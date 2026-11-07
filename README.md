# Pokemake

**Pokemake** (« Pokémon Kevin Remake ») est un jeu **personnel** pour smartphone : un remake de Pokémon Rouge / Bleu, suivi d'un chapitre Johto, pensé pour un téléphone en paysage. Le dépôt, le dossier et le package gardent l'ancien nom de travail, `kanto2026`.

- **Moteur** : Godot 4.7 + GDScript
- **Cibles** : Android en paysage (Galaxy S24, Galaxy A17) ; iOS en seconde cible pour les proches ([`docs/tech/ios.md`](docs/tech/ios.md))
- **Direction artistique** : « 2D HD atmosphérique ». Décors peints en HD ; personnages et Pokémon **peints simplifiés**, de la même main, dans le monde, en combat et dans les menus ; lumière dynamique ; interface moderne et discrète, pas en pixel art.
- **Version** : 0.35.0 (`config/version` de `project.godot`, source unique)

> Projet de fan, non commercial et privé. Pokémon et tous les noms, personnages et univers associés appartiennent à Nintendo, Game Freak et The Pokémon Company ; les autres œuvres citées (costumes et leurs musiques) appartiennent à leurs ayants droit. Ce dépôt n'est affilié à aucun d'eux. Le jeu n'est diffusé qu'à Kevin et à un cercle de moins de dix proches, par APK installé à la main : jamais de store ni de lien public.

## Où en est le jeu

| Partie | Contenu | État |
|---|---|---|
| **Kanto** | Toute l'aventure de Rouge / Bleu : 8 Arènes, Team Rocket, rival, Ligue Pokémon, Mewtwo ; toutes les cartes peintes | Jouable de bout en bout ; jalons jusqu'au J34 dans `main` |
| **Chapitre Johto** | Histoire réécrite (Orme, Team Rocket, légendaires, arc des Pierres), horloge jour / nuit | Jouable (JOH0 à JOH9, JOHP0 à JOHP3) ; pas encore joué d'un bout à l'autre |
| **Costumes** | Un costume par badge (joueur et joueuse), avec un avantage écrit, un thème de combat et un chant d'arrivée en ville | Dans `main` depuis le 2026-11-07 |
| **Version des proches** | RC 0.35.0, jeu complet | Construite ; la RC suivante ajoutera les costumes, la nouvelle icône et le démarrage direct |

Quelques chiffres : 202 espèces, 211 capacités, 8 badges de Kanto, 16 costumes, plus de 300 cartes.

Ce que le jeu sait faire, entre autres : déplacement case par case avec joystick tactile, course, vélo, surf et pêche ; combats avec statuts, objets, changements et apprentissage de capacités ; capture, Pokédex, stockage, pension et œufs, échanges en jeu, Parc Safari ; compagnon Pokémon qui suit le joueur ; menu Dresseur (badges, grands moments, costumes) ; sauvegarde automatique ; musiques et bruitages ; joueur ou joueuse au choix.

L'état détaillé, les prochaines étapes et les questions ouvertes sont dans [`docs/tech/etat-projet.md`](docs/tech/etat-projet.md).

## Documentation

- [`CLAUDE.md`](CLAUDE.md) : règles de travail et décisions techniques, à lire en premier.
- [`docs/tech/etat-projet.md`](docs/tech/etat-projet.md) : où en est le projet, à lire en début de session.
- [`docs/design/vision.md`](docs/design/vision.md) : constitution du jeu, direction artistique, contrôles. Source de vérité du design.
- [`docs/design/roadmap.md`](docs/design/roadmap.md) et [`docs/design/index-dossiers.md`](docs/design/index-dossiers.md) : vue d'ensemble des jalons et index de tous les dossiers de conception.
- [`docs/tech/`](docs/tech/) : plans techniques des jalons (`jalon-*.md`), sortie des versions ([`release.md`](docs/tech/release.md)), point juridique ([`jalon-34-34e.md`](docs/tech/jalon-34-34e.md)).
- Interface : [`docs/design/ui-ux-bible-v0.1.md`](docs/design/ui-ux-bible-v0.1.md) ; art du monde : [`docs/design/cahier-art-monde-v0.1.md`](docs/design/cahier-art-monde-v0.1.md).

## Démarrer

Prérequis : Godot 4.7.2 dans le `PATH` (commande `godot`). Pour Android : SDK Android et modèles d'export Godot. Pour iOS : Xcode.

```bash
godot --path .                          # lancer le jeu sur ordinateur (flèches ou ZQSD, Maj pour courir, E ou Espace pour interagir)
godot --headless --path . --import      # réimport et détection d'erreurs de scripts
tools/test.sh --changed                 # tests GUT liés aux fichiers modifiés
tools/test.sh                           # suite complète
tools/ci_wait.sh                        # après un push : attend la CI GitHub (14 lots)
tools/build_android.sh                  # APK debug → build/kanto2026-debug.apk
tools/deploy_s24.sh                     # build, installation, lancement, capture et journal sur le téléphone
tools/build_rc.sh                       # APK release signé → build/rc/ (clé hors dépôt, voir docs/tech/release.md)
tools/build_ios.sh                      # projet Xcode et application pour le simulateur
tools/version.py show                   # version du jeu et code Android
```

Avec deux téléphones branchés, chaque commande `adb` fixe `ANDROID_SERIAL`. Des départs de débogage prêts à jouer sont décrits dans [`tools/debug_start/README.md`](tools/debug_start/README.md).

## Organisation du code

```
game/          code et scènes (world/, player/, pokemon/, battle/, ui/, systems/, autoload/)
data/          données de jeu en JSON : Pokémon, capacités, rencontres, Dresseurs, dialogues, histoire, costumes, audio
assets/        décors peints, personnages, Pokémon, interface, polices, musiques et bruitages
tests/         tests GUT (unit/, integration/, fixtures/)
tools/         tests, exports Android et iOS, outils d'art, de cartes et d'audio, captures
docs/          conception (docs/design/) et plans techniques (docs/tech/)
```

Principes : le contenu vit dans des **fichiers de données**, jamais en dur dans la logique ; la **logique est séparée de la présentation** et testable sans scène ; les visuels sont validés sur le téléphone, pas seulement à l'écran du Mac.

## Façon de travailler

Kevin est le **directeur du jeu** : il conçoit, souvent avec ChatGPT, et Claude implémente, avec des agents spécialisés (`.claude/agents/` : architecte, constructeur du monde, UI mobile, QA mobile). Les décisions de game design reviennent toujours à Kevin.

- Une session Claude par jalon, dans sa propre copie du dépôt (worktree) et sur sa branche, poussée sur GitHub.
- Avant chaque fusion dans `main` : tests ciblés et suite complète (CI GitHub verte ou suite du Mac).
- Validation sur téléphone par sous-jalon. Depuis le 2026-11-04, les sessions avancent et fusionnent sur auto-validation et CI verte ; seules les décisions de game design et les questions juridiques remontent à Kevin.
- L'art est généré avec Codex, à partir de planches validées par Kevin ; une maquette validée se reproduit à l'identique.
