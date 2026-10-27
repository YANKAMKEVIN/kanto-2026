extends GutTest
## [CreditsData] (jalon 30, T16, Q30-1) : `data/story/credits.json` se charge ; lignes du
## générique dans l'ordre (logo, remake, joueur et équipe, merci), ligne d'un Pokémon (T30-16) ;
## fichiers mal formés refusés.

var _credits: CreditsData


func before_each() -> void:
	_credits = CreditsData.new()


func _entry() -> Dictionary:
	return {"player": "Kevin", "team": [
		{"species": "charizard", "nickname": "", "level": 62},
		{"species": "pidgeot", "nickname": "Plume", "level": 58}]}


func _name_of(member: Dictionary) -> String:
	return member["nickname"] if not (member["nickname"] as String).is_empty() \
		else String(member["species"]).capitalize()


func test_the_file_loads_with_the_decided_texts() -> void:
	assert_true(_credits.load_file(), str(_credits.get_errors()))
	assert_eq(_credits.member_line("Dracaufeu", 62), "Dracaufeu — N62", "T30-16")
	var texts: Array = _credits.rows(_entry(), _name_of).filter(func(row: Dictionary) -> bool:
		return row["kind"] != CreditsData.RowKind.GAP).map(func(row: Dictionary) -> String:
			return row["text"])
	assert_eq(texts[0], "KANTO 2026", "T30-19")
	assert_eq(texts[1], "Kanto 2026 — un remake personnel de Kevin", "Q30-1")
	assert_eq(texts.slice(2, 5), ["Kevin", "Charizard — N62", "Plume — N58"], "l'équipe du joueur")
	assert_eq(texts.back(), "Merci d'avoir joué", "Q30-1")
	assert_false(_credits.skip_label.is_empty())


func test_rows_are_typed_and_blocks_are_separated() -> void:
	assert_true(_credits.load_dict({"blocks": [{"logo": "L"}, {"team": true}, {"title": "T"}]}))
	var kinds: Array = _credits.rows(_entry(), _name_of).map(func(row: Dictionary) -> int:
		return row["kind"])
	assert_eq(kinds, [CreditsData.RowKind.LOGO, CreditsData.RowKind.GAP,
		CreditsData.RowKind.HEADING, CreditsData.RowKind.LINE, CreditsData.RowKind.LINE,
		CreditsData.RowKind.GAP, CreditsData.RowKind.TITLE])


func test_bad_files_are_refused() -> void:
	var bad: Array[Dictionary] = [
		{}, {"blocks": []}, {"blocks": [{"title": ""}]}, {"blocks": [{"lines": []}]},
		{"blocks": [{"title": "a", "lines": ["b"]}]}, {"blocks": [{"team": false}]},
		{"blocks": [{"title": "a", "color": "red"}]}, {"member": "", "blocks": [{"title": "a"}]},
	]
	for data: Dictionary in bad:
		var credits := CreditsData.new()
		assert_false(credits.load_dict(data), str(data))
	assert_push_error_count(bad.size())
