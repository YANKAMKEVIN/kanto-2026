extends "res://tests/helpers/hideout_play.gd"
## Harnais des parcours scriptés (jalon 33, T5 ; `docs/tech/jalon-33.md` §2 T5) : une seule
## partie, sur la vraie scène Boot et une sauvegarde en mémoire, enchaîne les étapes d'un
## parcours. L'état (drapeaux, équipe, Sac, Pokédex, Panthéon) passe d'une étape à l'autre :
## seul le premier pas part d'un départ de débogage (`tools/debug_start/`).
##
## Ce qu'une étape peut faire, en plus de [HideoutPlay] (marche, interaction, combat piloté) :
## - [method jump] : aller à un point d'apparition d'une carte, comme un Vol (le chemin entre
##   deux étapes n'est pas rejoué ; les états accélérés complètent la partie réelle de Kevin,
##   ils ne la remplacent pas) ;
## - [method expect] / [method expect_flags] : contrôles nommés, relevés dans le journal ;
## - [method persist] : sauvegarde écrite, application relancée, partie relue à l'identique.
##
## Journal : une ligne par étape (« ✔ » ou « ✘ »), imprimé à la fin ([method report]) ; les
## contrôles en échec font aussi échouer le test.

const STABLE_TIMEOUT := 20.0
## Champs de [method GameState.to_dict] comparés avant et après une relance.
const KEPT_FIELDS: Array[String] = ["map", "starter", "party", "storage", "bag", "pokedex",
	"flags", "money", "discovered_maps", "daycare", "hall_of_fame", "companion"]

## Aléatoire « toujours 1 » (capture sûre, voir [method catch_with]).
class SureRng extends GameRng:
	func roll(_n: int) -> int:
		return 1


var journey: String
## Combats du parcours, dans l'ordre : { trainer, foe (espèces adverses), outcome }.
var battles: Array[Dictionary] = []
var _lines: Array[String] = []
var _step: String = ""
var _failures: int = 0


func _init(test: GutTest, name: String) -> void:
	super(test, "user://parcours_%s.json" % name)
	journey = name


## Comme [method HideoutPlay.start], combats relevés dans [member battles].
func start(start_path: String, tweak: Callable = Callable(), do_settle: bool = true) -> void:
	await super(start_path, tweak, do_settle)
	_watch_battles()


## Nouvelle partie (sans départ de débogage ni sauvegarde) sur [param map_id] /
## [param spawn] ; [param tweak] (facultatif) pose ce qui précède (prologue) avant le
## rechargement de la carte.
func start_new(map_id: StringName, spawn: StringName, facing: Vector2i,
		tweak: Callable = Callable()) -> void:
	GameState.new_game(7)
	boot = BOOT_SCENE.instantiate() as Boot
	boot.save_system = SaveSystem.new(fs, save_path)
	boot.start_map = map_id
	boot.start_spawn = spawn
	boot.start_facing = facing
	_test.add_child_autofree(boot)
	player = boot.get_player()
	boot.get_dialogue_runner().chars_per_second = 0.0
	GameState.player_name = "Kevin"
	GameState.rival_name = "Régis"
	GameState.rng = GameRng.new(7)
	_quiet_battles()
	if tweak.is_valid():
		tweak.call()
	await _test.wait_process_frames(2)
	await SceneRouter.change_map(map_id, spawn, facing)
	await _test.wait_process_frames(3)
	await wait_stable()
	_quiet_battles()
	_watch_battles()


## Nouveau segment du parcours sur un autre départ de débogage : la partie en cours est fermée
## (l'état du départ remplace le précédent, comme un chargement d'une autre partie).
func restart(start_path: String, tweak: Callable = Callable(), do_settle: bool = true) -> void:
	if is_instance_valid(boot):
		_test.remove_child(boot)
		boot.free()
	await _test.wait_process_frames(2)
	await start(start_path, tweak, do_settle)


## Comme [method HideoutPlay.resume], combats relevés dans [member battles].
func resume(do_settle: bool = true) -> void:
	await super(do_settle)
	_watch_battles()


## Ouvre une étape du journal ; les contrôles qui suivent s'y rattachent.
func begin(label: String) -> void:
	_step = label
	_lines.append("— %s" % label)


## Contrôle nommé : assertion GUT et ligne du journal.
func expect(condition: bool, label: String) -> bool:
	_test.assert_true(condition, "[%s] %s : %s" % [journey, _step, label])
	_lines.append("  %s %s" % ["✔" if condition else "✘", label])
	if not condition:
		_failures += 1
	return condition


## Tous les drapeaux de [param flags] posés.
func expect_flags(flags: Array, label: String) -> bool:
	var missing: Array[String] = []
	for flag: Variant in flags:
		if not GameState.flags.has_flag(StringName(str(flag))):
			missing.append(str(flag))
	return expect(missing.is_empty(), "%s%s" % [label,
		"" if missing.is_empty() else " (manque : %s)" % ", ".join(missing)])


## Aucun des drapeaux de [param flags] posé.
func expect_no_flags(flags: Array, label: String) -> bool:
	var present: Array[String] = []
	for flag: Variant in flags:
		if GameState.flags.has_flag(StringName(str(flag))):
			present.append(str(flag))
	return expect(present.is_empty(), "%s%s" % [label,
		"" if present.is_empty() else " (posés : %s)" % ", ".join(present)])


## Va sur [param map_id] au point [param spawn] (changement de carte réel, sans le chemin).
func jump(map_id: StringName, spawn: StringName, facing: Vector2i = Vector2i.DOWN,
		settle: bool = true) -> void:
	await SceneRouter.change_map(map_id, spawn, facing)
	await _test.wait_process_frames(3)
	if settle:
		await _test.wait_until(func() -> bool: return boot.is_stable(), STABLE_TIMEOUT)


## Marche jusqu'à [param goal] ; un Dresseur qui repère le joueur (ou toute scène qui prend la
## main en chemin) est joué jusqu'au bout ([method HideoutPlay.run_scene]), puis la marche
## reprend. Vrai si le joueur arrive sur [param goal].
func walk_through(goal: Vector2i, attempts: int = 8) -> bool:
	for attempt: int in attempts:
		await walk_to(goal)
		if not boot.is_stable():
			await run_scene()
		if player.get_cell() == goal:
			return true
	return player.get_cell() == goal


## Marche jusqu'à [param cell], se tourne vers [param facing] et interagit (scène, combat
## piloté). Vrai si un combat a eu lieu.
func talk(cell: Vector2i, facing: Vector2i, answer: bool = true) -> bool:
	await walk_through(cell)
	return await interact(facing, answer)


## Marche jusqu'à la case voisine de [param target] (PNJ, objet, machine) la plus proche par
## la vraie grille et renvoie la direction vers [param target] (ZERO si aucune n'est accessible).
func approach(target: Vector2i) -> Vector2i:
	var grid := boot.get_map().get_grid()
	var best := Vector2i.ZERO
	var best_length := -1
	for side: Vector2i in DIRECTIONS:
		var cell := target + side
		if cell == player.get_cell():
			best = side
			best_length = 0
			break
		var path := grid.find_path(player.get_cell(), cell, player)
		if not path.is_empty() and (best_length < 0 or path.size() < best_length):
			best = side
			best_length = path.size()
	_test.assert_true(best_length >= 0, "une case voisine de %s est accessible" % target)
	if best_length < 0:
		return Vector2i.ZERO
	await walk_through(target + best)
	return -best


## [method approach], puis interaction tournée vers [param target]. Vrai si un combat a eu lieu.
func talk_to(target: Vector2i, answer: bool = true) -> bool:
	var facing := await approach(target)
	if facing == Vector2i.ZERO:
		return false
	return await interact(facing, answer)


## Raccourci du parcours : pose [param flags] (ce que le tronçon sauté aurait posé) et le note
## dans le journal avec [param reason]. Le tronçon a ses propres tests ; le parcours réel de
## Kevin (T6) le rejoue au doigt. [param items] : objets reçus dans ce tronçon ({ id: nombre }).
func shortcut(flags: Array, reason: String, items: Dictionary = {}) -> void:
	for flag: Variant in flags:
		GameState.flags.set_flag(StringName(str(flag)))
	for item: Variant in items:
		GameState.bag.add(StringName(str(item)), int(items[item]))
	_lines.append("  ↷ raccourci : %s" % reason)


## Comme [method HideoutPlay.interact], mais le combat sauvage qui suit est une capture : une
## [param ball] lancée au premier tour, puis l'attaque. [param sure] : aléatoire « toujours 1 »
## pendant le combat (la Ball prend à coup sûr, comme dans `test_snorlax_route_12.gd` ; la
## probabilité de capture a ses propres tests). Renvoie l'issue du combat
## ([enum Battle.Outcome], NONE sans combat).
func catch_with(facing: Vector2i, ball: StringName, sure: bool = false) -> int:
	var saved_rng := GameState.rng
	if sure:
		GameState.rng = SureRng.new(0)
	player.face(facing)
	Input.action_press(&"interact")
	await _test.wait_process_frames(2)
	Input.action_release(&"interact")
	var director := boot.get_cutscene_director()
	var runner := boot.get_dialogue_runner()
	var box := boot.get_dialogue_box()
	var battles := boot.get_battle_director()
	var hud := boot.get_battle_hud()
	var outcome: Array[int] = [Battle.Outcome.NONE]
	var on_finished := func(_id: StringName, result: int) -> void: outcome[0] = result
	battles.battle_finished.connect(on_finished)
	var thrown := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	await _test.wait_process_frames(2)
	while (director.is_running() or runner.is_running() or box.is_open()
			or battles.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		var card := battles.get_capture_card()
		if card != null and card.is_waiting():
			card.skip()
		var battle := battles.get_battle() if battles.is_running() else null
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					if thrown:
						hud.action_selected.emit(ActionGrid.ATTACK)
					else:
						thrown = true
						hud.action_selected.emit(ActionGrid.BAG)
						await _test.wait_until(func() -> bool:
							var panel := battles.get_bag_panel()
							return panel != null \
								and not panel.item_chosen.get_connections().is_empty(), 5.0)
						battles.get_bag_panel().item_chosen.emit(ball)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(0)
		await _test.wait_process_frames(1)
		if runner.is_awaiting_choice():
			runner.choose(true)
		elif box.is_choice_showing():
			box.get_choice_cards().get_confirm_button().pressed.emit()
		elif box.is_open():
			box.advance_requested.emit()
	battles.battle_finished.disconnect(on_finished)
	GameState.rng = saved_rng
	await wait_stable()
	return outcome[0]


## Attend que la partie soit stable (fin de scène, de combat ou de transition).
func wait_stable() -> bool:
	await _test.wait_until(func() -> bool: return boot.is_stable(), STABLE_TIMEOUT)
	return boot.is_stable()


## Sauvegarde écrite à l'état stable, application relancée, puis la partie relue doit être la
## même ([constant KEPT_FIELDS]) à la même place. Vrai si tout concorde.
func persist(label: String = "sauvegarde relue à l'identique") -> bool:
	await wait_stable()
	var before := _kept(GameState.to_dict())
	var cell := player.get_cell()
	boot.request_autosave("parcours")
	await _test.wait_until(func() -> bool:
		return str(saved().get("map", "")) == str(before["map"]) \
			and _kept(saved()).hash() == before.hash(), STABLE_TIMEOUT)
	await resume()
	var after := _kept(GameState.to_dict())
	var diff: Array[String] = []
	for field: String in KEPT_FIELDS:
		if str(before.get(field)) != str(after.get(field)):
			diff.append(field)
	var same_cell := player.get_cell() == cell
	if not same_cell:
		diff.append("case %s → %s" % [cell, player.get_cell()])
	return expect(diff.is_empty(), "%s%s" % [label,
		"" if diff.is_empty() else " (diffère : %s)" % ", ".join(diff)])


## Met en tête un Mewtwo N100 (Psyko, 16 PP) à la place du dernier membre si l'équipe est
## pleine : il gagne les combats du parcours sans dépendre du tirage (le parcours vérifie les
## enchaînements, pas l'équilibrage, qui a ses propres tests). Le starter reste dans l'équipe.
func make_ace() -> void:
	var ace := PokemonFactory.create(boot.get_pokemon_data(), &"mewtwo", 100, GameState.rng)
	ace.moves.clear()
	ace.moves.append(MoveSlot.new(&"psychic", 16))
	if GameState.party.size() >= 6:
		GameState.party.remove_at(GameState.party.size() - 1)
	GameState.party.add(ace)
	GameState.party.move(GameState.party.size() - 1, 0)


## Équipe soignée (PV, statut, PP), comme après un passage au Centre ou une Guérison.
func heal() -> void:
	GameState.party.heal_all()


## Espèces de l'équipe, dans l'ordre.
func party_species() -> Array[StringName]:
	var species: Array[StringName] = []
	for pokemon: Pokemon in GameState.party.get_all():
		species.append(pokemon.species_id)
	return species


## Espèces de l'équipe que les données donnent à [param trainer] contre [param starter].
func trainer_species(trainer: StringName, starter: StringName) -> Array[StringName]:
	var species: Array[StringName] = []
	var data := boot.get_trainer_library().get_trainer(trainer)
	if data == null:
		return species
	for slot: TrainerSlot in data.team_for(starter):
		species.append(slot.species)
	return species


## Journal du parcours, imprimé dans la sortie de GUT. Vrai si aucun contrôle n'a échoué.
func report() -> bool:
	_test.gut.p("Parcours %s : %s" % [journey,
		"OK" if _failures == 0 else "%d contrôle(s) en échec" % _failures])
	for line: String in _lines:
		_test.gut.p(line)
	return _failures == 0


## Dernier combat contre [param trainer] (dictionnaire vide s'il n'y en a pas eu).
func last_battle(trainer: StringName) -> Dictionary:
	for index: int in range(battles.size() - 1, -1, -1):
		if battles[index]["trainer"] == trainer:
			return battles[index]
	return {}


## Vrai si le dernier combat contre [param trainer] est gagné.
func won(trainer: StringName) -> bool:
	return last_battle(trainer).get("outcome", -1) == Battle.Outcome.WIN


func _watch_battles() -> void:
	var director := boot.get_battle_director()
	if not director.battle_started.is_connected(_on_parcours_battle_started):
		director.battle_started.connect(_on_parcours_battle_started)
		director.battle_finished.connect(_on_parcours_battle_finished)


func _on_parcours_battle_started(trainer_id: StringName) -> void:
	var entry := {"trainer": trainer_id, "foe": [] as Array[StringName], "outcome": -1}
	battles.append(entry)
	# Le moteur du combat est créé juste après le signal : équipe adverse relevée ensuite.
	var director := boot.get_battle_director()
	for frame: int in 30:
		await _test.get_tree().process_frame
		var battle := director.get_battle() if is_instance_valid(director) else null
		if battle != null:
			for pokemon: Pokemon in battle.get_foe_side().party.get_all():
				(entry["foe"] as Array[StringName]).append(pokemon.species_id)
			return


func _on_parcours_battle_finished(trainer_id: StringName, outcome: int) -> void:
	for index: int in range(battles.size() - 1, -1, -1):
		if battles[index]["trainer"] == trainer_id and battles[index]["outcome"] == -1:
			battles[index]["outcome"] = outcome
			return


func _kept(dict: Dictionary) -> Dictionary:
	var kept := {}
	for field: String in KEPT_FIELDS:
		kept[field] = dict.get(field)
	return kept
