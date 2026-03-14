#!/usr/bin/env bash
#
# Push secret values to Scaleway Secret Manager.
# Terraform manages secret shells (name/description/tags) only.
# This script pushes the actual sensitive data via the scw CLI,
# keeping it out of Terraform state.
#
# Usage:
#   source .env && ./scripts/push-secrets.sh [--dry-run] [SECRET_NAME...]
#
# If no secret names are given, all secrets are pushed.
# With --dry-run, prints what would be pushed without doing it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=false
SELECTED=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) SELECTED+=("$arg") ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}-${NC} $*"; }
ok() { echo -e "${GREEN}ok${NC} $*"; }
err() { echo -e "${RED}error${NC} $*" >&2; }

# Validate required env vars exist
require_env() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      err "missing env var $var"
      exit 1
    fi
  done
}

# Preflight
for cmd in scw jq; do
  if ! command -v "$cmd" &>/dev/null; then
    err "required command '$cmd' not found"
    exit 1
  fi
done

# Push a secret version. Creates a new version each time (ESO reads latest).
push_secret() {
  local name="$1"
  local data="$2"

  if $DRY_RUN; then
    info "[dry-run] would push: $name"
    return
  fi

  info "pushing: $name"
  scw secret version create \
    "$(scw secret secret list name="$name" -o json | jq -r '.[0].id')" \
    data="$data" \
    disable-previous=true \
    -o json > /dev/null
}

should_push() {
  local name="$1"
  if [[ ${#SELECTED[@]} -eq 0 ]]; then
    return 0
  fi
  for s in "${SELECTED[@]}"; do
    [[ "$s" == "$name" ]] && return 0
  done
  return 1
}

# --- Secret definitions ---

push_all() {
  if should_push "dev-db-password"; then
    require_env TF_VAR_db_password
    push_secret "dev-db-password" "$TF_VAR_db_password"
  fi

  if should_push "dev-api-auth-token"; then
    require_env TF_VAR_api_auth_token
    push_secret "dev-api-auth-token" "$TF_VAR_api_auth_token"
  fi
}

push_all
echo ""
ok "done."
