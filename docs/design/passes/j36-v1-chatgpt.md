# Kanto 2026 — J36 : Consolidation de la bêta et version stable candidate

> Dossier de conception V1.0 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le lancement du
> J36** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages verrouillés.

Phase de convergence : exploiter les résultats de la bêta J35, corriger les défauts prioritaires,
préserver les sauvegardes et préparer une **version stable candidate**. Principe directeur :
stabiliser ce qui existe, démontrer sa fiabilité, éviter toute régression.

## 1. Les sept décisions définitives

| # | Domaine | Arbitrage verrouillé |
|---|---|---|
| 1 | Périmètre | Consolidation de la bêta et préparation d'une version stable candidate |
| 2 | Corrections | Résoudre tous les P0/P1 et sélectionner les P2 les plus impactants |
| 3 | Régression | Rejouer les parcours critiques et les scénarios ayant échoué pendant la bêta |
| 4 | Sauvegardes | Garantir la migration des sauvegardes bêta vers la version stable |
| 5 | Performances | Valider sur les appareils réellement utilisés en J35 |
| 6 | Documentation | Notes de version, limitations, installation et support |
| 7 | Sortie | Version stable candidate et Go/No-Go distinct de toute diffusion publique |

Ni nouvelle région, ni nouvelle espèce, ni nouvelle mécanique majeure.

## 2. Architecture du jalon

Rapport bêta J35 (retours réels, builds, anomalies) → triage (P0/P1 obligatoires, P2 choisis) →
corrections (patchs limités et revus) → migrations (sauvegardes bêta préservées) → régression
(scénarios critiques et incidents précédents) → performances (appareils J35) → **stable candidate**
(build figé, documentation, Go/No-Go).

Le rapport J35 est la **source de vérité** des défauts : ne jamais inventer de problèmes ou de
statistiques de bêta si les tests n'ont pas eu lieu.

## 3. Politique de correction

**Gel fonctionnel strict** : seules les modifications nécessaires à la fiabilité, à la compatibilité
et aux défauts retenus sont admises.

| Priorité | Politique J36 | Sortie autorisée ? |
|---|---|---|
| P0 — Critique | Correction et retest obligatoires | Non si ouvert |
| P1 — Majeur | Correction et retest obligatoires | Non si ouvert |
| P2 — Modéré | Sélection selon impact, fréquence et risque | Oui si résiduel accepté |
| P3 — Mineur | Documenter, reporter si nécessaire | Oui si documenté |

**Sélection des P2** : fréquence, impact sur la progression ou le confort, nombre d'appareils
touchés, facilité de reproduction, risque de régression. Un défaut visuel fréquent sur tous les
combats peut primer sur un défaut rare d'un menu secondaire ; un correctif très risqué à la veille du
gel s'évalue avec prudence.

**Contrat d'un correctif** : identifiant d'anomalie, scénario de reproduction, cause identifiée ou
hypothèse vérifiable, test de non-régression, référence du commit. Un bug est corrigé quand **le
scénario qui échouait a été rejoué avec succès sur la nouvelle build**, pas quand le code change.

## 4. Préservation des sauvegardes bêta

Un joueur qui a commencé pendant la bêta continue dans la version stable sans rien perdre.

| Élément | À conserver |
|---|---|
| Équipe Pokémon | Espèces, niveaux, capacités, PV, statuts et données individuelles |
| Stockage | Tous les Pokémon, leurs positions et leurs caractéristiques |
| Pokédex | Pokémon vus et capturés |
| Inventaire | Objets, quantités, CT et CS |
| Badges | Huit Badges et événements associés |
| Monde | Position valide, objets collectés, Dresseurs vaincus |
| Événements uniques | Fossiles, cadeaux, légendaires et échanges |
| Ligue | Victoire, progression permanente et Panthéon |
| Post-game | Accès Grotte Inconnue, état de Mewtwo |
| Préférences | Paramètres utilisateur compatibles |

**Stratégie** : sauvegarde bêta originale → copie de sécurité et vérification du schéma → migration
vers le schéma stable → validation des données et invariants → sauvegarde stable utilisable. En cas
d'échec : original intact et message compréhensible. Une sauvegarde partiellement migrée ne remplace
**jamais** la seule copie valide.

**Tests obligatoires** : sauvegarde bêta du début de l'aventure ; équipe et stockage remplis ;
plusieurs Badges ; après le Panthéon ; post-game avec Mewtwo capturé ; événements uniques consommés ;
interruption forcée pendant la migration ; échec de migration et récupération de l'original. Les
sauvegardes de test viennent de **vraies builds antérieures**, pas seulement de données synthétiques.

## 5. Régression

| Domaine | Scénarios |
|---|---|
| Début de partie | Nouvelle partie, starter, première sauvegarde |
| Exploration | Cartes, transitions, collisions, PNJ |
| Combat | Attaques, objets, statuts, captures et défaites |
| CS | Modèle hybride, Surf, Force et Coupe |
| Progression | Huit Arènes, rival et événements Rocket |
| Donjons | Îles Écume, Sylphe SARL, Route Victoire |
| Ligue | Cinq combats, Panthéon et reprise |
| Post-game | Grotte Inconnue et Mewtwo |
| Collection | Pokédex, évolutions locales et stockage |
| Rejouabilité | Ligue, Safari, pêche et revisites |

**Régression globale** (scénarios J33/J34 toujours valides) et **régression ciblée** (chaque incident
J35 rejoué avec les mêmes préconditions, le même appareil si possible, une version identifiée).
Variantes de starter prises en compte pour le rival.

## 6. Performances

Aucun nouvel objectif arbitraire sans les résultats J35 : comparer avant / après corrections.

| Indicateur | Comparaison attendue |
|---|---|
| FPS | Avant / après sur la même zone |
| Temps de chargement | Même appareil, même transition |
| Mémoire | Lancement et session longue |
| Batterie | Conditions comparables |
| Stabilité | Crashes et fermetures anormales |
| Température | Dégradation en session prolongée |
| Réactivité tactile | Latence perceptible et commandes perdues |
| Sauvegarde | Durée et fiabilité des écritures |

Résultats par modèle et version Android, sans fusionner des mesures incompatibles. Le S24 reste la
référence, sans dégrader silencieusement les appareils moins puissants de la bêta.

## 7. Documentation de la version stable candidate

Livrable obligatoire, au même titre que l'APK :

- **A. Notes de version** : corrections principales, stabilité, changements de sauvegarde,
  limitations connues.
- **B. Guide d'installation** : version Android minimale réellement prise en charge, méthode,
  conséquences d'une mise à jour, précautions de sauvegarde.
- **C. Guide de support** : comment signaler, quelle version mentionner, quelles informations
  techniques, sans données personnelles inutiles.
- **D. Registre des anomalies résiduelles** : chaque défaut non corrigé classé, documenté,
  explicitement accepté ou bloquant.

**Fiche de livraison (modèle)** : version (ex. `0.36.0-sc.1`, illustrative), commit, version de
Godot, signature APK, SHA-256, tests de migration, décision Go/No-Go : tous à renseigner sur un build
réel.

## 8. Dépendances J33–J35 → J36

| Dépendance | Origine | Condition J36 |
|---|---|---|
| Baseline fonctionnelle | J33 | Parcours critiques et mesures disponibles |
| Sauvegardes versionnées | J33 | Migration fiable |
| Export Android signé | J34 | Mise à jour compatible |
| Registre P0–P3 | J34/J35 | Historique des anomalies exploitable |
| Matrice multiappareil | J34 | Compatibilité documentée |
| Rapport bêta | J35 | Résultats observés, non supposés |
| Builds bêta identifiées | J35 | Comparaisons reproductibles |
| Retours de testeurs | J35 | Priorisation des P2 |
| Conformité | J34/J35 | Aucune diffusion présumée autorisée |
| Collection complète | J32 | Pas de régression de disponibilité |
| Ligue et post-game | J30/J31 | Sauvegardes et événements préservés |

Architecture cohérente avec J33–J35, sans nouvelle mécanique ; la vérification opérationnelle exige
les résultats réels du J35 (builds, rapport, tickets, sauvegardes représentatives).

## 9. Découpage technique

| Lot | Livrable |
|---|---|
| 36.0 | Audit des résultats J35, inventaire des builds et anomalies |
| 36A | Triage définitif et corrections P0/P1 |
| 36B | Sélection et traitement des P2 prioritaires |
| 36C | Migration et intégrité des sauvegardes bêta |
| 36D | Régression globale et ciblée |
| 36E | Performances, documentation et support |
| 36F | Build stable candidate, rapport QA et Go/No-Go |

**« J36 terminé »** : 1. tous les P0/P1 connus corrigés et retestés ; 2. P2 retenus traités, autres
documentés ; 3. sauvegardes bêta représentatives migrées sans perte ; 4. parcours critiques et anciens
scénarios en échec rejoués ; 5. performances vérifiées sur les appareils J35 ; 6. version stable
candidate signée, identifiée et documentée ; 7. Go/No-Go pris sur cette version exacte. Le Go du J36
autorise la poursuite de la validation, **pas une diffusion publique**.

## 10. Prompt de transmission à Claude (au lancement du J36)

> **Kanto 2026 — J36 : consolidation bêta et version stable candidate.**
>
> **Arbitrages verrouillés** (ne pas les rouvrir, aucun contenu majeur nouveau) : 1. Consolidation
> de la bêta et préparation d'une version stable candidate. 2. Correction obligatoire des P0/P1 et
> sélection des P2 les plus impactants. 3. Régression complète des parcours critiques et des
> scénarios en échec pendant la bêta. 4. Migration fiable des sauvegardes bêta. 5. Performances
> validées sur les appareils réellement testés en J35. 6. Notes de version, limitations, guide
> d'installation et support. 7. Version stable candidate et Go/No-Go distinct de toute diffusion
> publique.
>
> **Audit** : dépôt, branche active, projet Godot, builds Android, rapports QA, tickets, résultats
> réels du J35. Classer : implémenté et vérifié ; présent mais incomplet ; spécifié seulement ;
> absent ; non vérifiable. Si la bêta J35 n'a pas eu lieu, le dire et lister les prérequis manquants.
> N'inventer ni testeurs, ni résultats, ni bugs.
>
> **Corrections** : matrice P0–P3 (identifiant, version, appareil, reproduction, impact, cause,
> correctif, commit, retest) ; tous les P0/P1 ; P2 classés par impact, fréquence et risque ;
> modifications limitées et réversibles, sans nouveau gameplay.
> **Sauvegardes** : formats de toutes les builds bêta pertinentes ; migration sûre (copie de sécurité,
> version de schéma, migrations incrémentales, invariants, écriture atomique, reprise après
> interruption ; Pokémon, objets, Badges, Pokédex, événements, Panthéon) ; tests sur de vraies
> sauvegardes bêta.
> **Régression** : bout en bout du Bourg Palette à Mewtwo, scénarios en échec au J35, variantes de
> starter ; CS hybrides, événements uniques, combats, captures, évolutions locales, Ligue, stockage.
> **Performances** : mesures J35 contre résultats après corrections, mêmes appareils, conditions
> comparables ; aucune valeur fabriquée.
> **Documentation** : notes de version, installation et mise à jour, support, limitations, registre
> des anomalies résiduelles, manifeste du build (version, commit, Godot, signature, SHA-256).
>
> **Livrables** : 1. Audit factuel J35 → J36. 2. Matrice de corrections P0–P3. 3. Plan de migration.
> 4. Tests de régression. 5. Comparaison des performances. 6. Documentation utilisateur et technique.
> 7. Lots 36.0 à 36F. 8. Checklist de génération stable candidate. 9. Rapport QA. 10. Décision
> Go/No-Go. 11. Plan de transmission à Codex. DA 2D HD peinte, vue orthogonale, expérience tactile
> Android. Séparer faits observés, décisions verrouillées et recommandations nouvelles.
>
> Conception et audit uniquement. Ne rien coder avant validation ; ne pas prétendre avoir produit une
> version stable ou exécuté des tests sans preuve réelle.

---

## Note de la session de coordination (2026-10-19)

Le J36 n'a de matière qu'après une bêta J35 **réellement exécutée**, elle-même conditionnée au Go
juridique du J34. Sans bêta externe, le J36 peut s'appliquer à des « bêta-builds » internes (les
APK successifs installés sur le S24 de Kevin) : la migration des sauvegardes entre builds reste alors
pleinement utile, puisqu'elle protège la propre partie de Kevin.
