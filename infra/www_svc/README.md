# infra/www_svc

Edge CDN optimizations, rulesets, and canonical host redirects for `www.cambrera.net` and `cambrera.net`.

| File | Contents |
|---|---|
| `config.tf` | Version pins, S3 backend, and Cloudflare provider |
| `cdn.tf` | Invokes `tf_cdn` to manage the proxied CNAMEs, Strict SSL/TLS, and 301 canonical redirects |

<!-- BEGIN_TF_DOCS_WWW_SVC -->
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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cdn"></a> [cdn](#module\_cdn) | ../../tf_cdn | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_accounts.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/accounts) | data source |
| [cloudflare_zones.all](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zones) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_proxied_records"></a> [proxied\_records](#output\_proxied\_records) | Proxied records (key => ID, full name, origin). |
| <a name="output_redirects_ruleset_id"></a> [redirects\_ruleset\_id](#output\_redirects\_ruleset\_id) | ID of the canonical-host redirects ruleset. |
<!-- END_TF_DOCS_WWW_SVC -->
