extends Node2D
## Route 22 (prototype, série 05, lumière C2), d'après le dossier 09 §12–§13 : chemin de
## terre depuis Jadielle (à l'est) vers l'ouest, falaise basse et escalier vers un niveau
## supérieur, herbes hautes avec Pokémon sauvages (Rattata, Piafabec, Férosinge, Nidoran),
## et au bout, la vue vers le Plateau Indigo. Le rival vient de battre un jeune Dresseur.
## La caméra parcourt la route en boucle. Jetable : le vrai plan se fera au J7B.

const CASE := 96
const LARGEUR := 46
const HAUTEUR := 20
const TEX := "res://proto/da_jadielle/tex/"
const SOL_SHADER := preload("res://proto/da_jadielle/sol.gdshader")
const OBJET_SHADER := preload("res://proto/da_jadielle/objet.gdshader")
const OMBRE_SHADER := preload("res://proto/da_jadielle/ombre.gdshader")
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const ETALONNAGE := preload("res://proto/da_jadielle/etalonnage.gdshader")
const MARCHEUR := preload("res://proto/da_jadielle/marcheur.gd")
const EMPRISES := preload("res://proto/da_jadielle/emprises.gd")

## Chemin de terre [x, y, largeur, hauteur] en cases.
const CHEMIN: Array[Rect2i] = [
	Rect2i(14, 10, 32, 3),  # depuis Jadielle (est)
	Rect2i(15, 8, 2, 2),  # pied de l'escalier
	Rect2i(2, 5, 15, 2),  # niveau supérieur, vers le point de vue
]
## Herbes hautes (rencontres).
const HERBES: Array[Rect2] = [Rect2(20, 13, 8, 4), Rect2(32, 3, 7, 4), Rect2(5, 13, 6, 4)]
## Zones laissées libres d'arbres (point de vue, abords de la falaise).
const DEGAGES: Array[Rect2] = [Rect2(0, 0, 17, 5), Rect2(0, 7, 18, 3), Rect2(17, 7, 13, 2)]
## Objets : [texture, x (milieu du pied), y (pied), vent, part de base du contact].
const OBJETS: Array = [
	["falaise.png", 2.0, 4.2, false, 0.3], ["falaise.png", 6.0, 4.2, false, 0.3],
	["falaise.png", 10.0, 4.2, false, 0.3], ["falaise.png", 14.0, 4.2, false, 0.3],
	["falaise.png", 2.0, 8.0, false, 0.3], ["falaise.png", 6.0, 8.0, false, 0.3],
	["falaise.png", 10.0, 8.0, false, 0.3], ["falaise.png", 13.0, 8.0, false, 0.3],
	["escalier.png", 16.0, 8.4, false, 0.2],
	["falaise.png", 19.0, 8.0, false, 0.3], ["falaise.png", 23.0, 8.0, false, 0.3],
	["falaise.png", 27.0, 8.0, false, 0.3],
	["rocher.png", 30.0, 14.4, false, 0.15], ["rocher.png", 41.0, 7.6, false, 0.15],
	["rocher.png", 12.6, 16.8, false, 0.15],
]
## Personnages et Pokémon : [texture, coins du circuit en cases].
const HABITANTS: Array = [
	["perso_p2", [Vector2i(44, 11), Vector2i(16, 11), Vector2i(16, 6), Vector2i(12, 6),
		Vector2i(16, 6), Vector2i(16, 11)]],
	["voyageur", [Vector2i(18, 10), Vector2i(42, 10)]],
	["rival", [Vector2i(8, 6)]],
	["jeune_dresseur", [Vector2i(6, 6)]],
	# Pokémon au bord des herbes hautes (dedans, ils disparaîtraient entièrement).
	["rattata_p2", [Vector2i(21, 17), Vector2i(26, 17)]],
	["nidoran_f", [Vector2i(19, 14), Vector2i(19, 16)]],
	["piafabec", [Vector2i(33, 7), Vector2i(37, 7)]],
	["ferosinge", [Vector2i(39, 4), Vector2i(39, 6)]],
	["nidoran_m", [Vector2i(6, 12), Vector2i(10, 12)]],
]
const PARCOURS: Array[Vector2] = [Vector2(36, 10), Vector2(26, 11), Vector2(17, 9),
	Vector2(9, 3), Vector2(9, 3), Vector2(12, 9), Vector2(30, 6)]
const DUREE_TOUR := 50.0

var _camera := Camera2D.new()
var _obstacles: Array[Rect2i] = []
var _temps := 0.0
var _hasard := RandomNumberGenerator.new()


func _ready() -> void:
	_hasard.seed = 22
	var vue := Sprite2D.new()
	vue.texture = load(TEX + "plateau_indigo.png")
	vue.centered = false
	vue.position = Vector2(-0.5, -6.6) * CASE
	vue.scale = Vector2(1.13, 1.0)
	var cases := _cases_chemin()
	_sol(cases)
	# Au-dessus de la carte : la vue vers le Plateau à l'ouest, la forêt ailleurs.
	var lisiere := ColorRect.new()
	lisiere.position = Vector2(14, -7) * CASE
	lisiere.size = Vector2(LARGEUR - 14, 7) * CASE
	var mat_lisiere := ShaderMaterial.new()
	mat_lisiere.shader = SOL_SHADER
	mat_lisiere.set_shader_parameter(&"herbe", load(TEX + "herbe.png"))
	mat_lisiere.set_shader_parameter(&"paves", load(TEX + "chemin.png"))
	mat_lisiere.set_shader_parameter(&"masque", ImageTexture.create_from_image(
		Image.create(1, 1, false, Image.FORMAT_L8)))
	lisiere.material = mat_lisiere
	lisiere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lisiere)
	var fondu := Shader.new()
	fondu.code = """shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Bord droit et bas fondus dans la forêt et le sol (pas de raccord net).
	c.a *= 1.0 - smoothstep(0.86, 1.0, UV.x);
	c.a *= 1.0 - smoothstep(0.88, 1.0, UV.y);
	COLOR = c;
}"""
	var mat_vue := ShaderMaterial.new()
	mat_vue.shader = fondu
	vue.material = mat_vue
	add_child(vue)
	var ombres := Node2D.new()
	add_child(ombres)
	var bordures := Node2D.new()
	add_child(bordures)
	var tries := Node2D.new()
	tries.y_sort_enabled = true
	add_child(tries)
	_bordures(cases, bordures)
	for objet: Array in OBJETS:
		_objet(objet, tries, ombres)
	_herbes_hautes(tries)
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
	_camera.limit_left = 0
	_camera.limit_right = LARGEUR * CASE
	_camera.limit_top = -7 * CASE
	_camera.limit_bottom = HAUTEUR * CASE
	add_child(_camera)
	_lumiere()


func _process(delta: float) -> void:
	# Inspection : `-- --vise=x,y` fige la caméra sur un point (en cases).
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--vise="):
			var v := argument.trim_prefix("--vise=").split(",")
			_camera.position = Vector2(v[0].to_float(), v[1].to_float()) * CASE
			return
	_temps = fmod(_temps + delta, DUREE_TOUR)
	var t := _temps / DUREE_TOUR * PARCOURS.size()
	var i := int(t)
	var f := smoothstep(0.0, 1.0, t - i)
	_camera.position = PARCOURS[i].lerp(PARCOURS[(i + 1) % PARCOURS.size()], f) * CASE


func _cases_chemin() -> Dictionary:
	var cases := {}
	for zone in CHEMIN:
		for x in range(zone.position.x, zone.end.x):
			for y in range(zone.position.y, zone.end.y):
				cases[Vector2i(x, y)] = true
	return cases


## Une touffe par case, triée par les pieds : les personnages y entrent jusqu'aux genoux.
func _herbes_hautes(tries: Node2D) -> void:
	var texture: Texture2D = load(TEX + "hautes_herbes.png")
	for zone in HERBES:
		for x in range(int(zone.position.x), int(zone.end.x)):
			for y in range(int(zone.position.y), int(zone.end.y)):
				# Deux touffes par case, décalées et de tailles variées : pas de rangées visibles.
				for k in 2:
					var sprite := _au_pied(texture)
					sprite.position = (Vector2(x, y) + Vector2(_hasard.randf_range(0.25, 0.75),
						0.55 + 0.45 * k)) * CASE
					sprite.scale = Vector2.ONE * _hasard.randf_range(1.0, 1.3)
					sprite.flip_h = _hasard.randf() < 0.5
					_herbe_vent(sprite, tries)


func _herbe_vent(sprite: Sprite2D, tries: Node2D) -> void:
	if sprite:
		var materiau := ShaderMaterial.new()
		materiau.shader = OBJET_SHADER
		materiau.set_shader_parameter(&"force_vent", 2.5)
		sprite.material = materiau
		tries.add_child(sprite)


func _sol(cases: Dictionary) -> void:
	var image := Image.create(LARGEUR, HAUTEUR, false, Image.FORMAT_L8)
	for cellule: Vector2i in cases:
		image.set_pixelv(cellule, Color.WHITE)
	var materiau := ShaderMaterial.new()
	materiau.shader = SOL_SHADER
	materiau.set_shader_parameter(&"herbe", load(TEX + "herbe.png"))
	materiau.set_shader_parameter(&"paves", load(TEX + "chemin.png"))
	materiau.set_shader_parameter(&"echelle_paves", 1.0)
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


## Arbres sur l'herbe, loin du chemin, des herbes hautes et des zones dégagées.
func _foret(cases: Dictionary, tries: Node2D, ombres: Node2D) -> void:
	var poses: Array[Vector2] = []
	for essai in 2200:
		var p := Vector2(_hasard.randf_range(0.5, LARGEUR - 0.5),
			_hasard.randf_range(-6.0, HAUTEUR - 0.2))
		# Au-dessus de la carte : seulement la forêt à droite de la vue (x ≥ 14,5).
		if p.y < 0.8 and p.x < 15.8:
			continue
		var cellule := Vector2i(p)
		var proche := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if cases.has(cellule + Vector2i(dx, dy)):
					proche = true
		for zone in DEGAGES:
			if zone.grow(1.0).has_point(p):
				proche = true
		# Clairière autour des herbes hautes : plus large au sud, où les arbres (hauts de
		# 4 à 5 cases) cacheraient le champ et les Pokémon.
		for zone in HERBES:
			if Rect2(zone.position - Vector2(2, 2), zone.size + Vector2(4, 7)).has_point(p):
				proche = true
		for autre in poses:
			if autre.distance_to(p) < 2.1:
				proche = true
		if proche:
			continue
		poses.append(p)
		var nom := "tree_b_ne.png" if _hasard.randf() < 0.6 else "tree_a_ne.png"
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
