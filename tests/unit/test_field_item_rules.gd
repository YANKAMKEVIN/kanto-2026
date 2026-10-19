extends GutTest
## Objets AVENTURE et Corde Sortie (jalon 12, T20 ; `jalon-12.md` §2.6, dossier 15 §11, §20
## n° 32–34) : champ de donnée `field_use` (validé, réservé à AVENTURE), règle pure
## [FieldItemRules] (grotte / hors grotte / objet sans usage, destination), Sac ([BagQuery] :
## UTILISER seulement avec un usage ; refus « Impossible de l'utiliser ici. ») et
## [MenuDirector] (refus dans le bandeau, rien ne change ; accepté → `field_item_requested`,
## rien consommé par le menu ; jamais le choix du Pokémon).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const DOSSIER_15 := "res://docs/design/dossier-15-route-3-mont-selenite.md"

var _items: ItemLibrary
var _caves: CaveLibrary


func before_all() -> void:
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))
	_caves = CaveLibrary.new()
	assert_true(_caves.load_file(), "\n".join(_caves.get_errors()))


func after_each() -> void:
	get_tree().paused = false


# --- Données ------------------------------------------------------------------------------

func test_escape_rope_data() -> void:
	var rope := _items.get_item(&"escape_rope")
	assert_eq(rope.field_use, ItemData.FIELD_USE_ESCAPE_ROPE)
	assert_true(rope.has_field_use())
	assert_eq(rope.category, ItemData.Category.FIELD, "AVENTURE")
	assert_eq(rope.price, 550)
	assert_true(rope.is_sellable(), "se revend comme un objet ordinaire")
	assert_eq(rope.contexts(), [ItemData.CONTEXT_FIELD] as Array[StringName], "hors combat")
	assert_false(rope.targets_pokemon(), "sans cible")
	assert_eq(rope.added_text(1), "Ajoutée au Sac")
	# La Pierre Lune (T23) : pierre d'évolution, UTILISER.
	var stone := _items.get_item(&"moon_stone")
	assert_true(stone.has_field_use())
	assert_eq(stone.field_use, ItemData.FIELD_USE_EVOLUTION_STONE)
	# Le Super Bonbon (jalon 14, T18b) : un Pokémon cible ([RareCandy]).
	var candy := _items.get_item(&"rare_candy")
	assert_eq(candy.field_use, ItemData.FIELD_USE_RARE_CANDY)
	assert_true(RareCandy.is_candy(candy))
	assert_false(RareCandy.is_candy(stone))
	assert_false(StoneUse.is_stone(candy))
	# Jalon 20 (T7) : les quatre pierres du grand magasin, comme la Pierre Lune.
	var stones: Array[StringName] = [&"fire_stone", &"water_stone", &"thunder_stone",
		&"leaf_stone"]
	for id: StringName in stones:
		assert_eq(_items.get_item(id).field_use, ItemData.FIELD_USE_EVOLUTION_STONE, String(id))
	# Aucun autre objet n'a d'usage d'exploration.
	for id: StringName in _items.get_ids():
		if id not in [&"escape_rope", &"moon_stone", &"rare_candy"] and id not in stones:
			assert_eq(_items.get_item(id).field_use, &"", "%s : aucun usage" % id)


func test_field_use_is_validated() -> void:
	var library := ItemLibrary.new()
	var base := {"name": "X", "plural": "X", "feminine": false, "description": "x"}
	var cases: Array = [
		[{"category": "heal", "heal_amount": 20, "field_use": "escape_rope"}, "réservé"],
		[{"category": "key", "field_use": "escape_rope"}, "réservé"],
		[{"category": "field", "field_use": "fly"}, "« field_use » vaut"],
		[{"category": "field", "field_use": 3}, "« field_use » vaut"],
	]
	var i := 0
	for entry: Array in cases:
		var dict: Dictionary = base.duplicate()
		dict.merge(entry[0], true)
		assert_false(library.add_from_dict({StringName("bad_%d" % i): dict}, "t"), str(entry[0]))
		assert_string_contains("\n".join(library.get_errors()), entry[1])
		i += 1
	assert_push_error_count(cases.size())
	var good: Dictionary = base.duplicate()
	good.merge({"category": "field", "field_use": "evolution_stone"}, true)
	assert_true(library.add_from_dict({&"stone": good}, "t"))
	assert_eq(library.get_item(&"stone").field_use, ItemData.FIELD_USE_EVOLUTION_STONE)
	var candy: Dictionary = base.duplicate()
	candy.merge({"category": "field", "field_use": "rare_candy"}, true)
	assert_true(library.add_from_dict({&"candy": candy}, "t"), "jalon 14 : « rare_candy »")
	assert_eq(library.get_item(&"candy").field_use, ItemData.FIELD_USE_RARE_CANDY)
	var not_field: Dictionary = base.duplicate()
	not_field.merge({"category": "heal", "heal_amount": 20, "field_use": "rare_candy"}, true)
	assert_false(library.add_from_dict({&"bad_candy": not_field}, "t"), "réservé à AVENTURE")
	assert_push_error_count(cases.size() + 1)


func test_validated_texts_are_the_dossier_lot() -> void:
	var dossier := FileAccess.get_file_as_string(DOSSIER_15)
	assert_string_contains(dossier, "« %s »" % _items.get_item(&"escape_rope").description)
	assert_string_contains(dossier, "refus : « %s »" % BagQuery.FIELD_REFUSAL_TEXT)
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	var used := dialogues.get_dialogue(Boot.ESCAPE_ROPE_DIALOGUE)
	assert_not_null(used)
	assert_true(used.narration, "narration, sans locuteur")
	assert_eq(used.variants[0].pages.size(), 1)
	assert_string_contains(dossier, "utilisée : « %s »" % used.variants[0].pages[0].text)


# --- Règle pure ----------------------------------------------------------------------------

func test_rope_only_in_a_cave() -> void:
	var rope := _items.get_item(&"escape_rope")
	for map_id: StringName in [&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f"]:
		assert_eq(FieldItemRules.check(rope, map_id, _caves), FieldItemRules.Check.OK,
			"%s : grotte" % map_id)
	for map_id: StringName in [&"route_3", &"pewter_city", &"mt_moon_center", &"route_4",
			&"viridian_forest", &""]:
		assert_eq(FieldItemRules.check(rope, map_id, _caves), FieldItemRules.Check.NOT_HERE,
			"%s : hors grotte" % map_id)
	assert_eq(FieldItemRules.check(rope, &"mt_moon_1f", null), FieldItemRules.Check.NOT_HERE,
		"sans grottes connues")


func test_items_without_field_use() -> void:
	for id: StringName in [&"potion", &"poke_ball", &"oak_parcel", &"tm34"]:
		assert_eq(FieldItemRules.check(_items.get_item(id), &"mt_moon_1f", _caves),
			FieldItemRules.Check.NOT_FIELD_USE, String(id))
		assert_false(FieldItemRules.is_targetless(_items.get_item(id)), String(id))
	assert_eq(FieldItemRules.check(null, &"mt_moon_1f", _caves),
		FieldItemRules.Check.NOT_FIELD_USE)
	assert_true(FieldItemRules.is_targetless(_items.get_item(&"escape_rope")))
	assert_eq(FieldItemRules.check(_items.get_item(&"moon_stone"), &"route_3", _caves),
		FieldItemRules.Check.OK, "Pierre Lune (T23) : partout en exploration")
	assert_false(FieldItemRules.is_targetless(_items.get_item(&"moon_stone")))
	var stone := ItemData.new()
	stone.category = ItemData.Category.FIELD
	stone.field_use = ItemData.FIELD_USE_EVOLUTION_STONE
	assert_eq(FieldItemRules.check(stone, &"route_3", _caves), FieldItemRules.Check.OK,
		"pierre : partout en exploration (le Pokémon se choisit ensuite, T23)")
	assert_false(FieldItemRules.is_targetless(stone), "la pierre a une cible")
	var candy := _items.get_item(&"rare_candy")
	assert_eq(FieldItemRules.check(candy, &"route_25", _caves), FieldItemRules.Check.OK,
		"Super Bonbon (T18b) : partout en exploration")
	assert_false(FieldItemRules.is_targetless(candy), "le Super Bonbon a une cible")


func test_escape_target_from_every_floor() -> void:
	for map_id: StringName in [&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f"]:
		var exit := FieldItemRules.escape_target(map_id, _caves)
		assert_not_null(exit, String(map_id))
		if exit == null:
			continue
		assert_eq([exit.map, exit.spawn, exit.facing],
			[&"route_3", &"from_mt_moon_w", Vector2i.DOWN], "%s : devant l'entrée, ↓" % map_id)
	assert_null(FieldItemRules.escape_target(&"route_3", _caves))
	assert_null(FieldItemRules.escape_target(&"mt_moon_1f", null))


func test_escape_target_uses_the_player_row_in_a_two_mouth_cave() -> void:
	# Jalon 17 (T6, jalon-17.md §2.3) : la bouche de la moitié où se tient le joueur.
	var caves := CaveLibrary.new()
	assert_true(caves.add_from_dict({"caves": {"tunnel": {"maps": ["tunnel"], "escapes": [
		{"rows": [0, 39], "map": "nord", "spawn": "s", "facing": "down"},
		{"rows": [40, 79], "map": "sud", "spawn": "s", "facing": "down"},
	]}}}))
	assert_eq(FieldItemRules.escape_target(&"tunnel", caves, Vector2i(4, 39)).map, &"nord")
	assert_eq(FieldItemRules.escape_target(&"tunnel", caves, Vector2i(4, 40)).map, &"sud")
	assert_null(FieldItemRules.escape_target(&"tunnel", caves), "sans case : aucune")
	assert_eq(FieldItemRules.escape_target(&"mt_moon_1f", _caves, Vector2i(4, 40)).map,
		&"route_3", "Mont Sélénite : la case ne change rien")


# --- Sac -----------------------------------------------------------------------------------

func test_bag_shows_use_only_for_items_with_a_field_use() -> void:
	var bag := Bag.new()
	bag.add(&"escape_rope", 2)
	bag.add(&"moon_stone", 1)
	var by_id := {}
	for view: BagEntryView in BagQuery.entries(bag, _items, BagQuery.CONTEXT_FIELD):
		by_id[view.item_id] = view
	var rope: BagEntryView = by_id[&"escape_rope"]
	assert_true(rope.usable, "Corde : UTILISER")
	assert_eq(rope.action_label, "UTILISER")
	assert_eq(rope.category_id, &"field", "onglet AVENTURE")
	assert_false(rope.targets_pokemon, "sans choix du Pokémon")
	assert_eq(rope.note, "")
	var stone: BagEntryView = by_id[&"moon_stone"]
	assert_true(stone.usable, "Pierre Lune (T23) : UTILISER")
	assert_eq(stone.action_label, "UTILISER")
	assert_true(stone.targets_pokemon, "choix du Pokémon")
	assert_eq(stone.note, "", "aucune mention")
	# En combat : aucun objet AVENTURE.
	for context: StringName in [BagQuery.CONTEXT_WILD_BATTLE, BagQuery.CONTEXT_TRAINER_BATTLE]:
		for view: BagEntryView in BagQuery.entries(bag, _items, context):
			assert_false(view.is_displayable(), "%s : %s absent" % [context, view.item_id])
	# Depuis la fiche Équipe : absente (ne se donne pas à un Pokémon).
	assert_true(BagQuery.entries(bag, _items, BagQuery.CONTEXT_TEAM).is_empty())


func test_refusal_text() -> void:
	assert_eq(BagQuery.field_refusal_text(FieldItemRules.Check.NOT_HERE),
		"Impossible de l'utiliser ici.")
	assert_eq(BagQuery.field_refusal_text(FieldItemRules.Check.OK), "")


# --- Directeur du menu ---------------------------------------------------------------------

func _director_on(map_id: StringName, ropes: int) -> Array:
	var state: Node = GameStateScript.new()
	add_child_autofree(state)
	state.new_game(1)
	if ropes > 0:
		state.bag.add(&"escape_rope", ropes)
	var director := MenuDirector.new()
	add_child_autofree(director)
	director.setup(state, PokemonData.new(), ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(state.flags, state.party), func() -> bool: return true, _items)
	director.set_caves(_caves, func() -> StringName: return map_id)
	var log := {"requested": [], "results": [], "targets": 0}
	director.field_item_requested.connect(func(id: StringName) -> void:
		(log["requested"] as Array).append(id))
	director.bag_result_shown.connect(func(text: String, repeat: bool) -> void:
		(log["results"] as Array).append([text, repeat]))
	director.bag_targets_shown.connect(func(_v: PartyPickerView) -> void:
		log["targets"] = int(log["targets"]) + 1)
	return [director, state, log]


func test_menu_refuses_outside_a_cave() -> void:
	for map_id: StringName in [&"route_3", &"pewter_city", &"mt_moon_center"]:
		var parts := _director_on(map_id, 2)
		var director: MenuDirector = parts[0]
		var state: Node = parts[1]
		var log: Dictionary = parts[2]
		director.request_item_use(&"escape_rope")
		assert_eq(log["results"], [["Impossible de l'utiliser ici.", false]], String(map_id))
		assert_eq(log["requested"], [], "rien demandé")
		assert_eq(log["targets"], 0, "jamais le choix du Pokémon")
		assert_eq(state.bag.count_of(&"escape_rope"), 2, "rien consommé")


func test_menu_requests_the_rope_in_a_cave_without_consuming_it() -> void:
	var parts := _director_on(&"mt_moon_b2f", 1)
	var director: MenuDirector = parts[0]
	var state: Node = parts[1]
	var log: Dictionary = parts[2]
	director.request_item_use(&"escape_rope")
	assert_eq(log["requested"], [&"escape_rope"])
	assert_eq(log["results"], [], "aucun bandeau")
	assert_eq(log["targets"], 0, "jamais le choix du Pokémon")
	assert_eq(state.bag.count_of(&"escape_rope"), 1, "Boot la retire, pas le menu")


func test_menu_ignores_a_rope_not_in_the_bag() -> void:
	var parts := _director_on(&"mt_moon_1f", 0)
	var director: MenuDirector = parts[0]
	var log: Dictionary = parts[2]
	director.request_item_use(&"escape_rope")
	assert_eq(log["requested"], [])
	assert_eq(log["results"], [])
	assert_eq(log["targets"], 0)


func test_healing_items_keep_their_picker() -> void:
	var parts := _director_on(&"mt_moon_1f", 0)
	var director: MenuDirector = parts[0]
	var state: Node = parts[1]
	var log: Dictionary = parts[2]
	state.bag.add(&"potion", 1)
	director.request_item_use(&"potion")
	assert_eq(log["targets"], 1, "la Potion ouvre le choix du Pokémon, comme avant")
	assert_eq(log["requested"], [])
