class_name MapZoneView
extends RefCounted
## Une zone **découverte** sur l'écran Carte (dossier 08 §5 ; jalon-06.md §3.6). Construite par
## [method MapJournal.view]. Contrat figé au T18 (§6.10) : on peut seulement ajouter des champs
## (architecte).
##
## Une zone non découverte n'a **pas** de vue : ni nom, ni toucher (Q-15) ; l'illustration
## seule la montre.

var zone_id: StringName = &""
## « Route 1 ».
var name: String = ""
## Genre ([constant ZoneData.KIND_TOWN]…) : l'écran peut dessiner une ville et une route
## différemment.
var kind: StringName = &""
## Rectangle sur l'illustration, en pixels de l'image ([member MapView.image_size]) ; vide
## (sans aire) si l'illustration n'en a pas : la zone n'est alors pas touchable sur la carte.
var area: Rect2 = Rect2()
## Le joueur est dans cette zone (dans un intérieur : sa ville) : portrait discret.
var current: bool = false


func is_touchable() -> bool:
	return area.has_area()
