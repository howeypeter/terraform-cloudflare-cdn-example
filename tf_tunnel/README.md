# tf_tunnel

Reusable module: Cloudflare Zero Trust Tunnel (`cloudflared`) configuration.

Manages remote tunnel ingress rules, connector tokens, and automatic `http_status:404` catch-all routing.

| File | Contents |
|---|---|
| `versions.tf` | Cloudflare provider version constraints |
| `variables.tf` | Module variables: `account_id`, `name`, `ingress_rules`, and `config_src` |
| `tunnel.tf` | Declares `cloudflare_zero_trust_tunnel_cloudflared` and remote ingress configuration |
| `outputs.tf` | Exports `tunnel_id`, `tunnel_name`, `tunnel_cname`, and `tunnel_token` (sensitive) |

<!-- BEGIN_TF_DOCS_TF_TUNNEL -->
<!-- END_TF_DOCS_TF_TUNNEL -->

<!-- BEGIN_TF_DOCS_TUNNEL -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | >= 5.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 5.28 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_zero_trust_tunnel_cloudflared.tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared_config.tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared_config) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared_token.tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zero_trust_tunnel_cloudflared_token) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Cloudflare tunnel. | `string` | n/a | yes |
| <a name="input_config_src"></a> [config\_src](#input\_config\_src) | Configuration source for the tunnel (cloudflare or local). | `string` | `"cloudflare"` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | List of ingress rules mapping hostnames/paths to local service endpoints. | <pre>list(object({<br/>    hostname      = optional(string)<br/>    path          = optional(string)<br/>    service       = string<br/>    origin_request = optional(map(any))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_tunnel_cname"></a> [tunnel\_cname](#output\_tunnel\_cname) | CNAME target for DNS records pointing to this tunnel. |
| <a name="output_tunnel_id"></a> [tunnel\_id](#output\_tunnel\_id) | UUID of the Cloudflare tunnel. |
| <a name="output_tunnel_name"></a> [tunnel\_name](#output\_tunnel\_name) | Name of the Cloudflare tunnel. |
| <a name="output_tunnel_token"></a> [tunnel\_token](#output\_tunnel\_token) | Run token for the cloudflared connector. |
<!-- END_TF_DOCS_TUNNEL -->