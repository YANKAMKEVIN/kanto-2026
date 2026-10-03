extends Node2D
## Jadielle entière (prototype, séries 01 à 04, lumière C2) selon le plan du dossier 09 §1 :
## sortie nord, place centrale entre le Centre et la Boutique, Arène fermée à l'ouest avec le
## départ de la Route 22, quartier sud vers la Route 1. La caméra parcourt la ville en boucle.
## Jetable : le vrai plan se fera dans Godot au J7A.

const CASE := 96
const LARGEUR := 40
const HAUTEUR := 28
const TEX := "res://proto/da_jadielle/tex/"
const SOL_SHADER := preload("res://proto/da_jadielle/sol.gdshader")
const OBJET_SHADER := preload("res://proto/da_jadielle/objet.gdshader")
const OMBRE_SHADER := preload("res://proto/da_jadielle/ombre.gdshader")
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const ETALONNAGE := preload("res://proto/da_jadielle/etalonnage.gdshader")
const MARCHEUR := preload("res://proto/da_jadielle/marcheur.gd")
const EMPRISES := preload("res://proto/da_jadielle/emprises.gd")

## Zones pavées [x, y, largeur, hauteur] en cases.
const PAVES: Array[Rect2i] = [
	Rect2i(21, 0, 3, 10),  # rue nord
	Rect2i(12, 10, 22, 9),  # place
	Rect2i(21, 19, 3, 9),  # rue sud, vers la Route 1
	Rect2i(2, 10, 10, 2),  # parvis de l'Arène
	Rect2i(0, 12, 12, 2),  # chemin vers la Route 22
]
## Objets : [texture, x (milieu du pied), y (ligne du pied), vent, part de base du contact].
const OBJETS: Array = [
	["porte_nord.png", 22.5, 2.6, false, 0.1],
	["centre_ne.png", 17.0, 13.0, false, 0.12],
	["boutique_ne.png", 28.0, 13.0, false, 0.12],
	["arene.png", 6.5, 10.0, false, 0.1],
	["tree_central_ne.png", 22.5, 15.6, true, 0.05],
	["maison_a.png", 9.0, 23.5, false, 0.12],
	["maison_b.png", 34.0, 24.0, false, 0.12],
	["maison_b.png", 35.5, 8.5, false, 0.12],
	["haie.png", 18.5, 21.0, false, 0.3], ["haie.png", 26.5, 21.0, false, 0.3],
	["haie.png", 18.5, 25.5, false, 0.3], ["haie.png", 26.5, 25.5, false, 0.3],
	["cloture.png", 7.0, 27.0, false, 0.3], ["cloture.png", 11.0, 27.0, false, 0.3],
	["cloture.png", 32.0, 27.4, false, 0.3], ["cloture.png", 36.0, 27.4, false, 0.3],
	["panneau.png", 20.2, 19.6, false, 0.1], ["panneau.png", 12.6, 15.2, false, 0.1],
	["lampadaire.png", 20.2, 14.6, false, 0.1], ["lampadaire.png", 24.8, 14.6, false, 0.1],
	["lampadaire.png", 20.3, 9.6, false, 0.1], ["lampadaire.png", 24.7, 9.6, false, 0.1],
	["lampadaire.png", 11.6, 11.6, false, 0.1],
	["banc.png", 19.0, 17.6, false, 0.2], ["banc.png", 26.0, 17.6, false, 0.2],
]
## Personnages : [texture, coins du circuit en cases].
const HABITANTS: Array = [
	["perso_p2", [Vector2i(22, 26), Vector2i(22, 18), Vector2i(14, 18), Vector2i(14, 13),
		Vector2i(3, 13), Vector2i(14, 13), Vector2i(14, 18), Vector2i(22, 18)]],
	["infirmiere", [Vector2i(16, 13)]],
	["marchand", [Vector2i(27, 13)]],
	["livreur", [Vector2i(23, 2), Vector2i(23, 13), Vector2i(32, 13)]],
	["dresseuse", [Vector2i(18, 17)]], ["roucool", [Vector2i(17, 17)]],
	["vieil_homme", [Vector2i(6, 12), Vector2i(9, 12)]],
	["voyageur", [Vector2i(23, 0), Vector2i(23, 27)]],
	["enfant_p2", [Vector2i(27, 16), Vector2i(27, 18), Vector2i(31, 18), Vector2i(31, 16)]],
	["rattata_p2", [Vector2i(27, 16), Vector2i(27, 18), Vector2i(31, 18), Vector2i(31, 16)]],
	["rival", [Vector2i(13, 13), Vector2i(13, 17)]],
]
## Parcours de la caméra (en cases) et durée d'un tour.
const PARCOURS: Array[Vector2] = [Vector2(22.5, 8), Vector2(22.5, 14), Vector2(9, 11),
	Vector2(12, 20), Vector2(22.5, 22), Vector2(32, 18), Vector2(31, 7)]
const DUREE_TOUR := 48.0

var _camera := Camera2D.new()
var _obstacles: Array[Rect2i] = []
var _temps := 0.0
var _hasard := RandomNumberGenerator.new()


func _ready() -> void:
	_hasard.seed = 7
	var cases := _cases_pavees()
	_sol(cases)
	var ombres := Node2D.new()
	add_child(ombres)
	var bordures := Node2D.new()
	add_child(bordures)
	var tries := Node2D.new()
	tries.y_sort_enabled = true
	add_child(tries)
	_bordures(cases, bordures)
	var massif := Sprite2D.new()
	massif.texture = load(TEX + "massif.png")
	massif.centered = false
	massif.position = Vector2(22.5, 15.6) * CASE - Vector2(182, 109)
	bordures.add_child(massif)
	_obstacles.append(Rect2i(21, 14, 4, 3))  # massif de l'arbre central
	for objet: Array in OBJETS:
		_objet(objet, tries, ombres)
	_foret(cases, tries, ombres)
	# Les personnages immobiles sont aussi des obstacles pour ceux qui marchent.
	for habitant: Array in HABITANTS:
		if (habitant[1] as Array).size() == 1:
			_obstacles.append(Rect2i(habitant[1][0], Vector2i.ONE))
	var grille: AStarGrid2D = EMPRISES.grille(Vector2i(LARGEUR, HAUTEUR), _obstacles)
	for habitant: Array in HABITANTS:
		var marcheur: Node2D = MARCHEUR.new()
		marcheur.obstacles = grille
		marcheur.planche_marche = load(TEX + habitant[0] + ".png")
		marcheur.planche_course = marcheur.planche_marche
		var coins: Array[Vector2i] = []
		coins.assign(habitant[1])
		marcheur.circuit = coins
		tries.add_child(marcheur)
	add_child(_camera)
	_lumiere()


func _process(delta: float) -> void:
	_temps = fmod(_temps + delta, DUREE_TOUR)
	var t := _temps / DUREE_TOUR * PARCOURS.size()
	var i := int(t)
	var a := PARCOURS[i]
	var b := PARCOURS[(i + 1) % PARCOURS.size()]
	var f := smoothstep(0.0, 1.0, t - i)
	_camera.position = a.lerp(b, f) * CASE


func _cases_pavees() -> Dictionary:
	var cases := {}
	for zone in PAVES:
		for x in range(zone.position.x, zone.end.x):
			for y in range(zone.position.y, zone.end.y):
				cases[Vector2i(x, y)] = true
	for x in range(21, 24):
		for y in range(15, 17):
			cases.erase(Vector2i(x, y))
	return cases


func _sol(cases: Dictionary) -> void:
	var image := Image.create(LARGEUR, HAUTEUR, false, Image.FORMAT_L8)
	for cellule: Vector2i in cases:
		image.set_pixelv(cellule, Color.WHITE)
	var materiau := ShaderMaterial.new()
	materiau.shader = SOL_SHADER
	materiau.set_shader_parameter(&"herbe", load(TEX + "herbe.png"))
	materiau.set_shader_parameter(&"paves", load(TEX + "paves.png"))
	materiau.set_shader_parameter(&"masque", ImageTexture.create_from_image(image))
	var sol := ColorRect.new()
	sol.size = Vector2(LARGEUR, HAUTEUR) * CASE
	sol.material = materiau
	sol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sol)


func _bordures(cases: Dictionary, parent: Node2D) -> void:
	for cellule: Vector2i in cases:
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var voisin := cellule + direction
			if cases.has(voisin) or voisin.x < 0 or voisin.y < 0 or voisin.x >= LARGEUR \
					or voisin.y >= HAUTEUR:
				continue
			var bord := (Vector2(cellule) + Vector2(0.5, 0.5) + Vector2(direction) * 0.5) * CASE
			var long_bord := Vector2(absf(direction.y), absf(direction.x))
			for i in 2:
				var point := bord + long_bord * _hasard.randf_range(-40.0, 40.0)
				if _hasard.randf() < 0.3:
					_decal(parent, "bord_terre_%d.png" % _hasard.randi_range(1, 4), point, 0.45)
				_decal(parent, "bord_touffe_%d.png" % _hasard.randi_range(1, 4), point, 0.8)


func _decal(parent: Node2D, nom: String, point: Vector2, echelle: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(TEX + nom)
	sprite.position = point
	sprite.scale = Vector2.ONE * echelle * _hasard.randf_range(0.85, 1.15)
	sprite.flip_h = _hasard.randf() < 0.5
	parent.add_child(sprite)


func _objet(objet: Array, tries: Node2D, ombres: Node2D) -> void:
	var texture: Texture2D = load(TEX + objet[0])
	var pied := Vector2(objet[1], objet[2]) * CASE
	_obstacles.append_array(EMPRISES.de(objet[0], Vector2(objet[1], objet[2])))
	var sprite := _au_pied(texture)
	sprite.position = pied
	var materiau := ShaderMaterial.new()
	materiau.shader = OBJET_SHADER
	materiau.set_shader_parameter(&"force_vent", 5.0 if objet[3] else 0.0)
	materiau.set_shader_parameter(&"force_lisere", 1.0)
	sprite.material = materiau
	tries.add_child(sprite)
	var ombre := _au_pied(texture)
	var mat_ombre := ShaderMaterial.new()
	mat_ombre.shader = OMBRE_SHADER
	ombre.material = mat_ombre
	ombre.position = pied
	ombre.scale = Vector2(1.0, -0.26)
	ombre.skew = deg_to_rad(-45.0)
	ombres.add_child(ombre)
	var contact := _au_pied(texture)
	var mat_contact := ShaderMaterial.new()
	mat_contact.shader = CONTACT_SHADER
	mat_contact.set_shader_parameter(&"etendue", 18.0)
	mat_contact.set_shader_parameter(&"part_base", objet[4])
	contact.material = mat_contact
	contact.position = pied + Vector2(0, 18)
	ombres.add_child(contact)


## Arbres sur l'herbe, loin des rues et des bâtiments (dense sur les bords de la ville).
func _foret(cases: Dictionary, tries: Node2D, ombres: Node2D) -> void:
	var libres: Array[Rect2] = [Rect2(12, 4, 10, 10), Rect2(23, 4, 10, 10), Rect2(0, 3, 13, 9),
		Rect2(4, 17, 12, 11), Rect2(30, 18, 10, 10), Rect2(31, 2, 9, 7)]
	var poses: Array[Vector2] = []
	for essai in 900:
		var p := Vector2(_hasard.randf_range(0.5, LARGEUR - 0.5),
			_hasard.randf_range(1.0, HAUTEUR - 0.2))
		var cellule := Vector2i(p)
		var proche := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if cases.has(cellule + Vector2i(dx, dy)):
					proche = true
		for zone in libres:
			if zone.has_point(p):
				proche = true
		for autre in poses:
			if autre.distance_to(p) < 2.1:
				proche = true
		if proche:
			continue
		poses.append(p)
		var nom := "tree_b_ne.png" if _hasard.randf() < 0.5 else "tree_a_ne.png"
		_objet([nom, p.x, p.y, true, 0.05], tries, ombres)


func _lumiere() -> void:
	var calque := CanvasLayer.new()
	calque.layer = 0
	var materiau := ShaderMaterial.new()
	materiau.shader = ETALONNAGE
	var rect := ColorRect.new()
	rect.material = materiau
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	calque.add_child(rect)
	add_child(calque)


func _au_pied(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	return sprite
