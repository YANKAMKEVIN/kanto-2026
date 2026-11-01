class_name CostumeSlot
extends PanelContainer
## Un costume de la section « Costumes » de l'écran Dresseur (dossier-costumes.md, CO-1, CO-2) :
## vignette = l'image d'attente de face de l'apparence du monde [D]. **Verrouillé** : silhouette
## noire, sans nom (CO-2). Le costume porté est cerclé (variation « TrainerBadgeOn »).
## Un toucher émet [signal touched] (verrouillé compris : l'écran dit alors pourquoi). Dans un
## défilement horizontal : le glissement du doigt atteint le ScrollContainer ([TapGuard]).

signal touched(slot: CostumeSlot)

var _view: CostumeSlotView
var _hit: Button
var _art: TextureRect


func _init(view: CostumeSlotView = null) -> void:
	_view = view if view != null else CostumeSlotView.new()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit = Button.new()
	# Zone tactile d'au moins TOUCH_MIN (le cadre du panneau s'ajoute autour).
	_hit.custom_minimum_size = Vector2.ONE * UiTokens.TOUCH_MIN
	_hit.flat = true
	_hit.focus_mode = Control.FOCUS_NONE
	_hit.mouse_filter = Control.MOUSE_FILTER_PASS
	_hit.tooltip_text = _view.name
	TapGuard.attach(_hit)
	_hit.pressed.connect(_on_pressed)
	add_child(_hit)
	_art = TextureRect.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture = idle_texture(_view.sprite)
	add_child(_art)
	theme_type_variation = &"TrainerBadgeOn" if _view.worn else &"TrainerBadge"
	_art.modulate = Color.WHITE if _view.unlocked else UiTokens.TRAINER_COSTUME_SILHOUETTE


## Image d'attente de face (`idle_down`) de l'apparence [param sprite] ; null si absente.
static func idle_texture(sprite: StringName) -> Texture2D:
	if sprite.is_empty():
		return null
	var frames := load(CharacterLook.resolve(sprite).frames_path) as SpriteFrames
	if frames == null or not frames.has_animation(&"idle_down"):
		return null
	return frames.get_frame_texture(&"idle_down", 0)


func get_view() -> CostumeSlotView:
	return _view


func get_hit() -> Button:
	return _hit


func get_art() -> TextureRect:
	return _art


## Vrai si la vignette est une silhouette (costume verrouillé, CO-2).
func is_silhouette() -> bool:
	return not _view.unlocked


func _on_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	touched.emit(self)
