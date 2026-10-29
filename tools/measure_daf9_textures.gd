extends SceneTree
## Mémoire des textures (RVBA 8 bits, sans mipmaps) des cartes du lot DAF.9 (Cramois'Île), chaque
## texture comptée une fois par groupe (dépendances des scènes, objets peints compris ; personnages
## exclus), contre le repère de 64 Mo par carte (RP-091). Même calcul que
## `measure_daf3_textures.gd`.
##
##   godot --headless --path . -s res://tools/measure_daf9_textures.gd
func _deps(path: String, seen: Dictionary, tex: Dictionary) -> void:
	if seen.has(path):
		return
	seen[path] = true
	for dep: String in ResourceLoader.get_dependencies(path):
		var p := dep.get_slice("::", 2) if dep.contains("::") else dep
		if p.begins_with("uid://"):
			p = ResourceUID.get_id_path(ResourceUID.text_to_id(p))
		if p.ends_with(".png") or p.ends_with(".webp"):
			var t: Texture2D = load(p)
			if t != null:
				tex[p] = t.get_width() * t.get_height() * 4
		elif p.ends_with(".tscn") or p.ends_with(".tres"):
			_deps(p, seen, tex)

func _init() -> void:
	var groups := {
		"Cramois'Île": ["cinnabar_island"],
		"Île + Centre + Boutique + Labo (voisines)": ["cinnabar_island", "cinnabar_center",
			"cinnabar_mart", "cinnabar_lab"],
		"Arène": ["cinnabar_gym"],
		"Manoir 1F": ["pokemon_mansion_1f"],
		"Manoir 2F": ["pokemon_mansion_2f"],
		"Manoir 3F": ["pokemon_mansion_3f"],
		"Manoir B1F": ["pokemon_mansion_b1f"],
		"Manoir entier (4 niveaux)": ["pokemon_mansion_1f", "pokemon_mansion_2f",
			"pokemon_mansion_3f", "pokemon_mansion_b1f"],
	}
	for g in groups:
		var seen := {}
		var tex := {}
		for m in groups[g]:
			_deps("res://game/world/maps/%s.tscn" % m, seen, tex)
		var total := 0
		for p in tex:
			total += tex[p]
		print("%s : %.1f Mo (%d textures)" % [g, total / 1048576.0, tex.size()])
	quit()
