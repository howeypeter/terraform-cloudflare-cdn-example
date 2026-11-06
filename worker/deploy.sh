#!/usr/bin/env bash
set -euo pipefail

# Cloudflare Worker Deployment & Asset Release Pipeline
# Automates Step 7 of Cloudflare Application Services Assignment

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# 1. Load credentials from flag_svc .env if available
if [[ -f "$DIR/../infra/flag_svc/.env" ]]; then
    set -a
    source <(tr -d '\r' < "$DIR/../infra/flag_svc/.env")
    set +a
fi

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "Error: CLOUDFLARE_API_TOKEN is not set." >&2
    exit 1
fi

export CLOUDFLARE_ACCOUNT_ID="eedd707b4e658a58dff3f7d2933f5bb0"
BUCKET_NAME="cambrera-prod-country-flags"

# 2. Generate unique release timestamp build ID
BUILD_ID="build-$(date -u +'%Y%m%d-%H%M%S')"
echo "============================================="
echo "  Releasing Worker Build: ${BUILD_ID}"
echo "============================================="

# 3. Upload build-stamped flag assets to private R2
FLAGS_DIR="$DIR/../flags"
for file in "$FLAGS_DIR"/*.svg; do
    filename=$(basename "$file")
    basename="${filename%.*}"
    stamped_name="${basename}-${BUILD_ID}.svg"
    echo "Uploading asset to R2: ${stamped_name}..."
    npx wrangler r2 object put "${BUCKET_NAME}/${stamped_name}" --file="$file" --content-type="image/svg+xml" --remote > /dev/null
done

echo "All assets uploaded to private R2 bucket: ${BUCKET_NAME}."

# 4. Deploy the Worker using Wrangler with the new BUILD_ID
echo "Deploying Cloudflare Worker via Wrangler..."
npx wrangler deploy --var "BUILD_ID:${BUILD_ID}"

echo ""
echo "Deployment Complete!"
echo "Verify endpoints:"
echo "  Dynamic HTML: https://tunnel.cambrera.net/secure"
echo "  Country Flag: https://tunnel.cambrera.net/secure/US (redirects to US-${BUILD_ID}.svg)"
