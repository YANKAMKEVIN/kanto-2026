extends GutTest
## JOHP3 (`jalon-joh-pierres.md` §5.4, dossier JOH-11 §15) : la bascule touche une sauvegarde
## sensible. Le **vrai Boot** joue l'autel, l'application est tuée à chaque écriture, une nouvelle
## Boot reprend sur le fichier écrit :
## - tuée pendant le Réveil, avant l'écriture : rien n'a changé, la scène reprend à l'autel ;
## - tuée après l'écriture du Réveil : réveil acquis, la scène reprend à Cenere ;
## - tuée sur l'écran du choix des 6 : rien d'écrit, l'équipe reste confisquée, la scène rejoue ;
## - VALIDER : T-29, une écriture, reprise sur le fichier = acte 1 fini, Exp ×1,5 retiré.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START_ALTAR := "res://tools/debug_start/johto_den_altar.json"
const START_CENERE := "res://tools/debug_start/johto_den_cenere.json"
const TIMEOUT_MS := 30000

## Jamais émis : la cinématique du Réveil qui ne finit pas (application tuée pendant qu'elle joue).
signal _never

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_johp3_resume_save.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


## Fait défiler les pages jusqu'à [param done].
func _advance_until(done: Callable) -> void:
	var box := _play.boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not done.call() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)


func _saved_flags() -> Array:
	return _play.saved().get("flags", []) as Array


func _overlay() -> TeamReturnOverlay:
	return _play.boot._team_return_overlay


## Trois Mewtwo N100 (Météores) : gagnent tout ; équipe de Kanto de 5 : 8 Pokémon, écran des 6.
func _strong() -> void:
	GameState.party.clear()
	for i: int in 3:
		var extra := PokemonFactory.create(_play.boot.get_pokemon_data(), &"mewtwo", 100,
			GameState.rng)
		extra.moves.clear()
		extra.moves.append(MoveSlot.new(&"swift", 20))
		GameState.party.add(extra)


## Quatre Pokémon de Johto, rencontrés à Oliville : le Réveil les monte.
func _johto_team() -> void:
	for pokemon: Pokemon in GameState.party.get_all():
		pokemon.met_map = &"olivine_city"


func test_killed_during_the_awakening_nothing_changed() -> void:
	await _play.start(START_ALTAR, _johto_team)
	await _play.step(Vector2i.DOWN)
	await _play.step(Vector2i.UP)
	var written := _play.saved()
	assert_false(written.is_empty(), "une partie est écrite")
	var levels: Array = []
	for pokemon: Pokemon in GameState.party.get_all():
		levels.append(pokemon.level)
	var director := _play.boot.get_cutscene_director()
	director.awakening_handler = func(_report: AwakeningReport) -> void: await _never
	await _play.step(Vector2i.UP)
	await _advance_until(func() -> bool: return GameState.flags.has_flag(&"johto_stones_awakened"))
	assert_true(GameState.flags.has_flag(&"johto_stones_awakened"), "en mémoire seulement")
	assert_false(_saved_flags().has("johto_stones_awakened"), "rien d'écrit pendant la cinématique")
	await _play.resume()
	assert_false(GameState.flags.has_flag(&"johto_stones_awakened"), "la scène reprend à l'autel")
	assert_eq(GameState.bag.count_of(&"stone_breath"), 1, "les pierres sont toujours là")
	for i: int in levels.size():
		assert_eq(GameState.party.get_all()[i].level, levels[i], "niveau d'avant")
	assert_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere reviendra avec la scène")


func test_killed_after_the_awakening_write_resumes_at_cenere() -> void:
	await _play.start(START_ALTAR, _johto_team)
	await _play.step(Vector2i.DOWN)
	await _play.step(Vector2i.UP)
	await _play.step(Vector2i.UP)
	await _advance_until(func() -> bool: return _saved_flags().has("johto_stones_awakened"))
	assert_true(_saved_flags().has("johto_stones_awakened"), "écriture du Réveil")
	await _play.resume()
	assert_true(GameState.flags.has_flag(&"johto_stones_awakened"))
	assert_eq(_play.map_id(), &"dragons_den_sanctuary")
	assert_not_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere à l'autel")
	assert_gt(GameState.party.get_lead().level, 54, "équipe réveillée")
	assert_false(GameState.flags.has_flag(&"johto_team_returned"))
	assert_false(GameState.confiscated.is_empty(), "mallette non rendue")


func test_choice_screen_survives_a_kill_then_writes_once() -> void:
	await _play.start(START_CENERE, func() -> void:
		_strong()
		GameState.flags.set_flag(&"johto_cenere_defeated_arc"))
	assert_eq(GameState.party.size() + GameState.confiscated.party.size(), 8)
	var stored_before := GameState.storage.size()
	await _play.step(Vector2i.DOWN)
	await _play.step(Vector2i.UP)
	await _play.step(Vector2i.UP)
	await _advance_until(func() -> bool: return _overlay().is_open())
	assert_true(_overlay().is_open(), "écran du choix des 6")
	assert_false(_saved_flags().has("johto_team_returned"), "rien d'écrit avant VALIDER")
	# Application tuée pendant l'écran : la partie reprend avec l'équipe confisquée.
	await _play.resume()
	assert_eq(GameState.confiscated.party.size(), 5, "jamais d'équipe perdue")
	assert_false(GameState.flags.has_flag(&"johto_team_returned"))
	assert_eq(_play.map_id(), &"dragons_den_sanctuary")
	await _play.step(Vector2i.DOWN)
	await _play.step(Vector2i.UP)
	await _advance_until(func() -> bool: return _overlay().is_open())
	assert_true(_overlay().is_open(), "la scène rejoue")
	_overlay().get_confirm_button().pressed.emit()
	await _play.run_scene()
	assert_eq(GameState.party.size(), 6)
	assert_eq(GameState.storage.size(), stored_before + 2, "les 2 autres au Stockage")
	assert_true(_play.pages().has("Connexion rétablie ! Les autres Pokémon sont au Stockage."), "P-36")
	assert_false(GameState.flags.has_flag(&"johto_return_stored"), "drapeau de travail baissé")
	var saved := _play.saved()
	assert_eq((saved.get("party", []) as Array).size(), 6)
	assert_false(saved.has("confiscated"))
	# Reprise sur le fichier écrit : l'acte 1 est fini.
	await _play.resume()
	assert_true(GameState.flags.has_flag(&"johto_team_returned"))
	assert_false(GameState.flags.has_flag(&"johto_act1"))
	assert_false(GameState.flags.has_flag(&"storage_offline"))
	assert_eq(TeamConfiscation.exp_bonus(GameState.flags), 1.0, "×1,5 retiré")
	assert_eq(GameState.party.size(), 6)
	assert_eq(GameState.bag.count_of(&"great_ball"), 7, "sacs fusionnés (P-37)")


func test_an_unhatched_egg_comes_back_with_the_team() -> void:
	await _play.start(START_CENERE, func() -> void:
		_strong()
		GameState.party.remove_at(0)
		GameState.party.add(EggRules.create(_play.boot.get_pokemon_data(), &"togepi", 800,
			GameState.rng))
		GameState.confiscated.party.resize(3)
		GameState.flags.set_flag(&"johto_cenere_defeated_arc"))
	await _play.step(Vector2i.DOWN)
	await _play.step(Vector2i.UP)
	await _play.step(Vector2i.UP)
	await _play.run_scene()
	assert_false(_overlay().is_open(), "6 Pokémon en tout : pas d'écran")
	assert_true(GameState.flags.has_flag(&"johto_team_returned"))
	var eggs := 0
	for pokemon: Pokemon in GameState.party.get_all():
		if pokemon.egg_steps > 0:
			eggs += 1
	assert_eq(eggs, 1, "l'œuf non éclos revient dans l'équipe")
