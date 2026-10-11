# J15 — En route vers Carmin-sur-Mer : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-11. J'ai relu la V2 contre `vision.md`, `roadmap.md`, les dossiers 06, 09, 11, 12
> et 15, le dossier 14 et le code du J11 (branche `origin/claude/lancement-j11-4pkt2k`), le plan
> `docs/tech/jalon-12.md`, les passes du J13 (`docs/dossier-16-j13` à `4c89696`, D-1 à D-16 **pas
> encore tranchés**) et du J14 (`docs/dossier-17-j14` à `d179274`, E-1 à E-15 **pas encore
> tranchés**), le code de `main` (`a34e433`) et, pour les données de Rouge/Bleu, le désassemblage
> `pret/pokered`. Aucune ligne de code avant le dossier validé.
>
> **Numéro de dossier : 18** (`dossier-18-carmin-sur-mer.md`). 13 = ouverture, 14 = systèmes du
> J11, 15 = J12, 16 = J13 (réservé), 17 = J14 (réservé). Le J16 prendra le **19**.
>
> La V2 est reproduite dans `j15-v2-chatgpt.md`. Ses **6 décisions verrouillées** ne sont pas
> rouvertes. Ses quatre arbitrages « E-1 à E-4 » sont renommés **V-1 à V-4** (les E-1 à E-15
> appartiennent au J14) et commentés au §4. Mes arbitrages sont numérotés **F-1 à F-16** (§5) ; un
> lot de textes proposés suit (§7). Un premier avis sur le J16 est au §8.
>
> Origine des règles : **RB** = Rouge/Bleu, **G+** = génération plus récente, **K26** = invention
> de Kanto 2026.

## 1. Les décisions verrouillées de la V2

D'accord avec les six (le tableau en compte sept lignes : Safrania est la septième). Aucune n'est à
rouvrir ; trois demandent une précision.

| # | V2 | Avis |
|---|---|---|
| 1 | Route 5, souterrain, Route 6, Carmin | Oui. **Route 5 et Route 6 de RB n'ont aucun Dresseur sur la Route 5** et 6 sur la Route 6 : conforme à la V2. |
| 2 | Pension fonctionnelle | Oui, mais **c'est le système le plus risqué depuis la sauvegarde** : nouvelle version de sauvegarde, montée de niveau hors combat, apprentissage hors combat (§2, points 1 à 5). À valider seul (règle 1 de `CLAUDE.md`). |
| 3 | Souterrain enrichi, découverte facultative | Oui. **RB n'y met aucune rencontre** : V-3 est fidèle. Le système d'objets cachés du J12 n'existe encore que sur plan (§2, point 8). |
| 4 | Carmin complète | Oui. Taille à surveiller (§3, F-12). |
| 5 | S.S. Anne visible, non explorable | Oui. Le verrou du J15 est **provisoire par nature** : dans le jeu final, le Passe Bateau suffit (RB). → **F-5**. |
| 6 | Arène présente, défi reporté | Oui, et **RB a déjà le verrou intégré au monde** : un arbre à couper devant l'entrée. Il colle exactement au découpage J16 (Coupe) → J17 (Major Bob). → **F-6**. |
| 7 | Safrania fermée, justification narrative | Oui. RB : les gardes ont soif (boisson du toit de Céladopole). La V2 a raison de ne rien annoncer de l'occupation. → **F-7**. |

## 2. Ce que l'audit du code et des données apporte

### Pension (audit du code)

1. **Aucun emplacement « hors équipe, hors boîte »** n'existe. `Party` (`party.gd`, 6 places) et
   `PokemonStorage` (liste sans limite) ont des règles pures dans `storage_rules.gd`
   (`can_deposit` → refus `LAST_POKEMON` / `LAST_ABLE` ; `can_withdraw` → `PARTY_FULL`). La Pension
   suivra ce modèle : un champ `daycare` dans `GameState` et des règles `DaycareRules` (dépôt,
   retrait, prix, refus `PARTY_FULL`, `NO_MONEY`, `EMPTY`, `OCCUPIED`).
2. **Sauvegarde : il faut une nouvelle version.** `main` est en v5 ; le J11 écrit la v6 (uid,
   compteur de statut, compagnon). La règle de `save_system.gd` (l. 21-26) impose une version dès
   qu'un champ serait effacé par une build plus ancienne : **la Pension écrit la v7**. J12, J13 et
   J14 ne changent pas le format ; si cela change, « le second fusionné renumérote ». Un Pokémon
   déposé relu par une build v6 serait **perdu** : c'est exactement le cas que la version protège.
3. **Identité du Pokémon.** Le J11 ajoute `Pokemon.uid` (16 caractères, attribué par `Party.add` et
   `PokemonStorage.add`) et `GameState.ensure_unique_uids()`, qui **ne parcourt que l'équipe et le
   Stockage**. La Pension devra y être incluse, ainsi que dans la règle du compagnon : le compagnon
   est retrouvé par son uid **dans l'équipe seulement**, et la règle « effacé s'il quitte l'équipe »
   (jalon-11-compagnon l. 82-83) n'est pas encore codée. Un compagnon déposé doit être effacé.
4. **Montée de niveau hors combat : aucun précédent.** `Pokemon.gain_exp()` (pokemon.gd l. 163)
   gère plusieurs niveaux d'un coup, plafonne au niveau 100 et rend la liste des `LevelUp` (capacités
   dues incluses), mais **n'apprend rien lui-même** ; son seul appelant est le combat
   (`battle.gd:676`). Il n'y a pas de Super Bonbon. **L'XP de la Pension doit rester en attente**
   hors de `experience` et passer par `gain_exp` au retrait ; écrire directement dans `experience`
   désynchroniserait niveau et XP (`from_dict` ne recalcule pas le niveau).
   - **Synergie avec le J14** : son E-6 recommande un Super Bonbon, qui demande exactement le même
     parcours (niveau → capacités → évolution, hors combat). Le premier des deux jalons codé le
     crée, l'autre le réutilise.
5. **Apprentissage hors combat : l'écran existe, pas son hôte.** `MoveLearnPrompt.teach()`
   (`move_learn_prompt.gd` l. 48 : « veut apprendre… oublier ? ») sert déjà hors combat à
   l'`EvolutionDirector`, une capacité à la fois ; il lui faut un `BattleMessageBanner` et un
   `Control` hôte, qu'aucun écran de carte ne fournit. Sans écran, rien n'est décidé à la place du
   joueur (l. 62-64) : **aucun oubli automatique n'est possible pour un Pokémon du joueur**. Le seul
   « garder les 4 dernières » (`SpeciesData.moves_at`) ne sert qu'à créer les sauvages et les
   Pokémon de Dresseurs. V-2 est donc compatible avec le moteur.
6. **Évolution.** Elle n'est proposée qu'en fin de combat gagné ou de capture, pour un Pokémon qui a
   gagné un niveau **dans ce combat** (`Evolution.candidates()` l. 43). Un Pokémon rendu au-delà de
   son niveau d'évolution n'évoluerait qu'au **prochain niveau gagné en combat** (comportement RB,
   mais surprenant). Le J12 crée l'évolution hors combat (Pierre Lune). → **F-3**.
7. **Pas du joueur.** Le signal `Player.moved(cell)` existe (player.gd l. 13), mais il est aussi émis
   pendant les pas scriptés : il faut filtrer par `is_input_enabled()` comme `SceneRouter`. Aucun
   compteur n'existe. Le poison ne fait rien en marchant (J9). L'autosave n'écrit pas à chaque pas :
   si l'application est tuée, quelques pas sont perdus, sans risque de duplication. Acceptable.
8. **Argent et dialogues.** `GameState.spend_money()` refuse sans effet ; `MONEY_MAX = 999 999`.
   `DialogueChoice` (Oui / Non) et `PartyPicker` (choix d'un Pokémon avec raisons de refus)
   existent. **Il manque** : une action de service `open_daycare` (liste fermée
   `DialogueLibrary.ACTIONS`) et des jetons `{pokemon}`, `{levels}` et `{price}` (aujourd'hui :
   `first_wild_species`, `player`, `rival` seulement).
9. **Statuts.** Le statut est persistant et n'est effacé que par un soin. Un Pokémon empoisonné
   déposé reste empoisonné tant qu'une règle ne dit pas le contraire. → défaut au §6.

### Contenu, données et assets

10. **Espèces (RB, `Route5.asm` et `Route6.asm` : même table)** : Mystherbe (Rouge) / Chétiflor
    (Bleu), Roucool, Férosinge (Rouge) / Miaouss (Bleu), niveaux 10 à 16. Roucool et Férosinge
    existent sur `main` (38 espèces ; 50 après le J12).
    - **Si le J13 retient D-8** (Mystherbe et Chétiflor, avec Ortide et Boustiflor) : il ne reste
      que **Miaouss** et **Persan** (niveau 28, atteignable en s'entraînant).
    - **Sinon** : 6 espèces nouvelles (Mystherbe, Ortide, Chétiflor, Boustiflor, Miaouss, Persan).
    - Pas d'Abra sur les Routes 5 et 6 (RB) : rien ne dépend de l'E-3 du J14.
    - Artwork de face : les 151 existent. **Dos : 20 sprites provisoires en pixel art seulement**,
      aucun dos peint branché ; la dette du J12, J13 et J14 s'accumule. → **F-10**.
11. **Dresseurs de la Route 6 (RB)** : 6, et **toutes leurs espèces existent déjà** (Carapuce,
    Rattata, Pikachu, Piafabec, Rattatac, Roucool, Aspicot, Chenipan, Papilusion). Quatre « Jr
    Trainer » rangés **par paires côte à côte** : Kanto 2026 n'a pas de combat en duo, ils
    deviennent deux combats séparés. Modèles peints existants : `scout`, `youngster`, `camper`,
    `lass` (et `lass_young` au J12). Écart déjà présent : le projet paie le Scout 12 ₽ par niveau
    (dossier 15), RB 10. → **F-11**.
12. **Objets cachés.** Le modèle **existant** se déclenche en marchant sur la case (Route 2,
    `route_2_item_3`). Le modèle **du J12** (EXAMINER face à un indice sur une case bloquée,
    `InteractPoint.unless_flags`, toast, `got_<id>`, aucun nouveau champ de sauvegarde) **n'est que
    planifié** : `jalon-12` pointe encore sur `main`. Le souterrain RB cache **2 objets** :
    Guérison (`FULL_RESTORE`) près de l'entrée nord et Spécial + (`X_SPECIAL`) vers le sud ; Carmin
    en cache 1 (Huile Max). **Aucun de ces objets n'existe** (`items.json` en compte 4). → **F-9**.
13. **Postes de garde.** Le modèle à deux sorties existe (`_forest_gate()` de
    `build_painted_interiors.gd`, 10 × 8, deux paires de portes, un garde) ; il a servi deux fois
    pour la Forêt de Jade. Le garde qui bloque existe aussi (`route_3_guard`, Argenta : réplique
    puis recul d'une case). **Rien à créer.**
14. **Raccords « à venir ».** `Warp.coming_soon` montre « X — À venir » en build de développement et
    bloque le bord en release. Il servira pour la Route 11 (est de Carmin) et, si F-5 le retient,
    jamais pour le navire (verrou diégétique demandé par la V2).
15. **Catégorie du souterrain.** `zones.json` ne connaît ni `route_5`, ni `route_6`, ni le
    souterrain (`vermilion_city` et `saffron_city` existent, sans carte). Le J12 crée la catégorie
    « grotte » (`data/world/caves.json`), qui **autorise la Corde Sortie**. Un souterrain dans cette
    liste la rendrait utilisable ; un intérieur, lui, ne précharge pas ses voisines. → défaut §6.
16. **Passe Bateau.** Aucun objet clé n'existe à part `oak_parcel`. Il est créé par le J14 (objet
    clé invendable, sans UTILISER). **Le J14 (V-3) rend les histoires de Léo et du cambriolage
    indépendantes** : un joueur peut atteindre le J15 **sans le Passe Bateau**. Le J15 ne doit donc
    rien supposer de la visite à Léo ; seul le S.S. Anne (J16) le demandera.
17. **Vélo, pêche, Coupe : trois systèmes non conçus.** Le « Dossier 07 — Exploration et monde
    vivant » annoncé par le dossier 06 (l. 67 : pêche, vélo, Surf) **n'existe pas** (le numéro 07 a
    servi à la Route 1). Or Carmin porte, dans RB, **trois déclencheurs** de ces systèmes :
    - le **Bon pour Vélo** (président du Fan Club) ;
    - la **Canne** (Maître Pêcheur) ;
    - la **Coupe** (capitaine du S.S. Anne, J16), qui ouvre l'Arène.

    Le J13 (D-11) a déjà recommandé un magasin de vélos sans Bon. → **F-8, V-4**.
18. **Dépendance du raccord nord.** La sortie sud d'Azuria est ouverte par le J14 (E-10 : barrage de
    police levé après la victoire contre le Rocket). Le J14 passe le relais : carte `route_5`,
    arrivée `from_cerulean`, repère de coordonnées ; avant le J15, le bord sud mène à
    « ROUTE 5 — À venir » en développement. **Si l'E-10 du J14 est refusé**, la Route 5 est libre
    dès l'arrivée à Azuria (comme dans RB) et le J15 devient accessible avant la Route 25.
19. **Dépendances de code.** Le code du J15 vient **après la clôture du J14**, elle-même après le
    J13, le J12 et le J11 :
    - **J11** : sauvegarde v6, uid, compagnon, remèdes ;
    - **J12** : objets cachés (EXAMINER), évolution hors combat, catégorie grotte ;
    - **J13** : Azuria, Mystherbe et Chétiflor (D-8) ;
    - **J14** : Passe Bateau, barrage sud, Super Bonbon (E-6).

    Exception possible : la **logique pure de la Pension** (règles, prix, XP en attente), sans écran
    ni carte, une fois la v6 du J11 fusionnée, sur le modèle d'OUV.0. Le dossier, les grilles, les
    vues peintes et l'art peuvent avancer en parallèle.

## 3. Plan et déplacements

- **Angles droits** (dossiers 01 et 07) : quais rectilignes, pontons perpendiculaires au rivage,
  coque du navire parallèle au quai. Aucune côte en diagonale.
- **L'eau reste un obstacle** (pas de Surf ni de pêche, J13 D-12).
- **Échelle.** RB : Routes 5 et 6 en 20 × 36, Carmin en 40 × 36, souterrain en 8 × 48. Le projet
  agrandit d'environ 2 fois les routes (Route 2 : 42 × 60).

  | Carte | V2 | Comparaison | Avis |
  |---|---|---|---|
  | Route 5 | 42 × 62 | Route 2 (42 × 60, ≈ 2 700 nœuds) | Tenable. |
  | Souterrain | 18 × 70 | aucune carte aussi longue sans décor | 70 cases en ligne droite sans rencontre ≈ 25 s de marche : **raccourcir** (F-9). |
  | Carmin | 72 × 54 | 1,7 × Argenta, 1,9 × Jadielle | **Plus grande ville du jeu**, avec de l'eau animée et un navire : risque de dépasser les nœuds et la mémoire (F-12). |

- **Budget** : ≤ 3 000 nœuds par carte, mémoire = carte + voisines (J10). À mesurer dès la grille.
- **Sorties de Carmin** :

  | Sortie | État au J15 |
  |---|---|
  | Nord | Route 6, ouverte |
  | Est | Route 11 (Grotte Taupiqueur, Route 12) : fermée, « ROUTE 11 — À venir » en développement |
  | Sud | Quai et S.S. Anne : fermé de façon diégétique (F-5) |
  | Arène | Arbre devant l'entrée (F-6) |

- **Filière habituelle** : grille `tools/plans/*.txt` et `plan_check` (combats inévitables,
  chemins), puis vue générale peinte validée par Kevin, puis la carte. Les images de la V2 servent
  à l'ambiance seulement et **ne vont pas dans le dépôt** (droits).

## 4. Les arbitrages de la V2 (V-1 à V-4)

| # | V2 | Avis |
|---|---|---|
| **V-1** | Un Pokémon à la fois, sans reproduction | **Oui** (RB). Aucun Œuf, aucun objet tenu, aucun choix de compatibilité. |
| **V-2** | Capacités : apprentissage proposé au retrait, sans oubli automatique | **Oui.** Au retrait, on rejoue **dans l'ordre** chaque capacité due à chaque niveau gagné, avec l'écran existant (« veut apprendre… oublier ? »). Refuser = la capacité n'est pas apprise (choix du joueur, comme en combat). **Écart RB assumé** : RB remplaçait la plus ancienne capacité sans rien demander. Il n'existe pas de Maître des Capacités : une capacité refusée est perdue pour ce Pokémon, comme en combat. |
| **V-3** | Souterrain sans rencontres, une découverte cachée | **Oui** (RB). Voir F-9 pour l'objet et la longueur. |
| **V-4** | Maison du Pêcheur présente, pêche reportée | **Oui.** Le Pêcheur parle de pêche sans rien donner. Quand la pêche sera conçue, il donnera la Canne à la prochaine visite (drapeau `got_old_rod`) : **aucun joueur ne rate rien**. Un modèle peint de pêcheur existe déjà (`haru`, planche `pecheur`). |

## 5. Arbitrages à trancher (F-1 à F-16)

| # | Question | Recommandation |
|---|---|---|
| **F-1** | XP de la Pension | **RB : 1 XP par pas** du joueur, quelle que soit la carte. Les pas scriptés ne comptent pas, la course compte comme la marche, un pas refusé (mur) ne compte pas. Plafond = niveau 100. L'XP est **en attente** et n'est appliquée qu'au retrait. |
| **F-2** | Prix du retrait | **RB : 100 ₽ + 100 ₽ par niveau gagné.** Si l'argent manque : **la Pension rend quand même le Pokémon et prend tout l'argent du joueur** (*K26*). RB refusait, ce qui pouvait bloquer un Pokémon sans source d'argent (les Dresseurs ne se rejouent pas). Alternative : refus RB. |
| **F-3** | Évolution d'un Pokémon qui a dépassé son niveau | **Proposée au retrait**, après les capacités, avec l'écran d'évolution existant (annulable) : le même parcours que le Super Bonbon (J14 E-6) et la Pierre Lune (J12). Rien ne se passe **pendant** le séjour : la décision « pas d'évolution automatique à la Pension » est respectée. Alternative RB : rien au retrait, évolution au prochain niveau gagné en combat (surprenant). |
| **F-4** | Ce que le joueur voit du séjour | Le gardien annonce le **nombre de niveaux gagnés et le prix** avant la confirmation (jetons `{pokemon}`, `{levels}`, `{price}`). **Pas de Pokémon visible au jardin** au J15 (peu d'espèces peintes dans le monde : 13) : le jardin est un décor. À reprendre à la phase DA. |
| **F-5** | Verrou du S.S. Anne | **Deux temps.** Au J15 : un marin devant la passerelle, réplique **provisoire** (« l'équipage prépare la croisière, l'embarquement n'a pas commencé »), identique avec ou sans Passe Bateau, retirée au J16. Au J16 : la règle **permanente** est celle de RB (le Passe Bateau suffit). On ne crée pas de condition artificielle permanente. |
| **F-6** | Verrou de l'Arène de Major Bob | **L'arbre de RB**, devant l'entrée : obstacle « arbre » déjà posé sur la Route 2 (FUTUR A), même mécanique future (Coupe). Le panneau de l'Arène se lit ; les habitants parlent de Major Bob. Aucun garde, aucune porte fermée. Il tombe avec Coupe (J16 ou J17, voir §8). Alternative : un guide qui dit que Major Bob est absent (raison inventée, moins solide). |
| **F-7** | Raison de la fermeture de Safrania | **Une fermeture officielle, sans motif donné** : « La route de Safrania est fermée. Ordre de la ville. Je n'en sais pas plus. » Le garde **renvoie vers le souterrain** (aide au chemin). Rien n'annonce la Team Rocket ; le déblocage reste à décider avec l'arc Rocket (roadmap : « non décidé »). Alternative : la soif de RB (gag), qui impose une boisson à Céladopole. |
| **F-8** | Fan Club et Bon pour Vélo | **Fan Club présent, président bavard, Bon pour Vélo reporté** au système du vélo (non conçu). Il le donnera à la prochaine visite une fois le vélo prêt (`got_bike_voucher`). Cohérent avec le J13 D-11 (magasin sans Bon). Alternative : donner le Bon maintenant, sans vélo achetable : un objet clé inutile. |
| **F-9** | Souterrain | **Longueur ≤ 50 cases**, deux coudes à angle droit, 3 alcôves ; **un seul objet caché : Guérison** (RB, objet nouveau : soin total + statut, simple donnée de soin du Sac), selon le modèle du J12 (EXAMINER face à un indice). **Pas de Spécial +** : les objets X n'existent pas en combat. Un PNJ passant au milieu (respiration). Alternative : Super Potion (moins mémorable). |
| **F-10** | Espèces nouvelles | **Miaouss et Persan**, les deux versions réunies comme au J12 (Mystherbe et Chétiflor viennent du J13 si D-8 est retenu ; sinon, ils viennent ici, avec leurs évolutions). Table RB pour les deux routes, niveaux 10 à 16. Données, face ; dos provisoires selon la dette. Alternative à coût nul : seulement des espèces existantes. |
| **F-11** | Dresseurs de la Route 6 | **Les 6 de RB**, avec leurs équipes RB (aucune espèce nouvelle) : **1 inévitable au plus**, les autres dans des poches latérales (`plan_check`). Les paires RB deviennent deux combats voisins. Classes : Scout ×2, Campeur ×2, Jeune Dresseuse ×2 (modèles existants). Alternative V2 : 4 Dresseurs. |
| **F-12** | Taille de Carmin | **Cible ≤ 64 × 48**, mesurée à la grille. Si elle dépasse 3 000 nœuds : le quai du S.S. Anne devient une **carte séparée** (`vermilion_dock`, comme dans RB). Alternative : 72 × 54 et risque de dépassement. |
| **F-13** | Lieux RB de Carmin | **Gardés** : Centre, Boutique, Arène (arbre), Fan Club, maison du Pêcheur, quai, 2 maisons d'habitants. **Exclus** : maison d'échange (Canarticho) et échange « SPOT » de la Route 5 (aucun système d'échange) ; maison de la lettre de Roucool (gag sans système). Défaut. |
| **F-14** | Boutique de Carmin | Stock d'Azuria (J13 D-13) **plus Super Potion** (RB, objet nouveau). Pas de Repousse (reportée au J12). Défaut, à confirmer au plan. |
| **F-15** | Ordre de validation sur S24 | **15.0** Pension seule (logique pure, sauvegarde v7, migration v6→v7, tests) : **validée isolément** (système risqué). **15A** Route 5, Pension sur la carte, poste nord, souterrain. **15B** Route 6, Carmin, port, garde, Arène, Fan Club, Pêcheur, clôture. Code après la clôture du J14. |
| **F-16** | Roadmap | Écrire l'ordre réel dans `roadmap.md` (« Ordre immédiat » s'arrête au J12+) : J12 Route 3 et Mont Sélénite · J13 Azuria et Ondine · J14 Cap d'Azuria et Léo · J15 Route 5, Route 6, Carmin · J16 S.S. Anne · J17 Major Bob. Je l'écris après ta validation. |

## 6. Ce qui est verrouillable tel quel (défauts)

- **Pension** : gardien au comptoir d'un petit bâtiment (modèle `old_man`) ; le dépôt refuse le
  dernier Pokémon apte (`LAST_ABLE`, règle du Stockage) ; un Pokémon K.O. peut être déposé.
- **Soin complet au retrait** (PV, statut) : simple, cohérent avec un séjour.
- **Compagnon** : déposer le compagnon l'efface, le joueur en choisit un autre (règle du J11).
- **Grands moments** : aucun pour la Pension.
- **Pokédex** : un Pokémon déposé reste « capturé » ; rien ne change.
- **Souterrain** : carte **non** listée dans `caves.json` (pas de Corde Sortie), sans ciel, avec un
  profil de lumière dédié (éclairage mural) ; compagnon visible comme sur une route ; deux postes
  d'entrée sur le modèle `_forest_gate`.
- **Poste de garde nord (Route 5)** et **poste de garde de la Route 6** : modèle `_forest_gate`, la
  porte côté Safrania gardée.
- **Route 11** : bord fermé, « ROUTE 11 — À venir » en développement.
- **Aucun rival**, aucun Rocket visible, aucun combat de Champion.
- **Aucune nouvelle version de sauvegarde en dehors de la Pension** : Dresseurs (`beaten_<id>`),
  objets (`got_<id>`), postes et drapeaux tiennent dans les champs existants.

## 7. Lot de textes proposés (à relire en un seul lot)

> Propositions de départ pour la consolidation ; les réponses à F-2, F-5, F-7 et F-8 peuvent les
> modifier. `{pokemon}`, `{levels}` et `{price}` sont les jetons nouveaux de F-4.

### Pension (Route 5)

| # | Moment | Texte |
|---|---|---|
| T-1 | Panneau | « PENSION POKÉMON — Nous gardons votre Pokémon pendant votre voyage. » |
| T-2 | Premier dialogue, Pension vide | « Bienvenue à la Pension ! Je garde un Pokémon pendant que tu voyages. » / « Il s'entraîne un peu à chaque pas que tu fais. Tu veux m'en confier un ? » [Oui / Non] |
| T-3 | Non | « Reviens quand tu veux. » |
| T-4 | Choix | « Lequel veux-tu me confier ? » |
| T-5 | Dernier Pokémon apte | « Tu ne peux pas partir sans un Pokémon en forme. » |
| T-6 | Dépôt | « Très bien. Je m'occupe de {pokemon}. Reviens le chercher quand tu veux. » |
| T-7 | Visite, aucun niveau gagné | « {pokemon} va très bien. Il n'a pas encore beaucoup changé. » / « Tu veux le reprendre ? Ce sera {price} ₽. » [Oui / Non] |
| T-8 | Visite, niveaux gagnés | « Ah, te voilà ! {pokemon} a gagné {levels} niveau(x). » / « Tu veux le reprendre ? Ce sera {price} ₽. » [Oui / Non] |
| T-9 | Équipe pleine | « Ton équipe est complète. Fais-lui une place d'abord. » |
| T-10 | Retrait | « Merci ! Voici {pokemon}. Il est en pleine forme. » |
| T-11 | Argent insuffisant (F-2 retenu) | « Tu n'as pas tout à fait assez… Ce n'est rien, je prends ce que tu as. » / « Voici {pokemon}. » |
| T-12 | Après le retrait | « Je garde toujours une place. Reviens quand tu veux. » |

### Route 5, souterrain, Route 6

| # | Moment | Texte |
|---|---|---|
| T-13 | Panneau Route 5 | « ROUTE 5 — Azuria ↔ Safrania » |
| T-14 | Panneau du souterrain | « PASSAGE SOUTERRAIN — Route 5 ↔ Route 6 » |
| T-15 | Garde, poste de la Route 5 | « Halte ! La route de Safrania est fermée. » / « Ordre de la ville. Je n'en sais pas plus, désolé. » |
| T-16 | Garde, deuxième fois | « Toujours fermé. Si tu vas vers Carmin-sur-Mer, prends le passage souterrain. » |
| T-17 | Garde, poste de la Route 6 | « Désolé, personne n'entre à Safrania en ce moment. » / « Ordre de la ville. » |
| T-18 | Passant du souterrain | « On dit que ce passage est plus vieux que les routes. » / « Il y a des recoins où personne ne regarde jamais. » |
| T-19 | Indice (EXAMINER) | « Une pierre est descellée dans le mur. Quelque chose est coincé derrière. » → toast « Guérison obtenue » |
| T-20 | Panneau Route 6 | « ROUTE 6 — Safrania ↔ Carmin-sur-Mer » |
| T-21 | 6 Dresseurs | Avant / défaite / après : à écrire au dossier, une réplique de chaque, ton léger (deux paires d'amis, deux Scouts). |

### Carmin-sur-Mer

| # | Moment | Texte |
|---|---|---|
| T-22 | Panneau d'entrée | « CARMIN-SUR-MER — Le port des grands départs » |
| T-23 | Marin de la passerelle (J15, provisoire, F-5) | « Le S.S. Anne est à quai pour quelques jours. » / « L'équipage prépare la croisière. L'embarquement n'a pas encore commencé. » |
| T-24 | Docker | « Ce paquebot fait le tour du monde. Les Dresseurs à bord viennent de partout. » |
| T-25 | Arbre de l'Arène (EXAMINER) | « Un jeune arbre pousse devant l'entrée. Impossible de passer. » |
| T-26 | Panneau de l'Arène | « ARÈNE DE CARMIN-SUR-MER — Champion : Major Bob » (sous-titre à valider) |
| T-27 | Habitant, Major Bob | « Major Bob a servi dans l'armée, autrefois. » / « Ses Pokémon Électrik l'ont sorti de bien des situations. » |
| T-28 | Habitant, l'arbre | « Cet arbre devant l'Arène ? Il a poussé tout seul. Major Bob dit que les vrais challengers trouveront un moyen. » |
| T-29 | Président du Fan Club (F-8) | « Tu aimes les Pokémon ? Alors écoute-moi parler de mon Ponyta ! » / « … » / « Reviens quand tu veux, j'ai toujours une histoire à raconter ! » |
| T-30 | Pêcheur (V-4) | « Je suis le meilleur pêcheur de Carmin ! » / « La mer est pleine de Pokémon. Un jour, je t'apprendrai. » |
| T-31 | Habitant, Safrania | « Safrania est fermée depuis quelque temps. Personne ne sait vraiment pourquoi. » |

## 8. Premier avis sur le J16 (avant-projet V1)

Les six choix du J16 sont à toi ; voici ce que les documents existants en disent.

| # | Choix | Avis |
|---|---|---|
| 1 | Périmètre | **S.S. Anne seul, Major Bob au J17.** D'accord avec la V1. |
| 2 | Intérieur | **Plusieurs ponts**, en réutilisant **une enveloppe de cabine** peinte pour toutes les cabines (modèle des intérieurs 15 × 10). Budget mémoire : chaque pont est une carte. |
| 3 | Rival n° 4 | **L'histoire continue après une défaite** (dossier 09 §15 : « l'issue est acceptée par l'histoire »). Le J13 fait déjà une exception pour le rival n° 3 ; en faire une deuxième affaiblit la règle. Le Grand moment est écrit dans les deux cas (roadmap). |
| 4 | Capitaine | **Épisode historique conservé**, comme Léo transformé en Pokémon au J14. |
| 5 | Coupe | **Attention : « capacité en combat et hors combat » contredit une règle verrouillée.** Le dossier 06 §11 (« non négociable ») dit que les ex-CS n'occupent **jamais** un des 4 emplacements de combat. Coupe est donc **une capacité d'exploration**, sans usage en combat. Je recommande de l'obtenir **et** de pouvoir l'utiliser dans le monde **dès le J16** (dans RB, le Badge Cascade suffit, et il est obtenu au J13). C'est au J16 que se conçoit le menu des capacités d'exploration, reporté par le J14 (E-9). L'arbre de l'Arène tombe ; la porte mène à « À venir » en développement jusqu'au J17. |
| 6 | Départ du navire | **Il appareille après la sortie définitive, avec confirmation** (RB). Liberté sans blocage définitif : rien d'obligatoire ne reste à bord (Coupe est remise avant la sortie), les objets à bord restent facultatifs. Option à garder pour le post-game : le navire revient. |

## 9. À fournir par la consolidation (dossier 18)

- **Textes définitifs** à partir du §7 : les 6 Dresseurs de la Route 6, les habitants de Carmin
  (avant et après le J16 pour le marin), la Boutique, le Centre, les descriptions d'objets
  (Guérison, Super Potion), les entrées du Pokédex des espèces nouvelles et les objectifs du
  tableau de bord.
- **Règles complètes de la Pension** : F-1 à F-4, cas limites, jetons.
- **Équipes exactes** et capacités, en signalant toute capacité absente du moteur.
- **Tables de rencontres** des Routes 5 et 6.
- **Liste des drapeaux**.
- **Plan fonctionnel ASCII** : Route 5, Pension, souterrain, Route 6, Carmin (quai, Arène).
- **Relais** : reçu du J14 (`route_5`, `from_cerulean`) ; passé au J16 (`vermilion_dock` ou quai
  dans `vermilion_city`, passerelle) et au J17 (Arène).
- **Cas limites** :
  - déposer le compagnon ;
  - déposer puis quitter l'application avant l'autosave ;
  - retirer avec l'équipe pleine ;
  - retirer sans assez d'argent ;
  - Pokémon déposé au niveau 99 ou 100 ;
  - plusieurs capacités dues, toutes refusées ;
  - évolution annulée au retrait ;
  - Pokémon empoisonné déposé ;
  - partie sauvegardée sur le raccord « ROUTE 5 — À venir » du J14 ;
  - partie v6 chargée par la build v7, et l'inverse (refus) ;
  - arrivée à Carmin sans Passe Bateau, puis avec.
