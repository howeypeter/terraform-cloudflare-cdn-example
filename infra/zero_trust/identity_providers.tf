# Login methods for Cloudflare Access (step 5).
# If credentials are provided via tfvars, Terraform will manage them.
# Otherwise, existing IdPs configured via dashboard/API are preserved.

resource "cloudflare_zero_trust_access_identity_provider" "google" {
  count = var.google_client_id != null ? 1 : 0

  account_id = var.account_id
  name       = "Google"
  type       = "google"

  config = {
    client_id     = var.google_client_id
    client_secret = var.google_client_secret
  }
}
