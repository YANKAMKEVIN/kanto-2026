extends GutTest
## PerfProbe (moteur commun) : sonde de QA qui coupe une couche de la carte à la fois et écrit la
## cadence obtenue. Jamais posée sous GUT ; réglages facultatifs ; couches rendues après l'étape.

const BOOT_SCENE := preload("res://game/boot.tscn")


func test_not_added_under_gut() -> void:
	var boot := BOOT_SCENE.instantiate() as Boot
	add_child_autofree(boot)
	for child in boot.get_children():
		assert_false(child is PerfProbe, "Boot ne pose la sonde qu'en scène principale")


func test_configure_reads_hold_and_known_steps_only() -> void:
	var probe: PerfProbe = autofree(PerfProbe.new())
	probe.configure("")
	assert_eq(probe.hold, PerfProbe.DEFAULT_HOLD)
	assert_eq(probe.steps, PerfProbe.STEPS)
	probe.configure('{ "hold": 4, "steps": ["base", "no_ground", "inconnue", 3] }')
	assert_eq(probe.hold, 4.0)
	assert_eq(probe.steps, ["base", "no_ground"] as Array[String])
	probe.configure('{ "hold": 0.5 }')
	assert_eq(probe.hold, 2.0, "au moins 2 s")
	probe.configure("pas du JSON")
	assert_eq(probe.steps, ["base", "no_ground"] as Array[String], "inchangé")


func test_known_steps() -> void:
	for step: String in PerfProbe.STEPS:
		assert_true(PerfProbe.is_known_step(step), step)
	assert_false(PerfProbe.is_known_step("no_everything"))
