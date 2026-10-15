class_name DaycareWithdrawal
extends RefCounted
## « Plan de retrait » de la Pension, rendu par [method DaycareRules.withdraw] (J15, V-2, F-2,
## F-3). Donnée pure : l'XP est déjà appliquée et le Pokémon soigné et rendu à l'équipe ; ce qui
## reste à **proposer** au joueur (écrans du 15A) est décrit ici, dans l'ordre :
## 1. débiter [member paid] de l'argent de `GameState` (au 15A : ajouter le relais de la Pension
##    à la liste blanche de `test_shop_rules.test_only_the_shop_spends_money`) ;
## 2. chaque capacité de [member moves], dans l'ordre (`MoveLearnPrompt.teach`, « veut
##    apprendre… oublier ? » ; refuser = capacité non apprise, jamais d'oubli automatique) ;
## 3. puis, si [member evolution] n'est pas vide, l'évolution (écran existant, annulable ;
##    capacités de la nouvelle espèce : [method Evolution.evolve]).

## OK, ou la raison du refus (rien n'a changé alors).
var status: DaycareRules.Status = DaycareRules.Status.EMPTY
## Le Pokémon rendu (après un refus : celui qui reste gardé, ou null).
var pokemon: Pokemon = null
## Un [LevelUp] par niveau gagné, dans l'ordre ([method Pokemon.gain_exp]).
var level_ups: Array[LevelUp] = []
## Capacités à proposer, dans l'ordre des niveaux puis des données, sans doublon.
var moves: Array[StringName] = []
## Espèce vers laquelle proposer l'évolution, ou &"" (aucune).
var evolution: StringName = &""
## Prix demandé.
var price: int = 0
## Montant à débiter réellement (≤ argent du joueur, F-2).
var paid: int = 0


func is_ok() -> bool:
	return status == DaycareRules.Status.OK


func levels_gained() -> int:
	return level_ups.size()
