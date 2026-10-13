extends GutTest
## Scène de Léo (jalon 14 T17, docs/tech/jalon-14.md §2.9, §2.10 ; dossier 17 §4, §5, §14) avec la
## vraie scène Boot, la vraie carte `bill_house`, ses vrais PNJ, dialogues et scènes, les vraies
## entrées (`move_*`, `interact`) et l'autoload SceneRouter (fondus raccourcis).
## - déroulé complet dans l'ordre : accueil de Mélofée, PARLER, écran, module (Léo entre dans la
##   cabine A), console (deux éclairs, Léo humain devant la cabine B), remerciements, Passe Bateau
##   et Super Bonbon, répliques d'après, objectifs ;
## - ordre forcé : écran / module / console hors d'ordre → phrases d'aide, lueur sur l'objet
##   attendu seul à chaque étape ;
## - sortie en cours de route : avancement gardé, Léo déjà dans la cabine au retour ;
## - fermeture pendant l'effet : scène rejouée en entier, objets une seule fois, drapeaux levés
##   ensemble à la fin ;
## - récompenses uniques, variantes de Léo (tirage `one_in`, « Rocket pas battu »).
## Le Grand moment `bill_restored` n'est pas enregistré ici : l'étape de scène « moment » (J12 T23)
## n'existe pas encore sur la branche (repli du plan, §0.3).

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/bill_house.json"
const AFTER_START := "res://tools/debug_start/bill_after.json"
const SAVE_PATH := "user://test_bill_house_save.json"
const HOUSE := &"bill_house"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 60000
const WALK_STOP := &"test_walk_stop"
const DATE := "2026-10-13T10:00:00"

const GREET := "Ah ! Enfin quelqu'un ! Non, non, ne sors pas ta Poké Ball !"
const INTRO_1 := "Je ne suis pas un Pokémon. Enfin… pas d'habitude. Je m'appelle Léo."
const INTRO_5 := "Commence par l'écran de diagnostic, là, au mur. Il me dira si les réglages ont tenu."
const WAIT_LINE := "Prends ton temps. Je ne vais nulle part. Littéralement."
const SCREEN_TEXT := "Des courbes et des voyants. Une ligne clignote : SÉPARATION PRÊTE."
const SCREEN_NEXT := "Parfait. Maintenant, le module, à droite de la console. Vérifie que tout est bien branché."
const MODULE_TEXT := "Tous les câbles sont en place. Le boîtier ronronne doucement."
const MODULE_HELP := "Des câbles partout. Mieux vaut commencer par l'écran."
const MODULE_NEXT := "Bon. J'entre dans la cabine. Quand je te fais signe, appuie sur le grand bouton de la console. Et… ne te trompe pas de bouton."
const CONSOLE_EARLY := "Beaucoup de boutons. Mieux vaut attendre les consignes de Léo."
const CONSOLE_HELP := "Léo t'a demandé de vérifier autre chose d'abord."
const CONSOLE_GO := "Un grand bouton rouge. Tu appuies dessus."
const CONSOLE_DEAD := "Léo a débranché la console. Le grand bouton ne répond plus."
const SCREEN_DONE := "SÉPARATION RÉUSSIE. Le Mélofée est retourné dehors."
const READY := "Je suis prêt ! Le grand bouton, sur la console !"
const THANKS := "Ha ! Deux bras, deux jambes, et à la bonne taille ! Merci, %s !"
const TICKET_LINE := "Tiens, j'ai reçu ça pour la soirée du S.S. Anne, mais je n'aime pas les bateaux. Prends-le."
const TICKET_CAPTION := "%s reçoit le PASSE BATEAU !"
const CANDY_LINE := "Et ça aussi. Un Super Bonbon. Il aide un Pokémon à grandir d'un coup."
const CANDY_CAPTION := "%s reçoit un SUPER BONBON !"
const SS_ANNE := "Le S.S. Anne fait escale à Carmin-sur-Mer, au sud. Il paraît que les Dresseurs du monde entier y montent."
const AFTER_1 := "Je reprends mes réglages. Promis, plus aucun Pokémon dans la cabine."
const AFTER_ROCKET := "Il paraît qu'il y a eu un cambriolage à Azuria. Les gens deviennent nerveux."
const AFTER_CHEN := "Chen m'a demandé conseil pour ses transferts de Pokémon, une fois. Il ne m'a jamais rendu mon tournevis."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
## Ce qui s'est passé, dans l'ordre : « page:<locuteur>|<texte> », « flash:<n> ».
var _events: Array[String] = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_events.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Aides ---------------------------------------------------------------------------------

## Boot (sauvegarde en mémoire) dans la maison de Léo, partie de [param start_path].
func _start(start_path: String = START, flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = HOUSE
	_boot.start_spawn = &"from_route_25"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	_boot.get_cutscene_director().flash_started.connect(
		func(count: int) -> void: _events.append("flash:%d" % count))
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, HOUSE)
	_boot.get_map().refresh_npcs(GameState.flags)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Maintient la direction jusqu'à [param until] (ou jusqu'à ce qu'une scène bloque le joueur).
func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Marche sans déclencher de scène : les cases sont à enchaîner dans l'ordre.
func _go(steps: Array) -> void:
	for step: Array in steps:
		await _walk(step[0], step[1])


## Joue tout ce qui est en cours (scène, dialogue, fondus) en tournant chaque page.
func _play_out() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			var page := "page:%s|%s" % [box.get_speaker_text(), box.get_text()]
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
	await wait_process_frames(3)


## Interagit avec la case devant le joueur (bouton d'interaction) et déroule le dialogue.
func _interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _play_out()


func _page(text: String, speaker: String = "") -> String:
	return "page:%s|%s" % [speaker, text]


func _index(text: String, speaker: String) -> int:
	return _events.find(_page(text, speaker))


func _name() -> String:
	return GameState.player_name


func _gate(node_name: String) -> FlagGate:
	return _boot.get_map().get_node(node_name) as FlagGate


## Seules les lueurs de [param expected] sont allumées (noms des nœuds `Hint…`).
func _assert_hints(expected: Array[String], label: String) -> void:
	for node_name: String in ["HintScreen", "HintModule", "HintConsole"]:
		assert_eq(_gate(node_name).visible, expected.has(node_name),
			"%s : lueur %s" % [label, node_name])


func _flag(name: StringName) -> bool:
	return GameState.flags.has_flag(name)


func _objective() -> String:
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	return objectives.current(GameState.flags)


## Entrée dans la maison : premier pas vers le nord depuis le paillasson (scène d'accueil).
func _enter_house() -> void:
	await _walk(Vector2i.UP, Vector2i(7, 9))
	await _play_out()


func _arrived(map_id: StringName) -> bool:
	return _boot.get_map().map_id == map_id and not SceneRouter.is_transitioning()


func _face_up() -> void:
	_player.face(Vector2i.UP)


# --- Déroulé complet -----------------------------------------------------------------------

func test_full_scene_in_order_with_rewards_hints_and_objectives() -> void:
	await _start()
	var map := _boot.get_map()
	var player_name := _name()
	assert_not_null(map.get_npc(&"bill_clefairy"), "Léo-Mélofée attend")
	assert_null(map.get_npc(&"bill"), "pas de Léo humain")
	_assert_hints([], "avant la rencontre")
	# Étape 0 : Mélofée se tourne, « ! », sa première réplique ; rien n'est levé.
	await _enter_house()
	assert_eq(_events, [_page(GREET, "Mélofée")] as Array[String])
	assert_false(_flag(&"bill_met"))
	assert_eq(map.get_npc(&"bill_clefairy").get_cell(), Vector2i(6, 5))
	# Avant de lui parler : la console n'a rien à dire de précis.
	await _go([[Vector2i.RIGHT, Vector2i(8, 9)], [Vector2i.UP, Vector2i(8, 4)]])
	_events.clear()
	await _interact()
	assert_eq(_events, [_page(CONSOLE_EARLY)] as Array[String])
	# Étape 1 : PARLER à Mélofée, nom affiché « Mélofée » puis « Léo ».
	await _go([[Vector2i.LEFT, Vector2i(6, 4)]])
	_player.face(Vector2i.DOWN)
	_events.clear()
	await _interact()
	assert_eq(_events[0], _page(INTRO_1, "Mélofée"))
	assert_eq(_events.size(), 5, "cinq répliques (n° 2 à 6)")
	assert_eq(_events[4], _page(INTRO_5, "Léo"))
	assert_true(_flag(&"bill_met"))
	assert_eq(_objective(), "aider Léo.")
	_assert_hints(["HintScreen"], "après la rencontre")
	# Hors d'ordre : module et console renvoient une phrase d'aide.
	await _go([[Vector2i.RIGHT, Vector2i(10, 4)]])
	_face_up()
	_events.clear()
	await _interact()
	assert_eq(_events, [_page(MODULE_HELP)] as Array[String], "module avant l'écran")
	assert_false(_flag(&"bill_module_checked"))
	await _go([[Vector2i.LEFT, Vector2i(8, 4)]])
	_face_up()
	_events.clear()
	await _interact()
	assert_eq(_events, [_page(CONSOLE_HELP)] as Array[String], "console avant le module")
	# Étape 2 : l'écran.
	await _go([[Vector2i.LEFT, Vector2i(5, 4)]])
	_face_up()
	_events.clear()
	await _interact()
	assert_eq(_events, [_page(SCREEN_TEXT), _page(SCREEN_NEXT, "Léo")] as Array[String])
	assert_true(_flag(&"bill_screen_checked"))
	_assert_hints(["HintModule"], "après l'écran")
	# Parler à Mélofée pendant une étape : « Prends ton temps. »
	await _go([[Vector2i.RIGHT, Vector2i(6, 4)]])
	_player.face(Vector2i.DOWN)
	_events.clear()
	await _interact()
	assert_eq(_events, [_page(WAIT_LINE, "Léo")] as Array[String])
	# Étape 3 : le module ; Léo entre dans la cabine A (marche, disparaît).
	await _go([[Vector2i.RIGHT, Vector2i(10, 4)]])
	_face_up()
	_events.clear()
	await _interact()
	assert_eq(_events, [_page(MODULE_TEXT), _page(MODULE_NEXT, "Léo")] as Array[String])
	assert_null(map.get_npc(&"bill_clefairy"), "Léo est dans la cabine")
	assert_true(_flag(&"bill_module_checked"))
	assert_true(_flag(&"bill_in_cabin"))
	assert_false(_flag(&"bill_restored"))
	_assert_hints(["HintConsole"], "Léo dans la cabine")
	# Étape 4 : la console.
	await _go([[Vector2i.LEFT, Vector2i(8, 4)]])
	_face_up()
	_events.clear()
	var candy := GameState.bag.count_of(&"rare_candy")
	var ticket := GameState.bag.count_of(&"ss_ticket")
	await _interact()
	assert_eq(_events[0], _page(CONSOLE_GO))
	assert_eq(_events.slice(1, 3), ["flash:1", "flash:1"] as Array[String], "deux éclairs")
	var thanks := _index(THANKS % player_name, "Léo")
	assert_gt(thanks, 2, "remerciements après les éclairs")
	var ticket_line := _index(TICKET_LINE, "Léo")
	var ticket_caption := _index(TICKET_CAPTION % player_name, "")
	var candy_line := _index(CANDY_LINE, "Léo")
	var candy_caption := _index(CANDY_CAPTION % player_name, "")
	var ss_anne := _index(SS_ANNE, "Léo")
	assert_true(thanks < ticket_line and ticket_line < ticket_caption
		and ticket_caption < candy_line and candy_line < candy_caption
		and candy_caption < ss_anne, "n° 18 à 24 dans l'ordre : %s" % [_events])
	assert_eq(GameState.bag.count_of(&"ss_ticket"), ticket + 1, "Passe Bateau")
	assert_eq(GameState.bag.count_of(&"rare_candy"), candy + 1, "Super Bonbon")
	for flag: StringName in [&"bill_restored", &"got_ss_ticket", &"got_bill_rare_candy"]:
		assert_true(_flag(flag), String(flag))
	var leo := map.get_npc(&"bill")
	assert_not_null(leo, "Léo humain")
	if leo != null:
		assert_eq(leo.get_cell(), Vector2i(12, 5), "devant la cabine B")
	_assert_hints([], "Léo humain")
	assert_eq(_objective(), "le S.S. Anne fait escale à Carmin-sur-Mer.")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# Après : la console est débranchée, l'écran annonce la réussite.
	_events.clear()
	_face_up()
	await _interact()
	assert_eq(_events, [_page(CONSOLE_DEAD)] as Array[String])
	assert_eq(GameState.bag.count_of(&"ss_ticket"), ticket + 1, "une seule fois")
	assert_eq(GameState.bag.count_of(&"rare_candy"), candy + 1, "une seule fois")
	assert_eq(_boot.get_item_library().get_item(&"ss_ticket").category, ItemData.Category.KEY)
	assert_eq(_boot.get_item_library().get_item(&"ss_ticket").contexts(), [] as Array[StringName],
		"aucun usage : jamais consommé")
	await _go([[Vector2i.LEFT, Vector2i(5, 4)]])
	_face_up()
	_events.clear()
	await _interact()
	assert_eq(_events, [_page(SCREEN_DONE)] as Array[String])
	# Léo humain : sa première réplique, toujours la même.
	await _go([[Vector2i.RIGHT, Vector2i(11, 4)], [Vector2i.DOWN, Vector2i(11, 5)]])
	_player.face(Vector2i.RIGHT)
	_events.clear()
	await _interact()
	assert_eq(_events[0], _page(AFTER_1, "Léo"))
	assert_push_error_count(0)


# --- Sortie et retour ----------------------------------------------------------------------

func test_leaving_after_the_module_keeps_the_progress_and_leo_is_in_the_cabin() -> void:
	await _start(START, [&"bill_met", &"bill_screen_checked", &"bill_module_checked",
		&"bill_in_cabin"])
	var map := _boot.get_map()
	assert_null(map.get_npc(&"bill_clefairy"), "absent au retour")
	_assert_hints(["HintConsole"], "au retour")
	# Sortie par le paillasson (poussée vers le sud), puis retour par la porte (un pas au nord).
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(_arrived.bind(&"route_25"), TIMEOUT)
	await wait_process_frames(2)
	var door_front := _player.get_cell()
	await _go([[Vector2i.UP, door_front + Vector2i.UP]])
	await wait_until(_arrived.bind(HOUSE), TIMEOUT)
	await wait_process_frames(2)
	assert_eq(_boot.get_map().map_id, HOUSE, "revenu dans la maison")
	_events.clear()
	await _enter_house()
	assert_eq(_events, [_page(READY, "Léo")] as Array[String], "n° 11")
	assert_true(_flag(&"bill_in_cabin"))
	assert_false(_flag(&"bill_restored"))
	assert_null(_boot.get_map().get_npc(&"bill_clefairy"))
	_assert_hints(["HintConsole"], "après le retour")
	assert_push_error_count(0)


func test_entering_after_the_meeting_plays_nothing() -> void:
	await _start(START, [&"bill_met"])
	_events.clear()
	await _enter_house()
	assert_eq(_events, [] as Array[String], "accueil seulement avant la rencontre")
	assert_not_null(_boot.get_map().get_npc(&"bill_clefairy"))
	assert_push_error_count(0)


# --- Fermeture pendant l'effet ---------------------------------------------------------------

func test_closing_during_the_machine_replays_the_whole_scene_and_gives_once() -> void:
	var cabin_flags: Array[StringName] = [&"bill_met", &"bill_screen_checked",
		&"bill_module_checked", &"bill_in_cabin"]
	await _start(START, cabin_flags)
	var saved := GameState.to_dict()
	await _enter_house()
	await _go([[Vector2i.RIGHT, Vector2i(8, 9)], [Vector2i.UP, Vector2i(8, 4)]])
	_events.clear()
	# La console joue la scène ; on « ferme » dès que Léo est apparu (après les éclairs).
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var box := _boot.get_dialogue_box()
	var map := _boot.get_map()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while map.get_npc(&"bill") == null and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	assert_not_null(map.get_npc(&"bill"), "Léo est apparu")
	assert_false(_flag(&"bill_restored"), "drapeaux de l'étape 4 pas encore levés")
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 0, "rien n'est encore donné")
	assert_eq(_events.count("flash:1"), 2, "les deux éclairs ont eu lieu")
	# Fermeture : la dernière sauvegarde est celle d'avant la scène.
	_boot.queue_free()
	await wait_process_frames(2)
	assert_true(GameState.load_dict(saved, _make_data()), "partie rechargée")
	assert_false(_flag(&"bill_restored"))
	assert_true(_flag(&"bill_in_cabin"))
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 0)
	# Au retour : Léo est dans la cabine, la console attend, la scène se rejoue en entier.
	_events.clear()
	_fs = MemoryFs.new() # nouvelle session : départ de débogage, pas la sauvegarde de la première
	await _start(START, cabin_flags)
	_assert_hints(["HintConsole"], "au retour")
	await _enter_house()
	await _go([[Vector2i.RIGHT, Vector2i(8, 9)], [Vector2i.UP, Vector2i(8, 4)]])
	_events.clear()
	await _interact()
	assert_eq(_events.count("flash:1"), 2, "scène rejouée en entier")
	assert_gte(_events.size(), 9)
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 1, "Passe Bateau une seule fois")
	assert_eq(GameState.bag.count_of(&"rare_candy"), 1, "Super Bonbon une seule fois")
	for flag: StringName in [&"bill_restored", &"got_ss_ticket", &"got_bill_rare_candy"]:
		assert_true(_flag(flag), String(flag))
	assert_not_null(_boot.get_map().get_npc(&"bill"))
	assert_push_error_count(0)


func _make_data() -> PokemonData:
	var data := PokemonData.new()
	data.load_dir()
	return data


# --- Après la scène --------------------------------------------------------------------------

func test_after_start_shows_the_human_leo_and_no_mofee() -> void:
	await _start(AFTER_START)
	var map := _boot.get_map()
	assert_null(map.get_npc(&"bill_clefairy"))
	var leo := map.get_npc(&"bill")
	assert_not_null(leo, "Léo humain dès l'arrivée")
	if leo != null:
		assert_eq(leo.get_cell(), Vector2i(12, 5))
	_assert_hints([], "tout est fait")
	await _enter_house()
	assert_eq(_events, [] as Array[String], "aucune scène d'entrée")
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 1)
	assert_push_error_count(0)


func test_leo_lines_after_the_scene_depend_on_the_rocket_and_the_draw() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir())
	var bill := library.get_dialogue(&"bill")
	var restored := StoryFlags.new()
	restored.set_flag(&"bill_restored")
	# Sans tirage : le Rocket n'est pas battu → cambriolage (n° 26).
	var variant := bill.pick(restored)
	assert_eq(variant.pages.back().text, AFTER_ROCKET)
	assert_eq(variant.pages[0].text, AFTER_1, "n° 25 d'abord")
	# Rocket battu : seulement n° 25.
	restored.set_flag(&"cerulean_rocket_beaten")
	variant = bill.pick(restored)
	assert_eq(variant.pages.size(), 1)
	assert_eq(variant.pages[0].text, AFTER_1)
	# Une fois sur trois : n° 25 puis 27 (tirage gagné), quel que soit le Rocket.
	var win := ScriptedRng.new([1] as Array[int])
	variant = bill.pick(restored, win)
	assert_eq(variant.pages.back().text, AFTER_CHEN)
	var lose := ScriptedRng.new([2] as Array[int])
	variant = bill.pick(restored, lose)
	assert_eq(variant.pages.size(), 1, "tirage perdu : réplique courte")


func test_clefairy_dialogue_variants_by_flag() -> void:
	var library := DialogueLibrary.new()
	library.load_dir()
	var clefairy := library.get_dialogue(&"bill_clefairy")
	var flags := StoryFlags.new()
	assert_eq(clefairy.pick(flags).set_flags, [&"bill_met"] as Array[StringName])
	assert_eq(clefairy.pick(flags).pages.size(), 5)
	flags.set_flag(&"bill_met")
	assert_eq(clefairy.pick(flags).pages[0].text, WAIT_LINE)
	assert_eq(clefairy.pick(flags).pages[0].speaker, "Léo")
