extends GutTest
## Parcours 04 — Ligue (jalon 33, T5 ; `docs/design/passes/j33-v1-chatgpt.md` §7) : Conseil des
## Quatre, Champion et Panthéon d'une seule traite, sur la vraie partie ([ParcoursPlay]) :
## - salle d'Olga (départ `league_lorelei`, 8 Badges) → Aldo → Agatha → Peter → le rival, chaque
##   combat lancé par le premier pas, gagné, porte nord ouverte puis franchie ;
## - équipe du rival = celle de son starter (Salamèche choisi → Tortank en dernier) ;
## - cérémonie : Panthéon (une entrée, l'équipe victorieuse), générique, Bourg Palette ;
## - sauvegarde relue à l'identique après la relance (titre, Badges, Panthéon).

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const START := "res://tools/debug_start/league_lorelei.json"
const ROOMS: Array[StringName] = [&"league_lorelei", &"league_bruno", &"league_agatha",
	&"league_lance", &"league_champion"]
const TRAINERS: Array[StringName] = [&"league_lorelei", &"league_bruno", &"league_agatha",
	&"league_lance", &"rival_champion"]
## Porte nord de chaque salle (case de la porte) et case d'appel la plus proche (déclencheurs
## `Appel*` des scènes) : le couloir de Peter est long, son appel n'est pas au premier pas.
const NORTH_DOORS: Array[Vector2i] = [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0),
	Vector2i(5, 0), Vector2i(3, 0)]
const CALLS: Array[Vector2i] = [Vector2i(4, 9), Vector2i(4, 9), Vector2i(4, 9), Vector2i(5, 12),
	Vector2i(4, 5)]

var _play: ParcoursPlay


func before_each() -> void:
	_play = ParcoursPlay.new(self, "04_ligue")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_parcours_04_conseil_champion_pantheon() -> void:
	_play.begin("Entrée dans la salle d'Olga")
	await _play.start(START, _play.make_ace)
	_play.expect(_play.map_id() == &"league_lorelei", "salle d'Olga")
	_play.expect(LeagueAttempt.is_active(GameState.flags), "tentative commencée")
	for stage: int in 4:
		await _fight_room(stage)
		_play.begin("Porte nord de %s" % ROOMS[stage])
		var door: Vector2i = NORTH_DOORS[stage]
		await _play.walk_to(door + Vector2i.DOWN)
		await _play.step(Vector2i.UP)
		_play.expect(_play.map_id() == ROOMS[stage + 1], "arrivée dans %s" % ROOMS[stage + 1])
	_play.expect(LeagueAttempt.current_stage(GameState.flags) == 4, "étape du Champion")
	var party_before := _play.party_species()
	await _fight_room(4, false)
	_play.begin("Cérémonie")
	var rival := _play.last_battle(&"rival_champion")
	_play.expect(rival.get("foe", []) == _play.trainer_species(&"rival_champion", &"charmander"),
		"équipe du rival contre Salamèche (%s)" % [rival.get("foe", [])])
	_play.expect((rival.get("foe", []) as Array).back() == &"blastoise", "Tortank en dernier")
	_play.expect(_play.map_id() == &"pallet_town", "retour à Bourg Palette")
	_play.expect(LeagueAttempt.is_champion(GameState.flags), "titre de Champion")
	_play.expect(not LeagueAttempt.is_active(GameState.flags), "tentative close")
	_play.expect(GameState.flags.has_flag(LeagueAttempt.CREDITS_SEEN), "générique vu")
	_play.expect(GameState.hall_of_fame.size() == 1, "une entrée au Panthéon")
	if GameState.hall_of_fame.size() == 1:
		var team: Array = (GameState.hall_of_fame.get_entry(0)["team"] as Array).map(
			func(member: Dictionary) -> StringName: return StringName(member["species"]))
		_play.expect(team == party_before, "l'équipe victorieuse, dans l'ordre")
	_play.expect_flags(["badge_boulder", "badge_cascade", "badge_thunder", "badge_rainbow",
		"badge_soul", "badge_marsh", "badge_volcano", "badge_earth"], "8 Badges gardés")
	_play.begin("Relance après la Ligue")
	await _play.persist()
	_play.expect(LeagueAttempt.is_champion(GameState.flags), "titre relu")
	_play.expect(GameState.hall_of_fame.size() == 1, "Panthéon relu")
	assert_true(_play.report())
	assert_push_error_count(0)


## Premier pas vers le membre de la salle [param stage] : appel, combat, victoire.
func _fight_room(stage: int, check_door: bool = true) -> void:
	_play.begin("Combat de %s" % TRAINERS[stage])
	_play.heal()
	await _play.walk_to(CALLS[stage])
	await _play.run_scene()
	_play.expect(_play.won(TRAINERS[stage]), "combat gagné")
	if not check_door:
		return
	_play.expect(GameState.flags.has_flag(LeagueAttempt.stage_flag(stage)), "étape franchie")
	_play.expect(not _play.boot.get_map().get_grid().is_occupied(NORTH_DOORS[stage]),
		"porte nord ouverte")
