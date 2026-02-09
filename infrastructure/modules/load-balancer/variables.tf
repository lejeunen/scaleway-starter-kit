variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "lb_type" {
  description = "Type of load balancer (e.g., LB-S)"
  type        = string
  default     = "LB-S"
}

variable "zone" {
  description = "Scaleway zone"
  type        = string
}

variable "private_network_id" {
  description = "Private network ID to attach the load balancer to"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = list(string)
  default     = []
}

variable "frontend_port" {
  description = "Port the frontend listens on"
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Port to forward traffic to on backend servers"
  type        = number
  default     = 80
}

variable "backend_server_ips" {
  description = "List of backend server IPs"
  type        = list(string)
  default     = []
}
