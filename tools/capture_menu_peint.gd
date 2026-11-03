extends SceneTree
## Captures du chantier « Menu Dresseur peint » (`tools/art/menu_peint.py`) sur le vrai Boot,
## sauvegarde et réglages en mémoire (le vrai `user://` n'est jamais lu ni écrit). Partie de Kevin
## (fixture v1) ; état de capture posé après le chargement : badges levés (3 ou 8, avec leur moment
## dans la ville de l'arène), toutes les cartes de zones.json découvertes, objets repeints au Sac.
##   trainer               écran Dresseur : badges peints obtenus et gabarits « ??? »
##   trainer_moments       frise défilée jusqu'en bas : moments des badges, emblèmes peints
##   dashboard             tableau de bord : ligne des badges avec le dernier badge peint
##   bag_field[_repel]     Sac, onglet AVENTURE (vitamines, PP, Repousses)
##   bag_key               Sac, OBJETS CLÉS (Cherch'Objet, Multi Exp)
##   map_<zone>            Carte du menu, panneau de la zone et son aperçu peint
## Avec --reliquats (reliquats du 2026-11-02, `tools/art/menu_peint_reliquats.py`) : badges levés
## dans la sauvegarde **avant** le titre, puis
##   title_continue        écran titre, carte Continuer et l'icône du dernier badge obtenu
##   bag_ball, bag_tm      Sac, onglets BALLS (Master Ball) et CT (disques par type)
##   map_full              Carte entière, sans zone choisie (étiquettes sans chevauchement)
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_menu_peint.gd \
##     -- --out=build/captures/menu_peint [--badges=3] [--reliquats]
## Ne référence aucune classe du jeu par son nom (les autoloads ne sont pas encore là quand un
## script `-s` se compile) : tout passe par load() et call().

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const ROUTE: String = "res://game/systems/menu/menu_route.gd"
const SAVE_PATH: String = "user://cap_mp_save.json"
const ABSENT: String = "user://cap_mp_absent.json"
const FIXTURE: String = "res://tests/fixtures/save/v1_after_capture.json"
const BADGES: Array[StringName] = [&"boulder", &"cascade", &"thunder", &"rainbow", &"soul",
	&"marsh", &"volcano", &"earth"]
const BADGE_MAPS: Array[StringName] = [&"pewter_city", &"cerulean_city", &"vermilion_city",
	&"celadon_city", &"fuchsia_city", &"saffron_city", &"cinnabar_island", &"viridian_city"]
const ITEMS: Array[StringName] = [&"protein", &"iron", &"calcium", &"carbos", &"hp_up", &"pp_up",
	&"ether", &"max_ether", &"elixir", &"max_elixir", &"repel", &"super_repel", &"max_repel",
	&"itemfinder", &"exp_all"]
## Reliquats : Balls et CT de types variés au Sac.
const RELIQUAT_ITEMS: Array[StringName] = [&"poke_ball", &"great_ball", &"ultra_ball",
	&"master_ball", &"tm01", &"tm06", &"tm11", &"tm13", &"tm17", &"tm21", &"tm23", &"tm24",
	&"tm26", &"tm29", &"tm38", &"tm43", &"tm48", &"hm01"]
const MAP_ZONES: Array[StringName] = [&"cerulean_city", &"mt_moon", &"ss_anne", &"route_12",
	&"indigo_plateau"]

var _out_dir: String = "build/captures/menu_peint"
var _badges: int = 8
var _reliquats: bool = false
var _boot: Node
var _fs: RefCounted


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--badges="):
			_badges = clampi(int(arg.trim_prefix("--badges=")), 0, 8)
		elif arg == "--reliquats":
			_reliquats = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_fs = (load(MEMORY_FS) as GDScript).new()
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	(load(SAVE) as GDScript).call(&"upgrade", content)
	if _reliquats:
		for i: int in _badges:
			(content["flags"] as Array).append("badge_" + String(BADGES[i]))
	var save: RefCounted = (load(SAVE) as GDScript).new(_fs, SAVE_PATH)
	save.call(&"write", content)
	var store: RefCounted = (load(STORE) as GDScript).new(_fs, "user://cap_mp.json")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", (load(SAVE) as GDScript).new(_fs, SAVE_PATH))
	_boot.set(&"settings_store", store)
	_boot.set(&"debug_start_path", ABSENT)
	_boot.set(&"debug_unlocks_path", ABSENT)
	var boot := _boot
	boot.tree_entered.connect(func() -> void: current_scene = boot, CONNECT_ONE_SHOT)
	root.add_child(boot)
	await _frames(60)
	var screen: Node = _boot.call(&"get_opening").call(&"get_screen")
	if _reliquats:
		await _shot("title_continue")
	screen.call(&"get_entry_button", &"continue").pressed.emit()
	for i: int in 600:
		await process_frame
		if _boot.call(&"is_stable"):
			break
	await _frames(30)
	_prepare_state()
	var route := load(ROUTE) as GDScript
	var menu: Node = _boot.call(&"get_menu_director")
	var trainer_menu: Node = _boot.call(&"get_trainer_menu")
	trainer_menu.set(&"speed_scale", 0.0)
	if _reliquats:
		await _run_reliquats(menu, trainer_menu, route)
		quit()
		return
	menu.call(&"open", route.call(&"trainer"))
	await _frames(30)
	await _shot("trainer")
	var trainer: Node = trainer_menu.call(&"get_trainer")
	(trainer.call(&"get_scroll") as ScrollContainer).scroll_vertical = 100000
	await _frames(10)
	await _shot("trainer_moments")
	menu.call(&"handle_back")
	await _frames(20)
	await _shot("dashboard")
	menu.call(&"go", route.call(&"bag"))
	await _frames(30)
	var bag: Node = trainer_menu.call(&"get_bag")
	for shot: Array in [[&"field", &"protein", "bag_field"], [&"field", &"max_repel",
			"bag_field_repel"], [&"key", &"itemfinder", "bag_key"]]:
		bag.call(&"open_category", shot[0])
		await _frames(10)
		bag.call(&"select_item", shot[1])
		await _frames(20)
		await _shot(shot[2])
	menu.call(&"handle_back")
	await _frames(20)
	for zone: StringName in MAP_ZONES:
		menu.call(&"go", route.call(&"map", zone))
		await _frames(30)
		await _shot("map_" + String(zone))
		menu.call(&"handle_back")
		await _frames(20)
	quit()


## Reliquats : Sac (Balls, CT) puis Carte entière.
func _run_reliquats(menu: Node, trainer_menu: Node, route: GDScript) -> void:
	var bag_state: Object = root.get_node("GameState").get(&"bag")
	for item: StringName in RELIQUAT_ITEMS:
		bag_state.call(&"add", item, 1)
	menu.call(&"open", route.call(&"bag"))
	await _frames(30)
	var bag: Node = trainer_menu.call(&"get_bag")
	for shot: Array in [[&"ball", &"master_ball", "bag_ball"], [&"tm", &"tm13", "bag_tm"]]:
		bag.call(&"open_category", shot[0])
		await _frames(10)
		bag.call(&"select_item", shot[1])
		await _frames(20)
		await _shot(shot[2])
	menu.call(&"handle_back")
	await _frames(20)
	menu.call(&"go", route.call(&"map"))
	await _frames(30)
	await _shot("map_full")


## Badges, moments, cartes découvertes et objets (état de capture seulement).
func _prepare_state() -> void:
	var state: Node = root.get_node("GameState")
	var flags: Object = state.get(&"flags")
	var moment_script := load("res://game/systems/menu/badge_moment.gd") as GDScript
	for i: int in _badges:
		flags.call(&"set_flag", StringName("badge_" + String(BADGES[i])))
		state.call(&"record_moment", moment_script.get(&"TYPE"), BADGE_MAPS[i],
			moment_script.call(&"details", BADGES[i], state.get(&"party")))
	flags.call(&"set_flag", &"pokedex_activated")
	var zones: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/world/zones.json"))["zones"]
	for zone: String in zones:
		for map_id: String in zones[zone].get("maps", []):
			state.call(&"discover_map", StringName(map_id))
	var bag: Object = state.get(&"bag")
	for item: StringName in ITEMS:
		bag.call(&"add", item, 3)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	var path := "%s/%s_%db.png" % [_out_dir, name, _badges]
	root.get_texture().get_image().save_png(path)
	print("capture : ", path)
