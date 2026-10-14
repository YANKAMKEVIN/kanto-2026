extends GutTest
## Étape de scène « moment » (jalon 12, T23 ; `jalon-12.md` §2.13) : lue par [CutsceneLibrary]
## (type de [MomentLibrary], sauf l'arrivée dans une zone ; « details » { clé: texte }), jouée par
## le [CutsceneDirector] : Grand moment enregistré sur la carte courante **une seule fois par type
## et par détails** (rejouer n'en ajoute pas ; un autre fossile, si) ; sans état de la partie,
## étape sautée (push_error) et la scène continue. Noms figés : `CutsceneStep.Kind.MOMENT` après
## `BADGE`, clé « moment ».

const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")
const TIMEOUT := 5.0
const SCENES := {
	"dome": {"steps": [
		{"set": ["before"]},
		{"moment": "fossil", "details": {"item": "dome_fossil"}},
		{"set": ["after"]},
	]},
	"helix": {"steps": [{"moment": "fossil", "details": {"item": "helix_fossil"}}]},
	"bare": {"steps": [{"moment": "fossil"}]},
}

var _director: CutsceneDirector
var _flags: StoryFlags
var _state: Node


func before_each() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_flags = StoryFlags.new()
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, null, null, null)
	_state = STATE_SCRIPT.new()
	autofree(_state)
	var map := GameMap.new()
	map.map_id = &"mt_moon_b2f"
	autofree(map)
	_director.set_map(map)


func _play(id: StringName) -> void:
	assert_true(_director.play(id), String(id))
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)


func _fossil_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in _state.moments:
		if moment.get("type") == String(MomentLibrary.FOSSIL):
			found.append(moment)
	return found


func test_frozen_names() -> void:
	assert_eq(CutsceneStep.Kind.MOMENT, CutsceneStep.Kind.BADGE + 1, "après BADGE")
	assert_eq(CutsceneStep.TYPE_KEYS[CutsceneStep.Kind.MOMENT], "moment")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size())
	assert_eq(MomentLibrary.FOSSIL, &"fossil")


func test_library_reads_the_step() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"))
	var step: CutsceneStep = scenes.get_cutscene(&"dome").variants[0].steps[1]
	assert_eq(step.kind, CutsceneStep.Kind.MOMENT)
	assert_eq(step.moment_type, &"fossil")
	assert_eq(step.moment_details, {"item": "dome_fossil"})
	var copy := step.copy()
	assert_eq([copy.moment_type, copy.moment_details], [&"fossil", {"item": "dome_fossil"}])
	copy.moment_details["item"] = "x"
	assert_eq(step.moment_details["item"], "dome_fossil", "copie indépendante")
	var bare: CutsceneStep = scenes.get_cutscene(&"bare").variants[0].steps[0]
	assert_eq(bare.moment_details, {}, "détails facultatifs")


func test_library_refuses_bad_steps() -> void:
	var bad := {
		"unknown_type": {"steps": [{"moment": "party"}]},
		"zone": {"steps": [{"moment": "zone_arrival"}]},
		"not_text": {"steps": [{"moment": 3}]},
		"details_list": {"steps": [{"moment": "fossil", "details": ["dome_fossil"]}]},
		"details_number": {"steps": [{"moment": "fossil", "details": {"item": 3}}]},
		"details_empty": {"steps": [{"moment": "fossil", "details": {"item": " "}}]},
		"extra_key": {"steps": [{"moment": "fossil", "item": "dome_fossil"}]},
	}
	for id: String in bad:
		var scenes := CutsceneLibrary.new()
		assert_false(scenes.add_from_dict({id: bad[id]}, "t"), id)
		assert_null(scenes.get_cutscene(StringName(id)), "%s écartée" % id)
	assert_push_error_count(bad.size(), "une erreur par scène au moins")


func test_moment_is_recorded_once_on_the_current_map() -> void:
	_director.set_badges(null, _state)
	await _play(&"dome")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	var found := _fossil_moments()
	assert_eq(found.size(), 1)
	assert_eq(found[0].get("map"), "mt_moon_b2f")
	assert_eq(found[0].get("details"), {"item": "dome_fossil"})
	await _play(&"dome")
	assert_eq(_fossil_moments().size(), 1, "rejouée : aucun second moment")
	await _play(&"helix")
	assert_eq(_fossil_moments().size(), 2, "autres détails : un autre moment")
	assert_push_error_count(0)


func test_already_recorded_after_a_reload() -> void:
	_director.set_badges(null, _state)
	await _play(&"dome")
	var reloaded: Node = autofree(STATE_SCRIPT.new())
	var data := PokemonData.new()
	data.load_dir()
	reloaded.load_dict(JSON.parse_string(JSON.stringify(_state.to_dict())), data)
	assert_true(CutsceneDirector.has_moment(reloaded.moments, MomentLibrary.FOSSIL,
		{"item": "dome_fossil"}), "relu de la sauvegarde")
	assert_false(CutsceneDirector.has_moment(reloaded.moments, MomentLibrary.FOSSIL,
		{"item": "helix_fossil"}))
	assert_false(CutsceneDirector.has_moment(reloaded.moments, MomentLibrary.FOSSIL, {}))
	assert_false(CutsceneDirector.has_moment(reloaded.moments, BadgeMoment.TYPE,
		{"item": "dome_fossil"}))


func test_without_state_the_step_is_skipped() -> void:
	await _play(&"dome")
	assert_push_error("pas d'état de la partie")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_eq(_fossil_moments().size(), 0)
