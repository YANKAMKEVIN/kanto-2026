# Jalon 36 — Consolidation de la bêta et version stable candidate

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j36-v1-chatgpt.md` (7 arbitrages verrouillés). Arbitrages et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> Objectif : **une version stable candidate** : tous les P0/P1 de la bêta corrigés et retestés, les
> sauvegardes bêta migrées sans perte, les parcours rejoués, la documentation prête, et un Go/No-Go
> pris sur cette version exacte. **Gel fonctionnel strict.** Le Go du J36 autorise la poursuite de la
> validation, **pas une diffusion publique**.
>
> Le **rapport bêta du J35 est la source de vérité** des défauts. Si la bêta n'a pas eu lieu, ce
> jalon ne peut pas être exécuté : on n'invente ni problèmes ni statistiques.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Rapport bêta, builds, tickets | N'existent pas (J35 non exécuté) | T3 à T7 attendent |
| Migrations | `SaveSystem.upgrade` : migrations incrémentales jusqu'à v7 ; tests `test_save_j11` … `test_save_j20`, `test_save_kevin_j12` (vraie sauvegarde de Kevin) | Modèle des tests de migration (T2) |
| Vraies sauvegardes | Une copie de Kevin à la racine de son dossier personnel (`kanto_save_kevin_backup_s2a_*.json`) | À copier dans `tests/fixtures/` **après relecture** (données personnelles : nom, temps de jeu) |
| Régression | Suite GUT, départs de débogage, parcours scriptés du J33 | Réutilisés |
| Mesures | `tools/measure_*.gd`, protocole du J33 | Comparaison avant/après |

### 0.1 Ce qui peut commencer tout de suite
- **T1** modèle du dossier de triage et du contrat de correctif ; **T2** harnais de migration avec
  les sauvegardes déjà disponibles ; **T6** gabarits de documentation (notes de version, guide
  d'installation, guide de support, registre résiduel) ; **T5** script de comparaison de mesures.

### 0.2 Ce qui attend
- Triage, corrections, retests, sélection des P2 : le rapport bêta. Fiche de livraison : un build réel.

## 1. Contrats

- **Politique** : P0/P1 corrigés et retestés (sinon pas de sortie) ; P2 choisis selon fréquence,
  impact, appareils touchés, facilité de reproduction, risque ; P3 documentés ou reportés.
- **Contrat d'un correctif** : identifiant d'anomalie, scénario de reproduction, cause identifiée ou
  hypothèse vérifiable, test de non-régression, référence de commit. **Un bug est corrigé quand le
  scénario qui échouait a été rejoué avec succès sur la nouvelle build**, pas quand le code change.
- **Migration** : sauvegarde bêta originale → copie de sécurité et vérification du schéma →
  migration → validation des invariants → sauvegarde stable utilisable. Échec : original intact et
  message clair. **Une sauvegarde partiellement migrée ne remplace jamais la seule copie valide.**
- **Mesures** : par modèle et version d'Android, sans mélanger des mesures incompatibles. Le S24 reste
  la référence, sans dégrader en silence les appareils plus faibles.

## 2. Tâches

### T1 — Audit 36.0 et triage (Sonnet)
Inventaire des builds bêta, des tickets, des préconditions. Chaque anomalie : ID, priorité, appareil,
build, scénario. Critère : tableau complet, aucune anomalie sans scénario.

### T2 — Harnais de migration (36C, Opus — sauvegarde : validé seul)
Générateur de sauvegardes « bêta » **à partir de vraies builds** et des fixtures disponibles :
début de l'aventure, équipe et stockage remplis, plusieurs Badges, après le Panthéon, post-game
avec Mewtwo capturé, événements uniques consommés. Tests : interruption forcée pendant la migration ;
échec de migration et récupération de l'original ; invariants (Pokémon, Pokédex, inventaire, Badges,
position valide, Panthéon).
Critère : toutes les fixtures passent ; une sauvegarde refusée reste byte à byte identique.

### T3 — Corrections P0/P1 (36A, Opus)
Un correctif = un commit, un test, un rejeu. Revue par une seconde lecture. Aucune « amélioration
au passage ».

### T4 — P2 prioritaires (36B)
Sélection documentée (critères du §1). Un correctif risqué après le gel se refuse ou se reporte.

### T5 — Régression globale et ciblée (36D)
Globale : parcours du J33 et du J34. Ciblée : chaque incident du J35 rejoué avec les mêmes
préconditions, le même appareil si possible. Variantes de starter prises en compte.

### T6 — Performances et documentation (36E)
Mesures avant/après sur les appareils du J35. Documents : **A** notes de version ; **B** guide
d'installation (version Android minimale réellement prise en charge) ; **C** guide de support ;
**D** registre des anomalies résiduelles.

### T7 — Build stable candidate et Go/No-Go (36F)
Fiche de livraison renseignée sur un build **réel** : version (exemple illustratif `0.36.0-sc.1`),
commit, Godot, signature, SHA-256, tests de migration, décision.

## 3. Textes
Validés par Kevin le 2026-10-21 : le plan des quatre documents (A à D) ; le contrat de correctif ;
la formule « Le Go du J36 n'est pas une diffusion publique ». Propositions **[D]** : modèle des notes
de version : « Corrigé : … ; Connu : … ; Sauvegardes : compatibles / migrées. »

## 4. Critères d'acceptation (« J36 terminé »)
1. Tous les P0/P1 connus corrigés **et** retestés ; 2. P2 retenus traités, autres documentés ;
3. sauvegardes bêta représentatives migrées sans perte ; 4. parcours critiques et scénarios en échec
rejoués ; 5. performances vérifiées sur les appareils du J35 ; 6. version stable candidate signée,
identifiée, documentée ; 7. Go/No-Go sur cette version exacte.

## 5. QA téléphone
Mise à jour par-dessus la dernière bêta avec une vraie sauvegarde ; reprise après coupure pendant la
migration (si reproductible) ; les parcours qui avaient échoué.

## 6. Risques
Correctif qui casse un contrat plus ancien ; migration partielle ; P2 acceptés sans critère ; bêta
trop petite pour représenter les appareils réels.

## 7. Points ouverts pour Kevin
1. Peut-on copier ta sauvegarde réelle dans `tests/fixtures/` (après retrait du superflu) ?
2. Qui tranche les P2 : toi, ou le critère du §1 appliqué par la session ? [D : critère, toi en cas de doute]
3. Date de gel : après combien de builds bêta ? [D : après la 3e]
