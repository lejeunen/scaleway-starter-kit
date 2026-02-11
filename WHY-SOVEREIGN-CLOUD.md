# Why Sovereign Cloud?

## The context has changed

European organizations have relied on US cloud providers for over a decade. That dependency is now a strategic risk.

Transatlantic relations are under pressure — trade disputes, diverging technology regulation, and shifting geopolitical alliances are forcing European governments and businesses to reconsider where their critical infrastructure lives and who ultimately controls it.

Digital sovereignty is no longer a policy aspiration. It is becoming a regulatory requirement and a business continuity concern.

## The legal problem

US law grants authorities access to data held by US companies — **regardless of where that data is physically stored**:

- The **CLOUD Act** (2018) allows US law enforcement to compel any US-headquartered company to hand over data, even if it resides in a European datacenter.
- **FISA Section 702** enables intelligence agencies to collect data on non-US persons without individual warrants — the issue at the heart of the Schrems II ruling that invalidated the EU-US Privacy Shield.

This is not a theoretical risk. It is a structural legal conflict between US surveillance law and European data protection (GDPR).

## What about US "sovereign cloud" offerings?

AWS, Google, and Microsoft have launched European sovereign cloud initiatives — with dedicated infrastructure, EU-resident staff, and European legal entities. These are meaningful **operational** safeguards.

However, the **legal** question remains open: the European subsidiaries are owned by US parent companies, and no court has ruled that this structure shields data from US jurisdiction. Most European legal experts and the EDPB (European Data Protection Board) consider the risk unresolved.

The choice is between **legal certainty** (a European-owned provider) and **legal risk** (a US-owned provider with operational separation).

## The alternative exists today

European cloud providers — Scaleway, OVH, Outscale, and others — offer mature, enterprise-grade infrastructure: managed Kubernetes, managed databases, load balancing, secret management, container registries, and more.

This project is a working demonstration: a complete cloud stack deployed entirely in France on [Scaleway](https://www.scaleway.com/), with infrastructure defined as code, HTTPS with automatic certificates, secrets managed through a dedicated service, and automated security scanning.

It is a starting point — not a turnkey solution — designed to show that sovereign cloud is practical, not just political.

## Regulation is accelerating

European regulations are creating mandatory demand for sovereign infrastructure:

- **NIS2** — Cybersecurity requirements for critical and important entities across the EU
- **DORA** — Operational resilience requirements for the financial sector and their ICT providers
- **SecNumCloud** — France's highest cloud security certification, increasingly required for public sector and sensitive data
- **GDPR** — Data protection obligations that structurally conflict with US extraterritorial surveillance laws

Organizations that begin their migration now will have a competitive advantage when compliance deadlines arrive. Those that wait will be forced to move under time pressure.

## Learn more

- [Technical overview](README.md) — Architecture, setup, and deployment guide
- [Compliance & sovereignty](COMPLIANCE.md) — Legal framework, technical controls, and regulatory mapping ([version française](COMPLIANCE.fr.md))
- [Live demo](https://sovereigncloudwisdom.eu/) — A sample application running on this infrastructure
- [Source code](https://github.com/lejeunen/scaleway-starter-kit) — Fully open-source infrastructure and deployment
