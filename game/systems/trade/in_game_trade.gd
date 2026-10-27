class_name InGameTrade
extends RefCounted
## Échanges fixes avec des PNJ (jalon 25, dossier 28 §6.2, X-15 ; `jalon-25.md` §2.5), lus dans
## `data/trades/*.json`. Classe pure, sans scène.
##
## Règles Kanto 2026 : le Pokémon reçu prend **la place** du Pokémon donné dans l'équipe (pas de
## stockage, pas d'équipe pleine possible), **son niveau**, les capacités de montée de niveau à
## ce niveau, des IV tirés normalement, un surnom fixe, le prénom du PNJ comme dresseur
## d'origine ; PV pleins, sans statut. Pas de bonus d'expérience ni de désobéissance. Chaque
## échange ne se fait qu'une fois (drapeau `<id>_done`).
##
## [method execute] fait tout **dans un seul bloc synchrone** (aucune sauvegarde ne peut tomber
## entre le retrait et l'ajout) : l'autosave n'a lieu qu'à la fin de la scène.

enum Status {
	DONE, ## Échange fait.
	ALREADY_DONE, ## Échange déjà fait (drapeau posé).
	WRONG_SPECIES, ## Le Pokémon choisi n'est pas de l'espèce demandée.
	INVALID, ## Échange inconnu, index invalide, espèce inconnue.
}

const DATA_PATH: String = "res://data/trades/cinnabar.json"
## Jalon 32 (N-14) : tous les fichiers d'échanges (Cramois'Île, échanges RB de `rb_trades.json`).
const DATA_DIR: String = "res://data/trades/"
## Origine du Pokémon reçu (ajoutée en fin d'énumération à l'intégration du J25).
const RECEIVED_ORIGIN: Pokemon.Origin = Pokemon.Origin.TRADE

var _trades: Dictionary[StringName, Dictionary] = {}
var _errors: PackedStringArray = PackedStringArray()


## Sans [param path] : tous les `.json` de [constant DATA_DIR], par ordre alphabétique (jalon 32).
static func load_default(path: String = "") -> InGameTrade:
	var trade := InGameTrade.new()
	if path.is_empty():
		trade.load_dir()
	else:
		trade.load_file(path)
	return trade


## Charge tous les `.json` de [param dir] ; un identifiant en double est une erreur.
func load_dir(dir: String = DATA_DIR) -> bool:
	var files := DirAccess.get_files_at(dir)
	if files.is_empty():
		return _fail("dossier vide ou introuvable : %s" % dir)
	var names: Array[String] = []
	for name: String in files:
		if name.ends_with(".json"):
			names.append(name)
	names.sort()
	var ok := true
	for name: String in names:
		ok = load_file(dir.path_join(name)) and ok
	return ok


func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1, json.get_error_message()])
	if not json.data is Dictionary or not json.data.get("trades") is Dictionary:
		return _fail("%s : « trades » manquant" % path)
	for id: String in json.data["trades"]:
		var t: Variant = json.data["trades"][id]
		if not t is Dictionary:
			return _fail("%s : échange « %s » invalide" % [path, id])
		for key: String in ["npc", "trainer_name", "wants", "gives", "nickname"]:
			if not (t as Dictionary).has(key):
				return _fail("%s : « %s » sans « %s »" % [path, id, key])
		if _trades.has(StringName(id)):
			return _fail("%s : échange « %s » déjà défini" % [path, id])
		_trades[StringName(id)] = t
	return true


func get_errors() -> PackedStringArray:
	return _errors


func ids() -> Array[StringName]:
	var keys: Array[StringName] = _trades.keys()
	keys.sort()
	return keys


func get_trade(id: StringName) -> Dictionary:
	return _trades.get(id, {})


static func done_flag(id: StringName) -> StringName:
	return StringName(String(id) + "_done")


func is_done(id: StringName, flags: StoryFlags) -> bool:
	return flags.has_flag(done_flag(id))


## Index des Pokémon de l'équipe que le PNJ accepte (espèce demandée), dans l'ordre.
func candidates(id: StringName, party: Party) -> Array[int]:
	var result: Array[int] = []
	if not _trades.has(id):
		return result
	var wanted := StringName(str(_trades[id]["wants"]))
	for i: int in party.size():
		if party.get_at(i).species_id == wanted:
			result.append(i)
	return result


## Fait l'échange [param id] avec le Pokémon d'index [param index]. Rend `{status, given,
## received, companion_cleared}`. Si le Pokémon donné est le compagnon ([param companion_uid]),
## `companion_cleared` est vrai : l'appelant retire le compagnon (règle du J11) avant tout
## rafraîchissement du monde.
func execute(id: StringName, index: int, party: Party, pokedex: Pokedex, flags: StoryFlags,
		data: PokemonData, rng: GameRng, map: StringName = &"", date: String = "",
		companion_uid: String = "") -> Dictionary:
	var result := {"status": Status.INVALID, "given": null, "received": null,
		"companion_cleared": false}
	if not _trades.has(id) or index < 0 or index >= party.size():
		return result
	if is_done(id, flags):
		result["status"] = Status.ALREADY_DONE
		return result
	var t: Dictionary = _trades[id]
	var given := party.get_at(index)
	if given.species_id != StringName(str(t["wants"])):
		result["status"] = Status.WRONG_SPECIES
		return result
	var received := PokemonFactory.create(data, StringName(str(t["gives"])), given.level, rng)
	if received == null:
		return result
	# Bloc synchrone : retrait, ajout à la même place, Pokédex, rencontre, drapeau.
	received.nickname = str(t["nickname"])
	received.record_meeting(RECEIVED_ORIGIN, map, date, str(t["trainer_name"]))
	received.ensure_uid()
	result["companion_cleared"] = not companion_uid.is_empty() and given.uid == companion_uid
	party.remove_at(index)
	party.add(received)
	party.move(party.size() - 1, index)
	if pokedex != null:
		pokedex.mark_seen(received.species_id, map, date)
		pokedex.mark_caught(received.species_id, map, date)
	flags.set_flag(done_flag(id))
	result["status"] = Status.DONE
	result["given"] = given
	result["received"] = received
	return result


## Titre du choix [D] ; raison d'une place refusée [D].
const PICK_TITLE: String = "Échanger un Pokémon"
const REFUSED_REASON: String = "Pas l'espèce demandée"


## Vue du choix pour le [PartyPicker] : [param party] entière, [param accepted] utilisables, les
## autres places avec leur raison.
static func picker_view(party: Party, accepted: Array[int], data: PokemonData) -> PartyPickerView:
	var picker := PartyPickerView.new()
	picker.title = PICK_TITLE
	var members := party.get_all()
	for i: int in members.size():
		var ok := i in accepted
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			ok, "" if ok else REFUSED_REASON, REFUSED_REASON))
	return picker


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("InGameTrade : " + message)
	return false
