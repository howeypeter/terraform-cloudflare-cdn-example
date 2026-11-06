# bootstrap

Sets up the CI credentials and their permissions. It creates the Cloudflare API token (`cambrera-cloudflare-ci`)
that becomes `CLOUDFLARE_API_TOKEN` for every other stack (`common`, `www_svc`, `zero_trust`, ...), and defines
exactly what that token may do.

- **This folder:** run by hand with an admin credential (see [Credentials](#credentials)), rarely: the first time,
  when the token's permissions change, or when a zone is added. CI can't create or change its own token.
- **Every other folder:** uses the token from this folder as `CLOUDFLARE_API_TOKEN`, in CI and locally. See
  [Using the token](#using-the-token).

| File | Contents |
|---|---|
| `.env.example` | Template for the Cloudflare credentials (`.env`) |
| `config.tf` | Version pins, S3 backend, provider |
| `data.tf` | Read-only lookups: the account, its zones, and Cloudflare's permission catalog |
| `iam.tf` | The CI token and its permission lists (`ci_account_permissions`, `ci_zone_permissions`) |
| `outputs.tf` | Zone names, the permission catalog, and the token value |

## Credentials

### Cloudflare

This stack creates tokens, so it needs one of:

- **Global API Key:** `CLOUDFLARE_API_KEY` + `CLOUDFLARE_EMAIL`. Legacy and full-access, but the simplest option
  for the first run, when it isn't yet clear how to set up a token with granular permissions.
- **API token:** `CLOUDFLARE_API_TOKEN`, with User > API Tokens: Edit **and** every permission it grants
  (a token can't grant permissions it doesn't have).

Don't set both. To set them:

1. Copy `.env.example` to `.env` and fill it in (`.env` is gitignored; never commit it).
2. Restrict it: `chmod 600 .env`
3. Load it from this folder:

   ```bash
   set -a; source <(tr -d '\r' < .env); set +a   # Git Bash (strips Windows line endings)
   ```

   ```powershell
   Get-Content .env | Where-Object { $_ -match '^\s*([^#=]+)=(.*)$' } |
     ForEach-Object { Set-Item "env:$($matches[1].Trim())" $matches[2].Trim() }
   ```

Variables stay set for the shell session; start a new shell before switching stacks.

### State (AWS S3)

| Setting | Value |
|---|---|
| Bucket | `cambrera-prod-tf-state` (us-west-2) |
| Key | `cloudflare/infra/bootstrap/terraform.tfstate` |
| Bucket settings | Versioned, encrypted, public access blocked |
| Locking | S3-native (`use_lockfile`); no DynamoDB table |

- **Credentials:** the standard AWS chain (environment variables, `AWS_PROFILE`, SSO, or the default profile).
- **IAM permissions:**
  - `s3:ListBucket` on the bucket
  - `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on `cloudflare/*` (DeleteObject releases the lock)
- **After changing the backend:** run `terraform init -migrate-state`.

## Usage

```bash
terraform init
terraform plan
terraform apply
terraform output -raw ci_api_token   # the token value; see Using the token
```

## Using the token

Once the token is set up and its permissions are tuned, it's the credential for all other stacks:

1. Get the value: `terraform output -raw ci_api_token` (from this folder).
2. **CI:** store it as the `CLOUDFLARE_API_TOKEN` secret.
3. **Locally:** set `CLOUDFLARE_API_TOKEN` in the other stack's `.env` (e.g. `infra/www_svc/.env`) and load it there.
4. In those folders, set only `CLOUDFLARE_API_TOKEN`; not the Global API Key, which is for this folder only.

The secret doesn't change when permissions are updated (the token is updated in place), so there's nothing to
re-copy after an apply here. If a stack fails with an auth error (code 10000), add the missing permission here: see
[Adding a permission](#adding-a-permission).

## The CI token

- **Scope:**
  - The account: one account policy.
  - Every zone in it: one policy per zone. Zones are read at apply time, so re-apply after adding a zone.
- **Permissions:** listed by name in `iam.tf`, one list per scope, each with a comment on what it's for.
  - Names are only unique within a scope ("Logs Write" exists for accounts and zones).
  - Put each name in the list for its scope.
- **Deliberately not granted:**
  - API Tokens (CI can't create or widen tokens)
  - Account Settings Write, Memberships, Billing
  - Zone Write (CI can't add or delete zones)
- **Wrangler in CI:** set `CLOUDFLARE_ACCOUNT_ID`; otherwise Wrangler looks up the user, which the token can't read.

## Adding a permission

1. Find the exact name in the permission catalog (name => ID), which this stack outputs per scope:

   ```bash
   terraform output account_permission_groups   # names for ci_account_permissions
   terraform output zone_permission_groups      # names for ci_zone_permissions (keyed by zone)
   ```

   Search it:

   ```bash
   terraform output -json account_permission_groups | jq 'keys[] | select(test("Zero Trust"))'
   ```

   ```powershell
   (terraform output -json account_permission_groups | ConvertFrom-Json).PSObject.Properties.Name | Select-String "Zero Trust"
   ```

2. Add the name to the list for its scope in `iam.tf`, then `terraform plan` and `terraform apply`. The token is
   updated in place; its secret doesn't change.