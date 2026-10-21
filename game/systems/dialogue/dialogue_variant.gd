class_name DialogueVariant
extends RefCounted
## Une version d'un dialogue : ses pages et les drapeaux qui la conditionnent.
##
## Donnée pure, construite par [DialogueLibrary] à partir des fichiers de `data/dialogues/`.
## Elle s'applique si tous les drapeaux de [member if_flags] sont levés et aucun de
## [member unless_flags] ; [member set_flags] sont levés à la fin du dialogue
## (docs/tech/jalon-03.md §2.4). Une variante [member auto] se joue d'elle-même quand le
## joueur arrive sur la carte du PNJ (premier dialogue de Maman).
## Jalon 7 (§3.3) : une variante peut finir par un **choix** à deux cartes ([member choice]),
## une **action** ([member action] : soin, Boutique, Stockage) ou lancer une **scène**
## ([member cutscene]) ; elle peut alors n'avoir aucune page (action ou scène seulement).

var pages: Array[DialoguePage] = []
var if_flags: Array[StringName] = []
var unless_flags: Array[StringName] = []
var set_flags: Array[StringName] = []
## Se déclenche à l'arrivée du joueur sur la carte du PNJ, si la variante s'applique.
var auto: bool = false
## Action jouée à la fin du dialogue, boîte fermée (&"" = aucune) : une de
## [constant DialogueLibrary.ACTIONS]. [code]heal[/code] (Maman, jalon 5 §3.11 ; ancienne clé
## « heal »: true) fait émettre [signal DialogueRunner.heal_requested] ; les autres passent par
## [member DialogueRunner.action_handler]. Jamais avec [member choice].
var action: StringName = &""
## Boutique ouverte par [code]open_shop[/code] (jalon 20, `jalon-20.md` §2.9.1 : un vendeur, une
## boutique de `data/shops/`) ; &"" = celle de la carte courante. Clé « shop », permise seulement
## avec l'action [code]open_shop[/code].
var shop: StringName = &""
## Jalon 20 (`jalon-20.md` §2.9.6, §2.16) : objets exigés dans le Sac (« if_items » : tous) ou
## absents (« unless_items » : aucun) ; zone qui doit être jouable (« if_zone »,
## [method ZoneLibrary.is_playable] : le garde de Safrania ne demande rien avant la ville).
var if_items: Array[StringName] = []
var unless_items: Array[StringName] = []
var if_zone: StringName = &""
## Choix à deux cartes après la dernière page (la question) ; null = aucun.
var choice: DialogueChoice = null
## Scène lancée à la fin du dialogue ([signal DialogueRunner.cutscene_requested]) ; &"" = aucune.
var cutscene: StringName = &""
## Texte provisoire de cette variante, à relire par Kevin (clé « draft » de la variante ;
## « draft » du dialogue entier : [member Dialogue.draft]).
var draft: bool = false
## Tirage (jalon 14, jalon-14.md §2.8 : « une fois sur trois ») : ≥ 2, la variante ne
## s'applique qu'une fois sur [member one_in], tirée **après** ses drapeaux
## ([method Dialogue.pick]) ; 0 = toujours (aucun tirage).
var one_in: int = 0
## Pokédex (jalon 17, jalon-17.md §2.5 ; dossier 20 §8, H-9) : la variante ne s'applique que si
## le joueur a capturé **au moins** ce nombre d'espèces (clé « if_caught_at_least ») ; 0 = sans
## condition.
var caught_at_least: int = 0
## … et seulement s'il en a capturé **moins** que ce nombre (clé « unless_caught_at_least ») ;
## 0 = sans condition.
var caught_below: int = 0
## Capacité de terrain (jalon 16, `jalon-16.md` §2.2) : « cut:ready » (capacité et état de
## [constant FieldMoves.STATE_NAMES]) ; la variante ne s'applique que dans cet état, lu par
## [member DialogueRunner.field_source] ; "" = toujours. Le jeton `{pokemon}` d'une telle variante
## nomme le Pokémon qui utiliserait la capacité.
var field: String = ""


## Vrai si la variante s'applique avec les drapeaux [param flags] (null = aucun drapeau) et
## [param caught] espèces capturées au Pokédex (jalon 17 ; 0 par défaut).
func matches(flags: StoryFlags, caught: int = 0) -> bool:
	if not matches_caught(caught):
		return false
	if flags == null:
		return if_flags.is_empty()
	return flags.has_all(if_flags) and flags.has_none(unless_flags)


## Vrai si [param caught] espèces capturées satisfont [member caught_at_least] et
## [member caught_below].
func matches_caught(caught: int) -> bool:
	return caught >= caught_at_least and (caught_below <= 0 or caught < caught_below)


## Vrai si la variante ne dépend d'aucun drapeau.
func is_unconditional() -> bool:
	return if_flags.is_empty() and unless_flags.is_empty()


## Vrai si la variante demande un tirage ([member one_in]).
func is_random() -> bool:
	return one_in >= 2
