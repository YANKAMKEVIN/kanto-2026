extends GutTest
## Parcours 03 — Donjons et légendaires (jalon 33, T5 ; `docs/design/passes/j33-v1-chatgpt.md`
## §7 : Îles Écume, Manoir, Sylphe SARL, Route Victoire), une seule partie sur la vraie Boot
## ([ParcoursPlay]), partie du départ `j24_articuno` (5 Badges, Îles Écume résolues) :
## Artikodin capturé → Clé Secrète au Manoir → Auguste (Badge Volcan) → Giovanni à Jadielle
## (Badge Terre) → Électhor capturé → dernier rival de la Route 22 → Sulfura capturé →
## les trois légendaires et les 8 Badges relus après une relance.
## Captures : Hyper Ball à coup sûr ([method ParcoursPlay.catch_with], `sure`).

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const START := "res://tools/debug_start/j24_articuno.json"
const LEGENDARIES: Array[StringName] = [&"articuno", &"zapdos", &"moltres"]

var _play: ParcoursPlay


func before_each() -> void:
	_play = ParcoursPlay.new(self, "03_donjons")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_parcours_03_legendaires_badges_volcan_et_terre() -> void:
	_play.begin("Îles Écume B4F : Artikodin")
	await _play.start(START, func() -> void:
		_play.make_ace()
		_play.shortcut(["badge_marsh", "sabrina_met", "tm46_received"],
			"Badge Marais (parcours 02)"))
	# Escalier sud de la plateforme (7, 11) → SURFER sur la mer ouest (courant calmé) →
	# escalier (7, 3) → salle d'Artikodin (`jalon-24.md` §4, QA n° 4).
	await _play.walk_through(Vector2i(7, 11))
	_play.player.face(Vector2i.DOWN)
	await wait_process_frames(2)
	var check := _play.boot.get_mount_director().start_surf()
	await _play.run_scene()
	_play.expect(_play.player.get_mount() == Mount.Kind.SURF,
		"SURFER depuis l'escalier sud (contrôle %d, case %s)" % [check, _play.player.get_cell()])
	await _catch(Vector2i(6, 1), &"articuno")

	_play.begin("Manoir Pokémon B1F : Clé Secrète")
	_play.shortcut([], "Cramois'Île, Manoir 1F à 3F (journaux, trous : tests J25)")
	await _play.jump(&"pokemon_mansion_b1f", &"arrivee_s", Vector2i.DOWN)
	# Interrupteur sur ARRÊT : grille B ouverte jusqu'à la statue du nord (20, 3) ; MARCHE ouvre
	# la grille A de la salle ouest.
	_play.expect(not GameState.flags.has_flag(&"mansion_switch_on"), "interrupteur sur ARRÊT")
	await _play.talk_to(Vector2i(20, 3))
	_play.expect(GameState.flags.has_flag(&"mansion_switch_on"), "statue : interrupteur sur MARCHE")
	await _play.talk_to(Vector2i(5, 13))
	_play.expect(GameState.bag.has(&"secret_key"), "Clé Secrète dans le Sac")

	_play.begin("Arène de Cramois'Île : Auguste")
	_play.shortcut(["cinnabar_gym_gate_1", "cinnabar_gym_gate_2", "cinnabar_gym_gate_3",
		"cinnabar_gym_gate_4", "cinnabar_gym_gate_5", "cinnabar_gym_gate_6"],
		"portes du quiz (tests J25) ; les Dresseurs croisés sont combattus")
	await _play.jump(&"cinnabar_gym", &"depuis_ile", Vector2i.UP)
	_play.heal()
	await _play.talk_to(Vector2i(3, 3))
	_play.expect(_play.won(&"cinnabar_gym_blaine"), "Auguste battu")
	_play.expect_flags(["badge_volcano", "blaine_met", "tm38_received"], "Badge Volcan et CT38")

	_play.begin("Arène de Jadielle : Giovanni")
	_play.shortcut(["giovanni_gym_met"], "dalles tournantes de l'Arène (tests J28)")
	await _play.jump(&"viridian_gym", &"before_giovanni", Vector2i.UP)
	_play.heal()
	await _play.interact(Vector2i.UP)
	_play.expect(_play.won(&"viridian_gym_giovanni"), "Giovanni battu")
	_play.expect_flags(["badge_earth", "tm27_received"], "Badge Terre et CT27")

	_play.begin("Centrale : Électhor")
	await _play.jump(&"power_plant", &"from_route_10", Vector2i.UP)
	await _catch(Vector2i(4, 9), &"zapdos")

	_play.begin("Route 22 : dernier rival")
	await _play.jump(&"route_22_west", &"from_route_22", Vector2i.LEFT)
	_play.heal()
	await _play.walk_through(Vector2i(9, 7))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(_play.won(&"rival_route22_final"), "rival battu")
	_play.expect(_play.last_battle(&"rival_route22_final").get("foe", []) == _play.trainer_species(
		&"rival_route22_final", GameState.starter_species),
		"équipe contre le starter de la partie (%s)" % GameState.starter_species)
	_play.expect(GameState.flags.has_flag(&"rival_route22_final_won"), "rival_route22_final_won")

	_play.begin("Route Victoire 2F : Sulfura")
	_play.shortcut(["victory_road_1f_switch_1"], "Route 23 (contrôles des Badges, tests J29), "
		+ "Route Victoire 1F (rocher)")
	await _play.jump(&"victory_road_2f", &"moltres_front", Vector2i.UP)
	await _catch(Vector2i(11, 5), &"moltres")

	_play.begin("Bilan et relance")
	_play.expect_flags(["badge_boulder", "badge_cascade", "badge_thunder", "badge_rainbow",
		"badge_soul", "badge_marsh", "badge_volcano", "badge_earth"], "huit Badges")
	await _play.persist()
	for species: StringName in LEGENDARIES:
		_play.expect(_owned(species), "%s toujours là après la relance" % species)
		_play.expect(GameState.pokedex.is_caught(species), "%s capturé au Pokédex" % species)
	assert_true(_play.report())
	assert_push_error_count(0)


## Capture du légendaire posé en [param cell] : Hyper Ball sûre, drapeaux, équipe ou Stockage.
func _catch(cell: Vector2i, species: StringName) -> void:
	var facing := await _play.approach(cell)
	var outcome := await _play.catch_with(facing, &"ultra_ball", true)
	_play.expect(outcome == Battle.Outcome.CAUGHT, "%s capturé (issue %d)" % [species, outcome])
	_play.expect_flags(["%s_done" % species, "%s_caught" % species], "drapeaux de la rencontre")
	_play.expect(_owned(species), "%s dans l'équipe ou au Stockage" % species)
	_play.expect(_play.boot.get_map().get_npc(species) == null
		or not _play.boot.get_map().get_npc(species).visible, "%s n'est plus sur la carte" % species)


func _owned(species: StringName) -> bool:
	for pokemon: Pokemon in GameState.party.get_all() + GameState.storage.get_all():
		if pokemon.species_id == species:
			return true
	return false
