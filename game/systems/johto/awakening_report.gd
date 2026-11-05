class_name AwakeningReport
extends RefCounted
## Le bilan du Réveil ([method StoneAwakening.awaken]) : ce que l'écran montre. Rien n'est écrit
## ici ; l'état de partie est déjà à jour quand ce bilan existe.

## Niveau visé (JH-66).
var target: int = 0
## Pokémon de l'équipe réveillés, dans l'ordre de l'équipe (le premier a été frappé, P-28b).
var party: Array[AwakeningResult] = []
## Captures du Stockage réveillées (JH-71) : annoncées en une ligne, sans écran.
var stored: Array[AwakeningResult] = []
## Tous les Pokémon de l'équipe qui peuvent paraître (ni œuf) : le plan large final, y compris
## ceux qui étaient déjà au-dessus de la cible.
var line_up: Array[Pokemon] = []


## Vrai si au moins un Pokémon de l'équipe a un plan (sinon : le Réveil se joue sans écran).
func has_scene() -> bool:
	return not party.is_empty()


## Attaques proposées à l'écran, tous Pokémon confondus.
func offered_moves_count() -> int:
	var total := 0
	for result: AwakeningResult in party:
		total += result.new_moves.size()
	return total
