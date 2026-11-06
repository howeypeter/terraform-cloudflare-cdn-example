# Orange proxy: a proxied CNAME per hostname. DNS answers with Cloudflare's IPs, so visitors connect to Cloudflare,
# which connects to the origin (content). How Cloudflare talks to the origin is set by the zone's SSL/TLS mode.
resource "cloudflare_dns_record" "proxied" {
  for_each = var.proxied_records

  zone_id = var.zone_id
  name    = each.value.name
  type    = "CNAME"
  content = each.value.content
  proxied = true # orange cloud
  ttl     = 1    # automatic; proxied records always use it
  comment = each.value.comment
}
