extends ColorRect
## Premier écran Android. Le lanceur natif reste visible jusqu'au démarrage de Godot.
##
## Le jeu se charge **sur le fil principal**, jamais en arrière-plan : avec
## `ResourceLoader.load_threaded_request`, le chargement de Boot s'est figé sur le S24 (RC 0.35.1,
## 2026-11-09) et l'écran attendait sans fin. L'illustration reste affichée pendant le chargement.

const BOOT_SCENE := "res://game/boot.tscn"


func _ready() -> void:
	color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	# Laisser l'illustration se dessiner avant de bloquer le fil principal.
	await get_tree().process_frame
	await get_tree().process_frame
	var error := get_tree().change_scene_to_file(BOOT_SCENE)
	if error != OK:
		push_error("Impossible de charger le jeu (%s)." % error_string(error))
