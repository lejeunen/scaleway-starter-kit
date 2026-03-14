# Manages secret shells (name, description, tags) only.
# Secret values are pushed separately via scripts/push-secrets.sh
# to keep sensitive data out of Terraform state.

resource "scaleway_secret" "this" {
  name        = var.secret_name
  description = var.description
  tags        = var.tags
}

# Drop secret versions from state without destroying them in Scaleway.
# Safe for fresh deploys (no-op if the resource was never in state).
removed {
  from = scaleway_secret_version.this
  lifecycle {
    destroy = false
  }
}

removed {
  from = scaleway_secret_version.externally_rotated
  lifecycle {
    destroy = false
  }
}
