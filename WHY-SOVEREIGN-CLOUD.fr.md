# Pourquoi le cloud souverain ?

## Le contexte a changé

Les organisations européennes s'appuient sur des fournisseurs cloud américains depuis plus de dix ans. Cette dépendance est désormais un risque stratégique.

Les relations transatlantiques sont sous tension — différends commerciaux, divergences en matière de régulation technologique, alliances géopolitiques mouvantes. Les gouvernements et entreprises européens sont amenés à reconsidérer où réside leur infrastructure critique et qui la contrôle réellement.

La souveraineté numérique n'est plus une aspiration politique. Elle devient une exigence réglementaire et un enjeu de continuité d'activité.

## Le problème juridique

Le droit américain confère aux autorités un accès aux données détenues par les entreprises américaines — **quel que soit le lieu physique de stockage** :

- Le **CLOUD Act** (2018) autorise la justice américaine à contraindre toute entreprise dont le siège est aux États-Unis à produire des données, même si celles-ci se trouvent dans un datacenter européen.
- **FISA Section 702** permet aux agences de renseignement de collecter les données de personnes non américaines sans mandat individuel — le problème central de l'arrêt Schrems II qui a invalidé le Privacy Shield UE-US.

Ce n'est pas un risque théorique. C'est un conflit juridique structurel entre le droit de surveillance américain et la protection des données européenne (RGPD).

## Et les offres « cloud de confiance » des providers américains ?

AWS, Google et Microsoft ont lancé des initiatives de cloud souverain en Europe — avec des infrastructures dédiées, du personnel résident de l'UE et des entités juridiques européennes. Ce sont des garanties **opérationnelles** réelles.

Cependant, la question **juridique** reste ouverte : les filiales européennes sont détenues par des sociétés mères américaines, et aucun tribunal ne s'est prononcé sur la capacité de cette structure à protéger les données de la juridiction américaine. La plupart des juristes européens et le CEPD (Comité Européen de la Protection des Données) considèrent que le risque subsiste.

Le choix se résume à **certitude juridique** (un fournisseur européen) ou **risque juridique** (un fournisseur américain avec séparation opérationnelle).

## L'alternative existe aujourd'hui

Les fournisseurs cloud européens — Scaleway, OVH, Outscale et d'autres — proposent une infrastructure mature : Kubernetes managé, bases de données managées, load balancing, gestion des secrets, registres de conteneurs, et bien plus.

Ce projet en est la démonstration : une infrastructure cloud complète déployée entièrement en France sur [Scaleway](https://www.scaleway.com/), avec l'infrastructure définie en code, HTTPS avec certificats automatiques, secrets gérés via un service dédié, et scans de sécurité automatisés.

C'est un point de départ — pas une solution clé en main — conçu pour montrer que le cloud souverain est un choix pragmatique, pas seulement un discours politique.

## La réglementation accélère

Les réglementations européennes créent une demande contraignante en matière d'infrastructure souveraine :

- **NIS2** — Exigences de cybersécurité pour les entités essentielles et importantes dans l'UE
- **DORA** — Exigences de résilience opérationnelle pour le secteur financier et ses prestataires TIC
- **SecNumCloud** — La plus haute certification de sécurité cloud en France, de plus en plus exigée pour le secteur public et les données sensibles
- **RGPD** — Obligations de protection des données qui entrent structurellement en conflit avec les lois de surveillance extraterritoriale américaines
- **EU Cloud Sovereignty Framework** — La Commission européenne formalise une classification des niveaux de souveraineté cloud, avec des critères mesurables pour définir ce que « souverain » signifie concrètement

Les organisations qui entament leur migration dès maintenant auront un avantage compétitif à l'échéance des obligations de conformité. Celles qui attendent devront migrer dans l'urgence.

## En savoir plus

- [Présentation technique](README.md) — Architecture, installation et guide de déploiement
- [Conformité & souveraineté](COMPLIANCE.fr.md) — Cadre juridique, mesures techniques et cartographie réglementaire ([English version](COMPLIANCE.md))
- [Démo en ligne](https://sovereigncloudwisdom.eu/) — Une application exemple fonctionnant sur cette infrastructure
- [Code source](https://github.com/lejeunen/scaleway-starter-kit) — Infrastructure et déploiement entièrement open source
