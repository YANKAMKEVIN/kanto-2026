class_name FlashbackFilter
extends CanvasLayer
## Filtre du souvenir (Chapitre Johto, JOH6, `docs/tech/jalon-joh6.md` §2.7 ; dossier JOH-07 §8 :
## le souvenir de Dante) : **sépia** plein écran sur le monde, bord d'image adouci (vignette).
## Posé au-dessus de l'étalonnage du monde et sous le HUD et les dialogues : les bulles restent
## lisibles. Ouvert et fermé par l'étape de scène « flashback » ([CutsceneDirector]).

const LAYER: int = UiTokens.LAYER_WORLD_GRADE + 1
const SHADER: Shader = preload("res://game/world/effects/flashback_sepia.gdshader")
## Durée des fondus d'entrée et de sortie du filtre (s) [D].
const FADE_SECONDS: float = 0.8

var _rect: ColorRect


func _init() -> void:
	layer = LAYER
	name = "FlashbackFilter"
	_rect = ColorRect.new()
	_rect.name = "Sepia"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"amount", 0.0)
	_rect.material = material
	add_child(_rect)


## Intensité du filtre (0 = aucun, 1 = sépia complet).
func get_amount() -> float:
	return float((_rect.material as ShaderMaterial).get_shader_parameter(&"amount"))


func set_amount(value: float) -> void:
	(_rect.material as ShaderMaterial).set_shader_parameter(&"amount", clampf(value, 0.0, 1.0))


## Fondu vers [param target] en [param seconds] (0 = tout de suite) ; attend la fin.
func fade_to(target: float, seconds: float = FADE_SECONDS) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		set_amount(target)
		return
	var tween := create_tween()
	tween.tween_method(set_amount, get_amount(), target, seconds)
	await tween.finished
