# Proposal: lock the origin ALB to Cloudflare

Exercise 1, step 6: "Ensure nobody can bypass Cloudflare and access your server's IP directly." Option A chosen; see
[Decision](#decision). See [topology.md](topology.md).

## Where it stands (checked 2026-11-03)

| Piece | Exposure today |
|---|---|
| ALB (`www-origin.cambrera.net`) | Beanstalk-managed security group: **443 from `0.0.0.0/0`**. Anyone can call it directly, skipping Cloudflare (and its redirect, TLS 1.3 minimum, and later Access). |
| EC2 instance | Public IP (`3.219.216.131`, for outbound only), but its security group allows only port 80 **from the ALB's security group**, and there's no SSH key. Already closed. |

So the one door to close is the ALB.

## Two gaps to close

1. **The internet at large**: anything that isn't Cloudflare connecting to the ALB.
2. **Other Cloudflare accounts**: an IP allow list only proves a request came *through Cloudflare*, not through
   *your zone*. Anyone can point their own proxied record at the ALB's hostname, and Cloudflare will connect from the
   same IP ranges. Closing this needs something only your zone sends.

## Options

| | Closes | How | Cost / effort |
|---|---|---|---|
| **A. Security group: Cloudflare IPs only** | Gap 1 | Our own ALB security group allowing 443 only from Cloudflare's 15 IPv4 ranges (the ALB is IPv4-only), handed to Beanstalk (`aws:elbv2:loadbalancer` `SecurityGroups` + `ManagedSecurityGroup`) in place of its managed one | Free; small. The ranges change rarely, but have to be kept in sync ([cloudflare.com/ips](https://www.cloudflare.com/ips/)) |
| **B. Secret header, checked by AWS WAF** | Gap 2 | A Cloudflare Transform Rule (request header modification, Free plan) adds `X-Origin-Verify: <secret>` to every request to the origin; an AWS WAF web ACL on the ALB allows only requests carrying it, blocks the rest | About $6/month (web ACL + a rule). Attaches to the ALB without touching Beanstalk's listeners. The secret lives in Cloudflare and AWS (both via Terraform, so in state). |
| **B'. Secret header, checked by an ALB listener rule** | Gap 2 | Same header; an ALB listener rule forwards only when it matches, otherwise a fixed 403 | Free, but the listener belongs to Beanstalk: rules added outside it can drift or be reset on environment updates |
| **C. Authenticated Origin Pulls (mTLS)** | Gap 2 | Cloudflare presents a client certificate to the origin; the ALB verifies it (ALB mutual TLS with a trust store) | Zone-level pulls use a certificate shared by all Cloudflare customers (same weakness as IPs); a per-hostname certificate fixes that. Beanstalk doesn't expose ALB mTLS settings, so it means managing the listener outside Beanstalk. Most work. |
| **D. Tunnel only** | Both | Route `www` through the Cloudflare Tunnel (step 4) and make the ALB internal or remove it; nothing is reachable from the internet | Strongest, but it changes how steps 2 and 3 are shown (Full strict doesn't apply to tunnel traffic). Depends on the open tunnel decision in topology.md. |

## Decision

**A only** (2026-11-03): `infra_aws/www_security_group.tf`. The ranges are fetched on every plan from
[cloudflare.com/ips-v4](https://www.cloudflare.com/ips-v4/) (`http` data source; the plan stops if the response isn't a
list of CIDRs), so new Cloudflare ranges are picked up by the next plan and apply. B (the secret header) isn't planned; the "other
Cloudflare accounts" gap stays open, which is worth noting in the report.

## Recommendation (original)

**A + B**, in that order:

1. **A first**: it answers the step as written (direct access to the server's IP is refused) and is easy to show in
   the report: `curl https://www-origin.cambrera.net` times out, `https://www.cambrera.net` returns 200.
2. **Then B**: closes the "any Cloudflare account" gap, with WAF's block count as testing evidence. Skip it if the
   $6/month isn't worth it for the exercise; A alone meets the wording.

Revisit D when we decide the tunnel topology.

### What A would change

- `infra_aws`: a new `aws_security_group` for the ALB with 15 ingress rules (443 from each Cloudflare IPv4 range,
  hardcoded with a link to the source list) and egress to the instances; two Beanstalk settings
  (`aws:elbv2:loadbalancer` `SecurityGroups` and `ManagedSecurityGroup`) pointing at it. Beanstalk then grants the
  instances' port 80 from this group instead of its own.
- Effect: `www-origin.cambrera.net` stops answering from anywhere but Cloudflare (including from your own machine),
  so direct checks of the origin's certificate have to go through Cloudflare from then on.
- Applied in place by Beanstalk (an environment update, about a minute).
