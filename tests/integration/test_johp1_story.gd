extends GutTest
## Arc des Pierres, JOHP1 (`docs/tech/jalon-joh-pierres.md` §3, critères) : le **vrai Boot** sur les
## départs de débogage, vraies entrées et vrais combats (`hideout_play.gd`) : de la Route 36 à la
## Pierre Mémoire et retour chez Héloïse ; mauvaises dalles ; barrière de chantier ; défaite contre
## le faux archéologue. Système de fichiers en mémoire : jamais le vrai `user://`.

const Play := preload("res://tests/helpers/hideout_play.gd")
const STARTS := "res://tools/debug_start/"

const QUEST: StringName = &"johto_stones_quest"
const TILE_1: StringName = &"johto_alph_tile_1"
const TILE_2: StringName = &"johto_alph_tile_2"
const TILES_DONE: StringName = &"johto_alph_tiles_done"
const STONE: StringName = &"johto_stone_memory"

var _play: Play


func before_each() -> void:
	_play = Play.new(self, "user://test_johp1_story_save.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


## Marche jusqu'à [param goal] ; un Dresseur qui repère le joueur est battu en chemin.
func _go(goal: Vector2i) -> void:
	for attempt: int in 8:
		await _play.walk_to(goal)
		await _play.run_scene()
		if _play.player.get_cell() == goal:
			return
	assert_eq(_play.player.get_cell(), goal, "arrivée")


func _step_scene(direction: Vector2i) -> void:
	await _play.step(direction)
	await _play.run_scene()


func _said(text: String) -> bool:
	for page: String in _play.pages():
		if page.contains(text):
			return true
	return false


func test_from_route_36_to_the_stone_and_back_to_heloise() -> void:
	await _play.start(STARTS + "johto_alph_route_36.json", _play.make_strong)
	# P-2 : le premier passage de la barrière de chantier, en descendant.
	await _go(Vector2i(40, 16))
	await _step_scene(Vector2i.DOWN)
	assert_true(_said("Passe, c'est ouvert."), "P-2")
	await _go(Vector2i(40, 19))
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.map_id(), &"ruins_of_alph", "bord sud de la Route 36")
	assert_eq(_play.player.get_cell(), Vector2i(17, 1))
	# Héloïse (P-3, P-4).
	await _go(Vector2i(8, 14))
	await _play.step(Vector2i.UP)
	assert_eq(_play.map_id(), &"alph_tent")
	await _go(Vector2i(4, 3))
	await _play.interact(Vector2i.UP)
	assert_true(_said("Ils tiennent leurs pelles à l'envers."), "P-3")
	assert_true(_said("Lis les murs."), "P-4")
	assert_true(GameState.flags.has_flag(&"johto_alph_met"))
	await _go(Vector2i(4, 6))
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.map_id(), &"ruins_of_alph")
	assert_eq(_play.player.get_cell(), Vector2i(8, 14))
	# La Galerie : le Sbire X garde le goulet (inévitable).
	await _go(Vector2i(17, 18))
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.map_id(), &"alph_gallery")
	assert_eq(_play.player.get_cell(), Vector2i(4, 13), "case à case")
	await _go(Vector2i(16, 11))
	assert_true(GameState.flags.has_flag(TrainerRules.beaten_flag(&"alph_grunt_x")), "Sbire X")
	# Les trois bonnes dalles, puis l'escalier.
	await _step_scene(Vector2i.UP)
	assert_true(GameState.flags.has_flag(TILE_1))
	await _go(Vector2i(18, 8))
	await _step_scene(Vector2i.UP)
	assert_true(GameState.flags.has_flag(TILE_2))
	await _go(Vector2i(15, 5))
	await _step_scene(Vector2i.UP)
	assert_true(GameState.flags.has_flag(TILES_DONE))
	assert_true(_said("La porte du fond s'ouvre."), "P-45")
	await _go(Vector2i(16, 3))
	await _play.step(Vector2i.UP)
	assert_eq(_play.map_id(), &"alph_chamber")
	# Le faux archéologue (P-6, P-7), la pierre (P-8).
	assert_not_null(_play.boot.get_map().get_npc(&"faux_archeologue"))
	_play.make_strong() # équipe neuve : le chemin l'a usée.
	await _go(Vector2i(6, 8))
	await _step_scene(Vector2i.UP)
	assert_true(_play.events.has("battle"))
	assert_true(_said("Mon déguisement était parfait, pourtant !"), "P-6")
	assert_true(_said("arrache sa fausse barbe"), "P-7")
	assert_null(_play.boot.get_map().get_npc(&"faux_archeologue"), "il s'enfuit")
	await _go(Vector2i(6, 4))
	await _play.interact(Vector2i.UP)
	assert_true(GameState.flags.has_flag(STONE))
	assert_eq(GameState.bag.count_of(&"stone_memory"), 1, "P-8")
	assert_true(_said("obtient la Pierre Mémoire"), "P-8")
	# Retour par la Galerie, puis P-10.
	await _go(Vector2i(6, 9))
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.map_id(), &"alph_gallery")
	assert_eq(_play.player.get_cell(), Vector2i(16, 3))
	await SceneRouter.change_map(&"ruins_of_alph", &"retour_tente", Vector2i.UP)
	await wait_process_frames(3)
	await _play.step(Vector2i.UP)
	await _go(Vector2i(4, 3))
	await _play.interact(Vector2i.UP)
	assert_true(_said("Va voir le vieux Goulven"), "P-10")


func test_a_wrong_tile_sends_back_and_clears_the_ranks() -> void:
	await _play.start(STARTS + "johto_alph_tiles.json", _play.make_strong)
	assert_eq(_play.player.get_cell(), Vector2i(16, 12))
	await _go(Vector2i(15, 11))
	await _step_scene(Vector2i.UP)
	assert_true(_said("Le sol gronde."), "P-45")
	assert_eq(_play.player.get_cell(), Vector2i(16, 12), "retour à l'entrée de la salle")
	# Bonne dalle, puis mauvaise au rang suivant : tout est à refaire.
	await _go(Vector2i(16, 11))
	await _step_scene(Vector2i.UP)
	assert_true(GameState.flags.has_flag(TILE_1))
	await _go(Vector2i(15, 8))
	await _step_scene(Vector2i.UP)
	assert_false(GameState.flags.has_flag(TILE_1), "les rangs retombent")
	assert_eq(_play.player.get_cell(), Vector2i(16, 12))
	assert_false(GameState.flags.has_flag(TILES_DONE))
	var lit := _play.boot.get_map().find_child("Lueur_16_10", true, false) as FlagGate
	assert_not_null(lit)
	assert_false(lit.visible, "la dalle s'éteint")


func test_the_door_stays_closed_without_the_tiles() -> void:
	await _play.start(STARTS + "johto_alph_tiles.json")
	var grid := _play.boot.get_map().get_grid()
	assert_true(grid.is_occupied(Vector2i(16, 2)), "porte du fond fermée")
	GameState.flags.set_flag(TILES_DONE)
	await wait_process_frames(2)
	assert_false(grid.is_occupied(Vector2i(16, 2)), "porte ouverte par le drapeau")


func test_the_worksite_stays_closed_before_the_quest() -> void:
	await _play.start(STARTS + "johto_alph_route_36.json", func() -> void:
		_play.make_strong()
		GameState.flags.set_flag(QUEST, false))
	await SceneRouter.change_map(&"route_36", &"from_route_35", Vector2i.UP)
	await wait_process_frames(3)
	await _go(Vector2i(40, 16))
	await _step_scene(Vector2i.DOWN)
	assert_true(_said("Entrée réservée au personnel."), "P-42")
	assert_eq(_play.player.get_cell(), Vector2i(40, 16), "un pas en arrière")
	assert_true(_play.boot.get_map().get_grid().is_occupied(Vector2i(40, 18)), "barrière")


func test_losing_to_the_fake_archeologist_wakes_up_at_the_center() -> void:
	await _play.start(STARTS + "johto_alph_chamber.json", _play.make_weak)
	await _go(Vector2i(6, 8))
	await _step_scene(Vector2i.UP)
	assert_eq(_play.map_id(), &"goldenrod_center", "dernier Centre")
	assert_false(GameState.flags.has_flag(&"johto_alph_fake_defeated"))
	assert_false(GameState.flags.has_flag(STONE))
