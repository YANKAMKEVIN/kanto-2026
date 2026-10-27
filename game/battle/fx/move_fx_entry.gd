class_name MoveFxEntry
extends RefCounted
## Effet d'une attaque, lu dans `data/battle/move_fx/` par [MoveFxCatalog] (chantier Combat
## vivant, `docs/tech/combat-vivant.md` §2.2). Donnée pure.
##
## Format d'une entrée de `moves` :
## [codeblock]
## "thunder_shock": {"family": "electrique", "signature": "eclair"},
## "barrage": {"family": "contact", "impact": "corps", "modifiers": ["multi"]}
## [/codeblock]
## `family` est obligatoire ; `impact` (variante de Contact), `modifiers` et `signature` sont
## facultatifs. Les lots P1 à P4 y ajouteront la chorégraphie propre de l'attaque (CV-1).

var move_id: StringName = &""
## Famille (`families` de `families.json`) : briques communes et plancher.
var family: StringName = &""
## Variante d'impact de la famille Contact ("" : aucune).
var impact: StringName = &""
var modifiers: Array[StringName] = []
## Signature (§3.3, brique neuve) ; "" : aucune.
var signature: StringName = &""
## Fichier d'origine (messages d'erreur ; "" pour une entrée de repli).
var source: String = ""
## Vrai si l'attaque n'a pas d'entrée et que la famille vient de son type et de sa catégorie.
var fallback: bool = false


func has_modifier(modifier: StringName) -> bool:
	return modifiers.has(modifier)
