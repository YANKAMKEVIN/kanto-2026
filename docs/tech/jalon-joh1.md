# Jalon JOH1 — Le passage et Oliville (grotte marine, vol, Professeur Orme)

> **PLAN — aucun code n'est écrit par ce document.** Sources de vérité :
> `docs/design/dossier-joh-00-cadre.md` (§3, §4.1, §4.2) et
> `docs/design/dossier-joh-02-oliville.md` (textes O-1 à O-25 et JH-25 à JH-27 validés par Kevin
> le 2026-11-02 ; grilles validées le 2026-11-02 ; vues générales validées le 2026-11-03). Les
> systèmes viennent du JOH0 (`docs/tech/jalon-joh0.md` §2 et §8). Écrit le 2026-11-04 sur la
> branche `claude/joh1-oliville-336a58` (cut de `claude/joh0-systemes` @ `2021ca82` ; `main` sera
> refusionné quand le JOH0 y sera).

> Objectif jouable : **du labo de Chen au choix du Pokémon de départ de Johto** : la lettre
> d'Orme, la bouche de grotte à Bourg Palette, les deux salles de la grotte marine en Surf (courants,
> ombre de Lugia), l'arrivée à Oliville de nuit, le Centre, le vol de l'équipe et du Sac, le PC
> hors ligne, le réveil, Orme et Germignon / Héricendre / Kaiminus, les 5 Poké Balls et la Potion,
> la sortie est ouverte (Route 39 « à venir »).
>
> Règle 1 de `CLAUDE.md` : aucune sauvegarde ne change de format (v10 du JOH0). Le vol est une
> écriture unique (`confiscate_team` + `save`, JOH0 §2.2) : il se **valide à part** sur le
> téléphone (critère 7), le reste en un lot.

## 0. État des lieux (relu sur la branche, 2026-11-04)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Vol et retour | `TeamConfiscation`, étapes `confiscate_team` / `return_team` + `save`, dialogue `storage_offline` (texte [D] du JOH0, O-11 le remplace), Ball refusée à 6 | Mise en scène seulement (T8) |
| Heure | `WorldClock` réel, `force_period` / `release_period`, lu seulement sur les cartes dont la zone a `region: johto` ; un départ de débogage peut imposer `period` | Règle du moment imposé par les drapeaux (T7, §2.4), **sans nouvelle étape de scène** |
| Lumière | `johto_auto` → `johto_<moment>`, fondu 10 s, groupe `night_lights` (`WorldLighting.set_night`), profils de grotte `cave_1f`… | Profil `sea_cave` [D] (T3), lampes d'Oliville (T5) |
| Courants | `GameMap.current_cells` posés **toujours** à la construction de la grille ; aux Îles Écume, `SeafoamFloorGate` les conditionne à ses drapeaux (dessin de l'eau vive compris) | Porte de courant générique `CurrentGate` (T3, §2.2) |
| Starter | `StarterOffer.load_file(path)`, un seul `StarterChoice` (Boot `%StarterChoice`), `rival_pick` obligatoire, `starter_species` écrasé à l'entrée dans l'équipe | Clé `rival: false` de l'offre, second contrôleur (T9, §2.6) |
| Scènes | `change_map` **continue la scène** après l'arrivée ; dialogue `heal: true` ; variante `auto` d'un PNJ jouée à l'arrivée sur la carte si le joueur est libre ; `moved_cell` d'un PNJ selon drapeaux | Une scène continue du Centre au matin, reprise après coupure par la variante `auto` de l'infirmière (§2.5) |
| Bourg Palette | Carte peinte, géométrie figée (`tests/fixtures/maps/pallet_town_logic.txt`), eau rangées 32–33, Route 21 par le canal (10..14) | Passe d'image idempotente (modèle DAF) qui ajoute warps, décor et point d'examen **sans toucher la grille** (T2) |
| Chen | `oak_lab_waiting` : variante des cadeaux d'après la Ligue (J32, `oak_post_league_gifts_done`) | La lettre vient **après** les cadeaux [D] (T1) |
| Intérieurs | `build_painted_interiors.gd` : `_pokemon_center`, `_poke_mart`, maisons relues sur une grille (`lavanville_maison_*.txt`) | Oliville = mêmes définitions (`--oliville`, T6) ; la salle de repos = enveloppe d'une maison d'Argenta |
| Zones, Vol, Carte | `olivine_city` déclarée (`maps: []`, `region: johto`, description `draft`), point de Vol `olivine_city` → `from_center` | Cartes remplies, description O-23, zone `sea_cave` neuve (T4) |
| Art | Vues générales validées, aucun décor peint ; pas de sprite d'Orme, des starters de Johto ni de Lugia | Tuiles provisoires + kit de bâtiments de Kanto ; Orme = `researcher` [D] ; starters = apparence générique ; ombre de Lugia = sprite provisoire généré (T3) ; tout en « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH1A** — le passage | T1 lettre et mère, T2 bouche de grotte, T3 grotte marine (2 cartes, courants, Lugia, objets, rencontres), T4 données de monde | Captures Mac ; téléphone en fin de jalon |
| **JOH1B** — Oliville | T5 ville (carte, PNJ, lampes, panneaux, garde), T6 intérieurs (Centre + salle de repos, Boutique, 2 maisons, point de repos, Boutique) | Captures Mac |
| **JOH1C** — le vol et Orme | T7 moment imposé, T8 arrivée, nuit, vol, matin, T9 Orme et starter de Johto, T10 départs de débogage | **Le vol seul** sur le téléphone (écriture unique), puis le reste |
| Clôture | T11 tests et CI, T12 état du projet, liste de validation, prompt du JOH2 | Kevin |

Ordre : A → B → C (chaque sous-jalon laisse le jeu jouable jusqu'à son bout ; les cartes
manquantes sont « à venir »).

## 2. Conception technique

### 2.1 Cartes et identifiants

| Carte | Identifiant | Grille | Taille | Lumière | Outil |
|---|---|---|---|---|---|
| Grotte marine, salle 1 | `sea_cave_1` | `grotte_marine_1.txt` | 30 × 40 | `sea_cave` [D] | `tools/build_joh1_sea_cave.gd` |
| Grotte marine, salle 2 | `sea_cave_2` | `grotte_marine_2.txt` | 30 × 40 | `sea_cave` | idem |
| Oliville | `olivine_city` | `oliville.txt` | 50 × 40 | `johto_auto` | `tools/build_joh1_olivine.gd` |
| Centre | `olivine_center` | définition commune | 15 × 10 | `interior_warm` | `build_painted_interiors.gd --oliville` |
| Salle de repos (étage) | `olivine_center_room` | définition propre | 15 × 10 | `johto_auto` [D] | idem |
| Boutique | `olivine_mart` | définition commune | 15 × 10 | `interior_warm` | idem |
| Maison 1 (vieille dame) | `olivine_house_1` | `lavanville_maison_1.txt` [D] | 15 × 10 | `interior_warm` | idem |
| Maison 2 (enfant) | `olivine_house_2` | `lavanville_maison_2.txt` [D] | 15 × 10 | `interior_warm` | idem |

- Tuiles provisoires (`OverworldTiles`), comme le J22 : grotte `#`/`o` falaise, `w d > v` eau,
  `.` terre, `g` sable ; ville `T` forêt, `R` falaise, `.` herbe, `p` pavé, `g` sable, `q`
  planches, `w` eau, emprises `C O m N P` falaise (bâtiments peints du kit de Kanto posés dessus :
  `bldg_centre_01`, `bldg_boutique_01`, maisons ; Phare = tour provisoire en aplats), `x y n G k`
  bloquées. **La grille fait foi** (test : grille de la scène = grille du plan, §4).
- Raccords : Bourg Palette (22..25, 33) PUSH ↓ ↔ salle 1 (12..15, 0) ; salle 1 (20..21, 39) PUSH ↓
  ↔ salle 2 (20..21, 0) ; salle 2 (3..4, 39) STEP_ON ↓ → Oliville `from_sea_cave` (11, 31..32),
  tourné → ; Oliville (10, 31..32) STEP_ON ← → salle 2 `from_olivine_city` (3..4, 38), tourné ↑ ;
  Oliville est (49, 20..22) PUSH → « Route 39 » à venir ; sud (20..29, 39) PUSH ↓ « Route 40 » à
  venir. Arrivées en Surf : `forced_surf_cells` des deux côtés (Bourg Palette compris).
- Portes d'Oliville : Centre (27..28, 19) → `olivine_center` `entrance`, retour `from_center`
  (= point de Vol déjà déclaré) ; Boutique (37..38, 19) ↔ `from_mart` ; maisons (16, 19) ↔
  `from_house_1`, (37, 30) ↔ `from_house_2`. Escalier du Centre (13, 5) [D] STEP_ON ↑ ↔ salle de
  repos `from_stairs` ; la salle a un lit (arrivée `lit`), une table avec les trois Pokémon.
- Zones (`data/world/zones.json`) : `olivine_city.maps` = les six cartes d'Oliville, services
  Centre et Boutique, description O-23 (plus `draft`), `subtitle` « Grotte marine — Route 39 »
  [D] ; zone neuve `sea_cave` « Grotte marine » (`kind: place`, `region: johto` [D], description
  O-24, `subtitle` « Bourg Palette — Oliville »). `interiors.json` + 5 ; `rest_points.json` +
  `olivine_center` (`registers: true`) ; `music_zones.json` : `olivine_city` → `cinnabar_island`,
  `sea_cave` → `mt_moon` [D] (aucune musique de Johto : lot Son) ; `data/shops/olivine_mart.json`
  : Poké Ball, Potion, Super Potion [D], Antidote, Rappel (dossier §3.3).
- `caves.json` : la grotte marine **n'y entre pas** [D] : la Corde Sortie y est refusée (un
  passage sous la mer, pas une grotte de Kanto ; à l'acte 1, une sortie vers Bourg Palette
  casserait JH-18).

### 2.2 Grotte marine : Surf, courants, Lugia, objets, rencontres

- `surf_cells` = toutes les cases `w d > v` ; aucune case pêchable [D].
- Courant de la salle 1 (rangées 14..15, `>`) : permanent (`current_cells`).
- Chenal de la salle 2 (6..8, 30..34, `v`) : **`CurrentGate`** (`game/world/surf/current_gate.gd`,
  nouveau, étend `FlagGate`) : `cells: Dictionary[Vector2i, Vector2i]`, `unless_flags` ;
  `apply_to_grid` pose les courants si la porte est ouverte, les efface sinon
  (`GridWorld.set_current(cell, ZERO)`) ; dessine l'eau vive et les chevrons des courants actifs
  comme `SeafoamFloorGate` (même texture `ground_courant_01`). Réglée à l'arrivée et à chaque
  drapeau par `GameMap.apply_flag_gates`, comme toute `FlagGate`. Drapeau : **`johto_team_returned`**
  (fin de l'acte 1, JOH0) à la place du `johto_act2` de la grille [D] : courant actif tant qu'il est
  bas, calme ensuite (grille : « calme » à l'acte 2).
- O-7 : déclencheur `courant_retour` (6..8, 35), direction ↑, scène `sea_cave_current_back`
  (`unless johto_team_returned`) : narration O-7 puis un pas en arrière (`move player path [down]
  keep_facing`).
- Ombre de Lugia : déclencheur `ombre_lugia` (9..20, 17), toute direction, scène
  `sea_cave_lugia_shadow` (`unless johto_lugia_shadow`) : `spawn` d'un acteur `lugia_shadow`
  (sprite provisoire `assets/sprites/characters/placeholder/lugia_shadow` : ellipse sombre
  translucide 128 × 48 générée par `tools/build_joh1_placeholders.gd`, affichée ×2) à l'ouest de
  l'eau profonde, narration O-6 page 1, `animate` de 10 cases vers l'est avec fondu (≈ 4 s), pages
  2 et 3, `despawn`, `set johto_lugia_shadow`. Sans combat.
- Objets visibles : PNJ `object/poke_ball_ground` (verbe PRENDRE) `sea_cave_1_item_1` (7, 10) →
  `pearl`, `sea_cave_2_item_1` (23, 24) → `max_repel` (« Rappel Max », JH-25) ; scènes
  `give … found`, drapeaux `got_<id>`.
- Rencontres (`data/encounters/sea_cave.json`) : table `sea_cave_water`, cartes `sea_cave_1` et
  `sea_cave_2`, terrain `water`, taux 10 [D], Tentacool 40–45 (poids 154), Kokiyas 40–45 (77),
  Stari 40–45 (25) (≈ 60 / 30 / 10 %) ; sans `period`.
- Lumière : profil `sea_cave` [D] = `cave_1f` avec un étalonnage plus bleu et un liseré
  `#9fd8ff` (eau turquoise, rais de lumière des fissures : vues validées).

### 2.3 Bourg Palette : la bouche de grotte (T2)

Passe idempotente `tools/build_joh1_pallet_cave.gd` (préfixe de nœuds `Joh1`) sur
`pallet_town.tscn`, modèle des passes DAF : la grille logique **ne change pas**
(`test_pallet_town_painted` reste vert) :
- 4 `WarpPoint` (22..25, 33) PUSH ↓ → `sea_cave_1` / `from_pallet_town`, `_1`, `_2`, `_3`
  (une arrivée par case), arrivée tournée ↓, **`if_flags: [johto_letter_read]`** (fermé avant la
  lettre : bord de carte ordinaire) ;
- arrivées `from_sea_cave`, `_1`, `_2`, `_3` (22..25, 33) et `forced_surf_cells` += ces 4 cases ;
- `FlagGate` `Joh1GrotteOuverte` (`if johto_letter_read`) : bouche sombre provisoire en aplats
  sur le bord sud (22..25, 33) ; `Joh1GrotteFermee` (`unless`) : rochers fermés ;
- `InteractPoint` `Joh1GrotteExamen` (22..25, 33), tourné ↓, dialogue `pallet_cave_mouth` (O-5),
  `if_flags: [johto_letter_read]`.

### 2.4 Moment imposé : règle des drapeaux (T7)

`JohtoPeriodRule` (`game/systems/story/johto_period_rule.gd`, statique, pur) :
`forced_period(flags) -> StringName` :
- `night` si `johto_letter_read` levé et `johto_team_stolen` bas (du départ de Bourg Palette
  au vol : la grotte a une lumière fixe, Kanto ne lit pas l'heure, Oliville est donc de nuit dès
  la plage, sans fondu à la première case) ;
- `morning` si `johto_team_stolen` levé et `johto_orme_left` bas ;
- `""` sinon (heure réelle).
Boot l'applique (`_apply_story_period`) après la mise en place de la partie (nouvelle, chargée,
débogage) et à chaque drapeau changé : `force_period` / `release_period` sur `_world_clock`, puis
la lumière suit par `period_changed` (fondu) ; **jamais** quand un départ de débogage a imposé
`period`. La règle est recalculée au chargement : une application tuée entre le vol et le choix
reprend bien le matin (cas limite du dossier §11). Aucune étape de scène `force_period` : le
moment ne dépend pas de la scène en cours, et il survit à la coupure.

### 2.5 Arrivée, nuit, vol, matin (T8)

| Moment | Mécanisme | Données |
|---|---|---|
| Plage (étape 5) | Déclencheur `olivine_arrival` sur (12, 31..32) et (11, 33) [D] (le premier pas depuis l'arrivée), scène `unless johto_arrived` : `set johto_arrived` (page Johto de la Carte) ; le titre « OLIVILLE » vient du `ZoneAnnouncer` | `data/cutscenes/joh1.json` |
| Centre, arrivée (6) | Déclencheur sur la rangée d'entrée du Centre (5..9, 7) → scène **`olivine_center_arrival`** (`if johto_arrived unless johto_slept`) : face à face avec le comptoir, dialogue `olivine_nurse_arrival` (O-8, **`heal: true`** : soin et point de repos « Oliville »), `set johto_slept`, `change_map olivine_center_room` / `lit` (nuit par la règle §2.4) | |
| Nuit (7) | La **même scène** continue : `wait`, narration `olivine_night_sounds` (O-9) entrecoupée de `spawn` / `move` (arrière-plan) / `despawn` de deux Sbires (`rocket_grunt_m`, `rocket_grunt_f`) qui filent de l'escalier au lit et repartent, **`confiscate_team`**, **`save`** (écriture unique, JOH0 §2.2), `set johto_team_stolen` (→ matin), `change_map olivine_center_room` / `lit` (fondu : la salle recharge au matin, les trois Pokémon et Orme présents) | |
| Matin (8–9) | Suite de la scène : infirmière (PNJ de la salle `if johto_team_stolen unless johto_starter_offered`) O-10, elle sort ; Orme (PNJ `if johto_team_stolen unless johto_orme_left`, `researcher` [D]) vient au joueur, O-12, O-13, `set johto_starter_offered` → le choix s'ouvre (légende, RENCONTRER) | |
| Reprise après coupure | Avant le `save` : la dernière sauvegarde est l'entrée du Centre, la scène rejoue depuis O-8. Après le `save` : la salle se charge le matin, l'infirmière a une variante **`auto`** (`olivine_nurse_wake`, `if johto_team_stolen unless johto_starter_offered`) qui joue `olivine_morning` = les étapes du matin (dupliquées en données [D]) | |
| PC (O-11) | Dialogue `storage_offline` du JOH0 réécrit avec le texte validé O-11 (trois pages) ; terminal du Centre d'Oliville = définition commune | `data/dialogues/johto_systems.json` |

Le Sac part avec les Sbires (objets non clés, Rappel Max compris : JH-25). Pas de combat, pas
d'issue possible pendant la nuit.

### 2.6 Orme et le Pokémon de départ de Johto (T9)

- `data/pokemon/starters_johto.json` : `map: olivine_center_room`, `level: 5`, `prompt`
  « CHOISIS TON PARTENAIRE DE JOHTO » [D], choix Germignon / Héricendre / Kaiminus (PNJ
  `chikorita` / `cyndaquil` / `totodile` de la salle, présents `if johto_team_stolen unless
  taken_<espèce>`), `open_flag: johto_starter_offered`, `done_flag: johto_starter_chosen`,
  `chosen_scene: johto_starter_chosen`, `female_flag: johto_starter_female`, **`rival: false`**.
  Phrases de la fiche [D] : « Doux et obstiné. », « Timide, mais ardent. », « Joueur et mordant. »
  (hors dossier : à relire par Kevin).
- `StarterOffer` : clé facultative `rival` (booléen, vrai par défaut). Faux : aucun Pokémon pour
  le rival (cadre §5.7) et **`starter_species` n'est pas modifié** (le starter de Kanto, dont
  dépendent les équipes du rival). `StarterChoice` : sans rival, pas de `rival_pick`, un seul
  `taken_`, un seul alias `$player_starter`.
- Boot : second contrôleur `_starter_choice_johto` (créé en code, même `setup` avec l'offre de
  Johto, mêmes relais de carte et `starter_chosen` → `_on_starter_chosen` : Pokédex, rencontre
  « starter » (lien 50, JOH0 §2.7), Grand moment). **Compagnon** : `GameState.set_companion` sur le
  starter de Johto ; sans planche de compagnon (JOH0 §2.11), il reste dans sa Ball (« Reportés »).
- Scène `johto_starter_chosen` (alias `$player_starter`) : saut près du joueur, O-17 (jeton
  `{pokemon}` = nom du starter, posé par le second contrôleur comme le jeton des capacités de
  terrain, §2.6 bis), `set johto_starter_chosen` (entrée dans l'équipe), `give poke_ball × 5`,
  `give potion`, O-18, Orme à l'escalier, `despawn`, `set johto_orme_left` (→ heure réelle, étape
  11), `despawn` du starter.
- §2.6 bis — jeton `{pokemon}` : `DialogueRunner` connaît déjà le jeton pour les variantes
  `field` ; `StarterChoice` fournit le nom de l'espèce en attente par un `Callable`
  `pending_name_source` posé sur le runner par Boot [D] (aucun nom en dur).
- Après le choix : garde de la sortie est rangé (`moved_cell` (47, 19), `moved_if_flags:
  [johto_starter_chosen]`), déclencheur `garde_barriere` (48, 20..22) `unless johto_starter_chosen`
  (O-19 et un pas en arrière).

### 2.7 PNJ d'Oliville et moments (T5, T6)

| PNJ | Carte, case | Sprite | Dialogue | Moments |
|---|---|---|---|---|
| Garde | ville (47, 21) ← | `guard` | O-19 ; après le choix : `olivine_guard_after` [D] | toujours |
| Marin du port | ville (33, 33) ↓ | `sailor` | O-20 | `if_period: ["day", "night"]` [D] (en mer le matin) |
| Vieille dame | maison 1 | `old_man` → `aoki` [D] | O-21 | toujours |
| Enfant | maison 2 | `kid` | O-22 | `if_period: ["morning", "day"]` [D] (couché la nuit) |
| Infirmière de la salle | salle de repos | `nurse` | `auto` O-10 → `olivine_morning` | `if johto_team_stolen unless johto_starter_offered` |
| Orme | salle de repos | `researcher` [D] | O-12 / O-13 (variantes), scène du choix | `if johto_team_stolen unless johto_orme_left` |
| Germignon, Héricendre, Kaiminus | salle, table | apparence générique (aucune planche) | O-14 à O-16 (observer) | `if johto_team_stolen unless taken_<espèce>` |
| Panneaux | ville (23, 19) ↑, (6, 19) ↑ | — | O-25 ; Phare : « PHARE D'OLIVILLE / Fermé pour travaux. » [D] | — |

Le marin de la plage (M-1) est du JOH7 : absent ici. Lampes de nuit (groupe `night_lights`,
`LightGlow` type `lamp`) : sommet du Phare, deux réverbères de l'avenue, fenêtres du Centre et de
la Boutique [D] ; allumées seulement la nuit sur la carte `johto_auto`.

### 2.8 Chen et la mère (T1)

- `mom` (`player_house.json`) : variante O-1 `if league_champion_defeated unless
  johto_letter_read`, avant la variante du soin [D].
- `oak_lab_waiting` : variante `if [league_champion_defeated, oak_post_league_gifts_done] unless
  johto_letter_read` → `cutscene: johto_letter` (O-2, O-3, `set johto_letter_read`, O-4) ; puis
  variante `if johto_letter_read unless johto_arrived` : O-4 (rappel) [D]. Les cadeaux du J32
  passent d'abord (une conversation), la lettre à la suivante [D].

### 2.9 Départs de débogage (T10, `tools/debug_start/`)

| Fichier | Partie |
|---|---|
| `johto_letter.json` | Ligue gagnée, cadeaux de Chen reçus, équipe de 6 (Tortank avec Surf), devant le labo : la lettre |
| `johto_sea_cave.json` | Lettre lue, en Surf au bord sud de Bourg Palette (22, 32) : la bouche, salle 1, Perle, courant, salle 2, Lugia |
| `johto_olivine_arrival.json` | Lettre et Lugia faits, sortie de la salle 2 : plage, nuit, ville, Centre (arrivée, vol) |
| `johto_olivine_night.json` | `johto_arrived`, devant la porte du Centre : O-8 → vol → matin → Orme (validation du vol seul) |
| `johto_orme.json` | Équipe confisquée, `johto_slept`, `johto_team_stolen`, dans la salle (`lit`) : reprise après coupure, Orme, choix |
| `johto_olivine_day.json` | Après le choix (Kaiminus N5, 5 Poké Balls, Potion, équipe confisquée), Oliville de jour : garde rangé, PNJ, Boutique, PC hors ligne, Route 39 « à venir » |

## 3. Tâches

| N° | Tâche | Critère |
|---|---|---|
| T1 | Lettre et mère (données) | `johto_letter` jouable au labo après les cadeaux ; O-1 à O-4 mot pour mot |
| T2 | Bouche de grotte (passe sur Bourg Palette) | Warps gardés par `johto_letter_read`, décor ouvert / fermé, O-5 ; `test_pallet_town_painted` vert |
| T3 | Grotte marine (2 cartes, `CurrentGate`, Lugia, objets, rencontres, profil) | Grille = plan ; acte 1 : nord → plage, pas de retour ; acte 2 : deux sens ; Lugia une fois ; O-6, O-7 |
| T4 | Données de monde (zones, intérieurs, repos, musique, Boutique, Vol) | Tests d'inventaire verts (zones, musique, Vol, intérieurs) |
| T5 | Oliville (carte, PNJ, lampes, panneaux, garde, raccords « à venir ») | Grille = plan ; toutes les cases praticables connexes ; lampes la nuit seulement |
| T6 | Intérieurs (Centre + escalier + salle, Boutique, maisons) | Portes aller-retour ; terminal hors ligne ; Boutique ; point de repos |
| T7 | `JohtoPeriodRule` + Boot | Tests de la règle ; nuit dès la lettre, matin après le vol, heure réelle après Orme ; débogage `period` prioritaire |
| T8 | Arrivée, Centre, nuit, vol, matin (scènes, O-8 à O-13) | Scène jouée sur la vraie carte en test : équipe vidée, Sac vidé des objets non clés, `storage_offline`, `save` demandé ; reprise par `auto` |
| T9 | Offre de Johto, `rival: false`, second contrôleur, scène du choix, jeton `{pokemon}` | Choix → équipe de 1, `starter_species` inchangé, 5 Poké Balls + Potion, `johto_orme_left` ; O-14 à O-18 |
| T10 | Départs de débogage et README | Les six fichiers se lisent et s'appliquent |
| T11 | Tests ciblés puis CI (`tools/ci_wait.sh HEAD`, « success ») | CI verte |
| T12 | `etat-projet.md`, liste de validation, prompt du JOH2 | — |

## 4. Critères d'acceptation

1. Après la Ligue et les cadeaux de Chen, la mère dit O-1 ; Chen lit la lettre (O-2 à O-4) ; la
   bouche de grotte n'existe pas avant, elle s'examine (O-5) et se traverse après.
2. Salle 1 : Surf d'un bout à l'autre, courant vers l'est, Perle sur l'îlot ; salle 2 : l'ombre
   passe une seule fois (O-6), Rappel Max, chenal à sens unique à l'acte 1 (O-7 au pied), deux
   sens une fois `johto_team_returned`. Rencontres : Tentacool, Kokiyas, Stari N40–45, dans l'eau.
3. Plage d'Oliville : nuit quelle que soit l'heure du téléphone, titre « OLIVILLE », page Johto de
   la Carte ; lampes allumées.
4. Centre : O-8, soin, repos ; nuit : silhouettes, bruits (O-9) ; équipe et Sac confisqués en une
   seule écriture ; matin : O-10, PC O-11, Orme O-12 / O-13 ; choix de Germignon / Héricendre /
   Kaiminus (fiche, RENCONTRER), O-14 à O-18, 5 Poké Balls et 1 Potion ; `starter_species` de
   Kanto intact ; heure réelle de retour ; garde rangé, Route 39 « à venir ».
5. Application tuée avant le vol : reprise à l'entrée du Centre, O-8 rejoue ; tuée après : reprise
   dans la salle, le matin, Orme vient ; tuée pendant la scène du choix : le Pokémon n'est jamais
   perdu (règle du `StarterChoice`).
6. Tests ciblés verts, import headless sans erreur, CI verte sur la tête de la branche.
7. **Validation téléphone (Kevin, fin de jalon)** : le vol seul d'abord (`johto_olivine_night`,
   une écriture : relancer l'appli après le vol montre l'équipe vide et `confiscated` relue), puis
   le reste (`johto_letter` → `johto_olivine_day`).

## 5. Risques

- `starter_species` écrasé par le second choix (rival de Kanto, Mont Argenté) : clé `rival: false`
  et test dédié.
- Deux contrôleurs sur la même fiche : chacun ne répond qu'à ses PNJ et à sa fiche ouverte (gardes
  existantes `is_open`, `_sheet_open`).
- Moment imposé et départ de débogage `period` : le débogage gagne (drapeau `_debug_period`).
- Bourg Palette : la passe ne touche ni `Ground` ni `blocked_cells` ; vérifié par la fixture
  figée.
- Fusion de `main` (JOH0 fusionné pendant le jalon) : `johto_systems.json` (O-11) et Boot sont
  les seuls points de contact ; refusionner tôt.

## 6. Valeurs par défaut [D] posées par ce plan

Profil `sea_cave` ; taux 10 et poids des rencontres ; zone `sea_cave` à Johto ; pas de Corde
Sortie dans la grotte ; `johto_team_returned` à la place de `johto_act2` ; déclencheur d'arrivée sur
les cases voisines de la plage ; escalier du Centre en (13, 5) ; salle de repos = enveloppe des
maisons d'Argenta, lumière `johto_auto` ; la lettre après les cadeaux du J32 ; nuit imposée dès la
lettre lue ; Orme = `researcher`, vieille dame = `aoki`, Sbires = `rocket_grunt_m` / `_f` ;
starters de Johto en apparence générique ; phrases des fiches ; libellé « CHOISIS TON PARTENAIRE DE
JOHTO » ; marin présent jour et nuit, enfant matin et jour ; panneau du Phare et réplique du garde
après le choix (textes `draft`) ; musiques de substitution ; Boutique à 5 objets ; lampes de nuit.

## 7. Questions ouvertes (pour Kevin, non bloquantes)

- JOH1-Q1 : les trois phrases des fiches de Germignon, Héricendre et Kaiminus (§2.6).
- JOH1-Q2 : panneau du Phare et réplique du garde une fois rangé (`draft`).
- JOH1-Q3 : le marin absent le matin, l'enfant absent la nuit : garder ?

## 8. Fait

(journal rempli tâche par tâche)
