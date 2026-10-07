class_name SettingsViews
extends RefCounted
## Construit la vue de l'écran Paramètres à partir des réglages (dossier 08 §7 ; jalon-06.md
## §3.8, §6.12). Pur : ni nœud, ni fichier.
##
## Catégories dans l'ordre du dossier 08 §7, sans AUDIO (Q-17) : JEU, COMMANDES,
## ACCESSIBILITÉ, GRAPHISMES. Textes d'interface validés par Kevin le 2026-10-06.

const CATEGORY_GAME: StringName = &"game"
const CATEGORY_CONTROLS: StringName = &"controls"
const CATEGORY_ACCESSIBILITY: StringName = &"accessibility"
const CATEGORY_GRAPHICS: StringName = &"graphics"
## Clé de l'action « Sauvegarder maintenant » (pas un réglage : émet `save_now_requested`).
const SAVE_NOW: StringName = &"save_now"

const ON_TEXT: String = "Activé"
const OFF_TEXT: String = "Désactivé"
const SAVE_DONE_TEXT: String = "Partie sauvegardée"
const SAVE_FAILED_TEXT: String = "La sauvegarde n'a pas pu être écrite."
const SAVE_DISABLED_TEXT: String = "Sauvegarde désactivée pour cette session."
const SAVE_DETAIL_TEXT: String = "La partie se sauvegarde aussi toute seule."
## Sous-titres des sections (MM.3, repris de la maquette ; à relire par Kevin).
const SUBTITLE_GAME: String = "Paramètres principaux du jeu."
const SUBTITLE_CONTROLS: String = "Personnalise tes contrôles."
const SUBTITLE_ACCESSIBILITY: String = "Rends le jeu accessible à tous."
const SUBTITLE_GRAPHICS: String = "Ajuste la qualité visuelle du jeu."


## Vue de l'écran. [param device_quality] : ce que donne Auto sur cet appareil
## ([method GraphicsProfile.auto_quality]), écrit « Auto (Élevée) ». [param can_save] : faux
## dans une session sans écriture (départ de débogage, sauvegarde d'une version plus récente) ;
## « Sauvegarder maintenant » est alors visible mais inactif, avec la raison.
static func build(settings: GameSettings, device_quality: GameSettings.Graphics,
		can_save: bool) -> SettingsView:
	var view := SettingsView.new()
	var game := SettingsCategoryView.new(CATEGORY_GAME, "JEU", SUBTITLE_GAME)
	game.controls.append(_choice(GameSettings.TEXT_SPEED, "Vitesse du texte",
		"Dans les dialogues.", settings.text_speed,
		[["Lente", GameSettings.TextSpeed.SLOW], ["Normale", GameSettings.TextSpeed.NORMAL],
		["Rapide", GameSettings.TextSpeed.FAST], ["Instantanée", GameSettings.TextSpeed.INSTANT]]))
	game.controls.append(_toggle(GameSettings.CONFIRM_ACTIONS, "Confirmer certaines actions",
		"Avant d'oublier une capacité.", settings.confirm_actions))
	var save := SettingControlView.new()
	save.key = SAVE_NOW
	save.kind = SettingControlView.Kind.ACTION
	save.label = "Sauvegarder maintenant"
	save.enabled = can_save
	save.detail = SAVE_DETAIL_TEXT if can_save else SAVE_DISABLED_TEXT
	game.controls.append(save)
	view.categories.append(game)

	var controls := SettingsCategoryView.new(CATEGORY_CONTROLS, "COMMANDES",
		SUBTITLE_CONTROLS)
	controls.controls.append(_choice(GameSettings.JOYSTICK_SCALE, "Taille du joystick", "",
		settings.joystick_scale, [["Petite", GameSettings.JOYSTICK_SCALES[0]],
		["Normale", GameSettings.JOYSTICK_SCALES[1]], ["Grande", GameSettings.JOYSTICK_SCALES[2]]]))
	var opacity := SettingControlView.new()
	opacity.key = GameSettings.JOYSTICK_OPACITY
	opacity.kind = SettingControlView.Kind.SLIDER
	opacity.label = "Opacité du joystick"
	opacity.value = settings.joystick_opacity
	opacity.value_text = percent_text(settings.joystick_opacity)
	opacity.min_value = GameSettings.JOYSTICK_OPACITY_MIN
	opacity.max_value = GameSettings.JOYSTICK_OPACITY_MAX
	opacity.step = GameSettings.JOYSTICK_OPACITY_STEP
	controls.controls.append(opacity)
	controls.controls.append(_choice(GameSettings.BUTTON_SCALE, "Taille des boutons", "",
		settings.button_scale, [["Normale", GameSettings.BUTTON_SCALES[0]],
		["Grande", GameSettings.BUTTON_SCALES[1]]]))
	controls.controls.append(_toggle(GameSettings.HAPTICS, "Vibrations", "", settings.haptics))
	controls.controls.append(_toggle(GameSettings.LEFT_HANDED, "Mode gaucher",
		"Joystick à droite, boutons à gauche.", settings.left_handed))
	view.categories.append(controls)

	var access := SettingsCategoryView.new(CATEGORY_ACCESSIBILITY, "ACCESSIBILITÉ",
		SUBTITLE_ACCESSIBILITY)
	access.controls.append(_choice(GameSettings.TEXT_SIZE, "Taille du texte", "",
		settings.text_size, [["Normale", GameSettings.TextSize.NORMAL],
		["Grande", GameSettings.TextSize.LARGE]]))
	access.controls.append(_toggle(GameSettings.HIGH_CONTRAST, "Contraste renforcé", "",
		settings.high_contrast))
	access.controls.append(_toggle(GameSettings.REDUCE_MOTION, "Réduire les animations",
		"Transitions et animations de combat plus courtes.", settings.reduce_motion))
	access.controls.append(_toggle(GameSettings.REDUCE_FLASHES, "Réduire les flashs",
		"Coups et captures sans éclair vif.", settings.reduce_flashes))
	view.categories.append(access)

	var graphics := SettingsCategoryView.new(CATEGORY_GRAPHICS, "GRAPHISMES",
		SUBTITLE_GRAPHICS)
	var quality := _choice(GameSettings.GRAPHICS, "Qualité",
		"Économie : 30 images par seconde, pour la batterie.", settings.graphics,
		[["Auto", GameSettings.Graphics.AUTO], ["Élevée", GameSettings.Graphics.HIGH],
		["Économie", GameSettings.Graphics.ECO]])
	if settings.graphics == GameSettings.Graphics.AUTO:
		quality.value_text = "Auto (%s)" % quality_name(device_quality)
	graphics.controls.append(quality)
	view.categories.append(graphics)
	return view


## « Élevée » ou « Économie » (AUTO → « Auto »).
static func quality_name(quality: GameSettings.Graphics) -> String:
	match quality:
		GameSettings.Graphics.HIGH:
			return "Élevée"
		GameSettings.Graphics.ECO:
			return "Économie"
	return "Auto"


## « 70 % » (espace insécable avant %).
static func percent_text(value: float) -> String:
	return "%d %%" % roundi(value * 100.0)


## Texte du résultat de « Sauvegarder maintenant » (`SettingsScreen.show_save_result`) :
## « Partie sauvegardée — 14 h 32 » ; un échec dit seulement qu'il a échoué. [param time] :
## `Time.get_datetime_dict_from_system()` (au moins « hour » et « minute »).
static func save_result_text(error: Error, time: Dictionary) -> String:
	if error != OK:
		return SAVE_FAILED_TEXT
	var hour := JsonFields.get_int(time, "hour", -1)
	var minute := JsonFields.get_int(time, "minute", -1)
	if hour < 0 or minute < 0:
		return SAVE_DONE_TEXT
	return "%s — %d h %02d" % [SAVE_DONE_TEXT, hour, minute]


static func _toggle(key: StringName, label: String, detail: String,
		value: bool) -> SettingControlView:
	var item := SettingControlView.new()
	item.key = key
	item.kind = SettingControlView.Kind.TOGGLE
	item.label = label
	item.detail = detail
	item.value = value
	item.value_text = ON_TEXT if value else OFF_TEXT
	return item


## [param pairs] : [[libellé, valeur], …] dans l'ordre d'affichage.
static func _choice(key: StringName, label: String, detail: String, value: Variant,
		pairs: Array) -> SettingControlView:
	var item := SettingControlView.new()
	item.key = key
	item.kind = SettingControlView.Kind.CHOICE
	item.label = label
	item.detail = detail
	item.value = value
	for pair: Array in pairs:
		item.options.append(SettingOptionView.new(pair[0], pair[1]))
	var selected := item.selected_option()
	item.value_text = item.options[selected].label if selected >= 0 else ""
	return item
