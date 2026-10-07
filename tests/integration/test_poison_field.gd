extends GutTest
## Poison hors combat (jalon 9 §2.1.4, arbitrage 2 du dossier 10, Q-6) : **aucune perte de PV
## en marchant**. La vraie scène Boot, une équipe empoisonnée, 200 pas annoncés par le joueur
## (tous les écouteurs du pas réagissent : scènes, rencontres, Pokémon d'ambiance, warps) :
## PV et statut inchangés. Le statut ne part qu'avec un soin complet (Centre, Maman).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_poison_field_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const STEPS := 200

var _boot: Boot
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-07T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func test_walking_never_hurts_a_poisoned_pokemon() -> void:
	GameState.new_game(3)
	GameState.flags.set_flag(&"starter_chosen")
	var data := _boot.get_pokemon_data()
	var lead := PokemonFactory.create(data, &"charmander", 9, GameRng.new(7))
	lead.status = StatusRules.POISON
	lead.hp = 5
	var second := PokemonFactory.create(data, &"pidgey", 7, GameRng.new(7))
	second.status = StatusRules.POISON
	GameState.party.add(lead)
	GameState.party.add(second)
	var player := _boot.get_player()
	var cell := player.get_cell()
	for i: int in STEPS:
		player.moved.emit(cell)
	await wait_process_frames(3)
	assert_false(_boot.get_battle_director().is_running(), "aucun combat (pas dans l'herbe)")
	assert_eq([lead.hp, lead.status], [5, &"poison"], "PV et statut inchangés")
	assert_eq([second.hp, second.status], [second.max_hp(), &"poison"])
	GameState.party.heal_all()
	assert_eq([lead.hp, lead.status], [lead.max_hp(), StatusRules.NONE],
		"le soin complet (Centre, Maman) efface le poison")
