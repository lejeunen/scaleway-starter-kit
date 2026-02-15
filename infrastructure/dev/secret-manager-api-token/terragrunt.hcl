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
  secret_name        = local.env.locals.api_auth_token_secret
  secret_data        = get_env("TF_VAR_api_auth_token")
  description        = "API token for the sovereign-wisdom POST /api/wisdom endpoint"
  externally_rotated = true
  tags               = local.env.locals.tags
}
