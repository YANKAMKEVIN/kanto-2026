extends GutTest
## Coque partagée des maisons d'Argenta : son paillasson peint (6..8, 9) fait
## croire à une sortie. Un étage qui l'utilise sans sortie sur ce paillasson
## doit le recouvrir par le mur sud sans porte (`ShellSouthWall`).

const COQUE := "res://assets/world/interiors/int_maison_argenta_coque.png"
const MUR_SUD := "res://assets/world/interiors/int_maison_argenta_mur_sud_sans_porte.png"
const MAPS_DIR := "res://game/world/maps/"
const SORTIES := [Vector2(624, 864), Vector2(720, 864), Vector2(816, 864)]


func _maps_avec_coque() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(MAPS_DIR):
		if f.ends_with(".tscn") and FileAccess.get_file_as_string(MAPS_DIR + f).contains(COQUE):
			out.append(MAPS_DIR + f)
	return out


func _a_sortie_sur_paillasson(root: Node) -> bool:
	var warps := root.get_node_or_null("Warps")
	if warps == null:
		return false
	for w in warps.get_children():
		if w is Node2D and SORTIES.has((w as Node2D).position) and str(w.get("target_map")) != "":
			return true
	return false


func test_paillasson_sans_sortie_recouvert() -> void:
	var maps := _maps_avec_coque()
	assert_gt(maps.size(), 20, "les maisons au gabarit d'Argenta sont trouvées")
	var sans_sortie := 0
	for path in maps:
		var root := (load(path) as PackedScene).instantiate()
		if not _a_sortie_sur_paillasson(root):
			sans_sortie += 1
			var mur := root.get_node_or_null("ShellSouthWall") as Sprite2D
			assert_not_null(mur, "%s : paillasson peint sans sortie, mur sud manquant" % path)
			if mur != null:
				assert_eq(mur.texture.resource_path, MUR_SUD, path)
		root.free()
	assert_gte(sans_sortie, 3, "poste de la Route 12, chambre du Copieur, salle du Centre d'Oliville")
