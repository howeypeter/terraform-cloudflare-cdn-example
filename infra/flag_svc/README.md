# flag_svc

Provisions the private Cloudflare R2 bucket for the country flags service (Step 7 of `docs/Application_Services_Assignment.pdf`).

## Contents

- `config.tf`: Pinned Terraform and Cloudflare provider v5 (`~> 5.28`), with S3 backend state.
- `r2.tf`: The `cloudflare_r2_bucket` resource (`cambrera-prod-country-flags`).

## Deploying

```bash
cd infra/flag_svc
# Ensure CLOUDFLARE_API_TOKEN is set (e.g. from .env)
terraform init
terraform plan
terraform apply
```

## Security & Access
The bucket has no public URL enabled (private by default). Access is granted exclusively to the Cloudflare Worker via Wrangler's internal R2 binding.
