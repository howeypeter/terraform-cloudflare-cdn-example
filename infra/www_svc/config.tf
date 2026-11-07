terraform {
  required_version = ">= 1.17.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28" # >= 5.28, < 6.0. Pinned to v5: v4 -> v5 is a breaking rewrite.
    }
  }

  # State: AWS S3 (versioned), S3-native locking. Credentials: standard AWS chain. See the root README.
  backend "s3" {
    bucket       = "cambrera-prod-tf-state"
    key          = "cloudflare/infra/www_svc/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

# Credentials: the provider reads the API token from the CLOUDFLARE_API_TOKEN environment variable (the CI token from
# infra/bootstrap); see the root README.
provider "cloudflare" {}
