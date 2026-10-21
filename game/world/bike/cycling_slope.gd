class_name CyclingSlope
extends RefCounted
## Pente de la Piste Cyclable (docs/tech/jalon-22.md §2.3, dossier 25 §6.4) : sur une case de
## pente de la Route 17, sans appui, le joueur dérive d'une case vers le bas au rythme du vélo.
## Gauche, droite et haut restent libres ; les paliers (cases sans marque) arrêtent la dérive.
## Classe statique, sans nœud.


## Doit-on dériver d'une case vers le bas ? Seulement sans direction tenue, sur une case de pente
## (pas un palier), joueur libre (ni dialogue, ni combat, ni scène) et aucun Dresseur qui le voit.
static func should_drift(
		input_dir: Vector2i, on_slope_cell: bool, player_free: bool,
		seen_by_trainer: bool) -> bool:
	return input_dir == Vector2i.ZERO and on_slope_cell and player_free and not seen_by_trainer
