extends GutTest
## Points d'origine des effets de combat (chantier Combat vivant, CV.A ; `docs/tech/combat-vivant.md`
## §2.2, CV-10) : `data/battle/fx_anchors.json`, écrit par `tools/art/fx_anchors.py`. Chaque espèce
## a ses points de face et de dos, posés sur l'image que le combat affiche vraiment.

const PATH := "res://data/battle/fx_anchors.json"
const POINTS: Array[String] = ["tete", "bouche", "yeux", "joues", "mains", "queue", "cornes",
	"canons", "bulbe", "centre"]
const PAIRS: Array[String] = ["yeux", "joues", "mains", "canons"]

var _art := BattleArt.new()


func _species() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_typeof(parsed, TYPE_DICTIONARY, "fichier lisible")
	return (parsed as Dictionary).get("species", {})


func test_all_151_species_are_listed() -> void:
	var species := _species()
	for dex: int in range(1, 152):
		assert_true(species.has("%03d" % dex), "%03d" % dex)


## Une vue décrit l'image affichée : si un dos est remplacé (lots DAF), ses points sont à refaire.
func test_each_view_matches_the_image_shown_in_battle() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var species := _species()
	for id: StringName in data.get_species_ids():
		var key := "%03d" % data.get_species(id).dex
		var entry: Dictionary = species[key]
		for back: bool in [false, true]:
			var texture: Texture2D = _art.image(id, back)["texture"]
			var view: Variant = entry["back" if back else "front"]
			if texture == null:
				assert_null(view, "%s : aucune image, aucun point" % key)
				continue
			# Repli d'un dos manquant sur l'artwork officiel : pas de points de dos à poser.
			if back and not texture.resource_path.contains("/dos/") \
					and not texture.resource_path.contains("/placeholder/"):
				assert_null(view, "%s : dos absent" % key)
				continue
			assert_not_null(view, "%s %s" % [key, "dos" if back else "face"])
			if view == null:
				continue
			# Face : l'artwork est affiché resserré (AtlasTexture sans chemin) ; on compare la
			# source. La boîte de la vue est en pixels de la source, avant ce recadrage.
			var shown := texture.resource_path if back \
				else PokedexArt.portrait_path(data.get_species(id).dex)
			assert_eq("res://" + str(view["image"]), shown, key)


func test_points_are_named_and_inside_the_box() -> void:
	var species := _species()
	for key: String in species:
		for side: String in ["front", "back"]:
			var view: Variant = species[key][side]
			if view == null:
				continue
			var points: Dictionary = view["points"]
			assert_true(points.has("tete"), "%s %s : tete" % [key, side])
			assert_true(points.has("centre"), "%s %s : centre" % [key, side])
			var box: Array = view["box"]
			var size: Array = view["size"]
			assert_true(box[0] + box[2] <= size[0] and box[1] + box[3] <= size[1], key)
			for name: String in points:
				assert_has(POINTS, name, "%s %s : %s" % [key, side, name])
				var value: Array = points[name]
				var list: Array = value if PAIRS.has(name) else [value]
				if PAIRS.has(name):
					assert_eq(list.size(), 2, "%s %s : %s par paire" % [key, side, name])
				for p: Array in list:
					assert_eq(p.size(), 2)
					for c: float in p:
						assert_between(c, -0.05, 1.05, "%s %s : %s" % [key, side, name])
