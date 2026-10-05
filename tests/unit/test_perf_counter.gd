extends GutTest
## PerfCounter : compteur de fps de QA (jalon 5). Inactif sous GUT et en release ; ligne
## « [perf] fps=… min=… draw=… » toutes les 2 s.

const BOOT_SCENE := preload("res://game/boot.tscn")


func test_allowed_only_in_a_debug_build_with_boot_as_main_scene() -> void:
	assert_true(PerfCounter.is_allowed(true, true))
	assert_false(PerfCounter.is_allowed(false, true), "export release : jamais")
	assert_false(PerfCounter.is_allowed(true, false), "GUT, outils : Boot n'est pas principal")
	assert_false(PerfCounter.is_allowed(false, false))


func test_inactive_under_gut() -> void:
	assert_true(OS.is_debug_build())
	assert_false(PerfCounter.is_allowed(OS.is_debug_build(),
		get_tree().current_scene is Boot))
	var boot := BOOT_SCENE.instantiate() as Boot
	add_child_autofree(boot)
	for child in boot.get_children():
		assert_false(child is PerfCounter, "Boot ne doit pas ajouter le compteur sous GUT")


func test_line_format() -> void:
	assert_eq(PerfCounter.format_line(59.6, 41.2, 87), "[perf] fps=60 min=41 draw=87 tex=0.0")


func test_no_report_before_the_window_is_full() -> void:
	var counter := PerfCounter.new()
	autofree(counter)
	for i in 100:
		assert_false(counter.tick(1.0 / 60.0), "image %d" % i)
	assert_true(counter.tick(0.5), "fenêtre de 2 s atteinte")


## Durées exactes en binaire (1/64 s) : la somme d'une fenêtre de 2 s est exactement 2,0.
const FRAME: float = 1.0 / 64.0


func test_steady_cadence() -> void:
	var counter := PerfCounter.new()
	autofree(counter)
	var ready := false
	for i in 128:
		ready = counter.tick(FRAME)
	assert_true(ready)
	assert_eq(counter.take_line(55), "[perf] fps=64 min=64 draw=55 tex=0.0")


func test_a_stutter_shows_in_min_but_barely_in_the_average() -> void:
	var counter := PerfCounter.new()
	autofree(counter)
	var ready := false
	for i in 111:
		ready = counter.tick(FRAME)
	assert_false(ready)
	ready = counter.tick(17.0 * FRAME)  # une image de 266 ms : ~4 fps
	assert_true(ready)
	assert_eq(counter.take_line(10), "[perf] fps=56 min=4 draw=10 tex=0.0")


func test_window_resets_after_a_report() -> void:
	var counter := PerfCounter.new()
	autofree(counter)
	counter.tick(2.0)
	assert_ne(counter.take_line(1), "")
	assert_eq(counter.take_line(1), "", "fenêtre vide : pas de ligne")
	for i in 128:
		counter.tick(FRAME)
	assert_eq(counter.take_line(2), "[perf] fps=64 min=64 draw=2 tex=0.0",
		"la saccade de la fenêtre précédente ne fuit pas")


## Jalon 7 (§7) : la mémoire des textures, en Mo à 0,1 près.
func test_line_reports_texture_memory() -> void:
	assert_eq(PerfCounter.format_line(58.7, 57.0, 120, 23 * 1048576 + 524288),
		"[perf] fps=59 min=57 draw=120 tex=23.5")
	var counter := PerfCounter.new()
	autofree(counter)
	for i in 128:
		counter.tick(FRAME)
	assert_eq(counter.take_line(40, 18 * 1048576), "[perf] fps=64 min=64 draw=40 tex=18.0")
