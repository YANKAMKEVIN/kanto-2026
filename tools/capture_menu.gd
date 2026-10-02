extends SceneTree
## Captures du tableau de bord du Menu Dresseur (jalon 6, T3), avec des vues fabriquées, posé sur
## le vrai monde (Boot sur la Route 1) :
##   dashboard_5          cinq cartes (sans Pokédex), sans vus · capturés
##   dashboard_6          six cartes, vus · capturés, Pokémon K.O.
##   dashboard_no_team    sans équipe (pas de carte du Pokémon de tête), sans objectif
##   hud_button           exploration : le bouton Menu en haut à droite (menu fermé)
##
## Sur le Mac, en 2340×1080 :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 900 \
##     -s res://tools/capture_menu.gd -- --out=build/captures/jalon06_t3
## (1920x1080 pour l'autre largeur de référence.)

const BOOT_SCENE: String = "res://game/boot.tscn"
const MENU_SCENE: String = "res://game/ui/menu/trainer_menu.tscn"

var _boot: Node
var _menu: TrainerMenu
var _out_dir: String = "build/captures/jalon06_t3"
var _suffix: String = ""
var _frame: int = 0
var _step: int = 0
var _scenarios: Array[String] = ["hud_button", "dashboard_5", "dashboard_6", "dashboard_no_team"]
var _current: String = ""
var _wait: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--suffix="):
			_suffix = arg.trim_prefix("--suffix=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"jadielle_soon_w")
	root.add_child(_boot)
	_menu = (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	_menu.speed_scale = 0.0
	root.add_child(_menu)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _frame < 40:
		return
	if _current.is_empty():
		if _scenarios.is_empty():
			quit()
			return
		_current = _scenarios.pop_front()
		_wait = 0
		_begin(_current)
		return
	_wait += 1
	if _wait == 12:
		_save(_current)
		_current = ""
		if _menu.is_open():
			_menu.close_animated()


func _begin(scenario: String) -> void:
	match scenario:
		"hud_button":
			return
		"dashboard_5":
			_open(_view(5, true, false, ""))
		"dashboard_6":
			_open(_view(6, true, true, "27 vus · 14 capturés"))
		"dashboard_no_team":
			_open(_view(5, false, false, ""))


func _open(view: DashboardView) -> void:
	_menu.open_animated()
	_menu.show_dashboard(view)


func _view(card_count: int, with_lead: bool, fainted: bool, dex: String) -> DashboardView:
	var view := DashboardView.new()
	view.zone_name = "Route 1"
	view.player_name = "Kevin"
	view.player_title = "Dresseur Pokémon"
	view.play_time_text = "12 h 43"
	view.dex_text = dex
	view.objective_text = "Objectif : rejoindre Jadielle" if with_lead else ""
	if with_lead:
		var lead := TeamMemberView.new()
		lead.species_id = &"charmander"
		lead.display_name = "Salamèche"
		lead.gender = BattleCardView.Gender.MALE
		lead.level = 14
		lead.max_hp = 39
		lead.hp = 0 if fainted else 39
		lead.status_text = TeamMemberView.STATUS_FAINTED if fainted else ""
		if not fainted:
			lead.hp = 31
		view.lead = lead
	var texts: Dictionary = {
		&"team": ["Équipe", "Tes Pokémon et leurs capacités."],
		&"pokedex": ["Pokédex", "Tes découvertes dans la région de Kanto."],
		&"bag": ["Sac", "Utilise et range tes objets."],
		&"map": ["Carte", "Kanto et tes découvertes."],
		&"trainer": ["Dresseur", "Ton profil et ton parcours."],
		&"settings": ["Paramètres", "Jeu, commandes, graphismes et accessibilité."],
	}
	var order: Array[StringName] = [&"team", &"pokedex", &"bag", &"map", &"trainer", &"settings"]
	if card_count == 5:
		order.erase(&"pokedex")
	for screen: StringName in order:
		view.cards.append(MenuCardView.new(screen, texts[screen][0], texts[screen][1]))
	return view


func _save(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + _suffix + ".png")
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	image.save_png(path)
	print("CAPTURE %s %s" % [path, image.get_size()])
