class_name StorageQuery
extends RefCounted
## Recherche et tri de la grille STOCKAGE (jalon 32, T7 ; décision de Kevin N-21, 2026-10-28) :
## recherche par **nom d'espèce**, tri par **espèce** (numéro de Pokédex), **type** et **niveau**.
## Classe pure, statique. Elle ne change **que l'affichage** : elle renvoie des index dans la liste
## réelle ([PokemonStorage]), qu'elle ne modifie jamais ; l'écran et le directeur continuent de
## parler en index réels (déplacer, favori, libérer visent le bon individu, filtre actif ou non).
## L'ordre choisi est de session : jamais sauvegardé.

## Ordre d'arrivée = pas de tri (valeur par défaut).
enum Sort { ARRIVAL, SPECIES, TYPE, LEVEL }

## Libellés courts, dans l'ordre de [enum Sort] (valeurs par défaut [D]).
const SORT_LABELS: PackedStringArray = ["Arrivée", "Espèce", "Type", "Niveau"]
## Bouton de tri : « Tri : Espèce ».
const SORT_FORMAT: String = "Tri : %s"
const SEARCH_PLACEHOLDER: String = "Rechercher"
## Recherche sans résultat dans un stockage non vide.
const NO_MATCH_TEXT: String = "Aucun Pokémon ne correspond."


## Index réels des Pokémon de [param pokemon] à afficher, dans l'ordre d'affichage. [param text] :
## partie du nom d'espèce, sans casse ni accents (vide = tous) ; [param sort] : [enum Sort].
## Tri stable : à clé égale, l'ordre d'arrivée est conservé. Niveau : du plus haut au plus bas.
static func order(pokemon: Array[Pokemon], data: PokemonData, text: String = "",
		sort: int = Sort.ARRIVAL) -> Array[int]:
	var search := PokedexQuery.fold(text.strip_edges())
	var type_rank := _type_rank(data)
	var rows: Array[Array] = []
	for i: int in pokemon.size():
		var species := data.get_species(pokemon[i].species_id) if data != null else null
		var species_name := species.name if species != null else String(pokemon[i].species_id)
		if not search.is_empty() and not PokedexQuery.fold(species_name).contains(search):
			continue
		rows.append([i, _key(pokemon[i], species, sort, type_rank)])
	if sort != Sort.ARRIVAL:
		rows.sort_custom(_before)
	var result: Array[int] = []
	for row: Array in rows:
		result.append(row[0])
	return result


## Tri suivant dans le cycle ARRIVÉE → ESPÈCE → TYPE → NIVEAU → ARRIVÉE.
static func next_sort(sort: int) -> int:
	return (sort + 1) % SORT_LABELS.size()


static func sort_label(sort: int) -> String:
	return SORT_FORMAT % SORT_LABELS[clampi(sort, 0, SORT_LABELS.size() - 1)]


## Clé de tri : tableau d'entiers comparés dans l'ordre.
static func _key(pokemon: Pokemon, species: SpeciesData, sort: int,
		type_rank: Dictionary) -> Array[int]:
	var dex := species.dex if species != null else 0
	match sort:
		Sort.SPECIES:
			return [dex]
		Sort.TYPE:
			var first := 999
			var second := -1
			if species != null and not species.types.is_empty():
				first = type_rank.get(species.types[0], 998)
				if species.types.size() > 1:
					second = type_rank.get(species.types[1], 998)
			return [first, second]
		Sort.LEVEL:
			return [-pokemon.level]
	return []


static func _type_rank(data: PokemonData) -> Dictionary:
	var ranks := {}
	if data == null:
		return ranks
	var ids := data.get_type_chart().get_type_ids()
	for i: int in ids.size():
		ranks[ids[i]] = i
	return ranks


## Ordre strict : clé, puis index réel (rend le tri stable quel que soit l'algorithme).
static func _before(a: Array, b: Array) -> bool:
	var ka: Array[int] = a[1]
	var kb: Array[int] = b[1]
	for i: int in ka.size():
		if ka[i] != kb[i]:
			return ka[i] < kb[i]
	return int(a[0]) < int(b[0])
