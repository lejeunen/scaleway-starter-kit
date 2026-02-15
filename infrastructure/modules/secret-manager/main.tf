resource "scaleway_secret" "this" {
  name        = var.secret_name
  description = var.description
  tags        = var.tags
}

resource "scaleway_secret_version" "this" {
  count     = var.externally_rotated ? 0 : 1
  secret_id = scaleway_secret.this.id
  data      = var.secret_data
}

# Separate resource for secrets rotated outside of Terraform (e.g. scripts/rotate-api-token.sh).
# ignore_changes on data prevents terragrunt apply from overwriting a rotated value.
resource "scaleway_secret_version" "externally_rotated" {
  count     = var.externally_rotated ? 1 : 0
  secret_id = scaleway_secret.this.id
  data      = var.secret_data

  lifecycle {
    ignore_changes = [data]
  }
}
