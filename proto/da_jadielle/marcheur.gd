extends Node2D
## Personnage d'essai du prototype (J7.1) : fait le tour de la place case par case, à la
## vitesse de marche du jeu, avec un cycle de 4 images. Toucher l'écran passe d'une piste à
## l'autre (pixel art détaillé 64 px, peint simplifié, repère provisoire).

const CASE := 96
const DUREE_PAS := 0.27  # Grid.WALK_STEP_DURATION
## Pistes : [nom affiché, texture, colonnes, lignes, échelle, filtre pixel].
const PISTES: Array = [
	["Piste 1 — pixel art détaillé 64 px (×2)", "res://proto/da_jadielle/tex/perso_p1.png",
		4, 4, 2.0, true],
	["Piste 2 — peint simplifié (128 px)", "res://proto/da_jadielle/tex/perso_p2.png",
		4, 4, 1.0, false],
	["Repère — sprite provisoire actuel", "res://assets/sprites/characters/placeholder/player_sheet.png",
		3, 4, 2.0, true],
]
## Lignes des planches : bas, gauche, droite, haut (le repère : bas, haut, gauche, droite).
const LIGNE := {Vector2i.DOWN: 0, Vector2i.LEFT: 1, Vector2i.RIGHT: 2, Vector2i.UP: 3}
const LIGNE_REPERE := {Vector2i.DOWN: 0, Vector2i.UP: 1, Vector2i.LEFT: 2, Vector2i.RIGHT: 3}

## Circuit, en cases (coins du tour de la place).
@export var circuit: Array[Vector2i] = [Vector2i(5, 7), Vector2i(5, 12), Vector2i(20, 12),
	Vector2i(20, 7)]

var _piste := 0
var _corps := Sprite2D.new()
var _etiquette := Label.new()
var _case := Vector2i.ZERO
var _cible := 0
var _direction := Vector2i.DOWN
var _temps := 0.0
var _image := 0


func _ready() -> void:
	_case = circuit[0]
	position = _pied(_case)
	add_child(_ombre())
	_corps.centered = false
	add_child(_corps)
	var calque := CanvasLayer.new()
	_etiquette.position = Vector2(32, 24)
	_etiquette.add_theme_font_size_override(&"font_size", 34)
	_etiquette.add_theme_color_override(&"font_color", Color.WHITE)
	_etiquette.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	_etiquette.add_theme_constant_override(&"outline_size", 8)
	calque.add_child(_etiquette)
	add_child(calque)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--perso="):
			_piste = clampi(argument.trim_prefix("--perso=").to_int() - 1, 0, PISTES.size() - 1)
	_appliquer_piste()


func _input(event: InputEvent) -> void:
	# Seulement le toucher : Android émet aussi un clic simulé (un seul geste = une piste) ;
	# sur le Mac, le clic est converti en toucher (pointing/emulate_touch_from_mouse).
	if event is InputEventScreenTouch and event.pressed:
		_piste = (_piste + 1) % PISTES.size()
		_appliquer_piste()


func _process(delta: float) -> void:
	_temps += delta
	var suivante := circuit[(_cible + 1) % circuit.size()]
	if _case == suivante:
		_cible = (_cible + 1) % circuit.size()
		return
	var pas := Vector2i(signi(suivante.x - _case.x), signi(suivante.y - _case.y))
	if pas.x != 0 and pas.y != 0:
		pas.y = 0
	_direction = pas
	var avance := minf(_temps / DUREE_PAS, 1.0)
	position = _pied(_case).lerp(_pied(_case + pas), avance)
	# Deux images par pas : passage puis pas (gauche, puis droite au pas suivant).
	var image_du_pas := 1 if avance < 0.5 else 0
	_afficher(_image * 2 + image_du_pas if image_du_pas == 1 else (_image * 2 + 2) % 4)
	if _temps >= DUREE_PAS:
		_temps -= DUREE_PAS
		_case += pas
		_image = (_image + 1) % 2


func _pied(case_grille: Vector2i) -> Vector2:
	return (Vector2(case_grille) + Vector2(0.5, 0.85)) * CASE


func _appliquer_piste() -> void:
	var piste: Array = PISTES[_piste]
	_corps.texture = load(piste[1])
	_corps.hframes = piste[2]
	_corps.vframes = piste[3]
	_corps.scale = Vector2.ONE * piste[4]
	_corps.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if piste[5] \
		else CanvasItem.TEXTURE_FILTER_LINEAR
	var cellule := _corps.texture.get_size() / Vector2(piste[2], piste[3])
	_corps.offset = Vector2(-cellule.x / 2.0, -cellule.y)
	_etiquette.text = "%s  ·  toucher l'écran pour changer" % piste[0]
	_afficher(0)


func _afficher(image: int) -> void:
	var repere := _piste == PISTES.size() - 1
	var ligne: int = (LIGNE_REPERE if repere else LIGNE)[_direction]
	# Le repère n'a que 3 images (pas, repos, pas) : on boucle 1-0-1-2.
	var colonne: int = [1, 0, 1, 2][image] if repere else image
	_corps.frame = ligne * _corps.hframes + colonne


func _ombre() -> Sprite2D:
	var degrade := Gradient.new()
	degrade.set_color(0, Color(0.10, 0.08, 0.20, 0.42))
	degrade.set_color(1, Color(0.10, 0.08, 0.20, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = degrade
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	var ombre := Sprite2D.new()
	ombre.texture = texture
	ombre.scale = Vector2(1.0, 0.32)
	ombre.position = Vector2(4, 0)
	return ombre
