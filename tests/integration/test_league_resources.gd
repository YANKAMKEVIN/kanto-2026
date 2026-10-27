extends GutTest
## Ressources pendant la tentative de Ligue (jalon 30, `jalon-30.md` §2.2, §5) : aucun soin gratuit.
## - données : les cinq combats sont `heal_after: false`, `can_lose: false`, IA `smart` ;
## - aucune salle n'a de soin (ni infirmière, ni Centre, ni point de repos) ;
## - passer d'une salle à l'autre garde PV, PP, statuts et Sac ;
## - une victoire ne soigne pas : PV et PP restent ceux de la fin du combat.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const AGATHA := "res://tools/debug_start/league_agatha.json"
const LORELEI := "res://tools/debug_start/league_lorelei.json"
const SAVE_PATH := "user://test_league_resources_save.json"
const ROOMS: Array[StringName] = [&"league_lorelei", &"league_bruno", &"league_agatha",
	&"league_lance", &"league_champion", &"hall_of_fame"]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _party_state() -> Array:
	var rows: Array = []
	for pokemon: Pokemon in GameState.party.get_all():
		var pp: Array[int] = []
		for slot: MoveSlot in pokemon.moves:
			pp.append(slot.pp)
		rows.append([pokemon.species_id, pokemon.hp, pokemon.status, pp])
	return rows


func test_league_battles_never_heal() -> void:
	var pokemon := PokemonData.new()
	pokemon.load_dir()
	var trainers := TrainerLibrary.new(pokemon)
	trainers.load_dir()
	for trainer_id: StringName in LeagueAttempt.TRAINERS:
		var trainer := trainers.get_trainer(trainer_id)
		assert_not_null(trainer, String(trainer_id))
		assert_false(trainer.heal_after, "%s : heal_after false" % trainer_id)
		assert_false(trainer.can_lose, "%s : défaite = réveil" % trainer_id)
		assert_eq(trainer.ai, &"smart", "%s : IA smart" % trainer_id)


func test_no_room_offers_healing() -> void:
	var rest_points := RestPointLibrary.new()
	rest_points.load_file()
	for map_id: StringName in ROOMS:
		assert_false(rest_points.has_point(map_id), "%s : pas de point de repos" % map_id)
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			assert_ne(spec.sprite, &"nurse", "%s : pas d'infirmière" % map_id)
			assert_true(spec.is_trainer() or spec.sprite == &"oak",
				"%s : seulement le membre (et Chen)" % map_id)


func test_changing_rooms_keeps_hp_pp_status_and_bag() -> void:
	await _play.start(AGATHA)
	var party := _party_state()
	var bag: int = (GameState.bag as Bag).count_of(&"full_restore")
	await SceneRouter.change_map(&"league_lance", &"from_south", Vector2i.LEFT)
	await wait_process_frames(3)
	assert_eq(_play.map_id(), &"league_lance")
	assert_eq(_party_state(), party, "PV, PP et statuts inchangés")
	assert_eq((GameState.bag as Bag).count_of(&"full_restore"), bag)
	assert_push_error_count(0)


func test_a_victory_does_not_heal() -> void:
	await _play.start(LORELEI, func() -> void:
		var ace := PokemonFactory.create(_play.boot.get_pokemon_data(), &"alakazam", 100,
			GameState.rng)
		ace.moves.clear()
		ace.moves.append(MoveSlot.new(&"thunderbolt", 15))
		ace.hp = 120
		GameState.party.remove_at(0)
		GameState.party.add(ace)
		GameState.party.move(GameState.party.size() - 1, 0))
	await _play.step(Vector2i.UP)
	assert_true(await _play.run_scene(), "combat contre Olga")
	assert_true(GameState.flags.has_flag(&"league_stage_0_cleared"))
	var ace: Pokemon = GameState.party.get_at(0)
	assert_lte(ace.hp, 120, "aucun soin après la victoire")
	assert_lt(ace.moves[0].pp, 15, "PP dépensés, non rendus")
	assert_push_error_count(0)
