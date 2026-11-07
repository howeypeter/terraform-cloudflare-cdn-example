# Cloudflare Solutions Engineering: Take-Home Deliverables

Production infrastructure-as-code repository implementing **Exercise 1 (Application Services)** and **Exercise 2 (Zero Trust Services)** for `cambrera.net` on the Cloudflare global network.

---

## Executive Deliverables & Final Reports

The formal technical reports and architecture diagrams for both exercises are located in the [`docs/`](docs/) directory:

- 📄 [**Application Services Deliverable Report (PDF)**](docs/Application_Services_Report.pdf)
  *DNSSEC, Universal SSL strict mode, CDN caching optimizations, custom Transform & Edge Redirect rulesets, and Cloudflare Tunnel origin integration.*
- 📄 [**Zero Trust Services Deliverable Report (PDF)**](docs/Zero_Trust_Services_Report.pdf)
  *Zero Trust Network Access (ZTNA) self-hosted app onboarding, SAML 2.0 SaaS SSO integration, WARP client enrollment, and Secure Web Gateway (SWG) security policies.*
- 📋 [**Assignment 1 Specification (PDF)**](docs/Application_Services_Assignment.pdf)
- 📋 [**Assignment 2 Specification (PDF)**](docs/Zero_Trust_Services_Assignment.pdf)

---

## Repository Architecture

This project is built using modular, production-ready Terraform (Cloudflare Provider v5) divided into decoupled root stacks and reusable modules:

```text
├── docs/                     # Final PDF reports, assignment briefs, and architecture graphics
├── code/
│   └── flag_svc/             # Cloudflare Worker + Private R2 country flag service
├── tf_cdn/                   # Reusable module: CDN caching, HTTP/3, 0-RTT, and canonical redirects
├── tf_dns/                   # Reusable module: Declarative DNS zone and record management
├── tf_tunnel/                # Reusable module: Cloudflare Zero Trust Tunnel (cloudflared)
├── tf_zerotrust/             # Reusable module: Cloudflare Gateway DNS & HTTP policies
├── infra/
│   ├── bootstrap/            # Creates the scoped CI API token (run once)
│   ├── common/               # Zone setup, DNSSEC, and primary DNS records
│   ├── flag_svc/             # Private R2 bucket and Worker deployment bindings
│   ├── tunnel_svc/           # Cloudflare Tunnel for tunnel.cambrera.net
│   ├── www_svc/              # Edge CDN optimizations, rulesets, and redirects for www
│   └── zero_trust/           # Access self-hosted apps, SaaS SSO, WARP enrollment, & Gateway
└── infra_aws/                # AWS EC2 & ALB origin infrastructure
```

---

## Core Components Summary

### 1. Application Services (`infra/common`, `infra/www_svc`, `infra/tunnel_svc`, `code/flag_svc`)
- **DNS & Security**: DNSSEC enabled, Strict SSL/TLS verification against AWS ACM certificates, CAA records, and Minimum TLS 1.3.
- **Edge Performance**: Tiered Caching (Upper-Tier super-PoPs), Polish (WebP lossless), Brotli, Early Hints (103), HTTP/3 with QUIC, and 0-RTT connection resumption.
- **Microservices & R2**: Edge Worker on `tunnel.cambrera.net/secure*` preloading and serving vector country flags from private R2 with edge cache acceleration (`caches.default`).
- **Origin Cloaking**: Complete origin infrastructure cloaking via `cloudflared` tunnel, bypassing the AWS ALB and neutralizing external port scans.

### 2. Zero Trust Services (`infra/zero_trust`, `tf_zerotrust`)
- **Self-Hosted Application**: `tunnel.cambrera.net/testers*` protected by Cloudflare Access with device-aware WARP-as-Auth and IdP group evaluation.
- **SaaS SSO**: SAML 2.0 integration configured with MockSAML (`shy-frog-17eb.cloudflareaccess.com`).
- **WARP Device Enrollment**: Zero Trust client enrollment secured with administrative approvals.
- **Gateway Policies**: Zero Trust Gateway enforcing DNS & HTTP security filtering against phishing, malware, and unauthorized categories.

---

## Quick Start & Verification

### Running Terraform Stacks
Each stack under `infra/` is independently managed with its own remote state:

```bash
cd infra/common
terraform init
terraform plan
```

### Module Documentation
Each module and stack directory contains its own auto-generated, isolated `README.md` produced via `terraform-docs`.
