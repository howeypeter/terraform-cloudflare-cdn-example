# infra/zero_trust

Cloudflare Zero Trust services: Access self-hosted applications, SAML 2.0 SaaS SSO integration, WARP device enrollment, and Secure Web Gateway policies.

| File | Contents |
|---|---|
| `config.tf` | Version pins, S3 backend, and Cloudflare provider |
| `groups.tf` | Access user groups: `Testers` and `SaaS Users` |
| `self_hosted.tf` | Self-hosted Access application protecting `tunnel.cambrera.net/testers*` |
| `saas_app.tf` | SAML 2.0 SaaS application onboarding for MockSAML |
| `device_enrollment.tf` | WARP client onboarding and enrollment permissions |
| `gateway.tf` | Deploys Gateway DNS and HTTP policies via `tf_zerotrust` |
| `outputs.tf` | Exported URLs, Access application IDs, and policies |

<!-- BEGIN_TF_DOCS_ZERO_TRUST -->
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
| <a name="module_gateway"></a> [gateway](#module\_gateway) | ../../tf_zerotrust | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_zero_trust_access_application.samltest](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_application) | resource |
| [cloudflare_zero_trust_access_application.self_hosted_testers](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_application) | resource |
| [cloudflare_zero_trust_access_application.warp_device_enrollment](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_application) | resource |
| [cloudflare_zero_trust_access_group.saas_users](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_group) | resource |
| [cloudflare_zero_trust_access_group.testers](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_group) | resource |
| [cloudflare_zero_trust_access_identity_provider.google](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_identity_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID (32 hex characters). | `string` | `"eedd707b4e658a58dff3f7d2933f5bb0"` | no |
| <a name="input_google_client_id"></a> [google\_client\_id](#input\_google\_client\_id) | Google OAuth client ID (optional if already configured in dashboard). | `string` | `null` | no |
| <a name="input_google_client_secret"></a> [google\_client\_secret](#input\_google\_client\_secret) | Google OAuth client secret (optional if already configured in dashboard). | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_gateway_policies"></a> [gateway\_policies](#output\_gateway\_policies) | Configured Gateway policies from tf\_zerotrust module |
| <a name="output_saas_users_group_id"></a> [saas\_users\_group\_id](#output\_saas\_users\_group\_id) | ID of the SaaS Users Access Group |
| <a name="output_samltest_app_id"></a> [samltest\_app\_id](#output\_samltest\_app\_id) | ID of the SAMLtest SaaS Application |
| <a name="output_samltest_idp_entity_id"></a> [samltest\_idp\_entity\_id](#output\_samltest\_idp\_entity\_id) | Cloudflare IdP Entity ID / Issuer for SAMLtest.id |
| <a name="output_samltest_sso_endpoint"></a> [samltest\_sso\_endpoint](#output\_samltest\_sso\_endpoint) | Cloudflare SSO login endpoint for SAMLtest.id |
| <a name="output_self_hosted_testers_app_id"></a> [self\_hosted\_testers\_app\_id](#output\_self\_hosted\_testers\_app\_id) | ID of the Self-Hosted Testers Access Application |
| <a name="output_testers_group_id"></a> [testers\_group\_id](#output\_testers\_group\_id) | ID of the Testers Access Group |
| <a name="output_warp_device_enrollment_app_id"></a> [warp\_device\_enrollment\_app\_id](#output\_warp\_device\_enrollment\_app\_id) | ID of the WARP Device Enrollment Access Application |
<!-- END_TF_DOCS_ZERO_TRUST -->
