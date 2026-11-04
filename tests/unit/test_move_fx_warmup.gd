extends GutTest
## RP-263 : préchauffage des effets de combat ([MoveFxWarmup], [method MoveFxPlayer.warm_up]) :
## couvre les familles des attaques des deux équipes, une seule fois par session, invisible, et
## se retire seul.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")

var _data: PokemonData
var _catalog: MoveFxCatalog
var _player: MoveFxPlayer


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = MoveFxCatalog.load_dir()


func before_each() -> void:
	MoveFxPlayer.reset_warmup()
	MoveFxPlayer.warmup_enabled = true
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	_player = MoveFxPlayer.new()
	layer.add_child(_player)


func after_all() -> void:
	MoveFxPlayer.reset_warmup()
	MoveFxPlayer.warmup_enabled = true


func _party(entries: Array) -> Party:
	var party := Party.new()
	var rng := GameRng.new(7)
	for entry: Array in entries:
		var pokemon := PokemonFactory.create(_data, entry[0], entry[1], rng)
		party.add(pokemon)
	return party


func _plans(parties: Array[Party]) -> Array[MoveFxPlan]:
	return MoveFxWarmup.plans_for(_catalog, _data, parties)


func _warmup_layer() -> Node:
	return _player.get_node_or_null(^"Warmup")


func test_plans_cover_every_move_of_both_teams_once() -> void:
	var mine := _party([[&"charmander", 5], [&"pidgey", 5]])
	var foe := _party([[&"pidgey", 3], [&"squirtle", 6]])
	var plans := _plans([mine, foe] as Array[Party])
	var expected: Dictionary[StringName, bool] = {}
	for party: Party in [mine, foe]:
		for pokemon: Pokemon in party.get_all():
			for slot: MoveSlot in pokemon.moves:
				expected[slot.move_id] = true
	var ids: Array[StringName] = []
	for plan: MoveFxPlan in plans:
		ids.append(plan.move_id)
	assert_eq(ids.size(), expected.size(), "une chorégraphie par attaque, sans doublon")
	for id: StringName in expected:
		assert_true(ids.has(id), "%s couvert" % id)
	var families := MoveFxWarmup.families(plans)
	for id: StringName in expected:
		var move := _data.get_move(id)
		var category := StringName(MoveData.CATEGORY_NAMES.find_key(move.category))
		assert_true(families.has(_catalog.entry(id, move.type, category).family),
			"famille de %s couverte" % id)


func test_art_of_the_plans_is_listed() -> void:
	var plans := _plans([_party([[&"charmander", 5]])] as Array[Party])
	var art := MoveFxWarmup.art_ids(plans)
	assert_false(art.is_empty())
	for id: StringName in art:
		assert_true(FxArt.has(id), String(id))


func test_warm_up_draws_once_per_session_then_only_new_art() -> void:
	var first := _plans([_party([[&"charmander", 5]])] as Array[Party])
	var drawn := _player.warm_up(first, Vector2(960, 540))
	assert_gt(drawn, 6, "pipelines (sprite, trait, émetteur ×2 mélanges) et art")
	var layer := _warmup_layer()
	assert_not_null(layer, "calque de préchauffage")
	assert_lte(layer.modulate.a, MoveFxPlayer.WARMUP_ALPHA, "invisible à l'œil")
	assert_gt(layer.modulate.a, 0.0, "mais dessiné")
	layer.free()
	assert_eq(_player.warm_up(first, Vector2(960, 540)), 0, "rien de neuf : rien")
	var later := _plans([_party([[&"squirtle", 10]])] as Array[Party])
	var fresh := 0
	for id: StringName in MoveFxWarmup.art_ids(later):
		if not MoveFxWarmup.art_ids(first).has(id):
			fresh += 1
	assert_eq(_player.warm_up(later, Vector2(960, 540)), fresh,
		"seulement l'art pas encore préparé, sans les pipelines")


func test_warm_up_layer_leaves_by_itself() -> void:
	var clock := TweenClock.new(get_tree())
	_player.warm_up(_plans([_party([[&"bulbasaur", 5]])] as Array[Party]), Vector2(960, 540))
	var layer := _warmup_layer()
	assert_not_null(layer)
	clock.step(MoveFxPlayer.WARMUP_DURATION * 0.5)
	assert_true(is_instance_valid(layer), "encore là avant la durée")
	clock.run_until(func() -> bool: return layer.is_queued_for_deletion(),
		MoveFxPlayer.WARMUP_DURATION + 0.1)
	assert_true(layer.is_queued_for_deletion(), "retiré après %.2f s" % MoveFxPlayer.WARMUP_DURATION)
	clock.release()


func test_warm_up_can_be_disabled() -> void:
	MoveFxPlayer.warmup_enabled = false
	assert_eq(_player.warm_up(_plans([_party([[&"bulbasaur", 5]])] as Array[Party]),
		Vector2.ZERO), 0)
	assert_null(_warmup_layer())
