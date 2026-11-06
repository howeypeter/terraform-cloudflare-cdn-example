terraform {
  required_version = ">= 1.17.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28" # >= 5.28, < 6.0. Pinned to v5: v4 -> v5 is a breaking rewrite.
    }
  }
}
