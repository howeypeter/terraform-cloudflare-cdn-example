output "tunnel_id" {
  description = "UUID of the Cloudflare tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "tunnel_name" {
  description = "Name of the Cloudflare tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.name
}

output "tunnel_cname" {
  description = "CNAME target for DNS records pointing to this tunnel."
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
}

output "tunnel_token" {
  description = "Run token for the cloudflared connector."
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel.token
  sensitive   = true
}
