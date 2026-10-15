extends GutTest
## Capacités de la Tour Pokémon (jalon 19 T3 ; `jalon-19.md` §2.12, dossier 22 §12.2) : valeurs
## actuelles, effets joués par le moteur existant (aucun code nouveau), textes du §15.7.
##
## Tirages (voir `test_battle_status_j11.gd`) : IA adverse (roll(1)), puis pour chaque Pokémon qui
## agit : statut (roll(100) s'il est paralysé), précision, critique (2 = non), aléatoire (16) ;
## effet à chance (roll(100)) ; durée du sommeil (roll(3)).

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
const DOSSIER := "res://docs/design/dossier-22-tour-pokemon.md"

## Capacité → [nom, type, catégorie, puissance, précision, PP].
const VALUES := {
	&"lick": ["Léchouille", &"ghost", MoveData.Category.PHYSICAL, 30, 100, 30],
	&"night_shade": ["Ténèbres", &"ghost", MoveData.Category.STATUS, 0, 100, 15],
	&"hypnosis": ["Hypnose", &"psychic", MoveData.Category.STATUS, 0, 60, 20],
	&"bone_club": ["Massd'Os", &"ground", MoveData.Category.PHYSICAL, 65, 85, 20],
	&"dragon_rage": ["Draco-Rage", &"dragon", MoveData.Category.STATUS, 0, 100, 10],
	&"dream_eater": ["Dévorêve", &"psychic", MoveData.Category.SPECIAL, 100, 100, 15],
	&"bonemerang": ["Osmerang", &"ground", MoveData.Category.PHYSICAL, 50, 90, 10],
	&"roar": ["Hurlement", &"normal", MoveData.Category.STATUS, 0, 0, 20],
	&"take_down": ["Bélier", &"normal", MoveData.Category.PHYSICAL, 90, 85, 20],
	&"barrage": ["Pilonnage", &"normal", MoveData.Category.PHYSICAL, 15, 85, 20],
	&"hyper_beam": ["Ultralaser", &"normal", MoveData.Category.SPECIAL, 150, 90, 5],
}
## Effets que le moteur ne joue pas encore : la capacité le dit (convention des jalons 12 à 15).
const PENDING := {
	&"dream_eater": ["dream_eater"], &"roar": ["force_switch"],
	&"take_down": ["recoil_damage"], &"hyper_beam": ["recharge"],
}
## Descriptions du lot §15.7 (validé par Kevin le 2026-10-15), par nom affiché.
const VALIDATED := [&"lick", &"night_shade", &"hypnosis", &"bone_club", &"dragon_rage"]

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _battle(mine: Pokemon, foe: Pokemon, draws: Array[int]) -> Battle:
	_rng = Kit.ScriptedRng.new(draws)
	return Kit.battle(_data, _rng, [mine], [foe])


# --- Données ----------------------------------------------------------------------------

func test_values_are_the_current_ones() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	for id: StringName in VALUES:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq([move.name, move.type, move.category, move.power, move.accuracy, move.pp],
			VALUES[id], String(id))
		assert_eq(move.source, "res://data/pokemon/moves/tower.json", String(id))
		var pending: Array = PENDING.get(id, [])
		assert_eq(Array(move.pending_effects), pending, String(id))
		assert_eq(move.description.ends_with(" Sans effet dans le moteur actuel."),
			not pending.is_empty(), String(id))
	assert_eq(_data.get_move(&"roar").priority, -6, "Hurlement agit en dernier")


func test_effects_use_existing_kinds() -> void:
	var lick := _data.get_move(&"lick").effect_of(MoveEffect.Kind.STATUS)
	assert_eq([lick.status, lick.chance], [StatusRules.PARALYSIS, 30])
	var shade := _data.get_move(&"night_shade").effect_of(MoveEffect.Kind.FIXED_DAMAGE)
	assert_eq(shade.mode, &"level")
	var hypnosis := _data.get_move(&"hypnosis").effect_of(MoveEffect.Kind.STATUS)
	assert_eq(hypnosis.status, StatusRules.SLEEP)
	assert_eq(_data.get_move(&"bone_club").effect_of(MoveEffect.Kind.FLINCH).chance, 10)
	var rage := _data.get_move(&"dragon_rage").effect_of(MoveEffect.Kind.FIXED_DAMAGE)
	assert_eq([rage.mode, rage.amount], [&"value", 40])
	var bones := _data.get_move(&"bonemerang").effect_of(MoveEffect.Kind.HITS)
	assert_eq([bones.min_hits, bones.max_hits], [2, 2])
	var barrage := _data.get_move(&"barrage").effect_of(MoveEffect.Kind.HITS)
	assert_eq([barrage.min_hits, barrage.max_hits], [2, 5])


func test_validated_descriptions_are_the_lot_word_for_word() -> void:
	var dossier := FileAccess.get_file_as_string(DOSSIER)
	for id: StringName in VALIDATED:
		var move := _data.get_move(id)
		assert_false(move.draft, String(id))
		var found := false
		for line: String in dossier.split("\n"):
			if line.begins_with("- **%s**" % move.name) \
					and line.ends_with("« %s »" % move.description):
				found = true
		assert_true(found, "%s : « %s » (dossier 22 §15.7)" % [id, move.description])


# --- Effets en combat -------------------------------------------------------------------

func test_lick_paralyses_on_30_or_less_and_is_super_effective_on_psychic() -> void:
	var foe := Kit.mon(_data, &"exeggcute", 20, [&"growl"])
	var battle := _battle(Kit.mon(_data, &"gastly", 22, [&"lick"]), foe,
		[1, 50, 2, 16, 30, 99, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(foe.status, StatusRules.PARALYSIS)
	assert_eq(Kit.find(events, K.DAMAGE, F).effectiveness, 2.0, "Spectre → Plante/Psy")
	assert_eq(_data.get_type_chart().multiplier(&"ghost", [&"psychic"]), 2.0)
	var other := Kit.mon(_data, &"exeggcute", 20, [&"growl"])
	battle = _battle(Kit.mon(_data, &"gastly", 22, [&"lick"]), other, [1, 50, 2, 16, 31, 50])
	battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(other.status, StatusRules.NONE, "31 : pas de paralysie")


func test_night_shade_deals_the_level_and_nothing_to_a_normal_type() -> void:
	var foe := Kit.mon(_data, &"exeggcute", 20, [&"growl"])
	var battle := _battle(Kit.mon(_data, &"gastly", 22, [&"night_shade"]), foe, [1, 50, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(Kit.find(events, K.DAMAGE, F).amount, 22, "niveau du lanceur")
	assert_eq(foe.hp, foe.max_hp() - 22)
	var rattata := Kit.mon(_data, &"rattata", 20, [&"growl"])
	battle = _battle(Kit.mon(_data, &"gastly", 22, [&"night_shade"]), rattata, [1, 50, 50])
	events = battle.submit(BattleAction.move(0))
	assert_null(Kit.find(events, K.DAMAGE, F), "Spectre → Normal : aucun dégât")
	assert_not_null(Kit.find(events, K.NO_EFFECT))
	assert_eq(rattata.hp, rattata.max_hp())


func test_hypnosis_puts_to_sleep_and_misses_above_60() -> void:
	var foe := Kit.mon(_data, &"rattata", 20, [&"growl"])
	var battle := _battle(Kit.mon(_data, &"gastly", 27, [&"hypnosis"]), foe, [1, 60, 2])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(foe.status, StatusRules.SLEEP)
	assert_eq(Kit.find(events, K.STATUS_INFLICTED).status, StatusRules.SLEEP)
	var other := Kit.mon(_data, &"rattata", 20, [&"growl"])
	battle = _battle(Kit.mon(_data, &"gastly", 27, [&"hypnosis"]), other, [1, 61, 50])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P), "précision 60")
	assert_eq(other.status, StatusRules.NONE)


func test_bone_club_flinches_on_10_or_less() -> void:
	var foe := Kit.mon(_data, &"exeggcute", 20, [&"growl"])
	var battle := _battle(Kit.mon(_data, &"cubone", 40, [&"bone_club"]), foe,
		[1, 50, 2, 16, 10])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(Kit.find(events, K.FLINCHED).side, F)
	assert_null(Kit.find(events, K.MOVE_USED, F), "apeuré : n'agit pas")
	var other := Kit.mon(_data, &"exeggcute", 20, [&"growl"])
	battle = _battle(Kit.mon(_data, &"cubone", 40, [&"bone_club"]), other, [1, 50, 2, 16, 11, 50])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_null(Kit.find(events, K.FLINCHED))


func test_dragon_rage_always_deals_forty() -> void:
	var foe := Kit.mon(_data, &"pidgeotto", 30, [&"growl"])
	var battle := _battle(Kit.mon(_data, &"gyarados", 22, [&"dragon_rage"]), foe, [1, 50, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(Kit.find(events, K.DAMAGE, F).amount, 40)
	assert_eq(foe.hp, foe.max_hp() - 40)
