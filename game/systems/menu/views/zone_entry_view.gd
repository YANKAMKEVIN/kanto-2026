class_name ZoneEntryView
extends RefCounted
## Une ligne d'une liste du panneau de zone (dossier 08 §5 ; jalon-06.md §3.6) : un Pokémon
## observé, un objet trouvé ou un service découvert. Contrat figé au T18 (§6.10) : on peut
## seulement ajouter des champs (architecte).
##
## Selon la liste, [member id] est une espèce (sprite `BattleStage.sprite_path(id, false)`,
## toucher → fiche du Pokédex), un objet (icône `BagEntryView.icon_for(id)`) ou un service.

var id: StringName = &""
## « Roucool », « Potion », « Centre Pokémon ».
var name: String = ""
## Objets : exemplaires trouvés dans la zone (≥ 1) ; 1 pour les Pokémon et les services.
var count: int = 1
## Pokémon : numéro du Pokédex (artwork officiel, [PokedexArt]) ; 0 = inconnu ou pas un
## Pokémon (pas d'image : le nom seul, jamais une silhouette). Ajouté au MM.2.
var dex_number: int = 0


func _init(entry_id: StringName = &"", shown_name: String = "", times: int = 1) -> void:
	id = entry_id
	name = shown_name
	count = times


## « ×2 » si l'objet a été trouvé plusieurs fois ; "" sinon (jamais un total à atteindre).
func count_text() -> String:
	return "×%d" % count if count > 1 else ""
