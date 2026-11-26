class_name BootWorld
extends Node
## Domaine « monde » de [Boot] : déplacements et systèmes de terrain.
##
## Glissades forcées (dalles tournantes, courants), ascenseurs, téléporteurs et portes à carte,
## Vol, Téléport et Tunnel, grottes et Corde Sortie, Flash, monture et objets clés, pêche, Force,
## Parc Safari, puzzles d'interrupteurs.
##
## Extrait de `boot.gd` sans changer le comportement : Boot crée ce nœud au début de son `_ready`,
## appelle chaque `setup_*` au même moment qu'avant le découpage (l'ordre des branchements sur
## le pas du joueur et sur le routeur compte), et relaie ses accesseurs publics. Les directeurs
## créés ici restent des enfants directs de Boot (mêmes noms, mêmes modes de traitement).

## Narration de la Corde Sortie (jalon 12, dossier 15 §20 n° 33) :
## `data/dialogues/field_items.json`.
const ESCAPE_ROPE_DIALOGUE: StringName = &"escape_rope_used"

var _boot: Boot
## J20 (T19, `jalon-20.md` §2.4.4) : dalles tournantes du repaire (glisse, verrou, reprise).
var _forced_slide: ForcedSlideDirector
## J20 (T13, `jalon-20.md` §2.3) : ascenseurs (cabine, panneau, trajet, position sauvée).
var _elevators := ElevatorLibrary.new()
var _elevator_panel: ElevatorPanel
## Le panneau de la cabine a été demandé (`open_elevator`) : ouvert à la fin du dialogue.
var _pending_elevator: bool = false
## Passe systèmes 2 (S2F) : portes à carte.
var _key_doors: KeyDoorDirector
## Passe systèmes 2 (S2E) : Vol, puis Téléport et Tunnel hors combat.
var _fly: FlyDirector
var _field_travel: FieldTravelDirector
## Passe systèmes 2 (S2B) : monture (Vélo) et objets clés utilisables (Bicyclette, Poké Flûte).
var _mount: MountDirector
var _key_items: KeyItemDirector
## Passe systèmes 2 (S2C-bis) : pêche.
var _fishing: FishingDirector
## Passe systèmes 2 (S2D) : Force.
var _strength: StrengthDirector
## J23 : visite du Parc Safari.
var _safari: SafariDirector
## Puzzles d'interrupteurs (jalon 16, Arène de Carmin) : data/world/switch_puzzles.json.
var _switch_puzzles := SwitchPuzzleLibrary.new()
## Puzzle de la carte courante (identifiant → [SwitchPuzzle]) : créé à la première fouille, oublié
## à chaque arrivée sur une carte (état jamais sauvegardé, nouveau tirage au retour).
var _active_puzzles: Dictionary[StringName, SwitchPuzzle] = {}


func _init(boot: Boot = null) -> void:
	_boot = boot


# --- Accesseurs (relayés par Boot) -------------------------------------------------------------

func get_forced_slide_director() -> ForcedSlideDirector:
	return _forced_slide


func get_elevator_panel() -> ElevatorPanel:
	return _elevator_panel


func get_key_door_director() -> KeyDoorDirector:
	return _key_doors


func get_fly_director() -> FlyDirector:
	return _fly


func get_field_travel_director() -> FieldTravelDirector:
	return _field_travel


func get_mount_director() -> MountDirector:
	return _mount


func get_key_item_director() -> KeyItemDirector:
	return _key_items


func get_fishing_director() -> FishingDirector:
	return _fishing


func get_strength_director() -> StrengthDirector:
	return _strength


func get_safari_director() -> SafariDirector:
	return _safari


## Puzzle d'interrupteurs en cours sur la carte (tests, QA) ; null s'il n'a pas encore été fouillé.
func get_active_puzzle(puzzle_id: StringName) -> SwitchPuzzle:
	return _active_puzzles.get(puzzle_id)


## Arrivée sur une carte : les puzzles tirés sur la carte précédente sont oubliés.
func clear_active_puzzles() -> void:
	_active_puzzles.clear()


## Vrai si SURFER est possible devant le joueur (même s'il voit PÊCHER).
func can_surf_ahead() -> bool:
	var player := _boot.get_player()
	var target := _mount.surf_target(player.get_cell(), player.get_facing())
	return target != null and target.kind == Interaction.Kind.SURF


## Fin d'un dialogue : vrai si le panneau d'ascenseur demandé par ce dialogue vient d'être ouvert
## (une seule fois par demande).
func open_pending_elevator() -> bool:
	if not _pending_elevator:
		return false
	_pending_elevator = false
	_boot.get_elevator_director().open_panel()
	return true


# --- Glissades forcées (J20 T19, passe systèmes 2 T15) ------------------------------------------

## Directeur des glissades forcées (dalles tournantes, courants du Surf), branché sur le pas du
## joueur **avant** tout autre écouteur (directeur de scènes, Dresseurs, rencontres, routeur) : le
## pas qui lance une glissade bloque le joueur avant qu'ils ne le voient.
func setup_forced_slides() -> void:
	_forced_slide = ForcedSlideDirector.new()
	_forced_slide.name = "ForcedSlideDirector"
	_forced_slide.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_forced_slide)
	_forced_slide.setup(_boot.get_player(), _boot.get_trainer_watcher())
	_forced_slide.slide_started.connect(_on_cue_started.unbind(1))
	_forced_slide.slide_finished.connect(_on_cue_finished.unbind(1))
	_forced_slide.warp_reached.connect(_on_forced_slide_warp_reached)


## Courant fini sur un passage : suivi comme un pas libre (verrou de la glissade déjà levé).
func _on_forced_slide_warp_reached(cell: Vector2i, direction: Vector2i) -> void:
	if not SceneRouter.follow_warp_at(cell, direction):
		push_error("Boot : aucun passage à suivre en %s au bout du courant" % cell)


## Début d'une glissade ou d'un trajet d'ascenseur : le compagnon rentre, contrôles cachés.
func _on_cue_started() -> void:
	_boot.get_companion_controller().on_cutscene_started()
	_boot.refresh_controls()


func _on_cue_finished() -> void:
	_boot.get_companion_controller().on_cutscene_finished()
	_boot.refresh_controls()


# --- Ascenseurs (J20 T13) ----------------------------------------------------------------------

## Ascenseurs (`data/world/elevators.json`), directeur (créé par Boot avant les réglages), écran du
## panneau ; le dialogue du panneau (`open_elevator`) l'ouvre à sa fin, comme la Boutique.
func setup_elevators() -> void:
	if not _elevators.load_file():
		for error: String in _elevators.get_errors():
			push_error("Boot : %s" % error)
	var elevator := _boot.get_elevator_director()
	elevator.setup(_elevators, GameState, _boot.get_player(), _boot.get_dialogue_runner(),
		_boot.get_fade())
	elevator.spawn_cell_source = _boot.spawn_cell
	_elevator_panel = ElevatorPanel.new()
	_elevator_panel.name = "ElevatorPanel"
	var settings := _boot.get_settings()
	if settings != null:
		_elevator_panel.reduce_motion = settings.reduce_motion
	_elevator_panel.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_elevator_panel)
	elevator.set_panel(_elevator_panel)
	elevator.ride_started.connect(_on_cue_started.unbind(1))
	elevator.ride_finished.connect(_on_cue_finished.unbind(1))
	elevator.panel_opened.connect(_boot.refresh_controls.unbind(1))
	elevator.panel_closed.connect(_boot.refresh_controls)
	_boot.get_service_director().elevator_requested.connect(_on_elevator_requested)


## « open_elevator » (le panneau de la cabine) : il s'ouvre à la fin du dialogue.
func _on_elevator_requested() -> void:
	_pending_elevator = true


# --- Téléporteurs et portes à carte (passe systèmes 2, S2F) -------------------------------------

## Téléporteurs (`systemes-2.md` §2.9) : à la fin d'un replacement sur la même carte, le compagnon
## ressort comme après l'écran « à venir ». Portes à carte (§2.10) : [KeyDoorDirector] répond à
## l'appui OUVRIR. Un seul bloc, déconnecté à la sortie par le directeur lui-même.
func setup_teleporters() -> void:
	_key_doors = KeyDoorDirector.new()
	_key_doors.name = "KeyDoorDirector"
	_key_doors.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_key_doors)
	_key_doors.setup(GameState.flags, GameState.bag, _boot.get_player(),
		_boot.get_dialogue_runner(), SceneRouter.get_current_map, _boot.request_autosave)
	_boot.get_interaction_controller().door_requested.connect(_key_doors.on_door_requested)
	var boot := _boot
	var on_relocated := func(map: GameMap) -> void: boot.finish_same_map_transition(map)
	SceneRouter.relocated.connect(on_relocated)
	_key_doors.tree_exiting.connect(func() -> void:
		if SceneRouter.relocated.is_connected(on_relocated):
			SceneRouter.relocated.disconnect(on_relocated))


# --- Vol (passe systèmes 2, S2E) ---------------------------------------------------------------

## Vol (`systemes-2.md` §2.8, T24–T25) : destinations de `fly_points.json`, bouton « S'ENVOLER »
## de la Carte (Q-4), menu fermé puis [FlyDirector].
func setup_fly() -> void:
	var runner := _boot.get_dialogue_runner()
	var zones := _boot.get_zone_library()
	var menu := _boot.get_menu_director()
	var menu_screen := _boot.get_trainer_menu()
	var rules := FlyRules.new()
	rules.load_file()
	rules.stamp_regions(zones) # JOH0 : la région de chaque destination
	_fly = FlyDirector.new()
	_fly.name = "FlyDirector"
	_fly.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_fly)
	_fly.setup(rules, func() -> Dictionary: return GameState.discovered_maps,
		func(move: StringName) -> Variant: return runner.field_source.call(move),
		_boot.get_caves(), SceneRouter.get_current_map, _boot.get_player(), runner, SceneRouter,
		_boot.get_companion_controller())
	# JOH0 (JH-18) : pas de Vol entre Kanto et Johto pendant l'acte 1.
	_fly.region_source = zones.region_of
	_fly.cross_source = func() -> bool: return not TeamConfiscation.is_act1(GameState.flags)
	# Animation du Vol (2026-11-19) : porteur, ciel du trajet, son de l'envol.
	_fly.overlay = _boot.get_dragon_flight_overlay()
	_fly.carrier_source = _fly_carrier_info
	_fly.sfx = func(id: StringName) -> void: Audio.play_sfx(id)
	_fly.reduce_motion = _boot.get_settings().reduce_motion
	_fly.flight_started.connect(func(_zone: StringName) -> void:
		_fly.reduce_motion = _boot.get_settings().reduce_motion)
	menu.set_fly_check(_fly.can_fly_to)
	menu.fly_requested.connect(func(zone: StringName) -> void:
		menu.close()
		_fly.fly(zone))
	if menu_screen.has_signal(&"map_fly_requested"):
		menu_screen.map_fly_requested.connect(menu.request_fly)
	_fly.flight_started.connect(_boot.refresh_controls.unbind(1))
	_fly.flight_finished.connect(_boot.refresh_controls.unbind(1))


## Le porteur du Vol : espèce et artwork du Pokémon d'équipe [param index] ; {} sans lui.
func _fly_carrier_info(index: int) -> Dictionary:
	var member := GameState.party.get_at(index) if index >= 0 else null
	if member == null:
		return {}
	var species := _boot.get_pokemon_data().get_species(member.species_id)
	var artwork := PokedexArt.portrait(species.dex) if species != null else null
	return {"species": member.species_id, "artwork": artwork}


# --- Téléport et Tunnel hors combat (passe systèmes 2, S2E, T25b) -------------------------------

## Téléport (au point du réveil, sans soin) et Tunnel (sortie de grotte, comme la Corde Sortie) :
## UTILISER sous la fiche de la capacité dans l'Équipe, menu fermé puis [FieldTravelDirector].
func setup_field_travel() -> void:
	var menu := _boot.get_menu_director()
	var menu_screen := _boot.get_trainer_menu()
	_field_travel = FieldTravelDirector.new()
	_field_travel.name = "FieldTravelDirector"
	_field_travel.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_field_travel)
	_field_travel.setup(_boot.field_state, _boot.get_defeat_recovery().wakeup_point,
		_boot.get_caves(), SceneRouter.get_current_map, _boot.get_player(),
		_boot.get_dialogue_runner(), SceneRouter, _boot.get_companion_controller())
	menu.set_field_travel_check(_field_travel.check)
	menu.field_travel_requested.connect(func(move: StringName) -> void:
		menu.close()
		_field_travel.travel(move))
	if menu_screen.has_signal(&"team_field_move_requested"):
		menu_screen.team_field_move_requested.connect(menu.request_field_travel)
		menu.team_notice_shown.connect(menu_screen.show_team_notice)
	_field_travel.travel_started.connect(_boot.refresh_controls.unbind(1))
	_field_travel.travel_finished.connect(_boot.refresh_controls.unbind(1))


# --- Capacités de terrain et objets du monde (après le compagnon) ------------------------------

## Grottes, Flash, monture et objets clés, pêche, Parc Safari et Force, dans cet ordre (celui
## d'avant le découpage : la pêche se branche après les objets clés, le Safari après le Vol).
func setup_field_systems() -> void:
	_setup_caves()
	_setup_flash()
	_setup_mount()
	_setup_fishing()
	_setup_safari()
	_setup_strength()


## Grottes (`data/world/caves.json`) et UTILISER d'un objet AVENTURE sans cible (la Corde
## Sortie) : le Sac la refuse hors grotte, sinon elle est jouée ([method _on_field_item_requested]).
func _setup_caves() -> void:
	var caves := _boot.get_caves()
	if not caves.load_file(_boot.caves_path):
		for error: String in caves.get_errors():
			push_error("Boot : %s" % error)
	var menu := _boot.get_menu_director()
	menu.set_caves(caves, _boot.current_map_id)
	menu.field_item_requested.connect(_on_field_item_requested)


## Corde Sortie acceptée par le Sac (jalon 12, dossier 15 §11, `jalon-12.md` §2.6) : menu fermé,
## « Tu utilises la Corde Sortie. », puis la Corde est retirée **dans la même image** que le
## départ du fondu vers l'entrée de la grotte (comme une porte) — aucune image stable entre les
## deux : l'autosave suivant est celui de l'arrivée (position et Sac ensemble) ; une fermeture
## pendant le fondu laisse la sauvegarde d'avant, Corde comprise. Ni soin ni point de repos.
func _on_field_item_requested(item_id: StringName) -> void:
	var item := _boot.get_item_library().get_item(item_id)
	# J17 (§2.3) : la case du joueur choisit la bouche d'une grotte à deux bouches.
	var exit := FieldItemRules.escape_target(_boot.current_map_id(), _boot.get_caves(),
		_boot.get_player().get_cell())
	if item == null or exit == null or not GameState.bag.has(item_id):
		return
	_boot.get_menu_director().close()
	var runner := _boot.get_dialogue_runner()
	if runner.play(ESCAPE_ROPE_DIALOGUE, null, SceneRouter.get_current_map()):
		await runner.dialogue_finished
	GameState.bag.remove(item_id, 1)
	SceneRouter.change_map(exit.map, exit.spawn, exit.facing)


## [FlashDirector] (J17 T24) : état de Flash lu dans la partie (CS05 au Sac, compatible, compagnon
## d'abord), action d'arrivée seulement sur une partie stable, hors écran titre.
func _setup_flash() -> void:
	var flash := _boot.get_flash_director()
	var field_moves := _boot.get_field_moves()
	var items := _boot.get_item_library()
	var pokemon := _boot.get_pokemon_data()
	flash.setup(GameState, _boot.get_darkness(), _boot.get_caves(), field_moves, _boot.get_hud(),
		_boot.get_dialogue_runner(), _boot.get_dialogue_library(), _boot.get_player(),
		_boot.get_companion_controller(), _boot.get_companion_catalog())
	flash.check_flash = func() -> FieldMoves.Result:
		return field_moves.check(FlashDirector.MOVE, GameState.party, GameState.bag,
			GameState.flags, items, pokemon, GameState.get_companion())
	flash.can_start = func() -> bool: return _boot.is_stable() and not _boot.is_opening_active()
	flash.cue_started.connect(_boot.refresh_controls)
	flash.flash_used.connect(_boot.refresh_controls.unbind(1))


## [MountDirector] (arrivée, Vélo, bouton du HUD) et [KeyItemDirector] (UTILISER d'un objet clé
## dans le Sac : menu fermé, puis l'objet aiguillé par son usage).
func _setup_mount() -> void:
	var player := _boot.get_player()
	var runner := _boot.get_dialogue_runner()
	var interactions := _boot.get_interaction_controller()
	var menu := _boot.get_menu_director()
	_mount = MountDirector.new()
	_mount.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_mount)
	_mount.setup(GameState, player, runner, _boot.get_hud())
	_mount.can_toggle = func() -> bool: return _boot.is_stable() and not _boot.is_opening_active()
	# S2C (§2.5) : SURFER au bouton contextuel, face à l'eau.
	_mount.surf_state = func() -> FieldMoves.State: return _boot.field_state(&"surf").state
	interactions.terrain_target = _mount.surf_target
	interactions.surf_requested.connect(_mount.start_surf.unbind(1))
	_key_items = KeyItemDirector.new()
	_key_items.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_key_items)
	_key_items.setup(GameState, _boot.get_item_library(), _mount, runner,
		_boot.get_cutscene_director(), _boot.get_companion_controller(), player)
	menu.key_item_requested.connect(func(item_id: StringName) -> void:
		menu.close()
		_key_items.use(item_id))


## Pêche (J22 §2.7) : cible de terrain PÊCHER, appui, cannes du Sac ([KeyItemDirector]). Tables
## chargées sans contrôle des espèces (celles du J22 manquent) : le directeur refuse une espèce
## inconnue au moment de la touche. Après [method _setup_mount] (objets clés).
func _setup_fishing() -> void:
	var interactions := _boot.get_interaction_controller()
	var tables := WaterRodTables.new()
	tables.load_game_files()
	_fishing = FishingDirector.new()
	_fishing.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_fishing)
	_fishing.setup(GameState, tables, _boot.get_pokemon_data(), _boot.get_player(),
		_boot.get_dialogue_runner(), _boot.get_encounter_director(),
		_boot.get_companion_controller())
	SceneRouter.map_changed.connect(_fishing.set_map)
	_fishing.tree_exiting.connect(func() -> void:
		if SceneRouter.map_changed.is_connected(_fishing.set_map):
			SceneRouter.map_changed.disconnect(_fishing.set_map))
	# Cible de terrain : la pêche d'abord (case pêchable et canne au Sac, [D]), sinon le Surf.
	interactions.terrain_target = func(c: Vector2i, f: Vector2i) -> Interaction:
		var target := _fishing.target_at(c, f)
		return target if target != null else _mount.surf_target(c, f)
	interactions.fish_requested.connect(_fishing.on_fish_requested)
	# Demande de Kevin (2026-11-22) : face à une eau pêchable ET surfable, PÊCHER reste le
	# contextuel et un second bouton SURFER s'affiche au-dessus (plus de choix par appui long).
	_boot.get_hud().surf_requested.connect(_on_surf_button_pressed)
	_key_items.set_fishing(_fishing)
	_fishing.fishing_started.connect(_boot.refresh_controls.unbind(1))
	_fishing.fishing_finished.connect(_boot.refresh_controls.unbind(1))


## Bouton SURFER (second bouton, affiché avec PÊCHER face à une eau où l'on peut surfer).
func _on_surf_button_pressed() -> void:
	var player := _boot.get_player()
	if _boot.get_dialogue_runner().is_running() or _fishing.is_running() \
			or not player.is_input_enabled() or player.is_moving() or not can_surf_ahead():
		return
	_mount.start_surf()


## J23 : visite du Parc Safari (`jalon-23.md` §2.1, §2.5, §2.15).
func _setup_safari() -> void:
	_safari = SafariDirector.new()
	_safari.name = "SafariDirector"
	_safari.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_safari)
	_safari.setup(GameState, SafariConfig.load_default(), _boot.get_player(), SceneRouter,
		_boot.get_cutscene_director(), _boot.get_encounter_director(),
		_boot.get_battle_director(), _boot.request_autosave)
	SceneRouter.map_changed.connect(_safari.set_map)
	_safari.tree_exiting.connect(func() -> void:
		if SceneRouter.map_changed.is_connected(_safari.set_map):
			SceneRouter.map_changed.disconnect(_safari.set_map))
	# Pastille « pas · Balls » (N-7), seulement dans le Parc.
	_safari.visit_changed.connect(_boot.get_hud().set_safari_badge)
	# Vol et Téléport refusés dans le Parc (dossier 26 §4).
	for map: StringName in _safari.get_config().maps:
		if _fly != null:
			_fly.no_fly_maps[map] = true
		if _field_travel != null:
			_field_travel.no_fly_maps[map] = true


## [StrengthDirector] (`systemes-2.md` §2.7) : rochers de la carte (nœud `Boulders`), activation
## par EXAMINER, poussée, sauvegarde forcée par le chemin de l'étape « save » des scènes ; Force
## retombe à chaque carte. Le compagnon reste dehors pendant l'activation s'il est le Pokémon qui
## utilise Force. Les contrôles restent affichés pendant une poussée (le joystick tenu enchaîne
## les poussées).
func _setup_strength() -> void:
	var companion := _boot.get_companion_controller()
	_strength = StrengthDirector.new()
	_strength.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_strength)
	_strength.setup(GameState.flags, _boot.get_player(), _boot.get_dialogue_runner(),
		_boot.get_field_move_presenter())
	_strength.save_handler = _boot.save_checkpoint_now
	SceneRouter.map_changed.connect(_strength.on_map_changed)
	_strength.tree_exiting.connect(func() -> void:
		if SceneRouter.map_changed.is_connected(_strength.on_map_changed):
			SceneRouter.map_changed.disconnect(_strength.on_map_changed))
	_strength.activation_started.connect(func() -> void:
		var chosen := companion.get_chosen()
		companion.on_cutscene_started(chosen != null
			and _boot.field_move_user(StrengthDirector.MOVE) == chosen))
	_strength.activation_finished.connect(companion.on_cutscene_finished)


# --- Puzzles d'interrupteurs (jalon 16, Arène de Carmin) ----------------------------------------

## Charge `data/world/switch_puzzles.json` (au chargement des données, comme avant).
func load_switch_puzzles() -> void:
	_switch_puzzles.load_file()


## Fouille de l'objet [param slot] du puzzle [param puzzle_id] (jalon 16, `jalon-16.md` §2.6) :
## puzzle déjà résolu (drapeau) → « rien » ; sinon le puzzle de la carte (tiré à la première
## fouille depuis l'arrivée) répond, et le dialogue du résultat est joué, ou la scène de la
## réussite (qui ouvre la barrière et lève le drapeau). Puzzle inconnu : push_error.
func on_puzzle_searched(puzzle_id: StringName, slot: int) -> void:
	var spec := _switch_puzzles.get_spec(puzzle_id)
	if spec == null:
		push_error("Boot : puzzle inconnu « %s »" % puzzle_id)
		return
	var runner := _boot.get_dialogue_runner()
	var map := SceneRouter.get_current_map()
	if GameState.flags.has_flag(spec.solved_flag):
		runner.play(spec.nothing, null, map)
		return
	var puzzle: SwitchPuzzle = _active_puzzles.get(puzzle_id)
	if puzzle == null:
		puzzle = SwitchPuzzle.new(GameState.rng, spec.columns, spec.rows)
		puzzle.start()
		_active_puzzles[puzzle_id] = puzzle
	var result := puzzle.search(slot)
	if OS.is_debug_build():
		print("[qa] puzzle « %s » : objet %d → %s (premier %d, second %d)" % [puzzle_id, slot,
			SwitchPuzzle.Result.keys()[result], puzzle.first(), puzzle.second()])
	if result == SwitchPuzzle.Result.SOLVED:
		_active_puzzles.erase(puzzle_id)
		if not _boot.get_cutscene_director().play(spec.solved_cutscene):
			push_error("Boot : la scène « %s » du puzzle n'a pas été jouée" % spec.solved_cutscene)
		return
	runner.play(spec.dialogue_for(result), null, map)
