extends GutTest
## BattleArt (CB.1) : adversaire en artwork officiel par numéro du Pokédex, dos du joueur en
## sprite provisoire, taille réelle lue dans le Pokédex ; pour **toutes** les espèces des
## données, les deux côtés tiennent dans l'écran, hors des zones de l'interface, à 1920 et à
## 2340 de large.

const VIEWS: Array[Vector2] = [Vector2(1920, 1080), Vector2(2340, 1080)]
## Espèces des données jamais affichées au J19 : Osselait et Ossatueur n'apparaissent qu'en
## SPECTRE (silhouette), sans image propre (jalon-19.md §2.12) ; leur art arrive au J20 / J21.
const NEVER_SHOWN: Array[StringName] = [&"cubone", &"marowak"]

var _art := BattleArt.new()


func test_foe_is_the_official_artwork_by_dex_number() -> void:
	var image := _art.image(&"pidgey", false)
	assert_true(image["official"])
	var texture: Texture2D = image["texture"]
	assert_true(texture is AtlasTexture, "resserré sur le cadre utile (PokedexArt)")
	assert_string_ends_with((texture as AtlasTexture).atlas.resource_path, "official/016.png")
	var box: Rect2 = image["box"]
	assert_true(Rect2(Vector2.ZERO, texture.get_size()).encloses(box), "boîte dans l'image")
	assert_gt(box.size.y, 300.0, "artwork HD")


func test_player_side_keeps_the_placeholder_back() -> void:
	var image := _art.image(&"charmander", true)
	assert_false(image["official"])
	assert_eq((image["texture"] as Texture2D).resource_path,
		BattleArt.placeholder_path(&"charmander", true))
	assert_eq(image["box"], Rect2(14, 7, 48, 56), "boîte de l'alpha, pieds au bas")


## Correctif QA 12A (Reptincel sans dos sur le S24) : **chaque** espèce des données a son sprite
## provisoire de face et de dos. Le test d'avant (`test_battle_stage.gd`) ne partait que des
## rencontres de trois cartes et des équipes de Dresseurs : une évolution (Herbizarre,
## Reptincel, Carabaffe…) n'y figurait pas. Toute espèce des données peut finir chez le joueur
## (rencontre, cadeau, évolution) : la règle est donc « toutes », et chaque évolution vise une
## espèce des données (la chaîne est couverte jusqu'au bout).
func test_every_species_of_the_data_has_its_front_and_back() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var ids := data.get_species_ids()
	assert_gt(ids.size(), 40)
	for id: StringName in ids:
		if NEVER_SHOWN.has(id):
			continue
		for back: bool in [false, true]:
			var path := BattleArt.placeholder_path(id, back)
			assert_true(ResourceLoader.exists(path), "sprite provisoire %s" % path)
		for rule: EvolutionRule in data.get_species(id).evolutions:
			assert_true(data.has_species(rule.into), "%s évolue en %s : espèce des données"
				% [id, rule.into])


## Repli : une espèce sans sprite de dos montre son artwork officiel, jamais un côté vide.
func test_a_missing_back_falls_back_to_the_official_artwork() -> void:
	var file := FileAccess.open("res://data/pokemon/species/kanto.json", FileAccess.READ)
	var entries: Dictionary = JSON.parse_string(file.get_as_text())
	var data := PokemonData.new()
	assert_true(data.add_species_from_dict({"zz_no_sprite": entries["charmeleon"]}))
	var art := BattleArt.new()
	art.setup(data, null)
	assert_false(ResourceLoader.exists(BattleArt.placeholder_path(&"zz_no_sprite", true)))
	var image := art.image(&"zz_no_sprite", true)
	assert_not_null(image["texture"], "jamais vide")
	assert_true(image["official"], "artwork officiel")
	assert_string_ends_with(((image["texture"] as AtlasTexture).atlas).resource_path,
		"official/005.png")


func test_unknown_species_has_no_texture_and_reference_height() -> void:
	var image := _art.image(&"missingno", false)
	assert_null(image["texture"])
	assert_eq(_art.dex_number(&"missingno"), 0)
	assert_eq(_art.height_m(&"missingno"), BattleLayout.REFERENCE_HEIGHT_M)


func test_heights_and_numbers_come_from_the_data() -> void:
	assert_eq(_art.dex_number(&"charmander"), 4)
	assert_eq(_art.height_m(&"charmander"), 0.6)
	assert_eq(_art.height_m(&"pidgey"), 0.3)
	assert_eq(_art.height_m(&"venusaur"), 2.0)


func test_setup_uses_the_given_libraries() -> void:
	var dex := PokedexLibrary.new()
	dex.add_from_dict({"size": 151, "species": {"pidgey": {"height": 1.5, "weight": 1.0,
		"description": "x"}}})
	var art := BattleArt.new()
	art.setup(null, dex)
	assert_eq(art.height_m(&"pidgey"), 1.5)
	assert_eq(art.height_m(&"rattata"), BattleLayout.REFERENCE_HEIGHT_M, "absent : référence")


## Toutes les espèces des données, des deux côtés : dans l'écran, hors de l'interface, et
## l'adversaire jamais plus grand que sa boîte maximale.
func test_every_species_fits_the_framing() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var dex := PokedexLibrary.new()
	dex.load_file()
	_art.setup(data, dex)
	for species: StringName in dex.get_species_ids():
		for back: bool in [true, false]:
			var image := _art.image(species, back)
			var box: Rect2 = image["box"]
			for view: Vector2 in VIEWS:
				var key := "player_feet" if back else "foe_feet"
				var feet: Vector2 = BattleLayout.anchors(view)[key]
				var scale := BattleLayout.sprite_scale(box.size, _art.height_m(species), back,
					view.y, not image["official"])
				var rect := BattleLayout.sprite_rect(feet, scale, box.size)
				var where := "%s %s %s" % [species, "dos" if back else "face", view]
				assert_true(BattleLayout.max_rect(back, view).grow(0.5).encloses(rect), where)
				for zone: Rect2 in BattleLayout.hud_zones(view):
					assert_false(rect.intersects(zone), "%s hors de %s" % [where, zone])
