class_name WarpPoint
extends Marker2D
## Passage posé dans une carte (enfant de `Warps`) : porte, tapis de sortie, escalier.
##
## Donnée de carte visible dans l'éditeur (croix du Marker2D). La position est celle
## de la case, au pied (Grid.cell_to_world). [GameMap] convertit chaque WarpPoint en
## [Warp] (donnée pure) et le range dans sa [WarpTable]. Voir docs/tech/jalon-02.md §2.3.

## STEP_ON : un pas terminé sur la case ; PUSH : pousser depuis la case.
@export var trigger: Warp.Trigger = Warp.Trigger.STEP_ON
## STEP_ON : direction de pas exigée (ZERO = toutes) ; PUSH : direction de poussée.
@export var direction: Vector2i = Vector2i.ZERO
@export var target_map: StringName = &""
@export var target_spawn: StringName = &""
## Orientation à l'arrivée (ZERO = garder celle du joueur).
@export var arrival_facing: Vector2i = Vector2i.ZERO
## Destination « à venir » (build de développement) : libellé affiché (« JADIELLE »). Vide :
## passage ordinaire. Sinon `target_map` est ignoré et `target_spawn` désigne le point de
## retour sur la carte courante (voir [Warp]).
@export var coming_soon: String = ""
## Passe systèmes 2 (§2.9) : porte ordinaire ou téléporteur ([enum Warp.Style]).
@export var style: Warp.Style = Warp.Style.DOOR


## Case du passage, déduite de la position.
func get_cell() -> Vector2i:
	return Grid.world_to_cell(position)


## Donnée pure équivalente.
func to_warp() -> Warp:
	return Warp.new(get_cell(), trigger, direction, target_map, target_spawn, arrival_facing,
		coming_soon, style)
