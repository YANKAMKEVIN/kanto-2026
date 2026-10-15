extends GutTest
## Données du jalon 17 (T8 ; `docs/tech/jalon-17.md` §2.6, §2.12.3 à §2.12.5) : Dresseurs de la
## Route 11, rencontres de la Route 11 et de la Cave Taupiqueur, dialogues (Route 11, Route 2 est,
## barrière de FUTUR B), scène de remise de la CS05, zones en attente de leurs cartes. Textes
## recopiés **mot pour mot** du lot validé par Kevin le 2026-10-14 (dossier 20 §16, variantes A) ;
## la variante d'accord « 1 espèce » vient de l'annexe A du plan (Q-2, validée le 2026-10-16).
## Les cartes n'existent pas encore (T15, T16, T19, T21) : rien ici ne charge de scène.

const DOSSIER := "res://docs/design/dossier-20-chemins-retrouves.md"
const PLAN := "res://docs/tech/jalon-17.md"
const PENDING_ZONES := "res://tools/pending_data/j17/zones.json"
const AnnexATexts := preload("res://tests/unit/test_annex_a_texts.gd")
## Jetons de code → notation du dossier (§16 : `{n}`, `{reste}`, `{joueur}`).
const TOKENS: Dictionary[String, String] = {"{caught_missing}": "{reste}", "{caught}": "{n}",
	"{player}": "{joueur}"}

## Dresseurs (§6 ; identifiants de la grille `route_11.txt`) : [ligne du §16, nom, équipe
## [espèce, niveau]…, argent du dossier, base de la classe (Rouge/Bleu)]. Niveaux : références RB
## gardées après la simulation du T8 (plan §2.12.4).
const TRAINERS := {
	&"route_11_youngster_lucas": ["T-18", "Gamin Lucas", [[&"ekans", 21]], 315, 15],
	&"route_11_youngster_arthur": ["T-19", "Gamin Arthur",
		[[&"sandshrew", 19], [&"zubat", 19]], 285, 15],
	&"route_11_youngster_louis": ["T-20", "Gamin Louis",
		[[&"rattata", 17], [&"rattata", 17], [&"raticate", 17]], 255, 15],
	&"route_11_youngster_raphael": ["T-21", "Gamin Raphaël",
		[[&"nidoran_m", 18], [&"nidorino", 18]], 270, 15],
	&"route_11_gambler_marcel": ["T-22", "Joueur Marcel",
		[[&"voltorb", 18], [&"magnemite", 18]], 1260, 70],
	&"route_11_gambler_roger": ["T-23", "Joueur Roger",
		[[&"growlithe", 18], [&"vulpix", 18]], 1260, 70],
	&"route_11_engineer_bruno": ["T-24", "Ingénieur Bruno", [[&"magnemite", 21]], 1050, 50],
	&"route_11_engineer_victor": ["T-25", "Ingénieur Victor",
		[[&"magnemite", 16], [&"magnemite", 16], [&"magneton", 16]], 800, 50],
}
## Recalés par la simulation du T8 (plan §2.12.4) → équipe et argent de référence du dossier §6.
const RECALIBRATED := {
	&"route_11_engineer_victor": "Magnéti Nv. 18, Magnéti Nv. 18, Magnéton Nv. 18 | 900",
}
## Références de Major Bob (dossier 19, J16) : aucun Dresseur de la Route 11 ne les dépasse.
const MAJOR_BOB_MAX_LEVEL := 24

var _data: PokemonData
var _dialogues: DialogueLibrary
var _dossier: String
var _annex: String


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_dialogues = DialogueLibrary.new()
	assert_true(_dialogues.load_dir(), "\n".join(_dialogues.get_errors()))
	_dossier = FileAccess.get_file_as_string(DOSSIER)
	_annex = AnnexATexts.annex_a(FileAccess.get_file_as_string(PLAN))


# --- Dresseurs --------------------------------------------------------------------------

func test_route_11_trainers() -> void:
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var trainer := trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.source, "res://data/trainers/route_11.json")
		assert_eq([trainer.name, trainer.ai, trainer.can_lose, trainer.heal_after,
			trainer.gives_exp, trainer.can_switch], [row[1], &"random", false, false, true,
			false], String(id))
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
			assert_lte(slot.level, MAJOR_BOB_MAX_LEVEL, "%s : sous Major Bob" % id)
		assert_eq(team, row[2], String(id))
		var last_level: int = (row[2] as Array).back()[1]
		assert_eq(trainer.prize_for(last_level), int(row[4]) * last_level,
			"%s : base de la classe × dernier niveau" % id)
		assert_eq(int(row[4]) * last_level, row[3], "%s : argent" % id)
		if RECALIBRATED.has(id):
			assert_true(_dossier.contains("| **%s** | %s |" % [row[1], RECALIBRATED[id]]),
				"%s : référence du dossier §6" % id)
		else:
			assert_true(_dossier.contains(" | %s | " % _money(row[3])), "%s : argent du §6" % id)
		assert_true(_dossier.contains("| **%s** |" % row[1]), "%s : nom du dossier §6" % row[1])


func test_trainers_know_red_blue_moves_except_growlithe() -> void:
	# Capacités apprises au niveau (méthode du J12) ; Caninos : Hurlement (sans effet moteur)
	# remplacé par Groz'Yeux, la plus proche existante (plan §2.12.2).
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	for id: StringName in TRAINERS:
		var team := trainers.build_team(id, &"bulbasaur", GameRng.new(17))
		for i: int in team.size():
			var mon := team.get_at(i)
			var moves: Array = mon.moves.map(func(m: MoveSlot) -> StringName: return m.move_id)
			for move_id: StringName in moves:
				assert_true(_data.has_move(move_id), "%s : %s" % [id, move_id])
				assert_eq(_data.get_move(move_id).pending_effects, PackedStringArray(),
					"%s : %s a un effet moteur" % [id, move_id])
			if mon.species_id == &"growlithe":
				assert_eq(moves, [&"bite", &"leer", &"ember"], "Caninos sans Hurlement")
			else:
				assert_eq(moves, Array(_data.get_species(mon.species_id).moves_at(mon.level)),
					"%s : %s au niveau %d" % [id, mon.species_id, mon.level])


func test_trainer_lines_are_the_validated_lot() -> void:
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var quotes := _trainer_quotes(row[0])
		assert_eq(quotes.size(), 3, "%s : avant, défaite, après" % row[0])
		var moments := ["before", "defeated", "after"]
		for i: int in mini(moments.size(), quotes.size()):
			var dialogue := _dialogues.get_dialogue(StringName("%s_%s" % [id, moments[i]]))
			assert_not_null(dialogue, "%s_%s" % [id, moments[i]])
			if dialogue == null:
				continue
			assert_eq(dialogue.source, "res://data/dialogues/route_11.json")
			assert_eq([dialogue.speaker, dialogue.narration, dialogue.draft], [row[1], false,
				false], String(id))
			assert_eq(_texts(dialogue, 0), [quotes[i]] as Array[String], String(id))


# --- Rencontres -------------------------------------------------------------------------

func test_route_11_and_cave_tables() -> void:
	var encounters := EncounterLibrary.new(_data)
	assert_true(encounters.load_dir(), "\n".join(encounters.get_errors()))
	# Dossier 20 §5 : [espèce, poids, niveaux] ; taux des routes et du Mont Sélénite.
	var expected := {
		[&"route_11", &"grass"]: [[&"ekans", 20, 12, 15], [&"sandshrew", 20, 12, 15],
			[&"spearow", 35, 13, 17], [&"drowzee", 25, 9, 15]],
		[&"digletts_cave", &"rubble"]: [[&"diglett", 95, 15, 22], [&"dugtrio", 5, 24, 26]],
	}
	var reference := {&"grass": encounters.get_table(&"route_3", &"grass"),
		&"rubble": encounters.get_table(&"mt_moon_1f", &"rubble")}
	for key: Array in expected:
		var table := encounters.get_table(key[0], key[1])
		assert_not_null(table, str(key))
		if table == null:
			continue
		var slots: Array = []
		for slot: EncounterSlot in table.slots:
			slots.append([slot.species, slot.weight, slot.min_level, slot.max_level])
		assert_eq(slots, expected[key], str(key))
		var model: EncounterTable = reference[key[1]]
		assert_eq([table.rate, table.ramp_from, table.ramp_max],
			[model.rate, model.ramp_from, model.ramp_max], "%s : taux" % [key])
	assert_null(encounters.get_table(&"route_2_east", &"grass"), "Route 2 est : aucune")


# --- Route 11 : panneaux et Ronflex -----------------------------------------------------

func test_route_11_signs() -> void:
	assert_eq(_texts(_dialogues.get_dialogue(&"route_11_sign"), 0),
		[_sign("T-12")] as Array[String])
	assert_eq(_texts(_dialogues.get_dialogue(&"route_11_cave_sign"), 0),
		[_sign("T-10")] as Array[String])
	assert_eq(_texts(_dialogues.get_dialogue(&"route_2_east_cave_sign"), 0),
		[_sign("T-11")] as Array[String])


func test_snorlax_says_t6_once_then_t7() -> void:
	var snorlax := _dialogues.get_dialogue(&"route_11_snorlax")
	assert_true(snorlax.narration, "examen : narration")
	assert_eq(snorlax.variants.size(), 2)
	var first := snorlax.pick(_flags())
	assert_same(first, snorlax.variants[0])
	assert_eq(first.set_flags, [&"snorlax_route_11_seen"] as Array[StringName])
	assert_eq(_texts(snorlax, 0), _bubbles("T-6"))
	assert_same(snorlax.pick(_flags([&"snorlax_route_11_seen"])), snorlax.variants[1])
	assert_eq(_texts(snorlax, 1), _bubbles("T-7"))
	var used := _dialogues.get_condition_flags()
	assert_false(used.has(&"snorlax_route_11_awake"), "le réveil est un drapeau de la carte")


# --- Assistant et CS05 ------------------------------------------------------------------

func test_assistant_texts() -> void:
	var assistant := _dialogues.get_dialogue(&"route_2_east_assistant")
	assert_eq(assistant.source, "res://data/dialogues/route_2_east.json")
	assert_eq(assistant.variants.size(), 5)
	var t3 := _bubbles("T-3")
	assert_eq(t3.size(), 6, "T-3 : 3 bulles, la ligne système, 2 bulles")
	assert_eq(_texts(assistant, 0), _bubbles("T-4"))
	assert_eq(_texts(assistant, 1), t3.slice(0, 3))
	assert_eq(_texts(assistant, 2), _bubbles("T-1"))
	assert_eq(_texts(assistant, 4), _bubbles("T-2"))
	# Accord de T-2 pour une seule espèce : annexe A.3 (Q-2, validée le 2026-10-16).
	var singular := _texts(assistant, 3)
	assert_true(_annex.contains("« %s »" % singular[0]), singular[0])
	assert_eq(singular[1], _bubbles("T-2")[1])
	for i: int in [0, 1, 2, 3, 4]:
		assert_false(assistant.variants[i].draft, "variante %d validée" % i)
	var system := _dialogues.get_dialogue(&"route_2_east_assistant_hm05_system")
	assert_true(system.narration)
	assert_eq(_texts(system, 0), [t3[3].trim_prefix("*(système)* ")] as Array[String])
	var use := _dialogues.get_dialogue(&"route_2_east_assistant_hm05_use")
	assert_eq(use.speaker, assistant.speaker)
	assert_eq(_texts(use, 0), t3.slice(4, 6))
	var visitor := _dialogues.get_dialogue(&"route_2_east_visitor")
	assert_eq(_texts(visitor, 0), _bubbles("T-5"))


## Table du plan §2.6 sur les vraies données : variante selon le compte et les drapeaux.
func test_assistant_variant_by_count_and_flags() -> void:
	var assistant := _dialogues.get_dialogue(&"route_2_east_assistant")
	var met := [&"hm05_assistant_met"]
	var cases := [
		[[], 1, 2], [[], 9, 2], [met, 1, 3], [met, 2, 4], [met, 9, 4],
		[[], 10, 1], [met, 10, 1], [met, 37, 1],
		[[&"got_hm05"] + met, 9, 0], [[&"got_hm05"] + met, 10, 0], [[&"got_hm05"], 151, 0],
	]
	for row: Array in cases:
		var picked := assistant.pick(_flags(row[0]), null, row[1])
		assert_eq(assistant.variants.find(picked), row[2], "%s, %d espèces" % [row[0], row[1]])
	assert_eq(assistant.variants[1].cutscene, &"route_2_east_give_hm05")
	assert_eq(assistant.variants[2].set_flags, [&"hm05_assistant_met"] as Array[StringName])


func test_assistant_pages_with_their_tokens() -> void:
	var assistant := _dialogues.get_dialogue(&"route_2_east_assistant")
	var resolved := DialogueTokens.resolve_pages(assistant.variants[4].pages,
		DialogueTokens.caught_values(7))
	assert_eq(resolved.map(func(p: DialoguePage) -> String: return p.text),
		["Ton Pokédex compte 7 espèces capturées.", "Encore 3, et c'est à toi."])
	resolved = DialogueTokens.resolve_pages(assistant.variants[3].pages,
		DialogueTokens.caught_values(1))
	assert_eq(resolved.map(func(p: DialoguePage) -> String: return p.text),
		["Ton Pokédex compte 1 espèce capturée.", "Encore 9, et c'est à toi."])
	resolved = DialogueTokens.resolve_pages(assistant.variants[1].pages,
		DialogueTokens.caught_values(12))
	assert_eq(resolved[0].text, "Ton Pokédex compte 12 espèces !")


func test_give_hm05_scene_gives_once_then_sets_the_flag() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir(), "\n".join(cutscenes.get_errors()))
	var scene := cutscenes.get_cutscene(&"route_2_east_give_hm05")
	assert_not_null(scene)
	if scene == null:
		return
	assert_eq(scene.variants.size(), 1)
	var steps := scene.variants[0].steps
	assert_eq(steps.map(func(s: CutsceneStep) -> int: return s.kind), [
		CutsceneStep.Kind.GIVE, CutsceneStep.Kind.DIALOGUE, CutsceneStep.Kind.DIALOGUE,
		CutsceneStep.Kind.SET_FLAGS])
	assert_eq([steps[0].item_id, steps[0].count], [&"hm05", 1])
	assert_eq(steps[1].dialogue_id, &"route_2_east_assistant_hm05_system")
	assert_eq(steps[2].dialogue_id, &"route_2_east_assistant_hm05_use")
	assert_eq(steps[3].flags, [&"got_hm05"] as Array[StringName], "drapeau en dernier")
	# Rejouée après coup (application tuée) : l'objet n'est jamais donné deux fois.
	var given := _flags([&"got_hm05"])
	for i: int in 3:
		assert_false(steps[i].applies(given), "étape %d sautée une fois la CS05 reçue" % i)
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(items.get_item(&"hm05").is_hm(), "CS05 (T7)")


# --- Route 2 : barrière de FUTUR B --------------------------------------------------------

func test_futur_b_gate_from_the_east_and_its_sign() -> void:
	var gate := _dialogues.get_dialogue(&"route_2_gate_east")
	assert_eq(gate.source, "res://data/dialogues/route_2.json")
	assert_true(gate.narration)
	assert_eq(gate.variants[0].set_flags, [&"route_2_east_gate_open"] as Array[StringName])
	assert_eq(_texts(gate, 0), _bubbles("T-8"))
	var sign := _dialogues.get_dialogue(&"route_2_closed_sign")
	assert_eq(sign.variants.size(), 2)
	assert_same(sign.pick(_flags([&"route_2_east_gate_open"])), sign.variants[0])
	assert_eq(_texts(sign, 0), [_sign("T-9")] as Array[String])
	assert_same(sign.pick(_flags()), sign.variants[1])
	assert_eq(_texts(sign, 1), ["ACCÈS FERMÉ\nTravaux sur le sentier."] as Array[String],
		"texte T8 du dossier 11 tant que la barrière est fermée")


# --- Zones, Pokédex, compagnon ----------------------------------------------------------

func test_zones_wait_for_their_maps() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file(), "\n".join(zones.get_errors()))
	if not FileAccess.file_exists(PENDING_ZONES):
		# Posées avec leurs cartes (T15, T16) : le fichier d'attente a disparu.
		_check_zones(zones)
		return
	var pending: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PENDING_ZONES))
	var areas: Dictionary = pending.get("_areas", {})
	var scenes: Dictionary = pending.get("_pokedex_scenes", {})
	for key: String in ["_comment", "_areas", "_pokedex_scenes"]:
		pending.erase(key)
	var staged := ZoneLibrary.new()
	assert_true(staged.add_from_dict(pending, PENDING_ZONES), "\n".join(staged.get_errors()))
	for id: StringName in staged.get_ids():
		assert_false(zones.has_zone(id), "%s : déjà dans zones.json, à retirer d'ici" % id)
		assert_true(areas.has(String(id)), "%s : rectangle proposé" % id)
		assert_true(PokedexScene.all_scenes().has(scenes.get(String(id), "")),
			"%s : décor du Pokédex existant" % id)
	_check_zones(staged)
	assert_false(zones.get_zone(&"route_2").maps.has(&"route_2_east"), "avec la carte (T19)")


func test_companion_contexts() -> void:
	var catalog := CompanionCatalog.new()
	assert_true(catalog.load_file(), "\n".join(catalog.get_errors()))
	assert_eq(catalog.context_of(&"digletts_cave"), &"cave")
	assert_eq(catalog.context_of(&"route_2_east"), &"forest")
	assert_eq(catalog.context_of(&"route_11"), &"", "route : phrase générique")


# --- Outils ---------------------------------------------------------------------------

func _check_zones(zones: ZoneLibrary) -> void:
	var expected := {
		&"route_11": ["Route 11", ZoneData.KIND_ROUTE, "T-13", "Carmin-sur-Mer — Route 12"],
		&"digletts_cave": ["Cave Taupiqueur", ZoneData.KIND_PLACE, "T-14",
			"Route 11 — Route 2"],
	}
	for id: StringName in expected:
		var zone := zones.get_zone(id)
		assert_not_null(zone, String(id))
		if zone == null:
			continue
		var row: Array = expected[id]
		assert_eq([zone.name, zone.kind, zone.maps], [row[0], row[1], [id] as Array[StringName]])
		assert_eq([zone.description], _bubbles(row[2]), "%s : description validée" % id)
		assert_eq(zone.subtitle, row[3])
		assert_true(_annex.contains("« %s »" % zone.subtitle), "%s : sous-titre, annexe A" % id)


## Textes des pages de la variante [param index] de [param dialogue].
func _texts(dialogue: Dialogue, index: int) -> Array[String]:
	var texts: Array[String] = []
	if dialogue == null or index >= dialogue.variants.size():
		return texts
	for page: DialoguePage in dialogue.variants[index].pages:
		var text := page.text
		for token: String in TOKENS:
			text = text.replace(token, TOKENS[token])
		texts.append(text)
	return texts


## Troisième colonne de la ligne [param tag] du §16 (« | T-1 | Où | Texte | »).
func _cell(tag: String) -> String:
	for line: String in _dossier.split("\n"):
		if line.begins_with("| %s |" % tag):
			var cells := line.split(" | ")
			return cells[2].trim_suffix(" |") if cells.size() >= 3 else ""
	return ""


## Bulles de [param tag], séparées par « / » (et « · » entre deux voix, T-3).
func _bubbles(tag: String) -> Array[String]:
	var bubbles: Array[String] = []
	for voice: String in _cell(tag).split(" · "):
		for bubble: String in voice.split(" / "):
			bubbles.append(bubble.strip_edges())
	return bubbles


## Panneau de [param tag] : « **TITRE** / texte » → « TITRE\ntexte ».
func _sign(tag: String) -> String:
	return _cell(tag).replace("**", "").replace(" / ", "\n")


## Répliques avant, défaite, après de [param tag] (« avant : … · défaite : … · après : … »).
func _trainer_quotes(tag: String) -> Array[String]:
	var quotes: Array[String] = []
	for part: String in _cell(tag).split(" · "):
		quotes.append(part.get_slice(" : ", 1) if part.contains(" : ") else part)
	return quotes


## Montant écrit comme le dossier (« 1 260 »).
func _money(amount: int) -> String:
	return str(amount) if amount < 1000 else "%d %03d" % [floori(amount / 1000.0), amount % 1000]


func _flags(names: Array = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags
