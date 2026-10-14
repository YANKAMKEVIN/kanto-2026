extends SceneTree
## Planche de contrôle in-game de la série 14 (J12 T6) : les assets préparés, rendus par le
## moteur à 1:1 (case de 96 px, filtre LINEAR), le héros peint à côté de chaque groupe.
## Pas de lumière de grotte (profils `cave_*` : T9) ; aucune carte. Pas en `--headless`.
##
##   godot --path . -s res://tools/capture_serie14.gd -- --out=build/captures/jalon12_t6
##
## Écrit :
## - `personnages.png` : héros, Fillette, Sbires ♂ / ♀, chercheur ; marche (face, gauche,
##   droite, dos) puis attente, sur le sol calme de la grotte (clair) et sur la masse (sombre) ;
## - `relief.png` : paroi d'ardoise et entrée de la grotte sur le sol rocheux de la Route 3,
##   parois de grotte au bord d'une masse ;
## - `objets.png` : repères, camp Rocket, mare, puits de jour, échelles, dalle et fossiles,
##   indices, objets fixes (fossiles, Poké Ball) ;
## - `sols.png` : les quatre textures de sol en mosaïque 3 × 3 (raccords visibles) ;
## - `icones.png` : icônes du Sac (série 14 et existantes), sur fond sombre et clair.

const CELL := 96
const GROUND := "res://assets/world/ground/"
const PROPS := "res://game/world/props/painted/"
const HERO := &"player"
const PEOPLE: Array = [
	[&"lass_young", "Fillette 108"], [&"rocket_grunt_m", "Sbire H 128"],
	[&"rocket_grunt_f", "Sbire F 124 (attente : creuse)"],
	[&"fossil_researcher", "chercheur 128"],
]
const DIRS: Array[String] = ["down", "left", "right", "up"]
const GROUNDS: Array[String] = ["ground_roche_01", "ground_grotte_01", "ground_gravats_01",
	"ground_masse_roche_01"]
const ICONS: Array[String] = ["moon_stone", "escape_rope", "dome_fossil", "helix_fossil",
	"poke_ball", "potion"]

var _out: String = "build/captures/jalon12_t6"
var _rules: GDScript
var _look: GDScript


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	_look = load("res://game/world/character_look.gd")
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	await _save(_people(), "personnages")
	await _save(_relief(), "relief")
	await _save(_objects(), "objets")
	await _save(_grounds(), "sols")
	await _save(_icons(), "icones")
	print("captures : %s" % _out)
	quit()


func _save(viewport: SubViewport, file: String) -> void:
	root.add_child(viewport)
	for i: int in 8:
		await process_frame
	viewport.get_texture().get_image().save_png("res://%s/%s.png" % [_out, file])
	viewport.queue_free()
	await process_frame


func _viewport(cells: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = cells * CELL
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = \
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	return viewport


## Sol répété sur le rectangle [param rect] (cases).
func _floor(parent: Node, texture_id: String, rect: Rect2i) -> void:
	var floor_rect := TextureRect.new()
	floor_rect.texture = load(GROUND + texture_id + ".png")
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
	floor_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_rect.position = Vector2(rect.position * CELL)
	floor_rect.size = Vector2(rect.size * CELL)
	floor_rect.z_index = -3
	parent.add_child(floor_rect)


func _label(parent: Node, text: String, position: Vector2, size: int = 22) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.z_index = 10
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", 6)
	parent.add_child(label)


## Personnage (ou objet fixe) posé pieds au milieu du bas de la case [param cell].
func _figure(parent: Node, sprite: StringName, animation: StringName, cell: Vector2i,
		frame: int = 0) -> void:
	var look: RefCounted = _look.call(&"resolve", sprite)
	var node := AnimatedSprite2D.new()
	node.sprite_frames = load(look.get(&"frames_path"))
	node.animation = animation
	node.frame = frame
	node.texture_filter = look.get(&"filter")
	var texture := node.sprite_frames.get_frame_texture(animation, frame)
	node.centered = false
	node.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	node.position = Vector2(cell.x * CELL + CELL / 2.0, (cell.y + 1) * CELL)
	parent.add_child(node)


func _prop(parent: Node, id: StringName, cell: Vector2i) -> void:
	var prop := (load(PROPS + String(id) + ".tscn") as PackedScene).instantiate() as Node2D
	prop.position = _rules.call(&"foot_position", id, cell)
	prop.set_process(false)
	parent.add_child(prop)


func _sorted(parent: Node) -> Node2D:
	var entities := Node2D.new()
	entities.y_sort_enabled = true
	parent.add_child(entities)
	return entities


func _people() -> SubViewport:
	var viewport := _viewport(Vector2i(20, 11))
	_floor(viewport, "ground_grotte_01", Rect2i(0, 0, 10, 11))
	_floor(viewport, "ground_masse_roche_01", Rect2i(10, 0, 10, 11))
	var entities := _sorted(viewport)
	_label(viewport, "sol calme de la grotte (clair)", Vector2(8, 4))
	_label(viewport, "masse (sombre) : franges et taches", Vector2(10 * CELL + 8, 4))
	var rows: Array = [[HERO, "héros 128"]] + PEOPLE
	for r: int in rows.size():
		var y := 1 + r * 2
		var sprite: StringName = rows[r][0]
		_label(viewport, rows[r][1], Vector2(8, (y - 0.6) * CELL + 50), 18)
		for side: int in 2:
			var x0 := 1 + side * 10
			for d: int in DIRS.size():
				_figure(entities, sprite, StringName("walk_" + DIRS[d]), Vector2i(x0 + d, y), 1)
				_figure(entities, sprite, StringName("idle_" + DIRS[d]), Vector2i(x0 + 4 + d, y))
	return viewport


func _relief() -> SubViewport:
	var viewport := _viewport(Vector2i(24, 11))
	_floor(viewport, "ground_roche_01", Rect2i(0, 0, 12, 11))
	_floor(viewport, "ground_grotte_01", Rect2i(12, 0, 12, 11))
	_floor(viewport, "ground_masse_roche_01", Rect2i(12, 0, 12, 4))
	var ground := Node2D.new()
	viewport.add_child(ground)
	var entities := _sorted(viewport)
	_prop(ground, &"relief_paroi_ardoise_01", Vector2i(3, 2))
	_prop(ground, &"relief_paroi_ardoise_02", Vector2i(8, 2))
	_prop(ground, &"relief_paroi_ardoise_03", Vector2i(3, 6))
	_prop(ground, &"relief_paroi_ardoise_04", Vector2i(8, 6))
	_prop(entities, &"relief_entree_grotte_01", Vector2i(6, 10))
	_figure(entities, HERO, &"idle_up", Vector2i(10, 10))
	_figure(entities, HERO, &"idle_down", Vector2i(1, 10))
	_prop(entities, &"relief_paroi_grotte_01", Vector2i(14, 3))
	_prop(entities, &"relief_paroi_grotte_02", Vector2i(17, 3))
	_prop(entities, &"relief_paroi_grotte_03", Vector2i(20, 3))
	_prop(entities, &"relief_paroi_grotte_04", Vector2i(23, 3))
	_prop(entities, &"relief_paroi_grotte_05", Vector2i(13, 8))
	_prop(entities, &"relief_paroi_grotte_06", Vector2i(18, 8))
	_figure(entities, HERO, &"idle_up", Vector2i(16, 4))
	_figure(entities, HERO, &"idle_down", Vector2i(15, 7))
	_label(viewport, "ardoise 01 / 02 (haut), 03 / 04 ; entrée (Q, 2 cases libres)",
		Vector2(8, 4))
	_label(viewport, "parois de grotte 01 02 03 04 (bord sud de la masse), 05, 06",
		Vector2(12 * CELL + 8, 4 * CELL + 4))
	return viewport


func _objects() -> SubViewport:
	var viewport := _viewport(Vector2i(24, 11))
	_floor(viewport, "ground_grotte_01", Rect2i(0, 0, 24, 11))
	_floor(viewport, "ground_gravats_01", Rect2i(14, 8, 10, 3))
	var ground := Node2D.new()
	viewport.add_child(ground)
	var entities := _sorted(viewport)
	for row: int in [3, 7, 10]:
		_figure(entities, HERO, &"idle_down", Vector2i(1, row))
	var row_a: Array = [[&"prop_colonne_grotte_01", 3], [&"prop_colonne_grotte_02", 5],
		[&"prop_rocher_grotte_01", 7], [&"prop_rocher_grotte_02", 8],
		[&"prop_eclats_lune_01", 10], [&"prop_eclats_lune_02", 11],
		[&"prop_lampe_chantier_01", 13], [&"prop_projecteur_01", 15],
		[&"prop_caisse_r_01", 17], [&"prop_caisse_r_02", 19], [&"prop_outils_fouille_01", 21]]
	for entry: Array in row_a:
		_prop(entities, entry[0], Vector2i(entry[1], 3))
	_prop(ground, &"prop_tranchee_01", Vector2i(3, 7))
	_prop(ground, &"prop_mare_grotte_01", Vector2i(8, 7))
	_prop(ground, &"decal_puits_jour_01", Vector2i(13, 7))
	_figure(entities, HERO, &"idle_down", Vector2i(13, 6))
	_prop(ground, &"prop_echelle_descend_01", Vector2i(16, 7))
	_prop(ground, &"prop_echelle_monte_01", Vector2i(18, 7))
	_prop(entities, &"prop_dalle_01", Vector2i(21, 7))
	_prop(entities, &"prop_fossile_dome_01", Vector2i(20, 7))
	_prop(entities, &"prop_fossile_nautile_01", Vector2i(22, 7))
	_prop(entities, &"prop_indice_caillou_01", Vector2i(3, 10))
	_prop(entities, &"prop_indice_eclat_01", Vector2i(5, 10))
	_figure(entities, &"object/fossil_dome", &"idle_down", Vector2i(7, 10))
	_figure(entities, &"object/fossil_helix", &"idle_down", Vector2i(8, 10))
	_figure(entities, &"object/poke_ball_ground", &"idle_down", Vector2i(10, 10))
	_prop(entities, &"prop_indice_caillou_01", Vector2i(16, 10))
	_prop(entities, &"prop_indice_eclat_01", Vector2i(18, 10))
	_prop(entities, &"prop_rocher_grotte_01", Vector2i(20, 10))
	_figure(entities, HERO, &"idle_down", Vector2i(22, 10))
	_label(viewport, "colonnes, rochers, éclats, lampe, projecteur, caisses R, outils",
		Vector2(8, 4))
	_label(viewport, "tranchée, mare, puits de jour, échelles V / U, dalle + fossiles",
		Vector2(8, 4 * CELL + 4))
	_label(viewport, "indices, fossiles et Poké Ball (objets fixes) ; sur gravats : indices",
		Vector2(8, 8 * CELL + 4))
	return viewport


func _grounds() -> SubViewport:
	var tile := 4 * CELL
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2 * 3 * tile + 32, 2 * 3 * tile + 32)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i: int in GROUNDS.size():
		var origin := Vector2((i % 2) * (3 * tile + 32), (i / 2) * (3 * tile + 32))
		var rect := TextureRect.new()
		rect.texture = load(GROUND + GROUNDS[i] + ".png")
		rect.stretch_mode = TextureRect.STRETCH_TILE
		rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		rect.position = origin
		rect.size = Vector2(3 * tile, 3 * tile)
		viewport.add_child(rect)
		_label(viewport, GROUNDS[i] + " (3 × 3 tuiles de 384 px)", origin + Vector2(8, 4), 28)
	return viewport


func _icons() -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(ICONS.size() * 288 + 32, 2 * 320)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for band: int in 2:
		var back := ColorRect.new()
		back.color = Color("#1c2230") if band == 0 else Color("#e9e4d8")
		back.position = Vector2(0, band * 320)
		back.size = Vector2(viewport.size.x, 320)
		viewport.add_child(back)
		for i: int in ICONS.size():
			var icon := TextureRect.new()
			icon.texture = load("res://assets/ui/items/%s.webp" % ICONS[i])
			icon.position = Vector2(32 + i * 288, band * 320 + 16)
			viewport.add_child(icon)
			_label(viewport, ICONS[i], Vector2(32 + i * 288, band * 320 + 276), 22)
	return viewport
