extends GutTest
## Jalon 23 : données générées depuis les grilles (`tools/gen_j23_data.py`) — dialogues et scènes
## `j23_*.json`, PNJ des cartes du Parc, de la Porte et des maisons — à part des grands registres.
## Textes : dossier 26 §8 et annexe A de `jalon-23.md`, mot pour mot ; les textes recommandés
## (« [R] », validés d'avance par Kevin le 2026-10-21) sont listés ici.

const J22Ids := preload("res://tests/helpers/j22_ids.gd")
const DOSSIER_26: String = "res://docs/design/dossier-26-parc-safari-koga.md"
const PLAN_J23: String = "res://docs/tech/jalon-23.md"
const MAPS: Array[StringName] = [&"safari_zone_gate", &"safari_zone_center", &"safari_zone_east",
	&"safari_zone_north", &"safari_zone_west", &"safari_zone_rest_house_center",
	&"safari_zone_rest_house_east", &"safari_zone_rest_house_north",
	&"safari_zone_rest_house_west", &"safari_zone_secret_house", &"wardens_house", &"fuchsia_gym"]
## Textes recommandés (« [R] ») et défauts du plan ([D]) : hors des documents validés.
const RECOMMENDED: Array[String] = ["Passe au comptoir pour entrer.",
	"Ta visite du PARC SAFARI est terminée.",
	# Koga (T19, [R]) : reprise après une défaite, défaite.
	"Fwahahaha ! Tu reviens ?", "Le poison a fait son œuvre.", "Reviens quand tu seras prêt."]
## Objets du dossier 26 §7 (remplacements N-19), par carte et position.
const ITEMS: Dictionary = {
	&"safari_zone_center_pepite": &"nugget", &"safari_zone_east_guerison": &"full_restore",
	&"safari_zone_east_potion_max": &"hyper_potion", &"safari_zone_east_carbone": &"rare_candy",
	&"safari_zone_east_ct37": &"tm37", &"safari_zone_north_proteine": &"revive",
	&"safari_zone_north_ct40": &"tm40", &"safari_zone_west_potion_max": &"hyper_potion",
	&"safari_zone_west_ct32": &"tm32", &"safari_zone_west_rappel_max": &"revive",
	&"safari_zone_west_dents_or": &"gold_teeth", &"safari_zone_west_rappel_cache": &"revive",
	&"wardens_house_super_bonbon": &"rare_candy",
}

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _items: ItemLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _ids(dir: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(J22Ids.in_dir(dir, "j23_").keys())
	return ids


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 40)


func test_every_line_is_a_validated_text() -> void:
	var source := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER_26)
		+ FileAccess.get_file_as_string(PLAN_J23))
	for id: StringName in _ids("res://data/dialogues/"):
		var dialogue := _dialogues.get_dialogue(id)
		for variant: DialogueVariant in dialogue.variants:
			var texts: Array[String] = []
			for page: DialoguePage in variant.pages:
				texts.append(page.text)
			if variant.choice != null:
				for page: DialoguePage in variant.choice.confirm_pages + variant.choice.cancel_pages:
					texts.append(page.text)
			for text: String in texts:
				if RECOMMENDED.has(text):
					continue
				assert_true(source.contains(J22Ids.flat_text(text)),
					"%s : « %s » dans le dossier 26 ou l'annexe A" % [id, text])


func test_every_scene_and_dialogue_exists() -> void:
	for map_id: StringName in MAPS:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			assert_true(_dialogues.has_dialogue(spec.dialogue), "%s : %s" % [map_id,
				spec.dialogue])
	for id: StringName in _ids("res://data/cutscenes/"):
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.DIALOGUE:
					assert_true(_dialogues.has_dialogue(step.dialogue_id), "%s → %s" % [id,
						step.dialogue_id])
				if step.kind in [CutsceneStep.Kind.GIVE, CutsceneStep.Kind.TAKE]:
					assert_not_null(_items.get_item(step.item_id), "%s : %s" % [id, step.item_id])


func test_items_once_with_their_flag() -> void:
	for id: StringName in ITEMS:
		assert_true(_cutscenes.has_cutscene(id), id)
		if not _cutscenes.has_cutscene(id):
			continue
		var variant: CutsceneVariant = _cutscenes.get_cutscene(id).variants[0]
		assert_eq(variant.unless_flags, [StringName("got_" + String(id))] as Array[StringName],
			"%s : une seule fois" % id)
		var given: Array[StringName] = []
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.GIVE:
				given.append(step.item_id)
				assert_true(step.found, "%s : objet trouvé (journal)" % id)
		assert_eq(given, [ITEMS[id]] as Array[StringName], id)


func test_hm_gifts_set_their_flag_right_after_the_item() -> void:
	for pair: Array in [[&"j23_secret_house_hm03", &"hm03", &"got_hm03"],
			[&"j23_warden_teeth", &"hm04", &"got_hm04"], [&"j23_warden_hm04", &"hm04", &"got_hm04"]]:
		var steps: Array[CutsceneStep] = _cutscenes.get_cutscene(pair[0]).variants[0].steps
		var at := -1
		for i: int in steps.size():
			if steps[i].kind == CutsceneStep.Kind.GIVE and steps[i].item_id == pair[1]:
				at = i
		assert_gt(at, -1, "%s donne %s" % [pair[0], pair[1]])
		assert_eq(steps[at + 1].kind, CutsceneStep.Kind.SET_FLAGS)
		assert_eq(steps[at + 1].flags, [pair[2]] as Array[StringName], "même écriture")


func test_warden_takes_the_teeth_before_giving_force() -> void:
	var steps: Array[CutsceneStep] = _cutscenes.get_cutscene(&"j23_warden_teeth").variants[0].steps
	var kinds: Array[int] = []
	for step: CutsceneStep in steps:
		if step.kind in [CutsceneStep.Kind.TAKE, CutsceneStep.Kind.GIVE]:
			kinds.append(step.kind)
	assert_eq(kinds, [CutsceneStep.Kind.TAKE, CutsceneStep.Kind.GIVE] as Array[int])
	var warden := _dialogues.get_dialogue(&"wardens_house_gardien")
	assert_eq(warden.variants[0].if_flags, [&"gave_gold_teeth"] as Array[StringName],
		"reprise si la CS n'a pas été donnée (RB)")
