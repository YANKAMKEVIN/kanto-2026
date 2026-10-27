extends GutTest
## Poison grave branché dans le moteur (jalon 23, T18 ; `jalon-23.md` §2.12, dossier 26 §10.4,
## N-14) : Toxik (capacité et CT06), dégâts N/16 croissants en fin de tour ([ToxicRules]),
## remise à zéro au changement de Pokémon et en fin de combat (reste un poison simple),
## étiquette « PSN+ », IA « smart » (Toxik ne vise ni un Pokémon déjà empoisonné ni un type Poison).
##
## IV 0 ; combat sauvage : Smogogo (Nv. 43, Toxik et Boul'Armure) contre Rattata puis Roucool
## (Nv. 40, Boul'Armure). Boul'Armure ne tire rien ; un tour = l'IA de Smogogo (roll(2) : 1 =
## Toxik, 2 = Boul'Armure), puis la précision de Toxik (roll(100)) s'il la lance.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _battle(mine: Array) -> Battle:
	_rng = Kit.ScriptedRng.new()
	return Kit.battle(_data, _rng, mine,
		[Kit.mon(_data, &"weezing", 43, [&"toxic", &"defense_curl"])])


func _rattata() -> Pokemon:
	return Kit.mon(_data, &"rattata", 40, [&"defense_curl"])


func _pidgey() -> Pokemon:
	return Kit.mon(_data, &"pidgey", 40, [&"defense_curl"])


## Un tour où Smogogo lance Toxik (et touche) pendant que le joueur fait [param action].
func _toxic_turn(battle: Battle, action: BattleAction) -> Array[BattleEvent]:
	_rng.push([1, 50])
	return battle.submit(action)


## Un tour où Smogogo se met en boule.
func _quiet_turn(battle: Battle, action: BattleAction) -> Array[BattleEvent]:
	_rng.push([2])
	return battle.submit(action)


func _expected(pokemon: Pokemon, counter: int) -> int:
	return maxi(floori(pokemon.max_hp() * counter / 16.0), 1)


# --- Données ----------------------------------------------------------------------------------

func test_toxic_move_and_tm06_data() -> void:
	var toxic := _data.get_move(&"toxic")
	assert_not_null(toxic)
	assert_eq([toxic.name, toxic.type, toxic.category, toxic.accuracy, toxic.pp],
		["Toxik", &"poison", MoveData.Category.STATUS, 85, 10])
	assert_eq(toxic.description, "Un poison qui s'aggrave à chaque tour.", "A-25")
	assert_eq(toxic.effects.size(), 1)
	assert_eq([toxic.effects[0].kind, toxic.effects[0].status, toxic.effects[0].toxic],
		[MoveEffect.Kind.STATUS, StatusRules.POISON, true])
	assert_eq(toxic.pending_effects.size(), 0)
	assert_false(_data.get_move(&"poison_powder").effects[0].toxic, "Poudre Toxik : poison simple")
	var items := ItemLibrary.new()
	items.load_dir()
	var tm06 := items.get_item(&"tm06")
	assert_not_null(tm06)
	assert_eq([tm06.name, tm06.description], ["CT06 — Toxik", "Empoisonne gravement."], "texte 59")
	assert_eq(tm06.category, ItemData.Category.TM)
	assert_eq(tm06.teaches, &"toxic")


func test_toxic_flag_is_refused_without_poison() -> void:
	var data := PokemonData.new()
	var ok := data.add_moves_from_dict({"bad": {
		"name": "X", "type": "poison", "category": "status", "accuracy": 85, "pp": 10,
		"effects": [{"kind": "status", "status": "sleep", "toxic": true}],
		"description": "X"}}, "test")
	assert_false(ok)
	assert_push_error_count(1)


# --- Combat -----------------------------------------------------------------------------------

func test_weezing_toxic_deals_growing_damage() -> void:
	var rattata := _rattata()
	var battle := _battle([rattata])
	var events := _toxic_turn(battle, BattleAction.move(0))
	var inflicted := Kit.find(events, K.STATUS_INFLICTED, P)
	assert_not_null(inflicted, "Toxik touche")
	assert_eq(inflicted.status, StatusRules.TOXIC, "étiquette « PSN+ »")
	assert_eq(rattata.status, StatusRules.POISON, "le Pokémon garde un poison (sauvegarde)")
	assert_true(battle.get_player_side().active.toxic)
	var texts := BattleText.new()
	texts.load_file()
	assert_eq(Array(texts.lines(inflicted, _data)), ["Rattata est gravement empoisonné !"])
	var hp := rattata.max_hp()
	for counter: int in range(1, 4):
		if counter > 1:
			events = _quiet_turn(battle, BattleAction.move(0))
		var damaged := Kit.find(events, K.STATUS_DAMAGED, P)
		assert_not_null(damaged, "tour %d" % counter)
		if damaged == null:
			continue
		assert_eq(damaged.status, StatusRules.TOXIC)
		assert_eq(damaged.amount, _expected(rattata, counter), "%d/16" % counter)
		hp -= damaged.amount
		assert_eq(rattata.hp, hp)
		assert_eq(battle.get_player_side().active.toxic_counter, counter)
		assert_eq(Array(texts.lines(damaged, _data)), ["Rattata souffre du poison !"])
	assert_eq(_rng.remaining(), 0)
	assert_push_error_count(0)


func test_switch_resets_to_simple_poison() -> void:
	var rattata := _rattata()
	var battle := _battle([rattata, _pidgey()])
	_toxic_turn(battle, BattleAction.move(0))
	_quiet_turn(battle, BattleAction.move(0))
	assert_eq(battle.get_player_side().active.toxic_counter, 2)
	var events := _quiet_turn(battle, BattleAction.switch_to(1))
	assert_null(Kit.find(events, K.STATUS_DAMAGED, P), "Roucool n'est pas empoisonné")
	assert_eq(rattata.status, StatusRules.POISON, "Rattata reste empoisonné dans l'équipe")
	events = _quiet_turn(battle, BattleAction.switch_to(0))
	var damaged := Kit.find(events, K.STATUS_DAMAGED, P)
	assert_not_null(damaged)
	assert_false(battle.get_player_side().active.toxic, "plus de poison grave")
	if damaged != null:
		assert_eq(damaged.status, StatusRules.POISON, "poison simple")
		assert_eq(damaged.amount, maxi(floori(rattata.max_hp() / 8.0), 1), "1/8")
	assert_eq(_rng.remaining(), 0)
	assert_push_error_count(0)


func test_end_of_battle_keeps_a_simple_poison() -> void:
	var rattata := _rattata()
	var battle := _battle([rattata])
	_toxic_turn(battle, BattleAction.move(0))
	_quiet_turn(battle, BattleAction.move(0))
	assert_eq(rattata.status, StatusRules.POISON)
	# Combat suivant avec le même Pokémon : poison simple, pas de compteur.
	var next := _battle([rattata])
	assert_false(next.get_player_side().active.toxic)
	assert_eq(next.get_player_side().active.toxic_counter, ToxicRules.OFF)
	var events := _quiet_turn(next, BattleAction.move(0))
	var damaged := Kit.find(events, K.STATUS_DAMAGED, P)
	assert_not_null(damaged)
	if damaged != null:
		assert_eq(damaged.status, StatusRules.POISON)
		assert_eq(damaged.amount, maxi(floori(rattata.max_hp() / 8.0), 1))
	assert_push_error_count(0)


func test_toxic_on_an_already_poisoned_target_is_unchanged() -> void:
	var rattata := _rattata()
	rattata.status = StatusRules.POISON
	var battle := _battle([rattata])
	var events := _toxic_turn(battle, BattleAction.move(0))
	assert_not_null(Kit.find(events, K.STATUS_UNCHANGED, P))
	assert_false(battle.get_player_side().active.toxic, "un poison simple ne s'aggrave pas")
	assert_push_error_count(0)


func test_cured_toxic_is_forgotten() -> void:
	var rattata := _rattata()
	var battle := _battle([rattata])
	_toxic_turn(battle, BattleAction.move(0))
	rattata.cure_status()
	var events := _quiet_turn(battle, BattleAction.move(0))
	assert_null(Kit.find(events, K.STATUS_DAMAGED, P))
	assert_false(battle.get_player_side().active.toxic)
	assert_push_error_count(0)


# --- Interface et IA --------------------------------------------------------------------------

func test_psn_plus_label() -> void:
	assert_eq(StatusView.text_of(StatusRules.TOXIC), "PSN+", "A-27")
	assert_eq(StatusView.text_of(StatusRules.POISON), "PSN")
	assert_eq(StatusView.badge_type(StatusRules.TOXIC), &"poison")
	assert_eq(StatusView.color("PSN+"), StatusView.color("PSN"))
	assert_false(StatusRules.is_known(StatusRules.TOXIC), "jamais un statut sauvegardé")


func test_smart_ai_skips_toxic_on_poisoned_or_poison_targets() -> void:
	var toxic := _data.get_move(&"toxic")
	var chart := _data.get_type_chart()
	var weezing := Kit.mon(_data, &"weezing", 43, [&"toxic"])
	var own := Battler.new(weezing, _data.get_species(&"weezing").types)
	var healthy := _rattata()
	var target := Battler.new(healthy, _data.get_species(&"rattata").types)
	assert_gt(BattleAI.score_move(toxic, own, target, chart, 0), 0.0, "cible saine")
	healthy.status = StatusRules.POISON
	assert_eq(BattleAI.score_move(toxic, own, target, chart, 0), 0.0, "déjà empoisonnée")
	var koffing := Kit.mon(_data, &"koffing", 37, [&"tackle"])
	var poison_type := Battler.new(koffing, _data.get_species(&"koffing").types)
	assert_eq(BattleAI.score_move(toxic, own, poison_type, chart, 0), 0.0, "type Poison")


## Clôture du J23 (QA 23E : « Smogogo a préféré Détritus ») puis tirage de statut (décision de
## Kevin, 2026-10-27) : le vrai Smogogo de Koga (Purédpois, Détritus, Toxik, Destruction) sous
## l'IA « smart ». Par la note, Détritus (65 × 1,5 STAB) l'emporte toujours sur Toxik
## (40 × 85 %) ; Toxik pas encore joué sur une cible saine : roll(3) = 1 le joue (règle 0).
## Jamais sur une cible déjà empoisonnée ou de type Poison (note nulle : aucun tirage), jamais
## une deuxième fois par le tirage.
func test_kogas_weezing_toxic_by_status_draw() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var team := trainers.build_team(&"fuchsia_gym_koga", &"charmander", GameRng.new(1))
	var weezing := team.get_at(3)
	assert_eq(weezing.species_id, &"weezing")
	assert_eq(weezing.level, 43)
	var ids: Array[StringName] = []
	for slot: MoveSlot in weezing.moves:
		ids.append(slot.move_id)
	assert_eq(ids, [&"smog", &"sludge", &"toxic", &"self_destruct"] as Array[StringName])
	var ai := trainers.get_trainer(&"fuchsia_gym_koga").make_ai()
	assert_eq(ai.kind, BattleAI.SMART)
	var own := BattleSide.new(team, false, "Koga", ai)
	own.send_out(weezing, _data)
	var rattata := _rattata()
	var foe := _foe_side(rattata)
	var rng := Kit.ScriptedRng.new([2])
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 1, "tirage manqué : Détritus")
	rattata.status = StatusRules.POISON
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 1, "déjà empoisonnée : Détritus")
	rattata.status = StatusRules.NONE
	rng.push([1])
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 2, "tirage réussi : Toxik")
	assert_eq(ai.times_used(weezing, &"toxic"), 1)
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 1, "Toxik déjà joué : Détritus")
	weezing.moves[1].pp = 0
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 2, "Détritus épuisé : Toxik (note)")
	assert_eq(rng.remaining(), 0)
	assert_eq(rng.calls, 2, "un tirage de statut seulement quand Toxik est neuf et utile")
	var koffing := Kit.mon(_data, &"koffing", 37, [&"tackle"])
	var fresh_ai := trainers.get_trainer(&"fuchsia_gym_koga").make_ai()
	var own_fresh := BattleSide.new(team, false, "Koga", fresh_ai)
	weezing.moves[1].pp = 10
	own_fresh.send_out(weezing, _data)
	var poison_rng := Kit.ScriptedRng.new()
	assert_eq(fresh_ai.choose(own_fresh, _foe_side(koffing), poison_rng, _data).move_index, 1,
		"type Poison : Détritus, aucun tirage")
	assert_eq(poison_rng.calls, 0)


## Toxik de Koga au premier tour, sur une cible saine : environ une fois sur trois (graines
## 0..599, une IA neuve par combat).
func test_kogas_weezing_toxic_about_one_in_three() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var team := trainers.build_team(&"fuchsia_gym_koga", &"charmander", GameRng.new(1))
	var weezing := team.get_at(3)
	var foe := _foe_side(_rattata())
	var toxic := 0
	var runs := 600
	for seed_value: int in runs:
		var ai := trainers.get_trainer(&"fuchsia_gym_koga").make_ai()
		var own := BattleSide.new(team, false, "Koga", ai)
		own.send_out(weezing, _data)
		if ai.choose(own, foe, GameRng.new(seed_value), _data).move_index == 2:
			toxic += 1
	assert_between(float(toxic) / runs, 0.28, 0.39, "Toxik %d / %d" % [toxic, runs])


func _foe_side(pokemon: Pokemon) -> BattleSide:
	var party := Party.new()
	party.add(pokemon)
	var side := BattleSide.new(party, true)
	side.send_out(pokemon, _data)
	return side
