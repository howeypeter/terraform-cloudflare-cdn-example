output "account" {
  description = "The account the credentials see."
  value       = { id = local.account_id, name = one(data.cloudflare_accounts.this.result).name }
}

output "zones" {
  description = "Zones in the account (zone name => ID, status, nameservers to set at the registrar)."
  value       = { for name, z in local.zones : name => { id = z.id, status = z.status, name_servers = z.name_servers } }
}

output "rulesets" {
  description = "Rulesets per zone (zone name => rulesets with phase and ID, for terraform import)."
  value = { for name, d in data.cloudflare_rulesets.zone : name => [
    for r in d.rulesets : { id = r.id, name = r.name, kind = r.kind, phase = r.phase, version = r.version }
  ] }
}

output "lists" {
  description = "Account-level lists (IP Lists etc.). Reference them in rule expressions as $name."
  value       = [for l in data.cloudflare_lists.account.result : { id = l.id, name = l.name, kind = l.kind, num_items = l.num_items }]
}

output "cloudflare_ip_ranges" {
  description = "Cloudflare edge IP ranges, to allow at your origin."
  value = {
    ipv4 = data.cloudflare_ip_ranges.this.ipv4_cidrs
    ipv6 = data.cloudflare_ip_ranges.this.ipv6_cidrs
  }
}
