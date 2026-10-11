# J13 — Azuria, Ondine et le Pont Pépite : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-11. J'ai relu la V2 contre `vision.md`, `roadmap.md`, les dossiers 05, 06, 09, 12
> et 15, le dossier 14 (J11, branche `origin/claude/lancement-j11-4pkt2k` à `1f7a880`), le plan
> `docs/tech/jalon-12.md` et le code de `main` (`a34e433`). Aucune ligne de code n'est écrite avant
> le dossier 16 validé. Le numéro **16** est libre sur toutes les branches (13 = ouverture,
> 14 = systèmes du J11, 15 = J12).
>
> La V2 est reproduite dans `j13-v2-chatgpt.md`. Ses **9 arbitrages créatifs** ne sont pas rouverts.
> Ses **C-1 à C-8** sont commentés au §4. Mes arbitrages nouveaux sont numérotés **D-1 à D-16** (§5) :
> on y répond par numéro, puis on les transmet à ChatGPT avec la V2 pour la consolidation.
>
> Origine des règles : **RB** = Rouge/Bleu, **G+** = génération plus récente, **K26** = invention
> de Kanto 2026.

## 0. Décision déjà prise pour le J14

**L'épisode historique de Léo est conservé** (Kevin, 2026-10-11). Léo est transformé en Pokémon et
le joueur l'aide à retrouver son apparence. Il garde son rôle et sa maison au Cap d'Azuria. Le J13
n'en montre rien (arbitrage 9 de la V2).

## 1. Les 9 arbitrages de la V2

Je suis d'accord avec les neuf. Aucun ne contredit une règle écrite au point de devoir être
rouvert. Le n° 6 demande seulement une adaptation (§2, point 2).

| # | V2 | Avis |
|---|---|---|
| 1 | Azuria + Ondine + rival + Pont Pépite | Oui, mais **la Route 4 manque** : le dossier 15 (§14) la réserve au J13 (point 1). |
| 2 | Canaux, pierre claire, ponts, végétation | Oui. Le plan doit respecter les **angles droits** (dossiers 01 et 07) : canaux rectilignes, ponts perpendiculaires (§3). |
| 3 | Piscine, deux Dresseurs, Stari et Staross | Oui. Niveaux RB 18 / 21 cohérents avec Pierre (12 / 14, valeurs RB). Capacités : voir §2, point 6. |
| 4 | Arène débloquée après la victoire contre le rival | Oui. **Écart avec RB**, où l'Arène est libre. Il faut une raison dans le monde (D-3). |
| 5 | Rival avant le Pont Pépite | Oui (RB : il descend du pont). |
| 6 | Victoire obligatoire | Oui, mais **contraire à une règle écrite** : le dossier 09 §15 dit que l'issue d'un combat contre le rival « est acceptée par l'histoire ». C'est donc une exception assumée pour ce combat, à écrire (D-4, D-5). |
| 7 | Cinq Dresseurs puis recruteur Rocket | Oui (RB). Cohérent avec le dossier 15 §8.1 : une organisation qui « a une mission », sans chef ni intrigue parallèle. |
| 8 | Maison cambriolée : indices seulement | Oui. Dans RB, l'arrière de cette maison mène plus tard vers la Route 9 : ce sera au J14. |
| 9 | Route 25 et Léo au J14 | Oui. |

## 2. Ce que la V2 oublie ou contredit

1. **La Route 4 est absente.** Le dossier 15 §14 la réserve au J13 : rebords à sens unique,
   Dresseurs, herbes, objets. Le J12 livre seulement un **sas** (`route_4`, 24 × 14, sans herbe ni
   Dresseur) et une passation : garder l'identifiant `route_4`, l'arrivée `from_mt_moon` (3, 6) et
   le repère de coordonnées du sas (`jalon-12.md` §0.2 n° 15).
   Surtout, **c'est la seule zone d'entraînement possible avant un rival qu'il faut battre** : la
   Route 24 est derrière lui, la Route 5 et la Route 9 sont fermées. Sans elle, un joueur trop
   faible ne peut plus progresser. → **D-1**.
2. **Le rival obligatoire touche à trois règles existantes** :
   - **Issue acceptée par l'histoire** (dossier 09 §15) : le J13 en fait une exception pour ce
     combat.
   - **Grand moment `rival_battle`** : la roadmap dit « victoire comme défaite ». Dans le code,
     `boot.gd` (l. 1193) **ajoute un moment à chaque combat, sans contrôle de doublon**. Un combat
     rejouable écrirait un moment par défaite. → **D-5**.
   - **États « pas affronté / gagné / perdu »** (dossier 09 §15) : ici, « perdu » n'est jamais un
     état final.
3. **Le modèle « rejouable jusqu'à la victoire » existe déjà** : c'est Pierre
   (`data/cutscenes/pewter_gym.json` ; variante `unless badge_boulder`, défaite → réplique `_lost`
   puis `wake_up`, `brock_met` évite de rejouer l'introduction). Le rival n° 2, lui, ne se rejoue
   jamais. C-2 et C-3 ne demandent donc **aucune mécanique nouvelle**.
4. **Ondine qui « gère les changements de Pokémon » demande une mécanique absente.** L'IA ne change
   jamais de Pokémon. Le dossier 14 (A-4) a **reporté** l'IA qui change de Pokémon, et le dossier 06
   §3 attend justement d'Ondine la leçon « les Dresseurs peuvent faire ça aussi ». C'est le bon
   moment pour la créer, mais c'est la seule mécanique de combat vraiment nouvelle du J13. → **D-7**.
5. **Le Rattata du rival.** Le tournant de Lavanville (dossier 06 §6) repose sur la disparition du
   **Rattata / Rattatac** du rival. Aujourd'hui son équipe est Roucool + starter : sans Rattata au
   combat n° 3, le combat de Lavanville perd son sens. → **D-6**.
6. **Capacités d'Ondine**. Stari 18 dans RB : Charge, Pistolet à O. Staross 21 : Charge, Pistolet à
   O, Armure, Bulles d'O.
   - Existent : `tackle`, `water_gun`, `harden` (et `bubble`, `swift`).
   - **Bulles d'O (`bubble_beam`) n'existe pas** ; ce n'est qu'un nom dans la table des CT du J11.
     C'est une **donnée simple** (65, baisse de Vitesse avec une chance) que le moteur sait déjà
     traiter (`STAT_STAGE` avec chance).
   - **Soin (Recover) n'est pas nécessaire** : Stari ne l'apprend qu'au niveau 27 dans RB. Si on
     s'en tient à RB, aucun effet de soin n'est à créer.
7. **La CT11 dépend du J11.** Le système de CT (Sac → CT → Pokémon, CT permanente, catégorie
   masquée tant qu'elle est vide, `tm_compatibility.json`) n'est **planifié qu'au 11B** : rien n'est
   codé, même sur la branche du J11. Bulles d'O est compatible avec le moteur. Il faut seulement
   ajouter les compatibilités CT des espèces nouvelles du J12 et du J13. → **C-6**.
8. **La Pépite n'existe pas, mais l'économie sait la gérer.**
   - `items.json` contient 4 objets.
   - La vente existe déjà (`ShopRules.sell`, reprise = `floor(price / 2)`, refusée pour un objet
     clé ou sans prix).
   - La protection contre les doublons est le drapeau `got_<id>` (modèle de la Forêt de Jade) ;
     `found_items` n'est qu'un journal.
   - Seule question : **dans quelle catégorie du Sac** (D-10).
9. **Sauvegarde : rien de nouveau.** Badges (`badge_cascade` est déjà déclaré dans
   `data/badges.json`), Dresseurs battus (`beaten_<id>`), Pépite (`got_nugget`, Sac) et Grands
   moments tiennent tous dans les champs existants. Le J11 écrit la v6, le J12 ne change rien, et
   **le J13 ne change pas non plus le format**. La « migration additive » de la V2 est sans objet ;
   il reste à vérifier qu'une partie sauvegardée dans le sas retombe sur une case praticable de la
   vraie Route 4.
10. **Espèces : la V2 sous-estime le coût.** Aujourd'hui `main` a 38 espèces. Le J12 en prévoit 12,
    qui ne sont pas encore écrites dans les données.
    - **Stari, Staross, Abra et les Pokémon de l'eau** sont absents des données. L'artwork officiel
      de face existe pour les 151.
    - **Aucun dos peint n'existe nulle part.** Le côté joueur utilise des dos provisoires en pixel
      art pour 20 espèces seulement ; c'est une dette du J12, que le J13 hérite.
    - Le pool RB de la Route 24 apporte en plus Mystherbe / Chétiflor et Abra, avec leurs
      évolutions atteignables. → **D-8, D-9**.
11. **Abra = deux mécaniques cachées.**
    - **Téléport** : un Abra sauvage s'enfuit au premier tour. La fuite adverse n'existe pas.
    - **Évolution par échange** : Kadabra → Alakazam. Kanto 2026 n'a ni échange ni règle pour ces
      évolutions (Kadabra, Machopeur, Gravalanche, Spectrum).

    C'est une décision de game design qui dépasse le J13. → **D-9**.
12. **Point de repos avant le rival.** Après une défaite, le joueur se réveille au **dernier Centre
    utilisé**. S'il défie le rival sans être entré au Centre d'Azuria, il se réveille au Centre de
    la Route 3 et doit retraverser le Mont Sélénite (≈ 10 min). Ce n'est pas un blocage, mais c'est
    une mauvaise surprise. Le même risque existait avec Pierre et il a été accepté. → **D-2**
    (placement du Centre).
13. **Lieux historiques d'Azuria absents de la V2.** Ils doivent être décidés, sinon la
    consolidation les inventera :
    - **le magasin de vélos** (le vélo est un système du dossier 07, pas encore conçu) ;
    - **la Grotte Azurée** (post-game, dossier 06 §9) ;
    - la maison d'échange ;
    - la **Boutique** (son stock).

    → **D-11, D-12, D-13**.
14. **Pas d'eau jouable.** Ni Surf, ni pêche, ni rencontres sur l'eau (seul le terrain « herbe »
    existe). Une ville de canaux montre donc beaucoup d'eau **sans y donner accès**. Magicarpe,
    Poissirène et Psykokwak restent hors du Pokédex sauvage tant que la pêche n'existe pas. Le
    vendeur de Magicarpe a été reporté par le J12 (B-13) : il ne revient pas au J13 sans pêche.
    → **D-12**.
15. **Dépendances**. Le code du J13 vient **après la clôture du J12**, elle-même après celle du J11 :
    - CT et statuts (Ultrason des Poissirène et Kokiyas) viennent du J11 ;
    - Abo, Nosferapti, le Sbire Rocket peint, l'étape « choix qui lance une scène » et la carte
      `route_4` viennent du J12.

    La conception (dossier, grilles, vues peintes, art) peut avancer en parallèle, comme pour le J12.

## 3. Plan orthogonal d'Azuria et déplacements

- **Angles droits seulement** : canaux en L ou en T, ponts perpendiculaires aux berges, aucun
  canal en diagonale. Les quais et les ponts font au moins 2 cases de large, pour que le joueur et
  le compagnon (J11) se croisent sans se bloquer (le compagnon échange sa place, mais un goulet de
  1 case répété devient pénible).
- **L'eau est un obstacle** comme les arbres : aucune case d'eau praticable, ni rebord ni nage.
- **Quatre sorties lisibles** :

  | Sortie | État au J13 |
  |---|---|
  | Ouest | Route 4, ouverte |
  | Nord | Route 24 et Pont Pépite, derrière le rival |
  | Est | Route 9 : fermée sans promesse (arbre, éboulis, clôture), comme le sentier est d'Argenta |
  | Sud | Route 5 : fermée proprement, comme le Cap d'Azuria (C-7) |

- **Le Centre est sur l'avenue d'arrivée** (D-2) ; l'Arène et la sortie nord sont plus loin.
- **Budget** : ≤ 3 000 nœuds par carte, mémoire = carte + voisines (J10). Une ville d'eau avec des
  reflets animés coûte plus cher que la pierre d'Argenta : à mesurer dès la grille.
- **Filière habituelle** : grille `tools/plans/*.txt` + contrôle `plan_check` (combats inévitables,
  chemins), puis vue générale peinte validée par Kevin, puis la carte. Les images de la V2 servent
  à l'ambiance seulement et ne vont **pas dans le dépôt** (droits).

## 4. Les propositions C-1 à C-8 de la V2

| # | V2 | Avis |
|---|---|---|
| **C-1** | Entrée libre, Ondine indisponible avant le rival | **Oui.** Les deux Dresseurs de l'Arène sont **combattables dès l'arrivée** : ils s'entraînent, ce qui fait aussi un point d'entraînement de plus. Il faut décider **pourquoi** Ondine est indisponible (D-3). |
| **C-2** | Défaite contre le rival : retour au Centre, rejouable | **Oui.** C'est le modèle de Pierre ; aucune perte d'argent (règle existante). Au retour, le rival ne rejoue pas son introduction (D-4). |
| **C-3** | Cinq Dresseurs gardés individuellement | **Oui. C'est déjà le cas** (`beaten_<id>`, sauvegardé ; un Dresseur battu reste battu). Rien à coder. |
| **C-4** | Refus du recrutement, puis combat ; aucune branche criminelle | **Oui.** Le refus est le **seul** choix. Le « Oui » reçoit une réplique (« Tu crois que c'est si simple ? ») puis mène au même combat, comme dans RB. Cela utilise l'étape « choix qui lance une scène » créée au J12. **Pépite remise avant le combat**, une seule fois (`got_nugget`), même si le combat est perdu (RB). |
| **C-5** | Aucun bonus caché | **Oui** (règle du dossier 12 §13). |
| **C-6** | CT11 Bulles d'O si compatible | **Oui, c'est compatible** : une donnée et un effet existant. Condition : 11B fusionné, et compatibilités CT ajoutées pour toutes les espèces du J12 et du J13. Remise après le badge, drapeau `tm11_received` (modèle de la CT34). |
| **C-7** | Pont et petit espace nord jouables ; Route 25 fermée | **Oui.** Le petit espace nord = la fin de la Route 24 après le recruteur (herbes, 1 objet), fermée à l'est par un raccord « ROUTE 25 — À venir » en développement (bord bloqué en release, mécanisme existant). Espèces : D-8. |
| **C-8** | Indices accessibles, aucune résolution | **Oui.** Indices **matériels** : clôture arrachée, trou dans le mur arrière, un policier (modèle « garde » existant) devant la maison, deux habitants qui en parlent. Aucun objectif ni marqueur. La maison est **fermée** (« L'enquête est en cours. »). Les indices **ne nomment pas** la Team Rocket (D-14). |

## 5. Arbitrages à trancher (D-1 à D-16)

| # | Question | Recommandation |
|---|---|---|
| **D-1** | La Route 4 dans le J13 ? | **Oui, en version courte** : le sas du J12 devient l'extrémité ouest d'une vraie Route 4, avec les mêmes cases et la même arrivée (3, 6), qui descend vers Azuria. On y trouve un **rebord à sens unique vers l'est** (RB : pas de retour vers le Mont Sélénite par la route), des **herbes** (Rattata, Piafabec, Abo, Sabelette, Férosinge, toutes espèces existantes après le J12), **1 Dresseur** évitable (RB : une Jeune Dresseuse) et **1 objet**. C'est la zone d'entraînement d'avant le rival. |
| **D-2** | Point de repos avant le rival | **Garder la règle « dernier Centre utilisé »**, sans exception. Le Centre est placé **sur l'avenue d'arrivée**, avant toute bifurcation, avec une réplique d'habitant à côté. Le joueur passe devant avant d'atteindre le rival. |
| **D-3** | Pourquoi Ondine est indisponible avant le rival | **Ondine est au pied du Pont Pépite** et regarde les jeunes Dresseurs relever le défi du pont. Le guide de l'Arène le dit (« Ondine ? Elle est partie voir les défis du pont, au nord. »). Elle assiste au combat contre le rival ; après la victoire du joueur, elle s'approche et l'invite (« Je t'attends à l'Arène. »), puis rentre. Une seule scène relie les deux drapeaux, sans porte verrouillée. *Invention K26.* Alternative moins chère : Ondine dans son bassin, « elle ne prend aucun défi aujourd'hui », débloquée sans raison visible (déconseillé : causalité artificielle). |
| **D-4** | Rejouer le rival | Le rival reste **au pied du pont**, tourné vers la ville. Un joueur qui entre dans sa vue déclenche une **réplique courte de reprise** puis le combat (pas d'introduction). Il ne se moque jamais. Drapeaux `rival_cerulean_won` (final) et `rival_cerulean_lost_once` (mémoire, pour une petite variation de réplique, jamais une branche). Le combat est **inévitable par la géométrie** : sa vue couvre toute la largeur de l'accès au pont (modèle de Théo et Milo). |
| **D-5** | Grand moment du rival n° 3 | **Un seul moment, écrit à la victoire**, et aucun moment par défaite. Il faut une protection contre les doublons dans `boot.gd`. La règle de la roadmap (« victoire comme défaite ») reste vraie pour les combats à un seul essai ; elle est précisée pour les combats obligatoires. |
| **D-6** | Équipe du rival n° 3 | **Roucoups, Rattata, starter évolué** (Herbizarre / Reptincel / Carabaffe, avantage de type comme avant). Niveaux de base RB (18 / 15 / 17), à recaler au plan avec l'outil de simulation du J12. **Abra écarté** : dans RB il ne connaît que Téléport, qui échoue en combat de Dresseur. Ce serait un Pokémon inutile, contraire à « le rival progresse », et il coûterait une espèce. Il pourra arriver en Kadabra plus tard (RB : S.S. Anne). Le **Rattata** prépare Lavanville. Trois Pokémon, sous le maximum de quatre. |
| **D-7** | IA qui change de Pokémon | **La créer au J13, en version prudente**. Règle : **au plus un changement par combat**, seulement si le Pokémon actif est en faiblesse ×2 face à celui du joueur et qu'un autre de l'équipe résiste ; message « X rappelle Stari ! ». Activée pour **Ondine** et le **rival n° 3** (IA « niveau 3 » du dossier 09 §14). Mécanique nouvelle, reportée par le J11 (A-4). Sinon : Ondine sans changement, et la leçon du dossier 06 attend. |
| **D-8** | Espèces sauvages de la Route 24 (espace nord, C-7) | **Mystherbe et Chétiflor** (les deux versions réunies, comme Sabelette et Abo au J12), avec Chenipan, Aspicot, Chrysacier, Coconfort et Roucool. Coût : **4 espèces nouvelles**, dont **Ortide** et **Boustiflor** (évolutions au niveau 21, atteignables). Rafflesia et Empiflor (pierres) ne sont pas atteignables au J13. Alternative à coût nul : uniquement des espèces existantes, mais le J13 n'apporterait alors aucune découverte sauvage. |
| **D-9** | Abra | **Reporté au J14** (Route 25, RB). Avant, deux décisions : la fuite adverse par Téléport, et **la règle des évolutions par échange** (Alakazam, Mackogneur, Grolem, Ectoplasma). Question à poser à Kevin à la conception du J14, pas dans le J13. |
| **D-10** | Catégorie de la Pépite dans le Sac | **AVENTURE**, comme la Pierre Lune du J12 (défaut : la catégorie « OBJETS » n'existe pas). Prix 10 000 ₽, vendue 5 000 ₽ (RB). Pas de bouton UTILISER. Une catégorie « TRÉSORS » pourra venir quand il y aura plusieurs objets de valeur. |
| **D-11** | Magasin de vélos | **Façade et intérieur visibles, avec un vendeur.** Vélo à 1 000 000 ₽, inaccessible (RB, gag connu). Pas de Bon pour Vélo au J13 : le vélo est un système du dossier 07, à concevoir. Alternative moins chère : façade seule, porte fermée. |
| **D-12** | Eau, pêche, Grotte Azurée | **Aucune interaction avec l'eau au J13.** La Grotte Azurée **peut être vue de loin** (entrée au-delà d'un bras d'eau, sans garde ni réplique), ce qui ne promet rien. Vendeur de Magicarpe et maison d'échange : pas au J13. |
| **D-13** | Boutique d'Azuria | **Stock d'Argenta, plus les remèdes du J11** (Anti-Para, Réveil, Antigel, Anti-Brûle s'ils existent après 11A). Pas de Repousse (reportée par le J12). Défaut, à confirmer au plan. |
| **D-14** | Ce que disent les indices du cambriolage | « On a vu un homme en noir partir par l'arrière. » **Rien de plus** : pas de « R », pas de nom. Le joueur fait le lien avec le Mont Sélénite s'il le veut. La révélation reste au J14. |
| **D-15** | Dresseurs de l'Arène | **Deux, combattables avant le rival** (C-1) : un **Nageur** (Hypotrempe et Kokiyas, Nv. 16, RB) et une **Jeune Dresseuse** (Poissirène Nv. 19, RB). Trois espèces **de Dresseur seulement** : données et face, sans dos ni évolution. Nouveau modèle peint : Nageur. Alternative moins chère : Poissirène seul pour les deux, mais l'Arène serait monotone. |
| **D-16** | Ordre de validation sur S24 | **13.0** art et données (espèces, Bulles d'O, Pépite, IA qui change) · **13A** Route 4 et Azuria (ville, Centre, Boutique, maisons, indices) · **13B** rival n° 3 et Arène (Ondine, badge, CT11) · **13C** Pont Pépite, recruteur, espace nord, clôture. Code après la clôture du J12. |

## 6. Ce qui est verrouillable tel quel

- Ville librement explorable dès l'arrivée : seule l'Arène dépend du rival.
- Aucun puzzle ni nage dans l'Arène.
- Carte de présentation « ONDINE — Championne d'Arène d'Azuria » : le composant existe.
- Inscription « BADGE CASCADE » et vibration, sans toast.
- Grand moment « badge » générique, enregistré une fois (existant).
- Le badge n'ouvre rien de nouveau au J13 : il reconnaît la victoire.
- Défaite sans perte d'argent (existant).
- Recruteur Rocket : ton légèrement inquiétant, sans système d'adhésion.
- Pas de Léo, de Route 25, de Route 5, de S.S. Anne ni de Passe Bateau.
- Rival : ni malveillant ni humiliant.
- Pas de marqueur d'objectif pour le cambriolage.

## 7. À fournir par la consolidation (dossier 16)

- **Textes définitifs** regroupés et numérotés : rival (introduction, reprise, victoire,
  défaite), Ondine (pont, invitation, Arène, badge, CT11), guide de l'Arène avant et après,
  recruteur, 5 Dresseurs du pont, Dresseurs de l'Arène et de la Route 4, habitants avant et après
  le badge, indices du cambriolage, panneaux, objectifs du tableau de bord.
- **Équipes exactes** et capacités, en signalant toute capacité absente du moteur.
- **Tables de rencontres** de la Route 4 et de la Route 24 nord.
- **Liste des drapeaux**.
- **Plan fonctionnel ASCII** d'Azuria, de la Route 4, de la Route 24 et de l'Arène.
- **Cas limites** :
  - défaite contre le rival, puis retour par le Mont Sélénite ;
  - partie quittée pendant la scène d'Ondine au pont ;
  - défaite contre le recruteur après avoir reçu la Pépite ;
  - Pépite vendue ;
  - partie sauvegardée dans le sas du J12 ;
  - badge obtenu avant la remise de la CT11 (patch).
