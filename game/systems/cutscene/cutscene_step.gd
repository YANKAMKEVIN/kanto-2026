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
##   (ZERO = garder l'orientation) ;
## - [constant Kind.HOP] (jalon 4) : le PNJ [member actor] saute (d'un meuble) vers une
##   case absolue [member cell], ou la première case libre autour de [member near] parmi
##   [member offsets] ;
## - [constant Kind.LEAN] (jalon 4) : le PNJ [member actor] s'avance légèrement vers
##   [member target] (comme « face ») puis revient ;
## - [constant Kind.DESPAWN] (jalon 4) : le PNJ [member actor] quitte la carte.
## Alias (jalon 4 §3.6) : partout où un acteur ou une cible d'acteur est attendu,
## « $nom » ([method is_alias]) désigne un PNJ choisi au lancement de la scène
## (CutsceneDirector.play(id, alias)). La bibliothèque valide sa forme ; il est résolu
## par le directeur au début de chaque étape.

## Nouvelles valeurs en fin d'enum (ordre de [constant TYPE_KEYS]).
enum Kind { WAIT, DIALOGUE, FACE, SET_FLAGS, SPAWN, MOVE, CHANGE_MAP, HOP, LEAN, DESPAWN }

## Clé de type de chaque étape dans les fichiers, dans l'ordre de [enum Kind].
const TYPE_KEYS: Array[String] = [
	"wait", "dialogue", "face", "set", "spawn", "move", "change_map", "hop", "lean",
	"despawn",
]
## Préfixe d'un alias d'acteur (« $player_starter »).
const ALIAS_PREFIX: String = "$"
const _ALIAS_CHARS: String = "abcdefghijklmnopqrstuvwxyz_"
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


## Étape MOVE ou HOP vers une destination (case absolue ou voisine d'un acteur) plutôt
## qu'un chemin écrit.
func has_destination() -> bool:
	return cell != NO_CELL or not near.is_empty()


## Vrai pour une référence d'alias bien formée : « $ » puis au moins une lettre minuscule
## ou « _ » (forme $[a-z_]+).
static func is_alias(ref: StringName) -> bool:
	var text := String(ref)
	if text.length() < 2 or not text.begins_with(ALIAS_PREFIX):
		return false
	for i: int in range(1, text.length()):
		if not _ALIAS_CHARS.contains(text[i]):
			return false
	return true


## Nom de l'alias sans « $ » (« $player_starter » → player_starter), &"" si [param ref]
## n'est pas un alias bien formé.
static func alias_name(ref: StringName) -> StringName:
	return StringName(String(ref).substr(1)) if is_alias(ref) else &""


## Alias utilisés par l'étape (acteur, cible, suiveur, voisin), sans « $ », dans cet ordre.
func get_aliases() -> Array[StringName]:
	var found: Array[StringName] = []
	for ref: StringName in [actor, target, follower, near]:
		var alias := alias_name(ref)
		if not alias.is_empty() and not found.has(alias):
			found.append(alias)
	return found
