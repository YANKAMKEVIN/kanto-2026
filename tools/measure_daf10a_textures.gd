extends SceneTree
## Mémoire des textures (RVBA 8 bits, sans mipmaps) des cartes du lot DAF.10a (Parmanie et Parc Safari), chaque
## texture comptée une fois par groupe (dépendances des scènes, objets peints compris ; personnages
## exclus), contre le repère de 64 Mo par carte (RP-091). Même calcul que
## `measure_daf3_textures.gd`.
##
##   godot --headless --path . -s res://tools/measure_daf10a_textures.gd
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
		"Parmanie": ["fuchsia_city"],
		"Parmanie + Centre + Boutique + Salle + 3 maisons + Arène": ["fuchsia_city", "fuchsia_center",
			"fuchsia_mart", "fuchsia_meeting_room", "fuchsia_good_rod_house", "fuchsia_grandpa_house",
			"fuchsia_gym"],
		"Arène de Parmanie": ["fuchsia_gym"],
		"Parc Centre": ["safari_zone_center"],
		"Parc Nord": ["safari_zone_north"],
		"Parc Est": ["safari_zone_east"],
		"Parc Ouest": ["safari_zone_west"],
		"Porte du Parc": ["safari_zone_gate"],
		"Maison de repos": ["safari_zone_rest_house_center"],
		"Maison Secrète": ["safari_zone_secret_house"],
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
