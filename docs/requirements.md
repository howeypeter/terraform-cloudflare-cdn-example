# Assignment requirements and overlap

Two take-home exercises, both designed for Cloudflare's free tier:

- **Exercise 1, Application Services** (`Application_Services_Assignment.pdf`)
- **Exercise 2, Zero Trust** (`Zero_Trust_Services_Assignment.pdf`)

## Requirements map

The left column holds what **both** exercises need. Arrows point from a shared foundation to the exercise
requirements that depend on it. The dotted arrow marks something exercise 1 builds that exercise 2 can reuse.

```mermaid
flowchart LR
  subgraph BOTH["Both exercises"]
    direction TB
    S1["Cloudflare account (Free plan)"]
    S2["Domain on Cloudflare<br/>(Ex 1: activated via nameservers)"]
    S3["Zero Trust organization"]
    S4["SSO identity provider in Zero Trust"]
    S5["Self-hosted web app,<br/>reachable from the internet"]
    S6["Access applications + policies"]
    S7["Email-based allow rules"]
    S8["Written report"]
  end

  subgraph EX1["Exercise 1: Application Services only"]
    direction TB
    A1["Origin endpoint that returns<br/>all request headers in the body"]
    A2["Proxy origin traffic through Cloudflare"]
    A3["Full (strict) TLS with a<br/>non-Cloudflare certificate"]
    A4["Cloudflare Tunnel on tunnel.yourdomain"]
    A5["Lock tunnel.yourdomain/secure to<br/>you + @cloudflare.com"]
    A6["Block direct access to the origin IP"]
    A7["Worker (built with Wrangler) on /secure:<br/>EMAIL authenticated at TIMESTAMP from COUNTRY<br/>(HTML; COUNTRY links to /secure/COUNTRY)"]
    A8["/secure/COUNTRY returns the flag<br/>from a private R2 bucket, correct content type"]
    A9["Worker code in a public Git repo"]
    A10["Report: steps + screenshots, use cases,<br/>knowledge gaps, customer experience"]
  end

  subgraph EX2["Exercise 2: Zero Trust only"]
    direction TB
    Z1["Groups in the identity provider:<br/>Testers, SaaS Users"]
    Z2["Self-hosted app: only Testers<br/>+ admin@example.com allow list"]
    Z3["SaaS app using Cloudflare as its IdP:<br/>only SaaS Users + admin@example.com"]
    Z4["WARP client on your device;<br/>only the IdP group can enroll"]
    Z5["Gateway DNS: block Anonymizer + Malware<br/>(anonymizer / malware.testcategory.com)"]
    Z6["Gateway: block Entertainment,<br/>except Netflix / YouTube"]
    Z7["Report (PDF): summary, lessons and issues,<br/>best practices, questions;<br/>readable by non-technical stakeholders"]
  end

  S1 --> S2
  S1 --> S3
  S3 --> S4

  S2 --> A2
  S2 --> A4
  S5 --> A1
  S6 --> A5
  S4 --> A5
  S7 --> A5
  S6 --> A7
  S8 --> A10

  S4 --> Z1
  S5 --> Z2
  S6 --> Z2
  S7 --> Z2
  S6 --> Z3
  S7 --> Z3
  S3 --> Z4
  S3 --> Z5
  S3 --> Z6
  S8 --> Z7

  Z1 --> Z2
  Z1 --> Z3
  Z1 --> Z4
  A4 -.->|reuse: second hostname on the same tunnel| Z2

  classDef shared fill:#fff3e0,stroke:#f38020,color:#000
  classDef ex1 fill:#e3f2fd,stroke:#1565c0,color:#000
  classDef ex2 fill:#e8f5e9,stroke:#2e7d32,color:#000
  class S1,S2,S3,S4,S5,S6,S7,S8 shared
  class A1,A2,A3,A4,A5,A6,A7,A8,A9,A10 ex1
  class Z1,Z2,Z3,Z4,Z5,Z6,Z7 ex2
```

## Overlap in detail

| Shared requirement | Exercise 1 | Exercise 2 | Build once? |
|---|---|---|---|
| Cloudflare account (Free plan) | Pre-requisite 1 | Implied | Yes |
| Domain on Cloudflare | Pre-requisites 2 and 3 (nameservers changed, zone active) | Pre-requisite 6 | Yes: one active zone serves both |
| Zero Trust organization | Needed for the IdP and Access (steps 5 and 6) | Pre-requisite 1 | Yes |
| SSO identity provider | Step 5: "an SSO IdP of your choosing" | Pre-requisite 4, and the steps need **groups** (Testers, SaaS Users) | Yes: Okta covers both, if it sends groups |
| Self-hosted web app | Step 1: header-echo origin | Pre-requisite 2: "a hosted application that is internet accessible" | Yes: the same origin, a second hostname on the same tunnel |
| Access applications + policies | Step 6: `/secure` path | Self-hosted and SaaS apps | Same building blocks, separate apps |
| Email-based allow rules | You + `@cloudflare.com` | `admin@example.com` allow list | Same rule type (an email list can serve both) |
| Written report | Steps with screenshots, use cases, knowledge gaps, customer experience | Summary, lessons and issues, best practices, questions; PDF, non-technical audience | Separate reports, shared screenshots and diagrams |

Not shared, but worth noting:

- **Cloudflare Tunnel** is required only by exercise 1. Exercise 2's architecture diagram shows a tunnel in front of
  self-hosted apps but doesn't require one, so reusing it there is a design choice, not a requirement.
- **Public Git repo** is required only for the exercise 1 Worker code, but this repo holds both exercises, so keep
  everything in it free of secrets.
- **The reviewers' login:** exercise 1 allows `@cloudflare.com` users, who have no account in your identity provider.
  The `/secure` app also needs a login method they can use, such as the one-time PIN.
