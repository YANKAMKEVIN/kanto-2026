class_name DialogueLibrary
extends RefCounted
## Tous les dialogues du jeu, lus dans les fichiers JSON de `data/dialogues/`.
##
## Classe pure (docs/tech/jalon-03.md §2.4). Chaque fichier est un objet
## « identifiant → dialogue » ; les identifiants sont uniques dans tout le dossier.
## [codeblock]
## "mom": {
##   "speaker": "Maman",
##   "variants": [
##     { "unless": ["mom_greeted"], "set": ["mom_greeted"], "auto": true,
##       "pages": ["Bonjour ! Tu es enfin réveillé ?", "J'ai laissé ..."] },
##     { "pages": ["Tu sors ? Profite de cette belle journée.", "..."] }
##   ]
## },
## "breakfast_table": { "narration": true, "pages": ["Ton petit-déjeuner est encore chaud."] }
## [/codeblock]
## Clés de page : text, speaker, pause, face_player, react, turn ({ acteur: cible }, 3B),
## voice ("spirit" : voix d'esprit, J19).
## Sans « variants », les clés d'une variante (pages, if, unless, set, auto) peuvent être
## écrites directement dans le dialogue. Toute clé inconnue est une erreur (faute de frappe).
## Fin d'une variante (jalon 7 §3.3) : **une seule** de « choice » ([DialogueChoice] : confirm,
## cancel, confirm_action, confirm_pages, cancel_pages ; jalon 12 : confirm_cutscene, identifiant
## de scène lancée après un OUI, exclusive de confirm_action ; jalon 13 : confirm_set,
## cancel_set), « action » ([constant ACTIONS]) ou
## « cutscene » (identifiant de scène). L'ancienne clé « heal »: true vaut « action »: "heal".
## « pages » peut manquer (ou être vide) si la variante a une « action » ou une « cutscene » ;
## jamais avec un « choice » (sa dernière page est la question).
## Tirage (jalon 14, jalon-14.md §2.8) : « one_in »: N (entier ≥ 2) sur une variante, qui ne
## s'applique alors qu'une fois sur N ([method Dialogue.pick]) ; jamais avec « auto ».
## Pokédex (jalon 17, jalon-17.md §2.5) : « if_caught_at_least »: N (au moins N espèces
## capturées) et « unless_caught_at_least »: N (moins de N), entiers ≥ 1 ; les deux ensemble
## seulement si le premier est plus petit (sinon la variante ne s'appliquerait jamais).
## Jetons de texte (jalon 7 §3.6, T18) : `{nom}` dans le texte d'une page **et dans
## « speaker »** (`{rival}`, OUV.2), seulement ceux de [constant DialogueTokens.KNOWN] ; toute
## autre accolade est une erreur. La question d'un
## choix n'a pas de jeton (elle ne peut pas être omise), sauf les jetons « de contexte » de la
## Pension ([constant DialogueTokens.CONTEXT], J15).
## Une entrée invalide est écartée, l'erreur est signalée ([method get_errors], push_error).

const DATA_DIR: String = "res://data/dialogues/"
## Actions de fin de variante ou de choix (jalon-07.md §3.3, §6.2) : soin de Maman, soin du
## Centre (rituel, point de repos), Boutique, Stockage.
## Pension (J15, jalon-15.md §2.5.2) : `open_daycare`, le gardien (variante sans page).
## J20 (T13) : `open_elevator`, le panneau d'une cabine d'ascenseur (variante sans page).
const ACTIONS: Array[StringName] = [
	&"heal", &"center_heal", &"open_shop", &"open_storage", &"open_daycare",
	&"open_elevator",
]

const _DIALOGUE_KEYS: Array[String] = ["speaker", "narration", "draft", "variants"]
const _VARIANT_KEYS: Array[String] = [
	"pages", "if", "unless", "set", "auto", "heal", "draft", "action", "choice", "cutscene",
	"one_in", "if_caught_at_least", "unless_caught_at_least", "field", "shop", "if_items", "unless_items", "if_zone",
]
const _CHOICE_KEYS: Array[String] = [
	"confirm", "cancel", "confirm_action", "confirm_pages", "cancel_pages", "confirm_cutscene",
	"confirm_set", "cancel_set",
]
const _PAGE_KEYS: Array[String] = [
	"text", "speaker", "pause", "face_player", "react", "turn", "voice",
]

var _dialogues: Dictionary[StringName, Dialogue] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une
## erreur a été signalée (les entrées valides sont gardées).
func load_dir(dir: String = DATA_DIR) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier introuvable : %s" % dir)
	var files := DirAccess.get_files_at(dir)
	var sorted: Array[String] = []
	sorted.assign(files)
	sorted.sort()
	var ok := true
	for file: String in sorted:
		if file.get_extension() == "json":
			ok = load_file(dir.path_join(file)) and ok
	return ok


## Charge un fichier JSON. Faux si le fichier est illisible ou contient une erreur.
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { identifiant: dialogue } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les dialogues d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _dialogues.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _dialogues[id].source])
			continue
		var dialogue := _parse_dialogue(data[key], where)
		if dialogue == null:
			ok = false
			continue
		dialogue.id = id
		dialogue.source = source
		_dialogues[id] = dialogue
	return ok


func has_dialogue(id: StringName) -> bool:
	return _dialogues.has(id)


## Dialogue [param id], ou null s'il n'existe pas.
func get_dialogue(id: StringName) -> Dialogue:
	return _dialogues.get(id)


## Identifiants connus, triés.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_dialogues.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func size() -> int:
	return _dialogues.size()


## Erreurs signalées depuis la création (fichiers et entrées écartés).
func get_errors() -> PackedStringArray:
	return _errors


## Drapeaux lus par des conditions (« if », « unless ») dans tous les dialogues.
func get_condition_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for dialogue: Dialogue in _dialogues.values():
		for variant: DialogueVariant in dialogue.variants:
			for flag: StringName in variant.if_flags + variant.unless_flags:
				found[flag] = true
	return _sorted_keys(found)


## Drapeaux levés (« set », et « confirm_set » / « cancel_set » d'un choix) par au moins un
## dialogue.
func get_set_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for dialogue: Dialogue in _dialogues.values():
		for variant: DialogueVariant in dialogue.variants:
			var raised := variant.set_flags.duplicate()
			if variant.choice != null:
				raised += variant.choice.confirm_set + variant.choice.cancel_set
			for flag: StringName in raised:
				found[flag] = true
	return _sorted_keys(found)


func _parse_dialogue(value: Variant, where: String) -> Dialogue:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var dialogue := Dialogue.new()
	var ok := _check_keys(entry, _DIALOGUE_KEYS + _VARIANT_KEYS, where)
	if entry.has("speaker"):
		ok = _read_string(entry["speaker"], where + " speaker") and ok
		dialogue.speaker = str(entry["speaker"])
		ok = _check_tokens(dialogue.speaker, where + " speaker") and ok
	if entry.has("narration"):
		ok = _read_bool(entry["narration"], where + " narration") and ok
		dialogue.narration = entry["narration"] is bool and entry["narration"]
	if entry.has("draft"):
		ok = _read_bool(entry["draft"], where + " draft") and ok
		dialogue.draft = entry["draft"] is bool and entry["draft"]
	var raw_variants: Array = []
	if entry.has("variants"):
		for key: String in _VARIANT_KEYS:
			if entry.has(key):
				ok = _fail("%s : « %s » doit être dans une variante" % [where, key])
		if not entry["variants"] is Array or (entry["variants"] as Array).is_empty():
			return _null_fail("%s : « variants » doit être une liste non vide" % where)
		raw_variants = entry["variants"]
	else:
		var single: Dictionary = {}
		for key: String in _VARIANT_KEYS:
			if entry.has(key):
				single[key] = entry[key]
		raw_variants = [single]
	for i: int in raw_variants.size():
		var variant := _parse_variant(raw_variants[i], "%s variante %d" % [where, i + 1])
		if variant == null:
			ok = false
		else:
			dialogue.variants.append(variant)
	return dialogue if ok else null


func _parse_variant(value: Variant, where: String) -> DialogueVariant:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var variant := DialogueVariant.new()
	var ok := _check_keys(entry, _VARIANT_KEYS, where)
	ok = _read_ending(entry, variant, where) and ok
	var pages_optional := not variant.action.is_empty() or not variant.cutscene.is_empty()
	if entry.has("pages") or not pages_optional:
		var pages_ok := _read_pages(entry.get("pages"), variant.pages, "pages", where,
			pages_optional)
		if not pages_ok and variant.pages.is_empty():
			return null
		ok = pages_ok and ok
	if variant.choice != null and not variant.pages.is_empty() \
			and not _question_tokens_ok(variant.pages.back().text):
		ok = _fail("%s : la question d'un choix (dernière page) n'a pas de jeton" % where)
	ok = _read_flags(entry, "if", variant.if_flags, where) and ok
	ok = _read_flags(entry, "unless", variant.unless_flags, where) and ok
	ok = _read_flags(entry, "set", variant.set_flags, where) and ok
	if entry.has("auto"):
		ok = _read_bool(entry["auto"], where + " auto") and ok
		variant.auto = entry["auto"] is bool and entry["auto"]
	if entry.has("draft"):
		ok = _read_bool(entry["draft"], where + " draft") and ok
		variant.draft = entry["draft"] is bool and entry["draft"]
	if entry.has("one_in"):
		ok = _read_one_in(entry, variant, where) and ok
	ok = _read_caught(entry, variant, where) and ok
	if entry.has("field"):
		ok = _read_field(entry, variant, where) and ok
	if entry.has("shop"):
		ok = _read_shop(entry, variant, where) and ok
	ok = _read_items(entry, "if_items", variant.if_items, where) and ok
	ok = _read_items(entry, "unless_items", variant.unless_items, where) and ok
	if entry.has("if_zone"):
		if not entry["if_zone"] is String or (entry["if_zone"] as String).is_empty():
			ok = _fail("%s : « if_zone » doit être un identifiant de zone" % where)
		else:
			variant.if_zone = StringName(entry["if_zone"])
	return variant if ok else null


## « if_items » / « unless_items » (jalon 20) : liste non vide d'identifiants d'objets, sans
## doublon (l'existence des objets est vérifiée par les tests de données).
func _read_items(entry: Dictionary, key: String, out: Array[StringName], where: String) -> bool:
	if not entry.has(key):
		return true
	var value: Variant = entry[key]
	if not value is Array or (value as Array).is_empty():
		return _fail("%s : « %s » doit être une liste non vide d'objets" % [where, key])
	for id: Variant in value:
		if not id is String or (id as String).is_empty() or out.has(StringName(id)):
			out.clear()
			return _fail("%s : « %s » doit être une liste d'objets sans doublon" % [where, key])
		out.append(StringName(id))
	return true


## « shop » (jalon 20) : identifiant de boutique non vide, seulement avec « action »: « open_shop ».
func _read_shop(entry: Dictionary, variant: DialogueVariant, where: String) -> bool:
	var value: Variant = entry["shop"]
	if not value is String or (value as String).is_empty():
		return _fail("%s : « shop » doit être un identifiant de boutique" % where)
	if variant.action != &"open_shop":
		return _fail("%s : « shop » seulement avec « action »: « open_shop »" % where)
	variant.shop = StringName(value)
	return true


## « if_caught_at_least » / « unless_caught_at_least » (jalon 17) : entiers ≥ 1 ; ensemble, le
## premier strictement plus petit que le second.
func _read_caught(entry: Dictionary, variant: DialogueVariant, where: String) -> bool:
	var ok := true
	for key: String in ["if_caught_at_least", "unless_caught_at_least"]:
		if not entry.has(key):
			continue
		var value: Variant = entry[key]
		if not (value is float or value is int) or float(value) != floorf(float(value)) \
				or int(value) < 1:
			ok = _fail("%s : « %s » doit être un entier ≥ 1" % [where, key])
			continue
		if key == "if_caught_at_least":
			variant.caught_at_least = int(value)
		else:
			variant.caught_below = int(value)
	if ok and variant.caught_at_least > 0 and variant.caught_below > 0 \
			and variant.caught_at_least >= variant.caught_below:
		ok = _fail("%s : « if_caught_at_least » doit être < « unless_caught_at_least »"
			% where)
	return ok


## « field » (jalon 16) : « capacité:état », état de [constant FieldMoves.STATE_NAMES] ; refusé
## avec « auto ».
func _read_field(entry: Dictionary, variant: DialogueVariant, where: String) -> bool:
	var value: Variant = entry["field"]
	if not value is String or (value as String).get_slice_count(":") != 2 \
			or (value as String).get_slice(":", 0).is_empty() \
			or not FieldMoves.STATE_NAMES.has((value as String).get_slice(":", 1)):
		return _fail("%s : « field » vaut « capacité:état » (%s)" % [where,
			", ".join(PackedStringArray(FieldMoves.STATE_NAMES))])
	if variant.auto:
		return _fail("%s : « field » interdit avec « auto »" % where)
	variant.field = value
	return true


## « one_in » (jalon 14) : entier ≥ 2 ; refusé avec « auto » (une arrivée sur la carte ne
## tire rien).
func _read_one_in(entry: Dictionary, variant: DialogueVariant, where: String) -> bool:
	var value: Variant = entry["one_in"]
	if not (value is float or value is int) or float(value) != floorf(float(value)) \
			or int(value) < 2:
		return _fail("%s : « one_in » doit être un entier ≥ 2" % where)
	if variant.auto:
		return _fail("%s : « one_in » interdit avec « auto »" % where)
	variant.one_in = int(value)
	return true


## Fin de la variante : « heal » (ancienne forme), « action », « choice », « cutscene » ; une
## seule. Lue avant les pages (elle dit si les pages peuvent manquer).
func _read_ending(entry: Dictionary, variant: DialogueVariant, where: String) -> bool:
	var ok := true
	var endings: Array[String] = []
	for key: String in ["heal", "action", "choice", "cutscene"]:
		if entry.has(key):
			endings.append(key)
	if endings.size() > 1:
		ok = _fail("%s : une seule fin parmi %s" % [where, ", ".join(endings)])
	if entry.has("heal"):
		if _read_bool(entry["heal"], where + " heal"):
			if entry["heal"]:
				variant.action = &"heal"
		else:
			ok = false
	if entry.has("action"):
		var action := _read_action(entry["action"], where + " action")
		ok = not action.is_empty() and ok
		variant.action = action
	if entry.has("cutscene"):
		if not entry["cutscene"] is String or (entry["cutscene"] as String).is_empty():
			ok = _fail("%s : « cutscene » doit être un identifiant de scène" % where)
		else:
			variant.cutscene = StringName(entry["cutscene"])
	if entry.has("choice"):
		variant.choice = _parse_choice(entry["choice"], where + " choice")
		ok = variant.choice != null and ok
	return ok


func _parse_choice(value: Variant, where: String) -> DialogueChoice:
	if not value is Dictionary:
		return _null_fail("%s : un objet { confirm, cancel, … } est attendu" % where)
	var entry: Dictionary = value
	var choice := DialogueChoice.new()
	var ok := _check_keys(entry, _CHOICE_KEYS, where)
	for key: String in ["confirm", "cancel"]:
		if not entry.get(key) is String or (entry[key] as String).strip_edges().is_empty():
			ok = _fail("%s : « %s » doit être un libellé non vide" % [where, key])
	if ok:
		choice.confirm_label = entry["confirm"]
		choice.cancel_label = entry["cancel"]
	if entry.has("confirm_action"):
		choice.confirm_action = _read_action(entry["confirm_action"], where + " confirm_action")
		ok = not choice.confirm_action.is_empty() and ok
	if entry.has("confirm_cutscene"):
		ok = _read_confirm_cutscene(entry, choice, where) and ok
	# Jalon 13 (§2.13) : drapeaux levés selon le bouton choisi, listes non vides.
	for key: String in ["confirm_set", "cancel_set"]:
		if not entry.has(key):
			continue
		if not entry[key] is Array or (entry[key] as Array).is_empty():
			ok = _fail("%s : « %s » doit être une liste non vide de drapeaux" % [where, key])
		else:
			var into: Array[StringName] = choice.confirm_set if key == "confirm_set" \
				else choice.cancel_set
			ok = _read_flags(entry, key, into, where) and ok
	if entry.has("confirm_pages"):
		ok = _read_pages(entry["confirm_pages"], choice.confirm_pages, "confirm_pages", where,
			true) and ok
	if entry.has("cancel_pages"):
		ok = _read_pages(entry["cancel_pages"], choice.cancel_pages, "cancel_pages", where,
			true) and ok
	return choice if ok else null


## Liste de pages [param key] ; vide permise seulement si [param may_be_empty].
func _read_pages(value: Variant, into: Array[DialoguePage], key: String, where: String,
		may_be_empty: bool) -> bool:
	if not value is Array or (not may_be_empty and (value as Array).is_empty()):
		return _fail("%s : « %s » doit être une liste %s" % [where, key,
			"de pages" if may_be_empty else "non vide"])
	var ok := true
	var pages: Array = value
	for i: int in pages.size():
		var page := _parse_page(pages[i], "%s %s %d" % [where, key.replace("pages", "page"),
			i + 1])
		if page == null:
			ok = false
		else:
			into.append(page)
	return ok


## Action connue ([constant ACTIONS]), sinon &"" (erreur signalée).
func _read_action(value: Variant, where: String) -> StringName:
	if not value is String or not ACTIONS.has(StringName(value)):
		_fail("%s : action inconnue « %s » (attendu : %s)" % [where, value, ACTIONS])
		return &""
	return StringName(value)


func _parse_page(value: Variant, where: String) -> DialoguePage:
	if value is String:
		if (value as String).strip_edges().is_empty():
			return _null_fail("%s : texte vide" % where)
		if not _check_tokens(value, where):
			return null
		return DialoguePage.new(value)
	if not value is Dictionary:
		return _null_fail("%s : texte ou objet { \"text\": … } attendu" % where)
	var entry: Dictionary = value
	var ok := _check_keys(entry, _PAGE_KEYS, where)
	if not entry.get("text") is String or (entry["text"] as String).strip_edges().is_empty():
		return _null_fail("%s : « text » doit être un texte non vide" % where)
	var page := DialoguePage.new(entry["text"])
	ok = _check_tokens(page.text, where) and ok
	if entry.has("speaker"):
		ok = _read_string(entry["speaker"], where + " speaker") and ok
		page.speaker = str(entry["speaker"])
		ok = _check_tokens(page.speaker, where + " speaker") and ok
	if entry.has("voice"):
		if entry["voice"] is String and DialoguePage.VOICES.has(StringName(entry["voice"])):
			page.voice = StringName(entry["voice"])
		else:
			ok = _fail("%s : « voice » inconnue (attendu : %s)" % [where, DialoguePage.VOICES])
	if entry.has("pause"):
		var pause: Variant = entry["pause"]
		if not (pause is float or pause is int) or float(pause) < 0.0:
			ok = _fail("%s : « pause » doit être un nombre de secondes ≥ 0" % where)
		else:
			page.pause = float(pause)
	if entry.has("face_player"):
		ok = _read_bool(entry["face_player"], where + " face_player") and ok
		page.face_player = entry["face_player"] is bool and entry["face_player"]
	if entry.has("react"):
		if not entry["react"] is String or (entry["react"] as String).is_empty():
			ok = _fail("%s : « react » doit être un identifiant" % where)
		else:
			page.react = StringName(entry["react"])
	if entry.has("turn"):
		ok = _read_turn(entry["turn"], page.turn, where) and ok
	return page if ok else null


## Jetons de [param text] : bien formés et connus ([constant DialogueTokens.KNOWN]).
func _check_tokens(text: String, where: String) -> bool:
	if not DialogueTokens.is_well_formed(text):
		return _fail("%s : accolade hors d'un jeton {nom} dans « %s »" % [where, text])
	var ok := true
	for token: StringName in DialogueTokens.tokens_in(text):
		if not DialogueTokens.KNOWN.has(token):
			ok = _fail("%s : jeton inconnu « {%s} » (attendu : %s)" % [where, token,
				DialogueTokens.KNOWN])
	return ok


## La question d'un choix ne peut pas être omise : aucun jeton, sauf ceux « de contexte »
## ([constant DialogueTokens.CONTEXT], toujours fournis par le directeur de la Pension, J15).
static func _question_tokens_ok(text: String) -> bool:
	for token: StringName in DialogueTokens.tokens_in(text):
		if not DialogueTokens.CONTEXT.has(token):
			return false
	return true


## « turn » : objet non vide { acteur: cible }, textes non vides. Qu'une cible qui n'est ni une
## direction ni « player » désigne bien un PNJ se vérifie avec les cartes (tests de données).
func _read_turn(value: Variant, into: Dictionary[StringName, StringName], where: String) -> bool:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return _fail("%s : « turn » doit être un objet { acteur: cible } non vide" % where)
	var turn: Dictionary = value
	for actor: Variant in turn:
		var target: Variant = turn[actor]
		if str(actor).is_empty() or not target is String or (target as String).is_empty():
			return _fail("%s : « turn » : acteur et cible doivent être des textes non vides"
				% where)
		if Grid.is_direction_name(str(actor)):
			return _fail("%s : « turn » : « %s » n'est pas un acteur" % [where, actor])
		into[StringName(str(actor))] = StringName(target)
	return true


func _read_flags(entry: Dictionary, key: String, into: Array[StringName], where: String) -> bool:
	if not entry.has(key):
		return true
	if not entry[key] is Array:
		return _fail("%s : « %s » doit être une liste de drapeaux" % [where, key])
	for flag: Variant in entry[key]:
		if not flag is String or (flag as String).is_empty():
			return _fail("%s : drapeau invalide dans « %s »" % [where, key])
		into.append(StringName(flag))
	return true


func _check_keys(entry: Dictionary, allowed: Array[String], where: String) -> bool:
	var ok := true
	for key: Variant in entry:
		if not allowed.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	return ok


func _read_string(value: Variant, where: String) -> bool:
	return value is String or _fail("%s : texte attendu" % where)


func _read_bool(value: Variant, where: String) -> bool:
	return value is bool or _fail("%s : true ou false attendu" % where)


func _fail(message: String) -> bool:
	var full := "DialogueLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> Variant:
	_fail(message)
	return null


static func _sorted_keys(found: Dictionary[StringName, bool]) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(found.keys())
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


## « confirm_cutscene » d'un choix (jalon 12, T23) : identifiant de scène non vide, jamais avec
## « confirm_action ». L'existence de la scène n'est pas vérifiée ici (tests de données).
func _read_confirm_cutscene(entry: Dictionary, choice: DialogueChoice, where: String) -> bool:
	var value: Variant = entry["confirm_cutscene"]
	if not value is String or (value as String).is_empty():
		return _fail("%s : « confirm_cutscene » doit être un identifiant de scène" % where)
	if entry.has("confirm_action"):
		return _fail("%s : « confirm_cutscene » et « confirm_action » s'excluent" % where)
	choice.confirm_cutscene = StringName(value)
	return true
