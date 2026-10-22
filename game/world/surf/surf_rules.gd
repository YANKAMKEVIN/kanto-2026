class_name SurfRules
extends RefCounted
## Règles du Surf hors combat (jalon 24, T6 ; dossier 27 §5, `jalon-24.md` §2.2) : classe pure et
## statique, sans nœud. Les conditions (CS03, Badge Âme, Pokémon compatible) viennent de
## [FieldMoves] (`status(&"surf")`, données du J23) : elles arrivent ici déjà évaluées, sous forme
## d'un [enum FieldMoves.State].
##
## Le joueur est **en Surf** quand il est sur une eau surfable ([method GridWorld.is_surfable]) :
## monter = un pas de la terre vers l'eau ([method can_mount]) ; en mer, chaque pas nage ou
## descend ([method step_kind]) ; au chargement, [method resume] choisit la case et le mode
## (garde-fou du §5.7). [method find_reachable] parcourt une carte à pied **et** en Surf (tests
## d'anti-blocage, garde-fou générique des Îles Écume).
##
## Niveaux de sol (Îles Écume) : l'eau est au niveau du sol bas ; on ne monte ni ne descend depuis
## ou vers le sol haut ([method GridWorld.levels_compatible]).

## Réponse de [method can_mount], face à une case (nommée `Mount` au J24 : renommée, [Mount] est
## la monture du joueur).
enum MountCheck {
	READY, ## On peut monter (bouton SURFER).
	NO_HM, ## Eau surfable, mais pas de CS03 (texte T-1).
	NO_BADGE, ## CS sans badge (T-2).
	NO_POKEMON, ## Aucun Pokémon compatible (T-1, variante).
	NOT_WATER, ## Pas face à une eau surfable, ou déjà en mer (« Impossible ici. », T-4).
	BLOCKED, ## Eau surfable, mais occupée (rocher, Nageur) ou hors de portée (sol haut).
	FORBIDDEN, ## Départ interdit tant qu'un courant est actif (B4F, T-14).
}

## Nature d'un pas en Surf ([method step_kind]).
enum StepKind {
	SWIM, ## Eau surfable libre : on nage.
	DISMOUNT, ## Terre praticable libre : on descend (le joueur repasse à pied).
	BLOCKED, ## Tout le reste.
}

## Raison du choix de [method resume].
enum ResumeReason {
	AS_SAVED, ## La case sauvegardée, dans son mode.
	LAST_LAND, ## Garde-fou : la dernière case de terre de la carte.
	SPAWN, ## Garde-fou : le point d'arrivée de la carte.
	NO_EXIT, ## Garde-fou générique : aucune sortie atteignable, retour au point d'arrivée.
}

const _DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]


## Reprise d'une partie ([method resume]) : la case, le mode, la raison. [member ride_current] :
## la case est un courant actif, la glissade doit partir dès l'arrivée (cas limite 2).
class Resume:
	extends RefCounted
	var cell: Vector2i = Vector2i.ZERO
	var mount: Mount.Kind = Mount.Kind.NONE
	var reason: ResumeReason = ResumeReason.AS_SAVED
	var ride_current: bool = false

	func _init(p_cell: Vector2i = Vector2i.ZERO, p_mount: Mount.Kind = Mount.Kind.NONE,
			p_reason: ResumeReason = ResumeReason.AS_SAVED) -> void:
		cell = p_cell
		mount = p_mount
		reason = p_reason

	func is_surfing() -> bool:
		return mount == Mount.Kind.SURF


## Le joueur à pied en [param from], tourné vers [param direction], peut-il monter ?
## [param field_state] : `FieldMoves.status(&"surf")` ; [param forbidden] : [param from] est un
## départ interdit tant qu'un courant est actif (donnée `surf_forbidden` de la carte, déjà
## évaluée par l'appelant). Ordre : NOT_WATER, BLOCKED, conditions (NO_HM…), FORBIDDEN, READY.
static func can_mount(grid: GridWorld, from: Vector2i, direction: Vector2i,
		field_state: FieldMoves.State, forbidden: bool = false, mover: Object = null) -> MountCheck:
	var target := from + direction
	if grid == null or not Grid.is_cardinal(direction) or grid.is_surfable(from) \
			or not grid.is_surfable(target):
		return MountCheck.NOT_WATER
	if not grid.can_enter_as(target, direction, GridWorld.MoveMode.SURF, mover):
		return MountCheck.BLOCKED
	match field_state:
		FieldMoves.State.NO_HM:
			return MountCheck.NO_HM
		FieldMoves.State.NO_BADGE:
			return MountCheck.NO_BADGE
		FieldMoves.State.NO_POKEMON:
			return MountCheck.NO_POKEMON
	if forbidden:
		return MountCheck.FORBIDDEN
	return MountCheck.READY


## Le pas de [param from] vers [param direction], en Surf : SWIM, DISMOUNT ou BLOCKED.
static func step_kind(grid: GridWorld, from: Vector2i, direction: Vector2i,
		mover: Object = null) -> StepKind:
	if grid == null:
		return StepKind.BLOCKED
	var target := from + direction
	if not grid.can_enter_as(target, direction, GridWorld.MoveMode.SURF, mover):
		return StepKind.BLOCKED
	return StepKind.SWIM if grid.is_surfable(target) else StepKind.DISMOUNT


## Reprise d'une partie (dossier §5.7), monture sauvegardée [param saved_mount] :
## - en Surf sur une eau surfable libre, conditions réunies ([param field_state] READY) → en Surf ;
## - sur une terre libre → à pied, ou à Vélo si [param saved_mount] est le Vélo
##   ([method MountRules.on_map_entered] décide ensuite selon la carte) ;
## - sinon : [param last_land] s'il est une terre libre, à défaut [param spawn] (en Surf si
##   [param spawn] est une eau surfable : arrivée en Surf forcé).
## **Garde-fou générique** (Îles Écume) : si [param has_exit] est valide et rend faux pour la case
## choisie (appel `has_exit.call(cell) -> bool`), retour à [param spawn]. Voir [method reaches_any].
static func resume(grid: GridWorld, saved_cell: Vector2i, saved_mount: Mount.Kind,
		last_land: Vector2i, spawn: Vector2i, field_state: FieldMoves.State,
		has_exit: Callable = Callable(), mover: Object = null) -> Resume:
	var on_land := Mount.Kind.BIKE if saved_mount == Mount.Kind.BIKE else Mount.Kind.NONE
	var result: Resume
	if saved_mount == Mount.Kind.SURF and grid.is_surfable(saved_cell) \
			and _is_unoccupied(grid, saved_cell, mover) and field_state == FieldMoves.State.READY:
		result = Resume.new(saved_cell, Mount.Kind.SURF)
	elif _is_land(grid, saved_cell, mover):
		result = Resume.new(saved_cell, on_land)
	elif _is_land(grid, last_land, mover):
		result = Resume.new(last_land, on_land, ResumeReason.LAST_LAND)
	else:
		result = Resume.new(spawn, _mount_at(grid, spawn, on_land), ResumeReason.SPAWN)
	if result.reason != ResumeReason.SPAWN and has_exit.is_valid() \
			and not bool(has_exit.call(result.cell)):
		result = Resume.new(spawn, _mount_at(grid, spawn, on_land), ResumeReason.NO_EXIT)
	result.ride_current = result.is_surfing() and grid.is_current(result.cell)
	return result


## Case d'arrivée d'un pas de [param from] vers [param direction], à pied ou en Surf selon le
## terrain de [param from] : sur l'eau, nager ou descendre ; sur la terre, marcher, ou monter si
## [param can_surf] et que [param from] n'est pas dans [param no_mount]. [param from] si le pas
## est impossible. Les courants ne sont pas suivis ici (voir [method find_reachable]).
static func next_cell(grid: GridWorld, from: Vector2i, direction: Vector2i, can_surf: bool,
		no_mount: Dictionary = {}, mover: Object = null) -> Vector2i:
	if grid.is_surfable(from):
		return grid.get_step_target_as(from, direction, GridWorld.MoveMode.SURF, mover)
	var walk := grid.get_step_target_as(from, direction, GridWorld.MoveMode.WALK, mover)
	if walk != from or not can_surf or no_mount.has(from):
		return walk
	var target := from + direction
	if grid.is_surfable(target) \
			and grid.can_enter_as(target, direction, GridWorld.MoveMode.SURF, mover):
		return target
	return from


## Cases atteintes depuis [param start] à pied et, si [param can_surf], en Surf (monter, nager,
## descendre). [param terminals] : cases où l'on est transféré en y entrant (échelles, passages,
## entrées, trous ouverts) : comptées mais jamais dépassées. Un pas sur un **courant** actif mène
## à la fin de sa glissade ([method CurrentField.ride], fin sur un terminal comprise) ; le joueur
## ne s'arrête jamais sur un courant actif. Alloue : pour les tests et le chargement, jamais à
## chaque image.
static func find_reachable(grid: GridWorld, start: Vector2i, can_surf: bool,
		terminals: Dictionary = {}, no_mount: Dictionary = {},
		mover: Object = null) -> Dictionary[Vector2i, bool]:
	var reached: Dictionary[Vector2i, bool] = {}
	if grid == null or not grid.is_in_bounds(start):
		return reached
	reached[start] = true
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if terminals.has(cell) and cell != start:
			continue
		for direction: Vector2i in _DIRECTIONS:
			var target := next_cell(grid, cell, direction, can_surf, no_mount, mover)
			if target == cell:
				continue
			if grid.is_current(target) and not terminals.has(target):
				var ride := CurrentField.ride(grid, target, terminals, mover)
				if not ride.is_ok():
					continue
				target = ride.end
			if not reached.has(target):
				reached[target] = true
				queue.append(target)
	return reached


## Vrai si une case de [param exits] est atteignable depuis [param start] ([method
## find_reachable] ; les sorties sont aussi des terminaux). Sert de [code]has_exit[/code] à
## [method resume].
static func reaches_any(grid: GridWorld, start: Vector2i, exits: Dictionary, can_surf: bool,
		terminals: Dictionary = {}, no_mount: Dictionary = {}, mover: Object = null) -> bool:
	var stops := terminals.duplicate()
	stops.merge(exits)
	var reached := find_reachable(grid, start, can_surf, stops, no_mount, mover)
	for cell: Vector2i in reached:
		if exits.has(cell):
			return true
	return false


## Terre où l'on peut se tenir : dans la carte, ni eau, ni solide, ni rebord, libre.
static func _is_land(grid: GridWorld, cell: Vector2i, mover: Object) -> bool:
	return grid.is_free(cell, mover)


## En Surf sur une eau surfable (arrivée en Surf forcé), sinon [param on_land].
static func _mount_at(grid: GridWorld, cell: Vector2i, on_land: Mount.Kind) -> Mount.Kind:
	return Mount.Kind.SURF if grid.is_surfable(cell) else on_land


static func _is_unoccupied(grid: GridWorld, cell: Vector2i, mover: Object) -> bool:
	var occupant := grid.get_occupant(cell)
	return occupant == null or occupant == mover
