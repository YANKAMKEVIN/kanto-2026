class_name SpinSlide
extends ForcedSlide
## Trajet d'une glisse sur les dalles tournantes (jalon 20 T4, docs/tech/jalon-20.md §2.4.3),
## calculé d'avance par [method SpinTileRules.slide]. Classe pure, sans nœud.
##
## Forme commune des glissades forcées ([ForcedSlide], passe systèmes 2 T15) : [member
## ForcedSlide.end] est la case d'arrêt si [member status] vaut OK. Jouée par
## [ForcedSlideDirector] ; aucune sauvegarde pendant la glisse (dossier 23 §13.3).

enum Status {
	OK, ## La glisse finit sur une case d'arrêt.
	NOT_AN_ARROW, ## La case de départ n'est pas une dalle : aucun trajet.
	BLOCKED, ## La case suivante n'est pas praticable (erreur de données).
	LOOP, ## Le trajet repasse par la même case dans la même direction (erreur de données).
	TOO_LONG, ## Plus de pas que la limite permise (erreur de données).
}

var status: Status = Status.NOT_AN_ARROW


func is_ok() -> bool:
	return status == Status.OK


func status_name() -> String:
	return Status.keys()[status]


## Trajet en texte, au format des grilles (« O4,S2,E1 », N S E O) : sert aux messages.
func path_text() -> String:
	var parts: PackedStringArray = []
	var count := 0
	for i: int in facings.size():
		count += 1
		if i == facings.size() - 1 or facings[i + 1] != facings[i]:
			parts.append("%s%d" % [SpinTileRules.compass_letter(facings[i]), count])
			count = 0
	return ",".join(parts)
