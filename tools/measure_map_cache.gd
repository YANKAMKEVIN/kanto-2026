extends SceneTree
## Mesure de la mémoire des textures sur le trajet Bourg Palette → Route 1 → Jadielle → Route 2
## → poste sud → Forêt de Jade (T19) → poste nord → Route 2 nord → Argenta → Centre → Argenta
## (jalon 10) → Route 3 → Centre du Mont Sélénite → Route 3 → sas de la Route 4 (jalon 12)
## (jalon 9 T18, jalon-09.md §2.8.6) : cache de cartes du SceneRouter **borné** (carte courante
## et voisines par warps) contre l'ancien comportement (toute carte chargée gardée pour la
## session, émulé ici en retenant chaque scène que le routeur a eue en cache).
##
##   godot --path . --resolution 1170x540 -s res://tools/measure_map_cache.gd
##   godot --path . --resolution 1170x540 -s res://tools/measure_map_cache.gd -- --unbounded
##   (… -- --shot=build/captures/cache_route_2.png : capture de la dernière carte)
##   (… -- --all-neighbors : comportement d'avant le jalon 10, intérieurs préchargés depuis
##   l'extérieur, pour comparer)
##   (… -- --route=mt_moon : la descente du Mont Sélénite, jalon 12)
##   (… -- --route=vermilion : Route 6 → Carmin-sur-Mer → Centre, jalon 15)
##   (… -- --route=route_5 : Azuria, la Route 5 et ses trois intérieurs, jalon 15)
##   (… -- --route=ss_anne : les pièces du S.S. Anne et l'Arène de Carmin, jalon 16)
##   (… -- --from=pewter_city : départ direct sur cette étape, processus neuf : le compteur
##   `tex=` est alors juste, aucune libération avant la mesure)
##
## Pas en --headless : le pilote factice ne compte aucune texture. Une ligne « [mem] » par étape,
## après la fin des préchargements : `cartes=` = textures (RVBA 8 bits, sans mipmaps) des scènes
## de cartes retenues, comptées une fois chacune par leurs dépendances (calcul exact, ce que le
## cache libère) ; `tex=` = compteur `RENDER_TEXTURE_MEM_USED` du processus, donné pour
## information (en retard d'une étape sur les chargements en arrière-plan, et faux après des
## libérations sur Mac : il peut passer sous zéro). Un processus par mode.

const STEPS: Array[Array] = [
	[&"pallet_town", &"start"],
	[&"route_1", &"from_pallet_w"],
	[&"viridian_city", &"from_route_1_w"],
	[&"route_2", &"from_viridian_c"],
	# Jalon 9 (T19) : la montée dans la Forêt de Jade.
	[&"viridian_forest_gate_south", &"from_route_2"],
	[&"viridian_forest", &"from_gate_south"],
	# Jalon 10 : poste nord, Route 2 nord, Argenta et un aller-retour au Centre.
	[&"viridian_forest_gate_north", &"from_forest"],
	[&"route_2_north", &"from_forest_gate"],
	[&"pewter_city", &"from_route_2_north_c"],
	[&"pewter_center", &"entrance"],
	[&"pewter_city", &"from_center"],
	# Jalon 12 (T8) : la Route 3, le Centre du Mont Sélénite, le sas de la Route 4 (atteint
	# par la grotte dans le jeu ; ici directement, les étages arrivent au T9).
	[&"route_3", &"from_pewter_c"],
	[&"mt_moon_center", &"entrance"],
	[&"route_3", &"from_center_e"],
	[&"route_4", &"from_mt_moon"],
]
## Jalon 12 (T9, §2.21) : la descente du Mont Sélénite (`-- --route=mt_moon`) : entrée du 1F,
## échelle A vers B1F, échelle B vers le secteur nord du 1F, échelle D vers B2F. Tant que la
## Route 3 et le sas (T8) n'existent pas, leurs passages sont « à venir » (rien à précharger).
const MT_MOON_STEPS: Array[Array] = [
	[&"mt_moon_1f", &"from_route_3_w"],
	[&"mt_moon_b1f", &"arrivee_a"],
	[&"mt_moon_1f", &"arrivee_b"],
	[&"mt_moon_b2f", &"arrivee_d"],
]
## Jalon 15 (T14, §2.11) : Route 6 → Carmin-sur-Mer → Centre → Carmin (`-- --route=vermilion`),
## mémoire « carte + voisines » (la plus lourde : Carmin et son navire).
const VERMILION_STEPS: Array[Array] = [
	[&"route_6", &"from_underground"],
	[&"vermilion_city", &"from_route_6_c"],
	[&"vermilion_center", &"entrance"],
	[&"vermilion_city", &"from_center"],
]
## Jalon 15 (T13, §2.11) : Azuria → Route 5 → Pension → Route 5 → poste → Route 5 → entrée du
## souterrain (`-- --route=route_5`) : mémoire « carte + voisines ».
const ROUTE_5_STEPS: Array[Array] = [
	[&"cerulean_city", &"from_route_5_c"],
	[&"route_5", &"from_cerulean_c"],
	[&"route_5_daycare", &"entrance"],
	[&"route_5", &"from_daycare"],
	[&"route_5_gate", &"from_route_5"],
	[&"route_5", &"from_gate"],
	[&"route_5_underground_gate", &"from_route_5"],
]
## Jalon 16 (T11, §2.13) : à bord du S.S. Anne (`-- --route=ss_anne`) : pont principal (six
## pièces voisines et Carmin), cabine A, pont extérieur, pont inférieur, cabine B, couloir, cabine
## du capitaine ; puis l'Arène de Carmin : mémoire « carte + voisines ».
const SS_ANNE_STEPS: Array[Array] = [
	[&"ss_anne_main_deck", &"from_ss_anne_w"],
	[&"ss_anne_cabin_a", &"entrance"],
	[&"ss_anne_main_deck", &"from_cabin_a"],
	[&"ss_anne_outer_deck", &"entrance"],
	[&"ss_anne_lower_deck", &"entrance"],
	[&"ss_anne_cabin_b", &"entrance"],
	[&"ss_anne_captain_corridor", &"entrance"],
	[&"ss_anne_captain_room", &"entrance"],
	[&"vermilion_gym", &"entrance"],
]
## Images attendues après chaque étape (textures envoyées, préchargements finis).
const SETTLE_FRAMES: int = 20

var _router: Node
var _unbounded: bool = false
## Mode « non borné » : scènes retenues comme l'ancien routeur.
var _hold: Array[Resource] = []


func _init() -> void:
	_unbounded = OS.get_cmdline_user_args().has("--unbounded")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var player: Node = (load("res://game/player/player.tscn") as PackedScene).instantiate()
	_router = (load("res://game/autoload/scene_router.gd") as GDScript).new()
	root.add_child(_router)
	_router.call(&"setup", world, player, null)
	if OS.get_cmdline_user_args().has("--all-neighbors"):
		_router.set(&"interior_maps", [] as Array[StringName])
	print("[mem] mode=%s" % ("non borné (ancien)" if _unbounded else "borné (T18)"))
	await _settle()
	print("[mem] départ tex=%.1f Mo" % _tex_mb())
	var steps: Array[Array] = STEPS
	if OS.get_cmdline_user_args().has("--route=mt_moon"):
		steps = MT_MOON_STEPS
	if OS.get_cmdline_user_args().has("--route=vermilion"):
		steps = VERMILION_STEPS
	if OS.get_cmdline_user_args().has("--route=route_5"):
		steps = ROUTE_5_STEPS
	if OS.get_cmdline_user_args().has("--route=ss_anne"):
		steps = SS_ANNE_STEPS
	var first := 0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			for i: int in steps.size():
				if String(steps[i][0]) == arg.trim_prefix("--from="):
					first = i
					break
	for i: int in range(first, steps.size()):
		var step: Array = steps[i]
		if i == first:
			_router.call(&"start", step[0], step[1], Vector2i.UP)
		else:
			_router.call(&"change_map", step[0], step[1], Vector2i.UP)
		await _settle()
		if _unbounded:
			for path: String in _router.call(&"get_cached_paths"):
				_hold.append(load(path))
			await _settle()
		var cached: PackedStringArray = _router.call(&"get_cached_paths")
		var held := PackedStringArray()
		if _unbounded:
			for resource: Resource in _hold:
				if not held.has(resource.resource_path):
					held.append(resource.resource_path)
		else:
			held = cached
		print("[mem] %s cartes=%.1f Mo (%d scènes : %s) tex=%.1f Mo changement=%.1f ms" % [
			step[0], _scene_textures_mb(held), held.size(), ", ".join(_names(held)), _tex_mb(),
			_router.get(&"last_change_ms")])
	# Contrôle visuel de la dernière carte (textures intactes après les libérations).
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			var camera := Camera2D.new()
			world.add_child(camera)
			camera.global_position = (player as Node2D).global_position
			camera.make_current()
			await _settle()
			root.get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--shot="))
	quit()


func _settle() -> void:
	for i: int in SETTLE_FRAMES:
		await process_frame
	var pending: Dictionary = _router.get(&"_prefetching")
	var guard := 600
	while guard > 0:
		var busy := false
		for path: String in pending:
			if ResourceLoader.load_threaded_get_status(path) \
					== ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				busy = true
		if not busy:
			break
		guard -= 1
		await process_frame
	for i: int in SETTLE_FRAMES:
		await process_frame


func _names(paths: PackedStringArray) -> PackedStringArray:
	var names := PackedStringArray()
	for path: String in paths:
		names.append(path.get_file().get_basename())
	names.sort()
	return names


## Octets des textures (RVBA 8 bits) dont dépendent les scènes [param paths], chacune une fois.
func _scene_textures_mb(paths: PackedStringArray) -> float:
	var textures: Dictionary = {}
	var visited: Dictionary = {}
	for path: String in paths:
		_collect_textures(path, textures, visited)
	var bytes := 0
	for texture_path: String in textures:
		var texture := load(texture_path) as Texture2D
		if texture != null:
			bytes += texture.get_width() * texture.get_height() * 4
	return bytes / 1048576.0


func _collect_textures(path: String, textures: Dictionary, visited: Dictionary) -> void:
	if visited.has(path):
		return
	visited[path] = true
	for dependency: String in ResourceLoader.get_dependencies(path):
		var dep_path := dependency.get_slice("::", dependency.get_slice_count("::") - 1)
		if dep_path.begins_with("uid://"):
			dep_path = ResourceUID.get_id_path(ResourceUID.text_to_id(dep_path))
		var extension := dep_path.get_extension()
		if extension in ["png", "webp", "jpg", "svg"]:
			textures[dep_path] = true
		elif extension in ["tscn", "tres", "scn", "res"]:
			_collect_textures(dep_path, textures, visited)


func _tex_mb() -> float:
	return Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
