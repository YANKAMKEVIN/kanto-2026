extends GutTest
## Rencontres SPECTRE de bout en bout (jalon 19 T11, `jalon-19.md` §2.2, §2.3 et §5 ; dossier 22
## §6 et §16 n° 4 et 11) avec la vraie scène Boot sur la carte réelle `pokemon_tower_3f`, texte
## et animations de combat instantanés :
## - le SPECTRE n'enregistre rien au Pokédex (ni « vu », ni « pris », ni première espèce
##   sauvage, ni toast), même en tirant de force Osselait et Spectrum, ni par le combat lancé
##   hors rencontre ([method BattleDirector.run_wild], garde de Boot) ;
## - une Ball choisie dans le Sac est refusée par le message du §15.3.5, sans être retirée ni
##   jouer de tour ; avec 0 Ball, rien ne change ;
## - la fuite réussit toujours ; contrôle rendu ; argent et équipe inchangés ;
## - avec `silph_scope` dans le Sac (identifiant brut), la rencontre est normale ; la règle est
##   relue à chaque rencontre ;
## - garde du nom : aucune ligne affichée, aucune carte, aucune image ne nomme l'espèce tirée ;
## - terrain « floor » : jamais sur un escalier, un déclencheur ou une case calme ; 2F : jamais.

const STARTER := &"charmander"
const LEVEL := 20
const PARTY_SEED := 777
const MAP_ID := &"pokemon_tower_3f"
const SPAWN := &"arrivee_T23"
## Case d'arrivée (4, 9), tournée vers l'est ; la case à l'est (5, 9) est du sol.
const FLOOR_STEP := Vector2i(5, 9)
const SCOPE := &"silph_scope"
const BALL := &"poke_ball"
const FADE := 0.05
const TIMEOUT := 12.0
## Espèces tirées de force (dossier 22 §5) et leurs noms, qui ne doivent jamais apparaître.
const FORCED: Array[StringName] = [&"cubone", &"haunter", &"gastly"]

var _boot: Boot
var _player: Player
var _fades: Array[float] = []
## Ce qui a été montré pendant les combats (lignes du bandeau, nom et niveau de la carte
## adverse, image adverse).
var _shown_lines: Array[String] = []
var _shown_cards: Array[String] = []
var _shown_images: Array[String] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_shown_lines.clear()
	_shown_cards.clear()
	_shown_images.clear()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = MAP_ID
	_boot.start_spawn = SPAWN
	_boot.start_facing = Vector2i.RIGHT
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	await wait_process_frames(2)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_boot.get_battle_hud().get_message_banner().message_shown.connect(
		func(text: String, _wait: bool) -> void: _shown_lines.append(text))


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		Input.action_release(action)


# --- Mise en place ---------------------------------------------------------------------

## Nouvelle partie dans la Tour : graine [param seed], starter N20, des Poké Balls et une Potion,
## joueur replacé à son arrivée.
func _new_tower_game(seed: int, balls: int = 5) -> void:
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = STARTER
	var party := Party.new()
	party.add(PokemonFactory.create(_boot.get_pokemon_data(), STARTER, LEVEL,
		GameRng.new(PARTY_SEED)))
	GameState.party = party
	if balls > 0:
		GameState.bag.add(BALL, balls)
	GameState.bag.add(&"potion", 1)
	var map := _boot.get_map()
	_player.enter_map(map.get_grid(), Vector2i(4, 9), Vector2i.RIGHT, map.get_pixel_rect())


## Nom affiché de l'espèce [param species] (données).
func _species_name(species: StringName) -> String:
	return _boot.get_pokemon_data().get_species(species).name


## Relève ce que montrent la carte et l'image adverses à cet instant.
func _snapshot() -> void:
	var card := _boot.get_battle_hud().get_card(BattleHud.Side.FOE)
	if card != null and card.visible:
		_shown_cards.append("%s %s" % [card.get_name_text(), card.get_level_text()])
	var sprite := _boot.get_battle_stage().get_sprite(BattleEvent.SideId.FOE)
	if sprite != null and sprite.visible and sprite.texture != null:
		_shown_images.append(sprite.texture.resource_path)


## Pilote le combat en cours jusqu'à sa fin : FUITE à chaque choix, après avoir relevé la carte et
## l'image. Attend [param director_only] : la fin du combat seul (combat hors rencontre), sinon
## celle de la rencontre. Renvoie l'issue.
func _flee_battle(director_only: bool = false) -> int:
	var enc := _boot.get_encounter_director()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var outcome: Array[int] = [Battle.Outcome.NONE]
	var on_finished := func(_id: StringName, o: int) -> void: outcome[0] = o
	battles.battle_finished.connect(on_finished)
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_until(func() -> bool: return battles.is_running(), 5.0)
	while (battles.is_running() or (not director_only and enc.is_running())) \
			and Time.get_ticks_msec() < deadline:
		_snapshot()
		var battle := battles.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS:
			hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
	battles.battle_finished.disconnect(on_finished)
	assert_false(battles.is_running(), "le combat s'est terminé")
	return outcome[0]


## Ouvre le Sac au premier choix, y choisit [param item] (même absent du Sac) et attend que la
## grille d'actions revienne. Renvoie le combat.
func _choose_from_bag(item: StringName) -> Battle:
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	await wait_until(func() -> bool:
		var b := battles.get_battle()
		return b != null and b.get_state() == Battle.State.CHOOSING \
			and hud.get_zone() == BattleHud.Zone.ACTIONS, 5.0)
	_snapshot()
	hud.action_selected.emit(ActionGrid.BAG)
	await wait_until(func() -> bool:
		var panel := battles.get_bag_panel()
		return panel != null and not panel.item_chosen.get_connections().is_empty(), 5.0)
	battles.get_bag_panel().item_chosen.emit(item)
	await wait_until(func() -> bool: return hud.get_zone() == BattleHud.Zone.ACTIONS, 5.0)
	return battles.get_battle()


## Graine dont le premier pas sur le sol de [constant MAP_ID] tire une rencontre (reproduit le
## tirage du jeu) ; −1 si aucune.
func _floor_seed() -> int:
	var table := _boot.get_encounter_library().get_table(MAP_ID, &"floor")
	for seed: int in range(0, 4000):
		if table.roll(GameRng.new(seed)) != null:
			return seed
	return -1


# --- Pokédex ---------------------------------------------------------------------------

func test_walking_on_the_floor_meets_a_ghost_that_records_nothing() -> void:
	var seed := _floor_seed()
	assert_gt(seed, -1, "une graine : rencontre au premier pas")
	if seed < 0:
		return
	_new_tower_game(seed)
	var enc := _boot.get_encounter_director()
	watch_signals(enc)
	watch_signals(GameState.pokedex)
	var money := GameState.money
	var hp := GameState.party.get_lead().hp
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	Input.action_release(&"move_right")
	assert_true(enc.is_running(), "une rencontre sur le sol de la Tour")
	assert_eq(_player.get_cell(), FLOOR_STEP)
	var outcome := await _flee_battle()
	assert_eq(outcome, Battle.Outcome.FLED, "la fuite réussit")
	assert_signal_emitted_with_parameters(enc, "encounter_started",
		[GhostDisguise.SPECIES, GhostDisguise.HIDDEN_LEVEL])
	assert_signal_not_emitted(enc, "cry_requested", "aucun cri")
	assert_signal_not_emitted(GameState.pokedex, "recorded", "ni « vu », ni toast")
	assert_eq(GameState.pokedex.seen_count(), 0)
	assert_eq(GameState.pokedex.caught_count(), 0)
	assert_true(GameState.first_wild_encounter.is_empty(), "pas de première espèce sauvage")
	assert_has(_shown_lines, "Un SPECTRE apparaît !")
	assert_has(_shown_lines, "Impossible d'identifier le SPECTRE…")
	assert_eq(_boot.get_map().map_id, MAP_ID)
	assert_eq(_player.get_cell(), FLOOR_STEP, "resté sur sa case")
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	assert_eq(GameState.money, money, "argent inchangé")
	assert_eq(GameState.party.get_lead().hp, hp, "équipe inchangée")
	assert_eq(GameState.party.size(), 1)


func test_forced_species_never_leak_nor_get_recorded() -> void:
	_new_tower_game(11)
	var enc := _boot.get_encounter_director()
	watch_signals(GameState.pokedex)
	for species: StringName in FORCED:
		assert_true(enc.start_encounter(WildEncounter.new(species, 25)), String(species))
		await wait_until(func() -> bool: return enc.is_running(), 5.0)
		assert_eq(await _flee_battle(), Battle.Outcome.FLED, String(species))
		assert_eq(GameState.pokedex.seen_count(), 0, "%s : rien de vu" % species)
	assert_signal_not_emitted(GameState.pokedex, "recorded")
	assert_true(GameState.first_wild_encounter.is_empty())
	# Garde du nom : ni texte, ni carte, ni image.
	assert_gt(_shown_lines.size(), 0)
	assert_gt(_shown_cards.size(), 0)
	assert_gt(_shown_images.size(), 0)
	for species: StringName in FORCED:
		var name := _species_name(species)
		for line: String in _shown_lines + _shown_cards + _shown_images:
			assert_false(line.containsn(name), "« %s » dans « %s »" % [name, line])
			assert_false(line.containsn(String(species)), "« %s » dans « %s »" % [species, line])
	for card: String in _shown_cards:
		assert_eq(card, "SPECTRE Nv. ??", "carte masquée")
	for path: String in _shown_images:
		assert_eq(path, GhostDisguise.TEXTURE_PATH, "silhouette seulement")


func test_a_ghost_battle_outside_an_encounter_records_nothing() -> void:
	_new_tower_game(12)
	watch_signals(GameState.pokedex)
	var encounter := WildEncounter.new(&"marowak", 30)
	encounter.ghost = true
	var outcome: Array[int] = [Battle.Outcome.NONE]
	var run := func() -> void:
		outcome[0] = await _boot.get_battle_director().run_wild(encounter, _boot.get_map(),
			_player.get_cell())
	run.call()
	assert_eq(await _flee_battle(true), Battle.Outcome.FLED)
	assert_eq(outcome[0], Battle.Outcome.FLED)
	assert_signal_not_emitted(GameState.pokedex, "recorded", "garde de Boot")
	assert_false(GameState.pokedex.is_seen(&"marowak"))


# --- Ball ------------------------------------------------------------------------------

func test_a_ball_is_refused_without_being_spent_nor_playing_a_turn() -> void:
	_new_tower_game(13)
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"gastly", 20)))
	var battle := await _choose_from_bag(BALL)
	assert_not_null(battle)
	assert_has(_shown_lines,
		"Pas question de lancer une Ball sur… ça. Elle passerait au travers.")
	assert_eq(GameState.bag.count_of(BALL), 5, "Ball non consommée")
	assert_eq(battle.get_turn(), 0, "aucun tour joué")
	assert_eq(battle.get_state(), Battle.State.CHOOSING, "le combat attend un nouveau choix")
	assert_eq(await _flee_battle(), Battle.Outcome.FLED)
	assert_eq(GameState.bag.count_of(BALL), 5)
	assert_push_error_count(0)


func test_without_any_ball_nothing_changes() -> void:
	_new_tower_game(14, 0)
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"gastly", 20)))
	var battle := await _choose_from_bag(BALL)
	assert_eq(GameState.bag.count_of(BALL), 0)
	assert_eq(battle.get_turn(), 0, "aucun tour joué")
	assert_eq(await _flee_battle(), Battle.Outcome.FLED)
	assert_push_error_count(0)


# --- Scope -----------------------------------------------------------------------------

func test_the_scope_is_read_again_at_each_encounter() -> void:
	_new_tower_game(15)
	GameState.party.get_lead().stats[&"spe"] = 999
	var enc := _boot.get_encounter_director()
	var battles := _boot.get_battle_director()
	var name := _species_name(&"gastly")
	# Avec le Scope (identifiant brut) : rencontre normale.
	GameState.bag.add(SCOPE)
	assert_true(enc.start_encounter(WildEncounter.new(&"gastly", 20)))
	await wait_until(func() -> bool:
		return battles.get_battle() != null \
			and battles.get_battle().get_state() == Battle.State.CHOOSING, 5.0)
	var battle := battles.get_battle()
	assert_false(battle.get_rules().ghost, "Scope : pas de SPECTRE")
	assert_false(battle.refuses_balls())
	assert_true(battle.is_legal(BattleAction.ball(BALL)), "capture possible")
	assert_eq(await _flee_battle(), Battle.Outcome.FLED)
	assert_true(GameState.pokedex.is_seen(&"gastly"), "« vu »")
	assert_true(_shown_lines.any(func(l: String) -> bool: return l.contains(name)), "nom réel")
	# Sans le Scope : de nouveau un SPECTRE.
	GameState.bag.remove(SCOPE)
	var seen := GameState.pokedex.times_seen(&"gastly")
	assert_true(enc.start_encounter(WildEncounter.new(&"gastly", 20)))
	await wait_until(func() -> bool: return battles.get_battle() != null, 5.0)
	assert_true(battles.get_battle().get_rules().ghost, "Scope retiré : SPECTRE")
	assert_eq(await _flee_battle(), Battle.Outcome.FLED)
	assert_eq(GameState.pokedex.times_seen(&"gastly"), seen, "rien de plus au Pokédex")


# --- Terrain ---------------------------------------------------------------------------

## Directeur seul sur la carte [param map_id] (la vraie scène), avec la vraie bibliothèque.
func _director_on(map_id: StringName) -> Array:
	var map := (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var director := EncounterDirector.new()
	add_child_autofree(director)
	director.setup(_boot.get_encounter_library(), _boot.get_pokemon_data(), GameState, null,
		null, null, null)
	director.set_map(map)
	return [director, map]


func test_floor_terrain_excludes_stairs_triggers_and_calm_cells() -> void:
	var pair := _director_on(MAP_ID)
	var director: EncounterDirector = pair[0]
	var map: GameMap = pair[1]
	assert_eq(director.terrain_at(FLOOR_STEP), &"floor", "sol de la Tour")
	assert_eq(director.terrain_at(Vector2i(0, 0)), &"", "mur")
	assert_gt(map.get_warps().size(), 0)
	for warp: Warp in map.get_warps().get_all():
		assert_eq(director.terrain_at(warp.cell), &"", "escalier %s" % warp.cell)
	for upper: StringName in [&"pokemon_tower_5f", &"pokemon_tower_6f"]:
		var floor_pair := _director_on(upper)
		var upper_director: EncounterDirector = floor_pair[0]
		var upper_map: GameMap = floor_pair[1]
		assert_gt(upper_map.get_triggers().size(), 0, "%s a des déclencheurs" % upper)
		for trigger: EventTrigger in upper_map.get_triggers().get_all():
			assert_eq(upper_director.terrain_at(trigger.cell), &"",
				"%s : déclencheur %s" % [upper, trigger.cell])
		for warp: Warp in upper_map.get_warps().get_all():
			assert_eq(upper_director.terrain_at(warp.cell), &"", "%s : escalier" % upper)
		for cell: Vector2i in upper_map.calm_cells:
			assert_eq(upper_director.terrain_at(cell), &"", "%s : case calme %s" % [upper, cell])
	var calm_map: GameMap = _director_on(&"pokemon_tower_5f")[1]
	assert_gt(calm_map.calm_cells.size(), 0, "le 5F a ses cases calmes")


func test_second_floor_never_has_an_encounter() -> void:
	var pair := _director_on(&"pokemon_tower_2f")
	var director: EncounterDirector = pair[0]
	var map: GameMap = pair[1]
	var grid := map.get_grid()
	var encounter_cells: Array[Vector2i] = []
	for y: int in grid.get_size().y:
		for x: int in grid.get_size().x:
			if not director.terrain_at(Vector2i(x, y)).is_empty():
				encounter_cells.append(Vector2i(x, y))
	assert_eq(encounter_cells, [] as Array[Vector2i], "2F : aucune case de rencontre")
