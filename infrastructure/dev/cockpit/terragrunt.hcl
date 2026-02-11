include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/cockpit"
}

inputs = {
  project_id = get_env("SCW_DEFAULT_PROJECT_ID")
}
