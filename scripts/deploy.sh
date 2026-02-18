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

for cmd in kubectl terragrunt jq helm; do
    if ! command -v "$cmd" &>/dev/null; then
        err "Required command '$cmd' is not found"
        exit 1
    fi
done

# --- Collect infrastructure outputs ---

info "Collecting infrastructure outputs..."

DB_ENDPOINT_IP=$(cd "$INFRA_DEV_DIR/database" && terragrunt output -raw endpoint_ip) || {
    err "Failed to get database endpoint IP. Is the database deployed?"
    exit 1
}
DB_ENDPOINT_PORT=$(cd "$INFRA_DEV_DIR/database" && terragrunt output -raw endpoint_port) || {
    err "Failed to get database endpoint port. Is the database deployed?"
    exit 1
}

ok "Database endpoint: $DB_ENDPOINT_IP:$DB_ENDPOINT_PORT"

# --- Install NGINX Ingress Controller (if not present) ---
#
# The ingress-nginx Helm chart creates a Service of type LoadBalancer.
# The Scaleway CCM (pre-installed in Kapsule) detects it and automatically
# provisions a Scaleway Load Balancer with the settings from the Service
# annotations (see k8s/ingress/nginx-values.yaml).
#
# This replaces the old Terraform-managed LB, which had hardcoded backend IPs
# that broke on node upgrades and cluster autoscaling.

if ! kubectl get namespace ingress-nginx &>/dev/null; then
    info "Installing NGINX Ingress Controller..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update ingress-nginx
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --values "$K8S_DIR/ingress/nginx-values.yaml" \
        --wait
    ok "NGINX Ingress Controller installed"
else
    info "Upgrading NGINX Ingress Controller..."
    helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --values "$K8S_DIR/ingress/nginx-values.yaml" \
        --wait
    ok "NGINX Ingress Controller upgraded"
fi

# --- Install cert-manager (if not present) ---
#
# cert-manager automates TLS certificate lifecycle:
#   1. Watches for Ingress resources with cert-manager annotations
#   2. Requests certificates from Let's Encrypt via ACME protocol
#   3. Solves HTTP-01 challenges (proves domain ownership)
#   4. Stores certs as Kubernetes Secrets
#   5. Auto-renews ~30 days before expiry
#
# --set crds.enabled=true installs the CRDs (CustomResourceDefinitions)
# that define cert-manager's API types (Certificate, ClusterIssuer, etc.)

if ! kubectl get namespace cert-manager &>/dev/null; then
    info "Installing cert-manager..."
    helm repo add jetstack https://charts.jetstack.io
    helm repo update jetstack
    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --set crds.enabled=true \
        --wait
    ok "cert-manager installed"
else
    ok "cert-manager already installed"
fi

# --- Install External Secrets Operator (if not present) ---

if ! kubectl get namespace external-secrets &>/dev/null; then
    info "Installing External Secrets Operator..."
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update external-secrets
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

# --- Apply ClusterSecretStore ---

info "Applying ClusterSecretStore..."
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: scaleway-secret-store
spec:
  provider:
    scaleway:
      region: fr-par
      projectId: "$SCW_DEFAULT_PROJECT_ID"
      accessKey:
        secretRef:
          name: scaleway-api-credentials
          namespace: external-secrets
          key: access-key
      secretKey:
        secretRef:
          name: scaleway-api-credentials
          namespace: external-secrets
          key: secret-key
EOF
ok "ClusterSecretStore applied"

# --- Apply ExternalSecret ---

info "Applying ExternalSecret..."
kubectl apply -f "$K8S_DIR/external-secrets/external-secret.yaml"
ok "ExternalSecret applied"

# --- Apply API auth token ExternalSecret ---

info "Applying API auth token ExternalSecret..."
kubectl apply -f "$K8S_DIR/external-secrets/api-auth-token.yaml"
ok "API auth token ExternalSecret applied"

# --- Create app ConfigMap ---

info "Creating app ConfigMap..."
kubectl create configmap app-config \
    --namespace sovereign-wisdom \
    --from-literal=db-host="$DB_ENDPOINT_IP" \
    --from-literal=db-port="$DB_ENDPOINT_PORT" \
    --from-literal=db-name="app" \
    --from-literal=db-user="app_admin" \
    --dry-run=client -o yaml | kubectl apply -f -
ok "ConfigMap created"

# --- Apply Deployment, Service, and Ingress ---

info "Applying app Deployment..."
kubectl apply -f "$K8S_DIR/app/deployment.yaml"

info "Applying app Service..."
kubectl apply -f "$K8S_DIR/app/service.yaml"

# --- Apply ClusterIssuer and Ingress ---
#
# ClusterIssuer must exist before the Ingress, because cert-manager reads
# the Ingress annotation and looks up the referenced ClusterIssuer to know
# which ACME server to use.

info "Applying ClusterIssuer..."
kubectl apply -f "$K8S_DIR/ingress/cluster-issuer.yaml"

info "Applying app Ingress..."
kubectl apply -f "$K8S_DIR/app/ingress.yaml"

ok "App deployed"

# --- Wait for Load Balancer IP ---

echo ""
info "Waiting for the Load Balancer external address..."

LB_ADDRESS=""
for i in $(seq 1 30); do
    LB_ADDRESS=$(kubectl get svc ingress-nginx-controller \
        -n ingress-nginx \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    if [[ -z "$LB_ADDRESS" ]]; then
        LB_ADDRESS=$(kubectl get svc ingress-nginx-controller \
            -n ingress-nginx \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    fi
    if [[ -n "$LB_ADDRESS" ]]; then
        break
    fi
    sleep 10
done

echo ""
if [[ -n "$LB_ADDRESS" ]]; then
    ok "Load Balancer address: $LB_ADDRESS"
    echo ""
    echo -e "${BLUE}DNS configuration:${NC}"
    echo "  Create a CNAME record pointing your domain to the Load Balancer:"
    echo "    scw.sovereigncloudwisdom.eu → $LB_ADDRESS"
    echo ""
    echo "  Once DNS propagates, cert-manager will automatically obtain a"
    echo "  Let's Encrypt certificate. Check progress with:"
    echo "    kubectl get certificate -n sovereign-wisdom"
else
    err "Timed out waiting for Load Balancer address (5 minutes)."
    echo "  Check status with: kubectl get svc -n ingress-nginx"
fi

echo ""
ok "Deployment complete!"
