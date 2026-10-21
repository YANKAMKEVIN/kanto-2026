extends GutTest
## Étape de scène « wild_battle » (jalon 19 T13, `jalon-19.md` §2.4) avec la vraie scène Boot sur
## la carte réelle `pokemon_tower_3f`, texte et animations de combat instantanés :
## - le combat sauvage est lancé par la scène, depuis la case devant le joueur ;
## - « ghost_unless_item » : SPECTRE sans l'objet, combat normal avec ; « ghost: always » :
##   SPECTRE même avec l'objet ;
## - en SPECTRE, rien n'est « vu » au Pokédex (garde de Boot sur les événements masqués) ; en
##   combat normal, l'espèce est vue ;
## - défaite (poison) : réveil au point de repos, la scène s'arrête ;
## - fuite : l'étape suivante est jouée ;
## - drapeaux « win » / « lose » posés seulement s'ils sont écrits.

const STARTER := &"charmander"
const LEVEL := 20
const PARTY_SEED := 777
const MAP_ID := &"pokemon_tower_3f"
const SPAWN := &"arrivee_T23"
## Case d'arrivée (4, 9), tournée vers l'est.
const START := Vector2i(4, 9)
const SCOPE := &"silph_scope"
const FOE := &"marowak"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENES := {
	"t13_unless_scope": {"steps": [
		{"wild_battle": "marowak", "level": 30, "ghost_unless_item": "silph_scope",
			"lose": ["t13_lost"]},
		{"set": ["t13_after"]},
	]},
	"t13_always": {"steps": [
		{"wild_battle": "marowak", "level": 30, "ghost": "always", "ghost_unless_item":
			"silph_scope"},
		{"set": ["t13_after"]},
	]},
	"t13_flags": {"steps": [
		{"wild_battle": "marowak", "level": 30, "ghost": "always", "win": ["t13_won"],
			"lose": ["t13_lost"]},
		{"set": ["t13_after"]},
	]},
}

var _boot: Boot
var _player: Player
var _fades: Array[float] = []
var _shown_lines: Array[String] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_shown_lines.clear()
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
	var library := _boot.get_cutscene_library()
	assert_true(library.add_from_dict(SCENES, "test"), str(library.get_errors()))
	assert_true(library.check_species(_boot.get_pokemon_data()))


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


# --- Mise en place ---------------------------------------------------------------------

## Nouvelle partie dans la Tour : starter N20, joueur replacé à son arrivée, tourné vers l'est.
func _new_tower_game(seed: int = 11) -> void:
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = STARTER
	var party := Party.new()
	party.add(PokemonFactory.create(_boot.get_pokemon_data(), STARTER, LEVEL,
		GameRng.new(PARTY_SEED)))
	GameState.party = party
	var map := _boot.get_map()
	_player.enter_map(map.get_grid(), START, Vector2i.RIGHT, map.get_pixel_rect())


## Joue la scène [param id] et pilote son combat jusqu'à la fin de la scène : FUITE si
## [param flee], sinon ATTAQUER puis la 1re capacité. Renvoie l'issue du combat.
func _play_and_drive(id: StringName, flee: bool) -> int:
	var cutscenes := _boot.get_cutscene_director()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var outcome: Array[int] = [Battle.Outcome.NONE]
	var on_finished := func(_id: StringName, o: int) -> void: outcome[0] = o
	battles.battle_finished.connect(on_finished)
	assert_true(cutscenes.play(id), "scène lancée")
	await wait_until(func() -> bool: return battles.is_running(), 5.0)
	assert_true(battles.is_running(), "combat lancé par la scène")
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while cutscenes.is_running() and Time.get_ticks_msec() < deadline:
		var battle := battles.get_battle() if battles.is_running() else null
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					hud.action_selected.emit(ActionGrid.RUN if flee else ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(0)
		await wait_process_frames(1)
	battles.battle_finished.disconnect(on_finished)
	assert_false(cutscenes.is_running(), "la scène s'est terminée")
	return outcome[0]


# --- Mode SPECTRE ou normal ------------------------------------------------------------

func test_without_the_item_the_battle_is_a_ghost_that_records_nothing() -> void:
	_new_tower_game()
	watch_signals(GameState.pokedex)
	watch_signals(_boot.get_battle_director())
	var outcome := await _play_and_drive(&"t13_unless_scope", true)
	assert_eq(outcome, Battle.Outcome.FLED, "la fuite réussit")
	assert_signal_emitted(_boot.get_battle_director(), "battle_started")
	assert_has(_shown_lines, "Un SPECTRE apparaît !")
	var name := _boot.get_pokemon_data().get_species(FOE).name
	for line: String in _shown_lines:
		assert_false(line.contains(name), "espèce jamais nommée : %s" % line)
	assert_signal_not_emitted(GameState.pokedex, "recorded", "aucun « vu »")
	assert_eq(GameState.pokedex.seen_count(), 0)
	assert_true(GameState.first_wild_encounter.is_empty(), "pas de première espèce sauvage")


func test_with_the_item_the_battle_is_normal_and_the_species_is_seen() -> void:
	_new_tower_game()
	GameState.bag.add(SCOPE, 1)
	var outcome := await _play_and_drive(&"t13_unless_scope", true)
	assert_eq(outcome, Battle.Outcome.FLED)
	assert_does_not_have(_shown_lines, "Un SPECTRE apparaît !")
	assert_true(GameState.pokedex.is_seen(FOE), "l'espèce est vue en combat normal")


func test_ghost_always_stays_a_ghost_even_with_the_item() -> void:
	_new_tower_game()
	GameState.bag.add(SCOPE, 1)
	watch_signals(GameState.pokedex)
	var outcome := await _play_and_drive(&"t13_always", true)
	assert_eq(outcome, Battle.Outcome.FLED)
	assert_has(_shown_lines, "Un SPECTRE apparaît !")
	assert_signal_not_emitted(GameState.pokedex, "recorded", "aucun « vu »")


# --- Issues ----------------------------------------------------------------------------

func test_fleeing_plays_the_next_step_and_returns_control() -> void:
	_new_tower_game()
	var outcome := await _play_and_drive(&"t13_flags", true)
	assert_eq(outcome, Battle.Outcome.FLED)
	assert_true(GameState.flags.has_flag(&"t13_after"), "étape suivante jouée")
	assert_false(GameState.flags.has_flag(&"t13_won"), "pas de drapeau de victoire")
	assert_false(GameState.flags.has_flag(&"t13_lost"), "pas de drapeau de défaite")
	assert_eq(_boot.get_map().map_id, MAP_ID)
	assert_eq(_player.get_cell(), START, "resté sur sa case")
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	assert_push_error_count(0)


func test_a_poison_defeat_wakes_the_player_and_stops_the_scene() -> void:
	_new_tower_game()
	var lead := GameState.party.get_lead()
	lead.hp = 1
	lead.status = StatusRules.POISON
	var outcome := await _play_and_drive(&"t13_unless_scope", false)
	assert_eq(outcome, Battle.Outcome.LOSS, "défaite")
	assert_true(GameState.flags.has_flag(&"t13_lost"), "drapeau « lose » écrit, posé")
	assert_false(GameState.flags.has_flag(&"t13_after"), "la scène s'arrête au réveil")
	await wait_until(func() -> bool:
		return _boot.get_map() != null and _boot.get_map().map_id == GameState.heal_map, TIMEOUT)
	assert_eq(_boot.get_map().map_id, GameState.heal_map, "réveil au point de repos")
	assert_eq(lead.hp, lead.max_hp(), "équipe soignée")
	assert_push_error_count(0)


func test_a_defeat_without_lose_flags_sets_no_flag() -> void:
	_new_tower_game()
	var lead := GameState.party.get_lead()
	lead.hp = 1
	lead.status = StatusRules.POISON
	var before := GameState.flags.to_array()
	var outcome := await _play_and_drive(&"t13_always", false)
	assert_eq(outcome, Battle.Outcome.LOSS)
	assert_false(GameState.flags.has_flag(&"t13_lost"), "aucun drapeau non écrit")
	assert_false(GameState.flags.has_flag(&"t13_after"))
	assert_eq(GameState.flags.to_array(), before, "aucun drapeau posé par le combat")
