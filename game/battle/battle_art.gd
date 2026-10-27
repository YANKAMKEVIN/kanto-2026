class_name BattleArt
extends RefCounted
## Images des Pokémon en combat (CB.1, `docs/tech/combat-maquettes.md`) : **seul** endroit du
## combat qui choisit l'image d'une espèce et sa boîte visible.
##
## - Adversaire : **artwork officiel** (`assets/sprites/pokemon/official/NNN.png`, par numéro du
##   Pokédex), resserré sur son cadre utile par [PokedexArt] (chargement partagé avec le
##   Pokédex), filtre linéaire ; à défaut, le sprite provisoire de face.
## - Ton Pokémon : dos **peint** (`dos/dos_ia_NNN.png`, filtre linéaire) s'il existe, sinon sprite provisoire **de dos** (pixel art 64 px, NEAREST) jusqu'au premier lot
##   de dos peints (J11) ; à défaut (aucune espèce des données ne doit en manquer :
##   `test_battle_art.gd`), l'artwork officiel : jamais de côté vide.
## - Taille réelle (m) : données du Pokédex (`data/pokedex/kanto.json`) ; inconnue : la taille de
##   référence ([constant BattleLayout.REFERENCE_HEIGHT_M]).
## - Orientation : l'adversaire regarde vers la gauche (vers ton Pokémon) ; les artworks tournés
##   vers la droite ([constant FACING_RIGHT]) sont retournés (`"flip"`, boîte en miroir).
## Les données d'espèces viennent de [method setup] (Boot) ; sans appel, elles sont lues une
## fois et partagées (tests, outils de capture).

## Dossier des sprites provisoires (pixel art 64 px).
const PLACEHOLDER_DIR: String = "res://assets/sprites/pokemon/placeholder/"

## Dossier des dos de combat **peints** (1024 × 1024 RGBA, `dos_ia_NNN.png`, NNN = numéro du Pokédex) :
## lot « série dos » (`tools/art/serie_dos.py`, `docs/design/inventaire-art.md` §2). Lus en priorité
## pour le côté du joueur ; une espèce sans fichier garde son sprite provisoire.
const PAINTED_BACK_DIR: String = "res://assets/sprites/pokemon/dos/"

## Dos peint **en plongée** pour le cadrage B (`dos_rb_NNN.png`, déjà coupé par le bas : posé
## sur le bord de l'écran, [constant BattleLayout.BACK_CROP] ne s'applique pas). Priorité : dos RB
## > dos IA > dos 3D > sprite provisoire.

## Dos 3D (`dos3d_NNN.png`, rendu X/Y, même format 1024²) : repli du dos IA pour une espèce qui n'a
## pas de `dos_ia` (16 prototypes validés, dont 4 sans équivalent IA : 050, 051, 096, 109).
## Priorité : dos IA > dos 3D > sprite provisoire.

## Numéros du Pokédex dont l'artwork officiel regarde vers la droite (relevé sur planche,
## QA A17 du J30 : Roucarnage du rival tournait le dos) : retournés côté adversaire.
const FACING_RIGHT: Array[int] = [2, 9, 10, 18, 21, 28, 30, 38, 53, 55, 58, 78, 83, 106, 118,
	146, 147]

## Boîtes visibles des images provisoires, par chemin (lues une fois).
static var _boxes: Dictionary[String, Rect2] = {}
static var _shared_pokemon: PokemonData
static var _shared_dex: PokedexLibrary

var _pokemon: PokemonData
var _dex: PokedexLibrary


## Données d'espèces (numéro) et du Pokédex (taille). Null : lecture partagée à la demande.
func setup(pokemon: PokemonData, dex: PokedexLibrary) -> void:
	_pokemon = pokemon
	_dex = dex


## Chemin du sprite provisoire de [param species] (de dos si [param back]) : seule convention
## de chemin des sprites provisoires de combat.
static func placeholder_path(species: StringName, back: bool) -> String:
	return PLACEHOLDER_DIR + "%s_%s.png" % [species, "back" if back else "front"]


## Chemin du dos peint du numéro [param dex] du Pokédex (le fichier peut ne pas exister).
static func painted_back_path(dex: int) -> String:
	return PAINTED_BACK_DIR + "dos_ia_%03d.png" % dex


## Chemin du dos 3D du numéro [param dex] (repli du dos IA ; le fichier peut ne pas exister).
static func painted_back_3d_path(dex: int) -> String:
	return PAINTED_BACK_DIR + "dos3d_%03d.png" % dex


## Chemin du dos en plongée (cadrage B) du numéro [param dex] (le fichier peut ne pas exister).
static func painted_back_rb_path(dex: int) -> String:
	return PAINTED_BACK_DIR + "dos_rb_%03d.png" % dex


## Chemin du dos peint à utiliser pour le numéro [param dex] : plongée, puis IA, puis 3D ; "" sinon.
static func best_painted_back_path(dex: int) -> String:
	for path: String in [painted_back_rb_path(dex), painted_back_path(dex),
			painted_back_3d_path(dex)]:
		if ResourceLoader.exists(path):
			return path
	return ""


## Numéro du Pokédex de [param species] (0 si inconnu).
func dex_number(species: StringName) -> int:
	var data := _species_data()
	if data == null or not data.has_species(species):
		return 0
	return data.get_species(species).dex


## Taille réelle (m) de [param species] ; inconnue : la taille de référence.
func height_m(species: StringName) -> float:
	var dex := _dex_data()
	if dex == null or not dex.has_species(species):
		return BattleLayout.REFERENCE_HEIGHT_M
	var entry := dex.get_species(species)
	return entry.height if entry.height > 0.0 else BattleLayout.REFERENCE_HEIGHT_M


## Image de combat de [param species] : { texture (Texture2D ou null), box (Rect2 : boîte
## visible dans la texture, pieds au bas-centre), official (bool : artwork HD, filtre
## linéaire ; sinon pixel art provisoire, NEAREST, échelle entière), crop (float, dos
## seulement : part de la boîte sous le bord bas en cadrage B, 0 pour un dos en plongée) }.
func image(species: StringName, back: bool) -> Dictionary:
	var result := _image(species, back)
	if back:
		var texture: Texture2D = result["texture"]
		var rb := texture != null and texture.resource_path.get_file().begins_with("dos_rb_")
		result["crop"] = 0.0 if rb else BattleLayout.BACK_CROP
	return result


func _image(species: StringName, back: bool) -> Dictionary:
	if species == GhostDisguise.SPECIES:
		return _ghost_image(back)
	if not back:
		var official := _official(species)
		if not official.is_empty():
			return _facing_left(official, dex_number(species))
	if back:
		var painted_path := best_painted_back_path(dex_number(species))
		if not painted_path.is_empty():
			var painted := load(painted_path) as Texture2D
			return {"texture": painted, "official": true, "box": visible_box(painted, painted_path)}
	var path := placeholder_path(species, back)
	if species.is_empty() or not ResourceLoader.exists(path):
		# Repli (correctif QA 12A) : un dos manquant ne laisse jamais le côté du joueur vide ;
		# l'artwork officiel le remplace (le test des données exige pourtant chaque dos).
		var fallback := _official(species) if back else {}
		if not fallback.is_empty():
			return fallback
		return {"texture": null, "official": false, "box": Rect2(Vector2.ZERO, BattleLayout.NATIVE)}
	var sprite := load(path) as Texture2D
	return {"texture": sprite, "official": false, "box": visible_box(sprite, path)}


## Silhouette du SPECTRE (jalon 19, [GhostDisguise]) : peinte (filtre linéaire, comme un
## artwork), taille de référence ; elle n'existe pas en dos (texture nulle).
func _ghost_image(back: bool) -> Dictionary:
	var path := GhostDisguise.TEXTURE_PATH
	if back or not ResourceLoader.exists(path):
		return {"texture": null, "official": false, "box": Rect2(Vector2.ZERO, BattleLayout.NATIVE)}
	var texture := load(path) as Texture2D
	return {"texture": texture, "official": true, "box": visible_box(texture, path)}


## [param image] (artwork de face) tourné vers la gauche : un artwork de [constant FACING_RIGHT]
## est retourné (`"flip"`) et sa boîte mise en miroir dans la texture.
static func _facing_left(image: Dictionary, number: int) -> Dictionary:
	if not FACING_RIGHT.has(number):
		return image
	var box: Rect2 = image["box"]
	var width: float = (image["texture"] as Texture2D).get_size().x
	var mirrored := image.duplicate()
	mirrored["flip"] = true
	mirrored["box"] = Rect2(Vector2(width - box.end.x, box.position.y), box.size)
	return mirrored


## Artwork officiel de [param species], resserré sur son cadre utile ; vide sans artwork.
func _official(species: StringName) -> Dictionary:
	var number := dex_number(species)
	var texture := PokedexArt.portrait(number) if PokedexArt.has_portrait(number) else null
	if texture == null:
		return {}
	var margin := float(PokedexArt.THUMB_CROP_MARGIN) \
		if PokedexArt.portrait_crop(number).has_area() else 0.0
	var size := texture.get_size()
	return {"texture": texture, "official": true,
		"box": Rect2(Vector2.ONE * margin, size - Vector2.ONE * margin * 2.0)}


## Boîte de l'alpha de [param texture] (lue une fois par [param key]) ; toute l'image si
## illisible.
static func visible_box(texture: Texture2D, key: String) -> Rect2:
	if _boxes.has(key):
		return _boxes[key]
	var box := Rect2(Vector2.ZERO, texture.get_size())
	var data := texture.get_image()
	if data != null:
		if data.is_compressed():
			data.decompress()
		var used := data.get_used_rect()
		if used.has_area():
			box = Rect2(used)
	_boxes[key] = box
	return box


func _species_data() -> PokemonData:
	if _pokemon != null:
		return _pokemon
	if _shared_pokemon == null:
		_shared_pokemon = PokemonData.new()
		_shared_pokemon.load_dir()
	return _shared_pokemon


func _dex_data() -> PokedexLibrary:
	if _dex != null:
		return _dex
	if _shared_dex == null:
		_shared_dex = PokedexLibrary.new()
		_shared_dex.load_file()
	return _shared_dex
