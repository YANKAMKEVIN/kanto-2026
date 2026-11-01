class_name Boulder
extends Node2D
## Rocher de Force dans le monde (passe systèmes 2, `docs/tech/systemes-2.md` §2.7.2) :
## présentation seule. Occupant de la grille ([method GridWorld.occupy]) sur sa case, origine aux
## pieds comme les autres occupants ; les règles de poussée sont dans [BoulderRules] et
## [BoulderField], la mise en scène dans [StrengthDirector].
##
## - **EXAMINER** : tant que Force n'est pas active, [method get_interaction] rend une
##   interaction EXAMINER (`strength_boulder`) dont la source est le rocher ([InteractionFinder]
##   la trouve par la grille, comme un PNJ).
## - **Glissade** ([method slide]) : l'occupation passe tout de suite à la case visée, l'image
##   suit en [constant SLIDE_DURATION] s.
## - **Refus** ([method shake]) : tremblement sur place, sans texte.
## - **Chute** ([method fall]) : la case est libérée tout de suite, le rocher s'enfonce et
##   disparaît en fondu ; [StrengthDirector] le libère ensuite.
##
## Image peinte `prop_rocher_force_01` (série 27, dossier 27 §6.4 : « arrondis, plus clairs, une
## fissure » ; lot DAF.10c, RP-275), pied au bas de la case, ombre au sol dessinée.

## Dialogue d'EXAMINER (variantes `field: "strength:<état>"`, `data/dialogues/strength.json`).
const EXAMINE_DIALOGUE: StringName = &"strength_boulder"
## Durées (s), valeurs par défaut (règle 4) : glissade (§2.7.2 [D]), tremblement, chute.
const SLIDE_DURATION: float = 0.3
const SHAKE_DURATION: float = 0.24
const FALL_DURATION: float = 0.35
## Amplitude du tremblement (px monde) et enfoncement de la chute.
const SHAKE_AMPLITUDE: float = 6.0
const FALL_DEPTH: float = 40.0
## Image peinte et ombre au sol (px monde).
const IMAGE: Texture2D = preload("res://assets/world/props/prop_rocher_force_01.png")
const SHADOW_SIZE := Vector2(46.0, 13.0)
const COLOR_SHADOW := Color(0.0, 0.0, 0.0, 0.3)

var _grid: GridWorld
var _cell: Vector2i = Vector2i.ZERO
var _examinable: bool = true
var _interaction: Interaction
## Décalage horizontal du tremblement et enfoncement de la chute (dessin seulement).
var _shake_offset: float = 0.0
var _sink: float = 0.0
var _tween: Tween


func _draw() -> void:
	if _sink == 0.0:
		draw_set_transform(Vector2(_shake_offset, -4.0), 0.0, SHADOW_SIZE / SHADOW_SIZE.x)
		draw_circle(Vector2.ZERO, SHADOW_SIZE.x, COLOR_SHADOW)
		draw_set_transform(Vector2.ZERO)
	var size := IMAGE.get_size()
	draw_texture(IMAGE, Vector2(_shake_offset - size.x / 2.0, -size.y - 2.0 + _sink))


## Pose le rocher sur [param cell] de [param grid] (occupant) ; faux si la case est prise.
func place(grid: GridWorld, cell: Vector2i) -> bool:
	if grid == null or not grid.occupy(cell, self):
		return false
	_grid = grid
	_set_cell(cell)
	position = Grid.cell_to_world(cell)
	return true


func get_cell() -> Vector2i:
	return _cell


## Interaction EXAMINER (null quand Force est active : rien à proposer, on pousse).
func get_interaction() -> Interaction:
	return _interaction if _examinable else null


func set_examinable(examinable: bool) -> void:
	_examinable = examinable


func is_examinable() -> bool:
	return _examinable


## Vrai pendant une glissade, un tremblement ou une chute.
func is_animating() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## Glisse vers [param cell] (case voisine libre, vérifiée par [BoulderRules]) : l'occupation
## change tout de suite (le joueur peut entrer dans la case quittée), l'image suit. Rend le tween
## à attendre (null si la case est prise).
func slide(cell: Vector2i) -> Tween:
	if _grid != null and not _grid.move_occupant(self, _cell, cell):
		push_error("Boulder : case %s prise, glissade annulée" % cell)
		return null
	_set_cell(cell)
	_tween = create_tween()
	_tween.tween_property(self, ^"position", Grid.cell_to_world(cell), SLIDE_DURATION)
	return _tween


## Tremble sur place (refus de poussée). Rend le tween.
func shake() -> Tween:
	if is_animating():
		return _tween
	_tween = create_tween()
	var quarter := SHAKE_DURATION / 4.0
	for offset: float in [SHAKE_AMPLITUDE, -SHAKE_AMPLITUDE, SHAKE_AMPLITUDE * 0.5, 0.0]:
		_tween.tween_method(_set_shake, _shake_offset, offset, quarter)
	_tween.tween_callback(_set_shake.bind(0.0))
	return _tween


## Glisse dans le trou de [param cell], s'y enfonce et disparaît en fondu ; la case quittée est
## libérée tout de suite, le trou n'est jamais occupé. Caché à la fin (le directeur le libère).
## Rend le tween.
func fall(cell: Vector2i) -> Tween:
	if _grid != null:
		_grid.release(_cell, self)
	_set_cell(cell)
	_examinable = false
	_tween = create_tween()
	_tween.tween_property(self, ^"position", Grid.cell_to_world(cell), SLIDE_DURATION)
	_tween.tween_method(_set_sink, 0.0, FALL_DEPTH, FALL_DURATION)
	_tween.parallel().tween_property(self, ^"modulate:a", 0.0, FALL_DURATION)
	_tween.tween_callback(hide)
	return _tween


## Retire le rocher de la grille (carte quittée, rocher libéré).
func leave_grid() -> void:
	if _grid != null:
		_grid.release(_cell, self)
	_grid = null


func _set_cell(cell: Vector2i) -> void:
	_cell = cell
	_interaction = Interaction.new(Interaction.Kind.EXAMINE, cell, EXAMINE_DIALOGUE,
		Vector2i.ZERO, self)


func _set_shake(value: float) -> void:
	_shake_offset = value
	queue_redraw()


func _set_sink(value: float) -> void:
	_sink = value
	queue_redraw()
