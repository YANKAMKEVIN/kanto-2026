extends ColorRect
## Premier écran Android. Le lanceur natif reste visible jusqu'au démarrage de Godot.

const BOOT_SCENE := "res://game/boot.tscn"


func _ready() -> void:
	color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	var error := ResourceLoader.load_threaded_request(BOOT_SCENE, "PackedScene")
	# Laisser l'illustration se dessiner avant de passer à Boot, même si la scène
	# est déjà en cache.
	await get_tree().process_frame
	await get_tree().process_frame
	if error == OK:
		while ResourceLoader.load_threaded_get_status(BOOT_SCENE) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(BOOT_SCENE) == ResourceLoader.THREAD_LOAD_LOADED:
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(BOOT_SCENE))
			return
	error = get_tree().change_scene_to_file(BOOT_SCENE)
	if error != OK:
		push_error("Impossible de charger le jeu (%s)." % error_string(error))
