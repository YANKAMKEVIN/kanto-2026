extends GutTest
## Arène de Koga (fuchsia_gym, jalon 23 T17 à T19 ; `jalon-23.md` §2.13, dossier 26 §10, annexe A.3)
## sur la vraie scène et les vraies données :
## - **grille de la scène = grille fonctionnelle** `tools/plans/parmanie_arene.txt` (14 × 20) ;
##   36 murs invisibles bloquants, dessinés comme le parquet (variante de lame : indice au sol) ;
##   statues bloquantes avec le texte 35 ; sortie vers `fuchsia_city` / `from_gym` ;
## - indice au contact : un « i » vibre et frémit, un mur ordinaire rien ;
## - six Dresseurs aux cases, vues et orientations de la grille, équipes RB du dossier §10.2,
##   textes A-15 à A-20 mot pour mot ; Koga (6, 11), équipe §10.3, IA smart, 4 257 ₽ ;
## - zone, Badge Âme et Surf (`FieldMoves` « prêt » avec la CS03 et un Pokémon compatible).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAYER_SCENE := "res://game/player/player.tscn"
const MAP_PATH := "res://game/world/maps/fuchsia_gym.tscn"
const PLAN_PATH := "res://tools/plans/parmanie_arene.txt"
const SIZE := Vector2i(14, 20)
const FACINGS := {"left": Vector2i.LEFT, "right": Vector2i.RIGHT, "up": Vector2i.UP,
	"down": Vector2i.DOWN}
## Dresseurs : position de la grille → identifiant, nom (prénoms [D] du rapport), équipe.
const TRAINERS := {
	"j1": [&"fuchsia_gym_juggler_1", "Jongleur Nino", [[&"hypno", 38]]],
	"j2": [&"fuchsia_gym_juggler_2", "Jongleur Igor",
		[[&"drowzee", 31], [&"drowzee", 31], [&"kadabra", 31], [&"drowzee", 31]]],
	"j3": [&"fuchsia_gym_juggler_3", "Jongleur Silvio", [[&"drowzee", 34], [&"kadabra", 34]]],
	"d1": [&"fuchsia_gym_tamer_1", "Dompteur Marius", [[&"sandslash", 34], [&"arbok", 34]]],
	"d2": [&"fuchsia_gym_tamer_2", "Dompteur Edgar",
		[[&"arbok", 33], [&"sandslash", 33], [&"arbok", 33]]],
	"j4": [&"fuchsia_gym_juggler_4", "Jongleur Léon", [[&"drowzee", 34], [&"hypno", 34]]],
}
## Annexe A.3 (avant / défaite / après), mot pour mot.
const TEXTS := {
	&"fuchsia_gym_juggler_1": ["Mes balles volent, mon Hypnomade veille !",
		"Raté… j'ai tout fait tomber.", "Koga voit tout. Même ce qu'on ne voit pas."],
	&"fuchsia_gym_juggler_2": ["Un, deux, trois… à toi de jongler !", "Trop de balles en l'air !",
		"Les murs ? Quels murs ? Moi, je ne vois rien."],
	&"fuchsia_gym_juggler_3": ["Tu cherches ton chemin ? Cherche-moi plutôt !", "Bien joué.",
		"Avance à petits pas. Écoute le parquet."],
	&"fuchsia_gym_tamer_1": ["Mes Pokémon obéissent au fouet… et au sifflet !",
		"Ils n'ont rien écouté !", "Koga ne dompte pas : il commande."],
	&"fuchsia_gym_tamer_2": ["Arbok ! Montre-lui tes crocs !", "Couché, Arbok…",
		"Le poison, c'est de la patience."],
	&"fuchsia_gym_juggler_4": ["Hop ! Tu ne me verras pas venir !", "Tu m'as vu venir…",
		"Le maître est juste derrière, au centre."],
}

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
var _data: PokemonData
var _trainers: TrainerLibrary
var _dialogues: DialogueLibrary


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()


func after_all() -> void:
	_map.free()


func after_each() -> void:
	Haptics.reset()


func _hint() -> InvisibleWallHint:
	return _map.get_node(^"InvisibleWalls") as InvisibleWallHint


func _pages(id: StringName, variant: int = 0) -> Array:
	var texts: Array = []
	var dialogue := _dialogues.get_dialogue(id)
	if dialogue == null:
		return texts
	for page: DialoguePage in dialogue.variants[variant].pages:
		texts.append(page.text)
	return texts


# --- Carte ------------------------------------------------------------------------------------

func test_metadata_and_grid_match_the_plan() -> void:
	assert_eq(_map.map_id, &"fuchsia_gym")
	assert_eq(_map.display_name, "Parmanie", "titre = nom de la zone")
	assert_eq(_map.region, "Arène de Parmanie")
	assert_eq(_map.size, SIZE)
	assert_true(_map.interior)
	assert_true(MapCatalog.load_interiors().has(&"fuchsia_gym"))
	assert_eq(_plan.walkable, ".X")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _grid.is_solid(cell) != not _plan.is_walkable(cell):
				mismatches += 1
				if mismatches <= 5:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/parmanie_arene.txt")


func test_thirty_six_invisible_walls_block_and_look_like_the_floor() -> void:
	var walls := _plan.cells_of("i")
	assert_eq(walls.size(), 36)
	assert_eq(_hint().cells.size(), 36)
	var ground := _map.get_node(^"Ground") as TileMapLayer
	for cell: Vector2i in walls:
		assert_true(_hint().is_invisible_wall(cell), str(cell))
		assert_true(_grid.is_solid(cell), "mur invisible %s bloquant" % cell)
		assert_true(_map.blocked_cells.has(cell))
		assert_eq(ground.get_cell_atlas_coords(cell),
			InteriorTiles.atlas_coords(InteriorTiles.Kind.FLOOR_WOOD, 1), "parquet (variante)")
	assert_eq(ground.get_cell_atlas_coords(Vector2i(6, 14)),
		InteriorTiles.atlas_coords(InteriorTiles.Kind.FLOOR_WOOD, 0), "parquet ordinaire")
	for cell: Vector2i in _plan.cells_of("S"):
		assert_true(_grid.is_solid(cell), "statue %s" % cell)
		var point := _map.get_interactions().find(cell, Vector2i.UP)
		assert_not_null(point, "statue examinable %s" % cell)
		if point != null:
			assert_eq(point.dialogue_id, &"fuchsia_gym_statue")
	assert_eq(_pages(&"fuchsia_gym_statue"),
		["ARÈNE DE PARMANIE\nChampion : Koga — le maître des poisons"], "texte 35")


func test_exit_and_entrance() -> void:
	assert_eq(_map.get_spawn_cell(&"entree"), Vector2i(6, 17))
	for cell: Vector2i in [Vector2i(6, 18), Vector2i(7, 18)]:
		var out := _map.get_warps().find_on_push(cell + Vector2i.UP, Vector2i.DOWN)
		var on := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		var warp := on if on != null else out
		assert_not_null(warp, "sortie %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [&"fuchsia_city", &"from_gym"])
	assert_eq(_map.get_warps().size(), 2)


func test_contact_hint_only_on_invisible_walls() -> void:
	var vibrations: Array[int] = []
	Haptics.sink = func(ms: int) -> void: vibrations.append(ms)
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	_map.spawn_player_at(player, Vector2i(5, 12), Vector2i.LEFT)
	var hint := _hint()
	hint.attach(player)
	watch_signals(hint)
	player.bumped.emit(Vector2i.LEFT)
	assert_signal_emitted_with_parameters(hint, "hinted", [Vector2i(4, 12)])
	assert_true(hint.is_shivering())
	assert_eq(vibrations, [InvisibleWallHint.HAPTIC_MS], "une vibration courte")
	await wait_seconds(InvisibleWallHint.SHIVER_TIME + 0.15)
	assert_false(hint.is_shivering(), "rien de permanent")
	# Mur ordinaire : rien.
	player.get_parent().remove_child(player)
	_map.spawn_player_at(player, Vector2i(2, 14), Vector2i.LEFT)
	player.bumped.emit(Vector2i.LEFT)
	assert_signal_emit_count(hint, "hinted", 1)
	assert_false(hint.is_shivering())
	assert_eq(vibrations.size(), 1)
	player.get_parent().remove_child(player)
	player.free()


# --- Dresseurs, Guide, Koga ---------------------------------------------------------------

func test_six_trainers_at_their_cells_with_rb_teams_and_texts() -> void:
	var roster := NpcRoster.load_for_map(&"fuchsia_gym")
	assert_eq(roster.size(), 8, "6 Dresseurs, le Guide et Koga")
	for id: String in TRAINERS:
		var row: Array = TRAINERS[id]
		var spec := roster.get_spec(StringName(id))
		assert_not_null(spec, id)
		if spec == null:
			continue
		assert_eq(spec.cell, _plan.cell_of(id), "%s : case" % id)
		assert_eq(spec.facing, FACINGS[_plan.attr(id, "facing")], "%s : orientation" % id)
		assert_eq(spec.sight, int(_plan.attr(id, "sight")), "%s : vue" % id)
		assert_eq(spec.trainer_id, row[0])
		assert_eq(String(spec.trainer_id), _plan.attr(id, "trainer"))
		var trainer := _trainers.get_trainer(row[0])
		assert_not_null(trainer, String(row[0]))
		if trainer == null:
			continue
		assert_eq(trainer.name, row[1])
		var team := _trainers.build_team(row[0], &"charmander", GameRng.new(1))
		assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
			row[2], "%s : équipe RB" % id)
		var expected: Array = TEXTS[row[0]]
		for i: int in 3:
			var suffix: String = ["_before", "_defeated", "_after"][i]
			assert_eq(_pages(StringName(String(row[0]) + suffix)), [expected[i]],
				"%s%s : texte de l'annexe A" % [row[0], suffix])


func test_trainer_names_are_unique_in_the_game() -> void:
	var seen := {}
	for id: StringName in _trainers.get_ids():
		var name := _trainers.get_trainer(id).name
		if String(id).begins_with("fuchsia_gym_") and id != &"fuchsia_gym_koga":
			var first := name.split(" ")[-1]
			for other: StringName in _trainers.get_ids():
				if other == id or String(other).begins_with("qa_"):
					continue
				var other_name := _trainers.get_trainer(other).name
				assert_ne(other_name.split(" ")[-1], first,
					"prénom « %s » déjà pris par %s" % [first, other])
		seen[name] = true


func test_guide_and_koga() -> void:
	var roster := NpcRoster.load_for_map(&"fuchsia_gym")
	var guide := roster.get_spec(&"guide")
	assert_eq(guide.cell, _plan.cell_of("guide"))
	assert_eq(_pages(&"fuchsia_gym_guide", 0),
		["Le Badge Âme !", "Tes Pokémon peuvent maintenant surfer."], "texte 37")
	assert_eq(_pages(&"fuchsia_gym_guide", 1), ["L'Arène de Koga est pleine de murs invisibles.",
		"Observe le sol et avance pas à pas."], "texte 36")
	var koga := roster.get_spec(&"koga")
	assert_eq([koga.cell, koga.facing], [Vector2i(6, 11), Vector2i.DOWN])
	var trainer := _trainers.get_trainer(&"fuchsia_gym_koga")
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_eq(trainer.prize_money, 4257, "99 × 43")
	assert_eq([trainer.card_name, trainer.card_title], ["KOGA", "Champion d'Arène de Parmanie"])
	var team := _trainers.build_team(&"fuchsia_gym_koga", &"charmander", GameRng.new(1))
	var rows := team.get_all().map(func(p: Pokemon) -> Array:
		return [p.species_id, p.level, p.moves.map(func(m: MoveSlot) -> StringName:
			return m.move_id)])
	assert_eq(rows, [
		[&"koffing", 37, [&"tackle", &"smog", &"sludge", &"haze"]],
		[&"muk", 39, [&"disable", &"poison_gas", &"minimize", &"sludge"]],
		[&"koffing", 37, [&"tackle", &"smog", &"sludge", &"haze"]],
		[&"weezing", 43, [&"smog", &"sludge", &"toxic", &"self_destruct"]],
	], "équipe RB du dossier §10.3 (Gaz Toxik présent : aucun repli)")
	for row: Array in rows:
		for move: StringName in row[2]:
			assert_not_null(_data.get_move(move), String(move))
			assert_eq(_data.get_move(move).pending_effects.size(), 0, String(move))


# --- Zone, badge, Surf ------------------------------------------------------------------------

func test_zone_and_gym_service() -> void:
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"fuchsia_gym"), &"fuchsia_city")


func test_soul_badge_makes_surf_ready() -> void:
	var badges := BadgeLibrary.new()
	badges.load_file()
	assert_true(badges.has_badge(&"soul"))
	assert_eq(badges.flag(&"soul"), &"badge_soul")
	var field := FieldMoves.new()
	assert_true(field.load_file())
	var items := ItemLibrary.new()
	items.load_dir()
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"vaporeon", 40, GameRng.new(3)))
	var bag := Bag.new()
	bag.add(&"hm03", 1)
	var flags := StoryFlags.new()
	assert_eq(field.check(&"surf", party, bag, flags, items, _data).state,
		FieldMoves.State.NO_BADGE)
	flags.set_flag(&"badge_soul")
	assert_eq(field.check(&"surf", party, bag, flags, items, _data).state,
		FieldMoves.State.READY, "Badge Âme + CS03 + Aquali")
