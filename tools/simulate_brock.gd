extends SceneTree
## Équilibrage de Pierre (jalon 10 T16, dossier 12 arbitrages 1 à 3 et §11). Information pour
## Kevin, pas un seuil.
##
## Tout passe par le vrai moteur ([Battle], règles de Dresseur, XP ×1,5 et niveaux gagnés en
## combat), la vraie IA ([BattleAI] : Pierre `smart`, Liam `random`), les vraies données
## (`data/trainers/pewter_gym.json`, espèces, capacités, table `route_2_north`, Potion) et
## [GameRng] : une graine = une partie (IV des adversaires et des Pokémon types, tirages du
## combat). 1 000 graines par ligne (0..999).
##
## Une partie : (1) équipe de départ ; (2) facultatif, la traversée de la Route 2 nord :
## [constant ROUTE_ENCOUNTERS] combats sauvages tirés dans la vraie table, menés par le starter
## (PV gardés d'un combat à l'autre, évolution en fin de combat gagné comme en jeu) ;
## (3) facultatif, Campeur Liam (évitable) ; soin au Centre ; (4) Pierre.
##
## Joueurs : « naïf » (ordre de l'équipe, une capacité offensive au hasard sans regarder les
## types, remplaçant = le suivant, jamais de Potion) et « attentif » (en tête le Pokémon qui
## a le meilleur rapport dégâts infligés / dégâts reçus contre le premier adversaire, capacités
## choisies par la même IA `smart` que Pierre, remplaçant choisi de la même façon, Potion au
## Pokémon en jeu sous ⅓ de ses PV tant qu'il en reste). Aucun changement volontaire.
##
## Équipes : (a) la vraie équipe de Kevin à la fin du J9 (sauvegarde de la QA T22 :
## `build/qa/jalon09_t22/save_fin_qa.json` de la copie du J9, non versionnée ; IV, XP,
## capacités et ordre recopiés dans [constant KEVIN_PARTY]), telle quelle puis avec un
## Salamèche entraîné ; (b) les équipes types de chaque starter (N11 à la sortie du poste nord,
## comme le départ `route_2_north`), avec Roucool, avec Papilusion (Choc Mental) ou Férosinge ;
## (c) avec ou sans Potions. Puis Pierre à d'autres niveaux (proposition).
##
##   godot --headless --path . -s res://tools/simulate_brock.gd
##   godot --headless --path . -s res://tools/simulate_brock.gd -- --seeds 200
##   godot --headless --path . -s res://tools/simulate_brock.gd -- --save <sauvegarde.json>
##   godot --headless --path . -s res://tools/simulate_brock.gd -- --grille 2
##
## `--grille <n>` : seulement la grille de la variante n de [constant BROCK_VARIANTS]
## (2 = Jet-Pierres sur Racaillou). `--save` remplace l'équipe de Kevin par l'équipe d'une
## sauvegarde (clé « party »).

@warning_ignore_start("integer_division")

const DEFAULT_SEEDS: int = 1000
const MAX_TURNS: int = 200
## Battle.State, Battle.Outcome (les classes du jeu sont chargées par load()).
const CHOOSING: int = 1
const OVER: int = 2
const REPLACING: int = 3
const WIN: int = 1
const LOSS: int = 2
const BROCK: StringName = &"pewter_gym_brock"
const LIAM: StringName = &"pewter_gym_liam"
const POTION: StringName = &"potion"
## PV rendus par une Potion (données : `heal_amount`), pour le choix du joueur attentif.
const POTION_HP: int = 20
## Combats sauvages pendant la traversée de la Route 2 nord (défaut : deux petites zones
## d'herbes, taux 25, rampe 15 → 20 ; un joueur qui passe par les herbes sans s'y attarder).
const ROUTE_ENCOUNTERS: int = 3
## Potions de Kevin avant Pierre : 1 dans le Sac + 4 achetées à Argenta (1 396 ₽, 300 ₽ pièce).
const KEVIN_POTIONS: int = 5
## Potions des équipes types (comme les départs `route_2_north` / `pewter_gym`).
const TYPE_POTIONS: int = 3
## Niveaux de Pierre (données) et de Liam : [Racaillou, Onix], [Racaillou, Sabelette].
const BROCK_LEVELS: Array[Vector2i] = [Vector2i(12, 14)]
const LIAM_LEVELS: Array[Vector2i] = [Vector2i(10, 10)]
## Grille de la proposition : [Racaillou, Onix].
const BROCK_GRID: Array[Vector2i] = [
	Vector2i(12, 14), Vector2i(12, 13), Vector2i(12, 12), Vector2i(11, 13), Vector2i(11, 12),
	Vector2i(10, 12), Vector2i(10, 11), Vector2i(10, 10),
]
## Capacités de Pierre essayées dans la grille : [nom, capacités de Racaillou, capacités
## d'Onix (vide = les données), niveaux (vide = [constant BROCK_GRID])]. Seule la première
## est dans les données ; les autres sont une information pour Kevin (arbitrage 1, Q-6).
const BROCK_VARIANTS: Array = [
	["Onix des données (Charge, Grincement, Armure, Jet-Pierres)", [], [], []],
	["Onix sans Jet-Pierres (Charge, Grincement, Armure)", [],
		["tackle", "screech", "harden"], []],
	["Jet-Pierres sur Racaillou (Charge, Boul'Armure, Jet-Pierres) ; Onix (Charge, "
		+ "Grincement, Armure)", ["tackle", "defense_curl", "rock_throw"],
		["tackle", "screech", "harden"], [Vector2i(12, 14), Vector2i(11, 14)]],
]
## Équipe de Kevin, fin du J9 (sauvegarde de la QA T22), dans l'ordre de l'équipe.
const KEVIN_PARTY: Array[Dictionary] = [
	{ "species": "caterpie", "level": 6, "exp": 293, "gender": "female",
		"ivs": [16, 10, 17, 8, 19, 21], "moves": ["tackle", "string_shot"] },
	{ "species": "pidgey", "level": 9, "exp": 556, "gender": "male",
		"ivs": [23, 28, 19, 30, 18, 7], "moves": ["gust", "sand_attack"] },
	{ "species": "rattata", "level": 3, "exp": 62, "gender": "female",
		"ivs": [18, 24, 29, 27, 7, 7], "moves": ["tackle", "tail_whip"] },
	{ "species": "nidoran_m", "level": 3, "exp": 81, "gender": "male",
		"ivs": [30, 16, 3, 10, 30, 18], "moves": ["leer", "tackle"] },
	{ "species": "charmander", "level": 10, "exp": 652, "gender": "male",
		"ivs": [16, 1, 13, 1, 1, 27], "moves": ["scratch", "growl", "ember"] },
	{ "species": "caterpie", "level": 5, "exp": 125, "gender": "female",
		"ivs": [12, 11, 24, 17, 15, 24], "moves": ["tackle", "string_shot"] },
]
## Ordre des IV dans [constant KEVIN_PARTY] (= SpeciesData.STATS).
const STAT_KEYS: Array[String] = ["hp", "atk", "def", "spa", "spd", "spe"]
## Équipes types (b) : [nom, [[espèce, niveau, capacités (vide = Rouge/Bleu)], …]] ; le starter
## est ajouté en tête au niveau [constant TYPE_STARTER_LEVEL].
const TYPE_STARTER_LEVEL: int = 11
const TYPE_TEAMS: Array = [
	["seul", []],
	["+ Roucool 10", [["pidgey", 10, []]]],
	["+ Papilusion 10, Roucool 10", [["butterfree", 10,
		["tackle", "string_shot", "harden", "confusion"]], ["pidgey", 10, []]]],
	["+ Férosinge 7, Roucool 10", [["mankey", 7, []], ["pidgey", 10, []]]],
]
## Événements gardés par `--trace` (en plus des capacités et des dégâts).
const TRACED: Array[String] = ["STAT_CHANGED", "STAT_UNCHANGED", "MOVE_MISSED", "FAINTED",
	"SENT_OUT", "ITEM_USED", "LEVEL_UP", "MOVE_LEARNED", "BATTLE_ENDED"]
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]
## Starters et leurs évolutions (un Salamèche entraîné devient Reptincel au N16).
const STARTER_LINES: Array[StringName] = [&"bulbasaur", &"ivysaur", &"charmander",
	&"charmeleon", &"squirtle", &"wartortle"]

var _seeds: int = DEFAULT_SEEDS
var _data: RefCounted
var _trainers: RefCounted
var _items: RefCounted
var _table: RefCounted
var _chart: RefCounted
var _kevin: Array[Dictionary] = []
var _factory: GDScript
var _party_script: GDScript
var _pokemon_script: GDScript
var _side_script: GDScript
var _battle_script: GDScript
var _rules_script: GDScript
var _action_script: GDScript
var _ai_script: GDScript
var _rng_script: GDScript
var _curve_script: GDScript
var _evolution_script: GDScript
## Ordre d'origine des équipes réordonnées ([method _put_first]), par identifiant d'instance.
var _orders: Dictionary = {}
## `--trace <texte>` : journal du combat contre Pierre des deux premières graines des lignes
## dont le nom contient ce texte.
var _trace: String = ""
var _tracing: bool = false
## Capacités de Racaillou et d'Onix imposées (grille, [constant BROCK_VARIANTS]) ; vide = les
## données.
var _geodude_moves: Array[StringName] = []
var _onix_moves: Array[StringName] = []
## `--grille <n>` : seulement la grille de la variante n (0 = les données) ; −1 = tout.
var _only_variant: int = -1


func _init() -> void:
	if not _load():
		quit(1)
		return
	print("=== Équilibrage de Pierre (jalon 10 T16) : %d graines par ligne ===" % _seeds)
	print("Pierre (données) : %s ; Liam : %s" % [_team_text(BROCK), _team_text(LIAM)])
	if _only_variant < 0:
		_report_kevin()
		_report_types()
	_report_levels()
	if _only_variant < 0:
		_report_liam()
	quit()


# --- Rapports ----------------------------------------------------------------------------

## (a) et (c) : la vraie équipe de Kevin.
func _report_kevin() -> void:
	print("")
	print("=== (a) Équipe réelle de Kevin (fin du J9) : %s ===" % _party_text(_kevin_party()))
	var brock := BROCK_LEVELS[0]
	var liam := LIAM_LEVELS[0]
	_line("telle quelle, naïf, sans Potion", _kevin_builder(0), brock, liam, false, false,
		"naif", 0)
	_line("telle quelle, attentif, 1 Potion (son Sac)", _kevin_builder(0), brock, liam, false,
		false, "attentif", 1)
	_line("telle quelle, attentif, %d Potions" % KEVIN_POTIONS, _kevin_builder(0), brock, liam,
		false, false, "attentif", KEVIN_POTIONS)
	_line("route + Liam, naïf, sans Potion", _kevin_builder(0), brock, liam, true, true,
		"naif", 0)
	_line("route + Liam, attentif, sans Potion", _kevin_builder(0), brock, liam, true, true,
		"attentif", 0)
	_line("route + Liam, attentif, %d Potions" % KEVIN_POTIONS, _kevin_builder(0), brock, liam,
		true, true, "attentif", KEVIN_POTIONS)
	print("--- Entraînement de Salamèche (le reste tel quel), attentif, %d Potions, sans Liam"
		% KEVIN_POTIONS)
	for level: int in [12, 13, 14, 15, 16, 17, 18]:
		_line("Salamèche N%d" % level, _kevin_builder(level), brock, liam, false, false,
			"attentif", KEVIN_POTIONS)


## (b) et (c) : les équipes types de chaque starter.
func _report_types() -> void:
	var brock := BROCK_LEVELS[0]
	var liam := LIAM_LEVELS[0]
	for potions: int in [0, TYPE_POTIONS]:
		print("")
		print(("=== (b) Équipes types : starter N%d à la sortie du poste nord, route + Liam, "
			+ "attentif, %d Potion(s) ===") % [TYPE_STARTER_LEVEL, potions])
		for starter: StringName in STARTERS:
			for team: Array in TYPE_TEAMS:
				_line("%s %s" % [_name(starter), team[0]], _type_builder(starter, team[1]),
					brock, liam, true, true, "attentif", potions)
	print("")
	print("=== (b) Équipes types, joueur naïf (le starter pour tout), route + Liam, "
		+ "sans Potion ===")
	for starter: StringName in STARTERS:
		_line("%s + Roucool 10" % _name(starter), _type_builder(starter, TYPE_TEAMS[1][1]),
			brock, liam, true, true, "naif", 0)


## Proposition : Pierre (et Liam) à d'autres niveaux, sur les lignes qui décident.
func _report_levels() -> void:
	var liam := LIAM_LEVELS[0]
	var columns: Array = [
		["Kev.0P", _kevin_builder(0), true, 0],
		["Kev.1P", _kevin_builder(0), true, 1],
		["Kev.3P", _kevin_builder(0), true, 3],
		["Kev.5P", _kevin_builder(0), true, KEVIN_POTIONS],
		["K.N14 5P", _kevin_builder(14), false, KEVIN_POTIONS],
		["SR 3P", _type_builder(&"charmander", TYPE_TEAMS[1][1]), true, TYPE_POTIONS],
		["SPR 3P", _type_builder(&"charmander", TYPE_TEAMS[2][1]), true, TYPE_POTIONS],
		["BR 0P", _type_builder(&"bulbasaur", TYPE_TEAMS[1][1]), true, 0],
		["BR 3P", _type_builder(&"bulbasaur", TYPE_TEAMS[1][1]), true, TYPE_POTIONS],
		["CR 0P", _type_builder(&"squirtle", TYPE_TEAMS[1][1]), true, 0],
	]
	print("")
	print("Colonnes : Kev. = Kevin à l'arrivée (route + Liam), K.N14 = Kevin avec Salamèche N14")
	print("(sans Liam) ; SR / SPR / BR / CR = Salamèche + Roucool, Salamèche + Papilusion +")
	print("Roucool, Bulbizarre + Roucool, Carapuce + Roucool (starter N11, route + Liam) ;")
	print("nP = n Potions ; joueur attentif.")
	for index: int in BROCK_VARIANTS.size():
		if _only_variant >= 0 and index != _only_variant:
			continue
		var variant: Array = BROCK_VARIANTS[index]
		_geodude_moves.assign(variant[1])
		_onix_moves.assign(variant[2])
		var levels: Array[Vector2i] = BROCK_GRID
		if not (variant[3] as Array).is_empty():
			levels.assign(variant[3])
		print("")
		print("=== Grille : %% de victoires contre Pierre ; %s ===" % variant[0])
		var header := "  %-9s" % "Rac./Onix"
		for column: Array in columns:
			header += " | %8s" % column[0]
		print(header)
		for brock: Vector2i in levels:
			var row := "  %-9s" % ("%d / %d" % [brock.x, brock.y])
			for column: Array in columns:
				var stats := _measure(column[1], brock, liam, column[2], column[2], "attentif",
					column[3], column[0])
				row += " | %7.1f%%" % stats["win"]
			print(row)
	_geodude_moves.clear()
	_onix_moves.clear()


## Liam seul (évitable) : équipes après la route, avec ou sans Potions, à deux niveaux.
func _report_liam() -> void:
	print("")
	print("=== Campeur Liam (évitable, IA random) : % de victoires après la route, "
		+ "joueur attentif ===")
	var teams: Array = [
		["Kevin", _kevin_builder(0)],
		["Bulbizarre + Roucool", _type_builder(&"bulbasaur", TYPE_TEAMS[1][1])],
		["Salamèche + Roucool", _type_builder(&"charmander", TYPE_TEAMS[1][1])],
		["Carapuce + Roucool", _type_builder(&"squirtle", TYPE_TEAMS[1][1])],
		["Bulbizarre seul", _type_builder(&"bulbasaur", [])],
	]
	for liam: Vector2i in [Vector2i(10, 10), Vector2i(9, 9)]:
		for potions: int in [0, TYPE_POTIONS]:
			var row := "  Racaillou %d, Sabelette %d, %d Potion(s) :" % [liam.x, liam.y, potions]
			for team: Array in teams:
				var wins := 0
				for seed_value: int in _seeds:
					var rng: RefCounted = _rng_script.new(seed_value)
					var party: RefCounted = (team[1] as Callable).call(rng)
					_walk_route(party, _starter_of(party), rng)
					party.heal_all()
					if _trainer_battle(party, LIAM, liam, rng, "attentif", potions)[0] == WIN:
						wins += 1
				row += "  %s %.1f %%" % [team[0], 100.0 * wins / _seeds]
			print(row)


## Une ligne du rapport : taux de victoire contre Pierre (et Liam), tours, Potions utilisées,
## niveau du starter devant Pierre ([method _measure]).
func _line(label: String, builder: Callable, brock: Vector2i, liam: Vector2i, route: bool,
		fight_liam: bool, policy: String, potions: int) -> void:
	var stats := _measure(builder, brock, liam, route, fight_liam, policy, potions, label)
	var text := "  %-52s Pierre %5.1f %%  %4.1f tours  %3.1f Potion(s)  starter N%.1f" % [
		label, stats["win"], stats["turns"], stats["potions"], stats["level"]]
	if fight_liam:
		text += "  | Liam %5.1f %%" % stats["liam"]
	if stats["unfinished"] > 0:
		text += "  (%d non terminés)" % stats["unfinished"]
	print(text)


## [member _seeds] parties ; moyennes en pourcentages (victoires) ou par partie.
func _measure(builder: Callable, brock: Vector2i, liam: Vector2i, route: bool,
		fight_liam: bool, policy: String, potions: int, label: String = "") -> Dictionary:
	var wins := 0
	var liam_wins := 0
	var turns := 0
	var used := 0
	var levels := 0
	var unfinished := 0
	for seed_value: int in _seeds:
		_tracing = not _trace.is_empty() and label.contains(_trace) and seed_value < 2
		var result := _play(builder, seed_value, brock, liam, route, fight_liam, policy,
			potions)
		wins += 1 if result["outcome"] == WIN else 0
		unfinished += 1 if result["outcome"] == 0 else 0
		liam_wins += 1 if result["liam"] == WIN else 0
		turns += int(result["turns"])
		used += int(result["potions_used"])
		levels += int(result["starter_level"])
	return {
		"win": 100.0 * wins / _seeds, "liam": 100.0 * liam_wins / _seeds,
		"turns": float(turns) / _seeds, "potions": float(used) / _seeds,
		"level": float(levels) / _seeds, "unfinished": unfinished,
	}


# --- Une partie -------------------------------------------------------------------------

func _play(builder: Callable, seed_value: int, brock: Vector2i, liam: Vector2i, route: bool,
		fight_liam: bool, policy: String, potions: int) -> Dictionary:
	var rng: RefCounted = _rng_script.new(seed_value)
	var party: RefCounted = builder.call(rng)
	var starter: RefCounted = _starter_of(party)
	if route:
		_walk_route(party, starter, rng)
	var liam_outcome := 0
	if fight_liam:
		var liam_battle := _trainer_battle(party, LIAM, liam, rng, policy, 0)
		liam_outcome = liam_battle[0]
		_evolve(party)
	party.heal_all()
	var starter_level: int = starter.level
	var result := _trainer_battle(party, BROCK, brock, rng, policy, potions)
	return {
		"outcome": result[0], "turns": result[1], "potions_used": result[2],
		"liam": liam_outcome, "starter_level": starter_level,
	}


## Traversée de la Route 2 nord : [constant ROUTE_ENCOUNTERS] combats sauvages menés par
## [param lead] (capacités `smart`), PV gardés ; K.O. = soin (borne simple, le joueur repasse
## au Centre). Évolutions en fin de combat gagné.
func _walk_route(party: RefCounted, lead: RefCounted, rng: RefCounted) -> void:
	for i: int in ROUTE_ENCOUNTERS:
		var encounter: RefCounted = _table.pick(rng)
		var foes: RefCounted = _party_script.new()
		foes.add(_factory.create(_data, encounter.species, encounter.level, rng))
		_put_first(party, lead)
		var player: RefCounted = _side_script.new(party, true)
		var foe: RefCounted = _side_script.new(foes, false, "")
		var battle: RefCounted = _battle_script.new(player, foe, _data, rng,
			_rules_script.for_wild(_items))
		battle.start()
		var ai: RefCounted = _ai_script.new(&"smart")
		while battle.get_state() == CHOOSING and battle.get_turn() < MAX_TURNS:
			if battle.submit(ai.choose(player, foe, rng, _data)).is_empty():
				break
			if battle.get_state() == REPLACING:
				break
		if battle.get_outcome() == WIN:
			_evolve(party)
		if battle.get_state() != CHOOSING or lead.is_fainted():
			party.heal_all()
	_restore_order(party)


## Combat contre le Dresseur [param trainer_id] (niveaux [param levels]) ; renvoie
## [issue, tours, Potions utilisées]. L'équipe du joueur garde l'XP gagnée.
func _trainer_battle(party: RefCounted, trainer_id: StringName, levels: Vector2i,
		rng: RefCounted, policy: String, potions: int) -> Array[int]:
	var trainer: RefCounted = _trainers.get_trainer(trainer_id)
	var foes: RefCounted = _trainers.build_team(trainer_id, &"", rng)
	for i: int in foes.size():
		_set_level(foes.get_at(i), levels.x if i == 0 else levels.y)
	if trainer_id == BROCK:
		_force_moves(foes.get_at(0), _geodude_moves)
		_force_moves(foes.get_at(foes.size() - 1), _onix_moves)
	if policy == "attentif":
		_put_first(party, _best_against(party, foes.get_at(0)))
	var player: RefCounted = _side_script.new(party, true)
	var foe: RefCounted = _side_script.new(foes, false, trainer.name,
		_ai_script.new(trainer.ai))
	var battle: RefCounted = _battle_script.new(player, foe, _data, rng,
		_rules_script.for_trainer(trainer, _items))
	battle.start()
	var player_ai: RefCounted = _ai_script.new(&"smart")
	var left := potions
	while battle.get_state() != OVER and battle.get_turn() < MAX_TURNS:
		if battle.get_state() == REPLACING:
			var next: RefCounted = _best_against(party, foe.active.pokemon) \
				if policy == "attentif" else party.first_able()
			battle.replace(party.index_of(next))
			continue
		var action: RefCounted = _choose(battle, player, foe, player_ai, rng, policy, left)
		if action.kind == 2:
			left -= 1
		var events: Array = battle.submit(action)
		if events.is_empty():
			break
		if _tracing and trainer_id == BROCK:
			_print_events(events)
	_restore_order(party)
	return [battle.get_outcome(), battle.get_turn(), potions - left]


func _choose(battle: RefCounted, player: RefCounted, foe: RefCounted, ai: RefCounted,
		rng: RefCounted, policy: String, potions: int) -> RefCounted:
	var active: RefCounted = player.active.pokemon
	if policy == "attentif" and potions > 0 and _needs_potion(active, foe.active.pokemon):
		var heal: RefCounted = _action_script.heal(POTION, player.party.index_of(active))
		if battle.is_legal(heal):
			return heal
	if policy == "attentif":
		return ai.choose(player, foe, rng, _data)
	# Naïf : une capacité offensive au hasard parmi celles qui ont des PP, sans regarder les
	# types (sinon n'importe quelle capacité qui a des PP, sinon Lutte).
	var usable: Array[int] = battle.get_usable_moves()
	if usable.is_empty():
		return _action_script.move(-1)
	var attacks: Array[int] = []
	for index: int in usable:
		if _data.get_move(active.moves[index].move_id).is_damaging():
			attacks.append(index)
	var pool := attacks if not attacks.is_empty() else usable
	return _action_script.move(pool[rng.pick_index(pool.size())])


# --- Choix du joueur attentif ------------------------------------------------------------

## Pokémon debout de [param party] qui a le meilleur rapport « part des PV de [param foe]
## retirée par sa meilleure attaque » / « part de ses PV retirée par la meilleure attaque de
## [param foe] » (dégâts moyens, précision comprise, sans critique).
func _best_against(party: RefCounted, foe: RefCounted) -> RefCounted:
	var best: RefCounted = null
	var best_score := -1.0
	for pokemon: RefCounted in party.get_all():
		if pokemon.is_fainted():
			continue
		var dealt := _best_damage(pokemon, foe) / float(foe.max_hp())
		var taken := maxf(_best_damage(foe, pokemon) / float(pokemon.max_hp()), 0.01)
		var score := dealt / taken
		if score > best_score:
			best = pokemon
			best_score = score
	return best


## Potion utile : le prochain coup le plus fort de [param foe] (tirage maximal, sans raté) peut
## mettre [param active] K.O., et une Potion (+20 PV) lui permettrait de le recevoir.
func _needs_potion(active: RefCounted, foe: RefCounted) -> bool:
	var danger := _best_damage(foe, active, true)
	return active.hp <= danger and mini(active.hp + POTION_HP, active.max_hp()) > danger


func _best_damage(attacker: RefCounted, defender: RefCounted, worst: bool = false) -> float:
	var best := 0.0
	var attacker_types: Array = _data.get_species(attacker.species_id).types
	var defender_types: Array[StringName] = _data.get_species(defender.species_id).types
	for slot: RefCounted in attacker.moves:
		var move: RefCounted = _data.get_move(slot.move_id)
		if not move.is_damaging():
			continue
		var physical: bool = move.category == 0
		var attack: int = attacker.stats[&"atk" if physical else &"spa"]
		var defense: int = defender.stats[&"def" if physical else &"spd"]
		var damage := float((2 * attacker.level / 5 + 2) * move.power * attack
			/ maxi(defense, 1) / 50 + 2) * (1.0 if worst else 0.925)
		if not move.typeless and attacker_types.has(move.type):
			damage *= 1.5
		damage *= _chart.multiplier(&"" if move.typeless else move.type, defender_types)
		if not worst and not move.never_misses():
			damage *= move.accuracy / 100.0
		best = maxf(best, damage)
	return best


# --- Équipes ------------------------------------------------------------------------------

## Équipe de Kevin ; [param charmander_level] > 0 : Salamèche entraîné jusqu'à ce niveau (XP du
## niveau, capacités de Rouge/Bleu apprises en route si un emplacement est libre).
func _kevin_builder(charmander_level: int) -> Callable:
	return func(_rng: RefCounted) -> RefCounted:
		var party: RefCounted = _kevin_party()
		if charmander_level > 0:
			for pokemon: RefCounted in party.get_all():
				if pokemon.species_id == &"charmander":
					_train_to(pokemon, charmander_level)
		return party


func _kevin_party() -> RefCounted:
	var party: RefCounted = _party_script.new()
	for entry: Dictionary in _kevin:
		party.add(_pokemon_script.from_dict(entry, _data))
	return party


func _type_builder(starter: StringName, members: Array) -> Callable:
	return func(rng: RefCounted) -> RefCounted:
		var party: RefCounted = _party_script.new()
		party.add(_factory.create(_data, starter, TYPE_STARTER_LEVEL, rng))
		for member: Array in members:
			var pokemon: RefCounted = _factory.create(_data, StringName(member[0]), member[1],
				rng)
			if not (member[2] as Array).is_empty():
				pokemon.moves.clear()
				for move_id: String in member[2]:
					pokemon.learn_move(StringName(move_id), _data)
			party.add(pokemon)
		return party


## Le starter de l'équipe (Salamèche chez Kevin, sinon le premier).
func _starter_of(party: RefCounted) -> RefCounted:
	for pokemon: RefCounted in party.get_all():
		if STARTER_LINES.has(pokemon.species_id):
			return pokemon
	return party.get_lead()


func _train_to(pokemon: RefCounted, level: int) -> void:
	var rate: int = _data.get_species(pokemon.species_id).growth_rate
	var needed: int = _curve_script.exp_for_level(rate, level) - pokemon.experience
	if needed <= 0:
		return
	for step: RefCounted in pokemon.gain_exp(needed, _data):
		for move_id: StringName in step.moves:
			pokemon.learn_move(move_id, _data)
	_evolve_one(pokemon)
	pokemon.hp = pokemon.max_hp()


## Remplace les capacités de [param pokemon] par [param moves] (vide : rien ne change).
func _force_moves(pokemon: RefCounted, moves: Array[StringName]) -> void:
	if moves.is_empty():
		return
	pokemon.moves.clear()
	for move_id: StringName in moves:
		pokemon.learn_move(move_id, _data)


## Niveau d'un Pokémon de Dresseur (IV gardés, capacités des données gardées).
func _set_level(pokemon: RefCounted, level: int) -> void:
	var rate: int = _data.get_species(pokemon.species_id).growth_rate
	pokemon.level = level
	pokemon.experience = _curve_script.exp_for_level(rate, level)
	pokemon.recalc(_data)
	pokemon.hp = pokemon.max_hp()


## Évolutions de fin de combat (une par Pokémon), capacités apprises si un emplacement est libre.
func _evolve(party: RefCounted) -> void:
	for pokemon: RefCounted in party.get_all():
		if not pokemon.is_fainted():
			_evolve_one(pokemon)


func _evolve_one(pokemon: RefCounted) -> void:
	var into: StringName = _evolution_script.level_up_target(pokemon, _data)
	if into.is_empty():
		return
	for move_id: StringName in _evolution_script.evolve(pokemon, into, _data):
		pokemon.learn_move(move_id, _data)


## Met [param pokemon] en tête (le joueur réordonne son équipe avant le combat) ; l'ordre
## d'origine est retenu pour [method _restore_order].
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


# --- Chargement -------------------------------------------------------------------------

func _load() -> bool:
	var args := OS.get_cmdline_user_args()
	var save_path := ""
	for i: int in args.size():
		if args[i] == "--seeds" and i + 1 < args.size():
			_seeds = maxi(int(args[i + 1]), 1)
		elif args[i] == "--grille" and i + 1 < args.size():
			_only_variant = int(args[i + 1])
		elif args[i] == "--trace" and i + 1 < args.size():
			_trace = args[i + 1]
		elif args[i] == "--save" and i + 1 < args.size():
			save_path = args[i + 1]
	_data = load("res://game/pokemon/pokemon_data.gd").new()
	if not _data.load_dir():
		push_error("données invalides")
		return false
	_chart = _data.get_type_chart()
	_trainers = load("res://game/battle/trainer_library.gd").new(_data)
	_items = load("res://game/items/item_library.gd").new()
	var encounters: RefCounted = load(
		"res://game/pokemon/encounters/encounter_library.gd").new(_data)
	if not _trainers.load_dir() or not _items.load_dir() or not encounters.load_dir():
		push_error("dresseurs, objets ou rencontres invalides")
		return false
	_table = encounters.get_table(&"route_2_north", &"grass")
	_factory = load("res://game/pokemon/pokemon_factory.gd")
	_party_script = load("res://game/pokemon/party.gd")
	_pokemon_script = load("res://game/pokemon/pokemon.gd")
	_side_script = load("res://game/battle/battle_side.gd")
	_battle_script = load("res://game/battle/battle.gd")
	_rules_script = load("res://game/battle/battle_rules.gd")
	_action_script = load("res://game/battle/battle_action.gd")
	_ai_script = load("res://game/battle/battle_ai.gd")
	_rng_script = load("res://game/systems/random/game_rng.gd")
	_curve_script = load("res://game/pokemon/exp_curve.gd")
	_evolution_script = load("res://game/pokemon/evolution/evolution.gd")
	return _load_kevin(save_path)


## Équipe de Kevin au format de la sauvegarde ([method Pokemon.from_dict]) : celle de
## [constant KEVIN_PARTY], ou la clé « party » de [param save_path].
func _load_kevin(save_path: String) -> bool:
	if not save_path.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if not parsed is Dictionary or not (parsed as Dictionary).get("party") is Array:
			push_error("sauvegarde illisible : %s" % save_path)
			return false
		for entry: Variant in parsed["party"]:
			_kevin.append(entry as Dictionary)
		print("Équipe lue dans %s" % save_path)
		return true
	for member: Dictionary in KEVIN_PARTY:
		var ivs: Dictionary = {}
		var zeros: Dictionary = {}
		for i: int in STAT_KEYS.size():
			ivs[STAT_KEYS[i]] = member["ivs"][i]
			zeros[STAT_KEYS[i]] = 0
		var moves: Array = []
		for move_id: String in member["moves"]:
			var pp: int = _data.get_move(StringName(move_id)).pp
			moves.append({ "id": move_id, "pp": pp, "max_pp": pp })
		_kevin.append({
			"species": member["species"], "level": member["level"], "exp": member["exp"],
			"gender": member["gender"], "hp": 999, "ivs": ivs, "evs": zeros, "moves": moves,
		})
	return true


# --- Textes -------------------------------------------------------------------------------

func _name(species: StringName) -> String:
	return _data.get_species(species).name


func _party_text(party: RefCounted) -> String:
	var parts := PackedStringArray()
	for pokemon: RefCounted in party.get_all():
		parts.append("%s N%d" % [_name(pokemon.species_id), pokemon.level])
	return ", ".join(parts)


func _team_text(trainer_id: StringName) -> String:
	var rng: RefCounted = _rng_script.new(0)
	var parts := PackedStringArray()
	for pokemon: RefCounted in _trainers.build_team(trainer_id, &"", rng).get_all():
		var moves := PackedStringArray()
		for slot: RefCounted in pokemon.moves:
			moves.append(_data.get_move(slot.move_id).name)
		parts.append("%s N%d (%s)" % [_name(pokemon.species_id), pokemon.level,
			", ".join(moves)])
	return " ; ".join(parts)


## Journal compact d'un tour (`--trace`).
func _print_events(events: Array) -> void:
	var kinds: Dictionary = load("res://game/battle/battle_event.gd").Kind
	var parts := PackedStringArray()
	for event: RefCounted in events:
		var kind: String = kinds.find_key(event.kind)
		var who := "%s%s" % ["J:" if event.side == 0 else "P:", event.pokemon_name]
		match kind:
			"MOVE_USED":
				parts.append("%s %s" % [who, _data.get_move(event.move_id).name])
			"DAMAGE":
				parts.append("-%d → %s %d/%d%s" % [event.amount, who, event.hp, event.max_hp,
					" (crit)" if event.critical else ""])
			_:
				if not TRACED.has(kind):
					continue
				parts.append("%s %s%s" % [kind, who, (" " + String(event.stat))
					if kind.begins_with("STAT") else ""])
	print("    " + " | ".join(parts))
