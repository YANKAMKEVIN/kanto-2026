extends RefCounted
## Forêt serrée du prototype (validée par Kevin, 2026-10-06), commune à la Route 1 et à
## Bourg Palette : sous-bois sombre sous les cases de forêt, arbres de forêt d'environ 3 cases
## (planches `foret_1..8`) espacés de 1,1 case, taille, sens et teinte tirés au hasard ;
## bandes trop étroites garnies de buissons ; les arbres repères restent dégagés.

const CASE := 96
const TEX := "res://proto/da_jadielle/tex/"
const OBJET_SHADER := preload("res://proto/da_jadielle/objet.gdshader")
const CONTACT_SHADER := preload("res://proto/da_jadielle/contact.gdshader")
const SOUS_BOIS := preload("res://proto/da_jadielle/sous_bois.gdshader")


## Calque de sous-bois (à placer au-dessus du sol, sous les décalcomanies).
static func sous_bois(foret: Dictionary, taille: Vector2i) -> ColorRect:
	var image := Image.create(taille.x, taille.y, false, Image.FORMAT_L8)
	for cellule: Vector2i in foret:
		image.set_pixelv(cellule, Color.WHITE)
	var materiau := ShaderMaterial.new()
	materiau.shader = SOUS_BOIS
	materiau.set_shader_parameter(&"masque", ImageTexture.create_from_image(image))
	var rect := ColorRect.new()
	rect.size = Vector2(taille) * CASE
	rect.material = materiau
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Plante la forêt. `buisson` : Callable(nom, position en cases) qui pose un buisson.
static func planter(foret: Dictionary, taille: Vector2i, reperes: Array[Vector2],
		hasard: RandomNumberGenerator, tries: Node2D, ombres: Node2D, buisson: Callable) -> void:
	var poses: Array[Vector2] = []
	for essai in 9000:
		var p := Vector2(hasard.randf_range(0.3, taille.x - 0.3), hasard.randf_range(0.6, taille.y + 1.2))
		var cellule := Vector2i(p)
		var couvert := true
		for dy in range(0, 3):
			var c := cellule + Vector2i(0, -dy)
			if c.y >= 0 and c.y < taille.y and not foret.has(c):
				couvert = false
		if not couvert:
			continue
		var proche := false
		for autre in poses:
			if autre.distance_to(p) < 1.1:
				proche = true
				break
		for repere in reperes:
			if repere.distance_to(p) < 2.0:
				proche = true
		if proche:
			continue
		poses.append(p)
		var texture: Texture2D = load(TEX + "foret_%d.png" % hasard.randi_range(1, 8))
		var sprite := _au_pied(texture)
		sprite.position = p * CASE
		var echelle := hasard.randf_range(0.85, 1.15)
		sprite.scale = Vector2(echelle * (-1.0 if hasard.randf() < 0.5 else 1.0), echelle)
		var v := hasard.randf_range(0.86, 1.08)
		sprite.modulate = Color(v * hasard.randf_range(0.95, 1.03), v, v * hasard.randf_range(0.93, 1.05))
		var materiau := ShaderMaterial.new()
		materiau.shader = OBJET_SHADER
		materiau.set_shader_parameter(&"force_vent", 3.5)
		materiau.set_shader_parameter(&"force_lisere", 1.0)
		sprite.material = materiau
		tries.add_child(sprite)
		var contact := _au_pied(texture)
		var mat_contact := ShaderMaterial.new()
		mat_contact.shader = CONTACT_SHADER
		mat_contact.set_shader_parameter(&"etendue", 18.0)
		mat_contact.set_shader_parameter(&"part_base", 0.05)
		contact.material = mat_contact
		contact.position = p * CASE + Vector2(0, 18)
		contact.scale = sprite.scale  # même taille et même sens que l'arbre
		ombres.add_child(contact)
	poses.append_array(reperes)
	for cellule: Vector2i in foret:
		var centre := Vector2(cellule) + Vector2(0.5, 0.7)
		var garni := false
		for autre in poses:
			if autre.distance_to(centre) < 1.0 or (absf(autre.x - centre.x) < 0.9 \
					and centre.y < autre.y and autre.y - centre.y < 2.4):
				garni = true
				break
		if not garni:
			buisson.call(["buisson_a.png", "buisson_b.png"][hasard.randi_range(0, 1)],
				Vector2(centre.x + hasard.randf_range(-0.15, 0.15), centre.y + 0.25))


static func _au_pied(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	return sprite
