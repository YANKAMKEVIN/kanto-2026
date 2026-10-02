extends Node
## Autoload « GameState » : état de la partie, qui survit aux changements de carte et que la
## sauvegarde sérialise (jalon 5 §16, 5C.5).
##
## 3A (docs/tech/jalon-03.md §2.6) : drapeaux d'histoire (« Maman a déjà parlé »).
## Jalon 4 (docs/tech/jalon-04.md §3.9) : équipe du joueur, espèce de son starter et
## aléatoire à graine de la partie. Jalon 4B (jalon-04.md §14.6) : le Sac (les 5 Poké Balls
## données par le Prof. Chen). Jalon 5 (jalon-05.md §16) : position du joueur, point de soin,
## Pokédex, et les faits que le Menu Dresseur du J6 affichera (temps de jeu, début de
## l'aventure, zones découvertes, objets trouvés, grands moments, nom du joueur).
## [method to_dict] / [method load_dict] font l'aller-retour complet ; [SaveSystem] écrit et
## lit le fichier ; Boot (tâche S2) décide des moments d'autosave et appelle les
## méthodes `record_*` au bon endroit.
## Il ne connaît aucun autre autoload. Les systèmes qui lisent l'état (dialogues, scènes,
## choix du starter) le reçoivent par injection et restent testables avec des instances
## neuves. Sans [code]class_name[/code] (le nom est pris par l'autoload) : les tests
## instancient [code]preload("res://game/autoload/game_state.gd").new()[/code].

## Types des grands moments (§16.3) : premier Pokémon (starter), combat contre le rival
## (issue dans les détails), première capture.
const MOMENT_STARTER: StringName = &"starter"
const MOMENT_RIVAL_BATTLE: StringName = &"rival_battle"
const MOMENT_FIRST_CAPTURE: StringName = &"first_capture"
const DEFAULT_PLAYER_NAME: String = "Kevin"
const DEFAULT_HEAL_MAP: StringName = &"player_house_1f"
const DEFAULT_HEAL_SPAWN: StringName = &"heal"

## Horloge de l'appareil (dates ISO des faits) ; les tests injectent une date fixe.
var clock: DeviceClock = DeviceClock.new()
## Drapeaux d'histoire (même instance pendant toute la session : elle est injectée).
var flags: StoryFlags = StoryFlags.new()
## Équipe du joueur (même instance pendant toute la session : vidée par [method new_game]).
var party: Party = Party.new()
## Espèce du starter choisi au labo (&"" avant le choix).
var starter_species: StringName = &""
## Aléatoire de la partie (remplacé par [method new_game] : nouvelle graine ; repris à
## l'identique par [method load_dict]).
var rng: GameRng = GameRng.new()
## Sac du joueur (même instance pendant toute la session : vidé par [method new_game]).
var bag: Bag = Bag.new()
## Pokédex : espèces vues et capturées (jalon 5, décision de Kevin 2026-09-29). L'écran
## arrive au jalon 6 ; les données sont collectées et sauvegardées dès le jalon 5. Même
## instance pendant toute la session (vidée par [method new_game]).
var pokedex: Pokedex = Pokedex.new()
## Pokémon capturés quand l'équipe est pleine, « système de recherche de Chen » (jalon 5D).
## Même instance pendant toute la session (vidée par [method new_game]).
var storage: PokemonStorage = PokemonStorage.new()
## Dernier point de soin (jalon 5 §3.11, 5B) : carte et spawn où le joueur se réveille, équipe
## soignée, après une défaite sauvage. Tant qu'aucun Centre Pokémon n'existe (avant Jadielle),
## c'est la maison familiale, face à Maman (dossier 07 §11). Un futur Centre le remplacera.
var heal_map: StringName = DEFAULT_HEAL_MAP
var heal_spawn: StringName = DEFAULT_HEAL_SPAWN
## Position du joueur telle que connue au dernier [method set_player_location] (la scène la
## pousse avant chaque sauvegarde ; &"" = pas encore placé).
var current_map: StringName = &""
var player_cell: Vector2i = Vector2i.ZERO
var player_facing: Vector2i = Vector2i.DOWN
## Nom du joueur (« Kevin » par défaut : pas encore d'écran de nom, dossier 08 §12).
var player_name: String = DEFAULT_PLAYER_NAME
## Temps de jeu en secondes, compté par la scène seulement au premier plan
## ([method add_play_time]).
var play_time: float = 0.0
## Date ISO du début de l'aventure (posée par [method new_game]).
var started_at: String = ""
## Zones découvertes : identifiant de carte → date ISO de la première visite.
var discovered_maps: Dictionary[StringName, String] = {}
## Objets trouvés dans le monde, dans l'ordre : { "item", "map", "date" } (clés String).
var found_items: Array[Dictionary] = []
## Grands moments, chronologiques, en ajout seul : { "type", "date", "map", "details" }.
var moments: Array[Dictionary] = []


## Nouvelle partie (appelé par Boot au démarrage) : drapeaux baissés, équipe, Sac et Pokédex
## vides, pas de starter, aléatoire neuf de graine [param rng_seed] (−1 = graine tirée au
## hasard), point de soin remis à la maison familiale, journal vide, aventure commencée
## maintenant.
func new_game(rng_seed: int = -1) -> void:
	flags.clear()
	party.clear()
	bag.clear()
	pokedex.clear()
	storage.clear()
	starter_species = &""
	rng = GameRng.new(rng_seed)
	heal_map = DEFAULT_HEAL_MAP
	heal_spawn = DEFAULT_HEAL_SPAWN
	current_map = &""
	player_cell = Vector2i.ZERO
	player_facing = Vector2i.DOWN
	player_name = DEFAULT_PLAYER_NAME
	play_time = 0.0
	started_at = now()
	discovered_maps.clear()
	found_items.clear()
	moments.clear()


# --- Faits (§16.3), appelés par la scène (tâche S2) ------------------------------------

## Date ISO courante de l'appareil.
func now() -> String:
	return clock.now_iso()


## Où est le joueur (à pousser avant chaque sauvegarde et à chaque changement de carte).
func set_player_location(map: StringName, cell: Vector2i, facing: Vector2i) -> void:
	current_map = map
	player_cell = cell
	player_facing = facing


## Secondes de jeu au premier plan ([param delta] ≤ 0 ignoré).
func add_play_time(delta: float) -> void:
	if delta > 0.0:
		play_time += delta


## Première arrivée sur [param map] : datée. Vrai si la zone vient d'être découverte.
func discover_map(map: StringName) -> bool:
	if map.is_empty() or discovered_maps.has(map):
		return false
	discovered_maps[map] = now()
	return true


## Objet [param item] ramassé dans le monde sur [param map] (ex. la Potion de la Route 1).
func record_item_found(item: StringName, map: StringName) -> void:
	if item.is_empty():
		return
	found_items.append({"item": String(item), "map": String(map), "date": now()})


## Grand moment [param type] ([constant MOMENT_STARTER]…) sur [param map], avec ses
## [param details] (clés et valeurs JSON : chaînes, nombres, booléens).
func record_moment(type: StringName, map: StringName, details: Dictionary = {}) -> void:
	if type.is_empty():
		return
	moments.append({
		"type": String(type), "date": now(), "map": String(map), "details": details.duplicate(),
	})


## Un grand moment de ce [param type] est déjà enregistré (ex. la première capture).
func has_moment(type: StringName) -> bool:
	for moment: Dictionary in moments:
		if moment.get("type", "") == String(type):
			return true
	return false


## Espèce vue sur [param map] (Pokédex daté). Vrai si c'est la première observation.
func record_seen(species: StringName, map: StringName) -> bool:
	return pokedex.mark_seen(species, map, now())


## Espèce capturée sur [param map] (Pokédex daté). Vrai si c'est la première capture.
func record_caught(species: StringName, map: StringName) -> bool:
	return pokedex.mark_caught(species, map, now())


## Rencontre de [param pokemon] à son entrée dans l'équipe : [param kind] (starter, capture),
## [param map], niveau courant, date, dresseur = le joueur.
func stamp_meeting(pokemon: Pokemon, kind: Pokemon.Origin, map: StringName) -> void:
	if pokemon != null:
		pokemon.record_meeting(kind, map, now(), player_name)


# --- Sauvegarde ----------------------------------------------------------------------

## Tout l'état, prêt pour le JSON ([SaveSystem] y pose la version). Clés et identifiants en
## chaînes, [Vector2i] en `[x, y]`, dictionnaires triés par clé pour un fichier stable.
func to_dict() -> Dictionary:
	var discovered: Dictionary = {}
	var map_ids: Array[StringName] = []
	map_ids.assign(discovered_maps.keys())
	map_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for map: StringName in map_ids:
		discovered[String(map)] = discovered_maps[map]
	return {
		"player_name": player_name,
		"started_at": started_at,
		"play_time": play_time,
		"map": String(current_map),
		"cell": JsonFields.vector2i_to_array(player_cell),
		"facing": JsonFields.vector2i_to_array(player_facing),
		"heal_map": String(heal_map),
		"heal_spawn": String(heal_spawn),
		"starter": String(starter_species),
		"party": party.to_array(),
		"storage": storage.to_array(),
		"bag": bag.to_dict(),
		"pokedex": pokedex.to_dict(),
		"flags": JsonFields.ids_to_array(flags.to_array()),
		"rng": rng.to_dict(),
		"discovered_maps": discovered,
		"found_items": found_items.duplicate(true),
		"moments": moments.duplicate(true),
	}


## Remplace tout l'état par [param dict] ([method to_dict], déjà migré par [SaveSystem]).
## Un champ absent ou mal formé prend sa valeur par défaut ; un champ inconnu est ignoré ;
## rien ne plante. Faux si une entrée a dû être écartée (Pokémon, objet, espèce invalides :
## signalés par push_error), vrai sinon. Les instances injectées (flags, party, storage, bag,
## pokedex) sont conservées ; l'aléatoire reprend où il en était (ou repart d'une graine neuve).
func load_dict(dict: Dictionary, data: PokemonData) -> bool:
	new_game()
	var ok := true
	player_name = JsonFields.get_string(dict, "player_name", DEFAULT_PLAYER_NAME)
	if player_name.is_empty():
		player_name = DEFAULT_PLAYER_NAME
	started_at = JsonFields.get_string(dict, "started_at", started_at)
	play_time = maxf(JsonFields.get_float(dict, "play_time"), 0.0)
	current_map = JsonFields.get_id(dict, "map")
	player_cell = JsonFields.get_vector2i(dict, "cell")
	player_facing = JsonFields.get_vector2i(dict, "facing", Vector2i.DOWN)
	if player_facing == Vector2i.ZERO:
		player_facing = Vector2i.DOWN
	heal_map = JsonFields.get_id(dict, "heal_map", DEFAULT_HEAL_MAP)
	heal_spawn = JsonFields.get_id(dict, "heal_spawn", DEFAULT_HEAL_SPAWN)
	if heal_map.is_empty() or heal_spawn.is_empty():
		heal_map = DEFAULT_HEAL_MAP
		heal_spawn = DEFAULT_HEAL_SPAWN
	starter_species = JsonFields.get_id(dict, "starter")
	ok = party.load_array(JsonFields.get_array(dict, "party"), data) and ok
	ok = storage.load_array(JsonFields.get_array(dict, "storage"), data) and ok
	ok = bag.load_dict(JsonFields.get_dict(dict, "bag")) and ok
	ok = pokedex.from_dict(JsonFields.get_dict(dict, "pokedex")) and ok
	flags.load_array(JsonFields.get_array(dict, "flags"))
	var rng_dict := JsonFields.get_dict(dict, "rng")
	var loaded_rng: GameRng = GameRng.from_dict(rng_dict) if not rng_dict.is_empty() else null
	if loaded_rng != null:
		rng = loaded_rng
	var discovered := JsonFields.get_dict(dict, "discovered_maps")
	for key: Variant in discovered:
		if key is String and not (key as String).is_empty() and discovered[key] is String:
			discovered_maps[StringName(key)] = discovered[key]
	for entry: Variant in JsonFields.get_array(dict, "found_items"):
		if entry is Dictionary and not JsonFields.get_string(entry, "item").is_empty():
			found_items.append({
				"item": JsonFields.get_string(entry, "item"),
				"map": JsonFields.get_string(entry, "map"),
				"date": JsonFields.get_string(entry, "date"),
			})
	for entry: Variant in JsonFields.get_array(dict, "moments"):
		if entry is Dictionary and not JsonFields.get_string(entry, "type").is_empty():
			moments.append({
				"type": JsonFields.get_string(entry, "type"),
				"date": JsonFields.get_string(entry, "date"),
				"map": JsonFields.get_string(entry, "map"),
				"details": JsonFields.get_dict(entry, "details"),
			})
	return ok
