locals {
  # Standardize all record names to fully-qualified domain names (FQDN) to prevent Terraform plan drift:
  # 1. Apex symbol ("@") or zone name -> var.zone_name (e.g. "cambrera.net")
  # 2. Fully-qualified subdomain       -> r.name (e.g. "_acm.www-origin.cambrera.net")
  # 3. Relative label                 -> "${r.name}.${var.zone_name}" (e.g. "www" -> "www.cambrera.net")
  resource_records = {
    for key, r in coalesce(var.resource_records, {}) : key => merge(r, {
      name = (
        r.name == "@" || r.name == var.zone_name ? var.zone_name :
        endswith(r.name, ".${var.zone_name}") ? r.name :
        "${r.name}.${var.zone_name}"
      )
    })
  }
}

resource "cloudflare_dns_record" "this" {
  for_each = local.resource_records

  zone_id  = cloudflare_zone.this.id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  data     = each.value.data
  ttl      = each.value.ttl
  priority = each.value.priority
  proxied  = each.value.proxied
  comment  = each.value.comment
}
