class_name SafariVisit
extends RefCounted
## Visite du Parc Safari en cours (J23, dossier 26 §4, §11 ; plan `jalon-23.md` §2.1). Donnée et
## règles pures, sans écran ; sauvegardée telle quelle ([method to_dict], champ `safari`, v8).
##
## - **Entrée** ([method start]) : refusée si l'argent est sous [member SafariConfig.fee] ; sinon
##   [member SafariConfig.steps] pas et [member SafariConfig.balls] Safari Balls. Les règles ne
##   touchent pas à l'argent : l'appelant débite le prix.
## - **Pas** ([method on_step]) : appelé pour chaque pas effectif sur une carte du Parc (pivoter,
##   se cogner, parler, combattre : aucun appel). Rouge/Bleu : quand le compteur est déjà à 0, le
##   pas **suivant** termine la visite (N-8) ; on peut donc faire [member SafariConfig.steps] pas.
## - **Balls** ([method on_ball_thrown]) : la dernière termine la visite (capture ou non).
## - **Fin** ([method finish]) : la visite n'est plus active ; les Balls restantes sont perdues
##   (elles ne sont pas des objets du Sac).

## Raison d'une fin de visite ([constant NONE] : la visite continue).
const NONE: StringName = &""
const TIME_UP: StringName = &"time_up"
const OUT_OF_BALLS: StringName = &"out_of_balls"
const LEFT_EARLY: StringName = &"left_early"

var active: bool = false
var steps_left: int = 0
var balls_left: int = 0


## Nouvelle visite si [param money] couvre le prix, sinon null (rien n'est débité ici).
static func start(money: int, config: SafariConfig) -> SafariVisit:
	if not can_pay(money, config):
		return null
	var visit := SafariVisit.new()
	visit.active = true
	visit.steps_left = config.steps
	visit.balls_left = config.balls
	return visit


## Vrai si [param money] suffit pour entrer.
static func can_pay(money: int, config: SafariConfig) -> bool:
	return money >= config.fee


## Un pas effectif sur une carte du Parc : [constant TIME_UP] si ce pas termine la visite
## (compteur déjà à 0), sinon [constant NONE] et un pas de moins. Sans effet hors visite.
func on_step() -> StringName:
	if not active:
		return NONE
	if steps_left <= 0:
		finish()
		return TIME_UP
	steps_left -= 1
	return NONE


## Une Safari Ball lancée : [constant OUT_OF_BALLS] si c'était la dernière (la visite est finie),
## sinon [constant NONE]. Sans effet hors visite ou sans Ball.
func on_ball_thrown() -> StringName:
	if not active or balls_left <= 0:
		return NONE
	balls_left -= 1
	if balls_left == 0:
		finish()
		return OUT_OF_BALLS
	return NONE


## Fin de visite (pas, Balls, sortie volontaire, Corde Sortie) : plus de pas ni de Balls.
func finish() -> void:
	active = false
	steps_left = 0
	balls_left = 0


## Contenu prêt pour la sauvegarde (champ `safari`).
func to_dict() -> Dictionary:
	return {"active": active, "steps_left": steps_left, "balls_left": balls_left}


## Visite reprise depuis [param dict] ; un contenu absent ou invalide donne une visite inactive
## (jamais de pas ni de Balls rendus par erreur).
static func from_dict(dict: Dictionary) -> SafariVisit:
	var visit := SafariVisit.new()
	if not JsonFields.get_bool(dict, "active"):
		return visit
	var steps := JsonFields.get_int(dict, "steps_left", -1)
	var balls := JsonFields.get_int(dict, "balls_left", -1)
	if steps < 0 or balls < 1:
		return visit
	visit.active = true
	visit.steps_left = steps
	visit.balls_left = balls
	return visit
