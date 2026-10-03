extends Node2D
## Intérieur du Centre Pokémon ou de la Boutique (série 03, lumière neutre) : enveloppe de la
## pièce (15 × 10 cases) + meubles triés par les pieds + personnages. Jetable (prototype).

const CASE := 96
const TEX := "res://proto/da_jadielle/tex/"
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const MARCHEUR := preload("res://proto/da_jadielle/marcheur.gd")
const EMPRISES := preload("res://proto/da_jadielle/emprises.gd")
## Lumière d'intérieur : neutre légèrement chaude (lampes), sans voile.
const TEINTE := Color(1.0, 0.97, 0.92)

## [enveloppe, meubles [texture, x, y (pied, en cases)], personnages [texture, coins]].
const PIECES := {
	"centre": ["int_centre_coque.png", [
		["int_comptoir.png", 7.5, 5.0], ["int_terminal.png", 2.2, 3.4],
		["int_plante.png", 12.9, 3.4], ["int_banquette.png", 3.4, 7.2],
		["int_banquette.png", 11.6, 7.2], ["int_plante.png", 1.2, 8.8],
		["int_plante.png", 13.8, 8.8],
	], [
		["infirmiere", [Vector2i(7, 3)]],
		["dresseuse", [Vector2i(10, 6)]],
		["roucool", [Vector2i(9, 6)]],
		["perso_p2", [Vector2i(4, 6), Vector2i(4, 8), Vector2i(11, 8), Vector2i(11, 6)]],
	]],
	"boutique": ["int_boutique_coque.png", [
		["int_caisse.png", 7.5, 5.0], ["int_rayon.png", 2.3, 3.2], ["int_rayon.png", 12.7, 3.2],
		["int_presentoir.png", 4.0, 7.3], ["int_presentoir.png", 11.0, 7.3],
		["int_plante.png", 13.8, 8.8],
	], [
		["marchand", [Vector2i(7, 3)]],
		["livreur", [Vector2i(12, 6)]],
		["perso_p2", [Vector2i(3, 6), Vector2i(3, 8), Vector2i(8, 8), Vector2i(8, 6)]],
	]],
}

var piece := "centre"


func _ready() -> void:
	var donnees: Array = PIECES[piece]
	var coque := Sprite2D.new()
	coque.texture = load(TEX + donnees[0])
	coque.centered = false
	add_child(coque)
	var ombres := Node2D.new()
	add_child(ombres)
	var tries := Node2D.new()
	tries.y_sort_enabled = true
	add_child(tries)
	# Murs : le fond (3 rangées), les côtés, le bas sauf l'entrée (colonnes 6 à 8).
	var obstacles: Array[Rect2i] = [Rect2i(0, 0, 15, 3), Rect2i(0, 0, 1, 10),
		Rect2i(14, 0, 1, 10), Rect2i(0, 9, 6, 1), Rect2i(9, 9, 6, 1)]
	for meuble: Array in donnees[1]:
		var texture: Texture2D = load(TEX + meuble[0])
		var pied := Vector2(meuble[1], meuble[2]) * CASE
		obstacles.append_array(EMPRISES.de(meuble[0], Vector2(meuble[1], meuble[2])))
		var sprite := _au_pied(texture)
		sprite.position = pied
		tries.add_child(sprite)
		var contact := _au_pied(texture)
		var materiau := ShaderMaterial.new()
		materiau.shader = CONTACT_SHADER
		materiau.set_shader_parameter(&"etendue", 14.0)
		materiau.set_shader_parameter(&"part_base", 0.15)
		contact.material = materiau
		contact.position = pied + Vector2(0, 14)
		ombres.add_child(contact)
	for habitant: Array in donnees[2]:
		if (habitant[1] as Array).size() == 1:
			obstacles.append(Rect2i(habitant[1][0], Vector2i.ONE))
	var grille: AStarGrid2D = EMPRISES.grille(Vector2i(15, 10), obstacles)
	for habitant: Array in donnees[2]:
		var marcheur: Node2D = MARCHEUR.new()
		marcheur.obstacles = grille
		marcheur.planche_marche = load(TEX + habitant[0] + ".png")
		marcheur.planche_course = marcheur.planche_marche
		var coins: Array[Vector2i] = []
		coins.assign(habitant[1])
		marcheur.circuit = coins
		tries.add_child(marcheur)
	var teinte := CanvasModulate.new()
	teinte.color = TEINTE
	add_child(teinte)
	var camera := Camera2D.new()
	camera.position = Vector2(7.5, 5.0) * CASE
	add_child(camera)


func _au_pied(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	return sprite
