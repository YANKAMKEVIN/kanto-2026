# Kanto 2026 — J38 : Pérennisation technique et préparation des évolutions

> Dossier consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le lancement du J38**
> (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages verrouillés. Notes de
> la session de coordination à la fin.

De la préparation de la 1.0 à la **pérennisation** : un projet facile à maintenir, une chaîne de
compilation sécurisée, et la garantie qu'une mise à jour ne détruira pas des mois de progression.
Principe : **améliorer la robustesse sans modifier l'expérience de jeu**.

## 1. Les sept décisions définitives

| # | Domaine | Arbitrage verrouillé |
|---|---|---|
| 1 | Périmètre | Pérenniser la version 1.0, sans nouveau contenu |
| 2 | Architecture | Audit ciblé, documentation et refactorisations à faible risque |
| 3 | Sécurité | Audit des dépendances, secrets, signatures et chaîne de compilation |
| 4 | Sauvegardes | Restauration, compatibilité et intégrité sur plusieurs versions 1.0.x |
| 5 | Automatisation | Compilation, tests, qualité et archivage automatisés |
| 6 | Documentation | Guide de reprise, architecture, conventions et incidents |
| 7 | Évolutions | Backlog priorisé, sans implémentation avant décision |

Aucune nouvelle région, espèce, quête ou mécanique.

## 2. Architecture générale

J37 (version 1.0 : build identifié, maintenance, support) → quatre chantiers : **Architecture**
(dette technique maîtrisée), **Sécurité** (dépendances et secrets), **Sauvegardes** (compatibilité et
récupération), **Automatisation** (tests, builds, archives) → **documentation de reprise**
(reproduire, diagnostiquer, corriger) → **backlog priorisé** (préparer la suite sans toucher à la 1.0).

## 3. Architecture et dette technique

Pas de réécriture : une refonte générale multiplierait les régressions.

| Domaine | Vérification |
|---|---|
| Scènes Godot | Responsabilités, dépendances et réutilisation |
| Scripts | Duplication, couplage et complexité |
| Données Pokémon | Cohérence entre catalogue, combat et Pokédex |
| Cartes | Transitions, collisions et événements |
| Combat | Séparation des règles et de la présentation |
| Sauvegardes | Versionnement, validation et migrations |
| Android | Dépendances natives et cycle de vie |
| Tests | Couverture des systèmes critiques |

**Refactorisation admissible** seulement si elle répond à un problème identifié, conserve le
comportement observable, a des tests de non-régression et s'annule proprement. Petites modifications
isolées (duplication, interfaces, fonctions testables, documentation des dépendances). À éviter :
remplacer en même temps combat, cartes et sauvegardes au nom d'une architecture plus élégante.

## 4. Sécurité de la chaîne de compilation

| Contrôle | Exigence |
|---|---|
| Version Godot | Version exacte documentée |
| Plugins et extensions | Inventaire et licences |
| Dépendances Android | Versions et provenance identifiées |
| Vulnérabilités | Audit des composants concernés |
| Secrets | Aucun mot de passe ou jeton dans le dépôt |
| Signature APK | Clé protégée, accès limité |
| CI | Permissions minimales |
| Artefacts | Empreintes et traçabilité |
| Archives | Conservation et restauration testées |

Secrets hors du dépôt ; journaux sans valeurs sensibles. Un secret réellement exposé ne se règle pas
en le retirant du dernier commit : évaluer révocation ou rotation, et l'exposition dans l'historique.

**Provenance** : chaque APK relié à un commit, une configuration, une version d'outil, une signature
et une empreinte SHA-256. Pas seulement « le jeu compile », mais « on sait à partir de quoi cette APK
a été construite ».

## 5. Sauvegardes : compatibilité sur plusieurs versions

| Sauvegarde source | Application cible | Résultat attendu |
|---|---|---|
| 1.0.0 | 1.0.1 | Chargement et progression conservée |
| 1.0.0 | 1.0.2 | Migrations successives si nécessaires |
| 1.0.1 | 1.0.2 | Chargement valide |
| 1.0.2 | 1.0.1 | Refus sûr si rétrocompatibilité non garantie |
| Sauvegarde interrompue | Même version | Récupération de la dernière copie valide |
| Sauvegarde corrompue | Version récente | Erreur contrôlée, sans écrasement destructeur |

(Numéros illustratifs.) Une mise à jour compatible n'implique pas qu'un retour arrière soit possible :
une sauvegarde plus récente est refusée proprement si son schéma n'est pas pris en charge.

**Invariants** : Pokémon et caractéristiques, stockage, Badges, Pokédex, objets, événements uniques,
Panthéon, post-game. Captures légendaires, échanges locaux, évolutions et remises d'objets restent
atomiques.

**Tests de récupération** : écriture interrompue puis redémarrage ; sauvegarde incomplète ; ancien
schéma ; sauvegarde d'une version plus récente ; copies de secours ; mêmes tests avec stockage presque
plein. Une procédure n'est validée qu'**exécutée réellement** sur des données représentatives.

## 6. Automatisation des builds et de la qualité

Pipeline cible : commit / pull request → validation statique (scripts, ressources, configuration) →
tests automatisés (règles, sauvegardes, événements) → import et export Godot (projet, compilation
Android) → contrôles de sécurité (dépendances, permissions, secrets) → archivage (rapports,
manifestes, empreintes).

| Déclencheur | Contrôles |
|---|---|
| Pull request | Analyse statique, tests rapides, validation des ressources |
| Fusion dans la branche stable | Tests étendus et export de vérification |
| Tag de version | Build identifié, contrôles et archivage |
| Correctif 1.0.x | Régression ciblée + tests critiques |
| Mise à jour des dépendances | Compatibilité, sécurité et tests Android |

Aucun secret de signature exposé aux pull requests non approuvées ; un build de vérification non
signé suffit aux premières étapes. **Limites** : l'automatisation ne remplace ni l'examen des décors
peints, ni la lisibilité des dialogues, ni la précision tactile, ni les performances sur appareil. Elle
réduit les erreurs répétitives, sans fausse impression de qualité garantie.

## 7. Documentation développeur

Structure proposée (à adapter aux dossiers réels) :

```
docs/
├── README_DEVELOPMENT.md
├── architecture/  (overview, gameplay-systems, world-and-events, save-schema)
├── android/       (build-and-export, signing, compatibility)
├── quality/       (testing, performance, regression-matrix)
├── operations/    (release-process, incident-response, save-recovery, rollback)
└── roadmap/       (backlog)
```

**Guide de reprise** : lancer le projet ; où sont les systèmes ; ajouter un test ; construire une
APK ; reproduire un bug ; migrer une sauvegarde ; préparer un correctif.

**Trois procédures d'incident** :

- **Sauvegarde corrompue** : arrêter les écritures destructrices, préserver les données, diagnostiquer
  le schéma, tester la récupération.
- **Build compromis ou secret exposé** : interrompre la distribution concernée, analyser l'exposition,
  révoquer ou remplacer les secrets si possible, reconstruire une version sûre.
- **Régression critique après mise à jour** : suspendre la diffusion, identifier les versions
  affectées, préparer un correctif compatible ; ne pas recommander de rétrogradation si les
  sauvegardes risquent de devenir illisibles.

## 8. Backlog des évolutions futures

Le J38 prépare les idées, sans les implémenter.

| Catégorie | Exemple de sujet | Statut J38 |
|---|---|---|
| Fiabilité | Réduire davantage les risques de sauvegarde | À prioriser |
| Ergonomie | Améliorations issues des retours testeurs | À étudier |
| Technique | Optimisations et dette documentée | À estimer |
| Contenu | Éventuelles extensions futures | Hors périmètre |

Chaque proposition : objectif, justification, coût estimé, dépendances, risques, critères
d'acceptation. Être au backlog ne valide pas une fonctionnalité.

**Ordre de décision du backlog** (distinct des gravités P0–P3 des anomalies) : P1 fiabilité et
protection des données ; P2 compatibilité et performances ; P3 ergonomie et confort étayés par les
retours ; P4 nouvelles fonctionnalités, uniquement après arbitrage ultérieur.

## 9. Dépendances J33–J37 → J38

| Dépendance | Origine | Condition J38 |
|---|---|---|
| Architecture fonctionnelle | J0–J32 | Contrats de gameplay préservés |
| Tests de progression | J33 | Base de régression réutilisable |
| Configuration Android | J34 | Export et signature documentés |
| Rapports de bugs | J35 | Défauts et retours traçables |
| Migrations bêta | J36 | Schémas et tests existants |
| Version stable candidate | J36 | Validation technique documentée |
| Version 1.0 | J37 | Commit, tag et build identifiés |
| Maintenance 1.0.x | J37 | Procédure et branches connues |
| Support et incidents | J37 | Tickets et règles de priorité |
| Licences et conformité | J34–J37 | Contraintes conservées |

Cohérent avec les jalons précédents, sans modification du gameplay. Dépendances critiques : une 1.0
de référence, une configuration de build exploitable, des sauvegardes représentatives. Si le J37
n'est pas réalisé, audit, documentation, tests et pipeline peuvent commencer, mais la pérennisation
de la 1.0 ne peut pas être déclarée achevée.

## 10. Découpage technique

| Lot | Livrable |
|---|---|
| 38.0 | Audit de la version 1.0, des dépendances et de la dette |
| 38A | Refactorisations ciblées et documentation d'architecture |
| 38B | Sécurité des dépendances, secrets, signatures et CI |
| 38C | Tests de compatibilité et récupération des sauvegardes |
| 38D | Automatisation des builds, tests et archivage |
| 38E | Documentation de reprise et procédures d'incident |
| 38F | Backlog priorisé, rapport de pérennisation et décision de sortie |

**« J38 terminé »** : risques principaux identifiés ; refactorisations retenues couvertes par des
tests ; contrôles de sécurité et pipeline exécutables ; scénarios de récupération vérifiés ;
documentation permettant la reprise ; backlog priorisé et documenté, **sans aucune évolution
fonctionnelle implémentée** au titre du J38.

## 11. Prompt de transmission à Claude (au lancement du J38)

> **Kanto 2026 — J38 : pérennisation technique de la version 1.0.** Rôle : architecte Godot,
> auditeur de sécurité, responsable QA, ingénieur de maintenance. Mission : auditer le dépôt réel et
> préparer le J38 (architecture maintenable, sécurité des builds, compatibilité des sauvegardes,
> automatisation, documentation développeur, backlog).
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Pérennisation de la 1.0, sans nouveau contenu.
> 2. Audit architectural ciblé, documentation, refactorisations à faible risque. 3. Audit des
> dépendances, secrets, signatures et chaîne de compilation. 4. Restauration, compatibilité et
> intégrité sur plusieurs versions 1.0.x. 5. Automatisation de la compilation, des tests, des
> contrôles qualité et de l'archivage. 6. Guide de reprise, architecture, conventions, incidents.
> 7. Backlog priorisé sans implémentation avant décision.
>
> **Phase 1 — Audit factuel** : dépôt, branche active, tags, scripts, scènes, exports Android, CI,
> tests, sauvegardes, livrables J37 ; existence effective de la 1.0 et de son dossier. Classer :
> implémenté et vérifié ; présent mais incomplet ; spécifié seulement ; absent ; non vérifiable ;
> chemins et résultats observés. Si le J37 n'est pas terminé, séparer le réalisable du bloqué.
> **Phase 2 — Architecture** : dépendances fragiles, duplications, scripts trop couplés, systèmes peu
> testés ; refactorisations petites, isolées, réversibles, testées ; pas de refonte générale ;
> contrats J0–J32 et DA 2D HD peinte orthogonale préservés.
> **Phase 3 — Sécurité** : Godot et extensions, dépendances Android, licences, secrets (fichiers et
> historique si accessible), permissions CI, protection de la signature, provenance et archivage des
> artefacts ; aucune valeur sensible dans le rapport ; remédiation et rotation si un secret est
> exposé.
> **Phase 4 — Sauvegardes** : matrice entre les 1.0.x réellement disponibles ; migrations, secours,
> écritures interrompues, corruption, retour vers une ancienne version ; invariants (Pokémon, équipe,
> stockage, Pokédex, Badges, objets, événements uniques, Ligue, Panthéon, post-game) ; ne pas inventer
> de sauvegardes de test.
> **Phase 5 — Automatisation** : partir de la CI existante ; contrôles de PR, tests unitaires et
> d'intégration, import et validation Godot, export Android de vérification, sécurité, archivage des
> rapports et empreintes, release autorisée ; jamais de secret de signature pour les contributions
> non approuvées.
> **Phase 6 — Documentation** : environnement, architecture, tests, export Android, sauvegardes,
> correctifs, diagnostic et incidents, retour arrière sûr ; structure adaptée aux dossiers réels.
> **Phase 7 — Backlog** : fondé sur les défauts et besoins documentés ; problème, justification,
> bénéfice, coût, dépendances, risques, critères ; aucune fonctionnalité implémentée.
>
> **Livrables** : 1. Audit J37 → J38. 2. Cartographie des dépendances. 3. Registre de dette technique.
> 4. Plan de refactorisation à faible risque. 5. Rapport de sécurité. 6. Matrice de compatibilité des
> sauvegardes. 7. Plan CI et archivage. 8. Documentation de reprise. 9. Procédures d'incident.
> 10. Backlog priorisé. 11. Lots 38.0 à 38F. 12. Checklist de sortie. 13. Prompts Codex par lots ;
> pour chaque lot : fichiers réellement concernés, prérequis, tests, risques, critères d'acceptation,
> retour arrière.
>
> Conception et audit uniquement. Ne rien coder avant validation ; n'affirmer aucun build, test,
> restauration ou audit de sécurité sans preuve observable.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 38.0

- **CI existante** : `.github/workflows/godot-tests.yml` lance déjà toute la suite GUT sur GitHub
  Actions, en **8 lots parallèles**, avec Godot 4.7.2 **vérifié par SHA-256**, des permissions
  minimales (`contents: read`) et l'archivage des journaux. Déclencheurs : pull requests et `push`
  sur `main`. Le pipeline du §6 part donc de là, pas de zéro.
- **Documentation** : le dépôt range déjà sa doc en `docs/design/` (conception) et `docs/tech/`
  (plans techniques, `etat-projet.md`), avec `CLAUDE.md` comme guide de reprise de fait. La structure
  du §7 est à fondre dans ces dossiers plutôt qu'à créer à côté.
- **Sauvegardes** : voir les notes du J33 (atomiques et versionnées depuis le jalon 5).
