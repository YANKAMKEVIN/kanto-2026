extends Node2D
## Route 1 (prototype, série 08, lumière C2) d'après la vue générale peinte v1
## (`docs/design/reference/route-1-vue-generale-v1.png`, dossier 07 « Vue générale peinte v1 »).
## Géométrie = celle de `game/world/maps/route_1.tscn` (jalon 5), recopiée case par case :
## T forêt, . herbe, , fleurs, = chemin, h hautes herbes, v rebord (sauté vers le sud).
## La caméra remonte la route en boucle. Jetable : la vraie carte reste celle du jeu.

const CASE := 96
const LARGEUR := 48
const HAUTEUR := 44
const TEX := "res://proto/da_jadielle/tex/"
const SOL_SHADER := preload("res://proto/da_jadielle/sol_bourg.gdshader")
const OBJET_SHADER := preload("res://proto/da_jadielle/objet.gdshader")
const OMBRE_SHADER := preload("res://proto/da_jadielle/ombre.gdshader")
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const ETALONNAGE := preload("res://proto/da_jadielle/etalonnage.gdshader")
const MARCHEUR := preload("res://proto/da_jadielle/marcheur.gd")
const EMPRISES := preload("res://proto/da_jadielle/emprises.gd")

const GRILLE: Array[String] = [
	"TTTTTTTTTTTTTTTTTTTTTTT==TTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTT..,,......,......==.................TTTTTT",
	"TTTTTT..,..,...........==,................TTTTTT",
	"TTTTTT.....,......,,...==.....,...........TTTTTT",
	"TTTTTT........,........==.................TTTTTT",
	"TTTTTT..............,..==..........,.....,TTTTTT",
	"TTTTTT.................==.................TTTTTT",
	"TTTTTT..............,..==................,TTTTTT",
	"TTTTTTTTTTTTTTTTTTTTTTThhTTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTTTThhTTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTT.............==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTT.............==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTT....=============..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTT....=============..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTT....==.............TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTThhhh==.............TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTThhhh==..TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTh.hh==..TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTThhhh==..TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTThhhh==..TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTThhhh==..TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTThhhh==.........................TTTTTTTTT",
	"TTTTTTTThhhh=======================....TTTTTTTTT",
	"TTTTTTTThhhh=======================....TTTTTTTTT",
	"TTTTTTTThhhh.....................==....TTTTTTTTT",
	"TTTTTTTT.........................==....TTTTTTTTT",
	"TTTTTTTT.........................==....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTTTTTTTvvvTT..==....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTTTTTTT...TT..==....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT......hhhh..==....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT......hhhh..==....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT......hhhh..==....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..============....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..============....TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..............TTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT,.==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
	"TTTTTTTTTTTTTTTTTTTTT..==..TTTTTTTTTTTTTTTTTTTTT",
]
## Arbres repères (positions des arbres de la carte du jeu) et objets, [texture, x, y (pied),
## vent, part de base du contact].
const OBJETS: Array = [
	["tree_c_ne.png", 9.5, 20.0, true, 0.05],  # arbre du recoin de la Potion
	["souche.png", 9.6, 20.95, false, 0.15],
	["tree_b_ne.png", 7.5, 11.0, true, 0.05], ["tree_b_ne.png", 30.5, 21.0, true, 0.05],
	["tree_c_ne.png", 40.5, 11.0, true, 0.05], ["tree_a_ne.png", 33.5, 22.0, true, 0.05],
	["automne.png", 16.5, 22.0, true, 0.05], ["tree_d_ne.png", 19.5, 31.0, true, 0.05],
	# Départ depuis Bourg Palette : clôtures courtes, fleurs, un rocher.
	["piquet_court.png", 21.5, 42.9, false, 0.2], ["piquet_court.png", 25.5, 42.9, false, 0.2],
	["rocher.png", 26.3, 40.6, false, 0.15], ["buisson_b.png", 21.6, 39.4, false, 0.1],
	# Prairie du nord : traces humaines qui annoncent Jadielle.
	["panneau.png", 22.3, 7.8, false, 0.1], ["cloture.png", 12.0, 3.6, false, 0.3],
	["cloture.png", 35.0, 2.6, false, 0.3], ["banc.png", 38.5, 5.2, false, 0.2],
	# Bords des clairières.
	["buisson_a.png", 10.6, 13.9, false, 0.1], ["buisson_c.png", 26.4, 11.0, false, 0.1],
	["pierres.png", 37.6, 27.6, false, 0.1], ["buisson_b.png", 38.4, 24.8, false, 0.1],
	["rocher.png", 8.6, 28.6, false, 0.15], ["buisson_a.png", 21.6, 36.9, false, 0.1],
]
## Personnages et Pokémon : [texture, coins du circuit, options] (cf. proto_bourg.gd).
const HABITANTS: Array = [
	["perso_p2", [Vector2i(23, 43), Vector2i(24, 1)], {}],
	# Le Voyageur (dossier 07 §5) : petite zone près du chemin, jamais dans les herbes.
	["voyageur", [Vector2i(25, 11), Vector2i(26, 14), Vector2i(25, 13)],
		{"pauses": [3.0, 4.0, 2.0]}],
	["roucool", [Vector2i(12, 4), Vector2i(14, 4)], {"pauses": [6.0, 4.0]}],
	["roucool", [Vector2i(33, 3)], {}],
	["rattata_p2", [Vector2i(26, 32), Vector2i(26, 34)], {"pauses": [5.0, 3.0]}],
]
const PARCOURS: Array[Vector2] = [Vector2(24, 39), Vector2(28, 32), Vector2(24, 26), Vector2(12, 22),
	Vector2(16, 15), Vector2(24, 11), Vector2(24, 5), Vector2(34, 4)]
const DUREE_TOUR := 56.0

## Forêt de forêt (test de Kevin, 2026-10-06) : sous-bois sombre, arbres de forêt plus petits
## et serrés (planche `foret_1..8`, ≈ 3 cases) teintés au hasard, hautes herbes jaune-vert.
## Faux : la version précédente (grands arbres de Jadielle sur l'herbe), pour comparer.
var nouvelle_foret := true

var _camera := Camera2D.new()
var _obstacles: Array[Rect2i] = []
var _temps := 0.0
var _hasard := RandomNumberGenerator.new()


func _ready() -> void:
	_hasard.seed = 1
	var chemin := _cases("=")
	var herbes := _cases("h")
	var foret := _cases("T")
	_sol(chemin)
	if nouvelle_foret:
		_sous_bois(foret)
	var ombres := Node2D.new()
	add_child(ombres)
	var bordures := Node2D.new()
	add_child(bordures)
	var tries := Node2D.new()
	tries.y_sort_enabled = true
	add_child(tries)
	_bordures(chemin, bordures)
	for cellule: Vector2i in _cases(","):
		for i in 2:
			var p := (Vector2(cellule) + Vector2(_hasard.randf(), _hasard.randf())) * CASE
			_decal(bordures, "fleur_%d.png" % _hasard.randi_range(1, 8), p, 1.0)
	# Le rebord fait partie du sol : on le saute vers le sud, il ne passe jamais devant.
	for cellule: Vector2i in _cases("v"):
		_objet(["rebord.png", cellule.x + 0.5, cellule.y + 1.0, false, 0.0], bordures, ombres)
	for objet: Array in OBJETS:
		_objet(objet, tries, ombres)
	_herbes_hautes(herbes, tries)
	if nouvelle_foret:
		_foret_serree(foret, tries, ombres)
	else:
		_foret(foret, tries, ombres)
	_semis(chemin, herbes, foret, bordures)
	for cellule: Vector2i in foret:
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
		var options: Dictionary = habitant[2]
		marcheur.pauses.assign(options.get("pauses", []))
		tries.add_child(marcheur)
	_camera.limit_left = 0
	_camera.limit_right = LARGEUR * CASE
	_camera.limit_top = 0
	_camera.limit_bottom = HAUTEUR * CASE
	add_child(_camera)
	_lumiere()


func _process(delta: float) -> void:
	# Inspection : `-- --vise=x,y[,zoom]` fige la caméra sur un point (en cases).
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


func _cases(caractere: String) -> Dictionary:
	var cases := {}
	for y in GRILLE.size():
		for x in GRILLE[y].length():
			if GRILLE[y][x] == caractere:
				cases[Vector2i(x, y)] = true
	return cases


func _sol(chemin: Dictionary) -> void:
	var image := Image.create(LARGEUR, HAUTEUR, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for cellule: Vector2i in chemin:
		image.set_pixelv(cellule, Color(0, 1, 0, 0))
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
		return
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


func _herbes_hautes(herbes: Dictionary, tries: Node2D) -> void:
	var texture: Texture2D = load(TEX + ("hautes_herbes_jaune.png" if nouvelle_foret
		else "hautes_herbes.png"))
	for cellule: Vector2i in herbes:
		for k in 2:
			var sprite := _au_pied(texture)
			sprite.position = (Vector2(cellule) + Vector2(_hasard.randf_range(0.25, 0.75),
				0.55 + 0.45 * k)) * CASE
			sprite.scale = Vector2.ONE * _hasard.randf_range(1.0, 1.3)
			sprite.flip_h = _hasard.randf() < 0.5
			var materiau := ShaderMaterial.new()
			materiau.shader = OBJET_SHADER
			materiau.set_shader_parameter(&"force_vent", 2.5)
			sprite.material = materiau
			tries.add_child(sprite)


## Forêt dense : un arbre (4 à 5 cases de haut) ne pousse que si les cases que couvre son
## feuillage, au-dessus de son pied, sont aussi de la forêt : il ne cache ni le chemin ni les
## clairières (dossier 07, choix 1 : clairières larges). Les bandes trop étroites pour un
## arbre sont garnies de buissons denses.
func _foret(foret: Dictionary, tries: Node2D, ombres: Node2D) -> void:
	var poses: Array[Vector2] = []
	# Les arbres repères restent dégagés : pas d'autre arbre à moins de 2,4 cases.
	var reperes: Array[Vector2] = []
	for objet: Array in OBJETS:
		var nom_objet: String = objet[0]
		if nom_objet.begins_with("tree") or nom_objet.begins_with("automne"):
			reperes.append(Vector2(objet[1], objet[2]))
	for essai in 5000:
		var p := Vector2(_hasard.randf_range(0.3, LARGEUR - 0.3), _hasard.randf_range(0.6, HAUTEUR + 1.5))
		if not _sous_couvert(Vector2i(p), foret):
			continue
		var proche := false
		for autre in poses:
			if autre.distance_to(p) < 1.75:
				proche = true
				break
		for repere in reperes:
			if repere.distance_to(p) < 2.4:
				proche = true
		if proche:
			continue
		poses.append(p)
		var nom: String = ["tree_a_ne.png", "tree_b_ne.png", "tree_central_ne.png", "tree_c_ne.png",
			"tree_d_ne.png", "tree_e_ne.png", "tree_c_ne.png", "tree_e_ne.png"][_hasard.randi_range(0, 7)]
		_objet([nom, p.x, p.y, true, 0.05], tries, ombres)
	poses.append_array(reperes)
	for cellule: Vector2i in foret:
		var centre := Vector2(cellule) + Vector2(0.5, 0.7)
		var couvert := false
		for autre in poses:
			if autre.distance_to(centre) < 1.3 or (absf(autre.x - centre.x) < 1.2 \
					and centre.y < autre.y and autre.y - centre.y < 3.5):
				couvert = true
				break
		if couvert:
			continue
		var nom: String = ["buisson_a.png", "buisson_b.png", "buisson_a.png"][_hasard.randi_range(0, 2)]
		_objet([nom, centre.x + _hasard.randf_range(-0.2, 0.2), centre.y + 0.25, true, 0.1], tries, ombres)


func _sous_couvert(cellule: Vector2i, foret: Dictionary) -> bool:
	for dy in range(0, 4):
		for dx in range(-1, 2):
			if dy == 0 and dx != 0:
				continue
			var c := cellule + Vector2i(dx, -dy)
			if c.y < 0 or c.x < 0 or c.x >= LARGEUR or c.y >= HAUTEUR:
				continue  # hors de la carte : la forêt continue
			if not foret.has(c):
				return false
	return true


func _sous_bois(foret: Dictionary) -> void:
	var image := Image.create(LARGEUR, HAUTEUR, false, Image.FORMAT_L8)
	for cellule: Vector2i in foret:
		image.set_pixelv(cellule, Color.WHITE)
	var materiau := ShaderMaterial.new()
	materiau.shader = preload("res://proto/da_jadielle/sous_bois.gdshader")
	materiau.set_shader_parameter(&"masque", ImageTexture.create_from_image(image))
	var rect := ColorRect.new()
	rect.size = Vector2(LARGEUR, HAUTEUR) * CASE
	rect.material = materiau
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


## Forêt serrée : arbres de forêt (≈ 3 cases) dont la cime couvre 2 cases au-dessus du pied,
## espacés de 1,1 case pour que les cimes se touchent, teinte et taille variées au hasard.
func _foret_serree(foret: Dictionary, tries: Node2D, ombres: Node2D) -> void:
	var reperes: Array[Vector2] = []
	for objet: Array in OBJETS:
		var nom_objet: String = objet[0]
		if nom_objet.begins_with("tree") or nom_objet.begins_with("automne"):
			reperes.append(Vector2(objet[1], objet[2]))
	var poses: Array[Vector2] = []
	for essai in 9000:
		var p := Vector2(_hasard.randf_range(0.3, LARGEUR - 0.3), _hasard.randf_range(0.6, HAUTEUR + 1.2))
		var cellule := Vector2i(p)
		var couvert := true
		for dy in range(0, 3):
			var c := cellule + Vector2i(0, -dy)
			if c.y >= 0 and c.y < HAUTEUR and not foret.has(c):
				couvert = false
		if not couvert:
			continue
		var proche := false
		for autre in poses:
			if autre.distance_to(p) < 1.1:
				proche = true
				break
		for repere in reperes:
			if repere.distance_to(p) < 2.0:
				proche = true
		if proche:
			continue
		poses.append(p)
		var texture: Texture2D = load(TEX + "foret_%d.png" % _hasard.randi_range(1, 8))
		var sprite := _au_pied(texture)
		sprite.position = p * CASE
		var echelle := _hasard.randf_range(0.85, 1.15)
		sprite.scale = Vector2(echelle * (-1.0 if _hasard.randf() < 0.5 else 1.0), echelle)
		var v := _hasard.randf_range(0.86, 1.08)
		sprite.modulate = Color(v * _hasard.randf_range(0.95, 1.03), v, v * _hasard.randf_range(0.93, 1.05))
		var materiau := ShaderMaterial.new()
		materiau.shader = OBJET_SHADER
		materiau.set_shader_parameter(&"force_vent", 3.5)
		materiau.set_shader_parameter(&"force_lisere", 1.0)
		sprite.material = materiau
		tries.add_child(sprite)
		var contact := _au_pied(texture)
		var mat_contact := ShaderMaterial.new()
		mat_contact.shader = CONTACT_SHADER
		mat_contact.set_shader_parameter(&"etendue", 18.0)
		mat_contact.set_shader_parameter(&"part_base", 0.05)
		contact.material = mat_contact
		contact.position = p * CASE + Vector2(0, 18)
		ombres.add_child(contact)
	# Bandes trop étroites pour un arbre (bords du rebord, goulet) : buissons denses.
	poses.append_array(reperes)
	for cellule: Vector2i in foret:
		var centre := Vector2(cellule) + Vector2(0.5, 0.7)
		var garni := false
		for autre in poses:
			if autre.distance_to(centre) < 1.0 or (absf(autre.x - centre.x) < 0.9 \
					and centre.y < autre.y and autre.y - centre.y < 2.4):
				garni = true
				break
		if not garni:
			_objet([["buisson_a.png", "buisson_b.png"][_hasard.randi_range(0, 1)],
				centre.x + _hasard.randf_range(-0.15, 0.15), centre.y + 0.25, true, 0.1], tries, ombres)


## Touffes, fleurs sauvages et quelques pierres sur l'herbe rase, en gardant du calme.
func _semis(chemin: Dictionary, herbes: Dictionary, foret: Dictionary, sol: Node2D) -> void:
	for essai in 900:
		var p := Vector2(_hasard.randf_range(0.5, LARGEUR - 0.5), _hasard.randf_range(0.5, HAUTEUR - 0.5))
		var cellule := Vector2i(p)
		if chemin.has(cellule) or herbes.has(cellule) or foret.has(cellule):
			continue
		if _hasard.randf() < 0.14:
			_decal(sol, "fleur_%d.png" % _hasard.randi_range(1, 8), p * CASE, 1.0)
		else:
			_decal(sol, "bord_touffe_%d.png" % _hasard.randi_range(1, 4), p * CASE, 0.9)


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
