# Jalon JOH4 — Le détour du sud : Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss

> **PLAN — aucun code n'est écrit par ce document.** Sources de vérité :
> `docs/design/dossier-joh-05-ecorcia.md` (textes E-1 à E-36 et arbitrages JH-37 à JH-39 validés
> par Kevin le 2026-11-02 ; le reste porte des défauts **[D]**) ; grilles `tools/plans/route_34.txt`,
> `ilex_forest.txt`, `azalea_town.txt`, `slowpoke_well_b1f.txt`, `slowpoke_well_b2f.txt`
> (validées le 2026-11-02, **elles font foi**) ; vues générales `docs/design/reference/route-34-*`,
> `bois-aux-chenes-*`, `ecorcia-*`, `puits-ramoloss-b1f-*`, `puits-ramoloss-b2f-*` (validées le
> 2026-11-03, DA seulement). Systèmes du JOH0 (`docs/tech/jalon-joh0.md` §2 et §8), outils et
> conventions du JOH2 (`docs/tech/jalon-joh2.md`, `tools/gen_joh2_data.py`,
> `tools/build_joh2_maps.gd`) et grotte du JOH1 (`tools/build_joh1_sea_cave.gd`). Écrit le
> 2026-11-04 sur la branche `claude/joh4-ecorcia-cbf565` (cut de `main` @ `695e0216` ; `main`
> refusionné dès que JOH1 et JOH2 y sont).

> Objectif jouable : **du sud de Doublonville au fond du Puits Ramoloss, et retour** : Route 34
> (trois Dresseurs dont Félix inévitable à la clôture, pêcheur, maison de l'ancienne Pension, étang
> surfable, Super Potion), Bois aux Chênes (sentier à trois traversées, autel examinable, vieille
> femme, deux Dresseurs, Repousses, Super Bonbon caché, charbonnier et Canarticho), Écorcia (titre,
> rues sans Ramoloss, Centre, Boutique, maison de Fargas, maison, charbonnerie en façade, Sbire à la
> descente du puits), le récit de Fargas et sa descente, Puits B1F (Fargas tombé, trois Sbires),
> Puits B2F (Brace, papiers, Fargas et la Roche Royale), retour des Ramoloss dans Écorcia, Vincent
> le vendredi, rencontres par moment, Corde Sortie.
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA sur l'A17,
> fusion dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change
> (règle 1 : rien à valider seul).

## 0. État des lieux (relu sur `main`, 2026-11-04)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Outils de cartes et de données | JOH2 (`build_joh2_maps.gd`, `gen_joh2_data.py`) et JOH1 (`build_joh1_sea_cave.gd`) pas encore dans `main` à l'écriture | Même modèle : `tools/build_joh4_maps.gd` (cinq cartes, extérieurs et puits) et `tools/gen_joh4_data.py` ; code commencé après la fusion de JOH1 et JOH2 dans `main` (refusion) |
| Zones | `azalea_town` déclarée (`maps: []`, `johto`) ; point de Vol `azalea_town` → `from_center` | Cartes remplies, zones `route_34`, `ilex_forest`, `slowpoke_well` neuves |
| Doublonville | Carte du JOH3 (session parallèle) | Raccord nord de la Route 34 « À venir » (« Doublonville ») tant que `goldenrod_city.tscn` manque ; relancer l'outil à la fusion du second |
| Objets | `kings_rock` existe (JOH0) ; ni Ordre de mission ni Carte d'accès | `data/items/items_joh4.json` : `mission_order`, `radio_card` (objets clés) |
| Lecture d'un objet clé | Aucun objet « lisible » : le Sac montre la description de l'objet | **[D]** : l'Ordre de mission se lit dans le panneau de détail du Sac (sa description = E-22) ; aucun bouton LIRE neuf |
| Grottes | `caves.json` : catégorie grotte, Corde Sortie, `calm_cells` | Grotte `slowpoke_well` (B1F, B2F), Corde Sortie → `azalea_town` / `from_well` |
| Art | Vues générales validées ; aucun décor peint ; pas de sprite de Fargas, Brace, Vincent, Canarticho ; Ramoloss peint (`pokemon/slowpoke`) | Tuiles provisoires, kit de Kanto, sprites existants [D] ; « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH4A** — les cartes | T1 données générées, T2 cinq cartes, T3 raccords, T4 intérieurs, T5 données de monde, T6 rencontres | Tests, captures Mac |
| **JOH4B** — l'histoire | T7 Fargas, Sbires, Brace, papiers, Roche Royale, retour des Ramoloss ; T8 Vincent ; T9 départs de débogage ; T10 tests ; T11 captures | Tests, captures Mac |
| Clôture | T12 QA A17, T13 CI et fusion, T14 état du projet et compte rendu | Déléguée |

## 2. Conception technique

### 2.1 Cartes et identifiants

| Carte | Identifiant | Grille | Taille | Lumière | Outil |
|---|---|---|---|---|---|
| Route 34 | `route_34` | `route_34.txt` | 24 × 48 | `johto_auto` | `tools/build_joh4_maps.gd` |
| Bois aux Chênes | `ilex_forest` | `ilex_forest.txt` | 48 × 48 | `johto_auto` | idem |
| Écorcia | `azalea_town` | `azalea_town.txt` | 44 × 36 | `johto_auto` | idem |
| Puits B1F | `slowpoke_well_b1f` | `slowpoke_well_b1f.txt` | 30 × 24 | `cave` [D] | idem (grotte) |
| Puits B2F | `slowpoke_well_b2f` | `slowpoke_well_b2f.txt` | 30 × 24 | `cave` [D] | idem (grotte) |
| Centre | `azalea_center` | définition commune | 15 × 10 | `interior_warm` | `build_painted_interiors.gd --azalea` |
| Boutique | `azalea_mart` | définition commune | 15 × 10 | `interior_warm` | idem |
| Maison de Fargas | `azalea_kurt_house` | grille de maison de Lavanville [D] | 15 × 10 | `interior_warm` | idem |
| Maison | `azalea_house_1` | idem [D] | 15 × 10 | `interior_warm` | idem |
| Maison de la Route 34 | `route_34_house` | idem [D] | 15 × 10 | `interior_warm` | idem |

- Tuiles provisoires (`OverworldTiles`) : `.` herbe, `=` terre, `p` pavé, `h` hautes herbes,
  `T` `G` forêt, `M` mer (eau, bloquée), `w` eau surfable (étang, mares), `x` clôture / margelle,
  `C` clairière (herbe), `A` autel, `y` fleurs, `s` souche, `k` bûches, `Q` puits, `E` descente,
  emprises `m H C O K` bloquées. Grottes : sol de grotte, `#` paroi, `g` gravats (rencontres),
  `o` rocher, `R` caisses, `U` `V` échelles. **La grille fait foi** (test « grille de la scène =
  plan », modèle `test_joh2_maps`).
- Bâtiments du kit peint [D] : Centre `bldg_centre_01`, Boutique `bldg_boutique_01`, maisons
  `bldg_maison_argenta_01` (Fargas, maison, maison de la Route 34) ; charbonnerie : aplat
  provisoire (modèle des tours du JOH2) ; autel : aplat provisoire.
- Surf : l'étang de la Route 34 et l'eau des deux niveaux du puits (`surf_cells`, JH-36) ; pêche
  sur l'étang [D].
- Lampes de nuit (Écorcia) : fenêtres du Centre et de la Boutique, deux réverbères [D].
- Écran : la Route 34 et le Bois ont un ciel ; le puits est une grotte (`caves.json`), sans
  rencontre sur le sol calme (`.`), rencontres sur les gravats (`g`) et l'eau.

### 2.2 Raccords et sorties (T3)

| Passage | Mécanisme |
|---|---|
| Route 34 (10..12, 0) ↔ Doublonville (34..36, 59) | PUSH ↑ vers `goldenrod_city` / `from_route_34` (`_1`, `_2`) ; « À venir » (« Doublonville ») tant que la carte manque ; arrivée `from_goldenrod` (+ `_1`, `_2`) tournée ↓ |
| Route 34 (10..12, 47) ↔ Bois (8..10, 0) | PUSH ↓ / PUSH ↑ ; `from_route_34` / `from_ilex` |
| Bois (36..38, 47) ↔ Écorcia (20..22, 0) | PUSH ↓ / PUSH ↑ ; `from_ilex` / `from_azalea` |
| Écorcia (37, 7) ↔ B1F (3, 2) | descente STEP_ON ↑ vers `slowpoke_well_b1f` / `from_azalea` ; échelle du B1F STEP_ON → `azalea_town` / `from_well` (37, 8) |
| B1F (3, 20) ↔ B2F (3, 3) | échelles STEP_ON ; `from_b1f` / `from_b2f` |
| Portes | Centre (10..11, 20), Boutique (30..31, 20), Fargas (10, 30), maison (30, 30), maison de la Route 34 (17, 9) ; retours `retour_*` ; `from_center` = `retour_centre` (point de Vol) |
| Barrière du puits | déclencheur (37, 8) sens ↑, scène `azalea_well_guard` `unless johto_kurt_told` : E-14 (première page) puis un pas en arrière [D] |

### 2.3 Données générées (T1, `tools/gen_joh4_data.py`)

Lit les positions des cinq grilles et écrit `data/npcs/<carte>.json`, `data/trainers/<carte>.json`,
`data/encounters/<carte>.json`, `data/dialogues/joh4_*.json`, `data/cutscenes/joh4_*.json`, les
PNJ des intérieurs. Textes §14 mot pour mot (« / » = page, « · » = variante) ; textes absents du
dossier en `draft` + `PENDING_DRAFTS` : Canarticho (examen), Ramoloss sans queue (examen),
habitant de la maison d'Écorcia, réplique de Fargas tombé une fois la scène jouée (= E-15 [D]).
Sprites [D] : Sophie `lass`, Bruno `pokemaniac`, Félix `gambler`, Tom `scout`, Céline
`cooltrainer_f`, Sbires `rocket_grunt_m` / `rocket_grunt_f`, Brace `rocket_grunt_m`, Fargas
`old_man`, vieille femme `aoki`, charbonnier `hiker`, Vincent `docker`, pêcheur
`fisher_route_12`, habitante `beauty`, homme de la Route 34 `gentleman`, garçon `kid`, Ramoloss
`pokemon/slowpoke` ; Canarticho : examen seul (aucune planche).

Classes de combat [D] : Sophie `fillette`, Bruno `pokemaniac`, Félix `jongleur`, Tom `scout`,
Céline `topdresseuse`, Sbires `sbire_rocket` / `sbire_rocket_f`, Brace `sbire_rocket` (nom
« Brace », carte de grand adversaire « BRACE — Admin de la Team Rocket » sans portrait).
`prize_per_level` [D] : 20 (Fillette, Scout), 25 (Pokémaniac, Jongleur), 35 (Dresseuse), 30
(Sbires), Brace `prize_money` 2 000 [D], `ai: smart`, sac et changements permis.

### 2.4 Rencontres (T6)

| Table | Carte | Terrain | `period` | Taux | Niveaux | Espèces (poids) |
|---|---|---|---|---|---|---|
| `route_34_grass_day` | `route_34` | herbe | `["morning", "day"]` | 25 | 16–19 | sentret 25, abra 20, nidoran_f 15, nidoran_m 15, raticate 15, ditto 10 |
| `route_34_grass_night` | `route_34` | herbe | `night` | 25 | 16–19 | hoothoot 35, raticate 25, ditto 15, nidoran_f 12, nidoran_m 13 |
| `route_34_water` | `route_34` | eau | toute la journée [D] | 10 | 15–20 | tentacool 60, psyduck 30, wooper 10 [D] |
| `ilex_forest_grass_morning` | `ilex_forest` | herbe | `morning` | 25 | 17–20 | teddiursa 25, paras 25, caterpie 15, weedle 15, heracross 5, oddish 15 |
| `ilex_forest_grass_day` | `ilex_forest` | herbe | `day` | 25 | 17–20 | paras 30, caterpie 20, weedle 20, oddish 20, sentret 10 |
| `ilex_forest_grass_night` | `ilex_forest` | herbe | `night` | 25 | 17–20 | murkrow 30, noctowl 15, hoothoot 25, oddish 20, paras 10 |
| `slowpoke_well_cave` | B1F, B2F | grotte (gravats) | toute la journée | 10 [D] | 18–22 | slowpoke 45, zubat 45, geodude 10 |
| `slowpoke_well_water` | B1F, B2F | eau | toute la journée | 10 [D] | 18–22 | slowpoke 70, poliwag 30 |

L'eau de la Route 34 n'a pas de ligne au dossier : table [D] (Tentacool côtier). Identifiants
d'espèces relus contre `data/pokemon/` à l'écriture (sinon la table est refusée par le test).

### 2.5 Scènes et drapeaux (T7)

| Scène | Déclencheur | Variante | Étapes |
|---|---|---|---|
| Panneaux, pêcheur, vieille femme, charbonnier, habitante | PNJ / panneau | — | E-1, E-2, E-4, E-6, E-8, E-9, E-36 ; habitante E-10 `unless johto_slowpoke_well_cleared`, E-26 `if` |
| Autel | examen (23, 11) | — | E-5 ; `set johto_shrine_seen` (variante unique, posé à chaque lecture) |
| Titre d'Écorcia | arrivée (titre de zone automatique, `zones.json`) | — | `johto_azalea_arrived` non posé : le titre de zone suffit [D] (le déclencheur de la grille est ignoré) |
| `azalea_well_guard` | (37, 8) ↑ | `unless johto_kurt_told` | face Sbire, page 1 de E-14 (`azalea_well_grunt_block`), un pas en arrière |
| `azalea_kurt_story` | Fargas (maison), `unless johto_kurt_told` | — | E-11, E-12, E-13 ; `set johto_kurt_told` ; `change_map azalea_town` arrivée `kurt_scene` (37, 10) tournée ↑ ; `spawn` Sbire (38, 8) et Fargas (36, 10) ; E-14 (trois pages, Sbire puis narration [D]) ; Sbire descend (37, 8 → 37, 7), `despawn` ; Fargas le suit, `despawn` |
| `slowpoke_well_kurt_fall` | B1F, colonne (6, 2..5) → | `unless johto_kurt_fell` [D] | `set johto_kurt_fell` ; `emote` Fargas ; face ; E-15 |
| Sbires E, F, G | vue | — | combats ordinaires, E-16 |
| `slowpoke_well_brace` | B2F (25..27, 10) ↑ | `unless johto_brace_defeated` | Brace `emote`, s'approche ; E-17 ; `battle` (`win` `johto_brace_defeated`, `lose` `lost_brace` [D]) ; si victoire : E-18, E-19, Brace s'enfuit (vers (24, 16), `despawn`), E-20, `spawn` papiers (25, 5), `spawn` Fargas (5, 5) ; si défaite : `wake_up` |
| `slowpoke_well_papers` | papiers (PRENDRE) | `unless johto_radio_pass` | `despawn` ; `give mission_order` ; `give radio_card` ; E-21 ; `set johto_radio_pass` |
| `slowpoke_well_kings_rock` | Fargas au B2F | `unless johto_slowpoke_well_cleared` | E-23 ; E-24 ; `give kings_rock` ; ligne système ; `set johto_slowpoke_well_cleared` |
| Fargas chez lui (après) | PNJ `fargas_home` `if johto_slowpoke_well_cleared` | — | E-25 |
| Ramoloss d'Écorcia | PNJ `if johto_slowpoke_well_cleared` | — | E-27 (trois rues) ; margelle E-31 |
| Fargas tombé (B1F) | PNJ `if johto_kurt_told unless johto_slowpoke_well_cleared` | — | E-15 |
| Ramoloss sans queue (B2F) | PNJ `unless johto_slowpoke_well_cleared` | — | examen [D] (`draft`) |
| Objets | PNJ objet / souche | `unless got_<id>` | `give found`, `set` |

Drapeaux du jalon : `johto_shrine_seen`, `johto_kurt_told`, `johto_kurt_fell` [D],
`johto_brace_defeated`, `lost_brace` [D], `johto_radio_pass`, `johto_slowpoke_well_cleared`,
`week_friday_gift`, `got_route_34_item_1`, `got_ilex_item_1`, `got_ilex_hidden_1`,
`got_well_b1f_item_1`, `got_well_b2f_item_1`. Combats ordinaires : drapeaux des Dresseurs
(système existant).

Cas limites (dossier §11) : défaite contre Brace → Centre d'Écorcia (`azalea_center`,
`registers: true`), Fargas reste au B1F, Brace au B2F ; sortie du puits avant Brace → Ramoloss
absents ; Roche Royale au terminal d'échange local (système JOH0, rien de neuf) ; œuf (système
JOH0) ; Corde Sortie → `from_well`.

### 2.6 Vincent, le vendredi (T8)

Écorcia (8, 11), `if_weekday: ["friday"]`, dialogue `week_friday_vincent` : `unless
week_friday_gift` : E-28 (deux pages) puis `cutscene: week_friday_gift` (`give super_repel × 2`,
ligne système, `set week_friday_gift`) ; `if` : « À vendredi ! ». Don une fois pour toutes (modèle
JOH2). Fichiers `joh4_week.json`.

### 2.7 Données de monde (T5)

- `zones.json` : `route_34` (« Route 34 », sous-titre « Doublonville — Bois aux Chênes », E-32),
  `ilex_forest` (« Bois aux Chênes », E-33), `slowpoke_well` (« Puits Ramoloss », E-35, cartes
  B1F et B2F), `azalea_town` : cartes, services Centre et Boutique, description E-34 (plus
  `draft`).
- `interiors.json` + 5 ; `rest_points.json` + `azalea_center` ; `lighting.json` ; `caves.json` +
  `slowpoke_well` ; `music_zones.json` (musiques de substitution [D]) ;
  `data/shops/azalea_mart.json` [D] (Poké Ball, Super Ball, Potion, Super Potion, Antidote,
  Anti-Para, Repousse) ; aperçus de la Carte (`build_zone_previews.gd`) ; rectangles de la carte
  provisoire de Johto [D].
- `data/items/items_joh4.json` : `mission_order` (« Ordre de mission », clé, description = E-22),
  `radio_card` (« Carte d'accès », clé, « Tour Radio de Doublonville »).

### 2.8 Départs de débogage (T9)

| Fichier | Partie |
|---|---|
| `johto_route_34.json` | Équipe de Johto niv. 17–20 (Kaiminus/Croconaw, Fouinette, Wattouat, Togepi), drapeaux JOH1 à JOH3 (`johto_arrived`, `johto_act1`, `storage_offline`, `johto_starter_chosen`, `johto_rosalia_rockets_seen`, `johto_goldenrod_arrived`, `johto_egg_received`, `johto_radio_tower_closed_seen`, `johto_azalea_clue`), à l'entrée nord de la Route 34 |
| `johto_ilex_morning.json`, `johto_ilex_night.json` | Idem, à l'entrée du Bois, `period` imposé |
| `johto_azalea.json` | Idem, équipe niv. 20–22, à l'entrée d'Écorcia |
| `johto_slowpoke_well.json` | `johto_kurt_told`, au B1F |
| `johto_brace.json` | Sbires battus, devant le couloir de Brace, équipe niv. 22–24 |
| `johto_azalea_after.json` | Tout le jalon fait (Ramoloss de retour, objets clés, Roche Royale) |
| `johto_azalea_friday.json` | `weekday: friday` (Vincent) |

### 2.9 Données pour les autres jalons

- JOH3 : arrivées `from_route_34` (+ `_1`, `_2`) attendues sur Doublonville (34..36, 59) ; la
  Route 34 fournit `from_goldenrod` (+ `_1`, `_2`).
- JOH5 : objets clés `mission_order`, `radio_card`, drapeaux `johto_brace_defeated`,
  `johto_radio_pass` (message à la session JOH5 une fois les identifiants posés).

## 3. Tâches

| N° | Tâche | Critère |
|---|---|---|
| T1 | `tools/gen_joh4_data.py` | Textes §14 mot pour mot (`test_joh4_data`) |
| T2 | `tools/build_joh4_maps.gd` : cinq cartes | Grille = plan ; praticables connexes ; emprises bloquées ; eau surfable ; sol calme du puits |
| T3 | Raccords, barrière du puits | Allers-retours ; Doublonville « À venir » ; barrière levée par `johto_kurt_told` |
| T4 | Intérieurs (`--azalea`) | Portes ; soin et repos « Écorcia » ; PC hors ligne ; Boutique |
| T5 | Données de monde, objets clés | Inventaires verts |
| T6 | Rencontres par moment, grotte, eau | `get_table` par moment ; puits toute la journée |
| T7 | Scènes de l'histoire | Ordre Fargas → Brace → papiers → Roche Royale ; Ramoloss de retour |
| T8 | Vincent | Le vendredi seulement, une fois |
| T9 | Départs de débogage | Se lisent et s'appliquent |
| T10 | Tests (`test_joh4_data`, `test_joh4_maps`, `test_joh4_story`) et registres | `tools/test.sh --changed` vert |
| T11 | Captures Mac : Bois de matin et de nuit, autel, Écorcia avant / après, B2F et Brace | Relues |
| T12 | QA A17 (tour demandé à la coordination) | Parcours Route 34 → Brace → retour, sans bloquant |
| T13 | CI « success », refusion de `main`, CI, fusion `--no-ff`, push | `main` vert |
| T14 | `etat-projet.md`, reportés, compte rendu | — |

## 4. Critères d'acceptation

1. Depuis le départ `johto_route_34`, la Route 34 se traverse sans herbes ; Sophie et Bruno sont
   évitables, Félix ne l'est pas ; Super Potion au bord de l'étang ; panneau E-1, pêcheur E-2,
   maison E-30 ; l'étang se surfe.
2. Bois aux Chênes : trois traversées, H1 et H3 obligatoires ; autel E-5 (pose
   `johto_shrine_seen`) ; vieille femme E-6 ; Tom et Céline évitables ; Repousses, Super Bonbon dans
   la souche ; charbonnier E-8 ; le matin, Teddiursa et Scarhino ; la nuit, Cornèbre et Noarfang.
3. Écorcia : titre, panneau E-9, habitante E-10, aucun Ramoloss ; le Sbire bloque la descente
   (E-14) ; chez Fargas, E-11 à E-13, puis Fargas fait fuir le Sbire et descend.
4. Puits : Fargas tombé (E-15), Sbire E inévitable, F et G évitables ; Brace (E-17 à E-20), papiers
   (E-21, deux objets clés), Fargas (E-23, E-24, Roche Royale) ; défaite : Centre d'Écorcia, rien
   n'est perdu ; Corde Sortie : devant le puits.
5. Après : trois Ramoloss dans les rues (E-27), un sur la margelle (E-31), habitante E-26, Fargas
   chez lui E-25 ; l'Ordre de mission se lit dans le Sac (E-22).
6. Un vendredi, Vincent donne 2 Super Repousses une fois.
7. Tests ciblés verts, import sans erreur, CI verte, QA A17 sans bloquant, fusion dans `main`.

## 5. Risques

- Raccord Doublonville : construit en parallèle par le JOH3 ; « À venir » jusqu'à la fusion du
  second ; relancer `build_joh4_maps.gd --maps=route_34` puis `test_map_links`.
- Fichiers partagés (`zones.json`, `interiors.json`, `rest_points.json`, `lighting.json`,
  `caves.json`, `music_zones.json`, `test_no_draft_in_data.gd`, `j22_ids.gd`,
  `build_painted_interiors.gd`, `debug_start`) : ajouts en fin de liste ; ancienneté JOH0 > … >
  JOH3 > JOH4.
- Scène de Fargas interrompue : drapeau posé avant le `change_map` ; au rechargement, Fargas est au
  B1F et la barrière levée : acceptable [D].
- Brace : les papiers et Fargas apparaissent par `spawn` pendant la scène (les entrées de
  `data/npcs/` ne se relisent qu'à l'entrée sur la carte) ; au rechargement, les entrées
  conditionnelles prennent le relais.
- Difficulté de Brace (35–60 %) : à mesurer par simulation (outil d'équilibrage existant) si le
  temps le permet ; sinon équipe du dossier telle quelle.

## 6. Valeurs par défaut [D] posées par ce plan

Tuiles et bâtiments provisoires ; aplats de la charbonnerie et de l'autel ; sprites et classes des
PNJ et Dresseurs ; `prize_per_level`, prix de Brace ; table de l'eau de la Route 34 ; taux du
puits ; Boutique ; grilles des intérieurs ; lecture de l'Ordre de mission par la description ;
drapeaux `johto_kurt_fell`, `lost_brace` ; scène de la barrière (page 1 de E-14) ; E-14 joué
quand Fargas arrive ; titre d'Écorcia par la zone ; textes en brouillon (Canarticho, Ramoloss sans
queue, habitant) ; don du vendredi une fois pour toutes ; musiques de substitution.

## 7. Questions ouvertes (pour Kevin, non bloquantes)

- JOH4-Q1 : textes en brouillon (Canarticho, Ramoloss sans queue, habitant de la maison) à relire.
- JOH4-Q2 : un bouton LIRE pour les objets clés lisibles (au lieu de la description du Sac) ?

## 8. Fait

| Tâche | Commit | Note |
|---|---|---|
| Plan | (ce commit) | Ce document |
