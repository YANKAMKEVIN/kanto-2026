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
##   pas reçu d'un personnage (les Poké Balls de Chen) : il entre au journal des objets trouvés ;
## - [constant Kind.SCARE] (jalon 7, micro-scène d'arrivée à Jadielle) : le Pokémon d'ambiance
##   [member actor] (un PNJ « shy ») joue **tout de suite** sa réaction (envol ou fuite) et
##   quitte la carte pour la visite ; la scène n'attend pas la fin de la réaction.
## Conditions d'étape (jalon 4B) : [member if_flags] / [member unless_flags] ; une étape dont
## les conditions ne sont pas remplies au moment de la jouer est sautée ([method applies]).
## Elles servent aux suites qui dépendent de l'issue d'un combat (victoire / défaite), qu'une
## variante de scène, choisie au lancement, ne peut pas connaître.
## Alias (jalon 4 §3.6) : partout où un acteur ou une cible d'acteur est attendu,
## « $nom » ([method is_alias]) désigne un PNJ choisi au lancement de la scène
## (CutsceneDirector.play(id, alias)). La bibliothèque valide sa forme ; il est résolu
## par le directeur au début de chaque étape.
## Jalon 7 (jalon-07.md §3.6, T18), scène du colis et de l'activation du Pokédex :
## - [constant Kind.CAPTION] : légende [member text] posée sur le monde (« POKÉDEX ACTIVÉ ») ;
##   la scène attend qu'elle disparaisse ;
## - [constant Kind.TAKE] : [member count] objets [member item_id] **quittent** le Sac (le
##   colis remis à Chen) ; sans l'objet : étape sautée (push_error), rien ne change.
## Jalon 7 (jalon-07.md §3.8, T25), défaite contre un Dresseur (le rival de la Route 22) :
## - [constant Kind.WAKE_UP] : [method DefeatRecovery.recover] (équipe soignée, fondu, réveil au
##   point de repos, mot du lieu) ; la carte a changé, **la scène s'arrête là** (les étapes
##   suivantes ne sont pas jouées). Sans paramètre (« wake_up »: true dans les fichiers).
## Retours T5 (jalon-07.md §15.21), micro-scène d'arrivée à Jadielle :
## - [member background] d'un « move » (PNJ seulement, sans suiveur) : le PNJ marche **en
##   arrière-plan**, la scène passe aussitôt à l'étape suivante (regards, réactions pendant
##   qu'il traverse) ; une étape suivante sur le même PNJ (move, hop, lean, despawn, scare,
##   react) attend d'abord la fin de sa marche, et la scène ne finit qu'à la fin de toutes ;
## - [constant Kind.REACT] : [member actor] (joueur ou PNJ) a une petite réaction de surprise
##   ([method Npc.react], [method Player.react] : animation « react » ou petit bond), sans
##   attendre sa fin.
## Jalon 9 (jalon-09.md §2.4.4), Dresseurs :
## - [constant Kind.EMOTE] : bulle [member emote] (« ! », [constant EMOTE_KINDS]) au-dessus du
##   PNJ [member actor] ([method Npc.show_emote]) ; la scène attend sa fin.
## Jalon 10 (jalon-10.md §2.7, §2.8), Champions et badges :
## - [constant Kind.CHAMPION_CARD] : carte de présentation du Dresseur [member trainer_id]
##   (son bloc « card » de `data/trainers/`) ; la scène attend qu'elle disparaisse ;
## - [constant Kind.BADGE] : remise du badge [member badge_id] (`data/badges.json`) : drapeau du
##   badge, légende « BADGE ROCHE » (tenue courte) avec une vibration légère, Grand moment
##   « badge » (une seule fois par badge) ; la scène attend la fin de la légende.
## Jalon 12 (`jalon-12.md` §2.13, T23), choix du fossile :
## - [constant Kind.MOMENT] : Grand moment de type [member moment_type] ([constant
##   MomentLibrary.TYPES], « fossil ») avec [member moment_details] (« item » : le fossile),
##   enregistré sur la carte courante **une seule fois** par type et détails ; rien d'affiché.
## Jalon 14 (jalon-14.md §2.7), la machine de Léo :
## - [constant Kind.FLASH] : [member count] éclairs blancs plein écran (≥ 1), avec une vibration
##   légère au début de chacun ; adoucis par « Réduire les animations » ou « Réduire les
##   flashs » ; la scène attend la fin du dernier. Ajoutée en fin d'enum : à la fusion du J12,
##   FLASH passe **après** MOMENT (J12 T23), les deux gardés.
## Jalon 16 (`jalon-16.md` §2.3 à §2.5), le S.S. Anne :
## - [constant Kind.FIELD_MOVE] : capacité de terrain [member field_move] (Coupe) sur la cible
##   [member actor] (« on » : un PNJ objet, ou un nœud de la carte comme l'arbuste `FlagGate` du
##   J15) : mise en scène par le gestionnaire de Boot (le Pokémon qui coupe), puis retrait du PNJ
##   s'il en est un (un décor part avec le drapeau de l'étape « set » suivante) ;
## - [constant Kind.SAVE] : **écriture immédiate** de la partie ([member text] = raison), par le
##   chemin du réveil ; réservée au départ du navire (liste blanche des données, testée) ;
## - [constant Kind.ANIMATE] : déplace le nœud [member target] de la carte de [member offset]
##   cases en [member seconds] s, puis le masque si [member fade] ; « Réduire les animations » :
##   fondu sur place ; la scène attend la fin.
## Jalon 19 (`jalon-19.md` §2.4, T13), le SPECTRE du 6F :
## - [constant Kind.WILD_BATTLE] : combat **sauvage** scripté contre [member species] au niveau
##   [member level] (hors des herbes, depuis la case devant le joueur) ; combat SPECTRE selon
##   [method GhostRule.is_ghost_for] ([member ghost_mode], [member ghost_unless_item], Sac du
##   moment) ; [member win_flags] / [member lose_flags] facultatifs ; défaite : réveil au point
##   de repos et **fin de la scène** (comme « wake_up »).
##   Passe systèmes 2 (T30, `systemes-2.md` §3.8 ; politique d'Artikodin, `jalon-24.md` §2.7) :
##   [member catch_flags] (clé « catch ») levés sur une capture ; rencontre fixe
##   [member static_encounter] (clé « static » : drapeaux `done` / `caught`, [StaticEncounter]) ;
##   [member actor] (clé « actor », avec « static » seulement) : le Pokémon de la carte, retiré
##   quand la rencontre est consommée ; [member intro] (clé « intro ») : entrée en scène
##   ([constant INTRO_LEGENDARY] : plus lente).
## Jalon 20 (`jalon-20.md` §2.5.2, T12), le don d'Évoli :
## - [constant Kind.GIFT_POKEMON] : [member species] au niveau [member level] donné au joueur
##   ([method PokemonGift.give], une seule fois par drapeau [member gift_flag]) ; s'il est donné,
##   le dialogue [member dialogue_id] (« reçoit ») puis, s'il est allé au Stockage,
##   [member dialogue_stored] (facultatif). Déjà reçu : rien, l'étape passe.
## Jalon 23 (`jalon-23.md` §2.1, §2.2), la Porte du Parc Safari :
## - [constant Kind.SAFARI] : action [member text] ([constant SAFARI_ACTIONS]) jouée par le
##   gestionnaire [member CutsceneDirector.safari_handler] ([SafariDirector]) : « enter » (péage de
##   500 ₽ et début de visite ; refus sans débit partiel : drapeau `safari_pay_failed`),
##   « leave » (fin de visite volontaire, Balls perdues), « clear » (drapeaux de passage
##   `safari_gate_yes`, `safari_gate_leave_yes`, `safari_pay_failed` remis à faux).

## Nouvelles valeurs en fin d'enum (ordre de [constant TYPE_KEYS]).
enum Kind {
	WAIT, DIALOGUE, FACE, SET_FLAGS, SPAWN, MOVE, CHANGE_MAP, HOP, LEAN, DESPAWN, BATTLE, GIVE,
	CAPTION, TAKE, SCARE, WAKE_UP, REACT, EMOTE, CHAMPION_CARD, BADGE, MOMENT,
	FLASH,
	FIELD_MOVE, SAVE, ANIMATE,
	WILD_BATTLE,
	GIFT_POKEMON,
	## J23 (`jalon-23.md` §2.1, §2.2) : visite du Parc Safari.
	SAFARI,
}

## Clé de type de chaque étape dans les fichiers, dans l'ordre de [enum Kind].
const TYPE_KEYS: Array[String] = [
	"wait", "dialogue", "face", "set", "spawn", "move", "change_map", "hop", "lean",
	"despawn", "battle", "give", "caption", "take", "scare", "wake_up", "react", "emote",
	"champion_card", "badge", "moment",
	"flash",
	"field_move", "save", "animate",
	"wild_battle",
	"gift_pokemon",
	"safari",
]
## Actions d'une étape « safari » (J23) : péage et début de visite, sortie volontaire, remise à
## zéro des drapeaux de passage du comptoir.
const SAFARI_ACTIONS: Array[String] = ["enter", "leave", "clear"]
## Bulles d'une étape « emote » (clé « kind ») : le « ! » du Dresseur qui repère le joueur.
const EMOTE_KINDS: Array[StringName] = [&"exclamation"]
## Entrées en scène d'une étape « wild_battle » (clé « intro », T30) ; &"" = l'entrée sauvage
## ordinaire.
const INTRO_LEGENDARY: StringName = &"legendary"
const INTROS: Array[StringName] = [INTRO_LEGENDARY]
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
## Étape « move » : marche en arrière-plan (la scène continue sans attendre).
var background: bool = false
var map_id: StringName = &""
var spawn: StringName = &""
var facing: Vector2i = Vector2i.ZERO
## Étape « battle » (et « champion_card » : le Dresseur présenté) : dresseur, PNJ Pokémon qui
## combattent, drapeaux selon l'issue.
var trainer_id: StringName = &""
var player_pokemon: StringName = &""
var foe_pokemon: StringName = &""
var win_flags: Array[StringName] = []
var lose_flags: Array[StringName] = []
## Étape « give » : objet, quantité, et objet trouvé dans le monde (vrai) ou reçu (faux).
## Étape « flash » : [member count] = nombre d'éclairs.
var item_id: StringName = &""
var count: int = 1
var found: bool = false
## Étape « caption » : texte de la légende.
var text: String = ""
## Étape « emote » : bulle affichée ([constant EMOTE_KINDS]).
var emote: StringName = &""
## Étape « badge » : badge remis (identifiant de `data/badges.json`, « boulder »).
var badge_id: StringName = &""
## Étape « moment » (jalon 12) : type du Grand moment et ses détails (clés et valeurs texte).
var moment_type: StringName = &""
var moment_details: Dictionary = {}
## Étape « field_move » (jalon 16) : capacité de terrain (« cut »).
var field_move: StringName = &""
## Étape « animate » (jalon 16) : déplacement en cases, et masquage à la fin.
var offset: Vector2i = Vector2i.ZERO
var fade: bool = false
## Étape « wild_battle » (jalon 19) : espèce et niveau du Pokémon sauvage, règle du SPECTRE
## (clé « ghost » : [constant GhostRule.ALWAYS] ou vide ; clé « ghost_unless_item »).
var species: StringName = &""
var level: int = 1
var ghost_mode: StringName = &""
var ghost_unless_item: StringName = &""
## Étape « wild_battle », passe systèmes 2 (T30) : drapeaux d'une capture (clé « catch »),
## rencontre fixe (clé « static », null = combat ordinaire ; partagée entre copies) et entrée en
## scène (clé « intro », [constant INTROS] ou &"").
var catch_flags: Array[StringName] = []
var static_encounter: StaticEncounter = null
var intro: StringName = &""
## Étape « gift_pokemon » (jalon 20) : drapeau du don (clé « flag ») et dialogue joué si le
## Pokémon part au Stockage (clé « say_stored », &"" = aucun) ; [member species],
## [member level] et [member dialogue_id] (clé « say ») servent aussi.
var gift_flag: StringName = &""
var dialogue_stored: StringName = &""
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
## [member win_flags] pour WIN, [member lose_flags] pour LOSS, [member catch_flags] pour CAUGHT
## (T30), rien sinon. Avec une rencontre fixe ([member static_encounter]), ses drapeaux
## ([method StaticEncounter.flags_for]) d'abord, sans doublon.
func outcome_flags(outcome: int) -> Array[StringName]:
	var raised: Array[StringName] = []
	if static_encounter != null:
		raised = static_encounter.flags_for(outcome)
	var written: Array[StringName] = []
	match outcome:
		Battle.Outcome.WIN:
			written = win_flags
		Battle.Outcome.LOSS:
			written = lose_flags
		Battle.Outcome.CAUGHT:
			written = catch_flags
	for flag: StringName in written:
		if not raised.has(flag):
			raised.append(flag)
	return raised


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
	other.background = background
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
	other.text = text
	other.emote = emote
	other.field_move = field_move
	other.offset = offset
	other.fade = fade
	other.species = species
	other.level = level
	other.ghost_mode = ghost_mode
	other.ghost_unless_item = ghost_unless_item
	other.catch_flags = catch_flags.duplicate()
	other.static_encounter = static_encounter
	other.intro = intro
	other.gift_flag = gift_flag
	other.dialogue_stored = dialogue_stored
	other.badge_id = badge_id
	other.moment_type = moment_type
	other.moment_details = moment_details.duplicate()
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
