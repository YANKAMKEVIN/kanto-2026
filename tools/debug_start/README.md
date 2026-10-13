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
| `save_v4_qa.json` | J9 (9A.1, T2) : Salamèche N9 **empoisonné** (clé de membre `status`), Roucool N7, 3 000 ₽, devant la porte du Centre de Jadielle (spawn `from_center`). **Clé `autosave: true` : ce départ REMPLACE `user://save.json`** (autosave actif, contrairement à tous les autres départs). Sert à vérifier qu'un statut survit à une fermeture forcée : relancer ensuite **sans** départ de débogage (`tools/deploy_s24.sh --no-build`), le journal affiche « [qa] statut relu : Salamèche (équipe 1) poison ». **Copier d'abord la vraie sauvegarde** (voir la procédure T3 dans `docs/tech/jalon-09.md`) |
| `poison_ui.json` | J9 (9A.2, T5) : Salamèche N9 et Rattata N5 **empoisonnés**, Roucool N7, Nidoran♀ N6 K.O., 3 Antidotes, 2 Potions, 3 Poké Balls, 3 000 ₽, **`poison_unlocked` posé** (Antidote en vente), devant la Boutique de Jadielle (spawn `from_mart`). Sert à `tools/capture_poison.gd` ; gardé au T23 (Sac, Équipe et Boutique avec deux empoisonnés, sans combat) |
| `poison_qa.json` | J9 (9A.2, T6 ; **rebasé au T23** sur le vrai poste sud) : Salamèche N9 **empoisonné**, Roucool N7, 2 Potions, **2 Antidotes**, 3 000 ₽, Pokédex activé, **`poison_unlocked` absent**, à l'entrée du **poste sud de la Forêt de Jade** côté Route 2 (spawn `from_route_2`, tourné vers le nord). Le garde parle de lui-même à l'arrivée (dialogue « auto », une seule fois) et pose `poison_unlocked` (Antidote en vente à Jadielle) ; ensuite on lui reparle pour le rappel. Ouverture nord → forêt (Aspicot : poison en combat, Antidote du Sac) ; porte sud → Route 2 |
| `evolution_qa.json` | J9 (9A.3, T6 ; **rebasé au T23** sur la vraie forêt) : Salamèche N9, **Chenipan N6** et **Aspicot N6** à 1 XP du N7, **Chrysacier N9** à 1 XP du N10 (deuxième évolution), 5 Potions, 3 000 ₽, `poison_unlocked` posé, à l'**entrée sud de la Forêt de Jade** (spawn `from_gate_south`, tourné vers le nord) : H1 (table de la forêt, niveaux 3 à 6) à quelques pas au nord-est, Théo (Dresseur) plus haut. Mettre le Pokémon voulu en tête ; évolutions jouées après le bilan (T8 / T9) |
| `trainers_qa.json` | J9 (9A.4, T6 ; **rebasé au T23** sur la vraie forêt) : Salamèche N9, Roucool N8, 5 Potions, **1 Antidote**, 3 000 ₽, `poison_unlocked` posé, sur le sentier de la Forêt de Jade **devant Scout Théo** (spawn `before_theo` (34, 70), tourné vers l'ouest : au 4e pas, (30, 70), Théo voit le joueur). Les 5 Dresseurs de la forêt sont à leur place (aucun battu) : Théo, puis Tom (C2), Noé (H2), Milo (inévitable), Éli (parvis) |
| `trainers_weak_qa.json` | J9 (9A.4, T6 ; **rebasé au T23**) : comme `trainers_qa` mais Salamèche **N4** seul, sans Sac : perdre contre Théo (réveil chez Maman, argent intact, Théo redéfie). Sert à `tools/capture_trainer_spotted.gd` |
| `route_2.json` | J8 (T4) : Salamèche N10, Roucool N9, Rattata N8, **Pokédex activé**, 3 000 ₽, 5 Poké Balls et 3 Potions, à l'entrée sud de la Route 2 (spawn `from_viridian_c`, case du milieu côté Jadielle), tourné vers le nord. Aucun objet de la Route 2 ramassé, Randonneuse et Jeune Dresseur jamais vus. La carte arrive au T5 |
| `viridian_forest.json` | J9 (9B.1, T18) : Salamèche N10, Roucool N9, Rattata N8, **Pokédex activé**, `poison_unlocked` posé (le garde du poste sud a parlé), 3 000 ₽, 5 Poké Balls et 3 Potions, **sans Antidote** (celui de la forêt, O1, est à 15 pas depuis la forêt agrandie), à l'entrée sud de la Forêt de Jade (spawn `from_gate_south`), tourné vers le nord. Aucun objet ramassé, aucun Dresseur battu. La carte arrive au T19 |
| `viridian_forest_north.json` | Forêt agrandie (2026-10-08, QA de l'étape 3) : comme `viridian_forest.json`, mais **devant la porte du poste nord** (spawn `from_gate_north`, tourné vers le sud) : parvis, H5, raccord nord (poste nord dans les deux sens), traversée à rebours |
| `route_2_north.json` | J10 (T8) : fin du J9 (Pokédex activé, `poison_unlocked`, Théo battu), Salamèche N11, Papilusion N10 (Choc Mental), Roucool N10, 3 000 ₽, 5 Poké Balls, 3 Potions, 1 Antidote, à la sortie du poste nord sur la Route 2 nord (spawn `from_forest_gate`), tourné vers le nord. Potion de la route et Montagnard jamais vus. La carte arrive au T11 |
| `pewter.json` | J10 (T8) : même partie, à l'entrée sud d'Argenta (spawn `from_route_2_north_c`), tourné vers le nord : le premier pas dans la ville pose `pewter_arrived` (objectif « obtenir le Badge Roche. »). La carte arrive au T11 |
| `pewter_gym.json` | J10 (T8) : même partie, `pewter_arrived` posé, devant la porte de l'Arène (spawn `from_gym`), tourné vers le nord. Liam non battu, Pierre jamais rencontré. Équipe « naturelle » confirmée au T16 (Salamèche N11 : la traversée de la Route 2 nord, 3 combats, ne lui fait pas gagner de niveau ; Liam le monte au N12) |
| `brock_weak.json` | J10 (T8) : Salamèche **N6** seul, sans Sac, 3 000 ₽, Liam battu, devant la porte du Centre d'Argenta (spawn `from_center`) : se soigner d'abord au Centre (point de repos « Argenta »), puis perdre contre Pierre → réplique de défaite, réveil au Centre d'Argenta, argent intact, `brock_met` posé ; en lui reparlant : « Prêt à essayer autrement ? » |
| `brock_charmander.json` | J10 (T16) : **départ Salamèche** (dossier 12 arbitrage 3), devant la porte de l'Arène (spawn `from_gym`), fin du J9, `pewter_arrived`, **Liam pas encore battu** : Salamèche **N12**, Papilusion N10 (**Choc Mental**), Roucool N10, 3 Potions, 3 000 ₽. Niveaux = niveau moyen du starter devant Pierre mesuré par `tools/simulate_brock.gd` (route + Liam) ; prendre le détour pour arriver à ces niveaux devant Pierre |
| `brock_squirtle.json` | J10 (T16) : même départ, Carapuce N12 et Roucool N10 (rival : Bulbizarre), 3 Potions |
| `brock_bulbasaur.json` | J10 (T16) : même départ, Bulbizarre N12 (sans Fouet Lianes, appris au N13) et Roucool N10 (rival : Salamèche), 3 Potions |
| `brock_kevin.json` | J10 (T16) : **la vraie équipe de Kevin** en fin de J9 (QA T22) après la Route 2 nord : Salamèche N11 (Griffe, Rugissement, Flammèche) en tête, Roucool N9, Chenipan N6 et N5, Rattata N3, Nidoran♂ N3, 1 Potion, 3 Antidotes, 2 Poké Balls, 1 396 ₽ (4 Potions achetables à la Boutique). Les IV de la vraie partie (Salamèche : Attaque et Att. Spé. à 1) ne sont pas reproduits : `DebugStart` les tire |
| `badge_after.json` | J10 (T8) : Badge Roche obtenu (`badge_boulder`, `brock_met`, Liam battu), dans l'Arène (spawn `entrance`) : réactions au badge (guide, enfant, Dresseuse, Montagnard), allusion de Pierre au rival, objectif « continuer vers la Route 3. », garde de la Route 3 qui se décale. **Aucun Grand moment « badge »** (il est enregistré par l'étape `badge` de la vraie scène, T9) |
| `status_qa.json` | J11 (11A, T9) : QA des statuts **sans carte de QA** (écart au plan : clé `wild`). Route 1 (spawn `from_pallet_w`), fin du J9 (`poison_unlocked`). Équipe : Salamèche N18 (Flammèche : brûlure), Papilusion N17 (Choc Mental, Poudre Toxik, Para-Spore, Poudre Dodo), Nidoran♂ N16 (Puissance, Double Pied), Rattata N16 **brûlé** (Croc de Mort, Croc Fatal), Pikachu N14 **endormi 3 tours** (clé de membre `status_turns`), Roucool N12 **paralysé** (Frappe Atlas) ; Piafabec N10 **gelé** au Stockage. Sac : 10 Potions, 5 Poké Balls, 3 de chaque remède, 2 Antigels ; 5 000 ₽. Clé **`wild`** : les herbes de la Route 1 donnent, pour la session, Pikachu N12 (Cage-Éclair), Papilusion N17 (Para-Spore, Poudre Dodo, Choc Mental), Dardargnan N16 (Furie, Puissance), Rattata N14 (Croc de Mort), taux 60. Rien n'est sauvegardé |
| `route_25.json` | J14 (T14) : Badge Roche obtenu, Charmander N22, Papilusion N20, Roucool N18, 10 Poké Balls, 6 000 ₽, à l'entrée ouest de la Route 25 (spawn `from_route_24_c`, tourné vers l'est). Sans PNJ ni rencontres jusqu'au T16 ; le raccord ouest affiche « Route 24 — À venir » jusqu'au T15 |
| `route_25_cape.json` | J14 (T14) : même partie, devant la maison de Léo (spawn `from_bill_house_w`, tourné vers le nord : un pas en haut pour entrer) |
| `bill_house.json` | J14 (T14) : même partie, dans la maison de Léo sur le paillasson (spawn `from_route_25`, tourné vers le nord). Sans PNJ avant le T17 ; les drapeaux `bill_met`, `bill_in_cabin` viendront avec eux |

La carte de QA `qa_forest_systems` (J9, T6) et ses données ont été **retirées à la clôture du
J9 (T23)** ; les départs qui s'en servaient sont rebasés ci-dessus sur le poste sud et la vraie
forêt.

## Déblocages du Menu Dresseur (jalon 6 T2)

`tools/deploy_s24.sh --debug-unlock pokedex` dépose `user://debug_unlocks.json`
(`{ "pokedex": true }`, lu par `DebugUnlocks`, `game/systems/debug/debug_unlocks.gd`) : l'écran
Pokédex existe **sans** que le drapeau d'histoire `pokedex_activated` soit posé ; rien n'est
sauvegardé. Même garde que le départ de débogage (build debug, Boot scène principale, fichier
présent). Se combine avec `--debug-start` ou avec la vraie partie ; sans l'option, le fichier est
retiré. Sur le Mac : `echo '{ "pokedex": true }' > "$HOME/Library/Application Support/Godot/app_userdata/Kanto 2026/debug_unlocks.json"`.
