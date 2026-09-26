# Kanto 2026

Remake 2D **personnel** de Pokémon Rouge/Bleu pour smartphone, « comme si Pokémon n'avait jamais quitté la 2D ». Godot 4.7 + GDScript, cible Android (Galaxy S24, paysage).

Kevin est le **directeur du jeu** : il conçoit (souvent avec ChatGPT), Claude implémente. Toute décision de game design non documentée → la lui poser, ne pas l'inventer.

## À lire avant de travailler

- `docs/design/vision.md` — constitution, DA, contrôles, plan en 13 phases. **Source de vérité du design.**
- `docs/design/ui-reference.md` + `docs/design/reference/da-2026-planche-v1.webp` — référence **UI** validée.
- `docs/design/ui-ux-bible-v0.1.md` — philosophie UI/UX (« le monde est la star ») ; ses contradictions avec la planche sont listées en fin de fichier.
- `docs/design/dossier-04-systeme-pokemon.md` — système Pokémon (jalons 4+) ; `dossier-05-combat.md` — combat ; `dossier-06-progression.md` — progression, arènes, rival, Ligue.
- `docs/design/reference/bourg-palette-aplus-v1.png` — benchmark graphique du **monde** (2D HD atmosphérique, golden hour).
- `docs/design/reference/chambre-joueur-v1.webp` — référence de la **chambre du joueur** (agencement + rendu cible des intérieurs) ; autres intérieurs : `ouverture-storyboard-v1.webp`, `maison-rival-v1.webp`, `labo-chen-v1.png` ; combat : `combat-v1.webp`, `combat-capture-v1.webp`.
- `docs/design/dossier-*.md` — conception détaillée par zone (`dossier-02-prologue.md` : textes définitifs du prologue, découpage 3A / 3B / 4).
- `docs/tech/etat-projet.md` — **où en est le projet, prochaine étape, questions ouvertes.** À lire en début de session.
- `docs/tech/jalon-*.md` — plans techniques des jalons (tâches et critères d'acceptation).

## Règles de travail

1. **Une fonctionnalité → testée sur le S24 → validée par Kevin → suivante.** Jamais trois systèmes à la fois.
2. Une tâche n'est finie que si : `tools/test.sh` passe, le projet s'importe sans erreur, et (si c'est visible) une capture S24 a été vérifiée.
3. Données (Pokémon, attaques, objets, rencontres, dialogues) = fichiers de données, jamais codées en dur dans la logique.
4. Logique de jeu séparée de la présentation (testable sans scène).
5. Monde en **2D HD atmosphérique** (décors HD, personnages et Pokémon en pixel art fin, lumière dynamique) ; UI **non** pixel art (skill `ui-theme-2026`).

## Décisions techniques

| Sujet | Valeur |
|---|---|
| Résolution de référence | 1920×1080, stretch `canvas_items`, aspect `expand` (le S24 affiche ~2340×1080) |
| Rendu | `mobile`, filtre par défaut `linear` (décors HD), `nearest` sur les sprites pixel art (personnages, Pokémon), snap 2D au pixel |
| Grille | **case = 96 px** en unités monde = pixels de référence, caméra zoom 1 (≈ 11 cases de haut) ; décors HD dessinés à 1:1 |
| Personnages | pixel art 64 px de haut en natif, affichés ×2 (128 px ≈ 1,33 case), origine aux pieds |
| Déplacement | Case par case (grille 96 px), marche/course |
| Couches physiques | 1 monde · 2 joueur · 3 pnj · 4 interactifs · 5 déclencheurs |
| Actions d'entrée | `move_up/down/left/right`, `interact`, `run`, `menu` (clavier pour tests desktop, tactile sur mobile) |
| Tests | GUT 9.7 (`addons/gut`), dossier `tests/` |
| Package Android | `dev.kevin.kanto2026` |

## Arborescence

```
game/          code et scènes (world/, player/, pokemon/, battle/, ui/, systems/, autoload/)
assets/        tiles/, sprites/, ui/, fonts/, audio/
data/          (à venir) données de jeu
tests/         unit/, integration/ (GUT)
tools/         test.sh, build_android.sh, deploy_s24.sh
docs/design/   conception (ignoré par Godot)
```

## Commandes

```bash
tools/test.sh                  # tests GUT headless
tools/build_android.sh         # APK debug → build/kanto2026-debug.apk
tools/deploy_s24.sh            # build + install + lancement + capture build/screenshot.png + logs
godot --headless --path . --import   # réimport / détection d'erreurs de scripts
```

## Skills du projet (`.claude/skills/`)

`godot-conventions` · `godot-cli` · `android-deploy` · `ui-theme-2026` · `world-tiles`

## Agents (`.claude/agents/`)

`architecte-godot` · `constructeur-monde` · `ui-mobile` · `qa-mobile`
