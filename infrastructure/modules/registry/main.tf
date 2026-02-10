resource "scaleway_registry_namespace" "this" {
  name        = var.registry_name
  description = var.description
  is_public   = var.is_public
  region      = var.region
}
