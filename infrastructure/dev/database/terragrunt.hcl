include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/database"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "fr-par/00000000-0000-0000-0000-000000000000"
    private_network_id = "fr-par/00000000-0000-0000-0000-000000000000"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
}

inputs = {
  instance_name             = "${local.env.locals.environment}-postgresql"
  engine                    = local.env.locals.db_engine
  node_type                 = local.env.locals.db_node_type
  volume_size_gb            = local.env.locals.db_volume_size_gb
  is_ha_cluster             = local.env.locals.db_is_ha
  disable_backup            = local.env.locals.db_disable_backup
  backup_schedule_frequency = local.env.locals.db_backup_frequency
  backup_schedule_retention = local.env.locals.db_backup_retention
  db_name                   = local.env.locals.db_name
  user_name                 = local.env.locals.db_user
  user_password             = get_env("TF_VAR_db_password", "placeholder-change-me")
  private_network_id        = dependency.vpc.outputs.private_network_id
  region                    = local.env.locals.region
  tags                      = local.env.locals.tags
}
