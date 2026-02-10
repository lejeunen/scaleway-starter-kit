output "lb_id" {
  description = "ID of the load balancer"
  value       = scaleway_lb.this.id
}

output "lb_ip" {
  description = "Public IP address of the load balancer"
  value       = scaleway_lb_ip.this.ip_address
}

output "lb_ip_id" {
  description = "ID of the load balancer IP"
  value       = scaleway_lb_ip.this.id
}

output "frontend_id" {
  description = "ID of the frontend"
  value       = scaleway_lb_frontend.this.id
}

output "backend_id" {
  description = "ID of the backend"
  value       = scaleway_lb_backend.this.id
}

output "domain_name" {
  description = "Domain name configured for the load balancer"
  value       = var.domain_name
}

output "certificate_id" {
  description = "ID of the Let's Encrypt certificate"
  value       = var.domain_name != "" ? scaleway_lb_certificate.this[0].id : ""
}

output "https_frontend_id" {
  description = "ID of the HTTPS frontend"
  value       = var.domain_name != "" ? scaleway_lb_frontend.https[0].id : ""
}
