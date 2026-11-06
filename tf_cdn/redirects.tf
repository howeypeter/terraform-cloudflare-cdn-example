# Canonical-host redirect (Single Redirects): Cloudflare answers these requests itself, so they never reach the
# origin. One rule, so http://alias, https://alias, and http://canonical all go to https://canonical in one hop.
# Always Use HTTPS (zone_cdn_optimizations.tf) stays on for any other proxied hostname. One ruleset per zone for this phase.
locals {
  canonical = var.canonical_redirect
  canonical_expression = local.canonical == null ? null : format(
    "(http.host in {%s}) or (http.host eq \"%s\" and not ssl)",
    join(" ", [for h in local.canonical.aliases : "\"${h}\""]),
    local.canonical.hostname,
  )
}

resource "cloudflare_ruleset" "redirects" {
  count = local.canonical == null ? 0 : 1

  zone_id     = var.zone_id
  name        = "redirects"
  description = "Canonical-host redirect (tf_cdn)"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [{
    ref         = "canonical"
    description = "${join(", ", local.canonical.aliases)} and http://${local.canonical.hostname} -> https://${local.canonical.hostname}"
    expression  = local.canonical_expression
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code           = local.canonical.status_code
        preserve_query_string = true
        target_url = {
          expression = "concat(\"https://${local.canonical.hostname}\", http.request.uri.path)" # same path
        }
      }
    }
  }]
}
