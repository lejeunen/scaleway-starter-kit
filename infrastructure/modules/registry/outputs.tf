output "namespace_id" {
  description = "ID of the registry namespace."
  value       = scaleway_registry_namespace.this.id
}

output "endpoint" {
  description = "Endpoint URL of the registry namespace."
  value       = scaleway_registry_namespace.this.endpoint
}
