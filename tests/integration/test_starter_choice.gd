extends GutTest
## StarterChoice (jalon-04.md §3.5, §13.3, T3) sur un mini-labo (PNJ de
## tests/fixtures/npcs/starter_lab.json : trois starters sur une table en (10..12, 4..5),
## Chen, le rival), avec les vraies données Pokémon, une offre d'essai (mêmes espèces que
## data/pokemon/starters.json, carte « starter_lab »), un vrai joueur, un vrai
## CutsceneDirector, un vrai DialogueRunner (texte instantané), la vraie DialogueBox, la vraie
## StarterSheet, la vraie ExplorationHud, un vrai InteractionController et un GameState neuf
## (graine fixe). Scène du choix d'essai en mémoire : le starter descend à côté du joueur
## (qui ne bouge pas), « réciproque », done_flag, le Pokémon du rival le rejoint,
## rival_challenged.
## - ouverture : rien sans open_flag ; open_flag pendant une scène → légende et MEET après
##   sa fin ; hors scène → tout de suite ;
## - RENCONTRER : joueur bloqué (starter_choice), Pokémon qui s'avance, fiche avec la vue
##   (nom, types, phrase), contrôles de la HUD à cacher (is_sheet_open) ;
## - RETOUR : fiche fermée, Pokémon revenu, joueur libre, MEET toujours là ;
## - CHOISIR : taken_* des deux, surcharges retirées, scène avec les bons alias, joueur jamais
##   libre entre la fiche et la scène ; **équipe vide jusqu'à la réplique de Chen**, puis 1
##   Pokémon (espèce, niveau 5, PV pleins, 2 capacités), starter_species, signal ;
## - scène refusée : erreur, done_flag levé par le code, Pokémon dans l'équipe ;
## - sortie et retour au labo avant le choix : MEET reposé, légende réaffichée.

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const BOX_SCENE := preload("res://game/ui/dialogue/dialogue_box.tscn")
const SHEET_SCENE := preload("res://game/ui/starter/starter_sheet.tscn")
const HUD_SCENE := preload("res://game/ui/hud/exploration_hud.tscn")
const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")
const NPCS := "res://tests/fixtures/npcs/"
const MAP_ID := &"starter_lab"
const SEED := 42
const TIMEOUT := 5.0
const RECIPROCAL := "On dirait que le choix est réciproque."
const OFFER := {
	"map": "starter_lab", "level": 5, "prompt": "CHOISIS TON PREMIER PARTENAIRE",
	"choices": [
		{"species": "bulbasaur", "npc": "bulbasaur", "blurb": "Calme et tenace."},
		{"species": "charmander", "npc": "charmander", "blurb": "Fougueux et courageux."},
		{"species": "squirtle", "npc": "squirtle", "blurb": "Vif et malicieux."},
	],
	"open_flag": "starter_offered", "done_flag": "starter_chosen",
	"chosen_scene": "choice", "female_flag": "starter_female",
}
const DIALOGUES := {
	"observe": {"narration": true, "pages": ["Il t'observe."]},
	"reciprocal": {"speaker": "Prof. Chen", "pages": [RECIPROCAL]},
	"pick": {"speaker": "Rival", "pages": ["Alors ce sera toi."]},
}
const SCENES := {
	"offer": {"steps": [{"wait": 0.1}, {"set": ["starter_offered"]}, {"wait": 0.2}]},
	"choice": {"unless": ["rival_challenged"], "steps": [
		{"hop": "$player_starter",
			"to": {"near": "player", "offsets": [[1, 0], [-1, 0], [1, 1], [-1, 1]]}},
		{"face": "player", "to": "$player_starter"},
		{"dialogue": "reciprocal"},
		{"set": ["starter_chosen"]},
		{"hop": "$rival_starter", "to": {"near": "rival", "offsets": [[1, 0], [0, 1], [-1, 0]]}},
		{"dialogue": "pick"},
		{"set": ["rival_challenged"]},
	]},
}
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]

var _world: Node2D
var _map: GameMap
var _player: Player
var _box: DialogueBox
var _runner: DialogueRunner
var _director: CutsceneDirector
var _interactions: InteractionController
var _sheet: StarterSheet
var _hud: ExplorationHud
var _state: Node
var _data: PokemonData
var _offer: StarterOffer
var _choice: StarterChoice


func before_each() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_offer = StarterOffer.new()
	assert_true(_offer.add_from_dict(OFFER, "test"))
	var dialogues := DialogueLibrary.new()
	dialogues.add_from_dict(DIALOGUES, "test")
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_state = STATE_SCRIPT.new()
	autofree(_state)
	_state.call(&"new_game", SEED)
	_world = Node2D.new()
	add_child_autofree(_world)
	_player = PLAYER_SCENE.instantiate() as Player
	_world.add_child(_player)
	_box = BOX_SCENE.instantiate() as DialogueBox
	add_child_autofree(_box)
	_hud = HUD_SCENE.instantiate() as ExplorationHud
	add_child_autofree(_hud)
	_sheet = SHEET_SCENE.instantiate() as StarterSheet
	add_child_autofree(_sheet)
	_runner = DialogueRunner.new()
	_runner.chars_per_second = 0.0
	add_child_autofree(_runner)
	_runner.setup(dialogues, _flags(), _box, _player)
	_interactions = InteractionController.new()
	add_child_autofree(_interactions)
	_interactions.setup(_player, _runner)
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags(), _runner, _player, null)
	_choice = StarterChoice.new()
	add_child_autofree(_choice)
	_choice.setup(_offer, _data, _state, _player, _sheet, _hud, _director, _interactions)
	_map = _make_map()
	_enter(_map, Vector2i(11, 6))
	watch_signals(_choice)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"run", &"interact"]:
		Input.action_release(action)


func _flags() -> StoryFlags:
	return _state.get(&"flags") as StoryFlags


func _party() -> Party:
	return _state.get(&"party") as Party


## Mini-labo 16 × 11 sans tuiles : table (10..12, 4..5) solide, PNJ du fixture.
func _make_map(map_id: StringName = MAP_ID) -> GameMap:
	var map := GameMap.new()
	map.name = "StarterLab"
	map.map_id = map_id
	map.npcs_dir = NPCS
	map.size = Vector2i(16, 11)
	var blocked: Array[Vector2i] = []
	for y: int in range(4, 6):
		for x: int in range(10, 13):
			blocked.append(Vector2i(x, y))
	map.blocked_cells = blocked
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	return map


## Pose [param map] comme carte courante (comme Boot sur map_changed), joueur en
## [param cell] tourné vers le haut.
func _enter(map: GameMap, cell: Vector2i) -> void:
	_world.add_child(map)
	map.refresh_npcs(_flags())
	_player.enter_map(map.get_grid(), cell, Vector2i.UP, map.get_pixel_rect())
	_interactions.set_map(map)
	_director.set_map(map)
	_choice.set_map(map)
	_choice.on_map_entered(map)


func _open() -> void:
	_flags().set_flag(&"starter_offered")


func _meet(species: StringName) -> Npc:
	var npc := _map.get_npc(species)
	_interactions.meet_requested.emit(npc)
	return npc


func _starter_overrides() -> Array[bool]:
	var result: Array[bool] = []
	for id: StringName in STARTERS:
		var npc := _map.get_npc(id)
		result.append(npc != null and npc.has_interaction_override()
			and npc.get_interaction().kind == Interaction.Kind.MEET)
	return result


## Avance les dialogues de la scène jusqu'à sa fin ; renvoie [taille de l'équipe à chaque
## page] et les pages vues.
func _play_scene_to_end() -> Array:
	var sizes: Array[Array] = []
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _director.is_running() and Time.get_ticks_msec() < deadline:
		assert_false(_player.is_input_enabled(), "joueur bloqué pendant la scène")
		await wait_process_frames(1)
		if _box.is_open():
			var row := [_box.get_text(), _party().size()]
			if sizes.is_empty() or sizes.back() != row:
				sizes.append(row)
			_box.advance_requested.emit()
	assert_false(_director.is_running(), "scène terminée")
	return sizes


# --- Ouverture ---------------------------------------------------------------------------

func test_nothing_without_the_open_flag() -> void:
	assert_false(_choice.is_open())
	assert_eq(_starter_overrides(), [false, false, false] as Array[bool])
	assert_false(_hud.get_caption().is_showing())
	_meet(&"charmander")
	assert_false(_sheet.is_open(), "pas de fiche sans offre")
	assert_true(_player.is_input_enabled())


func test_open_flag_during_a_cutscene_opens_after_its_end() -> void:
	assert_true(_director.play(&"offer"))
	await wait_until(func() -> bool: return _flags().has_flag(&"starter_offered"), TIMEOUT)
	assert_true(_director.is_running())
	assert_eq(_starter_overrides(), [false, false, false] as Array[bool], "pas pendant la scène")
	assert_false(_hud.get_caption().is_showing())
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)
	assert_true(_choice.is_open())
	assert_eq(_starter_overrides(), [true, true, true] as Array[bool])
	assert_true(_hud.get_caption().is_showing(), "légende")
	assert_eq(_hud.get_caption().text, "CHOISIS TON PREMIER PARTENAIRE")


func test_open_flag_outside_a_cutscene_opens_at_once() -> void:
	_open()
	assert_true(_choice.is_open())
	assert_eq(_starter_overrides(), [true, true, true] as Array[bool])
	assert_true(_hud.get_caption().is_showing())
	# La cible devant le joueur (11, 6) est la surcharge MEET de Salamèche.
	var target := InteractionFinder.find(_map.get_grid(), _map.get_interactions(),
		_player.get_cell(), Vector2i.UP)
	assert_not_null(target)
	if target != null:
		assert_eq(target.kind, Interaction.Kind.MEET)
		assert_eq(target.source, _map.get_npc(&"charmander"))


# --- Rencontrer, RETOUR ------------------------------------------------------------------

func test_meet_blocks_the_player_leans_and_opens_the_sheet() -> void:
	_open()
	var npc := _meet(&"charmander")
	assert_true(_player.is_blocked_by(StarterChoice.REASON), "bloqué dans l'appel")
	assert_true(_choice.is_sheet_open())
	assert_true(_sheet.is_open())
	assert_signal_emit_count(_choice, "sheet_opened", 1)
	assert_eq(_sheet.get_name_text(), "SALAMÈCHE")
	assert_eq(_sheet.get_phrase_label().text, "Fougueux et courageux.")
	var badges := _sheet.get_badges()
	assert_eq(badges.size(), 1)
	await wait_seconds(Npc.LEAN_DURATION + 0.1)
	assert_eq(npc.get_lean_offset(), Vector2(0.0, Npc.LEAN_DISTANCE), "il s'avance vers le bas")
	assert_eq(npc.get_cell(), Vector2i(11, 5), "sans changer de case")
	# Un second appui ne rouvre rien.
	_meet(&"bulbasaur")
	assert_signal_emit_count(_choice, "sheet_opened", 1)
	assert_eq(_sheet.get_name_text(), "SALAMÈCHE")


func test_view_of_each_starter() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"bulbasaur": ["Bulbizarre", [&"grass", &"poison"], ["Plante", "Poison"],
			"Calme et tenace."],
		&"charmander": ["Salamèche", [&"fire"], ["Feu"], "Fougueux et courageux."],
		&"squirtle": ["Carapuce", [&"water"], ["Eau"], "Vif et malicieux."],
	}
	for species: StringName in expected:
		var view := StarterChoice.make_view(_offer.get_choice(species), _data)
		assert_not_null(view)
		if view == null:
			continue
		assert_true(view.is_valid())
		assert_eq(view.display_name, expected[species][0])
		assert_eq(Array(view.type_ids), expected[species][1])
		assert_eq(Array(view.type_names), expected[species][2])
		assert_eq(view.phrase, expected[species][3])


func test_back_closes_settles_and_frees_the_player() -> void:
	_open()
	var npc := _meet(&"squirtle")
	await wait_seconds(Npc.LEAN_DURATION + 0.1)
	_sheet.back_pressed.emit()
	assert_false(_choice.is_sheet_open())
	assert_false(_sheet.is_open())
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_signal_emit_count(_choice, "sheet_closed", 1)
	await wait_seconds(Npc.LEAN_DURATION + 0.1)
	assert_eq(npc.get_lean_offset(), Vector2.ZERO, "revenu")
	assert_true(_choice.is_open(), "choix toujours ouvert")
	assert_eq(_starter_overrides(), [true, true, true] as Array[bool])
	assert_eq(_party().size(), 0)
	assert_false(_flags().has_flag(&"taken_squirtle"))


# --- CHOISIR -----------------------------------------------------------------------------

func test_choose_plays_the_scene_and_joins_the_party_after_the_reciprocal_line() -> void:
	_open()
	var never_free := [true]
	var check := func(_id: StringName) -> void:
		never_free[0] = never_free[0] and _player.is_blocked_by(StarterChoice.REASON) \
			and _player.is_blocked_by(CutsceneDirector.REASON)
	_director.cutscene_started.connect(check)
	_meet(&"charmander")
	_sheet.choose_pressed.emit()
	assert_true(never_free[0], "bloqué par la fiche ET la scène au lancement")
	assert_true(_director.is_running(), "scène lancée")
	assert_eq(_director.get_cutscene_id(), &"choice")
	assert_false(_player.is_input_enabled(), "jamais libre entre la fiche et la scène")
	assert_false(_player.is_blocked_by(StarterChoice.REASON), "blocage de la fiche rendu")
	assert_false(_choice.is_sheet_open())
	assert_false(_sheet.is_open())
	assert_signal_emit_count(_choice, "sheet_closed", 1)
	assert_true(_flags().has_flag(&"taken_charmander"))
	assert_true(_flags().has_flag(&"taken_squirtle"), "le rival prend Carapuce")
	assert_false(_flags().has_flag(&"taken_bulbasaur"))
	assert_eq(_starter_overrides(), [false, false, false] as Array[bool], "surcharges retirées")
	assert_false(_choice.is_open())
	assert_eq(_choice.get_pending_species(), &"charmander")
	assert_eq(_party().size(), 0, "pas encore dans l'équipe")
	var pages := await _play_scene_to_end()
	assert_eq(pages, [[RECIPROCAL, 0], ["Alors ce sera toi.", 1]],
		"équipe vide jusqu'à « réciproque », 1 Pokémon ensuite")
	# Alias : le Pokémon du joueur est descendu à côté du joueur (qui n'a pas bougé), celui du
	# rival à côté du rival.
	assert_eq(_player.get_cell(), Vector2i(11, 6))
	assert_eq(_map.get_npc(&"charmander").get_cell(), Vector2i(12, 6))
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "le joueur regarde son Pokémon")
	assert_eq(_map.get_npc(&"charmander").get_lift(), 0.0)
	assert_eq(_map.get_npc(&"squirtle").get_cell(), Vector2i(10, 6))
	assert_eq(_map.get_npc(&"bulbasaur").get_cell(), Vector2i(10, 5), "resté sur la table")
	assert_eq(_party().size(), 1)
	var pokemon := _party().get_lead()
	assert_eq(pokemon.species_id, &"charmander")
	assert_eq(pokemon.level, 5)
	assert_eq(pokemon.hp, pokemon.max_hp(), "PV pleins")
	assert_gt(pokemon.hp, 0)
	assert_eq(pokemon.moves.size(), 2)
	assert_eq(_state.get(&"starter_species"), &"charmander")
	assert_signal_emitted_with_parameters(_choice, "starter_chosen", [&"charmander", &"squirtle"])
	assert_true(_flags().has_flag(&"rival_challenged"))
	assert_true(_player.is_input_enabled(), "joueur libre à la fin")


func test_same_seed_same_starter() -> void:
	_open()
	_meet(&"bulbasaur")
	_sheet.choose_pressed.emit()
	await _play_scene_to_end()
	var first := _party().get_lead().to_dict()
	var twin := PokemonFactory.create(_data, &"bulbasaur", 5, GameRng.new(SEED))
	assert_eq(first, twin.to_dict(), "graine fixe → même Pokémon")


func test_rival_takes_the_advantaged_starter() -> void:
	var expected: Dictionary[StringName, StringName] = {
		&"bulbasaur": &"charmander", &"charmander": &"squirtle", &"squirtle": &"bulbasaur",
	}
	for species: StringName in expected:
		assert_eq(_offer.rival_pick(species, _data), expected[species])
	assert_eq(StarterChoice.get_set_flags(_offer), [&"taken_bulbasaur", &"taken_charmander",
		&"taken_squirtle", &"starter_female"] as Array[StringName])


## Première graine (0..999) dont le Salamèche de niveau 5 est du sexe [param gender].
func _seed_for(gender: Pokemon.Gender) -> int:
	for candidate: int in 1000:
		if PokemonFactory.create(_data, &"charmander", 5, GameRng.new(candidate)).gender \
				== gender:
			return candidate
	return -1


## Décision n° 16 : l'accord « lui / elle » des dialogues suit le sexe du starter (modèle
## Pokémon) : female_flag levé en même temps que l'entrée dans l'équipe, seulement pour une
## femelle.
func test_female_starter_raises_the_female_flag() -> void:
	var seed_value := _seed_for(Pokemon.Gender.FEMALE)
	assert_gte(seed_value, 0, "une graine donne une femelle")
	_state.call(&"new_game", seed_value)
	_open()
	_meet(&"charmander")
	_sheet.choose_pressed.emit()
	assert_false(_flags().has_flag(&"starter_female"), "pas avant l'entrée dans l'équipe")
	await _play_scene_to_end()
	assert_eq(_party().get_lead().gender, Pokemon.Gender.FEMALE)
	assert_true(_flags().has_flag(&"starter_female"))


func test_male_starter_leaves_the_female_flag_down() -> void:
	var seed_value := _seed_for(Pokemon.Gender.MALE)
	assert_gte(seed_value, 0, "une graine donne un mâle")
	_state.call(&"new_game", seed_value)
	_open()
	_meet(&"charmander")
	_sheet.choose_pressed.emit()
	await _play_scene_to_end()
	assert_eq(_party().get_lead().gender, Pokemon.Gender.MALE)
	assert_false(_flags().has_flag(&"starter_female"))


func test_refused_scene_still_gives_the_pokemon() -> void:
	var broken: Dictionary = OFFER.duplicate(true)
	broken["chosen_scene"] = "missing"
	var offer := StarterOffer.new()
	assert_true(offer.add_from_dict(broken, "test"))
	_choice.setup(offer, _data, _state, _player, _sheet, _hud, _director, _interactions)
	_choice.set_map(_map)
	_open()
	_meet(&"squirtle")
	_sheet.choose_pressed.emit()
	assert_push_error("scène inconnue")
	assert_push_error("refusée")
	assert_eq(_party().size(), 1, "le Pokémon n'est jamais perdu")
	assert_true(_flags().has_flag(&"starter_chosen"))
	assert_eq(_state.get(&"starter_species"), &"squirtle")
	assert_true(_player.is_input_enabled())


func test_done_flag_without_a_pending_choice_adds_nothing() -> void:
	_open()
	_flags().set_flag(&"starter_chosen")
	assert_eq(_party().size(), 0)
	assert_false(_choice.is_open())
	assert_signal_not_emitted(_choice, "starter_chosen")


# --- Sortie et retour --------------------------------------------------------------------

func test_leaving_and_coming_back_before_choosing_puts_meet_back() -> void:
	_open()
	_meet(&"charmander")
	_sheet.back_pressed.emit()
	# Départ : une autre carte, puis un labo neuf (les PNJ sont recréés, sans surcharge).
	_map.queue_free()
	var outside := _make_map(&"outside")
	_enter(outside, Vector2i(3, 8))
	assert_true(_choice.is_open())
	_hud.hide_caption()
	await wait_seconds(0.3)
	outside.queue_free()
	_map = _make_map()
	_enter(_map, Vector2i(7, 8))
	assert_eq(_starter_overrides(), [true, true, true] as Array[bool], "MEET reposé")
	assert_true(_hud.get_caption().is_showing(), "légende réaffichée")
	_meet(&"bulbasaur")
	assert_true(_sheet.is_open())
	assert_eq(_sheet.get_name_text(), "BULBIZARRE")
	# La pastille de la fiche précédente est libérée à la fin de l'image (queue_free).
	await wait_process_frames(2)
