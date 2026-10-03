class_name UseResultBar
extends PanelContainer
## Le résultat d'un usage dans le Sac (dossier 08 §3) : « +20 PV — Salamèche 33/51 », et
## UTILISER À NOUVEAU tant qu'il reste un exemplaire, pour recommencer sans refaire le parcours.
## Pas de confirmation, pas de bouton Fermer : la barre reste jusqu'au prochain geste de
## l'écran ([method clear]).
##
## Deux aspects, jamais la couleur seule (le texte dit tout) : l'objet a servi (le texte du
## modèle de [BagQuery] commence par « + » : fond de succès) ou il a été refusé (la raison,
## fond d'accent : rien n'a été consommé).

## UTILISER À NOUVEAU touché : un seul signal par toucher.
signal repeat_requested

const REPEAT_TEXT := "UTILISER À NOUVEAU"
const SUCCESS_PREFIX := "+"

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _label: Label
var _repeat: Button
var _tween: Tween


func _init() -> void:
	theme_type_variation = &"ResultBar"
	custom_minimum_size.y = UiTokens.RESULT_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(row)
	_label = Label.new()
	_label.theme_type_variation = &"ResultText"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_label)
	_repeat = Button.new()
	_repeat.theme_type_variation = &"AccentButton"
	_repeat.text = REPEAT_TEXT
	_repeat.focus_mode = Control.FOCUS_NONE
	_repeat.custom_minimum_size = Vector2(UiTokens.RESULT_REPEAT_WIDTH, UiTokens.TOUCH_MIN)
	_repeat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_repeat.pressed.connect(_on_repeat)
	row.add_child(_repeat)
	visible = false


## Affiche [param text] ; UTILISER À NOUVEAU seulement si [param can_repeat]. Rappelée avec un
## nouveau texte, elle remplace l'ancien sans rejouer l'entrée.
func show_result(text: String, can_repeat: bool) -> void:
	_label.text = text
	_repeat.visible = can_repeat
	theme_type_variation = &"ResultBar" if text.begins_with(SUCCESS_PREFIX) \
		else &"ResultBarRefused"
	var fresh := not visible
	visible = true
	_kill_tween()
	var time := UiTokens.ANIM_PANEL * speed_scale
	if fresh and time > 0.0 and is_inside_tree():
		modulate.a = 0.0
		_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, ^"modulate:a", 1.0, time)
	else:
		modulate.a = 1.0


## Retire la barre (prochain geste de l'écran).
func clear() -> void:
	_kill_tween()
	modulate.a = 1.0
	visible = false


func get_text() -> String:
	return _label.text


func get_repeat_button() -> Button:
	return _repeat


## UTILISER À NOUVEAU est proposé.
func is_repeat_shown() -> bool:
	return visible and _repeat.visible


func _on_repeat() -> void:
	if not visible:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	repeat_requested.emit()


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
