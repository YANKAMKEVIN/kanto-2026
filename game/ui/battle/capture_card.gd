class_name CaptureCard
extends BattleWidget
## Carte de capture (case 9 de combat-capture-v1, dossier 05 §17) : « ROUCOOL CAPTURÉ ! » en
## capitales, vignette du Pokémon, puis discrètement « Nouvelle entrée Pokédex » (seulement si
## elle est demandée), la ligne d'équipe (« Roucool rejoint ton équipe. » ou « … a été confié
## au système de recherche de Chen. ») et l'indicateur ▼. Pas huit fenêtres : une carte, un
## toucher.
##
## show_capture est une coroutine : elle se termine au premier toucher sur l'écran (appui d'un
## InputEventScreenTouch, comme le bandeau des messages), la carte ressort alors. Un toucher
## n'est pris qu'après CAPTURE_TOUCH_LOCK : celui qui vient de lancer la Ball ne ferme pas la
## carte. Les lignes se révèlent l'une après l'autre (CAPTURE_LINE_DELAY, CAPTURE_LINE_FADE).
## Placement : BattleHudLayout.Slot.CAPTURE (centrée).

## Durée d'attente qui ne se termine jamais d'elle-même (secondes ; plus courte que
## COMPLETE_STEP, qui l'achève).
const WAIT_LIMIT := 3000.0

var _wait: Tween
var _reveal: Tween
var _blink: Tween
var _unlock_at_ms: int = 0

@onready var _frame: PanelContainer = %Frame
@onready var _column: VBoxContainer = %Column
@onready var _title: Label = %Title
@onready var _thumb: PanelContainer = %Thumb
@onready var _portrait: TextureRect = %Portrait
@onready var _pokedex_row: HBoxContainer = %PokedexRow
@onready var _pokedex_icon: TextureRect = %PokedexIcon
@onready var _pokedex_label: Label = %PokedexLabel
@onready var _result: Label = %Result
@onready var _continue: TextureRect = %Continue


func _ready() -> void:
	super._ready()
	_frame.anchor_left = 0.5
	_frame.anchor_right = 0.5
	_frame.anchor_top = 0.5
	_frame.anchor_bottom = 0.5
	_frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	_frame.offset_left = 0.0
	_frame.offset_right = 0.0
	_frame.offset_top = 0.0
	_frame.offset_bottom = 0.0
	_frame.custom_minimum_size.x = UiTokens.CAPTURE_CARD_WIDTH
	var inner := float(UiTokens.CAPTURE_CARD_WIDTH - 2 * UiTokens.CAPTURE_CARD_PAD_H)
	_column.add_theme_constant_override(&"separation", UiTokens.CAPTURE_ROW_GAP)
	_title.custom_minimum_size.x = inner
	_result.custom_minimum_size.x = inner
	_thumb.custom_minimum_size = Vector2.ONE * (UiTokens.CAPTURE_THUMB
		+ 2 * UiTokens.CAPTURE_THUMB_PAD)
	_portrait.custom_minimum_size = Vector2.ONE * UiTokens.CAPTURE_THUMB
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_pokedex_row.add_theme_constant_override(&"separation", UiTokens.CAPTURE_LINE_GAP)
	_pokedex_icon.custom_minimum_size = Vector2.ONE * UiTokens.CAPTURE_LINE_ICON
	_pokedex_icon.self_modulate = UiTokens.TEXT_MUTED
	_continue.custom_minimum_size = UiTokens.CAPTURE_CONTINUE_SIZE
	_continue.self_modulate = UiTokens.ACCENT


func _input(event: InputEvent) -> void:
	if not is_waiting():
		return
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() >= _unlock_at_ms:
		skip()


## Coroutine : montre la carte de [param view] (glissement + fondu), puis attend un toucher ;
## la carte ressort alors et la coroutine se termine. Une vue invalide est refusée (erreur,
## rien ne change). Une carte encore en attente est terminée d'abord.
func show_capture(view: CaptureCardView) -> void:
	if view == null or not view.is_valid():
		push_error("CaptureCard : vue invalide")
		return
	skip()
	_apply(view)
	_unlock_at_ms = Time.get_ticks_msec() + int(
		UiTokens.CAPTURE_TOUCH_LOCK * speed_scale * 1000.0)
	var wait := create_tween()
	wait.tween_interval(WAIT_LIMIT)
	_wait = wait
	_start_reveal(view)
	slide_in()
	await wait.finished
	_stop_effects()
	_haptic(UiTokens.HAPTIC_TICK_MS)
	await slide_out()


## Termine tout de suite la carte en attente (comme un toucher, sans le délai de garde).
func skip() -> void:
	var wait := _wait
	_wait = null
	BattleWidget.complete_tween(wait)


## La carte est affichée et attend un toucher.
func is_waiting() -> bool:
	return _wait != null and _wait.is_valid() and _wait.is_running()


## Les lignes sont toutes révélées (la ▼ clignote).
func is_revealed() -> bool:
	return _continue.visible and _continue.modulate.a > 0.0 and \
		(_reveal == null or not _reveal.is_running())


func get_title_text() -> String:
	return _title.text


func get_pokedex_text() -> String:
	return _pokedex_label.text


## La ligne « Nouvelle entrée Pokédex » est affichée.
func is_pokedex_line_shown() -> bool:
	return _pokedex_row.visible


func get_result_text() -> String:
	return _result.text


func get_portrait() -> TextureRect:
	return _portrait


func get_frame() -> PanelContainer:
	return _frame


func get_continue() -> TextureRect:
	return _continue


func get_pokedex_row() -> HBoxContainer:
	return _pokedex_row


func get_result_label() -> Label:
	return _result


func _apply(view: CaptureCardView) -> void:
	_title.text = view.title.to_upper()
	_portrait.texture = view.portrait
	_thumb.visible = view.portrait != null
	_pokedex_row.visible = view.shows_pokedex_line()
	_pokedex_label.text = view.pokedex_line
	_result.text = view.result_line


## Titre et vignette sont là d'emblée ; la ligne Pokédex, la ligne d'équipe puis ▼ se
## révèlent à la suite.
func _start_reveal(view: CaptureCardView) -> void:
	_stop_effects()
	var later: Array[CanvasItem] = []
	if view.shows_pokedex_line():
		later.append(_pokedex_row)
	later.append(_result)
	later.append(_continue)
	for item: CanvasItem in later:
		item.modulate.a = 1.0
	var delay := UiTokens.CAPTURE_LINE_DELAY * speed_scale
	var fade := UiTokens.CAPTURE_LINE_FADE * speed_scale
	if delay > 0.0 and fade > 0.0 and is_inside_tree():
		for item: CanvasItem in later:
			item.modulate.a = 0.0
		_reveal = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		for item: CanvasItem in later:
			_reveal.tween_interval(delay)
			_reveal.tween_property(item, ^"modulate:a", 1.0, fade)
	_start_blink()


## ▼ clignote doucement (boucle à durée réelle, jamais nulle), comme l'indicateur du dialogue.
func _start_blink() -> void:
	if not is_inside_tree():
		return
	_blink = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blink.tween_property(_continue, ^"self_modulate:a", UiTokens.DIALOG_CONTINUE_DIM,
		UiTokens.DIALOG_CONTINUE_BLINK)
	_blink.tween_property(_continue, ^"self_modulate:a", 1.0, UiTokens.DIALOG_CONTINUE_BLINK)


func _stop_effects() -> void:
	if _reveal != null:
		_reveal.kill()
		_reveal = null
	if _blink != null:
		_blink.kill()
		_blink = null
	_continue.self_modulate = UiTokens.ACCENT
