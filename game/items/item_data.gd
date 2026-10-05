class_name ItemData
extends RefCounted
## Un objet du Sac, lu dans `data/items/*.json` par [ItemLibrary] (jalon-04.md §14.6,
## jalon-05.md §2.4). Donnée pure.
##
## Le nom et son accord servent aux textes d'interface : « Poké Balls ×5 » et
## « Ajoutées au Sac » (toast, bible UI §6) sont formés ici, jamais recopiés dans le code
## qui donne l'objet.

## Catégories d'objets (dossier 08 §3, jalon-06.md §3.4), chacune un onglet du Sac. Ajouts en
## fin d'enum : les fichiers et la sauvegarde ne stockent que des identifiants (rien à migrer).
## - BALL (CAPTURE) : se lance en combat sauvage ;
## - HEAL (SOINS) : se donne à un Pokémon de l'équipe, en exploration et en combat ;
## - BATTLE (COMBAT) : en combat seulement (« Utilisable en combat » hors combat) ;
## - FIELD (AVENTURE) : en exploration seulement ;
## - KEY (OBJETS CLÉS) : jamais « utilisé », jamais vendu ni jeté.
enum Category { BALL, HEAL, BATTLE, FIELD, KEY }

## Nom de chaque catégorie dans les fichiers, dans l'ordre de [enum Category].
const CATEGORY_NAMES: Array[String] = ["ball", "heal", "battle", "field", "key"]
## Contextes d'usage (jalon-06.md §3.4) : exploration (menu, fiche Équipe comprise), combat
## sauvage, combat de dresseur. Mêmes valeurs que [constant MenuRoute.BAG_CONTEXT_FIELD] et
## que les contextes de [BagQuery].
const CONTEXT_FIELD: StringName = &"field"
const CONTEXT_WILD_BATTLE: StringName = &"wild_battle"
const CONTEXT_TRAINER_BATTLE: StringName = &"trainer_battle"
## Texte du toast après l'ajout au Sac (bible UI §6 : « Potion ×1 — Ajoutée au Sac »).
const ADDED_BASE := "Ajouté"
const ADDED_SUFFIX := " au Sac"
## Toast d'un objet clé (dossier 09 §19 : « COLIS POUR CHEN — ajouté aux objets clés »).
const KEY_ADDED_BASE := "ajouté"
const KEY_ADDED_SUFFIX := " aux objets clés"

var id: StringName = &""
## Nom au singulier (« Poké Ball ») et au pluriel (« Poké Balls »).
var name: String = ""
var plural: String = ""
## Nom féminin (accord de « Ajoutée »).
var feminine: bool = false
var category: Category = Category.BALL
## Multiplicateur de capture (Poké Ball : 1 ; catégorie BALL seulement).
var catch_bonus: float = 1.0
## PV rendus (catégorie HEAL seulement, > 0 ; la Potion : 20).
var heal_amount: int = 0
## Description (fiche du Sac, jalon 5), texte provisoire tant que [member draft].
var description: String = ""
var draft: bool = false
## Fichier d'origine (messages d'erreur).
var source: String = ""
## Prix d'achat en ₽ (dossier 09 §10, jalon-07.md §3.4) ; 0 = jamais vendu en Boutique ni
## repris. Un objet clé n'a jamais de prix ([ItemLibrary] le refuse).
var price: int = 0
## Rang dans les données (0, 1, 2… dans l'ordre de lecture des fichiers) : ordre « pertinence »
## du Sac hors combat. Posé par [ItemLibrary].
var order: int = 0


## Identifiant de la catégorie dans les fichiers (&"ball", &"heal"…) : onglet du Sac.
func category_id() -> StringName:
	return StringName(CATEGORY_NAMES[category])


## Contextes où l'objet sert (jalon-06.md §3.4), déduits de sa catégorie : un objet clé n'en a
## aucun.
func contexts() -> Array[StringName]:
	match category:
		Category.BALL:
			return [CONTEXT_WILD_BATTLE]
		Category.HEAL:
			return [CONTEXT_FIELD, CONTEXT_WILD_BATTLE, CONTEXT_TRAINER_BATTLE]
		Category.BATTLE:
			return [CONTEXT_WILD_BATTLE, CONTEXT_TRAINER_BATTLE]
		Category.FIELD:
			return [CONTEXT_FIELD]
	return []


## Vrai si l'objet sert dans le contexte [param context] (exploration, combat sauvage, combat
## de dresseur).
func usable_in(context: StringName) -> bool:
	return contexts().has(context)


## Vrai si l'objet se donne à un Pokémon de l'équipe (choix du Pokémon, [ItemUse]) : les soins.
func targets_pokemon() -> bool:
	return category == Category.HEAL and heal_amount > 0


## Nom accordé à [param count] : singulier pour 1, pluriel au-delà.
func name_for(count: int) -> String:
	return name if count <= 1 else plural


## « Poké Balls ×5 », « Poké Ball ×1 » ; un objet clé, unique, n'a que son nom en capitales
## (« COLIS POUR CHEN », dossier 09 §19).
func quantity_text(count: int) -> String:
	if is_key():
		return name.to_upper()
	return "%s ×%d" % [name_for(count), count]


## « Ajoutée au Sac », « Ajoutées au Sac », « Ajouté au Sac »… accordé au genre du nom et à
## [param count] ; un objet clé : « ajouté aux objets clés » (dossier 09 §19).
func added_text(count: int) -> String:
	var agreement := ("e" if feminine else "") + ("s" if count > 1 else "")
	if is_key():
		return KEY_ADDED_BASE + agreement + KEY_ADDED_SUFFIX
	return ADDED_BASE + agreement + ADDED_SUFFIX


## Objet clé (OBJETS CLÉS) : jamais utilisé, vendu ni jeté.
func is_key() -> bool:
	return category == Category.KEY


## Vrai si la Boutique peut reprendre l'objet : il a un prix et ce n'est pas un objet clé.
func is_sellable() -> bool:
	return price > 0 and not is_key()


## Prix de reprise en ₽ : la moitié du prix, arrondie en dessous (Rouge/Bleu) ; 0 si l'objet
## ne se vend pas.
func sell_price() -> int:
	return floori(price / 2.0) if is_sellable() else 0
