class_name BattleEvent
extends RefCounted
## Une ligne du journal de combat (jalon 4 §2.2 et §3.4). Donnée pure.
##
## Le moteur ([Battle]) ne joue rien : il renvoie une liste d'événements que la
## présentation joue dans l'ordre, à son rythme. Chaque événement porte [b]l'état
## d'après[/b] (PV restants, niveau de statistique, PP) : la présentation n'interroge
## jamais le moteur pendant qu'elle joue. Champs utiles selon [member kind] :
## - BATTLE_STARTED : [member trainer_name] (camp adverse) ;
## - SENT_OUT : Pokémon envoyé ([member pokemon_name], [member species_id], [member level],
##   [member gender], [member hp], [member max_hp]) et [member trainer_name] de son camp ;
## - TURN_STARTED : [member turn] ;
## - MOVE_USED : lanceur, [member move_id], [member pp] restants (−1 pour Lutte) ;
## - MOVE_MISSED : lanceur, [member move_id] ;
## - DAMAGE : cible, [member amount] (PV perdus), [member hp], [member max_hp],
##   [member effectiveness], [member critical] ;
## - NO_EFFECT : cible (type immunisé), [member move_id] ;
## - STAT_CHANGED : Pokémon touché, [member stat], [member stages] (variation réelle),
##   [member stage] (niveau d'après) ;
## - STAT_UNCHANGED : Pokémon touché, [member stat], [member stages] (variation demandée),
##   [member stage] (déjà au bout) ;
## - RECOIL : lanceur, [member amount], [member hp], [member max_hp] ;
## - FAINTED : Pokémon K.O. ;
## - BATTLE_ENDED : [member outcome] ([enum Battle.Outcome], du point de vue du joueur) ;
## - FLED : le joueur a réussi à fuir (combat sauvage) ;
## - FLEE_FAILED : la fuite a échoué, l'adversaire va jouer.
## Jalon 5C (§2.3), toujours entre le FAINTED adverse et la suite (BATTLE_ENDED ou envoi
## suivant) ; le Pokémon concerné est un participant du joueur, pas forcément celui en jeu :
## - EXP_GAINED : une tranche de barre d'XP, dans le [member level] où elle se remplit, de
##   [member exp_from] à [member exp_to] (fractions 0..1 de la barre) ; [member amount] =
##   XP gagnée en tout sur la première tranche, 0 sur les suivantes (un niveau gagné ouvre
##   une nouvelle tranche) ; [member hp], [member max_hp] avant le niveau suivant ;
##   [member exp_points_from], [member exp_points_to] : la même tranche en points d'XP du
##   niveau, sur [member exp_points_need] (« 112 / 173 » ; 0 au niveau 100 : pas de nombres) ;
## - LEVEL_UP : nouveau [member level], [member hp] et [member max_hp] recalculés,
##   [member stat_gains] (gain de chaque statistique à ce niveau, bilan de fin de combat) ;
##   [member exp_from], [member exp_points_from], [member exp_points_need] : la barre du
##   nouveau niveau, d'où elle repart ;
## - MOVE_LEARNED : [member move_id] appris dans un emplacement libre (déjà fait par le
##   moteur) ;
## - MOVE_FORGET_OFFERED : [member move_id] à apprendre alors que les 4 emplacements sont
##   pris. Rien n'a changé : la présentation fait choisir le joueur
##   ([method Pokemon.replace_move] ou rien).
## Vampigraine (Q28) :
## - SEEDED : Pokémon sur lequel la graine est plantée ;
## - DRAINED : Pokémon drainé en fin de tour ([member amount] PV perdus, [member hp],
##   [member max_hp]) ; [member healed] PV rendus au Pokémon d'en face, qui en a ensuite
##   [member healed_hp].
## Tout événement sur un Pokémon porte aussi [member party_index] : sa place dans l'équipe de
## son camp (0 = en tête). La présentation retrouve ainsi le Pokémon exact (SENT_OUT : celui
## que le moteur envoie, pas forcément le premier de l'équipe ; MOVE_FORGET_OFFERED : celui qui
## apprend), sans le chercher par espèce et nom, ambigus avec deux Pokémon identiques.
## Capture (jalon 5D, §2.4), juste après TURN_STARTED, toutes sur le Pokémon sauvage (camp
## FOE, son état au moment du lancer) :
## - BALL_THROWN : la Ball [member item_id] ([member item_name] : son nom) est lancée ;
## - BALL_SHAKE : une secousse, numéro [member shake] (1 à 3) ; 0 à 3 de suite ;
## - CAUGHT : capturé (après 3 secousses), puis BATTLE_ENDED (CAUGHT) ; l'adversaire ne joue
##   pas, aucune XP n'est donnée ;
## - BROKE_FREE : il s'est libéré, puis l'adversaire joue son tour.
## Soin (jalon 6, §3.4), juste après TURN_STARTED, puis l'adversaire joue son tour :
## - ITEM_USED : le soin [member item_id] ([member item_name]) est donné au Pokémon du joueur
##   [member party_index] (pas forcément celui en jeu) ; [member amount] PV rendus,
##   [member hp] et [member max_hp] d'après.
## Changement de Pokémon (jalon 7), juste après TURN_STARTED (ou sans tour : remplacement
## après un K.O., [method Battle.replace]) :
## - WITHDRAWN : le Pokémon du joueur en jeu est rappelé (« Reviens, … ! ») ; suit le SENT_OUT
##   du Pokémon envoyé, puis (changement volontaire) l'adversaire joue son tour. Côté adverse
##   (jalon 13, IA qui change) : [member trainer_name] porte le Dresseur (« … rappelle … ! ») ;
##   suit le SENT_OUT adverse, puis l'action du joueur.
## Statuts durables (jalon 9 §2.1.3, le poison seul) ; [member status] = le statut concerné :
## - STATUS_INFLICTED : le Pokémon touché reçoit [member status] (Poudre Toxik, Dard-Venin) ;
## - STATUS_UNCHANGED : capacité de statut sur un Pokémon qui a déjà ce même [member status]
##   (rien ne change ; un autre statut donne FAILED, une immunité de type NO_EFFECT) ;
## - STATUS_DAMAGED : fin de tour, le Pokémon perd [member amount] PV à cause de
##   [member status] ([member hp], [member max_hp] d'après) ; un K.O. suit le chemin habituel
##   (FAINTED, XP, BATTLE_ENDED ou remplacement) ;
## - STATUS_CURED : juste après ITEM_USED (Antidote), le Pokémon [member party_index] n'a plus
##   [member status] (le statut [b]effacé[/b], pas l'état d'après).
## Jalon 11 (statuts complets, `jalon-11.md` §2.2) :
## - STATUS_PREVENTED : le Pokémon ne peut pas agir ce tour-ci à cause de [member status]
##   (paralysie totale, sommeil, gel) ; aucune capacité n'est lancée, aucun PP dépensé ;
## - STATUS_ENDED : [member status] (le statut [b]fini[/b]) s'arrête de lui-même : réveil,
##   dégel au moment d'agir (le Pokémon agit ensuite) ou dégel par une capacité Feu ;
## - FAILED : la capacité [member move_id] du lanceur échoue sans autre effet (« Mais ça
##   échoue ! ») — statut sur une cible qui en a déjà un autre, Puissance déjà active…
## - CONFUSED : le Pokémon devient confus ; CONFUSION_UNCHANGED : capacité de confusion sur un
##   Pokémon déjà confus ; CONFUSION_CHECK : au moment d'agir, il est confus (« … est
##   confus… ») ; HURT_ITSELF : il se frappe ([member amount], [member hp]) et n'agit pas ;
##   CONFUSION_ENDED : il n'est plus confus (puis il agit) ;
## - MULTI_HIT : après les coups d'une capacité à plusieurs coups, [member amount] = nombre de
##   coups portés (« Touché 3 fois ! ») ;
## - FLINCHED : le Pokémon apeuré ne peut pas agir ce tour-ci ;
## - FOCUSED : Puissance réussie (critique +2 niveaux).
## Patience (CT34, dossier 14 §6.3) : BIDE_STARTED (tour 1, après MOVE_USED : « se prépare à
## encaisser ! »), BIDE_STORING (tour 2, sans MOVE_USED : « encaisse ! »), BIDE_UNLEASHED
## (tour 3, sans MOVE_USED : « riposte ! », puis DAMAGE de [member move_id] « bide » ou FAILED
## si rien n'a été reçu), BIDE_BROKEN (« La patience de … est rompue ! » : paralysie totale,
## sommeil, gel, apeurement, se frapper dans la confusion).
## Jalon 12 (`jalon-12.md` §2.10, dossier 15 §20 n° 46) :
## - DRAINED_HP : après les dégâts d'une capacité de drain (Vampirisme), le lanceur récupère
##   [member amount] PV ([member hp] d'après) ; absent si ses PV étaient pleins (distinct de
##   DRAINED, la Vampigraine) ;
## - TRAPPED : la cible est piégée par [member move_id] (Ligotage, Étreinte, Danse Flamme) ;
## - TRAP_DAMAGED : fin de tour, le Pokémon piégé perd [member amount] PV ([member hp]) à cause de
##   [member move_id] ; un K.O. suit le chemin habituel ;
## - TRAP_ENDED : le Pokémon est libéré de [member move_id] (fin du compteur) ; aucun événement
##   quand le lanceur quitte le terrain ou tombe ;
## - MOVE_DISABLED : la capacité [member move_id] du Pokémon est bloquée (Entrave réussie) ; aussi
##   quand il tente, dans le tour même où elle vient d'être bloquée, la capacité choisie avant
##   (rien n'est lancé, aucun PP) ;
## - DISABLE_ENDED : fin de tour, [member move_id] n'est plus bloquée ;
## - RESTED : Repos, le lanceur a [member hp] PV (pleins, [member amount] rendus) et dort
##   ([member status]) ;
## - SELF_KO : Destruction, Explosion : le lanceur perd ses [member amount] derniers PV
##   ([member hp] = 0) après les effets de sa capacité ; suivent le FAINTED de la cible (si elle
##   tombe) puis le sien. Pas de phrase (« … est K.O. ! » est celle du FAINTED).
## Jalon 14 (`jalon-14.md` §2.3, §2.5) : CHARGE_STARTED (tour 1, après MOVE_USED : « creuse un
## trou ! » ; [member move_id] = la capacité chargée, dont l'effet choisit le message ; la
## présentation cache le sprite si l'effet est invulnérable), CHARGE_RELEASED (tour 2, avant le
## MOVE_USED sans PP ; sprite rendu, pas de phrase), CHARGE_BROKEN (tour 2 : « remonte à la
## surface. », rien n'est frappé ; sprite rendu), DODGED (sur la cible invulnérable : « évite
## l'attaque ! »), BALL_BLOCKED (sur le sauvage invulnérable, à la place de BALL_THROWN :
## « Impossible de viser ! » ; [member item_id], [member item_name]), TELEPORTED (le lanceur
## s'en va : suit BATTLE_ENDED, FLED ou FOE_FLED), NOTHING_HAPPENED (Téléport contre un
## Dresseur : « Mais rien ne se passe ! »).
## Jalon 15 (`jalon-15.md` §2.7.3) :
## - COINS_SCATTERED : Jackpot réussi du joueur (camp PLAYER, le lanceur), juste après ses
##   dégâts ; [member amount] = pièces éparpillées par ce Jackpot (niveau × « per_level »). Le
##   Jackpot de l'adversaire n'en émet aucun (il ne rapporte rien au joueur).
## Jalon 19 (Hurlement, Ultralaser) :
## - RECHARGING : le lanceur d'un Ultralaser qui a touché se repose (« … doit se reposer ! ») ;
##   ni MOVE_USED ni PP, son tour est perdu ;
## - SCARED_AWAY : Hurlement en combat sauvage, la cible [member move_id] s'enfuit ; suit
##   BATTLE_ENDED (FOE_FLED si c'est le sauvage, FLED si c'est le Pokémon du joueur) ;
## - FORCED_OUT : Hurlement contre un Dresseur (ou d'un Dresseur), la cible quitte le terrain ;
##   suit le SENT_OUT du remplaçant tiré au hasard dans son camp.
## Jalon 19 (mode SPECTRE, dossier 22 §6.2, [GhostDisguise]) :
## - GHOST_SCARED : le Pokémon du joueur a trop peur pour bouger (capacité remplacée : ni PP, ni
##   tirage) ;
## - GHOST_SPOKE : le SPECTRE (camp adverse) ne fait que parler ;
## - tout événement du camp adverse d'un combat SPECTRE porte [member disguised] : espèce
##   [constant GhostDisguise.SPECIES], niveau 0, sans genre (garde du Pokédex et du cri).
## Jalon 20 (objets du grand magasin de Céladopole, `jalon-20.md` §2.9.3 et §2.9.4) :
## - BATTLE_ITEM_USED : objet de combat du joueur ([member item_id], [member item_name]) sur son
##   Pokémon actif : « {player} utilise {item} ! » ; suivent STAT_CHANGED / STAT_UNCHANGED (objet
##   X) ou FOCUSED / FAILED (Muscle +) ;
## - ITEM_ESCAPE : Poupée Poké en combat sauvage (camp PLAYER) : la fuite est garantie ; suit
##   BATTLE_ENDED (FLED) ;
## - REVIVED : juste après l'ITEM_USED d'un Rappel, le Pokémon [member party_index] de l'équipe
##   du joueur n'est plus K.O. ([member hp] : ses PV rendus).
## Tous les autres événements sur un Pokémon portent dans [member status] son statut au moment
## de l'événement (SENT_OUT : la carte de PV l'affiche dès l'entrée ; FAINTED : toujours vide,
## le K.O. efface le statut).

enum Kind {
	BATTLE_STARTED, SENT_OUT, TURN_STARTED, MOVE_USED, MOVE_MISSED, DAMAGE, NO_EFFECT,
	STAT_CHANGED, STAT_UNCHANGED, RECOIL, FAINTED, BATTLE_ENDED, FLED, FLEE_FAILED,
	EXP_GAINED, LEVEL_UP, MOVE_LEARNED, MOVE_FORGET_OFFERED, SEEDED, DRAINED,
	BALL_THROWN, BALL_SHAKE, CAUGHT, BROKE_FREE,
	ITEM_USED,
	WITHDRAWN,
	STATUS_INFLICTED, STATUS_UNCHANGED, STATUS_DAMAGED, STATUS_CURED,
	STATUS_PREVENTED, STATUS_ENDED, FAILED,
	CONFUSED, CONFUSION_UNCHANGED, CONFUSION_CHECK, HURT_ITSELF, CONFUSION_ENDED,
	MULTI_HIT, FLINCHED, FOCUSED,
	BIDE_STARTED, BIDE_STORING, BIDE_UNLEASHED, BIDE_BROKEN,
	DRAINED_HP, TRAPPED, TRAP_DAMAGED, TRAP_ENDED, MOVE_DISABLED, DISABLE_ENDED, RESTED, SELF_KO,
	CHARGE_STARTED, CHARGE_RELEASED, CHARGE_BROKEN, DODGED, BALL_BLOCKED,
	TELEPORTED, NOTHING_HAPPENED,
	COINS_SCATTERED,
	RECHARGING, SCARED_AWAY, FORCED_OUT,
	GHOST_SCARED, GHOST_SPOKE,
	ITEM_ESCAPE, REVIVED, BATTLE_ITEM_USED,
}
enum SideId { PLAYER, FOE }

var kind: Kind = Kind.BATTLE_STARTED
## Camp concerné (le lanceur, la cible ou le Pokémon touché selon [member kind]).
var side: SideId = SideId.PLAYER
## Nom affiché du Pokémon concerné (surnom ou espèce).
var pokemon_name: String = ""
var species_id: StringName = &""
var level: int = 0
var gender: Pokemon.Gender = Pokemon.Gender.NONE
## Place du Pokémon concerné dans l'équipe de son camp (−1 : événement sans Pokémon).
var party_index: int = -1
var trainer_name: String = ""
var turn: int = 0
var move_id: StringName = &""
var pp: int = 0
var amount: int = 0
var hp: int = 0
var max_hp: int = 0
var effectiveness: float = 1.0
var critical: bool = false
var stat: StringName = &""
var stages: int = 0
var stage: int = 0
var outcome: int = 0
## EXP_GAINED : remplissage de la barre d'XP au début et à la fin de la tranche (0..1).
var exp_from: float = 0.0
var exp_to: float = 0.0
## EXP_GAINED : la tranche en points d'XP dans le niveau ([method ExpCalc.level_span]) : début,
## fin, et XP du niveau entier (0 au niveau 100).
var exp_points_from: int = 0
var exp_points_to: int = 0
var exp_points_need: int = 0
## LEVEL_UP : gain de chaque statistique ([constant SpeciesData.STATS]) à ce niveau.
var stat_gains: Dictionary[StringName, int] = {}
## DRAINED : PV rendus au Pokémon d'en face, et ses PV ensuite.
var healed: int = 0
var healed_hp: int = 0
## BALL_THROWN, ITEM_USED : l'objet (identifiant et nom affiché, « Poké Ball », « Potion »).
var item_id: StringName = &""
var item_name: String = ""
## BALL_SHAKE : numéro de la secousse (1 à 3).
var shake: int = 0
## Statut durable concerné ([constant StatusRules.NONE] = aucun) : voir l'en-tête.
var status: StringName = StatusRules.NONE
## Masqué par [method GhostDisguise.mask] (combat SPECTRE, jalon 19) : rien ne doit révéler
## l'espèce réelle (Pokédex, cri, image, nom, niveau).
var disguised: bool = false


func _init(event_kind: Kind = Kind.BATTLE_STARTED, event_side: SideId = SideId.PLAYER) -> void:
	kind = event_kind
	side = event_side


## Tous les champs (journaux, tests de reproductibilité).
func to_dict() -> Dictionary:
	return {
		"kind": Kind.find_key(kind), "side": SideId.find_key(side), "pokemon": pokemon_name,
		"species": species_id, "party_index": party_index, "level": level, "gender": gender,
		"trainer": trainer_name, "turn": turn, "move": move_id, "pp": pp, "amount": amount, "hp": hp,
		"max_hp": max_hp, "effectiveness": effectiveness, "critical": critical,
		"stat": stat, "stages": stages, "stage": stage, "outcome": outcome,
		"exp_from": exp_from, "exp_to": exp_to, "exp_points_from": exp_points_from,
		"exp_points_to": exp_points_to, "exp_points_need": exp_points_need,
		"stat_gains": stat_gains, "healed": healed, "healed_hp": healed_hp,
		"item": item_id, "item_name": item_name, "shake": shake, "status": status,
		"disguised": disguised,
	}
