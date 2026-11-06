# Cloudflare Zero Trust Access Groups (Exercise 2)

# 1. Testers group: allowed access to the self-hosted application
resource "cloudflare_zero_trust_access_group" "testers" {
  account_id = var.account_id
  name       = "Testers"

  include = [
    { email = { email = "howey.peter+tester@gmail.com" } },
    { email = { email = "howey.peter@gmail.com" } }
  ]
}

# 2. SaaS Users group: allowed access to SaaS applications where Cloudflare is the IdP
resource "cloudflare_zero_trust_access_group" "saas_users" {
  account_id = var.account_id
  name       = "SaaS Users"

  include = [
    { email = { email = "howey.peter+saas@gmail.com" } },
    { email = { email = "howey.peter@gmail.com" } }
  ]
}
