class_name InteractionFinder
extends RefCounted
## Trouve la cible d'interaction du joueur : la case **devant lui** (docs/tech/jalon-03.md
## §2.2).
##
## Règle unique, sans scène : on regarde la case voisine dans l'orientation du joueur.
## 1. Si une entité l'occupe et qu'elle expose [code]get_interaction() -> Interaction[/code]
##    (PNJ, Pokémon du décor), c'est elle : parler ou observer.
## 2. Sinon, le point fixe de la [InteractionTable] de la carte sur cette case, s'il
##    accepte l'orientation du joueur : examiner.
## Jalon 11 (compagnon, `jalon-11-compagnon.md` §2.5) : le compagnon n'occupe pas la grille ;
## un fournisseur facultatif ([param companion], un objet qui expose
## [code]get_interaction_at(cell) -> Interaction[/code], null s'il n'est pas visible sur la case)
## est consulté après les occupants, avant les points fixes.
## Rien derrière ni sur les côtés : le bouton contextuel n'apparaît que face à la cible.
## Aucune allocation : appelable à chaque image.

const _METHOD: StringName = &"get_interaction"
const _COMPANION_METHOD: StringName = &"get_interaction_at"


## Cible devant un joueur en [param cell] orienté vers [param facing], ou null.
## [param grid] ou [param table] peuvent être null.
static func find(grid: GridWorld, table: InteractionTable, cell: Vector2i,
		facing: Vector2i, companion: Object = null) -> Interaction:
	if not Grid.is_cardinal(facing):
		return null
	var target := cell + facing
	if grid != null:
		var occupant := grid.get_occupant(target)
		if occupant != null and occupant.has_method(_METHOD):
			var interaction := occupant.call(_METHOD) as Interaction
			if interaction != null and interaction.accepts(facing):
				return interaction
	if companion != null and companion.has_method(_COMPANION_METHOD):
		var with_companion := companion.call(_COMPANION_METHOD, target) as Interaction
		if with_companion != null and with_companion.accepts(facing):
			return with_companion
	if table != null:
		return table.find(target, facing)
	return null
