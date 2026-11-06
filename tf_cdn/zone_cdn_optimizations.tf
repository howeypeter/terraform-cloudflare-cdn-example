# Zone-wide edge optimizations (apply to every proxied hostname in the zone).

locals {
  zone_cdn_optimizations = {
    # Non-negotiable security baseline: plain HTTP is never served; Cloudflare answers http://
    # with a 301 redirect to https:// directly at the edge. Hardcoded like the Akamai property baseline.
    always_use_https = "on"
    ssl              = var.cdn_ssl_mode
    tls_1_3          = "on"
    min_tls_version  = var.cdn_min_tls_version
  }
}

# Declarative for_each loop configuring all zone optimizations from local map
resource "cloudflare_zone_setting" "optimization" {
  for_each   = local.zone_cdn_optimizations
  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}

# Safe state migrations to prevent resource recreation/downtime
moved {
  from = cloudflare_zone_setting.always_use_https
  to   = cloudflare_zone_setting.optimization["always_use_https"]
}

moved {
  from = cloudflare_zone_setting.ssl
  to   = cloudflare_zone_setting.optimization["ssl"]
}

moved {
  from = cloudflare_zone_setting.min_tls_version
  to   = cloudflare_zone_setting.optimization["min_tls_version"]
}

moved {
  from = cloudflare_zone_setting.tls_1_3
  to   = cloudflare_zone_setting.optimization["tls_1_3"]
}

moved {
  from = cloudflare_zone_setting.settings
  to   = cloudflare_zone_setting.optimization
}

# Tiered Caching: consolidates edge cache misses across regional Upper-Tier super-PoPs,
# reducing origin requests by 90%+ and protecting infrequently requested assets from LRU eviction.
resource "cloudflare_tiered_cache" "tiered_cache" {
  zone_id = var.zone_id
  value   = var.cdn_tiered_cache
}
