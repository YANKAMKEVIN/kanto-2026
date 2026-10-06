extends RefCounted
## Images simulées pour les tests : des nœuds (directeur de scènes, joueur, PNJ) sont retirés du
## moteur (process_mode désactivé) et le test appelle leur [code]_process(STEP)[/code] à chaque
## [method frame], dans l'ordre du moteur (process_priority, puis ordre de l'arbre) ; les tweens
## nés ensuite passent par une [code]TweenClock[/code]. Une durée se compte alors en images,
## quelle que soit la charge de la machine.
##
## Utilisation : [code]const FrameSim := preload("res://tests/helpers/frame_sim.gd")[/code],
## [code]var sim := FrameSim.new(get_tree(), [director, player] + npcs, [entities])[/code]
## avant l'action mesurée, [code]await sim.frame()[/code] par image, [method finish] à la fin.
##
## Les nœuds passés doivent définir [code]_process[/code]. Un PNJ ([Npc]) qui entre sous l'un des
## [param parents] (apparition pendant une scène) est retiré du moteur dès son entrée, avant
## toute image. Les enfants des nœuds retirés (sprites, caméra du joueur) sont figés aussi.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STEP := TweenClock.STEP

var _tree: SceneTree
var _clock: TweenClock
## Nœuds retirés du moteur → leur process_mode d'origine (non typé : un PNJ peut être libéré
## pendant la simulation, et un objet libéré ne se convertit pas en Node).
var _frozen: Dictionary = {}
var _parents: Array = []
## Images simulées depuis la création.
var frames: int = 0


func _init(tree: SceneTree, nodes: Array, parents: Array = []) -> void:
	_tree = tree
	_clock = TweenClock.new(tree)
	for node: Node in nodes:
		freeze(node)
	for parent: Node in parents:
		_parents.append(parent)
		parent.child_entered_tree.connect(_on_child_entered)


## Retire [param node] du moteur (sans effet s'il l'est déjà).
func freeze(node: Node) -> void:
	if node != null and not _frozen.has(node):
		_frozen[node] = node.process_mode
		node.process_mode = Node.PROCESS_MODE_DISABLED


## Temps simulé écoulé (s).
func elapsed() -> float:
	return frames * STEP


## Une image simulée : attend une vraie image (pour les coroutines qui en attendent une), fait
## avancer les tweens, puis appelle _process(STEP) des nœuds retirés qui traitent.
func frame() -> void:
	await _tree.process_frame
	_clock.step()
	var nodes: Array[Node] = []
	for key: Variant in _frozen:
		if is_instance_valid(key) and (key as Node).is_inside_tree() \
				and (key as Node).is_processing():
			nodes.append(key)
	nodes.sort_custom(_before)
	for node: Variant in nodes:
		# Un PNJ traité plus tôt dans l'image peut en avoir libéré un autre.
		if is_instance_valid(node) and (node as Node).is_processing():
			(node as Node).call(&"_process", STEP)
	frames += 1


## Images simulées jusqu'à ce que [param done] rende vrai (au plus [param max_seconds]).
func run_until(done: Callable, max_seconds: float) -> void:
	var start := frames
	while not done.call() and (frames - start) * STEP < max_seconds:
		await frame()


## Rend les nœuds et les tweens au moteur (temps réel).
func finish() -> void:
	for parent: Variant in _parents:
		if is_instance_valid(parent) \
				and (parent as Node).child_entered_tree.is_connected(_on_child_entered):
			(parent as Node).child_entered_tree.disconnect(_on_child_entered)
	_parents.clear()
	_clock.release()
	for key: Variant in _frozen:
		if is_instance_valid(key):
			(key as Node).process_mode = _frozen[key]
	_frozen.clear()


func _on_child_entered(node: Node) -> void:
	if node is Npc:
		freeze(node)


static func _before(a: Node, b: Node) -> bool:
	if a.process_priority != b.process_priority:
		return a.process_priority < b.process_priority
	return b.is_greater_than(a)
