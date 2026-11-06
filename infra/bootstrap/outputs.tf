output "zone_names" {
  description = "Zones in the account (the CI token is scoped to all of them)."
  value       = keys(local.zones)
}

# Permission catalog (name => ID) for picking names in iam.tf; see README.md.
output "account_permission_groups" {
  description = "All account-scoped API token permission groups (name => ID)."
  value       = local.account_permission_ids
}

output "zone_permission_groups" {
  description = "All zone-scoped API token permission groups, per zone (zone name => permission name => ID)."
  value       = local.zone_permission_ids
}

output "ci_api_token" {
  description = "CI token value. Read with: terraform output -raw ci_api_token, then store it as the CLOUDFLARE_API_TOKEN secret in CI."
  value       = cloudflare_api_token.ci.value
  sensitive   = true
}

output "acme_api_token" {
  description = "ACME DNS-01 token value (cambrera.net DNS only). Read with: terraform output -raw acme_api_token, then put it in the ACME client's credentials file on the origin (e.g. certbot's cloudflare.ini, chmod 600)."
  value       = cloudflare_api_token.acme.value
  sensitive   = true
}
