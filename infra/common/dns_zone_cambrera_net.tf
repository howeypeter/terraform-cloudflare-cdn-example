# Created in the dashboard and imported into this state. To re-import (e.g. into fresh state), find the zone ID in
# data_references output "zones", then: terraform import module.dns_zone_cambrera_net.cloudflare_zone.this <zone_id>
module "dns_zone_cambrera_net" {
  source    = "../../tf_dns"
  zone_name = "cambrera.net"

  # Record comments show in the dashboard; start each with its ticket (NET-xxx IDs here are examples).
  # Zone-wide records. Site hostnames (www, api, tunnel, ...) belong to the stacks that serve them.
  # Email: the domain neither receives nor sends mail.
  #   Null MX (RFC 7505): senders bounce immediately instead of falling back to the apex A record.
  #   SPF -all + DMARC reject: receivers reject mail spoofing @cambrera.net.
  resource_records = {
    mx_null = {
      name     = "@"
      type     = "MX"
      content  = "."
      priority = 0
      comment  = "NET-101: Null MX (RFC 7505): domain accepts no mail, so senders bounce at once"
    }
    txt_spf = {
      name    = "@"
      type    = "TXT"
      content = "\"v=spf1 -all\""
      comment = "NET-101: SPF -all: no server may send mail as @cambrera.net"
    }
    txt_dmarc = {
      name    = "_dmarc"
      type    = "TXT"
      content = "\"v=DMARC1; p=reject;\""
      comment = "NET-101: DMARC reject: receivers reject mail spoofing @cambrera.net"
    }

    # Certificates: only Let's Encrypt (origin certificates, DNS-01) and ACM may issue, and no CA may issue wildcards
    # (caa_no_wildcard). Cloudflare adds its own CAs to the answer automatically for Universal SSL (edge certificates),
    # including issuewild entries for its *.cambrera.net edge certificate, so they aren't listed; those still allow
    # Cloudflare's CAs (Let's Encrypt among them) to issue wildcards. Pin to one ACME account:
    # "letsencrypt.org; accounturi=https://...".
    caa_letsencrypt = {
      name = "@"
      type = "CAA"
      data = {
        flags = 0
        tag   = "issue"
        value = "letsencrypt.org"
      }
      comment = "NET-102: CAA: only Let's Encrypt (plus Cloudflare's own CAs) may issue certificates"
    }
    # AWS Certificate Manager (infra_aws: www-origin.cambrera.net). At the apex rather than on the host, since a
    # host that's a CNAME (e.g. to an ALB) can't also have a CAA record.
    caa_amazon = {
      name = "@"
      type = "CAA"
      data = {
        flags = 0
        tag   = "issue"
        value = "amazon.com"
      }
      comment = "NET-102: CAA: AWS Certificate Manager may also issue (infra_aws)"
    }
    caa_no_wildcard = {
      name = "@"
      type = "CAA"
      data = {
        flags = 0
        tag   = "issuewild"
        value = ";"
      }
      comment = "NET-102: CAA: no CA may issue wildcard certificates (Cloudflare adds its own for Universal SSL)"
    }

    # ACM DNS validation for the www-origin.cambrera.net certificate (infra_aws, output
    # www_origin_validation_records). ACM renews the certificate automatically as long as it's in use (attached to
    # an AWS resource, e.g. an ALB listener) and this record is in place; don't delete it.
    cname_acm_www_origin = {
      name    = "_87e3a0f5a3ec51016d805049258a6474.www-origin"
      type    = "CNAME"
      content = "_62115c8849505908a08595785566d526.wzccmgtwzk.acm-validations.aws"
      ttl     = 60
      proxied = false # ACM must see the record itself
      comment = "NET-103: ACM DNS validation for www-origin (infra_aws); keep for auto-renewal"
    }
    # The http-echo Beanstalk ALB (infra_aws). DNS only.
    cname_www_origin = {
      name    = "www-origin"
      type    = "CNAME"
      content = "cambrera-prod-www.eba-de2pqsyp.us-east-1.elasticbeanstalk.com"
      proxied = false
      comment = "NET-103: www origin: http-echo Beanstalk ALB (infra_aws)"
    }
    # The Cloudflare Tunnel (infra/tunnel_svc, output tunnel_cname). Proxied.
    cname_tunnel = {
      name    = "tunnel"
      type    = "CNAME"
      content = "bafe27e6-f0e1-471a-8012-1c3f8f9ebc15.cfargotunnel.com"
      proxied = true
      comment = "NET-105: tunnel.cambrera.net via Cloudflare Tunnel (infra/tunnel_svc)"
    }

    # ACM DNS validation for the certificate's other names (infra_aws, output www_origin_validation_records; its
    # www-origin name uses cname_acm_www_origin above, since ACM uses one CNAME per name per account). ACM renews the
    # certificate automatically as long as it's in use (on the ALB listener) and these records are in place.
    cname_acm_www = {
      name    = "_c79ef91c9e58cc35ecaf78853311f740.www"
      type    = "CNAME"
      content = "_9371e9da5ec7208913b9e1aef8456db6.wzccmgtwzk.acm-validations.aws"
      ttl     = 60
      proxied = false # ACM must see the record itself
      comment = "NET-104: ACM DNS validation for www (infra_aws); keep for auto-renewal"
    }
    cname_acm_apex = {
      name    = "_6018b45a3dfaedd90cce3772df8d9a6e"
      type    = "CNAME"
      content = "_a6348483ab0cd5bb07531ee6af051ac9.wzccmgtwzk.acm-validations.aws"
      ttl     = 60
      proxied = false # ACM must see the record itself
      comment = "NET-104: ACM DNS validation for cambrera.net (infra_aws); keep for auto-renewal"
    }
  }

  # Not here: _acme-challenge TXT records. The ACME client creates and deletes them on every issue/renewal, using
  # the DNS-only token from infra/bootstrap (acme_api_token). Terraform ignores records it doesn't manage.
}

# Module outputs aren't shown by terraform output; re-export at the root.
output "zone" {
  description = "The zone's ID, status, and the nameservers (set these at the registrar)."
  value       = module.dns_zone_cambrera_net.zone
}

output "resource_records" {
  description = "DNS records managed in this zone (key => ID, full name, type, content)."
  value       = module.dns_zone_cambrera_net.resource_records
}
