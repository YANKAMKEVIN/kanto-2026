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
## Jalon 5C (revu par la demande n° 1 : le bilan de fin de combat raconte la progression) :
## - EXP : une tranche de la barre d'XP du Pokémon du joueur ; rien à l'écran pendant le
##   combat (le directeur la note pour le bilan) ;
## - LEVEL : « Nv. » de la carte du Pokémon du joueur en jeu prend [member BattleEvent.level],
##   ses PV max [member BattleEvent.max_hp], en silence ;
## - DRAIN : Vampigraine en fin de tour : la barre du Pokémon drainé ([member side]) descend à
##   [member BattleEvent.hp], celle du Pokémon d'en face monte à [member BattleEvent.healed_hp] ;
## - FORGET : le joueur choisit la capacité à oublier ([member BattleEvent.move_id] est la
##   nouvelle) ; la lecture du journal est suspendue jusqu'à son choix.
## Jalon 5D (capture) :
## - THROW : le dresseur lance la Ball ([member BattleEvent.item_id]), le Pokémon sauvage est
##   absorbé, la Ball tombe dans l'herbe ;
## - SHAKE : une secousse de la Ball ([member BattleEvent.shake], 1 à 3), avec vibration ;
## - CATCH : éclat doré et motif de vibration ; le directeur range ensuite le Pokémon et
##   montre la carte de capture (la lecture est suspendue jusqu'au toucher) ;
## - RELEASE : la Ball s'ouvre, le Pokémon sauvage ressort et sa carte revient.
## Jalon 6 (soin) :
## - HEAL : la barre de PV du Pokémon soigné remonte jusqu'à [member BattleEvent.hp] ; seulement
##   s'il est en jeu ([member BattleEvent.party_index]), sinon rien ne bouge à l'écran.
## Jalon 9 (poison) :
## - POISON : fin de tour, le Pokémon de [member side] est rongé par son statut : voile violet
##   sur le Pokémon et barre de PV jusqu'à [member BattleEvent.hp] ([member BattleEvent.max_hp]),
##   en même temps (comme DRAIN) ; le message suit ;
## - STATUS_TAG : l'étiquette « PSN » de la carte du Pokémon concerné apparaît (STATUS_INFLICTED :
##   [member BattleEvent.status] sur [member side]) ou disparaît (STATUS_CURED : le Pokémon
##   [member BattleEvent.party_index], seulement s'il est en jeu) ; instantané, sans attente.
## Jalon 11 : STATUS_TAG pose aussi l'effet du statut sur le Pokémon ([StatusAura]) ; POISON
## sert aussi à la brûlure (voile orangé) ; CONFUSION : étoiles au-dessus du Pokémon confus de
## [member side], au moment du test (après « … est confus… »).
## Jalon 12 : HP — la barre de PV du Pokémon de [member side] va à [member BattleEvent.hp]
## ([member BattleEvent.max_hp]) sans coup ni voile (drain d'une attaque, Repos).
## Jalon 14 (Tunnel, Téléport) :
## - BURROW : le Pokémon de [member side] s'enfonce dans le sol et disparaît (ombre comprise) ;
## - SURFACE : il remonte (charge libérée ou rompue) ;
## - VANISH : il scintille puis s'efface (Téléport) ; « Réduire les animations » : fondus courts.
## Jalon 7 (changement de Pokémon) :
## - WITHDRAW : le Pokémon du joueur est rappelé dans sa Poké Ball (il rétrécit dans un éclat
##   rouge), sa carte et les pastilles sortent ; le SEND_OUT du suivant les ramène.

enum Kind {
	MESSAGE, SEND_OUT, MOVE, DAMAGE, STAT, FAINT, EXP, LEVEL, DRAIN, FORGET,
	THROW, SHAKE, CATCH, RELEASE,
	HEAL,
	WITHDRAW,
	POISON, STATUS_TAG,
	CONFUSION,
	HP,
	BURROW, SURFACE, VANISH,
}

var kind: Kind = Kind.MESSAGE
var side: BattleEvent.SideId = BattleEvent.SideId.PLAYER
## MESSAGE : la phrase à afficher.
var text: String = ""
## MESSAGE : la phrase attend un toucher (« X apprend Y ! » : phrase importante).
var wait_touch: bool = false
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
