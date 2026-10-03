class_name MomentTextData
extends RefCounted
## Titre et détail d'un grand moment de l'écran Dresseur (data/trainer/moments.json,
## jalon-06.md §3.7). Donnée pure, construite par [MomentLibrary]. Les marques ({species},
## {zone}, {outcome}) sont remplies par [TrainerSummary].

## Titre (« Première capture », « {zone} »). Jamais vide.
var title: String = ""
## Ligne de détail (« {species} rejoint l'aventure. ») ; "" = pas de ligne.
var detail: String = ""
## Texte provisoire, à relire par Kevin.
var draft: bool = false
