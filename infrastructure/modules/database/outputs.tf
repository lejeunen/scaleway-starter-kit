output "instance_id" {
  description = "ID of the RDB instance"
  value       = scaleway_rdb_instance.this.id
}

output "endpoint_ip" {
  description = "Private network endpoint IP"
  value       = scaleway_rdb_instance.this.private_network[0].ip
}

output "endpoint_port" {
  description = "Endpoint port"
  value       = scaleway_rdb_instance.this.private_network[0].port
}

output "database_name" {
  description = "Name of the database"
  value       = scaleway_rdb_database.this.name
}
