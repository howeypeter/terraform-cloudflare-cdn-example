# Cloudflare Worker Deployment & Asset Release Pipeline
# Automates Step 7 of Cloudflare Application Services Assignment

$ErrorActionPreference = "Stop"

# 1. Load credentials from flag_svc .env if available
$envFile = Join-Path $PSScriptRoot "..\..\infra\flag_svc\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match '^\s*([^#=]+)=(.*)$' } | ForEach-Object {
        Set-Item "env:$($matches[1].Trim())" $matches[2].Trim()
    }
}

if (-not $env:CLOUDFLARE_API_TOKEN) {
    Write-Error "CLOUDFLARE_API_TOKEN is not set."
}

$env:CLOUDFLARE_ACCOUNT_ID = "eedd707b4e658a58dff3f7d2933f5bb0"
$bucketName = "cambrera-prod-country-flags"

# 2. Generate unique release timestamp build ID
$buildId = "build-" + (Get-Date -Format "yyyyMMdd-HHmmss")
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Releasing Worker Build: $buildId" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan

# 3. Package flags into build/$buildId/flags/ and upload to private R2
$buildDir = Join-Path $PSScriptRoot "build\$buildId\flags"
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$sourceFlagsDir = Join-Path $PSScriptRoot "flags"
Copy-Item (Join-Path $sourceFlagsDir "*") -Destination $buildDir -Force

$flagFiles = Get-ChildItem -Path $buildDir -Filter "*.svg"
foreach ($file in $flagFiles) {
    $r2Key = "$buildId/$($file.Name)"
    Write-Host "Uploading asset to R2: $r2Key..." -ForegroundColor Gray
    
    npx wrangler r2 object put "$bucketName/$r2Key" --file="$($file.FullName)" --content-type="image/svg+xml" --remote | Out-Null
}

Write-Host "All assets packaged into build/$buildId/flags/ and uploaded to private R2: $bucketName." -ForegroundColor Green

# 4. Deploy the Worker using Wrangler with the new BUILD_ID
Write-Host "Deploying Cloudflare Worker via Wrangler..." -ForegroundColor Yellow
npx wrangler deploy --var "BUILD_ID:$buildId"

Write-Host ""
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Verify endpoints:" -ForegroundColor Cyan
Write-Host "  Dynamic HTML: https://tunnel.cambrera.net/secure" -ForegroundColor White
Write-Host "  Country Flag: https://tunnel.cambrera.net/secure/US (redirects to $buildId/US.svg)" -ForegroundColor White
