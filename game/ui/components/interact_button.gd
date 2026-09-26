class_name InteractButton
extends TouchScreenButton
## Bouton contextuel unique (bible UI/UX §1) : rond, icône du verbe, et le verbe en toutes
## lettres dans une pastille à sa gauche (PARLER, EXAMINER, OBSERVER, PRENDRE).
##
## Invisible tant qu'on ne lui demande rien : show_verb le fait apparaître en fondu
## (ANIM_MICRO), hide_verb le fait disparaître de même. Invisible, il ne reçoit pas le
## toucher. Il presse l'action « interact » (comme E ou Espace au clavier) : il ne sait pas
## à quoi elle sert. Vibration courte à l'appui.

## Verbe → libellé (texte d'interface) et icône. « take » (Prendre) est prévu pour les
## objets ramassables, sans usage au jalon 3A.
const VERBS: Dictionary[StringName, Dictionary] = {
	&"talk": {"label": "PARLER", "icon": preload("res://assets/ui/icons/talk.svg")},
	&"examine": {"label": "EXAMINER", "icon": preload("res://assets/ui/icons/examine.svg")},
	&"observe": {"label": "OBSERVER", "icon": preload("res://assets/ui/icons/observe.svg")},
	&"take": {"label": "PRENDRE", "icon": preload("res://assets/ui/icons/take.svg")},
}

var _verb: StringName = &""
var _tween: Tween

@onready var _visual: RoundButtonVisual = %Visual
@onready var _tag: PanelContainer = %Tag
@onready var _tag_label: Label = %TagLabel


func _ready() -> void:
	action = "interact"
	visibility_mode = VISIBILITY_ALWAYS
	passby_press = false
	pressed.connect(_on_pressed)
	visible = false
	modulate.a = 0.0


## Affiche le bouton avec le verbe [param verb] (&"talk", &"examine", &"observe", &"take").
## Un verbe inconnu cache le bouton (avertissement).
func show_verb(verb: StringName) -> void:
	if not VERBS.has(verb):
		push_warning("InteractButton : verbe inconnu « %s »" % verb)
		hide_verb()
		return
	_verb = verb
	var entry: Dictionary = VERBS[verb]
	_visual.icon = entry["icon"]
	_visual.queue_redraw()
	_tag_label.text = entry["label"]
	_tag.reset_size()
	_tag.position = Vector2(
		-UiTokens.ROUND_BUTTON * 0.5 - UiTokens.GAP - _tag.size.x, -_tag.size.y * 0.5)
	visible = true
	_fade_to(1.0)


## Cache le bouton en fondu ANIM_MICRO (et relâche « interact » s'il était tenu).
func hide_verb() -> void:
	_verb = &""
	if not visible:
		return
	_fade_to(0.0)


## Cache le bouton tout de suite, sans fondu, et relâche « interact ».
func hide_now() -> void:
	_verb = &""
	if _tween != null:
		_tween.kill()
		_tween = null
	modulate.a = 0.0
	_hide()


## Verbe affiché ; &"" s'il est caché ou en train de disparaître.
func get_verb() -> StringName:
	return _verb


func get_label_text() -> String:
	return _tag_label.text


func get_icon() -> Texture2D:
	return _visual.icon


## Pastille du verbe (à gauche du bouton), pour les tests de placement.
func get_tag() -> PanelContainer:
	return _tag


func _fade_to(alpha: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"modulate:a", alpha, UiTokens.ANIM_MICRO)
	if alpha <= 0.0:
		_tween.tween_callback(_hide)


func _hide() -> void:
	visible = false
	Input.action_release(&"interact")


func _on_pressed() -> void:
	Input.vibrate_handheld(UiTokens.HAPTIC_TAP_MS)
