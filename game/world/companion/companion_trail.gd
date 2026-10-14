class_name CompanionTrail
extends RefCounted
## Où va le compagnon (jalon 11, dossier 14 §8.4 ; `docs/tech/jalon-11-compagnon.md` §2.3) :
## logique pure, aucune scène.
##
## Le compagnon suit **la case que le joueur vient de quitter** : au départ de chaque pas du joueur
## `(from, to, kind)`, il part vers `from`, à la vitesse du pas courant (il ne prend jamais de
## retard), avec le **genre du pas précédent** du joueur, celui qui l'avait amené en `from` : si
## c'était un saut de rebord, le compagnon saute à son tour. Il ne va donc que sur des cases où le
## joueur est passé, jamais en travers d'un obstacle, et n'est jamais à plus d'un pas (ou d'un
## saut) derrière lui. Si le joueur marche sur sa case, la même règle les fait se croiser
## (échange de places, D-4). Un pivot ou une poussée contre un mur ne font rien : ce ne sont pas
## des pas.
##
## Sans case (arrivée sans case libre derrière le joueur, A-1), il apparaît en `from` à la fin du
## premier pas. Le compagnon n'occupe pas la grille : rien ici ne réserve de case.

const WALK: StringName = &"walk"
const RUN: StringName = &"run"
const JUMP: StringName = &"jump"
const KINDS: Array[StringName] = [WALK, RUN, JUMP]
## Pas de case.
const NONE := Vector2i(-99999, -99999)


## Un déplacement du compagnon, rendu par [method on_player_step].
class Step:
	extends RefCounted
	## Case de départ ([constant NONE] si [member appear]).
	var from_cell: Vector2i = NONE
	var to_cell: Vector2i = NONE
	## Genre du mouvement : WALK (ou RUN) le long d'un pas, JUMP pour sauter un rebord derrière
	## le joueur.
	var kind: StringName = WALK
	## Durée à prendre : celle du pas courant du joueur (WALK, RUN ou JUMP).
	var pace: StringName = WALK
	## Vrai : il n'avait pas de case, il **apparaît** en [member to_cell] à la fin du pas.
	var appear: bool = false


var _cell: Vector2i = NONE
## Genre du dernier pas du joueur (celui qui l'a amené sur sa case actuelle).
var _last_kind: StringName = WALK


## Case du compagnon ([constant NONE] s'il n'en a pas).
func get_cell() -> Vector2i:
	return _cell


func is_placed() -> bool:
	return _cell != NONE


## Retire le compagnon de la carte (intérieur, scène, transition, rappel) : plus de case.
func clear() -> void:
	_cell = NONE


## Placement après une arrivée (porte, reprise de partie, réveil, départ de débogage, fin de
## scène, FAIRE SORTIR) : la case **derrière** le joueur ([param player_cell] − [param facing])
## si [param is_free] (`func(cell: Vector2i) -> bool` : ni solide, ni eau, ni rebord, ni occupée)
## l'accepte ; sinon aucune (il viendra au premier pas). Le dernier pas est oublié : le prochain
## mouvement est une marche. Rend la case (ou [constant NONE]).
func place_after_arrival(player_cell: Vector2i, facing: Vector2i, is_free: Callable) -> Vector2i:
	_last_kind = WALK
	var behind := player_cell - facing
	_cell = behind if facing != Vector2i.ZERO and bool(is_free.call(behind)) else NONE
	return _cell


## Le joueur commence un pas de [param from] à [param _to] ([param kind] : WALK, RUN ou JUMP).
## Rend le mouvement du compagnon (toujours un, vers [param from]).
func on_player_step(from: Vector2i, _to: Vector2i, kind: StringName) -> Step:
	if not KINDS.has(kind):
		push_error("CompanionTrail : genre de pas inconnu « %s »" % kind)
		kind = WALK
	var step := Step.new()
	step.to_cell = from
	step.pace = kind
	if _cell == NONE:
		step.appear = true
	else:
		step.from_cell = _cell
		step.kind = JUMP if _last_kind == JUMP else (RUN if kind == RUN else WALK)
	_cell = from
	_last_kind = kind
	return step
