class_name StorageView
extends RefCounted
## Ce qu'affiche l'écran Stockage (dossier 09 §8, §19 ; jalon-07.md §3.5, §6.4) : trois
## colonnes, ÉQUIPE · Pokémon sélectionné et ses actions · STOCKAGE (grille défilante, ordre
## d'arrivée). Des chaînes et des nombres : l'écran ne connaît ni [Pokemon] ni les données.
## Construit par [StorageViews] ; une vue neuve après chaque action. Contrat figé au T14 : les
## champs ne changent ni de nom ni de sens ; on peut en ajouter.

## Emplacements de la colonne ÉQUIPE (les vides sont neutres, comme dans l'Équipe).
const PARTY_SLOTS: int = Party.MAX_SIZE

## « ÉQUIPE », « STOCKAGE », « RETOUR ».
var party_title: String = ""
var storage_title: String = ""
var back_label: String = ""
## Colonne ÉQUIPE, dans l'ordre (0 = tête).
var party: Array[StorageCardView] = []
## Grille STOCKAGE, dans l'ordre d'arrivée.
var storage: Array[StorageCardView] = []
## « Le stockage est vide. » quand il l'est, sinon "".
var empty_text: String = ""
## Pokémon sélectionné (jamais null ; vide si l'équipe et le stockage sont vides).
var selection: StorageSelection = StorageSelection.new()
## Fiche du Pokémon sélectionné (langage de l'Équipe : types, PV, XP, statistiques,
## capacités, histoire) ; null sans sélection.
var sheet: PokemonSheetView
## Actions du Pokémon sélectionné, dans l'ordre : DÉPOSER (équipe) ou REPRENDRE (stockage),
## puis FAVORI. Vide sans sélection.
var actions: Array[StorageActionView] = []
## Menu secondaire « ⋯ » : LIBÉRER (dossier 09 §8 : jamais en bouton principal). Vide sans
## sélection.
var more_actions: Array[StorageActionView] = []


## Carte de [param place] à [param index], ou null.
func card_at(place: StorageRules.Place, index: int) -> StorageCardView:
	var cards := party if place == StorageRules.Place.PARTY else storage
	return cards[index] if index >= 0 and index < cards.size() else null
