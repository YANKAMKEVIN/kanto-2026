# Jalon 22 — Les deux chemins vers Parmanie (Routes 12 sud à 18, Parmanie, Vélo, pêche)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/dossier-25-deux-chemins-parmanie.md` (7 décisions, arbitrages M-1 à M-24 et textes
> du §16 **validés par Kevin** le 2026-10-16). Passe : `docs/design/passes/j22-v2-alignement.md`.

> Objectif jouable sur le téléphone : **deux chemins indépendants mènent à Parmanie.** À l'est,
> après le Ronflex du croisement, le **chemin des pêcheurs** : Route 12 sud, Routes 13, 14, 15, avec
> trois cannes et la pêche. À l'ouest, après le Ronflex de la Route 16, la **Piste Cyclable** :
> Bon de Commande (Carmin), Bicyclette (Azuria), poste de la Route 16, Route 17 en pente, Route 18.
> **Parmanie** ouvre ses intérieurs principaux ; Safari, Koga et le Gardien attendent le J23.
>
> Mécaniques nouvelles :
> - le **mode vélo** (vitesse, lieux, compagnon rentré, bouton rond du HUD) ;
> - la **pente** de la Piste (dérive vers le bas sans appui, paliers, arrêt devant un Dresseur) ;
> - la **pêche** (cases pêchables, trois cannes, terrain de rencontre `water_rod`) ;
> - un garde qui **lit un objet du Sac** (poste de la Piste).
>
> Le reste (7 routes, 3 postes, 2 maisons, Parmanie, 40 Dresseurs, 13 espèces) est du contenu
> posé sur des systèmes existants. **Format de sauvegarde inchangé : v7** (§2.13).

> **Stratégie d'accélération (Kevin, 2026-10-19, `docs/design/strategie-acceleration.md` sur `main`
> `384f53b1`) : elle prévaut sur le découpage ci-dessous.**
> - **Le Vélo et la Piste Cyclable sortent du J22** : ils passent dans la passe « systèmes 2 ».
>   T14 à T20 et T23 (22B) ne sont pas codés ici. La logique pure déjà écrite (`BikeRules`,
>   `CyclingSlope`, T2) et le §2.1–2.2 sont remis à cette passe comme point de départ.
> - **La pêche** est un système prévu dans un jalon de contenu : d'après la stratégie (« tout système
>   encore prévu dans un jalon de contenu »), elle rejoint aussi la passe systèmes 2 (`FishingRules`,
>   `FishingSpot`, T3). **À confirmer par Kevin.**
> - Le J22 **ne termine que sa partie indépendante** (22.0, fait hors T10) et **n'ouvre aucune tâche
>   de code** qui dépend d'un autre jalon. T10 et la suite attendent la fin de la passe systèmes 2 ;
>   le J22 devient alors un jalon de contenu (cartes et données).
> - Art : grille et vue générale avant le code (déjà faites et validées) ; le reste par lots ; le code
>   ne bloque jamais sur l'art.

> **État au 2026-10-21 (session de nuit, branche `jalon-22`) : le J22 est codé en contenu sur les
> systèmes de la passe systèmes 2.** `origin/systemes-2` (main J20 + passe complète) fusionnée ;
> la passe est propriétaire du Vélo, de la Piste, de la pente, de la pêche et de `key_use` : le
> J22 ne les recode pas, il pose cartes et données. Voir §0.5 (alignement T10) et §8 (QA).

**Pré-requis.** Dossier 25 validé. Grilles du J22 **à produire** (T6) et à faire valider par Kevin.
Grille de la Route 12 du J21 (`origin/jalon-21` à `925ec9f3`, M-3 appliqué) : le J22 part du bord
`warp_sud` (25..26, 101).

**Code lu** (lecture seule, 2026-10-16) : `origin/main` à `2bd6bbf7` (J14) ; `origin/jalon-21` à
`925ec9f3` (contient `main` + J15 + le début du J21) ; `jalon-16` à `a4bda303` (Coupe) ;
`jalon-17` à `61fa5178` (Route 11) ; `jalon-18` à `505f0f57` ; `jalon-19` à `3888cacc` ;
`jalon-20` à `d26789bd` (dalles tournantes partielles). Quand un nom n'existe que dans un plan, il
est suivi de « (plan) ». **La tâche d'alignement (T10) réaligne ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), skills `godot-conventions`, `world-tiles`,
`ui-theme-2026` ; modèles de forme `jalon-21.md`, `jalon-17.md` ; `jalon-20.md` (dalles
tournantes, compagnon rentré) ; `jalon-16.md` (`field_move`, Coupe) ; `jalon-12.md` §2.5 (terrain
`rubble`).

---

## 0. État et dépendances

### 0.1 Règle C-8 : le code des cartes et du moteur commence après la clôture du J21

- Un seul jalon à la fois dans le moteur, les directeurs, `boot.gd` et les cartes des autres
  jalons (règle C-7 du J21, prolongée). **M-2** : les cartes du J22 attendent une branche qui
  réunit J15 → J21.
- **Les tâches qui touchent `game/player/`, `game/world/grid_mover.gd`, `boot.gd`, les directeurs,
  `item_data.gd`, l'exploration HUD, ou une carte d'un autre jalon commencent après la clôture du
  J21** (`origin/main` contient alors J15 à J21) : c'est **T10**.
- **Règle d'ancienneté** (Kevin, relayée le 2026-10-16) : le J22 ne modifie pas ce qu'une session
  plus ancienne (J15, J17 à J21) est en train de modifier (fichiers, systèmes, données, moteur) ; il
  attend et demande à Kevin, ou travaille ailleurs. Même priorité pour les numéros (série d'art 25,
  la 24 étant au J19). **Avant chaque tâche qui touche un système partagé**, vérifier les branches des
  sessions plus anciennes (`git log origin/jalon-1[5-9] origin/jalon-2[01]` sur les fichiers visés).
- **Avant**, seulement : documents, **logique pure dans des fichiers nouveaux**, données dans des
  fichiers nouveaux, grilles, vues peintes, art, contrôles de grilles (§1.2).

### 0.2 Contrat d'entrée (dossier §3) relu sur le code réel

| Le J22 suppose | Jalon | État réel (2026-10-16) | Ce que fait le J22 |
|---|---|---|---|
| Fan Club de Carmin, président | J15 | Codé (`data/npcs/vermilion_fan_club.json`, dialogue `vermilion_city.json` l. 54-70 : il parle de son Ponyta) ; **aucun** `got_bike_voucher` | Variante de dialogue + choix OUI / NON + scène de remise (T17) |
| Maison du pêcheur de Carmin | J15 | Codé (`vermilion_fisher_house.tscn`, `data/npcs/vermilion_fisher_house.json`, dialogue `vermilion_city.json` l. 72-77 « Un jour, je t'apprendrai. ») ; **aucun** `got_old_rod` | Variante + scène de remise de la Canne (T13) |
| Boutique de Vélos d'Azuria | J13 | Codé, décor (`cerulean_bike_shop.json`, `cerulean_bike_clerk` dans `cerulean_city.json` l. 98) | Variante `if_items [bike_voucher]` + scène d'échange (T17) |
| Coupe | J16 | Codé sur `jalon-16` : `data/world/field_moves.json` (`cut` : `hm01`, `badge_cascade`), `game/world/field/field_moves.gd`, buisson `InteractPoint` `dialogue_id=cut_tree`, scène `cut_tree.json` | Arbre de la Route 16 en buisson coupable (T19) |
| Ronflex au croisement, Route 12 nord | J21 | Grille `route_12.txt` à `925ec9f3` (Ronflex `ronflex_12` (25..26, 93..94), `unless snorlax_route_12_done`, `warp_sud` (25..26, 101) `coming_soon=route_12_sud`, `from_route_12_sud` (25..26, 100)) ; **scène pas encore construite** (T20–T21 du J21) | Retire le `coming_soon` du bord sud (T12) |
| Route 16 est, façade du poste, voie haute, arbre | J21 | Grille `route_16.txt` (44 × 28) : porte `coming_soon=route_16_poste` (15..16, 20), voie haute (26..42, 9..16), arbre (38..39, 19..20) en **décor** ; scène pas construite | Ouvre la porte, rend l'arbre coupable, prolonge la carte à l'ouest (T19) |
| Objet clé utilisable `key_use` | J21 | Plan `jalon-21.md` §2.1 (T17 du J21) : `key_use`, `KEY_USES`, `has_key_use()` ; **pas codé** | Ajoute `bicycle` et `fishing_rod` à `KEY_USES` (T11) |
| Drapeaux Ronflex `snorlax_route_12_*`, `snorlax_route_16_*` | J21 | Plan | Lus, jamais posés |
| Compagnon rentré pendant un mouvement forcé | J20 | `jalon-20.md` §2 (dalles tournantes, `SpinTileDirector` (plan)) ; `companion.gd` l. 223 `appear`, l. 234 `withdraw` | Même API pour le vélo et la pêche (T14, T16) |
| Mouvement forcé | J20 | `game/world/spin/spin_tile_rules.gd`, `spin_slide.gd` (`jalon-20`) ; directeur (plan) | La pente réutilise l'idée, pas le code : elle ne verrouille pas l'entrée (§2.3) |
| Sauvegarde v7 | J15 | `save_system.gd` l. 36 `VERSION = 7` | Inchangée (§2.13) |

### 0.3 Points d'accroche dans le code (`origin/jalon-21` à `925ec9f3`)

| Pièce | Fichier et ligne | Ce que le J22 y fait |
|---|---|---|
| Durées de pas | `game/world/grid.gd` l. 16 (`WALK_STEP_DURATION` 0,27), l. 18 (`RUN` 0,16), l. 20 (saut 0,40) | `BIKE_STEP_DURATION` 0,12 [D] (T14) |
| Déplacement | `game/world/grid_mover.gd` l. 25 (`step_started(from, to, running)`), l. 31-34 (durées surchargeables), l. 84 (`update(delta, direction, run)`), l. 152 (`start_step`) | Mode `bike` : durée du vélo, la course ignorée (T14) |
| Joueur | `game/player/player.gd` l. 16 (`step_started(…, kind)` : `walk`, `run`, `jump`), l. 45-49 (`_ANIMS` : idle, walk, run), l. 100 (`_mover.update(…, Input.is_action_pressed(&"run"))`), l. 107 (`enter_map`), l. 193 (`script_step`) | `kind = &"bike"`, animations `bike_*`, `set_riding()`, entrée de la pente (T14, T16) |
| Compagnon | `game/world/companion/companion.gd` l. 223 (`appear`), l. 234 (`withdraw`), l. 178 (`move`) | Rentré en selle et pendant la pêche (T14, T13) |
| HUD d'exploration | `game/ui/hud/exploration_hud.gd` l. 46-48 (`RunButton`, `InteractButton`, `MenuButton`), l. 150 (`set_controls_visible`) ; `round_button_visual.gd` | Bouton rond `BikeButton` (T15) |
| Interaction | `game/world/interactions/interaction_controller.gd` l. 141 (`_can_target`), l. 149 (`_interact`), l. 177 (`_set_target`) | Cible « eau pêchable » devant le joueur (T13) |
| Rencontres | `encounter_table.gd` l. 26 (`TERRAINS = [grass, rubble]`) ; `encounter_library.gd` (clé (carte, terrain)) ; `encounter_director.gd` l. 100 (`terrain_at`), l. 113 (`start_encounter`) | Terrain `water_rod` tiré **hors pas**, par la pêche (T12) |
| Grille | `game/world/grid_world.gd` l. 15 (`_FLAG_WATER`), l. 76-81 (`set_water`, `is_water`), l. 87-101 (herbes, gravats) | Drapeau `_FLAG_FISHABLE` (T12) |
| Carte | `game/world/map.gd` l. 48 (`@export var interior`) | `@export var cycling_road` (tronçon de Piste), `slope` (pente) (T16) |
| « À venir » | `game/autoload/scene_router.gd` l. 36-42 (`coming_soon_enabled` en debug) ; `Warp.coming_soon` | Portes réservées au J23 (T22) |
| Postes | `data/cutscenes/route_5.json` `route_5_gate_rule` (face, dialogue, recul) ; `tools/build_painted_interiors.gd` `_gate_room()` | Garde de la Piste sur ce modèle, plus une condition d'objet (T18) |
| Objets du Sac en exploration | `field_item_rules.gd` (`check`, `is_targetless`) ; `boot.gd` l. 1632 (`_on_field_item_requested`) ; `key_use` (plan J21) | Bicyclette et cannes (T11) |
| Stabilité | `boot.gd` l. 695 (`is_stable` : aucune écriture pendant une scène, un dialogue, un combat) | Pas d'écriture pendant la pêche ; la dérive n'empêche pas d'écrire (§2.13) |
| Dresseurs | `data/trainers/<carte>.json` (`trainer_data.gd`), `data/npcs/<carte>.json` (`trainer` : `id`, `sight` 1–8, `before`, `defeated`) ; `trainer_rules.gd` (`beaten_<id>`, `lost_<id>`) | 40 Dresseurs, 4 classes (T8, T12, T19) |
| Fonds de combat | `data/battle/decors.json` (`decors`, `places[<carte>]`) ; `tools/art/combat_decors/` | 4 fonds (T7) |
| Art de combat | `game/battle/battle_art.gd` (face `official/NNN.png`, dos `placeholder/<id>_back.png`) ; `tests/unit/test_battle_art.gd` l. 37 (face et dos pour chaque espèce) | 12 dos (T7) |

### 0.4 Écarts et trous du dossier

1. **Interaction avec l'eau.** Aujourd'hui, l'interaction ne vise que des entités (PNJ, points
   d'interaction). Une case d'eau n'en est pas une. Le J22 ajoute une **cible de terrain**
   (`FishingSpot`, pure) que l'`InteractionController` propose quand aucune entité n'est devant
   le joueur et que la case de devant est pêchable **et** qu'une canne est dans le Sac. Le verbe
   du bouton d'interaction devient « Pêcher » [D].
2. **Cases pêchables des cartes déjà livrées** (M-8). Six cartes (Carmin, Azuria, Routes 6, 11, 24,
   25) appartiennent à d'autres jalons. On ne réécrit pas leurs grilles : un fichier de données
   `data/world/fishable.json` liste, par carte, des **rectangles** de cases pêchables [D] ; les
   cartes nouvelles les marquent dans leur grille (caractère dédié, T6). `GameMap` applique les
   deux au chargement.
3. **Vélo dans une grotte** : le dossier dit « extérieurs et grottes ». Aucune grotte n'est sur le
   chemin du J22 ; la règle vaut pour les grottes existantes (Mont Sélénite, Cave Taupiqueur,
   Grotte Sombre) : `interior == false`. Si une grotte est marquée `interior`, le vélo y est
   interdit [D] ; T10 vérifie le marquage.
4. **Animation de pêche** : une pose « lancer » et une pose « attente » par direction (dossier §15).
   Sans planche à T13, repli sur l'animation `idle` + bulle « … » [D].
5. **Musique du vélo** : aucun son dans le projet. Rien à coder ; noté pour le jalon audio.
6. **Postes 16 et 18 traversants** : le poste de la Route 16 a **deux voies** (basse, haute).
   Modèle : la pièce `_gate_room()` (10 × 8) est trop petite ; enveloppe 14 × 10 à deux couloirs
   [D], définie par une grille `tools/plans/route_16_gate.txt` (T6).
7. **Ronflex de la Route 16** : la carte de la Route 16 du J21 (44 × 28) est **prolongée à
   l'ouest** par une carte séparée `route_16_west` [D], raccordée par la porte basse et la porte
   haute du poste, plutôt que d'agrandir la carte du J21 (fichier chaud d'un autre jalon).
8. **Hyper Potion et Hyper Ball** : objets de données pures (`heal` 200, `ball_bonus` 2.0), sur
   les modèles de Super Potion et Super Ball (`items.json`, `items_j20.json`).
9. **CT20** : T10 vérifie si Frénésie (`rage`) tient dans le moteur (capacité verrouillée, Attaque
   +1 quand on est touché). Sinon **CT20 → CT existante non encore distribuée** [D], choisie avec
   Kevin dans le rapport de T10.
10. **Total Soin** à la Boutique de Parmanie : `full_heal` existe-t-il ? T10 vérifie ; sinon
    Antidote (dossier §10.2).
11. **Krabby** : évolution vers Krabboss coupée (dossier §19) : `evolutions: []` [D] jusqu'à la
    création de Krabboss.
12. **Pente et Dresseurs** : la vue des Dresseurs est vérifiée à chaque fin de pas
    (`trainer_rules.gd`). La dérive interroge la même vérification **avant** de lancer le pas
    suivant (§2.3).

### 0.5 Alignement (T10, 2026-10-21) sur `origin/systemes-2` (main J20 + passe systèmes 2)

Fusion de `origin/systemes-2` dans `jalon-22` (`5ee69e45`). Réponses aux points du T10 :

| Point | État réel | Décision |
|---|---|---|
| `key_use` | Livré par la passe (S2B T10) : `bicycle`, `old_rod`, `good_rod`, `super_rod` dans `items_systemes2.json` | Doublons du J22 retirés (`items_j22.json` ne garde que Bon, Hyper Potion, Hyper Ball, CT09). T11 **fait par la passe**. |
| Mode Vélo, bouton HUD, Piste, pente | Livrés (`Mount`, `MountRules`, `MountDirector`, `BikeButton`, `GameMap.cycling_road`, `slope_cells`) | T14, T15, T16 **faits par la passe**. Écart [D] du J22 : `GameMap.cycling_road_cells` (Piste sur une partie de carte : Route 16 ouest voie basse, Route 18 ouest) ; `MountDirector` et `FishingDirector` lisent la case du joueur. |
| Pêche | Livrée (S2C-bis : `FishingDirector`, PÊCHER, tables `data/fishing/water_rod.json`) | T13 (système) **fait par la passe** ; le J22 branche `data/world/fishable.json` dans `GameMap.fishable_set` (cartes livrées) et marque ses cartes (« f »). |
| `if_items`, étape de retrait | `if_items` / `unless_items` sur les dialogues (J20) ; étape `take` (J20) | Échange du Bon : variante `if_items [bike_voucher]` + scène avec `take`. Les scènes n'ont pas de condition d'objet : les gardes de la Piste lisent `got_bicycle` (posé seulement par l'échange). |
| `full_heal` (Total Soin) | Absent | Antidote à la Boutique de Parmanie (dossier §10.2). |
| CT20 Frénésie | `rage` en `pending_effects` (aucun effet) | **CT09 Bélier** à sa place [D] (Bélier existe, recul codé, jamais distribuée) ; texte §16.8.12. À confirmer par Kevin. |
| Grottes `interior` | Mont Sélénite, Cave Taupiqueur, Grotte Sombre : extérieures | Vélo permis (MapTraits). |
| Routes 12 et 16 du J21 | Pas encore construites (`origin/jalon-21` à `3fbca1ff` : grilles seulement) | Passages vers elles « À venir » ; contrat ci-dessous. |
| Ptitard, Tentacool | Au J21 seulement (`kanto_j21.json`, Amnésie et Bouclier dans `moves/j21.json`) | **Copie à l'identique** (`species/kanto_j22_j21.json`, `moves/j22_j21.json`, Pokédex) ; **à retirer à la fusion du J21** (doublons d'identifiants). Dos provisoires repris du J24 (mêmes fichiers). |
| Léviator, Saquedeneu, Kangourex | Présents (J19, J20) | Magicarpe → Léviator au N20. |
| Planches série 25 (vélo, pêche, PNJ, Kangourex, Ramoloss) | Images brutes hors dépôt ; rien d'intégré | Sprites existants en remplacement [D] (Pêcheur → `haru`, Motard → `rocker`, Ornithologue → `naturalist`, Loubard → `docker`) ; Kangourex et Ramoloss : examen seulement (pas de planche). |
| Fonds de combat CB.3 du J22 | Non intégrés | Fonds existants [D] : Route 12 sud → `route_11_coast` ; 13–15, Parmanie → `route_5_6_prairie` ; 16–18 → `route_7_8_urbaine`. |
| Maison de Vol (Q-9 de la passe) | « Le J22, en données » | Maison `route_16_fly_house` et CS02 posées (textes §16.8.13 à 15). |

**Contrat avec le J21 (Route 12 nord, Route 16 est)** — rien n'est modifié dans ses cartes :
- `route_12` : le bord `warp_sud` (25..26, 101) doit mener à `route_12_south` / `from_route_12`
  (case 25) et `from_route_12_1` (case 26) ; la Route 12 sud revient sur `route_12` /
  `from_route_12_sud` (puis `_1`).
- `route_16` : porte basse (15..16, 20) → `route_16_gate` / `entrance_bas_est` (+ `_1`), arrivée
  `from_poste` ; porte haute (19..20, 13) → `entrance_haut_est` (+ `_1`), arrivée `from_poste_haut`
  (cases notées en tête de `route_16_gate.txt`) ; arbre (38..39, 19..20) coupable
  (`cut_route_16_tree`), bloc « J22 » de `build_route_16.gd` (T19) : **à faire à la fusion du J21**.
- Après la fusion : relancer `tools/build_j22_maps.gd` (les « À venir » deviennent des passages).

---

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §18, M-24)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **22.0** | Grilles et contrôle ; vues peintes ; données en fichiers nouveaux (13 espèces, capacités, objets, 40 Dresseurs, rencontres, tables d'eau) ; logique pure (`BikeRules`, `CyclingSlope`, `FishingRules`, `FishingSpot`) ; art (planches vélo et pêche, 4 classes, 12 dos, 4 fonds CB.3, enclos, bouton HUD) ; alignement après le J21 (T10) | Kevin valide grilles, vues et art. **Aucune session téléphone.** |
| **22A** « le chemin des pêcheurs » | Pêche (interaction, tirage, scène) ; Canne (Carmin), Méga Canne (Route 12 sud) ; cases pêchables des cartes livrées ; Route 12 sud, Routes 13, 14, 15 et poste | **Téléphone** (S24 ou S21) |
| **22B** « la Piste » | Mode vélo et bouton HUD ; Bon de Commande, Bicyclette ; poste 16, Route 16 ouest (voies basse et haute, arbre), Route 17 et sa pente, Route 18 et son poste | **Téléphone** |
| **22C** « Parmanie » | Ville, Centre, Boutique, maison de la Super Canne, Salle de réunion, maison du grand-père, enclos, portes réservées ; raccords des deux chemins ; QA de bout en bout ; équilibrage ; clôture | **Téléphone** + fusion |

Règle des trois systèmes :
- **22A** porte **un** système : la pêche.
- **22B** porte **un** système, le vélo, et sa règle de lieu (la pente), qui n'existe que sur un vélo.
- **22C** n'en porte aucun : contenu et QA.
- **Aucune validation isolée de sauvegarde** : rien ne touche sa forme (§2.13).

22A et 22B sont **indépendants** : l'ordre peut s'inverser selon les livraisons d'art.

### 1.2 « Peut commencer maintenant » ou « après la clôture du J21 »

| Tâche | Quand | Pourquoi |
|---|---|---|
| T1 branche `jalon-22` | **maintenant** | Depuis `origin/jalon-21` (contient J15) + `docs/dossier-25-j22` |
| T2 logique pure du vélo et de la pente | **maintenant** | Fichiers nouveaux, sans scène |
| T3 logique pure de la pêche | **maintenant** | Fichiers nouveaux ; `EncounterTable` lu, pas modifié |
| T4 données valides sur `jalon-21` | **maintenant** | Espèces, capacités, objets (sans `key_use`), tables d'eau en fichiers nouveaux |
| T5 Dresseurs et rencontres | **rédigés maintenant**, validés après T10 | Espèces des J19–J21 (Léviator, Ptitard, Tentacool, Saquedeneu) |
| T6 grilles et contrôle | **maintenant** | Kevin valide d'abord |
| T7 art (kit, génération, intégration) | **maintenant**, après T6 pour les vues | Images, entrées **en fin** de manifeste |
| T8 classes de Dresseurs (planches PNJ) | **maintenant** | Art |
| T9 vues peintes | après validation des grilles | |
| T10 alignement | **après la clôture du J21** | Fusion de `main` (J15 à J21) |
| T11 à T27 | **après T10** | Joueur, moteur, `boot.gd`, HUD, cartes des autres jalons |

### 1.3 Branches et fichiers chauds

- Intégration sur **`jalon-22`**, dans une copie dédiée ; une branche par tâche
  (`j22-t<n>-<sujet>`) ; rien dans `main` avant la clôture (T27).
- **Fichiers nouveaux de préférence** :
  - logique : `game/world/bike/bike_rules.gd`, `cycling_slope.gd`, `game/world/fishing/fishing_rules.gd`, `fishing_spot.gd`, `fishing_director.gd` ;
  - données : `species/kanto_j22.json`, `moves/j22.json`, `items/items_j22.json`,
    `encounters/water_rod.json`, `encounters/route_12_sud.json` … `route_18.json`,
    `trainers/route_12_sud.json` … `route_18.json`, `npcs/*.json`, `dialogues/j22_*.json`,
    `cutscenes/j22_*.json`, `data/world/fishable.json` ;
  - cartes : `tools/build_route_12_sud.gd`, `build_route_13.gd` … `build_route_18.gd`,
    `build_route_16_west.gd`, `build_fuchsia_city.gd` ; grilles `tools/plans/*.txt` ;
    contrôle `tools/art/plan_check_j22.py`.
- **Fichiers uniques, ajouts en fin** : `data/pokedex/kanto.json`, `zones.json`,
  `data/battle/decors.json`, `messages.json`, `tools/art/manifeste.json`,
  `build_character_frames.gd`, `tm_compatibility.json`.
- **Fichiers chauds (après T10 seulement), ajouts courts en bloc « J22 »** :
  - `grid.gd`, `grid_mover.gd`, `grid_world.gd`, `map.gd`, `player.gd`, `companion.gd`,
    `companion_trail.gd` ;
  - `encounter_table.gd`, `encounter_library.gd`, `encounter_director.gd` ;
  - `item_data.gd`, `item_library.gd`, `field_item_rules.gd`, `menu_director.gd`, `boot.gd`,
    `debug_start.gd` ;
  - `exploration_hud.gd` / `.tscn`, `interaction_controller.gd` ;
  - cartes des autres jalons : `build_route_12.gd` et `build_route_16.gd` (J21),
    `vermilion_*` (J15), `cerulean_*` (J13), `build_painted_interiors.gd` ;
  - données des autres jalons : `vermilion_city.json`, `cerulean_city.json`, `data/npcs/vermilion_*`.

---

## 2. Conception technique

### 2.1 Vélo : règles pures (T2)

```gdscript
# game/world/bike/bike_rules.gd — pur, statique
class_name BikeRules
enum Check { OK, NO_BIKE, INDOORS, ON_CYCLING_ROAD, BUSY }
## Peut-on monter ? Bicyclette dans le Sac, carte extérieure, joueur libre.
static func can_mount(has_bike: bool, map_interior: bool, busy: bool) -> Check
## Peut-on descendre ? Jamais sur un tronçon de Piste.
static func can_dismount(on_cycling_road: bool, busy: bool) -> Check
## Durée d'un pas selon le mode : vélo > course > marche (la course est ignorée à vélo).
static func step_duration(riding: bool, run: bool) -> float
## À l'arrivée sur une carte : faut-il descendre (intérieur), monter d'office (Piste) ou rien ?
static func on_map_entered(riding: bool, map_interior: bool, cycling_road: bool, has_bike: bool) -> StringName  # &"dismount", &"mount", &""
```

- Constantes : `Grid.BIKE_STEP_DURATION = 0.12` [D] (T14 l'ajoute à `grid.gd` ; T2 garde une
  copie locale le temps que `grid.gd` soit libre, puis la retire).
- Messages : `INDOORS` → dossier §16.1.3 ; `ON_CYCLING_ROAD` → §16.1.4.

### 2.2 Vélo : mode du joueur (T14)

- `Player.set_riding(riding: bool, instant: bool = false)` : change le jeu d'animations
  (`_ANIMS` gagne une 4e colonne `bike_*` [D : `idle` = arrêt en selle]), la durée du mouvement
  (`_mover.walk_duration = Grid.BIKE_STEP_DURATION`, `run_duration` idem), et émet
  `riding_changed(riding)`.
- `step_started(…, kind)` : `kind = &"bike"` en selle (le compagnon est rentré : aucun relais).
- Le drapeau `riding_bicycle` est la **source de vérité** sauvegardée (`StoryFlags`) ; le joueur
  le lit à `enter_map` et applique `BikeRules.on_map_entered`.
- **Compagnon** : `Boot` écoute `riding_changed` : `true` → `companion.withdraw()` (sans
  cinématique) ; `false` → `appear()` derrière le joueur (règle d'arrivée existante).
- Rebords : inchangés (saut à la durée de saut).
- Après un combat : on reste en selle ; après une défaite (retour au Centre, intérieur) : à pied.

### 2.3 Piste Cyclable et pente (T2, T16)

```gdscript
# game/world/bike/cycling_slope.gd — pur
class_name CyclingSlope
## Doit-on dériver d'une case vers le bas ? Seulement sans direction tenue, sur une case de pente
## (pas un palier), joueur libre (ni dialogue, ni combat, ni scène, ni Dresseur qui le voit).
static func should_drift(input_dir: Vector2i, on_slope_cell: bool, player_free: bool, seen_by_trainer: bool) -> bool
```

- **Données de carte** : `GameMap.cycling_road: bool` (tronçon de Piste : Route 16 ouest voie
  basse, Route 17, Route 18 ouest) ; cases de **pente** marquées dans la grille de la Route 17
  (caractère dédié, T6) ; les **paliers** sont des cases sans marque.
- **Moteur** : `Player._process` : si la direction lue est nulle et `should_drift(…)` → `_mover.update(delta, Vector2i.DOWN, false)` (même chemin qu'un appui : collisions, rebords et
  vue des Dresseurs restent ceux du jeu). Aucun verrou d'entrée : gauche, droite et haut restent
  libres.
- **Dresseurs** : `TrainerRules` expose déjà la vue en fin de pas ; la dérive demande
  `seen_by_trainer` **avant** de lancer le pas suivant (écart n° 12).
- **Descente du vélo** : refusée sur `cycling_road` (T-§16.1.4).
- **Objet caché sur la Piste** : Action face à la case : comme partout (la dérive s'arrête pendant
  le dialogue, `player_free` faux).

### 2.4 Bouton « Vélo » du HUD (T15)

- `ExplorationHud` : `TouchScreenButton` `%BikeButton` avec `RoundButtonVisual`, icône
  `assets/ui/icons/hud/bike.svg` (UI non pixel art). Placé au-dessus du bouton Course [D].
- Visible si `got_bicycle` **et** `are_controls_visible()` ; grisé [D] en intérieur et sur la Piste
  (le toucher affiche le message de refus).
- Signal `bike_toggle_requested` → `Boot` → `BikeRules` → `Player.set_riding`.
- Clavier (tests desktop) : action d'entrée `bike` sur la touche B [D] (`project.godot`).

### 2.5 Pêche : règles pures (T3)

```gdscript
# game/world/fishing/fishing_rules.gd — pur, statique
class_name FishingRules
const RODS: Array[StringName] = [&"old_rod", &"good_rod", &"super_rod"]  # du moins bon au meilleur
## Meilleure canne possédée, ou &"" (M-9).
static func best_rod(bag: Bag) -> StringName
## Chance de touche par canne : 100 / 50 / 75 % (dossier §7.4).
static func bite_chance(rod: StringName) -> int
## Table à utiliser : globale pour old_rod et good_rod ; par carte pour super_rod, sinon défaut.
static func table_for(library: EncounterLibrary, rod: StringName, map_id: StringName) -> EncounterTable
## Tirage complet : touche ou non, puis rencontre (null si rien ne mord).
static func roll(rng: GameRng, library: EncounterLibrary, rod: StringName, map_id: StringName) -> WildEncounter
```

```gdscript
# game/world/fishing/fishing_spot.gd — pur
class_name FishingSpot
## Case d'eau pêchable devant le joueur, ou null : case de devant pêchable (grille ou
## fishable.json), joueur sur une case praticable, aucune entité devant, pas sur la Piste.
static func in_front(grid: GridWorld, cell: Vector2i, facing: Vector2i, cycling_road: bool) -> Vector2i  # Vector2i(-1, -1) si aucune
```

### 2.6 Pêche : tables (T4, T12)

- `EncounterTable.TERRAINS` gagne `&"water_rod"` (en fin). Une table `water_rod` porte en plus
  `"rod": "old_rod" | "good_rod" | "super_rod"` ; la clé de bibliothèque devient (carte, terrain,
  canne) **pour ce terrain seulement** ; `maps: ["*"]` = table globale ; `"default": true` =
  table par défaut de la Méga Canne.
- **Aucun tirage au pas** sur ce terrain : `EncounterDirector.terrain_at` ne renvoie jamais
  `water_rod` (la pêche passe par `start_encounter`, l. 113).
- `data/encounters/water_rod.json` :

```json
{
  "old_rod_any":   { "maps": ["*"], "terrain": "water_rod", "rod": "old_rod",  "rate": 100,
                     "slots": [ { "species": "magikarp", "level": 5, "weight": 1 } ] },
  "good_rod_any":  { "maps": ["*"], "terrain": "water_rod", "rod": "good_rod", "rate": 50,
                     "slots": [ { "species": "goldeen", "level": 10, "weight": 1 },
                                { "species": "poliwag", "level": 10, "weight": 1 } ] },
  "super_rod_default": { "maps": ["*"], "default": true, "terrain": "water_rod", "rod": "super_rod", "rate": 75,
                     "slots": [ { "species": "tentacool", "level": 5, "weight": 1 },
                                { "species": "krabby", "level": 15, "weight": 1 },
                                { "species": "goldeen", "level": 15, "weight": 1 },
                                { "species": "magikarp", "level": 15, "weight": 1 } ] },
  "super_rod_fuchsia": { "maps": ["fuchsia_city"], "terrain": "water_rod", "rod": "super_rod", "rate": 75,
                     "slots": [ { "species": "seaking", "level": 23, "weight": 1 },
                                { "species": "krabby", "level": 15, "weight": 1 },
                                { "species": "goldeen", "level": 15, "weight": 1 },
                                { "species": "magikarp", "level": 15, "weight": 1 } ] }
}
```

- Routes 12, 13, 18 : table par défaut (RB Groupe 7) [D : pas de fichier par route].
- **Garde** (test) : chaque espèce d'une table existe dans les données, a une face et un dos.

### 2.7 Pêche : déroulé (T13)

`FishingDirector` (nœud de `Boot`, sur le modèle des petits directeurs existants) :
1. `InteractionController` : sans entité devant, `FishingSpot.in_front(...)` et
   `FishingRules.best_rod(bag) != &""` → cible `Interaction.FISH`, verbe « Pêcher » [D].
   Sac → UTILISER une canne : même chemin avec la canne choisie ; sans case pêchable → §16.2.11.
2. Entrée verrouillée (`set_input_enabled(false, &"fishing")`), compagnon `withdraw()`.
3. Pose « lancer » ; texte §16.2.8 ; attente 1–2 s [D] (`GameRng`) ; bulle « ! » existante.
4. `FishingRules.roll` : rencontre → §16.2.9 → `EncounterDirector.start_encounter(encounter)`
   avec le **fond `route_12_ponton`** (`places` de `decors.json` : clé `water_rod` [D]) ; sinon
   §16.2.10.
5. Fin : entrée rendue, compagnon `appear()` (sauf en selle).
- **Aucune écriture** de sauvegarde pendant la pêche (`is_stable` faux : la pêche compte comme
  une scène).

### 2.8 Objets (T4, T11)

`data/items/items_j22.json` (T4 sans `key_use`, T11 l'ajoute) :

| Id | Catégorie | `key_use` (T11) | Texte |
|---|---|---|---|
| `bike_voucher` | key | — | §16.1.6 |
| `bicycle` | key | `bicycle` | §16.1.7 |
| `old_rod` | key | `fishing_rod` | §16.2.5 |
| `good_rod` | key | `fishing_rod` | §16.2.6 |
| `super_rod` | key | `fishing_rod` | §16.2.7 |
| `hyper_potion` | medicine | — | §16.7.1 (soin 200) |
| `ultra_ball` | ball | — | §16.7.2 (bonus 2) |

- `KEY_USES` gagne `&"bicycle"`, `&"fishing_rod"` (en fin). `key_use` borne les contextes à
  **exploration seulement** pour ces deux usages [D] (la Flûte du J21 reste exploration + combats) :
  `contexts()` lit une table `KEY_USE_CONTEXTS`.
- `Boot._on_field_item_requested` (l. 1632) : `bicycle` → bascule du vélo (§2.2) ; `fishing_rod`
  → pêche avec cette canne (§2.7).
- Stock de la Boutique de Parmanie : `data/shops/fuchsia_mart.json` [D] (format existant).

### 2.9 Bon de Commande et Bicyclette (T17)

- **Carmin, président du Fan Club** : variante de dialogue `unless [got_bike_voucher]` avec choix
  OUI / NON (`dialogue_choice.gd`) ; OUI → scène `j22_fan_club_voucher` : bulles §16.1.9, `give
  bike_voucher` (système §16.1.10), `set [got_bike_voucher]` ; NON → §16.1.11. Ensuite §16.1.12.
  Remise **idempotente** (condition sur le drapeau **et** la possession, modèle de la Flûte du J21).
- **Azuria, vendeur** : variante `if_items [bike_voucher]` (clé du J20) → scène
  `j22_bike_exchange` : §16.1.13, `take bike_voucher` (étape de retrait : existe-t-elle ? T10
  vérifie ; sinon `give` avec `count: -1` [D]), `give bicycle` (système §16.1.14), `set
  [got_bicycle]`. Ensuite §16.1.15 si `got_bicycle`.
- Rien d'autre ne change à Carmin ni à Azuria (fichiers d'autres jalons : blocs « J22 » courts).

### 2.10 Postes de la Piste (T18)

- Scène `j22_cycling_gate_rule_16` (et `_18`), modèle `route_5_gate_rule` :
  - variante `unless_items [bicycle]` : face, §16.1.1, recul d'une case ;
  - variante `if_items [bicycle]`, `unless [cycling_gate_16_greeted]` : §16.1.2, `set` ;
  - sinon : rien (passage).
- Déclencheur sur la case devant la porte côté Piste ; la sortie côté Piste pose `riding_bicycle`
  par `BikeRules.on_map_entered(…, cycling_road=true)` (montée d'office, sans message).
- Poste 16 : enveloppe à **deux couloirs** (écart n° 6) ; couloir haut sans garde.

### 2.11 Cartes (T12, T19, T21, T22)

| Carte | Outil | Grille | Raccords | Particularités |
|---|---|---|---|---|
| `route_12_south` | `build_route_12_sud.gd` | `route_12_sud.txt` (30 × 70) | N ↔ Route 12 (25..26, 100/101) ; O ↔ Route 13 | Maison de la Méga Canne (`route_12_rod_house`), ponton pêchable, herbes |
| `route_13` | `build_route_13.gd` | `route_13.txt` (90 × 27) | E ↔ Route 12 sud ; O ↔ Route 14 | Clôtures, berge nord pêchable |
| `route_14` | `build_route_14.gd` | `route_14.txt` (30 × 81) | E ↔ Route 13 ; O ↔ Route 15 | |
| `route_15` | `build_route_15.gd` | `route_15.txt` (90 × 27) | E ↔ Route 14 ; O ↔ Parmanie | Poste `route_15_gate` 1F + 2F (assistant, jumelles) |
| `route_16_west` | `build_route_16_west.gd` | `route_16_west.txt` [D] | E ↔ poste 16 (portes basse et haute) ; S ↔ Route 17 | Voie basse = Piste (`cycling_road`) ; voie haute : herbe, objet caché, maison de Vol (`coming_soon`) |
| `route_16_gate` | `build_painted_interiors.gd` (bloc J22) | `route_16_gate.txt` (14 × 10) | Route 16 est (J21) ↔ Route 16 ouest | Garde de la Piste, couloir haut |
| `route_17` | `build_route_17.gd` | `route_17.txt` (30 × 150) | N ↔ Route 16 ouest ; S ↔ Route 18 | `cycling_road`, pente, 3 paliers, 5 cachés |
| `route_18` | `build_route_18.gd` | `route_18.txt` (75 × 27) | N ↔ Route 17 ; E ↔ Parmanie ; poste au milieu | Ouest = Piste ; poste `route_18_gate` |
| `fuchsia_city` | `build_fuchsia_city.gd` | `parmanie.txt` (60 × 54) | O ↔ Route 18 ; E ↔ Route 15 ; **S : bord `warp_sud` réservé à la Route 19 (J24)**, rangée y = 53, colonnes **24..32** (terrasse de sable) et **34..35** (couloir) praticables, `coming_soon=route_19` ; colonne Parmanie = colonne Route 19 + 15 | 5 intérieurs, 3 portes `coming_soon`, enclos, étang pêchable |

- **Accord du J21 (2026-10-19, option B)** : `route_16.txt` reste celle du J21 ; **T19** applique, dans le
  bloc « J22 » de `build_route_16.gd` et de la grille, les cases notées en tête de `route_16_gate.txt`
  (voie haute (18..25, 11..12), porte haute (19..20, 13), lien de l'arbre (38..39, 17..18), porte basse
  (15..16, 20) → `entrance_bas_est`, arrivée (15..16, 21)), vérifiées par la session du J21. **Aucun
  contournement de Ronflex** : couloirs du poste séparés et falaise entre la voie haute et la Piste (RB).
- **Route 16 du J21** : T19 retire le `coming_soon` de la porte (15..16, 20) et rend l'arbre
  (38..39, 19..20) coupable (`InteractPoint` `cut_tree`, `unless [cut_route_16_tree]`, `FlagGate`
  sur ses cases), en bloc « J22 » dans `build_route_16.gd`.
- **Route 12 du J21** : T12 retire le `coming_soon` du `warp_sud` (bloc « J22 » dans
  `build_route_12.gd`).
- Rencontres d'herbes : tables `grass` par carte (dossier §8.8), pondérations RB.
- Toutes les cartes : ≤ 3 000 nœuds (règle des cartes peintes) ; zones de `zones.json` ; fonds
  `places` de `decors.json`.

### 2.12 Dresseurs, classes, espèces (T5, T8)

- **Classes** (données de classe existantes) : `fisherman` « Pêcheur », `biker` « Motard »,
  `bird_keeper` « Ornithologue », `cue_ball` « Loubard » ; `prize_per_level` RB [D] (Pêcheur 35,
  Motard 20, Ornithologue 25, Loubard 25).
- **40 Dresseurs** : ids et équipes du dossier §9 ; `ai: random` ; portée = RB × 1,5 ; répliques
  §16.4 mot pour mot. Les inévitables (I) sont placés par la grille (le contrôle T6 vérifie qu'il
  n'y en a qu'un par route et qu'un chemin évite tous les autres).
- **Espèces** `species/kanto_j22.json` (13, correction du 2026-10-19) : Magicarpe, Krabby, Poissoroy, Mimitoss, Aéromite, Doduo, Dodrio,
  Canarticho, Tadmorv, Grotadmorv, Smogogo, Électrode, Machopeur ; données RB (statistiques, types,
  learnset jusqu'au N40, évolutions du dossier §12.1), entrées de Pokédex réécrites (§16.7.3).
- **Magicarpe** : reprise **à l'identique** de l'entrée créée par le J24 (`jalon-24`,
  `data/pokemon/species/kanto_j24.json`, `magikarp` : dex 129, Eau, PV 20 / Att 10 / Déf 55 /
  Spé A 15 / Spé D 20 / Vit 80, croissance lente, exp. 40, capture 255, Trempette N1, Charge N15,
  Léviator N20). Le J22, plus ancien, la porte dans `kanto_j22.json` ; le J24 retire sa copie à la
  fusion (accord du 2026-10-16).
- **Capacités** `moves/j22.json` : celles des learnsets qui manquent **et** dont l'effet existe
  (Trempette = aucun effet). Les autres sont remplacées (dossier §12.3) ; liste dans le rapport
  de T4 pour Kevin.

### 2.13 Sauvegarde : **aucun changement de version** (v7)

- `SaveSystem.VERSION` reste **7**.
- Drapeaux du J22 (tous dans `StoryFlags`) : `got_bike_voucher`, `got_bicycle`, `riding_bicycle`,
  `got_old_rod`, `got_good_rod`, `got_super_rod`, `cut_route_16_tree`,
  `cycling_gate_16_greeted`, `cycling_gate_18_greeted`, `beaten_<id>` ×40, `got_<carte>_item_N`,
  `got_<carte>_hidden_N`, `route_*_visited` (si le modèle des visites l'exige).
- Objets : identifiants du Sac (existant).

**Tests d'interruption** (`tests/integration/test_save_j22.gd`, vraie Boot) :

| n° | Point de coupure | Attendu au rechargement |
|---|---|---|
| 1 | En selle sur la Route 13 | en selle, compagnon rentré |
| 2 | Sur la Route 17, `riding_bicycle` retiré à la main (donnée abîmée) | remis en selle (Piste) |
| 3 | Application tuée pendant la pêche | sauvegarde d'avant ; aucune rencontre fantôme |
| 4 | Après le Bon, avant l'échange | Bon dans le Sac, `got_bike_voucher` ; président §16.1.12 ; vendeur échange |
| 5 | Après l'échange | Bicyclette, pas de Bon ; bouton HUD visible |
| 6 | Après la Méga Canne seule | Action face à l'eau → Méga Canne |
| 7 | Défaite sur la Piste | Centre, à pied |
| 8 | Sauvegarde J21 (fixture : Flûte, Ronflex `_done`, aucun drapeau J22) | rien ne casse ; Fan Club propose l'histoire ; Route 12 sud ouverte |

Plus : `test_the_jalon_22_adds_no_save_version` ; chaque drapeau du J22 survit à un aller-retour ;
**aucun drapeau du J22 n'est lu par un poste de Safrania** (`test_j22_flags_contract`).

### 2.14 Départs de débogage (`tools/debug_start/`)

Équipe de référence [D] : starter final N36, Roucarnage N34, Ronflex N30 (capturé au J21),
Ptitard N28, Évoli N28, Nidorino N30. Sac : 10 Super Balls, 10 Super Potions, 3 Rappels, Poké
Flûte, CS01. 8 000 ₽. Badges jusqu'au Prisme. Drapeaux jusqu'à `got_poke_flute`,
`snorlax_route_12_done`, `snorlax_route_16_done`. T10 recale sur les sorties réelles du J21.

| Départ | Sous-jalon | Contenu |
|---|---|---|
| `fishing_qa` | 22A | Carmin, devant le pêcheur, `got_old_rod` absent |
| `route_12_south_qa` | 22A | Route 12, `from_route_12_sud`, Canne ; Dresseurs non battus |
| `route_15_qa` | 22A | Route 15 est, Méga Canne ; poste 15 |
| `bike_qa` | 22B | Carmin, Fan Club, ni Bon ni Bicyclette |
| `cycling_road_qa` | 22B | Poste 16, Bicyclette ; Dresseurs non battus |
| `cycling_road_nobike_qa` | 22B | Poste 16 **sans** Bicyclette (refus) |
| `fuchsia_qa` | 22C | Parmanie, entrée est, Canne et Bicyclette |
| `j22_full_qa` | 22C | Lavanville, Flûte, Ronflex 12 endormi, rien du J22 : parcours complet par l'est puis l'ouest |

### 2.15 Art (lot 22.0) — **série 25** proposée

Séries prises au 2026-10-16 (branches distantes) : 20 (J19), 21 (J18), 22 (J20), 23 (J21), 24 (J19 : escalier et dalle purifiée). **Série 25 pour le J22** (conflit du 24 tranché par la règle de Kevin : priorité à la session la plus ancienne), revérifiée
au T7 (fiche `docs/design/fiches-assets/serie-25-deux-chemins.md`, outil `tools/art/serie25.py`).

| Élément | État | Besoin |
|---|---|---|
| **Planche « vélo » du joueur** | rien | 4 directions, arrêt + pédalage ; garçon et fille si le profil l'exige |
| **Planche « pêche » du joueur** | rien | 4 directions, lancer + attente |
| Pêcheur | existe (`pecheur_sheet.png`) | décliné pour les 3 frères [D] |
| **Motard, Ornithologue, Loubard** | rien | 3 planches PNJ |
| Président du club, vieil homme | vieil homme générique existe | président : planche [D, réemploi du gentleman] |
| **Kangourex, Ramoloss (monde)** | rien | 2 Pokémon d'ambiance peints, routine courte |
| **12 dos de combat** | Magicarpe : `dos_ia_129` prototype | chaîne X/Y repeinte (`tools/art/dos_t13.py`) ; repli artwork officiel [D] |
| **Fonds CB.3** | aucun fond d'eau | `route_12_ponton`, `route_13_15_prairie`, `route_16_18_piste`, `parmanie_ville` (`tools/art/combat_decors/`) |
| **Vues générales** | rien | Route 12 sud, 13, 14, 15, 16 ouest, 17, 18, Parmanie (+ plans) ; intérieurs (postes, maisons, Salle de réunion) |
| **Icônes** | rien | Bon, Bicyclette, 3 cannes, Hyper Potion, Hyper Ball ; bouton HUD « Vélo » (`ui-theme-2026`) |

---

## 3. Tâches

Chaque tâche :
- part d'une branche `j22-t<n>-<sujet>` créée depuis `jalon-22` ;
- n'utilise jamais `pkill` ni `killall` (arrêter ses propres processus par PID) ;
- reprend les textes **mot pour mot** (dossier §16 validé) ;
- met à jour `docs/tech/etat-projet.md` dans son commit ;
- **CA communs** : `tools/test.sh` vert ; `godot --headless --path . --import` sans `ERROR`.

Agents : **A** architecte-godot, **C** constructeur-monde, **U** ui-mobile, **Q** qa-mobile, **K**
Kevin.

### 3.1 Sous-jalon 22.0

#### T0 — A : plan (ce document)

#### T1 — A : branche `jalon-22` — **maintenant**
- Créer `jalon-22` depuis `origin/jalon-21` dans une copie dédiée ; y fusionner
  `docs/dossier-25-j22`.
- **CA** : tests verts, import propre.

#### T2 — A : logique pure du vélo et de la pente — **maintenant**
- `bike_rules.gd`, `cycling_slope.gd` (§2.1, §2.3).
- **Tests** `tests/unit/test_bike_rules.gd`, `test_cycling_slope.gd` : montée refusée sans vélo,
  en intérieur ; descente refusée sur la Piste ; durée vélo < course < marche ; course ignorée à
  vélo ; `on_map_entered` (intérieur → descente, Piste → montée, ailleurs → rien) ; dérive
  seulement sans appui, sur pente, joueur libre, sans Dresseur.

#### T3 — A : logique pure de la pêche — **maintenant**
- `fishing_rules.gd`, `fishing_spot.gd` (§2.5).
- **Tests** `test_fishing_rules.gd`, `test_fishing_spot.gd` : meilleure canne ; chances 100 / 50 /
  75 % sur 10 000 tirages (± 2 %) ; table globale, par carte, défaut ; case pêchable devant
  seulement (pas en diagonale, pas derrière une entité, pas sur la Piste) ; aucune canne → rien.

#### T4 — A : données valides sur `jalon-21` — **maintenant**
- `items_j22.json` (sans `key_use`), `species/kanto_j22.json` (13 espèces), `moves/j22.json`,
  `encounters/water_rod.json` (§2.6 ; Ptitard et Tentacool : si absents de `jalon-21`, rédigés
  et validés après T10), Pokédex.
- **CA** : toutes les données se chargent ; liste des capacités remplacées envoyée à Kevin.

#### T5 — A : Dresseurs et rencontres — **rédigés maintenant, validés après T10**
- `trainers/route_12_sud.json` … `route_18.json` (40, §9), `encounters/route_*.json` (herbes,
  §8.8), classes (§2.12).
- **CA après T10** : chaque espèce existe ; chaque Dresseur a une face et un dos pour chaque
  Pokémon.

#### T6 — C puis K : grilles et contrôle — **maintenant**
- `tools/plans/route_12_sud.txt`, `route_13.txt`, `route_14.txt`, `route_15.txt`,
  `route_15_gate.txt`, `route_16_west.txt`, `route_16_gate.txt`, `route_17.txt`, `route_18.txt`,
  `route_18_gate.txt`, `parmanie.txt` ; caractères pour « pêchable », « pente », « Piste » ;
  `data/world/fishable.json` (rectangles des six cartes livrées) ; contrôle
  `tools/art/plan_check_j22.py`.
- **Contrôle** : raccords alignés (Route 12 (25..26, 101) → Route 12 sud) ; Parmanie atteignable
  par chaque chemin ; **un** inévitable au plus par route et un chemin qui évite les autres ;
  pente seulement sur la Route 17, paliers ≥ 3 ; Parmanie : rangée 53, colonnes 24..32 et 34..35 praticables (raccord Route 19 du J24) ; aucune case pêchable sur la Piste ; portes J23
  `coming_soon`.
- **CA** : Kevin valide les grilles.

#### T7 — A puis C (Mac, Codex) : art, série 25 — **maintenant**
- Fiche, kit, génération, planche de contact → K, intégration (§2.15). Dos de combat et fonds
  CB.3 sur leurs chaînes existantes.
- **CA** : Kevin valide la planche de contact ; `test_battle_art` vert pour les 13 espèces.

#### T8 — C : planches PNJ — **maintenant**
- Motard, Ornithologue, Loubard ; frères pêcheurs ; président du club ; `build_character_frames.gd`
  (en fin).

#### T9 — C puis K : vues générales peintes — après T6
- Routes 12 sud à 18, Parmanie (+ plans), intérieurs. **CA** : Kevin valide.

#### T10 — A : alignement après la clôture du J21 — **après la clôture du J21**
- Fusionner `origin/main` (J15 à J21) dans `jalon-22`. Vérifier : `key_use` livré (sinon T11 le
  crée selon `jalon-21.md` §2.1) ; `if_items` sur dialogues et scènes ; étape de retrait d'objet ;
  `full_heal` ; règle de Frénésie (CT20) ; marquage `interior` des grottes ; scènes des Routes 12 et
  16 du J21 ; Ptitard, Tentacool, Léviator, Saquedeneu, Kangourex ; recaler §0.3 et les départs.
- **CA** : rapport d'alignement dans ce fichier (§0.4 mis à jour) ; décisions CT20 et Total Soin
  envoyées à Kevin.

### 3.2 Sous-jalon 22A (le chemin des pêcheurs)

#### T11 — A : objets clés utilisables du J22 — après T10
- `key_use` `bicycle` et `fishing_rod`, contextes « exploration » (§2.8) ; aiguillage dans
  `Boot._on_field_item_requested`.
- **Tests** : la Bicyclette et les cannes ont UTILISER en exploration, pas en combat ; les autres
  objets clés inchangés ; suites `test_bag*` vertes.

#### T12 — A puis C : terrain `water_rod`, cases pêchables, Route 12 sud — après T11, T5, T6
- `encounter_table.gd` (`water_rod`, clé `rod`, `maps: ["*"]`, `default`), `encounter_library.gd`
  ; `grid_world.gd` (`_FLAG_FISHABLE`) ; `map.gd` (grille + `fishable.json`) ;
  `build_route_12_sud.gd`, maison de la Méga Canne, raccord avec la Route 12 du J21.
- **Tests** : `water_rod` jamais tiré au pas ; table par défaut ; cases pêchables chargées sur les
  six cartes livrées ; raccord Route 12 ↔ Route 12 sud aller-retour ; Ronflex `_done` requis.

#### T13 — A puis U : pêche jouable — après T12
- `FishingDirector`, cible `FISH` de l'`InteractionController`, verbe « Pêcher », poses, bulle,
  compagnon rentré (§2.7) ; Canne à Carmin (variante + scène), Méga Canne (scène).
- **Tests** `tests/integration/test_fishing.gd` (vraie Boot) : Action face à l'eau sans canne →
  rien ; avec la Canne → Magicarpe N5 ; sans touche → §16.2.10 ; Sac → canne loin de l'eau →
  §16.2.11 ; aucune sauvegarde pendant la pêche ; remises uniques.

#### T14 — A : mode vélo (moteur) — après T11 (peut précéder T12)
- `grid.gd` (`BIKE_STEP_DURATION`), `grid_mover.gd`, `player.gd` (`set_riding`, `kind = &"bike"`,
  animations), `companion` rentré, `riding_bicycle`, `BikeRules.on_map_entered` (§2.2).
- **Tests** `test_player_bike.gd` : vitesse ; course ignorée ; intérieur → descente ; rebord à
  vélo ; compagnon rentré puis ressorti ; rechargement en selle.

#### T15 — U : bouton « Vélo » du HUD — après T14
- §2.4. **Tests** : visible avec `got_bicycle` seulement ; masqué avec les contrôles ; grisé en
  intérieur ; touche B en desktop.

#### T16 — A : Piste et pente — après T14
- `GameMap.cycling_road`, cases de pente, dérive dans `Player._process`, refus de descente,
  arrêt devant un Dresseur (§2.3).
- **Tests** `test_cycling_slope_world.gd` : sans appui, le joueur descend de N cases en N pas ;
  gauche, droite, haut libres ; arrêt sur palier ; arrêt quand un Dresseur voit ; aucune dérive
  pendant un dialogue.

#### T17 — C : Bon de Commande et Bicyclette — après T11
- Carmin (président : choix, scène, variantes), Azuria (vendeur : échange) (§2.9).
- **Tests** : NON → rien ; OUI → Bon, une fois ; échange → Bicyclette, Bon retiré ; sans Bon →
  réplique existante ; rien d'autre ne change à Carmin et Azuria.

#### T18 — C : postes de la Piste — après T16, T17
- Scènes de garde, déclencheurs, montée d'office côté Piste (§2.10), poste 16 à deux couloirs,
  poste 18.
- **Tests** : sans vélo, refus et recul ; avec, §16.1.2 une fois puis rien ; sortie côté Piste en
  selle ; côté ville à pied.

#### T19 — C : Route 16 ouest, arbre, voie haute — après T18
- `build_route_16_west.gd`, bloc « J22 » de `build_route_16.gd` (porte, arbre coupable),
  5 Dresseurs, objet caché, maison de Vol `coming_soon`.
- **Tests** : arbre coupé une fois (`cut_route_16_tree`) ; voie haute ↔ couloir haut du poste ;
  voie basse = Piste ; aucune entrée dans la maison.

#### T20 — C : Route 17 et Route 18 — après T16, T19
- `build_route_17.gd` (pente, 3 paliers, 8 Dresseurs, 5 cachés), `build_route_18.gd` (Piste à
  l'ouest, poste 18, partie est à pied, 3 Dresseurs).
- **Tests** : descente complète sans appui jusqu'au premier Dresseur en vue ; objets cachés
  ramassés à vélo ; poste 18 depuis l'est sans vélo → refus.

#### T21 — C : Routes 13, 14, 15 et poste 15 — après T12, T5
- 3 cartes, poste 15 (1F + 2F, assistant sans cadeau, jumelles), 21 Dresseurs, objets (§11).
- **Tests** : un chemin évite tous les Dresseurs non (I) ; objets une fois ; rencontres des tables
  du dossier ; raccords.

#### T22 — Q : **session 22A** → K — après T13, T21
| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `fishing_qa` | parler au pêcheur de Carmin, pêcher sur le quai | Canne ; Magicarpe ; « Rien ne mord… » sur d'autres essais (Super Canne : non) |
| 2 | `route_12_south_qa` | Route 12 sud → Méga Canne → pêcher sur le ponton | table par défaut ; fond `route_12_ponton` |
| 3 | (suite) | Routes 13 → 14 → 15 → poste 15 | clôtures lisibles ; assistant ; aucun inévitable de trop |
| 4 | (suite) | relancer l'appli à chaque étape | état gardé |
| 5 | (fps) | Route 13, ponton | ≥ 58 fps de moyenne |

### 3.3 Sous-jalon 22B (la Piste)

#### T23 — Q : **session 22B** → K — après T15, T17 à T20
| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `bike_qa` | Fan Club : NON puis OUI ; Azuria : échange | Bon, puis Bicyclette ; bouton HUD |
| 2 | (suite) | rouler dans Azuria, entrer au Centre | vitesse ; descente automatique ; compagnon rentré puis ressorti |
| 3 | `cycling_road_nobike_qa` | entrer côté Piste | refus, recul |
| 4 | `cycling_road_qa` | descendre la Piste au doigt | dérive confortable, paliers, Dresseurs en retrait ; descente du vélo refusée |
| 5 | (suite) | voie haute : couper l'arbre | objet caché ; maison fermée |
| 6 | (suite) | Route 18 jusqu'au poste et au-delà | à pied côté est |
| 7 | (fps) | Route 17 | ≥ 58 fps de moyenne, creux ≥ 50 |

### 3.4 Sous-jalon 22C (Parmanie)

#### T24 — C : Parmanie — après T12 (cases pêchables), T9
- `build_fuchsia_city.gd`, 5 intérieurs (Centre, Boutique, Super Canne, Salle de réunion,
  grand-père), 3 portes `coming_soon`, enclos (Kangourex, Ramoloss), panneaux, 4 PNJ, étang
  pêchable, table Méga Canne de Parmanie, Super Canne, raccords Route 15 et Route 18 ; zones,
  fonds.
- **Tests** : Super Canne une fois ; Poissoroy possible à la Méga Canne ici seulement ; portes
  J23 fermées ; enclos sans combat ni Pokédex ; raccords aller-retour.

#### T25 — A : sauvegarde, contrat, équilibrage — après T24
- `test_save_j22` (§2.13), `test_j22_flags_contract` ; simulation : une équipe N30–34 traverse
  chaque chemin sans soin forcé (`tools/simulate_mt_moon.gd -- --scenario=j22`, 100 parties) ;
  au-delà du seuil, retirer un Pokémon, jamais un niveau (dossier §9).

#### T26 — Q : **session 22C** et QA de bout en bout → K, fusion — après T25
| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `fuchsia_qa` | Parmanie : intérieurs, enclos, portes réservées | textes §16.6 ; « À venir » en debug |
| 2 | (suite) | Super Canne, pêcher dans l'étang | Super Canne ; Poissoroy possible à la Méga Canne |
| 3 | `j22_full_qa` | Lavanville → Ronflex 12 → Routes 12 sud à 15 → Parmanie | **sans blocage** |
| 4 | (suite) | Parmanie → Route 18 (refus sans vélo) → Céladopole → Ronflex 16 → Piste → Parmanie | **sans blocage** (critère de clôture) |
| 5 | (suite) | relancer l'appli à chaque étape | état gardé |
| 6 | **vraie partie de Kevin** (si le J21 y est arrivé) | jusqu'à Parmanie | aucune régression |

**Critère de clôture (V2)** : les deux Ronflex réveillés, le joueur atteint Parmanie par chacun des
deux chemins, avec les prérequis de chacun, puis explore librement.

#### T27 — A : clôture et passation — après T26
- `etat-projet.md`, roadmap, `CLAUDE.md`.
- **Passation au J23** : portes `coming_soon` de l'Arène, du Parc Safari, de la Maison du Gardien,
  de la maison de Vol (Route 16) ; club du Safari ; Erik et Sara (si le J23 les reprend).
- **Reportés** : Métamorph et Morphing ; Multi Exp ; vitamines, PP Plus, Élixirs, Repousse ;
  Krabboss ; musique du vélo ; îlot de la CT16 (Surf).

---

## 4. Critères d'acceptation par sous-jalon

**22.0** : grilles et vues validées ; logique pure testée ; données valides (13 espèces, objets,
tables d'eau ; Dresseurs et rencontres après T10) ; art validé ; alignement T10 fait ; tests
verts, import propre.

**22A** : pêche (meilleure canne, chances, tables, aucune sauvegarde pendant) ; Canne et Méga Canne
uniques ; cases pêchables des cartes livrées ; Route 12 sud et Routes 13 à 15 jouables, Dresseurs
évitables sauf un par route ; session validée.

**22B** : Bon puis Bicyclette, jamais automatiques ; vélo (vitesse, lieux, compagnon, HUD) ;
Piste (refus sans vélo, montée d'office, pente, paliers, arrêt devant un Dresseur, descente
refusée) ; Route 16 ouest (arbre, voie haute) ; Routes 17 et 18 ; session validée.

**22C** : Parmanie (5 intérieurs, enclos, 3 portes réservées, Super Canne) ; les deux chemins de
bout en bout ; sauvegarde v7 et tests d'interruption ; équilibrage ; ≥ 58 fps ; validation de
Kevin, puis fusion.

---

## 5. Cas limites (dossier §17) → tests

| Cas | Test | Attendu |
|---|---|---|
| Sauvegarde sur la Piste | `test_save_j22` n° 1, 2 | en selle |
| Défaite sur la Piste | `test_save_j22` n° 7 | Centre, à pied |
| Parmanie par l'est sans vélo | `test_route_18` | refus au poste |
| Vélo puis intérieur | `test_player_bike` | descente |
| Pêche avec le compagnon | `test_fishing` | rentré puis ressorti |
| Pêche sur la Piste | `test_fishing_spot` | impossible |
| Dresseur en vue sur la pente | `test_cycling_slope_world` | arrêt, combat, reprise |
| Objet caché sur la Piste | `test_route_17` | ramassé |
| Ronflex rendormi | tests du J21 gardés | passage fermé |
| Bon pour une partie avancée | `test_save_j22` n° 8 | proposé au Fan Club |
| Équipe pleine après une pêche | `test_fishing` | Stockage |
| Espèce sans données dans une table | `test_water_rod_tables` | refusée |
| Safrania | `test_j22_flags_contract` | aucun drapeau J22 lu |

---

## 6. Risques et ordre

| Risque | Effet | Parade |
|---|---|---|
| **Sept jalons non fusionnés** (J15–J21) | conflits, cartes impossibles à poser | C-8 / M-2 ; 22.0 en fichiers nouveaux ; blocs « J22 » courts dans les fichiers des autres |
| **La pente rend la Piste frustrante au doigt** | rejet en 22B | paliers ; dérive seulement sans appui ; paramètres en données ; session 22B dédiée |
| **Vitesse du vélo et caméra** | saccades, fps | mesure en T14 et T23 ; durée en donnée |
| **Cases pêchables de six cartes d'autres jalons** | conflits | `fishable.json` à part, aucune grille modifiée |
| **Taille du contenu** (8 cartes, 40 Dresseurs, 13 espèces) | délai | contenu parallélisable par carte (T12, T19 à T21, T24) ; art lancé dès 22.0 |
| **`key_use` du J21 livré autrement** | §2.8 à réécrire | T10 réaligne |
| Échec intermittent de `tools/test.sh` sous charge | faux rouge | relancer le fichier seul avant de conclure |

```
Maintenant  : T1 ─→ T2 ∥ T3 ∥ T4 ∥ T5 (rédaction) ; T6 (K) ─→ T9 (K) ; T7 ∥ T8
[clôture J21] ─→ T10 ─→ T11 ─→ T12 ─→ T13 ; T21 ─→ T22 (téléphone 22A)
22B          : T11 ─→ T14 ─→ T15 ∥ T16 ; T17 ─→ T18 ─→ T19 ─→ T20 ─→ T23 (téléphone 22B)
22C          : T24 ─→ T25 ─→ T26 (téléphone) ─→ T27
```

**Peut commencer maintenant** : T1 à T9 (T5 en rédaction, T9 après validation des grilles).

---

## 7. Valeurs par défaut (règle 4)

| Sujet | Valeur |
|---|---|
| Vitesse à vélo | 0,12 s par case (`Grid.BIKE_STEP_DURATION`) |
| Bouton « Vélo » | au-dessus du bouton Course ; grisé en intérieur et sur la Piste ; touche B en desktop |
| Verbe du bouton d'interaction face à l'eau | « Pêcher » |
| Attente avant la touche | 1 à 2 s |
| Fond de combat de la pêche | `route_12_ponton`, partout |
| Routes 12, 13, 18 (Méga Canne) | table par défaut, pas de fichier par route |
| Cases pêchables des cartes livrées | rectangles dans `data/world/fishable.json` |
| Route 16 ouest | carte séparée `route_16_west` |
| Poste 16 | enveloppe 14 × 10 à deux couloirs |
| Postes 16 et 18 | sans 2F |
| Argent par niveau | Pêcheur 35, Motard 20, Ornithologue 25, Loubard 25 |
| Contextes des objets clés du J22 | exploration seulement |
| Retrait d'objet (échange du Bon) | étape existante, sinon `give` avec `count: -1` |
| Animation de pêche sans planche | `idle` + bulle « … » |
| Série d'art | 25 (24 prise par le J19) |

---

## 8. État des tâches et QA (2026-10-21, session de nuit)

### 8.1 Fait

| Tâche | Où |
|---|---|
| T10 alignement | §0.5 ; fusion de `origin/systemes-2` |
| T11, T14, T15, T16 (systèmes) | **passe systèmes 2** (réutilisés tels quels) ; `cycling_road_cells` [D] du J22 |
| T12 cases pêchables, Route 12 sud | `GameMap.fishable_set` + `fishable.json` ; `route_12_south`, maison de la Méga Canne |
| T13 cannes | Canne (pêcheur de Carmin, variante), Méga Canne (Route 12 sud), Super Canne (Parmanie) |
| T17 Bon et Bicyclette | Fan Club (choix OUI / NON), Boutique de Vélos d'Azuria (`if_items`, `take`) |
| T18 postes de la Piste | `route_16_gate` (deux couloirs), `route_18_gate` ; refus et recul, salut une fois, montée d'office côté Piste |
| T19 Route 16 ouest | voie basse = Piste (cases), voie haute à pied, objet caché, **maison de Vol + CS02** (Q-9) ; arbre de la Route 16 est : au J21 (§0.5) |
| T20 Routes 17 et 18 | pente, 3 paliers, 5 cachés ; Route 18 (Piste à l'ouest, poste, étang pêchable à l'est) |
| T21 Routes 13, 14, 15, poste 15 | 1F + 2F (assistant, jumelles), 21 Dresseurs, objets (CT09 pour la CT20) |
| T24 Parmanie | ville, Centre (repos), Boutique (`fuchsia_mart`), Super Canne, Salle de réunion, grand-père ; portes Arène, Safari, Gardien « À venir » ; Route 19 « À venir » ; enclos (panneaux, examen) |
| T25 (partie) | `test_save_j22` (v7, drapeaux, monture, Bon) ; contrat Safrania (`test_j22_data`) |
| Départs §2.14 | `fishing_qa`, `route_12_south_qa`, `route_15_qa`, `bike_qa`, `cycling_road_qa`, `cycling_road_nobike_qa`, `fuchsia_qa`, `j22_full_qa` (part de la Route 12 sud tant que la Route 12 nord n'existe pas) |

Outils : `tools/build_j22_maps.gd` (12 cartes, tuiles provisoires), `tools/gen_j22_data.py`
(PNJ, Dresseurs, répliques, rencontres, objets depuis les grilles), `build_painted_interiors.gd --j22`
(7 intérieurs). Tests : `test_j22_maps`, `test_j22_data`, `test_j22_story` (vraie Boot),
`test_j22_fishable`, `test_save_j22`.

Suite complète : 6 489 / 6 496, puis les 7 échecs corrigés (relance ciblée 143 / 143). Prénoms
renommés [D] (pris entre-temps par d'autres jalons) : Lou → Lison, Firmin → Ferdinand, Anatole →
Léonce, Capucine → Maëlle.

### 8.2 Reste

- **Art** : planches série 25 (vélo, pêche, Motard, Ornithologue, Loubard, frères pêcheurs,
  Kangourex, Ramoloss), fonds CB.3, cartes peintes depuis les vues validées (aujourd'hui : tuiles
  provisoires, règle 3).
- **Fusion du J21** : retirer `kanto_j22_j21.json`, `moves/j22_j21.json` et les deux fiches du
  Pokédex en double ; appliquer le contrat de §0.5 (Route 12, Route 16, arbre) ; relancer
  `build_j22_maps.gd` ; `j22_full_qa` repart de Lavanville.
- **T25 équilibrage** (simulation N30–34 sur chaque chemin) : non lancé.
- **QA téléphone 22A, 22B, 22C** (T22, T23, T26) : liste ci-dessous, pour Kevin.

### 8.3 QA téléphone (pour Kevin)

| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `fishing_qa` | parler au pêcheur ; sortir ; pêcher au quai de Carmin | Canne reçue ; PÊCHER ; Magicarpe N5 |
| 2 | `route_12_south_qa` | descendre le ponton ; Méga Canne (maison) ; pêcher au ponton | table par défaut (Tentacool, Krabby, Poissirène, Magicarpe) |
| 3 | (suite) | Routes 13 → 14 → 15 → poste 15 (2F : assistant, jumelles) → Parmanie | Dresseurs évitables sauf un par route ; textes |
| 4 | `bike_qa` | Fan Club : NON puis OUI ; Azuria : vendeur | Bon une fois, puis Bicyclette ; bouton Vélo du HUD |
| 5 | `cycling_road_nobike_qa` | aller vers la Piste dans le poste 16 | « Désolé ! La Piste Cyclable… », recul d'une case |
| 6 | `cycling_road_qa` | traverser le poste vers la Piste | salut une fois ; sortie en selle ; descente refusée sur la voie basse |
| 7 | (suite) | Route 17 sans toucher : dérive, paliers, Dresseurs en retrait ; objets cachés à vélo | confortable au doigt ; ≥ 58 fps |
| 8 | (suite) | Route 18 → poste 18 → Parmanie | à pied côté est ; étang pêchable |
| 9 | `fuchsia_qa` | Parmanie : Centre, Boutique, Salle de réunion, grand-père, Super Canne, étang ; portes Arène / Safari / Gardien / Route 19 | intérieurs, « À venir » en debug ; Poissoroy possible à la Méga Canne |
| 10 | (Route 16 ouest, voie haute) | entrer dans la maison de Vol | CS02 reçue une fois |
| 11 | partout | relancer l'appli | état gardé (v7) |
