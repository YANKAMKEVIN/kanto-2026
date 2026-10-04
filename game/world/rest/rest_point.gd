class_name RestPoint
extends RefCounted
## Un point de repos (dossier 09 §7 ; jalon-07.md §3.3) : où le joueur se réveille après une
## défaite, et ce qu'on lui dit. La maison (point de départ) et chaque Centre Pokémon.
##
## Donnée pure, lue dans `data/world/rest_points.json` par [RestPointLibrary]. Le point de
## repos **courant** de la partie vit dans [member GameState.heal_map] / `heal_spawn` (champs
## de la sauvegarde depuis le jalon 5) ; cette donnée n'y ajoute que l'orientation et le mot
## du réveil.

## Carte (identifiant de scène, [MapCatalog]) ; un point de repos par carte au plus.
var map: StringName = &""
## Point d'apparition de la carte (nœud de `Spawns`) : devant Maman, devant le comptoir.
var spawn: StringName = &""
## Orientation au réveil (vers Maman, vers l'infirmière).
var facing: Vector2i = Vector2i.UP
## Dialogue joué au réveil après une défaite (« mom_wakeup », « nurse_wakeup ») ; &"" = aucun.
var wakeup_dialogue: StringName = &""
## Vrai pour un Centre : s'y soigner l'enregistre comme point de repos. Faux pour la maison
## (point de départ, que Maman ne « réenregistre » pas : dossier 09 §7).
var registers: bool = false
## Fichier d'origine (messages d'erreur).
var source: String = ""
