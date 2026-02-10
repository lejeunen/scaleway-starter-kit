output "secret_id" {
  description = "ID of the secret."
  value       = scaleway_secret.this.id
}

output "secret_name" {
  description = "Name of the secret."
  value       = scaleway_secret.this.name
}

output "version_id" {
  description = "ID of the secret version."
  value       = scaleway_secret_version.this.id
}
