extends GutTest
## Jalon 15 : les textes posés dans les données viennent mot pour mot de l'annexe A de
## `docs/tech/jalon-15.md` (validée par Kevin le 2026-10-14, Q-1) : Jackpot (A.1), zones (A.2),
## note de Miaouss (A.5). Les zones de la Route 5, du souterrain et de la Route 6 attendent
## leurs cartes (T13, T14) dans `tools/pending_data/j15/zones.json` : vérifiées là tant
## qu'elles n'ont pas rejoint `data/world/zones.json`. Panneaux (A.3) et personnages (A.4) :
## contrôlés par test_dialogue_data quand T15 les pose.

const PLAN := "res://docs/tech/jalon-15.md"
const PENDING_ZONES := "res://tools/pending_data/j15/zones.json"
## Zone → [sous-titre attendu ("" : aucun), la description vient de l'annexe].
const ZONES := {
	&"route_5": "Azuria — Safrania",
	&"underground_path": "Route 5 — Route 6",
	&"route_6": "Safrania — Carmin-sur-Mer",
	&"vermilion_city": "",
}

var _annex: String


func before_all() -> void:
	_annex = annex_a(FileAccess.get_file_as_string(PLAN))


## Annexe A de [param plan] (de son titre au titre de même niveau suivant), lignes de
## continuation recollées : une citation coupée par la mise en page redevient une seule ligne.
static func annex_a(plan: String) -> String:
	var start := plan.find("## Annexe A")
	if start < 0:
		return ""
	var end := plan.find("\n## ", start + 1)
	var annex := plan.substr(start, end - start if end >= 0 else -1)
	return annex.replace("\n  ", " ")


func _in_annex(text: String) -> bool:
	return not text.is_empty() and _annex.contains("« %s »" % text)


func test_annex_is_found() -> void:
	assert_string_contains(_annex, "Textes VALIDÉS")
	assert_true(_in_annex("SAFRANIA — Poste de garde"), "citations lues")
	assert_true(_in_annex("Le S.S. Anne ne reste jamais longtemps. Quand il repart, toute la "
		+ "ville vient le saluer."), "citation coupée par la mise en page, recollée")


func test_jackpot_messages() -> void:
	var text := BattleText.new()
	assert_true(text.load_file(), "messages.json")
	for id: StringName in [&"coins_scattered", &"coins_collected"]:
		assert_false(text.is_draft(id), "%s : validé" % id)
		assert_true(_in_annex(text.get_template(id)), "%s : annexe A.1" % id)
	assert_eq(text.coins_line(34), "Tu ramasses %s." % MenuFormat.money(34))


func test_meowth_note() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	var notes := dex.get_notes(&"meowth")
	assert_eq(notes.size(), 1, "une note pour la forme de base")
	if notes.is_empty():
		return
	assert_true(_in_annex(notes[0].text), "annexe A.5")
	assert_false(notes[0].draft)
	assert_eq(notes[0].seen, 1, "à la première observation, comme les autres")
	assert_eq(dex.get_notes(&"persian").size(), 0, "pas de note pour l'évolution")


func test_zone_texts() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file(), "\n".join(zones.get_errors()))
	if FileAccess.file_exists(PENDING_ZONES):
		var pending: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PENDING_ZONES))
		pending.erase("_comment")
		var staged := ZoneLibrary.new()
		assert_true(staged.add_from_dict(pending, PENDING_ZONES),
			"\n".join(staged.get_errors()))
		for id: StringName in staged.get_ids():
			assert_false(zones.has_zone(id), "%s : déjà dans zones.json, à retirer d'ici" % id)
			_check_zone(id, staged.get_zone(id))
	for id: StringName in ZONES:
		if zones.has_zone(id):
			_check_zone(id, zones.get_zone(id))
		else:
			assert_true(FileAccess.file_exists(PENDING_ZONES), "%s : zone en attente" % id)


func _check_zone(id: StringName, zone: ZoneData) -> void:
	assert_true(ZONES.has(id), "%s : zone de l'annexe A.2" % id)
	assert_false(zone.draft, String(id))
	assert_eq(zone.subtitle, ZONES.get(id, ""), "%s : sous-titre" % id)
	if not zone.subtitle.is_empty():
		assert_true(_in_annex(zone.subtitle), "%s : sous-titre de l'annexe" % id)
	assert_true(_in_annex(zone.description), "%s : description de l'annexe A.2" % id)
