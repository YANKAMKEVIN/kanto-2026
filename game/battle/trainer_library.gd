class_name TrainerLibrary
extends RefCounted
## Tous les dresseurs, lus dans les fichiers JSON de `data/trainers/` (jalon 4 §2.2).
##
## Classe pure, validation stricte comme [DialogueLibrary]. Chaque fichier est un objet
## « identifiant → dresseur » ; les identifiants sont uniques dans tout le dossier :
## [codeblock]
## "rival_lab": {
##   "name": "Le Rival", "ai": "random",
##   "can_lose": true, "heal_after": true, "gives_exp": false, "prize_money": 0,
##   "end_message": false,
##   "team_by_starter": {
##     "bulbasaur": [{ "species": "charmander", "level": 5 }], ...
##   }
## }
## [/codeblock]
## Clés obligatoires : name, ai, can_lose, heal_after, gives_exp, prize_money, et
## [b]une[/b] des deux : team (équipe fixe) ou team_by_starter (starter du joueur → équipe).
## Facultatives : end_message et start_message (true par défaut ; false = pas de message
## générique, [member TrainerData.end_message]), bag (true par défaut : SAC utilisable,
## [member TrainerData.allow_bag]), prize_per_level (0 par défaut, entier ≥ 0 : argent par
## niveau du dernier Pokémon, [member TrainerData.prize_per_level] ; exclusif d'un
## prize_money > 0).
## Une équipe compte 1 à 6 Pokémon { species, level, moves? }. Les espèces (et les starters
## de team_by_starter) sont vérifiées contre [PokemonData]. « moves » (facultatif, jalon 10
## §2.4) : 1 à 4 capacités distinctes connues de [PokemonData], dans l'ordre, sans contrôle
## « apprenable » ; absent = capacités de Rouge/Bleu au niveau.
## « card » (facultatif, jalon 10 §2.7) : { "name", "title" }, deux textes non vides, la carte
## de présentation d'un Champion ([member TrainerData.card_name], [member TrainerData.card_title]).

const DATA_DIR: String = "res://data/trainers/"

const _KEYS: Array[String] = [
	"name", "ai", "can_lose", "heal_after", "gives_exp", "prize_money", "end_message",
	"start_message", "team", "team_by_starter", "bag", "prize_per_level", "card",
]
const _REQUIRED: Array[String] = [
	"name", "ai", "can_lose", "heal_after", "gives_exp", "prize_money",
]
const _SLOT_KEYS: Array[String] = ["species", "level", "moves"]
const _CARD_KEYS: Array[String] = ["name", "title"]

var _pokemon: PokemonData
var _trainers: Dictionary[StringName, TrainerData] = {}
var _errors: PackedStringArray = PackedStringArray()


## [param pokemon_data] : données chargées, pour vérifier les espèces et créer les équipes.
func _init(pokemon_data: PokemonData) -> void:
	_pokemon = pokemon_data


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une
## erreur a été signalée (les entrées valides sont gardées).
func load_dir(dir: String = DATA_DIR) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier introuvable : %s" % dir)
	var sorted: Array[String] = []
	sorted.assign(DirAccess.get_files_at(dir))
	sorted.sort()
	var ok := true
	for file: String in sorted:
		if file.get_extension() == "json":
			ok = load_file(dir.path_join(file)) and ok
	return ok


## Charge un fichier JSON. Faux s'il est illisible ou contient une erreur.
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { identifiant: dresseur } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les dresseurs d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _trainers.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _trainers[id].source])
			continue
		var trainer := _parse(data[key], where)
		if trainer == null:
			ok = false
			continue
		trainer.id = id
		trainer.source = source
		_trainers[id] = trainer
	return ok


func has_trainer(id: StringName) -> bool:
	return _trainers.has(id)


## Dresseur [param id], ou null.
func get_trainer(id: StringName) -> TrainerData:
	return _trainers.get(id)


## Identifiants connus, triés.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_trainers.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Équipe du dresseur [param trainer_id] contre le starter [param player_starter], créée
## avec [param rng] (IV, sexe). Null (push_error) si le dresseur ou l'équipe n'existe pas.
func build_team(trainer_id: StringName, player_starter: StringName, rng: GameRng) -> Party:
	var trainer := get_trainer(trainer_id)
	if trainer == null:
		_fail("dresseur inconnu « %s »" % trainer_id)
		return null
	var slots := trainer.team_for(player_starter)
	if slots.is_empty():
		_fail("« %s » n'a pas d'équipe contre « %s »" % [trainer_id, player_starter])
		return null
	var party := Party.new()
	for slot: TrainerSlot in slots:
		var pokemon := PokemonFactory.create(_pokemon, slot.species, slot.level, rng)
		# Même règle que DebugStart._create : on remplace, PP pleins, aucun tirage en plus.
		if not slot.moves.is_empty():
			pokemon.moves.clear()
			for move_id: StringName in slot.moves:
				pokemon.learn_move(move_id, _pokemon)
		party.add(pokemon)
	return party


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _parse(value: Variant, where: String) -> TrainerData:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var trainer := TrainerData.new()
	var ok := true
	for key: Variant in entry:
		if not _KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	for key: String in _REQUIRED:
		if not entry.has(key):
			ok = _fail("%s : « %s » est obligatoire" % [where, key])
	if entry.has("team") == entry.has("team_by_starter"):
		ok = _fail("%s : une et une seule des clés « team » et « team_by_starter »" % where)
	if entry.has("name"):
		if not entry["name"] is String or (entry["name"] as String).strip_edges().is_empty():
			ok = _fail("%s : « name » doit être un texte non vide" % where)
		else:
			trainer.name = entry["name"]
	if entry.has("ai"):
		if not entry["ai"] is String or not BattleAI.is_known(StringName(entry["ai"])):
			ok = _fail("%s : « ai » vaut %s" % [where,
				", ".join(PackedStringArray(BattleAI.KINDS))])
		else:
			trainer.ai = StringName(entry["ai"])
	for key: String in ["can_lose", "heal_after", "gives_exp", "end_message", "start_message"]:
		if entry.has(key):
			if entry[key] is bool:
				trainer.set(key, entry[key])
			else:
				ok = _fail("%s : « %s » vaut true ou false" % [where, key])
	if entry.has("bag"):
		if entry["bag"] is bool:
			trainer.allow_bag = entry["bag"]
		else:
			ok = _fail("%s : « bag » vaut true ou false" % where)
	for key: String in ["prize_money", "prize_per_level"]:
		if entry.has(key):
			var money: Variant = entry[key]
			if not (money is int or money is float) or float(money) != floorf(float(money)) \
					or float(money) < 0.0:
				ok = _fail("%s : « %s » doit être un entier ≥ 0" % [where, key])
			else:
				trainer.set(key, int(money))
	if trainer.prize_money > 0 and trainer.prize_per_level > 0:
		ok = _fail("%s : « prize_money » et « prize_per_level » sont exclusifs" % where)
	if entry.has("card"):
		ok = _read_card(entry["card"], trainer, where) and ok
	if entry.has("team"):
		ok = _read_team(entry["team"], trainer.team, where + " team") and ok
	if entry.has("team_by_starter"):
		ok = _read_teams_by_starter(entry["team_by_starter"], trainer, where) and ok
	return trainer if ok else null


## Lit « card » : { "name", "title" }, deux textes non vides, aucune autre clé.
func _read_card(value: Variant, trainer: TrainerData, where: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : « card » doit être { name, title }" % where)
	var card: Dictionary = value
	var ok := true
	for key: Variant in card:
		if not _CARD_KEYS.has(str(key)):
			ok = _fail("%s card : clé inconnue « %s »" % [where, key])
	for key: String in _CARD_KEYS:
		var text: Variant = card.get(key)
		if not text is String or (text as String).strip_edges().is_empty():
			ok = _fail("%s card : « %s » doit être un texte non vide" % [where, key])
	if ok:
		trainer.card_name = card["name"]
		trainer.card_title = card["title"]
	return ok


func _read_teams_by_starter(value: Variant, trainer: TrainerData, where: String) -> bool:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return _fail("%s : « team_by_starter » doit être un objet non vide" % where)
	var ok := true
	for key: Variant in value:
		var starter := StringName(str(key))
		if not _pokemon.has_species(starter):
			ok = _fail("%s team_by_starter : starter inconnu « %s »" % [where, starter])
			continue
		var slots: Array[TrainerSlot] = []
		if _read_team(value[key], slots, "%s team_by_starter « %s »" % [where, starter]):
			trainer.team_by_starter[starter] = slots
		else:
			ok = false
	return ok


func _read_team(value: Variant, into: Array[TrainerSlot], where: String) -> bool:
	if not value is Array or (value as Array).is_empty() \
			or (value as Array).size() > Party.MAX_SIZE:
		return _fail("%s : une équipe de 1 à %d Pokémon est attendue" % [where, Party.MAX_SIZE])
	var ok := true
	for i: int in (value as Array).size():
		var at := "%s %d" % [where, i + 1]
		var entry: Variant = value[i]
		if not entry is Dictionary:
			ok = _fail("%s : un objet { species, level } est attendu" % at)
			continue
		for key: Variant in entry:
			if not _SLOT_KEYS.has(str(key)):
				ok = _fail("%s : clé inconnue « %s »" % [at, key])
		var species := StringName(str(entry.get("species", "")))
		if not _pokemon.has_species(species):
			ok = _fail("%s : espèce inconnue « %s »" % [at, species])
			continue
		var level: Variant = entry.get("level")
		if not (level is int or level is float) or float(level) != floorf(float(level)) \
				or int(level) < 1 or int(level) > ExpCurve.MAX_LEVEL:
			ok = _fail("%s : « level » doit être un entier de 1 à %d" % [at,
				ExpCurve.MAX_LEVEL])
			continue
		var slot := TrainerSlot.new()
		slot.species = species
		slot.level = int(level)
		if entry.has("moves") and not _read_moves(entry["moves"], slot.moves, at):
			ok = false
			continue
		into.append(slot)
	return ok


## Lit « moves » d'un Pokémon : 1 à [constant SpeciesData.MAX_MOVES] identifiants distincts
## et connus. Faux (rien n'est ajouté) sinon.
func _read_moves(value: Variant, into: Array[StringName], where: String) -> bool:
	if not value is Array or (value as Array).is_empty() \
			or (value as Array).size() > SpeciesData.MAX_MOVES:
		return _fail("%s : « moves » doit être une liste de 1 à %d capacités" % [where,
			SpeciesData.MAX_MOVES])
	var ids: Array[StringName] = []
	for item: Variant in value:
		if not item is String:
			return _fail("%s : « moves » ne contient que des identifiants" % where)
		var move_id := StringName(item)
		if not _pokemon.has_move(move_id):
			return _fail("%s : capacité inconnue « %s »" % [where, move_id])
		if ids.has(move_id):
			return _fail("%s : capacité en double « %s »" % [where, move_id])
		ids.append(move_id)
	into.assign(ids)
	return true


func _fail(message: String) -> bool:
	var full := "TrainerLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
