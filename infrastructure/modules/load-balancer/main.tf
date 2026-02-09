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
    uri = "/"
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
