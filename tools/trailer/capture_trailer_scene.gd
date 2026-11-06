extends SceneTree
## Bande-annonce v2 (J34, storyboard `docs/design/storyboard-trailer-v1.md` validé par Kevin le
## 2026-11-04) : chaque scène est **jouée dans le vrai jeu** (Boot sur un départ de débogage,
## HUD tactile caché, pas du joueur simulés, directeurs du jeu appelés directement) et rendue
## en Movie Maker avec le son, puis montée par `tools/trailer/assemble.py` d'après les repères
## « [trailer] » du journal (image, seconde, événement).
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     --write-movie build/trailer/raw/<scène>.avi \
##     -s res://tools/trailer/capture_trailer_scene.gd -- --scene=<scène>
##
## Scènes (plans du storyboard) : `depart` (1 à 5 : chambre, maison, Bourg Palette, Route 1 en
## courant, rencontre et capture d'un Roucool), `rival` (6 à 8 : Route 22, le rival surgit, VS,
## combat au dernier PV), `evolution` (9), `velo` (10), `surf` (11), `selenite` (12), `tour` (13),
## `mewtwo` (14), `ligue` (15), `championne` (16). Série : `tools/trailer/render.sh`.
##
## Les choix de combat sont faits par les signaux de la HUD (comme un toucher) ; les boîtes de
## dialogue et les cartes qui attendent un toucher en reçoivent un simulé. La musique de la
## fenêtre d'enregistrement n'est jamais atténuée (le jeu baisse le son quand il perd le focus).

const STARTS: Dictionary[String, String] = {
	"depart": "trailer_depart",
	"rival": "trailer_rival",
	"evolution": "trailer_evolution",
	"velo": "trailer_velo",
	"surf": "trailer_surf",
	"selenite": "mt_moon_1f",
	"tour": "tower_ghost_qa",
	"mewtwo": "trailer_mewtwo",
	"ligue": "trailer_ligue",
	"championne": "league_champion_charmander",
	# v2.1 (retouches de Kevin du 2026-11-04 : « plus de scènes ») : ville, pont, légendaire de glace.
	"celadopole": "celadon",
	"pont_pepite": "nugget_bridge",
	"artikodin": "trailer_articuno",
	# v3 (`docs/design/storyboard-trailer-v3.md`) : le duo, les costumes, l'ombre.
	"duo": "trailer_v3_duo",
	"marche_origine": "trailer_v3_marche",
	"marche_luffy": "trailer_v3_marche",
	"marche_naruto": "trailer_v3_marche",
	"marche_goku": "trailer_v3_marche",
	"velo_joueuse": "trailer_velo",
	"surf_ironman": "trailer_surf",
	"silhouette": "trailer_v3_marche",
	"ombre": "trailer_v3_ombre",
}
## v3 : tenue portée par scène (identifiants de `data/costumes.json`).
const COSTUMES: Dictionary[String, StringName] = {
	"marche_luffy": &"cascade",
	"marche_naruto": &"soul",
	"marche_goku": &"volcano",
	"velo_joueuse": &"cascade",
	"surf_ironman": &"thunder",
}
## v3 : scènes jouées par la joueuse.
const HEROINE_SCENES: Array[String] = ["velo_joueuse"]
## Place du costume Foudre dans la bande de l'écran Dresseur (tenue d'origine en 0).
const SLOT_THUNDER: int = 3
const ABSENT: String = "user://cap_trailer_absent.json"
const FPS: float = 30.0
## Garde-fou : une scène ne dure jamais plus de 4 minutes.
const MAX_FRAMES: int = 7200
## Toucher simulé : coin haut gauche, loin de toute commande.
const TOUCH_AT := Vector2(12.0, 12.0)
## Cadence des touchers automatiques pendant un dialogue (images).
const AUTO_TOUCH_EVERY: int = 50
const WALK_TIMEOUT: int = 120
## [enum BattleHud.Zone] (la classe lit les autoloads : pas de référence statique ici).
const ZONE_ACTIONS: int = 1
const ZONE_MOVES: int = 2

var _scene: String = "depart"
var _boot: Node
var _state: Node
## Classes du jeu tenues sans type : elles lisent les autoloads, absents à la compilation d'un
## script lancé par `-s`.
var _player: Node
var _battles: Node
var _hud: Node
var _auto_touch: bool = false
var _battle_plan: Array = []
var _finished: bool = false
var _hud_hidden: bool = false


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene = arg.trim_prefix("--scene=")
	if not STARTS.has(_scene):
		push_error("Scène inconnue : %s (%s)" % [_scene, ", ".join(STARTS.keys())])
		quit(1)
		return
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_guard()
	await _boot_scene(STARTS[_scene])
	_dress()
	match _scene:
		"depart": await _depart()
		"rival": await _rival()
		"evolution": await _evolution()
		"velo": await _velo()
		"surf": await _surf()
		"selenite": await _selenite()
		"tour": await _tour()
		"mewtwo": await _mewtwo()
		"ligue": await _ligue()
		"championne": await _championne()
		"celadopole": await _promenade(Vector2i.LEFT, 12)
		"pont_pepite": await _promenade(Vector2i.UP, 14)
		"artikodin": await _legendaire()
		"duo": await _duo()
		"marche_origine", "marche_luffy", "marche_naruto", "marche_goku":
			await _promenade(Vector2i.LEFT, 20)
		"velo_joueuse": await _velo()
		"surf_ironman": await _surf()
		"silhouette": await _silhouette()
		"ombre": await _ombre()
	_mark("fin")
	_finished = true
	quit()


# --- Scènes ------------------------------------------------------------------------------

## Plans 1 à 5 : il descend de sa chambre, traverse la maison, sort, traverse Bourg Palette,
## court sur la Route 1 jusqu'aux herbes, rencontre un Roucool, Flammèche deux fois, Poké Ball.
func _depart() -> void:
	_state.set(&"repel_steps", 2000)  # Aucune rencontre avant celle du scénario.
	_mark("chambre")
	await _wait(40)
	await _walk_to(Vector2i(6, 8))
	await _step_until_map(Vector2i.DOWN, &"player_house_1f")
	_mark("rez-de-chaussée")
	await _wait(20)
	await _walk_to(Vector2i(7, 7))
	await _step_until_map(Vector2i.DOWN, &"pallet_town")
	_mark("perron")
	await _wait(70)
	# Un pas pour quitter le seuil (un chemin qui partirait vers le haut rentrerait).
	await _route_1_capture()


## v3, plans 1 à 3 : le duo devant la maison, la phrase du compagnon, puis la Route 1 et la capture.
func _duo() -> void:
	_state.set(&"repel_steps", 2000)
	_mark("duo")
	await _wait(10)
	# Quitter le seuil, puis marcher de côté : le compagnon se place à côté du joueur, pas derrière.
	await _walk_to(Vector2i(33, 13))
	await _wait(25)
	_mark("côte à côte")
	_boot.call(&"_on_companion_line", &"companion_happy")
	_mark("phrase")
	await _wait(100)
	_touch()
	await _wait(25)
	_mark("en route")
	await _walk_to(Vector2i(23, 2))
	await _route_1_suite()


## Du perron de Bourg Palette à la capture du Roucool (v2 : plans 2 à 5 ; v3 : plans 2 et 3).
func _route_1_capture() -> void:
	await _hold_steps(Vector2i.DOWN, 1)
	await _walk_to(Vector2i(23, 2))
	await _route_1_suite()


func _route_1_suite() -> void:
	await _step_until_map(Vector2i.UP, &"route_1")
	_mark("route 1")
	await _wait(10)
	var grass_steps: Array[int] = [0]
	var encounters: Node = _boot.call(&"get_encounter_director")
	# Vers le nord, aussi loin que le chemin le permet (rebords à sens unique) : on s'arrête aux
	# herbes de toute façon.
	var far_north := _reachable_north(20)
	await _walk_to(far_north, true, func() -> bool:
		if encounters.call(&"terrain_at", _player.call(&"get_cell")) == &"grass":
			grass_steps[0] += 1
		return grass_steps[0] >= 3)
	_mark("herbes")
	await _wait(6)
	# Une Flammèche (Roucool à mi-vie), puis la Poké Ball (de nouveau s'il se libère).
	_battle_plan = [["attack", 0], ["ball", &"poke_ball"], ["ball", &"poke_ball"], ["ball", &"poke_ball"]]
	_drive_battle()
	_auto_touch = true
	var encounter := WildEncounter.new(&"pidgey", 3)
	encounters.call(&"start_encounter", encounter)
	await _until(_battle_running, 300)
	await _until(_battle_over, 5400)
	_mark("combat fini")
	await _wait(50)


## Plans 6 à 8 : Route 22, le rival surgit (scène du jeu), séquence VS, puis Carapuce lance
## Pistolet à O (Salamèche à quelques PV), Salamèche riposte Griffe, Carapuce K.O.
func _rival() -> void:
	_state.set(&"repel_steps", 2000)
	var trainers: RefCounted = _boot.call(&"get_trainer_library")
	var rival: RefCounted = trainers.call(&"get_trainer", &"rival_route22")
	var slot := TrainerSlot.new()
	slot.species = &"squirtle"
	slot.level = 8
	slot.moves = [&"water_gun"] as Array[StringName]
	var team: Array[TrainerSlot] = [slot]
	(rival.get(&"team_by_starter") as Dictionary)[&"charmander"] = team
	# Carapuce entre avec peu de PV : la première Griffe le met K.O. (posé dès l'ouverture du
	# combat, avant le premier tour).
	_battles.connect(&"battle_started", func(_id: StringName) -> void:
		await process_frame
		var battle: RefCounted = _battles.call(&"get_battle")
		if battle != null:
			var side: RefCounted = battle.call(&"get_foe_side")
			var foe: RefCounted = side.get(&"party").call(&"get_at", 0)
			foe.set(&"hp", 6)
			_mark("carapuce à %d PV" % int(foe.get(&"hp"))), CONNECT_ONE_SHOT)
	_battle_plan = [["attack", 1], ["attack", 0], ["attack", 0]]
	_drive_battle()
	_auto_touch = true
	_mark("route 22")
	await _wait(30)
	await _walk_to(Vector2i(15, 13))
	await _wait(8)
	await _press(Vector2i.LEFT, 12)
	await _until(_battle_running, 2400)
	await _until(_battle_over, 5400)
	_mark("combat fini")
	await _wait(120)


## Plan 9 : Salamèche évolue en Reptincel (écran d'évolution du jeu, jingle).
func _evolution() -> void:
	_auto_touch = true
	await _wait(30)
	var party: RefCounted = _state.get(&"party")
	var candidate := EvolutionCandidate.new(0, &"charmander", &"charmeleon")
	candidate.cancellable = false
	var director: Node = _boot.call(&"get_evolution_director")
	director.call(&"play", [candidate] as Array[EvolutionCandidate], party)
	_mark("évolution")
	await _wait(10)
	await _until(func() -> bool: return not bool(director.call(&"is_playing")), 3600)
	_mark("évolution finie")
	await _wait(40)


## Plan 10 : Piste Cyclable, vélo lancé plein sud.
func _velo() -> void:
	_player.call(&"set_mount", 1)  # Mount.Kind.BIKE
	await _wait(20)
	_mark("vélo")
	await _press(Vector2i.DOWN, 300)
	await _wait(10)


## Plan 11 : Route 19, Surf depuis la plage, puis sur l'eau.
func _surf() -> void:
	_mark("plage")
	await _hold_steps(Vector2i.DOWN, 22)
	await _wait(40)
	var mounts: Node = _boot.call(&"get_mount_director")
	var check: int = mounts.call(&"start_surf")
	_mark("surf → %d" % check)
	await _wait(60)
	await _press(Vector2i.DOWN, 150)
	await _press(Vector2i.LEFT, 90)
	await _wait(10)


## Plan 12 : Mont Sélénite, entre les lampes.
func _selenite() -> void:
	_state.set(&"repel_steps", 2000)
	_mark("mont sélénite")
	await _wait(20)
	await _walk_to(Vector2i(29, 33))
	await _wait(20)


## Plan 13 : Tour Pokémon, un SPECTRE surgit.
func _tour() -> void:
	_auto_touch = true
	_mark("tour")
	await _wait(20)
	await _hold_steps(Vector2i.RIGHT, 6)
	await _until(_battle_running, 600)
	_mark("spectre")
	await _until(_actions_shown, 1200)
	await _wait(45)


## Plan 14 : Grotte Azurée, Mewtwo (cri, entrée légendaire au ralenti).
func _mewtwo() -> void:
	_auto_touch = true
	_mark("mewtwo")
	await _wait(40)
	Input.action_press(&"interact")
	await _wait(3)
	Input.action_release(&"interact")
	await _until(_battle_running, 900)
	_mark("entrée légendaire")
	await _until(_actions_shown, 1800)
	await _wait(45)


## Plan 15 : fin de la Route 23, montée vers la Ligue, les portes.
func _ligue() -> void:
	_mark("route 23")
	await _wait(30)
	await _step_until_map(Vector2i.UP, &"indigo_plateau")
	_mark("plateau indigo")
	await _wait(20)
	await _walk_to(Vector2i(9, 6))
	await _step_until_map(Vector2i.UP, &"indigo_plateau_lobby")
	_mark("hall")
	await _wait(90)


## Plan 16 : salle du Maître, la Championne, banderole VS.
func _championne() -> void:
	_state.set(&"rival_look", &"rivale")
	_state.set(&"rival_name", "Rose")
	_auto_touch = true
	_mark("salle du maître")
	await _wait(40)
	await _press(Vector2i.UP, 14)
	await _until(_battle_running, 2400)
	_mark("combat")
	await _until(_actions_shown, 2400)
	await _wait(45)


## Plans de réserve (v2.1) : quelques pas dans un lieu, caméra qui suit.
func _promenade(direction: Vector2i, steps: int) -> void:
	_state.set(&"repel_steps", 2000)
	_auto_touch = true
	_mark("promenade")
	await _wait(30)
	await _hold_steps(direction, steps)
	await _wait(30)


## Légendaire (Artikodin, Îles Écume B4F en (6, 1)) : le joueur le rejoint, lui fait face,
## interaction, cri, entrée légendaire du combat.
func _legendaire() -> void:
	_state.set(&"repel_steps", 2000)
	_auto_touch = true
	_mark("légendaire")
	await _wait(30)
	await _walk_to(Vector2i(6, 2))
	await _press(Vector2i.UP, 3)
	await _wait(20)
	Input.action_press(&"interact")
	await _wait(3)
	Input.action_release(&"interact")
	await _until(_battle_running, 900)
	_mark("entrée légendaire")
	await _until(_actions_shown, 1800)
	await _wait(45)


## v3 : apparence de la scène, posée après le départ de débogage (qui n'en a pas la clé).
func _dress() -> void:
	if HEROINE_SCENES.has(_scene):
		_state.set(&"player_look", &"heroine")
	if COSTUMES.has(_scene):
		_state.call(&"wear_costume", COSTUMES[_scene])
	_player.call(&"refresh_look")


## v3, plan 10 : écran Dresseur, la silhouette du costume Foudre s'allume et le portrait la porte.
func _silhouette() -> void:
	var menu: Node = _boot.call(&"get_menu_director")
	var trainer_menu: Node = _boot.call(&"get_trainer_menu")
	trainer_menu.set(&"speed_scale", 0.0)
	var flags: Object = _state.get(&"flags")
	flags.call(&"set_flag", &"badge_thunder", false)
	flags.call(&"set_flag", &"badge_boulder", false)
	menu.call(&"open", (load("res://game/systems/menu/menu_route.gd") as GDScript).call(&"trainer"))
	await _wait(60)
	_mark("silhouettes")
	var screen: Node = trainer_menu.call(&"get_trainer")
	var slots: Array = screen.call(&"get_costume_slots")
	var art: Control = slots[SLOT_THUNDER].call(&"get_art")
	var tween: Tween = screen.create_tween()
	tween.tween_property(art, ^"modulate", Color.WHITE, 0.5)
	await _wait(10)
	_mark("allumage")
	await _wait(10)
	var portrait: TextureRect = screen.call(&"get_portrait")
	portrait.texture = (load("res://game/ui/menu/menu_art.gd") as GDScript).call(&"bust_for",
		&"hero", &"thunder")
	(screen.get(&"_costume_caption") as Label).text = "Nouveau costume : Iron Man"
	(screen.get(&"_costume_caption") as Label).visible = true
	await _wait(90)


## v3, plan 19 : grotte marine, l'ombre passe sous l'eau, personne à l'écran. Même déplacement que
## la scène du jeu `sea_cave_lugia_shadow` (11 cases en 4 s, en fondu), sans ses dialogues.
func _ombre() -> void:
	var shadow: Node2D = _boot.find_child("LugiaShadow", true, false)
	_player.visible = false
	# La caméra suit le joueur : détachée ici, elle cadre l'eau, joueur caché.
	var camera: Camera2D = _player.call(&"get_camera")
	camera.top_level = true
	camera.position_smoothing_enabled = false
	camera.global_position = shadow.global_position + Vector2(528.0, 48.0)
	await _wait(45)
	_mark("eau calme")
	# Plus grande que dans le jeu (×2,5), elle traverse toute l'eau à l'image.
	shadow.visible = true
	shadow.scale = Vector2(2.5, 2.5)
	shadow.position.x -= 1000.0
	shadow.modulate = Color(0.0, 0.0, 0.0, 1.0)
	var tween: Tween = shadow.create_tween()
	tween.tween_property(shadow, ^"position:x", shadow.position.x + 3000.0, 4.0)
	_mark("ombre")
	await _wait(150)


# --- Lancement ---------------------------------------------------------------------------

func _boot_scene(start: String) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", "res://tools/debug_start/%s.json" % start)
	_boot.set(&"force_debug_start", true)
	_boot.set(&"debug_unlocks_path", ABSENT)
	root.add_child(_boot)
	_state = root.get_node(^"GameState")
	_state.set(&"player_name", "Kevin")
	_state.set(&"rival_name", "Régis")
	_player = _boot.call(&"get_player")
	_battles = _boot.call(&"get_battle_director")
	_hud = _boot.call(&"get_battle_hud")
	_hud.set(&"haptics_enabled", false)
	_watch()
	_keep_audio_up()
	_auto_toucher()
	# Le fondu d'arrivée bloque les entrées pendant une demi-seconde.
	await _wait(75)
	var hud: CanvasLayer = _boot.call(&"get_hud")
	if hud != null:
		hud.visible = false
	_hud_hidden = true
	_mark("départ %s, case %s" % [start, _player.call(&"get_cell")])


## Repères du journal : carte, rencontres, événements de combat, évolution, montures.
func _watch() -> void:
	var router: Node = root.get_node(^"SceneRouter")
	router.connect(&"map_changed", func(map: Node) -> void: _mark("carte %s" % map.get(&"map_id")))
	var encounters: Node = _boot.call(&"get_encounter_director")
	encounters.connect(&"encounter_started", func(species: StringName, level: int) -> void:
		_mark("rencontre %s N%d" % [species, level]))
	_battles.connect(&"battle_started", func(id: StringName) -> void: _mark("combat %s" % id))
	_battles.connect(&"vs_started", func(foe_name: String, title: String) -> void:
		_mark("VS %s — %s" % [foe_name, title]))
	_battles.connect(&"trainer_intro_step", func(step: int) -> void: _mark("entrée étape %d" % step))
	_battles.connect(&"event_played", func(event: RefCounted) -> void:
		_mark("événement %s %s %s PV %d/%d" % [BattleEvent.Kind.find_key(event.get(&"kind")),
			event.get(&"pokemon_name"), event.get(&"move_id"), event.get(&"hp"), event.get(&"max_hp")]))
	_battles.connect(&"battle_finished", func(id: StringName, outcome: int) -> void:
		_mark("combat fini %s → %d" % [id, outcome]))
	var evolutions: Node = _boot.call(&"get_evolution_director")
	evolutions.connect(&"evolution_started", func(_i: int, into: StringName) -> void:
		_mark("évolution vers %s" % into))
	evolutions.connect(&"evolution_finished", func(_i: int, into: StringName, _c: bool) -> void:
		_mark("évolution finie %s" % into))
	var mounts: Node = _boot.call(&"get_mount_director")
	mounts.connect(&"surf_mounted", func() -> void: _mark("surf monté"))
	var cutscenes: Node = _boot.call(&"get_cutscene_director")
	cutscenes.connect(&"cutscene_started", func(id: StringName) -> void: _mark("scène %s" % id))
	cutscenes.connect(&"cutscene_finished", func(id: StringName) -> void: _mark("scène finie %s" % id))


func _mark(label: String) -> void:
	var frame := Engine.get_process_frames()  # = image de la vidéo (une par tour de boucle)
	print("[trailer] %5d %7.2f %s" % [frame, frame / FPS, label])


## La fenêtre d'enregistrement n'a pas le focus : le jeu baisserait la musique (ducking voulu
## en jeu) ; on le lève à chaque image.
func _keep_audio_up() -> void:
	var audio: Node = root.get_node(^"Audio")
	while not _finished:
		if bool(audio.call(&"is_focus_ducked")):
			audio.call(&"_set_focus_ducked", false)
		# Le HUD d'exploration se remontre de lui-même (annonce de zone) : caché à chaque image,
		# et tout autre HUD d'exploration présent dans l'arbre avec lui.
		if _hud_hidden:
			for hud: Node in root.find_children("*", "ExplorationHud", true, false):
				if (hud as CanvasLayer).visible:
					(hud as CanvasLayer).visible = false
		await process_frame


## Toucher simulé toutes les [constant AUTO_TOUCH_EVERY] images tant qu'une boîte de dialogue,
## une carte de capture ou un message qui attend le toucher est ouvert.
func _auto_toucher() -> void:
	var box: Node = _boot.call(&"get_dialogue_box")
	var countdown := AUTO_TOUCH_EVERY
	while not _finished:
		await process_frame
		if not _auto_touch:
			continue
		var waiting: bool = box != null and bool(box.call(&"is_open"))
		if not waiting:
			var card: Node = _battles.call(&"get_capture_card")
			waiting = card != null and bool(card.get(&"visible"))
		if not waiting and _hud != null:
			var banner: Node = _hud.call(&"get_message_banner")
			waiting = banner != null and bool(banner.call(&"is_waiting"))
		if not waiting:
			var summary: Node = _battles.call(&"get_summary_card")
			waiting = summary != null and bool(summary.get(&"visible"))
		if not waiting:
			var evolutions: Node = _boot.call(&"get_evolution_director")
			var screen: Node = evolutions.call(&"get_screen")
			waiting = screen != null and bool(screen.call(&"is_waiting_touch"))
		if not waiting:
			countdown = AUTO_TOUCH_EVERY
			continue
		countdown -= 1
		if countdown <= 0:
			countdown = AUTO_TOUCH_EVERY
			_touch()


func _touch() -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = TOUCH_AT
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = TOUCH_AT
	up.pressed = false
	Input.parse_input_event(up)


## Joue les choix de [member _battle_plan] dès que la HUD les propose (grille d'actions, puis
## capacité ou Sac), avec un court temps où la grille reste visible.
func _drive_battle() -> void:
	while not _finished and not _battle_plan.is_empty():
		await _until(_actions_shown, 7200)
		if _finished:
			return
		await _wait(24)
		var choice: Array = _battle_plan.pop_front()
		# Les choix passent par les gestionnaires des boutons (comme un toucher) : la grille ou
		# le Sac se ferment d'eux-mêmes.
		var actions: Node = _hud.get(&"_actions")
		if choice[0] == "attack":
			actions.call(&"_on_pressed", &"attack")  # ActionGrid.ATTACK
			await _until(func() -> bool: return int(_hud.call(&"get_zone")) == ZONE_MOVES, 300)
			await _wait(18)
			_mark("choix capacité %d" % int(choice[1]))
			(_hud.get(&"_moves") as Node).call(&"_choose", int(choice[1]))
		else:
			actions.call(&"_on_pressed", &"bag")  # ActionGrid.BAG
			await _until(func() -> bool:
				var panel: Node = _battles.call(&"get_bag_panel")
				return panel != null and bool(panel.get(&"visible")) \
					and not bool(panel.call(&"is_sliding")), 300)
			await _wait(24)
			_mark("choix objet %s" % choice[1])
			var bag: Node = _battles.call(&"get_bag_panel")
			bag.call(&"select_item", StringName(choice[1]))
			await _wait(10)
			bag.call(&"_on_action")
		await _until(func() -> bool: return not _actions_shown.call(), 300)


# --- Déplacements ------------------------------------------------------------------------

## Marche (ou court) jusqu'à [param target] par le plus court chemin du monde. Le joueur
## enchaîne le pas suivant dans l'image même où un pas finit : la direction suivante est donc
## posée (ou relâchée, au dernier pas) **pendant** le pas en cours, dès qu'il est parti vers la
## case attendue ; replanifie si un pas ne part pas (PNJ sur le chemin). [param stop] : appelée à
## chaque pas parti, vrai pour s'arrêter sur sa case.
func _walk_to(target: Vector2i, running: bool = false, stop: Callable = Callable()) -> bool:
	var map: Node = _boot.call(&"get_map")
	var grid: RefCounted = map.call(&"get_grid")
	if running:
		Input.action_press(&"run")
	var ok := false
	for attempt: int in 4:
		await _until(_still, 60)
		var path: Array = grid.call(&"find_path", _cell(), target, _player)
		if path.is_empty():
			ok = _cell() == target
			if not ok:
				_mark("aucun chemin de %s vers %s" % [_cell(), target])
			break
		var result := await _follow(path, stop)
		if result != "blocked":
			ok = true
			break
		_mark("pas bloqué en %s, nouveau chemin" % _cell())
	if running:
		Input.action_release(&"run")
	await _until(_still, 60)
	_mark("arrivé en %s (visé %s)" % [_cell(), target])
	return ok


## Suit [param path] (directions) en tenant la direction courante ; "done", "stopped" ou
## "blocked".
func _follow(path: Array, stop: Callable = Callable()) -> String:
	var at: Vector2i = _cell()
	var held: StringName = &""
	var result := "done"
	for i: int in path.size():
		var direction: Vector2i = path[i]
		var action := _action_of(direction)
		if held != action:
			if not held.is_empty():
				Input.action_release(held)
			Input.action_press(action)
			held = action
		var expected := at + direction
		var started := await _until(func() -> bool: return _target_cell() == expected, WALK_TIMEOUT)
		if not started:
			result = "blocked"
			break
		at = expected
		if stop.is_valid() and bool(stop.call()):
			result = "stopped"
			break
		# Le pas est parti : la suite se décide maintenant, avant qu'il finisse.
		if i == path.size() - 1:
			break
		var next_action := _action_of(path[i + 1])
		if next_action != held:
			Input.action_release(held)
			Input.action_press(next_action)
			held = next_action
	if not held.is_empty():
		Input.action_release(held)
	return result


## La case la plus au nord atteignable à pied depuis la case du joueur, cherchée colonne par
## colonne autour de la sienne jusqu'à [param max_rows] rangées plus haut ; sa case si aucune.
func _reachable_north(max_rows: int) -> Vector2i:
	var map: Node = _boot.call(&"get_map")
	var grid: RefCounted = map.call(&"get_grid")
	var from := _cell()
	for rows: int in range(max_rows, 2, -1):
		for dx: int in [0, 1, -1, 2, -2, 3, -3]:
			var target := Vector2i(from.x + dx, from.y - rows)
			var path: Array = grid.call(&"find_path", from, target, _player)
			if not path.is_empty():
				return target
	return from


## Tient la direction [param direction] pendant [param frames] images.
func _press(direction: Vector2i, frames: int) -> void:
	var action := _action_of(direction)
	Input.action_press(action)
	await _wait(frames)
	Input.action_release(action)
	await _until(_still, 60)


## Avance de [param steps] cases dans [param direction] (ou jusqu'à un blocage), sans dépasser.
func _hold_steps(direction: Vector2i, steps: int) -> void:
	var path: Array = []
	for _i: int in steps:
		path.append(direction)
	await _follow(path)
	await _until(_still, 60)


## Avance dans [param direction] jusqu'à l'arrivée sur la carte [param map_id] (passage d'une
## porte ou d'un bord), puis attend la fin du fondu.
func _step_until_map(direction: Vector2i, map_id: StringName) -> void:
	var action := _action_of(direction)
	Input.action_press(action)
	await _until(func() -> bool:
		var map: Node = _boot.call(&"get_map")
		return map != null and map.get(&"map_id") == map_id, 400)
	Input.action_release(action)
	await _wait(45)


static func _action_of(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP: return &"move_up"
		Vector2i.DOWN: return &"move_down"
		Vector2i.LEFT: return &"move_left"
	return &"move_right"


# --- Attentes ----------------------------------------------------------------------------

func _cell() -> Vector2i:
	return _player.call(&"get_cell")


func _still() -> bool:
	return not bool(_player.call(&"is_moving"))


## Case visée par le pas en cours (la case du joueur à l'arrêt).
func _target_cell() -> Vector2i:
	return (_player.get(&"_mover") as RefCounted).call(&"get_target_cell")


func _battle_running() -> bool:
	return bool(_battles.call(&"is_running"))


func _battle_over() -> bool:
	return not _battle_running()


## La grille d'actions du combat est affichée (BattleHud.Zone.ACTIONS).
func _actions_shown() -> bool:
	return int(_hud.call(&"get_zone")) == ZONE_ACTIONS


func _wait(frames: int) -> void:
	for _i: int in frames:
		await process_frame


func _until(done: Callable, frames: int) -> bool:
	for _i: int in frames:
		if bool(done.call()):
			return true
		await process_frame
	return false


func _guard() -> void:
	await _wait(MAX_FRAMES)
	if not _finished:
		_mark("garde-fou : scène trop longue")
		_finished = true
		quit(2)
