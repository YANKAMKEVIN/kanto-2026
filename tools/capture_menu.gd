extends SceneTree
## Captures du tableau de bord du Menu Dresseur (jalon 6, T3), avec des vues fabriquées, posé sur
## le vrai monde (Boot sur la Route 1) :
##   dashboard_5          cinq cartes (sans Pokédex), sans vus · capturés
##   dashboard_6          six cartes, vus · capturés, Pokémon K.O.
##   dashboard_no_team    sans équipe (pas de carte du Pokémon de tête), sans objectif
##   hud_button           exploration : le bouton Menu en haut à droite (menu fermé)
## Équipe (T7, avec --only=team,team_sheet_moves,team_history,team_move_mode) :
##   team                 Aperçu de Salamèche (favori), Roucool, Rattata K.O., trois vides
##   team_sheet_moves     onglet Capacités, fiche de la première capacité ouverte
##   team_history         onglet Histoire
##   team_move_mode       DÉPLACER actif sur Roucool
## Sac (T11, avec --only=bag,bag_use,bag_result,bag_from_team) :
##   bag                  SOINS ouvert, Potion aperçue (favori), cartes, tri
##   bag_use              le choix du Pokémon après UTILISER (un membre à PV pleins, un K.O.)
##   bag_result           après un usage : « +20 PV — … » et UTILISER À NOUVEAU
##   bag_from_team        ouvert depuis la fiche Équipe de Salamèche (« Pour Salamèche »)
## Pokédex (T15, avec --only=dex_grid,dex_sheet_caught,dex_sheet_seen,dex_habitat,dex_search_empty
## ,dex_evolution,dex_notes) : vraies vues de PokedexQuery sur un Pokédex de test
##   dex_grid             grille seule (fiche fermée), 151 cases dont 6 connues
##   dex_sheet_caught     fiche de Salamèche (capturé) : Aperçu complet
##   dex_sheet_seen       fiche de Carapuce (seulement vu) : ni types, ni taille, ni poids
##   dex_habitat          filtre HABITATS (Route 1), fiche de Roucool, onglet Habitat
##   dex_search_empty     recherche sans résultat
##   dex_evolution / dex_notes   onglets Évolution et Observations de Salamèche / Roucool
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
## Image (à 30 i/s) de la capture du scénario courant (12 par défaut ; plus tôt pour les animations).
var _save_wait: int = 12


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--suffix="):
			_suffix = arg.trim_prefix("--suffix=")
		elif arg.begins_with("--only="):
			_scenarios.clear()
			for scenario: String in arg.trim_prefix("--only=").split(","):
				_scenarios.append(scenario)
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
		_save_wait = 12
		_menu.speed_scale = 0.0
		_begin(_current)
		return
	_wait += 1
	if _wait == _save_wait:
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
		"header_team":
			_open(_view(5, true, false, ""))
			_menu.show_team(_team_view(), 0)
		"team", "team_sheet_moves", "team_history", "team_move_mode":
			_team_scenario(scenario)
		"dex_grid", "dex_sheet_caught", "dex_sheet_seen", "dex_habitat", "dex_search_empty", \
		"dex_evolution", "dex_notes":
			_dex_scenario(scenario)
		"bag", "bag_use", "bag_result", "bag_from_team", "bag_refuse", "bag_heal_mid", "bag_heal_end":
			_bag_scenario(scenario)


## Pokédex du menu : vraies vues de PokedexQuery sur un Pokédex de test (la partie de Kevin à la
## fin du J5, plus Bulbizarre capturé et Reptincel vu).
func _dex_scenario(scenario: String) -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := PokedexLibrary.new()
	library.load_file()
	library.check_references(data)
	var zones := ZoneLibrary.new()
	zones.load_file()
	var dex := Pokedex.new()
	dex.mark_caught(&"charmander", &"oak_lab", "2026-09-30T10:00:00")
	dex.mark_caught(&"bulbasaur", &"oak_lab", "2026-09-30T10:01:00")
	dex.mark_seen(&"squirtle", &"oak_lab", "2026-09-30T10:05:00")
	dex.mark_seen(&"pidgey", &"pallet_town", "2026-10-01T09:00:00")
	dex.mark_caught(&"pidgey", &"pallet_town", "2026-10-01T09:01:00")
	dex.mark_seen(&"rattata", &"route_1", "2026-10-02T18:00:00")
	dex.mark_caught(&"rattata", &"route_1", "2026-10-02T18:02:00")
	dex.mark_seen(&"pidgey", &"route_1", "2026-10-02T18:10:00")
	dex.mark_seen(&"charmeleon", &"route_1", "2026-10-02T18:20:00")
	PokedexNotes.refresh(dex, library, null)
	var filter := PokedexQuery.Filter.ALL
	var zone := &""
	var text := ""
	var species := &"charmander"
	match scenario:
		"dex_sheet_seen":
			species = &"squirtle"
		"dex_habitat":
			filter = PokedexQuery.Filter.HABITAT
			zone = &"route_1"
			species = &"pidgey"
		"dex_search_empty":
			text = "zzz"
		"dex_notes":
			species = &"pidgey"
	var grid := PokedexQuery.grid(dex, data, library, zones, filter, zone, &"", text)
	_menu.open_animated()
	_menu.show_pokedex(grid)
	if scenario == "dex_grid" or scenario == "dex_search_empty":
		return
	_menu.show_pokedex_sheet(PokedexQuery.sheet(species, dex, data, library, zones))
	var sheet := _menu.get_pokedex().get_sheet()
	match scenario:
		"dex_habitat":
			sheet.select_tab(PokedexSheet.Tab.HABITAT)
		"dex_evolution":
			sheet.select_tab(PokedexSheet.Tab.EVOLUTION)
		"dex_notes":
			sheet.select_tab(PokedexSheet.Tab.NOTES)


func _team_scenario(scenario: String) -> void:
	var move_mode := scenario == "team_move_mode"
	_menu.open_animated()
	_menu.show_team(_team_view(), 1 if move_mode else 0)
	var team := _menu.get_team()
	match scenario:
		"team_sheet_moves":
			team.get_sheet().select_tab(PokemonSheet.Tab.MOVES)
			team.get_sheet().get_move_cards()[0].tapped.emit()
		"team_history":
			team.get_sheet().select_tab(PokemonSheet.Tab.HISTORY)
		"team_move_mode":
			team.get_move_button().pressed.emit()


## Sac du menu : vraies vues de BagQuery sur un Sac de test (cinq catégories) et trois Pokémon.
func _bag_scenario(scenario: String) -> void:
	var state: Node = (load("res://game/autoload/game_state.gd") as GDScript).new()
	state.new_game(7)
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	var specs: Array = [
		["potion", "Potion", "heal", {"heal_amount": 20}, 7, "Un spray qui soigne les blessures. Restaure 20 PV d'un Pokémon."],
		["super_potion", "Super Potion", "heal", {"heal_amount": 50}, 3, "Restaure 50 PV d'un Pokémon."],
		["hyper_potion", "Hyper Potion", "heal", {"heal_amount": 120}, 1, "Restaure 120 PV d'un Pokémon."],
		["poke_ball", "Poké Ball", "ball", {"catch_bonus": 1}, 12, "Permet de capturer un Pokémon sauvage."],
		["great_ball", "Super Ball", "ball", {"catch_bonus": 1.5}, 4, "Plus efficace qu'une Poké Ball."],
		["x_attack", "Attaque +", "battle", {}, 2, "Augmente l'Attaque pendant un combat."],
		["repel", "Repousse", "field", {}, 3, "Éloigne les Pokémon sauvages faibles."],
		["parcel", "Colis", "key", {}, 1, "Un colis pour le Prof. Chen."],
	]
	for spec: Array in specs:
		var entry := {"name": spec[1], "plural": spec[1] + "s", "feminine": false,
			"category": spec[2], "description": spec[5]}
		entry.merge(spec[3])
		items.add_from_dict({spec[0]: entry}, "capture")
		state.bag.add(StringName(spec[0]), spec[4])
	state.bag.set_favorite(&"potion", true)
	state.bag.set_favorite(&"poke_ball", true)
	var mons: Array = [[&"charmander", 14, 13], [&"pidgey", 12, -1], [&"rattata", 10, 0]]
	for mon_spec: Array in mons:
		var pokemon := PokemonFactory.create(data, mon_spec[0], mon_spec[1], state.rng)
		if mon_spec[2] >= 0:
			pokemon.hp = mon_spec[2]
		state.party.add(pokemon)
	var from_team := scenario == "bag_from_team"
	var context := BagQuery.CONTEXT_TEAM if from_team else BagQuery.CONTEXT_FIELD
	var view := BagQuery.view(state.bag, items, context, BagQuery.Sort.RELEVANCE,
		&"heal", state.party, 0 if from_team else -1, data)
	_menu.open_animated()
	_menu.show_bag(view)
	var potion := items.get_item(&"potion")
	if scenario == "bag_use" or scenario == "bag_result":
		var picker := BagQuery.targets(state.party, state.bag, potion, context, data)
		_menu.show_bag_targets(picker)
		if scenario == "bag_result":
			var mon: Pokemon = state.party.get_at(0)
			var result := ItemUse.apply(state.bag, potion, mon, context)
			_menu.show_bag(BagQuery.view(state.bag, items, context, BagQuery.Sort.RELEVANCE,
				&"heal", state.party, -1, data))
			_menu.show_bag_targets(BagQuery.targets(state.party, state.bag, potion, context,
				data, 0))
			_menu.show_bag_result(BagQuery.result_text(result, mon.display_name(data)),
				BagQuery.can_repeat(result))
	if scenario == "bag_refuse":
		_menu.show_bag_targets(BagQuery.targets(state.party, state.bag, potion, context, data))
		_menu.speed_scale = 1.0
		_menu.get_bag().get_picker().get_card(1).tapped.emit()
		_save_wait = 3
	elif scenario == "bag_heal_mid" or scenario == "bag_heal_end":
		_menu.show_bag_targets(BagQuery.targets(state.party, state.bag, potion, context, data))
		_menu.speed_scale = 1.0
		var healed: Pokemon = state.party.get_at(0)
		var done := ItemUse.apply(state.bag, potion, healed, context)
		_menu.show_bag(BagQuery.view(state.bag, items, context, BagQuery.Sort.RELEVANCE,
			&"heal", state.party, -1, data))
		_menu.show_bag_result(BagQuery.result_text(done, healed.display_name(data)),
			BagQuery.can_repeat(done))
		_menu.show_bag_targets(BagQuery.targets(state.party, state.bag, potion, context, data, 0))
		_save_wait = 6 if scenario == "bag_heal_mid" else 30
	state.free()


## Vraie vue d'Équipe (TeamViews) sur une équipe de trois Pokémon.
func _team_view() -> TeamView:
	var state: Node = (load("res://game/autoload/game_state.gd") as GDScript).new()
	state.new_game(7)
	var data := PokemonData.new()
	data.load_dir()
	var zones := ZoneLibrary.new()
	zones.load_file()
	var specs: Array = [[&"charmander", 14, Pokemon.Origin.STARTER, &"oak_lab"],
		[&"pidgey", 12, Pokemon.Origin.CAPTURE, &"route_1"],
		[&"rattata", 10, Pokemon.Origin.CAPTURE, &"route_1"]]
	for spec: Array in specs:
		var pokemon := PokemonFactory.create(data, spec[0], spec[1], state.rng)
		state.party.add(pokemon)
		state.stamp_meeting(pokemon, spec[2], spec[3])
	state.party.get_at(0).favorite = true
	state.party.get_at(1).hp = state.party.get_at(1).hp * 3 / 4
	state.party.get_at(2).hp = 0
	state.pokedex.mark_seen(&"charmeleon")
	state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	var view := TeamViews.build(state.party, data, zones, state.pokedex, unlocks)
	state.free()
	return view


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
