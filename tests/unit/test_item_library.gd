extends GutTest
## ItemLibrary et ItemData (jalon-04.md §14.6) : vraies données (la Poké Ball donnée par
## le Prof. Chen), validation stricte, textes du toast (bible UI §6) accordés.

const BALL := {
	"name": "Poké Ball", "plural": "Poké Balls", "feminine": true,
	"category": "ball", "catch_bonus": 1, "description": "Capture.",
}

var _library: ItemLibrary


func before_each() -> void:
	_library = ItemLibrary.new()


func test_real_data_loads_without_error() -> void:
	assert_true(_library.load_dir(), "data/items/ se charge")
	assert_eq(_library.get_errors().size(), 0, str(_library.get_errors()))
	# Jalon 5 : la Potion cachée de la Route 1 (catégorie « heal », ramassée seulement).
	assert_eq(_library.get_ids(), [&"poke_ball", &"potion"] as Array[StringName])
	var ball := _library.get_item(&"poke_ball")
	assert_eq(ball.name, "Poké Ball")
	assert_eq(ball.plural, "Poké Balls")
	assert_true(ball.feminine)
	assert_eq(ball.category, ItemData.Category.BALL)
	assert_eq(ball.catch_bonus, 1.0)
	assert_true(ball.draft, "description à relire par Kevin")
	assert_eq(ball.source, "res://data/items/items.json")
	var potion := _library.get_item(&"potion")
	assert_eq(potion.name, "Potion")
	assert_eq(potion.category, ItemData.Category.HEAL)
	assert_eq(potion.catch_bonus, 1.0, "pas de catch_bonus hors Ball (valeur par défaut)")


## Dossier 07 §8 (« Poké Balls ×5 ») et bible UI §6 (« Potion ×1 — Ajoutée au Sac »).
func test_toast_texts_of_the_five_poke_balls() -> void:
	_library.load_dir()
	var ball := _library.get_item(&"poke_ball")
	assert_eq(ball.quantity_text(5), "Poké Balls ×5")
	assert_eq(ball.added_text(5), "Ajoutées au Sac")
	assert_eq(ball.quantity_text(1), "Poké Ball ×1")
	assert_eq(ball.added_text(1), "Ajoutée au Sac")


func test_masculine_agreement() -> void:
	var item := ItemData.new()
	item.name = "Rappel"
	item.plural = "Rappels"
	item.feminine = false
	assert_eq(item.quantity_text(1), "Rappel ×1")
	assert_eq(item.added_text(1), "Ajouté au Sac")
	assert_eq(item.quantity_text(2), "Rappels ×2")
	assert_eq(item.added_text(2), "Ajoutés au Sac")


func test_valid_entry() -> void:
	assert_true(_library.add_from_dict({"poke_ball": BALL}, "test"))
	assert_true(_library.has_item(&"poke_ball"))
	assert_eq(_library.size(), 1)
	assert_false(_library.get_item(&"poke_ball").draft, "draft facultatif, faux par défaut")
	assert_null(_library.get_item(&"missing"))


func test_invalid_entries_are_rejected() -> void:
	var bad: Array[Dictionary] = []
	for key: String in ["name", "plural", "feminine", "category", "description"]:
		var entry := BALL.duplicate()
		entry.erase(key)
		bad.append(entry)
	var extra := BALL.duplicate()
	extra["price"] = 200
	bad.append(extra)
	var no_bonus := BALL.duplicate()
	no_bonus.erase("catch_bonus")
	bad.append(no_bonus)
	var zero_bonus := BALL.duplicate()
	zero_bonus["catch_bonus"] = 0
	bad.append(zero_bonus)
	var unknown := BALL.duplicate()
	unknown["category"] = "berry"
	bad.append(unknown)
	var empty_name := BALL.duplicate()
	empty_name["name"] = " "
	bad.append(empty_name)
	var not_bool := BALL.duplicate()
	not_bool["feminine"] = "oui"
	bad.append(not_bool)
	for i: int in bad.size():
		assert_false(_library.add_from_dict({"item_%d" % i: bad[i]}, "test"), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par entrée")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["« name » est obligatoire", "clé inconnue « price »",
			"« catch_bonus » doit être", "catégorie inconnue « berry »",
			"« name » doit être un texte", "« feminine » vaut true ou false"]:
		assert_string_contains(errors, expected)


## Jalon 5D : le multiplicateur de capture est une donnée de la Ball, lu par le moteur.
func test_catch_bonus_belongs_to_balls_only() -> void:
	var better := BALL.duplicate()
	better["catch_bonus"] = 1.5
	assert_true(_library.add_from_dict({"great_ball": better}, "test"))
	assert_eq(_library.get_item(&"great_ball").catch_bonus, 1.5, "nombre décimal accepté")
	var healing := BALL.duplicate()
	healing["category"] = "heal"
	assert_false(_library.add_from_dict({"potion": healing}, "test"))
	assert_push_error("« catch_bonus » est réservé aux Balls")
	var negative := BALL.duplicate()
	negative["catch_bonus"] = -1
	var text := BALL.duplicate()
	text["catch_bonus"] = "1"
	assert_false(_library.add_from_dict({"a": negative, "b": text}, "test"))
	assert_push_error_count(3)
	assert_eq(_library.get_ids(), [&"great_ball"] as Array[StringName])


func test_duplicate_id_is_rejected() -> void:
	assert_true(_library.add_from_dict({"poke_ball": BALL}, "a.json"))
	assert_false(_library.add_from_dict({"poke_ball": BALL}, "b.json"))
	assert_push_error("déjà défini dans a.json")


func test_missing_dir_and_file() -> void:
	assert_false(_library.load_dir("res://tests/fixtures/items/missing/"))
	assert_false(_library.load_file("res://tests/fixtures/items/missing.json"))
	assert_push_error_count(2)
