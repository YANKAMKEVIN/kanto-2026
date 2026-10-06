class_name PokedexArt
extends RefCounted
## Images du Pokédex (refonte, docs/tech/pokedex-refonte.md §2) : **seul** endroit qui connaît
## le lien numéro ↔ fichier. Artworks officiels (PokeAPI, 475 × 475) nommés par **numéro**,
## jamais par espèce : une case inconnue trouve sa silhouette sans connaître l'espèce.
##
## - Portrait (grand, centre) : [method portrait_path], chargé à l'affichage.
## - Vignette 128 px (grille, ronds d'Évolution) : [method thumbnail], région de l'atlas
##   `atlas_128.png` (généré par `tools/build_pokedex_atlas.gd`, qui lit ses constantes ici).
## - Silhouette : la même vignette avec [method silhouette_material] (shader, forme seule).
## - Halo : [method halo_texture], dégradé radial clair derrière chaque image.
## Classe statique ; les ressources partagées sont créées au premier appel puis gardées.

## Nombre d'artworks (001 à 151).
const COUNT := 151
## Dossier des artworks et de l'atlas.
const PORTRAIT_DIR := "res://assets/sprites/pokemon/official/"
const ATLAS_PATH := PORTRAIT_DIR + "atlas_128.png"
## Cadre utile de chaque artwork (boîte de l'alpha + marge), écrit par build_pokedex_atlas.gd.
const CROPS_PATH := PORTRAIT_DIR + "crops.json"
const SILHOUETTE_SHADER_PATH := "res://game/ui/menu/pokedex/pokedex_silhouette.gdshader"
## Disposition de l'atlas : cases de [constant THUMB] px au pas de THUMB + [constant THUMB_PAD]
## (marge transparente de THUMB_PAD / 2 de chaque côté : le filtre linéaire ne bave pas).
const ATLAS_COLUMNS := 13
const ATLAS_ROWS := 12
const THUMB := 128
const THUMB_PAD := 4
## Plus grand côté de l'image dans sa case (centrée), après recadrage à l'alpha + marge.
const THUMB_ART := 124
const THUMB_CROP_MARGIN := 2

static var _thumbs: Dictionary[int, AtlasTexture] = {}
static var _atlas: Texture2D
static var _silhouette: ShaderMaterial
static var _halo: GradientTexture2D
static var _crops: Dictionary = {}
static var _crops_loaded: bool = false


## « res://…/004.png » ; "" hors de 1..[constant COUNT].
static func portrait_path(number: int) -> String:
	if number < 1 or number > COUNT:
		return ""
	return PORTRAIT_DIR + "%03d.png" % number


## Vrai si l'artwork de [param number] existe.
static func has_portrait(number: int) -> bool:
	var path := portrait_path(number)
	return not path.is_empty() and ResourceLoader.exists(path)


## Cadre utile de l'artwork [param number] en pixels de la source (boîte de l'alpha + marge) ;
## Rect2() si inconnu (hors bornes ou fichier absent : le portrait est alors montré entier).
static func portrait_crop(number: int) -> Rect2:
	if number < 1 or number > COUNT:
		return Rect2()
	if not _crops_loaded:
		_crops_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CROPS_PATH))
		if parsed is Dictionary and (parsed as Dictionary).get("crops") is Dictionary:
			_crops = (parsed as Dictionary)["crops"]
	var entry: Variant = _crops.get("%03d" % number, null)
	if not entry is Array or (entry as Array).size() != 4:
		return Rect2()
	var a: Array = entry
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


## Grand portrait de [param number], **resserré sur son cadre utile** (une [AtlasTexture] sur
## l'artwork chargé à l'appel) ; null si l'artwork n'existe pas.
static func portrait(number: int) -> Texture2D:
	if not has_portrait(number):
		return null
	var source := load(portrait_path(number)) as Texture2D
	var crop := portrait_crop(number)
	if source == null or not crop.has_area():
		return source
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = crop
	return texture


## Pas d'une case de l'atlas.
static func thumb_pitch() -> int:
	return THUMB + THUMB_PAD


## Taille de l'atlas (1716 × 1584).
static func atlas_size() -> Vector2i:
	return Vector2i(ATLAS_COLUMNS, ATLAS_ROWS) * thumb_pitch()


## Région de la vignette [param number] dans l'atlas ; Rect2() hors bornes.
@warning_ignore("integer_division")
static func thumb_region(number: int) -> Rect2:
	if number < 1 or number > COUNT:
		return Rect2()
	var index := number - 1
	var cell := Vector2(index % ATLAS_COLUMNS, index / ATLAS_COLUMNS) * thumb_pitch()
	return Rect2(cell + Vector2.ONE * (THUMB_PAD / 2), Vector2.ONE * THUMB)


## Vignette 128 px de [param number] (même objet à chaque appel) ; null hors bornes.
static func thumbnail(number: int) -> AtlasTexture:
	if number < 1 or number > COUNT:
		return null
	if _thumbs.has(number):
		return _thumbs[number]
	if _atlas == null:
		_atlas = load(ATLAS_PATH) as Texture2D
	var texture := AtlasTexture.new()
	texture.atlas = _atlas
	texture.region = thumb_region(number)
	_thumbs[number] = texture
	return texture


## Matériau partagé des silhouettes (teinte [constant UiTokens.DEX_SILHOUETTE]).
static func silhouette_material() -> ShaderMaterial:
	if _silhouette == null:
		_silhouette = ShaderMaterial.new()
		_silhouette.shader = load(SILHOUETTE_SHADER_PATH) as Shader
		_silhouette.set_shader_parameter(&"tint", UiTokens.DEX_SILHOUETTE)
	return _silhouette


## Halo radial partagé : [constant UiTokens.DEX_HALO_CENTER] au centre → transparent au bord.
## Derrière une silhouette, l'écran l'estompe de [constant UiTokens.DEX_HALO_UNKNOWN_ALPHA].
static func halo_texture() -> Texture2D:
	if _halo == null:
		var gradient := Gradient.new()
		var edge := UiTokens.DEX_HALO_CENTER
		edge.a = 0.0
		gradient.set_color(0, UiTokens.DEX_HALO_CENTER)
		gradient.set_color(1, edge)
		_halo = GradientTexture2D.new()
		_halo.gradient = gradient
		_halo.fill = GradientTexture2D.FILL_RADIAL
		_halo.fill_from = Vector2(0.5, 0.5)
		_halo.fill_to = Vector2(1.0, 0.5)
		_halo.width = UiTokens.DEX_HALO_TEXTURE
		_halo.height = UiTokens.DEX_HALO_TEXTURE
	return _halo
