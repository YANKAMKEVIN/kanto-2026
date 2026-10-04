class_name CharacterLook
extends RefCounted
## Où trouver l'apparence d'un personnage et comment l'afficher (docs/tech/jalon-07.md §3.2) :
## **peinte** (128 px à 1:1, filtre LINEAR ; CLAUDE.md) si
## `painted/<sprite>_frames.tres` existe, sinon **provisoire** (pixel art ×2, NEAREST), sinon
## l'apparence générique provisoire. Une seule règle pour `Npc` et `Player` (branchés au T3).
## Classe pure : l'existence des fichiers est demandée à un [Callable] (les tests en
## fournissent un faux).

const PAINTED_DIR: String = "res://assets/sprites/characters/painted/"
const PLACEHOLDER_DIR: String = "res://assets/sprites/characters/placeholder/"
## Apparence générique (provisoire) quand aucune planche n'existe pour le nom demandé.
const FALLBACK_SPRITE: StringName = &"npc"
const FRAMES_SUFFIX: String = "_frames.tres"
## Échelle d'affichage : peint à 1:1, provisoire pixel art ×2.
const PAINTED_SCALE: float = 1.0
const PLACEHOLDER_SCALE: float = 2.0

## SpriteFrames à charger.
var frames_path: String = ""
## 1.0 peint, 2.0 provisoire.
var scale: float = PLACEHOLDER_SCALE
var filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_NEAREST
## Vrai pour une apparence peinte.
var painted: bool = false


## Apparence de [param sprite]. [param exists] : `func(path: String) -> bool` (défaut :
## [method ResourceLoader.exists]).
static func resolve(sprite: StringName, exists: Callable = Callable()) -> CharacterLook:
	var check := exists if exists.is_valid() else _resource_exists
	var look := CharacterLook.new()
	if not sprite.is_empty():
		var painted_path := painted_frames_path(sprite)
		if check.call(painted_path):
			look.frames_path = painted_path
			look.scale = PAINTED_SCALE
			look.filter = CanvasItem.TEXTURE_FILTER_LINEAR
			look.painted = true
			return look
		var placeholder_path := placeholder_frames_path(sprite)
		if check.call(placeholder_path):
			look.frames_path = placeholder_path
			return look
	look.frames_path = placeholder_frames_path(FALLBACK_SPRITE)
	return look


static func painted_frames_path(sprite: StringName) -> String:
	return PAINTED_DIR + String(sprite) + FRAMES_SUFFIX


static func placeholder_frames_path(sprite: StringName) -> String:
	return PLACEHOLDER_DIR + String(sprite) + FRAMES_SUFFIX


static func _resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path)
