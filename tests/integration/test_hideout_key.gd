extends GutTest
## Clé Ascenseur (jalon 20 T21, `jalon-20.md` §2.7.2 ; dossier 23 §13.4, §19, §20.7 n° 46 à 49,
## annexe A.8 n° 146, 147) avec la vraie scène Boot, la vraie carte `rocket_hideout_b4f` et ses
## PNJ, les vraies données et les vraies entrées :
## - le sbire (11, 2) se bat (n° 146), battu : n° 47, **pas de Clé** ;
## - on lui reparle : n° 48, `rocket_dropped_lift_key`, une Poké Ball en (10, 2) ; ensuite n° 147 ;
## - la Poké Ball : n° 49 en page, puis le toast, `lift_key` au Sac, `got_…` ; plus rien ensuite,
##   ni après un rechargement (unique) ;
## - Clé ramassée puis défaite contre un sbire du B3F : réveil au Centre, Clé gardée.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START_KEY := "res://tools/debug_start/rocket_hideout_key.json"
const START_B3F := "res://tools/debug_start/rocket_hideout_b3f.json"
const MAP := &"rocket_hideout_b4f"
const ROCKET := &"rocket_key"
const BALL := &"rocket_hideout_b4f_lift_key"
const BALL_CELL := Vector2i(10, 2)
const BEATEN := &"beaten_rocket_hideout_b4f_key"
const DROPPED := &"rocket_dropped_lift_key"
const GOT := &"got_rocket_hideout_b4f_lift_key"
const KEY := &"lift_key"
const BEFORE: Array[String] = ["La Clé Ascenseur ne quitte jamais ma poche.", "Jamais."]
const DEFEATED := "Non !…"
const DROP_LINE := "Oh non. J'ai laissé tomber la Clé Ascenseur."
const AFTER := "Si on te demande, tu l'as trouvée par terre."
const GOT_LINE := "Kevin obtient la Clé Ascenseur !"

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_hideout_key.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_the_key_is_only_dropped_after_talking_again_and_taken_once() -> void:
	await _play.start(START_KEY, func() -> void: GameState.flags.set_flag(BEATEN, false))
	_play.make_strong()
	assert_eq(_play.map_id(), MAP)
	assert_not_null(_play.boot.get_map().get_npc(ROCKET))
	assert_null(_play.boot.get_map().get_npc(BALL), "aucune Poké Ball au départ")
	# Le sbire voit (11, 3) : on s'y présente.
	await _play.walk_to(Vector2i(11, 3))
	await _play.run_scene()
	assert_true(_play.events.has("battle"), "le sbire se bat")
	var pages := _play.pages()
	assert_eq(pages.slice(0, 2), BEFORE, "n° 146")
	assert_true(pages.has(DEFEATED), "n° 47")
	assert_false(pages.has(DROP_LINE), "pas encore la Clé")
	assert_true(GameState.flags.has_flag(BEATEN))
	assert_false(GameState.flags.has_flag(DROPPED))
	assert_null(_play.boot.get_map().get_npc(BALL), "battu : toujours pas de Clé")
	assert_eq(GameState.bag.count_of(KEY), 0)
	# On lui reparle : la Clé tombe.
	_play.events.clear()
	assert_eq(_play.player.get_cell(), Vector2i(11, 3))
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), [DROP_LINE] as Array[String], "n° 48")
	assert_true(GameState.flags.has_flag(DROPPED))
	var ball := _play.boot.get_map().get_npc(BALL)
	assert_not_null(ball, "la Poké Ball est apparue")
	if ball != null:
		assert_eq(ball.get_cell(), BALL_CELL)
	assert_eq(GameState.bag.count_of(KEY), 0, "pas encore ramassée")
	# Reparler encore : n° 147, rien d'autre.
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), [AFTER] as Array[String], "n° 147")
	# La ramasser.
	await _play.walk_to(BALL_CELL + Vector2i.DOWN)
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), [GOT_LINE] as Array[String], "n° 49")
	assert_has(_play.events, "toast:CLÉ ASCENSEUR / ajoutée aux objets clés",
		"toast de l'objet clé (catégorie « key », sans « obtained »)")
	assert_eq(GameState.bag.count_of(KEY), 1)
	assert_true(GameState.flags.has_flag(GOT))
	assert_null(_play.boot.get_map().get_npc(BALL), "la Poké Ball a disparu")
	# Unique : plus de Poké Ball après un rechargement de la carte.
	await SceneRouter.change_map(MAP, &"from_b3f", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_null(_play.boot.get_map().get_npc(BALL))
	assert_not_null(_play.boot.get_map().get_npc(ROCKET), "le sbire reste en place (RB)")
	assert_eq(GameState.bag.count_of(KEY), 1, "une seule Clé")
	assert_push_error_count(0)


func test_a_dropped_key_left_on_the_floor_is_still_there_after_a_reload() -> void:
	await _play.start(START_KEY, func() -> void: GameState.flags.set_flag(DROPPED))
	var ball := _play.boot.get_map().get_npc(BALL)
	assert_not_null(ball, "Poké Ball au sol (roster : if dropped, unless got)")
	if ball != null:
		assert_eq(ball.get_cell(), BALL_CELL)
	await _play.walk_to(BALL_CELL + Vector2i.DOWN)
	await _play.interact(Vector2i.UP)
	assert_eq(GameState.bag.count_of(KEY), 1)
	assert_push_error_count(0)


func test_the_key_is_kept_after_a_defeat() -> void:
	await _play.start(START_B3F, func() -> void:
		for flag: StringName in [BEATEN, DROPPED, GOT]:
			GameState.flags.set_flag(flag)
		GameState.bag.add(KEY)
		GameState.heal_map = &"celadon_center"
		GameState.heal_spawn = &"heal")
	_play.make_weak()
	assert_eq(_play.map_id(), &"rocket_hideout_b3f")
	# Le technicien (26, 12) regarde vers le nord : la colonne x = 26 le réveille.
	await _play.walk_to(Vector2i(26, 7))
	await _play.step(Vector2i.DOWN)
	await _play.run_scene()
	assert_true(_play.events.has("battle"), "le sbire se bat")
	assert_false(GameState.flags.has_flag(&"beaten_rocket_hideout_b3f_2"), "perdu")
	assert_eq(_play.map_id(), &"celadon_center", "réveil au Centre de Céladopole")
	assert_eq(GameState.bag.count_of(KEY), 1, "Clé gardée")
	for flag: StringName in [BEATEN, DROPPED, GOT, &"game_corner_switch"]:
		assert_true(GameState.flags.has_flag(flag), "%s gardé" % flag)
	assert_push_error_count(0)
