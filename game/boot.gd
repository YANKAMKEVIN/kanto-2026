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
## Ouverture (OUV.1, dossier 13 §3.1, §3.7) : **seulement quand Boot est la scène principale
## lancée par le moteur, sans départ de débogage**, le démarrage passe par l'[OpeningDirector] :
## écran titre sur Bourg Palette en mode décor ([TitleBackdrop]), Continuer / Nouvelle partie /
## Paramètres. Rien n'est écrit tant qu'il est affiché : **tout** autosave passe par la seule garde
## [method _can_write] (`_opening == null or _opening.autosave_allowed()`). Sous GUT et dans les
## outils de capture (Boot hors scène courante), le démarrage est inchangé : sauvegarde injectée
## reprise, ou nouvelle partie dans la chambre.
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
const MAX_PLAY_TIME_STEP: float = SessionLifecycle.MAX_PLAY_TIME_STEP
## Décor de l'introduction de Chen (OUV.2, dossier 13 §9.0) : le labo, cadré en son centre
## (16 × 11 cases ; défaut, règle 4).
const INTRO_BACKDROP_MAP: StringName = &"oak_lab"
const INTRO_BACKDROP_FOCUS: Vector2 = Vector2(768, 528)
## Le labo (1536 px de large) est plus étroit que l'écran (jusqu'à 2340) : agrandi pour le remplir.
const INTRO_BACKDROP_ZOOM: float = 1.6
## Raison de blocage du joueur pendant le fondu d'arrivée dans la chambre (OUV.3).
const OPENING_ARRIVAL: StringName = &"opening_arrival"
## Narration de la Corde Sortie (jalon 12, dossier 15 §20 n° 33) :
## `data/dialogues/field_items.json`.
const ESCAPE_ROPE_DIALOGUE: StringName = &"escape_rope_used"
## Raison de blocage du joueur pendant une évolution par pierre hors combat (jalon 12, T23).
const EVOLUTION_ITEM: StringName = &"evolution_item"
## Raison de blocage du joueur pendant tout le déroulé d'un Super Bonbon (jalon 14, T18b) : voile
## au-dessus du menu, puis évolution éventuelle. La partie n'est pas stable : aucune écriture.
const RARE_CANDY: StringName = &"rare_candy"

@export var start_map: StringName = &"player_house_2f"
@export var start_spawn: StringName = &"start"
@export var start_facing: Vector2i = Vector2i.DOWN
## Fichier du départ de débogage ([DebugStart]) ; lu seulement en build debug, quand Boot est
## la scène principale lancée par le moteur, et si le fichier existe (jamais sous GUT).
var debug_start_path: String = DebugStart.USER_PATH
## Tests seulement : appliquer le départ de débogage même sous GUT (jamais en jeu).
var force_debug_start: bool = false
## Tests seulement : grottes lues dans un autre fichier (J17 T28 : la Cave Taupiqueur rendue
## obscure pour éprouver le voile et Flash dans le vrai Boot ; jamais en jeu).
var caves_path: String = CaveLibrary.DATA_PATH
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
## Durées de l'ouverture multipliées (fondus, écrans ; 0 = instantané, tests et captures).
var opening_speed_scale: float = 1.0

var _settings := GameSettings.new()
var _profile: GraphicsProfile
var _player: Player
var _announcer := ZoneAnnouncer.new()
## Légende de la toute première sortie (OUV.3) et carte quittée par la transition en cours (&"" :
## démarrage, reprise).
var _first_exit := FirstExitCaption.new()
var _arrival_from: StringName = &""
var _library := DialogueLibrary.new()
var _cutscenes := CutsceneLibrary.new()
var _pokemon := PokemonData.new()
var _offer := StarterOffer.new()
var _trainers: TrainerLibrary
## Badges de Kanto (jalon 10 : étape de scène « badge »).
var _badges: BadgeLibrary = BadgeLibrary.new()
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
## Départ de débogage sans écriture, ou Boot d'un outil sans SaveSystem injecté.
## Les points critiques y sont simulés ; jamais activé pour une vraie partie refusée.
var _simulate_checkpoints: bool = false
## Voile de l'apprentissage d'une CT depuis le Sac (jalon 11), créé au premier besoin.
var _tm_overlay: TmLearnOverlay
## Pension (J15, jalon-15.md §2.5) : directeur (pas, conversation) ; le gardien (`open_daycare`)
## la demande, elle commence à la fin de son dialogue.
var _daycare: DaycareDirector
var _pending_daycare: bool = false
## Compagnon (jalon 11, 11D) : espèces éligibles et contrôleur (nœud créé tout de suite pour
## recevoir les réglages).
var _companions := CompanionCatalog.new()
var _companion := CompanionController.new()
## Mise en scène des capacités de terrain (jalon 16, Coupe : le Pokémon qui coupe, l'effet).
var _field_presenter := FieldMovePresenter.new()
## Écran de la Pension (J15 T5) : choix du dépôt, bandeau et hôte des capacités du retrait.
var _daycare_overlay: DaycareOverlay
## J25 : choix du Pokémon d'un échange fixe.
var _trade_overlay: TradeOverlay
## Coordination locale : aucun nouvel autoload, dépendances câblées dans _ready.
var _save_coordinator := SaveCoordinator.new()
var _lifecycle := SessionLifecycle.new()
var _settings_applier := SettingsApplier.new()
## Ouverture (OUV.1) : null hors scène principale ou avec un départ de débogage.
var _opening: OpeningDirector = null
## Bourg Palette en mode décor derrière le titre (libéré en quittant le titre).
var _title_backdrop: TitleBackdrop = null
## Grottes de Kanto (jalon 12, T20 : Corde Sortie, `data/world/caves.json`).
var _caves := CaveLibrary.new()
## Capacités de terrain (jalon 16 Coupe, jalon 17 Flash) : data/world/field_moves.json.
var _field_moves := FieldMoves.new()
## Puzzles d'interrupteurs (jalon 16, Arène de Carmin) : data/world/switch_puzzles.json.
var _switch_puzzles := SwitchPuzzleLibrary.new()
## Puzzle de la carte courante (identifiant → [SwitchPuzzle]) : créé à la première fouille, oublié
## à chaque arrivée sur une carte (état jamais sauvegardé, nouveau tirage au retour).
var _active_puzzles: Dictionary[StringName, SwitchPuzzle] = {}
## Pierre en cours d'utilisation (jalon 12, T23) : retirée du Sac à
## [signal EvolutionDirector.evolution_applied], une seule fois ; &"" sinon.
var _stone_item: StringName = &""
## Place du Pokémon qui reçoit un Super Bonbon pendant son déroulé (jalon 14, T18b) ; −1 sinon.
var _candy_index: int = -1
## Voile d'obscurité des grottes obscures (J17 T9, brique commune avec le J18 :
## `docs/tech/jalon-18.md` §2) : posé à chaque changement de carte (écran noir).
var _darkness: DarknessController
## Départ de débogage « veil » (J18 §2.12) : voile forcé sur cette carte pour la session
## (&"dark" ou &"lit"), jamais sauvegardé ; &"" sinon.
var _veil_debug_map: StringName = &""
var _veil_debug: StringName = &""
## Flash automatique à l'arrivée sur une carte obscure (J17 T24, Q-1 « tout J17 » ; contrat commun
## avec le J18, `jalon-18.md` §3.3).
var _flash: FlashDirector
## J20 (T13, `jalon-20.md` §2.3) : ascenseurs (cabine, panneau, trajet, position sauvée).
var _elevators := ElevatorLibrary.new()
var _elevator: ElevatorDirector
var _elevator_panel: ElevatorPanel
var _pending_elevator: bool = false
## J20 (T19, `jalon-20.md` §2.4.4) : dalles tournantes du repaire (glisse, verrou, reprise).
var _forced_slide: ForcedSlideDirector
## Passe systèmes 2 (S2B) : monture (Vélo) et objets clés utilisables (Bicyclette, Poké Flûte).
var _mount: MountDirector
var _key_items: KeyItemDirector

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
	_save_coordinator.setup(_can_write, is_stable, _persist_snapshot)
	_setup_save_checkpoint()
	GameState.new_game()
	_lighting = WorldLighting.new()
	_lighting.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_lighting)
	_wire_settings_applier()
	_light_profiles.load_file()
	_darkness = DarknessController.new()
	_darkness.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_darkness)
	_flash = FlashDirector.new()
	_flash.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_flash)
	# J20 (T13) : directeur de l'ascenseur, créé avant les réglages (« Réduire les animations »).
	_elevator = ElevatorDirector.new()
	_elevator.name = "ElevatorDirector"
	_elevator.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_elevator)
	_load_settings()
	# Compteur de fps de QA (journal « [perf] »), seulement en build debug, Boot scène principale.
	if PerfCounter.is_allowed(OS.is_debug_build(), get_tree().current_scene == self):
		add_child(PerfCounter.new())
	_player = PLAYER_SCENE.instantiate() as Player
	_darkness.setup(_world, _player)
	_library.load_dir()
	_cutscenes.load_dir()
	_runner.setup(_library, GameState.flags, _dialogue_box, _player)
	_setup_forced_slides()
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
	_trainer_watcher.setup(_player, GameState.flags, _cutscenes_node, GameState)
	_interactions.set_story_flags(GameState.flags)
	_interactions.challenge_requested.connect(_trainer_watcher.challenge)
	_pokemon.load_dir()
	# Combats sauvages scriptés (jalon 19) : leurs espèces sont vérifiées une fois les données
	# Pokémon chargées (une scène qui nomme une espèce inconnue est écartée).
	_cutscenes.check_species(_pokemon)
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
	if not _field_moves.load_file():
		for error: String in _field_moves.get_errors():
			push_error("Boot : %s" % error)
	_switch_puzzles.load_file()
	_items.check_moves(_pokemon)
	_battle_director.setup(_pokemon, _trainers, _texts, _battle_stage, _battle_hud, _player,
		GameState, _items)
	# CB.1 : artwork officiel de l'adversaire (numéro) et tailles réelles (Pokédex).
	_battle_stage.set_species_source(_pokemon, _dex)
	_cutscenes_node.set_battle_runner(_battle_director)
	# Jalon 10 (jalon-10.md §2.7, §2.8) : carte de présentation d'un Champion (bloc « card » de son
	# Dresseur) et remise d'un badge (légende, vibration, Grand moment « badge »).
	_cutscenes_node.set_trainers(_trainers)
	_badges.load_file()
	_cutscenes_node.set_badges(_badges, GameState)
	# J20 (§2.5.2, T12) : don de Pokémon (étape « gift_pokemon », Évoli) ; le Pokédex suit par
	# GameState.pokedex.recorded (toasts existants).
	_cutscenes_node.set_pokemon_data(_pokemon)
	_cutscenes_node.pokemon_gifted.connect(_on_pokemon_gifted)
	# J25 (§2.5) : échanges fixes du Labo (étape « trade ») : choix sur le sélecteur de l'équipe.
	_trade_overlay = TradeOverlay.new()
	_trade_overlay.name = "TradeOverlay"
	_trade_overlay.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_trade_overlay)
	_cutscenes_node.trade_pick_handler = _on_trade_pick_requested
	_cutscenes_node.pokemon_traded.connect(_on_pokemon_traded)
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
	# Pension (J15, jalon-15.md §2.5) : compteur de pas sur le joueur, conversation du gardien.
	_daycare = DaycareDirector.new()
	_daycare.name = "DaycareDirector"
	_daycare.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_daycare)
	_daycare.setup(GameState, _player, _runner, _library, _pokemon, DaycareConfig.load_default())
	_daycare.set_learning(_battle_director.get_move_learn_prompt(), _evolutions)
	_daycare_overlay = DaycareOverlay.new()
	_daycare_overlay.name = "DaycareOverlay"
	_daycare_overlay.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_daycare_overlay)
	_daycare_overlay.attach(_daycare,
		func(view: DaycarePickView) -> PartyPickerView: return view.to_picker_view(_pokemon))
	_daycare.overlay = _daycare_overlay
	_daycare.deposited.connect(_on_daycare_deposited.unbind(1))
	_daycare.finished.connect(_on_daycare_finished)
	_services.daycare_requested.connect(_on_daycare_requested)
	_setup_elevators()
	_setup_teleporters()
	_setup_fly()
	_setup_field_travel()
	_cutscenes_node.set_inventory(GameState.bag, _items)
	# Remise du colis (jalon-07.md §3.6.2, T19) : jeton {first_wild_species} des répliques de
	# Chen, scène lancée par une variante de dialogue (« colis en main »), légende POKÉDEX ACTIVÉ.
	_runner.token_values = _dialogue_token_values
	# Variantes « une fois sur N » (jalon 14) : l'aléatoire de la partie courante.
	_runner.rng_source = func() -> GameRng: return GameState.rng
	# J17 (§2.5) : variantes selon les espèces capturées (assistant de Chen, CS05).
	_runner.caught_count = func() -> int: return GameState.pokedex.caught_count()
	# Capacités de terrain (jalon 16) : état de Coupe pour les variantes « field » de l'arbuste.
	_runner.field_source = field_state
	# Jalon 20 (§2.9.6, §2.16) : variantes selon le Sac et selon les zones jouables (postes de
	# Safrania).
	_runner.item_source = func(id: StringName) -> bool: return (GameState.bag as Bag).has(id)
	_runner.zone_source = _zones.is_playable
	# OUV.2 : prénoms du joueur et du rival (`{player}`, `{rival}`) aussi dans le nom du dresseur.
	_texts.token_values = _dialogue_token_values
	_runner.cutscene_requested.connect(_on_cutscene_requested)
	_cutscenes_node.set_hud(_hud)
	_cutscenes_node.item_given.connect(_on_item_given)
	# Jalon 16 : écriture immédiate demandée par une scène (départ du S.S. Anne).
	_cutscenes_node.save_handler = _on_cutscene_save_requested
	_cutscenes_node.save_failed.connect(_on_checkpoint_save_failed)
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
	_first_exit.load_file()
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
	_setup_companion()
	_setup_caves()
	_setup_flash()
	_setup_mount()
	_setup_fishing()
	_setup_strength()
	_setup_evolution_items()
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
		_menu_screen.team_companion_toggled.connect(_menu.toggle_companion)
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
		# Jalon 11 (T12) : apprendre une CT par-dessus le menu.
		_menu.tm_learn_requested.connect(_on_tm_learn_requested)
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
	_interactions.puzzle_searched.connect(_on_puzzle_searched)
	_hud.menu_requested.connect(_menu.open)
	SceneRouter.setup(_world, _player, _fade)
	# Destinations « à venir » (dossier-07 §12, build de développement) : l'écran provisoire.
	SceneRouter.coming_soon_presenter = _coming_soon.present
	# Décors qui suivent les drapeaux à jour avant de poser le joueur (arbuste coupé J16 T14,
	# Ronflex J17 T5) : un seul branchement pour les deux jalons.
	SceneRouter.arrival_flags = func() -> StoryFlags: return GameState.flags
	# Branchés avant start() : la première carte passe aussi par le contrôleur.
	SceneRouter.transition_started.connect(_on_transition_started)
	# Via Boot (ordre garanti) : présence des PNJ, puis le contrôleur, puis le directeur.
	SceneRouter.map_changed.connect(_on_map_changed)
	SceneRouter.map_entered.connect(_on_map_entered)
	SceneRouter.map_entered.connect(_interactions.on_map_entered)
	SceneRouter.map_entered.connect(_starter_choice.on_map_entered)
	SceneRouter.coming_soon_finished.connect(_on_coming_soon_finished)
	_start_game()
	_menu.set_settings(_settings, _profile_device_quality(), _can_write())


func _process(delta: float) -> void:
	GameState.add_play_time(_lifecycle.play_time_step(delta, _is_opening_active()))
	_watch_save_checkpoint(delta)
	_save_coordinator.process(delta)
	if not _dex_toasts.is_empty():
		_show_next_dex_toast()


## Boot transmet les notifications ; le cycle de vie décide du temps de jeu, le point de reprise
## de ce qui s'écrit à la mise en arrière-plan (passe systèmes 2, S2A).
func _notification(what: int) -> void:
	if _lifecycle.handle_notification(what):
		_save_in_background("arrière-plan")
	_on_focus_change(SessionLifecycle.focus_change(what))
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_go_back()


## Action `menu` (Échap, M) : ouvre le menu en exploration, le ferme s'il est ouvert (après avoir
## refermé le choix du Pokémon du Sac s'il est ouvert).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu") and not event.is_echo():
		if _is_opening_active():
			# Écran titre (Mac) : comme le retour Android.
			_opening.handle_back()
		elif _candy_index >= 0:
			pass  # Super Bonbon : le déroulé va à son terme (ni menu fermé, ni ouvert).
		elif _menu.is_open():
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
		[SceneRouter.coming_soon_finished, _on_coming_soon_finished],
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


## Pension (J15) : écran du dépôt et des capacités.
func get_daycare_overlay() -> DaycareOverlay:
	return _daycare_overlay


func get_daycare_director() -> DaycareDirector:
	return _daycare


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


## État de la capacité de terrain [param move] pour la partie courante (jalon 16, [FieldMoves]) :
## équipe, Sac, drapeaux, compagnon choisi.
func field_state(move: StringName) -> FieldMoves.Result:
	return _field_moves.check(move, GameState.party, GameState.bag, GameState.flags, _items,
		_pokemon, GameState.get_companion())


## Le Pokémon qui utilise la capacité de terrain [param move] (état READY), ou null.
func _field_move_user(move: StringName) -> Pokemon:
	var state := field_state(move)
	if state.state != FieldMoves.State.READY:
		return null
	return GameState.party.get_at(state.pokemon_index)


## Vrai si la scène [param cutscene_id] commence par une capacité de terrain que le compagnon
## utilise lui-même (jalon 16) : il reste alors dehors pour couper.
func _companion_cuts(cutscene_id: StringName) -> bool:
	var cutscene := _cutscenes.get_cutscene(cutscene_id)
	var move := cutscene.leading_field_move(GameState.flags) if cutscene != null else &""
	if move.is_empty():
		return false
	var chosen := _companion.get_chosen()
	return chosen != null and _field_move_user(move) == chosen


## Fouille de l'objet [param slot] du puzzle [param puzzle_id] (jalon 16, `jalon-16.md` §2.6) :
## puzzle déjà résolu (drapeau) → « rien » ; sinon le puzzle de la carte (tiré à la première
## fouille depuis l'arrivée) répond, et Boot joue le dialogue du résultat, ou la scène de la
## réussite (qui ouvre la barrière et lève le drapeau). Puzzle inconnu : push_error.
func _on_puzzle_searched(puzzle_id: StringName, slot: int) -> void:
	var spec := _switch_puzzles.get_spec(puzzle_id)
	if spec == null:
		push_error("Boot : puzzle inconnu « %s »" % puzzle_id)
		return
	var map := SceneRouter.get_current_map()
	if GameState.flags.has_flag(spec.solved_flag):
		_runner.play(spec.nothing, null, map)
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
		if not _cutscenes_node.play(spec.solved_cutscene):
			push_error("Boot : la scène « %s » du puzzle n'a pas été jouée" % spec.solved_cutscene)
		return
	_runner.play(spec.dialogue_for(result), null, map)


## Puzzle d'interrupteurs en cours sur la carte (tests, QA) ; null s'il n'a pas encore été fouillé.
func get_active_puzzle(puzzle_id: StringName) -> SwitchPuzzle:
	return _active_puzzles.get(puzzle_id)


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
		and not _battle_director.is_running() and not _encounters.is_running() \
		and not _flash.is_running() and not _elevator.is_running() \
		and not _forced_slide.is_running()


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
	# Ouverture (OUV.1) : Paramètres ou confirmation refermés ; au titre, rien (§5.2).
	if _opening != null and _opening.handle_back():
		return
	# Bilan de fin de combat affiché : retour = le fermer (demande n° 1).
	if _battle_director.handle_back():
		return
	# Super Bonbon (jalon 14) : voile du niveau et des capacités, retour absorbé (l'évolution qui
	# suit, annulable, l'a reçu juste au-dessus).
	if _candy_index >= 0:
		return
	# Un choix à deux cartes dans un dialogue (SOIGNER / PAS MAINTENANT) : retour = annuler.
	if _dialogue_box.cancel_choice():
		return
	# Pension (J15) : écran du dépôt = ANNULER ; le reste de la conversation avale le geste.
	if _daycare.handle_back():
		return
	# J25 : choix du Pokémon d'un échange = ANNULER.
	if _trade_overlay != null and _trade_overlay.handle_back():
		return
	# J20 (T13) : panneau d'étages = FERMER ; pendant un trajet, avalé.
	if _elevator.handle_back():
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
		_push_stable_location(here.map_id)
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
	# Compagnon : FAIRE SORTIR / RAPPELER, dépôt, Potion sur un K.O. (sortie ou rentrée).
	_companion.refresh()
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
	_save_coordinator.request(reason)


## Démarrage (jalon 5C.5) : départ de débogage s'il est appliqué (ni lecture ni écriture de
## la sauvegarde), sinon reprise de la sauvegarde si elle se charge, sinon nouvelle partie sur
## [member start_map] / [member start_spawn].
func _start_game() -> void:
	if _start_game_state():
		_finish_start()


## Fin commune du démarrage (partie en place).
func _finish_start() -> void:
	# Parties existantes : notes débloquées sans bruit (jalon-06.md §6.9, point 4).
	PokedexNotes.refresh(GameState.pokedex, _dex, GameState.flags)
	_dex_toasts.clear()


## Vrai si la partie est en place ; faux si l'ouverture est montrée (la partie démarrera à son
## signal : [method _on_opening_resumed], [method _on_opening_new_game]). Ordre : départ de
## débogage (inchangé), Boot hors scène courante (tests, outils : inchangé), sinon l'ouverture.
func _start_game_state() -> bool:
	if _apply_debug_start():
		_simulate_checkpoints = not _debug_start_autosave
		if _debug_start_autosave:
			_open_save_system()
			_autosave_enabled = save_system != null
			print("Départ de débogage : la sauvegarde n'est pas lue, elle sera REMPLACÉE.")
		else:
			print("Départ de débogage : la sauvegarde n'est ni lue ni écrite.")
	elif get_tree().current_scene == self:
		_open_save_system()
		_start_opening()
		return false
	else:
		_simulate_checkpoints = save_system == null
		_open_save_system()
		if save_system != null and _load_save() and _resume():
			return true
	SceneRouter.start(start_map, start_spawn, start_facing)
	return true


## L'ouverture (OUV.1) : Bourg Palette en mode décor sous le titre, le directeur lit la sauvegarde
## et montre le titre. Le HUD d'exploration est caché jusqu'au démarrage de la partie.
func _start_opening() -> void:
	_autosave_enabled = save_system != null
	_hud.visible = false
	_title_backdrop = TitleBackdrop.new()
	_title_backdrop.name = "TitleBackdrop"
	_world.add_child(_title_backdrop)
	_title_backdrop.set_reduce_motion(_settings.reduce_motion)
	_title_backdrop.show_map()
	_opening = OpeningDirector.new()
	_opening.name = "OpeningDirector"
	_opening.process_mode = Node.PROCESS_MODE_PAUSABLE
	_opening.speed_scale = opening_speed_scale
	add_child(_opening)
	var badge_flags: Array[StringName] = []
	for badge: StringName in _badges.ids():
		badge_flags.append(_badges.flag(badge))
	_opening.setup(save_system, _build_new_game, _fade, _settings, _profile_device_quality(),
		_zones.zone_name_of, badge_flags)
	_opening.set_dialogue_box(_dialogue_box)
	_opening.title_closed.connect(_release_title_backdrop)
	_opening.intro_opened.connect(_show_intro_backdrop)
	_opening.intro_closed.connect(_release_title_backdrop)
	_opening.resumed.connect(_on_opening_resumed)
	_opening.new_game_entered.connect(_on_opening_new_game)
	_opening.settings_changed.connect(_on_settings_changed)
	_opening.apply_settings(_settings, _profile.menu_blur)
	_opening.run()


## Vrai tant que l'écran titre occupe le jeu (avant la reprise ou la chambre).
func _is_opening_active() -> bool:
	return _opening != null and _opening.is_active()


## Directeur de l'ouverture (null hors scène principale ou avec un départ de débogage).
func get_opening() -> OpeningDirector:
	return _opening


## Décor du titre (null une fois le titre quitté, ou sans ouverture).
func get_title_backdrop() -> TitleBackdrop:
	return _title_backdrop


## Introduction de Chen (OUV.2, dossier 13 §9.0) : le vrai labo en mode décor, sans dérive, sous
## sa lumière de jeu ; l'introduction le floute et le dore ([IntroStage]).
func _show_intro_backdrop() -> void:
	_release_title_backdrop()
	_title_backdrop = TitleBackdrop.new()
	_title_backdrop.name = "IntroBackdrop"
	_title_backdrop.map_id = INTRO_BACKDROP_MAP
	_title_backdrop.focus = INTRO_BACKDROP_FOCUS
	_title_backdrop.drift = Vector2.ZERO
	_title_backdrop.zoom = INTRO_BACKDROP_ZOOM
	_world.add_child(_title_backdrop)
	if _title_backdrop.show_map():
		_apply_lighting(_title_backdrop.get_map())


## Le titre (ou l'introduction) se ferme (rideau baissé) : le décor est libéré avant le commit ou
## la reprise.
func _release_title_backdrop() -> void:
	if _title_backdrop != null:
		_title_backdrop.release()
		_title_backdrop = null


## Nouvelle partie de l'ouverture (constructeur du commit, dossier 13 §3.7 étape 2) : partie
## neuve en mémoire, prénoms (vides : défauts), héros, joueur dans la chambre face au sud ; rend
## le dictionnaire à écrire.
func _build_new_game(player_name: String, rival_name: String) -> Dictionary:
	GameState.new_game()
	if not player_name.is_empty():
		GameState.player_name = player_name
	if not rival_name.is_empty():
		GameState.rival_name = rival_name
	GameState.player_look = GameState.DEFAULT_PLAYER_LOOK
	GameState.set_player_location(start_map, _spawn_cell(start_map, start_spawn), start_facing)
	return GameState.to_dict()


## Case du point d'apparition [param spawn] de [param map_id], lue dans la scène de la carte
## (instanciée hors de l'arbre, puis libérée) ; (-1, -1) si elle manque.
func _spawn_cell(map_id: StringName, spawn: StringName) -> Vector2i:
	var path := MapCatalog.scene_path(map_id)
	var packed := load(path) as PackedScene if ResourceLoader.exists(path) else null
	var map := packed.instantiate() as GameMap if packed != null else null
	if map == null:
		return Vector2i(-1, -1)
	var cell := map.get_spawn_cell(spawn) if map.has_spawn(spawn) else Vector2i(-1, -1)
	map.free()
	return cell


## Continuer : la partie lue au lancement est chargée et reprise là où elle était.
func _on_opening_resumed(save: Dictionary) -> void:
	if not GameState.load_dict(save, _pokemon):
		_keep_rejected_save()
	_resumed = true
	print("Sauvegarde chargée : %s %s (temps de jeu %d s)" % [GameState.current_map,
		GameState.player_cell, int(GameState.play_time)])
	_log_loaded_save()
	_repair_key_items()
	if not _resume():
		SceneRouter.start(start_map, start_spawn, start_facing)
	_finish_opening()


## Nouvelle partie : la chambre, face au sud, sans titre de zone ni dialogue (dossier 13 §4
## plan 9). Elle apparaît en fondu depuis le blanc chaud de la fin de l'introduction (OUV.3) ;
## le joueur et les contrôles ne sont rendus **qu'à la fin du fondu** (la première autosave suit,
## partie stable). [param warning] : la partie n'a pas pu être écrite (elle continue sans
## sauvegarde).
func _on_opening_new_game(warning: String) -> void:
	# Bloqué avant la pose de la chambre : map_entered (synchrone) le trouve déjà immobile.
	_player.set_input_enabled(false, OPENING_ARRIVAL)
	SceneRouter.start(start_map, start_spawn, start_facing)
	await _finish_opening(false)
	_hud.visible = true
	_player.set_input_enabled(true, OPENING_ARRIVAL)
	_refresh_controls()
	if not warning.is_empty():
		_hud.show_toast(warning, "")


## La partie a démarré après le titre (coroutine, rend la main à la fin du fondu) : HUD rendu
## tout de suite si [param show_hud] (Continuer ; sinon par l'appelant), faits rafraîchis,
## « Sauvegarder maintenant » selon la garde, rideau levé (depuis le blanc chaud après
## l'introduction, durées raccourcies par « Réduire les animations » :
## [method OpeningDirector.entry_fade_time]).
func _finish_opening(show_hud: bool = true) -> void:
	_hud.visible = show_hud
	_finish_start()
	_menu.set_settings(_settings, _profile_device_quality(), _can_write())
	_refresh_controls()
	_fade.set_opaque(true)
	await _fade.fade_in(_opening.entry_fade_time())


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
			_repair_key_items()
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


## Rattrapage des objets remis par une scène (J16 T13, [KeyItemRepair]) : CS01 sans
## `got_hm01` → drapeau levé ; `got_hm01` sans CS01 → objet rendu une fois. Journalisé.
func _repair_key_items() -> void:
	var repair := KeyItemRepair.new()
	if not repair.load_file():
		push_warning("Boot : rattrapage des objets illisible : %s" % ", ".join(repair.get_errors()))
		return
	for note: String in repair.apply(GameState.flags, GameState.bag):
		print("[qa] rattrapage : " + note)


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
	# J15 (v7) : Pension relue (session 15.0).
	if not GameState.daycare.is_empty():
		var kept: Pokemon = GameState.daycare.pokemon
		print("[qa] pension relue : %s N%d (dépôt N%d), %d XP en attente, uid %s" % [
			kept.display_name(_pokemon), kept.level, GameState.daycare.deposit_level,
			GameState.daycare.pending_exp, kept.uid])


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
	_veil_debug = start.veil
	_veil_debug_map = start.map if not start.veil.is_empty() else &""
	if not start.wild.is_empty():
		_encounter_library.override_table(start.map, start.wild_terrain, start.wild,
			debug_start_path)
	if not start.map.is_empty():
		start_map = start.map
		start_spawn = start.spawn
		start_facing = start.facing
	print("Départ de débogage (%s) : %s" % [debug_start_path, start.describe()])
	return true


## **La** garde de toute écriture de la sauvegarde par Boot (entrée de carte, fin de scène, de
## combat, de capture, soins, réveil, retour, arrière-plan, « Sauvegarder maintenant ») : session
## avec écriture, et ouverture absente ou terminée sur une partie stable sur le disque
## ([method OpeningDirector.autosave_allowed], OUV.1).
func _can_write() -> bool:
	return _autosave_enabled and save_system != null \
		and (_opening == null or _opening.autosave_allowed())


## Écrit la sauvegarde : position du joueur poussée dans GameState, puis écriture atomique.
func _write_save(reason: String) -> Error:
	return _save_coordinator.write_now(reason)


## Adaptateur du coordinateur : relit la position et l'état au moment de l'écriture.
## La permission a été vérifiée par SaveCoordinator, pour chaque chemin d'appel.
func _persist_snapshot(reason: String) -> Error:
	var map := SceneRouter.get_current_map()
	if not is_instance_valid(map) or not is_instance_valid(_player):
		return ERR_UNAVAILABLE
	_push_stable_location(map.map_id)
	var snapshot := GameState.to_dict()
	var error := save_system.write(snapshot)
	if error == OK:
		_checkpoint.note_written(snapshot, background_clock.call(), _background_write)
	if OS.is_debug_build():
		print("Sauvegarde automatique (%s) : %s %s, %s" % [reason, map.map_id,
			_player.get_cell(), error_string(error)])
	return error


## Identifiant de la carte courante (&"" sans carte).
func _current_map_id() -> StringName:
	var map := SceneRouter.get_current_map()
	return map.map_id if is_instance_valid(map) else &""


func _on_transition_started(_target_map: StringName) -> void:
	_companion.on_transition_started()
	_arrival_from = _current_map_id()
	_hud.hide_zone_title()
	_hud.hide_caption()


## Fin de l'écran « à venir » (même carte, aucun [signal SceneRouter.map_entered]) : ferme la
## transition ouverte par [method _on_transition_started] (QA finale 12D : le compagnon restait
## caché jusqu'au changement de carte suivant).
func _on_coming_soon_finished(_map: GameMap) -> void:
	_arrival_from = &""
	_companion.on_transition_finished()


## Écran noir (ou démarrage) : présence des PNJ selon les drapeaux de la partie d'abord
## (jalon 3B §2.6), puis la carte passe aux contrôleurs.
func _on_map_changed(map: GameMap) -> void:
	_observed.clear()
	_flash.on_map_changed(map)
	_apply_lighting(map)
	_apply_darkness(map)
	map.refresh_npcs(GameState.flags)
	_interactions.set_map(map)
	_cutscenes_node.set_map(map)
	_starter_choice.set_map(map)
	_ambient.set_map(map)
	_trainer_watcher.set_map(map)
	_encounters.set_map(map)
	_services.set_map(map)
	_daycare.set_map(map)
	_recovery.set_map(map)
	# J20 (T13) : cabine d'ascenseur (étage courant d'après la carte quittée, sortie réorientée).
	_elevator.set_map(map, _arrival_from)
	# J20 (T19) : dalles tournantes ; joueur posé sur une dalle → case stable (avant le compagnon).
	_forced_slide.set_map(map)
	_companion.on_map_changed(map)
	_field_presenter.set_map(map)
	# Décor de combat de la carte chargé en tâche de fond (correctif QA S24 du CB.3).
	_battle_stage.prepare_place(map.map_id)


## Compagnon (jalon 11, 11D ; `docs/tech/jalon-11-compagnon.md`) : espèces éligibles (Équipe :
## FAIRE SORTIR / RAPPELER), contrôleur branché sur le joueur, l'interaction (curiosité) et la
## boîte de dialogue ; Boot lui relaie cartes, transitions, scènes, combats et menu.
func _setup_companion() -> void:
	_companions.load_file()
	for error: String in _companions.get_errors():
		push_error("Compagnon : %s" % error)
	_companion.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_companion)
	_companion.setup(GameState, _companions, _pokemon, _player)
	_companion.line_requested.connect(_on_companion_line)
	_interactions.set_companion(_companion)
	_interactions.companion_talked.connect(_companion.talk)
	_battle_director.battle_started.connect(_companion.on_battle_started.unbind(1))
	_menu.set_companions(_companions)
	# Coupe (jalon 16, `jalon-16.md` §2.3) : le compagnon s'il coupe et qu'il est dehors, sinon
	# le Pokémon de l'équipe choisi par FieldMoves, apparu le temps de couper.
	_field_presenter.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_field_presenter)
	_field_presenter.setup(_companion, _player)
	_field_presenter.user_source = _field_move_user
	_cutscenes_node.field_move_handler = _field_presenter.perform


func get_companion_controller() -> CompanionController:
	return _companion


## Mise en scène des capacités de terrain (jalon 16 ; tests, captures).
func get_field_move_presenter() -> FieldMovePresenter:
	return _field_presenter


## Le joueur a parlé au compagnon : sa phrase (narration, jeton « {pokemon} »).
func _on_companion_line(dialogue_id: StringName) -> void:
	_runner.play(dialogue_id, null, SceneRouter.get_current_map())


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


## Voile d'obscurité (J17 T9) : grotte obscure (`caves.json`, « dark ») ou voile forcé par le
## départ de débogage (« veil » : « lit » ouvre le halo). **Flash** (T24) : à une arrivée, le
## voile est posé sombre et [FlashDirector] l'ouvre après sa mise en scène ; le halo n'est ouvert
## dès l'écran noir que hors arrivée ([method FlashRules.is_lit]).
func _apply_darkness(map: GameMap) -> void:
	var forced := not _veil_debug.is_empty() and map.map_id == _veil_debug_map
	var removed := forced and _veil_debug == DebugStart.VEIL_OFF
	var dark := not removed and (forced or _caves.is_dark(map.map_id))
	var lit := (forced and _veil_debug == DebugStart.VEIL_LIT) \
		or FlashRules.is_lit(_arrival_from, map.map_id, _caves, _flash.is_available())
	_darkness.set_map(map, dark, lit)


func get_darkness() -> DarknessController:
	return _darkness


## Arrivée sur une carte (écran visible) : zone découverte, autosave demandé, titre de zone.
## Toute première sortie de la maison (OUV.3) : la légende remplace la région, déduite des
## cartes découvertes **avant** de marquer celle-ci.
func _on_map_entered(map: GameMap) -> void:
	var region := _first_exit.subtitle_for(map.map_id, _arrival_from, GameState.discovered_maps,
		map.region)
	var from := _arrival_from
	_arrival_from = &""
	_active_puzzles.clear()
	GameState.discover_map(map.map_id)
	_companion.on_map_entered(map)
	# Passe systèmes 2 (T15) : arrivée en Surf sur un courant (reprise) → la glissade part ici ;
	# l'autosave d'arrivée attend sa fin (partie pas stable).
	_forced_slide.ride_from_here()
	request_autosave("changement de carte")
	var indoors := map.interior and not _zones.interior_title_of(map.map_id)
	if _announcer.should_announce(map.display_name, indoors):
		_hud.show_zone_title(map.display_name, region)
		zone_announced.emit(map.display_name, region)
	# J17 T24 : Flash (ou l'avertissement) une fois par arrivée, après l'autosave d'arrivée.
	_flash.on_map_entered(map, from)


func _on_target_changed(kind: int) -> void:
	if kind == InteractionController.NO_TARGET:
		_hud.hide_interact()
	else:
		_hud.show_interact(Interaction.kind_name(kind as Interaction.Kind),
			kind == Interaction.Kind.FISH and _can_surf_ahead())


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
	elif _pending_daycare:
		_pending_daycare = false
		_daycare.run()
	elif _pending_elevator:
		_pending_elevator = false
		_elevator.open_panel()


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


# --- Pension (J15, jalon-15.md §2.5.3) ----------------------------------------------------------

## « open_daycare » (le gardien) : la conversation de la Pension commence à la fin du dialogue.
func _on_daycare_requested() -> void:
	_pending_daycare = true


## Dépôt fait : écriture tout de suite (quitter avant l'autosave ne perd rien), comme au soin.
## Le compagnon déposé (choix effacé par le directeur) rentre tout de suite (J11, 11D).
func _on_daycare_deposited() -> void:
	_companion.refresh()
	if _can_write() and not SceneRouter.is_transitioning():
		_write_save("pension, dépôt")
	else:
		request_autosave("pension, dépôt")


## Conversation finie (joueur rendu) : contrôles ; après un retrait, **une seule** écriture.
func _on_daycare_finished(withdrew: bool) -> void:
	_companion.refresh()
	_refresh_controls()
	if not withdrew:
		return
	if _can_write() and not SceneRouter.is_transitioning():
		_write_save("pension, retrait")
	else:
		request_autosave("pension, retrait")


## Soin demandé par un dialogue « heal » (jalon 5 §3.11, Maman) : l'équipe est soignée (PV et
## PP) ; le point de repos ne change pas (dossier 09 §7).
func _on_heal_requested() -> void:
	_services.heal()
	request_autosave("soin")


## Soin d'un Centre fini (jalon-07.md §5.3) : écriture tout de suite (joueur au comptoir, la
## partie ne peut plus rien perdre), comme au réveil ; le toast du point de repos attend la fin
## du dialogue (après « Voilà. Tout le monde est en pleine forme. »), une fois par changement.
func _on_center_healed(map_id: StringName, registered: bool) -> void:
	_companion.note_joy()
	if registered:
		_rest_toast = _rest_points.registered_toast(_zones.zone_name_of(map_id))
	if _can_write() and not SceneRouter.is_transitioning():
		_write_save("soin")
	else:
		request_autosave("soin")


func _on_cutscene_started(cutscene_id: StringName) -> void:
	_companion.on_cutscene_started(_companion_cuts(cutscene_id))
	_refresh_controls()


## Valeurs des jetons des dialogues (jalon-07.md §3.6, T19) : lues au début d'un dialogue qui en
## contient (« Un Roucool… » ; aucune rencontre → la page est omise) ; prénoms du joueur et du
## rival (OUV.2), aussi pour les étiquettes et le nom du dresseur en combat.
func _dialogue_token_values() -> Dictionary[StringName, String]:
	var companion := GameState.get_companion()
	var values := DialogueTokens.values_for(GameState.first_wild_species(), _pokemon,
		GameState.player_name, GameState.rival_name,
		companion.display_name(_pokemon) if companion != null else "")
	# Pension (J15) : {pokemon}, {levels}, {price}, seulement pendant sa conversation ; son
	# {pokemon} (le Pokémon gardé ou rendu) passe alors avant celui du compagnon (J11).
	if _daycare != null:
		values.merge(_daycare.token_values(), true)
	# J17 (§2.5) : {caught}, {caught_missing} (assistant de Chen).
	values.merge(DialogueTokens.caught_values(GameState.pokedex.caught_count()))
	return values


## Une variante de dialogue lance une scène à sa fin (Chen, colis en main → `oak_parcel`). Le
## verrou du joueur passe du dialogue à la scène dans la même image (jalon-07.md §3.6.2).
func _on_cutscene_requested(cutscene_id: StringName) -> void:
	if not _cutscenes_node.play(cutscene_id):
		push_warning("Boot : la scène « %s » demandée par un dialogue n'a pas été jouée"
			% cutscene_id)


## Fin d'une scène : autosave demandé. Si la scène a une suite (clé « next », jalon-13.md
## §2.9), la sauvegarde est écrite **tout de suite** (partie stable), puis la suite est jouée si
## une de ses variantes s'applique (sinon rien). Une seule fois par fin de scène : la suite
## n'enchaîne à son tour que si elle a elle-même « next ». Partie pas stable (réveil après une
## défaite, transition) : pas d'enchaînement, l'autosave ordinaire s'en charge.
func _on_cutscene_finished(cutscene_id: StringName) -> void:
	_companion.on_cutscene_finished()
	_refresh_controls()
	var next := _cutscenes.get_next(cutscene_id)
	if next.is_empty() or not is_stable():
		request_autosave("fin de scène")
		return
	if _can_write():
		_write_save("entre deux scènes")
	_cutscenes_node.play(next)


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
	# SPECTRE (jalon 19, K-9) : un événement masqué n'enregistre rien (ni le 6F scénarisé).
	if GhostDisguise.is_masked(event):
		return
	if event.kind == BattleEvent.Kind.SENT_OUT and event.side == BattleEvent.SideId.FOE \
			and not _encounters.is_running():
		GameState.record_seen(event.species_id, _current_map_id())


## Fin d'un combat de dresseur : grand moment « combat contre le rival » (le rival est le
## dresseur dont l'équipe dépend du starter du joueur, comme dans Rouge/Bleu ; un seul par
## rival, [RivalMoment]), puis autosave
## (écrit à la fin de la scène qui contient le combat). Les sauvages passent par
## [method _on_encounter_finished].
func _on_battle_finished(trainer_id: StringName, outcome: int) -> void:
	# Compagnon : réapparaît (espèce après évolution) ; enthousiasme si victoire de Dresseur.
	_companion.on_battle_finished(not trainer_id.is_empty() and outcome == Battle.Outcome.WIN)
	if trainer_id.is_empty():
		return
	var trainer := _trainers.get_trainer(trainer_id) if _trainers != null else null
	# Un seul moment par rival, à la victoire seulement si la donnée le dit (§2.8).
	if RivalMoment.should_record(trainer, outcome, GameState.moments):
		GameState.record_moment(GameState.MOMENT_RIVAL_BATTLE, _current_map_id(),
			RivalMoment.details(trainer_id, outcome))
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


## Écriture immédiate demandée par l'étape « save » d'une scène (jalon 16, `jalon-16.md` §2.4 :
## le départ du S.S. Anne) : même chemin que le réveil après une défaite. Le joueur est déjà à sa
## place (quai) et les drapeaux sont levés ; la scène attend OK avant le spectacle.
## Écriture refusée pour toute la session (sauvegarde plus récente protégée, ouverture) : rien
## n'est écrit et la scène continue, comme une simulation (sinon elle resterait bloquée pour
## toujours). Pendant une transition : ERR_BUSY, la même étape réessaie à l'image suivante, sans
## message d'échec. Seule une vraie panne d'écriture bloque la scène jusqu'à la réussite.
func _on_cutscene_save_requested(reason: String) -> Error:
	if _simulate_checkpoints or not _can_write():
		if OS.is_debug_build():
			print("[qa] point de sauvegarde sans écriture (%s) : %s"
				% ["simulé" if _simulate_checkpoints else "écriture refusée pour la session", reason])
		return OK
	if SceneRouter.is_transitioning():
		return ERR_BUSY
	return _write_save(reason)


## La scène garde son verrou ; aucune réussite affichée avant l'écriture sur disque.
func _on_checkpoint_save_failed(_reason: String, _error: Error) -> void:
	_hud.show_toast("Sauvegarde impossible", "Nouvelle tentative en cours…")


## Pokémon sauvage capturé et rangé (équipe ou stockage, jalon 5D) : autosave demandé, écrit à
## la première image stable (après la carte de capture et la fin de la rencontre).
func _on_pokemon_caught() -> void:
	_companion.note_joy()
	request_autosave("capture")


## J25 (§2.5) : choix du Pokémon d'un échange fixe (places de l'espèce demandée) ; −1 = renonce.
func _on_trade_pick_requested(_trade_id: StringName, accepted: Array[int]) -> int:
	return await _trade_overlay.pick(TradeOverlay.view_for(GameState.party, accepted, _pokemon))


## J25 (§2.5) : échange fait d'un seul bloc : compagnon à jour (le Pokémon donné a pu l'être,
## choix effacé en silence), autosave demandé (écrit à la fin de la scène).
func _on_pokemon_traded(_given: Pokemon, _received: Pokemon) -> void:
	_companion.refresh()
	request_autosave("échange")


## J20 (§2.5.2, T12) : Pokémon donné (équipe ou Stockage, drapeau levé d'un seul bloc) :
## compagnon à jour, autosave demandé (écrit à la fin de la scène, partie stable).
func _on_pokemon_gifted(_pokemon: Pokemon, _stored: bool) -> void:
	_companion.refresh()
	request_autosave("don")


## Objet trouvé dans le monde (étape « give » marquée « found », la Potion de la Route 1) :
## inscrit au journal des objets trouvés avec la carte (§16.3). Les objets reçus d'un
## personnage (les Poké Balls de Chen) n'y entrent pas.
func _on_item_found(item_id: StringName, _count: int) -> void:
	GameState.record_item_found(item_id, _current_map_id())


## Objet donné par une scène (étape « give ») : toast en haut de l'écran, sans rien bloquer
## (jalon-04.md §14.6). L'accord (« Poké Balls ×5 » / « Ajoutées au Sac ») vient de l'objet.
## Jalon 11 (T12) : le Pokémon [param index] apprend la capacité de la CT [param item_id] par le
## déroulé partagé avec le combat et l'évolution ([MoveLearnPrompt.teach]), sur un voile au-dessus
## du menu ([TmLearnOverlay]) ; la CT reste au Sac.
func _on_tm_learn_requested(index: int, item_id: StringName) -> void:
	var item := _items.get_item(item_id)
	var pokemon: Pokemon = GameState.party.get_at(index)
	if item == null or pokemon == null:
		return
	_learn_overlay().open()
	var prompt := _battle_director.get_move_learn_prompt()
	var learned := await prompt.teach(pokemon, index, item.teaches,
		_tm_overlay.get_message_banner(), _tm_overlay.get_prompt_host())
	prompt.release()
	_tm_overlay.close()
	_menu.finish_tm_learn(index, item_id, learned)


func get_tm_learn_overlay() -> TmLearnOverlay:
	return _tm_overlay


## Le voile d'apprentissage au-dessus du menu (CT, Super Bonbon, Pension), créé au premier
## besoin.
func _learn_overlay() -> TmLearnOverlay:
	if _tm_overlay == null:
		_tm_overlay = TmLearnOverlay.new()
		_tm_overlay.name = "TmLearnOverlay"
		add_child(_tm_overlay)
	return _tm_overlay


func _on_item_given(item_id: StringName, count: int) -> void:
	var item := _items.get_item(item_id)
	if item == null:
		return
	# Un objet « obtenu » (fossile) : son icône peinte du Sac, sinon l'icône générique.
	var icon: Texture2D = MenuArt.item_icon(item_id) if item.obtained else null
	_hud.show_toast(item.quantity_text(count), item.added_text(count), icon)


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


## Un drapeau d'histoire a changé : décor de la carte qui suit les drapeaux (FlagGate,
## jalon 14) ; notes de toutes les espèces ; un toast par espèce concernée, sauf à
## l'activation du Pokédex (tout apparaît d'un coup, sans rafale).
func _on_flag_changed(flag: StringName, _value: bool) -> void:
	var map := SceneRouter.get_current_map()
	if is_instance_valid(map):
		map.apply_flag_gates(GameState.flags)
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
	_hud.set_controls_visible(not _is_opening_active() and not _menu.is_open()
		and not _runner.is_running() and not _cutscenes_node.is_running()
		and not _starter_choice.is_sheet_open() and not _battle_director.is_running()
		and not _encounters.is_running() and not _player.is_blocked_by(EVOLUTION_ITEM)
		and not _player.is_blocked_by(RARE_CANDY)
		and not (_daycare != null and _daycare.is_running())
		and not _player.is_blocked_by(FlashDirector.LOCK_REASON)
		and not _elevator.is_running() and not _forced_slide.is_running())


## Racine de composition : les dépendances sont explicites et câblées une seule fois.
func _wire_settings_applier() -> void:
	_settings_applier.runner = _runner
	_settings_applier.battle_director = _battle_director
	_settings_applier.battle_hud = _battle_hud
	_settings_applier.battle_stage = _battle_stage
	_settings_applier.services = _services
	_settings_applier.companion = _companion
	_settings_applier.field_presenter = _field_presenter
	_settings_applier.hud = _hud
	_settings_applier.cutscenes = _cutscenes_node
	_settings_applier.menu_screen = _menu_screen
	_settings_applier.lighting = _lighting


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
	_profile = _settings_applier.apply(s, device, _evolution_screen, _opening, _title_backdrop)
	# Voile d'obscurité (J17 T9) : battement coupé, ouverture du halo instantanée ; Flash (T24) :
	# saut et sortie de Ball adoucis.
	_darkness.set_reduce_motion(s.reduce_motion)
	_flash.reduce_motion = s.reduce_motion
	if _elevator_panel != null:
		_elevator_panel.reduce_motion = s.reduce_motion
	_elevator.reduce_motion = s.reduce_motion  # J20 (T13) : pas de secousse


## « Sauvegarder maintenant » : écrit la sauvegarde et affiche le résultat dans l'écran.
func _on_save_requested() -> void:
	var text := SettingsViews.SAVE_DISABLED_TEXT
	if _can_write():
		var error := _write_save("menu")
		text = SettingsViews.save_result_text(error, Time.get_datetime_dict_from_system())
	_menu.show_save_result(text)


# --- Jalon 12 (T20) : grottes et Corde Sortie -----------------------------------------------

## Grottes (`data/world/caves.json`) et UTILISER d'un objet AVENTURE sans cible (la Corde
## Sortie) : le Sac la refuse hors grotte, sinon Boot la joue ([method _on_field_item_requested]).
func _setup_caves() -> void:
	if not _caves.load_file(caves_path):
		for error: String in _caves.get_errors():
			push_error("Boot : %s" % error)
	_menu.set_caves(_caves, _current_map_id)
	_menu.field_item_requested.connect(_on_field_item_requested)


func get_caves() -> CaveLibrary:
	return _caves


# --- Jalon 17 (T24) : Flash automatique ------------------------------------------------------

## [FlashDirector] : état de Flash lu dans la partie (CS05 au Sac, compatible, compagnon d'abord),
## action d'arrivée seulement sur une partie stable, hors écran titre.
func _setup_flash() -> void:
	_flash.setup(GameState, _darkness, _caves, _field_moves, _hud, _runner, _library, _player,
		_companion, _companions)
	_flash.check_flash = func() -> FieldMoves.Result:
		return _field_moves.check(FlashDirector.MOVE, GameState.party, GameState.bag,
			GameState.flags, _items, _pokemon, GameState.get_companion())
	_flash.can_start = func() -> bool: return is_stable() and not _is_opening_active()
	_flash.cue_started.connect(_refresh_controls)
	_flash.flash_used.connect(_refresh_controls.unbind(1))


func get_flash_director() -> FlashDirector:
	return _flash


## Corde Sortie acceptée par le Sac (jalon 12, dossier 15 §11, `jalon-12.md` §2.6) : menu fermé,
## « Tu utilises la Corde Sortie. », puis la Corde est retirée **dans la même image** que le
## départ du fondu vers l'entrée de la grotte (comme une porte) — aucune image stable entre les
## deux : l'autosave suivant est celui de l'arrivée (position et Sac ensemble) ; une fermeture
## pendant le fondu laisse la sauvegarde d'avant, Corde comprise. Ni soin ni point de repos.
func _on_field_item_requested(item_id: StringName) -> void:
	var item := _items.get_item(item_id)
	# J17 (§2.3) : la case du joueur choisit la bouche d'une grotte à deux bouches.
	var exit := FieldItemRules.escape_target(_current_map_id(), _caves, _player.get_cell())
	if item == null or exit == null or not GameState.bag.has(item_id):
		return
	_menu.close()
	if _runner.play(ESCAPE_ROPE_DIALOGUE, null, SceneRouter.get_current_map()):
		await _runner.dialogue_finished
	GameState.bag.remove(item_id, 1)
	SceneRouter.change_map(exit.map, exit.spawn, exit.facing)


# --- Passe systèmes 2 (S2B) : monture, Vélo, objets clés utilisables -------------------------

## [MountDirector] (arrivée, Vélo, bouton du HUD) et [KeyItemDirector] (UTILISER d'un objet clé
## dans le Sac : menu fermé, puis l'objet aiguillé par son usage).
func _setup_mount() -> void:
	_mount = MountDirector.new()
	_mount.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_mount)
	_mount.setup(GameState, _player, _runner, _hud)
	_mount.can_toggle = func() -> bool: return is_stable() and not _is_opening_active()
	# S2C (§2.5) : SURFER au bouton contextuel, face à l'eau.
	_mount.surf_state = func() -> FieldMoves.State: return field_state(&"surf").state
	_interactions.terrain_target = _mount.surf_target
	_interactions.surf_requested.connect(_mount.start_surf.unbind(1))
	_key_items = KeyItemDirector.new()
	_key_items.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_key_items)
	_key_items.setup(GameState, _items, _mount, _runner, _cutscenes_node, _companion, _player)
	_menu.key_item_requested.connect(func(item_id: StringName) -> void:
		_menu.close()
		_key_items.use(item_id))


func get_mount_director() -> MountDirector:
	return _mount


func get_key_item_director() -> KeyItemDirector:
	return _key_items


# --- Jalon 12 (T23) : évolution par pierre hors combat ------------------------------------

## Sac → pierre → UTILISER → Pokémon COMPATIBLE ([signal MenuDirector.evolution_item_requested]) ;
## la pierre est retirée à [signal EvolutionDirector.evolution_applied].
func _setup_evolution_items() -> void:
	_menu.evolution_item_requested.connect(_on_evolution_item_requested)
	_menu.rare_candy_requested.connect(_on_rare_candy_requested)
	_evolutions.evolution_applied.connect(_on_evolution_applied)


## Pierre utilisée sur le Pokémon [param index] (`jalon-12.md` §2.9) : menu fermé, joueur et
## contrôles bloqués, [method EvolutionDirector.play_item] (non annulable) ; la pierre quitte le
## Sac **dans l'appel même** où l'évolution est appliquée ([method _on_evolution_applied]). Aucune
## image stable pendant la séquence (le joueur est bloqué) : une fermeture de l'application
## reprend à la sauvegarde d'avant, pierre comprise. Fin : retour au monde, compagnon mis à jour
## (rentre en silence si sa nouvelle espèce n'est pas éligible), autosave.
func _on_evolution_item_requested(index: int, item_id: StringName) -> void:
	var candidate := StoneUse.candidate(GameState.party, index, item_id, _pokemon)
	if candidate == null or not GameState.bag.has(item_id) or _evolutions.is_playing():
		return
	_menu.close()
	_player.set_input_enabled(false, EVOLUTION_ITEM)
	_refresh_controls()
	_stone_item = item_id
	_evolutions.speed_scale = _battle_director.speed_scale
	await _evolutions.play_item(candidate, GameState.party, item_id)
	_stone_item = &""
	if is_instance_valid(_player):
		_player.set_input_enabled(true, EVOLUTION_ITEM)
	_companion.refresh()
	_refresh_controls()
	request_autosave("évolution")


## L'évolution vient d'être appliquée : la pierre en cours quitte le Sac (une seule fois).
func _on_evolution_applied(_party_index: int, _into: StringName) -> void:
	if _stone_item.is_empty():
		return
	if not GameState.bag.remove(_stone_item, 1):
		push_error("Boot : la pierre « %s » n'est plus dans le Sac" % _stone_item)
	_stone_item = &""


# --- Jalon 14 (T18b) : Super Bonbon depuis le Sac ----------------------------------------

## Super Bonbon donné au Pokémon [param index] (`jalon-14.md` §2.6, dossier 17 §5) :
## 1. dans le même appel, le bonbon quitte le Sac et le niveau est gagné ([method RareCandy.apply] :
##    stats et PV recalculés) ; le joueur est bloqué ([constant RARE_CANDY]) : la partie n'est pas
##    stable, rien n'est écrit pendant le déroulé (une fermeture de l'application reprend avant
##    l'usage, bonbon et niveau ensemble) ;
## 2. voile au-dessus du menu ([TmLearnOverlay]) : « {pokemon} monte au niveau {niveau} ! »
##    (n° 62), puis chaque capacité du niveau par [method MoveLearnPrompt.teach] (« apprend », ou
##    l'oubli ; NE PAS APPRENDRE la laisse) ;
## 3. sans évolution due : retour au Sac ([method MenuDirector.finish_rare_candy] : autosave à la
##    fermeture du menu) ; avec une évolution due ([method RareCandy.evolution_after]) : comme la
##    Pierre Lune, menu fermé puis écran d'évolution hors combat, mais **annulable** (évolution par
##    niveau : ARRÊTER, retour Android ; reproposée au prochain niveau gagné), puis retour au monde
##    et autosave.
func _on_rare_candy_requested(index: int, item_id: StringName) -> void:
	var pokemon: Pokemon = GameState.party.get_at(index)
	if pokemon == null or _candy_index >= 0 or _evolutions.is_playing() \
			or not GameState.bag.has(item_id) or RareCandy.check(pokemon) != RareCandy.Check.OK:
		return
	_candy_index = index
	_player.set_input_enabled(false, RARE_CANDY)
	GameState.bag.remove(item_id, 1)
	var level_up := RareCandy.apply(pokemon, _pokemon)
	if level_up == null:
		push_error("Boot : Super Bonbon sans effet sur la place %d" % index)
		GameState.bag.add(item_id, 1)
		_end_rare_candy()
		return
	var overlay := _learn_overlay()
	overlay.open()
	var banner := overlay.get_message_banner()
	await banner.show_message(_rare_candy_line(pokemon, index), true)
	var prompt := _battle_director.get_move_learn_prompt()
	for move_id: StringName in level_up.moves:
		if not is_instance_valid(banner):
			return
		await prompt.teach(pokemon, index, move_id, banner, overlay.get_prompt_host())
	prompt.release()
	if not is_instance_valid(overlay):
		return
	overlay.close()
	_menu.finish_rare_candy(index, item_id)
	var into := RareCandy.evolution_after(pokemon, _pokemon)
	if not into.is_empty() and _pokemon.has_species(into):
		_menu.close()
		var candidate := EvolutionCandidate.new(index, pokemon.species_id, into)
		var list: Array[EvolutionCandidate] = [candidate]
		_evolutions.speed_scale = _battle_director.speed_scale
		await _evolutions.play(list, GameState.party)
		if not is_instance_valid(_player):
			return
		_end_rare_candy()
		_companion.refresh()
		request_autosave("évolution")
		return
	_end_rare_candy()


## « Abra monte au niveau 16 ! » (n° 62, accordé au sexe si la donnée a une variante).
func _rare_candy_line(pokemon: Pokemon, index: int) -> String:
	var event := BattleEvent.new(BattleEvent.Kind.LEVEL_UP, BattleEvent.SideId.PLAYER)
	event.pokemon_name = pokemon.display_name(_pokemon)
	event.gender = pokemon.gender
	event.party_index = index
	event.level = pokemon.level
	event.species_id = pokemon.species_id
	return _texts.line_for(&"rare_candy_level", event, _pokemon)


func _end_rare_candy() -> void:
	_candy_index = -1
	if is_instance_valid(_player):
		_player.set_input_enabled(true, RARE_CANDY)
	_refresh_controls()


## Vrai pendant le déroulé d'un Super Bonbon (tests, QA).
func is_rare_candy_running() -> bool:
	return _candy_index >= 0


# --- Jalon 20 (T13) : ascenseur ----------------------------------------------------------------

## Ascenseurs (`data/world/elevators.json`), directeur, écran du panneau (provisoire jusqu'au
## T14) ; le dialogue du panneau (`open_elevator`) l'ouvre à sa fin, comme la Boutique.
func _setup_elevators() -> void:
	if not _elevators.load_file():
		for error: String in _elevators.get_errors():
			push_error("Boot : %s" % error)
	_elevator.setup(_elevators, GameState, _player, _runner, _fade)
	_elevator.spawn_cell_source = _spawn_cell
	_elevator_panel = ElevatorPanel.new()
	_elevator_panel.name = "ElevatorPanel"
	if _settings != null:
		_elevator_panel.reduce_motion = _settings.reduce_motion
	_elevator_panel.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_elevator_panel)
	_elevator.set_panel(_elevator_panel)
	_elevator.ride_started.connect(_on_elevator_ride_started.unbind(1))
	_elevator.ride_finished.connect(_on_elevator_ride_finished.unbind(1))
	_elevator.panel_opened.connect(_refresh_controls.unbind(1))
	_elevator.panel_closed.connect(_refresh_controls)
	_services.elevator_requested.connect(_on_elevator_requested)


func get_elevator_director() -> ElevatorDirector:
	return _elevator


## « open_elevator » (le panneau de la cabine) : il s'ouvre à la fin du dialogue.
func _on_elevator_requested() -> void:
	_pending_elevator = true


func _on_elevator_ride_started() -> void:
	_companion.on_cutscene_started()
	_refresh_controls()


func _on_elevator_ride_finished() -> void:
	_companion.on_cutscene_finished()
	_refresh_controls()


## Position du joueur poussée dans GameState, jamais la cabine d'un ascenseur (§2.3.5).
func _push_stable_location(map_id: StringName) -> void:
	var at := _elevator.stable_location(map_id, _player.get_cell(), _player.get_facing())
	GameState.set_player_location(at["map"], at["cell"], at["facing"])


## J20 (T19, `jalon-20.md` §2.4.4) et passe systèmes 2 (T15, `systemes-2.md` §2.6) : directeur
## des glissades forcées (dalles tournantes, courants du Surf), branché sur le pas du joueur
## **avant** tout autre écouteur (directeur de scènes, Dresseurs, rencontres, routeur) : le pas
## qui lance une glissade bloque le joueur avant qu'ils ne le voient.
func _setup_forced_slides() -> void:
	_forced_slide = ForcedSlideDirector.new()
	_forced_slide.name = "ForcedSlideDirector"
	_forced_slide.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_forced_slide)
	_forced_slide.setup(_player, _trainer_watcher)
	_forced_slide.slide_started.connect(_on_forced_slide_started.unbind(1))
	_forced_slide.slide_finished.connect(_on_forced_slide_finished.unbind(1))
	_forced_slide.warp_reached.connect(_on_forced_slide_warp_reached)


func get_forced_slide_director() -> ForcedSlideDirector:
	return _forced_slide


## Ancien nom (J20, J28) : même directeur que [method get_forced_slide_director].
func get_spin_director() -> ForcedSlideDirector:
	return _forced_slide


func _on_forced_slide_started() -> void:
	_companion.on_cutscene_started()
	_refresh_controls()


func _on_forced_slide_finished() -> void:
	_companion.on_cutscene_finished()
	_refresh_controls()


## Courant fini sur un passage : suivi comme un pas libre (verrou de la glissade déjà levé).
func _on_forced_slide_warp_reached(cell: Vector2i, direction: Vector2i) -> void:
	if not SceneRouter.follow_warp_at(cell, direction):
		push_error("Boot : aucun passage à suivre en %s au bout du courant" % cell)


# --- Passe systèmes 2, S2A : sauvegarde à la mise en arrière-plan (`systemes-2.md` §2.12) ------

## Point de reprise : instantané capturé au passage stable → instable (dialogue, scène,
## rencontre, combat, transition), remplacé par chaque écriture réussie.
var _checkpoint := SaveCheckpoint.new()
## Horloge du point de reprise, en secondes (délai de garde, écart entre écritures) ; les tests
## la remplacent avant l'entrée dans l'arbre.
var background_clock: Callable
var _was_stable: bool = false
## Position de la dernière image stable ({ map, cell, facing }) : celle du point de reprise (la
## première image instable peut avoir posé le joueur sur une dalle tournante).
var _stable_location: Dictionary = {}
## Vrai pendant une écriture déclenchée par l'arrière-plan ([method SaveCheckpoint.note_written]).
var _background_write: bool = false
## Nouvelle tentative d'écriture du point de reprise après un échec (s restantes, −1 sinon).
var _checkpoint_retry: float = -1.0
## Plus longue capture de la session (µs), pour la mesure sur téléphone (budget < 5 ms).
var _checkpoint_max_usec: int = 0


func _setup_save_checkpoint() -> void:
	if not background_clock.is_valid():
		background_clock = func() -> float: return Time.get_ticks_msec() / 1000.0


func get_save_checkpoint() -> SaveCheckpoint:
	return _checkpoint


## Une fois par image, avant le coordinateur : capture au passage stable → instable, délai de
## garde d'un `FOCUS_OUT`, nouvelle tentative après un échec.
func _watch_save_checkpoint(delta: float) -> void:
	var stable := is_stable()
	if stable:
		_stable_location = {"map": _current_map_id(), "cell": _player.get_cell(),
			"facing": _player.get_facing()}
	elif _was_stable and _can_write():
		_capture_checkpoint()
	_was_stable = stable
	if _checkpoint.focus_due(background_clock.call()):
		_save_in_background("arrière-plan (focus perdu)")
	if _checkpoint_retry >= 0.0:
		_checkpoint_retry = maxf(0.0, _checkpoint_retry - maxf(delta, 0.0))
		if _checkpoint_retry == 0.0:
			_checkpoint_retry = -1.0
			# Redevenue stable, la partie s'écrit par les autosaves ordinaires.
			if not stable:
				_save_in_background("nouvelle tentative")


## Instantané de l'état courant, à la position de la dernière image stable.
func _capture_checkpoint() -> void:
	if _stable_location.is_empty():
		return
	var start := Time.get_ticks_usec()
	var at := _elevator.stable_location(_stable_location["map"], _stable_location["cell"],
		_stable_location["facing"])
	GameState.set_player_location(at["map"], at["cell"], at["facing"])
	_checkpoint.capture(GameState.to_dict())
	var spent := Time.get_ticks_usec() - start
	_checkpoint_max_usec = maxi(_checkpoint_max_usec, spent)
	if OS.is_debug_build():
		print("[save] point de reprise : %d µs (max %d µs)" % [spent, _checkpoint_max_usec])


## Mise en arrière-plan (`PAUSED`, `WM_CLOSE_REQUEST`, `FOCUS_OUT` échu) : état courant si la
## partie est stable, sinon le point de reprise s'il est plus récent que le disque.
func _save_in_background(reason: String) -> void:
	if not _can_write():
		return
	match _checkpoint.decide(is_stable(), background_clock.call()):
		SaveCheckpoint.Decision.WRITE_CURRENT:
			_background_write = true
			_save_coordinator.flush_if_stable(reason)
			_background_write = false
		SaveCheckpoint.Decision.WRITE_CHECKPOINT:
			_write_checkpoint(reason)


func _write_checkpoint(reason: String) -> void:
	var snapshot := _checkpoint.get_snapshot()
	var error := save_system.write(snapshot)
	if error == OK:
		_checkpoint.note_written(snapshot, background_clock.call(), true)
		_checkpoint_retry = -1.0
	else:
		_checkpoint_retry = SaveCoordinator.RETRY_DELAY
	if OS.is_debug_build():
		print("Sauvegarde du point de reprise (%s) : %s %s, %s" % [reason,
			snapshot.get("map", ""), snapshot.get("cell", ""), error_string(error)])


func _on_focus_change(change: SessionLifecycle.Focus) -> void:
	if change != SessionLifecycle.Focus.NONE and OS.is_debug_build():
		print("[save] focus %s à %.2f s" % [SessionLifecycle.Focus.keys()[change],
			background_clock.call()])
	match change:
		SessionLifecycle.Focus.LOST:
			_checkpoint.focus_out(background_clock.call())
		SessionLifecycle.Focus.REGAINED:
			_checkpoint.focus_in()


# --- Passe systèmes 2 (S2F) : téléporteurs et portes à carte -----------------------------------

## Téléporteurs (`systemes-2.md` §2.9) : à la fin d'un replacement sur la même carte, le compagnon
## ressort comme après l'écran « à venir ». Portes à carte (§2.10) : [KeyDoorDirector] répond à
## l'appui OUVRIR. Un seul bloc, déconnecté à la sortie par le directeur lui-même.
var _key_doors: KeyDoorDirector


func _setup_teleporters() -> void:
	_key_doors = KeyDoorDirector.new()
	_key_doors.name = "KeyDoorDirector"
	_key_doors.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_key_doors)
	_key_doors.setup(GameState.flags, GameState.bag, _player, _runner,
		SceneRouter.get_current_map, request_autosave)
	_interactions.door_requested.connect(_key_doors.on_door_requested)
	var on_relocated := func(_map: GameMap) -> void: _on_coming_soon_finished(_map)
	SceneRouter.relocated.connect(on_relocated)
	_key_doors.tree_exiting.connect(func() -> void:
		if SceneRouter.relocated.is_connected(on_relocated):
			SceneRouter.relocated.disconnect(on_relocated))


func get_key_door_director() -> KeyDoorDirector:
	return _key_doors


# --- Passe systèmes 2 (S2E) : Vol -------------------------------------------------------------

var _fly: FlyDirector


## Vol (`systemes-2.md` §2.8, T24–T25) : destinations de `fly_points.json`, bouton « S'ENVOLER »
## de la Carte (Q-4), menu fermé puis [FlyDirector].
func _setup_fly() -> void:
	var rules := FlyRules.new()
	rules.load_file()
	_fly = FlyDirector.new()
	_fly.name = "FlyDirector"
	_fly.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_fly)
	_fly.setup(rules, func() -> Dictionary: return GameState.discovered_maps,
		func(move: StringName) -> Variant: return _runner.field_source.call(move), _caves, SceneRouter.get_current_map, _player, _runner, SceneRouter,
		_companion)
	_menu.set_fly_check(_fly.can_fly_to)
	_menu.fly_requested.connect(func(zone: StringName) -> void:
		_menu.close()
		_fly.fly(zone))
	if _menu_screen.has_signal(&"map_fly_requested"):
		_menu_screen.map_fly_requested.connect(_menu.request_fly)
	_fly.flight_started.connect(_refresh_controls.unbind(1))
	_fly.flight_finished.connect(_refresh_controls.unbind(1))


func get_fly_director() -> FlyDirector:
	return _fly


# --- Passe systèmes 2 (S2E, T25b) : Téléport et Tunnel hors combat ----------------------------

var _field_travel: FieldTravelDirector


## Téléport (au point du réveil, sans soin) et Tunnel (sortie de grotte, comme la Corde Sortie) :
## UTILISER sous la fiche de la capacité dans l'Équipe, menu fermé puis [FieldTravelDirector].
func _setup_field_travel() -> void:
	_field_travel = FieldTravelDirector.new()
	_field_travel.name = "FieldTravelDirector"
	_field_travel.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_field_travel)
	_field_travel.setup(field_state, _recovery.wakeup_point, _caves, SceneRouter.get_current_map,
		_player, _runner, SceneRouter, _companion)
	_menu.set_field_travel_check(_field_travel.check)
	_menu.field_travel_requested.connect(func(move: StringName) -> void:
		_menu.close()
		_field_travel.travel(move))
	if _menu_screen.has_signal(&"team_field_move_requested"):
		_menu_screen.team_field_move_requested.connect(_menu.request_field_travel)
		_menu.team_notice_shown.connect(_menu_screen.show_team_notice)
	_field_travel.travel_started.connect(_refresh_controls.unbind(1))
	_field_travel.travel_finished.connect(_refresh_controls.unbind(1))


func get_field_travel_director() -> FieldTravelDirector:
	return _field_travel


# --- Passe systèmes 2 (S2C-bis) : pêche --------------------------------------------------------

## Choix « Pêcher / Surfer » par appui long (option A de Kevin) : OUI = PÊCHER, NON = SURFER.
const WATER_CHOICE_DIALOGUE: StringName = &"water_choice"
enum WaterChoice { NONE, FISH, SURF }

var _fishing: FishingDirector
var _water_choice: WaterChoice = WaterChoice.NONE


## Pêche (J22 §2.7) : cible de terrain PÊCHER, appui, cannes du Sac ([KeyItemDirector]). Tables
## chargées sans contrôle des espèces (celles du J22 manquent) : le directeur refuse une espèce
## inconnue au moment de la touche. Après [method _setup_mount] (objets clés).
## Vrai si SURFER est possible devant le joueur (même s'il voit PÊCHER).
func _can_surf_ahead() -> bool:
	var target := _mount.surf_target(_player.get_cell(), _player.get_facing())
	return target != null and target.kind == Interaction.Kind.SURF


## Appui long sur PÊCHER (mode choix) : « Pêcher / Surfer ».
func _on_water_choice_requested() -> void:
	if _runner.is_running() or _fishing.is_running() or not _player.is_input_enabled() \
			or _player.is_moving() or not _can_surf_ahead():
		return
	_water_choice = WaterChoice.NONE
	_runner.play(WATER_CHOICE_DIALOGUE)


func _on_water_choice_finished(dialogue_id: StringName) -> void:
	if dialogue_id != WATER_CHOICE_DIALOGUE:
		return
	var choice := _water_choice
	_water_choice = WaterChoice.NONE
	if choice == WaterChoice.FISH:
		_fishing.on_fish_requested(_player.get_cell() + _player.get_facing())
	elif choice == WaterChoice.SURF:
		_mount.start_surf()


func _setup_fishing() -> void:
	var tables := WaterRodTables.new()
	tables.load_game_files()
	_fishing = FishingDirector.new()
	_fishing.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_fishing)
	_fishing.setup(GameState, tables, _pokemon, _player, _runner, _encounters, _companion)
	SceneRouter.map_changed.connect(_fishing.set_map)
	_fishing.tree_exiting.connect(func() -> void:
		if SceneRouter.map_changed.is_connected(_fishing.set_map):
			SceneRouter.map_changed.disconnect(_fishing.set_map))
	# Cible de terrain : la pêche d'abord (case pêchable et canne au Sac, [D]), sinon le Surf.
	_interactions.terrain_target = func(c: Vector2i, f: Vector2i) -> Interaction:
		var target := _fishing.target_at(c, f)
		return target if target != null else _mount.surf_target(c, f)
	_interactions.fish_requested.connect(_fishing.on_fish_requested)
	# Option A de Kevin (2026-10-21) : PÊCHER face à une eau où l'on peut aussi surfer ; un appui
	# long ouvre le choix « Pêcher / Surfer », joué au premier plan puis lancé à sa fermeture.
	_hud.interact_long_pressed.connect(_on_water_choice_requested)
	_runner.choice_made.connect(func(confirmed: bool) -> void:
		if _runner.get_dialogue_id() == WATER_CHOICE_DIALOGUE:
			_water_choice = WaterChoice.FISH if confirmed else WaterChoice.SURF)
	_runner.dialogue_finished.connect(_on_water_choice_finished)
	_key_items.set_fishing(_fishing)
	_fishing.fishing_started.connect(_refresh_controls.unbind(1))
	_fishing.fishing_finished.connect(_refresh_controls.unbind(1))


func get_fishing_director() -> FishingDirector:
	return _fishing


# --- Passe systèmes 2, S2D : Force (`systemes-2.md` §2.7) -----------------------------------

var _strength: StrengthDirector


## [StrengthDirector] : rochers de la carte (nœud `Boulders`), activation par EXAMINER, poussée,
## sauvegarde forcée par le chemin de l'étape « save » des scènes ; Force retombe à chaque carte.
## Le compagnon reste dehors pendant l'activation s'il est le Pokémon qui utilise Force. Les
## contrôles restent affichés pendant une poussée (le joystick tenu enchaîne les poussées).
func _setup_strength() -> void:
	_strength = StrengthDirector.new()
	_strength.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_strength)
	_strength.setup(GameState.flags, _player, _runner, _field_presenter)
	_strength.save_handler = _on_cutscene_save_requested
	SceneRouter.map_changed.connect(_strength.on_map_changed)
	_strength.tree_exiting.connect(func() -> void:
		if SceneRouter.map_changed.is_connected(_strength.on_map_changed):
			SceneRouter.map_changed.disconnect(_strength.on_map_changed))
	_strength.activation_started.connect(func() -> void:
		var chosen := _companion.get_chosen()
		_companion.on_cutscene_started(chosen != null
			and _field_move_user(StrengthDirector.MOVE) == chosen))
	_strength.activation_finished.connect(_companion.on_cutscene_finished)


func get_strength_director() -> StrengthDirector:
	return _strength
