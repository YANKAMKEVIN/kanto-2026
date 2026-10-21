class_name FieldMoveStage
extends RefCounted
## Règles de mise en scène d'une capacité de terrain (jalon 16, Coupe ; `jalon-16.md` §2.3,
## dossier 19 §7) : classe pure, sans scène. [FieldMovePresenter] l'affiche.
##
## - Le Pokémon qui coupe se place **à côté du joueur** (donc de l'arbuste qu'il regarde) : la
##   case à sa droite, puis à sa gauche (par rapport à son regard), puis derrière lui ; la
##   première qui est libre. Aucune : pas de Pokémon montré, seulement l'effet.
## - Déroulé (au plus [constant MAX_DURATION] s) : apparition (ou pas du compagnon resté dehors),
##   effet de coupe, l'obstacle disparaît en fondu, retour dans la Ball (sauf le compagnon).
## - « Réduire les animations » : ni Pokémon ni effet, l'obstacle disparaît en fondu
##   ([constant REDUCED_FADE] s).

## Étapes, dans l'ordre ([signal FieldMovePresenter.stage_started]).
const APPEAR: StringName = &"appear"
const SLASH: StringName = &"slash"
const CLEAR: StringName = &"clear"
const WITHDRAW: StringName = &"withdraw"
## Pas de case.
const NONE := Vector2i(-99999, -99999)
## Durées (s), valeurs par défaut (règle 4) : effet de coupe, fondu de l'obstacle, version
## réduite (`jalon-16.md` §6 : « réduite : fondu 0,3 s »), plafond (dossier 19 : ≤ 2 s).
const SLASH_DURATION: float = 0.35
const CLEAR_FADE: float = 0.3
const REDUCED_FADE: float = 0.3
const MAX_DURATION: float = 2.0
## Capacité sans obstacle (Force) : le Pokémon montré prend appui ce temps-là (s) [D].
const HOLD_DURATION: float = 0.35


## Case du Pokémon qui coupe, pour le joueur sur [param player_cell] tourné vers [param facing] :
## droite, gauche, derrière, la première que [param is_free] (`func(cell) -> bool`) accepte ;
## [constant NONE] sinon (ou regard non cardinal).
static func pick_cell(player_cell: Vector2i, facing: Vector2i, is_free: Callable) -> Vector2i:
	if not Grid.is_cardinal(facing):
		return NONE
	var right := Vector2i(-facing.y, facing.x)
	for offset: Vector2i in [right, -right, -facing]:
		var cell := player_cell + offset
		if bool(is_free.call(cell)):
			return cell
	return NONE


## Étapes jouées, dans l'ordre : [param reduce_motion] (fondu seul), [param shown] (un Pokémon
## est montré), [param is_companion] (c'est le compagnon resté dehors : il ne rentre pas).
## Passe systèmes 2 (Force, §2.7.1) : [param clears] faux = capacité **sans obstacle à retirer**
## (le Pokémon apparaît, prend appui [constant HOLD_DURATION] s, rentre) : ni effet ni fondu.
static func stages(reduce_motion: bool, shown: bool, is_companion: bool,
		clears: bool = true) -> Array[StringName]:
	if not clears:
		if reduce_motion or not shown:
			return [] as Array[StringName]
		if is_companion:
			return [APPEAR] as Array[StringName]
		return [APPEAR, WITHDRAW] as Array[StringName]
	if reduce_motion:
		return [CLEAR] as Array[StringName]
	if not shown:
		return [SLASH, CLEAR] as Array[StringName]
	if is_companion:
		return [APPEAR, SLASH, CLEAR] as Array[StringName]
	return [APPEAR, SLASH, CLEAR, WITHDRAW] as Array[StringName]
