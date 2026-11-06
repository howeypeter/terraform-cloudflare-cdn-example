variable "account_id" {
  description = "Cloudflare account ID (32 hex characters)."
  type        = string
  default     = "eedd707b4e658a58dff3f7d2933f5bb0"

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be 32 lowercase hex characters."
  }
}

variable "google_client_id" {
  description = "Google OAuth client ID (optional if already configured in dashboard)."
  type        = string
  default     = null
}

variable "google_client_secret" {
  description = "Google OAuth client secret (optional if already configured in dashboard)."
  type        = string
  default     = null
  sensitive   = true
}
