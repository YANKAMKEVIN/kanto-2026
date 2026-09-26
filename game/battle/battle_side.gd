class_name BattleSide
extends RefCounted
## Un camp du combat : équipe, Pokémon en jeu, dresseur, IA (jalon 4 §2.2). Classe pure.

## Nom du dresseur (« Le Rival ») ; vide = Pokémon sauvage (jalon 5).
var trainer_name: String = ""
var party: Party
## Pokémon en jeu (null avant [method Battle.start]).
var active: Battler = null
var is_player: bool = false
## IA du camp ; null pour le joueur (ses choix viennent de la présentation).
var ai: BattleAI = null


func _init(side_party: Party, player_side: bool, side_trainer: String = "",
		side_ai: BattleAI = null) -> void:
	party = side_party
	is_player = player_side
	trainer_name = side_trainer
	ai = side_ai


## Met en jeu [param pokemon] (niveaux de statistiques remis à zéro).
func send_out(pokemon: Pokemon, data: PokemonData) -> void:
	var species := data.get_species(pokemon.species_id)
	var types: Array[StringName] = species.types if species != null else []
	active = Battler.new(pokemon, types)


## Vrai s'il reste au camp un Pokémon non K.O.
func has_able() -> bool:
	return party.has_able()
