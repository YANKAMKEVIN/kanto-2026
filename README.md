# Kanto 2026

Remake 2D **personnel** de Pokémon Rouge/Bleu pour smartphone, « comme si Pokémon n'avait jamais quitté la 2D ».

- **Moteur** : Godot 4.7 + GDScript
- **Cible** : Android, en paysage (testé sur Galaxy S24)
- **Direction artistique** : « 2D HD atmosphérique » — décors HD, personnages et Pokémon en pixel art fin, lumière dynamique ; interface moderne et discrète (« le monde est la star »)

> Projet de fan, non commercial et privé. Pokémon et tous les noms, personnages et univers associés appartiennent à Nintendo, Game Freak et The Pokémon Company. Ce dépôt n'est affilié à aucun d'eux.

## Où en est le jeu

| Jalon | Contenu | État |
|---|---|---|
| 1 | Se promener dans Bourg Palette (carte, déplacement case par case, caméra, joystick, course) | ✅ validé |
| 2 | Portes et intérieurs (chambre, maison, maison du rival, labo de Chen, transitions) | ✅ validé |
| 3A | PNJ, dialogues, bouton contextuel Parler / Examiner / Observer | ✅ validé |
| 3B | L'événement de la Route 1 : « Hé ! Attends ! », le Prof. Chen, le retour au labo | ✅ validé |
| 4A | Le choix du starter | 🔧 en finition |
| 4B | Le premier combat contre le rival | 🔧 en cours |
| 5 | La Route 1, les rencontres sauvages, l'XP, la sauvegarde, la capture | 📐 conçu |

L'état détaillé, la prochaine étape et les questions ouvertes sont dans [`docs/tech/etat-projet.md`](docs/tech/etat-projet.md).

Les graphismes actuels sont **provisoires, aux dimensions finales** : on valide d'abord la géométrie, le rythme et les mécaniques, puis la passe graphique transforme la même base.

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — règles de travail et décisions techniques (à lire en premier)
- [`docs/design/`](docs/design/) — conception : [`vision.md`](docs/design/vision.md) (constitution, DA, plan en 13 phases), dossiers par thème (Bourg Palette, prologue, système Pokémon, combat, progression, Route 1), bible UI/UX et images de référence
- [`docs/tech/`](docs/tech/) — plans techniques de chaque jalon (`jalon-*.md`) et état du projet

## Démarrer

Prérequis : Godot 4.7.2 dans le `PATH` (commande `godot`). Pour Android : SDK Android et modèles d'export Godot.

```bash
tools/test.sh                          # tests GUT en headless
godot --headless --path . --import     # réimport et détection d'erreurs de scripts
godot --path .                         # lancer le jeu sur ordinateur (clavier : flèches ou ZQSD, Maj pour courir, E ou Espace pour interagir)
tools/build_android.sh                 # APK debug → build/kanto2026-debug.apk
tools/deploy_s24.sh                    # build + installation + lancement sur le téléphone + capture + logs
```

## Organisation du code

```
game/          code et scènes (world/, player/, pokemon/, battle/, ui/, systems/, autoload/)
data/          données de jeu en JSON : dialogues, PNJ, scènes scriptées, Pokémon, capacités, types, combat
assets/        tuiles, sprites, interface
tests/         tests GUT (unit/, integration/, fixtures/)
tools/         scripts : tests, export Android, génération des cartes et des assets provisoires, captures
docs/          conception et plans techniques
```

Principes : contenu dans des **fichiers de données** (jamais en dur dans la logique), **logique séparée de la présentation** et testable sans scène, **une fonctionnalité à la fois**, validée sur le téléphone avant la suivante.

## Façon de travailler

Kevin est le directeur du jeu : il conçoit, Claude implémente, avec des agents spécialisés (`.claude/agents/` : architecte, constructeur du monde, UI mobile, QA mobile).

- Les **sessions Claude dans le cloud** conçoivent, codent et testent sur une branche dédiée (Godot s'y installe automatiquement via `tools/cloud_setup.sh`).
- Le **Mac** (téléphone branché en USB) récupère la branche, fait les captures et la QA sur le Galaxy S24.
- Rien n'entre dans `main` sans la validation de Kevin sur le téléphone.
