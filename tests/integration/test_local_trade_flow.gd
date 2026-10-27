extends GutTest
## Terminal d'échange local (jalon 32, T5 ; `jalon-32.md` §1.2, §5 ; N-15) avec le vrai Boot
## (Centre de Jadielle) et une sauvegarde en mémoire :
## - chaque Centre a son terminal d'échange (deux cases, face au mur) en plus du Stockage ;
## - échange fait : le même individu (identifiant, surnom) évolue, Pokédex à jour,
##   **une seule** écriture à la fin (le disque garde le Pokémon d'origine pendant l'évolution) ;
## - ANNULER au choix ou à la confirmation, aucun Pokémon compatible : rien ne change ;
## - le retour Android n'arrête pas l'évolution (non annulable).
## Le choix (TradeOverlay) est remplacé par une réponse directe ; l'écran d'évolution par le faux
## écran des tests.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FakeScreen := preload("res://tests/helpers/fake_evolution_screen.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_local_trade_flow_save.json"
const TIMEOUT := 15.0
const FADE := 0.05
const CENTERS: Array[StringName] = [&"viridian_center", &"pewter_center", &"mt_moon_center",
	&"cerulean_center", &"vermilion_center", &"route_10_center", &"lavender_center",
	&"celadon_center", &"saffron_center", &"fuchsia_center", &"cinnabar_center"]

var _fs: MemoryFs
var _boot: Boot
var _runner: DialogueRunner
var _trade: LocalTradeDirector
var _data: PokemonData
var _saved_router: Array = []
var _answers: Array[bool] = []
## Réponse au choix : une place, −1 = ANNULER.
var _pick: int = 0
var _views: Array[PartyPickerView] = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_answers = []
	_pick = 0
	_views.clear()
	_pages.clear()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"viridian_center"
	_boot.start_spawn = &"trade_terminal"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	_trade = _boot.get_local_trade_director()
	_data = _boot.get_pokemon_data()
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	prompt.speed_scale = 0.0
	prompt.confirm_forget = false
	_boot.get_evolution_director().speed_scale = 0.0
	_runner.page_started.connect(_on_page_started)
	_trade.pick_handler = func(view: PartyPickerView) -> int:
		_views.append(view)
		await get_tree().process_frame
		return _pick
	await wait_until(func() -> bool: return _writes() >= 1, TIMEOUT)
	GameState.new_game(32)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]


func _mon(species: StringName, level: int) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, GameRng.new(level))
	pokemon.ensure_uid()
	return pokemon


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _saved_species() -> Array[String]:
	var result: Array[String] = []
	var game: Dictionary = _saved().get("game", _saved())
	for member: Variant in game.get("party", []):
		if member is Dictionary:
			result.append(str((member as Dictionary).get("species", "")))
	return result


func _on_page_started(_index: int) -> void:
	_pages.append(_boot.get_dialogue_box().get_text())


## Le terminal est examiné (son dialogue) et toute la conversation se déroule.
func _use_terminal() -> void:
	assert_true(_runner.play(LocalTradeDirector.TERMINAL, null, _boot.get_map()), "le terminal")
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	# Le dialogue du terminal finit avant que la conversation ne commence (même image).
	await wait_process_frames(1)
	while (_runner.is_running() or _trade.is_running()) and Time.get_ticks_msec() < deadline:
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			var yes: bool = _answers.pop_front() if not _answers.is_empty() else false
			(cards.get_confirm_button() if yes else cards.get_cancel_button()).pressed.emit()
		elif box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		var banner := _boot.get_evolution_director().get_screen().get_message_banner() \
			if _boot.get_evolution_director().get_screen() != null else null
		if banner != null and banner.is_waiting():
			banner.skip()
		await wait_process_frames(1)
	assert_false(_runner.is_running() or _trade.is_running(), "la conversation s'est terminée")
	await wait_process_frames(2)


func _save_now() -> void:
	var writes := _writes()
	_boot.request_autosave("test")
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)


func test_every_center_has_a_trade_terminal_beside_the_storage() -> void:
	for map_id: StringName in CENTERS:
		var scene := load("res://game/world/maps/%s.tscn" % map_id) as PackedScene
		var map := scene.instantiate() as GameMap
		var trade := map.get_node_or_null(^"Interactables/TradeTerminalScreen") as InteractPoint
		var storage := map.get_node_or_null(^"Interactables/StorageTerminalScreen") \
			as InteractPoint
		assert_not_null(trade, "%s : terminal d'échange" % map_id)
		assert_not_null(storage, "%s : Stockage gardé" % map_id)
		if trade != null:
			assert_eq([trade.dialogue_id, trade.get_cells(), trade.facing], [&"trade_terminal",
				[Vector2i(12, 3), Vector2i(13, 3)] as Array[Vector2i], Vector2i.UP], String(map_id))
		assert_not_null(map.get_node_or_null(^"Entities/TradeTerminal"), "%s : le meuble" % map_id)
		assert_null(map.get_node_or_null(^"Entities/PlantNorthEast"), String(map_id))
		assert_not_null(map.get_node_or_null(^"Spawns/trade_terminal"), String(map_id))
		map.free()


func test_trade_evolves_the_same_individual_and_writes_once() -> void:
	var pikachu := _mon(&"pikachu", 25)
	var kadabra := _mon(&"kadabra", 30)
	kadabra.nickname = "Cuillère"
	GameState.party.add(pikachu)
	GameState.party.add(kadabra)
	assert_true(GameState.set_companion(kadabra))
	await _save_now()
	var uid := kadabra.uid
	var screen := FakeScreen.new()
	add_child_autofree(screen)
	_boot.get_evolution_director().set_screen(screen)
	var during: Array[Array] = []
	screen.probe = func() -> void: during.append(_saved_species())
	_pick = 1
	_answers = [true]
	var writes := _writes()
	await _use_terminal()
	assert_eq(_views.size(), 1, "le choix s'est ouvert")
	assert_eq(_views[0].title, LocalTrade.PICK_TEXT)
	assert_eq(_views[0].targets.map(func(t: PartyTargetView) -> bool: return t.usable),
		[false, true], "Pikachu refusé, Kadabra accepté")
	assert_true(_pages.has("Échanger Cuillère ?"), "confirmation : %s" % [_pages])
	assert_eq(during, [["pikachu", "kadabra"]] as Array[Array],
		"pendant l'évolution, le disque garde le Pokémon d'origine")
	var after := GameState.party.get_at(1)
	assert_eq([after.species_id, after.uid, after.nickname], [&"alakazam", uid, "Cuillère"])
	# Compagnon : même identifiant ; Boot le rentre en silence si Alakazam n'a pas de planche
	# (règle du 11D), jamais un autre Pokémon.
	assert_true(GameState.get_companion() in [after, null], "jamais un autre Pokémon")
	assert_true(GameState.pokedex.is_caught(&"alakazam"))
	assert_eq(_writes(), writes + 1, "une seule écriture, à la fin")
	assert_eq(_saved_species(), ["pikachu", "alakazam"] as Array[String])
	assert_true(_boot.get_player().is_input_enabled(), "joueur rendu")


func test_back_does_not_stop_the_trade_evolution() -> void:
	GameState.party.add(_mon(&"graveler", 30))
	var screen := FakeScreen.new()
	add_child_autofree(screen)
	_boot.get_evolution_director().set_screen(screen)
	screen.cancel = true
	screen.back = func() -> bool:
		_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		return true
	_pick = 0
	_answers = [true]
	await _use_terminal()
	assert_eq(GameState.party.get_at(0).species_id, &"golem", "non annulable")
	assert_false(screen.calls.has("revert"))


func test_cancel_at_the_pick_or_the_confirmation_changes_nothing() -> void:
	GameState.party.add(_mon(&"haunter", 28))
	await _save_now()
	var writes := _writes()
	_pick = -1
	await _use_terminal()
	assert_eq(GameState.party.get_at(0).species_id, &"haunter", "ANNULER au choix")
	_pick = 0
	_answers = [false]
	await _use_terminal()
	assert_eq(GameState.party.get_at(0).species_id, &"haunter", "ANNULER à la confirmation")
	assert_eq(_writes(), writes, "rien n'est écrit")
	assert_true(_boot.get_player().is_input_enabled())


func test_no_compatible_pokemon_says_so() -> void:
	GameState.party.add(_mon(&"pikachu", 25))
	await _use_terminal()
	assert_eq(_views.size(), 0, "pas de choix")
	var none := _boot.get_dialogue_library().get_dialogue(LocalTradeDirector.NONE)
	assert_true(_pages.has(none.variants[0].pages[0].text), "%s" % [_pages])
