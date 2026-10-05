class_name DialogueTokens
extends RefCounted
## Jetons de texte des dialogues (jalon-07.md §3.6) : « Un {first_wild_species}… ».
##
## Classe pure. Un jeton s'écrit `{nom}` (lettres minuscules et « _ ») ; seuls ceux de
## [constant KNOWN] sont permis ([DialogueLibrary] refuse les autres au chargement, et toute
## accolade qui ne forme pas un jeton). Une page dont un jeton n'a **pas de valeur** (absente ou
## vide) est **omise** (dossier 09 §19 : « aucune → la réplique est omise »).
## Le [DialogueRunner] résout les pages au début du dialogue (et au début des pages d'une
## réponse de choix) avec les valeurs de [member DialogueRunner.token_values] ; Boot les
## construit par [method values_for].

## Première espèce sauvage rencontrée **en combat** (GameState.first_wild_species, jalon 7 T0) :
## son nom affiché (« Roucool »). Jamais un Pokémon d'habitant ni seulement observé.
const FIRST_WILD_SPECIES: StringName = &"first_wild_species"
## Jetons permis dans les données.
const KNOWN: Array[StringName] = [FIRST_WILD_SPECIES]
const _NAME_CHARS: String = "abcdefghijklmnopqrstuvwxyz_"


## Jetons de [param text], dans l'ordre (doublons compris). Une accolade qui ne forme pas un
## jeton bien formé est ignorée ici ([method is_well_formed] la signale).
static func tokens_in(text: String) -> Array[StringName]:
	var found: Array[StringName] = []
	var start := text.find("{")
	while start != -1:
		var end := text.find("}", start + 1)
		if end == -1:
			break
		var name := text.substr(start + 1, end - start - 1)
		if _is_name(name):
			found.append(StringName(name))
			start = text.find("{", end + 1)
		else:
			start = text.find("{", start + 1)
	return found


## Vrai si chaque accolade de [param text] appartient à un jeton `{nom}` bien formé (pas
## d'accolade seule, pas de jeton vide ni de majuscule) : une faute de frappe est refusée.
static func is_well_formed(text: String) -> bool:
	var stripped := text
	for token: StringName in tokens_in(text):
		stripped = stripped.replace("{%s}" % token, "")
	return not stripped.contains("{") and not stripped.contains("}")


## Texte de [param text] avec ses jetons remplacés par [param values] ; "" si un jeton n'a pas
## de valeur (absente ou vide) : la page est alors omise. Sans jeton : le texte tel quel.
static func resolve(text: String, values: Dictionary[StringName, String]) -> String:
	var result := text
	for token: StringName in tokens_in(text):
		var value: String = values.get(token, "")
		if value.is_empty():
			return ""
		result = result.replace("{%s}" % token, value)
	return result


## Pages de [param pages] prêtes à jouer : jetons résolus (copie de la page), pages dont un
## jeton manque omises. Sans aucun jeton, renvoie [param pages] elle-même (aucune copie).
static func resolve_pages(pages: Array[DialoguePage],
		values: Dictionary[StringName, String]) -> Array[DialoguePage]:
	if not has_tokens(pages):
		return pages
	var resolved: Array[DialoguePage] = []
	for page: DialoguePage in pages:
		if tokens_in(page.text).is_empty():
			resolved.append(page)
			continue
		var text := resolve(page.text, values)
		if text.is_empty():
			continue
		resolved.append(_copy_with_text(page, text))
	return resolved


## Vrai si une page de [param pages] contient un jeton.
static func has_tokens(pages: Array[DialoguePage]) -> bool:
	for page: DialoguePage in pages:
		if not tokens_in(page.text).is_empty():
			return true
	return false


## Valeurs des jetons pour une partie (Boot : `values_for(GameState.first_wild_species(),
## pokemon_data)`). [param first_wild_species] vide ou espèce inconnue : pas de valeur (la page
## qui la cite est omise).
static func values_for(first_wild_species: StringName,
		data: PokemonData) -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {}
	if first_wild_species.is_empty() or data == null:
		return values
	var species := data.get_species(first_wild_species)
	if species != null and not species.name.is_empty():
		values[FIRST_WILD_SPECIES] = species.name
	return values


static func _is_name(name: String) -> bool:
	if name.is_empty():
		return false
	for i: int in name.length():
		if not _NAME_CHARS.contains(name[i]):
			return false
	return true


static func _copy_with_text(page: DialoguePage, text: String) -> DialoguePage:
	var copy := DialoguePage.new(text)
	copy.speaker = page.speaker
	copy.pause = page.pause
	copy.face_player = page.face_player
	copy.react = page.react
	copy.turn = page.turn.duplicate()
	return copy
