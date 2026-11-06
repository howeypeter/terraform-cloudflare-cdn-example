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
