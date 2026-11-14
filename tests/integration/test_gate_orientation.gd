extends GutTest
## Sens des grilles, herses et barrières (audit du 2026-11-14, après les grilles du Manoir) :
## une barrière **vue de face** ferme un couloir nord-sud, entre deux murs à l'ouest et à l'est ;
## une barrière **de profil** ferme un passage est-ouest, dans un mur nord-sud. Un dessin de face
## posé dans un mur nord-sud (le défaut trouvé par Kevin au Manoir Pokémon) se lit à l'envers.
##
## Pour chaque [FlagGate] dessinée avec une de ces images, on retrouve le bloc de cases bloquées
## de sa barrière (cases des portes du même préfixe de nom, reliées à la case du pied du dessin),
## puis on regarde les murs autour du bloc.

const MAPS_DIR := "res://game/world/maps/"
const PROPS := "res://assets/world/props/"
## Images vues de face.
const FRONT: Array[String] = [
	"int_grille_manoir_fermee_01.png",
	"int_grille_manoir_ouverte_01.png",
	"int_herse_fermee_01.png",
	"int_herse_ouverte_01.png",
	"prop_barriere_victoire_01.png",
	"prop_barriere_croisillon_01.png",
	"prop_barriere_ouverte_01.png",
	"prop_porte_condamnee_01.png",
	"prop_porte_nord_01.png",
	"hideout_office_door.png",
	"int_porte_ascenseur_repaire_01.png",
]
## Images de profil.
const SIDE: Array[String] = [
	"int_grille_manoir_fermee_cote_01.png",
	"int_grille_manoir_ouverte_cote_01.png",
	"int_porte_sylphe_v_01.png",
]


func _gate_maps() -> Array[String]:
	var out: Array[String] = []
	for file: String in DirAccess.get_files_at(MAPS_DIR):
		if not file.ends_with(".tscn"):
			continue
		var text := FileAccess.get_file_as_string(MAPS_DIR + file)
		if not text.contains("flag_gate.gd"):
			continue
		for image: String in FRONT + SIDE:
			if text.contains(PROPS + image):
				out.append(file)
				break
	return out


## Préfixe d'une porte : « GrilleA_18_9 » → « GrilleA ».
func _prefix(gate: Node) -> String:
	return String(gate.name).get_slice("_", 0)


## Bloc de cases bloquées relié à [param start] parmi [param cells] (vide si [param start] n'y
## est pas).
func _component(cells: Dictionary, start: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not cells.has(start):
		return out
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		out.append(c)
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if cells.has(c + d) and not seen.has(c + d):
				seen[c + d] = true
				todo.append(c + d)
	return out


## Défaut de sens pour [param drawing] (texte vide si bon ou non vérifiable).
func _check(map: GameMap, gates: Array[FlagGate], drawing: Sprite2D) -> String:
	var image := drawing.texture.resource_path.get_file()
	var gate := drawing.get_parent() as FlagGate
	var cells := {}
	for other: FlagGate in gates:
		if _prefix(other) == _prefix(gate):
			for c: Vector2i in other.blocking_cells:
				cells[c] = true
	var foot := gate.position + drawing.position
	var start := Grid.world_to_cell(foot + Vector2(-1, -1))
	var box := _component(cells, start)
	if box.is_empty():
		return ""
	var r := Rect2i(box[0], Vector2i.ONE)
	for c: Vector2i in box:
		r = r.expand(c).merge(Rect2i(c, Vector2i.ONE))
	var grid := map.get_grid()
	# Une colonne du bloc entre deux murs au nord et au sud : le bloc coupe un mur nord-sud.
	var ns := false
	for x: int in range(r.position.x, r.end.x):
		if grid.is_solid(Vector2i(x, r.position.y - 1)) and grid.is_solid(Vector2i(x, r.end.y)):
			ns = true
	# Une rangée du bloc entre deux murs à l'ouest et à l'est : le bloc ferme un couloir nord-sud.
	var ew := false
	for y: int in range(r.position.y, r.end.y):
		if grid.is_solid(Vector2i(r.position.x - 1, y)) and grid.is_solid(Vector2i(r.end.x, y)):
			ew = true
	if image in FRONT and ns and not ew:
		return "%s %s : %s vue de face dans un mur nord-sud (cases %s)" % [
			map.map_id, gate.name, image, r]
	if image in SIDE and ew and not ns:
		return "%s %s : %s de profil dans un mur est-ouest (cases %s)" % [
			map.map_id, gate.name, image, r]
	return ""


func test_barriers_face_the_way_of_their_wall() -> void:
	var maps := _gate_maps()
	assert_gt(maps.size(), 3, "cartes à barrières trouvées")
	var problems: Array[String] = []
	var checked := 0
	for file: String in maps:
		var map := (load(MAPS_DIR + file) as PackedScene).instantiate() as GameMap
		add_child(map)
		var gates: Array[FlagGate] = []
		for node: Node in map.get_entities().get_children():
			if node is FlagGate:
				gates.append(node as FlagGate)
		for gate: FlagGate in gates:
			var drawing := gate.get_node_or_null(^"Dessin") as Sprite2D
			if drawing == null or drawing.texture == null:
				continue
			var image := drawing.texture.resource_path.get_file()
			if not (image in FRONT or image in SIDE):
				continue
			checked += 1
			var problem := _check(map, gates, drawing)
			if not problem.is_empty():
				problems.append(problem)
		map.free()
	gut.p("barrières vérifiées : %d sur %d cartes" % [checked, maps.size()])
	assert_gt(checked, 10, "barrières vérifiées")
	assert_eq(problems, [] as Array[String], "\n".join(problems))
