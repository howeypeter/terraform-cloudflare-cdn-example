# Credentials: the provider reads the API token from the CLOUDFLARE_API_TOKEN environment variable (the CI token from
# infra/bootstrap); see the root README.
provider "cloudflare" {}

terraform {
  # State: AWS S3 (versioned), S3-native locking. Credentials: standard AWS chain. See the root README.
  backend "s3" {
    bucket       = "cambrera-prod-tf-state"
    key          = "cloudflare/infra/www_svc/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
