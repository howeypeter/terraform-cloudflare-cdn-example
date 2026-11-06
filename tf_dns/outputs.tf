output "account_id" {
  description = "The account that owns the zone."
  value       = local.account_id
}

output "zone" {
  description = "The zone's ID, status (pending until the registrar points at name_servers, then active), and the nameservers to set at the registrar."
  value = {
    id           = cloudflare_zone.this.id
    name         = cloudflare_zone.this.name
    status       = cloudflare_zone.this.status
    name_servers = cloudflare_zone.this.name_servers
  }
}

output "resource_records" {
  description = "DNS records managed by this module (key => ID, full name, type, content)."
  value = { for key, r in cloudflare_dns_record.this : key => {
    id = r.id, name = r.name, type = r.type, content = r.content
  } }
}
