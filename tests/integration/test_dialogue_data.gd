extends GutTest
## Données de dialogue du jalon 3A (jalon-03.md §3.3, §3.4, T4) : data/dialogues/*.json
## avec les vrais PNJ (data/npcs/*.json) et les vrais points d'examen des cartes.
## Chargement sans erreur, références (dialogues, react), drapeaux, textes du dossier 02
## repris mot pour mot, trois lignes au plus dans la vraie DialogueBox à 1920 × 1080,
## aucun texte provisoire (draft) depuis la validation du lot de textes (2026-10-06).
## Jalon 3B (T2) : dialogues joués par les scènes de data/cutscenes/ (via les
## EventTriggerPoint des cartes), drapeaux lus et levés par dialogues, scènes et PNJ.
## T3 : répliques du Prof. Chen, acteurs et cibles des « turn » (PNJ de la carte ou créés
## par la scène qui joue le dialogue).
## T4 : retour au labo (change_map : les dialogues suivants sont joués sur la carte cible),
## « oak_lab_reunion », nouvelle variante de Maya (oak_met), drapeau oak_lab_reunion.
## Jalon 4 (T1) : « oak_starter_offer » (Chen propose, 4 pages, regard vers la table à la 3e)
## joué à la fin de la variante 1 de route1_grass, qui lève starter_offered.
## T3 (jalon-04.md §13.5 à §13.7) : répliques du choix (« réciproque », rival, sortie
## empêchée), jouées par la scène du choix (lancée par le code sur la carte de l'offre) ou
## par le déclencheur LabExit ; variantes starter_chosen de Maya et de Chen ; drapeaux levés
## par le code (StarterChoice.get_set_flags : taken_*, starter_female).
## Décision n° 16 : répliques de la phase de choix ; celles de la décision n° 8 réservées à
## l'après-combat (rival_battle_done, drapeau « futur » du 4B), Maya accordée (lui / elle).
## Jalon 9 (T11) : répliques des 5 Dresseurs de la Forêt de Jade, mot pour mot depuis les
## « Textes verrouillés » du dossier 10 (« « … » / « … » » = une page de deux lignes), locuteur
## = nom du Dresseur ; réplique « avant » du bloc « trainer » utilisée comme un dialogue de PNJ.
## Jalon 10 (T8) : Route 2 nord et Argenta, mot pour mot depuis les « Textes verrouillés » du
## dossier 12 (même forme que le dossier 10) et le lot de textes du J10 validé le 2026-10-08
## (panneaux, noms affichés) ; dialogues en attente de leurs cartes ([constant UNUSED_YET]).

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const DOSSIER := "res://docs/design/dossier-02-prologue.md"
## Route 1 (jalon 5) : ses textes définitifs viennent du dossier-07, pas du dossier-02.
const DOSSIER_07 := "res://docs/design/dossier-07-route-1.md"
## Jalon 7 : textes de référence validés (dossier 09 §19) ; un jeton y est écrit « {espèce} ».
const DOSSIER_09 := "res://docs/design/dossier-09-jadielle.md"
## Jalon 9 : textes verrouillés du dossier 10 (Forêt de Jade, gardes, Dresseurs) ; une réplique
## de deux lignes « « ligne 1 » / « ligne 2 » » = une page, lignes jointes par « \n ».
const DOSSIER_10 := "res://docs/design/dossier-10-foret-de-jade.md"
## Gardes des postes de la Forêt de Jade (T6) : textes vérifiés par un test dédié.
const GATE_GUARDS: Array[StringName] = [&"forest_gate_north_guard", &"forest_gate_south_guard"]
## Dialogues pas encore posés sur une carte (vidée au T19 du jalon 9 : la forêt et ses postes
## sont dans [constant MAPS]). Jalon 10 (T8) : tous ceux de la Route 2 nord et d'Argenta, en
## attente de leurs cartes (T11 Route 2 nord et Argenta, T13 intérieurs, T14 la vie, T17
## l'Arène ; `pewter_gym_liam_defeated` est lue par la clé « defeated » du bloc « trainer »
## depuis le T9). À retirer carte par carte en ajoutant la carte à [constant MAPS].
## T13 : les intérieurs d'Argenta sont dans [constant MAPS] (Musée, maisons, Arène : retirés).
## T11 : la Route 2 nord et Argenta (extérieur) sont dans [constant MAPS] : liste vide.
const UNUSED_YET: Array[StringName] = [
]
## Jalon 11 (T20c) : phrases jouées par le contrôleur du compagnon (ni PNJ, ni point, ni scène).
const PLAYED_BY_COMPANION: Array[StringName] = [
	&"companion_cave", &"companion_city", &"companion_forest", &"companion_happy",
	&"companion_sniff", &"companion_stretch", &"companion_stretch_soft", &"companion_tired",
	&"companion_tired_f", &"companion_unwell", &"companion_watch", &"companion_water",
]
## Jalon 12 (T20) : phrases jouées par Boot (ni PNJ, ni point, ni scène) : la Corde Sortie
## ([constant Boot.ESCAPE_ROPE_DIALOGUE], dossier 15 §20 n° 33).
const PLAYED_BY_BOOT: Array[StringName] = [&"escape_rope_used"]
## Jalon 10 : textes verrouillés du dossier 12 (même forme que le dossier 10) et lot de textes du
## J10 (panneaux, noms affichés), où un retour à la ligne est écrit « \n ».
const DOSSIER_12 := "res://docs/design/dossier-12-argenta.md"
const LOT_J10 := "res://docs/design/textes/textes-brouillon-j10.md"
## Jalon 11 : textes du §13 (« « … » » par ligne).
const DOSSIER_14 := "res://docs/design/dossier-14-systemes-j11.md"
## Jalon 12 : lot de textes du §20 du dossier 15 (« n. Libellé : « … » »).
const DOSSIER_15 := "res://docs/design/dossier-15-route-3-mont-selenite.md"
## Jalon 8 : textes T1–T16 validés (dossier 11, « Textes à valider ») ; dans son tableau, « / »
## marque le retour à la ligne de la bulle et le gras (« ** ») le titre d'un panneau.
const DOSSIER_11 := "res://docs/design/dossier-11-route-2.md"
const _DOSSIER_TOKENS: Dictionary[String, String] = {"{first_wild_species}": "{espèce}"}
const MAPS: Array[StringName] = [
	&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab", &"pallet_town",
	&"route_1", &"route_22", &"viridian_city", &"viridian_center", &"viridian_mart",
	&"route_2",
	# Jalon 9 (T19) : la Forêt de Jade et ses deux postes.
	&"viridian_forest", &"viridian_forest_gate_south", &"viridian_forest_gate_north",
	# Jalon 10 (T13) : les intérieurs d'Argenta.
	&"pewter_center", &"pewter_mart", &"pewter_museum", &"pewter_museum_science", &"pewter_gym",
	&"pewter_house_mason", &"pewter_house_researcher",
	# Jalon 10 (T11) : la Route 2 nord et Argenta (extérieur).
	&"route_2_north", &"pewter_city",
	# Jalon 12 (T18) : la Route 3 et le Centre du Mont Sélénite.
	&"route_3", &"mt_moon_center",
	# Jalon 12 (T21) : le Mont Sélénite (1F, B1F) ; B2F au T25 (Rocket, chercheur, fossiles).
	&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f",
]
## Lot de textes validé par Kevin le 2026-10-06 (anciens brouillons : panneau, observations,
## soin de Maman, terminal du Stockage, portes de Jadielle…) : source des textes hors dossiers.
const TEXTES_VALIDES := "res://docs/design/textes/textes-brouillon-j7.md"
## Identifiants attendus (3A) : Maman, table, rival, carte, Maya, 3 starters, 3 habitants,
## panneau ; (3B) « Hé ! Attends ! », les répliques du Prof. Chen et la pensée des herbes ;
## (4A, T1) la proposition du Prof. Chen ; (4A, T3) le choix et la sortie empêchée.
const IDS: Array[StringName] = [
	&"aoki", &"breakfast_table", &"clerk", &"clerk_parcel",
	&"clerk_parcel_hello",
	# Jalon 11 (T20c) : phrases du compagnon (dossier 14 §13.12) ; grotte (jalon 12, T20).
	&"companion_cave", &"companion_city", &"companion_forest", &"companion_happy",
	&"companion_sniff", &"companion_stretch", &"companion_stretch_soft", &"companion_tired",
	&"companion_tired_f", &"companion_unwell", &"companion_watch", &"companion_water",
	# Jalon 12 (T20) : narration de la Corde Sortie, jouée par Boot.
	&"escape_rope_used",
	&"forest_gate_north_guard", &"forest_gate_south_guard",
	&"forest_hiker", &"forest_naturalist",
	&"forest_scout_eli_after", &"forest_scout_eli_before", &"forest_scout_milo_after",
	&"forest_scout_milo_before", &"forest_scout_noe_after", &"forest_scout_noe_before",
	&"forest_scout_theo_after", &"forest_scout_theo_before", &"forest_youngster_tom_after",
	&"forest_youngster_tom_before",
	&"haru", &"leo", &"maya", &"mom",
	&"mom_wakeup",
	# Jalon 12 (T21) : la vie du Mont Sélénite (dossier 15 §20 n° 12–15, objets).
	&"mt_moon_1f_ball_1", &"mt_moon_1f_crate", &"mt_moon_1f_hidden_1", &"mt_moon_1f_hiker",
	&"mt_moon_1f_lamp", &"mt_moon_1f_sign", &"mt_moon_b1f_ball_1", &"mt_moon_b1f_ball_2",
	# Jalon 12 (T25) : Team Rocket, chercheur, fossiles, CT01, Pierre Lune cachée (§20 n° 16–26).
	&"mt_moon_b2f_ball_1", &"mt_moon_b2f_hidden_1", &"mt_moon_fossil_dome",
	&"mt_moon_fossil_helix", &"mt_moon_researcher_before", &"mt_moon_researcher_chosen",
	&"mt_moon_researcher_defeated", &"mt_moon_researcher_guard", &"mt_moon_researcher_rematch",
	&"mt_moon_researcher_share", &"mt_moon_researcher_talk", &"mt_moon_rocket_1_before",
	&"mt_moon_rocket_1_defeated", &"mt_moon_rocket_1_rematch", &"mt_moon_rocket_2_before",
	&"mt_moon_rocket_2_defeated", &"mt_moon_rocket_2_rematch", &"mt_moon_rocket_3_before",
	&"mt_moon_rocket_3_defeated", &"mt_moon_rocket_3_rematch",
	&"nurse", &"nurse_wakeup",
	&"oak_after_battle",
	&"oak_lab_exit_block", &"oak_lab_reunion", &"oak_lab_waiting", &"oak_parcel_records",
	&"oak_parcel_rival", &"oak_parcel_rival_dex", &"oak_poke_balls", &"oak_poke_balls_intro",
	&"oak_pokedex_activated", &"oak_route1_call", &"oak_route1_warning", &"oak_starter_offer",
	&"oak_starter_reciprocal", &"observe_aoki_pidgey", &"observe_bulbasaur",
	&"observe_charmander", &"observe_leo_rattata", &"observe_squirtle",
	# Jalon 10 (T8) : Argenta (dossier 12, lot du J10).
	&"pewter_city_sign", &"pewter_gym_brock", &"pewter_gym_brock_badge", &"pewter_gym_brock_intro",
	&"pewter_gym_brock_lost", &"pewter_gym_brock_resume", &"pewter_gym_brock_tm",
	&"pewter_gym_brock_tm_late", &"pewter_gym_brock_tm_use", &"pewter_gym_brock_won",
	&"pewter_gym_guide", &"pewter_gym_liam_after", &"pewter_gym_liam_before",
	&"pewter_gym_liam_defeated", &"pewter_gym_sign", &"pewter_house_mason_kid",
	&"pewter_house_mason_partner", &"pewter_house_researcher", &"pewter_kid", &"pewter_lass",
	&"pewter_museum_clerk", &"pewter_museum_dome", &"pewter_museum_helix", &"pewter_museum_journal",
	&"pewter_museum_lab_door", &"pewter_museum_lab_sign", &"pewter_museum_moon_stone",
	&"pewter_museum_researcher", &"pewter_museum_researcher_f", &"pewter_museum_science_panel",
	&"pewter_museum_sign", &"pewter_old_man", &"pewter_route_3_guard",
	&"pewter_route_3_guard_cleared", &"pewter_route_3_guard_rule", &"pewter_stonemason",
	&"pewter_visitor",
	# DA.2 : le chercheur de Bourg Palette (réplique validée par Kevin, dossier-02 §4).
	&"researcher",
	&"rival", &"rival_challenge", &"rival_challenge_wait", &"rival_kanto_map",
	&"rival_lab_lost", &"rival_lab_waiting", &"rival_lab_won", &"rival_lab_won_leaving",
	&"rival_parcel_greet", &"rival_parcel_leaving", &"rival_parcel_return",
	&"rival_starter_pick", &"rival_starter_smile", &"route1_grass_thought",
	&"route22_rival_greet", &"route22_rival_hesitates", &"route22_rival_lost",
	&"route22_rival_won", &"route22_youngster_sigh",
	&"route_1_potion_found", &"route_1_traveler", &"route_22_traveler",
	# Jalon 8 : la Route 2 (dossier 11, T1 à T11).
	&"route_2_ball_1", &"route_2_ball_2", &"route_2_closed_gate", &"route_2_closed_sign",
	&"route_2_dense_tree", &"route_2_forest_sign", &"route_2_hiker", &"route_2_item_3_found",
	&"route_2_item_4_found",
	# Jalon 10 (T8) : la Route 2 nord.
	&"route_2_north_ball_1", &"route_2_north_mountaineer", &"route_2_north_rockslide",
	&"route_2_north_sign",
	&"route_2_sign", &"route_2_youngster",
	# Jalon 12 (T18) : la vie de la Route 3 (dossier 15 §20 n° 1–11, panneaux, objets).
	&"route_3_enzo_after", &"route_3_enzo_before", &"route_3_hidden_1", &"route_3_hiker",
	&"route_3_hugo_after", &"route_3_hugo_before", &"route_3_ines_after", &"route_3_ines_before",
	&"route_3_item_1", &"route_3_item_2", &"route_3_item_3", &"route_3_lea_after",
	&"route_3_lea_before", &"route_3_nolan_after", &"route_3_nolan_before",
	&"route_3_sacha_after", &"route_3_sacha_before", &"route_3_sign_center",
	&"route_3_sign_west", &"route_3_traveler",
	&"sign_pallet_town",
	&"storage_terminal",
	&"viridian_courier",
	# Jalon 9 (T18) : objets de la Forêt de Jade.
	&"viridian_forest_item_1", &"viridian_forest_item_2", &"viridian_forest_item_3_found",
	&"viridian_forest_item_4_found", &"viridian_forest_item_5", &"viridian_forest_item_6_found",
	&"viridian_gym_door", &"viridian_gym_watcher", &"viridian_house_door",
	&"viridian_kid",
	&"viridian_lass", &"viridian_old_man", &"viridian_traveler",
]
## Plus aucun drapeau futur au 4B : rival_battle_done est levé par la scène du combat
## (jalon-04.md §14.5, §14.8), quelle que soit l'issue.
## Jalon 7 : got_oak_parcel, lu par Chen (scène du colis, T18), est levé par la première visite
## de la Boutique depuis le T12 (data/cutscenes/viridian_mart.json).
## Jalon 9 : `pewter_arrived` (lu par le garde du poste nord) est posé par le J10, à l'arrivée à
## Argenta : levé par la scène `pewter_arrival` depuis le T8 du J10.
const FUTURE_FLAGS: Array[StringName] = []
var _library: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _offer: StarterOffer
## Dialogue → cartes où il est utilisé (PNJ ou point d'examen).
var _used_on: Dictionary[StringName, Array] = {}
## Carte → identifiants de PNJ.
var _npc_ids: Dictionary[StringName, Array] = {}
## Dialogue joué par une scène → PNJ créés (« spawn ») par cette scène.
var _spawned_for: Dictionary[StringName, Array] = {}


func before_all() -> void:
	_library = DialogueLibrary.new()
	_library.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_offer = StarterOffer.new()
	_offer.load_file()
	# Scène du choix : jouée par le code (StarterChoice) sur la carte de l'offre.
	_use_cutscene(_offer.chosen_scene, _offer.map_id)
	# Mots de réveil après une défaite (dossier 07 §11, dossier 09 §7) : joués par le code sur
	# la carte du point de repos (data/world/rest_points.json, jalon 7 T6), pas par un PNJ.
	var rest_points := RestPointLibrary.new()
	rest_points.load_file()
	for rest_map: StringName in rest_points.get_maps():
		_use(rest_points.get_point(rest_map).wakeup_dialogue, rest_map)
	for map_id: StringName in MAPS:
		_npc_ids[map_id] = []
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			(_npc_ids[map_id] as Array).append(spec.id)
			if spec.is_interactive():
				_use(spec.dialogue, map_id)
			# Jalon 9 : la réplique « avant » d'un Dresseur est jouée par sa séquence, sur sa carte.
			if spec.is_trainer():
				_use(spec.before_dialogue, map_id)
				# Jalon 10 (T9) : la réplique « vaincu », dite par la séquence à la victoire.
				if not spec.defeated_dialogue.is_empty():
					_use(spec.defeated_dialogue, map_id)
				# Jalon 12 (T25) : la réplique de reprise, dite par la séquence après une défaite.
				if spec.has_rematch():
					_use(spec.rematch_dialogue, map_id)
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Interactables").get_children():
			_use((point as InteractPoint).dialogue_id, map_id)
		for point: Node in map.get_node(^"Triggers").get_children():
			_use_cutscene((point as EventTriggerPoint).cutscene_id, map_id)
		map.free()
	# Jalon 7 (T18) : scène lancée par un dialogue (variante « cutscene ») sur les cartes où ce
	# dialogue est joué (la scène du colis, en parlant à Chen).
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				for map_id: StringName in (_used_on.get(id, []) as Array).duplicate():
					_use_cutscene(variant.cutscene, map_id)
			# Jalon 12 (T25) : scène lancée par le OUI d'un choix (« confirm_cutscene » : le
			# choix du fossile).
			if variant.choice != null and not variant.choice.confirm_cutscene.is_empty():
				for map_id: StringName in (_used_on.get(id, []) as Array).duplicate():
					_use_cutscene(variant.choice.confirm_cutscene, map_id)


## Dialogues joués par les étapes de la scène [param cutscene_id], sur la carte de son
## déclencheur, puis sur la carte de chaque « change_map » (T4). Un PNJ créé par « spawn »
## disparaît avec sa carte.
func _use_cutscene(cutscene_id: StringName, trigger_map: StringName) -> void:
	var cutscene := _cutscenes.get_cutscene(cutscene_id)
	if cutscene == null:
		return
	for variant: CutsceneVariant in cutscene.variants:
		var spawned: Array[StringName] = []
		var map_id := trigger_map
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.CHANGE_MAP:
				map_id = step.map_id
				spawned = []
			if step.kind == CutsceneStep.Kind.SPAWN:
				spawned.append(step.spec.id)
			if step.kind == CutsceneStep.Kind.DIALOGUE:
				_use(step.dialogue_id, map_id)
				if not _spawned_for.has(step.dialogue_id):
					_spawned_for[step.dialogue_id] = []
				(_spawned_for[step.dialogue_id] as Array).append_array(spawned)


func _use(dialogue: StringName, map_id: StringName) -> void:
	if not _used_on.has(dialogue):
		_used_on[dialogue] = []
	(_used_on[dialogue] as Array).append(map_id)


## Toutes les pages de toutes les variantes : [id, texte, page].
func _pages() -> Array[Array]:
	var pages: Array[Array] = []
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			for page: DialoguePage in variant.pages:
				pages.append([id, page.text, page, variant])
			# Jalon 7 (T8) : pages des réponses d'un choix (SOIGNER / PAS MAINTENANT).
			if variant.choice != null:
				for page: DialoguePage in variant.choice.confirm_pages + variant.choice.cancel_pages:
					pages.append([id, page.text, page, variant])
	return pages


func test_library_loads_without_error() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), "data/dialogues/ se charge")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_eq(_without_qa(library.get_ids()), IDS)


func test_every_used_dialogue_exists() -> void:
	assert_gt(_used_on.size(), 0)
	for dialogue: StringName in _used_on:
		assert_true(_library.has_dialogue(dialogue), "dialogue « %s » défini" % dialogue)


func test_every_dialogue_is_used() -> void:
	var played := _cutscenes.get_dialogue_ids()
	for id: StringName in _real_ids():
		if UNUSED_YET.has(id) or PLAYED_BY_COMPANION.has(id) or PLAYED_BY_BOOT.has(id):
			continue
		assert_true(_used_on.has(id) or played.has(id),
			"dialogue « %s » utilisé par un PNJ, un point ou une scène" % id)


func test_every_dialogue_played_by_a_cutscene_exists() -> void:
	assert_eq(_cutscenes.get_errors().size(), 0, str(_cutscenes.get_errors()))
	var played := _cutscenes.get_dialogue_ids()
	assert_eq(played, [&"clerk_parcel", &"clerk_parcel_hello",
		# Jalon 12 (T25) : scène du chercheur et choix du fossile.
		&"mt_moon_researcher_before", &"mt_moon_researcher_chosen",
		&"mt_moon_researcher_defeated", &"mt_moon_researcher_rematch",
		&"mt_moon_researcher_share",
		&"oak_after_battle", &"oak_lab_exit_block", &"oak_lab_reunion",
		&"oak_parcel_records", &"oak_parcel_rival", &"oak_parcel_rival_dex", &"oak_poke_balls",
		&"oak_poke_balls_intro", &"oak_pokedex_activated", &"oak_route1_call",
		&"oak_route1_warning", &"oak_starter_offer", &"oak_starter_reciprocal",
		# Jalon 10 (T8) : scènes de Pierre et du garde de la Route 3.
		&"pewter_gym_brock_badge", &"pewter_gym_brock_intro", &"pewter_gym_brock_lost",
		&"pewter_gym_brock_resume",
		# Jalon 11 (T14) : remise de la CT34.
		&"pewter_gym_brock_tm", &"pewter_gym_brock_tm_late", &"pewter_gym_brock_tm_use",
		&"pewter_gym_brock_won", &"pewter_route_3_guard_cleared",
		&"pewter_route_3_guard_rule",
		&"rival_challenge", &"rival_challenge_wait", &"rival_lab_lost", &"rival_lab_won",
		&"rival_lab_won_leaving", &"rival_parcel_greet", &"rival_parcel_leaving",
		&"rival_parcel_return", &"rival_starter_pick", &"rival_starter_smile",
		&"route1_grass_thought", &"route22_rival_greet", &"route22_rival_hesitates",
		&"route22_rival_lost", &"route22_rival_won", &"route22_youngster_sigh",
		&"route_1_potion_found", &"route_2_item_3_found", &"route_2_item_4_found",
		&"viridian_forest_item_3_found", &"viridian_forest_item_4_found",
		&"viridian_forest_item_6_found"]
		as Array[StringName])
	for id: StringName in played:
		assert_true(_library.has_dialogue(id), "dialogue « %s » défini" % id)
		if UNUSED_YET.has(id):
			continue
		assert_true(_used_on.has(id), "« %s » joué depuis un déclencheur ou par le code" % id)
	for id: StringName in [&"oak_starter_reciprocal", &"rival_starter_pick",
			&"rival_starter_smile", &"rival_challenge_wait", &"rival_challenge",
			&"oak_lab_exit_block", &"rival_lab_won", &"rival_lab_won_leaving", &"rival_lab_lost",
			&"oak_after_battle", &"oak_poke_balls_intro", &"oak_poke_balls"]:
		assert_eq(_used_on.get(id), [&"oak_lab"], "%s joué au labo" % id)
	# Jalon 7 (T25) : la scène du rival n° 2, sur la Route 22 seulement.
	for id: StringName in [&"route22_youngster_sigh", &"route22_rival_hesitates",
			&"route22_rival_greet", &"route22_rival_won", &"route22_rival_lost"]:
		assert_eq(_used_on.get(id), [&"route_22"], "%s joué sur la Route 22" % id)


func test_every_react_targets_an_npc_of_the_map_where_it_is_used() -> void:
	for row: Array in _pages():
		var page: DialoguePage = row[2]
		if page.react.is_empty():
			continue
		var maps: Array = _used_on.get(row[0], [])
		assert_false(maps.is_empty(), "%s utilisé" % row[0])
		for map_id: StringName in maps:
			assert_true((_npc_ids[map_id] as Array).has(page.react),
				"%s : « react » %s sur %s" % [row[0], page.react, map_id])


func test_every_turn_actor_and_target_exists_where_the_dialogue_is_played() -> void:
	var turns := 0
	for row: Array in _pages():
		var page: DialoguePage = row[2]
		for actor: StringName in page.turn:
			turns += 1
			for who: StringName in [actor, page.turn[actor]]:
				if who == NpcRoster.PLAYER_ID or (who != actor and Grid.is_direction_name(who)):
					continue
				var maps: Array = _used_on.get(row[0], [])
				assert_false(maps.is_empty(), "%s utilisé" % row[0])
				for map_id: StringName in maps:
					var known: bool = (_npc_ids[map_id] as Array).has(who) or \
						(_spawned_for.get(row[0], []) as Array).has(who)
					assert_true(known, "%s : « turn » %s sur %s" % [row[0], who, map_id])
	assert_gt(turns, 0, "les répliques de Chen ont des « turn »")


func test_oak_looks_at_the_grass_on_his_second_line_and_thinks_before_the_last() -> void:
	var pages := _library.get_dialogue(&"oak_route1_warning").variants[0].pages
	assert_eq(pages.size(), 4)
	assert_eq(pages[0].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])
	assert_eq(pages[1].turn, {&"oak": &"up"} as Dictionary[StringName, StringName],
		"il regarde les hautes herbes (nord)")
	assert_eq(pages[2].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])
	assert_eq(pages[3].pause, 1.0, "il réfléchit une seconde")
	assert_eq(pages[3].text, "...Viens avec moi.")


func test_every_condition_flag_is_set_somewhere() -> void:
	var set_flags := _library.get_set_flags() + _cutscenes.get_set_flags() \
		+ StarterChoice.get_set_flags(_offer)
	var read_flags := _library.get_condition_flags() + _cutscenes.get_condition_flags()
	for map_id: StringName in MAPS:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			read_flags.append_array(spec.if_flags + spec.unless_flags)
			# Jalon 12 (T25) : `beaten_<id>` d'un Dresseur est levé par sa séquence (victoire).
			if spec.is_trainer():
				set_flags.append(TrainerRules.beaten_flag(spec.trainer_id))
	for flag: StringName in read_flags:
		if FUTURE_FLAGS.has(flag):
			continue
		assert_true(set_flags.has(flag), "drapeau « %s » levé par un « set »" % flag)
	for flag: StringName in FUTURE_FLAGS:
		assert_false(set_flags.has(flag), "« %s » : levé par un jalon futur" % flag)
	assert_true(read_flags.has(&"starter_chosen"), "starter_chosen lu (pensée des herbes)")
	assert_eq(_library.get_set_flags(),
		[&"blacked_out_before", &"forest_hiker_talked", &"forest_naturalist_talked",
			&"mom_greeted", &"pewter_researcher_talked", &"poison_unlocked", &"rival_met",
			&"route_2_hiker_talked", &"route_2_youngster_talked", &"storage_terminal_seen",
			&"viridian_old_man_talked"]
		as Array[StringName])
	assert_eq(_cutscenes.get_set_flags(), [&"badge_boulder", &"beaten_mt_moon_researcher",
		&"brock_met",
		&"got_mt_moon_1f_hidden_1", &"got_mt_moon_1f_item_1", &"got_mt_moon_b1f_item_1",
		&"got_mt_moon_b1f_item_2", &"got_mt_moon_b2f_hidden_1", &"got_mt_moon_b2f_item_1",
		&"got_oak_parcel", &"got_potion_route_1",
		&"got_route_2_item_1", &"got_route_2_item_2", &"got_route_2_item_3",
		&"got_route_2_item_4", &"got_route_2_north_item_1", &"got_route_3_hidden_1",
		&"got_route_3_item_1", &"got_route_3_item_2", &"got_route_3_item_3",
		&"got_viridian_forest_item_1",
		&"got_viridian_forest_item_2",
		&"got_viridian_forest_item_3", &"got_viridian_forest_item_4",
		&"got_viridian_forest_item_5", &"got_viridian_forest_item_6",
		&"lost_mt_moon_researcher", &"mt_moon_fossil_chosen", &"mt_moon_got_dome_fossil",
		&"mt_moon_got_helix_fossil", &"oak_lab_reunion",
		&"oak_met", &"pewter_arrived",
		&"pokedex_activated", &"rival_battle_done", &"rival_challenged", &"rival_lab_lost",
		&"rival_lab_won", &"rival_left_lab", &"rival_route22_lost", &"rival_route22_won",
		&"route_3_entered", &"route_3_guard_cleared", &"starter_chosen", &"starter_offered", &"tm34_received",
		&"viridian_arrived"] as Array[StringName])
	assert_eq(_used_on.get(&"oak_lab_reunion"), [&"oak_lab"], "joué au labo, après le fondu")
	assert_eq(_used_on.get(&"oak_starter_offer"), [&"oak_lab"], "joué au labo")


## Drapeaux du choix (§13.3) : l'offre les nomme, le code lève les taken_*, la scène lève
## done_flag ; starter_offered (levé par route1_grass) est lu par la scène oak_lab_exit.
func test_starter_flags_are_set_and_read() -> void:
	assert_eq(StarterChoice.get_set_flags(_offer), [&"taken_bulbasaur", &"taken_charmander",
		&"taken_squirtle", &"starter_female"] as Array[StringName])
	assert_true(_library.get_condition_flags().has(_offer.female_flag), "lu par Maya")
	var read_flags := _cutscenes.get_condition_flags()
	for spec: NpcSpec in NpcRoster.load_for_map(_offer.map_id).get_all():
		read_flags.append_array(spec.if_flags + spec.unless_flags)
	for flag: StringName in StarterChoice.get_set_flags(_offer):
		if flag == _offer.female_flag:
			continue
		assert_true(read_flags.has(flag), "« %s » lu (présence du starter)" % flag)
	assert_true(_cutscenes.get_set_flags().has(_offer.done_flag), "done_flag levé par la scène")
	assert_true(_cutscenes.get_set_flags().has(_offer.open_flag), "open_flag levé par la scène")
	assert_true(read_flags.has(_offer.open_flag), "open_flag lu par oak_lab_exit")


## Décisions de Kevin n° 1, 2, 11 et 16 (jalon-04.md §13.5, §13.12) : textes mot pour mot,
## une page chacun ; « Ça devrait être intéressant. » gardé (décision n° 16, Q-A).
func test_starter_choice_lines() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"oak_starter_reciprocal": ["Prof. Chen", "On dirait que le choix est réciproque."],
		&"rival_starter_pick": ["{rival}", "Alors ce sera toi."],
		&"rival_starter_smile": ["{rival}", "Ça devrait être intéressant."],
		&"rival_challenge_wait": ["{rival}", "Attends."],
		&"rival_challenge": ["{rival}",
			"On ne va quand même pas partir sans savoir ce qu'ils savent faire."],
		&"oak_lab_exit_block": ["Prof. Chen",
			"Pas si vite. Tu n'as pas encore choisi ton partenaire."],
	}
	for id: StringName in expected:
		var dialogue := _library.get_dialogue(id)
		assert_eq(dialogue.speaker, expected[id][0], "%s : locuteur" % id)
		assert_false(dialogue.narration)
		assert_false(dialogue.draft)
		assert_eq(dialogue.variants.size(), 1)
		var pages := dialogue.variants[0].pages
		assert_eq(pages.size(), 1, "%s : une page" % id)
		assert_eq(pages[0].text, expected[id][1])


## Décision n° 16 (Q-G) : pendant la phase de choix (starter_offered, pas encore choisi),
## Chen et le rival ont leurs nouvelles répliques ; avant l'offre, celles du 3B.
## Décision n° 16 (Q-E) : les répliques de la décision n° 8 (Chen « Le monde qui vous
## attend… », Maya « Alors, c'est lui / elle… ») seulement après le combat du 4B
## (rival_battle_done) ; avant, Maya garde celle du 3B ; Maya s'accorde au sexe du starter.
func test_waiting_lines_during_and_after_the_choice() -> void:
	var oak := _library.get_dialogue(&"oak_lab_waiting")
	# 4B : la variante répétée « starter_chosen » du 4A est supprimée (3 variantes) ; J7 (T18) :
	# la variante du colis passe en tête (test_oak_parcel_lines).
	assert_eq(oak.variants.size(), 4)
	assert_eq(oak.variants[0].cutscene, &"oak_parcel")
	assert_eq(oak.variants[1].if_flags, [&"rival_battle_done"] as Array[StringName])
	assert_eq(_texts(oak.variants[1]), [
		"Le monde qui vous attend est bien plus vaste que Bourg Palette.",
		"Prends le temps de l'observer. Les Pokémon ont beaucoup à nous apprendre.",
	] as Array[String])
	assert_eq(oak.variants[2].if_flags, [&"starter_offered"] as Array[StringName])
	assert_eq(_texts(oak.variants[2]), ["Prends ton temps.",
		"Choisis celui avec qui tu as envie de partir."] as Array[String])
	assert_eq(_texts(oak.variants[3]),
		["Un peu de patience. J'ai quelque chose à vous montrer."] as Array[String])
	var rival := _library.get_dialogue(&"rival_lab_waiting")
	assert_eq(rival.speaker, "{rival}")
	# 4B : la variante répétée « rival_challenged » du 4A est supprimée (2 variantes).
	assert_eq(rival.variants.size(), 2)
	assert_eq(rival.variants[0].if_flags, [&"starter_offered"] as Array[StringName])
	assert_eq(_texts(rival.variants[0]), ["Tu comptes les regarder encore longtemps ?",
		"Dépêche-toi de choisir."] as Array[String])
	assert_eq(_texts(rival.variants[1]),
		["Tu vois ? Je t'avais dit que j'étais prêt."] as Array[String])
	var maya := _library.get_dialogue(&"maya")
	assert_eq(maya.variants.size(), 4)
	assert_eq(maya.variants[0].if_flags, [&"rival_battle_done", &"starter_female"]
		as Array[StringName])
	assert_eq(_texts(maya.variants[0]), ["Alors, c'est elle que tu as choisi ?",
		"Vous avez l'air de déjà bien vous entendre."] as Array[String])
	assert_eq(maya.variants[1].if_flags, [&"rival_battle_done"] as Array[StringName])
	assert_eq(_texts(maya.variants[1]), ["Alors, c'est lui que tu as choisi ?",
		"Vous avez l'air de déjà bien vous entendre."] as Array[String])
	var flags := StoryFlags.new()
	flags.set_flag(&"oak_met")
	assert_eq(oak.pick(flags), oak.variants[3], "avant l'offre : réplique du 3B")
	assert_eq(rival.pick(flags), rival.variants[1], "avant l'offre : réplique du 3B")
	assert_eq(maya.pick(flags), maya.variants[2], "réplique du 3B")
	flags.set_flag(&"starter_offered")
	assert_eq(oak.pick(flags), oak.variants[2], "pendant le choix")
	assert_eq(rival.pick(flags), rival.variants[0], "pendant le choix")
	assert_eq(maya.pick(flags), maya.variants[2])
	# L'état « starter choisi, combat pas encore fini » n'est plus atteint par le joueur : la
	# scène s'enchaîne du choix jusqu'à la fin du combat (jalon-04.md §14.8). Après le combat :
	flags.set_flag(&"starter_chosen")
	flags.set_flag(&"rival_challenged")
	flags.set_flag(&"rival_left_lab")
	flags.set_flag(&"rival_battle_done")
	flags.set_flag(&"starter_female")
	assert_eq(oak.pick(flags), oak.variants[1], "après le combat : « Le monde qui vous attend… »")
	assert_eq(maya.pick(flags), maya.variants[0], "starter femelle : « elle »")
	flags.set_flag(&"starter_female", false)
	assert_eq(maya.pick(flags), maya.variants[1], "starter mâle ou sans sexe : « lui »")


func _texts(variant: DialogueVariant) -> Array[String]:
	var texts: Array[String] = []
	for page: DialoguePage in variant.pages:
		texts.append(page.text)
	return texts


## Décision de Kevin (jalon-04.md §4.1, §13.5) : 4 répliques du Prof. Chen, mot pour mot ; il
## regarde les trois Pokémon (table à sa droite) à la 3e, puis revient vers le joueur.
func test_oak_starter_offer_four_lines_and_looks() -> void:
	var dialogue := _library.get_dialogue(&"oak_starter_offer")
	assert_eq(dialogue.speaker, "Prof. Chen")
	assert_false(dialogue.narration)
	assert_false(dialogue.draft)
	assert_eq(dialogue.variants.size(), 1)
	var pages := dialogue.variants[0].pages
	var texts: Array[String] = []
	for page: DialoguePage in pages:
		texts.append(page.text)
	assert_eq(texts, [
		"Vous voulez tous les deux découvrir Kanto.",
		"Mais découvrir ce monde seul serait une mauvaise idée.",
		"Eux aussi ont encore beaucoup à découvrir.",
		"Alors... pourquoi ne pas commencer ensemble ?",
	] as Array[String])
	assert_true(pages[0].turn.is_empty())
	assert_true(pages[1].turn.is_empty())
	assert_eq(pages[2].turn, {&"oak": &"right"} as Dictionary[StringName, StringName],
		"il regarde les trois Pokémon (table à sa droite)")
	assert_eq(pages[3].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])


func test_mom_first_variant_is_automatic_and_only_hers() -> void:
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			# Maman, et le garde du poste sud à son premier passage (jalon 9, Q-4).
			var first_of: Array[StringName] = [&"mom", &"forest_gate_south_guard"]
			assert_eq(variant.auto, first_of.has(id) and variant == \
				_library.get_dialogue(id).variants[0], "%s : auto" % id)


## Lot de textes validé par Kevin le 2026-10-06 : plus aucun dialogue ni variante provisoire.
func test_no_dialogue_nor_variant_is_draft() -> void:
	for id: StringName in _real_ids():
		var dialogue := _library.get_dialogue(id)
		assert_false(dialogue.draft, String(id))
		for i: int in dialogue.variants.size():
			assert_false(dialogue.variants[i].draft, "%s:%d" % [id, i])


## Le soin de Maman (Q22, jalon 5C) : elle soigne l'équipe, seulement après le starter.
func test_mom_heal_variant() -> void:
	var heal: DialogueVariant = _library.get_dialogue(&"mom").variants[1]
	assert_eq(heal.action, &"heal", "soigne l'équipe")
	assert_eq(heal.if_flags, [&"starter_chosen"] as Array[StringName], "après le starter")
	assert_false(heal.auto, "jamais automatique")
	assert_eq(heal.pages.size(), 2, "courte")
	# Seule cette variante soigne (le réveil après défaite soigne par la défaite, pas par le texte).
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			assert_eq(variant.action == &"heal", variant == heal, "%s : « heal »" % id)


func test_texts_are_the_dossier_02_texts_word_for_word() -> void:
	assert_true(FileAccess.file_exists(DOSSIER), DOSSIER)
	assert_true(FileAccess.file_exists(DOSSIER_07), DOSSIER_07)
	var dossier := FileAccess.get_file_as_string(DOSSIER)
	var dossier_07 := FileAccess.get_file_as_string(DOSSIER_07)
	var dossier_09 := FileAccess.get_file_as_string(DOSSIER_09)
	var dossier_11 := FileAccess.get_file_as_string(DOSSIER_11).replace("**", "")
	var valides := FileAccess.get_file_as_string(TEXTES_VALIDES)
	var dossier_10 := FileAccess.get_file_as_string(DOSSIER_10)
	var dossier_12 := FileAccess.get_file_as_string(DOSSIER_12)
	var lot_j10 := FileAccess.get_file_as_string(LOT_J10)
	var dossier_14 := FileAccess.get_file_as_string(DOSSIER_14)
	var dossier_15 := FileAccess.get_file_as_string(DOSSIER_15)
	# Formes accordées « fatigué[e] » (n° 55) : masculin et féminin.
	dossier_14 += dossier_14.replace("[e]", "") + dossier_14.replace("[e]", "e")
	# J12 (T25) : formes au masculin du héros actuel (« revenu[e] », « gamin[e] curieux[se] ») et
	# question du choix écrite par fossile (« Prendre le {fossil} ? », §20 n° 23).
	dossier_15 += dossier_15.replace("[e]", "").replace("[se]", "") \
		+ dossier_15.replace("{fossil}", "Fossile Dôme") \
		+ dossier_15.replace("{fossil}", "Fossile Nautile")
	for row: Array in _pages():
		if GATE_GUARDS.has(row[0]):
			continue
		var text: String = row[1]
		for token: String in _DOSSIER_TOKENS:
			text = text.replace(token, _DOSSIER_TOKENS[token])
		# Prologue : dossier 02 ; Route 1 (jalon 5) : dossier 07 ; Jadielle (jalon 7) : dossier 09 ;
		# anciens brouillons : lot de textes validé le 2026-10-06.
		# Route 2 (jalon 8) : dossier 11, « / » = retour à la ligne (forcé pour un panneau,
		# sinon laissé à la bulle).
		var in_dossier_11 := dossier_11.contains("| %s |" % text.replace("\n", " / ")) \
			or dossier_11.replace(" / ", " ").contains("| %s |" % text)
		assert_true(dossier.contains(text) or dossier_07.contains(text)
			or dossier_09.contains(text) or in_dossier_11 or valides.contains("« %s »" % text)
			or dossier_10.contains(_as_dossier_10(text))
			or dossier_12.contains(_as_dossier_10(text))
			or lot_j10.contains("| « %s » |" % text.replace("\n", "\\n"))
			or _each_line_quoted(dossier_14, text)
			or dossier_15.contains(" : « %s »" % text)
			# J12 (T21) : bulles suivantes (« / ») et panneaux sur deux lignes du §20.
			or _each_line_quoted(dossier_15, text)
			# J12 (T18) : une réplique du §20 coupée en deux lignes dans sa bulle (retour à la
			# ligne de mise en page) : la bulle entière est une citation du dossier.
			or dossier_15.contains("« %s »" % text.replace("\n", " ")),
			"%s : « %s » dans un dossier de conception" % [row[0], text])


## Vrai si chaque ligne de [param text] figure entre guillemets dans [param dossier] (dossier 14 :
## une réplique par numéro, « Avec Patience, ton Pokémon encaisse, » puis « puis rend… »).
func _each_line_quoted(dossier: String, text: String) -> bool:
	for line: String in text.split("\n"):
		if not dossier.contains("« %s »" % line):
			return false
	return true


func test_speakers_and_narration() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"mom": ["Maman", false], &"mom_wakeup": ["Maman", false],
		&"rival": ["{rival}", false], &"maya": ["Maya", false],
		&"aoki": ["Mme Aoki", false], &"leo": ["Léo", false], &"haru": ["Haru", false],
		&"breakfast_table": ["", true], &"rival_kanto_map": ["", true],
		&"observe_bulbasaur": ["Bulbizarre", true], &"observe_charmander": ["Salamèche", true],
		&"observe_squirtle": ["Carapuce", true], &"observe_aoki_pidgey": ["Roucool", true],
		&"observe_leo_rattata": ["Rattata", true], &"sign_pallet_town": ["", false],
		&"oak_route1_call": ["???", false], &"route1_grass_thought": ["", true],
		&"oak_route1_warning": ["Prof. Chen", false], &"oak_lab_reunion": ["", false],
		&"oak_lab_waiting": ["Prof. Chen", false], &"rival_lab_waiting": ["{rival}", false],
		&"oak_starter_offer": ["Prof. Chen", false],
		&"oak_starter_reciprocal": ["Prof. Chen", false], &"rival_starter_pick": ["{rival}", false],
		&"rival_starter_smile": ["{rival}", false],
		&"rival_challenge_wait": ["{rival}", false], &"rival_challenge": ["{rival}", false],
		&"oak_lab_exit_block": ["Prof. Chen", false],
		&"rival_lab_won": ["{rival}", false], &"rival_lab_won_leaving": ["{rival}", false],
		&"rival_lab_lost": ["{rival}", false], &"oak_after_battle": ["Prof. Chen", false],
		&"oak_poke_balls_intro": ["Prof. Chen", false], &"oak_poke_balls": ["Prof. Chen", false],
		&"viridian_courier": ["Livreur", false], &"viridian_lass": ["Dresseuse", false],
		&"viridian_kid": ["Enfant", false], &"viridian_traveler": ["Voyageur", false],
		&"viridian_old_man": ["Vieil homme", false],
		&"viridian_gym_watcher": ["Habitant", false], &"viridian_gym_door": ["", true],
		&"viridian_house_door": ["", true],
		&"oak_parcel_records": ["Prof. Chen", false],
		&"oak_pokedex_activated": ["Prof. Chen", false], &"oak_parcel_rival": ["", false],
		&"oak_parcel_rival_dex": ["Prof. Chen", false],
		&"rival_parcel_return": ["{rival}", false], &"rival_parcel_greet": ["{rival}", false],
		&"rival_parcel_leaving": ["{rival}", false],
		&"nurse": ["Infirmière", false], &"nurse_wakeup": ["Infirmière", false],
		&"route22_youngster_sigh": ["Jeune Dresseur", false],
		&"route22_rival_hesitates": ["{rival}", false], &"route22_rival_greet": ["{rival}", false],
		&"route22_rival_won": ["{rival}", false], &"route22_rival_lost": ["{rival}", false],
		# Jalon 8 (dossier 11, T16) : panneaux sans locuteur, comme celui de Bourg Palette.
		&"route_2_sign": ["", false], &"route_2_forest_sign": ["", false],
		&"route_2_closed_sign": ["", false], &"route_2_hiker": ["Randonneuse", false],
		&"route_2_youngster": ["Jeune Dresseur", false], &"route_2_dense_tree": ["", true],
		&"route_2_closed_gate": ["", true], &"route_2_item_3_found": ["", true],
		&"route_2_item_4_found": ["", true],
		# Jalon 12 (T21) : panneau sans locuteur, examens du camp en narration.
		&"mt_moon_1f_sign": ["", false], &"mt_moon_1f_crate": ["", true],
		&"mt_moon_1f_lamp": ["", true], &"mt_moon_1f_hiker": ["Randonneur", false],
		# Jalon 12 (T18) : panneaux de la Route 3 sans locuteur.
		&"route_3_sign_west": ["", false], &"route_3_sign_center": ["", false],
		&"route_3_traveler": ["Voyageur", false], &"route_3_hiker": ["Randonneuse", false],
		# Jalon 12 (T25) : Sbires (§20 n° 19), chercheur, question du fossile en narration.
		&"mt_moon_rocket_1_before": ["Sbire Rocket", false],
		&"mt_moon_rocket_2_before": ["Sbire Rocket", false],
		&"mt_moon_rocket_3_before": ["Sbire Rocket", false],
		&"mt_moon_researcher_before": ["Chercheur Gaspard", false],
		&"mt_moon_researcher_talk": ["Chercheur Gaspard", false],
		&"mt_moon_fossil_dome": ["", true], &"mt_moon_fossil_helix": ["", true],
	}
	for id: StringName in expected:
		var dialogue := _library.get_dialogue(id)
		assert_eq(dialogue.speaker, expected[id][0], "%s : locuteur" % id)
		assert_eq(dialogue.narration, expected[id][1], "%s : narration" % id)


func test_every_page_fits_in_three_lines_of_the_real_box() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	viewport.add_child(box)
	box.open()
	var label := box.get_node(^"%Text") as Label
	for row: Array in _pages():
		var dialogue := _library.get_dialogue(row[0])
		box.show_page(dialogue.speaker, row[1], dialogue.narration)
		box.set_visible_characters(-1)
		await wait_process_frames(1)
		assert_lte(label.get_line_count(), UiTokens.DIALOG_MAX_LINES,
			"%s : « %s » en %d lignes" % [row[0], row[1], label.get_line_count()])
		assert_eq(box.get_panel().size.x, float(UiTokens.DIALOG_BOX_WIDTH))


## Décisions de Kevin 6, 7 et 9 : Maya a une variante « oak_met » placée avant celle de 3A
## (après les deux de l'après-combat, décision n° 16) ; au labo, quatre répliques avec « Rival » et « Prof. Chen »
## page par page.
func test_maya_after_oak_returns_and_the_lab_reunion() -> void:
	var maya := _library.get_dialogue(&"maya")
	assert_eq(maya.variants.size(), 4)
	assert_eq(maya.variants[2].if_flags, [&"oak_met"] as Array[StringName], "avant celle de 3A")
	assert_eq(_texts(maya.variants[2]), ["Ah, le professeur est revenu.",
		"Et à voir son air, j'imagine qu'il a encore quelque chose en tête."] as Array[String])
	assert_eq(maya.variants[3].pages[0].text, "Bonjour ! Tu cherches le professeur Chen ?",
		"réplique de 3A inchangée")
	var flags := StoryFlags.new()
	assert_eq(maya.pick(flags), maya.variants[3])
	flags.set_flag(&"oak_met")
	assert_eq(maya.pick(flags), maya.variants[2])
	var reunion := _library.get_dialogue(&"oak_lab_reunion").variants[0].pages
	var lines: Array = []
	for page: DialoguePage in reunion:
		lines.append([page.speaker, page.text])
	assert_eq(lines, [
		["{rival}", "Enfin."],
		["Prof. Chen", "Un peu de patience."],
		["{rival}", "Ça fait une heure que tu dis ça."],
		["Prof. Chen", "Et pourtant, tu es toujours là."],
	])
	assert_eq(reunion[1].turn, {&"oak": &"rival"} as Dictionary[StringName, StringName])
	assert_eq(reunion[2].turn, {&"rival": &"oak"} as Dictionary[StringName, StringName])


## Jalon 7 (T18, dossier 09 §6, §19) : parler à Chen avec le colis lance la scène (variante sans
## page, en tête) ; jamais après l'activation. Répliques de la scène dans l'ordre du §19, la
## réplique de l'espèce porte le jeton, « Observe. Explore. » garde sa phrase.
func test_oak_parcel_lines() -> void:
	var oak := _library.get_dialogue(&"oak_lab_waiting")
	var first := oak.variants[0]
	assert_eq(first.if_flags, [&"got_oak_parcel"] as Array[StringName])
	assert_eq(first.unless_flags, [StoryFlags.POKEDEX_ACTIVATED] as Array[StringName])
	assert_eq(first.cutscene, &"oak_parcel")
	assert_true(first.pages.is_empty(), "la scène porte toutes les répliques")
	var flags := StoryFlags.new()
	for flag: StringName in [&"rival_battle_done", &"got_oak_parcel"]:
		flags.set_flag(flag)
	assert_same(oak.pick(flags), first)
	flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_eq(oak.pick(flags).cutscene, &"", "après l'activation : Chen parle normalement")
	assert_eq(_used_on.get(&"oak_parcel_records"), [&"oak_lab"], "joué au labo")
	var records := _library.get_dialogue(&"oak_parcel_records").variants[0].pages
	var texts: Array[String] = []
	for page: DialoguePage in records:
		texts.append(page.text)
	assert_eq(texts, ["Tiens…", "Il a déjà commencé à enregistrer tes rencontres.",
		"Un {first_wild_species}… Tu n'as pas perdu de temps.",
		"J'étudie depuis longtemps la manière dont les Pokémon vivent à travers Kanto.",
		"Mais aucune recherche ne remplacera ce qu'un Dresseur découvre sur le terrain.",
		"Ton voyage peut nous apprendre beaucoup."] as Array[String])
	var activated := _library.get_dialogue(&"oak_pokedex_activated").variants[0].pages
	assert_eq(activated.back().text, "Observe. Explore. Fais-toi ta propre idée du monde.")
	var rival := _library.get_dialogue(&"oak_parcel_rival").variants[0].pages
	assert_eq([rival[0].speaker, rival[1].speaker], ["Prof. Chen", "{rival}"])
	assert_gt(rival[1].pause, 0.0, "« …On verra. » après une courte pause")
	# Toute scène lancée par un dialogue existe.
	var launched := 0
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				launched += 1
				assert_true(_cutscenes.has_cutscene(variant.cutscene), "%s : scène « %s »" % [
					id, variant.cutscene])
	# La scène du colis ; jalon 8 : les deux objets visibles de la Route 2 (PRENDRE) ; jalon 9 :
	# les trois de la Forêt de Jade ; jalon 10 : la Potion de la Route 2 nord et Pierre.
	# Jalon 11 : la remise tardive de la CT34 par Pierre. Jalon 12 (T21) : la Corde Sortie et
	# la Potion au sol du Mont Sélénite, le Réveil caché (examen de l'indice). Jalon 12 (T18) :
	# les trois objets au sol de la Route 3 et son objet caché. Jalon 12 (T25) : la Pierre Lune
	# (B1F) et la CT01 (B2F) au sol, la Pierre Lune cachée (B2F).
	assert_eq(launched, 19,
		"la scène du colis, treize objets au sol, trois cachés, Pierre et sa CT34")
	# Le jeton n'apparaît que dans la réplique de l'espèce (et « {pokemon} » dans les phrases du
	# compagnon, J11).
	for row: Array in _pages():
		var tokens := DialogueTokens.tokens_in(row[1])
		var expected: Array[StringName] = []
		if row[1] == records[2].text:
			expected = [DialogueTokens.FIRST_WILD_SPECIES]
		elif PLAYED_BY_COMPANION.has(row[0]):
			expected = [DialogueTokens.POKEMON]
		assert_eq(tokens, expected, "%s : jeton" % row[0])



## Forme d'une réplique dans le dossier 10 : « ligne » ou « ligne 1 » / « ligne 2 ».
static func _as_dossier_10(text: String) -> String:
	var quoted := PackedStringArray()
	for line: String in text.split("\n"):
		quoted.append("« %s »" % line)
	return " / ".join(quoted)


## Jalon 9 (T11) : une réplique avant et une après par Dresseur de la forêt, une page chacune,
## locuteur = nom du Dresseur (data/trainers/), mot pour mot (dont « Enfin... presque. »).
func test_forest_trainer_lines() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	var expected: Dictionary[StringName, Array] = {
		&"forest_scout_theo": ["Hé ! Toi aussi, tu cherches\ndes Pokémon dans la forêt ?",
			"Ton Pokémon est bien entraîné.\nJe dois encore progresser."],
		&"forest_scout_noe": ["Mes Pokémon ont grandi ici.\nTu veux les affronter ?",
			"Ils deviennent plus forts\nchaque jour."],
		&"forest_youngster_tom": ["Je connais cette forêt par cœur !\nEnfin... presque.",
			"D'accord. Peut-être pas par cœur."],
		&"forest_scout_milo": ["Les Pokémon Insecte évoluent vite.\nRegarde ça !",
			"Pas encore assez vite, apparemment."],
		&"forest_scout_eli": ["Tu as traversé toute la forêt ?\nAlors montre-moi ton équipe !",
			"Pas mal !\nArgenta n'est plus très loin."],
	}
	var dossier_10 := FileAccess.get_file_as_string(DOSSIER_10)
	for trainer_id: StringName in expected:
		var trainer := trainers.get_trainer(trainer_id)
		assert_not_null(trainer, String(trainer_id))
		var suffixes: Array[String] = ["_before", "_after"]
		for i: int in suffixes.size():
			var id := StringName(String(trainer_id) + suffixes[i])
			var dialogue := _library.get_dialogue(id)
			assert_not_null(dialogue, String(id))
			if dialogue == null or trainer == null:
				continue
			assert_eq(dialogue.speaker, trainer.name, "%s : locuteur" % id)
			assert_false(dialogue.narration)
			assert_eq(dialogue.variants.size(), 1, String(id))
			var pages := dialogue.variants[0].pages
			assert_eq(pages.size(), 1, "%s : une page" % id)
			assert_eq(pages[0].text, expected[trainer_id][i], String(id))
			assert_string_contains(dossier_10, _as_dossier_10(pages[0].text))


## Jalon 9 (T6) : les deux gardes, mot pour mot du dossier 10 (« Textes verrouillés »), nom
## affiché « Garde » (lot de textes n° 55), une page de deux lignes par réplique.
func test_forest_gate_guards_say_the_locked_lines() -> void:
	var dossier := FileAccess.get_file_as_string(DOSSIER_10)
	var south := _library.get_dialogue(&"forest_gate_south_guard")
	var north := _library.get_dialogue(&"forest_gate_north_guard")
	assert_eq([south.speaker, north.speaker], ["Garde", "Garde"])
	assert_eq(south.variants.size(), 2)
	assert_eq(north.variants.size(), 2)
	var pages: Array[String] = []
	for dialogue: Dialogue in [south, north]:
		for variant: DialogueVariant in dialogue.variants:
			assert_eq(variant.pages.size(), 1, "une réplique = une page")
			pages.append(variant.pages[0].text)
	assert_eq(pages.size(), 4)
	for text: String in pages:
		var lines := text.split("\n")
		assert_eq(lines.size(), 2, "bulle de 2 lignes : %s" % text)
		assert_true(dossier.contains("« %s » / « %s »" % [lines[0], lines[1]]),
			"« %s » dans le dossier 10" % text)
	assert_eq(pages[0], "La Forêt de Jade est juste devant.\nGarde un Antidote avec toi.")
	assert_eq(pages[1], "Les Aspicot peuvent empoisonner.\nLa Boutique de Jadielle vend des Antidotes.")
	# Garde du sud : première conversation = avertissement + `poison_unlocked`, automatique,
	# une seule fois ; ensuite PNJ ordinaire (rappel, pas de drapeau).
	var first: DialogueVariant = south.variants[0]
	assert_true(first.auto)
	assert_eq(first.unless_flags, [&"poison_unlocked"] as Array[StringName])
	assert_eq(first.set_flags, [&"poison_unlocked"] as Array[StringName])
	assert_false(south.variants[1].auto)
	assert_true(south.variants[1].set_flags.is_empty())
	# Garde du nord : la variante d'Argenta attend le drapeau du J10.
	assert_eq(north.variants[0].if_flags, [&"pewter_arrived"] as Array[StringName])


## Jalon 11 (T20c) : chaque phrase que le compagnon peut choisir existe (et sa forme féminine),
## en narration (style « observer »), sans locuteur.
func test_companion_lines_exist_as_narration() -> void:
	var lines: Array[StringName] = [CompanionRules.LINE_TIRED, CompanionRules.LINE_UNWELL,
		CompanionRules.LINE_WATER]
	lines.append_array(CompanionRules.CONTEXT_LINES.values())
	lines.append_array(CompanionRules.GENERIC_LINES)
	for line: StringName in CompanionController.FEMININE_LINES:
		lines.append(StringName(String(line) + CompanionController.FEMININE_SUFFIX))
	for line: StringName in lines:
		assert_true(PLAYED_BY_COMPANION.has(line), "%s : listée" % line)
		var dialogue := _library.get_dialogue(line)
		assert_not_null(dialogue, "%s : définie" % line)
		if dialogue != null:
			assert_eq(dialogue.speaker, "", "%s : sans locuteur" % line)
			assert_true(dialogue.narration, "%s : narration" % line)
			assert_true(dialogue.variants[0].pages[0].text.begins_with("{pokemon} "), line)
	assert_eq(lines.size(), PLAYED_BY_COMPANION.size())


## Dialogues sans ceux de la carte de QA (`qa_*`, jalon 13 T14, retirés au T22).
func _real_ids() -> Array[StringName]:
	return _without_qa(_library.get_ids())


func _without_qa(ids: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in ids:
		if not MapCatalog.is_qa_map(id):
			result.append(id)
	return result
