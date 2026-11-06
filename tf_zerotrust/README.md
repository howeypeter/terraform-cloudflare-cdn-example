# tf_zerotrust

Module: Zero Trust policies and security rules for Cloudflare Gateway and Access.

| File | Contents |
|---|---|
| `versions.tf` | Version pins |
| `variables.tf` | Alphabetical module variables: `account_id`, `gateway_policies` |
| `gateway_policies.tf` | Declarative `for_each` loop managing Gateway policies (DNS, HTTP, Network) |
| `outputs.tf` | Configured Gateway policies |

<!-- BEGIN_TF_DOCS -->
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
<!-- END_TF_DOCS -->

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