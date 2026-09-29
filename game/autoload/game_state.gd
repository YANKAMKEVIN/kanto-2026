extends Node
## Autoload « GameState » : état de la session qui survit aux changements de carte.
##
## 3A (docs/tech/jalon-03.md §2.6) : drapeaux d'histoire (« Maman a déjà parlé »).
## Jalon 4 (docs/tech/jalon-04.md §3.9) : équipe du joueur, espèce de son starter et
## aléatoire à graine de la partie. Jalon 4B (jalon-04.md §14.6) : le Sac (les 5 Poké Balls
## données par le Prof. Chen). Pas de sauvegarde : quitter l'application recommence la
## partie.
## Il ne connaît aucun autre autoload. Les systèmes qui lisent l'état (dialogues, scènes,
## choix du starter) le reçoivent par injection et restent testables avec des instances
## neuves. Sans [code]class_name[/code] (le nom est pris par l'autoload) : les tests
## instancient [code]preload("res://game/autoload/game_state.gd").new()[/code].

## Drapeaux d'histoire (même instance pendant toute la session : elle est injectée).
var flags: StoryFlags = StoryFlags.new()
## Équipe du joueur (même instance pendant toute la session : vidée par [method new_game]).
var party: Party = Party.new()
## Espèce du starter choisi au labo (&"" avant le choix).
var starter_species: StringName = &""
## Aléatoire de la partie (remplacé par [method new_game] : nouvelle graine).
var rng: GameRng = GameRng.new()
## Sac du joueur (même instance pendant toute la session : vidé par [method new_game]).
var bag: Bag = Bag.new()
## Pokédex : espèces vues et capturées (jalon 5, décision de Kevin 2026-09-29). L'écran
## arrive au jalon 6 ; les données sont collectées et sauvegardées dès le jalon 5. Même
## instance pendant toute la session (vidée par [method new_game]).
var pokedex: Pokedex = Pokedex.new()


## Nouvelle partie (appelé par Boot au démarrage) : drapeaux baissés, équipe, Sac et Pokédex
## vides, pas de starter, aléatoire neuf de graine [param rng_seed] (−1 = graine tirée au
## hasard).
func new_game(rng_seed: int = -1) -> void:
	flags.clear()
	party.clear()
	bag.clear()
	pokedex.clear()
	starter_species = &""
	rng = GameRng.new(rng_seed)
