class_name AudioLibrary
extends RefCounted
## Données audio lues dans `data/audio/*.json` (docs/tech/jalon-son.md §1.2, §2, §3).
##
## Classe pure : ni nœud, ni lecteur. Cinq fichiers :
## - `tracks.json` : morceaux (`file`, `kind` music | jingle, `loop`, `loop_offset`,
##   `volume_db`, `expected`, `confirm`, `fade_out_after`) et `events` (moment du jeu → morceau) ;
## - `music_zones.json` : `zones`, `maps`, `movement` (surf, bike), `flags`, `areas` ;
## - `battle_music.json` : catégories de combat, Dresseurs, thèmes du « ! » ;
## - `sfx.json` : bruitages, familles d'attaques (`move_sounds`), cris (`cries`) ;
## - `ambiences.json` : boucles d'ambiance par zone, carte ou météo.
##
## « expected » : le fichier n'est pas encore là (Son.0 : tous) ; le jeu reste muet sans erreur.
## [constant SILENCE] est un morceau réservé (rien ne joue), [constant NONE] une ambiance
## réservée. Toute référence à un morceau, un bruitage ou une ambiance inconnus est une erreur
## ([method get_errors]) ; l'entrée fautive est écartée. Les zones et cartes inconnues de
## `zones.json` sont permises (elles viennent des branches ouvertes : `check_audio_data.py`).

const DATA_DIR: String = "res://data/audio/"
const SILENCE: StringName = &"silence"
const NONE: StringName = &"none"
const KIND_MUSIC: StringName = &"music"
const KIND_JINGLE: StringName = &"jingle"
const MOVEMENT_SURF: StringName = &"surf"
const MOVEMENT_BIKE: StringName = &"bike"
const BATTLE_WILD: StringName = &"wild"
const BATTLE_LEGENDARY: StringName = &"legendary"
const MOVE_CATEGORIES: Array[StringName] = [&"physical", &"special", &"status"]

const _TRACK_KEYS: Array[String] = ["title", "file", "kind", "loop", "loop_offset", "volume_db",
	"expected", "confirm", "fade_out_after"]
const _SFX_KEYS: Array[String] = ["files", "bus", "volume_db", "max_polyphony", "expected",
	"loop"]
const _AMBIENCE_KEYS: Array[String] = ["file", "volume_db", "expected"]

## Morceau : { title, file, kind, loop, loop_offset, volume_db, expected, fade_out_after }.
var _tracks: Dictionary[StringName, Dictionary] = {}
var _events: Dictionary[StringName, StringName] = {}
var _zone_music: Dictionary[StringName, StringName] = {}
var _map_music: Dictionary[StringName, StringName] = {}
var _movement: Dictionary[StringName, StringName] = {}
## Règles de drapeau, dans l'ordre : { flag, maps: Array[StringName], track }.
var _flag_rules: Array[Dictionary] = []
var _area_volume: Dictionary[StringName, float] = {}
## Catégorie de combat → { battle, victory }.
var _battle_categories: Dictionary[StringName, Dictionary] = {}
var _default_battle: StringName = &""
var _trainer_battle: Dictionary[StringName, StringName] = {}
var _legendary_species: Array[StringName] = []
var _encounter_themes: Dictionary[StringName, StringName] = {}
var _default_encounter: StringName = &""
var _encounter_trainers: Dictionary[StringName, StringName] = {}
var _encounter_prefixes: Dictionary[String, StringName] = {}
## Bruitage : { files: PackedStringArray, bus, volume_db, max_polyphony, expected, loop }.
var _sfx: Dictionary[StringName, Dictionary] = {}
var _move_overrides: Dictionary[StringName, StringName] = {}
## Type → catégorie → bruitage.
var _move_by_type: Dictionary[StringName, Dictionary] = {}
var _move_by_category: Dictionary[StringName, StringName] = {}
var _cries: Dictionary = {}
var _ambiences: Dictionary[StringName, Dictionary] = {}
var _ambience_zones: Dictionary[StringName, StringName] = {}
var _ambience_maps: Dictionary[StringName, StringName] = {}
var _ambience_weather: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge les cinq fichiers de [param dir]. Faux si l'un est illisible ou contient une erreur
## (les entrées valides sont gardées).
func load_dir(dir: String = DATA_DIR) -> bool:
	var ok := true
	var files: Array[String] = ["tracks.json", "music_zones.json", "battle_music.json",
		"sfx.json", "ambiences.json"]
	var data: Dictionary[String, Dictionary] = {}
	for file: String in files:
		var parsed := _read(dir.path_join(file))
		ok = not parsed.is_empty() and ok
		data[file] = parsed
	# Les morceaux et les bruitages d'abord : les autres fichiers y renvoient.
	ok = add_tracks(data["tracks.json"], "tracks.json") and ok
	ok = add_sfx(data["sfx.json"], "sfx.json") and ok
	ok = add_music_zones(data["music_zones.json"], "music_zones.json") and ok
	ok = add_battle_music(data["battle_music.json"], "battle_music.json") and ok
	ok = add_ambiences(data["ambiences.json"], "ambiences.json") and ok
	return ok


## Ajoute les morceaux et les événements de [param data] (forme de `tracks.json`).
func add_tracks(data: Dictionary, source: String = "") -> bool:
	var ok := true
	var tracks := JsonFields.get_dict(data, "tracks")
	for raw_id: Variant in tracks:
		var id := StringName(str(raw_id))
		var entry: Variant = tracks[raw_id]
		var where := "%s %s" % [source, id]
		if id == SILENCE:
			ok = _fail("%s : « silence » est réservé" % where)
			continue
		if not entry is Dictionary or not _known_keys(entry, _TRACK_KEYS, where):
			ok = _fail("%s : morceau invalide" % where) if not entry is Dictionary else false
			continue
		var dict: Dictionary = entry
		var file := JsonFields.get_string(dict, "file")
		var kind := JsonFields.get_id(dict, "kind", KIND_MUSIC)
		if not file.begins_with("res://") or not kind in [KIND_MUSIC, KIND_JINGLE]:
			ok = _fail("%s : « file » res:// et « kind » music | jingle attendus" % where)
			continue
		_tracks[id] = {
			"title": JsonFields.get_string(dict, "title"),
			"file": file,
			"kind": kind,
			"loop": JsonFields.get_bool(dict, "loop", kind == KIND_MUSIC),
			"loop_offset": JsonFields.get_float(dict, "loop_offset"),
			"volume_db": JsonFields.get_float(dict, "volume_db"),
			"expected": JsonFields.get_bool(dict, "expected"),
			"fade_out_after": JsonFields.get_float(dict, "fade_out_after"),
		}
	var events := JsonFields.get_dict(data, "events")
	for raw_event: Variant in events:
		var track := StringName(str(events[raw_event]))
		if _check_track(track, "%s events.%s" % [source, raw_event]):
			_events[StringName(str(raw_event))] = track
		else:
			ok = false
	return ok


## Ajoute la musique des zones et des cartes (forme de `music_zones.json`).
func add_music_zones(data: Dictionary, source: String = "") -> bool:
	var ok := _add_track_table(JsonFields.get_dict(data, "zones"), _zone_music,
		source + " zones")
	ok = _add_track_table(JsonFields.get_dict(data, "maps"), _map_music,
		source + " maps") and ok
	ok = _add_track_table(JsonFields.get_dict(data, "movement"), _movement,
		source + " movement") and ok
	var rules := JsonFields.get_array(data, "flags")
	for i: int in rules.size():
		var rule: Variant = rules[i]
		var where := "%s flags[%d]" % [source, i]
		if not rule is Dictionary:
			ok = _fail("%s : objet attendu" % where)
			continue
		var track := JsonFields.get_id(rule, "track")
		var flag := JsonFields.get_id(rule, "flag")
		if flag.is_empty() or not _check_track(track, where):
			ok = _fail("%s : « flag » et « track » attendus" % where) if flag.is_empty() else false
			continue
		_flag_rules.append({ "flag": flag, "maps": JsonFields.get_ids(rule, "maps"),
			"track": track })
	var areas := JsonFields.get_dict(data, "areas")
	for raw_area: Variant in areas:
		var area: Variant = areas[raw_area]
		_area_volume[StringName(str(raw_area))] = JsonFields.get_float(
			area if area is Dictionary else {}, "volume_db")
	return ok


## Ajoute les musiques de combat (forme de `battle_music.json`).
func add_battle_music(data: Dictionary, source: String = "") -> bool:
	var ok := true
	var categories := JsonFields.get_dict(data, "categories")
	for raw: Variant in categories:
		var where := "%s categories.%s" % [source, raw]
		var entry: Variant = categories[raw]
		var dict: Dictionary = entry if entry is Dictionary else {}
		var battle := JsonFields.get_id(dict, "battle")
		var victory := JsonFields.get_id(dict, "victory")
		if _check_track(battle, where + ".battle") and _check_track(victory, where + ".victory"):
			_battle_categories[StringName(str(raw))] = { "battle": battle, "victory": victory }
		else:
			ok = false
	_default_battle = JsonFields.get_id(data, "default_category")
	if not _battle_categories.has(_default_battle):
		ok = _fail("%s : default_category inconnue « %s »" % [source, _default_battle])
	var trainers := JsonFields.get_dict(data, "trainers")
	for raw: Variant in trainers:
		var category := StringName(str(trainers[raw]))
		if _battle_categories.has(category):
			_trainer_battle[StringName(str(raw))] = category
		else:
			ok = _fail("%s trainers.%s : catégorie inconnue « %s »" % [source, raw, category])
	_legendary_species = JsonFields.get_ids(data, "legendary_species")
	ok = _add_track_table(JsonFields.get_dict(data, "encounter_themes"), _encounter_themes,
		source + " encounter_themes") and ok
	_default_encounter = JsonFields.get_id(data, "default_encounter")
	if not _encounter_themes.has(_default_encounter):
		ok = _fail("%s : default_encounter inconnu « %s »" % [source, _default_encounter])
	var by_trainer := JsonFields.get_dict(data, "encounter_trainers")
	for raw: Variant in by_trainer:
		var theme := StringName(str(by_trainer[raw]))
		if _encounter_themes.has(theme):
			_encounter_trainers[StringName(str(raw))] = theme
		else:
			ok = _fail("%s encounter_trainers.%s : thème inconnu" % [source, raw])
	var prefixes := JsonFields.get_dict(data, "encounter_prefixes")
	for raw: Variant in prefixes:
		var theme := StringName(str(prefixes[raw]))
		if _encounter_themes.has(theme):
			_encounter_prefixes[str(raw)] = theme
		else:
			ok = _fail("%s encounter_prefixes.%s : thème inconnu" % [source, raw])
	return ok


## Ajoute les bruitages, les familles d'attaques et les cris (forme de `sfx.json`).
func add_sfx(data: Dictionary, source: String = "") -> bool:
	var ok := true
	var sfx := JsonFields.get_dict(data, "sfx")
	for raw: Variant in sfx:
		var id := StringName(str(raw))
		var where := "%s %s" % [source, id]
		var entry: Variant = sfx[raw]
		if not entry is Dictionary or not _known_keys(entry, _SFX_KEYS, where):
			ok = _fail("%s : bruitage invalide" % where) if not entry is Dictionary else false
			continue
		var files := PackedStringArray()
		for file: Variant in JsonFields.get_array(entry, "files"):
			if file is String and (file as String).begins_with("res://"):
				files.append(file)
		var polyphony := JsonFields.get_int(entry, "max_polyphony", 1)
		if files.is_empty() or polyphony < 1:
			ok = _fail("%s : « files » (res://) et « max_polyphony » ≥ 1 attendus" % where)
			continue
		_sfx[id] = {
			"files": files,
			"bus": JsonFields.get_id(entry, "bus", &"Sfx"),
			"volume_db": JsonFields.get_float(entry, "volume_db"),
			"max_polyphony": polyphony,
			"expected": JsonFields.get_bool(entry, "expected"),
			"loop": JsonFields.get_bool(entry, "loop"),
		}
	var sounds := JsonFields.get_dict(data, "move_sounds")
	ok = _add_sfx_table(JsonFields.get_dict(sounds, "moves"), _move_overrides,
		source + " move_sounds.moves") and ok
	ok = _add_sfx_table(JsonFields.get_dict(sounds, "by_category"), _move_by_category,
		source + " move_sounds.by_category") and ok
	for category: StringName in MOVE_CATEGORIES:
		if not _move_by_category.has(category):
			ok = _fail("%s move_sounds.by_category : « %s » manque" % [source, category])
	var by_type := JsonFields.get_dict(sounds, "by_type")
	for raw: Variant in by_type:
		var table: Dictionary[StringName, StringName] = {}
		var entry: Variant = by_type[raw]
		ok = _add_sfx_table(entry if entry is Dictionary else {}, table,
			"%s move_sounds.by_type.%s" % [source, raw]) and ok
		_move_by_type[StringName(str(raw))] = table
	_cries = JsonFields.get_dict(data, "cries")
	if not JsonFields.get_string(_cries, "path_format").contains("%d"):
		ok = _fail("%s cries : « path_format » avec %%d attendu" % source)
	return ok


## Ajoute les ambiances (forme de `ambiences.json`).
func add_ambiences(data: Dictionary, source: String = "") -> bool:
	var ok := true
	var entries := JsonFields.get_dict(data, "ambiences")
	for raw: Variant in entries:
		var id := StringName(str(raw))
		var where := "%s %s" % [source, id]
		var entry: Variant = entries[raw]
		if id == NONE or not entry is Dictionary or not _known_keys(entry, _AMBIENCE_KEYS, where):
			ok = _fail("%s : ambiance invalide" % where)
			continue
		var file := JsonFields.get_string(entry, "file")
		if not file.begins_with("res://"):
			ok = _fail("%s : « file » res:// attendu" % where)
			continue
		_ambiences[id] = { "file": file, "volume_db": JsonFields.get_float(entry, "volume_db"),
			"expected": JsonFields.get_bool(entry, "expected") }
	var tables: Array = [["zones", _ambience_zones], ["maps", _ambience_maps],
		["weather", _ambience_weather]]
	for pair: Array in tables:
		var raw_table := JsonFields.get_dict(data, pair[0])
		var table: Dictionary[StringName, StringName] = pair[1]
		for raw: Variant in raw_table:
			var id := StringName(str(raw_table[raw]))
			if id == NONE or _ambiences.has(id):
				table[StringName(str(raw))] = id
			else:
				ok = _fail("%s %s.%s : ambiance inconnue « %s »" % [source, pair[0], raw, id])
	return ok


func has_track(id: StringName) -> bool:
	return _tracks.has(id)


## Morceau [param id] ({ title, file, kind, loop, loop_offset, volume_db, expected,
## fade_out_after }) ; vide si inconnu ou [constant SILENCE].
func track(id: StringName) -> Dictionary:
	return _tracks.get(id, {})


func track_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_tracks.keys())
	return ids


func is_jingle(id: StringName) -> bool:
	return track(id).get("kind", KIND_MUSIC) == KIND_JINGLE


## Morceau d'un moment du jeu (`events` : « heal », « badge »…) ; "" si aucun.
func event_track(event: StringName) -> StringName:
	return _events.get(event, &"")


## Morceau propre à la carte ; "" si elle n'a pas d'exception.
func map_track(map_id: StringName) -> StringName:
	return _map_music.get(map_id, &"")


## Morceau de la zone ; "" si elle n'en a pas.
func zone_track(zone_id: StringName) -> StringName:
	return _zone_music.get(zone_id, &"")


func zone_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_zone_music.keys())
	return ids


func map_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_map_music.keys())
	return ids


## Morceau d'un mode de déplacement ([constant MOVEMENT_SURF], [constant MOVEMENT_BIKE]) ;
## "" = la musique de la carte continue.
func movement_track(movement: StringName) -> StringName:
	return _movement.get(movement, &"")


## Règles de drapeau ({ flag, maps, track }), dans l'ordre du fichier.
func flag_rules() -> Array[Dictionary]:
	return _flag_rules


## Réglage de volume (dB) d'une partie de carte (« purified ») ; 0 si inconnue.
func area_volume_db(area: StringName) -> float:
	return _area_volume.get(area, 0.0)


func has_battle_category(category: StringName) -> bool:
	return _battle_categories.has(category)


## { battle, victory } de la catégorie ; vide si inconnue.
func battle_category(category: StringName) -> Dictionary:
	return _battle_categories.get(category, {})


## Catégorie de combat d'un Dresseur (défaut : `default_category`).
func trainer_category(trainer_id: StringName) -> StringName:
	return _trainer_battle.get(trainer_id, _default_battle)


func is_legendary(species_id: StringName) -> bool:
	return _legendary_species.has(species_id)


## Thème du « ! » d'un Dresseur : par Dresseur, puis par le plus long préfixe du nom
## (« Jeune Dresseuse » avant « Jeune Dresseur »), puis le thème par défaut.
func encounter_track(trainer_id: StringName, trainer_name: String = "") -> StringName:
	var theme: StringName = _encounter_trainers.get(trainer_id, &"")
	if theme.is_empty():
		var best := ""
		for prefix: String in _encounter_prefixes:
			if prefix.length() > best.length() \
					and (trainer_name == prefix or trainer_name.begins_with(prefix + " ")):
				best = prefix
		theme = _encounter_prefixes.get(best, _default_encounter)
	return _encounter_themes.get(theme, &"")


func has_sfx(id: StringName) -> bool:
	return _sfx.has(id)


## Bruitage [param id] ({ files, bus, volume_db, max_polyphony, expected, loop }) ; vide si
## inconnu.
func sfx(id: StringName) -> Dictionary:
	return _sfx.get(id, {})


func sfx_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_sfx.keys())
	return ids


## Bruitage d'une attaque (SON-11) : exception par attaque → type et catégorie → catégorie.
func move_sfx(move_id: StringName, type: StringName, category: StringName) -> StringName:
	if _move_overrides.has(move_id):
		return _move_overrides[move_id]
	var by_category: Dictionary = _move_by_type.get(type, {})
	if by_category.has(category):
		return by_category[category]
	return _move_by_category.get(category, _move_by_category.get(&"physical", &""))


## Réglages des cris : { path_format, count, bus, volume_db, faint_pitch, expected }.
func cries() -> Dictionary:
	return _cries


func has_ambience(id: StringName) -> bool:
	return _ambiences.has(id)


## Ambiance [param id] ({ file, volume_db, expected }) ; vide si inconnue.
func ambience(id: StringName) -> Dictionary:
	return _ambiences.get(id, {})


## Ambiance d'une carte : météo (si posée) → carte → zone ; "" = aucune.
func ambience_for(map_id: StringName, zone_id: StringName, weather: StringName = &"") -> StringName:
	var id: StringName = _ambience_weather.get(weather, &"") if not weather.is_empty() else &""
	if id.is_empty():
		id = _ambience_maps.get(map_id, _ambience_zones.get(zone_id, &""))
	return &"" if id == NONE else id


## Cartes de [param zones] sans musique (ni exception de carte, ni morceau de zone).
func uncovered_maps(zones: ZoneLibrary) -> Array[StringName]:
	var missing: Array[StringName] = []
	for map_id: StringName in zones.get_maps():
		if not _map_music.has(map_id) and not _zone_music.has(zones.zone_of(map_id)):
			missing.append(map_id)
	return missing


func get_errors() -> PackedStringArray:
	return _errors


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("fichier introuvable : %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		_fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1, json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		_fail("%s : objet attendu" % path)
		return {}
	return json.data


func _add_track_table(raw: Dictionary, table: Dictionary[StringName, StringName],
		where: String) -> bool:
	var ok := true
	for key: Variant in raw:
		var track := StringName(str(raw[key]))
		if _check_track(track, "%s.%s" % [where, key]):
			table[StringName(str(key))] = track
		else:
			ok = false
	return ok


func _add_sfx_table(raw: Dictionary, table: Dictionary[StringName, StringName],
		where: String) -> bool:
	var ok := true
	for key: Variant in raw:
		var id := StringName(str(raw[key]))
		if _sfx.has(id):
			table[StringName(str(key))] = id
		else:
			ok = _fail("%s.%s : bruitage inconnu « %s »" % [where, key, id])
	return ok


## Vrai si [param track] est [constant SILENCE] ou un morceau connu ; sinon l'erreur est notée.
func _check_track(track: StringName, where: String) -> bool:
	if track == SILENCE or _tracks.has(track):
		return true
	return _fail("%s : morceau inconnu « %s »" % [where, track])


func _known_keys(dict: Dictionary, keys: Array[String], where: String) -> bool:
	for key: Variant in dict:
		if not keys.has(str(key)):
			return _fail("%s : clé inconnue « %s »" % [where, key])
	return true


func _fail(message: String) -> bool:
	var full := "AudioLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
