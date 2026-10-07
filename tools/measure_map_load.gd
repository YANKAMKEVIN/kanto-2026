extends SceneTree
## Temps de changement de carte (jalon 9 T19, budget jalon-09.md §2.7.4 : forêt ≤ 1,5 × Jadielle) :
## lecture disque de la scène (sans cache), instanciation, entrée dans l'arbre et première
## image, pour chaque carte demandée, plusieurs fois (médiane).
##
##   godot --path . --resolution 1170x540 -s res://tools/measure_map_load.gd \
##     -- viridian_city viridian_forest route_2
##
## Mesure Mac indicative (le S24 mesure le vrai temps au T20).

const REPEATS: int = 5


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var ids := OS.get_cmdline_user_args()
	if ids.is_empty():
		ids = PackedStringArray(["viridian_city", "viridian_forest"])
	for id: String in ids:
		var times: Array[float] = []
		for i: int in REPEATS:
			var start := Time.get_ticks_usec()
			var packed := ResourceLoader.load("res://game/world/maps/%s.tscn" % id, "",
				ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
			var loaded := Time.get_ticks_usec()
			var map := packed.instantiate()
			root.add_child(map)
			await process_frame
			var shown := Time.get_ticks_usec()
			times.append((shown - start) / 1000.0)
			print("[load] %s : lecture %.0f ms, total %.0f ms" % [id, (loaded - start) / 1000.0,
				(shown - start) / 1000.0])
			map.queue_free()
			await process_frame
		times.sort()
		print("[load] %s : médiane %.0f ms" % [id, times[REPEATS / 2]])
	quit()
