# Jalon JOH8 — La flamme : Bois de la Tour, Tour Carillon, Dante (1), Entei, Ho-Oh

> **PLAN.** Sources de vérité : `docs/design/dossier-joh-09-tour-carillon.md` (textes H-1 à H-38
> et arbitrages JH-52 à JH-55 validés par Kevin le 2026-11-02 ; le reste porte des défauts
> **[D]**) ; cadre `dossier-joh-00-cadre.md` (§4.3, §4.5, §7 : niveaux 62–68) ; grilles
> `tools/plans/bell_tower_woods.txt`, `bell_tower_1f.txt`, `bell_tower_2f.txt`,
> `bell_tower_roof.txt` (validées le 2026-11-03, **elles font foi**) et la retouche de
> `rosalia.txt` (sage blessé, raccord nord) ; vues générales `docs/design/reference/bois-de-la-tour-*`,
> `tour-carillon-1f-*`, `tour-carillon-2f-*`, `tour-carillon-sommet-*` (DA seulement). Systèmes du
> JOH0 (`jalon-joh0.md` §2), conventions du JOH1 (moment imposé `JohtoPeriodRule`) et du JOH2
> (cartes depuis une grille, données générées, préfixe de fichiers). Écrit le 2026-11-04 sur la
> branche `claude/joh8-carillon-ab63fa` (cut de `main` @ `bdcc90ae`, JOH1 fusionné tôt pour ses
> outils ; `main` refusionné dès que JOH1 et JOH2 y sont).

> Objectif jouable : **de Rosalia au sommet de la Tour Carillon et retour** : le sage blessé (H-1)
> au pied du chemin gardé, le doyen qui ouvre la tour (H-2, H-3), le Bois de la Tour (Sbire de guet
> évitable, Hyper Potions, panneau, lanternes), le 1F (sages assommés, Sbire V inévitable, Rappel
> Max), le 2F (planches qui cèdent → chute au 1F, Sbire W, Hiroshi qui soigne, PP Plus), le long
> escalier en fondu (H-12), le sommet **à l'aube forcée** (Dante, la cage de feu, premier combat
> contre Dante, la cloche, Ho-Oh qui refuse Dante, la fuite sur Arcanin, Entei puis Ho-Oh en
> rencontres fixes capturables, la Plume Arc-en-ciel), puis Rosalia (doyen H-34, Orme H-35 / H-36,
> habitante H-37, Diane H-38 le dimanche) et `johto_act3`.
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA A17, fusion
> dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change.

## 0. État d'entrée (relu le 2026-11-04)

| Point | Réel | Conséquence |
|---|---|---|
| JOH3 à JOH7 | Codés en parallèle par d'autres sessions ; rien dans `main` | Départs de débogage qui posent l'état de fin du JOH7 (`johto_lugia_done`, `johto_bell_tower_clue`, drapeaux des actes 1 et 2, équipe 62–68) |
| Rosalia | Carte du JOH2 (branche à fusionner) : chemin gardé (42..43, 0..13), garde R-20 (41, 13), déclencheur `barriere_carillon` `unless johto_bell_tower_open`, warp nord « À venir » vers `bell_tower_woods` / `from_ecruteak`, `sage_blesse` (44, 13) **sauté** par le JOH2 | JOH8 : PNJ `sage_blesse` (H-1), garde `unless johto_bell_tower_open`, reconstruction de Rosalia (`build_joh2_maps.gd --maps=ecruteak_city`) quand mes cartes existent |
| Doyen | `ecruteak_elders_house` (JOH2, dialogue `ecruteak_elders_house_doyen`) ; le JOH6 y ajoute C-10 à C-12 | Variantes JOH8 (H-2 + H-3 ; H-34) **en tête** du dialogue, ajoutées à la fusion ; ancienneté JOH6 > JOH8 |
| Diane (dimanche) | PNJ du JOH6 (C-46) | H-38 : variante `if johto_ho_oh_seen` ajoutée à son dialogue après la fusion du JOH6 ; texte prêt dans `joh8_ecruteak.json` |
| Moment imposé | `JohtoPeriodRule` (JOH1) : règle pure sur les drapeaux | Aube du sommet = règle **par carte** (§2.6), branchée dans `Boot._apply_story_period` |
| Espèces | Entei, Ho-Oh et toutes les équipes existent (`johto.json`, Kanto) | Rien à ajouter |
| Art | Vues validées, aucun décor peint, aucun sprite de Dante, Ho-Oh, cage | Tuiles provisoires, sprites existants [D], aplats ; « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH8A** — la tour | T1 données générées, T2 quatre cartes, T3 raccords, planches qui cèdent, T4 données de monde | Tests, captures Mac |
| **JOH8B** — la flamme | T5 scènes de Rosalia (sage blessé, doyen, après), T6 sommet (Dante, cloche, Ho-Oh, fuite, Entei, Ho-Oh, plume), T7 aube forcée, T8 Corde Sortie, T9 départs de débogage, T10 tests, T11 captures | Tests, captures Mac |
| Clôture | T12 QA A17, T13 CI verte et fusion, T14 état du projet, compte rendu | Déléguée |

## 2. Conception technique

### 2.1 Cartes (`tools/build_joh8_maps.gd`)

| Carte | Identifiant | Taille | `interior` | Lumière | Zone |
|---|---|---|---|---|---|
| Bois de la Tour | `bell_tower_woods` | 24 × 20 | non | `johto_auto` | `bell_tower_woods` (lieu, Johto) |
| Tour Carillon 1F | `bell_tower_1f` | 24 × 24 | non (grotte) | `tower` | `bell_tower` |
| Tour Carillon 2F | `bell_tower_2f` | 24 × 24 | non (grotte) | `tower` | `bell_tower` |
| Sommet | `bell_tower_roof` | 20 × 20 | non | `johto_auto` (aube forcée, §2.6) | `bell_tower` |

- Tuiles provisoires (`OverworldTiles`) [D] : Bois `.` herbe, `p` `D` `L` pavé, `h` hautes herbes
  (aucune table : aucune rencontre, §5 du dossier), `T` `G` forêt, `K` falaise ; 1F / 2F `.`
  planches (BOARDWALK), `#` `M` falaise, `A` autel (CROP), `U` `D` `E` pavé, `O` terre (planches
  qui cèdent) ; sommet `.` `c` `D` pavé, `r` `#` `B` `M` falaise. **La grille fait foi** (test
  « grille de la scène = grille du plan »).
- Façade de la Tour Carillon dans le Bois : aplat provisoire (corps, trois toits rouges) [D] ;
  lanternes : aplats + lampes de nuit (`night_lights`).
- **Planches qui cèdent** : chaque case `O` du 2F est un warp **FALL** (mécanisme des trous du
  Manoir, J25) vers l'arrivée `chute` (12, 12) du 1F, avec deux traits sombres de planche [D] ;
  aucune ne mène au sommet ni hors de la carte (test) ; un chemin sans chute existe (test). H-9
  est l'examen de la planche (9, 5), lu depuis (9, 4).
- **Long escalier** (2F (3, 0) → sommet) : pas de warp, un déclencheur qui joue la scène
  `bell_tower_climb` : « La montée est longue… », `change_map` (fondu), « Le ciel pâlit. » (H-12).
  Le retour (trappe du sommet) est un escalier ordinaire.
- **Cage de feu** : `FlagGate` `CageDeFeu` `unless johto_ho_oh_seen`, qui occupe ses barreaux
  (`c`) ; elle brûle avec H-21 (drapeau posé dans la scène, décor mis à jour aussitôt).
- Raccords : Bois (10..11, 19) PUSH ↓ → Rosalia `from_bois` (« À venir » tant que la carte du JOH2
  manque ; relancer `--maps=bell_tower_woods` après la fusion) ; porte (10..11, 5) ↔ 1F `from_woods`
  / `retour_tour` ; escaliers par paire (`vers=carte:arrivée`).
- Corde Sortie : `caves.json` `bell_tower` = 1F et 2F, sortie `bell_tower_woods` / `retour_tour`
  (devant la porte). Le sommet est à ciel ouvert : la Corde Sortie y est **toujours** refusée
  [D] (le dossier §12 la refuse tant qu'Entei et Ho-Oh n'ont pas été affrontés ; après, il n'y a
  plus rien à fuir au sommet).

### 2.2 Données générées (`tools/gen_joh8_data.py`)

- `data/npcs/bell_tower_*.json` : Sbires (bloc `trainer`, H-5, H-7, H-8), sages assommés (H-6),
  Hiroshi (H-10, `heal`), objets visibles (§7), Dante (`gentleman` [D], `unless
  johto_dante_fled_1`, lui parler reprend la scène), Entei (`pokemon/entei`, `unless
  johto_entei_done`), Ho-Oh (`if johto_entei_done unless johto_ho_oh_done`), la plume (`if
  johto_ho_oh_done unless got_rainbow_wing`), Ho-Oh du retour après le chapitre (§2.4).
- `data/trainers/bell_tower.json` : trois Sbires (§6, `prize_per_level` 40 [D]) et
  `bell_tower_dante_1` (§2.5).
- `data/dialogues/joh8_bell_tower.json`, `data/cutscenes/joh8_bell_tower.json` ;
  `data/dialogues/joh8_ecruteak.json` (sage blessé, Orme, habitante, Diane) ; `data/items/items_joh8.json`
  (`rainbow_wing`, objet clé sans effet).
- Rosalia (fichiers du JOH2, complétés **quand ils existent**) : PNJ `sage_blesse` (44, 13) `if
  johto_bell_tower_clue unless johto_bell_tower_open` ; garde R-20 `unless johto_bell_tower_open`
  (il s'efface) ; habitante H-37 (30, 18) `if johto_ho_oh_seen` [D] ; Orme (Centre, (11, 6)) `if
  johto_ho_oh_done` [D] ; deux variantes **en tête** du dialogue du doyen : `if johto_ho_oh_done`
  → H-34 + `johto_act3` ; `if johto_bell_tower_clue unless johto_bell_tower_open` → H-2 + H-3 +
  `johto_bell_tower_open`. Relancer le script après `gen_joh2_data.py`.
- Textes : §15 mot pour mot (test) ; brouillons [D] (`draft`, `PENDING_DRAFTS`) : examen de
  l'autel, de la cloche, de la rambarde.

### 2.3 Scènes du sommet (`bell_tower_summit`, déclencheur (3, 3), `unless johto_dante_defeated_1`)

1. H-13 (la première fois), le joueur va en (9, 7) face à Dante ; H-14, H-15 (première fois),
   `johto_dante_met` ;
2. H-16 (ou **H-17** si `johto_dante_lost_1`), combat `bell_tower_dante_1` (win
   `johto_dante_defeated_1`, lose `johto_dante_lost_1`) ; défaite → `wake_up` (Centre de Rosalia,
   la scène s'arrête ; au retour, le déclencheur la rejoue avec H-17) ;
3. H-18, H-19 (cloche : éclair blanc), H-20, Ho-Oh descend en (9, 6), H-21 (deux éclairs,
   `johto_ho_oh_seen` : la cage brûle), Ho-Oh s'envole, H-22 ;
4. H-23 (Entei rugit), H-24, H-25, Dante part vers l'est et quitte la carte, `johto_dante_fled_1` ;
5. H-26, **Entei** N60 (`wild_battle`, `intro: legendary`, `static` done `johto_entei_done` / caught
   `johto_entei_caught` ; fuite du joueur → `johto_entei_fled` + `johto_entei_done` [D] : il
   disparaît aussi, dossier §6) ; H-28 si capturé, sinon H-27 ;
6. H-29, Ho-Oh se pose sous la cloche, H-30, **Ho-Oh** N65 (mêmes règles) ; H-31 s'il n'est pas
   capturé ; H-32, Plume Arc-en-ciel au Sac, H-33, `got_rainbow_wing`.

Reprises après une coupure (dossier §12) : parler à Dante rejoue la suite selon les drapeaux
(`bell_tower_dante_resume_bell`) ; parler à Entei libre (`if johto_dante_fled_1`) lance son combat
puis Ho-Oh ; parler à Ho-Oh lance le sien ; la plume reste à ramasser si la scène a été coupée.
Les drapeaux sont écrits par l'écriture forcée des rencontres fixes (passe systèmes 2).

### 2.4 Légendaires après le chapitre

Cadre §4.5, dossier §6 [D] : Ho-Oh K.O. ou fui revient au sommet quand `johto_chapter_done` (JOH9)
est levé (PNJ `ho_oh_retour`, rencontre `johto_ho_oh_return_done`). Entei revient à la Tour
Cendrée : carte du JOH6, à poser par la session qui fusionne en second (drapeaux `johto_entei_done`
sans `johto_entei_caught`, `johto_chapter_done`).

### 2.5 Dante (1) (JH-54, mémoire « Difficulté des combats »)

Démolosse 64 (Lance-Flammes, Mâchouille, Lance-Soleil, Feinte), Magmar 65 (Déflagration,
Poing-Éclair, Psyko, Onde Folie), Cizayox 66 (Griffe Acier, Cru-Ailes, Tranche, Danse-Lames),
Farfuret 66 (Laser Glace, Feinte, Tranche, Vive-Attaque), Arcanin 68 (Lance-Flammes, Mâchouille,
Plaquage, Tunnel) ; IA `smart`, changements permis, sans Tyranocif ; pas de séquence « VS » (aucun
portrait de Dante : phase DA) [D]. Équilibrage `tools/sim/joh8_dante_scenario.json` (300 parties,
soin d'Hiroshi avant) :

| Équipe estimée (62–66) | attentif | expert | naïf |
|---|---|---|---|
| Aligatueur, Dracaufeu, Florizarre, Pharamp, Roucarnage, Nidoking | 46 % | 51 % | 6 % |
| Typhlosion, Tortank, Raichu, Roucarnage, Alakazam, Pharamp | 82 % | 89 % | 4 % |
| Méganium, Dracaufeu, Raichu, Roucarnage, Ectoplasma, Togetic | 10 % | 4 % | 0 % |

La cible 35–60 % est tenue pour l'équipe sans avantage de type ; les deux autres sont l'avantage
ou le désavantage de type choisi par le joueur (exception déjà validée pour Tortank au J25). Les
premiers choix (Purédpois, Brouillard, Hâte, Bélier) donnaient 84–89 % : remplacés.

### 2.6 Aube forcée (JH-55)

`BellTowerDawnRule.forced_period(map_id, flags)` (pure) : `morning` sur `bell_tower_roof` tant que
`johto_ho_oh_done` est bas. `Boot._apply_story_period(map_id)` la lit après `JohtoPeriodRule` (qui
garde la priorité) et est appelée au début de `_on_map_changed` (avant la lumière : pas de fondu à
l'arrivée). Le drapeau de Ho-Oh ne relâche pas l'heure au milieu de la scène : l'heure réelle
reprend au prochain changement de carte (« à la sortie du sommet »).

### 2.7 Données de monde

`zones.json` : `bell_tower_woods` (« Bois de la Tour », sous-titre « Rosalia — Tour Carillon »,
H-11) et `bell_tower` (« Tour Carillon », H-11), région `johto`, aucun point de Vol ;
`lighting.json` (§2.1) ; `music_zones.json` : Bois `viridian_forest`, Tour `pokemon_tower` [D]
(musiques HGSS au lot Son, JH-12) ; `decors.json` : Bois et sommet `route_1_chemin`, 1F / 2F
`tour_pokemon` [D] ; `caves.json` (§2.1) ; rectangles de la Carte de Johto [D].
H-38 (Diane, dimanche) : texte prêt (`joh8_diane_after`), variante `if johto_ho_oh_seen` à poser
en tête du dialogue de Diane quand le JOH6 l'a fusionnée.

### 2.8 Départs de débogage (`tools/gen_joh8_debug_starts.py`)

État de fin du JOH7 (drapeaux des dossiers JOH-02 à JOH-08), équipe 62–66 [D], point de repos
Rosalia : `johto_bell_tower_rosalia` (devant le Centre : sage blessé, doyen), `_woods` (tour
ouverte), `_2f`, `_roof` (arrivée au sommet), `_roof_autosave` (**écrit la vraie sauvegarde**,
reprise après coupure), `_entei` (Dante parti, Entei libre), `_after` (Rosalia après le sommet).

## 3. Tâches

| N° | Tâche | Critère |
|---|---|---|
| T1 | `gen_joh8_data.py` | Textes §15 mot pour mot ; Dresseurs §6 ; objets §7 |
| T2 | `build_joh8_maps.gd` | Grille = plan ; raccords ; planches ; cage ; long escalier |
| T3 | Données de monde | Inventaires verts (zones, lumière, musique, décors, grottes, Carte) |
| T4 | Rosalia (après fusion du JOH2) | Sage blessé, doyen, garde, Orme, habitante ; Rosalia reconstruite (raccord nord) |
| T5 | Scènes du sommet, reprises | `test_joh8_boot` : ordre complet, défaite et H-17, reprise d'Entei |
| T6 | Aube forcée | `test_bell_tower_dawn_rule` ; heure réelle hors du sommet |
| T7 | Équilibrage de Dante | 35–60 % pour l'équipe sans avantage de type |
| T8 | Captures Mac | Sommet à l'aube (Dante, cage), descente de Ho-Oh, 2F (planches) |
| T9 | QA A17 | Parcours doyen → sommet → Rosalia ; défaite ; reprise après coupure |
| T10 | CI verte, fusion, état du projet, compte rendu | `main` vert |

## 4. Critères d'acceptation

1. Rosalia : avec `johto_bell_tower_clue`, le sage blessé dit H-1 au pied du chemin ; le doyen dit
   H-2 et H-3 et ouvre la tour ; le garde s'efface ; le chemin mène au Bois.
2. Bois : panneau H-4, Sbire de guet évitable (H-5), Hyper Potions ×2, porte de la tour.
3. 1F : sages H-6, Sbire V inévitable (H-7), Rappel Max ; 2F : planches qui cèdent → 1F, Hiroshi
   soigne (H-10), Sbire W évitable (H-8), PP Plus, long escalier H-12.
4. Sommet à l'aube : H-13 à H-33 dans l'ordre, Dante (1), Entei N60 et Ho-Oh N65 capturables, Plume
   Arc-en-ciel ; défaite contre Dante → Centre de Rosalia, H-17 au retour ; heure réelle hors du
   sommet.
5. Rosalia après : doyen H-34 (`johto_act3`), Orme H-35 puis H-36, habitante H-37.
6. Tests ciblés verts, import sans erreur, CI verte, QA A17 sans bloquant, fusion dans `main`.

## 5. Risques

- Fichiers de Rosalia partagés avec le JOH2 (et le JOH6 : doyen, Diane) : mes entrées sont
  posées par `gen_joh8_data.py` après `gen_joh2_data.py` ; ancienneté JOH2 / JOH6 > JOH8.
- Entei de la Tour Cendrée (JOH6) et son sprite de carte : si le JOH6 en pose un, le sien gagne.
- Registres d'inventaire : préfixe `joh8_` dans `j22_ids.gd`.

## 6. Valeurs par défaut [D] posées par ce plan

Tuiles et aplats provisoires ; planches = traits sombres ; profils `tower` (1F, 2F) ; Dante en
`gentleman` sans « VS » ; attaques de Dante ; `prize_per_level` (Sbires 40, Dante 120) ; Hiroshi
soigne à chaque passage ; fuite d'un légendaire = il disparaît ; Corde Sortie refusée au sommet ;
Orme au Centre de Rosalia ; habitante H-37 en (30, 18) ; doyen H-34 lève `johto_act3` (Orme aussi) ;
retour de Ho-Oh avec `johto_chapter_done` ; musiques et décors de combat de substitution ;
textes des examens (autel, cloche, rambarde) en brouillon ; équipe des départs de débogage.

## 7. Questions ouvertes (non bloquantes)

- JOH8-Q1 : textes en brouillon (autel, cloche, rambarde) à relire.

## 8. Fait

| Tâche | Commit | Note |
|---|---|---|
| Plan, T1–T3, T5, T6 | `cbdd2335`, `85ae12af` | Cartes, données, aube, tests |
| T7 | (ce commit) | Équilibrage §2.5 |

QA A17 (2026-11-04, 22 h 38 – 23 h 04, APK de `7b72e415`) : aucun bloquant. Vu sur téléphone : Rosalia,
raccord nord, Bois, 1F, planches du 2F, escalier, sommet, Dante lancé, cloche, Ho-Oh, cage brûlée, Entei
et Ho-Oh en fuite, plume, reprise après arrêt forcé. Pas vu sur téléphone (tests GUT seulement) : victoire
complète contre Dante, défaite, captures, Orme et doyen H-34. Corrigé ensuite : Orme déplacé en (9, 6)
[D] ; trois objectifs du Menu [D] en brouillon.

Fusion avec le JOH6 : H-38 posée dans `week_sunday_diane` (variante après le don, `write_diane()` de
`gen_joh8_data.py`, à relancer après `gen_joh6_data.py`) ; retour d'Entei au B1F de la Tour Cendrée
(`entei_retour`, `joh8_entei_return`, drapeau [D] `johto_entei_return_done`), inactif tant que le JOH9
ne lève pas `johto_chapter_done` ; Entei de carte du JOH6 gardé, le provisoire du JOH8 retiré.

**JOH8 terminé** : fusionné dans `main` le 2026-11-05 (CI verte sur `f7c3709f`, run 41945347983).

## 9. Peinture (2026-11-06)

Bois de la Tour, 1F, 2F et sommet peints d'après leurs vues générales : art Codex
(`tools/art/joh8_carillon.py`, éléments Tour Carillon de `joh_ambiance_lot3.py`), passes
`build_joh_ambiance.gd`, `build_joh_ambiance_caves.gd` et `build_joh_ambiance_carillon.gd` (ordre
en tête de ce dernier, à relancer après `build_joh8_maps.gd`). Décor de combat du sommet :
`bell_tower_sommet`. Logique identique avant et après (`dump_map_logic`, `dump_map_nodes` : seul
`NightLights` devient calque). Planche : `docs/design/reference/joh8-peinture-avant-apres-v1.jpg`.
Départs `johto_bell_tower_woods_night`, `johto_bell_tower_roof_night` pour relire la nuit.

Défauts [D] : érable peint exprès pour le Bois, plancher réchauffé contre le profil `tower`, 2F
plus gris, escalier qui descend assombri, lueurs des brûle-parfums la nuit ; rambarde sud fermée
(la grille fait foi : la vue générale la montre ouverte). Le Bois et le 1F gardent leurs décors de
combat de substitution (`route_1_chemin`, `tour_pokemon`).

QA A17 (2026-11-06, 10 h 24 – 10 h 35, APK de `1ea78e9c`) : aucun bloquant. Vus sur téléphone : Bois de
jour et de nuit (lanternes allumées), 2F, chute d'une planche vers le 1F, sommet à l'aube, scène de
Dante jusqu'au combat, décor `bell_tower_sommet`, sommet de nuit. Environ 50 images/s, creux à 31
au chargement. Pas vus sur téléphone : cage brûlée, Entei et Ho-Oh après la peinture (logique
inchangée, tests GUT).
