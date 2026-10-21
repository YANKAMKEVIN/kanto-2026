extends GutTest
## Champ d'objet `obtained` (jalon 12, T23 ; `jalon-12.md` §0.4 n° 7, dossier 15 §20 n° 27–29) :
## toast « Fossile Dôme » / « obtenu » des fossiles (objets clés), sans changer celui des CT
## (« CT34 — Patience » / « obtenue ») ni celui des autres objets clés (« COLIS POUR CHEN » /
## « ajouté aux objets clés ») ; donnée facultative, booléenne.

var _items: ItemLibrary


func before_all() -> void:
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))


func test_fossils_are_obtained_key_items() -> void:
	var expected := {
		&"dome_fossil": ["Fossile Dôme", "Fossile d'un Pokémon ancien à la carapace en dôme."],
		&"helix_fossil": ["Fossile Nautile",
			"Fossile d'un Pokémon ancien à la coquille en spirale."],
	}
	for id: StringName in expected:
		var item := _items.get_item(id)
		assert_true(item.is_key(), "%s : objet clé" % id)
		assert_true(item.obtained, String(id))
		assert_eq(item.description, expected[id][1], "%s : description (§20)" % id)
		assert_eq(item.quantity_text(1), expected[id][0], "%s : nom tel quel" % id)
		assert_eq(item.added_text(1), "obtenu", "%s : « {fossil} obtenu » (§20 n° 27)" % id)
		assert_eq(item.price, 0)
		assert_false(item.is_sellable())


func test_tm_and_other_key_items_toasts_are_unchanged() -> void:
	var tm := _items.get_item(&"tm34")
	assert_false(tm.obtained)
	assert_eq(tm.quantity_text(1), tm.name)
	assert_eq(tm.added_text(1), "obtenue")
	var parcel := _items.get_item(&"oak_parcel")
	assert_false(parcel.obtained)
	assert_eq(parcel.quantity_text(1), parcel.name.to_upper())
	assert_eq(parcel.added_text(1), "ajouté aux objets clés")
	# Jalon 20 (T7, plan §2.7.5) : le Scope Sylphe aussi (toast « obtenu », T-55).
	assert_true(_items.get_item(&"silph_scope").obtained)
	for id: StringName in _items.get_ids():
		if id not in [&"dome_fossil", &"helix_fossil", &"silph_scope"]:
			assert_false(_items.get_item(id).obtained, "%s : pas « obtained »" % id)


func test_obtained_is_validated() -> void:
	var library := ItemLibrary.new()
	var base := {"name": "X", "plural": "X", "feminine": false, "description": "x",
		"category": "key"}
	var good := base.duplicate()
	good["obtained"] = true
	assert_true(library.add_from_dict({"good": good}, "t"))
	assert_true(library.get_item(&"good").obtained)
	var bad := base.duplicate()
	bad["obtained"] = "oui"
	assert_false(library.add_from_dict({"bad": bad}, "t"))
	assert_false(library.has_item(&"bad"))
	assert_push_error_count(1)
