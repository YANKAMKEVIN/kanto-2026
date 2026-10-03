class_name PokedexUpdates
extends RefCounted
## Les mises à jour discrètes du Pokédex (dossier 08 §4 ; jalon-06.md §3.5) : ce qu'une
## observation apporte de nouveau, et le toast qui le dit. Classe pure, statique.
##
## **Un seul toast par observation**, le plus parlant : ÉVOLUTION DÉCOUVERTE, sinon nouvelle
## espèce, sinon nouvel habitat, sinon nouvelle note. Une **capture** n'a pas de toast : la
## carte de capture dit déjà « Nouvelle entrée Pokédex » (après l'activation). **Aucun
## message tant que le Pokédex n'est pas visible** ([method message] avec
## [code]visible = false[/code]) : avant l'activation, les données sont collectées en silence.

enum Kind { NONE, NEW_SPECIES, NEW_HABITAT, NEW_NOTE, EVOLUTION_DISCOVERED }

## Titre du toast de chaque genre (le détail est le nom de l'espèce). Textes d'interface
## provisoires (dossier 08 §4).
const TITLES: Dictionary[Kind, String] = {
	Kind.NEW_SPECIES: "Pokédex mis à jour",
	Kind.NEW_HABITAT: "Nouvel habitat observé",
	Kind.NEW_NOTE: "Pokédex mis à jour",
	Kind.EVOLUTION_DISCOVERED: "Évolution découverte",
}


## Ce que l'enregistrement décrit par [signal Pokedex.recorded] apporte de nouveau
## ([param species] … [param caught] : les arguments du signal), une fois les notes
## rafraîchies ([param new_note] : [method PokedexNotes.refresh] a débloqué une note de
## cette espèce). [param zones] peut être null (pas d'habitat).
static func classify(pokedex: Pokedex, data: PokemonData, zones: ZoneLibrary,
		species: StringName, map: StringName, first_seen: bool, new_map: bool, caught: bool,
		new_note: bool = false) -> Kind:
	if caught or pokedex == null or species.is_empty():
		return Kind.NONE
	if first_seen:
		return Kind.EVOLUTION_DISCOVERED if _family_was_known(pokedex, data, species) \
			else Kind.NEW_SPECIES
	if new_map and _is_new_zone(pokedex, zones, species, map):
		return Kind.NEW_HABITAT
	return Kind.NEW_NOTE if new_note else Kind.NONE


## Toast [titre, détail] du genre [param kind] pour l'espèce [param species_name] ; vide si
## rien n'est à dire ou si le Pokédex n'est pas [param visible].
static func message(kind: Kind, species_name: String, visible: bool) -> PackedStringArray:
	if not visible or not TITLES.has(kind) or species_name.is_empty():
		return PackedStringArray()
	return PackedStringArray([TITLES[kind], species_name])


## Vrai si une autre espèce de la lignée de [param species] était déjà vue.
static func _family_was_known(pokedex: Pokedex, data: PokemonData,
		species: StringName) -> bool:
	if data == null:
		return false
	for column: Array in EvolutionReveal.family(species, data):
		for id: StringName in column:
			if id != species and pokedex.is_seen(id):
				return true
	return false


## Vrai si la zone de [param map] n'apparaissait dans aucune autre carte où [param species]
## a été vue (une nouvelle carte de Bourg Palette n'est pas un nouvel habitat).
static func _is_new_zone(pokedex: Pokedex, zones: ZoneLibrary, species: StringName,
		map: StringName) -> bool:
	if zones == null:
		return false
	var zone := zones.zone_of(map)
	if zone.is_empty():
		return false
	var entry := pokedex.get_entry(species)
	if entry == null:
		return false
	for other: StringName in entry.seen_maps:
		if other != map and zones.zone_of(other) == zone:
			return false
	return true
