extends GutTest
## Chapitre Johto, JOH0 lot C (`jalon-joh0.md` §2.7 à §2.10) : le lien (pas, compagnon, combat),
## les évolutions « bond » (seuil 70, moment lu par une source statique), l'œuf (création,
## phrase, exclusions de l'équipe, du combat, du compagnon et du Stockage, éclosion), l'Exp ×1,5
## de l'acte 1 et l'objet du terminal d'échange.

const GameStateScript := preload("res://game/autoload/game_state.gd")

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func after_each() -> void:
	Evolution.set_current_period(&"")


func _mon(species: StringName, level: int, seed: int = 1) -> Pokemon:
	var mon := PokemonFactory.create(_data, species, level, GameRng.new(seed))
	mon.ensure_uid()
	return mon


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.new_game(3)
	return state


# --- Lien : pas ----------------------------------------------------------------------------------

func test_steps_give_a_point_every_256_steps_and_one_more_to_the_companion() -> void:
	var party := Party.new()
	var lead := _mon(&"pidgey", 10, 1)
	var buddy := _mon(&"rattata", 10, 2)
	party.add(lead)
	party.add(buddy)
	lead.set_bond(20)
	buddy.set_bond(20)
	var counter := BondStepCounter.new()
	for i: int in BondRules.STEPS_PER_POINT - 1:
		var step := counter.on_player_moved(party, buddy.uid, true)
		assert_false(step["bond"])
	assert_eq(lead.bond, 20)
	var last := counter.on_player_moved(party, buddy.uid, true)
	assert_true(last["bond"], "256e pas")
	assert_eq(lead.bond, 21)
	assert_eq(buddy.bond, 22, "le compagnon gagne +1 de plus")
	assert_eq(counter.counted(), 256)
	assert_eq(counter.since_bond(), 0)
	counter.on_player_moved(party, buddy.uid, false)
	assert_eq(counter.counted(), 256, "un pas scripté ne compte pas")
	assert_false(counter.on_player_moved(Party.new(), "", true)["bond"], "équipe vide : rien")


# --- Lien : combat ----------------------------------------------------------------------------

func test_battle_bond_gains_for_participants_and_losses_for_each_ko() -> void:
	var party := Party.new()
	for species: StringName in [&"pidgey", &"rattata", &"spearow"]:
		var mon := _mon(species, 10)
		mon.set_bond(50)
		party.add(mon)
	BondRules.apply_battle(party, true, [0, 2], [1, 1])
	assert_eq(party.get_at(0).bond, 52)
	assert_eq(party.get_at(1).bond, 44, "deux K.O. : −6")
	assert_eq(party.get_at(2).bond, 52)
	BondRules.apply_battle(party, false, [0], [0])
	assert_eq(party.get_at(0).bond, 49, "défaite : pas de gain, la perte reste")
	var egg := _mon(&"togepi" if _data.has_species(&"togepi") else &"pidgey", 5)
	egg.egg_steps = 100
	egg.set_bond(50)
	party.add(egg)
	BondRules.apply_battle(party, true, [3], [3, 9])
	assert_eq(egg.bond, 50, "un œuf ne bouge pas ; un index hors équipe est ignoré")
	BondRules.apply_battle(null, true, [0], [0])
	assert_eq(BondRules.tier(29), 0)
	assert_eq(BondRules.tier(30), 1)
	assert_eq(BondRules.tier(70), 2)
	assert_eq(BondRules.tier(90), 3)


# --- Évolutions par lien ---------------------------------------------------------------------

func test_bond_evolution_needs_the_threshold_and_the_period_of_the_rule() -> void:
	# Règle posée en test sur Roucool (les règles de Johto arrivent avec les données du lot D).
	var species := _data.get_species(&"pidgey")
	var saved := species.evolutions.duplicate()
	var rule := EvolutionRule.new()
	rule.into = &"pidgeot"
	rule.method = EvolutionRule.Method.BOND
	species.evolutions = [rule]
	var mon := _mon(&"pidgey", 10)
	mon.set_bond(69)
	assert_eq(Evolution.level_up_target(mon, _data), &"", "sous le seuil")
	mon.set_bond(70)
	assert_eq(Evolution.level_up_target(mon, _data), &"pidgeot", "au seuil, sans moment exigé")
	rule.periods = [&"night"]
	assert_eq(Evolution.level_up_target(mon, _data), &"", "sans heure (Kanto) : non")
	assert_eq(Evolution.level_up_target(mon, _data, &"day"), &"")
	assert_eq(Evolution.level_up_target(mon, _data, &"night"), &"pidgeot")
	Evolution.set_current_period(&"night")
	assert_eq(Evolution.level_up_target(mon, _data), &"pidgeot", "la valeur statique")
	assert_eq(Evolution.current_period(), &"night")
	Evolution.set_current_period(&"")
	assert_eq(Evolution.current_period(), &"")
	var party := Party.new()
	party.add(mon)
	var found := Evolution.candidates(party, [0], _data)
	assert_eq(found.size(), 0, "fin de combat : même règle")
	Evolution.set_current_period(&"night")
	assert_eq(Evolution.candidates(party, [0], _data).size(), 1)
	species.evolutions = saved


# --- Œuf ---------------------------------------------------------------------------------------

func test_an_egg_is_created_hinted_excluded_and_hatches() -> void:
	var state := _state()
	var egg := EggRules.create(_data, &"pidgey", 500, GameRng.new(4))
	assert_not_null(egg)
	assert_true(egg.is_egg())
	assert_eq(egg.level, 5)
	assert_eq(egg.egg_steps, 500)
	assert_null(EggRules.create(_data, &"missingno"))
	assert_null(EggRules.create(_data, &"pidgey", 0))
	assert_eq(EggRules.hint_text(1500), EggRules.HINT_CALM)
	assert_eq(EggRules.hint_text(600), EggRules.HINT_MOVING)
	assert_eq(EggRules.hint_text(12), EggRules.HINT_SOON)
	# Équipe : compte dans les 6, jamais apte, jamais compagnon.
	var lead := _mon(&"rattata", 8)
	state.party.add(egg)
	state.party.add(lead)
	assert_eq(state.party.size(), 2)
	assert_same(state.party.first_able(), lead, "l'œuf est sauté")
	assert_false(state.set_companion(egg), "un œuf n'est pas compagnon")
	assert_true(state.set_companion(lead))
	var view := DashboardViews.member(egg, 0, _data)
	assert_eq(view.display_name, EggRules.NAME)
	assert_true(view.egg)
	assert_eq(view.status_text, EggRules.HINT_MOVING)
	# Stockage : ni libéré, ni favori ; déposable.
	var storage := PokemonStorage.new()
	assert_eq(StorageRules.release(state.party, storage, StorageRules.Place.PARTY, 0).status,
		StorageRules.Status.EGG)
	assert_eq(StorageRules.toggle_favorite(state.party, storage, StorageRules.Place.PARTY,
		0).status, StorageRules.Status.EGG)
	assert_false(egg.favorite)
	# Seul avec l'œuf : Roucool est le « dernier Pokémon apte ».
	assert_eq(StorageRules.keep_status(state.party, 1), StorageRules.Status.LAST_ABLE)
	# Pas : décompte, puis prêt à éclore (1 pas restant jusqu'à l'éclosion).
	var counter := BondStepCounter.new()
	for i: int in 499:
		assert_true((counter.on_player_moved(state.party, "", true)["hatched"] as Array).is_empty())
	var last := counter.on_player_moved(state.party, "", true)
	assert_eq(last["hatched"], [egg] as Array[Pokemon])
	assert_true(EggRules.is_ready(egg))
	assert_true(egg.is_egg(), "encore un œuf jusqu'à l'éclosion jouée")
	assert_true(EggRules.hatch(egg, state, &"goldenrod_city"))
	assert_false(egg.is_egg())
	assert_eq(egg.origin, Pokemon.Origin.EGG)
	assert_eq(egg.met_map, &"goldenrod_city")
	assert_eq(egg.bond, BondRules.START_GIFT)
	assert_true(state.pokedex.is_caught(&"pidgey"), "capturé au Pokédex à l'éclosion")
	assert_false(EggRules.hatch(egg, state, &"x"), "plus un œuf")
	assert_same(state.party.first_able(), egg, "apte désormais")


func test_an_egg_cannot_be_sent_to_battle_and_gains_no_exp() -> void:
	var party := Party.new()
	var lead := _mon(&"charmander", 20)
	var egg := EggRules.create(_data, &"pidgey", 2000, GameRng.new(2))
	party.add(lead)
	party.add(egg)
	var foes := Party.new()
	foes.add(_mon(&"rattata", 3, 9))
	var rules := BattleRules.for_wild()
	rules.exp_all = true
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""), _data,
		GameRng.new(1), rules)
	battle.start()
	assert_eq(battle.check_switch(1), Battle.SwitchCheck.EGG)
	assert_false(battle.is_legal(BattleAction.switch_to(1)), "pas d'envoi d'un œuf")
	var texts := BattleText.new()
	texts.load_file()
	var views := BattleViews.party(battle, _data, texts)
	assert_false(views[1].can_send)
	assert_eq(views[1].reason, "Un œuf ne peut pas combattre.")
	var before := egg.experience
	for i: int in 6:
		if battle.get_outcome() != Battle.Outcome.NONE:
			break
		battle.submit(BattleAction.move(0))
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	assert_eq(egg.experience, before, "Multi Exp : l'œuf ne reçoit rien")
	assert_gt(lead.experience, 0)


# --- Exp ×1,5 et objet d'échange ---------------------------------------------------------------

func test_act1_exp_bonus_follows_the_flag() -> void:
	var flags := StoryFlags.new()
	assert_eq(TeamConfiscation.exp_bonus(flags), 1.0)
	flags.set_flag(TeamConfiscation.ACT1)
	assert_eq(TeamConfiscation.exp_bonus(flags), 1.5)
	assert_eq(TeamConfiscation.exp_bonus(null), 1.0)


func test_a_trade_rule_with_an_item_needs_the_item_and_consumes_it() -> void:
	# Règle posée en test sur Gravalanch (Onix + Peau Métal arrive avec les données du lot D).
	var species := _data.get_species(&"graveler")
	var rule: EvolutionRule = species.evolutions[0]
	assert_eq(rule.method, EvolutionRule.Method.TRADE)
	rule.item = &"metal_coat"
	var party := Party.new()
	party.add(_mon(&"graveler", 30))
	var bag := Bag.new()
	assert_eq(LocalTrade.trade_target(party.get_at(0), _data, bag), &"", "sans l'objet : rien")
	assert_eq(LocalTrade.candidates(party, _data, bag), [] as Array[int])
	assert_eq(LocalTrade.execute(party, 0, _data, null, &"", "", "", bag)["status"],
		LocalTrade.Status.INCOMPATIBLE)
	bag.add(&"metal_coat", 2)
	assert_eq(LocalTrade.trade_target(party.get_at(0), _data, bag), &"golem")
	assert_eq(LocalTrade.trade_item(party.get_at(0), _data, bag), &"metal_coat")
	assert_eq(LocalTrade.candidates(party, _data, bag), [0] as Array[int])
	var result := LocalTrade.execute(party, 0, _data, null, &"", "", "", bag)
	assert_eq(result["status"], LocalTrade.Status.DONE)
	assert_eq(result["item"], &"metal_coat")
	assert_eq(bag.count_of(&"metal_coat"), 1, "un objet consommé avec l'évolution")
	assert_eq(party.get_at(0).species_id, &"golem")
	rule.item = &""
