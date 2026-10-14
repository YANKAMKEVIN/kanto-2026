extends GutTest
## Descriptions des capacités (data/pokemon/moves/*.json) : deux capacités différentes ne
## partagent jamais la même description, sauf exception listée ci-dessous. Garde-fou contre un
## texte recopié d'une autre capacité (signalement : Spore décrite comme Patience).

## Groupes de capacités autorisés à partager une description (aucun aujourd'hui). Exemple :
## [[&"move_a", &"move_b"]]. Chaque groupe doit couvrir toutes les capacités du doublon.
const SHARED_DESCRIPTIONS: Array = []

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func test_data_loads() -> void:
	assert_eq(_data.get_errors(), PackedStringArray())
	assert_gt(_data.get_move_ids().size(), 0)


func test_no_two_moves_share_a_description() -> void:
	var by_text: Dictionary[String, Array] = {}
	for id: StringName in _data.get_move_ids():
		var text := _data.get_move(id).description.strip_edges()
		if text.is_empty():
			continue
		if not by_text.has(text):
			by_text[text] = []
		by_text[text].append(id)
	var shared: PackedStringArray = []
	for text: String in by_text:
		var ids: Array = by_text[text]
		if ids.size() < 2 or _is_allowed(ids):
			continue
		ids.sort()
		shared.append("%s : « %s »" % [", ".join(ids), text])
	assert_eq(shared, PackedStringArray(), "descriptions partagées entre capacités")


func test_spore_is_not_described_as_bide() -> void:
	var spore := _data.get_move(&"spore")
	assert_not_null(spore)
	assert_ne(spore.description, _data.get_move(&"bide").description)
	assert_string_contains(spore.description, "spores")


func _is_allowed(ids: Array) -> bool:
	for group: Array in SHARED_DESCRIPTIONS:
		if ids.all(func(id: StringName) -> bool: return group.has(id)):
			return true
	return false
