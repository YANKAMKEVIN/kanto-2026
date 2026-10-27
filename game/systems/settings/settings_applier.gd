class_name SettingsApplier
extends RefCounted
## Applique les réglages aux composants injectés, sans lire de fichier ni connaître Boot.
## Les écrans créés après le démarrage sont passés à chaque application.

var runner: DialogueRunner
var battle_director: BattleDirector
var battle_hud: BattleHud
var battle_stage: BattleStage
var services: ServiceDirector
var companion: CompanionController
var field_presenter: FieldMovePresenter
var hud: ExplorationHud
var cutscenes: CutsceneDirector
var menu_screen: TrainerMenu
var lighting: WorldLighting
## Jalon Son (T6) : autoload « Audio » (volumes des bus) ; null = rien (tests).
var audio: Node


func apply(s: GameSettings, device: Dictionary, evolution_screen: EvolutionScreen = null,
		opening: OpeningDirector = null, title_backdrop: TitleBackdrop = null) -> GraphicsProfile:
	runner.chars_per_second = s.chars_per_second()
	battle_director.speed_scale = s.battle_speed_scale()
	battle_director.confirm_forget = s.confirm_actions
	battle_hud.message_hold_scale = 1.0
	battle_stage.reduce_flashes = s.reduce_flashes
	battle_stage.reduce_motion = s.reduce_motion
	battle_stage.battle_animations = s.battle_animations
	if evolution_screen != null:
		evolution_screen.reduce_flashes = s.reduce_flashes
	services.reduce_motion = s.reduce_motion
	companion.set_reduce_motion(s.reduce_motion)
	field_presenter.reduce_motion = s.reduce_motion
	# Halos des grottes (jalon 12, T7 / T20) et lueur « hint » chez Léo (jalon 14) : vacillement
	# coupé.
	LightGlow.set_reduce_motion(s.reduce_motion)
	# Brume de la Tour Pokémon (jalon 19, T19) : cachée.
	MistLayer.set_reduce_motion(s.reduce_motion)
	# Carte du Champion (jalon 10, T5) : sans glissé, un fondu court.
	hud.get_champion_card().reduce_motion = s.reduce_motion
	cutscenes.reduce_motion = s.reduce_motion
	# Étape « flash » (jalon 14) : adoucie par l'un ou l'autre réglage.
	hud.set_flash_reduced(s.reduce_motion or s.reduce_flashes)
	menu_screen.speed_scale = s.menu_speed_scale()
	Haptics.enabled = s.haptics
	if audio != null:
		audio.call(&"apply_settings", s)
	UiPrefs.apply(s)
	if hud.has_method(&"set_left_handed"):
		hud.call(&"set_left_handed", s.left_handed)
	if hud.has_method(&"set_joystick_style"):
		hud.call(&"set_joystick_style", s.joystick_scale, s.joystick_opacity)
	if hud.has_method(&"set_button_scale"):
		hud.call(&"set_button_scale", s.button_scale)
	var profile := GraphicsProfile.resolve(s.graphics, device)
	Engine.max_fps = profile.max_fps
	if menu_screen.has_method(&"set_backdrop_blur"):
		menu_screen.call(&"set_backdrop_blur", profile.menu_blur)
	battle_stage.backdrop_blur = not profile.reduced_effects
	lighting.set_reduced_effects(profile.reduced_effects)
	lighting.set_economy(s.economy)
	# Écran titre (OUV.1) : main du joueur, flou des Paramètres, dérive du décor.
	if opening != null:
		opening.apply_settings(s, profile.menu_blur)
	if title_backdrop != null:
		title_backdrop.set_reduce_motion(s.reduce_motion)

	return profile
