extends GutTest
## BattleText : messages de combat de data/battle/messages.json pour chaque sorte
## d'événement (jalon 4 §2.2 ; décisions de Kevin du §8 point 5).

const K := BattleEvent.Kind

var _data: PokemonData
var _text: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_text = BattleText.new()
	_text.load_file()


func _event(kind: BattleEvent.Kind, foe: bool = false, pokemon: String = "Carapuce") \
		-> BattleEvent:
	var event := BattleEvent.new(kind, BattleEvent.SideId.FOE if foe
		else BattleEvent.SideId.PLAYER)
	event.pokemon_name = pokemon
	event.trainer_name = "Le Rival"
	return event


func _lines(event: BattleEvent) -> Array[String]:
	var result: Array[String] = []
	result.assign(_text.lines(event, _data))
	return result


# --- Données ----------------------------------------------------------------------------

func test_real_messages_load_without_error() -> void:
	assert_eq(_text.get_errors().size(), 0)
	for id: StringName in BattleText.TEMPLATE_IDS:
		assert_false(_text.get_template(id).is_empty(), String(id))


func test_messages_fixed_by_kevin_are_final_and_the_others_draft() -> void:
	var fixed: Array[StringName] = [&"sent_out_foe", &"critical", &"super_effective",
		&"not_very_effective"]
	for id: StringName in BattleText.TEMPLATE_IDS:
		assert_eq(_text.is_draft(id), not fixed.has(id), String(id))


func test_foe_is_named_alone() -> void:
	for id: StringName in BattleText.TEMPLATE_IDS:
		var template := _text.get_template(id)
		assert_false(template.containsn("ennemi"), String(id))
		assert_false(template.contains("du Rival"), String(id))


# --- Phrases ----------------------------------------------------------------------------

func test_start_and_sending_out() -> void:
	assert_eq(_lines(_event(K.BATTLE_STARTED, true)), ["Le Rival veut se battre !"])
	assert_eq(_lines(_event(K.SENT_OUT, true)), ["Le Rival envoie Carapuce !"])
	assert_eq(_lines(_event(K.SENT_OUT, false, "Salamèche")), ["En avant, Salamèche !"])
	var wild := _event(K.SENT_OUT, true)
	wild.trainer_name = ""
	assert_eq(_lines(wild), [], "Pokémon sauvage : jalon 5")


func test_turn_start_has_no_message() -> void:
	assert_eq(_lines(_event(K.TURN_STARTED)), [])


func test_moves() -> void:
	var used := _event(K.MOVE_USED, true)
	used.move_id = &"tail_whip"
	assert_eq(_lines(used), ["Carapuce utilise Mimi-Queue !"])
	var missed := _event(K.MOVE_MISSED)
	missed.move_id = &"hydro_pump"
	assert_eq(_lines(missed), ["Carapuce rate son attaque !"])


func test_damage_lines() -> void:
	var plain := _event(K.DAMAGE, true)
	assert_eq(_lines(plain), [], "un coup normal ne dit rien")
	var strong := _event(K.DAMAGE, true)
	strong.critical = true
	strong.effectiveness = 2.0
	assert_eq(_lines(strong), ["Coup critique !", "C'est super efficace !"])
	var weak := _event(K.DAMAGE, true)
	weak.effectiveness = 0.25
	assert_eq(_lines(weak), ["Ce n'est pas très efficace..."])
	assert_eq(_lines(_event(K.NO_EFFECT, true, "Fantominus")),
		["Ça n'affecte pas Fantominus..."])


func test_stat_lines() -> void:
	var fell := _event(K.STAT_CHANGED, false, "Salamèche")
	fell.stat = &"def"
	fell.stages = -1
	assert_eq(_lines(fell), ["La Défense de Salamèche baisse !"])
	fell.stages = -2
	assert_eq(_lines(fell), ["La Défense de Salamèche baisse beaucoup !"])
	var rose := _event(K.STAT_CHANGED, false, "Évoli")
	rose.stat = &"atk"
	rose.stages = 1
	assert_eq(_lines(rose), ["L'Attaque d'Évoli augmente !"])
	rose.stages = 4
	assert_eq(_lines(rose), ["L'Attaque d'Évoli augmente énormément !"])
	var stuck := _event(K.STAT_UNCHANGED, true)
	stuck.stat = &"atk"
	stuck.stages = -1
	assert_eq(_lines(stuck), ["L'Attaque de Carapuce ne peut plus baisser !"])
	stuck.stages = 1
	assert_eq(_lines(stuck), ["L'Attaque de Carapuce ne peut plus augmenter !"])


func test_recoil_faint_and_end() -> void:
	assert_eq(_lines(_event(K.RECOIL)), ["Carapuce est blessé par le contrecoup !"])
	assert_eq(_lines(_event(K.FAINTED, true)), ["Carapuce est K.O. !"])
	var won := _event(K.BATTLE_ENDED)
	won.outcome = Battle.Outcome.WIN
	assert_eq(_lines(won), ["Tu as battu Le Rival !"])
	won.outcome = Battle.Outcome.LOSS
	assert_eq(_lines(won), ["Le Rival a gagné cette fois..."])


func test_elision() -> void:
	assert_eq(BattleText.de_name("Salamèche"), "de Salamèche")
	assert_eq(BattleText.de_name("Évoli"), "d'Évoli")
	assert_eq(BattleText.de_name("Abra"), "d'Abra")


func test_every_real_battle_event_has_a_known_phrase() -> void:
	# Un combat complet réel : aucune phrase ne garde de marque « { } ».
	var rng := GameRng.new(5)
	var player_party := Party.new()
	player_party.add(PokemonFactory.create(_data, &"bulbasaur", 5, rng))
	var foe_party := Party.new()
	foe_party.add(PokemonFactory.create(_data, &"charmander", 5, rng))
	var player := BattleSide.new(player_party, true)
	var battle := Battle.new(player, BattleSide.new(foe_party, false, "Le Rival"), _data, rng)
	var events := battle.start()
	while battle.get_state() == Battle.State.CHOOSING:
		events.append_array(battle.submit(BattleAI.new().choose(player, null, rng)))
	var count := 0
	for event: BattleEvent in events:
		for line: String in _text.lines(event, _data):
			assert_false(line.contains("{"), line)
			count += 1
	assert_gt(count, 5)


# --- Validation -------------------------------------------------------------------------

func _valid_dict() -> Dictionary:
	var templates: Dictionary = {}
	for id: StringName in BattleText.TEMPLATE_IDS:
		templates[String(id)] = { "text": "{pokemon} !" }
	var stats: Dictionary = {}
	for stat: StringName in MoveEffect.STAGE_STATS:
		stats[String(stat)] = "Stat"
	return { "templates": templates, "stats": stats }


func test_valid_dict_is_accepted() -> void:
	assert_true(BattleText.new().add_from_dict(_valid_dict(), "t"))


func test_missing_unknown_and_malformed_templates_are_rejected() -> void:
	var text := BattleText.new()
	var dict := _valid_dict()
	dict["templates"].erase("fainted")
	dict["templates"]["victory_dance"] = { "text": "Youpi !" }
	dict["templates"]["recoil"] = { "text": "{pokemon} et {ennemi}", "draft": "oui" }
	dict["templates"]["critical"] = { "text": "" }
	dict["stats"].erase("spe")
	dict["stats"]["luck"] = "Chance"
	dict["extra"] = 1
	assert_false(text.add_from_dict(dict, "t"))
	assert_push_error_count(8)
	var errors := "\n".join(text.get_errors())
	for expected: String in ["clé inconnue « extra »", "modèle « victory_dance » : modèle inconnu",
			"marque inconnue « {ennemi} »", "« draft » vaut true ou false",
			"« text » doit être un texte non vide", "modèle « fainted » manquant",
			"statistique inconnue « luck »", "stats : « spe » manquant"]:
		assert_string_contains(errors, expected)
	assert_eq(text.get_template(&"move_used"), "", "tout ou rien")


func test_broken_or_missing_file() -> void:
	var text := BattleText.new()
	assert_false(text.load_file("res://tests/fixtures/trainers/bad_json/broken.json"))
	assert_push_error("ligne 6")
	assert_false(text.load_file("res://nothing.json"))
	assert_push_error_count(2)
