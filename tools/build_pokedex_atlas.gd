extends SceneTree
## Construit l'atlas des vignettes du Pokédex (docs/tech/pokedex-refonte.md §2.2, §2.5) :
## assets/sprites/pokemon/official/atlas_128.png, depuis les artworks NNN.png de **chaque espèce
## des données** (`data/pokemon/species/*.json` : Kanto 1 à 151 et les 51 espèces de Johto) ; la
## case d'un numéro sans espèce reste vide.
## Disposition lue dans PokedexArt (une seule source). Pour chaque artwork : recadrage à
## l'alpha + marge, réduction au grand côté THUMB_ART (Lanczos), centré dans sa case.
## Écrit aussi le cadre utile de chaque artwork (boîte de l'alpha + marge, en pixels de la
## source) dans `crops.json` (PokedexArt.CROPS_PATH) : le grand portrait est resserré dessus.
## Refuse l'artwork manquant d'une espèce des données. Usage :
##   godot --headless --path . -s res://tools/build_pokedex_atlas.gd
## puis `godot --headless --path . --import`.


func _init() -> void:
	var art: GDScript = load("res://game/ui/menu/pokedex/pokedex_art.gd")
	var count: int = art.COUNT
	var thumb: int = art.THUMB
	var size: Vector2i = art.atlas_size()
	var atlas := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var crops: Dictionary = {}
	var numbers := _species_numbers()
	for number: int in numbers:
		if number < 1 or number > count:
			push_error("Atlas du Pokédex : numéro %d hors de 1..%d" % [number, count])
			quit(1)
			return
		var path: String = art.portrait_path(number)
		var source := Image.load_from_file(ProjectSettings.globalize_path(path))
		if source == null or source.is_empty():
			push_error("Atlas du Pokédex : artwork manquant %s" % path)
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		var used := source.get_used_rect()
		if used.size == Vector2i.ZERO:
			push_error("Atlas du Pokédex : artwork vide %s" % path)
			quit(1)
			return
		used = used.grow(art.THUMB_CROP_MARGIN).intersection(
			Rect2i(Vector2i.ZERO, source.get_size()))
		crops["%03d" % number] = [used.position.x, used.position.y, used.size.x, used.size.y]
		var cropped := source.get_region(used)
		# Couleurs étalées sous les pixels transparents : pas de liseré sombre à la réduction.
		cropped.fix_alpha_edges()
		var longest := maxi(used.size.x, used.size.y)
		var scaled := Vector2i((Vector2(used.size) * art.THUMB_ART / float(longest)).round())
		scaled = scaled.clamp(Vector2i.ONE, Vector2i.ONE * art.THUMB_ART)
		cropped.resize(scaled.x, scaled.y, Image.INTERPOLATE_LANCZOS)
		var region: Rect2 = art.thumb_region(number)
		var origin := Vector2i(region.position) + (Vector2i.ONE * thumb - scaled) / 2
		atlas.blit_rect(cropped, Rect2i(Vector2i.ZERO, scaled), origin)
	var out: String = ProjectSettings.globalize_path(art.ATLAS_PATH)
	var error := atlas.save_png(out)
	if error != OK:
		push_error("Atlas du Pokédex : écriture impossible (%s)" % error_string(error))
		quit(1)
		return
	var file := FileAccess.open(ProjectSettings.globalize_path(art.CROPS_PATH), FileAccess.WRITE)
	file.store_string(JSON.stringify({"_comment": "Cadre utile de chaque artwork [x, y, w, h] "
		+ "(boîte de l'alpha + marge), généré par tools/build_pokedex_atlas.gd.",
		"crops": crops}, "\t", true) + "\n")
	file.close()
	print("Atlas du Pokédex : %s (%d × %d, %d vignettes)" % [out, size.x, size.y, numbers.size()])
	quit()


## Numéros nationaux des espèces des données, triés, sans doublon.
func _species_numbers() -> Array[int]:
	var numbers: Array[int] = []
	var dir := "res://data/pokemon/species/"
	for file: String in DirAccess.get_files_at(dir):
		if not file.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + file))
		if not parsed is Dictionary:
			continue
		for entry: Variant in (parsed as Dictionary).values():
			if entry is Dictionary and (entry as Dictionary).has("dex"):
				var number := int((entry as Dictionary)["dex"])
				if not numbers.has(number):
					numbers.append(number)
	numbers.sort()
	return numbers
