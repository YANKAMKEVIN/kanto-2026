extends GutTest
## Premier écran Android : Boot se charge sur le fil principal. Le chargement en arrière-plan
## s'est figé sur le S24 (RC 0.35.1, 2026-11-09), l'écran attendait sans fin.

const SCRIPT_PATH := "res://game/ui/opening/android_launch.gd"


func test_boot_is_never_loaded_in_the_background() -> void:
	var code := (load(SCRIPT_PATH) as GDScript).source_code
	assert_false(code.contains("load_threaded_request("), "pas de chargement en arrière-plan")
	assert_true(code.contains("change_scene_to_file(BOOT_SCENE)"), "chargement direct de Boot")


func test_boot_scene_exists() -> void:
	assert_true(ResourceLoader.exists("res://game/boot.tscn"))
