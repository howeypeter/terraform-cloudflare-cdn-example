output "testers_group_id" {
  description = "ID of the Testers Access Group"
  value       = cloudflare_zero_trust_access_group.testers.id
}

output "saas_users_group_id" {
  description = "ID of the SaaS Users Access Group"
  value       = cloudflare_zero_trust_access_group.saas_users.id
}

output "self_hosted_testers_app_id" {
  description = "ID of the Self-Hosted Testers Access Application"
  value       = cloudflare_zero_trust_access_application.self_hosted_testers.id
}

output "samltest_app_id" {
  description = "ID of the SAMLtest SaaS Application"
  value       = cloudflare_zero_trust_access_application.samltest.id
}

output "samltest_idp_entity_id" {
  description = "Cloudflare IdP Entity ID / Issuer for SAMLtest.id"
  value       = cloudflare_zero_trust_access_application.samltest.saas_app.idp_entity_id
}

output "samltest_sso_endpoint" {
  description = "Cloudflare SSO login endpoint for SAMLtest.id"
  value       = cloudflare_zero_trust_access_application.samltest.saas_app.sso_endpoint
}

output "gateway_policies" {
  description = "Configured Gateway policies from tf_zerotrust module"
  value       = module.gateway.gateway_policies
}
