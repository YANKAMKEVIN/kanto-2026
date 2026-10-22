class_name GiftResult
extends RefCounted
## Résultat d'un don de Pokémon ([method PokemonGift.give], jalon-20.md §2.5.1) : le statut et
## le Pokémon donné. Donnée pure.

var status: PokemonGift.Status = PokemonGift.Status.INVALID
## Le Pokémon reçu (JOINED, STORED) ; null pour un refus.
var pokemon: Pokemon


func _init(result_status: PokemonGift.Status = PokemonGift.Status.INVALID,
		given: Pokemon = null) -> void:
	status = result_status
	pokemon = given


## Le Pokémon a été donné (équipe ou Stockage).
func is_given() -> bool:
	return status == PokemonGift.Status.JOINED or status == PokemonGift.Status.STORED


## Le Pokémon est allé au Stockage, l'équipe étant pleine (message T-30).
func is_stored() -> bool:
	return status == PokemonGift.Status.STORED
