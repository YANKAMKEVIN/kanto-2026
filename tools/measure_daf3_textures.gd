extends SceneTree
## Mémoire des textures (RVBA 8 bits, sans mipmaps) des cartes du lot DAF.3 / DAF.4, chaque texture
## comptée une fois par groupe (dépendances des scènes, objets peints compris ; personnages exclus).
## RP-143 : la Sylphe entière (11 étages + cabine) contre le budget de 64 Mo « carte + voisines ».
##
##   godot --headless --path . -s res://tools/measure_daf3_textures.gd
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
		"7F seul": ["silph_co_7f"],
		"Sylphe entière (11 étages + cabine)": [],
		"Arène de Morgane": ["saffron_gym"],
		"Dojo": ["fighting_dojo"],
		"Arène de Jadielle": ["viridian_gym"],
		"Safrania": ["saffron_city"],
	}
	for n in range(1, 12):
		groups["Sylphe entière (11 étages + cabine)"].append("silph_co_%df" % n)
	groups["Sylphe entière (11 étages + cabine)"].append("silph_co_elevator")
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
