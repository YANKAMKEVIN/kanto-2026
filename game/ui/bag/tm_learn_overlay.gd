class_name TmLearnOverlay
extends CanvasLayer
## Apprendre une CT depuis le Sac (jalon 11, T12 ; dossier 14 §6.1) : un voile au-dessus du Menu
## Dresseur, avec le bandeau des messages et l'hôte des panneaux du déroulé « apprendre / oublier
## une capacité » existant ([MoveLearnPrompt.teach] : « {pokemon} apprend {move} ! », ou
## « veut apprendre… », le panneau d'oubli, GARDER / NE PAS APPRENDRE). Aucune règle ici : Boot
## l'ouvre, lance le déroulé, le referme. Placement repris de l'écran d'évolution (bandeau
## centré en bas).

const BANNER_SCENE: PackedScene = preload("res://game/ui/battle/battle_message_banner.tscn")

var _root: Control
var _veil: ColorRect
var _banner: BattleMessageBanner
var _host: Control


func _ready() -> void:
	layer = UiTokens.LAYER_MENU + 1
	visible = false
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_veil = ColorRect.new()
	_veil.name = "Veil"
	# Même voile que l'Équipe (défaut, règle 4).
	_veil.color = UiTokens.TEAM_SCRIM
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_veil)
	_banner = BANNER_SCENE.instantiate() as BattleMessageBanner
	_banner.name = "Banner"
	_root.add_child(_banner)
	_banner.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.anchor_top = 1.0
	_banner.anchor_bottom = 1.0
	_banner.offset_left = -UiTokens.BATTLE_MESSAGE_WIDTH * 0.5
	_banner.offset_right = UiTokens.BATTLE_MESSAGE_WIDTH * 0.5
	_banner.offset_bottom = -UiTokens.EVOLUTION_BANNER_BOTTOM
	_banner.offset_top = -UiTokens.EVOLUTION_BANNER_BOTTOM - UiTokens.BATTLE_MESSAGE_HEIGHT
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_host = Control.new()
	_host.name = "PromptHost"
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_host)


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func get_message_banner() -> BattleMessageBanner:
	return _banner


func get_prompt_host() -> Control:
	return _host
