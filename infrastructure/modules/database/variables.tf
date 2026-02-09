variable "instance_name" {
  description = "Name of the RDB instance"
  type        = string
}

variable "engine" {
  description = "Database engine (e.g., PostgreSQL-16)"
  type        = string
}

variable "node_type" {
  description = "Node type for the database instance"
  type        = string
}

variable "volume_size_gb" {
  description = "Volume size in GB"
  type        = number
  default     = 10
}

variable "is_ha_cluster" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "disable_backup" {
  description = "Disable automated backups"
  type        = bool
  default     = false
}

variable "backup_schedule_frequency" {
  description = "Backup frequency in hours"
  type        = number
  default     = 24
}

variable "backup_schedule_retention" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
}

variable "user_name" {
  description = "Admin username for the database"
  type        = string
}

variable "user_password" {
  description = "Admin password for the database"
  type        = string
  sensitive   = true
}

variable "private_network_id" {
  description = "Private network ID to attach the database to"
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
