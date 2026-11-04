# Jalon JOH7 — La mer : Routes 40 et 41, Îles Tourbillon, Suicune, Lugia

> Sources de vérité : `docs/design/dossier-joh-08-iles-tourbillon.md` (textes M-1 à M-34 et
> arbitrages JH-48 à JH-51 validés par Kevin le 2026-11-02 ; le reste porte des défauts **[D]**),
> `docs/design/dossier-joh-00-cadre.md` (§4.3, §4.5, §5.2, niveaux §5 : 60–66) ; grilles
> `tools/plans/route_40.txt`, `route_41.txt`, `whirl_islands_1f.txt`, `whirl_islands_b1f.txt`,
> `whirl_islands_b2f.txt` et la retouche d'`oliville.txt` (validées le 2026-11-03, **elles font
> foi** ; contrôle `tools/art/plan_check_joh7.py`) ; vues générales `docs/design/reference/route-40-…`,
> `route-41-…`, `iles-tourbillon-1f-…`, `-b1f-…`, `-b2f-vue-generale-v1.png` (DA seulement).
> Systèmes : JOH0 (`docs/tech/jalon-joh0.md` §2, §8), grotte marine et `CurrentGate` du JOH1,
> courants et rochers de Force de la passe systèmes 2 (Îles Écume, Route Victoire).
> Écrit le 2026-11-04 sur la branche `claude/joh7-tourbillon-886122` (depuis `main` @ `695e0216`).

> Objectif jouable : **de la plage d'Oliville au fond des Îles Tourbillon, et retour** : Route 40
> (3 Nageurs évitables, Ultra Ball ×2), Route 41 (tourbillons infranchissables qui dessinent les
> chenaux, Noé inévitable, Léa et Gabin, Max Potion), Îles 1F (deux rochers de Force, deux Sbires),
> B1F (puzzle de courants, Suicune sur son rocher, Cenere et son combat obligatoire, Suicune
> combattu et capturable, Écaille Draco, PP Max, crique du Lokhlass du vendredi, courant violent de
> l'escalier qui s'apaise après Suicune), B2F (Lugia émerge du bassin, combat et capture, Super
> Bonbon ×2 derrière la cascade) ; à Oliville, le marin (M-1, M-29), l'enfant (M-30) et Orme au
> Centre (M-31, M-32, accroche du JOH8).
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA sur l'A17,
> fusion dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change.

## 0. État des lieux

| Point | Réel | Conséquence |
|---|---|---|
| Cartes depuis une grille | JOH1 : `tools/build_joh1_sea_cave.gd` (eau surfable, courants permanents ou `CurrentGate`, arrivées en Surf forcé, warps par case) ; J29 : rochers de Force (`BoulderSetup`) | `tools/build_joh7_maps.gd` construit les 5 cartes (tuiles provisoires) |
| Données depuis une grille | `tools/gen_joh2_data.py` (PNJ, Dresseurs, objets, dialogues, scènes) | `tools/gen_joh7_data.py`, fichiers préfixés `joh7_` |
| Légendaires fixes | Étape `wild_battle` + `static {done, caught}` + `flee` ; `StaticRespawn` baisse `done` à chaque victoire à la Ligue | Suicune, Lugia, Lokhlass en rencontres fixes (§2.5) |
| Jours de la semaine | PNJ `if_weekday` (lu à l'entrée sur la carte), variantes de dialogue `if_weekday` ; **aucune remise à zéro hebdomadaire** des drapeaux | `WeeklyFlags` (logique pure, données `data/story/weekly_flags.json`) appelé par Boot à chaque carte (§2.6) |
| PP Max | Absent (seul le PP Plus existe, `PpItem`) | Objet `pp_max` : `field_use: pp_up` + `pp_up_max: true` (porte la capacité à son plafond d'un coup) |
| Art | Aucun sprite de Suicune, Lugia, Lokhlass dans le monde ; Cenere (JOH5, en cours) | Sprites provisoires générés (`tools/build_joh7_placeholders.gd`) ; Cenere : `rocket_grunt_f` [D] tant que le JOH5 n'a pas fusionné |
| Oliville | Carte du JOH1 (raccord sud (20..29, 39) → `route_40`, `from_olivine`) | Marin de la plage, enfant, Orme ajoutés aux PNJ du JOH1 à la fusion |

## 1. Découpage

Un seul sous-jalon (JOH7), validé par la QA A17 à la fin : cartes → données → scènes → tests →
captures → QA → CI → fusion.

## 2. Conception technique

### 2.1 Cartes (`tools/build_joh7_maps.gd`)

| Carte | Grille | Taille | Région, lumière | Zone |
|---|---|---|---|---|
| `route_40` | `route_40.txt` | 24 × 40 | johto, `johto_auto` | `route_40` (M-7) |
| `route_41` | `route_41.txt` | 60 × 48 | johto, `johto_auto` | `route_41` (M-7) |
| `whirl_islands_1f` | `whirl_islands_1f.txt` | 30 × 24 | intérieur, `sea_cave` [D] | `whirl_islands` (M-9) |
| `whirl_islands_b1f` | `whirl_islands_b1f.txt` | 36 × 28 | intérieur, `sea_cave` [D] | `whirl_islands` |
| `whirl_islands_b2f` | `whirl_islands_b2f.txt` | 24 × 24 | intérieur, `whirl_islands_b2f` (lumière bleue venue d'en haut) [D] | `whirl_islands` (titre M-22 à l'arrivée [D]) |

- Sol : `R # o` falaise ; `w d` eau surfable (`surf_cells`), toute l'eau des routes pêchable
  (`fishable_cells`) ; `s .` sable / terre ; `g` gravats (`RUBBLE`, rencontres de grotte) ; `E V U`
  terre (warps) ; `@` eau bloquée + **tourbillon animé** (`WhirlpoolField`, dessin seul, M-4 à
  l'examen de chaque case par un [InteractPoint] [D]) ; `F` cascade bloquée + décor animé
  (`WaterfallDecor` [D] : bandes qui défilent vers le bas) ; `< > ^ v` courants.
- Courants : les flèches de la grille sont permanentes (`current_cells`) ; le courant violent du
  B1F (`courant_b2f`, (2, 4..5), `actif_sans=johto_suicune_done`) est un `CurrentGate`.
- Bords : warps PUSH case à case (`from_<carte>`, `_1`…), Surf forcé aux arrivées `surf=1` ;
  rangée 0 bloquée et arrivées en rangée 1 (règle du JOH1).
- Entrée des îles : STEP_ON → (22, 24) → `whirl_islands_1f` `from_route_41` ; sortie PUSH ← (0, 12)
  → `route_41` `from_whirl` (Surf forcé). **Corde Sortie** : point de repli de la zone
  `whirl_islands` = `route_41` / `from_whirl` [D] (§13 du dossier).
- Échelles : paires `wi_1`, `wi_2` (STEP_ON, arrivée voisine).
- Rochers de Force (1F) : `BoulderSetup` (`boulder_cells` (16, 8) et (24, 12)) ; aucune case de
  trou ni d'interrupteur.
- Déclencheurs : `scene_suicune`, `scene_cenere`, `scene_crique` (direction ←), `examen_courant_b2f`
  (direction ↑), `scene_lugia` ; examens : panneaux, tourbillons, cascade.
- Lugia : FlagGate `LugiaShadow` (même sprite que la grotte marine) pour l'ombre de M-23.

### 2.2 Données générées (`tools/gen_joh7_data.py`)

`data/npcs/<carte>.json` (Dresseurs, objets visibles, Suicune, Lugia, Lokhlass, Cenere est posée
par sa scène), `data/trainers/joh7.json`, `data/encounters/joh7.json`, `data/fishing/joh7.json`,
`data/dialogues/joh7.json`, `data/cutscenes/joh7.json`. Textes M-1 à M-34 **mot pour mot** (« / »
= bulle). Dresseurs (§6) : classes `nageur`, `nageuse`, `pecheur`, `sbire_rocket(_f)` ; Cenere
`sbire_rocket_f` [D] (classe d'admin du JOH5 reprise à la fusion si elle existe) ; récompenses par
niveau [D] : Nageur 5 ×, Pêcheur 35 ×, Sbire 30 ×, Cenere 60 ×.

### 2.3 Rencontres (dossier §5)

Tables `water` des Routes 40 et 41 (toute la journée, 42–48) ; `rubble` du 1F par moment (matin et
jour / nuit, 46–50) ; B1F `rubble` et `water` (48–52) ; B2F aucune. Pêche (Routes 40, 41) : Canne
(`old_rod`) Magicarpe, Tentacool niv. 5 ; Super Canne (`good_rod`) Krabby, Hypotrempe, Stari
niv. 10 ; Méga Canne : table par défaut [D] (« comme Kanto »).

### 2.4 Scènes et drapeaux

| Scène | Déclencheur | Conditions | Étapes |
|---|---|---|---|
| `whirl_suicune_seen` | B1F (8..14, 6) | `unless johto_suicune_seen` | M-12 ; `set johto_suicune_seen` |
| `whirl_cenere` | B1F (8..14, 4) | `unless johto_cenere_defeated_2` | `spawn cenere` (14, 1) ; marche vers le joueur ; M-14, M-15 ; `battle` (win `johto_cenere_defeated_2`) ; M-16 ; M-17 ; système « Cenere s'en va… » ; Cenere repart dans la galerie, `despawn` ; `next: whirl_suicune` |
| `whirl_suicune` | dialogue de Suicune après Cenere, ou suite de `whirl_cenere` | `if johto_cenere_defeated_2`, `unless johto_suicune_done` | M-18 ; `wild_battle suicune 60` (`intro legendary`, `static {done: johto_suicune_resolved, caught: johto_suicune_caught}`, `flee [johto_suicune_resolved]`, `actor suicune`) ; M-19 et `set johto_suicune_done` si `johto_suicune_resolved` |
| Suicune (PNJ) | (11, 3) | `unless johto_suicune_done` | avant Cenere : M-13 ; après : `whirl_suicune` |
| `whirl_b2f_current` | B1F (2, 6) ↑ | — | M-20 tant que `johto_suicune_done` manque ; M-21 une fois après (`johto_whirl_current_calm_seen`) |
| `whirl_cove` | B1F (7, 22) ← | — | capturé : M-33 ; vendredi et Lokhlass présent : M-26 ; autre jour : M-27 ; vendredi après un K.O. : M-33 [D] |
| Lokhlass (PNJ) | (3, 23), `if_weekday friday` | `unless week_friday_lapras, johto_lapras_caught` | `wild_battle lapras 50`, `static {done: week_friday_lapras, caught: johto_lapras_caught}`, `flee [week_friday_lapras]` |
| `whirl_lugia_rise` | B2F (6..18, 17) | `unless johto_lugia_emerged` | M-23 (ombre qui passe) ; M-24 ; `set johto_lugia_emerged` (Lugia apparaît au centre) |
| Lugia (PNJ) | (12, 9) | `if johto_lugia_emerged`, `unless johto_lugia_resolved` | `wild_battle lugia 65` (`static {done: johto_lugia_resolved, caught: johto_lugia_caught}`, `flee [johto_lugia_resolved]`) ; M-25 si non capturé ; `set johto_lugia_done` |
| Écaille Draco | (2, 13) | `unless got_whirl_islands_b1f_dragon_scale` | M-28 (au lieu du « trouve » ordinaire) |
| Orme (Centre d'Oliville) | PNJ `if johto_lugia_done`, `unless johto_bell_tower_clue` → M-31 + `set johto_bell_tower_clue` ; ensuite M-32 | — | — |
| Marin de la plage (Oliville) | M-1 ; `if johto_lugia_done` : M-29 | — | — |
| Enfant (maison 2 d'Oliville) | variante `if johto_lugia_done` : M-30 | — | — |

Drapeaux posés : `johto_suicune_seen`, `johto_cenere_defeated_2`, `johto_suicune_resolved`,
`johto_suicune_caught`, `johto_suicune_done`, `johto_lugia_emerged`, `johto_lugia_resolved`,
`johto_lugia_caught`, `johto_lugia_done`, `johto_bell_tower_clue`, `week_friday_lapras`,
`johto_lapras_caught`, `johto_whirl_current_calm_seen`, `got_<objet>`. Lus : `johto_raikou_done`,
`johto_whirl_clue` (JOH6 ; ils ne ferment rien ici [D] : la mer est ouverte dès l'acte 2).

### 2.5 Légendaires (dossier §6, §9 ; cadre §4.5)

- **Progression et réapparition séparées** : `johto_suicune_done` / `johto_lugia_done` (jamais
  baissés) font avancer l'histoire ; `*_resolved` est le drapeau `done` de la rencontre fixe, que
  `StaticRespawn` baisse (K.O. ou fuite sans capture) : **Lugia revient au B2F**, Suicune **ne
  revient pas au B1F** (son PNJ suit `johto_suicune_done`) : sa place d'après le chapitre est la
  Tour Cendrée (JOH8 / JOH9, qui lit `johto_suicune_resolved` et `johto_suicune_caught`).
- Fuite = K.O. (dossier : « K.O. ou fuite → ils disparaissent ») : clé `flee`.
- Défaite du joueur : réveil au Centre (Oliville), Suicune et Lugia restent ; contre Cenere, elle
  et Suicune restent (scène rejouée).
- Capture avec l'équipe pleine : Stockage (en ligne à l'acte 2).

### 2.6 Lokhlass du vendredi (JH-50)

- PNJ présent le vendredi (`if_weekday`), lu à l'entrée sur la carte : il reste jusqu'à la sortie
  de la carte si le jour change (dossier §13).
- **Remise à zéro** : `WeeklyFlags` (`game/systems/story/weekly_flags.gd`, pur) lit
  `data/story/weekly_flags.json` (`{"week_friday_lapras": "friday"}`) ; à chaque chargement de
  carte, Boot baisse chaque drapeau dont **le jour n'est pas aujourd'hui** (horloge réelle,
  partout). Un K.O. du vendredi garde le Lokhlass absent jusqu'à la fin du vendredi ; dès que le
  jeu tourne un autre jour, il reviendra au vendredi suivant [D]. Limite connue : un joueur qui
  n'ouvrirait le jeu **que** le vendredi ne le reverrait pas (aucune date en sauvegarde : format
  inchangé).

### 2.7 Monde

`zones.json` : `route_40`, `route_41` (`route`, `johto`, descriptions M-7), `whirl_islands`
(`dungeon`, `johto`, M-9, repli Corde Sortie) ; `interiors.json` (les trois étages) ;
`lighting.json` (cartes, profil `whirl_islands_b2f`) ; `music_zones.json` [D] (mer : morceau de
la Route 19 ; îles : Îles Écume ; Lugia : musique de légendaire existante, celle de HGSS au lot
Son) ; décor de combat [D] (`sea` / `cave`) ; aperçus de la Carte ; rectangles de l'illustration
provisoire de Johto.

### 2.8 Départs de débogage (`tools/debug_start/`)

État de fin du JOH6 (équipe rendue, `johto_team_returned`, `johto_act2`, `johto_raikou_done`,
`johto_whirl_clue`, `johto_cenere_defeated`, 6 Pokémon niv. 60–66 avec Surf et Force, badges de
Kanto) : `johto_whirl_route_40` (plage d'Oliville, en Surf), `johto_whirl_1f`, `johto_whirl_b1f`,
`johto_whirl_suicune` (au pied de la plate-forme), `johto_whirl_lugia` (B2F, après Suicune),
`johto_whirl_friday` (crique, `weekday: friday`).

## 3. Tâches

| T | Contenu |
|---|---|
| T1 | Plan (ce document), branche poussée |
| T2 | `build_joh7_maps.gd` + `WhirlpoolField`, `WaterfallDecor` ; sprites provisoires |
| T3 | `gen_joh7_data.py` : PNJ, Dresseurs, objets, rencontres, pêche, dialogues, scènes |
| T4 | `WeeklyFlags` + Boot ; `pp_max` |
| T5 | Monde : zones, intérieurs, lumière, musique, Carte ; Oliville (marin, enfant, Orme) |
| T6 | Départs de débogage ; tests GUT (`test_joh7_maps`, `test_joh7_data`, `test_joh7_story`, `test_weekly_flags`) ; inventaires réalignés |
| T7 | Captures Mac (Route 41 et ses tourbillons, B1F avec Suicune, B2F avec Lugia) |
| T8 | QA A17 ; CI verte ; fusion ; compte rendu |

## 4. Critères d'acceptation

- Les 5 cartes se construisent depuis les grilles, les raccords tiennent dans les deux sens
  (Oliville ↔ Route 40 ↔ Route 41 ↔ 1F ↔ B1F ↔ B2F).
- Courants : simulation de la grille (aucune boucle sans sortie) ; le lac ouest ne s'atteint
  qu'en glissant ; le courant violent repousse avant Suicune, plus après.
- Ordre Cenere → Suicune → courant du B2F → Lugia ; capture, K.O., fuite.
- Lokhlass : présent le vendredi seulement, absent après un K.O. jusqu'à la remise à zéro, plus
  jamais après sa capture (horloge injectée).
- Écaille Draco ramassée (M-28) ; Hypocéan + Écaille au terminal d'échange local → Hyporoi.
- Textes M-1 à M-34 mot pour mot.

## 5. Valeurs par défaut [D] posées par ce plan

Lumière `sea_cave` au 1F et au B1F, profil bleu au B2F ; tourbillons examinés partout (M-4) ;
Corde Sortie → Route 41 devant la grotte ; récompenses par niveau des Dresseurs ; Cenere en
sprite de Sbire tant que le JOH5 n'a pas fusionné ; musiques existantes ; vendredi suivant
(§2.6) ; M-33 dit à l'entrée de la crique quand le Lokhlass n'y est pas un vendredi ou après sa
capture ; M-22 = titre de zone au B2F ; `johto_raikou_done` et `johto_whirl_clue` ne ferment pas
la mer.

## 6. Fait

### T1 — plan (2026-11-04)
Ce document ; branche `claude/joh7-tourbillon-886122` poussée.
