extends GutTest
## BadgeLibrary (MM.1) : les 8 badges de Kanto en données, obtenus par drapeau d'histoire,
## muets tant qu'ils ne sont pas obtenus.

const EXPECTED: Array[Array] = [
	[&"boulder", "Badge Roche", "Argenta", "Pierre"],
	[&"cascade", "Badge Cascade", "Azuria", "Ondine"],
	[&"thunder", "Badge Foudre", "Carmin-sur-Mer", "Major Bob"],
	[&"rainbow", "Badge Prisme", "Céladopole", "Erika"],
	[&"soul", "Badge Âme", "Parmanie", "Koga"],
	[&"marsh", "Badge Marais", "Safrania", "Morgane"],
	[&"volcano", "Badge Volcan", "Cramois'Île", "Auguste"],
	[&"earth", "Badge Terre", "Jadielle", "Giovanni"],
]


func _library() -> BadgeLibrary:
	var library := BadgeLibrary.new()
	assert_true(library.load_file(), "data/badges.json se charge")
	assert_eq(library.get_errors(), PackedStringArray())
	return library


func test_the_eight_badges_of_kanto_in_gym_order() -> void:
	var library := _library()
	assert_eq(library.size(), BadgeLibrary.COUNT)
	var ids := library.ids()
	for i: int in EXPECTED.size():
		var row: Array = EXPECTED[i]
		assert_eq(ids[i], row[0])
		assert_eq(library.order(row[0]), i + 1)
		assert_eq(library.badge_name(row[0]), row[1])
		assert_eq(library.city(row[0]), row[2])
		assert_eq(library.leader(row[0]), row[3])
		assert_false(library.flag(row[0]).is_empty())


func test_nothing_obtained_in_a_new_game_and_slots_stay_mute() -> void:
	var library := _library()
	var flags := StoryFlags.new()
	assert_eq(library.obtained_count(flags), 0)
	var slots := library.slots(flags)
	assert_eq(slots.size(), BadgeLibrary.COUNT)
	for i: int in slots.size():
		assert_eq(slots[i].index, i)
		assert_false(slots[i].obtained)
		assert_eq(slots[i].name, "", "un badge inconnu ne dit pas son nom")
		assert_eq(slots[i].detail, "")
		assert_eq(slots[i].badge_id, &"")


func test_a_raised_flag_gives_the_badge() -> void:
	var library := _library()
	var flags := StoryFlags.new()
	flags.set_flag(library.flag(&"cascade"))
	assert_true(library.is_obtained(&"cascade", flags))
	assert_false(library.is_obtained(&"boulder", flags))
	assert_eq(library.obtained_ids(flags), [&"cascade"] as Array[StringName])
	var slot := library.slots(flags)[1]
	assert_true(slot.obtained)
	assert_eq(slot.badge_id, &"cascade")
	assert_eq(slot.name, "Badge Cascade")
	assert_eq(slot.detail, "Azuria — Ondine")
	assert_false(library.slots(flags)[0].obtained)


func test_invalid_entries_are_rejected() -> void:
	var library := BadgeLibrary.new()
	var ok := library.add_from_array([
		{"id": "a", "order": 1, "name": "Badge A", "leader": "L", "city": "C", "flag": "fa"},
		{"id": "a", "order": 2, "name": "Badge B", "leader": "L", "city": "C", "flag": "fb"},
		{"id": "c", "order": 1, "name": "Badge C", "leader": "L", "city": "C", "flag": "fc"},
		{"id": "d", "order": 9, "name": "Badge D", "leader": "L", "city": "C", "flag": "fd"},
		{"id": "e", "order": 3, "name": "", "leader": "L", "city": "C", "flag": "fe"},
		{"id": "f", "order": 4, "name": "Badge F", "leader": "L", "city": "C", "flag": "fa"},
		{"id": "g", "order": 5, "name": "Badge G", "leader": "L", "city": "C", "flag": "fg",
			"couleur": "or"},
		"pas un objet",
	], "test")
	assert_false(ok)
	assert_eq(library.ids(), [&"a"] as Array[StringName], "seule la première entrée est valide")
	assert_eq(library.get_errors().size(), 7)
