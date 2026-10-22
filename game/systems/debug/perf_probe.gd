class_name PerfProbe
extends Node
## Sonde de performance de QA (moteur commun, 2026-10-22) : sur le téléphone, coupe une couche
## de la carte à la fois et écrit dans le journal la cadence obtenue, pour savoir **ce qui
## coûte** sur une carte (méthode de la QA du J21 sur l'A17, rendue automatique) :
## [codeblock]
## [probe] no_ground fps=52.1 min=40 (map=route_11)
## [/codeblock]
## Chaque étape dure [member hold] s : la première moitié laisse la cadence se poser, la seconde
## est mesurée (moyenne et image la plus lente). Puis la couche est rendue et l'étape suivante
## commence ; à la fin du cycle, une ligne « [probe] fin ». Le joueur peut rester immobile.
##
## [b]Quand est-elle active ?[/b] Comme [PerfCounter] (build debug, [Boot] scène principale) et
## seulement si le fichier [constant USER_PATH] existe sur l'appareil :
## [codeblock]
## adb shell "run-as dev.kevin.kanto2026 sh -c 'echo {} > files/perf_probe.json'"
## [/codeblock]
## Contenu facultatif : { "hold": 8, "steps": ["base", "no_ground"] } (défauts :
## [constant DEFAULT_HOLD], [constant STEPS]). Jamais lu sous GUT ni en release.

const USER_PATH: String = "user://perf_probe.json"
const PREFIX: String = "[probe]"
const DEFAULT_HOLD: float = 8.0
## Étape « no_layer_<Nom> » : cache le seul `CanvasLayer` de ce nom.
const LAYER_STEP: String = "no_layer_"
## Étapes connues : « base » (rien de coupé), « no_<couche> » (nœud de la carte du même nom,
## voir [constant MAP_LAYERS]), « no_grade » (étalonnage d'écran), « no_shadows » (ombres
## portées et de contact), « no_map » (carte entière cachée), « no_layers » (tous les
## `CanvasLayer` : HUD, combat, fondu… ; les calques cachés sont écrits dans le journal).
const STEPS: Array[String] = [
	"base", "no_ground", "no_water", "no_forest_floor", "no_decals", "no_entities",
	"no_overhead", "no_shadows", "no_grade", "no_map", "base",
]
## Étape → nœuds de la carte (enfants directs) cachés.
const MAP_LAYERS: Dictionary[String, Array] = {
	"no_ground": ["PaintedGround"],
	"no_water": ["WaterOverlay"],
	"no_forest_floor": ["ForestFloor"],
	"no_decals": ["GroundDecals"],
	"no_entities": ["Entities"],
	"no_overhead": ["Overhead"],
}

var hold: float = DEFAULT_HOLD
var steps: Array[String] = STEPS.duplicate()

var _lighting: WorldLighting
var _index: int = -1
var _elapsed: float = 0.0
var _frames: int = 0
var _measured: float = 0.0
var _longest: float = 0.0
## Sommes de la fenêtre mesurée (ms) : GPU et CPU de rendu de la vue principale, scripts.
var _gpu_ms: float = 0.0
var _cpu_ms: float = 0.0
var _script_ms: float = 0.0
var _hidden: Array[CanvasItem] = []
var _hidden_layers: Array[CanvasLayer] = []


## Lit les réglages facultatifs de [param text] (JSON) ; étapes inconnues ignorées.
func configure(text: String) -> void:
	var json := JSON.new()
	if text.strip_edges().is_empty() or json.parse(text) != OK:
		return
	var data: Variant = json.data
	if not data is Dictionary:
		return
	if data.has("hold") and (data["hold"] is float or data["hold"] is int):
		hold = maxf(2.0, float(data["hold"]))
	if data.has("steps") and data["steps"] is Array:
		var chosen: Array[String] = []
		for step: Variant in data["steps"]:
			if step is String and is_known_step(step):
				chosen.append(step)
		if not chosen.is_empty():
			steps = chosen


static func is_known_step(step: String) -> bool:
	return step in ["base", "no_grade", "no_shadows", "no_map", "no_layers"] \
		or MAP_LAYERS.has(step) or step.begins_with(LAYER_STEP)


func setup(lighting: WorldLighting) -> void:
	_lighting = lighting


func _ready() -> void:
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


func _process(delta: float) -> void:
	if _index >= steps.size():
		return
	if _index < 0:
		# Attendre une carte (chargement, départ de débogage).
		if _current_map() == null:
			return
		_start(0)
		return
	_elapsed += delta
	if _elapsed >= hold * 0.5:
		_frames += 1
		_measured += delta
		_longest = maxf(_longest, delta)
		var viewport := get_viewport().get_viewport_rid()
		_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
		_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(viewport) \
			+ RenderingServer.get_frame_setup_time_cpu()
		_script_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	if _elapsed >= hold:
		_report()
		_start(_index + 1)


func _start(index: int) -> void:
	_restore()
	_index = index
	_elapsed = 0.0
	_frames = 0
	_measured = 0.0
	_longest = 0.0
	_gpu_ms = 0.0
	_cpu_ms = 0.0
	_script_ms = 0.0
	if _index >= steps.size():
		print("%s fin" % PREFIX)
		return
	_apply(steps[_index])


func _report() -> void:
	if _frames == 0 or _measured <= 0.0:
		return
	var map := _current_map()
	print("%s %s fps=%.1f min=%d gpu=%.1fms rendu_cpu=%.1fms scripts=%.1fms (map=%s)" % [
		PREFIX, steps[_index], _frames / _measured, roundi(1.0 / maxf(_longest, 0.001)),
		_gpu_ms / _frames, _cpu_ms / _frames, _script_ms / _frames,
		map.name if map != null else "?"])


func _apply(step: String) -> void:
	var map := _current_map()
	match step:
		"no_map":
			if map != null:
				_hide(map)
		"no_grade":
			if _lighting != null:
				for child: Node in _lighting.get_children():
					_hide(child as CanvasItem)
		"no_layers", _ when step.begins_with(LAYER_STEP):
			# Tous les calques (HUD, combat, fondu, étalonnage…), ou celui qui porte ce nom.
			var only := step.trim_prefix(LAYER_STEP) if step.begins_with(LAYER_STEP) else ""
			for node: Node in get_tree().root.find_children("*", "CanvasLayer", true, false):
				var layer := node as CanvasLayer
				if layer.visible and (only.is_empty() or layer.name == only):
					print("%s calque visible : %s (%d)" % [PREFIX, layer.get_path(), layer.layer])
					layer.visible = false
					_hidden_layers.append(layer)
		"no_shadows":
			for group: StringName in [WorldLighting.GROUP_CAST_SHADOWS,
					WorldLighting.GROUP_CONTACT_SHADOWS]:
				for node: Node in get_tree().get_nodes_in_group(group):
					_hide(node as CanvasItem)
		_:
			if map != null:
				for layer_name: String in MAP_LAYERS.get(step, []):
					_hide(map.get_node_or_null(NodePath(layer_name)) as CanvasItem)


func _hide(item: CanvasItem) -> void:
	if item != null and item.visible:
		item.visible = false
		_hidden.append(item)


func _restore() -> void:
	for item: CanvasItem in _hidden:
		if is_instance_valid(item):
			item.visible = true
	_hidden.clear()
	for layer: CanvasLayer in _hidden_layers:
		if is_instance_valid(layer):
			layer.visible = true
	_hidden_layers.clear()


func _current_map() -> Node2D:
	var map: Node = SceneRouter.get_current_map()
	return map as Node2D if is_instance_valid(map) else null
