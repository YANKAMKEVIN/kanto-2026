extends GutTest
## Vie du repaire Rocket (jalon 20 T21, `jalon-20.md` §2.4.2, §2.7, §2.10.6 ; dossier 23 §13.2) sur
## les vraies données et les vraies cartes, comparées aux grilles `tools/plans/repaire_b*.txt` :
## - les 9 sbires du repaire (10 Dresseurs avec celui du Casino) sont aux cases, orientations et
##   identifiants des grilles ; chacun a son équipe (§2.10.6) et ses répliques ;
## - les objets visibles sont aux cases des grilles, avec la valeur de remplacement retenue
##   (CT absentes, Hyper Potion, PP Plus, PV Plus, Fer → Super Potion ou Rappel) ;
## - les objets cachés sont des points EXAMINER lus seulement depuis la case et l'orientation de
##   la grille (`depuis=… face=…`), retirés par `got_<id>` ;
## - **rien sur une dalle ni sur un trajet** (§2.4.2) : ni PNJ, ni objet, ni point ; chaque
##   Dresseur et chaque objet visible est atteignable depuis une case praticable ;
## - la porte du bureau fermée s'examine depuis le sud (texte 153).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FLOORS: Dictionary[StringName, String] = {
	&"rocket_hideout_b1f": "repaire_b1f", &"rocket_hideout_b2f": "repaire_b2f",
	&"rocket_hideout_b3f": "repaire_b3f", &"rocket_hideout_b4f": "repaire_b4f",
}
## Grille → Dresseur (identifiant de la grille, `trainer=`).
const TRAINERS: Dictionary[String, Array] = {
	"sbire_b1_1": [&"rocket_b1f_1", &"rocket_hideout_b1f_1"],
	"sbire_b1_2": [&"rocket_b1f_2", &"rocket_hideout_b1f_2"],
	"sbire_b1_3": [&"rocket_b1f_3", &"rocket_hideout_b1f_3"],
	"sbire_b2": [&"rocket_b2f_1", &"rocket_hideout_b2f_1"],
	"sbire_b3_1": [&"rocket_b3f_1", &"rocket_hideout_b3f_1"],
	"sbire_b3_2": [&"rocket_b3f_2", &"rocket_hideout_b3f_2"],
	"sbire_cle": [&"rocket_key", &"rocket_hideout_b4f_key"],
	"garde_ouest": [&"rocket_guard_1", &"rocket_hideout_b4f_guard_1"],
	"garde_est": [&"rocket_guard_2", &"rocket_hideout_b4f_guard_2"],
}
## Grille → [PNJ « objet », objet donné] (valeurs de remplacement du dossier §13.2, H-7, [D]).
const ITEMS: Dictionary[String, Array] = {
	"corde_sortie": [&"rocket_hideout_b1f_item_1", &"escape_rope"],
	"hyper_potion": [&"rocket_hideout_b1f_item_2", &"super_potion"],
	"pierre_lune": [&"rocket_hideout_b2f_item_1", &"moon_stone"],
	"pepite": [&"rocket_hideout_b2f_item_2", &"nugget"],
	"ct07": [&"rocket_hideout_b2f_item_3", &"super_potion"],
	"super_potion": [&"rocket_hideout_b2f_item_4", &"super_potion"],
	"ct10": [&"rocket_hideout_b3f_item_1", &"super_potion"],
	"super_bonbon": [&"rocket_hideout_b3f_item_2", &"rare_candy"],
	"ct02": [&"rocket_hideout_b4f_item_1", &"super_potion"],
	"pv_plus": [&"rocket_hideout_b4f_item_2", &"revive"],
	"fer": [&"rocket_hideout_b4f_item_3", &"super_potion"],
	"cle_ascenseur": [&"rocket_hideout_b4f_lift_key", &"lift_key"],
	"scope_sylphe": [&"rocket_hideout_b4f_silph_scope", &"silph_scope"],
}
## Grille → [point d'examen, objet donné].
const HIDDEN: Dictionary[String, Array] = {
	"pp_plus_cache": [&"rocket_hideout_b1f_hidden_1", &"revive"],
	"pepite_cachee": [&"rocket_hideout_b3f_hidden_1", &"nugget"],
	"super_potion_cachee": [&"rocket_hideout_b4f_hidden_1", &"super_potion"],
}
const FACINGS: Dictionary[String, Vector2i] = {
	"N": Vector2i.UP, "S": Vector2i.DOWN, "E": Vector2i.RIGHT, "O": Vector2i.LEFT,
	"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT,
}

var _plans: Dictionary[StringName, PlanGrid] = {}
var _maps: Dictionary[StringName, GameMap] = {}
var _cutscenes: CutsceneLibrary
var _dialogues: DialogueLibrary
var _trainers: TrainerLibrary


func before_all() -> void:
	for map_id: StringName in FLOORS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % FLOORS[map_id]), plan.error)
		_plans[map_id] = plan
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	var data := PokemonData.new()
	data.load_dir()
	_trainers = TrainerLibrary.new(data)
	_trainers.load_dir()


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()


## Carte et position de la grille portant l'identifiant [param id].
func _find(id: String) -> StringName:
	for map_id: StringName in _plans:
		if _plans[map_id].positions.has(id):
			return map_id
	return &""


func test_the_nine_hideout_grunts_stand_where_the_grids_put_them() -> void:
	var count := 0
	for grid_id: String in TRAINERS:
		var map_id := _find(grid_id)
		assert_ne(map_id, &"", grid_id)
		var plan := _plans[map_id]
		var spec := NpcRoster.load_for_map(map_id).get_spec(TRAINERS[grid_id][0])
		assert_not_null(spec, grid_id)
		if spec == null:
			continue
		count += 1
		assert_eq(spec.trainer_id, TRAINERS[grid_id][1], grid_id)
		assert_eq(String(spec.trainer_id), plan.attr(grid_id, "trainer"), "grille : %s" % grid_id)
		assert_eq(spec.cell, plan.cell_of(grid_id), "%s : case" % grid_id)
		assert_eq(spec.facing, FACINGS[plan.attr(grid_id, "facing")], "%s : orientation" % grid_id)
		var sight := maxi(int(plan.attr(grid_id, "sight")), 1)
		assert_eq(spec.sight, sight, "%s : vision (0 de la grille → 1 [D])" % grid_id)
		assert_true(_trainers.has_trainer(spec.trainer_id), "%s : équipe" % grid_id)
		for line: StringName in [spec.before_dialogue, spec.defeated_dialogue, spec.dialogue]:
			assert_true(_dialogues.has_dialogue(line), "%s : %s" % [grid_id, line])
			assert_eq(_dialogues.get_dialogue(line).speaker, "Sbire Rocket", String(line))
		assert_false(spec.leaves, "%s : les sbires vaincus restent en place (RB)" % grid_id)
	assert_eq(count, 9, "9 sbires + le Rocket du Casino = 10 Dresseurs (dossier §13.2)")


func test_visible_items_are_on_their_grid_cells_with_the_retained_values() -> void:
	for grid_id: String in ITEMS:
		var map_id := _find(grid_id)
		var spec := NpcRoster.load_for_map(map_id).get_spec(ITEMS[grid_id][0])
		assert_not_null(spec, grid_id)
		if spec == null:
			continue
		assert_eq(spec.cell, _plans[map_id].cell_of(grid_id), "%s : case" % grid_id)
		assert_eq(spec.verb, Interaction.Kind.TAKE, "%s : PRENDRE" % grid_id)
		var cutscene := _cutscenes.get_cutscene(spec.dialogue)
		assert_not_null(cutscene, "%s : scène de prise" % grid_id)
		var given: Array[StringName] = []
		for step: CutsceneStep in cutscene.variants[0].steps:
			if step.kind == CutsceneStep.Kind.GIVE:
				given.append(step.item_id)
				assert_true(step.found, "%s : objet trouvé (journal)" % grid_id)
		assert_eq(given, [ITEMS[grid_id][1]] as Array[StringName], grid_id)
		var got := StringName("got_" + String(spec.id))
		assert_has(spec.unless_flags, got, "%s : retiré une fois pris" % grid_id)


func test_hidden_items_are_read_only_from_the_grid_cell_and_facing() -> void:
	for grid_id: String in HIDDEN:
		var map_id := _find(grid_id)
		var plan := _plans[map_id]
		var clue := plan.cell_of(grid_id)
		var from := PlanGrid.parse_cells(plan.attr(grid_id, "depuis"))[0]
		var facing: Vector2i = FACINGS[plan.attr(grid_id, "face")]
		assert_eq(from + facing, clue, "%s : depuis + face = l'indice" % grid_id)
		var table := _maps[map_id].get_interactions()
		var found := table.find(clue, facing)
		assert_not_null(found, "%s : EXAMINER face à l'indice" % grid_id)
		if found == null:
			continue
		assert_eq(found.kind, Interaction.Kind.EXAMINE)
		assert_eq(found.dialogue_id, HIDDEN[grid_id][0])
		assert_eq(found.unless_flags, [StringName("got_" + String(HIDDEN[grid_id][0]))]
			as Array[StringName])
		for other: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if other != facing:
				assert_null(table.find(clue, other), "%s : pas de côté (%s)" % [grid_id, other])
		var steps := _cutscenes.get_cutscene(HIDDEN[grid_id][0]).variants[0].steps
		assert_eq(steps[0].kind, CutsceneStep.Kind.GIVE, "toast seul, aucune page [D]")
		assert_eq([steps[0].item_id, steps[0].found], [HIDDEN[grid_id][1], true], grid_id)


func test_nothing_stands_on_an_arrow_a_slide_or_a_stop() -> void:
	for map_id: StringName in _maps:
		var map := _maps[map_id]
		var field := map.get_node_or_null(^"SpinTiles") as SpinTileField
		if field == null:
			continue
		var grid := map.get_grid()
		var walkable := func(cell: Vector2i) -> bool:
			return grid.is_in_bounds(cell) and not grid.is_solid(cell) and not grid.is_water(cell)
		var covered: Dictionary[Vector2i, bool] = {}
		for arrow: Vector2i in field.arrows:
			covered[arrow] = true
			var slide := field.slide_from(arrow, walkable)
			for cell: Vector2i in slide.cells:
				covered[cell] = true
		assert_true(field.check(walkable).is_empty(), "%s : dalles valides" % map_id)
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			assert_false(covered.has(spec.cell), "%s : %s sur une dalle ou un trajet" % [map_id,
				spec.id])
		for warp: Warp in map.get_warps().get_all():
			assert_false(covered.has(warp.cell), "%s : passage %s" % [map_id, warp.cell])
		for interaction: Interaction in map.get_interactions().get_all():
			assert_false(covered.has(interaction.cell), "%s : point %s" % [map_id,
				interaction.cell])


func test_every_grunt_and_item_can_be_reached_from_a_walkable_cell() -> void:
	for map_id: StringName in _maps:
		var grid := _maps[map_id].get_grid()
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			var reachable := false
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next := spec.cell + side
				if grid.is_in_bounds(next) and not grid.is_solid(next):
					reachable = true
			assert_true(reachable, "%s : %s a une case voisine praticable" % [map_id, spec.id])


func test_the_closed_office_door_is_examined_from_the_south() -> void:
	var table := _maps[&"rocket_hideout_b4f"].get_interactions()
	for cell: Vector2i in [Vector2i(24, 11), Vector2i(25, 11)]:
		var found := table.find(cell, Vector2i.UP)
		assert_not_null(found, "porte %s" % cell)
		if found != null:
			assert_eq(found.dialogue_id, &"rocket_hideout_b4f_office_door")
			assert_eq(found.unless_flags, [&"rocket_hideout_b4f_door_open"] as Array[StringName])
	assert_eq(_dialogues.get_dialogue(&"rocket_hideout_b4f_office_door").variants[0]
		.pages[0].text, "La porte est verrouillée.", "texte 153")
