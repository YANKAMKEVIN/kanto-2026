extends Node2D
## Scène prototype de la place de Jadielle (cahier de l'art du monde §5, série 01).
## Jetable : vit seulement sur la branche proto/da-jadielle, ne dépend d'aucun code du jeu.
## Construit la place en code : sol par masque, bordures, ombres, objets triés par les pieds.

const CASE := 96
const LARGEUR := 26
const HAUTEUR := 14
const TEX := "res://proto/da_jadielle/tex/"
const SOL_SHADER := preload("res://proto/da_jadielle/sol.gdshader")
const OBJET_SHADER := preload("res://proto/da_jadielle/objet.gdshader")
const OMBRE_SHADER := preload("res://proto/da_jadielle/ombre.gdshader")
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const JOUEUR := preload("res://assets/sprites/characters/placeholder/player_sheet.png")

## Zones pavées, en cases [x, y, largeur, hauteur].
const PAVES: Array[Rect2i] = [
	Rect2i(2, 5, 22, 8),  # la place, sous et devant les bâtiments
	Rect2i(12, 13, 2, 1),  # départ du chemin vers la Route 1
]
## Massif fleuri au pied de l'arbre central (J7.1) : centre de son trou de terre, en pixels
## de la texture, posé sur le pied de l'arbre.
const MASSIF_TROU := Vector2(182, 109)
const PIED_ARBRE_CENTRAL := Vector2(13.0, 9.8)
## Objets : [texture, x en cases (milieu du pied), y en cases (ligne du pied), vent].
const OBJETS: Array = [
	["centre.png", 7.0, 7.0, false],
	["boutique.png", 19.0, 7.0, false],
	["tree_central.png", 13.0, 9.8, true],
	["tree_b.png", 1.0, 5.0, true],
	["tree_a.png", 1.0, 9.0, true],
	["tree_b.png", 1.2, 13.6, true],
	["tree_a.png", 25.0, 5.5, true],
	["tree_b.png", 24.8, 9.6, true],
	["tree_a.png", 25.0, 13.8, true],
	# J7.1 : bancs face au sud de part et d'autre du massif, lampadaires.
	["banc.png", 9.4, 10.7, false],
	["banc.png", 16.6, 10.7, false],
	["lampadaire.png", 10.4, 8.6, false],
	["lampadaire.png", 15.6, 8.6, false],
	["lampadaire.png", 3.2, 7.6, false],
	["lampadaire.png", 22.8, 7.6, false],
]
const BATIMENTS: Array[String] = ["centre.png", "boutique.png"]
## Objets qui existent aussi en lumière neutre (« _ne »).
const VARIANTES_NE: Array[String] = ["centre.png", "boutique.png", "tree_a.png", "tree_b.png",
	"tree_central.png"]
## Lumière GH : teinte chaude du sol (les objets sont déjà peints en GH).
const TEINTE_SOL := Color(1.0, 0.95, 0.86)

## Comparaison de lumière (cahier §5.3) ; toucher l'écran passe au mode suivant.
## [nom, variantes NE, teinte du sol, teinte globale de Godot (CanvasModulate)].
const MODES_LUMIERE: Array = [
	["A — golden hour PEINTE dans les assets", false, Color(1.0, 0.95, 0.86), Color.WHITE],
	["B — assets NEUTRES, sans traitement", true, Color.WHITE, Color.WHITE],
	["C — assets neutres + golden hour par Godot (v1 : teinte globale)", true, Color.WHITE,
		Color(1.0, 0.9, 0.76)],
	["C2 — assets neutres + golden hour par Godot (v2 : étalonnage par zones + lisere de soleil)", true,
		Color.WHITE, Color.WHITE],
	["D — assets neutres + fin de journée par Godot", true, Color.WHITE, Color(0.82, 0.66, 0.66)],
]

## Mode par défaut : C2, la méthode retenue par Kevin.
var _mode := 3
var _materiau_sol: ShaderMaterial
var _teinte := CanvasModulate.new()
var _etalonnage := ColorRect.new()
var _materiaux_objets: Array[ShaderMaterial] = []
var _etiquette := Label.new()
## Objets qui ont une variante NE : [sprite, nom de la texture GH].
var _variables: Array = []

var _hasard := RandomNumberGenerator.new()


func _ready() -> void:
	_hasard.seed = 2026
	var cases := _cases_pavees()
	_construire_sol(cases)
	var ombres := Node2D.new()
	ombres.name = "Ombres"
	add_child(ombres)
	var tries := Node2D.new()
	tries.name = "Objets"
	tries.y_sort_enabled = true
	add_child(tries)
	_poser_bordures(cases, ombres)
	_poser_massif(ombres)
	for objet: Array in OBJETS:
		_poser_objet(objet[0], Vector2(objet[1], objet[2]) * CASE, objet[3], tries, ombres)
	_poser_groupes(tries)
	add_child(_camera())
	_journal_fps()
	add_child(_teinte)
	# Étalonnage d'écran (mode C2), sous l'étiquette.
	var calque := CanvasLayer.new()
	calque.layer = 0
	var materiau := ShaderMaterial.new()
	materiau.shader = preload("res://proto/da_jadielle/etalonnage.gdshader")
	_etalonnage.material = materiau
	_etalonnage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_etalonnage.set_anchors_preset(Control.PRESET_FULL_RECT)
	calque.add_child(_etalonnage)
	add_child(calque)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lumiere="):
			_mode = clampi(argument.trim_prefix("--lumiere=").to_int(), 0, MODES_LUMIERE.size() - 1)
	_appliquer_lumiere()


func _input(event: InputEvent) -> void:
	# Seulement le toucher (Android émet aussi un clic simulé).
	if event is InputEventScreenTouch and event.pressed:
		_mode = (_mode + 1) % MODES_LUMIERE.size()
		_appliquer_lumiere()


func _appliquer_lumiere() -> void:
	var mode: Array = MODES_LUMIERE[_mode]
	for entree: Array in _variables:
		var nom: String = entree[1]
		(entree[0] as Sprite2D).texture = load(TEX + (nom.replace(".png", "_ne.png") if mode[1]
			else nom))
	_materiau_sol.set_shader_parameter(&"teinte", mode[2])
	_teinte.color = mode[3]
	var c2 := (mode[0] as String).begins_with("C2")
	_etalonnage.visible = c2
	for materiau in _materiaux_objets:
		materiau.set_shader_parameter(&"force_lisere", 1.0 if c2 else 0.0)
	_etiquette.text = "%s   ·   toucher l'écran pour changer" % mode[0]


## Relevé « [proto-perf] » toutes les 2 s dans le journal (lu par adb logcat sur le S24).
func _journal_fps() -> void:
	var minuterie := Timer.new()
	minuterie.wait_time = 2.0
	minuterie.autostart = true
	minuterie.timeout.connect(func() -> void:
		print("[proto-perf] fps=%d vram_textures_mo=%.1f" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0]))
	add_child(minuterie)


## Caméra du cadrage réel. Pour inspecter un détail à la capture :
## `-- --zoom=2 --vise=8.5,9` (zoom et point visé en cases).
func _camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.position = Vector2(LARGEUR / 2.0, 7.3) * CASE
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--zoom="):
			var zoom := argument.trim_prefix("--zoom=").to_float()
			camera.zoom = Vector2(zoom, zoom)
		elif argument.begins_with("--vise="):
			var vise := argument.trim_prefix("--vise=").split(",")
			camera.position = Vector2(vise[0].to_float(), vise[1].to_float()) * CASE
	return camera


func _cases_pavees() -> Dictionary:
	var cases := {}
	for zone: Rect2i in PAVES:
		for x in range(zone.position.x, zone.end.x):
			for y in range(zone.position.y, zone.end.y):
				cases[Vector2i(x, y)] = true
	return cases


func _construire_sol(cases: Dictionary) -> void:
	var image := Image.create(LARGEUR, HAUTEUR, false, Image.FORMAT_L8)
	for cellule: Vector2i in cases:
		image.set_pixelv(cellule, Color.WHITE)
	var materiau := ShaderMaterial.new()
	materiau.shader = SOL_SHADER
	materiau.set_shader_parameter(&"herbe", load(TEX + "herbe.png"))
	materiau.set_shader_parameter(&"paves", load(TEX + "paves.png"))
	materiau.set_shader_parameter(&"masque", ImageTexture.create_from_image(image))
	_materiau_sol = materiau
	var sol := ColorRect.new()
	sol.name = "Sol"
	sol.size = Vector2(LARGEUR, HAUTEUR) * CASE
	sol.material = materiau
	# Le sol est un contrôle d'interface : il ne doit pas intercepter les touchers.
	sol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sol)


## Décalcomanies le long de la frontière herbe / pavés : terre, pavés déchaussés, touffes.
func _poser_bordures(cases: Dictionary, parent: Node2D) -> void:
	var calque := Node2D.new()
	calque.name = "Bordures"
	parent.add_sibling(calque)
	var voisins: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for cellule: Vector2i in cases:
		for direction in voisins:
			var voisin := cellule + direction
			if cases.has(voisin) or not _dans_la_carte(voisin):
				continue
			# Milieu du côté de la case pavée qui touche l'herbe.
			var bord := (Vector2(cellule) + Vector2(0.5, 0.5) + Vector2(direction) * 0.5) * CASE
			var long_bord := Vector2(absf(direction.y), absf(direction.x))
			for i in 2:
				var point := bord + long_bord * _hasard.randf_range(-40.0, 40.0)
				point += Vector2(direction) * _hasard.randf_range(-8.0, 8.0)
				var tirage := _hasard.randf()
				if tirage < 0.25:
					_decal(calque, "bord_terre_%d.png" % _hasard.randi_range(1, 4), point, 0.45)
				elif tirage < 0.40:
					_decal(calque, "bord_pave_%d.png" % _hasard.randi_range(1, 4), point, 0.4)
				var touffe := point + Vector2(direction) * _hasard.randf_range(-4.0, 10.0)
				_decal(calque, "bord_touffe_%d.png" % _hasard.randi_range(1, 4), touffe, 0.8)


func _decal(parent: Node2D, nom: String, point: Vector2, echelle: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(TEX + nom)
	sprite.position = point
	sprite.scale = Vector2.ONE * echelle * _hasard.randf_range(0.85, 1.15)
	sprite.flip_h = _hasard.randf() < 0.5
	parent.add_child(sprite)


## Massif fleuri : au sol (non trié), sous l'arbre central dont le tronc sort de son trou.
func _poser_massif(ombres: Node2D) -> void:
	var texture: Texture2D = load(TEX + "massif.png")
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = PIED_ARBRE_CENTRAL * CASE - MASSIF_TROU
	ombres.add_sibling(sprite)
	var pied := sprite.position + Vector2(texture.get_width() / 2.0, texture.get_height())
	_contact(texture, pied, 0.25, ombres)


func _poser_objet(nom: String, pied: Vector2, vent: bool, tries: Node2D, ombres: Node2D) -> void:
	var texture: Texture2D = load(TEX + nom)
	var sprite := _sprite_au_pied(texture)
	sprite.position = pied
	var materiau := ShaderMaterial.new()
	materiau.shader = OBJET_SHADER
	materiau.set_shader_parameter(&"force_vent", 5.0 if vent else 0.0)
	sprite.material = materiau
	_materiaux_objets.append(materiau)
	tries.add_child(sprite)
	if nom in VARIANTES_NE:
		_variables.append([sprite, nom])
	_ombre(texture, pied, ombres, Rect2())
	# Ombre de contact : ce qui « pose » l'objet au sol (les bâtiments sur toute leur base).
	_contact(texture, pied, 0.12 if nom.begins_with("centre") or nom.begins_with("boutique") \
		else 0.05, ombres)


func _poser_joueur(pied: Vector2, tries: Node2D, ombres: Node2D) -> void:
	var sprite := _sprite_au_pied(JOUEUR, Rect2(0, 0, 32, 64))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2, 2)
	sprite.position = pied
	tries.add_child(sprite)
	_ombre(JOUEUR, pied, ombres, Rect2(0, 0, 32, 64), 2.0)
	_contact(JOUEUR, pied, 0.1, ombres, Rect2(0, 0, 32, 64), 2.0)


func _sprite_au_pied(texture: Texture2D, region := Rect2()) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	var taille := texture.get_size()
	if region.has_area():
		sprite.region_enabled = true
		sprite.region_rect = region
		taille = region.size
	sprite.offset = Vector2(-taille.x / 2.0, -taille.y)
	return sprite


## Ombre portée vers le bas à droite (soleil en haut à gauche) : la silhouette
## retournée, écrasée et inclinée, floutée et teintée bleu-violet (ombre.gdshader).
## Réglage J7.1 : plus courte, plus légère, bords doux.
func _ombre(texture: Texture2D, pied: Vector2, parent: Node2D, region: Rect2,
		echelle := 1.0) -> void:
	var ombre := _sprite_au_pied(texture, region)
	ombre.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var materiau := ShaderMaterial.new()
	materiau.shader = OMBRE_SHADER
	ombre.material = materiau
	ombre.position = pied
	ombre.scale = Vector2(echelle, -0.26 * echelle)
	ombre.skew = deg_to_rad(-45.0)
	parent.add_child(ombre)


func _dans_la_carte(cellule: Vector2i) -> bool:
	return cellule.x >= 0 and cellule.y >= 0 and cellule.x < LARGEUR and cellule.y < HAUTEUR


## Ombre de contact (contact.gdshader) : la base de la silhouette, décalée vers le bas et
## floutée ; elle assombrit le sol juste contre la base de l'objet, en suivant sa forme.
func _contact(texture: Texture2D, pied: Vector2, part_base: float, parent: Node2D,
		region := Rect2(), echelle := 1.0) -> void:
	var etendue := 18.0
	var sprite := _sprite_au_pied(texture, region)
	var materiau := ShaderMaterial.new()
	materiau.shader = CONTACT_SHADER
	materiau.set_shader_parameter(&"etendue", etendue / echelle)
	materiau.set_shader_parameter(&"part_base", part_base)
	sprite.material = materiau
	sprite.scale = Vector2(echelle, echelle)
	sprite.position = pied + Vector2(0.0, etendue)
	parent.add_child(sprite)


## Jadielle peuplée (J7, personnages peints en lumière neutre). Chaque entrée :
## [texture, coins du circuit en cases (un seul = immobile), pas d'avance, taille d'ombre].
const HABITANTS: Array = [
	["perso_p2", [Vector2i(4, 8), Vector2i(4, 12), Vector2i(8, 12), Vector2i(8, 8)], 0, 1.0],
	["enfant_p2", [Vector2i(17, 11), Vector2i(17, 12), Vector2i(21, 12), Vector2i(21, 11)], 1,
		0.85],
	["rattata_p2", [Vector2i(17, 11), Vector2i(17, 12), Vector2i(21, 12), Vector2i(21, 11)], 0,
		0.6],
	["infirmiere", [Vector2i(5, 7)], 0, 1.0],
	["marchand", [Vector2i(17, 7)], 0, 1.0],
	["livreur", [Vector2i(20, 8), Vector2i(23, 8), Vector2i(23, 10), Vector2i(20, 10)], 0, 1.0],
	["dresseuse", [Vector2i(16, 11)], 0, 1.0],
	["roucool", [Vector2i(15, 11)], 0, 0.6],
	["vieil_homme", [Vector2i(9, 9), Vector2i(10, 9)], 0, 0.95],
	["voyageur", [Vector2i(13, 13), Vector2i(13, 12), Vector2i(2, 12), Vector2i(2, 13)], 0, 1.0],
	["rival", [Vector2i(10, 12), Vector2i(16, 12)], 0, 1.0],
]


func _poser_groupes(tries: Node2D) -> void:
	for habitant: Array in HABITANTS:
		var nom: String = habitant[0]
		var course: Texture2D = null
		if nom == "perso_p2":
			course = load("res://proto/da_jadielle/tex/perso_p2_course.png")
		var coins: Array[Vector2i] = []
		coins.assign(habitant[1])
		var marcheur := _marcheur(load(TEX + nom + ".png"), course, 1.0, false, coins,
			Vector2i.ZERO)
		if nom == "perso_p2":
			marcheur.segments_course.assign([1])
		marcheur.avance_depart = habitant[2]
		marcheur.taille_ombre = habitant[3]
		tries.add_child(marcheur)
	var calque := CanvasLayer.new()
	var etiquette := _etiquette
	etiquette.position = Vector2(32, 24)
	etiquette.add_theme_font_size_override(&"font_size", 34)
	etiquette.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	etiquette.add_theme_constant_override(&"outline_size", 8)
	calque.add_child(etiquette)
	add_child(calque)


func _marcheur(marche: Texture2D, course: Texture2D, echelle: float, pixel: bool,
		coins: Array[Vector2i], decalage: Vector2i) -> Node2D:
	var marcheur: Node2D = preload("res://proto/da_jadielle/marcheur.gd").new()
	marcheur.planche_marche = marche
	marcheur.planche_course = course if course else marche
	marcheur.echelle = echelle
	marcheur.pixel = pixel
	var circuit: Array[Vector2i] = []
	for coin in coins:
		circuit.append(coin + decalage)
	marcheur.circuit = circuit
	return marcheur
