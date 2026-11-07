# infra_aws

AWS infrastructure (Elastic Beanstalk, ALBs, ...), set up the same way as [`infra/bootstrap`](../infra/bootstrap/README.md).
Resources go in **us-east-1**; the state bucket stays in us-west-2.

| File | Contents |
|---|---|
| `config.tf` | Version pins, S3 backend, AWS provider (plus `http`, for Cloudflare's IP list) |
| `vpc.tf` | VPC with two public subnets (the account has no default VPC) |
| `www_iam.tf` | Beanstalk instance profile and service role |
| `www_security_group.tf` | The ALB's security group: HTTPS from Cloudflare's IPv4 ranges only, fetched on every plan from [cloudflare.com/ips-v4](https://www.cloudflare.com/ips-v4/) |
| `www_origin.tf` | `http-echo` app on Beanstalk, its ACM certificate (`www-origin`, `www`, `cambrera.net`), ALB on 443 only |
| `www/docker-compose.yml` | The containers: the app and its `cloudflared` tunnel connector; edit to redeploy |
| `outputs.tf` | The certificate's DNS validation records |

## Credentials

The standard AWS chain: environment variables, `AWS_PROFILE`, SSO, or the default profile. Check which identity
you're using before an apply:

```bash
aws sts get-caller-identity
```

No Cloudflare credentials: this stack is AWS only. The DNS records for `www-origin`, including the ACM validation
CNAME, are in `infra/common`.

**CAA:** ACM only issues if the zone's CAA records allow `amazon.com` (`caa_amazon` in `infra/common`). Apply
`infra/common` first.

**Certificate renewal:** ACM renews the certificate automatically as long as it's in use (on the ALB listener) and its
validation CNAMEs stay in `infra/common` (`cname_acm_www_origin`, `cname_acm_www`, `cname_acm_apex`).

## State (AWS S3)

| Setting | Value |
|---|---|
| Bucket | `cambrera-prod-tf-state` (us-west-2), shared with the Cloudflare stacks |
| Key | `aws/infra_aws/terraform.tfstate` |
| Bucket settings | Versioned, encrypted, public access blocked |
| Locking | S3-native (`use_lockfile`); no DynamoDB table |

- **Key layout:** `aws/<path to stack>/terraform.tfstate`, next to `cloudflare/...` for the Cloudflare stacks.
- **IAM permissions:**
  - `s3:ListBucket` on the bucket
  - `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on `aws/*` (DeleteObject releases the lock)
- **After changing the backend:** run `terraform init -migrate-state`.

## Usage

```bash
terraform init
terraform plan
terraform apply
```


<!-- BEGIN_TF_DOCS_INFRA_AWS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.71 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.5 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.7 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.71 |
| <a name="provider_http"></a> [http](#provider\_http) | ~> 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.www_origin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.www_origin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_elastic_beanstalk_application.www](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_application) | resource |
| [aws_elastic_beanstalk_application_version.www](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_application_version) | resource |
| [aws_elastic_beanstalk_environment.www](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_environment) | resource |
| [aws_iam_instance_profile.www_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.www_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.www_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.www_ec2_tunnel_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.www_ec2_web_tier](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.www_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.www_versions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.www_versions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_object.www_bundle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_security_group_egress_rule.alb_to_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_https_cloudflare](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [archive_file.www](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_elastic_beanstalk_solution_stack.docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elastic_beanstalk_solution_stack) | data source |
| [http_http.cloudflare_ipv4](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_www_origin_validation_records"></a> [www\_origin\_validation\_records](#output\_www\_origin\_validation\_records) | DNS validation CNAMEs for the www-origin certificate; keep them in Cloudflare (DNS only) for renewal. |
<!-- END_TF_DOCS_INFRA_AWS -->
