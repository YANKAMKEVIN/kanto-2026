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

## Les coulisses : ce qui a été difficile, et ce qui a permis de tenir

*Note écrite le 2026-11-08 par Claude, à la demande de Kevin, à partir de ce que le projet a gardé en mémoire : décisions notées, rapports de QA, règles de travail.*

### Les difficultés

**1. Trouver l'identité visuelle.** Le jeu devait d'abord avoir des personnages en pixel art fin sur des décors HD. Le 3 octobre 2026, après un test en mouvement sur le S24, Kevin a tout basculé vers des personnages peints. Il a ensuite fallu repeindre 300 cartes et plus de 200 espèces, avec des dos de combat et une même main partout.

**2. Produire l'art avec une IA capricieuse.** Codex refusait Mario et Harry Potter, et a bloqué Link six fois sur onze à cause d'un blason de bouclier. Il y avait aussi une limite d'images sur 24 h. Même refaire une pose devenait un petit chantier.

**3. Ne pas se perdre.** Avec des centaines de décisions de design, les maquettes contredisaient parfois les dossiers. D'où la règle : l'écrit gagne toujours sur l'image. Et une IA ne se souvient de rien d'une session à l'autre.

**4. Faire travailler plusieurs sessions en même temps.** Elles partageaient le même dépôt et se marchaient dessus. Il a fallu des copies séparées, une règle d'ancienneté sur les fichiers et une file d'attente pour le téléphone.

**5. Les pannes qui mentent.** Ce sont les plus dangereuses :

- un « All tests passed » alors qu'un fichier de test n'avait pas pu se charger ;
- une CI « réussie » sans conclusion après une coupure réseau ;
- un outil qui réenregistrait des cartes dégradées en disant « OK ».

**6. Les limites matérielles.** Le Mac ne tenait que deux suites de tests à la fois, et les fusions attendaient une à deux heures. L'APK de 780 Mo faisait tomber la connexion adb. Une QA sur téléphone a duré plus de 3 h. Le S24 a aussi été indisponible un temps.

**7. Le risque de tout perdre.** La sauvegarde a connu dix versions de format, et chacune devait relire les anciennes parties. Ce système se validait toujours seul.

**8. Le droit.** Un jeu de fan rempli de licences, c'est un risque que personne ne peut faire disparaître. Il fallait le regarder en face et décider : diffusion limitée à moins de dix proches, jamais de store.

### Ce qui a permis de tenir

- **Un seul directeur.** Kevin a tranché, parfois brutalement, comme quand Mario a été remplacé en une décision. Sans cela, un projet pareil se dilue.
- **Des petites étapes vérifiables.** Le premier jalon, c'était juste se promener dans Bourg Palette. Chaque jalon se terminait sur un téléphone réel, et on voyait le jeu grandir.
- **Une mémoire écrite.** `etat-projet.md`, les dossiers et les arbitrages numérotés permettaient à chaque nouvelle session de repartir sans rien perdre.
- **Les petites questions ne bloquent jamais.** Une valeur par défaut, une note, et on continue. Seul le vrai game design remontait jusqu'à Kevin.
- **Corriger la méthode, pas seulement le bug.** Chaque panne est devenue une règle ou un outil, et on est arrivé à plus de 800 fichiers de test et une CI passée de 24 à 10 minutes.
- **Se faire confiance progressivement.** La validation déléguée du 4 novembre 2026 a enlevé à Kevin le rôle de goulot d'étranglement.
- **Le plaisir.** Kevin a continué à ajouter ce qui l'amusait : l'arc de Johto, les costumes, et même Naruto en arrivant à Jadielle. Un projet tenu par obligation s'arrête avant.

Une nuance sur « jusqu'au bout » : le jeu existe, il est complet et il tourne sur un téléphone, ce qui est déjà énorme. Mais il reste le plus beau : personne n'a encore joué Johto d'un bout à l'autre, et la partie complète de Kevin reste à faire.
