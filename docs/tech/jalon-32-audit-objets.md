# Jalon 32 — T6 : audit des secrets et objets

> **Audit en lecture seule** (T6, `jalon-32.md` §2) sur `origin/jalon-32` @ `aa184830` : aucun fichier de données ni de code n'est modifié. Les cases viennent des grilles `tools/plans/*.txt` (là où l'identifiant de la grille égale celui de la scène). La référence Rouge/Bleu est celle des commentaires `# RB …` des grilles et des dossiers de conception (relevé RB déjà fait par les jalons) ; ce que l'auteur de l'audit ne peut pas confirmer est marqué **à vérifier**.

## 0. Comment le jeu déclare un objet

| Mécanisme | Où | Remarque |
|---|---|---|
| Objet au sol (visible) | PNJ-objet dans `data/npcs/<carte>.json` (sprite `object/poke_ball_ground`, `"verb": "take"`, `"unless": ["got_<id>"]`) **ou** interactable `.tscn` posé par `tools/build_*.gd` ; le dialogue renvoie à une cutscène | Grille : ligne `<id> objet_visible x,y item=…` |
| Objet caché | Point d'examen (`objet_cache`, `depuis=`/`face=`) → cutscène | Même cutscène, `"found": true` |
| Don / récompense | Pas `{ "give": "<objet>", "count": n }` d'une cutscène (`data/cutscenes/*.json`), drapeau `got_*` | 216 pas `give` dans 65 fichiers ; 209 hors rattrapages `*_tm_late` (voir plus bas) |
| Pierres / boutique | `data/shops/*.json` (liste `stock`) | 10 fichiers |
| Échange PNJ | `data/trades/rb_trades.json`, `cinnabar.json` (`InGameTrade`) + `data/cutscenes/j32_trades.json`, `cinnabar_trades.json` | 9 échanges |
| Don de Pokémon | pas `{ "gift_pokemon": … }` (cutscènes) | hors objets : voir la matrice T1 |
| Pêche | `data/fishing/water_rod.json` + cases d'eau (`data/world/fishable.json`, cases `f` des grilles) | 1 table par canne, 3 lieux spéciaux de Super Canne |
| Safari | `data/safari/safari.json` (entrée 500 ₽, 30 balls, 500 pas, bonus ×2) | |
| Fossiles | `data/world/fossils.json` | 3 fossiles → Kabuto, Amonita, Ptéra |

Sept cutscènes « `*_tm_late` » (Pierre, Ondine, Major Bob, Erika, Koga, Sabrina, Giovanni) redonnent la CT d'Arène si le joueur l'a laissée (variante de rattrapage) : elles ne comptent pas comme objets supplémentaires.

## 1. Synthèse chiffrée

- **209 pas `give` (hors rattrapages)** : **127 visibles**, **47 cachés**, **35 dons/récompenses** (CT d'Arène comprises).
- Catalogue d'objets : **88 objets** (`data/items/*.json`). **2 objets définis ne sont jamais obtenables** : `guard_spec`, `max_ether`.
- CT obtenables : **26 sur 50** (01, 05, 06, 09, 11, 13, 14, 17, 19, 21, 22, 24, 25, 27, 28, 32, 33, 34, 35, 37, 38, 39, 40, 43, 46, 47). **24 manquantes** : 02, 03, 04, 07, 08, 10, 12, 15, 16, 18, 20, 23, 26, 29, 30, 31, 36, 41, 42, 44, 45, 48, 49, 50. 4 d'entre elles n'ont pas de capacité dans le jeu (02 Coupe-Vent, 31 Copie, 41 Soin, 48 Éboulement).
- CS obtenables : **5 sur 5** (CS01 capitaine du S.S. Anne, CS02 Route 16, CS03 maison secrète du Safari, CS04 Gardien, CS05 assistant de Chen).
- Pierres : les 5 pierres d'évolution sont obtenables (4 en boutique, Pierre Lune en 5 ramassages) ; fossiles et Vieil Ambre obtenables.
- Objets clés de progression (Colis, Pass Bateau, Flûte, Scope Sylphe, Carte magnétique, Clé Ascenseur, Clé Secrète, Dents d'Or, Bon de Commande, Bicyclette, 3 cannes) : tous présents.
- **Aucun P0** : rien à la lecture ne bloque la progression ni la complétion du Pokédex (la matrice T1 : 147/151 sans échange, 4 par échange local, 0 sans voie).


## 2. Tableaux par zone (ordre de l'aventure)

Lecture : « visible » = Poké Ball au sol ; « caché » = point d'examen ; « don/récompense » = remise par un PNJ, une Arène ou une cutscène de scénario (`found` absent). « Case » = case de la grille quand son identifiant égale celui de la cutscène (sinon « — », la case figure dans la grille de la carte sous un autre identifiant). Les lignes `*_tm_late` sont les rattrapages d'une CT d'Arène.


#### Bourg Palette

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `starter_chosen` | Poké Ball (`poke_ball`) | 5 | don/récompense | — | `data/cutscenes/starter.json` |

#### Route 1

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_1_potion` | Potion (`potion`) | 1 | visible | — | `data/cutscenes/route_1.json` |

#### Jadielle

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `mart_parcel` | Colis pour Chen (`oak_parcel`) | 1 | don/récompense | — | `data/cutscenes/viridian_mart.json` |

#### Arène de Jadielle

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `viridian_gym_giovanni` | CT27 — Abîme (`tm27`) | 1 | don/récompense | — | `data/cutscenes/viridian_gym.json` |
| `viridian_gym_giovanni_tm_late` | CT27 — Abîme (`tm27`) | 1 | don/récompense | — | `data/cutscenes/viridian_gym.json` |
| `viridian_gym_item_1` | Rappel (`revive`) | 1 | visible | — | `data/cutscenes/viridian_gym.json` |

#### Route 2 (sud)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_2_item_1` | Poké Ball (`poke_ball`) | 1 | visible | — | `data/cutscenes/route_2.json` |
| `route_2_item_2` | Potion (`potion`) | 1 | visible | — | `data/cutscenes/route_2.json` |
| `route_2_item_3` | Poké Ball (`poke_ball`) | 1 | visible | 13,42 | `data/cutscenes/route_2.json` |
| `route_2_item_4` | Potion (`potion`) | 1 | visible | 16,9 | `data/cutscenes/route_2.json` |
| `route_2_item_5` | Super Potion (`super_potion`) | 1 | visible | 1,17 | `data/cutscenes/route_2.json` |

#### Forêt de Jade

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `viridian_forest_item_1` | Antidote (`antidote`) | 1 | visible | 34,83 | `data/cutscenes/viridian_forest.json` |
| `viridian_forest_item_2` | Poké Ball (`poke_ball`) | 1 | visible | 4,77 | `data/cutscenes/viridian_forest.json` |
| `viridian_forest_item_3` | Potion (`potion`) | 1 | visible | 29,53 | `data/cutscenes/viridian_forest.json` |
| `viridian_forest_item_4` | Antidote (`antidote`) | 1 | visible | 6,49 | `data/cutscenes/viridian_forest.json` |
| `viridian_forest_item_5` | Poké Ball (`poke_ball`) | 1 | visible | 59,5 | `data/cutscenes/viridian_forest.json` |
| `viridian_forest_item_6` | Potion (`potion`) | 1 | visible | 23,6 | `data/cutscenes/viridian_forest.json` |

#### Route 2 (nord)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_2_north_item_1` | Potion (`potion`) | 1 | visible | — | `data/cutscenes/route_2_north.json` |

#### Argenta (Arène)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `pewter_gym_brock` | CT34 — Patience (`tm34`) | 1 | don/récompense | — | `data/cutscenes/pewter_gym.json` |
| `pewter_gym_brock_tm_late` | CT34 — Patience (`tm34`) | 1 | don/récompense | — | `data/cutscenes/pewter_gym.json` |

#### Argenta (Musée)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `pewter_museum_old_amber` | Vieil Ambre (`old_amber`) | 1 | don/récompense | — | `data/cutscenes/pewter_museum_reserve.json` |

#### Route 3

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_3_hidden_1` | Réveil (`awakening`) | 1 | caché | — | `data/cutscenes/route_3.json` |
| `route_3_item_1` | Poké Ball (`poke_ball`) | 1 | visible | 34,36 | `data/cutscenes/route_3.json` |
| `route_3_item_2` | Potion (`potion`) | 1 | visible | 57,14 | `data/cutscenes/route_3.json` |
| `route_3_item_3` | Anti-Para (`paralyze_heal`) | 1 | visible | 77,23 | `data/cutscenes/route_3.json` |

#### Mont Sélénite 1F

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `mt_moon_1f_hidden_1` | Réveil (`awakening`) | 1 | caché | 56,19 | `data/cutscenes/mt_moon.json` |
| `mt_moon_1f_item_1` | Corde Sortie (`escape_rope`) | 1 | visible | 9,29 | `data/cutscenes/mt_moon.json` |

#### Mont Sélénite B1F

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `mt_moon_b1f_item_1` | Pierre Lune (`moon_stone`) | 1 | visible | 25,20 | `data/cutscenes/mt_moon.json` |
| `mt_moon_b1f_item_2` | Potion (`potion`) | 1 | visible | 16,21 | `data/cutscenes/mt_moon.json` |

#### Mont Sélénite B2F

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `mt_moon_b2f_hidden_1` | Pierre Lune (`moon_stone`) | 1 | caché | 35,12 | `data/cutscenes/mt_moon.json` |
| `mt_moon_b2f_item_1` | CT01 — Ultimapoing (`tm01`) | 1 | visible | 4,5 | `data/cutscenes/mt_moon.json` |

#### Mont Sélénite B2F (fossiles)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `mt_moon_fossil_dome` | Fossile Dôme (`dome_fossil`) | 1 | don/récompense | — | `data/cutscenes/mt_moon.json` |
| `mt_moon_fossil_helix` | Fossile Nautile (`helix_fossil`) | 1 | don/récompense | — | `data/cutscenes/mt_moon.json` |

#### Route 4

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_4_item_1` | Poké Ball (`poke_ball`) | 1 | visible | 21,20 | `data/cutscenes/route_4.json` |

#### Azuria (Arène)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `cerulean_gym_misty` | CT11 — Bulles d'O (`tm11`) | 1 | don/récompense | — | `data/cutscenes/cerulean_gym.json` |
| `cerulean_gym_misty_tm_late` | CT11 — Bulles d'O (`tm11`) | 1 | don/récompense | — | `data/cutscenes/cerulean_gym.json` |

#### Azuria (maison cambriolée)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `cerulean_rocket_fight` | CT28 — Tunnel (`tm28`) | 1 | don/récompense | — | `data/cutscenes/cerulean_rocket.json` |

#### Route 24

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_24_antidote` | Antidote (`antidote`) | 1 | visible | — | `data/cutscenes/route_24.json` |
| `route_24_item_1` | Potion (`potion`) | 1 | visible | 44,3 | `data/cutscenes/route_24.json` |
| `route_24_rocket` | Pépite (`nugget`) | 1 | don/récompense | — | `data/cutscenes/route_24.json` |

#### Route 25

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_25_hidden_1` | Potion (`potion`) | 1 | caché | — | `data/cutscenes/route_25.json` |
| `route_25_item_1` | CT19 — Frappe Atlas (`tm19`) | 1 | visible | 33,5 | `data/cutscenes/route_25.json` |
| `route_25_item_2` | Potion (`potion`) | 1 | visible | 35,19 | `data/cutscenes/route_25.json` |
| `route_25_item_3` | Poké Ball (`poke_ball`) | 1 | visible | 77,21 | `data/cutscenes/route_25.json` |

#### Route 25 (maison de Léo/Bill)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `bill_machine` | Passe Bateau (`ss_ticket`) | 1 | don/récompense | — | `data/cutscenes/bill_house.json` |
| `bill_machine` | Super Bonbon (`rare_candy`) | 1 | don/récompense | — | `data/cutscenes/bill_house.json` |

#### Route 5

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_5_hidden_1` | Antidote (`antidote`) | 1 | caché | — | `data/cutscenes/route_5.json` |
| `route_5_item_1` | Super Potion (`super_potion`) | 1 | visible | 11,15 | `data/cutscenes/route_5.json` |

#### Souterrain Routes 5-6

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `underground_hidden_1` | Guérison (`full_restore`) | 1 | caché | — | `data/cutscenes/underground_path.json` |

#### Route 6

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_6_hidden_1` | Super Potion (`super_potion`) | 1 | caché | — | `data/cutscenes/route_6.json` |
| `route_6_item_1` | Poké Ball (`poke_ball`) | 1 | visible | 38,41 | `data/cutscenes/route_6.json` |

#### Carmin (Arène)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `vermilion_gym_surge` | CT24 — Tonnerre (`tm24`) | 1 | don/récompense | — | `data/cutscenes/vermilion_gym.json` |
| `vermilion_gym_surge_tm_late` | CT24 — Tonnerre (`tm24`) | 1 | don/récompense | — | `data/cutscenes/vermilion_gym.json` |

#### S.S. Anne

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `ss_anne_hidden_1` | Réveil (`awakening`) | 1 | caché | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_hidden_2` | Antidote (`antidote`) | 1 | caché | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_hidden_3` | Potion (`potion`) | 1 | caché | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_item_01` | Potion (`potion`) | 1 | visible | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_item_02` | Potion (`potion`) | 1 | visible | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_item_03` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_item_04` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_item_05` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/ss_anne_life.json` |
| `ss_anne_item_06` | Anti-Para (`paralyze_heal`) | 1 | visible | — | `data/cutscenes/ss_anne_life.json` |

#### S.S. Anne (capitaine)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `ss_anne_captain` | CS01 — Coupe (`hm01`) | 1 | don/récompense | — | `data/cutscenes/ss_anne_captain_room.json` |

#### Route 11

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_11_hidden_1` | Poké Ball (`poke_ball`) | 1 | caché | — | `data/cutscenes/route_11.json` |
| `route_11_item_1` | Super Potion (`super_potion`) | 1 | visible | 40,13 | `data/cutscenes/route_11.json` |
| `route_11_item_2` | Réveil (`awakening`) | 1 | visible | 47,25 | `data/cutscenes/route_11.json` |

#### Grotte Taupiqueur

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `digletts_cave_item_1` | Corde Sortie (`escape_rope`) | 1 | visible | — | `data/cutscenes/digletts_cave.json` |

#### Route 2 (est)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_2_east_give_hm05` | CS05 — Flash (`hm05`) | 1 | don/récompense | — | `data/cutscenes/route_2_east.json` |
| `route_2_east_item_1` | Pierre Lune (`moon_stone`) | 1 | visible | 12,26 | `data/cutscenes/route_2_east.json` |
| `route_2_east_item_2` | Super Bonbon (`rare_candy`) | 1 | visible | 3,33 | `data/cutscenes/route_2_east.json` |

#### Route 9

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_9_item_1` | Super Potion (`super_potion`) | 1 | visible | 32,9 | `data/cutscenes/route_9.json` |
| `route_9_item_2` | Antidote (`antidote`) | 1 | visible | 29,25 | `data/cutscenes/route_9.json` |
| `route_9_item_3` | Poké Ball (`poke_ball`) | 2 | visible | 65,20 | `data/cutscenes/route_9.json` |

#### Route 10

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_10_item_1` | Super Potion (`super_potion`) | 1 | visible | 3,66 | `data/cutscenes/route_10.json` |

#### Centrale

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `power_plant_hidden_1` | Max Élixir (`max_elixir`) | 1 | caché | 18,16 | `data/cutscenes/j32_power_plant.json` |
| `power_plant_hidden_2` | PP Plus (`pp_up`) | 1 | caché | 12,2 | `data/cutscenes/j32_power_plant.json` |
| `power_plant_item_1` | PV Plus (`hp_up`) | 1 | visible | — | `data/cutscenes/j32_power_plant.json` |
| `power_plant_item_2` | Super Bonbon (`rare_candy`) | 1 | visible | — | `data/cutscenes/j32_power_plant.json` |
| `power_plant_item_3` | Carbone (`carbos`) | 1 | visible | — | `data/cutscenes/j32_power_plant.json` |
| `power_plant_item_4` | CT25 — Fatal-Foudre (`tm25`) | 1 | visible | — | `data/cutscenes/j32_power_plant.json` |
| `power_plant_item_5` | CT33 — Protection (`tm33`) | 1 | visible | — | `data/cutscenes/j32_power_plant.json` |

#### Grotte Sombre

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `dark_cave_1f_item_1` | Corde Sortie (`escape_rope`) | 1 | visible | 39,20 | `data/cutscenes/dark_cave.json` |
| `dark_cave_1f_item_2` | Antidote (`antidote`) | 1 | visible | 17,46 | `data/cutscenes/dark_cave.json` |
| `dark_cave_b1f_hidden_1` | Super Potion (`super_potion`) | 1 | caché | 42,32 | `data/cutscenes/dark_cave.json` |
| `dark_cave_b1f_item_1` | Super Potion (`super_potion`) | 1 | visible | 21,18 | `data/cutscenes/dark_cave.json` |

#### Lavanville (Maison Pokémon)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `pokemon_house_flute` | Poké Flûte (`poke_flute`) | 1 | don/récompense | — | `data/cutscenes/j21_tower.json` |

#### Tour Pokémon

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `tower_3f_objet_1` | Corde Sortie (`escape_rope`) | 1 | visible | 12,1 | `data/cutscenes/pokemon_tower_floors.json` |
| `tower_4f_objet_1` | Réveil (`awakening`) | 1 | visible | 9,10 | `data/cutscenes/pokemon_tower_floors.json` |
| `tower_4f_objet_2` | Super Potion (`super_potion`) | 1 | visible | 12,10 | `data/cutscenes/pokemon_tower_floors.json` |
| `tower_5f_cache_1` | Super Potion (`super_potion`) | 1 | caché | — | `data/cutscenes/pokemon_tower_floors.json` |
| `tower_5f_objet_1` | Pépite (`nugget`) | 1 | visible | 6,14 | `data/cutscenes/pokemon_tower_floors.json` |
| `tower_6f_objet_1` | Super Potion (`super_potion`) | 1 | visible | 14,14 | `data/cutscenes/pokemon_tower_floors.json` |

#### Route 8

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_8_hidden_1` | Rappel (`revive`) | 1 | caché | — | `data/cutscenes/route_8.json` |
| `route_8_item_1` | Super Potion (`super_potion`) | 1 | visible | 37,5 | `data/cutscenes/route_8.json` |

#### Souterrain Routes 7-8

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `souterrain_hidden_1` | Pépite (`nugget`) | 1 | caché | — | `data/cutscenes/underground_7_8.json` |
| `souterrain_hidden_2` | Super Potion (`super_potion`) | 1 | caché | — | `data/cutscenes/underground_7_8.json` |

#### Céladopole (Arène)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `celadon_gym_erika` | CT21 — Méga-Sangsue (`tm21`) | 1 | don/récompense | — | `data/cutscenes/celadon_gym.json` |
| `celadon_gym_erika_tm_late` | CT21 — Méga-Sangsue (`tm21`) | 1 | don/récompense | — | `data/cutscenes/celadon_gym.json` |

#### Céladopole (toit du grand magasin)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `celadon_roof_trade` | CT13 — Laser Glace (`tm13`) | 1 | don/récompense | — | `data/cutscenes/celadon_dept.json` |

#### Céladopole (ville)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `celadon_hidden_1` | Rappel (`revive`) | 1 | caché | — | `data/cutscenes/celadon_city_life.json` |

#### Repaire Rocket (Céladopole)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `rocket_hideout_b1f_hidden_1` | Rappel (`revive`) | 1 | caché | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b1f_item_1` | Corde Sortie (`escape_rope`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b1f_item_2` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b2f_item_1` | Pierre Lune (`moon_stone`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b2f_item_2` | Pépite (`nugget`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b2f_item_3` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b2f_item_4` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b3f_hidden_1` | Pépite (`nugget`) | 1 | caché | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b3f_item_1` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b3f_item_2` | Super Bonbon (`rare_candy`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b4f_hidden_1` | Super Potion (`super_potion`) | 1 | caché | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b4f_item_1` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b4f_item_2` | Rappel (`revive`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b4f_item_3` | Super Potion (`super_potion`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b4f_lift_key` | Clé Ascenseur (`lift_key`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |
| `rocket_hideout_b4f_silph_scope` | Scope Sylphe (`silph_scope`) | 1 | visible | — | `data/cutscenes/rocket_hideout.json` |

#### Sylphe SARL

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `silph_co_10f_item_4` | Pépite (`nugget`) | 1 | visible | 2,12 | `data/cutscenes/silph_co_life.json` |
| `silph_co_10f_item_5` | Super Bonbon (`rare_candy`) | 1 | visible | 4,14 | `data/cutscenes/silph_co_life.json` |
| `silph_co_10f_item_6` | Carbone (`carbos`) | 1 | visible | 5,11 | `data/cutscenes/silph_co_life.json` |
| `silph_co_3f_item_4` | Hyper Potion (`hyper_potion`) | 1 | visible | 8,5 | `data/cutscenes/silph_co_life.json` |
| `silph_co_4f_item_5` | Total Soin (`full_heal`) | 1 | visible | 3,9 | `data/cutscenes/silph_co_life.json` |
| `silph_co_4f_item_6` | Rappel Max (`max_revive`) | 1 | visible | 4,7 | `data/cutscenes/silph_co_life.json` |
| `silph_co_4f_item_7` | Corde Sortie (`escape_rope`) | 1 | visible | 5,8 | `data/cutscenes/silph_co_life.json` |
| `silph_co_5f_card_key` | Carte Magnétique (`card_key`) | 1 | visible | 21,16 | `data/cutscenes/silph_co_life.json` |
| `silph_co_5f_hidden_1` | Rappel (`revive`) | 1 | caché | 12,3 | `data/cutscenes/silph_co_life.json` |
| `silph_co_5f_item_6` | CT09 — Bélier (`tm09`) | 1 | visible | 2,13 | `data/cutscenes/silph_co_life.json` |
| `silph_co_5f_item_7` | Super Bonbon (`rare_candy`) | 1 | visible | 4,6 | `data/cutscenes/silph_co_life.json` |
| `silph_co_6f_item_10` | Précision + (`x_accuracy`) | 1 | visible | 2,15 | `data/cutscenes/silph_co_life.json` |
| `silph_co_6f_item_9` | PV Plus (`hp_up`) | 1 | visible | 3,12 | `data/cutscenes/silph_co_life.json` |
| `silph_co_7f_item_10` | Super Bonbon (`rare_candy`) | 1 | visible | 1,9 | `data/cutscenes/silph_co_story.json` |
| `silph_co_7f_item_11` | Pépite (`nugget`) | 1 | visible | 24,11 | `data/cutscenes/silph_co_story.json` |
| `silph_co_9f_hidden_1` | Potion Max (`max_potion`) | 1 | caché | 2,15 | `data/cutscenes/silph_co_life.json` |

#### Sylphe SARL (général)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `silph_co_master_ball` | Master Ball (`master_ball`) | 1 | don/récompense | — | `data/cutscenes/silph_co_story.json` |

#### Safrania (Arène)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `saffron_gym_sabrina` | CT46 — Vague Psy (`tm46`) | 1 | don/récompense | — | `data/cutscenes/saffron_gym.json` |
| `saffron_gym_sabrina_tm_late` | CT46 — Vague Psy (`tm46`) | 1 | don/récompense | — | `data/cutscenes/saffron_gym.json` |

#### Safrania (maison du Copieur)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `saffron_copycat_hidden_1` | Pépite (`nugget`) | 1 | caché | — | `data/cutscenes/saffron_life.json` |

#### Route 12

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_12_hidden_1` | Hyper Potion (`hyper_potion`) | 1 | caché | — | `data/cutscenes/j22_route_12_south.json` |
| `route_12_item_1` | Pépite (`nugget`) | 1 | visible | 14,33 | `data/cutscenes/j22_route_12_south.json` |

#### Route 12 (poste, 2F)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_12_gate_tm39` | CT39 — Météores (`tm39`) | 1 | don/récompense | — | `data/cutscenes/route_12.json` |

#### Route 13

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_13_hidden_1` | Super Bonbon (`rare_candy`) | 1 | caché | — | `data/cutscenes/j22_route_13.json` |
| `route_13_hidden_2` | Hyper Potion (`hyper_potion`) | 1 | caché | — | `data/cutscenes/j22_route_13.json` |

#### Route 15

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_15_item_1` | CT09 — Bélier (`tm09`) | 1 | visible | 11,3 | `data/cutscenes/j22_route_15.json` |

#### Route 16

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_16_hidden_1` | Hyper Potion (`hyper_potion`) | 1 | caché | — | `data/cutscenes/j22_route_16_west.json` |

#### Route 17

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_17_hidden_1` | Super Bonbon (`rare_candy`) | 1 | caché | — | `data/cutscenes/j22_route_17.json` |
| `route_17_hidden_2` | Guérison (`full_restore`) | 1 | caché | — | `data/cutscenes/j22_route_17.json` |
| `route_17_hidden_3` | Pépite (`nugget`) | 1 | caché | — | `data/cutscenes/j22_route_17.json` |
| `route_17_hidden_4` | Guérison (`full_restore`) | 1 | caché | — | `data/cutscenes/j22_route_17.json` |
| `route_17_hidden_5` | Pépite (`nugget`) | 1 | caché | — | `data/cutscenes/j22_route_17.json` |

#### Azuria (magasin de vélos)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j22_bike_exchange` | Bicyclette (`bicycle`) | 1 | don/récompense | — | `data/cutscenes/j22_story.json` |

#### Carmin (Fan-club)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j22_fan_club_voucher` | Bon de Commande (`bike_voucher`) | 1 | don/récompense | — | `data/cutscenes/j22_story.json` |

#### Carmin (maison du pêcheur)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j22_old_rod` | Canne (`old_rod`) | 1 | don/récompense | — | `data/cutscenes/j22_story.json` |

#### Parmanie (maison de la Super Canne)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j22_good_rod` | Super Canne (`good_rod`) | 1 | don/récompense | — | `data/cutscenes/j22_story.json` |

#### Route 12 (maison de la Méga Canne)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j22_super_rod` | Méga Canne (`super_rod`) | 1 | don/récompense | — | `data/cutscenes/j22_story.json` |

#### Route 16 (maison du Vol)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j22_hm02` | CS02 — Vol (`hm02`) | 1 | don/récompense | — | `data/cutscenes/j22_story.json` |

#### Parmanie (Arène)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `fuchsia_gym_koga` | CT06 — Toxik (`tm06`) | 1 | don/récompense | — | `data/cutscenes/j23_fuchsia_gym.json` |
| `fuchsia_gym_koga_tm_late` | CT06 — Toxik (`tm06`) | 1 | don/récompense | — | `data/cutscenes/j23_fuchsia_gym.json` |

#### Parc Safari (centre)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `safari_zone_center_pepite` | Pépite (`nugget`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_center.json` |

#### Parc Safari (est)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `safari_zone_east_carbone` | Super Bonbon (`rare_candy`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_east.json` |
| `safari_zone_east_ct37` | CT37 — Bomb'Œuf (`tm37`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_east.json` |
| `safari_zone_east_guerison` | Guérison (`full_restore`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_east.json` |
| `safari_zone_east_potion_max` | Hyper Potion (`hyper_potion`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_east.json` |

#### Parc Safari (maison secrète)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j23_secret_house_hm03` | CS03 — Surf (`hm03`) | 1 | don/récompense | — | `data/cutscenes/j23_safari_zone_secret_house.json` |

#### Parc Safari (nord)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `safari_zone_north_ct40` | CT40 — Coud'Krâne (`tm40`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_north.json` |
| `safari_zone_north_proteine` | Rappel (`revive`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_north.json` |

#### Parc Safari (ouest)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `safari_zone_west_ct32` | CT32 — Reflet (`tm32`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_west.json` |
| `safari_zone_west_dents_or` | Dents d'Or (`gold_teeth`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_west.json` |
| `safari_zone_west_potion_max` | Hyper Potion (`hyper_potion`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_west.json` |
| `safari_zone_west_rappel_cache` | Rappel (`revive`) | 1 | caché | — | `data/cutscenes/j23_safari_zone_west.json` |
| `safari_zone_west_rappel_max` | Rappel (`revive`) | 1 | visible | — | `data/cutscenes/j23_safari_zone_west.json` |

#### Parmanie (maison du Gardien)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `j23_warden_hm04` | CS04 — Force (`hm04`) | 1 | don/récompense | — | `data/cutscenes/j23_wardens_house.json` |
| `j23_warden_teeth` | CS04 — Force (`hm04`) | 1 | don/récompense | — | `data/cutscenes/j23_wardens_house.json` |
| `wardens_house_super_bonbon` | Super Bonbon (`rare_candy`) | 1 | visible | — | `data/cutscenes/j23_wardens_house.json` |

#### Îles Écume

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `seafoam_b2f_hidden_1` | Pépite (`nugget`) | 1 | caché | — | `data/cutscenes/seafoam.json` |
| `seafoam_b4f_hidden_1` | Hyper Ball (`ultra_ball`) | 1 | caché | — | `data/cutscenes/seafoam.json` |

#### Route 20

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_20_item_1` | Super Ball (`great_ball`) | 3 | visible | — | `data/cutscenes/route_20.json` |

#### Route 21

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_21_item_1` | Hyper Potion (`hyper_potion`) | 1 | visible | — | `data/cutscenes/route_21.json` |

#### Cramois'Île (Arène)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `cinnabar_gym_blaine` | CT38 — Déflagration (`tm38`) | 1 | don/récompense | — | `data/cutscenes/cinnabar_gym.json` |

#### Cramois'Île (Labo)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `cinnabar_lab_tm35` | CT35 — Métronome (`tm35`) | 1 | don/récompense | — | `data/cutscenes/cinnabar_lab_rd.json` |
| `j32_fossil_give_dome` | Fossile Dôme (`dome_fossil`) | 1 | don/récompense | — | `data/cutscenes/j32_collection.json` |
| `j32_fossil_give_helix` | Fossile Nautile (`helix_fossil`) | 1 | don/récompense | — | `data/cutscenes/j32_collection.json` |

#### Grotte Azurée

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `cerulean_cave_1f_hidden_1` | Super Bonbon (`rare_candy`) | 1 | caché | 14,12 | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_1f_item_1` | Guérison (`full_restore`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_1f_item_2` | Max Élixir (`max_elixir`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_1f_item_3` | Pépite (`nugget`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_2f_item_1` | PP Plus (`pp_up`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_2f_item_2` | Hyper Ball (`ultra_ball`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_2f_item_3` | Guérison (`full_restore`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_b1f_hidden_1` | Hyper Ball (`ultra_ball`) | 1 | caché | 27,4 | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_b1f_item_1` | Hyper Ball (`ultra_ball`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |
| `cerulean_cave_b1f_item_2` | Rappel Max (`max_revive`) | 1 | visible | — | `data/cutscenes/cerulean_cave.json` |

#### Route 23

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `route_23_hidden_1` | Guérison (`full_restore`) | 1 | caché | — | `data/cutscenes/j29.json` |
| `route_23_hidden_2` | Hyper Ball (`ultra_ball`) | 1 | caché | — | `data/cutscenes/j29.json` |
| `route_23_hidden_3` | Potion Max (`max_potion`) | 1 | caché | — | `data/cutscenes/j29.json` |

#### Route Victoire 1F

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `victory_road_1f_item_1` | CT43 — Piqué (`tm43`) | 1 | visible | — | `data/cutscenes/j29.json` |
| `victory_road_1f_item_2` | Super Bonbon (`rare_candy`) | 1 | visible | — | `data/cutscenes/j29.json` |

#### Route Victoire 2F

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `victory_road_2f_hidden_1` | Hyper Ball (`ultra_ball`) | 1 | caché | — | `data/cutscenes/j29.json` |
| `victory_road_2f_hidden_2` | Guérison (`full_restore`) | 1 | caché | — | `data/cutscenes/j29.json` |
| `victory_road_2f_item_1` | CT17 — Sacrifice (`tm17`) | 1 | visible | — | `data/cutscenes/j29.json` |
| `victory_road_2f_item_2` | Total Soin (`full_heal`) | 1 | visible | — | `data/cutscenes/j29.json` |
| `victory_road_2f_item_3` | CT05 — Ultimawashi (`tm05`) | 1 | visible | — | `data/cutscenes/j29.json` |
| `victory_road_2f_item_4` | Super Bonbon (`rare_candy`) | 1 | visible | — | `data/cutscenes/j29.json` |

#### Route Victoire 3F

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `victory_road_3f_item_1` | Rappel Max (`max_revive`) | 1 | visible | — | `data/cutscenes/j29.json` |
| `victory_road_3f_item_2` | CT47 — Explosion (`tm47`) | 1 | visible | — | `data/cutscenes/j29.json` |

#### Manoir Pokémon (Cramois'Île)

| id (cutscène) | objet | qté | nature | case | source |
|---|---|---|---|---|---|
| `pokemon_mansion_1f_hidden_1` | Pierre Lune (`moon_stone`) | 1 | caché | 8,16 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_1f_item_1` | Corde Sortie (`escape_rope`) | 1 | visible | 14,3 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_1f_item_2` | Pépite (`nugget`) | 1 | visible | 18,21 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_2f_item_1` | Super Bonbon (`rare_candy`) | 1 | visible | 28,7 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_3f_hidden_1` | Rappel Max (`max_revive`) | 1 | caché | 1,9 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_3f_item_1` | Potion Max (`max_potion`) | 1 | visible | 1,16 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_3f_item_2` | Pépite (`nugget`) | 1 | visible | 25,5 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_b1f_hidden_1` | Super Bonbon (`rare_candy`) | 1 | caché | 1,9 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_b1f_item_1` | Super Bonbon (`rare_candy`) | 1 | visible | 10,2 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_b1f_item_2` | Guérison (`full_restore`) | 1 | visible | 1,22 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_b1f_item_3` | CT14 — Blizzard (`tm14`) | 1 | visible | 19,25 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_b1f_item_4` | CT22 — Lance-Soleil (`tm22`) | 1 | visible | 5,4 | `data/cutscenes/pokemon_mansion.json` |
| `pokemon_mansion_b1f_item_5` | Clé Secrète (`secret_key`) | 1 | visible | 5,13 | `data/cutscenes/pokemon_mansion.json` |

### 2.1 Boutiques (`data/shops/*.json`)

| Boutique | Stock du jeu | Rouge/Bleu (à vérifier) | Écart |
|---|---|---|---|
| Jadielle | Poké Ball, Potion, Antidote, Anti-Para, Réveil, Anti-Brûle | Poké Ball, Antidote, Anti-Para, Réveil, Anti-Brûle (pas de Potion) | Potion en plus (P3) |
| Argenta | Poké Ball, Potion, Antidote, Anti-Para, Réveil, Anti-Brûle, Corde Sortie | idem | conforme |
| Azuria | Poké Ball, Potion, Antidote, Anti-Para, Réveil, Antigel, Anti-Brûle, Corde Sortie | + Repousse (D-13 : reporté) | Repousse (P1, AUD-14), Antigel/Corde en plus (P3) |
| Carmin | Poké Ball, Potion, Super Potion, soins de statut, Antigel, Corde Sortie | Poké Ball, Super Potion, Antigel, Réveil, Anti-Para, Repousse | Repousse (AUD-14) |
| Lavanville | Poké Ball, Potion, Super Potion, soins, Corde Sortie | Super Ball, Super Potion, Rappel, Corde Sortie, Super Repousse, soins | Super Ball / Rappel / Super Repousse absents (AUD-14, AUD-26) |
| Céladopole 2F | Super Ball, Super Potion, Rappel, soins de statut | idem + Super Repousse | AUD-14 |
| Céladopole 2F (CT) | **CT01** seule | 9 CT : 01, 02, 05, 07, 09, 17, 32, 33, 37 (liste RB du dossier 23 §H-7 : Ultimapoing, Ultimawashi, Bélier, Sacrifice, Reflet, Protection, Coupe-Vent, Empal'Korne, Bombe-Œuf ; le dossier ne retient que les CT dont la capacité existe) | AUD-22 |
| Céladopole 4F | Poupée Poké, 4 pierres (2 100 ₽) | idem | conforme |
| Céladopole 5F | Attaque +, Défense +, Vitesse +, Spécial +, Précision +, Muscle + | Précision +, **Défense Spéc.**, Muscle +, Attaque +/Défense +/Vitesse +/Spécial + | Défense Spéc. (`guard_spec`) non vendue (AUD-21) |
| Toit | Eau Fraîche, Soda Cool, Limonade | idem | conforme |
| Safrania | Super Ball, Corde Sortie, Rappel | Super Ball, Hyper Potion, Max Repousse, Corde Sortie, Total Soin, Rappel | Hyper Potion, Total Soin, Max Repousse (AUD-14, AUD-26) |
| Parmanie | Hyper Ball, Super Ball, Super Potion, Rappel, Total Soin | + Max Repousse | AUD-14 |
| Cramois'Île | Hyper Ball, Super Ball, Hyper Potion, Corde Sortie, Total Soin, Rappel | + Max Repousse | AUD-14 |
| Plateau Indigo | Hyper Ball, Super Ball, Guérison, Potion Max, Total Soin, Rappel | + Max Repousse | AUD-14 |

### 2.2 Échanges PNJ (9 sur 9 de RB, à vérifier)

| Échange | Donne → reçoit | Lieu dans le jeu | Lieu RB (à vérifier) | Source |
|---|---|---|---|---|
| Rémi | Abra → M. Mime (Marcel) | poste est de la Route 2 (`route_2_east_gate`) | maison d'échange de la Route 2 | `data/trades/rb_trades.json`, `data/npcs/route_2_east_gate.json` |
| Léon | Piafabec → Canarticho (Dux) | Carmin, maison 2 | Carmin | idem, `data/npcs/vermilion_house_2.json` |
| Aline | Flagadoss → Excelangue (Marc) | poste de la Route 18 | Route 18 | `data/npcs/route_18_gate.json` |
| Hugo | Nidoran ♂ → ♀ (Spot) | entrée du souterrain Route 5 | idem | `data/npcs/route_5_underground_gate.json` |
| Théo | Nidorino → Nidorina (Terry) | 2F du poste de la Route 12 | poste de la Route 11 | `data/npcs/route_12_gate_2f.json` [D] |
| Coline | Têtarte → Lippoutou (Lola) | Azuria, maison | Azuria | `data/npcs/cerulean_house.json` |
| Cramois'Île ×3 | voir ci-dessous | Labo de Cramois'Île (`cinnabar_lab_meeting`) | idem | `data/trades/cinnabar.json` |

Labo de Cramois'Île : `cinnabar_trade_electrode` (Raichu → Électrode, Kourjus), `cinnabar_trade_tangela` (Mimitoss → Saquedeneu, Bigoudi), `cinnabar_trade_seel` (Ponyta → Otaria, Bibi), conformes à RB. Les 6 autres viennent du lot 32I (surnoms d'après l'anglais de RB, textes [D] à valider).

### 2.3 Pêche

| Canne | Obtention | Table (`data/fishing/water_rod.json`) | RB (à vérifier) |
|---|---|---|---|
| Canne (`old_rod`) | Carmin, maison du pêcheur (`j22_old_rod`) | Magicarpe N5 partout (taux 100) | Magicarpe N5 ✓ |
| Super Canne (`good_rod`) | Parmanie, maison de la Canne (`j22_good_rod`) | Poissirène N10, Ptitard N10 (taux 50) partout | Poissirène/Ptitard N10 ✓ |
| Méga Canne (`super_rod`) | Route 12, maison de la Canne (`j22_super_rod`) | Défaut : Tentacool N5, Krabby N15, Poissirène N15, Magicarpe N15 ; Parmanie : + Poissoroy N23 ; Grotte Azurée : Flagadoss/Poissoroy/Krabboss/Hypocéan N23 ; Safari : Minidraco/Krabby/Psykokwak/Ramoloss N15 | tables par zone dans RB (à vérifier : Hypotrempe/Stari/Kokiyas sont pêchables par endroits) |

Cases d'eau pêchables avant le J22 : `data/world/fishable.json` (Carmin, Azuria, Routes 6, 11, 24, 25) ; les cartes du J22 marquent leurs cases `f`. Aucun drapeau de pêche n'est consommé (T8). La table de Super Canne est **unique** hors 3 lieux : écart de design connu (AUD-30).

### 2.4 Parc Safari

Entrée 500 ₽, 30 balls, 500 pas, bonus ×2 (conforme à RB). Objets (cf. tableaux « Parc Safari ») : centre Pépite, est Guérison/Hyper Potion/Super Bonbon/CT37, nord Rappel/CT40, ouest Hyper Potion/CT32/Rappel/Rappel caché/Dents d'Or, maison secrète CS03 ; remplacements validés par N-19 (Potion Max → Hyper Potion, Rappel Max → Rappel, Carbone → Super Bonbon, Protéine → Rappel). Gardien : Dents d'Or → CS04.

### 2.5 Dons de Pokémon (rappel, hors objets)

Évoli (toit de Céladopole + deux copies post-Ligue), Lokhlass (Sylphe SARL), Kicklee ou Tygnon (Dojo, choix unique + post-Ligue), Porygon (Sylphe, après Giovanni), fossiles ressuscités au Labo, Bulbizarre/Salamèche/Carapuce (Chen, post-Ligue), 3 starters. Le détail relève de la matrice T1 (`jalon-32-matrice.md`).

## 3. Comparaison avec Rouge/Bleu (version française)

### 3.1 CT 01–50 : où chacune s'obtient

Moves = capacité présente dans `data/pokemon/moves/*.json` ; objet = l'objet `tmNN` existe dans `data/items/` ; origine RB = lieu de Rouge/Bleu connu par les commentaires des grilles/dossiers, sinon « à vérifier ».

| CT | Capacité | Dans le jeu | Statut | Origine RB |
|---|---|---|---|---|
| 01 | Ultimapoing | Mont Sélénite B2F ; boutique Céladopole 2F | obtenable | Mt Moon (confirmé par la grille), boutique |
| 02 | Coupe-Vent (RB) | — | **capacité absente** (`razor_wind`) | Repaire B4F (grille `repaire_b4f.txt:87`) ; boutique |
| 03 | Danse-Lames | — (Sylphe 7F : Pépite) | **manquante** (objet absent) | Sylphe 7F (`sylphe_7f.txt:133`) |
| 04 | Cyclone | — | manquante | à vérifier |
| 05 | Ultimawashi | Route Victoire 2F | obtenable | Route Victoire |
| 06 | Toxik | Arène de Parmanie (Koga) | obtenable | Koga |
| 07 | Empal'Korne | — (Repaire B2F : Super Potion) | **manquante** (objet absent) | Repaire B2F (`repaire_b2f.txt:88`) ; boutique |
| 08 | Plaquage | — | manquante | à vérifier |
| 09 | Bélier | Route 15 ; Sylphe 5F (**doublon**) | obtenable | Sylphe 5F |
| 10 | Damoclès | — (Repaire B3F : Super Potion) | **manquante** (objet absent) | Repaire B3F (`repaire_b3f.txt:81`) |
| 11 | Bulles d'O | Arène d'Azuria (Ondine) | obtenable | Ondine |
| 12 | Pistolet à O | — | manquante | à vérifier |
| 13 | Laser Glace | toit du grand magasin (Eau Fraîche) | obtenable | toit (dossier 23) |
| 14 | Blizzard | Manoir B1F | obtenable | Manoir (RB : à vérifier) |
| 15 | Ultralaser | — | manquante | à vérifier (probablement Coin à lots) |
| 16 | Jackpot | — | manquante | à vérifier |
| 17 | Sacrifice | Route Victoire 2F | obtenable | Route Victoire |
| 18 | Riposte | — | **manquante** (la capacité existe) | grand magasin 3F (dossier 23 : PNJ prévu, « ne donne rien ») |
| 19 | Frappe Atlas | Route 25 | obtenable | Route 25 |
| 20 | Frénésie | — (Route 15 donne CT09 à la place) | **manquante** (objet absent) | Route 15 (`route_15.txt:92`) |
| 21 | Méga-Sangsue | Arène de Céladopole (Erika) | obtenable | Erika |
| 22 | Lance-Soleil | Manoir B1F | obtenable | Manoir (RB : à vérifier) |
| 23 | Draco-Rage | — | manquante | à vérifier (Coin à lots) |
| 24 | Tonnerre | Arène de Carmin (Major Bob) | obtenable | Major Bob |
| 25 | Fatal-Foudre | Centrale | obtenable | Centrale |
| 26 | Séisme | — (Sylphe 10F : Pépite) | **manquante** (objet absent) | Sylphe 10F (`sylphe_10f.txt:98`) |
| 27 | Abîme | Arène de Jadielle (Giovanni) | obtenable | Giovanni |
| 28 | Tunnel | Azuria, maison cambriolée | obtenable | Rocket d'Azuria |
| 29 | Psyko | — | manquante | à vérifier (Safrania, maison du télépathe, de mémoire) |
| 30 | Téléport | — | manquante | à vérifier |
| 31 | Copie (RB) | — | **capacité absente** (`mimic`) | à vérifier (la Copieuse de Safrania, de mémoire) |
| 32 | Reflet | Parc Safari ouest | obtenable | Safari ; boutique |
| 33 | Protection | Centrale | obtenable | boutique |
| 34 | Patience | Arène d'Argenta (Pierre) | obtenable | Pierre |
| 35 | Métronome | Labo de Cramois'Île | obtenable | Labo |
| 36 | Destruction | — | manquante | à vérifier |
| 37 | Bomb'Œuf | Parc Safari est | obtenable | Safari ; boutique |
| 38 | Déflagration | Arène de Cramois'Île (Auguste) | obtenable | Auguste |
| 39 | Météores | poste de la Route 12 (2F) | obtenable | à vérifier |
| 40 | Coud'Krâne | Parc Safari nord | obtenable | Safari |
| 41 | Soin (RB) | — | **capacité absente** (`soft_boiled`) | à vérifier |
| 42 | Dévorêve | — | manquante | à vérifier |
| 43 | Piqué | Route Victoire 1F | obtenable | Route Victoire |
| 44 | Repos | — | manquante | à vérifier |
| 45 | Cage-Éclair | — | manquante | à vérifier |
| 46 | Vague Psy | Arène de Safrania (Morgane) | obtenable | Morgane |
| 47 | Explosion | Route Victoire 3F | obtenable | Route Victoire |
| 48 | Éboulement (RB) | — | **capacité absente** (`rock_slide`) | toit (soda) |
| 49 | Triplattaque | — | **manquante** (la capacité existe) | toit (limonade) |
| 50 | Clonage | — | manquante | à vérifier (Coin à lots) |

Noms de capacités lus dans `data/pokemon/moves/` (numéros → capacités : `data/pokemon/tm_compatibility.json`) ; pour les 4 capacités absentes, le nom français de RB est donné avec « (RB) ».

### 3.2 CS 01–05

| CS | Capacité | Où | Statut |
|---|---|---|---|
| 01 | Coupe | capitaine, S.S. Anne | obtenable |
| 02 | Vol | maison du Vol, Route 16 (`j22_hm02`) | obtenable |
| 03 | Surf | maison secrète, Parc Safari | obtenable |
| 04 | Force | Gardien de Parmanie, contre les Dents d'Or | obtenable |
| 05 | Flash | assistant de Chen, Route 2 est | obtenable (seuil d'espèces RB : à vérifier) |

### 3.3 Pierres, fossiles, objets clés

| Élément | Dans le jeu | RB | Verdict |
|---|---|---|---|
| Pierre Feu / Eau / Foudre / Plante | boutique Céladopole 4F, 2 100 ₽ | idem | conforme |
| Pierre Lune | 5 ramassages : Mont Sélénite B1F, B2F (cachée), Manoir 1F (cachée), Repaire B2F, Route 2 est | RB : Mt Moon, Route 2 est… (à vérifier) | 5 pour 4 évolutions (Nidorina, Nidorino, Mélofée, Rondoudou) : marge de 1 (AUD-27) |
| Fossiles | choix unique au Mont Sélénite ; autre fossile post-Ligue ; Vieil Ambre au Musée | RB : un seul fossile | conforme + post-game |
| Passe Bateau | maison de Léo/Bill, Route 25 | idem | conforme (+ Super Bonbon en plus, AUD-35) |
| Colis pour Chen | Boutique de Jadielle | idem | conforme |
| Poké Flûte | Maison Pokémon, Lavanville (`pokemon_house_flute`) | M. Fuji | conforme |
| Scope Sylphe | Repaire B4F (`rocket_hideout_b4f_silph_scope`) | Giovanni, Repaire | conforme |
| Carte Magnétique | Sylphe 5F | idem | conforme |
| Clé Ascenseur | Repaire B4F | idem | conforme |
| Clé Secrète | Manoir B1F | idem | conforme |
| Dents d'Or | Safari ouest | idem | conforme |
| Bon de Commande / Bicyclette | Fan-club de Carmin / magasin de vélos d'Azuria | idem | conforme |
| Cannes (3) | Carmin, Parmanie, Route 12 | idem | conforme |
| Master Ball | Sylphe SARL | idem | conforme |
| Cherch'Objet (Route 11) | — | assistant de Chen, 30 espèces | **absent** (AUD-15) |
| Multi Exp (Route 15) | — | assistant de Chen, 50 espèces | **absent** (AUD-16) |
| Carte de la ville | — | sœur du rival | absente (menu « Carte » existant : AUD-31) |
| Boîte à Jetons | — | Céladopole | absente (Casino narratif) (AUD-17) |

### 3.4 Objets de Rouge/Bleu absents du catalogue

| Objet RB | Dans le jeu | Remplacé par (validé) |
|---|---|---|
| Repousse / Super Repousse / Max Repousse | absents | reporté (dossiers 15, 16, 21, 23) ; Route 21 : le Max Repousse de la grille n'est pas placé |
| Éther | absent | — |
| Max Éther | défini, **jamais obtenu** | grille Écume B3F prévue, non placée |
| Élixir | absent | Rappel (Sylphe 5F caché), Super Potion (Tour 4F) |
| Protéine / Fer / Calcium | absents | Super Bonbon / Pépite / Super Bonbon (M-16, N-19) |
| PV Plus, Carbone | définis et ramassés, **inertes** | AUD-20 |
| PP Plus, Max Élixir | définis et ramassés, **inertes** | AUD-20 |
| Défense Spéc. | définie, **ni vendue ni ramassée** | AUD-21 |
| Cherch'Objet, Multi Exp, Boîte à Jetons | absents | voir 3.3 |

### 3.5 Objets au sol : écarts de composition RB

Le jeu a son propre plan de placement par carte (conception J12-J32) ; il n'a pas été recopié ligne à ligne sur RB. Les substitutions volontaires relevées dans les commentaires des grilles sont dans le registre. Constats globaux (RB : à vérifier) : **17 Super Bonbons** ramassables (RB en a nettement moins), **16 Pépites** (RB en a une dizaine), 7 Hyper Potions, 23 Super Potions (surpeuplement dû aux remplacements « objet absent → Super Potion/Pépite/Super Bonbon »).


## 4. Vitamines et objets « sans effet dans le moteur actuel »

Constat (lecture du code et des données) :

- `hp_up` (PV Plus) et `carbos` (Carbone) sont déclarés `"category": "field"`, `"price": 0`, `"draft": true`, **sans `field_use`** (`data/items/items_j32.json:2` et `:11`). `ItemData.contexts()` renvoie alors une liste vide pour un objet AVENTURE sans `field_use` (`game/items/item_data.gd:127-140`) : **aucun bouton UTILISER**, l'objet reste dans le Sac.
- Les EV existent dans le modèle : `Pokemon.evs` (`game/pokemon/pokemon.gd:43`), lus par `StatCalc.value` (`game/pokemon/stat_calc.gd:27`, `ev / 4`) et sauvegardés (`pokemon.gd:238`, `:269`), mais **initialisés à 0** (`game/pokemon/pokemon_factory.gd:24`) et **jamais incrémentés** : aucun gain d'EV au combat, aucun usage d'objet. Une vitamine n'a donc aujourd'hui nulle part où écrire.
- Même statut « sans effet » pour `pp_up`, `max_elixir` (`items_j31.json:2`, `:10`), `max_ether`, `guard_spec` (`items_j29.json:38`, `:46`). Les PP maximum (`MoveSlot.max_pp`, `game/pokemon/move_slot.gd:7`) n'ont pas de notion de PP Plus.
- Obtention des quatre vitamines/PP déjà placées : PV Plus (Centrale, Sylphe 6F), Carbone (Centrale, Sylphe 10F), PP Plus (Grotte Azurée 2F, Centrale caché), Max Élixir (Grotte Azurée 1F, Centrale caché). Le joueur les ramasse, mais elles n'ont aucun effet.
- Décisions antérieures : « les vitamines ne sont pas conçues » (`docs/design/dossier-20-chemins-retrouves.md:274`, `dossier-23-celadopole.md:36` H-8 « pas de vitamines », `dossier-25-deux-chemins-parmanie.md:54` M-16 : objets sans mécanique remplacés). Les objets du J29/J31/J32 sont arrivés après et sont des ajouts « draft » pour tenir la matrice RB.

**Classement** : P2 (AUD-20) — objet de RB obtenable mais inerte ; ne bloque ni la progression ni le Pokédex ; la surface réelle est une promesse non tenue au joueur (« ramassé = inutile »). Proposition : soit (a) un mini-système (`field_use: "vitamin"` qui écrit dans `Pokemon.evs`, plafond et pas à fixer par Kevin : RB utilise l'expérience de statistique de la 1re génération, pas les EV de la 3e ; + gain d'EV au combat seulement si Kevin veut le système complet), soit (b) retirer ces 4 types des cartes et les remplacer par des objets existants.


## 5. Registre des écarts

Priorités : **P0** bloque la progression ou la complétion du Pokédex · **P1** objet ou CT de RB inobtenable · **P2** emplacement/quantité différent de RB ou objet inerte · **P3** cosmétique. Aucune correction n'est faite ici. « À vérifier » = l'origine RB n'est pas confirmée par un commentaire du dépôt.

### P0

Aucun. Vérifié à la lecture : les 5 CS, les 8 CT d'Arène, les objets clés de progression, les 5 pierres, les 3 fossiles, les 3 cannes, la Poké Flûte (2 Ronflex) et le Scope Sylphe sont tous obtenables ; la matrice T1 (147/151 + 4 par échange local) ne dépend d'aucun objet manquant. Réserve : l'accessibilité en jeu de chaque ramassage (portes, drapeaux) n'a pas été rejouée, seulement la présence des données.

### P1 — objet ou CT de RB inobtenable

| Id | Prio | Carte | Constat | Source | Proposition |
|---|---|---|---|---|---|
| AUD-01 | P1 | Sylphe SARL 7F | CT03 Danse-Lames absente : l'objet `tm03` n'existe pas, le ramassage de la grille (`item=tm03 fallback=nugget`) donne une Pépite ; la capacité existe | `tools/plans/sylphe_7f.txt:133`, `data/cutscenes/silph_co_story.json:85` | Créer `tm03` (données) et remplacer le `give` de `silph_co_7f_item_11` |
| AUD-02 | P1 | Repaire Rocket B2F | CT07 Empal'Korne absente (RB : ramassage + boutique de Céladopole) : repli Super Potion ; capacité présente | `tools/plans/repaire_b2f.txt:88`, `data/cutscenes/rocket_hideout.json:353` | Créer `tm07` ; l'ajouter aussi à la boutique CT (AUD-22) |
| AUD-03 | P1 | Repaire Rocket B3F | CT10 Damoclès absente : repli Super Potion ; capacité présente | `tools/plans/repaire_b3f.txt:81`, `data/cutscenes/rocket_hideout.json:377` | Créer `tm10` et remplacer le `give` de `rocket_hideout_b3f_item_1` |
| AUD-04 | P1 | Route 15 | CT20 Frénésie absente : la grille prévoit `tm20`, la cutscène donne **CT09** (doublon de Sylphe 5F) ; capacité `rage` présente | `tools/plans/route_15.txt:92`, `data/cutscenes/j22_route_15.json:13` | Créer `tm20`, donner CT20 à la Route 15 |
| AUD-05 | P1 | Sylphe SARL 10F | CT26 Séisme absente : repli Pépite ; capacité présente | `tools/plans/sylphe_10f.txt:98`, `data/cutscenes/silph_co_life.json:263` | Créer `tm26` |
| AUD-06 | P1 | Céladopole, grand magasin 3F | CT18 Riposte : le PNJ prévu au dossier 23 (H-7) n'existe pas ; la capacité `counter` existe | `docs/design/dossier-23-celadopole.md:311`, `data/cutscenes/celadon_dept.json` (absent) | Poser le PNJ du 3e étage et créer `tm18` |
| AUD-07 | P1 | Céladopole, toit | CT49 Triplattaque : la fillette refuse la Limonade (« trop sucré »), alors que `tri_attack` existe (dossier 23 : « seulement si la capacité existe ») | `data/dialogues/celadon_dept.json:173-184`, `data/cutscenes/celadon_dept.json` | Créer `tm49` et brancher l'échange Limonade → CT49 |
| AUD-08 | P1 | Hors cartes (RB : à vérifier) | 9 CT dont la capacité existe n'ont **aucun** emplacement : CT04 Cyclone, CT08 Plaquage, CT12 Pistolet à O, CT29 Psyko, CT30 Téléport, CT36 Destruction, CT42 Dévorêve, CT44 Repos, CT45 Cage-Éclair ; aucun objet `tmNN` n'existe | `data/pokemon/tm_compatibility.json` (`tms`), `data/items/*.json` | Relever l'origine RB de chacune (à vérifier) et créer objet + emplacement, par lots ; CT29 Psyko et CT44 Repos d'abord (usage compétitif) |
| AUD-09 | P1 | Céladopole (Coin à lots) | CT15 Ultralaser, CT23 Draco-Rage, CT50 Clonage (RB : à vérifier, vraisemblablement prix du Casino) inobtenables : le Casino est narratif, sans jeton ni échange de prix | `data/dialogues/game_corner.json`, `docs/design/dossier-23-celadopole.md:167` | Décision de Kevin : les donner ailleurs (récompense, boutique) ou les écarter |
| AUD-10 | P1 | Hors cartes | 4 CT sans capacité dans le jeu : CT02 Coupe-Vent, CT31 Copie, CT41 Soin, CT48 Éboulement (`razor_wind`, `mimic`, `soft_boiled`, `rock_slide` absentes) | `data/pokemon/tm_compatibility.json` (`tms`), `data/pokemon/moves/*.json` | Décision de Kevin : créer les capacités (Copie, Soin : nouvelle mécanique) ou écarter ces 4 CT |
| AUD-11 | P1 | Sylphe 5F / 7F, Manoir 1F/3F, Repaire B4F | Protéine, Fer, Calcium absents du catalogue : remplacés par Super Bonbon, Pépite, Super Bonbon (Fer → Super Potion au Repaire B4F) | `tools/plans/sylphe_5f.txt:126`, `sylphe_7f.txt:132`, `repaire_b4f.txt:89`, `manoir_1f.txt:64`, `manoir_3f.txt:56` | Substitution déjà validée (M-16/N-19) : confirmer, ou créer les vitamines avec AUD-20 |
| AUD-12 | P1 | Sylphe 5F (caché) ; Tour Pokémon 4F | Élixir et Éther absents du catalogue : Élixir → Rappel (Sylphe 5F caché) et Super Potion (Tour 4F, K-17) | `tools/plans/sylphe_5f.txt:131`, `pokemon_tower_4f.txt:69` | Confirmer la substitution, ou créer Élixir/Éther |
| AUD-13 | P1 | Îles Écume B3F | Objet caché **Max Éther** (RB) prévu par la grille mais **non placé** : aucune cutscène `seafoam_b3f_*`, et `max_ether` est défini sans jamais être obtenu | `tools/plans/seafoam_b3f.txt:68`, `data/cutscenes/seafoam.json` (clés `seafoam_b2f_hidden_1`, `seafoam_b4f_hidden_1` seulement), `data/items/items_j29.json:46` | Ajouter `seafoam_b3f_hidden_1` (Max Éther ou un repli) |
| AUD-14 | P1 | Partout | Repousse, Super Repousse, Max Repousse absentes (aucun objet, aucune boutique, aucun ramassage) | dossiers 15 (B-4), 16 (D-13), 21 (I-20), 23 : « reporté » | Décision de Kevin : créer le système (compteur de pas, déjà utile au Safari) ou assumer l'écart |
| AUD-15 | P1 | Route 11 (poste) | Cherch'Objet (assistant de Chen, 30 espèces) absent | `docs/design/dossier-20-chemins-retrouves.md:88` | Reporté depuis le J17 : à trancher |
| AUD-16 | P1 | Route 15 (poste) | Multi Exp (assistant de Chen, 50 espèces) absent | `docs/design/dossier-25-deux-chemins-parmanie.md:84` | Reporté : à trancher |
| AUD-17 | P1 | Céladopole | Boîte à Jetons absente (Casino narratif sans jeu d'argent, Coin à lots et Boîte Jetons retirés, décision H-6 du J20) | `docs/design/dossier-23-celadopole.md:30` | Écart assumé ; lier à AUD-09 |

### P2 — emplacement, quantité ou objet inerte

| Id | Prio | Carte | Constat | Source | Proposition |
|---|---|---|---|---|---|
| AUD-18 | P2 | Route 21 | Max Repousse de la prairie (grille) non placé ; seul l'Hyper Potion de l'îlot sud existe | `tools/plans/route_21.txt:179`, `data/cutscenes/route_21.json` | Placer un repli (Hyper Potion) tant que la Repousse n'existe pas |
| AUD-19 | P2 | Repaire Rocket B1F, B4F | Replis restés en place alors que les objets existent désormais : Hyper Potion → Super Potion (B1F), PP Plus caché → Rappel (B1F), PV Plus → Rappel (B4F) | `tools/plans/repaire_b1f.txt:92-93`, `repaire_b4f.txt:88`, `data/cutscenes/rocket_hideout.json:236`, `:260`, `:470` | Remettre `hyper_potion` (existe depuis le J22) ; PP Plus/PV Plus selon AUD-20 |
| AUD-20 | P2 | Centrale, Sylphe 6F/10F, Grotte Azurée, Écume | **Vitamines sans effet** : PV Plus (×2) et Carbone (×2) ramassés mais inertes ; PP Plus (×2), Max Élixir (×2) idem ; aucun EV n'est jamais écrit (voir §4) | `data/items/items_j32.json:2`, `:11`, `data/items/items_j31.json:2`, `:10`, `game/pokemon/pokemon_factory.gd:24`, `game/items/item_data.gd:127-140` | Soit un mini-système d'EV/PP (choix de Kevin), soit retrait de ces objets des cartes |
| AUD-21 | P2 | Céladopole 5F | Défense Spéc. (`guard_spec`) définie mais ni vendue ni ramassée, et sans effet dans le moteur ; RB la vend au 5F | `data/items/items_j29.json:38`, `data/shops/celadon_dept.json` (`celadon_dept_5f`) | Ajouter au stock si l'effet est implémenté, sinon laisser |
| AUD-22 | P2 | Céladopole 2F (CT) | Seule CT01 est en vente ; les objets `tm05`, `tm09`, `tm17`, `tm32`, `tm33`, `tm37` existent et sont dans la liste RB (+ CT02 impossible, CT07 manquante) | `data/shops/celadon_dept.json:14-18`, `docs/design/dossier-23-celadopole.md:310` | Compléter le stock avec les CT existantes (obtenues ailleurs : pas de risque d'inflation majeur) |
| AUD-23 | P2 | Parc Safari | 4 objets RB remplacés (Potion Max → Hyper Potion ×2, Rappel Max → Rappel ×2, Carbone → Super Bonbon, Protéine → Rappel) ; CT32/CT37 « créées » | `tools/plans/safari_est.txt:68-71`, `safari_ouest.txt:73-77`, `safari_nord.txt:84-85` | Substitution validée (N-19) ; ajuster avec AUD-20 |
| AUD-24 | P2 | Manoir Pokémon, Tour Pokémon, Sylphe | Autres remplacements « objet absent » : Manoir 1F/3F Pépite (Carbone/Fer), 2F Super Bonbon (Calcium), Tour 4F Super Potion (Élixir), Sylphe 7F/10F Super Bonbon/Pépite (CT03, CT26, Calcium) | `tools/plans/manoir_1f.txt:64`, `manoir_2f.txt:65`, `manoir_3f.txt:56`, `pokemon_tower_4f.txt:69` | Défaire au fil de la création des objets (AUD-01, 05, 11, 12) |
| AUD-25 | P2 | Partout | Inflation de Super Bonbons (17 ramassages) et de Pépites (16) due aux remplacements ; RB en compte nettement moins (à vérifier) | `data/cutscenes/*.json` (comptage `give`) | Réduire à la création des objets d'origine |
| AUD-26 | P2 | Boutiques | Stocks différents de RB (à vérifier) : Lavanville (pas de Super Ball/Rappel), Safrania (pas d'Hyper Potion/Total Soin), Azuria/Carmin/Parmanie/Cramois'Île/Plateau (pas de Repousse) | `data/shops/*.json` | Aligner avec le dossier de chaque ville ; Repousse via AUD-14 |
| AUD-27 | P2 | Mont Sélénite, Manoir, Repaire, Route 2 est | Pierre Lune : aucune boutique, 5 ramassages pour 4 évolutions (Nidorina, Nidorino, Mélofée, Rondoudou) : marge de 1 seulement, sans rachat possible | `data/cutscenes/mt_moon.json`, `pokemon_mansion.json`, `rocket_hideout.json`, `route_2_east.json` | Garder (marge 1) ; vérifier que les 5 sont atteignables avant la Ligue |
| AUD-28 | P2 | Parc Safari centre | La Pépite de l'îlot (14, 10) de RB est déplacée en (14, 16), car l'îlot est inaccessible sans Surf à cet endroit [D] | `tools/plans/safari_centre.txt:74`, `data/cutscenes/j23_safari_zone_center.json` | Valider le déplacement |

### P3 — cosmétique

| Id | Prio | Carte | Constat | Source | Proposition |
|---|---|---|---|---|---|
| AUD-29 | P3 | Route 4 (Centre) | Vendeur de Magicarpe (500 ₽) absent : décision B-13 du J12 ; l'espèce reste obtenable par la Canne | `docs/design/dossier-15-route-3-mont-selenite.md:44` | Aucune |
| AUD-30 | P3 | Partout | Méga Canne (`super_rod`) : une table unique + 3 lieux ; RB varie par zone | `data/fishing/water_rod.json` | Garder (simplification connue) |
| AUD-31 | P3 | Bourg Palette | Carte de la ville (sœur du rival) absente ; le menu « Carte » existe | `docs/design/dossier-08-menu-dresseur.md` | Ignorer |
| AUD-32 | P3 | Jadielle | La Boutique vend la Potion (RB : pas de Potion à Jadielle, à vérifier) | `data/shops/viridian_mart.json` | Ignorer |
| AUD-33 | P3 | Route 1 | La Potion de RB (vendeur) devient une Poké Ball au sol | `data/cutscenes/route_1.json:2` | Ignorer |
| AUD-34 | P3 | Arène de Jadielle | Un Rappel au sol dans l'Arène (RB : aucun, à vérifier) | `data/cutscenes/viridian_gym.json` (`viridian_gym_item_1`) | Ignorer |
| AUD-35 | P3 | Route 25 (maison de Léo) | Léo donne un Super Bonbon en plus du Passe Bateau | `data/cutscenes/bill_house.json` (`bill_machine`) | Ignorer ou retirer |
| AUD-36 | P3 | Échanges | Lieu de 3 échanges différent de RB : Route 2 (poste est, RB maison d'échange), Route 11 → 2F du poste de la Route 12 [D], Carmin maison 2 | `data/npcs/route_2_east_gate.json`, `route_12_gate_2f.json`, `vermilion_house_2.json` | Déjà notés [D] au lot 32I |
| AUD-37 | P3 | Route 12 (poste, 2F) | CT39 Météores : lieu à vérifier face à RB | `data/cutscenes/route_12.json:12` | Vérifier |
