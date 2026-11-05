extends SceneTree
## Captures de la remise en scène du vol (JOH1, 2026-11-04 : « le joueur dort vraiment ») avec la
## vraie scène `game/boot.tscn`, sur le Mac (fenêtre, pas en headless) :
##
##   tools/capture_joh1_theft.sh [dossier] [hero|heroine]
##
## Départ : le Centre d'Oliville de nuit (`tests/fixtures/debug_start/…_night_autosave.json`) ;
## l'infirmière lance la scène. Les dialogues avancent seuls ; une image est écrite au début de
## chaque plan : `1_dort` (« … »), `2_sbires` (« Un bruit de verre. »), `3_plateau` (« Des pas
## pressés. »), `4_porte` (« Une porte qui claque. »), `5_retour_lit` (avant l'écriture du vol),
## `6_matin` (O-10). Fin après le matin.

const START := "res://tests/fixtures/debug_start/johto_olivine_night_autosave.json"
const SHOTS: Dictionary = {
	&"olivine_night_1": "1_dort", &"olivine_night_2": "2_sbires", &"olivine_night_3": "3_plateau",
	&"olivine_night_4": "4_porte", &"olivine_nurse_morning": "6_matin",
}

var _out: String = "build/captures/joh1_vol"
var _look: StringName = &"hero"
var _boot: Node
var _pending: String = ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--look="):
			_look = StringName(arg.trim_prefix("--look="))
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	for i in 3:
		await process_frame
	root.get_node(^"GameState").set(&"player_look", _look)
	var director: Object = _boot.call(&"get_cutscene_director")
	director.connect(&"step_played", _on_step)
	var box: Object = _boot.call(&"get_dialogue_box")
	var frames := 0
	var morning_done := false
	while frames < 60 * 90:
		await process_frame
		frames += 1
		if bool(box.call(&"is_open")):
			# Laisser le texte s'écrire et le plan se poser, puis l'image, puis la suite.
			for i in 45:
				await process_frame
			if not _pending.is_empty():
				await _shot(_pending)
				morning_done = morning_done or _pending == "6_matin"
				_pending = ""
			box.emit_signal(&"advance_requested")
			for i in 6:
				await process_frame
		elif morning_done:
			break
	quit(0)


func _on_step(step: Object) -> void:
	var kind := int(step.get(&"kind"))
	var id: StringName = step.get(&"dialogue_id")
	if kind == CutsceneStep.Kind.DIALOGUE and SHOTS.has(id):
		_pending = SHOTS[id]
	elif kind == CutsceneStep.Kind.CONFISCATE_TEAM:
		_shot.call_deferred("5_retour_lit")


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s_%s.png" % [_out, name, _look]
	image.save_png(path)
	print(path)
