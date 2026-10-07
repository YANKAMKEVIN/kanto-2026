class_name ItemUse
extends RefCounted
## Donner un objet à un Pokémon de l'équipe (jalon-06.md §3.4, Q-10, Q-11). Classe pure,
## statique : **une seule règle** pour le Sac du menu (exploration, fiche Équipe) et pour le
## moteur de combat ([Battle], action [method BattleAction.heal]).
##
## Seuls les soins (catégorie HEAL) se donnent à un Pokémon : les PV remontent jusqu'au maximum
## ([member ItemData.heal_amount]) et / ou un statut est soigné ([member ItemData.cures],
## jalon 9 : l'Antidote). Refusé sur un Pokémon K.O. (Q-11 : aucun objet ne ranime pour
## l'instant) ; sinon, accepté si l'objet change quelque chose (des PV à rendre, ou un statut
## qu'il soigne), refusé sinon : FULL_HP pour un soin de PV, NO_EFFECT pour un soin de statut
## seul. Les raisons affichées sont des textes d'interface, choisis d'après [enum Check] par
## [BagQuery] (jamais ici).
##
## Le moteur de combat ne touche pas au Sac : il appelle [method check_target], puis
## [method restore] et [method cure] ; le BattleDirector retire l'objet une fois, avant de
## soumettre l'action (comme la Ball au 5D). Le menu appelle [method apply], qui fait tout.

## Résultat d'une vérification, du plus général au plus particulier : NOT_USABLE (l'objet ne
## se donne pas à un Pokémon : Ball, objet clé…, objet ou Pokémon absent), WRONG_CONTEXT (pas
## ici : un objet de combat hors combat), NOT_IN_BAG (plus d'exemplaire), FAINTED, puis
## FULL_HP (soin de PV, PV pleins) ou NO_EFFECT (soin de statut seul, le Pokémon n'a pas ce
## statut ; jalon 9, ajouté en fin d'enum).
enum Check { OK, NOT_IN_BAG, WRONG_CONTEXT, FULL_HP, FAINTED, NOT_USABLE, NO_EFFECT }

## Contexte du Sac ouvert depuis la fiche Équipe : l'exploration, pour les règles.
const CONTEXT_TEAM: StringName = &"team"


## Vérifie que [param item] peut être donné à [param pokemon] dans [param context] avec le Sac
## [param bag] (un exemplaire au moins). Rien ne change.
static func check(bag: Bag, item: ItemData, pokemon: Pokemon, context: StringName) -> Check:
	var general := _check_item(item, context)
	if general != Check.OK:
		return general
	if bag == null or not bag.has(item.id):
		return Check.NOT_IN_BAG
	return _check_pokemon(item, pokemon)


## Même règle que [method check], sans le Sac (le moteur de combat ne le connaît pas).
static func check_target(item: ItemData, pokemon: Pokemon, context: StringName) -> Check:
	var general := _check_item(item, context)
	if general != Check.OK:
		return general
	return _check_pokemon(item, pokemon)


## Donne [param item] à [param pokemon] et retire un exemplaire du Sac, seulement si
## [method check] vaut OK ; sinon rien ne change. Le résultat dit ce qui s'est passé.
static func apply(bag: Bag, item: ItemData, pokemon: Pokemon,
		context: StringName) -> ItemUseResult:
	var result := ItemUseResult.new()
	result.check = check(bag, item, pokemon, context)
	result.item_id = item.id if item != null else &""
	if pokemon != null:
		result.hp_before = pokemon.hp
		result.hp_after = pokemon.hp
		result.max_hp = pokemon.max_hp()
	if pokemon != null:
		result.gender = pokemon.gender
	if result.check == Check.OK:
		bag.remove(item.id)
		restore(item, pokemon)
		result.status_cured = cure(item, pokemon)
		result.hp_after = pokemon.hp
	result.remaining = bag.count_of(result.item_id) if bag != null else 0
	return result


## Applique l'effet de [param item] sur [param pokemon], sans vérifier ni toucher au Sac (le
## moteur, après [method check_target]) : PV + [member ItemData.heal_amount], bornés au
## maximum. Renvoie les PV rendus.
static func restore(item: ItemData, pokemon: Pokemon) -> int:
	if item == null or pokemon == null or not item.targets_pokemon():
		return 0
	var before := pokemon.hp
	pokemon.hp = mini(pokemon.hp + item.heal_amount, pokemon.max_hp())
	return pokemon.hp - before


## Soigne le statut de [param pokemon] si [param item] le soigne ([member ItemData.cures]),
## sans vérifier ni toucher au Sac (le moteur, après [method check_target]). Renvoie le statut
## effacé ([constant StatusRules.NONE] : rien n'a changé).
static func cure(item: ItemData, pokemon: Pokemon) -> StringName:
	if item == null or pokemon == null or not item.targets_pokemon() \
			or not item.cures_status(pokemon.status):
		return StatusRules.NONE
	return pokemon.cure_status()


## Contexte des règles : la fiche Équipe est de l'exploration.
static func rule_context(context: StringName) -> StringName:
	return ItemData.CONTEXT_FIELD if context == CONTEXT_TEAM else context


static func _check_item(item: ItemData, context: StringName) -> Check:
	if item == null or not item.targets_pokemon():
		return Check.NOT_USABLE
	if not item.usable_in(rule_context(context)):
		return Check.WRONG_CONTEXT
	return Check.OK


static func _check_pokemon(item: ItemData, pokemon: Pokemon) -> Check:
	if pokemon == null:
		return Check.NOT_USABLE
	if pokemon.is_fainted():
		return Check.FAINTED
	if item.heal_amount > 0 and pokemon.hp < pokemon.max_hp():
		return Check.OK
	if item.cures_status(pokemon.status):
		return Check.OK
	return Check.FULL_HP if item.heal_amount > 0 else Check.NO_EFFECT
