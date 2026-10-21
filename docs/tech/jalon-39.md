# Jalon 39 — Gouvernance après la 1.0

> **PLAN — aucun code de jeu n'est écrit par ce document** (seuls des tests de contrat sont
> prévus). Source de vérité : `docs/design/passes/j39-v1-chatgpt.md` (7 décisions verrouillées).
> Décisions et textes recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes
> recommandés)**. Texte manquant : proposition marquée **[D]**.

> Objectif : **un cadre pour maintenir Kanto 2026 après la 1.0** : une modification n'entre pas
> parce qu'elle est possible, mais parce qu'elle répond à un besoin, respecte les contrats et passe
> par une décision traçable. Aucun nouveau contenu jouable.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Sources de vérité multiples | `etat-projet.md` (« Reportés »), `roadmap.md`, `docs/tech/jalon-*.md`, `CLAUDE.md` | Risque de **plusieurs backlogs** : en choisir un (T1) |
| Contrats historiques | Écrits dans les dossiers de conception et les plans ; testés en partie par ≈ 6 050 tests GUT | Un contrat écrit n'est pas un test : T3 recense |
| Branches | `main` + branches `jalon-*`, `art-*`, `docs/*` ; aucune `release/*` | Politique à poser avec le J37 |
| Revues | Règles de `CLAUDE.md` (tests ciblés, suite complète avant fusion) | Cadence qualité à formaliser |
| Prototypes | Dossier `proto/` (hors export) | Modèle possible d'isolement |

### 0.1 Ce qui peut commencer tout de suite
- **T3** recensement des contrats et de leurs tests existants (lecture seule) ; **T1** modèle de
  backlog et de décision ; **T6** charte technique (document déjà rédigé par la passe).

### 0.2 Ce qui attend
- Application réelle (versions, prototypes, revues) : une 1.0 produite (J37) et le backlog du J38.
  Sans 1.0, la gouvernance **se prépare mais ne s'applique pas encore**.

## 1. Contrats

### 1.1 Backlog unique
Une seule source de vérité. Recommandation de la passe : GitHub Issues si l'outil est déjà utilisé.
Champs : identifiant, type (bug, maintenance, ergonomie, évolution), problème, justification,
impact, priorité, dépendances, critères d'acceptation, risques, version cible (1.0.x, mineure,
majeure, non décidée), décision (acceptée, reportée, rejetée, à prototyper), preuves. Rapprocher les
idées du J35 et le backlog du J38 pour éviter les doublons.

### 1.2 Versions
Correctif 1.0.x (compatible, pas de contenu majeur) ; mineure 1.1.0 (améliorations validées, sans
rupture volontaire des sauvegardes) ; majeure 2.0.0 (plan de migration et décision distincte). Le
numéro ne garantit pas la compatibilité : les tests de sauvegarde restent obligatoires.

### 1.3 Contrats protégés par des tests
| Contrat | Origine | Test à préserver |
|---|---|---|
| CS hybrides | J16 | CS possédée + Pokémon compatible + Badge : utilisation sans apprentissage (Coupe/Cascade, Surf/Âme, Force/Prisme) |
| Safari | J23 | 500 pas, 30 Safari Balls |
| Légendaires uniques | J24/J29/J31 | Pas de duplication |
| Sylphe SARL | J26 | Progression, rival, Giovanni, cadeaux uniques |
| Arènes | J27/J28 | Badges, récompenses, accès |
| Route 23 et Route Victoire | J29 | Contrôle des huit Badges ; puzzles de Force persistants |
| Ligue et Panthéon | J30 | Cinq combats consécutifs sans Centre ; défaite : retour au Centre du Plateau ; historique conservé |
| Grotte Inconnue | J31 | Accès après première victoire |
| Pokédex | J32 | Règles d'obtention cohérentes |
| Sauvegardes | J33–J38 | Migrations, intégrité |

### 1.4 Prototype isolé
Jamais sur la branche stable. Hypothèse, portée, critères de réussite, date ou condition de clôture ;
données en copies isolées (jamais les vraies sauvegardes). Un prototype concluant **ouvre une
décision**, il ne déclenche pas l'intégration.

## 2. Tâches

### T1 — Backlog unique et modèle de décision (39A, Sonnet)
Labels et modèle de ticket GitHub [D] ; fichier `docs/tech/decisions.md` [D] en journal court
(date, décision, qui, pourquoi) pour les décisions qui ne sont pas des tickets. Fusion des idées de
J35 et J38. Critère : un seul endroit où lire « qu'est-ce qui est décidé ».

### T2 — Politique de versions et de branches (39B, Sonnet)
Branches indicatives du dossier (`main`, `release/1.0`, `hotfix/issue-xxx`, `feature/prototype-xxx`,
`release/1.1`) **confrontées aux branches réelles** ; règles de nommage cohérentes avec les noms
actuels (`jalon-NN`, `art-…`, `docs/…`).

### T3 — Tests contractuels (39C, Opus)
Pour chaque ligne du §1.3 : test GUT existant (chemin), test à écrire, ou « non testable
automatiquement ». Les tests sont regroupés ou étiquetés (`tests/contract/` [D]) pour pouvoir les
lancer ensemble par `tools/test.sh -f contrat`. Critère : table complète, aucun contrat « testé »
sans chemin de fichier.

### T4 — Procédure de prototype et d'intégration (39D)
Fiche d'une page : hypothèse, portée, critères, clôture ; cycle accepté ou archivé.

### T5 — Cadence qualité et indicateurs (39E)
À chaque pull request : tests et contrats touchés. À chaque correctif : régression ciblée et
sauvegardes. Mensuelle si développement actif : incidents, dette, performances. Trimestrielle :
dépendances, sécurité, documentation, backlog. Avant livraison : QA, compatibilité, conformité,
Go/No-Go. Indicateurs utiles pour décider (P0/P1 ouverts, régressions, tests de sauvegarde,
performances par appareil, réussite de la CI). Ce sont des **recommandations**, pas des tâches déjà
programmées.

### T6 — Charte, roadmap et décision de cycle (39F, Kevin)
Charte en 10 points (ci-dessous), roadmap priorisée, décision explicite : poursuivre la
maintenance, lancer une évolution approuvée, ou suspendre.

## 3. Textes
**Charte technique — validée par Kevin le 2026-10-21 (validation d'avance des textes recommandés)** :
1. La stabilité de la version 1.0 prime sur l'ajout de fonctionnalités.
2. Toute demande entre dans un backlog unique.
3. Toute évolution possède des critères d'acceptation.
4. Les contrats historiques sont protégés par des tests.
5. Les prototypes restent isolés jusqu'à validation.
6. Les sauvegardes et leur compatibilité sont prioritaires.
7. Chaque livraison est identifiable et reproductible.
8. La conformité de diffusion reste indépendante du Go technique.
9. Les incidents alimentent les décisions futures.
10. Aucun nouveau cycle de développement n'est ouvert sans arbitrage.

## 4. Critères d'acceptation (« J39 réalisé »)
Backlog unique opérationnel ; décisions traçables ; politique de versions documentée ; contrats
critiques couverts par des tests **vérifiés** ; prototypes isolés ; revues qualité organisées ;
charte et roadmap associées à une décision explicite.

## 5. QA téléphone
Aucune QA dédiée. Un contrôle : les tests de contrat tournent en suite complète sur le Mac.

## 6. Risques
Backlogs en double ; contrat écrit mais non testé ; formalisme disproportionné (le processus doit
rester **proportionné** : un correctif de texte n'a pas la revue d'un changement de sauvegarde).

## 7. Points ouverts pour Kevin
1. Outil du backlog unique : GitHub Issues ? [D : oui, un seul projet]
2. Veux-tu un journal de décisions séparé (`docs/tech/decisions.md`) ? [D : oui, court]
3. Décision de cycle (T6) : à prendre à la fin, avec le rapport du J40.
