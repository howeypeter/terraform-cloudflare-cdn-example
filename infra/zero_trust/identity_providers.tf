# Login methods for Cloudflare Access (step 5). Google: you, with your Gmail account. One-time PIN: anyone, with a code
# emailed to them (how @cloudflare.com reviewers log in). Who may get in is decided by the Access policy, not here.
resource "cloudflare_zero_trust_access_identity_provider" "google" {
  account_id = "eedd707b4e658a58dff3f7d2933f5bb0"
  name       = "Google"
  type       = "google"

  config = {
    client_id     = var.google_client_id
    client_secret = var.google_client_secret
  }
}

resource "cloudflare_zero_trust_access_identity_provider" "otp" {
  account_id = "eedd707b4e658a58dff3f7d2933f5bb0"
  name       = "One-time PIN"
  type       = "onetimepin"
  config     = {}
}
