variable "account_id" {
  description = "Cloudflare account ID (32 hex characters)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be 32 lowercase hex characters."
  }
}

variable "gateway_policies" {
  description = <<-EOT
    Map of Cloudflare Zero Trust Gateway policies (DNS, HTTP, Network) configured via for_each.
    Keys are stable identifiers. Each policy requires name, action, filters, traffic, and precedence.
  EOT
  type = map(object({
    name        = string
    description = optional(string)
    action      = string
    filters     = list(string)
    traffic     = string
    precedence  = number
    enabled     = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for p in var.gateway_policies : contains(["block", "allow", "isolate", "nosnoop", "off", "audit_ssh"], p.action)])
    error_message = "action must be one of: block, allow, isolate, nosnoop, off, audit_ssh."
  }
}
