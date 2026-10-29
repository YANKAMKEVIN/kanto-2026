extends GutTest
## La vie de Céladopole (jalon 20 T17, jalon-20.md §2.9, §3 T17 ; dossier 23 §7.3, §9, §10, §20 et
## annexe A du plan) sur les **vraies cartes et leurs PNJ** (`data/npcs/celadon_*.json`) :
## - les 12 habitants et les 2 Rocket en civil sur les cases de la grille (`celadopole.txt`), sans
##   combat ; chaque intérieur a exactement les PNJ de sa grille (`celadopole_*.txt`) ;
## - chaque vendeur (par-dessus son comptoir) et chaque distributeur du toit ouvre **sa**
##   boutique (clé `shop`, §2.9.1) ; prix : pierres 2 100 ₽, Poupée Poké 1 000 ₽, boissons 200 /
##   300 / 350 ₽ ; aucune vitamine ; CT01 achetable **une fois** ;
## - la fillette du toit (§2.9.6) : Eau Fraîche → CT13 une seule fois, Soda Cool ou Limonade
##   seuls → refus (« trop sucré »), NON → rien ne change ;
## - la vieille dame de la Résidence ne donne rien ; l'homme du 3e ne donne rien (Riposte
##   absente) ;
## - Boot réel : arrivée en ville (déclencheur silencieux, drapeau, objectif).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_celadon_life_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
## Habitants de la ville : identifiant de la grille → [clé du PNJ, dialogue, locuteur, pages].
const CITY := {
	"h1_pecheur": ["fisherman", &"celadon_fisherman", "Pêcheur",
		["Pas de pêche ici, c'est interdit.",
			"Alors je regarde l'eau, avec mon Tartard. On aime ça, tous les deux."]],
	"h2_vieil_homme": ["old_man", &"celadon_old_man", "Vieil homme",
		["J'ai grandi à Lavanville.",
			"Ces temps-ci, on dit que la Tour ne dort plus la nuit."]],
	"h3_jardiniere": ["gardener_f", &"celadon_gardener_f", "Jardinière",
		["Erika soigne chaque plante de son Arène elle-même.",
			"Même l'arbuste devant l'entrée. Il faut bien le Couper pour entrer."]],
	"h4_client_casino": ["casino_client", &"celadon_casino_client", "Client",
		["Le patron du Casino a de drôles d'amis.", "Toujours en costume, jamais un sourire."]],
	"h5_employe": ["clerk", &"celadon_clerk", "Employé",
		["Sylphe ? Une grande entreprise de Safrania.",
			"Ils fabriquent des appareils que personne ne comprend."]],
	"h6_enfant": ["kid", &"celadon_kid", "Enfant",
		["On dit que si on jette une pièce dans la fontaine, le vœu se réalise.",
			"J'en ai jeté trois. J'attends encore."]],
	"h7_homme_banc": ["stroller", &"celadon_stroller", "Promeneur",
		["Au bout de l'avenue, il n'y a que des arbres.",
			"C'est pour ça que je viens lire ici. Personne ne passe."]],
	"h8_cliente": ["shopper", &"celadon_shopper", "Cliente",
		["Cinq étages de magasin.", "Je n'arrive jamais à tout voir en une seule journée."]],
	"h9_touriste": ["tourist", &"celadon_tourist", "Touriste",
		["Je suis venu pour les jardins.", "J'ai prolongé mon séjour d'une semaine."]],
	"h10_jardinier": ["gardener_m", &"celadon_gardener_m", "Jardinier",
		["On replante ces massifs à chaque saison.",
			"Erika passe parfois nous donner des conseils."]],
	"h11_jeune": ["youth", &"celadon_youth", "Jeune homme",
		["De Lavanville, je prends toujours le souterrain.",
			"C'est long, mais au moins il ne pleut pas."]],
	"h12_cuisinier": ["cook", &"celadon_cook", "Cuisinier",
		["Depuis que le Casino est fermé, le restaurant ne désemplit pas.",
			"Je ne m'en plains pas."]],
	"r1_rocket_civil": ["rocket_1", &"celadon_rocket_1", "Inconnu",
		["Tu regardes quoi ? Circule."]],
	"r2_rocket_civil": ["rocket_2", &"celadon_rocket_2", "Inconnu",
		["… Le Casino ? Il est très bien, le Casino."]],
}
## Intérieurs → grille de la carte (les PNJ de la grille = ceux des données).
const INTERIORS := {
	&"celadon_dept_gf": "celadopole_magasin_rdc", &"celadon_dept_2f": "celadopole_magasin_2e",
	&"celadon_dept_3f": "celadopole_magasin_3e", &"celadon_dept_4f": "celadopole_magasin_4e",
	&"celadon_dept_5f": "celadopole_magasin_5e", &"celadon_dept_roof": "celadopole_magasin_toit",
	&"celadon_mansion_gf": "celadopole_residence_rdc",
	&"celadon_mansion_1f": "celadopole_residence_1er",
	&"celadon_mansion_2f": "celadopole_residence_2e",
	&"celadon_mansion_roof_house": "celadopole_residence_maison_toit",
	&"celadon_chief_house": "celadopole_maison_chef", &"celadon_restaurant": "celadopole_restaurant",
	&"celadon_hotel": "celadopole_hotel", &"celadon_gym": "celadopole_arene",
}
const PLAN_KINDS: Array[String] = ["pnj", "dresseur", "pokemon", "objet_don"]
## Vendeurs et distributeurs : [carte, case du joueur, boutique attendue].
const VENDORS: Array = [
	[&"celadon_dept_2f", Vector2i(7, 6), &"celadon_dept_2f"],
	[&"celadon_dept_2f", Vector2i(12, 6), &"celadon_dept_2f_tm"],
	[&"celadon_dept_4f", Vector2i(7, 6), &"celadon_dept_4f"],
	[&"celadon_dept_4f", Vector2i(12, 6), &"celadon_dept_4f_stones"],
	[&"celadon_dept_5f", Vector2i(10, 6), &"celadon_dept_5f"],
	[&"celadon_dept_roof", Vector2i(10, 3), &"celadon_dept_roof_water"],
	[&"celadon_dept_roof", Vector2i(12, 3), &"celadon_dept_roof_soda"],
	[&"celadon_dept_roof", Vector2i(14, 3), &"celadon_dept_roof_lemonade"],
]
const GIRL_CELL := Vector2i(17, 5)
const GIRL_FRONT := Vector2i(16, 5)

var _boot: Boot
var _player: Player
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []
var _shops: Array[StringName] = []
var _dialogues: DialogueLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	assert_true(_dialogues.load_dir())


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T15:00:00")
	_fs = MemoryFs.new()
	_pages.clear()
	_shops.clear()


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"interact", &"move_left", &"move_right"]:
		Input.action_release(action)


func _load_map(id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _texts(dialogue: Dialogue) -> Array:
	var texts: Array = []
	for page: DialoguePage in dialogue.variants[0].pages:
		texts.append(page.text.replace("\n", " "))
	return texts


# --- Les habitants de la ville --------------------------------------------------------------

func test_twelve_inhabitants_and_two_civil_rockets_on_their_plan_cells() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/celadopole.txt"), plan.error)
	var map := _load_map(&"celadon_city")
	assert_eq(map.get_npcs().size(), CITY.size(), "14 PNJ (12 habitants, 2 Rocket en civil)")
	for id: String in CITY:
		var row: Array = CITY[id]
		var npc := map.get_npc(StringName(row[0]))
		assert_not_null(npc, "%s posé" % id)
		if npc == null:
			continue
		var spec := npc.get_spec()
		assert_eq(spec.cell, plan.cell_of(id), "%s : case de la grille" % id)
		assert_eq(spec.facing, Grid.direction_from_name(plan.attr(id, "facing")), id)
		assert_false(spec.is_trainer(), "%s : aucun combat" % id)
		assert_eq(spec.dialogue, row[1])
		var dialogue := _dialogues.get_dialogue(spec.dialogue)
		assert_eq(dialogue.speaker, row[2])
		assert_eq(_texts(dialogue), row[3], "%s : texte validé" % id)
	for id: String in ["r1_rocket_civil", "r2_rocket_civil"]:
		assert_eq(map.get_npc(StringName(CITY[id][0])).get_spec().sprite, &"rocket_civilian",
			"civil élégant à détail rouge (série 22)")


func test_every_interior_has_exactly_the_npcs_of_its_plan() -> void:
	for id: StringName in INTERIORS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % INTERIORS[id]), plan.error)
		var map := _load_map(id)
		var wanted: Array[Vector2i] = []
		for pos: String in plan.positions:
			if PLAN_KINDS.has(plan.positions[pos]["kind"]):
				wanted.append_array(plan.cells_at(pos))
		var cells: Array[Vector2i] = []
		for npc: Npc in map.get_npcs():
			cells.append(npc.get_cell())
		wanted.sort()
		cells.sort()
		assert_eq(cells, wanted, "%s : les PNJ sont ceux de la grille" % id)
		for pos: String in plan.positions:
			var position: Dictionary = plan.positions[pos]
			if position["kind"] != "pnj":
				continue
			var cell: Vector2i = plan.cells_at(pos)[0]
			var found: Npc = null
			for npc: Npc in map.get_npcs():
				if npc.get_cell() == cell:
					found = npc
			assert_not_null(found, "%s %s" % [id, pos])
			if found != null:
				assert_eq(found.get_spec().facing, Grid.direction_from_name(plan.attr(pos, "facing")),
					"%s %s : orientation" % [id, pos])


func test_centre_nurse_and_the_reserved_rooms_without_npc() -> void:
	var center := _load_map(&"celadon_center")
	assert_eq(center.get_npcs().size(), 1, "l'infirmière seule")
	assert_eq(center.get_npcs()[0].get_spec().sprite, &"nurse")
	assert_eq(_load_map(&"celadon_mansion_3f").get_npcs().size(), 0, "palier et porte fermée")
	assert_eq(_load_map(&"celadon_mansion_roof").get_npcs().size(), 0, "terrasse")


func test_old_lady_pokemon_and_the_bureau_door() -> void:
	var map := _load_map(&"celadon_mansion_gf")
	var lady := map.get_npc(&"old_lady").get_spec()
	assert_eq(_texts(_dialogues.get_dialogue(lady.dialogue)),
		["Bienvenue. Je reçois rarement des visiteurs, mais j'aime ça."], "texte 26")
	for id: StringName in [&"meowth", &"clefairy"]:
		var pokemon := map.get_npc(id)
		assert_not_null(pokemon, "%s de la vieille dame" % id)
		assert_false(pokemon.get_spec().is_interactive(), "Pokémon d'ambiance")
		assert_false(pokemon.get_spec().is_shy(), "il ne fuit pas")
	var third := _load_map(&"celadon_mansion_3f")
	var door: InteractPoint = null
	for point: Node in third.get_node(^"Interactables").get_children():
		door = point as InteractPoint
	assert_eq(door.dialogue_id, &"celadon_mansion_office_door", "BUREAU PRIVÉ, fermée (texte 27)")


# --- Vendeurs, boutiques, prix --------------------------------------------------------------

func test_every_vendor_counter_and_dispenser_opens_its_own_shop() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir())
	for row: Array in VENDORS:
		var map := _load_map(row[0])
		var cell: Vector2i = row[1]
		var target := InteractionFinder.find(map.get_grid(), map.get_interactions(), cell,
			Vector2i.UP)
		assert_not_null(target, "%s %s : une cible face au comptoir" % [row[0], cell])
		if target == null:
			continue
		var dialogue := _dialogues.get_dialogue(target.dialogue_id)
		assert_not_null(dialogue, String(target.dialogue_id))
		var variant := dialogue.variants[0]
		assert_eq(variant.action, &"open_shop", "%s : ouvre une boutique" % target.dialogue_id)
		assert_eq(variant.shop, row[2], "%s → %s" % [target.dialogue_id, row[2]])
		assert_true(shops.has_shop(row[2]), "boutique %s définie" % row[2])
	# La boutique n'est plus celle de la carte : le vendeur nomme la sienne.
	assert_false(shops.has_shop(&"celadon_dept_roof"), "aucune boutique « de carte »")


func test_dispenser_says_its_line_then_opens_the_shop() -> void:
	var dialogue := _dialogues.get_dialogue(&"celadon_dept_roof_water")
	assert_true(dialogue.narration)
	assert_eq(_texts(dialogue), ["Un distributeur de boissons fraîches."], "texte 90")


func test_prices_stock_and_the_single_tm() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir())
	var prices := {
		&"fire_stone": 2100, &"water_stone": 2100, &"thunder_stone": 2100, &"leaf_stone": 2100,
		&"poke_doll": 1000, &"fresh_water": 200, &"soda_pop": 300, &"lemonade": 350,
		&"tm01": 3000,
	}
	for item_id: StringName in prices:
		assert_eq(items.get_item(item_id).price, prices[item_id], "%s : prix" % item_id)
	assert_eq(ShopRules.stock(shops.get_shop(&"celadon_dept_4f_stones"), null),
		[&"fire_stone", &"water_stone", &"thunder_stone", &"leaf_stone"] as Array[StringName],
		"pierres du 4e")
	assert_eq(ShopRules.stock(shops.get_shop(&"celadon_dept_4f"), null),
		[&"poke_doll"] as Array[StringName], "Poupée Poké du 4e")
	var fifth := ShopRules.stock(shops.get_shop(&"celadon_dept_5f"), null)
	assert_eq(fifth, [&"x_attack", &"x_defend", &"x_speed", &"x_special", &"x_accuracy",
		&"dire_hit", &"hp_up", &"protein", &"iron", &"carbos", &"calcium"] as Array[StringName], "objets de combat du 5e, puis les cinq vitamines (lot 32P)")
	for item_id: StringName in fifth.slice(0, 6):
		assert_eq(items.get_item(item_id).category, ItemData.Category.BATTLE)
	for shop_id: StringName in [&"celadon_dept_roof_water", &"celadon_dept_roof_soda",
			&"celadon_dept_roof_lemonade"]:
		assert_eq(ShopRules.stock(shops.get_shop(shop_id), null).size(), 1, "une boisson chacun")
	assert_eq(items.get_item(&"fresh_water").heal_amount, 50)
	assert_eq(items.get_item(&"soda_pop").heal_amount, 60)
	assert_eq(items.get_item(&"lemonade").heal_amount, 80)
	# CT01 : une seule fois.
	GameState.new_game(3)
	GameState.money = 10000
	var shop := shops.get_shop(&"celadon_dept_2f_tm")
	var tm := items.get_item(&"tm01")
	assert_eq(ShopRules.max_buy(tm, GameState.money, GameState.bag), 1)
	assert_eq(ShopRules.buy(GameState, shop, tm, 1), ShopRules.Status.OK)
	assert_eq(GameState.money, 7000)
	assert_eq(ShopRules.max_buy(tm, GameState.money, GameState.bag), 0, "déjà au Sac")
	assert_eq(ShopRules.buy(GameState, shop, tm, 1), ShopRules.Status.ALREADY_OWNED)
	assert_eq(GameState.money, 7000, "rien débité")


func test_second_floor_clerk_sells_the_status_heals_and_the_super_ball() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir())
	assert_eq(ShopRules.stock(shops.get_shop(&"celadon_dept_2f"), null),
		[&"great_ball", &"super_potion", &"revive", &"antidote", &"burn_heal", &"ice_heal",
		&"awakening", &"paralyze_heal", &"super_repel"] as Array[StringName])  # lot 32P : Super Repousse (RB)


# --- Boot réel : parler à un vendeur, à la fillette ----------------------------------------

func _start(start_path: String, map: StringName = &"celadon_dept_gf",
		spawn: StringName = &"entrance") -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text().replace("\n", " ")))
	_boot.get_service_director().shop_requested.connect(
		func(shop: StringName) -> void: _shops.append(shop))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Se place sur [param cell] (de la carte courante) tourné vers [param facing].
func _stand(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


## Bouton d'interaction, puis déroule le dialogue ; [param answer] au choix éventuel.
func _talk(answer: bool = true) -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(answer)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	# La Boutique met le monde en pause (`wait_until` de GUT s'y figerait) : image par image.
	while not (_boot.is_stable() or _boot.get_menu_director().is_open()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)


func test_talking_over_each_counter_asks_for_the_right_shop() -> void:
	await _start("res://tools/debug_start/celadon_dept.json")
	for row: Array in VENDORS:
		if _boot.get_map().map_id != row[0]:
			var arrival := &"from_down" if row[0] == &"celadon_dept_roof" else &"from_up"
			await SceneRouter.change_map(row[0], arrival, Vector2i.DOWN)
			await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
		_shops.clear()
		await _stand(row[1], Vector2i.UP)
		await _talk()
		assert_eq(_shops, [row[2]] as Array[StringName], "%s %s" % [row[0], row[1]])
		assert_true(_boot.get_menu_director().is_open(), "la Boutique s'ouvre à la fin du dialogue")
		_close_shop()
		await wait_process_frames(2)
	assert_push_error_count(0)


func _close_shop() -> void:
	if _boot.get_menu_director().is_open():
		_boot.get_menu_director().close()


func test_the_hostess_gives_nothing_and_the_gift_man_gives_tm18_once() -> void:
	await _start("res://tools/debug_start/celadon_dept.json")
	var bag_before: Dictionary = (GameState.bag as Bag).to_dict()
	await _stand(Vector2i(9, 6), Vector2i.UP)
	await _talk()
	assert_eq(_pages, ["Bienvenue au grand magasin de Céladopole !",
		"Le tableau des étages est juste derrière moi."] as Array[String], "texte 80")
	assert_eq((GameState.bag as Bag).to_dict(), bag_before, "l'hôtesse ne donne rien")
	await SceneRouter.change_map(&"celadon_dept_3f", &"from_up", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_pages.clear()
	assert_eq(GameState.bag.count_of(&"tm18"), 0)
	await _stand(Vector2i(14, 6), Vector2i.RIGHT)
	await _talk()
	# N-22 : Riposte existe, l'homme du 3e étage donne la CT18 (une seule fois).
	assert_eq(_pages, ["J'avais un cadeau pour un Dresseur doué.",
		"Toi, tu as l'air de ceux qui encaissent les coups. Tiens, prends ça !",
		"{player} obtient la CT18 — Riposte !".replace("{player}", GameState.player_name),
		"Riposte renvoie le double des dégâts d'une attaque Normal ou Combat."]
		as Array[String], "répliques [D] du don")
	assert_eq(GameState.bag.count_of(&"tm18"), 1, "CT18 — Riposte")
	assert_true(GameState.flags.has_flag(&"got_tm18"))
	_pages.clear()
	await _talk()
	assert_eq(_pages, ["Riposte, ça ne s'improvise pas.", "Il faut d'abord savoir encaisser."]
		as Array[String], "après le don")
	assert_eq(GameState.bag.count_of(&"tm18"), 1, "pas de seconde CT18")


func test_the_old_lady_gives_nothing() -> void:
	await _start("res://tools/debug_start/celadon_dept.json")
	await SceneRouter.change_map(&"celadon_mansion_gf", &"entrance", Vector2i.UP)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	var bag_before: Dictionary = (GameState.bag as Bag).to_dict()
	var party_before := GameState.party.size()
	await _stand(Vector2i(8, 5), Vector2i.UP)
	await _talk()
	assert_eq(_pages, ["Bienvenue. Je reçois rarement des visiteurs, mais j'aime ça."]
		as Array[String])
	assert_eq((GameState.bag as Bag).to_dict(), bag_before)
	assert_eq(GameState.party.size(), party_before)


# --- La fillette du toit -------------------------------------------------------------------

const T24 := "J'ai tellement soif… Tu as quelque chose à boire ?"
const ASK := "Lui donner une Eau Fraîche ?"


func _on_roof(items: Dictionary) -> void:
	await _start("res://tools/debug_start/celadon_dept.json")
	var bag: Bag = GameState.bag
	for item_id: StringName in [&"fresh_water", &"soda_pop", &"lemonade"]:
		bag.remove(item_id, bag.count_of(item_id))
	for item_id: StringName in items:
		bag.add(item_id, items[item_id])
	await SceneRouter.change_map(&"celadon_dept_roof", &"from_down", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_pages.clear()
	await _stand(GIRL_FRONT, Vector2i.RIGHT)


func test_water_for_the_girl_gives_tm13_once() -> void:
	await _on_roof({&"fresh_water": 1})
	await _talk(true)
	assert_eq(_pages, [T24, ASK, "Merci ! Tiens, c'est pour toi."] as Array[String],
		"T-24, question, T-25")
	assert_eq(GameState.bag.count_of(&"fresh_water"), 0, "l'Eau Fraîche part")
	assert_eq(GameState.bag.count_of(&"tm13"), 1, "CT13 — Laser Glace")
	assert_true(GameState.flags.has_flag(&"rooftop_tm13"))
	# Une seule fois : l'échange ne se rejoue pas, même avec une autre Eau Fraîche.
	GameState.bag.add(&"fresh_water", 1)
	_pages.clear()
	await _talk()
	# N-22 : les deux autres CT existent, elle a encore soif d'autre chose (T24 seul).
	assert_eq(_pages, [T24] as Array[String], "texte 24 : encore soif")
	assert_eq(GameState.bag.count_of(&"tm13"), 1, "pas de seconde CT13")
	assert_eq(GameState.bag.count_of(&"fresh_water"), 1, "l'Eau Fraîche reste")


func test_refusing_changes_nothing() -> void:
	await _on_roof({&"fresh_water": 1})
	await _talk(false)
	assert_eq(_pages, [T24, ASK, "Tant pis… Je vais attendre encore un peu."] as Array[String],
		"textes 24, 91, 92")
	assert_eq(GameState.bag.count_of(&"fresh_water"), 1)
	assert_eq(GameState.bag.count_of(&"tm13"), 0)
	assert_false(GameState.flags.has_flag(&"rooftop_tm13"))


## N-22 : le Soda Cool donne la CT48 (Éboulement), la Limonade la CT49 (Triplattaque), une fois
## chacune, indépendamment de l'Eau Fraîche (CT13).
func test_soda_and_lemonade_give_tm48_and_tm49_once() -> void:
	var cases: Array = [[&"soda_pop", &"tm48", &"rooftop_tm48", "Lui donner un Soda Cool ?"],
		[&"lemonade", &"tm49", &"rooftop_tm49", "Lui donner une Limonade ?"]]
	for entry: Array in cases:
		var drink: StringName = entry[0]
		await _on_roof({drink: 1})
		await _talk(true)
		assert_eq(_pages, [T24, entry[3], "Merci ! Tiens, c'est pour toi."] as Array[String],
			"T-24, question [D], T-25 (%s)" % drink)
		assert_eq(GameState.bag.count_of(drink), 0, "la boisson part")
		assert_eq(GameState.bag.count_of(entry[1]), 1, String(entry[1]))
		assert_true(GameState.flags.has_flag(entry[2]))
		assert_eq(GameState.bag.count_of(&"tm13"), 0, "l'Eau Fraîche n'est pas concernée")
		GameState.bag.add(drink, 1)
		_pages.clear()
		await _talk()
		assert_eq(_pages, [T24] as Array[String], "une seule fois (%s)" % drink)
		assert_eq(GameState.bag.count_of(entry[1]), 1, "pas de seconde CT")
		_boot.queue_free()
		await wait_process_frames(3)
		_pages.clear()


func test_the_three_drinks_give_the_three_tms_then_she_is_content() -> void:
	await _on_roof({&"fresh_water": 1, &"soda_pop": 1, &"lemonade": 1})
	for i: int in 3:
		await _talk(true)
		_pages.clear()
	for tm: StringName in [&"tm13", &"tm48", &"tm49"]:
		assert_eq(GameState.bag.count_of(tm), 1, String(tm))
	await _talk()
	assert_eq(_pages, ["Ça va mieux, merci.", "Le toit, c'est joli, mais il y fait chaud."]
		as Array[String], "texte 94 : les trois CT données")


func test_nothing_to_drink_just_the_thirst() -> void:
	await _on_roof({})
	await _talk()
	assert_eq(_pages, [T24] as Array[String], "texte 24 seul")
	assert_eq(GameState.bag.count_of(&"tm13"), 0)


# --- Arrivée en ville ----------------------------------------------------------------------

func test_the_east_arrival_raises_the_flag_and_changes_the_objective() -> void:
	await _start("res://tools/debug_start/celadon.json", &"celadon_city", &"from_route_7_c")
	assert_eq(_boot.get_map().map_id, &"celadon_city")
	assert_false(GameState.flags.has_flag(&"celadon_reached"))
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	assert_eq(objectives.current(GameState.flags), "rejoindre Céladopole.",
		"Route 8 atteinte, pas encore la ville")
	var cell := _player.get_cell()
	assert_eq(cell, Vector2i(69, 22), "arrivée de la Route 7, case du milieu")
	Input.action_press(&"move_left")
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"celadon_reached"), TIMEOUT)
	Input.action_release(&"move_left")
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_player.get_cell().x, 68, "2e colonne du raccord")
	assert_eq(objectives.current(GameState.flags), "explorer Céladopole.")
