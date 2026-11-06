# Cloudflare Zero Trust Gateway Module Call (Exercise 2)

module "gateway" {
  source     = "../../tf_zerotrust"
  account_id = var.account_id

  gateway_policies = {
    # 1. DNS Filtering Policy: Block Anonymizer and Malware traffic
    # Verified against: anonymizer.testcategory.com and malware.testcategory.com
    block_malware_anonymizers = {
      name        = "Block Malware and Anonymizers (DNS)"
      description = "Blocks Anonymizer (68) and Malware (117) categories per ZTNA requirements"
      action      = "block"
      filters     = ["dns"]
      precedence  = 100
      traffic     = "any(dns.security_category[*] in {68 117}) or dns.fqdn in {\"anonymizer.testcategory.com\" \"malware.testcategory.com\"}"
      enabled     = true
    }

    # 2. HTTP Filtering Policy: Block Entertainment sites except Netflix and YouTube
    block_entertainment_except_streaming = {
      name        = "Block Entertainment except Netflix and YouTube (HTTP)"
      description = "Blocks Entertainment category (92) while allowing Netflix and YouTube"
      action      = "block"
      filters     = ["http"]
      precedence  = 200
      traffic     = "any(http.request.uri.content_category[*] in {7 92}) and not (http.request.host in {\"youtube.com\" \"*.youtube.com\" \"netflix.com\" \"*.netflix.com\" \"*.googlevideo.com\"})"
      enabled     = true
    }
  }
}

# Safe state migration to prevent recreation of already applied policy
moved {
  from = cloudflare_zero_trust_gateway_policy.block_malware_anonymizers
  to   = module.gateway.cloudflare_zero_trust_gateway_policy.policy["block_malware_anonymizers"]
}
