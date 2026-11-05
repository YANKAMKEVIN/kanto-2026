extends GutTest
## Art des Pokémon de Johto (fiche docs/design/fiches-assets/serie-johto-pokemon.md) : chaque
## espèce de Johto a son artwork, sa vignette, son dos peint et son cri ; aucune silhouette
## provisoire ne reste ; les Pokémon du monde (table d'Orme, compagnon, légendaires observés) sont
## peints ; les quatre objets d'évolution ont leur icône.

const JOHTO_FIRST_DEX: int = 152
## Pokémon de Johto posés dans le monde (`"sprite": "pokemon/<espèce>"`) : table d'Orme (JOH1),
## légendaires observés (JOH6, JOH7, JOH8).
const WORLD_SPECIES: Array[StringName] = [&"chikorita", &"cyndaquil", &"totodile", &"suicune",
	&"raikou", &"lugia", &"entei", &"ho_oh"]
## Compagnons de Johto : les trois de départ et leurs évolutions (Kevin, 2026-11-04).
const STARTERS: Array[StringName] = [&"chikorita", &"bayleef", &"meganium", &"cyndaquil", &"quilava",
	&"typhlosion", &"totodile", &"croconaw", &"feraligatr"]
const EVOLUTION_ITEMS: Array[StringName] = [&"kings_rock", &"metal_coat", &"dragon_scale",
	&"up_grade"]

var _data := PokemonData.new()
var _johto: Array[StringName] = []


func before_all() -> void:
	_data.load_dir()
	for id: StringName in _data.get_species_ids():
		if _data.get_species(id).dex >= JOHTO_FIRST_DEX:
			_johto.append(id)


func test_the_51_species_of_johto_are_covered() -> void:
	assert_eq(_johto.size(), 51)


func test_every_species_has_its_artwork_and_thumbnail() -> void:
	for id: StringName in _johto:
		var dex := _data.get_species(id).dex
		assert_true(PokedexArt.has_portrait(dex), "artwork de %s" % id)
		assert_true(PokedexArt.portrait_crop(dex).has_area(), "cadre de %s" % id)
		assert_not_null(PokedexArt.thumbnail(dex), "vignette de %s" % id)


func test_foe_is_the_official_artwork() -> void:
	var art := BattleArt.new()
	for id: StringName in _johto:
		var image := art.image(id, false)
		assert_true(image["official"], "%s : artwork" % id)
		var texture: Texture2D = image["texture"]
		assert_true(texture is AtlasTexture, "%s : artwork resserré" % id)


func test_every_species_has_a_painted_back() -> void:
	var art := BattleArt.new()
	for id: StringName in _johto:
		var path := BattleArt.best_painted_back_path(_data.get_species(id).dex)
		assert_ne(path, "", "dos peint de %s" % id)
		var texture: Texture2D = art.image(id, true)["texture"]
		assert_not_null(texture, "%s : dos" % id)
		if texture != null:
			assert_string_contains(texture.resource_path, "/dos/", "%s : dos peint lu" % id)


func test_no_placeholder_remains() -> void:
	for id: StringName in _johto:
		for back: bool in [false, true]:
			assert_false(ResourceLoader.exists(BattleArt.placeholder_path(id, back)),
				"silhouette provisoire restante : %s" % BattleArt.placeholder_path(id, back))


func test_every_species_has_its_cry() -> void:
	var library := AudioLibrary.new()
	library.load_dir()
	var cries := CryCatalog.new(library)
	for id: StringName in _johto:
		var path := cries.path_for_species(_data.get_species(id))
		assert_ne(path, "", "cri de %s" % id)
		assert_true(ResourceLoader.exists(path), "fichier du cri de %s : %s" % [id, path])


func test_world_pokemon_are_painted() -> void:
	for id: StringName in WORLD_SPECIES:
		var look := CharacterLook.resolve(StringName("pokemon/" + String(id)))
		assert_true(look.painted, "%s : peint dans le monde" % id)
		var frames := load(look.frames_path) as SpriteFrames
		assert_not_null(frames, "%s : SpriteFrames" % id)
		if frames != null:
			assert_true(frames.has_animation(&"idle_down"), "%s : attente de face" % id)


func test_the_starters_and_their_evolutions_walk_and_follow_the_hero() -> void:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/pokemon/companions.json"))
	var eligible: Dictionary = (parsed as Dictionary)["species"]
	for id: StringName in STARTERS:
		assert_true(eligible.has(String(id)), "%s : compagnon" % id)
		var frames := load(CharacterLook.resolve(StringName("pokemon/" + String(id))).frames_path) \
			as SpriteFrames
		for dir: String in ["down", "left", "right", "up"]:
			assert_true(frames.has_animation(StringName("walk_" + dir)), "%s : marche %s" % [id, dir])


func test_evolution_items_have_their_icon() -> void:
	for item: StringName in EVOLUTION_ITEMS:
		assert_not_null(MenuArt.item_icon(item), "icône de %s" % item)
