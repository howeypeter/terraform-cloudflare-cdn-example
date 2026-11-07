variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "name" {
  description = "Name of the Cloudflare tunnel."
  type        = string
}

variable "config_src" {
  description = "Configuration source for the tunnel (cloudflare or local)."
  type        = string
  default     = "cloudflare"
}

variable "ingress_rules" {
  description = "List of ingress rules mapping hostnames/paths to local service endpoints."
  type = list(object({
    hostname      = optional(string)
    path          = optional(string)
    service       = string
    origin_request = optional(map(any))
  }))
  default = []
}
