# infra/tunnel_svc

Cloudflare Tunnel (`cloudflared`) configuration for `tunnel.cambrera.net`.

The connector runs on the AWS EC2 instance, dials out to Cloudflare's Anycast edge over QUIC, and forwards requests to the application on `localhost:8080`, bypassing the public AWS ALB.

| File | Contents |
|---|---|
| `config.tf` | Version pins, S3 backend, Cloudflare and AWS providers |
| `tunnel.tf` | Manages `cambrera-prod-tunnel` via `tf_tunnel`, exports `tunnel_cname`, and writes token to AWS SSM Parameter Store |

<!-- BEGIN_TF_DOCS_TUNNEL_SVC -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.71 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.71 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.28 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_tunnel"></a> [tunnel](#module\_tunnel) | ../../tf_tunnel | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ssm_parameter.tunnel_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [cloudflare_accounts.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/accounts) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_tunnel_cname"></a> [tunnel\_cname](#output\_tunnel\_cname) | Target for the tunnel.cambrera.net CNAME (proxied) in infra/common. |
<!-- END_TF_DOCS_TUNNEL_SVC -->
