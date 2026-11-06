terraform {
  required_version = ">= 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71" # >= 6.71, < 7.0
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7" # Zips www/ for Beanstalk (www_origin.tf).
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5" # >= 3.5, < 4.0. Fetches Cloudflare's IP list (www_security_group.tf).
    }
  }

  # State: AWS S3 (versioned), S3-native locking. Same bucket as the Cloudflare stacks, under aws/. See README.md.
  backend "s3" {
    bucket       = "cambrera-prod-tf-state"
    key          = "aws/infra_aws/terraform.tfstate"
    region       = "us-west-2" # the bucket's region, not where resources go (that's the provider's region)
    encrypt      = true
    use_lockfile = true
  }
}

# Credentials: standard AWS chain (environment, AWS_PROFILE, SSO); see README.md.
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Stack     = "infra_aws"
    }
  }
}

# Prefix for resource names and Name tags.
locals {
  name_prefix = "cambrera-prod"
}
