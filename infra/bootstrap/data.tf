# Read-only lookups used by iam.tf.

# The account (credentials must see exactly one) and all of its zones.
data "cloudflare_accounts" "this" {}

data "cloudflare_zones" "all" {
  account = {
    id = local.account_id
  }
}

# Permission catalog per scope, as name => ID maps.
data "cloudflare_api_token_permission_groups_list" "account" {
  scope     = "com.cloudflare.api.account"
  max_items = 1000
}

data "cloudflare_api_token_permission_groups_list" "zone" {
  for_each = local.zones

  scope     = "com.cloudflare.api.account.zone"
  max_items = 1000
}

locals {
  account_id             = one(data.cloudflare_accounts.this.result).id
  account_permission_ids = { for g in data.cloudflare_api_token_permission_groups_list.account.result : g.name => g.id }
  zones                  = { for z in data.cloudflare_zones.all.result : z.name => z }
  zone_permission_ids    = { for zone_name, d in data.cloudflare_api_token_permission_groups_list.zone : zone_name => { for g in d.result : g.name => g.id } }
}
