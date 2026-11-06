output "gateway_policies" {
  description = "Configured Gateway policies (key => ID, name, action, precedence)."
  value = { for key, p in cloudflare_zero_trust_gateway_policy.policy : key => {
    id         = p.id
    name       = p.name
    action     = p.action
    precedence = p.precedence
  } }
}
