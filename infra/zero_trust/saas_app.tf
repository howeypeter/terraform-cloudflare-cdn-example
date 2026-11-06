# SaaS Application (Exercise 2 - Steps 1-3)
# Onboards MockSAML (BoxyHQ) with Cloudflare as the Identity Provider (SAML 2.0).
# SP Entity ID: https://mocksaml.com
# ACS URL:      https://mocksaml.com/api/saml/sso
# Restricts access to:
# - SaaS Users group
# - Whitelisted admin: howey.peter@gmail.com

resource "cloudflare_zero_trust_access_application" "samltest" {
  account_id = var.account_id
  name       = "MockSAML SaaS App"
  type       = "saas"

  saas_app = {
    auth_type            = "saml"
    sp_entity_id         = "https://mocksaml.com"
    consumer_service_url = "https://mocksaml.com/api/saml/sso"
    name_id_format       = "email"
  }

  policies = [
    {
      name     = "Allow SaaS Users and Admin"
      decision = "allow"
      include = [
        { group = { id = cloudflare_zero_trust_access_group.saas_users.id } },
        { email = { email = "howey.peter@gmail.com" } }
      ]
    }
  ]
}
