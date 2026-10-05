class_name ShopEntryView
extends RefCounted
## Un objet de la Boutique, vu d'un onglet (ACHETER ou VENDRE) : des chaînes, des entiers et
## une carte du langage du Sac, rien d'autre (dossier 09 §9, jalon-07.md §3.4, §6.9). Construit
## par [ShopViews] ; l'écran ne connaît ni le Sac, ni l'argent, ni les données.
##
## Contrat figé au T10 : les champs ne changent ni de nom ni de sens ; on peut en ajouter.
## **Texte vide = élément absent.**

var item_id: StringName = &""
## Nom au singulier (« Poké Ball »).
var name: String = ""
## Nom au pluriel (« Poké Balls ») : TOTAL, confirmation d'une vente de plusieurs.
var plural: String = ""
## Description courte (aperçu).
var description: String = ""
## Identifiant de catégorie (&"ball", &"heal"…).
var category_id: StringName = &""
## Favori du Sac (étoile **et** texte, jamais la couleur seule). En VENDRE : la vente demande
## une confirmation ([member needs_confirm]).
var favorite: bool = false
## Exemplaires dans le Sac, et « DANS LE SAC : 3 » (toujours écrit, « DANS LE SAC : 0 »
## compris, à l'achat).
var owned: int = 0
var owned_text: String = ""
## Prix unitaire de l'onglet (achat : le prix ; vente : la moitié, arrondie en dessous) et
## « 200 ₽ ».
var unit_price: int = 0
var price_text: String = ""
## Quantité maximale du sélecteur (1 à [constant ShopRules.MAX_QUANTITY]) ; 0 = indisponible :
## le sélecteur et CONFIRMER sont inactifs et [member reason] dit pourquoi.
var max_quantity: int = 0
## Raison d'une indisponibilité (« Tu n'as pas assez d'argent. ») ; vide si disponible.
var reason: String = ""
## VENDRE d'un favori : CONFIRMER passe d'abord par [method ShopViews.sell_confirm_view].
var needs_confirm: bool = false
## Carte du langage du Sac (`BagItemCard`) : nom accordé, quantité possédée, catégorie,
## favori, illustration.
var card: BagEntryView = null


func is_available() -> bool:
	return max_quantity > 0


## Quantité ramenée dans [1, [member max_quantity]] (1 si indisponible) : sélecteur QUANTITÉ.
func clamp_quantity(quantity: int) -> int:
	return clampi(quantity, 1, maxi(max_quantity, 1))


## Illustration (celle de la carte).
func get_icon() -> Texture2D:
	return card.get_icon() if card != null else BagEntryView.icon_for(item_id)
