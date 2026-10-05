class_name StorageRules
extends RefCounted
## Règles métier du Stockage Pokémon V1 (dossier 09 §8, §19 ; jalon-07.md §3.5), indépendantes
## de l'écran : déposer, reprendre, libérer, favori. Classe pure et statique ; c'est **ici**
## que vivent les refus (le dernier Pokémon, l'équipe pleine, le favori), pas dans l'interface.
##
## - Le stockage n'a **aucune limite** (un stockage unique, sans boîtes : dossier 09 §8) ; un
##   Pokémon déposé arrive à la fin (ordre d'arrivée), un Pokémon repris arrive en fin d'équipe.
## - Déplacer garde **la même instance** : PV, PP, XP, favori et histoire ne changent pas.
## - « Garder au moins un Pokémon avec toi » (Q-7) : l'équipe doit garder au moins un Pokémon
##   **en état de combattre** après un dépôt ou une libération depuis l'équipe.
## - Un favori ne se libère pas, sans contournement : il faut d'abord retirer le favori.
## - Libérer retire le Pokémon, sans trace : le Pokédex et la statistique « Captures »
##   (carrière, [method TrainerSummary.capture_count]) n'en dépendent pas.
## - Refus : rien ne change. Ordre des refus : introuvable, puis dernier Pokémon, puis favori.

## Où se trouve un Pokémon.
enum Place { PARTY, STORAGE }
## Résultat d'une règle. Texte affiché : [method StorageViews.status_text].
enum Status {
	OK,
	LAST_POKEMON, ## L'équipe garderait 0 Pokémon en état de combattre.
	PARTY_FULL, ## Reprendre avec 6 Pokémon dans l'équipe.
	FAVORITE, ## Libérer un favori.
	NOT_FOUND, ## Aucune place à cet index.
}


## Pokémon de [param place] à [param index], ou null.
static func get_pokemon(party: Party, storage: PokemonStorage, place: Place,
		index: int) -> Pokemon:
	if place == Place.PARTY:
		return party.get_at(index) if party != null else null
	return storage.get_at(index) if storage != null else null


## Vrai si l'équipe garde au moins un Pokémon en état de combattre sans celui de la place
## [param without_index] (Q-7).
static func keeps_able(party: Party, without_index: int) -> bool:
	var members := party.get_all()
	for i: int in members.size():
		if i != without_index and not members[i].is_fainted():
			return true
	return false


static func can_deposit(party: Party, index: int) -> Status:
	if party == null or party.get_at(index) == null:
		return Status.NOT_FOUND
	if not keeps_able(party, index):
		return Status.LAST_POKEMON
	return Status.OK


## Dépose le Pokémon [param index] de l'équipe à la fin du stockage. Sélection du résultat :
## sa nouvelle place dans le stockage.
static func deposit(party: Party, storage: PokemonStorage, index: int) -> StorageResult:
	var status := can_deposit(party, index)
	if storage == null:
		status = Status.NOT_FOUND
	if status != Status.OK:
		return _refused(status, party, storage, Place.PARTY, index)
	var pokemon := party.remove_at(index)
	storage.add(pokemon)
	return StorageResult.new(Status.OK, pokemon,
		StorageSelection.new(Place.STORAGE, storage.size() - 1))


static func can_withdraw(party: Party, storage: PokemonStorage, index: int) -> Status:
	if party == null or storage == null or storage.get_at(index) == null:
		return Status.NOT_FOUND
	if party.is_full():
		return Status.PARTY_FULL
	return Status.OK


## Reprend le Pokémon [param index] du stockage en fin d'équipe. Sélection du résultat : sa
## nouvelle place dans l'équipe.
static func withdraw(party: Party, storage: PokemonStorage, index: int) -> StorageResult:
	var status := can_withdraw(party, storage, index)
	if status != Status.OK:
		return _refused(status, party, storage, Place.STORAGE, index)
	var pokemon := storage.remove_at(index)
	party.add(pokemon)
	return StorageResult.new(Status.OK, pokemon,
		StorageSelection.new(Place.PARTY, party.size() - 1))


static func can_release(party: Party, storage: PokemonStorage, place: Place,
		index: int) -> Status:
	var pokemon := get_pokemon(party, storage, place, index)
	if pokemon == null:
		return Status.NOT_FOUND
	if place == Place.PARTY and not keeps_able(party, index):
		return Status.LAST_POKEMON
	if pokemon.favorite:
		return Status.FAVORITE
	return Status.OK


## Libère le Pokémon de [param place] à [param index] : il quitte l'équipe ou le stockage,
## définitivement. La confirmation (LIBÉRER / ANNULER) est celle de l'écran ; la règle, elle,
## est vérifiée ici à chaque appel. Sélection du résultat : celui qui prend sa place (même
## liste), sinon le premier de l'autre liste.
static func release(party: Party, storage: PokemonStorage, place: Place,
		index: int) -> StorageResult:
	var status := can_release(party, storage, place, index)
	if status != Status.OK:
		return _refused(status, party, storage, place, index)
	var pokemon: Pokemon
	if place == Place.PARTY:
		pokemon = party.remove_at(index)
	else:
		pokemon = storage.remove_at(index)
	return StorageResult.new(Status.OK, pokemon,
		StorageSelection.new(place, index).clamped(party, storage))


## Inverse le favori du Pokémon de [param place] à [param index] (dossier 09 §20 : on le marque
## depuis l'Équipe ou depuis le Stockage). Sélection du résultat : inchangée.
static func toggle_favorite(party: Party, storage: PokemonStorage, place: Place,
		index: int) -> StorageResult:
	var pokemon := get_pokemon(party, storage, place, index)
	if pokemon == null:
		return _refused(Status.NOT_FOUND, party, storage, place, index)
	pokemon.favorite = not pokemon.favorite
	return StorageResult.new(Status.OK, pokemon, StorageSelection.new(place, index))


static func _refused(status: Status, party: Party, storage: PokemonStorage, place: Place,
		index: int) -> StorageResult:
	return StorageResult.new(status, get_pokemon(party, storage, place, index),
		StorageSelection.new(place, index))
