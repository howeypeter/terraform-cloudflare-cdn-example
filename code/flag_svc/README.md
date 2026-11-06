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

## Package & Build Structure

- `src/index.js`: Worker entrypoint handling `/secure`, `/secure/:country`, and `/secure/:buildId/:country.svg`.
- `flags/`: Canonical source vector SVG assets (`US.svg`, `CA.svg`, `GB.svg`, `default.svg`).
- `build/<buildID>/flags/`: Release-packaged flag assets stamped with the active release build ID and uploaded to the private R2 bucket (`cambrera-prod-country-flags`).
- `wrangler.jsonc`: Wrangler configuration including route pattern, R2 bucket bindings, and build variables.
- `deploy.ps1` / `deploy.sh`: Release automation script creating the versioned build package, uploading to R2, and deploying to Cloudflare Edge.

## Development & Deployment

```bash
# Install dependencies
npm install

# Local development simulation
npx wrangler dev

# Deploy to Cloudflare Edge
npx wrangler deploy
```
