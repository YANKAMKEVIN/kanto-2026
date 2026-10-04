extends GutTest
## BattleViews (jalon-04.md §14.2) : vues de l'interface de combat construites depuis le
## journal et les données (cartes d'information, cartes de capacités, actions du premier
## combat).

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func test_card_of_the_player_shows_hp_numbers_and_the_foe_does_not() -> void:
	var event := BattleEvent.new(BattleEvent.Kind.SENT_OUT, BattleEvent.SideId.PLAYER)
	event.pokemon_name = "Salamèche"
	event.gender = Pokemon.Gender.FEMALE
	event.level = 5
	event.hp = 18
	event.max_hp = 19
	var own := BattleViews.card(event)
	assert_true(own.is_valid())
	assert_eq(own.display_name, "Salamèche")
	assert_eq(own.gender, BattleCardView.Gender.FEMALE)
	assert_eq(own.level, 5)
	assert_eq(own.hp, 18)
	assert_eq(own.max_hp, 19)
	assert_true(own.show_hp_numbers, "PV chiffrés du joueur (dossier 05 §5)")
	event.side = BattleEvent.SideId.FOE
	assert_false(BattleViews.card(event).show_hp_numbers, "jamais pour l'adversaire")


func test_genders() -> void:
	assert_eq(BattleViews.card_gender(Pokemon.Gender.MALE), BattleCardView.Gender.MALE)
	assert_eq(BattleViews.card_gender(Pokemon.Gender.FEMALE), BattleCardView.Gender.FEMALE)
	assert_eq(BattleViews.card_gender(Pokemon.Gender.NONE), BattleCardView.Gender.NONE)


func test_moves_of_a_level_5_charmander() -> void:
	var pokemon := PokemonFactory.create(_data, &"charmander", 5, GameRng.new(1))
	pokemon.moves[0].use()
	var views := BattleViews.moves(pokemon, _data)
	assert_eq(views.size(), 2, "Griffe et Rugissement (décision de Kevin n° 3)")
	assert_eq(views[0].display_name, "Griffe")
	assert_eq(views[0].type_id, &"normal")
	assert_eq(views[0].type_name, "Normal")
	assert_eq(views[0].category, BattleMoveView.Category.PHYSICAL)
	assert_eq(views[0].pp, views[0].max_pp - 1, "PP restants")
	assert_eq(views[0].power, 40)
	assert_eq(views[0].accuracy, 100)
	assert_false(views[0].description.is_empty())
	assert_eq(views[1].display_name, "Rugissement")
	assert_eq(views[1].category, BattleMoveView.Category.STATUS)
	assert_eq(views[1].power, 0)
	for view: BattleMoveView in views:
		assert_true(view.is_valid())


func test_move_categories() -> void:
	assert_eq(BattleViews.move_category(MoveData.Category.SPECIAL),
		BattleMoveView.Category.SPECIAL)
	assert_eq(BattleViews.move_category(MoveData.Category.STATUS),
		BattleMoveView.Category.STATUS)
	assert_eq(BattleViews.move_category(MoveData.Category.PHYSICAL),
		BattleMoveView.Category.PHYSICAL)


## Décision de Kevin n° 12 : ATTAQUER seul actif ; SAC, ÉQUIPE, FUITE atténués.
func test_first_battle_actions_attack_only() -> void:
	for action: StringName in BattleViews.TRAINER_BATTLE_ACTIONS:
		assert_true(ActionGrid.ACTIONS.has(action), "clé de la grille : %s" % action)
	assert_true(BattleViews.TRAINER_BATTLE_ACTIONS.get(ActionGrid.ATTACK, false))
	for action: StringName in [ActionGrid.BAG, ActionGrid.TEAM, ActionGrid.RUN]:
		assert_false(BattleViews.TRAINER_BATTLE_ACTIONS.get(action, false), str(action))


## Jalons 5B et 5D : contre un sauvage, ATTAQUER, SAC (les Balls) et FUITE actifs ; ÉQUIPE
## atténué. Le combat de dresseur garde SAC atténué.
func test_wild_battle_actions_attack_bag_and_run() -> void:
	for action: StringName in BattleViews.WILD_BATTLE_ACTIONS:
		assert_true(ActionGrid.ACTIONS.has(action), "clé de la grille : %s" % action)
	assert_true(BattleViews.WILD_BATTLE_ACTIONS.get(ActionGrid.ATTACK, false), "ATTAQUER actif")
	assert_true(BattleViews.WILD_BATTLE_ACTIONS.get(ActionGrid.BAG, false), "SAC actif")
	assert_true(BattleViews.WILD_BATTLE_ACTIONS.get(ActionGrid.RUN, false), "FUITE active")
	assert_false(BattleViews.WILD_BATTLE_ACTIONS.get(ActionGrid.TEAM, false), "ÉQUIPE atténué")
	assert_false(BattleViews.TRAINER_BATTLE_ACTIONS.get(ActionGrid.BAG, false),
		"SAC reste atténué contre un dresseur")


## Sac de combat : les Balls sont utilisables, la Potion est rangée mais jamais proposée (son
## usage arrive au jalon 6) ; nom au singulier, quantité du Sac, catégorie des données.
func test_bag_entries_offer_the_balls_and_the_potion() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir(), "objets chargés")
	var bag := Bag.new()
	bag.add(&"poke_ball", 5)
	bag.add(&"potion", 2)
	var views := BattleViews.bag_entries(bag, items)
	assert_eq(views.size(), 2, "une entrée par objet du Sac")
	var by_id: Dictionary[StringName, BagEntryView] = {}
	for view: BagEntryView in views:
		by_id[view.item_id] = view
	var ball := by_id[&"poke_ball"]
	assert_eq(ball.display_name, "Poké Ball", "nom au singulier")
	assert_eq(ball.quantity, 5)
	assert_eq(ball.category_id, &"ball")
	assert_true(ball.usable, "la Ball est utilisable")
	assert_true(ball.is_displayable())
	var potion := by_id[&"potion"]
	assert_eq(potion.category_id, &"heal")
	assert_true(potion.usable, "la Potion est utilisable en combat (jalon 6)")
	assert_true(potion.targets_pokemon, "elle ouvre le choix du Pokémon")
	assert_true(potion.is_displayable())


func test_bag_entries_skip_unknown_items_and_handle_no_bag() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	var bag := Bag.new()
	bag.add(&"mystery", 1)
	assert_eq(BattleViews.bag_entries(bag, items).size(), 0, "objet inconnu omis")
	assert_push_error("objet inconnu")
	assert_eq(BattleViews.bag_entries(null, items).size(), 0)
	assert_eq(BattleViews.bag_entries(Bag.new(), null).size(), 0)


func test_offered_move_has_full_pp_and_unknown_move_is_refused() -> void:
	var view := BattleViews.offered_move(&"leech_seed", _data)
	assert_not_null(view)
	assert_true(view.is_valid())
	assert_eq(view.display_name, "Vampigraine")
	assert_eq(view.pp, view.max_pp, "PP pleins : jamais servie")
	assert_eq(view.max_pp, _data.get_move(&"leech_seed").pp)
	assert_eq(view.category, BattleMoveView.Category.STATUS)
	assert_null(BattleViews.offered_move(&"nope", _data))
	assert_push_error("capacité inconnue")
