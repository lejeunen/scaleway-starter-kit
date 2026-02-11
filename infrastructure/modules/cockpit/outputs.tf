output "grafana_url" {
  description = "URL of the Cockpit Grafana dashboard."
  value       = data.scaleway_cockpit_grafana.this.grafana_url
}
