extends GutTest
## Combat vivant (CV.0, T8) : départ de débogage « fx_gallery » (galerie d'effets à la place de la
## partie) lu par DebugStart ; mode invalide refusé ; liste par défaut de la galerie (une attaque
## par famille, les attaques de CV.0 d'abord).

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_gallery_starts_are_read() -> void:
	for case: Array in [["fx_gallery", "full"], ["fx_gallery_fast", "fast"]]:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % case[0], _data, _items),
			str(start.get_errors()))
		assert_eq(start.fx_gallery.get("mode"), case[1])
		assert_true(start.map.is_empty(), "pas de carte : la galerie remplace la partie")


func test_bad_gallery_is_refused() -> void:
	var party := [{"species": "pikachu", "level": 5}]
	var start := DebugStart.new()
	assert_false(start.add_from_dict({"party": party, "fx_gallery": {"mode": "slow"}}, _data,
		_items, "test"))
	assert_false(start.add_from_dict({"party": party, "fx_gallery": {"moves": "ember"}}, _data,
		_items, "test"))
	assert_push_error_count(2, "une erreur par réglage invalide")
	assert_true(start.add_from_dict({"party": party, "fx_gallery": {"moves": ["ember"]}}, _data,
		_items, "test"), str(start.get_errors()))
	assert_eq(start.fx_gallery.get("moves"), ["ember"])
