class_name FossilLab
extends RefCounted
## Résurrection des fossiles (jalon 24, T13 ; dossier 27 §10.5, `jalon-24.md` §2.8) : classe
## pure. Données : `data/world/fossils.json` (fossile → espèce, niveau, drapeau) ; aucune espèce
## n'est écrite ici.
##
## L'état se lit **entièrement dans les drapeaux** (la sauvegarde ne change pas, v7) :
## - IDLE : aucun drapeau `flag` de fossile n'est posé ;
## - REVIVING : le drapeau d'un fossile est posé ([method deposit] : fossile retiré du Sac) ;
## - READY : en plus, `ready_flag` est posé ([method on_map_entered] : le joueur est ressorti
##   sur `ready_map`, cas limite 9).
## [method collect] donne le Pokémon par une **interface injectée** (un [Callable]
## `gift(species: StringName, level: int) -> bool`, vrai si le Pokémon est écrit dans l'équipe ou
## au Stockage) ; la vraie sera un adaptateur de `PokemonGift` (J20). Les drapeaux ne sont effacés
## qu'après un don réussi, dans le même appel synchrone : la sauvegarde forcée qui suit contient
## le Pokémon **et** l'état IDLE (don idempotent, §10.5 n° 5).

enum State { IDLE, REVIVING, READY }

const DATA_FILE: String = "res://data/world/fossils.json"

var _fossils: Dictionary[StringName, Dictionary] = {}
var _order: Array[StringName] = []
var _ready_map: StringName = &""
var _ready_flag: StringName = &""
var _errors: PackedStringArray = PackedStringArray()


## Charge les données. Faux si le fichier est absent ou invalide ([method get_errors]).
func load_file(path: String = DATA_FILE) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return _fail("%s : objet JSON attendu" % path)
	return add_from_dict(json.data, path)


## Lit des données déjà analysées (format de `data/world/fossils.json`).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var fossils: Variant = data.get("fossils")
	if not fossils is Dictionary or not data.get("ready_map") is String \
			or not data.get("ready_flag") is String:
		return _fail("%s : « ready_map », « ready_flag » et « fossils » attendus" % source)
	_ready_map = StringName(data["ready_map"])
	_ready_flag = StringName(data["ready_flag"])
	var ok := true
	for key: Variant in fossils:
		var entry: Variant = fossils[key]
		if not entry is Dictionary or not (entry as Dictionary).get("species") is String \
				or not (entry as Dictionary).get("flag") is String \
				or not ((entry as Dictionary).get("level") is float \
					or (entry as Dictionary).get("level") is int) \
				or int(entry["level"]) < 1:
			ok = _fail("%s : fossile « %s » : species, level (≥ 1) et flag attendus"
				% [source, key])
			continue
		var id := StringName(str(key))
		if not _fossils.has(id):
			_order.append(id)
		_fossils[id] = {
			&"species": StringName(entry["species"]), &"level": int(entry["level"]),
			&"flag": StringName(entry["flag"]),
		}
	return ok


## Identifiants des fossiles connus, dans l'ordre des données.
func fossil_ids() -> Array[StringName]:
	return _order.duplicate()


func species_of(fossil: StringName) -> StringName:
	return _fossils.get(fossil, {}).get(&"species", &"")


func level_of(fossil: StringName) -> int:
	return _fossils.get(fossil, {}).get(&"level", 0)


## Drapeau « résurrection en cours » du fossile (&"" si inconnu).
func flag_of(fossil: StringName) -> StringName:
	return _fossils.get(fossil, {}).get(&"flag", &"")


func ready_map() -> StringName:
	return _ready_map


func ready_flag() -> StringName:
	return _ready_flag


func state(flags: StoryFlags) -> State:
	if reviving_fossil(flags).is_empty():
		return State.IDLE
	return State.READY if flags.has_flag(_ready_flag) else State.REVIVING


## Le fossile en cours de résurrection (&"" si aucun).
func reviving_fossil(flags: StoryFlags) -> StringName:
	if flags == null:
		return &""
	for id: StringName in _order:
		if flags.has_flag(_fossils[id][&"flag"]):
			return id
	return &""


## Les fossiles du Sac, dans l'ordre des données (choix du dialogue T-60 ; vide : T-63).
func fossils_in_bag(bag: Bag) -> Array[StringName]:
	var found: Array[StringName] = []
	if bag == null:
		return found
	for id: StringName in _order:
		if bag.has(id):
			found.append(id)
	return found


## Le joueur confie [param fossil] (OUI au T-60) : retiré du Sac, drapeau posé (→ REVIVING).
## Faux sans effet si une résurrection est déjà en cours, si le fossile est inconnu ou absent.
func deposit(fossil: StringName, bag: Bag, flags: StoryFlags) -> bool:
	if flags == null or bag == null or not _fossils.has(fossil) \
			or state(flags) != State.IDLE or not bag.has(fossil):
		return false
	bag.remove(fossil)
	flags.set_flag(_fossils[fossil][&"flag"])
	return true


## À l'arrivée sur une carte : sur `ready_map` pendant une résurrection, pose `ready_flag`
## (→ READY). Vrai si le drapeau vient d'être posé.
func on_map_entered(map_id: StringName, flags: StoryFlags) -> bool:
	if flags == null or map_id != _ready_map or state(flags) != State.REVIVING:
		return false
	flags.set_flag(_ready_flag)
	return true


## Remise du Pokémon (T-62) : si READY, appelle [param gift] (`species`, `level`) ; si le don
## réussit, efface les drapeaux (→ IDLE) et renvoie l'espèce donnée. &"" sinon (pas prêt, ou don
## refusé : rien n'est effacé, on pourra réessayer).
func collect(flags: StoryFlags, gift: Callable) -> StringName:
	if state(flags) != State.READY or not gift.is_valid():
		return &""
	var fossil := reviving_fossil(flags)
	var species: StringName = _fossils[fossil][&"species"]
	if not bool(gift.call(species, int(_fossils[fossil][&"level"]))):
		return &""
	flags.set_flag(_fossils[fossil][&"flag"], false)
	flags.set_flag(_ready_flag, false)
	return species


func get_errors() -> PackedStringArray:
	return _errors


func _fail(message: String) -> bool:
	var full := "FossilLab : " + message
	_errors.append(full)
	push_error(full)
	return false
