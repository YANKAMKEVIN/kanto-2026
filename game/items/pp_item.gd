class_name PpItem
extends RefCounted
## PP Plus, Éther, Max Éther, Élixir, Max Élixir (lot 32P, AUD-12, AUD-13, AUD-20). Classe statique
## et pure ; exploration seulement [D].
##
## - **PP Plus** ([constant ItemData.FIELD_USE_PP_UP]) : une capacité choisie gagne un cinquième
##   de ses PP de base (au moins 1), trois fois au plus (Rouge/Bleu) ; les PP courants montent
##   d'autant. Les PP max sont déjà sauvegardés ([method MoveSlot.to_dict]) : aucun changement
##   de format.
## - **Éther / Élixir** ([constant ItemData.FIELD_USE_PP_RESTORE]) : [member ItemData.pp_amount] PP
##   rendus (0 = tous) à une capacité choisie, ou à toutes ([member ItemData.pp_all_moves]).
## Un Pokémon K.O. peut les recevoir (Rouge/Bleu) [D]. Rien ici ne touche au Sac.

## État d'un Pokémon (ou d'une capacité) face à l'objet : OK, ou rien à faire (« Sans effet »).
enum Check { OK, NO_EFFECT }

## Nombre maximal de PP Plus par capacité.
const MAX_UPS: int = 3
## Phrases du résultat [D, textes à valider] : capacité (PP Plus, Éther) ou Pokémon (Élixir).
const PP_UP_FORMAT := "Les PP de %s augmentent."
const RESTORE_FORMAT := "Les PP de %s sont restaurés."


## Vrai si [param item] est un PP Plus, un Éther ou un Élixir.
static func is_pp_item(item: ItemData) -> bool:
	return item != null and item.has_field_use() and (item.field_use == ItemData.FIELD_USE_PP_UP
		or item.field_use == ItemData.FIELD_USE_PP_RESTORE)


## Vrai si l'objet agit sur une seule capacité, à choisir après le Pokémon (PP Plus, Éthers).
static func needs_move(item: ItemData) -> bool:
	return is_pp_item(item) and not item.pp_all_moves


## Le refus de [ItemUse] qui dit la même chose que [param check] (« Sans effet »).
static func item_use_check(check: Check) -> ItemUse.Check:
	return ItemUse.Check.OK if check == Check.OK else ItemUse.Check.NO_EFFECT


## OK si [param item] change quelque chose à au moins une capacité de [param pokemon].
static func check(pokemon: Pokemon, item: ItemData, data: PokemonData) -> Check:
	if pokemon == null or not is_pp_item(item):
		return Check.NO_EFFECT
	for i: int in pokemon.moves.size():
		if check_move(pokemon, i, item, data) == Check.OK:
			return Check.OK
	return Check.NO_EFFECT


## OK si [param item] change quelque chose à la capacité [param slot] de [param pokemon].
static func check_move(pokemon: Pokemon, slot: int, item: ItemData, data: PokemonData) -> Check:
	if pokemon == null or not is_pp_item(item) or slot < 0 or slot >= pokemon.moves.size():
		return Check.NO_EFFECT
	var move := pokemon.moves[slot]
	if item.field_use == ItemData.FIELD_USE_PP_UP:
		return Check.OK if move.max_pp < cap(move, data) else Check.NO_EFFECT
	return Check.OK if move.pp < move.max_pp else Check.NO_EFFECT


## Applique [param item] : sur la capacité [param slot] (PP Plus, Éther), ou sur toutes (Élixir,
## [param slot] ignoré). Renvoie les PP gagnés ou rendus (0 : rien n'a changé).
static func apply(pokemon: Pokemon, slot: int, item: ItemData, data: PokemonData) -> int:
	if check(pokemon, item, data) != Check.OK:
		return 0
	if item.field_use == ItemData.FIELD_USE_PP_UP:
		if check_move(pokemon, slot, item, data) != Check.OK:
			return 0
		var move := pokemon.moves[slot]
		var gain := mini(step(move, data), cap(move, data) - move.max_pp)
		move.max_pp += gain
		move.pp += gain
		return gain
	var slots: Array[int] = []
	if item.pp_all_moves:
		slots.assign(range(pokemon.moves.size()))
	elif check_move(pokemon, slot, item, data) == Check.OK:
		slots.append(slot)
	var restored := 0
	for i: int in slots:
		var move := pokemon.moves[i]
		var after := move.max_pp if item.pp_amount <= 0 \
			else mini(move.pp + item.pp_amount, move.max_pp)
		restored += after - move.pp
		move.pp = after
	return restored


## PP de base de la capacité (données), ou ses PP max actuels si elle est inconnue.
static func base_pp(move: MoveSlot, data: PokemonData) -> int:
	var move_data := data.get_move(move.move_id) if data != null else null
	return move_data.pp if move_data != null and move_data.pp > 0 else move.max_pp


## PP gagnés par un PP Plus : un cinquième des PP de base, au moins 1.
@warning_ignore("integer_division")
static func step(move: MoveSlot, data: PokemonData) -> int:
	return maxi(1, base_pp(move, data) / 5)


## PP max après trois PP Plus.
static func cap(move: MoveSlot, data: PokemonData) -> int:
	return base_pp(move, data) + MAX_UPS * step(move, data)


## Phrase du résultat : [param target_name] = capacité (PP Plus, Éther) ou Pokémon (Élixir).
static func result_text(item: ItemData, target_name: String) -> String:
	if item != null and item.field_use == ItemData.FIELD_USE_PP_UP:
		return PP_UP_FORMAT % target_name
	return RESTORE_FORMAT % target_name
