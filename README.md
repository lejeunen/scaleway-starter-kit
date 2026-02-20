# Scaleway Starter Kit

An infrastructure starter kit for [Scaleway](https://www.scaleway.com/), built with **Terragrunt** and **OpenTofu**. A learning tool and starting point for deploying a secure, sovereign cloud platform on a European provider.

## Architecture

```
                Internet
                   │
              ┌────┴────┐
              │  Load   │  ← Provisioned by the Scaleway Cloud Controller Manager (CCM)
              │Balancer │     via the NGINX Ingress Controller Service
              └────┬────┘
                   │ TCP (proxy protocol v2)
     ┌─────────────┼─────────────┐
     │    VPC / Private Network  │
     │             │             │
     │   ┌─────────┴─────────┐   │
     │   │     Kapsule       │   │
     │   │   (Kubernetes)    │   │
     │   │                   │   │
     │   │  NGINX Ingress ←──── TLS termination (Let's Encrypt via cert-manager)
     │   │       │           │   │
     │   │  ┌────┴────────┐  │   │
     │   │  │ Sovereign   │  │   │
     │   │  │ Cloud Wisdom│  │   │
     │   │  └──────┬──────┘  │   │
     │   └─────────┼─────────┘   │
     │             │             │
     │   ┌─────────┴─────────┐   │
     │   │    PostgreSQL     │   │
     │   │   (Managed DB)    │   │
     │   └───────────────────┘   │
     └───────────────────────────┘

     Secret Manager          Container Registry
     (DB credentials +       (Docker images)
      API auth token)
```

### Components

| Component | Description | Security |
|-----------|-------------|----------|
| **VPC + Private Network** | Isolated network with a `172.16.0.0/22` subnet. All resources communicate over private IPs only. | Network isolation for all internal resources |
| **Kapsule** | Managed Kubernetes cluster with Cilium CNI, autoscaling (1–3 nodes), and autohealing. | Attached to private network, no public node exposure |
| **PostgreSQL** | Managed database (PostgreSQL 16) with automated backups (daily, 7-day retention). | Private network only — no public endpoint. Password managed via Secret Manager. |
| **NGINX Ingress Controller** | Kubernetes ingress controller exposed via a CCM-managed Scaleway Load Balancer. Routes traffic based on Ingress rules. | TLS termination via cert-manager (Let's Encrypt). The LB is the only externally reachable component. |
| **cert-manager** | Automates Let's Encrypt certificate lifecycle: request, challenge validation, storage as K8s Secret, and auto-renewal. Uses HTTP-01 challenges for subdomains and DNS-01 (via cert-manager-webhook-scaleway) for the apex domain. | Certificates stored as Kubernetes Secrets, never on disk |
| **Secret Manager** | Stores database credentials and API auth token. Synced to Kubernetes via External Secrets Operator. | Secrets never hardcoded, injected at runtime |
| **Container Registry** | Private Docker image registry hosted on Scaleway. | Images stored in France, private access only |
| **Cockpit** | Managed observability platform (Grafana, Mimir, Loki, Tempo). Kapsule metrics collected automatically. | Data stays in France, managed by Scaleway |

> **Why not a Terraform-managed Load Balancer?** This project initially used a Scaleway Load Balancer managed entirely by Terraform — a natural choice when your infrastructure-as-code tool is Terraform and you want everything in one dependency graph. It worked, but the backend configuration required hardcoding node IPs. This broke whenever Kapsule auto-upgraded nodes (the IPs changed) or the cluster autoscaler added a node (the new node wasn't in the backend list). By letting the Kubernetes Cloud Controller Manager (CCM) manage the Load Balancer instead, backends are updated automatically — node upgrades and autoscaling just work.

### Dependency Graph

```
vpc
 ├── kapsule
 └── database

secret-manager   (independent)
registry         (independent)
cockpit          (independent)
```

## Project Structure

```
infrastructure/
├── root.hcl                       # Shared Terragrunt config (S3 backend, provider)
├── modules/                       # Reusable Terraform modules
│   ├── vpc/                       # VPC + private network
│   ├── kapsule/                   # Kubernetes cluster + node pool
│   ├── database/                  # PostgreSQL managed database
│   ├── secret-manager/            # Scaleway Secret Manager
│   ├── registry/                  # Scaleway Container Registry
│   └── cockpit/                   # Scaleway Cockpit (observability)
└── dev/                           # Dev environment
    ├── env.hcl                    # Environment-specific variables
    ├── vpc/terragrunt.hcl
    ├── kapsule/terragrunt.hcl
    ├── database/terragrunt.hcl
    ├── secret-manager-db-password/terragrunt.hcl
    ├── secret-manager-api-token/terragrunt.hcl
    ├── registry/terragrunt.hcl
    └── cockpit/terragrunt.hcl

k8s/                               # Kubernetes manifests
├── namespace.yaml
├── ingress/                       # Ingress controller + TLS
│   ├── nginx-values.yaml          # NGINX Ingress Helm values (Scaleway CCM annotations)
│   └── cluster-issuer.yaml        # cert-manager ClusterIssuer (HTTP-01 + DNS-01 solvers)
├── external-secrets/              # External Secrets Operator config
│   ├── external-secret.yaml       # DB password sync
│   └── api-auth-token.yaml        # API auth token sync
└── app/                           # Application deployment
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml               # App routing rules + TLS

scripts/
├── validate.sh                    # Validation & security scanning
├── deploy.sh                      # Application deployment to Kapsule
└── rotate-api-token.sh            # Manual API token rotation
```

The root Terragrunt config (`root.hcl`) is environment-agnostic — all environment-specific values live in `env.hcl`. To add a new environment (staging, prod), just create a new directory with its own `env.hcl`.

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.6.0
- [Terragrunt](https://terragrunt.gruntwork.io/) >= 0.93.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/) (for ingress-nginx, cert-manager, External Secrets Operator)
- [jq](https://jqlang.github.io/jq/)
- A Scaleway account with API credentials

## Getting Started

### 1. Create the state bucket

In the [Scaleway console](https://console.scaleway.com/), create an Object Storage bucket:
- **Name:** `scaleway-starter-kit`
- **Region:** `fr-par`
- **Visibility:** Private

### 2. Create the `.env` file

```bash
cp .env.example .env
```

Edit `.env` with your Scaleway credentials and database password:

```bash
export SCW_ACCESS_KEY=<your-access-key>
export SCW_SECRET_KEY=<your-secret-key>
export SCW_DEFAULT_ORGANIZATION_ID=<your-org-id>
export SCW_DEFAULT_PROJECT_ID=<your-project-id>
export TF_VAR_db_password=<a-secure-password>
export TF_VAR_api_auth_token=<generate-with-openssl-rand-hex-32>
export KUBECONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/infrastructure/dev/.kubeconfig"
```

Then load it:

```bash
source .env
```

### 3. Deploy the infrastructure

```bash
cd infrastructure/dev
terragrunt run --all apply
```

Terragrunt will deploy in order: VPC → Kapsule + Database (parallel). Secret Manager, Container Registry, and Cockpit are independent and deploy in parallel with the rest.

### 4. Generate the kubeconfig

After the Kapsule cluster is deployed:

```bash
cd infrastructure/dev/kapsule
terragrunt output -json kubeconfig | jq -r '.[0].config_file' > ../.kubeconfig
chmod 600 ../.kubeconfig
```

Then connect to the cluster:

```bash
kubectl get nodes
```

### 5. Deploy the application

The starter kit includes Kubernetes manifests for [**Sovereign Cloud Wisdom**](https://github.com/lejeunen/sovereign-cloud-wisdom), a demo application that serves curated wisdom about European digital sovereignty.

The app Docker image must be built and pushed to the Container Registry first (see the [app repository](https://github.com/lejeunen/sovereign-cloud-wisdom)).

**Run the deployment script:**

```bash
./scripts/deploy.sh
```

The script will:
1. Install [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/) — creates a Scaleway Load Balancer via the CCM
2. Install [cert-manager](https://cert-manager.io/) — automates Let's Encrypt TLS certificates
3. Install [cert-manager-webhook-scaleway](https://github.com/scaleway/cert-manager-webhook-scaleway) — DNS-01 solver for the apex domain via Scaleway DNS API
4. Install [External Secrets Operator](https://external-secrets.io/) — syncs secrets from Scaleway Secret Manager
5. Create Kubernetes secrets (registry pull credentials, Scaleway API access for ESO and DNS-01)
6. Create a `ClusterSecretStore` pointing to Scaleway Secret Manager
7. Sync the database password and API auth token as Kubernetes secrets via `ExternalSecret`
8. Create the app `ConfigMap` with database connection details (fetched from Terragrunt outputs)
9. Deploy the application (Deployment + ClusterIP Service + Ingress)
10. Print the Load Balancer address for DNS configuration

**Configure DNS:**

After the script completes, it prints the Load Balancer hostname. Create two DNS records:

```
scw.sovereigncloudwisdom.eu  CNAME → <LB hostname>
sovereigncloudwisdom.eu      A     → <LB IP>
```

> **Note:** Apex domains cannot use CNAME records (DNS specification). Resolve the LB hostname to get the IP: `dig +short <LB hostname>`.

Once DNS propagates, cert-manager automatically obtains Let's Encrypt certificates — via HTTP-01 for the subdomain and DNS-01 for the apex domain. Check progress:

```bash
kubectl get certificate -n sovereign-wisdom
```

**Verify:**

```bash
curl https://scw.sovereigncloudwisdom.eu/
curl https://sovereigncloudwisdom.eu/
```

**Retrieve the API auth token** (for use in client applications):

```bash
kubectl get secret api-auth-token -n sovereign-wisdom -o jsonpath='{.data.api-token}' | base64 -d; echo
```

To rotate the token manually:

```bash
./scripts/rotate-api-token.sh
```

### 6. Access the Grafana dashboard

Cockpit is Scaleway's managed observability platform. Kapsule metrics are collected automatically at no cost, and is very easy to set up.

```bash
cd infrastructure/dev/cockpit
terragrunt output grafana_url
```

Open the Grafana URL and log in with your Scaleway IAM credentials. Pre-configured dashboards for Kapsule are available under the Scaleway folder.

![Grafana Kapsule Overview](docs/grafana-kapsule-overview.png)

## Adding a New Environment

1. Create a new environment directory:
   ```bash
   mkdir -p infrastructure/staging
   ```

2. Copy and adjust `env.hcl`:
   ```bash
   cp infrastructure/dev/env.hcl infrastructure/staging/env.hcl
   # Edit values (instance sizes, cluster name, etc.)
   ```

3. Copy the child module configs (they're identical — all values come from `env.hcl`):
   ```bash
   for module in vpc kapsule database secret-manager-db-password secret-manager-api-token registry cockpit; do
     mkdir -p "infrastructure/staging/$module"
     cp "infrastructure/dev/$module/terragrunt.hcl" "infrastructure/staging/$module/"
   done
   ```

4. Deploy:
   ```bash
   cd infrastructure/staging
   terragrunt run --all apply
   ```

## Validation & Security Scanning

A validation script checks formatting, configuration, dependencies, linting, and security:

```bash
source .env
./scripts/validate.sh
```

The script runs the following checks:

| Check | Tool | Description |
|-------|------|-------------|
| HCL format | `terragrunt hcl fmt` | Ensures consistent formatting |
| Terraform validation | `terragrunt validate` | Validates resource configurations |
| Dependency graph | `terragrunt dag graph` | Detects circular dependencies |
| Linting | `tflint` | Catches common Terraform mistakes |
| Security scan | `trivy` | Flags security misconfigurations (HIGH/CRITICAL) |

Optional tools (`tflint`, `trivy`) are skipped if not installed:

```bash
brew install tflint trivy
```

To validate a different environment:

```bash
./scripts/validate.sh infrastructure/staging
```

## Compliance & Sovereignty

This project is designed with European data sovereignty in mind. All resources are deployed exclusively in France (`fr-par`), using Scaleway — a French cloud provider not subject to US extraterritorial surveillance laws (CLOUD Act, FISA Section 702).

For a non-technical overview of why sovereign cloud matters, see:
- [WHY-SOVEREIGN-CLOUD.md](WHY-SOVEREIGN-CLOUD.md) (English)
- [WHY-SOVEREIGN-CLOUD.fr.md](WHY-SOVEREIGN-CLOUD.fr.md) (French)

For details on how this project addresses GDPR, SecNumCloud, NIS2, and DORA requirements, see:
- [COMPLIANCE.md](COMPLIANCE.md) (English)
- [COMPLIANCE.fr.md](COMPLIANCE.fr.md) (French)

## What's Not Included

This starter kit is a foundation, not a turnkey production setup. You would still need to add:

- **GitOps** workflow (ArgoCD, Flux)
- **CI/CD** pipeline for infrastructure and application
- **Network policies** for fine-grained pod-to-pod traffic control
- **Secure private network access** (VPN or bastion) for reaching internal resources like the database
- **Backup strategy** beyond the managed database backups
- **Web Application Firewall** to protect against common threats
- And more, depending on your specific requirements

## Tear Down

**Important:** Follow this order to avoid orphaned resources.

**1. Delete Kubernetes resources first**

The NGINX Ingress Controller creates a Scaleway Load Balancer via the CCM. If you destroy the cluster without removing it first, the LB becomes orphaned in your Scaleway account.

```bash
helm uninstall ingress-nginx -n ingress-nginx
```

Wait for the Load Balancer to disappear in the [Scaleway console](https://console.scaleway.com/) before proceeding.

**2. Destroy the infrastructure**

```bash
cd infrastructure/dev
terragrunt run --all destroy
```

**3. Clean up Scaleway secrets**

Scaleway secrets survive `terragrunt destroy`. Delete them manually before redeploying, or you'll get a "cannot have same secret name" error:

```bash
scw secret secret list
scw secret secret delete <secret-id>
```
