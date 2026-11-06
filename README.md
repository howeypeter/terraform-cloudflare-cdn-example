# Cloudflare Terraform

Cloudflare configuration for `cambrera.net`, managed with the
[Cloudflare Terraform provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs) (v5).
The requirements it implements are in [docs/requirements.md](docs/requirements.md).

## Contents

- [Repository layout](#repository-layout)
- [Requirements](#requirements)
- [Credentials](#credentials)
- [State storage](#state-storage)
- [Working in a stack](#working-in-a-stack)
- [Deploying changes](#deploying-changes)
- [Stack status](#stack-status)
- [Regenerating the module docs](#regenerating-the-module-docs)
- [Module reference: tf_cdn](#module-reference-tf_cdn)
- [Module reference: tf_dns](#module-reference-tf_dns)
- [Module reference: tf_zerotrust](#module-reference-tf_zerotrust)

## Repository layout

Each folder under `infra/` is a separate Terraform root ("stack") with its own state.

| Path | What it is |
|---|---|
| `data_references/` | Read-only lookups for account, zone, DNS record, ruleset, and list IDs (all zones, no setup). See its [README](data_references/README.md). |
| `docs/` | Requirements ([requirements.md](docs/requirements.md)), the draft tunnel topology ([topology.md](docs/topology.md)), and the origin lockdown proposal ([origin-lockdown.md](docs/origin-lockdown.md)). |
| `infra/bootstrap/` | Creates the CI API token and its permissions. Run by hand. See its [README](infra/bootstrap/README.md). |
| `infra/common/` | Shared, account-level configuration, and the `cambrera.net` zone and its DNS records. |
| `infra/www_svc/` | The app's CDN configuration: calls `tf_cdn` (`www.cambrera.net` proxied to `www-origin.cambrera.net`; `cambrera.net` and `http://` 301 to `https://www.cambrera.net`). |
| `infra/tunnel_svc/` | Cloudflare Tunnel for `tunnel.cambrera.net` (connector: `cloudflared` next to the www app) and its token in SSM. |
| `infra/zero_trust/` | Zero Trust: login methods (Google, One-time PIN), and next Access for `tunnel.cambrera.net/secure`. |
| `tf_dns/` | Module: a zone and its DNS records. Used by `infra/common`. |
| `tf_cdn/` | Module: CDN configuration for proxied hostnames. So far the orange proxy (proxied CNAMEs), Always Use HTTPS, Full (strict), minimum TLS 1.3, and a canonical-host redirect. Used by `infra/www_svc`. |
| `infra_aws/` | AWS: the origin (`http-echo` on Elastic Beanstalk behind an ALB, HTTPS only on 443) and its ACM certificate for `www-origin.cambrera.net`. See its [README](infra_aws/README.md). |
| `.terraform-version`, `.tool-versions` | Pinned Terraform version for tfenv/tfswitch and asdf/mise. |

## Requirements

- **Terraform 1.17 or later** (enforced by `required_version`). Install with Homebrew, tfenv/tfswitch (reads
  `.terraform-version`), or asdf/mise (reads `.tool-versions`).
- **Cloudflare provider v5** (`~> 5.28`), pinned in each stack. v5 is a rewrite of v4; v4 examples found online
  won't work as-is.
- **AWS credentials** for the S3 state bucket (see [State storage](#state-storage)).

## Credentials

| Stack | Cloudflare credential | Where it comes from |
|---|---|---|
| `infra/bootstrap` | Global API Key (`CLOUDFLARE_API_KEY` + `CLOUDFLARE_EMAIL`), or a token that can create tokens | An admin, by hand |
| Every other stack | `CLOUDFLARE_API_TOKEN` | The CI token created by `infra/bootstrap` |
| `data_references` | `CLOUDFLARE_API_TOKEN` | A read-only token (recommended), or the CI token |

1. **Once:** run `infra/bootstrap` to create the CI token (`cambrera-cloudflare-ci`). It defines exactly what the
   token may do. See [infra/bootstrap/README.md](infra/bootstrap/README.md).
2. **CI:** store the token as the `CLOUDFLARE_API_TOKEN` secret.
3. **Locally:** put it in the stack's `.env` (copy `.env.example`; gitignored) and load it from that folder:

   ```bash
   set -a; source <(tr -d '\r' < .env); set +a   # Git Bash (strips Windows line endings)
   ```

   ```powershell
   Get-Content .env | Where-Object { $_ -match '^\s*([^#=]+)=(.*)$' } |
     ForEach-Object { Set-Item "env:$($matches[1].Trim())" $matches[2].Trim() }
   ```

- **Missing permission:** an authentication error (code 10000) in a stack means the token lacks a permission for that
  product. Add it in `infra/bootstrap` (see
  [Adding a permission](infra/bootstrap/README.md#adding-a-permission)).
- **Never commit** a token, `.env`, `terraform.tfvars`, or a state file. `.gitignore` excludes them.

## State storage

| Setting | Value |
|---|---|
| Backend | AWS S3, bucket `cambrera-prod-tf-state` (us-west-2) |
| Key | `cloudflare/infra/<stack>/terraform.tfstate`, one per stack (`infra_aws`: `aws/infra_aws/terraform.tfstate`) |
| Bucket settings | Versioned (any earlier state can be restored), encrypted, public access blocked |
| Locking | S3-native (`use_lockfile`); no DynamoDB table |
| Credentials | Standard AWS chain: environment variables, `AWS_PROFILE`, SSO, or the default profile |

- **New stack:** add the `backend "s3"` block with a unique `key`, then `terraform init`.
- **Changed backend:** `terraform init -migrate-state`.
- **Why not Cloudflare R2:** it works through the `s3` backend, but has no object versioning, so a bad write can't be
  rolled back.

## Working in a stack

```bash
cd infra/<stack>
cp .env.example .env                           # set CLOUDFLARE_API_TOKEN, then load it (see Credentials)
cp terraform.tfvars.example terraform.tfvars   # if the stack has one; set your values
terraform init
terraform plan
terraform apply
```

## Deploying changes

Cloudflare has no staging network: an apply changes the live configuration within seconds.

- **Review the plan.** For rulesets, `plan` also validates the rules with the Cloudflare API (dry run).
- **In CI:** save the plan (`terraform plan -out=tfplan`) and apply exactly that file.
- **Roll back:** revert the commit and apply. State history is in the versioned S3 bucket.

## Stack status

| Stack | Status |
|---|---|
| `infra/bootstrap` | Applied. CI token in place. |
| `infra/common` | Applied. Zone `cambrera.net` managed through the `tf_dns` module (`dns_zone_cambrera_net.tf`): email records (null MX, SPF, DMARC), CAA (Let's Encrypt and ACM may issue, no wildcards), and `www-origin` (CNAME to the Beanstalk ALB, DNS only) with its ACM validation CNAME. |
| `infra/www_svc` | Applied. Through `tf_cdn`: `www.cambrera.net` proxied to `www-origin`; `cambrera.net` (proxied) and `http://` 301 to `https://www.cambrera.net`; Full (strict), Always Use HTTPS, minimum TLS 1.3. |
| `infra/zero_trust` | Written, not applied: Google and One-time PIN login methods (needs Zero Trust enabled and the Google OAuth client in `terraform.tfvars`). |
| `infra_aws` | Applied. http-echo on Beanstalk, ALB on 443 only (port 80 off) with one ACM certificate for `www-origin.cambrera.net` (SANs `www.cambrera.net`, `cambrera.net`). Reached through Cloudflare as `www.cambrera.net`; the ALB accepts HTTPS only from Cloudflare's IPv4 ranges (fetched from cloudflare.com/ips-v4), so direct access to `www-origin` is refused. |

## Regenerating the module docs

The module references below are generated by [terraform-docs](https://terraform-docs.io).
After changing `tf_cdn/` or `tf_dns/`, regenerate them:

`bash
cd tf_cdn
terraform-docs .

cd ../tf_dns
terraform-docs .
`

## Module reference: tf_cdn

<!-- BEGIN_TF_DOCS_CDN -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.28 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_dns_record.proxied](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_ruleset.redirects](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_tiered_cache.tiered_cache](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tiered_cache) | resource |
| [cloudflare_zone_setting.optimization](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_setting) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID (32 hex characters) the records are created in. | `string` | n/a | yes |
| <a name="input_canonical_redirect"></a> [canonical\_redirect](#input\_canonical\_redirect) | One canonical URL for the site: every request to an alias (http or https), and every plain-http request to the<br/>canonical hostname, gets a redirect to https://<hostname> with the same path and query string, in one hop at<br/>Cloudflare's edge. E.g. hostname = "www.cambrera.net", aliases = ["cambrera.net"]. All of them must be proxied<br/>(proxied\_records). null = no redirect. | <pre>object({<br/>    hostname    = string<br/>    aliases     = list(string)<br/>    status_code = optional(number, 301)<br/>  })</pre> | `null` | no |
| <a name="input_cdn_min_tls_version"></a> [cdn\_min\_tls\_version](#input\_cdn\_min\_tls\_version) | Oldest TLS version visitors may use to connect to Cloudflare's edge (zone-wide). 1.3 refuses TLS 1.0-1.2 clients. | `string` | `"1.3"` | no |
| <a name="input_cdn_ssl_mode"></a> [cdn\_ssl\_mode](#input\_cdn\_ssl\_mode) | How Cloudflare connects to origins (zone-wide SSL/TLS encryption mode). strict = Full (strict): HTTPS, and the<br/>origin's certificate must be valid for the visitor's hostname (publicly trusted or Cloudflare Origin CA, not<br/>expired). full = HTTPS without checking the certificate. flexible = HTTP to the origin. off = no HTTPS at all. | `string` | `"strict"` | no |
| <a name="input_cdn_tiered_cache"></a> [cdn\_tiered\_cache](#input\_cdn\_tiered\_cache) | Enable Tiered Caching (on/off) to route edge cache misses through regional Upper-Tier super-PoPs. | `string` | `"on"` | no |
| <a name="input_proxied_records"></a> [proxied\_records](#input\_proxied\_records) | Orange-cloud hostnames, keyed by a stable name (the key is the record's Terraform address: renaming it replaces<br/>the record). Each is a proxied CNAME: visitors get Cloudflare's IPs, and Cloudflare connects to content (the<br/>origin's hostname). name: a label ("www") or the full name ("www.cambrera.net"). comment: start with the ticket. | <pre>map(object({<br/>    name    = string<br/>    content = string<br/>    comment = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_proxied_records"></a> [proxied\_records](#output\_proxied\_records) | Proxied records (key => ID, full name, origin). |
| <a name="output_redirects_ruleset_id"></a> [redirects\_ruleset\_id](#output\_redirects\_ruleset\_id) | ID of the redirects ruleset (null when canonical\_redirect is null). |
<!-- END_TF_DOCS_CDN -->

## Module reference: tf_dns

<!-- BEGIN_TF_DOCS_DNS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.28 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_dns_record.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone) | resource |
| [cloudflare_accounts.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/accounts) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | The zone (domain), e.g. cambrera.net. | `string` | n/a | yes |
| <a name="input_resource_records"></a> [resource\_records](#input\_resource\_records) | DNS records in the zone, keyed by a stable name (the key is the record's Terraform address: renaming it replaces<br/>the record). name: "@" for the apex, a label ("www"), or the full name ("www.cambrera.net"). ttl: defaults to<br/>1 = automatic (300s), otherwise 60-86400 seconds (proxied records are always automatic). priority: MX only.<br/>proxied: A/AAAA/CNAME only.<br/>TXT content must be quoted, e.g. "\"v=spf1 ... ~all\"". Set content for every type except CAA, which takes<br/>data = { flags = 0, tag = "issue", value = "letsencrypt.org" } instead. | <pre>map(object({<br/>    name    = string<br/>    type    = string<br/>    content = optional(string)<br/>    data = optional(object({<br/>      flags = number<br/>      tag   = string<br/>      value = string<br/>    }))<br/>    ttl      = optional(number, 1)    # 1 = automatic (300s unless proxied)<br/>    priority = optional(number, null) # MX only<br/>    proxied  = optional(bool)<br/>    comment  = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_zone_type"></a> [zone\_type](#input\_zone\_type) | full: Cloudflare is the authoritative DNS (nameservers changed at the registrar). partial: CNAME setup (Business plan and up). secondary: Enterprise only. | `string` | `"full"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The account that owns the zone. |
| <a name="output_resource_records"></a> [resource\_records](#output\_resource\_records) | DNS records managed by this module (key => ID, full name, type, content). |
| <a name="output_zone"></a> [zone](#output\_zone) | The zone's ID, status (pending until the registrar points at name\_servers, then active), and the nameservers to set at the registrar. |
<!-- END_TF_DOCS_DNS -->

<!-- BEGIN_TF_DOCS_ZEROTRUST -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.28 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_zero_trust_gateway_policy.policy](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_gateway_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID (32 hex characters). | `string` | n/a | yes |
| <a name="input_gateway_policies"></a> [gateway\_policies](#input\_gateway\_policies) | Map of Cloudflare Zero Trust Gateway policies (DNS, HTTP, Network) configured via for\_each.<br/>Keys are stable identifiers. Each policy requires name, action, filters, traffic, and precedence. | <pre>map(object({<br/>    name        = string<br/>    description = optional(string)<br/>    action      = string<br/>    filters     = list(string)<br/>    traffic     = string<br/>    precedence  = number<br/>    enabled     = optional(bool, true)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_gateway_policies"></a> [gateway\_policies](#output\_gateway\_policies) | Configured Gateway policies (key => ID, name, action, precedence). |
<!-- END_TF_DOCS_ZEROTRUST -->

## Module reference: tf_zerotrust

<!-- BEGIN_TF_DOCS_ZEROTRUST -->
<!-- END_TF_DOCS_ZEROTRUST -->
