class_name CutsceneStep
extends RefCounted
## Une étape d'une scène scriptée (docs/tech/jalon-03b.md §2.3) et ses paramètres typés.
##
## Donnée pure, construite et validée par [CutsceneLibrary] ; le directeur de scènes la joue.
## Seuls les champs de son [member kind] ont un sens :
## - [constant Kind.WAIT] : [member seconds] ;
## - [constant Kind.DIALOGUE] : [member dialogue_id] ;
## - [constant Kind.FACE] : [member actor] se tourne vers [member target] (nom de direction,
##   « player » ou identifiant de PNJ, axe dominant) ;
## - [constant Kind.SET_FLAGS] : [member flags] ;
## - [constant Kind.SPAWN] : [member spec] (PNJ créé pour la durée de la carte ;
##   [member actor] = son identifiant) ;
## - [constant Kind.MOVE] : [member actor] suit **soit** [member path] (directions), **soit**
##   un chemin calculé vers une destination : case absolue [member cell], ou première case
##   libre autour de [member near] parmi [member offsets] ; [member run] ; [member follower]
##   (second acteur, un pas derrière) ;
## - [constant Kind.CHANGE_MAP] : [member map_id], [member spawn], [member facing]
##   (ZERO = garder l'orientation).

enum Kind { WAIT, DIALOGUE, FACE, SET_FLAGS, SPAWN, MOVE, CHANGE_MAP }

## Clé de type de chaque étape dans les fichiers, dans l'ordre de [enum Kind].
const TYPE_KEYS: Array[String] = [
	"wait", "dialogue", "face", "set", "spawn", "move", "change_map",
]
## Pas de case (destination relative, ou étape sans case).
const NO_CELL: Vector2i = Vector2i(-1, -1)

var kind: Kind = Kind.WAIT
var seconds: float = 0.0
var dialogue_id: StringName = &""
var actor: StringName = &""
var target: StringName = &""
var flags: Array[StringName] = []
var spec: NpcSpec
var path: Array[Vector2i] = []
var cell: Vector2i = NO_CELL
var near: StringName = &""
var offsets: Array[Vector2i] = []
var run: bool = false
var follower: StringName = &""
var map_id: StringName = &""
var spawn: StringName = &""
var facing: Vector2i = Vector2i.ZERO


## Nom du type dans les fichiers (« wait », « dialogue »…).
static func kind_name(value: Kind) -> StringName:
	return StringName(TYPE_KEYS[value])


## Étape MOVE vers une destination (chemin calculé) plutôt qu'un chemin écrit.
func has_destination() -> bool:
	return cell != NO_CELL or not near.is_empty()
