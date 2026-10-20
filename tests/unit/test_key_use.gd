extends GutTest
## Objet clé utilisable (passe systèmes 2, `systemes-2.md` §2.4, T10) : clé « key_use » des
## données (objets clés seulement), contextes déduits, Sac → UTILISER sans cible.

var _library: ItemLibrary


func before_each() -> void:
	_library = ItemLibrary.new()


func _key(extra: Dictionary) -> Dictionary:
	var entry := {
		"name": "Objet", "plural": "Objets", "feminine": false, "category": "key",
		"description": "Un objet.",
	}
	entry.merge(extra, true)
	return entry


func test_key_use_is_read_on_a_key_item() -> void:
	assert_true(_library.add_from_dict({"flute": _key({"key_use": "poke_flute"})}))
	var item := _library.get_item(&"flute")
	assert_eq(item.key_use, ItemData.KEY_USE_POKE_FLUTE)
	assert_true(item.has_key_use())


func test_key_use_is_refused_outside_key_items() -> void:
	var entry := _key({"key_use": "bicycle"})
	entry["category"] = "field"
	entry["field_use"] = "escape_rope"
	assert_false(_library.add_from_dict({"rope": entry}))
	assert_false(_library.has_item(&"rope"))
	assert_push_error("« key_use » est réservé aux objets clés")


func test_an_unknown_key_use_is_refused() -> void:
	assert_false(_library.add_from_dict({"x": _key({"key_use": "jetpack"})}))
	assert_push_error("« key_use » vaut")


func test_a_key_item_without_use_keeps_no_context() -> void:
	_library.add_from_dict({"parcel": _key({})})
	var item := _library.get_item(&"parcel")
	assert_false(item.has_key_use())
	assert_eq(item.contexts(), [] as Array[StringName], "le Colis se consulte, sans UTILISER")
	assert_eq(FieldItemRules.check(item, &"route_1", null), FieldItemRules.Check.NOT_FIELD_USE)


func test_the_bicycle_is_used_in_the_field_only() -> void:
	_library.add_from_dict({"bike": _key({"key_use": "bicycle"})})
	var item := _library.get_item(&"bike")
	assert_eq(item.contexts(), [ItemData.CONTEXT_FIELD] as Array[StringName])
	assert_true(FieldItemRules.is_targetless(item))
	assert_eq(FieldItemRules.check(item, &"oak_lab", null), FieldItemRules.Check.OK,
		"le refus en intérieur est celui du Vélo, avec son texte")


func test_real_data_has_the_bicycle_and_the_flute() -> void:
	assert_true(_library.load_dir())
	assert_eq(_library.get_item(&"bicycle").key_use, ItemData.KEY_USE_BICYCLE)
	assert_eq(_library.get_item(&"poke_flute").key_use, ItemData.KEY_USE_POKE_FLUTE)
	assert_eq(_library.get_item(&"poke_flute").description,
		"Une flûte à la mélodie douce. Elle réveille les Pokémon endormis.",
		"dossier 24 §15.6.2 (validé)")
	assert_eq(_library.get_item(&"bicycle").description,
		"Une bicyclette pliante. Elle va deux fois plus vite que la marche.",
		"dossier 25 §16.1.7 (validé)")
