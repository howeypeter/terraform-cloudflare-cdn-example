output "www_origin_validation_records" {
  description = "DNS validation CNAMEs for the www-origin certificate; keep them in Cloudflare (DNS only) for renewal."
  value       = aws_acm_certificate.www_origin.domain_validation_options
}
