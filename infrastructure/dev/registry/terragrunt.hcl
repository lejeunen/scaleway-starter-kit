include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/registry"
}

inputs = {
  registry_name = local.env.locals.registry_name
  description   = "Container registry for ${local.env.locals.project}"
  region        = local.env.locals.region
}
