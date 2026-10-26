extends RefCounted
## Pilote de partie des tests du repaire Rocket et du Casino (jalon 20 T21) : vraie scène Boot,
## sauvegarde en mémoire, départ de débogage (`tools/debug_start/`), vraies entrées (`move_*`,
## `interact`), combats pilotés (ATTAQUE, première capacité), pages, cartes de Champion, légendes
## et toasts relevés dans [member events] :
## « page:<texte> », « card:<nom>/<titre> », « battle », « caption:<texte> »,
## « toast:<titre> / <détail> ».
##
## Les attentes sont bornées par un délai de garde (temps réel) : aucune durée n'est mesurée.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const FADE := 0.05
const STEP_TIMEOUT_MS := 12000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}

var boot: Boot
var player: Player
var fs: MemoryFs
var save_path: String
var events: Array[String] = []
var vibrations: Array[int] = []

var _test: GutTest
var _saved_router: Array = []


func _init(test: GutTest, path: String) -> void:
	_test = test
	save_path = path
	fs = MemoryFs.new()


## À appeler dans before_each.
func setup() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T18:00:00")
	events.clear()
	vibrations.clear()
	Haptics.sink = func(ms: int) -> void: vibrations.append(ms)


## À appeler dans after_each.
func teardown() -> void:
	if not _saved_router.is_empty():
		SceneRouter.fade_out_duration = _saved_router[0]
		SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"interact")


## Boot sur la partie du départ [param start_path] ; [param tweak] (facultatif,
## `func() -> void`) modifie la partie avant le rechargement de la carte (drapeaux, Sac, équipe).
## [param settle] faux (J30) : n'attend pas une partie stable (une scène part à l'arrivée).
func start(start_path: String, tweak: Callable = Callable(), settle: bool = true) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(start_path))
	var raw: Dictionary = parsed if parsed is Dictionary else {}
	var map_id := StringName(str(raw.get("map", "")))
	var spawn := StringName(str(raw.get("spawn", "")))
	var facing := _direction(str(raw.get("facing", "down")))
	boot = BOOT_SCENE.instantiate() as Boot
	boot.save_system = SaveSystem.new(fs, save_path)
	boot.start_map = map_id
	boot.start_spawn = spawn
	boot.start_facing = facing
	_test.add_child_autofree(boot)
	player = boot.get_player()
	boot.get_dialogue_runner().chars_per_second = 0.0
	var debug := DebugStart.new()
	_test.assert_true(debug.load_file(start_path, boot.get_pokemon_data(),
		boot.get_item_library()), "\n".join(debug.get_errors()))
	debug.apply(GameState, boot.get_pokemon_data())
	GameState.player_name = "Kevin"
	GameState.rng = GameRng.new(7)
	_quiet_battles()
	if tweak.is_valid():
		tweak.call()
	await _test.wait_process_frames(2)
	# Les PNJ suivent les drapeaux au chargement de la carte : on la recharge.
	await SceneRouter.change_map(map_id, spawn, facing)
	await _test.wait_process_frames(3)
	if settle:
		await _test.wait_until(func() -> bool: return boot.is_stable(), 15.0)
	_quiet_battles()


## Nouvelle Boot sur la sauvegarde en mémoire (application relancée). [param settle] : voir
## [method start].
func resume(settle: bool = true) -> void:
	if is_instance_valid(boot):
		_test.remove_child(boot)
		boot.free()
	await _test.wait_process_frames(2)
	boot = BOOT_SCENE.instantiate() as Boot
	boot.save_system = SaveSystem.new(fs, save_path)
	_test.add_child_autofree(boot)
	player = boot.get_player()
	boot.get_dialogue_runner().chars_per_second = 0.0
	await _test.wait_process_frames(3)
	if settle:
		await _test.wait_until(func() -> bool: return boot.is_stable(), 15.0)
	_quiet_battles()


## Équipe réduite à un Salamèche N60 (Flammèche) : gagne tout.
func make_strong() -> void:
	var champion := PokemonFactory.create(boot.get_pokemon_data(), &"charmander", 60,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	_replace_party(champion)


## Équipe réduite à un Salamèche N5 : perd tout combat de Dresseur du repaire.
func make_weak() -> void:
	_replace_party(PokemonFactory.create(boot.get_pokemon_data(), &"charmander", 5,
		GameState.rng))


func map_id() -> StringName:
	return boot.get_map().map_id


## Marche jusqu'à [param goal] par le plus court chemin de la vraie grille (pas libres, entrées
## réelles), sans passer par un passage ni une dalle tournante (sauf [param goal]). S'arrête si
## une scène prend la main (Dresseur qui repère le joueur).
func walk_to(goal: Vector2i) -> void:
	var map := boot.get_map()
	var grid := map.get_grid()
	var avoided: Array[Vector2i] = []
	for warp: Warp in map.get_warps().get_all():
		avoided.append(warp.cell)
	var field := map.get_node_or_null(^"SpinTiles")
	if field != null:
		avoided.append_array((field.get(&"arrows") as Dictionary).keys())
	var blocker := RefCounted.new()
	var held: Array[Vector2i] = []
	for cell: Vector2i in avoided:
		if cell != goal and cell != player.get_cell() and grid.occupy(cell, blocker):
			held.append(cell)
	var path := grid.find_path(player.get_cell(), goal, player)
	for cell: Vector2i in held:
		grid.release(cell, blocker)
	_test.assert_false(path.is_empty() and player.get_cell() != goal,
		"un chemin mène de %s à %s" % [player.get_cell(), goal])
	var cell := player.get_cell()
	for direction: Vector2i in path:
		cell += direction
		await step(direction)
		if player.get_cell() != cell:
			return


## Un pas (ou un passage) vers [param direction], puis la partie au repos.
func step(direction: Vector2i) -> void:
	var from_cell := player.get_cell()
	var from_map := map_id()
	var action: StringName = DIRECTIONS[direction]
	var deadline := Time.get_ticks_msec() + STEP_TIMEOUT_MS
	Input.action_press(action)
	while Time.get_ticks_msec() < deadline:
		if player.is_moving() or player.get_cell() != from_cell \
				or SceneRouter.is_transitioning() or not player.is_input_enabled():
			break
		await _test.wait_process_frames(1)
	Input.action_release(action)
	await _test.wait_process_frames(2)
	await _test.wait_until(func() -> bool:
		return (not player.is_moving() and not SceneRouter.is_transitioning()) \
			or boot.get_cutscene_director().is_running(), 15.0)
	if map_id() != from_map:
		await _test.wait_until(func() -> bool: return boot.is_stable(), 15.0)


## Tourné vers [param facing], bouton d'interaction ; déroule tout (pages, choix =
## [param answer], carte, combat piloté, légende, toast, réveil). Vrai si un combat a eu lieu.
func interact(facing: Vector2i, answer: bool = true) -> bool:
	player.face(facing)
	Input.action_press(&"interact")
	await _test.wait_process_frames(2)
	Input.action_release(&"interact")
	return await run_scene(answer)


## Déroule la scène ou le dialogue en cours (voir [method interact]).
func run_scene(answer: bool = true) -> bool:
	var before := events.count("battle")
	var director := boot.get_cutscene_director()
	var runner := boot.get_dialogue_runner()
	var box := boot.get_dialogue_box()
	var hud := boot.get_hud()
	var battles := boot.get_battle_director()
	var battle_hud := boot.get_battle_hud()
	var toast := hud.get_toast()
	var card_seen := false
	var caption_seen := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	await _test.wait_process_frames(1)
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()
			or battles.is_running()) and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		var card := hud.get_champion_card()
		if card.is_showing() and not card_seen:
			events.append("card:%s/%s" % [card.get_name_text(), card.get_title_text()])
			card.skip_hold()
		card_seen = card.is_showing()
		var caption := hud.get_caption()
		if caption.is_showing() and not caption_seen:
			events.append("caption:" + caption.text)
		caption_seen = caption.is_showing()
		if toast.visible:
			var shown := "toast:%s / %s" % [toast.get_title_text(), toast.get_detail_text()]
			if not events.has(shown):
				events.append(shown)
		await _test.wait_process_frames(1)
		if runner.is_awaiting_choice():
			runner.choose(answer)
		elif box.is_open():
			var page := "page:" + box.get_text().replace("\n", " ")
			if events.is_empty() or events.back() != page:
				events.append(page)
			box.advance_requested.emit()
	await _test.wait_process_frames(3)
	if toast.visible:
		var last := "toast:%s / %s" % [toast.get_title_text(), toast.get_detail_text()]
		if not events.has(last):
			events.append(last)
	# Panneau d'étages ouvert : la partie n'est pas « stable », la main est à l'écran.
	await _test.wait_until(func() -> bool:
		return boot.is_stable() or boot.get_elevator_director().is_panel_open(), 15.0)
	return events.count("battle") > before


## Textes des pages relevées, dans l'ordre.
func pages() -> Array[String]:
	var found: Array[String] = []
	for event: String in events:
		if event.begins_with("page:"):
			found.append(event.trim_prefix("page:"))
	return found


## Contenu du fichier de sauvegarde (dictionnaire vide s'il manque).
func saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(fs.files.get(save_path, ""))
	return parsed if parsed is Dictionary else {}


func _quiet_battles() -> void:
	# J30 : écran du Panthéon et générique instantanés (sans toucher).
	if boot.has_method(&"get_hall_of_fame_screen"):
		boot.get_hall_of_fame_screen().speed_scale = 0.0
		boot.get_credits_screen().speed_scale = 0.0
	var battles := boot.get_battle_director()
	battles.speed_scale = 0.0
	boot.get_battle_stage().speed_scale = 0.0
	boot.get_battle_hud().speed_scale = 0.0
	boot.get_battle_hud().haptics_enabled = false
	if not battles.battle_started.is_connected(_on_battle_started):
		battles.battle_started.connect(_on_battle_started)


func _on_battle_started(_id: StringName) -> void:
	events.append("battle")


func _replace_party(pokemon: Pokemon) -> void:
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(pokemon)


static func _direction(word: String) -> Vector2i:
	return {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
		"right": Vector2i.RIGHT}.get(word, Vector2i.DOWN)
