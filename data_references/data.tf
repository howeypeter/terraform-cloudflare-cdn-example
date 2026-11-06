# Read-only lookups. The account (credentials must see exactly one) and all of its zones.
data "cloudflare_accounts" "this" {}

data "cloudflare_zones" "all" {
  account = {
    id = local.account_id
  }
}

locals {
  account_id = one(data.cloudflare_accounts.this.result).id
  zones      = { for z in data.cloudflare_zones.all.result : z.name => z }
}

# Per zone, keyed by zone name.
data "cloudflare_dns_records" "zone" {
  for_each = local.zones

  zone_id = each.value.id
}

data "cloudflare_rulesets" "zone" {
  for_each = local.zones

  zone_id = each.value.id
}

# Account-level lists (IP Lists etc.).
data "cloudflare_lists" "account" {
  account_id = local.account_id
}

# Cloudflare's edge IP ranges (public; no permission needed).
data "cloudflare_ip_ranges" "this" {}

# Enterprise only: uncomment with the matching outputs. See README.md.
# data "cloudflare_logpush_jobs" "zone" {
#   for_each = local.zones
#
#   zone_id = each.value.id
# }
#
# data "cloudflare_logpush_dataset_field" "http_requests" {
#   for_each = local.zones
#
#   zone_id    = each.value.id
#   dataset_id = "http_requests"
# }
