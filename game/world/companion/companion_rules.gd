class_name CompanionRules
extends RefCounted
## Règles du compagnon Pokémon (jalon 11, dossier 14 §8 ; `docs/tech/jalon-11-compagnon.md`
## §2.2 et §2.6) : classe statique et pure (aucune scène, aucun autoload).
##
## - **Éligible** : une espèce du [CompanionCatalog] (planche repos + marche validée).
## - **Visible** : choisi, éligible, pas K.O., carte d'extérieur, hors scène, hors combat, hors
##   transition, et une case lui est attribuée. Le choix ([member GameState.companion_uid]) ne
##   change **jamais** pour une raison de visibilité (A-1).
## - **Choix effacé** dans trois cas seulement : RAPPELER (le menu) ; le Pokémon quitte l'équipe
##   (dépôt, libération) ; il évolue en espèce non éligible (A-11, en silence).
## - **Curiosité** : la phrase dépend seulement de faits visibles, dans cet ordre : PV ≤ 1/3
##   (n° 55), statut (n° 56), eau à 2 cases au plus (n° 59), contexte de la carte (forêt n° 57,
##   ville n° 58 ; grotte, jalon 12, dossier 15 §20 n° 40), sinon une des cinq génériques
##   (n° 50 à 54), jamais deux fois de suite la même (D-8). Le tirage est fourni par l'appelant, **hors** [GameRng] (l'aléatoire du jeu n'est
##   pas touché).

## Phrases de curiosité : identifiants des dialogues (`data/dialogues/companion.json`, T20).
const LINE_TIRED: StringName = &"companion_tired"
const LINE_UNWELL: StringName = &"companion_unwell"
const LINE_WATER: StringName = &"companion_water"
const CONTEXT_LINES: Dictionary[StringName, StringName] = {
	&"forest": &"companion_forest",
	&"city": &"companion_city",
	# Jalon 12 (T20, dossier 15 §20 n° 40) : les étages du Mont Sélénite.
	&"cave": &"companion_cave",
}
const GENERIC_LINES: Array[StringName] = [
	&"companion_happy", &"companion_sniff", &"companion_watch", &"companion_stretch",
	&"companion_stretch_soft",
]
## PV bas : au plus un tiers des PV max.
const LOW_HP_RATIO: float = 1.0 / 3.0
## Distance (en cases, Manhattan) à laquelle l'eau inspire la phrase n° 59.
const WATER_DISTANCE: int = 2

## Raison d'effacer le choix ([method clear_reason]).
enum Clear { KEEP, NOT_IN_PARTY, NOT_ELIGIBLE }


## Ce dont dépend la visibilité (rempli par le contrôleur).
class VisibilityInput:
	extends RefCounted
	## Le Pokémon choisi (null : aucun compagnon).
	var chosen: Pokemon = null
	var map_interior: bool = false
	var in_cutscene: bool = false
	var in_battle: bool = false
	var in_transition: bool = false
	## Une case lui est attribuée ([CompanionTrail]).
	var placed: bool = false


## Vrai si [param pokemon] peut être compagnon (FAIRE SORTIR n'existe que pour lui).
static func is_eligible(pokemon: Pokemon, catalog: CompanionCatalog) -> bool:
	return pokemon != null and catalog != null and catalog.is_eligible_species(pokemon.species_id)


## Vrai si le compagnon doit être montré sur la carte.
static func is_visible(input: VisibilityInput, catalog: CompanionCatalog) -> bool:
	if input == null or not is_eligible(input.chosen, catalog):
		return false
	return not input.chosen.is_fainted() and not input.map_interior and not input.in_cutscene \
		and not input.in_battle and not input.in_transition and input.placed


## Faut-il effacer le choix ? [param chosen] : le Pokémon désigné par l'identifiant du choix,
## cherché dans l'équipe (null s'il n'y est plus). Un K.O. ne l'efface pas.
static func clear_reason(chosen_uid: String, chosen: Pokemon, catalog: CompanionCatalog) -> Clear:
	if chosen_uid.is_empty():
		return Clear.KEEP
	if chosen == null:
		return Clear.NOT_IN_PARTY
	if not is_eligible(chosen, catalog):
		return Clear.NOT_ELIGIBLE
	return Clear.KEEP


## Vrai si les PV de [param pokemon] sont bas (au plus un tiers, et pas K.O.).
static func is_low_hp(pokemon: Pokemon) -> bool:
	var max_hp := pokemon.max_hp()
	return max_hp > 0 and pokemon.hp > 0 and float(pokemon.hp) <= max_hp * LOW_HP_RATIO


## Phrase de curiosité pour [param pokemon] : voir l'en-tête. [param near_water] : de l'eau à
## [constant WATER_DISTANCE] cases au plus ; [param context] : contexte de la carte
## ([method CompanionCatalog.context_of]) ; [param last] : la phrase précédente ;
## [param pick] : `func(n: int) -> int` dans 0..n−1 (tirage hors GameRng).
static func curiosity_line(pokemon: Pokemon, near_water: bool, context: StringName,
		last: StringName, pick: Callable) -> StringName:
	if pokemon != null and is_low_hp(pokemon):
		return LINE_TIRED
	if pokemon != null and pokemon.status != StatusRules.NONE:
		return LINE_UNWELL
	if near_water:
		return LINE_WATER
	if CONTEXT_LINES.has(context):
		return CONTEXT_LINES[context]
	var choices: Array[StringName] = GENERIC_LINES.duplicate()
	choices.erase(last)
	return choices[clampi(int(pick.call(choices.size())), 0, choices.size() - 1)]


## Vrai si une case d'eau de [param water_cells] est à [constant WATER_DISTANCE] cases au plus
## de [param cell] (distance de Manhattan).
static func is_near_water(cell: Vector2i, water_cells: Array[Vector2i]) -> bool:
	for water: Vector2i in water_cells:
		if absi(water.x - cell.x) + absi(water.y - cell.y) <= WATER_DISTANCE:
			return true
	return false
