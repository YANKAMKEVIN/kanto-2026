extends SceneTree
## Images provisoires du jalon JOH1 (`docs/tech/jalon-joh1.md` §0 « Art », §2.2), générées sans
## aucun asset (lot d'art de Johto à venir, « Reportés ») :
##   - `assets/world/props/placeholder/lugia_shadow.png` : l'ombre de Lugia sous l'eau profonde de
##     la salle 2 de la grotte marine (ellipse sombre et floue, 256 × 96 px, affichée en Sprite2D
##     par `build_joh1_sea_cave.gd`, animée par la scène `sea_cave_lugia_shadow`) ;
##   - `assets/ui/items/pearl.webp` : icône du Sac de la Perle (256 × 256, comme les icônes
##     provisoires des objets d'évolution du JOH0).
## Idempotent : une image identique n'est pas réécrite.
##
##   godot --headless --path . -s res://tools/build_joh1_placeholders.gd
##   godot --headless --path . --import

const SHADOW_PATH: String = "res://assets/world/props/placeholder/lugia_shadow.png"
const PEARL_PATH: String = "res://assets/ui/items/pearl.webp"
const SHADOW_SIZE := Vector2i(256, 96)
const ICON_SIZE: int = 256

var _errors: int = 0
var _written: int = 0


func _init() -> void:
	_write(_shadow(), SHADOW_PATH)
	_write(_pearl(), PEARL_PATH)
	print("build_joh1_placeholders : %s" % ("%d erreur(s)" % _errors if _errors > 0
		else "%d image(s) écrite(s)" % _written))
	quit(0 if _errors == 0 else 1)


## Ombre : ellipse bleu nuit, bord fondu, plus dense au centre (vue sous l'eau).
func _shadow() -> Image:
	var image := Image.create(SHADOW_SIZE.x, SHADOW_SIZE.y, false, Image.FORMAT_RGBA8)
	var center := Vector2(SHADOW_SIZE) / 2.0
	var radii := Vector2(118.0, 36.0)
	for y: int in SHADOW_SIZE.y:
		for x: int in SHADOW_SIZE.x:
			var p := (Vector2(x + 0.5, y + 0.5) - center) / radii
			# Silhouette : corps allongé, deux « ailes » évasées vers l'arrière.
			var d := p.length()
			var wing := absf(p.y) - 0.25 - 0.55 * maxf(0.0, -p.x)
			var inside := minf(1.0 - d, 0.6 - wing)
			var alpha := clampf(inside * 2.2, 0.0, 1.0)
			alpha = alpha * alpha * (3.0 - 2.0 * alpha) * 0.62
			image.set_pixel(x, y, Color(0.02, 0.05, 0.12, alpha))
	return image


## Perle : sphère nacrée, reflet en haut à gauche, ombre douce au sol.
func _pearl() -> Image:
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(128.0, 120.0)
	var radius := 84.0
	for y: int in ICON_SIZE:
		for x: int in ICON_SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			var color := Color(0.0, 0.0, 0.0, 0.0)
			# Ombre portée.
			var shadow := (p - Vector2(132.0, 214.0)) / Vector2(92.0, 22.0)
			var sa := clampf(1.0 - shadow.length(), 0.0, 1.0)
			if sa > 0.0:
				color = Color(0.08, 0.06, 0.12, sa * sa * 0.45)
			var d := (p - center).length()
			if d <= radius:
				var t := d / radius
				var light := clampf(1.0 - ((p - (center + Vector2(-30.0, -34.0))).length()
					/ (radius * 1.35)), 0.0, 1.0)
				var base := Color(0.93, 0.88, 0.94).lerp(Color(0.72, 0.70, 0.86), t * t)
				base = base.lerp(Color(1.0, 0.98, 0.96), light * 0.55)
				# Teinte nacrée : rose vers le bas droit, bleu vers le haut.
				var hue := Color(0.96, 0.82, 0.90).lerp(Color(0.80, 0.90, 1.0),
					clampf(0.5 - p.y / ICON_SIZE + 0.5, 0.0, 1.0))
				base = base.lerp(hue, 0.25)
				var edge := clampf((radius - d) / 2.0, 0.0, 1.0)
				color = Color(base.r, base.g, base.b, edge)
				# Reflet.
				var hl := (p - (center + Vector2(-28.0, -36.0))).length()
				if hl < 22.0:
					var h := clampf((22.0 - hl) / 10.0, 0.0, 1.0) * 0.85
					color = color.lerp(Color(1.0, 1.0, 1.0, 1.0), h)
			image.set_pixel(x, y, color)
	return image


func _write(image: Image, path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if FileAccess.file_exists(absolute):
		var old := Image.load_from_file(absolute)
		if old != null:
			old.convert(image.get_format())
			if old.get_size() == image.get_size() and old.get_data() == image.get_data():
				return
	var err := image.save_webp(absolute) if path.ends_with(".webp") else image.save_png(absolute)
	if err != OK:
		push_error("build_joh1_placeholders : %s (%d)" % [path, err])
		_errors += 1
		return
	_written += 1
	print("écrit : %s" % path)
