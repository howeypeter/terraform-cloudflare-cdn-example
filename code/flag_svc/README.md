# Cloudflare Worker: Flag & Identity Service (`flag_worker`)

Microservice implementing Step 7 of the Cloudflare Application Services Assignment:
- Intercepts requests on `tunnel.cambrera.net/secure*`.
- Reads authenticated identity (`cf-access-authenticated-user-email`) and visitor country (`cf-ipcountry`).
- Serves dynamic HTML: `${EMAIL} authenticated at ${TIMESTAMP} from ${COUNTRY}`.
- Serves country flags from a private Cloudflare R2 bucket (`cambrera-prod-country-flags`) on `/secure/{country_code}` (for example `/secure/US` or `/secure/CA`).

## Architecture & Cache Strategy

### 1. Cache-Control & Cacheability Matrix
To maximize performance while protecting sensitive session data, the service applies two contrasting caching models:

| Endpoint | Cache-Control Header | Cacheability Strategy | Reason |
|---|---|---|---|
| `/secure` | `no-store, no-cache, must-revalidate` | **Uncacheable (Dynamic)** | Protects user-specific identity, session timestamps, and Access tokens from being stored in shared edge or browser caches. |
| `/secure/{buildId}/{country}.svg` | `public, max-age=31536000, s-maxage=31536000, immutable` | **100% Cacheable (Edge & Browser)** | Content is permanently addressable by release build prefix and cached across Cloudflare edge PoPs. |
| `/secure/headers` | Upstream origin pass-through | **Uncacheable (Diagnostic)** | Relies on origin tunnel headers to display real-time request headers. |

### 2. Tiered Caching & Origin Protection
When an asset is not yet cached at a local edge PoP:
- **Tiered Cache Topology**: Requests route through regional Upper-Tier super-PoPs before reaching storage, consolidating cache misses across the network.
- **R2 Origin Shielding**: Reduces repetitive reads against the R2 bucket across geographically adjacent PoPs, ensuring hot assets stay pinned in upper-tier caches even when evicting from smaller edge PoPs.

### 2. Dual Preload Strategy (Performance Optimization)
When a user loads the dynamic `/secure` page, the Worker inspects the visitor's country and triggers proactive background pre-fetching of the flag asset:
- **HTTP `Link` Header**: Emits `Link: </secure/{buildId}/{country}.svg>; rel=preload; as=image` on the initial response, enabling Cloudflare Early Hints (103) and browser socket pipelining.
- **HTML `<link rel="preload">`**: Injects `<link rel="preload" href="/secure/{buildId}/{country}.svg" as="image" type="image/svg+xml">` in the HTML `<head>`.
- **Result**: Because the SVG is both preloaded and marked `immutable`, the flag renders instantaneously without layout shift or network delay when the user clicks the link.

### 3. Zero Trust Identity & Upstream Tunnel Routing
- **Zero Trust Header Parsing**: Consumes edge authentication headers passed by Cloudflare Access (`cf-access-authenticated-user-email`).
- **Private R2 Binding**: Fetches flag SVGs using native worker bindings (`env.FLAGS_BUCKET.get()`) without public R2 exposure.
- **Graceful Fallback**: Automatically serves `default.svg` within the same build ID if an unseeded country code is requested.

## Directory Structure

- `src/index.js`: Worker entrypoint handling `/secure`, `/secure/{country_code}`, `/secure/headers`, and release asset paths `/secure/{buildId}/{country_code}.svg`.
- `flags/`: Canonical source vector SVG assets (`US.svg`, `CA.svg`, `GB.svg`, `default.svg`, and 270+ worldwide country flags).
- `wrangler.jsonc`: Wrangler configuration including route patterns, R2 bucket bindings, and build variables.
- `deploy.ps1` / `deploy.sh`: Automated release pipeline that syncs flags from `flags/` into R2 with a timestamped build prefix and deploys the Worker via Wrangler.

## Development & Deployment

```bash
# Install dependencies
npm install

# Local development simulation
npx wrangler dev

# Full deployment (uploads flag assets to R2 and deploys Worker)
npm run deploy

# Worker-only deployment (when flag assets have not changed)
npm run deploy:worker-only
```
