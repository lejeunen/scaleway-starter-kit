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
  description = "Database password for the ${local.env.locals.db_name} database"
  tags        = local.env.locals.tags
}
