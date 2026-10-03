class_name DialogueBox
extends CanvasLayer
## Boîte de dialogue 2026 (bible UI/UX §3, calque LAYER_DIALOG) : panneau inférieur sombre et
## translucide, coins doux, sans portrait ; nom du locuteur dans le panneau, au-dessus du
## texte ; indicateur de suite « › » qui clignote en bas à droite.
##
## Elle ne fait qu'afficher : elle ne connaît ni le déroulé du dialogue, ni les données, ni
## le joueur. Celui qui la pilote appelle open, show_page, set_visible_characters (écriture
## du texte, ~45 caractères/s), set_continue_visible et close, et écoute advance_requested.
## - Ouverte, un toucher n'importe où sur l'écran émet advance_requested (un toucher = un
##   signal : seul l'appui d'un InputEventScreenTouch compte ; la souris émulée depuis le
##   toucher, ou le toucher émulé depuis la souris sur Mac, n'est donc pas compté deux fois).
## - Fermée, elle est invisible, ignore la souris et n'émet rien.
## - Taille du texte Grande et contraste renforcé ([UiPrefs]) lus à chaque ouverture et page.
## - Elle monte légèrement depuis le bas en fondu (DIALOG_OPEN), sans « pop ».
## Placement (aspect expand, 1920 à 2340 de large) : centrée en bas, largeur
## DIALOG_BOX_WIDTH, à DIALOG_BOTTOM_MARGIN du bas.

## Toucher sur l'écran pendant que la boîte est ouverte.
signal advance_requested
## Fin de l'animation de fermeture (la boîte est invisible).
signal closed
## Fin (ou interruption par open) de l'animation de fermeture : c'est ce qu'attend close.
signal _close_settled

var _open: bool = false
var _tween: Tween
var _blink: Tween

@onready var _root: Control = %Root
@onready var _panel: PanelContainer = %Panel
@onready var _speaker: Label = %Speaker
@onready var _text: Label = %Text
@onready var _continue: Label = %Continue
@onready var _continue_slot: Control = %ContinueSlot
@onready var _body: HBoxContainer = %Body
@onready var _lines: VBoxContainer = %Lines


func _ready() -> void:
	layer = UiTokens.LAYER_DIALOG
	_panel.custom_minimum_size = Vector2(UiTokens.DIALOG_BOX_WIDTH, UiTokens.DIALOG_BOX_MIN_HEIGHT)
	_panel.offset_left = -UiTokens.DIALOG_BOX_WIDTH * 0.5
	_panel.offset_right = UiTokens.DIALOG_BOX_WIDTH * 0.5
	_panel.offset_bottom = -UiTokens.DIALOG_BOTTOM_MARGIN
	_panel.offset_top = -UiTokens.DIALOG_BOTTOM_MARGIN - UiTokens.DIALOG_BOX_MIN_HEIGHT
	_lines.add_theme_constant_override(&"separation", UiTokens.DIALOG_SPEAKER_GAP)
	_body.add_theme_constant_override(&"separation", UiTokens.GAP)
	_continue_slot.custom_minimum_size.x = UiTokens.DIALOG_CONTINUE_WIDTH
	# Coupure des lignes calculée sur le texte entier : un mot ne saute pas à la ligne
	# suivante pendant qu'il s'écrit.
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.max_lines_visible = UiTokens.DIALOG_MAX_LINES
	_set_closed_state()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	advance_requested.emit()


## Ouvre la boîte (vide) : elle monte de DIALOG_SLIDE depuis le bas en fondu (DIALOG_OPEN).
## Sans effet si elle est déjà ouverte.
func open() -> void:
	if _open:
		return
	_open = true
	_kill_tween()
	_speaker.text = ""
	_speaker.visible = false
	_text.text = ""
	set_continue_visible(false)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	UiPrefsApplier.apply(_panel)
	# Rouverte pendant sa fermeture : elle remonte depuis sa position courante.
	if not visible:
		offset = Vector2(0.0, UiTokens.DIALOG_SLIDE)
	visible = true
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"offset", Vector2.ZERO, UiTokens.DIALOG_OPEN)
	_tween.parallel().tween_property(_root, ^"modulate:a", 1.0, UiTokens.DIALOG_OPEN)


## Affiche une page : [param speaker] au-dessus du texte (caché s'il est vide), [param text]
## sans aucun caractère visible (set_visible_characters l'écrit), [param narration] en
## italique (Examiner, Observer). Cache « › ».
func show_page(speaker: String, text: String, narration: bool) -> void:
	_speaker.text = speaker
	_speaker.visible = not speaker.is_empty()
	_text.theme_type_variation = &"DialogNarration" if narration else &"DialogText"
	_text.text = text
	_text.visible_characters = 0
	# Taille du texte et contraste (UiPrefs) : le thème du texte change selon la page.
	UiPrefsApplier.apply(_panel)
	set_continue_visible(false)


## Nombre de caractères visibles de la page ; -1 = tout le texte.
func set_visible_characters(count: int) -> void:
	_text.visible_characters = count


## Montre (clignotant) ou cache l'indicateur de suite « › ».
func set_continue_visible(shown: bool) -> void:
	if shown == _continue.visible:
		return
	_continue.visible = shown
	if _blink != null:
		_blink.kill()
		_blink = null
	_continue.modulate.a = 1.0
	if shown:
		_blink = create_tween().set_loops().set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)
		_blink.tween_property(_continue, ^"modulate:a", UiTokens.DIALOG_CONTINUE_DIM,
			UiTokens.DIALOG_CONTINUE_BLINK)
		_blink.tween_property(_continue, ^"modulate:a", 1.0, UiTokens.DIALOG_CONTINUE_BLINK)


## Ferme la boîte (redescente et fondu, DIALOG_CLOSE) ; coroutine : await box.close().
## Émet closed à la fin. Sans effet (et sans signal) si elle est déjà fermée.
func close() -> void:
	if not _open:
		return
	_open = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_continue_visible(false)
	_kill_tween()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"offset", Vector2(0.0, UiTokens.DIALOG_SLIDE),
		UiTokens.DIALOG_CLOSE)
	_tween.parallel().tween_property(_root, ^"modulate:a", 0.0, UiTokens.DIALOG_CLOSE)
	_tween.finished.connect(_close_settled.emit)
	await _close_settled
	if _open:
		return # rouverte pendant la fermeture : pas de closed
	_set_closed_state()
	closed.emit()
	# On rend la main depuis l'image suivante, hors de l'émission d'un signal de la boîte :
	# l'appelant peut alors la libérer sans erreur (objet verrouillé pendant une émission).
	if is_inside_tree():
		await get_tree().process_frame


## Vrai de open() jusqu'au début de close().
func is_open() -> bool:
	return _open


func is_continue_visible() -> bool:
	return _continue.visible


func get_speaker_text() -> String:
	return _speaker.text if _speaker.visible else ""


func get_text() -> String:
	return _text.text


func is_narration() -> bool:
	return _text.theme_type_variation == &"DialogNarration"


func get_panel() -> PanelContainer:
	return _panel


func _set_closed_state() -> void:
	visible = false
	offset = Vector2(0.0, UiTokens.DIALOG_SLIDE)
	_root.modulate.a = 0.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Arrête l'animation en cours ; une fermeture interrompue rend la main à son appelant.
func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	_close_settled.emit()
