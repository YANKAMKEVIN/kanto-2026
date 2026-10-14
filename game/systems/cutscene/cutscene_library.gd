class_name CutsceneLibrary
extends RefCounted
## Toutes les scènes scriptées du jeu, lues dans les fichiers JSON de `data/cutscenes/`.
##
## Classe pure (docs/tech/jalon-03b.md §2.3), sur le modèle exact de [DialogueLibrary].
## Chaque fichier est un objet « identifiant → scène » ; les identifiants sont uniques dans
## tout le dossier. Une scène a des variantes (première qui s'applique aux drapeaux) ; sans
## « variants », les clés d'une variante (if, unless, steps) s'écrivent dans la scène :
## [codeblock]
## "route1_grass": {
##   "variants": [
##     { "unless": ["oak_met"], "steps": [
##         { "wait": 0.4 },
##         { "dialogue": "oak_route1_call" },
##         { "face": "player", "to": "down" },
##         { "spawn": "oak", "sprite": "oak", "cell": [24, 13], "facing": "up" },
##         { "move": "oak", "run": true,
##           "to": { "near": "player", "offsets": [[1, 0], [-1, 0], [0, 1]] } },
##         { "set": ["oak_met"] },
##         { "move": "oak", "follower": "player", "path": ["down", "down"] },
##         { "change_map": "oak_lab", "at": "entrance", "facing": "up" } ] },
##     { "unless": ["starter_chosen"], "steps": [
##         { "dialogue": "route1_grass_thought" },
##         { "move": "player", "path": ["down"] } ] }
##   ]
## }
## [/codeblock]
## Chaque étape a **exactement une** clé de type ([constant CutsceneStep.TYPE_KEYS]) :
## - wait : secondes ≥ 0 ;
## - dialogue : identifiant de dialogue ;
## - face : acteur, avec « to » = direction, « player », identifiant de PNJ ou alias ;
## - set : liste non vide de drapeaux ;
## - spawn : identifiant du PNJ créé (ni « player », ni alias), avec les clés d'une entrée
##   de `data/npcs/` (sauf if et unless), validées par [method NpcRoster.parse_entry] ; sa
##   clé « dialogue » est celle du PNJ (dialogue quand on lui parle), pas un second type
##   d'étape ;
## - move : acteur, avec **soit** « path » (directions), **soit** « to » ([x, y], ou
##   { "near": acteur, "offsets": [[dx, dy], …] }), et « run », « follower » facultatifs ;
##   « keep_facing » (true : le joueur seulement, il avance sans se tourner, pour reculer) et
##   « optional » (true : avec « near », étape sautée sans erreur si aucune case ne convient)
##   facultatifs ;
## - change_map : identifiant de carte, avec « at » (point d'apparition) et « facing »
##   facultatif ;
## - hop (jalon 4) : PNJ (pas « player ») qui saute, avec « to » obligatoire, comme pour
##   move : [x, y] ou { "near": acteur, "offsets": … } ; le style du saut vient du PNJ
##   (clé « hop_style » de `data/npcs/`), pas de l'étape ;
## - lean (jalon 4) : PNJ (pas « player ») qui s'avance légèrement vers « to » (cible de
##   « face ») puis revient ;
## - despawn (jalon 4) : PNJ (pas « player ») qui quitte la carte ;
## - battle (jalon 4B) : identifiant de dresseur (data/trainers/), avec « player_pokemon » et
##   « foe_pokemon » facultatifs (PNJ ou alias, pas « player » : les Pokémon de la carte qui
##   combattent) et « win » / « lose » facultatifs (listes non vides de drapeaux levés selon
##   l'issue) ;
## - give (jalon 4B) : identifiant d'objet (data/items/), avec « count » facultatif (entier
##   ≥ 1, 1 par défaut) et « found » facultatif (booléen, faux par défaut : vrai pour un objet
##   trouvé dans le monde, comme la Potion de la Route 1, plutôt que reçu d'un personnage) ;
## - scare (jalon 7) : Pokémon d'ambiance (PNJ « shy » ou alias, pas « player ») qui réagit
##   tout de suite (envol ou fuite) et quitte la carte pour la visite ; que l'acteur soit
##   « shy » est vérifié par les tests des données réelles et, au jeu, par le directeur.
## Toute étape sauf spawn accepte « if » et « unless » (listes de drapeaux) : elle n'est jouée
## que si ses conditions sont remplies **au moment de la jouer** (suite d'un combat selon son
## issue). Les références aux dresseurs et aux objets ne sont pas vérifiées ici (tests de
## données : [method get_trainer_ids], [method get_item_ids]).
## [codeblock]
## "starter_chosen": { "unless": ["rival_challenged"], "steps": [
##     { "hop": "$player_starter", "to": { "near": "$player_starter", "offsets": [[0, 1]] } },
##     { "face": "player", "to": "$player_starter" },
##     { "lean": "$player_starter", "to": "player" },
##     { "despawn": "$rival_starter" } ] }
## [/codeblock]
## Jalon 7 (jalon-07.md §3.6, T18) :
## - caption : texte non vide de la légende posée sur le monde (« POKÉDEX ACTIVÉ ») ;
## - take : identifiant d'objet qui quitte le Sac, avec « count » facultatif (entier ≥ 1).
## Jalon 7 (jalon-07.md §3.8, T25) :
## - wake_up : true (aucun autre paramètre) ; réveil au point de repos après une défaite contre
##   un Dresseur ([DefeatRecovery]) ; la scène s'arrête après elle.
## Retours T5 (jalon-07.md §15.21) :
## - move accepte « background » (true : PNJ seulement, sans « follower ») : marche en
##   arrière-plan, la scène continue ([member CutsceneStep.background]) ;
## - react : acteur (joueur, PNJ ou alias) qui a une petite réaction de surprise.
## Jalon 9 (jalon-09.md §2.4.4) :
## - emote : PNJ (ou alias, pas « player ») avec « kind » obligatoire
##   ([constant CutsceneStep.EMOTE_KINDS] : « exclamation ») ; la scène attend la fin de la bulle.
## Jalon 10 (jalon-10.md §2.7, §2.8) :
## - champion_card : identifiant de dresseur (data/trainers/) dont le bloc « card » est présenté ;
## - badge : identifiant de badge (data/badges.json, « boulder »).
## Ni l'un ni l'autre n'est vérifié ici (tests de données : [method get_card_trainer_ids],
## [method get_badge_ids]).
## Jalon 12 (`jalon-12.md` §2.13, T23) :
## - moment : type de Grand moment ([constant MomentLibrary.TYPES] sauf « zone_arrival », déduit
##   des cartes), avec « details » facultatif : objet { clé: texte non vide } (« fossil » :
##   [code]{ "moment": "fossil", "details": { "item": "dome_fossil" } }[/code]).
## Jalon 13 (jalon-13.md §2.9) : clé de **scène** « next » (texte non vide, à côté de
## « variants » ou des clés d'une variante unique) = scène enchaînée à la fin de celle-ci
## ([member Cutscene.next]). Après [method load_dir], chaque « next » doit nommer une scène
## connue, autre que la scène elle-même ([method check_next_references]).
## Acteur = « player », identifiant d'un PNJ de la carte courante, ou **alias** « $nom »
## (forme $[a-z_]+, [method CutsceneStep.is_alias]) : PNJ choisi par le code qui lance la
## scène (CutsceneDirector.play(id, alias)), résolu au début de chaque étape. Les alias
## valent partout où un acteur ou une cible d'acteur est attendu : face (acteur et cible),
## move (acteur, near, follower), hop (acteur, near), lean (acteur et cible), despawn. La
## bibliothèque ne vérifie que leur forme ([method Cutscene.get_aliases] les énumère).
## Toute clé inconnue est une erreur (faute de frappe). Une scène invalide est écartée
## **entière**, l'erreur est signalée ([method get_errors], push_error).

const DATA_DIR: String = "res://data/cutscenes/"

const _SCENE_KEYS: Array[String] = ["variants", "next"]
const _VARIANT_KEYS: Array[String] = ["if", "unless", "steps"]
## Clés permises en plus de la clé de type, par type (ordre de CutsceneStep.Kind).
const _EXTRA_KEYS: Array[Array] = [
	[], [], ["to"], [], [],
	["path", "to", "run", "follower", "keep_facing", "optional", "background"],
	["at", "facing"], ["to"],
	["to"], [], ["player_pokemon", "foe_pokemon", "win", "lose"], ["count", "found"],
	[], ["count"], [], [], [], ["kind"], [], [], ["details"],
]
## Conditions permises sur toute étape sauf spawn.
const _CONDITION_KEYS: Array[String] = ["if", "unless"]

var _cutscenes: Dictionary[StringName, Cutscene] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une
## erreur a été signalée (les scènes valides sont gardées).
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
	return check_next_references() and ok


## Vérifie que chaque « next » nomme une scène connue, autre que la scène elle-même. Une scène
## dont la suite est invalide est écartée (erreur signalée). Faux si une erreur a été signalée.
func check_next_references() -> bool:
	var ok := true
	for id: StringName in get_ids():
		var cutscene := _cutscenes[id]
		if cutscene.next.is_empty():
			continue
		if cutscene.next == id or not _cutscenes.has(cutscene.next):
			ok = _fail("%s « %s » : « next » vaut « %s », scène inconnue ou elle-même"
				% [cutscene.source, id, cutscene.next])
			_cutscenes.erase(id)
	return ok


## Scène enchaînée à la fin de [param id] (&"" si aucune ou si [param id] est inconnue).
func get_next(id: StringName) -> StringName:
	var cutscene := get_cutscene(id)
	return cutscene.next if cutscene != null else &""


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
		return _fail("%s : un objet { identifiant: scène } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les scènes d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _cutscenes.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _cutscenes[id].source])
			continue
		var cutscene := _parse_cutscene(data[key], where)
		if cutscene == null:
			ok = false
			continue
		cutscene.id = id
		cutscene.source = source
		_cutscenes[id] = cutscene
	return ok


func has_cutscene(id: StringName) -> bool:
	return _cutscenes.has(id)


## Scène [param id], ou null si elle n'existe pas.
func get_cutscene(id: StringName) -> Cutscene:
	return _cutscenes.get(id)


## Identifiants connus, triés.
func get_ids() -> Array[StringName]:
	return _sorted_keys(_cutscenes)


func size() -> int:
	return _cutscenes.size()


## Erreurs signalées depuis la création (fichiers et scènes écartés).
func get_errors() -> PackedStringArray:
	return _errors


## Drapeaux lus par les conditions des variantes et des étapes (« if », « unless »).
func get_condition_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for cutscene: Cutscene in _cutscenes.values():
		for variant: CutsceneVariant in cutscene.variants:
			for flag: StringName in variant.if_flags + variant.unless_flags:
				found[flag] = true
			for step: CutsceneStep in variant.steps:
				for flag: StringName in step.if_flags + step.unless_flags:
					found[flag] = true
	return _sorted_keys(found)


## Drapeaux levés par au moins une étape « set », ou par l'issue d'une étape « battle »
## (« win », « lose »).
func get_set_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		var raised: Array[StringName] = []
		if step.kind == CutsceneStep.Kind.SET_FLAGS:
			raised = step.flags
		elif step.kind == CutsceneStep.Kind.BATTLE:
			raised = step.win_flags + step.lose_flags
		for flag: StringName in raised:
			found[flag] = true
	return _sorted_keys(found)


## Dresseurs combattus par au moins une étape « battle » (tests de données).
func get_trainer_ids() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		if step.kind == CutsceneStep.Kind.BATTLE:
			found[step.trainer_id] = true
	return _sorted_keys(found)


## Dresseurs présentés par au moins une étape « champion_card » (tests de données : chacun a
## un bloc « card »).
func get_card_trainer_ids() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		if step.kind == CutsceneStep.Kind.CHAMPION_CARD:
			found[step.trainer_id] = true
	return _sorted_keys(found)


## Badges remis par au moins une étape « badge » (tests de données).
func get_badge_ids() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		if step.kind == CutsceneStep.Kind.BADGE:
			found[step.badge_id] = true
	return _sorted_keys(found)


## Objets donnés (« give ») ou repris (« take ») par au moins une étape (tests de données).
func get_item_ids() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		if step.kind == CutsceneStep.Kind.GIVE or step.kind == CutsceneStep.Kind.TAKE:
			found[step.item_id] = true
	return _sorted_keys(found)


## Alias utilisés par la scène [param id] (sans « $ »), triés ; vide si elle n'existe pas.
func get_aliases(id: StringName) -> Array[StringName]:
	var cutscene := get_cutscene(id)
	if cutscene == null:
		return []
	return cutscene.get_aliases()


## Dialogues joués par au moins une étape « dialogue » (tests de données).
func get_dialogue_ids() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		if step.kind == CutsceneStep.Kind.DIALOGUE:
			found[step.dialogue_id] = true
	return _sorted_keys(found)


func _all_steps() -> Array[CutsceneStep]:
	var steps: Array[CutsceneStep] = []
	for cutscene: Cutscene in _cutscenes.values():
		for variant: CutsceneVariant in cutscene.variants:
			steps.append_array(variant.steps)
	return steps


func _parse_cutscene(value: Variant, where: String) -> Cutscene:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var cutscene := Cutscene.new()
	var ok := _check_keys(entry, _SCENE_KEYS + _VARIANT_KEYS, where)
	if entry.has("next"):
		var next_value: Variant = entry["next"]
		if not next_value is String or (next_value as String).strip_edges().is_empty():
			ok = _fail("%s : « next » doit être un identifiant de scène non vide" % where)
		else:
			cutscene.next = StringName((next_value as String).strip_edges())
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
			cutscene.variants.append(variant)
	return cutscene if ok else null


func _parse_variant(value: Variant, where: String) -> CutsceneVariant:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var variant := CutsceneVariant.new()
	var ok := _check_keys(entry, _VARIANT_KEYS, where)
	ok = _read_flags(entry, "if", variant.if_flags, where) and ok
	ok = _read_flags(entry, "unless", variant.unless_flags, where) and ok
	if not entry.get("steps") is Array or (entry.get("steps") as Array).is_empty():
		return _null_fail("%s : « steps » doit être une liste non vide" % where)
	var steps: Array = entry["steps"]
	for i: int in steps.size():
		var step := _parse_step(steps[i], "%s étape %d" % [where, i + 1])
		if step == null:
			ok = false
		else:
			variant.steps.append(step)
	return variant if ok else null


func _parse_step(value: Variant, where: String) -> CutsceneStep:
	if not value is Dictionary:
		return _null_fail("%s : un objet { type: … } est attendu" % where)
	var entry: Dictionary = value
	var kinds: Array[int] = []
	for i: int in CutsceneStep.TYPE_KEYS.size():
		# Dans une étape « spawn », « dialogue » est la clé du PNJ créé, pas un type.
		if i == CutsceneStep.Kind.DIALOGUE and entry.has("spawn"):
			continue
		if entry.has(CutsceneStep.TYPE_KEYS[i]):
			kinds.append(i)
	if kinds.size() != 1:
		return _null_fail("%s : une étape a exactement un type parmi %s" % [where,
			", ".join(CutsceneStep.TYPE_KEYS)])
	var step := CutsceneStep.new()
	step.kind = kinds[0] as CutsceneStep.Kind
	var type_key: String = CutsceneStep.TYPE_KEYS[step.kind]
	where += " (%s)" % type_key
	var ok := true
	if step.kind != CutsceneStep.Kind.SPAWN:
		var allowed: Array[String] = [type_key]
		allowed.append_array(_EXTRA_KEYS[step.kind])
		allowed.append_array(_CONDITION_KEYS)
		ok = _check_keys(entry, allowed, where)
		ok = _read_flags(entry, "if", step.if_flags, where) and ok
		ok = _read_flags(entry, "unless", step.unless_flags, where) and ok
	var main: Variant = entry[type_key]
	match step.kind:
		CutsceneStep.Kind.WAIT:
			if not (main is float or main is int) or float(main) < 0.0:
				ok = _fail("%s : « wait » doit être un nombre de secondes ≥ 0" % where)
			else:
				step.seconds = float(main)
		CutsceneStep.Kind.DIALOGUE:
			ok = _read_id(main, where + " dialogue", func(v: StringName) -> void:
				step.dialogue_id = v) and ok
		CutsceneStep.Kind.FACE:
			ok = _read_actor(main, where + " face", func(v: StringName) -> void:
				step.actor = v) and ok
			ok = _read_actor(entry.get("to"), where + " to", func(v: StringName) -> void:
				step.target = v) and ok
		CutsceneStep.Kind.SET_FLAGS:
			if not main is Array or (main as Array).is_empty():
				ok = _fail("%s : « set » doit être une liste non vide de drapeaux" % where)
			else:
				ok = _read_flags(entry, "set", step.flags, where) and ok
		CutsceneStep.Kind.SPAWN:
			ok = _parse_spawn(entry, step, where) and ok
		CutsceneStep.Kind.MOVE:
			ok = _parse_move(entry, step, where) and ok
		CutsceneStep.Kind.CHANGE_MAP:
			ok = _read_id(main, where + " change_map", func(v: StringName) -> void:
				step.map_id = v) and ok
			ok = _read_id(entry.get("at"), where + " at", func(v: StringName) -> void:
				step.spawn = v) and ok
			if entry.has("facing"):
				ok = _read_direction(entry["facing"], where + " facing",
					func(v: Vector2i) -> void: step.facing = v) and ok
		CutsceneStep.Kind.HOP:
			ok = _read_npc_actor(main, where + " hop", step) and ok
			if not entry.has("to"):
				ok = _fail("%s : « to » est obligatoire ([x, y] ou { near, offsets })" % where)
			else:
				ok = _parse_destination(entry["to"], step, where) and ok
		CutsceneStep.Kind.LEAN:
			ok = _read_npc_actor(main, where + " lean", step) and ok
			ok = _read_actor(entry.get("to"), where + " to", func(v: StringName) -> void:
				step.target = v) and ok
		CutsceneStep.Kind.DESPAWN:
			ok = _read_npc_actor(main, where + " despawn", step) and ok
		CutsceneStep.Kind.SCARE:
			ok = _read_npc_actor(main, where + " scare", step) and ok
		CutsceneStep.Kind.BATTLE:
			ok = _parse_battle(entry, step, where) and ok
		CutsceneStep.Kind.GIVE:
			ok = _read_id(main, where + " give", func(v: StringName) -> void:
				step.item_id = v) and ok
			if entry.has("count"):
				var amount: Variant = entry["count"]
				if not (amount is float or amount is int) \
						or float(amount) != floorf(float(amount)) or int(amount) < 1:
					ok = _fail("%s : « count » doit être un entier ≥ 1" % where)
				else:
					step.count = int(amount)
			if entry.has("found"):
				if entry["found"] is bool:
					step.found = entry["found"]
				else:
					ok = _fail("%s : « found » doit être un booléen" % where)
		CutsceneStep.Kind.CAPTION:
			if not main is String or (main as String).strip_edges().is_empty():
				ok = _fail("%s : « caption » doit être un texte non vide" % where)
			else:
				step.text = main
		CutsceneStep.Kind.TAKE:
			ok = _read_id(main, where + " take", func(v: StringName) -> void:
				step.item_id = v) and ok
			ok = _read_count(entry, step, where) and ok
		CutsceneStep.Kind.WAKE_UP:
			if not main is bool or not main:
				ok = _fail("%s : « wake_up » vaut true" % where)
		CutsceneStep.Kind.REACT:
			ok = _read_actor(main, where + " react", func(v: StringName) -> void:
				step.actor = v) and ok
		CutsceneStep.Kind.EMOTE:
			ok = _read_npc_actor(main, where + " emote", step) and ok
			var emote: Variant = entry.get("kind")
			if not emote is String or not CutsceneStep.EMOTE_KINDS.has(StringName(emote)):
				ok = _fail("%s : « kind » vaut %s" % [where, ", ".join(PackedStringArray(
					CutsceneStep.EMOTE_KINDS))])
			else:
				step.emote = StringName(emote)
		CutsceneStep.Kind.CHAMPION_CARD:
			ok = _read_id(main, where + " champion_card", func(v: StringName) -> void:
				step.trainer_id = v) and ok
		CutsceneStep.Kind.BADGE:
			ok = _read_id(main, where + " badge", func(v: StringName) -> void:
				step.badge_id = v) and ok
		CutsceneStep.Kind.MOMENT:
			ok = _parse_moment(entry, step, where) and ok
	return step if ok else null


## « count » facultatif d'une étape give ou take : entier ≥ 1 (1 par défaut).
func _read_count(entry: Dictionary, step: CutsceneStep, where: String) -> bool:
	if not entry.has("count"):
		return true
	var amount: Variant = entry["count"]
	if not (amount is float or amount is int) \
			or float(amount) != floorf(float(amount)) or int(amount) < 1:
		return _fail("%s : « count » doit être un entier ≥ 1" % where)
	step.count = int(amount)
	return true


## battle : dresseur, Pokémon de la carte qui combattent (facultatifs), drapeaux de l'issue.
func _parse_battle(entry: Dictionary, step: CutsceneStep, where: String) -> bool:
	var ok := _read_id(entry["battle"], where + " battle", func(v: StringName) -> void:
		step.trainer_id = v)
	if entry.has("player_pokemon"):
		ok = _read_actor(entry["player_pokemon"], where + " player_pokemon",
			func(v: StringName) -> void: step.player_pokemon = v) and ok
	if entry.has("foe_pokemon"):
		ok = _read_actor(entry["foe_pokemon"], where + " foe_pokemon",
			func(v: StringName) -> void: step.foe_pokemon = v) and ok
	for ref: StringName in [step.player_pokemon, step.foe_pokemon]:
		if ref == NpcRoster.PLAYER_ID:
			ok = _fail("%s : les Pokémon du combat sont des PNJ (pas « player »)" % where)
	if not step.player_pokemon.is_empty() and step.player_pokemon == step.foe_pokemon:
		ok = _fail("%s : « player_pokemon » et « foe_pokemon » sont le même PNJ" % where)
	for key: String in ["win", "lose"]:
		if not entry.has(key):
			continue
		if not entry[key] is Array or (entry[key] as Array).is_empty():
			ok = _fail("%s : « %s » doit être une liste non vide de drapeaux" % [where, key])
		else:
			ok = _read_flags(entry, key, step.win_flags if key == "win" else step.lose_flags,
				where) and ok
	return ok


## spawn : identifiant, puis les clés d'une entrée de data/npcs/ (sans condition).
func _parse_spawn(entry: Dictionary, step: CutsceneStep, where: String) -> bool:
	var ok := _read_id(entry["spawn"], where + " spawn", func(v: StringName) -> void:
		step.actor = v)
	if step.actor == NpcRoster.PLAYER_ID:
		ok = _fail("%s : identifiant réservé au joueur" % where)
	if String(step.actor).begins_with(CutsceneStep.ALIAS_PREFIX):
		ok = _fail("%s : un PNJ créé a un vrai identifiant, pas un alias" % where)
	var npc_entry := entry.duplicate()
	npc_entry.erase("spawn")
	for key: String in ["if", "unless"]:
		if npc_entry.has(key):
			ok = _fail("%s : « %s » n'a pas de sens dans une étape (conditions : variante)"
				% [where, key])
			npc_entry.erase(key)
	var errors := PackedStringArray()
	step.spec = NpcRoster.parse_entry(npc_entry, errors)
	for message: String in errors:
		ok = _fail("%s : %s" % [where, message])
	if step.spec != null:
		step.spec.id = step.actor
	return ok


## move : acteur, path ou to (exactement un des deux), run, follower, keep_facing, optional.
func _parse_move(entry: Dictionary, step: CutsceneStep, where: String) -> bool:
	var ok := _read_actor(entry["move"], where + " move", func(v: StringName) -> void:
		step.actor = v)
	if entry.has("path") == entry.has("to"):
		ok = _fail("%s : « path » ou « to », exactement l'un des deux" % where)
	if entry.has("path"):
		var path: Variant = entry["path"]
		if not path is Array or (path as Array).is_empty():
			ok = _fail("%s : « path » doit être une liste non vide de directions" % where)
		else:
			for name: Variant in path:
				if not name is String or not Grid.is_direction_name(name):
					ok = _fail("%s : direction inconnue « %s » dans « path »" % [where, name])
					break
				step.path.append(Grid.direction_from_name(name))
	if entry.has("to"):
		ok = _parse_destination(entry["to"], step, where) and ok
	if entry.has("run"):
		if not entry["run"] is bool:
			ok = _fail("%s : « run » vaut true ou false" % where)
		else:
			step.run = entry["run"]
	if entry.has("follower"):
		ok = _read_actor(entry["follower"], where + " follower", func(v: StringName) -> void:
			step.follower = v) and ok
		if step.follower == step.actor:
			ok = _fail("%s : « follower » ne peut pas être l'acteur lui-même" % where)
	if entry.has("keep_facing"):
		if not entry["keep_facing"] is bool:
			ok = _fail("%s : « keep_facing » vaut true ou false" % where)
		else:
			step.keep_facing = entry["keep_facing"]
		if step.keep_facing and step.actor != NpcRoster.PLAYER_ID:
			ok = _fail("%s : « keep_facing » ne vaut que pour « player »" % where)
	if entry.has("optional"):
		if not entry["optional"] is bool:
			ok = _fail("%s : « optional » vaut true ou false" % where)
		else:
			step.optional = entry["optional"]
		if step.optional and step.near.is_empty():
			ok = _fail("%s : « optional » exige une destination « near »" % where)
	if entry.has("background"):
		if not entry["background"] is bool:
			ok = _fail("%s : « background » vaut true ou false" % where)
		else:
			step.background = entry["background"]
		if step.background and step.actor == NpcRoster.PLAYER_ID:
			ok = _fail("%s : « background » ne vaut que pour un PNJ" % where)
		if step.background and not step.follower.is_empty():
			ok = _fail("%s : « background » sans « follower »" % where)
	return ok


## to : [x, y], ou { "near": acteur, "offsets": [[dx, dy], …] }.
func _parse_destination(value: Variant, step: CutsceneStep, where: String) -> bool:
	if value is Array:
		if not NpcRoster.is_cell(value):
			return _fail("%s : « to » doit être [x, y] (entiers ≥ 0)" % where)
		step.cell = Vector2i(int(value[0]), int(value[1]))
		return true
	if not value is Dictionary:
		return _fail("%s : « to » doit être [x, y] ou { near, offsets }" % where)
	var near: Dictionary = value
	var ok := _check_keys(near, ["near", "offsets"], where + " to")
	ok = _read_actor(near.get("near"), where + " to near", func(v: StringName) -> void:
		step.near = v) and ok
	var offsets: Variant = near.get("offsets")
	if not offsets is Array or (offsets as Array).is_empty():
		return _fail("%s : « offsets » doit être une liste non vide de [dx, dy]" % where)
	for offset: Variant in offsets:
		if not _is_offset(offset):
			return _fail("%s : décalage invalide %s (entiers, pas [0, 0])" % [where, offset])
		step.offsets.append(Vector2i(int(offset[0]), int(offset[1])))
	return ok


static func _is_offset(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return false
	for n: Variant in value:
		if not (n is float or n is int) or float(n) != floorf(float(n)):
			return false
	return int(value[0]) != 0 or int(value[1]) != 0


func _read_id(value: Variant, where: String, assign: Callable) -> bool:
	if not value is String or (value as String).is_empty():
		return _fail("%s : identifiant attendu" % where)
	assign.call(StringName(value))
	return true


## Acteur ou cible d'acteur : identifiant non vide ; commençant par « $ », un alias bien
## formé ($[a-z_]+).
func _read_actor(value: Variant, where: String, assign: Callable) -> bool:
	if not _read_id(value, where, assign):
		return false
	var ref := StringName(value)
	if String(ref).begins_with(CutsceneStep.ALIAS_PREFIX) and not CutsceneStep.is_alias(ref):
		return _fail("%s : alias mal formé « %s » ($ puis a-z ou _)" % [where, ref])
	return true


## Acteur d'une étape hop, lean ou despawn : un PNJ ou un alias, jamais le joueur.
func _read_npc_actor(value: Variant, where: String, step: CutsceneStep) -> bool:
	if not _read_actor(value, where, func(v: StringName) -> void: step.actor = v):
		return false
	if step.actor == NpcRoster.PLAYER_ID:
		return _fail("%s : réservé aux PNJ (pas « player »)" % where)
	return true


func _read_direction(value: Variant, where: String, assign: Callable) -> bool:
	if not value is String or not Grid.is_direction_name(value):
		return _fail("%s : direction inconnue « %s » (up, down, left, right)" % [where, value])
	assign.call(Grid.direction_from_name(value))
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


func _fail(message: String) -> bool:
	var full := "CutsceneLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> Variant:
	_fail(message)
	return null


static func _sorted_keys(found: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(found.keys())
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


## moment (jalon 12, T23) : type connu de [MomentLibrary] (pas l'arrivée dans une zone, déduite
## des cartes découvertes), « details » facultatif { clé: texte non vide }.
func _parse_moment(entry: Dictionary, step: CutsceneStep, where: String) -> bool:
	var ok := true
	var type: Variant = entry["moment"]
	if not type is String or not MomentLibrary.TYPES.has(StringName(type)) \
			or StringName(type) == MomentLibrary.ZONE_ARRIVAL:
		ok = _fail("%s : « moment » vaut un type de MomentLibrary (sauf « %s »)" % [where,
			MomentLibrary.ZONE_ARRIVAL])
	else:
		step.moment_type = StringName(type)
	if not entry.has("details"):
		return ok
	var details: Variant = entry["details"]
	if not details is Dictionary:
		return _fail("%s : « details » doit être un objet { clé: texte }" % where)
	for key: Variant in details:
		var value: Variant = (details as Dictionary)[key]
		if not value is String or (value as String).strip_edges().is_empty():
			ok = _fail("%s : « details » « %s » doit être un texte non vide" % [where, key])
		else:
			step.moment_details[str(key)] = value
	return ok
