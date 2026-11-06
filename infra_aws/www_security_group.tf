# The ALB's security group: HTTPS only from Cloudflare, so nobody can skip Cloudflare (its redirect, TLS 1.3
# minimum, and later Access) by calling the ALB directly. Replaces the group Beanstalk would create (www_origin.tf,
# aws:elbv2:loadbalancer); Beanstalk still lets this group reach the instances on port 80.
#
# This closes direct access from the internet. It doesn't prove a request came through *this* zone: another
# Cloudflare account could point its own proxied record here (see docs/origin-lockdown.md).

# Cloudflare's IPv4 ranges, fetched on every plan from Cloudflare's published list (plain text, one CIDR per line).
# The ALB is IPv4 only, so the IPv6 list isn't needed. If the fetch fails or returns something that isn't a list of
# CIDRs, the plan stops here rather than rewriting the rules from bad data.
data "http" "cloudflare_ipv4" {
  url = "https://www.cloudflare.com/ips-v4/"

  request_headers = {
    Accept = "text/plain"
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Fetching https://www.cloudflare.com/ips-v4/ failed (HTTP ${self.status_code})."
    }
    postcondition {
      condition = (
        length(compact(split("\n", trimspace(self.response_body)))) >= 10 &&
        alltrue([for c in compact(split("\n", trimspace(self.response_body))) : can(cidrhost(trimspace(c), 0))])
      )
      error_message = "https://www.cloudflare.com/ips-v4/ didn't return a list of IPv4 CIDRs (at least 10)."
    }
  }
}

locals {
  cloudflare_ipv4 = toset([for c in compact(split("\n", trimspace(data.http.cloudflare_ipv4.response_body))) : trimspace(c)])
}

resource "aws_security_group" "alb" {
  name        = "${local.www_name}-alb"
  description = "www ALB: HTTPS from Cloudflare only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.www_name}-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_cloudflare" {
  for_each = local.cloudflare_ipv4

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from Cloudflare"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

# To the instances (HTTP on port 80, and health checks), inside the VPC.
resource "aws_vpc_security_group_egress_rule" "alb_to_vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "To the instances in the VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = local.vpc_cidr
}
