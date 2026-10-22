extends GutTest
## Textes de la Ligue (jalon 30 T4 ; `jalon-30.md` §3, T30-01 à T30-17) : propositions du plan,
## validées par Kevin le 2026-10-21 (validation d'avance, proposition du plan). Rangées dans
## `data/league/dialogues.json` tant qu'aucune carte ne les utilise (test_dialogue_data exige
## qu'un dialogue de `data/dialogues/` soit utilisé) : le fichier passe dans `data/dialogues/`
## avec les cartes (T9, après le J29). Il se charge sans erreur, à côté des autres dialogues.

const SOURCE := "res://data/league/dialogues.json"
const IDS: Array[StringName] = [
	&"league_guard_door",
	&"league_lorelei_before", &"league_lorelei_defeated",
	&"league_bruno_before", &"league_bruno_defeated",
	&"league_agatha_before", &"league_agatha_defeated",
	&"league_lance_before", &"league_lance_defeated",
	&"rival_champion_before", &"rival_champion_defeated", &"rival_champion_won",
	&"league_oak_congrats", &"league_oak_to_rival", &"league_oak_hall",
	&"league_hall_welcome", &"league_ending",
]


func test_the_league_texts_load_with_all_dialogues() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_true(library.load_file(SOURCE), "aucun identifiant en double avec les dialogues")
	for id: StringName in IDS:
		assert_true(library.has_dialogue(id), String(id))


func test_the_file_holds_exactly_the_league_texts() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_file(SOURCE), "\n".join(library.get_errors()))
	assert_eq(library.size(), IDS.size())
	assert_eq(library.get_dialogue(&"league_lorelei_before").speaker, "Olga")
	assert_eq(library.get_dialogue(&"league_bruno_before").speaker, "Aldo")
	assert_eq(library.get_dialogue(&"league_agatha_before").speaker, "Agatha")
	assert_eq(library.get_dialogue(&"league_lance_before").speaker, "Peter")
	assert_eq(library.get_dialogue(&"rival_champion_before").speaker, "{rival}")
	assert_eq(library.get_dialogue(&"league_oak_congrats").speaker, "Prof. Chen")
