class_name EggRules
extends RefCounted
## L'œuf (JOH0, `jalon-joh0.md` §2.9 ; dossier JOH-01 §7 : seul l'œuf de Togepi existe, pas de
## reproduction). Classe statique et pure.
##
## Un œuf est un [Pokemon] déjà tiré (espèce, niveau 5, sexe, IV, capacités du niveau 5) qui
## porte des pas restants ([member Pokemon.egg_steps] > 0, [method Pokemon.is_egg]) : il compte
## dans les 6, ne combat pas ([method Party.first_able], [method Battle.check_switch]), ne gagne
## pas d'XP, ne peut être ni compagnon, ni favori, ni libéré **[D]**. Les pas sont décomptés par
## [BondStepCounter] ; à 0, Boot joue l'éclosion ([method hatch]) : le Pokémon prend l'origine
## [constant Pokemon.Origin.EGG], le lien de départ d'un cadeau, et entre au Pokédex vu et capturé.

## Pas d'un œuf de Togepi [D] (dossier JOH-01 §7).
const DEFAULT_STEPS: int = 2000
## Nom affiché d'un œuf (le Pokédex ne connaît pas encore l'espèce).
const NAME: String = "Œuf"
## Paliers de la phrase de l'écran Équipe [D] : au-dessus de [constant CALM_ABOVE] pas,
## « bien tranquille » ; au-dessus de [constant MOVING_ABOVE], « bouge un peu » ; sinon « remue ».
const CALM_ABOVE: int = 1000
const MOVING_ABOVE: int = 300
const HINT_CALM: String = "Il a l'air bien tranquille."
const HINT_MOVING: String = "Il bouge un peu."
const HINT_SOON: String = "On l'entend remuer !"
## Dialogue de l'éclosion (`data/dialogues/johto_systems.json`, jeton {pokemon}).
const HATCH_DIALOGUE: StringName = &"egg_hatched"


## Un œuf de [param species] à [param steps] pas de l'éclosion (niveau 5, tiré avec [param rng]).
## Null si l'espèce est inconnue ou si [param steps] < 1.
static func create(data: PokemonData, species: StringName, steps: int = DEFAULT_STEPS,
		rng: GameRng = null) -> Pokemon:
	if data == null or not data.has_species(species) or steps < 1:
		return null
	var egg := PokemonFactory.create(data, species, 5, rng if rng != null else GameRng.new())
	egg.egg_steps = steps
	return egg


## Phrase de l'écran Équipe selon les pas restants.
static func hint_text(steps: int) -> String:
	if steps > CALM_ABOVE:
		return HINT_CALM
	if steps > MOVING_ABOVE:
		return HINT_MOVING
	return HINT_SOON


## L'éclosion de [param egg] : plus un œuf, rencontre datée (origine EGG, carte [param map]),
## lien de départ d'un cadeau, Pokédex vu et capturé. Faux si ce n'était pas un œuf.
## [param state] : l'autoload GameState en jeu, une instance de `game_state.gd` en test.
static func hatch(egg: Pokemon, state: Node, map: StringName) -> bool:
	if egg == null or not egg.is_egg() or state == null:
		return false
	egg.egg_steps = 0
	state.stamp_meeting(egg, Pokemon.Origin.EGG, map)
	state.record_seen(egg.species_id, map)
	state.record_caught(egg.species_id, map)
	return true


## Vrai si [param pokemon] est un œuf prêt à éclore (plus qu'un pas, posé par [BondStepCounter]).
static func is_ready(pokemon: Pokemon) -> bool:
	return pokemon != null and pokemon.egg_steps == 1
