# Départs de débogage (jalon 5 T9)

Parties prêtes à jouer, construites par `DebugStart` (`game/systems/debug/debug_start.gd`,
format décrit en tête du fichier) au lieu de la nouvelle partie. **Désactivé par défaut.**

Le jeu lit `user://debug_start.json` seulement si :
- c'est un **build debug** (jamais dans un export release) ;
- `Boot` est la **scène principale** lancée par le moteur (jamais sous GUT ni dans un outil) ;
- le fichier **existe**.

Clé **`wild`** (J11) : table forcée sur la carte de départ pour la session. **J12 (T20)** : elle
accepte `"terrain": "rubble"` pour forcer les **gravats** d'un étage du Mont Sélénite (défaut :
`"grass"`, les herbes) ; ex. `"wild": { "terrain": "rubble", "rate": 200, "slots": [ … ] }`.

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
| `daycare_v7_qa.json` | J15 (15.0, T2/T3) : Salamèche N12, Roucool N9, Chenipan N5 au Stockage, et **Rattata N10 à la Pension avec 500 XP en attente** (clé `daycare` : un membre + `pending_exp`), 3 000 ₽, devant la porte du Centre de Jadielle (spawn `from_center`). **Clé `autosave: true` : ce départ REMPLACE `user://save.json`** (copier d'abord la vraie sauvegarde). Relancer ensuite **sans** départ : le journal affiche « [qa] pension relue : Rattata N10 (dépôt N10), 500 XP en attente, uid … » et `save.json` contient `"daycare"` (version 7). Aucune Pension visible en jeu avant le T4 |
| `s2_save.json` | Passe systèmes 2 (S2A, T5) : copie de `route_3.json` (fin du J10, Reptincel N17 compagnon, Papilusion N15, Roucool N14, 5 Poké Balls, 5 Potions, 2 Antidotes, 4 300 ₽, entrée ouest de la Route 3) **avec `autosave: true` : ce départ REMPLACE `user://save.json`** (copier d'abord la vraie sauvegarde). Retirer ensuite `files/debug_start.json` pour que chaque relance lise la sauvegarde. Hugo (goulet, inévitable) : dialogue + combat ; herbes H4 ; Argenta à l'ouest : changement de carte. Interruptions réelles pendant un dialogue, un combat, une scène ; le journal affiche « [save] point de reprise : … µs » et « Sauvegarde du point de reprise (…) » |
| `route_5.json` | J15 (T13) : Rocket d'Azuria battu et barrage levé (`cerulean_south_guard_left`), **sans** Passe Bateau, Salamèche N22, Papilusion N20, Roucool N18, 3 000 ₽, à l'entrée nord de la Route 5 (spawn `from_cerulean_c`, tourné vers le sud) : Pension (porte (27, 27)), poste nord (T-15 puis T-16, recul), entrée du souterrain (bâtiment puis escalier vers `underground_path`), Super Potion (11, 15), Antidote caché (tronc, (16, 31)) ; un pas vers le nord : Azuria |
| `companion_qa.json` | J11 (11D, T20d/T21) : QA du compagnon. Jadielle, devant le Centre (spawn `from_center`, tourné vers le sud), fin du J9 (`poison_unlocked`, Dresseurs de la forêt pas battus). Équipe : **Salamèche N15 à 1 XP du N16, compagnon** (clé `companion` : place dans l'équipe ; il évolue au premier combat gagné et Reptincel, qui a sa planche depuis le 2026-10-13, reste compagnon), Roucool N12, Rattata N10 **K.O.** (éligible : reste invisible), Nidoran ♂ N11 **empoisonné** (« … », phrase « pas dans son assiette »), Nidoran ♀ N9 à 4 PV (« fatiguée »), Chenipan N6 (aucun bouton). 10 Potions, 3 Antidotes, 10 Poké Balls, 3 000 ₽. Parcours : Jadielle (« passants », Centre, Boutique), Route 1 (rebords), Bourg Palette (l'étang : « regarde l'eau »), Route 2, Forêt de Jade (« forêt », Dresseurs), Argenta |
| `route_3.json` | J12 (T18, session 12A) : fin du J10 (Badge Roche, garde de la Route 3 décalé), **Reptincel N17 compagnon** (clé `companion`), Papilusion N15, Roucool N14, 5 Poké Balls, 5 Potions, 2 Antidotes, 4 300 ₽, à l'entrée ouest de la Route 3 (spawn `from_pewter_c`, tourné vers l'est). Premier pas : objectif « traverser le Mont Sélénite. » (en silence). Aucun Dresseur battu, aucun objet ramassé : Hugo (goulet, inévitable), embranchement nord (Sacha) / sud (Enzo), Inès (poche du sud, Poké Ball), Réveil caché face au caillou (36, 18) depuis le sentier du rebord, Léa (goulet de la jonction, inévitable), H4, plateau du Centre (Potion), Nolan (Anti-Para) |
| `mt_moon_center.json` | J12 (T18) : même partie, `route_3_entered` posé, dans le Centre du Mont Sélénite (spawn `entrance`, tourné vers le nord), Reptincel N18 à 20 PV, **Papilusion N16 K.O.**, Roucool N15 : monter au comptoir, SOIGNER → toast « Point de repos enregistré — Mont Sélénite » ; terminal de Stockage à gauche ; sortie → Route 3 devant la porte |
| `mt_moon_1f.json` | J12 (T21, session 12B) : **entrée du Mont Sélénite 1F** (spawn `from_route_3_w`, tourné vers le nord), fin du J10 + Route 3 entrée (Hugo et Léa battus). Équipe : Reptincel N18, **Rondoudou N14 compagnon** (clé `companion` : 1), Nosferapti N12, Roucoups N18, Racaillou N12 (les trois derniers ont aussi leur planche de compagnon : les choisir depuis l'Équipe). 10 Poké Balls, 5 Potions, 2 Antidotes, 1 Anti-Para, 1 Réveil, 3 000 ₽. Clé **`wild`** + `"terrain": "rubble"` : les gravats du 1F gardent la table réelle (Nosferapti, Racaillou, Paras, Mélofée) mais au **taux 60** (au lieu de 25) pour vérifier vite l'éboulis ; le sol calme ne déclenche rien. Randonneur au puits de jour, panneau, camp (caisses R, lampe), Corde au sol (9, 29), Réveil caché (indice (57, 19), à examiner depuis (56, 19)) |
| `mt_moon_b1f.json` | J12 (T21) : même partie, **B1F à l'arrivée de l'échelle A** (avant le guetteur R1, inévitable depuis le T25 : sa vue (14, 2..6) coupe la salle), Corde du 1F ramassée (1 Corde au Sac), **Nosferapti compagnon** (en vol). Potion au sol (16, 21) dans la galerie de la fouilleuse |
| `mt_moon_b2f.json` | J12 (T21) : même partie un peu plus haut (Reptincel N19…), **B2F à l'arrivée de l'échelle D** (avant le gardien R3 (29, 24), inévitable dans le couloir des lampes, puis le chercheur au bas du couloir, T25), Corde et Potion ramassées, **Racaillou compagnon** (planche de marche `geodude_walk`) |
| `escape_rope_qa.json` | J12 (T21) : **1F, arrivée de l'échelle A** (galerie ouest, loin de l'entrée), **3 Cordes Sortie**, Reptincel N18 à 20 PV (le soin ne change pas après la Corde), **Abo compagnon**, Roucoups N17. Corde depuis le Sac : 1F, puis redescendre et l'utiliser en B1F / B2F → devant l'entrée côté Route 3, tourné vers le sud, une Corde de moins ; refus sur la Route 3 et au Centre |
| `mt_moon_weak.json` | J12 (T25, session 12C) : **B1F à l'arrivée de l'échelle A**, Salamèche **N4** seul (Rugissement seulement, pour perdre), 2 Poké Balls, 1 Corde. Marcher vers l'est sur la rangée 4 : le guetteur R1 (14, 1) voit le joueur en (14, 4) → « Hé, toi ! Ce passage est interdit. Fais demi-tour. » → défaite → réveil chez Maman (aucun Centre enregistré, comme `rival_2_weak`) ; R1 reste à son poste ; revenir (ou relancer `mt_moon_b1f` avec une sauvegarde) : « Encore toi ? Demi-tour. » || `mt_moon_weak.json` | J12 (T25, session 12C) : **B1F à l'arrivée de l'échelle A**, Salamèche **N4** seul (Rugissement seulement, pour perdre), 2 Poké Balls, 1 Corde. Marcher vers l'est sur la rangée 4 : le guetteur R1 (14, 1) voit le joueur en (14, 4) → « Hé, toi ! Ce passage est interdit. Fais demi-tour. » → défaite → réveil chez Maman (aucun Centre enregistré, comme `rival_2_weak`) ; R1 reste à son poste ; revenir (ou relancer `mt_moon_b1f` avec une sauvegarde) : « Encore toi ? Demi-tour. » |
| `mt_moon_fossil.json` | J12 (T25) : **B2F au pied de l'échelle de sortie** (spawn `arrivee_s` (11, 30), tourné vers l'est), R1, R2, R3 et le **chercheur battus** (il est rangé en (15, 30) : « Sans toi, ils les auraient emportés. / Un fossile chacun. Choisis. »), **choix du fossile à faire** : aller face à la dalle depuis (24, 30) ou (24, 32) (Dôme) ou (26, 30) / (26, 32) (Nautile) → EXAMINER → « Prendre le … ? » OUI / NON ; NON : rien ; OUI : toast « … — obtenu », l'autre disparaît, « Alors je garde celui-ci. / Prends-en soin. », Grand moment (écran Dresseur). Équipe de fin de grotte, **Racaillou compagnon**, 1 Pierre Lune (celle du B1F) ; la Pierre Lune cachée (indice (36, 12), depuis (35, 12)) et la CT01 (4, 5) restent à prendre || `mt_moon_fossil.json` | J12 (T25) : **B2F au pied de l'échelle de sortie** (spawn `arrivee_s` (11, 30), tourné vers l'est), R1, R2, R3 et le **chercheur battus** (il est rangé en (15, 30) : « Sans toi, ils les auraient emportés. / Un fossile chacun. Choisis. »), **choix du fossile à faire** : aller face à la dalle depuis (24, 30) ou (24, 32) (Dôme) ou (26, 30) / (26, 32) (Nautile) → EXAMINER → « Prendre le … ? » OUI / NON ; NON : rien ; OUI : toast « … — obtenu », l'autre disparaît, « Alors je garde celui-ci. / Prends-en soin. », Grand moment (écran Dresseur). Équipe de fin de grotte, **Racaillou compagnon**, 1 Pierre Lune (celle du B1F) ; la Pierre Lune cachée (indice (36, 12), depuis (35, 12)) et la CT01 (4, 5) restent à prendre |
| `moon_stone_qa.json` | J12 (T25, session 12C, évolution par pierre) : Centre du Mont Sélénite, **2 Pierres Lune**, équipe Reptincel N20, **Nidorina N18, Nidorino N18, Mélofée N15, Rondoudou N15**, Nosferapti N14 (Mélofée compagnon). Sac → Pierre Lune → UTILISER : COMPATIBLE pour les quatre, INCOMPATIBLE pour Reptincel et Nosferapti ; évolution sans ARRÊTER, retour Android sans effet, une pierre de moins à chaque fois || `moon_stone_qa.json` | J12 (T25, session 12C, évolution par pierre) : Centre du Mont Sélénite, **2 Pierres Lune**, équipe Reptincel N20, **Nidorina N18, Nidorino N18, Mélofée N15, Rondoudou N15**, Nosferapti N14 (Mélofée compagnon). Sac → Pierre Lune → UTILISER : COMPATIBLE pour les quatre, INCOMPATIBLE pour Reptincel et Nosferapti ; évolution sans ARRÊTER, retour Android sans effet, une pierre de moins à chaque fois |
| `route_4.json` | J12 (T28, session 12D) : **sas de la Route 4** à l'arrivée de l'échelle de sortie (spawn `from_mt_moon` (3, 6), tourné vers l'est), tout le Mont Sélénite fait (R1–R3 et chercheur battus, **Fossile Dôme** choisi, sans Grand moment). Équipe : Reptincel N21 (compagnon), Rondoudou N17, Nosferapti N16, Roucoups N19, Racaillou N15. Un pas vers l'est (colonne 4) → `route_4_reached` en silence, objectif « continuer vers Azuria. » ; panneau (6, 5) lu depuis (6, 6) ; raccord est → « AZURIA — À venir » (debug) ; bouche (2, 6) → B2F, échelle de sortie → retour au sas. || `route_4.json` | J12 (T28, session 12D) : **sas de la Route 4** à l'arrivée de l'échelle de sortie (spawn `from_mt_moon` (3, 6), tourné vers l'est), tout le Mont Sélénite fait (R1–R3 et chercheur battus, **Fossile Dôme** choisi, sans Grand moment). Équipe : Reptincel N21 (compagnon), Rondoudou N17, Nosferapti N16, Roucoups N19, Racaillou N15. Un pas vers l'est (colonne 4) → `route_4_reached` en silence, objectif « continuer vers Azuria. » ; panneau (6, 5) lu depuis (6, 6) ; raccord est → « AZURIA — À venir » (debug) ; bouche (2, 6) → B2F, échelle de sortie → retour au sas. Depuis la fusion dans le J13, sur la vraie Route 4 (mêmes coordonnées à l'ouest). |
| `cerulean_city.json` | J13 (T17) : fin du J12 supposée (Badge Roche, Argenta atteinte ; Salamèche N20, Papilusion N18, Roucool N18, 3 000 ₽, 5 Poké Balls, 5 Potions, 1 Antidote), à l'arrivée d'Azuria (spawn `from_route_4_c`), `cerulean_reached` posé : habitants, indices du cambriolage, Centre (point de repos), Boutique (VENDRE), vélos, maison, Arène (Lucas, Diane, guide). Retirer `cerulean_reached` du fichier pour rejouer l'arrivée (titre, Grand moment) |
| `rival_cerulean.json` | J13 (T19) : même partie que `cerulean_city`, Salamèche N22, Papilusion N20, Roucool N20, 3 000 ₽, 5 Poké Balls, 5 Potions, au bas du couloir de la Route 24 (spawn `from_cerulean_c`, tourné vers le nord) : le premier pas sur la rangée 55 déclenche le rival n° 3 (vue de 5 cases, inévitable). Victoire : réplique n° 32, départ, puis la scène d'Ondine au pont enchaînée |
| `rival_cerulean_weak.json` | J13 (T19) : Salamèche **N5** seul, sans Sac, 3 000 ₽, même endroit : perdre contre le rival → réplique n° 29, réveil au dernier Centre (chez Maman tant qu'aucun Centre n'est enregistré), argent intact ; au retour, n° 30 puis n° 31 |
| `misty_pending.json` | J13 (T19) : `rival_cerulean_won` et `rival_cerulean_lost_once` posés, **`misty_invited` absent** (partie quittée entre les deux scènes), même endroit : le rival est parti, Ondine attend au pied du pont ; le premier pas sur la place (rangée 53) ou lui parler joue la scène d'invitation |
| `cerulean_gym.json` | J13 (T19) : rival vaincu, `misty_invited` posé, à l'entrée de l'Arène d'Azuria (spawn `entrance`, tourné vers le nord) : Ondine est au fond (carte « ONDINE », combat avec changement de Pokémon, badge, CT11). Lucas et Diane non battus |
| `cascade_no_tm.json` | J13 (T19) : `badge_cascade` et `misty_met` posés **sans `tm11_received`** (partie badgée avant la CT11), dans l'Arène : lui parler joue le rattrapage (« J'allais oublier. »), une seule fois |
| `nugget_bridge.json` | J13 (T22) : fin de l'Arène (Badge Cascade, CT11 reçue, rival et Ondine faits), Reptincel N26, Papilusion N22, Roucoups N22, au **pied du Pont Pépite** (spawn `bridge_foot` (32, 46), tourné vers le nord) : panneau (34, 45) lu depuis (34, 46) ; le premier pas sur la file ouest (32, 44) déclenche Timéo (P1) ; les cinq Dresseurs sont inévitables, dans l'ordre P1 → P5 ; objectif « traverser le Pont Pépite. » |
| `nugget_rocket.json` | J13 (T22) : même partie, P1 à P5 battus, en haut du pont (spawn `bridge_top` (33, 26)) : monter jusqu'à la rangée 23 déclenche le recruteur (félicitations, Pépite, proposition OUI / NON, combat Abo N15 / Nosferapti N15) |
| `route_24_north.json` | J13 (T22) : recruteur battu et Pépite au Sac, sur la rive nord (spawn `north_land` (33, 17)) : prairies H1 (21, 12) et H2 (43, 13), Potion (44, 3), Antidote caché (souche (16, 6), à examiner depuis (16, 7)), raccord est « ROUTE 25 — À venir » ; objectif « explorer les environs d'Azuria. » |
| `nugget_sell.json` | J13 (T22) : même partie, devant la Boutique d'Azuria (spawn `from_mart`) avec **1 Pépite** : VENDRE → 5 000 ₽ |
| `route_25.json` | J14 (T14) : Badge Roche obtenu, Charmander N22, Papilusion N20, Roucool N18, 10 Poké Balls, 6 000 ₽, à l'entrée ouest de la Route 25 (spawn `from_route_24_c`, tourné vers l'est). Sans PNJ ni rencontres jusqu'au T16 ; le raccord ouest affiche « Route 24 — À venir » jusqu'au T15 |
| `route_25_cape.json` | J14 (T14) : même partie, devant la maison de Léo (spawn `from_bill_house_w`, tourné vers le nord : un pas en haut pour entrer) |
| `bill_house.json` | J14 (T14) : même partie, dans la maison de Léo sur le paillasson (spawn `from_route_25`, tourné vers le nord). Léo-Mélofée y attend (T17) : partie complète de la scène, depuis l'accueil |
| `route_6.json` | J15 (T14) : même partie que `route_25.json` (Charmander N22, Papilusion N20, Roucool N18), à la sortie du bâtiment du souterrain de la Route 6 (spawn `from_underground`, tourné vers le sud) : Chloé juste devant |
| `vermilion.json` | J15 (T14) : même partie, à l'entrée nord de Carmin-sur-Mer (spawn `from_route_6_c`, tourné vers le sud) |
| `route_11.json` | J17 (T17) : même partie que `vermilion.json`, à l'arrivée de Carmin sur la Route 11 (spawn `from_vermilion_c`, tourné vers l'est) : Arthur dans le goulet |
| `route_9.json` | J18 (T18) : sortie du J16 plausible (Badges Roche et Cascade, Passe Bateau, Reptincel N25, Roucoups N22, Férosinge N22, Ortide N21, 3 Potions, 2 Super Potions, 2 Antidotes, 6 000 ₽), à l'arrivée d'Azuria sur la Route 9 (spawn `from_cerulean`, tourné vers l'est). Le raccord Azuria ↔ Route 9 attend la Coupe du J16 : ce départ le remplace. Le premier pas vers l'est pose `route_9_entered` (objectif « traverser la Route 9 vers l'est. ») ; Lou voit le joueur au goulet |
| `route_10_center.json` | J18 (T18) : même partie, `route_9_entered` et `route_10_reached` posés, dans le Centre de la Route 10 (spawn `entrance`, tourné vers le haut), Reptincel à 12 PV et Roucoups K.O. : SOIGNER → toast « Point de repos enregistré — Route 10 » ; une défaite ramène ensuite à ce Centre |
| `route_5_daycare.json` | J15 (T15/T20, session 15A) : **vraie Pension** (`route_5_daycare`, spawn `counter` devant le comptoir, tourné vers le gardien), Pension vide, **Miaouss N17 compagnon** (Jackpot), Salamèche N22, Roucool N18 **K.O.** (déposable), 3 000 ₽ : déposer Miaouss → T-6, plus de compagnon dehors |
| `route_5_daycare_last.json` | J15 (15A) : même Pension, Miaouss N17 **seul en forme** (Salamèche et Roucool K.O.) : sa carte est refusée (T-5) dans le sélecteur, un K.O. se dépose |
| `route_5_daycare_ready.json` | J15 (15A) : même Pension, **Salamèche N14 gardé** (1 PV, empoisonné, 4 capacités) + 950 XP → N16 : T-8 « 300 ₽ », Groz'Yeux au N15 → écran d'oubli (refus possible), **évolution en Reptincel proposée et annulable**, rendu soigné ; équipe Papilusion N20, Roucool N18, Miaouss N17 compagnon ; 5 000 ₽. En sortant : les pas comptent (marche et course) |
| `route_5_pay_day.json` | J15 (15B, Jackpot) : Route 5 (spawn `from_cerulean_c`), **Miaouss N17 en tête** (Griffe, Rugissement, Morsure, **Jackpot**) et compagnon, table forcée Rattata N4 (taux 255) : chaque pas dans H1 (24..28, 8..13) lance un combat ; Jackpot → « Des pièces s'éparpillent partout ! » puis « Tu ramasses … » après la victoire |
| `route_6_basile.json` | J15 (15B) : Route 6, au **belvédère** (spawn `belvedere` (34, 44), tourné vers le nord), les cinq autres Dresseurs battus : un pas vers le nord → Basile (Papilusion N20 : Poudre Toxik, Para-Spore, Poudre Dodo) ; 2 Anti-Para, 2 Réveil au Sac ; la Poké Ball (38, 41) au fond du belvédère |
| `vermilion_ss_ticket.json` | J15 (15B) : partie de `bill_after` (Léo aidé, **Passe Bateau** au Sac, `got_ss_ticket`), à l'entrée nord de Carmin : le marin dit T-26 **à l'identique**, embarquement inatteignable |
| `vermilion_dock.json` | J16 (embarquement) : partie de `vermilion`, **sans Passe Bateau**, sur le quai devant le marin (spawn `dock` (31, 24)) : TXT-02, la passerelle reste fermée |
| `vermilion_dock_ticket.json` | J16 (embarquement) : partie de `vermilion_ss_ticket` (Passe Bateau au Sac), sur le quai (spawn `dock`) : marin → TXT-01, il s'écarte en (30, 26), montée à bord |
| `bill_after.json` | J14 (T17) : même partie, Léo déjà aidé (`bill_restored`, `got_ss_ticket`, `got_bill_rare_candy`), Passe Bateau et Super Bonbon au Sac, sur le paillasson de la maison : Léo humain devant la cabine B |
| `rare_candy_qa.json` | J14 (T18b) : même partie que `bill_after` (maison de Léo), **5 Super Bonbons** : Abra N15 (bonbon → N16, n° 62, puis évolution en Kadabra **annulable** : ARRÊTER ou retour Android ; Choc Mental appris), Papilusion N20 à quatre capacités (→ N21 : Ultrason, écran « oublier une capacité »), Roucarnage **N100** (« Sans effet »), Rattata N12 **K.O.** (« Ce Pokémon est K.O. »), Salamèche N22. Sac → AVENTURE → Super Bonbon → UTILISER |
| `cerulean_garden.json` | J14 (T20b) : Badge Roche, Salamèche N22, Papilusion N20, Roucool N18, devant la clôture arrachée du jardin de la maison cambriolée (spawn `garden_start` (5, 2), tourné vers l'est) : le premier pas sur la colonne 7 lance la poursuite (« ! », n° 30), puis combat par la bande (17, 2..3) |
| `cerulean_rocket_weak.json` | J14 (T20b) : Rocket déjà repéré (`cerulean_rocket_spotted`), Salamèche **N5** seul, dans l'impasse (spawn `impasse_start` (16, 3)) : un pas à l'est = combat à perdre (réveil au Centre, retour : n° 32) |
| `cerulean_after.json` | J14 (T20b) : Rocket battu et CT28 reçue, devant la maison cambriolée (spawn `from_burgled_house`, tourné vers le nord) : la porte s'ouvre sur la victime ; le policier du sud est encore là (n° 41 en passant par la bande (31..33, 37)) |

## Jalon 17 — voile d'obscurité et Flash

Clé **`veil`** (J17 T9, `"dark"`, `"lit"` ou `"off"` (T25 : voile retiré), avec `map`) : voile d'obscurité **forcé sur la carte
de départ** pour la session (`"lit"` : halo de Flash ouvert), même hors d'une grotte obscure ;
jamais sauvegardé. Ex. sur le Mont Sélénite (qui n'a pas de voile en jeu) : ajouter
`"veil": "dark"` à `mt_moon_1f.json`.

La carte de QA `qa_flash` (grotte obscure) et sa pièce `qa_flash_entry`, leur outil, leurs grilles,
leur test et les départs `flash_qa*` ont été **retirés au T28** : le voile et Flash sont éprouvés
dans le vrai Boot sur la Cave Taupiqueur rendue obscure **en mémoire** par les tests
(`tests/helpers/dark_cave.gd`, `test_darkness_boot`, `test_flash_director`) ; captures :
`tools/capture_flash.sh` (voile posé sur la Cave). Au J18, les vraies grottes `"dark"` prennent
le relais (et la clé `veil` reste disponible).

La carte de QA `qa_charge_j14` (J14, T10), ses données, son outil de construction et de capture,
son test et les départs `charge_qa` et `teleport_qa` ont été **retirés au T24** (Tunnel, Téléport
et l'IA qui creuse sont couverts par les tests de combat ; Abra se rencontre sur la Route 25).

| `route_2_east.json` | J17 (T19) : **9 espèces capturées** (équipe de 6 : Salamèche N22, Roucool, Rattata, Piafabec, Nidoran♀, Férosinge ; stockage : Nidoran♂, Chenipan, Aspicot), Badge Roche, à la **bouche nord de la Cave** côté Route 2 est (spawn `from_cave_w`, tourné vers le sud). Poste à 12 pas ; l'assistant donne T-1 puis T-2 (9 espèces : pas de CS05) ; le goulet est fermé par l'arbuste (sans CS01 : « Un arbuste barre le passage. / Il faudrait savoir le couper. ») |
| `route_2_east_10.json` | J17 (T19) : comme `route_2_east` avec **10 espèces** (un Nosferapti au stockage) : l'assistant remet la CS05 (T-3) une seule fois, T-4 ensuite |
| `route_2_east_south.json` | J17 (T19, T20) : **derrière l'arbuste** du couloir (spawn `debug_south`, (6, 23)), 10 espèces : Pierre Lune (12, 26) et Super Bonbon (3, 33) ramassables, sentier ouest jusqu'à la barrière de FUTUR B (vue de l'est : T-8, elle s'ouvre). Raccourci : sans CS01 ni Badge Cascade, l'arbuste reste en place (retour au nord impossible ; dans le jeu, on y arrive en le coupant : `route_2_east_cut`) |
| `route_2_futur_a.json` | J17 (T21) : **dans la clairière de FUTUR A** de la Route 2 sud (spawn `debug_futur_a`, (2, 19), tourné vers l'ouest) : Super Potion en (1, 17) ; l'arbuste (4, 19) la ferme (raccourci sans CS01 ; dans le jeu, on y entre en le coupant : `route_2_futur_a_cut`) |
| `route_2_east_cut.json` | J17 (T23) : comme `route_2_east_south` (10 espèces), plus **CS01 et Badge Cascade** (drapeaux jusqu'à Azuria), **devant l'arbuste** du couloir, au nord (spawn `debug_bush`, (6, 20), tourné vers le sud) : « Salamèche peut couper cet arbuste. / Utiliser Coupe ? » → COUPER : « Salamèche utilise Coupe ! », l'arbuste disparaît **pour toujours** (`cut_route_2_east_bush`), le sud du couloir s'ouvre |
| `route_2_futur_a_cut.json` | J17 (T23) : même partie, Route 2 sud **devant l'arbuste de FUTUR A**, à l'est (spawn `debug_futur_a_bush`, (5, 19), tourné vers l'ouest) : COUPER → `cut_route_2_futur_a`, la clairière et sa Super Potion s'ouvrent. Sans CS01 : texte T7 du dossier 11 (« Les branches sont trop épaisses… ») ; avec CS01 sans Badge Cascade : texte du J16 |
| `cerulean_east_cut.json` | J18 (T15) : partie de `route_9` (sortie du J16 plausible, Reptincel N25 en tête) plus **CS01** et `got_hm01`, à Azuria **devant l'arbre à couper** de la sortie est (spawn `east_tree_start`, (52, 23), tourné vers l'est) : COUPER → `cut_cerulean_east_tree`, le raccord (55, 22..24) mène à la Route 9 |
| `route_10_south.json` | J18 (T24) : Badges Roche et Cascade, `route_9_entered`, `route_10_reached`, Charmeleon N24, Pikachu N20, Papilusion N20, Roucoups N19, à la **sortie sud de la Grotte Sombre** (spawn `from_dark_cave_s_w`, tourné vers le sud) : Hector et Paul facultatifs, Super Potion, objectif « Rejoindre Lavanville, au sud. » dès le premier pas ; Lavanville jamais découverte : la légende s'affiche à l'arrivée par le sud de la Route 10 |
| `lavender.json` | J18 (T24) : même partie + `dark_cave_crossed`, arrivée à Lavanville par le nord (spawn `from_route_10`, tourné vers le sud) ; **aucune légende** (départ de débogage) ; `lavender_reached` posé au premier pas vers le sud |
| `pokemon_tower_1f.json` | J18 (T24) : même partie + `lavender_reached`, dans la Tour Pokémon à l'entrée (spawn `entrance`, tourné vers le nord) : gardien, visiteurs, tombes, Exorciste devant l'escalier (T-34 puis T-35, objectif « Revenir plus tard à la Tour Pokémon. ») |
| `dark_cave_1f.json` | J18 (T20) : Pikachu N20, Reptincel N22, Roucarnage N19, **sans CS05** (Flash indisponible), 5 Potions, 2 Super Potions, 2 Antidotes, 2 Cordes Sortie, à l'entrée nord de la Grotte Sombre (spawn `from_route_10_n_w`, tourné vers le sud) : voile sombre et « Il fait très sombre ici… » une fois |
| `dark_cave_1f_flash.json` | J18 (T20) : comme `dark_cave_1f` avec la **CS05** au Sac et Pikachu (compatible) : Flash automatique à l'entrée, « Pikachu utilise Flash ! » |
| `dark_cave_b1f.json` | J18 (T20) : comme `dark_cave_1f_flash`, à l'arrivée de l'échelle A du B1F (spawn `arrivee_a`) : colonne, flaque, passage étroit (Marcel), racines (Super Potion cachée). L'arrivée de l'échelle B (`arrivee_b`, côté Marcel) n'a pas de départ : copier le fichier et changer `spawn` (QA du 2026-10-19) |

La carte de QA `qa_switch_j13` (J13, T14), ses données, son outil de construction et de capture,
son test et le départ `switch_qa` ont été **retirés au T22** (les Dresseurs qui changent de
Pokémon se vérifient sur la vraie partie : rival n° 3 et Ondine).

La carte de QA `qa_forest_systems` (J9, T6) et ses données ont été **retirées à la clôture du
J9 (T23)** ; les départs qui s'en servaient sont rebasés ci-dessus sur le poste sud et la vraie
forêt.

## Jalon 16 (T16) : départs de la Coupe et du départ du navire

Écrits sur les cartes de QA `qa_dock_j16`, `qa_ship_j16`, `qa_gym_j16`, **retirées au T20** (avec
leurs PNJ, dialogues, scènes, le puzzle `qa_vermilion_gym`, le Major Bob d'essai et les objets
dessinés en code `qa_cut_tree` / `qa_barrier`) ; ces départs sont rebasés sur les vraies cartes :
l'arbuste `gym_tree` devant l'Arène de Carmin (spawn `gym_tree`, drapeau `cut_vermilion_gym_bush`)
et le pont principal du S.S. Anne (spawn `from_ss_anne_w`, sortie par la passerelle). Le départ
`vermilion_gym` (Arène d'essai) est retiré : `vermilion_gym_map` le remplace. Équipe des départs
`cut_*` : Pikachu N22 (compagnon dans `cut_ready`, **incompatible**), Sabelette N20, Mystherbe
N20, Reptincel N24.

| Fichier | Partie |
|---|---|
| `cut_no_hm.json` | Devant l'arbuste de Carmin (spawn `gym_tree`), Badge Cascade, **sans CS01** : « Un arbuste barre le passage. / Il faudrait savoir le couper. » (ARB-00) |
| `cut_no_badge.json` | CS01, **sans Badge Cascade** : ARB-01 nomme Sabelette, sans choix |
| `cut_no_pokemon.json` | CS01 et Badge Cascade, Carapuce + Pikachu (**incompatibles**) : ARB-02, sans choix |
| `cut_ready.json` | CS01, Badge Cascade, équipe mixte : « Sabelette peut couper cet arbuste. / Utiliser Coupe ? » → COUPER / LAISSER ; COUPER : « Sabelette utilise Coupe ! », l'arbuste disparaît **pour toujours** (`cut_vermilion_gym_bush`), la porte de l'Arène s'ouvre au nord |
| `ss_anne_free_exit.json` | Sur le pont principal, **sans CS01** : descendre par la passerelle → TXT-03 une fois, puis sortie libre vers le quai de Carmin |
| `ss_anne_exit.json` | **16D, validé seul.** CS01 en poche, devant la sortie : PARTIR / PAS ENCORE. PAS ENCORE : « Prends ton temps… », un pas en arrière. PARTIR : fondu vers le quai, **écriture immédiate**, légende « Le S.S. Anne quitte Carmin. », le navire s'éloigne, passerelle fermée (« Le S.S. Anne a pris le large. »). **Clé `autosave: true` : ce départ REMPLACE `user://save.json`** (copier la vraie sauvegarde avant). Arrêt brutal (forcer l'arrêt Android) pendant la confirmation → relance à bord ; après la légende → relance au quai, navire parti, spectacle non rejoué |

## Jalon 16 (T11) : les vraies cartes du S.S. Anne et de l'Arène (décor provisoire)

Tant que Carmin n'y mène pas (embarquement au T15, porte de l'Arène au T14), on y entre par ces
départs. Sans PNJ à bord (T12, T13) ; dans l'Arène, seule la barrière (T14 : Major Bob, Dresseurs,
guide).

| Fichier | Partie |
|---|---|
| `ss_anne.json` | Sur le **pont principal**, en haut de la passerelle (spawn `from_ss_anne_w`, tourné vers le nord), Passe Bateau, Badge Cascade, équipe N20–24 (celle de `ss_anne_free_exit`) : les 9 pièces reliées (portes du nord : cabines A, C, couloir et cabine du capitaine ; ouest : restaurant ; est : pont extérieur ; escalier sud-est : pont inférieur et cabine B) ; la passerelle ramène au quai de Carmin |
| `vermilion_gym_map.json` | Dans la **vraie Arène de Carmin** (spawn `entrance`), arbuste coupé : le puzzle `vermilion_gym` (GYM-01 à GYM-04, journal `[qa] puzzle …`), barrière de 3 segments ; la sortie ramène devant l'Arène à Carmin. Équipe Sablaireau N26 (Tunnel), Racaillou N24, Herbizarre N24, Roucoups N22 ; 3 Super Potions, 3 Anti-Para. Depuis le T14 : Louis, Axel, Marc (évitables), le guide, Major Bob derrière la barrière |
| `vermilion_gym_solved.json` | J16 (T14) : même partie, **puzzle résolu** (`vermilion_gym_puzzle_solved`) : barrière absente, Louis, Axel et Marc pas battus ; monter jusqu'à (8, 4) et parler à Major Bob (carte « MAJOR BOB », combat, « BADGE FOUDRE », CT24) |
| `surge_weak.json` | J16 (T14) : puzzle résolu, Salamèche **N6** seul, CS01 seule au Sac : perdre contre Major Bob (n° 37, réveil au dernier Centre enregistré : **chez Maman** dans ce départ, aucun Centre n'étant enregistré ; le Centre de Carmin est couvert par `test_vermilion_gym_sequence`), barrière toujours ouverte, reprise n° 38 sans carte |
| `thunder_no_tm.json` | J16 (T14) : Badge Foudre **sans** `tm24_received` (partie d'avant la CT) : parler à Major Bob donne la CT24 une fois (n° 43 puis 42), ensuite n° 44 |

La carte de QA `qa_moves_j12` (J12, T15) ses données, son outil et les départs `moves_qa` /
`moves_qa_solo` ont été **retirés au T28 du J12** (les capacités du J12 se vérifient sur la vraie
grotte : départs `mt_moon_*`).

## Déblocages du Menu Dresseur (jalon 6 T2)

`tools/deploy_s24.sh --debug-unlock pokedex` dépose `user://debug_unlocks.json`
(`{ "pokedex": true }`, lu par `DebugUnlocks`, `game/systems/debug/debug_unlocks.gd`) : l'écran
Pokédex existe **sans** que le drapeau d'histoire `pokedex_activated` soit posé ; rien n'est
sauvegardé. Même garde que le départ de débogage (build debug, Boot scène principale, fichier
présent). Se combine avec `--debug-start` ou avec la vraie partie ; sans l'option, le fichier est
retiré. Sur le Mac : `echo '{ "pokedex": true }' > "$HOME/Library/Application Support/Godot/app_userdata/Kanto 2026/debug_unlocks.json"`.

## Jalon 19 (T14) : départs de la Tour Pokémon (QA 19A)

Même partie que `pokemon_tower_1f` (Lavanville atteinte, `tower_stairs_open`), Centre de Lavanville **enregistré** (clé `rest_point`, J19 T14 : une défaite réveille là).

| Fichier | Partie |
|---|---|
| `tower_ghost_qa.json` | 3F, à l'arrivée de l'escalier (spawn `arrivee_T23`, tourné vers l'est). Équipe : Reptincel N24, Pikachu N20, **Rondoudou N15** (le plus lent), **Papilusion N20 endormi** (5 tours), Roucoups N19 ; 10 Poké Balls, Potions, Super Potions. Clé `wild` : table `floor` forcée (taux 255, Fantominus N20, `ghost_unless_item: silph_scope`) → un SPECTRE dès les premiers pas ; les 2 Exorcistes du 3F sont là (QA 19A n° 1 à 8) |
| `tower_exorcist_weak.json` | **4F**, à l'arrivée de l'escalier (spawn `arrivee_T34`, tourné vers l'ouest) : Salamèche **N6** seul (Rugissement), 2 Poké Balls. Deux pas vers l'ouest, Solange (E3, inévitable, (15, 7)) voit le joueur : perdre → réveil au Centre de Lavanville, Solange toujours à battre (QA 19A n° 9) |
| `tower_6f_block.json` | 6F, case `devant_spectre` (10, 14), tourné vers le sud : deux pas, le déclencheur (10, 16) joue §15.3.7 → combat SPECTRE → fuite → recul en (10, 15) → §15.3.8. **Rival n° 5 non battu** (`rival_tower_won` absent) : les drapeaux sont indépendants (dossier 22 §16 n° 10) |
| `tower_rival.json` | 2F, arrivée de l'escalier (spawn `arrivee_T12`, tourné vers l'ouest) : Salamèche N24, Pikachu, Rondoudou, Roucoups ; trois pas (haut, ouest, haut) jusqu'à (14, 6) lancent la scène du rival n° 5 |
| `tower_rival_weak.json` | idem, Salamèche **N5** seul : défaite → réveil au Centre de Lavanville |

## Jalon 20 (T17) : départs de la vie du 20-I (Routes 7 et 8, souterrain, Céladopole, Arène d'Erika)

Équipe de référence « arrivée J19 » : Reptincel N28, Roucoups N24, Papilusion N22, Sabelette N22 (apte à Couper avec la CS01), 10 Poké Balls, Potions, CS01 ; Badges Roche, Cascade, Foudre ; Lavanville atteinte ; 6 000 ₽. Centre de Lavanville enregistré (Céladopole : `celadon_center` pour les départs en ville). Les drapeaux d'arrivée `route_8_reached` / `celadon_reached` sont posés dès que le départ est plus loin que l'entrée.

| Fichier | Partie |
|---|---|
| `route_8.json` | bord est de la Route 8 (spawn `from_lavender_c`, tourné vers l'ouest) : Fillettes Nina et Joueur Fernand, puis le duo Iris / Margot (combats successifs), D3 et la Super Potion sur le chemin haut |
| `route_8_west.json` | place de l'ouest (spawn `west_square`, tourné vers l'est) : Joueur René (inévitable), poste de Safrania, couloir de l'entrée du souterrain |
| `underground_7_8.json` | entrée ouest du souterrain (spawn `from_route_7_n`, tourné vers l'est) : Pépite (niche) et Super Potion (coude) cachées |
| `route_7.json` | Route 7, sortie du bâtiment d'entrée du souterrain (spawn `from_underground`) |
| `celadon.json` | entrée est de Céladopole (spawn `from_route_7_c`, tourné vers l'ouest) : le Rappel caché de la ruelle (46, 27), les 14 PNJ |
| `celadon_dept.json` | RdC du grand magasin, 5 000 ₽, **Eau Fraîche** et **Soda Cool** : vendeurs, ascenseur, toit (distributeurs, fillette) |
| `celadon_dept_tm01.json` | 2e étage, **CT01 déjà au Sac** : la boutique des CT affiche « Déjà dans le Sac » |
| `celadon_eevee_full.json` | maison du toit de la Résidence, **équipe de 6** : Évoli part au Stockage (message n° 30) |
| `celadon_gym_outside.json` | devant l'arbuste de l'enclos de l'Arène (spawn `gym_front`, tourné vers l'ouest) : COUPER ouvre l'enclos |
| `celadon_gym.json` | à l'entrée de l'Arène, arbustes coupés : cinq Dresseuses, Erika |
| `erika_weak.json` | idem, Salamèche **N5** seul, les cinq Dresseuses déjà battues : perdre contre Erika → réveil au Centre de Céladopole, Dresseuses gardées |
| `erika_win.json` | idem, Reptincel **N40** et Roucoups **N36**, les cinq Dresseuses déjà battues : battre Erika → Badge Prisme, CT21 (QA 20-I, valeur par défaut) |

## Jalon 20 (T21) : départs de la vie du 20-II (Casino, repaire Rocket, Giovanni, Tour avec le Scope)

Même partie que `celadon.json` (équipe de référence « arrivée J19 », CS01, Badges Roche, Cascade, Foudre) avec `celadon_reached` ; Centre de Céladopole enregistré (défaite → réveil là). Chaque départ pose les étapes déjà franchies (Rocket de l'affiche battu, interrupteur, sbires des étages au-dessus battus).

| Fichier | Partie |
|---|---|
| `game_corner.json` | entrée du Casino (spawn `entrance`, tourné ↑) : Rocket de l'affiche (9, 5) à battre, cinq PNJ, machines, puis l'affiche et l'interrupteur (OUI / NON) |
| `rocket_hideout_b1f.json` | B1F, au pied de l'escalier du Casino (spawn `from_casino`) : trois sbires, Corde Sortie, Super Potion, Rappel caché (21, 15) lu depuis (20, 15) tourné → |
| `rocket_hideout_b2f.json` | B2F, arrivée nord (spawn `from_b1f_north`), sbires du B1F battus : **dalles tournantes** (labyrinthe ouest), sbire de la salle centrale, quatre objets |
| `rocket_hideout_b3f.json` | B3F (spawn `from_b2f`), B1F et B2F battus : dalles, deux sbires, Super Potion, Super Bonbon, Pépite cachée (27, 17) lue depuis (27, 16) tourné ↓ |
| `rocket_hideout_key.json` | B4F ouest (spawn `from_b3f`), **sbire de la Clé déjà battu** : lui reparler → la Clé tombe en (10, 2) |
| `rocket_hideout_lift.json` | B1F devant l'ascenseur (spawn `from_elevator`, tourné ↓), **Clé au Sac** : un pas vers le bas → cabine, panneau B1F / B2F / B4F |
| `giovanni.json` | B4F est, sortie de l'ascenseur (spawn `from_elevator`, tourné ↑), Clé au Sac, **gardes battus, porte ouverte** : Giovanni (25, 3), à aborder par le côté |
| `giovanni_weak.json` | idem, Salamèche **N5** seul : perdre → réveil au Centre de Céladopole, Clé et sbires battus gardés ; nouvel essai : n° 156 |
| `tower_scope.json` | Tour 3F (spawn `arrivee_T23`), **Scope Sylphe au Sac**, Giovanni battu : rencontres identifiées, le 6F reste un SPECTRE |

Les cartes de QA du J20 (`qa_gift_j20`, `qa_elevator_j20`, `qa_elevator_j20_1f` / `_2f`,
`qa_spin_j20`), leur outil `tools/build_qa_j20.gd`, leurs PNJ et les ascenseurs de test
(`tests/fixtures/elevators/`) ont été **retirés au T24** ; elles n'avaient aucun départ. Le don
d'Évoli, l'ascenseur et les dalles tournantes sont éprouvés sur les vraies cartes (maison du toit
de la Résidence, grand magasin et repaire Rocket : `test_eevee_gift`, `test_elevator_flow`,
`test_spin_slide`).

## Passe systèmes 2 (T9) : cartes de QA de la monture

Cartes `qa_mount` (extérieur : rebord rangée 14, maison, dormeur 2 × 1 qui ferme le nord),
`qa_mount_interieur` (refus du Vélo) et `qa_mount_piste` (`cycling_road`, pente, Dresseur de
l'alcôve), construites par `tools/build_qa_mount.gd` d'après `tools/plans/qa_mount*.txt`. Aucun
passage du jeu n'y mène. **Retirées à la clôture de la passe (S2Z)** avec leurs données `qa_mount*`.

| Fichier | Partie |
|---|---|
| `s2_bike.json` | Pikachu N12 (compagnon) et Roucool N12 **endormi** (`status: sleep`), Bicyclette et Poké Flûte au Sac (+ 10 Poké Balls, 5 Potions), 3 000 ₽, sur `qa_mount` (spawn `depart`, tourné vers le haut). Vélo : bouton du HUD / Sac, saut du rebord, refus dans la maison ; entrées de la Piste à l'est (19, 8) et (19, 16) : monté d'office, descente refusée, dérive sur la pente, le Gamin QA (Soporifik N8, Hypnose) voit la pente depuis son alcôve ; Flûte : à côté du dormeur (10..11, 4) réveil et passage au nord, en combat contre le Gamin QA réveil des endormis |
| `s2_surf.json` | Carapuce N20 (compatible CS03) et Pikachu N18 (compagnon 0), CS03 + 10 Poké Balls + 5 Potions au Sac, Badge Âme (`badge_soul`), sur `qa_sea` (spawn `depart` (2, 16), tourné vers le haut). Surf : montée depuis la plage, nage, descente sur l'îlot, rencontres `water`, courant (12..21, 4) puis (21, 4..9) jusqu'au passage (21, 10) → `qa_sea_2`, bord est (25, 11..14), Nageur QA (15, 13) (Poissirène N18, Kokiyas N20) qui voit vers l'ouest et nage vers le joueur |

## Passe systèmes 2 (`docs/tech/systemes-2.md`)

| Fichier | Partie |
|---|---|
| `s2_field_travel.json` | T25b : **Mont Sélénite 1F** (spawn `from_route_3_w`, tourné ↑), Centre du Mont Sélénite **enregistré** (clé `rest_point`). Équipe : Reptincel N18 à 20 PV, **Abra N15 (Téléport)**, **Taupiqueur N18 (Griffe, Tunnel)**. Menu → Équipe → Abra → onglet Capacités → Téléport → UTILISER : « Abra utilise Téléport ! », retour dans le Centre (point de réveil), **sans soin** (Reptincel toujours à 20 PV). Taupiqueur → Tunnel → UTILISER : « Taupiqueur creuse un tunnel ! », Route 3 devant la grotte (destination de la Corde Sortie). Tunnel hors grotte (Route 3) ou Téléport dans le Centre : « Impossible de l'utiliser ici. » dans le bandeau de l'Équipe |
## Passe systèmes 2 — S2G (T30, rencontre légendaire fixe)

| Fichier | Partie |
|---|---|
| `s2_legendary.json` | Route 1 (spawn `from_pallet_w`, tourné vers le nord), **Reptincel N36** et Roucool N10, 20 Super Balls, 10 Poké Balls, 5 Potions, drapeau de QA `qa_s2_legendary` : un **Mélofée N25 de QA** est juste devant le joueur (23, 41). OBSERVER → cri, combat à l'entrée « legendary » (1,5 × plus lente). **K.O.** ou **capture** → journal « [qa] point de sauvegarde sans écriture (écriture refusée pour la session) : rencontre fixe : qa_s2_legendary » **avant** le texte de QA qui suit, puis Mélofée quitte la carte (et n'y revient pas) ; **fuite** → rien, il reste. Relancer l'appli pour rejouer une autre issue |
| `s2_legendary_weak.json` | Même départ, **Salamèche N5 seul** : **défaite** → réveil chez Maman, aucun drapeau, pas de sauvegarde forcée ; Mélofée est toujours sur la Route 1 |

Le PNJ de QA (`data/npcs/route_1.json`), la scène et les textes `qa_s2_legendary` sont retirés à
la clôture de la passe (S2Z, T33).

## Jalon 21 (T12 à T14) : départs de la Tour résolue (QA 21A)

Équipe de référence [D, `jalon-21.md` §2.15] : Reptincel N33, Roucarnage N30, Papilusion N28 (Poudre Dodo), Évoli N25, Nidorino N28 **endormi** (`status_turns` 3), Sabelette N26 **empoisonné** ; 10 Poké Balls, 10 Super Potions, 3 Réveils, 2 Cordes Sortie, Scope Sylphe ; 5 000 ₽ ; Badge Prisme et drapeaux des J18 à J20 jusqu'au Scope ; Centre de Lavanville enregistré (`rest_point`).

| Fichier | Partie |
|---|---|
| `tower_marowak_qa.json` | 6F, `devant_spectre` (10, 14) tourné ↓, Exorcistes 8 et 9 et rival n° 5 battus, **Scope au Sac** : la scène d'Ossatueur (variante A, écrite après la fusion par la session parente) ; en attendant, le SPECTRE du J19 |
| `tower_marowak_noscope.json` | idem **sans** Scope (ni objet ni drapeau) : le SPECTRE du J19, inchangé (non-régression) |
| `tower_marowak_weak.json` | idem avec Salamèche N8 seul : défaite → Centre de Lavanville, déclencheur réarmé |
| `tower_7f_qa.json` | 7F, `arrivee_T67` tourné →, `ghost_marowak_calmed` et `tower_6f_mist_lifted` levés, **Sbires non battus** : monter vers Fuji (10, 3) |
| `fuji_flute_qa.json` | Maison des Pokémon, `devant_fuji` tourné ↑, `fuji_rescued` et Sbires battus, **sans Flûte** (cas « entre deux scènes ») : parler à Fuji, ou sortir et rentrer (déclencheur d'entrée) |
| `j21_full_qa.json` | Lavanville devant la Tour (`retour_tour`), Scope, **rien du J21 ni de la Tour du J19** : parcours complet |

## Jalon 21 (T22) : Route 16 est

| Fichier | Partie |
|---|---|
| `snorlax_16_qa.json` | Route 16, devant Ronflex (spawn `face_ronflex`, case (26, 22), tourné ←), **Poké Flûte** et **1 Poké Ball** au Sac, équipe de référence du J21 [D] (Reptincel N33, Roucarnage N30, Papilusion N28, Évoli N25, Nidorino N28 **endormi**, Sabelette N26 empoisonnée), Badges jusqu'au Prisme, Centre de Céladopole enregistré. Parler à Ronflex : « Jouer de la Poké Flûte ? » ; réveil, combat N30 ; **fuite** et **défaite** (une seule Ball) rejouables ; K.O. ou capture : le goulet s'ouvre sur la porte du poste (« Route 16 — à venir » en développement) ; `route_16_visited` : non posé par ce départ (il l'est en entrant par Céladopole) |
