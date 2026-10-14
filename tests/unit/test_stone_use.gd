extends GutTest
## Pierre Lune (jalon 12, T23 ; `jalon-12.md` §2.9, dossier 15 §10, §20 n° 35) : règle pure
## [StoneUse] (COMPATIBLE / INCOMPATIBLE, K.O. compatible, candidat non annulable), Sac
## ([BagQuery] : UTILISER ouvre le choix du Pokémon, libellés toujours visibles) et
## [MenuDirector] (`evolution_item_requested` pour un Pokémon compatible, rien consommé par le
## menu, rien pour un incompatible).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const STONE := &"moon_stone"
## Données RB : les quatre espèces qui évoluent avec la Pierre Lune.
const COMPATIBLE := {
	&"nidorina": &"nidoqueen", &"nidorino": &"nidoking",
	&"clefairy": &"clefable", &"jigglypuff": &"wigglytuff",
}

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir())
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))


func after_each() -> void:
	get_tree().paused = false


func _mon(species: StringName, level: int = 20) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(5))


# --- Règle --------------------------------------------------------------------------------

func test_the_four_compatible_species() -> void:
	for species: StringName in COMPATIBLE:
		var pokemon := _mon(species)
		assert_eq(StoneUse.check(pokemon, STONE, _data), StoneUse.Check.COMPATIBLE,
			String(species))
		assert_eq(StoneUse.target(pokemon, STONE, _data), COMPATIBLE[species], String(species))


func test_incompatible_species_and_items() -> void:
	for species: StringName in [&"pikachu", &"charmander", &"nidoran_f", &"nidoran_m",
			&"clefable", &"wigglytuff", &"nidoqueen", &"zubat", &"geodude"]:
		var pokemon := _mon(species)
		assert_eq(StoneUse.check(pokemon, STONE, _data), StoneUse.Check.INCOMPATIBLE,
			String(species))
		assert_eq(StoneUse.target(pokemon, STONE, _data), &"", String(species))
	var nidorina := _mon(&"nidorina")
	for item: StringName in [&"potion", &"escape_rope", &"", &"fire_stone"]:
		assert_eq(StoneUse.check(nidorina, item, _data), StoneUse.Check.INCOMPATIBLE,
			"objet « %s »" % item)
	assert_eq(StoneUse.check(null, STONE, _data), StoneUse.Check.INCOMPATIBLE)
	assert_eq(StoneUse.check(nidorina, STONE, null), StoneUse.Check.INCOMPATIBLE)


func test_a_fainted_pokemon_stays_compatible() -> void:
	var clefairy := _mon(&"clefairy")
	clefairy.hp = 0
	assert_true(clefairy.is_fainted())
	assert_eq(StoneUse.check(clefairy, STONE, _data), StoneUse.Check.COMPATIBLE)


func test_labels_are_those_of_the_tms() -> void:
	assert_eq(StoneUse.LABELS[StoneUse.Check.COMPATIBLE], "COMPATIBLE")
	assert_eq(StoneUse.LABELS[StoneUse.Check.INCOMPATIBLE], "INCOMPATIBLE")
	assert_eq(StoneUse.LABELS.size(), 2, "jamais « déjà connue »")


func test_is_stone() -> void:
	assert_true(StoneUse.is_stone(_items.get_item(STONE)))
	for id: StringName in [&"escape_rope", &"potion", &"tm34", &"dome_fossil", &"poke_ball"]:
		assert_false(StoneUse.is_stone(_items.get_item(id)), String(id))
	assert_false(StoneUse.is_stone(null))


func test_candidate_is_not_cancellable_and_carries_the_stone() -> void:
	var party := Party.new()
	party.add(_mon(&"pikachu"))
	party.add(_mon(&"jigglypuff"))
	var candidate := StoneUse.candidate(party, 1, STONE, _data)
	assert_not_null(candidate)
	assert_eq([candidate.party_index, candidate.from_species, candidate.into],
		[1, &"jigglypuff", &"wigglytuff"])
	assert_false(candidate.cancellable, "non annulable")
	assert_eq(candidate.item_id, STONE)
	assert_null(StoneUse.candidate(party, 0, STONE, _data), "Pikachu : incompatible")
	assert_null(StoneUse.candidate(party, 5, STONE, _data), "place vide")
	assert_null(StoneUse.candidate(null, 0, STONE, _data))
	# Les candidats de fin de combat restent annulables (inchangé).
	var level := EvolutionCandidate.new(0, &"caterpie", &"metapod")
	assert_true(level.cancellable)
	assert_eq(level.item_id, &"")


# --- Sac ----------------------------------------------------------------------------------

func test_bag_targets_show_compatible_and_incompatible() -> void:
	var party := Party.new()
	party.add(_mon(&"charmander"))
	party.add(_mon(&"clefairy"))
	var fainted := _mon(&"nidorino")
	fainted.hp = 0
	party.add(fainted)
	var bag := Bag.new()
	bag.add(STONE, 2)
	var stone := _items.get_item(STONE)
	var picker := BagQuery.targets(party, bag, stone, BagQuery.CONTEXT_FIELD, _data)
	assert_eq(picker.item_id, STONE)
	assert_eq(picker.item_name, "Pierre Lune")
	assert_eq(picker.quantity, 2)
	assert_false(picker.permanent, "consommée : la quantité s'affiche")
	assert_eq(picker.size(), 3)
	var expected := [[false, "INCOMPATIBLE"], [true, "COMPATIBLE"], [true, "COMPATIBLE"]]
	for i: int in 3:
		var target := picker.target_at(i)
		assert_eq([target.usable, target.reason], expected[i], "place %d" % i)
		assert_true(target.show_reason, "libellé toujours visible (place %d)" % i)
	var entry: BagEntryView = BagQuery.entries(bag, _items, BagQuery.CONTEXT_FIELD)[0]
	assert_true(entry.usable)
	assert_true(entry.targets_pokemon, "UTILISER ouvre le choix du Pokémon")
	assert_eq(entry.action_label, "UTILISER")
	assert_eq(entry.category_id, &"field", "onglet AVENTURE")


# --- Directeur du menu ------------------------------------------------------------------

func _director(species: Array[StringName], stones: int) -> Array:
	var state: Node = GameStateScript.new()
	add_child_autofree(state)
	state.new_game(1)
	for id: StringName in species:
		state.party.add(_mon(id))
	if stones > 0:
		state.bag.add(STONE, stones)
	var director := MenuDirector.new()
	add_child_autofree(director)
	director.setup(state, _data, ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(state.flags, state.party), func() -> bool: return true, _items)
	var log := {"requested": [], "targets": [], "results": []}
	director.evolution_item_requested.connect(func(i: int, id: StringName) -> void:
		(log["requested"] as Array).append([i, id]))
	director.bag_targets_shown.connect(func(v: PartyPickerView) -> void:
		(log["targets"] as Array).append(v))
	director.bag_result_shown.connect(func(text: String, _r: bool) -> void:
		(log["results"] as Array).append(text))
	return [director, state, log]


func test_menu_opens_the_picker_then_requests_the_evolution() -> void:
	var parts := _director([&"pikachu", &"nidorina"] as Array[StringName], 1)
	var director: MenuDirector = parts[0]
	var state: Node = parts[1]
	var log: Dictionary = parts[2]
	director.request_item_use(STONE)
	assert_eq((log["targets"] as Array).size(), 1, "choix du Pokémon")
	assert_false(director.use_item_on(STONE, 0), "Pikachu : INCOMPATIBLE, refusé")
	assert_eq(log["requested"], [], "rien demandé")
	assert_true(director.use_item_on(STONE, 1))
	assert_eq(log["requested"], [[1, STONE]])
	assert_eq(state.bag.count_of(STONE), 1, "rien consommé par le menu")
	assert_eq(state.party.get_at(1).species_id, &"nidorina", "rien n'évolue dans le menu")
	assert_eq(log["results"], [], "aucun bandeau")


func test_menu_refuses_without_a_stone_in_the_bag() -> void:
	var parts := _director([&"clefairy"] as Array[StringName], 0)
	var director: MenuDirector = parts[0]
	var log: Dictionary = parts[2]
	assert_false(director.use_item_on(STONE, 0))
	assert_eq(log["requested"], [])
