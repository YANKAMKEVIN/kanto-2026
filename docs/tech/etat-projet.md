# État du projet — note de passage

Mis à jour : 2026-09-25 (T1–T6 faits, retouches QA en cours de validation).

## Fait
- Outillage : Godot 4.7.2, export Android vérifié sur le S24, GUT 9.7.1, scripts `tools/`.
- Conception synthétisée dans `docs/design/` (vision, Dossier 01 Master Map A+, référence UI, images de référence).
- Skills et agents du projet dans `.claude/`.
- **Jalon 1, étape architecture** : plan dans [`jalon-01.md`](jalon-01.md), fondations logiques testées (82 tests verts) :
  `game/world/grid.gd` (constantes, conversions), `grid_world.gd` (règles d'accès), `grid_mover.gd` (mouvement case par case), `game/systems/input/direction_input.gd` (clavier et joystick vers 4 directions).

- **Jalon 1, T1 à T6** : Bourg Palette jouable sur le S24 (carte 48×34, joueur, caméra, HUD : titre de zone, joystick, bouton courir). 173 tests verts. QA sur S24 : 60 fps, aucune collision traversée, aucun plantage (rapport : `build/qa/rapport-jalon-01.md`, non versionné).
- Retouches après QA (voir `jalon-01.md` §7) : transparence des feuillages et toits, bancs déplacés, haut de la Route 1.

## Prochaine étape
Validation de Kevin sur le S24, puis commit du jalon 1.

## Reportés (décision de Kevin)
- Écran de démarrage « GODOT » (~0,5 s) : à remplacer avec l'icône et l'identité du jeu.
- Incident de saisie vu une fois en QA (joueur reparti dans le mauvais sens), non reproduit : à surveiller.

## Décisions de Kevin (2026-09-25)
Les six propositions de l'architecte sont acceptées : porte du labo au sud avec parvis et portillon vers les jardins, carte 48×34, sous-titre « Kanto » (la phrase d'ouverture est réservée à la première sortie de la maison), course au bouton tenu, marche 0,22 s/case et course 0,12 s/case (à ajuster après l'essai sur S24), sortie Route 1 = bord de carte. Détails dans [`jalon-01.md`](jalon-01.md) §6.
