extends GutTest
## Les 14 Dresseurs du jalon 18 (T16 ; docs/tech/jalon-18.md §4.7) : Route 9 (7), Route 10 (2),
## Grotte Sombre (5). Équipes, récompenses et répliques recopiées du dossier 21 (§3.3, §4.3, §5.5,
## textes T-42 à T-55 validés par Kevin le 2026-10-14), identifiants des grilles (§0.2 n° 16),
## placement aux cases réservées des grilles (`tools/plans/`). Fichier séparé des tests partagés.

const DOSSIER := "res://docs/design/dossier-21-grotte-sombre-lavanville.md"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

## Identifiant → [texte du lot, nom affiché, équipe [espèce, niveau]…, récompense, base de la
## classe, fichier de données, carte, identifiant de PNJ = case de la grille, apparence].
## Substitutions du dossier (*) : Férosinge, Rondoudou, Smogo, Nidorino (pas d'Osselait).
const TRAINERS := {
	&"route_9_lass_lou": ["T-42", "Jeune Dresseuse Lou", [[&"oddish", 18], [&"bellsprout", 18],
		[&"oddish", 18], [&"bellsprout", 18]], 360, 20, "route_9", &"lou", &"lass"],
	&"route_9_camper_adam": ["T-43", "Campeur Adam", [[&"mankey", 20], [&"charmander", 21]],
		420, 20, "route_9", &"adam", &"camper"],
	&"route_9_camper_jules": ["T-44", "Campeur Jules", [[&"rattata", 19], [&"ekans", 19],
		[&"sandshrew", 19]], 380, 20, "route_9", &"jules", &"camper"],
	&"route_9_lass_zoe": ["T-45", "Jeune Dresseuse Zoé", [[&"meowth", 23]], 460, 20, "route_9",
		&"zoe", &"lass"],
	&"route_9_hiker_benoit": ["T-46", "Montagnard Benoît", [[&"machop", 20], [&"onix", 20]],
		700, 35, "route_9", &"benoit", &"hiker"],
	&"route_9_hiker_gilles": ["T-47", "Montagnard Gilles", [[&"geodude", 20], [&"machop", 20],
		[&"geodude", 20]], 700, 35, "route_9", &"gilles", &"hiker"],
	&"route_9_scout_noa": ["T-48", "Scout Noa", [[&"beedrill", 19], [&"beedrill", 19]], 228, 12,
		"route_9", &"noa", &"scout"],
	&"route_10_maniac_hector": ["T-49", "Pokémaniac Hector", [[&"nidorino", 20],
		[&"jigglypuff", 20]], 1000, 50, "route_10", &"hector", &"pokemaniac"],
	&"route_10_hiker_paul": ["T-50", "Montagnard Paul", [[&"geodude", 21], [&"onix", 21]], 735,
		35, "route_10", &"paul", &"hiker"],
	&"dark_cave_roger": ["T-51", "Montagnard Roger", [[&"geodude", 19], [&"machop", 19],
		[&"geodude", 19], [&"geodude", 19]], 665, 35, "dark_cave_1f", &"g1_roger", &"hiker"],
	&"dark_cave_simon": ["T-52", "Pokémaniac Simon", [[&"jigglypuff", 23], [&"koffing", 23]],
		1150, 50, "dark_cave_1f", &"g2_simon", &"pokemaniac"],
	&"dark_cave_elsa": ["T-53", "Jeune Dresseuse Elsa", [[&"pidgey", 19], [&"rattata", 19],
		[&"rattata", 19], [&"bellsprout", 19]], 380, 20, "dark_cave_b1f", &"g3_elsa", &"lass"],
	&"dark_cave_marcel": ["T-54", "Montagnard Marcel", [[&"onix", 20], [&"onix", 20],
		[&"geodude", 20]], 700, 35, "dark_cave_b1f", &"g4_marcel", &"hiker"],
	&"dark_cave_yanis": ["T-55", "Pokémaniac Yanis", [[&"charmander", 21], [&"nidorino", 21]],
		1050, 50, "dark_cave_1f", &"g5_yanis", &"pokemaniac"],
}
## Effets en attente sans conséquence contre un Dresseur : Cyclone (Roucool d'Elsa, Nv. 19)
## échoue face à un Dresseur dans Rouge/Bleu, comme dans le moteur (« Sans effet »).
const TOLERATED_PENDING: Array[String] = ["force_switch"]
## Carte → grille validée (§13.1).
const PLANS := {
	"route_9": "res://tools/plans/route_9.txt",
	"route_10": "res://tools/plans/route_10.txt",
	"dark_cave_1f": "res://tools/plans/grotte_sombre_1f.txt",
	"dark_cave_b1f": "res://tools/plans/grotte_sombre_b1f.txt",
}
const DATA_FILES := {
	"route_9": "res://data/trainers/route_9.json",
	"route_10": "res://data/trainers/route_10.json",
	"dark_cave_1f": "res://data/trainers/dark_cave.json",
	"dark_cave_b1f": "res://data/trainers/dark_cave.json",
}
const DIALOGUE_FILES := {
	"route_9": "res://data/dialogues/route_9.json",
	"route_10": "res://data/dialogues/route_10.json",
	"dark_cave_1f": "res://data/dialogues/dark_cave.json",
	"dark_cave_b1f": "res://data/dialogues/dark_cave.json",
}

var _data: PokemonData
var _trainers: TrainerLibrary
var _dossier: String


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_dossier = FileAccess.get_file_as_string(DOSSIER)


func test_fourteen_trainers_with_the_dossier_teams_and_prizes() -> void:
	assert_eq(_trainers.get_errors().size(), 0, "\n".join(_trainers.get_errors()))
	assert_eq(TRAINERS.size(), 14, "Route 9 : 7, Route 10 : 2, grotte : 5 (I-14)")
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.source, DATA_FILES[row[5]], String(id))
		assert_eq([trainer.name, trainer.ai, trainer.can_lose, trainer.heal_after,
			trainer.gives_exp], [row[1], &"random", false, false, true], String(id))
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
			assert_eq(slot.moves.size(), 0, "%s : capacités apprises au niveau" % id)
		assert_eq(team, row[2], String(id))
		assert_eq(trainer.prize_for(0), row[3], String(id))
		var last_level: int = (row[2] as Array).back()[1]
		assert_eq(row[3], int(row[4]) * last_level, "%s : base × dernier niveau" % id)


func test_no_cubone_and_no_pending_move() -> void:
	# Osselait réservé au J19 (I-14) ; aucune capacité sans effet moteur au niveau donné (garde
	# « Frénésie », dossier §3.3).
	for id: StringName in TRAINERS:
		var team := _trainers.build_team(id, &"bulbasaur", GameRng.new(18))
		assert_not_null(team, String(id))
		if team == null:
			continue
		for i: int in team.size():
			var mon := team.get_at(i)
			assert_ne(mon.species_id, &"cubone", String(id))
			for slot: MoveSlot in mon.moves:
				var move := _data.get_move(slot.move_id)
				assert_not_null(move, "%s : %s" % [id, slot.move_id])
				if move != null:
					var pending := Array(move.pending_effects).filter(
						func(tag: String) -> bool: return not TOLERATED_PENDING.has(tag))
					assert_eq(pending, [], "%s : %s sans effet en attente" % [id, slot.move_id])
				assert_ne(slot.move_id, &"rage", "%s : pas de Frénésie" % id)


func test_trainer_lines_are_the_validated_lot() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var quotes := _validated(row[0])
		assert_eq(quotes.size(), 3, "%s : avant, défaite, après" % row[0])
		var moments := ["before", "defeated", "after"]
		for i: int in moments.size():
			var dialogue_id := StringName("%s_%s" % [id, moments[i]])
			var dialogue := dialogues.get_dialogue(dialogue_id)
			assert_not_null(dialogue, String(dialogue_id))
			if dialogue == null or quotes.size() != 3:
				continue
			assert_eq(dialogue.source, DIALOGUE_FILES[row[5]], String(dialogue_id))
			assert_eq(dialogue.speaker, row[1], String(dialogue_id))
			assert_false(dialogue.draft, String(dialogue_id))
			assert_eq(dialogue.variants.size(), 1, String(dialogue_id))
			var texts: Array[String] = []
			for page: DialoguePage in dialogue.variants[0].pages:
				assert_lte(page.text.split("\n").size(), 2, "bulle de deux lignes au plus")
				texts.append(page.text.replace("\n", " "))
			var expected: String = quotes[i]
			if id == &"dark_cave_marcel" and moments[i] == "defeated":
				# [D] Marcel s'efface après sa défaite : il y dit aussi sa réplique « après ».
				expected += " " + quotes[2]
			assert_eq(" ".join(texts), expected, String(dialogue_id))


func test_trainers_stand_on_their_reserved_cells() -> void:
	# Case, orientation et vue de la grille (« dresseur … facing= sight= trainer= ») ; répliques
	# « avant / défaite / après » du bloc trainer ; apparence de la classe.
	var placed := 0
	for map_id: String in PLANS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(PLANS[map_id]), map_id)
		var roster := NpcRoster.load_for_map(StringName(map_id))
		assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
		for id: StringName in TRAINERS:
			var row: Array = TRAINERS[id]
			if row[5] != map_id:
				continue
			var spec := roster.get_spec(row[6])
			assert_not_null(spec, "%s : PNJ %s" % [map_id, row[6]])
			if spec == null:
				continue
			placed += 1
			var grid_id := String(row[6])
			assert_true(plan.positions.has(grid_id), "%s : %s dans la grille" % [map_id, grid_id])
			assert_eq(plan.positions.get(grid_id, {}).get("kind", ""), "dresseur", grid_id)
			assert_eq(spec.cell, plan.cell_of(grid_id), String(id))
			assert_eq(spec.facing, Grid.direction_from_name(plan.attr(grid_id, "facing")),
				String(id))
			assert_eq(spec.trainer_id, id)
			assert_eq(plan.attr(grid_id, "trainer"), String(id))
			assert_eq(spec.sight, int(plan.attr(grid_id, "sight")), String(id))
			assert_eq([spec.dialogue, spec.before_dialogue, spec.defeated_dialogue],
				[StringName("%s_after" % id), StringName("%s_before" % id),
				StringName("%s_defeated" % id)], String(id))
			assert_eq(spec.sprite, row[7], String(id))
	assert_eq(placed, 14)


func test_simulation_scenario_uses_the_same_trainers() -> void:
	# tools/sim/j18_scenario.json (T10) porte les mêmes valeurs : les données n'ont pas dérivé.
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tools/sim/j18_scenario.json"))
	var trainers: Dictionary = scenario["trainers"]
	assert_eq(trainers.size(), 14)
	for key: String in trainers:
		var row: Array = TRAINERS[StringName(key)]
		var team: Array = []
		for member: Dictionary in trainers[key]["team"]:
			team.append([StringName(member["species"]), int(member["level"])])
		assert_eq(team, row[2], key)
		assert_eq(int(trainers[key]["prize_money"]), row[3], key)


## Textes « … » de la ligne [param tag] (« T-42 »…) du lot validé (dossier §15).
func _validated(tag: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.create_from_string("« (.+?) »")
	for line: String in _dossier.split("\n"):
		if line.begins_with("| %s |" % tag):
			for m: RegExMatch in regex.search_all(line):
				found.append(m.get_string(1))
	return found
