# Jalon 26 — Safrania sous occupation (Safrania, Sylphe SARL, rival n° 6, Giovanni, Master Ball)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j26-v2-chatgpt.md` (7 arbitrages verrouillés par Kevin le 2026-10-19 ; ne pas
> les rouvrir). Plan écrit le 2026-10-21 (branche `plans-j26-j30`), en conception seulement
> (`strategie-acceleration.md`, levier 2). Il n'existe pas encore de dossier de conception numéroté
> pour le J26 : la passe en tient lieu.

> Objectif jouable sur le téléphone : **Safrania se libère.** Le joueur donne une boisson au garde
> d'un poste (J20) et entre dans une ville tenue par la Team Rocket. Il monte dans la **Sylphe SARL**,
> onze étages reliés par un ascenseur et des **téléporteurs**. Au 5e, il trouve la **Carte
> Magnétique**, qui ouvre les **portes électroniques**. Au 7e, il bat son **rival** (n° 6) ; un
> employé lui confie un **Lokhlass**. Au 11e, il bat **Giovanni** ; le président lui remet la
> **Master Ball**. Safrania est libérée ; l'Arène de Morgane devient accessible (J27).
>
> **Aucune mécanique nouvelle.** Tout repose sur des systèmes existants ou de la passe systèmes 2 :
> téléporteurs et portes à carte (S2F), ascenseur et don de Pokémon (J20), postes de Safrania (J20,
> T25), rival par starter (J4+), Champion et scène de combat (modèle d'Erika). Deux petits ajouts de
> données ou de moteur sont à vérifier au T4 : la **Master Ball** (capture garantie) et le
> **dialogue des postes du J15**.
>
> **Format de sauvegarde inchangé : v7** (drapeaux et objets seulement).

## 0. État et dépendances

### 0.1 Contrat d'entrée, relu sur le code (2026-10-21)

| Besoin | Où, état réel | Ce que fait le J26 |
|---|---|---|
| Postes de Safrania (boisson, `saffron_gates_open`) | `main` (J20 T25) : gardes des Routes 7 et 8, scènes `saffron_gate_drink_*`, variante `if_zone` ; mécanique **en sommeil** tant que `saffron_city` n'a pas de carte (`zones.json`, `"maps": []`) | Déclare les cartes de `saffron_city` dans `zones.json` : les postes s'ouvrent **sans code**. Relance `build_painted_interiors.gd --routes78` (warps `from_gate_r7`, `from_gate_r8`) et les outils des Routes 5 et 6 |
| Postes du J15 (Routes 5 et 6) | `main` : règles de recul `unless [saffron_gates_open]` ; **la remise de la boisson n'y est pas faite** (écart du J20 T25 : le déclencheur et le garde partagent une réplique) | Donne aux déclencheurs du J15 un dialogue à eux, puis y ajoute les textes 216 à 219 (marche à suivre : `etat-projet.md`, entrée « J20 T25 ») |
| Ascenseur piloté par les données | `main` (J20) : `game/world/elevator/`, `data/world/elevators.json`, objet-clé facultatif `key` | Nouvelle entrée `silph_co` : 11 étages, **sans clé** (RB) |
| Don de Pokémon (vers le Stockage si l'équipe est pleine) | `main` (J20) : `game/systems/gift/pokemon_gift.gd`, étape de scène du don d'Évoli | Lokhlass, tel quel |
| Téléporteurs (`Warp.Style.TELEPORT`, `SceneRouter.relocate`, contrôle `plan_check_teleports.py`) | `systemes-2` (S2F, **validé par Kevin** le 2026-10-21) ; **pas encore dans `main`** | Grilles et données seulement |
| Portes à carte (`KeyDoor`, verbe OUVRIR, objet `card_key`, texte « Il faut une carte. ») | `systemes-2` (S2F, validé) ; pas encore dans `main` | Portes posées depuis les grilles ; la Carte au 5F |
| Sauvegarde à la mise en arrière-plan (reprise juste avant un combat ou une scène) | `systemes-2` (S2A, validé) | Rien à faire ; les remises uniques s'appuient dessus |
| Rival par starter (`team_by_starter`, clé = starter **du joueur**) | `main` : `data/trainers/rival.json` (`rival_lab`, `rival_route22`, `rival_cerulean`, `rival_ss_anne`), `pokemon_tower.json` (`rival_tower`) | Nouvelle entrée `rival_silph` |
| Scène de Champion (carte, combat, drapeaux de victoire, don) | `main` : `data/cutscenes/celadon_gym.json` (Erika) | Modèle de la scène de Giovanni |
| Point d'arrivée du Vol | `systemes-2` : `fly_points.json` prévoit `saffron_city` / `from_center` | Le J26 crée ce spawn devant le Centre (ou corrige la donnée) |
| Espèces | sur `main` : Roucarnage, Caninos, Noeunoeuf, Léviator, Nidorino, Nidoqueen, Kangourex, Rhinocorne, Kadabra | **À créer** : Lokhlass, Alakazam (`lapras`, `alakazam` ; vérifier d'abord les branches J21 à J25) |
| Objets | `card_key` sur `systemes-2` ; **aucune** `master_ball` dans le dépôt | Créer `master_ball` (T4) |
| Badge Volcan (J25) | non requis | **Aucune condition** sur un Badge (règle de la passe §7) |

### 0.2 Contrat de sortie (ce que les jalons suivants lisent)

| Donnée | Lue par | Règle |
|---|---|---|
| Drapeau **`silph_giovanni_defeated`** (posé à la victoire contre Giovanni, au 11F) | J27 (Arène de Morgane), J28 (Arène de Jadielle) | **Seule source de vérité de la libération.** Le J26 ne crée pas de drapeau `saffron_liberated` ni `saffron_gym_unlocked` [D] |
| Carte `saffron_city`, porte de l'Arène et porte du Dojo (warps vers `saffron_gym`, `fighting_dojo`, cartes du J27) | J27 | Le J26 pose les deux portes en « À venir » ; le J27 crée les cartes et relance l'outil de Safrania |
| Sbire Rocket devant la porte de l'Arène, présent `unless [silph_giovanni_defeated]` | J27 | C'est lui qui ferme l'Arène pendant l'occupation (la porte du Dojo reste libre) |
| Espèces `lapras`, `alakazam` | J27 (Morgane), J29, J30 (Olga, rival) | Créées ici avec leurs capacités jusqu'au N65 |
| Combat `rival_silph` (identifiant distinct) | J29 (`rival_route22_final`), J30 (rival Champion) | Les trois combats partagent `starter_species`, jamais l'équipe actuelle du joueur |
| Objet `master_ball` | J29 (Sulfura), J31 (Mewtwo) | Capture garantie, aucune autre règle |

### 0.3 Ce qui peut commencer maintenant, ce qui attend

**Maintenant** (branche `jalon-26` depuis `origin/main`, aucun fichier de jeu touché) :
- T1 à T5 : décodage RB, grilles, données, textes, kit d'art et vue générale ;
- le contrôle des téléporteurs peut tourner dès maintenant en lisant `tools/art/plan_check_teleports.py`
  sur la branche `systemes-2` (lecture seule) ; il sera recopié par la fusion de la passe.

**Après la fusion de la passe systèmes 2 dans `main`** (S2D en QA, puis S2Z) : tout ce qui pose une
carte réelle (T6 et suivantes). Le J26 n'a besoin d'**aucun** des J21 à J25 : il peut entrer en code
avant eux, sur une zone de carte qui ne touche aucun d'eux (stratégie, levier 2). Seul point commun :
les fichiers d'espèces et `tm_compatibility.json`, à régénérer à chaque fusion.

### 0.4 Écarts relevés dans la passe (sans rouvrir les arbitrages)

- La passe dit « Lot J26B : téléporteurs, ascenseur, portes et Carte Magnétique ». Depuis le
  2026-10-19, ces systèmes sont codés par la passe systèmes 2 : **26B n'est que du placement**.
- Les notes de coordination disent que la passe ne sait pas « qui ouvre les postes ». C'est réglé :
  le J20 (T25) a codé l'ouverture ; le J26 ne fait que déclarer la carte (§0.1).
- Rouge/Bleu : le Lokhlass est donné au 7F **sans condition**. La passe le place « après la victoire »
  contre le rival : on suit la passe (variante `if` du drapeau de victoire du rival).

## 1. Découpage

### 1.1 Sous-jalons et validations

Contenu simple sur des systèmes déjà validés : **une seule QA téléphone** (stratégie, levier 4).

| Sous-jalon | Lots de la passe | Tâches | Validation |
|---|---|---|---|
| **26.0** | J26.0 | T0 à T5 | Kevin sur planches : grilles, graphe des téléporteurs, vue générale, textes |
| **26-I** | J26A, J26B, J26C | T6 à T10 | — (tests, captures) |
| **26-II** | J26D, J26E, J26F | T11 à T16 | **une session téléphone**, puis clôture |

### 1.2 Fichiers chauds

| Fichier | Tâches | Risque |
|---|---|---|
| `data/world/zones.json` | T6 | Faible : remplir `saffron_city` ; c'est **le** basculement des postes (tests du J20 à relancer) |
| `data/world/elevators.json` | T7 | Faible : une entrée |
| `data/npcs/route_5_gate.json`, `route_6*.json`, `data/dialogues/route_5.json`, `route_6.json` | T8 | Moyen : données du J15 ; ne rien changer d'autre que le dialogue du déclencheur |
| `data/trainers/rival.json` | T11 | Faible : une entrée |
| `data/pokemon/species/*`, `tm_compatibility.json` | T3 | Moyen : doublons possibles avec les J21 à J25 ; vérifier toutes les branches distantes avant d'ajouter |

Aucun fichier de `game/` n'est modifié, sauf peut-être la Master Ball (T4, une ligne de règle).

## 2. Conception technique

### 2.1 Cartes et grilles (`tools/plans/`)

| Grille | Carte | Contenu |
|---|---|---|
| `safrania.txt` | `saffron_city` | Ville RB à l'échelle des villes précédentes (Céladopole, J20) ; 4 entrées (postes N, S, E, O) ; Centre, Boutique, Sylphe, Arène (porte du J27), Dojo (porte du J27), maisons ; arrivées `from_gate_r5`, `from_gate_r6`, `from_gate_r7`, `from_gate_r8`, `from_center` |
| `safrania_centre.txt`, `safrania_boutique.txt` | `saffron_center`, `saffron_mart` | Coques connues (Centre et Boutique types) ; point de repos `saffron_center` |
| `safrania_maison_*.txt` | maisons | Voir Q26-3 (périmètre des maisons) |
| `sylphe_1f.txt` … `sylphe_11f.txt` | `silph_co_1f` … `silph_co_11f` | **Puzzles à 1:1** depuis RB (règle du J24 §2.11) ; positions `teleporteur`, `porte_carte`, Dresseurs, objets, ascenseur, escaliers |
| `sylphe_ascenseur.txt` | `silph_co_elevator` | Cabine (modèle du J20) |

- **Décodage RB** : `tools/art/silph_rb_decode.py` (sur le modèle de `seafoam_rb_decode.py` du J24)
  lit les cartes et les `warp_events` de pokered (téléporteurs, portes à carte, escaliers) et produit
  le **graphe des salles**. Les grilles en partent.
- **Contrôles** : `plan_check.py --legende` (types `teleporteur`, `porte_carte`) ;
  `plan_check_teleports.py` sur les 11 étages (spawns, paires, graphe imprimé, salle isolée refusée) ;
  un contrôle propre `tools/art/plan_check_j26.py` : raccords des 4 postes, chaque étage atteignable
  depuis le 1F, **le 11F atteignable** avec la Carte, **le 7F (rival) sur le chemin du 11F** [D],
  retour au 1F toujours possible depuis chaque salle, avec et sans la Carte.

### 2.2 Systèmes branchés (données seulement)

- **Téléporteurs** : `Warp` `STEP_ON` de style `TELEPORT` créés par l'outil de construction depuis les
  `teleporteur` de la grille ; même carte → `relocate`, autre étage → `change_map` (S2F). Orientation
  conservée, aucun verrou d'arrivée (valeurs S2F).
- **Portes à carte** : `KeyDoor` (`key_item: card_key`), drapeaux `door_silph_co_<n>f_<id>_open` ;
  une Carte ouvre toutes les portes, pour toujours (S2F).
- **Ascenseur** : entrée `silph_co` de `elevators.json`, étages 1F à 11F, sans clé.
- **Occupation** : PNJ et Dresseurs de la ville à variantes `unless [silph_giovanni_defeated]`
  (sbires, dont celui de la porte de l'Arène) et `if [silph_giovanni_defeated]` (habitants revenus).
  Mécanisme existant des PNJ conditionnels. Pendant l'occupation, la porte de l'Arène est bloquée
  par le sbire ; le Dojo reste libre (règle de la passe §7).
- **Sylphe libérée** : les sbires de la Sylphe disparaissent (`unless`), les employés changent de
  réplique ; les portes ouvertes le restent.

### 2.3 Combats

- **Sbires et scientifiques** : équipes RB (pokered `parties.asm`, à auditer au T3), la plupart
  évitables (arbitrage 4). Chaque Dresseur : bloc `trainer` existant (`id`, `sight`, `before`,
  `defeated`).
- **Rival n° 6, 7F** (`rival_silph`, obligatoire, Grand moment `rival_battle` à la victoire comme
  à la défaite). Référence Rouge/Bleu, **à confirmer par l'audit** (pokered) :

  | Starter du joueur | Équipe du rival (RB) |
  |---|---|
  | Bulbizarre | Roucarnage 37, Noeunoeuf 38, Léviator 35, Alakazam 35, Dracaufeu 40 |
  | Salamèche | Roucarnage 37, Caninos 38, Noeunoeuf 35, Alakazam 35, Tortank 40 |
  | Carapuce | Roucarnage 37, Léviator 38, Caninos 35, Alakazam 35, Florizarre 40 |

  Le `rival_tower` du J19 a adapté la variante Bulbizarre (Sabelette au lieu de Léviator) : voir
  Q26-4. Obligatoire : le rival se tient sur le passage du 7F vers le 11F (grille) ; défaite →
  réveil habituel, combat rejouable.
- **Giovanni, 11F** (`silph_co_giovanni`) : Nidorino 37, Kangourex 35, Rhinocorne 37, Nidoqueen 41
  (arbitrage verrouillé). Capacités RB auditées ; IA `smart`. Scène sur le modèle d'Erika : intro,
  carte, combat, victoire → `silph_giovanni_defeated`, départ de Giovanni. Défaite → réveil,
  rejouable.
- **Équilibrage** : simulation des combats majeurs avec l'outil du J12 (comme J19, J20).

### 2.4 Remises uniques

| Remise | Mécanisme | Drapeau | Règle |
|---|---|---|---|
| Carte Magnétique (5F) | objet au sol (Poké Ball), `found_items` | `got_silph_co_5f_card_key` | Comme tout objet ramassé |
| Lokhlass N15 (7F, employé) | étape de don du J20 (`PokemonGift`, équipe pleine → Stockage) | `silph_lapras_received` | Variante `if [<victoire rival_silph>]` ; remise **idempotente** : drapeau et don dans le même bloc, puis écriture immédiate (modèle du don d'Évoli) |
| Master Ball (11F, président) | étape `give` | `silph_master_ball_received` | Variante `if [silph_giovanni_defeated] unless [silph_master_ball_received]` : si le jeu s'arrête entre la victoire et la remise, le président la donne à la visite suivante |

**Master Ball** : objet `master_ball` (Poké Balls, `catch_bonus` à fixer au T4). Le T4 vérifie dans
`CaptureCalc.catch_value` qu'un bonus suffisant donne une capture certaine **même** pour un taux de
3 à PV pleins. Sinon, ajout minimal : `ItemData.always_catches` lu par `throw_ball` (une règle pure,
un test). Pas de vente en boutique.

### 2.5 Drapeaux et sauvegarde (v7 inchangée)

| Drapeau | Rôle |
|---|---|
| `silph_giovanni_defeated` | Victoire au 11F ; libération ; contrat J27 / J28 |
| `silph_master_ball_received` | Master Ball remise |
| `silph_lapras_received` | Lokhlass remis |
| `got_silph_co_5f_card_key` | Carte ramassée (la possession est lue dans le Sac) |
| `door_silph_co_<n>f_<id>_open` | Portes ouvertes (S2F) |
| drapeau de victoire de `rival_silph` | même convention que `rival_ss_anne` (T11 la recopie) |
| `defeated` de chaque Dresseur | mécanisme existant |

Sauvegardes forcées : ouverture de porte (S2F), don de Lokhlass, Master Ball, fin du combat de
Giovanni (autosave existante après un combat de Champion, à vérifier au T13).

### 2.6 Départs de débogage (`tools/debug_start/`)

| Départ | Contenu |
|---|---|
| `saffron_gate` | Poste de la Route 8, une Eau Fraîche, équipe N38 |
| `silph_1f` | Sylphe 1F, Safrania occupée, sans Carte |
| `silph_5f` | 5F, devant la Carte |
| `silph_7f_rival` | 7F avec la Carte, devant le rival (3 variantes par `starter_species`) |
| `silph_11f` | 11F, rival battu, devant Giovanni, équipe N42 |
| `saffron_free` | Safrania libérée, Lokhlass et Master Ball reçus |

### 2.7 Art (levier 4 : entre-deux)

Avant le code : **grilles** + **une vue générale peinte** de Safrania et d'un étage type de la
Sylphe. Tout le reste va dans un lot d'art (numéro de série réservé au push, après vérification des
branches distantes) : façades de Safrania, intérieurs des 11 étages (en **modules**, comme le repaire
et le Casino de la série 22 bis), tapis de téléporteur, porte électronique (fermée / ouverte),
Giovanni (déjà peint au J20), président, employés, Lokhlass, Alakazam, Nidoqueen, Rhinocorne,
fond de combat « bureaux ». Le code ne bloque jamais sur l'art (placeholders).

## 3. Textes

La passe ne propose **aucun texte**. Les textes ci-dessous sont des propositions **[D] (défaut, à
relire)**, à présenter à Kevin en un seul lot. Locuteurs et format : ceux des dialogues existants.
Les textes des postes (215 à 219) sont déjà validés (J20).

| N° | Locuteur | Texte |
|---|---|---|
| T26-01 [D] | Sbire Rocket (rue) | « Safrania est à nous. Circule, gamin. » |
| T26-02 [D] | Sbire Rocket (porte de l'Arène) | « L'Arène est fermée. Ordre du patron. » |
| T26-03 [D] | Habitant (occupation) | « Ils sont entrés dans la Sylphe SARL… Plus personne n'ose sortir. » |
| T26-04 [D] | Hôtesse (1F, occupation) | « Je… je ne peux rien dire. Ils sont partout dans les étages. » |
| T26-05 [D] | Narration (porte fermée) | « Une porte électronique. Elle ne s'ouvre qu'avec une carte. » (en plus de « Il faut une carte. », validé en S2F) |
| T26-06 [D] | Narration (Carte) | « {player} obtient la Carte Magnétique ! » (modèle du toast d'objet clé existant) |
| T26-07 [D] | Rival (7F, avant) | « Tiens, {player}. Toi aussi, tu cherches le chef de la Team Rocket ? Montre-moi d'abord ce que tu vaux. » |
| T26-08 [D] | Rival (7F, victoire du joueur) | « Pas mal… Le chef est tout en haut. Fais ce que tu veux, moi j'ai mieux à faire. » |
| T26-09 [D] | Rival (7F, défaite du joueur) | « Trop facile. Reviens quand tu seras prêt. » |
| T26-10 [D] | Employé (7F) | « Tu as battu ce garçon ? Alors tu peux protéger celui-ci. Les Rocket voulaient l'emporter. » |
| T26-11 [D] | Narration | « {player} reçoit un LOKHLASS ! » (texte existant du don, à vérifier) |
| T26-12 [D] | Employé (7F, après) | « Prends soin de lui. Il sait nager très loin. » |
| T26-13 [D] | Giovanni (11F, avant) | « Te voilà encore. Tu t'obstines à te mettre en travers de mes affaires. Cette fois, je ne te ferai pas de cadeau. » |
| T26-14 [D] | Giovanni (victoire du joueur) | « … Je me suis trompé sur toi. La Sylphe SARL n'en vaut plus la peine. Nous partons. » |
| T26-15 [D] | Giovanni (défaite du joueur) | « Rentre chez toi. Ce n'est pas un jeu d'enfant. » |
| T26-16 [D] | Président | « Merci ! Sans toi, la Sylphe SARL était perdue. Accepte ceci : c'est notre plus grande invention. » |
| T26-17 [D] | Narration | « {player} obtient la MASTER BALL ! » |
| T26-18 [D] | Président (après) | « La MASTER BALL attrape n'importe quel Pokémon à coup sûr. Il n'en existe qu'une. » |
| T26-19 [D] | Habitant (libéré) | « La Team Rocket est partie ! Safrania respire enfin. » |
| T26-20 [D] | Hôtesse (1F, libérée) | « Bienvenue à la Sylphe SARL ! Grâce à toi, tout est rentré dans l'ordre. » |
| T26-21 [D] | Objet `master_ball` (Sac) | « La meilleure Ball qui soit. Elle attrape à coup sûr n'importe quel Pokémon sauvage. » |
| T26-22 [D] | Panneau de Safrania | « SAFRANIA — Ville dorée, cœur commercial de Kanto. » |

Les répliques des ~30 Dresseurs de la Sylphe (avant, vaincu, après) sont écrites au T3, sur le
format des J20 et J24, et marquées [D] en lot.

## 4. Tâches

Rôles : **A** architecte-godot · **C** constructeur-monde · **U** ui-mobile · **Q** qa-mobile ·
**K** Kevin.

### 4.1 Sous-jalon 26.0 — **maintenant**

#### T0 — A : plan (ce document) — fait

#### T1 — A : branche `jalon-26` depuis `origin/main` ; audit d'alignement
- Relire `systemes-2.md` §2.9, §2.10, §7 et l'état de la passe ; noter dans ce plan tout écart de nom.
- Vérifier sur **toutes** les branches distantes que `lapras`, `alakazam`, `master_ball` n'existent pas.

#### T2 — C : décodage RB, grilles v1, contrôles
- `silph_rb_decode.py`, grilles de Safrania, de ses intérieurs et des 11 étages, `plan_check_j26.py`.
- **Fin** : « TOUT EST CONFORME », graphe des salles imprimé → K valide les grilles et le graphe.

#### T3 — A : données
- Espèces (Lokhlass, Alakazam), capacités jusqu'au N65 (remplacements explicites pour les capacités
  absentes du moteur, comme au J24), équipes RB des Dresseurs, `rival_silph`, `silph_co_giovanni`,
  objets au sol et cachés (liste RB), répliques des Dresseurs [D].

#### T4 — A : objets et petites règles
- `master_ball` ; vérification de la capture garantie (§2.4) ; si besoin `always_catches` + test.

#### T5 — C (Mac, Codex) : vue générale peinte de Safrania et d'un étage de la Sylphe → K

### 4.2 Sous-jalon 26-I — **après la fusion de la passe systèmes 2 dans `main`**

#### T6 — C : Safrania et ses intérieurs (géométrie), raccords des 4 postes
- `zones.json` ; outils des Routes 5, 6, 7, 8 relancés ; spawn du Vol `from_center` ; point de repos.
- Tests des postes du J20 relancés (`test_saffron_gates`) **avec la vraie carte**.

#### T7 — C : Sylphe 1F à 11F, cabine, téléporteurs, portes à carte (géométrie et placement) — après T2, T6

#### T8 — C : dialogue propre des déclencheurs du J15 (Routes 5 et 6) et remise de la boisson — après T6

#### T9 — C : vie de Safrania occupée et de la Sylphe (sbires, scientifiques, employés, objets) — après T3, T7

#### T10 — A : contrôle de bout en bout sur les cartes réelles (graphe joué par un test d'intégration) — après T7

### 4.3 Sous-jalon 26-II

#### T11 — C : rival n° 6 (7F) et Lokhlass — après T9

#### T12 — C : Giovanni (11F), président, Master Ball — après T9

#### T13 — C : libération (variantes de la ville et de la Sylphe) — après T12

#### T14 — A : simulation d'équilibrage (rival, Giovanni) ; départs de débogage — après T11, T12

#### T15 — Q : **session 26** sur téléphone → K — après T13, T14

#### T16 — A : clôture (suite complète, retrait des départs de QA, passation J27 / J28, fusion après accord de K)

## 5. Tests

- `test_saffron_city.gd` : grille = plan ; 4 postes ↔ ville dans les deux sens ; zone jouable →
  boisson demandée (J20) ; sauvegarde sur chaque case d'arrivée → reprise sur la case.
- `test_silph_teleports.gd` : chaque téléporteur des 11 étages mène à son spawn, sans boucle ;
  `relocate` sur le même étage ; parcours 1F → 11F joué.
- `test_silph_doors.gd` : sans Carte → refus ; avec → ouverte pour toujours, après rechargement aussi.
- `test_silph_elevator.gd` : 11 étages, aucun étage grisé à tort.
- `test_silph_rival.gd` : trois variantes selon `starter_species`, jamais selon l'équipe ; défaite →
  rejouable ; victoire → Grand moment.
- `test_silph_lapras.gd` : don unique ; équipe pleine → Stockage ; arrêt simulé pendant la scène →
  ni perte ni doublon.
- `test_silph_giovanni.gd` : victoire → `silph_giovanni_defeated` ; Master Ball une fois ; arrêt
  entre les deux → remise à la visite suivante.
- `test_master_ball.gd` : capture certaine (taux 3, PV pleins).
- `test_saffron_liberation.gd` : PNJ occupés / libérés ; porte du Dojo libre pendant l'occupation ;
  aucun Badge exigé (ni Volcan ni autre).
- `test_save_j26.gd` : v7, une sauvegarde du J20 se charge sans changement.

## 6. Critères d'acceptation

1. `tools/test.sh` passe ; import sans erreur ; captures relues.
2. Les grilles passent `plan_check_j26.py` et `plan_check_teleports.py` (11 étages).
3. Les postes du J20 et du J15 s'ouvrent avec une boisson, sans une ligne de code nouvelle.
4. Le rival et Giovanni sont obligatoires ; la plupart des sbires sont évitables.
5. Lokhlass, Carte et Master Ball : une seule fois, même avec une fermeture de l'application.
6. `silph_giovanni_defeated` est posé, et c'est le seul drapeau que lisent J27 et J28.
7. La session téléphone est validée par K.

## 7. QA téléphone (une session, 45 min au plus, téléphone selon l'attribution du moment)

| Scénario | Attendu |
|---|---|
| `saffron_gate` : donner l'Eau Fraîche, entrer | Garde écarté, ville occupée |
| Porte de l'Arène | Sbire, T26-02 ; porte du Dojo libre (« À venir » jusqu'au J27) |
| `silph_1f` : téléporteurs du 1F au 5F | Arrivée exacte, pas de boucle, lisible |
| Porte sans Carte, puis avec | Refus, puis ouverture, OUVRIR disparaît |
| `silph_7f_rival` ×3 starters | Bonne équipe ; Lokhlass après la victoire |
| Équipe pleine au 7F | Lokhlass au Stockage, message clair |
| `silph_11f` : défaite, puis victoire | Rejouable ; Master Ball ; ville libérée |
| Appel ou verrouillage pendant le combat de Giovanni, puis relance | Reprise juste avant le combat, rien en double |
| 60 fps sur un grand étage | Tenu |

## 8. Valeurs par défaut [D] (règle 4, à relire en lot)

- Un seul drapeau de libération, `silph_giovanni_defeated` (pas de `saffron_liberated`).
- Le 7F (rival) est sur le chemin obligatoire du 11F (contrôle de la grille).
- Lokhlass N15 (RB), donné seulement après la victoire contre le rival (passe).
- Master Ball : capture certaine, une seule, jamais en boutique.
- Étages de la Sylphe à 1:1 (puzzles), ville à l'échelle des villes précédentes.
- Une seule session téléphone (contenu sur systèmes validés).
- Textes T26-01 à T26-22.

## 9. Points ouverts pour Kevin (aucun ne bloque le 26.0)

- **Q26-1 — Textes.** La passe n'a aucun texte ; T26-01 à T26-22 sont des propositions [D].
  Les considères-tu couverts par ta validation d'avance du 2026-10-21, ou à relire au prochain créneau ?
- **Q26-2 — Lokhlass.** RB le donne sans condition au 7F ; la passe le lie à la victoire contre le
  rival. Plan : la passe. À confirmer si tu préfères RB.
- **Q26-3 — Maisons de Safrania.** RB : maison de M. Psy (CT29 Psyko), maison du Copieur (Poupée →
  CT31 Copie), maison du Roucool messager. La passe ne les cite pas. Défaut : maisons posées et
  habitées, **sans** remise de CT (reportées), ou bien porte « À venir ». À trancher.
- **Q26-4 — Rival, variante Bulbizarre.** Le `rival_tower` du J19 a remplacé un Pokémon RB par
  Sabelette. Faut-il garder cette lignée (Sablaireau au 7F) ou revenir à l'équipe RB ?
- **Q26-5 — Porygon (Casino).** La passation du J20 range « Porygon (Casino) » au J26 sans détail.
  À préciser (lot de prix du Casino ?) ou à reporter.
- **Q26-6 — Fusion avant les J21 à J25.** Le J26 ne dépend d'aucun d'eux : peut-il entrer en code
  dès que la passe systèmes 2 est dans `main`, avant eux (stratégie, levier 2 : 2 à 3 jalons en code) ?
