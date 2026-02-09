# Conformité & Cloud Souverain

Ce projet est conçu pour répondre aux exigences européennes en matière de souveraineté numérique et de conformité réglementaire, en s'appuyant sur **Scaleway**, un fournisseur cloud français disposant de datacenters en France et en Europe.

## Table des matières

- [Cadre juridique](#cadre-juridique)
  - [Le problème du CLOUD Act américain](#le-problème-du-cloud-act-américain)
  - [Souveraineté numérique européenne](#souveraineté-numérique-européenne)
  - [SecNumCloud](#secnumcloud)
  - [RGPD](#rgpd)
- [Mesures techniques](#mesures-techniques)
  - [Localisation des données](#localisation-des-données)
  - [Sécurité réseau](#sécurité-réseau)
  - [Chiffrement](#chiffrement)
  - [Gestion des secrets](#gestion-des-secrets)
  - [Audit & Traçabilité](#audit--traçabilité)
- [Cartographie réglementaire](#cartographie-réglementaire)
  - [Directive NIS2](#directive-nis2)
  - [DORA (Secteur financier)](#dora-secteur-financier)
  - [Matrice d'applicabilité](#matrice-dapplicabilité)

---

## Cadre juridique

### Le problème du CLOUD Act américain

Le CLOUD Act américain (Clarifying Lawful Overseas Use of Data Act, 2018) autorise la justice américaine à contraindre les entreprises dont le siège est aux États-Unis à divulguer les données stockées sur leurs serveurs — **quel que soit le lieu physique de stockage de ces données**. Cela signifie que des données hébergées sur AWS, Azure ou GCP dans un datacenter européen peuvent être soumises à la juridiction américaine.

Cela entre directement en conflit avec :
- **L'article 48 du RGPD**, qui restreint les transferts de données personnelles vers des autorités de pays tiers en l'absence d'accord international
- **L'arrêt Schrems II** (CJUE, juillet 2020), qui a invalidé le Privacy Shield UE-US et soulevé des inquiétudes quant aux clauses contractuelles types lorsque les sous-traitants sont soumis aux lois de surveillance américaines

En utilisant un **fournisseur cloud européen** non soumis à la juridiction américaine, ce projet élimine le conflit juridique structurel entre le CLOUD Act et le RGPD.

### Souveraineté numérique européenne

L'Union européenne et ses États membres promeuvent activement la souveraineté numérique à travers :
- **EUCS (European Cybersecurity Certification Scheme for Cloud Services)** — schéma européen de certification cloud
- **SecNumCloud** (France) — certification de sécurité de l'ANSSI pour les fournisseurs cloud
- **C5** (Allemagne) — standard de sécurité cloud du BSI
- **Directive NIS2** (2023) — exigences de cybersécurité pour les infrastructures critiques à l'échelle européenne
- **DORA** (Digital Operational Resilience Act) — exigences de résilience pour le secteur financier

### SecNumCloud

[SecNumCloud](https://www.anssi.gouv.fr/enjeux-technologiques/cloud/) est une certification de sécurité délivrée par l'**ANSSI** (Agence Nationale de la Sécurité des Systèmes d'Information). C'est le plus haut niveau de certification de sécurité cloud en France.

Scaleway est actuellement en cours de qualification SecNumCloud 3.2 pour ses services cloud. Cette certification atteste du respect d'exigences de sécurité rigoureuses, notamment :
- Sécurité physique des datacenters
- Contrôles d'accès logiques
- Chiffrement des données
- Procédures de réponse aux incidents
- Protection contre les juridictions extra-européennes

SecNumCloud est de plus en plus exigé pour :
- Le secteur public français (Code de la Commande Publique)
- L'hébergement de données de santé (HDS)
- Les opérateurs de services essentiels (OSE) dans le cadre de NIS2

### RGPD

Cette infrastructure contribue à la conformité RGPD à travers :

**Protection des données dès la conception (Article 25)**

- **Isolation réseau :** toutes les ressources de calcul et de base de données sont déployées dans un réseau privé (`172.16.0.0/22`) sans accès direct à internet
  - *Code :* [`infrastructure/modules/vpc/main.tf`](infrastructure/modules/vpc/main.tf)
- **Base de données privée :** PostgreSQL n'est accessible que depuis le réseau privé — aucun point d'accès public n'existe
  - *Code :* [`infrastructure/modules/database/main.tf`](infrastructure/modules/database/main.tf) — bloc `private_network`
- **Point d'entrée unique :** seul le load balancer dispose d'une IP publique, servant de point d'accès unique
  - *Code :* [`infrastructure/modules/load-balancer/main.tf`](infrastructure/modules/load-balancer/main.tf)

**Minimisation des données & Limitation des finalités**

- L'infrastructure est dimensionnée au strict nécessaire
- La séparation des environnements (dev/staging/prod) empêche le mélange des données

**Droit à l'effacement (Article 17)**

- PostgreSQL managé supporte les opérations SQL standard de suppression (`DELETE`)
- Scaleway fournit des garanties de destruction des données lors de la suppression des instances

---

## Mesures techniques

### Localisation des données

Toutes les ressources d'infrastructure de ce projet sont déployées exclusivement en **France** :

| Ressource                     | Région           | Zone       |
|-------------------------------|------------------|------------|
| VPC & Réseau Privé            | `fr-par` (Paris) | —          |
| Cluster Kubernetes (Kapsule)  | `fr-par`         | `fr-par-1` |
| Base de données PostgreSQL    | `fr-par`         | —          |
| Load Balancer                 | —                | `fr-par-1` |
| État Terraform (S3)           | `fr-par`         | —          |

Aucune donnée ne quitte le territoire français. Les datacenters parisiens de Scaleway (DC2-DC5) sont situés en Île-de-France.

**Référence code :** la région et la zone sont imposées dans [`infrastructure/root.hcl`](infrastructure/root.hcl) au niveau du provider, empêchant tout déploiement accidentel hors de France.

### Sécurité réseau

```
Internet → Load Balancer (IP publique) → Réseau Privé (172.16.0.0/22) → Kapsule / PostgreSQL
```

- **Isolation VPC :** toutes les ressources internes communiquent via un réseau privé
- **Aucune IP publique** sur les nœuds Kubernetes ou les instances de base de données
- **Cilium CNI :** le cluster Kubernetes utilise Cilium, qui permet des politiques réseau granulaires pour le contrôle du trafic entre pods
  - *Code :* [`infrastructure/modules/kapsule/main.tf`](infrastructure/modules/kapsule/main.tf) — `cni = "cilium"`
- **Health checks :** le load balancer effectue des vérifications HTTP pour s'assurer que seuls les backends sains reçoivent du trafic
  - *Code :* [`infrastructure/modules/load-balancer/main.tf`](infrastructure/modules/load-balancer/main.tf)

### Chiffrement

**Au repos**

- **Stockage base de données :** les volumes SBS (Scaleway Block Storage) utilisent le chiffrement AES-256 par défaut
  - *Code :* [`infrastructure/modules/database/main.tf`](infrastructure/modules/database/main.tf) — `volume_type = "sbs_5k"`
- **Volumes persistants Kubernetes :** basés sur SBS, chiffrés par défaut

**En transit**

- **Communication provider :** tous les appels API Scaleway utilisent TLS 1.2+
- **API Kubernetes :** accessible uniquement via HTTPS (kubeconfig utilise TLS)
- **Load balancer :** supporte la terminaison HTTPS (à configurer par application)

### Gestion des secrets

- Tous les identifiants (clés API, mots de passe base de données) sont issus de variables d'environnement — jamais codés en dur
  - *Code :* `.env.example` pour le modèle d'identifiants, `.gitignore` exclut `.env`
- Les sorties Terraform sensibles sont marquées `sensitive = true` pour empêcher toute exposition accidentelle dans les logs
  - *Code :* [`infrastructure/modules/kapsule/outputs.tf`](infrastructure/modules/kapsule/outputs.tf) — sortie kubeconfig
  - *Code :* [`infrastructure/modules/database/variables.tf`](infrastructure/modules/database/variables.tf) — variable mot de passe

### Audit & Traçabilité

- **Infrastructure as Code :** toute l'infrastructure est définie en Terraform/Terragrunt — chaque modification est versionnée dans Git, fournissant une piste d'audit complète
- **Tagging des ressources :** toutes les ressources sont taguées avec l'environnement, le projet et l'outil de gestion pour la traçabilité
  - Tags : `env:dev`, `project:scaleway-starter-kit`, `managed-by:terragrunt`
- **Pipeline de validation :** le script [`scripts/validate.sh`](scripts/validate.sh) exécute :
  - Vérification du formatage HCL
  - Validation Terraform
  - Analyse du graphe de dépendances
  - Linting TFLint
  - **Scan de sécurité Trivy** (sévérités HIGH et CRITICAL)

---

## Cartographie réglementaire

### Directive NIS2

La directive NIS2 (UE 2022/2555) renforce les exigences de cybersécurité pour les organisations opérant des infrastructures critiques. La conformité complète à NIS2 nécessite une approche organisationnelle plus large, mais ce projet adresse plusieurs domaines pertinents :

- **Gestion des risques :** l'approche Infrastructure-as-Code permet des déploiements reproductibles et auditables
- **Gestion des incidents :** la supervision automatisée (health checks, autohealing) permet une détection et une réponse rapides
- **Continuité d'activité :** sauvegardes automatisées, autoscaling et capacités d'auto-réparation
- **Sécurité de la chaîne d'approvisionnement :** le recours à un fournisseur européen en cours de qualification SecNumCloud réduit le risque lié aux tiers

### DORA (Secteur financier)

Le Digital Operational Resilience Act (UE 2022/2554) s'applique aux entités financières et à leurs prestataires de services TIC. La conformité DORA couvre la gouvernance, les processus et la technologie ; cette infrastructure contribue à plusieurs domaines clés :

- **Gestion des risques TIC :** scan de sécurité automatisé, isolation réseau, chiffrement
- **Tests de résilience :** scripts de validation pour le test continu de l'infrastructure
- **Risque tiers :** fournisseur européen non soumis aux lois extraterritoriales d'accès aux données
- **Signalement d'incidents :** infrastructure taguée et auditable permettant une investigation rapide des incidents

### Matrice d'applicabilité

| Réglementation                   | Périmètre                                              | Ce projet                                                    |
|----------------------------------|--------------------------------------------------------|--------------------------------------------------------------|
| **RGPD**                         | Tout organisme traitant des données personnelles UE    | Localisation des données en France, chiffrement, isolation réseau |
| **SecNumCloud**                  | Secteur public français, données sensibles             | Scaleway est en cours de qualification SecNumCloud            |
| **NIS2**                         | Entités essentielles & importantes dans l'UE           | Piste d'audit IaC, résilience automatisée, scan de sécurité  |
| **DORA**                         | Secteur financier & prestataires TIC                   | Résilience, tests, fournisseur européen                      |
| **HDS**                          | Données de santé en France                             | SecNumCloud + localisation des données en France              |
| **Code de la Commande Publique** | Marchés publics français                               | Fournisseur cloud souverain, données en France               |
