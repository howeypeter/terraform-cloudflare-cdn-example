# www.cambrera.net behind Cloudflare (orange cloud), proxied to the http-echo origin (infra_aws: the Beanstalk ALB,
# HTTPS on 443 with an ACM certificate). The origin record (www-origin, DNS only) is in infra/common.
module "cdn" {
  source  = "../../tf_cdn"
  zone_id = "540470e266d01ed15c67e0ba13e3ef63" # cambrera.net

  proxied_records = {
    www = {
      name    = "www"                     # www.cambrera.net
      content = "www-origin.cambrera.net" # origin (ALB, ACM certificate)
      comment = "NET-104: www proxied to www-origin (http-echo)"
    }
    # The apex has to be proxied for the redirect below to run; its requests never reach the origin.
    apex = {
      name    = "cambrera.net"
      content = "www-origin.cambrera.net"
      comment = "NET-104: apex proxied; 301 to https://www.cambrera.net at the edge"
    }
  }

  # http://cambrera.net, https://cambrera.net, and http://www.cambrera.net -> https://www.cambrera.net (301, same
  # path and query string).
  canonical_redirect = {
    hostname = "www.cambrera.net"
    aliases  = ["cambrera.net"]
  }

  cdn_ssl_mode        = "strict" # Full (strict): the origin's ACM certificate covers www and the apex
  cdn_min_tls_version = "1.3"    # visitors must use TLS 1.3 to reach the edge
}

output "redirects_ruleset_id" {
  description = "ID of the canonical-host redirects ruleset."
  value       = module.cdn.redirects_ruleset_id
}

output "proxied_records" {
  description = "Proxied records (key => ID, full name, origin)."
  value       = module.cdn.proxied_records
}
