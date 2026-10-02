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
##   (second acteur, un pas derrière) ; [member keep_facing] (le joueur recule sans se
##   retourner) ; [member optional] (aucune case libre autour de [member near] : étape
##   sautée sans erreur) ;
## - [constant Kind.CHANGE_MAP] : [member map_id], [member spawn], [member facing]
##   (ZERO = garder l'orientation) ;
## - [constant Kind.HOP] (jalon 4) : le PNJ [member actor] saute (d'un meuble) vers une
##   case absolue [member cell], ou la première case d'atterrissage autour de [member near]
##   parmi [member offsets] ([method CutsceneMoves.resolve_landing] : libre, trajectoire qui
##   ne traverse la case d'aucun personnage, pas juste derrière la tête d'un grand) ;
## - [constant Kind.LEAN] (jalon 4) : le PNJ [member actor] s'avance légèrement vers
##   [member target] (comme « face ») puis revient ;
## - [constant Kind.DESPAWN] (jalon 4) : le PNJ [member actor] quitte la carte ;
## - [constant Kind.BATTLE] (jalon 4B, jalon-04.md §14) : combat contre le dresseur
##   [member trainer_id] ; [member player_pokemon] et [member foe_pokemon] : PNJ Pokémon de
##   la carte qui combattent (cachés pendant le combat, facultatifs) ; [member win_flags] ou
##   [member lose_flags] levés selon l'issue ([method outcome_flags]) ;
## - [constant Kind.GIVE] (jalon 4B) : [member count] objets [member item_id] ajoutés au Sac ;
##   [member found] (jalon 5C.5) : objet **trouvé dans le monde** (la Potion de la Route 1),
##   pas reçu d'un personnage (les Poké Balls de Chen) : il entre au journal des objets trouvés.
## Conditions d'étape (jalon 4B) : [member if_flags] / [member unless_flags] ; une étape dont
## les conditions ne sont pas remplies au moment de la jouer est sautée ([method applies]).
## Elles servent aux suites qui dépendent de l'issue d'un combat (victoire / défaite), qu'une
## variante de scène, choisie au lancement, ne peut pas connaître.
## Alias (jalon 4 §3.6) : partout où un acteur ou une cible d'acteur est attendu,
## « $nom » ([method is_alias]) désigne un PNJ choisi au lancement de la scène
## (CutsceneDirector.play(id, alias)). La bibliothèque valide sa forme ; il est résolu
## par le directeur au début de chaque étape.

## Nouvelles valeurs en fin d'enum (ordre de [constant TYPE_KEYS]).
enum Kind {
	WAIT, DIALOGUE, FACE, SET_FLAGS, SPAWN, MOVE, CHANGE_MAP, HOP, LEAN, DESPAWN, BATTLE, GIVE,
}

## Clé de type de chaque étape dans les fichiers, dans l'ordre de [enum Kind].
const TYPE_KEYS: Array[String] = [
	"wait", "dialogue", "face", "set", "spawn", "move", "change_map", "hop", "lean",
	"despawn", "battle", "give",
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
var keep_facing: bool = false
var optional: bool = false
var map_id: StringName = &""
var spawn: StringName = &""
var facing: Vector2i = Vector2i.ZERO
## Étape « battle » : dresseur, PNJ Pokémon qui combattent, drapeaux selon l'issue.
var trainer_id: StringName = &""
var player_pokemon: StringName = &""
var foe_pokemon: StringName = &""
var win_flags: Array[StringName] = []
var lose_flags: Array[StringName] = []
## Étape « give » : objet, quantité, et objet trouvé dans le monde (vrai) ou reçu (faux).
var item_id: StringName = &""
var count: int = 1
var found: bool = false
## Conditions de l'étape (toutes levées / aucune levée), vides = toujours jouée.
var if_flags: Array[StringName] = []
var unless_flags: Array[StringName] = []


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


## Vrai si l'étape doit être jouée avec les drapeaux [param flags] (null = aucun drapeau) :
## toutes ses conditions « if » levées et aucune de ses conditions « unless ».
func applies(flags: StoryFlags) -> bool:
	if flags == null:
		return if_flags.is_empty()
	return flags.has_all(if_flags) and flags.has_none(unless_flags)


## Drapeaux à lever pour l'issue [param outcome] d'un combat ([enum Battle.Outcome]) :
## [member win_flags] pour WIN, [member lose_flags] pour LOSS, rien sinon.
func outcome_flags(outcome: int) -> Array[StringName]:
	match outcome:
		Battle.Outcome.WIN:
			return win_flags.duplicate()
		Battle.Outcome.LOSS:
			return lose_flags.duplicate()
	return []


## Copie indépendante de l'étape (le directeur y remplace les alias ; les étapes de la
## bibliothèque ne sont jamais modifiées). La [member spec] d'un « spawn » est partagée.
func copy() -> CutsceneStep:
	var other := CutsceneStep.new()
	other.kind = kind
	other.seconds = seconds
	other.dialogue_id = dialogue_id
	other.actor = actor
	other.target = target
	other.flags = flags.duplicate()
	other.spec = spec
	other.path = path.duplicate()
	other.cell = cell
	other.near = near
	other.offsets = offsets.duplicate()
	other.run = run
	other.follower = follower
	other.keep_facing = keep_facing
	other.optional = optional
	other.map_id = map_id
	other.spawn = spawn
	other.facing = facing
	other.trainer_id = trainer_id
	other.player_pokemon = player_pokemon
	other.foe_pokemon = foe_pokemon
	other.win_flags = win_flags.duplicate()
	other.lose_flags = lose_flags.duplicate()
	other.item_id = item_id
	other.count = count
	other.found = found
	other.if_flags = if_flags.duplicate()
	other.unless_flags = unless_flags.duplicate()
	return other


## Alias utilisés par l'étape (acteur, cible, suiveur, voisin, Pokémon d'un combat), sans
## « $ », dans cet ordre.
func get_aliases() -> Array[StringName]:
	var found: Array[StringName] = []
	for ref: StringName in [actor, target, follower, near, player_pokemon, foe_pokemon]:
		var alias := alias_name(ref)
		if not alias.is_empty() and not found.has(alias):
			found.append(alias)
	return found
