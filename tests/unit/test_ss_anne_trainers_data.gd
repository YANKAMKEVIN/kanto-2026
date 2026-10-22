extends GutTest
## Dresseurs du jalon 16 (T4 ; dossier 19 §4, §5, §9 et §0 R-5, R-10, R-12) : les 10 du navire,
## les 3 de l'Arène, Major Bob et le rival n° 4 se chargent ; aucune mécanique exclue (dossier 19
## §17) ; noms uniques parmi tous les Dresseurs ; rival n° 4 selon le starter du joueur.

const SHIP: Array[StringName] = [
	&"ss_anne_gentleman_armand", &"ss_anne_sailor_erwan", &"ss_anne_sailor_loic",
	&"ss_anne_gentleman_emile", &"ss_anne_sailor_yann", &"ss_anne_sailor_remi",
	&"ss_anne_lass_lena", &"ss_anne_scout_basile", &"ss_anne_gentleman_victor",
	&"ss_anne_sailor_paul",
]
const GYM: Array[StringName] = [
	&"vermilion_gym_gentleman_louis", &"vermilion_gym_rocker_axel", &"vermilion_gym_sailor_marc",
]
## Mécaniques exclues (dossier 19 §17 « Effets exclus »).
const FORBIDDEN: Array[StringName] = [
	&"self_destruct", &"explosion", &"disable", &"teleport", &"light_screen", &"reflect",
	&"double_team",
]

var _data: PokemonData
var _trainers: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_trainers = TrainerLibrary.new(_data)
	assert_true(_trainers.load_dir(), "\n".join(_trainers.get_errors()))


func _slots(id: StringName) -> Array[TrainerSlot]:
	var trainer := _trainers.get_trainer(id)
	var slots: Array[TrainerSlot] = []
	if trainer == null:
		return slots
	if trainer.team_by_starter.is_empty():
		slots.assign(trainer.team)
	else:
		for starter: StringName in trainer.team_by_starter:
			slots.append_array(trainer.team_by_starter[starter])
	return slots


func test_all_present_with_allowed_moves() -> void:
	var ids: Array[StringName] = []
	ids.append_array(SHIP)
	ids.append_array(GYM)
	ids.append_array([&"vermilion_gym_surge", &"rival_ss_anne"] as Array[StringName])
	for id: StringName in ids:
		assert_true(_trainers.has_trainer(id), String(id))
		for slot: TrainerSlot in _slots(id):
			assert_false(slot.moves.is_empty(), "%s : capacités choisies à la main" % id)
			for move: StringName in slot.moves:
				assert_not_null(_data.get_move(move), "%s : %s existe" % [id, move])
				assert_false(FORBIDDEN.has(move), "%s : %s est exclue" % [id, move])


func test_names_unique_across_all_trainers() -> void:
	var seen := {}
	for id: StringName in _trainers.get_ids():
		var name := _trainers.get_trainer(id).name
		# Jalon 28 (comme le J26) : Giovanni, même personnage, combats distincts.
		if name.begins_with("{") or name == "Sbire Rocket" or name == "Giovanni":
			continue
		assert_false(seen.has(name), "%s : nom déjà pris par %s" % [name, seen.get(name, "")])
		seen[name] = id


func test_surge() -> void:
	var bob := _trainers.get_trainer(&"vermilion_gym_surge")
	assert_eq([bob.name, bob.ai, bob.can_lose, bob.can_switch, bob.card_name],
		["Major Bob", BattleAI.SMART, false, true, "MAJOR BOB"], "change de Pokémon (Kevin, 2026-10-15)")
	var species: Array[StringName] = []
	for slot: TrainerSlot in bob.team:
		species.append(slot.species)
	assert_eq(species, [&"voltorb", &"pikachu", &"raichu"] as Array[StringName], "F-5")
	# Décision de Kevin du 2026-10-16 (R-3) : niveaux gardés, Raichu sans Tonnerre (la CT24 reste
	# la récompense).
	assert_eq([bob.team[0].level, bob.team[1].level, bob.team[2].level], [21, 18, 24])
	assert_eq(bob.team[2].moves, [&"thunder_shock", &"thunder_wave", &"quick_attack"]
		as Array[StringName])
	for slot: TrainerSlot in bob.team:
		assert_false(slot.moves.has(&"thunderbolt"), "aucun Tonnerre dans l'équipe")


func test_rival_by_starter() -> void:
	var rival := _trainers.get_trainer(&"rival_ss_anne")
	assert_true(rival.moment_on_win, "Grand moment à la victoire seulement")
	assert_false(rival.can_lose)
	assert_true(rival.can_switch, "comme le rival n° 3 (Kevin, 2026-10-15)")
	var last := {&"bulbasaur": &"charmeleon", &"charmander": &"wartortle",
		&"squirtle": &"ivysaur"}
	for starter: StringName in last:
		var team := rival.team_for(starter)
		assert_eq(team.size(), 4, String(starter))
		assert_eq([team[0].species, team[1].species, team[2].species, team[3].species],
			[&"pidgeotto", &"raticate", &"kadabra", last[starter]], "G-7")
		# Recalage à ~40 % au premier essai en ligne droite (décision de Kevin du 2026-10-16,
		# « 95 % c'est trop » ; jalon-16-equilibrage.md §10).
		var levels: Array = {&"bulbasaur": [13, 12, 13, 15], &"charmander": [19, 16, 19, 20],
			&"squirtle": [20, 17, 19, 24]}[starter]
		assert_eq([team[0].level, team[1].level, team[2].level, team[3].level], levels,
			String(starter))
		# Le starter évolué reste le plus fort (Kevin, 2026-10-16 : Carapuce 20 / 17 / 19 / 24).
		for i in 3:
			assert_lt(team[i].level, team[3].level, "%s : starter le plus haut" % starter)
		assert_eq(team[2].moves, [&"confusion", &"psybeam"] as Array[StringName], "R-12")
