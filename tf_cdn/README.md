# tf_cdn

Module: CDN configuration for a Cloudflare zone, i.e. what happens to traffic once a hostname is proxied (orange cloud): TLS between Cloudflare and the origin, caching, and request/response rules.

DNS records and the zone itself stay in [`tf_dns`](../tf_dns).

| File | Contents |
|---|---|
| `versions.tf` | Version pins |
| `variables.tf` | Alphabetical module variables: `canonical_redirect`, `cdn_min_tls_version`, `cdn_ssl_mode`, `cdn_tiered_cache`, `proxied_records`, `zone_id` |
| `proxied_records.tf` | The orange proxy: a proxied CNAME per hostname, to its origin |
| `zone_cdn_optimizations.tf` | Zone-wide edge optimizations: `cloudflare_zone_setting.optimization` (`for_each` map) and `cloudflare_tiered_cache.tiered_cache` |
| `redirects.tf` | Canonical-host redirect: aliases and http:// to https://<canonical>, one hop |
| `outputs.tf` | The proxied records and the redirects ruleset ID |

Used by `infra/www_svc`.

<!-- BEGIN_TF_DOCS_TF_CDN -->
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
<!-- END_TF_DOCS_TF_CDN -->
