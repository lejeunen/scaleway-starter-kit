include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/load-balancer"
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

dependency "kapsule" {
  config_path = "../kapsule"

  mock_outputs = {
    cluster_id   = "fr-par/00000000-0000-0000-0000-000000000000"
    cluster_url  = "https://mock-api-url"
    wildcard_dns = "mock.cluster.k8s.fr-par.scw.cloud"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
}

inputs = {
  lb_name            = local.env.locals.lb_name
  lb_type            = local.env.locals.lb_type
  zone               = local.env.locals.zone
  private_network_id = dependency.vpc.outputs.private_network_id
  tags               = local.env.locals.tags
  backend_port       = 30080
  health_check_uri   = "/health"
  backend_server_ips = []
}
