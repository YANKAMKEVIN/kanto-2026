extends GutTest
## Cohérence des scènes scriptées de data/cutscenes/ avec les vraies cartes, les vrais PNJ
## et les vrais dialogues (jalon 3B §3.6, T4) :
## - chargement sans erreur ; chaque déclencheur vise une scène existante, chaque scène est
##   visée ; chaque dialogue d'étape existe ; chaque change_map vise une carte et un point
##   d'apparition existants ;
## - simulation statique de chaque variante : départ sur la carte de son déclencheur, avec
##   les drapeaux qui la choisissent ; « set » et « spawn » au fil des étapes ; à chaque
##   change_map, PNJ **présents** de la carte cible pour les drapeaux du moment. Chaque
##   acteur (face, move, follower, near), chaque cible de face qui n'est pas une direction,
##   et chaque acteur ou cible de « turn » des dialogues joués existe à ce moment-là.
## Jalon 4 (T1) : la variante 1 de route1_grass finit par la proposition de Chen
## (wait 0,5 s, oak_starter_offer, set starter_offered).
## T3 (jalon-04.md §13.5, §13.6) : scène oak_lab_exit (déclencheur LabExit du labo, choix en
## cours seulement) ; scène starter_chosen **jouée par le code** (StarterChoice, pas de
## déclencheur), simulée sur le labo avec les 3 jeux d'alias de l'offre ; elle lève
## starter_chosen une seule fois, juste après « On dirait que le choix est réciproque. ».
## Jalon 7 (T25) : scène du rival n° 2 (déclencheur de la Route 22), simulée pour les trois
## paires `taken_*` (Pokémon du rival) et les deux issues du combat ; l'étape « wake_up » arrête
## la simulation (la scène s'arrête au réveil). Correctif : les scènes **déclenchées** n'étaient
## plus simulées (boucle indentée sous `if CODE_PLAYED.has(id)`), elles le sont de nouveau.
## Jalon 8 (T4) : objets de la Route 2 — deux visibles (scène lancée par le dialogue du PNJ
## « objet », qui le retire : `despawn` → `give found` → `set`), deux cachés (déclencheurs de la
## carte, comme la Potion de la Route 1), posés par `tools/build_route_2.gd` (T5).
## Jalon 10 (T8) : arrivée à Argenta et garde de la Route 3 (déclencheurs d'Argenta, en attente de
## la carte du T11 : simulés sur les PNJ de son fichier), Potion de la Route 2 nord et scène de
## Pierre (lancées par le dialogue de leur PNJ) ; étapes `champion_card` et `badge` au T9.

const MAPS: Array[StringName] = [
	&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab", &"pallet_town",
	&"route_1", &"viridian_city", &"route_22", &"viridian_mart", &"route_2",
	# Jalon 9 (T19) : déclencheurs des objets cachés de la forêt.
	&"viridian_forest",
]
## Jalon 7 (T18) : partie qui revient au labo avec le colis (rival parti après le combat).
const PARCEL_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel",
]
## Jalon 7 (T25) : partie qui arrive sur la Route 22 après l'activation du Pokédex.
const ROUTE22_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel", &"pokedex_activated",
]
## Jalon 10 (T8) : partie qui arrive à Argenta (fin du J9 : poison annoncé, Théo battu).
const PEWTER_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel", &"pokedex_activated", &"poison_unlocked", &"beaten_forest_scout_theo",
]
## Paires `taken_*` posées au labo (starter du joueur, puis celui du rival) → Pokémon du rival
## présent sur la Route 22 (data/npcs/route_22.json).
const RIVAL_PAIRS: Dictionary = {
	&"rival_charmander": [&"taken_bulbasaur", &"taken_charmander"],
	&"rival_squirtle": [&"taken_charmander", &"taken_squirtle"],
	&"rival_bulbasaur": [&"taken_squirtle", &"taken_bulbasaur"],
}
## Scène → drapeaux qui choisissent chaque variante, dans l'ordre (§3.6).
const VARIANT_FLAGS: Dictionary = {
	&"route1_grass": [[], [&"oak_met"]],
	&"route_1_potion": [[]],
	&"oak_lab_exit": [[&"oak_met", &"oak_lab_reunion", &"starter_offered"]],
	&"starter_chosen": [[&"oak_met", &"oak_lab_reunion", &"starter_offered"]],
	&"viridian_arrival": [[&"rival_battle_done"]],
	&"mart_parcel": [[&"rival_battle_done", &"viridian_arrived"]],
	&"oak_parcel": [PARCEL_FLAGS],
	&"rival_route22": [ROUTE22_FLAGS],
	&"route_2_item_1": [ROUTE22_FLAGS],
	&"route_2_item_2": [ROUTE22_FLAGS],
	&"route_2_item_3": [ROUTE22_FLAGS],
	&"route_2_item_4": [ROUTE22_FLAGS],
	# Jalon 9 (T18) : les 6 objets de la Forêt de Jade.
	&"viridian_forest_item_1": [ROUTE22_FLAGS],
	&"viridian_forest_item_2": [ROUTE22_FLAGS],
	&"viridian_forest_item_3": [ROUTE22_FLAGS],
	&"viridian_forest_item_4": [ROUTE22_FLAGS],
	&"viridian_forest_item_5": [ROUTE22_FLAGS],
	&"viridian_forest_item_6": [ROUTE22_FLAGS],
	# Jalon 10 (T8) : Route 2 nord et Argenta.
	&"route_2_north_item_1": [PEWTER_FLAGS],
	&"pewter_arrival": [PEWTER_FLAGS],
	&"route_3_guard": [PEWTER_FLAGS + [&"pewter_arrived"],
		PEWTER_FLAGS + [&"pewter_arrived", &"brock_met", &"badge_boulder"]],
	&"pewter_gym_brock": [PEWTER_FLAGS + [&"pewter_arrived"]],
}
## Scènes jouées par le code (pas de déclencheur) → carte où elles sont jouées.
## Jalon 7 (T18) : la scène du colis est lancée par la variante « cutscene » du dialogue de Chen.
## Jalon 8 : les objets visibles de la Route 2, par le dialogue de leur PNJ « objet ».
const CODE_PLAYED: Dictionary[StringName, StringName] = {
	&"starter_chosen": &"oak_lab", &"oak_parcel": &"oak_lab",
	&"route_2_item_1": &"route_2", &"route_2_item_2": &"route_2",
	# Jalon 9 (T18) : objets visibles de la Forêt de Jade (PNJ « objet » de son fichier).
	&"viridian_forest_item_1": &"viridian_forest", &"viridian_forest_item_2": &"viridian_forest",
	&"viridian_forest_item_5": &"viridian_forest",
	# Jalon 10 (T8) : Potion de la Route 2 nord (PNJ « objet »), Pierre (son dialogue).
	&"route_2_north_item_1": &"route_2_north", &"pewter_gym_brock": &"pewter_gym",
}
## Scènes à déclencheur dont la carte n'est pas encore construite → leur carte (simulées sur les
## PNJ de son fichier). Vidée au T19 du jalon 9 (la forêt existe). Jalon 10 (T8) : les deux
## scènes d'Argenta, jusqu'à la carte du T11.
const AWAITING_MAP: Dictionary[StringName, StringName] = {
	&"pewter_arrival": &"pewter_city", &"route_3_guard": &"pewter_city",
}

var _cutscenes: CutsceneLibrary
var _dialogues: DialogueLibrary
var _offer: StarterOffer
var _pokemon: PokemonData
var _trainers: TrainerLibrary
var _items: ItemLibrary
## Scène → cartes de ses déclencheurs.
var _triggered_on: Dictionary[StringName, Array] = {}


func before_all() -> void:
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_offer = StarterOffer.new()
	_offer.load_file()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	for map_id: StringName in MAPS:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Triggers").get_children():
			var id := (point as EventTriggerPoint).cutscene_id
			if not _triggered_on.has(id):
				_triggered_on[id] = []
			(_triggered_on[id] as Array).append(map_id)
		map.free()


func _all_steps() -> Array[CutsceneStep]:
	var steps: Array[CutsceneStep] = []
	for id: StringName in _cutscenes.get_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			steps.append_array(variant.steps)
	return steps


func test_library_loads_without_error() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), "data/cutscenes/ se charge")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_eq(library.get_ids(), [&"mart_parcel", &"oak_lab_exit", &"oak_parcel",
		&"pewter_arrival", &"pewter_gym_brock",
		&"rival_route22", &"route1_grass", &"route_1_potion", &"route_2_item_1",
		&"route_2_item_2", &"route_2_item_3", &"route_2_item_4", &"route_2_north_item_1",
		&"route_3_guard", &"starter_chosen",
		&"viridian_arrival", &"viridian_forest_item_1", &"viridian_forest_item_2",
		&"viridian_forest_item_3", &"viridian_forest_item_4", &"viridian_forest_item_5",
		&"viridian_forest_item_6"] as Array[StringName])


func test_route1_grass_ends_with_the_starter_offer() -> void:
	var steps := _cutscenes.get_cutscene(&"route1_grass").variants[0].steps
	assert_gt(steps.size(), 4)
	var tail := steps.slice(steps.size() - 4)
	assert_eq(tail[0].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(tail[0].flags, [&"oak_lab_reunion"] as Array[StringName], "après la réunion")
	assert_eq(tail[1].kind, CutsceneStep.Kind.WAIT)
	assert_eq(tail[1].seconds, 0.5)
	assert_eq(tail[2].kind, CutsceneStep.Kind.DIALOGUE)
	assert_eq(tail[2].dialogue_id, &"oak_starter_offer")
	assert_eq(tail[3].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(tail[3].flags, [&"starter_offered"] as Array[StringName], "dernière étape")


func test_every_trigger_targets_a_scene_and_every_scene_is_triggered() -> void:
	assert_false(_triggered_on.is_empty())
	for id: StringName in _triggered_on:
		assert_true(_cutscenes.has_cutscene(id), "scène « %s » définie" % id)
	for id: StringName in _cutscenes.get_ids():
		if CODE_PLAYED.has(id):
			assert_false(_triggered_on.has(id), "« %s » jouée par le code seulement" % id)
			continue
		if AWAITING_MAP.has(id) and not MapCatalog.has_map(AWAITING_MAP[id]):
			continue
		assert_true(_triggered_on.has(id), "scène « %s » visée par un déclencheur" % id)
	assert_eq(_triggered_on.get(&"route1_grass"), [&"pallet_town"])
	assert_eq(_triggered_on.get(&"route_1_potion"), [&"route_1"])
	assert_eq(_triggered_on.get(&"oak_lab_exit"), [&"oak_lab"])
	assert_eq(_triggered_on.get(&"viridian_arrival"), [&"viridian_city"])
	assert_eq(_triggered_on.get(&"rival_route22"), [&"route_22"])
	assert_eq(_triggered_on.get(&"mart_parcel"), [&"viridian_mart"])
	assert_eq(_triggered_on.get(&"route_2_item_3"), [&"route_2"])
	assert_eq(_triggered_on.get(&"route_2_item_4"), [&"route_2"])
	assert_eq(_offer.chosen_scene, &"starter_chosen", "scène du choix = CODE_PLAYED")
	assert_eq(CODE_PLAYED[_offer.chosen_scene], _offer.map_id)


func test_every_dialogue_step_exists() -> void:
	for id: StringName in _cutscenes.get_dialogue_ids():
		assert_true(_dialogues.has_dialogue(id), "dialogue « %s » défini" % id)


## Jalon 4B : chaque étape « battle » vise un dresseur chargé, chaque étape « give » un objet
## chargé.
func test_every_trainer_and_item_step_exists() -> void:
	var trainer_ids := _cutscenes.get_trainer_ids()
	assert_false(trainer_ids.is_empty(), "au moins le combat du rival")
	for id: StringName in trainer_ids:
		assert_true(_trainers.has_trainer(id), "dresseur « %s » chargé" % id)
	var item_ids := _cutscenes.get_item_ids()
	assert_false(item_ids.is_empty(), "au moins les Poké Balls")
	for id: StringName in item_ids:
		assert_true(_items.has_item(id), "objet « %s » chargé" % id)


## Jalon 5C.5 (décision de Kevin) : la Potion de la Route 1 est un objet **trouvé** dans le
## monde ; les 5 Poké Balls de Chen sont **reçues** (pas au journal des objets trouvés).
## Jalon 8 : les quatre objets de la Route 2 (dossier 11 §11) sont trouvés eux aussi.
func test_only_world_items_are_found_items() -> void:
	var found: Array[String] = []
	for id: StringName in _cutscenes.get_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.GIVE and step.found:
					found.append("%s:%s" % [id, step.item_id])
	assert_eq(found, ["route_1_potion:potion", "route_2_item_1:poke_ball",
		"route_2_item_2:potion", "route_2_item_3:poke_ball", "route_2_item_4:potion",
		"route_2_north_item_1:potion",
		"viridian_forest_item_1:antidote", "viridian_forest_item_2:poke_ball",
		"viridian_forest_item_3:potion", "viridian_forest_item_4:antidote",
		"viridian_forest_item_5:poke_ball", "viridian_forest_item_6:potion"]
		as Array[String])


## Jalon 8 (jalon-08.md §2.3, §2.4) : un objet visible disparaît d'abord (son PNJ, retiré au
## prochain chargement par son « unless »), puis entre au Sac, puis son drapeau ; un objet
## caché joue sa narration d'abord. Une seule fois chacun (variante unique sous « unless »).
func test_route_2_items() -> void:
	var roster := NpcRoster.load_for_map(&"route_2")
	var expected := {
		&"route_2_item_1": [&"despawn", &"route_2_ball_1", &"poke_ball", &"got_route_2_item_1"],
		&"route_2_item_2": [&"despawn", &"route_2_ball_2", &"potion", &"got_route_2_item_2"],
		&"route_2_item_3": [&"dialogue", &"route_2_item_3_found", &"poke_ball",
			&"got_route_2_item_3"],
		&"route_2_item_4": [&"dialogue", &"route_2_item_4_found", &"potion",
			&"got_route_2_item_4"],
	}
	for id: StringName in expected:
		var row: Array = expected[id]
		var cutscene := _cutscenes.get_cutscene(id)
		assert_eq(cutscene.variants.size(), 1, String(id))
		var variant := cutscene.variants[0]
		assert_eq(variant.unless_flags, [row[3]] as Array[StringName], "%s : une fois" % id)
		assert_eq(variant.steps.size(), 3, String(id))
		var first := variant.steps[0]
		assert_eq(CutsceneStep.kind_name(first.kind), row[0], String(id))
		assert_eq(first.actor if first.kind == CutsceneStep.Kind.DESPAWN
			else first.dialogue_id, row[1], String(id))
		var give := variant.steps[1]
		assert_eq(give.kind, CutsceneStep.Kind.GIVE)
		assert_eq([give.item_id, give.count, give.found], [row[2], 1, true], String(id))
		assert_eq(variant.steps[2].flags, [row[3]] as Array[StringName], String(id))
		assert_true(cutscene.pick(_flags([row[3]])) == null, "%s : rien ensuite" % id)
		if first.kind == CutsceneStep.Kind.DESPAWN:
			var spec := roster.get_spec(row[1])
			assert_not_null(spec, "%s : PNJ « objet » sur la Route 2" % row[1])
			if spec == null:
				continue
			assert_eq(spec.verb, Interaction.Kind.TAKE, "%s : PRENDRE" % row[1])
			assert_eq(spec.sprite, &"object/poke_ball_ground", "même aspect (Q-1)")
			assert_eq(spec.unless_flags, [row[3]] as Array[StringName], "retiré ensuite")
			var dialogue := _dialogues.get_dialogue(spec.dialogue)
			assert_eq(dialogue.variants.size(), 1)
			assert_eq(dialogue.variants[0].cutscene, id, "le dialogue lance la scène")
			assert_true(dialogue.variants[0].pages.is_empty(), "aucune bulle avant le toast")


func test_every_change_map_targets_an_existing_map_and_spawn() -> void:
	var count := 0
	for step: CutsceneStep in _all_steps():
		if step.kind != CutsceneStep.Kind.CHANGE_MAP:
			continue
		count += 1
		assert_true(MapCatalog.has_map(step.map_id), "carte « %s »" % step.map_id)
		if not MapCatalog.has_map(step.map_id):
			continue
		var map := (load(MapCatalog.scene_path(step.map_id)) as PackedScene).instantiate() \
				as GameMap
		assert_true(map.has_spawn(step.spawn), "%s : point « %s »" % [step.map_id, step.spawn])
		map.free()
	assert_eq(count, 1, "le retour au labo")


func test_every_variant_is_chosen_by_its_flags() -> void:
	for id: StringName in _cutscenes.get_ids():
		assert_true(VARIANT_FLAGS.has(id), "%s : drapeaux des variantes écrits" % id)
		var cutscene := _cutscenes.get_cutscene(id)
		var rows: Array = VARIANT_FLAGS.get(id, [])
		assert_eq(rows.size(), cutscene.variants.size())
		for i: int in mini(rows.size(), cutscene.variants.size()):
			assert_same(cutscene.pick(_flags(rows[i])), cutscene.variants[i],
				"%s : variante %d" % [id, i + 1])


func test_static_simulation_of_every_variant() -> void:
	var checked := 0
	for id: StringName in _cutscenes.get_ids():
		var cutscene := _cutscenes.get_cutscene(id)
		var rows: Array = VARIANT_FLAGS.get(id, [])
		var maps: Array = _triggered_on.get(id, [])
		if CODE_PLAYED.has(id):
			maps = [CODE_PLAYED[id]]
		elif maps.is_empty() and AWAITING_MAP.has(id):
			maps = [AWAITING_MAP[id]]
		# Une scène avec un combat est jouée « à blanc » pour les deux issues (jalon-04.md §14.11
		# T8 ; rival n° 2, T25).
		var outcomes: Array[int] = ([Battle.Outcome.WIN, Battle.Outcome.LOSS] as Array[int]) \
			if _has_battle(cutscene) else ([Battle.Outcome.WIN] as Array[int])
		for i: int in mini(rows.size(), cutscene.variants.size()):
			for map_id: StringName in maps:
				for aliases: Dictionary in _alias_sets(id):
					for extra: Array in _extra_flag_sets(id):
						for outcome: int in outcomes:
							checked += _simulate("%s/%d %s %s %d" % [id, i + 1, aliases, extra,
								outcome], cutscene.variants[i], map_id,
								_flags(rows[i] + extra), aliases, outcome)
	assert_gt(checked, 60, "acteurs vérifiés")


func _has_battle(cutscene: Cutscene) -> bool:
	for variant: CutsceneVariant in cutscene.variants:
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.BATTLE:
				return true
	return false


## Drapeaux ajoutés à chaque simulation d'une scène : les trois paires `taken_*` pour la scène
## du rival n° 2 (le Pokémon du rival présent en dépend), aucun sinon.
func _extra_flag_sets(cutscene_id: StringName) -> Array:
	if cutscene_id != &"rival_route22":
		return [[]]
	return RIVAL_PAIRS.values()


## Jalon 7 (T2) : la simulation connaît l'étape « scare » (acteur présent et « shy », retiré
## ensuite), sur les vrais Pokémon d'ambiance de la Route 1 et sur un PNJ créé par la scène.
func test_simulation_knows_the_scare_step() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"scare_test": {"steps": [
		{"scare": "route_pidgey"},
		{"spawn": "roof_bird", "sprite": "pidgey", "cell": [3, 3], "shy": {"action": "fly"}},
		{"scare": "$bird"},
		{"face": "traveler", "to": "player"},
	]}}, "test"), str(library.get_errors()))
	var variant := library.get_cutscene(&"scare_test").variants[0]
	var checked := _simulate("scare_test", variant, &"route_1", _flags([]),
		{&"bird": &"roof_bird"})
	assert_eq(checked, 4, "deux Pokémon effrayés, le voyageur et le joueur")


## Jeux d'alias d'une scène : ceux de l'offre pour la scène du choix (un par starter), un
## jeu vide sinon.
func _alias_sets(cutscene_id: StringName) -> Array[Dictionary]:
	if cutscene_id != _offer.chosen_scene:
		return [{}]
	var sets: Array[Dictionary] = []
	for option: StarterOption in _offer.get_choices():
		var rival := _offer.get_choice(_offer.rival_pick(option.species, _pokemon))
		sets.append({
			StarterChoice.PLAYER_ALIAS: option.npc, StarterChoice.RIVAL_ALIAS: rival.npc,
		})
	return sets


func test_alias_sets_of_the_choice_cover_the_three_starters() -> void:
	var sets := _alias_sets(&"starter_chosen")
	assert_eq(sets.size(), 3)
	assert_eq(_cutscenes.get_aliases(&"starter_chosen"),
		[StarterChoice.PLAYER_ALIAS, StarterChoice.RIVAL_ALIAS] as Array[StringName])
	assert_true(_cutscenes.get_aliases(&"oak_lab_exit").is_empty())


## Décision n° 1 (§13.3) : done_flag levé une seule fois, à l'étape qui suit le dialogue
## « oak_starter_reciprocal » ; la scène finit par rival_challenged ; ordre des dialogues
## (§13.5, décision n° 16 : « Ça devrait être intéressant. » après « Alors ce sera toi. »).
func test_starter_chosen_sets_done_flag_right_after_the_reciprocal_line() -> void:
	var cutscene := _cutscenes.get_cutscene(_offer.chosen_scene)
	assert_eq(cutscene.variants.size(), 1)
	var variant := cutscene.variants[0]
	assert_true(variant.if_flags.is_empty())
	assert_eq(variant.unless_flags, [&"rival_challenged"] as Array[StringName])
	var steps := variant.steps
	var set_at: Array[int] = []
	var dialogues: Array[StringName] = []
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.SET_FLAGS and steps[i].flags.has(_offer.done_flag):
			set_at.append(i)
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE:
			dialogues.append(steps[i].dialogue_id)
	assert_eq(set_at.size(), 1, "done_flag levé une seule fois")
	if set_at.size() == 1:
		var previous := steps[set_at[0] - 1]
		assert_eq(previous.kind, CutsceneStep.Kind.DIALOGUE)
		assert_eq(previous.dialogue_id, &"oak_starter_reciprocal")
		assert_eq(steps[set_at[0]].flags, [_offer.done_flag] as Array[StringName])
	assert_eq(dialogues, [&"oak_starter_reciprocal", &"rival_starter_pick",
		&"rival_starter_smile", &"rival_challenge_wait", &"rival_challenge", &"rival_lab_won",
		&"rival_lab_won_leaving", &"rival_lab_lost", &"oak_after_battle",
		&"oak_poke_balls_intro", &"oak_poke_balls"] as Array[StringName])
	assert_eq(steps.back().kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps.back().flags, [&"rival_challenged"] as Array[StringName], "dernière étape")
	# Le Pokémon descend (hop) et s'approche (lean) avant Chen.
	var kinds: Array[int] = []
	for step: CutsceneStep in steps.slice(0, set_at[0] if set_at.size() == 1 else 0):
		kinds.append(step.kind)
	assert_true(kinds.has(CutsceneStep.Kind.HOP), "le starter descend de la table")
	assert_true(kinds.has(CutsceneStep.Kind.LEAN), "il s'approche")
	# Décision n° 16 (Q-A) : après l'arrivée de son Pokémon, le rival regarde celui du joueur,
	# puis le joueur, temps mort (petit sourire), « Ça devrait être intéressant. ».
	var smile := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE \
				and steps[i].dialogue_id == &"rival_starter_smile":
			smile = i
	assert_gt(smile, 3)
	if smile > 3:
		assert_eq(steps[smile - 1].kind, CutsceneStep.Kind.WAIT, "temps mort")
		assert_eq([steps[smile - 2].actor, steps[smile - 2].target], [&"rival", &"player"])
		assert_eq(steps[smile - 3].kind, CutsceneStep.Kind.WAIT)
		assert_eq([steps[smile - 4].actor, steps[smile - 4].target],
			[&"rival", &"$player_starter"])


## Jalon 4B (§14.7) : le combat, puis rival_battle_done (quelle que soit l'issue), les
## répliques selon l'issue (conditions d'étape), le départ du rival, Chen, les 5 Poké Balls.
func test_starter_chosen_battle_and_aftermath() -> void:
	var steps := _cutscenes.get_cutscene(_offer.chosen_scene).variants[0].steps
	var battle := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.BATTLE:
			battle = i
	assert_gt(battle, 0, "une étape de combat")
	var step: CutsceneStep = steps[battle]
	assert_eq(step.trainer_id, &"rival_lab")
	assert_eq(CutsceneStep.alias_name(step.player_pokemon), StarterChoice.PLAYER_ALIAS)
	assert_eq(CutsceneStep.alias_name(step.foe_pokemon), StarterChoice.RIVAL_ALIAS)
	assert_eq(step.win_flags, [&"rival_lab_won"] as Array[StringName])
	assert_eq(step.lose_flags, [&"rival_lab_lost"] as Array[StringName])
	# Juste après le combat : rival_battle_done, sans condition (les deux issues).
	assert_eq(steps[battle + 1].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps[battle + 1].flags, [&"rival_battle_done"] as Array[StringName])
	assert_true(steps[battle + 1].if_flags.is_empty() and steps[battle + 1].unless_flags.is_empty(),
		"levé quelle que soit l'issue")
	# La remise des 5 Poké Balls et le départ du rival.
	var give := -1
	var left := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.GIVE:
			give = i
		if steps[i].kind == CutsceneStep.Kind.SET_FLAGS \
				and steps[i].flags == ([&"rival_left_lab"] as Array[StringName]):
			left = i
	assert_gt(give, battle, "give après le combat")
	assert_eq(steps[give].item_id, &"poke_ball")
	assert_eq(steps[give].count, 5)
	assert_gt(left, battle, "rival_left_lab après le combat")


## §13.6 : Chen se tourne vers le joueur, parle, le joueur recule d'un pas (vers le haut) ;
## seulement pendant le choix.
func test_oak_lab_exit_only_during_the_choice() -> void:
	var cutscene := _cutscenes.get_cutscene(&"oak_lab_exit")
	assert_eq(cutscene.variants.size(), 1)
	var steps := cutscene.variants[0].steps
	assert_eq(steps.size(), 3)
	assert_eq(steps[0].kind, CutsceneStep.Kind.FACE)
	assert_eq([steps[0].actor, steps[0].target], [&"oak", &"player"])
	assert_eq(steps[1].dialogue_id, &"oak_lab_exit_block")
	assert_eq(steps[2].kind, CutsceneStep.Kind.MOVE)
	assert_eq(steps[2].actor, &"player")
	assert_eq(steps[2].path, [Vector2i.UP] as Array[Vector2i])
	assert_null(cutscene.pick(_flags([&"oak_met", &"oak_lab_reunion"])), "avant l'offre")
	assert_not_null(cutscene.pick(_flags([&"oak_met", &"starter_offered"])), "pendant")
	assert_null(cutscene.pick(_flags([&"starter_offered", &"starter_chosen"])), "après")


## Jalon 7 (T18, dossier 09 §6 et §19) : scène du colis, lancée en parlant à Chen avec le colis
## (variante « cutscene » de son dialogue). Ordre : le colis quitte le Sac, Chen remarque les
## rencontres (réplique de l'espèce dans le même dialogue, omise sans rencontre), le Pokédex est
## activé **une seule fois**, juste avant la légende POKÉDEX ACTIVÉ, puis « Observe. Explore. » ;
## le rival entre ensuite, reçoit le sien, ses répliques, il repart.
func test_oak_parcel_scene_order() -> void:
	var cutscene := _cutscenes.get_cutscene(&"oak_parcel")
	assert_eq(cutscene.variants.size(), 1)
	var variant := cutscene.variants[0]
	assert_true(variant.if_flags.is_empty())
	assert_eq(variant.unless_flags, [StoryFlags.POKEDEX_ACTIVATED] as Array[StringName],
		"jamais rejouée après l'activation")
	var steps := variant.steps
	var take := _index_of(steps, CutsceneStep.Kind.TAKE)
	var activated := -1
	var caption := _index_of(steps, CutsceneStep.Kind.CAPTION)
	var spawn := _index_of(steps, CutsceneStep.Kind.SPAWN)
	var dialogues: Array[StringName] = []
	for i: int in steps.size():
		assert_true(steps[i].if_flags.is_empty() and steps[i].unless_flags.is_empty(),
			"étape %d sans condition" % i)
		if steps[i].kind == CutsceneStep.Kind.SET_FLAGS:
			assert_eq(steps[i].flags, [StoryFlags.POKEDEX_ACTIVATED] as Array[StringName])
			assert_eq(activated, -1, "un seul « set »")
			activated = i
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE:
			dialogues.append(steps[i].dialogue_id)
	assert_eq(steps[take].item_id, &"oak_parcel")
	assert_eq(steps[take].count, 1)
	assert_eq(steps[caption].text, "POKÉDEX ACTIVÉ")
	assert_lt(take, _index_of_dialogue(steps, &"oak_parcel_records"), "colis remis d'abord")
	assert_lt(_index_of_dialogue(steps, &"oak_parcel_records"), activated)
	assert_eq(caption, activated + 1, "la légende suit l'activation")
	assert_eq(_index_of_dialogue(steps, &"oak_pokedex_activated"), caption + 1)
	assert_gt(spawn, caption, "le rival arrive après l'activation")
	assert_eq(steps[spawn].spec.id, &"rival")
	assert_eq(steps[spawn].spec.sprite, &"rival")
	assert_eq(dialogues, [&"oak_parcel_records", &"oak_pokedex_activated",
		&"rival_parcel_return", &"rival_parcel_greet", &"oak_parcel_rival_dex",
		&"oak_parcel_rival", &"rival_parcel_leaving"] as Array[StringName])
	var despawn := _index_of(steps, CutsceneStep.Kind.DESPAWN)
	assert_eq(steps[despawn].actor, &"rival", "il repart")
	assert_gt(despawn, _index_of_dialogue(steps, &"rival_parcel_leaving"))
	assert_eq(_cutscenes.get_item_ids().count(&"oak_parcel"), 1)


## Une seule étape de toutes les données lève pokedex_activated (jamais un dialogue).
func test_pokedex_activated_is_raised_only_by_the_parcel_scene() -> void:
	var raised := 0
	for id: StringName in _cutscenes.get_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.flags.has(StoryFlags.POKEDEX_ACTIVATED) \
						or step.win_flags.has(StoryFlags.POKEDEX_ACTIVATED) \
						or step.lose_flags.has(StoryFlags.POKEDEX_ACTIVATED):
					raised += 1
					assert_eq(id, &"oak_parcel")
	assert_eq(raised, 1)
	assert_false(_dialogues.get_set_flags().has(StoryFlags.POKEDEX_ACTIVATED))


func _index_of(steps: Array[CutsceneStep], kind: CutsceneStep.Kind) -> int:
	for i: int in steps.size():
		if steps[i].kind == kind:
			return i
	return -1


func _index_of_dialogue(steps: Array[CutsceneStep], dialogue_id: StringName) -> int:
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE and steps[i].dialogue_id == dialogue_id:
			return i
	return -1


## Joue [param variant] « à blanc » : renvoie le nombre d'acteurs vérifiés. [param aliases] :
## « nom sans $ » → PNJ, remplacés comme le fait le directeur.
func _simulate(label: String, variant: CutsceneVariant, start_map: StringName,
		flags: StoryFlags, aliases: Dictionary = {}, outcome: int = Battle.Outcome.WIN) -> int:
	var map_id := start_map
	var actors := _present(map_id, flags)
	var checked := 0
	# PNJ créés par les étapes « spawn » de la carte courante.
	var spawned: Dictionary[StringName, NpcSpec] = {}
	for source: CutsceneStep in variant.steps:
		# Conditions d'étape (« if » / « unless ») évaluées au moment de la jouer : une étape
		# sautée ne vérifie aucun acteur (jalon-04.md §14.3).
		if not source.applies(flags):
			continue
		var step := _resolved(source, aliases)
		var where := "%s sur %s (%s)" % [label, map_id, CutsceneStep.kind_name(step.kind)]
		var needed: Array[StringName] = []
		if step.kind == CutsceneStep.Kind.WAKE_UP:
			# Réveil au point de repos (T25) : la scène s'arrête là.
			break
		match step.kind:
			CutsceneStep.Kind.SET_FLAGS:
				for flag: StringName in step.flags:
					flags.set_flag(flag)
			CutsceneStep.Kind.BATTLE:
				assert_true(_trainers.has_trainer(step.trainer_id),
					"%s : dresseur « %s »" % [where, step.trainer_id])
				for who: StringName in [step.player_pokemon, step.foe_pokemon]:
					if not who.is_empty():
						needed.append(who)
				for flag: StringName in step.outcome_flags(outcome):
					flags.set_flag(flag)
			CutsceneStep.Kind.GIVE:
				assert_true(_items.has_item(step.item_id), "%s : objet « %s »" % [where,
					step.item_id])
			CutsceneStep.Kind.TAKE:
				assert_true(_items.has_item(step.item_id), "%s : objet « %s »" % [where,
					step.item_id])
			CutsceneStep.Kind.SPAWN:
				assert_false(actors.has(step.spec.id), "%s : « %s » déjà là" % [where,
					step.spec.id])
				actors.append(step.spec.id)
				spawned[step.spec.id] = step.spec
			CutsceneStep.Kind.CHANGE_MAP:
				map_id = step.map_id
				actors = _present(map_id, flags)
				spawned.clear()
			CutsceneStep.Kind.FACE:
				needed.append(step.actor)
				if not Grid.is_direction_name(step.target):
					needed.append(step.target)
			CutsceneStep.Kind.MOVE, CutsceneStep.Kind.HOP:
				needed.append(step.actor)
				for other: StringName in [step.follower, step.near]:
					if not other.is_empty():
						needed.append(other)
			CutsceneStep.Kind.LEAN:
				needed.append(step.actor)
				if not Grid.is_direction_name(step.target):
					needed.append(step.target)
			CutsceneStep.Kind.DESPAWN:
				needed.append(step.actor)
			CutsceneStep.Kind.SCARE:
				# Jalon 7 (T2) : seul un Pokémon d'ambiance « shy » peut être effrayé.
				needed.append(step.actor)
				var spec := _spec_of(step.actor, map_id, spawned)
				assert_true(spec != null and spec.is_shy(), "%s : « %s » est « shy »" % [
					where, step.actor])
			CutsceneStep.Kind.DIALOGUE:
				var dialogue := _dialogues.get_dialogue(step.dialogue_id)
				var picked: DialogueVariant = dialogue.pick(flags) if dialogue != null else null
				assert_not_null(picked, "%s : « %s » a une variante" % [where,
					step.dialogue_id])
				if picked != null:
					for page: DialoguePage in picked.pages:
						for actor: StringName in page.turn:
							needed.append(actor)
							if not Grid.is_direction_name(page.turn[actor]):
								needed.append(page.turn[actor])
		for who: StringName in needed:
			checked += 1
			assert_false(CutsceneStep.is_alias(who), "%s : alias « %s » résolu" % [where, who])
			assert_true(actors.has(who), "%s : « %s » présent" % [where, who])
		if step.kind == CutsceneStep.Kind.DESPAWN or step.kind == CutsceneStep.Kind.SCARE:
			actors.erase(step.actor)
	return checked


## Description du PNJ [param id] : créé par la scène, sinon lu dans le fichier de la carte.
func _spec_of(id: StringName, map_id: StringName,
		spawned: Dictionary[StringName, NpcSpec]) -> NpcSpec:
	if spawned.has(id):
		return spawned[id]
	return NpcRoster.load_for_map(map_id).get_spec(id)


## Copie de [param step] avec ses alias remplacés (acteur, cible, voisin, suiveur).
func _resolved(step: CutsceneStep, aliases: Dictionary) -> CutsceneStep:
	if step.get_aliases().is_empty():
		return step
	var copy := CutsceneStep.new()
	copy.kind = step.kind
	copy.dialogue_id = step.dialogue_id
	copy.flags = step.flags
	copy.spec = step.spec
	copy.map_id = step.map_id
	copy.actor = _alias(step.actor, aliases)
	copy.target = _alias(step.target, aliases)
	copy.near = _alias(step.near, aliases)
	copy.follower = _alias(step.follower, aliases)
	copy.trainer_id = step.trainer_id
	copy.item_id = step.item_id
	copy.count = step.count
	copy.win_flags = step.win_flags
	copy.lose_flags = step.lose_flags
	copy.player_pokemon = _alias(step.player_pokemon, aliases)
	copy.foe_pokemon = _alias(step.foe_pokemon, aliases)
	return copy


func _alias(ref: StringName, aliases: Dictionary) -> StringName:
	if not CutsceneStep.is_alias(ref):
		return ref
	return aliases.get(CutsceneStep.alias_name(ref), ref)


## Joueur et PNJ présents sur [param map_id] pour [param flags].
func _present(map_id: StringName, flags: StoryFlags) -> Array[StringName]:
	var ids: Array[StringName] = [NpcRoster.PLAYER_ID]
	for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_present(flags):
		ids.append(spec.id)
	return ids


func _flags(names: Array) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in names:
		flags.set_flag(flag)
	return flags
