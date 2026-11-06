# Private R2 bucket for country flags (Step 7d of Application Services Assignment).
# By default in Cloudflare, R2 buckets are completely private with public access disabled.
# Objects are accessed directly by the Cloudflare Worker via an R2 binding (env.FLAGS_BUCKET).

resource "cloudflare_r2_bucket" "country_flags" {
  account_id = "eedd707b4e658a58dff3f7d2933f5bb0"
  name       = "cambrera-prod-country-flags"
}

output "bucket_name" {
  description = "Private R2 bucket name holding country flags."
  value       = cloudflare_r2_bucket.country_flags.name
}

output "account_id" {
  description = "Cloudflare account ID."
  value       = cloudflare_r2_bucket.country_flags.account_id
}
