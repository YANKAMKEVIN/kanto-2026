extends GutTest
## Combat en surfant (fiche entree-dresseurs §13, demande de Kevin du 2026-11-03) : SurfStaging
## (décision pure), réglage des données (banc de sable par défaut tant que Kevin n'a pas choisi),
## images du joueur sur sa monture et des Nageurs dans l'eau, fonds des Routes 16 ouest et 18.

var _intros: TrainerIntroCatalog


func before_each() -> void:
	_intros = TrainerIntroCatalog.new()
	assert_true(_intros.load_file(), str(_intros.get_errors()))


## Catalogue de décors de test : la mer à pied et sa version en Surf, plus une route.
func _decors(enabled: bool) -> BattleDecorCatalog:
	var decor := {"size": [2340, 1080], "foe_feet": [1559, 560], "player_feet": [716, 972]}
	var catalog := BattleDecorCatalog.new()
	catalog.read({
		"surf": {"enabled": enabled, "decors": {"sea_open": "sea_surf"}},
		"decors": {
			"sea_open": decor.merged({"zone": "sea", "back": "res://a.webp"}),
			"sea_surf": decor.merged({"zone": "sea", "back": "res://b.webp"}),
			"route": decor.merged({"zone": "route", "back": "res://c.webp"}),
		},
		"places": {"route_19": [{"decor": "sea_open"}], "route_1": [{"decor": "route"}]},
	})
	return catalog


func _surf_id(decors: BattleDecorCatalog, map_id: StringName, surfing: bool, wild: bool,
		foe_class: StringName = &"") -> StringName:
	var decor := SurfStaging.surf_decor(decors, _intros, decors.pick(map_id, Vector2i.ZERO),
		surfing, wild, foe_class)
	return decor.id if decor != null else &""


func test_surf_staging_needs_the_setting() -> void:
	assert_eq(_surf_id(_decors(false), &"route_19", true, true), &"",
		"réglage faux : le banc de sable reste")
	assert_eq(_surf_id(_decors(true), &"route_19", true, true), &"sea_surf")


func test_surf_staging_needs_the_player_to_surf() -> void:
	assert_eq(_surf_id(_decors(true), &"route_19", false, true), &"", "à pied : banc de sable")
	assert_eq(_surf_id(_decors(true), &"route_1", true, true), &"",
		"décor sans remplaçant en Surf")


func test_only_swimmers_fight_in_open_water() -> void:
	var decors := _decors(true)
	assert_eq(_surf_id(decors, &"route_19", true, false, &"nageur"), &"sea_surf")
	assert_eq(_surf_id(decors, &"route_19", true, false, &"nageuse"), &"sea_surf")
	assert_eq(_surf_id(decors, &"route_19", true, false, &"pecheur"), &"",
		"Dresseur de la terre ferme : banc de sable")
	assert_eq(_surf_id(decors, &"route_19", true, false, &""), &"", "classe inconnue")


func test_surf_images_follow_the_suffix() -> void:
	var trainer := TrainerData.new()
	trainer.id = &"t"
	trainer.name = "Nageuse Léna"
	var intro := TrainerIntro.build(trainer, Party.new(), _intros)
	var all := func(_path: String) -> bool: return true
	assert_eq(intro.art_id(), &"nageuse", "à pied")
	intro.surf = true
	assert_eq(intro.art_id(), &"nageuse_surf")
	assert_eq(intro.front_path(all, true),
		"res://assets/sprites/trainers/battle/nageuse_surf_lancer.webp")
	assert_eq(intro.player_path(&"heroine", all),
		"res://assets/sprites/trainers/battle/dos_heroine_surf.webp")
	assert_lt(_intros.scale_of(intro.art_id()), _intros.scale_of(&"nageuse"),
		"dans l'eau, seul le haut du corps compte")
	trainer.name = "Pêcheur Yves"
	var fisher := TrainerIntro.build(trainer, Party.new(), _intros)
	fisher.surf = true
	assert_eq(fisher.art_id(), &"pecheur", "classe non peinte dans l'eau : images à pied")


# --- Données réelles -------------------------------------------------------------------

func test_real_setting_is_surf_and_keeps_the_sandbar() -> void:
	var decors := BattleDecorCatalog.load_file()
	assert_true(decors.surf_enabled, "Surf choisi par Kevin le 2026-11-03")
	var surf := decors.surf_decor_for(&"sea_open")
	assert_not_null(surf, "la mer a son décor en Surf")
	assert_eq(surf.id, &"sea_surf")
	assert_eq(decors.get_decor(&"sea_open").back_path,
		"res://assets/battle/decors/sea_open_v2_back.webp", "le banc de sable reste intact")


func test_real_surf_art_exists() -> void:
	var dir := _intros.front_dir
	for look: String in ["hero", "heroine"]:
		for suffix: String in ["", _intros.throw_suffix]:
			var path := dir + "dos_" + look + _intros.surf_suffix + suffix + _intros.extension
			assert_true(ResourceLoader.exists(path), path)
	for id: StringName in [&"nageur", &"nageuse"]:
		assert_true(_intros.has_surf_art(id), String(id))
		for suffix: String in ["", _intros.throw_suffix]:
			var path := dir + String(id) + _intros.surf_suffix + suffix + _intros.extension
			assert_true(ResourceLoader.exists(path), path)
	assert_false(_intros.has_surf_art(&"pecheur"))
	assert_between(_intros.surf_player_scale, 0.5, 1.2)


func test_cycling_road_routes_share_the_route_17_decor() -> void:
	var decors := BattleDecorCatalog.load_file()
	for map_id: StringName in [&"route_16_west", &"route_17", &"route_18"]:
		assert_eq(decors.default_for(map_id).id, &"route_17_cyclable", String(map_id))
	assert_eq(decors.pick(&"route_16_west", Vector2i(20, 5)).id, &"route_5_6_prairie",
		"hautes herbes de la voie haute")
	assert_eq(decors.pick(&"route_18", Vector2i(60, 6)).id, &"route_5_6_prairie",
		"hautes herbes à l'est du poste")
	assert_eq(decors.pick(&"route_18", Vector2i(20, 8)).id, &"route_17_cyclable", "la Piste")
