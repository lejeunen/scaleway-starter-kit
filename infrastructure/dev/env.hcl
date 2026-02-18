locals {
  environment = "dev"
  region      = "fr-par"
  zone        = "fr-par-1"
  project     = "scaleway-starter-kit"

  # VPC
  vpc_name             = "dev-vpc"
  private_network_name = "dev-private-network"
  ipv4_subnet          = "172.16.0.0/22"

  # Kapsule
  k8s_cluster_name   = "dev-kapsule"
  k8s_version        = "1.35.1"
  k8s_cni            = "cilium"
  k8s_node_type      = "DEV1-M"
  k8s_pool_size      = 1
  k8s_pool_min_size  = 1
  k8s_pool_max_size  = 3
  k8s_pool_autoscale = true

  # Database
  db_engine           = "PostgreSQL-16"
  db_node_type        = "DB-DEV-S"
  db_name             = "app"
  db_user             = "app_admin"
  db_volume_size_gb   = 10
  db_is_ha            = false
  db_disable_backup   = false
  db_backup_frequency = 24
  db_backup_retention = 7

  # Container Registry
  registry_name = "dev-sovereign-wisdom"

  # Secret Manager
  secret_name           = "dev-db-password"
  api_auth_token_secret = "dev-api-auth-token"

  # Common tags
  tags = ["env:dev", "project:scaleway-starter-kit", "managed-by:terragrunt"]
}
