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
## Onglets ([method categories]) : FAVORIS (si non vide), SOINS, CAPTURE, COMBAT, AVENTURE, CT
## (jalon 11), OBJETS CLÉS ; **un onglet vide n'apparaît pas** (rien d'annoncé d'avance : l'onglet
## CT reste absent tant que le joueur n'a aucune CT, dossier 14 §6.2).
## Tris ([enum Sort]) : pertinence (combat sauvage : Balls puis soins ; ailleurs, l'ordre des
## données), nom, quantité (la plus grande d'abord), récents (obtenus le plus récemment
## d'abord, Q-12 : [method Bag.acquired_rank]).
##
## Textes d'interface validés par Kevin le 2026-10-06 : raisons, mentions, résultat, Sac vide.

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
const CATEGORY_ORDER: Array[StringName] = [&"heal", &"ball", &"battle", &"field", &"tm", &"key"]
## Détail d'une CT (dossier 14 §6.2) : type, puissance, précision, PP, puis la description.
const TM_DETAIL_FORMAT: String = "%s · Puissance %s · Précision %s · PP %d\n%s"
const NO_VALUE: String = "—"
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
	ItemUse.Check.NO_EFFECT: "Sans effet",
	# Jalon 20 (annexe A, n° 166) : un Rappel sur un Pokémon debout.
	ItemUse.Check.NOT_FAINTED: "Pas K.O.",
}
## Phrase de refus quand on touche un Pokémon qui ne peut pas recevoir l'objet.
const REFUSAL_FORMATS: Dictionary[ItemUse.Check, String] = {
	ItemUse.Check.FULL_HP: "%s a déjà tous ses PV.",
	ItemUse.Check.FAINTED: "%s est K.O.",
	ItemUse.Check.NOT_IN_BAG: "Il n'en reste plus.",
	ItemUse.Check.WRONG_CONTEXT: "Pas maintenant.",
	ItemUse.Check.NOT_USABLE: "Cela n'aurait aucun effet sur %s.",
	ItemUse.Check.NO_EFFECT: "Cela n'aurait aucun effet sur %s.",
	# Jalon 20 (annexe A, n° 165) : texte « aucun effet » existant.
	ItemUse.Check.NOT_FAINTED: "Cela n'aurait aucun effet sur %s.",
}
## Résultat d'un soin : « +20 PV — Salamèche 33/51 ».
const RESULT_FORMAT: String = "+%d PV — %s %d/%d"
## Résultat d'un soin de statut sans PV rendus (jalon 9, textes n° 14 et 15 du lot verrouillé
## le 2026-10-07), par statut : masculin, puis féminin (Pokémon femelle).
const STATUS_CURED_FORMATS: Dictionary[StringName, Array] = {
	StatusRules.POISON: ["%s n'est plus empoisonné.", "%s n'est plus empoisonnée."],
	# Jalon 11 (dossier 14 §13, n° 4, 9, 13, 16).
	StatusRules.PARALYSIS: ["%s n'est plus paralysé.", "%s n'est plus paralysée."],
	StatusRules.SLEEP: ["%s est réveillé.", "%s est réveillée."],
	StatusRules.BURN: ["%s n'est plus brûlé.", "%s n'est plus brûlée."],
	StatusRules.FREEZE: ["%s n'est plus gelé !", "%s n'est plus gelée !"],
}
## Résultat d'un Rappel (jalon 20, annexe A, n° 164).
const REVIVED_FORMAT: String = "%s reprend connaissance !"
## Sac sans objet (Q-2) ; depuis la fiche Équipe, aucun objet à donner.
const EMPTY_TEXT: String = "Ton Sac est vide."
const EMPTY_TEAM_TEXT: String = "Aucun soin dans ton Sac."
## Objet AVENTURE refusé ici (jalon 12, dossier 15 §20 n° 34 : la Corde Sortie hors grotte).
const FIELD_REFUSAL_TEXT: String = "Impossible de l'utiliser ici."


## Objets du Sac vus de [param context], triés selon [param sort] : une vue par objet présent
## (un objet inconnu de [param items] est omis, push_error). Depuis la fiche Équipe
## ([constant CONTEXT_TEAM]), seuls les objets qui se donnent à un Pokémon ; si
## [param target] est donné, chacun est utilisable **sur lui** ou porte la raison.
static func entries(bag: Bag, items: ItemLibrary, context: StringName,
		sort: Sort = Sort.RELEVANCE, target: Pokemon = null,
		data: PokemonData = null) -> Array[BagEntryView]:
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
		views.append(_entry(bag, item, context, target, data))
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
## [param money] : l'argent du joueur (« 3 000 ₽ », J7) ; négatif = non affiché.
static func view(bag: Bag, items: ItemLibrary, context: StringName,
		sort: Sort = Sort.RELEVANCE, last_category: StringName = &"", party: Party = null,
		target_index: int = -1, data: PokemonData = null, money: int = -1) -> BagView:
	var result := BagView.new()
	result.context = context
	if money >= 0:
		result.money_text = MenuFormat.money(money)
	result.sort = sort
	result.sort_labels = PackedStringArray(SORT_LABELS)
	var target: Pokemon = null
	if context == CONTEXT_TEAM and party != null:
		target = party.get_at(target_index)
	if target != null:
		result.target_index = target_index
		result.target_name = target.display_name(data) if data != null \
			else String(target.species_id)
	result.entries = entries(bag, items, context, sort, target, data)
	result.favorites = _favorites(result.entries, bag, sort)
	result.categories = categories(result.entries)
	result.start_category = start_category(context, last_category, result.categories)
	if result.entries.is_empty():
		result.empty_text = EMPTY_TEAM_TEXT if context == CONTEXT_TEAM else EMPTY_TEXT
	return result


## Choix du Pokémon pour [param item] (UTILISER) : toute l'équipe, chaque membre utilisable ou
## avec sa raison ([method ItemUse.check], Sac compris) ; une CT ou une pierre d'évolution
## (jalon 12) : la raison toujours visible ([method _stone_targets]) ; un Super Bonbon (jalon 14) :
## [method _candy_targets]. [param selected] : membre
## mis en avant (UTILISER À NOUVEAU), −1 = aucun.
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
	if item != null and item.is_tm():
		picker.permanent = true
		# CT (dossier 14 §6.1) : COMPATIBLE / DÉJÀ CONNUE / INCOMPATIBLE, toujours visibles.
		for i: int in members.size():
			var state := TmTeach.check(members[i], item, data)
			var target_view := PartyTargetView.new(DashboardViews.member(members[i], i, data),
				state == TmTeach.Check.COMPATIBLE, TmTeach.LABELS[state])
			target_view.show_reason = true
			picker.targets.append(target_view)
		return picker
	if StoneUse.is_stone(item):
		_stone_targets(picker, members, item, data)
		return picker
	if RareCandy.is_candy(item):
		_candy_targets(picker, members, bag, item, data)
		return picker
	for i: int in members.size():
		var check := ItemUse.check(bag, item, members[i], context)
		var mon_name := members[i].display_name(data)
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			check == ItemUse.Check.OK, reason_text(check), refusal_text(check, mon_name)))
	return picker


## Phrase de refus pour [param check] sur [param pokemon_name] ; vide pour OK.
static func refusal_text(check: ItemUse.Check, pokemon_name: String) -> String:
	var format: String = REFUSAL_FORMATS.get(check, "")
	return format % pokemon_name if format.contains("%s") else format


## Raison affichée pour [param check] ; vide pour OK.
static func reason_text(check: ItemUse.Check) -> String:
	return REASONS.get(check, "")


## Texte du résultat (UseResultBar) : « +20 PV — Salamèche 33/51 » si l'objet a rendu des PV,
## « Salamèche n'est plus empoisonné. » s'il n'a soigné qu'un statut (accordé au sexe du
## Pokémon), sinon la raison (rien n'a été consommé).
static func result_text(result: ItemUseResult, pokemon_name: String) -> String:
	if result == null:
		return ""
	if not result.is_ok():
		return reason_text(result.check)
	if result.revived:
		return REVIVED_FORMAT % pokemon_name
	if result.amount() == 0 and STATUS_CURED_FORMATS.has(result.status_cured):
		var formats: Array = STATUS_CURED_FORMATS[result.status_cured]
		var female := result.gender == Pokemon.Gender.FEMALE
		return String(formats[1 if female else 0]) % pokemon_name
	return RESULT_FORMAT % [result.amount(), pokemon_name, result.hp_after, result.max_hp]


## UTILISER À NOUVEAU est proposé tant qu'il reste un exemplaire (même s'il serait refusé :
## la raison s'affichera alors, rien ne sera consommé).
static func can_repeat(result: ItemUseResult) -> bool:
	return result != null and result.remaining > 0


## Vue d'un objet : nom au singulier, quantité, catégorie, favori, utilisable ici, mention.
static func _entry(bag: Bag, item: ItemData, context: StringName,
		target: Pokemon, data: PokemonData = null) -> BagEntryView:
	var rules := ItemUse.rule_context(context)
	var view := BagEntryView.new(item.id, item.name, bag.count_of(item.id), item.description,
		item.category_id(), item.usable_in(rules))
	view.favorite = bag.is_favorite(item.id)
	view.targets_pokemon = item.targets_pokemon()
	if StoneUse.is_stone(item) or RareCandy.is_candy(item):
		# Jalon 12 (T23) : UTILISER ouvre le choix du Pokémon (COMPATIBLE / INCOMPATIBLE) ; jalon 14
		# (T18b) : le Super Bonbon aussi (niveau 100, K.O. refusés).
		view.targets_pokemon = true
	if item.is_tm():
		# CT : APPRENDRE ouvre le choix du Pokémon ; hors combat seulement (n° 44) ; permanente,
		# donc sans quantité.
		view.targets_pokemon = true
		view.permanent = true
		view.description = tm_detail(item, data)
		if not view.usable:
			view.note = TmTeach.IN_BATTLE_TEXT
		return view
	if context == CONTEXT_TEAM and target != null:
		var check := ItemUse.check_target(item, target, context)
		view.usable = check == ItemUse.Check.OK
		view.note = reason_text(check)
	elif not view.usable and rules == CONTEXT_FIELD \
			and (item.usable_in(CONTEXT_WILD_BATTLE) or item.usable_in(CONTEXT_TRAINER_BATTLE)):
		view.note = BATTLE_NOTE
	return view


## Détail d'une CT : « Normal · Puissance — · Précision — · PP 10 », puis la description de
## l'objet ; sans données, la description seule.
static func tm_detail(item: ItemData, data: PokemonData) -> String:
	var move := data.get_move(item.teaches) if data != null else null
	if move == null:
		return item.description
	var type_name := data.get_type_chart().get_type_name(move.type)
	var power := str(move.power) if move.power > 0 else NO_VALUE
	var accuracy := ("%d %%" % move.accuracy) if move.accuracy > 0 else NO_VALUE
	return TM_DETAIL_FORMAT % [type_name, power, accuracy, move.pp, item.description]


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


## Refus d'un objet AVENTURE ([method FieldItemRules.check]) : « Impossible de l'utiliser ici. »
## (jalon 12, dossier 15 §20 n° 34) ; vide pour OK.
static func field_refusal_text(check: FieldItemRules.Check) -> String:
	return "" if check == FieldItemRules.Check.OK else FIELD_REFUSAL_TEXT


## Pierre d'évolution (jalon 12, T23 ; `jalon-12.md` §2.9) : chaque membre COMPATIBLE
## (choisissable) ou INCOMPATIBLE (non choisissable), libellé toujours visible
## ([member PartyTargetView.show_reason]) ; un Pokémon K.O. reste COMPATIBLE. La pierre n'est pas
## permanente (la quantité s'affiche).
static func _stone_targets(picker: PartyPickerView, members: Array[Pokemon], item: ItemData,
		data: PokemonData) -> void:
	for i: int in members.size():
		var state := StoneUse.check(members[i], item.id, data)
		var target_view := PartyTargetView.new(DashboardViews.member(members[i], i, data),
			state == StoneUse.Check.COMPATIBLE, StoneUse.LABELS[state])
		target_view.show_reason = true
		picker.targets.append(target_view)


## Super Bonbon (jalon 14, T18b ; `jalon-14.md` §2.6) : chaque membre choisissable si
## [method RareCandy.check] vaut OK ; sinon la raison et la phrase de refus des soins (« Sans
## effet » au niveau 100, « Ce Pokémon est K.O. » ; plus de bonbon : « Il n'en reste plus »), rien
## n'est consommé.
static func _candy_targets(picker: PartyPickerView, members: Array[Pokemon], bag: Bag,
		item: ItemData, data: PokemonData) -> void:
	var in_bag := bag != null and bag.has(item.id)
	for i: int in members.size():
		var check := RareCandy.item_use_check(RareCandy.check(members[i])) if in_bag \
			else ItemUse.Check.NOT_IN_BAG
		var mon_name := members[i].display_name(data)
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			check == ItemUse.Check.OK, reason_text(check), refusal_text(check, mon_name)))
