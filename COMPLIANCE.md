# Compliance & Sovereign Cloud

This project is designed to meet European data sovereignty and regulatory requirements by leveraging **Scaleway**, a French cloud provider with datacenters in France and Europe.

## Table of Contents

- [Legal Framework](#legal-framework)
  - [US Extraterritorial Surveillance](#us-extraterritorial-surveillance)
  - [US Hyperscaler "Sovereign Cloud" Offerings](#us-hyperscaler-sovereign-cloud-offerings)
  - [European Digital Sovereignty](#european-digital-sovereignty)
  - [SecNumCloud](#secnumcloud)
  - [GDPR / RGPD](#gdpr--rgpd)
- [Technical Controls](#technical-controls)
  - [Data Residency](#data-residency)
  - [Network Security](#network-security)
  - [Encryption](#encryption)
  - [Credentials Management](#credentials-management)
  - [Audit & Traceability](#audit--traceability)
- [Regulatory Mapping](#regulatory-mapping)
  - [NIS2 Directive](#nis2-directive)
  - [DORA (Financial Sector)](#dora-financial-sector)
  - [Applicability Matrix](#applicability-matrix)

---

## Legal Framework

### US Extraterritorial Surveillance

Several US laws grant authorities access to data held by US companies, regardless of where that data is physically stored:

- **CLOUD Act** (2018) — Grants US law enforcement the authority to compel US-headquartered companies to disclose data stored on their servers, **regardless of where that data is physically located**. Data hosted on AWS, Azure, or GCP in a European datacenter can still be subject to US jurisdiction.

- **FISA Section 702** — Allows the NSA to compel US companies to provide data on non-US persons without individual warrants. This applies to any company subject to US jurisdiction and was the core issue behind the Schrems II ruling. Unlike the CLOUD Act (which targets specific legal proceedings), FISA 702 enables **bulk surveillance**.

- **Executive Order 12333** — Authorizes intelligence collection of data in transit (e.g., tapping undersea cables and internet backbone infrastructure) without judicial oversight. This means data doesn't need to be at rest on US servers to be intercepted.

These laws directly conflict with:
- **GDPR Article 48**, which restricts data transfers to third-country authorities without an international agreement
- The **Schrems II ruling** (CJEU, July 2020), which invalidated the EU-US Privacy Shield over concerns about US surveillance of EU citizens' data

By using a **European cloud provider** not subject to US jurisdiction, this project eliminates the structural legal conflict between US surveillance laws and GDPR.

### US Hyperscaler "Sovereign Cloud" Offerings

In response to growing European demand for data sovereignty, US hyperscalers have launched dedicated "sovereign cloud" regions:

- **AWS European Sovereign Cloud** (2025) — A separate AWS infrastructure in Germany, operated through a German legal entity with EU-resident staff and management. AWS invested €7.8 billion in this initiative.
- **Google Sovereign Cloud** — Partnerships with local operators (T-Systems in Germany, Thales in France) to provide jointly operated environments.
- **Microsoft Azure Confidential Computing** — Various sovereignty features including EU Data Boundary commitments.

These offerings provide genuine **operational** safeguards: data residency, EU-only personnel, independent governance boards. However, they do not resolve the **legal** risk:

- **Corporate ownership**: The European subsidiaries are ultimately owned by US parent companies. The CLOUD Act applies to data within the "possession, custody, or control" of US companies — and ownership of a subsidiary is a strong argument for control.
- **Untested in court**: No court has ruled on whether a specifically-structured European subsidiary of a US company can resist a CLOUD Act order. Most EU legal experts and the **EDPB** (European Data Protection Board) consider the risk remains.
- **Classified orders**: FISA court orders are secret by design. There is no mechanism to verify whether a US parent company has directed its European subsidiary to comply with a classified surveillance request.
- **SecNumCloud exclusion**: France's SecNumCloud 3.2 certification explicitly requires protection against non-European jurisdictions. Subsidiaries of US companies cannot qualify, regardless of operational safeguards.

The distinction is between **legal certainty** and **legal risk**: a European-owned provider eliminates the jurisdictional question entirely, while a US-owned "sovereign cloud" relies on an untested legal theory that operational separation overrides corporate ownership.

### European Digital Sovereignty

The European Union and its member states are actively promoting digital sovereignty through:
- **EUCS (European Cybersecurity Certification Scheme for Cloud Services)** — EU-wide cloud certification framework
- **SecNumCloud** (France) — ANSSI security certification for cloud providers
- **C5** (Germany) — BSI cloud security standard
- **NIS2 Directive** (2023) — EU-wide cybersecurity requirements for critical infrastructure
- **DORA** (Digital Operational Resilience Act) — Resilience requirements for the financial sector

### SecNumCloud

[SecNumCloud](https://cyber.gouv.fr/enjeux-technologiques/cloud/) is a security certification issued by **ANSSI** (Agence Nationale de la Sécurité des Systèmes d'Information), the French national cybersecurity agency. It is the highest level of cloud security certification in France.

Scaleway is currently pursuing SecNumCloud 3.2 qualification for its cloud services. This certification demonstrates compliance with rigorous security requirements including:
- Physical security of datacenters
- Logical access controls
- Data encryption
- Incident response procedures
- Protection against non-European jurisdictions

SecNumCloud is increasingly required for:
- French public sector (Code de la Commande Publique)
- Health data hosting (HDS — Hébergement de Données de Santé)
- Operators of Essential Services (OES) under NIS2

### GDPR / RGPD

This infrastructure supports GDPR compliance through:

**Data Protection by Design (Article 25)**

- **Network isolation:** All compute and database resources are deployed in a private network (`172.16.0.0/22`) with no direct internet access
  - *Code:* [`infrastructure/modules/vpc/main.tf`](infrastructure/modules/vpc/main.tf)
- **Private database:** PostgreSQL is accessible only from within the private network — no public endpoint exists
  - *Code:* [`infrastructure/modules/database/main.tf`](infrastructure/modules/database/main.tf) — `private_network` block
- **Single entry point:** Only the CCM-managed Load Balancer (provisioned by the NGINX Ingress Controller) has a public IP, acting as the sole ingress point
  - *Code:* [`k8s/ingress/nginx-values.yaml`](k8s/ingress/nginx-values.yaml)

**Data Minimization & Purpose Limitation**

- Infrastructure is scoped to the minimum necessary resources
- Environment separation (dev/staging/prod) prevents data mixing

**Right to Erasure (Article 17)**

- Managed PostgreSQL supports standard SQL `DELETE` operations
- Scaleway provides data destruction guarantees when instances are deleted

---

## Technical Controls

### Data Residency

All infrastructure resources in this project are deployed exclusively in **France**:

| Resource                      | Region          | Zone       |
|-------------------------------|-----------------|------------|
| VPC & Private Network         | `fr-par` (Paris)| —          |
| Kubernetes Cluster (Kapsule)  | `fr-par`        | `fr-par-1` |
| PostgreSQL Database           | `fr-par`        | —          |
| Load Balancer (CCM-managed)   | —               | `fr-par-1` |
| Secret Manager                | `fr-par`        | —          |
| Container Registry            | `fr-par`        | —          |
| Cockpit (Observability)       | `fr-par`        | —          |
| DNS (Domain Records)          | Scaleway DNS    | —          |
| Terraform State (S3)          | `fr-par`        | —          |

No data leaves French territory. Scaleway's Paris datacenters (DC2-DC5) are located in the Île-de-France region.

**Code reference:** Region and zone are enforced in [`infrastructure/root.hcl`](infrastructure/root.hcl) at the provider level, ensuring no resource can accidentally be deployed outside France.

### Network Security

```
Internet → Load Balancer (TCP/443, proxy protocol v2) → NGINX Ingress Controller (TLS termination) → Private Network (172.16.0.0/22) → App Pods / PostgreSQL
```

- **VPC isolation:** All internal resources communicate over a private network
- **No public IPs** on Kubernetes nodes or database instances
- **Cilium CNI:** The Kubernetes cluster uses Cilium, which supports fine-grained network policies for pod-to-pod traffic control
  - *Code:* [`infrastructure/modules/kapsule/main.tf`](infrastructure/modules/kapsule/main.tf) — `cni = "cilium"`
- **CCM-managed Load Balancer:** The Scaleway Cloud Controller Manager automatically provisions and manages the Load Balancer from the NGINX Ingress Controller Service. Backends are updated automatically when nodes change (upgrades, autoscaling).
  - *Code:* [`k8s/ingress/nginx-values.yaml`](k8s/ingress/nginx-values.yaml)
- **Health checks:** NGINX Ingress Controller performs health checks on upstream pods to ensure only healthy backends receive traffic

### Encryption

**At Rest**

- **Database storage:** SBS (Scaleway Block Storage) volumes use AES-256 encryption by default
  - *Code:* [`infrastructure/modules/database/main.tf`](infrastructure/modules/database/main.tf) — `volume_type = "sbs_5k"`
- **Kubernetes persistent volumes:** SBS-backed, encrypted by default

**In Transit**

- **Provider communication:** All Scaleway API calls use TLS 1.2+
- **Kubernetes API:** Accessible via HTTPS only (kubeconfig uses TLS)
- **Ingress TLS:** TLS termination at the NGINX Ingress Controller using Let's Encrypt certificates managed by cert-manager. Certificates are automatically requested, validated, and renewed. Subdomains use HTTP-01 challenges; the apex domain uses DNS-01 challenges via cert-manager-webhook-scaleway (Scaleway DNS API). All HTTP traffic is redirected to HTTPS.
  - *Code:* [`k8s/ingress/cluster-issuer.yaml`](k8s/ingress/cluster-issuer.yaml) — ClusterIssuer for Let's Encrypt
  - *Code:* [`k8s/app/ingress.yaml`](k8s/app/ingress.yaml) — TLS configuration and cert-manager annotation

### Credentials Management

- **Scaleway Secret Manager:** Database credentials are stored in Scaleway's managed Secret Manager service, using envelope encryption (AES-256) via KMS
  - *Code:* [`infrastructure/modules/secret-manager/main.tf`](infrastructure/modules/secret-manager/main.tf)
- **External Secrets Operator:** Secrets are synced from Scaleway Secret Manager to Kubernetes secrets at runtime — credentials are never baked into manifests or container images
  - *Code:* [`k8s/external-secrets/`](k8s/external-secrets/)
- **No hardcoded credentials:** All credentials (API keys, database passwords) are sourced from environment variables or Secret Manager — never committed to code
  - *Code:* `.env.example` for credential template, `.gitignore` excludes `.env`
- **Sensitive outputs:** Terraform outputs containing secrets are marked `sensitive = true` to prevent accidental exposure in logs
  - *Code:* [`infrastructure/modules/kapsule/outputs.tf`](infrastructure/modules/kapsule/outputs.tf) — kubeconfig output
  - *Code:* [`infrastructure/modules/database/variables.tf`](infrastructure/modules/database/variables.tf) — password variable
- **Strict validation:** Terragrunt fails fast if required secrets (e.g., `TF_VAR_db_password`) are not set — no fallback defaults

### Audit & Traceability

- **Infrastructure as Code:** All infrastructure is defined in Terraform/Terragrunt — every change is versioned in Git, providing a complete audit trail
- **Resource tagging:** All resources are tagged with environment, project, and management tool for traceability
  - Tags: `env:dev`, `project:scaleway-starter-kit`, `managed-by:terragrunt`
- **Observability:** Scaleway Cockpit provides managed metrics, logs, and traces via Grafana dashboards — all data stored in France
  - *Code:* [`infrastructure/modules/cockpit/main.tf`](infrastructure/modules/cockpit/main.tf)
- **Validation pipeline:** The [`scripts/validate.sh`](scripts/validate.sh) script runs:
  - HCL format checking
  - Terraform validation
  - Dependency graph analysis
  - TFLint linting
  - **Trivy security scanning** (HIGH and CRITICAL severity)

---

## Regulatory Mapping

### NIS2 Directive

The NIS2 Directive (EU 2022/2555) strengthens cybersecurity requirements for organizations operating critical infrastructure. While full NIS2 compliance requires a broader organizational approach, this project addresses several relevant areas:

- **Risk management:** Infrastructure-as-code approach enables repeatable, auditable deployments
- **Incident handling:** Automated monitoring (health checks, autohealing) enables rapid detection and response
- **Business continuity:** Automated backups, autoscaling, and self-healing capabilities
- **Supply chain security:** Using a European provider pursuing SecNumCloud certification reduces supply chain risk

### DORA (Financial Sector)

The Digital Operational Resilience Act (EU 2022/2554) applies to financial entities and their ICT service providers. While DORA compliance spans governance, processes, and technology, this infrastructure contributes to several key areas:

- **ICT risk management:** Automated security scanning, network isolation, encryption
- **Resilience testing:** Validation scripts for continuous infrastructure testing
- **Third-party risk:** European provider not subject to extraterritorial data access laws
- **Incident reporting:** Tagged, auditable infrastructure enables rapid incident investigation

### Applicability Matrix

| Regulation                       | Scope                                        | This Project                                               |
|----------------------------------|----------------------------------------------|------------------------------------------------------------|
| **GDPR / RGPD**                 | Any organization processing EU personal data | Data residency in France, encryption, network isolation    |
| **SecNumCloud**                  | French public sector, sensitive data         | Scaleway is pursuing SecNumCloud qualification             |
| **NIS2**                         | Essential & important entities in the EU     | IaC audit trail, automated resilience, security scanning   |
| **DORA**                         | Financial sector & ICT providers             | Resilience, testing, European provider                     |
| **HDS**                          | Health data in France                        | SecNumCloud + data residency in France                     |
| **Code de la Commande Publique** | French public procurement                    | Sovereign cloud provider, data in France                   |
