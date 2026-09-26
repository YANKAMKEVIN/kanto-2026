extends Node
## Autoload « GameState » : état de la session qui survit aux changements de carte.
##
## Un seul rôle en 3A (docs/tech/jalon-03.md §2.6) : tenir les drapeaux d'histoire
## (« Maman a déjà parlé »). Pas de sauvegarde : quitter l'application recommence la partie.
## Il ne connaît aucun autre autoload. Les systèmes qui lisent les drapeaux (dialogues) les
## reçoivent par injection (`GameState.flags`) et restent testables avec un [StoryFlags] neuf.
## Sans [code]class_name[/code] (le nom est pris par l'autoload) : les tests instancient
## [code]preload("res://game/autoload/game_state.gd").new()[/code].

var flags: StoryFlags = StoryFlags.new()


## Nouvelle partie : tous les drapeaux baissés (appelé par Boot au démarrage).
func new_game() -> void:
	flags.clear()
