resource "scaleway_rdb_instance" "this" {
  name      = var.instance_name
  engine    = var.engine
  node_type = var.node_type
  region    = var.region
  tags      = var.tags

  is_ha_cluster  = var.is_ha_cluster
  disable_backup = var.disable_backup

  volume_type       = "bssd"
  volume_size_in_gb = var.volume_size_gb

  backup_schedule_frequency = var.backup_schedule_frequency
  backup_schedule_retention = var.backup_schedule_retention

  user_name = var.user_name
  password  = var.user_password

  private_network {
    pn_id       = var.private_network_id
    enable_ipam = true
  }
}

resource "scaleway_rdb_database" "this" {
  instance_id = scaleway_rdb_instance.this.id
  name        = var.db_name
}
