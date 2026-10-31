extends SceneTree
## Lot DAF.10d (fiche `docs/design/fiches-assets/daf-10d/fiche.md`, RP-277, RP-280) : habille les salles
## de la Ligue (Olga, Aldo, Agatha, Peter, Champion), le Panthéon, le hall du Labo de Cramois'Île et
## l'étage type de Sylphe SARL (5F) ; les salles de la Ligue et le Panthéon ont leurs faces de mur et leurs
## objets de thème peints par Codex depuis le 2026-10-31 (`tools/art/daf10d_codex.py`). Seconde passe d'image sur le modèle de `build_daf10a_arene.gd` : **la logique
## ne change pas** (gel du J33). Tout ce qui est ajouté porte le préfixe `Daf10d` (ignoré par
## `dump_map_nodes.gd`) et n'a aucune emprise : les objets debout ne sont posés que sur des cases déjà
## bloquées, le sol praticable ne reçoit que du plat (tapis, lueurs).
##
## Deux modes :
## - « salle » (Ligue, Panthéon, écrits en tuiles provisoires `InteriorTiles`) : tuiles masquées, sol
##   répété, masse de mur, faces peintes au bas des murs, voile sur les murs profonds, ombres au pied des
##   murs latéraux, objets du thème sur les piliers et le long des murs ;
## - « coque » (Labo, Sylphe, déjà peints) : seulement des objets, des tapis et des lueurs.
##
##   godot --headless --path . -s res://tools/build_daf10d.gd [-- <map_id>…]

const MAPS: String = "res://game/world/maps/%s.tscn"
const GROUND: String = "res://assets/world/ground/%s.png"
const RELIEF: String = "res://assets/world/relief/%s.png"
const PROPS: String = "res://assets/world/props/%s.png"
const INT: String = "res://assets/world/interiors/%s.png"
const TILE: int = 96
const PREFIX: String = "Daf10d"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const DECOR_Z: int = -2

const BLANC := Color(1, 1, 1)

## Thèmes des salles. `faces` : bas de mur (2 cases de large) ; `murs` : objets posés tous les `pas`
## cases de face ; `piliers` : cases bloquées isolées dans la salle ; `objets` : [image, x, y (pied, en
## cases), teinte, échelle] ; `tapis` : [image, Rect2 en cases, marge du neuf-carreaux] ;
## `lueurs` : [x, y (centre, en cases), rayon en cases].
var THEMES: Dictionary = {
	&"league_lorelei": {
		"mode": "salle", "sol": GROUND % "ground_glace_01", "sol_teinte": Color(0.92, 0.97, 1.05),
		"masse": GROUND % "ground_azuree_bas_01", "masse_teinte": Color(0.70, 0.80, 0.95),
		"faces": [RELIEF % "relief_mur_ligue_glace_01", RELIEF % "relief_mur_ligue_glace_02"],
		"face_teinte": BLANC,
		"murs": [INT % "int_colonne_glace_01"], "pas": 2, "mur_teinte": BLANC,
		"piliers": [INT % "int_colonne_glace_01"], "pilier_teinte": BLANC,
		"objets": [[INT % "int_colonne_glace_01", 2.5, 6.8, BLANC, 1.0],
			[INT % "int_colonne_glace_01", 7.5, 6.8, BLANC, 1.0]],
		"voile": Color(0.03, 0.06, 0.12), "lueur": Color(0.55, 0.80, 1.0, 0.22),
		"lueurs": [[5, 3.5, 3.2], [5, 8.5, 2.2]], "ombre": 0.30,
	},
	&"league_bruno": {
		"mode": "salle", "sol": GROUND % "ground_victoire_haut_01", "sol_teinte": BLANC,
		"masse": GROUND % "ground_masse_grotte_sombre_01", "masse_teinte": BLANC,
		"faces": [RELIEF % "relief_mur_ligue_roche_01", RELIEF % "relief_mur_ligue_roche_02"],
		"face_teinte": BLANC,
		"murs": [INT % "int_brasero_ligue_01"], "pas": 3, "mur_teinte": BLANC,
		"piliers": [INT % "int_brasero_ligue_01"], "pilier_teinte": BLANC,
		"voile": Color(0.06, 0.04, 0.03), "lueur": Color(1.0, 0.62, 0.30, 0.20),
		"lueurs": [[5, 3, 3.0], [5, 7, 2.4]], "ombre": 0.35,
	},
	&"league_agatha": {
		"mode": "salle", "sol": GROUND % "ground_dalles_tour_01", "sol_teinte": Color(0.78, 0.72, 0.92),
		"masse": GROUND % "ground_masse_manoir_b1_01", "masse_teinte": Color(0.55, 0.48, 0.70),
		"faces": [RELIEF % "relief_mur_ligue_spectre_01", RELIEF % "relief_mur_ligue_spectre_02"],
		"face_teinte": BLANC,
		"murs": [INT % "int_candelabre_ligue_01", INT % "int_tombe_tour_01", INT % "int_tombe_tour_03"],
		"pas": 2, "mur_teinte": Color(0.85, 0.80, 1.0),
		"piliers": [INT % "int_tombe_tour_02"], "pilier_teinte": Color(0.82, 0.76, 0.98),
		"voile": Color(0.06, 0.03, 0.10), "lueur": Color(0.62, 0.42, 1.0, 0.24),
		"lueurs": [[2.5, 2, 1.6], [7.5, 2, 1.6], [5, 6, 2.6]], "ombre": 0.40,
	},
	&"league_lance": {
		"mode": "salle", "sol": GROUND % "ground_victoire_bas_01", "sol_teinte": Color(0.92, 0.82, 0.78),
		"masse": GROUND % "ground_masse_arene_01", "masse_teinte": BLANC,
		"faces": [RELIEF % "relief_mur_ligue_dragon_01", RELIEF % "relief_mur_ligue_dragon_02"],
		"face_teinte": BLANC,
		"murs": [INT % "int_statue_dragon_01", INT % "int_brasero_ligue_01"], "pas": 2, "mur_teinte": BLANC,
		"piliers": [INT % "int_statue_dragon_01"], "pilier_teinte": BLANC,
		"tapis": [[INT % "int_tapis_rouge_01", Rect2(5, 1, 2, 12), 44],
			[INT % "int_tapis_rouge_01", Rect2(3, 14, 6, 10), 44],
			[INT % "int_tapis_rouge_01", Rect2(9, 23, 8, 2), 44],
			[INT % "int_tapis_rouge_01", Rect2(17, 19, 2, 4), 44],
			[INT % "int_tapis_rouge_01", Rect2(17, 15, 8, 4), 44]],
		"voile": Color(0.08, 0.03, 0.02), "lueur": Color(1.0, 0.45, 0.20, 0.22),
		"lueurs": [[6, 4, 2.0], [6, 10, 2.0], [6, 18.5, 3.2], [13, 23.5, 2.4], [21, 17, 2.8]],
		"ombre": 0.38,
	},
	&"league_champion": {
		"mode": "salle", "sol": GROUND % "ground_dalles_morgane_01", "sol_teinte": Color(1.0, 0.97, 0.95),
		"masse": GROUND % "ground_masse_manoir_01", "masse_teinte": BLANC,
		"faces": [RELIEF % "relief_mur_ligue_champion_01", RELIEF % "relief_mur_ligue_champion_02"],
		"face_teinte": BLANC, "murs": [], "pas": 99, "mur_teinte": BLANC,
		"piliers": [INT % "int_colonne_champion_01"], "pilier_teinte": BLANC,
		"tapis": [[INT % "int_tapis_rouge_01", Rect2(3, 0.6, 2, 7.4), 44]],
		"voile": Color(0.07, 0.03, 0.04), "lueur": Color(1.0, 0.80, 0.45, 0.22),
		"lueurs": [[4, 2.5, 2.2], [4, 5.5, 2.2]], "ombre": 0.32,
	},
	&"hall_of_fame": {
		"mode": "salle", "sol": GROUND % "ground_dalles_morgane_01", "sol_teinte": BLANC,
		"masse": GROUND % "ground_masse_manoir_b1_01", "masse_teinte": BLANC,
		"faces": [RELIEF % "relief_mur_ligue_pantheon_01", RELIEF % "relief_mur_ligue_pantheon_02"],
		"face_teinte": BLANC, "murs": [], "pas": 99, "mur_teinte": BLANC,
		"piliers": [], "pilier_teinte": BLANC, "sans_face": [Vector2i(4, 1), Vector2i(5, 1)],
		"objets": [[INT % "int_machine_pantheon_01", 5.0, 2.0, BLANC, 1.0],
			[INT % "int_vitrine_rubans_01", 2.0, 1.0, BLANC, 1.0],
			[INT % "int_vitrine_rubans_01", 8.0, 1.0, BLANC, 1.0]],
		"tapis": [[INT % "int_tapis_rouge_01", Rect2(4, 2, 2, 5), 44]],
		"voile": Color(0.05, 0.03, 0.08), "lueur": Color(1.0, 0.85, 0.55, 0.24),
		"lueurs": [[5, 2.5, 2.2], [2, 3, 1.6], [8, 3, 1.6], [5, 5.5, 2.4]], "ombre": 0.30,
	},
	&"cinnabar_lab": {
		"mode": "coque",
		"objets": [[INT % "int_etagere_labo_01", 3.0, 4.0, BLANC, 1.0],
			[INT % "int_machines_labo_01", 8.0, 4.0, BLANC, 1.0],
			[INT % "int_classeur_01", 10.5, 4.0, BLANC, 1.0],
			[INT % "int_plante_sylphe_01", 11.5, 4.0, BLANC, 1.0],
			[INT % "int_plante_sylphe_01", 14.5, 4.0, BLANC, 1.0],
			[INT % "int_plante_sylphe_01", 17.5, 4.0, BLANC, 1.0],
			[INT % "int_plante_sylphe_01", 20.5, 4.0, BLANC, 1.0],
			[INT % "int_plante_sylphe_01", 23.5, 4.0, BLANC, 1.0],
			[INT % "int_paillasse_01", 13.5, 9.0, BLANC, 1.0],
			[INT % "int_plante", 1.5, 5.0, BLANC, 0.62], [INT % "int_plante", 1.5, 10.0, BLANC, 0.62],
			[INT % "int_plante", 25.5, 5.0, BLANC, 0.62], [INT % "int_plante", 25.5, 10.0, BLANC, 0.62]],
		"tapis": [[INT % "int_tapis_labo_pokeball_01", Rect2(5, 5, 4, 4), 0],
			[INT % "int_tapis_labo_pokeball_01", Rect2(18, 5, 4, 4), 0]],
		"lueur": Color(1.0, 0.78, 0.48, 0.20),
		"lueurs": [[7, 6.5, 3.0], [13.5, 6.5, 3.2], [20, 6.5, 3.0], [4.5, 9.5, 1.8]],
	},
	&"silph_co_5f": {
		"mode": "coque",
		"sols": [[GROUND % "ground_moquette_sylphe_01", Rect2(16, 5, 11, 10), Color(0.74, 0.82, 1.0)],
			[GROUND % "ground_moquette_sylphe_01", Rect2(10, 1, 4, 4), Color(0.74, 0.82, 1.0)]],
		"objets": [[INT % "int_plante_sylphe_01", 16.5, 5.0, BLANC, 1.0],
			[INT % "int_plante_sylphe_01", 21.5, 5.0, BLANC, 1.0],
			[INT % "int_plante_sylphe_01", 24.5, 5.0, BLANC, 1.0]],
		"tapis": [[INT % "int_tapis_salon_01", Rect2(2, 4, 4, 3), 0],
			[INT % "int_tapis_salon_01", Rect2(11, 12, 3, 2), 0]],
		"lueur": Color(1.0, 0.86, 0.62, 0.16),
		"lueurs": [[21, 7.5, 3.4], [21, 12.5, 3.4], [4, 5, 3.0], [13, 4, 2.6], [13, 12, 2.6],
			[4, 13.5, 2.6], [17, 16.5, 3.0], [26, 16.5, 3.0]],
	},
	# Lot DAF.10c (reste de RP-280) : autres étages de Sylphe, habillés comme le 5F d'après leur grille
	# ([method _auto_theme]).
	&"silph_co_2f": {"auto": "sylphe_2f"},
	&"silph_co_3f": {"auto": "sylphe_3f"},
	&"silph_co_4f": {"auto": "sylphe_4f"},
	&"silph_co_6f": {"auto": "sylphe_6f"},
	&"silph_co_7f": {"auto": "sylphe_7f"},
	&"silph_co_8f": {"auto": "sylphe_8f"},
	&"silph_co_9f": {"auto": "sylphe_9f"},
	&"silph_co_10f": {"auto": "sylphe_10f"},
	&"silph_co_11f": {"auto": "sylphe_11f"},
}
## Mode « auto » (Sylphe) : moquette bleutée sous les zones de bureaux (rectangle des meubles `M`
## agrandi d'une case) des salles qui en ont au moins [constant AUTO_DESKS], plantes contre la
## cloison nord de ces zones (une case sur
## [constant AUTO_PLANT_STEP], au plus [constant AUTO_PLANTS] par salle), lueurs chaudes sur une
## trame de [constant AUTO_GLOW_STEP] cases (au plus [constant AUTO_GLOWS]) [D].
const AUTO_DESKS: int = 4
const AUTO_PLANT_STEP: int = 4
const AUTO_PLANTS: int = 3
const AUTO_GLOW_STEP: int = 5
const AUTO_GLOWS: int = 10
const AUTO_TINT := Color(0.74, 0.82, 1.0)

var _errors: int = 0


func _init() -> void:
	var only := OS.get_cmdline_user_args()
	for map_id: StringName in THEMES:
		if only.is_empty() or String(map_id) in only:
			var theme: Dictionary = THEMES[map_id]
			if theme.has("auto"):
				theme = _auto_theme(theme["auto"])
			if not theme.is_empty():
				_build(map_id, theme)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName, theme: Dictionary) -> void:
	var path := MAPS % map_id
	var probe := (load(path) as PackedScene).instantiate()
	var grid = probe.get_grid()
	var size: Vector2i = probe.size
	var solid: Dictionary = {}
	for y: int in size.y:
		for x: int in size.x:
			if grid.is_solid(Vector2i(x, y)):
				solid[Vector2i(x, y)] = true
	probe.free()
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	var decor := Node2D.new()
	decor.name = PREFIX + "Decor"
	decor.z_index = DECOR_Z
	_attach(root, root, decor)
	var entities := root.get_node(^"Entities") as Node2D
	var placed := 0
	if theme["mode"] == "salle":
		placed = _room(root, decor, entities, size, solid, theme)
	for sol: Array in theme.get("sols", []):
		_floor_patch(root, decor, sol[0], sol[1], sol[2])
	for t: Array in theme.get("tapis", []):
		_rug(root, decor, t[0], t[1], t[2])
	for o: Array in theme.get("objets", []):
		_sprite(root, entities, "%sObjet_%d" % [PREFIX, placed], o[0], Vector2(o[1] * TILE, o[2] * TILE),
			o[3], o[4])
		placed += 1
	var glow := _glow_texture()
	var i := 0
	for l: Array in theme.get("lueurs", []):
		var s := Sprite2D.new()
		s.name = "Lueur_%d" % i
		s.texture = glow
		s.modulate = theme["lueur"]
		s.position = Vector2(l[0] * TILE, l[1] * TILE)
		s.scale = Vector2.ONE * (l[2] * TILE * 2.0 / glow.get_width())
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = m
		_attach(root, decor, s)
		i += 1
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("%s : enregistrement impossible (%d)" % [map_id, err])
		_errors += 1
	else:
		print("%s : %d objets debout, %d tapis, %d lueurs" % [map_id, placed,
			theme.get("tapis", []).size(), theme.get("lueurs", []).size()])
	root.free()


## Salle en tuiles provisoires : renvoie le nombre d'objets debout posés.
func _room(root: Node2D, decor: Node2D, entities: Node2D, size: Vector2i, solid: Dictionary,
		theme: Dictionary) -> int:
	for layer_name: String in ["Ground", "Detail", "Obstacles", "Overhead"]:
		var layer := root.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		if layer != null:
			layer.visible = false
	var wall := func(c: Vector2i) -> bool:
		return solid.has(c) or c.x < 0 or c.y < 0 or c.x >= size.x or c.y >= size.y
	var floor_tex: Texture2D = load(theme["sol"])
	var floor := _repeat("Sol", floor_tex, Rect2(0, 0, size.x * TILE, size.y * TILE))
	floor.modulate = theme["sol_teinte"]
	_attach(root, decor, floor)
	var pillars: Dictionary = {}
	var masses: Dictionary = {}
	for c: Vector2i in solid:
		var free_ns: bool = not wall.call(c + Vector2i.UP) and not wall.call(c + Vector2i.DOWN)
		var free_ew: bool = not wall.call(c + Vector2i.LEFT) and not wall.call(c + Vector2i.RIGHT)
		if (free_ns or free_ew) and not theme.get("sans_face", []).has(c):
			pillars[c] = true
		else:
			masses[c] = true
	var masse_tex: Texture2D = load(theme["masse"])
	for y: int in size.y:
		for run: Vector2i in _runs(masses, y, size.x):
			var r := Rect2(run.x * TILE, y * TILE, (run.y - run.x + 1) * TILE, TILE)
			var s := _repeat("Masse_%d_%d" % [run.x, y], masse_tex, r)
			s.modulate = theme["masse_teinte"]
			_attach(root, decor, s)
	# Ombres au pied des murs latéraux (sur le sol, côté salle).
	var shade: float = theme["ombre"]
	for c: Vector2i in masses:
		for side: int in [-1, 1]:
			var n := c + Vector2i(side, 0)
			if wall.call(n):
				continue
			var x0 := float(n.x * TILE) if side == 1 else float((n.x + 1) * TILE)
			var x1 := x0 + 26.0 * side
			var p := Polygon2D.new()
			p.name = "Ombre_%d_%d_%d" % [c.x, c.y, side]
			p.polygon = PackedVector2Array([Vector2(x0, c.y * TILE), Vector2(x1, c.y * TILE),
				Vector2(x1, (c.y + 1) * TILE), Vector2(x0, (c.y + 1) * TILE)])
			p.vertex_colors = PackedColorArray([Color(0, 0, 0, shade), Color(0, 0, 0, 0),
				Color(0, 0, 0, 0), Color(0, 0, 0, shade)])
			_attach(root, decor, p)
	# Voile : murs à plus d'une case du sol.
	var veil: Color = theme["voile"]
	for y: int in size.y:
		for x: int in size.x:
			var c := Vector2i(x, y)
			if not masses.has(c):
				continue
			var near := 9
			for dy: int in range(-3, 4):
				for dx: int in range(-3, 4):
					var o := c + Vector2i(dx, dy)
					if o.x >= 0 and o.y >= 0 and o.x < size.x and o.y < size.y and not solid.has(o):
						near = mini(near, maxi(absi(dx), absi(dy)))
			if near < 2:
				continue
			var p := Polygon2D.new()
			p.name = "Voile_%d_%d" % [x, y]
			p.color = Color(veil, 0.5 if near == 2 else 0.85)
			p.polygon = PackedVector2Array([Vector2(x * TILE, y * TILE), Vector2((x + 1) * TILE, y * TILE),
				Vector2((x + 1) * TILE, (y + 1) * TILE), Vector2(x * TILE, (y + 1) * TILE)])
			_attach(root, decor, p)
	# Faces au bas des murs donnant sur le sol.
	var faces: Dictionary = {}
	for c: Vector2i in masses:
		if not wall.call(c + Vector2i.DOWN):
			faces[c] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(root.name))
	var face_ids: Array = theme["faces"]
	for y: int in size.y:
		for run: Vector2i in _runs(faces, y, size.x):
			var x := run.x
			while x <= run.y:
				var w := mini(2, run.y - x + 1)
				var tex: Texture2D = load(face_ids[rng.randi() % face_ids.size()])
				var s := Sprite2D.new()
				s.name = "Face_%d_%d" % [x, y]
				s.texture = tex
				s.centered = false
				s.modulate = theme["face_teinte"]
				s.region_enabled = true
				var rw := mini(w * TILE, tex.get_width())
				s.region_rect = Rect2(0, 0, rw, tex.get_height())
				s.scale = Vector2(float(w * TILE) / rw, 1.0)
				s.position = Vector2(x * TILE, (y + 1) * TILE - tex.get_height())
				_attach(root, decor, s)
				x += w
	var placed := 0
	var pillar_ids: Array = theme["piliers"]
	var k := 0
	for c: Vector2i in _sorted(pillars):
		if pillar_ids.is_empty():
			break
		_sprite(root, entities, "%sPilier_%d_%d" % [PREFIX, c.x, c.y], pillar_ids[k % pillar_ids.size()],
			Vector2((c.x + 0.5) * TILE, (c.y + 1) * TILE), theme["pilier_teinte"], 1.0)
		var under := _repeat("SolPilier_%d_%d" % [c.x, c.y], floor_tex,
			Rect2(c.x * TILE, c.y * TILE, TILE, TILE))
		under.modulate = theme["sol_teinte"]
		_attach(root, decor, under)
		k += 1
		placed += 1
	# Objets le long des murs : une face sur `pas`, jamais au bord d'une ouverture.
	var wall_ids: Array = theme["murs"]
	var step: int = theme["pas"]
	k = 0
	var n := 0
	for c: Vector2i in _sorted(faces):
		if wall_ids.is_empty():
			break
		if not wall.call(c + Vector2i.LEFT) or not wall.call(c + Vector2i.RIGHT):
			continue
		n += 1
		if n % step != 0:
			continue
		_sprite(root, entities, "%sMur_%d_%d" % [PREFIX, c.x, c.y], wall_ids[k % wall_ids.size()],
			Vector2((c.x + 0.5) * TILE, (c.y + 1) * TILE), theme["mur_teinte"], 1.0)
		k += 1
		placed += 1
	return placed


func _repeat(node_name: String, texture: Texture2D, rect: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = node_name
	s.texture = texture
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(fposmod(rect.position.x, texture.get_width()),
		fposmod(rect.position.y, texture.get_height()), rect.size.x, rect.size.y)
	s.position = rect.position
	return s


func _floor_patch(root: Node, decor: Node, path: String, cells: Rect2, tint: Color) -> void:
	var s := _repeat("Moquette_%d_%d" % [cells.position.x, cells.position.y], load(path),
		Rect2(cells.position * TILE, cells.size * TILE))
	s.modulate = tint
	_attach(root, decor, s)


## Tapis : neuf-carreaux étiré sur [param cells] (bordure gardée) ; marge 0 = image entière mise à
## l'échelle.
func _rug(root: Node, decor: Node, path: String, cells: Rect2, margin: int) -> void:
	var texture: Texture2D = load(path)
	var r := NinePatchRect.new()
	r.name = "Tapis_%d_%d" % [int(cells.position.x * 10), int(cells.position.y * 10)]
	r.texture = texture
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = cells.position * TILE + Vector2(6, 6)
	r.size = cells.size * TILE - Vector2(12, 12)
	if margin > 0:
		r.patch_margin_left = margin
		r.patch_margin_right = margin
		r.patch_margin_top = margin
		r.patch_margin_bottom = margin
		r.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		r.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	_attach(root, decor, r)


func _glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.45))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _sprite(root: Node, parent: Node, node_name: String, path: String, foot: Vector2, tint: Color,
		scale_factor: float) -> void:
	var s := Sprite2D.new()
	s.name = node_name
	s.texture = load(path)
	if s.texture == null:
		push_error("%s : image absente %s" % [root.name, path])
		_errors += 1
		return
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.scale = Vector2.ONE * scale_factor
	s.position = foot
	s.modulate = tint
	_attach(root, parent, s)


func _sorted(cells: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(cells.keys())
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


func _runs(cells: Dictionary, y: int, width: int) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	for x: int in width:
		if not cells.has(Vector2i(x, y)):
			continue
		if not runs.is_empty() and runs[-1].y == x - 1:
			runs[-1].y = x
		else:
			runs.append(Vector2i(x, x))
	return runs


func _attach(root: Node, parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = root
	for child: Node in node.get_children():
		_own(child, root)


func _own(node: Node, root: Node) -> void:
	node.owner = root
	for child: Node in node.get_children():
		_own(child, root)


func _clean(root: Node) -> void:
	for parent: Node in [root, root.get_node(^"Entities")]:
		for child: Node in parent.get_children():
			if String(child.name).begins_with(PREFIX):
				parent.remove_child(child)
				child.free()


## Thème « coque » d'un étage de Sylphe tiré de sa grille `tools/plans/<plan>.txt` (salles = taches
## 4-connexes de cases praticables hors portes `K`). Les plantes sont posées sur des cases `#` déjà
## bloquées ; la moquette et les lueurs sont plates.
func _auto_theme(plan_name: String) -> Dictionary:
	var plan := PlanGrid.new()
	if not plan.load_file("res://tools/plans/%s.txt" % plan_name):
		push_error("%s : %s" % [plan_name, plan.error])
		_errors += 1
		return {}
	var room_of: Dictionary = {}
	var rooms: Array = []
	for y: int in plan.height:
		for x: int in plan.width:
			var start := Vector2i(x, y)
			if room_of.has(start) or not _room_cell(plan, start):
				continue
			var cells: Array[Vector2i] = [start]
			room_of[start] = rooms.size()
			var k := 0
			while k < cells.size():
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n := cells[k] + d
					if not room_of.has(n) and _room_cell(plan, n):
						room_of[n] = rooms.size()
						cells.append(n)
				k += 1
			rooms.append(cells)
	var carpet: Dictionary = {}
	var plants: Array = []
	var glows: Array = []
	for index: int in rooms.size():
		var cells: Array = rooms[index]
		var desks: Dictionary = {}
		for cell: Vector2i in cells:
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if _mark(plan, cell + d) == "M":
					desks[cell + d] = true
		if desks.size() >= AUTO_DESKS:
			# Zone de bureaux : rectangle des meubles agrandi d'une case, sur la salle et ses meubles.
			var zone := Rect2i(desks.keys()[0], Vector2i.ONE)
			for cell: Vector2i in desks:
				zone = zone.expand(cell).expand(cell + Vector2i.ONE)
			zone = zone.grow(1)
			for cell: Vector2i in cells:
				if zone.has_point(cell):
					carpet[cell] = true
			for cell: Vector2i in desks:
				carpet[cell] = true
			var count := 0
			var run := 0
			var ordered: Array = cells.duplicate()
			ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
			var previous := Vector2i(-9, -9)
			for cell: Vector2i in ordered:
				if cell != previous + Vector2i.RIGHT:
					run = 0
				previous = cell
				var wall := cell + Vector2i.UP
				var ok := carpet.has(cell) and wall.y >= 1 and _mark(plan, cell) == "." and _mark(plan, wall) == "#" \
					and _mark(plan, wall + Vector2i.LEFT) == "#" and _mark(plan, wall + Vector2i.RIGHT) == "#"
				run = run + 1 if ok else 0
				if ok and run % AUTO_PLANT_STEP == 2 and count < AUTO_PLANTS:
					plants.append([INT % "int_plante_sylphe_01", wall.x + 0.5, wall.y + 1.0, BLANC, 1.0])
					count += 1
		for cell: Vector2i in cells:
			if glows.size() < AUTO_GLOWS and cells.size() >= 6 and cell.x % AUTO_GLOW_STEP == 2 \
					and cell.y % AUTO_GLOW_STEP == 2:
				glows.append([cell.x + 0.5, cell.y + 0.5, 3.0])
	var sols: Array = []
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if not carpet.has(Vector2i(x, y)):
				x += 1
				continue
			var x0 := x
			while carpet.has(Vector2i(x, y)):
				x += 1
			sols.append([GROUND % "ground_moquette_sylphe_01", Rect2(x0, y, x - x0, 1), AUTO_TINT])
	return {"mode": "coque", "sols": sols, "objets": plants, "tapis": [],
		"lueur": Color(1.0, 0.86, 0.62, 0.16), "lueurs": glows}


func _mark(plan: PlanGrid, cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height:
		return "#"
	return plan.at(cell)


func _room_cell(plan: PlanGrid, cell: Vector2i) -> bool:
	var mark := _mark(plan, cell)
	return plan.walkable.contains(mark) and mark != "K"
