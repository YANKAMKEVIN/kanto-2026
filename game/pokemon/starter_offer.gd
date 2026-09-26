class_name StarterOffer
extends RefCounted
## L'offre du labo : les Pokémon proposés et le choix du rival (jalon 4 §2.1, §3.2).
##
## Classe pure, lue dans `data/pokemon/starters.json` (textes du dossier 02 §7) :
## [codeblock]
## {
##   "map": "oak_lab", "level": 5, "prompt": "CHOISIS TON PREMIER PARTENAIRE",
##   "choices": [
##     { "species": "bulbasaur", "npc": "bulbasaur", "blurb": "Calme et tenace." }, ...
##   ],
##   "open_flag": "starter_offered", "done_flag": "starter_chosen",
##   "chosen_scene": "starter_chosen"
## }
## [/codeblock]
## Toutes les clés sont obligatoires ; au moins 2 choix, espèces et PNJ distincts. Les
## drapeaux et la scène sont des données : aucun nom n'est écrit dans le code.
## [method rival_pick] applique la règle du dossier 02 §9 (« il choisit le Pokémon avantagé
## contre celui du joueur ») sans aucun nom d'espèce.

const DATA_PATH: String = "res://data/pokemon/starters.json"

const _KEYS: Array[String] = [
	"map", "level", "prompt", "choices", "open_flag", "done_flag", "chosen_scene",
]
const _CHOICE_KEYS: Array[String] = ["species", "npc", "blurb"]

## Carte du labo.
var map_id: StringName = &""
## Niveau des Pokémon proposés (et de celui du rival).
var level: int = 0
## Légende affichée sur le monde à l'ouverture du choix.
var prompt: String = ""
## Drapeau qui ouvre le choix.
var open_flag: StringName = &""
## Drapeau levé quand le joueur a choisi.
var done_flag: StringName = &""
## Scène jouée juste après le choix.
var chosen_scene: StringName = &""

var _choices: Array[StarterOption] = []
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux (offre vide) si le fichier est illisible ou invalide.
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà décodé. Tout ou rien : une offre invalide reste vide.
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	for key: String in _KEYS:
		if not data.has(key):
			ok = _fail("%s : « %s » est obligatoire" % [source, key])
	if not ok:
		return false
	for key: String in ["map", "open_flag", "done_flag", "chosen_scene", "prompt"]:
		if not data[key] is String or (data[key] as String).strip_edges().is_empty():
			ok = _fail("%s : « %s » doit être un texte non vide" % [source, key])
	var level_value: Variant = data["level"]
	if not (level_value is int or level_value is float) \
			or float(level_value) != floorf(float(level_value)) \
			or int(level_value) < 1 or int(level_value) > ExpCurve.MAX_LEVEL:
		ok = _fail("%s : « level » doit être un entier de 1 à %d" % [source, ExpCurve.MAX_LEVEL])
	var choices := _parse_choices(data["choices"], source)
	if choices.is_empty() or not ok:
		return false
	map_id = StringName(data["map"])
	level = int(level_value)
	prompt = data["prompt"]
	open_flag = StringName(data["open_flag"])
	done_flag = StringName(data["done_flag"])
	chosen_scene = StringName(data["chosen_scene"])
	_choices = choices
	return true


## Vérifie que chaque espèce proposée existe dans [param data]. Faux (push_error) sinon.
func check_species(data: PokemonData) -> bool:
	var ok := true
	for option: StarterOption in _choices:
		if not data.has_species(option.species):
			ok = _fail("espèce proposée inconnue « %s »" % option.species)
	return ok


## Les choix, dans l'ordre du fichier.
func get_choices() -> Array[StarterOption]:
	return _choices.duplicate()


## Choix de l'espèce [param species], ou null.
func get_choice(species: StringName) -> StarterOption:
	for option: StarterOption in _choices:
		if option.species == species:
			return option
	return null


func get_species_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for option: StarterOption in _choices:
		result.append(option.species)
	return result


## PNJ des Pokémon proposés, dans l'ordre du fichier.
func get_npc_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for option: StarterOption in _choices:
		result.append(option.npc)
	return result


## Espèce que prend le rival quand le joueur a choisi [param player_species] : parmi les
## choix restants, celle dont [b]un[/b] type donne le plus grand multiplicateur contre les
## types du Pokémon du joueur ; à égalité, la première dans l'ordre du fichier. &"" (et
## push_error) si le choix du joueur n'est pas proposé ou si une espèce est inconnue.
func rival_pick(player_species: StringName, data: PokemonData) -> StringName:
	var player := data.get_species(player_species)
	if player == null or get_choice(player_species) == null:
		_fail("rival_pick : « %s » n'est pas un choix de l'offre" % player_species)
		return &""
	var chart := data.get_type_chart()
	var best := &""
	var best_score := -1.0
	for option: StarterOption in _choices:
		if option.species == player_species:
			continue
		var species := data.get_species(option.species)
		if species == null:
			_fail("rival_pick : espèce inconnue « %s »" % option.species)
			return &""
		for type: StringName in species.types:
			var score := chart.multiplier(type, player.types)
			if score > best_score:
				best_score = score
				best = option.species
	return best


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _parse_choices(value: Variant, source: String) -> Array[StarterOption]:
	var result: Array[StarterOption] = []
	if not value is Array or (value as Array).size() < 2:
		_fail("%s : « choices » doit être une liste d'au moins 2 choix" % source)
		return result
	var ok := true
	for i: int in (value as Array).size():
		var where := "%s choix %d" % [source, i + 1]
		var entry: Variant = value[i]
		if not entry is Dictionary:
			ok = _fail("%s : un objet est attendu" % where)
			continue
		for key: Variant in entry:
			if not _CHOICE_KEYS.has(str(key)):
				ok = _fail("%s : clé inconnue « %s »" % [where, key])
		var texts_ok := true
		for key: String in _CHOICE_KEYS:
			var text: Variant = (entry as Dictionary).get(key)
			if not text is String or (text as String).strip_edges().is_empty():
				texts_ok = _fail("%s : « %s » doit être un texte non vide" % [where, key])
		if not texts_ok:
			ok = false
			continue
		var option := StarterOption.new()
		option.species = StringName(entry["species"])
		option.npc = StringName(entry["npc"])
		option.blurb = entry["blurb"]
		for other: StarterOption in result:
			if other.species == option.species or other.npc == option.npc:
				ok = _fail("%s : espèce ou PNJ déjà proposé" % where)
		result.append(option)
	if not ok:
		result.clear()
	return result


func _fail(message: String) -> bool:
	var full := "StarterOffer : " + message
	_errors.append(full)
	push_error(full)
	return false
