# tf_dns

Module: a Cloudflare DNS zone and its resource records.

| File | Contents |
|---|---|
| `versions.tf` | Version pins |
| `variables.tf` | Alphabetical module variables: `resource_records`, `zone_name`, `zone_type` |
| `zone.tf` | The `cloudflare_zone` resource, owned by the account discovered via data source, with `prevent_destroy` protection |
| `dns_records.tf` | The `cloudflare_dns_record` resources for the zone |
| `outputs.tf` | The account ID, zone metadata (ID, status, name servers), and managed resource records |

Used by `infra/common`.

<!-- BEGIN_TF_DOCS_TF_DNS -->
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
<!-- END_TF_DOCS_TF_DNS -->
