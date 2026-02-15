#!/usr/bin/env bash
set -euo pipefail

# Manually rotate the API auth token in Scaleway Secret Manager.
#
# This creates a new secret version and disables the previous one.
# The ExternalSecret will pick up the new token within its refreshInterval (5 min).
# During that window, clients with the new token may get rejected by pods
# still serving the old one. For zero-downtime rotation, restart pods after
# the ExternalSecret has synced:
#   kubectl rollout restart deployment/sovereign-wisdom -n sovereign-wisdom

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DEV_DIR="$(dirname "$SCRIPT_DIR")/infrastructure/dev"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
err() { echo -e "${RED}✗${NC} $*" >&2; }

for var in SCW_SECRET_KEY; do
    if [[ -z "${!var:-}" ]]; then
        err "Required environment variable $var is not set"
        exit 1
    fi
done

for cmd in terragrunt curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        err "Required command '$cmd' is not found"
        exit 1
    fi
done

# Get secret ID from Terraform state
info "Fetching secret ID from infrastructure state..."
SECRET_ID=$(cd "$INFRA_DEV_DIR/secret-manager-api-token" && terragrunt output -raw secret_id) || {
    err "Failed to get secret ID. Is secret-manager-api-token deployed?"
    exit 1
}

# Generate new token
NEW_TOKEN=$(openssl rand -hex 32)
TOKEN_B64=$(echo -n "$NEW_TOKEN" | base64)

# Push to Secret Manager (disables previous version)
info "Creating new secret version..."
RESPONSE=$(curl -sf \
    -X POST \
    -H "X-Auth-Token: $SCW_SECRET_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"data\": \"$TOKEN_B64\", \"disable_previous\": true}" \
    "https://api.scaleway.com/secret-manager/v1beta1/regions/fr-par/secrets/$SECRET_ID/versions")

REVISION=$(echo "$RESPONSE" | jq -r '.revision')
ok "New token created (revision $REVISION)"
echo ""
echo -e "${BLUE}The ExternalSecret will sync within 5 minutes.${NC}"
echo -e "${BLUE}To force immediate pod update:${NC}"
echo "  kubectl rollout restart deployment/sovereign-wisdom -n sovereign-wisdom"
