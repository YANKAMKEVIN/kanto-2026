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
## - FIELD (AVENTURE) : en exploration seulement, **et seulement s'il a un usage**
##   ([member field_use]) : sans usage (la Pépite, jalon 13 §2.13), aucun contexte, donc pas de
##   bouton UTILISER ;
## - KEY (OBJETS CLÉS) : jamais « utilisé », jamais vendu ni jeté ;
## - TM (CT, jalon 11, dossier 14 §6) : enseigne [member teaches] à un Pokémon compatible, hors
##   combat seulement ; **permanente** (jamais consommée, une seule dans le Sac) ; jamais vendue.
enum Category { BALL, HEAL, BATTLE, FIELD, KEY, TM }

## Nom de chaque catégorie dans les fichiers, dans l'ordre de [enum Category].
const CATEGORY_NAMES: Array[String] = ["ball", "heal", "battle", "field", "key", "tm"]
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
## Toast d'une CT (dossier 14 §13, n° 40 : « CT34 — Patience obtenue »).
const TM_ADDED_BASE := "obtenu"
## Usages d'un objet AVENTURE (jalon 12, T20 ; [member field_use]) : la Corde Sortie (sans cible,
## [FieldItemRules]) et la pierre d'évolution (un Pokémon cible, T23) ; jalon 14 (T18b) : le
## Super Bonbon (un Pokémon cible, [RareCandy]). Ajouts en fin.
const FIELD_USE_ESCAPE_ROPE: StringName = &"escape_rope"
const FIELD_USE_EVOLUTION_STONE: StringName = &"evolution_stone"
const FIELD_USE_RARE_CANDY: StringName = &"rare_candy"
const FIELD_USES: Array[StringName] = [FIELD_USE_ESCAPE_ROPE, FIELD_USE_EVOLUTION_STONE,
	FIELD_USE_RARE_CANDY]
## Usages en combat d'un objet COMBAT (jalon 20, `jalon-20.md` §2.9.3 ; [member battle_use]) :
## un étage de statistique (objets X), la Puissance (Muscle +), la fuite garantie (Poupée Poké,
## combat sauvage seulement). Ajouts en fin.
const BATTLE_USE_STAT_STAGE: StringName = &"stat_stage"
const BATTLE_USE_CRIT_UP: StringName = &"crit_up"
const BATTLE_USE_ESCAPE: StringName = &"escape"
const BATTLE_USES: Array[StringName] = [BATTLE_USE_STAT_STAGE, BATTLE_USE_CRIT_UP,
	BATTLE_USE_ESCAPE]
## Usages d'un objet clé (passe systèmes 2, `systemes-2.md` §2.4 ; [member key_use]) : la Poké
## Flûte (exploration et combat), la Bicyclette (exploration), les trois cannes (exploration,
## pêche de la passe, S2C-bis). Ajouts en fin.
const KEY_USE_POKE_FLUTE: StringName = &"poke_flute"
const KEY_USE_BICYCLE: StringName = &"bicycle"
const KEY_USES: Array[StringName] = [KEY_USE_POKE_FLUTE, KEY_USE_BICYCLE, &"old_rod",
	&"good_rod", &"super_rod"]

var id: StringName = &""
## Nom au singulier (« Poké Ball ») et au pluriel (« Poké Balls »).
var name: String = ""
var plural: String = ""
## Nom féminin (accord de « Ajoutée »).
var feminine: bool = false
var category: Category = Category.BALL
## Multiplicateur de capture (Poké Ball : 1 ; catégorie BALL seulement).
var catch_bonus: float = 1.0
## PV rendus (catégorie HEAL seulement ; la Potion : 20 ; 0 pour un soin de statut seul).
var heal_amount: int = 0
## Statuts soignés (catégorie HEAL seulement, [constant StatusRules.KNOWN] ; l'Antidote :
## [code][&"poison"][/code]). Un soin a des PV à rendre, des statuts à soigner, ou les deux.
var cures: Array[StringName] = []
## Description (fiche du Sac, jalon 5), texte provisoire tant que [member draft].
var description: String = ""
var draft: bool = false
## Fichier d'origine (messages d'erreur).
var source: String = ""
## Prix d'achat en ₽ (dossier 09 §10, jalon-07.md §3.4) ; 0 = jamais vendu en Boutique ni
## repris. Un objet clé n'a jamais de prix ([ItemLibrary] le refuse).
var price: int = 0
## CT (catégorie TM) : numéro (1 à 50, « CT34 ») et capacité enseignée ; 0 et &"" ailleurs.
var tm_number: int = 0
var teaches: StringName = &""
## CS (jalon 16, dossier 19 §0 R-17) : une CS est rangée dans la catégorie TM, avec un numéro de
## CS (1 à 5, « CS01 ») **à la place** du numéro de CT ; elle s'apprend comme une CT réutilisable
## ([TmTeach]) et débloque sa capacité de terrain ([FieldMoves]). 0 pour une CT ou tout autre objet.
var hm_number: int = 0
## Rang dans les données (0, 1, 2… dans l'ordre de lecture des fichiers) : ordre « pertinence »
## du Sac hors combat. Posé par [ItemLibrary].
var order: int = 0
## Usage en exploration d'un objet AVENTURE (jalon 12, T20 ; [constant FIELD_USES]) : &"" =
## aucun (l'objet se consulte, sans bouton UTILISER). Clé « field_use » des données, réservée à
## la catégorie AVENTURE. Sans usage (la Pépite, jalon 13), [method contexts] est vide : c'est la
## seule condition qui retire UTILISER (le Sac et [ItemUse] la lisent par [method usable_in]).
var field_use: StringName = &""
## Toast « obtenu » (jalon 12, T23 ; `jalon-12.md` §0.4 n° 7) : vrai → le toast d'ajout est celui
## d'une CT, nom en casse normale puis « obtenu[e] » (les fossiles, dossier 15 §20 n° 27 :
## « Fossile Dôme » / « obtenu ») au lieu de « ajouté aux objets clés ». Clé « obtained » des
## données, facultative (faux par défaut).
var obtained: bool = false
## Usage en combat d'un objet COMBAT (jalon 20 ; [constant BATTLE_USES]) : &"" = aucun. Clé
## « battle_use » des données : [code]{ "kind": "stat_stage", "stat": "atk", "stages": 1 }[/code],
## [code]{ "kind": "crit_up" }[/code] ou [code]{ "kind": "escape" }[/code].
var battle_use: StringName = &""
## Objet X ([constant BATTLE_USE_STAT_STAGE]) : statistique et étages gagnés.
var battle_stat: StringName = &""
var battle_stages: int = 0
## Rappel (jalon 20, §2.9.4) : fraction des PV max rendue à un Pokémon **K.O.** (0 = pas un
## Rappel). Clé « revive » des données, réservée aux soins.
var revive: float = 0.0
## Usage d'un objet clé (passe systèmes 2 ; [constant KEY_USES]) : &"" = aucun (l'objet se
## consulte, sans UTILISER). Clé « key_use » des données, réservée à la catégorie OBJETS CLÉS.
var key_use: StringName = &""


## Identifiant de la catégorie dans les fichiers (&"ball", &"heal"…) : onglet du Sac.
func category_id() -> StringName:
	return StringName(CATEGORY_NAMES[category])


## Contextes où l'objet sert (jalon-06.md §3.4), déduits de sa catégorie : un objet clé n'en a
## aucun, un objet AVENTURE sans [member field_use] non plus.
func contexts() -> Array[StringName]:
	match category:
		Category.BALL:
			return [CONTEXT_WILD_BATTLE]
		Category.HEAL:
			return [CONTEXT_FIELD, CONTEXT_WILD_BATTLE, CONTEXT_TRAINER_BATTLE]
		Category.BATTLE:
			if battle_use == BATTLE_USE_ESCAPE:
				# La Poupée Poké : combat sauvage seulement (jalon 20, §2.9.3).
				return [CONTEXT_WILD_BATTLE]
			return [CONTEXT_WILD_BATTLE, CONTEXT_TRAINER_BATTLE]
		Category.FIELD:
			if field_use.is_empty():
				return []
			return [CONTEXT_FIELD]
		Category.TM:
			return [CONTEXT_FIELD]
		Category.KEY:
			if key_use == KEY_USE_POKE_FLUTE:
				return [CONTEXT_FIELD, CONTEXT_WILD_BATTLE, CONTEXT_TRAINER_BATTLE]
			if not key_use.is_empty():
				return [CONTEXT_FIELD]
	return []


## Vrai si l'objet sert dans le contexte [param context] (exploration, combat sauvage, combat
## de dresseur).
func usable_in(context: StringName) -> bool:
	return contexts().has(context)


## Vrai si l'objet se donne à un Pokémon de l'équipe (choix du Pokémon, [ItemUse]) : les soins
## (de PV ou de statut) et le Rappel (jalon 20).
func targets_pokemon() -> bool:
	return category == Category.HEAL and (heal_amount > 0 or not cures.is_empty() \
		or is_revive())


## Rappel (jalon 20) : se donne seulement à un Pokémon K.O.
func is_revive() -> bool:
	return revive > 0.0


## Objet COMBAT avec un usage (jalon 20) : se joue sur le Pokémon actif, sans choix de cible.
func has_battle_use() -> bool:
	return category == Category.BATTLE and not battle_use.is_empty()


## Vrai si l'objet soigne le statut [param status].
func cures_status(status: StringName) -> bool:
	return status != StatusRules.NONE and cures.has(status)


## CT (jalon 11) : enseigne une capacité ([member teaches]).
func is_tm() -> bool:
	return category == Category.TM


## CS (jalon 16) : une CT de numéro de CS ([member hm_number]).
func is_hm() -> bool:
	return is_tm() and hm_number > 0


## Objet permanent (les CT) : jamais consommé par un usage, une seule fois dans le Sac.
func is_permanent() -> bool:
	return category == Category.TM


## Nom accordé à [param count] : singulier pour 1, pluriel au-delà.
func name_for(count: int) -> String:
	return name if count <= 1 else plural


## « Poké Balls ×5 », « Poké Ball ×1 » ; un objet clé, unique, n'a que son nom en capitales
## (« COLIS POUR CHEN », dossier 09 §19) ; une CT ou un objet [member obtained], son nom tel quel.
func quantity_text(count: int) -> String:
	if is_tm() or obtained:
		return name
	if is_key():
		return name.to_upper()
	return "%s ×%d" % [name_for(count), count]


## « Ajoutée au Sac », « Ajoutées au Sac », « Ajouté au Sac »… accordé au genre du nom et à
## [param count] ; un objet clé : « ajouté aux objets clés » (dossier 09 §19) ; une CT ou un objet
## [member obtained] : « obtenu[e] ».
func added_text(count: int) -> String:
	var agreement := ("e" if feminine else "") + ("s" if count > 1 else "")
	if obtained:
		return TM_ADDED_BASE + agreement
	if is_key():
		return KEY_ADDED_BASE + agreement + KEY_ADDED_SUFFIX
	if is_tm():
		return TM_ADDED_BASE + agreement
	return ADDED_BASE + agreement + ADDED_SUFFIX


## Objet clé (OBJETS CLÉS) : jamais utilisé, vendu ni jeté.
func is_key() -> bool:
	return category == Category.KEY


## Vrai si la Boutique peut reprendre l'objet : il a un prix et n'est pas permanent (objet clé,
## CT).
func is_sellable() -> bool:
	return price > 0 and not is_key() and not is_permanent()


## Prix de reprise en ₽ : la moitié du prix, arrondie en dessous (Rouge/Bleu) ; 0 si l'objet
## ne se vend pas.
func sell_price() -> int:
	return floori(price / 2.0) if is_sellable() else 0


## Vrai si l'objet a un usage en exploration (jalon 12 : UTILISER d'un objet AVENTURE).
func has_key_use() -> bool:
	return category == Category.KEY and not key_use.is_empty()


func has_field_use() -> bool:
	return category == Category.FIELD and not field_use.is_empty()
