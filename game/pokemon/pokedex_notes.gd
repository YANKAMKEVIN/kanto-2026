class_name PokedexNotes
extends RefCounted
## Déblocage des notes d'Observations (dossier 08 §4 ; jalon-06.md §3.5, Q-6). Classe pure,
## statique.
##
## À appeler après chaque observation ou capture ([signal Pokedex.recorded]), après chaque
## changement de drapeau d'histoire et au chargement d'une partie. **Les notes se débloquent
## même avant l'activation du Pokédex** (règle de déblocage : les données sont collectées en
## silence ; elles apparaîtront d'un coup) ; c'est l'appelant qui décide d'un toast
## ([PokedexUpdates]), jamais cette classe.


## Débloque, dans [param pokedex], toutes les notes de [param library] dont la condition
## tient ([method PokedexNoteData.is_met]) ; [param only] limite le parcours à une espèce
## (&"" = toutes). Renvoie les notes nouvelles, dans l'ordre (espèces par ordre du fichier,
## notes par ordre du fichier) : des paires [code][espèce: StringName, note: StringName][/code].
static func refresh(pokedex: Pokedex, library: PokedexLibrary, flags: StoryFlags,
		only: StringName = &"") -> Array[Array]:
	var unlocked: Array[Array] = []
	if pokedex == null or library == null:
		return unlocked
	var ids: Array[StringName] = library.get_species_ids()
	if not only.is_empty():
		ids = [only]
	for species: StringName in ids:
		var entry := pokedex.get_entry(species)
		if entry == null:
			continue
		for note: PokedexNoteData in library.get_notes(species):
			if not entry.notes.has(note.id) and note.is_met(entry, flags):
				pokedex.unlock_note(species, note.id)
				unlocked.append([species, note.id])
	return unlocked


## Espèces distinctes de [param unlocked] (résultat de [method refresh]), dans l'ordre.
static func species_of(unlocked: Array[Array]) -> Array[StringName]:
	var result: Array[StringName] = []
	for pair: Array in unlocked:
		var species: StringName = pair[0]
		if not result.has(species):
			result.append(species)
	return result
