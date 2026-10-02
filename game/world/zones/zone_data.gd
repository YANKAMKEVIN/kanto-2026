class_name ZoneData
extends RefCounted
## Une zone du Kanto du projet (data/world/zones.json) : une ville, une route ou un lieu, et
## les cartes qui lui appartiennent (un intérieur appartient à sa ville). Donnée pure,
## construite par [ZoneLibrary].
##
## Sa place sur l'illustration de Kanto n'est pas ici : les rectangles appartiennent à
## l'illustration (`assets/ui/map/kanto_placeholder_areas.json`), qui sera refaite en phase DA.

const KIND_TOWN: StringName = &"town"
const KIND_ROUTE: StringName = &"route"
## Lieu nommé qui n'est ni une ville ni une route (Forêt de Jade, Mont Sélénite…).
const KIND_PLACE: StringName = &"place"
## Route maritime (Route 21).
const KIND_SEA_ROUTE: StringName = &"sea_route"
const KINDS: Array[StringName] = [KIND_TOWN, KIND_ROUTE, KIND_PLACE, KIND_SEA_ROUTE]

var id: StringName = &""
## Nom affiché (« Bourg Palette », « Route 1 »).
var name: String = ""
var kind: StringName = KIND_TOWN
## Cartes de la zone (identifiants de [MapCatalog]) ; vide tant que la zone n'est pas construite.
var maps: Array[StringName] = []
## Fichier d'origine (messages d'erreur).
var source: String = ""
