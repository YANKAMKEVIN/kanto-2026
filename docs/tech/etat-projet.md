# État du projet — note de passage

Mis à jour : 2026-09-25 (fin de la session d'initialisation).

## Fait
- Outillage : Godot 4.7.2, export Android vérifié sur le S24, GUT 9.7.1, scripts `tools/`.
- Conception synthétisée dans `docs/design/` (vision, Dossier 01 Master Map A+, référence UI, images de référence).
- Skills et agents du projet dans `.claude/`.
- **Jalon 1, étape architecture** : plan dans [`jalon-01.md`](jalon-01.md), fondations logiques testées (82 tests verts) :
  `game/world/grid.gd` (constantes, conversions), `grid_world.gd` (règles d'accès), `grid_mover.gd` (mouvement case par case), `game/systems/input/direction_input.gd` (clavier et joystick vers 4 directions).

## Prochaine étape
Jalon 1, tâches **T1 à T4** pour l'agent `constructeur-monde` : tuiles provisoires et TileSet, props et `GameMap`, carte `pallet_town` (48×34), joueur, caméra et `Boot`. Viennent ensuite **T5** pour `ui-mobile` puis **T6** pour `qa-mobile`. Les critères d'acceptation sont dans `jalon-01.md`.

## Questions ouvertes pour Kevin (posées par l'architecte)
1. **Porte du labo et jardins** : la porte du labo est au sud, donc les jardins arrivent devant elle. Proposition : un parvis devant l'entrée, un portillon vers les jardins, et un accès à la côte par l'ouest et l'est du labo.
2. **Hauteur de carte** : 34 rangées au lieu de 32, pour caser les jardins derrière le labo.
3. **Sous-titre du nom de zone** : « Kanto » à chaque arrivée ; « Le commencement de toute aventure » réservé à la première sortie de la maison (plus tard).
4. **Courir** : bouton tenu (supposé), bouton bascule, ou joystick poussé à fond ?
5. **Vitesse** : 0,22 s par case, soit environ 7,5 s pour traverser nord-sud. On garde pour le premier test sur le S24, puis on ajuste ?
6. **Sortie Route 1** : simple bord de carte (supposé) ou élément visible qui explique le blocage ?

Tant que Kevin n'a pas répondu, les agents appliquent les hypothèses ci-dessus.
