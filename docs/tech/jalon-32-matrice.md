# Jalon 32 — matrice d'obtention des 151 espèces (audit 32.0)

> **Généré par `tools/audit_pokedex.py` — ne pas éditer à la main.** Lecture seule des données des branches : `origin/main`, `origin/jalon-23`, `origin/jalon-26`, `origin/jalon-27`, `origin/jalon-28`, `origin/jalon-29`, `origin/jalon-30`, `origin/jalon-31`, `HEAD`. Règles : arbitrages N-1 à N-16 validés par Kevin (`docs/design/passes/j32-arbitrages-kevin.md`). Une voie compte si elle existe sur **au moins une** branche ; tant que ces branches ne sont pas fusionnées dans `main`, la matrice décrit le jeu « une fois tout fusionné ».

## Résumé

- **116 / 151** obtenables dans une seule sauvegarde solo, sans choix unique ni échange local.
- **18** seulement par un choix unique (une seule par sauvegarde) ; **2** seulement par évolution par échange (terminal local, T4) ; **15** sans aucune voie.
- Espèces sans données sur aucune branche : Élektek, Porygon, Électhor, Minidraco, Mew.

### Choix uniques (une espèce par groupe et par sauvegarde)

- `starters` : Bulbizarre, Herbizarre, Florizarre, Salamèche, Reptincel, Dracaufeu, Carapuce, Carabaffe, Tortank → **N-6** (Chen confie les deux autres après la Ligue).
- `dojo` : Kicklee, Tygnon → **N-8** (le Maître du Dojo offre l'autre Poké Ball après la Ligue).
- `evolutions:eevee` : Aquali, Voltali, Pyroli → **N-9** (deux Évoli de plus sur le toit de Céladopole après la Ligue).
- `fossile_mt_moon` : Amonita, Amonistar, Kabuto, Kabutops → **N-7** (le chercheur du Mont Sélénite confie l'autre fossile à Cramois'Île).

### Par branche (statut atteint grâce à cette branche)

- **main** (119)
- **J26, J27** (2) : Alakazam, Lokhlass
- **J29** (2) : Machopeur, Sulfura
- **J31** (4) : Magnéton, Rhinoféros, Métamorph, Mewtwo
- **J23** (6) : Noeunoeuf, Rhinocorne, Kangourex, Insécateur, Scarabrute, Tauros
- **J27** (2) : Kicklee, Tygnon
- **J23, J31** (1) : Leveinard

### Sans voie

- 065 Alakazam (échange local) → N-15 / T4 : terminal d'échange local dans tous les Centres.
- 068 Mackogneur (manque) → données : évolution absente de `species/` (machoke → machamp (trade)), puis N-15 / T4.
- 076 Grolem (échange local) → N-15 / T4 : terminal d'échange local dans tous les Centres.
- 081 Magnéti (manque) → N-11 : Centrale, lot 32G (Magnéti, sauvage RB à la Centrale seulement).
- 083 Canarticho (manque) → N-14 : échange PNJ Piafabec → Canarticho (Carmin).
- 094 Ectoplasma (manque) → données : évolution absente de `species/` (haunter → gengar (trade)), puis N-15 / T4.
- 103 Noadkoko (manque) → données : évolution absente de `species/` (exeggcute → exeggutor (leaf_stone)).
- 108 Excelangue (manque) → N-14 : échange PNJ Flagadoss → Excelangue (Route 18).
- 122 M. Mime (manque) → N-14 : échange PNJ Abra → M. Mime (Route 2).
- 124 Lippoutou (manque) → N-14 : échange PNJ Têtarte → Lippoutou (Azuria).
- 125 Élektek (manque) → N-11 : Centrale, lot 32G (union Rouge + Bleu).
- 137 Porygon (manque) → N-13 : employé de Sylphe SARL après Giovanni.
- 145 Électhor (manque) → N-11 : Centrale, lot 32G (Électhor N50).
- 147 Minidraco (manque) → N-12 : Super Canne RB au Parc Safari.
- 148 Draco (manque) → N-12 (par évolution de Minidraco) : Super Canne RB au Parc Safari.
- 149 Dracolosse (manque) → N-12 (par évolution de Minidraco) : Super Canne RB au Parc Safari.
- 151 Mew (manque) → N-1 à N-5 : rencontre secrète au camion du quai de Carmin, 150 capturées, N30.

### Évolutions de Rouge/Bleu absentes des données

- machop → machoke (level)
- machoke → machamp (trade)
- haunter → gengar (trade)
- voltorb → electrode (level)
- exeggcute → exeggutor (leaf_stone)
- koffing → weezing (level)
- dratini → dragonair (level)

### Pierres d'évolution

Boutiques et dons uniques des scènes (union des branches, maximum par branche), face au besoin du Pokédex (une pierre par évolution) :

- `fire_stone` : en boutique, 0 don(s) unique(s) ; 3 évolution(s) au Pokédex.
- `leaf_stone` : en boutique, 0 don(s) unique(s) ; 2 évolution(s) au Pokédex.
- `moon_stone` : **absente des boutiques**, 5 don(s) unique(s) ; 4 évolution(s) au Pokédex.
- `thunder_stone` : en boutique, 0 don(s) unique(s) ; 2 évolution(s) au Pokédex.
- `water_stone` : en boutique, 0 don(s) unique(s) ; 4 évolution(s) au Pokédex.

## Matrice

| N° | Espèce | Types | Évolution de | Voies (branches) | Apportée par | Statut | Manque → règle |
|---|---|---|---|---|---|---|---|
| 001 | Bulbizarre (`bulbasaur`) | grass/poison | — | starter : labo de Chen [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 002 | Herbizarre (`ivysaur`) | grass/poison | Bulbizarre (niveau 16) | — | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 003 | Florizarre (`venusaur`) | grass/poison | Herbizarre (niveau 32) | — | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 004 | Salamèche (`charmander`) | fire | — | starter : labo de Chen [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 005 | Reptincel (`charmeleon`) | fire | Salamèche (niveau 16) | — | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 006 | Dracaufeu (`charizard`) | fire/flying | Reptincel (niveau 36) | — | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 007 | Carapuce (`squirtle`) | water | — | starter : labo de Chen [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 008 | Carabaffe (`wartortle`) | water | Carapuce (niveau 16) | — | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 009 | Tortank (`blastoise`) | water | Carabaffe (niveau 36) | — | main | choix unique | N-6 : Chen confie les deux autres après la Ligue |
| 010 | Chenipan (`caterpie`) | bug | — | sauvage : route_24 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : viridian_forest (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 011 | Chrysacier (`metapod`) | bug | Chenipan (niveau 7) | sauvage : route_24 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : viridian_forest (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 012 | Papilusion (`butterfree`) | bug/flying | Chrysacier (niveau 10) | — | main | obtenable | — |
| 013 | Aspicot (`weedle`) | bug/poison | — | sauvage : route_24 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : viridian_forest (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 014 | Coconfort (`kakuna`) | bug/poison | Aspicot (niveau 7) | sauvage : route_24 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : viridian_forest (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 015 | Dardargnan (`beedrill`) | bug/poison | Coconfort (niveau 10) | — | main | obtenable | — |
| 016 | Roucool (`pidgey`) | normal/flying | — | sauvage : route_1, pallet_town (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_12_south (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_13 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_14 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_15 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_2 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_21 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_24 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_2_north (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_5 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_6 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_7 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_8 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 017 | Roucoups (`pidgeotto`) | normal/flying | Roucool (niveau 18) | sauvage : route_14 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_15 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_21 (grass) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 018 | Roucarnage (`pidgeot`) | normal/flying | Roucoups (niveau 36) | — | main | obtenable | — |
| 019 | Rattata (`rattata`) | normal | — | sauvage : route_1, pallet_town (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_16_west (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_2 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_21 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_22 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_2_north (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_3 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_4 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_9 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 020 | Rattatac (`raticate`) | normal | Rattata (niveau 20) | sauvage : route_16_west (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_17 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_18 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_21 (grass) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 021 | Piafabec (`spearow`) | normal/flying | — | sauvage : route_10 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_11 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_16_west (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_17 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_18 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_2 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_22 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_2_north (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_3 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_4 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_9 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_23 (grass) [J29] | main | obtenable | — |
| 022 | Rapasdepic (`fearow`) | normal/flying | Piafabec (niveau 20) | sauvage : route_17 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_18 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_23 (grass) [J29] | main | obtenable | — |
| 023 | Abo (`ekans`) | poison | — | sauvage : route_10 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_11 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_3 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_4 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_8 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_9 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_23 (grass) [J29] | main | obtenable | — |
| 024 | Arbok (`arbok`) | poison | Abo (niveau 22) | sauvage : route_23 (grass) [J29]<br>sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | main | obtenable | — |
| 025 | Pikachu (`pikachu`) | electric | — | sauvage : viridian_forest (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 026 | Raichu (`raichu`) | electric | Pikachu (thunder_stone) | sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | main | obtenable | — |
| 027 | Sabelette (`sandshrew`) | ground | — | sauvage : route_10 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_11 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_3 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_4 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_8 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_9 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_23 (grass) [J29] | main | obtenable | — |
| 028 | Sablaireau (`sandslash`) | ground | Sabelette (niveau 22) | sauvage : route_23 (grass) [J29]<br>sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | main | obtenable | — |
| 029 | Nidoran♀ (`nidoran_f`) | poison | — | sauvage : route_2 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_22 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_2_north (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | main | obtenable | — |
| 030 | Nidorina (`nidorina`) | poison | Nidoran♀ (niveau 16) | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | main | obtenable | — |
| 031 | Nidoqueen (`nidoqueen`) | poison/ground | Nidorina (moon_stone) | — | main | obtenable | — |
| 032 | Nidoran♂ (`nidoran_m`) | poison | — | sauvage : route_2 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_22 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_2_north (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | main | obtenable | — |
| 033 | Nidorino (`nidorino`) | poison | Nidoran♂ (niveau 16) | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | main | obtenable | — |
| 034 | Nidoking (`nidoking`) | poison/ground | Nidorino (moon_stone) | — | main | obtenable | — |
| 035 | Mélofée (`clefairy`) | fairy | — | sauvage : mt_moon_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 036 | Mélodelfe (`clefable`) | fairy | Mélofée (moon_stone) | — | main | obtenable | — |
| 037 | Goupix (`vulpix`) | fire | — | sauvage : pokemon_mansion_1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : route_7 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_8 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 038 | Feunard (`ninetales`) | fire | Goupix (fire_stone) | — | main | obtenable | — |
| 039 | Rondoudou (`jigglypuff`) | normal/fairy | — | sauvage : route_3 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 040 | Grodoudou (`wigglytuff`) | normal/fairy | Rondoudou (moon_stone) | sauvage : cerulean_cave_2f (floor) [J31] | main | obtenable | — |
| 041 | Nosferapti (`zubat`) | poison/flying | — | sauvage : dark_cave_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : victory_road_3f (rubble) [J29] | main | obtenable | — |
| 042 | Nosferalto (`golbat`) | poison/flying | Nosferapti (niveau 22) | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : victory_road_3f (rubble) [J29]<br>sauvage : cerulean_cave_1f (floor) [J31] | main | obtenable | — |
| 043 | Mystherbe (`oddish`) | grass/poison | — | sauvage : route_12_south (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_13 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_14 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_15 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_24 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_5 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_6 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_7 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 044 | Ortide (`gloom`) | grass/poison | Mystherbe (niveau 21) | sauvage : route_12_south (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_13 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_14 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_15 (grass) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 045 | Rafflesia (`vileplume`) | grass/poison | Ortide (leaf_stone) | — | main | obtenable | — |
| 046 | Paras (`paras`) | bug/grass | — | sauvage : mt_moon_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23] | main | obtenable | — |
| 047 | Parasect (`parasect`) | bug/grass | Paras (niveau 24) | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | main | obtenable | — |
| 048 | Mimitoss (`venonat`) | bug/poison | — | sauvage : route_12_south (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_13 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_14 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_15 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | main | obtenable | — |
| 049 | Aéromite (`venomoth`) | bug/poison | Mimitoss (niveau 31) | sauvage : safari_zone_north (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23]<br>sauvage : victory_road_3f (rubble) [J29]<br>sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_2f (floor) [J31] | main | obtenable | — |
| 050 | Taupiqueur (`diglett`) | ground | — | sauvage : digletts_cave (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 051 | Triopikeur (`dugtrio`) | ground | Taupiqueur (niveau 26) | sauvage : digletts_cave (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 052 | Miaouss (`meowth`) | normal | — | sauvage : route_5 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_6 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_7 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_8 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 053 | Persan (`persian`) | normal | Miaouss (niveau 28) | — | main | obtenable | — |
| 054 | Psykokwak (`psyduck`) | water | — | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 055 | Akwakwak (`golduck`) | water | Psykokwak (niveau 33) | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 056 | Férosinge (`mankey`) | fighting | — | sauvage : route_2 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_22 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_2_north (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_4 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_5 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_6 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_7 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_8 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 057 | Colossinge (`primeape`) | fighting | Férosinge (niveau 28) | — | main | obtenable | — |
| 058 | Caninos (`growlithe`) | fire | — | sauvage : pokemon_mansion_1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : route_7 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_8 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 059 | Arcanin (`arcanine`) | fire | Caninos (fire_stone) | — | main | obtenable | — |
| 060 | Ptitard (`poliwag`) | water | — | sauvage : * (good_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 061 | Têtarte (`poliwhirl`) | water | Ptitard (niveau 25) | — | main | obtenable | — |
| 062 | Tartard (`poliwrath`) | water/fighting | Têtarte (water_stone) | — | main | obtenable | — |
| 063 | Abra (`abra`) | psychic | — | sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 064 | Kadabra (`kadabra`) | psychic | Abra (niveau 16) | sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_2f (floor) [J31] | main | obtenable | — |
| 065 | Alakazam (`alakazam`) | psychic | Kadabra (trade) | — | J26, J27 | échange local | N-15 / T4 : terminal d'échange local dans tous les Centres |
| 066 | Machoc (`machop`) | fighting | — | sauvage : dark_cave_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : victory_road_3f (rubble) [J29] | main | obtenable | — |
| 067 | Machopeur (`machoke`) | fighting | — ; absente des données : machop → machoke (level) | sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : victory_road_3f (rubble) [J29] | J29 | obtenable | — |
| 068 | Mackogneur (`machamp`) | fighting | — ; absente des données : machoke → machamp (trade) | — | — | manque | données : évolution absente de `species/` (machoke → machamp (trade)), puis N-15 / T4 |
| 069 | Chétiflor (`bellsprout`) | grass/poison | — | sauvage : route_24 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_25 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_5 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_6 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : route_7 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 070 | Boustiflor (`weepinbell`) | grass/poison | Chétiflor (niveau 21) | — | main | obtenable | — |
| 071 | Empiflor (`victreebel`) | grass/poison | Boustiflor (leaf_stone) | — | main | obtenable | — |
| 072 | Tentacool (`tentacool`) | water/poison | — | sauvage : cinnabar_island (water) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_19 (water) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_20 (water) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_21 (water) [main, J23, J29, J30, J31, HEAD]<br>sauvage : * (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 073 | Tentacruel (`tentacruel`) | water/poison | Tentacool (niveau 30) | — | main | obtenable | — |
| 074 | Racaillou (`geodude`) | rock/ground | — | sauvage : dark_cave_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : victory_road_3f (rubble) [J29] | main | obtenable | — |
| 075 | Gravalanch (`graveler`) | rock/ground | Racaillou (niveau 25) | sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : victory_road_3f (rubble) [J29] | main | obtenable | — |
| 076 | Grolem (`golem`) | rock/ground | Gravalanch (trade) | — | main | échange local | N-15 / T4 : terminal d'échange local dans tous les Centres |
| 077 | Ponyta (`ponyta`) | fire | — | sauvage : pokemon_mansion_1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 078 | Galopa (`rapidash`) | fire | Ponyta (niveau 40) | — | main | obtenable | — |
| 079 | Ramoloss (`slowpoke`) | water/psychic | — | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 080 | Flagadoss (`slowbro`) | water/psychic | Ramoloss (niveau 37) | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [J31] | main | obtenable | — |
| 081 | Magnéti (`magnemite`) | electric/steel | — | — | — | manque | N-11 : Centrale, lot 32G (Magnéti, sauvage RB à la Centrale seulement) |
| 082 | Magnéton (`magneton`) | electric/steel | Magnéti (niveau 30) | sauvage : cerulean_cave_1f (floor) [J31] | J31 | obtenable | — |
| 083 | Canarticho (`farfetchd`) | normal/flying | — | — | — | manque | N-14 : échange PNJ Piafabec → Canarticho (Carmin) |
| 084 | Doduo (`doduo`) | normal/flying | — | sauvage : route_16_west (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_17 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : route_18 (grass) [main, J23, J29, J30, J31, HEAD]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | main | obtenable | — |
| 085 | Dodrio (`dodrio`) | normal/flying | Doduo (niveau 31) | sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_2f (floor) [J31] | main | obtenable | — |
| 086 | Otaria (`seel`) | water | — | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD]<br>échange PNJ : cinnabar_trade_seel (contre ponyta) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 087 | Lamantine (`dewgong`) | water/ice | Otaria (niveau 34) | sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 088 | Tadmorv (`grimer`) | poison | — | sauvage : pokemon_mansion_1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 089 | Grotadmorv (`muk`) | poison | Tadmorv (niveau 38) | sauvage : pokemon_mansion_1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 090 | Kokiyas (`shellder`) | water | — | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 091 | Crustabri (`cloyster`) | water/ice | Kokiyas (water_stone) | — | main | obtenable | — |
| 092 | Fantominus (`gastly`) | ghost/poison | — | sauvage : pokemon_tower_3f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_4f, pokemon_tower_5f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_6f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_7f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 093 | Spectrum (`haunter`) | ghost/poison | Fantominus (niveau 25) | sauvage : pokemon_tower_3f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_4f, pokemon_tower_5f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_6f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_7f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 094 | Ectoplasma (`gengar`) | ghost/poison | — ; absente des données : haunter → gengar (trade) | — | — | manque | données : évolution absente de `species/` (haunter → gengar (trade)), puis N-15 / T4 |
| 095 | Onix (`onix`) | rock/ground | — | sauvage : dark_cave_1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : victory_road_3f (rubble) [J29] | main | obtenable | — |
| 096 | Soporifik (`drowzee`) | psychic | — | sauvage : route_11 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 097 | Hypno (`hypno`) | psychic | Soporifik (niveau 26) | sauvage : cerulean_cave_1f (floor) [J31] | main | obtenable | — |
| 098 | Krabby (`krabby`) | water | — | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : * (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : fuchsia_city (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 099 | Krabboss (`kingler`) | water | Krabby (niveau 28) | sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [J31] | main | obtenable | — |
| 100 | Voltorbe (`voltorb`) | electric | — | sauvage : route_10 (grass) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 101 | Électrode (`electrode`) | electric | — ; absente des données : voltorb → electrode (level) | échange PNJ : cinnabar_trade_electrode (contre raichu) [main, J29, J30, J31, HEAD]<br>sauvage : cerulean_cave_2f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | main | obtenable | — |
| 102 | Noeunoeuf (`exeggcute`) | grass/psychic | — | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | J23 | obtenable | — |
| 103 | Noadkoko (`exeggutor`) | grass/psychic | — ; absente des données : exeggcute → exeggutor (leaf_stone) | — | — | manque | données : évolution absente de `species/` (exeggcute → exeggutor (leaf_stone)) |
| 104 | Osselait (`cubone`) | ground | — | sauvage : pokemon_tower_3f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_4f, pokemon_tower_5f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_6f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : pokemon_tower_7f (floor) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 105 | Ossatueur (`marowak`) | ground | Osselait (niveau 28) | sauvage : victory_road_1f (rubble) [J29]<br>sauvage : victory_road_2f (rubble) [J29]<br>sauvage : cerulean_cave_2f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | main | obtenable | — |
| 106 | Kicklee (`hitmonlee`) | fighting | — | don : fighting_dojo (N30) [J27] | J27 | choix unique | N-8 : le Maître du Dojo offre l'autre Poké Ball après la Ligue |
| 107 | Tygnon (`hitmonchan`) | fighting | — | don : fighting_dojo (N30) [J27] | J27 | choix unique | N-8 : le Maître du Dojo offre l'autre Poké Ball après la Ligue |
| 108 | Excelangue (`lickitung`) | normal | — | — | — | manque | N-14 : échange PNJ Flagadoss → Excelangue (Route 18) |
| 109 | Smogo (`koffing`) | poison | — | sauvage : pokemon_mansion_1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 110 | Smogogo (`weezing`) | poison | — ; absente des données : koffing → weezing (level) | sauvage : pokemon_mansion_1f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 111 | Rhinocorne (`rhyhorn`) | ground/rock | — | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23] | J23 | obtenable | — |
| 112 | Rhinoféros (`rhydon`) | ground/rock | Rhinocorne (niveau 42) | sauvage : cerulean_cave_2f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | J31 | obtenable | — |
| 113 | Leveinard (`chansey`) | normal | — | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_north (grass) [J23]<br>sauvage : cerulean_cave_2f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | J23, J31 | obtenable | — |
| 114 | Saquedeneu (`tangela`) | grass | — | sauvage : route_21 (grass) [main, J23, J29, J30, J31, HEAD]<br>échange PNJ : cinnabar_trade_tangela (contre venonat) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 115 | Kangourex (`kangaskhan`) | normal | — | sauvage : safari_zone_east (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | J23 | obtenable | — |
| 116 | Hypotrempe (`horsea`) | water | — | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 117 | Hypocéan (`seadra`) | water | Hypotrempe (niveau 32) | sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [J31] | main | obtenable | — |
| 118 | Poissirène (`goldeen`) | water | — | sauvage : * (good_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : * (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : fuchsia_city (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 119 | Poissoroy (`seaking`) | water | Poissirène (niveau 33) | sauvage : fuchsia_city (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [J31] | main | obtenable | — |
| 120 | Stari (`staryu`) | water | — | sauvage : seafoam_1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b1f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b2f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b3f (floor) [main, J23, J29, J30, J31, HEAD]<br>sauvage : seafoam_b4f (floor) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 121 | Staross (`starmie`) | water/psychic | Stari (water_stone) | — | main | obtenable | — |
| 122 | M. Mime (`mr_mime`) | psychic | — | — | — | manque | N-14 : échange PNJ Abra → M. Mime (Route 2) |
| 123 | Insécateur (`scyther`) | bug/flying | — | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23] | J23 | obtenable | — |
| 124 | Lippoutou (`jynx`) | ice/psychic | — | — | — | manque | N-14 : échange PNJ Têtarte → Lippoutou (Azuria) |
| 125 | Élektek (`electabuzz`) | — | — | — | — | manque | N-11 : Centrale, lot 32G (union Rouge + Bleu) |
| 126 | Magmar (`magmar`) | fire | — | sauvage : pokemon_mansion_3f (floor) [main, J29, J30, J31, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 127 | Scarabrute (`pinsir`) | bug | — | sauvage : safari_zone_center (grass) [J23]<br>sauvage : safari_zone_east (grass) [J23] | J23 | obtenable | — |
| 128 | Tauros (`tauros`) | normal | — | sauvage : safari_zone_north (grass) [J23]<br>sauvage : safari_zone_west (grass) [J23] | J23 | obtenable | — |
| 129 | Magicarpe (`magikarp`) | water | — | sauvage : * (old_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : * (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>sauvage : fuchsia_city (super_rod) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 130 | Léviator (`gyarados`) | water/flying | Magicarpe (niveau 20) | — | main | obtenable | — |
| 131 | Lokhlass (`lapras`) | water/ice | — | don : silph_co_story (N15) [J26, J27] | J26, J27 | obtenable | — |
| 132 | Métamorph (`ditto`) | normal | — | sauvage : cerulean_cave_1f (floor) [J31]<br>sauvage : cerulean_cave_2f (floor) [J31]<br>sauvage : cerulean_cave_b1f (floor) [J31] | J31 | obtenable | — |
| 133 | Évoli (`eevee`) | normal | — | don : celadon_eevee (N25) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 134 | Aquali (`vaporeon`) | water | Évoli (water_stone) | — | main | choix unique | N-9 : deux Évoli de plus sur le toit de Céladopole après la Ligue |
| 135 | Voltali (`jolteon`) | electric | Évoli (thunder_stone) | — | main | choix unique | N-9 : deux Évoli de plus sur le toit de Céladopole après la Ligue |
| 136 | Pyroli (`flareon`) | fire | Évoli (fire_stone) | — | main | choix unique | N-9 : deux Évoli de plus sur le toit de Céladopole après la Ligue |
| 137 | Porygon (`porygon`) | — | — | — | — | manque | N-13 : employé de Sylphe SARL après Giovanni |
| 138 | Amonita (`omanyte`) | rock/water | — | fossile : helix_fossil → labo de Cramois'Île [main, J23, J29, J30, J31, HEAD] | main | choix unique | N-7 : le chercheur du Mont Sélénite confie l'autre fossile à Cramois'Île |
| 139 | Amonistar (`omastar`) | rock/water | Amonita (niveau 40) | — | main | choix unique | N-7 : le chercheur du Mont Sélénite confie l'autre fossile à Cramois'Île |
| 140 | Kabuto (`kabuto`) | rock/water | — | fossile : dome_fossil → labo de Cramois'Île [main, J23, J29, J30, J31, HEAD] | main | choix unique | N-7 : le chercheur du Mont Sélénite confie l'autre fossile à Cramois'Île |
| 141 | Kabutops (`kabutops`) | rock/water | Kabuto (niveau 40) | — | main | choix unique | N-7 : le chercheur du Mont Sélénite confie l'autre fossile à Cramois'Île |
| 142 | Ptéra (`aerodactyl`) | rock/flying | — | fossile : old_amber → labo de Cramois'Île [main, J29, J30, J31, HEAD] | main | obtenable | — |
| 143 | Ronflex (`snorlax`) | normal | — | fixe : j21_snorlax (N30) [main, J23, J26, J27, J28, J29, J30, J31, HEAD]<br>fixe : j21_snorlax_16 (N30) [main, J23, J26, J27, J28, J29, J30, J31, HEAD] | main | obtenable | — |
| 144 | Artikodin (`articuno`) | ice/flying | — | fixe : seafoam (N50) [main, J23, J29, J30, J31, HEAD] | main | obtenable | — |
| 145 | Électhor (`zapdos`) | — | — | — | — | manque | N-11 : Centrale, lot 32G (Électhor N50) |
| 146 | Sulfura (`moltres`) | fire/flying | — | fixe : j29 (N50) [J29] | J29 | obtenable | — |
| 147 | Minidraco (`dratini`) | — | — | — | — | manque | N-12 : Super Canne RB au Parc Safari |
| 148 | Draco (`dragonair`) | dragon | — ; absente des données : dratini → dragonair (level) | — | — | manque | N-12 (par évolution de Minidraco) : Super Canne RB au Parc Safari |
| 149 | Dracolosse (`dragonite`) | dragon/flying | Draco (niveau 55) | — | — | manque | N-12 (par évolution de Minidraco) : Super Canne RB au Parc Safari |
| 150 | Mewtwo (`mewtwo`) | psychic | — | fixe : cerulean_cave (N70) [J31] | J31 | obtenable | — |
| 151 | Mew (`mew`) | — | — | — | — | manque | N-1 à N-5 : rencontre secrète au camion du quai de Carmin, 150 capturées, N30 |
