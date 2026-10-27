extends GutTest
## GameSettings (jalon-06.md §3.8) : défauts, bornes, crans, aller-retour JSON, champs inconnus
## ignorés, valeurs mal formées sans échec ; vitesses du texte et réduction des animations.

const FIXTURE := "res://tests/fixtures/settings/v1_mixed.json"


func test_defaults() -> void:
	var settings := GameSettings.new()
	assert_eq(settings.text_speed, GameSettings.TextSpeed.NORMAL)
	assert_false(settings.confirm_actions, "Q-18 : désactivé par défaut")
	assert_eq(settings.joystick_scale, 1.0)
	assert_eq(settings.joystick_opacity, 1.0)
	assert_eq(settings.button_scale, 1.0)
	assert_true(settings.haptics)
	assert_false(settings.left_handed)
	assert_eq(settings.text_size, GameSettings.TextSize.NORMAL)
	assert_false(settings.high_contrast)
	assert_false(settings.reduce_motion)
	assert_false(settings.reduce_flashes)
	assert_eq(settings.graphics, GameSettings.Graphics.AUTO, "Q-17 : Auto par défaut")
	assert_almost_eq(settings.music_volume, 0.7, 0.0001, "SON-7 : Musique 70 %")
	assert_almost_eq(settings.sfx_volume, 0.8, 0.0001, "SON-7 : Effets 80 %")
	assert_almost_eq(settings.cry_volume, 0.8, 0.0001, "SON-7 : Cris 80 %")


func test_no_autosave_setting_and_three_volumes() -> void:
	var volumes: Array[StringName] = []
	for key: StringName in GameSettings.KEYS:
		assert_false(String(key).contains("autosave"), "sauvegarde automatique permanente")
		if String(key).contains("volume"):
			volumes.append(key)
	assert_eq(volumes, [GameSettings.MUSIC_VOLUME, GameSettings.SFX_VOLUME,
		GameSettings.CRY_VOLUME] as Array[StringName], "SON-7 : Musique, Effets, Cris")


func test_every_key_is_a_field() -> void:
	var settings := GameSettings.new()
	for key: StringName in GameSettings.KEYS:
		assert_not_null(settings.get_value(key), String(key))
	assert_null(settings.get_value(&"autosave"))


func test_round_trip() -> void:
	var settings := GameSettings.new()
	settings.text_speed = GameSettings.TextSpeed.INSTANT
	settings.confirm_actions = true
	settings.joystick_scale = 0.8
	settings.joystick_opacity = 0.3
	settings.button_scale = 1.2
	settings.haptics = false
	settings.left_handed = true
	settings.text_size = GameSettings.TextSize.LARGE
	settings.high_contrast = true
	settings.reduce_motion = true
	settings.reduce_flashes = true
	settings.graphics = GameSettings.Graphics.ECO
	var json := JSON.stringify(settings.to_dict())
	var back := GameSettings.from_dict(JSON.parse_string(json))
	assert_true(back.equals(settings), json)
	assert_eq(back.to_dict(), settings.to_dict())


func test_enums_written_by_name() -> void:
	var settings := GameSettings.new()
	settings.graphics = GameSettings.Graphics.HIGH
	var dict := settings.to_dict()
	assert_eq(dict["text_speed"], "normal")
	assert_eq(dict["text_size"], "normal")
	assert_eq(dict["graphics"], "high")


func test_empty_dict_gives_defaults() -> void:
	assert_true(GameSettings.from_dict({}).equals(GameSettings.new()))


func test_fixture_unknown_fields_ignored_malformed_to_default() -> void:
	var text := FileAccess.get_file_as_string(FIXTURE)
	var settings := GameSettings.from_dict(JSON.parse_string(text))
	assert_eq(settings.text_speed, GameSettings.TextSpeed.FAST)
	assert_true(settings.confirm_actions)
	assert_eq(settings.joystick_scale, 1.2)
	assert_almost_eq(settings.joystick_opacity, 0.7, 0.0001)
	assert_eq(settings.button_scale, 1.2)
	assert_false(settings.haptics)
	assert_true(settings.left_handed)
	assert_eq(settings.text_size, GameSettings.TextSize.LARGE)
	assert_false(settings.high_contrast, "« oui » n'est pas un booléen : défaut")
	assert_true(settings.reduce_motion)
	assert_false(settings.reduce_flashes, "1 n'est pas un booléen : défaut")
	assert_eq(settings.graphics, GameSettings.Graphics.ECO)
	assert_false(settings.to_dict().has("autosave"), "champ inconnu non recopié")
	assert_almost_eq(settings.music_volume, 0.5, 0.0001, "jalon Son : champ désormais connu")
	assert_false(settings.to_dict().has("autosave"))


func test_out_of_bounds_and_malformed_values_fall_back() -> void:
	var settings := GameSettings.from_dict({
		"text_speed": "turbo",
		"confirm_actions": null,
		"joystick_scale": 1.3,
		"joystick_opacity": 0.2,
		"button_scale": 1.1,
		"haptics": "false",
		"text_size": 1,
		"graphics": ["eco"],
		"left_handed": {},
	})
	assert_true(settings.equals(GameSettings.new()), JSON.stringify(settings.to_dict()))


func test_opacity_steps() -> void:
	var settings := GameSettings.new()
	assert_true(settings.set_value(GameSettings.JOYSTICK_OPACITY, 0.3))
	assert_almost_eq(settings.joystick_opacity, 0.3, 0.0001)
	assert_true(settings.set_value(GameSettings.JOYSTICK_OPACITY, 0.8))
	assert_false(settings.set_value(GameSettings.JOYSTICK_OPACITY, 0.75), "entre deux crans")
	assert_false(settings.set_value(GameSettings.JOYSTICK_OPACITY, 1.1), "au-dessus de 100 %")
	assert_false(settings.set_value(GameSettings.JOYSTICK_OPACITY, 0.29), "sous 30 %")
	assert_almost_eq(settings.joystick_opacity, 0.8, 0.0001)
	assert_true(settings.set_value(GameSettings.JOYSTICK_OPACITY, 1), "un entier compte")
	assert_eq(settings.joystick_opacity, 1.0)


func test_float_noise_snaps_to_step() -> void:
	var settings := GameSettings.new()
	assert_true(settings.set_value(GameSettings.JOYSTICK_OPACITY, 0.1 * 7.0))
	assert_eq(settings.to_dict()["joystick_opacity"], 0.7)
	assert_true(settings.set_value(GameSettings.JOYSTICK_SCALE, 0.8000001))
	assert_eq(settings.joystick_scale, 0.8)


func test_set_value_reports_change_only() -> void:
	var settings := GameSettings.new()
	assert_false(settings.set_value(GameSettings.HAPTICS, true), "déjà vrai")
	assert_true(settings.set_value(GameSettings.HAPTICS, false))
	assert_false(settings.haptics)
	assert_false(settings.set_value(GameSettings.HAPTICS, 0), "pas un booléen")
	assert_false(settings.set_value(&"autosave", false), "clé inconnue")
	assert_true(settings.set_value(GameSettings.TEXT_SPEED, GameSettings.TextSpeed.SLOW))
	assert_false(settings.set_value(GameSettings.TEXT_SPEED, 4), "hors de l'enum")
	assert_false(settings.set_value(GameSettings.TEXT_SPEED, -1))
	assert_true(settings.set_value(GameSettings.GRAPHICS, 2.0), "entier venu du JSON")
	assert_eq(settings.graphics, GameSettings.Graphics.ECO)
	assert_false(settings.set_value(GameSettings.BUTTON_SCALE, 1.1))
	assert_true(settings.set_value(GameSettings.BUTTON_SCALE, 1.2))


func test_chars_per_second() -> void:
	var settings := GameSettings.new()
	var expected: Array[float] = [25.0, UiTokens.DIALOG_CHARS_PER_SECOND, 90.0, 0.0]
	for speed: int in 4:
		settings.text_speed = speed as GameSettings.TextSpeed
		assert_eq(settings.chars_per_second(), expected[speed])
	assert_eq(UiTokens.DIALOG_CHARS_PER_SECOND, 45.0, "Normale = la vitesse d'avant le J6")


func test_reduce_motion_scales() -> void:
	var settings := GameSettings.new()
	assert_eq(settings.battle_speed_scale(), 1.0)
	assert_eq(settings.menu_speed_scale(), 1.0)
	settings.reduce_motion = true
	assert_eq(settings.battle_speed_scale(), 0.6)
	assert_eq(settings.menu_speed_scale(), 0.5)


func test_duplicate_is_independent() -> void:
	var settings := GameSettings.new()
	var copy := settings.duplicate()
	copy.haptics = false
	assert_true(settings.haptics)
	assert_false(settings.equals(copy))


# --- Économie (moteur commun) ---------------------------------------------------------------

func test_economy_off_by_default() -> void:
	assert_false(GameSettings.new().economy, "désactivé : rendu inchangé")
	assert_false(GameSettings.new().to_dict()[String(GameSettings.ECONOMY)])


func test_economy_toggle_and_round_trip() -> void:
	var settings := GameSettings.new()
	assert_true(settings.set_value(GameSettings.ECONOMY, true))
	assert_false(settings.set_value(GameSettings.ECONOMY, true), "déjà activé")
	assert_false(settings.set_value(GameSettings.ECONOMY, 1), "booléen seulement")
	assert_true(GameSettings.from_dict(JSON.parse_string(JSON.stringify(settings.to_dict()))).economy)
	assert_true(settings.set_value(GameSettings.ECONOMY, false))


func test_old_settings_file_without_the_economy_key_reads_as_off() -> void:
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	assert_false(old.has("economy"), "ancien fichier : pas de clé")
	var settings := GameSettings.from_dict(old)
	assert_false(settings.economy)
	assert_true(settings.reduce_motion, "le reste est lu normalement")
	assert_false(GameSettings.from_dict({"economy": "oui"}).economy, "mal formé : défaut")


func test_volume_steps_and_bounds() -> void:
	var settings := GameSettings.new()
	for key: StringName in [GameSettings.MUSIC_VOLUME, GameSettings.SFX_VOLUME,
			GameSettings.CRY_VOLUME]:
		assert_true(GameSettings.is_valid(key, 0.0), "0 : coupé")
		assert_true(GameSettings.is_valid(key, 1), "100 % (entier)")
		assert_true(GameSettings.is_valid(key, 0.3))
		assert_false(GameSettings.is_valid(key, 0.35), "entre deux crans")
		assert_false(GameSettings.is_valid(key, 1.1), "hors bornes")
		assert_false(GameSettings.is_valid(key, -0.1), "hors bornes")
		assert_false(GameSettings.is_valid(key, "0.5"), "texte")
		assert_true(settings.set_value(key, 0.30000000000000004))
		assert_eq(settings.get_value(key), 0.3, "cran exact")
		assert_false(settings.set_value(key, 2.0), "refusée : rien ne change")
		assert_eq(settings.get_value(key), 0.3)


func test_out_of_bounds_volumes_in_a_file_fall_back_to_defaults() -> void:
	var settings := GameSettings.from_dict({ "music_volume": 1.5, "sfx_volume": "fort",
		"cry_volume": 0.0 })
	assert_almost_eq(settings.music_volume, GameSettings.DEFAULT_MUSIC_VOLUME, 0.0001)
	assert_almost_eq(settings.sfx_volume, GameSettings.DEFAULT_SFX_VOLUME, 0.0001)
	assert_eq(settings.cry_volume, 0.0, "0 est permis : coupé")


func test_old_settings_file_without_volumes_reads_defaults() -> void:
	# Écrit par le jeu d'avant le jalon Son : même version (1), pas de clés de volume.
	var old: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/settings/v1_before_sound.json"))
	assert_false(old.has("music_volume"), "ancien fichier : pas de clé")
	var settings := GameSettings.from_dict(old)
	assert_true(settings.equals(_with_old_values()), "volumes aux défauts, le reste relu")
	assert_almost_eq(settings.music_volume, 0.7, 0.0001)
	var written := settings.to_dict()
	assert_almost_eq(float(written["sfx_volume"]), 0.8, 0.0001, "réécrit avec les volumes")


func _with_old_values() -> GameSettings:
	var settings := GameSettings.new()
	settings.joystick_opacity = 0.8
	settings.economy = true
	return settings


# --- Combat vivant (CV-4, T5) -------------------------------------------------------------

func test_battle_animations_full_by_default() -> void:
	assert_eq(GameSettings.new().battle_animations, GameSettings.BattleAnimations.FULL)
	assert_eq(GameSettings.new().to_dict()["battle_animations"], "full")


func test_battle_animations_round_trip_by_name() -> void:
	var settings := GameSettings.new()
	assert_true(settings.set_value(GameSettings.BATTLE_ANIMATIONS,
		GameSettings.BattleAnimations.FAST))
	assert_false(settings.set_value(GameSettings.BATTLE_ANIMATIONS, 2), "hors bornes")
	assert_false(settings.set_value(GameSettings.BATTLE_ANIMATIONS, "fast"), "pas un entier")
	var dict := settings.to_dict()
	assert_eq(dict["battle_animations"], "fast")
	var back := GameSettings.from_dict(JSON.parse_string(JSON.stringify(dict)))
	assert_eq(back.battle_animations, GameSettings.BattleAnimations.FAST)


func test_old_settings_file_without_battle_animations_reads_full() -> void:
	var old := GameSettings.new().to_dict()
	old.erase("battle_animations")
	assert_eq(GameSettings.from_dict(old).battle_animations, GameSettings.BattleAnimations.FULL)
	assert_eq(GameSettings.from_dict({"battle_animations": "turbo"}).battle_animations,
		GameSettings.BattleAnimations.FULL, "nom inconnu : défaut")


func test_battle_animations_independent_of_reduce_motion() -> void:
	var settings := GameSettings.new()
	settings.set_value(GameSettings.BATTLE_ANIMATIONS, GameSettings.BattleAnimations.FAST)
	assert_false(settings.reduce_motion, "CV-5 : deux réglages distincts")
	assert_eq(settings.battle_speed_scale(), 1.0)
