extends GutTest
## Données du jalon 26 (T3, docs/tech/jalon-26.md §2.3, §2.4) : Dresseurs de la Sylphe SARL
## (`data/trainers/silph_co.json`), leurs répliques (`data/dialogues/silph_co.json`), Giovanni du
## 11F, rival n° 6 (`rival_silph`, `data/trainers/rival.json`), espèces Lokhlass et Alakazam.
##
## Textes : **[D] textes proposés, validés par Kevin le 2026-10-21, validation d'avance
## (proposition du plan)**. Les données n'ont pas de clé « draft » (les tests partagés n'en
## admettent aucune) : ce commentaire est la marque. Identifiants imposés :
## `silph_co_<étage>f_<rang>`, rang = ordre des `object_event` à `OPP_…` de
## `data/maps/objects/SilphCo<n>F.asm` de pokered, sans le rival ni Giovanni.
##
## Équipes = celles de `parties.asm` (niveau, ordre) ; les espèces absentes de cette branche
## sont remplacées [D] (table SUBSTITUTES) ; à restaurer quand le J22 est fusionné
## (Grotesque, Grotadmorv, Électrode, Machopeur existent sur `jalon-22`) ; M. Mime n'existe
## sur aucune branche.

## Rouge/Bleu : id → [niveau, espèces de parties.asm] (avant remplacement).
const RB_TEAMS := {
	&"silph_co_2f_1": [26, ["grimer", "weezing", "koffing", "weezing"]],
	&"silph_co_2f_2": [28, ["magnemite", "voltorb", "magneton"]],
	&"silph_co_2f_3": [29, ["cubone", "zubat"]],
	&"silph_co_2f_4": [25, ["golbat", "zubat", "zubat", "raticate", "zubat"]],
	&"silph_co_3f_1": [28, ["raticate", "hypno", "raticate"]],
	&"silph_co_3f_2": [29, ["electrode", "weezing"]],
	&"silph_co_4f_1": [29, ["machop", "drowzee"]],
	&"silph_co_4f_2": [33, ["electrode"]],
	&"silph_co_4f_3": [28, ["ekans", "zubat", "cubone"]],
	&"silph_co_5f_1": [33, ["arbok"]],
	&"silph_co_5f_2": [26, ["magneton", "koffing", "weezing", "magnemite"]],
	&"silph_co_5f_3": [29, ["kadabra", "mr_mime"]],
	&"silph_co_5f_4": [33, ["hypno"]],
	&"silph_co_6f_1": [29, ["machop", "machoke"]],
	&"silph_co_6f_2": [25, ["voltorb", "koffing", "magneton", "magnemite", "koffing"]],
	&"silph_co_6f_3": [28, ["zubat", "zubat", "golbat"]],
	&"silph_co_7f_1": [26, ["raticate", "arbok", "koffing", "golbat"]],
	&"silph_co_7f_2": [29, ["electrode", "muk"]],
	&"silph_co_7f_3": [29, ["cubone", "cubone"]],
	&"silph_co_7f_4": [29, ["sandshrew", "sandslash"]],
	&"silph_co_8f_1": [26, ["raticate", "zubat", "golbat", "rattata"]],
	&"silph_co_8f_2": [29, ["grimer", "electrode"]],
	&"silph_co_8f_3": [28, ["weezing", "golbat", "koffing"]],
	&"silph_co_9f_1": [28, ["drowzee", "grimer", "machop"]],
	&"silph_co_9f_2": [28, ["voltorb", "koffing", "magneton"]],
	&"silph_co_9f_3": [28, ["golbat", "drowzee", "hypno"]],
	&"silph_co_10f_1": [33, ["machoke"]],
	&"silph_co_10f_2": [29, ["magnemite", "koffing"]],
	&"silph_co_11f_1": [32, ["cubone", "drowzee", "marowak"]],
	&"silph_co_11f_2": [25, ["rattata", "rattata", "zubat", "rattata", "ekans"]],
}
## Remplacements [D] : espèce RB absente de cette branche → la plus proche présente.
const SUBSTITUTES := {
	"grimer": "koffing", "weezing": "koffing", "muk": "arbok", "electrode": "magneton",
	"machoke": "machop", "mr_mime": "hypno",
}
## Étage → nombre de Dresseurs (hors rival et Giovanni).
const PER_FLOOR := {2: 4, 3: 2, 4: 3, 5: 4, 6: 3, 7: 4, 8: 3, 9: 3, 10: 2, 11: 2}
## Argent RB : base × niveau du dernier Pokémon.
const BASE_MONEY := {"Sbire Rocket": 30, "Scientifique": 50, "Jongleur": 35}

var _data: PokemonData
var _trainers: TrainerLibrary
var _dialogues: DialogueLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()


func _silph_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _trainers.get_ids():
		if String(id).begins_with("silph_co_"):
			ids.append(id)
	return ids


func test_libraries_load_without_error() -> void:
	assert_eq(_trainers.get_errors().size(), 0, str(_trainers.get_errors()))
	assert_eq(_dialogues.get_errors().size(), 0, str(_dialogues.get_errors()))


func test_the_ids_are_the_imposed_ones() -> void:
	var expected: Array[StringName] = [&"silph_co_giovanni"]
	for floor_number: int in PER_FLOOR:
		for rank: int in range(1, int(PER_FLOOR[floor_number]) + 1):
			expected.append(StringName("silph_co_%df_%d" % [floor_number, rank]))
	expected.sort()
	var found := _silph_ids()
	found.sort()
	assert_eq(found, expected)
	assert_eq(found.size(), 31, "30 Dresseurs et Giovanni")
	assert_eq(RB_TEAMS.size(), 30)


func test_each_silph_trainer_has_its_three_lines_and_known_species() -> void:
	for id: StringName in _silph_ids():
		var trainer := _trainers.get_trainer(id)
		assert_true(trainer.team.size() >= 1 and trainer.team.size() <= 6, String(id))
		for slot: TrainerSlot in trainer.team:
			assert_true(_data.has_species(slot.species), "%s : %s" % [id, slot.species])
		if id == &"silph_co_giovanni":
			continue
		for suffix: String in ["before", "defeated", "after"]:
			var key := StringName("%s_%s" % [id, suffix])
			assert_true(_dialogues.has_dialogue(key), String(key))
			var dialogue := _dialogues.get_dialogue(key)
			assert_eq(dialogue.speaker, trainer.name, String(key))
			assert_false(dialogue.draft, String(key))
			var pages := dialogue.variants[0].pages
			assert_true(pages.size() >= 1 and pages.size() <= 3, String(key))
			for page: DialoguePage in pages:
				assert_false(page.text.strip_edges().is_empty(), String(key))
	var silph_dialogues := 0
	for id: StringName in _dialogues.get_ids():
		if String(id).begins_with("silph_co_"):
			silph_dialogues += 1
	assert_eq(silph_dialogues, 90, "3 répliques × 30 Dresseurs, aucune autre")


func test_teams_are_the_red_blue_ones_with_the_documented_substitutes() -> void:
	for id: StringName in RB_TEAMS:
		var trainer := _trainers.get_trainer(id)
		var level: int = RB_TEAMS[id][0]
		var species: Array = RB_TEAMS[id][1]
		assert_eq(trainer.team.size(), species.size(), String(id))
		for i: int in species.size():
			var rb: String = species[i]
			assert_eq(trainer.team[i].species, StringName(SUBSTITUTES.get(rb, rb)),
				"%s #%d (RB : %s)" % [id, i, rb])
			assert_eq(trainer.team[i].level, level, "%s #%d" % [id, i])
		assert_eq(trainer.prize_money, BASE_MONEY[trainer.name.get_slice(" ", 0) if
			not trainer.name.begins_with("Sbire") else "Sbire Rocket"] * level, String(id))
		assert_eq(trainer.ai, &"random")
		assert_false(trainer.can_lose, String(id))
		assert_false(trainer.heal_after, String(id))
		assert_true(trainer.gives_exp, String(id))


func test_names_follow_the_class_and_first_names_are_unique() -> void:
	var seen: Dictionary[String, StringName] = {}
	for id: StringName in RB_TEAMS:
		var name := _trainers.get_trainer(id).name
		var parts := name.split(" ")
		if name == "Sbire Rocket":
			continue
		assert_true(parts[0] in ["Scientifique", "Jongleur"], name)
		assert_eq(parts.size(), 2, name)
		assert_false(seen.has(name), "%s en double (%s)" % [name, id])
		seen[name] = id
	assert_eq(seen.size(), 11, "10 Scientifiques et 1 Jongleur")
	# Aucun prénom déjà pris par un autre Dresseur de la branche (autres jalons : vérifiés à
	# la main sur origin/jalon-21 à jalon-25 et j2*, voir le commit).
	var first_names: Dictionary[String, StringName] = {}
	for id: StringName in _trainers.get_ids():
		if String(id).begins_with("silph_co_") or id == &"rival_silph":
			continue
		var parts := _trainers.get_trainer(id).name.split(" ")
		if parts.size() > 1:
			first_names[parts[parts.size() - 1]] = id
	for name: String in seen:
		var first := name.split(" ")[1]
		assert_false(first_names.has(first), "%s déjà pris (%s)" % [first, first_names.get(first)])


func test_giovanni_of_the_11th_floor() -> void:
	var giovanni := _trainers.get_trainer(&"silph_co_giovanni")
	assert_eq(giovanni.name, "Giovanni")
	assert_eq(giovanni.ai, &"smart")
	assert_true(giovanni.can_switch)
	assert_true(giovanni.allow_bag)
	assert_false(giovanni.can_lose)
	assert_false(giovanni.start_message, "comme giovanni_hideout (scène)")
	assert_true(giovanni.end_message)
	assert_eq(giovanni.prize_money, 99 * 41, "RB : 99 × niveau du dernier")
	assert_eq([giovanni.card_name, giovanni.card_title], ["GIOVANNI", "Chef de la Team Rocket"])
	var expected := [
		[&"nidorino", 37, [&"horn_attack", &"poison_sting", &"focus_energy", &"fury_attack"]],
		[&"kangaskhan", 35, [&"comet_punch", &"rage", &"bite", &"tail_whip"]],
		[&"rhyhorn", 37, [&"horn_attack", &"stomp", &"tail_whip"]],
		[&"nidoqueen", 41, [&"scratch", &"tail_whip", &"body_slam", &"poison_sting"]],
	]
	assert_eq(giovanni.team.size(), 4)
	for i: int in expected.size():
		assert_eq(giovanni.team[i].species, expected[i][0])
		assert_eq(giovanni.team[i].level, expected[i][1])
		assert_eq(giovanni.team[i].moves, expected[i][2] as Array[StringName], str(i))
		# Les capacités RB sont celles que le niveau donne : la liste explicite les fige.
		var known := _data.get_species(giovanni.team[i].species).moves_at(giovanni.team[i].level)
		known.sort()
		var listed := giovanni.team[i].moves.duplicate()
		listed.sort()
		assert_eq(listed, known, "capacités RB au niveau, espèce %d" % i)


func test_rival_silph_has_the_three_starter_variants() -> void:
	var rival := _trainers.get_trainer(&"rival_silph")
	var tower := _trainers.get_trainer(&"rival_tower")
	assert_eq(rival.name, "{rival}")
	assert_eq(rival.ai, &"smart")
	assert_true(rival.moment_on_win)
	assert_true(rival.can_switch)
	assert_true(rival.allow_bag)
	assert_true(rival.start_message)
	assert_false(rival.end_message)
	assert_false(rival.can_lose)
	assert_eq(rival.prize_money, 0)
	assert_eq(rival.prize_per_level, tower.prize_per_level, "même champs que rival_tower")
	assert_eq(rival.team_by_starter.keys().size(), 3)
	# Clé = starter du JOUEUR ; le rival a le starter qui l'avantage (comme rival_tower).
	var expected := {
		&"bulbasaur": [[&"pidgeot", 37], [&"exeggcute", 38], [&"sandslash", 35], [&"alakazam", 35],
			[&"charizard", 40]],
		&"charmander": [[&"pidgeot", 37], [&"growlithe", 38], [&"exeggcute", 35],
			[&"alakazam", 35], [&"blastoise", 40]],
		&"squirtle": [[&"pidgeot", 37], [&"gyarados", 38], [&"growlithe", 35], [&"alakazam", 35],
			[&"venusaur", 40]],
	}
	for starter: StringName in expected:
		var team := rival.team_for(starter)
		assert_eq(team.size(), 5, String(starter))
		for i: int in team.size():
			assert_eq([team[i].species, team[i].level], expected[starter][i], "%s #%d" % [starter, i])
			assert_true(team[i].moves.size() >= 3, "%s #%d : capacités listées" % [starter, i])
			var known := _data.get_species(team[i].species).moves_at(team[i].level)
			known.sort()
			var listed := team[i].moves.duplicate()
			listed.sort()
			assert_eq(listed, known, "%s #%d : capacités RB au niveau" % [starter, i])
	# Q26-4 [D] : la lignée du rival_tower (Sablaireau au lieu de Léviator, N35 = niveau RB).
	assert_eq(tower.team_for(&"bulbasaur")[2].species, &"sandshrew", "lignée du J19")
	assert_eq(rival.team_for(&"bulbasaur")[2].species, &"sandslash")


func test_lapras_and_alakazam_of_the_silph_file() -> void:
	var lapras := _data.get_species(&"lapras")
	assert_eq([lapras.dex, lapras.name, lapras.types], [131, "Lokhlass",
		[&"water", &"ice"] as Array[StringName]])
	assert_eq(lapras.catch_rate, 45)
	assert_eq(lapras.moves_at(15), [&"water_gun", &"growl"] as Array[StringName])
	assert_eq(lapras.moves_at(46), [&"body_slam", &"confuse_ray", &"ice_beam", &"hydro_pump"]
		as Array[StringName])
	var alakazam := _data.get_species(&"alakazam")
	assert_eq([alakazam.dex, alakazam.name, alakazam.types], [65, "Alakazam",
		[&"psychic"] as Array[StringName]])
	assert_eq(alakazam.catch_rate, 50)
	assert_eq(alakazam.moves_at(35), [&"confusion", &"disable", &"psybeam", &"recover"]
		as Array[StringName])
	var kadabra := _data.get_species(&"kadabra")
	assert_eq(kadabra.evolutions.size(), 1)
	assert_eq(kadabra.evolutions[0].into, &"alakazam")
	assert_eq(kadabra.evolutions[0].method, EvolutionRule.Method.TRADE)
	assert_eq(alakazam.evolutions.size(), 0)
	assert_eq(lapras.evolutions.size(), 0)
	assert_true(_data.can_learn_hm(&"lapras", 3), "Surf")
	assert_true(_data.can_learn_hm(&"lapras", 4), "Force")
	assert_true(_data.can_learn_hm(&"alakazam", 5), "Flash")
	assert_true(_data.can_learn_tm(&"alakazam", 29), "Psyko")
	assert_true(_data.can_learn_tm(&"lapras", 13), "Laser Glace")
	assert_false(_data.can_learn_tm(&"lapras", 26), "pas de Séisme")
