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
| `bag_qa.json` | Salamèche N8 à 6 PV, Roucool N5 en pleine forme, Rattata N5 K.O., 10 Potions et 5 Poké Balls : soin, refus et Potion en combat (QA 6B). Clé de membre « hp » : PV de départ (0 = K.O.) |
| `viridian.json` | J7 (7A.1) : Salamèche N8 et Roucool N7, prologue et rival du labo faits, à l'entrée sud de Jadielle (spawn `from_route_1_w`), tourné vers le nord : monter le chemin et le grand escalier sud (12 pas) ; le premier pas sur la place joue la micro-scène d'arrivée (une seule fois). Sans argent ni stockage (clés `money` / `storage` de `DebugStart` disponibles depuis le T8) |
| `center_qa.json` | J7 (7A.2, T9) : Salamèche N8 à 6 PV et Roucool N7 **K.O.**, 3 000 ₽, Jadielle découverte, devant la porte du Centre (spawn `from_center`, tourné vers le sud : un pas en bas, un pas en haut pour entrer). Aucun Centre enregistré : une défaite ramène encore chez Maman ; après un soin au Centre, au Centre |
| `route_22.json` | J7 (7B.2, T25) : Salamèche N8 et Roucool N7, **Pokédex activé**, 3 000 ₽, à l'entrée de la Route 22 (spawn `from_viridian`). Monter l'escalier puis un pas vers l'ouest sur le sentier : la scène du rival n° 2 (Carapuce, paire `taken_charmander` + `taken_squirtle`) |
| `rival_2_weak.json` | J7 (7B.2, T25) : Salamèche **N4** seul (pour perdre), Pokédex activé, 3 000 ₽, au pied de l'escalier de la Route 22 (spawn `stair_foot`, tourné vers le nord : 3 pas en haut, 1 à gauche). Défaite → réveil chez Maman (aucun Centre enregistré), argent intact |
| `parcel.json` | J7 (7A.5, T19) : Salamèche N9 et Roucool N7, **colis pour Chen** dans le Sac (`got_oak_parcel`), rival du labo parti, 2 700 ₽, devant la porte du labo (spawn `oak_lab_door`, tourné vers le nord : un pas en haut pour entrer). Parler à Chen joue la remise du colis et l'activation du Pokédex. **Aucune rencontre sauvage** : la réplique « Un {espèce}… » est omise (la vraie partie la joue). Jamais `pokedex_activated` |

| `shop_qa.json` | J7 (7A.3, T13) : Salamèche N8, Roucool N7, **6 000 ₽**, 3 Poké Balls et 4 Potions **favorites** (clé `favorites` : objets du Sac marqués favoris), devant la porte de la Boutique (spawn `from_mart`, tourné vers le sud : un pas en bas, puis vers le haut pour entrer). Colis pas encore reçu : la première visite joue la scène du colis ; ensuite, parler au marchand ouvre la Boutique |
| `storage_qa.json` | J7 (7A.4, T17) : **6 en équipe** (Salamèche N9 en tête, Roucool N8, Rattata N6 **K.O.**, Piafabec, Nidoran♀, Férosinge) et **10 au stockage** dont un Piafabec N5 **favori** (clé de membre `favorite`), 3 000 ₽, dans le Centre de Jadielle **devant le terminal** (spawn `terminal`, tourné vers le haut : EXAMINER ouvre le Stockage). Équipe pleine : REPRENDRE refusé tant qu'on n'a rien déposé |

## Déblocages du Menu Dresseur (jalon 6 T2)

`tools/deploy_s24.sh --debug-unlock pokedex` dépose `user://debug_unlocks.json`
(`{ "pokedex": true }`, lu par `DebugUnlocks`, `game/systems/debug/debug_unlocks.gd`) : l'écran
Pokédex existe **sans** que le drapeau d'histoire `pokedex_activated` soit posé ; rien n'est
sauvegardé. Même garde que le départ de débogage (build debug, Boot scène principale, fichier
présent). Se combine avec `--debug-start` ou avec la vraie partie ; sans l'option, le fichier est
retiré. Sur le Mac : `echo '{ "pokedex": true }' > "$HOME/Library/Application Support/Godot/app_userdata/Kanto 2026/debug_unlocks.json"`.
