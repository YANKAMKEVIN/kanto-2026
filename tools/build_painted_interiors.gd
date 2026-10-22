extends SceneTree
## Construit les intérieurs **peints** (docs/tech/jalon-07.md §6.3, §6.6) :
##   viridian_center — le Centre Pokémon de Jadielle (jalon 7, T8)
##   viridian_mart   — la Boutique de Jadielle (jalon 7, T12)
##   player_house_2f, player_house_1f, rival_house, oak_lab — Bourg Palette (DA.3,
##     docs/tech/integration-da-bourg-route1.md ; plans du jalon 2, géométrie inchangée)
##
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --bourg
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --rooms=oak_lab
##   viridian_forest_gate_south, viridian_forest_gate_north — postes de garde de la Forêt de
##     Jade (jalon 9 T19, jalon-09.md §2.7.2 : une définition, deux scènes)
##
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --foret
##   pewter_center, pewter_mart, pewter_museum, pewter_museum_science, pewter_gym,
##     pewter_house_mason, pewter_house_researcher — intérieurs d'Argenta (jalon 10 T13,
##     jalon-10.md §2.2) : Centre et Boutique = définitions de Jadielle ; Musée, Arène et maisons
##     relus sur leur grille (`tools/plans/argenta_*.txt`, « plan »)
##
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --argenta
##   mt_moon_center — le Centre Pokémon du Mont Sélénite (jalon 12 T8, jalon-12.md §2.14) :
##     définition commune des Centres, sans Boutique ; sortie vers la Route 3 (`from_center_e`)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --rooms=mt_moon_center
##   cerulean_center, cerulean_mart, cerulean_gym, cerulean_bike_shop, cerulean_house,
##   cerulean_burgled_house (J14 T20b) — intérieurs
##     d'Azuria (jalon 13 T7, jalon-13.md §2.1, §2.5, §2.6) : Centre et Boutique = définitions
##     de Jadielle ; Arène, magasin de vélos et maison relus sur leur grille
##     (`tools/plans/azuria_*.txt`) ; **sans PNJ** (T17)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --azuria
##   bill_house — la maison de Léo au Cap d'Azuria (jalon 14 T14, jalon-14.md §2.1) : relue sur sa
##     grille (`tools/plans/bill_house.txt`, « plan »), sans PNJ (T17) ; affichée « Cap d'Azuria »
##     (nom de sa zone, `test_zone_library`)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --rooms=bill_house
##   vermilion_center, vermilion_mart, vermilion_fan_club, vermilion_fisher_house,
##   vermilion_house_1, vermilion_house_2, route_6_underground_gate — Carmin-sur-Mer et le
##     bâtiment de sortie du souterrain de la Route 6 (jalon 15 T14, jalon-15.md §2.2)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --carmin
##   route_5_daycare, route_5_gate, route_5_underground_gate — Pension, poste de garde vers Safrania
##     et bâtiment d'entrée du souterrain de la Route 5 (jalon 15 T13, jalon-15.md §2.2) ; titre
##     « Route 5 » (nom de leur zone, `test_zone_library`)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --route5
##   route_2_east_gate — le poste de l'assistant de Chen, sur la Route 2 est (jalon 17 T19,
##     jalon-17.md §2.2) : enveloppe d'une maison d'Argenta, relue sur sa grille
##     (`tools/plans/route_2_east_gate.txt`) ; titre « Route 2 » (nom de sa zone)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --route2est
##   ss_anne_main_deck, ss_anne_captain_corridor, ss_anne_captain_room, ss_anne_restaurant,
##   ss_anne_lower_deck, ss_anne_outer_deck, ss_anne_cabin_a|b|c — les 9 pièces du S.S. Anne,
##     et vermilion_gym — l'Arène de Carmin (jalon 16 T11, jalon-16.md §2.10) : relues sur leur
##     grille (`tools/plans/ss_anne_*.txt`, `carmin_arene.txt`), habillées au T10 par la série 18
##     (enveloppes peintes, meubles posés sur les cases de la grille ; pont extérieur : sol peint
##     en teck et mer, bastingages, superstructure)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --ss-anne
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --j16   (+ l'Arène)
##   lavender_center, lavender_mart, pokemon_house, lavender_house_1, lavender_house_2 — Lavanville
##     (jalon 18 T14, jalon-18.md §4.1, §4.2) : Centre et Boutique = définitions de Jadielle ;
##     Maison des Pokémon et maisons relues sur leur grille (`tools/plans/lavanville_maison_*.txt`),
##     **sans PNJ** (T18) ; la Tour (`pokemon_tower_1f`) est en modules (`tools/build_pokemon_tower.gd`)
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --lavanville
##   route_7_gate, route_8_gate, route_7_underground_gate, route_8_underground_gate — postes de
##     Safrania et bâtiments d'entrée du souterrain (jalon 20 T15, `--routes78`)
##   celadon_center, celadon_dept_gf|2f|3f|4f|5f|roof|elevator, celadon_mansion_gf|1f|2f|3f|roof|
##   roof_house, celadon_restaurant, celadon_chief_house, celadon_hotel — Céladopole (jalon 20 T16,
##     jalon-20.md §2.2 ; `--celadon`) : Centre = définition commune ; les autres relus sur leur
##     grille (`tools/plans/celadopole_*.txt`), enveloppes **provisoires** dessinées d'après la
##     grille (`tools/art/placeholders_celadopole.py`, série 22 bis à venir) ; **sans PNJ** (T17).
##     L'Arène d'Erika (`celadon_gym`) est dans `tools/build_celadon_gym.gd`.
##   godot --headless --path . -s res://tools/build_painted_interiors.gd -- --celadon
##   godot --headless --path . -s res://tools/build_painted_interiors.gd   (toutes les pièces)
##   godot --headless --path . --import
##
## **Ne relancer que les pièces voulues** : réécrire une carte change tous ses `unique_id`
## (`--bourg` = les quatre intérieurs de Bourg Palette ; `--jadielle` = Centre et Boutique).
##
## Bourg Palette (DA.3) : la **géométrie logique du jalon 2** est figée dans
## `tests/fixtures/maps/<carte>_logic.txt` (`tools/dump_map_logic.gd`, avant le passage au
## peint) ; l'outil la relit. Chaque meuble couvre exactement les cases solides de l'ancien
## meuble (rectangle donné en cases ; son emprise est écrite dans l'instance), ses images
## posées pied au milieu du bas du rectangle (comme le prototype validé,
## `proto/da_jadielle/proto_interieur_bourg.gd`) ; toutes les autres cases solides de la grille
## figée (murs de l'enveloppe, cases d'un meuble remplacé par plus petit) vont dans
## `blocked_cells`. Les tapis peints sont à plat dans `GroundDecals` (z −1). L'outil échoue si
## un meuble couvre une case praticable de la grille figée.
##
## Principe (§6.6, « intérieurs enveloppe vide + meubles séparés ») : l'enveloppe peinte de la
## pièce (15 × 10 cases, sprite opaque du sol, z −3) ; les meubles = scènes peintes
## `game/world/props/painted/<id>.tscn` (WorldProp, emprises de PaintedPropRules) dans
## `Entities` (tri par les pieds) ; les murs = cases bloquées (`GameMap.blocked_cells`) relevées
## sur l'enveloppe ; aucun TileMapLayer. Agencement : prototype validé par Kevin
## (`proto/da-jadielle:proto/da_jadielle/proto_interieur.gd`), colonnes posées sur la grille
## pour que les emprises tombent sous les images (banquettes en x = 3 et 12, présentoirs en
## x = 3 et 11, symétriques).
##
## Coordonnées en cases (x vers l'est, y vers le sud). Un meuble : [identifiant, case d'ancrage,
## pied en cases (y, peut remonter dans la case d'ancrage comme au prototype), nom du nœud].

const MAPS_DIR := "res://game/world/maps/"
const PROPS_DIR := "res://game/world/props/painted/"
const RULES_SCRIPT := "res://game/world/props/painted_prop_rules.gd"
const TILE := 96
## Warp.Trigger (valeurs).
const PUSH := 1
## Interaction.Kind (valeurs).
const TALK := 0
const EXAMINE := 1
## WorldLighting.Z_GROUND.
const Z_GROUND := -3
## WorldLighting.Z_GROUND_DECALS.
const Z_GROUND_DECALS := -1
const STEP_ON := 0
const BOURG := [&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab"]
const JADIELLE := [&"viridian_center", &"viridian_mart"]
const FORET := [&"viridian_forest_gate_south", &"viridian_forest_gate_north"]
const ARGENTA := [&"pewter_center", &"pewter_mart", &"pewter_museum", &"pewter_museum_science",
	&"pewter_gym", &"pewter_house_mason", &"pewter_house_researcher"]
const AZURIA := [&"cerulean_center", &"cerulean_mart", &"cerulean_gym", &"cerulean_bike_shop",
	&"cerulean_house", &"cerulean_burgled_house"]
## Jalon 15 (T14) : Carmin-sur-Mer et le bâtiment de sortie du souterrain de la Route 6.
const CARMIN := [&"vermilion_center", &"vermilion_mart", &"vermilion_fan_club",
	&"vermilion_fisher_house", &"vermilion_house_1", &"vermilion_house_2",
	&"route_6_underground_gate"]
## Jalon 15 (T13) : Pension, poste nord et entrée du souterrain de la Route 5.
const ROUTE_5 := [&"route_5_daycare", &"route_5_gate", &"route_5_underground_gate"]
## Jalon 17 (T19) : le poste de l'assistant de Chen (Route 2 est).
const ROUTE_2_EAST := [&"route_2_east_gate"]
## Jalon 16 (T11) : les 9 pièces du S.S. Anne ; avec l'Arène de Carmin : `--j16`.
const SS_ANNE := [&"ss_anne_main_deck", &"ss_anne_captain_corridor", &"ss_anne_captain_room",
	&"ss_anne_restaurant", &"ss_anne_lower_deck", &"ss_anne_outer_deck", &"ss_anne_cabin_a",
	&"ss_anne_cabin_b", &"ss_anne_cabin_c"]
## Jalon 16 (T10) : pont extérieur du S.S. Anne (sol peint teck + mer du port de Carmin).
const DECK_TEXTURE := "res://assets/world/ground/ground_pont_teck_01.png"
const SEA_FOAM := 0.3
const SEA_TINT := Color(0.58, 0.68, 0.9)
## Jalon 18 (T14) : les cinq intérieurs peints de Lavanville.
const LAVANVILLE := [&"lavender_center", &"lavender_mart", &"pokemon_house",
	&"lavender_house_1", &"lavender_house_2"]
## Jalon 20 (T15) : postes de Safrania et bâtiments d'entrée du souterrain des Routes 7 et 8.
const ROUTES_7_8 := [&"route_7_gate", &"route_8_gate", &"route_7_underground_gate",
	&"route_8_underground_gate"]
## Jalon 20 (T16) : Céladopole (hors Arène, `tools/build_celadon_gym.gd`).
const CELADON := [&"celadon_center", &"celadon_dept_gf", &"celadon_dept_2f", &"celadon_dept_3f",
	&"celadon_dept_4f", &"celadon_dept_5f", &"celadon_dept_roof", &"celadon_dept_elevator",
	&"celadon_mansion_gf", &"celadon_mansion_1f", &"celadon_mansion_2f", &"celadon_mansion_3f",
	&"celadon_mansion_roof", &"celadon_mansion_roof_house", &"celadon_restaurant",
	&"celadon_chief_house", &"celadon_hotel"]
## Jalon 29 : poste de la Ligue (Route 22 → Route 23) et hall du Plateau Indigo.
const J29 := [&"route_22_gate", &"indigo_plateau_lobby"]
const PLANS_DIR := "res://tools/plans/"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const LOGIC_DIR := "res://tests/fixtures/maps/"

var _rules: GDScript
var _scenes: Dictionary = {}
var _errors: int = 0


func _init() -> void:
	_rules = load(RULES_SCRIPT)
	var wanted := _wanted_rooms()
	var rooms: Array[Dictionary] = [_viridian_center(), _viridian_mart(), _player_house_2f(),
		_player_house_1f(), _rival_house(), _oak_lab(), _forest_gate(&"south"),
		_forest_gate(&"north")]
	rooms.append_array(_pewter_rooms())
	rooms.append(_bill_house())
	rooms.append(_pokemon_center(&"mt_moon_center", "MtMoonCenter", "Mont Sélénite",
		[&"route_3", &"from_center_e"]))
	rooms.append_array(_cerulean_rooms())
	rooms.append_array(_vermilion_rooms())
	rooms.append_array(_route_5_rooms())
	rooms.append(_route_2_east_gate())
	rooms.append_array(_ss_anne_rooms())
	rooms.append(_vermilion_gym())
	# Jalon 18 (T12) : le Centre de la Route 10 (même définition ; pièces du J18 en fin de liste).
	rooms.append(_pokemon_center(&"route_10_center", "Route10Center", "Route 10",
		[&"route_10", &"from_center"]))
	rooms.append_array(_lavender_rooms())
	rooms.append_array(_routes_7_8_rooms())
	rooms.append_array(_celadon_rooms())
	# Jalon 29 : le poste de la Ligue (Route 22) et le hall du Plateau Indigo (fin de liste).
	rooms.append_array(_j29_rooms())
	for room: Dictionary in rooms:
		if not wanted.is_empty() and not wanted.has(room["id"]):
			continue
		var root := _build(room)
		if _errors > 0:
			print("%s : non écrite (%d erreur(s))" % [room["id"], _errors])
			root.free()
			quit(1)
			return
		var packed := PackedScene.new()
		var err := packed.pack(root)
		var path := MAPS_DIR + "%s.tscn" % room["id"]
		if err == OK:
			err = ResourceSaver.save(packed, path)
		print("%s : %s" % [room["id"], error_string(err)])
		if err != OK:
			_errors += 1
		root.free()
	quit(1 if _errors > 0 else 0)


## Pièces demandées en ligne de commande (vide = toutes).
func _wanted_rooms() -> Array:
	var wanted: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--bourg":
			wanted.append_array(BOURG)
		elif arg == "--jadielle":
			wanted.append_array(JADIELLE)
		elif arg == "--foret":
			wanted.append_array(FORET)
		elif arg == "--argenta":
			wanted.append_array(ARGENTA)
		elif arg == "--azuria":
			wanted.append_array(AZURIA)
		elif arg == "--carmin":
			wanted.append_array(CARMIN)
		elif arg == "--route5":
			wanted.append_array(ROUTE_5)
		elif arg == "--route2est":
			wanted.append_array(ROUTE_2_EAST)
		elif arg == "--ss-anne":
			wanted.append_array(SS_ANNE)
		elif arg == "--j16":
			wanted.append_array(SS_ANNE + [&"vermilion_gym"])
		elif arg == "--lavanville":
			wanted.append_array(LAVANVILLE)
		elif arg == "--routes78":
			wanted.append_array(ROUTES_7_8)
		elif arg == "--celadon":
			wanted.append_array(CELADON)
		elif arg == "--j29":
			wanted.append_array(J29)
		elif arg.begins_with("--rooms="):
			for id: String in arg.trim_prefix("--rooms=").split(","):
				wanted.append(StringName(id))
	return wanted


## Centre Pokémon de Jadielle (dossier 09 §7) : comptoir au milieu (infirmière derrière, machine
## de soin à droite du plateau), terminal du Stockage au nord-ouest (EXAMINER face à lui →
## `storage_terminal` → l'écran Stockage, T16), deux banquettes, trois plantes ; pas d'escalier ni de Leveinard (arbitrages du dossier).
func _viridian_center() -> Dictionary:
	return _pokemon_center(&"viridian_center", "ViridianCenter", "Jadielle",
		[&"viridian_city", &"from_center"])


## Centre Pokémon (même enseigne partout, dossier 12 §8) : la définition du Centre de Jadielle
## (jalon 7 T8), seuls changent l'identifiant, le nœud racine, le titre et la sortie.
func _pokemon_center(id: StringName, node: String, title: String, exit_target: Array) \
		-> Dictionary:
	return {
		"id": id, "node": node, "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_centre_coque.png",
		"title": title, "light": &"interior_warm",
		# Mur du fond : 3 rangées (prototype) ; derrière le comptoir : l'infirmière seule.
		"back_rows": 3,
		"exit": [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		"exit_target": exit_target,
		"blocked": [Vector2i(5, 3), Vector2i(6, 3), Vector2i(8, 3), Vector2i(9, 3)],
		"props": [
			[&"int_centre_comptoir", Vector2i(7, 4), 5.0, "Counter"],
			[&"int_centre_terminal", Vector2i(2, 3), 3.4, "StorageTerminal"],
			[&"int_plante", Vector2i(12, 3), 3.4, "PlantNorthEast"],
			[&"int_centre_banquette", Vector2i(3, 7), 7.2, "BenchWest"],
			[&"int_centre_banquette", Vector2i(12, 7), 7.2, "BenchEast"],
			[&"int_plante", Vector2i(1, 8), 8.8, "PlantSouthWest"],
			[&"int_plante", Vector2i(13, 8), 8.8, "PlantSouthEast"],
		],
		# Machine de soin : halos sur les six alvéoles du plateau peint dans le comptoir (pixels
		# de l'image du comptoir relevés : rangée du fond puis de devant, de gauche à droite),
		# relatifs à l'origine de la machine, posée 1 px devant le pied du comptoir.
		"machine": {
			"name": "HealMachine", "position": Vector2(720, 481), "attendant": &"nurse",
			"turn": Vector2i.RIGHT,
			"slots": [Vector2(120, -130), Vector2(146, -130), Vector2(171, -130),
				Vector2(122, -116), Vector2(148, -116), Vector2(173, -116)],
			"flash": Vector2(147, -123),
		},
		# Parler à l'infirmière par-dessus le comptoir (trois cases devant elle, tourné vers le
		# haut).
		# Le terminal du Stockage (T16) : ses deux cases, face à lui (tourné vers le haut).
		"interactables": [["NurseCounter", Vector2i(6, 4), Vector2i(3, 1), &"nurse", TALK,
			Vector2i.UP], ["StorageTerminalScreen", Vector2i(1, 3), Vector2i(2, 1),
			&"storage_terminal", EXAMINE, Vector2i.UP]],
		"spawns": {"entrance": Vector2i(7, 8), "heal": Vector2i(7, 5),
			"terminal": Vector2i(1, 4)},
	}


## Boutique de Jadielle (dossier 09 §4, §9 ; prototype validé) : la caisse au milieu (le
## marchand derrière, on lui parle par-dessus), deux rayons muraux sans étiquette au fond, deux
## présentoirs de part et d'autre de l'allée qui mène au paillasson bleu, une plante. Première
## visite : déclencheur sur toute la rangée qu'on traverse en entrant (le seul passage depuis le
## paillasson) → scène `mart_parcel` (data/cutscenes/viridian_mart.json), qui ne se joue que sans
## `got_oak_parcel`.
func _viridian_mart() -> Dictionary:
	var room := _poke_mart(&"viridian_mart", "ViridianMart", "Jadielle",
		[&"viridian_city", &"from_mart"])
	# Rangée d'entrée (5..9, 7), toutes directions : on la traverse forcément en entrant.
	room["triggers"] = [["ParcelTrigger", Vector2i(5, 7), Vector2i(5, 1), &"mart_parcel"]]
	return room


## Boutique (même enseigne partout, dossier 12 §8) : la définition de la Boutique de Jadielle
## (jalon 7 T12) sans le déclencheur du colis, propre à Jadielle.
func _poke_mart(id: StringName, node: String, title: String, exit_target: Array) -> Dictionary:
	return {
		"id": id, "node": node, "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_boutique_coque.png",
		"title": title, "light": &"interior_warm",
		# Mur du fond : 3 rangées (prototype) ; derrière la caisse : le marchand seul.
		"back_rows": 3,
		"exit": [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		"exit_target": exit_target,
		"blocked": [Vector2i(5, 3), Vector2i(6, 3), Vector2i(8, 3), Vector2i(9, 3)],
		"props": [
			[&"int_boutique_caisse", Vector2i(7, 4), 5.0, "Counter"],
			[&"int_boutique_rayon_mural", Vector2i(2, 3), 3.2, "ShelfWest"],
			[&"int_boutique_rayon_mural", Vector2i(12, 3), 3.2, "ShelfEast"],
			[&"int_boutique_presentoir", Vector2i(3, 7), 7.3, "StandWest"],
			[&"int_boutique_presentoir", Vector2i(11, 7), 7.3, "StandEast"],
			[&"int_plante", Vector2i(13, 8), 8.8, "PlantSouthEast"],
		],
		# Parler au marchand par-dessus la caisse (trois cases devant lui, tourné vers le haut).
		"interactables": [["ClerkCounter", Vector2i(6, 4), Vector2i(3, 1), &"clerk", TALK,
			Vector2i.UP]],
		"spawns": {"entrance": Vector2i(7, 8), "counter": Vector2i(7, 5)},
	}


## Postes de garde de la Forêt de Jade (jalon 9 T19, jalon-09.md §2.7.2, dossier 10 §3) : **une
## définition, deux scènes** (même enveloppe peinte `int_poste_foret_coque`, mêmes meubles, garde
## à la même place ; seuls changent l'identifiant, le fichier de PNJ — donc la réplique du garde
## — et les passages). Pièce 10 × 8 cases : mur du fond sur 2 rangées, ouverture nord (4..5, 1),
## sol (1..8, 2..6), paillasson sud (4..5, 7) ; défaut : le garde en (7, 4), tourné vers le
## passage. Portes STEP_ON (on avance d'un pas dedans, comme la porte du poste de la Route 2).
## [param side] : `&"south"` (Route 2 ↔ forêt) ou `&"north"` (forêt ↔ « Route 2 nord — À
## venir » au J9 ; Argenta au J10).
func _forest_gate(side: StringName) -> Dictionary:
	var south := side == &"south"
	var room := {
		"id": StringName("viridian_forest_gate_" + String(side)),
		"node": "ViridianForestGate" + ("South" if south else "North"),
		"size": Vector2i(10, 8),
		"shell": "res://assets/world/interiors/int_poste_foret_coque.png",
		"title": "Forêt de Jade", "light": &"interior_warm",
		"floor": Rect2i(1, 2, 8, 5),
		"doors": [Vector2i(4, 1), Vector2i(5, 1), Vector2i(4, 7), Vector2i(5, 7)],
		"props": [
			[&"int_meuble_bas_01", Vector2i(2, 2), 3.0, "LowCabinet"],
			[&"int_porte_manteau_01", Vector2i(8, 2), 3.0, "CoatRack"],
			[&"int_plante", Vector2i(1, 6), 7.0, "PlantWest"],
			[&"int_plante", Vector2i(8, 6), 7.0, "PlantEast"],
		],
	}
	if south:
		# Depuis la Route 2 : un pas dans la pièce, tourné vers le nord ; depuis la forêt : sous
		# l'ouverture nord, tourné vers le sud.
		room["spawns"] = {"from_route_2": Vector2i(4, 6), "from_forest": Vector2i(4, 2)}
		room["warps"] = [
			["ToRoute2W", Vector2i(4, 7), STEP_ON, Vector2i.DOWN, &"route_2",
				&"from_forest_gate", Vector2i.DOWN],
			["ToRoute2E", Vector2i(5, 7), STEP_ON, Vector2i.DOWN, &"route_2",
				&"from_forest_gate", Vector2i.DOWN],
			["ToForestW", Vector2i(4, 1), STEP_ON, Vector2i.UP, &"viridian_forest",
				&"from_gate_south", Vector2i.UP],
			["ToForestE", Vector2i(5, 1), STEP_ON, Vector2i.UP, &"viridian_forest",
				&"from_gate_south", Vector2i.UP],
		]
	else:
		# Porte nord : la Route 2 nord (J10 T11), devant la porte du poste, tourné vers le nord ;
		# retour sous l'ouverture (spawn `north_door`), tourné vers le sud.
		room["spawns"] = {"from_forest": Vector2i(4, 6), "north_door": Vector2i(4, 2)}
		room["warps"] = [
			["ToForestW", Vector2i(4, 7), STEP_ON, Vector2i.DOWN, &"viridian_forest",
				&"from_gate_north", Vector2i.DOWN],
			["ToForestE", Vector2i(5, 7), STEP_ON, Vector2i.DOWN, &"viridian_forest",
				&"from_gate_north", Vector2i.DOWN],
			["ToRoute2NorthW", Vector2i(4, 1), STEP_ON, Vector2i.UP, &"route_2_north",
				&"from_forest_gate", Vector2i.UP],
			["ToRoute2NorthE", Vector2i(5, 1), STEP_ON, Vector2i.UP, &"route_2_north",
				&"from_forest_gate", Vector2i.UP],
		]
	return room


## Chambre du joueur (jalon 2 §4.3, référence `chambre-joueur-v1.webp`) : affiches, fenêtre,
## carte de Kanto, porte du mur est, tapis à carreaux et escalier = enveloppe peinte.
## Écart (géométrie gardée) : le meuble télé du jeu est **contre le mur est** (12, 4..5), là où
## le prototype mettait la télé au fond ; aucune image de télé vue de côté : petite étagère et
## commode Poké Ball à sa place (question à Kevin).
func _player_house_2f() -> Dictionary:
	return {
		"id": &"player_house_2f", "node": "PlayerHouse2F", "size": Vector2i(14, 10),
		"shell": "res://assets/world/interiors/int_chambre_joueur_coque.png",
		"title": "Bourg Palette", "region": "Kanto", "light": &"interior_warm",
		"logic": LOGIC_DIR + "player_house_2f_logic.txt",
		"furniture": [
			[&"int_lit_01", Rect2i(1, 2, 2, 3), "Bed"],
			[&"int_chevet_lampe_01", Rect2i(3, 2, 1, 1), "Nightstand"],
			[&"int_petite_etagere_01", Rect2i(4, 2, 1, 1), "SmallShelf"],
			[&"int_bureau_pc_01", Rect2i(6, 2, 3, 1), "Desk"],
			[&"int_chaise_bureau_01", Rect2i(7, 3, 1, 1), "DeskChair"],
			[&"int_grande_etagere_01", Rect2i(9, 2, 2, 2), "Bookshelf"],
			[&"int_petite_etagere_01", Rect2i(12, 4, 1, 1), "SideShelf"],
			[&"int_commode_pokeball_01", Rect2i(12, 5, 1, 1), "SideCabinet"],
			[&"int_sac_voyage_01", Rect2i(1, 5, 1, 1), "TravelBag"],
			[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
			[&"int_plante", Rect2i(12, 6, 1, 1), "PlantEast"],
			[&"int_meuble_bas_01", Rect2i(1, 8, 3, 1), "LowCabinet"],
			[&"int_commode_pokeball_01", Rect2i(9, 8, 1, 1), "CapCabinet"],
			[&"int_caisse_pokeballs_01", Rect2i(10, 8, 2, 1), "PokeballCrate"],
		],
		"rugs": [[&"int_tapis_pokeball_01", Vector2(7.0, 5.5), "RugPokeball"]],
		"spawns": {"start": Vector2i(3, 4), "stairs": Vector2i(6, 8)},
		"warps": [
			["StairsDownW", Vector2i(6, 9), STEP_ON, Vector2i.DOWN, &"player_house_1f",
				&"stairs"],
			["StairsDownE", Vector2i(7, 9), STEP_ON, Vector2i.DOWN, &"player_house_1f",
				&"stairs"],
		],
	}


## Rez-de-chaussée du joueur (jalon 2 §4.4, storyboard d'ouverture) : fenêtres, étagères
## murales, porte d'entrée et paillasson = enveloppe peinte. Sortie d'**une** case (7, 8) : la
## moitié ouest de l'ouverture peinte (2 cases) est derrière le porte-manteau (6, 8).
## Écarts (géométrie gardée) : meuble télé contre le mur est (12, 5..6) → aquarium et lampe ;
## le petit-déjeuner provisoire n'a pas d'image peinte (bouquet de la table peinte).
func _player_house_1f() -> Dictionary:
	return {
		"id": &"player_house_1f", "node": "PlayerHouse1F", "size": Vector2i(14, 10),
		"shell": "res://assets/world/interiors/int_maison_joueur_rdc_coque.png",
		"title": "Bourg Palette", "region": "Kanto", "light": &"interior_warm",
		"logic": LOGIC_DIR + "player_house_1f_logic.txt",
		"furniture": [
			# Escalier montant : la rangée du bas (1..2, 3) porte les passages vers l'étage.
			[&"int_escalier_montant_01", Rect2i(1, 2, 2, 2), "Stairs",
				[Vector2i(1, 2), Vector2i(2, 2)]],
			[&"int_frigo_01", Rect2i(3, 2, 1, 1), "Fridge"],
			[&"int_cuisine_01", Rect2i(4, 2, 3, 1), "Kitchen"],
			[&"int_table_repas_01", Rect2i(3, 4, 3, 2), "DiningTable"],
			[&"int_canape_01", Rect2i(9, 4, 3, 1), "Sofa"],
			[&"int_table_basse_01", Rect2i(9, 6, 2, 1), "CoffeeTable"],
			[&"int_aquarium_01", Rect2i(12, 5, 1, 1), "SideAquarium"],
			[&"int_chevet_lampe_01", Rect2i(12, 6, 1, 1), "SideLamp"],
			[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
			[&"int_plante", Rect2i(12, 7, 1, 1), "PlantEast"],
			[&"int_meuble_bas_01", Rect2i(1, 8, 3, 1), "LowCabinet"],
			[&"int_porte_manteau_01", Rect2i(6, 8, 1, 1), "CoatRack"],
			[&"int_commode_pokeball_01", Rect2i(9, 8, 1, 1), "Dresser"],
		],
		# Jalon 3A : petit-déjeuner posé sur la table (provisoire, sans image peinte).
		"decor": [["res://game/world/props/interior/breakfast.tscn", Vector2i(3, 5),
			"Breakfast"]],
		"rugs": [
			[&"int_tapis_plaid_01", Vector2(4.5, 5.0), "RugPlaid"],
			[&"int_tapis_salon_01", Vector2(10.5, 6.5), "RugLiving"],
		],
		"spawns": {"entrance": Vector2i(7, 8), "stairs": Vector2i(2, 4), "heal": Vector2i(7, 5)},
		# Jalon 3A : la table à manger (3..5, 4..5) s'examine de tous côtés.
		"interactables": [["BreakfastTable", Vector2i(3, 5), Vector2i(3, 2), &"breakfast_table",
			EXAMINE, Vector2i.ZERO]],
		"warps": [
			["StairsUpW", Vector2i(1, 3), STEP_ON, Vector2i.UP, &"player_house_2f", &"stairs"],
			["StairsUpE", Vector2i(2, 3), STEP_ON, Vector2i.UP, &"player_house_2f", &"stairs"],
			["Exit", Vector2i(7, 8), PUSH, Vector2i.DOWN, &"pallet_town", &"player_house_door"],
		],
	}


## Maison du rival (jalon 2 §4.5, référence `maison-rival-v1.webp`, sans Évoli) : fenêtres,
## affiches du rival, porte et paillasson = enveloppe peinte. L'escalier décoratif est solide
## sur ses **3 colonnes** (7..9, 2..4), l'image (2 cases) centrée dessus.
## Écarts (géométrie gardée) : télé murale de l'ouest (1, 6..7) → petite étagère et lampe ;
## coin du bureau d'angle (11, 3) → le sac du rival ; carte de Kanto dépliée sur le lit et
## tapis du salon et de la salle de bain non peints (prototype : tapis de la chambre seul).
func _rival_house() -> Dictionary:
	return {
		"id": &"rival_house", "node": "RivalHouse", "size": Vector2i(18, 11),
		"shell": "res://assets/world/interiors/int_maison_rival_coque.png",
		"title": "Bourg Palette", "region": "Kanto", "light": &"interior_warm",
		"logic": LOGIC_DIR + "rival_house_logic.txt",
		"furniture": [
			[&"int_frigo_01", Rect2i(1, 2, 1, 1), "Fridge"],
			[&"int_cuisine_01", Rect2i(2, 2, 3, 1), "Kitchen"],
			[&"int_cuisiniere_hotte_01", Rect2i(5, 2, 1, 1), "Stove"],
			[&"int_escalier_montant_01", Rect2i(7, 2, 3, 3), "Stairs"],
			[&"int_commode_pokeball_01", Rect2i(8, 5, 1, 1), "UnderStairsCabinet"],
			[&"int_table_repas_01", Rect2i(2, 4, 3, 2), "DiningTable"],
			[&"int_petite_etagere_01", Rect2i(1, 6, 1, 1), "LivingShelf"],
			[&"int_chevet_lampe_01", Rect2i(1, 7, 1, 1), "LivingLamp"],
			[&"int_canape_01", Rect2i(3, 7, 3, 1), "Sofa"],
			[&"int_table_basse_01", Rect2i(3, 8, 2, 1), "CoffeeTable"],
			[&"int_plante", Rect2i(1, 9, 1, 1), "PlantLivingWest"],
			[&"int_plante", Rect2i(6, 9, 1, 1), "PlantLivingEast"],
			[&"int_cloison_v_01", Rect2i(10, 2, 1, 3), "PartitionBedroom"],
			[&"int_bureau_angle_pc_01", Rect2i(11, 2, 2, 1), "CornerDesk"],
			[&"int_sac_voyage_01", Rect2i(11, 3, 1, 1), "RivalBag"],
			[&"int_chaise_gamer_01", Rect2i(12, 3, 1, 1), "GamerChair"],
			[&"int_commode_01", Rect2i(13, 2, 2, 1), "Dresser"],
			[&"int_lit_pokeball_01", Rect2i(15, 2, 2, 3), "Bed"],
			[&"int_chevet_lampe_01", Rect2i(16, 5, 1, 1), "Nightstand"],
			[&"int_cloison_h_01", Rect2i(12, 6, 5, 1), "PartitionBathroom"],
			[&"int_cloison_v_01", Rect2i(7, 7, 1, 3), "PartitionHallWest"],
			[&"int_cloison_v_01", Rect2i(10, 7, 1, 3), "PartitionHallEast"],
			[&"int_porte_manteau_01", Rect2i(12, 7, 1, 1), "CoatRack"],
			[&"int_lavabo_01", Rect2i(13, 7, 2, 1), "BathroomSink"],
			[&"int_douche_01", Rect2i(16, 7, 1, 2), "Shower"],
			[&"int_meuble_chaussures_01", Rect2i(11, 9, 1, 1), "ShoeRack"],
			[&"int_plante", Rect2i(12, 9, 1, 1), "PlantBathroom"],
		],
		# Jalon 3A (Q3) : carte de Kanto dépliée, sac et affaires sur le lit (provisoire).
		"decor": [["res://game/world/props/interior/bed_items.tscn", Vector2i(15, 4),
			"BedItems"]],
		"rugs": [[&"int_tapis_pokeball_01", Vector2(13.5, 4.5), "RugBedroom"]],
		"spawns": {"entrance": Vector2i(9, 9)},
		# Jalon 3A : la carte de Kanto sur le lit (15..16, 2..4), de tous côtés.
		"interactables": [["KantoMap", Vector2i(15, 4), Vector2i(2, 3), &"rival_kanto_map",
			EXAMINE, Vector2i.ZERO]],
		"warps": [
			["Exit", Vector2i(9, 9), PUSH, Vector2i.DOWN, &"pallet_town", &"rival_house_door"],
		],
	}


## Laboratoire de Chen (jalon 2 §4.7, référence `labo-chen-v1.png`) : carte de Kanto, grande
## fenêtre, affiche Poké Ball, suspensions et paillasson = enveloppe peinte. Tapis Poké Ball =
## arène du combat (6..9, 5..7). Écarts (géométrie gardée) : canapé vu de côté (1, 6..7) →
## classeur et petite étagère ; écran mural de l'est (14, 6..7) → seconde vitrine ; table des
## starters en (10..12, 4..5) et paillasse en rangée 8 (tabouret derrière elle), comme le jeu.
func _oak_lab() -> Dictionary:
	return {
		"id": &"oak_lab", "node": "OakLab", "size": Vector2i(16, 11),
		"shell": "res://assets/world/interiors/int_labo_coque.png",
		"title": "Bourg Palette", "region": "Kanto", "light": &"interior_warm",
		"logic": LOGIC_DIR + "oak_lab_logic.txt",
		"battle_arena": Rect2i(6, 5, 4, 3),
		"furniture": [
			[&"int_aquarium_01", Rect2i(1, 2, 1, 1), "Aquarium"],
			[&"int_incubateur_01", Rect2i(2, 2, 2, 2), "Incubator"],
			[&"int_machines_labo_01", Rect2i(4, 2, 2, 1), "Computers"],
			[&"int_bureau_chen_01", Rect2i(7, 2, 3, 1), "OakDesk"],
			[&"int_chaise_bureau_01", Rect2i(8, 3, 1, 1), "DeskChair"],
			[&"int_classeur_01", Rect2i(10, 2, 1, 1), "FileCabinet"],
			[&"int_etagere_labo_01", Rect2i(11, 2, 2, 2), "Bookshelf"],
			[&"int_frigo_01", Rect2i(13, 2, 1, 1), "Fridge"],
			[&"int_vitrine_pokeballs_01", Rect2i(14, 2, 1, 3), "DisplayCase"],
			[&"int_long_comptoir_01", Rect2i(1, 5, 5, 1), "LongCounter"],
			[&"int_table_starters_01", Rect2i(10, 4, 3, 2), "StarterTable"],
			[&"int_classeur_01", Rect2i(1, 6, 1, 1), "WestCabinet"],
			[&"int_petite_etagere_01", Rect2i(1, 7, 1, 1), "WestShelf"],
			[&"int_table_basse_01", Rect2i(3, 7, 2, 1), "CoffeeTable"],
			[&"int_tabouret_01", Rect2i(12, 7, 1, 1), "Stool"],
			[&"int_paillasse_01", Rect2i(11, 8, 3, 1), "Bench"],
			[&"int_vitrine_pokeballs_01", Rect2i(14, 6, 1, 2), "DisplayCaseEast"],
			[&"int_escalier_deco_01", Rect2i(1, 8, 3, 2), "Stairs"],
			[&"int_plante", Rect2i(6, 8, 1, 1), "PlantRug"],
			[&"int_plante", Rect2i(4, 9, 1, 1), "PlantStairs"],
			[&"int_plante", Rect2i(9, 9, 1, 1), "PlantEntrance"],
			[&"int_plante", Rect2i(14, 8, 1, 1), "PlantCorner"],
		],
		"rugs": [
			[&"int_tapis_rouge_01", Vector2(4.0, 7.5), "RugRed"],
			[&"int_tapis_labo_pokeball_01", Vector2(8.0, 6.5), "RugPokeball"],
		],
		"spawns": {"entrance": Vector2i(7, 9)},
		"warps": [
			["Exit", Vector2i(7, 9), PUSH, Vector2i.DOWN, &"pallet_town", &"oak_lab_door"],
		],
		# Sortie empêchée pendant le choix du starter (jalon-04.md §13.6).
		"triggers": [["LabExit", Vector2i(7, 9), Vector2i.ONE, &"oak_lab_exit"]],
	}


## Intérieurs d'Argenta (jalon 10 T13, jalon-10.md §2.2, dossier 12 §7, §8, §10, §19). Titre
## « Argenta » (toast du point de repos), lumière `interior_warm` ; sorties vers `pewter_city`,
## spawns `from_<carte sans « pewter_ »>` devant les portes de la ville (T11).
func _pewter_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = [
		_pokemon_center(&"pewter_center", "PewterCenter", "Argenta",
			[&"pewter_city", &"from_center"]),
		_poke_mart(&"pewter_mart", "PewterMart", "Argenta", [&"pewter_city", &"from_mart"]),
		_pewter_museum(), _pewter_museum_science(), _pewter_gym(),
		_pewter_house(&"pewter_house_mason", "PewterHouseMason", "argenta_maison_tailleur.txt",
			_mason_furniture(), [
				[&"int_tapis_plaid_01", Vector2(3.5, 6.0), "RugPlaid"],
				[&"int_tapis_salon_01", Vector2(11.0, 5.3), "RugLiving"],
			]),
		_pewter_house(&"pewter_house_researcher", "PewterHouseResearcher",
			"argenta_maison_chercheuse.txt", _researcher_furniture(),
			[[&"int_tapis_rouge_01", Vector2(8.5, 6.2), "RugReading"]]),
	]
	return rooms



## Maison de Léo, au Cap d'Azuria (`tools/plans/bill_house.txt`, 16 × 11) : deux cabines de
## téléportation (la seconde en miroir ; machine et armoire occupent 3 cases de large, l'armoire
## dans le mur latéral `K`), écran, console, module, bureau encombré et sa chaise, deux
## bibliothèques (la seconde en miroir), lit, plante. Sortie : le paillasson (7..8, 10), PUSH ↓.
## Léo-Mélofée et Léo humain : `data/npcs/bill_house.json` (T17).
func _bill_house() -> Dictionary:
	return {
		"id": &"bill_house", "node": "BillHouse", "size": Vector2i(16, 11),
		"shell": "res://assets/world/interiors/int_maison_leo_coque.png",
		"title": "Cap d'Azuria", "light": &"interior_warm",
		"plan": PLANS_DIR + "bill_house.txt", "walkable": ".X",
		"furniture": [
			[&"int_cabine_teleport_01", Rect2i(1, 3, 3, 2), "CabinA", [Vector2i(1, 3),
				Vector2i(2, 3), Vector2i(3, 3), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]],
			[&"int_cabine_teleport_01", Rect2i(12, 3, 3, 2), "CabinB", [Vector2i(12, 3),
				Vector2i(13, 3), Vector2i(14, 3), Vector2i(12, 4), Vector2i(13, 4),
				Vector2i(14, 4)], 1.0, true],
			[&"int_ecran_diagnostic_01", Rect2i(5, 3, 1, 1), "Screen"],
			[&"int_console_leo_01", Rect2i(7, 3, 2, 1), "Console"],
			[&"int_module_leo_01", Rect2i(10, 3, 1, 1), "Module"],
			[&"int_bibliotheque_cote_01", Rect2i(1, 6, 1, 2), "BookshelfWest"],
			[&"int_bibliotheque_cote_01", Rect2i(14, 6, 1, 2), "BookshelfEast", [Vector2i(14, 6),
				Vector2i(14, 7)], 1.0, true],
			[&"int_bureau_leo_01", Rect2i(5, 7, 3, 1), "Desk"],
			[&"int_chaise_bureau_01", Rect2i(6, 8, 1, 1), "DeskChair"],
			[&"int_lit_01", Rect2i(12, 7, 2, 2), "Bed"],
			[&"int_plante", Rect2i(1, 9, 1, 1), "Plant"],
		],
		"rugs": [[&"int_tapis_carreaux_01", Vector2(6.5, 7.8), "RugDesk"]],
		"spawns": {"from_route_25": Vector2i(7, 10)},
		"warps": [
			["Exit0", Vector2i(7, 10), PUSH, Vector2i.DOWN, &"route_25", &"from_bill_house_w",
				Vector2i.DOWN],
			["Exit1", Vector2i(8, 10), PUSH, Vector2i.DOWN, &"route_25", &"from_bill_house_e",
				Vector2i.DOWN],
		],
		# T17 : les trois objets EXAMINER (depuis la case au sud, tournés vers le nord), le
		# premier pas depuis le paillasson (scène d'entrée) et la lueur « hint » de l'objet
		# attendu (FlagGate : écran après `bill_met`, module après l'écran, console quand Léo est
		# dans la cabine).
		"interactables": [
			["ScreenPoint", Vector2i(5, 3), Vector2i(1, 1), &"bill_screen", EXAMINE, Vector2i.UP],
			["ModulePoint", Vector2i(10, 3), Vector2i(1, 1), &"bill_module", EXAMINE,
				Vector2i.UP],
			["ConsolePoint", Vector2i(7, 3), Vector2i(2, 1), &"bill_console", EXAMINE,
				Vector2i.UP],
		],
		"triggers": [["EntryTrigger", Vector2i(7, 9), Vector2i(2, 1), &"bill_house_enter",
			Vector2i.UP]],
		"gates": [
			["HintScreen", [&"bill_met"], [&"bill_screen_checked"], &"hint", Vector2(528, 275)],
			["HintModule", [&"bill_screen_checked"], [&"bill_module_checked"], &"hint",
				Vector2(1008, 320)],
			["HintConsole", [&"bill_in_cabin"], [&"bill_restored"], &"hint", Vector2(768, 335)],
		],
	}

## Poste de l'assistant de Chen (`tools/plans/route_2_east_gate.txt`, 15 × 10, jalon 17 T19,
## dossier 20 §8) : enveloppe d'une maison d'Argenta. Petit poste de recherche en bois : deux
## bibliothèques et la carte de Kanto au mur du fond, le bureau de l'assistant (et sa chaise)
## face à la porte, un classeur, l'étagère aux lampes de grotte (rappel de Flash), une table de
## lecture, deux plantes. L'assistant (8, 5) et le visiteur (11, 7) viennent de
## `data/npcs/route_2_east_gate.json` ; leurs cases (`a`, `v`) sont praticables dans la grille
## (le PNJ les occupe). Sortie : le paillasson (6..8, 8), PUSH ↓ → `route_2_east`.
func _route_2_east_gate() -> Dictionary:
	return {
		"id": &"route_2_east_gate", "node": "Route2EastGate", "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Route 2", "light": &"interior_warm",
		"plan": PLANS_DIR + "route_2_east_gate.txt", "walkable": ".Xav",
		"furniture": [
			[&"int_grande_etagere_01", Rect2i(1, 2, 2, 2), "BookshelfWest"],
			[&"int_grande_etagere_01", Rect2i(3, 2, 2, 2), "BookshelfCentre"],
			[&"int_bureau_chen_01", Rect2i(7, 3, 3, 1), "AssistantDesk"],
			[&"int_chaise_bureau_01", Rect2i(8, 4, 1, 1), "DeskChair"],
			[&"int_classeur_01", Rect2i(10, 3, 1, 1), "FileCabinet"],
			[&"int_etagere_lampes_01", Rect2i(12, 3, 2, 1), "LampShelf"],
			[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
			[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
		],
		# Table de lecture : image de 3 × 1,5 cases posée sur ses deux rangées (6..7) ; carte
		# murale accrochée au mur du fond, entre la bibliothèque et le bureau.
		"props": [
			[&"int_table_lecture_01", Vector2i(3, 7), 7.95, "ReadingTable"],
			[&"int_carte_murale_01", Vector2i(6, 2), 2.7, "WallMap"],
		],
		"spawns": {"entrance": Vector2i(7, 8)},
		"warps": [
			["Exit0", Vector2i(6, 8), PUSH, Vector2i.DOWN, &"route_2_east", &"from_gate",
				Vector2i.DOWN],
			["Exit1", Vector2i(7, 8), PUSH, Vector2i.DOWN, &"route_2_east", &"from_gate",
				Vector2i.DOWN],
			["Exit2", Vector2i(8, 8), PUSH, Vector2i.DOWN, &"route_2_east", &"from_gate",
				Vector2i.DOWN],
		],
	}


## Passages de sortie d'un intérieur d'Argenta : [param cells] PUSH ↓ → [param target]
## (`pewter_city` par défaut), [param spawn], tourné vers le sud.
func _pewter_exits(cells: Array, spawn: StringName, target: StringName = &"pewter_city") \
		-> Array:
	var warps: Array = []
	var index := 0
	for cell: Vector2i in cells:
		warps.append(["Exit%d" % index, cell, PUSH, Vector2i.DOWN, target, spawn, Vector2i.DOWN])
		index += 1
	return warps


## Musée, salle principale (`tools/plans/argenta_musee.txt`) : trois vitrines (Fossile Dôme,
## Fossile Nautile, Pierre Lune au centre sur son socle), examinées de tous côtés ; arche nord
## (STEP_ON ↑) vers la salle science ; ambiance silencieuse : personne dans la salle.
func _pewter_museum() -> Dictionary:
	var room := {
		"id": &"pewter_museum", "node": "PewterMuseum", "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_musee_coque.png",
		"title": "Argenta", "light": &"interior_warm",
		"plan": PLANS_DIR + "argenta_musee.txt", "walkable": ".DX",
		"props": [
			[&"int_vitrine_dome_01", Vector2i(3, 4), 4.92, "DomeFossilCase"],
			[&"int_vitrine_nautile_01", Vector2i(12, 4), 4.92, "HelixFossilCase"],
			[&"int_vitrine_pierre_lune_01", Vector2i(7, 5), 5.92, "MoonStoneCase"],
			[&"int_plante", Vector2i(1, 7), 7.85, "PlantSouthWest"],
			[&"int_plante", Vector2i(13, 7), 7.85, "PlantSouthEast"],
		],
		"interactables": [
			["DomeFossil", Vector2i(2, 4), Vector2i(2, 1), &"pewter_museum_dome", EXAMINE,
				Vector2i.ZERO],
			["HelixFossil", Vector2i(11, 4), Vector2i(2, 1), &"pewter_museum_helix", EXAMINE,
				Vector2i.ZERO],
			["MoonStone", Vector2i(7, 5), Vector2i.ONE, &"pewter_museum_moon_stone", EXAMINE,
				Vector2i.ZERO],
		],
		"spawns": {"entrance": Vector2i(7, 8), "from_science": Vector2i(7, 3)},
	}
	var warps := _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)], &"from_museum")
	for x: int in [6, 7, 8]:
		warps.append(["ToScience%d" % (x - 6), Vector2i(x, 2), STEP_ON, Vector2i.UP,
			&"pewter_museum_science", &"from_hall", Vector2i.UP])
	room["warps"] = warps
	return room


## Musée, salle « science » (`tools/plans/argenta_musee_science.txt`) : même coque ; l'arche
## nord est fermée par la porte du laboratoire (plaque à gauche, double porte : deux points
## d'examen, tourné vers le nord) ; panneau d'exposition, vitrine du journal ; deux chercheurs
## (data/npcs/pewter_museum_science.json). Retour vers la salle principale par le seuil.
func _pewter_museum_science() -> Dictionary:
	return {
		"id": &"pewter_museum_science", "node": "PewterMuseumScience", "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_musee_coque.png",
		"title": "Argenta", "light": &"interior_warm",
		"plan": PLANS_DIR + "argenta_musee_science.txt", "walkable": ".Xc",
		"props": [
			# Porte du laboratoire calée dans l'arche peinte (pied au bas du mur du fond) ; sans
			# emprise : la rangée 2 est bloquée par la grille.
			[&"int_porte_labo_01", Vector2i(7, 2), 2.4, "LabDoor"],
			[&"int_panneau_expo_01", Vector2i(3, 4), 4.92, "ExhibitPanel"],
			[&"int_vitrine_journal_01", Vector2i(12, 4), 4.92, "JournalCase"],
			[&"int_plante", Vector2i(1, 7), 7.85, "PlantSouthWest"],
			[&"int_plante", Vector2i(13, 7), 7.85, "PlantSouthEast"],
		],
		"interactables": [
			["LabSign", Vector2i(6, 2), Vector2i.ONE, &"pewter_museum_lab_sign", EXAMINE,
				Vector2i.UP],
			["LabDoorExamine", Vector2i(7, 2), Vector2i(2, 1), &"pewter_museum_lab_door",
				EXAMINE, Vector2i.UP],
			["SciencePanel", Vector2i(2, 4), Vector2i(2, 1), &"pewter_museum_science_panel",
				EXAMINE, Vector2i.ZERO],
			["Journal", Vector2i(11, 4), Vector2i(2, 1), &"pewter_museum_journal", EXAMINE,
				Vector2i.ZERO],
		],
		"spawns": {"from_hall": Vector2i(7, 8)},
		"warps": _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
			&"from_science", &"pewter_museum"),
	}


## Arène d'Argenta (`tools/plans/argenta_arene.txt`, 15 × 11, la salle entière à l'écran) :
## deux piliers au fond, quatre rochers bas devant, le bloc central (il arrête la vision de
## Liam), deux rochers bas de part et d'autre de Pierre sur l'estrade peinte ; Pierre, Liam et le guide = data/npcs/pewter_gym.json
## (vie et combats : T17).
func _pewter_gym() -> Dictionary:
	return {
		"id": &"pewter_gym", "node": "PewterGym", "size": Vector2i(15, 11),
		"shell": "res://assets/world/interiors/int_arene_coque.png",
		"title": "Argenta", "light": &"interior_warm",
		"plan": PLANS_DIR + "argenta_arene.txt", "walkable": ".XPLG",
		"props": [
			[&"int_rochers_bas_02", Vector2i(6, 2), 2.9, "RockStageWest"],
			[&"int_rochers_bas_02", Vector2i(8, 2), 2.9, "RockStageEast"],
			[&"int_pilier_roche_01", Vector2i(3, 4), 4.9, "PillarNorthWest"],
			[&"int_pilier_roche_01", Vector2i(12, 4), 4.9, "PillarNorthEast"],
			[&"int_rochers_bas_01", Vector2i(9, 7), 7.9, "CentralRocks"],
			# Devant (rangée 8) : rochers bas plutôt que piliers (3,5 cases de haut, ils cachaient
			# Liam en (2, 6) et tout le passage ouest) ; même emprise 2 × 1.
			[&"int_rochers_bas_02", Vector2i(2, 8), 8.9, "RockSouthWestA"],
			[&"int_rochers_bas_02", Vector2i(3, 8), 8.8, "RockSouthWestB"],
			[&"int_rochers_bas_02", Vector2i(11, 8), 8.8, "RockSouthEastA"],
			[&"int_rochers_bas_02", Vector2i(12, 8), 8.9, "RockSouthEastB"],
		],
		"spawns": {"entrance": Vector2i(7, 9)},
		"warps": _pewter_exits([Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9)], &"from_gym"),
	}


## Maison d'Argenta (arbitrage 14 : une seule enveloppe, deux mobiliers) : grille
## `tools/plans/<plan>` (même convention que le Centre), meubles de Bourg Palette posés comme
## dans les intérieurs de Bourg (rectangle des cases solides), tapis à plat. Sortie vers
## `pewter_city`, spawn `from_<carte sans « pewter_ »>`.
func _pewter_house(id: StringName, node: String, plan: String, furniture: Array,
		rugs: Array) -> Dictionary:
	return {
		"id": id, "node": node, "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Argenta", "light": &"interior_warm",
		"plan": PLANS_DIR + plan, "walkable": ".Xaec",
		"furniture": furniture, "rugs": rugs,
		"spawns": {"entrance": Vector2i(7, 8)},
		"warps": _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
			StringName("from_" + String(id).trim_prefix("pewter_"))),
	}


## Maison du tailleur (`argenta_maison_tailleur.txt`) : cuisine, table à manger, salon.
func _mason_furniture() -> Array:
	return [
		[&"int_frigo_01", Rect2i(1, 3, 1, 1), "Fridge"],
		[&"int_cuisine_01", Rect2i(2, 3, 3, 1), "Kitchen"],
		[&"int_cuisiniere_hotte_01", Rect2i(5, 3, 1, 1), "Stove"],
		[&"int_table_repas_01", Rect2i(2, 5, 3, 2), "DiningTable"],
		[&"int_canape_01", Rect2i(10, 3, 3, 1), "Sofa"],
		[&"int_chevet_lampe_01", Rect2i(13, 3, 1, 1), "Lamp"],
		[&"int_table_basse_01", Rect2i(10, 5, 2, 1), "CoffeeTable"],
		[&"int_porte_manteau_01", Rect2i(5, 7, 1, 1), "CoatRack"],
		[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
		[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
	]


## Maison de la chercheuse (`argenta_maison_chercheuse.txt`) : bibliothèque, bureau aux notes,
## étagère de pierres et de bocaux, pierres posées au sol, table de lecture.
func _researcher_furniture() -> Array:
	return [
		[&"int_grande_etagere_01", Rect2i(1, 2, 2, 2), "BookshelfWest"],
		[&"int_grande_etagere_01", Rect2i(3, 2, 2, 2), "BookshelfCentre"],
		[&"int_bureau_chen_01", Rect2i(7, 3, 3, 1), "NotesDesk"],
		[&"int_chaise_bureau_01", Rect2i(8, 4, 1, 1), "DeskChair"],
		[&"int_classeur_01", Rect2i(10, 3, 1, 1), "FileCabinet"],
		[&"int_etagere_labo_01", Rect2i(12, 2, 2, 2), "SpecimenShelf"],
		[&"int_rochers_bas_02", Rect2i(6, 3, 1, 1), "Stones"],
		[&"int_table_repas_01", Rect2i(2, 5, 3, 2), "ReadingTable"],
		[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
		[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
	]


## Intérieurs d'Azuria (jalon 13 T7, jalon-13.md §2.1, §2.5, §2.6 ; dossier 16 §4.3, §5, §9).
## Titre « Azuria » (toast du point de repos), lumière `interior_warm` ; sorties vers
## `cerulean_city`, spawns `from_<carte>` devant les portes de la ville. **Sans PNJ** : les
## cases de leurs positions (`bloque`) sont praticables dans la grille (T17).
func _cerulean_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = [
		_pokemon_center(&"cerulean_center", "CeruleanCenter", "Azuria",
			[&"cerulean_city", &"from_center"]),
		_poke_mart(&"cerulean_mart", "CeruleanMart", "Azuria", [&"cerulean_city", &"from_mart"]),
		_cerulean_gym(), _cerulean_bike_shop(), _cerulean_house(), _cerulean_burgled_house(),
	]
	return rooms


## Arène d'Azuria (`tools/plans/azuria_arene.txt`, 17 × 13) : bassin peint dans la coque (cases
## `W` bloquées), plongeoir contre le mur du fond (`P`), deux porte-bouées dans le mur du fond ;
## ni puzzle, ni nage. Ondine, Lucas, Diane et le guide = T17 (cases `O`, `N`, `J`, `G`).
func _cerulean_gym() -> Dictionary:
	return {
		"id": &"cerulean_gym", "node": "CeruleanGym", "size": Vector2i(17, 13),
		"shell": "res://assets/world/interiors/int_arene_azuria_coque.png",
		"title": "Azuria", "light": &"interior_warm",
		"plan": PLANS_DIR + "azuria_arene.txt", "walkable": ".XONJG",
		"props": [
			[&"int_plongeoir_01", Vector2i(13, 2), 2.95, "DivingBoard"],
			[&"int_porte_bouees_01", Vector2i(4, 1), 1.95, "LifebuoysWest"],
			[&"int_porte_bouees_01", Vector2i(11, 1), 1.95, "LifebuoysEast"],
		],
		"spawns": {"entrance": Vector2i(8, 11)},
		"warps": _pewter_exits([Vector2i(7, 11), Vector2i(8, 11), Vector2i(9, 11)], &"from_gym",
			&"cerulean_city"),
	}


## Magasin de vélos (`tools/plans/azuria_velos.txt`, 15 × 10, enveloppe des maisons d'Argenta) :
## trois vélos exposés au fond, un quatrième à l'écart, étagère de casques, comptoir (l'image
## de 5 cases réduite à 3), deux plantes ; le vendeur (`v`) = T17. Aucun achat.
func _cerulean_bike_shop() -> Dictionary:
	return {
		"id": &"cerulean_bike_shop", "node": "CeruleanBikeShop", "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Azuria", "light": &"interior_warm",
		"plan": PLANS_DIR + "azuria_velos.txt", "walkable": ".Xv",
		"props": [
			[&"int_velo_expose_01", Vector2i(2, 3), 3.9, "BikeA"],
			[&"int_velo_expose_02", Vector2i(5, 3), 3.9, "BikeB"],
			[&"int_velo_expose_03", Vector2i(8, 3), 3.9, "BikeC"],
			[&"int_velo_expose_02", Vector2i(2, 6), 6.9, "BikeD"],
			[&"int_etagere_casques_01", Vector2i(11, 3), 3.9, "HelmetShelf"],
			[&"int_plante", Vector2i(1, 7), 7.8, "PlantWest"],
			[&"int_plante", Vector2i(13, 7), 7.8, "PlantEast"],
		],
		"furniture": [
			[&"int_long_comptoir_01", Rect2i(9, 4, 3, 1), "Counter", [], 0.6],
		],
		"spawns": {"entrance": Vector2i(7, 8)},
		"warps": _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
			&"from_bike_shop", &"cerulean_city"),
	}


## Maison ouverte (`tools/plans/azuria_maison.txt`, 15 × 10, même enveloppe) : canapé, grand
## aquarium (trois bacs côte à côte), cuisine, table à manger ; l'habitante (`h`) = T17.
func _cerulean_house() -> Dictionary:
	return {
		"id": &"cerulean_house", "node": "CeruleanHouse", "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Azuria", "light": &"interior_warm",
		"plan": PLANS_DIR + "azuria_maison.txt", "walkable": ".Xh",
		"furniture": [
			[&"int_canape_01", Rect2i(1, 3, 3, 1), "Sofa"],
			[&"int_aquarium_01", Rect2i(5, 3, 1, 1), "AquariumA"],
			[&"int_aquarium_01", Rect2i(6, 3, 1, 1), "AquariumB"],
			[&"int_aquarium_01", Rect2i(7, 3, 1, 1), "AquariumC"],
			[&"int_frigo_01", Rect2i(9, 3, 1, 1), "Fridge"],
			[&"int_cuisine_01", Rect2i(10, 3, 2, 1), "Kitchen", [], 0.667],
			[&"int_cuisiniere_hotte_01", Rect2i(12, 3, 1, 1), "Stove"],
			[&"int_chevet_lampe_01", Rect2i(13, 3, 1, 1), "Lamp"],
			[&"int_table_repas_01", Rect2i(9, 5, 3, 2), "DiningTable"],
			[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
			[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
		],
		"rugs": [[&"int_tapis_plaid_01", Vector2(5.0, 6.0), "RugPlaid"]],
		"spawns": {"entrance": Vector2i(7, 8)},
		"warps": _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)], &"from_house",
			&"cerulean_city"),
	}


## Maison cambriolée (`tools/plans/azuria_maison_cambriolee.txt`, 15 × 10, même enveloppe ;
## jalon 14 T20b) : salon un peu en désordre (canapé, étagère, télévision, commode, table basse
## décalée, sac de voyage) ; la victime (`v`) remercie le joueur après le Rocket.
func _cerulean_burgled_house() -> Dictionary:
	return {
		"id": &"cerulean_burgled_house", "node": "CeruleanBurgledHouse",
		"size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Azuria", "light": &"interior_warm",
		"plan": PLANS_DIR + "azuria_maison_cambriolee.txt", "walkable": ".Xv",
		"furniture": [
			[&"int_canape_01", Rect2i(1, 3, 3, 1), "Sofa"],
			[&"int_petite_etagere_01", Rect2i(5, 3, 1, 1), "Shelf"],
			[&"int_tele_01", Rect2i(7, 3, 2, 1), "Television"],
			[&"int_commode_01", Rect2i(10, 3, 2, 1), "Dresser"],
			[&"int_chevet_lampe_01", Rect2i(13, 3, 1, 1), "Lamp"],
			[&"int_table_basse_01", Rect2i(6, 5, 2, 1), "CoffeeTable"],
			[&"int_sac_voyage_01", Rect2i(11, 6, 1, 1), "TravelBag"],
			[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
			[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
		],
		"rugs": [[&"int_tapis_salon_01", Vector2(5.0, 6.0), "RugLiving"]],
		"spawns": {"entrance": Vector2i(7, 8)},
		"warps": _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
			&"from_burgled_house", &"cerulean_city"),
	}


# --- Route 5 (jalon 15 T13, jalon-15.md §2.2) ---------------------------------------------


## Les trois pièces de la Route 5, titre « Route 5 » (zone `route_5`).
func _route_5_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = [_route_5_daycare(), _route_5_gate(),
		_route_5_underground_gate()]
	return rooms


## Pension Pokémon (dossier 18 §4.1, 15 × 10 [D]) : enveloppe des maisons d'Argenta, comptoir de la
## Pension (série 17) au milieu, le gardien (`old_man`, `data/npcs/route_5_daycare.json`) derrière,
## en (7, 3) ; on lui parle par-dessus le comptoir (trois cases devant, tourné vers le haut,
## modèle de la Boutique). Coin salon à l'est (canapé, lampe, table basse), paniers de Pokémon à
## l'ouest (aucun Pokémon visible, F-4), commode, deux plantes. Murs comme le Centre (3 rangées
## au fond) ; les cases (6, 3) et (8, 3), de part et d'autre du gardien, sont fermées.
func _route_5_daycare() -> Dictionary:
	return {
		"id": &"route_5_daycare", "node": "Route5Daycare", "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Route 5", "light": &"interior_warm",
		"back_rows": 3,
		"exit": [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		"exit_target": [&"route_5", &"from_daycare"],
		"blocked": [Vector2i(6, 3), Vector2i(8, 3)],
		"props": [
			[&"int_comptoir_pension_01", Vector2i(7, 4), 5.0, "Counter"],
			[&"int_commode_pokeball_01", Vector2i(1, 3), 3.9, "Dresser"],
			[&"int_panier_pokemon_01", Vector2i(2, 5), 5.85, "BasketA"],
			[&"int_panier_pokemon_01", Vector2i(3, 6), 6.85, "BasketB"],
			[&"int_canape_01", Vector2i(11, 3), 3.9, "Sofa"],
			[&"int_chevet_lampe_01", Vector2i(13, 3), 3.9, "Lamp"],
			[&"int_table_basse_01", Vector2i(12, 5), 5.85, "CoffeeTable"],
			[&"int_plante", Vector2i(1, 7), 7.8, "PlantWest"],
			[&"int_plante", Vector2i(13, 7), 7.8, "PlantEast"],
		],
		"interactables": [["KeeperCounter", Vector2i(6, 4), Vector2i(3, 1), &"daycare_keeper",
			TALK, Vector2i.UP]],
		"spawns": {"entrance": Vector2i(7, 8), "counter": Vector2i(7, 5)},
	}


## Pièce 10 × 8 des postes de la Route 5 (enveloppe `int_poste_foret_coque`, mêmes meubles que les
## postes de la forêt, `_forest_gate` inchangée) : sol (1..8, 2..6), portes (4..5, 7) au sud vers
## la Route 5 ([param exit_spawn]), arrivée `from_route_5` (4, 6) ; [param extra] : champs propres
## à la pièce (meubles en plus, passages nord, points, déclencheurs), ajoutés aux communs.
func _gate_room(id: StringName, node: String, exit_spawn: StringName, extra: Dictionary) \
		-> Dictionary:
	var room := {
		"id": id, "node": node, "size": Vector2i(10, 8),
		"shell": "res://assets/world/interiors/int_poste_foret_coque.png",
		"title": "Route 5", "light": &"interior_warm",
		"floor": Rect2i(1, 2, 8, 5),
		"doors": [Vector2i(4, 7), Vector2i(5, 7)],
		"props": [
			[&"int_meuble_bas_01", Vector2i(2, 2), 3.0, "LowCabinet"],
			[&"int_porte_manteau_01", Vector2i(8, 2), 3.0, "CoatRack"],
			[&"int_plante", Vector2i(1, 6), 7.0, "PlantWest"],
			[&"int_plante", Vector2i(8, 6), 7.0, "PlantEast"],
		],
		"spawns": {"from_route_5": Vector2i(4, 6)},
		"warps": [
			["ToRoute5W", Vector2i(4, 7), STEP_ON, Vector2i.DOWN, &"route_5", exit_spawn,
				Vector2i.DOWN],
			["ToRoute5E", Vector2i(5, 7), STEP_ON, Vector2i.DOWN, &"route_5", exit_spawn,
				Vector2i.DOWN],
		],
	}
	for key: String in extra:
		if room.has(key) and room[key] is Array:
			(room[key] as Array).append_array(extra[key])
		elif room.has(key) and room[key] is Dictionary:
			(room[key] as Dictionary).merge(extra[key], true)
		else:
			room[key] = extra[key]
	return room


## Poste de garde nord, vers Safrania (dossier 18 §7, jalon-15.md §2.4) : le garde (`guard`,
## `data/npcs/route_5_gate.json`) se tient en (4, 2), tourné vers le sud, devant l'ouverture nord ;
## la case (5, 2) est fermée par une plante [D]. Le joueur qui avance sur la rangée 3 (4..5, 3), pas
## vers le nord, déclenche `route_5_gate_rule` (T-15 puis T-16, recul d'une case). Ouverture nord
## (4..5, 1) = « SAFRANIA — À venir » (jamais atteinte : relais du jour où la ville rouvrira).
func _route_5_gate() -> Dictionary:
	return _gate_room(&"route_5_gate", "Route5Gate", &"from_gate", {
		"doors": [Vector2i(4, 1), Vector2i(5, 1)],
		"props": [[&"int_plante", Vector2i(5, 2), 2.95, "PlantDoor"]],
		"spawns": {"north_door": Vector2i(4, 3)},
		"warps": [
			["ToSaffronW", Vector2i(4, 1), STEP_ON, Vector2i.UP, &"", &"north_door",
				Vector2i.DOWN, "Safrania"],
			["ToSaffronE", Vector2i(5, 1), STEP_ON, Vector2i.UP, &"", &"north_door",
				Vector2i.DOWN, "Safrania"],
		],
		"triggers": [["GateRule", Vector2i(4, 3), Vector2i(2, 1), &"route_5_gate_rule",
			Vector2i.UP]],
	})


## Bâtiment d'entrée du souterrain (dossier 18 §5, jalon-15.md §2.2) : l'escalier descendant
## (série 17) sur (4..5, 2), deux passages `STEP_ON` sans direction (comme les échelles du J12)
## vers `underground_path` / `from_route_5_w|e` (arrivées de la carte du T18) ; retour du
## souterrain sur `from_underground_w` (4, 3) (nom attendu par le T18, tourné ↓ ; `_e` (5, 3) en
## plus), une case devant l'escalier. **Tant que la carte du souterrain (T18) n'existe pas**,
## l'escalier mène à « PASSAGE SOUTERRAIN — À venir » (retour sur la case devant, tourné vers le
## sud) ; relancer `--route5` une fois `underground_path.tscn` construite. Panneau T-14 au mur du
## fond (7, 1), EXAMINER depuis (7, 2) tourné vers le haut.
func _route_5_underground_gate() -> Dictionary:
	var built := ResourceLoader.exists(MAPS_DIR + "underground_path.tscn")
	var warps: Array = []
	var index := 0
	for suffix: String in ["w", "e"]:
		var cell := Vector2i(4 + index, 2)
		var back := StringName("from_underground_" + suffix)
		if built:
			warps.append(["ToUnderground" + suffix.to_upper(), cell, STEP_ON, Vector2i.ZERO,
				&"underground_path", StringName("from_route_5_" + suffix), Vector2i.DOWN])
		else:
			warps.append(["ToUnderground" + suffix.to_upper(), cell, STEP_ON, Vector2i.ZERO, &"",
				back, Vector2i.DOWN, "Passage souterrain"])
		index += 1
	return _gate_room(&"route_5_underground_gate", "Route5UndergroundGate", &"from_underground",
		{
			"props": [[&"int_escalier_descendant_01", Vector2i(5, 2), 3.0, "Stairs"]],
			"spawns": {"from_underground_w": Vector2i(4, 3), "from_underground_e": Vector2i(5, 3)},
			"warps": warps,
			"interactables": [["UndergroundSign", Vector2i(7, 1), Vector2i.ONE,
				&"route_5_underground_sign", EXAMINE, Vector2i.UP]],
		})


func _build(room: Dictionary) -> Node2D:
	var size: Vector2i = room["size"]
	var root := Node2D.new()
	root.name = room["node"]
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", room["id"])
	root.set(&"display_name", room["title"])
	root.set(&"region", room.get("region", ""))
	root.set(&"size", size)
	# Jalon 16 (T11) : le pont extérieur du S.S. Anne est une carte d'extérieur (le compagnon
	# peut y sortir, titre de zone).
	root.set(&"interior", not room.get("exterior", false))
	root.set(&"light_profile", room["light"])
	if room.has("battle_arena"):
		root.set(&"battle_arena", room["battle_arena"])
	if room.has("deck"):
		# Jalon 16 (T10) : le pont extérieur n'a pas d'enveloppe : sol peint (teck) et mer.
		_add_deck_ground(root, room)
	else:
		var shell := Sprite2D.new()
		shell.name = "Shell"
		shell.texture = load(room["shell"])
		shell.centered = false
		shell.z_index = Z_GROUND
		_attach(root, root, shell)
		if shell.texture.get_size() != Vector2(size * TILE):
			push_error("%s : enveloppe %s ≠ %s cases" % [room["id"], shell.texture.get_size(),
				size])
			_errors += 1
	if room.has("rugs") or room.has("deck") or room.has("ground_props"):
		var decals := Node2D.new()
		decals.name = "GroundDecals"
		decals.z_index = Z_GROUND_DECALS
		_attach(root, root, decals)
		for entry: Array in room.get("rugs", []):
			_add_rug(root, decals, entry[0], entry[1], entry[2])
		if room.has("deck"):
			_add_sea_tint(root, decals, room)
		for entry: Array in room.get("ground_props", []):
			_add_free_prop(root, decals, entry)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	for entry: Array in room.get("props", []):
		_add_prop(root, entities, entry[0], entry[1], entry[2], entry[3])
	for entry: Array in room.get("free_props", []):
		_add_free_prop(root, entities, entry)
	if room.has("machine"):
		_add_machine(root, entities, room["machine"])
	if room.has("logic"):
		var solid := _read_logic(room["logic"], size)
		var covered: Dictionary[Vector2i, bool] = {}
		for entry: Array in room["furniture"]:
			var cells: Array[Vector2i] = _add_furniture(root, entities, entry)
			for cell: Vector2i in cells:
				if not solid.has(cell):
					push_error("%s/%s : %s praticable dans la grille figée" % [room["id"],
						entry[2], cell])
					_errors += 1
				covered[cell] = true
		var blocked: Array[Vector2i] = []
		for y in size.y:
			for x in size.x:
				var cell := Vector2i(x, y)
				if solid.has(cell) and not covered.has(cell):
					blocked.append(cell)
		root.set(&"blocked_cells", blocked)
		# Décor posé sur un meuble (jalon 3A), sans emprise, dessiné après lui : [scène, case
		# d'ancrage du jalon 2 (en bas à gauche), nœud]. Provisoire tant qu'il n'a pas d'image
		# peinte.
		for entry: Array in room.get("decor", []):
			var decor := (load(entry[0]) as PackedScene).instantiate(
				PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
			decor.name = entry[2]
			decor.position = _world(entry[1])
			_attach(root, entities, decor)
	elif room.has("plan"):
		root.set(&"blocked_cells", _plan_blocked(root, entities, room))
	elif room.has("floor"):
		root.set(&"blocked_cells", _walls_around_floor(room))
	else:
		root.set(&"blocked_cells", _walls(room))
	var spawns: Dictionary = room["spawns"]
	for spawn_name: String in spawns:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(spawns[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	if room.has("exit"):
		var target: Array = room["exit_target"]
		var exit_spawns: Array = room.get("exit_spawns", [])
		var index := 0
		for cell: Vector2i in room["exit"]:
			var point := Marker2D.new()
			point.set_script(warp_script)
			point.name = "Exit%d" % index
			point.position = _world(cell)
			point.set(&"trigger", PUSH)
			point.set(&"direction", Vector2i.DOWN)
			point.set(&"target_map", target[0])
			# Jalon 20 : une arrivée par case de la porte (`from_<lieu>_w|e`), sinon la même.
			point.set(&"target_spawn", exit_spawns[index] if index < exit_spawns.size()
				else target[1])
			point.set(&"arrival_facing", Vector2i.DOWN)
			_attach(root, root.get_node(^"Warps"), point)
			index += 1
	# Passages décrits un par un : [nœud, case, déclenchement, direction, carte, spawn,
	# (orientation à l'arrivée), (destination « à venir »)].
	for warp: Array in room.get("warps", []):
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = warp[0]
		point.position = _world(warp[1])
		point.set(&"trigger", warp[2])
		point.set(&"direction", warp[3])
		point.set(&"target_map", warp[4])
		point.set(&"target_spawn", warp[5])
		if warp.size() > 6:
			point.set(&"arrival_facing", warp[6])
		if warp.size() > 7:
			point.set(&"coming_soon", warp[7])
		_attach(root, root.get_node(^"Warps"), point)
	var point_script: GDScript = load("res://game/world/interactions/interact_point.gd")
	for entry: Array in room.get("interactables", []):
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"dialogue_id", entry[3])
		point.set(&"kind", entry[4])
		point.set(&"facing", entry[5])
		if entry.size() == 7:
			# Jalon 16 (T12) : objet caché, cible tant que ces drapeaux sont bas (`got_<id>`).
			var hidden_unless: Array[StringName] = []
			hidden_unless.assign(entry[6])
			point.set(&"unless_flags", hidden_unless)
		if entry.size() > 7:
			# Jalon 16 : objet à fouiller d'un puzzle d'interrupteurs ([puzzle, emplacement]).
			point.set(&"puzzle", entry[6])
			point.set(&"puzzle_slot", entry[7])
		_attach(root, root.get_node(^"Interactables"), point)
	var trigger_script: GDScript = load("res://game/world/triggers/event_trigger_point.gd")
	for entry: Array in room.get("triggers", []):
		var point := Marker2D.new()
		point.set_script(trigger_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"cutscene_id", entry[3])
		if entry.size() > 4:
			point.set(&"direction", entry[4])
		_attach(root, root.get_node(^"Triggers"), point)
	# Décor qui suit les drapeaux (jalon 14) : [nœud, if, unless, type de halo, centre en pixels].
	var gate_script: GDScript = load("res://game/world/flag_gate.gd")
	var glow_script: GDScript = load("res://game/world/lighting/light_glow.gd")
	for entry: Array in room.get("gates", []):
		var gate := Node2D.new()
		gate.set_script(gate_script)
		gate.name = entry[0]
		var if_flags: Array[StringName] = []
		if_flags.assign(entry[1])
		var unless_flags: Array[StringName] = []
		unless_flags.assign(entry[2])
		gate.set(&"if_flags", if_flags)
		gate.set(&"unless_flags", unless_flags)
		_attach(root, root, gate)
		var glow := Sprite2D.new()
		glow.set_script(glow_script)
		glow.name = "Glow"
		glow.set(&"glow_type", entry[3])
		glow.position = entry[4]
		_attach(root, gate, glow)
	return root


## Pièce relue sur sa grille fonctionnelle (« plan », jalon 10 T13) : les caractères de
## « walkable » sont praticables (sol, passages, cases des PNJ, qui occupent leur case à
## l'exécution) ; toute autre case est solide. Pose les meubles « furniture » (rectangles, comme
## Bourg Palette) ; les emprises des objets (« props », règles d'emprise) et des meubles doivent
## tomber sur des cases solides de la grille (sinon erreur) ; les cases solides qu'ils ne couvrent
## pas (murs, rangée de la porte du laboratoire…) sont renvoyées pour `blocked_cells`.
func _plan_blocked(root: Node, entities: Node, room: Dictionary) -> Array[Vector2i]:
	var size: Vector2i = room["size"]
	var plan := PlanGrid.new()
	var blocked: Array[Vector2i] = []
	if not plan.load_file(room["plan"]) or Vector2i(plan.width, plan.height) != size:
		push_error("%s : grille %s illisible ou ≠ %s (%s)" % [room["id"], room["plan"], size,
			plan.error])
		_errors += 1
		return blocked
	var walkable: String = room["walkable"]
	var covered: Dictionary[Vector2i, String] = {}
	for entry: Array in room.get("props", []):
		for cell: Vector2i in _rules.call(&"footprint", entry[0]):
			covered[entry[1] + cell] = entry[3]
	for entry: Array in room.get("furniture", []):
		for cell: Vector2i in _add_furniture(root, entities, entry):
			covered[cell] = entry[2]
	for cell: Vector2i in covered:
		if walkable.contains(plan.at(cell)):
			push_error("%s/%s : %s praticable dans la grille" % [room["id"], covered[cell], cell])
			_errors += 1
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if not walkable.contains(plan.at(cell)) and not covered.has(cell):
				blocked.append(cell)
	return blocked


## Grille logique figée (`tools/dump_map_logic.gd`) : cases solides (« # » et « G »).
func _read_logic(path: String, size: Vector2i) -> Dictionary[Vector2i, bool]:
	var solid: Dictionary[Vector2i, bool] = {}
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	if lines.size() != size.y:
		push_error("%s : %d rangées au lieu de %d" % [path, lines.size(), size.y])
		_errors += 1
		return solid
	for y in size.y:
		for x in size.x:
			var c := lines[y][x]
			if c == "#" or c == "G":
				solid[Vector2i(x, y)] = true
	return solid


## Meuble de Bourg Palette : [identifiant, rectangle des cases solides, nœud, (cases solides
## explicites ; `[]` = le rectangle), (échelle), (miroir)]. Pied au milieu du bas du rectangle ; emprise écrite dans l'instance (relative
## à la case d'ancrage, celle qui contient le pied). Renvoie les cases solides.
func _add_furniture(root: Node, parent: Node, entry: Array) -> Array[Vector2i]:
	var id: StringName = entry[0]
	var rect: Rect2i = entry[1]
	var cells: Array[Vector2i] = []
	if entry.size() > 3 and not (entry[3] as Array).is_empty():
		cells.assign(entry[3])
	else:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				cells.append(Vector2i(x, y))
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + String(id) + ".tscn")
	var prop := (_scenes[id] as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) \
		as Node2D
	prop.name = entry[2]
	prop.position = Vector2((rect.position.x + rect.size.x / 2.0) * TILE, rect.end.y * TILE)
	if entry.size() > 4:
		# Meuble réduit à la place de la grille (jalon 13 : comptoir des vélos, cuisine).
		prop.scale = Vector2.ONE * float(entry[4])
	if entry.size() > 5 and bool(entry[5]):
		# Meuble en miroir (jalon 14 : cabine B et bibliothèque est de la maison de Léo).
		(prop.get_node(^"Sprite") as Sprite2D).flip_h = true
	var anchor := Vector2i(floori(prop.position.x / TILE), ceili(prop.position.y / TILE) - 1)
	var footprint: Array[Vector2i] = []
	for cell: Vector2i in cells:
		footprint.append(cell - anchor)
	prop.set(&"footprint", footprint)
	_attach(root, parent, prop)
	return cells


## Tapis peint à plat (traversable), centré sur [param centre] (en cases).
func _add_rug(root: Node, parent: Node, id: StringName, centre: Vector2, node_name: String) \
		-> void:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + String(id) + ".tscn")
	var rug := (_scenes[id] as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) \
		as Node2D
	rug.name = node_name
	var sprite := rug.get_node(^"Sprite") as Sprite2D
	var height := sprite.texture.get_height()
	rug.position = Vector2(roundf(centre.x * TILE), roundf(centre.y * TILE + height / 2.0))
	_attach(root, parent, rug)


## Murs de l'enveloppe : les rangées du fond, les colonnes de côté, l'avant-dernière rangée sauf
## la sortie (le paillasson), la dernière rangée ; plus les cases listées (« blocked »).
func _walls(room: Dictionary) -> Array[Vector2i]:
	var size: Vector2i = room["size"]
	var exit: Array = room["exit"]
	var extra: Array = room.get("blocked", [])
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var wall := y < int(room["back_rows"]) or y == size.y - 1 or x == 0 \
				or x == size.x - 1 or extra.has(cell)
			if y == size.y - 2 and not exit.has(cell):
				wall = true
			if wall:
				cells.append(cell)
	return cells


## Murs d'une pièce décrite par son sol (« floor », rectangle praticable) et ses portes
## (« doors ») : toute autre case est bloquée, plus les cases listées (« blocked »).
func _walls_around_floor(room: Dictionary) -> Array[Vector2i]:
	var size: Vector2i = room["size"]
	var floor_rect: Rect2i = room["floor"]
	var doors: Array = room.get("doors", [])
	var extra: Array = room.get("blocked", [])
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if extra.has(cell) or not (floor_rect.has_point(cell) or doors.has(cell)):
				cells.append(cell)
	return cells


func _add_prop(root: Node, parent: Node, id: StringName, anchor: Vector2i, foot_y: float,
		node_name: String) -> void:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + String(id) + ".tscn")
	var scene: PackedScene = _scenes[id]
	var prop := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	var foot: Vector2 = _rules.call(&"foot_position", id, anchor)
	foot.y = roundf(foot_y * TILE)
	prop.position = foot
	if Vector2i(floori(foot.x / TILE), ceili(foot.y / TILE) - 1) != anchor:
		push_error("%s : le pied %s n'est pas dans la case %s" % [node_name, foot, anchor])
	_attach(root, parent, prop)


## Objet sans emprise posé à un pied libre (jalon 16 T10) : [identifiant, pied en cases
## (Vector2), nœud, (miroir)]. Les cases restent celles de la grille (objets traversables :
## bastingages, superstructure, pylônes de la barrière).
func _add_free_prop(root: Node, parent: Node, entry: Array) -> void:
	var id: StringName = entry[0]
	if not _rules.call(&"is_traversable", id):
		push_error("%s : objet libre avec emprise" % entry[2])
		_errors += 1
		return
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + String(id) + ".tscn")
	var prop := (_scenes[id] as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) \
		as Node2D
	prop.name = entry[2]
	var foot: Vector2 = entry[1]
	prop.position = Vector2(roundf(foot.x * TILE), roundf(foot.y * TILE))
	if entry.size() > 3 and bool(entry[3]):
		(prop.get_node(^"Sprite") as Sprite2D).flip_h = true
	_attach(root, parent, prop)


## Pont extérieur (jalon 16 T10) : `PaintedGround` de la taille de la carte, fond = planches de
## teck ([constant DECK_TEXTURE], masque noir : ni pavés ni chemin), mer de Bourg Palette sur les
## cases `w` de la grille, à angles droits, écume réduite (comme le port de Carmin).
func _add_deck_ground(root: Node, room: Dictionary) -> void:
	var size: Vector2i = room["size"]
	var ground := Node2D.new()
	ground.set_script(load("res://game/world/ground/painted_ground.gd"))
	ground.name = "PaintedGround"
	ground.set(&"size", size)
	var mask := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	mask.fill(Color.BLACK)
	ground.set(&"mask", ImageTexture.create_from_image(mask))
	ground.set(&"base_texture", load(DECK_TEXTURE))
	var mask_script := load("res://game/world/ground/ground_mask.gd") as GDScript
	ground.set(&"shore_mask", ImageTexture.create_from_image(
		mask_script.call(&"build_water", size, _sea_cells(room)) as Image))
	ground.set(&"foam_strength", SEA_FOAM)
	ground.set(&"square_shore", true)
	_attach(root, root, ground)


func _sea_cells(room: Dictionary) -> Dictionary:
	var plan := PlanGrid.new()
	plan.load_file(room["plan"])
	var cells: Dictionary = {}
	var size: Vector2i = room["size"]
	for y in size.y:
		for x in size.x:
			if plan.at(Vector2i(x, y)) == "w":
				cells[Vector2i(x, y)] = true
	return cells


## Aplats multiplicatifs (bleu profond de la mer de Carmin) sur les rangées de mer pleines.
func _add_sea_tint(root: Node, parent: Node, room: Dictionary) -> void:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	var size: Vector2i = room["size"]
	var cells := _sea_cells(room)
	var index := 0
	var y := 0
	while y < size.y:
		if not cells.has(Vector2i(0, y)):
			y += 1
			continue
		var start := y
		while y < size.y and cells.has(Vector2i(0, y)):
			y += 1
		var r := Rect2(0, start * TILE, size.x * TILE, (y - start) * TILE)
		var polygon := Polygon2D.new()
		polygon.name = "SeaTint%02d" % index
		index += 1
		polygon.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		polygon.color = SEA_TINT
		polygon.material = material
		_attach(root, parent, polygon)


func _add_machine(root: Node, parent: Node, spec: Dictionary) -> void:
	var machine := Node2D.new()
	machine.set_script(load("res://game/world/props/heal_machine.gd"))
	machine.name = spec["name"]
	machine.position = spec["position"]
	var slots: Array[Vector2] = []
	slots.assign(spec["slots"])
	machine.set(&"slot_offsets", slots)
	machine.set(&"flash_offset", spec["flash"])
	machine.set(&"attendant", spec["attendant"])
	machine.set(&"attendant_turn", spec["turn"])
	_attach(root, parent, machine)
	machine.unique_name_in_owner = true


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


# --- Jalon 15 (T14) : Carmin-sur-Mer et la Route 6 ----------------------------------------


## Intérieurs de Carmin-sur-Mer (jalon 15 T14, jalon-15.md §2.2 ; dossier 18 §8.2) et bâtiment de
## sortie du souterrain de la Route 6. Titre « Carmin-sur-Mer » (toast du point de repos),
## lumière `interior_warm` ; sorties vers `vermilion_city`, spawns `from_<lieu>` devant les
## portes de la ville. Maisons, Pêcheur et Fan Club relus sur leur grille
## (`tools/plans/carmin_*.txt`) dans l'enveloppe des maisons d'Argenta.
func _vermilion_rooms() -> Array[Dictionary]:
	return [
		_pokemon_center(&"vermilion_center", "VermilionCenter", "Carmin-sur-Mer",
			[&"vermilion_city", &"from_center"]),
		_poke_mart(&"vermilion_mart", "VermilionMart", "Carmin-sur-Mer",
			[&"vermilion_city", &"from_mart"]),
		_vermilion_fan_club(), _vermilion_fisher_house(), _vermilion_house_1(),
		_vermilion_house_2(), _route_6_underground_gate(),
	]


## Pièce de Carmin relue sur sa grille : enveloppe des maisons d'Argenta, sortie PUSH ↓ vers
## `vermilion_city` / [param spawn].
func _vermilion_house(id: StringName, node: String, plan: String, walkable: String,
		spawn: StringName) -> Dictionary:
	return {
		"id": id, "node": node, "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Carmin-sur-Mer", "light": &"interior_warm",
		"plan": PLANS_DIR + plan, "walkable": walkable,
		"spawns": {"entrance": Vector2i(7, 8)},
		"warps": _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)], spawn,
			&"vermilion_city"),
	}


## Fan Club (`carmin_fan_club.txt`) : vitrine de rubans, fauteuil du président, tableau du port
## au mur, canapé et table basse ; président, deux membres et un Miaouss (data/npcs).
func _vermilion_fan_club() -> Dictionary:
	var room := _vermilion_house(&"vermilion_fan_club", "VermilionFanClub",
		"carmin_fan_club.txt", ".Xcamp", &"from_fan_club")
	room["props"] = [
		[&"int_tableau_port_01", Vector2i(8, 2), 2.55, "PortPainting"],
	]
	room["furniture"] = [
		[&"int_vitrine_rubans_01", Rect2i(1, 2, 2, 2), "RibbonCase"],
		[&"int_fauteuil_president_01", Rect2i(6, 3, 1, 1), "ChairmanSeat"],
		[&"int_canape_01", Rect2i(10, 3, 3, 1), "Sofa"],
		[&"int_chevet_lampe_01", Rect2i(13, 3, 1, 1), "Lamp"],
		[&"int_table_basse_01", Rect2i(10, 5, 2, 1), "CoffeeTable"],
		[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
		[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
	]
	room["rugs"] = [[&"int_tapis_rouge_01", Vector2(6.5, 5.6), "RugRed"]]
	return room


## Maison du Pêcheur (`carmin_pecheur.txt`) : cuisine, table, casiers de pêche ; le Pêcheur.
func _vermilion_fisher_house() -> Dictionary:
	var room := _vermilion_house(&"vermilion_fisher_house", "VermilionFisherHouse",
		"carmin_pecheur.txt", ".Xh", &"from_fisher_house")
	room["furniture"] = [
		[&"int_frigo_01", Rect2i(1, 3, 1, 1), "Fridge"],
		[&"int_cuisine_01", Rect2i(2, 3, 3, 1), "Kitchen"],
		[&"int_cuisiniere_hotte_01", Rect2i(5, 3, 1, 1), "Stove"],
		[&"prop_casiers_peche_01", Rect2i(10, 3, 2, 1), "FishingTraps"],
		[&"int_chevet_lampe_01", Rect2i(13, 3, 1, 1), "Lamp"],
		[&"int_table_repas_01", Rect2i(2, 5, 3, 2), "DiningTable"],
		[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
		[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
	]
	room["rugs"] = [[&"int_tapis_salon_01", Vector2(10.0, 5.8), "RugLiving"]]
	return room


## Maison 1 (`carmin_maison_1.txt`) : le mobilier de la maison du tailleur d'Argenta.
func _vermilion_house_1() -> Dictionary:
	var room := _vermilion_house(&"vermilion_house_1", "VermilionHouse1",
		"carmin_maison_1.txt", ".Xh", &"from_house_1")
	room["furniture"] = _mason_furniture()
	return room


## Maison 2 (`carmin_maison_2.txt`) : le mobilier de la maison d'Azuria.
func _vermilion_house_2() -> Dictionary:
	var room := _vermilion_house(&"vermilion_house_2", "VermilionHouse2",
		"carmin_maison_2.txt", ".Xh", &"from_house_2")
	var azuria := _cerulean_house()
	room["furniture"] = azuria["furniture"]
	room["rugs"] = azuria["rugs"]
	return room


## Bâtiment de sortie du souterrain, côté Route 6 (jalon-15.md §2.2) : enveloppe des postes de la
## Forêt de Jade (10 × 8), meuble bas, plantes ; **escalier descendant** sur (4..5, 2) (couche du
## sol), warps STEP_ON sans direction → `underground_path` / `from_route_6_w|e` (la carte du
## souterrain est faite en parallèle par le T18 : tant qu'elle n'existe pas, « Passage
## souterrain — À venir », retour sous l'escalier) ; panneau T-14 (panneau d'exposition, EXAMINER
## tourné ↑). Porte sud (4..5, 7) → `route_6` / `from_underground`, tournée ↓. Titre « Route 6 »
## (nom de sa zone, `test_zone_library`). Arrivées :
## `from_route_6` (4, 6) depuis la route, `from_underground_w|e` (4..5, 3) sous l'escalier.
func _route_6_underground_gate() -> Dictionary:
	var built := ResourceLoader.exists(MAPS_DIR + "underground_path.tscn")
	var warps: Array = [
		["ToRoute6W", Vector2i(4, 7), STEP_ON, Vector2i.DOWN, &"route_6", &"from_underground",
			Vector2i.DOWN],
		["ToRoute6E", Vector2i(5, 7), STEP_ON, Vector2i.DOWN, &"route_6", &"from_underground",
			Vector2i.DOWN],
	]
	for entry: Array in [["StairsW", Vector2i(4, 2), &"from_route_6_w"],
			["StairsE", Vector2i(5, 2), &"from_route_6_e"]]:
		if built:
			warps.append([entry[0], entry[1], STEP_ON, Vector2i.ZERO, &"underground_path",
				entry[2], Vector2i.UP])
		else:
			warps.append([entry[0], entry[1], STEP_ON, Vector2i.ZERO, &"",
				&"from_underground_w", Vector2i.DOWN, "Passage souterrain"])
	return {
		"id": &"route_6_underground_gate", "node": "Route6UndergroundGate",
		"size": Vector2i(10, 8),
		"shell": "res://assets/world/interiors/int_poste_foret_coque.png",
		"title": "Route 6", "light": &"interior_warm",
		"floor": Rect2i(1, 2, 8, 5),
		"doors": [Vector2i(4, 7), Vector2i(5, 7)],
		"props": [
			[&"int_meuble_bas_01", Vector2i(2, 2), 3.0, "LowCabinet"],
			[&"int_panneau_expo_01", Vector2i(8, 2), 3.0, "SignBoard"],
			[&"int_plante", Vector2i(1, 6), 7.0, "PlantWest"],
			[&"int_plante", Vector2i(8, 6), 7.0, "PlantEast"],
		],
		# Escalier à plat (couche du sol) : pied au bas de la rangée 2, centré sur 4..5.
		"rugs": [[&"int_escalier_descendant_01", Vector2(5.0, 3.0 - 86.0 / TILE),
			"StairsDown"]],
		"interactables": [["SignBoardRead", Vector2i(7, 2), Vector2i(2, 1),
			&"route_6_underground_gate_sign", EXAMINE, Vector2i.UP]],
		"spawns": {"from_route_6": Vector2i(4, 6), "from_underground_w": Vector2i(4, 3),
			"from_underground_e": Vector2i(5, 3)},
		"warps": warps,
	}


# --- Jalon 16 (T11) : le S.S. Anne et l'Arène de Carmin ----------------------------------------


## Les 9 pièces du S.S. Anne (jalon-16.md §2.10, dossier 19 §0.4) relues sur leur grille
## (`tools/plans/ss_anne_*.txt`, qui fait foi) : titre « S.S. Anne », sous-titre « Le grand
## paquebot de Kanto » (lot de textes du §0.5, n° 1), lumière `interior_warm` (le pont extérieur :
## `golden_hour`, carte d'extérieur). **Habillage de la série 18 (T10)** : enveloppe peinte
## (`int_ss_anne_*_coque`, cabines A, B, C = une seule) et meubles posés en rectangles sur les
## cases de leur lettre (« furniture », emprise = ces cases), grilles et passages inchangés. Les
## PNJ sont dans `data/npcs/ss_anne_*.json` (cases praticables de la grille). Passages : les portes `D` et escaliers `S` sont des passages
## terminaux (STEP_ON ; les escaliers dans toutes les directions, comme les échelles du J12), les
## sorties `X` des PUSH ↓. Arrivées nommées d'après la pièce d'où l'on vient (`from_<pièce>`).
## La passerelle (12..13, 11) ramène sur le quai de Carmin (`vermilion_city`, `from_ss_anne_w|e`,
## contrat du J15) ; l'embarquement de Carmin vise `from_ss_anne_w|e` du pont principal (T15).
func _ss_anne_rooms() -> Array[Dictionary]:
	return [_ss_anne_main_deck(), _ss_anne_captain_corridor(), _ss_anne_captain_room(),
		_ss_anne_restaurant(), _ss_anne_lower_deck(), _ss_anne_outer_deck(),
		_ss_anne_cabin(&"a", &"ss_anne_main_deck", &"from_cabin_a"),
		_ss_anne_cabin(&"b", &"ss_anne_lower_deck", &"from_cabin_b"),
		_ss_anne_cabin(&"c", &"ss_anne_main_deck", &"from_cabin_c")]


## Champs communs d'une pièce du navire : grille [param plan] (praticables de sa ligne
## `PRATICABLES`), taille, enveloppe peinte `assets/world/interiors/<shell>.png` (vide : aucune,
## le pont extérieur).
func _ss_anne_room(id: StringName, node: String, plan: String, walkable: String, size: Vector2i,
		shell: String) -> Dictionary:
	var room := {
		"id": id, "node": node, "size": size,
		"title": "S.S. Anne", "region": "Le grand paquebot de Kanto", "light": &"interior_warm",
		"plan": PLANS_DIR + plan, "walkable": walkable,
	}
	if not shell.is_empty():
		room["shell"] = "res://assets/world/interiors/%s.png" % shell
	return room


## Passage [param warp_name] sur [param cell] : porte ou escalier (STEP_ON, [param direction] ;
## ZERO = escalier, de tous côtés) vers [param target] / [param spawn], tourné [param facing].
func _door(warp_name: String, cell: Vector2i, direction: Vector2i, target: StringName,
		spawn: StringName, facing: Vector2i) -> Array:
	return [warp_name, cell, STEP_ON, direction, target, spawn, facing]


## Pont principal (`ss_anne_pont_principal.txt`, 26 × 13) : hall d'accueil ; passerelle au sud.
func _ss_anne_main_deck() -> Dictionary:
	var room := _ss_anne_room(&"ss_anne_main_deck", "SsAnneMainDeck",
		"ss_anne_pont_principal.txt", ".XDS", Vector2i(26, 13), "int_ss_anne_pont_principal_coque")
	# Grand tapis bordeaux, escalier et sa rambarde de laiton peints dans l'enveloppe (r2).
	room["furniture"] = [
		[&"int_banquette_ss_anne_01", Rect2i(3, 3, 2, 1), "BenchW"],
		[&"int_banquette_ss_anne_01", Rect2i(8, 3, 2, 1), "BenchC"],
		[&"int_banquette_ss_anne_01", Rect2i(16, 3, 2, 1), "BenchE"],
		[&"int_comptoir_accueil_ss_anne_01", Rect2i(15, 9, 4, 1), "Counter"],
	]
	room["props"] = [
		[&"int_plante", Vector2i(23, 2), 2.95, "PlantNE"],
		[&"int_plante", Vector2i(2, 10), 10.95, "PlantSW"],
	]
	room["spawns"] = {
		"from_ss_anne_w": Vector2i(12, 10), "from_ss_anne_e": Vector2i(13, 10),
		"from_cabin_a": Vector2i(5, 2), "from_cabin_c": Vector2i(11, 2),
		"from_corridor": Vector2i(20, 2), "from_restaurant": Vector2i(2, 6),
		"from_outer_deck": Vector2i(23, 6), "from_lower_deck": Vector2i(22, 9),
	}
	room["warps"] = [
		["ExitW", Vector2i(12, 11), PUSH, Vector2i.DOWN, &"vermilion_city", &"from_ss_anne_w",
			Vector2i.DOWN],
		["ExitE", Vector2i(13, 11), PUSH, Vector2i.DOWN, &"vermilion_city", &"from_ss_anne_e",
			Vector2i.DOWN],
		_door("DoorCabinA", Vector2i(5, 1), Vector2i.UP, &"ss_anne_cabin_a", &"entrance",
			Vector2i.UP),
		_door("DoorCabinC", Vector2i(11, 1), Vector2i.UP, &"ss_anne_cabin_c", &"entrance",
			Vector2i.UP),
		_door("DoorCorridor", Vector2i(20, 1), Vector2i.UP, &"ss_anne_captain_corridor",
			&"entrance", Vector2i.UP),
		_door("DoorRestaurant", Vector2i(1, 6), Vector2i.LEFT, &"ss_anne_restaurant",
			&"entrance", Vector2i.LEFT),
		_door("DoorOuterDeck", Vector2i(24, 6), Vector2i.RIGHT, &"ss_anne_outer_deck",
			&"entrance", Vector2i.RIGHT),
		_door("StairsDownW", Vector2i(22, 10), Vector2i.ZERO, &"ss_anne_lower_deck",
			&"entrance", Vector2i.DOWN),
		_door("StairsDownE", Vector2i(23, 10), Vector2i.ZERO, &"ss_anne_lower_deck",
			&"entrance", Vector2i.DOWN),
	]
	# Jalon 16 T15 (`jalon-16.md` §2.4, §2.11) : la passerelle (cases de sortie, de tous côtés)
	# lance `ss_anne_departure` : TXT-03 une fois avant la CS01, confirmation et départ après.
	room["triggers"] = [
		["DepartureTrigger", Vector2i(12, 11), Vector2i(2, 1), &"ss_anne_departure",
			Vector2i.ZERO],
	]
	return room


## Couloir du capitaine (`ss_anne_couloir_capitaine.txt`, 18 × 7) : la porte de la cabine au
## nord-est ; le déclencheur du rival (colonne 7) arrive au T13 avec sa scène.
func _ss_anne_captain_corridor() -> Dictionary:
	var room := _ss_anne_room(&"ss_anne_captain_corridor", "SsAnneCaptainCorridor",
		"ss_anne_couloir_capitaine.txt", ".XDT", Vector2i(18, 7), "int_ss_anne_couloir_coque")
	room["spawns"] = {"entrance": Vector2i(2, 4), "from_captain_room": Vector2i(15, 2)}
	room["warps"] = [
		["Exit", Vector2i(2, 5), PUSH, Vector2i.DOWN, &"ss_anne_main_deck", &"from_corridor",
			Vector2i.DOWN],
		_door("DoorCaptain", Vector2i(15, 1), Vector2i.UP, &"ss_anne_captain_room", &"entrance",
			Vector2i.UP),
	]
	# T13 : la vue du rival n° 4 (colonne 7, rangées 2..4, ancre en bas), toutes directions ;
	# la scène `ss_anne_rival` ne joue plus après `rival_ss_anne_won`.
	room["triggers"] = [["RivalView", Vector2i(7, 4), Vector2i(1, 3), &"ss_anne_rival"]]
	return room


## Cabine du capitaine (`ss_anne_cabine_capitaine.txt`, 14 × 10) : bureau, lavabo, couchette,
## carte marine ; le capitaine (8, 3) arrive au T13.
func _ss_anne_captain_room() -> Dictionary:
	var room := _ss_anne_room(&"ss_anne_captain_room", "SsAnneCaptainRoom",
		"ss_anne_cabine_capitaine.txt", ".X", Vector2i(14, 10), "int_ss_anne_cabine_capitaine_coque")
	room["furniture"] = [
		[&"int_bureau_capitaine_01", Rect2i(2, 2, 3, 1), "Desk"],
		[&"int_lavabo_cabine_01", Rect2i(8, 2, 1, 1), "Washbasin"],
		[&"int_table_cartes_01", Rect2i(10, 2, 2, 1), "ChartTable"],
		[&"int_lit_cabine_01", Rect2i(11, 5, 2, 2), "Bunk"],
	]
	room["spawns"] = {"entrance": Vector2i(6, 7)}
	room["warps"] = _pewter_exits([Vector2i(6, 8), Vector2i(7, 8)], &"from_captain_room",
		&"ss_anne_captain_corridor")
	return room


## Restaurant (`ss_anne_restaurant.txt`, 18 × 11) : quatre tables, comptoir de la cuisine.
func _ss_anne_restaurant() -> Dictionary:
	var room := _ss_anne_room(&"ss_anne_restaurant", "SsAnneRestaurant",
		"ss_anne_restaurant.txt", ".D", Vector2i(18, 11), "int_ss_anne_restaurant_coque")
	room["furniture"] = [
		[&"int_table_restaurant_01", Rect2i(3, 3, 2, 1), "TableNW"],
		[&"int_table_restaurant_01", Rect2i(8, 3, 2, 1), "TableNE"],
		[&"int_table_restaurant_01", Rect2i(3, 6, 2, 1), "TableSW"],
		[&"int_table_restaurant_01", Rect2i(8, 6, 2, 1), "TableSE"],
		[&"int_comptoir_cuisine_01", Rect2i(11, 2, 4, 1), "KitchenCounter"],
	]
	room["spawns"] = {"entrance": Vector2i(15, 6)}
	room["warps"] = [_door("Door", Vector2i(16, 6), Vector2i.RIGHT, &"ss_anne_main_deck",
		&"from_restaurant", Vector2i.RIGHT)]
	# Objet caché : le comptoir de la cuisine, examiné depuis (11, 3) tourné vers le haut (T12).
	room["interactables"] = [["HiddenPotion", Vector2i(11, 2), Vector2i.ONE,
		&"ss_anne_hidden_3", EXAMINE, Vector2i.UP, [&"got_ss_anne_hidden_3"]]]
	return room


## Pont inférieur (`ss_anne_pont_inferieur.txt`, 22 × 11) : caisses, escalier vers le pont
## principal, porte de la cabine B.
func _ss_anne_lower_deck() -> Dictionary:
	var room := _ss_anne_room(&"ss_anne_lower_deck", "SsAnneLowerDeck",
		"ss_anne_pont_inferieur.txt", ".DS", Vector2i(22, 11), "int_ss_anne_pont_inferieur_coque")
	# Escalier montant peint dans l'enveloppe (2..3, 2).
	room["furniture"] = [
		[&"prop_caisses_port_01", Rect2i(19, 2, 2, 1), "CratesNE"],
		[&"int_caisses_cale_02", Rect2i(14, 3, 3, 2), "CratesCentre"],
		[&"int_caisses_cale_01", Rect2i(5, 6, 2, 2), "CratesSW"],
	]
	room["spawns"] = {"entrance": Vector2i(2, 3), "from_cabin_b": Vector2i(10, 2)}
	room["warps"] = [
		_door("StairsUpW", Vector2i(2, 2), Vector2i.ZERO, &"ss_anne_main_deck",
			&"from_lower_deck", Vector2i.UP),
		_door("StairsUpE", Vector2i(3, 2), Vector2i.ZERO, &"ss_anne_main_deck",
			&"from_lower_deck", Vector2i.UP),
		_door("DoorCabinB", Vector2i(10, 1), Vector2i.UP, &"ss_anne_cabin_b", &"entrance",
			Vector2i.UP),
	]
	# Objet caché : la caisse (5, 6), examinée depuis (5, 5) tournée vers le bas (T12).
	room["interactables"] = [["HiddenAntidote", Vector2i(5, 6), Vector2i.ONE,
		&"ss_anne_hidden_2", EXAMINE, Vector2i.DOWN, [&"got_ss_anne_hidden_2"]]]
	return room


## Pont extérieur (`ss_anne_pont_exterieur.txt`, 26 × 11) : **carte d'extérieur** (compagnon
## dehors, titre de zone), lumière `golden_hour` ; mer au nord et au sud (bloquée), rambardes,
## chaises longues, bouées ; une porte à l'ouest vers le pont principal.
func _ss_anne_outer_deck() -> Dictionary:
	var room := _ss_anne_room(&"ss_anne_outer_deck", "SsAnneOuterDeck",
		"ss_anne_pont_exterieur.txt", ".D", Vector2i(26, 11), "")
	room["light"] = &"golden_hour"
	room["exterior"] = true
	room["deck"] = true
	room["furniture"] = [
		[&"prop_chaises_longues_01", Rect2i(5, 4, 2, 1), "LoungersN"],
		[&"prop_chaises_longues_01", Rect2i(5, 7, 2, 1), "LoungersS"],
		[&"prop_bouee_01", Rect2i(14, 3, 1, 1), "LifebuoyN"],
		[&"prop_bouee_01", Rect2i(22, 8, 1, 1), "LifebuoyS"],
	]
	room["ground_props"] = _outer_deck_rails()
	# Superstructure ouest : colonne 0 (rangées 3..8), porte peinte sur la case `D` (0, 6).
	room["free_props"] = [[&"bldg_ss_anne_superstructure_01", Vector2(0.65, 8.4),
		"Superstructure"]]
	room["spawns"] = {"entrance": Vector2i(1, 6)}
	room["warps"] = [_door("Door", Vector2i(0, 6), Vector2i.LEFT, &"ss_anne_main_deck",
		&"from_outer_deck", Vector2i.LEFT)]
	return room


## Bastingages du pont extérieur (couche du sol, cases `r` bloquées par la grille) : nord (rangée
## 2, modules de 2 cases, la variante à taquet une fois sur quatre), sud (rangée 9, avec le flanc
## blanc qui déborde sur la mer de la rangée 10), est (colonne 25), angles nord-est et sud-est.
func _outer_deck_rails() -> Array:
	var rails: Array = []
	for i in 13:
		var north := &"relief_bastingage_02" if i % 4 == 2 else &"relief_bastingage_01"
		rails.append([north, Vector2(2 * i + 1, 3.0), "RailN%02d" % i])
		rails.append([&"relief_bastingage_sud_01", Vector2(2 * i + 1, 10.39), "RailS%02d" % i])
	for i in 4:
		rails.append([&"relief_bastingage_est_01", Vector2(25.86, 4.55 + 1.5 * i), "RailE%d" % i])
	rails.append([&"relief_bastingage_angle_ne_01", Vector2(25.7, 3.0), "RailCornerNE"])
	rails.append([&"relief_bastingage_angle_se_01", Vector2(25.7, 10.39), "RailCornerSE"])
	return rails


## Cabine de passagers [param letter] (`ss_anne_cabine_<lettre>.txt`, 12 × 9, même grille pour
## A, B, C) : lit, table sous le hublot, armoire ; sortie (5..6, 7) vers [param target] /
## [param spawn].
func _ss_anne_cabin(letter: StringName, target: StringName, spawn: StringName) -> Dictionary:
	var id := StringName("ss_anne_cabin_" + String(letter))
	var room := _ss_anne_room(id, "SsAnneCabin" + String(letter).to_upper(),
		"ss_anne_cabine_%s.txt" % letter, ".X", Vector2i(12, 9), "int_ss_anne_cabine_coque")
	room["furniture"] = [
		[&"int_table_hublot_01", Rect2i(2, 2, 2, 1), "Table"],
		[&"int_lit_cabine_01", Rect2i(8, 2, 2, 2), "Bed"],
		[&"int_armoire_cabine_01", Rect2i(10, 6, 1, 1), "Wardrobe"],
	]
	room["spawns"] = {"entrance": Vector2i(5, 6)}
	room["warps"] = _pewter_exits([Vector2i(5, 7), Vector2i(6, 7)], spawn, target)
	if letter == &"b":
		# Objet caché : l'armoire (10, 6), examinée depuis (9, 6) tournée vers la droite (T12).
		room["interactables"] = [["HiddenAwakening", Vector2i(10, 6), Vector2i.ONE,
			&"ss_anne_hidden_1", EXAMINE, Vector2i.RIGHT, [&"got_ss_anne_hidden_1"]]]
	return room


## Arène de Carmin (`carmin_arene.txt`, 17 × 15, plus haute que l'écran : la caméra suit) :
## 15 poubelles à fouiller (puzzle `vermilion_gym`, emplacements 1..15 ligne par ligne, comme la
## grille 5 × 3 de `SwitchPuzzle`), rangée de machines et barrière (7..9, 5 : cases praticables,
## fermées par les trois segments de `data/npcs/vermilion_gym.json` tant que
## `vermilion_gym_puzzle_solved` n'est pas levé), sortie (7..9, 13) vers Carmin (`from_gym`).
## Major Bob, ses Dresseurs, le guide et le panneau : T14 (`data/npcs/vermilion_gym.json`). Titre
## « Carmin-sur-Mer » (zone de la ville, comme les autres Arènes) ; arrivée `entrance` (8, 12).
## Habillage de la série 18 (T10) : enveloppe peinte (zone du Champion sur les rangées 2..4), 15
## poubelles identiques sur les cases `i`, armoires électriques A / B alternées sur les cases `m`,
## pylônes éteints de la barrière toujours posés (objet libre, sous la barrière active des PNJ
## objets `electric_barrier`).
func _vermilion_gym() -> Dictionary:
	var bins: Array = []
	var slot := 1
	for y: int in [7, 9, 11]:
		for x: int in [2, 5, 8, 11, 14]:
			bins.append(["Bin%02d" % slot, Vector2i(x, y), Vector2i.ONE, &"vermilion_gym_trash",
				EXAMINE, Vector2i.ZERO, &"vermilion_gym", slot])
			slot += 1
	var furniture: Array = []
	for index in bins.size():
		var cell: Vector2i = bins[index][1]
		furniture.append([&"int_poubelle_arene_01", Rect2i(cell, Vector2i.ONE),
			"Trash%02d" % (index + 1)])
	var machine := 0
	for x: int in [2, 3, 4, 5, 6, 10, 11, 12, 13, 14]:
		var id := &"int_armoire_electrique_01" if machine % 2 == 0 else &"int_armoire_electrique_02"
		furniture.append([id, Rect2i(x, 5, 1, 1), "Cabinet%02d" % machine])
		machine += 1
	return {
		"id": &"vermilion_gym", "node": "VermilionGym", "size": Vector2i(17, 15),
		"shell": "res://assets/world/interiors/int_arene_carmin_coque.png",
		"title": "Carmin-sur-Mer", "light": &"interior_warm",
		"plan": PLANS_DIR + "carmin_arene.txt", "walkable": ".XB",
		"furniture": furniture,
		# Un pixel au-dessus du pied des PNJ objets de la barrière : dessinés derrière elle.
		"free_props": [[&"int_barriere_coupee_01", Vector2(8.5, 5.99), "BarrierPylons"]],
		"spawns": {"entrance": Vector2i(8, 12)},
		"warps": _pewter_exits([Vector2i(7, 13), Vector2i(8, 13), Vector2i(9, 13)], &"from_gym",
			&"vermilion_city"),
		"interactables": bins,
	}


# --- Lavanville (jalon 18 T14, jalon-18.md §4.1, §4.2) -------------------------------------


## Les cinq intérieurs peints de Lavanville (à la suite des autres, aucune scène existante n'est
## réécrite par défaut) : Centre et Boutique = définitions de Jadielle, trois maisons relues sur
## leur grille (enveloppe des maisons d'Argenta, 15 × 10 : même taille que les maisons d'Azuria et
## de Carmin ; le plan §4.1 dit « 10 × 8 » à tort, hypothèse notée au compte rendu du T14).
func _lavender_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = [
		_pokemon_center(&"lavender_center", "LavenderCenter", "Lavanville",
			[&"lavender_town", &"retour_centre"]),
		_poke_mart(&"lavender_mart", "LavenderMart", "Lavanville",
			[&"lavender_town", &"retour_boutique"]),
		_pokemon_house(), _lavender_house_1(), _lavender_house_2(),
	]
	return rooms


## Pièce de Lavanville relue sur sa grille : enveloppe des maisons d'Argenta, sortie PUSH ↓ vers
## `lavender_town` / [param spawn].
func _lavender_house(id: StringName, node: String, plan: String, walkable: String,
		spawn: StringName) -> Dictionary:
	return {
		"id": id, "node": node, "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_maison_argenta_coque.png",
		"title": "Lavanville", "light": &"interior_warm",
		"plan": PLANS_DIR + plan, "walkable": walkable,
		"spawns": {"entrance": Vector2i(7, 8)},
		"warps": _pewter_exits([Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)], spawn,
			&"lavender_town"),
	}


## Maison des Pokémon (`lavanville_maison_pokemon.txt`, dossier 21 §6.2) : cuisine, canapé,
## table à manger, deux paniers de Pokémon à l'ouest ; l'enfant, Rondoudou et Nidoran ♀ (cases `h`)
## = T18 ; M. Fuji est absent (« à la Tour »).
func _pokemon_house() -> Dictionary:
	var room := _lavender_house(&"pokemon_house", "PokemonHouse", "lavanville_maison_pokemon.txt",
		".Xh", &"retour_fuji")
	room["furniture"] = [
		[&"int_frigo_01", Rect2i(1, 3, 1, 1), "Fridge"],
		[&"int_cuisine_01", Rect2i(2, 3, 3, 1), "Kitchen"],
		[&"int_cuisiniere_hotte_01", Rect2i(5, 3, 1, 1), "Stove"],
		[&"int_canape_01", Rect2i(10, 3, 3, 1), "Sofa"],
		[&"int_chevet_lampe_01", Rect2i(13, 3, 1, 1), "Lamp"],
		[&"int_table_repas_01", Rect2i(9, 5, 3, 2), "DiningTable"],
		[&"int_plante", Rect2i(1, 7, 1, 1), "PlantWest"],
		[&"int_plante", Rect2i(13, 7, 1, 1), "PlantEast"],
	]
	room["props"] = [
		[&"int_panier_pokemon_01", Vector2i(2, 5), 5.85, "BasketA"],
		[&"int_panier_pokemon_01", Vector2i(3, 6), 6.85, "BasketB"],
	]
	room["rugs"] = [[&"int_tapis_plaid_01", Vector2(6.0, 6.2), "RugPlaid"]]
	return room


## Maison 1 (`lavanville_maison_1.txt`) : le mobilier de la maison du tailleur d'Argenta ; la
## vieille dame (case `h`) = T18.
func _lavender_house_1() -> Dictionary:
	var room := _lavender_house(&"lavender_house_1", "LavenderHouse1",
		"lavanville_maison_1.txt", ".Xh", &"retour_maison_1")
	room["furniture"] = _mason_furniture()
	return room


## Maison 2 (`lavanville_maison_2.txt`) : le mobilier de la maison d'Azuria ; le couple (cases
## `h`) = T18.
func _lavender_house_2() -> Dictionary:
	var room := _lavender_house(&"lavender_house_2", "LavenderHouse2",
		"lavanville_maison_2.txt", ".Xh", &"retour_maison_2")
	var azuria := _cerulean_house()
	room["furniture"] = azuria["furniture"]
	room["rugs"] = azuria["rugs"]
	return room


# --- Jalon 20 (T15) : Routes 7 et 8 ------------------------------------------------------------

## Postes de Safrania et bâtiments d'entrée du souterrain des Routes 7 et 8 (`jalon-20.md` §2.1,
## §2.2 ; grilles `poste_safrania.txt` et `souterrain_entree.txt`, une enveloppe pour les deux
## routes). La coque du poste du J15 (10 × 8, `_gate_room`) est gardée **telle quelle** (§2.2) :
## les grilles (12 × 10) s'y lisent décalées d'une case (porte côté route (4..5, 7), porte du
## nord ou escalier (4..5, 1..2)). Habitant (texte 10) et garde (texte 12) : PNJ des données (T17,
## T25).
func _routes_7_8_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = []
	for route: int in [7, 8]:
		rooms.append(_saffron_gate(route))
	for route: int in [7, 8]:
		rooms.append(_celadon_underground_gate(route))
	return rooms


## Coque commune (celle de `_gate_room`, J15) : sortie STEP_ON ↓ vers la Route [param route] /
## [param exit_spawn] ; arrivée `entrance` (4, 6), tournée ↑.
func _route_7_8_room(id: StringName, node: String, route: int, exit_spawn: StringName) \
		-> Dictionary:
	var route_map := StringName("route_%d" % route)
	return {
		"id": id, "node": node, "size": Vector2i(10, 8),
		"shell": "res://assets/world/interiors/int_poste_foret_coque.png",
		"title": "Route %d" % route, "light": &"interior_warm",
		"floor": Rect2i(1, 2, 8, 5),
		"doors": [Vector2i(4, 7), Vector2i(5, 7), Vector2i(4, 1), Vector2i(5, 1)],
		"props": [
			[&"int_meuble_bas_01", Vector2i(2, 2), 3.0, "LowCabinet"],
			[&"int_porte_manteau_01", Vector2i(8, 2), 3.0, "CoatRack"],
			[&"int_plante", Vector2i(1, 6), 7.0, "PlantWest"],
			[&"int_plante", Vector2i(8, 6), 7.0, "PlantEast"],
		],
		"spawns": {"entrance": Vector2i(4, 6)},
		"warps": [
			["ToRouteW", Vector2i(4, 7), STEP_ON, Vector2i.DOWN, route_map, exit_spawn,
				Vector2i.DOWN],
			["ToRouteE", Vector2i(5, 7), STEP_ON, Vector2i.DOWN, route_map, exit_spawn,
				Vector2i.DOWN],
		],
	}


## Poste de Safrania (grille `poste_safrania.txt`) : la porte de Safrania (4..5, 1), fermée par le
## garde (`saffron_guard`, `data/npcs/route_<n>_gate.json`) en (4, 2) et la barrière (plante) en
## (5, 2) ; le garde s'écarte en (3, 2) quand les postes s'ouvrent (T25, `saffron_gates_open`).
func _saffron_gate(route: int) -> Dictionary:
	var room := _route_7_8_room(StringName("route_%d_gate" % route), "Route%dGate" % route, route,
		&"from_gate")
	# Le garde s'écarte vers (3, 2) une fois la boisson donnée (T25, §2.16) : pas d'armoire basse.
	room["props"] = (room["props"] as Array).filter(func(prop: Array) -> bool:
		return prop[3] != "LowCabinet")
	(room["props"] as Array).append([&"int_plante", Vector2i(5, 2), 2.95, "Barrier"])
	(room["spawns"] as Dictionary)["north_door"] = Vector2i(4, 3)
	# Porte de Safrania : la ville (J26) / `from_gate_r<n>` dès que sa carte existe ; avant,
	# « Safrania — À venir » (jamais atteinte : le garde la ferme tant que les postes sont clos).
	var city := ResourceLoader.exists(MAPS_DIR + "saffron_city.tscn")
	for entry: Array in [["ToSaffronW", Vector2i(4, 1)], ["ToSaffronE", Vector2i(5, 1)]]:
		if city:
			(room["warps"] as Array).append([entry[0], entry[1], STEP_ON, Vector2i.UP,
				&"saffron_city", StringName("from_gate_r%d" % route), Vector2i.UP])
		else:
			(room["warps"] as Array).append([entry[0], entry[1], STEP_ON, Vector2i.UP, &"",
				&"north_door", Vector2i.DOWN, "Safrania"])
	return room


## Bâtiment d'entrée du souterrain (grille `souterrain_entree.txt`) : escalier descendant sur
## (4..5, 2), STEP_ON sans direction vers `underground_path_7_8` / `from_route_<n>_n|s` (« à
## venir » tant que la carte n'existe pas) ; retour du souterrain `from_underground` (4, 3), tourné
## ↓ ; panneau (texte 2) au mur du fond (7, 1), EXAMINER depuis (7, 2) tourné ↑.
func _celadon_underground_gate(route: int) -> Dictionary:
	var room := _route_7_8_room(StringName("route_%d_underground_gate" % route),
		"Route%dUndergroundGate" % route, route, &"from_underground")
	room["doors"] = [Vector2i(4, 7), Vector2i(5, 7)]
	(room["props"] as Array).append([&"int_escalier_descendant_01", Vector2i(5, 2), 3.0,
		"Stairs"])
	(room["spawns"] as Dictionary)["from_underground"] = Vector2i(4, 3)
	var built := ResourceLoader.exists(MAPS_DIR + "underground_path_7_8.tscn")
	var index := 0
	for suffix: String in ["n", "s"]:
		var cell := Vector2i(4 + index, 2)
		if built:
			(room["warps"] as Array).append(["ToUnderground" + suffix.to_upper(), cell, STEP_ON,
				Vector2i.ZERO, &"underground_path_7_8",
				StringName("from_route_%d_%s" % [route, suffix]), Vector2i.DOWN])
		else:
			(room["warps"] as Array).append(["ToUnderground" + suffix.to_upper(), cell, STEP_ON,
				Vector2i.ZERO, &"", &"from_underground", Vector2i.DOWN, "Passage souterrain"])
		index += 1
	room["interactables"] = [["UndergroundSign", Vector2i(7, 1), Vector2i.ONE,
		StringName("route_%d_underground_sign" % route), EXAMINE, Vector2i.UP]]
	return room


# --- Jalon 20 (T16) : Céladopole ---------------------------------------------------------------

const CELADON_TITLE := "Céladopole"
const INTERIORS_DIR := "res://assets/world/interiors/"
## Étages du grand magasin : [identifiant, grille].
const DEPT_FLOORS: Array = [
	["gf", "celadopole_magasin_rdc.txt"], ["2f", "celadopole_magasin_2e.txt"],
	["3f", "celadopole_magasin_3e.txt"], ["4f", "celadopole_magasin_4e.txt"],
	["5f", "celadopole_magasin_5e.txt"],
]
## Comptoirs parlants (T17) : on parle au vendeur par-dessus le comptoir, depuis la case devant lui
## (tourné ↑). [nœud, case de gauche du comptoir, largeur, dialogue du vendeur] par étage.
const DEPT_COUNTERS: Dictionary = {
	"gf": [["HostessCounter", Vector2i(7, 5), 6, &"celadon_dept_hostess"]],
	"2f": [["ClerkCounterA", Vector2i(6, 5), 3, &"celadon_dept_2f_clerk"],
		["ClerkCounterB", Vector2i(11, 5), 3, &"celadon_dept_2f_clerk_tm"]],
	"4f": [["ClerkCounterA", Vector2i(6, 5), 3, &"celadon_dept_4f_clerk"],
		["ClerkCounterB", Vector2i(11, 5), 3, &"celadon_dept_4f_clerk_stones"]],
	"5f": [["ClerkCounter", Vector2i(9, 5), 3, &"celadon_dept_5f_clerk"]],
}
## Distributeurs du toit (T17) : [nœud, case, dialogue] (EXAMINER depuis la case du sud, ↑).
const ROOF_DISPENSERS: Array = [
	["DispenserWater", Vector2i(10, 2), &"celadon_dept_roof_water"],
	["DispenserSoda", Vector2i(12, 2), &"celadon_dept_roof_soda"],
	["DispenserLemonade", Vector2i(14, 2), &"celadon_dept_roof_lemonade"],
]
## Étages de la Résidence : [identifiant, grille].
const MANSION_FLOORS: Array = [
	["gf", "celadopole_residence_rdc.txt"], ["1f", "celadopole_residence_1er.txt"],
	["2f", "celadopole_residence_2e.txt"], ["3f", "celadopole_residence_3e.txt"],
]


## Les dix-sept intérieurs de Céladopole construits ici (jalon-20.md §2.2, grilles
## `celadopole_*.txt`) : Centre (définition commune), grand magasin (cinq étages, toit, cabine
## d'ascenseur), Résidence (quatre niveaux, toit, maison du toit), maison du chef, restaurant et
## hôtel. Titre « Céladopole » ; coques peintes de la série 22 bis (`int_<carte>_coque.png`). Les PNJ, vendeurs,
## distributeurs, Évoli et la Poké Ball viennent au T17 ; le moteur d'ascenseur au T13.
func _celadon_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = []
	var center := _pokemon_center(&"celadon_center", "CeladonCenter", CELADON_TITLE,
		[&"celadon_city", &"from_center_e"])
	center["exit_spawns"] = _celadon_exit_spawns("center", 3)
	rooms.append(center)
	for index: int in DEPT_FLOORS.size():
		rooms.append(_celadon_dept_floor(index))
	rooms.append(_celadon_dept_roof())
	rooms.append(_celadon_dept_elevator())
	for index: int in MANSION_FLOORS.size():
		rooms.append(_celadon_mansion_floor(index))
	rooms.append(_celadon_mansion_roof())
	rooms.append(_celadon_mansion_roof_house())
	for entry: Array in [[&"celadon_restaurant", "CeladonRestaurant",
			"celadopole_restaurant.txt", "restaurant"],
			[&"celadon_chief_house", "CeladonChiefHouse", "celadopole_maison_chef.txt", "chief"],
			[&"celadon_hotel", "CeladonHotel", "celadopole_hotel.txt", "hotel"]]:
		rooms.append(_celadon_small_room(entry[0], entry[1], entry[2], entry[3]))
	return rooms


## Pièce relue sur sa grille : coque peinte `int_<id>_coque.png` ; [param light] `interior_warm`
## (toits : `golden_hour`, ciel ouvert).
func _celadon_room(id: StringName, node: String, plan: String, walkable: String,
		light: StringName = &"interior_warm") -> Dictionary:
	var grid := PlanGrid.new()
	if not grid.load_file(PLANS_DIR + plan):
		push_error("%s : grille %s illisible (%s)" % [id, plan, grid.error])
		_errors += 1
	return {
		"id": id, "node": node, "size": Vector2i(grid.width, grid.height),
		"shell": INTERIORS_DIR + "int_%s_coque.png" % id,
		"title": CELADON_TITLE, "light": light,
		"plan": PLANS_DIR + plan, "walkable": walkable,
		"spawns": {}, "warps": [], "interactables": [],
	}


## Arrivées d'une porte de la ville : `from_<base>_w` à gauche, `_e` à droite (la case du milieu
## d'une sortie à trois cases sort à gauche).
func _celadon_exit_spawns(base: String, count: int) -> Array:
	var names: Array = []
	for index: int in count:
		names.append(StringName("from_%s_%s" % [base, "e" if index == count - 1 else "w"]))
	return names


## Sortie PUSH ↓ vers la ville : [param cells] → `from_<base>_w|e`.
func _celadon_exit_warps(cells: Array, base: String) -> Array:
	var warps: Array = []
	var spawns := _celadon_exit_spawns(base, cells.size())
	for index: int in cells.size():
		warps.append(["Exit%d" % index, cells[index], PUSH, Vector2i.DOWN, &"celadon_city",
			spawns[index], Vector2i.DOWN])
	return warps


## Escalier : cases sur la rangée 2, STEP_ON sans direction (J12), arrivée tournée ↓.
func _celadon_stairs(prefix: String, x: int, target: StringName, spawn: StringName) -> Array:
	var warps: Array = []
	for index: int in 2:
		warps.append(["%s%d" % [prefix, index], Vector2i(x + index, 2), STEP_ON, Vector2i.ZERO,
			target, spawn, Vector2i.DOWN])
	return warps


## Étage du grand magasin (une enveloppe par étage, un accent de couleur chacun) : escaliers à
## l'ouest (S montant (2..3, 2), Z descendant (4..5, 2)), porte de l'ascenseur à l'est (16..17, 2),
## arrivées `from_up` (devant S), `from_down` (devant Z), `from_elevator` (devant la porte).
func _celadon_dept_floor(index: int) -> Dictionary:
	var floor_id: String = DEPT_FLOORS[index][0]
	var room := _celadon_room(StringName("celadon_dept_" + floor_id),
		"CeladonDept" + floor_id.to_upper(), DEPT_FLOORS[index][1], ".XSZV")
	var spawns: Dictionary = room["spawns"]
	var warps: Array = room["warps"]
	spawns["from_up"] = Vector2i(2, 3)
	spawns["from_elevator"] = Vector2i(16, 3)
	if index > 0:
		spawns["from_down"] = Vector2i(4, 3)
		warps.append_array(_celadon_stairs("StairsDown", 4,
			StringName("celadon_dept_" + DEPT_FLOORS[index - 1][0]), &"from_up"))
	var above: StringName = &"celadon_dept_roof" if index == DEPT_FLOORS.size() - 1 \
		else StringName("celadon_dept_" + DEPT_FLOORS[index + 1][0])
	warps.append_array(_celadon_stairs("StairsUp", 2, above, &"from_down"))
	for door: int in 2:
		warps.append(["Elevator%d" % door, Vector2i(16 + door, 2), STEP_ON, Vector2i.UP,
			&"celadon_dept_elevator", &"entrance", Vector2i.UP])
	if index == 0:
		spawns["entrance"] = Vector2i(9, 11)
		warps.append_array(_celadon_exit_warps([Vector2i(9, 11), Vector2i(10, 11)], "dept"))
		# Tableau des étages (texte 22), lu depuis la case devant lui, tourné ↑.
		room["interactables"] = [["FloorBoard", Vector2i(9, 2), Vector2i(2, 1),
			&"celadon_dept_board", EXAMINE, Vector2i.UP]]
	for counter: Array in DEPT_COUNTERS.get(floor_id, []):
		(room["interactables"] as Array).append([counter[0], counter[1],
			Vector2i(counter[2], 1), counter[3], TALK, Vector2i.UP])
	return room


## Toit-terrasse du grand magasin (carte intérieure à ciel ouvert, sans compagnon) : on y monte par
## l'escalier du 5e (jamais par l'ascenseur) ; trois distributeurs (EXAMINER, T17) ; la fillette
## est un PNJ des données.
func _celadon_dept_roof() -> Dictionary:
	var room := _celadon_room(&"celadon_dept_roof", "CeladonDeptRoof",
		"celadopole_magasin_toit.txt", ".XSZV", &"golden_hour")
	(room["spawns"] as Dictionary)["from_down"] = Vector2i(2, 3)
	(room["warps"] as Array).append_array(_celadon_stairs("StairsDown", 2, &"celadon_dept_5f",
		&"from_up"))
	for dispenser: Array in ROOF_DISPENSERS:
		(room["interactables"] as Array).append([dispenser[0], dispenser[1], Vector2i.ONE,
			dispenser[2], EXAMINE, Vector2i.UP])
	return room


## Cabine de l'ascenseur (6 × 6) : la sortie ramène au premier étage (RdC) ; le moteur
## (`ElevatorDirector`, T13) la réoriente vers l'étage courant. Panneau d'étages examiné depuis
## (2..3, 2), tourné ↑ : dialogue `elevator_panel` (T13 : `open_elevator`, un seul pour toutes les
## cabines).
func _celadon_dept_elevator() -> Dictionary:
	var room := _celadon_room(&"celadon_dept_elevator", "CeladonDeptElevator",
		"celadopole_magasin_ascenseur.txt", ".X")
	(room["spawns"] as Dictionary)["entrance"] = Vector2i(2, 4)
	var warps: Array = room["warps"]
	for index: int in 2:
		warps.append(["Exit%d" % index, Vector2i(2 + index, 4), PUSH, Vector2i.DOWN,
			&"celadon_dept_gf", &"from_elevator", Vector2i.DOWN])
	room["interactables"] = [["ElevatorPanel", Vector2i(2, 1), Vector2i(2, 1),
		&"elevator_panel", EXAMINE, Vector2i.UP]]
	return room


## Niveau de la Résidence : hall (RdC, sortie PUSH ↓ vers la ville) puis paliers ; escaliers S
## (2..3, 2) montants, Z (4..5, 2) descendants. 3e : seulement Z, et la porte « BUREAU PRIVÉ »
## (8, 2), examinée depuis (8, 3), sans warp.
func _celadon_mansion_floor(index: int) -> Dictionary:
	var floor_id: String = MANSION_FLOORS[index][0]
	var room := _celadon_room(StringName("celadon_mansion_" + floor_id),
		"CeladonMansion" + floor_id.to_upper(), MANSION_FLOORS[index][1], ".XSZ")
	var spawns: Dictionary = room["spawns"]
	var warps: Array = room["warps"]
	if index < MANSION_FLOORS.size() - 1:
		spawns["from_up"] = Vector2i(2, 3)
		warps.append_array(_celadon_stairs("StairsUp", 2,
			StringName("celadon_mansion_" + MANSION_FLOORS[index + 1][0]), &"from_down"))
	if index > 0:
		spawns["from_down"] = Vector2i(4, 3)
		warps.append_array(_celadon_stairs("StairsDown", 4,
			StringName("celadon_mansion_" + MANSION_FLOORS[index - 1][0]), &"from_up"))
	else:
		spawns["entrance"] = Vector2i(7, 9)
		warps.append_array(_celadon_exit_warps([Vector2i(7, 9), Vector2i(8, 9)], "mansion"))
	if index == MANSION_FLOORS.size() - 1:
		room["interactables"] = [["PrivateOffice", Vector2i(8, 2), Vector2i.ONE,
			&"celadon_mansion_office_door", EXAMINE, Vector2i.UP]]
	return room


## Toit de la Résidence : on y entre seulement par l'escalier de service de la ville (Z (2..3, 2)
## le ramène, arrivées `from_service_w|e`) ; la maison du toit (porte D (10, 5), emprise 5 × 4).
func _celadon_mansion_roof() -> Dictionary:
	var room := _celadon_room(&"celadon_mansion_roof", "CeladonMansionRoof",
		"celadopole_residence_toit.txt", ".ZD", &"golden_hour")
	var spawns: Dictionary = room["spawns"]
	spawns["from_service"] = Vector2i(2, 3)
	spawns["from_house"] = Vector2i(10, 6)
	var warps: Array = room["warps"]
	var back := _celadon_exit_spawns("service", 2)
	for index: int in 2:
		warps.append(["ServiceStairs%d" % index, Vector2i(2 + index, 2), STEP_ON, Vector2i.ZERO,
			&"celadon_city", back[index], Vector2i.DOWN])
	warps.append(["DoorHouse", Vector2i(10, 5), STEP_ON, Vector2i.UP,
		&"celadon_mansion_roof_house", &"entrance", Vector2i.UP])
	room["props"] = [[&"bldg_maison_toit_01", Vector2i(10, 5), 5.9, "RoofHouse"]]
	return room


## Maison du toit (10 × 8) : la Poké Ball d'Évoli (4, 3) est le PNJ `eevee_ball` des données (T17).
func _celadon_mansion_roof_house() -> Dictionary:
	var room := _celadon_room(&"celadon_mansion_roof_house", "CeladonMansionRoofHouse",
		"celadopole_residence_maison_toit.txt", ".X")
	(room["spawns"] as Dictionary)["entrance"] = Vector2i(4, 6)
	for index: int in 2:
		(room["warps"] as Array).append(["Exit%d" % index, Vector2i(4 + index, 6), PUSH,
			Vector2i.DOWN, &"celadon_mansion_roof", &"from_house", Vector2i.DOWN])
	return room


## Restaurant, maison du chef, hôtel (15 × 10, sortie à trois cases (6..8, 8) vers la ville ;
## [param base] : début du nom des arrivées de la ville). La maison du chef n'a qu'une porte :
## `from_chief`.
func _celadon_small_room(id: StringName, node: String, plan: String, base: String) -> Dictionary:
	var room := _celadon_room(id, node, plan, ".X")
	(room["spawns"] as Dictionary)["entrance"] = Vector2i(7, 8)
	# Comptoirs parlants (T17) : réception de l'hôtel (5..9, 4), serveur du restaurant (2..5, 4).
	if base == "hotel":
		(room["interactables"] as Array).append(["ReceptionCounter", Vector2i(5, 4),
			Vector2i(5, 1), &"celadon_hotel_reception", TALK, Vector2i.UP])
	elif base == "restaurant":
		(room["interactables"] as Array).append(["WaiterCounter", Vector2i(2, 4),
			Vector2i(4, 1), &"celadon_restaurant_waiter", TALK, Vector2i.UP])
	var cells: Array = [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
	if base == "chief":
		for index: int in cells.size():
			(room["warps"] as Array).append(["Exit%d" % index, cells[index], PUSH,
				Vector2i.DOWN, &"celadon_city", &"from_chief", Vector2i.DOWN])
	else:
		(room["warps"] as Array).append_array(_celadon_exit_warps(cells, base))
	return room


# --- Jalon 29 : poste de la Ligue, hall du Plateau Indigo -----------------------------------------


func _j29_rooms() -> Array[Dictionary]:
	return [_route_22_gate(), _indigo_plateau_lobby()]


## Poste de la Ligue (jalon 29, `tools/plans/poste_ligue.txt`, Q29-1 : Badge Roche, comme RB
## Route22Gate) : l'enveloppe et les meubles des postes de la Forêt de Jade ; porte sud → partie
## ouest de la Route 22 (devant la porte), ouverture nord → Route 23. Garde (6, 2) dans
## `data/npcs/route_22_gate.json` ; déclencheur (4..5, 2) toutes directions → scène
## `route_22_gate_check` (Badge Roche : T29-04 et recul, ou T29-05 une fois).
func _route_22_gate() -> Dictionary:
	return {
		"id": &"route_22_gate", "node": "Route22Gate", "size": Vector2i(10, 8),
		"shell": "res://assets/world/interiors/int_poste_foret_coque.png",
		"title": "Route 22", "light": &"interior_warm",
		"floor": Rect2i(1, 2, 8, 5),
		"doors": [Vector2i(4, 1), Vector2i(5, 1), Vector2i(4, 7), Vector2i(5, 7)],
		"props": [
			[&"int_meuble_bas_01", Vector2i(2, 2), 3.0, "LowCabinet"],
			[&"int_porte_manteau_01", Vector2i(8, 2), 3.0, "CoatRack"],
			[&"int_plante", Vector2i(1, 6), 7.0, "PlantWest"],
			[&"int_plante", Vector2i(8, 6), 7.0, "PlantEast"],
		],
		"spawns": {"entrance": Vector2i(4, 6), "from_route_23": Vector2i(4, 2)},
		"warps": [
			["ToRoute22W", Vector2i(4, 7), STEP_ON, Vector2i.DOWN, &"route_22_west",
				&"from_gate", Vector2i.DOWN],
			["ToRoute22E", Vector2i(5, 7), STEP_ON, Vector2i.DOWN, &"route_22_west",
				&"from_gate", Vector2i.DOWN],
			["ToRoute23W", Vector2i(4, 1), STEP_ON, Vector2i.UP, &"route_23", &"from_gate",
				Vector2i.UP],
			["ToRoute23E", Vector2i(5, 1), STEP_ON, Vector2i.UP, &"route_23", &"from_gate",
				Vector2i.UP],
		],
		"triggers": [["BadgeCheck", Vector2i(4, 2), Vector2i(2, 1), &"route_22_gate_check",
			Vector2i.ZERO]],
	}


## Hall du Plateau Indigo (jalon 29, `jalon-29.md` §2.5) : le Centre Pokémon (même enseigne
## partout) avec, en plus, le marchand (13, 5) tourné vers l'ouest (Boutique `indigo_plateau_lobby`,
## RB), l'hôte (3, 6) (T29-10) et, au nord-est, la porte de la Ligue (12, 3) : « Ligue Pokémon —
## À venir » jusqu'au J30 (il en change la cible). Aucun dialogue ni soin ne lance la Ligue.
## Point de repos `indigo_plateau_lobby` (`data/world/rest_points.json`).
func _indigo_plateau_lobby() -> Dictionary:
	var room := _pokemon_center(&"indigo_plateau_lobby", "IndigoPlateauLobby", "Plateau Indigo",
		[&"indigo_plateau", &"from_lobby"])
	var props: Array = []
	for prop: Array in room["props"]:
		if prop[3] != "PlantNorthEast":
			props.append(prop)
	room["props"] = props
	room["warps"] = [["ToLeague", Vector2i(12, 3), STEP_ON, Vector2i.UP, &"", &"league_door",
		Vector2i.DOWN, "Ligue Pokémon"]]
	(room["spawns"] as Dictionary)["league_door"] = Vector2i(12, 4)
	return room
