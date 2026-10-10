class_name SaveSystem
extends RefCounted
## Lecture et écriture de la sauvegarde unique du joueur (jalon 5 §16.1, 5C.5).
##
## Classe pure : elle ne connaît ni [GameState] ni l'arbre de scènes. Elle reçoit un
## dictionnaire prêt pour le JSON (`GameState.to_dict()`) et en rend un (`GameState.load_dict`).
## Celui qui la tient (Boot, tâche S2) décide des moments d'autosave.
##
## Garanties :
##  - **un seul emplacement** ([constant DEFAULT_PATH]) ;
##  - **écriture atomique** : le JSON est écrit dans un fichier temporaire, relu et comparé,
##    puis renommé par-dessus la sauvegarde ; une coupure en pleine écriture laisse l'ancienne
##    sauvegarde intacte ;
##  - **format versionné** : [constant VERSION] à la racine ; une version plus ancienne est
##    migrée ([method upgrade]) et les champs absents prennent leur valeur par défaut (côté
##    `GameState.load_dict`) ; une version plus récente est refusée sans être touchée ;
##  - **un fichier corrompu** renvoie une erreur claire ([member last_error]) et est mis de côté
##    (`save.json.corrupt`) plutôt qu'écrasé par l'autosave suivant : il n'est jamais détruit.
## Le système de fichiers est injectable ([SaveFileSystem]) pour des tests déterministes.

## Version du format écrit par cette build ; ajouter un cas à [method upgrade] à chaque
## incrément. À incrémenter quand un champ change de forme, **et aussi** quand on ajoute des
## champs qu'une build plus ancienne effacerait : à la lecture, un champ absent prend bien sa
## valeur par défaut, mais une ancienne build qui lirait le fichier ignorerait les champs
## nouveaux puis les perdrait au premier autosave ; un numéro plus grand la fait refuser le
## fichier sans jamais l'écraser (jalon-06.md §5.1).
## Historique : 1 = jalon 5 (5C.5) ; 2 = jalon 6 (Sac { items, favorites, acquired }, favori
## des Pokémon, notes du Pokédex), une seule version pour tout le J6 ; 3 = jalon 7 (argent,
## première rencontre sauvage), une seule version pour tout le J7 (jalon-07.md §5.1) ; 4 =
## jalon 9 (statut de chaque Pokémon, « status »), une seule version pour tout le J9
## (jalon-09.md §2.2) ; 5 = **provisoire** (jalon 11, T1 : identifiant des Pokémon « uid »,
## compteur « status_turns », compagnon « companion ») — **OUV.1 a réservé la v5** (dossier 13
## §3.4) : à la fusion d'OUV.1 dans cette branche, le J11 devient la **v6** (pas v5 → v6) et ce
## fichier n'est ni fusionné ni installé sur la vraie partie avant (dossier 14 §9).
const VERSION: int = 5
const DEFAULT_PATH: String = "user://save.json"
const TEMP_SUFFIX: String = ".tmp"
const CORRUPT_SUFFIX: String = ".corrupt"
const VERSION_KEY: String = "version"
## Argent donné à une partie v2 migrée (dossier 09 §17 : la même somme qu'une nouvelle partie
## au J7, `GameState.STARTING_MONEY`). Figé ici : c'est un fait de la migration, il ne suit pas
## une future retouche de l'argent de départ.
const V3_MIGRATED_MONEY: int = 3000
## Cartes où un combat sauvage a pu avoir lieu avant la v3 (fait historique figé, pas une
## règle de contenu) : la table `route_1_grass` (data/encounters/route_1.json) couvre la
## Route 1 et l'herbe du nord de Bourg Palette, et aucune autre table n'existait.
const V3_LEGACY_WILD_MAPS: Array[String] = ["route_1", "pallet_town"]
## Parmi elles, celles où « vu » ne pouvait venir que d'une rencontre sauvage, quelle que soit
## la build : la Route 1 n'a jamais eu ni Pokémon à OBSERVER ni Dresseur. À Bourg Palette,
## OBSERVER (J6, T16) marque aussi « vu » le Roucool et le Rattata des habitants.
const V3_LEGACY_BATTLE_ONLY_MAPS: Array[String] = ["route_1"]

## Chemin de la sauvegarde (les tests en changent).
var path: String = DEFAULT_PATH
## Version écrite et acceptée par ce système : toujours [constant VERSION] dans le jeu. Les
## tests la baissent pour simuler une build plus ancienne (un APK du J5 lisant une v2).
var version: int = VERSION
## Accès disque (les tests injectent un système de fichiers en mémoire).
var fs: SaveFileSystem = SaveFileSystem.new()
## Résultat de la dernière opération : OK, ERR_FILE_NOT_FOUND (aucune sauvegarde : cas normal
## d'une nouvelle partie), ERR_FILE_CORRUPT (illisible, mis de côté), ERR_INVALID_DATA (version
## plus récente que cette build), ou l'erreur d'écriture.
var last_status: Error = OK
## Message lisible du dernier échec (vide si OK).
var last_error: String = ""
## Version trouvée dans le fichier par la dernière lecture réussie, avant migration (0 sinon) :
## plus petite que [member version] quand la sauvegarde vient d'être migrée
## ([method migration_note]).
var read_version: int = 0


func _init(file_system: SaveFileSystem = null, save_path: String = DEFAULT_PATH) -> void:
	if file_system != null:
		fs = file_system
	path = save_path


func has_save() -> bool:
	return fs.exists(path)


## Écrit [param state] (racine : dictionnaire, la clé « version » est posée ici) de façon
## atomique. En cas d'échec, la sauvegarde précédente est intacte et le temporaire effacé.
func write(state: Dictionary) -> Error:
	var content := state.duplicate()
	content[VERSION_KEY] = version
	var text := JSON.stringify(content, "\t")
	var temp := path + TEMP_SUFFIX
	var error := fs.write_text(temp, text)
	if error != OK:
		fs.remove(temp)
		return _fail(error, "écriture du fichier temporaire impossible (%s)" % error_string(error))
	if fs.read_text(temp) != text:
		fs.remove(temp)
		return _fail(ERR_FILE_CORRUPT, "relecture du fichier temporaire différente : écriture coupée")
	error = fs.rename(temp, path)
	if error != OK:
		fs.remove(temp)
		return _fail(error, "remplacement de la sauvegarde impossible (%s)" % error_string(error))
	return _ok()


## Lit la sauvegarde, la migre à [constant VERSION] et la renvoie ; dictionnaire vide si elle
## manque ou est invalide ([member last_status], [member last_error]). Un fichier corrompu est
## renommé `<path>.corrupt` ; un fichier d'une version plus récente est laissé tel quel.
func read() -> Dictionary:
	read_version = 0
	if not fs.exists(path):
		_fail(ERR_FILE_NOT_FOUND, "aucune sauvegarde")
		return {}
	var text := fs.read_text(path)
	# JSON.new().parse plutôt que JSON.parse_string : pas d'erreur moteur imprimée, le message
	# est rendu proprement dans last_error.
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	var reason := ""
	if text.is_empty():
		reason = "fichier vide"
	elif parsed == null:
		reason = json.get_error_message()
	elif not parsed is Dictionary:
		reason = "la racine n'est pas un objet"
	elif not JsonFields.is_int((parsed as Dictionary).get(VERSION_KEY)):
		reason = "version absente"
	if not reason.is_empty():
		_quarantine()
		_fail(ERR_FILE_CORRUPT, "sauvegarde illisible (%s), mise de côté dans %s"
			% [reason, _corrupt_path()])
		return {}
	var content := parsed as Dictionary
	var found := int(content[VERSION_KEY])
	var error := upgrade(content, version)
	if error != OK:
		_fail(error, "sauvegarde d'une version plus récente (%d > %d) : mise à jour du jeu requise"
			% [int(content[VERSION_KEY]), version])
		return {}
	read_version = found
	_ok()
	return content


## Ligne du journal de la migration de [param from] à [param to] (« sauvegarde v3 → v4 »), ou
## vide si rien n'a été migré.
static func migration_note(from: int, to: int) -> String:
	return "sauvegarde v%d → v%d" % [from, to] if from < to else ""


## Supprime la sauvegarde (nouvelle partie volontaire ; pas appelé au jalon 5).
func erase() -> Error:
	if not fs.exists(path):
		return _ok()
	var error := fs.remove(path)
	return _ok() if error == OK else _fail(error, "suppression impossible (%s)" % error_string(error))


## Migre [param content] (modifié en place) de sa version à [param target] ([constant VERSION]
## par défaut). OK si la version est la cible ou plus ancienne ; ERR_INVALID_DATA (contenu
## intact) si elle est plus récente. Les champs absents d'une version antérieure à 1 ne sont
## pas ajoutés ici : `GameState.load_dict` leur donne leur valeur par défaut.
static func upgrade(content: Dictionary, target: int = VERSION) -> Error:
	var from := JsonFields.get_int(content, VERSION_KEY, 0)
	if from > target:
		return ERR_INVALID_DATA
	var original := from
	while from < target:
		match from:
			1:
				_upgrade_1_to_2(content)
			2:
				# Avant la v2 (builds du J5), OBSERVER n'existait pas.
				_upgrade_2_to_3(content, original < 2)
			_:
				# 0 → 1 : aucune forme n'a changé, les défauts suffisent.
				# 3 → 4 (J9) : rien à transformer, un Pokémon sans « status » n'a aucun statut
				# (Pokemon.from_dict) ; seul le numéro change, pour qu'une build v3 refuse le
				# fichier au lieu d'effacer les statuts au premier autosave.
				# J11 (jalon-11.md §2.1) : rien à transformer non plus ; les identifiants manquants
				# sont attribués au chargement (Party / PokemonStorage, puis
				# GameState.ensure_unique_uids), le compteur et le compagnon absents valent 0 et
				# « aucun ». Le numéro change pour qu'une build plus ancienne refuse le fichier au
				# lieu d'effacer identifiants et compagnon au premier autosave.
				pass
		from += 1
	content[VERSION_KEY] = target
	return OK


## Jalon 6 (jalon-06.md §5.1) : le Sac plat devient { items, favorites, acquired } ; chaque
## Pokémon (équipe, stockage) reçoit « favorite » = false et chaque entrée du Pokédex
## « notes » = []. Les « times_seen » ne sont PAS touchés : le starter « vu 0 fois » des
## sauvegardes du jalon 5 est déjà corrigé au chargement, quelle que soit la version
## ([method PokedexEntry.ensure_seen], jalon 5, Q-8 du J6) ; une seule règle, pas deux.
## Un champ absent ou mal formé est laissé tel quel : les chargeurs tolérants s'en chargent.
static func _upgrade_1_to_2(content: Dictionary) -> void:
	var bag: Variant = content.get("bag")
	if bag is Dictionary and not (bag as Dictionary).has(Bag.ITEMS_KEY):
		content["bag"] = Bag.upgrade_flat(bag)
	for key: String in ["party", "storage"]:
		var members: Variant = content.get(key)
		if not members is Array:
			continue
		for member: Variant in members:
			if member is Dictionary and not (member as Dictionary).has("favorite"):
				(member as Dictionary)["favorite"] = false
	var entries: Variant = JsonFields.get_dict(content, "pokedex").get("entries")
	if entries is Dictionary:
		for species: Variant in entries:
			var entry: Variant = (entries as Dictionary)[species]
			if entry is Dictionary and not (entry as Dictionary).has("notes"):
				(entry as Dictionary)["notes"] = []


## Jalon 7 (jalon-07.md §5.1) : « money » = [constant V3_MIGRATED_MONEY] et
## « first_wild_encounter » rattrapée par [method recover_first_wild_encounter] ({} si
## introuvable). Rien d'autre ne change. Un champ déjà présent (fichier retouché à la main)
## n'est pas remplacé.
static func _upgrade_2_to_3(content: Dictionary, from_v1: bool = false) -> void:
	if not content.has("money"):
		content["money"] = V3_MIGRATED_MONEY
	if not content.has("first_wild_encounter"):
		content["first_wild_encounter"] = recover_first_wild_encounter(content, from_v1)


## Retrouve, dans une sauvegarde d'avant la v3, la **première espèce sauvage rencontrée en
## combat** (dossier 09 §19, J6 Q-7), que la v2 n'enregistrait pas. Rend { "species", "map",
## "date" } ou {} si aucune n'est sûre. Règle (faits déjà enregistrés, jalon 5 §16.3) :
##  1. **Sûr et daté** : une entrée du Pokédex dont la première observation est sur une carte
##     de [constant V3_LEGACY_BATTLE_ONLY_MAPS] (Route 1) — date = début de la rencontre. Si
##     [param from_v1] (fichier écrit par une build du J5, sans OBSERVER), toute carte de
##     [constant V3_LEGACY_WILD_MAPS] l'est aussi (Bourg Palette).
##  2. **Sûr, date majorée** : une capture sur une carte de [constant V3_LEGACY_WILD_MAPS]
##     (Pokédex `first_caught_*`, rencontre `met` d'origine « capture » de l'équipe et du
##     stockage, grand moment « first_capture ») — le combat a commencé avant cette date.
##  La candidate à la date la plus ancienne l'emporte (dates ISO de l'appareil, comparées
##  comme des chaînes ; à égalité, la règle 1 puis l'ordre alphabétique de l'espèce).
##  3. Sans candidate datée : si **une seule** espèce a, dans ses `seen_maps`, une carte de la
##     règle 1, c'est elle (date vide).
## Limites (assumées, documentées au §5.1) : une espèce vue d'abord autrement (OBSERVER à Bourg
## Palette, Pokémon du rival au labo) puis combattue sans être capturée n'a pas de date de
## combat ; si elle a été combattue avant toutes les autres, la règle en désigne une autre (ou
## aucune). Un combat dans l'herbe de Bourg Palette d'une espèce jamais capturée, écrit par une
## build du J6, est indiscernable d'une observation : il est ignoré.
static func recover_first_wild_encounter(content: Dictionary, from_v1: bool = false) -> Dictionary:
	var exact_maps: Array[String] = V3_LEGACY_WILD_MAPS if from_v1 else V3_LEGACY_BATTLE_ONLY_MAPS
	var best: Dictionary = {}
	var best_rank := 0
	var entries := JsonFields.get_dict(JsonFields.get_dict(content, "pokedex"), "entries")
	for key: Variant in entries:
		if not key is String or not entries[key] is Dictionary:
			continue
		var entry := entries[key] as Dictionary
		var seen_map := JsonFields.get_string(entry, "first_seen_map")
		if seen_map in exact_maps:
			best_rank = _keep_earliest(best, best_rank, key, seen_map,
				JsonFields.get_string(entry, "first_seen_date"), 1)
		var caught_map := JsonFields.get_string(entry, "first_caught_map")
		if JsonFields.get_bool(entry, "caught") and caught_map in V3_LEGACY_WILD_MAPS:
			best_rank = _keep_earliest(best, best_rank, key, caught_map,
				JsonFields.get_string(entry, "first_caught_date"), 2)
	for list_key: String in ["party", "storage"]:
		for member: Variant in JsonFields.get_array(content, list_key):
			if not member is Dictionary:
				continue
			var met := JsonFields.get_dict(member, "met")
			var met_map := JsonFields.get_string(met, "map")
			if JsonFields.get_string(met, "origin") == "capture" and met_map in V3_LEGACY_WILD_MAPS:
				best_rank = _keep_earliest(best, best_rank,
					JsonFields.get_string(member, "species"), met_map,
					JsonFields.get_string(met, "date"), 2)
	for moment: Variant in JsonFields.get_array(content, "moments"):
		if moment is Dictionary and JsonFields.get_string(moment, "type") == "first_capture":
			var moment_map := JsonFields.get_string(moment, "map")
			if moment_map in V3_LEGACY_WILD_MAPS:
				best_rank = _keep_earliest(best, best_rank,
					JsonFields.get_string(JsonFields.get_dict(moment, "details"), "species"),
					moment_map, JsonFields.get_string(moment, "date"), 2)
	if not best.is_empty():
		return best
	var fought: Dictionary = {}  # espèce → carte où elle a été combattue
	for key: Variant in entries:
		if key is String and entries[key] is Dictionary:
			for map: Variant in JsonFields.get_array(entries[key], "seen_maps"):
				if map is String and map in exact_maps:
					fought[key] = map
	if fought.size() == 1:
		var species: String = fought.keys()[0]
		return {"species": species, "map": fought[species], "date": ""}
	return {}


## Remplace [param best] (modifié en place) par la candidate si elle est plus ancienne ; une
## candidate sans espèce ou sans date est ignorée. Renvoie le rang de la meilleure.
static func _keep_earliest(best: Dictionary, best_rank: int, species: String, map: String,
		date: String, rank: int) -> int:
	if species.is_empty() or date.is_empty():
		return best_rank
	if not best.is_empty():
		var key := [date, rank, species]
		var held := [best["date"], best_rank, best["species"]]
		if not _before(key, held):
			return best_rank
	best["species"] = species
	best["map"] = map
	best["date"] = date
	return rank


## Ordre (date, rang, espèce) : vrai si [param a] passe avant [param b].
static func _before(a: Array, b: Array) -> bool:
	for i: int in a.size():
		if a[i] != b[i]:
			return a[i] < b[i]
	return false


func _corrupt_path() -> String:
	return path + CORRUPT_SUFFIX


func _quarantine() -> void:
	if fs.exists(_corrupt_path()):
		fs.remove(_corrupt_path())
	fs.rename(path, _corrupt_path())


func _ok() -> Error:
	last_status = OK
	last_error = ""
	return OK


func _fail(status: Error, message: String) -> Error:
	last_status = status
	last_error = "SaveSystem : " + message
	push_warning(last_error)
	return status
