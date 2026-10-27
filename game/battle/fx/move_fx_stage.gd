class_name MoveFxStage
extends RefCounted
## Ce que le lecteur d'effets ([MoveFxPlayer]) sait de la scène pour une attaque (chantier Combat
## vivant, §2.4) : les deux sprites, leur place de repos et leur boîte visible à l'écran, le point
## d'origine de l'effet, les calques du décor peint. Rempli par [BattleStage] (branchement de T3),
## ou par la galerie d'effets et les tests : le lecteur ne lit rien d'autre de la scène.
## Tout est en px du calque du combat.

var user: Sprite2D
var target: Sprite2D
## Position de repos des sprites (pieds) : le lecteur les y rend à la fin.
var user_rest: Vector2 = Vector2.ZERO
var target_rest: Vector2 = Vector2.ZERO
## Boîte visible des Pokémon à leur place ([method BattleStage.get_sprite_rect]).
var user_rect: Rect2 = Rect2()
var target_rect: Rect2 = Rect2()
## Points d'origine de l'effet sur le lanceur (un, ou deux pour une paire : joues, canons…),
## déjà résolus par [FxAnchors] ; vide : le centre de [member user_rect].
var origins: PackedVector2Array = PackedVector2Array()
## Le lanceur est le Pokémon du joueur (de dos, en bas à gauche) : l'effet part vers le haut à
## droite et rapetisse ; sinon il part vers le bas à gauche et grandit (§2.4, en miroir).
var user_is_player: bool = true
## Calques du décor peint (null sans décor : fond flouté du monde).
var decor_back: Sprite2D
var decor_front: Sprite2D
var view_size: Vector2 = Vector2(1920, 1080)


## Origine de l'effet (le milieu d'une paire).
func origin() -> Vector2:
	if origins.is_empty():
		return user_rect.get_center()
	var sum := Vector2.ZERO
	for point: Vector2 in origins:
		sum += point
	return sum / origins.size()


## Point d'impact sur la cible (le centre de sa boîte visible).
func impact_point() -> Vector2:
	return target_rect.get_center()


## Points d'origine en px du calque depuis des points normalisés de [FxAnchors] dans [param rect].
static func to_screen(points: PackedVector2Array, rect: Rect2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(rect.position + point * rect.size)
	return result
