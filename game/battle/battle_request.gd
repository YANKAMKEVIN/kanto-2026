class_name BattleRequest
extends RefCounted
## Ce que le [BattleDirector] doit jouer : sauvage ou dresseur, camps, règles, mise en scène
## d'entrée (jalon 5 §3.8, §15.6). Donnée pure.
##
## Le directeur généralise son `run` en `run_request(request, map)` (T7) : il construit les
## [BattleSide] depuis cette requête, joue le moteur ([Battle], avec [member rules]), puis
## conclut (dresseur : [BattleConclusion] ; sauvage : défaite et soin par
## l'[EncounterDirector]). Un combat sauvage se construit par [method wild] ; un combat de
## dresseur par [method trainer_battle] (l'équipe est bâtie par le directeur, hors de cette
## classe pure).

## L'entrée à jouer : celle d'un dresseur (labo, §3.7 du 4B) ou d'un sauvage (herbe, §3.7).
enum Intro { TRAINER, WILD }

var intro: Intro = Intro.TRAINER
## Dresseur adverse ; null pour un sauvage.
var trainer: TrainerData = null
## Nom du camp adverse pour le [BattleSide] (nom du dresseur ; vide pour un sauvage).
var foe_name: String = ""
## Équipe adverse (déjà construite : le sauvage tiré, ou l'équipe du dresseur).
var foe_party: Party = null
var rules: BattleRules = null
## &"player" / &"foe" → identifiant du PNJ Pokémon de la carte qui combat (cachés, 4B).
var world_actors: Dictionary[StringName, StringName] = {}
## Case de l'herbe qui bouge (point d'origine de l'intro sauvage, §3.7).
var origin_cell: Vector2i = Vector2i.ZERO
## Entrée sauvage « légendaire », plus lente (passe systèmes 2, T30 ;
## [member WildEncounter.legendary_intro]).
var legendary_intro: bool = false
## J23 : visite du Parc Safari de la rencontre Safari ([member GameState.safari] ; null sinon) :
## chaque Safari Ball lancée appelle [method SafariVisit.on_ball_thrown].
var safari_visit: SafariVisit = null
## J23 : multiplicateur de la Safari Ball ([member SafariConfig.ball_bonus]).
var safari_ball_bonus: float = 1.0


## Requête d'un combat sauvage : le sauvage est créé par [method PokemonFactory.create] à
## partir de [param encounter], sur [param cell] (l'herbe qui bouge). [param items] : les objets
## connus, où le moteur lit le bonus des Balls (5D ; null = aucune Ball utilisable).
static func wild(encounter: WildEncounter, data: PokemonData, rng: GameRng,
		cell: Vector2i, items: ItemLibrary = null) -> BattleRequest:
	var request := BattleRequest.new()
	request.intro = Intro.WILD
	request.trainer = null
	request.foe_name = ""
	var party := Party.new()
	party.add(PokemonFactory.create(data, encounter.species, encounter.level, rng))
	request.foe_party = party
	# Combat SPECTRE (jalon 19) : décidé au tirage ([member WildEncounter.ghost]).
	request.rules = BattleRules.for_ghost(items) if encounter.ghost \
		else BattleRules.for_wild(items)
	request.origin_cell = cell
	request.legendary_intro = encounter.legendary_intro
	return request


## Requête d'un combat de dresseur ([param foe_party] déjà bâtie par le directeur, §15.6).
## [param items] : les objets connus (null = Sac inutilisable : aucun objet de soin légal).
static func trainer_battle(trainer: TrainerData, foe_party: Party,
		world_actors: Dictionary[StringName, StringName] = {},
		items: ItemLibrary = null) -> BattleRequest:
	var request := BattleRequest.new()
	request.intro = Intro.TRAINER
	request.trainer = trainer
	request.foe_name = trainer.name if trainer != null else ""
	request.foe_party = foe_party
	request.rules = BattleRules.for_trainer(trainer, items)
	request.world_actors = world_actors
	return request


## J23 : requête d'une rencontre Safari (`jalon-23.md` §2.3) : le sauvage de [param encounter]
## (créé comme pour [method wild]), règles [method BattleRules.for_safari], visite
## [param visit] et multiplicateur [param ball_bonus] de la Safari Ball.
static func safari(encounter: WildEncounter, data: PokemonData, rng: GameRng, cell: Vector2i,
		visit: SafariVisit, ball_bonus: float) -> BattleRequest:
	var request := wild(encounter, data, rng, cell, null)
	request.rules = BattleRules.for_safari()
	request.safari_visit = visit
	request.safari_ball_bonus = ball_bonus
	return request


## J23 : vrai pour une rencontre Safari.
func is_safari() -> bool:
	return rules != null and rules.safari


func is_wild() -> bool:
	return intro == Intro.WILD
