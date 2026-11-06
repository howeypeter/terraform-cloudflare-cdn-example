# data_references

Read-only lookups, to surface hard-to-find Cloudflare metadata, for reference. 
DNS record IDs, ruleset IDs, and list IDs. Use it to find an ID (e.g. for `terraform import`) or to check what Cloudflare actually has configured.

This dir is not intended to maintain Cloudflare resources. Rather, it is a discovery tool to find internal data structures.

| File | Contents |
|---|---|
| `.env.example` | Template for the Cloudflare credential (`.env`) |
| `config.tf` | Version pins, S3 backend, provider |
| `data.tf` | The lookups: account, zones, and per-zone DNS records and rulesets |
| `outputs.tf` | The results |

## Outputs

| Output | Contents |
|---|---|
| `account` | The account's ID and name |
| `zones` | Per zone: ID, status, and the nameservers to set at the registrar |
| `dns_records` | Per zone: DNS records with IDs |
| `rulesets` | Per zone: rulesets with phase and ID (shows which phases already have rules) |
| `lists` | Account-level lists (IP Lists etc.) with IDs and item counts |
| `cloudflare_ip_ranges` | Cloudflare's edge IPv4 / IPv6 ranges, to allow at your origin |
| `logpush_jobs`, `logpush_fields` | Enterprise only; commented out in `data.tf` / `outputs.tf` |

Per-zone outputs are keyed by zone name, e.g. `dns_records["cambrera.net"]`.

## Credentials

- **Cloudflare:** `CLOUDFLARE_API_TOKEN`. A **read-only** token is recommended, since this folder only reads.
  The CI token from `infra/bootstrap` also works.
- **Read-only token permissions:**
  - Account: Account Settings Read, Account Rule Lists Read
  - Zone: Zone Read, DNS Read, and Read for the rules products you use (e.g. Zone WAF, Cache Settings)
  - Zone: Logs Read, only for the Logpush lookups (Enterprise)
  - `cloudflare_ip_ranges` is public and needs no permission.
- **State:** AWS S3, key `cloudflare/data_references/terraform.tfstate`; see the root README (State storage).

Copy `.env.example` to `.env` (gitignored; never commit it) and load it from this folder:

```bash
set -a; source <(tr -d '\r' < .env); set +a   # Git Bash (strips Windows line endings)
```

```powershell
Get-Content .env | Where-Object { $_ -match '^\s*([^#=]+)=(.*)$' } |
  ForEach-Object { Set-Item "env:$($matches[1].Trim())" $matches[2].Trim() }
```

## Usage

```bash
terraform init
terraform plan                      # shows the lookups under "Changes to Outputs"; saves nothing
terraform apply                     # saves the outputs to state
terraform output                    # read the saved outputs
terraform output -json rulesets     # one output as JSON (e.g. in CI)
```

- **Refresh:** outputs hold the values as of the last apply; run `terraform apply` again to update them.
- **`plan` vs `output`:** `plan` prints outputs only when their values change, so use `terraform output` to browse.
- **Logpush (Enterprise):** uncomment the lookups in `data.tf` and the outputs in `outputs.tf`. On other plans they
  fail with an authorization error.
