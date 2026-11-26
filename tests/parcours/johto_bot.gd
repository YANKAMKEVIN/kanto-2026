extends "res://tests/parcours/parcours_play.gd"
## Bot de parcours de Johto (2026-11-26, demande de Kevin : « personne n'a encore joué Johto d'un
## bout à l'autre ») : sur la **vraie scène Boot** ([ParcoursPlay]), il joue le chapitre seul, de la
## lettre d'Orme ([constant START]) au retour à Bourg Palette ([constant GOAL]), sans raccourci de
## drapeaux ni saut de carte : marche case par case, passages, Surf, Vol, dialogues, combats.
##
## À chaque tour, il choisit l'action qui fait avancer l'histoire, puis la joue :
## 1. **Index du monde**, lu une fois : passages, déclencheurs, points d'examen et points d'arrivée
##    de toutes les cartes (texte des `.tscn`, sans les charger), PNJ des fichiers `data/npcs/`.
## 2. **Événements candidats** : déclencheur de scène, PNJ présent (drapeaux, heure de Johto),
##    point d'examen actif. Pour chacun, les drapeaux qu'il peut lever **maintenant** : variante de
##    scène ou de dialogue choisie avec les drapeaux et le Sac, puis tout ce qu'elle enchaîne
##    (« set », victoire d'un combat, capture, don, scène suivante, réponse OUI d'un choix).
## 3. **Priorité** : d'abord l'événement qui lève le drapeau de sortie de l'objectif affiché
##    (`data/story/objectives.json`), puis celui qui lève un drapeau **lu ailleurs** (condition
##    d'une autre scène, d'un PNJ, d'un passage, d'un décor, du code), ou donne une CS ou un objet
##    clé. Les drapeaux qui ne servent qu'à l'événement lui-même (objet ramassé, salutation) sont
##    ignorés. À priorité égale, la carte la plus proche en nombre de passages.
## 4. **Exécution réelle** : chemin de cartes par les passages actifs (Vol vers une ville
##    découverte si aucun chemin à pied), marche, puis le pas sur le déclencheur ou la parole.
##    Un événement qui ne change aucun drapeau est noté en échec pour l'état courant, avec la raison
##    (case inaccessible, PNJ absent, scène sans effet), et n'est plus retenté avant un progrès.
## 5. **Blocage** : plus aucun candidat atteignable, ou trop d'échecs de suite. Le rapport donne
##    l'objectif affiché, la carte et la case du joueur, les drapeaux de sortie attendus, les
##    événements qui les lèveraient et pourquoi ils n'ont pas abouti.
##
## L'équipe est montée au niveau 100 et soignée avant chaque action, un Repousse permanent évite
## les rencontres sauvages : le bot vérifie les **enchaînements**, pas l'équilibrage. Les
## dialogues avancent, les choix répondent OUI, les combats attaquent avec la première capacité.

const START := "res://tools/debug_start/johto_letter.json"
const GOAL: StringName = &"johto_chapter_done"
const MAPS_DIR := "res://game/world/maps/"
const OBJECTIVES_PATH := "res://data/story/objectives.json"
## Échecs de suite (aucun drapeau gagné) avant de déclarer un blocage.
const MAX_FAILS_IN_ROW := 12
## Passages tentés avant d'abandonner un trajet entre deux cartes.
const MAX_ROUTE_TRIES := 6
## Poussées de rochers de Force au plus pour rejoindre une case (Îles Tourbillon).
const MAX_PUSHES := 12
## Parents des nœuds lus dans les `.tscn`.
const INDEXED_PARENTS: Array[String] = ["Warps", "Triggers", "Interactables", "Spawns"]
## Objets clés et CS qui comptent comme un progrès quand un événement les donne.
const KEY_ITEM_PREFIXES: Array[String] = ["hm"]

## Carte → { warps, triggers, interacts, spawns } (index du monde).
var world: Dictionary[StringName, Dictionary] = {}
## Drapeau → propriétaires qui le lisent (« c:scène », « d:dialogue », « n:carte:pnj »,
## « m:carte:nœud », « o » objectifs, « code »).
var readers: Dictionary[StringName, Dictionary] = {}
## Texte de tout le code du jeu (drapeaux lus en dur).
var _code_text: String = ""
var _objectives: Array = []
var _rosters: Dictionary[StringName, NpcRoster] = {}
var _cutscenes: CutsceneLibrary
var _dialogues: DialogueLibrary
var _items: ItemLibrary
var _fly_rules: FlyRules
var _elevators: ElevatorLibrary
## Échecs : clé d'événement + signature des drapeaux → raison.
var _failed: Dictionary[String, String] = {}
## Passages qui ont échoué pour l'état courant : « carte>carte » → vrai.
var _failed_edges: Dictionary[String, bool] = {}
## Journal des actions jouées (lignes lisibles).
var actions: Array[String] = []
## Diagnostic du blocage (vide si le but est atteint).
var stall: Array[String] = []
## Culs-de-sac traversés (aucun passage vers la suite) : le bot en sort à la Corde Sortie, comme un
## joueur qui en a une, mais un joueur sans Corde ni Tunnel y reste bloqué. Le test les signale.
var dead_ends: Array[String] = []
var _ever_held: Dictionary[StringName, bool] = {}
var _signature: String = ""
## Trajets joués par une scène (Goulven sur le Goéland : parler = traversée) : carte →
## [{ target, event }], recalculés à chaque tour.
var _event_edges: Dictionary[StringName, Array] = {}


func _init(test: GutTest, name: String = "johto_bot") -> void:
	super(test, name)


# --- Index du monde ---------------------------------------------------------------------------

## Lit les cartes, les PNJ, les scènes, les dialogues, les objectifs et le code (une fois).
func build_index() -> void:
	_cutscenes = boot.get_cutscene_library()
	_dialogues = boot.get_dialogue_library()
	_items = boot.get_item_library()
	_fly_rules = FlyRules.new()
	_fly_rules.load_file()
	var dir := DirAccess.open(MAPS_DIR)
	for file: String in dir.get_files():
		if file.ends_with(".tscn") and not MapCatalog.is_qa_map(StringName(file.get_basename())):
			_index_map(StringName(file.get_basename()))
	_elevators = ElevatorLibrary.new()
	_elevators.load_file()
	for id: StringName in _elevators.get_ids():
		var elevator := _elevators.get_elevator(id)
		if not world.has(elevator.car):
			continue
		for floor: Dictionary in elevator.floors:
			# Cabine → étage : passage virtuel joué au panneau ([method _ride_to]).
			(world[elevator.car]["warps"] as Array).append({"cell": Vector2i(-1, -1),
				"target": StringName(floor["map"]), "spawn": StringName(floor["spawn"]),
				"trigger": 0, "direction": Vector2i.ZERO, "soon": false, "if": [] as Array[StringName],
				"unless": [] as Array[StringName], "elevator": StringName(floor["id"])})
	for map_id: StringName in world:
		var roster := NpcRoster.load_for_map(map_id)
		if roster == null or roster.size() == 0:
			continue
		_rosters[map_id] = roster
		for spec: NpcSpec in roster.get_all():
			var owner := "n:%s:%s" % [map_id, spec.id]
			_read(spec.if_flags, owner)
			_read(spec.unless_flags, owner)
			_read(spec.moved_if_flags, owner)
			_read(spec.moved_unless_flags, owner)
	for id: StringName in _cutscenes.get_ids():
		var owner := "c:%s" % id
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			_read(variant.if_flags, owner)
			_read(variant.unless_flags, owner)
			for step: CutsceneStep in variant.steps:
				_read(step.if_flags, owner)
				_read(step.unless_flags, owner)
	for id: StringName in _dialogues.get_ids():
		var owner := "d:%s" % id
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			_read(variant.if_flags, owner)
			_read(variant.unless_flags, owner)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES_PATH))
	_objectives = parsed if parsed is Array else []
	for objective: Variant in _objectives:
		var entry: Dictionary = objective
		_read(_names(entry.get("if", [])), "o")
		_read(_names(entry.get("unless", [])), "o")
	var texts: PackedStringArray = []
	_collect_code(&"res://game", texts)
	_code_text = "\n".join(texts)


func _collect_code(path: String, into: PackedStringArray) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file: String in dir.get_files():
		if file.ends_with(".gd"):
			into.append(FileAccess.get_file_as_string(path.path_join(file)))
	for sub: String in dir.get_directories():
		_collect_code(path.path_join(sub), into)


func _read(flags: Array, owner: String) -> void:
	for flag: Variant in flags:
		var name := StringName(str(flag))
		if not readers.has(name):
			readers[name] = {}
		readers[name][owner] = true


static func _names(values: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if values is Array:
		for value: Variant in values:
			out.append(StringName(str(value)))
	return out


## Lit les nœuds utiles d'une scène de carte dans son texte (sans charger les textures).
func _index_map(map_id: StringName) -> void:
	var info := {"warps": [], "triggers": [], "interacts": [], "spawns": {}}
	var text := FileAccess.get_file_as_string(MapCatalog.scene_path(map_id))
	var node := {}
	for line: String in text.split("\n"):
		if line.begins_with("["):
			_store_node(map_id, info, node)
			node = {}
			if line.begins_with("[node "):
				node["name"] = _attr(line, "name")
				node["parent"] = _attr(line, "parent")
			continue
		if node.is_empty():
			continue
		if not INDEXED_PARENTS.has(node.get("parent", "")) and not line.contains("_flags = "):
			continue
		var eq := line.find(" = ")
		if eq > 0:
			node[line.substr(0, eq)] = line.substr(eq + 3)
	_store_node(map_id, info, node)
	world[map_id] = info


static func _attr(line: String, key: String) -> String:
	var start := line.find(key + "=\"")
	if start < 0:
		return ""
	start += key.length() + 2
	return line.substr(start, line.find("\"", start) - start)


func _store_node(map_id: StringName, info: Dictionary, node: Dictionary) -> void:
	if node.is_empty():
		return
	var owner := "m:%s:%s" % [map_id, node.get("name", "")]
	for key: String in ["if_flags", "unless_flags", "unless_all_flags"]:
		if node.has(key):
			_read(_string_names(node[key]), owner)
	var parent: String = node.get("parent", "")
	if not INDEXED_PARENTS.has(parent) or not node.has("position"):
		return
	var cell := Grid.world_to_cell(_vector2(node["position"]))
	match parent:
		"Spawns":
			(info["spawns"] as Dictionary)[StringName(node["name"])] = cell
		"Warps":
			if not node.has("target_map"):
				return
			(info["warps"] as Array).append({
				"cell": cell, "target": _string_name(node["target_map"]),
				"spawn": _string_name(node.get("target_spawn", "&\"\"")),
				"trigger": int(node.get("trigger", "0")),
				"direction": _vector2i(node.get("direction", "Vector2i(0, 0)")),
				"soon": node.has("coming_soon"),
				"if": _string_names(node.get("if_flags", "")),
				"unless": _string_names(node.get("unless_flags", "")),
			})
		"Triggers":
			if not node.has("cutscene_id"):
				return
			(info["triggers"] as Array).append({
				"name": node["name"], "cutscene": _string_name(node["cutscene_id"]),
				"cells": _cells(cell, _vector2i(node.get("size", "Vector2i(1, 1)"))),
				"direction": _vector2i(node.get("direction", "Vector2i(0, 0)")),
			})
		"Interactables":
			if not node.has("dialogue_id") or node.has("puzzle"):
				return
			(info["interacts"] as Array).append({
				"name": node["name"], "owner": owner,
				"dialogue": _string_name(node["dialogue_id"]),
				"cells": _cells(cell, _vector2i(node.get("size", "Vector2i(1, 1)"))),
				"facing": _vector2i(node.get("facing", "Vector2i(0, 0)")),
				"kind": int(node.get("kind", "0")),
				"if": _string_names(node.get("if_flags", "")),
				"unless": _string_names(node.get("unless_flags", "")),
				"unless_all": _string_names(node.get("unless_all_flags", "")),
			})


## Cases couvertes depuis l'ancre (bas-gauche), comme [method EventTriggerPoint.get_cells].
static func _cells(anchor: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			cells.append(anchor + Vector2i(x, -y))
	return cells


static func _numbers(value: String) -> PackedFloat64Array:
	var inner := value.substr(value.find("(") + 1)
	inner = inner.substr(0, inner.find(")"))
	var out := PackedFloat64Array()
	for part: String in inner.split(","):
		out.append(float(part.strip_edges()))
	return out


static func _vector2(value: String) -> Vector2:
	var n := _numbers(value)
	return Vector2(n[0], n[1]) if n.size() >= 2 else Vector2.ZERO


static func _vector2i(value: String) -> Vector2i:
	var n := _numbers(value)
	return Vector2i(int(n[0]), int(n[1])) if n.size() >= 2 else Vector2i.ZERO


static func _string_name(value: String) -> StringName:
	var start := value.find("\"")
	if start < 0:
		return &""
	return StringName(value.substr(start + 1, value.find("\"", start + 1) - start - 1))


static func _string_names(value: String) -> Array[StringName]:
	var out: Array[StringName] = []
	var regex := RegEx.create_from_string("&\"([^\"]*)\"")
	for found: RegExMatch in regex.search_all(value):
		out.append(StringName(found.get_string(1)))
	return out


# --- Boucle -----------------------------------------------------------------------------------

## Joue le chapitre jusqu'à [param goal]. [param max_actions] borne le nombre d'actions.
## Vrai si le but est atteint.
func run(goal: StringName = GOAL, max_actions: int = 600) -> bool:
	if world.is_empty():
		build_index()
	var fails_in_row := 0
	_remember_flags()
	for turn: int in max_actions:
		if GameState.flags.has_flag(goal):
			return true
		_prepare_team()
		_refresh_signature()
		var candidates := _candidates()
		if candidates.is_empty():
			_diagnose("aucun événement atteignable ne fait avancer l'histoire")
			return false
		var event: Dictionary = candidates[0]
		var before := GameState.flags.to_array()
		var reason: String = await _attempt(event)
		await wait_stable()
		var gained := _gained(before)
		var label := "%s (%s)" % [_describe(event), map_id()]
		if gained.is_empty():
			fails_in_row += 1
			_failed[_key(event)] = reason if not reason.is_empty() else "joué sans effet"
			_log("  ✘ %s : %s" % [label, _failed[_key(event)]])
			if fails_in_row >= MAX_FAILS_IN_ROW:
				_diagnose("%d actions de suite sans progrès" % fails_in_row)
				return false
			continue
		fails_in_row = 0
		_failed_edges.clear()
		_log("  ✔ %s → %s" % [label, ", ".join(gained)])
	_diagnose("limite de %d actions atteinte" % max_actions)
	return GameState.flags.has_flag(goal)


## Drapeaux nouveaux depuis [param before]. Un drapeau déjà tenu une fois (posé, effacé, reposé :
## l'aller du bateau) ne compte pas : sinon le bot ferait la navette sans fin.
func _gained(before: Array[StringName]) -> Array[String]:
	var gained: Array[String] = []
	for flag: StringName in GameState.flags.to_array():
		if not before.has(flag) and not _ever_held.has(flag):
			gained.append(String(flag))
	_remember_flags()
	return gained


func _remember_flags() -> void:
	for flag: StringName in GameState.flags.to_array():
		_ever_held[flag] = true


## Équipe au niveau 100, soignée ; Repousse permanent.
func _prepare_team() -> void:
	var data := boot.get_pokemon_data()
	for pokemon: Pokemon in GameState.party.get_all():
		if pokemon.egg_steps > 0:
			continue
		# Niveau 100, potentiels et efforts au maximum : le bot cherche les blocages, pas les combats
		# serrés (Germignon seul, niveau 100 sans efforts, tombait sous un Laser Glace critique).
		pokemon.level = maxi(pokemon.level, 100)
		for stat: StringName in pokemon.stats:
			pokemon.ivs[stat] = 31
			pokemon.evs[stat] = 252
		pokemon.recalc(data)
		pokemon.heal_full()
		# La boucle de combat joue toujours la capacité 0 : la plus forte d'abord (Germignon seul
		# perdait contre Cenere en ouvrant par Rugissement).
		pokemon.moves.sort_custom(func(a: MoveSlot, b: MoveSlot) -> bool:
			return _move_score(data, a) > _move_score(data, b))
	GameState.repel_steps = 9999


func _move_score(data: PokemonData, slot: MoveSlot) -> int:
	var move := data.get_move(slot.move_id)
	if move == null or move.power <= 1:
		return 0
	return move.power * (move.accuracy if move.accuracy > 0 else 100)


func _refresh_signature() -> void:
	var flags := GameState.flags.to_array()
	flags.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	_signature = str(hash(str(flags) + str(GameState.bag.get_ids())))


func _key(event: Dictionary) -> String:
	return "%s|%s" % [event["key"], _signature]


# --- Candidats --------------------------------------------------------------------------------

## Événements prometteurs, triés (priorité, distance en passages).
func _candidates() -> Array[Dictionary]:
	var exits := _objective_exits()
	var events := _all_events()
	_event_edges.clear()
	for event: Dictionary in events:
		event["effects"] = _effects(event)
		for target: StringName in _travel_targets(event):
			if target != event["map"] and world.has(target) and event["kind"] != "trigger":
				if not _event_edges.has(event["map"]):
					_event_edges[event["map"]] = []
				(_event_edges[event["map"]] as Array).append({"target": target, "event": event})
	var distances := _map_distances(map_id())
	var found: Array[Dictionary] = []
	for event: Dictionary in events:
		if _failed.has(_key(event)):
			continue
		var effects: Dictionary = event["effects"]
		var useful: Array[StringName] = []
		var priority := 9
		for flag: StringName in effects["flags"]:
			if exits.has(flag):
				priority = 0
				useful.append(flag)
			elif _is_read_elsewhere(flag, effects["owners"]):
				priority = mini(priority, 1)
				useful.append(flag)
		for item: StringName in effects["items"]:
			priority = mini(priority, 2)
			useful.append(StringName("objet " + String(item)))
		if useful.is_empty():
			continue
		if not boot.is_johto_map(event["map"]) and not _mentions_johto(useful):
			continue  # Kanto : seulement ce qui touche au chapitre.
		event["useful"] = useful
		event["priority"] = priority
		event["distance"] = distances.get(event["map"], 1000)
		found.append(event)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["priority"] != b["priority"]:
			return a["priority"] < b["priority"]
		if a["distance"] != b["distance"]:
			return a["distance"] < b["distance"]
		return str(a["key"]) < str(b["key"]))
	return found


static func _mentions_johto(flags: Array[StringName]) -> bool:
	for flag: StringName in flags:
		if String(flag).contains("johto"):
			return true
	return false


## Drapeaux de sortie (« unless ») de l'objectif affiché (le premier qui s'applique, comme le
## menu).
func _objective_exits() -> Array[StringName]:
	var objective := current_objective()
	return _names(objective.get("unless", []))


## L'objectif affiché dans le menu (premier dont les conditions s'appliquent), ou {}.
func current_objective() -> Dictionary:
	for value: Variant in _objectives:
		var entry: Dictionary = value
		if GameState.flags.has_all(_names(entry.get("if", []))) \
				and GameState.flags.has_none(_names(entry.get("unless", []))):
			return entry
	return {}


func _is_read_elsewhere(flag: StringName, own: Dictionary) -> bool:
	for owner: String in readers.get(flag, {}):
		if not own.has(owner):
			return true
	return _code_text.contains("\"%s\"" % flag)


## Tous les événements actifs du monde avec les drapeaux courants.
func _all_events() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for map: StringName in world:
		var info: Dictionary = world[map]
		for trigger: Dictionary in info["triggers"]:
			events.append({"kind": "trigger", "map": map, "key": "t:%s:%s" % [map,
				trigger["name"]], "cutscene": trigger["cutscene"], "cells": trigger["cells"],
				"direction": trigger["direction"]})
		for point: Dictionary in info["interacts"]:
			if not _interact_active(point):
				continue
			events.append({"kind": "interact", "map": map, "key": "i:%s:%s" % [map,
				point["name"]], "dialogue": point["dialogue"], "cells": point["cells"],
				"facing": point["facing"], "owner": point["owner"]})
		var roster: NpcRoster = _rosters.get(map)
		if roster == null:
			continue
		var time := _time_for(map)
		for spec: NpcSpec in roster.get_present(GameState.flags, time[0], time[1]):
			events.append({"kind": "npc", "map": map, "key": "n:%s:%s" % [map, spec.id],
				"npc": spec.id, "spec": spec})
	return events


func _interact_active(point: Dictionary) -> bool:
	var flags := GameState.flags
	if not flags.has_none(point["unless"]) or not flags.has_all(point["if"]):
		return false
	var all: Array[StringName] = point["unless_all"]
	return all.is_empty() or not flags.has_all(all)


func _time_for(map: StringName) -> Array[StringName]:
	var clock := boot.get_world_clock()
	if not boot.is_johto_map(map) or clock == null or not clock.is_active():
		return [&"", &""]
	return [clock.period_name(), clock.weekday_name()]


## Ce que l'événement peut lever maintenant : { flags, items, owners } (owners : ce qui le
## compose, pour ne pas compter ses propres conditions).
func _effects(event: Dictionary) -> Dictionary:
	var out := {"flags": [] as Array[StringName], "items": [] as Array[StringName],
		"owners": {}, "seen": {}, "maps": [] as Array[StringName]}
	match event["kind"]:
		"trigger":
			_cutscene_effects(event["cutscene"], out)
		"interact":
			out["owners"][event["owner"]] = true
			_dialogue_effects(event["dialogue"], out)
		"npc":
			var spec: NpcSpec = event["spec"]
			out["owners"]["n:%s:%s" % [event["map"], spec.id]] = true
			var offer := _open_offer(event["map"], spec.id)
			if offer != null:
				_add_flag(offer.done_flag, out)
				_cutscene_effects(offer.chosen_scene, out)
			elif spec.is_trainer() and not TrainerRules.is_beaten(GameState.flags, spec.trainer_id):
				_add_flag(TrainerRules.beaten_flag(spec.trainer_id), out)
				for line: StringName in [spec.before_dialogue, spec.defeated_dialogue]:
					if not line.is_empty():
						_dialogue_effects(line, out)
			elif not spec.dialogue.is_empty():
				_dialogue_effects(spec.dialogue, out)
	return out


## Offre de starter ouverte dont [param npc] est un des choix sur [param map] (Rencontrer,
## puis CHOISIR), ou null.
func _open_offer(map: StringName, npc: StringName) -> StarterOffer:
	for offer: StarterOffer in [boot.get_starter_offer(), boot.get_johto_starter_offer()]:
		if offer == null or offer.map_id != map or not offer.get_npc_ids().has(npc):
			continue
		if GameState.flags.has_flag(offer.open_flag) \
				and not GameState.flags.has_flag(offer.done_flag):
			return offer
	return null


## Cartes où une scène de [param event] peut emmener le joueur, **toutes variantes confondues**
## (le retour du Goéland dépend d'un drapeau que l'embarquement efface) : sur-approximation,
## le vrai trajet tranche.
func _travel_targets(event: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var seen := {}
	match event["kind"]:
		"interact":
			_maps_of_dialogue(event["dialogue"], seen, out)
		"npc":
			_maps_of_dialogue((event["spec"] as NpcSpec).dialogue, seen, out)
	return out


func _maps_of_dialogue(id: StringName, seen: Dictionary, out: Array[StringName]) -> void:
	var dialogue := _dialogues.get_dialogue(id) if not id.is_empty() else null
	if dialogue == null or seen.has("d:" + id):
		return
	seen["d:" + id] = true
	for variant: DialogueVariant in dialogue.variants:
		_maps_of_cutscene(variant.cutscene, seen, out)
		if variant.choice != null:
			_maps_of_cutscene(variant.choice.confirm_cutscene, seen, out)


func _maps_of_cutscene(id: StringName, seen: Dictionary, out: Array[StringName]) -> void:
	var cutscene := _cutscenes.get_cutscene(id) if not id.is_empty() else null
	if cutscene == null or seen.has("c:" + id):
		return
	seen["c:" + id] = true
	for variant: CutsceneVariant in cutscene.variants:
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.CHANGE_MAP and not out.has(step.map_id):
				out.append(step.map_id)
			elif step.kind == CutsceneStep.Kind.DIALOGUE:
				_maps_of_dialogue(step.dialogue_id, seen, out)
	_maps_of_cutscene(cutscene.next, seen, out)


func _add_flag(flag: StringName, out: Dictionary) -> void:
	if flag.is_empty() or GameState.flags.has_flag(flag):
		return
	var flags: Array[StringName] = out["flags"]
	if not flags.has(flag):
		flags.append(flag)


func _dialogue_effects(id: StringName, out: Dictionary) -> void:
	var seen: Dictionary = out["seen"]
	if seen.has("d:" + id):
		return
	seen["d:" + id] = true
	out["owners"]["d:%s" % id] = true
	var dialogue := _dialogues.get_dialogue(id)
	if dialogue == null:
		return
	var variant := _pick_dialogue(dialogue)
	if variant == null:
		return
	for flag: StringName in variant.set_flags:
		_add_flag(flag, out)
	if not variant.cutscene.is_empty():
		_cutscene_effects(variant.cutscene, out)
	if variant.choice != null:
		for flag: StringName in variant.choice.confirm_set:
			_add_flag(flag, out)
		if not variant.choice.confirm_cutscene.is_empty():
			_cutscene_effects(variant.choice.confirm_cutscene, out)


## Première variante de dialogue qui s'applique (drapeaux, Sac, heure ; les variantes au hasard
## et les conditions de Pokédex ou de lien sont ignorées).
func _pick_dialogue(dialogue: Dialogue) -> DialogueVariant:
	for variant: DialogueVariant in dialogue.variants:
		if not GameState.flags.has_all(variant.if_flags) \
				or not GameState.flags.has_none(variant.unless_flags):
			continue
		var items_ok := true
		for item: StringName in variant.if_items:
			items_ok = items_ok and GameState.bag.has(item)
		for item: StringName in variant.unless_items:
			items_ok = items_ok and not GameState.bag.has(item)
		if not items_ok or variant.is_random():
			continue
		return variant
	return null


func _cutscene_effects(id: StringName, out: Dictionary) -> void:
	var seen: Dictionary = out["seen"]
	if id.is_empty() or seen.has("c:" + id):
		return
	seen["c:" + id] = true
	out["owners"]["c:%s" % id] = true
	var cutscene := _cutscenes.get_cutscene(id)
	if cutscene == null:
		return
	var variant := cutscene.pick(GameState.flags, GameState.bag)
	if variant == null:
		return
	for step: CutsceneStep in variant.steps:
		match step.kind:
			CutsceneStep.Kind.SET_FLAGS:
				for flag: StringName in step.flags:
					_add_flag(flag, out)
			CutsceneStep.Kind.GIVE:
				for flag: StringName in step.flags:
					_add_flag(flag, out)
				if _is_key_item(step.item_id) and not GameState.bag.has(step.item_id):
					(out["items"] as Array[StringName]).append(step.item_id)
			CutsceneStep.Kind.BATTLE:
				for flag: StringName in step.win_flags:
					_add_flag(flag, out)
				_add_flag(TrainerRules.beaten_flag(step.trainer_id), out)
			CutsceneStep.Kind.WILD_BATTLE:
				for flag: StringName in step.win_flags + step.catch_flags:
					_add_flag(flag, out)
				if step.static_encounter != null:
					_add_flag(step.static_encounter.done_flag, out)
			CutsceneStep.Kind.GIFT_POKEMON:
				_add_flag(step.gift_flag, out)
			CutsceneStep.Kind.DIALOGUE:
				_dialogue_effects(step.dialogue_id, out)
			CutsceneStep.Kind.CHANGE_MAP:
				if step.if_flags.is_empty() and step.unless_flags.is_empty():
					(out["maps"] as Array[StringName]).append(step.map_id)
	_cutscene_effects(cutscene.next, out)


func _is_key_item(item: StringName) -> bool:
	for prefix: String in KEY_ITEM_PREFIXES:
		if String(item).begins_with(prefix):
			return true
	var data := _items.get_item(item) if _items != null else null
	return data != null and data.category == ItemData.Category.KEY


# --- Cartes et trajets ------------------------------------------------------------------------

func _warp_usable(warp: Dictionary) -> bool:
	if warp["soon"] or not world.has(warp["target"]):
		return false
	return GameState.flags.has_all(warp["if"]) and GameState.flags.has_none(warp["unless"])


## Cartes voisines de [param map] : passages actifs et trajets joués par une scène.
func _neighbors(map: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for warp: Dictionary in (world.get(map, {}) as Dictionary).get("warps", []):
		var target: StringName = warp["target"]
		if _warp_usable(warp) and not _failed_edges.has("%s>%s" % [map, target]):
			out.append(target)
	for edge: Dictionary in _event_edges.get(map, []):
		if not _failed_edges.has("%s>%s" % [map, edge["target"]]):
			out.append(edge["target"])
	return out


## Distance en passages depuis [param from] vers chaque carte (passages actifs).
func _map_distances(from: StringName) -> Dictionary:
	var distance := {from: 0}
	var queue: Array[StringName] = [from]
	var head := 0
	while head < queue.size():
		var map: StringName = queue[head]
		head += 1
		for target: StringName in _neighbors(map):
			if distance.has(target):
				continue
			distance[target] = distance[map] + 1
			queue.append(target)
	return distance


## Chemin de cartes de [param from] à [param to] (sans [param from]) ; vide si aucun.
func _map_path(from: StringName, to: StringName) -> Array[StringName]:
	var previous := {from: from}
	var queue: Array[StringName] = [from]
	var head := 0
	while head < queue.size():
		var map: StringName = queue[head]
		head += 1
		if map == to:
			break
		for target: StringName in _neighbors(map):
			if previous.has(target):
				continue
			previous[target] = map
			queue.append(target)
	var path: Array[StringName] = []
	if not previous.has(to) or from == to:
		return path
	var at := to
	while at != from:
		path.push_front(at)
		at = previous[at]
	return path


## Rejoint [param target] : passages à pied (Surf si besoin), sinon Vol vers la ville découverte
## la plus proche de la cible. Rend "" ou la raison de l'échec.
func go_to_map(target: StringName) -> String:
	var used_fly := false
	for attempt: int in MAX_ROUTE_TRIES * 3:
		if map_id() == target:
			return ""
		var path := _map_path(map_id(), target)
		if path.is_empty():
			if await _escape_dead_end(target):
				continue
			if used_fly or not await _fly_towards(target):
				return "aucun chemin de %s vers %s" % [map_id(), target]
			used_fly = true
			continue
		var from := map_id()
		var next: StringName = path[0]
		if not await _hop(next):
			if map_id() == from:
				_failed_edges["%s>%s" % [from, next]] = true
				_log("    · passage %s → %s impossible (case %s)" % [from, next,
					player.get_cell()])
	return "trajet vers %s abandonné (sur %s)" % [target, map_id()]


## Dans une grotte d'où aucun passage ne mène plus à [param target] (ni à pied, ni à l'aide d'un
## autre passage) : Corde Sortie, donnée si le Sac n'en a pas, et cul-de-sac noté dans
## [member dead_ends]. Vrai si le joueur a quitté la carte.
func _escape_dead_end(target: StringName) -> bool:
	var from := map_id()
	var cell := player.get_cell()
	var exit := FieldItemRules.escape_target(from, boot.get_caves(), cell)
	if exit == null or (exit.map != target and not _map_distances(exit.map).has(target)):
		return false
	var note := "%s (case %s) : aucun passage vers %s, sortie à la Corde Sortie" % [from, cell,
		target]
	if not dead_ends.has(note):
		dead_ends.append(note)
	_log("    · CUL-DE-SAC " + note)
	if not GameState.bag.has(&"escape_rope"):
		GameState.bag.add(&"escape_rope", 1)
	boot.get_menu_director().field_item_requested.emit(&"escape_rope")
	await _settle()
	return map_id() != from


## Passe sur la carte voisine [param next] par un de ses passages (le plus proche à pied
## d'abord ; Surf si l'eau y mène).
func _hop(next: StringName) -> bool:
	await _ride_to(next)
	var options: Array[Dictionary] = []
	for warp: Warp in boot.get_map().get_warps().get_all():
		if warp.target_map != next or warp.is_coming_soon() or not _warp_active(warp):
			continue
		if warp.trigger == Warp.Trigger.PUSH:
			options.append({"stand": warp.cell, "press": warp.direction})
		elif warp.direction != Vector2i.ZERO:
			options.append({"stand": warp.cell - warp.direction, "press": warp.direction})
		else:
			for side: Vector2i in DIRECTIONS:
				options.append({"stand": warp.cell + side, "press": -side})
	for option: Dictionary in options:
		option["length"] = _foot_length(option["stand"])
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["length"] < b["length"])
	if options.is_empty():
		for edge: Dictionary in _event_edges.get(map_id(), []):
			if edge["target"] == next:
				_log("    · trajet joué : %s" % _describe(edge["event"]))
				await _act(edge["event"])
				return map_id() == next
	var tried := 0
	for option: Dictionary in options:
		if map_id() == next:
			return true
		if tried >= 3:
			break
		tried += 1
		if not await reach(option["stand"]):
			continue
		await step(option["press"])
		await _settle()
	return map_id() == next


## Dans une cabine d'ascenseur : panneau, étage de [param floor_map] (la sortie de la cabine y
## mène ensuite). Sans effet ailleurs ou si la cabine y est déjà.
func _ride_to(floor_map: StringName) -> void:
	if _elevators == null or not _elevators.is_car(map_id()):
		return
	var elevator := _elevators.for_car(map_id())
	var floor := elevator.floor_for_map(floor_map)
	var director := boot.get_elevator_director()
	if floor.is_empty() or director.get_current_floor() == StringName(floor["id"]):
		return
	if not director.open_panel():
		return
	await _test.wait_process_frames(2)
	director.choose_floor(StringName(floor["id"]))
	await _test.wait_until(func() -> bool: return not director.is_riding(), STABLE_TIMEOUT)
	await wait_stable()
	_log("    · ascenseur → %s" % floor["label"])


func _fly_towards(target: StringName) -> bool:
	var fly := boot.get_fly_director()
	var best: FlyRules.Point = null
	var best_length := -1
	for point: FlyRules.Point in _fly_rules.get_points():
		if not fly.can_fly_to(point.zone):
			continue
		var length := 0 if point.map == target else _map_path(point.map, target).size()
		if point.map != target and length == 0:
			continue
		if best_length < 0 or length < best_length:
			best = point
			best_length = length
	if best == null:
		return false
	_log("    · Vol vers %s" % best.zone)
	await fly.fly(best.zone)
	await _settle()
	return true


## Joue la scène en cours s'il y en a une, puis attend la partie au repos.
func _settle() -> void:
	await _test.wait_process_frames(3)
	if not boot.is_stable():
		await run_scene()
	await wait_stable()


## Chemin à pied de la vraie grille vers [param goal], sans passer sur un passage ni, si
## possible, sur un déclencheur de scène (dalles des Ruines d'Alpha : un faux pas efface la
## suite) ; sauf [param goal]. Vide si aucun.
func _foot_path(goal: Vector2i) -> Array[Vector2i]:
	var spin := _spin_field()
	if spin != null:
		return _spin_path(goal, spin)
	var map := boot.get_map()
	var avoided: Array[Vector2i] = []
	for warp: Warp in map.get_warps().get_all():
		avoided.append(warp.cell)
	var path := _path_avoiding(goal, avoided + _trigger_cells())
	return path if not path.is_empty() else _path_avoiding(goal, avoided)


func _trigger_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for trigger: Dictionary in (world.get(map_id(), {}) as Dictionary).get("triggers", []):
		cells.append_array(trigger["cells"])
	return cells


func _path_avoiding(goal: Vector2i, avoided: Array[Vector2i]) -> Array[Vector2i]:
	var grid := boot.get_map().get_grid()
	var blocker := RefCounted.new()
	var held: Array[Vector2i] = []
	for cell: Vector2i in avoided:
		if cell != goal and cell != player.get_cell() and grid.occupy(cell, blocker):
			held.append(cell)
	var path := grid.find_path(player.get_cell(), goal, player)
	for cell: Vector2i in held:
		grid.release(cell, blocker)
	return path


## Dalles tournantes de la carte (repaire d'Acajou B2F), ou null.
func _spin_field() -> SpinTileField:
	var node := boot.get_map().get_node_or_null(^"SpinTiles")
	return node as SpinTileField


## Chemin sur une carte à dalles tournantes : un pas qui pose le joueur sur une flèche le mène au
## bout de sa glisse ([method SpinTileField.slide_from]). Rend la suite des directions ;
## [method reach] n'en joue que la première, puis recalcule.
func _spin_path(goal: Vector2i, spin: SpinTileField) -> Array[Vector2i]:
	var grid := boot.get_map().get_grid()
	var walkable := func(cell: Vector2i) -> bool:
		return grid.is_in_bounds(cell) and not grid.is_solid(cell)
	var warps: Dictionary[Vector2i, bool] = {}
	for warp: Warp in boot.get_map().get_warps().get_all():
		warps[warp.cell] = true
	var start := player.get_cell()
	var previous: Dictionary[Vector2i, Vector2i] = {start: start}
	var step_of: Dictionary[Vector2i, Vector2i] = {}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in DIRECTIONS:
			var target := grid.get_step_target(cell, direction, player)
			if target == cell or (warps.has(target) and target != goal):
				continue
			if spin.is_arrow(target):
				target = spin.slide_from(target, walkable).end
			if previous.has(target):
				continue
			previous[target] = cell
			step_of[target] = direction
			if target == goal:
				var path: Array[Vector2i] = []
				var back := goal
				while back != start:
					path.push_front(step_of[back])
					back = previous[back]
				return path
			queue.append(target)
	return []


## Va sur [param goal] (marche ; Surf depuis une berge si l'eau y mène). Les scènes qui prennent
## la main en chemin (Dresseurs) sont jouées. Vrai si le joueur y est, sur la même carte.
func reach(goal: Vector2i) -> bool:
	var origin := map_id()
	var spinning := _spin_field() != null
	var surfed := false
	var pushes := 0
	var last_push: Dictionary[Boulder, Vector2i] = {}
	for attempt: int in (80 if spinning else 6) + MAX_PUSHES:
		if map_id() != origin:
			return false
		if player.get_cell() == goal:
			return true
		var path := _foot_path(goal)
		if path.is_empty():
			if not surfed:
				surfed = true
				if await _try_surf(goal):
					continue
			if pushes < MAX_PUSHES and await _push_a_boulder(last_push):
				pushes += 1
				continue
			return false
		if spinning:
			path = [path[0]]
		var cell := player.get_cell()
		for direction: Vector2i in path:
			cell += direction
			await step(direction)
			if player.get_cell() != cell:
				break
		await _settle()
	return map_id() == origin and player.get_cell() == goal


## Force : pousse un rocher qu'on peut aborder à pied, vers une case libre, jamais en arrière de
## sa dernière poussée ([param last_push]). Le chemin est recalculé après chaque poussée. Vrai si
## un rocher a bougé.
func _push_a_boulder(last_push: Dictionary[Boulder, Vector2i]) -> bool:
	var strength := boot.get_strength_director()
	if strength == null or boot.field_state(&"strength").state != FieldMoves.State.READY:
		return false
	var grid := boot.get_map().get_grid()
	var options: Array[Dictionary] = []
	for boulder: Boulder in strength.get_boulders():
		var cell := boulder.get_cell()
		for direction: Vector2i in DIRECTIONS:
			if last_push.get(boulder, Vector2i.ZERO) == -direction:
				continue
			var stand := cell - direction
			if not grid.can_enter(cell + direction, direction):
				continue
			var length := _foot_length(stand)
			if length < 100000:
				options.append({"boulder": boulder, "stand": stand, "direction": direction,
					"length": length + (0 if last_push.has(boulder) else 1000)})
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["length"] < b["length"])
	for option: Dictionary in options:
		if not await reach(option["stand"]):
			continue
		_log("    · Force : rocher %s poussé vers %s" % [(option["boulder"] as Boulder).get_cell(),
			option["direction"]])
		if await push_boulder(option["stand"], option["direction"]):
			last_push[option["boulder"]] = option["direction"]
			return true
	return false


func _try_surf(goal: Vector2i) -> bool:
	if boot.field_state(&"surf").state != FieldMoves.State.READY:
		return false
	var grid := boot.get_map().get_grid()
	var on_foot := grid.find_reachable(player.get_cell(), player, GridWorld.MoveMode.WALK)
	var surf_state := boot.get_mount_director().get_surf_state()
	# La rive d'où l'on rejoint [param goal] à pied (le lac de la Route 42 se traverse) : les cases
	# d'eau voisines de ces cases-là suffisent.
	var beyond: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in grid.find_reachable(goal, null, GridWorld.MoveMode.WALK):
		for side: Vector2i in DIRECTIONS:
			beyond[cell + side] = true
	for cell: Vector2i in on_foot:
		for side: Vector2i in DIRECTIONS:
			var sea := cell + side
			if not grid.is_surfable(sea) or grid.is_occupied(sea):
				continue
			if SurfRules.can_mount(grid, cell, side, surf_state, false, player) \
					!= SurfRules.MountCheck.READY:
				continue
			var water := grid.find_reachable(sea, null, GridWorld.MoveMode.SURF)
			if not water.has(goal) and not water.keys().any(func(c: Vector2i) -> bool:
					return beyond.has(c)):
				continue
			if not await reach(cell):
				return false
			player.face(side)
			await _test.wait_process_frames(2)
			boot.get_mount_director().start_surf()
			await _settle()
			return player.get_mount() == Mount.Kind.SURF
	return false


# --- Écrans pilotés pendant une scène ---

var _pumping: bool = false


## Comme [method HideoutPlay.run_scene], avec les écrans propres à Johto pilotés en même temps :
## fiche du starter (CHOISIR), choix des 6 au retour de l'équipe (VALIDER).
func run_scene(answer: bool = true) -> bool:
	var outer := not _pumping
	if outer:
		_pumping = true
		_pump_screens()
	var battle: bool = await super(answer)
	if outer:
		_pumping = false
	return battle


func _pump_screens() -> void:
	while _pumping and is_instance_valid(boot):
		_press_screens()
		await _test.get_tree().process_frame


## Un appui sur l'écran ouvert, s'il y en a un. Vrai si un écran a été validé.
func _press_screens() -> bool:
	# Combat : la première capacité est refusée (plus de PP, entrave) → la suivante permise.
	var battles := boot.get_battle_director()
	var battle := battles.get_battle() if battles.is_running() else null
	# Le bot cherche les blocages, pas l'équilibrage : son Pokémon est soigné à chaque choix (un
	# Germignon seul, niveau 100, tombait encore contre l'équipe de Cenere après un critique).
	if battle != null and battle.get_state() == Battle.State.CHOOSING:
		var active := battle.get_player_side().active
		if active != null and active.pokemon != null and active.pokemon.hp > 0:
			active.pokemon.hp = active.pokemon.max_hp()
	if battle != null and battle.get_state() == Battle.State.CHOOSING \
			and boot.get_battle_hud().get_zone() == BattleHud.Zone.MOVES \
			and not battle.is_legal(BattleAction.move(0)):
		for index: int in range(1, 4):
			if battle.is_legal(BattleAction.move(index)):
				boot.get_battle_hud().move_selected.emit(index)
				return true
	var sheet := boot.get_starter_sheet()
	if sheet != null and sheet.is_open() and sheet.get_choose_button().visible:
		sheet.choose_pressed.emit()
		return true
	var overlay := boot.get_team_return_overlay()
	if overlay != null and overlay.is_open() and not overlay.get_confirm_button().disabled:
		overlay.get_confirm_button().pressed.emit()
		return true
	return false


# --- Exécution --------------------------------------------------------------------------------

## Joue [param event] : trajet, puis le pas ou la parole. Rend "" ou la raison d'un échec.
func _attempt(event: Dictionary) -> String:
	var travel_error: String = await go_to_map(event["map"])
	if not travel_error.is_empty():
		return travel_error
	return await _act(event)


## Joue [param event] sur la carte courante (sa carte).
func _act(event: Dictionary) -> String:
	match event["kind"]:
		"trigger":
			return await _step_on(event["cells"], event["direction"])
		"interact":
			return await _examine(event["cells"], event["facing"])
		"npc":
			var npc := boot.get_map().get_npc(event["npc"])
			if npc == null:
				return "PNJ absent de la carte chargée"
			return await _talk(npc.get_cell())
	return "type inconnu"


func _step_on(cells: Array, direction: Vector2i) -> String:
	var grid := boot.get_map().get_grid()
	for cell: Vector2i in cells:
		var sides: Array[Vector2i] = []
		if direction != Vector2i.ZERO:
			sides.append(-direction)
		else:
			sides.assign(DIRECTIONS.keys())
		# D'abord les cases d'approche qui ne sont pas elles-mêmes des déclencheurs.
		var triggers := _trigger_cells()
		sides.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return int(triggers.has(cell + a)) < int(triggers.has(cell + b)))
		for side: Vector2i in sides:
			var stand: Vector2i = cell + side
			if grid.is_occupied(stand) and stand != player.get_cell():
				continue
			# Déjà sur le déclencheur : reach en sort, puis le pas y revient.
			if not await reach(stand):
				continue
			await step(-side)
			await _settle()
			return ""
	return "aucune case d'approche du déclencheur %s" % [cells[0]]


func _examine(cells: Array, facing: Vector2i) -> String:
	for cell: Vector2i in cells:
		var sides: Array[Vector2i] = []
		if facing != Vector2i.ZERO:
			sides.append(-facing)
		else:
			sides.assign(DIRECTIONS.keys())
		for side: Vector2i in sides:
			if await reach(cell + side):
				await interact(-side)
				await _settle()
				return ""
	return "point d'examen %s inaccessible" % [cells[0]]


## Parle au PNJ en [param target] : case voisine, sinon par-dessus un comptoir (deux cases).
func _talk(target: Vector2i) -> String:
	for distance: int in [1, 2]:
		var options: Array[Vector2i] = []
		for side: Vector2i in DIRECTIONS:
			options.append(side)
		options.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return _foot_length(target + a * distance) < _foot_length(target + b * distance))
		for side: Vector2i in options:
			var stand := target + side * distance
			if _foot_length(stand) >= 100000:
				continue
			if await reach(stand):
				await interact(-side)
				await _test.wait_process_frames(3)
				if _press_screens():
					await _settle()
				await _settle()
				return ""
	# Sur l'eau (le Léviator rouge du Lac Colère) : on l'aborde en Surf ([method reach]).
	var grid := boot.get_map().get_grid()
	for side: Vector2i in DIRECTIONS:
		var stand := target + side
		if grid.is_surfable(stand) and await reach(stand):
			await interact(-side)
			await _test.wait_process_frames(3)
			if _press_screens():
				await _settle()
			await _settle()
			return ""
	return "PNJ en %s inaccessible" % [target]


func _foot_length(cell: Vector2i) -> int:
	if cell == player.get_cell():
		return 0
	var path := _foot_path(cell)
	return path.size() if not path.is_empty() else 100000


# --- Rapport ---

## Ligne du journal, aussi imprimée tout de suite (suivi d'une longue partie).
func _log(line: String) -> void:
	actions.append(line)
	print("[bot] ", line)


func _describe(event: Dictionary) -> String:
	match event["kind"]:
		"trigger":
			return "déclencheur « %s » [%s]" % [event["cutscene"], event["key"]]
		"interact":
			return "examen « %s » [%s]" % [event["dialogue"], event["key"]]
		"npc":
			return "PNJ « %s » sur %s" % [event["npc"], event["map"]]
	return str(event["key"])


func _diagnose(why: String) -> void:
	var objective := current_objective()
	stall.append("Blocage : %s." % why)
	stall.append("Objectif affiché : « %s » (%s)" % [objective.get("text", "aucun"),
		objective.get("id", "-")])
	stall.append("Position : %s, case %s" % [map_id(), player.get_cell()])
	var exits := _objective_exits()
	stall.append("Drapeaux de sortie attendus : %s" % ", ".join(exits))
	var setters := 0
	for event: Dictionary in _all_events():
		var effects := _effects(event)
		var hits: Array[String] = []
		for flag: StringName in effects["flags"]:
			if exits.has(flag):
				hits.append(String(flag))
		if hits.is_empty():
			continue
		setters += 1
		stall.append("  - %s lèverait %s : %s" % [_describe(event), ", ".join(hits),
			_failed.get(_key(event), "pas tenté")])
	if setters == 0:
		stall.append("  Aucun événement présent ne lève ces drapeaux avec l'état actuel.")


## Journal complet (actions puis blocage), une ligne par entrée.
func journal() -> Array[String]:
	var lines: Array[String] = []
	lines.append_array(actions)
	for note: String in dead_ends:
		lines.append("CUL-DE-SAC : " + note)
	lines.append_array(stall)
	return lines
