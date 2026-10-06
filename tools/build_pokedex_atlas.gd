extends SceneTree
## Construit l'atlas des vignettes du Pokédex (docs/tech/pokedex-refonte.md §2.2, §2.5) :
## assets/sprites/pokemon/official/atlas_128.png, depuis les 151 artworks NNN.png.
## Disposition lue dans PokedexArt (une seule source). Pour chaque artwork : recadrage à
## l'alpha + marge, réduction au grand côté THUMB_ART (Lanczos), centré dans sa case.
## Refuse un numéro manquant. Usage :
##   godot --headless --path . -s res://tools/build_pokedex_atlas.gd
## puis `godot --headless --path . --import`.


func _init() -> void:
	var art: GDScript = load("res://game/ui/menu/pokedex/pokedex_art.gd")
	var count: int = art.COUNT
	var thumb: int = art.THUMB
	var size: Vector2i = art.atlas_size()
	var atlas := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for number: int in range(1, count + 1):
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
	print("Atlas du Pokédex : %s (%d × %d, %d vignettes)" % [out, size.x, size.y, count])
	quit()
