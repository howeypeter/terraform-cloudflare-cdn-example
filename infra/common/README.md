# infra/common

Shared, account-level configuration, the `cambrera.net` zone, and its primary DNS records.

| File | Contents |
|---|---|
| `config.tf` | Version pins, S3 backend, and Cloudflare provider configuration |
| `dns_zone_cambrera_net.tf` | Declares the `cambrera.net` zone and its zone-wide resource records (Null MX, SPF, DMARC, CAA, and origin CNAMEs) |

<!-- BEGIN_TF_DOCS_COMMON -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.28 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_dns_zone_cambrera_net"></a> [dns\_zone\_cambrera\_net](#module\_dns\_zone\_cambrera\_net) | ../../tf_dns | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_resource_records"></a> [resource\_records](#output\_resource\_records) | DNS records managed in this zone (key => ID, full name, type, content). |
| <a name="output_zone"></a> [zone](#output\_zone) | The zone's ID, status, and the nameservers (set these at the registrar). |
<!-- END_TF_DOCS_COMMON -->
