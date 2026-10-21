extends GutTest
## Casino de Céladopole : Rocket de l'affiche, affiche, interrupteur et mur coulissant (jalon 20
## T21, `jalon-20.md` §2.6 ; dossier 23 §12, §20.6 n° 39 à 43, annexe A.5 n° 95 à 100) avec la
## vraie scène Boot, la vraie carte `celadon_game_corner`, ses PNJ, ses vraies données et les
## vraies entrées :
## - données : Rocket devant l'affiche (9, 5) tourné ↑, vision 1, départ ; cinq PNJ et leurs
##   répliques ; affiche examinable depuis (9, 5) seulement, tournée ↑ ;
## - on lui parle → combat → n° 41 → il s'en va (absent ensuite) ;
## - l'affiche : n° 42 et la question ; NON → rien ; OUI → n° 43, drapeau `game_corner_switch`,
##   le mur disparaît, l'escalier (17, 4) mène au B1F ; ensuite l'affiche dit n° 100 ;
## - le passage reste ouvert au retour (drapeau sauvé, mur caché au chargement).

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/game_corner.json"
const MAP := &"celadon_game_corner"
const ROCKET := &"game_corner_rocket"
const ROCKET_CELL := Vector2i(9, 5)
const POSTER := Vector2i(9, 4)
const STAIRS := Vector2i(17, 4)
const BEATEN := &"beaten_celadon_game_corner_rocket"
const SWITCH := &"game_corner_switch"
const BEFORE: Array[String] = ["Cette affiche ne te regarde pas.", "Va jouer ailleurs."]
const DEFEATED := "Hé… Ne touche pas à l'affiche !"
const POSTER_LINES: Array[String] = ["Il y a un interrupteur derrière l'affiche.", "Appuyer ?"]
const SWITCH_LINE := "Un bruit sourd… Un passage s'est ouvert."
const OPEN_LINES: Array[String] = ["Derrière l'affiche, l'interrupteur.", "Le passage est ouvert."]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_game_corner_switch.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_the_poster_rocket_and_the_five_guests_are_placed() -> void:
	var roster := NpcRoster.load_for_map(MAP)
	var rocket := roster.get_spec(ROCKET)
	assert_not_null(rocket)
	assert_eq([rocket.cell, rocket.facing, rocket.sight, rocket.trainer_id],
		[ROCKET_CELL, Vector2i.UP, 1, &"celadon_game_corner_rocket"])
	assert_true(rocket.leaves, "il quitte la salle après sa défaite")
	assert_eq(rocket.unless_flags, [BEATEN] as Array[StringName])
	var expected := {
		&"game_corner_clerk": [Vector2i(5, 6), "Employé"],
		&"game_corner_client_1": [Vector2i(2, 10), "Client"],
		&"game_corner_client_2": [Vector2i(8, 11), "Cliente"],
		&"game_corner_client_3": [Vector2i(11, 15), "Client"],
		&"game_corner_client_4": [Vector2i(17, 13), "Client"],
	}
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	for id: StringName in expected:
		var spec := roster.get_spec(id)
		assert_not_null(spec, String(id))
		if spec == null:
			continue
		assert_eq(spec.cell, expected[id][0], String(id))
		assert_false(spec.is_trainer(), "%s : aucun combat" % id)
		assert_eq(dialogues.get_dialogue(spec.dialogue).speaker, expected[id][1], String(id))
	assert_eq(roster.get_all().size(), 6, "le Rocket et cinq PNJ (dossier 23 §12)")
	var map := (load(MapCatalog.scene_path(MAP)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	var front := map.get_interactions().find(POSTER, Vector2i.UP)
	assert_not_null(front, "affiche lue depuis (9, 5), tourné ↑")
	if front != null:
		assert_eq(front.dialogue_id, &"game_corner_poster")
	assert_null(map.get_interactions().find(POSTER, Vector2i.LEFT),
		"de côté : rien")


func test_beat_the_rocket_flip_the_switch_and_go_down() -> void:
	await _play.start(START)
	_play.make_strong()
	assert_not_null(_play.boot.get_map().get_npc(ROCKET), "le Rocket garde l'affiche")
	assert_false(_play.boot.get_map().get_grid().is_free(STAIRS), "mur fermé")
	# Lui parler depuis (10, 5), tourné vers l'ouest.
	await _play.walk_to(Vector2i(10, 5))
	assert_eq(_play.player.get_cell(), Vector2i(10, 5))
	assert_true(await _play.interact(Vector2i.LEFT), "le combat a eu lieu")
	var pages := _play.pages()
	assert_eq(pages.slice(0, 2), BEFORE)
	assert_true(pages.has(DEFEATED), "n° 41")
	assert_true(GameState.flags.has_flag(BEATEN))
	assert_null(_play.boot.get_map().get_npc(ROCKET), "il est parti")
	assert_false(GameState.flags.has_flag(SWITCH), "l'interrupteur attend")
	# L'affiche : NON ne fait rien.
	await _play.walk_to(ROCKET_CELL)
	_play.events.clear()
	await _play.interact(Vector2i.UP, false)
	assert_eq(_play.pages(), POSTER_LINES)
	assert_false(GameState.flags.has_flag(SWITCH), "NON : rien")
	assert_false(_play.boot.get_map().get_grid().is_free(STAIRS), "mur toujours fermé")
	# OUI : le mur coulisse, l'escalier apparaît.
	_play.events.clear()
	await _play.interact(Vector2i.UP, true)
	assert_eq(_play.pages(), POSTER_LINES + [SWITCH_LINE])
	assert_true(GameState.flags.has_flag(SWITCH))
	var wall := _play.boot.get_map().get_node(^"Entities/SlidingWall") as FlagGate
	assert_false(wall.visible, "mur caché")
	assert_true(_play.boot.get_map().get_grid().is_free(STAIRS), "escalier praticable")
	# Ensuite : texte n° 100.
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), OPEN_LINES)
	# L'escalier mène au B1F.
	await _play.walk_to(STAIRS)
	assert_eq(_play.map_id(), &"rocket_hideout_b1f", "descente au repaire")
	assert_eq(_play.player.get_cell(), Vector2i(21, 3), "arrivée from_casino")
	await wait_until(func() -> bool:
		return (_play.saved().get("flags", []) as Array).has(String(SWITCH)), 5.0)
	assert_true((_play.saved().get("flags", []) as Array).has(String(SWITCH)), "sauvé")
	assert_push_error_count(0)


func test_the_passage_stays_open_after_a_reload() -> void:
	await _play.start(START, func() -> void:
		GameState.flags.set_flag(BEATEN)
		GameState.flags.set_flag(SWITCH))
	assert_null(_play.boot.get_map().get_npc(ROCKET), "le Rocket n'est plus là")
	var wall := _play.boot.get_map().get_node(^"Entities/SlidingWall") as FlagGate
	assert_false(wall.visible, "mur ouvert au chargement")
	assert_true(_play.boot.get_map().get_grid().is_free(STAIRS))
	await _play.walk_to(ROCKET_CELL)
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), OPEN_LINES, "plus de question")
	assert_push_error_count(0)
