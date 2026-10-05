class_name BorderDecals
extends RefCounted
## Décalcomanies le long de la frontière herbe / pavés (terre, pavés déchaussés, touffes), comme
## la place du prototype (proto_da_jadielle.gd, `_poser_bordures`) : même algorithme, même
## suite de tirages. Graine fixe par carte : la même carte donne toujours les mêmes décors.
## Classe pure : l'outil de construction d'une carte pose les sprites (nœud `GroundDecals`,
## [constant WorldLighting.Z_GROUND_DECALS], non trié) ; elle ne fait que les décrire.

const TEXTURE_DIR: String = "res://assets/world/ground/decals/"
## Variantes par famille (decal_<famille>_<1..4>.png).
const VARIANTS: int = 4
## Tirages : terre sous ce seuil, pavé déchaussé ensuite jusqu'au second ; une touffe toujours.
const EARTH_CHANCE: float = 0.25
const PAVING_CHANCE: float = 0.40
## Échelles de base (pixels du sol) et dispersion.
const EARTH_SCALE: float = 0.45
const PAVING_SCALE: float = 0.4
const TUFT_SCALE: float = 0.8
const _SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## Décors du bord des cases de [param paving] (Vector2i → vrai, dans l'ordre d'insertion) sur
## une carte de [param map_size] cases. Chaque entrée : { "texture": chemin, "position":
## Vector2 (centre, pixels monde), "scale": float, "flip_h": bool }, dans l'ordre de dessin.
static func plan(paving: Dictionary, map_size: Vector2i, seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var decals: Array[Dictionary] = []
	var tile := float(Grid.TILE_SIZE)
	for cell: Vector2i in paving:
		for side: Vector2i in _SIDES:
			var neighbour := cell + side
			if paving.has(neighbour) or not _inside(map_size, neighbour):
				continue
			# Milieu du côté de la case pavée qui touche l'herbe.
			var edge := (Vector2(cell) + Vector2(0.5, 0.5) + Vector2(side) * 0.5) * tile
			var along := Vector2(absf(side.y), absf(side.x))
			for i in 2:
				var point := edge + along * rng.randf_range(-40.0, 40.0)
				point += Vector2(side) * rng.randf_range(-8.0, 8.0)
				var draw := rng.randf()
				if draw < EARTH_CHANCE:
					decals.append(_decal(rng, "terre", point, EARTH_SCALE))
				elif draw < PAVING_CHANCE:
					decals.append(_decal(rng, "pave", point, PAVING_SCALE))
				var tuft := point + Vector2(side) * rng.randf_range(-4.0, 10.0)
				decals.append(_decal(rng, "touffe", tuft, TUFT_SCALE))
	return decals


## Les sprites des décors de [param decals] ([method plan]) sous [param parent].
static func place(decals: Array[Dictionary], parent: Node, owner_node: Node = null) -> void:
	for decal: Dictionary in decals:
		var sprite := Sprite2D.new()
		sprite.texture = load(decal["texture"])
		sprite.position = decal["position"]
		sprite.scale = Vector2.ONE * float(decal["scale"])
		sprite.flip_h = decal["flip_h"]
		parent.add_child(sprite)
		if owner_node != null:
			sprite.owner = owner_node


static func _decal(rng: RandomNumberGenerator, family: String, point: Vector2,
		base_scale: float) -> Dictionary:
	# Même ordre de tirages que le prototype : variante, puis échelle, puis miroir.
	var variant := rng.randi_range(1, VARIANTS)
	var scale := base_scale * rng.randf_range(0.85, 1.15)
	var flip := rng.randf() < 0.5
	return {
		"texture": "%sdecal_%s_%d.png" % [TEXTURE_DIR, family, variant],
		"position": point,
		"scale": scale,
		"flip_h": flip,
	}


static func _inside(size: Vector2i, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y
