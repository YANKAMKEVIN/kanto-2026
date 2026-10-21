class_name SpinTileRules
extends RefCounted
## Règle des dalles tournantes (jalon 20 T4, docs/tech/jalon-20.md §2.4, dossier 23 §13.3).
## Classe pure et statique, sans nœud : le directeur (T19) et les tests s'en servent.
##
## Posé sur une dalle (flèche), le joueur glisse **case par case** dans sa direction ; chaque
## dalle rencontrée change la direction ; la glisse s'arrête sur la **première case d'arrêt**.
## Déterministe : même dalle, même trajet. Une case ni dalle ni arrêt se traverse tout droit.
##
## Données (déclarées dans la carte, `SpinTileField`) : [param arrows] case → direction
## (vecteur cardinal), [param stops] cases d'arrêt. [param walkable] : `func(cell: Vector2i)
## -> bool`, vrai si la case est praticable (sol de la carte, sans obstacle).
## Caractères des grilles `tools/plans/repaire_b*.txt` : `<` `>` `^` `v` (dalles), `o` (arrêt).

const ARROW_CHARS: String = "<>^v"
const STOP_CHAR: String = "o"
const DEFAULT_MAX_STEPS: int = 256

const _COMPASS: Dictionary[Vector2i, String] = {
	Vector2i.UP: "N", Vector2i.DOWN: "S", Vector2i.RIGHT: "E", Vector2i.LEFT: "O",
}


## Trajet depuis la dalle [param start] (voir [SpinSlide]). Le trajet finit sur une case d'arrêt
## (OK), ou s'interrompt sur une erreur de données : case suivante non praticable (BLOCKED),
## cycle (LOOP), plus de [param max_steps] pas (TOO_LONG). [member SpinSlide.end] est alors la
## dernière case atteinte.
static func slide(start: Vector2i, arrows: Dictionary, stops: Array[Vector2i],
		walkable: Callable, max_steps: int = DEFAULT_MAX_STEPS) -> SpinSlide:
	var result := SpinSlide.new()
	result.start = start
	result.end = start
	if not arrows.has(start):
		result.status = SpinSlide.Status.NOT_AN_ARROW
		return result
	var direction: Vector2i = arrows[start]
	var cell := start
	var seen: Dictionary[Vector4i, bool] = {}
	seen[Vector4i(cell.x, cell.y, direction.x, direction.y)] = true
	while result.cells.size() < max_steps:
		var next := cell + direction
		if not walkable.call(next):
			result.status = SpinSlide.Status.BLOCKED
			return result
		result.cells.append(next)
		result.facings.append(direction)
		cell = next
		result.end = cell
		if stops.has(cell):
			result.status = SpinSlide.Status.OK
			return result
		if arrows.has(cell):
			direction = arrows[cell]
		var state := Vector4i(cell.x, cell.y, direction.x, direction.y)
		if seen.has(state):
			result.status = SpinSlide.Status.LOOP
			return result
		seen[state] = true
	result.status = SpinSlide.Status.TOO_LONG
	return result


## Une erreur (texte) par dalle qui ne mène pas à une case d'arrêt praticable ; vide si toutes
## les dalles sont bonnes. Vérifie aussi que les dalles ont une direction cardinale et que les
## cases d'arrêt sont praticables et ne sont pas des dalles.
static func check_field(arrows: Dictionary, stops: Array[Vector2i],
		walkable: Callable) -> PackedStringArray:
	var errors: PackedStringArray = []
	for stop: Vector2i in stops:
		if not walkable.call(stop):
			errors.append("arrêt %s : case non praticable" % stop)
		if arrows.has(stop):
			errors.append("arrêt %s : aussi une dalle" % stop)
	for cell: Vector2i in arrows:
		if not walkable.call(cell):
			errors.append("dalle %s : case non praticable" % cell)
		var direction: Vector2i = arrows[cell]
		if not Grid.is_cardinal(direction):
			errors.append("dalle %s : direction %s non cardinale" % [cell, direction])
			continue
		var result := slide(cell, arrows, stops, walkable)
		if not result.is_ok():
			errors.append("dalle %s : %s après « %s » (case %s)" % [cell,
				SpinSlide.Status.keys()[result.status], result.path_text(), result.end])
	return errors


## Case **stable** pour une reprise : [param cell] si ce n'est pas une dalle, sinon la case
## d'arrêt de sa glisse (ou [param cell] si la glisse est en erreur de données).
static func safe_cell(cell: Vector2i, arrows: Dictionary, stops: Array[Vector2i],
		walkable: Callable) -> Vector2i:
	if not arrows.has(cell):
		return cell
	var result := slide(cell, arrows, stops, walkable)
	return result.end if result.is_ok() else cell


## Direction d'un caractère de grille (`<` `>` `^` `v`) ; ZERO pour tout autre caractère.
static func direction_of_char(character: String) -> Vector2i:
	match character:
		"<":
			return Vector2i.LEFT
		">":
			return Vector2i.RIGHT
		"^":
			return Vector2i.UP
		"v":
			return Vector2i.DOWN
	return Vector2i.ZERO


## Lettre de boussole d'une direction (N, S, E, O ; « ? » si non cardinale), format des trajets
## `trajet=` des grilles.
static func compass_letter(direction: Vector2i) -> String:
	return _COMPASS.get(direction, "?")


## Direction d'une lettre de boussole (N, S, E, O) ; ZERO sinon.
static func compass_direction(letter: String) -> Vector2i:
	for direction: Vector2i in _COMPASS:
		if _COMPASS[direction] == letter:
			return direction
	return Vector2i.ZERO
