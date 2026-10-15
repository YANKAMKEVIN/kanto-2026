# Jalon 19 — Les mystères de la Tour Pokémon (étages 2F à 6F)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/dossier-22-tour-pokemon.md` (K-1 à K-20, textes du §15 et grilles v1 validés par
> Kevin le 2026-10-14 ; corrections J20 / J21 appliquées).

> Objectif jouable sur le téléphone : **le premier lieu où l'on ne gagne pas en se battant**. Au
> rez-de-chaussée (J18), la gardienne s'écarte de l'escalier. Le joueur monte du 2F au 6F, bat le
> **rival n° 5** au 2F (victoire obligatoire), affronte **9 Exorcistes** possédés, se repose dans la
> **zone purifiée** du 5F et rencontre des **SPECTRES** qu'il ne peut ni voir, ni toucher, ni
> capturer. Au 6F, un SPECTRE le repousse devant l'escalier du 7F. Il redescend avec deux fils :
> le panneau du **Scope Sylphe** et une rumeur sur le **Casino de Céladopole**.
>
> Mécaniques nouvelles :
> - le **mode spectre** : décidé à chaque rencontre par la possession de `silph_scope` ; identité
>   masquée ; « trop effrayé » ; Ball refusée **sans être consommée** ; fuite toujours réussie ;
>   aucune XP ; rien au Pokédex ;
> - le terrain de rencontre **`floor`** (toute case praticable, sauf des exclusions) ;
> - une **étape de scène « combat sauvage »** (le SPECTRE du 6F ; elle resservira au J21) ;
> - un **profil de lumière `tower`** et une **brume** en calque, sans `Light2D`.
>
> Tout le reste (rival, Exorcistes, zone purifiée, objets, Lavanville) est du contenu posé sur des
> systèmes existants. **Format de sauvegarde inchangé : v7** (§2.13).

**Pré-requis.** Dossier 22 verrouillé (2026-10-14). Passe d'alignement :
`docs/design/passes/j19-v2-alignement.md`. Grilles : `tools/plans/pokemon_tower_2f.txt` à `6f.txt`,
contrôle `tools/art/plan_check_tour_pokemon.py` (OK). Vue générale validée :
`reference/tour-pokemon-vue-generale-v1.png` et son plan `tour-pokemon-plan-v1.png`.

Plan écrit sur `docs/dossier-j19` à `f9d4ab77`, soit `origin/main` à `440f9b17` (**J15 terminé**,
sauvegarde v7) plus les documents du J19. **Code lu** : `origin/main` à `440f9b17`. Lus sans
modification :
- `origin/docs/dossier-j18` à `ae5053db` : `docs/tech/jalon-18.md`,
  `tools/plans/tour_pokemon_rdc.txt`, `lavanville.txt` et le dossier 21 ;
- `origin/jalon-17` à `369a20e2` : plan seulement, aucun code du J17.

Quand un nom n'existe que dans un plan, il est suivi de « (plan) ». **La tâche d'alignement (T10)
réaligne ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), skills `godot-conventions` et `world-tiles`, `jalon-12.md`
(grottes, étages, cartes générées par outil), `jalon-13.md` (rival à victoire obligatoire,
simulation), `jalon-15.md` (forme, QA, clôture).

---

## 0. État et dépendances

### 0.1 Règle C-7 : le code du moteur commence après la clôture du J18

- **Un seul jalon à la fois dans le moteur de combat et dans la sauvegarde** (C-7). Le J16 (S.S.
  Anne, Major Bob, rival n° 4), le J17 et le J18 passent avant.
- **Les tâches qui touchent `game/battle/`, les directeurs (rencontres, scènes, combat), `boot.gd`
  ou les fichiers du J18 commencent après la clôture du J18.** À ce moment-là, `origin/main` (avec
  J16, J17 et J18) est fusionné dans `jalon-19`. C'est la tâche **T10**.
- **Avant cette clôture**, on n'avance que sur ce qui ne peut pas entrer en conflit (§1.2,
  « peut commencer maintenant ») :
  - la logique pure, dans des fichiers nouveaux ;
  - les données, dans des fichiers nouveaux ;
  - le générateur des cartes 2F à 6F ;
  - l'art.

### 0.2 Ce que le J19 attend des J16, J17 et J18, et quoi faire si c'est absent

Le dossier 22 §3 fixe le principe : **le J19 ajoute ses variantes là où les PNJ existent ; sinon,
il les place lui-même.**

| Le J19 attend | Jalon | État réel (2026-10-15) | Si c'est absent à la clôture du J18 |
|---|---|---|---|
| **Kadabra** (données, art) | J16 | **Déjà sur `main`** : créé au J14 (`data/pokemon/species/kanto_j14.json`, Abra → Kadabra N16). L'artwork officiel n'est pas à vérifier ici : c'est le travail de T3. | Rien à créer. On vérifie seulement l'art de face et le dos (T3). |
| **Rival n° 4** : Roucoups, Rattatac, Kadabra, starter évolué | J16 | Aucune branche de code. Les données attendues sont dans la passe J16 (G-7). | Le n° 5 n'en dépend pas : son équipe est autonome (`team_by_starter`). Seul `prize_per_level` s'aligne sur le n° 4 (§2.6) ; défaut : 35, celui du n° 3. |
| **Coupe** (`cut_cerulean_east_tree`, CS01) | J16 | Absente | Le J19 n'en a pas besoin. Les départs de débogage partent de Lavanville ou de la Tour, sans passer par Azuria. |
| **Flash** (CS05) | J17 / J18 | Absente | Hors J19 : la Tour n'est pas obscure (`dark` absent de `caves.json`). |
| **Lavanville** : `lavender_town`, Centre (point de repos), Boutique, `pokemon_house` (Fuji absent), maisons 1 et 2 | J18 | Plan seulement (`jalon-18.md` §4.1) | Le J19 ne crée pas de ville. Les tâches 19B qui en dépendent (T16, T20) attendent. La QA 19A passe par les départs de débogage dans la Tour. |
| **`pokemon_tower_1f`** : Exorciste `exorciste_gardienne` en (17, 3) `unless=tower_stairs_open` ; escalier (17, 2) en `coming_soon = "Tour Pokémon"` ; sortie (9..10, 16) ; spawn `entree` (9, 16) | J18 | Grille confirmée (`tour_pokemon_rdc.txt`, commit `89b46a9a`) ; carte en plan seulement | T16 attend. Les cartes 2F à 6F se construisent sans elle : la sortie du 2F vers le 1F devient un repli « à venir » (comme le Mont Sélénite au J12). |
| **Planche Exorciste** (`channeler`, marche et prière) | J18 | Prompts poussés (`0dbd1c53`), bruts non branchés | Si elle manque, T8 la produit **avec** le lot du J19 (même prompt, pas de double). Les Exorcistes du J19 la réutilisent telle quelle. |
| **Halo `candle`** (`light_glows.json`) et profil **`tower_cold`** (1F) | J18 | Plan seulement (`jalon-18.md` §4.12, §4.14) | T19 les crée **en fin de fichier**, avec les valeurs du plan du J18 (`candle` = `lamp` plus pâle, vacillement 0,06). Le premier fusionné garde son entrée, l'autre retire son doublon. |
| **Panneau du Scope** : emplacement (42, 11) de `lavanville.txt`, lu depuis (41, 11) → | J18 | Réservé (`panneau_scope_j19`, repère libre) | Le J19 le pose (T20). |
| **Sortie ouest « ROUTE 8 — À venir »** (0, 10..12) | J18 | Plan | Ce n'est pas bloquant pour le J19. La rumeur K-16 ne la suppose pas. |
| **Maison d'Osselait** | J18 → J19 | **Absente de la grille de Lavanville** (dossier 21 §6.2 : « le J19 la placera ») | **Q-2** (§8). Défaut : la fille se tient dans la Maison des Pokémon. |
| Équipe du joueur vers N22–25 | J16–J18 | Inconnue | La simulation (T21) s'appuie sur les équipes de sortie réelles des J16 à J18. Si elles manquent, elle prend l'équipe de référence du J18 (`jalon-18.md` §4.16), augmentée de 1 à 2 niveaux. |

**Si le J18 est en retard sur un point qui n'est pas bloquant**, la tâche concernée avance avec un
bouchon déjà connu du projet : un warp `coming_soon`, ou une variante de dialogue écrite dans un
fichier nouveau qui attend son PNJ. Elle ne recrée jamais une carte du J18.

### 0.3 Points d'accroche : la passe §3 relue sur le code actuel

Les lignes de la passe avaient été relevées sur `origin/main` au J13 (`4f0ee90`). Les voici sur
`440f9b17`.

| Pièce | Passe (J13) | Code actuel (`440f9b17`) | Écart |
|---|---|---|---|
| Tirage d'une rencontre | `encounter_director.gd:181-212` | `_on_player_moved` l. 119, `_can_encounter` l. 143, **`_run` l. 181**, `terrain_at` l. 100 | Seulement des lignes décalées. `terrain_at` ne connaît que `grass` et `rubble` (l. 100-108). |
| « Vu » avant le combat | `encounter_director.gd:189` | **l. 189** (`record_seen`), plus **l. 192** (`record_wild_encounter`, première espèce citée par Chen) | **Écart** : il faut sauter les deux en mode spectre. |
| Conditions des tables | `encounter_library.gd:26-30` | `_KEYS` l. 26, `_OPTIONAL_KEYS = ["ramp"]` l. 29 | **Écart** : une clé facultative existe déjà (`ramp`). `ghost_unless_item` s'ajoute à la même liste. |
| Terrains | `encounter_table.gd:26` | **l. 26** : `[&"grass", &"rubble"]` | Aucun |
| **Montée du taux** (`ramp`) | — | `EncounterTable.effective_rate` (décision de Kevin du 2026-10-02) | **Écart non vu par la passe** : avec une montée, un taux de 10 ne serait plus « RB » (K-10). Défaut : tables de la Tour **sans** `ramp` (§2.2). |
| Nom du sauvage | `pokemon.gd:36` | **l. 36** (`nickname`) | Aucun |
| Sprite adverse | `battle_stage.gd:370-383` | Le choix de l'image est dans **`BattleArt.image`** (`battle_art.gd:61`), appelé par `battle_stage.gd:1218`. L'intro sauvage : `play_wild_intro` l. 461. | **Écart** : l'image se choisit dans `BattleArt`, pas dans la scène. C'est là qu'on accroche la silhouette. |
| Jeton `{species}` | `battle_text.gd:446` | **`_fill` l. 474-492** (`species` l. 481) | Seulement des lignes décalées |
| Carte adverse | `battle_views.gd:84-86` | **`card` l. 84-88** ; le niveau s'affiche dans `battle_info_card.gd` (« Nv. » + valeur) | Le niveau masqué s'écrit « Nv. ?? » (convention de la carte) |
| « Trop effrayé » | `_can_act` (`battle.gd:635-672`) | **`_can_act` l. 672**, `_execute` l. 606 | Seulement des lignes décalées |
| **Ball refusée** | `BALL_BLOCKED` sur `jalon-14` (`battle.gd:1102-1111`) | **Sur `main`** : `_ball_blocked` l. 1374, `BattleEvent.Kind.BALL_BLOCKED` | **Écart important** : `BALL_BLOCKED` vient **après** le retrait de la Ball par le directeur (« la Ball est déjà retirée », l. 1372), et l'adversaire joue ensuite. Il est donc **inutilisable pour K-8**. Le refus se fait dans `BattleDirector`, **avant** `_spend_item` (l. 470), sans tour joué (§2.3). |
| Fuite toujours réussie | `battle_rules.gd:11-27` | Champs l. 11-36, `for_wild` l. 41 ; la fuite est tirée dans `Battle._attempt_flee` l. 377 (`FleeCalc`) | Seulement des lignes décalées |
| IA « message » | IA adverse | `BattleAI.choose` (`battle_ai.gd:71`) ; `Battle._foe_action` l. 475 | Défaut : **pas dans `BattleAI`**. Une action `SPEAK` est imposée par le moteur en mode spectre (§2.3) : aucun tirage n'est consommé. |
| Étape « combat » d'une scène | `cutscene_director.gd:500-516` | **`_battle` l. 508-525** (Dresseurs seulement, par `BattleDirector.run`) | Aucun |
| Recul | `pewter_city.json:12-21` | **l. 12-21** (`route_3_guard` : `move player path ["left"] keep_facing`) | Aucun |
| Soin | `dialogue_runner.gd:339-343` | Action `heal` → `heal_requested` (**l. 351** et **l. 391**) ; `DialogueLibrary.ACTIONS` l. 41 | Seulement des lignes décalées. Le soin part **à la fin** du dialogue (§2.8). |
| Variantes du rival | `trainer_data.gd:46`, `route_24.json:14-55` | **l. 46** ; scène `route_24_rival` **l. 14-50** | Aucun |
| Défaite → dernier Centre | `DefeatRecovery.recover` | **`defeat_recovery.gd:46`** | Aucun |
| Ténèbres | `fixed_damage` `mode:"level"` | `battle.gd:885-904` : l'immunité de type **est déjà appliquée** (multiplicateur 0 → `NO_EFFECT`) | **Rien à coder** : Spectre → Normal vaut 0 (`types.json:46`). |
| Objet clé | `item_data.gd:18-24` | `enum Category` l. 21 ; `Bag` n'est pas lié à `ItemLibrary` (`bag.gd:26`) | Un `silph_scope` brut se met dans le Sac d'un test, sans donnée d'objet (§2.13). |
| Halos | `lighting.json`, `light_glows.json` | `LightGlowLibrary.MAX_PER_MAP = 16` (`light_glow_library.gd:54`) ; `LightGlow.set_reduce_motion` | Aucun |
| **« Vu » d'un combat de Dresseur** | — | **`boot.gd:1360-1363`** : tout `SENT_OUT` adverse est enregistré **hors d'une rencontre** | **Écart non vu par la passe** : le SPECTRE du 6F, lancé par une scène, serait enregistré au Pokédex comme **Ossatueur**. Il faut une garde (§2.3, test dédié). |
| Kadabra | « à créer » | **Existe** (J14) | Aucune espèce de plus à créer |
| Morsure, Onde Folie, Sonicboom (`fixed_damage` `value`) | — | Existent | Draco-Rage = `value` 40 : **rien à coder** |

### 0.4 Écarts et trous du dossier

1. **Learnsets complets** (dossier §12.1 : « données complètes »). Il manque d'autres capacités
   que les six du §12.2. La liste vérifiée sur `main` :
   - Rêve d'Ondine (Fantominus, Spectrum) ;
   - Osmerang et Mania (Mania existe) (Osselait, Ossatueur) ;
   - Hurlement, Bélier (Caninos) ;
   - Pilonnage (Noeunoeuf) ;
   - Ultralaser (Léviator).

   Règle des jalons précédents : la capacité est créée si son effet existe. Sinon, elle est créée
   avec `pending_effects`. Aucune ne peut être apprise par un Pokémon du joueur au J19.
2. **Textes non couverts par le §15** (règle : aucun texte inventé en jeu). Ce sont :
   - 5 entrées de Pokédex ;
   - les descriptions des capacités nouvelles ;
   - le nom affiché « SPECTRE » pour la carte (le §15.3 ne donne que les phrases) ;
   - la forme féminine « effrayée » ;
   - le nom de zone des étages ;
   - les objectifs du tableau de bord ;
   - la phrase de défaite des Exorcistes (`defeated`).

   Brouillons à rédiger en T2 et à valider en une passe (**Q-1**). Cela bloque des données, pas le
   code.
3. **Maison d'Osselait absente** de la grille de Lavanville (§0.2) → **Q-2**.
4. **Gardienne** :
   - au J18, son entrée de PNJ est `unless=tower_stairs_open`. Elle **disparaîtrait** donc au
     J19 ;
   - le dossier §6.4 veut qu'elle reste à côté de l'escalier.

   Le J19 remplace la condition de présence par une **autre place** (`moved`, mécanisme du J14,
   `npc_spec.gd:132-138`).
5. **Rez-de-chaussée** : il n'y a **aucun spawn** à côté de l'escalier (la grille du J18 n'a que
   `entree`). Le J19 ajoute `arrivee_T12` en (17, 3), tourné ↓.
6. **Déclencheurs du rival** : la grille donne (15, 5) « venant de l'est » et (14, 6) « venant du
   sud ». Mais on entre aussi en (15, 5) **depuis le sud** : (15, 6) est praticable. Défaut :
   déclencheurs **sans direction** sur ces deux cases.
7. **« La brume s'épaissit »** (§6.3, étape 1) : aucun système ne le permet. Défaut : une pause
   de 0,6 s et une réaction du joueur (étape `react` existante). Le vrai épaississement est noté
   dans « Reportés » pour la phase DA.
8. **Drapeau du 6F** : le commentaire de la grille dit `ghost_marowak_calmed` « posé au J20 ». Le
   dossier §6.3 et §13 dit **J21**. **Le dossier fait foi.**
9. **Tour dans `caves.json`** (Corde Sortie, dossier §4.1) :
   - les cartes 2F à 6F sont « extérieures » (`interior = false`) comme les grottes, donc le
     compagnon y est visible (dossier §4.1 et §16 n° 6) ;
   - le 1F reste un bâtiment du J18 (`interior = true`, sans Corde : dossier §4.1).

   Le compagnon rentre donc au 1F et ressort au 2F. Défaut : rien de nouveau.

---

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §14, K-20)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **19.0** | Données (espèces, capacités, Pokédex, Exorcistes, rival n° 5 en valeurs RB **provisoires**, tables `floor`) ; logique pure du mode spectre ; terrain `floor` et clé `ghost_unless_item` dans les tables ; lot d'art ; **générateur des cartes 2F à 6F** depuis les grilles ; alignement après le J18 (T10) | Kevin valide la planche d'art et les captures des cartes générées (comme aux J12 et J15). **Aucune session téléphone.** |
| **19A** | **Mode spectre complet** dans le moteur et à l'écran ; étape de scène `wild_battle` ; SPECTRE du 6F et recul ; Exorcistes posés et combattables du 3F au 6F ; départs `tower_ghost_qa`, `tower_6f_block` et `tower_exorcist_weak` | **Téléphone** (S21 ou S24) |
| **19B** | Cartes branchées au 1F (escalier armé, gardienne, `tower_stairs_open`) ; rival n° 5 ; zone purifiée ; objets (dont l'objet caché) ; profil `tower`, halos, brume ; fond CB.3 `tour_pokemon` ; PNJ et variantes de Lavanville ; panneau du Scope ; simulation du rival ; départ `tower_qa` ; **QA de bout en bout** ; clôture | **Téléphone** + fusion |

Règle des trois systèmes :
- **19A** porte **un** système risqué (le mode spectre dans le moteur). L'étape `wild_battle` en
  est la suite directe. Les Exorcistes ne sont que du contenu.
- **19B** n'est que du contenu sur des systèmes existants. Seul ajout : la brume, une couche
  d'affichage.
- **Aucune validation isolée de sauvegarde** : rien ne touche à sa forme (§2.13).

### 1.2 « Peut commencer maintenant » ou « après la clôture du J18 »

| Tâche | Quand | Pourquoi |
|---|---|---|
| T1 branche `jalon-19` | **peut commencer maintenant** | Branche créée depuis `main` |
| T2 textes de l'annexe (Q-1) | **peut commencer maintenant** | Documents seulement |
| T3 espèces, capacités, Pokédex | **peut commencer maintenant** | Fichiers **nouveaux** : `species/kanto_tower.json`, `moves/tower.json`. Seul le Pokédex s'ajoute **en fin** du fichier unique `data/pokedex/kanto.json`. |
| T4 Dresseurs + scénario de simulation | **peut commencer maintenant** | Fichiers nouveaux : `trainers/pokemon_tower.json`, `tools/sim/tower_scenario.json` |
| T5 terrain `floor`, `ghost_unless_item`, tables | **peut commencer maintenant** | Deux classes **pures** de données (`encounter_table.gd`, `encounter_library.gd`), qu'aucun plan des J16 à J18 ne modifie, plus `data/encounters/pokemon_tower.json` (nouveau) |
| T6 logique pure du mode spectre | **peut commencer maintenant** | Fichiers nouveaux : `game/battle/ghost_rule.gd`, `ghost_disguise.gd`. **Aucune** modification de `battle.gd`. |
| T7 kit d'art (référence au manifeste) | **peut commencer maintenant** | La vue générale est validée |
| T8 génération et intégration de l'art | **peut commencer maintenant**, après T7 | Images et entrées **en fin** de manifeste |
| T9 générateur des cartes 2F à 6F | **peut commencer maintenant** | Outil nouveau. Il s'appuie sur `cave_map_kit.gd` sans le modifier, ou par un ajout groupé. L'art peut être provisoire. Les sorties vers le 1F sont en repli « à venir ». |
| T10 alignement | **après la clôture du J18** | Fusion de `main` (J16 à J18) |
| T11 à T24 | **après T10** | Moteur de combat, directeurs, `boot.gd`, fichiers du J18 |

### 1.3 Branches et fichiers chauds

- **Branches** :
  - intégration sur **`jalon-19`**, dans une copie dédiée (mémoire « worktree d'intégration ») ;
  - une branche par tâche (`j19-t<n>-<sujet>`) ;
  - rien n'est fusionné dans `main` avant la clôture (T24).
- **Fichiers nouveaux** de préférence. Les données chargées par dossier vont dans des fichiers
  nouveaux : `species/`, `moves/`, `trainers/`, `encounters/`, `dialogues/`, `npcs/`,
  `cutscenes/`.
- **Fichiers uniques : ajouts en fin de fichier.** Ce sont `data/pokedex/kanto.json`,
  `data/world/caves.json`, `lighting.json`, `light_glows.json`, `zones.json`,
  `data/battle/decors.json`, `messages.json`, `objectives.json`, `tools/art/manifeste.json` et
  `build_character_frames.gd`.
- **Fichiers chauds (après T10 seulement)** :
  - `game/battle/battle.gd`, `battle_director.gd`, `battle_rules.gd`, `battle_event.gd`,
    `battle_action.gd`, `battle_text.gd`, `battle_views.gd`, `battle_art.gd` ;
  - `game/pokemon/encounters/encounter_director.gd`, `game/battle/battle_request.gd` ;
  - `game/systems/cutscene/cutscene_director.gd`, `cutscene_step.gd` ;
  - `game/boot.gd`, `game/systems/debug/debug_start.gd` ;
  - les fichiers du J18 : `tools/build_painted_interiors.gd` (pièce `pokemon_tower_1f`),
    `tools/build_lavender_town.gd` (plan), `data/npcs/pokemon_tower_1f.json`,
    `data/dialogues/pokemon_tower.json`, `data/npcs/lavender_center.json`,
    `data/npcs/pokemon_house.json`.

  Dans ces fichiers, le J19 fait des **ajouts courts et groupés** (un bloc commenté « Tour
  Pokémon (J19) »), jamais de réécriture.

---

## 2. Conception technique

### 2.1 Cartes 2F à 6F : générateur, raccords, catégorie (T9, T16)

**Outil** : `tools/build_pokemon_tower.gd -- --etage=2f|3f|4f|5f|6f|tous` (`extends SceneTree`,
modèle `build_mt_moon.gd`), sur `tools/cave_map_kit.gd`. On utilise les réglages « carte sans
grotte » déjà ouverts par le souterrain du J15 :
- `walkable_marks` = `.ZUV` ;
- sol, canal R et canal G réglables ;
- `rubble_is_logic = false`.

Grilles : `tools/plans/pokemon_tower_<n>f.txt`, lues par `tests/helpers/plan_grid.gd`. **Elles
font foi.**

| Carte | Racine | Taille | Graines [D] | Lumière | `display_name` |
|---|---|---|---|---|---|
| `pokemon_tower_2f` … `6f` | `PokemonTower2F` … `6F` | 20 × 18 | 1901/1902 … 1941/1942 | `tower` (§2.10) | « Tour Pokémon » |

- **`Ground` (invisible)** : la source logique.
  - `.`, `Z`, `U`, `V` = sol ; tout le reste est solide.
  - Aucune herbe et aucun gravat logique : le terrain `floor` ne dépend pas des tuiles (§2.2).
- **Image** :
  - sol peint en dalles ;
  - murs en modules (`relief_mur_tour_*`, comme `place_walls` des grottes) ;
  - tombes `T` et stèles `S` = props bas ; les stèles portent un halo `candle` ;
  - escaliers `U` / `V` ;
  - dalle claire de la zone purifiée (5F) ;
  - voile de pénombre (`tools/cave_shade.gd`), dont l'`ambient` baisse d'étage en étage. C'est lui
    qui fait la gradation (dossier §12.5 : « les étages s'assombrissent peu »).
- **Escaliers** :
  - warps `STEP_ON` sans direction (comme les échelles du J12), selon les paires `T23` … `T56` ;
  - arrivée sur le `spawn` de même paire (`arrivee_T<nn>`, orientation de la grille) ;
  - **T12** : `escalier_bas` du 2F (18, 9) → `pokemon_tower_1f` / `arrivee_T12`. Tant que le 1F
    n'existe pas, c'est un repli `coming_soon = "Tour Pokémon"` ; T16 le remplace ;
  - **T67** : `escalier_7f` (9, 16) → `coming_soon = "Tour Pokémon"`. Il est **inatteignable** au
    J19 (K-13), car le déclencheur (10, 16) recule le joueur.
- **Spawns de QA** [D] : `devant_spectre` (10, 14) ↓ au 6F et `devant_rival` (16, 7) ↑ au 2F.
  `DebugStart` ne lit que des spawns (`debug_start.gd:74`).
- **Cases calmes** (§2.2) : le nouvel `@export var calm_cells: Array[Vector2i]` de `GameMap`
  reçoit les cases `Z` et leurs 8 voisines praticables. L'outil les écrit depuis la grille (5F
  seulement).
- **Déclencheurs** (`EventTriggerPoint`) :
  - zone purifiée (§2.8) ;
  - rival (§2.6) ;
  - SPECTRE du 6F (§2.4).
- **Budget** : ≤ 3 000 nœuds par carte et ≤ 16 halos (`MAX_PER_MAP`).
- **`caves.json` (en fin)** :
  ```json
  "pokemon_tower": { "maps": ["pokemon_tower_2f", …, "pokemon_tower_6f"],
    "escape": { "map": "lavender_town", "spawn": "retour_tour", "facing": "down" } }
  ```
  La Corde Sortie ramène devant la porte. Le 1F n'est **pas** dans la liste : la Corde y est
  refusée (`FieldItemRules`, `NOT_HERE`).
- **`zones.json`** :
  - les cinq cartes s'ajoutent à la zone de la Tour créée par le J18 ;
  - aucune légende ne s'affiche en changeant d'étage ;
  - **aucun nouveau nom de zone** sans Q-1.

### 2.2 Rencontres : terrain `floor` et `ghost_unless_item` (T5, T11)

**Données** (`encounter_table.gd`, `encounter_library.gd`, T5, pures) :
- `EncounterTable.TERRAINS += &"floor"` ;
- `EncounterTable.ghost_unless_item: StringName` (vide = jamais de spectre) ;
- `EncounterLibrary._OPTIONAL_KEYS += "ghost_unless_item"` : un identifiant d'objet non vide. Il
  n'est **pas** vérifié contre `ItemLibrary`, car `silph_scope` est créé au J20 ;
- `WildEncounter.ghost: bool` (faux par défaut) : décidé au tirage, pas par la table seule.

**`data/encounters/pokemon_tower.json`** (dossier §5, poids sur 256, **sans `ramp`** [D]) :

| Table | `maps` | `rate` | Fantominus | Spectrum | Osselait |
|---|---|---|---|---|---|
| `pokemon_tower_low` | `pokemon_tower_3f` | 10 | 18–24, 229 | 25–25, 3 | 20–22, 24 |
| `pokemon_tower_mid` | `pokemon_tower_4f`, `_5f` | 10 | 18–24, 219 | 25–25, 13 | 20–22, 24 |
| `pokemon_tower_high` | `pokemon_tower_6f` | 15 | 19–24, 216 | 26–28, 16 | 22–24, 24 |

Toutes portent `"terrain": "floor"` et `"ghost_unless_item": "silph_scope"`. La table du 7F n'est
**pas** créée. Le 2F n'a aucune table, donc aucune rencontre.

**Directeur** (`encounter_director.gd`, T11) :
- `terrain_at(cell)` : herbe, puis gravats, puis **`floor`**. `floor` s'applique si :
  - la carte a une table `floor` (`_library.has_table`) ;
  - la case n'est pas solide ;
  - elle n'est ni dans `GameMap.calm_cells`, ni sur un warp (`get_warps()`), ni sur un
    déclencheur (`get_triggers()`).
- **Pourquoi exclure les warps et les déclencheurs** : un pas sur un escalier, sur la case du
  rival ou sur celle du SPECTRE ne doit jamais tirer une rencontre. Sinon, l'ordre des
  écouteurs de `moved` déciderait.
- `_on_player_moved` : après `table.roll`,
  `encounter.ghost = GhostRule.is_ghost(table.ghost_unless_item, _state.bag)`. **C'est relu à
  chaque rencontre** : aucun drapeau, aucun cache.
- `_run` en mode spectre :
  - **ni `record_seen` (l. 189), ni `record_wild_encounter` (l. 192)** ;
  - **ni `cry_requested`** ;
  - aucune intro d'herbe ni de gravats : le fondu de combat ordinaire suffit (`floor` : aucun
    effet [D]).
- Hors mode spectre (le Scope dans le Sac, au J20), le terrain `floor` fait une rencontre
  normale, sans intro propre [D].
- `start_encounter` (départs de débogage) passe par le même calcul. La clé `wild` de `DebugStart`
  accepte `ghost_unless_item` (`test_encounter_override_table`).

### 2.3 Le mode spectre (T6 pur, T11 moteur, T12 écran)

**Classes pures (T6, fichiers nouveaux, testables maintenant)** :

```gdscript
# game/battle/ghost_rule.gd — pur
class_name GhostRule
extends RefCounted
## Règle du SPECTRE (dossier 22 §6, K-8, K-9, K-11) : sans l'objet qui révèle, le combat sauvage
## est un combat SPECTRE. Relu à chaque rencontre, jamais un drapeau.
## Vrai si [param item_id] n'est pas vide et que [param bag] ne le contient pas.
static func is_ghost(item_id: StringName, bag: Bag) -> bool
## Le tour du joueur est remplacé par la peur, sauf s'il dort ou s'il est gelé : ces statuts
## gardent leur message (dossier §6.2). Paralysie et confusion : la peur passe avant [D].
static func fear_applies(status: int) -> bool
```

```gdscript
# game/battle/ghost_disguise.gd — pur
class_name GhostDisguise
extends RefCounted
## Masque d'identité du SPECTRE : pseudo-espèce de l'image, niveau masqué, marquage de
## l'événement. Le moteur l'applique à tout événement du camp adverse d'un combat SPECTRE.
const SPECIES: StringName = &"ghost_disguise"
const TEXTURE_PATH: String = "res://assets/sprites/battle/spectre.png"   # lot 19.0
static func mask(event: BattleEvent) -> void   # species_id = SPECIES, level = 0, disguised = true
```

**Moteur (T11, après T10)** :

| Fichier | Changement |
|---|---|
| `battle_rules.gd` | `var ghost: bool` ; `var flee_always: bool` ; `static func for_ghost(items) -> BattleRules` : `wild` = vrai, `can_flee` = vrai, `flee_always` = vrai, `gives_exp` = faux, `allow_balls` = vrai (le Sac s'ouvre ; c'est le refus qui parle), `allow_heal_items` = vrai |
| `battle_request.gd` | `wild(encounter, …)` : `rules = for_ghost(items)` si `encounter.ghost` |
| `battle_action.gd` | `Kind.SPEAK` **en fin d'enum** ; `static func speak()` |
| `battle_event.gd` | `Kind.GHOST_SCARED`, `Kind.GHOST_SPOKE` **en fin d'enum** ; `var disguised: bool` |
| `battle.gd` | (1) `_pokemon_event` : si `_rules.ghost` et camp adverse, `GhostDisguise.mask(event)`. (2) `_foe_action` : si `_rules.ghost`, `BattleAction.speak()` (ni IA ni tirage). (3) `_execute` : une action `SPEAK` donne `GHOST_SPOKE`, rien d'autre ; un `MOVE` du joueur en mode spectre passe d'abord le contrôle sommeil / gel (`StatusRules.check_act` seulement si `not GhostRule.fear_applies(status)`), sinon `GHOST_SCARED` : aucun PP, aucun tirage, la confusion n'est pas décomptée [D]. (4) `_player_goes_second` : le joueur d'abord en mode spectre (`SPEAK` n'a pas de capacité). (5) `_attempt_flee` : si `flee_always`, `FLED` sans `FleeCalc` (aucun tirage). (6) `is_legal(ITEM)` : faux pour une Ball si `_rules.ghost` ; `func refuses_balls() -> bool`. La fin de tour (`_end_turn`) reste la même : le poison et la brûlure du joueur s'appliquent [D, dossier §16 n° 3]. |
| `battle_director.gd` | (1) `run_request` : si `request.rules.ghost`, `foe.nickname = _texts.get_template(&"ghost_name")`. Tous les textes et la carte affichent alors « SPECTRE » sans autre branchement. (2) `_choose_action` : si `_choose_item` rend une Ball et `_battle.refuses_balls()`, afficher `ghost_ball_refused` puis `continue`. **Ni `_spend_item`, ni tour.** (3) `func run_wild(encounter: WildEncounter, map: GameMap, origin: Vector2i) -> int` : construit `BattleRequest.wild` et appelle `run_request` (pour l'étape de scène, §2.4). |
| `boot.gd` | `_on_battle_event` (l. 1360) : **ignorer un événement `disguised`**. C'est la garde du Pokédex pour le 6F. |
| `battle_text.gd` | `SENT_OUT` adverse `disguised` : `ghost_appeared`, puis `ghost_unidentified` (au lieu de `wild_appeared`) ; `GHOST_SCARED` : `ghost_scared` (forme féminine si Q-1) ; `GHOST_SPOKE` : `ghost_spoke`. La fuite garde le message existant (§15.3.6). |
| `battle_views.gd` / `BattleCardView` | `card(event)` : `level_hidden = event.disguised` ; la carte écrit « Nv. ?? » [D]. |
| `battle_art.gd` | `image(GhostDisguise.SPECIES, false)` : la silhouette (linéaire, taille de référence). Elle n'existe pas en dos. |
| `data/battle/messages.json` | `ghost_name` (Q-1), `ghost_appeared` (§15.3.1), `ghost_unidentified` (15.3.2), `ghost_scared` (15.3.3), `ghost_spoke` (15.3.4), `ghost_ball_refused` (15.3.5) ; mot pour mot |

**Fin du combat** :
- issue `FLED` : ni XP, ni argent, ni bilan (`shows_progress` est faux), ni Grand moment ;
- `BattleConclusion` reste la même (sauvage : rien) ;
- une équipe entière K.O. par le poison est la seule défaite possible. C'est alors le chemin
  ordinaire : `LOSS`, puis `DefeatRecovery` (règle du J15 T24).

**Ce qui n'est jamais montré** :
- l'espèce réelle : ni nom, ni image, ni niveau, ni cri, ni Pokédex ;
- l'objet du Pokémon tiré est jeté à la fin du combat.

Test de garde : **aucun texte, aucune carte, aucune image et aucune entrée de Pokédex d'un combat
SPECTRE ne contient le nom ou l'identifiant de l'espèce tirée** (§5).

### 2.4 Étape de scène `wild_battle` et SPECTRE du 6F (T13, T14)

**Étape** (`cutscene_step.gd`, `Kind.WILD_BATTLE` **en fin d'enum**) :

```json
{ "wild_battle": "marowak", "level": 30, "ghost": "always",
  "win": [], "lose": [] }
```

**`"ghost": "always"`** (décision de Claude, 2026-10-15, conforme aux dossiers 22 et 23) : le
SPECTRE du 6F reste masqué **même avec `silph_scope`**, aux J19 et J20. Le J21 (dossier 24) changera
cette **donnée** de scène (`"ghost_unless_item": "silph_scope"` ou une variante conditionnée), sans
migration de sauvegarde. Les deux clés sont acceptées par l'étape : `ghost` (`"always"`) et
`ghost_unless_item` (comme les tables).

```json
```

`CutsceneDirector._wild_battle(step)` :
1. construit un `WildEncounter(species, level, &"cutscene")` ;
2. calcule `ghost = GhostRule.is_ghost(step.ghost_unless_item, _bag)` ;
3. appelle `_battle_runner.run_wild(encounter, _map, origin)`, où `origin` = la case du joueur plus
   son orientation [D] ;
4. sur `LOSS` : réveil par le `DefeatRecovery` (comme `wake_up`), puis **la scène s'arrête** ;
5. pour les autres issues, les drapeaux `win` / `lose` sont facultatifs (prévus pour le J21).

L'espèce et le niveau sont validés par `PokemonData` au chargement de la scène.

**Scène du 6F** (`data/cutscenes/pokemon_tower_floors.json`, `tower_6f_ghost`). Déclencheur
`declencheur_spectre` en (10, 16), sans direction. Variante `unless: [ghost_marowak_calmed]` : le
drapeau est **lu** ici, jamais posé (J21).

```text
react player (surprise) ; wait 0.6                     # « la brume s'épaissit » [D], §0.4 n° 7
dialogue tower_6f_ghost_warning                        # §15.3.7 « …Va-t'en… Intrus… »
wild_battle marowak 30, ghost always                   # §6.2 ; jamais nommé, montré ni enregistré
move player path ["up"] keep_facing                    # recul vers (10, 15) (grille)
dialogue tower_6f_ghost_after                          # §15.3.8
```

- Le déclencheur se réarme seul : la variante dépend d'un drapeau jamais posé.
- **Au J20**, le joueur a le Scope : la rencontre de la scène devient **non spectre**. Cela
  contredirait le dossier §6.3 (« le SPECTRE du 6F reste un blocage au J20 ») ; **la session J20
  doit donc changer cette étape.** Notée en passation (§9 de la clôture, T24) : le J19 ne
  présume pas du J21.
- Compagnon : il suit le joueur repoussé. L'échange de places est la règle du J11 (dossier §16
  n° 6 et 7).

### 2.5 Exorcistes (T4 données, T14 cartes)

- **`data/trainers/pokemon_tower.json`** : `tower_channeler_1` … `_9`.
  - nom : « Exorciste <Prénom> » ;
  - équipes : dossier §8 ;
  - `ai: random`, `prize_per_level: 30`, aucune `moves` (capacités naturelles au niveau :
    Léchouille, Onde Folie, Ténèbres).
- **PNJ** : `data/npcs/pokemon_tower_3f.json` … `_6f.json`.
  - bloc `trainer` aux cases, orientations et vues (`sight`) de la grille ;
  - apparence `channeler` (J18).
- **Dialogues** : `data/dialogues/pokemon_tower_floors.json`.
  - `before` = §15.4, lignes 1 à 9, avec la **voix d'esprit** (page `"voice": "spirit"`, T12) ;
  - `after` = la réplique « après le combat » du §15.4 (E1, E3, E5, E9 ; la variante unique pour
    les autres) ;
  - `defeated` (fin du combat) : la même réplique [D, ou Q-1].
- **Inévitables** : E3, E8 et E9, vérifiés **sur la vraie scène avec ses PNJ** (recherche de
  chemin hors des vues, comme `test_route_6_trainers`).
- **Défaite** : réveil au dernier point de repos (normalement le Centre de Lavanville). Les
  Exorcistes battus le restent (`beaten_<id>`).
- **Pokédex** : Fantominus et Spectrum « vus » par le chemin habituel des Dresseurs
  (`boot.gd:1360`).

### 2.6 Rival n° 5 (T4 données, T17 scène, T21 niveaux)

- **`data/trainers/pokemon_tower.json`**, entrée `rival_tower`. On recopie le gabarit de
  `rival_cerulean` : `name: "{rival}"`, `ai: smart`, `switch: true`, `moment: "win"`,
  `gives_exp: true`, `bag: true`.
- **`prize_per_level`** :
  - celui du n° 4 si le J16 l'a fixé ;
  - sinon 35 [D], celui du n° 3 (≈ 875 ₽ à N25 ; repère RB : 1 625 ₽).
- **`team_by_starter`** (dossier §7.3, **RB provisoire** jusqu'à T21) :
  - `bulbasaur` : Roucoups 25, Noeunoeuf 23, Léviator 22, Kadabra 20, Reptincel 25 ;
  - `charmander` : Roucoups 25, Caninos 23, Noeunoeuf 22, Kadabra 20, Carabaffe 25 ;
  - `squirtle` : Roucoups 25, Léviator 23, Caninos 22, Kadabra 20, Herbizarre 25.
- **Pas de Rattatac**, et aucune ligne n'en parle.
- **Capacités choisies à la main** quand une mécanique manque :
  - Caninos : Hurlement remplacé (aucun effet contre un Dresseur), par exemple par Groz'Yeux ;
  - Léviator : sans Hydrocanon ni Ultralaser, mais Morsure, Draco-Rage et Groz'Yeux ;
  - Kadabra : règle du J16, sinon Choc Mental, Entrave et Téléport.

  Le choix final revient à T21.
- **PNJ** (`data/npcs/pokemon_tower_2f.json`) : `tower_rival` en (14, 5), tourné ←, `unless:
  [rival_tower_won]`, apparence `rival`.
- **Déclencheurs** : (15, 5) et (14, 6), **sans direction** (§0.4 n° 6).
- **Scène** `tower_rival` : motif J13 (`route_24.json:14-50`). Variante `unless:
  [rival_tower_won]` :

```text
face tower_rival → player ; face player → tower_rival
dialogue rival_tower_intro    (§15.2.1–3)   unless rival_tower_lost_once
dialogue rival_tower_resume   (§15.2.6)     if rival_tower_lost_once
set [rival_tower_retried]                    if rival_tower_lost_once
battle rival_tower  win [rival_tower_won]  lose [rival_tower_lost_once]
wait 2.0                                     if rival_tower_won    # silence [D] §7.1
dialogue rival_tower_won      (§15.2.4–5)   if rival_tower_won
move tower_rival to [17, 9] ; despawn        if rival_tower_won    # « il descend » [D]
dialogue rival_tower_lost     (§15.2.7)     unless rival_tower_won
wake_up                                      unless rival_tower_won
```

- **Grand moment** `rival_battle` : seulement à la victoire, une fois (`RivalMoment`,
  `moment: "win"`).
- **Contrat de sortie vers le J20** : `rival_tower_won` posé.

### 2.7 Gardienne du rez-de-chaussée (T16, fichiers du J18)

- **`data/npcs/pokemon_tower_1f.json`**, entrée `exorciste_gardienne` :
  - on retire `unless: [tower_stairs_open]` ;
  - on ajoute `moved: { if: [tower_stairs_open], cell: [18, 3], facing: left }` [D : une case à
    droite, tournée vers l'escalier].
- **Dialogues** (`data/dialogues/pokemon_tower.json`, bloc J19) :
  - variante `if tower_stairs_open` → §15.1.5 ;
  - variante `unless tower_stairs_open` → `cutscene: tower_guardian`. Lui parler joue la scène, si
    le joueur a chargé une partie déjà dans la salle.
- **Déclencheur** (9..10, 15), direction ↑ : c'est le premier pas depuis l'entrée. Il est ajouté à
  la pièce `pokemon_tower_1f` de `build_painted_interiors.gd`.
- **Scène `tower_guardian`**, variante `unless: [tower_stairs_open]` :
  - `face` → `player` ;
  - `dialogue tower_guardian_worried` (§15.1.1–4) ;
  - `move exorciste_gardienne path ["right"]` ;
  - `face` ← ;
  - `set [tower_stairs_open]`.
- **Escalier (17, 2)** : on retire `coming_soon`. Il mène à `pokemon_tower_2f` / `arrivee_T12`.
- **Spawn** `arrivee_T12` en (17, 3), tourné ↓, pour le retour depuis le 2F.
- **Objectifs** (J18) : `visit_tower`, `tower_later`. **Q-1** pour ceux du J19. Défaut : aucun
  objectif nouveau, ceux du J18 inchangés.

### 2.8 Zone purifiée (T18)

- **Le réarmement sans code.** Le soin ne doit partir qu'en **entrant** dans la zone. Il ne doit
  pas repartir quand on se déplace à l'intérieur. On le règle par des **déclencheurs à
  direction**, déjà gérés par `TriggerTable` : chaque case `Z` reçoit un déclencheur pour **chaque
  direction qui vient d'une case hors de la zone**. Avec la grille du 5F :

  | Case | Directions qui viennent du dehors |
  |---|---|
  | (10, 8) | → |
  | (10, 9) | →, ↑ |
  | (11, 9) | ←, ↑ |
  | (11, 8) | ← (depuis (12, 8), occupée par l'Exorciste calme) |

  Un pas d'une case `Z` à une autre ne correspond à aucun déclencheur. L'outil (T9) les calcule
  depuis la grille, et un test les vérifie.
- **Scène `tower_purified_zone`** :
  1. `flash` 1 [D : le fondu blanc court réutilise l'éclair adouci du J14, qui respecte
     « Réduire les animations »] ;
  2. `dialogue tower_purified_zone_heal` (§15.5.1, `action: heal`) ;
  3. `dialogue tower_purified_zone_done` (§15.5.2).

  Deux dialogues : le soin part à la fin du premier, **avant** la phrase « entièrement soignée ».
- **Ce que ce n'est pas** : pas un point de repos. `heal_map` et `heal_spawn` restent inchangés
  (test).
- **Ni rencontre, ni vue** :
  - aucune rencontre : cases `Z` et voisines dans `calm_cells` (§2.2) ;
  - aucune vue de Dresseur : géométrie vérifiée par `plan_check` (critère 8), puis sur la vraie
    scène (T18).
- **Halo** : un halo blanc fixe, de type `purified` [D] (`light_glows.json`, en fin, `flicker`
  0, `blend: mix`).
- **Exorciste calme** : en (12, 8), §15.4 « Cette dalle a été bénie… ».

### 2.9 Objets (T18)

Les objets visibles sont des PNJ objets (modèle du J12). Les drapeaux sont `got_<id>`. Les
identifiants et les cases viennent de la grille.

| Étage | Objet | Case |
|---|---|---|
| 3F | `tower_3f_objet_1` : Corde Sortie | (12, 1) |
| 4F | `tower_4f_objet_1` : Réveil | (9, 10) |
| 4F | `tower_4f_objet_2` : Super Potion | (12, 10) |
| 5F | `tower_5f_objet_1` : Pépite | (6, 14) |
| 6F | `tower_6f_objet_1` : Super Potion | (14, 14) |
| 5F | **caché** `tower_5f_cache_1` : Super Potion | (4, 11) |

Objet caché :
- c'est le modèle `_add_hidden_item` du J13 : point EXAMINER sur la case-indice, `unless_flags =
  [got_tower_5f_cache_1]` ;
- la grille met l'objet en (4, 11), alors que le dossier §4.2 dit (4, 12). **La grille fait
  foi** ;
- la case-indice est l'« offrande fanée » ; la case d'où on la lit est choisie par T9 sur un
  voisin praticable [D].

Le dossier §4.2 dit « Super Potion si le J15 l'a créée » : c'est le cas (`data/items/vermilion.json`).

### 2.10 Lumière, halos, brume, fond de combat, performances (T19)

- **`lighting.json` (en fin)** :
  - profil `tower`, gris violacé, doux et lisible. Il part de `tower_cold` (J18) ou de
    `interior_warm` sans chaleur [D, réglé sur capture] ;
  - `maps` : les cinq étages.

  La gradation passe par l'`ambient` du voile, étage par étage [D : 2F 0,96 → 6F 0,88].
- **Halos** : `candle` sur chaque stèle `S` (2 par étage), `purified` au 5F, ≤ 16. Le
  battement de `candle` est coupé par `LightGlow.set_reduce_motion` (existant).
- **Brume** : `game/world/lighting/mist_layer.gd` (`class_name MistLayer`, `extends Sprite2D`) et
  son shader `shaders/mist_scroll.gdshader`.
  - une texture qui se répète (512 px, lot d'art), décalée lentement (UV + `TIME`) ;
  - alpha ≤ 0,2 [D], posée **sous les personnages** (au-dessus du sol), pour que les personnages
    restent lisibles ;
  - une seule par carte, à la taille de la carte ;
  - « Réduire les animations » **la cache** (dossier §4.1 : « coupe la brume ») ;
  - `set_process(false)` : aucun `_process`, le shader fait tout.
- **Interdits** : aucune `Light2D` (les tests existants le refusent) ; aucune particule au J19
  [D, les « quelques particules » du §11 vont à la phase DA].
- **Fond CB.3 `tour_pokemon`** (`decors.json`, en fin) :
  - un décor (dalles, stèles, brume) ;
  - `places` pour les cinq étages, valable pour les sauvages, les Exorcistes, le rival et le
    SPECTRE.
- **Mesures S24 / S21** : ≥ 58 fps de moyenne, creux ≥ 50 (règle du J15), au 6F avec brume et
  halos ; changement d'étage ≤ 1,5 × celui de Jadielle ; journal `[perf]`.

### 2.11 Lavanville au J19 (T20, fichiers du J18)

| PNJ / objet | Fichier | Contenu |
|---|---|---|
| Enfant, Maison des Pokémon (J18) | `data/dialogues/lavender_houses.json` (bloc J19) | On **remplace** T-25 par §15.6.1. T-26 garde sa place [D : elle ne parle pas de Fuji au présent]. |
| **Homme**, Maison des Pokémon (nouveau) | `data/npcs/pokemon_house.json` | §15.6.2 ; case libre de la pièce [D] |
| **Fille, maison d'Osselait** (nouvelle) | selon **Q-2** ; défaut `pokemon_house.json` | §15.6.3 ; sans Osselait visible (aucun art au J19) |
| **Gentleman**, Centre de Lavanville (nouveau) | `data/npcs/lavender_center.json` | §15.6.4 (rumeur K-16) ; apparence existante (`traveler` ou `old_man`) [D] |
| **Panneau du Scope** | `tools/build_lavender_town.gd` (plan) + `data/dialogues/lavender_town.json` | Prop bloquant en (42, 11), EXAMINER depuis (41, 11) →, §15.6.5 |
| Légende de la Tour | — | inchangée (§15.6.6) |

Les variantes sont actives **dès la build J19, sans drapeau** (dossier §10).

**Garde de la décision 7** : test « le mot « Rocket » n'apparaît dans aucun texte ajouté par le
J19 ».

### 2.12 Espèces, capacités, Pokédex (T3)

- **`data/pokemon/species/kanto_tower.json`** :

  | Espèce | N° | Types | Évolution |
  |---|---|---|---|
  | `gastly` | 92 | ghost, poison | → `haunter` N25 |
  | `haunter` | 93 | ghost, poison | aucune (pas d'échange) |
  | `cubone` | 104 | ground | → `marowak` N28 |
  | `marowak` | 105 | ground | — |
  | `growlithe` | 58 | fire | pierre absente : aucune |
  | `gyarados` | 130 | water, flying | — |
  | `exeggcute` | 102 | grass, psychic | pierre absente : aucune |

  Statistiques, taux et learnsets complets ; valeurs **actuelles** (précédent du J16).
- **`data/pokemon/moves/tower.json`** :

  | Capacité | Valeurs | Effet |
  |---|---|---|
  | `lick` | Spectre, 30, 100 %, 30 PP | paralysie 30 % |
  | `night_shade` | Spectre | `fixed_damage` `level` |
  | `hypnosis` | Psy, 60 % | sommeil |
  | `bone_club` | Sol, 65, 85 % | peur 10 % |
  | `dragon_rage` | Dragon | `fixed_damage` `value` 40 |

  On y ajoute celles du §0.4 n° 1 (effet existant ou `pending_effects`). `bite` et `confuse_ray`
  existent déjà.
- **Pokédex** (`data/pokedex/kanto.json`, en fin) : `gastly`, `haunter`, `growlithe`, `gyarados`,
  `exeggcute` (textes : Q-1). `cubone` et `marowak` attendent le J20 / J21 (dossier §12.1).
- **Art** :
  - face : artwork officiel (existant pour 92, 93, 104, 105 ; à vérifier pour 58, 102, 130) ;
  - dos : Fantominus (lot), Spectrum (`dos_ia_093` provisoire), Caninos, Léviator et Noeunoeuf
    (provisoires suffisants : espèces de Dresseur) ;
  - Osselait et Ossatueur : **aucun** au J19, ils ne s'affichent jamais. `test_battle_art` doit
    les tolérer (liste d'exceptions « jamais affichés au J19 »).
- **Compagnon** : aucune entrée dans `companions.json` (non capturables).

### 2.13 Sauvegarde : **aucun changement de version** (v7 depuis le J15)

- `SaveSystem.VERSION` reste **7** (`save_system.gd:36`).
- Le J19 n'ajoute que des **drapeaux** (`StoryFlags`, déjà sérialisés) :
  - `tower_stairs_open` ;
  - `rival_tower_won`, `rival_tower_lost_once`, `rival_tower_retried` ;
  - `beaten_tower_channeler_1` … `_9` ;
  - `got_tower_3f_objet_1`, `got_tower_4f_objet_1`, `_2`, `got_tower_5f_objet_1`,
    `got_tower_5f_cache_1`, `got_tower_6f_objet_1`.
- **Le mode spectre lit le Sac, jamais un drapeau.**
- **Réservés au J21, jamais posés ni lus par une donnée du J19** : `ghost_marowak_calmed` (lu
  seulement en `unless` de la scène du 6F), `fuji_rescued`, `got_poke_flute`,
  `beaten_tower_rocket_1..3`.
- **Tests de non-régression** (`tests/unit/test_save_j19.gd`, modèle `test_save_j13`) :
  1. `test_the_jalon_19_adds_no_save_version` : `VERSION == 7` ;
  2. chaque drapeau du J19 survit à un aller-retour ;
  3. une sauvegarde v7 du J15 (fixture existante) se charge sans changement ;
  4. **une partie J19 sauvegardée au 6F, rechargée avec `silph_scope` ajouté au Sac, donne des
     rencontres normales** (§5) ;
  5. un identifiant d'objet encore inconnu (`silph_scope`) survit à un aller-retour du Sac. Sinon,
     le test 4 utilise une donnée de test, et l'écart est signalé au J20.

### 2.14 Départs de débogage (`tools/debug_start/`, README complété)

Équipe de référence [D, recalée par T21] :
- starter évolué N25 ;
- Roucoups N22 ;
- Papilusion N21 ;
- un Pokémon **empoisonné** (Rattata N20) ;
- un Pokémon **endormi** (Nidorino N21, `status_turns` 3) ;
- un Pokémon **Normal** (pour Ténèbres sans effet).

Sac : 10 Poké Balls, 5 Super Potions, 3 Antidotes, 2 Réveils, 2 Cordes Sortie. Argent : 3 000 ₽.
Badges Roche et Cascade (plus Foudre si le J16 est fusionné). Drapeaux du J18 jusqu'à
`tower_medium_talked`.

| Départ | Sous-jalon | Contenu |
|---|---|---|
| `tower_ghost_qa` | 19A | 3F, `arrivee_T23`, `tower_stairs_open`. Clé `wild` : table réelle avec `"terrain": "floor"`, `"ghost_unless_item": "silph_scope"` et **taux 60**. Exorcistes du 3F non battus. |
| `tower_6f_block` | 19A | 6F, spawn `devant_spectre` (10, 14) ; E8 et E9 battus ; **rival non battu** (dossier §16 n° 10). |
| `tower_exorcist_weak` | 19A | 4F, `arrivee_T34`, Salamèche N4 seul : défaite contre E3 → réveil au Centre de Lavanville (ou au dernier Centre), E3 toujours à battre. |
| `tower_qa` | 19B | Lavanville devant la Tour (`retour_tour`), rien du J19 posé : parcours complet de 1F à 6F. |
| `tower_rival` | 19B | 2F, spawn `devant_rival`, `tower_stairs_open`. |
| `tower_rival_weak` | 19B | Idem, Salamèche N6 seul : défaite → §15.2.7 → réveil ; retour : §15.2.6. |
| `tower_5f_zone` | 19B | 5F, `arrivee_T45`, deux Pokémon blessés, un K.O. |

### 2.15 Art (lot 19.0, T7, T8)

Fiche `docs/tech/serie-<n>-tour-pokemon.md` (le prochain numéro libre, vérifié sur toutes les
branches à T7), script `tools/art/serie<n>.py` (`--prompts`, `--refs`, `--planche`,
`--manifeste`, `--controle`), entrées **en fin** de `tools/art/manifeste.json`. **Ce plan ne
produit aucune image.** Le lot du dossier §12.4 :
- **Cartes** :
  - sol en dalles (base, canal R pour l'usure, canal G pour les masses) ;
  - modules de mur ;
  - tombe basse, stèle à bougie ;
  - escaliers montant et descendant ;
  - dalle bénie de la zone purifiée ;
  - texture de brume qui se répète.
- **Lavanville** : panneau du Scope (prop).
- **Personnages** :
  - planche Exorciste (J18, réutilisée ; produite ici si le J18 ne l'a pas fait) ;
  - silhouette SPECTRE de combat (une planche, brume violette, sans yeux lisibles, sans contour
    noir) : `assets/sprites/battle/spectre.png`.
- **Pokémon** : dos de Fantominus.
- **Combat** : fond CB.3 `tour_pokemon`.

---

## 3. Tâches

Chaque tâche :
- part d'une branche `j19-t<n>-<sujet>` créée depuis `jalon-19` ;
- n'utilise jamais `pkill` (arrêter ses propres processus par PID) ;
- reprend les textes **mot pour mot** (dossier §15 et annexe validée) ;
- met à jour `docs/tech/etat-projet.md` dans son commit ;
- **CA communs** : `tools/test.sh` vert, `godot --headless --path . --import` sans `ERROR`.

Agents : **A** architecte-godot, **C** constructeur-monde, **U** ui-mobile, **Q** qa-mobile, **K**
Kevin.

### 3.1 Sous-jalon 19.0 (données, logique pure, cartes, art)

#### T0 — A : plan (ce document)

#### T1 — A : branche `jalon-19` — **peut commencer maintenant**
- Créer `jalon-19` depuis `origin/main` dans une copie dédiée. Y fusionner `docs/dossier-j19`
  (dossier, grilles, plan).
- **CA** : tests verts, import propre.

#### T2 — A puis K : textes de l'annexe (Q-1) — **peut commencer maintenant**
- Brouillons dans une annexe de ce plan :
  - 5 entrées de Pokédex (taille, poids officiels, description) ;
  - descriptions des capacités nouvelles ;
  - `ghost_name` (« SPECTRE ») ;
  - la forme « effrayée » ;
  - la phrase `defeated` des Exorcistes ;
  - les objectifs du J19 ;
  - le nom de zone des étages s'il en faut un.
- **CA** : Kevin valide en une passe. Cela bloque les données qui en dépendent (T3, T4, T11), pas
  le code.

#### T3 — A : espèces, capacités, Pokédex — **peut commencer maintenant**
- Fichiers : `data/pokemon/species/kanto_tower.json`, `data/pokemon/moves/tower.json`,
  `data/pokedex/kanto.json` (en fin).
- §2.12. Artworks de face des 7 espèces présents (`assets/sprites/pokemon/official/`) ; dos
  provisoires.
- **Tests** :
  - `test_pokemon_data` (compte d'espèces recalé ; types Spectre / Poison ; évolutions de
    Fantominus N25 et Osselait N28 ; Spectrum, Caninos, Noeunoeuf et Léviator sans évolution) ;
  - `tests/unit/test_tower_moves.gd` :
    - Léchouille paralyse ;
    - Ténèbres fait des dégâts égaux au niveau et **aucun dégât** sur un type Normal ;
    - Hypnose endort ;
    - Massd'Os apeure ;
    - Draco-Rage fait 40 ;
    - Léchouille est super efficace sur un type Psy (valeurs actuelles) ;
  - `test_pokedex_library` (5 entrées) ;
  - `test_battle_art` (exceptions Osselait et Ossatueur).
- **CA** : aucune carte touchée.

#### T4 — A : Dresseurs et scénario de simulation — **peut commencer maintenant**
- Fichiers : `data/trainers/pokemon_tower.json` (9 Exorcistes + `rival_tower`, RB provisoire,
  §2.5, §2.6) ; `tools/sim/tower_scenario.json`.
- Le scénario sert à `tools/simulate_mt_moon.gd` (générique depuis le J13 ; méthode
  `simulate_brock.gd`). Il contient :
  - les équipes de sortie supposées du J18 ;
  - les Exorcistes inévitables (E3, E8, E9) ; les facultatifs en `optional` ;
  - le rival à `team_by_starter`, avec les trois starters ;
  - aucune étape `wild` (les spectres ne donnent rien).
- **Tests** :
  - `tests/unit/test_trainers_j19.gd` :
    - 10 Dresseurs valides ;
    - récompense 30 × niveau du dernier ;
    - aucune `pending_effects` au niveau donné ;
    - aucun Rattatac dans `rival_tower` ;
    - trois variantes de cinq Pokémon ;
    - `moment: "win"` ;
  - `test_trainer_library`.
- **CA** : `simulate_mt_moon.gd -- --scenario=tower --valider` ne signale rien.

#### T5 — A : terrain `floor`, `ghost_unless_item`, tables — **peut commencer maintenant**
- Fichiers : `game/pokemon/encounters/encounter_table.gd`, `encounter_library.gd`,
  `wild_encounter.gd` (champ `ghost`), `data/encounters/pokemon_tower.json` (§2.2).
- **Tests** :
  - `test_encounter_table` (`floor` accepté ; `ghost_unless_item` relu) ;
  - `test_encounter_library` :
    - tables de la Tour valides ;
    - poids 229/3/24, 219/13/24, 216/16/24 ;
    - **pas de `ramp`** ;
    - un `ghost_unless_item` vide est refusé ;
    - un objet inconnu est accepté ;
  - `tests/unit/test_tower_encounters.gd` :
    - aucune table pour le 2F ni le 7F ;
    - fréquences relatives sur 10 000 tirages avec une graine fixe (≈ 89 %, 86 %, 84 % de
      Fantominus) ;
  - `test_encounter_override_table` (clé `ghost_unless_item` dans `wild`).
- **CA** : `encounter_director.gd` n'est **pas** touché (T11).

#### T6 — A : logique pure du mode spectre — **peut commencer maintenant**
- Fichiers : `game/battle/ghost_rule.gd`, `game/battle/ghost_disguise.gd` (§2.3).
- **Tests** (`tests/unit/test_ghost_rule.gd`) :
  - `is_ghost` : vrai sans l'objet ; faux avec ; faux pour un identifiant vide ; **relu à chaque
    appel** (on ajoute l'objet entre deux appels → faux) ;
  - `fear_applies` : faux pour sommeil et gel ; vrai pour aucun statut, poison, brûlure,
    paralysie ;
  - `GhostDisguise.mask` : espèce masquée, niveau 0, `disguised`.
- **CA** : aucun fichier existant de `game/battle/` n'est modifié.

#### T7 — A : kit d'art (référence au manifeste) — **peut commencer maintenant**
- §2.15. Fiche, prompts, planche `build/art/J19_KIT_v1.png`.
- **CA** : chaque élément visible de la vue générale validée a un asset (réutilisé, varié ou
  nouveau), ou il est abandonné explicitement. Écarts de la vue gardés (dossier §12.5 : spectre
  sans silhouette humaine).

#### T8 — C (Mac, Codex) : génération, planche de contact → K, intégration — après T7
- Génération, planche de contact, validation de Kevin, puis intégration :
  - entrées en fin de manifeste ;
  - `preparer.py` ;
  - `build_painted_props.gd -- --nouveaux` ;
  - `build_character_frames.gd` (`channeler` si absent) ;
  - silhouette et fond CB.3.
- **CA** : un second passage ne change rien ; `test_painted_props` vert.

#### T9 — C : générateur des cartes 2F à 6F — **peut commencer maintenant** (art provisoire accepté)
- `tools/build_pokemon_tower.gd` (§2.1) ; `game/world/maps/pokemon_tower_2f.tscn` … `6f.tscn` ;
  `GameMap.calm_cells` (`game/world/map.gd`, **un seul `@export` ajouté** ; c'est le seul
  fichier existant touché, et aucun plan des J16 à J18 ne le modifie).
- Rien d'autre :
  - aucun PNJ ;
  - aucune scène ;
  - aucune table branchée ;
  - les déclencheurs sont posés vers des scènes encore absentes (sans effet tant que la scène
    n'existe pas, comportement existant de `CutsceneDirector`) ;
  - le 2F vers le 1F, et le 6F vers le 7F, en `coming_soon`.
- **Tests** (`tests/integration/test_pokemon_tower_maps.gd`, modèle `test_mt_moon_maps`) :
  - grille de la scène = grille du plan (praticables, solides) ;
  - paires d'escaliers aller-retour (T23 à T56), arrivée sur la bonne case et la bonne
    orientation ;
  - `calm_cells` du 5F = cases `Z` + 8 voisines praticables ; vide ailleurs ;
  - **déclencheurs à direction de la zone purifiée** = tableau du §2.8 ;
  - déclencheurs du rival sans direction ; déclencheur du SPECTRE en (10, 16) ;
  - escalier du 7F atteignable seulement par (10, 16) ;
  - ≤ 3 000 nœuds, ≤ 16 halos, **aucune `Light2D`** ;
  - `interior == false`.
- **CA** : captures relues contre la vue générale (une par étage, 2340 × 1080).

#### T10 — A : alignement après la clôture du J18 — **après la clôture du J18**
- Fusionner `origin/main` (J16, J17, J18) dans `jalon-19`.
- Vérifier chaque ligne du §0.2 ; réaligner §0.3 si le moteur a bougé.
- Comptes d'espèces et de Dresseurs recalés ; doublons de données (Caninos, `candle`) retirés du
  côté du second fusionné.
- Régénérer les cartes (T9) sur l'art final.
- **CA** : tests verts ; liste des écarts écrite dans ce plan (§0) ; T11 peut partir.

### 3.2 Sous-jalon 19A (mode spectre et Exorcistes)

#### T11 — A : le mode spectre dans le moteur — après T10, T5, T6
- Fichiers (§2.2, §2.3) : `battle_rules.gd`, `battle_request.gd`, `battle_action.gd`,
  `battle_event.gd`, `battle.gd`, `battle_director.gd`, `battle_text.gd`, `battle_views.gd`,
  `battle_art.gd`, `encounter_director.gd`, `boot.gd` (garde du Pokédex),
  `data/battle/messages.json`.
- **Tests unitaires** (`tests/unit/test_battle_ghost.gd`, moteur pur, graines fixes) :
  - toute capacité donne `GHOST_SCARED` : aucun PP dépensé, aucun dégât, aucun tirage consommé
    (rang du `GameRng` inchangé) ;
  - **sommeil** → `STATUS_PREVENTED` (sommeil), jamais `GHOST_SCARED` ; **gel** idem ; réveil →
    `STATUS_ENDED`, puis la peur ;
  - confusion : ni `HURT_ITSELF` ni décompte [D] ; paralysie : la peur, sans tirage de
    paralysie [D] ;
  - le SPECTRE ne fait que `GHOST_SPOKE` : PV, statut et stades du joueur inchangés ;
  - **la fuite réussit toujours** : 50 essais avec la Vitesse du joueur à 1 contre 200 →
    `FLED` au premier tour, **sans** `FLEE_FAILED` ;
  - `is_legal(ball)` faux et `refuses_balls()` vrai ; les soins sont permis ; le changement est
    permis (le SPECTRE parle ensuite) ;
  - poison du joueur : dégâts de fin de tour ; dernier Pokémon K.O. par le poison → `LOSS` ;
  - **aucune XP**, aucun `EXP_GAINED`, `get_pay_day_coins() == 0` ;
  - tout événement adverse est `disguised`, avec l'espèce `ghost_disguise` et le niveau 0 ;
  - les règles hors mode spectre sont inchangées (le reste de `test_battle.gd` reste vert).
- **Tests d'intégration** (`tests/integration/test_ghost_encounter.gd`, carte réelle `pokemon_tower_3f`
  + Boot) :
  - **le spectre n'enregistre rien au Pokédex** : après N combats SPECTRE, ni « vu », ni « pris »,
    ni première espèce sauvage (`record_wild_encounter`), ni toast ; même en tirant de force
    Osselait et Spectrum ;
  - **la Ball n'est pas consommée** : Sac → Poké Ball → message §15.3.5 ; le nombre de Poké Balls
    est inchangé ; le combat attend un nouveau choix (pas de tour joué) ; avec 0 Ball, rien ne
    change ;
  - **la fuite réussit toujours**, en vraie scène ; contrôle rendu ; argent et équipe inchangés ;
  - **avec `silph_scope` dans le Sac** (identifiant brut) : rencontre normale (nom réel, « vu »,
    capture possible) ;
  - **relu à chaque rencontre** : on retire l'objet entre deux rencontres → spectre de nouveau ;
  - **garde du nom** : aucune ligne de texte affichée, aucune carte, aucune image ne contient le
    nom ou l'identifiant de l'espèce tirée ;
  - aucune rencontre sur un escalier, un déclencheur ou une case calme ; 2F : jamais de
    rencontre.
- **CA** : tests verts ; `test_battle*.gd` existants verts sans modification de leurs attentes.

#### T12 — U : présentation du SPECTRE et voix d'esprit — après T11
- Fichiers :
  - `game/ui/battle/battle_info_card.gd` : « Nv. ?? » si `level_hidden` ;
  - `game/ui/battle/battle_card_view.gd` ;
  - `game/ui/dialogue/dialogue_box.gd` : page `"voice": "spirit"` en italique, ou, sans variante
    italique de la police, en teinte adoucie [D] ;
  - `game/systems/dialogue/dialogue_library.gd` (clé de page `voice`, valeurs `spirit`) ;
  - jetons dans `ui_tokens.gd` (en fin).
- **Tests** :
  - `test_battle_views` (carte masquée) ;
  - `test_dialogue_library` (`voice` acceptée ; une valeur inconnue est refusée) ;
  - `tests/integration/test_dialogue_box.gd` (étendu : style appliqué, puis retiré à la page suivante).
- **Captures 2340 × 1080 relues** :
  - entrée d'un SPECTRE (silhouette, « Un SPECTRE apparaît ! ») ;
  - carte « SPECTRE Nv. ?? » ;
  - « trop effrayé » ;
  - refus de la Ball ;
  - Exorciste possédée (voix d'esprit).
- **CA** : aucune couleur en dur ; la silhouette n'a ni yeux ni contour noir (§11).

#### T13 — A : étape de scène `wild_battle` — après T11
- Fichiers : `cutscene_step.gd` (`Kind.WILD_BATTLE`, en fin), `cutscene_library.gd`
  (validation : espèce connue, niveau 1..100), `cutscene_director.gd` (`_wild_battle`),
  `battle_director.gd` (`run_wild`).
- **Tests** :
  - `tests/unit/test_cutscene_library` (étape valide ou refusée) ;
  - `tests/integration/test_cutscene_wild_battle.gd` :
    - combat lancé ;
    - mode spectre sans l'objet, normal avec ;
    - **aucun « vu » au Pokédex en mode spectre** (garde `boot.gd`) ;
    - `LOSS` (poison) → réveil, scène arrêtée ;
    - `FLED` → étape suivante jouée ;
    - drapeaux `win` / `lose` posés seulement s'ils sont écrits.
- **CA** : l'étape `battle` (Dresseurs) est inchangée.

#### T14 — C : Exorcistes, rencontres et SPECTRE du 6F sur les cartes — après T11, T12, T13, T4
- Fichiers :
  - `data/npcs/pokemon_tower_3f.json` … `_6f.json` ;
  - `data/dialogues/pokemon_tower_floors.json` (Exorcistes §15.4, SPECTRE §15.3.7–8) ;
  - `data/cutscenes/pokemon_tower_floors.json` (`tower_6f_ghost`) ;
  - `data/battle/decors.json` (`tour_pokemon`, `places`, en fin) ;
  - départs `tower_ghost_qa`, `tower_6f_block`, `tower_exorcist_weak` et `README.md`.
- **Tests** :
  - `tests/integration/test_tower_channelers.gd` :
    - 9 Exorcistes aux bons étages et aux bonnes cases ;
    - E3, E8, E9 inévitables et les six autres évitables, par recherche de chemin hors des vues
      **sur la vraie scène avec ses PNJ** ;
    - réplique avant / après mot pour mot ;
    - Fantominus « vu » après le combat ;
    - défaite contre E3 → réveil au dernier point de repos, E3 encore à battre (dossier §16
      n° 2) ;
    - `beaten_<id>` posé, et gardé après un rechargement ;
  - `tests/integration/test_tower_6f_ghost.gd` :
    - le pas sur (10, 16) → ligne §15.3.7 → combat SPECTRE → fuite → **joueur en (10, 15)** →
      §15.3.8 ;
    - le déclencheur se réarme (on recommence, même déroulé) ;
    - l'escalier du 7F n'est jamais atteint ;
    - **avec le compagnon sur (10, 15)** : échange de places, ni blocage ni chevauchement ;
    - départ `tower_6f_block` sans rival battu : le blocage fonctionne (§16 n° 10) ;
    - **rien au Pokédex** (ni `marowak`, ni `cubone`) ;
  - `test_battle_stage_decor` (`tour_pokemon` sur les cinq étages) ;
  - `test_debug_start` (trois départs chargés sans erreur).
- **CA** : captures du 6F (déclencheur, recul) et d'un combat d'Exorciste.

#### T15 — Q : **session 19A** → K — après T14

Protocole des J15 : APK debug, `tools/deploy_s24.sh --debug-start <départ>`, durée bornée 30 à
45 min, preuves `19a_<n>.png`.

| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `tower_ghost_qa` | marcher | combat SPECTRE : silhouette, « Un SPECTRE apparaît ! », « Impossible d'identifier le SPECTRE… », carte « SPECTRE Nv. ?? », aucun cri |
| 2 | (suite) | ATTAQUE (deux capacités) | « … est trop effrayé pour bouger ! », puis « SPECTRE : Va-t'en… Va-t'en… » ; PP inchangés |
| 3 | (suite) | SAC → Poké Ball | message §15.3.5, Poké Balls inchangées, retour au choix |
| 4 | (suite) | SAC → Super Potion ; ÉQUIPE → changer | les deux marchent ; le SPECTRE parle |
| 5 | (suite) | mettre en tête le Pokémon endormi, ATTAQUE | message de sommeil, pas la peur |
| 6 | (suite) | FUITE (avec le Pokémon le plus lent) | « Vous prenez la fuite ! » du premier coup, plusieurs fois |
| 7 | (suite) | ouvrir le Pokédex | aucune espèce nouvelle |
| 8 | (suite) | Exorcistes du 3F | voix d'esprit, combat, Fantominus « vu », réplique d'après |
| 9 | `tower_exorcist_weak` | perdre contre E3 | réveil au Centre, E3 toujours là |
| 10 | `tower_6f_block` | descendre sur (10, 16) | §15.3.7 → combat → fuite → recul en (10, 15) → §15.3.8 ; recommencer |
| 11 | (fps) | pendant 1 à 10 | ≥ 58 fps de moyenne, creux ≥ 50 |

**CA** : rapport `build/qa/jalon19_t15/` ; validation de Kevin.

### 3.3 Sous-jalon 19B (Tour complète, Lavanville, clôture)

#### T16 — C : rez-de-chaussée, gardienne, cartes branchées, Corde Sortie — après T15
- Fichiers :
  - `tools/build_painted_interiors.gd`, pièce `pokemon_tower_1f` (bloc J19) : escalier armé,
    spawn `arrivee_T12`, déclencheur (9..10, 15) ↑ ;
  - `data/npcs/pokemon_tower_1f.json`, `data/dialogues/pokemon_tower.json` (bloc J19) ;
  - `data/cutscenes/pokemon_tower_floors.json` (`tower_guardian`) ;
  - `tools/build_pokemon_tower.gd` (2F vers le 1F réel) ;
  - `data/world/caves.json` (en fin) ; `zones.json`.
- **Tests** (`tests/integration/test_pokemon_tower_1f_j19.gd`) :
  - premier pas → scène (§15.1.1–4) → la gardienne en (18, 3) → `tower_stairs_open` ;
  - escalier praticable → 2F, et retour en (17, 3) ;
  - après rechargement, la gardienne est en (18, 3) et dit §15.1.5 ;
  - lui parler avant le drapeau joue la scène ;
  - le test du J18 « escalier inatteignable » reste vrai **sans** le drapeau ;
  - **Corde Sortie** :
    - du 2F au 6F → devant la porte (`retour_tour`, ↓), une Corde de moins ;
    - au 1F → refusée ;
    - le rival non battu attend toujours (§16 n° 5) ;
  - `test_cave_library`, `test_field_item_rules`.

#### T17 — C : rival n° 5 et Exorciste calme du 2F — après T16, T4
- Fichiers : `data/npcs/pokemon_tower_2f.json`, `data/dialogues/pokemon_tower_floors.json`
  (§15.2, §15.4 « Exorciste qui ne combat pas, 2F »), `data/cutscenes/pokemon_tower_floors.json`
  (`tower_rival`), départs `tower_rival` et `tower_rival_weak`.
- **Tests** (`tests/integration/test_rival_tower.gd`, modèle `test_rival_cerulean`) :
  - inévitable : depuis `arrivee_T12`, aucun chemin vers `escalier_haut` n'évite (15, 5) ni
    (14, 6) ;
  - les trois variantes selon le starter (5 Pokémon, sans Rattatac) ;
  - victoire → silence → §15.2.4–5 → le rival part et disparaît → `rival_tower_won`, Grand
    moment `rival_battle` **une seule fois** ;
  - **le rival battu ne revient pas** : on repasse sur les deux cases, on recharge la partie, on
    entre de nouveau par l'escalier → aucune scène, aucun PNJ ;
  - **une défaite ne pose pas `rival_tower_won`** : §15.2.7 → réveil au Centre →
    `rival_tower_lost_once`, sans `_won` ni Grand moment → retour : §15.2.6 →
    `rival_tower_retried` → victoire ;
  - `test_rival_moment` (un moment par Dresseur).

#### T18 — C : zone purifiée, Exorciste calme du 5F, objets — après T16
- Fichiers : `data/npcs/pokemon_tower_5f.json` (Exorciste calme) et les objets des 3F à 6F,
  `data/dialogues/pokemon_tower_floors.json` (§15.5, §15.4 5F), `data/cutscenes/
  pokemon_tower_floors.json` (`tower_purified_zone`, scènes d'objets), `tools/build_pokemon_tower.gd`
  (objet caché, halo `purified`), départ `tower_5f_zone`.
- **Tests** (`tests/integration/test_tower_purified_zone.gd`) :
  - entrer par chacune des 5 entrées praticables du §2.8 → éclair, soin complet (PV, PP, statuts), §15.5 ;
  - se déplacer **dans** la zone → rien ;
  - **sortir, rentrer, cinq fois de suite** → soin **à chaque passage** ;
  - jamais de rencontre en 1 000 pas simulés dans la zone et sur ses abords (graine fixe, taux
    forcé à 255) ;
  - aucun Dresseur ne voit une case `Z` ni ses abords (sur la vraie scène) ;
  - `heal_map` et `heal_spawn` inchangés (pas un point de repos) ;
  - défaite ailleurs → Centre, pas la zone.
- **Tests** (`tests/integration/test_tower_items.gd`) :
  - cinq objets visibles, toasts, `got_<id>` ;
  - objet caché : bouton EXAMINER seulement face à l'indice, toast « Super Potion ×1 », plus rien
    après un rechargement (modèle `test_hidden_items`).

#### T19 — C (+ U pour le shader) : lumière `tower`, halos, brume, mesures — après T16
- Fichiers :
  - `data/world/lighting.json`, `light_glows.json` (en fin : `candle` si absent, `purified`) ;
  - `game/world/lighting/mist_layer.gd`, `shaders/mist_scroll.gdshader` ;
  - `tools/build_pokemon_tower.gd` (voile `ambient` par étage, brume, halos) ;
  - `boot.gd` : « Réduire les animations » vers `MistLayer` (bloc court, sur le modèle de
    `LightGlow.set_reduce_motion`).
- **Tests** :
  - `test_map_light_profiles` (`tower` sur les cinq étages) ;
  - `test_light_glow` (`purified` fixe) ;
  - `tests/unit/test_mist_layer.gd` : cachée si « Réduire les animations » ; aucun `_process`
    actif ; alpha ≤ 0,2 ;
  - `test_pokemon_tower_maps` : ≤ 16 halos, aucune `Light2D`.
- **CA** : captures 2340 × 1080 des cinq étages à luminosité moyenne (lisible sans monter la
  luminosité) ; mesure fps sur téléphone au 6F (≥ 58 de moyenne, creux ≥ 50).

#### T20 — C : Lavanville au J19 — après T16 (et Q-2 pour la fille)
- Fichiers (§2.11) : `data/npcs/pokemon_house.json`, `lavender_center.json`,
  `data/dialogues/lavender_houses.json`, `lavender_town.json` (blocs J19),
  `tools/build_lavender_town.gd` (panneau (42, 11)), prop du panneau (T8).
- **Tests** (`tests/integration/test_lavender_j19.gd`) :
  - §15.6.1 à 15.6.5 mot pour mot, aux bonnes cases ;
  - panneau bloquant, lu depuis (41, 11) → ;
  - **le mot « Rocket » n'apparaît dans aucun texte des fichiers ajoutés ou modifiés par le J19**
    (décision 7) ;
  - les lignes du J18 qui parlent de Fuji au présent ne sont plus jouées (T-25).

#### T21 — A : simulation du rival n° 5 — après T10 (équipes réelles des J16 à J18), T4
- Méthode `simulate_brock.gd`, par `tools/simulate_mt_moon.gd -- --scenario=tower`.
  - 200 parties par starter ;
  - joueur « attentif » et joueur « bas » (sortie directe du J18) ;
  - variantes avec et sans les Exorcistes facultatifs.
- **Cible** : niveaux finaux du rival dans la **fourchette 22–26** (K-6), le starter évolué
  plafonné à 26.
  - **Victoire du joueur « attentif »** : ≥ 70 % au premier essai ;
  - **victoire du joueur « bas »** : ≥ 90 % en trois essais ;
  - la variante Bulbizarre peut être adoucie (précédent du J13).
  - Ce sont des seuils [D], comme au J13.
- **Livrables** :
  - `docs/tech/jalon-19-equilibrage.md` (méthode, résultats, niveaux retenus) ;
  - niveaux et capacités finaux dans `data/trainers/pokemon_tower.json` ;
  - départs recalés.
- **CA** : `test_trainers_j19` vérifie la fourchette 22–26 (aucun Pokémon du rival hors de la
  fourchette, sauf Kadabra, gardé ≤ 22 [D]) ; résultats envoyés à Kevin avant T23.

#### T22 — A : gardes de sauvegarde et de contrat — après T17, T18
- Fichiers : `tests/unit/test_save_j19.gd` (§2.13), `tests/unit/test_j19_flags_contract.gd`.
- **Tests** :
  - tout le §2.13 ;
  - **aucun drapeau du J21 n'est posé** : on parcourt toutes les données ajoutées par le J19
    (scènes : `set`, `win`, `lose` ; dialogues : `set`, `confirm_set`, `cancel_set` ; PNJ ; départs
    `flags`) et **aucune** ne contient `ghost_marowak_calmed`, `fuji_rescued`, `got_poke_flute`,
    `beaten_tower_rocket_*` (le `unless` de `tower_6f_ghost` est la seule lecture permise) ;
  - les données du J19 ne posent aucun drapeau du J20 (liste du dossier 23, lue à T10) ;
  - **une sauvegarde J19 + `silph_scope` donne des rencontres normales** : on sauvegarde au 6F
    (vraie Boot), on ajoute `silph_scope` au Sac du fichier, on recharge, on force une rencontre
    → nom réel, « vu » au Pokédex, Ball acceptée ; **le SPECTRE du 6F reste un SPECTRE** (`ghost: always`), même
    avec `silph_scope` dans le Sac.

#### T23 — Q : **session 19B** et QA de bout en bout → K, fusion — après T17 à T22

| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `tower_qa` | entrer dans la Tour | §15.1.1–4, la gardienne s'écarte ; lui reparler : §15.1.5 |
| 2 | (suite) | monter au 2F | Exorciste calme (Scope) ; rival inévitable, §15.2, combat, silence, départ ; Grand moment dans l'écran Dresseur |
| 3 | `tower_rival_weak` | perdre, revenir | §15.2.7, réveil, §15.2.6 |
| 4 | (suite de 2) | 3F à 6F | spectres, Exorcistes (E3, E8, E9 impossibles à éviter), objets, Corde Sortie au sol |
| 5 | (suite) | zone purifiée : entrer, sortir, rentrer | soin à chaque passage, éclair, §15.5 |
| 6 | (suite) | objet caché du 5F | toast, puis plus rien |
| 7 | (suite) | 6F, escalier du 7F | blocage, recul, impossible de passer |
| 8 | (suite) | Corde Sortie au 6F | devant la Tour ; rival battu toujours absent |
| 9 | (suite) | Lavanville | enfant, homme, fille, gentleman (rumeur), panneau du Scope |
| 10 | (suite) | relancer l'appli (sauvegarde) | drapeaux gardés, gardienne en (18, 3), rival absent |
| 11 | (fps, lumière) | 2F à 6F | ≥ 58 fps de moyenne, creux ≥ 50 ; lisible à luminosité moyenne ; « Réduire les animations » coupe la brume et le battement |
| 12 | **vraie partie de Kevin** (si le J18 y est arrivé) | aller de Lavanville au 6F | aucune régression, rien de perdu |

**Critère de clôture (dossier §14)** : le joueur explore le 1F au 6F, bat le rival, rencontre des
SPECTRES et bute contre le blocage. Il **ne peut ni** atteindre le 7F, **ni** voir Fuji, **ni**
obtenir la Poké Flûte.

**CA** : rapport `build/qa/jalon19_t23/` ; validation de Kevin ; fusion dans `main` (copie
d'intégration ; `project.godot` et filtre d'export vérifiés).

#### T24 — A : clôture et passation — après T23
- `etat-projet.md`, roadmap (la ligne J19 seulement avec l'accord de Kevin, comme pour le J18).
- **Passation au J20** :
  - `silph_scope` (identifiant fixé, objet à créer) ;
  - **l'étape `wild_battle` du 6F est en `ghost: always`** : rien à adapter au J20 ; le J21
    (dossier 24) la passe en `ghost_unless_item` pour la révélation ;
  - Osselait devient capturable (art de face et de dos, Pokédex) ;
  - table du 7F notée au dossier §5 ;
  - `prize_per_level` du rival.
- **Passation au J21** : `ghost_marowak_calmed` (lu en `unless`), Ossatueur N30 et ses données,
  7F non construit, `escalier_7f` en `coming_soon`.
- **Reportés à la phase DA** : épaississement de la brume, particules, son (K-18).

---

## 4. Critères d'acceptation par sous-jalon

**19.0** :
- données valides (7 espèces, capacités, 10 Dresseurs, 3 tables `floor` avec `ghost_unless_item`) ;
- logique pure du mode spectre testée ;
- cinq cartes générées conformes aux grilles (escaliers, cases calmes, déclencheurs à direction) ;
- planche d'art validée ;
- alignement T10 fait ;
- tests verts, import propre.

**19A** :
- rencontre SPECTRE sur toute case praticable du 3F au 6F (sauf escaliers, déclencheurs et cases
  calmes), jamais au 2F ;
- masque complet (nom, image, niveau « Nv. ?? », aucun cri) ;
- « trop effrayé » (sommeil et gel exceptés) ;
- le SPECTRE ne fait que parler ;
- Sac et changement permis ;
- **Ball refusée et non consommée** ;
- **fuite toujours réussie** ;
- aucune XP ;
- **rien au Pokédex** (sauvage et 6F) ;
- avec `silph_scope` : combat normal ;
- 9 Exorcistes (voix d'esprit, E3, E8 et E9 inévitables, Fantominus et Spectrum « vus ») ;
- SPECTRE du 6F : combat scripté puis recul en (10, 15), réarmé ;
- session téléphone validée.

**19B** :
- gardienne et `tower_stairs_open` ;
- escaliers 1F ↔ 6F ;
- rival n° 5 (inévitable ; victoire obligatoire ; trois variantes sans Rattatac ; défaite → Centre
  sans `won` ; battu = absent pour toujours ; Grand moment unique) ;
- zone purifiée (soin à chaque passage, sans rencontre ni vue, pas un point de repos) ;
- objets et objet caché ;
- Corde Sortie (2F à 6F → porte ; 1F refusée) ;
- profil `tower`, halos, brume (coupée par « Réduire les animations »), fond `tour_pokemon` ;
- Lavanville (variantes, homme, fille, gentleman, panneau) ;
- « Rocket » absent ;
- niveaux du rival simulés dans 22–26 ;
- sauvegarde v7 inchangée ;
- aucun drapeau du J21 posé ;
- ≥ 58 fps de moyenne ;
- validation de Kevin, puis fusion.

---

## 5. Cas limites (dossier §16 et passe §4) → tests

| Cas | Test | Attendu |
|---|---|---|
| §16 n° 1 / passe 1 : sauvegarde au 6F, puis `silph_scope` | `test_save_j19`, `test_j19_flags_contract` (T22) | rencontres normales sans migration ; le blocage du 6F reste un SPECTRE (`ghost: always`) |
| §16 n° 2 : équipe K.O. contre un Exorciste | `test_tower_channelers` (T14) | réveil au Centre ; les Exorcistes battus le restent |
| §16 n° 3 : statuts en combat SPECTRE | `test_battle_ghost` (T11) | sommeil / gel : leur message ; poison : dégâts ; la fuite reste possible |
| §16 n° 4 : plus de Ball | `test_ghost_encounter` (T11) | rien ne change |
| §16 n° 5 : Corde Sortie | `test_pokemon_tower_1f_j19` (T16) | devant la porte ; le rival non battu attend |
| §16 n° 6 et 7 : compagnon, recul | `test_tower_6f_ghost` (T14) | il suit ; échange de places ; aucun blocage |
| §16 n° 8 : zone en boucle | `test_tower_purified_zone` (T18) | soin à chaque entrée, sans rencontre |
| §16 n° 9 / passe 3 : rival vaincu | `test_rival_tower` (T17) | jamais redéclenché ; Grand moment unique ; une défaite ne pose pas `won` |
| §16 n° 10 : 6F sans rival battu | `test_tower_6f_ghost` (T14) | le blocage fonctionne |
| §16 n° 11 / passe 4 : Pokédex | `test_ghost_encounter`, `test_cutscene_wild_battle` | rien n'est enregistré, ni sauvage ni scénarisé |
| §16 n° 12 / passe 2 : drapeaux du J21 | `test_j19_flags_contract` (T22) | aucun posé par une donnée du J19 |
| Ball non consommée | `test_ghost_encounter` (T11) | nombre de Balls inchangé, aucun tour joué |
| Fuite toujours réussie | `test_battle_ghost`, `test_ghost_encounter` | `FLED` au premier essai, quelles que soient les Vitesses |
| Zone : soin à chaque passage | `test_tower_purified_zone` | cinq entrées = cinq soins |
| (en plus) l'espèce tirée ne fuit jamais | `test_ghost_encounter` | aucun texte, aucune carte, aucune image ne la nomme |
| (en plus) rencontre sur un escalier ou un déclencheur | `test_ghost_encounter` | jamais |
| (en plus) Ténèbres contre un type Normal | `test_tower_moves` | sans effet |

---

## 6. Risques et ordre

| Risque | Effet | Parade |
|---|---|---|
| **Le mode spectre touche le cœur du moteur** (`battle.gd` : `_execute`, `_foe_action`, `_attempt_flee`, `is_legal`, `_pokemon_event` ; `battle_director.gd` : choix du Sac) | régressions de combat sur tout le jeu | **C-7** : seulement après la clôture du J18 (T10). Chaque branche est gardée par `_rules.ghost` : hors mode spectre, aucun tirage ni aucun ordre ne change (test : les suites `test_battle*.gd` restent vertes **sans** toucher leurs attentes). Logique pure séparée (T6). Une seule tâche moteur (T11). |
| **Fuite de l'identité** (texte, carte, image, Pokédex, cri, toast, Grand moment) | spoiler d'Ossatueur, bris de la décision 5 | masque **dans le moteur** (un seul point : `_pokemon_event`), surnom posé par le directeur, garde `disguised` dans `boot.gd`, test « aucun nom de l'espèce tirée » |
| **Ordre des écouteurs de `moved`** (rencontre, scène, Dresseur sur la même case) | rencontre tirée sur un escalier ou sur la case du rival | `floor` exclut les warps, les déclencheurs et les cases calmes (§2.2) |
| **Rencontres trop fréquentes** (taux RB de 10 et 15, sans montée, et rien à gagner) | lassitude | K-10 : fuite en un geste ; revoir à la QA (« Reportés ») |
| **Brume et halos sur S24 / S21** | baisse d'images | une seule couche de brume par carte, un shader trivial, sans `_process` ; halos ≤ 16 ; aucune `Light2D`, aucune particule ; mesure au T19 et à la session 19B ; repli : brume à moitié de résolution, ou coupée au 6F |
| **Fichiers du J18** (1F, Lavanville, Centre, maisons) encore en mouvement | conflits | 19B seulement après la fusion du J18 ; blocs courts « Tour Pokémon (J19) » |
| **J16 en retard** (rival n° 4, `prize_per_level`) | une valeur à recaler | défaut 35, réaligné à T10 |
| **Équipes réelles des J16 à J18 inconnues** | niveaux du rival mal calés | T21 tourne après T10, sur les vraies sorties |
| **Le J20 donne `silph_scope`** | aucun : le 6F est en `ghost: always` | test T22 ; le J21 change la donnée |
| Échec intermittent connu de `tools/test.sh` sous charge | faux rouge | relancer le fichier seul avant de conclure |

**Ordre et parallélisme**

```
Maintenant  : T1 ─→ T3 ∥ T4 ∥ T5 ∥ T6 ; T2 (K) ; T7 ─→ T8 ; T9 (art provisoire)
[clôture J18] ─→ T10 ─→ T11 ─→ T12 ∥ T13 ─→ T14 ─→ T15 (téléphone 19A)
19B          : T16 ─→ T17 ∥ T18 ∥ T19 ∥ T20 ; T21 (après T10) ─→ T22 ─→ T23 (téléphone) ─→ T24
```

**Peut commencer maintenant** (avant la clôture du J18) : T1, T2, T3, T4, T5, T6, T7, T8 et T9.
Ce sont de la logique pure, des données dans des fichiers nouveaux, le générateur et l'art.

---

## 7. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Branches | `jalon-19` (copie dédiée) ; tâches `j19-t<n>-*` |
| Fichiers de données | `species/kanto_tower.json`, `moves/tower.json`, `trainers/pokemon_tower.json`, `encounters/pokemon_tower.json`, `npcs/pokemon_tower_2f..6f.json`, `dialogues/pokemon_tower_floors.json`, `cutscenes/pokemon_tower_floors.json` |
| Cartes | `pokemon_tower_2f..6f`, 20 × 18, `interior = false`, dans `caves.json` (Corde → `lavender_town` / `retour_tour`, ↓) ; spawns de QA `devant_spectre` (6F) et `devant_rival` (2F) |
| Tables | sans `ramp` (K-10 : taux RB) |
| Terrain `floor` | toute case praticable, sauf warps, déclencheurs et `calm_cells` (cases `Z` + 8 voisines) ; aucune intro d'herbe ou de gravats |
| Peur | la paralysie et la confusion passent après la peur (ni tirage, ni décompte) ; sommeil et gel gardent leur message ; PP non dépensés |
| Ball | refusée avant le Sac, sans tour joué |
| Ordre du tour SPECTRE | le joueur d'abord |
| Niveau masqué | « Nv. ?? » (convention de la carte ; le dossier écrit « N?? ») |
| Silhouette | `assets/sprites/battle/spectre.png`, pseudo-espèce `ghost_disguise` |
| Origine du combat scripté | case du joueur plus son orientation |
| « La brume s'épaissit » | réaction du joueur et pause de 0,6 s ; reporté à la phase DA |
| Gardienne | déclencheur (9..10, 15) ↑ ; elle se range en (18, 3), tournée ← ; spawn `arrivee_T12` (17, 3) ↓ |
| Rival | déclencheurs sans direction ; silence de 2,0 s ; part vers (17, 9) puis disparaît ; `prize_per_level` 35 (ou celui du n° 4) |
| Exorcistes | `defeated` = réplique « après » (sauf Q-1) |
| Zone purifiée | déclencheurs à direction ; un éclair adouci (`flash` 1) ; deux dialogues (soin avant la phrase « soignée ») ; halo `purified` fixe |
| Objet caché du 5F | la grille (4, 11) fait foi, pas le dossier (4, 12) |
| Lumière | profil `tower` ; gradation par l'`ambient` du voile (2F 0,96 → 6F 0,88) ; `candle` sur les stèles |
| Brume | une couche par carte, sous les personnages, alpha ≤ 0,2, cachée par « Réduire les animations » ; aucune particule |
| Lavanville | homme et gentleman sur des cases libres ; gentleman `traveler` ou `old_man` ; T-26 gardé |
| Pokédex | 5 entrées ; Osselait et Ossatueur attendent le J20 / J21 |
| Kadabra du rival | ≤ 22 (rôle de « petit » de l'équipe RB) |
| Seuils de simulation | ≥ 70 % au premier essai (attentif) ; ≥ 90 % en trois essais (bas) |
| Budgets | ≤ 3 000 nœuds, ≤ 16 halos ; ≥ 58 fps de moyenne, creux ≥ 50 |
| Sauvegarde | v7 |

---

## 8. Questions pour Kevin

Vraies décisions de game design seulement ; tout le reste a une valeur par défaut (§7).

- **Q-1 — Lot de textes complémentaires** (T2). Ces textes ne sont pas couverts par le §15 :
  - 5 entrées de Pokédex ;
  - les descriptions des capacités nouvelles ;
  - le nom affiché « SPECTRE » ;
  - la forme féminine « effrayée » ;
  - la phrase de défaite des Exorcistes ;
  - les objectifs du tableau de bord après l'ouverture de l'escalier, puis après le blocage du 6F ;
  - un éventuel nom de zone des étages.

  *Recommandation* : relecture en une passe, comme aux J13 et J15. Pour les objectifs, garder
  « revenir plus tard à la Tour Pokémon. » du J18 après le blocage, et ajouter une seule ligne
  « monter dans la Tour Pokémon. » entre l'ouverture de l'escalier et le 6F. Cela ne bloque pas
  le code.

- **Q-2 — Où se tient la fille de la « maison d'Osselait » ?** Le dossier 21 a exclu cette maison
  et renvoyé son placement au J19. La grille de Lavanville (J18, validée) n'a aucun bâtiment
  libre.
  - **A** (recommandé) : elle se tient dans la **Maison des Pokémon** de M. Fuji, qui recueille
    les Pokémon orphelins. Aucune géométrie ne change. Le texte §15.6.3 y garde son sens.
  - **B** : dans la maison 1 ou 2 du J18.
  - **C** : un nouveau bâtiment à Lavanville. Il faudrait modifier la grille validée et la vue
    générale, et créer de l'art.
