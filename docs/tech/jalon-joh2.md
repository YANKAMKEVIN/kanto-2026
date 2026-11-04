# Jalon JOH2 — Routes 39 et 38, Rosalia (premiers pas à Johto)

> **PLAN — aucun code n'est écrit par ce document.** Sources de vérité :
> `docs/design/dossier-joh-00-cadre.md` (§3, §4.2, §5.2) et
> `docs/design/dossier-joh-03-rosalia.md` (textes §13 et JH-28 à JH-30 validés par Kevin le
> 2026-11-02 ; le reste porte des défauts **[D]**) ; grilles `tools/plans/route_39.txt`,
> `route_38.txt`, `rosalia.txt` (validées le 2026-11-02, **elles font foi**) ; vues générales
> `docs/design/reference/route-39-vue-generale-v1.png`, `route-38-vue-generale-v1.png`,
> `rosalia-vue-generale-v1.png` (validées le 2026-11-03, DA seulement). Les systèmes viennent du
> JOH0 (`docs/tech/jalon-joh0.md` §2 et §8). Écrit le 2026-11-04 sur la branche
> `claude/joh2-rosalia-bd0f78` (cut de `claude/joh0-systemes` @ `441051db` ; `main` refusionné dès
> que le JOH0 y est).

> Objectif jouable : **d'Oliville à la sortie sud de Rosalia** : la Route 39 (Ferme Meumeu en
> façade, deux Dresseurs, Potion), la Route 38 (trois Dresseurs dont Inès inévitable, Poké Balls,
> Super Potion cachée, promeneur), Rosalia (titre de zone, scène des Sbires devant la Tour
> Cendrée, doyen et légende de Ho-Oh, garde de la Tour Carillon, Centre avec PC hors ligne,
> Boutique, deux maisons, sortie est fermée par un garde, sortie sud vers la Route 37 « à
> venir »), rencontres par moment, PNJ de la semaine (Margot le mardi à Rosalia ; Lucien le lundi
> à Oliville, posé par le JOH1), point de Vol Rosalia.
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA sur l'A17,
> fusion dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change
> (règle 1 : rien à valider seul).

## 0. État des lieux (relu sur la branche, 2026-11-04)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Cartes depuis une grille | `tools/build_j22_maps.gd` : tuiles provisoires (`OverworldTiles`), positions lues dans la grille (warps par case, arrivées, panneaux, caches, déclencheurs), destinations absentes en « À venir » | Même modèle : `tools/build_joh2_maps.gd` (T2), avec bâtiments du kit peint posés sur leur emprise, tours en aplats provisoires, lampes de nuit |
| Données depuis une grille | `tools/gen_j22_data.py` : PNJ, Dresseurs, objets, dialogues et scènes générés des positions ; textes en table ; `tests/helpers/j22_ids.gd` écarte les fichiers `j22_*` des grands registres | `tools/gen_joh2_data.py` (T1), préfixe **`joh2_`** ajouté aux préfixes écartés ; `tests/unit/test_joh2_data.gd` vérifie les textes mot pour mot (§13) |
| Intérieurs | `build_painted_interiors.gd` : `_pokemon_center`, `_poke_mart` (définitions communes), maisons relues sur une grille de Lavanville | `--rosalia` : Centre, Boutique, maison des sages et deux maisons (T4) |
| Heure, lumière | `WorldClock` réel, moments lus sur les cartes `region: johto` ; `johto_auto` ; groupe `night_lights` ; `period` des tables ; `if_period` / `if_weekday` des PNJ et variantes ; départ de débogage : `period` | Rien de neuf, sauf **`weekday`** du départ de débogage (T9, [D]) pour voir Margot un autre jour qu'un mardi |
| Zones | `ecruteak_city` déclarée (`maps: []`, région `johto`, description [D] en brouillon) ; point de Vol `ecruteak_city` → `from_center` ; rectangle sur l'illustration provisoire de Johto | Cartes remplies, description R-25 (validée), zones `route_39` et `route_38` neuves (T5) ; aperçus de la Carte (`build_zone_previews.gd`) |
| Oliville | Carte du JOH1, pas encore construite (branche `claude/joh1-oliville-336a58`) | Raccord ouest de la Route 39 « À venir » tant que `olivine_city.tscn` manque ; relancer l'outil à la fusion ; Lucien (lundi) = PNJ de la carte d'Oliville : textes et scène ici, placement par le JOH1 (message envoyé) |
| Art | Vues générales validées, aucun décor peint ; pas de sprite de doyen, de sage, de Margot, d'Écrémeuh | Tuiles provisoires, kit de bâtiments de Kanto, sprites existants [D] ; Pokémon de la ferme = points d'examen ; tout en « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH2A** — les cartes | T1 données générées, T2 trois cartes, T3 raccords et sorties, T4 intérieurs, T5 données de monde, T6 rencontres | Tests, captures Mac |
| **JOH2B** — la vie | T7 scènes (Sbires, doyen, gardes, objets), T8 PNJ de la semaine, T9 départs de débogage, T10 tests, T11 captures | Tests, captures Mac |
| Clôture | T12 QA A17 (tour demandé à la coordination), T13 CI verte et fusion dans `main`, T14 état du projet, prompt du JOH3, compte rendu | Déléguée |

## 2. Conception technique

### 2.1 Cartes et identifiants

| Carte | Identifiant | Grille | Taille | Lumière | Outil |
|---|---|---|---|---|---|
| Route 39 | `route_39` | `route_39.txt` | 24 × 50 | `johto_auto` | `tools/build_joh2_maps.gd` |
| Route 38 | `route_38` | `route_38.txt` | 60 × 20 | `johto_auto` | idem |
| Rosalia | `ecruteak_city` | `rosalia.txt` | 56 × 48 | `johto_auto` | idem |
| Centre | `ecruteak_center` | définition commune | 15 × 10 | `interior_warm` | `build_painted_interiors.gd --rosalia` |
| Boutique | `ecruteak_mart` | définition commune | 15 × 10 | `interior_warm` | idem |
| Maison des sages | `ecruteak_elders_house` | `lavanville_maison_1.txt` [D] | 15 × 10 | `interior_warm` | idem |
| Maison 1 | `ecruteak_house_1` | `lavanville_maison_2.txt` [D] | 15 × 10 | `interior_warm` | idem |
| Maison 2 | `ecruteak_house_2` | `lavanville_maison_1.txt` [D] | 15 × 10 | `interior_warm` | idem |

- Tuiles provisoires (`OverworldTiles`, modèle J22) : `.` herbe, `=` terre, `h` hautes herbes,
  `p` pavé (COBBLE), `D` porte (COBBLE), `T` `x` forêt (bloquées), `R` falaise, `W` eau (décor,
  bloquée), `f` clôture (CLIFF [D]), `e` pré d'enclos (CROP, bloqué), `G` arbre repère (FOREST),
  `y` massif (FLOWERS, bloqué), `n` banc (CROP, bloqué), emprises `M B K S C O m N` (CLIFF,
  bloquées). Bâtiments du kit peint posés sur l'emprise : Centre `bldg_centre_01` (ancre : porte
  est (9, 29)), Boutique `bldg_boutique_01` ((19, 29)), maisons `bldg_maison_lavanville_01` [D]
  ((35, 29), (47, 29)), maison des sages `bldg_maison_argenta_01` [D] ((21, 12)), Ferme Meumeu
  `bldg_maison_pecheur_01` [D] (façade sans porte : emprise seule). Tours Cendrée et Carillon :
  **aplats provisoires** (`Polygon2D` sombres, `Joh2TourCendree`, `Joh2TourCarillon`) sur leur
  emprise [D] (art au lot suivant). **La grille fait foi** : test « grille de la scène = grille du
  plan » (`test_joh2_maps`).
- Lampes de nuit (groupe `night_lights`, `LightGlow` type `lamp`, visibles la nuit seulement) [D] :
  Route 39 : façade de la ferme ; Route 38 : aucune ; Rosalia : deux réverbères de l'avenue
  ((20, 13), (40, 13)), fenêtres du Centre et de la Boutique, parvis de la Tour Cendrée.
- Pokémon de la ferme (Écrémeuh ×3, Tauros, Ponyta : positions `pokemon`) : cases bloquées +
  point d'examen (textes [D] en `draft`) ; aucune planche d'Écrémeuh (« Reportés »).

### 2.2 Raccords et sorties (T3)

| Passage | Mécanisme |
|---|---|
| Route 39 (0, 20..22) ↔ Oliville (49, 20..22) | PUSH ← vers `olivine_city` / `from_route_39` (une arrivée par case : `from_route_39`, `_1`, `_2`) ; « À venir » (« Oliville ») tant que la carte manque ; arrivée `from_olivine` (+ `_1`, `_2`) tournée → |
| Route 39 (23, 3..5) ↔ Route 38 (0, 3..5) | PUSH → / PUSH ← ; `from_route_38` / `from_route_39` |
| Route 38 (59, 14..16) ↔ Rosalia (0, 14..16) | PUSH → / PUSH ← ; `from_ecruteak` / `from_route_38` |
| Rosalia (26..28, 47) → Route 37 (8..10, 0) | PUSH ↓ vers `route_37` / `from_ecruteak` ; « À venir » (« Route 37 ») ; arrivée `from_route_37` |
| Rosalia (55, 30..32) → Route 42 | PUSH → « À venir » (« Route 42 ») ; **fermé à l'acte 1** : garde (54, 29) `unless johto_act2`, déclencheur (54, 30..32) sens → → scène `ecruteak_route_42_guard` (`unless johto_act2` : texte du garde [D] en `draft`, un pas en arrière) |
| Rosalia (42..43, 0) → Bois de la Tour | PUSH ↑ « À venir » (« Bois de la Tour ») ; garde (41, 13) R-20 `unless johto_bell_tower_open` ; déclencheur (42..43, 13) sens ↑ → `ecruteak_bell_tower_guard` (R-20, un pas en arrière) |
| Portes | STEP_ON ↑ : Centre (8..9, 29) → `ecruteak_center` / `entrance`, retour `retour_centre` (8..9, 30) **= aussi `from_center`** (point de Vol) ; Boutique (18..19, 29) ↔ `retour_boutique` ; sages (21, 12) ↔ `retour_sages` ; maisons (35, 29) ↔ `retour_maison_1`, (47, 29) ↔ `retour_maison_2` |
| Tour Cendrée (8..9, 12) | examen R-19 (`unless johto_burned_tower_open`) ; warp STEP_ON ↑ `if johto_burned_tower_open` → `burned_tower_1f` « À venir » (« Tour Cendrée ») [D] ; retour `retour_tour_cendree` |

Intérieurs : sortie PUSH ↓ (3 cases) vers la ville, comme Lavanville.

### 2.3 Données générées (T1, `tools/gen_joh2_data.py`)

Lit les positions des trois grilles et écrit :
- `data/npcs/route_39.json`, `route_38.json`, `ecruteak_city.json` : Dresseurs (bloc `trainer`
  : `sight`, `before`, `defeated`, réplique « après » = `dialogue`), PNJ, objets visibles (verbe
  PRENDRE, `unless got_<id>`) ; `ecruteak_elders_house.json` (doyen + deux sages), `ecruteak_house_1.json`
  (habitante aux Antidotes), `ecruteak_house_2.json` (habitant) ;
- `data/trainers/route_39.json`, `route_38.json` (§6 ; `prize_per_level` 20 / 25 / 35 [D],
  `ai: random`) ;
- `data/dialogues/joh2_route_39.json`, `joh2_route_38.json`, `joh2_ecruteak_city.json`,
  `joh2_ecruteak_interiors.json`, `joh2_week.json` (Lucien, Margot) ;
- `data/cutscenes/joh2_*.json` : objets (visibles : `despawn` → `give found` → `set` ; caché :
  `give found` → `set`), scène des Sbires, gardes, dons de la semaine.
- Textes : §13 mot pour mot (« / » = page, « · » = variante) ; les textes absents du dossier sont
  marqués `draft` et listés dans `PENDING_DRAFTS` : garde de la Route 42 (« texte à écrire avec le
  JOH6 »), habitants des deux maisons (don des Antidotes), Pokémon de la ferme, panneau du Phare
  d'Oliville non concerné.
- Sprites [D] : Hugo `youngster`, Lina `lass_young`, Paul `bird_keeper`, Inès `cooltrainer_f`,
  Théo `camper`, fermière `beauty`, promeneur `traveler`, sages `channeler`, doyen `mr_fuji`,
  Sbires `rocket_grunt_m` / `rocket_grunt_f`, gardes `guard`, Margot `aoki`, Lucien `sailor`,
  habitants `old_man` / `kid`.

### 2.4 Rencontres (T6, `data/encounters/route_39.json`, `route_38.json`, `ecruteak_city.json`)

| Table | Carte | `period` | Taux | Niveaux | Espèces (poids) |
|---|---|---|---|---|---|
| `route_39_grass_day` | `route_39` | `["morning", "day"]` | 25 | 4–7 | sentret 30, mareep 30, rattata 18, pidgey 18, miltank 4 |
| `route_39_grass_night` | `route_39` | `night` | 25 | 4–7 | hoothoot 40, rattata 30, oddish 30 |
| `route_38_grass_day` | `route_38` | `["morning", "day"]` | 25 | 7–11 | sentret 30, mareep 25, pidgey 20, rattata 12, meowth 9, miltank 4 |
| `route_38_grass_night` | `route_38` | `night` | 25 | 7–11 | hoothoot 40, rattata 30, meowth 20, oddish 10 |
| `ecruteak_towers_night` | `ecruteak_city` | `night` | **3** [D] (≈ 10 % de 25) | 10–12 | murkrow 50, hoothoot 50 |

Rosalia n'a **aucune table de jour** : l'herbe des tours ne donne rien le matin et le jour
(vérifié : `has_table` faux, aucun tirage, aucune erreur). Rampe standard (`from_step 15`,
`max_steps 20`).

### 2.5 Scènes et drapeaux (T7)

| Scène | Déclencheur | Variante | Étapes |
|---|---|---|---|
| `ecruteak_rockets` | `scene_sbires` (1..2, 14..16), toute direction | `unless johto_rosalia_rockets_seen` | `set johto_rosalia_rockets_seen` ; `face sbire_1 → sage_tour` ; dialogue R-12 ; R-13 ; `emote sbire_2 !` ; `face sbire_2 → player` ; R-14 ; `move sbire_1 → (54, 15)` en arrière-plan, `move sbire_2 → (54, 16)` ; `despawn` des deux ; `face sage_tour → player` |
| Sage de la Tour (PNJ, dialogue) | — | `if johto_rosalia_rockets_seen` : R-15 ; sinon R-13 [D] | — |
| Doyen (PNJ, dialogue) | — | `unless johto_tower_legend_heard` : R-16 + R-17, `set johto_tower_legend_heard` ; `if` : R-18 | — |
| `ecruteak_bell_tower_guard` | (42..43, 13) ↑ | `unless johto_bell_tower_open` | face, R-20, `move player path [down] keep_facing` |
| `ecruteak_route_42_guard` | (54, 30..32) → | `unless johto_act2` | face, texte [D], `move player path [left] keep_facing` |
| Objets | dialogue du PNJ objet / examen du tronc | `unless got_<id>` | `give found`, `set` |
| Sbires | PNJ `sbire_1` (11, 13), `sbire_2` (12, 14), `unless johto_rosalia_rockets_seen` | — | — |

Drapeaux du jalon : `johto_rosalia_rockets_seen`, `johto_tower_legend_heard`, `week_monday_gift`,
`week_tuesday_gift`, `got_route_39_item_1`, `got_route_38_item_1`, `got_route_38_hidden_1`,
`got_ecruteak_house_1_antidote`. Lus sans être posés ici : `johto_act2` (JOH5 / JOH6),
`johto_bell_tower_open` (JOH8), `johto_burned_tower_open` (JOH6).

### 2.6 PNJ de la semaine (T8, cadre §5.2)

- **Margot** (Rosalia, (13, 29), `if_weekday: ["tuesday"]`, dialogue `week_tuesday_margot`) :
  variante `unless week_tuesday_gift` : R-22 (deux pages) puis `cutscene: week_tuesday_gift`
  (`give revive × 2` (pas « found »), narration `week_tuesday_received` « {player} reçoit 2
  Rappels ! », `set week_tuesday_gift`) ; variante `if week_tuesday_gift` : « Reviens un mardi,
  j'en connais d'autres. ». Hors du mardi : absente (clé `if_weekday`, lue à l'entrée sur la carte).
- **Lucien** (Oliville, port, `if_weekday: ["monday"]`, dialogue `week_monday_lucien`) : même
  construction (R-21, `super_potion × 3`, `week_monday_gift`, « À lundi prochain, peut-être ! »).
  Les textes et la scène sont dans `joh2_week.json` ; **le PNJ est posé par le JOH1** dans
  `data/npcs/olivine_city.json` (entrée fournie par message : `{"cell": [x, y], "facing":
  "down", "sprite": "sailor", "dialogue": "week_monday_lucien", "if_weekday": ["monday"]}`).
  `test_joh2_data` vérifie l'entrée seulement si la carte d'Oliville existe.
- Le drapeau est posé **une fois pour toutes** (dossier §8 : « don (une fois) ») : pas de remise
  chaque semaine [D].

### 2.7 Données de monde (T5)

- `data/world/zones.json` : `route_39` (« Route 39 », `route`, `johto`, sous-titre « Oliville —
  Route 38 », description R-23), `route_38` (« Route 38 », sous-titre « Route 39 — Rosalia »,
  R-24), `ecruteak_city` : `maps` = les six cartes, sous-titre « Route 38 — Route 37 » [D],
  services Centre et Boutique, description **R-25** (validée : plus `draft`, retirée de
  `PENDING_DRAFTS`).
- `interiors.json` + 5 ; `rest_points.json` + `ecruteak_center` (`registers: true`) ;
  `lighting.json` : les trois extérieurs `johto_auto`, les intérieurs `interior_warm` ;
  `music_zones.json` : `route_39` → `road_to_viridian`, `route_38` → `road_to_cerulean`,
  `ecruteak_city` → `pewter_city` [D] (aucune musique de Johto : lot Son) ;
  `data/shops/ecruteak_mart.json` : Poké Ball, Potion, Super Potion, Antidote, Anti-Para, Réveil,
  Rappel [D] ; `assets/ui/map/johto_placeholder_areas.json` : rectangles de `route_39` et
  `route_38` [D] ; aperçus `assets/ui/map/zones/route_39.webp`, `route_38.webp`,
  `ecruteak_city.webp` (`build_zone_previews.gd --only=…`).
- `fly_points.json` : inchangé (`ecruteak_city` → `from_center`, arrivée devant le Centre).

### 2.8 Départs de débogage (T9, `tools/debug_start/`)

| Fichier | Partie |
|---|---|
| `johto_route_39.json` | Kaiminus N5, 5 Poké Balls, 1 Potion, équipe de Kanto confisquée, `johto_arrived`, `johto_act1`, `storage_offline`, `johto_starter_chosen`, à l'entrée ouest de la Route 39 (`from_olivine`) |
| `johto_rosalia.json` | Croconaw N13 (ou Kaiminus N13), Fouinette N12, Wattouat N12, 3 000 ₽, 5 Poké Balls, 3 Potions, à l'entrée de Rosalia (`from_route_38`) : scène des Sbires, doyen, gardes, Centre, Boutique |
| `johto_rosalia_night.json` | Idem, `period: night` (lampes, herbe des tours) |
| `johto_rosalia_tuesday.json` | Idem, `weekday: tuesday` (Margot) |

Clé **`weekday`** neuve de `DebugStart` (`WorldClock.force_weekday` / `release_weekday`, même
modèle que `force_period`) [D] ; sans elle, le jour réel.

## 3. Tâches

| N° | Tâche | Critère |
|---|---|---|
| T1 | `tools/gen_joh2_data.py` : PNJ, Dresseurs, objets, dialogues, scènes | Fichiers écrits ; textes §13 mot pour mot (`test_joh2_data`) |
| T2 | `tools/build_joh2_maps.gd` : trois cartes | Grille = plan ; toutes les cases praticables connexes ; emprises bloquées ; lampes de nuit |
| T3 | Raccords, sorties, barrières | 39 ↔ 38 ↔ Rosalia aller-retour ; Oliville, Route 37, Route 42, Bois « à venir » ; gardes repoussent |
| T4 | Intérieurs (`--rosalia`) | Portes aller-retour ; soin, point de repos « Rosalia » ; PC « Le réseau de Kanto ne répond pas. » ; Boutique |
| T5 | Données de monde | Tests d'inventaire verts (zones, musique, intérieurs, repos, Vol, Carte, aperçus) |
| T6 | Rencontres par moment | `get_table` par moment ; Rosalia de jour : rien |
| T7 | Scènes et drapeaux | Sbires une fois, fuite par l'avenue, sage « après » ; doyen pose le drapeau ; gardes |
| T8 | PNJ de la semaine | Margot le mardi seulement, don une fois ; Lucien : textes et scène, message au JOH1 |
| T9 | Départs de débogage, clé `weekday` | Les quatre fichiers se lisent et s'appliquent ; `weekday` imposé |
| T10 | Tests (`test_joh2_data`, `test_joh2_maps`) et réalignement des registres | `tools/test.sh --changed` vert |
| T11 | Captures Mac : Route 39 jour / nuit, Rosalia jour / nuit, scène des Sbires | Relues ; défauts fonctionnels corrigés |
| T12 | QA A17 (tour demandé à la coordination) | Parcours Route 39 → Rosalia, scènes, Centre, Boutique, Margot (mardi forcé), nuit |
| T13 | CI (`tools/ci_wait.sh HEAD`, « success »), refusion de `main`, CI, fusion `--no-ff`, push | `main` vert |
| T14 | `etat-projet.md`, reportés, prompt du JOH3, compte rendu | — |

## 4. Critères d'acceptation

1. Depuis Oliville (ou le départ `johto_route_39`), la Route 39 se traverse jusqu'à la Route 38
   sans herbes ; Hugo et Lina sont évitables ; la Potion est derrière la ferme ; panneaux R-1,
   R-2 ; fermière R-3 ; de nuit, Hoothoot et Mystherbe remplacent Fouinette et Wattouat.
2. Route 38 : Paul et Théo évitables, Inès inévitable sur le passage d'une case ; Poké Balls au
   fond de l'impasse ; Super Potion dans le tronc ; promeneur R-10 ; panneau R-6.
3. Rosalia : titre « ROSALIA » à l'entrée ; au premier pas, la scène des Sbires (R-12 à R-14) et
   leur fuite vers l'est, une seule fois ; le sage dit R-15 ensuite ; le doyen (toit rouge) R-16,
   R-17 puis R-18 ; porte de la Tour Cendrée R-19 ; garde de la Tour Carillon R-20 et recul ;
   sortie est refusée (garde) ; sortie sud « Route 37 — À venir » ; Centre (soin, repos, PC hors
   ligne), Boutique (Poké Balls), maisons (Antidote ×2 une fois).
4. De nuit (heure réelle ou `period`), les lampes s'allument, l'herbe des tours donne Cornèbre et
   Hoothoot (rare) ; de jour, rien.
5. Un mardi (réel ou `weekday`), Margot est près du Centre et donne 2 Rappels une fois ; un autre
   jour, elle n'y est pas.
6. Tests ciblés verts, import headless sans erreur, CI verte sur la tête, QA A17 sans bloquant,
   fusion dans `main`.

## 5. Risques

- Raccord Oliville : les deux cartes se construisent en parallèle ; chaque côté est « À venir »
  jusqu'à la fusion ; **relancer `build_joh2_maps.gd --maps=route_39`** (ou le builder du JOH1)
  après la fusion et vérifier `test_map_links`.
- Fichiers partagés avec le JOH1 (`zones.json`, `interiors.json`, `rest_points.json`,
  `music_zones.json`, `lighting.json`, `test_no_draft_in_data.gd`, `test_zone_library.gd`,
  `j22_ids.gd`, `build_painted_interiors.gd`, `debug_start.gd`) : ajouts en fin de liste, conflits
  triviaux ; règle d'ancienneté JOH1 > JOH2.
- Registres d'inventaire : les identifiants `joh2_*` doivent être écartés des grands registres
  (comme `j22_`), sinon `test_dialogue_data` / `test_cutscene_data` exigent leur déclaration.
- Scène des Sbires interrompue (application tuée) : le drapeau est posé **au début** de la scène
  (modèle du Rocket d'Azuria) ; les Sbires manquent au rechargement, le sage dit R-15 : acceptable
  [D].
- Herbe des tours sans table de jour : vérifier qu'un terrain `grass` sans table n'émet aucune
  erreur (test dédié).

## 6. Valeurs par défaut [D] posées par ce plan

Tuiles et bâtiments provisoires (maisons de Lavanville, maison d'Argenta pour les sages, maison de
pêcheur pour la ferme, tours en aplats) ; lampes de nuit ; sprites des PNJ ; Pokémon de la ferme
en points d'examen ; `prize_per_level` ; taux 3 de l'herbe des tours ; sous-titre de Rosalia ;
musiques de substitution ; Boutique à 7 objets ; grilles des intérieurs ; sage « avant » = R-13 ;
don de la semaine une fois pour toutes ; textes en brouillon (garde de la Route 42, habitants,
Pokémon de la ferme) ; clé `weekday` du départ de débogage ; warp de la Tour Cendrée gardé par
`johto_burned_tower_open` ; rectangles des routes sur l'illustration de Johto.

## 7. Questions ouvertes (pour Kevin, non bloquantes)

- JOH2-Q1 : textes en brouillon (garde de la Route 42, habitants des maisons, Pokémon de la
  ferme) à relire.
- JOH2-Q2 : la fermière (R-3) parle à toute heure ; les Tauros « nerveux depuis quelques nuits »
  : garder tel quel ?

## 8. Fait

(journal rempli tâche par tâche)
