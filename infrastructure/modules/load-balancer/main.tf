resource "scaleway_lb_ip" "this" {
  zone = var.zone
}

resource "scaleway_lb" "this" {
  name  = var.lb_name
  ip_ids = [scaleway_lb_ip.this.id]
  zone  = var.zone
  type  = var.lb_type
  tags  = var.tags

  private_network {
    private_network_id = var.private_network_id
  }
}

resource "scaleway_lb_backend" "this" {
  lb_id            = scaleway_lb.this.id
  name             = "${var.lb_name}-backend"
  forward_protocol = "http"
  forward_port     = var.backend_port
  server_ips       = var.backend_server_ips

  health_check_http {
    uri = var.health_check_uri
  }

  health_check_max_retries = 3
  health_check_delay       = "60s"
  health_check_timeout     = "30s"
}

resource "scaleway_lb_frontend" "this" {
  lb_id        = scaleway_lb.this.id
  backend_id   = scaleway_lb_backend.this.id
  name         = "${var.lb_name}-frontend"
  inbound_port = var.frontend_port
}

# --- DNS + TLS (conditional on domain_name) ---

resource "scaleway_domain_record" "this" {
  count = var.domain_name != "" ? 1 : 0

  dns_zone = var.domain_name
  name     = ""
  type     = "A"
  data     = scaleway_lb_ip.this.ip_address
  ttl      = 3600
}

resource "scaleway_lb_certificate" "this" {
  count = var.domain_name != "" ? 1 : 0

  lb_id = scaleway_lb.this.id
  name  = "${var.lb_name}-cert"

  letsencrypt {
    common_name = var.domain_name
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [scaleway_domain_record.this]
}

resource "scaleway_lb_frontend" "https" {
  count = var.domain_name != "" ? 1 : 0

  lb_id           = scaleway_lb.this.id
  backend_id      = scaleway_lb_backend.this.id
  name            = "${var.lb_name}-frontend-https"
  inbound_port    = 443
  certificate_ids = [scaleway_lb_certificate.this[0].id]
}

resource "scaleway_lb_acl" "http_to_https" {
  count = var.domain_name != "" ? 1 : 0

  frontend_id = scaleway_lb_frontend.this.id
  name        = "${var.lb_name}-http-to-https"
  index       = 0
  description = "Redirect all HTTP traffic to HTTPS"

  action {
    type = "redirect"
    redirect {
      type   = "scheme"
      target = "https"
      code   = 301
    }
  }

  match {
    ip_subnet = ["0.0.0.0/0"]
  }
}
