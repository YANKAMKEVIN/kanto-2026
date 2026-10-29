extends SceneTree
## Outil (DAF.9) : complète `dump_map_logic.gd` pour le gel fonctionnel du J33. Écrit, un nœud par
## ligne, chaque nœud non graphique d'une carte (portes, déclencheurs, apparitions, points d'examen,
## [FlagGate], PNJ…) avec sa position globale et ses variables de script enregistrées. Les nœuds
## purement graphiques (Polygon2D, Sprite2D, ColorRect, Line2D, lumières, TileMapLayer) et ceux
## d'une passe d'art (préfixe `Daf`, racine `PaintedGround`) sont ignorés : une seconde passe
## d'image doit laisser cette sortie identique.
##   godot --headless --path . -s res://tools/dump_map_nodes.gd -- <map_id> <sortie res://…>

const VISUAL: Array[String] = ["Polygon2D", "Sprite2D", "AnimatedSprite2D", "ColorRect", "Line2D",
	"PointLight2D", "DirectionalLight2D", "LightOccluder2D", "TileMapLayer", "CanvasModulate",
	"TextureRect", "GPUParticles2D", "CPUParticles2D"]
const ART_ROOTS: Array[String] = ["PaintedGround", "Eau", "Painted"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var id: String = args[0] if args.size() > 0 else "pallet_town"
	var map: Node = (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate()
	var lines := PackedStringArray()
	_walk(map, map, lines)
	var text := "\n".join(lines) + "\n"
	if args.size() > 1:
		var f := FileAccess.open(args[1], FileAccess.WRITE)
		f.store_string(text)
		f.close()
	print(text)
	map.free()
	quit()


func _walk(node: Node, root: Node, lines: PackedStringArray) -> void:
	for child: Node in node.get_children():
		var n := String(child.name)
		if n.begins_with("Daf") or (node == root and n in ART_ROOTS):
			continue
		if not child.get_class() in VISUAL:
			lines.append(_describe(child, root))
		_walk(child, root, lines)


func _describe(node: Node, root: Node) -> String:
	var s := "%s [%s]" % [root.get_path_to(node), node.get_class()]
	if node is Node2D:
		s += " pos=%s" % (node as Node2D).position
	elif node is Control:
		s += " pos=%s size=%s" % [(node as Control).position, (node as Control).size]
	var script := node.get_script() as Script
	if script != null:
		s += " script=%s" % script.resource_path.get_file()
		for prop: Dictionary in node.get_property_list():
			var usage: int = prop["usage"]
			if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
				s += " %s=%s" % [prop["name"], node.get(prop["name"])]
	return s
