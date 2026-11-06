# Credentials: the provider reads the API token from the CLOUDFLARE_API_TOKEN environment variable.
# See the README (Authentication) for the token's permissions.
provider "cloudflare" {}

locals {
  env = "prod"
}

terraform {
  # State storage: AWS S3 (bucket in us-west-2: versioned, encrypted by default, public access blocked).
  # Locking uses S3 native lockfiles (use_lockfile), so no DynamoDB table is needed.
  # Credentials come from the standard AWS chain (AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY, AWS_PROFILE, SSO, or the
  # default profile in ~/.aws/credentials). Grant them s3:ListBucket on the bucket and s3:GetObject, s3:PutObject,
  # s3:DeleteObject on cloudflare/* (DeleteObject is needed to release the lockfile).
  # After changing this block, run: terraform init -migrate-state (or -reconfigure if there's no state to move).
  backend "s3" {
    bucket       = "cambrera-prod-tf-state"
    key          = "cloudflare/infra/common/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

terraform {
  required_version = ">= 1.17.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28" # >= 5.28, < 6.0. Pinned to v5: v4 -> v5 is a breaking rewrite.
    }
  }
}
