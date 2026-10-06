extends SceneTree
## Convertit un modèle Collada (importé par Godot) en glTF binaire lisible par Blender 5, qui
## ne lit plus le Collada. Usage :
##   godot --headless --path . -s tools/art/blender/dae_vers_glb.gd -- res://chemin/modele.dae sortie.glb
## Le .dae doit être dans le projet (dossier temporaire importé au préalable par --import).


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var scene: PackedScene = load(args[0])
	if scene == null:
		push_error("dae_vers_glb : impossible de charger %s" % args[0])
		quit(1)
		return
	var root := scene.instantiate()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, args[1])
	print("GLB ", args[1], " : ", error_string(err))
	root.free()
	quit(0 if err == OK else 1)
