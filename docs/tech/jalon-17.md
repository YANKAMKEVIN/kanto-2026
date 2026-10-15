# Jalon 17 — Les chemins retrouvés : Route 11, Cave Taupiqueur, Route 2 est, CS05 Flash

> Objectif jouable sur le téléphone : **Kanto commence à se reconnecter**. Depuis Carmin, la
> **Route 11** côtière (8 Dresseurs dont Arthur inévitable, trois parcours, Ronflex endormi qui
> ferme l'est), la **Cave Taupiqueur** (tunnel linéaire de 96 pas, gravats, Triopikeur rare), la
> **Route 2 est** (couloir boisé, poste de l'assistant de Chen, Pierre Lune, Super Bonbon), la
> **CS05 Flash** remise contre **10 espèces capturées**, la **barrière de FUTUR B** ouverte depuis
> l'est (raccourci vers Jadielle), la clairière de **FUTUR A** derrière un arbuste, et la
> **fondation de l'éclairage** (obscurité + halo qui suit le joueur) sur une carte de QA.
>
> Mécaniques nouvelles : **condition de dialogue « au moins N espèces capturées »**, **CS** (objet,
> compatibilités, `FieldMoves`), **cases libérées par un drapeau** (`FlagGate.blocking_cells`, §2.4), **Corde Sortie à
> deux bouches**, **voile d'obscurité** en shader `CanvasItem` (sans `Light2D`) et **mise en scène
> automatique de Flash**. Tout le reste est du contenu sur des systèmes existants.

**Pré-requis.** Dossier 20 **verrouillé** par Kevin le 2026-10-14 (H-1 à H-17, grilles, vues
générales v1, textes §16 variantes A) : c'est la **source de vérité**. Organisation imposée par
Kevin : **une session par jalon** ; J14, J15 et le futur J16 avancent en parallèle. Ce plan sépare
les tâches **(A)**, lançables maintenant depuis `origin/main`, des tâches **(B)**, qui attendent un
système précis d'un autre jalon (§1.2), avec pour chacune une façon d'avancer sans conflit.

Plan écrit sur `docs/dossier-20-j17` (base `main` à `267fcf1`). **Code lu** : `origin/main` à
**`4f0ee90`** (J11, **J12 et J13 fusionnés**, sauvegarde v6) ; `jalon-14` à `808f45e` (14C validé,
pas encore dans `main` : `FlagGate`, `rare_candy`, `ss_ticket`, `dig`, `psychic`) ; `jalon-15` à
`4c16542` (dossier 18, grilles, Pension, v7 ; **Carmin pas encore construite** : aucun
`build_vermilion_city.gd`) ; J16 : **aucun dossier**, seulement la passe d'alignement
(`origin/ccr-fa255d49-wvvacc` à `474a9d2`, G-1 à G-10, G-3 retranché : Coupe exige le Badge
Cascade) ; J18 : dossier 21 (`docs/dossier-j18` à `69771a1`, textes validés, grilles en attente).
Quand un nom n'existe que dans un plan ou une passe, c'est écrit « (plan) ».
**Chaque tâche d'architecture commence par réaligner ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/dossier-20-chemins-retrouves.md`,
`docs/design/passes/j17-v2-alignement.md` (§0 hypothèses, §4 coûts cachés), grilles
`tools/plans/route_11.txt`, `digletts_cave.txt`, `route_2_east.txt`, `route_2_east_gate.txt`,
`route_2_j17_retouches.txt`, contrôle `tools/art/plan_check_j17.py` (vert), modèle de forme
`jalon-15.md` (branche `jalon-15`) et `jalon-12.md` (`main`).

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin du dossier

| Besoin (dossier 20) | Existant sur `origin/main` (fichier) | Apporté par un autre jalon (non fusionné) | Manque |
|---|---|---|---|
| Compteur d'espèces | `Pokedex.caught_count()` (`game/pokemon/pokedex.gd:128`) ; starter compté (`boot.gd:1255`) ; relâcher / déposer ne touche pas le Pokédex | — | rien |
| Condition de dialogue | `DialogueVariant.matches(flags)` : `if` / `unless` sur des drapeaux seulement (`dialogue_variant.gd`) ; `Dialogue.pick(flags)` appelé par `DialogueRunner` (l. 134, 169) | — | condition « au moins N espèces capturées » (§2.5) |
| Jetons de texte | `DialogueTokens.KNOWN = [first_wild_species, player, rival, pokemon, levels, price]` (J15 fusionné : `CONTEXT` = Pension) ; `Boot._dialogue_token_values` (`boot.gd:1297`, fusionne `_daycare.token_values()`) ; page à jeton sans valeur **omise** | — | `{caught}`, `{caught_missing}` (§2.5) |
| Remise « une seule fois » atomique | modèle CT34 : scène `give` puis `set` (`data/cutscenes/pewter_gym.json`) ; sauvegarde écrite seulement en état stable, scène interrompue rejouée | — | rien (§2.6) |
| Objets CT | `ItemData.Category.TM` (`item_data.gd:22`), `tm_number` 1..50 (`ItemLibrary` : `TM_MIN`, `TM_MAX`), `TmTeach` (jamais consommée), onglet « CT » (`bag_screen.gd:54`) | J16 (passe) : « catégorie `hm` ou CS rangée avec les CT » | CS : champ `hm`, section CS des compatibilités (§2.7) |
| Compatibilités | `data/pokemon/tm_compatibility.json` (généré, `tms` 01..50, `species`) ; `tools/gen_tm_compatibility.py` exclut les numéros ≥ 101 de PokeAPI ; `PokemonData.can_learn_tm` | J16 (passe) : « étendre le script aux CS » | section `hms` + `hm_species` (§2.7) |
| Capacité de terrain | rien | J16 (passe) : `FieldMoves.can_cut(party, bag, flags)` lit `badge_cascade` | `FieldMoves` (§2.8) |
| Case libérée par un drapeau | **aucune** : grille statique (`map.gd:283-290`, `blocked_cells`) ; un PNJ `unless` occupe **une** case (`npc_spec.gd:168`) ; `GridWorld.set_solid(cell, solid)` sait rendre une case libre | J14 : `FlagGate` (`game/world/flag_gate.gd`) **visuel seulement**, réglé par `GameMap.apply_flag_gates` à l'arrivée et par Boot à chaque drapeau | rien : `FlagGate.blocking_cells` (J15) + `SceneRouter.arrival_flags` (§2.4, T5) |
| Grotte, Corde Sortie | `CaveLibrary` + `data/world/caves.json` (une seule sortie `escape` par grotte), `FieldItemRules.escape_target` (`boot.gd:1527`), `tools/cave_map_kit.gd`, terrain `rubble`, `RubbleBurst`, profils `cave_*`, voile précalculé `tools/cave_shade.gd`, `LightGlow` | — | `digletts_cave` dans `caves.json` ; **deux bouches** (§2.3) |
| Éclairage | `WorldLighting` (`CanvasLayer` `LAYER_WORLD_GRADE` = 6 : étalonnage en `screen_texture`, globals) ; **aucune** `Light2D` ni `CanvasModulate` ; calques : monde 0, `BattleStage` 5, étalonnage 6, HUD 10 | J18 (dossier 21 §5.2) : voile au-dessus du monde, trou radial, halo 2,5 / 7 cases, champ `dark` de `caves.json` | voile d'obscurité (§2.10) |
| Objets visibles et cachés | modèle J8 (`got_<id>`) ; objets cachés `InteractPoint.unless_flags` (`interact_point.gd:21`), `_add_hidden_item` (`tools/build_route_24.gd`) | — | rien |
| Dresseurs | `TrainerLibrary` (dossier `data/trainers/`), `moves` explicites permis (`cerulean_gym.json`), IA `random` | — | `data/trainers/route_11.json` |
| Rencontres | `data/encounters/*.json`, terrain `rubble`, `rate` + `ramp` (`mt_moon.json`) | — | `route_11.json`, `digletts_cave.json` |
| Espèces | aucune des 8 (Taupiqueur, Triopikeur, Soporifik, Hypno, Magnéti, Magnéton, Caninos, Goupix) sur aucune branche ; méthode : **types et statistiques actuels, apprentissages RB** (`kanto_mt_moon.json` : Mélofée Fée) | J15 : `kanto_vermilion.json` (modèle) | `kanto_j17.json` (§2.12) |
| Capacités | `sand_attack`, `scratch`, `growl`, `slash`, `earthquake`, `pound`, `disable`, `confusion`, `tackle`, `sonic_boom`, `thunder_shock`, `supersonic`, `thunder_wave`, `bite`, `ember`, `leer`, `tail_whip`, `quick_attack`, `screech`… ; `whirlwind` en `pending_effects: force_switch` | **J14** : `dig` (effet `charge`, invulnérable), `psychic` | `flash`, `hypnosis`, `headbutt`, `poison_gas`, `meditate`, `roar` (§2.12.2) |
| Sauvegarde | v6 (`save_system.gd:35`) | **J15 : v7** (Pension) | **rien** : pas de v8 (§2.15) |
| Carmin | — | J15 : grille `vermilion_city.txt` (bord est (63, 11..13) « ROUTE 11 — À venir », `from_route_11` réservé), **carte non construite** | raccord réel (T17) |
| Route 2 sud | `tools/build_route_2.gd` : FUTUR A `examen_arbre_dense`, barrière `ClosedGate` (34, 44) taille 1 × 2 lue **depuis l'ouest** (`Vector2i.RIGHT`), panneau `route_2_closed_sign` (33, 42) | — | report des retouches dans `route_2.txt`, raccord est (T21) |
| Coupe, arbustes | rien | J16 : CS01, arbustes définitifs (G-4), Badge Cascade exigé (G-3 retranché), textes génériques | arbuste du couloir, FUTUR A (T23, B) |

### 0.2 Écarts et trous constatés

1. **Contradiction de conception entre le dossier 20 (J17) et le dossier 21 (J18) sur Flash**, tous
   deux validés le 2026-10-14 (consolidés à 16 h 25 et 16 h 27) :
   | Sujet | Dossier 20 (H-6, H-7) | Dossier 21 (I-3, I-5, I-6) |
   |---|---|---|
   | Combat | CS05 = CT réutilisable, Flash capacité de combat (précision 70 %) | « jamais en combat », pas de capacité |
   | Déclenchement | **automatique** à l'entrée, sans menu ni bouton | « Utiliser Flash ? » OUI / NON à l'entrée, puis **menu des capacités de terrain du J16** |
   | État | aucun (rejoué à chaque entrée) | drapeau `dark_cave_lit`, effacé à la sortie |
   | Badge | aucun | Badge Roche (toujours obtenu à ce stade : sans effet pratique) |
   Le J17 suit **le dossier 20** (son mandat). La fondation (§2.10) est neutre : le voile ne sait
   rien du déclenchement ; seuls `flash` en combat (une donnée) et la mise en scène automatique
   (un nœud) dépendent du choix. **Question Q-1.** Le dossier 21 §8 (poste de l'assistant derrière
   FUTUR A, « seulement si le dossier 20 ne pose pas la source de Flash ») tombe : le dossier 20 la
   pose (Route 2 est).
2. **Roadmap divergente** : la roadmap de `docs/dossier-j18` liste « J16 S.S. Anne + rival n° 4 +
   Coupe (dossier 19) ; J17 Major Bob + Badge Foudre (dossier 20) ». Le dossier 20 verrouillé est ce
   jalon-ci (Route 11, Cave, Flash) et la passe du J16 met Major Bob au J16. À corriger à la fusion
   des branches de conception (pas une décision de game design ; noté pour la clôture).
3. **Ronflex occupe 2 × 2 cases** (66..67, 14..15) ; un PNJ n'occupe qu'**une** case. Le « PNJ
   présent `unless snorlax_route_11_awake` » du dossier se réalise donc en trois pièces
   conditionnées par le même drapeau : décor `FlagGate` (sprite et `blocking_cells` : les 4 cases), point
   d'examen `InteractPoint` 2 × 2 avec `unless_flags` [D]. Même comportement observable.
4. **Corde Sortie à deux bouches** : `caves.json` n'a qu'une sortie par grotte, et « la bouche par
   laquelle le joueur est entré » (§12, [D]) demanderait un état nouveau (sauvegarde). Défaut
   retenu (règle 4) : **la bouche de la moitié où se tient le joueur** (rangées 0..39 → Route 2 est,
   40..79 → Route 11). Sans état, juste après un rechargement, et c'est exactement le cas limite
   §13 « Corde Sortie depuis chaque moitié ».
5. **Le jeton `{pokemon}` existe déjà** (nom du compagnon, J11). T-17 « {pokemon} utilise Flash ! »
   n'est pas un dialogue : la mise en scène résout elle-même ce texte (donnée de
   `field_moves.json`) avec le nom du Pokémon qui éclaire, sans passer par `Boot._dialogue_token_values`.
6. **`{n}` et `{reste}` du §16** sont des notations : jetons de code `{caught}` et
   `{caught_missing}` (minuscules, `DialogueTokens._NAME_CHARS`) ; les textes restent mot pour mot.
   Accord : T-2 avec n = 1 donnerait « 1 espèces capturées » → variante d'accord « Ton Pokédex
   compte 1 espèce capturée. » (adaptation typographique [D], comme au J15 §0.2 n° 10). n = 0 est
   impossible (le starter est compté), test à l'appui.
7. **Textes non couverts par le §16** (règle : aucun texte inventé) — brouillons à l'**annexe A**,
   à valider en une passe (**Q-2**) : descriptions de Pokédex des 8 espèces (champ obligatoire de
   `PokedexLibrary`), notes de forme de base (Taupiqueur, Soporifik), sous-titres de zone, titre de
   l'onglet du Sac. Les données partent avec `"draft": true` en attendant.
8. **Noms des drapeaux d'objets** : le §10 propose `item_route_11_super_potion`… [D] ; le code
   nomme `got_<identifiant de grille>` (`got_mt_moon_1f_item_1`). On garde la convention du code
   (table §1.3) : défaut technique, sans effet de jeu.
9. **Dépendance réelle au J14** (pas seulement `rare_candy`) : Taupiqueur apprend **Tunnel** (`dig`)
   au Nv. 19 et Triopikeur l'a d'office ; `dig` n'existe que sur `jalon-14`. Les rencontres de la
   Cave attendent donc le J14 dans `main` (ou un repli §2.12.2). `FlagGate` (Ronflex, barrière) aussi.
10. **Coupe exige le Badge Cascade** (G-3 retranché le 2026-10-14) : l'arbuste du couloir et FUTUR A
    suivent la règle du J16 telle quelle (`can_cut` lit `badge_cascade`). Aucun effet sur le chemin
    principal du J17 (H-2) ; le cas « CS01 sans Cascade » est un cas limite de plus (§5).
11. **Carmin n'est pas encore construite** sur `jalon-15` : le raccord ouest de la Route 11 se pose
    en `coming_soon = "Carmin-sur-Mer"` jusqu'à la fusion du J15 (modèle J15 T13/T21).
12. **Les bulles « ! » des Dresseurs** et les PNJ hors du halo : le dossier 21 les veut au-dessus du
    voile. Aucun Dresseur sur une carte obscure au J17 : **passation au J18**, rien à coder ici.

### 0.3 Dépendances envers les autres jalons (vrais noms)

| Jalon | Système attendu | Nom réel / état | Utilisé par |
|---|---|---|---|
| J12 | kit de grotte, `rubble`, `cave_*`, `cave_shade.gd`, `LightGlow`, Corde Sortie, `InteractPoint.unless_flags` | **dans `main`** | rien à attendre |
| J13 | — | **dans `main`** | — |
| J14 | `FlagGate`, `GameMap.apply_flag_gates`, `rare_candy`, `dig`, `psychic` | **code sur `jalon-14`** (14C validé, clôture en cours) | Ronflex et barrière (T17, T21), Super Bonbon (T20), rencontres de la Cave (T15) |
| J15 | Carmin (`vermilion_city`, bord est, `from_route_11`), `super_potion`, sauvegarde v7 | **grille** sur `jalon-15` ; Carmin non construite ; v7 et `super_potion` codés | raccord ouest (T17), objets Super Potion (T18, T21) |
| J16 | CS01, Coupe dans le monde, arbustes définitifs, `can_cut`, textes génériques de l'arbuste, mise en scène de Coupe | **rien de codé, aucun dossier** (passe seulement) | arbuste du couloir et FUTUR A (T23) |
| J18 | voile réglé, déclenchement de Flash, bulle « ! » au-dessus du voile | dossier 21 (Q-1) | passation (T28) |

### 0.4 Réalignement sur le code (T2, 2026-10-15)

Base : `jalon-17` à `369a20e` (= `main` à `440f9b1` : **J12 à J15 fusionnés**) ; J16 lu sur
`origin/ccr-fa255d49-wvvacc` à `776ec16` (non fusionné). Les tableaux 0.1 et 0.3 restent comme
écrits ; ce qui a changé :

1. **J14 est dans `main`** : `FlagGate` + `GameMap.apply_flag_gates`, `rare_candy`, `ss_ticket`,
   `dig`, `psychic`, `teleport` (`data/pokemon/moves/moves_j14.json`, `items_j14.json`). La
   dépendance n° 9 du §0.2 est levée : 17A et 17B n'attendent plus le J14.
2. **J15 est dans `main`** : **Carmin construite** (`tools/build_vermilion_city.gd`, warp est (63,
   11..13) → `route_11` / `from_route_11_*` avec « Route 11 — À venir »), `super_potion` et
   `full_restore` (`data/items/vermilion.json`), sauvegarde **v7**, jetons `{levels}`, `{price}`.
   Le n° 11 du §0.2 tombe : le raccord ouest de la Route 11 (T17) est réalisable tout de suite
   (retirer le « À venir » côté Carmin).
3. **Le J16 a posé les CS et `FieldMoves` (contrat §1.2 : le J17 s'aligne)** :
   - CS **identiques au §2.7** (`ItemData.hm_number`, `is_hm`, `ItemLibrary` « hm » / `get_hm`,
     `PokemonData.can_learn_hm` / `hm_move`, `TmTeach`, générateur 101..105). **T2 reprend ce code
     octet pour octet** (fusion future sans conflit) ; seuls les tests sont propres au J17
     (`test_hm_j17.gd` ; le `test_hm.gd` du J16 dépend de la CS01).
   - **`FieldMoves` diffère du §2.8** : `game/world/field/field_moves.gd` (et non
     `game/systems/field_moves/`), **instance** chargée de `data/world/field_moves.json` (et non
     `data/pokemon/`), règle `{ "hm": "<id d'objet>", "badge": "<drapeau>" }`, API
     `check(move, party, bag, flags, items, data, companion) -> Result` (`state` ∈ NO_HM,
     NO_BADGE, NO_POKEMON, READY ; `pokemon_index` ; `pokemon_name`). La CS se lit **dans le Sac**
     (pas de drapeau `got_hm05` dans `requires`), pas de clé `cue`. **T3 adopte cette API** : le
     `user_index` / `can_use` / `cue_text` du §2.8 deviennent `check(&"flash", …)` ; le texte
     T-17 ira dans les données du T24 (bloqué par Q-1).
   - Le J16 ajoute aussi des variantes de dialogue `field` (« cut:ready ») et
     `DialogueRunner.field_source` : **T4** (`if_caught_at_least`) touche les mêmes fichiers
     (`dialogue.gd`, `dialogue_variant.gd`, `dialogue_runner.gd`) → ajouts courts, conflits
     attendus « garder les deux côtés ».
   - Le J16 recrée `super_potion` dans `items_j16.json` alors que le J15 l'a dans
     `vermilion.json` : doublon à résoudre **par le J16** à sa fusion (pas par le J17).
4. **Q-1 non tranché** : la CS05 est créée (T7) mais **non enseignable** (`"teachable": false`,
   §2.7 bis) ; `test_battle_flash` attend Q-1.

---

## 1. Découpage

### 1.1 Sous-jalons et validations (H-17)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **17.0** | logique pure et données sans carte : CS et `FieldMoves`, condition Pokédex et jetons, cases libérées par un drapeau, Corde Sortie à deux bouches, espèces, capacités, Pokédex, Dresseurs, rencontres, dialogues, art | aucune session téléphone (tests + captures Mac) |
| **17A** | Route 11 (rencontres, 8 Dresseurs, objets, Ronflex), Cave Taupiqueur, raccord de Carmin | téléphone |
| **17B** | Route 2 est, poste et assistant, condition Pokédex, CS05, FUTUR B ; arbuste du couloir et FUTUR A **si le J16 est fusionné** | téléphone |
| **17C** | Flash : combat, mise en scène automatique, **fondation d'éclairage** sur `qa_flash` (fps, contraste) | téléphone (S24 pour les fps) |
| **17D** | clôture : non-régression, retrait de `qa_flash`, traversées, sauvegarde / rechargement à chaque transition ; arbustes si le J16 est arrivé entre-temps | téléphone + fusion |

- **Jamais trois systèmes à la fois** : 17A = un petit système (Corde à deux bouches) + les blocs `FlagGate`
  pour Ronflex + du contenu ; 17B = condition Pokédex + CS (objet) + du contenu ; 17C = l'éclairage
  et Flash. Aucun lot ne touche la sauvegarde (§2.15) : pas de validation isolée.
- **Ce qui bloque les sessions téléphone** : 17A attend J14 + J15 dans `main` ; 17B attend J14
  (Super Bonbon) ; 17C attend 17B (CS05 dans le Sac) ; 17D attend tout, le J16 seulement pour les
  arbustes.

### 1.2 « Maintenant » (A) ou « après un autre jalon » (B)

**Règles des tâches (A)** : branche d'intégration **`jalon-17`** créée depuis `origin/main`
(`4f0ee90` ou plus récent) dans une copie dédiée (mémoire « worktree d'intégration ») ; une branche
par tâche (`j17-t<n>-<sujet>`), **jamais fusionnée dans `main` avant la fin du J17** ; `main` est
refusionné dans `jalon-17` après chaque jalon fusionné (J14, J15, J16). Fichiers **nouveaux** de
préférence ; les données lues par dossier vont dans des **fichiers nouveaux** (`species/`, `moves/`,
`items/`, `trainers/`, `encounters/`, `dialogues/`, `npcs/`, `cutscenes/`) ; ajouts aux fichiers
uniques **en fin de fichier** (`zones.json`, `caves.json`, `interiors.json`, `lighting.json`,
`data/pokedex/kanto.json`, `kanto_placeholder_areas.json`, `companions.json`,
`tools/art/manifeste.json`, `build_character_frames.gd`) — conflits attendus : « garder les deux
côtés ». `tm_compatibility.json` est **généré** : régénéré à chaque fusion, jamais fusionné à la main.

**Fichiers chauds** (touchés aussi par J14/J15/J16) : `game/boot.gd`, `game/world/map.gd`,
`game/items/item_data.gd`, `item_library.gd`, `tm_teach.gd`, `game/pokemon/pokemon_data.gd`,
`game/systems/dialogue/dialogue_variant.gd`, `dialogue_library.gd`, `dialogue_runner.gd`,
`dialogue_tokens.gd`, `game/world/caves/cave_library.gd`, `game/ui/theme/ui_tokens.gd`,
`tools/build_route_2.gd`, `tools/build_painted_interiors.gd`, `tools/debug_start/README.md`.
Ajouts **courts et groupés** (bloc commenté « J17 »), jamais de réécriture.

**Contrat avec le J16 (le premier fusionné crée, l'autre s'aligne)** : CS dans les objets (§2.7),
section CS des compatibilités, `FieldMoves` (§2.8), cases libérées par un drapeau (§2.4), mise en scène d'une capacité
de terrain (§2.11). Si le J16 arrive d'abord avec d'autres noms, la tâche J17 concernée **renomme**
ses appels et garde ses tests ; si le J17 arrive d'abord, ce plan devient le contrat du J16
(passation écrite au T28).

| Tâche | Agent | Quand | Dépendance | Comment avancer sans conflit |
|---|---|---|---|---|
| T0 Plan (ce document) | architecte | fait | — | docs |
| T1 Branche `jalon-17` + alignement | architecte | **(A)** | — | depuis `origin/main` |
| T2 CS : objet, compatibilités, `TmTeach` | architecte | **(A)**, après T1 | contrat J16 | fichiers d'objets + générateur |
| T3 `FieldMoves` + `field_moves.json` | architecte | **(A)**, après T2 | contrat J16 | fichiers nouveaux |
| T4 Condition Pokédex + jetons | architecte | **(A)**, après T1 | — | 4 fichiers de dialogue, ajouts courts |
| T5 Cases libérées par un drapeau (`FlagGate.blocking_cells`, **fait**) | architecte | **(A)**, après T1 | contrat J16 (aligné) | `scene_router.gd` + `boot.gd` (une ligne) |
| T6 Corde Sortie à deux bouches | architecte | **(A)**, après T1 | — | `cave_library.gd`, `field_item_rules.gd`, `boot.gd` (une ligne) |
| T7 Espèces, capacités, Pokédex, CS05 | architecte | **(A)**, après T2 | `dig` (J14) : repli §2.12.2 | fichiers nouveaux |
| T8 Dresseurs, rencontres, dialogues, zones + simulation | architecte | **(A)**, après T4, T7 | J14 pour la table de la Cave | fichiers nouveaux |
| T9 Fondation d'éclairage (voile, règles, données) | architecte | **(A)**, après T1 | — | `game/world/lighting/darkness_*` nouveaux |
| T10 Carte `qa_flash` + départs | constructeur-monde | **(A)**, après T9 | — | carte provisoire, retirée au T28 |
| T11 Kit d'assets série « 19 » (fiche, prompts) | architecte | **(A)** | vues générales (validées) | fichiers nouveaux |
| T12 Génération Codex → planche de contact | constructeur-monde (Mac) | **(A)**, après T11 | — | `build/art/` |
| T13 Dos de combat (méthode Colab) | constructeur-monde (Mac) | **(A)** | — | images seules |
| T14 Intégration de l'art | constructeur-monde (Mac) | **(A)**, après T12, T13 | — | entrées en fin de fichier |
| T15 Carte de la Cave Taupiqueur | constructeur-monde | **(A)** (outil, scène), après T6, T14 | rencontres : J14 | `build_digletts_cave.gd` nouveau |
| T16 Carte de la Route 11 | constructeur-monde | **(A)**, après T5, T14 | — | `build_route_11.gd` nouveau ; bord ouest `coming_soon` |
| T17 Vie de la Route 11 et raccord de Carmin | constructeur-monde | **(A)** pour la vie ; **(B)** pour le raccord | J14 (`FlagGate`), **J15** (Carmin construite) | Ronflex, Dresseurs, objets, panneaux |
| T18 Session 17A | qa-mobile | **(B)** | J14 + J15 dans `main` | — |
| T19 Route 2 est + poste + assistant | constructeur-monde | **(A)**, après T4, T14 | — | `build_route_2_east.gd` nouveau, pièce du poste |
| T20 Objets du couloir | constructeur-monde | **(B)** | J14 (`rare_candy`) | données prêtes au T8 |
| T21 Retouches de la Route 2 sud (FUTUR B, sentier, clairière sans arbuste) | constructeur-monde | **(A)**, après T5 | J14 (`FlagGate`) | `route_2.txt` + `build_route_2.gd` (bloc) |
| T22 Session 17B | qa-mobile | **(B)** | J14 dans `main` ; T19–T21 | — |
| T23 Arbustes (couloir, FUTUR A) | constructeur-monde | **(B)** | **J16** dans `main` | §2.13 |
| T24 Mise en scène de Flash (directeur) | architecte | **(A)**, après T3, T9 | — | `flash_director.gd` nouveau + `boot.gd` (bloc) |
| T25 Rendu : bandeau, éclair, réglage du voile, mesure du contraste | ui-mobile | **(A)**, après T10, T24 | — | shader, outil de mesure |
| T26 Session 17C | qa-mobile | après T22, T24, T25 | — | S24 |
| T27 Session 17D (traversées, sauvegarde) | qa-mobile | après tout | — | — |
| T28 Clôture | architecte | fin | — | — |

**Parallélisme maintenant** : T1 → (T2 → T3 → T7) ∥ T4 ∥ T5 ∥ T6 ∥ T9 → T10 ; T11 → T12 ∥ T13 →
T14 ; puis T8 (après T4 et T7) ; cartes T15, T16, T19, T21 dès T14 et leurs fondations. Les (B)
partent dès que leur jalon est dans `main` (puis `main` fusionné dans `jalon-17`).

### 1.3 Grilles : lecture et normalisations (aucune géométrie modifiée)

Les grilles font foi (règle 10) ; `plan_check_j17.py` est vert. Normalisations :

1. **Identifiants de carte** : `route_11`, `digletts_cave`, `route_2_east`, `route_2_east_gate`
   (intérieur 15 × 10). Zones : `route_11`, `digletts_cave` (nouvelles), `route_2` (+
   `route_2_east`, `route_2_east_gate`).
2. **Points d'apparition** (un par case quand la grille en couvre plusieurs : `_w / _c / _e`,
   `_w / _e` ; `_n / _s` pour une colonne) : Route 11 `from_vermilion_n|c|s` (0, 11..13) tournés →,
   `from_cave_w|e` (15..16, 8) ↓ ; Cave `from_route_11_w|e` (15..16, 78) ↑, `from_route_2_east_w|e`
   (16..17, 1) ↓ ; Route 2 est `from_cave_w|e` (6..7, 4) ↓, `from_gate` (11, 12) ↓,
   `from_route_2_n|s` (0, 43..44) → ; poste `entrance` (7, 8) ↑ ; Route 2 sud `from_route_2_east_n|s`
   (41, 43..44) ←. Carmin : `from_route_11_n|c|s` (63, 11..13) ← (réservé par le J15).
3. **Warps** : bords en `PUSH` (Carmin ↔ Route 11 rangées identiques ; Route 2 est (0, 43..44) ↔
   Route 2 sud (41, 43..44)) ; bouches de Cave en `STEP_ON` ↑ côté route, `PUSH` ↓ / ↑ côté Cave
   (grille) ; porte du poste `STEP_ON` ↑, sortie `PUSH` ↓.
4. **Drapeaux** (convention du code, §0.2 n° 8) :

   | Grille | Objet | Drapeau |
   |---|---|---|
   | `route_11_item_1` (40, 13) | Super Potion | `got_route_11_item_1` |
   | `route_11_item_2` (47, 25) | Réveil | `got_route_11_item_2` |
   | `route_11_hidden_1` (62, 9), indice caillou | Poké Ball | `got_route_11_hidden_1` |
   | `cave_item_1` (2, 44) | Corde Sortie | `got_digletts_cave_item_1` |
   | `route_2_east_item_1` (12, 26) | Pierre Lune | `got_route_2_east_item_1` |
   | `route_2_east_item_2` (3, 33) | Super Bonbon | `got_route_2_east_item_2` |
   | `route_2_item_5` (1, 17) | Super Potion | `got_route_2_item_5` |

   Plus : `route_11_visited` (titre d'arrivée, méthode existante), `snorlax_route_11_awake` (jamais
   posé), `snorlax_route_11_seen` [D] (T-6 puis T-7), `hm05_assistant_met` [D] (T-1 puis T-2),
   `got_hm05`, `route_2_east_gate_open`, `cut_route_2_east_bush`, `cut_route_2_futur_a`,
   `beaten_<id>` × 8.
5. **Dresseurs** : identifiants de la grille (`route_11_youngster_arthur`, `…_lucas`, `…_louis`,
   `…_raphael`, `route_11_gambler_marcel`, `…_roger`, `route_11_engineer_bruno`, `…_victor`),
   orientations et portées de la grille (D1 5, D2 4, autres 3).

### 1.4 Kit d'assets : série « 19 » provisoire

Numéro **19** [D] (14 = J12, 15 = J13, 16 = J14, 17 = J15, **18 réservé au J16**) ; « le second
fusionné renumérote », revérifié au push. Méthode des J12–J15 : le plus petit kit modulaire qui
donne la sensation des vues générales validées ; lumière neutre (NE) pour objets et personnages ;
la grille fait foi ; les « ne pas reproduire » du dossier (goulet d'Arthur, Gamin Louis peint près
de la Cave, canyon vu du ciel, clairières trop larges) sont respectés.

| Groupe | Réutilisé | Nouveau (série 19) |
|---|---|---|
| Route 11 | herbe, chemin, `DenseForest`, hautes herbes, rochers, buissons, clôtures basses, panneaux, eau de mer et rivage (J15), `object/poke_ball_ground`, indice « caillou » | **digue** (texture de planches ou de pierre, bords), **talus rocheux de la bouche** (façade de bouche de Cave, sud), **affleurements** du goulet |
| Cave Taupiqueur | kit de grotte J12 (`ground_masse_roche_01`, gravats, rochers isolés), profil dérivé de `cave_1f` | textures de **roche claire et sableuse** (sol, paroi), **bouches** (intérieur, nord et sud) |
| Route 2 est | forêt, chemin, prairie, rochers ; façade d'un **poste de la forêt** (même famille) ; éboulis de la Route 2 nord vus de dos | **paroi et bouche nord** (extérieur), **barrière ouverte** (FUTUR B, état ouvert) |
| Route 2 sud | fond peint existant | **retouche** : clairière FUTUR A (trouée de canopée), sentier `b` praticable, barrière ouverte |
| Intérieur du poste | coque `int_maison_argenta_coque` ou `int_poste_foret_coque`, bibliothèque, bureau, table, plantes | étagère « lampes de grotte et bocaux » (rappel de Flash) |
| Personnages | scientifique existant (si convenable pour l'assistant), habitants | **Joueur** (Gambler), **Ingénieur** (Engineer), **assistant** (si le scientifique ne convient pas), **visiteur** — marche + attente |
| Pokémon (monde) | Rattata, Piafabec, Abo (planches) | **Taupiqueur** « sort du sol » (2 poses : tête sortie, caché), **Soporifik** (repos + marche 4 directions), **Ronflex endormi** (≈ 2 × 2 cases, 1 pose + respiration lente) |
| Combat | artworks officiels (faces) | **dos** Taupiqueur, Triopikeur, Soporifik, Hypno (Colab, T13) ; décors **`route_11_coast`** (prairie côtière) et **`digletts_cave_rock`** (roche claire) (chaîne CB.3) |
| Sac | — | icône `hm05` (variante de l'icône CT) |
| Arbuste | **celui du J16** | — (si le J17 passe avant : un arbuste provisoire, remplacé par celui du J16) |

---

## 2. Conception technique

### 2.1 Cartes et raccords (T15, T16, T19, T21)

| Carte | Taille | Catégorie | Lumière | `display_name` / zone |
|---|---|---|---|---|
| `route_11` | 76 × 36 | extérieur | `golden_hour` | « Route 11 » / `route_11` |
| `digletts_cave` | 34 × 80 | **grotte** (`caves.json`, `interior = false`), **pas obscure** | `cave_sand` (nouveau, dérivé de `cave_1f`, plus clair) [D] | « Cave Taupiqueur » / `digletts_cave` |
| `route_2_east` | 16 × 48 | extérieur | `forest` [D] | « Route 2 » / `route_2` (titre de la Route 2) |
| `route_2_east_gate` | 15 × 10 | intérieur | `interior_warm` | « Route 2 » / `route_2` |

- **Outils** : `tools/build_route_11.gd` (kit `pewter_map_kit.gd` : sol logique, `DenseForest`,
  hautes herbes, panneaux ; mer et rivage du J15 ; digue `q` = sol praticable texturé, clôtures `c`
  bloquées), `tools/build_digletts_cave.gd` (kit `cave_map_kit.gd`, `PaintedGround` à textures
  réglables, gravats `g` = tuiles `RUBBLE`, voile précalculé `cave_shade.gd` facultatif),
  `tools/build_route_2_east.gd` (kit forestier), pièce du poste dans `build_painted_interiors.gd`
  (groupe `ROUTE_2_EAST`, option `--route2est`, définition en fin de fichier). Graines fixes, deux
  passes masque / scène (méthode J10).
- **Préchargement** : `route_11` ↔ `vermilion_city`, `digletts_cave` ; `digletts_cave` ↔ `route_11`,
  `route_2_east` ; `route_2_east` ↔ `digletts_cave`, `route_2`.
- **Avant la fusion du J15** : bord ouest de la Route 11 en `coming_soon = "Carmin-sur-Mer"` (build
  de développement). **Après** : warp `PUSH ←` → `vermilion_city` / `from_route_11_*`, et côté
  Carmin une seule modification de l'outil du J15 : le warp est (63, 11..13) perd `coming_soon` et
  vise `route_11` / `from_vermilion_*` (T17).
- **Bord est de la Route 11** (75, 14..15) : praticable, inatteignable, **aucun warp** au J17.
- **Rest points** : aucun nouveau (aucun Centre) ; défaite → dernier Centre visité (règle existante).

### 2.2 Le poste de l'assistant (T19)

- `route_2_east_gate` : enveloppe de maison d'Argenta (15 × 10, grille `route_2_east_gate.txt`) ;
  bibliothèque, bureau et chaise, classeur, étagère (lampes de grotte), table, deux plantes.
- **Assistant** (8, 5) tourné ↓, parlé de face par (8, 6) : dialogue `route_2_east_assistant` (§2.6).
- **Visiteur** (11, 7) tourné ←, parlé par (11, 6) : `route_2_east_visitor` (T-5).
- Compagnon caché (intérieur, règle J11). `interiors.json` : `route_2_east_gate`.

### 2.3 La Cave : catégorie, lumière, Corde Sortie à deux bouches (T6, T15)

- **Catégorie** : `caves.json`, entrée `digletts_cave` (`maps: ["digletts_cave"]`) ; compagnon
  visible, phrase « grotte » (`companions.json`, `contexts`), titre « CAVE TAUPIQUEUR » à l'entrée.
- **Lumière** : roche claire et sableuse, « lumière naturelle lisible » ; profil `cave_sand` en fin
  de `lighting.json` [D] ; seuils Mac du J12 (`luminance_grotte.py` : sol ≥ 0,22, sol / paroi ≥ 2,0)
  ; **pas de voile d'obscurité** (§2.10 : seulement les grottes `dark`).
- **Corde Sortie** (§0.2 n° 4) : `caves.json` accepte, à la place de `escape`, une liste
  `escapes` dont chaque sortie porte la plage de rangées qu'elle sert :
  ```json
  "digletts_cave": {
    "maps": ["digletts_cave"],
    "escapes": [
      { "rows": [0, 39],  "map": "route_2_east", "spawn": "from_cave_w",    "facing": "down" },
      { "rows": [40, 79], "map": "route_11",     "spawn": "from_cave_w",    "facing": "down" }
    ]
  }
  ```
  `CaveLibrary.escape_target(map_id, cell := Vector2i(-1, -1)) -> CaveExit` : avec `escape`
  (Mont Sélénite), inchangé ; avec `escapes`, la sortie dont la plage contient `cell.y` ; validation
  au chargement : plages disjointes qui couvrent toute la hauteur de la carte (vérifié par le test
  de la vraie scène), `escape` et `escapes` exclusifs. `FieldItemRules.escape_target(map, caves,
  cell)` et l'appel de `boot.gd:1527` passent la case du joueur. Tests : `test_cave_library`
  (plages, exclusivité, erreurs), `test_escape_rope` (deux moitiés, rangée frontière 39/40).
- **Réalignement T6 (2026-10-15)** — fait ainsi, écarts au texte ci-dessus :
  - l'appel est à `boot.gd:1634` (`_on_field_item_requested`), avec `_player.get_cell()` ;
  - `CaveExit.first_row` / `last_row` (−1 = sortie unique) et `covers_row(row)` ;
    `CaveLibrary.escape_target(map_id, cell := NO_CELL)` : sortie unique → la case est ignorée
    (Mont Sélénite inchangé, tests existants intacts) ; plusieurs bouches → la plage de `cell.y`,
    **null** sans case ou hors de toute plage (aucune bouche devinée). `get_exits(cave)` liste
    toutes les sorties.
  - Validation au chargement : `escape` / `escapes` exclusifs, liste non vide, `rows` =
    `[première, dernière]` entiers ≥ 0 dans l'ordre, plages **disjointes**, clés inconnues
    refusées, aucune sortie vers une carte de la grotte. La **couverture** de toute la hauteur
    se vérifie avec la vraie scène : `test_map_catalog.test_cave_mouth_ranges_cover_every_row`
    (passe tant qu'il n'y a pas de grotte à deux bouches ; en attente tant que la carte manque).
  - `test_map_catalog.test_cave_escape_targets_exist_with_their_spawn` parcourt désormais
    **toutes** les sorties (`get_exits`) au lieu de la seule sortie de la première carte.
  - `test_escape_rope` : deux tests dans le vrai Boot avec une **grotte de test** ajoutée sur la
    Route 3 (rangées 13 et 27 → deux points d'apparition d'Argenta), car la Cave n'existe pas
    encore ; la frontière 39/40 est testée en pur (`test_cave_library`,
    `test_field_item_rules`). `caves.json` **non modifié** : l'entrée `digletts_cave` vient avec
    la carte (T15).
- **Rencontres** : gravats seulement (`data/encounters/digletts_cave.json`, terrain `rubble`, `rate`
  25, `ramp` 15 → 20 comme le Mont Sélénite) ; intro éboulis existante.
- **Taupiqueur d'ambiance** : PNJ `shy = hide` (réaction existante, `ambient_watcher.gd:56`), sprite
  « sort du sol » à deux poses.

### 2.4 Cases libérées par un drapeau : `FlagGate.blocking_cells` ; Ronflex (T5, T17)

> **Réaligné au T5 (2026-10-15)** : la classe `FlagBlock` prévue ici **n'est pas créée**. `main`
> contient déjà le mécanisme équivalent, posé par le J15 (jeune arbre de l'Arène de Carmin) et
> **adopté par le J16** pour ses arbustes (`ccr-fa255d49-wvvacc`, `ed7f5214`) : « le premier
> fusionné crée, l'autre s'aligne ». Deux mécanismes pour la même chose seraient un piège.

**Mécanisme** `game/world/flag_gate.gd` — `FlagGate` (`Node2D`, J14 ; `blocking_cells` J15) :

```gdscript
@export var if_flags: Array[StringName] = []       # tous levés pour afficher
@export var unless_flags: Array[StringName] = []   # aucun levé pour afficher
@export var blocking_cells: Array[Vector2i] = []   # cases OCCUPÉES tant que le décor est affiché
func is_open(flags: StoryFlags) -> bool            # pur ; null = nouvelle partie
func apply(flags: StoryFlags) -> void              # visible = is_open(flags)
func apply_to_grid(grid: GridWorld) -> void        # occupe (affiché) / libère (caché)
```

- **Occupation, pas solidité** : les cases sont *occupées* par le décor (`GridWorld.occupy`), comme
  la case d'un PNJ ; une case prise par un autre occupant n'est jamais volée. Elles doivent donc
  être **praticables** dans la grille (`Ground`) : pas de solide de tuile sous un bloc.
- `GameMap.apply_flag_gates(flags)` règle visibilité **et** cases de toutes les `FlagGate` de la
  carte ; appelé par `refresh_npcs` à l'arrivée et par Boot `_on_flag_changed` à chaque drapeau
  (libération pendant la visite, sans changer de carte). `_build_grid` les réinscrit à chaque
  reconstruction (enfants directs de `Entities` ou `GroundDecals`).
- **Ajout du T5** : `SceneRouter.arrival_flags: Callable` (`func() -> StoryFlags`, branché par Boot
  sur `GameState.flags`, remis à vide par `setup`) : les `FlagGate` de la carte sont réglées
  **avant** de placer le joueur (`start`, `start_at`, `_swap_map`). Avant, une `FlagGate` occupait
  ses cases avec son `visible` par défaut jusqu'à `map_changed` : une reprise de sauvegarde sur une
  case libérée (arbuste coupé, Ronflex réveillé) décalait le joueur d'une case.
- **Un bloc = une `FlagGate` `unless <drapeau>`** dont les enfants sont le visuel et
  `blocking_cells` les cases (Ronflex : 4 cases ; barrière : 2). Un visuel « ouvert » éventuel est
  une seconde `FlagGate` `if <drapeau>` **sans** `blocking_cells`.
- **Aucune sauvegarde** : l'état se déduit des drapeaux.
- **Tests** : `tests/unit/test_flag_gate.gd` (pur, + bloc 2 × 2 avec `null`),
  `tests/integration/test_flag_gate_blocking_map.gd` (couloir fermé par un bloc 2 × 2 : fermé sans
  drapeau, libéré pendant la visite, après rechargement, reprise de sauvegarde sur une case libérée
  sans décalage, `find_reachable` avant / après, crochet réel de Boot).
- **Ronflex** (§0.2 n° 3) : `FlagGate` « Ronflex endormi » (`unless snorlax_route_11_awake`,
  sprite ≈ 2 × 2, `blocking_cells` (66..67, 14..15)) + `InteractPoint` EXAMINER 2 × 2,
  `unless_flags = [snorlax_route_11_awake]`, dialogue `route_11_snorlax` (variantes : `unless
  snorlax_route_11_seen` → T-6 + `set snorlax_route_11_seen` ; sinon T-7). Aucune donnée d'espèce,
  aucune entrée de Pokédex (H-10).
- **Contrat J16** : un arbuste = `FlagGate` `unless cut_<id>` à `blocking_cells` + point
  « arbuste » du J16 (`FieldMoves`, §2.13), exactement comme `GymTree` de Carmin
  (`tools/build_vermilion_city.gd`).

### 2.5 Condition « au moins N espèces capturées » et jetons (T4)

- **Donnée** : deux clés de variante dans `data/dialogues/` : `"if_caught_at_least": 10` et
  `"unless_caught_at_least": 10` (entier ≥ 1) ; `DialogueLibrary._VARIANT_KEYS` += ces deux clés,
  validation (entier, ≥ 1).
- **Logique pure** : `DialogueVariant.caught_at_least: int = 0` (0 = sans condition),
  `caught_below: int = 0` ; `matches(flags, caught := 0)` ajoute `caught >= caught_at_least` et
  (`caught_below == 0` ou `caught < caught_below`). `Dialogue.pick(flags, caught := 0)`.
  **Pas** d'extension aux scènes (`CutsceneVariant`) : aucun besoin au J17.
- **Branchement** : `DialogueRunner.caught_count: Callable` (comme `token_values`), lu au début du
  dialogue ; Boot le pose (`GameState.pokedex.caught_count()`). Sans `Callable` : 0.
- **Jetons** : `DialogueTokens.KNOWN += caught, caught_missing` ; valeurs ajoutées par
  `Boot._dialogue_token_values` : `caught` = `str(n)`, `caught_missing` = `str(max(10 - n, 0))`
  **seulement si n < 10** (sinon vide : une page « Encore {caught_missing} » serait omise). Le seuil
  10 vient de la donnée de l'assistant : `caught_missing` est calculé contre la constante
  `DialogueTokens.CAUGHT_GOAL` [D] = 10 ; si un autre seuil apparaît un jour, on passera par la
  donnée (pas d'abstraction avant).
- **Tests** `test_dialogue_variant_caught` (seuil exact, 9 / 10 / 11, combinaison avec drapeaux,
  sans `Callable`), `test_dialogue_library` (clés, valeurs refusées), `test_dialogue_tokens`
  (jetons connus, omis à n ≥ 10), `test_assistant_dialogue` (variantes T-1/T-2/T-3/T-4 selon n et
  drapeaux, accord n = 1).
- **Réalignement T4 (2026-10-15, code de `jalon-17` à `369a20e`)** — écarts au texte ci-dessus :
  - `Dialogue.pick` a déjà un 2e paramètre `rng` (J14, « one_in ») : signature réelle
    `pick(flags, rng := null, caught := 0)` ; le compte est vérifié **avant** le tirage.
    `DialogueVariant.matches_caught(caught)` isole la règle ; `matches(null, n)` applique aussi
    le compte.
  - `DialogueRunner.caught_count` est lu à **chaque choix de variante** (`play` et
    `has_auto_variant`), pas seulement au début du dialogue.
  - Les jetons ne passent pas par `values_for` (signature inchangée) : `DialogueTokens.caught_values(n)`
    (pur) est fusionné par `Boot._dialogue_token_values` ; ni l'un ni l'autre n'est un jeton de
    contexte (refusés dans une question de choix).
  - Validation en plus : `if_caught_at_least` ≥ `unless_caught_at_least` sur la même variante est
    refusé (variante qui ne s'appliquerait jamais).
  - Tests réels : `test_dialogue_variant_caught` (lecture, refus, seuil 9 / 10 / 11, drapeaux, table
    de l'assistant §2.6 **en mémoire** avec l'accord n = 1, jetons omis à n ≥ 10),
    `test_dialogue_tokens` (`KNOWN`), `test_dialogue_runner` (compte relu, sans source = 0),
    `test_boot_caught_count` (branchement, évolution comptée). `test_assistant_dialogue` sur les
    **vraies** données reste au T8 (le fichier `route_2_east.json` n'existe pas encore).

### 2.6 L'assistant et la remise de la CS05 (T8, T19)

Dialogue `route_2_east_assistant` (`data/dialogues/route_2_east.json`), variantes dans l'ordre :

| # | Condition | Pages | Fin |
|---|---|---|---|
| 1 | `if got_hm05` | T-4 | — |
| 2 | `if_caught_at_least 10` | T-3 (3 premières bulles) | scène `route_2_east_give_hm05` |
| 3 | `unless hm05_assistant_met`, `unless_caught_at_least 10` | T-1 | `set hm05_assistant_met` |
| 4 | `unless_caught_at_least 2` | « Ton Pokédex compte 1 espèce capturée. » / « Encore {caught_missing}, et c'est à toi. » (accord, §0.2 n° 6) | — |
| 5 | (défaut) | T-2 | — |

Scène `route_2_east_give_hm05` (modèle CT34) : `dialogue route_2_east_assistant_hm05_system`
(narration « {player} reçoit la CS05 — Flash ! ») → `give hm05` → `dialogue
route_2_east_assistant_hm05_use` (T-3, deux dernières bulles) → `set got_hm05`. **Atomicité** :
objet et drapeau changent dans la même scène ; la sauvegarde n'est écrite qu'en état stable ; une
scène interrompue se rejoue (comportement de `boot.gd`, passe J16 §2 n° 11) → ni perte ni double.
Tests `test_assistant_hm05_flow` (intégration : vraie pièce ou carte de test ; n = 9 → T-2 ; capture
de la 10e espèce par évolution (`record_evolved`) → remise ; relâcher / déposer après → toujours
remise ; deux visites → une seule CS05 ; sauvegarde relue pendant la scène = état d'avant).

### 2.7 Les CS dans les données (T2) — interface partagée avec le J16

- **Objet** : catégorie **`tm`** (onglet existant, renommé « CT et CS » [D, annexe A]) + champ **`hm`**
  (numéro 1..5) **à la place de** `tm` :
  ```json
  "hm05": { "name": "CS05 — Flash", "plural": "CS05 — Flash", "feminine": true,
            "category": "tm", "hm": 5, "teaches": "flash", "description": "<T-15>" }
  ```
  `ItemData.hm_number: int = 0`, `is_hm() -> bool` ; `is_tm()` reste vrai (enseignement, jamais
  consommée, jamais vendue ni jetée : règles des CT). `ItemLibrary` : une CT a **exactement un** de
  `tm` (1..50) ou `hm` (1..5), unicité par espace de numéros ; `get_hm(number)`. Tri du Sac : CS
  après les CT [D]. Fichier `data/items/j17.json`.
- **Compatibilités** : `tools/gen_tm_compatibility.py` lit aussi les machines **101..105** du
  groupe `red-blue` (les CS de PokeAPI) et écrit deux clés de plus : `"hms": {"01": "cut", …,
  "05": "flash"}` et `"hm_species": {espèce: [numéros de CS]}` (`tms` / `species` **inchangés** ;
  assertion : 5 CS). `PokemonData` accepte ces clés (facultatives), `can_learn_hm(species, n)`,
  `hm_move(n)`.
- **`TmTeach.check`** : `data.can_learn_hm(…)` si `item.is_hm()`, sinon `can_learn_tm` (une ligne).
  Le reste du déroulé (liste COMPATIBLE / DÉJÀ CONNUE / INCOMPATIBLE, oublier une capacité) est
  celui des CT.
- **Tests** : `test_item_library` (CS valide, `tm` + `hm` refusé, `hm` 6 refusé, prix refusé),
  `test_pokemon_data` (`can_learn_hm`, clés facultatives), `test_tm_teach` (CS05 sur Pikachu
  compatible, Rattata incompatible, déjà connue), `test_tm_compatibility_file` (5 CS ;
  `flash` = 05 ; Soporifik, Pikachu, Mélofée compatibles CS05 ; régénération identique).
- **Si le J16 arrive d'abord** avec une catégorie `hm` à part : la CS05 la rejoint, `TmTeach`
  suit, le test garde ses cas.

**§2.7 bis — CS05 non enseignable tant que Q-1 n'est pas tranché (T7, TODO(Q-1)).** Clé
facultative `"teachable": false` (CT et CS seulement) → `ItemData.teachable` : `contexts()` vide
(pas de bouton APPRENDRE, pas de note « hors combat »), `TmTeach.check` → INCOMPATIBLE. La
capacité `flash`, l'objet `hm05` et les compatibilités existent. Q-1 → dossier 20 : retirer la clé
de `data/items/j17.json`, inverser `test_hm05_is_not_teachable_until_q1`, écrire
`test_battle_flash`. Q-1 → dossier 21 : garder la clé (CS de terrain seulement) et retirer `flash`
des capacités. Le texte T-15 (« Peut aussi apprendre Flash pour le combat ») suit la décision.

### 2.8 `FieldMoves` (T3)

`game/systems/field_moves/field_moves.gd` — `FieldMoves` (`RefCounted`, statique, pur) +
`data/pokemon/field_moves.json` :

```json
{ "field_moves": {
    "flash": { "hm": 5, "requires": ["got_hm05"], "cue": "{pokemon} utilise Flash !" } } }
```

- `FieldMoves.user_index(move_id, party, flags, data, config, companion_uid := "") -> int` : −1 si
  un drapeau de `requires` manque ; sinon le **compagnon** s'il est compatible, sinon le **premier
  compatible de l'équipe**, K.O. compris [D] (aucun blocage possible ; RB permet les CS d'un Pokémon
  K.O.). `can_use(…) -> bool`. `cue_text(move_id, pokemon_name) -> String` (texte de la donnée,
  jeton `{pokemon}` résolu par `DialogueTokens.resolve`).
- Le J16 ajoutera `"cut": { "hm": 1, "requires": ["got_hm01", "badge_cascade"], … }` ; `can_cut` du
  J16 devient `can_use(&"cut", …)` (ou l'inverse si le J16 passe d'abord).
- **Tests** `test_field_moves` : sans CS05 → −1 ; CS05 sans compatible → −1 (§13 : « rien ne se
  passe ») ; compagnon compatible prioritaire ; K.O. accepté ; équipe vide ; espèce inconnue ;
  drapeau requis manquant ; texte avec nom.

### 2.9 Flash en combat (T7)

`data/pokemon/moves/j17.json` : `"flash"` « Flash », Normal, statut, précision **70**, PP 20,
`effects: [{ "kind": "stat_stage", "stat": "acc", "stages": -1, "target": "foe" }]`, description
T-16. Aucune ligne de moteur (même effet que Jet de Sable). Apprentissage : la CS05 via `TmTeach`
(§2.7), oubliable normalement. Tests : `test_pokemon_data` (capacité), `test_battle_flash`
(précision −1 de l'adversaire, ratage possible : RNG scripté).

### 2.10 Fondation de l'éclairage : le voile d'obscurité (T9, T25)

**Approche retenue : un calque d'obscurité plein écran en shader `CanvasItem`, percé d'un trou
radial doux qui suit le joueur.** Pas de `Light2D`, pas de `CanvasModulate`, pas de lecture de
l'écran.

| Pièce | Fichier | Rôle |
|---|---|---|
| `DarknessConfig` (`RefCounted`) | `game/world/lighting/darkness_config.gd` ← `data/world/darkness.json` | couleur du voile, opacité hors halo, rayons (cases) **sans Flash** 2,5 / fondu 4 et **avec Flash** 7 / 9 (valeurs du dossier 21 I-7, [D]), durées (éclair 0,3 s, ouverture 0,6 s, mise en scène ≈ 1,5 s), décalage du centre (poitrine du héros, −0,6 case) |
| `DarknessRules` (statique, pur) | `game/world/lighting/darkness_rules.gd` | `state_for(map_id, caves, flash_ready) -> State {NONE, DARK, LIT}` ; `should_cue(from_map, to_map, caves, flash_ready, restoring) -> bool` (entrée dans une grotte `dark` depuis une carte **hors de cette grotte**, jamais au chargement d'une partie) ; `radii(state, config) -> Vector2` (cases) |
| `DarknessVeil` (`CanvasLayer`) | `game/world/lighting/darkness_veil.gd` + `shaders/darkness_veil.gdshader` | calque `UiTokens.LAYER_WORLD_VEIL = 4` [D] : au-dessus du monde (0), sous `BattleStage` (5), l'étalonnage (6), le HUD (10), les menus et dialogues ; un `ColorRect` plein écran ; `set_state(state, animated)`, `follow(player)` ; caché (et `set_process(false)`) hors carte obscure |
| `caves.json` | champ `"dark": true` par grotte (dossier 21 §5.2 [D]) | seule source de « carte obscure » ; `CaveLibrary.is_dark(map_id)` |

**Shader** (sans texture, sans `screen_texture`) :

```glsl
shader_type canvas_item;
uniform vec4 veil_color;          // noir bleuté, alpha = opacité hors halo (jamais 1,0)
uniform vec2 center_n;            // centre du trou, en unités « hauteur d'écran » (0..~2,2)
uniform float inner_n;            // rayon net, mêmes unités
uniform float outer_n;            // fin du fondu
uniform float aspect;             // largeur / hauteur du rectangle
void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y);
	float a = veil_color.a * smoothstep(inner_n, outer_n, distance(p, center_n));
	COLOR = vec4(veil_color.rgb, a);
}
```

- **Unités normalisées** (divisées par la hauteur du rectangle) : les distances restent < 3, sans
  risque de dépassement en précision moyenne (`mediump`) des GPU mobiles, contrairement à des
  pixels au carré (2 340² dépasse 65 504). Un léger **tramage** (bruit de 1/255) contre les bandes
  du dégradé sombre [D] si la capture en montre.
- **Position** : chaque image où le voile est visible, `player.get_global_transform_with_canvas()
  .origin` (même repère que le calque, étirement `canvas_items` / `expand` compris) + décalage → 
  `center_n` ; le paramètre n'est poussé **que s'il change** (pas d'allocation dans `_process`).
  La caméra centre le joueur sauf aux bords (et `CameraFraming` centre les petites cartes) : le
  trou suit le joueur, pas l'écran.
- **Ouverture** : un `Tween` sur `inner_n` / `outer_n` (rayon « sombre » → rayon « Flash ») ;
  « Réduire les animations » : ouverture instantanée [D] (et pas de respiration, J18).
- **Ce qui reste au-dessus du voile** : le joueur l'est **par construction** (centre du trou,
  opacité 0) ; le HUD, les dialogues et le menu sont sur des calques supérieurs. Les PNJ, le
  compagnon (adjacent : dans le halo net) et les décors sont dessous. Halos fixes (`LightGlow`) qui
  percent le voile et bulle « ! » : **J18** (extension : tableau de positions de lampes en uniforme).
- **Coût** : un quadrilatère plein écran alpha, quelques opérations par pixel, sans lecture de
  texture : négligeable devant l'étalonnage existant (qui, lui, copie l'écran).

**Alternatives écartées** : `CanvasModulate` + `PointLight2D` (chaque lumière ajoute une passe sur
tous les objets éclairés ; les shaders du monde — `world_object`, `ground_blend`, `forest_floor` —
devraient gérer `light()` ; risque de casser le rendu validé ; coût mobile imprévisible) ; masque
dans un `SubViewport` (mémoire, une texture de plus) ; voile précalculé du J12 (ne suit pas le
joueur).

**Risques** et parades : décalage du trou avec l'étirement `expand` ou la caméra limitée (captures
Mac 2340 × 1080 **et** 1170 × 540, joueur au centre et au bord de la carte) ; précision du shader
sur Mali / Adreno (unités normalisées, essai S21 et S24) ; bandes (tramage) ; « pop » au
changement de carte (état posé **pendant l'écran noir** du fondu, avant l'arrivée) ; voile visible
pendant une transition de combat (caché par `BattleStage`, vérifié en capture) ; empilement avec le
voile précalculé `cave_shade` (lisibilité jugée sur `qa_flash` qui l'utilise).

**Mesures** (critères H-8) : **fps inchangés** sur S24 (`qa_flash`, voile visible contre voile
désactivé par départ : écart ≤ 1 fps, moyenne ≥ 58, creux ≥ 50) ; **contraste du héros ≥ 3,0**
(WCAG, héros contre le sol de la couronne autour de lui) dans le halo, avec et sans Flash, mesuré
par `tools/art/luminance_grotte.py --halo` (option nouvelle, T25) sur les captures de
`tools/capture_flash.gd` ; hors halo : sol ≥ 0,10 (seuil du dossier 21, **informatif** au J17) ;
mise en scène jouée **une fois** par entrée (compteur dans le test).

**Tests** : `test_darkness_config` (lecture, erreurs, opacité < 1), `test_darkness_rules` (états,
`should_cue` : entrée depuis dehors oui, changement de carte dans la même grotte non, chargement
non, sans Flash non), `test_darkness_veil` (intégration : caché hors grotte obscure ; centre suit
le joueur en unités normalisées ; tween d'ouverture au pas près avec `TweenClock` ; « Réduire les
animations » → instantané ; aucun changement de collisions : `GridWorld` identique avec et sans
voile).

### 2.11 Mise en scène automatique de Flash (T24, T25)

`game/systems/field_moves/flash_director.gd` — `FlashDirector` (`Node`, enfant de Boot comme
`EvolutionDirector`) ; aucune règle (tout vient de `DarknessRules` et `FieldMoves`).

```
arrivée sur une carte (SceneRouter, pendant l'écran noir) :
  state := DarknessRules.state_for(map, caves, FieldMoves.can_use(&"flash", …))
  si state == NONE : voile caché (fin)
  si chargement d'une partie ou pas de mise en scène due : voile posé directement (DARK ou LIT)
  sinon : voile posé DARK ; après le fondu d'arrivée :
     verrou du joueur (raison « flash ») → le Pokémon apparaît (compagnon visible : petit saut ;
     sinon, espèce avec planche : apparition brève sur la case derrière le joueur ; sinon rien)
     → bandeau « {pokemon} utilise Flash ! » (T-17, `FieldMoves.cue_text`) → éclair blanc (0,3 s)
     → ouverture du halo (0,6 s) → fin du bandeau → verrou levé        (total ≈ 1,5 s [D])
```

- Attentes en **tweens** (testables avec `TweenClock`), jamais `create_timer`.
- `Boot.is_stable()` faux pendant la mise en scène (aucune autosave au milieu ; rien à sauver de
  toute façon).
- Retour Android pendant la mise en scène : ignoré [D] (1,5 s).
- Bandeau : composant existant hors combat (celui de `TmLearnOverlay`, `BattleMessageBanner`) ou
  toast long ; choix et placement au T25 (ui-mobile), jetons d'interface en fin de `ui_tokens.gd`.
- **Contrat J16** : la même séquence (« le Pokémon apparaît, effet, l'obstacle disparaît ») sert
  Coupe ; si le J16 crée d'abord un `FieldMoveCue`, `FlashDirector` l'appelle au lieu de dupliquer.
- **Tests** `test_flash_director` (intégration sur `qa_flash` : mise en scène une fois par entrée,
  pas au chargement, pas sans Flash, pas en changeant de carte dans la même grotte ; durée au pas
  près ; verrou ; compagnon ou premier compatible ; texte avec le bon nom).

### 2.12 Données (T7, T8)

#### 2.12.1 Espèces et Pokédex (T7)

`data/pokemon/species/kanto_j17.json` [D] — types et statistiques **actuels**, apprentissages
**RB** (méthode J12/J15 ; valeurs vérifiées sur PokeAPI et `pret/pokered` à l'écriture, tests sur
les numéros) :

| Espèce | N° | Types | Évolution | Notes |
|---|---|---|---|---|
| `diglett` Taupiqueur | 50 | Sol | → `dugtrio` Nv. 26 | capturable |
| `dugtrio` Triopikeur | 51 | Sol | — | capturable (Cave, 5 %) |
| `drowzee` Soporifik | 96 | Psy | → `hypno` Nv. 26 | capturable (Route 11) |
| `hypno` Hypno | 97 | Psy | — | par évolution |
| `magnemite` Magnéti | 81 | Électrik / Acier | → `magneton` Nv. 30 | adversaire seulement |
| `magneton` Magnéton | 82 | Électrik / Acier | — | adversaire seulement |
| `growlithe` Caninos | 58 | Feu | (Pierre Feu : **non** au J17, objet absent) | adversaire seulement |
| `vulpix` Goupix | 37 | Feu | (Pierre Feu : **non**) | adversaire seulement |

- `data/pokedex/kanto.json` (fin de fichier) : taille, poids, description (annexe A, `"draft":
  true` jusqu'à Q-2), notes de Taupiqueur et Soporifik. **Ronflex : rien** (H-10).
- `tm_compatibility.json` régénéré (T2) : les 8 espèces ont leurs CT et CS.
- Sprites provisoires de dos : `gen_placeholder_battlers.gd` étendu (exigé par `test_battle_stage`)
  jusqu'aux dos Colab (T13).
- Compagnon : **Soporifik** éligible si sa planche (repos + marche 4 directions) est validée (entrée
  en fin de `companions.json`) ; Taupiqueur non (sprite d'ambiance seulement) [D].

#### 2.12.2 Capacités : audit (T7)

Capacités apprises par les espèces nouvelles **aux niveaux du jalon** (sauvages, Dresseurs, Hypno
jusqu'à ≈ Nv. 30) :

| Capacité | Qui | État | Décision |
|---|---|---|---|
| `dig` Tunnel | Taupiqueur Nv. 19+, Triopikeur | **J14** (`charge`, invulnérable) | attend le J14 ; **repli** si le J17 doit passer avant : rencontres de la Cave en Nv. 15–18 pour Taupiqueur et Triopikeur sans Tunnel → **non retenu** (change le dossier) : 17A attend le J14 |
| `hypnosis` Hypnose | Soporifik, Hypno (Nv. 1) | absente | **donnée** : statut sommeil, précision 60, PP 20 (effet `status` existant) |
| `headbutt` Coup d'Boule | Soporifik Nv. 24, Hypno | absente | **donnée** : 70, 100 %, PP 15, apeurement 30 % (`flinch`) |
| `poison_gas` Gaz Toxik | Soporifik Nv. 29, Hypno Nv. 33 | absente | **donnée** : poison, précision 55 (RB), PP 40 |
| `meditate` Yoga | Soporifik Nv. 37, Hypno Nv. 43 | absente | **donnée** : Attaque +1 |
| `psychic` Psyko | Soporifik Nv. 32, Hypno Nv. 37 | **J14** | attend le J14 (hors niveaux du jalon : sans effet sur 17A) |
| `roar` Hurlement | Caninos (Nv. 1) | absente | **donnée** `pending_effects: ["force_switch"]` (comme `whirlwind`) ; **Dresseur** : remplacée par `leer` (Groz'Yeux), la plus proche existante (§6 du dossier) |
| `flash` | CS05 | absente | §2.9 |
| `take_down` Bélier | Caninos Nv. 30 (oublié par l'audit, ajouté au T7) | absente | **donnée** : 90, 85 %, PP 20, `pending_effects: ["recoil_damage"]` (comme `double_edge`) |

Toutes les capacités des Dresseurs aux niveaux du §6 existent ailleurs (`wrap`, `poison_sting`,
`bite`, `sand_attack`, `slash`, `leech_life`, `supersonic`, `tackle`, `tail_whip`, `quick_attack`,
`hyper_fang`, `leer`, `horn_attack`, `double_kick`, `screech`, `sonic_boom`, `thunder_shock`,
`ember`). Fichier `data/pokemon/moves/j17.json`. Tests : chaque capacité ajoutée a son effet ou sa
mention « Sans effet dans le moteur actuel. » (règle J12), `test_pokemon_data`.

#### 2.12.3 Rencontres (T8)

- `data/encounters/route_11.json` : herbes de la Route 11, Abo 20 (12–15), Sabelette 20 (12–15),
  Piafabec 35 (13–17), Soporifik 25 (9–15) ; taux des routes (`rate` et `ramp` de la Route 3).
- `data/encounters/digletts_cave.json` : terrain `rubble`, Taupiqueur 95 (15–22), Triopikeur 5
  (24–26) ; taux du Mont Sélénite. **Fusionné dans `jalon-17` seulement après le J14** (`dig`).
- Route 2 est : aucune rencontre. Tests `test_encounter_library` (tables, cartes, somme des poids).

#### 2.12.4 Dresseurs (T8)

`data/trainers/route_11.json`, IA `random`, `prize_money` du §6, capacités au niveau (sauf
Caninos : `["bite", "leer", "ember"]`), noms « Gamin Lucas », « Joueur Marcel », « Ingénieur
Bruno »… Répliques T-18 à T-25 (avant / défaite / après) dans `data/dialogues/route_11.json`.
**Simulation** `tools/simulate_route_11.gd` (modèle `simulate_mt_moon.gd`) : profil « arrivée
avant le S.S. Anne, équipe Nv. 18–22 » ; niveaux **recalés** si un Dresseur dépasse la cible, sans
dépasser les références de Major Bob ; tableau dans ce plan au T8 ; test
`test_simulate_route_11` (intégration).

**Fait au T8 (2026-10-15) — simulation et niveaux retenus.** Outil commun
`tools/simulate_mt_moon.gd` avec un scénario (précédent du J14 T21) au lieu d'un
`simulate_route_11.gd` : `tools/sim/route_11_scenario.json` (`--donnees --seeds 500`, ≈ 3 min ;
rapports bruts non versionnés `build/sim/j17_t8/`) et `tools/sim/route_11_recalage.json` (chaque
Dresseur seul, soigné, au premier essai). Profil « arrivé à Carmin avant le S.S. Anne » : meneur
Nv. 20–22 (Reptincel 22 + Férosinge, Roucoups, Mystherbe ; « Kevin » estimé Reptincel 22,
Roucoups 19, Nidorino 18, Rattata 17 ; Herbizarre 21 ; Carabaffe 22) et trois équipes basses
(meneur Nv. 18–19). Parcours de la grille : D2 seul inévitable vers la Cave, G2 = 7 cases ; la
Route 11 en deux allers depuis le Centre, ou avec un soin après chaque Dresseur. Cible (défaut du
J12) : joueur attentif (Centre + 3 Potions) au bout sans défaite ≥ 85 %, aucun combat > 40 % de
défaites, **sur les équipes du profil** (les basses : information, comme « Bulbizarre 15 » au J12).

| Dresseur | Dossier (RB) | Retenu | Raison |
|---|---|---|---|
| D8 Ingénieur Victor | Magnéti 18, Magnéti 18, Magnéton 18 · 900 ₽ | **Nv. 16 · 800 ₽** | Magnéti et Magnéton sont Électrik / **Acier** (types actuels, T7) : Plante, Normal, Vol, Insecte et Psy résistés ; Herbizarre 21 attentif ne gagnait qu'à 61 % (expert 21 %) ; Nv. 16 : 94,8 % (Nv. 17 : 84,5 %) |
| les sept autres | RB | **inchangés** | profil ≥ 98 % au premier essai, tous sous Major Bob (Nv. 24) |

- **Chemin principal** (Arthur + Cave) : ≥ 99 % pour toutes les équipes attentives, basses
  comprises (naïf : Herbizarre 18 à 84 %). Triopikeur Nv. 24–26 (H-15) : aucun échec mesuré.
- **Route 11 complète, soin après chaque Dresseur, attentif** : 96,6 à 100 % (profil) ; équipes
  basses : Herbizarre 18 à 4 %, Carabaffe 19 à 50 %, Reptincel 19 à 89 %.
- **Gamin Louis** (3 × Rattata / Rattatac Nv. 17, Croc de Mort) reste dur pour les équipes
  basses (victoire 31,8 % Herbizarre 18, 55,5 % Carabaffe 19) ; Nv. 15 donnerait 81 % / 92,5 %.
  Évitable (parcours nord) : **non recalé**, question à Kevin.
- Deux allers sans soin entre les Dresseurs : l'usure (3 Potions pour 4 Dresseurs) fait échouer
  l'équipe Herbizarre (0 %), comme « tous les Dresseurs » du J14 : rythme de RB, pas un réglage.

#### 2.12.5 Objets, dialogues, zones, Carte (T7, T8)

- `data/items/j17.json` : `hm05` (§2.7). Réutilisés : `super_potion` (J15), `awakening`,
  `poke_ball`, `escape_rope`, `moon_stone` (J12), `rare_candy` (J14).
- Dialogues (mot pour mot, §16) : `route_11.json` (T-6/T-7 Ronflex, T-10, T-12 panneaux, T-18 à
  T-25), `route_2_east.json` (T-1 à T-5, T-11, scène de remise), `route_2.json` (fin de fichier :
  T-8 barrière côté est, T-9 panneau après ouverture comme **variante** `if route_2_east_gate_open`
  du panneau existant `route_2_closed_sign`), `items` (T-15), capacités (T-16), `field_moves.json`
  (T-17).
- `zones.json` (fin) : `route_11` (« Route 11 », sous-titre annexe A, T-13), `digletts_cave` (kind
  `place`, « Cave Taupiqueur », T-14) ; `route_2.maps` += `route_2_east`, `route_2_east_gate`.
- `kanto_placeholder_areas.json` : aires `route_11`, `digletts_cave` ; l'aire `route_2` couvre le
  couloir (vérifié par capture de la Carte) [D]. `pokedex/scenes.json` : `route_11` → décor
  « prairie », `digletts_cave` → « grotte » [D].
- `companions.json` `contexts` : `digletts_cave` → `cave`, `route_2_east` → `forest` [D].
- **Objectifs** : aucun (pass §6 : rien de propre au J17).

- **Fait au T8 (2026-10-15)** — écarts au texte ci-dessus :
  - Dresseurs en `prize_per_level` (15 / 70 / 50 : argent = base de la classe × dernier niveau,
    suit un recalage) ; Caninos `["bite", "leer", "ember"]` ; Victor Nv. 16 (§2.12.4).
  - Dialogues : `route_11.json` (`route_11_sign` T-12, `route_11_cave_sign` T-10,
    `route_11_snorlax` T-6 puis T-7, 24 répliques de Dresseurs), `route_2_east.json` (assistant
    §2.6, `…_hm05_system`, `…_hm05_use`, visiteur T-5, `route_2_east_cave_sign` T-11),
    `route_2.json` (`route_2_gate_east` T-8 + `set route_2_east_gate_open` ; variante T-9 en tête
    de `route_2_closed_sign`). Locuteurs [D] : « Assistant », « Visiteur ». Variante d'accord à
    une espèce en `"draft": true` (annexe A, Q-2).
  - Scène `route_2_east_give_hm05` (`data/cutscenes/route_2_east.json`) : `give hm05` →
    narration T-3 → deux bulles T-3 → `set got_hm05` ; les trois premières étapes `unless got_hm05`
    (rejouée après coup : jamais deux CS05).
  - **Zones en attente de leurs cartes** (précédent du J15) : `tools/pending_data/j17/zones.json`
    (`route_11`, `digletts_cave`, en `draft` pour les sous-titres de l'annexe A ; rectangles de
    l'illustration et décors du Pokédex proposés : `route_11` « prairie », `digletts_cave`
    « plateau » comme le Mont Sélénite — aucun décor « grotte »). À poser avec T15 / T16 ;
    `route_2.maps` += `route_2_east`, `route_2_east_gate` avec T19.
  - `companions.json` : `digletts_cave` → `cave`, `route_2_east` → `forest`.
  - **Non faits ici** (données de carte, avec leurs PNJ) : objets au sol et caché (scènes
    `<carte>_item_<n>` et PNJ « objet »), `data/npcs/*.json` des Dresseurs, de l'assistant et du
    visiteur (T17, T19, T20, T21).
  - Tests : `test_j17_data` (Dresseurs, tables, textes mot pour mot du §16, table de l'assistant
    sur les vraies données, scène, zones en attente), `test_simulate_route_11` ; listes recalées
    (`test_dialogue_data` : dossier 20 et annexe A dans le contrôle « mot pour mot », dialogues
    `UNUSED_YET` jusqu'aux cartes ; `test_cutscene_data`, `test_encounter_library`,
    `test_no_draft_in_data`).

### 2.13 Route 2 sud, FUTUR A, FUTUR B, arbustes (T21, T23)

- **T21 (A)** : report des rangées de `route_2_j17_retouches.txt` dans `route_2.txt` (une seule
  source), plan en aplats refait, `plan_check` de la Route 2 et `plan_check_j17` verts ; dans
  `build_route_2.gd` (bloc « J17 ») :
  - sentier `b` (35..41, 43..44) praticable, warp est (41, 43..44) `PUSH →` → `route_2_east` /
    `from_route_2_n|s`, arrivée `from_route_2_east_n|s` ;
  - **barrière FUTUR B** : `FlagGate` fermée `unless route_2_east_gate_open` à `blocking_cells`
    1 × 2 en (34, 44) (cases rendues praticables dans la grille, §2.4) + `FlagGate` ouverte `if` ; le point existant `route_2_closed_gate` (lu depuis l'ouest) reçoit
    `unless_flags = [route_2_east_gate_open]` ; nouveau point `route_2_gate_east` (même cases, lu
    **depuis l'est**, `facing = LEFT`, `unless` le drapeau) → dialogue T-8 avec `set
    route_2_east_gate_open` (la barrière s'ouvre en fin de dialogue, sans changer de carte, §2.4) ;
  - panneau (33, 42) : variante T-9 ;
  - clairière FUTUR A (sol, objet `route_2_item_5`), **arbuste encore « arbre dense »** : le point
    `examen_arbre_dense` et son texte T7 restent tant que la Coupe n'existe pas.
- **T23 (B, après le J16)** : arbuste du couloir (6..7, 21) et FUTUR A (4, 19) = `FlagGate`
  `unless cut_<id>` à `blocking_cells` (arbuste du J16) + point « arbuste » du J16 (`FieldMoves.can_use(&"cut", …)` +
  Badge Cascade, textes génériques du J16) ; FUTUR A perd le texte T7 du dossier 11 dès la CS01
  (variante du J16).
- **Si le J16 n'est pas fusionné à la fin du J17** : le couloir sud (Pierre Lune, Super Bonbon,
  barrière vue de l'est) et la clairière FUTUR A restent **inatteignables** dans le jeu (aucun
  blocage : H-2) ; ils sont testés par **départs de débogage** placés derrière l'arbuste
  (`route_2_east_south`, `route_2_futur_a`) et par tests ; T23 passe au J16 (ou à une petite
  session après sa fusion), noté à la clôture. Le J17 ne crée **pas** Coupe.

### 2.14 Compagnon (aucune règle nouvelle)

Suit sur la Route 11, la Cave, la Route 2 est ; caché dans le poste ; jamais posé sur une bouche
(règle des escaliers du J12 appliquée aux warps `STEP_ON` des bouches : test) ; n'occupe aucune
case (`companion_trail.gd`) : ni contournement de Ronflex ni blocage. Test
`test_companion_j17` (bouches, goulet de Ronflex, poste).

### 2.15 Sauvegarde : **pas de v8**

Tout l'état du J17 est déjà sérialisé : drapeaux (`flags`), Sac (CS05 = identifiant d'objet, rangé
par sa catégorie : rien à migrer, `item_data.gd` « ajouts en fin d'enum »), Pokédex, objets trouvés.
Les blocs `FlagGate`, Ronflex, la barrière, le voile et la Corde à deux bouches se **déduisent** des drapeaux
et de la position. La version reste celle de `main` à la fusion (v7 du J15). **Si** Q-1 retenait le
`dark_cave_lit` du dossier 21, ce serait un drapeau : toujours pas de v8. Test
`test_save_j17` : aller-retour d'une partie avec `got_hm05`, `route_2_east_gate_open`, CS05 dans le
Sac, position dans la Cave et sur le sentier `b` ; aucune clé nouvelle à la racine.

### 2.16 Budgets et mesures

- ≤ 3 000 nœuds par carte, mesuré **dès la première construction** : Route 11 (76 × 36, forêt et
  mer), Cave (34 × 80, surtout paroi).
- Mémoire « carte + voisines » (`tools/measure_map_cache.gd`) : Route 11 + Carmin + Cave ; seuil
  64 Mo (J12).
- fps : moyenne ≥ 58, creux ≥ 50 (Route 11, Cave, Route 2 est, `qa_flash` avec voile).
- Voile : aucune allocation par image ; `set_process(false)` hors grotte obscure.

### 2.17 Carte de QA et départs de débogage

- **`qa_flash`** (T10, **provisoire, retirée au T28**) : petite grotte (≈ 20 × 14) construite avec
  `cave_map_kit.gd` et `cave_shade.gd`, entrée depuis une pièce éclairée `qa_flash_entry` ; entrée
  `qa_flash` dans `caves.json` avec `"dark": true` (retirée au T28) ; quelques gravats sans
  rencontre, un PNJ immobile pour juger « sous le voile », un `LightGlow` (comportement actuel noté,
  extension J18).
- Départs (`tools/debug_start/`, README) : `flash_qa` (CS05, Pikachu compagnon compatible) ;
  `flash_qa_no_pokemon` (CS05, équipe incompatible) ; `flash_qa_no_hm` (compatible sans CS05) ;
  `flash_qa_ko` (seul compatible K.O.) ; `route_11` (équipe Nv. 18–22) ; `digletts_cave_south`,
  `digletts_cave_north` ; `route_2_east` (9 espèces capturées) ; `route_2_east_10` (10 espèces) ;
  `route_2_east_south` (derrière l'arbuste) ; `route_2_futur_a`.

---

## 3. Tâches

Branche **`jalon-17`** (copie dédiée), une branche par tâche (`j17-t<n>-<sujet>`) ; jamais de
`pkill` ; chaque tâche met à jour `etat-projet.md` dans son commit ; textes **mot pour mot** (§16
et annexe A validée).

#### T0 — architecte : plan (fait)

#### T1 — architecte : branche d'intégration — **(A)**
- `jalon-17` depuis `origin/main` (`4f0ee90` ou plus récent) ; réaligner §0 si `main` a bougé
  (J14, J15). **CA** : `tools/test.sh` vert, import propre.

#### T2 — architecte : les CS dans les données — **(A)**, après T1
- §2.7 : `ItemData.hm_number`, `is_hm`, `ItemLibrary`, générateur (machines 101..105),
  `PokemonData.can_learn_hm`, `TmTeach`, titre d'onglet (annexe A). Vérifier d'abord la branche du
  J16 : s'il a déjà posé des CS, s'aligner.
- Tests §2.7. **CA** : tests verts ; `tm_compatibility.json` régénéré, identique sur `tms` / `species`.

#### T3 — architecte : `FieldMoves` — **(A)**, après T2
- §2.8 ; `data/pokemon/field_moves.json`. Tests `test_field_moves`. **CA** : tests verts ; aucun
  nœud.

#### T4 — architecte : condition Pokédex et jetons — **(A)**, après T1
- §2.5. Tests listés. **CA** : tests verts ; les dialogues existants inchangés (suite complète).

#### T5 — architecte : cases libérées par un drapeau — **(A)**, après T1 — **fait** (2026-10-15)
- §2.4 réaligné : `FlagGate.blocking_cells` (J15, adopté par le J16) au lieu d'un `FlagBlock` ;
  ajout `SceneRouter.arrival_flags`. Tests `test_flag_gate` (+1), `test_flag_gate_blocking_map`. **CA** : case libérée pendant la visite et après rechargement ; aucune
  scène existante modifiée.

#### T6 — architecte : Corde Sortie à deux bouches — **(A)**, après T1
- §2.3. Tests `test_cave_library`, `test_escape_rope` (Mont Sélénite inchangé). **CA** : tests verts.

#### T7 — architecte : espèces, capacités, Pokédex, CS05 — **(A)**, après T2
- §2.12.1, §2.12.2, §2.9, `hm05` ; Pokédex en `draft` jusqu'à Q-2 ; dos provisoires.
- Tests `test_pokemon_data` (compte d'espèces recalé), `test_pokedex_library`, `test_item_library`,
  `test_battle_flash`, `test_battle_stage`, **anti-blocage J18** : `test_hm05_availability` (au moins
  une espèce compatible CS05 capturable avant la Cave quel que soit le starter : Soporifik,
  Pikachu, Mélofée…, d'après les tables de rencontres). **CA** : tests verts ; aucune carte.

#### T8 — architecte : Dresseurs, rencontres, dialogues, zones, simulation — **(A)**, après T4, T7
- §2.12.3 (table de la Cave fusionnée après le J14), §2.12.4, §2.12.5, §2.6 (dialogues et scène).
- Tests `test_trainer_library`, `test_encounter_library`, `test_dialogue_library`,
  `test_cutscene_library`, `test_zone_library`, `test_assistant_dialogue`, `test_simulate_route_11`.
- **CA** : tests verts ; niveaux recalés notés dans ce plan.

#### T9 — architecte : fondation d'éclairage — **(A)**, après T1
- §2.10 : `DarknessConfig`, `DarknessRules`, `DarknessVeil`, shader, `darkness.json`, `dark` dans
  `CaveLibrary`, `LAYER_WORLD_VEIL`. Tests §2.10. **CA** : tests verts ; Mont Sélénite sans voile
  (test) ; capture Mac du voile sur une carte de test.
- **Fait (2026-10-15) — aligné sur `jalon-18.md` §2 (une seule brique)** : `DarknessProfile`,
  `VeilParams`, `VeilMath`, `DarknessVeil` (`Node2D` dans le monde, `WorldLighting.Z_VEIL` = 20,
  bulles en `Z_ABOVE_VEIL` = 21), `DarknessController` (Boot), shader en coordonnées du monde,
  trous des `LightGlow`. Remplacent `DarknessConfig`, le calque `LAYER_WORLD_VEIL` et
  `DarknessRules` (« obscure » = `CaveLibrary.is_dark` ; `should_cue` attend Q-1, T24). Tests
  `test_darkness_profile`, `test_veil_math`, `test_darkness_veil`, `test_cave_library`,
  `test_debug_start` (clé `veil`).

#### T10 — constructeur-monde : `qa_flash` et départs — **(A)**, après T9
- §2.17. **CA** : départs chargés sans erreur ; README à jour ; captures relues (voile sombre, halo
  ouvert, joueur au bord de la carte).
- **Fait (2026-10-15)** : `qa_flash` (32 × 16, obscure) + `qa_flash_entry` (12 × 8), outil
  `tools/build_qa_flash.gd`, départs `flash_qa`, `flash_qa_dark`, `flash_qa_lit` (clé `veil`).
  Reportés au T7 / T24 : CS05 au Sac, `flash_qa_no_pokemon`, `flash_qa_no_hm`, `flash_qa_ko`. À
  retirer au T28 : cartes, assets `assets/world/maps/qa_flash*`, grilles, outils
  `build_qa_flash.gd` / `capture_qa_flash.gd`, `data/npcs/qa_flash.json`, entrée de `caves.json`,
  départs, `test_qa_flash`, listes de `test_map_catalog` et `test_cave_library`.

#### T11 — architecte : kit d'assets série 19 — **(A)**
- §1.4 ; fiche `docs/design/fiches-assets/serie-19-chemins.md`, `tools/art/serie19.py`
  (`--prompts`, `--refs`, `--commandes`, `--planche`, `--manifeste`, `--controle`).
- **CA** : chaque élément visible des trois vues validées a un asset (réutilisé, varié, nouveau) ou
  est abandonné explicitement.

#### T12 — constructeur-monde (Mac, Codex) : génération → planche de contact pour Kevin — **(A)**
#### T13 — constructeur-monde (Mac) : dos de combat Taupiqueur, Triopikeur, Soporifik, Hypno (Colab) — **(A)**
#### T14 — constructeur-monde (Mac) : intégration de la série 19 — **(A)**, après T12, T13
- Manifeste (fin), `preparer.py`, `build_painted_props.gd -- --nouveaux`,
  `build_character_frames.gd` (fin), icône `hm05`, décors de combat CB.3. **CA** : second passage
  sans changement ; `test_painted_props` vert.

#### T15 — constructeur-monde : Cave Taupiqueur — **(A)**, après T6, T14 (rencontres : J14)
- §2.1, §2.3 ; `build_digletts_cave.gd`, `caves.json`, `cave_sand`, Taupiqueur d'ambiance, Corde
  Sortie visible. Test `test_digletts_cave` (grille de la scène = grille du plan ; 96 pas bouche à
  bouche ; 7 gravats obligatoires seulement en G2 ; G1, G3, G4 évitables ; Corde des deux moitiés ;
  nœuds ≤ 3 000 ; raccords aller-retour) ; captures + `luminance_grotte.py`.

#### T16 — constructeur-monde : Route 11 — **(A)**, après T5, T14
- §2.1 ; `build_route_11.gd` ; bord ouest `coming_soon` jusqu'au J15. Test `test_route_11`
  (grille = plan ; **critères de `plan_check_j17` sur la vraie scène** : D2 inévitable, D1 et
  D3..D8 évitables ensemble, trois parcours suffisants chacun, Ronflex sans contournement, bord est
  inatteignable, H2 6 cases obligatoires sur le parcours nord ; nœuds ≤ 3 000) ;
  `test_map_catalog`, `test_map_links`.

#### T17 — constructeur-monde : vie de la Route 11, raccord de Carmin — **(A)** puis **(B : J15)**
- Ronflex (§2.4), 8 Dresseurs, objets visibles et caché (`_add_hidden_item`), panneaux T-10, T-12,
  Pokémon d'ambiance, titre d'arrivée. **(B)** : warp est de Carmin (outil du J15) → `route_11`.
- Tests `test_route_11_life` (Ronflex T-6 puis T-7, cases bloquées, examen depuis les 2 cases du
  goulet ; objets ; caché : bouton face à l'indice seulement, absent après rechargement),
  `test_route_11_trainers` (Arthur inévitable, récompenses du §6, répliques), test de raccord
  Carmin ↔ Route 11 sur les trois rangées.

#### T18 — qa-mobile : **session 17A** → Kevin — **(B)**, J14 + J15 dans `main`
- Départs `route_11`, `digletts_cave_*` puis traversée depuis Carmin ; §4 « 17A ». Bornée
  30–45 min (mémoire « QA bornée »), S21 ou S24.

#### T19 — constructeur-monde : Route 2 est, poste, assistant — **(A)**, après T4, T14
- §2.1, §2.2, §2.6 ; `build_route_2_east.gd` ; arbuste posé en `FlagGate` fermée à `blocking_cells` (sans Coupe :
  inerte, texte T7-like absent : **aucun point d'examen** avant le J16 [D]) ; panneau T-11.
- Tests `test_route_2_east` (grille = plan ; bouche → poste 12 pas sans Coupe ; sud inatteignable
  sans le drapeau de l'arbuste, atteignable avec ; nœuds), `test_assistant_hm05_flow`.

#### T20 — constructeur-monde : objets du couloir — **(B : J14)**
- Pierre Lune, Super Bonbon (`rare_candy`). Test : ramassés une fois, absents après rechargement.

#### T21 — constructeur-monde : retouches de la Route 2 sud — **(A)**, après T5 (visuel : J14)
- §2.13 (A) ; captures avant / après de la retouche peinte.
- Tests `test_route_2` étendu (sentier `b`, raccord est, barrière fermée depuis l'ouest = texte
  existant, T-8 depuis l'est, ouverture sans changer de carte, puis passage dans les deux sens,
  panneau T-9 ; FUTUR A inatteignable sans le drapeau de l'arbuste).

#### T22 — qa-mobile : **session 17B** → Kevin — **(B : J14)**, après T19–T21
- Départs `route_2_east`, `route_2_east_10`, `route_2_east_south` ; §4 « 17B ».

#### T23 — constructeur-monde : arbustes — **(B : J16)**
- §2.13 (B). Tests : arbuste avec / sans CS01, avec / sans Cascade, sans compatible (textes du J16),
  coupé = définitif après rechargement ; FUTUR A → clairière → Super Potion.

#### T24 — architecte : mise en scène de Flash — **(A)**, après T3, T9
- §2.11 ; branchement dans Boot (bloc « J17 ») : voile posé à l'arrivée, `FlashDirector`.
- Tests `test_flash_director`. **CA** : tests verts ; la Cave et le Mont Sélénite sans voile.

#### T25 — ui-mobile : rendu de Flash et mesures — **(A)**, après T10, T24
- Bandeau, éclair, couleur et opacité du voile, tramage si besoin ; `tools/capture_flash.gd`
  (sans Flash, au milieu de la mise en scène, avec Flash, joueur au bord) en 2340 × 1080 et
  1170 × 540 ; `luminance_grotte.py --halo` ; jetons d'interface (fin de `ui_tokens.gd`).
- **CA** : captures relues ; contraste du héros ≥ 3,0 ; aucune couleur en dur.

#### T26 — qa-mobile : **session 17C** → Kevin — après T22, T24, T25
- `flash_qa*` sur **S24** (fps) et S21 (lisibilité, précision du shader) ; apprentissage de Flash
  par la CS05 (Sac) et utilisation en combat ; §4 « 17C ».

#### T27 — qa-mobile : **session 17D** → Kevin — après tout
- Traversées complètes, sauvegarde / rechargement à chaque transition, non-régression sur la vraie
  partie de Kevin ; arbustes si le J16 est arrivé ; §4 « 17D ».

#### T28 — architecte : clôture
- Retrait de `qa_flash`, `qa_flash_entry`, de leur entrée `caves.json` et des départs `flash_qa*` ;
  `etat-projet.md`, roadmap (et la ligne J17 des branches de conception, §0.2 n° 2) ; **passation
  au J18** (voile : lampes qui percent, bulle « ! », respiration, réglage avec l'art de la grotte ;
  déclenchement selon Q-1) et **au J16** (contrat §1.2 si le J17 passe d'abord ; T23 si non fait) ;
  fusion dans `main` (copie d'intégration ; `project.godot` et filtre d'export vérifiés).

---

## 4. Critères d'acceptation par sous-jalon

**17.0** — tests verts, import propre ; CS05 enseignable (Sac) aux compatibles seulement, jamais
consommée ; `FieldMoves` rend −1 sans CS05 ou sans compatible ; variantes de l'assistant correctes
à n = 1, 9, 10, 11 ; un bloc `FlagGate` libère ses cases pendant la visite ; Corde Sortie : bonne bouche de
chaque côté de la rangée 39/40 ; données des 8 espèces et 7 capacités chargées ; Pokédex en
brouillon ; captures Mac du voile.

**17A** — Carmin ↔ Route 11 sur les trois rangées (ou « À venir » avant le J15) ; T-12, T-10 ;
**Arthur impossible à contourner**, les sept autres évitables ; récompenses du §6, répliques T-18 à
T-25 ; rencontres (Soporifik vu, Hypnose) ; Super Potion, Réveil visibles, Poké Ball cachée (bouton
face au caillou seulement, puis plus rien) ; **Ronflex** : T-6 puis T-7, aucune case contournable,
le compagnon ne passe pas ; Cave : 96 pas, rencontres seulement sur les gravats, Triopikeur rare,
Corde Sortie visible et utilisée depuis chaque moitié, lisible **sans monter la luminosité** ;
compagnon jamais posé sur une bouche ; défaite → dernier Centre ; ≥ 58 fps, nœuds ≤ 3 000.

**17B** — Cave → Route 2 est → poste en 12 pas sans Coupe ; T-11, T-5 ; assistant T-1 puis T-2
(compte exact, « Encore n »), T-3 au seuil (atteint par capture **et** par évolution), CS05 reçue
une seule fois, T-4 ensuite ; CS05 dans le Sac (T-15) ; avec le départ `route_2_east_south` :
Pierre Lune, Super Bonbon, barrière T-8 → ouverte pour toujours, passage Route 2 sud ↔ couloir dans
les deux sens, panneau T-9, texte de l'ouest inchangé tant qu'elle est fermée ; FUTUR A et arbuste
du couloir **inertes** sans le J16 ; titre « ROUTE 2 » dans le couloir.

**17C** — Flash appris par la CS05, PP 20, précision 70 %, Précision de l'adversaire −1 ; sur
`qa_flash` : sans Flash, carte sombre mais lisible, rien ne bloque ; avec Flash, mise en scène
**une fois par entrée** (≈ 1,5 s), halo qui suit le joueur partout (bords compris), aucun
changement de collision ; « Réduire les animations » respecté ; **fps S24 inchangés** (écart
≤ 1 fps, moyenne ≥ 58, creux ≥ 50) ; **contraste du héros ≥ 3,0** dans le halo ; S21 sans artefact.

**17D** — traversées Carmin → Route 11 → Cave → Route 2 est → (barrière) → Route 2 sud → Jadielle
et retour complet par la Cave ; sauvegarde / rechargement à chaque transition (position, objets,
Dresseurs, barrière, CS05) ; `qa_flash` retirée ; vraie partie de Kevin sans régression ; tests
verts, import propre, budgets tenus.

---

## 5. Cas limites (dossier §13) → tests

| Cas | Test | Attendu |
|---|---|---|
| Seuil des 10 espèces atteint par une évolution | `test_assistant_hm05_flow` | `record_evolved` compte ; remise à la visite suivante |
| Seuil atteint, puis Pokémon relâchés / déposés | idem | compte inchangé, remise |
| CS05 reçue sans Pokémon compatible | `test_field_moves`, `test_flash_director` (`flash_qa_no_pokemon`) | rien ne se passe ; aucune carte obscure dans le jeu |
| Application tuée pendant la remise de la CS05 | `test_assistant_hm05_flow` (sauvegarde relue pendant la scène) | état d'avant (ni CS05 ni drapeau) ; la scène se rejoue |
| … pendant l'ouverture de la barrière | `test_route_2` | barrière fermée ou ouverte, jamais à moitié (drapeau seul) |
| … juste après avoir coupé un arbuste | T23 (J16) | règle du J16 |
| Joueur dans le couloir sans CS01 | `test_route_2_east` | assistant atteint, CS05 reçue, retour par la Cave ; ni arbuste ni barrière bloquant |
| Barrière ouverte, sauvegarde côté Route 2 sud, rechargement | `test_route_2`, `test_save_j17` | passage ouvert |
| Traversées complètes dans les deux sens | `test_j17_crossings` (intégration, warps enchaînés) + T27 | aller et retour sans blocage |
| Ronflex : aucune case contournable, compagnon, Dresseurs | `test_route_11`, `test_companion_j17` | bord est inatteignable ; aucun Dresseur ne pousse au-delà |
| Défaite contre Triopikeur dans la Cave | `test_digletts_cave` (défaite simulée) | réveil au dernier Centre (Carmin, Argenta ou Jadielle) |
| Corde Sortie depuis chaque moitié | `test_escape_rope` | moitié sud → Route 11, moitié nord → Route 2 est |
| Dresseur inévitable | `test_route_11` | Arthur sur tout chemin vers la Cave et vers l'est |
| (en plus) accord n = 1 | `test_assistant_dialogue` | « 1 espèce capturée » |
| (en plus) Flash avec un seul compatible K.O. | `test_field_moves` | utilisable [D] |
| (en plus) chargement d'une partie dans une grotte obscure | `test_flash_director` | halo posé directement, pas de mise en scène |
| (en plus) CS01 sans Badge Cascade | T23 | arbuste refusé avec le texte du J16 |

---

## 6. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Flash conçu deux fois** (dossiers 20 et 21 contradictoires) | travail jeté au J18 | Q-1 ; fondation neutre ; combat et mise en scène isolés (une donnée, un nœud) |
| **J16 non conçu** (CS, Coupe, arbustes) | doublons ou renommages | contrat §1.2, « premier fusionné crée » ; T23 isolée ; départs de débogage |
| **J14 / J15 en retard** (`dig`, `FlagGate`, `rare_candy`, Carmin) | 17A / 17B bloqués | tout le reste en (A) ; Route 11 avec `coming_soon` ; tables de la Cave préparées non fusionnées |
| **Voile mal placé** (étirement, caméra limitée, petites cartes) | trou décalé | `get_global_transform_with_canvas` ; captures au bord ; test du centre |
| **Précision du shader sur mobile** | artefacts, halo carré | unités normalisées ; S21 + S24 |
| **Budget de nœuds** Route 11 (forêt, mer) | fps | mesure au premier passage ; `DenseForest` ; mer en aplats |
| **Fichiers chauds** (`boot.gd`, `map.gd`, objets, dialogues) | conflits | blocs courts « J17 » ; fusion de `main` après chaque jalon |
| **Échec intermittent connu** de `tools/test.sh` sous charge | faux rouge | relancer le fichier seul ; noter |

---

## 7. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Branches | `jalon-17` depuis `origin/main` ; tâches `j17-t<n>-*` |
| Drapeaux | `got_<id de grille>` (§1.3) ; `snorlax_route_11_seen`, `hm05_assistant_met` |
| Ronflex | `FlagGate` (`blocking_cells` 2 × 2) + `InteractPoint` 2 × 2, tous `unless snorlax_route_11_awake` |
| Corde Sortie | bouche de la moitié où se tient le joueur (rangées 0..39 / 40..79) |
| CS | catégorie `tm` + champ `hm` ; onglet « CT et CS » ; CS après les CT |
| `FieldMoves` | compagnon compatible d'abord, puis premier compatible ; K.O. accepté |
| Jetons | `{caught}`, `{caught_missing}` (vide à n ≥ 10) ; accord n = 1 |
| Voile | calque 4 ; couleur noir bleuté ; halo 2,5 / 4 cases sans Flash, 7 / 9 avec ; ouverture 0,6 s, éclair 0,3 s, mise en scène ≈ 1,5 s ; « Réduire les animations » : instantané |
| Obscurité | `caves.json` `"dark": true` ; seule `qa_flash` au J17 |
| Mise en scène | à l'entrée d'une grotte obscure depuis l'extérieur de cette grotte ; jamais au chargement ; retour Android ignoré |
| Cave | profil `cave_sand` ; pas de voile ; `rate` 25 + rampe du Mont Sélénite |
| Route 2 est | lumière `forest` ; arbuste sans point d'examen avant le J16 |
| Données | fichiers `kanto_j17.json`, `moves/j17.json`, `items/j17.json`, `trainers/route_11.json`, `encounters/route_11.json`, `digletts_cave.json`, `dialogues/route_11.json`, `route_2_east.json` |
| Caninos (Dresseur) | Hurlement remplacé par Groz'Yeux |
| Compagnon | Soporifik éligible si planche validée ; contextes `cave` (Cave), `forest` (couloir) |
| Art | série 19 ; décors de combat `route_11_coast`, `digletts_cave_rock` |
| Budgets | ≤ 3 000 nœuds ; ≥ 58 fps moyens, creux ≥ 50 ; ≤ 64 Mo « carte + voisines » ; contraste héros ≥ 3,0 |
| Sauvegarde | aucune version nouvelle |

---

## 8. Questions pour Kevin

- **Q-1 — Flash : dossier 20 ou dossier 21 ?** (§0.2 n° 1, vraie décision de game design) Les deux
  dossiers validés le même jour se contredisent : le 20 fait de Flash une capacité de combat
  (CS05 enseignable, précision 70 %) **déclenchée automatiquement** à l'entrée d'une grotte obscure ;
  le 21 l'exclut du combat et la **propose** à l'entrée (« Utiliser Flash ? » OUI / NON, puis menu
  des capacités de terrain du J16, drapeau `dark_cave_lit`).
  *Recommandation : garder le dossier 20 pour le combat (cohérent avec le modèle hybride de Coupe,
  G-2, déjà validé) et pour le déclenchement automatique (pas de menu ni de bouton, bible UI) ; le
  J18 aligne son §5.3 (halo sans Flash 2,5 cases et « jamais de noir total » restent valables).*
  Alternative : dossier 21 partout — le J17 retire alors `flash` du combat (une donnée) et la mise
  en scène devient une question à l'entrée (au J18).
  **Ne bloque pas** 17.0, 17A ni 17B ; bloque seulement T24 et la partie « combat » de 17C.
- **Q-2 — Lot de textes de l'annexe A** (Pokédex des 8 espèces, deux notes, deux sous-titres de
  zone, titre de l'onglet du Sac). *Recommandation : relecture en une passe, comme aux J12–J15 ;
  bloque le retrait du `draft` des données, pas le code.*

**À fournir par Kevin** (pas une question) : sa vraie partie (sauvegarde) pour T27.

---

## Annexe A — Textes à valider (Q-2, brouillons)

Conventions des lots précédents : descriptions de Pokédex en deux phrases, ton d'observation, sans
statistique ; tailles et poids officiels (vérifiés sur PokeAPI à l'écriture des données).

### A.1 Pokédex

| Espèce | Taille / poids | Description |
|---|---|---|
| Taupiqueur | 0,2 m / 0,8 kg | Il vit sous terre et ne montre que sa tête. Là où il a creusé, la terre devient légère et fertile. |
| Triopikeur | 0,7 m / 33,3 kg | Trois têtes qui creusent ensemble, si vite qu'on ne les aperçoit qu'un instant. Le sol tremble encore longtemps après son passage. |
| Soporifik | 1,0 m / 32,4 kg | On raconte qu'il se nourrit des rêves des dormeurs. Quand il remue le nez, mieux vaut ne pas fermer les yeux. |
| Hypno | 1,6 m / 75,6 kg | Il balance un pendule sans le quitter des yeux. Ceux qui en suivent le mouvement s'endorment sans s'en rendre compte. |
| Magnéti | 0,3 m / 6,0 kg | Il flotte en grésillant, attiré par tout ce qui porte du courant. On le trouve souvent collé aux machines. |
| Magnéton | 1,0 m / 60,0 kg | Trois Magnéti liés par un même champ magnétique. Près de lui, les aiguilles des boussoles s'affolent. |
| Caninos | 0,7 m / 19,0 kg | Fidèle et courageux, il aboie pour défendre les siens. Son flair ne perd jamais une piste. |
| Goupix | 0,6 m / 9,9 kg | À sa naissance, il n'a qu'une seule queue, toute blanche. Elle se divise et se colore à mesure qu'il grandit. |

### A.2 Notes de forme de base (débloquées à la première rencontre)

- Taupiqueur : « Dans la Cave, on entend parfois un grattement juste sous ses pieds, puis plus
  rien. »
- Soporifik : « Sur la Route 11, il somnole dans l'herbe tiède, l'air de compter les passants. »

### A.3 Interface et zones

- Sous-titre de la Route 11 : « Carmin-sur-Mer — Route 12 » (repris du panneau T-12).
- Sous-titre de la Cave Taupiqueur : « Route 11 — Route 2 ».
- Titre de l'onglet du Sac (menu) : « CT et CS » (au lieu de « CT ») ; libellé court du combat
  inchangé.
- Accord de T-2 pour une seule espèce : « Ton Pokédex compte 1 espèce capturée. » (adaptation
  d'accord du texte validé).
