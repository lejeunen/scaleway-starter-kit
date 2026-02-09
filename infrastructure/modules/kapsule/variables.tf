variable "cluster_name" {
  description = "Name of the Kapsule cluster"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
}

variable "cni" {
  description = "Container Network Interface plugin"
  type        = string
  default     = "cilium"
}

variable "private_network_id" {
  description = "ID of the private network to attach the cluster to"
  type        = string
}

variable "region" {
  description = "Scaleway region"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = list(string)
  default     = []
}

variable "node_type" {
  description = "Node type for the default pool"
  type        = string
}

variable "pool_size" {
  description = "Initial size of the default pool"
  type        = number
  default     = 1
}

variable "pool_min_size" {
  description = "Minimum pool size for autoscaling"
  type        = number
  default     = 1
}

variable "pool_max_size" {
  description = "Maximum pool size for autoscaling"
  type        = number
  default     = 3
}

variable "pool_autoscaling" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

variable "auto_upgrade_enabled" {
  description = "Enable automatic Kubernetes version upgrades"
  type        = bool
  default     = true
}

variable "auto_upgrade_day" {
  description = "Day for the maintenance window"
  type        = string
  default     = "sunday"
}

variable "auto_upgrade_hour" {
  description = "Start hour for maintenance window (UTC)"
  type        = number
  default     = 3
}
