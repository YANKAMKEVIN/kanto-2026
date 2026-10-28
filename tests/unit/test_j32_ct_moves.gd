extends GutTest
## Lot 32N (N-22) : les trois capacités créées pour les CT02, CT41 et CT48. Coupe-Vent réutilise
## le système « deux tours » de Tunnel, Éboulement l'effet « apeurer », E-Coque le soin de moitié
## de Soin. Valeurs de Rouge/Bleu ; les textes sont en brouillon [D].

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _texts: BattleText
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


func _wild(moves: Array, draws: Array) -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	var mine := Kit.mon(_data, &"rattata", 30, moves)
	var foe := Kit.mon(_data, &"rattata", 10, [&"tackle"])
	return Kit.battle(_data, _rng, [mine], [foe])


func _lines(events: Array[BattleEvent]) -> String:
	var lines: PackedStringArray = []
	for event: BattleEvent in events:
		lines.append_array(_texts.lines(event, _data))
	return "\n".join(lines)


func test_the_three_moves_are_loaded_with_rb_values() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	var razor := _data.get_move(&"razor_wind")
	assert_eq([razor.name, razor.power, razor.accuracy, razor.pp], ["Coupe-Vent", 80, 75, 10])
	assert_eq(razor.charge_effect().texts, &"razor_wind")
	assert_false(razor.charge_effect().invulnerable)
	var slide := _data.get_move(&"rock_slide")
	assert_eq([slide.name, slide.power, slide.accuracy, slide.pp], ["Éboulement", 75, 90, 10])
	assert_eq(slide.effect_of(MoveEffect.Kind.FLINCH).chance, 30)
	var egg := _data.get_move(&"soft_boiled")
	assert_eq([egg.name, egg.pp], ["E-Coque", 10])
	assert_eq(egg.effect_of(MoveEffect.Kind.HEAL).fraction, 0.5)
	assert_ne(egg.name, _data.get_move(&"recover").name, "deux capacités, deux noms")
	for id: StringName in [&"razor_wind", &"rock_slide", &"soft_boiled"]:
		assert_eq(_data.get_move(id).pending_effects.size(), 0, String(id))


func test_the_tm_numbers_point_at_existing_moves() -> void:
	var tms: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/pokemon/tm_compatibility.json"))["tms"]
	for number: String in tms:
		if number == "31":
			continue
		assert_not_null(_data.get_move(StringName(tms[number])), "CT%s : %s" % [number, tms[number]])


func test_razor_wind_charges_then_strikes() -> void:
	var battle := _wild([&"razor_wind"], [1, Kit.HIT, 1, Kit.HIT, Kit.HIT])
	var first := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(first, K.CHARGE_STARTED, P))
	assert_true(_lines(first).contains("soulève un tourbillon !"))
	assert_null(Kit.find(first, K.DAMAGE, F), "aucun dégât au tour de charge")
	var second := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(second, K.DAMAGE, F), "frappe au second tour")


func test_soft_boiled_heals_half_the_max_hp() -> void:
	var battle := _wild([&"soft_boiled"], [1, Kit.HIT])
	var mine := battle.get_player_side().active.pokemon
	mine.hp = 1
	var healed := Kit.find(battle.submit(BattleAction.move(0)), K.HEALED, P)
	assert_not_null(healed)
	assert_eq(healed.amount, floori(mine.max_hp() / 2.0))
