extends GutTest
## Effets d'attaques (chantier Combat vivant, CV.0 T1 ; `docs/tech/combat-vivant.md` §2.2,
## annexe A) : `data/battle/move_fx/`, une entrée par attaque, repli par type et catégorie.

const ANNEX_COUNT: int = 165
const FAMILIES: Array[StringName] = [&"contact", &"feu", &"eau", &"electrique", &"plante",
	&"glace", &"psy", &"poison", &"sol_roche", &"vent", &"spectre", &"dragon", &"energie", &"son",
	&"statut_plus", &"statut_moins", &"soin"]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _families_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(
		MoveFxCatalog.DEFAULT_DIR.path_join(MoveFxCatalog.FAMILIES_FILE)))


func _catalog_with(moves_files: Array[Dictionary]) -> MoveFxCatalog:
	var catalog := MoveFxCatalog.new()
	catalog.read_families(_families_data())
	for i: int in moves_files.size():
		catalog.add_moves(moves_files[i], "lot_%d.json" % i)
	return catalog


# --- Données réelles ------------------------------------------------------------------

func test_real_catalog_has_no_error() -> void:
	var catalog := MoveFxCatalog.load_dir()
	assert_eq(catalog.get_errors(), PackedStringArray(), "\n".join(catalog.get_errors()))


func test_the_17_families_exist() -> void:
	var catalog := MoveFxCatalog.load_dir()
	assert_eq(catalog.family_ids().size(), FAMILIES.size())
	for family: StringName in FAMILIES:
		assert_false(catalog.family(family).is_empty(), String(family))


## Toute attaque des données a une entrée (une seule : un doublon est une erreur, testé plus haut).
func test_every_move_of_the_data_has_an_entry() -> void:
	var catalog := MoveFxCatalog.load_dir()
	for move_id: StringName in _data.get_move_ids():
		assert_true(catalog.has_entry(move_id), "%s : entrée dans data/battle/move_fx/" % move_id)


func test_the_165_moves_of_the_annex_are_listed() -> void:
	assert_eq(MoveFxCatalog.load_dir().move_ids().size(), ANNEX_COUNT)


func test_13_signatures_on_14_moves() -> void:
	var catalog := MoveFxCatalog.load_dir()
	assert_eq(catalog.signature_ids().size(), 13)
	var signed: Array[StringName] = []
	for move_id: StringName in catalog.move_ids():
		if not catalog.entry(move_id).signature.is_empty():
			signed.append(move_id)
	assert_eq(signed.size(), 14, "Explosion et Destruction partagent la leur")
	assert_eq(catalog.entry(&"thunder_shock").signature, &"eclair")
	assert_eq(catalog.entry(&"self_destruct").signature, catalog.entry(&"explosion").signature)


func test_examples_of_the_annex() -> void:
	var catalog := MoveFxCatalog.load_dir()
	var tackle := catalog.entry(&"tackle")
	assert_eq(tackle.family, &"contact")
	assert_eq(tackle.impact, &"corps")
	assert_false(tackle.fallback)
	assert_eq(catalog.entry(&"absorb").modifiers, [&"drain"] as Array[StringName])
	assert_eq(catalog.entry(&"bite").impact, &"crocs")
	assert_true(catalog.entry(&"barrage").has_modifier(&"multi"))
	assert_eq(catalog.entry(&"thunder_shock").family, &"electrique")


func test_camera_of_every_family_within_cv3_ceilings() -> void:
	var catalog := MoveFxCatalog.load_dir()
	for family: StringName in catalog.family_ids():
		var camera: Dictionary = catalog.family(family).get("camera", {})
		assert_lte(float(camera.get("zoom", 1.0)), 1.06, String(family))
		assert_lte(float(camera.get("shake", 0.0)), 6.0, String(family))


func test_phases_of_every_family_sum_to_one() -> void:
	var catalog := MoveFxCatalog.load_dir()
	for family: StringName in catalog.family_ids():
		var sum := 0.0
		for part: float in (catalog.family(family).get("phases", {}) as Dictionary).values():
			sum += part
		assert_almost_eq(sum, 1.0, 0.001, String(family))


# --- Repli ------------------------------------------------------------------------------

func test_fallback_by_type_and_category() -> void:
	var catalog := MoveFxCatalog.load_dir()
	var fire := catalog.entry(&"new_fire_move", &"fire", &"special")
	assert_true(fire.fallback)
	assert_eq(fire.family, &"feu")
	assert_eq(catalog.entry(&"x", &"normal", &"physical").family, &"contact")
	assert_eq(catalog.entry(&"x", &"normal", &"physical").impact, &"coup",
		"un contact de repli a une variante d'impact")
	assert_eq(catalog.entry(&"x", &"normal", &"special").family, &"energie")
	assert_eq(catalog.entry(&"x", &"fire", &"status").family, &"statut_moins",
		"une capacité de statut ne prend pas la famille de son type")
	assert_eq(catalog.entry(&"x", &"unknown_type", &"special").family, &"energie")
	assert_eq(catalog.entry(&"x", &"", &"").family, &"contact", "dernier recours")


func test_fallback_does_not_hide_a_real_entry() -> void:
	var catalog := MoveFxCatalog.load_dir()
	assert_eq(catalog.entry(&"tackle", &"fire", &"special").family, &"contact")


# --- Validation ---------------------------------------------------------------------------

func test_a_move_in_two_files_is_an_error() -> void:
	var catalog := _catalog_with([
		{"moves": {"tackle": {"family": "contact", "impact": "corps"}}},
		{"moves": {"tackle": {"family": "feu"}}},
	])
	assert_eq(catalog.get_errors().size(), 1)
	assert_eq(catalog.entry(&"tackle").family, &"contact", "la première lue est gardée")
	assert_eq(catalog.entry(&"tackle").source, "lot_0.json")


func test_unknown_references_are_errors() -> void:
	var catalog := _catalog_with([{"moves": {
		"a": {"family": "laser"},
		"b": {"family": "contact"},
		"c": {"family": "feu", "modifiers": ["spin"]},
		"d": {"family": "feu", "signature": "eclair"},
		"e": {"family": "contact", "impact": "gifle"},
	}}])
	assert_false(catalog.validate())
	assert_eq(catalog.get_errors().size(), 5, "\n".join(catalog.get_errors()))


func test_comment_keys_are_ignored() -> void:
	var catalog := _catalog_with([{"moves": {"_doc": "x", "ember": {"family": "feu"}}}])
	assert_true(catalog.validate())
	assert_eq(catalog.move_ids(), [&"ember"] as Array[StringName])
