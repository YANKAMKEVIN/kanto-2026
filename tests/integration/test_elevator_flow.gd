extends GutTest
## Ascenseur dans le moteur (jalon 20 T13, `docs/tech/jalon-20.md` §2.3.3, §2.3.5 ; dossier 23 §9,
## §13.4, §19). Vraie scène Boot, vraies données (`data/world/elevators.json`) et vraies cartes
## (T24 : les cartes de QA `qa_elevator_j20*` sont retirées) :
## - grand magasin de Céladopole (sans clé) : RdC → cabine → panneau → 2e → sortie au 2e (arrivée
##   `from_elevator`), retour Android avalé pendant le trajet ;
## - FERMER (et retour Android) : rien ne change, la sortie mène toujours au RdC ;
## - sauvegarde écrite dans la cabine → position de l'arrivée de l'étage courant ; reprise ;
## - cabine du repaire Rocket (Clé Ascenseur) sans la Clé → T-50, pas de panneau, aucun trajet ;
##   avec la Clé → panneau B1F / B2F / B4F.
## Le trajet RdC → 5e est joué par `test_celadon_dept`, le repaire jusqu'au B4F par
## `test_hideout_elevator`.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const DEPT_START := "res://tools/debug_start/celadon_dept.json"
const HIDEOUT_START := "res://tools/debug_start/rocket_hideout_lift.json"
const SAVE_PATH := "user://test_elevator_flow_save.json"
const CAR := &"celadon_dept_elevator"
const GROUND := &"celadon_dept_gf"
const SECOND := &"celadon_dept_2f"
const HIDEOUT_CAR := &"rocket_hideout_elevator"
## Arrivée `from_elevator` des étages du magasin (devant la porte (16..17, 2)).
const ARRIVAL := Vector2i(16, 3)
## Case sous le panneau de la cabine du magasin (grille `celadopole_magasin_ascenseur.txt`).
const UNDER_PANEL := Vector2i(2, 2)
## Case sous le panneau de la cabine du repaire (grille `repaire_ascenseur.txt`).
const HIDEOUT_UNDER_PANEL := Vector2i(1, 2)
const T50 := "Le panneau ne répond pas. Il faut une clé."
const TIMEOUT := 15.0

var _play: HideoutPlay
var _events: Array[String] = []


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()
	_events.clear()


func after_each() -> void:
	_play.teardown()


func test_ride_to_the_second_floor_and_walk_out_there() -> void:
	await _start_in_the_car()
	var boot := _play.boot
	var director := boot.get_elevator_director()
	assert_eq(director.get_current_floor(), &"gf", "on vient du RdC")
	assert_eq(_exit_target(), [GROUND, &"from_elevator"], "sortie vers le RdC")
	await _examine_panel()
	assert_true(director.is_panel_open(), "panneau ouvert")
	var panel := director.get_panel() as ElevatorPanel
	assert_true(panel.is_open(), "écran ouvert")
	assert_eq(panel.get_view().current_floor(), &"gf", "étage courant grisé")
	assert_eq(panel.get_view().choosable_ids(), [&"2f", &"3f", &"4f", &"5f"] as Array[StringName])
	assert_false(boot.is_stable(), "panneau ouvert : partie pas stable")
	panel.floor_chosen.emit(&"2f")
	assert_true(director.is_riding(), "trajet en cours")
	assert_false(boot.is_stable(), "aucune écriture pendant le trajet")
	assert_true(director.handle_back(), "retour Android avalé pendant le trajet")
	await wait_until(func() -> bool: return boot.is_stable(), TIMEOUT)
	assert_eq(_events, ["started:2f", "finished:2f"] as Array[String])
	assert_eq(director.get_current_floor(), &"2f")
	assert_eq(_play.map_id(), CAR, "toujours dans la cabine : on sort à pied")
	assert_eq(_exit_target(), [SECOND, &"from_elevator"], "sortie réorientée")
	assert_false(panel.is_open())
	await _walk_out()
	assert_eq(_play.map_id(), SECOND, "sortie au 2e")
	assert_eq(_play.player.get_cell(), ARRIVAL, "devant la porte de l'ascenseur")
	assert_eq(director.get_elevator(), null, "hors cabine")
	assert_push_error_count(0)


func test_close_changes_nothing() -> void:
	await _start_in_the_car()
	var boot := _play.boot
	var director := boot.get_elevator_director()
	await _examine_panel()
	(director.get_panel() as ElevatorPanel).closed.emit()
	assert_false(director.is_panel_open(), "FERMER")
	assert_true(boot.is_stable(), "joueur libre")
	assert_eq(_events, ["closed"] as Array[String])
	# Même chose avec le retour Android.
	await _examine_panel()
	assert_true(director.is_panel_open())
	boot._on_go_back()
	assert_false(director.is_panel_open(), "retour Android = FERMER")
	assert_false(boot.get_menu_director().is_open(), "le retour n'ouvre pas le menu")
	assert_eq(director.get_current_floor(), &"gf", "étage inchangé")
	assert_eq(_exit_target(), [GROUND, &"from_elevator"])
	await _walk_out()
	assert_eq(_play.map_id(), GROUND, "on ressort au RdC")
	assert_eq(_play.player.get_cell(), ARRIVAL)


func test_a_save_in_the_car_resumes_in_front_of_the_floor_door() -> void:
	await _start_in_the_car()
	var boot := _play.boot
	await _examine_panel()
	assert_eq(boot.get_elevator_director().choose_floor(&"2f"), ElevatorRules.Status.OK)
	await wait_until(func() -> bool: return boot.is_stable(), TIMEOUT)
	assert_eq(_play.map_id(), CAR, "dans la cabine")
	assert_eq(boot._write_save("test"), OK)
	var saved := _play.saved()
	assert_eq(saved.get("map"), String(SECOND), "jamais la cabine")
	var cell: Array = saved.get("cell", [])
	var facing: Array = saved.get("facing", [])
	assert_eq(Vector2i(int(cell[0]), int(cell[1])), ARRIVAL, "arrivée `from_elevator` du 2e")
	assert_eq(Vector2i(int(facing[0]), int(facing[1])), Vector2i.DOWN,
		"orientation de la sortie (↓)")
	# Ouvrir le menu dans la cabine pousse la même position (Carte, Dresseur).
	boot.get_menu_director().open()
	assert_eq([GameState.current_map, GameState.player_cell], [SECOND, ARRIVAL])
	boot.get_menu_director().close()
	await _play.resume()
	assert_eq(_play.map_id(), SECOND, "reprise au 2e")
	assert_eq(_play.player.get_cell(), ARRIVAL, "devant la porte")


func test_keyed_elevator_without_the_key_says_t50() -> void:
	await _play.start(HIDEOUT_START, func() -> void: GameState.bag.remove(&"lift_key", 1))
	assert_eq(GameState.bag.count_of(&"lift_key"), 0, "sans la Clé Ascenseur")
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.map_id(), HIDEOUT_CAR, "dans la cabine du repaire")
	var director := _play.boot.get_elevator_director()
	assert_eq(director.get_current_floor(), &"b1f")
	await _play.walk_to(HIDEOUT_UNDER_PANEL)
	assert_eq(_play.player.get_cell(), HIDEOUT_UNDER_PANEL, "sous le panneau")
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	assert_false(director.is_panel_open(), "le panneau ne répond pas")
	assert_eq(_play.pages(), [T50] as Array[String], "T-50")
	assert_true(_play.boot.is_stable())
	assert_eq(director.choose_floor(&"b2f"), ElevatorRules.Status.UNKNOWN_FLOOR, "aucun trajet")
	assert_eq(director.get_current_floor(), &"b1f")
	(GameState.bag as Bag).add(&"lift_key")
	await _play.interact(Vector2i.UP)
	assert_true(director.is_panel_open(), "avec la Clé, le panneau s'ouvre")
	assert_eq(director.panel_view().floors.map(func(f: Dictionary) -> String: return f["label"]),
		["B1F", "B2F", "B4F"])
	director.close_panel()


# --- Outils -----------------------------------------------------------------------------------

## Départ du grand magasin, devant la porte de l'ascenseur du RdC, puis dans la cabine, sous le
## panneau. Les signaux du directeur sont relevés dans [member _events].
func _start_in_the_car() -> void:
	await _play.start(DEPT_START)
	var director := _play.boot.get_elevator_director()
	director.ride_started.connect(func(id: StringName) -> void: _events.append("started:%s" % id))
	director.ride_finished.connect(func(id: StringName) -> void:
		_events.append("finished:%s" % id))
	director.panel_closed.connect(func() -> void: _events.append("closed"))
	assert_eq(_play.map_id(), GROUND)
	await _play.walk_to(ARRIVAL)
	assert_eq(_play.player.get_cell(), ARRIVAL, "devant la porte de l'ascenseur")
	await _play.step(Vector2i.UP)
	assert_eq(_play.map_id(), CAR, "dans la cabine")
	await _play.walk_to(UNDER_PANEL)
	assert_eq(_play.player.get_cell(), UNDER_PANEL, "sous le panneau")


## EXAMINER le panneau (tourné ↑ sous lui) et dérouler le dialogue.
func _examine_panel() -> void:
	await _play.interact(Vector2i.UP)


## De la cabine à l'étage : jusqu'à la sortie, puis un pas ↓ (sortie PUSH ↓).
func _walk_out() -> void:
	var exit := _play.boot.get_map().get_warps().get_all()[0] as Warp
	await _play.walk_to(exit.cell)
	if _play.map_id() == CAR:
		await _play.step(Vector2i.DOWN)


## [carte, arrivée] de la sortie de la cabine.
func _exit_target() -> Array:
	for warp: Warp in _play.boot.get_map().get_warps().get_all():
		return [warp.target_map, warp.target_spawn]
	return []
