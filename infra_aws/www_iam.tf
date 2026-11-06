# Beanstalk roles. Creating an environment through the API requires an instance profile; the service role runs
# enhanced health and managed platform updates.

# Instance profile for the EC2 instances.
resource "aws_iam_role" "www_ec2" {
  name = "${local.www_name}-ec2"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "www_ec2_web_tier" {
  role       = aws_iam_role.www_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Read the tunnel token (environmentsecrets in www_origin.tf), nothing else.
resource "aws_iam_role_policy" "www_ec2_tunnel_token" {
  name = "read-tunnel-token"
  role = aws_iam_role.www_ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = "arn:aws:ssm:us-east-1:305111894801:parameter/cambrera-prod/tunnel_svc/token"
    }]
  })
}

resource "aws_iam_instance_profile" "www_ec2" {
  name = aws_iam_role.www_ec2.name
  role = aws_iam_role.www_ec2.name
}

# Service role, assumed by Beanstalk itself.
resource "aws_iam_role" "www_service" {
  name = "${local.www_name}-service"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "elasticbeanstalk.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "www_service" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy",
  ])

  role       = aws_iam_role.www_service.name
  policy_arn = each.value
}
