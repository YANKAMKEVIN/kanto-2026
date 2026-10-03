extends Node2D
## Scène prototype de la place de Jadielle (cahier de l'art du monde §5, série 01).
## Jetable : vit seulement sur la branche proto/da-jadielle, ne dépend d'aucun code du jeu.
## Construit la place en code : sol par masque, bordures, ombres, objets triés par les pieds.

const CASE := 96
const LARGEUR := 26
const HAUTEUR := 14
const TEX := "res://proto/da_jadielle/tex/"
const SOL_SHADER := preload("res://proto/da_jadielle/sol.gdshader")
const VENT_SHADER := preload("res://proto/da_jadielle/vent.gdshader")
const JOUEUR := preload("res://assets/sprites/characters/placeholder/player_sheet.png")

## Zones pavées, en cases [x, y, largeur, hauteur].
const PAVES: Array[Rect2i] = [
	Rect2i(2, 5, 22, 8),  # la place, sous et devant les bâtiments
	Rect2i(12, 13, 2, 1),  # départ du chemin vers la Route 1
]
## Îlot d'herbe autour de l'arbre central (le massif viendra en série 02).
const ILOT := Rect2i(12, 9, 2, 2)
## Objets : [texture, x en cases (milieu du pied), y en cases (ligne du pied), vent].
const OBJETS: Array = [
	["centre.png", 7.0, 7.0, false],
	["boutique.png", 19.0, 7.0, false],
	["tree_central.png", 13.0, 10.9, true],
	["tree_b.png", 1.0, 5.0, true],
	["tree_a.png", 1.0, 9.0, true],
	["tree_b.png", 1.2, 13.6, true],
	["tree_a.png", 25.0, 5.5, true],
	["tree_b.png", 24.8, 9.6, true],
	["tree_a.png", 25.0, 13.8, true],
	["tree_a.png", 10.0, 14.2, true],
	["tree_b.png", 16.0, 14.4, true],
]
## Lumière GH : teinte chaude du sol (les objets sont déjà peints en GH).
const TEINTE_SOL := Color(1.0, 0.95, 0.86)
const COULEUR_OMBRE := Color(0.10, 0.09, 0.22, 0.30)

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
	for objet: Array in OBJETS:
		_poser_objet(objet[0], Vector2(objet[1], objet[2]) * CASE, objet[3], tries, ombres)
	_poser_joueur(Vector2(8.5, 9.0) * CASE, tries, ombres)
	add_child(_camera())
	_journal_fps()


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
	camera.position = Vector2(LARGEUR / 2.0, 6.4) * CASE
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
	for x in range(ILOT.position.x, ILOT.end.x):
		for y in range(ILOT.position.y, ILOT.end.y):
			cases.erase(Vector2i(x, y))
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
	materiau.set_shader_parameter(&"teinte", TEINTE_SOL)
	var sol := ColorRect.new()
	sol.name = "Sol"
	sol.size = Vector2(LARGEUR, HAUTEUR) * CASE
	sol.material = materiau
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


func _poser_objet(nom: String, pied: Vector2, vent: bool, tries: Node2D, ombres: Node2D) -> void:
	var texture: Texture2D = load(TEX + nom)
	var sprite := _sprite_au_pied(texture)
	sprite.position = pied
	if vent:
		var materiau := ShaderMaterial.new()
		materiau.shader = VENT_SHADER
		sprite.material = materiau
	tries.add_child(sprite)
	_ombre(texture, pied, ombres, Rect2())


func _poser_joueur(pied: Vector2, tries: Node2D, ombres: Node2D) -> void:
	var sprite := _sprite_au_pied(JOUEUR, Rect2(0, 0, 32, 64))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2, 2)
	sprite.position = pied
	tries.add_child(sprite)
	_ombre(JOUEUR, pied, ombres, Rect2(0, 0, 32, 64), 2.0)


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
## retournée, écrasée et inclinée, teintée bleu-violet.
func _ombre(texture: Texture2D, pied: Vector2, parent: Node2D, region: Rect2,
		echelle := 1.0) -> void:
	var ombre := _sprite_au_pied(texture, region)
	ombre.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ombre.modulate = COULEUR_OMBRE
	ombre.position = pied
	ombre.scale = Vector2(echelle, -0.42 * echelle)
	ombre.skew = deg_to_rad(-38.0)
	parent.add_child(ombre)


func _dans_la_carte(cellule: Vector2i) -> bool:
	return cellule.x >= 0 and cellule.y >= 0 and cellule.x < LARGEUR and cellule.y < HAUTEUR
