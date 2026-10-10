class_name IntroScript
extends RefCounted
## Script de l'introduction du Prof. Chen : `data/opening/oak_intro.json` (dossier 13 §3.2,
## §4, §6).
##
## Classe pure. Format :
## [codeblock]
## { "speaker": "Prof. Chen", "yes": "Oui", "no": "Non", "validate": "Valider",
##   "steps": [
##     { "type": "stage", "show": "chen", "at": "center" },
##     { "type": "stage", "show": "nidorino", "at": "right", "effect": "pokeball" },
##     { "type": "stage", "hide": "nidorino" },
##     { "type": "page", "text": "Bonjour !", "speaker": "…" },          (speaker facultatif)
##     { "type": "prompt", "name": "player_name", "text": "Comment t'appelles-tu ?" },
##     { "type": "confirm", "name": "player_name", "text": "{player} ! C'est bien ça ?" } ] }
## [/codeblock]
## **Validation stricte** au chargement (comme [DialogueLibrary]) ; la moindre erreur rejette
## tout le fichier ([method is_loaded] faux) :
##  - type, clé, portrait, emplacement ou effet inconnus ;
##  - « stage » : exactement un de « show » (avec « at ») ou « hide » (sans « at ») ; cacher un
##    portrait absent, ou deux portraits au même emplacement ;
##  - jeton inconnu (seuls `{player}` et `{rival}`), accolade mal formée, ou jeton employé
##    **avant** le prompt qui lui donne sa valeur ;
##  - chaque prompt ([constant PROMPTS]) exactement une fois ; « look » (choix de l'apparence,
##    option B) est prévu mais refusé tant que l'option A est retenue (A2) ;
##  - un « confirm » suit le prompt qu'il confirme (sans autre prompt entre eux) et contient
##    son jeton.
## Les jetons sont résolus par [method resolve] (mêmes noms que [constant DialogueTokens.PLAYER]
## et [constant DialogueTokens.RIVAL], mais ici seulement après leur prompt).

const DEFAULT_PATH: String = "res://data/opening/oak_intro.json"
const TYPE_STAGE: String = "stage"
const TYPE_PAGE: String = "page"
const TYPE_PROMPT: String = "prompt"
const TYPE_CONFIRM: String = "confirm"
const PORTRAITS: Array[StringName] = [&"chen", &"player", &"rival", &"nidorino"]
const SLOTS: Array[StringName] = [&"left", &"center", &"right"]
## Effets d'entrée : sortie de Poké Ball (éclair procédural, §9.2).
const EFFECTS: Array[StringName] = [&"pokeball"]
const PROMPT_PLAYER_NAME: StringName = &"player_name"
const PROMPT_RIVAL_NAME: StringName = &"rival_name"
## Choix de l'apparence (option B, A2) : prévu dans le format, refusé en option A.
const PROMPT_LOOK: StringName = &"look"
## Prompts permis, chacun obligatoire une fois.
const PROMPTS: Array[StringName] = [PROMPT_PLAYER_NAME, PROMPT_RIVAL_NAME]
const TOKEN_PLAYER: StringName = &"player"
const TOKEN_RIVAL: StringName = &"rival"
## Jeton rempli par chaque prompt.
const TOKEN_OF: Dictionary[StringName, StringName] = {
	PROMPT_PLAYER_NAME: TOKEN_PLAYER,
	PROMPT_RIVAL_NAME: TOKEN_RIVAL,
}

const _ROOT_KEYS: Array[String] = ["_note", "speaker", "yes", "no", "validate", "steps"]
const _STEP_KEYS: Dictionary[String, Array] = {
	TYPE_STAGE: ["type", "show", "hide", "at", "effect"],
	TYPE_PAGE: ["type", "text", "speaker"],
	TYPE_PROMPT: ["type", "name", "text"],
	TYPE_CONFIRM: ["type", "name", "text"],
}

var speaker: String = ""
## Libellés du choix de confirmation.
var yes_label: String = ""
var no_label: String = ""
## Libellé du bouton de l'écran de prénom (dossier 13 §5.5).
var validate_label: String = ""
var _steps: Array[IntroStep] = []
var _errors: PackedStringArray = PackedStringArray()


func load_file(path: String = DEFAULT_PATH) -> bool:
	var data := OpeningJson.read_object(path, _errors)
	if data.is_empty():
		_report()
		return false
	return add_from_dict(data, path)


## Applique un dictionnaire déjà lu (tout ou rien).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var errors := PackedStringArray()
	for key: String in OpeningJson.unknown_keys(data, _ROOT_KEYS):
		errors.append("%s : clé inconnue « %s »" % [source, key])
	for key: String in ["speaker", "yes", "no", "validate"]:
		if not OpeningJson.is_text(data.get(key)):
			errors.append("%s : texte « %s » manquant ou vide" % [source, key])
	var steps: Array[IntroStep] = []
	var raw_steps: Variant = data.get("steps")
	if not raw_steps is Array or (raw_steps as Array).is_empty():
		errors.append("%s : liste « steps » non vide attendue" % source)
	else:
		steps = _parse_steps(raw_steps, str(data.get("speaker", "")), source, errors)
	if not errors.is_empty():
		_errors.append_array(errors)
		_report()
		return false
	speaker = data["speaker"]
	yes_label = data["yes"]
	no_label = data["no"]
	validate_label = data["validate"]
	_steps = steps
	return true


func is_loaded() -> bool:
	return not _steps.is_empty()


func size() -> int:
	return _steps.size()


func step(index: int) -> IntroStep:
	return _steps[index] if index >= 0 and index < _steps.size() else null


## Index du prompt [param prompt] (-1 s'il n'existe pas).
func prompt_index(prompt: StringName) -> int:
	for i: int in _steps.size():
		if _steps[i].type == IntroStep.Type.PROMPT and _steps[i].name == prompt:
			return i
	return -1


## Nombre de textes affichés (pages, questions des prompts, confirmations) : ≈ 15 visés
## (dossier 13 §4).
func text_count() -> int:
	var count := 0
	for entry: IntroStep in _steps:
		if entry.type != IntroStep.Type.STAGE:
			count += 1
	return count


## Durée estimée de la lecture, saisie des prénoms non comptée (§4 : 60–90 s au plus) : pour
## chaque texte, son défilement à [param chars_per_second] (0 = instantané) plus
## [param read_seconds] pour le lire et toucher ; [param stage_seconds] par mouvement de scène.
## Les jetons comptent pour un prénom de [param name_length] caractères.
func estimated_seconds(chars_per_second: float, read_seconds: float, stage_seconds: float,
		name_length: int = 10) -> float:
	var sample := "x".repeat(name_length)
	var values: Dictionary[StringName, String] = {TOKEN_PLAYER: sample, TOKEN_RIVAL: sample}
	var total := 0.0
	for entry: IntroStep in _steps:
		if entry.type == IntroStep.Type.STAGE:
			total += stage_seconds
			continue
		var length := resolve(entry.text, values).length()
		if chars_per_second > 0.0:
			total += length / chars_per_second
		total += read_seconds
	return total


func get_errors() -> PackedStringArray:
	return _errors


## [param text] avec `{player}` / `{rival}` remplacés par [param values] (jeton → valeur) ; un
## jeton sans valeur reste tel quel (le chargement garantit qu'il en a une quand on y arrive).
static func resolve(text: String, values: Dictionary[StringName, String]) -> String:
	var result := text
	for token: StringName in DialogueTokens.tokens_in(text):
		if values.has(token):
			result = result.replace("{%s}" % token, values[token])
	return result


func _parse_steps(list: Array, default_speaker: String, source: String,
		errors: PackedStringArray) -> Array[IntroStep]:
	var steps: Array[IntroStep] = []
	var on_stage: Dictionary[StringName, StringName] = {}  # portrait → emplacement
	var answered: Array[StringName] = []  # prompts déjà passés
	var last_prompt: StringName = &""
	for i: int in list.size():
		var where := "%s étape %d" % [source, i + 1]
		var raw: Variant = list[i]
		if not raw is Dictionary:
			errors.append("%s : objet attendu" % where)
			continue
		var dict := raw as Dictionary
		var type: Variant = dict.get("type")
		if not type is String or not _STEP_KEYS.has(type):
			errors.append("%s : type inconnu « %s »" % [where, type])
			continue
		var keys: Array[String] = []
		keys.assign(_STEP_KEYS[type])
		for key: String in OpeningJson.unknown_keys(dict, keys):
			errors.append("%s : clé inconnue « %s »" % [where, key])
		var entry := IntroStep.new()
		match type:
			TYPE_STAGE:
				entry.type = IntroStep.Type.STAGE
				_parse_stage(dict, entry, on_stage, where, errors)
			TYPE_PAGE:
				entry.type = IntroStep.Type.PAGE
				entry.speaker = default_speaker
				if dict.has("speaker"):
					if OpeningJson.is_text(dict["speaker"]):
						entry.speaker = dict["speaker"]
					else:
						errors.append("%s : « speaker » vide" % where)
				_parse_text(dict, entry, answered, where, errors)
			TYPE_PROMPT:
				entry.type = IntroStep.Type.PROMPT
				entry.speaker = default_speaker
				entry.name = _parse_prompt_name(dict, where, errors)
				_parse_text(dict, entry, answered, where, errors)
				if not entry.name.is_empty():
					if answered.has(entry.name):
						errors.append("%s : prompt « %s » en double" % [where, entry.name])
					answered.append(entry.name)
					last_prompt = entry.name
			TYPE_CONFIRM:
				entry.type = IntroStep.Type.CONFIRM
				entry.speaker = default_speaker
				entry.name = _parse_prompt_name(dict, where, errors)
				_parse_text(dict, entry, answered, where, errors)
				if not entry.name.is_empty():
					if entry.name != last_prompt:
						errors.append("%s : « confirm » de « %s » sans son prompt juste avant"
							% [where, entry.name])
					elif not DialogueTokens.tokens_in(entry.text).has(TOKEN_OF[entry.name]):
						errors.append("%s : « confirm » sans le jeton {%s}"
							% [where, TOKEN_OF[entry.name]])
				last_prompt = &""
		steps.append(entry)
	for prompt: StringName in PROMPTS:
		if not answered.has(prompt):
			errors.append("%s : prompt « %s » manquant" % [source, prompt])
	return steps


func _parse_stage(dict: Dictionary, entry: IntroStep,
		on_stage: Dictionary[StringName, StringName], where: String,
		errors: PackedStringArray) -> void:
	if dict.has("show") == dict.has("hide"):
		errors.append("%s : « stage » attend exactement un de « show » ou « hide »" % where)
		return
	entry.show = dict.has("show")
	var portrait: Variant = dict.get("show") if entry.show else dict.get("hide")
	if not portrait is String or not PORTRAITS.has(StringName(portrait)):
		errors.append("%s : portrait inconnu « %s »" % [where, portrait])
		return
	entry.portrait = StringName(portrait)
	if not entry.show:
		if dict.has("at") or dict.has("effect"):
			errors.append("%s : « hide » sans « at » ni « effect »" % where)
		if not on_stage.has(entry.portrait):
			errors.append("%s : « %s » caché sans être sur la scène" % [where, portrait])
		on_stage.erase(entry.portrait)
		return
	var slot: Variant = dict.get("at")
	if not slot is String or not SLOTS.has(StringName(slot)):
		errors.append("%s : emplacement inconnu « %s »" % [where, slot])
		return
	entry.slot = StringName(slot)
	if dict.has("effect"):
		var effect: Variant = dict["effect"]
		if not effect is String or not EFFECTS.has(StringName(effect)):
			errors.append("%s : effet inconnu « %s »" % [where, effect])
		else:
			entry.effect = StringName(effect)
	for other: StringName in on_stage:
		if other != entry.portrait and on_stage[other] == entry.slot:
			errors.append("%s : « %s » et « %s » au même emplacement « %s »"
				% [where, other, portrait, slot])
	on_stage[entry.portrait] = entry.slot


func _parse_text(dict: Dictionary, entry: IntroStep, answered: Array[StringName],
		where: String, errors: PackedStringArray) -> void:
	var text: Variant = dict.get("text")
	if not OpeningJson.is_text(text):
		errors.append("%s : « text » manquant ou vide" % where)
		return
	entry.text = text
	if not DialogueTokens.is_well_formed(entry.text):
		errors.append("%s : accolade mal formée dans « %s »" % [where, text])
	for token: StringName in DialogueTokens.tokens_in(entry.text):
		var prompt: StringName = TOKEN_OF.find_key(token) if TOKEN_OF.values().has(token) else &""
		if prompt.is_empty():
			errors.append("%s : jeton inconnu {%s}" % [where, token])
		elif not answered.has(prompt) and not (entry.type == IntroStep.Type.CONFIRM
				and entry.name == prompt):
			errors.append("%s : jeton {%s} employé avant son prompt" % [where, token])


func _parse_prompt_name(dict: Dictionary, where: String, errors: PackedStringArray) -> StringName:
	var name: Variant = dict.get("name")
	if name is String and StringName(name) == PROMPT_LOOK:
		errors.append("%s : choix de l'apparence absent en option A (dossier 13, A2)" % where)
		return &""
	if not name is String or not PROMPTS.has(StringName(name)):
		errors.append("%s : prompt inconnu « %s »" % [where, name])
		return &""
	return StringName(name)


func _report() -> void:
	for message: String in _errors:
		push_warning("IntroScript : " + message)
