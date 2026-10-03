class_name GameSettings
extends RefCounted
## Réglages de l'appareil (dossier 08 §7, jalon-06.md §3.8) : valeurs par défaut, bornes,
## aller-retour JSON. Classe pure : ne connaît aucun nœud.
##
## Ils ne font **pas** partie de la partie : fichier à part ([SettingsStore],
## `user://settings.json`, §5.3), jamais remis à zéro ni restauré par une sauvegarde.
## Lecture tolérante : un champ absent, mal formé ou hors bornes prend sa valeur par défaut,
## un champ inconnu est ignoré ; [method from_dict] n'échoue jamais.
##
## Chaque réglage a une clé ([constant KEYS]) : c'est l'identifiant du contrôle de l'écran
## Paramètres (`SettingsScreen.setting_changed(key, value)`) et le nom du champ JSON. La valeur
## échangée avec l'écran est **celle du réglage** (booléen, entier d'enum, flottant), jamais un
## rang dans une liste.
##
## Pas de « sauvegarde automatique » : elle est permanente (dossier 08 §7). Pas d'AUDIO (Q-17).

enum TextSpeed { SLOW, NORMAL, FAST, INSTANT }
enum TextSize { NORMAL, LARGE }
## AUTO : le profil est choisi selon l'appareil ([GraphicsProfile]) ; jamais AUTO une fois
## résolu.
enum Graphics { AUTO, HIGH, ECO }

const TEXT_SPEED: StringName = &"text_speed"
const CONFIRM_ACTIONS: StringName = &"confirm_actions"
const JOYSTICK_SCALE: StringName = &"joystick_scale"
const JOYSTICK_OPACITY: StringName = &"joystick_opacity"
const BUTTON_SCALE: StringName = &"button_scale"
const HAPTICS: StringName = &"haptics"
const LEFT_HANDED: StringName = &"left_handed"
const TEXT_SIZE: StringName = &"text_size"
const HIGH_CONTRAST: StringName = &"high_contrast"
const REDUCE_MOTION: StringName = &"reduce_motion"
const REDUCE_FLASHES: StringName = &"reduce_flashes"
const GRAPHICS: StringName = &"graphics"
## Tous les réglages, dans l'ordre du fichier.
const KEYS: Array[StringName] = [TEXT_SPEED, CONFIRM_ACTIONS, JOYSTICK_SCALE, JOYSTICK_OPACITY,
	BUTTON_SCALE, HAPTICS, LEFT_HANDED, TEXT_SIZE, HIGH_CONTRAST, REDUCE_MOTION, REDUCE_FLASHES,
	GRAPHICS]

## Noms écrits dans le JSON pour les enums (un rang changerait si l'enum était réordonnée).
const TEXT_SPEED_NAMES: Array[String] = ["slow", "normal", "fast", "instant"]
const TEXT_SIZE_NAMES: Array[String] = ["normal", "large"]
const GRAPHICS_NAMES: Array[String] = ["auto", "high", "eco"]

## Caractères par seconde des dialogues, par [enum TextSpeed] (§13) ; 0 = la page entière
## d'un coup (convention de [DialogueSession]). NORMAL = la vitesse d'avant le J6.
const CHARS_PER_SECOND: Array[float] = [25.0, UiTokens.DIALOG_CHARS_PER_SECOND, 90.0, 0.0]
## Tailles permises du joystick (§13 : petite, normale, grande).
const JOYSTICK_SCALES: Array[float] = [0.8, 1.0, 1.2]
## Opacité du joystick : part de l'opacité actuelle, de 30 à 100 %, par pas de 10 %.
const JOYSTICK_OPACITY_MIN: float = 0.3
const JOYSTICK_OPACITY_MAX: float = 1.0
const JOYSTICK_OPACITY_STEP: float = 0.1
## Tailles permises des boutons ronds d'exploration (§13).
const BUTTON_SCALES: Array[float] = [1.0, 1.2]
## Réduction des animations (§13) : facteur des durées en combat et dans le menu. La tenue des
## messages de combat n'en dépend pas (T29).
const REDUCED_BATTLE_SPEED: float = 0.6
const REDUCED_MENU_SPEED: float = 0.5
## Tolérance de comparaison des flottants lus du JSON.
const EPSILON: float = 0.001

var text_speed: TextSpeed = TextSpeed.NORMAL
## Q-18 : confirmation de certaines actions (oublier une capacité au J6), désactivée.
var confirm_actions: bool = false
var joystick_scale: float = 1.0
var joystick_opacity: float = 1.0
var button_scale: float = 1.0
var haptics: bool = true
## Q-16 : exploration seulement (joystick à droite, boutons à gauche).
var left_handed: bool = false
var text_size: TextSize = TextSize.NORMAL
var high_contrast: bool = false
var reduce_motion: bool = false
var reduce_flashes: bool = false
var graphics: Graphics = Graphics.AUTO


## Réglages lus de [param dict] ; tout champ absent, mal formé ou hors bornes garde sa valeur
## par défaut, les champs inconnus sont ignorés. N'échoue jamais.
static func from_dict(dict: Dictionary) -> GameSettings:
	var settings := GameSettings.new()
	for key: StringName in KEYS:
		var raw: Variant = dict.get(String(key))
		if raw == null:
			continue
		var value: Variant = _from_json(key, raw)
		if value != null:
			settings.set_value(key, value)
	return settings


## Dictionnaire prêt pour le JSON (enums écrites par leur nom).
func to_dict() -> Dictionary:
	return {
		String(TEXT_SPEED): TEXT_SPEED_NAMES[text_speed],
		String(CONFIRM_ACTIONS): confirm_actions,
		String(JOYSTICK_SCALE): joystick_scale,
		String(JOYSTICK_OPACITY): joystick_opacity,
		String(BUTTON_SCALE): button_scale,
		String(HAPTICS): haptics,
		String(LEFT_HANDED): left_handed,
		String(TEXT_SIZE): TEXT_SIZE_NAMES[text_size],
		String(HIGH_CONTRAST): high_contrast,
		String(REDUCE_MOTION): reduce_motion,
		String(REDUCE_FLASHES): reduce_flashes,
		String(GRAPHICS): GRAPHICS_NAMES[graphics],
	}


func duplicate() -> GameSettings:
	return GameSettings.from_dict(to_dict())


func equals(other: GameSettings) -> bool:
	return other != null and to_dict() == other.to_dict()


## Valeur du réglage [param key] (null si la clé est inconnue).
func get_value(key: StringName) -> Variant:
	if not KEYS.has(key):
		return null
	return get(String(key))


## Vrai si [param value] est permise pour [param key] : type attendu (entier d'enum,
## booléen, nombre), dans les bornes, sur un cran permis.
static func is_valid(key: StringName, value: Variant) -> bool:
	match key:
		TEXT_SPEED:
			return _is_index(value, TEXT_SPEED_NAMES.size())
		TEXT_SIZE:
			return _is_index(value, TEXT_SIZE_NAMES.size())
		GRAPHICS:
			return _is_index(value, GRAPHICS_NAMES.size())
		CONFIRM_ACTIONS, HAPTICS, LEFT_HANDED, HIGH_CONTRAST, REDUCE_MOTION, REDUCE_FLASHES:
			return value is bool
		JOYSTICK_SCALE:
			return _is_number(value) and _find_step(JOYSTICK_SCALES, float(value)) >= 0
		BUTTON_SCALE:
			return _is_number(value) and _find_step(BUTTON_SCALES, float(value)) >= 0
		JOYSTICK_OPACITY:
			return _is_number(value) and _opacity_step(float(value)) >= 0
	return false


## Change le réglage [param key]. Vrai seulement si la valeur est permise **et** différente ;
## une valeur refusée ne change rien (jamais d'échec).
func set_value(key: StringName, value: Variant) -> bool:
	if not is_valid(key, value):
		return false
	var normalized: Variant = _normalize(key, value)
	if get_value(key) == normalized:
		return false
	set(String(key), normalized)
	return true


## Vitesse d'écriture des dialogues (Q-20 : les dialogues seulement) ; 0 = page entière.
func chars_per_second() -> float:
	return CHARS_PER_SECOND[text_speed]


## Facteur des durées d'animation du combat (`BattleDirector.speed_scale`).
func battle_speed_scale() -> float:
	return REDUCED_BATTLE_SPEED if reduce_motion else 1.0


## Facteur des durées d'animation du menu (`TrainerMenu.speed_scale`).
func menu_speed_scale() -> float:
	return REDUCED_MENU_SPEED if reduce_motion else 1.0


## Valeur interne d'une valeur JSON (nom d'enum → entier, nombre → flottant) ; null si la
## forme ne va pas.
static func _from_json(key: StringName, raw: Variant) -> Variant:
	match key:
		TEXT_SPEED:
			return _name_index(TEXT_SPEED_NAMES, raw)
		TEXT_SIZE:
			return _name_index(TEXT_SIZE_NAMES, raw)
		GRAPHICS:
			return _name_index(GRAPHICS_NAMES, raw)
	return raw


static func _name_index(names: Array[String], raw: Variant) -> Variant:
	if not raw is String:
		return null
	var index := names.find(raw as String)
	return index if index >= 0 else null


## Forme rangée : entier pour une enum, flottant exact du cran pour une échelle.
static func _normalize(key: StringName, value: Variant) -> Variant:
	match key:
		TEXT_SPEED, TEXT_SIZE, GRAPHICS:
			return int(value)
		JOYSTICK_SCALE:
			return JOYSTICK_SCALES[_find_step(JOYSTICK_SCALES, float(value))]
		BUTTON_SCALE:
			return BUTTON_SCALES[_find_step(BUTTON_SCALES, float(value))]
		JOYSTICK_OPACITY:
			# En pour cent entiers puis / 100 : 0,7 exact, pas 0,7000000000000001.
			var percent := roundi(JOYSTICK_OPACITY_MIN * 100.0) \
				+ _opacity_step(float(value)) * roundi(JOYSTICK_OPACITY_STEP * 100.0)
			return percent / 100.0
	return value


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


static func _is_index(value: Variant, count: int) -> bool:
	return JsonFields.is_int(value) and int(value) >= 0 and int(value) < count


static func _find_step(steps: Array[float], value: float) -> int:
	for i: int in steps.size():
		if absf(steps[i] - value) < EPSILON:
			return i
	return -1


## Rang du cran d'opacité (0 = 30 %), ou -1 hors bornes ou entre deux crans.
static func _opacity_step(value: float) -> int:
	if value < JOYSTICK_OPACITY_MIN - EPSILON or value > JOYSTICK_OPACITY_MAX + EPSILON:
		return -1
	var steps := (value - JOYSTICK_OPACITY_MIN) / JOYSTICK_OPACITY_STEP
	if absf(steps - roundf(steps)) > EPSILON * 10.0:
		return -1
	return roundi(steps)
