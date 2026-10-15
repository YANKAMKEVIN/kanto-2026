extends GutTest
## J15 T24 (`jalon-15.md` §3 T24) : « combat gagné avec toute l'équipe K.O. » n'existe plus.
## Avec la vraie scène Boot (combat instantané, sauvegarde en mémoire), départ `trainers_qa`
## (devant le Scout Théo, Chenipan N6 seul) : le dernier Pokémon valide du joueur, sans PP, met
## Chenipan K.O. avec Lutte et tombe sur le contrecoup → DÉFAITE (Rouge/Bleu) : réveil au dernier
## Centre utilisé avec l'équipe soignée (mot de l'infirmière), argent inchangé (ni prix ni perte,
## règle existante), Théo pas battu (`beaten_forest_scout_theo` absent : il reste à battre) ;
## aucune erreur (le Dresseur ne lance jamais un combat sans Pokémon valide).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const TRAINERS_START := "res://tools/debug_start/trainers_qa.json"
const SAVE_PATH := "user://test_double_ko_defeat_save.json"
const DATE := "2026-10-15T17:00:00"
const FADE := 0.05
const SCENE_TIMEOUT_MS := 60000
const THEO := &"forest_scout_theo"

var _fs: MemoryFs
var _boot: Boot
var _saved_router: Array = []
var _events: Array[BattleEvent] = []
var _outcomes: Array[int] = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	Haptics.sink = func(_ms: int) -> void: pass
	_fs = MemoryFs.new()
	_events.clear()
	_outcomes.clear()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()


## Boot devant Théo (départ appliqué à la main, un départ de débogage n'est pas lu sous GUT).
func _start() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	var start := DebugStart.new()
	add_child_autofree(_boot)
	assert_true(start.load_file(TRAINERS_START, _boot.get_pokemon_data(),
		_boot.get_item_library()), "\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	await wait_process_frames(2)
	await SceneRouter.change_map(start.map, start.spawn, start.facing)
	await wait_process_frames(3)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var battles := _boot.get_battle_director()
	battles.speed_scale = 0.0
	battles.event_played.connect(_events.append)
	battles.battle_finished.connect(func(_t: StringName, outcome: int) -> void:
		_outcomes.append(outcome))


## Équipe : Salamèche N50 sans PP à 1 PV (Lutte met Chenipan K.O., le contrecoup le met K.O.),
## puis Roucool déjà K.O. ; le dernier Centre utilisé est celui de Jadielle.
func _arm_double_ko() -> void:
	var data := _boot.get_pokemon_data()
	var party := Party.new()
	var strong := PokemonFactory.create(data, &"charmander", 50, GameRng.new(7))
	for slot: MoveSlot in strong.moves:
		slot.pp = 0
	strong.hp = 1
	party.add(strong)
	var fainted := PokemonFactory.create(data, &"pidgey", 8, GameRng.new(8))
	fainted.hp = 0
	party.add(fainted)
	GameState.party = party
	GameState.heal_map = &"viridian_center"
	GameState.heal_spawn = &"heal"


## Défi à la parole (ce que fait le contrôleur d'interactions) puis la séquence jusqu'au bout,
## réveil compris : pages avancées, combat piloté (ATTAQUER = Lutte sans PP).
func _challenge_and_play() -> void:
	var npc := _boot.get_map().get_npc(&"scout_theo")
	assert_not_null(npc, "Théo posé sur la carte")
	assert_true(_boot.get_trainer_watcher().challenge(npc), "défi lancé")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING \
					and hud.get_zone() == BattleHud.Zone.ACTIONS:
				hud.action_selected.emit(ActionGrid.ATTACK)
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)
	assert_false(director.is_running(), "séquence terminée")


func _fainted_sides() -> Array:
	var sides: Array = []
	for event: BattleEvent in _events:
		if event.kind == BattleEvent.Kind.FAINTED:
			sides.append(event.side)
	return sides


func test_last_pokemon_falling_with_the_trainer_s_last_is_a_defeat() -> void:
	await _start()
	_arm_double_ko()
	GameState.money = 3000
	await _challenge_and_play()
	assert_eq(_fainted_sides(), [BattleEvent.SideId.FOE, BattleEvent.SideId.PLAYER],
		"Chenipan K.O. puis Salamèche sur le contrecoup")
	assert_eq(_outcomes, [Battle.Outcome.LOSS] as Array[int], "défaite, pas victoire")
	assert_eq(_boot.get_map().map_id, &"viridian_center", "réveil au dernier Centre utilisé")
	assert_true(_pages.has("Voilà. Tout le monde est en pleine forme."), "mot de l'infirmière")
	for pokemon: Pokemon in GameState.party.get_all():
		assert_false(pokemon.is_fainted(), "%s soigné" % pokemon.species_id)
	assert_eq(GameState.money, 3000, "ni prix du Dresseur ni argent perdu")
	assert_false(GameState.flags.has_flag(&"beaten_%s" % THEO), "Théo reste à battre")
	assert_false(TrainerRules.is_beaten(GameState.flags, THEO))
	assert_true(_boot.get_player().is_input_enabled(), "joueur libre")
	assert_push_error_count(0)
