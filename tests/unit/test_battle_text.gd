extends GutTest
## BattleText : messages de combat de data/battle/messages.json pour chaque sorte
## d'événement (jalon 4 §2.2 ; décisions de Kevin du §8 point 5). Décision n° 15 :
## accord au féminin (« text_f ») et pas de message générique de fin pour le premier
## combat du rival (TrainerData.end_message).

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
	# Jalon 5D : les textes de la carte de capture viennent du dossier 05 §17 (Q36).
	var fixed: Array[StringName] = [&"sent_out_foe", &"critical", &"super_effective",
		&"not_very_effective", &"caught_title", &"pokedex_new", &"joined_party",
		&"sent_to_storage", &"summary_exp", &"summary_level", &"summary_stat"]
	# Bilan de fin de combat : libellés courts validés par Kevin (demande n° 1, décision 9).
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
	assert_eq(_lines(wild), ["Un Carapuce sauvage apparaît !"], "Pokémon sauvage : jalon 5")


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


func test_feminine_agreement() -> void:
	var recoil := _event(K.RECOIL, false, "Salamèche")
	recoil.gender = Pokemon.Gender.FEMALE
	assert_eq(_lines(recoil), ["Salamèche est blessée par le contrecoup !"])
	recoil.gender = Pokemon.Gender.MALE
	assert_eq(_lines(recoil), ["Salamèche est blessé par le contrecoup !"])
	recoil.gender = Pokemon.Gender.NONE
	assert_eq(_lines(recoil), ["Salamèche est blessé par le contrecoup !"], "asexué")
	assert_true(_text.has_feminine(&"recoil"))
	assert_eq(_text.get_template(&"recoil", true), "{pokemon} est blessée par le contrecoup !")
	# Sans variante au féminin, le modèle commun sert à tous.
	var fainted := _event(K.FAINTED, true)
	fainted.gender = Pokemon.Gender.FEMALE
	assert_false(_text.has_feminine(&"fainted"))
	assert_eq(_lines(fainted), ["Carapuce est K.O. !"])


func test_every_feminine_variant_differs_from_the_common_text() -> void:
	for id: StringName in BattleText.TEMPLATE_IDS:
		if _text.has_feminine(id):
			assert_ne(_text.get_template(id, true), _text.get_template(id), String(id))


func test_no_generic_end_message_for_the_first_rival_battle() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var rival := trainers.get_trainer(&"rival_lab")
	assert_false(rival.end_message, "ses répliques d'après-combat en tiennent lieu")
	var ended := _event(K.BATTLE_ENDED)
	for outcome: int in [Battle.Outcome.WIN, Battle.Outcome.LOSS]:
		ended.outcome = outcome
		assert_eq(Array(_text.lines(ended, _data, rival)), [], "issue %d" % outcome)
	# Les autres dresseurs gardent « Tu as battu… ».
	var other := TrainerData.new()
	ended.outcome = Battle.Outcome.WIN
	assert_true(other.end_message, "par défaut")
	assert_eq(Array(_text.lines(ended, _data, other)), ["Tu as battu Le Rival !"])
	# Le dresseur ne change que la fin.
	assert_eq(Array(_text.lines(_event(K.SENT_OUT, true), _data, rival)),
		["Le Rival envoie Carapuce !"])


func test_no_generic_start_message_for_the_first_rival_battle() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var rival := trainers.get_trainer(&"rival_lab")
	assert_false(rival.start_message, "décision n° 17 : « On ne va quand même pas… » suffit")
	var started := _event(K.BATTLE_STARTED, true)
	assert_eq(Array(_text.lines(started, _data, rival)), [], "pas de « veut se battre »")
	# Les autres dresseurs gardent « … veut se battre ! ».
	var other := TrainerData.new()
	assert_true(other.start_message, "par défaut")
	assert_eq(Array(_text.lines(started, _data, other)), ["Le Rival veut se battre !"])


func test_exp_and_learning_lines() -> void:
	# Pas de phrase pour l'XP ni le niveau (le bilan de fin de combat les raconte, demande
	# n° 1) ; une pour la capacité.
	var gained := _event(K.EXP_GAINED, false, "Salamèche")
	gained.amount = 21
	assert_eq(_lines(gained), [], "l'XP est dans le bilan")
	var level_up := _event(K.LEVEL_UP, false, "Salamèche")
	level_up.level = 6
	assert_eq(_lines(level_up), [], "plus de « monte au niveau » : le bilan le remplace")
	assert_eq(_text.line_for(&"level_up", level_up, _data), "", "modèle retiré")
	var learned := _event(K.MOVE_LEARNED, false, "Salamèche")
	learned.move_id = &"ember"
	assert_eq(_lines(learned), ["Salamèche apprend Flammèche !"])
	var offered := _event(K.MOVE_FORGET_OFFERED, false, "Salamèche")
	offered.move_id = &"rage"
	assert_eq(_lines(offered),
		["Salamèche veut apprendre Frénésie, mais connaît déjà quatre capacités."])
	assert_eq(_text.line_for(&"move_forgot", offered, _data, &"scratch"),
		"Salamèche oublie Griffe et apprend Frénésie !")
	assert_eq(_text.line_for(&"move_not_learned", offered, _data),
		"Salamèche n'apprend pas Frénésie.")
	assert_eq(_text.line_for(&"unknown_template", offered, _data), "")


func test_leech_seed_lines() -> void:
	var seeded := _event(K.SEEDED, true, "Roucool")
	assert_eq(_lines(seeded), ["Une graine est plantée sur Roucool !"])
	var drained := _event(K.DRAINED, true, "Roucool")
	assert_eq(_lines(drained), ["Vampigraine draine l'énergie de Roucool !"])
	drained.pokemon_name = "Évoli"
	assert_eq(_lines(drained), ["Vampigraine draine l'énergie d'Évoli !"])


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
	var dict := _valid_dict()
	dict["templates"]["fainted"] = { "text": "{pokemon} tombe !", "text_f": "{pokemon} chute !" }
	var text := BattleText.new()
	assert_true(text.add_from_dict(dict, "t"), "text_f facultatif")
	assert_true(text.has_feminine(&"fainted"))
	assert_false(text.has_feminine(&"recoil"))


func test_missing_unknown_and_malformed_templates_are_rejected() -> void:
	var text := BattleText.new()
	var dict := _valid_dict()
	dict["templates"].erase("fainted")
	dict["templates"]["victory_dance"] = { "text": "Youpi !" }
	dict["templates"]["recoil"] = { "text": "{pokemon} et {ennemi}", "draft": "oui" }
	dict["templates"]["critical"] = { "text": "" }
	dict["templates"]["move_used"] = { "text": "{pokemon} !", "text_f": "" }
	dict["templates"]["move_missed"] = { "text": "{pokemon} !", "text_f": "{pokemone} !" }
	dict["stats"].erase("spe")
	dict["stats"]["luck"] = "Chance"
	dict["extra"] = 1
	assert_false(text.add_from_dict(dict, "t"))
	assert_push_error_count(10)
	var errors := "\n".join(text.get_errors())
	for expected: String in ["clé inconnue « extra »", "modèle « victory_dance » : modèle inconnu",
			"marque inconnue « {ennemi} »", "« draft » vaut true ou false",
			"« text » doit être un texte non vide", "modèle « fainted » manquant",
			"statistique inconnue « luck »", "stats : « spe » manquant",
			"« text_f » doit être un texte non vide",
			"text_f : marque inconnue « {pokemone} »"]:
		assert_string_contains(errors, expected)
	assert_eq(text.get_template(&"move_used"), "", "tout ou rien")


func test_broken_or_missing_file() -> void:
	var text := BattleText.new()
	assert_false(text.load_file("res://tests/fixtures/trainers/bad_json/broken.json"))
	assert_push_error("ligne 6")
	assert_false(text.load_file("res://nothing.json"))
	assert_push_error_count(2)


# --- Combat sauvage (jalon 5 §2.2) ------------------------------------------------------

func _wild_event(kind: BattleEvent.Kind, side: BattleEvent.SideId,
		pokemon: String = "Rattata") -> BattleEvent:
	var event := BattleEvent.new(kind, side)
	event.pokemon_name = pokemon
	event.trainer_name = ""
	return event


func test_wild_sent_out_uses_wild_appeared() -> void:
	var event := _wild_event(K.SENT_OUT, BattleEvent.SideId.FOE)
	assert_eq(_lines(event), ["Un Rattata sauvage apparaît !"] as Array[String])


func test_wild_appeared_agrees_in_feminine() -> void:
	var event := _wild_event(K.SENT_OUT, BattleEvent.SideId.FOE, "Nidoran")
	event.gender = Pokemon.Gender.FEMALE
	assert_eq(_lines(event), ["Une Nidoran sauvage apparaît !"] as Array[String])


func test_fled_and_flee_failed() -> void:
	assert_eq(_lines(_wild_event(K.FLED, BattleEvent.SideId.PLAYER)),
		["Tu prends la fuite !"] as Array[String])
	assert_eq(_lines(_wild_event(K.FLEE_FAILED, BattleEvent.SideId.PLAYER)),
		["Impossible de fuir !"] as Array[String])


func test_wild_battle_ended_has_no_line() -> void:
	# Sortie d'un combat sauvage : ni « Tu as battu… » (pas de dresseur) ni message pour FLED.
	var fled := _wild_event(K.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	fled.outcome = Battle.Outcome.FLED
	assert_eq(_lines(fled).size(), 0)
	var won := _wild_event(K.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	won.outcome = Battle.Outcome.WIN
	assert_eq(_lines(won).size(), 0, "un sauvage n'a pas de « Tu as battu »")


# --- Capture (jalon 5D §2.4, dossier 05 §17, Q36) -------------------------------------------

func test_ball_thrown_names_the_ball() -> void:
	var event := _wild_event(K.BALL_THROWN, BattleEvent.SideId.FOE, "Roucool")
	event.item_id = &"poke_ball"
	event.item_name = "Poké Ball"
	assert_eq(_lines(event), ["Tu lances une Poké Ball !"] as Array[String])


func test_broke_free_agrees_in_feminine() -> void:
	var event := _wild_event(K.BROKE_FREE, BattleEvent.SideId.FOE, "Roucool")
	event.gender = Pokemon.Gender.MALE
	assert_eq(_lines(event), ["Oh non ! Il s'est libéré !"] as Array[String])
	event.gender = Pokemon.Gender.FEMALE
	assert_eq(_lines(event), ["Oh non ! Elle s'est libérée !"] as Array[String])


func test_shakes_caught_and_caught_end_have_no_line() -> void:
	# La carte de capture tient lieu de message (dossier 05 §17 : « pas 8 fenêtres »).
	assert_eq(_lines(_wild_event(K.BALL_SHAKE, BattleEvent.SideId.FOE)).size(), 0)
	assert_eq(_lines(_wild_event(K.CAUGHT, BattleEvent.SideId.FOE)).size(), 0)
	var ended := _wild_event(K.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	ended.outcome = Battle.Outcome.CAUGHT
	assert_eq(_lines(ended).size(), 0)


func test_capture_card_texts_are_those_of_dossier_05() -> void:
	var caught := _wild_event(K.CAUGHT, BattleEvent.SideId.FOE, "Roucool")
	caught.gender = Pokemon.Gender.MALE
	assert_eq(_text.line_for(&"caught_title", caught, _data).to_upper(), "ROUCOOL CAPTURÉ !",
		"titre en capitales sur la carte")
	assert_eq(_text.line_for(&"pokedex_new", caught, _data), "Nouvelle entrée Pokédex")
	assert_eq(_text.line_for(&"joined_party", caught, _data), "Roucool rejoint ton équipe.")
	assert_eq(_text.line_for(&"sent_to_storage", caught, _data),
		"Roucool a été confié au système de recherche de Chen.")
	caught.gender = Pokemon.Gender.FEMALE
	assert_eq(_text.line_for(&"caught_title", caught, _data).to_upper(), "ROUCOOL CAPTURÉE !")
	assert_eq(_text.line_for(&"sent_to_storage", caught, _data),
		"Roucool a été confiée au système de recherche de Chen.")
	assert_eq(_text.line_for(&"joined_party", caught, _data), "Roucool rejoint ton équipe.")
	caught.pokemon_name = "Salamèche"
	assert_eq(_text.line_for(&"caught_title", caught, _data).to_upper(), "SALAMÈCHE CAPTURÉE !")


## Jalon 6 : soin en combat, textes proposés (draft, à relire par Kevin).
func test_item_used_then_hp_restored() -> void:
	var used := _event(K.ITEM_USED, false, "Salamèche")
	used.item_name = "Potion"
	used.amount = 20
	assert_eq(_lines(used), ["Tu utilises Potion sur Salamèche.",
		"Salamèche récupère 20 PV."] as Array[String])
	assert_true(_text.is_draft(&"item_used"))
	assert_true(_text.is_draft(&"hp_restored"))


## Jalon 7 : « Tu remportes 280 ₽. » (draft), somme au format de l'argent du menu.
func test_prize_line() -> void:
	assert_eq(_text.prize_line(280), "Tu remportes %s." % MenuFormat.money(280))
	assert_eq(_text.prize_line(1400), "Tu remportes %s." % MenuFormat.money(1400))
	assert_true(_text.is_draft(&"prize_won"), "à relire par Kevin")


## Bilan de fin de combat (demande n° 1) : « +11 XP », « Nv. 9 », gains de statistiques courts
## dans l'ordre PV, Attaque, Défense, Atq. Spé., Déf. Spé., Vitesse ; +0 non écrits.
func test_summary_labels() -> void:
	assert_eq(_text.summary_exp(11), "+11 XP")
	assert_eq(_text.summary_level(9), "Nv. 9")
	var gains: Dictionary[StringName, int] = {&"spe": 1, &"hp": 2, &"atk": 1, &"def": 0,
		&"spa": 1, &"spd": 1}
	assert_eq(_text.summary_stats(gains), "PV +2 · Attaque +1 · Atq. Spé. +1 · Déf. Spé. +1"
		+ " · Vitesse +1", "ordre fixe, Défense +0 masquée")
	var none: Dictionary[StringName, int] = {&"hp": 0}
	assert_eq(_text.summary_stats(none), "")
	assert_eq(_text.get_template(&"summary_continue"), "Touchez l'écran pour continuer")


func test_incomplete_stat_labels_are_rejected() -> void:
	var broken := BattleText.new()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BattleText.DATA_PATH))
	(data["stat_labels"] as Dictionary).erase("spe")
	(data["stat_labels"] as Dictionary)["luck"] = "Chance"
	assert_false(broken.add_from_dict(data, "test"))
	assert_push_error_count(2)
