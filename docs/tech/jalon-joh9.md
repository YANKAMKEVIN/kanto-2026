# Jalon JOH9 — Le sommet du monde : Mont Argenté, Dante, Giovanni, le rival, épilogue

> **PLAN.** Sources de vérité : `docs/design/dossier-joh-10-mont-argente.md` (textes A-1 à A-54,
> arbitrages JH-56 à JH-60 validés par Kevin le 2026-11-02 ; le reste porte des défauts **[D]**),
> `docs/design/dossier-joh-00-cadre.md` (§3.2, §4.4, §4.5) ; grilles `tools/plans/silver_trail.txt`,
> `mt_silver_outside.txt`, `mt_silver_1f.txt`, `mt_silver_2f.txt`, `mt_silver_3f.txt`,
> `mt_silver_summit.txt`, `route_28.txt`, `route_28_gate.txt` et la **variante `JOH9`** de
> `route_22_ouest.txt` (validées le 2026-11-03, **elles font foi**) ; vues générales
> `docs/design/reference/*mont-argente*`, `route-28-vue-generale-v1.png`, `poste-route-28-v1.png`
> (DA seulement). Systèmes du JOH0 (`docs/tech/jalon-joh0.md` §2 et §8), modèle de construction du
> JOH2 (`tools/build_joh2_maps.gd`, `tools/gen_joh2_data.py`). Écrit le 2026-11-04 sur la branche
> `claude/joh9-mont-argente-f6ee3a` (depuis `main` ; `main` refusionné dès que JOH1 et JOH2 y sont,
> puis régulièrement).

> Objectif jouable : **du Lac Colère à l'épilogue**, en partant de l'état de fin du JOH8 (départs de
> débogage) : sentier et Centre du Mont Argenté (point de Vol), extérieur et **relais du rival**,
> grotte 1F (Force, Surf, Sbires), 2F dans le noir (Flash automatique, le rival soigne l'équipe), 3F,
> sommet (**Dante**, **Giovanni**, Cenere, **dernier combat du rival**), descente par la Route 28 et
> son poste, **porte neuve de la Route 22** (variante `JOH9`), **épilogue au labo de Chen** (Orme,
> Balle Verte, rival, petit générique), retour libre à Kanto.
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA sur l'A17,
> fusion dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change.

## 0. État des lieux (2026-11-04)

| Point | Réel | Conséquence |
|---|---|---|
| Cartes | Aucune carte du JOH9 ; grilles validées ; Lac Colère = carte du **JOH6** (en parallèle) | Raccord ouest du sentier « À venir » (« Lac Colère ») tant que `lake_of_rage.tscn` manque ; relancer l'outil à la fusion du JOH6 |
| Garde forestier (A-1, A-2) | PNJ et barrière de la carte du JOH6 (`garde_forestier`, `barriere_sentier` actif sans `johto_act3`) | Textes A-1, A-2 fournis ici (`joh9_*`) ; branchement sur le PNJ du JOH6 à sa fusion (message à JOH6) |
| Autel du Bois aux Chênes | Examen du **JOH4** (`ilex_forest`, (23, 11)) | Scène de Celebi (A-53, A-54) écrite ici ; branchée sur l'autel à la fusion du JOH4, sinon « Reportés » |
| Équipe de JOH8 | Dante (1), Ho-Oh, drapeaux `johto_act3`, `johto_dante_fled_1` : codés par le JOH8 en parallèle | Départs de débogage qui posent les drapeaux de fin du JOH8 (dossiers JOH-02 à JOH-09, §« Drapeaux ») |
| Espèces | Les 202 espèces sont dans `data/pokemon/species/` (JOH0) | Rien à ajouter |
| Rival de Ligue | `data/trainers/league.json` `rival_champion` (`team_by_starter`) | `rival_johto_final` : même structure, niveaux et Steelix du §9 |
| Art | Vues validées ; aucun décor peint ; pas de Dante âgé, Brace, Cenere, Orme, Agente ni tenue d'hiver du rival dans `main` | Tuiles provisoires, sprites existants [D] ; tout en « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH9A** — la montagne | T1 données générées, T2 cartes (sentier, extérieur, 1F, 2F, 3F, sommet, Route 28, poste), T3 Centre et maison du gardien, T4 zones, Vol, rencontres, lumière, musique | Tests, captures Mac |
| **JOH9B** — l'histoire | T5 relais, rival du 2F, Dante, Giovanni, rival final, défaites ; T6 poste et porte de la Route 22 (variante `JOH9`) ; T7 épilogue, Balle Verte, générique ; T8 Celebi (si JOH4 fusionné) ; T9 départs de débogage ; T10 tests ; T11 captures | Tests, captures Mac |
| Clôture | T12 QA A17 (tour demandé à la coordination), T13 CI verte et fusion dans `main`, T14 état du projet, compte rendu | Déléguée |

## 2. Conception technique

### 2.1 Cartes

| Carte | Identifiant | Grille | Taille | Lumière | Outil |
|---|---|---|---|---|---|
| Sentier du Mont Argenté | `silver_trail` | `silver_trail.txt` | 24 × 44 | `johto_auto` | `tools/build_joh9_maps.gd` |
| Mont Argenté, extérieur | `mt_silver_outside` | `mt_silver_outside.txt` | 40 × 40 | `johto_auto` | idem |
| Grotte 1F | `mt_silver_1f` | `mt_silver_1f.txt` | 32 × 28 | grotte | idem |
| Grotte 2F | `mt_silver_2f` | `mt_silver_2f.txt` | 32 × 28 | grotte + voile | idem |
| Grotte 3F | `mt_silver_3f` | `mt_silver_3f.txt` | 28 × 24 | grotte | idem |
| Sommet | `mt_silver_summit` | `mt_silver_summit.txt` | 20 × 18 | `johto_auto` | idem |
| Route 28 | `route_28` | `route_28.txt` | 44 × 20 | `johto_auto` | idem |
| Poste de la Route 28 | `route_28_gate` | `route_28_gate.txt` | 10 × 8 | intérieur | idem (intérieur provisoire) |
| Centre du Mont Argenté | `mt_silver_center` | définition commune des Centres | 15 × 10 | intérieur | `build_painted_interiors.gd --mont-argente` |
| Maison du gardien | `route_28_house` | maison commune [D] | 15 × 10 | intérieur | idem |

- **La grille fait foi** : test « grille de la scène = grille du plan » (`test_joh9_maps`).
- Neige `n` : tuile provisoire claire praticable sans rencontre [D] ; herbes sous la neige `h` =
  hautes herbes.
- **Route 22 ouest** (Kanto) : la carte `route_22_west` n'est **pas reconstruite** (art peint du
  DAF.4). La variante `JOH9` y est posée par des nœuds ajoutés (`tools/build_joh9_route22.gd`) :
  bâtiment provisoire `FlagGate` (cases Q en `blocking_cells`, **occupées** et non solides, la grille
  de base du J29 reste exacte pour `test_j29_maps`), porte `porte_route_28` (2, 10) STEP_ON ← et
  arrivée `from_route_28_gate` (3, 10), tous **actifs avec `johto_arrived`** [D] (la retouche
  n'apparaît qu'une fois le Chapitre Johto commencé).

### 2.2 Ordre de jeu et drapeaux

Ordre du dossier §4 : `johto_rival_relay` (extérieur) → `johto_rival_healed` (2F) →
`johto_dante_defeated_2` → `johto_giovanni_seen` → `johto_rival_final_done` (sommet) →
`johto_route28_open` (poste) → `johto_chapter_done` (labo) ; `johto_celebi_done` (post-game).

### 2.3 Combats et défaites

- Dresseurs du §6 (`data/trainers/joh9.json`), textes A-4 à A-6, A-14, A-18 mot pour mot.
- **Dante (2)** `dante_2` et **rival final** `rival_johto_final` : combats de scène, `can_lose`
  selon le moteur (défaite = retour au Centre du Mont Argenté, point de repos posé à la visite).
- Reprise après défaite : la scène du sommet lit les drapeaux (A-25 si Dante n'est pas battu ;
  A-45 si Giovanni est vu et le rival pas battu) ; aucune scène rejouée en double.

### 2.4 Épilogue

- Déclencheur à l'entrée du labo de Chen avec `johto_giovanni_seen` + `johto_rival_final_done`, sans
  `johto_chapter_done` : A-49 à A-51, Balle Verte, petit générique [D], sauvegarde proposée.

## 3. Tâches

| N° | Tâche | État |
|---|---|---|
| T1 | `tools/gen_joh9_data.py` : PNJ, Dresseurs (`data/trainers/joh9.json`), textes `joh9_*` A-1 à A-54 mot pour mot, scènes, rencontres | fait |
| T2 | `tools/build_joh9_maps.gd` : 7 cartes depuis les grilles (neige, lac surfable, rochers de Force, échelles, mer de nuages, Vol interdit au sommet) | fait |
| T3 | `build_painted_interiors.gd --joh9` : Centre du Mont Argenté (Centre + marchand), poste de la Route 28, maison du gardien | fait |
| T4 | Zones (`silver_trail`, `mt_silver`, `mt_silver_summit`, `route_28`), point de Vol, point de repos, grottes (`mt_silver`, `mt_silver_dark` : voile), lumière, musique, décors de combat, Boutique | fait |
| T5 | Scènes : relais, rival du 2F (soin), sommet (Dante, Giovanni, Cenere, sauvegarde, rival ; reprises), A-22 | fait |
| T6 | Poste de la Route 28 (A-48, porte verrouillée, A-47) ; variante `JOH9` de la Route 22 (`tools/build_joh9_route22.gd`) | fait |
| T7 | Épilogue au labo (déclencheur posé par `build_joh9_route22.gd`), Balle Verte (`items_joh9.json`), générique nommé `"credits": "johto"` (`data/story/credits_johto.json`, bloc « image ») | fait |
| T8 | Celebi (A-53, A-54, scène `ilex_altar_celebi`) : branchée sur l'autel du JOH4 à sa fusion | données faites ; branchement à la fusion du JOH4 |
| T9 | Départs de débogage `johto_mt_silver*`, `johto_route_28`, `johto_epilogue`, `johto_after_chapter` (`tools/gen_joh9_debug_starts.py`) | fait |
| T10 | Tests `test_joh9_data`, `test_joh9_maps` ; inventaires partagés réalignés après la fusion de JOH1 et JOH2 | en cours |
| T11 | Captures Mac (`tools/capture_joh9.sh`) | fait |
| T12 | QA A17 | fait (2026-11-04, 22 h 06 à 22 h 35 ; un P1 corrigé, §8) |
| T13 | CI verte, fusion dans `main` | fait (2026-11-05) |

## 4. Systèmes touchés (ajouts, rien de retiré)

- `CaveLibrary` + `FlashDirector` : clés facultatives `warn_dialogue` et `flash_cue` d'une grotte
  (A-16, A-17 propres au 2F ; la Grotte Sombre garde les siens).
- Étape `credits` : `true` (Kanto, inchangé) ou un nom (`"johto"` → `data/story/credits_johto.json`) ;
  `CutsceneDirector.credits_id`, `Boot._play_named_credits` ; `CreditsData` : bloc `image`, rangée
  `IMAGE` ; drapeau `johto_credits_seen` (générique passable ensuite).
- `npc.gd`, `player.gd` : correctif du JOH2 (autoload résolu à l'exécution) repris tel quel.

## 6. Valeurs par défaut [D]

- Tuiles provisoires : neige `n` = SAND + voile blanc ; grotte sur `OverworldTiles` (DIRT, RUBBLE,
  CLIFF, WATER) ; mer de nuages = aplat blanc ; échelles en aplats ; Centre `bldg_centre_01`, poste
  `bldg_poste_route_22_01`, maison du gardien `bldg_maison_argenta_01`.
- Lumière : extérieurs `johto_auto`, grottes `cave_1f`.
- Sprites : Dante `gentleman`, Brace et Sbires `rocket_grunt_m`, Cenere `rocket_grunt_f`, Orme
  `researcher`, rival `rival` (tenue d'hiver : art), Montagnards `mountaineer`, Karatéka
  `blackbelt`, Topdresseurs `cooltrainer_m/f`, gardien `old_man`.
- Prix par niveau : Montagnard, Karatéka 36 ; Topdresseur(se) 60 ; Sbires 32 ; Dante et rival 99.
- IA `smart` + changement de Pokémon pour Dante et le rival ; rival final sans attaques imposées
  (attaques de niveau).
- Drapeaux de travail : `johto_summit_reached` (A-23/A-26 à A-28 une fois, A-25 ensuite),
  `johto_rival_final_met` (A-40/A-41 une fois, A-45 ensuite), `johto_green_ball_received`,
  `johto_mt_silver_wind_seen` (A-22 une fois, déclencheur (12, 12..13) vers l'ouest).
- Vol et Téléport interdits au sommet **en permanence** (le dossier : entre Dante et le rival ;
  la scène enchaîne tout, on redescend par l'échelle).
- Variante de la Route 22 active avec `johto_arrived` ; cases Q occupées (FlagGate), pas solides.
- Rocher du 1F : texte d'EXAMINER = texte commun de Force (« Un gros rocher. Il pourrait être
  déplacé. ») ; A-15 n'est pas repris (même sens, un seul texte système de Force).
- Rival du relais : arrive en courant par le chemin depuis (19, 22) ; le joueur monte seul jusqu'à
  (19, 7), A-13, puis la grotte. Rival du 2F : arrive par la galerie est, repart vers l'échelle.
- Sommet : le joueur affronte Dante depuis (10, 8), recule de deux cases avant Cenere (10, 8) ; le
  rival se poste en (14, 8) ; sauvegarde (`save`) juste avant l'arrivée du rival.
- Garde du poste : A-48 (avant), texte [D] après l'ouverture ; « La porte est verrouillée. » [D] côté
  Johto ; gardien de la Route 28 [D] ; Topdresseur Jules [D] (textes absents du dossier, `draft`).
- Épilogue : Orme en (9, 5), le joueur en (8, 5) face à Chen, le rival à la porte (7, 9).
- Générique de Johto : 9 vues peintes réduites (800 px, `assets/ui/credits/`), noms de lieux [D]
  (`draft`), équipe du moment ; les légendaires ne sont pas listés un à un.
- Celebi niv. 60, `wild_battle` avec `catch` = `johto_celebi_done` : K.O. ou fuite → il revient.
- Boutique du Centre : Hyper Ball, Super Ball, Guérison, Potion Max, Hyper Potion, Total Soin,
  Rappel, Max Repousse.
- Musique : sentier `road_to_lavender`, grotte `mt_moon`, sommet `final_road`, Route 28
  `pokemon_road` ; Dante `gym_leader`, rival `rival_final` (HeartGold / SoulSilver au lot Son).

## 8. Fait

### T0 — plan et branche (2026-11-04)

Plan écrit ; branche `claude/joh9-mont-argente-f6ee3a`.

### T1 à T9 (2026-11-04)

Voir §3. Tests `test_joh9_data` (13) et `test_joh9_maps` (9) verts. Scènes jouées sur le Mac
(captures `build/captures/joh9/`).

### T12 — QA A17 (2026-11-04, 22 h 06 à 22 h 35)

Départs de débogage sur l'APK debug. Vu sans erreur : sentier, relais, 1F, voile du 2F sans CS05
(A-16, halo) et avec Flash, soin du rival, sommet (Dante, Giovanni, Cenere, entrée du combat du
rival), poste et porte de la Route 22 dans les deux sens, épilogue, générique Johto, Centre.
L'erreur « aucun chemin » du rival du 2F vient du départ de débogage : la scène y joue sur la case
de sortie du rival, pas sur la galerie (14, 10..12).

**P1 corrigé** : le rival restait sur (7, 9), seule case devant la sortie du labo, après le
générique. Orme et le rival quittent la carte avant le générique ; correctif couvert par un test,
pas rejoué sur le téléphone.

Non joué sur le téléphone : Dante et le rival final jusqu'au bout, rencontres sauvages, marchand.

### Celebi (2026-11-04)

JOH4 fusionné : variante de `ilex_forest_autel` (`tools/gen_joh4_data.py`) vers `ilex_altar_celebi`,
départ `johto_celebi`, combat niv. 60 vu sur le Mac (`tools/capture_joh9.sh build/captures/joh9c celebi`).

### Raccords à la fusion (2026-11-05)

Après JOH5, JOH6, JOH8 : Lac Colère ↔ sentier réel, case à case (`build_joh9_maps.gd`,
`build_joh6_maps.gd` lisent la grille de l'autre carte). Garde forestier et barrière : ceux du JOH6,
doublons retirés. `johto_chapter_done` retiré de `FUTURE_FLAGS`. Raikou : `raikou_retour` au B1F de
la Tour Cendrée, niv. 60 [D], comme Entei (JOH8). `johto_act3` : levé par le JOH8.

### T13 — fusion (2026-11-05)

CI verte run 41951949390 sur `2012ed61` ; fusion `--no-ff` dans `main`.

### Peinture (2026-11-06)

Sentier, extérieur, grotte 1F, 2F, 3F, sommet, Route 28 et poste peints d'après leurs vues
(`tools/art/joh9_argente.py`, `tools/joh_ambiance_neige.gd`, passes `build_joh_ambiance.gd` et
`build_joh_ambiance_caves.gd`). Centre et maison du gardien : intérieurs communs déjà peints, sans
vue propre, gardés. Route 22 ouest exclue (carte de Kanto, peinte au DAF.4). Logique identique avant
et après (`tools/joh_ambiance_dump.sh`) ; seuls les aplats `Neige`, `Nuages` et l'échelle du sommet
partent de `Decor`, et `NightLights` devient un calque.

Défauts [D] : neige `n` en canal des pavés sur le sentier, en sol de base ailleurs ; escalier de la vue
de l'extérieur peint sur les cases (14..24, 7..13), sans effet sur les déplacements ; rangée sud `R`
de l'extérieur en blocs ; versant de la Route 28 en ardoise ; gravats en galets gris ; givre du 3F en
26 traînées, vent de la vue non animé ; nuit de `johto_auto` sans lampe propre au Mont Argenté.

QA A17 du 2026-11-06 (10 h 12 à 10 h 17, APK debug) : sentier, extérieur, 1F, 2F, 3F, sommet, Route 28 et
poste, de jour, sentier et sommet de nuit, sans `SCRIPT ERROR`. 52 i/s, creux à 32, 275 Mo de textures.
