resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.account_id
  name       = var.name
  config_src = var.config_src
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  config = {
    # Combine the user-provided rules with the mandatory 404 catch-all
    ingress = concat(
      [
        for rule in var.ingress_rules : {
          hostname = rule.hostname
          path     = rule.path
          service  = rule.service
        }
      ],
      [
        { service = "http_status:404" }
      ]
    )
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}
