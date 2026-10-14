extends SceneTree
## Équilibrage de la Route 3 et du Mont Sélénite (jalon 12 T10, lancé au T26 ; dossier 15 §3.2,
## §3.3, §6, §8.3, §9). Information pour Kevin, pas un seuil ; aucune donnée n'est changée
## (résultats et ajustements du T26 : `docs/tech/jalon-12.md` §9).
##
## Modèle : `tools/simulate_brock.gd` (J10). Tout passe par le vrai moteur ([Battle], règles
## sauvage / Dresseur, XP, niveaux et capacités gagnés en combat, évolutions de fin de combat),
## la vraie IA ([BattleAI]), les vraies espèces, capacités et objets (`data/`) et [GameRng] :
## une graine = une partie (IV, sexes, rencontres, tirages du combat).
##
## [b]Scénario[/b] (JSON, défaut [constant DEFAULT_SCENARIO]) : les équipes de départ, les
## tables de rencontres (format de `data/encounters/`, terrains « grass » et « rubble »), les
## Dresseurs (format de `data/trainers/`), les étapes du parcours, dans l'ordre, et les
## variantes (joueur, Centre, objets, fuite, détours). Les espèces et capacités du J12 ne sont
## pas encore dans les données (T12) : tout élément qui en nomme une absente (équipe, table,
## Dresseur, objet d'une variante) est [b]sauté[/b] avec un message, et le code de sortie vaut
## [constant EXIT_SKIPPED]. Une étape sautée est retirée du parcours (les suivantes sont jouées).
##
## [b]Une partie[/b] : équipe de départ (soignée si « heal_at_start ») ; puis chaque étape :
## - « wild » : « cells » pas sur le terrain, tirés comme en jeu ([method EncounterTable.roll] :
##   taux, montée, compteur de pas calmes commun à toutes les étapes de la partie), puis
##   « count » rencontres forcées ([method EncounterTable.pick]) ; combats menés par le premier
##   Pokémon debout de l'équipe ;
## - « trainer » : le joueur attentif met en tête son meilleur Pokémon contre le premier
##   adversaire (ordre rétabli après) ;
## - « center » : soin complet, seulement si la variante a « center » ;
## - « optional » : étape jouée seulement si la variante la demande (détours, évitables) ;
##   true = groupe « détour », ou un texte = nom du groupe (jalon 13 : « route_24_nord »…).
##   Variante : « optional » true (tous les groupes) ou liste de groupes.
## « title » (facultatif) : titre du rapport. Équipe : « starter » (facultatif ; sinon celui du
## scénario ou de la sauvegarde) choisit l'équipe des Dresseurs à « team_by_starter » (rival).
## Une défaite (équipe entière K.O.) arrête la partie, sauf si la variante a « retries » (T26) :
## réveil au dernier Centre passé (soin complet ; Sac, niveaux et Dresseurs battus gardés) et
## reprise à l'étape qui le suit, au plus « retries » fois ; le rapport donne alors l'arrivée
## après 0, 1… défaites (les statistiques d'étape ne comptent que la première tentative) et,
## par Dresseur perdu au moins une fois, les tentatives moyennes jusqu'à la victoire (T20).
## Dresseurs à « switch » (J13) : l'IA peut changer de Pokémon une fois par combat, comme en jeu.
## En combat sauvage, un joueur ligoté (piège) ne tente pas de fuir. Aucune capture ; aucun
## changement volontaire de Pokémon, sauf pour le joueur « expert ».
##
## [b]Joueurs[/b] : « naif » (une capacité offensive au hasard, remplaçant = le suivant, aucun
## objet) ; « attentif » (capacités de l'IA `smart`, remplaçant le mieux placé, Potion en
## combat quand le prochain coup peut le mettre K.O. et qu'elle le sauverait ; après chaque
## combat, Antidote sur un Pokémon empoisonné et Potions jusqu'à plus de
## [constant HEAL_OUTSIDE_BELOW] des PV, tant qu'il en reste) ; « expert » (T20 : comme
## « attentif », mais toujours la capacité aux plus forts dégâts attendus, jamais de statut, et,
## contre un Dresseur, un changement volontaire par Pokémon adverse quand un autre membre est
## nettement mieux placé : [method _expert_switch]). « flee_below » : en combat
## sauvage, tentative de fuite quand le Pokémon en jeu passe sous cette part de ses PV.
##
## [b]Rapport[/b], par équipe et par variante : arrivée au bout, défaites par étape, puis, pour
## chaque étape (parmi les parties qui l'atteignent) : combats, victoires, fuites, défaites,
## tours par combat, K.O., objets consommés, PV de l'équipe après l'étape, niveau moyen,
## niveau le plus haut avant l'étape (« meneur avant », T20) ;
## enfin les niveaux de chaque membre à l'arrivée.
##
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --valider
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --seeds 200
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --save <sauvegarde.json>
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --donnees
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --scenario <fichier.json>
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --equipe <texte>
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --variante <texte>
##   godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --trace <texte>
##
## `--valider` : lit et vérifie le scénario, l'affiche, puis s'arrête (aucun combat).
## `--save` : ajoute l'équipe d'une sauvegarde (clé « party ») ; une variante peut alors
## prendre les objets de son Sac (« items » : { "potion": "sac" }). `--donnees` : les Dresseurs
## et les tables présents dans `data/` (même identifiant de Dresseur ; même carte et même
## terrain de table) remplacent ceux du scénario (T26 : vérifier les vraies données).
## `--equipe`, `--variante` : seulement les équipes / variantes dont le nom contient ce texte.
## `--trace` (T26) : déroulé, phrase par phrase, des combats des étapes dont le nom contient ce
## texte, pour les [constant TRACE_SEEDS] premières graines de chaque ligne.
##
## Codes de sortie : [constant EXIT_OK] tout est simulé (ou valide) ; [constant EXIT_ERROR]
## scénario, données ou arguments invalides ; [constant EXIT_SKIPPED] simulé (ou validé) en
## sautant des éléments dont une espèce, une capacité ou un objet manque aux données.

@warning_ignore_start("integer_division")

const DEFAULT_SCENARIO: String = "res://tools/sim/mt_moon_scenario.json"
const SCENARIO_VERSION: int = 1
const EXIT_OK: int = 0
const EXIT_ERROR: int = 1
const EXIT_SKIPPED: int = 3
const DEFAULT_SEEDS: int = 500
const MAX_TURNS: int = 200
## Battle.State, Battle.Outcome (les classes du jeu sont chargées par load()).
const CHOOSING: int = 1
const OVER: int = 2
const REPLACING: int = 3
const WIN: int = 1
const LOSS: int = 2
const FLED: int = 3
## BattleEvent.Kind (`--trace`).
const BATTLE_EVENT_SENT_OUT: int = 1
const BATTLE_EVENT_DAMAGE: int = 5
## Terrains de rencontre acceptés par le scénario (« rubble » arrive dans le moteur au T20).
const TERRAINS: Array[String] = ["grass", "rubble"]
const POLICIES: Array[String] = ["naif", "attentif", "expert"]
## Joueur « expert » (T20) : change de Pokémon quand un autre est au moins ce nombre de fois
## mieux placé (rapport dégâts infligés / reçus de [method _best_against]).
const EXPERT_SWITCH_FACTOR: float = 2.0
## Ordre des IV d'un membre d'équipe (« ivs » : 6 entiers) = SpeciesData.STATS.
const STAT_KEYS: Array[String] = ["hp", "atk", "def", "spa", "spd", "spe"]
const TOP_KEYS: Array[String] = ["version", "title", "description", "seeds", "heal_at_start",
	"starter", "teams", "tables", "trainers", "steps", "variants"]
const TEAM_KEYS: Array[String] = ["name", "members", "starter"]
const MEMBER_KEYS: Array[String] = ["species", "level", "moves", "ivs"]
const TABLE_KEYS: Array[String] = ["maps", "terrain", "rate", "ramp", "slots"]
const SLOT_KEYS: Array[String] = ["species", "levels", "weight"]
const STEP_KEYS: Array[String] = ["label", "wild", "cells", "count", "trainer", "center",
	"optional"]
const VARIANT_KEYS: Array[String] = ["name", "player", "center", "items", "flee_below",
	"optional", "retries"]
## Joueur attentif, hors combat : Potions tant que les PV sont sous cette part du maximum.
const HEAL_OUTSIDE_BELOW: float = 0.5
## `--trace` : nombre de graines dont les combats sont racontés, par ligne.
const TRACE_SEEDS: int = 3
## Valeur d'une quantité d'objet qui renvoie au Sac de la sauvegarde (`--save`).
const FROM_BAG: String = "sac"
## Groupe d'une étape « optional » : true (format du J12).
const DEFAULT_GROUP: String = "détour"
const DEFAULT_TITLE: String = "Équilibrage de la Route 3 et du Mont Sélénite (jalon 12)"

var _scenario_path: String = DEFAULT_SCENARIO
var _save_path: String = ""
var _seeds: int = 0
var _validate_only: bool = false
var _use_data: bool = false
var _team_filter: String = ""
var _variant_filter: String = ""
var _heal_at_start: bool = true
var _starter: StringName = &""
var _title: String = DEFAULT_TITLE
## Starter de l'équipe de la partie en cours (Dresseurs à « team_by_starter »).
var _play_starter: StringName = &""
var _trace_filter: String = ""
## Vrai pendant une étape racontée (`--trace`) ; [member _text] : phrases du combat.
var _tracing: bool = false
var _battle_text: RefCounted

var _data: RefCounted
var _chart: RefCounted
var _items: RefCounted
## Dresseurs du scénario (une [TrainerLibrary] à part) et ceux de `data/` (`--donnees`).
var _trainers: RefCounted
var _real_trainers: RefCounted
var _real_encounters: RefCounted
var _factory: GDScript
var _party_script: GDScript
var _pokemon_script: GDScript
var _side_script: GDScript
var _battle_script: GDScript
var _rules_script: GDScript
var _action_script: GDScript
var _ai_script: GDScript
var _rng_script: GDScript
var _evolution_script: GDScript
var _table_script: GDScript
var _slot_script: GDScript

## Équipes : { name, members (dictionnaires), save (format de sauvegarde), skip (texte) }.
var _teams: Array[Dictionary] = []
## Tables du scénario construites, par identifiant ; [member _table_info] : { map, terrain,
## skip } de chaque table (même sautée).
var _tables: Dictionary = {}
var _table_info: Dictionary = {}
## Dresseurs du scénario : identifiant → texte d'absence (vide = utilisable).
var _trainer_skip: Dictionary = {}
var _trainer_species: Dictionary = {}
## Étapes : { label, kind (wild, trainer, center), id, cells, count, optional (groupe, vide =
## obligatoire), skip, source,
## table (EncounterTable), library (TrainerLibrary) }.
var _steps: Array[Dictionary] = []
## Variantes : { name, player, center, items ({objet: quantité}), flee_below, optional (true :
## tous les groupes ; sinon liste de groupes), retries, skip }.
var _variants: Array[Dictionary] = []
## Objets du Sac de la sauvegarde (`--save`).
var _save_bag: Dictionary = {}
var _errors: PackedStringArray = PackedStringArray()
## Identifiants absents des données, pour le rapport final (liste de T12).
var _missing_species: Dictionary = {}
var _missing_moves: Dictionary = {}
var _missing_items: Dictionary = {}
var _skipped: int = 0
## Pas sur un terrain de rencontre sans rencontre depuis la dernière (une partie).
var _quiet_steps: int = 0
## Ordre d'origine des équipes réordonnées ([method _put_first]), par identifiant d'instance.
var _orders: Dictionary = {}


func _init() -> void:
	quit(_run())


func _run() -> int:
	if not _read_args() or not _load_game():
		return EXIT_ERROR
	var scenario: Variant = _read_json(_scenario_path)
	if not scenario is Dictionary:
		push_error("scénario illisible (un objet JSON est attendu) : %s" % _scenario_path)
		return EXIT_ERROR
	_parse_scenario(scenario)
	if not _save_path.is_empty():
		_read_save()
	if not _errors.is_empty():
		print("=== Scénario invalide : %s ===" % _scenario_path)
		for error: String in _errors:
			print("  ERREUR " + error)
		return EXIT_ERROR
	print("=== %s ===" % _title)
	print("Scénario : %s" % _scenario_path)
	if scenario.has("description"):
		print(str(scenario["description"]))
	_print_scenario()
	if not _validate_only:
		_simulate()
	return _finish()


# --- Arguments, données, scénario ---------------------------------------------------------

func _read_args() -> bool:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var arg: String = args[i]
		var value: String = args[i + 1] if i + 1 < args.size() else ""
		match arg:
			"--valider":
				_validate_only = true
			"--donnees":
				_use_data = true
			"--scenario", "--save", "--seeds", "--equipe", "--variante", "--trace":
				if value.is_empty():
					push_error("%s attend une valeur" % arg)
					return false
				i += 1
				match arg:
					"--scenario":
						_scenario_path = value
					"--save":
						_save_path = value
					"--seeds":
						_seeds = maxi(int(value), 1)
					"--equipe":
						_team_filter = value
					"--variante":
						_variant_filter = value
					"--trace":
						_trace_filter = value
			_:
				push_error("argument inconnu : %s" % arg)
				return false
		i += 1
	return true


func _load_game() -> bool:
	_data = load("res://game/pokemon/pokemon_data.gd").new()
	if not _data.load_dir():
		push_error("données des Pokémon invalides")
		return false
	_chart = _data.get_type_chart()
	_items = load("res://game/items/item_library.gd").new()
	_real_trainers = load("res://game/battle/trainer_library.gd").new(_data)
	_trainers = load("res://game/battle/trainer_library.gd").new(_data)
	_real_encounters = load("res://game/pokemon/encounters/encounter_library.gd").new(_data)
	if not _items.load_dir() or not _real_trainers.load_dir() \
			or not _real_encounters.load_dir():
		push_error("objets, Dresseurs ou rencontres de data/ invalides")
		return false
	_factory = load("res://game/pokemon/pokemon_factory.gd")
	_battle_text = load("res://game/battle/battle_text.gd").new()
	_battle_text.load_file()
	_party_script = load("res://game/pokemon/party.gd")
	_pokemon_script = load("res://game/pokemon/pokemon.gd")
	_side_script = load("res://game/battle/battle_side.gd")
	_battle_script = load("res://game/battle/battle.gd")
	_rules_script = load("res://game/battle/battle_rules.gd")
	_action_script = load("res://game/battle/battle_action.gd")
	_ai_script = load("res://game/battle/battle_ai.gd")
	_rng_script = load("res://game/systems/random/game_rng.gd")
	_evolution_script = load("res://game/pokemon/evolution/evolution.gd")
	_table_script = load("res://game/pokemon/encounters/encounter_table.gd")
	_slot_script = load("res://game/pokemon/encounters/encounter_slot.gd")
	return true


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("fichier introuvable : %s" % path)
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
		return null
	return json.data


func _parse_scenario(scenario: Dictionary) -> void:
	_check_keys(scenario, TOP_KEYS, "scénario")
	if int(scenario.get("version", 0)) != SCENARIO_VERSION:
		_error("scénario : « version » doit valoir %d" % SCENARIO_VERSION)
	if _seeds <= 0:
		_seeds = DEFAULT_SEEDS
		if scenario.has("seeds"):
			if _is_int(scenario["seeds"]) and int(scenario["seeds"]) >= 1:
				_seeds = int(scenario["seeds"])
			else:
				_error("scénario : « seeds » doit être un entier ≥ 1")
	if scenario.has("heal_at_start"):
		if scenario["heal_at_start"] is bool:
			_heal_at_start = scenario["heal_at_start"]
		else:
			_error("scénario : « heal_at_start » vaut true ou false")
	if scenario.has("starter"):
		_starter = StringName(str(scenario["starter"]))
	if scenario.has("title"):
		_title = _text(scenario, "title", "scénario")
	_parse_teams(scenario.get("teams", []))
	_parse_tables(scenario.get("tables", {}))
	_parse_trainers(scenario.get("trainers", {}))
	_parse_steps(scenario.get("steps"))
	_parse_variants(scenario.get("variants"))
	_check_starters()


## Un Dresseur à « team_by_starter » du parcours exige le starter de chaque équipe.
func _check_starters() -> void:
	var by_starter := PackedStringArray()
	for step: Dictionary in _steps:
		if step.get("kind") != "trainer" or not step.has("library"):
			continue
		var trainer: RefCounted = step["library"].get_trainer(StringName(step["id"]))
		if not trainer.team_by_starter.is_empty():
			by_starter.append(str(step["id"]))
	if by_starter.is_empty() or not _starter.is_empty():
		return
	for team: Dictionary in _teams:
		if StringName(team.get("starter", &"")).is_empty() and not team["save"]:
			_error("équipe « %s » : « starter » requis (Dresseurs à team_by_starter : %s)" % [
				team["name"], ", ".join(by_starter)])


func _parse_teams(value: Variant) -> void:
	if not value is Array:
		_error("« teams » doit être une liste")
		return
	for i: int in (value as Array).size():
		var where := "teams %d" % (i + 1)
		var entry: Variant = value[i]
		if not entry is Dictionary:
			_error("%s : un objet { name, members } est attendu" % where)
			continue
		_check_keys(entry, TEAM_KEYS, where)
		var name := _text(entry, "name", where)
		var members: Variant = entry.get("members")
		if not members is Array or (members as Array).is_empty() or (members as Array).size() > 6:
			_error("%s : « members » doit compter 1 à 6 Pokémon" % where)
			continue
		var missing := { "species": [], "moves": [] }
		for j: int in (members as Array).size():
			_check_member(members[j], "%s membre %d" % [where, j + 1], missing)
		var starter := ""
		if entry.has("starter"):
			starter = _text(entry, "starter", where)
		_teams.append({ "name": name, "members": members, "save": false,
			"skip": _missing_text(missing), "starter": StringName(starter) })


func _check_member(value: Variant, where: String, missing: Dictionary) -> void:
	if not value is Dictionary:
		_error("%s : un objet { species, level } est attendu" % where)
		return
	var member: Dictionary = value
	_check_keys(member, MEMBER_KEYS, where)
	_check_species(member.get("species"), where, missing)
	if not _is_int(member.get("level")) or int(member["level"]) < 1 \
			or int(member["level"]) > 100:
		_error("%s : « level » doit être un entier de 1 à 100" % where)
	if member.has("moves"):
		var moves: Variant = member["moves"]
		if not moves is Array or (moves as Array).is_empty() or (moves as Array).size() > 4:
			_error("%s : « moves » doit compter 1 à 4 capacités" % where)
		else:
			for move_id: Variant in moves:
				_check_move(move_id, where, missing)
	if member.has("ivs"):
		var ivs: Variant = member["ivs"]
		var ok: bool = ivs is Array and (ivs as Array).size() == STAT_KEYS.size()
		if ok:
			for iv: Variant in ivs:
				ok = ok and _is_int(iv) and int(iv) >= 0 and int(iv) <= 31
		if not ok:
			_error("%s : « ivs » doit compter 6 entiers de 0 à 31 (%s)" % [where,
				", ".join(PackedStringArray(STAT_KEYS))])


func _parse_tables(value: Variant) -> void:
	if not value is Dictionary:
		_error("« tables » doit être un objet « identifiant → table »")
		return
	for key: Variant in value:
		var id := str(key)
		var where := "table « %s »" % id
		var entry: Variant = value[key]
		if not entry is Dictionary:
			_error("%s : un objet est attendu" % where)
			continue
		_check_keys(entry, TABLE_KEYS, where)
		var maps: Variant = entry.get("maps")
		if not maps is Array or (maps as Array).is_empty() or not maps[0] is String:
			_error("%s : « maps » doit être une liste d'identifiants non vide" % where)
			continue
		var terrain := str(entry.get("terrain", ""))
		if not TERRAINS.has(terrain):
			_error("%s : « terrain » vaut %s" % [where, ", ".join(PackedStringArray(TERRAINS))])
		var rate: Variant = entry.get("rate")
		if not _is_int(rate) or int(rate) < 1 or int(rate) > 255:
			_error("%s : « rate » doit être un entier de 1 à 255" % where)
		var table: RefCounted = _table_script.new()
		table.id = StringName(id)
		table.terrain = StringName(terrain)
		table.maps.assign((maps as Array).map(func(m: Variant) -> StringName:
			return StringName(str(m))))
		table.rate = int(rate) if _is_int(rate) else 0
		if entry.has("ramp"):
			var ramp: Variant = entry["ramp"]
			if not ramp is Dictionary or not _is_int(ramp.get("from_step")) \
					or not _is_int(ramp.get("max_steps")) \
					or int(ramp["from_step"]) < 1 \
					or int(ramp["max_steps"]) <= int(ramp["from_step"]):
				_error("%s : « ramp » doit être { from_step ≥ 1, max_steps > from_step }" % where)
			else:
				table.ramp_from = int(ramp["from_step"])
				table.ramp_max = int(ramp["max_steps"])
		var missing := { "species": [], "moves": [] }
		var slots: Variant = entry.get("slots")
		if not slots is Array or (slots as Array).is_empty():
			_error("%s : « slots » doit être une liste non vide" % where)
			slots = []
		for j: int in (slots as Array).size():
			var slot := _parse_slot(slots[j], "%s emplacement %d" % [where, j + 1], missing)
			if slot != null:
				table.slots.append(slot)
		var skip := _missing_text(missing)
		_table_info[id] = { "map": StringName(str(maps[0])), "terrain": StringName(terrain),
			"skip": skip }
		if skip.is_empty():
			_tables[id] = table


func _parse_slot(value: Variant, where: String, missing: Dictionary) -> RefCounted:
	if not value is Dictionary:
		_error("%s : un objet { species, levels, weight } est attendu" % where)
		return null
	var entry: Dictionary = value
	_check_keys(entry, SLOT_KEYS, where)
	var known := _check_species(entry.get("species"), where, missing)
	var levels: Variant = entry.get("levels")
	if not levels is Array or (levels as Array).size() != 2 or not _is_int(levels[0]) \
			or not _is_int(levels[1]) or int(levels[0]) < 1 \
			or int(levels[0]) > int(levels[1]) or int(levels[1]) > 100:
		_error("%s : « levels » doit être [min, max], 1 ≤ min ≤ max ≤ 100" % where)
		return null
	if not _is_int(entry.get("weight")) or int(entry["weight"]) < 1:
		_error("%s : « weight » doit être un entier > 0" % where)
		return null
	if not known:
		return null
	return _slot_script.new(StringName(entry["species"]), int(levels[0]), int(levels[1]),
		int(entry["weight"]))


func _parse_trainers(value: Variant) -> void:
	if not value is Dictionary:
		_error("« trainers » doit être un objet « identifiant → Dresseur »")
		return
	for key: Variant in value:
		var id := str(key)
		var where := "Dresseur « %s »" % id
		var entry: Variant = value[key]
		if not entry is Dictionary:
			_error("%s : un objet est attendu (format de data/trainers/)" % where)
			continue
		var missing := { "species": [], "moves": [] }
		var teams: Array = []
		if entry.get("team") is Array:
			teams.append(entry["team"])
		if entry.get("team_by_starter") is Dictionary:
			teams.append_array((entry["team_by_starter"] as Dictionary).values())
		var species: Array = []
		for team: Variant in teams:
			if not team is Array:
				continue
			for slot: Variant in team:
				if not slot is Dictionary:
					continue
				species.append(str(slot.get("species", "")))
				_check_species(slot.get("species"), where, missing)
				if slot.get("moves") is Array:
					for move_id: Variant in slot["moves"]:
						_check_move(move_id, where, missing)
		_trainer_species[id] = species
		var skip := _missing_text(missing)
		_trainer_skip[id] = skip
		if skip.is_empty() and not _trainers.add_from_dict({ id: entry }, "scénario"):
			_error("%s : refusé par TrainerLibrary (%s)" % [where,
				_trainers.get_errors()[-1] if not _trainers.get_errors().is_empty() else "?"])


func _parse_steps(value: Variant) -> void:
	if not value is Array or (value as Array).is_empty():
		_error("« steps » doit être une liste non vide")
		return
	for i: int in (value as Array).size():
		var where := "steps %d" % (i + 1)
		var entry: Variant = value[i]
		if not entry is Dictionary:
			_error("%s : un objet est attendu" % where)
			continue
		_check_keys(entry, STEP_KEYS, where)
		var step := { "label": _text(entry, "label", where), "optional": "", "skip": "",
			"source": "scénario", "cells": 0, "count": 0, "id": "" }
		step["optional"] = ""
		if entry.has("optional"):
			var group: Variant = entry["optional"]
			if group is bool:
				step["optional"] = DEFAULT_GROUP if group else ""
			elif group is String and not (group as String).strip_edges().is_empty():
				step["optional"] = group
			else:
				_error("%s : « optional » vaut true, false ou un nom de groupe" % where)
		var kinds := 0
		for kind: String in ["wild", "trainer", "center"]:
			kinds += 1 if entry.has(kind) else 0
		if kinds != 1:
			_error("%s : une et une seule des clés « wild », « trainer », « center »" % where)
			continue
		if entry.has("center"):
			if not (entry["center"] is bool and entry["center"]):
				_error("%s : « center » vaut true" % where)
			step["kind"] = "center"
		elif entry.has("wild"):
			_parse_wild_step(entry, step, where)
		else:
			_parse_trainer_step(entry, step, where)
		_steps.append(step)


func _parse_wild_step(entry: Dictionary, step: Dictionary, where: String) -> void:
	step["kind"] = "wild"
	var id := str(entry["wild"])
	step["id"] = id
	for key: String in ["cells", "count"]:
		if entry.has(key):
			if _is_int(entry[key]) and int(entry[key]) >= 0:
				step[key] = int(entry[key])
			else:
				_error("%s : « %s » doit être un entier ≥ 0" % [where, key])
	if int(step["cells"]) + int(step["count"]) == 0:
		_error("%s : « cells » ou « count » doit être > 0" % where)
	if not _table_info.has(id):
		_error("%s : table inconnue « %s » (absente de « tables »)" % [where, id])
		return
	var info: Dictionary = _table_info[id]
	if _use_data and _real_encounters.has_table(info["map"], info["terrain"]):
		step["table"] = _real_encounters.get_table(info["map"], info["terrain"])
		step["source"] = "données"
	elif not str(info["skip"]).is_empty():
		step["skip"] = info["skip"]
	else:
		step["table"] = _tables[id]


func _parse_trainer_step(entry: Dictionary, step: Dictionary, where: String) -> void:
	step["kind"] = "trainer"
	var id := str(entry["trainer"])
	step["id"] = id
	if not _trainer_skip.has(id):
		_error("%s : Dresseur inconnu « %s » (absent de « trainers »)" % [where, id])
		return
	if _use_data and _real_trainers.has_trainer(StringName(id)):
		step["library"] = _real_trainers
		step["source"] = "données"
	elif not str(_trainer_skip[id]).is_empty():
		step["skip"] = _trainer_skip[id]
	else:
		step["library"] = _trainers


func _parse_variants(value: Variant) -> void:
	if not value is Array or (value as Array).is_empty():
		_error("« variants » doit être une liste non vide")
		return
	for i: int in (value as Array).size():
		var where := "variants %d" % (i + 1)
		var entry: Variant = value[i]
		if not entry is Dictionary:
			_error("%s : un objet est attendu" % where)
			continue
		_check_keys(entry, VARIANT_KEYS, where)
		var variant := { "name": _text(entry, "name", where), "player": "attentif",
			"center": false, "items": {}, "flee_below": 0.0, "optional": false, "retries": 0,
			"skip": "" }
		var player := str(entry.get("player", "attentif"))
		if not POLICIES.has(player):
			_error("%s : « player » vaut %s" % [where, ", ".join(PackedStringArray(POLICIES))])
		variant["player"] = player
		if entry.has("center"):
			if entry["center"] is bool:
				variant["center"] = entry["center"]
			else:
				_error("%s : « center » vaut true ou false" % where)
		if entry.has("optional"):
			var groups: Variant = entry["optional"]
			var ok: bool = groups is bool or groups is Array
			if groups is Array:
				for group: Variant in groups:
					ok = ok and group is String and not (group as String).is_empty()
			if ok:
				variant["optional"] = groups
			else:
				_error("%s : « optional » vaut true, false ou une liste de groupes" % where)
		if entry.has("flee_below"):
			var flee: Variant = entry["flee_below"]
			if (flee is int or flee is float) and float(flee) >= 0.0 and float(flee) <= 1.0:
				variant["flee_below"] = float(flee)
			else:
				_error("%s : « flee_below » doit être un nombre de 0 à 1" % where)
		if entry.has("retries"):
			if _is_int(entry["retries"]) and int(entry["retries"]) >= 0:
				variant["retries"] = int(entry["retries"])
			else:
				_error("%s : « retries » doit être un entier ≥ 0" % where)
		variant["skip"] = _parse_items(entry.get("items", {}), variant["items"], where)
		_variants.append(variant)


## Lit « items » ({ objet : quantité ≥ 0 ou "sac" }) dans [param into] ; renvoie le texte des
## objets absents des données (vide : tout est connu).
func _parse_items(value: Variant, into: Dictionary, where: String) -> String:
	if not value is Dictionary:
		_error("%s : « items » doit être un objet { objet : quantité }" % where)
		return ""
	var absent := PackedStringArray()
	for key: Variant in value:
		var id := StringName(str(key))
		var count: Variant = value[key]
		if not (count is String and count == FROM_BAG) \
				and not (_is_int(count) and int(count) >= 0):
			_error("%s : quantité de « %s » : un entier ≥ 0 ou \"%s\"" % [where, id, FROM_BAG])
			continue
		if not _items.has_item(id):
			absent.append(String(id))
			_missing_items[String(id)] = true
			continue
		var item: RefCounted = _items.get_item(id)
		if item.heal_amount <= 0 and item.cures.is_empty():
			_error("%s : « %s » ne soigne pas (heal_amount ou cures attendu)" % [where, id])
			continue
		into[id] = count if count is String else int(count)
	return "" if absent.is_empty() else "objets absents des données : " + ", ".join(absent)


func _read_save() -> void:
	var parsed: Variant = _read_json(_save_path)
	if not parsed is Dictionary or not (parsed as Dictionary).get("party") is Array:
		_error("sauvegarde illisible ou sans « party » : %s" % _save_path)
		return
	var missing := { "species": [], "moves": [] }
	var members: Array = parsed["party"]
	for i: int in members.size():
		var entry: Variant = members[i]
		var where := "sauvegarde membre %d" % (i + 1)
		if not entry is Dictionary:
			_error("%s : un objet est attendu" % where)
			continue
		_check_species(entry.get("species"), where, missing)
		if entry.get("moves") is Array:
			for move: Variant in entry["moves"]:
				_check_move(move.get("id") if move is Dictionary else move, where, missing)
	var bag: Variant = parsed.get("bag", {})
	if bag is Dictionary:
		var items: Variant = (bag as Dictionary).get("items", bag)
		if items is Dictionary:
			for key: Variant in items:
				if _is_int(items[key]):
					_save_bag[StringName(str(key))] = int(items[key])
	if _starter.is_empty():
		_starter = StringName(str(parsed.get("starter", "")))
	_teams.append({ "name": "Partie de Kevin (sauvegarde)", "members": members, "save": true,
		"skip": _missing_text(missing), "starter": StringName(str(parsed.get("starter", ""))) })


# --- Affichage du scénario ----------------------------------------------------------------

func _print_scenario() -> void:
	var rng: RefCounted = _rng_script.new(0)
	print("")
	print("--- Équipes de départ (graine 0) :")
	for team: Dictionary in _teams:
		if not str(team["skip"]).is_empty():
			_skip_line("équipe « %s »" % team["name"], team["skip"])
			continue
		print("  %s : %s" % [team["name"], _party_text(_build_team(team, rng))])
	print("--- Tables :")
	for id: String in _table_info:
		var info: Dictionary = _table_info[id]
		if not str(info["skip"]).is_empty():
			_skip_line("table « %s »" % id, info["skip"])
			continue
		var table: RefCounted = _tables[id]
		var slots := PackedStringArray()
		for slot: RefCounted in table.slots:
			slots.append("%s %d–%d (%d)" % [_name(slot.species), slot.min_level, slot.max_level,
				slot.weight])
		var ramp := "montée %d → %d" % [table.ramp_from, table.ramp_max] \
			if table.has_ramp() else "sans montée"
		print("  %s [%s, taux %d, %s] : %s" % [id, table.terrain, table.rate, ramp,
			", ".join(slots)])
	print("--- Dresseurs :")
	for id: String in _trainer_skip:
		if not str(_trainer_skip[id]).is_empty():
			_skip_line("Dresseur « %s » (%s)" % [id, ", ".join(PackedStringArray(
				_trainer_species[id]))], _trainer_skip[id])
			continue
		print("  %s : %s" % [id, _trainer_text(_trainers, StringName(id))])
	print("--- Parcours :")
	for i: int in _steps.size():
		var step: Dictionary = _steps[i]
		var what := "Centre (si la variante a « center »)"
		if step["kind"] == "wild":
			what = "%s, %d case(s) + %d rencontre(s) forcée(s)" % [step["id"], step["cells"],
				step["count"]]
		elif step["kind"] == "trainer":
			what = str(step["id"])
		var flags := (" [%s]" % step["optional"]) if not str(step["optional"]).is_empty() else ""
		if step["source"] == "données":
			flags += " [données]"
		if not str(step["skip"]).is_empty():
			_skip_line("étape %d « %s » (%s)" % [i + 1, step["label"], what], step["skip"])
			continue
		print("  %2d. %s : %s%s" % [i + 1, step["label"], what, flags])
	print("--- Variantes :")
	for variant: Dictionary in _variants:
		if not str(variant["skip"]).is_empty():
			_skip_line("variante « %s »" % variant["name"], variant["skip"])
			continue
		var groups: Variant = variant["optional"]
		var detours := ("oui" if groups else "non") if groups is bool \
			else ("non" if (groups as Array).is_empty() else ", ".join(PackedStringArray(groups)))
		print("  %s : joueur %s, Centre %s, objets %s, fuite sous %.2f, détours %s, reprises %d"
			% [variant["name"], variant["player"], "oui" if variant["center"] else "non",
			_items_text(variant["items"]), variant["flee_below"], detours, variant["retries"]])


func _skip_line(what: String, reason: String) -> void:
	_skipped += 1
	print("  SAUTÉ %s — %s" % [what, reason])


# --- Simulation ---------------------------------------------------------------------------

func _simulate() -> void:
	print("")
	print("=== Simulation : %d graine(s) par ligne ===" % _seeds)
	for team: Dictionary in _teams:
		if not _team_filter.is_empty() and not str(team["name"]).contains(_team_filter):
			continue
		if not str(team["skip"]).is_empty():
			continue
		for variant: Dictionary in _variants:
			if not _variant_filter.is_empty() \
					and not str(variant["name"]).contains(_variant_filter):
				continue
			if str(variant["skip"]).is_empty():
				_report(team, variant)


func _report(team: Dictionary, variant: Dictionary) -> void:
	var stats: Array[Dictionary] = []
	for step: Dictionary in _steps:
		stats.append(_blank_stats())
	var totals := { "end": 0, "hp": 0.0, "kos": 0, "items": {}, "levels": [], "evolved": [],
		"names": [], "after_defeats": {}, "tries": {} }
	for seed_value: int in _seeds:
		_play(team, variant, seed_value, stats, totals)
	print("")
	print("--- %s | %s" % [team["name"], variant["name"]])
	var defeats := PackedStringArray()
	for i: int in _steps.size():
		if int(stats[i]["defeats"]) > 0:
			defeats.append("%s %.1f %%" % [_steps[i]["label"],
				100.0 * stats[i]["defeats"] / _seeds])
	print("  arrivée au bout %.1f %% | K.O. %.2f | objets %s | PV à l'arrivée %s" % [
		100.0 * totals["end"] / _seeds, float(totals["kos"]) / _seeds,
		_used_text(totals["items"], _seeds),
		("%.0f %%" % (100.0 * totals["hp"] / totals["end"])) if totals["end"] > 0 else "—"])
	print("  défaites : %s" % ("aucune" if defeats.is_empty() else ", ".join(defeats)))
	if int(variant["retries"]) > 0 and variant["center"]:
		var parts := PackedStringArray()
		for n: int in int(variant["retries"]) + 1:
			parts.append("%d défaite(s) %.1f %%" % [n,
				100.0 * int(totals["after_defeats"].get(n, 0)) / _seeds])
		print("  avec reprises au Centre : arrivée après %s" % ", ".join(parts))
		_print_tries(totals["tries"])
	for i: int in _steps.size():
		var s: Dictionary = stats[i]
		var reached: int = s["reached"]
		if reached == 0:
			continue
		var battles: int = s["battles"]
		var line := "  %-40s %5.1f %% | combats %4.2f" % [_steps[i]["label"],
			100.0 * reached / _seeds, float(battles) / reached]
		if battles > 0:
			line += " | vict. %5.1f %% | fuites %4.2f | défaites %5.1f %% | %4.1f tours" % [
				100.0 * s["wins"] / battles, float(s["fled"]) / reached,
				100.0 * s["defeats"] / reached, float(s["turns"]) / battles]
		line += " | K.O. %4.2f | objets %s | PV après %3.0f %% | niv. %4.1f | meneur avant N%4.1f" \
			% [float(s["kos"]) / reached, _used_text(s["items"], reached),
			100.0 * s["hp"] / reached, s["level"] / reached, s["top"] / reached]
		if int(s["unfinished"]) > 0:
			line += " | %d non terminés" % s["unfinished"]
		print(line)
	if totals["end"] > 0:
		var levels := PackedStringArray()
		for j: int in (totals["levels"] as Array).size():
			levels.append("%s N%.1f%s" % [totals["names"][j],
				totals["levels"][j] / totals["end"],
				(" (évolué %.0f %%)" % (100.0 * totals["evolved"][j] / totals["end"]))
				if totals["evolved"][j] > 0 else ""])
		print("  niveaux à l'arrivée : %s" % ", ".join(levels))


func _play(team: Dictionary, variant: Dictionary, seed_value: int, stats: Array[Dictionary],
		totals: Dictionary) -> void:
	var rng: RefCounted = _rng_script.new(seed_value)
	var party: RefCounted = _build_team(team, rng)
	var start: Array = party.get_all().duplicate()
	var start_species: Array[StringName] = []
	for pokemon: RefCounted in start:
		start_species.append(pokemon.species_id)
	if _heal_at_start:
		party.heal_all()
	var bag := _start_bag(variant)
	_quiet_steps = 0
	_play_starter = team.get("starter", &"")
	if _play_starter.is_empty():
		_play_starter = _starter
	# Reprises (T26, « retries ») : après une défaite, réveil au dernier Centre (soin) et
	# reprise à l'étape qui le suit ; les Dresseurs battus sont partis. Les statistiques
	# d'étape ne comptent que la première tentative.
	var defeats := 0
	var restart := 0
	var beaten: Dictionary = {}
	# T20 : tentatives par Dresseur (indice d'étape → nombre), première comprise.
	var tries: Dictionary = {}
	var i := 0
	while i < _steps.size():
		var step: Dictionary = _steps[i]
		i += 1
		if not str(step["skip"]).is_empty() or not _step_played(step, variant):
			continue
		if step["kind"] == "center" and not variant["center"]:
			continue
		if beaten.has(i - 1):
			continue
		if step["kind"] == "trainer":
			tries[i - 1] = int(tries.get(i - 1, 0)) + 1
		if defeats > 0:
			_tracing = false
			var retry_lost := _play_step(step, party, rng, variant, bag, _blank_stats())
			if step["kind"] == "center":
				restart = i
			elif step["kind"] == "trainer" and not retry_lost:
				beaten[i - 1] = true
			if retry_lost:
				defeats += 1
				if defeats > int(variant["retries"]):
					_add_tries(totals, tries, beaten)
					return
				party.heal_all()
				i = restart
			continue
		var s: Dictionary = stats[i - 1]
		s["reached"] += 1
		_tracing = not _trace_filter.is_empty() and seed_value < TRACE_SEEDS \
			and str(step["label"]).contains(_trace_filter)
		if _tracing:
			print("  >>> graine %d, %s : %s" % [seed_value, step["label"], _party_text(party)])
		var before := bag.duplicate()
		var fainted := _fainted(party)
		s["top"] += _top_level(party)
		var lost := _play_step(step, party, rng, variant, bag, s)
		if step["kind"] == "center":
			restart = i
		elif step["kind"] == "trainer" and not lost:
			beaten[i - 1] = true
		var kos := maxi(_fainted(party) - fainted, 0)
		s["kos"] += kos
		totals["kos"] += kos
		for id: StringName in before:
			var used: int = int(before[id]) - int(bag[id])
			s["items"][id] = int(s["items"].get(id, 0)) + used
			totals["items"][id] = int(totals["items"].get(id, 0)) + used
		s["hp"] += _hp_share(party)
		s["level"] += _mean_level(party)
		if lost:
			s["defeats"] += 1
			defeats = 1
			if int(variant["retries"]) == 0 or not variant["center"]:
				_add_tries(totals, tries, beaten)
				return
			party.heal_all()
			i = restart
	_add_tries(totals, tries, beaten)
	totals["after_defeats"][defeats] = int(totals["after_defeats"].get(defeats, 0)) + 1
	if defeats > 0:
		return
	totals["end"] += 1
	totals["hp"] += _hp_share(party)
	if (totals["levels"] as Array).is_empty():
		for species: StringName in start_species:
			totals["levels"].append(0.0)
			totals["evolved"].append(0)
			totals["names"].append(_name(species))
	for j: int in start.size():
		var pokemon: RefCounted = start[j]
		totals["levels"][j] += pokemon.level
		totals["evolved"][j] += 1 if pokemon.species_id != start_species[j] else 0


## T20 : cumule les tentatives d'une partie, par Dresseur ({ parties, battu, tentatives
## jusqu'à la victoire }).
func _add_tries(totals: Dictionary, tries: Dictionary, beaten: Dictionary) -> void:
	for index: int in tries:
		var t: Dictionary = totals["tries"].get(index, { "games": 0, "beaten": 0, "attempts": 0 })
		t["games"] += 1
		if beaten.has(index):
			t["beaten"] += 1
			t["attempts"] += int(tries[index])
		totals["tries"][index] = t


## T20 (avec reprises) : tentatives moyennes jusqu'à la victoire et part des parties qui
## battent chaque Dresseur (parmi celles qui l'atteignent), pour les Dresseurs perdus au moins
## une fois.
func _print_tries(tries: Dictionary) -> void:
	var indexes: Array = tries.keys()
	indexes.sort()
	for index: int in indexes:
		var t: Dictionary = tries[index]
		if int(t["beaten"]) == int(t["games"]) and int(t["attempts"]) == int(t["beaten"]):
			continue
		print("  tentatives : %-40s %4.2f jusqu'à la victoire | battu %5.1f %% de %d parties"
			% [_steps[index]["label"], float(t["attempts"]) / maxi(int(t["beaten"]), 1),
			100.0 * t["beaten"] / t["games"], t["games"]])


## Vrai si [param step] est obligatoire ou si son groupe est demandé par [param variant].
func _step_played(step: Dictionary, variant: Dictionary) -> bool:
	var group := str(step["optional"])
	if group.is_empty():
		return true
	var groups: Variant = variant["optional"]
	return groups if groups is bool else (groups as Array).has(group)


## Joue une étape ; vrai si l'équipe entière est K.O.
func _play_step(step: Dictionary, party: RefCounted, rng: RefCounted, variant: Dictionary,
		bag: Dictionary, s: Dictionary) -> bool:
	match step["kind"]:
		"center":
			party.heal_all()
		"wild":
			return _wild_step(step, party, rng, variant, bag, s)
		"trainer":
			return _trainer_step(step, party, rng, variant, bag, s)
	return false


## Compteurs d'une étape (une tentative).
func _blank_stats() -> Dictionary:
	return { "reached": 0, "battles": 0, "wins": 0, "fled": 0, "defeats": 0, "turns": 0,
		"kos": 0, "hp": 0.0, "level": 0.0, "top": 0.0, "items": {}, "unfinished": 0 }


## Étape « wild » : renvoie vrai si l'équipe entière est K.O.
func _wild_step(step: Dictionary, party: RefCounted, rng: RefCounted, variant: Dictionary,
		bag: Dictionary, s: Dictionary) -> bool:
	var table: RefCounted = step["table"]
	var encounters: Array = []
	for cell: int in int(step["cells"]):
		var encounter: RefCounted = table.roll(rng, _quiet_steps)
		if encounter == null:
			_quiet_steps += 1
			continue
		_quiet_steps = 0
		if _wild_battle(encounter, party, rng, variant, bag, s):
			return true
	for i: int in int(step["count"]):
		if _wild_battle(table.pick(rng), party, rng, variant, bag, s):
			return true
	return false


func _wild_battle(encounter: RefCounted, party: RefCounted, rng: RefCounted,
		variant: Dictionary, bag: Dictionary, s: Dictionary) -> bool:
	var foes: RefCounted = _party_script.new()
	foes.add(_factory.create(_data, encounter.species, encounter.level, rng))
	var player: RefCounted = _side_script.new(party, true)
	var foe: RefCounted = _side_script.new(foes, false, "")
	var battle: RefCounted = _battle_script.new(player, foe, _data, rng,
		_rules_script.for_wild(_items))
	_trace(battle.start())
	return _after_battle(_fight(battle, player, foe, rng, variant, bag, true), party, variant,
		bag, s)


## Étape « trainer » : renvoie vrai si l'équipe entière est K.O.
func _trainer_step(step: Dictionary, party: RefCounted, rng: RefCounted, variant: Dictionary,
		bag: Dictionary, s: Dictionary) -> bool:
	var library: RefCounted = step["library"]
	var id := StringName(step["id"])
	var trainer: RefCounted = library.get_trainer(id)
	var foes: RefCounted = library.build_team(id, _play_starter, rng)
	if variant["player"] != "naif":
		_put_first(party, _best_against(party, foes.get_at(0)))
	var player: RefCounted = _side_script.new(party, true)
	# IA du jeu (TrainerData.make_ai) : « switch » = au plus un changement par combat (J13 T20).
	var foe: RefCounted = _side_script.new(foes, false, trainer.name,
		_ai_script.new(trainer.ai, trainer.can_switch))
	var battle: RefCounted = _battle_script.new(player, foe, _data, rng,
		_rules_script.for_trainer(trainer, _items))
	_trace(battle.start())
	var result := _fight(battle, player, foe, rng, variant, bag, false)
	_restore_order(party)
	return _after_battle(result, party, variant, bag, s)


## Comptes d'un combat terminé ([issue, tours]) ; évolutions et soins hors combat. Vrai si
## défaite.
func _after_battle(result: Array[int], party: RefCounted, variant: Dictionary,
		bag: Dictionary, s: Dictionary) -> bool:
	s["battles"] += 1
	s["turns"] += result[1]
	match result[0]:
		WIN:
			s["wins"] += 1
		FLED:
			s["fled"] += 1
		LOSS:
			return true
		_:
			s["unfinished"] += 1
	_evolve(party)
	if variant["player"] != "naif":
		_heal_outside(party, bag)
	return false


## Mène le combat jusqu'au bout ; renvoie [issue, tours].
func _fight(battle: RefCounted, player: RefCounted, foe: RefCounted, rng: RefCounted,
		variant: Dictionary, bag: Dictionary, wild: bool) -> Array[int]:
	var ai: RefCounted = _ai_script.new(&"smart")
	var careful: bool = variant["player"] != "naif"
	var expert: bool = variant["player"] == "expert"
	# Expert : au plus un changement volontaire par Pokémon adverse en jeu.
	var switched_against: RefCounted = null
	var flee_below: float = variant["flee_below"] if wild else 0.0
	var party: RefCounted = player.party
	while battle.get_state() != OVER and battle.get_turn() < MAX_TURNS:
		if battle.get_state() == REPLACING:
			var next: RefCounted = _best_against(party, foe.active.pokemon) if careful \
				else party.first_able()
			_trace(battle.replace(party.index_of(next)))
			continue
		var active: RefCounted = player.active.pokemon
		var action: RefCounted = null
		if flee_below > 0.0 and float(active.hp) / active.max_hp() < flee_below:
			action = _action_script.run()
			# Ligoté (piège, J12) : la fuite est refusée avant le tour ; on se bat.
			if not battle.is_legal(action):
				action = null
		if action == null and careful:
			action = _heal_action(battle, player, foe, bag)
		if action == null and expert and not wild and switched_against != foe.active.pokemon:
			action = _expert_switch(battle, party, active, foe.active.pokemon)
			if action != null:
				switched_against = foe.active.pokemon
		if action == null and expert:
			action = _strongest_move(battle, active, foe.active.pokemon)
		if action == null:
			action = ai.choose(player, foe, rng, _data) if careful \
				else _naive_move(battle, active, rng)
		if action.is_heal():
			bag[action.item_id] = int(bag[action.item_id]) - 1
		var events: Array = battle.submit(action)
		if events.is_empty():
			break
		_trace(events)
	return [battle.get_outcome(), battle.get_turn()]


## `--trace` : les phrases des événements, si l'étape est racontée.
func _trace(events: Array) -> void:
	if not _tracing:
		return
	for event: RefCounted in events:
		var hp := ""
		if event.max_hp > 0 and event.kind in [BATTLE_EVENT_DAMAGE, BATTLE_EVENT_SENT_OUT]:
			hp = " [%d/%d]" % [event.hp, event.max_hp]
		for line: String in _battle_text.lines(event, _data):
			print("      " + line + hp)


## Joueur naïf : une capacité offensive au hasard parmi celles qui ont des PP (sinon n'importe
## laquelle qui en a, sinon Lutte), sans regarder les types.
func _naive_move(battle: RefCounted, active: RefCounted, rng: RefCounted) -> RefCounted:
	var usable: Array[int] = battle.get_usable_moves()
	if usable.is_empty():
		return _action_script.move(-1)
	var attacks: Array[int] = []
	for index: int in usable:
		if _data.get_move(active.moves[index].move_id).is_damaging():
			attacks.append(index)
	var pool := attacks if not attacks.is_empty() else usable
	return _action_script.move(pool[rng.pick_index(pool.size())])


## Joueur expert (T20) : la capacité offensive aux plus forts dégâts attendus contre
## [param target] (jamais de statut), ou null s'il n'en a pas d'utilisable.
func _strongest_move(battle: RefCounted, active: RefCounted, target: RefCounted) -> RefCounted:
	var best := -1
	var best_damage := 0.0
	for index: int in battle.get_usable_moves():
		var damage := _move_damage(active, target, _data.get_move(active.moves[index].move_id))
		if damage > best_damage:
			best = index
			best_damage = damage
	return null if best < 0 else _action_script.move(best)


## Joueur expert, combat de Dresseur : rappel du Pokémon en jeu si un autre (plus de la moitié
## de ses PV) est [constant EXPERT_SWITCH_FACTOR] fois mieux placé contre [param target].
func _expert_switch(battle: RefCounted, party: RefCounted, active: RefCounted,
		target: RefCounted) -> RefCounted:
	var best: RefCounted = _best_against(party, target)
	if best == null or best == active or best.hp * 2 <= best.max_hp():
		return null
	if _placement(best, target) < EXPERT_SWITCH_FACTOR * _placement(active, target):
		return null
	var action: RefCounted = _action_script.switch_to(party.index_of(best))
	return action if battle.is_legal(action) else null


## Joueur attentif : le plus petit soin du Sac qui sauve le Pokémon en jeu du prochain coup le
## plus fort, ou null.
func _heal_action(battle: RefCounted, player: RefCounted, foe: RefCounted,
		bag: Dictionary) -> RefCounted:
	var active: RefCounted = player.active.pokemon
	for id: StringName in _heals(bag):
		if not _needs_heal(active, foe.active.pokemon, _items.get_item(id).heal_amount):
			continue
		var heal: RefCounted = _action_script.heal(id, player.party.index_of(active))
		if battle.is_legal(heal):
			return heal
	return null


## Joueur attentif, hors combat : Antidote (ou tout objet qui soigne le statut) sur un Pokémon
## qui en a un, puis soins jusqu'à plus de [constant HEAL_OUTSIDE_BELOW] des PV.
func _heal_outside(party: RefCounted, bag: Dictionary) -> void:
	for pokemon: RefCounted in party.get_all():
		if pokemon.is_fainted():
			continue
		if not String(pokemon.status).is_empty():
			for id: StringName in bag:
				if int(bag[id]) > 0 and _items.get_item(id).cures.has(pokemon.status):
					pokemon.cure_status()
					bag[id] = int(bag[id]) - 1
					break
		var heals := _heals(bag)
		while not heals.is_empty() and pokemon.hp < pokemon.max_hp() * HEAL_OUTSIDE_BELOW:
			var id: StringName = heals[0]
			pokemon.hp = mini(pokemon.hp + _items.get_item(id).heal_amount, pokemon.max_hp())
			bag[id] = int(bag[id]) - 1
			heals = _heals(bag)


## Objets de soin des PV du Sac encore disponibles, du plus petit au plus grand.
func _heals(bag: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in bag:
		if int(bag[id]) > 0 and _items.get_item(id).heal_amount > 0:
			ids.append(id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		return _items.get_item(a).heal_amount < _items.get_item(b).heal_amount)
	return ids


## Soin utile : le prochain coup le plus fort de [param foe] (tirage maximal, sans raté) peut
## mettre [param active] K.O., et [param amount] PV de plus lui permettraient de le recevoir.
func _needs_heal(active: RefCounted, foe: RefCounted, amount: int) -> bool:
	var danger := _best_damage(foe, active, true)
	return active.hp <= danger and mini(active.hp + amount, active.max_hp()) > danger


## Pokémon debout de [param party] qui a le meilleur rapport « part des PV de [param foe]
## retirée par sa meilleure attaque » / « part de ses PV retirée par la meilleure attaque de
## [param foe] » (comme `simulate_brock.gd`).
func _best_against(party: RefCounted, foe: RefCounted) -> RefCounted:
	var best: RefCounted = null
	var best_score := -1.0
	for pokemon: RefCounted in party.get_all():
		if pokemon.is_fainted():
			continue
		var score := _placement(pokemon, foe)
		if score > best_score:
			best = pokemon
			best_score = score
	return best


## Rapport (part des PV de [param foe] ôtée par coup) / (part des PV de [param pokemon] ôtée
## par coup) : plus il est haut, mieux [param pokemon] est placé.
func _placement(pokemon: RefCounted, foe: RefCounted) -> float:
	var dealt := _best_damage(pokemon, foe) / float(foe.max_hp())
	var taken := maxf(_best_damage(foe, pokemon) / float(pokemon.max_hp()), 0.01)
	return dealt / taken


## Dégâts moyens (ou maximaux si [param worst]) de la meilleure attaque de [param attacker]
## sur [param defender], sans critique ; précision comprise sauf si [param worst].
func _best_damage(attacker: RefCounted, defender: RefCounted, worst: bool = false) -> float:
	var best := 0.0
	for slot: RefCounted in attacker.moves:
		best = maxf(best, _move_damage(attacker, defender, _data.get_move(slot.move_id), worst))
	return best


## Dégâts moyens (ou maximaux si [param worst]) de [param move] ; 0 pour une capacité de statut.
func _move_damage(attacker: RefCounted, defender: RefCounted, move: RefCounted,
		worst: bool = false) -> float:
	if move == null or not move.is_damaging():
		return 0.0
	var physical: bool = move.category == 0
	var attack: int = attacker.stats[&"atk" if physical else &"spa"]
	var defense: int = defender.stats[&"def" if physical else &"spd"]
	var damage := float((2 * attacker.level / 5 + 2) * move.power * attack
		/ maxi(defense, 1) / 50 + 2) * (1.0 if worst else 0.925)
	if not move.typeless and _data.get_species(attacker.species_id).types.has(move.type):
		damage *= 1.5
	damage *= _chart.multiplier(&"" if move.typeless else move.type,
		_data.get_species(defender.species_id).types)
	if not worst and not move.never_misses():
		damage *= move.accuracy / 100.0
	return damage


# --- Équipes ------------------------------------------------------------------------------

## Équipe de départ : membres du scénario ([PokemonFactory], IV tirés sauf « ivs », capacités
## de Rouge/Bleu au niveau sauf « moves ») ou de la sauvegarde ([method Pokemon.from_dict]).
func _build_team(team: Dictionary, rng: RefCounted) -> RefCounted:
	var party: RefCounted = _party_script.new()
	for member: Dictionary in team["members"]:
		if team["save"]:
			party.add(_pokemon_script.from_dict(member, _data))
			continue
		var pokemon: RefCounted = _factory.create(_data, StringName(member["species"]),
			int(member["level"]), rng)
		if member.has("ivs"):
			for i: int in STAT_KEYS.size():
				pokemon.ivs[StringName(STAT_KEYS[i])] = int(member["ivs"][i])
			pokemon.recalc(_data)
		if member.has("moves"):
			pokemon.moves.clear()
			for move_id: Variant in member["moves"]:
				pokemon.learn_move(StringName(str(move_id)), _data)
		pokemon.hp = pokemon.max_hp()
		party.add(pokemon)
	return party


func _start_bag(variant: Dictionary) -> Dictionary:
	var bag: Dictionary = {}
	for id: StringName in variant["items"]:
		var count: Variant = variant["items"][id]
		bag[id] = int(_save_bag.get(id, 0)) if count is String else int(count)
	return bag


## Évolutions de fin de combat (une par Pokémon debout), capacités apprises si un emplacement
## est libre.
func _evolve(party: RefCounted) -> void:
	for pokemon: RefCounted in party.get_all():
		if pokemon.is_fainted():
			continue
		var into: StringName = _evolution_script.level_up_target(pokemon, _data)
		if into.is_empty():
			continue
		for move_id: StringName in _evolution_script.evolve(pokemon, into, _data):
			pokemon.learn_move(move_id, _data)


func _put_first(party: RefCounted, pokemon: RefCounted) -> void:
	var key: int = party.get_instance_id()
	if not _orders.has(key):
		_orders[key] = party.get_all().duplicate()
	party.move(party.index_of(pokemon), 0)


func _restore_order(party: RefCounted) -> void:
	var key: int = party.get_instance_id()
	if not _orders.has(key):
		return
	var order: Array = _orders[key]
	for target: int in order.size():
		party.move(party.index_of(order[target]), target)
	_orders.erase(key)


func _fainted(party: RefCounted) -> int:
	var count := 0
	for pokemon: RefCounted in party.get_all():
		count += 1 if pokemon.is_fainted() else 0
	return count


## Part des PV de l'équipe (somme des PV / somme des PV max).
func _hp_share(party: RefCounted) -> float:
	var hp := 0
	var total := 0
	for pokemon: RefCounted in party.get_all():
		hp += pokemon.hp
		total += pokemon.max_hp()
	return float(hp) / maxi(total, 1)


## Niveau le plus haut de l'équipe (T20 : niveau d'arrivée du meneur avant une étape).
func _top_level(party: RefCounted) -> int:
	var top := 0
	for pokemon: RefCounted in party.get_all():
		top = maxi(top, pokemon.level)
	return top


func _mean_level(party: RefCounted) -> float:
	var sum := 0
	for pokemon: RefCounted in party.get_all():
		sum += pokemon.level
	return float(sum) / maxi(party.size(), 1)


# --- Fin et textes ------------------------------------------------------------------------

func _finish() -> int:
	print("")
	if _skipped == 0:
		print("=== Terminé : rien n'a été sauté (code %d) ===" % EXIT_OK)
		return EXIT_OK
	print("=== Terminé : %d élément(s) SAUTÉ(S) (code %d) ===" % [_skipped, EXIT_SKIPPED])
	for line: Array in [["espèces absentes", _missing_species],
			["capacités absentes", _missing_moves], ["objets absents", _missing_items]]:
		if not (line[1] as Dictionary).is_empty():
			var ids := PackedStringArray((line[1] as Dictionary).keys())
			ids.sort()
			print("  %s des données : %s" % [line[0], ", ".join(ids)])
	return EXIT_SKIPPED


## Vérifie une espèce ; faux (et notée absente) si elle manque aux données.
func _check_species(value: Variant, where: String, missing: Dictionary) -> bool:
	if not value is String or (value as String).is_empty():
		_error("%s : « species » doit être un identifiant" % where)
		return false
	if _data.has_species(StringName(value)):
		return true
	if not (missing["species"] as Array).has(value):
		missing["species"].append(value)
	_missing_species[value] = true
	return false


func _check_move(value: Variant, where: String, missing: Dictionary) -> void:
	if not value is String or (value as String).is_empty():
		_error("%s : une capacité doit être un identifiant" % where)
		return
	if _data.has_move(StringName(value)):
		return
	if not (missing["moves"] as Array).has(value):
		missing["moves"].append(value)
	_missing_moves[value] = true


func _missing_text(missing: Dictionary) -> String:
	var parts := PackedStringArray()
	if not (missing["species"] as Array).is_empty():
		parts.append("espèces absentes des données : " + ", ".join(
			PackedStringArray(missing["species"])))
	if not (missing["moves"] as Array).is_empty():
		parts.append("capacités absentes des données : " + ", ".join(
			PackedStringArray(missing["moves"])))
	return " ; ".join(parts)


func _check_keys(entry: Dictionary, allowed: Array[String], where: String) -> void:
	for key: Variant in entry:
		if not allowed.has(str(key)):
			_error("%s : clé inconnue « %s »" % [where, key])


func _text(entry: Dictionary, key: String, where: String) -> String:
	var value: Variant = entry.get(key)
	if not value is String or (value as String).strip_edges().is_empty():
		_error("%s : « %s » doit être un texte non vide" % [where, key])
		return "?"
	return value


func _error(message: String) -> void:
	_errors.append(message)


static func _is_int(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == floorf(float(value))


func _name(species: StringName) -> String:
	return _data.get_species(species).name


func _party_text(party: RefCounted) -> String:
	var parts := PackedStringArray()
	for pokemon: RefCounted in party.get_all():
		var moves := PackedStringArray()
		for slot: RefCounted in pokemon.moves:
			moves.append(_data.get_move(slot.move_id).name)
		parts.append("%s N%d (%s)" % [_name(pokemon.species_id), pokemon.level,
			", ".join(moves)])
	return ", ".join(parts)


func _trainer_text(library: RefCounted, id: StringName) -> String:
	var trainer: RefCounted = library.get_trainer(id)
	var prize := "%d ₽" % trainer.prize_money if trainer.prize_per_level == 0 \
		else "%d ₽ × niveau" % trainer.prize_per_level
	var head := "%s, IA %s%s, %s" % [trainer.name, trainer.ai,
		" qui change" if trainer.can_switch else "", prize]
	if trainer.team_by_starter.is_empty():
		return "%s : %s" % [head, _party_text(library.build_team(id, &"", _rng_script.new(0)))]
	var parts := PackedStringArray()
	for starter: StringName in trainer.team_by_starter:
		parts.append("contre %s : %s" % [_name(starter),
			_party_text(library.build_team(id, starter, _rng_script.new(0)))])
	return "%s ; %s" % [head, " ; ".join(parts)]


func _items_text(items: Dictionary) -> String:
	if items.is_empty():
		return "aucun"
	var parts := PackedStringArray()
	for id: StringName in items:
		parts.append("%s × %s" % [_items.get_item(id).name, str(items[id])])
	return ", ".join(parts)


## Objets consommés en moyenne sur [param runs] parties.
func _used_text(used: Dictionary, runs: int) -> String:
	var parts := PackedStringArray()
	for id: StringName in used:
		if int(used[id]) > 0:
			parts.append("%s %.2f" % [_items.get_item(id).name, float(used[id]) / runs])
	return "aucun" if parts.is_empty() else ", ".join(parts)
