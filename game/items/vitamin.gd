class_name Vitamin
extends RefCounted
## Vitamines (lot 32P, AUD-11 et AUD-20 : PV Plus, Protéine, Fer, Carbone, Calcium). Classe
## statique et pure.
##
## Décision de Kevin (2026-10-29, Q1) : **pas d'EV gagnés en combat**, seulement les vitamines.
## Barème des générations 3 à 7 (le moteur calcule les statistiques avec les EV modernes,
## [StatCalc]) : +[constant EV_STEP] EV par prise dans chaque statistique de l'objet
## ([member ItemData.vitamin_stats]), jusqu'à [constant VITAMIN_CAP] par statistique et
## [constant EV_TOTAL_MAX] au total ; les statistiques sont recalculées ([method Pokemon.recalc]).
## Le Calcium monte l'Atq. Spé. **et** la Déf. Spé. (le Spécial unique de Rouge/Bleu) [D].
## Un Pokémon K.O. peut la prendre (Rouge/Bleu) [D]. Les EV sont déjà sauvegardés
## ([method Pokemon.to_dict]) : aucun changement de format. Rien ici ne touche au Sac.

## État d'un Pokémon face à une vitamine : OK, ou plafond atteint (« Sans effet »).
enum Check { OK, NO_EFFECT }

## EV gagnés par prise et par statistique.
const EV_STEP: int = 10
## Plafond des EV qu'une vitamine peut atteindre dans une statistique.
const VITAMIN_CAP: int = 100
## Plafond des EV d'un Pokémon, toutes statistiques comprises.
const EV_TOTAL_MAX: int = 510
## Phrase du résultat, par première statistique de l'objet (« Les PV de Pikachu augmentent. »)
## [D, texte à valider].
const RESULT_FORMATS: Dictionary[StringName, String] = {
	&"hp": "Les PV de %s augmentent.",
	&"atk": "L'Attaque de %s augmente.",
	&"def": "La Défense de %s augmente.",
	&"spa": "Le Spécial de %s augmente.",
	&"spd": "La Défense Spéciale de %s augmente.",
	&"spe": "La Vitesse de %s augmente.",
}


## Vrai si [param item] est une vitamine : UTILISER ouvre le choix du Pokémon.
static func is_vitamin(item: ItemData) -> bool:
	return item != null and item.has_field_use() \
		and item.field_use == ItemData.FIELD_USE_VITAMIN


## Le refus de [ItemUse] qui dit la même chose que [param check] (« Sans effet »).
static func item_use_check(check: Check) -> ItemUse.Check:
	return ItemUse.Check.OK if check == Check.OK else ItemUse.Check.NO_EFFECT


## OK si [param item] fait gagner au moins un EV à [param pokemon].
static func check(pokemon: Pokemon, item: ItemData) -> Check:
	return Check.OK if not gains(pokemon, item).is_empty() else Check.NO_EFFECT


## EV que [param item] ferait gagner à [param pokemon], par statistique (vide : aucun effet).
static func gains(pokemon: Pokemon, item: ItemData) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	if pokemon == null or not is_vitamin(item):
		return result
	var room := EV_TOTAL_MAX - total_evs(pokemon)
	for stat: StringName in item.vitamin_stats:
		var gain := mini(mini(EV_STEP, VITAMIN_CAP - int(pokemon.evs.get(stat, 0))), room)
		if gain > 0:
			result[stat] = gain
			room -= gain
	return result


## Donne la vitamine à [param pokemon] : EV montés, statistiques recalculées. Renvoie les EV
## gagnés (vide : rien n'a changé).
static func apply(pokemon: Pokemon, item: ItemData, data: PokemonData) -> Dictionary[StringName, int]:
	var result := gains(pokemon, item)
	if result.is_empty():
		return result
	for stat: StringName in result:
		pokemon.evs[stat] = int(pokemon.evs.get(stat, 0)) + result[stat]
	if data != null:
		pokemon.recalc(data)
	return result


## Somme des EV de [param pokemon].
static func total_evs(pokemon: Pokemon) -> int:
	var total := 0
	for stat: StringName in pokemon.evs:
		total += pokemon.evs[stat]
	return total


## Phrase du résultat de [param item] sur [param pokemon_name].
static func result_text(item: ItemData, pokemon_name: String) -> String:
	if item == null or item.vitamin_stats.is_empty():
		return ""
	return RESULT_FORMATS.get(item.vitamin_stats[0], "%s") % pokemon_name
