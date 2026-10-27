class_name CreditsData
extends RefCounted
## Générique et lignes de l'écran du Panthéon (jalon 30, T15, T16 ; `docs/tech/jalon-30.md` §2.4,
## Q30-1). Classe pure : lit `data/story/credits.json` et compose les **lignes** à afficher à
## partir d'une entrée du Panthéon ([HallOfFame]), sans scène.
##
## Fichier :
## [codeblock]
## { "member": "{pokemon} — N{level}",      # ligne d'un Pokémon (T30-16)
##   "skip": "Passer",                      # bouton du générique déjà vu
##   "blocks": [ { "logo": "KANTO 2026" },  # logo du jeu (texte : repli et accessibilité)
##               { "title": "…" },          # grande ligne
##               { "lines": ["…", "…"] },   # lignes ordinaires
##               { "team": true } ] }       # le joueur, puis son équipe (lignes « member »)
## [/codeblock]
## Un bloc peut porter « draft »: true (texte [D] proposé, à valider par Kevin) : sans effet ici.

enum RowKind { LOGO, TITLE, HEADING, LINE, GAP }

const PATH: String = "res://data/story/credits.json"
const _BLOCK_KEYS: Array[String] = ["logo", "title", "lines", "team"]
const _EXTRA_KEYS: Array[String] = ["draft"]

## Gabarit d'une ligne de Pokémon : {pokemon} (surnom ou nom), {level}.
var member_format: String = "{pokemon} — N{level}"
var skip_label: String = ""
var _blocks: Array[Dictionary] = []
var _errors: PackedStringArray = PackedStringArray()


func load_file(path: String = PATH) -> bool:
	_blocks.clear()
	_errors.clear()
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return load_dict(parsed, path)


## Lit [param data] (contenu du fichier). Faux si une erreur a été signalée (les blocs valides
## sont gardés).
func load_dict(data: Dictionary, where: String = "credits") -> bool:
	var ok := true
	if data.get("member") is String and not (data["member"] as String).is_empty():
		member_format = data["member"]
	elif data.has("member"):
		ok = _fail("%s : « member » doit être un texte non vide" % where)
	if data.get("skip") is String:
		skip_label = data["skip"]
	var blocks: Variant = data.get("blocks")
	if not blocks is Array or (blocks as Array).is_empty():
		return _fail("%s : « blocks » doit être une liste non vide" % where)
	var index := 0
	for raw: Variant in blocks:
		var at := "%s, bloc %d" % [where, index]
		index += 1
		if not raw is Dictionary:
			ok = _fail("%s : un objet est attendu" % at)
			continue
		var block: Dictionary = raw
		var kinds := _BLOCK_KEYS.filter(func(key: String) -> bool: return block.has(key))
		if kinds.size() != 1:
			ok = _fail("%s : une seule clé parmi %s" % [at, ", ".join(_BLOCK_KEYS)])
			continue
		var valid := true
		for key: Variant in block:
			if not _BLOCK_KEYS.has(key) and not _EXTRA_KEYS.has(key):
				valid = _fail("%s : clé inconnue « %s »" % [at, key])
		match kinds[0]:
			"logo", "title":
				if not block[kinds[0]] is String or (block[kinds[0]] as String).is_empty():
					valid = _fail("%s : « %s » doit être un texte non vide" % [at, kinds[0]])
			"lines":
				var lines: Variant = block["lines"]
				if not lines is Array or (lines as Array).is_empty() \
						or not (lines as Array).all(func(v: Variant) -> bool:
							return v is String and not (v as String).is_empty()):
					valid = _fail("%s : « lines » doit être une liste de textes non vides" % at)
			"team":
				if block["team"] != true:
					valid = _fail("%s : « team » vaut true" % at)
		if valid:
			_blocks.append(block)
		ok = valid and ok
	return ok


func get_errors() -> PackedStringArray:
	return _errors


func block_count() -> int:
	return _blocks.size()


## Ligne d'un Pokémon : [param display_name] (surnom ou nom de l'espèce) au niveau [param level].
func member_line(display_name: String, level: int) -> String:
	return member_format.replace("{pokemon}", display_name).replace("{level}", str(level))


## Lignes du générique, dans l'ordre, pour l'entrée du Panthéon [param entry] : chaque ligne est
## { "kind": [enum RowKind], "text": String }, un [constant RowKind.GAP] entre deux blocs. Le bloc
## « team » donne le nom du joueur ([constant RowKind.HEADING]) puis une ligne par Pokémon ;
## [param name_of] : `func(member: Dictionary) -> String` (surnom ou nom de l'espèce).
func rows(entry: Dictionary, name_of: Callable) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for block: Dictionary in _blocks:
		if not result.is_empty():
			result.append({"kind": RowKind.GAP, "text": ""})
		if block.has("logo"):
			result.append({"kind": RowKind.LOGO, "text": block["logo"]})
		elif block.has("title"):
			result.append({"kind": RowKind.TITLE, "text": block["title"]})
		elif block.has("lines"):
			for line: String in block["lines"]:
				result.append({"kind": RowKind.LINE, "text": line})
		elif block.has("team"):
			var player: String = str(entry.get("player", ""))
			if not player.is_empty():
				result.append({"kind": RowKind.HEADING, "text": player})
			for member: Variant in entry.get("team", []):
				if member is Dictionary:
					result.append({"kind": RowKind.LINE, "text": member_line(
						str(name_of.call(member)), int((member as Dictionary).get("level", 1)))})
	return result


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("CreditsData : %s" % message)
	return false
