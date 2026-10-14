extends GutTest
## BackgroundLoader : repli synchrone en headless (le rendu factice de Godot 4.7 ne supporte pas
## la création de textures depuis un autre fil : « Parameter "t" is null »).

const PATH := "res://assets/ui/icon.png"

var _threaded: bool


func before_each() -> void:
	_threaded = BackgroundLoader.threaded


func after_each() -> void:
	BackgroundLoader.threaded = _threaded


func test_headless_runs_use_the_synchronous_fallback() -> void:
	assert_eq(DisplayServer.get_name(), "headless", "la suite tourne en headless")
	assert_false(BackgroundLoader.threaded, "aucun chargement sur un autre fil en headless")


func test_fallback_request_loads_at_once_then_fetch_closes_the_request() -> void:
	BackgroundLoader.threaded = false
	assert_eq(BackgroundLoader.status(PATH), ResourceLoader.THREAD_LOAD_INVALID_RESOURCE,
			"rien de demandé")
	assert_eq(BackgroundLoader.request(PATH, "Texture2D"), OK)
	assert_eq(BackgroundLoader.status(PATH), ResourceLoader.THREAD_LOAD_LOADED, "déjà chargé")
	var texture := BackgroundLoader.fetch(PATH) as Texture2D
	assert_not_null(texture)
	assert_eq(BackgroundLoader.status(PATH), ResourceLoader.THREAD_LOAD_INVALID_RESOURCE,
			"demande close")
	assert_null(BackgroundLoader.fetch(PATH), "rien à récupérer deux fois")


func test_fallback_request_twice_keeps_one_resource() -> void:
	BackgroundLoader.threaded = false
	BackgroundLoader.request(PATH, "Texture2D")
	BackgroundLoader.request(PATH, "Texture2D")
	assert_not_null(BackgroundLoader.fetch(PATH))
	assert_eq(BackgroundLoader.status(PATH), ResourceLoader.THREAD_LOAD_INVALID_RESOURCE)
