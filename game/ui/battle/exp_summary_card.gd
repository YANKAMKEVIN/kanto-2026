class_name ExpSummaryCard
extends BattleWidget
## Bilan de fin de combat (demande n° 1, décisions de Kevin du 2026-10-06 ; DA de
## bilan-xp-v1) : une carte sans titre, centrée, le décor du combat visible autour ; une ligne
## par Pokémon qui a gagné de l'XP ([ExpSummaryRow]), dans l'ordre de l'équipe. Les barres
## partent [b]ensemble[/b] ; celle d'un Pokémon qui monte de niveau enchaîne ses tranches et
## met brièvement sa ligne en valeur à chaque passage (vibration courte, coupée avec les
## vibrations). Une fois toutes les barres arrivées, la consigne discrète « Touchez l'écran
## pour continuer » apparaît sous la carte.
##
## Gestes : pendant le remplissage, un toucher accélère tout (×SUMMARY_FAST), un second le
## termine ; ensuite, un toucher ferme. Retour (Android, par Boot → [method handle_back] ;
## « ui_cancel » au clavier) ferme à tout moment (les barres sont d'abord menées au bout). Un
## toucher n'est pris qu'après SUMMARY_TOUCH_LOCK. Seul l'appui d'un InputEventScreenTouch
## compte (la souris est émulée en toucher sur Mac), comme le bandeau des messages.
##
## Deux coroutines : [method show_summary] (la carte arrive, les barres se remplissent ; rend la
## main quand tout est arrivé) puis [method wait_closed] (attend le toucher, la carte sort).
## speed_scale 0 (tests) : tout est immédiat et [method wait_closed] n'attend pas, comme le
## bandeau des messages. Placement : BattleHudLayout.Slot.SUMMARY (centrée).

## Attente qui ne se termine jamais d'elle-même (secondes ; plus courte que COMPLETE_STEP).
const WAIT_LIMIT := 3000.0

enum Phase { HIDDEN, FILLING, WAITING }

var _phase: Phase = Phase.HIDDEN
var _rows: Array[ExpSummaryRow] = []
var _accelerated: bool = false
var _close_requested: bool = false
var _unlock_at_ms: int = 0
var _wait: Tween
var _hint_tween: Tween

@onready var _layout: VBoxContainer = %Layout
@onready var _frame: PanelContainer = %Frame
@onready var _list: VBoxContainer = %Rows
@onready var _hint: PanelContainer = %Hint
@onready var _hint_text: Label = %HintText


func _ready() -> void:
	super._ready()
	_layout.anchor_left = 0.5
	_layout.anchor_right = 0.5
	_layout.anchor_top = 0.5
	_layout.anchor_bottom = 0.5
	_layout.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_layout.grow_vertical = Control.GROW_DIRECTION_BOTH
	_layout.offset_left = 0.0
	_layout.offset_right = 0.0
	_layout.offset_top = 0.0
	_layout.offset_bottom = 0.0
	_layout.add_theme_constant_override(&"separation", UiTokens.SUMMARY_HINT_GAP)
	_frame.custom_minimum_size.x = UiTokens.SUMMARY_CARD_WIDTH
	_list.add_theme_constant_override(&"separation", UiTokens.SUMMARY_ROW_GAP)
	_hint.modulate.a = 0.0


func _input(event: InputEvent) -> void:
	if _phase == Phase.HIDDEN:
		return
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() >= _unlock_at_ms:
		tap()


func _unhandled_input(event: InputEvent) -> void:
	if _phase == Phase.HIDDEN:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		handle_back()
	elif event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		tap()


## Coroutine : montre la carte avec [param rows] (dans l'ordre) et la consigne [param hint]
## (cachée jusqu'à la fin des barres), fait remplir les barres ensemble et rend la main quand
## toutes sont arrivées. Une liste vide ou une vue invalide est refusée (erreur, rien ne
## s'affiche).
func show_summary(rows: Array[ExpSummaryRowView], hint: String) -> void:
	if rows.is_empty() or rows.any(func(view: ExpSummaryRowView) -> bool:
			return view == null or not view.is_valid()):
		push_error("ExpSummaryCard : vues invalides")
		return
	_clear_rows()
	_accelerated = false
	_close_requested = false
	_hint_text.text = hint
	_hint.visible = not hint.is_empty()
	_hint.modulate.a = 0.0
	for view: ExpSummaryRowView in rows:
		var row := ExpSummaryRow.new()
		_list.add_child(row)
		row.set_view(view)
		row.haptic_requested.connect(_haptic)
		_rows.append(row)
	_phase = Phase.FILLING
	_unlock_at_ms = Time.get_ticks_msec() + int(UiTokens.SUMMARY_TOUCH_LOCK * speed_scale * 1000.0)
	await slide_in()
	for row: ExpSummaryRow in _rows:
		# Fermé (retour) pendant l'arrivée de la carte : tout est déjà au bout.
		row.play(0.0 if _close_requested else speed_scale)
		if _accelerated:
			row.accelerate()
	while not is_filled():
		await get_tree().process_frame
	_phase = Phase.WAITING
	_show_hint()


## Coroutine : attend le toucher qui ferme (immédiat si speed_scale vaut 0 ou si la fermeture a
## déjà été demandée), puis la carte sort.
func wait_closed() -> void:
	if _phase == Phase.HIDDEN:
		return
	if speed_scale > 0.0 and not _close_requested:
		_wait = create_tween()
		_wait.tween_interval(WAIT_LIMIT)
		await _wait.finished
	_wait = null
	_phase = Phase.HIDDEN
	_haptic(UiTokens.HAPTIC_TICK_MS)
	await slide_out()
	_clear_rows()


## Un toucher : accélère, puis termine le remplissage ; une fois tout arrivé, ferme.
func tap() -> void:
	match _phase:
		Phase.FILLING:
			if _accelerated:
				finish()
			else:
				accelerate()
		Phase.WAITING:
			close()


## Toutes les barres vont SUMMARY_FAST fois plus vite.
func accelerate() -> void:
	_accelerated = true
	for row: ExpSummaryRow in _rows:
		row.accelerate()


## Toutes les barres arrivent tout de suite à leur valeur finale.
func finish() -> void:
	for row: ExpSummaryRow in _rows:
		row.finish_now()


## Ferme la carte (les barres sont d'abord menées au bout).
func close() -> void:
	if _phase == Phase.HIDDEN:
		return
	finish()
	_close_requested = true
	BattleWidget.complete_tween(_wait)


## Retour (Android, Échap) : ferme le bilan s'il est affiché. Vrai si le geste a servi.
func handle_back() -> bool:
	if _phase == Phase.HIDDEN:
		return false
	close()
	return true


## Toutes les barres sont arrivées.
func is_filled() -> bool:
	return _rows.all(func(row: ExpSummaryRow) -> bool: return row.is_done())


## La carte attend le toucher qui ferme (barres arrivées).
func is_waiting() -> bool:
	return _phase == Phase.WAITING


## Le remplissage a été accéléré par un toucher.
func is_accelerated() -> bool:
	return _accelerated


func get_rows() -> Array[ExpSummaryRow]:
	return _rows.duplicate()


func get_frame() -> PanelContainer:
	return _frame


func get_hint() -> PanelContainer:
	return _hint


## La consigne est affichée (après le remplissage).
func is_hint_shown() -> bool:
	return _hint.visible and _hint.modulate.a > 0.0


func get_hint_text() -> String:
	return _hint_text.text


func _show_hint() -> void:
	if not _hint.visible:
		return
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	var time := UiTokens.SUMMARY_HINT_FADE * speed_scale
	if time <= 0.0 or not is_inside_tree():
		_hint.modulate.a = 1.0
		return
	_hint_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hint_tween.tween_property(_hint, ^"modulate:a", 1.0, time)


func _clear_rows() -> void:
	for row: ExpSummaryRow in _rows:
		if is_instance_valid(row):
			row.queue_free()
	_rows.clear()
