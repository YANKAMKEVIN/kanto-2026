# Jalon 32 — matrice d'obtention des 151 espèces (audit 32.0)

> **Généré par `tools/audit_pokedex.py` — ne pas éditer à la main.** Lecture seule des données des branches : `origin/main`, `HEAD`. Règles : arbitrages N-1 à N-16 validés par Kevin (`docs/design/passes/j32-arbitrages-kevin.md`). Une voie compte si elle existe sur **au moins une** branche ; tant que ces branches ne sont pas fusionnées dans `main`, la matrice décrit le jeu « une fois tout fusionné ».

## Résumé

- **147 / 151** obtenables dans une seule sauvegarde solo, sans choix unique ni échange local.
- **0** seulement par un choix unique (une seule par sauvegarde) ; **4** seulement par évolution par échange (terminal local des Centres, T4 et T5) ; **0** sans aucune voie.
- Espèces sans données sur aucune branche : aucune.

### Choix uniques (une espèce par groupe et par sauvegarde)


### Par branche (statut atteint grâce à cette branche)

- **HEAD** (33) : Bulbizarre, Herbizarre, Florizarre, Salamèche, Reptincel, Dracaufeu, Carapuce, Carabaffe, Tortank, Mackogneur, Magnéti, Canarticho, Ectoplasma, Noadkoko, Kicklee, Tygnon, Excelangue, M. Mime, Lippoutou, Élektek, Aquali, Voltali, Pyroli, Porygon, Amonita, Amonistar, Kabuto, Kabutops, Électhor, Minidraco, Draco, Dracolosse, Mew
- **main** (118)

### Sans voie, ou seulement par le terminal d'échange local

- 065 Alakazam (échange local) → N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5).
- 068 Mackogneur (échange local) → N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5).
- 076 Grolem (échange local) → N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5).
- 094 Ectoplasma (échange local) → N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5).

### Évolutions de Rouge/Bleu absentes des données

- aucune

### Pierres d'évolution

Boutiques et dons uniques des scènes (union des branches, maximum par branche), face au besoin du Pokédex (une pierre par évolution) :

- `fire_stone` : en boutique, 0 don(s) unique(s) ; 3 évolution(s) au Pokédex.
- `leaf_stone` : en boutique, 0 don(s) unique(s) ; 3 évolution(s) au Pokédex.
- `moon_stone` : **absente des boutiques**, 5 don(s) unique(s) ; 4 évolution(s) au Pokédex.
- `thunder_stone` : en boutique, 0 don(s) unique(s) ; 2 évolution(s) au Pokédex.
- `water_stone` : en boutique, 0 don(s) unique(s) ; 4 évolution(s) au Pokédex.

## Matrice

| N° | Espèce | Types | Évolution de | Voies (branches) | Apportée par | Statut | Manque → règle |
|---|---|---|---|---|---|---|---|
| 001 | Bulbizarre (`bulbasaur`) | grass/poison | — | starter : labo de Chen [main, HEAD]<br>don : j32_collection (N5) [HEAD] | HEAD | obtenable | — |
| 002 | Herbizarre (`ivysaur`) | grass/poison | Bulbizarre (niveau 16) | — | HEAD | obtenable | — |
| 003 | Florizarre (`venusaur`) | grass/poison | Herbizarre (niveau 32) | — | HEAD | obtenable | — |
| 004 | Salamèche (`charmander`) | fire | — | starter : labo de Chen [main, HEAD]<br>don : j32_collection (N5) [HEAD] | HEAD | obtenable | — |
| 005 | Reptincel (`charmeleon`) | fire | Salamèche (niveau 16) | — | HEAD | obtenable | — |
| 006 | Dracaufeu (`charizard`) | fire/flying | Reptincel (niveau 36) | — | HEAD | obtenable | — |
| 007 | Carapuce (`squirtle`) | water | — | starter : labo de Chen [main, HEAD]<br>don : j32_collection (N5) [HEAD] | HEAD | obtenable | — |
| 008 | Carabaffe (`wartortle`) | water | Carapuce (niveau 16) | — | HEAD | obtenable | — |
| 009 | Tortank (`blastoise`) | water | Carabaffe (niveau 36) | — | HEAD | obtenable | — |
| 010 | Chenipan (`caterpie`) | bug | — | sauvage : route_24 (grass) [main, HEAD]<br>sauvage : route_25 (grass) [main, HEAD]<br>sauvage : viridian_forest (grass) [main, HEAD] | main | obtenable | — |
| 011 | Chrysacier (`metapod`) | bug | Chenipan (niveau 7) | sauvage : route_24 (grass) [main, HEAD]<br>sauvage : route_25 (grass) [main, HEAD]<br>sauvage : viridian_forest (grass) [main, HEAD] | main | obtenable | — |
| 012 | Papilusion (`butterfree`) | bug/flying | Chrysacier (niveau 10) | — | main | obtenable | — |
| 013 | Aspicot (`weedle`) | bug/poison | — | sauvage : route_24 (grass) [main, HEAD]<br>sauvage : route_25 (grass) [main, HEAD]<br>sauvage : viridian_forest (grass) [main, HEAD] | main | obtenable | — |
| 014 | Coconfort (`kakuna`) | bug/poison | Aspicot (niveau 7) | sauvage : route_24 (grass) [main, HEAD]<br>sauvage : route_25 (grass) [main, HEAD]<br>sauvage : viridian_forest (grass) [main, HEAD] | main | obtenable | — |
| 015 | Dardargnan (`beedrill`) | bug/poison | Coconfort (niveau 10) | — | main | obtenable | — |
| 016 | Roucool (`pidgey`) | normal/flying | — | sauvage : route_1, pallet_town (grass) [main, HEAD]<br>sauvage : route_12_south (grass) [main, HEAD]<br>sauvage : route_13 (grass) [main, HEAD]<br>sauvage : route_14 (grass) [main, HEAD]<br>sauvage : route_15 (grass) [main, HEAD]<br>sauvage : route_2 (grass) [main, HEAD]<br>sauvage : route_21 (grass) [main, HEAD]<br>sauvage : route_24 (grass) [main, HEAD]<br>sauvage : route_25 (grass) [main, HEAD]<br>sauvage : route_2_north (grass) [main, HEAD]<br>sauvage : route_5 (grass) [main, HEAD]<br>sauvage : route_6 (grass) [main, HEAD]<br>sauvage : route_7 (grass) [main, HEAD]<br>sauvage : route_8 (grass) [main, HEAD] | main | obtenable | — |
| 017 | Roucoups (`pidgeotto`) | normal/flying | Roucool (niveau 18) | sauvage : route_14 (grass) [main, HEAD]<br>sauvage : route_15 (grass) [main, HEAD]<br>sauvage : route_21 (grass) [main, HEAD] | main | obtenable | — |
| 018 | Roucarnage (`pidgeot`) | normal/flying | Roucoups (niveau 36) | — | main | obtenable | — |
| 019 | Rattata (`rattata`) | normal | — | sauvage : route_1, pallet_town (grass) [main, HEAD]<br>sauvage : route_16_west (grass) [main, HEAD]<br>sauvage : route_2 (grass) [main, HEAD]<br>sauvage : route_21 (grass) [main, HEAD]<br>sauvage : route_22, route_22_west (grass) [main, HEAD]<br>sauvage : route_2_north (grass) [main, HEAD]<br>sauvage : route_3 (grass) [main, HEAD]<br>sauvage : route_4 (grass) [main, HEAD]<br>sauvage : route_9 (grass) [main, HEAD] | main | obtenable | — |
| 020 | Rattatac (`raticate`) | normal | Rattata (niveau 20) | sauvage : route_16_west (grass) [main, HEAD]<br>sauvage : route_17 (grass) [main, HEAD]<br>sauvage : route_18 (grass) [main, HEAD]<br>sauvage : route_21 (grass) [main, HEAD] | main | obtenable | — |
| 021 | Piafabec (`spearow`) | normal/flying | — | sauvage : route_10 (grass) [main, HEAD]<br>sauvage : route_11 (grass) [main, HEAD]<br>sauvage : route_16_west (grass) [main, HEAD]<br>sauvage : route_17 (grass) [main, HEAD]<br>sauvage : route_18 (grass) [main, HEAD]<br>sauvage : route_2 (grass) [main, HEAD]<br>sauvage : route_22, route_22_west (grass) [main, HEAD]<br>sauvage : route_23 (grass) [main, HEAD]<br>sauvage : route_2_north (grass) [main, HEAD]<br>sauvage : route_3 (grass) [main, HEAD]<br>sauvage : route_4 (grass) [main, HEAD]<br>sauvage : route_9 (grass) [main, HEAD] | main | obtenable | — |
| 022 | Rapasdepic (`fearow`) | normal/flying | Piafabec (niveau 20) | sauvage : route_17 (grass) [main, HEAD]<br>sauvage : route_18 (grass) [main, HEAD]<br>sauvage : route_23 (grass) [main, HEAD] | main | obtenable | — |
| 023 | Abo (`ekans`) | poison | — | sauvage : route_10 (grass) [main, HEAD]<br>sauvage : route_11 (grass) [main, HEAD]<br>sauvage : route_23 (grass) [main, HEAD]<br>sauvage : route_3 (grass) [main, HEAD]<br>sauvage : route_4 (grass) [main, HEAD]<br>sauvage : route_8 (grass) [main, HEAD]<br>sauvage : route_9 (grass) [main, HEAD] | main | obtenable | — |
| 024 | Arbok (`arbok`) | poison | Abo (niveau 22) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD]<br>sauvage : route_23 (grass) [main, HEAD] | main | obtenable | — |
| 025 | Pikachu (`pikachu`) | electric | — | sauvage : viridian_forest (grass) [main, HEAD]<br>sauvage : power_plant (floor) [HEAD] | main | obtenable | — |
| 026 | Raichu (`raichu`) | electric | Pikachu (thunder_stone) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD]<br>sauvage : power_plant (floor) [HEAD] | main | obtenable | — |
| 027 | Sabelette (`sandshrew`) | ground | — | sauvage : route_10 (grass) [main, HEAD]<br>sauvage : route_11 (grass) [main, HEAD]<br>sauvage : route_23 (grass) [main, HEAD]<br>sauvage : route_3 (grass) [main, HEAD]<br>sauvage : route_4 (grass) [main, HEAD]<br>sauvage : route_8 (grass) [main, HEAD]<br>sauvage : route_9 (grass) [main, HEAD] | main | obtenable | — |
| 028 | Sablaireau (`sandslash`) | ground | Sabelette (niveau 22) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD]<br>sauvage : route_23 (grass) [main, HEAD] | main | obtenable | — |
| 029 | Nidoran♀ (`nidoran_f`) | poison | — | sauvage : route_2 (grass) [main, HEAD]<br>sauvage : route_22, route_22_west (grass) [main, HEAD]<br>sauvage : route_2_north (grass) [main, HEAD]<br>sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD]<br>échange PNJ : route_5_trade_nidoran_f (contre nidoran_m) [HEAD] | main | obtenable | — |
| 030 | Nidorina (`nidorina`) | poison | Nidoran♀ (niveau 16) | sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD]<br>échange PNJ : route_11_trade_nidorina (contre nidorino) [HEAD] | main | obtenable | — |
| 031 | Nidoqueen (`nidoqueen`) | poison/ground | Nidorina (moon_stone) | — | main | obtenable | — |
| 032 | Nidoran♂ (`nidoran_m`) | poison | — | sauvage : route_2 (grass) [main, HEAD]<br>sauvage : route_22, route_22_west (grass) [main, HEAD]<br>sauvage : route_2_north (grass) [main, HEAD]<br>sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD] | main | obtenable | — |
| 033 | Nidorino (`nidorino`) | poison | Nidoran♂ (niveau 16) | sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD] | main | obtenable | — |
| 034 | Nidoking (`nidoking`) | poison/ground | Nidorino (moon_stone) | — | main | obtenable | — |
| 035 | Mélofée (`clefairy`) | fairy | — | sauvage : mt_moon_1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, HEAD] | main | obtenable | — |
| 036 | Mélodelfe (`clefable`) | fairy | Mélofée (moon_stone) | — | main | obtenable | — |
| 037 | Goupix (`vulpix`) | fire | — | sauvage : pokemon_mansion_1f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD]<br>sauvage : route_7 (grass) [main, HEAD]<br>sauvage : route_8 (grass) [main, HEAD] | main | obtenable | — |
| 038 | Feunard (`ninetales`) | fire | Goupix (fire_stone) | — | main | obtenable | — |
| 039 | Rondoudou (`jigglypuff`) | normal/fairy | — | sauvage : route_3 (grass) [main, HEAD] | main | obtenable | — |
| 040 | Grodoudou (`wigglytuff`) | normal/fairy | Rondoudou (moon_stone) | sauvage : cerulean_cave_2f (floor) [main, HEAD] | main | obtenable | — |
| 041 | Nosferapti (`zubat`) | poison/flying | — | sauvage : dark_cave_1f (rubble) [main, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, HEAD]<br>sauvage : mt_moon_1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, HEAD]<br>sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 042 | Nosferalto (`golbat`) | poison/flying | Nosferapti (niveau 22) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD]<br>sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 043 | Mystherbe (`oddish`) | grass/poison | — | sauvage : route_12_south (grass) [main, HEAD]<br>sauvage : route_13 (grass) [main, HEAD]<br>sauvage : route_14 (grass) [main, HEAD]<br>sauvage : route_15 (grass) [main, HEAD]<br>sauvage : route_24 (grass) [main, HEAD]<br>sauvage : route_25 (grass) [main, HEAD]<br>sauvage : route_5 (grass) [main, HEAD]<br>sauvage : route_6 (grass) [main, HEAD]<br>sauvage : route_7 (grass) [main, HEAD] | main | obtenable | — |
| 044 | Ortide (`gloom`) | grass/poison | Mystherbe (niveau 21) | sauvage : route_12_south (grass) [main, HEAD]<br>sauvage : route_13 (grass) [main, HEAD]<br>sauvage : route_14 (grass) [main, HEAD]<br>sauvage : route_15 (grass) [main, HEAD] | main | obtenable | — |
| 045 | Rafflesia (`vileplume`) | grass/poison | Ortide (leaf_stone) | — | main | obtenable | — |
| 046 | Paras (`paras`) | bug/grass | — | sauvage : mt_moon_1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD] | main | obtenable | — |
| 047 | Parasect (`parasect`) | bug/grass | Paras (niveau 24) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD]<br>sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD] | main | obtenable | — |
| 048 | Mimitoss (`venonat`) | bug/poison | — | sauvage : route_12_south (grass) [main, HEAD]<br>sauvage : route_13 (grass) [main, HEAD]<br>sauvage : route_14 (grass) [main, HEAD]<br>sauvage : route_15 (grass) [main, HEAD]<br>sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD] | main | obtenable | — |
| 049 | Aéromite (`venomoth`) | bug/poison | Mimitoss (niveau 31) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_2f (floor) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 050 | Taupiqueur (`diglett`) | ground | — | sauvage : digletts_cave (rubble) [main, HEAD] | main | obtenable | — |
| 051 | Triopikeur (`dugtrio`) | ground | Taupiqueur (niveau 26) | sauvage : digletts_cave (rubble) [main, HEAD] | main | obtenable | — |
| 052 | Miaouss (`meowth`) | normal | — | sauvage : route_5 (grass) [main, HEAD]<br>sauvage : route_6 (grass) [main, HEAD]<br>sauvage : route_7 (grass) [main, HEAD]<br>sauvage : route_8 (grass) [main, HEAD] | main | obtenable | — |
| 053 | Persan (`persian`) | normal | Miaouss (niveau 28) | — | main | obtenable | — |
| 054 | Psykokwak (`psyduck`) | water | — | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD]<br>sauvage : safari_zone_center, safari_zone_east, safari_zone_north… (super_rod) [HEAD] | main | obtenable | — |
| 055 | Akwakwak (`golduck`) | water | Psykokwak (niveau 33) | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD] | main | obtenable | — |
| 056 | Férosinge (`mankey`) | fighting | — | sauvage : route_2 (grass) [main, HEAD]<br>sauvage : route_22, route_22_west (grass) [main, HEAD]<br>sauvage : route_2_north (grass) [main, HEAD]<br>sauvage : route_4 (grass) [main, HEAD]<br>sauvage : route_5 (grass) [main, HEAD]<br>sauvage : route_6 (grass) [main, HEAD]<br>sauvage : route_7 (grass) [main, HEAD]<br>sauvage : route_8 (grass) [main, HEAD] | main | obtenable | — |
| 057 | Colossinge (`primeape`) | fighting | Férosinge (niveau 28) | — | main | obtenable | — |
| 058 | Caninos (`growlithe`) | fire | — | sauvage : pokemon_mansion_1f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD]<br>sauvage : route_7 (grass) [main, HEAD]<br>sauvage : route_8 (grass) [main, HEAD] | main | obtenable | — |
| 059 | Arcanin (`arcanine`) | fire | Caninos (fire_stone) | — | main | obtenable | — |
| 060 | Ptitard (`poliwag`) | water | — | sauvage : * (good_rod) [main, HEAD] | main | obtenable | — |
| 061 | Têtarte (`poliwhirl`) | water | Ptitard (niveau 25) | — | main | obtenable | — |
| 062 | Tartard (`poliwrath`) | water/fighting | Têtarte (water_stone) | — | main | obtenable | — |
| 063 | Abra (`abra`) | psychic | — | sauvage : route_25 (grass) [main, HEAD] | main | obtenable | — |
| 064 | Kadabra (`kadabra`) | psychic | Abra (niveau 16) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_2f (floor) [main, HEAD] | main | obtenable | — |
| 065 | Alakazam (`alakazam`) | psychic | Kadabra (trade) | — | main | échange local | N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5) |
| 066 | Machoc (`machop`) | fighting | — | sauvage : dark_cave_1f (rubble) [main, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, HEAD]<br>sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 067 | Machopeur (`machoke`) | fighting | Machoc (niveau 28) | sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 068 | Mackogneur (`machamp`) | fighting | Machopeur (trade) | — | HEAD | échange local | N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5) |
| 069 | Chétiflor (`bellsprout`) | grass/poison | — | sauvage : route_24 (grass) [main, HEAD]<br>sauvage : route_25 (grass) [main, HEAD]<br>sauvage : route_5 (grass) [main, HEAD]<br>sauvage : route_6 (grass) [main, HEAD]<br>sauvage : route_7 (grass) [main, HEAD] | main | obtenable | — |
| 070 | Boustiflor (`weepinbell`) | grass/poison | Chétiflor (niveau 21) | — | main | obtenable | — |
| 071 | Empiflor (`victreebel`) | grass/poison | Boustiflor (leaf_stone) | — | main | obtenable | — |
| 072 | Tentacool (`tentacool`) | water/poison | — | sauvage : cinnabar_island (water) [main, HEAD]<br>sauvage : route_19 (water) [main, HEAD]<br>sauvage : route_20 (water) [main, HEAD]<br>sauvage : route_21 (water) [main, HEAD]<br>sauvage : * (super_rod) [main, HEAD] | main | obtenable | — |
| 073 | Tentacruel (`tentacruel`) | water/poison | Tentacool (niveau 30) | — | main | obtenable | — |
| 074 | Racaillou (`geodude`) | rock/ground | — | sauvage : dark_cave_1f (rubble) [main, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, HEAD]<br>sauvage : mt_moon_1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b1f (rubble) [main, HEAD]<br>sauvage : mt_moon_b2f (rubble) [main, HEAD]<br>sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 075 | Gravalanch (`graveler`) | rock/ground | Racaillou (niveau 25) | sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 076 | Grolem (`golem`) | rock/ground | Gravalanch (trade) | — | main | échange local | N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5) |
| 077 | Ponyta (`ponyta`) | fire | — | sauvage : pokemon_mansion_1f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD] | main | obtenable | — |
| 078 | Galopa (`rapidash`) | fire | Ponyta (niveau 40) | — | main | obtenable | — |
| 079 | Ramoloss (`slowpoke`) | water/psychic | — | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD]<br>sauvage : safari_zone_center, safari_zone_east, safari_zone_north… (super_rod) [HEAD] | main | obtenable | — |
| 080 | Flagadoss (`slowbro`) | water/psychic | Ramoloss (niveau 37) | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [main, HEAD] | main | obtenable | — |
| 081 | Magnéti (`magnemite`) | electric/steel | — | sauvage : power_plant (floor) [HEAD] | HEAD | obtenable | — |
| 082 | Magnéton (`magneton`) | electric/steel | Magnéti (niveau 30) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : power_plant (floor) [HEAD] | main | obtenable | — |
| 083 | Canarticho (`farfetchd`) | normal/flying | — | échange PNJ : vermilion_trade_farfetchd (contre spearow) [HEAD] | HEAD | obtenable | — |
| 084 | Doduo (`doduo`) | normal/flying | — | sauvage : route_16_west (grass) [main, HEAD]<br>sauvage : route_17 (grass) [main, HEAD]<br>sauvage : route_18 (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD] | main | obtenable | — |
| 085 | Dodrio (`dodrio`) | normal/flying | Doduo (niveau 31) | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_2f (floor) [main, HEAD] | main | obtenable | — |
| 086 | Otaria (`seel`) | water | — | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD]<br>échange PNJ : cinnabar_trade_seel (contre ponyta) [main, HEAD] | main | obtenable | — |
| 087 | Lamantine (`dewgong`) | water/ice | Otaria (niveau 34) | sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD] | main | obtenable | — |
| 088 | Tadmorv (`grimer`) | poison | — | sauvage : pokemon_mansion_1f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD] | main | obtenable | — |
| 089 | Grotadmorv (`muk`) | poison | Tadmorv (niveau 38) | sauvage : pokemon_mansion_1f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD] | main | obtenable | — |
| 090 | Kokiyas (`shellder`) | water | — | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD] | main | obtenable | — |
| 091 | Crustabri (`cloyster`) | water/ice | Kokiyas (water_stone) | — | main | obtenable | — |
| 092 | Fantominus (`gastly`) | ghost/poison | — | sauvage : pokemon_tower_3f (floor) [main, HEAD]<br>sauvage : pokemon_tower_4f, pokemon_tower_5f (floor) [main, HEAD]<br>sauvage : pokemon_tower_6f (floor) [main, HEAD]<br>sauvage : pokemon_tower_7f (floor) [main, HEAD] | main | obtenable | — |
| 093 | Spectrum (`haunter`) | ghost/poison | Fantominus (niveau 25) | sauvage : pokemon_tower_3f (floor) [main, HEAD]<br>sauvage : pokemon_tower_4f, pokemon_tower_5f (floor) [main, HEAD]<br>sauvage : pokemon_tower_6f (floor) [main, HEAD]<br>sauvage : pokemon_tower_7f (floor) [main, HEAD] | main | obtenable | — |
| 094 | Ectoplasma (`gengar`) | ghost/poison | Spectrum (trade) | — | HEAD | échange local | N-15 / T4, T5 : terminal d'échange local des Centres (écran fait, J32 T5) |
| 095 | Onix (`onix`) | rock/ground | — | sauvage : dark_cave_1f (rubble) [main, HEAD]<br>sauvage : dark_cave_b1f (rubble) [main, HEAD]<br>sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD]<br>sauvage : victory_road_3f (rubble) [main, HEAD] | main | obtenable | — |
| 096 | Soporifik (`drowzee`) | psychic | — | sauvage : route_11 (grass) [main, HEAD] | main | obtenable | — |
| 097 | Hypnomade (`hypno`) | psychic | Soporifik (niveau 26) | sauvage : cerulean_cave_1f (floor) [main, HEAD] | main | obtenable | — |
| 098 | Krabby (`krabby`) | water | — | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD]<br>sauvage : * (super_rod) [main, HEAD]<br>sauvage : fuchsia_city (super_rod) [main, HEAD]<br>sauvage : safari_zone_center, safari_zone_east, safari_zone_north… (super_rod) [HEAD] | main | obtenable | — |
| 099 | Krabboss (`kingler`) | water | Krabby (niveau 28) | sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [main, HEAD] | main | obtenable | — |
| 100 | Voltorbe (`voltorb`) | electric | — | sauvage : route_10 (grass) [main, HEAD]<br>sauvage : power_plant (floor) [HEAD]<br>fixe : j32_power_plant (N40) [HEAD] | main | obtenable | — |
| 101 | Électrode (`electrode`) | electric | Voltorbe (niveau 30) | sauvage : cerulean_cave_2f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD]<br>échange PNJ : cinnabar_trade_electrode (contre raichu) [main, HEAD]<br>fixe : j32_power_plant (N43) [HEAD] | main | obtenable | — |
| 102 | Noeunoeuf (`exeggcute`) | grass/psychic | — | sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD] | main | obtenable | — |
| 103 | Noadkoko (`exeggutor`) | grass/psychic | Noeunoeuf (leaf_stone) | — | HEAD | obtenable | — |
| 104 | Osselait (`cubone`) | ground | — | sauvage : pokemon_tower_3f (floor) [main, HEAD]<br>sauvage : pokemon_tower_4f, pokemon_tower_5f (floor) [main, HEAD]<br>sauvage : pokemon_tower_6f (floor) [main, HEAD]<br>sauvage : pokemon_tower_7f (floor) [main, HEAD] | main | obtenable | — |
| 105 | Ossatueur (`marowak`) | ground | Osselait (niveau 28) | sauvage : cerulean_cave_2f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD]<br>sauvage : victory_road_1f (rubble) [main, HEAD]<br>sauvage : victory_road_2f (rubble) [main, HEAD] | main | obtenable | — |
| 106 | Kicklee (`hitmonlee`) | fighting | — | don : fighting_dojo (N30) [main, HEAD]<br>don : j32_collection (N30) [HEAD] | HEAD | obtenable | — |
| 107 | Tygnon (`hitmonchan`) | fighting | — | don : fighting_dojo (N30) [main, HEAD]<br>don : j32_collection (N30) [HEAD] | HEAD | obtenable | — |
| 108 | Excelangue (`lickitung`) | normal | — | échange PNJ : route_18_trade_lickitung (contre slowbro) [HEAD] | HEAD | obtenable | — |
| 109 | Smogo (`koffing`) | poison | — | sauvage : pokemon_mansion_1f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD] | main | obtenable | — |
| 110 | Smogogo (`weezing`) | poison | Smogo (niveau 35) | sauvage : pokemon_mansion_1f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_2f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD] | main | obtenable | — |
| 111 | Rhinocorne (`rhyhorn`) | ground/rock | — | sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD] | main | obtenable | — |
| 112 | Rhinoféros (`rhydon`) | ground/rock | Rhinocorne (niveau 42) | sauvage : cerulean_cave_2f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD] | main | obtenable | — |
| 113 | Leveinard (`chansey`) | normal | — | sauvage : cerulean_cave_2f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD]<br>sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_north (grass) [main, HEAD] | main | obtenable | — |
| 114 | Saquedeneu (`tangela`) | grass | — | sauvage : route_21 (grass) [main, HEAD]<br>échange PNJ : cinnabar_trade_tangela (contre venonat) [main, HEAD] | main | obtenable | — |
| 115 | Kangourex (`kangaskhan`) | normal | — | sauvage : safari_zone_east (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD] | main | obtenable | — |
| 116 | Hypotrempe (`horsea`) | water | — | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD] | main | obtenable | — |
| 117 | Hypocéan (`seadra`) | water | Hypotrempe (niveau 32) | sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [main, HEAD] | main | obtenable | — |
| 118 | Poissirène (`goldeen`) | water | — | sauvage : * (good_rod) [main, HEAD]<br>sauvage : * (super_rod) [main, HEAD]<br>sauvage : fuchsia_city (super_rod) [main, HEAD] | main | obtenable | — |
| 119 | Poissoroy (`seaking`) | water | Poissirène (niveau 33) | sauvage : fuchsia_city (super_rod) [main, HEAD]<br>sauvage : cerulean_cave_1f, cerulean_cave_2f, cerulean_cave_b1f (super_rod) [main, HEAD] | main | obtenable | — |
| 120 | Stari (`staryu`) | water | — | sauvage : seafoam_1f (floor) [main, HEAD]<br>sauvage : seafoam_b1f (floor) [main, HEAD]<br>sauvage : seafoam_b2f (floor) [main, HEAD]<br>sauvage : seafoam_b3f (floor) [main, HEAD]<br>sauvage : seafoam_b4f (floor) [main, HEAD] | main | obtenable | — |
| 121 | Staross (`starmie`) | water/psychic | Stari (water_stone) | — | main | obtenable | — |
| 122 | M. Mime (`mr_mime`) | psychic | — | échange PNJ : route_2_trade_mr_mime (contre abra) [HEAD] | HEAD | obtenable | — |
| 123 | Insécateur (`scyther`) | bug/flying | — | sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD] | main | obtenable | — |
| 124 | Lippoutou (`jynx`) | ice/psychic | — | échange PNJ : cerulean_trade_jynx (contre poliwhirl) [HEAD] | HEAD | obtenable | — |
| 125 | Élektek (`electabuzz`) | electric | — | sauvage : power_plant (floor) [HEAD] | HEAD | obtenable | — |
| 126 | Magmar (`magmar`) | fire | — | sauvage : pokemon_mansion_3f (floor) [main, HEAD]<br>sauvage : pokemon_mansion_b1f (floor) [main, HEAD] | main | obtenable | — |
| 127 | Scarabrute (`pinsir`) | bug | — | sauvage : safari_zone_center (grass) [main, HEAD]<br>sauvage : safari_zone_east (grass) [main, HEAD] | main | obtenable | — |
| 128 | Tauros (`tauros`) | normal | — | sauvage : safari_zone_north (grass) [main, HEAD]<br>sauvage : safari_zone_west (grass) [main, HEAD] | main | obtenable | — |
| 129 | Magicarpe (`magikarp`) | water | — | sauvage : * (old_rod) [main, HEAD]<br>sauvage : * (super_rod) [main, HEAD]<br>sauvage : fuchsia_city (super_rod) [main, HEAD] | main | obtenable | — |
| 130 | Léviator (`gyarados`) | water/flying | Magicarpe (niveau 20) | — | main | obtenable | — |
| 131 | Lokhlass (`lapras`) | water/ice | — | don : silph_co_story (N15) [main, HEAD] | main | obtenable | — |
| 132 | Métamorph (`ditto`) | normal | — | sauvage : cerulean_cave_1f (floor) [main, HEAD]<br>sauvage : cerulean_cave_2f (floor) [main, HEAD]<br>sauvage : cerulean_cave_b1f (floor) [main, HEAD] | main | obtenable | — |
| 133 | Évoli (`eevee`) | normal | — | don : celadon_eevee (N25) [main, HEAD]<br>don : j32_collection (N25) [HEAD]<br>don : j32_collection (N25) [HEAD] | main | obtenable | — |
| 134 | Aquali (`vaporeon`) | water | Évoli (water_stone) | — | HEAD | obtenable | — |
| 135 | Voltali (`jolteon`) | electric | Évoli (thunder_stone) | — | HEAD | obtenable | — |
| 136 | Pyroli (`flareon`) | fire | Évoli (fire_stone) | — | HEAD | obtenable | — |
| 137 | Porygon (`porygon`) | normal | — | don : j32_porygon (N26) [HEAD] | HEAD | obtenable | — |
| 138 | Amonita (`omanyte`) | rock/water | — | fossile : helix_fossil → labo de Cramois'Île [main, HEAD] | HEAD | obtenable | — |
| 139 | Amonistar (`omastar`) | rock/water | Amonita (niveau 40) | — | HEAD | obtenable | — |
| 140 | Kabuto (`kabuto`) | rock/water | — | fossile : dome_fossil → labo de Cramois'Île [main, HEAD] | HEAD | obtenable | — |
| 141 | Kabutops (`kabutops`) | rock/water | Kabuto (niveau 40) | — | HEAD | obtenable | — |
| 142 | Ptéra (`aerodactyl`) | rock/flying | — | fossile : old_amber → labo de Cramois'Île [main, HEAD] | main | obtenable | — |
| 143 | Ronflex (`snorlax`) | normal | — | fixe : j21_snorlax (N30) [main, HEAD]<br>fixe : j21_snorlax_16 (N30) [main, HEAD]<br>fixe : j32_snorlax (N30) [HEAD] | main | obtenable | — |
| 144 | Artikodin (`articuno`) | ice/flying | — | fixe : seafoam (N50) [main, HEAD] | main | obtenable | — |
| 145 | Électhor (`zapdos`) | electric/flying | — | fixe : j32_power_plant (N50) [HEAD] | HEAD | obtenable | — |
| 146 | Sulfura (`moltres`) | fire/flying | — | fixe : j29 (N50) [main, HEAD] | main | obtenable | — |
| 147 | Minidraco (`dratini`) | dragon | — | sauvage : safari_zone_center, safari_zone_east, safari_zone_north… (super_rod) [HEAD] | HEAD | obtenable | — |
| 148 | Draco (`dragonair`) | dragon | Minidraco (niveau 30) | — | HEAD | obtenable | — |
| 149 | Dracolosse (`dragonite`) | dragon/flying | Draco (niveau 55) | — | HEAD | obtenable | — |
| 150 | Mewtwo (`mewtwo`) | psychic | — | fixe : cerulean_cave (N70) [main, HEAD] | main | obtenable | — |
| 151 | Mew (`mew`) | psychic | — | fixe : j32_mew (N30) [HEAD] | HEAD | obtenable | — |
