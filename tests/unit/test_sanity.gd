extends GutTest


func test_project_name() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Kanto 2026")


func test_viewport_reference_size() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)
