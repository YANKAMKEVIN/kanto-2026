class_name FieldItemRules
extends RefCounted
## Usage en exploration d'un objet AVENTURE (jalon 12, T20 ; `jalon-12.md` §2.6, dossier 15 §11) :
## classe statique et pure (ni scène, ni autoload). Elle dit seulement **si** l'objet peut servir
## ici ; le Sac ([MenuDirector]) affiche le refus, Boot fait le reste (narration, Corde retirée,
## changement de carte).
##
## - **Corde Sortie** ([constant ItemData.FIELD_USE_ESCAPE_ROPE]) : dans une carte de grotte
##   ([CaveLibrary]) seulement ; ailleurs, NOT_HERE (« Impossible de l'utiliser ici. »). Hors
##   combat (catégorie AVENTURE, jamais proposée en combat) et hors cinématique (le menu ne
##   s'ouvre pas pendant une scène) sont tenus par l'existant. Destination :
##   [method escape_target].
## - **Pierre d'évolution** ([constant ItemData.FIELD_USE_EVOLUTION_STONE], T23) : partout en
##   exploration ; le choix du Pokémon (COMPATIBLE / INCOMPATIBLE) est une autre règle (StoneUse).
## - **Super Bonbon** ([constant ItemData.FIELD_USE_RARE_CANDY], jalon 14, T18b) : partout en
##   exploration ; le choix du Pokémon (niveau 100, K.O.) est une autre règle ([RareCandy]).
## - Un objet sans [member ItemData.field_use] (ou absent) : NOT_FIELD_USE (pas de UTILISER).

enum Check { OK, NOT_HERE, NOT_FIELD_USE }


## Peut-on utiliser [param item] sur la carte [param map_id] ? [param caves] : les grottes de
## Kanto (null = aucune grotte connue).
static func check(item: ItemData, map_id: StringName, caves: CaveLibrary) -> Check:
	if item == null or not item.has_field_use():
		return Check.NOT_FIELD_USE
	match item.field_use:
		ItemData.FIELD_USE_ESCAPE_ROPE:
			if caves != null and caves.is_cave(map_id):
				return Check.OK
			return Check.NOT_HERE
		ItemData.FIELD_USE_EVOLUTION_STONE, ItemData.FIELD_USE_RARE_CANDY:
			return Check.OK
	return Check.NOT_FIELD_USE


## Où la Corde Sortie ramène depuis [param map_id] : la sortie de sa grotte (devant l'entrée
## extérieure, tournée vers le sud pour le Mont Sélénite) ; null hors grotte. Depuis n'importe quel
## étage, après l'événement compris : toujours la même entrée (dossier 15 §11, jamais le sas).
## Grotte à deux bouches (jalon 17, Cave Taupiqueur) : la bouche de la moitié où se tient le
## joueur ([param cell], sa case ; [method CaveLibrary.escape_target]).
static func escape_target(map_id: StringName, caves: CaveLibrary,
		cell: Vector2i = CaveLibrary.NO_CELL) -> CaveExit:
	if caves == null:
		return null
	return caves.escape_target(map_id, cell)


## Vrai si [param item] s'utilise sans choisir de Pokémon (la Corde Sortie) : UTILISER agit
## directement, sans le choix du Pokémon.
static func is_targetless(item: ItemData) -> bool:
	return item != null and item.has_field_use() \
		and item.field_use == ItemData.FIELD_USE_ESCAPE_ROPE
