# Read-only lookups for Cloudflare account
data "cloudflare_accounts" "this" {}

locals {
  account_id = one(data.cloudflare_accounts.this.result).id
}

# Cloudflare Tunnel for tunnel.cambrera.net. The connector (cloudflared, in infra_aws/www/docker-compose.yml) runs on
# the www instance, dials out to Cloudflare, and forwards requests to the app on localhost.

module "tunnel" {
  source     = "../../tf_tunnel"
  account_id = local.account_id
  name       = "cambrera-prod-tunnel"

  ingress_rules = [
    {
      hostname = "tunnel.cambrera.net"
      service  = "http://localhost:8080" # the www container, same instance
    }
  ]
}

# The connector reads the token from here at boot.
resource "aws_ssm_parameter" "tunnel_token" {
  name  = "/cambrera-prod/tunnel_svc/token"
  type  = "SecureString"
  value = module.tunnel.tunnel_token
}

output "tunnel_cname" {
  description = "Target for the tunnel.cambrera.net CNAME (proxied) in infra/common."
  value       = module.tunnel.tunnel_cname
}
