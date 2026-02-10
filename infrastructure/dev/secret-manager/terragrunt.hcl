include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/secret-manager"
}

inputs = {
  secret_name = local.env.locals.secret_name
  secret_data = get_env("TF_VAR_db_password")
  description = "Database password for the ${local.env.locals.db_name} database"
  tags        = local.env.locals.tags
}
