output "proxied_records" {
  description = "Proxied records (key => ID, full name, origin)."
  value = { for key, r in cloudflare_dns_record.proxied : key => {
    id = r.id, name = r.name, content = r.content
  } }
}

output "redirects_ruleset_id" {
  description = "ID of the redirects ruleset (null when canonical_redirect is null)."
  value       = one(cloudflare_ruleset.redirects[*].id)
}
