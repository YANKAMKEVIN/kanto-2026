# Kanto 2026 — J39 : Gouvernance technique et maîtrise des évolutions

> Dossier consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le lancement du J39**
> (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages verrouillés. Notes de
> la session de coordination à la fin.

Un cadre pour maintenir Kanto 2026 après la 1.0, décider des évolutions et protéger les mécaniques
validées. Changement fondamental : **aucune modification n'entre parce qu'elle est techniquement
possible** ; elle répond à un besoin identifié, respecte les contrats existants et passe par une
décision traçable.

## 1. Les sept décisions définitives

| # | Domaine | Arbitrage verrouillé |
|---|---|---|
| 1 | Périmètre | Gouvernance de la version 1.0 et préparation d'une feuille de route future |
| 2 | Demandes | Backlog unique, critères d'acceptation et décisions tracées |
| 3 | Versions | Distinguer correctifs 1.0.x, évolutions mineures et versions majeures |
| 4 | Gameplay | Tests contractuels des mécaniques historiques et de la progression |
| 5 | Évolutions | Prototype isolé et validation avant intégration stable |
| 6 | Qualité | Revues périodiques des incidents, sauvegardes, performances et dépendances |
| 7 | Sortie | Charte technique, roadmap priorisée et décision sur le prochain cycle |

Aucun nouveau contenu jouable : le J39 définit comment les évolutions futures sont proposées,
évaluées, validées et éventuellement implémentées.

## 2. Architecture de gouvernance

Besoin identifié (bug, retour testeur, dette, proposition) → **backlog unique** (description, impact,
priorité, critères) → **arbitrage** (accepter, reporter, rejeter, demander un prototype) → **prototype
isolé** (hors branche stable) → **validation** (tests, risques, compatibilité, décision) →
**planification** (correctif, mineure ou majeure) → **livraison contrôlée**.

Processus **proportionné** : un correctif de texte n'exige pas la revue d'une modification des
sauvegardes ou du combat.

## 3. Backlog unique et décisions traçables

Recommandation : backlog principal dans GitHub Issues ou l'outil déjà utilisé, **une seule source de
vérité**.

| Champ | Rôle |
|---|---|
| Identifiant | Référence unique |
| Type | Bug, maintenance, ergonomie, évolution |
| Problème | Situation observée ou besoin |
| Justification | Pourquoi agir |
| Impact | Joueurs, stabilité, performance ou maintenance |
| Priorité | Ordre de traitement |
| Dépendances | Systèmes et décisions concernés |
| Critères d'acceptation | Résultats vérifiables |
| Risques | Régression, sauvegardes, Android, droits |
| Version cible | 1.0.x, mineure, majeure ou non décidée |
| Décision | Acceptée, reportée, rejetée, à prototyper |
| Preuves | Tests, mesures ou retours disponibles |

Rapprocher les idées du J35 et le backlog du J38 pour éviter les doublons.

*Exemple fictif de format* — **UX-014, lisibilité des menus** : améliorer la lisibilité sur écrans
compacts si les tests démontrent un problème ; critères : aucun texte tronqué, commandes accessibles
au toucher, comportement inchangé sur S24 ; dépendances : UI Android, DA, tests multiappareils ;
décision : en attente de preuves.

## 4. Politique de versionnement

| Catégorie | Exemple | Usage |
|---|---|---|
| Correctif | 1.0.1 | Correction compatible, sans nouveau contenu majeur |
| Version mineure | 1.1.0 | Améliorations compatibles et validées |
| Version majeure | 2.0.0 | Changements structurants pouvant nécessiter de nouveaux contrats |

Esprit du versionnement sémantique, adapté à Android et aux règles de sauvegarde.

- **Correctif 1.0.x** : comportements validés et compatibilité des données conservés ; corriger un
  comportement incorrect est permis, mais documenté et testé.
- **Mineure** : évolutions approuvées sans rupture volontaire des sauvegardes.
- **Majeure** : plan de migration, évaluation des risques, décision distincte.

Le numéro ne garantit pas la compatibilité : les tests de sauvegarde restent obligatoires.

Branches indicatives (à confronter aux branches réelles) :

```
main
├── release/1.0
│   ├── hotfix/issue-xxx
│   └── tag v1.0.x
├── feature/prototype-xxx
└── release/1.1
```

## 5. Protection des contrats historiques

Les décisions J0–J32 deviennent des **tests de contrat**, pas seulement des documents.

| Contrat | Origine | Test à préserver |
|---|---|---|
| CS hybrides | J16 | Utilisation sur le terrain sans apprentissage obligatoire, sous conditions |
| Safari | J23 | 500 pas, 30 Safari Balls, objets et événements |
| Légendaires uniques | J24/J29/J31 | Pas de duplication après capture ou résolution |
| Sylphe SARL | J26 | Progression, rival, Giovanni, cadeaux uniques |
| Arènes | J27/J28 | Badges, récompenses et conditions d'accès |
| Route 23 | J29 | Contrôle des huit Badges |
| Route Victoire | J29 | Puzzles de Force et progression persistante |
| Ligue | J30 | Cinq combats consécutifs et reprise après défaite |
| Panthéon | J30 | Historique des victoires préservé |
| Grotte Inconnue | J31 | Accès après première victoire à la Ligue |
| Pokédex | J32 | Collection et règles d'obtention cohérentes |
| Sauvegardes | J33–J38 | Migrations et intégrité des données |

**Contrat des CS** : CS possédée + Pokémon compatible dans l'équipe + Badge requis = utilisation sur
le terrain sans enseigner la capacité. Coupe avec Cascade, Surf avec Âme, Force avec Prisme. Une
refonte de l'interface ne change pas ces règles.

**Contrat de la Ligue** : cinq combats consécutifs, sans Centre intermédiaire, ressources
persistantes ; une défaite termine la tentative et renvoie au Centre du Plateau Indigo. Une évolution
du combat ne supprime pas ces règles sans nouvel arbitrage explicite.

## 6. Prototypes isolés et intégration contrôlée

Jamais d'évolution développée directement sur la branche stable.

Cycle : demande acceptée pour étude → branche de prototype isolée → évaluation technique et UX →
**accepté** (planifier et tester l'intégration) ou **refusé / reporté** (archiver le résultat sans
toucher au stable).

Un prototype a une hypothèse, une portée limitée, des critères de réussite et une date ou condition de
clôture. Ses données ne touchent jamais les sauvegardes réelles (copies isolées si le schéma change).
Un prototype concluant **ouvre une nouvelle décision**, il ne déclenche pas l'intégration.

## 7. Qualité continue

| Fréquence proposée | Revue |
|---|---|
| À chaque pull request | Tests automatiques, contrats affectés, qualité |
| À chaque correctif | Régression ciblée et sauvegardes concernées |
| Mensuelle si développement actif | Incidents, dette technique et performances |
| Trimestrielle | Dépendances, sécurité, documentation et backlog |
| Avant chaque livraison | QA, compatibilité, conformité et Go/No-Go |

Recommandations, pas des tâches déjà programmées.

**Indicateurs utiles** (pour décider, pas pour produire des chiffres) : P0/P1 ouverts et durée de
résolution ; régressions réintroduites ; réussite des tests de sauvegarde ; stabilité et performances
par appareil suivi ; taux de réussite de la CI ; dépendances obsolètes ou vulnérables ; évolutions
approuvées, reportées, rejetées.

## 8. Dépendances J33–J38 → J39

| Dépendance | Origine | Condition J39 |
|---|---|---|
| Contrats de gameplay | J0–J32 | Règles documentées et testables |
| Régression globale | J33 | Scénarios critiques réutilisables |
| QA et versionnement | J34 | Builds traçables |
| Retours de testeurs | J35 | Besoins fondés sur des observations |
| Corrections et migrations | J36 | Compatibilité maîtrisée |
| Version 1.0 | J37 | Référence stable identifiée |
| Maintenance 1.0.x | J37 | Politique de correctifs disponible |
| CI et sécurité | J38 | Contrôles réutilisables |
| Documentation de reprise | J38 | Architecture et procédures accessibles |
| Backlog priorisé | J38 | Base du backlog unique J39 |

Pas de contradiction majeure. **Trois risques à vérifier dans le dépôt** : 1. duplication
documentaire (plusieurs registres ou backlogs : choisir une source de vérité) ; 2. un contrat écrit
n'est pas un test automatisé ; 3. sans 1.0 réellement produite, la gouvernance se prépare mais ne
s'applique pas encore.

## 9. Découpage technique

| Lot | Livrable |
|---|---|
| 39.0 | Audit J38, inventaire des outils et sources de vérité |
| 39A | Backlog unique et modèle de décision |
| 39B | Politique de versions et de branches |
| 39C | Tests contractuels des mécaniques et de la progression |
| 39D | Procédure de prototype isolé et d'intégration |
| 39E | Cadence qualité, indicateurs et revues |
| 39F | Charte technique, roadmap et décision sur le prochain cycle |

**« J39 réalisé »** : backlog unique opérationnel, décisions traçables, politique de versions
documentée, contrats critiques couverts par des tests vérifiés, prototypes isolés du stable, revues
qualité organisées ; charte et roadmap associées à une décision explicite (poursuivre la maintenance,
lancer une évolution approuvée ou suspendre les développements).

## 10. Charte technique (synthèse proposée)

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

## 11. Prompt de transmission à Claude (au lancement du J39)

> **Kanto 2026 — J39 : gouvernance technique et maîtrise des évolutions.** Rôle : architecte Godot,
> responsable qualité, mainteneur de version, auditeur technique. Mission : auditer le dépôt réel et
> préparer le J39 (gouvernance de la 1.0, backlog unique, politique de versions, tests contractuels,
> prototypes isolés, qualité continue, feuille de route).
>
> **Arbitrages verrouillés** (ne pas les rouvrir ; aucun contenu jouable) : 1. Gouvernance de la 1.0
> et feuille de route future. 2. Backlog unique, critères d'acceptation, décisions tracées.
> 3. Correctifs 1.0.x, mineures et majeures distinguées. 4. Tests contractuels des mécaniques
> historiques et de la progression. 5. Prototypes isolés, validés avant intégration stable. 6. Revue
> périodique des incidents, sauvegardes, performances, dépendances. 7. Charte technique, roadmap
> priorisée, décision sur le prochain cycle.
>
> **Phase 1 — Audit factuel** : dépôt, branche active, tags ; documentation ; tickets et backlog ; CI
> et tests ; conventions de branches et de versions ; résultats J33–J38 ; builds et sauvegardes de
> référence ; décisions de conformité. Classer : implémenté et vérifié ; présent mais incomplet ;
> spécifié seulement ; absent ; non vérifiable. Chemins, commits et résultats observés ; ne pas
> prétendre que la 1.0 existe si elle n'a pas été produite.
> **Phase 2 — Backlog unique** : sources existantes et consolidation sans perte d'historique ; modèle
> de ticket ; décisions accepté, reporté, rejeté, à prototyper.
> **Phase 3 — Versions** : règles 1.0.x, mineures, majeures ; branches et tags existants ;
> compatibilité des sauvegardes, migration, tests, retour arrière.
> **Phase 4 — Tests contractuels** : CS hybrides J16 ; Safari J23 ; légendaires J24/J29/J31 ; Sylphe
> J26 ; Arènes et Badges J27/J28 ; Route 23 et Route Victoire J29 ; Ligue et Panthéon J30 ; Grotte
> Inconnue et Mewtwo J31 ; Pokédex et stockage J32 ; sauvegardes J33–J38. Règles verrouillées
> préservées, aucun comportement inventé ; indiquer les tests existants et ceux à écrire.
> **Phase 5 — Prototypes** : branche isolée, hypothèse, critères, évaluation, décision ; aucune
> écriture sur les sauvegardes réelles ; pas de fusion automatique.
> **Phase 6 — Qualité continue** : contrôles par PR, correctif, livraison ; revues périodiques ;
> métriques réellement mesurables.
> **Phase 7 — Gouvernance et roadmap** : charte concise ; roadmap fondée sur les anomalies, besoins
> et contraintes documentés ; maintenance, dette, ergonomie et nouveaux contenus séparés ; aucun
> chantier sans décision explicite.
>
> **Livrables** : 1. Audit J38 → J39. 2. Cartographie des dépendances. 3. Consolidation du backlog.
> 4. Modèle de ticket et registre de décisions. 5. Politique de versions et de branches. 6. Matrice
> des tests contractuels. 7. Procédure de prototype. 8. Plan de qualité continue. 9. Charte
> technique. 10. Roadmap. 11. Lots 39.0 à 39F. 12. Checklist de sortie et décision sur le prochain
> cycle. 13. Prompts Codex par lots ; pour chaque lot : prérequis, fichiers concernés, modifications,
> tests, risques, critères, retour arrière.
>
> Conception et audit uniquement. Ne rien coder avant validation ; n'inventer aucun résultat, build,
> tag, incident ou métrique. DA 2D HD peinte, expérience tactile Android, progression historique
> préservées. Go technique toujours séparé de toute décision de diffusion.

---

## Note de la session de coordination (2026-10-19)

**Le J39 a déjà un début d'existence** : la règle « toute décision de game design non documentée →
la poser à Kevin » (`CLAUDE.md`), les dossiers verrouillés de `docs/design/passes/`, la stratégie
d'accélération et la CI GitHub (`.github/workflows/godot-tests.yml`) jouent déjà une partie du rôle
de la charte, du registre de décisions et de la qualité continue. L'audit 39.0 part de ces sources
de vérité plutôt que d'en créer de nouvelles (risque n° 1 du §8).
