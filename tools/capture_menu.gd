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
##   dex_grid             grille et fiche de Salamèche (trois colonnes permanentes)
##   dex_sheet_caught     fiche de Salamèche (capturé) : Aperçu complet
##   dex_sheet_seen       fiche de Carapuce (seulement vu) : ni types, ni taille, ni poids
##   dex_habitat          filtre HABITATS (Route 1), fiche de Roucool, onglet Habitat
##   dex_search_empty     recherche sans résultat
##   dex_evolution / dex_notes   onglets Évolution et Observations de Salamèche / Roucool
##   dex_planche[_023|_074|_095|_147]   les 151 cases « vues » (vues fabriquées), défilées
##                        jusqu'au numéro ; dex_planche_unknown[_074] : la même grille inconnue
## Carte (T20, avec --only=map,map_panel,map_dex) : vraies vues de MapJournal sur une partie de test
##   map                  Bourg Palette (portrait du joueur, panneau sans section : rien de trouvé)
##   map_panel            Route 1, Pokédex pas visible : objets trouvés seulement
##   map_dex              Route 1, Pokédex visible : Pokémon observés et objets trouvés
## Dresseur (T24, avec --only=trainer,trainer_dex,trainer_empty) : vraies vues de TrainerSummary
##   trainer              la vraie partie de Kevin (fixture v1), Pokédex pas visible : ni vus ni capturés
##   trainer_dex          idem, Pokédex activé : « vus » et « capturés » (liens)
##   trainer_empty        partie neuve : frise vide (« Ton aventure ne fait que commencer. »)
## Paramètres et commandes (T28, avec --only=settings,settings_controls,settings_access,
## settings_graphics,settings_save,settings_no_save,choice_cards,left_handed,text_large_dialogue,
## text_large_settings,contrast_dialogue,contrast_settings) : vraies vues de SettingsViews
##   settings             catégorie JEU (vitesse du texte, confirmations, Sauvegarder maintenant)
##   settings_controls    COMMANDES (taille, opacité, boutons, vibrations, mode gaucher)
##   settings_access      ACCESSIBILITÉ ; settings_graphics   GRAPHISMES (Auto (Élevée))
##   settings_save        après « Sauvegarder maintenant » (résultat) ; settings_no_save   inactif
##   choice_cards         ChoiceCards « Oublier Charge ? » sur le menu
##   left_handed          exploration en mode gaucher (joystick à droite, boutons à gauche)
##   text_large_* / contrast_*   dialogue (monde) et écran Paramètres en texte Grande / contraste
##
## Boutique (J7 T11, avec --only=shop_buy,shop_sell,shop_no_money,shop_confirm,trainer_money,
## bag_money) : vraies vues de ShopViews sur une partie de test (3 000 ₽, Potion favorite)
##   shop_buy             ACHETER, Potion sélectionnée, quantité 3, TOTAL 900 ₽, « Merci ! »
##   shop_sell            VENDRE, Poké Ball sélectionnée, quantité 2
##   shop_no_money        ACHETER avec 50 ₽ : CONFIRMER touché, refus et raison
##   shop_confirm         VENDRE la Potion favorite : ChoiceCards de confirmation
##   trainer_money        écran Dresseur avec la ligne « Argent : … »
##   bag_money            Sac avec l'argent sous les catégories
##
## Stockage (J7 T15, avec --only=storage,storage_drag,storage_menu,storage_release,storage_refusal,
## storage_empty,storage_team_button) : vraies vues de StorageViews et vraies règles StorageRules
##   storage              équipe de 4 et 9 Pokémon au stockage, Salamèche sélectionné
##   storage_drag         glisser une carte de l'équipe : fantôme et cadre de dépôt sur le stockage
##   storage_menu         menu « ⋯ » ouvert (LIBÉRER) sur un Pokémon du stockage
##   storage_release      confirmation « Libérer … ? » (ChoiceCards)
##   storage_refusal      LIBÉRER un favori : la carte tremble, la raison est écrite
##   storage_empty        stockage vide
##   storage_team_button  écran Équipe avec le bouton STOCKAGE (au Centre)
##
## Sur le Mac, en 2340×1080 :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 900 \
##     -s res://tools/capture_menu.gd -- --out=build/captures/jalon06_t3
## (1920x1080 pour l'autre largeur de référence.)

const BOOT_SCENE: String = "res://game/boot.tscn"
const MENU_SCENE: String = "res://game/ui/menu/trainer_menu.tscn"
## Scénarios qui montrent le monde (HUD visible) ; les autres ouvrent le menu comme Boot le fait :
## titre de zone retiré et contrôles cachés (MM.2 : plus de titre flou derrière le ×).
const WORLD_SCENARIOS: Array[String] = ["hud_button", "left_handed", "text_large_dialogue",
	"contrast_dialogue"]

var _boot: Node
var _menu: TrainerMenu
var _out_dir: String = "build/captures/jalon06_t3"
var _suffix: String = ""
var _frame: int = 0
var _step: int = 0
var _scenarios: Array[String] = ["hud_button", "dashboard_5", "dashboard_6", "dashboard_no_team"]
var _bag_money: bool = false
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
	_boot.set(&"start_spawn", &"from_viridian_w")
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
		if not WORLD_SCENARIOS.has(_current):
			_hide_world_hud()
		_begin(_current)
		return
	_wait += 1
	if _wait == _save_wait:
		_save(_current)
		_current = ""
		_cleanup()
		if _menu.is_open():
			_menu.close_animated()


func _begin(scenario: String) -> void:
	match scenario:
		"hud_button":
			return
		"settings", "settings_controls", "settings_access", "settings_graphics", \
		"settings_save", "settings_no_save", "choice_cards", "left_handed", \
		"text_large_dialogue", "text_large_settings", "contrast_dialogue", "contrast_settings":
			_settings_scenario(scenario)
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
		"dex_evolution", "dex_notes", "dex_planche", "dex_planche_023", "dex_planche_074", \
		"dex_planche_095", "dex_planche_147", "dex_planche_unknown", "dex_planche_unknown_074":
			_dex_scenario(scenario)
		"map", "map_panel", "map_dex":
			_map_scenario(scenario)
		"trainer", "trainer_dex", "trainer_empty", "trainer_badge":
			_trainer_scenario(scenario)
		"shop_buy", "shop_sell", "shop_no_money", "shop_confirm":
			_shop_scenario(scenario)
		"storage", "storage_drag", "storage_menu", "storage_release", "storage_refusal", \
		"storage_empty", "storage_team_button":
			_storage_scenario(scenario)
		"trainer_money":
			_trainer_scenario("trainer")
		"bag_money":
			_bag_money = true
			_bag_scenario("bag")
		"bag", "bag_use", "bag_result", "bag_from_team", "bag_refuse", "bag_heal_mid", "bag_heal_end":
			_bag_scenario(scenario)


## Paramètres, ChoiceCards, mode gaucher, texte Grande et contraste (T28).
func _settings_scenario(scenario: String) -> void:
	var settings := GameSettings.new()
	if scenario.begins_with("text_large"):
		settings.text_size = GameSettings.TextSize.LARGE
	if scenario.begins_with("contrast"):
		settings.high_contrast = true
	UiPrefs.apply(settings)
	var hud: ExplorationHud = _boot.get_hud()
	match scenario:
		"left_handed":
			settings.left_handed = true
			settings.joystick_opacity = 0.7
			hud.set_left_handed(true)
			hud.set_joystick_style(settings.joystick_scale, settings.joystick_opacity)
			hud.show_interact(&"talk")
			_touch_joystick(Vector2(1750.0, 700.0))
			return
		"text_large_dialogue", "contrast_dialogue":
			var box: DialogueBox = _boot.get_dialogue_box()
			box.open()
			box.show_page("Maman", "Bonjour ! Tu es enfin réveillé ? Le Prof. Chen t'attend "
				+ "dans son laboratoire, ne le fais pas patienter.", false)
			box.set_visible_characters(-1)
			box.set_continue_visible(true)
			hud.show_toast("Potion ×1", "Ajoutée au Sac")
			hud.show_zone_title("Route 1", "Bourg Palette — Jadielle")
			_save_wait = 20
			return
		"choice_cards":
			_menu.open_animated()
			_menu.show_settings(SettingsViews.build(settings, GameSettings.Graphics.HIGH, true))
			var layer := CanvasLayer.new()
			layer.layer = UiTokens.LAYER_DIALOG
			layer.name = "ChoiceLayer"
			root.add_child(layer)
			var cards := ChoiceCards.new()
			cards.speed_scale = 0.0
			layer.add_child(cards)
			var view := ChoiceView.new("Oublier Charge ?", "OUBLIER", "GARDER")
			view.detail = "Salamèche ne pourra plus l'utiliser."
			view.confirm_detail = "La capacité est perdue."
			view.cancel_detail = "Il la garde."
			cards.show_choice(view)
			return
	var view := SettingsViews.build(settings, GameSettings.Graphics.HIGH,
		scenario != "settings_no_save")
	# Comme Boot : le lieu dans le bandeau d'état (MM.3).
	_menu.set_zone_name("Route 1")
	_menu.open_animated()
	_menu.show_settings(view)
	var screen := _menu.get_settings()
	match scenario:
		"settings_controls":
			screen.select_category(SettingsViews.CATEGORY_CONTROLS)
		"settings_access", "text_large_settings", "contrast_settings":
			screen.select_category(SettingsViews.CATEGORY_ACCESSIBILITY)
		"settings_graphics":
			screen.select_category(SettingsViews.CATEGORY_GRAPHICS)
		"settings_save":
			screen.select_category(SettingsViews.CATEGORY_GAME)
			screen.show_save_result("Partie sauvegardée — 14 h 32")
		_:
			# L'écran garde la catégorie du scénario précédent : JEU par défaut.
			screen.select_category(SettingsViews.CATEGORY_GAME)


## Un doigt posé (et tiré un peu) dans le viewport : le joystick apparaît, pour la capture.
func _touch_joystick(point: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	root.push_input(touch, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = point + Vector2(0.0, -60.0)
	root.push_input(drag, true)


## Comme Boot à l'ouverture du menu (_on_menu_opened) : titre de zone et légende retirés,
## contrôles cachés.
func _hide_world_hud() -> void:
	var hud: ExplorationHud = _boot.get_hud()
	hud.hide_zone_title()
	hud.get_zone_title().visible = false
	hud.hide_caption()
	hud.get_caption().visible = false
	hud.set_controls_visible(false)


## Remet les réglages de capture à zéro entre deux scénarios.
func _cleanup() -> void:
	UiPrefs.reset()
	if _menu.get_settings() != null:
		_menu.get_settings().show_save_result("")
	var hud: ExplorationHud = _boot.get_hud()
	hud.set_left_handed(false)
	hud.set_joystick_style(1.0, 1.0)
	hud.hide_interact()
	hud.get_toast().hide_now()
	hud.hide_zone_title()
	hud.get_joystick().release()
	hud.set_controls_visible(true)
	var box: DialogueBox = _boot.get_dialogue_box()
	if box.is_open():
		box.close()
	var layer := root.get_node_or_null("ChoiceLayer")
	if layer != null:
		layer.queue_free()


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
	if scenario.begins_with("dex_planche"):
		grid = _planche_grid(grid, data, not scenario.begins_with("dex_planche_unknown"))
	_menu.open_animated()
	_menu.show_pokedex(grid)
	if scenario == "dex_search_empty":
		return
	_menu.show_pokedex_sheet(PokedexQuery.sheet(species, dex, data, library, zones))
	var sheet := _menu.get_pokedex().get_sheet()
	sheet.select_tab(PokedexSheet.Tab.OVERVIEW)
	if scenario.begins_with("dex_planche_"):
		for _i: int in 3:
			await process_frame
		var number := int(scenario.trim_prefix("dex_planche_").trim_prefix("unknown_"))
		var target := _menu.get_pokedex().get_slot(number)
		if target != null:
			_menu.get_pokedex().get_scroll().scroll_vertical = maxi(
				0, roundi(target.position.y) - 40)
	match scenario:
		"dex_habitat":
			sheet.select_tab(PokedexSheet.Tab.HABITAT)
		"dex_evolution":
			sheet.select_tab(PokedexSheet.Tab.EVOLUTION)
		"dex_notes":
			sheet.select_tab(PokedexSheet.Tab.NOTES)


## Vue fabriquée de la planche de contrôle : les 151 cases « vues » (ou toutes inconnues), les
## noms des espèces qui existent dans les données, « Nom » sinon.
func _planche_grid(base: PokedexGridView, data: PokemonData, seen: bool) -> PokedexGridView:
	var view := base
	view.slots = []
	var names: Dictionary[int, String] = {}
	var ids: Dictionary[int, StringName] = {}
	for id: StringName in data.get_species_ids():
		var species := data.get_species(id)
		names[species.dex] = species.name
		ids[species.dex] = id
	for number: int in range(1, 152):
		if seen:
			var id: StringName = ids.get(number, StringName("dex_%d" % number))
			view.slots.append(PokedexSlotView.new(number, id, names.get(number, "Nom"),
				PokedexQuery.State.CAUGHT if number % 3 == 0 else PokedexQuery.State.SEEN))
		else:
			view.slots.append(PokedexSlotView.new(number))
	return view


## Dresseur du menu : vraies vues de TrainerSummary (la partie de Kevin à la fin du J5, ou une
## partie neuve).
func _trainer_scenario(scenario: String) -> void:
	var state: Node = (load("res://game/autoload/game_state.gd") as GDScript).new()
	var data := PokemonData.new()
	data.load_dir()
	var zones := ZoneLibrary.new()
	zones.load_file()
	var moments := MomentLibrary.new()
	moments.load_file()
	if scenario == "trainer_empty":
		state.new_game(7)
	else:
		var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://tests/fixtures/save/v1_after_capture.json"))
		SaveSystem.upgrade(content)
		state.load_dict(content, data)
		if scenario == "trainer_dex" or scenario == "trainer_badge":
			state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
			state.record_seen(&"pidgey", &"route_1")
		if scenario == "trainer_badge":
			state.flags.set_flag(&"badge_boulder")  # capture seulement : aucun badge avant le J10
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	var badges := BadgeLibrary.new()
	badges.load_file()
	_menu.open_animated()
	_menu.show_trainer(TrainerSummary.build(state, data, zones, moments, unlocks, badges))
	state.free()


## Carte du menu : vraies vues de MapJournal sur une partie de test (Bourg Palette et Route 1
## découvertes, le joueur à Bourg Palette).
func _map_scenario(scenario: String) -> void:
	var state: Node = (load("res://game/autoload/game_state.gd") as GDScript).new()
	state.new_game(7)
	var data := PokemonData.new()
	data.load_dir()
	var zones := ZoneLibrary.new()
	zones.load_file()
	var items := ItemLibrary.new()
	items.load_dir()
	var illustration := MapIllustration.new()
	illustration.load_file()
	state.discover_map(&"pallet_town")
	state.discover_map(&"route_1")
	state.set_player_location(&"pallet_town", Vector2i.ZERO, Vector2i.DOWN)
	if scenario != "map":
		for species: StringName in [&"rattata", &"pidgey", &"charmander", &"squirtle"]:
			state.record_seen(species, &"route_1")
		state.record_item_found(&"potion", &"route_1")
		state.record_item_found(&"potion", &"route_1")
		state.record_item_found(&"poke_ball", &"route_1")
	var zone: StringName = &"pallet_town" if scenario == "map" else &"route_1"
	_menu.open_animated()
	_menu.show_map(MapJournal.view(state, zones, illustration, zone))
	_menu.show_map_zone(MapJournal.panel(zone, state, data, zones, items,
		scenario == "map_dex"))
	state.free()


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


## Boutique : vraies vues de ShopViews sur une partie de test.
func _shop_scenario(scenario: String) -> void:
	var state: Node = (load("res://game/autoload/game_state.gd") as GDScript).new()
	state.new_game(7)
	var items := ItemLibrary.new()
	items.load_dir()
	var shops := ShopLibrary.new()
	shops.load_dir()
	shops.check_references(items)
	var shop := shops.get_shop(&"viridian_mart")
	state.bag.add(&"potion", 5)
	state.bag.add(&"poke_ball", 6)
	state.bag.set_favorite(&"potion", true)
	if scenario == "shop_no_money":
		state.money = 50
	var sell := scenario == "shop_sell" or scenario == "shop_confirm"
	var view := ShopViews.build(state, shop, items,
		ShopViews.MODE_SELL if sell else ShopViews.MODE_BUY)
	_menu.open_animated()
	_menu.show_shop(view)
	var screen := _menu.get_shop()
	match scenario:
		"shop_buy":
			screen.select_item(&"potion")
			screen.set_quantity(3)
			screen.show_result(ShopViews.TEXT_THANKS, true)
		"shop_sell":
			screen.select_item(&"poke_ball")
			screen.set_quantity(2)
		"shop_no_money":
			screen.get_confirm_button().pressed.emit()
		"shop_confirm":
			screen.select_item(&"potion")
			screen.set_quantity(2)
			_menu.show_shop_confirm(ShopViews.sell_confirm_view(view.entry(&"potion"), 2),
				&"potion", 2)
	state.free()


## Stockage : vraies vues de StorageViews sur une équipe de 4 et un stockage de 9.
func _storage_scenario(scenario: String) -> void:
	var state: Node = (load("res://game/autoload/game_state.gd") as GDScript).new()
	state.new_game(7)
	var data := PokemonData.new()
	data.load_dir()
	var zones := ZoneLibrary.new()
	zones.load_file()
	var party_specs: Array = [[&"charmander", 14], [&"pidgey", 12], [&"rattata", 10],
		[&"squirtle", 9]]
	var stored_specs: Array = [[&"bulbasaur", 8], [&"pidgey", 6], [&"rattata", 5],
		[&"pidgey", 7], [&"rattata", 4], [&"bulbasaur", 11], [&"squirtle", 6],
		[&"charmander", 5], [&"pidgey", 9]]
	for spec: Array in party_specs:
		state.party.add(PokemonFactory.create(data, spec[0], spec[1], state.rng))
	if scenario != "storage_empty":
		for spec: Array in stored_specs:
			state.storage.add(PokemonFactory.create(data, spec[0], spec[1], state.rng))
	state.party.get_at(0).favorite = true
	state.party.get_at(2).hp = 0
	if state.storage.size() > 1:
		state.storage.get_at(1).favorite = true
	state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	if scenario == "storage_team_button":
		var team := TeamViews.build(state.party, data, zones, state.pokedex, unlocks)
		team.storage_available = true
		_menu.open_animated()
		_menu.show_team(team, 0)
		state.free()
		return
	var selection := StorageSelection.new(StorageRules.Place.PARTY, 0)
	if scenario == "storage_menu" or scenario == "storage_release":
		selection = StorageSelection.new(StorageRules.Place.STORAGE, 2)
	if scenario == "storage_refusal":
		selection = StorageSelection.new(StorageRules.Place.STORAGE, 1)
	var view := StorageViews.build(state, data, selection, zones, unlocks)
	_menu.open_animated()
	_menu.show_storage(view)
	var screen := _menu.get_storage()
	match scenario:
		"storage_drag":
			var card := screen.get_party_cards()[1]
			card.drag_started.emit(1)
			var target := screen.get_grid_zone().get_global_rect().get_center()
			card.drag_moved.emit(1, target)
		"storage_menu":
			screen.toggle_menu()
		"storage_release":
			var name := view.card_at(selection.place, selection.index).member.display_name
			_menu.ask_storage_release(StorageViews.release_choice(name),
				int(selection.place), selection.index)
		"storage_refusal":
			var result := StorageRules.release(state.party, state.storage, selection.place,
				selection.index)
			_menu.show_storage_refusal(int(selection.place), selection.index,
				StorageViews.result_text(result, data))
	state.free()


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
		&"heal", state.party, 0 if from_team else -1, data,
		state.money if _bag_money else -1)
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
		lead.dex_number = 4
		lead.display_name = "Salamèche"
		lead.gender = BattleCardView.Gender.MALE
		lead.level = 14
		lead.max_hp = 39
		lead.hp = 0 if fainted else 39
		lead.status_text = TeamMemberView.STATUS_FAINTED if fainted else ""
		if not fainted:
			lead.hp = 31
		view.lead = lead
	if card_count == 6:
		view.badges_text = DashboardViews.badges_text(2)  # capture seulement : aucun badge au MM.1
	var texts: Dictionary = DashboardViews.CARD_TEXTS
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
	# Coût de l'écran (MM.1) : appels de dessin de l'image et mémoire vidéo des textures.
	print("PERF %s draw=%d tex=%.1f Mo" % [capture_name,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])
