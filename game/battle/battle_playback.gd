class_name BattlePlayback
extends RefCounted
## Découpe le journal du moteur en temps de mise en scène ([BattleBeat]), dans l'ordre de
## jeu (jalon-04.md §14.2). Classe pure, statique : le BattleDirector ne décide rien de
## l'ordre, il joue les temps.
##
## Par sorte d'événement :
## - BATTLE_STARTED, MOVE_MISSED, NO_EFFECT, STAT_UNCHANGED, BATTLE_ENDED : messages
##   seulement (aucun pour BATTLE_ENDED contre un dresseur sans message de fin : premier
##   combat du rival, décision de Kevin n° 15) ;
## - SENT_OUT : message (« Le Rival envoie Carapuce ! »), puis SEND_OUT ;
## - TURN_STARTED : rien ;
## - MOVE_USED : message (« Salamèche utilise Griffe ! »), puis MOVE ;
## - DAMAGE et RECOIL : DAMAGE (coup et barre de PV ensemble), puis les messages
##   (« Coup critique ! », « C'est super efficace ! », contrecoup) ;
## - STAT_CHANGED : STAT, puis le message ;
## - FAINTED : FAINT, puis le message.
## Jalon 5C (Q25 : ni fenêtre de niveau, ni statistiques) :
## - EXP_GAINED : EXP seulement (« +21 XP » et la barre sont sur la carte, aucune phrase) ;
## - LEVEL_UP : LEVEL (« Nv. » qui pulse, PV max), puis le message « … monte au niveau … ! »
##   (décision de Kevin du 2026-10-02) ;
## - MOVE_LEARNED : le message ;
## - MOVE_FORGET_OFFERED : le message, puis FORGET (le choix et sa phrase sont à la charge du
##   BattleDirector : la lecture est suspendue) ;
## - SEEDED : le message ; DRAINED : DRAIN (les deux barres), puis le message.
## Jalon 5D (capture) :
## - BALL_THROWN : le message (« Tu lances une Poké Ball ! »), puis THROW ;
## - BALL_SHAKE : SHAKE seulement (une secousse, sans phrase) ;
## - CAUGHT : CATCH seulement (l'éclat, puis le directeur range le Pokémon et montre la carte
##   de capture, qui porte tout le texte) ;
## - BROKE_FREE : RELEASE (le Pokémon ressort), puis le message.
## Jalon 6 (soin) :
## - ITEM_USED : « Tu utilises Potion sur … », HEAL (la barre remonte), puis « … récupère
##   20 PV. ».
## Les phrases viennent de [BattleText] : rien n'est écrit ici.


## Temps de [param event], dans l'ordre. [param trainer] : le dresseur adverse (message de
## fin), null pour un Pokémon sauvage.
static func beats(event: BattleEvent, texts: BattleText, data: PokemonData,
		trainer: TrainerData = null) -> Array[BattleBeat]:
	var result: Array[BattleBeat] = []
	var messages: Array[BattleBeat] = []
	for line: String in texts.lines(event, data, trainer):
		var message := BattleBeat.new(BattleBeat.Kind.MESSAGE, event)
		message.text = line
		messages.append(message)
	match event.kind:
		BattleEvent.Kind.SENT_OUT:
			result.append_array(messages)
			result.append(BattleBeat.new(BattleBeat.Kind.SEND_OUT, event))
		BattleEvent.Kind.MOVE_USED:
			result.append_array(messages)
			var move := BattleBeat.new(BattleBeat.Kind.MOVE, event)
			var move_data := data.get_move(event.move_id)
			if move_data != null:
				move.category = move_data.category
			result.append(move)
		BattleEvent.Kind.DAMAGE, BattleEvent.Kind.RECOIL:
			result.append(BattleBeat.new(BattleBeat.Kind.DAMAGE, event))
			result.append_array(messages)
		BattleEvent.Kind.STAT_CHANGED:
			result.append(BattleBeat.new(BattleBeat.Kind.STAT, event))
			result.append_array(messages)
		BattleEvent.Kind.FAINTED:
			result.append(BattleBeat.new(BattleBeat.Kind.FAINT, event))
			result.append_array(messages)
		BattleEvent.Kind.EXP_GAINED:
			result.append(BattleBeat.new(BattleBeat.Kind.EXP, event))
		BattleEvent.Kind.LEVEL_UP:
			result.append(BattleBeat.new(BattleBeat.Kind.LEVEL, event))
			result.append_array(messages)
		BattleEvent.Kind.MOVE_FORGET_OFFERED:
			result.append_array(messages)
			result.append(BattleBeat.new(BattleBeat.Kind.FORGET, event))
		BattleEvent.Kind.DRAINED:
			result.append(BattleBeat.new(BattleBeat.Kind.DRAIN, event))
			result.append_array(messages)
		BattleEvent.Kind.BALL_THROWN:
			result.append_array(messages)
			result.append(BattleBeat.new(BattleBeat.Kind.THROW, event))
		BattleEvent.Kind.BALL_SHAKE:
			result.append(BattleBeat.new(BattleBeat.Kind.SHAKE, event))
		BattleEvent.Kind.CAUGHT:
			result.append(BattleBeat.new(BattleBeat.Kind.CATCH, event))
		BattleEvent.Kind.BROKE_FREE:
			result.append(BattleBeat.new(BattleBeat.Kind.RELEASE, event))
			result.append_array(messages)
		BattleEvent.Kind.ITEM_USED:
			result.append_array(messages.slice(0, 1))
			result.append(BattleBeat.new(BattleBeat.Kind.HEAL, event))
			result.append_array(messages.slice(1))
		_:
			result.append_array(messages)
	return result


## Temps de tout un journal, à la suite (tests, outils).
static func beats_for_log(events: Array[BattleEvent], texts: BattleText, data: PokemonData,
		trainer: TrainerData = null) -> Array[BattleBeat]:
	var result: Array[BattleBeat] = []
	for event: BattleEvent in events:
		result.append_array(beats(event, texts, data, trainer))
	return result
