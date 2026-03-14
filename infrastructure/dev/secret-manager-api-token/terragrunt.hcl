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
  secret_name = local.env.locals.api_auth_token_secret
  description = "API token for the sovereign-wisdom POST /api/wisdom endpoint"
  tags        = local.env.locals.tags
}
