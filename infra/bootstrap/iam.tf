# CI/CD API token, scoped to this account and its zones. Permission names: see README.md.

locals {
  ci_account_permissions = [
    "Account Settings Read",                                       # account lookups (data_references)
    "Account Rule Lists Write",                                    # cloudflare_list (IP Lists)
    "Logs Write",                                                  # account Logpush jobs
    "Workers Scripts Write",                                       # Worker deployment
    "Workers R2 Storage Write",                                    # R2 buckets (the /secure/COUNTRY flags)
    "Cloudflare Tunnel Write",                                     # Cloudflare Tunnel
    "Access: Apps and Policies Write",                             # Access applications and policies
    "Access: Organizations, Identity Providers, and Groups Write", # Zero Trust org, SSO IdP, groups
    "Zero Trust Write",                                            # Gateway DNS/HTTP policies, WARP enrollment
  ]

  ci_zone_permissions = [
    "Zone Read",                   # zone lookups
    "DNS Write",                   # cloudflare_dns_record
    "Zone Settings Write",         # cloudflare_zone_setting, tiered cache, Argo
    "SSL and Certificates Write",  # Full (strict) TLS, origin certificates
    "Cache Settings Write",        # cache rules
    "Config Settings Write",       # config rules
    "Response Compression Write",  # compression rules
    "Zone Transform Rules Write",  # response header rules (baseline headers, CORS)
    "Dynamic URL Redirects Write", # Single Redirects (tf_cdn canonical_redirect: apex and http:// to https://www)
    "Zone WAF Write",              # custom rules (nonprod ACL, block direct origin access)
    "Workers Routes Write",        # Worker route on /secure
    "Logs Write",                  # zone Logpush jobs
  ]
}

locals {
  ci_account_policy = {
    effect            = "allow"
    permission_groups = [for name in local.ci_account_permissions : { id = local.account_permission_ids[name] }]
    resources         = jsonencode({ "com.cloudflare.api.account.${local.account_id}" = "*" })
  }

  # One policy per zone in the account at apply time; re-apply after adding a zone to include it.
  ci_zone_policies = [for zone_name, zone in local.zones : {
    effect            = "allow"
    permission_groups = [for name in local.ci_zone_permissions : { id = local.zone_permission_ids[zone_name][name] }]
    resources         = jsonencode({ "com.cloudflare.api.account.zone.${zone.id}" = "*" })
  }]
}

resource "cloudflare_api_token" "ci" {
  name     = "cambrera-cloudflare-ci"
  policies = concat([local.ci_account_policy], local.ci_zone_policies)
}

# ACME (DNS-01) token for the origin's certificate client (certbot dns-cloudflare, lego, acme.sh): it creates and
# deletes _acme-challenge TXT records. DNS only, one zone, no account permissions. It lives on the origin server,
# not in CI, so it's kept separate from the CI token.
locals {
  acme_zone_name = "cambrera.net"

  acme_zone_permissions = [
    "Zone Read", # zone ID lookup (some clients need it)
    "DNS Write", # create/delete the challenge TXT records
  ]
}

resource "cloudflare_api_token" "acme" {
  name = "cambrera-acme-dns01"
  policies = [{
    effect            = "allow"
    permission_groups = [for name in local.acme_zone_permissions : { id = local.zone_permission_ids[local.acme_zone_name][name] }]
    resources         = jsonencode({ "com.cloudflare.api.account.zone.${local.zones[local.acme_zone_name].id}" = "*" })
  }]

  # Optional: only allow requests from the origin's public IP.
  # condition = {
  #   request_ip = { in = ["203.0.113.10/32"] } # PLACEHOLDER: the origin's IP
  # }
}
