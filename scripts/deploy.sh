#!/usr/bin/env bash
set -euo pipefail

# Deploy sovereign-cloud-wisdom to Kapsule
#
# Prerequisites:
#   - KUBECONFIG is set (see .env.example)
#   - Infrastructure is deployed (VPC, Kapsule, Database, Secret Manager, Registry)
#   - App image is pushed to the container registry
#   - SCW_ACCESS_KEY, SCW_SECRET_KEY, SCW_DEFAULT_PROJECT_ID are set

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
K8S_DIR="$PROJECT_DIR/k8s"
INFRA_DEV_DIR="$PROJECT_DIR/infrastructure/dev"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}→${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
err() { echo -e "${RED}✗${NC} $*" >&2; }

# --- Preflight checks ---

for var in SCW_ACCESS_KEY SCW_SECRET_KEY SCW_DEFAULT_PROJECT_ID KUBECONFIG; do
    if [[ -z "${!var:-}" ]]; then
        err "Required environment variable $var is not set"
        exit 1
    fi
done

for cmd in kubectl terragrunt jq envsubst; do
    if ! command -v "$cmd" &>/dev/null; then
        err "Required command '$cmd' is not found"
        exit 1
    fi
done

# --- Collect infrastructure outputs ---

info "Collecting infrastructure outputs..."

DB_ENDPOINT_IP=$(cd "$INFRA_DEV_DIR/database" && terragrunt output -raw endpoint_ip 2>/dev/null)
DB_ENDPOINT_PORT=$(cd "$INFRA_DEV_DIR/database" && terragrunt output -raw endpoint_port 2>/dev/null)

ok "Database endpoint: $DB_ENDPOINT_IP:$DB_ENDPOINT_PORT"

# --- Install External Secrets Operator (if not present) ---

if ! kubectl get namespace external-secrets &>/dev/null; then
    info "Installing External Secrets Operator..."
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update
    helm install external-secrets external-secrets/external-secrets \
        --namespace external-secrets \
        --create-namespace \
        --wait
    ok "External Secrets Operator installed"
else
    ok "External Secrets Operator already installed"
fi

# --- Create namespace ---

info "Applying namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

# --- Create Scaleway API credentials secret for ESO ---

info "Creating Scaleway API credentials secret for ESO..."
kubectl create secret generic scaleway-api-credentials \
    --namespace external-secrets \
    --from-literal=access-key="$SCW_ACCESS_KEY" \
    --from-literal=secret-key="$SCW_SECRET_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -
ok "Scaleway API credentials secret created"

# --- Create registry pull secret ---

info "Creating registry pull secret..."
kubectl create secret docker-registry registry-secret \
    --namespace sovereign-wisdom \
    --docker-server=rg.fr-par.scw.cloud \
    --docker-username=nologin \
    --docker-password="$SCW_SECRET_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -
ok "Registry pull secret created"

# --- Apply ClusterSecretStore (substitute project ID) ---

info "Applying ClusterSecretStore..."
export SCW_DEFAULT_PROJECT_ID
envsubst < "$K8S_DIR/external-secrets/cluster-secret-store.yaml" | kubectl apply -f -
ok "ClusterSecretStore applied"

# --- Apply ExternalSecret ---

info "Applying ExternalSecret..."
kubectl apply -f "$K8S_DIR/external-secrets/external-secret.yaml"
ok "ExternalSecret applied"

# --- Apply ConfigMap (substitute DB connection details) ---

info "Applying app ConfigMap..."
export DB_ENDPOINT_IP DB_ENDPOINT_PORT
envsubst < "$K8S_DIR/app/configmap.yaml" | kubectl apply -f -
ok "ConfigMap applied"

# --- Apply Deployment and Service ---

info "Applying app Deployment..."
kubectl apply -f "$K8S_DIR/app/deployment.yaml"

info "Applying app Service..."
kubectl apply -f "$K8S_DIR/app/service.yaml"
ok "App deployed"

# --- Update LB backend with node IPs ---

info "Fetching Kapsule node IPs..."
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')

if [[ -n "$NODE_IPS" ]]; then
    ok "Node IPs: $NODE_IPS"
    echo ""
    echo -e "${BLUE}To update the load balancer backend, add these IPs to:${NC}"
    echo "  infrastructure/dev/load-balancer/terragrunt.hcl"
    echo ""
    echo "  backend_server_ips = [$(echo "$NODE_IPS" | tr ' ' '\n' | sed 's/.*/"&"/' | paste -sd, -)]"
    echo ""
    echo "Then run: cd infrastructure/dev/load-balancer && terragrunt apply"
else
    err "Could not retrieve node IPs"
fi

echo ""
ok "Deployment complete!"
