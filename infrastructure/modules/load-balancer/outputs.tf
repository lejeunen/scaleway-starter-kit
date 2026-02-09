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
