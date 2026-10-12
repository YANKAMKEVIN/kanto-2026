class_name TeamMemberView
extends RefCounted
## Ce qu'affiche un membre de l'équipe dans le menu (Pokémon de tête du tableau de bord ;
## liste de l'Équipe au 6A) : des chaînes et des nombres, rien d'autre (jalon-06.md §3.2,
## §3.3). Les écrans ne connaissent ni [Pokemon] ni les données.
##
## Contrat figé au T2 : les champs ci-dessous ne changent ni de nom ni de sens ; le T6 peut en
## ajouter (sprite, XP…).

## Statut « K.O. » écrit en toutes lettres (dossier 08 §2 : le statut est toujours un texte ;
## les autres statuts viendront au J11).
const STATUS_FAINTED: String = "K.O."
## Statut « PSN » (poison, jalon 9) : toujours un texte, jamais une icône seule.
const STATUS_POISON: String = "PSN"
## Statuts du J11 (dossier 08 §2 : abréviations réservées ; dossier 14 §3.3).
const STATUS_PARALYSIS: String = "PAR"
const STATUS_SLEEP: String = "SOM"
const STATUS_BURN: String = "BRÛ"
const STATUS_FREEZE: String = "GEL"

## Place dans l'équipe (0 = Pokémon de tête).
var party_index: int = 0
## Espèce (identifiant de données) : l'écran en déduit le sprite.
var species_id: StringName = &""
## Numéro du Pokédex de l'espèce (artwork officiel, [PokedexArt]) ; 0 = inconnu (pas d'image).
## Ajouté au MM.1.
var dex_number: int = 0
## Surnom, sinon nom de l'espèce (« Salamèche »).
var display_name: String = ""
var gender: BattleCardView.Gender = BattleCardView.Gender.NONE
var level: int = 1
var hp: int = 1
var max_hp: int = 1
## "" ou [constant STATUS_FAINTED] ou [constant STATUS_POISON] (voir [StatusView]).
var status_text: String = ""
var favorite: bool = false


## Vue affichable : un nom, un niveau ≥ 1, 0 ≤ PV ≤ PV max, PV max ≥ 1.
func is_valid() -> bool:
	return not display_name.is_empty() and level >= 1 and max_hp >= 1 \
		and hp >= 0 and hp <= max_hp
