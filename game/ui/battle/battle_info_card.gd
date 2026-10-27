class_name BattleInfoCard
extends BattleWidget
## Carte d'information de combat (combat-v1) : NOM en MAJUSCULES, ♂/♀ coloré, « Nv. 5 » à
## droite, barre de PV, et « 19 / 19 » sous la barre, à droite, côté joueur seulement.
##
## Carte sombre translucide comme la boîte de dialogue (jalon 4 Q17), largeur
## BATTLE_CARD_WIDTH, hauteur BATTLE_CARD_HEIGHT (sans chiffres) ou BATTLE_CARD_HEIGHT_NUMBERS.
## Sous HP_LOW_THRESHOLD, elle pulse légèrement (dossier 05 §12) ; au-dessus, elle s'arrête.
## Elle ne connaît que sa BattleCardView ; play_hit vibre (coup reçu, plus fort si critique).
##
## XP (jalon 5C T10, côté joueur) : animate_exp fait glisser une fine barre d'XP, posée au bas de
## la carte, d'une fraction à l'autre en EXP_TWEEN, et fait monter « +21 XP » en l'effaçant
## (EXP_GAIN_HOLD) au-dessus de la carte. La barre disparaît ensuite (EXP_BAR_LINGER puis
## EXP_BAR_FADE), sauf si une autre tranche la reprend entre-temps : jamais permanente
## (bible §11). pulse_level met « Nv. » à jour et le fait pulser ; aucune fenêtre (Q25).
##
## Noms longs (QA 23E) : le nom n'est jamais rogné ; s'il ne tient pas dans la largeur de la
## carte, la pastille de statut perd son icône (le statut reste un texte, dossier 08 §2), puis
## le nom rétrécit jusqu'à BATTLE_CARD_NAME_FONT_MIN.

## Libellé du niveau (texte d'interface) et format des PV chiffrés.
const LEVEL_TAG := "Nv."
const HP_FORMAT := "%d / %d"
const EXP_GAIN_FORMAT := "+%d XP"
const GENDER_ICONS: Dictionary[BattleCardView.Gender, Texture2D] = {
	BattleCardView.Gender.MALE: preload("res://assets/ui/icons/battle/male.svg"),
	BattleCardView.Gender.FEMALE: preload("res://assets/ui/icons/battle/female.svg"),
}
const GENDER_COLORS: Dictionary[BattleCardView.Gender, Color] = {
	BattleCardView.Gender.MALE: UiTokens.GENDER_MALE,
	BattleCardView.Gender.FEMALE: UiTokens.GENDER_FEMALE,
}

var _gender: BattleCardView.Gender = BattleCardView.Gender.NONE
var _level: int = 1
var _status: StringName = StatusRules.NONE
var _show_numbers: bool = false
var _pulse: Tween
var _pulsing: bool = false
var _exp_hide: Tween
var _exp_gain: Tween
var _exp_rise: Tween
## Change à chaque animate_exp : une tranche dépassée par une plus récente ne cache pas la barre.
var _exp_serial: int = 0
var _level_pulse: Tween

@onready var _rows: VBoxContainer = %Rows
@onready var _header: HBoxContainer = %Header
@onready var _name_label: Label = %NameLabel
@onready var _gender_icon: TextureRect = %Gender
@onready var _status_badge: TypeBadge = %StatusBadge
@onready var _level_tag: Label = %LevelTag
@onready var _level_value: Label = %LevelValue
@onready var _bar: HpBar = %HpBar
@onready var _numbers: Label = %HpNumbers
@onready var _overlay: Control = %Overlay
@onready var _exp_bar: ExpBar = %ExpBar
@onready var _exp_gain_label: Label = %ExpGain


func _ready() -> void:
	super._ready()
	_rows.add_theme_constant_override(&"separation", UiTokens.BATTLE_CARD_ROW_GAP)
	_header.add_theme_constant_override(&"separation", UiTokens.BATTLE_CARD_NAME_GAP)
	_gender_icon.custom_minimum_size = Vector2.ONE * UiTokens.GENDER_ICON
	_level_tag.text = LEVEL_TAG
	_bar.display_changed.connect(_on_hp_shown)
	_level_value.pivot_offset_ratio = Vector2(0.5, 0.5)
	# La barre d'XP descend dans la marge basse de la carte : elle ne touche pas « 19 / 19 ».
	_exp_bar.offset_bottom = UiTokens.EXP_BAR_DROP
	_exp_bar.offset_top = UiTokens.EXP_BAR_DROP - UiTokens.EXP_BAR_HEIGHT
	_apply_numbers()


## Remplit la carte (nom, sexe, niveau, PV immédiats, chiffres ou non). Une vue invalide
## est refusée (erreur), la carte reste telle.
func set_view(view: BattleCardView) -> void:
	if view == null or not view.is_valid():
		push_error("BattleInfoCard : vue invalide")
		return
	_name_label.text = view.display_name.to_upper()
	_gender = view.gender
	_gender_icon.texture = GENDER_ICONS.get(_gender, null)
	_gender_icon.modulate = GENDER_COLORS.get(_gender, UiTokens.TEXT)
	_gender_icon.visible = _gender_icon.texture != null
	_level = view.level
	_level_value.text = GhostDisguise.HIDDEN_LEVEL_TEXT if view.level_hidden \
		else str(view.level)
	set_status(view.status)
	set_show_hp_numbers(view.show_hp_numbers)
	set_hp(view.hp, view.max_hp)
	_fit_name()


## Pose (ou retire, avec [constant StatusRules.NONE]) l'étiquette de statut « PSN » à droite du
## sexe : pastille de la couleur du type Poison, texte (dossier 08 §2). Aucune animation : elle
## accompagne la phrase du combat.
func set_status(status: StringName) -> void:
	var label := StatusView.text_of(status)
	_status = status if not label.is_empty() else StatusRules.NONE
	_status_badge.visible = not label.is_empty()
	if not label.is_empty():
		_status_badge.set_type(StatusView.badge_type(status), label)
	_fit_name()


## Montre ou cache « 19 / 19 » sous la barre (côté joueur seulement).
func set_show_hp_numbers(shown: bool) -> void:
	_show_numbers = shown
	_apply_numbers()


## PV immédiats (interrompt une animation).
func set_hp(hp: int, max_hp: int) -> void:
	_bar.speed_scale = speed_scale
	_bar.set_hp(hp, max_hp)


## Coroutine : descente (ou remontée) animée des PV, chiffres mis à jour en route ; plus
## rapide si [param big] (gros coup). Voir HpBar.animate_hp.
func animate_hp(hp: int, max_hp: int, big: bool = false) -> void:
	_bar.speed_scale = speed_scale
	await _bar.animate_hp(hp, max_hp, big)


## Retour haptique d'un coup reçu : HAPTIC_HIT_MS, ou HAPTIC_CRIT_MS si [param critical].
func play_hit(critical: bool = false) -> void:
	_haptic(UiTokens.HAPTIC_CRIT_MS if critical else UiTokens.HAPTIC_HIT_MS)


## Retour haptique du dégât de poison : HAPTIC_STATUS_MS, plus doux qu'un coup.
func play_poison() -> void:
	_haptic(UiTokens.HAPTIC_STATUS_MS)


## Coroutine : fait glisser la barre d'XP de [param from] à [param to] (fractions 0..1 d'une
## tranche de niveau) en EXP_TWEEN, et si [param gained] > 0 fait monter « +N XP » en
## l'effaçant (EXP_GAIN_HOLD). Se termine quand la barre a atteint [param to] et que « +N XP »
## est effacé ; la barre disparaît ensuite d'elle-même, sauf si une autre tranche suit.
func animate_exp(from: float, to: float, gained: int = 0) -> void:
	_kill_exp_hide()
	_exp_serial += 1
	var serial := _exp_serial
	_exp_bar.speed_scale = speed_scale
	_exp_bar.modulate.a = 1.0
	_exp_bar.visible = true
	var gain := _start_exp_gain(gained)
	await _exp_bar.animate_fraction(from, to)
	if gain != null and gain.is_valid() and gain.is_running():
		await gain.finished
	if serial == _exp_serial:
		_schedule_exp_hide()


## « Nv. » prend [param level] tout de suite, sans pulsation ni vibration.
func set_level(level: int) -> void:
	BattleWidget.complete_tween(_level_pulse)
	_level = level
	_level_value.text = str(level)
	_fit_name()


## Coroutine : « Nv. » prend [param level] et pulse un instant (grossit en ACCENT, puis revient,
## LEVEL_PULSE_UP + LEVEL_PULSE_DOWN) ; vibration courte HAPTIC_LEVEL_UP_MS.
func pulse_level(level: int) -> void:
	_level = level
	_level_value.text = str(level)
	_fit_name()
	_haptic(UiTokens.HAPTIC_LEVEL_UP_MS)
	BattleWidget.complete_tween(_level_pulse)
	_level_value.scale = Vector2.ONE
	_level_value.modulate = UiTokens.MODULATE_FULL
	var up := UiTokens.LEVEL_PULSE_UP * speed_scale
	if up <= 0.0:
		return
	var peak := Vector2.ONE * UiTokens.LEVEL_PULSE_SCALE
	_level_pulse = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_level_pulse.tween_property(_level_value, ^"scale", peak, up)
	_level_pulse.parallel().tween_property(_level_value, ^"modulate", UiTokens.ACCENT, up)
	var down := UiTokens.LEVEL_PULSE_DOWN * speed_scale
	_level_pulse.tween_property(_level_value, ^"scale", Vector2.ONE, down)
	_level_pulse.parallel().tween_property(_level_value, ^"modulate", UiTokens.MODULATE_FULL, down)
	await _level_pulse.finished


func get_name_text() -> String:
	return _name_label.text


## Taille de police du nom (BATTLE_CARD_NAME_FONT, moins pour un nom long).
func get_name_font_size() -> int:
	return _name_label.get_theme_font_size(&"font_size")


## Statut posé sur la carte (&"" = aucune étiquette).
func get_status() -> StringName:
	return _status


## « PSN » (vide sans étiquette).
func get_status_text() -> String:
	return _status_badge.get_type_text() if _status_badge.visible else ""


func get_status_badge() -> TypeBadge:
	return _status_badge


func get_gender() -> BattleCardView.Gender:
	return _gender


func get_gender_icon() -> TextureRect:
	return _gender_icon


## « Nv. 5 » (« Nv. ?? » pour un niveau masqué, jalon 19).
func get_level_text() -> String:
	return "%s %s" % [LEVEL_TAG, _level_value.text]


## « 19 / 19 » (même caché).
func get_hp_text() -> String:
	return _numbers.text


func is_hp_numbers_visible() -> bool:
	return _numbers.visible


func get_hp_bar() -> HpBar:
	return _bar


## La carte pulse (PV sous HP_LOW_THRESHOLD, Pokémon pas K.O.).
func is_pulsing() -> bool:
	return _pulsing


func get_exp_bar() -> ExpBar:
	return _exp_bar


## La barre d'XP est affichée (elle disparaît d'elle-même après une tranche).
func is_exp_bar_visible() -> bool:
	return _exp_bar.visible


## « +21 XP » (même effacé, dernier texte posé).
func get_exp_gain_text() -> String:
	return _exp_gain_label.text


## « +N XP » est affiché (entre son apparition et sa disparition).
func is_exp_gain_visible() -> bool:
	return _exp_gain_label.visible


func get_level_label() -> Label:
	return _level_value


func get_exp_gain_label() -> Label:
	return _exp_gain_label


## Les deux tweens de « +N XP » (fondus, montée), null hors animation. Les tests les mettent
## en pause et les font avancer à la main ([method Tween.custom_step]) : aucune durée réelle.
func get_exp_gain_tweens() -> Array[Tween]:
	var tweens: Array[Tween] = []
	for tween: Tween in [_exp_gain, _exp_rise]:
		if tween != null and tween.is_valid():
			tweens.append(tween)
	return tweens


func get_hp_numbers_label() -> Label:
	return _numbers


func _apply_numbers() -> void:
	_numbers.visible = _show_numbers
	var height := UiTokens.BATTLE_CARD_HEIGHT_NUMBERS if _show_numbers \
		else UiTokens.BATTLE_CARD_HEIGHT
	_body.custom_minimum_size = Vector2(UiTokens.BATTLE_CARD_WIDTH, height)


## Nom entier dans la largeur de la carte : taille du thème si tout tient ; sinon la pastille de
## statut perd d'abord son icône (le nom garde ainsi une taille proche de celle du niveau), puis
## le nom rétrécit (plancher BATTLE_CARD_NAME_FONT_MIN).
func _fit_name() -> void:
	_name_label.remove_theme_font_size_override(&"font_size")
	_status_badge.set_show_icon(true)
	if _name_label.get_combined_minimum_size().x <= _name_room():
		return
	if _status_badge.visible:
		_status_badge.set_show_icon(false)
	_shrink_name_to(_name_room())


## Réduit le nom jusqu'à ce qu'il tienne dans [param room] pixels ; faux s'il ne tient pas même
## au plancher (il reste alors au plancher).
func _shrink_name_to(room: float) -> bool:
	var size := UiTokens.BATTLE_CARD_NAME_FONT
	while true:
		if size == UiTokens.BATTLE_CARD_NAME_FONT:
			_name_label.remove_theme_font_size_override(&"font_size")
		else:
			_name_label.add_theme_font_size_override(&"font_size", size)
		if _name_label.get_combined_minimum_size().x <= room:
			return true
		if size <= UiTokens.BATTLE_CARD_NAME_FONT_MIN:
			return false
		size -= 1
	return false


## Largeur laissée au nom dans l'en-tête : carte moins ses marges, les autres éléments visibles
## de l'en-tête et leurs écarts.
func _name_room() -> float:
	var room := float(UiTokens.BATTLE_CARD_WIDTH) \
		- _body.get_theme_stylebox(&"panel").get_minimum_size().x
	var shown := 0
	for child: Node in _header.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		shown += 1
		if control != _name_label:
			room -= control.get_combined_minimum_size().x
	return room - float(maxi(shown - 1, 0) * UiTokens.BATTLE_CARD_NAME_GAP)


func _on_hp_shown(hp: int, max_hp: int) -> void:
	_numbers.text = HP_FORMAT % [hp, max_hp]
	var low := hp > 0 and float(hp) / float(max_hp) <= UiTokens.HP_LOW_THRESHOLD
	_set_pulsing(low)


func _set_pulsing(on: bool) -> void:
	if on == _pulsing:
		return
	_pulsing = on
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	_body.scale = Vector2.ONE
	if not on:
		return
	# Boucle à durée réelle (jamais nulle, même en test : une boucle de durée nulle bloque).
	var peak := Vector2.ONE * UiTokens.HP_LOW_PULSE_SCALE
	_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(_body, ^"scale", peak, UiTokens.HP_LOW_PULSE)
	_pulse.tween_property(_body, ^"scale", Vector2.ONE, UiTokens.HP_LOW_PULSE)


## Pose « +N XP » au bord haut de la carte, à droite, et le lance (apparition en fondu, montée
## de EXP_GAIN_RISE, disparition en fondu). Renvoie son Tween, null s'il n'y a rien à montrer
## ou si l'animation est instantanée (le texte est alors effacé tout de suite).
func _start_exp_gain(gained: int) -> Tween:
	BattleWidget.complete_tween(_exp_gain)
	BattleWidget.complete_tween(_exp_rise)
	_exp_gain = null
	_exp_rise = null
	_exp_gain_label.visible = false
	if gained <= 0:
		return null
	_exp_gain_label.text = EXP_GAIN_FORMAT % gained
	var hold := UiTokens.EXP_GAIN_HOLD * speed_scale
	if hold <= 0.0:
		return null
	var label_size := _exp_gain_label.get_combined_minimum_size()
	_exp_gain_label.size = label_size
	var start := Vector2(
		_overlay.size.x + UiTokens.BATTLE_CARD_PAD_H - label_size.x,
		-UiTokens.BATTLE_CARD_PAD_V - UiTokens.EXP_GAIN_GAP - label_size.y)
	_exp_gain_label.position = start
	_exp_gain_label.modulate.a = 0.0
	_exp_gain_label.visible = true
	var fade_in := UiTokens.EXP_GAIN_FADE_IN * speed_scale
	var fade_out := UiTokens.EXP_GAIN_FADE_OUT * speed_scale
	_exp_gain = create_tween()
	_exp_gain.tween_property(_exp_gain_label, ^"modulate:a", 1.0, fade_in)
	_exp_gain.tween_interval(maxf(hold - fade_in - fade_out, 0.0))
	_exp_gain.tween_property(_exp_gain_label, ^"modulate:a", 0.0, fade_out)
	_exp_gain.tween_callback(_exp_gain_label.hide)
	_exp_rise = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_exp_rise.tween_property(_exp_gain_label, ^"position:y", start.y - UiTokens.EXP_GAIN_RISE,
		hold)
	return _exp_gain


## La barre reste EXP_BAR_LINGER (une autre tranche peut la reprendre), s'efface en
## EXP_BAR_FADE, puis est cachée ; instantané si speed_scale vaut 0.
func _schedule_exp_hide() -> void:
	_kill_exp_hide()
	var linger := UiTokens.EXP_BAR_LINGER * speed_scale
	var fade := UiTokens.EXP_BAR_FADE * speed_scale
	if linger + fade <= 0.0:
		_exp_bar.visible = false
		return
	_exp_hide = create_tween()
	_exp_hide.tween_interval(linger)
	_exp_hide.tween_property(_exp_bar, ^"modulate:a", 0.0, fade)
	_exp_hide.tween_callback(_exp_bar.hide)


func _kill_exp_hide() -> void:
	if _exp_hide != null:
		_exp_hide.kill()
		_exp_hide = null
