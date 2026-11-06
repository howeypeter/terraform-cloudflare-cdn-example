# WARP Device Enrollment Permissions (Exercise 2 - Gateway Step 1)
# Restricts WARP client enrollment to:
# - Users in the IdP groups (Testers, SaaS Users)
# - Whitelisted admin: howey.peter@gmail.com
# Ensuring no unauthorized users can enroll devices to the Zero Trust organization.

resource "cloudflare_zero_trust_access_application" "warp_device_enrollment" {
  account_id = var.account_id
  name       = "WARP Device Enrollment"
  type       = "warp"

  session_duration = "24h"

  policies = [
    {
      name     = "Allow IdP Groups and Admin to Enroll WARP"
      decision = "allow"
      include = [
        { group = { id = cloudflare_zero_trust_access_group.testers.id } },
        { group = { id = cloudflare_zero_trust_access_group.saas_users.id } },
        { email = { email = "howey.peter@gmail.com" } }
      ]
    }
  ]
}
