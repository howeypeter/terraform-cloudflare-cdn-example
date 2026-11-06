terraform {
  required_version = ">= 1.17.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
  }

  backend "s3" {
    bucket       = "cambrera-prod-tf-state"
    key          = "cloudflare/infra/tunnel_svc/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

# CLOUDFLARE_API_TOKEN (the CI token, in .env) and the standard AWS credentials.
provider "cloudflare" {}

provider "aws" {
  region = "us-east-1"
}
