extends GutTest
## Parcours 08 — Progression à pied, tronçons a, b (découpé pour équilibrer les lots de la CI).
## Parcours 08 — Progression à pied (jalon 33, T6 préparation) : les raccourcis du parcours 02
## rejoués sur la vraie Boot ([ParcoursPlay]), un tronçon par test, chacun depuis son départ de
## débogage, sans saut entre deux cartes sauf quand c'est écrit (« ↷ » au journal) :
## Pont Pépite et Bill, puzzle de Carmin, Routes 9-10 et Grotte Sombre, Casino et repaire
## B1F-B4F, Tour 3F-5F, Route 16 et Piste Cyclable, Safrania et Sylphe 1F-5F.
## Mewtwo en tête ([method ParcoursPlay.make_ace]) : le parcours vérifie les enchaînements
## (déclencheurs, scènes, énigmes, passages), pas l'équilibrage.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const DEBUG := "res://tools/debug_start/%s.json"

var _play: ParcoursPlay
var _teleport_fade := 0.0


func before_each() -> void:
	_teleport_fade = SceneRouter.teleport_fade_duration
	SceneRouter.teleport_fade_duration = 0.05
	_play = ParcoursPlay.new(self, "08a_pont_et_carmin")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_08a_pont_pepite_route_25_et_bill() -> void:
	_play.begin("Pont Pépite : cinq Dresseurs et le recruteur")
	await _play.start(DEBUG % "nugget_bridge", _play.make_ace)
	await _play.walk_through(Vector2i(33, 24))
	_play.expect_flags(["beaten_route_24_timeo", "beaten_route_24_alice", "beaten_route_24_malo",
		"beaten_route_24_romane", "beaten_route_24_ethan"], "cinq Dresseurs du pont battus")
	await _play.walk_through(Vector2i(33, 23))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect_flags(["got_nugget", "beaten_nugget_rocket"], "Pépite et recruteur battu")

	_play.begin("Route 25 à pied jusqu'à la maison de Léo")
	await _play.travel_all([&"route_25", &"bill_house"])

	_play.begin("Maison de Léo : Mélofée, écran, module, console")
	await _play.walk_through(Vector2i(7, 9))
	if not _play.boot.is_stable():
		await _play.run_scene()
	await _play.talk(Vector2i(6, 4), Vector2i.DOWN)
	_play.expect(GameState.flags.has_flag(&"bill_met"), "Mélofée parle (bill_met)")
	await _play.talk(Vector2i(5, 4), Vector2i.UP)
	await _play.talk(Vector2i(10, 4), Vector2i.UP)
	_play.expect_flags(["bill_screen_checked", "bill_module_checked", "bill_in_cabin"],
		"écran et module")
	await _play.talk(Vector2i(8, 4), Vector2i.UP)
	_play.expect_flags(["bill_restored", "got_ss_ticket"], "Léo rétabli, Passe Bateau")
	_play.expect(GameState.bag.has(&"ss_ticket"), "Passe Bateau dans le Sac")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


func test_08b_puzzle_de_carmin() -> void:
	_play.begin("Arène de Carmin : poubelles, barrière, Major Bob")
	await _play.start(DEBUG % "vermilion_gym_map", _play.make_ace)
	await _search_bin(13)
	var puzzle: Variant = _play.boot.get_active_puzzle(&"vermilion_gym")
	if not _play.expect(puzzle != null, "puzzle tiré à la première fouille"):
		assert_true(_play.report())
		return
	if not puzzle.is_first_found():
		await _search_bin(puzzle.first())
	_play.expect(puzzle.is_first_found(), "premier interrupteur trouvé")
	await _search_bin(puzzle.second())
	_play.expect(GameState.flags.has_flag(&"vermilion_gym_puzzle_solved"), "barrière ouverte")
	await _play.talk(Vector2i(8, 4), Vector2i.UP)
	_play.expect(_play.won(&"vermilion_gym_surge"), "Major Bob battu")
	_play.expect_flags(["badge_thunder", "tm24_received"], "Badge Foudre et CT24")
	assert_true(_play.report())
	assert_push_error_count(0)


func _search_bin(slot: int) -> void:
	var xs: Array[int] = [2, 5, 8, 11, 14]
	var ys: Array[int] = [7, 9, 11]
	var bin := Vector2i(xs[(slot - 1) % 5], ys[(slot - 1) / 5])
	await _play.talk(bin + Vector2i.DOWN, Vector2i.UP)
