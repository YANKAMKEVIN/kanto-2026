# Jalon JOH6 — Les cendres : Tour Cendrée, Route 42, Acajou, Route 43, Lac Colère, repaire

> **PLAN.** Sources de vérité : `docs/design/dossier-joh-07-acajou.md` (textes C-1 à C-46 et
> arbitrages JH-44 à JH-47 validés par Kevin le 2026-11-02 ; le reste porte des défauts **[D]**) ;
> cadre `dossier-joh-00-cadre.md` (§4.3, §5) ; grilles `tools/plans/burned_tower_1f.txt`,
> `burned_tower_b1f.txt`, `route_42.txt`, `mahogany_town.txt`, `mahogany_souvenir_shop.txt`,
> `route_43.txt`, `lake_of_rage.txt`, `mahogany_hideout_b1f.txt` à `b3f.txt`, retouche de
> `rosalia.txt` (validées le 2026-11-03, **elles font foi**) ; vues générales
> `docs/design/reference/*-vue-generale-v1.png` (DA seulement). Systèmes : JOH0
> (`jalon-joh0.md` §2, §8), modèle des cartes et données : JOH2 (`jalon-joh2.md`).
> Écrit le 2026-11-04 sur la branche `claude/joh6-acajou-f527bc` (cut de `main` @ `bdcc90ae`,
> branche du JOH2 fusionnée par avance pour Rosalia et ses outils).

> Objectif jouable : **premier jalon de l'acte 2** (équipe rendue). De Rosalia (le doyen ouvre la
> Tour Cendrée) à Acajou libérée : Tour Cendrée 1F et B1F (réveil des trois chiens, Brace capture
> Raikou), Route 42 (Surf), Acajou, Route 43 (péage), Lac Colère (Léviator rouge), boutique de
> souvenirs (escalier caché), repaire B1F (statues d'alarme), B2F (dalles, cellules, souvenir de
> Dante en sépia, mot de passe), B3F (Brace, générateur, Raikou), accroche du JOH7 au Centre
> d'Acajou ; Samuel (samedi) et Diane (dimanche).
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA A17, fusion
> dans `main`, compte rendu à la coordination.

## 0. État des lieux (2026-11-04)

| Point | Réel | Conséquence |
|---|---|---|
| Rosalia, outils de grille | JOH2 (`build_joh2_maps.gd`, `gen_joh2_data.py`) sur sa branche, fusionnée ici par avance | Retouches de Rosalia **dans les outils du JOH2** (panneau C-3, porte, raccord est, Diane, doyen, sage, garde) ; refusion de `main` dès qu'il y est |
| Acte 1 (JOH3 à JOH5) | Codé en parallèle ailleurs | Départs de débogage qui posent l'état de fin d'acte 1 (§2.9) ; drapeau d'entrée lu : `johto_act2` |
| Trous, dalles, portes à drapeau, rencontres fixes | `WarpPoint` FALL (J24/J25), `SpinTileField` (J20), `FlagGate` + `blocking_cells` (J15/J17), `wild_battle` + `static` (S2G) | Réutilisés tels quels |
| Surf, pêche | Tuile `WATER` surfable ; tables `terrain: water` ; `data/fishing/water_rod.json` | Lac de la Route 42 et Lac Colère en `WATER` ; table Super Canne du lac ajoutée en fin de fichier |
| Variante de couleur | Aucune | **Neuf** : champ `variant` du Pokémon (§2.6) |
| Souvenir sépia | Aucun filtre plein écran, aucun moyen de cacher le joueur | **Neuf** : étape de scène `flashback` (§2.7) |
| Art | Aucun sprite de Brace, Dante jeune, Giovanni jeune, déserteur, Samuel, Diane ; pas de Raikou / Entei / Suicune dans le monde | Sprites existants [D] (§2.3) ; chiens et cage en aplats provisoires ; tout en « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH6A** — les cartes | T1 données générées, T2 cartes, T3 raccords, T4 intérieurs, T5 données de monde, T6 rencontres | Tests, captures Mac |
| **JOH6B** — l'histoire | T7 scènes (Tour, péage, lac, boutique, repaire, Raikou, Centre), T8 variante rouge, T9 souvenir sépia, T10 PNJ de la semaine, T11 départs de débogage, T12 tests, T13 captures | Tests, captures Mac |
| Clôture | T14 QA A17, T15 CI et fusion, T16 état du projet, compte rendu | Déléguée |

## 2. Conception technique

### 2.1 Cartes et identifiants

| Carte | Identifiant | Grille | Lumière | Outil |
|---|---|---|---|---|
| Tour Cendrée 1F | `burned_tower_1f` | `burned_tower_1f.txt` (28 × 24) | `johto_auto` [D] (ruine à ciel ouvert) | `tools/build_joh6_maps.gd` |
| Tour Cendrée B1F | `burned_tower_b1f` | `burned_tower_b1f.txt` (20 × 16) | `cave` [D] | idem |
| Route 42 | `route_42` | `route_42.txt` (72 × 20) | `johto_auto` | idem |
| Acajou | `mahogany_town` | `mahogany_town.txt` (36 × 30) | `johto_auto` | idem |
| Route 43 | `route_43` | `route_43.txt` (24 × 52) | `johto_auto` | idem |
| Lac Colère | `lake_of_rage` | `lake_of_rage.txt` (56 × 52) | `johto_auto` | idem |
| Boutique de souvenirs | `mahogany_souvenir_shop` | `mahogany_souvenir_shop.txt` (15 × 10) | `interior_warm` | idem (coque intérieure) |
| Repaire B1F, B2F, B3F | `mahogany_hideout_b1f`, `_b2f`, `_b3f` | `mahogany_hideout_b*.txt` | `interior_cool` [D] | idem (comme le repaire de Céladopole) |
| Centre d'Acajou | `mahogany_center` | définition commune | `interior_warm` | `build_painted_interiors.gd --acajou` |
| Maisons 1 et 2 | `mahogany_house_1`, `_2` | `lavanville_maison_1/2.txt` [D] | `interior_warm` | idem |
| Souvenir (ancien QG) | `dante_flashback_hq` | sans grille [D] : bureau 15 × 10 | `interior_warm` | `build_joh6_maps.gd` |

- Extérieurs en tuiles provisoires (`OverworldTiles`, modèle JOH2) : `.` herbe, `=` terre, `h`
  hautes herbes, `p` pavé, `D` porte, `T` `x` forêt, `G` arbre, `R` falaise, `w` **eau (WATER,
  surfable)**, `Q` falaise (porte du Mont Creuset, examen), `K` `C` `O` `m` `N` emprises (bloquées),
  `o` rocher (CLIFF). Acajou : Centre `bldg_centre_01`, boutique `bldg_boutique_01` [D], maisons
  `bldg_maison_argenta_01` [D] ; poste de péage en aplat provisoire ; antenne : aplat sur le toit.
- Tour et repaire : coque intérieure du repaire de Céladopole (`InteriorTiles`, sol béton / murs) ;
  Tour : `c` cendres (sol `floor` des rencontres), `.` dallage, `P` poutres (bloquées), `O` trou
  (WarpPoint **FALL** → `burned_tower_b1f` / `chute`, dessin noir), `V`/`U` échelles.
- Lampes de nuit (`night_lights`) [D] : Acajou (devant le Centre et la boutique), Route 43 (péage).

### 2.2 Raccords

| Passage | Mécanisme |
|---|---|
| Rosalia (55, 30..32) ↔ Route 42 (0, 9..11) | PUSH, arrivées case à case (`from_route_42`, `from_ecruteak`) ; garde de Rosalia `unless johto_act2` (JOH2) |
| Rosalia porte (8..9, 12) ↔ Tour 1F (13..14, 23) | STEP_ON ↑ `if johto_burned_tower_open` → `from_city` ; PUSH ↓ → `retour_tour_cendree` |
| Tour 1F échelle (3, 2) ↔ B1F échelle (3, 2) | STEP_ON (escalier), `from_b1f` / `from_1f` |
| Tour 1F trous `O` → B1F | FALL → `chute` (10, 3) |
| Route 42 (71, 9..11) ↔ Acajou (0, 14..16) | PUSH, case à case |
| Acajou (16..18, 0) ↔ Route 43 (10..12, 51) | PUSH, case à case |
| Route 43 (10..12, 0) ↔ Lac Colère (26..28, 51) | PUSH, case à case |
| Lac Colère (55, 3..5) → Sentier du Mont Argenté | PUSH « À venir » (JOH9) ; garde forestier + barrière `unless johto_act3` (textes A-1, A-2 du dossier JOH-10 si présents, sinon `draft`) |
| Acajou portes | Centre, boutique, maisons : STEP_ON ↑, retours tournés ↓ ; `retour_centre` = `from_center` (point de Vol) |
| Boutique (12, 3) ↔ Repaire B1F (2, 1) | escalier `if johto_hideout_found` ; avant : case bloquée par un `FlagGate` (étagère) ; retour `from_hideout` |
| B1F (28, 12) ↔ B2F (28, 12) ; B2F (3, 1) ↔ B3F (3, 1) | escaliers, arrivées de la grille |
| Corde Sortie dans le repaire | point de sortie = Acajou `retour_boutique` (carte « donjon » [D] : `escape_rope` lit l'entrée du donjon) |

### 2.3 Données générées (T1, `tools/gen_joh6_data.py`)

Modèle `gen_joh2_data.py`. Écrit :
- `data/npcs/<carte>.json` pour les 12 cartes ci-dessus (Dresseurs, PNJ, objets visibles, acteurs
  des scènes), `mahogany_center.json` (infirmière, **déserteur** `if johto_raikou_done`),
  `mahogany_house_1/2.json` (habitants, textes `draft`) ;
- `data/trainers/<carte>.json` (§6 du dossier ; `prize_per_level` [D] : 40 Dresseurs ordinaires,
  45 Sbires, 60 Brace ; `ai: random`, Brace `ai: smart` [D]) ;
- `data/dialogues/joh6_<carte>.json`, `joh6_week.json` ; `data/cutscenes/joh6_<carte>.json`,
  `joh6_week.json` ; `data/encounters/<carte>.json` (§2.4) ;
- textes **mot pour mot** (C-1 à C-46 : « / » = page, « · » = variante) ; les textes absents du
  dossier sont `draft` et listés dans `PENDING_DRAFTS` : sage après l'ouverture, pêcheur avant le
  Léviator rouge (« Le lac est fou. » est donné par la grille : validé avec elle), habitants des
  maisons, vendeur après le repaire, déserteur au Centre après C-45, doyen après C-11.
- Sprites [D] : Odile `channeler`, Sbires `rocket_grunt_m`/`_f`, Marcel et Ludovic
  `fisher_route_12`, Hector `hiker`, Coralie `swimmer_f_water`, Louis `nerd`, Basile `camper`,
  Scientifique `researcher`, **Brace `rocket_civilian`**, déserteur `rocket_grunt_m`, Samuel
  `mountaineer`, Diane `aoki`, vendeur `clerk`, habitants `old_man` / `beauty`, pêcheur
  `fisher_fuchsia`, garde forestier `guard`, **Dante jeune `gentleman`**, **Giovanni jeune
  `giovanni`**, Persian `pokemon/meowth` [D] ; chiens : `pokemon/<espèce>` si la planche existe,
  sinon aplat provisoire (`FlagGate` dessiné).

### 2.4 Rencontres (T6)

Tables du dossier §5, une par (carte, terrain, moment), `period` comme au JOH2 :
`burned_tower_1f_floor` (`terrain: floor`, cases `c`, toute la journée), `route_42_grass_day` /
`_night`, `route_42_water`, `route_43_grass_day` / `_night`, `lake_of_rage_grass_day` / `_night`,
`lake_of_rage_water`. Taux [D] : herbes 25, eau 10, cendres 15. « Ortie » du dossier = **Ortide**
(`gloom`) [D]. Pêche : `old_rod_any` (Magicarpe) suffit ; `super_rod_lake_of_rage` (Magicarpe 50,
Léviator 50, niv. 40–50 [D]) ajoutée **en fin** de `data/fishing/water_rod.json`. Aucune table au
B1F de la tour ni dans le repaire.

### 2.5 Scènes et drapeaux (T7)

| Scène | Où, déclencheur | Condition | Contenu |
|---|---|---|---|
| Sage C-1 | Rosalia, `sage_tour` (dialogue) | `if johto_act2 unless johto_burned_tower_open` | C-1 |
| Doyen C-2 | maison des sages, `doyen` (dialogue, 1re variante) | `if johto_act2 unless johto_burned_tower_open` | C-2, `set johto_burned_tower_open` |
| Panneau C-3 | Rosalia (7, 13) | — | C-3 |
| `burned_tower_floor` | 1F `plancher_effondre` | `unless johto_burned_floor_seen` | C-5, set |
| `burned_tower_beasts` | B1F `scene_chiens` (rangée y 6) | `unless johto_beasts_awakened` | `set johto_beasts_awakened` (en tête) ; C-6 (trois chiens `emote`, puis `animate` : Raikou ↓, Entei ↑, Suicune ←, fondu) ; `spawn brace` à l'est, marche vers le joueur ; C-7 ; C-8 + `flash` ; Raikou pris (aplat de cage) ; C-9 ; Brace et la cage repartent vers l'est, `despawn` ; `set johto_raikou_taken` |
| `ecruteak_dante_plan` | Rosalia `scene_doyen_plan` (8..9, 14) ajouté à la grille [D] | `if johto_raikou_taken unless johto_dante_plan_known` | `spawn doyen` près du joueur ; C-10, C-11 ; `set johto_dante_plan_known` ; le doyen rentre, `despawn` |
| Garde C-12 | Rosalia `garde_carillon` | `if johto_act2` (variante) | C-12 (sinon R-20) |
| `route_43_toll` | Route 43, Dresseur `peager` (sight 1) | Dresseur | C-22 ; après la victoire : `set johto_toll_cleared` (bloc `win` du Dresseur [D] : `trainer.set`) |
| `lake_red_gyarados` | Lac, PNJ `leviator_rouge` (parler depuis l'eau) | `unless johto_red_gyarados_done` | C-25 ; `wild_battle gyarados 50 variant red static` (done = `johto_red_gyarados_done`, caught = `johto_red_gyarados_caught`) ; actor retiré |
| Pêcheur C-26 | Lac `pecheur` | `if johto_red_gyarados_done` | C-26 (avant : « Le lac est fou. », grille) |
| `souvenir_shop_stairs` | boutique `scene_escalier` (12, 4) | `if johto_red_gyarados_done unless johto_hideout_found` | C-28, `set johto_hideout_found` (l'étagère s'efface : `FlagGate`) |
| Vendeur C-19 / C-29 | boutique `vendeur` | `unless johto_hideout_found` : C-19 puis Boutique [D] ; `if` : C-29 | — |
| `hideout_alarm_N` (×3) | B1F `alarme_N` | `unless johto_alarm_N` | `set johto_alarm_N` ; C-30 + `flash` rouge [D] ; `spawn sbire_alarme_N` à sa porte ; marche au joueur ; `battle` (perdu : `wake_up`) |
| Levier | B2F `levier` (examen depuis (13, 15) ↑) | `unless johto_cell_opened` | « Le levier bascule. » [D, `draft`], `set johto_cell_opened` (la grille `porte_cellule` s'efface) |
| `hideout_deserter` | B2F `deserteur` (dialogue) | `unless johto_dante_flashback_seen` | C-32 si la cellule est fermée ; ouverte : C-33, C-34, **souvenir** (§2.7, C-35), C-36, C-37, `set johto_dante_flashback_seen` |
| Porte à mot de passe | B2F `porte_mdp` (3, 3) | `FlagGate` `unless johto_dante_flashback_seen` ; examen | sans le drapeau : « “Mot de passe ?” » [D : 1re bulle de C-38] ; avec : C-38 une fois (`johto_password_said`) puis la porte s'efface |
| Examen générateur | B3F `generateur` | — | C-39 |
| `hideout_brace` | B3F `scene_brace` (9, 8..9) | `unless johto_brace_defeated_2` | Brace vient au joueur ; C-40 ; `battle hideout_brace` (win `johto_brace_defeated_2`) ; C-41 ; C-42 ; Brace file par le passage secret, `despawn` ; défaite : `wake_up` (Brace et Raikou restent) |
| `hideout_generator_off` | B3F `arret_generateur` | `if johto_brace_defeated_2 unless johto_generator_off` | C-43, `set johto_generator_off` (barreaux de (17, 10) levés) |
| `hideout_raikou` | B3F PNJ `raikou` | `if johto_generator_off unless johto_raikou_done` | C-44 ; `wild_battle raikou 60 static intro legendary` (done = `johto_raikou_done`, caught = `johto_raikou_caught` ; **fuite et défaite posent aussi `johto_raikou_done`** [D, §6 du dossier : « il ne peut pas être perdu définitivement », retour post-chapitre noté pour le JOH9]) |
| Déserteur C-45 | Centre d'Acajou | `if johto_raikou_done` | C-45, `set johto_whirl_clue` |
| Samuel, Diane | Acajou (samedi), Rosalia (dimanche) | `if_weekday` | C-46, dons `week_saturday_gift` / `week_sunday_gift` (modèle JOH2) |

Drapeaux du jalon : ceux du dossier §12 et les drapeaux de travail `johto_burned_floor_seen`,
`johto_mahogany_arrived`, `johto_alarm_1..3`, `johto_cell_opened`, `johto_password_said`,
`johto_generator_off`, `johto_red_gyarados_caught`, `johto_raikou_caught`, `got_<objet>`.
Lus sans être posés : `johto_act2` (JOH5), `johto_act3` (JOH9).

### 2.6 Variante rouge (T8, JH-46)

- `Pokemon.variant: StringName` (`&""` = normale). Sauvegarde : clé `"variant"` écrite **seulement
  si non vide** (comme `egg_steps`), lue avec tolérance (absente = normale ; inconnue = normale +
  avertissement) : **pas de changement de version**, une sauvegarde v10 se relit telle quelle.
- `wild_battle` : clé `"variant"` (« red ») passée au Pokémon sauvage ; capture : la variante suit.
- Rendu [D] : teinte rouge (`modulate`) de la planche de combat, de l'icône d'équipe et du résumé
  (`VariantLook.tint(variant)`) ; Pokédex : compte comme Léviator (aucune entrée à part).

### 2.7 Souvenir de Dante (T9, JH-44, JH-45)

- Étape de scène neuve **`flashback`** : `"start"` (fondu au noir, filtre **sépia** plein écran avec
  bord adouci, joueur caché) / `"end"` (fondu, filtre retiré, joueur visible). Le filtre est un
  `CanvasLayer` (`game/world/effects/flashback_filter.gd`, shader `hint_screen_texture`).
- Déroulé : `flashback start` → `change_map dante_flashback_hq` (bureau provisoire, Dante jeune
  derrière la porte en feu, Giovanni jeune et Persian) → C-35 (Giovanni s'éloigne avec Persian :
  `move` + `despawn` ; flammes : `flash` + lueurs) → `change_map mahogany_hideout_b2f` (devant la
  cellule) → `flashback end` → C-36. Le drapeau `johto_dante_flashback_seen` est posé **à la fin**
  (C-37) ; la carte du souvenir a une sortie de secours vers le B2F si l'application est tuée
  pendant le souvenir [D].

### 2.8 Données de monde (T5)

`zones.json` : `burned_tower` (cartes 1F, B1F), `route_42`, `mahogany_town` (+ boutique, Centre,
maisons ; services Centre et Boutique ; point de Vol), `route_43`, `lake_of_rage`,
`mahogany_hideout` (B1F à B3F, souvenir) ; descriptions du dossier §16 (validées), région `johto`.
`interiors.json`, `rest_points.json` (`mahogany_center`), `lighting.json`, `music_zones.json`
(substituts [D]), `fly_points.json` (`mahogany_town` → `from_center`, si absent du JOH0),
`data/shops/mahogany_mart.json` [D], `johto_placeholder_areas.json`, aperçus de la Carte. Ajouts en
**fin de liste** (fichiers partagés avec les JOH3 à JOH9).

### 2.9 Départs de débogage (T11)

État de fin d'acte 1 posé à la main (drapeaux des dossiers JOH-02 à JOH-06 : `johto_arrived`,
`johto_starter_chosen`, `johto_team_returned`, `johto_act2`, `johto_act1` **baissé**, Stockage en
ligne ; équipe de Ligue 58–64 + deux Pokémon de Johto, Surf, Multi Exp si l'objet existe) :
`johto_joh6_rosalia` (devant la maison des sages), `johto_joh6_tower_b1f`, `johto_joh6_route_42`,
`johto_joh6_mahogany` (péage à faire), `johto_joh6_lake` (Léviator rouge), `johto_joh6_hideout`
(B1F), `johto_joh6_hideout_b3f` (devant Brace), `johto_joh6_saturday` (Samuel).

## 3. Tâches

| N° | Tâche | Critère |
|---|---|---|
| T1 | `tools/gen_joh6_data.py` (+ retouches de `gen_joh2_data.py`) | Textes C-1 à C-46 mot pour mot (`test_joh6_data`) |
| T2 | `tools/build_joh6_maps.gd` : 11 cartes + souvenir | Grille = plan ; cases praticables connexes ; trous, dalles, portes |
| T3 | Raccords | Aller-retour partout ; « À venir » vers le sentier |
| T4 | Intérieurs `--acajou` | Soin, repos « Acajou », PC en ligne |
| T5 | Données de monde | Inventaires verts |
| T6 | Rencontres | `get_table` par moment ; eau ; cendres |
| T7 | Scènes | Ordre Tour → péage → lac → boutique → repaire → Centre |
| T8 | Variante rouge | Sauvegarde aller-retour, teinte, Pokédex |
| T9 | Souvenir sépia | Filtre, joueur caché, retour |
| T10 | Samuel, Diane | Jour seulement, don une fois |
| T11 | Départs de débogage | Se lisent et s'appliquent |
| T12 | Tests `test_joh6_data`, `test_joh6_maps`, `test_joh6_story`, registres | `tools/test.sh --changed` vert |
| T13 | Captures Mac (dossier §14) | Relues |
| T14 | QA A17 | Parcours, scènes, alarmes, Raikou |
| T15 | CI « success », refusion de `main`, fusion `--no-ff` | `main` vert |
| T16 | `etat-projet.md`, compte rendu | — |

## 4. Critères d'acceptation

1. À l'acte 2, le doyen ouvre la Tour Cendrée (C-2) ; le garde de la Route 42 s'efface ; la Tour
   Carillon reste fermée (C-12).
2. Tour : deux Dresseurs évitables, C-5 une fois, chute par les trous, Peau Métal au B1F ; scène
   des chiens une seule fois (C-6 à C-9) ; à la sortie, le doyen (C-10, C-11).
3. Route 42 : lac en Surf, Louis inévitable, Super Bonbon sur l'îlot ; Mont Creuset C-14.
4. Acajou : titre, habitants C-17, C-18, vendeur C-19 ; Route 43 : péager inévitable, C-22.
5. Lac : Léviator rouge (C-25), capture ou K.O., ne revient pas ; pêcheur C-26.
6. Boutique : escalier seulement après le lac (C-28, C-29).
7. Repaire : alarmes une fois par statue ; dalles ; levier ; souvenir sépia (C-35) ; porte refusée
   avant le déserteur, C-38 ensuite ; Brace obligatoire (défaite : Centre, Brace reste) ; C-43,
   Raikou (capture, K.O., fuite) ; déserteur au Centre (C-45).
8. Samuel le samedi, Diane le dimanche, une fois chacun.
9. Tests ciblés verts, import sans erreur, CI verte, QA A17 sans bloquant, fusion dans `main`.

## 5. Risques

- Fichiers partagés avec les JOH3 à JOH9 (zones, intérieurs, repos, lumière, musique, scènes,
  `cutscene_step.gd` : étapes ajoutées en fin d'enum par plusieurs sessions) : conflits triviaux,
  ancienneté JOH3 > … > JOH9 ; je refusionne `main` avant chaque fusion.
- Le Lac Colère contient le sentier du Mont Argenté (JOH9) : je pose le garde forestier et la
  barrière `unless johto_act3` ; le JOH9 relancera l'outil quand `silver_trail` existera (message
  à la session JOH9).
- Brace : grand combat, réglage dans la fourchette 35–60 % (mémoire « Difficulté des combats »).
- Souvenir interrompu (application tuée) : sortie de secours de la carte du souvenir.

## 6. Valeurs par défaut [D]

Tuiles et bâtiments provisoires ; chiens, cage et statues en aplats ; sprites des §2.3 ; lumières
des cartes ; taux de rencontre (cendres 15, eau 10) ; « Ortie » = Ortide ; `prize_per_level` ;
IA de Brace ; doyen sur le parvis à la sortie de la tour (C-10, C-11) ; mot de passe = porte
`FlagGate` + examen ; Raikou : fuite ou défaite = rencontre consommée (retour post-chapitre) ;
teinte rouge ; filtre sépia ; textes `draft` (§2.3).

## 7. Fait

| Tâche | Commit | Note |
|---|---|---|
| Plan | (ce commit) | Ce document |
