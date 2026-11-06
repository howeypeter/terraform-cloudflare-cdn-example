variable "resource_records" {
  description = <<-EOT
    DNS records in the zone, keyed by a stable name (the key is the record's Terraform address: renaming it replaces
    the record). name: "@" for the apex, a label ("www"), or the full name ("www.cambrera.net"). ttl: defaults to
    1 = automatic (300s), otherwise 60-86400 seconds (proxied records are always automatic). priority: MX only.
    proxied: A/AAAA/CNAME only.
    TXT content must be quoted, e.g. "\"v=spf1 ... ~all\"". Set content for every type except CAA, which takes
    data = { flags = 0, tag = "issue", value = "letsencrypt.org" } instead.
  EOT
  type = map(object({
    name    = string
    type    = string
    content = optional(string)
    data = optional(object({
      flags = number
      tag   = string
      value = string
    }))
    ttl      = optional(number, 1)    # 1 = automatic (300s unless proxied)
    priority = optional(number, null) # MX only
    proxied  = optional(bool)
    comment  = optional(string)
  }))
  default = null

  validation {
    condition     = alltrue([for r in coalesce(var.resource_records, {}) : (r.type == "CAA") == (r.data != null) && (r.content == null) == (r.data != null)])
    error_message = "CAA records need data (and no content); every other type needs content (and no data)."
  }

  validation {
    condition = alltrue([for r in coalesce(var.resource_records, {}) :
    r.data == null || contains(["issue", "issuewild", "iodef"], try(r.data.tag, ""))])
    error_message = "CAA data.tag must be one of: issue, issuewild, iodef."
  }

  validation {
    condition = alltrue([for r in coalesce(var.resource_records, {}) :
    contains(["A", "AAAA", "CAA", "CNAME", "MX", "NS", "SRV", "TXT"], r.type)])
    error_message = "type must be one of: A, AAAA, CAA, CNAME, MX, NS, SRV, TXT."
  }

  validation {
    condition     = alltrue([for r in coalesce(var.resource_records, {}) : r.ttl == 1 || (r.ttl >= 60 && r.ttl <= 86400)])
    error_message = "ttl must be 1 (automatic) or 60-86400 seconds."
  }

  validation {
    condition     = alltrue([for r in coalesce(var.resource_records, {}) : (r.type == "MX") == (r.priority != null)])
    error_message = "priority is required for MX records and only allowed on them."
  }

  validation {
    condition     = alltrue([for r in coalesce(var.resource_records, {}) : r.proxied != true || contains(["A", "AAAA", "CNAME"], r.type)])
    error_message = "proxied can only be true on A, AAAA, and CNAME records."
  }

  validation {
    condition     = alltrue([for r in coalesce(var.resource_records, {}) : length(r.comment == null ? "" : r.comment) <= 100])
    error_message = "comment must be at most 100 characters (Free plan limit)."
  }
}

variable "zone_name" {
  description = "The zone (domain), e.g. cambrera.net."
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9-]+\\.)+[a-z]{2,}$", var.zone_name))
    error_message = "zone_name must be a lowercase domain name, e.g. cambrera.net."
  }
}

variable "zone_type" {
  description = "full: Cloudflare is the authoritative DNS (nameservers changed at the registrar). partial: CNAME setup (Business plan and up). secondary: Enterprise only."
  type        = string
  default     = "full"

  validation {
    condition     = contains(["full", "partial", "secondary", "internal"], var.zone_type)
    error_message = "zone_type must be one of: full, partial, secondary, internal."
  }
}
