extends GutTest
## Dojo de Combat de Safrania (jalon 27, T9 et T10 ; `docs/tech/jalon-27.md` §2.3, §2.4, §5) sur la
## vraie scène Boot (`tests/helpers/hideout_play.gd`) :
## - indépendance : le Dojo se joue avec Safrania OCCUPÉE (départ `fighting_dojo`) ; sa porte de
##   Safrania ne porte aucun drapeau ;
## - le maître : défaite → réveil, rejouable ; victoire → `fighting_dojo_master_defeated` ;
## - les deux Poké Balls : avant la victoire, réplique du maître (T27-09) ; après, fiche, puis
##   « Choisir … ? » OUI / NON ; NON → rien ; OUI → UN Pokémon (N30, origine « gift ») et son
##   drapeau, les deux Balls disparaissent ; équipe pleine → Stockage (départ `dojo_choice`) ;
## - **transaction** : la seconde scène de don est désarmée ; l'autosave du don contient le
##   Pokémon et le drapeau ; relance de l'application → un seul Pokémon ; arrêt AVANT l'écriture
##   (sauvegarde d'avant la scène) → aucun Pokémon, les deux Balls sont là.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const START := "res://tools/debug_start/fighting_dojo.json"
const CHOICE := "res://tools/debug_start/dojo_choice.json"
const SAVE_PATH := "user://test_fighting_dojo.json"
const MASTER_FLAG := &"fighting_dojo_master_defeated"
const LEE := &"dojo_got_hitmonlee"
const CHAN := &"dojo_got_hitmonchan"
## Devant les Balls (4, 1) et (5, 1), et devant le maître (5, 3).
const BEFORE_LEE := Vector2i(4, 2)
const BEFORE_CHAN := Vector2i(5, 2)
const BEFORE_MASTER := Vector2i(5, 4)
const TIMEOUT := 15.0

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


## Élèves battus (le test vise le maître et les Balls ; leur vision est celle de RB).
func _beat_students() -> void:
	for trainer: String in ["hippolyte", "tancrede", "urbain", "wilfried"]:
		GameState.flags.set_flag(StringName("beaten_fighting_dojo_blackbelt_%s" % trainer))


func _hitmon_count() -> int:
	var count := 0
	for pokemon: Pokemon in GameState.party.get_all() + GameState.storage.get_all():
		if pokemon.species_id in [&"hitmonlee", &"hitmonchan"]:
			count += 1
	return count


func _place(cell: Vector2i) -> void:
	_play.boot.get_map().spawn_player_at(_play.player, cell, Vector2i.UP)
	await wait_process_frames(3)


func test_the_dojo_is_playable_while_saffron_is_occupied() -> void:
	await _play.start(START)
	assert_eq(_play.map_id(), &"fighting_dojo")
	assert_false(GameState.flags.has_flag(&"silph_giovanni_defeated"), "Safrania occupée")
	assert_not_null(_play.boot.get_map().get_npc(&"maitre"))
	assert_not_null(_play.boot.get_map().get_npc(&"ball_hitmonlee"))
	assert_not_null(_play.boot.get_map().get_npc(&"ball_hitmonchan"))
	var city := (load(MapCatalog.scene_path(&"saffron_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/safrania.txt"))
	for cell: Vector2i in plan.cells_at("porte_dojo"):
		var warp := city.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp)
		if warp != null:
			assert_eq(warp.target_map, &"fighting_dojo")
			assert_true(warp.unless_flags.is_empty(), "porte du Dojo : aucun drapeau")
	assert_push_error_count(0)


func test_balls_are_reserved_before_the_master_is_beaten() -> void:
	await _play.start(START, _beat_students)
	await _place(BEFORE_LEE)
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), ["Ces Pokémon sont réservés à qui me bat."] as Array[String])
	assert_eq(_hitmon_count(), 0)
	assert_false(GameState.flags.has_flag(LEE))
	assert_push_error_count(0)


func test_losing_to_the_master_wakes_up_and_can_be_replayed() -> void:
	await _play.start(START, _beat_students)
	_play.make_weak()
	await _place(BEFORE_MASTER)
	assert_true(await _play.interact(Vector2i.UP), "combat contre le maître")
	assert_false(GameState.flags.has_flag(MASTER_FLAG), "défaite : pas de victoire")
	assert_true(_play.pages().has("Ha ! Un challenger !"), "T27-07")


func test_beating_the_master_then_no_then_yes_gives_exactly_one_pokemon() -> void:
	await _play.start(START, _beat_students)
	_play.make_strong()
	await _place(BEFORE_MASTER)
	assert_true(await _play.interact(Vector2i.UP), "combat contre le maître")
	assert_true(GameState.flags.has_flag(MASTER_FLAG))
	assert_true(_play.pages().has("Choisis l'un de nos Pokémon. Il te suivra."), "T27-08")
	_play.events.clear()
	await _place(BEFORE_CHAN)
	await _play.interact(Vector2i.UP, false)
	assert_eq(_play.pages(), ["TYGNON, le Pokémon Puncheur.",
		"Ses poings sont plus rapides que l'œil.", "Choisir TYGNON ?"] as Array[String],
		"T27-11 et T27-12")
	assert_eq(_hitmon_count(), 0, "NON : rien")
	assert_not_null(_play.boot.get_map().get_npc(&"ball_hitmonchan"))
	_play.events.clear()
	await _play.interact(Vector2i.UP, true)
	assert_eq(_hitmon_count(), 1, "OUI : un Pokémon")
	assert_true(GameState.flags.has_flag(CHAN))
	assert_false(GameState.flags.has_flag(LEE))
	var chan: Pokemon = GameState.party.get_at(GameState.party.size() - 1)
	assert_eq([chan.species_id, chan.level, chan.origin],
		[&"hitmonchan", 30, Pokemon.Origin.GIFT])
	assert_true(_play.pages().has("Kevin reçoit Tygnon !"))
	assert_true(_play.pages().has("Prends-en soin. Et reviens t'entraîner quand tu veux !"),
		"T27-13")
	assert_null(_play.boot.get_map().get_npc(&"ball_hitmonchan"), "Ball prise")
	assert_null(_play.boot.get_map().get_npc(&"ball_hitmonlee"), "l'autre Ball disparaît")
	assert_false(_play.boot.get_cutscene_director().play(&"fighting_dojo_take_hitmonlee"),
		"second don désarmé")
	assert_eq(_hitmon_count(), 1, "jamais deux")
	assert_push_error_count(0)


func test_full_party_sends_the_choice_to_the_storage_and_survives_a_restart() -> void:
	await _play.start(CHOICE)
	assert_eq(GameState.party.size(), 6)
	var before := GameState.storage.size()
	await _place(BEFORE_LEE)
	await _play.interact(Vector2i.UP, true)
	assert_eq(GameState.party.size(), 6, "équipe inchangée")
	assert_eq(GameState.storage.size(), before + 1, "Kicklee au Stockage")
	assert_true(_play.pages().has("Kicklee a été envoyé au stockage."))
	assert_true(GameState.flags.has_flag(LEE))
	# Écriture immédiate (autosave du don) : le Pokémon et le drapeau ensemble.
	await wait_until(func() -> bool:
		return String(LEE) in JSON.stringify(_play.saved()), TIMEOUT)
	var saved := JSON.stringify(_play.saved())
	assert_string_contains(saved, String(LEE))
	assert_string_contains(saved, "hitmonlee")
	# Application tuée puis relancée.
	await _play.resume()
	assert_eq(_play.map_id(), &"fighting_dojo")
	assert_eq(_hitmon_count(), 1, "un seul Pokémon après la relance")
	assert_null(_play.boot.get_map().get_npc(&"ball_hitmonlee"))
	assert_null(_play.boot.get_map().get_npc(&"ball_hitmonchan"))
	assert_push_error_count(0)


func test_a_stop_before_the_write_leaves_nothing_changed() -> void:
	await _play.start(CHOICE)
	# Sauvegarde d'avant la scène (point de reprise) ; l'application s'arrête avant OUI.
	_play.boot.request_autosave("test")
	await wait_until(func() -> bool: return not _play.saved().is_empty(), TIMEOUT)
	await _play.resume()
	assert_eq(_hitmon_count(), 0, "aucun Pokémon")
	assert_false(GameState.flags.has_flag(LEE) or GameState.flags.has_flag(CHAN))
	assert_not_null(_play.boot.get_map().get_npc(&"ball_hitmonlee"))
	assert_not_null(_play.boot.get_map().get_npc(&"ball_hitmonchan"))
	assert_push_error_count(0)


## Point non vu en QA téléphone (2026-10-25) : le défi de Karatéka Wilfried comparé à la grille
## (`safrania_dojo.txt`, « dresseur_4 », RB objet 5) : case (5, 7), tourné vers l'ouest, vision 3 ;
## équipe RB Machoc, Férosinge, Colossinge N31. Joué : à 4 cases rien ne se passe, au pas suivant
## (3 cases) il repère le joueur et le combat a lieu ; battu, il ne relance plus le défi.
func test_wilfried_challenges_exactly_as_the_grid_says() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/safrania_dojo.txt"))
	var cell: Vector2i = plan.cells_at("dresseur_4")[0]
	var sight := int(plan.attr("dresseur_4", "sight"))
	assert_eq(plan.attr("dresseur_4", "trainer"), "fighting_dojo_blackbelt_wilfried")
	assert_eq([cell, plan.attr("dresseur_4", "facing"), sight], [Vector2i(5, 7), "left", 3])
	var team: Array = []
	for slot: TrainerSlot in _trainer(&"fighting_dojo_blackbelt_wilfried").team:
		team.append([slot.species, slot.level])
	assert_eq(team, [[&"machop", 31], [&"mankey", 31], [&"primeape", 31]], "équipe RB")
	await _play.start(START, func() -> void:
		for trainer: String in ["hippolyte", "tancrede", "urbain"]:
			GameState.flags.set_flag(StringName("beaten_fighting_dojo_blackbelt_%s" % trainer)))
	_play.make_strong()
	var npc := _play.boot.get_map().get_npc(&"wilfried")
	assert_not_null(npc)
	if npc == null:
		return
	assert_eq(npc.get_cell(), cell, "Wilfried sur la case de la grille")
	var outside := cell + Vector2i.LEFT * (sight + 1)
	_play.boot.get_map().spawn_player_at(_play.player, outside, Vector2i.RIGHT)
	await wait_process_frames(10)
	assert_false(_play.boot.get_cutscene_director().is_running(), "à %d cases : rien" % (sight + 1))
	var battles := _play.events.count("battle")
	await _play.step(Vector2i.RIGHT)
	assert_eq(_play.player.get_cell(), cell + Vector2i.LEFT * sight, "un pas dans sa vision")
	assert_true(await _play.run_scene(), "Wilfried repère le joueur et le combat a lieu")
	assert_eq(_play.events.count("battle"), battles + 1)
	assert_true(GameState.flags.has_flag(&"beaten_fighting_dojo_blackbelt_wilfried"))
	assert_true(_play.pages().has(_first_page(&"fighting_dojo_blackbelt_wilfried_before")),
		"réplique d'avant-combat")
	assert_push_error_count(0)


func _trainer(id: StringName) -> TrainerData:
	var data := PokemonData.new()
	data.load_dir()
	var library := TrainerLibrary.new(data)
	library.load_dir()
	return library.get_trainer(id)


func _first_page(id: StringName) -> String:
	var library := DialogueLibrary.new()
	library.load_dir()
	return String(library.get_dialogue(id).variants[0].pages[0].text).replace("\n", " ")
