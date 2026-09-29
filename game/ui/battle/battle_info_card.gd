class_name BattleInfoCard
extends BattleWidget
## Carte d'information de combat (combat-v1) : NOM en MAJUSCULES, ♂/♀ coloré, « Nv. 5 » à
## droite, barre de PV, et « 19 / 19 » sous la barre, à droite, côté joueur seulement.
##
## Carte sombre translucide comme la boîte de dialogue (jalon 4 Q17), largeur
## BATTLE_CARD_WIDTH, hauteur BATTLE_CARD_HEIGHT (sans chiffres) ou BATTLE_CARD_HEIGHT_NUMBERS.
## Sous HP_LOW_THRESHOLD, elle pulse légèrement (dossier 05 §12) ; au-dessus, elle s'arrête.
## Elle ne connaît que sa BattleCardView ; play_hit vibre (coup reçu, plus fort si critique).

## Libellé du niveau (texte d'interface) et format des PV chiffrés.
const LEVEL_TAG := "Nv."
const HP_FORMAT := "%d / %d"
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
var _show_numbers: bool = false
var _pulse: Tween
var _pulsing: bool = false

@onready var _rows: VBoxContainer = %Rows
@onready var _header: HBoxContainer = %Header
@onready var _name_label: Label = %NameLabel
@onready var _gender_icon: TextureRect = %Gender
@onready var _level_tag: Label = %LevelTag
@onready var _level_value: Label = %LevelValue
@onready var _bar: HpBar = %HpBar
@onready var _numbers: Label = %HpNumbers


func _ready() -> void:
	super._ready()
	_rows.add_theme_constant_override(&"separation", UiTokens.BATTLE_CARD_ROW_GAP)
	_header.add_theme_constant_override(&"separation", UiTokens.BATTLE_CARD_NAME_GAP)
	_gender_icon.custom_minimum_size = Vector2.ONE * UiTokens.GENDER_ICON
	_level_tag.text = LEVEL_TAG
	_bar.display_changed.connect(_on_hp_shown)
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
	_level_value.text = str(view.level)
	set_show_hp_numbers(view.show_hp_numbers)
	set_hp(view.hp, view.max_hp)


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


func get_name_text() -> String:
	return _name_label.text


func get_gender() -> BattleCardView.Gender:
	return _gender


func get_gender_icon() -> TextureRect:
	return _gender_icon


## « Nv. 5 ».
func get_level_text() -> String:
	return "%s %d" % [LEVEL_TAG, _level]


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


func _apply_numbers() -> void:
	_numbers.visible = _show_numbers
	var height := UiTokens.BATTLE_CARD_HEIGHT_NUMBERS if _show_numbers \
		else UiTokens.BATTLE_CARD_HEIGHT
	_body.custom_minimum_size = Vector2(UiTokens.BATTLE_CARD_WIDTH, height)


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
