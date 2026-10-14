class_name ExplorationHud
extends CanvasLayer
## HUD d'exploration (CanvasLayer HUD) : titre de zone, légende sur le monde, toast, joystick
## flottant, bouton courir, bouton contextuel.
##
## Il ne connaît ni le joueur ni la carte : le joystick, le bouton courir et le bouton
## contextuel pressent les actions de l'InputMap (move_*, run, interact) ; la scène qui
## charge la carte appelle show_zone_title, et celle qui connaît la cible devant le joueur
## appelle show_interact(verbe) / hide_interact().
## Le bouton Menu (rond, translucide, MENU_BUTTON_ALPHA) est ancré en haut à droite, à
## SAFE_MARGIN des bords ; il suit les contrôles (caché pendant un dialogue).
## Placement (aspect expand, 1920 à 2340 de large) : titre ancré en haut à gauche,
## joystick sur tout l'écran (apparition dans la moitié gauche), bouton courir et bouton
## contextuel ancrés au coin bas-droit, légende au milieu du bord haut (sous le titre),
## toast en haut au centre (au-dessus de la légende).
## Réglages (Paramètres, T28) : [method set_left_handed] (joystick dans la moitié droite, courir
## et contextuel au coin bas-gauche, bouton Menu inchangé en haut à droite),
## [method set_joystick_style] (taille, opacité), [method set_button_scale] (courir et
## contextuel ; le bouton Menu garde sa taille). Tout reste dans SAFE_MARGIN.

## Le titre de zone vient de disparaître (fin de son maintien ou hide_zone_title()).
signal title_hidden
## La légende vient de disparaître (fin de sa tenue ou hide_caption()).
signal caption_hidden
## La carte du Champion vient de disparaître (fin de sa tenue ou toucher).
signal champion_card_hidden
## Le bouton Menu rond (coin haut-droit) est touché : on demande le Menu Dresseur.
signal menu_requested

@onready var _zone_title: ZoneTitle = %ZoneTitle
@onready var _caption: WorldCaption = %WorldCaption
@onready var _toast: Toast = %Toast
@onready var _champion_card: ChampionCard = %ChampionCard
@onready var _joystick: TouchJoystick = %VirtualJoystick
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

## Verbe demandé pour le bouton contextuel (&"" = aucun) ; affiché si les contrôles le sont.
var _interact_verb: StringName = &""
var _controls_visible: bool = true
var _left_handed: bool = false
var _button_scale: float = 1.0
var _run_tween: Tween

@onready var _run_button: TouchScreenButton = %RunButton
@onready var _interact_button: InteractButton = %InteractButton
@onready var _menu_button: TouchScreenButton = %MenuButton
@onready var _corner: Control = %CornerAnchor


func _ready() -> void:
	layer = UiTokens.LAYER_HUD
	_place_corner_buttons()
	_menu_button.position = Vector2(-UiTokens.MENU_BUTTON_CENTER_FROM_CORNER.x,
		UiTokens.MENU_BUTTON_CENTER_FROM_CORNER.y)
	(_menu_button.get_node(^"Visual") as Node2D).modulate.a = UiTokens.MENU_BUTTON_ALPHA
	_menu_button.pressed.connect(_on_menu_pressed)
	_zone_title.title_hidden.connect(title_hidden.emit)
	_caption.caption_hidden.connect(caption_hidden.emit)
	_champion_card.card_finished.connect(champion_card_hidden.emit)


## Filet de sécurité : sans ce relâchement, l'action run resterait pressée si l'application
## perd le focus pendant que le bouton courir est tenu (le joystick gère déjà ses move_*).
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			Input.action_release(&"run")
			Input.action_release(&"interact")


## Affiche « NOM / région » en haut à gauche (glissement, maintien, disparition).
func show_zone_title(zone_name: String, region: String) -> void:
	_zone_title.show_title(zone_name, region)


## Masque le titre de zone en ANIM_MICRO (début d'une transition) ; émet title_hidden.
func hide_zone_title() -> void:
	_zone_title.hide_now()


## Pose [param text] sur le monde, en haut au centre (MAJUSCULES, sans rectangle) : fondu,
## tenue CAPTION_HOLD (ou [param hold] s si elle est ≥ 0 : « BADGE ROCHE », BADGE_CAPTION_HOLD),
## fondu. Jamais permanente. Indépendante des contrôles.
## [param centered] : au centre vertical de l'écran (« BADGE ROCHE »), pour ne pas couvrir
## le Champion.
func show_caption(text: String, hold: float = -1.0, centered: bool = false) -> void:
	_caption.show_caption(text, hold, centered)


## Efface la légende en ANIM_MICRO (changement de carte…) ; émet caption_hidden.
func hide_caption() -> void:
	_caption.hide_now()


## Carte de présentation d'un Champion (« PIERRE » / « Champion d'Arène d'Argenta ») : glisse
## depuis la gauche, reste CHAMPION_CARD_HOLD (un toucher l'abrège), ressort ; émet
## champion_card_hidden. Indépendante des contrôles.
func show_champion_card(champion_name: String, title: String) -> void:
	_champion_card.show_card(champion_name, title)


func get_champion_card() -> ChampionCard:
	return _champion_card


## Toast « [param title] — [param detail] » (« Poké Balls ×5 » / « Ajoutées au Sac ») en haut
## au centre, ~2 s, vibration « tic » ; il n'interrompt rien et n'intercepte aucun toucher.
## Indépendant des contrôles : il s'affiche aussi pendant une scène (contrôles cachés).
## [param icon] : icône du toast (Poké Ball si null).
func show_toast(title: String, detail: String, icon: Texture2D = null) -> void:
	_toast.show_toast(title, detail, icon)


## Fait apparaître le bouton contextuel avec [param verb] (&"talk" → PARLER, &"examine" →
## EXAMINER, &"observe" → OBSERVER, &"take" → PRENDRE, &"meet" → RENCONTRER). Pendant un
## dialogue (contrôles cachés), le verbe est retenu et le bouton n'apparaîtra qu'au retour
## des contrôles.
func show_interact(verb: StringName) -> void:
	_interact_verb = verb
	if _controls_visible:
		_interact_button.show_verb(verb)


## Fait disparaître le bouton contextuel (fondu ANIM_MICRO) : plus rien devant le joueur.
func hide_interact() -> void:
	_interact_verb = &""
	_interact_button.hide_verb()


## Cache (false) ou rétablit (true) joystick, bouton courir et bouton contextuel, par exemple
## pendant un dialogue. En les cachant, relâche move_*, run et interact : un doigt resté
## posé ne fait plus rien. Le titre de zone n'est pas concerné.
func set_controls_visible(shown: bool) -> void:
	if shown == _controls_visible:
		return
	_controls_visible = shown
	_joystick.visible = shown
	_menu_button.visible = shown
	if _run_tween != null:
		_run_tween.kill()
	if shown:
		_run_button.visible = true
		_run_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_run_tween.tween_property(_run_button, ^"modulate:a", 1.0, UiTokens.ANIM_MICRO)
		if not _interact_verb.is_empty():
			_interact_button.show_verb(_interact_verb)
		return
	_joystick.release()
	_run_button.visible = false
	_run_button.modulate.a = 0.0
	_interact_button.hide_now()
	for action: StringName in MOVE_ACTIONS:
		Input.action_release(action)
	Input.action_release(&"run")
	Input.action_release(&"interact")


func are_controls_visible() -> bool:
	return _controls_visible


func get_zone_title() -> ZoneTitle:
	return _zone_title


func get_caption() -> WorldCaption:
	return _caption


func get_toast() -> Toast:
	return _toast


func get_joystick() -> TouchJoystick:
	return _joystick


func get_run_button() -> TouchScreenButton:
	return _run_button


func get_interact_button() -> InteractButton:
	return _interact_button


func get_menu_button() -> TouchScreenButton:
	return _menu_button


## Mode gaucher (Q-16, exploration seulement) : joystick dans la moitié droite, courir et
## contextuel en bas à gauche (positions miroir) ; le bouton Menu reste en haut à droite.
func set_left_handed(enabled: bool) -> void:
	if enabled == _left_handed:
		return
	_left_handed = enabled
	_joystick.release()
	_place_corner_buttons()


func is_left_handed() -> bool:
	return _left_handed


## Taille ([param size_scale] : 0,8 / 1,0 / 1,2) et opacité (0,3 à 1,0) du joystick.
func set_joystick_style(size_scale: float, opacity: float) -> void:
	_joystick.size_scale = size_scale
	_joystick.opacity = opacity


## Échelle des boutons courir et contextuel (1,0 / 1,2) ; le centre de chaque bouton ne bouge
## pas, le bouton Menu garde sa taille.
func set_button_scale(button_scale: float) -> void:
	_button_scale = clampf(button_scale, 0.5, 2.0)
	_run_button.scale = Vector2.ONE * _button_scale
	_interact_button.scale = Vector2.ONE * _button_scale


func get_button_scale() -> float:
	return _button_scale


## Rectangles (coordonnées de l'écran) des zones touchables fixes : courir, contextuel (même
## caché : son emplacement) et Menu. Pour vérifier la symétrie et les marges.
func get_button_rects() -> Dictionary[StringName, Rect2]:
	var rects: Dictionary[StringName, Rect2] = {}
	for entry: Array in [[&"run", _run_button], [&"interact", _interact_button],
			[&"menu", _menu_button]]:
		var button: TouchScreenButton = entry[1]
		var radius := UiTokens.ROUND_BUTTON * 0.5 * button.scale.x
		var center := button.get_global_transform_with_canvas().origin
		rects[entry[0]] = Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	return rects


## Courir et contextuel dans le coin bas-droit, ou bas-gauche en mode gaucher.
func _place_corner_buttons() -> void:
	_joystick.zone_on_right = _left_handed
	_interact_button.set_mirrored(_left_handed)
	if _left_handed:
		_corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		_run_button.position = Vector2(UiTokens.RUN_BUTTON_CENTER_FROM_CORNER.x,
			-UiTokens.RUN_BUTTON_CENTER_FROM_CORNER.y)
		_interact_button.position = Vector2(UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER.x,
			-UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER.y)
	else:
		_corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		_run_button.position = -UiTokens.RUN_BUTTON_CENTER_FROM_CORNER
		_interact_button.position = -UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER


func _on_menu_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	menu_requested.emit()
