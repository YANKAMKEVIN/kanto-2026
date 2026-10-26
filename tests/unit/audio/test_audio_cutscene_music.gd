extends GutTest
## Clé facultative « music » des étapes de cinématique (SonA, T6) : sans nouvelle sorte
## d'étape ; toute valeur des fichiers est un morceau, un moment ou « stop ».


func _parse(steps: Array) -> Cutscene:
	var library := CutsceneLibrary.new()
	library.add_from_dict({ "scene": { "variants": [ { "steps": steps } ] } }, "test")
	return library.get_cutscene(&"scene")


func test_music_key_is_read_on_any_step() -> void:
	var scene := _parse([{ "wait": 0.1, "music": "rival" }, { "dialogue": "x", "music": "stop" },
		{ "wait": 0.2 }])
	assert_not_null(scene)
	var steps := scene.variants[0].steps
	assert_eq(steps[0].music, &"rival")
	assert_eq(steps[1].music, &"stop")
	assert_eq(steps[2].music, &"", "absente : rien ne change")
	assert_eq(steps[0].copy().music, &"rival", "copiée avec l'étape (alias)")


func test_music_key_must_be_an_id() -> void:
	assert_null(_parse([{ "wait": 0.1, "music": 3 }]))
	assert_push_error_count(1)


func test_no_new_step_kind() -> void:
	assert_false(CutsceneStep.TYPE_KEYS.has("music"), "pas de nouvelle sorte (rangs du J23)")


func test_every_music_key_of_the_data_is_known() -> void:
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var audio := AudioLibrary.new()
	audio.load_dir()
	var count := 0
	for id: StringName in cutscenes.get_ids():
		for variant: CutsceneVariant in cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.music.is_empty() or step.music == AudioBridge.STOP:
					continue
				count += 1
				assert_true(audio.has_track(step.music) or not audio.event_track(step.music)
					.is_empty(), "%s : « %s »" % [id, step.music])
	assert_gt(count, 5, "Chen et les rivaux de main ont leur musique de scène")


func test_lifecycle_audio_changes() -> void:
	assert_eq(SessionLifecycle.audio_change(Node.NOTIFICATION_APPLICATION_PAUSED),
		SessionLifecycle.AudioChange.MUTE)
	assert_eq(SessionLifecycle.audio_change(Node.NOTIFICATION_APPLICATION_FOCUS_OUT),
		SessionLifecycle.AudioChange.DUCK)
	assert_eq(SessionLifecycle.audio_change(Node.NOTIFICATION_APPLICATION_RESUMED),
		SessionLifecycle.AudioChange.RESTORE)
	assert_eq(SessionLifecycle.audio_change(Node.NOTIFICATION_APPLICATION_FOCUS_IN),
		SessionLifecycle.AudioChange.RESTORE)
	assert_eq(SessionLifecycle.audio_change(Node.NOTIFICATION_WM_CLOSE_REQUEST),
		SessionLifecycle.AudioChange.NONE)
