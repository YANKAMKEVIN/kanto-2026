# Jalon 38 — Pérennisation : robustesse, sécurité et reprise

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j38-v1-chatgpt.md` (7 décisions verrouillées). Décisions et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> Objectif : **un projet facile à maintenir, une chaîne de compilation sûre, et la garantie qu'une
> mise à jour ne détruira pas des mois de progression.** Principe : améliorer la robustesse **sans
> modifier l'expérience de jeu**. Pas de réécriture générale, pas de nouveau contenu.

## 0. État et dépendances (relu sur le dépôt)

| Domaine | Réel aujourd'hui | Manque |
|---|---|---|
| CI | `.github/workflows/godot-tests.yml` : GUT en 8 lots, Godot 4.7.2 vérifié par SHA-256, `contents: read`, journaux archivés ; déclencheurs : pull requests et `push` sur `main`, **jamais pour la documentation seule** | Export de vérification, contrôles statiques, secrets, empreintes |
| Contrôles statiques | `tools/check_json_keys.py`, `tools/check_test_timing.sh` (appelé par `tools/test.sh`) | Pas dans la CI |
| Quota CI | Dépôt privé ; minutes gratuites **épuisées en quelques heures** le 2026-10-19 (déclenchement sur `jalon-*` retiré) | Toute extension de la CI doit rester **économe** |
| Sécurité | Aucun keystore ni identifiant suivi ; plugin unique `addons/gut` | Inventaire de dépendances, scan de secrets |
| Documentation | `docs/design/`, `docs/tech/`, `CLAUDE.md` guide de reprise de fait | Structure du §7 à **fondre** dans l'existant |
| Sauvegarde | Atomique, versionnée, copie de secours ajoutée au J33 | Matrice de compatibilité 1.0.x |
| Dette | Non mesurée ; plusieurs `tools/build_*.gd` par carte, `pending_effects` | Audit ciblé (T1) |

### 0.1 Ce qui peut commencer tout de suite
- **T1** audit de la dette (lecture seule) ; **T2** inventaire des dépendances et des secrets ;
  **T4** documentation de reprise (fusionnée dans `docs/`) ; **T6** backlog priorisé (document).
- **T3** matrice de compatibilité des sauvegardes (sur les versions v1 à v7 déjà migrables).

### 0.2 Ce qui attend
- Compatibilité 1.0.x réelle : une 1.0 produite (J37). Pipeline de tag : version et signature (J34).

## 1. Contrats

- **Refactorisation admissible** seulement si elle répond à un problème identifié, conserve le
  comportement observable, a ses tests de non-régression et s'annule proprement. À éviter :
  remplacer en même temps combat, cartes et sauvegardes.
- **Secrets** : aucun mot de passe ni jeton dans le dépôt ; journaux sans valeurs sensibles ; un
  secret réellement exposé **n'est pas réglé en le retirant du dernier commit** (révocation ou
  rotation, exposition dans l'historique évaluée).
- **Provenance** : chaque APK relié à un commit, une configuration, une version d'outil, une
  signature, un SHA-256.
- **Sauvegardes** : une version plus récente est refusée proprement ; une procédure n'est validée
  qu'**exécutée réellement** sur des données représentatives.
- **Automatisation** : elle réduit les erreurs répétitives ; elle ne remplace ni l'œil sur les décors,
  ni la lisibilité, ni la précision tactile, ni les mesures sur appareil.

## 2. Tâches

### T1 — Audit de dette et refactorisations ciblées (38A, Sonnet puis Opus)
Parcours des domaines du dossier (scènes, scripts, données, cartes, combat, sauvegardes, Android,
tests). Chaque point : problème, risque, coût, décision. Seules les refactorisations du contrat §1
passent, **une à la fois**, avec un test.

### T2 — Sécurité de la chaîne (38B, Sonnet)
Inventaire : Godot (version exacte), plugin GUT, bibliothèques Android de l'export, licences.
Scan de secrets sur l'arbre et l'historique (outil à choisir [D] ; résultat sans valeur sensible
dans le rapport). Permissions Android (`export_presets.cfg` : vibrate) revues. CI : permissions
minimales conservées ; aucun secret aux pull requests non approuvées.

### T3 — Compatibilité et récupération des sauvegardes (38C, Opus — validé seul)
Matrice du dossier : 1.0.0 → 1.0.1, 1.0.0 → 1.0.2, 1.0.1 → 1.0.2, 1.0.2 → 1.0.1 (refus sûr),
interrompue, corrompue. Tests de récupération : écriture interrompue puis redémarrage, sauvegarde
incomplète, ancien schéma, schéma plus récent, copies de secours, **stockage presque plein**.
Critère : chaque ligne exécutée, résultat noté.

### T4 — Pipeline automatisé (38D, Opus)
Étapes : pull request → statique (`check_json_keys.py`, `check_test_timing.sh`, import du projet) →
tests (existants) → export non signé de vérification → contrôles de sécurité → archivage (rapports,
empreintes). Tag : build identifié et archivage. **Économie de minutes** : l'export et les contrôles
étendus se lancent sur `main` et sur tag, pas sur chaque branche ; documentation seule : rien.

### T5 — Documentation de reprise (38E, Sonnet)
Dans `docs/tech/` et `docs/design/` existants (pas d'arborescence parallèle) : guide de reprise
(lancer le projet, où sont les systèmes, ajouter un test, construire une APK, reproduire un bug,
migrer une sauvegarde, préparer un correctif) ; **trois procédures d'incident** (sauvegarde
corrompue ; build compromis ou secret exposé ; régression critique après mise à jour : ne pas
recommander une rétrogradation qui rendrait les sauvegardes illisibles).

### T6 — Backlog et rapport de sortie (38F)
Catégories : fiabilité, ergonomie, technique, contenu (hors périmètre). Ordre de décision : P1
fiabilité et données ; P2 compatibilité et performances ; P3 ergonomie étayée par les retours ;
P4 nouvelles fonctionnalités, après arbitrage. Une idée au backlog ne vaut pas validation.

## 3. Textes
Validés par Kevin le 2026-10-21 : les trois procédures d'incident ; l'ordre de décision P1–P4 du
backlog ; la liste des sujets du guide de reprise. Texte manquant : aucun (documents techniques).

## 4. Critères d'acceptation (« J38 terminé »)
Risques principaux identifiés ; refactorisations retenues couvertes par des tests ; contrôles de
sécurité et pipeline exécutables ; scénarios de récupération **exécutés** ; documentation permettant
la reprise par une session neuve ; backlog priorisé ; **aucune évolution fonctionnelle**.

## 5. QA téléphone
Peu de QA téléphone : une mise à jour réelle d'APK avec sauvegarde (reprise des tests J37) et la
vérification que le comportement observable n'a pas changé après les refactorisations.

## 6. Risques
Refactorisation qui change un comportement ; CI qui épuise de nouveau le quota ; scan de secrets
qui affiche une valeur ; documentation dupliquée dans deux arborescences.

## 7. Points ouverts pour Kevin
1. Budget de CI : limiter l'export aux tags et à `main` ? [D : oui]
2. Un historique Git contenant d'anciens secrets est-il connu ? (le scan le dira)
3. Faut-il un second dépôt privé pour l'archive des releases ? [D : non, release GitHub privée]
