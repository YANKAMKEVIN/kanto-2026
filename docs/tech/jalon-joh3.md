# Jalon JOH3 — La grande ville : Routes 37, 36, 35, Doublonville

> **PLAN.** Sources de vérité : `docs/design/dossier-joh-04-doublonville.md` (textes D-1 à D-38
> et arbitrages JH-31 à JH-36 validés par Kevin le 2026-11-02 ; le reste porte des défauts
> **[D]**) ; cadre `dossier-joh-00-cadre.md` (§4.2, §5.2 : œuf de Togepi au JOH3) ; grilles
> `tools/plans/route_37.txt`, `route_36.txt`, `route_35.txt`, `doublonville.txt`,
> `souterrain.txt` (validées le 2026-11-02, **elles font foi**) ; vues générales
> `docs/design/reference/route-37-*`, `route-36-*`, `route-35-*`, `doublonville-*`,
> `souterrain-doublonville-*` (validées le 2026-11-03, DA seulement). Systèmes : JOH0
> (`jalon-joh0.md` §2, §8). Modèle de construction : JOH2 (`jalon-joh2.md`). Écrit le 2026-11-04
> sur la branche `claude/joh3-doublonville-74be43` (cut de `main` @ `695e0216` ; `main` refusionné
> dès que JOH1 et JOH2 y sont).

> Objectif jouable : **de la sortie sud de Rosalia à la sortie sud de Doublonville** : Route 37
> (Lise ; deux Sbires la nuit), Route 36 (Max, Ernest, pont en travaux, grille du Parc fermée,
> Mercédès le mercredi), Route 35 (Gaston, Armand, Anna inévitable, étang : pêche et Surf),
> Doublonville (titre et haut-parleur, Centre avec Orme et l'œuf de Togepi, Grand Magasin sur
> 3 niveaux + toit avec promotion du jour et Améliorator, maison du lien de Mme Clémence, deux
> maisons, porte de la Tour Radio vers le hall du JOH5, Jérôme le jeudi), Souterrain (deux Sbires
> évitables, chef obligatoire, indice vers Écorcia), sortie sud ouverte par l'agent → Route 34
> « à venir » (JOH4).
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA A17, fusion
> dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change.

## 0. État des lieux (2026-11-04)

| Point | Réel | Conséquence |
|---|---|---|
| Construction depuis une grille | `build_joh2_maps.gd` + `gen_joh2_data.py` (JOH2, pas encore dans `main`) | Même modèle : `tools/build_joh3_maps.gd`, `tools/gen_joh3_data.py`, préfixe `joh3_` des fichiers de données |
| Rosalia | `ecruteak_city` du JOH2, warp sud → `route_37` / `from_ecruteak` (« À venir ») | Relancer `build_joh2_maps.gd --maps=ecruteak_city` après ma construction : le raccord cesse d'être « À venir » |
| Tour Radio | Grille `radio_tower_1f.txt` du **JOH5** (faux employé, D-18 sans la Carte, ascenseur D-19) | Ici : la porte et la façade ; warp vers `goldenrod_radio_tower_1f` « À venir » jusqu'à la fusion du JOH5. Textes D-18, D-19 écrits ici (ids donnés au JOH5 par message), drapeau `johto_radio_tower_closed_seen` posé par la scène du JOH5 |
| Route 34 | JOH4 | Sortie sud « À venir » (« Route 34 ») ; arrivée `from_route_34` posée |
| Grand Magasin | Céladopole (J20) : grilles `celadopole_magasin_*.txt`, coques peintes, comptoirs, distributeurs | Réutilisés [D] (RdC, 2e de Céladopole → 1er, 5e → 2e, toit) ; pas d'ascenseur [D] |
| Promotion du jour | Aucune : `ShopRules` ne connaît que les drapeaux | **Neuf** : `promotions` (jour → objets à moitié prix) et `if_weekday` d'une ligne de stock ; jour lu à l'ouverture de la Boutique |
| Paliers du lien | `BondRules.tier` (JOH0) ; aucune condition de dialogue | **Neuf** : variante `if_lead_bond_tier` (0..3, `egg`) lue par `DialogueRunner.lead_bond_source` |
| Œuf, équipe pleine | `give_egg` refuse avec une erreur | **Neuf** : clés `flag` (posé seulement si l'œuf est donné) et `say_full` (dialogue quand l'équipe est pleine) |
| Perle | Absente des objets | Celle du JOH1 (`items_joh1.json`, grotte marine), reprise à la fusion |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH3A** — systèmes | T1 promotion du jour, T2 paliers du lien, T3 œuf (équipe pleine), T4 Perle | Tests unitaires |
| **JOH3B** — cartes et vie | T5 données générées, T6 cartes extérieures, T7 Souterrain et intérieurs, T8 données de monde, T9 rencontres et pêche, T10 scènes, T11 départs de débogage | Tests, captures Mac |
| Clôture | T12 tests d'intégration, T13 captures, T14 QA A17, T15 CI, fusion, état, compte rendu | Déléguée |

## 2. Conception technique

### 2.1 Cartes

| Carte | Identifiant | Grille | Lumière | Outil |
|---|---|---|---|---|
| Route 37 | `route_37` | `route_37.txt` (20 × 40) | `johto_auto` | `build_joh3_maps.gd` |
| Route 36 | `route_36` | `route_36.txt` (56 × 20) | `johto_auto` | idem |
| Route 35 | `route_35` | `route_35.txt` (24 × 44) | `johto_auto` | idem |
| Doublonville | `goldenrod_city` | `doublonville.txt` (72 × 60) | `johto_auto` | idem |
| Souterrain | `goldenrod_underground` | `souterrain.txt` (40 × 14) | `interior_warm` [D] | idem (carte intérieure) |
| Centre | `goldenrod_center` | définition commune | `interior_warm` | `build_painted_interiors.gd --doublonville` |
| Grand Magasin RdC, 1er, 2e | `goldenrod_dept_store_1f`, `_2f`, `_3f` | `celadopole_magasin_rdc`, `_2e`, `_5e` [D] | `interior_warm` | idem |
| Toit | `goldenrod_dept_store_roof` | `celadopole_magasin_toit` [D] | `golden_hour` | idem |
| Maison du lien | `goldenrod_bond_house` | `lavanville_maison_1.txt` [D] | `interior_warm` | idem |
| Maisons 1 et 2 | `goldenrod_house_1`, `_2` | `lavanville_maison_2.txt`, `_1` [D] | `interior_warm` | idem |

- Tuiles provisoires comme au JOH2 ; `w` (étang de la Route 35) = eau **surfable** (`surf_cells`)
  et les cases d'eau qui touchent la berge sont **pêchables** (`fishable_cells`) [D] ; `W`
  (rivière de la Route 36) bloquée ; `b` pont praticable ; `X` barrière, `P` façades (Parc, poste
  de garde), emprises `U A L C m N F` bloquées.
- Bâtiments du kit peint [D] : Centre `bldg_centre_01`, maisons `bldg_maison_argenta_01`, Grand
  Magasin et Tour Radio, gare : **aplats provisoires** (`Polygon2D`) sur leur emprise (modèle des
  tours du JOH2) ; Parc et poste de garde de la Route 35 : aplats.
- Lampes de nuit (`night_lights`) [D] : Doublonville (avenue, place, devant le Centre et le
  Magasin, fenêtres de la Tour Radio) ; Route 35 (poste de garde).

### 2.2 Raccords (dossier §3.2)

| Passage | Mécanisme |
|---|---|
| Rosalia (26..28, 47) ↔ Route 37 (8..10, 0) | PUSH ; `from_ecruteak` / `from_route_37` (warps case à case) |
| Route 37 (8..10, 39) ↔ Route 36 (8..10, 0) | PUSH ; `from_route_36` / `from_route_37` |
| Route 36 (26..28, 19) ↔ Route 35 (10..12, 0) | PUSH ; `from_route_35` / `from_route_36` |
| Route 35 (10..12, 43) ↔ Doublonville (34..36, 0) | PUSH ; `from_goldenrod` / `from_route_35` |
| Doublonville (34..36, 59) → Route 34 | PUSH ↓ « À venir » (« Route 34 ») ; arrivée `from_route_34` |
| Escaliers (31, 25), (39, 33) ↔ Souterrain (1, 5..6), (38, 7..8) | STEP_ON ; `from_goldenrod_west` / `_east`, `from_underground_w` / `_e` |
| Portes | Centre, maison du lien, maisons, Magasin (STEP_ON ↑) ; Tour Radio → `goldenrod_radio_tower_1f` / `from_city` « À venir » (JOH5) |

### 2.3 Barrière sud, agent (D-33, D-34)

- `agent_sud` (33, 56) `unless johto_azalea_clue` ; `agent_sud_range` (33, 55) `if johto_azalea_clue`
  [D] (deux PNJ, même dialogue à variantes : D-33 sans le drapeau, D-34 avec).
- Déclencheur `barriere_sud` (34..36, 56), sens ↓, `unless johto_azalea_clue` : face, D-33, un pas
  en arrière.

### 2.4 Œuf de Togepi (JH-32, D-12 à D-15)

Orme au Centre (`goldenrod_center`, (11, 5) [D], sprite `researcher`), dialogue à variantes :
1. `unless johto_goldenrod_orme_met` : D-12, `set johto_goldenrod_orme_met`, puis la scène de l'œuf ;
2. `unless johto_egg_received` : la scène de l'œuf (redonnée tant que l'équipe était pleine) ;
3. sinon D-15.

Scène `goldenrod_orme_egg` : dialogue D-13 (quatre pages) → `give_egg togepi`, `steps 2000`,
`say` = D-13 (ligne système), `say_full` = D-14, `flag` = `johto_egg_received`.
`give_egg` (JOH0) gagne `flag` et `say_full` : équipe pleine → `say_full`, rien d'autre ; sinon
l'œuf, `say`, le drapeau. D-16 et D-17 sont les textes du JOH0 (`EggHatching`, `EggRules.hint_text`)
réalignés **mot pour mot** sur le dossier (seuils > 1 000 / 300–1 000 / < 300).

### 2.5 Maison du lien (D-24 à D-27)

`DialogueVariant.lead_bond_tiers` (clé `if_lead_bond_tier` : un entier 0..3 ou `"egg"`, ou une
liste) ; `Dialogue.pick` reçoit la source ; `BondReader.lead_tier(state)` (pur) : compagnon s'il y
en a un ; sinon, si le premier de l'équipe est un œuf, `egg` (-1) ; sinon le premier non-œuf
(`BondRules.tier`). Mme Clémence : variante œuf (D-27) ; quatre variantes de palier (D-24 puis le
palier puis D-26, une bulle par page).

### 2.6 Grand Magasin et promotion (JH-33)

- `ShopData.promotions: Dictionary[StringName, Array[StringName]]` (jour → objets à moitié prix,
  arrondi à l'unité inférieure [D]) ; ligne de stock `if_weekday` (un jour ou une liste).
- `ShopRules.stock(shop, flags, weekday = &"")` : une ligne `if_weekday` n'est vendue que ce
  jour-là (sans jour : jamais) ; `ShopRules.unit_price(shop, item, weekday)` ; `buy(..., weekday)`.
- `MenuDirector.weekday_source: Callable` (Boot : `WorldClock` du moment) ; lu à **l'ouverture**
  de la Boutique (le prix change à la réouverture, dossier §13). Kanto : aucune promotion, rien ne
  change.
- Boutiques : `goldenrod_dept_2f` (1er : 8 objets + Rappel `if_weekday friday`),
  `goldenrod_dept_3f` (2e : 7 objets), trois distributeurs du toit ; promotions §8.2.
- Panneau D-21 (RdC) : sept variantes `if_weekday`, `{article}` remplacé à la génération.
- Améliorator : Poké Ball posée sur le toit (`goldenrod_upgrade_taken`, D-22).

### 2.7 Drapeaux

`johto_goldenrod_arrived`, `johto_goldenrod_orme_met` [D], `johto_egg_received`,
`johto_radio_tower_closed_seen` (posé par le JOH5), `johto_azalea_clue`, `goldenrod_upgrade_taken`,
`week_wednesday_gift`, `week_thursday_gift`, `got_<objet>`. Les Sbires vaincus : drapeaux de
Dresseur habituels.

### 2.8 Rencontres et pêche (dossier §5)

Tables `route_37_grass_day` / `_night`, `route_36_grass_morning` (Chenipan) / `_day` / `_night`,
`route_35_grass_day` / `_night`, `route_35_surf` (toute la journée) ; Super Canne de la Route 35 :
Ptitard, Poissirène (`data/fishing/joh3_route_35.json`, niv. 15 [D]) ; Canne : Magicarpe (table
commune). Taux 25, rampe standard.

### 2.9 Départs de débogage

`johto_route_37` (+ `_night`), `johto_goldenrod` (+ `_night`, `_wednesday`, `_thursday`,
`_full_party`), `johto_underground`.

## 3. Tâches

| N° | Tâche | Critère |
|---|---|---|
| T1 | Promotion du jour (`ShopData`, `ShopLibrary`, `ShopRules`, `ShopViews`, `MenuDirector`, Boot) | Tests : prix moitié le bon jour, Rappel le vendredi seulement, Kanto inchangé |
| T2 | `if_lead_bond_tier`, `BondReader` | Tests : compagnon, œuf en tête, paliers |
| T3 | `give_egg` `flag` / `say_full` | Tests : équipe pleine, drapeau |
| T4 | Perle | Objet chargé, vendable |
| T5 | `tools/gen_joh3_data.py` | Textes D-1 à D-38 mot pour mot (`test_joh3_data`) |
| T6 | `tools/build_joh3_maps.gd` | Grille = plan, raccords, emprises, eau surfable |
| T7 | Souterrain et intérieurs (`--doublonville`), PNJ de chaque intérieur | Infirmière, vendeurs, hôtesse, Orme, Mme Clémence présents |
| T8 | Zones, intérieurs, repos, musique, lumière, Vol, Carte, aperçus | Tests d'inventaire verts |
| T9 | Rencontres par moment, Surf, pêche | `get_table` par moment |
| T10 | Scènes : titre et haut-parleur, agent, Souterrain, œuf, semaine | Ordre Souterrain → sortie sud |
| T11 | Départs de débogage | Fichiers lus |
| T12 | Tests d'intégration (`test_joh3_maps`, `test_joh3_boot`) | `tools/test.sh --changed` vert |
| T13 | Captures Mac (Routes 37 et 35 de nuit, Doublonville jour et nuit, Souterrain, toit) | Relues |
| T14 | QA A17 | Parcours Rosalia → sortie sud |
| T15 | CI, refusion de `main`, fusion, état, compte rendu | `main` vert |

## 4. Critères d'acceptation

1. De Rosalia, on traverse les Routes 37, 36, 35 jusqu'à Doublonville ; Anna est inévitable ;
   les autres Dresseurs sont évitables ; la nuit, deux Sbires sur la Route 37.
2. Doublonville : titre et haut-parleur (D-10) une fois ; Orme donne l'œuf (ou le garde si
   l'équipe est pleine) ; Tour Radio : porte vers le hall (JOH5) ; Souterrain : chef obligatoire,
   indice, l'agent s'écarte et la sortie sud mène à la Route 34 (« à venir »).
3. Grand Magasin : promotion du jour au panneau et au prix ; Rappel le vendredi ; Améliorator ;
   Mme Clémence lit le lien ; Mercédès le mercredi, Jérôme le jeudi.
4. Tests ciblés verts, import sans erreur, CI verte, QA A17 sans bloquant, fusion.

## 5. Valeurs par défaut [D] de ce plan

Tuiles et bâtiments provisoires, aplats du Magasin, de la Tour, de la gare, du Parc et du poste ;
grilles du Magasin reprises de Céladopole, sans ascenseur ; Orme en (11, 5) ; arrondi des
promotions ; Souterrain en `interior_warm` ; Super Canne niv. 15 ; sprites des PNJ ; agent rangé
par un second PNJ ; drapeau `johto_goldenrod_orme_met` ; prix de la Perle ; textes absents du
dossier en `draft` (grille du Parc, habitant de la maison 2, hôtesse du toit…).

## 6. Fait

| Tâche | Commit | Note |
|---|---|---|
| Plan | `9081f8a4` | Ce document |
| T1–T4 (JOH3A) | `d0e17e7d` | Promotion du jour, `if_lead_bond_tier` et `BondReader`, `give_egg` `flag` / `say_full`, Perle ; D-16 et D-17 du JOH0 réalignés ; `test_joh3_systems` |
| T5–T11 | `7c2e2565` | `gen_joh3_data.py`, `build_joh3_maps.gd`, `--doublonville`, données de monde, départs de débogage ; `npc.gd` / `player.gd` repris du JOH2 (outils sous `godot -s`) |
| T12 | `76a4caf3` | `test_joh3_maps` (10), `test_joh3_data` (11), `test_joh3_boot` (4) ; registres réalignés ; objets du Souterrain préfixés `goldenrod_underground_` (collision avec `underground_7_8`) ; Grand Magasin en aplat (le bâtiment peint de Céladopole fait 14 cases pour une emprise de 12 et bloquait Jérôme) |

| T13 | `76a4caf3` et suivants | `tools/capture_joh3.sh` (24 plans, `build/captures/joh3/`) relus : Routes 37 jour et nuit (Sbires), 36 (pont, Parc), 35 (étang, Anna), Doublonville (entrée, haut-parleur, place, Tour Radio, Magasin, sud, nuit), Souterrain, Centre (Orme), Magasin, toit, maison du lien. Corrigé : massifs de fleurs (tuile à fond noir → herbe + fleurs peintes), Grand Magasin peint trop large → aplat |
| `main` | (fusion) | JOH1 refusionné : la Perle est celle du JOH1 ; Oliville et ses intérieurs gardés |
| `main` | `cab39b03` et suivants | JOH2, JOH7 puis JOH4 refusionnés : raccords Rosalia ↔ Route 37 et Doublonville ↔ Route 34 réels (`per_cell`), inventaires des jalons réunis |
| T15 | fusion dans `main` | CI verte run 41919992604 sur `73a70b9a` (8 lots), QA A17 sans P0 ni P1 |
| T14 | QA A17, 2026-11-04 | Aucun P0 ni P1 (détail dans `etat-projet.md`) ; objectifs [D] `reach_goldenrod`, `search_underground` ajoutés (`meet_kurt` du JOH4 prend la suite) après la QA |

Écarts [D] relevés pendant le code : D-12 « Tu es venu » écrit `{g:venu|venue}` (accord de la
joueuse, JR-7) ; `{pokemon}` de D-12 = le compagnon (page omise sans compagnon, règle des jetons) ;
D-28 : la mention entre parenthèses du dossier devient la seconde bulle du panneau ; Orme redonne
l'œuf sans répéter D-12 ; le chef dit l'indice (D-32) comme réplique « après » (posée à chaque
fois, une partie fermée juste après le combat le retrouve).
