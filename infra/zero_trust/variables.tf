# Google OAuth client (Google Cloud Console > Credentials). Set in terraform.tfvars (gitignored).
variable "google_client_id" {
  type = string
}

variable "google_client_secret" {
  type      = string
  sensitive = true
}
