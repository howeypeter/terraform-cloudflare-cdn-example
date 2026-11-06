locals {
  # Names are stored as full names ("www.cambrera.net"); "@" and bare labels are expanded so the plan shows no drift.
  resource_records = {
    for key, r in coalesce(var.resource_records, {}) : key => merge(r, {
      name = (r.name == "@" ? var.zone_name
        : endswith(r.name, ".${var.zone_name}") || r.name == var.zone_name ? r.name
      : "${r.name}.${var.zone_name}")
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
