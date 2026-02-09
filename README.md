# Scaleway Starter Kit

A production-ready infrastructure starter kit for [Scaleway](https://www.scaleway.com/), built with **Terragrunt** and **OpenTofu**. Designed as a reference architecture demonstrating best practices for deploying a secure, multi-environment cloud platform.

## Architecture

```
                Internet
                   │
              ┌────┴────┐
              │  Load   │  ← Only public-facing resource
              │Balancer │
              └────┬────┘
                   │
     ┌─────────────┼─────────────┐
     │    VPC / Private Network  │
     │             │             │
     │   ┌─────────┴─────────┐   │
     │   │     Kapsule       │   │
     │   │   (Kubernetes)    │   │
     │   └───────────────────┘   │
     │                           │
     │   ┌───────────────────┐   │
     │   │    PostgreSQL     │   │
     │   │   (Managed DB)    │   │
     │   └───────────────────┘   │
     └───────────────────────────┘
```

### Components

| Component | Description | Security |
|-----------|-------------|----------|
| **VPC + Private Network** | Isolated network with a `172.16.0.0/22` subnet. All resources communicate over private IPs only. | Network isolation for all internal resources |
| **Kapsule** | Managed Kubernetes cluster with Cilium CNI, autoscaling (1–3 nodes), automatic upgrades, and autohealing. | Attached to private network, no public node exposure |
| **PostgreSQL** | Managed database (PostgreSQL 16) with automated backups (daily, 7-day retention). | Private network only — no public endpoint. Password sourced from environment variable. |
| **Load Balancer** | Public HTTP load balancer with health checks, connected to the private network. | The only externally reachable component |

### Dependency Graph

```
vpc
 ├── kapsule → load-balancer
 └── database
```

## Project Structure

```
infrastructure/
├── root.hcl                       # Shared Terragrunt config (S3 backend, provider)
├── modules/                       # Reusable Terraform modules
│   ├── vpc/                       # VPC + private network
│   ├── kapsule/                   # Kubernetes cluster + node pool
│   ├── database/                  # PostgreSQL managed database
│   └── load-balancer/             # Public load balancer
└── dev/                           # Dev environment
    ├── env.hcl                    # Environment-specific variables
    ├── vpc/terragrunt.hcl
    ├── kapsule/terragrunt.hcl
    ├── database/terragrunt.hcl
    └── load-balancer/terragrunt.hcl
```

The project uses **Pattern A** (environment-agnostic root): `root.hcl` contains no environment-specific references, making it easy to add `staging/` or `prod/` directories with their own `env.hcl`.

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.6.0
- [Terragrunt](https://terragrunt.gruntwork.io/) >= 0.93.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
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

Edit `.env` with your Scaleway credentials:

```bash
export SCW_ACCESS_KEY=<your-access-key>
export SCW_SECRET_KEY=<your-secret-key>
export SCW_DEFAULT_ORGANIZATION_ID=<your-org-id>
export SCW_DEFAULT_PROJECT_ID=<your-project-id>
export KUBECONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/infrastructure/dev/.kubeconfig"
```

Then load it:

```bash
source .env
```

### 3. Deploy the infrastructure

```bash
# Set the database password
export TF_VAR_db_password="<a-secure-password>"

# Deploy all modules (respects dependency order)
cd infrastructure/dev
terragrunt run --all apply
```

Terragrunt will deploy in order: VPC → Kapsule + Database (parallel) → Load Balancer.

### 4. Generate the kubeconfig

After the Kapsule cluster is deployed:

```bash
cd infrastructure/dev/kapsule
terragrunt output -json kubeconfig | jq -r '.[0].config_file' > ../.kubeconfig
```

Then reload your environment:

```bash
source .env
kubectl get nodes
```

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
   for module in vpc kapsule database load-balancer; do
     mkdir -p "infrastructure/staging/$module"
     cp "infrastructure/dev/$module/terragrunt.hcl" "infrastructure/staging/$module/"
   done
   ```

4. Deploy:
   ```bash
   cd infrastructure/staging
   terragrunt run --all apply
   ```

## Tear Down

```bash
cd infrastructure/dev
terragrunt run --all destroy
```
