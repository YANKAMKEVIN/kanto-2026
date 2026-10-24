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
## Jalon 14 : éclairs plein écran ([method flash], [ScreenFlash], au-dessus du reste du HUD).
## Passe systèmes 2 (`systemes-2.md` §2.3) : bouton rond Vélo au-dessus du bouton courir
## ([method set_bike_button] : visible avec la Bicyclette, grisé là où il refuse ; le toucher
## émet [signal bike_requested], même grisé, pour dire le refus).
## Moteur commun (défaut D5 de la QA du J24) : [method set_player_screen_rect] (Boot, à chaque
## image) — le groupe de boutons du coin bas (courir, contextuel, Vélo) ou le bouton Menu que le
## joueur touche à l'écran passe à [constant UiTokens.BUTTONS_UNDER_PLAYER_ALPHA] : le joueur
## se voit à travers, les boutons restent actifs. [D] : plutôt que décaler la caméra (qui
## montrerait le vide au-delà de la carte) ou rétrécir les boutons.

## Le titre de zone vient de disparaître (fin de son maintien ou hide_zone_title()).
signal title_hidden
## La légende vient de disparaître (fin de sa tenue ou hide_caption()).
signal caption_hidden
## La carte du Champion vient de disparaître (fin de sa tenue ou toucher).
signal champion_card_hidden
## Le bouton Menu rond (coin haut-droit) est touché : on demande le Menu Dresseur.
signal menu_requested
## Le bouton Vélo est touché (passe systèmes 2) : monter ou descendre, ou dire le refus.
signal bike_requested
## Appui long sur le bouton contextuel en mode choix (PÊCHER / SURFER, S2C option A).
signal interact_long_pressed

@onready var _zone_title: ZoneTitle = %ZoneTitle
@onready var _caption: WorldCaption = %WorldCaption
@onready var _toast: Toast = %Toast
@onready var _champion_card: ChampionCard = %ChampionCard
@onready var _joystick: TouchJoystick = %VirtualJoystick
@onready var _flash: ScreenFlash = %ScreenFlash
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

## Verbe demandé pour le bouton contextuel (&"" = aucun) ; affiché si les contrôles le sont.
var _interact_verb: StringName = &""
var _controls_visible: bool = true
var _left_handed: bool = false
var _button_scale: float = 1.0
var _run_tween: Tween
## Bouton Vélo demandé ([method set_bike_button]) ; affiché si les contrôles le sont.
var _bike_shown: bool = false
var _bike_dimmed: bool = false
## Rectangle du joueur à l'écran (vide = inconnu : boutons opaques).
var _player_rect: Rect2 = Rect2()

@onready var _run_button: TouchScreenButton = %RunButton
@onready var _interact_button: InteractButton = %InteractButton
@onready var _menu_button: TouchScreenButton = %MenuButton
@onready var _bike_button: TouchScreenButton = %BikeButton
@onready var _corner: Control = %CornerAnchor


func _ready() -> void:
	layer = UiTokens.LAYER_HUD
	set_process(false)
	_place_corner_buttons()
	_menu_button.position = Vector2(-UiTokens.MENU_BUTTON_CENTER_FROM_CORNER.x,
		UiTokens.MENU_BUTTON_CENTER_FROM_CORNER.y)
	(_menu_button.get_node(^"Visual") as Node2D).modulate.a = UiTokens.MENU_BUTTON_ALPHA
	_menu_button.pressed.connect(_on_menu_pressed)
	_bike_button.pressed.connect(_on_bike_pressed)
	_interact_button.long_pressed.connect(interact_long_pressed.emit)
	_apply_bike_button()
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
## le Champion. [param uppercase] faux : texte tel quel (phrase, « Pikachu utilise Flash ! »).
func show_caption(text: String, hold: float = -1.0, centered: bool = false,
		uppercase: bool = true) -> void:
	_caption.show_caption(text, hold, centered, uppercase)


## Éclairs plein écran de l'étape de scène « flash » (jalon-14.md §2.7) ; coroutine :
## await hud.flash(2). Au-dessus de tout le HUD, sans bloquer le toucher.
func flash(count: int) -> void:
	await _flash.play(count)


## Éclairs adoucis (« Réduire les animations » ou « Réduire les flashs », posé par Boot).
func set_flash_reduced(enabled: bool) -> void:
	_flash.reduced = enabled


func get_screen_flash() -> ScreenFlash:
	return _flash


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
## [param hold_choice] : un appui long émet [signal interact_long_pressed] (point doré [D]).
func show_interact(verb: StringName, hold_choice: bool = false) -> void:
	_interact_verb = verb
	_interact_button.set_hold_choice(hold_choice)
	if _controls_visible:
		_interact_button.show_verb(verb)


## Fait disparaître le bouton contextuel (fondu ANIM_MICRO) : plus rien devant le joueur.
func hide_interact() -> void:
	_interact_verb = &""
	_interact_button.set_hold_choice(false)
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
	_apply_bike_button()
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


## Bouton Vélo (passe systèmes 2) : [param shown] = la Bicyclette est dans le Sac ;
## [param dimmed] = grisé (intérieur, descente sur la Piste). Affiché seulement avec les
## contrôles.
func set_bike_button(shown: bool, dimmed: bool) -> void:
	_bike_shown = shown
	_bike_dimmed = dimmed
	if is_node_ready():
		_apply_bike_button()


func get_bike_button() -> TouchScreenButton:
	return _bike_button


## Vrai si le bouton Vélo est grisé.
func is_bike_button_dimmed() -> bool:
	return _bike_dimmed


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
	_bike_button.scale = Vector2.ONE * _button_scale


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


## Rectangle du joueur à l'écran (coordonnées de la vue, comme [method get_button_rects]) ;
## vide = aucun joueur. Les boutons qu'il touche deviennent transparents (fondu court).
func set_player_screen_rect(rect: Rect2) -> void:
	_player_rect = rect
	set_process(true)


## Vrai si le groupe de boutons [param group] (&"corner" ou &"menu") est rendu transparent parce
## que le joueur est dessous.
func is_group_under_player(group: StringName) -> bool:
	return _under_player(group)


## Opacité courante du groupe [param group] (&"corner" ou &"menu").
func get_group_alpha(group: StringName) -> float:
	return _group_node(group).modulate.a


func _process(delta: float) -> void:
	var step := delta * (1.0 - UiTokens.BUTTONS_UNDER_PLAYER_ALPHA) / UiTokens.ANIM_MICRO
	var settled := true
	for group: StringName in [&"corner", &"menu"]:
		var node := _group_node(group)
		var target := UiTokens.BUTTONS_UNDER_PLAYER_ALPHA if _under_player(group) else 1.0
		node.modulate.a = move_toward(node.modulate.a, target, step)
		settled = settled and is_equal_approx(node.modulate.a, target)
	if settled and not _player_rect.has_area():
		set_process(false)


func _group_node(group: StringName) -> CanvasItem:
	return _corner if group == &"corner" else _menu_button.get_parent() as CanvasItem


func _under_player(group: StringName) -> bool:
	if not _player_rect.has_area() or not _controls_visible:
		return false
	var rects := get_button_rects()
	var names: Array[StringName] = [&"menu"]
	if group == &"corner":
		names = [&"run", &"interact"]
	if group == &"corner" and _bike_button.visible:
		var radius := UiTokens.ROUND_BUTTON * 0.5 * _bike_button.scale.x
		var center := _bike_button.get_global_transform_with_canvas().origin
		rects[&"bike"] = Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		names.append(&"bike")
	for button: StringName in names:
		if rects[button].grow(UiTokens.BUTTONS_UNDER_PLAYER_MARGIN).intersects(_player_rect):
			return true
	return false


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
		_bike_button.position = Vector2(UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER.x,
			-UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER.y)
	else:
		_corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		_run_button.position = -UiTokens.RUN_BUTTON_CENTER_FROM_CORNER
		_interact_button.position = -UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER
		_bike_button.position = -UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER


func _apply_bike_button() -> void:
	_bike_button.visible = _bike_shown and _controls_visible
	_bike_button.modulate.a = UiTokens.BIKE_BUTTON_DIMMED_ALPHA if _bike_dimmed else 1.0


func _on_bike_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	bike_requested.emit()


func _on_menu_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	menu_requested.emit()
