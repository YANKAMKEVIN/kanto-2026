class_name PokemonVariant
extends RefCounted
## Variantes de couleur uniques (Chapitre Johto, JOH6, arbitrage JH-46 : le **Léviator rouge** du
## Lac Colère ; `docs/tech/jalon-joh6.md` §2.6). **Pas de système de chromatiques** : une variante
## n'existe que sur un Pokémon donné par une rencontre fixe (clé « variant » de l'étape de scène
## « wild_battle »). Au Pokédex, le Pokémon compte comme son espèce.
##
## Rendu provisoire [D] : rotation de teinte de l'image de combat ([method material_for]) ; la
## planche repeinte et l'artwork recoloré viendront avec l'art (cadre §9).

## Variantes connues → rotation de teinte (en tours : 0,42 ≈ 150°, le bleu du Léviator devient
## rouge).
const HUE_SHIFTS: Dictionary[StringName, float] = {&"red": 0.42}
const SHADER: Shader = preload("res://game/pokemon/pokemon_variant_hue.gdshader")


## Vrai si [param variant] est une variante connue (vide = forme normale : faux).
static func is_known(variant: StringName) -> bool:
	return HUE_SHIFTS.has(variant)


## Matériau de teinte de [param variant] pour une image de Pokémon ; null pour la forme normale
## ou une variante inconnue.
static func material_for(variant: StringName) -> ShaderMaterial:
	if not is_known(variant):
		return null
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"hue_shift", HUE_SHIFTS[variant])
	return material
