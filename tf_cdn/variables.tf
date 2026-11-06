variable "canonical_redirect" {
  description = <<-EOT
    One canonical URL for the site: every request to an alias (http or https), and every plain-http request to the
    canonical hostname, gets a redirect to https://<hostname> with the same path and query string, in one hop at
    Cloudflare's edge. E.g. hostname = "www.cambrera.net", aliases = ["cambrera.net"]. All of them must be proxied
    (proxied_records). null = no redirect.
  EOT
  type = object({
    hostname    = string
    aliases     = list(string)
    status_code = optional(number, 301)
  })
  default = null

  validation {
    condition     = var.canonical_redirect == null || contains([301, 302, 307, 308], try(var.canonical_redirect.status_code, 301))
    error_message = "canonical_redirect status_code must be one of: 301, 302, 307, 308."
  }
}

variable "cdn_min_tls_version" {
  description = "Oldest TLS version visitors may use to connect to Cloudflare's edge (zone-wide). 1.3 refuses TLS 1.0-1.2 clients."
  type        = string
  default     = "1.3"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.cdn_min_tls_version)
    error_message = "cdn_min_tls_version must be one of: 1.0, 1.1, 1.2, 1.3."
  }
}

variable "cdn_ssl_mode" {
  description = <<-EOT
    How Cloudflare connects to origins (zone-wide SSL/TLS encryption mode). strict = Full (strict): HTTPS, and the
    origin's certificate must be valid for the visitor's hostname (publicly trusted or Cloudflare Origin CA, not
    expired). full = HTTPS without checking the certificate. flexible = HTTP to the origin. off = no HTTPS at all.
  EOT
  type        = string
  default     = "strict"

  validation {
    condition     = contains(["off", "flexible", "full", "strict"], var.cdn_ssl_mode)
    error_message = "cdn_ssl_mode must be one of: off, flexible, full, strict."
  }
}

variable "cdn_tiered_cache" {
  description = "Enable Tiered Caching (on/off) to route edge cache misses through regional Upper-Tier super-PoPs."
  type        = string
  default     = "on"

  validation {
    condition     = contains(["off", "on"], var.cdn_tiered_cache)
    error_message = "cdn_tiered_cache must be one of: off, on."
  }
}

variable "proxied_records" {
  description = <<-EOT
    Orange-cloud hostnames, keyed by a stable name (the key is the record's Terraform address: renaming it replaces
    the record). Each is a proxied CNAME: visitors get Cloudflare's IPs, and Cloudflare connects to content (the
    origin's hostname). name: a label ("www") or the full name ("www.cambrera.net"). comment: start with the ticket.
  EOT
  type = map(object({
    name    = string
    content = string
    comment = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.proxied_records : length(r.comment == null ? "" : r.comment) <= 100])
    error_message = "comment must be at most 100 characters (Free plan limit)."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID (32 hex characters) the records are created in."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be 32 lowercase hex characters."
  }
}
