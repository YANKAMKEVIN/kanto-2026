class_name Boot
extends Node
## Scène principale : racine de composition (docs/tech/jalon-02.md §2.1).
##
## Ne fait que câbler : instancie le joueur, branche l'autoload SceneRouter sur `World`,
## le joueur et le rideau `ScreenFade`, relie les signaux du routeur au HUD, charge les
## dialogues de `data/dialogues/` et branche le lecteur de dialogues et le contrôleur
## d'interactions (docs/tech/jalon-03.md §2.1), charge les scènes scriptées de
## `data/cutscenes/` et branche le directeur de scènes (docs/tech/jalon-03b.md §2.1), charge
## les données Pokémon et l'offre du labo et branche le choix du starter (jalon-04.md §3.1,
## §13.3), puis démarre sur [member start_map] / [member start_spawn]. Le titre de zone ne s'affiche qu'en
## arrivant dans une zone extérieure différente ([ZoneAnnouncer]) : aucun au démarrage
## dans la chambre. Les réglages de départ servent au développement, aux tests et aux
## outils de capture : les régler avant add_child.
##
## Sauvegarde (jalon 5C.5, jalon-05.md §16) : Boot tient le [SaveSystem] (pas d'autoload).
## Au démarrage, il reprend la partie sauvegardée (carte, case, orientation) ou en commence
## une nouvelle. L'autosave est **demandé** aux moments du §16.1 (arrivée sur une carte, fin de
## scène, fin de combat ou de rencontre, soin chez Maman ; [method request_autosave] pour la
## capture du T15) et **écrit** à la première image où la partie est stable
## ([method is_stable] : ni dialogue, ni scène, ni fiche du starter, ni rencontre, ni combat,
## ni transition, joueur libre) ; au passage en arrière-plan il est écrit tout de suite, si la
## partie est stable (sinon la dernière sauvegarde stable reste). Jamais d'autosave après un
## départ de débogage (sauf s'il le demande, clé « autosave » de [DebugStart] : il remplace
## alors la sauvegarde, QA de la sauvegarde v4), ni quand la sauvegarde vient d'une version plus récente du jeu (elle
## n'est jamais écrasée). Boot enregistre aussi les faits du §16.3 (Pokédex daté, starter,
## combat du rival, objets trouvés, zones découvertes, temps de jeu).
##
## Menu Dresseur (jalon 6, T4) : Boot est en mode ALWAYS (le temps de jeu et l'autosave
## continuent menu ouvert, Q-21) et tous ses enfants sont PAUSABLE sauf [MenuDirector] : le
## directeur met l'arbre en pause à l'ouverture. Ouverture par l'action `menu` ou le retour
## Android (en exploration : sauvegarde puis ouverture, **jamais** de sortie du jeu, Q-3).

## Une zone vient d'être annoncée (titre de zone affiché).
signal zone_announced(zone_name: String, region: String)

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const EVOLUTION_SCREEN: PackedScene = preload("res://game/ui/evolution/evolution_screen.tscn")
## Temps de jeu : une image ne compte jamais plus que ceci (le retour de l'arrière-plan peut
## livrer un très grand delta, qui n'est pas du temps de jeu).
const MAX_PLAY_TIME_STEP: float = 0.5

@export var start_map: StringName = &"player_house_2f"
@export var start_spawn: StringName = &"start"
@export var start_facing: Vector2i = Vector2i.DOWN
## Fichier du départ de débogage ([DebugStart]) ; lu seulement en build debug, quand Boot est
## la scène principale lancée par le moteur, et si le fichier existe (jamais sous GUT).
var debug_start_path: String = DebugStart.USER_PATH
## Tests seulement : appliquer le départ de débogage même sous GUT (jamais en jeu).
var force_debug_start: bool = false
## Sauvegarde de la partie (jalon 5C.5). Les tests en injectent une (système de fichiers en
## mémoire) avant add_child. Null : Boot ouvre la vraie (`user://save.json`) **seulement s'il
## est la scène principale lancée par le moteur** ; sous GUT et dans les outils de capture
## (qui instancient Boot eux-mêmes), aucune sauvegarde n'est lue ni écrite.
var save_system: SaveSystem = null
## Fichier des déblocages de débogage ([DebugUnlocks]) ; mêmes règles que [member
## debug_start_path].
var debug_unlocks_path: String = DebugUnlocks.USER_PATH
## Tests seulement : appliquer les déblocages de débogage même sous GUT (jamais en jeu).
var force_debug_unlocks: bool = false

## Fichier des réglages de l'appareil (jalon 6, T29). Les tests en injectent un (système de
## fichiers en mémoire) avant add_child. Null : Boot ouvre le vrai (`user://settings.json`)
## **seulement s'il est la scène principale lancée par le moteur** (même garde que la
## sauvegarde) ; sinon réglages par défaut et rien d'écrit.
var settings_store: SettingsStore = null
## Appareil pour « Auto » ([method GraphicsProfile.current_device]) ; vide : l'appareil réel
## (tests : injecter une description).
var device: Dictionary = {}

var _settings := GameSettings.new()
var _profile: GraphicsProfile
var _player: Player
var _announcer := ZoneAnnouncer.new()
var _library := DialogueLibrary.new()
var _cutscenes := CutsceneLibrary.new()
var _pokemon := PokemonData.new()
var _offer := StarterOffer.new()
var _trainers: TrainerLibrary
var _texts := BattleText.new()
var _items := ItemLibrary.new()
var _encounter_library: EncounterLibrary
var _zones := ZoneLibrary.new()
var _dex := PokedexLibrary.new()
var _map_illustration := MapIllustration.new()
var _moments := MomentLibrary.new()
## Toasts du Pokédex en attente (au plus un par espèce) : des paires [espèce, [titre, détail]].
var _dex_toasts: Array[Array] = []
## Individus observés pendant la visite de la carte (OBSERVER, une fois par individu).
var _observed: Dictionary[StringName, bool] = {}
var _objectives := ObjectiveLibrary.new()
var _unlocks: MenuUnlocks
## Lumière du monde (jalon 7, jalon-07.md §6.7, §15.3) : profil de la carte appliqué à chaque
## changement de carte (écran noir) ; profil vide = aucun effet (Bourg Palette, Route 1).
var _lighting: WorldLighting
var _light_profiles := LightingLibrary.new()
## Évolutions de fin de combat (jalon 9, jalon-09.md §2.3) et leur écran (T9).
var _evolutions: EvolutionDirector
var _evolution_screen: EvolutionScreen
## Points de repos (jalon 7, 7A.2) : maison et Centres, mot du réveil (data/world/rest_points.json).
var _rest_points := RestPointLibrary.new()
## Toast « Point de repos enregistré — <zone> » en attente de la fin du dialogue du soin.
var _rest_toast: PackedStringArray = PackedStringArray()
## Boutiques (jalon 7, 7A.3, data/shops/) ; la boutique demandée par le marchand (`open_shop`),
## ouverte à la fin de son dialogue (le menu ne s'ouvre pas pendant un dialogue).
var _shops := ShopLibrary.new()
var _pending_shop: StringName = &""
## Le terminal du Centre a demandé le Stockage (`open_storage`) : ouvert à la fin du dialogue.
var _pending_storage: bool = false
## Faux : aucune écriture de toute la session (pas de sauvegarde, départ de débogage, ou
## sauvegarde d'une version plus récente à ne jamais écraser).
var _autosave_enabled: bool = false
## Vrai si la partie a repris une sauvegarde au démarrage.
var _resumed: bool = false
## Le départ de débogage appliqué demande l'autosave ([member DebugStart.autosave]).
var _debug_start_autosave: bool = false
## Autosave demandé, en attente d'un état stable, et sa raison (journal).
var _save_pending: bool = false
var _save_reason: String = ""
## Faux quand l'application est en arrière-plan ou a perdu le focus (temps de jeu arrêté).
var _in_foreground: bool = true

@onready var _world: Node2D = %World
@onready var _hud: ExplorationHud = %ExplorationHud
@onready var _fade: ScreenFade = %ScreenFade
@onready var _coming_soon: ComingSoonScreen = %ComingSoonScreen
@onready var _dialogue_box: DialogueBox = %DialogueBox
@onready var _runner: DialogueRunner = %DialogueRunner
@onready var _interactions: InteractionController = %InteractionController
@onready var _cutscenes_node: CutsceneDirector = %CutsceneDirector
@onready var _sheet: StarterSheet = %StarterSheet
@onready var _starter_choice: StarterChoice = %StarterChoice
@onready var _battle_stage: BattleStage = %BattleStage
@onready var _battle_hud: BattleHud = %BattleHud
@onready var _battle_director: BattleDirector = %BattleDirector
@onready var _ambient: AmbientWatcher = %AmbientWatcher
@onready var _encounters: EncounterDirector = %EncounterDirector
@onready var _trainer_watcher: TrainerWatcher = %TrainerWatcher
@onready var _recovery: DefeatRecovery = %DefeatRecovery
@onready var _services: ServiceDirector = %ServiceDirector
@onready var _menu: MenuDirector = %MenuDirector
@onready var _menu_screen: TrainerMenu = %TrainerMenu


func _ready() -> void:
	GameState.new_game()
	_lighting = WorldLighting.new()
	_lighting.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_lighting)
	_light_profiles.load_file()
	_load_settings()
	# Compteur de fps de QA (journal « [perf] »), seulement en build debug, Boot scène principale.
	if PerfCounter.is_allowed(OS.is_debug_build(), get_tree().current_scene == self):
		add_child(PerfCounter.new())
	_player = PLAYER_SCENE.instantiate() as Player
	_library.load_dir()
	_cutscenes.load_dir()
	_runner.setup(_library, GameState.flags, _dialogue_box, _player)
	# Centre Pokémon (jalon 7, 7A.2, jalon-07.md §6.2) : actions de dialogue (soins), choix à deux
	# cartes dans la boîte de dialogue (T7), réveil au point de repos.
	_rest_points.load_file()
	_services.setup(GameState, _rest_points)
	_services.center_healed.connect(_on_center_healed)
	_services.shop_requested.connect(_on_shop_requested)
	_services.storage_requested.connect(_on_storage_requested)
	_runner.action_handler = _services.run_action
	# Choix à deux cartes (jalon-07.md §6.5, T7) : la boîte montre les cartes, le lecteur attend.
	_runner.choice_requested.connect(_dialogue_box.show_choice)
	_dialogue_box.choice_made.connect(_runner.choose)
	_interactions.setup(_player, _runner)
	_cutscenes_node.setup(_cutscenes, GameState.flags, _runner, _player, SceneRouter)
	# Dresseurs (jalon-09.md §2.4.6) : branchés sur le pas du joueur APRÈS le directeur de scènes
	# et AVANT l'EncounterDirector (setup plus bas) : un pas qui entre dans un champ de vision ne
	# tire aucune rencontre sauvage. Défi à la parole par le contrôleur d'interactions.
	_trainer_watcher.setup(_player, GameState.flags, _cutscenes_node)
	_interactions.set_story_flags(GameState.flags)
	_interactions.challenge_requested.connect(_trainer_watcher.challenge)
	_pokemon.load_dir()
	if _offer.load_file():
		_offer.check_species(_pokemon)
	_starter_choice.setup(_offer, _pokemon, GameState, _player, _sheet, _hud, _cutscenes_node,
		_interactions)
	_starter_choice.sheet_opened.connect(_refresh_controls)
	_starter_choice.sheet_closed.connect(_refresh_controls)
	# Jalon 4B : combat, dresseurs, messages, objets et Sac.
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_texts.load_file()
	_items.load_dir()
	_battle_director.setup(_pokemon, _trainers, _texts, _battle_stage, _battle_hud, _player,
		GameState, _items)
	# CB.1 : artwork officiel de l'adversaire (numéro) et tailles réelles (Pokédex).
	_battle_stage.set_species_source(_pokemon, _dex)
	_cutscenes_node.set_battle_runner(_battle_director)
	_evolutions = EvolutionDirector.new()
	_evolutions.name = "EvolutionDirector"
	_evolutions.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_evolutions)
	_evolutions.setup(GameState, _pokemon, _texts, _battle_director.get_move_learn_prompt())
	_battle_director.set_evolution_director(_evolutions)
	# Écran d'évolution (T9) : au-dessus de l'interface de combat ; ses durées suivent celles du
	# combat (relayées par le directeur), « Réduire les flashs » atténue son flash.
	_evolution_screen = EVOLUTION_SCREEN.instantiate() as EvolutionScreen
	_evolution_screen.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_evolution_screen)
	_evolution_screen.reduce_flashes = _settings.reduce_flashes
	_evolutions.set_screen(_evolution_screen)
	_cutscenes_node.set_inventory(GameState.bag, _items)
	# Remise du colis (jalon-07.md §3.6.2, T19) : jeton {first_wild_species} des répliques de
	# Chen, scène lancée par une variante de dialogue (« colis en main »), légende POKÉDEX ACTIVÉ.
	_runner.token_values = _dialogue_token_values
	_runner.cutscene_requested.connect(_on_cutscene_requested)
	_cutscenes_node.set_hud(_hud)
	_cutscenes_node.item_given.connect(_on_item_given)
	_cutscenes_node.item_found.connect(_on_item_found)
	_battle_director.battle_started.connect(_on_battle_state_changed.unbind(1))
	# Le titre de zone ne reste pas affiché pendant un combat (jalon 5C T11) : une rencontre
	# peut survenir dans les secondes qui suivent l'arrivée dans la zone.
	_battle_director.battle_started.connect(_hud.hide_zone_title.unbind(1))
	_battle_director.battle_finished.connect(_on_battle_state_changed.unbind(2))
	_battle_director.battle_finished.connect(_on_battle_finished)
	# Pokédex (jalon 5, décision Kevin 2026-09-29) : le starter est « capturé » à son entrée
	# dans l'équipe ; tout Pokémon adverse envoyé au combat est « vu » (le Pokémon du rival au
	# labo, puis les sauvages en 5B).
	_starter_choice.starter_chosen.connect(_on_starter_chosen)
	_battle_director.event_played.connect(_on_battle_event)
	# Capture (jalon 5D) : le Pokémon rangé, l'autosave est demandé (écrit une fois stable).
	_battle_director.pokemon_caught.connect(_on_pokemon_caught.unbind(2))
	_ambient.setup(_player)
	# Rencontres sauvages (jalon 5, 5B) : tables lues dans data/encounters/, l'EncounterDirector
	# tire une rencontre à chaque pas dans les hautes herbes et joue le vrai combat sauvage
	# (BattleDirector.run_request). Une défaite renvoie au point de soin (§3.11).
	_encounter_library = EncounterLibrary.new(_pokemon)
	_encounter_library.load_dir()
	_recovery.setup(GameState, _rest_points, SceneRouter, _runner)
	_recovery.woke_up.connect(_on_woke_up_after_defeat.unbind(1))
	# Défaite contre un Dresseur (jalon-07.md §3.8, T25) : l'étape de scène « wake_up ».
	_cutscenes_node.set_recovery(_recovery)
	_encounters.setup(_encounter_library, _pokemon, GameState, _player, _battle_director,
		SceneRouter, _cutscenes_node, _recovery)
	_encounters.encounter_started.connect(_on_encounter_state_changed.unbind(2))
	_encounters.encounter_started.connect(_hud.hide_zone_title.unbind(2))
	_encounters.encounter_finished.connect(_on_encounter_state_changed.unbind(1))
	_encounters.encounter_finished.connect(_on_encounter_finished)
	_interactions.target_changed.connect(_on_target_changed)
	_runner.dialogue_started.connect(_on_dialogue_started)
	_runner.dialogue_finished.connect(_on_dialogue_finished)
	# Soin volontaire (jalon 5 §3.11) : une variante de dialogue « heal » (parler à Maman)
	# soigne l'équipe à la fin du dialogue.
	_runner.heal_requested.connect(_on_heal_requested)
	_cutscenes_node.cutscene_started.connect(_on_cutscene_started)
	_cutscenes_node.cutscene_finished.connect(_on_cutscene_finished)
	# Menu Dresseur (jalon 6, T4) : le directeur pilote la pile et la pause ; l'écran
	# (TrainerMenu) est relié après la fusion du T3 (jalon-06.md §6.6).
	_zones.load_file()
	_objectives.load_file()
	_unlocks = MenuUnlocks.new(GameState.flags, GameState.party)
	# Stockage (jalon-07.md §6.9, T16) : seulement dans un Centre (carte courante, relue à chaque
	# appel) ; l'écran Stockage et le bouton STOCKAGE de l'Équipe n'existent que là.
	_unlocks.set_location(_zones, _current_map_id)
	_apply_debug_unlocks()
	if _dex.load_file():
		_dex.check_references(_pokemon)
	for error: String in _dex.get_errors():
		push_error("Pokédex : %s" % error)
	if _map_illustration.load_file():
		_map_illustration.check_references(_zones)
	for error: String in _map_illustration.get_errors():
		push_error(error)
	if _moments.load_file():
		_moments.check_references(_zones)
	for error: String in _moments.get_errors():
		push_error(error)
	_menu.setup(GameState, _pokemon, _zones, _objectives, _unlocks, _can_open_menu, _items, _dex,
		_map_illustration, _moments)
	# Boutique (jalon-07.md §6.10, T12) : stock vérifié contre les objets.
	_shops.load_dir()
	_shops.check_references(_items)
	_menu.set_shops(_shops)
	_menu.menu_opened.connect(_on_menu_opened)
	_menu.menu_closed.connect(_on_menu_closed)
	# L'écran (jalon-06.md §6.6) : ouverture et vue dans la même frame, sans await (un fondu
	# coupé laisse une coroutine non reprise).
	_menu.menu_opened.connect(_menu_screen.open_animated)
	_menu.menu_closed.connect(_menu_screen.close_animated.unbind(1))
	_menu.dashboard_shown.connect(_menu_screen.show_dashboard)
	_menu.placeholder_shown.connect(_menu_screen.show_placeholder)
	_menu_screen.route_requested.connect(_menu.go)
	_menu_screen.back_requested.connect(_menu.handle_back)
	_menu_screen.close_requested.connect(_menu.close)
	# Équipe (T8) : reliée dès que l'écran porte l'interface du §6.7 (TeamScreen du T7).
	if _menu_screen.has_signal(&"team_member_moved"):
		_menu.team_shown.connect(_menu_screen.show_team)
		_menu_screen.team_member_moved.connect(_menu.move_member)
		_menu_screen.team_favorite_toggled.connect(_menu.toggle_favorite)
		_menu_screen.team_member_selected.connect(_menu.select_member)
	# Sac (T12) : relié dès que l'écran porte l'interface du §6.8 (BagScreen du T11).
	if _menu_screen.has_signal(&"bag_use_requested"):
		_menu.bag_shown.connect(_menu_screen.show_bag)
		_menu.bag_targets_shown.connect(_menu_screen.show_bag_targets)
		_menu.bag_result_shown.connect(_menu_screen.show_bag_result)
		_menu_screen.bag_category_opened.connect(_menu.open_bag_category)
		_menu_screen.bag_favorite_toggled.connect(_menu.toggle_item_favorite)
		_menu_screen.bag_sort_changed.connect(_menu.set_bag_sort)
		_menu_screen.bag_use_requested.connect(_menu.request_item_use)
		_menu_screen.bag_target_chosen.connect(_menu.use_item_on)
		_menu_screen.bag_repeat_requested.connect(_menu.repeat_item_use)
	# Pokédex (T16) : relié dès que l'écran porte l'interface du §6.9 (PokedexScreen du T15).
	if _menu_screen.has_signal(&"pokedex_species_opened"):
		_menu.pokedex_shown.connect(_menu_screen.show_pokedex)
		_menu.pokedex_sheet_shown.connect(_menu_screen.show_pokedex_sheet)
		_menu_screen.pokedex_filter_changed.connect(_menu.set_pokedex_filter)
		_menu_screen.pokedex_species_opened.connect(_menu.open_species)
	# Carte (T21) : reliée dès que l'écran porte l'interface du §6.10 (MapScreen du T20).
	if _menu_screen.has_signal(&"map_zone_touched"):
		_menu.map_shown.connect(_menu_screen.show_map)
		_menu.map_zone_shown.connect(_menu_screen.show_map_zone)
		_menu_screen.map_zone_touched.connect(_menu.open_zone)
	# Dresseur (T25) : sans show_trainer (écran pas encore fusionné), l'écran provisoire.
	if _menu_screen.has_method(&"show_trainer"):
		_menu.trainer_shown.connect(_menu_screen.show_trainer)
	else:
		_menu.trainer_shown.connect(
			func(_view: TrainerView) -> void: _menu_screen.show_placeholder(MenuRoute.TRAINER))
	# Paramètres (T29) : reliés dès que l'écran porte l'interface du §6.12 (SettingsScreen du
	# T28) ; sinon l'écran provisoire reste.
	_menu.settings_changed.connect(_on_settings_changed)
	_menu.save_requested.connect(_on_save_requested)
	if _menu_screen.has_signal(&"setting_changed"):
		_menu.save_result_shown.connect(_menu_screen.show_save_result)
		_menu.settings_shown.connect(_menu_screen.show_settings)
		_menu_screen.setting_changed.connect(_menu.change_setting)
		_menu_screen.save_now_requested.connect(_menu.request_save)
	# Boutique (jalon-07.md §6.10) : ShopScreen du T11 (TrainerMenu), directeur du T12.
	_menu.shop_shown.connect(_menu_screen.show_shop)
	_menu.shop_result_shown.connect(_menu_screen.show_shop_result)
	_menu.shop_confirm_requested.connect(_menu_screen.show_shop_confirm)
	_menu_screen.shop_mode_changed.connect(_menu.set_shop_mode)
	_menu_screen.shop_buy_requested.connect(_menu.buy)
	_menu_screen.shop_sell_requested.connect(_menu.sell)
	# Stockage (jalon-07.md §6.9) : StorageScreen du T15 (TrainerMenu, fusionné avant : câblage
	# direct, comme la Boutique), directeur du T16.
	_menu.storage_shown.connect(_menu_screen.show_storage)
	_menu.storage_refused.connect(_menu_screen.show_storage_refusal)
	_menu.storage_release_asked.connect(_menu_screen.ask_storage_release)
	_menu_screen.storage_selected.connect(_menu.select_storage)
	_menu_screen.storage_deposit_requested.connect(_menu.deposit_member)
	_menu_screen.storage_withdraw_requested.connect(_menu.withdraw_member)
	_menu_screen.storage_favorite_toggled.connect(_menu.toggle_storage_favorite)
	_menu_screen.storage_release_requested.connect(_menu.request_release)
	_menu_screen.storage_release_confirmed.connect(_menu.confirm_release)
	# Une seule écoute de tout ce qui s'enregistre au Pokédex (jalon-06.md §6.9).
	GameState.pokedex.recorded.connect(_on_pokedex_recorded)
	GameState.flags.flag_changed.connect(_on_flag_changed)
	_interactions.observed.connect(_on_observed)
	_hud.menu_requested.connect(_menu.open)
	SceneRouter.setup(_world, _player, _fade)
	# Destinations « à venir » (dossier-07 §12, build de développement) : l'écran provisoire.
	SceneRouter.coming_soon_presenter = _coming_soon.present
	# Branchés avant start() : la première carte passe aussi par le contrôleur.
	SceneRouter.transition_started.connect(_on_transition_started)
	# Via Boot (ordre garanti) : présence des PNJ, puis le contrôleur, puis le directeur.
	SceneRouter.map_changed.connect(_on_map_changed)
	SceneRouter.map_entered.connect(_on_map_entered)
	SceneRouter.map_entered.connect(_interactions.on_map_entered)
	SceneRouter.map_entered.connect(_starter_choice.on_map_entered)
	_start_game()
	_menu.set_settings(_settings, _profile_device_quality(), _can_write())


func _process(delta: float) -> void:
	if _in_foreground:
		GameState.add_play_time(minf(delta, MAX_PLAY_TIME_STEP))
	if _save_pending and is_stable():
		_write_save(_save_reason)
	if not _dex_toasts.is_empty():
		_show_next_dex_toast()


## Passage en arrière-plan (Android) ou fermeture de la fenêtre (Mac) : sauvegarde immédiate
## si la partie est stable (jalon 5C.5 §16.1) ; sinon la dernière sauvegarde stable reste.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			if what == NOTIFICATION_APPLICATION_PAUSED:
				_in_foreground = false
			if _can_write() and is_stable():
				_write_save("arrière-plan")
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_go_back()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_in_foreground = true
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_in_foreground = false


## Action `menu` (Échap, M) : ouvre le menu en exploration, le ferme s'il est ouvert (après avoir
## refermé le choix du Pokémon du Sac s'il est ouvert).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu") and not event.is_echo():
		if _menu.is_open():
			# Le choix du Pokémon du Sac se referme d'abord (retour d'un niveau).
			if not _screen_back():
				_menu.close()
		else:
			_menu.open()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	# Statiques : un test ne doit jamais hériter des réglages du précédent.
	Haptics.reset()
	UiPrefs.reset()
	Engine.max_fps = 0
	var links: Array[Array] = [
		[SceneRouter.transition_started, _on_transition_started],
		[SceneRouter.map_changed, _on_map_changed],
		[SceneRouter.map_entered, _on_map_entered],
		[SceneRouter.map_entered, _interactions.on_map_entered],
		[SceneRouter.map_entered, _starter_choice.on_map_entered],
	]
	for link: Array in links:
		var sig: Signal = link[0]
		if sig.is_connected(link[1]):
			sig.disconnect(link[1])


func get_player() -> Player:
	return _player


func get_map() -> GameMap:
	return SceneRouter.get_current_map()


## Réglages courants (jalon 6, T29).
## Lumière du monde (jalon 7) : tests et outils de capture.
func get_world_lighting() -> WorldLighting:
	return _lighting


func get_settings() -> GameSettings:
	return _settings


## Profil graphique appliqué (jalon 6, T29).
func get_graphics_profile() -> GraphicsProfile:
	return _profile


## Écran du Menu Dresseur (jalon 6).
func get_trainer_menu() -> TrainerMenu:
	return _menu_screen


## Directeur du Menu Dresseur (jalon 6).
func get_menu_director() -> MenuDirector:
	return _menu


func get_hud() -> ExplorationHud:
	return _hud


func get_fade() -> ScreenFade:
	return _fade


## Écran provisoire « <destination> — À venir » (build de développement).
func get_coming_soon_screen() -> ComingSoonScreen:
	return _coming_soon


func get_dialogue_box() -> DialogueBox:
	return _dialogue_box


func get_dialogue_runner() -> DialogueRunner:
	return _runner


func get_interaction_controller() -> InteractionController:
	return _interactions


func get_cutscene_director() -> CutsceneDirector:
	return _cutscenes_node


## Scènes scriptées chargées au démarrage (data/cutscenes/).
func get_cutscene_library() -> CutsceneLibrary:
	return _cutscenes


func get_starter_choice() -> StarterChoice:
	return _starter_choice


func get_starter_sheet() -> StarterSheet:
	return _sheet


## Données Pokémon chargées au démarrage (data/pokemon/).
func get_pokemon_data() -> PokemonData:
	return _pokemon


## Offre du labo chargée au démarrage (data/pokemon/starters.json).
func get_starter_offer() -> StarterOffer:
	return _offer


func get_battle_director() -> BattleDirector:
	return _battle_director


func get_evolution_director() -> EvolutionDirector:
	return _evolutions


func get_battle_stage() -> BattleStage:
	return _battle_stage


func get_battle_hud() -> BattleHud:
	return _battle_hud


## Dresseurs chargés au démarrage (data/trainers/).
func get_trainer_library() -> TrainerLibrary:
	return _trainers


## Objets chargés au démarrage (data/items/).
func get_item_library() -> ItemLibrary:
	return _items


func get_encounter_director() -> EncounterDirector:
	return _encounters


## Dresseurs du monde (jalon 9, T11).
func get_trainer_watcher() -> TrainerWatcher:
	return _trainer_watcher


## Réveil après une défaite (jalon 7, T8).
func get_defeat_recovery() -> DefeatRecovery:
	return _recovery


## Actions des services : soins, Boutique et Stockage (jalon 7, T8, T12, T16).
func get_service_director() -> ServiceDirector:
	return _services


## Points de repos chargés au démarrage (data/world/rest_points.json).
func get_shop_library() -> ShopLibrary:
	return _shops


func get_rest_points() -> RestPointLibrary:
	return _rest_points


## Tables de rencontre chargées au démarrage (data/encounters/).
func get_encounter_library() -> EncounterLibrary:
	return _encounter_library


## Dialogues chargés au démarrage (data/dialogues/).
func get_dialogue_library() -> DialogueLibrary:
	return _library


## Vrai si la partie a repris une sauvegarde au démarrage (sinon : nouvelle partie).
func has_resumed() -> bool:
	return _resumed


## Faux si rien ne sera écrit de toute la session (pas de sauvegarde ouverte, départ de
## débogage, sauvegarde d'une version plus récente).
func is_autosave_enabled() -> bool:
	return _autosave_enabled


## Vrai si la partie est dans un état stable, bon à sauvegarder : joueur libre, ni dialogue,
## ni scène, ni fiche du starter, ni rencontre, ni combat, ni transition de carte.
func is_stable() -> bool:
	return is_instance_valid(_player) and _player.is_input_enabled() \
		and is_instance_valid(SceneRouter.get_current_map()) \
		and not SceneRouter.is_transitioning() and not _runner.is_running() \
		and not _cutscenes_node.is_running() and not _starter_choice.is_sheet_open() \
		and not _battle_director.is_running() and not _encounters.is_running()


## Garde d'ouverture du Menu Dresseur : partie stable (ce qui exclut dialogue, scène, rencontre,
## combat et transition), sans écran « À venir ». [method is_stable] reste vrai menu ouvert :
## chaque action du menu est appliquée d'un bloc à l'état (jalon-06.md §5.4).
func _can_open_menu() -> bool:
	return is_stable() and not _coming_soon.is_showing()


## Retour Android (jalon-06.md §6.2, Q-3 : le jeu ne quitte **jamais** sur le retour) : menu
## ouvert, un niveau en arrière (la fermeture a son autosave) ; en exploration, sauvegarde
## immédiate puis ouverture du menu ; pendant un dialogue, une scène, un combat ou une
## transition, ignoré.
func _on_go_back() -> void:
	# Bilan de fin de combat affiché : retour = le fermer (demande n° 1).
	if _battle_director.handle_back():
		return
	# Un choix à deux cartes dans un dialogue (SOIGNER / PAS MAINTENANT) : retour = annuler.
	if _dialogue_box.cancel_choice():
		return
	if _menu.is_open() and _screen_back():
		return
	if _menu.handle_back():
		return
	if _hud.are_controls_visible() and _can_open_menu():
		if _can_write():
			_write_save("retour")
		_menu.open()


## Le menu s'ouvre (pause posée) : contrôles cachés (relâche joystick et boutons), titre de
## zone et légende retirés.
func _on_menu_opened() -> void:
	# La position vit dans GameState seulement après une sauvegarde : la pousser à l'ouverture,
	# pour que la Carte et le Dresseur sachent où est le joueur dès une partie neuve.
	var here := SceneRouter.get_current_map()
	if is_instance_valid(here) and is_instance_valid(_player):
		GameState.set_player_location(here.map_id, _player.get_cell(), _player.get_facing())
	_hud.hide_zone_title()
	# Le fondu du titre est un Tween du HUD, gelé par la pause : masqué net (la fin du fondu,
	# reprise à la fermeture, ne change plus rien).
	_hud.get_zone_title().visible = false
	# Légende du monde (haut, centre) retirée aussi : rien du HUD ne transparaît sous le flou.
	_hud.hide_caption()
	_hud.get_caption().visible = false
	_refresh_controls()


## Le menu se ferme (pause levée) : le monde reprend, les contrôles reviennent ; autosave
## seulement si l'état a changé.
func _on_menu_closed(changed: bool) -> void:
	_refresh_controls()
	if changed:
		request_autosave("menu")


## Déblocages de débogage ([DebugUnlocks]) : même garde que le départ de débogage, sans effet
## sur la sauvegarde ni sur les drapeaux d'histoire.
func _apply_debug_unlocks() -> void:
	var allowed := force_debug_unlocks \
		or DebugUnlocks.is_allowed(OS.is_debug_build(), get_tree().current_scene == self)
	if not allowed or not FileAccess.file_exists(debug_unlocks_path):
		return
	var unlocks := DebugUnlocks.new()
	if unlocks.load_file(debug_unlocks_path):
		unlocks.apply(_unlocks)
		print("Déblocages de débogage : %s" % unlocks.describe())


## Demande un autosave (jalon 5C.5 §16.1) : écrit à la première image où la partie est
## stable ([method is_stable]). Sans effet si l'autosave est coupé pour la session. Point
## d'appel de la capture (T15).
func request_autosave(reason: String) -> void:
	if not _can_write():
		return
	_save_pending = true
	_save_reason = reason


## Démarrage (jalon 5C.5) : départ de débogage s'il est appliqué (ni lecture ni écriture de
## la sauvegarde), sinon reprise de la sauvegarde si elle se charge, sinon nouvelle partie sur
## [member start_map] / [member start_spawn].
func _start_game() -> void:
	_start_game_state()
	# Parties existantes : notes débloquées sans bruit (jalon-06.md §6.9, point 4).
	PokedexNotes.refresh(GameState.pokedex, _dex, GameState.flags)
	_dex_toasts.clear()


func _start_game_state() -> void:
	if _apply_debug_start():
		if _debug_start_autosave:
			_open_save_system()
			_autosave_enabled = save_system != null
			print("Départ de débogage : la sauvegarde n'est pas lue, elle sera REMPLACÉE.")
		else:
			print("Départ de débogage : la sauvegarde n'est ni lue ni écrite.")
	else:
		_open_save_system()
		if save_system != null and _load_save() and _resume():
			return
	SceneRouter.start(start_map, start_spawn, start_facing)


## Ouvre la vraie sauvegarde si aucune n'a été injectée et que Boot est la scène principale.
func _open_save_system() -> void:
	if save_system == null and get_tree().current_scene == self:
		save_system = SaveSystem.new()


## Lit la sauvegarde et la charge dans GameState (décisions de Kevin du 2026-10-02). Vrai si
## une partie a été chargée. Sans sauvegarde ou fichier corrompu (déjà mis de côté par le
## [SaveSystem]) : nouvelle partie, autosave normal. Version plus récente (ou erreur
## imprévue) : nouvelle partie **sans autosave de toute la session**, le fichier n'est jamais
## écrasé.
func _load_save() -> bool:
	if not save_system.has_save():
		_autosave_enabled = true  # première partie : rien à lire (sans avertissement)
		return false
	var content := save_system.read()
	match save_system.last_status:
		OK:
			_autosave_enabled = true
			if not GameState.load_dict(content, _pokemon):
				_keep_rejected_save()
			_resumed = true
			print("Sauvegarde chargée : %s %s (temps de jeu %d s)" % [GameState.current_map,
				GameState.player_cell, int(GameState.play_time)])
			_log_loaded_save()
			return true
		ERR_FILE_NOT_FOUND:
			_autosave_enabled = true
		ERR_FILE_CORRUPT:
			_autosave_enabled = true
			push_warning("Boot : sauvegarde illisible, mise de côté ; nouvelle partie.")
		_:
			_autosave_enabled = false
			push_warning(("Boot : %s. Nouvelle partie SANS sauvegarde automatique : la "
				+ "sauvegarde existante n'est pas touchée.") % save_system.last_error)
	return false


## Journal de QA du chargement (build debug) : migration (une ligne, seulement si le fichier
## était d'une version plus ancienne : « [qa] sauvegarde v3 → v4 ») et statuts relus.
func _log_loaded_save() -> void:
	if not OS.is_debug_build():
		return
	var note := SaveSystem.migration_note(save_system.read_version, save_system.version)
	if not note.is_empty():
		print("[qa] " + note)
	var lists := {"équipe": GameState.party.get_all(), "stockage": GameState.storage.get_all()}
	for where: String in lists:
		var members: Array[Pokemon] = lists[where]
		for i: int in members.size():
			if members[i].status != StatusRules.NONE:
				print("[qa] statut relu : %s (%s %d) %s" % [members[i].display_name(_pokemon),
					where, i + 1, members[i].status])


## Une entrée de la sauvegarde a été écartée au chargement (Pokémon, objet ou espèce inconnus
## de cette build) : la partie reprend sans elle, mais le fichier d'origine est copié à côté
## (`save.json.rejected`) avant que l'autosave ne le remplace.
func _keep_rejected_save() -> void:
	var copy := save_system.path + ".rejected"
	var error := save_system.fs.write_text(copy, save_system.fs.read_text(save_system.path))
	push_warning("Boot : sauvegarde chargée en partie seulement ; original copié dans %s (%s)"
		% [copy, error_string(error)])


## Reprise sur la carte, la case et l'orientation sauvegardées ; si la carte n'existe plus,
## au point de soin. Faux si aucun des deux n'a marché (Boot part alors du départ par défaut,
## avec la partie chargée).
func _resume() -> bool:
	if SceneRouter.start_at(GameState.current_map, GameState.player_cell,
			GameState.player_facing) != null:
		return true
	push_warning("Boot : reprise sur « %s » impossible, retour au point de soin."
		% GameState.current_map)
	return SceneRouter.start(GameState.heal_map, GameState.heal_spawn, Vector2i.UP) != null


## Départ de débogage (jalon 5 T9, [DebugStart]) : remplace la nouvelle partie par celle du
## fichier [member debug_start_path], s'il est permis et présent. Vrai s'il a été appliqué.
func _apply_debug_start() -> bool:
	var allowed := force_debug_start \
		or DebugStart.is_allowed(OS.is_debug_build(), get_tree().current_scene == self)
	if not allowed or not FileAccess.file_exists(debug_start_path):
		return false
	var start := DebugStart.new()
	if not start.load_file(debug_start_path, _pokemon, _items):
		return false
	start.apply(GameState, _pokemon)
	_debug_start_autosave = start.autosave
	if not start.map.is_empty():
		start_map = start.map
		start_spawn = start.spawn
		start_facing = start.facing
	print("Départ de débogage (%s) : %s" % [debug_start_path, start.describe()])
	return true


func _can_write() -> bool:
	return _autosave_enabled and save_system != null


## Écrit la sauvegarde : position du joueur poussée dans GameState, puis écriture atomique.
func _write_save(reason: String) -> Error:
	_save_pending = false
	var map := SceneRouter.get_current_map()
	if not is_instance_valid(map) or not is_instance_valid(_player):
		return ERR_UNAVAILABLE
	GameState.set_player_location(map.map_id, _player.get_cell(), _player.get_facing())
	var error := save_system.write(GameState.to_dict())
	if OS.is_debug_build():
		print("Sauvegarde automatique (%s) : %s %s, %s" % [reason, map.map_id,
			_player.get_cell(), error_string(error)])
	return error


## Identifiant de la carte courante (&"" sans carte).
func _current_map_id() -> StringName:
	var map := SceneRouter.get_current_map()
	return map.map_id if is_instance_valid(map) else &""


func _on_transition_started(_target_map: StringName) -> void:
	_hud.hide_zone_title()
	_hud.hide_caption()


## Écran noir (ou démarrage) : présence des PNJ selon les drapeaux de la partie d'abord
## (jalon 3B §2.6), puis la carte passe aux contrôleurs.
func _on_map_changed(map: GameMap) -> void:
	_observed.clear()
	_apply_lighting(map)
	map.refresh_npcs(GameState.flags)
	_interactions.set_map(map)
	_cutscenes_node.set_map(map)
	_starter_choice.set_map(map)
	_ambient.set_map(map)
	_trainer_watcher.set_map(map)
	_encounters.set_map(map)
	_services.set_map(map)
	_recovery.set_map(map)
	# Décor de combat de la carte chargé en tâche de fond (correctif QA S24 du CB.3).
	_battle_stage.prepare_place(map.map_id)


## Profil de lumière de [param map] ([member GameMap.light_profile]) ; vide ou inconnu :
## aucun effet ([method WorldLighting.apply] avec null).
func _apply_lighting(map: GameMap) -> void:
	var profile: LightProfile = null
	if not map.light_profile.is_empty():
		profile = _light_profiles.get_profile(map.light_profile)
		if profile == null:
			push_error("Boot : profil de lumière inconnu « %s » (%s)" % [map.light_profile,
				map.map_id])
	_lighting.apply(profile, map)


## Arrivée sur une carte (écran visible) : zone découverte, autosave demandé, titre de zone.
func _on_map_entered(map: GameMap) -> void:
	GameState.discover_map(map.map_id)
	request_autosave("changement de carte")
	if _announcer.should_announce(map.display_name, map.interior):
		_hud.show_zone_title(map.display_name, map.region)
		zone_announced.emit(map.display_name, map.region)


func _on_target_changed(kind: int) -> void:
	if kind == InteractionController.NO_TARGET:
		_hud.hide_interact()
	else:
		_hud.show_interact(Interaction.kind_name(kind as Interaction.Kind))


func _on_dialogue_started(_dialogue_id: StringName) -> void:
	_refresh_controls()


func _on_dialogue_finished(_dialogue_id: StringName) -> void:
	_refresh_controls()
	if not _rest_toast.is_empty():
		_hud.show_toast(_rest_toast[0], _rest_toast[1])
		_rest_toast = PackedStringArray()
	if not _pending_shop.is_empty():
		var shop_id := _pending_shop
		_pending_shop = &""
		if not _menu.open(MenuRoute.shop(shop_id), true):
			push_error("Boot : la Boutique « %s » ne s'ouvre pas" % shop_id)
	elif _pending_storage:
		_pending_storage = false
		if not _menu.open(MenuRoute.storage(), true):
			push_error("Boot : le Stockage ne s'ouvre pas sur « %s »" % _current_map_id())


## « open_shop » (le marchand, jalon-07.md §6.10) : la Boutique s'ouvre en écran seul dès la fin
## du dialogue (partie stable). Boutique inconnue : refusée tout de suite.
func _on_shop_requested(shop_id: StringName) -> void:
	if not _shops.has_shop(shop_id):
		push_error("Boot : boutique inconnue « %s »" % shop_id)
		return
	_pending_shop = shop_id


## « open_storage » (le terminal du Centre, jalon-07.md §6.9) : le Stockage s'ouvre en écran
## seul dès la fin du dialogue ; retour = fermer, autosave à la fermeture s'il a changé.
func _on_storage_requested() -> void:
	_pending_storage = true


## Soin demandé par un dialogue « heal » (jalon 5 §3.11, Maman) : l'équipe est soignée (PV et
## PP) ; le point de repos ne change pas (dossier 09 §7).
func _on_heal_requested() -> void:
	_services.heal()
	request_autosave("soin")


## Soin d'un Centre fini (jalon-07.md §5.3) : écriture tout de suite (joueur au comptoir, la
## partie ne peut plus rien perdre), comme au réveil ; le toast du point de repos attend la fin
## du dialogue (après « Voilà. Tout le monde est en pleine forme. »), une fois par changement.
func _on_center_healed(map_id: StringName, registered: bool) -> void:
	if registered:
		_rest_toast = _rest_points.registered_toast(_zones.zone_name_of(map_id))
	if _can_write() and not SceneRouter.is_transitioning():
		_write_save("soin")
	else:
		request_autosave("soin")


func _on_cutscene_started(_cutscene_id: StringName) -> void:
	_refresh_controls()


## Valeurs des jetons des dialogues (jalon-07.md §3.6, T19) : lues au début d'un dialogue qui en
## contient (« Un Roucool… » ; aucune rencontre → la page est omise).
func _dialogue_token_values() -> Dictionary[StringName, String]:
	return DialogueTokens.values_for(GameState.first_wild_species(), _pokemon)


## Une variante de dialogue lance une scène à sa fin (Chen, colis en main → `oak_parcel`). Le
## verrou du joueur passe du dialogue à la scène dans la même image (jalon-07.md §3.6.2).
func _on_cutscene_requested(cutscene_id: StringName) -> void:
	if not _cutscenes_node.play(cutscene_id):
		push_warning("Boot : la scène « %s » demandée par un dialogue n'a pas été jouée"
			% cutscene_id)


func _on_cutscene_finished(_cutscene_id: StringName) -> void:
	_refresh_controls()
	request_autosave("fin de scène")


func _on_battle_state_changed() -> void:
	_refresh_controls()


func _on_encounter_state_changed() -> void:
	_refresh_controls()


## Le starter choisi (jalon 4A) est enregistré « capturé » au Pokédex (décision Q-D), avec
## sa rencontre (labo, niveau et date du choix) et le grand moment « premier Pokémon »
## (jalon 5 §16.3 ; décision de Kevin : premier Pokémon, pas première capture).
func _on_starter_chosen(player_species: StringName, _rival_species: StringName) -> void:
	var map_id := _current_map_id()
	GameState.record_caught(player_species, map_id)
	var members := GameState.party.get_all()
	for i: int in range(members.size() - 1, -1, -1):
		if members[i].species_id == player_species:
			GameState.stamp_meeting(members[i], Pokemon.Origin.STARTER, map_id)
			break
	GameState.record_moment(GameState.MOMENT_STARTER, map_id,
		{"species": String(player_species)})


## Pokémon adverse d'un combat de dresseur envoyé au combat : « vu » au Pokédex, avec la carte
## (le rival au labo, décision Q-D). Les sauvages sont enregistrés par l'[EncounterDirector]
## au début de la rencontre (une seule observation par rencontre).
func _on_battle_event(event: BattleEvent) -> void:
	if event.kind == BattleEvent.Kind.SENT_OUT and event.side == BattleEvent.SideId.FOE \
			and not _encounters.is_running():
		GameState.record_seen(event.species_id, _current_map_id())


## Fin d'un combat de dresseur : grand moment « combat contre le rival » (le rival est le
## dresseur dont l'équipe dépend du starter du joueur, comme dans Rouge/Bleu), puis autosave
## (écrit à la fin de la scène qui contient le combat). Les sauvages passent par
## [method _on_encounter_finished].
func _on_battle_finished(trainer_id: StringName, outcome: int) -> void:
	if trainer_id.is_empty():
		return
	var trainer := _trainers.get_trainer(trainer_id) if _trainers != null else null
	if trainer != null and not trainer.team_by_starter.is_empty():
		var outcome_name: Variant = Battle.Outcome.find_key(outcome)
		GameState.record_moment(GameState.MOMENT_RIVAL_BATTLE, _current_map_id(), {
			"trainer": String(trainer_id),
			"outcome": String(outcome_name).to_lower() if outcome_name != null else "",
		})
	request_autosave("fin de combat")


## Fin d'une rencontre sauvage (victoire, fuite ou défaite → réveil au point de repos) :
## autosave, écrit dès que la partie est stable (après le mot du lieu en cas de défaite).
func _on_encounter_finished(_outcome: int) -> void:
	request_autosave("fin de rencontre")


## Réveil au point de repos après une défaite ([DefeatRecovery] : dernier Centre utilisé, sinon
## la maison ; décision de Kevin du 2026-10-02, QA S3) : la défaite est un fait accompli.
## L'équipe est soignée et le joueur est au point de repos : on écrit tout de suite, avant le mot
## du lieu ; sinon, quitter pendant ce mot effaçait la défaite (retour à la dernière case stable
## d'avant le combat). Une scène interrompue, elle, se rejoue.
func _on_woke_up_after_defeat() -> void:
	if _can_write() and not SceneRouter.is_transitioning():
		_write_save("réveil")
	else:
		request_autosave("réveil")


## Pokémon sauvage capturé et rangé (équipe ou stockage, jalon 5D) : autosave demandé, écrit à
## la première image stable (après la carte de capture et la fin de la rencontre).
func _on_pokemon_caught() -> void:
	request_autosave("capture")


## Objet trouvé dans le monde (étape « give » marquée « found », la Potion de la Route 1) :
## inscrit au journal des objets trouvés avec la carte (§16.3). Les objets reçus d'un
## personnage (les Poké Balls de Chen) n'y entrent pas.
func _on_item_found(item_id: StringName, _count: int) -> void:
	GameState.record_item_found(item_id, _current_map_id())


## Objet donné par une scène (étape « give ») : toast en haut de l'écran, sans rien bloquer
## (jalon-04.md §14.6). L'accord (« Poké Balls ×5 » / « Ajoutées au Sac ») vient de l'objet.
func _on_item_given(item_id: StringName, count: int) -> void:
	var item := _items.get_item(item_id)
	if item == null:
		return
	_hud.show_toast(item.quantity_text(count), item.added_text(count))


## Retour de l'écran : la confirmation de vente de la Boutique, la confirmation ou le menu « ⋯ »
## du Stockage, la fiche du Pokédex, puis le choix du Pokémon du Sac.
func _screen_back() -> bool:
	if _menu_screen.shop_back():
		return true
	if _menu_screen.storage_back():
		return true
	if _menu_screen.has_method(&"pokedex_back") and _menu_screen.call(&"pokedex_back"):
		return true
	return _menu_screen.bag_back()


## OBSERVER (Q-7, jalon-06.md §6.9) : l'espèce est « vue » ici, une fois par individu et par
## visite de la carte. Le toast éventuel vient plus tard (file différée).
func _on_observed(npc: Npc, species: StringName) -> void:
	if _observed.has(npc.get_id()):
		return
	_observed[npc.get_id()] = true
	GameState.record_seen(species, _current_map_id())


## Une espèce vient d'être vue ou capturée : notes rafraîchies, puis toast en attente.
func _on_pokedex_recorded(species: StringName, map: StringName, first_seen: bool,
		new_map: bool, caught: bool) -> void:
	var fresh := PokedexNotes.refresh(GameState.pokedex, _dex, GameState.flags, species)
	var kind := PokedexUpdates.classify(GameState.pokedex, _pokemon, _zones, species, map,
		first_seen, new_map, caught, not fresh.is_empty())
	_queue_dex_toast(species, kind)


## Un drapeau d'histoire a changé : notes de toutes les espèces ; un toast par espèce
## concernée, sauf à l'activation du Pokédex (tout apparaît d'un coup, sans rafale).
func _on_flag_changed(flag: StringName, _value: bool) -> void:
	var fresh := PokedexNotes.refresh(GameState.pokedex, _dex, GameState.flags)
	if flag == StoryFlags.POKEDEX_ACTIVATED:
		return
	for species: StringName in PokedexNotes.species_of(fresh):
		_queue_dex_toast(species, PokedexUpdates.Kind.NEW_NOTE)


func _queue_dex_toast(species: StringName, kind: PokedexUpdates.Kind) -> void:
	for pending: Array in _dex_toasts:
		if pending[0] == species:
			return
	var data := _pokemon.get_species(species)
	var message := PokedexUpdates.message(kind, data.name if data != null else "",
		_unlocks.pokedex_visible())
	if not message.is_empty():
		_dex_toasts.append([species, message])


## Un toast à la fois, seulement partie stable, menu fermé, aucun toast à l'écran.
func _show_next_dex_toast() -> void:
	if _menu.is_open() or not is_stable() or _hud.get_toast().is_showing():
		return
	var message: PackedStringArray = _dex_toasts.pop_front()[1]
	_hud.show_toast(message[0], message[1])


## Contrôles visibles seulement hors dialogue, hors scène, hors fiche du starter et hors
## combat : pendant une scène ou un combat, ils restent cachés entre deux dialogues.
func _refresh_controls() -> void:
	_hud.set_controls_visible(not _menu.is_open() and not _runner.is_running() and not _cutscenes_node.is_running()
		and not _starter_choice.is_sheet_open() and not _battle_director.is_running()
		and not _encounters.is_running())


## Lit les réglages (fichier de l'appareil, indépendant de la sauvegarde et du départ de
## débogage) et les applique, avant le premier dialogue (jalon-06.md §6.12).
func _load_settings() -> void:
	if settings_store == null and get_tree().current_scene == self:
		settings_store = SettingsStore.new()
	if settings_store != null:
		_settings = settings_store.load_settings()
		if settings_store.last_status != OK and settings_store.last_status != ERR_FILE_NOT_FOUND:
			push_warning("Réglages : %s (valeurs par défaut)" % settings_store.last_error)
	if device.is_empty():
		device = GraphicsProfile.current_device()
	_apply_settings(_settings)


func _profile_device_quality() -> GameSettings.Graphics:
	return GraphicsProfile.auto_quality(device)


## Un réglage a changé (geste de l'écran) : fichier réécrit, puis effet.
func _on_settings_changed(settings: GameSettings) -> void:
	if settings_store != null:
		var error := settings_store.save_settings(settings)
		if error != OK:
			push_error("Réglages : écriture impossible (%s)" % error_string(error))
	_apply_settings(settings)


## Fait agir [param s] dans le jeu (jalon-06.md §6.12). Les écrans reçoivent les réglages
## par leurs méthodes dédiées (derrière `has_method` tant que le HUD du T28 n'est pas là).
func _apply_settings(s: GameSettings) -> void:
	_settings = s
	_runner.chars_per_second = s.chars_per_second()
	_battle_director.speed_scale = s.battle_speed_scale()
	_battle_director.confirm_forget = s.confirm_actions
	_battle_hud.message_hold_scale = 1.0
	_battle_stage.reduce_flashes = s.reduce_flashes
	if _evolution_screen != null:
		_evolution_screen.reduce_flashes = s.reduce_flashes
	_services.reduce_motion = s.reduce_motion
	_menu_screen.speed_scale = s.menu_speed_scale()
	Haptics.enabled = s.haptics
	UiPrefs.apply(s)
	if _hud.has_method(&"set_left_handed"):
		_hud.call(&"set_left_handed", s.left_handed)
	if _hud.has_method(&"set_joystick_style"):
		_hud.call(&"set_joystick_style", s.joystick_scale, s.joystick_opacity)
	if _hud.has_method(&"set_button_scale"):
		_hud.call(&"set_button_scale", s.button_scale)
	_profile = GraphicsProfile.resolve(s.graphics, device)
	Engine.max_fps = _profile.max_fps
	if _menu_screen.has_method(&"set_backdrop_blur"):
		_menu_screen.call(&"set_backdrop_blur", _profile.menu_blur)
	_battle_stage.backdrop_blur = not _profile.reduced_effects
	_lighting.set_reduced_effects(_profile.reduced_effects)


## « Sauvegarder maintenant » : écrit la sauvegarde et affiche le résultat dans l'écran.
func _on_save_requested() -> void:
	var text := SettingsViews.SAVE_DISABLED_TEXT
	if _can_write():
		var error := _write_save("menu")
		text = SettingsViews.save_result_text(error, Time.get_datetime_dict_from_system())
	_menu.show_save_result(text)
