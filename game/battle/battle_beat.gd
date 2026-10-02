class_name BattleBeat
extends RefCounted
## Un temps de la mise en scène d'un combat (jalon-04.md §14.2). Donnée pure.
##
## [BattlePlayback] découpe chaque [BattleEvent] du journal en temps, dans l'ordre où la
## présentation doit les jouer ; le BattleDirector joue chaque temps avec le BattleStage (le
## décor et les Pokémon) et la BattleHud (cartes, barres de PV, messages), et attend sa fin
## avant le suivant. Les valeurs à afficher (PV d'après, nom, niveau…) sont lues dans
## [member event] : la présentation n'interroge jamais le moteur.
##
## - MESSAGE : [member text] dans le bandeau des messages ;
## - SEND_OUT : le Pokémon de [member side] entre en jeu, sa carte arrive ;
## - MOVE : le Pokémon de [member side] attaque ([member category] : élan physique,
##   capacité spéciale, pulsation de statut) ;
## - DAMAGE : le Pokémon de [member side] est touché (tremblement, vibration plus forte sur
##   un critique) **et** sa barre de PV descend jusqu'à [member BattleEvent.hp], en même
##   temps ; aussi pour le contrecoup ;
## - STAT : effet de statistique sur le Pokémon de [member side] (monte si
##   [member BattleEvent.stages] > 0, baisse sinon) ;
## - FAINT : le Pokémon de [member side] tombe K.O., sa carte s'en va.
## Jalon 5C :
## - EXP : une tranche de la barre d'XP du Pokémon du joueur ([member BattleEvent.exp_from] →
##   [member BattleEvent.exp_to], « +[member BattleEvent.amount] XP » sur la première) ;
## - LEVEL : « Nv. » du Pokémon du joueur prend [member BattleEvent.level], ses PV max
##   [member BattleEvent.max_hp] ;
## - DRAIN : Vampigraine en fin de tour : la barre du Pokémon drainé ([member side]) descend à
##   [member BattleEvent.hp], celle du Pokémon d'en face monte à [member BattleEvent.healed_hp] ;
## - FORGET : le joueur choisit la capacité à oublier ([member BattleEvent.move_id] est la
##   nouvelle) ; la lecture du journal est suspendue jusqu'à son choix.

enum Kind { MESSAGE, SEND_OUT, MOVE, DAMAGE, STAT, FAINT, EXP, LEVEL, DRAIN, FORGET }

var kind: Kind = Kind.MESSAGE
var side: BattleEvent.SideId = BattleEvent.SideId.PLAYER
## MESSAGE : la phrase à afficher.
var text: String = ""
## Événement du journal d'où vient ce temps.
var event: BattleEvent
## MOVE : catégorie de la capacité (animation).
var category: MoveData.Category = MoveData.Category.PHYSICAL


func _init(beat_kind: Kind = Kind.MESSAGE, source: BattleEvent = null) -> void:
	kind = beat_kind
	event = source
	if source != null:
		side = source.side


## Vrai pour un coup qui retire plus de [param threshold] (fraction) des PV max : la barre
## descend plus vite (UiTokens.HP_BIG_HIT, décidé par la présentation).
func is_big_hit(threshold: float) -> bool:
	if kind != Kind.DAMAGE or event == null or event.max_hp <= 0:
		return false
	return float(event.amount) > threshold * float(event.max_hp)
