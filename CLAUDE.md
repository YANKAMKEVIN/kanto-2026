# Kanto 2026 (le jeu s'appelle **Pokemake**)

Godot 4.7 + GDScript, cible Android (Galaxy S24, paysage) ; seconde cible iOS pour les proches (`docs/tech/ios.md`).

Kevin est le **directeur du jeu** : il conçoit (souvent avec ChatGPT), Claude implémente. Toute décision de game design non documentée → la lui poser, ne pas l'inventer.

## À lire avant de travailler

- `docs/tech/etat-projet.md` — **où en est le projet, prochaine étape, questions ouvertes.** À lire en début de session.
- `docs/design/vision.md` — constitution, DA, contrôles, plan en 13 phases. **Source de vérité du design.**
- `docs/design/strategie-acceleration.md` — ordre et rythme des jalons (2 à 3 jalons en code au maximum, tests ciblés, validations groupées). À lire avant d'ouvrir ou de fusionner un jalon.
- `docs/design/roadmap.md` — vue macro du projet et ordre des jalons.
- `docs/design/index-dossiers.md` — **index de tous les dossiers, plans et images de référence**, jalon par jalon. Y chercher le dossier de la zone avant d'y travailler.
- `docs/tech/jalon-*.md` — plans techniques des jalons (tâches et critères d'acceptation).
- UI : `docs/design/ui-reference.md` et `docs/design/ui-ux-bible-v0.1.md`. Art du monde : `docs/design/cahier-art-monde-v0.1.md`.

## Règles de travail

1. **Validation S24 par sous-jalon** (5B, 5C…) : les tâches liées s'enchaînent, puis une seule session S24 + validation de Kevin à la fin du sous-jalon. Exception : un système risqué (sauvegarde, tout ce qui peut perdre des données) est validé seul. Jamais trois systèmes à la fois.
2. Une tâche n'est finie que si : les tests ciblés passent (`tools/test.sh --changed`), la **suite complète** (`tools/test.sh`, ou la CI GitHub verte via `tools/ci_wait.sh` tant que le dépôt est public, décision de Kevin du 2026-10-26) étant obligatoire avant chaque fusion (exception, décision de Kevin du 2026-11-06 : un changement de **texte seul**, dans `data/story/` ou la description du projet, se fusionne avec les tests ciblés ; tout ce qui touche au code, aux cartes, à la sauvegarde ou aux données de jeu garde la suite complète), le projet s'importe sans erreur, et (si c'est visible) une capture a été relue (headless ou Mac) ; la capture S24 vient à la validation du sous-jalon.
3. **Sur S24, on valide le fonctionnel** (ça marche, c'est lisible, c'est bien placé), pas le rendu final : les visuels sont provisoires jusqu'à la phase DA. Une remarque de rendu se note dans `docs/tech/etat-projet.md` (« Reportés »), sans la corriger tout de suite.
4. **Petites questions → valeur par défaut** : durées, positions, tailles, couleurs… reçoivent une valeur par défaut, notée dans le commit et dans `etat-projet.md`, et le travail continue. Seules les vraies décisions de game design bloquent et vont à Kevin.
5. **`docs/tech/etat-projet.md` est mis à jour dans le même commit que chaque tâche terminée** : chaque session repart de ce fichier. Il reste **court** : on y remplace ce qui change, sans empiler de ligne par tâche (le détail va dans `docs/tech/jalon-*.md`). Historique : `docs/tech/etat-projet-archive.md`, à chercher avec `grep`, jamais à lire en entier.
6. Kevin prépare le dossier de conception du jalon suivant **pendant** le jalon en cours, pour que le code n'attende pas les décisions.
7. Données (Pokémon, attaques, objets, rencontres, dialogues) = fichiers de données, jamais codées en dur dans la logique.
8. Logique de jeu séparée de la présentation (testable sans scène).
9. Monde en **2D HD atmosphérique** (décors HD peints, personnages et Pokémon **peints simplifiés** dans la même main, y compris en combat et dans les menus, lumière dynamique) ; UI **non** pixel art (skill `ui-theme-2026`). Production de l'art : `docs/design/cahier-art-monde-v0.1.md`.
10. **Les maquettes et images de référence donnent la DA et la composition, jamais la vérité fonctionnelle.** Si une image contredit un dossier, `vision.md`, la bible UI/UX ou une décision validée, l'écrit gagne. On n'implémente jamais un élément simplement parce qu'il apparaît sur une maquette.

## Décisions techniques

| Sujet | Valeur |
|---|---|
| Résolution de référence | 1920×1080, stretch `canvas_items`, aspect `expand` (le S24 affiche ~2340×1080) |
| Rendu | `mobile`, filtre `linear` partout (décors, personnages et Pokémon peints), snap 2D au pixel |
| Grille | **case = 96 px** en unités monde = pixels de référence, caméra zoom 1 (≈ 11 cases de haut) ; décors HD dessinés à 1:1 |
| Personnages | **peints simplifiés** (décision de Kevin, 2026-10-03, après test en mouvement sur S24), 128 px de haut affichés à 1:1 (≈ 1,33 case), origine aux pieds ; enfant ≈ 108 px, petit Pokémon (Rattata) ≈ 56 px |
| Déplacement | Case par case (grille 96 px), marche/course |
| Couches physiques | 1 monde · 2 joueur · 3 pnj · 4 interactifs · 5 déclencheurs |
| Actions d'entrée | `move_up/down/left/right`, `interact`, `run`, `menu` (clavier pour tests desktop, tactile sur mobile) |
| Tests | GUT 9.7 (`addons/gut`), dossier `tests/` |
| Package Android / bundle iOS | `dev.kevin.kanto2026` |
| Nom et version | `config/name="Pokemake"` (dépôt, dossier et package gardent « kanto2026 ») ; `config/version` = source unique, code Android `MAJEUR×10000+MINEUR×100+CORRECTIF` (`tools/version.py`) |

## Arborescence

```
game/          code et scènes (world/, player/, pokemon/, battle/, ui/, systems/, autoload/)
assets/        tiles/, sprites/, ui/, fonts/, audio/
data/          (à venir) données de jeu
tests/         unit/, integration/ (GUT)
tools/         test.sh, build_android.sh, deploy_s24.sh, build_ios.sh
docs/design/   conception (ignoré par Godot)
```

## Commandes

```bash
tools/test.sh                  # suite complète, avant une fusion (verrou : 2 suites complètes max sur le Mac ; affiche les 10 scripts les plus lents)
tools/test.sh --changed [base] # pendant une tâche : seulement les tests liés aux fichiers modifiés depuis base (défaut origin/main)
tools/test.sh -f surf,safari   # pendant une tâche : les fichiers de test dont le nom contient un des motifs
tools/ci_wait.sh [commit]      # dépôt public : après push, attend la CI GitHub (10 lots) ; remplace la suite du Mac avant une fusion
tools/build_android.sh         # APK debug → build/kanto2026-debug.apk
tools/build_rc.sh [--install]  # APK release signé → build/rc/pokemake-<version>.apk + manifeste (clé hors dépôt : docs/tech/release.md)
tools/version.py show|set X.Y.Z|check   # version unique (project.godot) recopiée dans les presets ; code Android dérivé
tools/deploy_s24.sh            # build + install + lancement + capture build/screenshot.png + logs (USB ou Wi-Fi)
tools/build_ios.sh [--run]     # projet Xcode build/ios/ + app simulateur (x86_64, runtime iOS 18) ; --device avec KANTO_IOS_TEAM
tools/s24_serial.sh            # série adb du S24 (USB ou débogage sans fil)
godot --headless --path . --import   # réimport / détection d'erreurs de scripts
```

## Skills du projet (`.claude/skills/`)

`godot-conventions` · `godot-cli` · `android-deploy` · `ui-theme-2026` · `world-tiles`

## Agents (`.claude/agents/`)

`architecte-godot` (Opus) · `constructeur-monde` (Sonnet) · `ui-mobile` (Sonnet) · `qa-mobile` (Sonnet) — pour une tâche difficile, on peut forcer Opus à l'appel.

**Agents en parallèle** : chacun travaille dans sa propre copie (worktree) ; **jamais de `pkill` / `killall` sur Godot ou GUT** (d'autres agents font tourner leurs tests sur le même Mac) : arrêter seulement ses propres processus, par PID.

**Fable, ponctuellement et sur demande** (≈ 2,5 × le coût d'Opus, jamais par défaut) : seulement quand une erreur coûterait cher — conception de la **sauvegarde** (5C.5), **compagnon Pokémon** (J11), bug sur lequel Opus a déjà échoué. Haiku n'est pas utilisé pour le code, les données ni la QA (au mieux, des recherches dans le code).

## Gestion des sessions (décision de Kevin, 2026-10-20)

Pour limiter la consommation de tokens, chaque session relisant tout son historique à chaque réponse :

- **Une session neuve par sous-jalon.** Elle repart de ce fichier, de `docs/tech/etat-projet.md` et du plan du jalon (`docs/tech/jalon-XX.md`), dans le worktree du jalon. Prompt de reprise type : « Reprise du JXX. Lis CLAUDE.md, docs/tech/etat-projet.md, docs/tech/jalon-XX.md. Travaille dans le worktree … (branche …, @commit). Prochaine tâche : … Décisions de Kevin : … »
- **Avant de rendre la main en fin de sous-jalon** : `etat-projet.md` à jour, tout commité et poussé, puis proposer à Kevin le prompt de reprise de la session suivante.
- **Au plus 2 à 3 jalons actifs** à la fois (`docs/design/strategie-acceleration.md`, levier 2). Une session en pause est **fermée**, puis reprise par une session neuve quand elle a de nouveau du travail.
- **Sous-agents** : Sonnet pour les données, cartes, textes et vérifications mécaniques ; Opus pour l'architecture et les bugs difficiles (voir « Agents » ci-dessus).
- La ligne d'état affiche la taille du contexte : en jaune ou en rouge, finir la tâche en cours puis repartir sur une session neuve.
