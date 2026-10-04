class_name BattleViews
extends RefCounted
## Traduit l'état du combat en vues de l'interface ([BattleCardView], [BattleMoveView]) :
## des chaînes et des entiers, pour que les composants de `game/ui/battle/` ne connaissent
## ni le moteur ni les données (jalon-04.md §3.8, §14.2). Classe pure, statique.

## Actions de la grille disponibles au premier combat (décision de Kevin n° 12) : ATTAQUER
## seulement ; SAC, ÉQUIPE et FUITE restent visibles mais atténués (pas d'objet utilisable
## contre un dresseur, pas de changement de Pokémon, pas de fuite contre un dresseur).
## Clés : ActionGrid.ACTIONS.
const TRAINER_BATTLE_ACTIONS: Dictionary[StringName, bool] = {&"attack": true}

## Actions de la grille disponibles contre un Pokémon sauvage (jalons 5B et 5D) : ATTAQUER, SAC
## (lancer une Ball) et FUITE ; ÉQUIPE reste atténué (pas de changement de Pokémon au jalon 5).
## Clés : ActionGrid.ACTIONS.
const WILD_BATTLE_ACTIONS: Dictionary[StringName, bool] = {
	&"attack": true, &"bag": true, &"run": true,
}

## Carte d'information du Pokémon envoyé par [param event] (SENT_OUT) : nom, sexe, niveau,
## PV ; PV chiffrés du côté du joueur seulement (dossier 05 §5).
static func card(event: BattleEvent) -> BattleCardView:
	return BattleCardView.new(event.pokemon_name, card_gender(event.gender), event.level,
		event.hp, event.max_hp, event.side == BattleEvent.SideId.PLAYER)


## Sexe du modèle Pokémon → sexe affiché par la carte.
static func card_gender(gender: Pokemon.Gender) -> BattleCardView.Gender:
	match gender:
		Pokemon.Gender.MALE:
			return BattleCardView.Gender.MALE
		Pokemon.Gender.FEMALE:
			return BattleCardView.Gender.FEMALE
	return BattleCardView.Gender.NONE


## Cartes des capacités de [param pokemon], dans l'ordre de ses emplacements (1 à 4) :
## nom, type (identifiant et nom affiché), catégorie, PP restants et max, puissance,
## précision, description. Une capacité inconnue des données est omise (push_error).
static func moves(pokemon: Pokemon, data: PokemonData) -> Array[BattleMoveView]:
	var views: Array[BattleMoveView] = []
	var chart := data.get_type_chart()
	for slot: MoveSlot in pokemon.moves:
		var move := data.get_move(slot.move_id)
		if move == null:
			push_error("BattleViews : capacité inconnue « %s »" % slot.move_id)
			continue
		views.append(BattleMoveView.new(move.name, move.type, chart.get_type_name(move.type),
			move_category(move.category), slot.pp, slot.max_pp, move.power, move.accuracy,
			move.description))
	return views


## Carte de la capacité [param move_id] proposée à l'apprentissage (panneau d'oubli, jalon
## 5C) : PP pleins (elle n'a jamais servi). Null si la capacité est inconnue des données.
static func offered_move(move_id: StringName, data: PokemonData) -> BattleMoveView:
	var move := data.get_move(move_id)
	if move == null:
		push_error("BattleViews : capacité inconnue « %s »" % move_id)
		return null
	return BattleMoveView.new(move.name, move.type,
		data.get_type_chart().get_type_name(move.type), move_category(move.category),
		move.pp, move.pp, move.power, move.accuracy, move.description)


## Catégorie du modèle → catégorie affichée par la fiche.
static func move_category(category: MoveData.Category) -> BattleMoveView.Category:
	match category:
		MoveData.Category.SPECIAL:
			return BattleMoveView.Category.SPECIAL
		MoveData.Category.STATUS:
			return BattleMoveView.Category.STATUS
	return BattleMoveView.Category.PHYSICAL


## Objets du Sac de combat sauvage ([BagEntryView]) : enveloppe de [method BagQuery.entries]
## (contexte combat sauvage, pertinence : Balls puis soins). Un objet inconnu de [param items]
## est omis (push_error). Nom au singulier, catégorie en identifiant des données ;
## [member BagEntryView.usable] selon les règles des données (Balls et soins).
static func bag_entries(bag: Bag, items: ItemLibrary) -> Array[BagEntryView]:
	return BagQuery.entries(bag, items, BagQuery.CONTEXT_WILD_BATTLE)
