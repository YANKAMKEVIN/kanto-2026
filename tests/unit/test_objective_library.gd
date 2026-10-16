extends GutTest
## ObjectiveLibrary : « Objectif : … » du tableau de bord (jalon-06.md §3.2, Q-4).


func _library(list: Array) -> ObjectiveLibrary:
	var library := ObjectiveLibrary.new()
	assert_true(library.add_from_array(list, "t"), "\n".join(library.get_errors()))
	return library


# --- Données réelles -----------------------------------------------------------------------

func test_real_data_loads_without_error() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	assert_eq(library.get_errors().size(), 0)
	# Jalon 15 (T15, jalon-15.md §2.7.9) : « explorer Carmin-sur-Mer. » puis « rejoindre
	# Carmin-sur-Mer, au sud. » en tête (ordre du voyage), devant le S.S. Anne du J14.
	# Jalon 16 (T13, jalon-16.md §2.9) : après le rival n° 4 et la CS01, en tête ; (T14) l'Arène
	# de Carmin devant (dossier 19 §0.5, objectifs R-9).
	assert_eq(library.get_ids(), [&"face_surge", &"open_surge_barrier",
		&"go_vermilion_gym", &"hm01_cascade_badge", &"help_captain",
		&"explore_vermilion", &"go_vermilion", &"ss_anne", &"help_bill",
		&"go_cerulean_cape",
		&"explore_cerulean", &"cross_nugget_bridge",
		&"get_cascade_badge", &"go_cerulean", &"cross_mt_moon", &"go_route_3",
		&"get_boulder_badge", &"go_north",
		&"deliver_parcel", &"reach_viridian"] as Array[StringName])


## Convention homogène (décision de Kevin du 2026-10-05) : tout texte d'objectif finit par un
## point (« remettre le colis au Professeur Chen. », « rejoindre Jadielle. »).
func test_every_objective_text_ends_with_a_period() -> void:
	var list: Array = JSON.parse_string(FileAccess.get_file_as_string(
		ObjectiveLibrary.DEFAULT_PATH))
	assert_gt(list.size(), 0)
	for entry: Dictionary in list:
		var text := str(entry.get("text", "")).strip_edges()
		assert_true(text.ends_with("."), "« %s » (%s) finit par un point" % [text, entry.get("id")])
		assert_false(text.ends_with(".."), "« %s » : un seul point" % text)


func test_q4_nothing_before_the_rival_battle_then_reach_viridian() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	assert_eq(library.current(flags), "", "prologue : aucune ligne")
	for flag: StringName in [&"mom_greeted", &"oak_met", &"starter_offered", &"starter_chosen",
			&"rival_challenged"]:
		flags.set_flag(flag)
		assert_eq(library.current(flags), "", "pas encore : %s" % flag)
	flags.set_flag(&"rival_battle_done")
	assert_eq(library.current(flags), "rejoindre Jadielle.")
	assert_eq(library.current_id(flags), &"reach_viridian")
	assert_false(library.is_draft(&"reach_viridian"), "texte validé par Kevin le 2026-10-06")
	flags.set_flag(&"got_potion_route_1")
	assert_eq(library.current(flags), "rejoindre Jadielle.", "toujours vrai sur la Route 1")
	# Jalon 7 T4 : l'arrivée à Jadielle (micro-scène) efface la ligne, en silence.
	flags.set_flag(&"viridian_arrived")
	assert_eq(library.current(flags), "", "arrivé à Jadielle : plus de ligne")


## Drapeaux lus par les objectifs avant que leur scène existe (J7) : à retirer de cette liste
## dès que la tâche qui les lève est fusionnée — `viridian_arrived` (T4, arrivée à Jadielle).
## `got_oak_parcel` est levé par la première visite de la Boutique depuis le T12
## (data/cutscenes/viridian_mart.json), `pokedex_activated` par la scène du colis depuis le T18
## (data/cutscenes/oak_lab.json).
## Jalon 10 (T8) : `pewter_arrived` (scène `pewter_arrival`) et `badge_boulder` (victoire de la
## scène `pewter_gym_brock`) sont levés par les données : retirés de la liste.
## Jalon 13 : `cerulean_reached` est levé par la scène `cerulean_arrival`, `badge_cascade` par
## celles d'Ondine (T19), `beaten_nugget_rocket` par celle du recruteur (T22) : retirés de la
## liste au T23 du J14 (`go_cerulean_cape` les lit).
## Jalon 12 (T18) : `route_3_entered` est levé par la scène du déclencheur de la Route 3 ;
## (T28) `route_4_reached` par celle du déclencheur du sas (data/cutscenes/route_4.json), posé
## aussi sur la vraie Route 4 du J13 (mêmes cases).
## Jalon 16 (T14) : `cut_vermilion_gym_bush` sera levé par la scène de Coupe de l'arbuste (T15).
const _PENDING_FLAGS: Array[StringName] = [&"viridian_arrived", &"cut_vermilion_gym_bush"]


## Jalon 10 (dossier 12 §16, jalon-10.md §2.10) : « continuer vers le nord. » jusqu'à Argenta,
## « obtenir le Badge Roche. » dès l'entrée (défaite comprise), puis « continuer vers la
## Route 3. » après la victoire.
func test_j10_north_then_boulder_badge_then_route_3() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	for flag: StringName in [&"rival_battle_done", &"viridian_arrived", &"got_oak_parcel",
			StoryFlags.POKEDEX_ACTIVATED]:
		flags.set_flag(flag)
	assert_eq(library.current_id(flags), &"go_north", "Route 2 nord : toujours le nord")
	flags.set_flag(&"pewter_arrived")
	assert_eq(library.current(flags), "obtenir le Badge Roche.")
	assert_eq(library.current_id(flags), &"get_boulder_badge")
	assert_false(library.is_draft(&"get_boulder_badge"), "texte verrouillé (dossier 12)")
	flags.set_flag(&"badge_boulder")
	assert_eq(library.current(flags), "continuer vers la Route 3.")
	assert_eq(library.current_id(flags), &"go_route_3")
	assert_false(library.is_draft(&"go_route_3"), "texte verrouillé (dossier 12)")
	flags.set_flag(&"pewter_arrived", false)
	assert_eq(library.current_id(flags), &"go_route_3", "le badge passe en tête")


## Jalon 15 (dossier 18 §12, T-42 ; jalon-15.md §2.7.9) : la Route 5 → « rejoindre
## Carmin-sur-Mer, au sud. » (dans les deux ordres des histoires du J14, avec ou sans Passe
## Bateau), Carmin → « explorer Carmin-sur-Mer. ».
func test_j15_route_5_then_vermilion() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	for flag: StringName in [&"rival_battle_done", &"viridian_arrived",
			StoryFlags.POKEDEX_ACTIVATED, &"pewter_arrived", &"badge_boulder", &"route_3_entered",
			&"route_4_reached", &"cerulean_reached", &"cerulean_rocket_beaten",
			&"cerulean_south_guard_left"]:
		flags.set_flag(flag)
	assert_eq(library.current_id(flags), &"get_cascade_badge", "Azuria, avant la Route 5")
	flags.set_flag(&"route_5_entered")
	assert_eq(library.current(flags), "rejoindre Carmin-sur-Mer, au sud.", "T-42")
	assert_eq(library.current_id(flags), &"go_vermilion")
	# Léo rencontré mais pas aidé (les deux histoires du J14 dans n'importe quel ordre) : le
	# voyage vers le sud passe devant.
	flags.set_flag(&"bill_met")
	assert_eq(library.current_id(flags), &"go_vermilion", "Léo pas encore aidé")
	flags.set_flag(&"bill_restored")
	flags.set_flag(&"got_ss_ticket")
	assert_eq(library.current_id(flags), &"go_vermilion", "avec le Passe Bateau")
	flags.set_flag(&"vermilion_reached")
	assert_eq(library.current(flags), "explorer Carmin-sur-Mer.", "T-42")
	assert_eq(library.current_id(flags), &"explore_vermilion")
	flags.set_flag(&"got_ss_ticket", false)
	assert_eq(library.current_id(flags), &"explore_vermilion", "sans le Passe Bateau")
	flags.set_flag(&"route_5_entered", false)
	assert_eq(library.current_id(flags), &"explore_vermilion", "l'arrivée seule suffit")
	for id: StringName in [&"go_vermilion", &"explore_vermilion"]:
		assert_false(library.is_draft(id), "texte validé (T-42)")


## Jalon 13 (dossier 16 §18, jalon-13.md §2.16, textes 61 à 63) : les quatre états d'Azuria, et le
## pont fait avant le badge (l'objectif reste « obtenir le Badge Cascade. »).
func test_j13_cerulean_states() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	for flag: StringName in [&"rival_battle_done", &"viridian_arrived", &"got_oak_parcel",
			StoryFlags.POKEDEX_ACTIVATED, &"pewter_arrived", &"badge_boulder"]:
		flags.set_flag(flag)
	assert_eq(library.current_id(flags), &"go_route_3", "avant Azuria : le J10 (le J12 passe devant)")
	flags.set_flag(&"cerulean_reached")
	assert_eq(library.current(flags), "obtenir le Badge Cascade.")
	assert_eq(library.current_id(flags), &"get_cascade_badge")
	# Le pont fait avant le badge : rien ne change.
	flags.set_flag(&"beaten_nugget_rocket")
	assert_eq(library.current_id(flags), &"get_cascade_badge", "pont avant badge")
	flags.set_flag(&"beaten_nugget_rocket", false)
	flags.set_flag(&"badge_cascade")
	assert_eq(library.current(flags), "traverser le Pont Pépite.")
	assert_eq(library.current_id(flags), &"cross_nugget_bridge")
	flags.set_flag(&"beaten_nugget_rocket")
	# Jalon 14 : « rejoindre le Cap d'Azuria. » passe devant (n° 66), puis « aider Léo. » ;
	# « explorer les environs d'Azuria. » revient une fois Léo aidé.
	assert_eq(library.current_id(flags), &"go_cerulean_cape")
	flags.set_flag(&"bill_met")
	flags.set_flag(&"bill_restored")
	assert_eq(library.current(flags), "explorer les environs d'Azuria.")
	assert_eq(library.current_id(flags), &"explore_cerulean")
	for id: StringName in [&"get_cascade_badge", &"cross_nugget_bridge", &"explore_cerulean"]:
		assert_false(library.is_draft(id), "texte validé le 2026-10-11")


## Jalon 7 (dossier 09 §4, §19) : le colis en main → « remettre le colis au Professeur
## Chen. » ; « rejoindre Jadielle » s'efface à l'arrivée. Jalon 8 (dossier 11, arbitrage 6) :
## après l'activation, « continuer vers le nord. » (remplacé au J9 à l'entrée de la forêt).
## Jalon 12 (dossier 15 §15, jalon-12.md §2.16) : les quatre états — badge seul → « continuer
## vers la Route 3. » ; première entrée sur la Route 3 → « traverser le Mont Sélénite. » ; sas de
## la Route 4 → « continuer vers Azuria. » (qui l'emporte même sans `route_3_entered`).
func test_j12_route_3_then_mt_moon_then_cerulean() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	for flag: StringName in [&"rival_battle_done", &"viridian_arrived",
			StoryFlags.POKEDEX_ACTIVATED, &"pewter_arrived", &"badge_boulder"]:
		flags.set_flag(flag)
	assert_eq(library.current_id(flags), &"go_route_3", "badge : la Route 3")
	flags.set_flag(&"route_3_entered")
	assert_eq(library.current(flags), "traverser le Mont Sélénite.")
	assert_eq(library.current_id(flags), &"cross_mt_moon")
	assert_false(library.is_draft(&"cross_mt_moon"), "texte validé (dossier 15 §20 n° 38)")
	flags.set_flag(&"route_4_reached")
	assert_eq(library.current(flags), "continuer vers Azuria.")
	assert_eq(library.current_id(flags), &"go_cerulean")
	assert_false(library.is_draft(&"go_cerulean"), "texte validé (dossier 15 §20 n° 39)")
	flags.set_flag(&"route_3_entered", false)
	assert_eq(library.current_id(flags), &"go_cerulean", "le sas passe en tête")


func test_parcel_objective_then_north_after_the_activation() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	flags.set_flag(&"rival_battle_done")
	assert_eq(library.current_id(flags), &"reach_viridian")
	flags.set_flag(&"viridian_arrived")
	assert_eq(library.current(flags), "", "arrivé à Jadielle : plus de « rejoindre Jadielle »")
	flags.set_flag(&"got_oak_parcel")
	assert_eq(library.current(flags), "remettre le colis au Professeur Chen.")
	assert_eq(library.current_id(flags), &"deliver_parcel")
	assert_false(library.is_draft(&"deliver_parcel"), "texte validé (dossier 09 §19)")
	flags.set_flag(&"viridian_arrived", false)
	assert_eq(library.current_id(flags), &"deliver_parcel", "le colis passe en tête")
	flags.set_flag(&"viridian_arrived")
	flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_eq(library.current(flags), "continuer vers le nord.", "jalon 8, T13")
	assert_eq(library.current_id(flags), &"go_north")
	assert_false(library.is_draft(&"go_north"), "texte validé (dossier 11, T13)")
	flags.set_flag(&"got_oak_parcel", false)
	assert_eq(library.current_id(flags), &"go_north", "actif pendant toute la Route 2")


func test_real_condition_flags_are_raised_by_the_story() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var raised := cutscenes.get_set_flags() + dialogues.get_set_flags()
	for flag: StringName in library.get_condition_flags():
		if _PENDING_FLAGS.has(flag) and not raised.has(flag):
			continue
		assert_true(raised.has(flag), "« %s » levé par une scène ou un dialogue" % flag)


# --- Règles --------------------------------------------------------------------------------

func test_first_matching_entry_wins() -> void:
	var library := _library([
		{"id": "b", "text": "étape B", "if": ["b"]},
		{"id": "a", "text": "étape A", "if": ["a"], "unless": ["done"]},
		{"id": "start", "text": "début"},
	])
	var flags := StoryFlags.new()
	assert_eq(library.current(flags), "début", "sans condition : toujours vraie")
	flags.set_flag(&"a")
	assert_eq(library.current(flags), "étape A")
	flags.set_flag(&"b")
	assert_eq(library.current(flags), "étape B", "ordre du fichier")
	flags.set_flag(&"b", false)
	flags.set_flag(&"done")
	assert_eq(library.current(flags), "début", "« unless » écarte A")
	assert_eq(library.current(null), "début")
	assert_eq(library.get_condition_flags(), [&"b", &"a", &"done"] as Array[StringName])


func test_no_entry_no_line() -> void:
	var library := _library([])
	assert_eq(library.current(StoryFlags.new()), "")
	assert_eq(library.current_id(StoryFlags.new()), &"")
	assert_false(library.is_draft(&"missing"))


func test_text_is_trimmed_and_draft_defaults_to_false() -> void:
	var library := _library([{"id": "x", "text": "  aller voir  "}])
	assert_eq(library.current(null), "aller voir")
	assert_false(library.is_draft(&"x"))


func test_invalid_entries_are_rejected() -> void:
	var library := ObjectiveLibrary.new()
	assert_false(library.add_from_array([
		{"id": "ok", "text": "bon"},
		{"id": "typo", "text": "x", "iff": ["a"]},
		{"id": "ok", "text": "doublon"},
		{"text": "sans id"},
		{"id": "no_text"},
		{"id": "bad_if", "text": "x", "if": "a"},
		{"id": "bad_flag", "text": "x", "unless": [""]},
		{"id": "bad_draft", "text": "x", "draft": "oui"},
		"pas un objet",
	], "t"))
	assert_eq(library.get_ids(), [&"ok"] as Array[StringName], "seule l'entrée valide reste")
	var errors := "\n".join(library.get_errors())
	assert_string_contains(errors, "clé inconnue « iff »")
	assert_string_contains(errors, "identifiant « ok » en double")
	assert_push_error_count(8, "une erreur par entrée invalide")


func test_missing_file_and_wrong_root() -> void:
	var library := ObjectiveLibrary.new()
	assert_false(library.load_file("res://tests/fixtures/absent_objectives.json"))
	assert_push_error("fichier introuvable")
	var path := "user://test_objectives_root.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\"id\": \"x\"}")
	file.close()
	assert_false(library.load_file(path))
	assert_push_error("une liste d'objectifs est attendue")
	DirAccess.remove_absolute(path)


## Jalon 14 (dossier 17 §15 n° 66 à 68, jalon-14.md §2.10) : « rejoindre le Cap d'Azuria. »
## après le Pont Pépite, « aider Léo. » après sa rencontre, « le S.S. Anne fait escale… » après
## le Passe Bateau ; en tête de liste, devant « continuer vers la Route 3. ».
## Jalon 16 : l'enchaînement du capitaine à Major Bob, puis plus aucune ligne du J16 après le
## Badge Foudre (décision de Kevin du 2026-10-16 : « rejoindre l'Arène de Carmin. » retiré).
func test_j16_objectives_until_the_thunder_badge() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	for flag: StringName in [&"badge_boulder", &"cerulean_reached", &"badge_cascade",
			&"beaten_nugget_rocket", &"bill_met", &"bill_restored", &"got_ss_ticket",
			&"route_5_entered", &"vermilion_reached"]:
		flags.set_flag(flag)
	flags.set_flag(&"rival_ss_anne_won")
	assert_eq(library.current(flags), "aider le capitaine.")
	flags.set_flag(&"got_hm01")
	assert_eq(library.current(flags), "rejoindre l'Arène de Carmin.")
	flags.set_flag(&"badge_cascade", false)
	assert_eq(library.current(flags), "obtenir le Badge Cascade.")
	flags.set_flag(&"badge_cascade")
	flags.set_flag(&"cut_vermilion_gym_bush")
	assert_eq(library.current(flags), "ouvrir le passage vers Major Bob.")
	flags.set_flag(&"vermilion_gym_puzzle_solved")
	assert_eq(library.current(flags), "affronter Major Bob.")
	flags.set_flag(&"badge_thunder")
	var j16: Array[StringName] = [&"face_surge", &"open_surge_barrier", &"go_vermilion_gym",
		&"hm01_cascade_badge", &"help_captain"]
	assert_false(j16.has(library.current_id(flags)),
		"après le Badge Foudre : plus d'objectif du J16 (%s)" % library.current_id(flags))
	assert_ne(library.current(flags), "rejoindre l'Arène de Carmin.")


func test_bill_objectives_in_order() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	for flag: StringName in [&"badge_boulder", &"cerulean_reached", &"badge_cascade"]:
		flags.set_flag(flag)
	assert_eq(library.current_id(flags), &"cross_nugget_bridge")
	flags.set_flag(&"beaten_nugget_rocket")
	assert_eq(library.current(flags), "rejoindre le Cap d'Azuria.")
	flags.set_flag(&"bill_met")
	assert_eq(library.current(flags), "aider Léo.")
	flags.set_flag(&"bill_restored")
	assert_eq(library.current_id(flags), &"explore_cerulean", "Léo aidé : l'objectif s'efface")
	flags.set_flag(&"got_ss_ticket")
	assert_eq(library.current(flags), "le S.S. Anne fait escale à Carmin-sur-Mer.")
	for id: StringName in [&"ss_anne", &"help_bill", &"go_cerulean_cape"]:
		assert_false(library.is_draft(id), "texte validé (dossier 17 §15)")
