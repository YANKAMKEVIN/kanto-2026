class_name ZoneAnnouncer
extends RefCounted
## Décide si le titre de zone doit s'afficher à l'arrivée sur une carte.
##
## Règle (proposition du jalon 2, question Q3 à Kevin) : on n'annonce que les zones
## **extérieures**, et seulement quand on arrive dans une zone différente de la dernière
## annoncée. Conséquences : rien dans les intérieurs ; en commençant dans la chambre,
## « BOURG PALETTE » s'affiche à la première sortie, puis plus à chaque porte franchie ;
## il reviendra en rentrant de la Route 1.

var _last: String = ""


## Vrai s'il faut afficher le titre de [param zone_name] ; mémorise la zone annoncée.
func should_announce(zone_name: String, interior: bool) -> bool:
	if interior or zone_name.is_empty() or zone_name == _last:
		return false
	_last = zone_name
	return true


## Dernière zone annoncée ("" si aucune).
func get_last_announced() -> String:
	return _last


## Oublie la dernière zone (nouvelle partie, chargement).
func reset() -> void:
	_last = ""
