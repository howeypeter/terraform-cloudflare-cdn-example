# Cloudflare Worker: Flag & Identity Service (`flag_worker`)

Microservice implementing Step 7 of the Cloudflare Application Services Assignment:
- Intercepts requests on `tunnel.cambrera.net/secure*`.
- Reads authenticated identity (`cf-access-authenticated-user-email`) and visitor country (`cf-ipcountry`).
- Serves dynamic HTML: `${EMAIL} authenticated at ${TIMESTAMP} from ${COUNTRY}`.
- Serves country flags from a private Cloudflare R2 bucket (`cambrera-prod-country-flags`) on `/secure/:country`.

## Features
- **Zero Trust Header Parsing**: Consumes edge authentication headers passed by Cloudflare Access.
- **Private R2 Binding**: Fetches flag SVGs using native worker bindings (`env.FLAGS_BUCKET.get()`) without public R2 exposure.
- **Graceful Fallback**: Automatically serves `default.svg` if an unseeded country code is visited.

## Development & Deployment

```bash
# Install dependencies
npm install

# Local development simulation
npx wrangler dev

# Deploy to Cloudflare Edge
npx wrangler deploy
```
