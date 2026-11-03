class_name MapView
extends RefCounted
## L'écran Carte (dossier 08 §5 ; jalon-06.md §3.6) : l'illustration de Kanto entière, les
## zones **découvertes** (touchables), le portrait du joueur. Construite par
## [method MapJournal.view] ; l'écran ne connaît ni la partie ni les données. Contrat figé au
## T18 (§6.10) : on peut seulement ajouter des champs (architecte) ; **texte vide = élément
## absent**.
##
## « Un journal, pas un guide » : aucun total (« 2 / 22 »), aucun « ??? », aucune zone non
## découverte nommée, aucun bouton de déplacement.

## « CARTE — KANTO ».
var title: String = ""
## Illustration (chemin res://) et sa taille en pixels : les rectangles des zones sont dans
## ce repère.
var image_path: String = ""
var image_size: Vector2i = Vector2i.ZERO
## Zones découvertes, dans l'ordre de `zones.json` (celui du voyage).
var zones: Array[MapZoneView] = []
## Zone du joueur (portrait) ; &"" si sa carte n'est rangée dans aucune zone.
var player_zone: StringName = &""
## Zone dont le panneau s'affiche à l'arrivée : celle de la route si elle est découverte
## (lien Habitat du Pokédex), sinon celle du joueur ; &"" = aucun panneau.
var selected: StringName = &""
## JOH0 (`jalon-joh0.md` §2.13) : page affichée (région), nom de la page, pages disponibles
## (Kanto seule tant que le joueur n'est pas arrivé à Johto) et leurs noms.
var region: StringName = &""
var region_name: String = ""
var regions: Array[StringName] = []
var region_names: PackedStringArray = PackedStringArray()


## Page suivante (JOH0 : Kanto ↔ Johto) ; &"" s'il n'y en a qu'une.
func next_region() -> StringName:
	if regions.size() < 2:
		return &""
	var rank := maxi(regions.find(region), 0)
	return regions[(rank + 1) % regions.size()]


## Vue de [param zone_id], ou null (zone non découverte).
func zone(zone_id: StringName) -> MapZoneView:
	if zone_id.is_empty():
		return null
	for found: MapZoneView in zones:
		if found.zone_id == zone_id:
			return found
	return null


## Rectangle du portrait du joueur (celui de sa zone) ; vide si inconnu.
func player_area() -> Rect2:
	var found := zone(player_zone)
	return found.area if found != null else Rect2()
