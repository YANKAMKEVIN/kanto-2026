class_name BootAudioWiring
extends RefCounted
## Câblage du son de [Boot] (jalon Son, T6, `docs/tech/jalon-son.md` §1.4–§1.8) : [AudioBridge]
## relaie au son les cartes, la monture (Surf, Vélo), le « ! » des Dresseurs, les combats, les
## jingles (soin, objets, capture, Badge, évolution, Poké Flûte) et la clé « music » des
## cinématiques. Sans fichier son, rien ne s'entend et rien ne change.
##
## Extrait de `boot.gd` sans changer le comportement : mêmes branchements, dans le même ordre,
## appelés au même moment du `_ready` de Boot.


static func wire(boot: Boot) -> void:
	var bridge := boot.get_audio_bridge()
	var zones := boot.get_zone_library()
	var player := boot.get_player()
	var pokemon := boot.get_pokemon_data()
	var battle := boot.get_battle_director()
	var cutscenes := boot.get_cutscene_director()
	var companion := boot.get_companion_controller()
	var awakening := boot.get_awakening_overlay()
	var evolutions := boot.get_evolution_director()
	var menu := boot.get_menu_director()
	var menu_screen := boot.get_trainer_menu()
	bridge.setup(Audio, zones)
	bridge.current_mount = player.get_mount
	bridge.has_flag = func(flag: StringName) -> bool: return GameState.flags.has_flag(flag)
	bridge.trainer_name = func(id: StringName) -> String:
		var trainers := boot.get_trainer_library()
		var trainer := trainers.get_trainer(id) if trainers != null else null
		return trainer.name if trainer != null else ""
	bridge.wild_species = battle.get_wild_species
	bridge.costume_music = func(kind: StringName) -> Array[StringName]:
		return CostumeCatalog.shared().music_tracks(GameState.worn_costume(), kind)
	bridge.caught_count = func() -> int: return GameState.pokedex.caught_count()
	bridge.items = boot.get_item_library()
	# SonB : cris (numéro national par l'espèce).
	bridge.species_dex = func(species: StringName) -> int:
		var data := pokemon.get_species(species)
		return data.dex if data != null else 0
	bridge.party_species = func(index: int) -> StringName:
		var member := GameState.party.get_at(index)
		return member.species_id if member != null else &""
	bridge.companion_species = func() -> StringName:
		var chosen := companion.get_chosen()
		return chosen.species_id if chosen != null else &""
	player.mount_changed.connect(bridge.on_mount_changed)
	boot.get_trainer_watcher().trainer_spotted.connect(bridge.on_trainer_spotted)
	battle.battle_started.connect(bridge.on_battle_started)
	battle.event_played.connect(bridge.on_battle_event)
	boot.get_battle_stage().move_fx_cue.connect(bridge.on_move_fx_cue)
	battle.battle_finished.connect(bridge.on_battle_finished)
	battle.pokemon_caught.connect(bridge.on_pokemon_caught.unbind(2))
	boot.get_service_director().center_healed.connect(bridge.on_center_healed)
	cutscenes.item_given.connect(bridge.on_item_given)
	cutscenes.item_found.connect(bridge.on_item_found)
	cutscenes.step_played.connect(bridge.on_cutscene_step)
	cutscenes.cutscene_finished.connect(bridge.on_cutscene_finished)
	# JOHP0 : le son du Réveil.
	awakening.silence_requested.connect(bridge.on_awakening_silence)
	awakening.theme_started.connect(bridge.on_awakening_theme)
	awakening.theme_burst.connect(bridge.on_awakening_burst)
	awakening.heartbeat.connect(bridge.on_awakening_heartbeat)
	awakening.ball_opened.connect(bridge.on_awakening_ball)
	awakening.level_ticked.connect(bridge.on_awakening_tick)
	awakening.cry_requested.connect(bridge.play_species_cry)
	evolutions.evolution_started.connect(bridge.on_evolution_started)
	evolutions.evolution_finished.connect(bridge.on_evolution_finished)
	boot.get_encounter_director().cry_requested.connect(bridge.on_encounter_cry)
	companion.line_requested.connect(bridge.on_companion_line)
	if menu_screen.has_signal(&"pokedex_cry_requested"):
		menu_screen.pokedex_cry_requested.connect(bridge.on_pokedex_cry)
	# SonC (T13) : bruitages du combat, des pas, du monde et de l'interface.
	bridge.move_info = func(move_id: StringName) -> Array:
		var move := pokemon.get_move(move_id)
		if move == null:
			return []
		return [move.type, StringName(String(MoveData.Category.find_key(move.category)).to_lower())]
	bridge.ground_at = func(cell: Vector2i) -> StringName:
		return ground_at(boot.get_map(), zones, cell)
	player.step_started.connect(bridge.on_player_step)
	player.bumped.connect(bridge.on_bumped)
	SceneRouter.transition_started.connect(bridge.on_transition_started)
	menu.menu_opened.connect(bridge.on_menu_opened)
	menu.menu_closed.connect(bridge.on_menu_closed)
	boot.get_dialogue_runner().page_started.connect(bridge.on_dialogue_page)
	# Une seule accroche pour tous les boutons ; le HUD d'exploration (joystick, actions) reste
	# muet.
	bridge.watch_ui(boot, boot.get_hud())


## Sol d'une case pour le bruit de pas [D] : intérieur ; herbes hautes ; neige aux Îles Écume ;
## sinon sol dur.
static func ground_at(map: GameMap, zones: ZoneLibrary, cell: Vector2i) -> StringName:
	if map == null:
		return &"hard"
	if map.interior:
		return &"indoor"
	var grid := map.get_grid()
	if grid != null and grid.is_tall_grass(cell):
		return &"grass"
	if zones.zone_of(map.map_id) == &"seafoam_islands":
		return &"snow"
	return &"hard"
