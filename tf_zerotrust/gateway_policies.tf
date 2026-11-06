# Declarative for_each loop configuring all Gateway policies from var.gateway_policies
resource "cloudflare_zero_trust_gateway_policy" "policy" {
  for_each = var.gateway_policies

  account_id  = var.account_id
  name        = each.value.name
  description = each.value.description
  action      = each.value.action
  filters     = each.value.filters
  traffic     = each.value.traffic
  precedence  = each.value.precedence
  enabled     = each.value.enabled
}
