class_name StorageSelection
extends RefCounted
## Le Pokémon sélectionné dans l'écran Stockage : une liste ([enum StorageRules.Place]) et un
## index. Donnée pure, de session : gardée pendant la visite, jamais sauvegardée
## (jalon-07.md §5). Index −1 = aucune sélection.

var place: StorageRules.Place = StorageRules.Place.PARTY
var index: int = -1


func _init(at_place: StorageRules.Place = StorageRules.Place.PARTY, at_index: int = -1) -> void:
	place = at_place
	index = at_index


## Sélection à l'ouverture de l'écran : le Pokémon de tête (sinon le premier du stockage,
## sinon aucune).
static func first(party: Party, storage: PokemonStorage) -> StorageSelection:
	return StorageSelection.new(StorageRules.Place.PARTY, 0).clamped(party, storage)


func is_empty() -> bool:
	return index < 0


func equals(other: StorageSelection) -> bool:
	return other != null and other.place == place and other.index == index


## Sélection ramenée dans les listes : même liste, index borné ; liste vide → premier de
## l'autre liste ; tout vide (ou aucune sélection) → aucune.
func clamped(party: Party, storage: PokemonStorage) -> StorageSelection:
	if is_empty():
		return StorageSelection.new()
	var party_size := party.size() if party != null else 0
	var storage_size := storage.size() if storage != null else 0
	var own := party_size if place == StorageRules.Place.PARTY else storage_size
	if own > 0:
		return StorageSelection.new(place, clampi(index, 0, own - 1))
	if place == StorageRules.Place.PARTY and storage_size > 0:
		return StorageSelection.new(StorageRules.Place.STORAGE, 0)
	if place == StorageRules.Place.STORAGE and party_size > 0:
		return StorageSelection.new(StorageRules.Place.PARTY, 0)
	return StorageSelection.new()


func _to_string() -> String:
	return "%s:%d" % [StorageRules.Place.keys()[place], index]
