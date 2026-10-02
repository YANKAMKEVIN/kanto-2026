# Départs de débogage (jalon 5 T9)

Parties prêtes à jouer, construites par `DebugStart` (`game/systems/debug/debug_start.gd`,
format décrit en tête du fichier) au lieu de la nouvelle partie. **Désactivé par défaut.**

Le jeu lit `user://debug_start.json` seulement si :
- c'est un **build debug** (jamais dans un export release) ;
- `Boot` est la **scène principale** lancée par le moteur (jamais sous GUT ni dans un outil) ;
- le fichier **existe**.

## Sur le S24 (APK debug)

```bash
tools/deploy_s24.sh --debug-start forget_move   # dépose tools/debug_start/forget_move.json
tools/deploy_s24.sh                             # retire le fichier : partie normale
```

Le fichier reste sur le téléphone (relancer l'appli depuis l'icône le relit) jusqu'au prochain
déploiement sans `--debug-start`. Le journal (`logcat -s godot`) affiche
« Départ de débogage (…) : … » quand il est appliqué.

## Sur le Mac

Copier le fichier dans le dossier utilisateur du projet, lancer, puis le retirer :

```bash
cp tools/debug_start/route_1.json "$HOME/Library/Application Support/Godot/app_userdata/Kanto 2026/debug_start.json"
godot --path .
rm "$HOME/Library/Application Support/Godot/app_userdata/Kanto 2026/debug_start.json"
```

## Fichiers

| Fichier | Partie |
|---|---|
| `route_1.json` | Salamèche N5 sur la Route 1 (entrée sud), prologue terminé, 5 Poké Balls |
| `learn_move.json` | Bulbizarre N6 à 5 XP du N7 : apprend Vampigraine au premier combat gagné |
| `forget_move.json` | Bulbizarre N19 à 1 XP du N20, 4 capacités : Poudre Toxik → choix de l'oubli |
| `capture_qa.json` | Salamèche N5 sur la Route 1, 30 Poké Balls : juger l'équilibrage de la capture (QA T16) |
| `team_full.json` | Équipe de 6 sur la Route 1, 10 Poké Balls : une capture part au stockage (QA T16) |

## Déblocages du Menu Dresseur (jalon 6 T2)

`tools/deploy_s24.sh --debug-unlock pokedex` dépose `user://debug_unlocks.json`
(`{ "pokedex": true }`, lu par `DebugUnlocks`, `game/systems/debug/debug_unlocks.gd`) : l'écran
Pokédex existe **sans** que le drapeau d'histoire `pokedex_activated` soit posé ; rien n'est
sauvegardé. Même garde que le départ de débogage (build debug, Boot scène principale, fichier
présent). Se combine avec `--debug-start` ou avec la vraie partie ; sans l'option, le fichier est
retiré. Sur le Mac : `echo '{ "pokedex": true }' > "$HOME/Library/Application Support/Godot/app_userdata/Kanto 2026/debug_unlocks.json"`.
