# Compliance & Sovereign Cloud

This project is designed to meet European data sovereignty and regulatory requirements by leveraging **Scaleway**, a French cloud provider with datacenters in France and Europe.

## Table of Contents

- [Legal Framework](#legal-framework)
  - [The US CLOUD Act Problem](#the-us-cloud-act-problem)
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

### The US CLOUD Act Problem

The US Clarifying Lawful Overseas Use of Data (CLOUD) Act of 2018 grants US law enforcement the authority to compel US-headquartered companies to disclose data stored on their servers — **regardless of where that data is physically located**. This means data hosted on AWS, Azure, or GCP in a European datacenter can still be subject to US jurisdiction.

This directly conflicts with:
- **GDPR Article 48**, which restricts data transfers to third-country authorities without an international agreement
- The **Schrems II ruling** (CJEU, July 2020), which invalidated the EU-US Privacy Shield and raised concerns about Standard Contractual Clauses when data processors are subject to US surveillance laws

By using a **European cloud provider** not subject to US jurisdiction, this project eliminates the structural legal conflict between the CLOUD Act and GDPR.

### European Digital Sovereignty

The European Union and its member states are actively promoting digital sovereignty through:
- **EUCS (European Cybersecurity Certification Scheme for Cloud Services)** — EU-wide cloud certification framework
- **SecNumCloud** (France) — ANSSI security certification for cloud providers
- **C5** (Germany) — BSI cloud security standard
- **NIS2 Directive** (2023) — EU-wide cybersecurity requirements for critical infrastructure
- **DORA** (Digital Operational Resilience Act) — Resilience requirements for the financial sector

### SecNumCloud

[SecNumCloud](https://www.anssi.gouv.fr/enjeux-technologiques/cloud/) is a security certification issued by **ANSSI** (Agence Nationale de la Sécurité des Systèmes d'Information), the French national cybersecurity agency. It is the highest level of cloud security certification in France.

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
- **Single entry point:** Only the load balancer has a public IP, acting as the sole ingress point
  - *Code:* [`infrastructure/modules/load-balancer/main.tf`](infrastructure/modules/load-balancer/main.tf)

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
| Load Balancer                 | —               | `fr-par-1` |
| Terraform State (S3)          | `fr-par`        | —          |

No data leaves French territory. Scaleway's Paris datacenters (DC2-DC5) are located in the Île-de-France region.

**Code reference:** Region and zone are enforced in [`infrastructure/root.hcl`](infrastructure/root.hcl) at the provider level, ensuring no resource can accidentally be deployed outside France.

### Network Security

```
Internet → Load Balancer (Public IP) → Private Network (172.16.0.0/22) → Kapsule / PostgreSQL
```

- **VPC isolation:** All internal resources communicate over a private network
- **No public IPs** on Kubernetes nodes or database instances
- **Cilium CNI:** The Kubernetes cluster uses Cilium, which supports fine-grained network policies for pod-to-pod traffic control
  - *Code:* [`infrastructure/modules/kapsule/main.tf`](infrastructure/modules/kapsule/main.tf) — `cni = "cilium"`
- **Health checks:** Load balancer performs HTTP health checks to ensure only healthy backends receive traffic
  - *Code:* [`infrastructure/modules/load-balancer/main.tf`](infrastructure/modules/load-balancer/main.tf)

### Encryption

**At Rest**

- **Database storage:** SBS (Scaleway Block Storage) volumes use AES-256 encryption by default
  - *Code:* [`infrastructure/modules/database/main.tf`](infrastructure/modules/database/main.tf) — `volume_type = "sbs_5k"`
- **Kubernetes persistent volumes:** SBS-backed, encrypted by default

**In Transit**

- **Provider communication:** All Scaleway API calls use TLS 1.2+
- **Kubernetes API:** Accessible via HTTPS only (kubeconfig uses TLS)
- **Load balancer:** Supports HTTPS termination (to be configured per application)

### Credentials Management

- All credentials (API keys, database passwords) are sourced from environment variables — never hardcoded
  - *Code:* `.env.example` for credential template, `.gitignore` excludes `.env`
- Sensitive Terraform outputs are marked `sensitive = true` to prevent accidental exposure in logs
  - *Code:* [`infrastructure/modules/kapsule/outputs.tf`](infrastructure/modules/kapsule/outputs.tf) — kubeconfig output
  - *Code:* [`infrastructure/modules/database/variables.tf`](infrastructure/modules/database/variables.tf) — password variable

### Audit & Traceability

- **Infrastructure as Code:** All infrastructure is defined in Terraform/Terragrunt — every change is versioned in Git, providing a complete audit trail
- **Resource tagging:** All resources are tagged with environment, project, and management tool for traceability
  - Tags: `env:dev`, `project:scaleway-starter-kit`, `managed-by:terragrunt`
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
