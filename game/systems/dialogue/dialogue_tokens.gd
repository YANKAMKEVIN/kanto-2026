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
## **Locuteur** (OUV.2, dossier 13 §3.5) : les jetons sont aussi permis et résolus dans
## « speaker » (`"speaker": "{rival}"` : le prénom choisi, jamais stocké dans les données) ; un
## locuteur dont un jeton n'a pas de valeur est **caché** (la page, elle, reste) :
## [method resolve_speaker].
## **Accords** (chantier JR, dossier 13 §3.5, JR-7) : `{g:réveillé|réveillée}` s'accorde avec le
## joueur (`GameState.player_look`), `{gr:il|elle}` avec le rival (`GameState.rival_look`).
## Exactement deux formes (masculine puis féminine, l'une peut être vide : `venu{g:|e}`), sans
## accolade ni barre dedans. La valeur de [constant AGREE_PLAYER] / [constant AGREE_RIVAL] dans
## les valeurs des jetons vaut [constant FEMININE] pour la forme féminine ; absente ou autre :
## la forme masculine. Un accord n'omet jamais la page.

## Première espèce sauvage rencontrée **en combat** (GameState.first_wild_species, jalon 7 T0) :
## son nom affiché (« Roucool »). Jamais un Pokémon d'habitant ni seulement observé.
const FIRST_WILD_SPECIES: StringName = &"first_wild_species"
## Prénom du joueur (GameState.player_name, dossier 13 §3.5).
const PLAYER: StringName = &"player"
## Prénom du rival (GameState.rival_name) : le **nom affiché** du rival, jamais son rôle ni ses
## identifiants techniques (dossier 13 §3.5, couche 1).
const RIVAL: StringName = &"rival"
## Jeton partagé (un seul nom affiché de Pokémon) :
## - compagnon (jalon 11, phrases de curiosité n° 50 à 59 : « {pokemon} renifle l'air. ») : son
##   nom affiché ; sans compagnon, pas de valeur ;
## - Pension (J15, jalon-15.md §2.5.2) : le Pokémon gardé ou rendu, **à la place** de celui du
##   compagnon pendant une conversation de la Pension (Boot fusionne les valeurs du
##   [DaycareDirector] par-dessus [method values_for]).
const POKEMON: StringName = &"pokemon"
## Pension (J15) : niveaux gagnés, prix annoncé (nombre formaté, **sans** « ₽ » : le texte le
## porte). Valeurs fournies par le [DaycareDirector] pendant sa conversation seulement.
const LEVELS: StringName = &"levels"
const PRICE: StringName = &"price"
## Pokédex (jalon 17, jalon-17.md §2.5 ; dossier 20 §16 T-1 à T-3, notés `{n}` et `{reste}`) :
## espèces capturées, et ce qu'il manque pour [constant CAUGHT_GOAL] (pas de valeur une fois
## l'objectif atteint : la page « Encore {caught_missing}… » est alors omise). Fournis par Boot
## ([method caught_values]).
const CAUGHT: StringName = &"caught"
const CAUGHT_MISSING: StringName = &"caught_missing"
## Objectif de l'assistant de Chen (dossier 20 §8, H-9 : CS05 à 10 espèces), le seul seuil du
## jeu ; un autre seuil passerait par la donnée.
const CAUGHT_GOAL: int = 10
## Jetons permis dans les données.
const KNOWN: Array[StringName] = [FIRST_WILD_SPECIES, PLAYER, RIVAL, POKEMON, LEVELS, PRICE,
	CAUGHT, CAUGHT_MISSING]
## Jetons « de contexte » : toujours fournis par le directeur qui joue les dialogues où ils
## figurent (la Pension). Ce sont les seuls permis dans la question d'un choix (T-7, T-8 : « Ce
## sera {price} ₽. »), qui ne doit jamais être omise ([DialogueLibrary]).
const CONTEXT: Array[StringName] = [POKEMON, LEVELS, PRICE]
## Accords (JR-7) : préfixe dans le texte et clé dans les valeurs des jetons.
const AGREE_PLAYER: StringName = &"g"
const AGREE_RIVAL: StringName = &"gr"
const AGREEMENTS: Array[StringName] = [AGREE_PLAYER, AGREE_RIVAL]
const FEMININE: String = "f"
const _NAME_CHARS: String = "abcdefghijklmnopqrstuvwxyz_"

static var _agreement_regex: RegEx


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
	var stripped := _regex().sub(text, "", true)
	for token: StringName in tokens_in(text):
		stripped = stripped.replace("{%s}" % token, "")
	return not stripped.contains("{") and not stripped.contains("}")


## Texte de [param text] avec ses jetons remplacés par [param values] ; "" si un jeton n'a pas
## de valeur (absente ou vide) : la page est alors omise. Sans jeton : le texte tel quel.
static func resolve(text: String, values: Dictionary[StringName, String]) -> String:
	var result := apply_agreements(text, values)
	for token: StringName in tokens_in(text):
		var value: String = values.get(token, "")
		if value.is_empty():
			return ""
		result = result.replace("{%s}" % token, value)
	return result


## Locuteur [param speaker] avec ses jetons remplacés ; "" (étiquette cachée) si l'un d'eux n'a
## pas de valeur. Sans jeton : tel quel.
static func resolve_speaker(speaker: String, values: Dictionary[StringName, String]) -> String:
	return resolve(speaker, values)


## Pages de [param pages] prêtes à jouer : jetons résolus dans le texte et le locuteur (copie de
## la page), pages dont un jeton du **texte** manque omises (un locuteur sans valeur est caché).
## Sans aucun jeton, renvoie [param pages] elle-même (aucune copie).
static func resolve_pages(pages: Array[DialoguePage],
		values: Dictionary[StringName, String]) -> Array[DialoguePage]:
	if not has_tokens(pages):
		return pages
	var resolved: Array[DialoguePage] = []
	for page: DialoguePage in pages:
		if not needs_values(page.text) and not needs_values(page.speaker):
			resolved.append(page)
			continue
		var text := resolve(page.text, values)
		if text.is_empty():
			continue
		var copy := _copy_with_text(page, text)
		copy.speaker = resolve_speaker(page.speaker, values)
		resolved.append(copy)
	return resolved


## Vrai si une page de [param pages] contient un jeton ou un accord (texte ou locuteur).
static func has_tokens(pages: Array[DialoguePage]) -> bool:
	for page: DialoguePage in pages:
		if needs_values(page.text) or needs_values(page.speaker):
			return true
	return false


## Vrai si [param text] contient un jeton ou un accord à résoudre.
static func needs_values(text: String) -> bool:
	return not tokens_in(text).is_empty() or has_agreements(text)


## Préfixes d'accord de [param text] ([constant AGREE_PLAYER], [constant AGREE_RIVAL]), dans
## l'ordre (doublons compris).
static func agreements_in(text: String) -> Array[StringName]:
	var found: Array[StringName] = []
	for match_: RegExMatch in _regex().search_all(text):
		found.append(StringName(match_.get_string(1)))
	return found


static func has_agreements(text: String) -> bool:
	return _regex().search(text) != null


## [param text] avec chaque accord remplacé par sa forme masculine ou féminine selon
## [param values] ([constant FEMININE] sous [constant AGREE_PLAYER] / [constant AGREE_RIVAL]).
static func apply_agreements(text: String, values: Dictionary[StringName, String]) -> String:
	if not has_agreements(text):
		return text
	var result := ""
	var last := 0
	for match_: RegExMatch in _regex().search_all(text):
		var feminine: bool = values.get(StringName(match_.get_string(1)), "") == FEMININE
		result += text.substr(last, match_.get_start() - last)
		result += match_.get_string(3) if feminine else match_.get_string(2)
		last = match_.get_end()
	return result + text.substr(last)


## Valeurs des accords pour l'apparence du joueur et du rival (Boot, introduction).
static func agreement_values(player_feminine: bool,
		rival_feminine: bool) -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {}
	if player_feminine:
		values[AGREE_PLAYER] = FEMININE
	if rival_feminine:
		values[AGREE_RIVAL] = FEMININE
	return values


## Valeurs des jetons pour une partie (Boot : `values_for(GameState.first_wild_species(),
## pokemon_data, GameState.player_name, GameState.rival_name)`). [param first_wild_species] vide
## ou espèce inconnue : pas de valeur (la page qui la cite est omise) ; prénom vide : pas de
## valeur non plus.
static func values_for(first_wild_species: StringName, data: PokemonData,
		player_name: String = "", rival_name: String = "",
		companion_name: String = "") -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {}
	if not companion_name.is_empty():
		values[POKEMON] = companion_name
	if not player_name.is_empty():
		values[PLAYER] = player_name
	if not rival_name.is_empty():
		values[RIVAL] = rival_name
	if first_wild_species.is_empty() or data == null:
		return values
	var species := data.get_species(first_wild_species)
	if species != null and not species.name.is_empty():
		values[FIRST_WILD_SPECIES] = species.name
	return values


## Valeurs de [constant CAUGHT] et [constant CAUGHT_MISSING] pour [param caught] espèces
## capturées : [constant CAUGHT_MISSING] seulement sous [constant CAUGHT_GOAL].
static func caught_values(caught: int) -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {CAUGHT: str(maxi(caught, 0))}
	if caught < CAUGHT_GOAL:
		values[CAUGHT_MISSING] = str(CAUGHT_GOAL - maxi(caught, 0))
	return values


static func _regex() -> RegEx:
	if _agreement_regex == null:
		_agreement_regex = RegEx.create_from_string("\\{(g|gr):([^{}|]*)\\|([^{}|]*)\\}")
	return _agreement_regex


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
