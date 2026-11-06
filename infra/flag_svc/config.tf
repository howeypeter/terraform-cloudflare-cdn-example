terraform {
  required_version = ">= 1.17.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
  }

  backend "s3" {
    bucket       = "cambrera-prod-tf-state"
    key          = "cloudflare/infra/flag_svc/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

# Credentials: provider reads CLOUDFLARE_API_TOKEN from the environment (.env)
provider "cloudflare" {}
