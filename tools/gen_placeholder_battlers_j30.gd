extends SceneTree
## Sprites de combat provisoires des espèces nouvelles du jalon 30 (Ligue) : recoloration d'un
## sprite provisoire existant d'une forme proche (comme `gen_placeholder_battlers.gd` au J29),
## dans un script à part pour ne pas toucher le générateur commun (fusion avec les J21 à J29).
## Kicklee et Tygnon : sprites du J27 repris à l'identique. Le peint en combat viendra à la
## phase DA.
##
##   godot --headless --path . -s res://tools/gen_placeholder_battlers_j30.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/pokemon/placeholder/"
## Espèce → [base, décalage de teinte, saturation, assombrissement].
const RECOLORS := {
	"gengar": ["haunter", -0.04, 1.1, 0.2],  # Ectoplasma : Spectrum plus sombre
	"jynx": ["jigglypuff", 0.6, 1.2, 0.0],  # Lippoutou : Rondoudou violet
	"machamp": ["machop", 0.08, 1.0, 0.25],  # Mackogneur : Machoc gris-bleu sombre
	"dragonair": ["gyarados", 0.02, 0.6, 0.0],  # Draco : Léviator bleu pâle
	"dragonite": ["charizard", 0.03, 0.8, 0.0],  # Dracolosse : Dracaufeu orangé
}


func _init() -> void:
	for species: String in RECOLORS:
		var row: Array = RECOLORS[species]
		for side: String in ["front", "back"]:
			var img := Image.load_from_file(ProjectSettings.globalize_path(
				"%s%s_%s.png" % [DIR, row[0], side]))
			img.convert(Image.FORMAT_RGBA8)
			for y: int in img.get_height():
				for x: int in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a <= 0.0 or c.s < 0.15:
						continue
					var shifted := Color.from_hsv(fposmod(c.h + float(row[1]), 1.0),
						clampf(c.s * float(row[2]), 0.0, 1.0), c.v, c.a)
					img.set_pixel(x, y, shifted.darkened(float(row[3])))
			img.save_png(ProjectSettings.globalize_path("%s%s_%s.png" % [DIR, species, side]))
	quit()
