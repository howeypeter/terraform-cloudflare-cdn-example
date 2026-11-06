# www: a diagnostics app (http-https-echo) that echoes back the request (headers included), behind an ALB.
#
# The containers are in www/docker-compose.yml (the app and cloudflared), zipped and uploaded to S3 as the application
# version. Editing anything in www/ creates a new version (named from the zip's hash) and redeploys.

data "archive_file" "www" {
  type        = "zip"
  source_dir  = "${path.module}/www"
  output_path = "${path.module}/.terraform/www.zip"
}

locals {
  www_name    = "${local.name_prefix}-www"
  www_version = "${local.www_name}-${substr(data.archive_file.www.output_md5, 0, 12)}"
}

resource "aws_acm_certificate" "www_origin" {
  domain_name               = "www-origin.cambrera.net"
  subject_alternative_names = ["www.cambrera.net", "cambrera.net"]
  validation_method         = "DNS"

  tags = { Name = "www-origin.cambrera.net" }

  # Replacing the certificate (e.g. changing its names) creates the new one first, so the listener isn't left without one.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "www_origin" {
  certificate_arn = aws_acm_certificate.www_origin.arn
}

# Latest AL2023 Docker platform. Plans show an in-place platform update when AWS releases a new one.
data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 (.*) running Docker$"
}

# Application versions (source bundles), for all Beanstalk apps; keys are per app.
resource "aws_s3_bucket" "www_versions" {
  bucket_prefix = "${local.name_prefix}-www-versions-"
  force_destroy = true # only holds generated bundles
}

resource "aws_s3_bucket_public_access_block" "www_versions" {
  bucket = aws_s3_bucket.www_versions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "www_bundle" {
  bucket = aws_s3_bucket.www_versions.id
  key    = "${local.www_name}/${local.www_version}/www.zip"
  source = data.archive_file.www.output_path
}

resource "aws_elastic_beanstalk_application" "www" {
  name        = local.www_name
  description = "Diagnostics app to echo back incoming request headers"
}

resource "aws_elastic_beanstalk_application_version" "www" {
  name        = local.www_version
  application = aws_elastic_beanstalk_application.www.name
  bucket      = aws_s3_object.www_bundle.bucket
  key         = aws_s3_object.www_bundle.key

  # New version first: Beanstalk won't delete the one the environment is running.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elastic_beanstalk_environment" "www" {
  name                = local.www_name # also the CNAME prefix
  application         = aws_elastic_beanstalk_application.www.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.docker.name
  version_label       = aws_elastic_beanstalk_application_version.www.name

  # ALB in front; one instance to keep cost down. (SingleInstance would mean no load balancer at all.)
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t3.micro"
  }

  # Listeners: HTTPS on 443 only, with the certificate above; port 80 is off.
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "false"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = aws_acm_certificate_validation.www_origin.certificate_arn
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLPolicy"
    value     = "ELBSecurityPolicy-TLS13-1-2-2021-06" # TLS 1.3 and 1.2 only
  }

  # The ALB's security group (www_security_group.tf): HTTPS from Cloudflare only, instead of Beanstalk's own
  # 443-from-anywhere group. ManagedSecurityGroup makes Beanstalk open the instances' port 80 to this group.
  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.alb.id
  }
  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = aws_security_group.alb.id
  }

  # Roles (www_iam.tf).
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.www_ec2.name
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.www_service.name
  }

  # Network (vpc.tf): ALB and instances in the public subnets.
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", sort([for s in aws_subnet.public : s.id])) # sorted, as Beanstalk stores it
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", sort([for s in aws_subnet.public : s.id])) # sorted, as Beanstalk stores it
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  # The tunnel token (infra/tunnel_svc), fetched from SSM at boot into .env for cloudflared.
  setting {
    namespace = "aws:elasticbeanstalk:application:environmentsecrets"
    name      = "TUNNEL_TOKEN"
    value     = "arn:aws:ssm:us-east-1:305111894801:parameter/cambrera-prod/tunnel_svc/token"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  depends_on = [
    aws_iam_role_policy_attachment.www_ec2_web_tier,
    aws_iam_role_policy_attachment.www_service,
    aws_iam_role_policy.www_ec2_tunnel_token,
    aws_route_table_association.public,
  ]
}
