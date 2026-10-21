class_name Dialogue
extends RefCounted
## Dialogue d'un PNJ, texte d'un objet examiné ou d'un Pokémon observé.
##
## Donnée pure, construite par [DialogueLibrary]. [method pick] renvoie la **première**
## variante qui s'applique aux drapeaux d'histoire : on écrit les cas particuliers d'abord,
## le cas général (sans condition) en dernier (docs/tech/jalon-03.md §2.4).

var id: StringName = &""
## Nom affiché dans l'étiquette (« Maman », « Maya », « Bulbizarre ») ; vide = pas
## d'étiquette (objets examinés).
var speaker: String = ""
## Texte de narration (examiner, observer) : style distinct de la parole (italique).
var narration: bool = false
## Texte provisoire, à remplacer par un texte de Kevin (sans effet en jeu).
var draft: bool = false
## Fichier d'origine (messages d'erreur).
var source: String = ""
var variants: Array[DialogueVariant] = []


## Première variante qui s'applique à [param flags], ou null si aucune.
## Variante à tirage ([member DialogueVariant.one_in], jalon 14) : ses drapeaux d'abord, puis
## un tirage de [param rng] (1 sur N) ; perdu, on passe à la suivante. Sans [param rng], une
## telle variante est sautée sans tirage (tests déterministes, simple consultation).
## [param caught] : espèces capturées au Pokédex, pour les variantes « if_caught_at_least » /
## « unless_caught_at_least » (jalon 17) ; 0 par défaut.
## Variante de capacité de terrain ([member DialogueVariant.field], jalon 16) : elle ne
## s'applique que si [param field] (`func(move: StringName) -> FieldMoves.Result`) rend cet état ;
## sans [param field], elle est sautée.
func pick(flags: StoryFlags, rng: GameRng = null, caught: int = 0,
		field: Callable = Callable(), has_item: Callable = Callable(),
		zone_playable: Callable = Callable()) -> DialogueVariant:
	for variant: DialogueVariant in variants:
		if not variant.matches(flags, caught):
			continue
		if not _items_match(variant, has_item):
			continue
		if not variant.if_zone.is_empty() \
				and not (zone_playable.is_valid() and bool(zone_playable.call(variant.if_zone))):
			continue
		if not variant.field.is_empty() and not _field_matches(variant.field, field):
			continue
		if variant.is_random() and (rng == null or rng.roll(variant.one_in) != 1):
			continue
		return variant
	return null


## « if_items » / « unless_items » (jalon 20) lus par [param has_item] (`func(id) -> bool`, le
## Sac) ; sans source, une variante qui demande un objet ne s'applique pas.
static func _items_match(variant: DialogueVariant, has_item: Callable) -> bool:
	if variant.if_items.is_empty() and variant.unless_items.is_empty():
		return true
	if not has_item.is_valid():
		return variant.if_items.is_empty()
	for id: StringName in variant.if_items:
		if not bool(has_item.call(id)):
			return false
	for id: StringName in variant.unless_items:
		if bool(has_item.call(id)):
			return false
	return true


static func _field_matches(key: String, field: Callable) -> bool:
	if not field.is_valid():
		return false
	var move := StringName(key.get_slice(":", 0))
	var result: Variant = field.call(move)
	return result is FieldMoves.Result and (result as FieldMoves.Result).key(move) == key
