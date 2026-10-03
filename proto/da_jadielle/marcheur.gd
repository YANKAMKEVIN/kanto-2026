extends Node2D
## Personnage d'essai du prototype (J7.1) : parcourt un circuit case par case, à la vitesse
## du jeu, avec un cycle de 4 images par direction (planches de `tools/art/decouper_perso.py` :
## lignes bas, gauche, droite, haut). Il court sur les segments listés dans `segments_course`.

const CASE := 96
const DUREE_MARCHE := 0.27  # Grid.WALK_STEP_DURATION
const DUREE_COURSE := 0.16  # Grid.RUN_STEP_DURATION
const LIGNE := {Vector2i.DOWN: 0, Vector2i.LEFT: 1, Vector2i.RIGHT: 2, Vector2i.UP: 3}

var planche_marche: Texture2D
var planche_course: Texture2D
var echelle := 1.0
var pixel := false
## Coins du circuit, en cases.
var circuit: Array[Vector2i] = []
## Pas d'avance au départ (le maître part devant son suiveur).
var avance_depart := 0
## Index des segments (du coin i au coin i + 1) parcourus en courant.
var segments_course: Array[int] = []
var taille_ombre := 1.0
## Grille de déplacement (emprises.gd) : si elle est fournie, le marcheur va d'un coin au
## suivant par le plus court chemin libre, au lieu de traverser les obstacles.
var obstacles: AStarGrid2D

var _corps := Sprite2D.new()
var _case := Vector2i.ZERO
var _cible := 0
var _direction := Vector2i.DOWN
var _temps := 0.0
var _image := 0
var _court := false


func _ready() -> void:
	_tracer_chemin()
	_case = circuit[0]
	for i in avance_depart:
		_avancer_case()
	position = _pied(_case)
	add_child(_ombre())
	_corps.centered = false
	_corps.scale = Vector2.ONE * echelle
	_corps.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel \
		else CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_corps)
	_planche(planche_marche)


func _process(delta: float) -> void:
	if circuit.size() < 2:
		# Personnage immobile : regarde vers le bas, image de repos.
		_direction = Vector2i.DOWN
		_corps.frame = 0
		return
	var court := _cible in segments_course
	if court != _court:
		_court = court
		_planche(planche_course if court else planche_marche)
	var duree := DUREE_COURSE if court else DUREE_MARCHE
	_temps += delta
	var pas := _pas()
	_direction = pas
	var avance := minf(_temps / duree, 1.0)
	position = _pied(_case).lerp(_pied(_case + pas), avance)
	# Quatre images sur deux pas : pas, passage, autre pas, passage.
	_afficher(_image * 2 + (0 if avance < 0.5 else 1))
	if _temps >= duree:
		_temps -= duree
		_avancer_case()
		_image = (_image + 1) % 2


func _tracer_chemin() -> void:
	if obstacles == null or circuit.size() < 2:
		return
	var chemin: Array[Vector2i] = []
	for i in circuit.size():
		var depart := circuit[i]
		var arrivee := circuit[(i + 1) % circuit.size()]
		var troncon := obstacles.get_id_path(depart, arrivee)
		if troncon.is_empty():
			push_warning("Trajet impossible de %s à %s" % [depart, arrivee])
			chemin.append(depart)
			continue
		for j in troncon.size() - 1:
			chemin.append(troncon[j])
	circuit = chemin


func _pas() -> Vector2i:
	var suivante := circuit[(_cible + 1) % circuit.size()]
	var pas := Vector2i(signi(suivante.x - _case.x), signi(suivante.y - _case.y))
	if pas.x != 0 and pas.y != 0:
		pas.y = 0
	return pas


func _avancer_case() -> void:
	_case += _pas()
	if _case == circuit[(_cible + 1) % circuit.size()]:
		_cible = (_cible + 1) % circuit.size()


func _pied(case_grille: Vector2i) -> Vector2:
	return (Vector2(case_grille) + Vector2(0.5, 0.85)) * CASE


func _planche(texture: Texture2D) -> void:
	_corps.texture = texture
	_corps.hframes = 4
	_corps.vframes = 4
	var cellule := texture.get_size() / 4.0
	_corps.offset = Vector2(-cellule.x / 2.0, -cellule.y)


func _afficher(image: int) -> void:
	# Colonnes des planches : 0 passage, 1 pas gauche, 2 passage, 3 pas droit.
	var colonne: int = [1, 2, 3, 0][posmod(image, 4)]
	_corps.frame = int(LIGNE[_direction]) * 4 + colonne


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
	ombre.scale = Vector2(1.0, 0.32) * taille_ombre
	ombre.position = Vector2(4, 0)
	return ombre
