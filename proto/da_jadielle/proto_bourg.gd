extends Node2D
## Bourg Palette entier (prototype, série 06, lumière C2) d'après la vue générale peinte v1
## et son plan (`docs/design/reference/bourg-palette-plan-v1.png`, dossier 01) : Route 1 au
## nord barrée par les hautes herbes, maisons du rival (ouest) et du joueur (est), place et
## grand arbre ancien, labo contourné par deux allées jusqu'à sa porte sud, jardins de
## recherche, ancien sentier envahi, sentier côtier, plage, ponton et océan.
## Chemins à angle droit seulement. La caméra parcourt le village en boucle.
## Jetable : la vraie carte (48 × 34 cases) reste `game/world/maps/pallet_town.tscn`.

const CASE := 96
const LARGEUR := 48
const HAUTEUR := 34
const TEX := "res://proto/da_jadielle/tex/"
const SOL_SHADER := preload("res://proto/da_jadielle/sol_bourg.gdshader")
const OBJET_SHADER := preload("res://proto/da_jadielle/objet.gdshader")
const OMBRE_SHADER := preload("res://proto/da_jadielle/ombre.gdshader")
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const ETALONNAGE := preload("res://proto/da_jadielle/etalonnage.gdshader")
const MARCHEUR := preload("res://proto/da_jadielle/marcheur.gd")
const EMPRISES := preload("res://proto/da_jadielle/emprises.gd")

## Zones pavées [x, y, largeur, hauteur] en cases (la place ovale est ajoutée à part).
const PAVES: Array[Rect2i] = [
	Rect2i(12, 9, 2, 4), Rect2i(12, 11, 7, 2),  # allée de la maison du rival
	Rect2i(34, 9, 2, 4), Rect2i(29, 11, 7, 2),  # allée de la maison du joueur
	Rect2i(15, 13, 5, 2), Rect2i(29, 13, 5, 2),  # sorties de la place vers le sud
	Rect2i(15, 13, 2, 13),  # allée ouest : longe le labo puis descend au sentier côtier
	Rect2i(32, 13, 2, 11),  # allée est
	Rect2i(15, 22, 19, 2),  # parvis devant la porte du labo
	Rect2i(11, 22, 4, 2),  # place de la camionnette
]
## Terre battue : Route 1, sentier côtier, ancien sentier.
const TERRE: Array[Rect2i] = [Rect2i(23, 0, 3, 9), Rect2i(5, 26, 43, 2), Rect2i(35, 24, 8, 1)]
const SABLE: Array[Rect2i] = [Rect2i(0, 28, 12, 3)]
## L'océan : tout le bas de la carte, plus large sous la plage.
const EAU: Array[Rect2i] = [Rect2i(0, 31, 48, 3), Rect2i(12, 30, 36, 1)]
const PLACE_CENTRE := Vector2(24.0, 11.2)
const PLACE_RAYONS := Vector2(6.4, 2.8)
## Hautes herbes en travers de la Route 1 : aucun contournement.
const HERBES: Array[Rect2] = [Rect2(20, 2, 9, 3)]
## Zones laissées libres d'arbres.
const DEGAGES: Array[Rect2] = [Rect2(7, 0, 12, 11), Rect2(29, 0, 18, 11), Rect2(19.5, 0, 9, 17),
	Rect2(10, 12, 26, 15), Rect2(3, 25, 45, 9), Rect2(33, 22, 11, 4)]
## Objets : [texture, x (milieu du pied), y (pied), vent, part de base du contact].
const OBJETS: Array = [
	["maison_rival.png", 12.5, 8.4, false, 0.12],
	["maison_joueur.png", 35.0, 8.4, false, 0.12],
	["labo.png", 24.0, 21.6, false, 0.1],
	["arbre_ancien.png", 24.0, 12.6, true, 0.05],
	["serre.png", 29.5, 26.0, false, 0.1],
	["champ.png", 42.5, 6.0, false, 0.0],
	["camionnette.png", 12.8, 23.8, false, 0.15],
	["velo.png", 38.6, 8.6, false, 0.15],
	["boite_lettres.png", 11.3, 9.8, false, 0.1], ["boite_lettres.png", 33.3, 9.8, false, 0.1],
	["cloture_piquets.png", 10.0, 9.9, false, 0.3], ["cloture_piquets.png", 16.0, 9.9, false, 0.3],
	["cloture_piquets.png", 32.0, 9.9, false, 0.3], ["cloture_piquets.png", 38.0, 9.9, false, 0.3],
	["potager.png", 19.5, 25.6, false, 0.2], ["potager.png", 23.0, 25.6, false, 0.2],
	["potager.png", 26.5, 25.6, false, 0.2],
	["ronces.png", 35.6, 25.0, false, 0.2], ["tronc_couche.png", 39.5, 24.9, false, 0.2],
	["escalier.png", 24.5, 7.4, false, 0.2],
	["lampadaire.png", 18.4, 10.6, false, 0.1], ["lampadaire.png", 29.6, 10.6, false, 0.1],
	["lampadaire.png", 18.4, 14.0, false, 0.1], ["lampadaire.png", 29.6, 14.0, false, 0.1],
	["lampadaire.png", 9.6, 25.9, false, 0.1], ["lampadaire.png", 21.6, 25.9, false, 0.1],
	["lampadaire.png", 33.6, 25.9, false, 0.1], ["lampadaire.png", 45.6, 25.9, false, 0.1],
	["banc.png", 20.0, 12.4, false, 0.2], ["banc.png", 28.0, 12.4, false, 0.2],
	["panneau.png", 17.4, 10.4, false, 0.1],
	["cloture.png", 19.0, 25.9, false, 0.3], ["cloture.png", 23.0, 25.9, false, 0.3],
	["cloture.png", 27.0, 25.9, false, 0.3], ["cloture.png", 31.0, 25.9, false, 0.3],
	["cloture.png", 37.0, 25.9, false, 0.3], ["cloture.png", 41.0, 25.9, false, 0.3],
	["cloture.png", 45.0, 25.9, false, 0.3],
	["rocher_mer.png", 17.0, 32.0, false, 0.0], ["rocher_mer.png", 26.0, 33.2, false, 0.0],
	["rocher_mer.png", 36.0, 31.8, false, 0.0], ["rocher_mer.png", 44.0, 33.0, false, 0.0],
	["rocher_mer.png", 9.0, 33.4, false, 0.0],
]
## Posés à plat dans la couche du sol (on marche dessus) : escaliers, ponton.
const A_PLAT := ["escalier", "ponton"]
## Falaise côtière : tronçons de 4 cases entre le sentier et la mer, à l'est de la plage.
const FALAISE_PIED := 30.2
## Personnages et Pokémon : [texture, coins du circuit en cases].
const HABITANTS: Array = [
	["perso_p2", [Vector2i(35, 10), Vector2i(35, 12), Vector2i(33, 14), Vector2i(33, 23),
		Vector2i(24, 23), Vector2i(16, 23), Vector2i(16, 27), Vector2i(8, 27), Vector2i(16, 27),
		Vector2i(16, 14), Vector2i(24, 9), Vector2i(35, 12)]],
	["rival", [Vector2i(12, 10)]],
	["vieil_homme", [Vector2i(21, 12)]],
	["enfant_p2", [Vector2i(27, 9), Vector2i(30, 9), Vector2i(30, 13), Vector2i(27, 13)]],
	["rattata_p2", [Vector2i(27, 9), Vector2i(30, 9), Vector2i(30, 13), Vector2i(27, 13)]],
	["voyageur", [Vector2i(6, 27), Vector2i(47, 27)]],
	["roucool", [Vector2i(19, 6), Vector2i(21, 6)]],
]
const PARCOURS: Array[Vector2] = [Vector2(24, 5), Vector2(24, 11), Vector2(13, 8), Vector2(35, 8),
	Vector2(24, 19), Vector2(16, 25), Vector2(7, 29), Vector2(28, 29), Vector2(39, 23)]
const DUREE_TOUR := 56.0

var _camera := Camera2D.new()
var _obstacles: Array[Rect2i] = []
var _temps := 0.0
var _hasard := RandomNumberGenerator.new()


func _ready() -> void:
	_hasard.seed = 1
	var paves := _cases(PAVES)
	for x in LARGEUR:
		for y in HAUTEUR:
			var d := (Vector2(x, y) + Vector2(0.5, 0.5) - PLACE_CENTRE) / PLACE_RAYONS
			if d.length() <= 1.0:
				paves[Vector2i(x, y)] = true
	var terre := _cases(TERRE)
	var eau := _cases(EAU)
	_sol(paves, terre, _cases(SABLE), eau)
	var ombres := Node2D.new()
	add_child(ombres)
	var bordures := Node2D.new()
	add_child(bordures)
	var tries := Node2D.new()
	tries.y_sort_enabled = true
	add_child(tries)
	var chemins := paves.duplicate()
	chemins.merge(terre)
	_bordures(chemins, bordures)
	_objet(["ponton.png", 5.0, 32.6, false, 0.0], bordures, ombres)
	_objet(["escalier_bois.png", 8.5, 29.4, false, 0.0], bordures, ombres)
	for x in range(14, 48, 4):
		_objet(["falaise.png", float(x), FALAISE_PIED, false, 0.3], tries, ombres)
	for objet: Array in OBJETS:
		var calque := tries
		for nom: String in A_PLAT:
			if (objet[0] as String).begins_with(nom):
				calque = bordures
		_objet(objet, calque, ombres)
	_herbes_hautes(tries)
	_foret(chemins, tries, ombres)
	for cellule: Vector2i in eau:
		_obstacles.append(Rect2i(cellule, Vector2i.ONE))
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
	_camera.limit_left = 0
	_camera.limit_right = LARGEUR * CASE
	_camera.limit_top = 0
	_camera.limit_bottom = HAUTEUR * CASE
	add_child(_camera)
	_lumiere()


func _process(delta: float) -> void:
	# Inspection : `-- --vise=x,y` fige la caméra sur un point (en cases).
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--vise="):
			var v := argument.trim_prefix("--vise=").split(",")
			_camera.position = Vector2(v[0].to_float(), v[1].to_float()) * CASE
			if v.size() > 2:
				_camera.zoom = Vector2.ONE * v[2].to_float()
			return
	_temps = fmod(_temps + delta, DUREE_TOUR)
	var t := _temps / DUREE_TOUR * PARCOURS.size()
	var i := int(t)
	var f := smoothstep(0.0, 1.0, t - i)
	_camera.position = PARCOURS[i].lerp(PARCOURS[(i + 1) % PARCOURS.size()], f) * CASE


func _cases(zones: Array[Rect2i]) -> Dictionary:
	var cases := {}
	for zone in zones:
		for x in range(zone.position.x, zone.end.x):
			for y in range(zone.position.y, zone.end.y):
				cases[Vector2i(x, y)] = true
	return cases


func _sol(paves: Dictionary, terre: Dictionary, sable: Dictionary, eau: Dictionary) -> void:
	var image := Image.create(LARGEUR, HAUTEUR, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in LARGEUR:
		for y in HAUTEUR:
			var cellule := Vector2i(x, y)
			image.set_pixelv(cellule, Color(float(paves.has(cellule)), float(terre.has(cellule)),
				float(sable.has(cellule) or eau.has(cellule)), float(eau.has(cellule))))
	var materiau := ShaderMaterial.new()
	materiau.shader = SOL_SHADER
	materiau.set_shader_parameter(&"herbe", load(TEX + "herbe.png"))
	materiau.set_shader_parameter(&"paves", load(TEX + "paves.png"))
	materiau.set_shader_parameter(&"chemin", load(TEX + "chemin.png"))
	materiau.set_shader_parameter(&"sable", load(TEX + "sable.png"))
	materiau.set_shader_parameter(&"eau", load(TEX + "eau.png"))
	materiau.set_shader_parameter(&"masque", ImageTexture.create_from_image(image))
	var sol := ColorRect.new()
	sol.size = Vector2(LARGEUR, HAUTEUR) * CASE
	sol.material = materiau
	sol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sol)


func _bordures(cases: Dictionary, parent: Node2D) -> void:
	for cellule: Vector2i in cases:
		if cellule.y >= 26:
			continue  # le sentier côtier borde la falaise : pas de touffes côté mer
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


func _objet(objet: Array, calque: Node2D, ombres: Node2D) -> void:
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
	calque.add_child(sprite)
	if objet[4] <= 0.0:
		return  # posé à plat ou dans l'eau : ni ombre portée ni ombre de contact
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


## Deux touffes par case, triées par les pieds : les personnages y entrent jusqu'aux genoux.
func _herbes_hautes(tries: Node2D) -> void:
	var texture: Texture2D = load(TEX + "hautes_herbes.png")
	for zone in HERBES:
		for x in range(int(zone.position.x), int(zone.end.x)):
			for y in range(int(zone.position.y), int(zone.end.y)):
				for k in 2:
					var sprite := _au_pied(texture)
					sprite.position = (Vector2(x, y) + Vector2(_hasard.randf_range(0.25, 0.75),
						0.55 + 0.45 * k)) * CASE
					sprite.scale = Vector2.ONE * _hasard.randf_range(1.0, 1.3)
					sprite.flip_h = _hasard.randf() < 0.5
					var materiau := ShaderMaterial.new()
					materiau.shader = OBJET_SHADER
					materiau.set_shader_parameter(&"force_vent", 2.5)
					sprite.material = materiau
					tries.add_child(sprite)


## Forêt dense sur l'herbe, loin des chemins et des zones dégagées.
func _foret(cases: Dictionary, tries: Node2D, ombres: Node2D) -> void:
	var poses: Array[Vector2] = []
	for essai in 2500:
		var p := Vector2(_hasard.randf_range(0.5, LARGEUR - 0.5),
			_hasard.randf_range(1.0, HAUTEUR - 0.2))
		var cellule := Vector2i(p)
		var proche := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if cases.has(cellule + Vector2i(dx, dy)):
					proche = true
		for zone in DEGAGES:
			if zone.has_point(p):
				proche = true
		for autre in poses:
			if autre.distance_to(p) < 2.0:
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
