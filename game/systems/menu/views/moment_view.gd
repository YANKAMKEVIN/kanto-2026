class_name MomentView
extends RefCounted
## Un grand moment de l'écran Dresseur (dossier 08 §6 ; jalon-06.md §3.7, Q-14) : titre,
## détail, lieu et date. Contrat figé au T23.
##
## Règle d'affichage : **un texte vide = une ligne absente**. [member route] null = la ligne
## ne se touche pas ; sinon, la toucher émet [code]route_requested(route)[/code] tel quel
## (le déblocage est déjà appliqué : l'écran ne décide rien).

## Type du moment ([constant MomentLibrary.STARTER]… [constant MomentLibrary.ZONE_ARRIVAL]) :
## pour une icône, jamais pour un texte.
var kind: StringName = &""
## « Premier Pokémon », « Départ de Bourg Palette ». Jamais vide.
var title: String = ""
## « Salamèche rejoint ton équipe. » ; "" = pas de ligne.
var detail: String = ""
## Nom de la **zone** du moment (« Bourg Palette » pour le labo) ; "" si inconnue.
var place: String = ""
## « 2 octobre 2026 » ; "" si la date est inconnue.
var date_text: String = ""
## Date ISO d'origine (ordre chronologique, tests) ; pas à afficher.
var date: String = ""
## Zone du moment (&"" si inconnue) : icône ou illustration, plus tard.
var zone_id: StringName = &""
## Espèce du moment (premier Pokémon, première capture), &"" sinon : petite image possible.
var species_id: StringName = &""
## Numéro du Pokédex de [member species_id] (artwork officiel) ; 0 sinon. Ajouté au MM.2.
var dex_number: int = 0
## Lien croisé (« premier Pokémon » → sa fiche Équipe, ou sa fiche Pokédex si le Pokédex est
## visible, §6.3) ; null = pas de lien.
var route: MenuRoute = null
