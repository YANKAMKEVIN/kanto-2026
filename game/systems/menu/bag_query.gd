class_name BagQuery
extends RefCounted
## Le Sac vu d'un contexte (dossier 08 §3, jalon-06.md §3.4) : quels objets, sous quel onglet,
## dans quel ordre, utilisables ou non, et sur quel Pokémon. Classe pure, statique : **un seul
## Sac** ([code]GameState.bag[/code]) et une seule règle ([ItemUse]) pour l'exploration, la
## fiche Équipe et le combat (le Sac du combat, [method BattleViews.bag_entries], en est une
## enveloppe).
##
## Contextes : [constant CONTEXT_FIELD] (menu en exploration), [constant CONTEXT_TEAM] (depuis
## la fiche Équipe : les objets qui se donnent à un Pokémon, SOINS d'abord),
## [constant CONTEXT_WILD_BATTLE], [constant CONTEXT_TRAINER_BATTLE].
## Onglets ([method categories]) : FAVORIS (si non vide), SOINS, CAPTURE, COMBAT, AVENTURE,
## OBJETS CLÉS ; **un onglet vide n'apparaît pas** (rien d'annoncé d'avance).
## Tris ([enum Sort]) : pertinence (combat sauvage : Balls puis soins ; ailleurs, l'ordre des
## données), nom, quantité (la plus grande d'abord), récents (obtenus le plus récemment
## d'abord, Q-12 : [method Bag.acquired_rank]).
##
## Textes d'interface provisoires (règle 4) : raisons, mentions, résultat, Sac vide.

enum Sort { RELEVANCE, NAME, QUANTITY, RECENT }

## Mêmes valeurs que [constant MenuRoute.BAG_CONTEXT_FIELD] et
## [constant MenuRoute.BAG_CONTEXT_TEAM].
const CONTEXT_FIELD: StringName = ItemData.CONTEXT_FIELD
const CONTEXT_TEAM: StringName = ItemUse.CONTEXT_TEAM
const CONTEXT_WILD_BATTLE: StringName = ItemData.CONTEXT_WILD_BATTLE
const CONTEXT_TRAINER_BATTLE: StringName = ItemData.CONTEXT_TRAINER_BATTLE
## Onglet des favoris (pas une catégorie de données).
const FAVORITES: StringName = &"favorites"
## Ordre des onglets après FAVORIS (identifiants de [constant ItemData.CATEGORY_NAMES]).
const CATEGORY_ORDER: Array[StringName] = [&"heal", &"ball", &"battle", &"field", &"key"]
## Noms des tris, dans l'ordre de [enum Sort].
const SORT_LABELS: Array[String] = ["Pertinence", "Nom", "Quantité", "Récents"]
## Mention d'un objet de combat consulté hors combat (dossier 08 §3).
const BATTLE_NOTE: String = "Utilisable en combat"
## Raison affichée pour chaque refus d'[ItemUse] (Q-11 : « Ce Pokémon est K.O. »).
const REASONS: Dictionary[ItemUse.Check, String] = {
	ItemUse.Check.FULL_HP: "PV déjà au maximum",
	ItemUse.Check.FAINTED: "Ce Pokémon est K.O.",
	ItemUse.Check.NOT_IN_BAG: "Il n'en reste plus",
	ItemUse.Check.WRONG_CONTEXT: "Pas maintenant",
	ItemUse.Check.NOT_USABLE: "Sans effet",
}
## Résultat d'un soin : « +20 PV — Salamèche 33/51 ».
const RESULT_FORMAT: String = "+%d PV — %s %d/%d"
## Sac sans objet (Q-2) ; depuis la fiche Équipe, aucun objet à donner.
const EMPTY_TEXT: String = "Ton Sac est vide."
const EMPTY_TEAM_TEXT: String = "Aucun soin dans ton Sac."


## Objets du Sac vus de [param context], triés selon [param sort] : une vue par objet présent
## (un objet inconnu de [param items] est omis, push_error). Depuis la fiche Équipe
## ([constant CONTEXT_TEAM]), seuls les objets qui se donnent à un Pokémon ; si
## [param target] est donné, chacun est utilisable **sur lui** ou porte la raison.
static func entries(bag: Bag, items: ItemLibrary, context: StringName,
		sort: Sort = Sort.RELEVANCE, target: Pokemon = null) -> Array[BagEntryView]:
	var views: Array[BagEntryView] = []
	if bag == null or items == null:
		return views
	var found: Array[ItemData] = []
	for id: StringName in bag.get_ids():
		var item := items.get_item(id)
		if item == null:
			push_error("BagQuery : objet inconnu « %s »" % id)
			continue
		if context == CONTEXT_TEAM and not _gives_to_pokemon(item):
			continue
		found.append(item)
	found.sort_custom(_comparator(bag, context, sort))
	for item: ItemData in found:
		views.append(_entry(bag, item, context, target))
	return views


## Onglets de [param views], dans l'ordre : FAVORIS si un objet est favori, puis les
## catégories qui ont au moins un objet.
static func categories(views: Array[BagEntryView]) -> Array[StringName]:
	var present: Dictionary[StringName, bool] = {}
	var has_favorite := false
	for view: BagEntryView in views:
		present[view.category_id] = true
		has_favorite = has_favorite or view.favorite
	var result: Array[StringName] = []
	if has_favorite:
		result.append(FAVORITES)
	for category: StringName in CATEGORY_ORDER:
		if present.has(category):
			result.append(category)
	return result


## Onglet d'ouverture (dossier 08 §3) : combat sauvage → CAPTURE ; combat de dresseur et fiche
## Équipe → SOINS ; exploration → [param last] (le dernier ouvert pendant la session). Si cet
## onglet n'est pas dans [param available], le premier ; &"" si aucun.
static func start_category(context: StringName, last: StringName,
		available: Array[StringName]) -> StringName:
	var wanted := last
	match context:
		CONTEXT_WILD_BATTLE:
			wanted = &"ball"
		CONTEXT_TRAINER_BATTLE, CONTEXT_TEAM:
			wanted = &"heal"
	if available.has(wanted):
		return wanted
	return available[0] if not available.is_empty() else &""


## Vue de l'écran Sac du menu. [param party], [param target_index] et [param data] : le
## Pokémon visé depuis la fiche Équipe ([constant CONTEXT_TEAM]) ; sinon null / −1.
static func view(bag: Bag, items: ItemLibrary, context: StringName,
		sort: Sort = Sort.RELEVANCE, last_category: StringName = &"", party: Party = null,
		target_index: int = -1, data: PokemonData = null) -> BagView:
	var result := BagView.new()
	result.context = context
	result.sort = sort
	result.sort_labels = PackedStringArray(SORT_LABELS)
	var target: Pokemon = null
	if context == CONTEXT_TEAM and party != null:
		target = party.get_at(target_index)
	if target != null:
		result.target_index = target_index
		result.target_name = target.display_name(data) if data != null \
			else String(target.species_id)
	result.entries = entries(bag, items, context, sort, target)
	result.favorites = _favorites(result.entries, bag, sort)
	result.categories = categories(result.entries)
	result.start_category = start_category(context, last_category, result.categories)
	if result.entries.is_empty():
		result.empty_text = EMPTY_TEAM_TEXT if context == CONTEXT_TEAM else EMPTY_TEXT
	return result


## Choix du Pokémon pour [param item] (UTILISER) : toute l'équipe, chaque membre utilisable ou
## avec sa raison ([method ItemUse.check], Sac compris). [param selected] : membre mis en avant
## (UTILISER À NOUVEAU), −1 = aucun.
static func targets(party: Party, bag: Bag, item: ItemData, context: StringName,
		data: PokemonData, selected: int = -1) -> PartyPickerView:
	var picker := PartyPickerView.new()
	if item != null:
		picker.item_id = item.id
		picker.item_name = item.name
		picker.quantity = bag.count_of(item.id) if bag != null else 0
	picker.selected = selected
	if party == null:
		return picker
	var members := party.get_all()
	for i: int in members.size():
		var check := ItemUse.check(bag, item, members[i], context)
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			check == ItemUse.Check.OK, reason_text(check)))
	return picker


## Raison affichée pour [param check] ; vide pour OK.
static func reason_text(check: ItemUse.Check) -> String:
	return REASONS.get(check, "")


## Texte du résultat (UseResultBar) : « +20 PV — Salamèche 33/51 » si l'objet a servi, sinon
## la raison (rien n'a été consommé).
static func result_text(result: ItemUseResult, pokemon_name: String) -> String:
	if result == null:
		return ""
	if not result.is_ok():
		return reason_text(result.check)
	return RESULT_FORMAT % [result.amount(), pokemon_name, result.hp_after, result.max_hp]


## UTILISER À NOUVEAU est proposé tant qu'il reste un exemplaire (même s'il serait refusé :
## la raison s'affichera alors, rien ne sera consommé).
static func can_repeat(result: ItemUseResult) -> bool:
	return result != null and result.remaining > 0


## Vue d'un objet : nom au singulier, quantité, catégorie, favori, utilisable ici, mention.
static func _entry(bag: Bag, item: ItemData, context: StringName,
		target: Pokemon) -> BagEntryView:
	var rules := ItemUse.rule_context(context)
	var view := BagEntryView.new(item.id, item.name, bag.count_of(item.id), item.description,
		item.category_id(), item.usable_in(rules))
	view.favorite = bag.is_favorite(item.id)
	view.targets_pokemon = item.targets_pokemon()
	if context == CONTEXT_TEAM and target != null:
		var check := ItemUse.check_target(item, target, context)
		view.usable = check == ItemUse.Check.OK
		view.note = reason_text(check)
	elif not view.usable and rules == CONTEXT_FIELD \
			and (item.usable_in(CONTEXT_WILD_BATTLE) or item.usable_in(CONTEXT_TRAINER_BATTLE)):
		view.note = BATTLE_NOTE
	return view


## Vrai si [param item] se donne à un Pokémon en exploration (fiche Équipe).
static func _gives_to_pokemon(item: ItemData) -> bool:
	return item.targets_pokemon() and item.usable_in(CONTEXT_FIELD)


## Favoris présents dans [param views] : en « pertinence », dans l'ordre de marquage ; sinon
## dans l'ordre du tri.
static func _favorites(views: Array[BagEntryView], bag: Bag, sort: Sort) -> Array[BagEntryView]:
	var result: Array[BagEntryView] = []
	if sort == Sort.RELEVANCE:
		for id: StringName in bag.favorite_ids():
			for view: BagEntryView in views:
				if view.item_id == id:
					result.append(view)
		return result
	for view: BagEntryView in views:
		if view.favorite:
			result.append(view)
	return result


static func _comparator(bag: Bag, context: StringName, sort: Sort) -> Callable:
	var relevance := func(a: ItemData, b: ItemData) -> bool:
		var rank_a := _relevance_rank(a, context)
		var rank_b := _relevance_rank(b, context)
		return rank_a < rank_b if rank_a != rank_b else a.order < b.order
	match sort:
		Sort.NAME:
			return func(a: ItemData, b: ItemData) -> bool:
				var compared := a.name.naturalnocasecmp_to(b.name)
				return compared < 0 if compared != 0 else relevance.call(a, b)
		Sort.QUANTITY:
			return func(a: ItemData, b: ItemData) -> bool:
				var count_a := bag.count_of(a.id)
				var count_b := bag.count_of(b.id)
				return count_a > count_b if count_a != count_b else relevance.call(a, b)
		Sort.RECENT:
			return func(a: ItemData, b: ItemData) -> bool:
				var rank_a := bag.acquired_rank(a.id)
				var rank_b := bag.acquired_rank(b.id)
				return rank_a > rank_b if rank_a != rank_b else relevance.call(a, b)
	return relevance


## Combat sauvage : les Balls, puis les soins, puis le reste (dossier 08 §3, « mis en avant ») ;
## ailleurs, l'ordre des données seul.
static func _relevance_rank(item: ItemData, context: StringName) -> int:
	if context != CONTEXT_WILD_BATTLE:
		return 0
	match item.category:
		ItemData.Category.BALL:
			return 0
		ItemData.Category.HEAL:
			return 1
	return 2
