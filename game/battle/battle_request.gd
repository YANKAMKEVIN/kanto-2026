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
	request.rules = BattleRules.for_wild(items)
	request.origin_cell = cell
	return request


## Requête d'un combat de dresseur ([param foe_party] déjà bâtie par le directeur, §15.6).
static func trainer_battle(trainer: TrainerData, foe_party: Party,
		world_actors: Dictionary[StringName, StringName] = {}) -> BattleRequest:
	var request := BattleRequest.new()
	request.intro = Intro.TRAINER
	request.trainer = trainer
	request.foe_name = trainer.name if trainer != null else ""
	request.foe_party = foe_party
	request.rules = BattleRules.for_trainer(trainer)
	request.world_actors = world_actors
	return request


func is_wild() -> bool:
	return intro == Intro.WILD
