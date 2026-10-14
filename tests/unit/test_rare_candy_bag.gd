extends GutTest
## Super Bonbon dans le Sac (jalon 14, T18b ; `jalon-14.md` §2.6, dossier 17 §5) : onglet
## AVENTURE, UTILISER hors combat seulement, choix du Pokémon (niveau 100 : « Sans effet », K.O. :
## « Ce Pokémon est K.O. », plus de bonbon : « Il n'en reste plus »), le directeur du menu demande
## le déroulé sans jamais consommer le bonbon lui-même, puis rafraîchit le choix et le Sac ;
## texte n° 62.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const CANDY := &"rare_candy"

var _data: PokemonData
var _items: ItemLibrary
var _state: Node


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func before_each() -> void:
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.new_game(3)
	_state.party.add(PokemonFactory.create(_data, &"abra", 15, GameRng.new(5)))
	_state.party.add(PokemonFactory.create(_data, &"pidgeot", 100, GameRng.new(5)))
	var fainted := PokemonFactory.create(_data, &"rattata", 10, GameRng.new(5))
	fainted.hp = 0
	_state.party.add(fainted)
	_state.bag.add(CANDY, 2)


func after_each() -> void:
	get_tree().paused = false


func _entry(context: StringName) -> BagEntryView:
	for view: BagEntryView in BagQuery.entries(_state.bag, _items, context,
			BagQuery.Sort.RELEVANCE, null, _data):
		if view.item_id == CANDY:
			return view
	return null


func _director() -> MenuDirector:
	var director := MenuDirector.new()
	add_child_autofree(director)
	director.setup(_state, _data, ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(_state.flags, _state.party), func() -> bool: return true, _items)
	return director


func test_card_in_adventure_with_use_out_of_battle_only() -> void:
	var entry := _entry(BagQuery.CONTEXT_FIELD)
	assert_eq(entry.category_id, &"field", "onglet AVENTURE")
	assert_eq(entry.display_name, "Super Bonbon", "nom au singulier (quantité à part)")
	assert_eq(entry.quantity, 2)
	assert_eq(entry.description, "Un bonbon plein d'énergie. Fait monter un Pokémon d'un niveau.",
		"texte n° 59")
	assert_true(entry.usable, "UTILISER")
	assert_eq(entry.action_label, "UTILISER")
	assert_true(entry.targets_pokemon, "choix du Pokémon")
	assert_eq(entry.note, "")
	for context: StringName in [BagQuery.CONTEXT_WILD_BATTLE, BagQuery.CONTEXT_TRAINER_BATTLE]:
		var in_battle := _entry(context)
		assert_false(in_battle.usable, "%s : jamais en combat" % context)
		assert_false(in_battle.is_displayable(), "%s : absent du Sac du combat" % context)
	assert_null(_entry(BagQuery.CONTEXT_TEAM), "pas dans le Sac ouvert depuis l'Équipe")


func test_targets_refuse_level_100_and_fainted() -> void:
	var picker := BagQuery.targets(_state.party, _state.bag, _items.get_item(CANDY),
		BagQuery.CONTEXT_FIELD, _data)
	var rows: Array = []
	for target: PartyTargetView in picker.targets:
		rows.append([target.usable, target.reason, target.refusal])
	assert_eq(rows, [
		[true, "", ""],
		[false, "Sans effet", "Cela n'aurait aucun effet sur Roucarnage."],
		[false, "Ce Pokémon est K.O.", "Rattata est K.O."],
	])
	assert_false(picker.permanent, "la quantité s'affiche")
	_state.bag.remove(CANDY, 2)
	picker = BagQuery.targets(_state.party, _state.bag, _items.get_item(CANDY),
		BagQuery.CONTEXT_FIELD, _data)
	assert_eq([picker.targets[0].usable, picker.targets[0].reason], [false, "Il n'en reste plus"])


func test_the_director_asks_for_the_candy_and_never_spends_it() -> void:
	var director := _director()
	var requests: Array = []
	director.rare_candy_requested.connect(func(i: int, id: StringName) -> void:
		requests.append([i, id]))
	var pickers: Array[PartyPickerView] = []
	director.bag_targets_shown.connect(pickers.append)
	var bags: Array[BagView] = []
	director.bag_shown.connect(bags.append)
	assert_false(director.use_item_on(CANDY, 1), "niveau 100 : rien ne part")
	assert_false(director.use_item_on(CANDY, 2), "K.O. : rien ne part")
	assert_true(director.use_item_on(CANDY, 0))
	assert_eq(requests, [[0, CANDY]])
	assert_eq(_state.bag.count_of(CANDY), 2, "le menu ne consomme rien")
	assert_eq((_state.party.get_at(0) as Pokemon).level, 15, "le menu ne fait rien gagner")
	# Boot a joué le déroulé (bonbon retiré, niveau gagné) puis rappelle le directeur.
	_state.bag.remove(CANDY, 1)
	RareCandy.apply(_state.party.get_at(0), _data)
	director.finish_rare_candy(0, CANDY)
	assert_false(bags.is_empty(), "Sac réémis")
	assert_eq(_state.bag.count_of(CANDY), 1)
	_state.bag.remove(CANDY, 1)
	assert_false(director.use_item_on(CANDY, 0), "plus de bonbon : rien ne part")
	assert_eq(requests.size(), 1)


func test_finish_marks_the_game_changed() -> void:
	var director := _director()
	var closed: Array = []
	director.menu_closed.connect(closed.append)
	assert_true(director.open())
	director.finish_rare_candy(0, CANDY)
	director.close()
	assert_eq(closed, [true], "autosave à la fermeture du menu")


func test_level_text_n62() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file(), "\n".join(texts.get_errors()))
	var event := BattleEvent.new(BattleEvent.Kind.LEVEL_UP, BattleEvent.SideId.PLAYER)
	event.pokemon_name = "Abra"
	event.level = 16
	assert_eq(texts.line_for(&"rare_candy_level", event, _data), "Abra monte au niveau 16 !")
	assert_false(texts.is_draft(&"rare_candy_level"), "texte validé (dossier 17 §15)")
