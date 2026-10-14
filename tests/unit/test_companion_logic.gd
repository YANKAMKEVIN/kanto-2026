extends GutTest
## Compagnon, logique pure (jalon 11, T19 ; dossier 14 §8, `jalon-11-compagnon.md` §2 et §5) :
## catalogue (9 espèces, planches réelles repos + marche), éligibilité, visibilité, effacement du
## choix, phrase de curiosité, suivi pas à pas (couloir, virage, échange, rebords, course,
## arrivée avec ou sans case).

const W := CompanionTrail.WALK
const R := CompanionTrail.RUN
const J := CompanionTrail.JUMP
const NONE := CompanionTrail.NONE

var _data: PokemonData
var _catalog: CompanionCatalog


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = CompanionCatalog.new()
	assert_true(_catalog.load_file(), "\n".join(_catalog.get_errors()))


func _mon(species: StringName, level: int = 10) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(3))


# --- Catalogue (T19a) --------------------------------------------------------------------------

func test_the_twenty_five_eligible_species_of_the_dossier() -> void:
	assert_eq(_catalog.get_species_ids(), [&"bulbasaur", &"butterfree", &"charmander",
		&"charmeleon", &"clefairy", &"ekans", &"fearow", &"geodude", &"ivysaur", &"jigglypuff",
		&"mankey", &"nidoran_f", &"nidoran_m", &"nidorina", &"nidorino", &"paras", &"pidgeotto",
		&"pidgey", &"pikachu", &"raticate", &"rattata", &"spearow", &"squirtle", &"wartortle",
		&"zubat"] as Array[StringName],
		"dossier 14 §8.2 : les 9 de départ + les 5 de la série 13 + les 11 de la série 14 (J12 T21)")
	assert_true(_catalog.is_flying(&"zubat"), "Nosferapti en vol (J12 T21)")
	assert_false(_catalog.is_flying(&"jigglypuff"))
	assert_eq(_catalog.sprite_of(&"geodude"), &"pokemon/geodude_walk",
		"Racaillou qui marche, pas le Racaillou fixe du tailleur")
	assert_false(_catalog.is_eligible_species(&"golbat"), "pas de planche (A-11)")
	assert_true(_catalog.is_flying(&"butterfree"), "Papilusion en vol")
	assert_false(_catalog.is_flying(&"ivysaur"))
	assert_false(_catalog.is_eligible_species(&"charizard"), "pas de planche : hors du lot (A-11)")
	assert_false(_catalog.is_eligible_species(&"caterpie"), "pas de planche de marche")
	assert_false(_catalog.is_eligible_species(&"onix"))
	assert_eq(_catalog.context_of(&"viridian_forest"), &"forest")
	assert_eq(_catalog.context_of(&"pewter_city"), &"city")
	assert_eq(_catalog.context_of(&"pallet_town"), &"", "Bourg Palette : générique (D-7)")


## Chaque espèce éligible a sa planche peinte, repos et marche dans les 4 directions : jamais le
## repli provisoire (dossier 14 §8.2 : aucun substitut).
func test_every_eligible_species_has_a_real_painted_walk_sheet() -> void:
	for species: StringName in _catalog.get_species_ids():
		assert_true(_data.has_species(species), String(species))
		var look := CharacterLook.resolve(_catalog.sprite_of(species))
		assert_true(look.painted, "%s : planche peinte" % species)
		var frames := load(look.frames_path) as SpriteFrames
		for prefix: String in ["idle_", "walk_"]:
			for dir: String in ["down", "up", "left", "right"]:
				assert_true(frames.has_animation(StringName(prefix + dir)),
					"%s : %s%s" % [species, prefix, dir])


func test_invalid_entries_are_rejected() -> void:
	var catalog := CompanionCatalog.new()
	assert_false(catalog.add_from_dict({
		"species": {
			"a": {"sprite": "pidgey"},
			"b": {"sprite": "pokemon/b", "flying": "yes"},
			"c": {"sprite": "pokemon/c", "speed": 2},
		},
		"contexts": {"x": "beach"},
		"extra": 1,
	}, "t"))
	assert_eq(catalog.get_species_ids(), [] as Array[StringName])
	assert_push_error_count(5)
	assert_false(catalog.add_from_dict({"species": {"zzz": {"sprite": "pokemon/zzz"}}}, "t",
		_data), "espèce inconnue")
	assert_push_error_count(6)


# --- Règles (T19b) -----------------------------------------------------------------------------

func test_eligibility_and_visibility_table() -> void:
	var charmander := _mon(&"charmander")
	assert_true(CompanionRules.is_eligible(charmander, _catalog))
	assert_false(CompanionRules.is_eligible(_mon(&"caterpie"), _catalog))
	assert_false(CompanionRules.is_eligible(null, _catalog))
	var input := CompanionRules.VisibilityInput.new()
	input.chosen = charmander
	input.placed = true
	assert_true(CompanionRules.is_visible(input, _catalog), "extérieur, rien en cours")
	for field: String in ["map_interior", "in_cutscene", "in_battle", "in_transition"]:
		input.set(field, true)
		assert_false(CompanionRules.is_visible(input, _catalog), field)
		input.set(field, false)
	input.placed = false
	assert_false(CompanionRules.is_visible(input, _catalog), "pas de case")
	input.placed = true
	charmander.hp = 0
	assert_false(CompanionRules.is_visible(input, _catalog), "K.O. : invisible…")
	assert_eq(CompanionRules.clear_reason("abc", charmander, _catalog),
		CompanionRules.Clear.KEEP, "…mais reste choisi")
	input.chosen = null
	assert_false(CompanionRules.is_visible(input, _catalog), "aucun compagnon")


func test_the_choice_is_cleared_only_when_it_must() -> void:
	assert_eq(CompanionRules.clear_reason("", null, _catalog), CompanionRules.Clear.KEEP)
	assert_eq(CompanionRules.clear_reason("abc", null, _catalog),
		CompanionRules.Clear.NOT_IN_PARTY, "déposé ou libéré")
	var evolved := _mon(&"charmander")
	evolved.species_id = &"charmeleon"
	assert_eq(CompanionRules.clear_reason("abc", evolved, _catalog), CompanionRules.Clear.KEEP,
		"évolue en Reptincel, qui a sa planche : reste compagnon")
	evolved.species_id = &"charizard"
	assert_eq(CompanionRules.clear_reason("abc", evolved, _catalog),
		CompanionRules.Clear.NOT_ELIGIBLE, "évolue en espèce sans planche (A-11)")


func test_curiosity_line_follows_visible_facts_in_order() -> void:
	var first := func(_n: int) -> int: return 0
	var mon := _mon(&"pidgey")
	assert_eq(CompanionRules.curiosity_line(mon, false, &"", &"", first), &"companion_happy")
	assert_eq(CompanionRules.curiosity_line(mon, false, &"forest", &"", first), &"companion_forest")
	assert_eq(CompanionRules.curiosity_line(mon, false, &"city", &"", first), &"companion_city")
	assert_eq(CompanionRules.curiosity_line(mon, true, &"city", &"", first), &"companion_water",
		"l'eau avant le contexte")
	mon.status = StatusRules.POISON
	assert_eq(CompanionRules.curiosity_line(mon, true, &"city", &"", first), &"companion_unwell")
	mon.hp = floori(mon.max_hp() / 3.0)
	assert_eq(CompanionRules.curiosity_line(mon, true, &"city", &"", first), &"companion_tired",
		"PV bas d'abord")
	mon.status = StatusRules.NONE
	mon.hp = mon.max_hp()
	assert_eq(CompanionRules.curiosity_line(mon, false, &"", &"companion_happy", first),
		&"companion_sniff", "jamais deux fois de suite la même (D-8)")
	var seen := {}
	for i: int in 5:
		var pick := func(_n: int) -> int: return i
		seen[CompanionRules.curiosity_line(mon, false, &"", &"", pick)] = true
	assert_eq(seen.size(), 5, "cinq génériques")
	assert_true(CompanionRules.is_near_water(Vector2i(5, 5), [Vector2i(6, 6)] as Array[Vector2i]))
	assert_false(CompanionRules.is_near_water(Vector2i(5, 5), [Vector2i(8, 5)] as Array[Vector2i]))


# --- Suivi (T19b) ------------------------------------------------------------------------------

func _free(_cell: Vector2i) -> bool:
	return true


func _step(trail: CompanionTrail, from: Vector2i, to: Vector2i, kind: StringName) -> Array:
	var step := trail.on_player_step(from, to, kind)
	return [step.from_cell, step.to_cell, step.kind, step.pace, step.appear]


func test_straight_corridor_and_turn_follow_the_left_cell() -> void:
	var trail := CompanionTrail.new()
	assert_eq(trail.place_after_arrival(Vector2i(5, 5), Vector2i.UP, _free), Vector2i(5, 6),
		"derrière le joueur")
	assert_eq(_step(trail, Vector2i(5, 5), Vector2i(5, 4), W),
		[Vector2i(5, 6), Vector2i(5, 5), W, W, false])
	assert_eq(_step(trail, Vector2i(5, 4), Vector2i(6, 4), W),
		[Vector2i(5, 5), Vector2i(5, 4), W, W, false], "virage : angles droits")
	assert_eq(_step(trail, Vector2i(6, 4), Vector2i(7, 4), R),
		[Vector2i(5, 4), Vector2i(6, 4), R, R, false], "course : même vitesse")


func test_walking_onto_the_companion_swaps_places() -> void:
	var trail := CompanionTrail.new()
	trail.place_after_arrival(Vector2i(5, 5), Vector2i.UP, _free)
	assert_eq(_step(trail, Vector2i(5, 5), Vector2i(5, 6), W),
		[Vector2i(5, 6), Vector2i(5, 5), W, W, false], "ils se croisent (D-4)")


func test_a_ledge_is_jumped_by_the_companion_on_the_next_step() -> void:
	var trail := CompanionTrail.new()
	trail.place_after_arrival(Vector2i(5, 3), Vector2i.DOWN, _free)
	# Le joueur saute le rebord de (5, 3) à (5, 5) : le compagnon arrive au bord, à la vitesse
	# du saut.
	assert_eq(_step(trail, Vector2i(5, 3), Vector2i(5, 5), J),
		[Vector2i(5, 2), Vector2i(5, 3), W, J, false])
	# Pas suivant : le compagnon saute le rebord à son tour, jamais à travers.
	assert_eq(_step(trail, Vector2i(5, 5), Vector2i(5, 6), W),
		[Vector2i(5, 3), Vector2i(5, 5), J, W, false])
	assert_eq(_step(trail, Vector2i(5, 6), Vector2i(5, 7), W),
		[Vector2i(5, 5), Vector2i(5, 6), W, W, false])


func test_two_ledges_in_a_row() -> void:
	var trail := CompanionTrail.new()
	trail.place_after_arrival(Vector2i(0, 0), Vector2i.DOWN, _free)
	_step(trail, Vector2i(0, 0), Vector2i(0, 2), J)
	assert_eq(_step(trail, Vector2i(0, 2), Vector2i(0, 4), J),
		[Vector2i(0, 0), Vector2i(0, 2), J, J, false])
	assert_eq(_step(trail, Vector2i(0, 4), Vector2i(0, 5), W),
		[Vector2i(0, 2), Vector2i(0, 4), J, W, false])


func test_arrival_without_a_free_cell_appears_on_the_first_step() -> void:
	var trail := CompanionTrail.new()
	var blocked := func(_cell: Vector2i) -> bool: return false
	assert_eq(trail.place_after_arrival(Vector2i(5, 5), Vector2i.UP, blocked), NONE)
	assert_false(trail.is_placed())
	assert_eq(_step(trail, Vector2i(5, 5), Vector2i(5, 4), W),
		[NONE, Vector2i(5, 5), W, W, true], "apparaît sur la case quittée")
	assert_true(trail.is_placed())
	trail.clear()
	assert_false(trail.is_placed(), "intérieur, scène, rappel")


## Garantie : le compagnon n'est jamais à plus d'un pas (ou d'un saut) du joueur et n'entre que
## dans des cases où le joueur est passé.
func test_never_more_than_one_step_behind_on_a_random_walk() -> void:
	var trail := CompanionTrail.new()
	var player := Vector2i(0, 0)
	trail.place_after_arrival(player, Vector2i.RIGHT, _free)
	var visited := {player: true, trail.get_cell(): true}
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for i: int in 300:
		var dir := dirs[rng.randi_range(0, 3)]
		var kind: StringName = [W, R, J][rng.randi_range(0, 2)]
		var to := player + dir * (2 if kind == J else 1)
		var step := trail.on_player_step(player, to, kind)
		assert_true(visited.has(step.to_cell), "pas %d : case déjà visitée par le joueur" % i)
		player = to
		visited[player] = true
		var gap := absi(player.x - step.to_cell.x) + absi(player.y - step.to_cell.y)
		assert_lte(gap, 2, "pas %d : au plus un pas ou un saut" % i)
