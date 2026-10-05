extends Node2D
## Intérieurs de Bourg Palette (prototype, série 07, lumière neutre) : enveloppe vide de la
## pièce + meubles triés par les pieds + tapis à plat + personnages, aux emplacements des
## plans du jalon 2 (docs/tech/jalon-02.md §4.3 à §4.7, mobilier à ±1 case).
## Jetable : les vraies pièces restent `game/world/maps/*.tscn`.

const CASE := 96
const TEX := "res://proto/da_jadielle/tex/"
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const MARCHEUR := preload("res://proto/da_jadielle/marcheur.gd")
const EMPRISES := preload("res://proto/da_jadielle/emprises.gd")
const TEINTE := Color(1.0, 0.97, 0.92)

## Chaque pièce : taille, enveloppe, ouverture du bas [x, largeur], meubles
## [texture, x, y, largeur, profondeur] (cases occupées, le pied est sous la dernière rangée),
## tapis [texture, centre x, centre y], personnages [texture, coins].
const PIECES := {
	"chambre": {
		"taille": Vector2i(14, 10), "coque": "int_chambre_coque.png", "ouverture": [6, 2],
		"meubles": [
			["int_lit.png", 1, 2, 2, 3], ["int_chevet.png", 3, 2, 1, 1],
			["int_petite_etagere.png", 4, 2, 1, 1], ["int_bureau_pc.png", 6, 2, 3, 1],
			["int_chaise_bureau.png", 7, 3, 1, 1], ["int_grande_etagere.png", 9, 2, 2, 2],
			["int_tele.png", 11, 2, 2, 1], ["int_sac.png", 1, 5, 1, 1],
			["int_plante.png", 1, 6, 1, 1], ["int_plante.png", 12, 6, 1, 1],
			["int_meuble_bas.png", 1, 8, 3, 1], ["int_commode_pokeball.png", 9, 8, 1, 1],
			["int_caisse_pokeballs.png", 10, 8, 2, 1],
		],
		"tapis": [["int_tapis_pokeball.png", 7.0, 5.5]],
		"habitants": [["perso_p2", [Vector2i(3, 4), Vector2i(3, 7), Vector2i(10, 7),
			Vector2i(10, 4), Vector2i(6, 4)]]],
	},
	"rdc": {
		"taille": Vector2i(14, 10), "coque": "int_rdc_coque.png", "ouverture": [6, 2],
		"meubles": [
			["int_escalier_montant.png", 1, 2, 2, 2], ["int_frigo.png", 3, 2, 1, 1],
			["int_cuisine.png", 4, 2, 3, 1], ["int_tele.png", 11, 2, 2, 1],
			["int_table_repas.png", 3, 4, 3, 2], ["int_canape.png", 9, 4, 3, 1],
			["int_table_basse.png", 9, 6, 2, 1], ["int_plante.png", 1, 7, 1, 1],
			["int_plante.png", 12, 7, 1, 1], ["int_meuble_bas.png", 1, 8, 3, 1],
			["int_porte_manteau.png", 5, 8, 1, 1], ["int_commode_pokeball.png", 9, 8, 1, 1],
		],
		"tapis": [["int_tapis_plaid.png", 4.5, 5.0], ["int_tapis_salon.png", 10.5, 6.5]],
		"habitants": [["perso_p2", [Vector2i(7, 8), Vector2i(7, 4), Vector2i(2, 4),
			Vector2i(7, 4)]]],
	},
	"rival": {
		"taille": Vector2i(18, 11), "coque": "int_rival_coque.png", "ouverture": [8, 2],
		"meubles": [
			["int_frigo.png", 1, 2, 1, 1], ["int_cuisine.png", 2, 2, 3, 1],
			["int_cuisiniere.png", 5, 2, 1, 1], ["int_escalier_montant.png", 7, 2, 3, 2],
			["int_cloison_v.png", 10, 2, 1, 3], ["int_bureau_angle.png", 11, 2, 2, 1],
			["int_chaise_gamer.png", 12, 3, 1, 1], ["int_commode.png", 13, 2, 2, 1],
			["int_lit_pokeball.png", 15, 2, 2, 3], ["int_chevet.png", 16, 5, 1, 1],
			["int_table_repas.png", 2, 4, 3, 2], ["int_commode_pokeball.png", 8, 5, 1, 1],
			["int_cloison_h.png", 12, 6, 5, 1], ["int_canape.png", 3, 7, 3, 1],
			["int_table_basse.png", 3, 8, 2, 1], ["int_cloison_v.png", 7, 7, 1, 3],
			["int_cloison_v.png", 10, 7, 1, 3], ["int_porte_manteau.png", 11, 7, 1, 1],
			["int_meuble_chaussures.png", 11, 9, 1, 1], ["int_lavabo.png", 13, 7, 2, 1],
			["int_douche.png", 16, 7, 1, 2], ["int_plante.png", 1, 9, 1, 1],
			["int_plante.png", 6, 9, 1, 1], ["int_plante.png", 15, 9, 1, 1],
		],
		"tapis": [["int_tapis_pokeball.png", 13.5, 4.5]],
		"habitants": [["rival", [Vector2i(13, 4)]],
			["perso_p2", [Vector2i(9, 9), Vector2i(9, 6), Vector2i(4, 6), Vector2i(9, 6)]]],
	},
	"labo": {
		"taille": Vector2i(16, 11), "coque": "int_labo_coque.png", "ouverture": [7, 2],
		"meubles": [
			# Machines, tabouret, escalier et tapis du labo pas encore générés (limite Codex) :
			# classeur et tapis des maisons à la place ; l'escalier décoratif viendra avec le sien.
			["int_aquarium.png", 1, 2, 1, 1], ["int_incubateur.png", 2, 2, 2, 2],
			["int_classeur.png", 4, 2, 1, 1], ["int_bureau_chen.png", 7, 2, 3, 1],
			["int_chaise_bureau.png", 8, 3, 1, 1], ["int_classeur.png", 10, 2, 1, 1],
			["int_etagere_labo.png", 11, 2, 2, 2], ["int_frigo.png", 13, 2, 1, 1],
			["int_vitrine.png", 14, 2, 1, 3], ["int_long_comptoir.png", 1, 5, 5, 1],
			["int_table_starters.png", 11, 4, 3, 2], ["int_canape.png", 1, 6, 3, 1],
			["int_table_basse.png", 3, 7, 2, 1], ["int_paillasse.png", 11, 7, 3, 1],
			["int_plante.png", 6, 8, 1, 1], ["int_plante.png", 4, 9, 1, 1],
			["int_plante.png", 10, 9, 1, 1], ["int_plante.png", 14, 9, 1, 1],
		],
		"tapis": [["int_tapis_salon.png", 3.5, 7.5], ["int_tapis_pokeball.png", 8.0, 6.5]],
		"habitants": [["perso_p2", [Vector2i(7, 9), Vector2i(7, 4), Vector2i(10, 4),
			Vector2i(10, 6), Vector2i(7, 6)]]],
	},
}

var piece := "chambre"


func _ready() -> void:
	var donnees: Dictionary = PIECES[piece]
	var taille: Vector2i = donnees["taille"]
	var coque := Sprite2D.new()
	coque.texture = load(TEX + donnees["coque"])
	coque.centered = false
	coque.scale = Vector2(taille * CASE) / coque.texture.get_size()
	add_child(coque)
	for tapis: Array in donnees["tapis"]:
		var sprite := Sprite2D.new()
		sprite.texture = load(TEX + tapis[0])
		sprite.position = Vector2(tapis[1], tapis[2]) * CASE
		add_child(sprite)
	var ombres := Node2D.new()
	add_child(ombres)
	var tries := Node2D.new()
	tries.y_sort_enabled = true
	add_child(tries)
	# Murs : le fond (2 rangées), les côtés, le bas sauf l'ouverture.
	var ouverture: Array = donnees["ouverture"]
	var bas := taille.y - 1
	var obstacles: Array[Rect2i] = [Rect2i(0, 0, taille.x, 2), Rect2i(0, 0, 1, taille.y),
		Rect2i(taille.x - 1, 0, 1, taille.y), Rect2i(0, bas, ouverture[0], 1),
		Rect2i(ouverture[0] + ouverture[1], bas, taille.x, 1)]
	for meuble: Array in donnees["meubles"]:
		var texture: Texture2D = load(TEX + meuble[0])
		var cases := Rect2i(meuble[1], meuble[2], meuble[3], meuble[4])
		obstacles.append(cases)
		var pied := Vector2(cases.position.x + cases.size.x / 2.0, cases.end.y) * CASE
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
	for habitant: Array in donnees["habitants"]:
		if (habitant[1] as Array).size() == 1:
			obstacles.append(Rect2i(habitant[1][0], Vector2i.ONE))
	var grille: AStarGrid2D = EMPRISES.grille(taille, obstacles)
	for habitant: Array in donnees["habitants"]:
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
	camera.position = Vector2(taille) * CASE / 2.0
	add_child(camera)


func _au_pied(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	return sprite
