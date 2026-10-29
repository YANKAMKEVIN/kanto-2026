extends GutTest
## Jalon 32, lots 32A à 32D (`jalon-32.md` T3 ; N-6 à N-9, textes 8 à 15) avec le vrai Boot et
## les vraies cartes : après la Ligue (`league_champion_defeated`), sans jamais annuler la
## première récompense,
## - 32A : Chen confie le starter resté sur la table, puis celui du rival (N5 [D]) ;
## - 32B : le chercheur du Mont Sélénite, au Labo de Cramois'Île, confie **son** fossile, une fois ;
## - 32C : le Maître du Dojo offre l'autre Poké Ball ;
## - 32D : deux Poké Balls d'Évoli de plus dans la maison du toit ;
## et rien de tout cela avant la Ligue.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_j32_post_league_gifts_save.json"
const LEAGUE := &"league_champion_defeated"
const FADE := 0.05
const TIMEOUT := 15.0

var _boot: Boot
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	Input.action_release(&"interact")


func test_oak_gives_the_table_starter_then_the_rivals() -> void:
	await _start(&"oak_lab", [LEAGUE, &"oak_met", &"starter_chosen", &"rival_left_lab",
		&"rival_battle_done", &"pokedex_activated", &"taken_bulbasaur", &"taken_charmander"])
	assert_not_null(_boot.get_map().get_npc(&"squirtle"), "Carapuce attend sur la table")
	await _talk(Vector2i(8, 5), Vector2i.UP)
	assert_eq(_species(), [&"rattata", &"squirtle", &"charmander"] as Array[StringName],
		"le starter de la table, puis celui du rival")
	assert_eq(GameState.party.get_at(1).level, 5)
	assert_true(_pages.has("Et ce n'est pas tout : un autre\nest arrivé au labo. Il est pour toi."))
	assert_null(_boot.get_map().get_npc(&"squirtle"), "la table est vide")
	assert_true(GameState.flags.has_flag(&"oak_post_league_gifts_done"))
	await _talk(Vector2i(8, 5), Vector2i.UP)
	assert_eq(GameState.party.size(), 3, "une seule fois")


func test_oak_gives_nothing_before_the_league() -> void:
	await _start(&"oak_lab", [&"oak_met", &"starter_chosen", &"rival_left_lab",
		&"rival_battle_done", &"pokedex_activated", &"taken_squirtle", &"taken_bulbasaur"])
	await _talk(Vector2i(8, 5), Vector2i.UP)
	assert_eq(GameState.party.size(), 1)


func test_the_dojo_master_offers_the_other_ball() -> void:
	await _start(&"fighting_dojo", [LEAGUE, &"fighting_dojo_master_defeated",
		&"dojo_got_hitmonlee"])
	await _talk(Vector2i(5, 4), Vector2i.UP)
	assert_eq(_species(), [&"rattata", &"hitmonchan"] as Array[StringName])
	assert_true(GameState.flags.has_flag(&"dojo_got_hitmonchan"))
	await _talk(Vector2i(5, 4), Vector2i.UP)
	assert_eq(GameState.party.size(), 2, "une seule fois")


func test_two_more_eevee_after_the_league() -> void:
	await _start(&"celadon_mansion_roof_house", [LEAGUE, &"eevee_received"])
	assert_null(_boot.get_map().get_npc(&"eevee_ball"), "la première est prise")
	for ball: Array in [[&"eevee_ball_2", Vector2i(6, 4)], [&"eevee_ball_3", Vector2i(8, 4)]]:
		assert_not_null(_boot.get_map().get_npc(ball[0]), String(ball[0]))
		await _talk(ball[1], Vector2i.UP)
		assert_null(_boot.get_map().get_npc(ball[0]), "%s prise" % ball[0])
	assert_eq(_species(), [&"rattata", &"eevee", &"eevee"] as Array[StringName])


func test_no_extra_eevee_before_the_league() -> void:
	await _start(&"celadon_mansion_roof_house", [&"eevee_received"])
	assert_null(_boot.get_map().get_npc(&"eevee_ball_2"))
	assert_null(_boot.get_map().get_npc(&"eevee_ball_3"))


func test_the_researcher_gives_his_fossil_once() -> void:
	await _start(&"cinnabar_lab_meeting", [LEAGUE, &"mt_moon_fossil_chosen",
		&"mt_moon_got_dome_fossil"])
	assert_not_null(_boot.get_map().get_npc(&"mt_moon_researcher_lab"))
	await _talk(Vector2i(12, 6), Vector2i.RIGHT)
	assert_eq(GameState.bag.count_of(&"helix_fossil"), 1, "son fossile : le Nautile")
	assert_eq(GameState.bag.count_of(&"dome_fossil"), 0)
	await _talk(Vector2i(12, 6), Vector2i.RIGHT)
	assert_eq(GameState.bag.count_of(&"helix_fossil"), 1, "une seule fois")


func test_the_researcher_is_absent_before_the_league() -> void:
	await _start(&"cinnabar_lab_meeting", [&"mt_moon_fossil_chosen", &"mt_moon_got_helix_fossil"])
	assert_null(_boot.get_map().get_npc(&"mt_moon_researcher_lab"))


# --- Outils -----------------------------------------------------------------------------------

func _start(map_id: StringName, flags: Array) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map_id
	_boot.start_spawn = &"entrance"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.new_game(32)
	GameState.player_name = "Kevin"
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"rattata", 10,
		GameState.rng))
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	# Les PNJ conditionnels suivent les drapeaux à l'entrée sur la carte : on y revient.
	await SceneRouter.change_map(map_id, &"entrance")
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable() \
		and _boot.get_map() != null and _boot.get_map().map_id == map_id, TIMEOUT)


func _talk(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_boot.get_player(), cell, facing)
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(true)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _species() -> Array[StringName]:
	var result: Array[StringName] = []
	for pokemon: Pokemon in GameState.party.get_all():
		result.append(pokemon.species_id)
	return result
