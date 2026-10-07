extends GutTest
## Remise du colis et activation du Pokédex (jalon 7 T19, jalon-07.md §3.6.2 ; dossier 09 §6,
## §19), avec la vraie scène Boot, le vrai labo, l'autoload SceneRouter (fondus raccourcis) et
## une sauvegarde en mémoire :
## - départ `parcel` (aucune rencontre sauvage) : parler à Chen, colis en main, joue la scène
##   jusqu'au bout ; la réplique « Un {espèce}… » est omise ; le colis quitte le Sac ;
##   `pokedex_activated` est levé une seule fois, juste avant la légende POKÉDEX ACTIVÉ ; le rival
##   entre, parle et repart ; aucun toast ; l'objectif du colis s'efface ; 6 cartes ensuite ;
##   drapeau et Sac sauvegardés à la fin de la scène ; reparler à Chen : réplique habituelle ;
## - la **vraie partie** de Kevin (fin du J6, migrée en v3) avec le colis : « Un Roucool… Tu n'as
##   pas perdu de temps. », puis ce qu'il avait vu avant visible au Pokédex, sans toast de
##   rattrapage.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const PARCEL_START := "res://tools/debug_start/parcel.json"
const KEVIN_SAVE := "res://tests/fixtures/save/v2_kevin_j6_fin.json"
const SAVE_PATH := "user://test_parcel_scene_save.json"
const DATE := "2026-10-05T18:30:00"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 60000
## Devant Chen (8, 4), tourné vers lui : de l'entrée (7, 9), quatre pas au nord, un à l'est.
const IN_FRONT_OF_OAK := Vector2i(8, 5)
const PATH_TO_OAK: Array[Vector2i] = [
	Vector2i.UP, Vector2i.UP, Vector2i.UP, Vector2i.UP, Vector2i.RIGHT,
]
const ROUCOOL_LINE := "Un Roucool… Tu n'as pas perdu de temps."
const CAPTION := "POKÉDEX ACTIVÉ"
## Les répliques de la scène, dans l'ordre (dossier 09 §19), sans celle de l'espèce.
const LINES: Array[String] = [
	"Tiens…",
	"Il a déjà commencé à enregistrer tes rencontres.",
	"J'étudie depuis longtemps la manière dont les Pokémon vivent à travers Kanto.",
	"Mais aucune recherche ne remplacera ce qu'un Dresseur découvre sur le terrain.",
	"Ton voyage peut nous apprendre beaucoup.",
	"Il enregistrera les Pokémon que tu observes, les endroits où tu les rencontres et ce que tu découvriras sur eux.",
	"Observe. Explore. Fais-toi ta propre idée du monde.",
	"Professeur ! Je suis revenu.",
	"Tiens. T'es déjà revenu, toi aussi ?",
	"Toi aussi, prends-en un.",
	"Et toi… apprends à regarder au-delà de la victoire.",
	"…On verra.",
	"Pas mal.",
	"Mais ne t'imagine pas que je vais t'attendre.",
]
const USUAL_LINE := "Le monde qui vous attend est bien plus vaste que Bourg Palette."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _fades: Array[float] = []
## Pages vues pendant la scène, dans l'ordre.
var _pages: Array[String] = []
## Index de la page en cours quand la légende est apparue (-1 : jamais).
var _caption_at: int = -1
## Index de la page en cours quand le drapeau a été levé (-1 : jamais).
var _flag_at: int = -1
var _flag_sets: int = 0
var _toast_seen: bool = false
var _rival_seen: bool = false


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_pages.clear()
	_caption_at = -1
	_flag_at = -1
	_flag_sets = 0
	_toast_seen = false
	_rival_seen = false


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	if GameState.flags.flag_changed.is_connected(_on_flag_changed):
		GameState.flags.flag_changed.disconnect(_on_flag_changed)
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)


# --- Mise en place -------------------------------------------------------------------------

## Boot sur la sauvegarde en mémoire (la vraie partie de Kevin si [param kevin], sinon nouvelle
## partie remplacée par le départ `parcel`).
func _start(kevin: bool) -> void:
	if kevin:
		_fs.files[SAVE_PATH] = FileAccess.get_file_as_string(KEVIN_SAVE)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"pallet_town"
	_boot.start_spawn = &"oak_lab_door"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	# La légende garde ses fondus ; sa tenue est raccourcie (le test attend sa disparition).
	_boot.get_hud().get_caption().hold_duration = 0.3
	await wait_process_frames(2)
	if kevin:
		assert_true(_boot.has_resumed(), "la vraie partie est reprise")
		# Fin du J7A sur sa partie : arrivé à Jadielle, colis reçu à la Boutique.
		GameState.flags.set_flag(&"viridian_arrived")
		GameState.flags.set_flag(&"got_oak_parcel")
		GameState.bag.add(&"oak_parcel", 1)
	else:
		var start := DebugStart.new()
		assert_true(start.load_file(PARCEL_START, _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	GameState.flags.flag_changed.connect(_on_flag_changed)
	await SceneRouter.change_map(&"oak_lab", &"entrance", Vector2i.UP)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"oak_lab")
	assert_null(_boot.get_map().get_npc(&"rival"), "le rival n'est pas encore là")
	for direction: Vector2i in PATH_TO_OAK:
		assert_true(_player.script_step(direction), "pas %s" % direction)
		await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
	_player.face(Vector2i.UP)
	await wait_process_frames(2)
	assert_eq(_player.get_cell(), IN_FRONT_OF_OAK, "devant Chen")


func _on_flag_changed(flag: StringName, value: bool) -> void:
	if flag == &"pokedex_activated" and value:
		_flag_sets += 1
		_flag_at = _pages.size() - 1


## Parle à Chen et déroule tout (dialogue, scène) en notant pages, légende, toasts et rival.
func _talk_to_oak() -> void:
	var runner := _boot.get_dialogue_runner()
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var hud := _boot.get_hud()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return runner.is_running() or director.is_running(),
		TIMEOUT)
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		_watch(hud)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "la scène est finie")
	# Un peu de jeu stable ensuite : aucun toast en retard.
	for i: int in 30:
		_watch(hud)
		await wait_process_frames(1)


func _watch(hud: ExplorationHud) -> void:
	if hud.get_toast().is_showing():
		_toast_seen = true
	if hud.get_caption().is_showing() and _caption_at < 0:
		_caption_at = _pages.size() - 1
		assert_eq(hud.get_caption().text, CAPTION, "légende")
	if _boot.get_map().get_npc(&"rival") != null:
		_rival_seen = true


func _cards() -> Array[StringName]:
	var screens: Array[StringName] = []
	for card: MenuCardView in _boot.get_menu_director().build_dashboard().cards:
		screens.append(card.screen)
	return screens


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


## Vérifications communes après la scène.
func _assert_after_scene(expected: Array[String]) -> void:
	assert_eq(_pages, expected, "répliques dans l'ordre")
	assert_eq(_flag_sets, 1, "pokedex_activated levé une seule fois")
	assert_eq(_flag_at, expected.find("Ton voyage peut nous apprendre beaucoup."),
		"drapeau levé après « Ton voyage… »")
	assert_eq(_caption_at, _flag_at, "légende après le drapeau, avant « Il enregistrera… »")
	assert_true(_rival_seen, "le rival est entré")
	assert_null(_boot.get_map().get_npc(&"rival"), "le rival est reparti")
	assert_false(_toast_seen, "aucun toast (ni colis, ni Pokédex, ni rattrapage)")
	assert_true(GameState.flags.has_flag(&"pokedex_activated"))
	assert_true(GameState.flags.has_flag(&"got_oak_parcel"), "le colis reste dans l'histoire")
	assert_eq(GameState.bag.count_of(&"oak_parcel"), 0, "colis retiré du Sac")
	assert_eq(_cards().size(), 6, "6e carte : Pokédex")
	assert_true(_cards().has(MenuRoute.POKEDEX), "carte Pokédex")
	var dashboard := _boot.get_menu_director().build_dashboard()
	# Jalon 8 (dossier 11, arbitrage 6) : l'objectif du colis cède la place au suivant.
	assert_eq(dashboard.objective_text, "Objectif : continuer vers le nord.",
		"objectif du colis remplacé")
	assert_eq(dashboard.dex_text, DashboardViews.dex_text(GameState.pokedex.seen_count(),
		GameState.pokedex.caught_count()), "ligne vus · capturés")
	assert_true(_player.is_input_enabled(), "le joueur reprend la main")
	# Écrit à la fin de la scène (partie stable).
	await wait_until(func() -> bool:
		return _saved().get("flags", []).has("pokedex_activated"), TIMEOUT)
	var saved := _saved()
	assert_true(saved.get("flags", []).has("pokedex_activated"), "drapeau sauvegardé")
	var items: Dictionary = JsonFields.get_dict(JsonFields.get_dict(saved, "bag"), "items")
	assert_false(items.has("oak_parcel"), "colis absent du Sac sauvegardé")


## Reparler à Chen : la réplique habituelle, la scène ne se rejoue pas.
func _assert_no_replay() -> void:
	_pages.clear()
	var director := _boot.get_cutscene_director()
	var started: Array[StringName] = []
	director.cutscene_started.connect(func(id: StringName) -> void: started.append(id))
	await _talk_to_oak()
	assert_eq(started, [] as Array[StringName], "aucune scène")
	assert_gt(_pages.size(), 0)
	assert_eq(_pages[0], USUAL_LINE, "réplique habituelle")
	assert_eq(_flag_sets, 1, "drapeau toujours levé une seule fois")


# --- Départ `parcel` (aucune rencontre) -----------------------------------------------------

func test_parcel_start_without_encounter_skips_the_species_line() -> void:
	await _start(false)
	assert_eq(GameState.first_wild_species(), &"", "aucune rencontre sauvage")
	assert_eq(GameState.bag.count_of(&"oak_parcel"), 1)
	assert_eq(_cards().size(), 5, "5 cartes avant l'activation")
	assert_ne(_boot.get_menu_director().build_dashboard().objective_text, "",
		"objectif : remettre le colis")
	await _talk_to_oak()
	await _assert_after_scene(LINES)
	await _assert_no_replay()
	assert_push_error_count(0)


# --- La vraie partie de Kevin -----------------------------------------------------------------

func test_kevin_real_save_names_his_pidgey_and_shows_what_he_saw() -> void:
	await _start(true)
	assert_eq(GameState.first_wild_species(), &"pidgey", "première rencontre : Roucool")
	var seen_before := GameState.pokedex.seen_count()
	assert_gt(seen_before, 1, "il a déjà vu plusieurs espèces")
	assert_eq(_cards().size(), 5)
	await _talk_to_oak()
	var expected := LINES.duplicate()
	expected.insert(2, ROUCOOL_LINE)
	await _assert_after_scene(expected)
	assert_eq(GameState.pokedex.seen_count(), seen_before, "rien d'enregistré par la scène")
	# Le Pokédex montre ce qu'il avait vu avant l'activation.
	var grids: Array[PokedexGridView] = []
	var menu := _boot.get_menu_director()
	menu.pokedex_shown.connect(func(view: PokedexGridView) -> void: grids.append(view))
	menu.open(MenuRoute.pokedex())
	assert_eq(grids.size(), 1, "écran Pokédex ouvert")
	if grids.size() == 1:
		for species: StringName in [&"pidgey", &"rattata", &"charmander"]:
			assert_not_null(grids[0].slot(species), "%s visible au Pokédex" % species)
	menu.close()
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await _assert_no_replay()
	assert_false(_toast_seen, "aucun toast de rattrapage")
	assert_push_error_count(0)
