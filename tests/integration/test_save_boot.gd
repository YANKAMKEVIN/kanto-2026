extends GutTest
## Sauvegarde branchée dans le jeu (jalon 5C.5 S2, jalon-05.md §16) avec la vraie scène Boot,
## l'autoload SceneRouter (fondus raccourcis) et un [SaveSystem] sur un système de fichiers en
## mémoire (jamais le vrai `user://`), horloge fixe :
## - démarrage sans sauvegarde, avec une sauvegarde valide (reprise complète), d'une version
##   plus récente (jamais écrasée, aucune écriture de la session), corrompue (mise de côté, puis
##   autosave normal), avec un départ de débogage (ni lecture ni écriture) ;
## - autosave au changement de carte, jamais pendant une transition, un dialogue, une scène, une
##   rencontre ou un combat ; passage en arrière-plan ;
## - faits du §16.3 : starter, combat du rival, Pokédex daté, Potion trouvée, zones découvertes,
##   temps de jeu.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_s2_save.json"
const FIXTURE_V1 := "res://tests/fixtures/save/v1_after_capture.json"
const FIXTURE_V2 := "res://tests/fixtures/save/v2_kevin_j6.json"
const FIXTURE_V2_END := "res://tests/fixtures/save/v2_kevin_j6_fin.json"
## Vraie partie de Kevin en fin de J7 (v3), voir test_save_system.
const FIXTURE_V3 := "res://tests/fixtures/save/v3_kevin_j7_fin.json"
const SAVE_V4_QA := "res://tools/debug_start/save_v4_qa.json"
const DAYCARE_V7_QA := "res://tools/debug_start/daycare_v7_qa.json"
const DATE := "2026-10-02T14:03:05"
const FADE := 0.05
const TIMEOUT := 12.0

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)


# --- Mise en place -------------------------------------------------------------------

## Lance Boot avec la sauvegarde de test (avant add_child), départ par défaut sur [param map].
func _start_boot(map: StringName = &"player_house_2f", spawn: StringName = &"start",
		facing: Vector2i = Vector2i.DOWN) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	await wait_process_frames(2)


## Nombre d'écritures de la sauvegarde (chacune : temporaire puis remplacement).
func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


## Contenu de la sauvegarde écrite (vide s'il n'y en a pas).
func _saved() -> Dictionary:
	if not _fs.files.has(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	return parsed if parsed is Dictionary else {}


## Quantités du Sac écrit (forme v2 : { "items", "favorites", "acquired" }).
func _bag_items(saved: Dictionary) -> Dictionary:
	return JsonFields.get_dict(JsonFields.get_dict(saved, "bag"), "items")


## Partie sauvegardée type (construite sur une instance neuve de GameState, jamais l'autoload),
## posée dans le système de fichiers en mémoire.
func _write_saved_game(map: StringName, cell: Vector2i, facing: Vector2i) -> void:
	var data := PokemonData.new()
	data.load_dir()
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-09-30T08:00:00")
	state.new_game(42)
	for flag: StringName in [&"mom_greeted", &"starter_chosen", &"rival_battle_done",
			&"rival_challenged", &"got_potion_route_1"]:
		state.flags.set_flag(flag)
	state.starter_species = &"charmander"
	var mon := PokemonFactory.create(data, &"charmander", 7, GameRng.new(3))
	mon.hp = 5
	state.party.add(mon)
	state.stamp_meeting(mon, Pokemon.Origin.STARTER, &"oak_lab")
	state.bag.add(&"poke_ball", 4)
	state.bag.add(&"potion", 1)
	state.record_caught(&"charmander", &"oak_lab")
	state.record_seen(&"pidgey", &"route_1")
	state.record_seen(&"pidgey", &"route_1")
	state.discover_map(&"route_1")
	state.record_item_found(&"potion", &"route_1")
	state.add_play_time(321.0)
	state.set_player_location(map, cell, facing)
	assert_eq(_save.write(state.to_dict()), OK, "sauvegarde type écrite")
	_fs.journal.clear()


## Copie de [param saved] sans le statut (v4) de chaque Pokémon de l'équipe et du stockage.
func _without_status(saved: Dictionary) -> Dictionary:
	var copy := saved.duplicate(true)
	for key: String in ["party", "storage"]:
		for member: Variant in JsonFields.get_array(copy, key):
			if member is Dictionary:
				assert_eq((member as Dictionary).get("status"), "", "statut écrit vide")
				(member as Dictionary).erase("status")
				# J11 (v5 provisoire) : compteur nul et identifiant attribué au chargement.
				assert_eq((member as Dictionary).get("status_turns"), 0.0, "compteur écrit nul")
				(member as Dictionary).erase("status_turns")
				assert_true(PokemonUid.is_valid((member as Dictionary).get("uid")), "identifiant")
				(member as Dictionary).erase("uid")
	# J11 : aucun compagnon au départ.
	assert_eq(copy.get("companion"), "", "aucun compagnon")
	copy.erase("companion")
	# J15 (v7) : Pension vide.
	assert_eq(copy.get("daycare"), {}, "Pension vide")
	copy.erase("daycare")
	return copy


## Fait défiler le dialogue en cours jusqu'à sa fin.
func _finish_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(runner.is_running(), "le dialogue s'est terminé")


## Case libre de la Route 1 à quelques pas au nord de l'entrée ouest (pas un départ de PNJ).
func _free_route_cell() -> Vector2i:
	var map := (load(MapCatalog.scene_path(&"route_1")) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	var cell := map.find_standing_cell(map.get_spawn_cell(&"from_pallet_w") + Vector2i(0, -2))
	remove_child(map)
	return cell


# --- Démarrage -----------------------------------------------------------------------

func test_without_a_save_a_new_game_starts_and_is_saved_on_arrival() -> void:
	await _start_boot()
	assert_false(_boot.has_resumed(), "nouvelle partie")
	assert_true(_boot.is_autosave_enabled())
	assert_eq(_boot.get_map().map_id, &"player_house_2f", "départ dans la chambre")
	assert_eq(GameState.party.size(), 0)
	assert_eq(GameState.started_at, DATE, "début de l'aventure daté")
	assert_eq(_writes(), 1, "autosave à l'arrivée sur la première carte")
	var saved := _saved()
	assert_eq(saved.get("map"), "player_house_2f")
	assert_eq(JsonFields.get_vector2i(saved, "cell"), _player.get_cell())
	assert_true((saved.get("discovered_maps", {}) as Dictionary).has("player_house_2f"),
		"zone découverte")
	assert_push_error_count(0)


func test_a_valid_save_resumes_position_team_bag_pokedex_and_flags() -> void:
	var cell := _free_route_cell()
	_write_saved_game(&"route_1", cell, Vector2i.LEFT)
	await _start_boot()
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(_boot.get_map().map_id, &"route_1", "même carte")
	assert_eq(_player.get_cell(), cell, "même case")
	assert_eq(_player.get_facing(), Vector2i.LEFT, "même orientation")
	assert_eq(GameState.party.size(), 1, "équipe")
	var lead := GameState.party.get_lead()
	assert_eq(lead.species_id, &"charmander")
	assert_eq(lead.level, 7)
	assert_eq(lead.hp, 5, "PV gardés")
	assert_eq(lead.origin, Pokemon.Origin.STARTER)
	assert_eq(lead.met_map, &"oak_lab")
	assert_eq(GameState.starter_species, &"charmander")
	assert_eq(GameState.bag.count_of(&"poke_ball"), 4, "Sac")
	assert_eq(GameState.bag.count_of(&"potion"), 1)
	assert_true(GameState.pokedex.is_caught(&"charmander"), "Pokédex")
	assert_eq(GameState.pokedex.times_seen(&"pidgey"), 2)
	for flag: StringName in [&"mom_greeted", &"starter_chosen", &"got_potion_route_1"]:
		assert_true(GameState.flags.has_flag(flag), "drapeau %s" % flag)
	assert_eq(GameState.started_at, "2026-09-30T08:00:00", "début de l'aventure gardé")
	assert_gte(GameState.play_time, 321.0, "temps de jeu repris")
	assert_eq(GameState.found_items.size(), 1)
	assert_push_error_count(0)


func test_resuming_on_a_cell_now_taken_by_an_npc_moves_to_the_nearest_free_cell() -> void:
	# Le Voyageur de la Route 1 part de (25, 38) ; le joueur s'y tenait pendant sa marche.
	var home := Vector2i(25, 38)
	_write_saved_game(&"route_1", home, Vector2i.UP)
	await _start_boot()
	assert_eq(_boot.get_map().map_id, &"route_1")
	var cell := _player.get_cell()
	assert_ne(cell, home, "pas sur la case du Voyageur")
	assert_eq(absi(cell.x - home.x) + absi(cell.y - home.y), 1, "juste à côté")
	assert_not_null(_boot.get_map().get_npc(&"traveler"), "le Voyageur est bien là")
	assert_push_error_count(0)


func test_a_save_on_an_unknown_map_resumes_at_the_heal_point() -> void:
	_write_saved_game(&"no_such_map", Vector2i(3, 3), Vector2i.UP)
	await _start_boot()
	assert_true(_boot.has_resumed())
	assert_eq(_boot.get_map().map_id, &"player_house_1f", "point de soin")
	assert_eq(_player.get_cell(), _boot.get_map().get_spawn_cell(&"heal"))
	assert_eq(GameState.party.size(), 1, "la partie est gardée")
	assert_push_error_count(0)


func test_a_newer_save_is_never_written_during_the_whole_session() -> void:
	var newer := JSON.stringify({"version": SaveSystem.VERSION + 1, "map": "route_1"})
	_fs.files[SAVE_PATH] = newer
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	assert_false(_boot.has_resumed(), "nouvelle partie")
	assert_false(_boot.is_autosave_enabled(), "autosave coupé pour la session")
	assert_eq(_boot.get_map().map_id, &"player_house_1f")
	assert_eq(GameState.party.size(), 0)
	# Toutes les occasions d'écrire : arrivée, fin de dialogue, changement de carte, demande
	# directe, arrière-plan, fermeture.
	await _finish_dialogue()
	SceneRouter.change_map(&"player_house_2f", &"stairs")
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == &"player_house_2f" and _boot.is_stable(), TIMEOUT)
	_boot.request_autosave("test")
	await wait_process_frames(3)
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(_fs.journal.size(), 0, "aucune écriture, aucun renommage, aucune suppression")
	assert_eq(_fs.files[SAVE_PATH], newer, "la sauvegarde plus récente est intacte")
	assert_push_error_count(0)


## Jalon 6, T0 (jalon-06.md §5.1) : la vraie sauvegarde v1 de Kevin (QA T16) reprend à
## l'identique, puis est réécrite (en v4 depuis le jalon 9).
func test_the_real_v1_save_resumes_then_is_rewritten_in_v4() -> void:
	var v1_text := FileAccess.get_file_as_string(FIXTURE_V1)
	_fs.files[SAVE_PATH] = v1_text
	await _start_boot()
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_true(_boot.is_autosave_enabled())
	assert_eq(_boot.get_map().map_id, &"route_1", "même carte")
	assert_eq(_player.get_cell(), Vector2i(30, 32), "même case")
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "même orientation")
	assert_eq(GameState.party.size(), 3)
	assert_eq(GameState.party.get_lead().hp, 4, "PV gardés")
	assert_eq(GameState.party.get_at(2).experience, 64, "XP gardée")
	assert_eq(GameState.bag.count_of(&"poke_ball"), 3, "Sac")
	assert_eq(GameState.pokedex.caught_count(), 3, "Pokédex")
	assert_eq(GameState.pokedex.times_seen(&"charmander"), 1, "starter vu une fois")
	assert_gte(GameState.play_time, 1616.0, "temps de jeu repris")
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved := _saved()
	assert_eq(int(saved.get("version", 0)), SaveSystem.VERSION,
		"réécrite à la version courante (v6 depuis le J11)")
	assert_eq(_bag_items(saved), {"poke_ball": 3.0, "potion": 1.0}, "Sac v2")
	assert_eq(saved.get("money"), 3000.0, "3 000 ₽")
	assert_eq(saved.get("map"), "route_1")
	assert_eq(JsonFields.get_vector2i(saved, "cell"), Vector2i(30, 32))
	assert_false(_fs.files.has(SAVE_PATH + ".rejected"), "rien d'écarté")
	assert_push_error_count(0)


## Ce que fait un APK du jalon 5 (VERSION = 1) devant une sauvegarde v4 : la vraie Boot avec un
## SaveSystem qui n'accepte que la v1 → nouvelle partie sans autosave, fichier intact.
func test_a_v4_save_is_never_written_by_a_build_that_only_knows_v1() -> void:
	_write_saved_game(&"route_1", _free_route_cell(), Vector2i.LEFT)
	var v2_text: String = _fs.files[SAVE_PATH]
	assert_eq(int((JSON.parse_string(v2_text) as Dictionary)["version"]), SaveSystem.VERSION)
	_save.version = 1
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	assert_false(_boot.has_resumed(), "nouvelle partie")
	assert_false(_boot.is_autosave_enabled(), "autosave coupé pour la session")
	assert_eq(GameState.party.size(), 0)
	await _finish_dialogue()
	_boot.request_autosave("test")
	await wait_process_frames(3)
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_fs.journal.size(), 0, "aucune écriture")
	assert_eq(_fs.files[SAVE_PATH], v2_text, "la sauvegarde v4 est intacte")
	assert_push_error_count(0)


## Jalon 7, T0 (jalon-07.md §5.1) : la vraie partie v2 de Kevin reprend à l'identique, puis
## est réécrite (en v4 depuis le jalon 9) avec 3 000 ₽ et sa première espèce sauvage ; rien
## d'autre ne change (sauf le statut vide de chaque Pokémon, v4).
func test_the_real_v2_save_resumes_then_is_rewritten_in_v4() -> void:
	var v2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V2))
	_fs.files[SAVE_PATH] = FileAccess.get_file_as_string(FIXTURE_V2)
	await _start_boot()
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_true(_boot.is_autosave_enabled())
	assert_eq(_boot.get_map().map_id, &"route_1", "même carte")
	assert_eq(_player.get_cell(), Vector2i(24, 2), "même case")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "même orientation")
	assert_eq(GameState.party.size(), 3)
	assert_eq(GameState.party.get_lead().hp, 21, "PV gardés")
	assert_eq(GameState.party.get_at(1).experience, 92, "XP gardée")
	assert_eq(GameState.bag.count_of(&"poke_ball"), 2, "Sac")
	assert_eq(GameState.money, 3000, "3 000 ₽")
	assert_eq(GameState.first_wild_species(), &"pidgey", "Roucool, première rencontre")
	assert_gte(GameState.play_time, 3732.0, "temps de jeu repris")
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved := _saved()
	assert_eq(int(saved.get("version", 0)), SaveSystem.VERSION,
		"réécrite à la version courante (v6 depuis le J11)")
	assert_eq(saved.get("money"), 3000.0)
	assert_eq(saved.get("first_wild_encounter"), {"species": "pidgey", "map": "route_1",
		"date": "2026-10-02T20:51:16"})
	var before := v2.duplicate(true)
	var after := _without_status(saved)
	for key: String in ["version", "money", "first_wild_encounter", "play_time"]:
		before.erase(key)
		after.erase(key)
	# Les notes du Pokédex se débloquent au chargement selon les drapeaux (J6, T16) : la fixture
	# date du T1 du J6, d'avant les données de notes ; la vraie partie de fin de J6 les a déjà.
	var notes: Array = []
	for entries: Dictionary in [before["pokedex"]["entries"], after["pokedex"]["entries"]]:
		for species: String in entries:
			notes.append(entries[species].get("notes"))
			entries[species].erase("notes")
	assert_eq(notes.slice(0, 4), [[], [], [], []], "fixture sans notes")
	assert_eq(notes.slice(4), [["charmander_shelter"], ["pidgey_paths"], ["rattata_hops"],
		["squirtle_peek"]], "notes débloquées au chargement, comme au J6")
	for key: String in before:
		assert_eq(after.get(key), before[key], "champ « %s » identique" % key)
	assert_eq(after.keys().size(), before.keys().size() + 2,
		"aucun champ perdu ; prénom du rival et apparence (v5) en plus")
	assert_false(_fs.files.has(SAVE_PATH + SaveSystem.CORRUPT_SUFFIX), "rien d'écarté")
	assert_push_error_count(0)


## T1 du J7 : la vraie partie de **fin de J6** (S24) reprend à l'identique avec le vrai Boot,
## puis est réécrite (en v4 depuis le jalon 9) : 3 000 ₽, Roucool, et tout le reste identique
## (notes comprises ; statut vide de chaque Pokémon en plus).
func test_the_real_end_of_j6_save_resumes_then_is_rewritten_in_v4() -> void:
	var text := FileAccess.get_file_as_string(FIXTURE_V2_END)
	var v2: Dictionary = JSON.parse_string(text)
	_fs.files[SAVE_PATH] = text
	await _start_boot()
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_true(_boot.is_autosave_enabled())
	assert_eq(_boot.get_map().map_id, &"route_1", "même carte")
	assert_eq(_player.get_cell(), Vector2i(24, 8), "même case")
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "même orientation")
	assert_eq(GameState.party.size(), 3)
	assert_eq(GameState.party.get_lead().species_id, &"rattata", "ordre de l'équipe")
	assert_eq(GameState.money, 3000, "3 000 ₽")
	assert_eq(GameState.first_wild_species(), &"pidgey")
	assert_gte(GameState.play_time, 50250.0, "temps de jeu repris")
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved := _saved()
	assert_eq(int(saved.get("version", 0)), SaveSystem.VERSION,
		"réécrite à la version courante (v6 depuis le J11)")
	assert_eq(saved.get("money"), 3000.0)
	assert_eq(saved.get("first_wild_encounter"), {"species": "pidgey", "map": "route_1",
		"date": "2026-10-02T20:51:16"})
	var before := v2.duplicate(true)
	var after := _without_status(saved)
	for key: String in ["version", "money", "first_wild_encounter", "play_time"]:
		before.erase(key)
		after.erase(key)
	for key: String in before:
		assert_eq(after.get(key), before[key], "champ « %s » identique" % key)
	assert_eq(after.keys().size(), before.keys().size() + 2,
		"aucun champ perdu ; prénom du rival et apparence (v5) en plus")
	assert_false(_fs.files.has(SAVE_PATH + SaveSystem.CORRUPT_SUFFIX), "rien d'écarté")
	assert_push_error_count(0)


## Ce que fait l'APK du jalon 6 (VERSION = 2) devant la sauvegarde du J9 : nouvelle partie
## sans autosave, la v4 reste intacte (protocole T1 du J7, étape 6).
func test_a_v4_save_is_never_written_by_the_j6_build() -> void:
	_fs.files[SAVE_PATH] = FileAccess.get_file_as_string(FIXTURE_V2_END)
	var reader := SaveSystem.new(_fs, SAVE_PATH)
	var state: Node = autofree(GameStateScript.new())
	var data := PokemonData.new()
	data.load_dir()
	assert_true(state.load_dict(reader.read(), data))
	assert_eq(reader.write(state.to_dict()), OK, "la partie de Kevin, écrite en v4")
	var v4_text: String = _fs.files[SAVE_PATH]
	_fs.journal.clear()
	_save.version = 2
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	assert_false(_boot.has_resumed(), "nouvelle partie")
	assert_false(_boot.is_autosave_enabled(), "autosave coupé pour la session")
	assert_eq(GameState.party.size(), 0)
	await _finish_dialogue()
	_boot.request_autosave("test")
	await wait_process_frames(3)
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(_fs.journal.size(), 0, "aucune écriture")
	assert_eq(_fs.files[SAVE_PATH], v4_text, "la sauvegarde v4 est intacte")
	assert_false(_fs.files.has(SAVE_PATH + SaveSystem.CORRUPT_SUFFIX))
	assert_push_error_count(0)


# --- Jalon 9 (T2) : sauvegarde v4, statut des Pokémon -------------------------------------

## La vraie partie de fin de J7 (v3) reprend à l'identique, sans statut, puis est réécrite en
## v4 : seul le statut vide de chaque Pokémon s'ajoute (protocole T3, étape 2).
func test_the_real_v3_save_resumes_then_is_rewritten_in_v4() -> void:
	var text := FileAccess.get_file_as_string(FIXTURE_V3)
	var v3: Dictionary = JSON.parse_string(text)
	_fs.files[SAVE_PATH] = text
	await _start_boot()
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_true(_boot.is_autosave_enabled())
	assert_eq(_save.read_version, 3, "lue en v3 : « [qa] sauvegarde v3 → v4 » au journal")
	assert_eq(_boot.get_map().map_id, &"viridian_center", "même carte")
	assert_eq(_player.get_cell(), Vector2i(7, 5), "même case")
	assert_eq(_player.get_facing(), Vector2i.UP, "même orientation")
	assert_eq(GameState.party.size(), 4)
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.status, StatusRules.NONE, "aucun statut")
	assert_eq(GameState.money, 2100)
	assert_true(GameState.flags.has_flag(&"pokedex_activated"))
	assert_gte(GameState.play_time, 72722.0, "temps de jeu repris")
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved := _saved()
	assert_eq(int(saved.get("version", 0)), SaveSystem.VERSION,
		"réécrite à la version courante (v6 depuis le J11)")
	var before := v3.duplicate(true)
	var after := _without_status(saved)
	for key: String in ["version", "play_time"]:
		before.erase(key)
		after.erase(key)
	for key: String in before:
		assert_eq(after.get(key), before[key], "champ « %s » identique" % key)
	assert_eq(after.keys().size(), before.keys().size() + 2,
		"aucun champ perdu ; prénom du rival et apparence (v5) en plus")
	assert_false(_fs.files.has(SAVE_PATH + ".rejected"), "rien d'écarté")
	assert_false(_fs.files.has(SAVE_PATH + SaveSystem.CORRUPT_SUFFIX))
	assert_push_error_count(0)


## Une v4 avec un Pokémon empoisonné reprend empoisonnée et se réécrit telle quelle (aucune
## migration : read_version = 4).
func test_a_poisoned_member_is_resumed_poisoned_and_saved_again() -> void:
	_write_saved_game(&"route_1", _free_route_cell(), Vector2i.LEFT)
	var dict: Dictionary = JSON.parse_string(_fs.files[SAVE_PATH])
	dict["party"][0]["status"] = "poison"
	assert_eq(_save.write(dict), OK)
	_fs.journal.clear()
	await _start_boot()
	assert_true(_boot.has_resumed())
	assert_eq(_save.read_version, SaveSystem.VERSION,
		"déjà à la version courante : pas de ligne de migration")
	assert_eq(GameState.party.get_lead().status, StatusRules.POISON, "statut relu")
	assert_eq(GameState.party.get_lead().hp, 5, "aucun dégât au chargement")
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_saved()["party"][0]["status"], "poison", "réécrit empoisonné")
	assert_push_error_count(0)


## Ce que fait l'APK du jalon 7 / 8 (VERSION = 3) devant la sauvegarde du J9 : nouvelle partie
## sans autosave, la v4 (statut compris) reste intacte (protocole T3, étape 5).
func test_a_v4_save_is_never_written_by_the_j7_build() -> void:
	_write_saved_game(&"route_1", _free_route_cell(), Vector2i.LEFT)
	var dict: Dictionary = JSON.parse_string(_fs.files[SAVE_PATH])
	dict["party"][0]["status"] = "poison"
	assert_eq(_save.write(dict), OK)
	var v4_text: String = _fs.files[SAVE_PATH]
	_fs.journal.clear()
	_save.version = 3
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	assert_false(_boot.has_resumed(), "nouvelle partie")
	assert_false(_boot.is_autosave_enabled(), "autosave coupé pour la session")
	assert_eq(GameState.party.size(), 0)
	await _finish_dialogue()
	_boot.request_autosave("test")
	await wait_process_frames(3)
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(_fs.journal.size(), 0, "aucune écriture")
	assert_eq(_fs.files[SAVE_PATH], v4_text, "la sauvegarde v4 est intacte")
	assert_false(_fs.files.has(SAVE_PATH + SaveSystem.CORRUPT_SUFFIX))
	assert_push_error_count(0)


## Départ `save_v4_qa` (« autosave » : vrai) : il remplace la sauvegarde, le statut est écrit,
## puis une relance sans départ de débogage reprend la partie empoisonnée (protocole T3,
## étape 3).
func test_the_save_v4_qa_start_replaces_the_save_then_resumes_poisoned() -> void:
	_write_saved_game(&"oak_lab", Vector2i(5, 8), Vector2i.UP)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.force_debug_start = true
	_boot.debug_start_path = SAVE_V4_QA
	add_child_autofree(_boot)
	_player = _boot.get_player()
	await wait_until(func() -> bool: return _writes() >= 1, TIMEOUT)
	assert_false(_boot.has_resumed(), "la sauvegarde n'est pas lue")
	assert_true(_boot.is_autosave_enabled(), "le départ demande l'autosave")
	assert_eq(_boot.get_map().map_id, &"viridian_city")
	var saved := _saved()
	assert_eq(int(saved.get("version", 0)), SaveSystem.VERSION)
	assert_eq(saved.get("map"), "viridian_city", "la partie de QA a remplacé la sauvegarde")
	assert_eq(saved["party"][0]["species"], "charmander")
	assert_eq(saved["party"][0]["status"], "poison", "statut écrit")
	assert_eq(saved["party"][1]["status"], "")
	_boot.free()
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	assert_true(_boot.has_resumed(), "relance : la partie de QA reprend")
	assert_eq(_boot.get_map().map_id, &"viridian_city")
	assert_eq(GameState.party.get_lead().status, StatusRules.POISON, "toujours empoisonné")
	assert_eq(GameState.party.get_at(1).status, StatusRules.NONE)
	assert_push_error_count(0)


## Départ `daycare_v7_qa` (J15, 15.0) : il remplace la sauvegarde avec un Pokémon à la Pension,
## puis une relance sans départ la retrouve intacte (même uid, même XP en attente).
func test_the_daycare_v7_qa_start_is_saved_then_resumed_with_the_daycare() -> void:
	_write_saved_game(&"oak_lab", Vector2i(5, 8), Vector2i.UP)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.force_debug_start = true
	_boot.debug_start_path = DAYCARE_V7_QA
	add_child_autofree(_boot)
	_player = _boot.get_player()
	await wait_until(func() -> bool: return _writes() >= 1, TIMEOUT)
	var saved := _saved()
	assert_eq(int(saved.get("version", 0)), SaveSystem.VERSION)
	assert_eq(saved["daycare"]["pokemon"]["species"], "rattata", "Pension écrite")
	assert_eq(int(saved["daycare"]["pending_exp"]), 500)
	var uid: String = saved["daycare"]["pokemon"]["uid"]
	_boot.free()
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	assert_true(_boot.has_resumed(), "relance : la partie de QA reprend")
	assert_false(GameState.daycare.is_empty(), "Pension relue")
	assert_eq(GameState.daycare.pokemon.uid, uid, "même Pokémon")
	assert_eq(GameState.daycare.pending_exp, 500)
	assert_eq(GameState.daycare.deposit_level, 10)
	assert_push_error_count(0)


## J15 (jalon-15.md §2.6) : une Pension illisible par cette build (espèce inconnue) n'est pas
## perdue en silence : la partie reprend sans elle, l'original est copié à côté.
func test_an_invalid_daycare_resumes_without_it_and_keeps_the_original_aside() -> void:
	_write_saved_game(&"route_1", _free_route_cell(), Vector2i.UP)
	var content: Dictionary = _saved()
	var kept := PokemonFactory.create(_boot_data(), &"rattata", 10, GameRng.new(4)).to_dict()
	kept["species"] = "missingno"
	content["daycare"] = {"pokemon": kept, "pending_exp": 100, "deposit_level": 10}
	var original := JSON.stringify(content)
	_fs.files[SAVE_PATH] = original
	await _start_boot()
	assert_true(_boot.has_resumed(), "la partie reprend")
	assert_true(GameState.daycare.is_empty(), "sans la Pension illisible")
	assert_eq(_fs.files.get(SAVE_PATH + ".rejected"), original, "original gardé à côté")
	assert_push_error_count(2, "Pokémon invalide puis Pension invalide")


func _boot_data() -> PokemonData:
	var data := PokemonData.new()
	data.load_dir()
	return data


func test_a_corrupt_save_is_set_aside_then_the_new_game_is_saved_normally() -> void:
	_fs.files[SAVE_PATH] = "{ pas du json"
	await _start_boot()
	assert_false(_boot.has_resumed(), "nouvelle partie")
	assert_true(_boot.is_autosave_enabled(), "autosave normal")
	assert_eq(_fs.files.get(SAVE_PATH + SaveSystem.CORRUPT_SUFFIX), "{ pas du json",
		"fichier corrompu mis de côté, jamais détruit")
	assert_eq(_writes(), 1, "la nouvelle partie est sauvegardée")
	assert_eq(_saved().get("map"), "player_house_2f")
	assert_push_error_count(0)


## Départ `status_qa` (J11, T9) : la table d'herbes forcée remplace celle de la Route 1 pour la
## session, statuts et compteur de sommeil posés, rien d'écrit.
func test_the_status_qa_start_forces_the_route_1_table() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.force_debug_start = true
	_boot.debug_start_path = "res://tools/debug_start/status_qa.json"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, &"route_1")
	var table := _boot.get_encounter_library().get_table(&"route_1")
	assert_eq(table.slots.size(), 4)
	assert_eq(table.slots[0].species, &"pikachu")
	assert_eq(GameState.party.get_at(4).status, StatusRules.SLEEP)
	assert_eq(GameState.party.get_at(4).status_turns, 3)
	assert_false(_boot.is_autosave_enabled())
	assert_eq(_fs.journal.size(), 0, "rien d'écrit")
	assert_push_error_count(0)


func test_a_debug_start_neither_reads_nor_writes_the_save() -> void:
	_write_saved_game(&"oak_lab", Vector2i(5, 8), Vector2i.UP)
	var before: String = _fs.files[SAVE_PATH]
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.force_debug_start = true
	_boot.debug_start_path = "res://tests/fixtures/debug_start/valid.json"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	await wait_process_frames(3)
	assert_false(_boot.has_resumed(), "la sauvegarde n'est pas chargée")
	assert_false(_boot.is_autosave_enabled(), "aucune écriture de la session")
	assert_eq(_boot.get_map().map_id, &"route_1", "départ du fichier de débogage")
	assert_eq(GameState.party.get_lead().species_id, &"bulbasaur")
	_boot.request_autosave("test")
	await wait_process_frames(2)
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_fs.journal.size(), 0, "rien d'écrit")
	assert_eq(_fs.files[SAVE_PATH], before, "la vraie partie est intacte")
	assert_push_error_count(0)


# --- Moments d'autosave et gardes ------------------------------------------------------

func test_a_map_change_is_saved_after_the_transition_never_during() -> void:
	await _start_boot()
	assert_eq(_writes(), 1)
	var router_entered: Array[bool] = [false]
	SceneRouter.map_entered.connect(func(_m: GameMap) -> void: router_entered[0] = true,
		CONNECT_ONE_SHOT)
	SceneRouter.change_map(&"player_house_1f", &"stairs")
	while not router_entered[0]:
		assert_eq(_writes(), 1, "rien pendant la transition")
		await wait_process_frames(1)
	# Arrivée : Maman parle d'abord (dialogue automatique) ; la sauvegarde attend sa fin.
	await wait_process_frames(3)
	assert_true(_boot.get_dialogue_runner().is_running(), "dialogue automatique de Maman")
	assert_eq(_writes(), 1, "rien pendant le dialogue")
	await _finish_dialogue()
	await wait_process_frames(2)
	assert_eq(_writes(), 2, "sauvegardé une fois la partie stable")
	var saved := _saved()
	assert_eq(saved.get("map"), "player_house_1f")
	assert_eq(JsonFields.get_vector2i(saved, "cell"), _player.get_cell())
	assert_true((saved.get("flags", []) as Array).has("mom_greeted"), "drapeau du dialogue")
	assert_true(GameState.discovered_maps.has(&"player_house_1f"), "zone découverte")
	assert_eq(GameState.discovered_maps[&"player_house_1f"], DATE, "datée")
	assert_push_error_count(0)


func test_no_save_during_a_scene_then_saved_at_its_end_with_the_found_potion() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	GameState.flags.set_flag(&"starter_chosen")
	var writes := _writes()
	var cutscenes := _boot.get_cutscene_director()
	assert_true(cutscenes.play(&"route_1_potion"), "scène de la Potion")
	_boot.request_autosave("test")
	await wait_process_frames(3)
	assert_true(cutscenes.is_running())
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	# Passe systèmes 2 (S2A) : en arrière-plan, le point de reprise d'avant la scène est écrit.
	assert_eq(_writes(), writes + 1, "point de reprise écrit en arrière-plan")
	assert_false((_saved().get("flags", []) as Array).has("got_potion_route_1"),
		"jamais l'état du milieu de la scène")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _finish_dialogue()
	await wait_until(func() -> bool: return not cutscenes.is_running(), TIMEOUT)
	await wait_process_frames(2)
	assert_eq(_writes(), writes + 2, "sauvegardé à la fin de la scène")
	assert_eq(GameState.found_items.size(), 1, "un objet trouvé")
	if GameState.found_items.size() == 1:
		assert_eq(GameState.found_items[0], {"item": "potion", "map": "route_1", "date": DATE},
			"Potion trouvée sur la Route 1")
	var saved := _saved()
	assert_eq((saved.get("found_items", []) as Array).size(), 1)
	assert_true((saved.get("flags", []) as Array).has("got_potion_route_1"))
	assert_eq(int(_bag_items(saved).get("potion", 0)), 1)
	assert_push_error_count(0)


## Graine d'une défaite : un sauvage rapide (Rattata N10) devance et achève le starter réduit à
## 1 PV (même méthode que test_wild_battle.gd).
func _defeat_seed(data: PokemonData) -> int:
	for seed: int in range(0, 2000):
		var rng := GameRng.new(seed)
		var encounter := WildEncounter.new(&"rattata", 10, &"route_1_grass")
		var request := BattleRequest.wild(encounter, data, rng, Vector2i.ZERO)
		var party := Party.new()
		party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
		party.get_lead().hp = 1
		var battle := Battle.new(BattleSide.new(party, true),
			BattleSide.new(request.foe_party, false, "", null), data, rng, request.rules)
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			battle.submit(BattleAction.move(0 if not battle.get_usable_moves().is_empty() \
				else BattleAction.STRUGGLE))
		if battle.get_outcome() == Battle.Outcome.LOSS:
			return seed
	return -1


func test_no_save_during_a_wild_battle_then_saved_on_waking_at_mom_after_a_defeat() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	var data := _boot.get_pokemon_data()
	var seed := _defeat_seed(data)
	assert_gt(seed, -1, "une graine de défaite")
	if seed < 0:
		return
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = &"charmander"
	GameState.party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
	GameState.party.get_lead().hp = 1
	var writes := _writes()
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 10, &"route_1_grass")))
	assert_eq(GameState.pokedex.times_seen(&"rattata"), 1, "vu une fois")
	assert_eq(GameState.pokedex.get_entry(&"rattata").first_seen_map, &"route_1", "avec la carte")
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		_boot.request_autosave("test")
		_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		if _boot.get_map().map_id != &"player_house_1f":
			# Passe systèmes 2 (S2A) : une seule écriture, le point de reprise d'avant la rencontre.
			assert_lte(_writes(), writes + 1, "rien d'autre pendant la rencontre ni le combat")
			assert_eq(_saved().get("map"), "route_1")
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_false(enc.is_running(), "rencontre terminée")
	assert_eq(GameState.pokedex.times_seen(&"rattata"), 1, "une seule observation par rencontre")
	assert_eq(_boot.get_map().map_id, &"player_house_1f", "réveil chez Maman")
	# La défaite est un fait accompli : sauvegardé au réveil, avant le mot de Maman (QA S3).
	await wait_process_frames(2)
	assert_eq(_writes(), writes + 2, "sauvegardé au réveil, avant le mot de Maman")
	var heal := _boot.get_map().get_spawn_cell(&"heal")
	var woke := _saved()
	assert_eq(woke.get("map"), "player_house_1f")
	assert_eq(JsonFields.get_vector2i(woke, "cell"), heal, "au point de soin")
	var lead: Dictionary = (woke.get("party", []) as Array)[0]
	assert_eq(int(lead.get("hp", 0)), GameState.party.get_lead().max_hp(), "équipe soignée")
	await _finish_dialogue()
	await wait_process_frames(2)
	assert_eq(_writes(), writes + 3, "puis sauvegardé à la fin du mot de Maman")
	var saved := _saved()
	assert_eq(saved.get("map"), "player_house_1f")
	assert_eq(JsonFields.get_vector2i(saved, "cell"), heal, "au point de soin")
	assert_true((saved.get("flags", []) as Array).has("blacked_out_before"))
	assert_push_error_count(0)


func test_talking_to_mom_heals_and_saves() -> void:
	await _start_boot(&"player_house_1f", &"heal", Vector2i.UP)
	await _finish_dialogue()  # premier dialogue automatique
	await wait_process_frames(2)
	GameState.flags.set_flag(&"starter_chosen")
	var data := _boot.get_pokemon_data()
	GameState.party.add(PokemonFactory.create(data, &"squirtle", 5, GameRng.new(1)))
	GameState.party.get_lead().hp = 1
	var writes := _writes()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	await wait_process_frames(2)
	assert_eq(_writes(), writes + 1, "sauvegardé après le soin")
	var saved_party: Array = _saved().get("party", [])
	assert_eq(saved_party.size(), 1)
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "équipe soignée")
	assert_eq(int((saved_party[0] as Dictionary).get("hp", 0)), lead.max_hp(), "PV pleins écrits")
	assert_push_error_count(0)


func test_going_to_the_background_saves_only_when_stable() -> void:
	await _start_boot()
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 1, "écrit tout de suite, partie stable")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	# Pas stable : un dialogue en cours.
	var runner := _boot.get_dialogue_runner()
	assert_true(runner.play(&"mom_wakeup", null, _boot.get_map()))
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 1, "rien pendant un dialogue")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _finish_dialogue()
	assert_push_error_count(0)


func test_play_time_grows_only_in_the_foreground() -> void:
	await _start_boot()
	var start := GameState.play_time
	await wait_process_frames(5)
	assert_gt(GameState.play_time, start, "le temps de jeu augmente")
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var paused := GameState.play_time
	await wait_process_frames(5)
	assert_eq(GameState.play_time, paused, "arrêté en arrière-plan")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await wait_process_frames(3)
	assert_gt(GameState.play_time, paused, "reprend au premier plan")
	assert_push_error_count(0)


# --- Faits (§16.3) -------------------------------------------------------------------

func test_the_starter_is_recorded_as_first_pokemon_not_first_capture() -> void:
	await _start_boot(&"oak_lab", &"entrance", Vector2i.UP)
	var data := _boot.get_pokemon_data()
	var mon := PokemonFactory.create(data, &"bulbasaur", 5, GameRng.new(1))
	GameState.party.add(mon)
	_boot.get_starter_choice().starter_chosen.emit(&"bulbasaur", &"charmander")
	var entry := GameState.pokedex.get_entry(&"bulbasaur")
	assert_true(GameState.pokedex.is_caught(&"bulbasaur"), "capturé au Pokédex")
	assert_eq(entry.first_caught_map, &"oak_lab")
	assert_eq(entry.first_caught_date, DATE)
	assert_eq(mon.origin, Pokemon.Origin.STARTER, "rencontre : starter")
	assert_eq(mon.met_map, &"oak_lab")
	assert_eq(mon.met_level, 5)
	assert_eq(mon.met_date, DATE)
	assert_eq(mon.original_trainer, GameState.player_name)
	assert_eq(GameState.moments.size(), 1)
	assert_eq(GameState.moments[0], {"type": "starter", "date": DATE, "map": "oak_lab",
		"details": {"species": "bulbasaur"}})
	assert_push_error_count(0)


func test_the_rival_battle_records_seen_and_its_outcome() -> void:
	await _start_boot(&"oak_lab", &"entrance", Vector2i.UP)
	var sent := BattleEvent.new(BattleEvent.Kind.SENT_OUT, BattleEvent.SideId.FOE)
	sent.species_id = &"squirtle"
	_boot.get_battle_director().event_played.emit(sent)
	var mine := BattleEvent.new(BattleEvent.Kind.SENT_OUT, BattleEvent.SideId.PLAYER)
	mine.species_id = &"charmander"
	_boot.get_battle_director().event_played.emit(mine)
	assert_eq(GameState.pokedex.times_seen(&"squirtle"), 1, "Pokémon du rival vu")
	assert_eq(GameState.pokedex.get_entry(&"squirtle").first_seen_map, &"oak_lab")
	assert_false(GameState.pokedex.is_seen(&"charmander"), "son propre Pokémon n'est pas « vu »")
	_boot.get_battle_director().battle_finished.emit(&"rival_lab", Battle.Outcome.LOSS)
	assert_eq(GameState.moments.size(), 1)
	assert_eq(GameState.moments[0], {"type": "rival_battle", "date": DATE, "map": "oak_lab",
		"details": {"trainer": "rival_lab", "outcome": "loss"}})
	assert_push_error_count(0)


# --- Capture (jalon 5D, T15) ------------------------------------------------------------

## Graine dont le premier lancer d'une Poké Ball capture un Rattata N3 (même flux d'aléatoire
## que le jeu : création du sauvage, puis le moteur) ; −1 si aucune.
func _catch_seed(data: PokemonData) -> int:
	var items := _boot.get_item_library()
	for seed: int in range(0, 3000):
		var rng := GameRng.new(seed)
		var wild := Party.new()
		wild.add(PokemonFactory.create(data, &"rattata", 3, rng))
		var party := Party.new()
		party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
		var battle := Battle.new(BattleSide.new(party, true),
			BattleSide.new(wild, false, "", null), data, rng, BattleRules.for_wild(items))
		battle.start()
		for event: BattleEvent in battle.submit(BattleAction.ball(&"poke_ball")):
			if event.kind == BattleEvent.Kind.CAUGHT:
				return seed
	return -1


## Une capture demande l'autosave : écrit une seule fois, après la carte de capture et la fin de
## la rencontre, avec le Pokémon dans l'équipe, le Pokédex, la Ball en moins et le grand moment.
func test_a_capture_saves_the_new_pokemon_once_the_game_is_stable() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	var data := _boot.get_pokemon_data()
	var seed := _catch_seed(data)
	assert_gt(seed, -1, "une graine de capture")
	if seed < 0:
		return
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = &"charmander"
	GameState.party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
	GameState.bag.add(&"poke_ball", 5)
	var writes := _writes()
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var pending := false
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		assert_eq(_writes(), writes, "rien pendant la rencontre, la carte de capture comprise")
		var card := battle_director.get_capture_card()
		var panel := battle_director.get_bag_panel()
		var battle := battle_director.get_battle()
		if card != null and card.is_waiting():
			card.skip()
		elif pending and panel != null and panel.is_shown() and not panel.is_answered():
			pending = false
			panel.get_action_button().pressed.emit()
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and battle_hud.get_zone() == BattleHud.Zone.ACTIONS and not pending:
			pending = true
			battle_hud.action_selected.emit(ActionGrid.BAG)
		await wait_process_frames(1)
	assert_false(enc.is_running(), "rencontre terminée")
	await wait_process_frames(2)
	assert_eq(_writes(), writes + 1, "sauvegardé une fois, partie stable")
	var saved := _saved()
	assert_eq((saved.get("party", []) as Array).size(), 2, "le Pokémon capturé est sauvegardé")
	var met: Dictionary = ((saved["party"] as Array)[1] as Dictionary).get("met", {})
	assert_eq(met.get("origin"), "capture", "rencontre : capture")
	assert_eq(met.get("map"), "route_1")
	assert_eq(int(_bag_items(saved).get("poke_ball", 0)), 4, "une Ball de moins")
	var entries: Dictionary = (saved.get("pokedex", {}) as Dictionary).get("entries", {})
	var entry: Dictionary = entries.get("rattata", {})
	assert_true(entry.get("caught", false), "Pokédex : capturé")
	assert_eq(entry.get("first_caught_map"), "route_1", "Pokédex : carte de la capture")
	assert_eq(int(entry.get("times_seen", 0)), 1, "une seule observation")
	var types: Array[String] = []
	for moment: Variant in saved.get("moments", []):
		types.append((moment as Dictionary).get("type", ""))
	assert_eq(types, ["first_capture"] as Array[String], "grand moment « première capture »")
	assert_push_error_count(0)



## Refactor de coordination : la panne ne consomme pas la demande d'autosave.
func test_failed_autosave_is_retried_with_the_current_state_after_the_delay() -> void:
	await _start_boot()
	var writes := _writes()
	_fs.fail_writes = true
	_boot.request_autosave("panne simulée")
	_boot._process(0.0)
	assert_eq(_writes(), writes, "ancienne sauvegarde intacte")
	_fs.fail_writes = false
	GameState.add_money(123)
	_boot._process(SaveCoordinator.RETRY_DELAY - 1.0)
	assert_eq(_writes(), writes, "pas de nouvelle tentative avant le délai")
	_boot._process(1.0)
	assert_eq(_writes(), writes + 1)
	assert_eq(int(_saved().get("money", 0)), GameState.money, "état actuel, pas un ancien cliché")
	assert_push_error_count(0)


func test_a_pending_retry_does_not_write_while_a_dialogue_is_running() -> void:
	await _start_boot()
	var writes := _writes()
	_fs.fail_writes = true
	_boot.request_autosave("panne simulée")
	_boot._process(0.0)
	_fs.fail_writes = false
	assert_true(_boot.get_dialogue_runner().play(&"mom_wakeup", null, _boot.get_map()))
	_boot._process(SaveCoordinator.RETRY_DELAY)
	assert_eq(_writes(), writes, "pas d'écriture au milieu du dialogue")
	await _finish_dialogue()
	await wait_process_frames(2)
	assert_gt(_writes(), writes, "demande conservée jusqu'à l'état stable")
	assert_push_error_count(0)


func test_critical_checkpoint_in_a_debug_start_is_simulated_without_writing() -> void:
	var original := JSON.stringify({"version": SaveSystem.VERSION + 1, "map": "route_1"})
	_fs.files[SAVE_PATH] = original
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.force_debug_start = true
	_boot.debug_start_path = "res://tests/fixtures/debug_start/valid.json"
	add_child_autofree(_boot)
	assert_false(_boot.is_autosave_enabled())
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"debug_checkpoint": {"steps": [
		{"save": "simulation"}, {"set": ["debug_checkpoint_finished"]},
	]}}, "test"))
	assert_true(_boot.get_cutscene_director().play_variant(&"debug_checkpoint",
		library.get_cutscene(&"debug_checkpoint").variants[0]))
	await wait_process_frames(2)
	assert_true(GameState.flags.has_flag(&"debug_checkpoint_finished"))
	assert_eq(_fs.files[SAVE_PATH], original, "aucune modification du vrai fichier")
	assert_eq(_writes(), 0)
	assert_push_error_count(0)


## Sauvegarde plus récente : écriture refusée pour toute la session. Le point critique d'une scène
## est accepté sans rien écrire (la scène continue, sinon elle resterait bloquée pour toujours) ;
## la sauvegarde plus récente reste intacte.
func test_a_future_save_is_never_written_and_never_blocks_a_checkpoint() -> void:
	var original := JSON.stringify({"version": SaveSystem.VERSION + 1, "map": "route_1"})
	_fs.files[SAVE_PATH] = original
	await _start_boot()
	assert_false(_boot.is_autosave_enabled())
	assert_eq(_boot._on_cutscene_save_requested("vraie partie refusée"), OK, "scène non bloquée")
	assert_eq(_fs.files[SAVE_PATH], original)
	assert_eq(_writes(), 0)
	assert_push_error_count(0)
