output "account" {
  description = "The account the credentials see."
  value       = { id = local.account_id, name = one(data.cloudflare_accounts.this.result).name }
}

output "zones" {
  description = "Zones in the account (zone name => ID, status, nameservers to set at the registrar)."
  value       = { for name, z in local.zones : name => { id = z.id, status = z.status, name_servers = z.name_servers } }
}

output "dns_records" {
  description = "DNS records per zone (zone name => records with IDs, for terraform import)."
  value = { for name, d in data.cloudflare_dns_records.zone : name => [
    for r in d.result : { id = r.id, name = r.name, type = r.type, content = r.content, proxied = r.proxied }
  ] }
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

# Enterprise only: uncomment with the matching data sources in data.tf.
# output "logpush_jobs" {
#   description = "Logpush jobs per zone."
#   value       = { for name, d in data.cloudflare_logpush_jobs.zone : name => d.result }
# }
#
# output "logpush_fields" {
#   description = "Fields available in the http_requests dataset, per zone."
#   value       = { for name, d in data.cloudflare_logpush_dataset_field.http_requests : name => d.fields }
# }
