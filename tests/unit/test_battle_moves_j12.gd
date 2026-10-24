extends GutTest
## Capacités activées par le moteur du jalon 12 (T13 ; `jalon-12.md` §2.10) : table pilotée par les
## données (chaque capacité ajoutée ou activée a son effet), lecture et refus des données, Sonicboom
## à 20 PV fixes, phrases validées (dossier 15 §20 n° 46, annexe A.4) et temps de mise en scène.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const B := BattleBeat.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

## Capacité → [genre, valeurs attendues de l'effet] (fraction, tours min, tours max, famille de
## phrases, mode, montant).
const TABLE := {
	&"leech_life": [MoveEffect.Kind.DRAIN, 0.5, 0, 0, &"", &"", 0],
	&"wrap": [MoveEffect.Kind.TRAP, 0.125, 4, 5, &"wrap", &"", 0],
	&"bind": [MoveEffect.Kind.TRAP, 0.125, 4, 5, &"bind", &"", 0],
	&"fire_spin": [MoveEffect.Kind.TRAP, 0.125, 4, 5, &"fire_spin", &"", 0],
	&"disable": [MoveEffect.Kind.DISABLE, 0.0, 4, 4, &"", &"", 0],
	&"rest": [MoveEffect.Kind.REST, 0.0, 0, 0, &"", &"", 0],
	&"self_destruct": [MoveEffect.Kind.SELF_KO, 0.0, 0, 0, &"", &"", 0],
	&"explosion": [MoveEffect.Kind.SELF_KO, 0.0, 0, 0, &"", &"", 0],
	&"sonic_boom": [MoveEffect.Kind.FIXED_DAMAGE, 0.0, 0, 0, &"", &"value", 20],
}
## Capacités du J12 (21) : genre attendu, ou rien (dégâts seuls) ; les 3 reportées gardent leur
## mention et leur effet en attente (Damoclès : contrecoup joué depuis le jalon 19 ; Buée Noire
## et Mur Lumière joués depuis la passe systèmes 2).
const POSTPONED := []  # Jalon 24 (T13) : Métronome codé ; plus rien en attente.

var _data: PokemonData
var _texts: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


func test_each_activated_move_carries_its_effect() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	for id: StringName in TABLE:
		var row: Array = TABLE[id]
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq(move.pending_effects.size(), 0, "%s : plus rien en attente" % id)
		var effect := move.effect_of(row[0])
		assert_not_null(effect, "%s : %s" % [id, MoveEffect.Kind.find_key(row[0])])
		if effect == null:
			continue
		assert_eq([effect.fraction, effect.min_turns, effect.max_turns, effect.messages,
			effect.mode, effect.amount], row.slice(1), String(id))


func test_every_j12_move_is_played_or_says_it_is_not() -> void:
	var raw := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/pokemon/moves/mt_moon.json")) as Dictionary
	assert_eq(raw.size(), 21)
	for key: String in raw:
		var move := _data.get_move(StringName(key))
		if POSTPONED.has(StringName(key)):
			assert_eq(move.pending_effects.size(), 1, key)
			assert_true(move.description.ends_with(" Sans effet dans le moteur actuel."), key)
		else:
			assert_eq(move.pending_effects.size(), 0, "%s : effet joué" % key)
			assert_false(move.description.contains("Sans effet"), key)


func test_no_move_waits_for_a_j12_kind_anymore() -> void:
	for id: StringName in _data.get_move_ids():
		for tag: String in _data.get_move(id).pending_effects:
			assert_false(tag in ["drain", "trap", "disable", "rest", "self_ko", "fixed_value"],
				"%s : %s" % [id, tag])


func test_invalid_j12_effects_are_rejected() -> void:
	var valid := [
		{ "kind": "drain", "fraction": 0.5 }, { "kind": "rest" }, { "kind": "self_ko" },
		{ "kind": "disable", "turns": 4 },
		{ "kind": "trap", "turns": [4, 5], "fraction": 0.125, "messages": "bind" },
		{ "kind": "fixed_damage", "mode": "value", "amount": 20 },
	]
	for effect: Dictionary in valid:
		assert_true(PokemonData.new().add_moves_from_dict(_move(effect), "ok"), str(effect))
	var cases: Dictionary = {
		"a": [{ "kind": "drain" }, "« fraction » est obligatoire"],
		"b": [{ "kind": "drain", "fraction": 1.5 }, "« fraction » doit être un nombre"],
		"c": [{ "kind": "trap", "turns": [5, 4], "fraction": 0.125, "messages": "wrap" },
			"« turns » vaut [min, max]"],
		"d": [{ "kind": "trap", "turns": 4, "fraction": 0.125, "messages": "wrap" },
			"« turns » vaut [min, max]"],
		"e": [{ "kind": "trap", "turns": [4, 5], "fraction": 0.125, "messages": "snap" },
			"« messages » vaut wrap, bind, fire_spin, clamp"],
		"f": [{ "kind": "disable", "turns": 0 }, "turns : entier de 1 à 8"],
		"g": [{ "kind": "rest", "turns": 2 }, "clé inconnue « turns »"],
		"h": [{ "kind": "fixed_damage", "mode": "value" }, "« amount » est obligatoire"],
		"i": [{ "kind": "fixed_damage", "mode": "level", "amount": 20 },
			"« amount » seulement pour le mode « value »"],
		"j": [{ "kind": "fixed_damage", "mode": "value", "amount": 0 }, "amount : entier de 1"],
		"k": [{ "kind": "self_ko", "chance": 50 }, "clé inconnue « chance »"],
	}
	for source: String in cases:
		var data := PokemonData.new()
		assert_false(data.add_moves_from_dict(_move(cases[source][0]), source), source)
		assert_string_contains("\n".join(data.get_errors()), cases[source][1])
	assert_push_error_count(cases.size())


func test_sonic_boom_always_deals_twenty() -> void:
	var rng := Kit.ScriptedRng.new([1, 50])
	var foe := Kit.mon(_data, &"geodude", 20, [&"defense_curl"])
	var battle := Kit.battle(_data, rng, [Kit.mon(_data, &"voltorb", 13, [&"sonic_boom"])], [foe])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(rng.remaining(), 0, "seulement la précision (90) : ni critique ni aléatoire")
	var damage := Kit.find(events, K.DAMAGE, F)
	assert_eq(damage.amount, 20, "même sur un Roche/Sol qui résiste au Normal")
	assert_eq(foe.hp, foe.max_hp() - 20)
	foe.hp = 7
	rng.push([1, 50])
	assert_eq(Kit.find(battle.submit(BattleAction.move(0)), K.DAMAGE, F).amount, 7,
		"au plus les PV restants")


func test_validated_texts() -> void:
	var expected := {
		&"drain_hp": "{pokemon} récupère des PV !",
		&"trap_wrap_started": "{pokemon} est ligoté !",
		&"trap_wrap_damaged": "{pokemon} souffre du Ligotage !",
		&"trap_ended": "{pokemon} est libéré !",
		&"move_disabled": "{move} de {pokemon} est bloquée !",
		&"disable_ended": "{move} n'est plus bloquée.",
		&"rested": "{pokemon} s'endort et récupère !",
		&"switch_reason_trapped": "Impossible de changer",
		&"move_disabled_label": "BLOQUÉE",
	}
	for id: StringName in expected:
		assert_eq(_texts.get_template(id), expected[id], String(id))
		assert_false(_texts.is_draft(id), String(id))
	assert_eq(_texts.get_template(&"trap_wrap_started", true), "{pokemon} est ligotée !")
	assert_eq(_texts.get_template(&"trap_ended", true), "{pokemon} est libérée !")
	# Messages du dossier 15 §20 n° 46, mot pour mot (« [e] » = la forme au féminin).
	var dossier := FileAccess.get_file_as_string(
		"res://docs/design/dossier-15-route-3-mont-selenite.md")
	for line: String in ["drain « {pokemon} récupère des PV ! »",
			"« {pokemon} est ligoté[e] ! » / « {pokemon} souffre du Ligotage ! » / "
				+ "« {pokemon} est libéré[e] ! »",
			"Entrave « {move} de {pokemon} est bloquée ! » / « {move} n'est plus bloquée. »",
			"Repos « {pokemon} s'endort et récupère ! »"]:
		assert_true(dossier.contains(line), line)


func test_playback_beats_of_the_new_events() -> void:
	var drained := _event(K.DRAINED_HP, P)
	assert_eq(_beat_kinds(drained), [B.HP, B.MESSAGE], "la barre remonte, puis la phrase")
	var rested := _event(K.RESTED, P)
	rested.status = StatusRules.SLEEP
	assert_eq(_beat_kinds(rested), [B.HP, B.STATUS_TAG, B.MESSAGE])
	var hurt := _event(K.TRAP_DAMAGED, F)
	hurt.move_id = &"wrap"
	assert_eq(_beat_kinds(hurt), [B.DAMAGE, B.MESSAGE])
	assert_eq(_beat_kinds(_event(K.SELF_KO, P)), [B.DAMAGE], "pas de phrase")
	var trapped := _event(K.TRAPPED, F)
	trapped.move_id = &"bind"
	assert_eq(_beat_kinds(trapped), [B.MESSAGE])
	for kind: BattleEvent.Kind in [K.TRAP_ENDED, K.MOVE_DISABLED, K.DISABLE_ENDED]:
		var event := _event(kind, F)
		event.move_id = &"tackle"
		assert_eq(_beat_kinds(event), [B.MESSAGE], K.find_key(kind))


func _event(kind: BattleEvent.Kind, side: BattleEvent.SideId) -> BattleEvent:
	var event := BattleEvent.new(kind, side)
	event.pokemon_name = "Rondoudou"
	event.max_hp = 40
	event.hp = 40
	return event


func _beat_kinds(event: BattleEvent) -> Array[BattleBeat.Kind]:
	var kinds: Array[BattleBeat.Kind] = []
	for beat: BattleBeat in BattlePlayback.beats(event, _texts, _data):
		kinds.append(beat.kind)
	return kinds


func _move(effect: Dictionary) -> Dictionary:
	return { "testy": { "name": "Essai", "type": "normal", "category": "physical",
		"power": 20, "accuracy": 100, "pp": 10, "description": "…", "effects": [effect] } }
