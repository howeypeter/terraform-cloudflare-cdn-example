# Self-Hosted Application (Exercise 2 - Steps 1-3)
# Onboards self-hosted application on Cloudflare Tunnel (tunnel.cambrera.net/testers*) and restricts access to:
# - Testers group in IdP
# - Whitelisted admin: howey.peter@gmail.com

resource "cloudflare_zero_trust_access_application" "self_hosted_testers" {
  account_id = var.account_id
  name       = "Self-Hosted Testers App"
  type       = "self_hosted"
  domain     = "tunnel.cambrera.net/testers*"

  session_duration = "24h"

  policies = [
    {
      name     = "Allow Testers and Admin"
      decision = "allow"
      include = [
        { group = { id = cloudflare_zero_trust_access_group.testers.id } },
        { email = { email = "howey.peter@gmail.com" } }
      ]
    }
  ]
}
