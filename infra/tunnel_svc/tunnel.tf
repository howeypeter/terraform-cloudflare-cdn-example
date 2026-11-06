# Cloudflare Tunnel for tunnel.cambrera.net. The connector (cloudflared, in infra_aws/www/docker-compose.yml) runs on
# the www instance, dials out to Cloudflare, and forwards requests to the app on localhost.
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = "eedd707b4e658a58dff3f7d2933f5bb0"
  name       = "cambrera-prod-tunnel"
  config_src = "cloudflare" # ingress rules managed here, not on the connector
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel" {
  account_id = "eedd707b4e658a58dff3f7d2933f5bb0"
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  config = {
    ingress = [
      { hostname = "tunnel.cambrera.net", service = "http://localhost:8080" }, # the www container, same instance
      { service = "http_status:404" },
    ]
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel" {
  account_id = "eedd707b4e658a58dff3f7d2933f5bb0"
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

# The connector reads the token from here at boot.
resource "aws_ssm_parameter" "tunnel_token" {
  name  = "/cambrera-prod/tunnel_svc/token"
  type  = "SecureString"
  value = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel.token
}

output "tunnel_cname" {
  description = "Target for the tunnel.cambrera.net CNAME (proxied) in infra/common."
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
}
