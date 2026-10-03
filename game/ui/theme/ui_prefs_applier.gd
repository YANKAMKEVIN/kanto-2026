class_name UiPrefsApplier
extends RefCounted
## Applique [UiPrefs] (taille du texte Grande, contraste renforcé) à un arbre de contrôles déjà
## construit (jalon-06.md §6.12) : les écrans du menu, la boîte de dialogue, le toast.
##
## Pas de signal statique en GDScript : celui qui montre un écran rappelle [method apply] (à
## chaque affichage). L'opération est **idempotente et réversible** : ce que l'applicateur pose
## (surcharge de taille, de couleur, de fond) est retenu en méta ; au passage suivant il le retire
## avant de recalculer, sans toucher aux surcharges que l'écran a posées lui-même (elles servent
## de base). Taille normale et contraste normal : tout est restitué.
##
## - Taille : chaque Label, Button et LineEdit prend [method UiPrefs.font] de sa taille de thème.
## - Contraste : les fonds de panneau et de bouton assez opaques (≥ [constant PANEL_MIN_ALPHA],
##   donc pas les voiles de 6 %) deviennent [method UiPrefs.panel_bg] ; le texte secondaire
##   (TEXT_MUTED) prend [method UiPrefs.text_muted].

const META_FONT := &"_uip_font"
const META_COLOR := &"_uip_color"
const META_BOXES := &"_uip_boxes"
## En dessous, un fond est un voile décoratif (lignes, cases) et reste tel quel.
const PANEL_MIN_ALPHA := 0.5
const BOX_NAMES: Array[StringName] = [&"panel", &"normal", &"hover", &"pressed",
	&"hover_pressed", &"disabled"]


## Vrai quand les préférences sont celles par défaut (rien à poser).
static func is_neutral() -> bool:
	return is_equal_approx(UiPrefs.text_scale, 1.0) and not UiPrefs.high_contrast


## Applique les préférences courantes à [param root] et à tous ses descendants.
static func apply(root: Node) -> void:
	if root == null:
		return
	var control := root as Control
	if control != null:
		_fit_font(control)
		_fit_boxes(control)
		_fit_color(control)
	for child: Node in root.get_children():
		if not child.is_queued_for_deletion():
			apply(child)


static func _fit_font(control: Control) -> void:
	if not (control is Label or control is Button or control is LineEdit):
		return
	if control.has_meta(META_FONT):
		# (base, posée, surcharge de l'écran avant nous : 1 / 0)
		var done: Vector3i = control.get_meta(META_FONT)
		if control.has_theme_font_size_override(&"font_size") \
				and control.get_theme_font_size(&"font_size") == done.y:
			control.remove_theme_font_size_override(&"font_size")
			if done.z == 1:
				control.add_theme_font_size_override(&"font_size", done.x)
		control.remove_meta(META_FONT)
	if is_equal_approx(UiPrefs.text_scale, 1.0):
		return
	var base := control.get_theme_font_size(&"font_size")
	var scaled := UiPrefs.font(base)
	if scaled != base:
		var had := 1 if control.has_theme_font_size_override(&"font_size") else 0
		control.add_theme_font_size_override(&"font_size", scaled)
		control.set_meta(META_FONT, Vector3i(base, scaled, had))


static func _fit_boxes(control: Control) -> void:
	if not (control is PanelContainer or control is Panel or control is Button):
		return
	if control.has_meta(META_BOXES):
		# nom → [posé, surcharge de l'écran avant nous ou null]
		var done: Dictionary = control.get_meta(META_BOXES)
		for key: StringName in done:
			if control.get_theme_stylebox(key) == done[key][0]:
				control.remove_theme_stylebox_override(key)
				if done[key][1] != null:
					control.add_theme_stylebox_override(key, done[key][1])
		control.remove_meta(META_BOXES)
	if not UiPrefs.high_contrast:
		return
	var added: Dictionary = {}
	for key: StringName in BOX_NAMES:
		var box := control.get_theme_stylebox(key) as StyleBoxFlat
		if box == null or box.bg_color.a < PANEL_MIN_ALPHA:
			continue
		var wanted := UiPrefs.panel_bg(box.bg_color)
		if wanted == box.bg_color:
			continue
		var copy := box.duplicate() as StyleBoxFlat
		copy.bg_color = wanted
		var original: StyleBox = box if control.has_theme_stylebox_override(key) else null
		control.add_theme_stylebox_override(key, copy)
		added[key] = [copy, original]
	if not added.is_empty():
		control.set_meta(META_BOXES, added)


static func _fit_color(control: Control) -> void:
	if not (control is Label):
		return
	if control.has_meta(META_COLOR):
		var done: Color = control.get_meta(META_COLOR)
		if control.get_theme_color(&"font_color") == done:
			control.remove_theme_color_override(&"font_color")
		control.remove_meta(META_COLOR)
	if not UiPrefs.high_contrast or control.has_theme_color_override(&"font_color"):
		return
	var color := control.get_theme_color(&"font_color")
	if color.is_equal_approx(UiTokens.TEXT_MUTED):
		var wanted := UiPrefs.text_muted()
		control.add_theme_color_override(&"font_color", wanted)
		control.set_meta(META_COLOR, wanted)
