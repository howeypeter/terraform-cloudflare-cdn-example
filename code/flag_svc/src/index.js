/**
 * Cloudflare Worker: Flag & Identity Service
 * Application Services Assignment (Step 7)
 * 
 * Features:
 * - Granular Zero Trust Access identity parsing (cf-access-authenticated-user-email)
 * - Dual Preload Optimization: HTTP Link header + HTML <link rel="preload">
 * - Release Prefix Caching: Immutable 1-year cache headers on /secure/:buildId/:country.svg
 * - Upstream Proxying: /secure/headers reflects origin headers with Zero Trust auth headers
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const pathname = url.pathname.replace(/\/+$/, ""); // normalize trailing slash
    const buildId = env.BUILD_ID || "build-20261106-124628";

    // 1. View Headers (With Authentication): /secure/headers
    // Passes through to the Cloudflare Tunnel origin to echo all headers (including Access auth headers)
    if (pathname === "/secure/headers") {
      return fetch(request);
    }

    // 2. Direct release asset path: /secure/:buildId/:country.svg
    // E.g. /secure/build-20261106-124628/US.svg
    const assetMatch = pathname.match(/^\/secure\/([A-Za-z0-9_-]+)\/([A-Za-z0-9_-]+\.svg)$/i);
    if (assetMatch) {
      const requestedBuild = assetMatch[1];
      const filename = assetMatch[2];
      const r2Key = `${requestedBuild}/${filename}`;

      // Retrieve directly from private R2 bucket
      let object = await env.FLAGS_BUCKET.get(r2Key);
      if (!object) {
        // Fallback to default asset within the same release
        object = await env.FLAGS_BUCKET.get(`${requestedBuild}/default.svg`);
      }

      if (!object) {
        return new Response(`Asset ${r2Key} not found in R2 storage`, {
          status: 404,
          headers: { "Content-Type": "text/plain" }
        });
      }

      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set("Content-Type", "image/svg+xml");
      
      // Professional Services Immutable Caching
      headers.set("Cache-Control", "public, max-age=31536000, immutable");
      headers.set("X-Cache-Strategy", "Immutable-Release-Prefix");

      if (object.httpEtag) {
        headers.set("ETag", object.httpEtag);
      }

      return new Response(object.body, { headers });
    }

    // 3. Canonical Country path: /secure/:country (Step 7.c requirement)
    // E.g. /secure/US -> Redirects to /secure/build-20261106-124628/US.svg
    const countryMatch = pathname.match(/^\/secure\/([A-Za-z]{2,3})$/i);
    if (countryMatch) {
      const countryCode = countryMatch[1].toUpperCase();
      const targetUrl = new URL(`/secure/${buildId}/${countryCode}.svg`, request.url);
      return Response.redirect(targetUrl.toString(), 302);
    }

    // 4. Dynamic HTML Wrapper: /secure (Step 7.a & 7.b)
    if (pathname === "/secure") {
      // Authenticated identity passed by Cloudflare Zero Trust Access
      const email = request.headers.get("cf-access-authenticated-user-email") || "candidate@cambrera.net";

      // Visitor country detected by Cloudflare Anycast edge
      const country = request.cf?.country || request.headers.get("cf-ipcountry") || "US";

      // Current UTC timestamp
      const timestamp = new Date().toUTCString();

      // Asset target for preloading
      const assetUrl = `/secure/${buildId}/${country}.svg`;

      const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cloudflare Zero Trust - Authenticated User</title>
  
  <!-- Dual Preload Strategy: Browser downloads the flag in the background before the link is clicked -->
  <link rel="preload" href="${assetUrl}" as="image" type="image/svg+xml">

  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #0f172a;
      color: #f8fafc;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 1.5rem;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 2.5rem;
      max-width: 680px;
      width: 100%;
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5), 0 8px 10px -6px rgba(0, 0, 0, 0.5);
      text-align: center;
    }
    .badge {
      display: inline-block;
      background: rgba(243, 128, 32, 0.15);
      color: #f38020;
      border: 1px solid rgba(243, 128, 32, 0.3);
      padding: 0.35rem 0.85rem;
      border-radius: 9999px;
      font-size: 0.8rem;
      font-weight: 700;
      margin-bottom: 1.25rem;
      letter-spacing: 0.05em;
      text-transform: uppercase;
    }
    .auth-statement {
      font-size: 1.25rem;
      line-height: 1.7;
      margin: 0 0 1.5rem 0;
      color: #e2e8f0;
    }
    .country-link {
      color: #f38020;
      text-decoration: underline;
      font-weight: 700;
      padding: 0.2rem 0.4rem;
      border-radius: 4px;
      transition: background 0.2s;
    }
    .country-link:hover {
      background: rgba(243, 128, 32, 0.2);
    }
    .preview-box {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 1rem;
      background: rgba(15, 23, 42, 0.6);
      border: 1px solid #334155;
      border-radius: 10px;
      padding: 0.75rem 1.25rem;
      margin: 1.25rem auto;
      max-width: 320px;
    }
    .flag-thumbnail {
      width: 48px;
      height: 30px;
      object-fit: cover;
      border-radius: 4px;
      border: 1px solid #475569;
      box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    }
    .preview-text {
      font-size: 0.85rem;
      color: #94a3b8;
      text-align: left;
    }
    .preview-text strong {
      color: #f8fafc;
      display: block;
    }
    .actions-grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 0.85rem;
      margin-top: 1.5rem;
    }
    @media (min-width: 540px) {
      .actions-grid {
        grid-template-columns: 1fr 1fr;
      }
      .actions-grid .btn-full {
        grid-column: span 2;
      }
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
      padding: 0.85rem 1.25rem;
      border-radius: 8px;
      font-size: 0.95rem;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.2s ease;
      cursor: pointer;
    }
    .btn-primary {
      background: #f38020;
      color: #ffffff;
      border: 1px solid #f38020;
    }
    .btn-primary:hover {
      background: #e26f12;
      border-color: #e26f12;
      box-shadow: 0 4px 12px rgba(243, 128, 32, 0.3);
    }
    .btn-secondary {
      background: #334155;
      color: #f8fafc;
      border: 1px solid #475569;
    }
    .btn-secondary:hover {
      background: #475569;
      border-color: #64748b;
    }
    .btn-outline {
      background: transparent;
      color: #94a3b8;
      border: 1px solid #334155;
    }
    .btn-outline:hover {
      background: rgba(51, 65, 85, 0.5);
      color: #f8fafc;
      border-color: #64748b;
    }
    .divider {
      height: 1px;
      background: #334155;
      margin: 1.5rem 0;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">Zero Trust Access Verified</div>
    
    <!-- Required format: Step 7.b & 7.c -->
    <p class="auth-statement">
      ${email} authenticated at ${timestamp} from <a href="/secure/${country}" class="country-link">${country}</a>
    </p>

    <!-- Inline Preview with Preloaded Vector -->
    <div class="preview-box">
      <img src="${assetUrl}" alt="${country} Flag" class="flag-thumbnail">
      <div class="preview-text">
        <strong>Detected: ${country}</strong>
        Preloaded via Edge Cache
      </div>
    </div>

    <div class="divider"></div>

    <div class="actions-grid">
      <!-- Action 1: View Flag -->
      <a href="/secure/${country}" class="btn btn-primary btn-full">
        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"></path></svg>
        View Standalone Flag (${country})
      </a>

      <!-- Action 2: View Headers (With Authentication) -->
      <a href="/secure/headers" class="btn btn-secondary">
        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.5L19 9.5V19a2 2 0 01-2 2z"></path></svg>
        View Headers (With Authentication)
      </a>

      <!-- Action 3: View Headers (No Auth Required) -->
      <a href="https://tunnel.cambrera.net/" class="btn btn-outline" target="_blank">
        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
        View Headers (No Auth Required)
      </a>
    </div>
  </div>
</body>
</html>`;

      return new Response(html, {
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          // Dynamic session wrapper is uncacheable
          "Cache-Control": "no-store, no-cache, must-revalidate",
          // HTTP Link Header Preload (Cloudflare 103 Early Hints compatible)
          "Link": `<${assetUrl}>; rel=preload; as=image`
        }
      });
    }

    // Default fallback
    return new Response("Not Found", { status: 404 });
  }
};
