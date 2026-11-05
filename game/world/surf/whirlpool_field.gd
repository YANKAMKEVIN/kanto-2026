class_name WhirlpoolField
extends Node2D
## Tourbillons de la Route 41 (Chapitre Johto, JOH7, `docs/tech/jalon-joh7.md` §2.1 ; dossier JOH-08
## §8, JH-48 : pas de Siphon, les tourbillons sont du **décor infranchissable** qui dessine les
## chenaux). Dessin seul : les cases sont bloquées par la carte (`blocked_cells`) et l'examen (M-4)
## est un [InteractPoint] posé par l'outil de construction. Une spirale d'écume peinte qui tourne
## sur chaque case de [member cells].

## Cases des tourbillons.
@export var cells: Array[Vector2i] = []

const TEXTURE: Texture2D = preload("res://assets/world/fx/fx_tourbillon_01.png")
const TURN_SPEED: float = 2.4
## Diamètre de la spirale, en cases.
const DIAMETER: float = 1.02

var _time: float = 0.0


func _process(delta: float) -> void:
	if cells.is_empty() or not is_visible_in_tree():
		return
	_time = fmod(_time + delta, 3600.0)
	queue_redraw()


func _draw() -> void:
	var tile := float(Grid.TILE_SIZE)
	# QA A17 : seuls les tourbillons à l'écran sont dessinés (la Route 41 en compte ~150 : 36 i/s
	# sans ce tri, 795 appels de dessin).
	var view := _visible_rect().grow(tile)
	for cell: Vector2i in cells:
		var center := (Vector2(cell) + Vector2(0.5, 0.5)) * tile - position
		if not view.has_point(center):
			continue
		# Phase propre à chaque case : les tourbillons voisins ne tournent pas en bloc.
		var phase := _time * TURN_SPEED + float((cell.x * 7 + cell.y * 13) % 11) * 0.6
		draw_set_transform(center, -phase, Vector2.ONE * (tile * DIAMETER / TEXTURE.get_width()))
		draw_texture(TEXTURE, -TEXTURE.get_size() / 2.0)
	draw_set_transform(Vector2.ZERO)


## Rectangle visible, dans le repère local (tout le champ hors d'un arbre de scène).
func _visible_rect() -> Rect2:
	if not is_inside_tree():
		return Rect2(-1e9, -1e9, 2e9, 2e9)
	var to_local := get_global_transform_with_canvas().affine_inverse()
	return to_local * get_viewport_rect()
