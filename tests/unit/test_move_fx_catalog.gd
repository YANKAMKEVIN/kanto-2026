extends GutTest
## Effets d'attaques (chantier Combat vivant, CV.0 T1 ; `docs/tech/combat-vivant.md` §2.2,
## annexe A) : `data/battle/move_fx/`, une entrée par attaque, repli par type et catégorie.

const ANNEX_COUNT: int = 165
## JOH0 (T6) : les 47 attaques d'Or/Argent de data/battle/move_fx/johto.json.
const JOHTO_COUNT: int = 47
const FAMILIES: Array[StringName] = [&"contact", &"feu", &"eau", &"electrique", &"plante",
	&"glace", &"psy", &"poison", &"sol_roche", &"vent", &"spectre", &"dragon", &"energie", &"son",
	&"statut_plus", &"statut_moins", &"statut_regard", &"statut_sable", &"soin",
	&"statut_geste", &"fouet", &"bulles", &"statut_fil", &"dard", &"poudre", &"graine",
	&"chute_pierres", &"teleport", &"trempette", &"explosion", &"fumee", &"gaz", &"flash",
	&"cuiller", &"etoiles", &"foudre", &"poing", &"os", &"onde_folie", &"brume", &"lancer",
	&"atlas", &"fissure", &"tunnel", &"cage_eclair", &"charge_electrique", &"elecanon",
	&"danse_flamme", &"roue_feu", &"feu_sacre", &"zenith", &"surf", &"repli", &"danse_pluie",
	&"rafale_psy", &"vague_psy", &"devoreve", &"prescience", &"hypnose", &"hate", &"repos",
	&"bouclier", &"protection", &"mur_lumiere", &"voile_miroir"]
## Vague 1 « Effets fidèles à Rouge » (2026-11-02) : attaque → [famille, variante, brique de
## trajet, brique de lancement].
const ROUGE_WAVE_1: Dictionary = {
	&"tail_whip": [&"statut_geste", &"", "", "tail_wag"],
	&"vine_whip": [&"fouet", &"", "whip", "rear_back"],
	&"bubble": [&"bulles", &"ecume", "bubbles", "bubble_swell"],
	&"bubble_beam": [&"bulles", &"rafale", "bubbles", "bubble_swell"],
	&"string_shot": [&"statut_fil", &"", "string", "rear_back"],
	&"poison_sting": [&"dard", &"", "needle", "rear_back"],
	&"sleep_powder": [&"poudre", &"dodo", "powder_fall", "powder_shake"],
	&"stun_spore": [&"poudre", &"para", "powder_fall", "powder_shake"],
	&"poison_powder": [&"poudre", &"toxik", "powder_fall", "powder_shake"],
	&"spore": [&"poudre", &"spore", "powder_fall", "powder_shake"],
	&"leech_seed": [&"graine", &"", "seed_arc", "rear_back"],
}
## Vague 2 « Effets fidèles à Rouge » (2026-11-04) : attaque → [famille, variante, variante
## d'impact, brique de trajet].
const ROUGE_WAVE_2: Dictionary = {
	&"twineedle": [&"dard", &"double", &"", "needle"],
	&"pin_missile": [&"dard", &"nuee", &"", "needle"],
	&"spike_cannon": [&"dard", &"picanon", &"", "needle"],
	&"rock_throw": [&"chute_pierres", &"", &"", "rockfall"],
	&"rock_slide": [&"chute_pierres", &"eboulement", &"", "rockfall"],
	&"teleport": [&"teleport", &"", &"", ""],
	&"splash": [&"trempette", &"", &"", ""],
	&"explosion": [&"explosion", &"", &"", ""],
	&"self_destruct": [&"explosion", &"destruction", &"", ""],
	&"pay_day": [&"contact", &"", &"pieces", "dash"],
	&"smokescreen": [&"fumee", &"", &"", "smoke_ball"],
	&"poison_gas": [&"gaz", &"", &"", "gas_drift"],
	&"smog": [&"gaz", &"smog", &"", "gas_drift"],
	&"flash": [&"flash", &"", &"", ""],
	&"kinesis": [&"cuiller", &"", &"", ""],
	&"swift": [&"etoiles", &"", &"", "stars"],
	&"thunder": [&"foudre", &"", &"", "sky_bolt"],
	&"fire_punch": [&"poing", &"feu", &"poing", "dash"],
	&"ice_punch": [&"poing", &"glace", &"poing", "dash"],
	&"thunder_punch": [&"poing", &"eclair", &"poing", "dash"],
	&"lick": [&"contact", &"", &"langue", "dash"],
	&"bone_club": [&"os", &"massue", &"", "bone"],
	&"bonemerang": [&"os", &"boomerang", &"", "bone"],
	&"confuse_ray": [&"onde_folie", &"", &"", "strange_orb"],
	&"haze": [&"brume", &"", &"", ""],
	&"clamp": [&"contact", &"", &"claquoir", "dash"],
	&"crabhammer": [&"contact", &"", &"pince_masse", "dash"],
	&"waterfall": [&"contact", &"", &"cascade", "dash"],
	&"egg_bomb": [&"lancer", &"oeuf", &"", "lob"],
	&"barrage": [&"lancer", &"pilonnage", &"", "lob"],
	&"seismic_toss": [&"atlas", &"", &"atlas", "dash"],
	&"fissure": [&"fissure", &"", &"", ""],
	&"dig": [&"tunnel", &"", &"", "underground"],
}

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


func test_every_family_exists() -> void:
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
	assert_eq(MoveFxCatalog.load_dir().move_ids().size(), ANNEX_COUNT + JOHTO_COUNT)


## 13 signatures sur 14 attaques (Flammèche ajoutée par la refonte Feu ; Surf devenu une famille
## par la refonte Eau).
func test_13_signatures_on_14_moves() -> void:
	var catalog := MoveFxCatalog.load_dir()
	assert_eq(catalog.signature_ids().size(), 13)
	var signed: Array[StringName] = []
	for move_id: StringName in catalog.move_ids():
		if not catalog.entry(move_id).signature.is_empty():
			signed.append(move_id)
	assert_eq(signed.size(), 14, "Explosion et Destruction partagent la leur")
	assert_eq(catalog.entry(&"thunder_shock").signature, &"eclair")
	assert_eq(catalog.entry(&"ember").signature, &"flammeche")
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


## RP-286 (décision de Kevin du 2026-11-01) : regard ou geste sur le lanceur, puis l'aura sur la
## cible, sans trajet ; le trajet reste pour Jet de Sable (une gerbe de sable, remarque de Kevin
## du 2026-11-02) et Sécrétion (son trajet d'origine).
func test_gaze_moves_have_no_travel_but_sand_and_string_keep_it() -> void:
	var catalog := MoveFxCatalog.load_dir()
	for move_id: StringName in [&"leer", &"glare", &"tail_whip", &"disable"]:
		var family := catalog.family(catalog.entry(move_id).family)
		var bricks: Dictionary = family.get("bricks", {})
		assert_eq(String(bricks.get("travel", "")), "", "%s : pas de trajet" % move_id)
		assert_false((family.get("fx", {}) as Dictionary).get("art", {}).has("travel"),
			"%s : pas d'art de trajet" % move_id)
		assert_eq(String(bricks.get("impact", "")), "falling_aura", "%s : aura sur la cible" % move_id)
		assert_ne(String(family.get("target", "")), "self", "%s : vise l'adversaire" % move_id)
	var sand := catalog.family(catalog.entry(&"sand_attack").family)
	assert_eq(String((sand.get("bricks", {}) as Dictionary).get("travel", "")), "sand_spray",
		"Jet de Sable : une gerbe de grains")
	var sand_art: Dictionary = (sand.get("fx", {}) as Dictionary).get("art", {})
	assert_false(sand_art.has("travel"), "Jet de Sable : pas de projectile peint")
	assert_eq(String(sand_art.get("spray", "")), "grain_sable", "Jet de Sable : grains de sable")
	var string_shot: Dictionary = catalog.family(catalog.entry(&"string_shot").family).get("bricks", {})
	assert_eq(String(string_shot.get("travel", "")), "string", "Sécrétion : des fils (vague 1)")


## Vague 1 « Effets fidèles à Rouge » : chaque attaque est rangée dans sa famille (et sa
## variante), avec ses briques ; aucune ne part plus en lueur (ni art de trajet `lueur_douce`, ni
## projectile rond par défaut : son trajet est une brique propre ou vide).
func test_rouge_wave_1_moves_have_their_family_and_bricks() -> void:
	var catalog := MoveFxCatalog.load_dir()
	for move_id: StringName in ROUGE_WAVE_1:
		var expected: Array = ROUGE_WAVE_1[move_id]
		var entry := catalog.entry(move_id)
		assert_false(entry.fallback, "%s : dans les données" % move_id)
		assert_eq(entry.family, expected[0], "%s : famille" % move_id)
		assert_eq(entry.variant, expected[1], "%s : variante" % move_id)
		var family := catalog.family(entry.family)
		var bricks: Dictionary = family.get("bricks", {})
		assert_eq(String(bricks.get("travel", "")), expected[2], "%s : trajet" % move_id)
		assert_eq(String(bricks.get("launch", "")), expected[3], "%s : lancement" % move_id)
		var art := JsonFields.get_dict(catalog.family_fx(entry.family, entry.variant), "art")
		assert_false(art.has("travel"), "%s : pas de projectile peint" % move_id)
		assert_false(art.values().has("lueur_douce"), "%s : pas de lueur" % move_id)
		assert_false(art.has("charge") and art["charge"] == "oeil_menacant",
			"%s : pas d'œil" % move_id)
	for move_id: StringName in [&"peck", &"drill_peck"]:
		var entry := catalog.entry(move_id)
		assert_eq(entry.family, &"contact", "%s : au contact" % move_id)
	assert_eq(catalog.entry(&"peck").impact, &"bec", "Picpic : coups de bec")
	assert_eq(catalog.entry(&"drill_peck").impact, &"vrille", "Bec Vrille : en vrille")
	assert_eq(JsonFields.get_int(catalog.impact(&"bec"), "beats"), 2, "deux coups de bec")


## Variante de famille : ses réglages `fx` remplacent ceux de la famille, l'art est fusionné.
func test_variant_overrides_family_fx() -> void:
	var catalog := MoveFxCatalog.load_dir()
	var base := catalog.family_fx(&"bulles")
	var rafale := catalog.family_fx(&"bulles", &"rafale")
	assert_gt(int(rafale["volley"]["count"]), int(base["volley"]["count"]), "Bulles d'O : plus")
	assert_lt(float(rafale["volley"]["stagger"]), float(base["volley"]["stagger"]), "plus serrées")
	assert_eq(rafale["art"], base["art"], "même art")
	var spore := catalog.family_fx(&"poudre", &"spore")
	assert_eq(String(spore["art"]["powder"]), "spore", "grains peints de Spore")
	assert_eq(String(spore["art"]["sparkle"]), "etincelle", "art de la famille gardé")
	var colors: Dictionary = {}
	for variant: StringName in [&"dodo", &"para", &"toxik", &"spore"]:
		colors[String(catalog.family_fx(&"poudre", variant)["palette"][1])] = variant
	assert_eq(colors.size(), 4, "une couleur par poudre")


## Vague 2 « Effets fidèles à Rouge » (2026-11-04) : les 22 lignes de l'audit (33 attaques)
## dans leur famille, leur variante et leurs briques ; aucune ne garde la famille qui trahissait
## sa nature (Contact pour des aiguilles tirées, rayon d'énergie pour Météores ou Explosion…).
func test_rouge_wave_2_moves_have_their_family_and_bricks() -> void:
	var catalog := MoveFxCatalog.load_dir()
	for move_id: StringName in ROUGE_WAVE_2:
		var expected: Array = ROUGE_WAVE_2[move_id]
		var entry := catalog.entry(move_id)
		assert_false(entry.fallback, "%s : dans les données" % move_id)
		assert_eq(entry.family, expected[0], "%s : famille" % move_id)
		assert_eq(entry.variant, expected[1], "%s : variante" % move_id)
		assert_eq(entry.impact, expected[2], "%s : variante d'impact" % move_id)
		var bricks: Dictionary = catalog.family(entry.family).get("bricks", {})
		assert_eq(String(bricks.get("travel", "")), expected[3], "%s : trajet" % move_id)
		var art := JsonFields.get_dict(catalog.family_fx(entry.family, entry.variant), "art")
		assert_false(art.has("travel"), "%s : pas de projectile peint générique" % move_id)
		assert_false(art.values().has("lueur_douce"), "%s : pas de lueur" % move_id)
	for move_id: StringName in [&"twineedle", &"pin_missile", &"spike_cannon", &"bonemerang",
			&"barrage"]:
		assert_true(catalog.entry(move_id).has_modifier(&"multi"), "%s : coups multiples" % move_id)
	assert_eq(JsonFields.get_id(catalog.signature(&"fatal_foudre"), "base"), &"foudre",
		"Fatal-Foudre : la signature tombe du ciel")
	assert_eq(JsonFields.get_id(catalog.signature(&"explosion"), "base"), &"explosion",
		"Explosion : sans rayon")
	assert_true(JsonFields.get_bool(catalog.family(&"teleport"), "vanish"), "Téléport : il part")


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
		"f": {"family": "feu", "variant": "bleue"},
	}}])
	assert_false(catalog.validate())
	assert_eq(catalog.get_errors().size(), 6, "\n".join(catalog.get_errors()))


func test_comment_keys_are_ignored() -> void:
	var catalog := _catalog_with([{"moves": {"_doc": "x", "ember": {"family": "feu"}}}])
	assert_true(catalog.validate())
	assert_eq(catalog.move_ids(), [&"ember"] as Array[StringName])
