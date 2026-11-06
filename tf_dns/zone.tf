# The account that owns the zone (credentials must see exactly one), looked up rather than passed in.
data "cloudflare_accounts" "this" {}

locals {
  account_id = one(data.cloudflare_accounts.this.result).id
}

# prevent_destroy: deleting the zone takes every DNS record and setting with it. To delete one on purpose, remove
# this flag first (lifecycle arguments can't come from variables).
resource "cloudflare_zone" "this" {
  account = {
    id = local.account_id
  }
  name = var.zone_name
  type = var.zone_type

  lifecycle {
    prevent_destroy = true
  }
}
