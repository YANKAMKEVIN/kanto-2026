class_name WorldCaption
extends Label
## Légende posée sur le monde (bible UI/UX §5) : « CHOISIS TON PREMIER PARTENAIRE ».
##
## Texte seul, sans rectangle : FONT_TITLE, gras, MAJUSCULES, ombre portée TEXT_SHADOW (halo
## pour rester lisible sur un sol clair). En haut au centre, sous la bande du titre de zone
## (CAPTION_TOP) : les deux ne se chevauchent jamais. Fondu d'apparition (CAPTION_FADE),
## tenue CAPTION_HOLD, fondu de disparition : jamais permanente (bible §11). Purement
## visuelle : elle ignore souris et toucher.
## Placement (aspect expand, 1920 à 2340 de large) : ancrée au milieu du bord haut, elle
## grandit des deux côtés avec son texte.

## Fin du fondu d'apparition (la légende est pleinement visible).
signal caption_shown
## La légende vient de disparaître (fin de sa tenue ou hide_now).
signal caption_hidden

@export var fade_duration: float = UiTokens.CAPTION_FADE
@export var hold_duration: float = UiTokens.CAPTION_HOLD

var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_left = 0.0
	offset_right = 0.0
	offset_top = UiTokens.CAPTION_TOP
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modulate.a = 0.0
	visible = false


## Affiche [param caption] (mis en MAJUSCULES) : fondu, tenue, fondu. Déjà visible, le texte
## change et la tenue repart de zéro, sans nouveau fondu d'apparition sec. [param hold] : tenue
## de cet affichage (s) ; négative = [member hold_duration] (« BADGE ROCHE » : 2 s, jalon 10).
## [param centered] : posée au centre vertical de l'écran au lieu du haut (« BADGE ROCHE » :
## en Arène la caméra est fixe et le Champion se tient en haut de la salle).
func show_caption(caption: String, hold: float = -1.0, centered: bool = false) -> void:
	text = caption.to_upper()
	_place(centered)
	if _tween != null:
		_tween.kill()
	if not visible:
		modulate.a = 0.0
	visible = true
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"modulate:a", 1.0, fade_duration)
	_tween.tween_callback(caption_shown.emit)
	_tween.tween_interval(hold if hold >= 0.0 else hold_duration)
	_tween.tween_property(self, ^"modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_on_hidden)


func _place(centered: bool) -> void:
	var middle := UiTokens.CAPTION_CENTER_ANCHOR if centered else 0.0
	anchor_top = middle
	anchor_bottom = middle
	grow_vertical = Control.GROW_DIRECTION_BOTH if centered else Control.GROW_DIRECTION_END
	offset_top = 0.0 if centered else UiTokens.CAPTION_TOP
	offset_bottom = 0.0


## Efface la légende en fondu court (changement de carte…) ; émet caption_hidden à la fin.
## Sans effet si elle n'est pas affichée.
func hide_now(duration: float = UiTokens.ANIM_MICRO) -> void:
	if not visible:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"modulate:a", 0.0, duration)
	_tween.tween_callback(_on_hidden)


func is_showing() -> bool:
	return visible


func _on_hidden() -> void:
	visible = false
	caption_hidden.emit()
