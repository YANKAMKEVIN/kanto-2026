# J14 — Le mystère du Cap d'Azuria : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-11. J'ai relu la V2 contre `vision.md`, `roadmap.md`, les dossiers 02, 06, 09 et
> 15, le dossier 14 et le code du J11 (branche `origin/claude/lancement-j11-4pkt2k` à `1f7a880`),
> le plan `docs/tech/jalon-12.md`, la passe du J13 (`docs/dossier-16-j13` à `4c89696`, arbitrages
> D-1 à D-16 **pas encore tranchés**) et le code de `main` (`a34e433`). Aucune ligne de code avant le
> dossier validé.
>
> **Numéro de dossier : 17** (`dossier-17-cap-azuria.md`). Vérifié libre sur toutes les branches :
> 13 = ouverture, 14 = systèmes du J11, 15 = J12, 16 = J13 (réservé, pas encore écrit).
>
> La V2 est reproduite dans `j14-v2-chatgpt.md`. Ses **8 arbitrages créatifs** ne sont pas rouverts.
> Ses trois points ouverts (« D-1 à D-3 » de la V2) sont commentés au §4 sous les noms **V-1 à V-3**,
> pour ne pas les confondre avec les D-1 à D-16 du J13. Mes arbitrages sont numérotés **E-1 à E-15**
> (§5) : on y répond par numéro.
>
> Origine des règles : **RB** = Rouge/Bleu, **G+** = génération plus récente, **K26** = invention
> de Kanto 2026.

## 1. Les 8 arbitrages de la V2

D'accord avec les huit. Deux demandent une précision, aucun n'est à rouvrir.

| # | V2 | Avis |
|---|---|---|
| 1 | Léo transformé en Mélofée | Oui (RB). La planche d'exploration de Mélofée est déjà au kit du J12 (T3, repos + marche 4 directions) : **réutilisable telle quelle** (E-4). |
| 2 | Plusieurs interactions courtes sur la machine | Oui. **Tout existe** : objets interactifs, verbe EXAMINER (J12, Q-2), drapeaux, variantes de dialogue. Une seule chose manque : l'effet de la transformation (point 6). |
| 3 | Passe Bateau + objet supplémentaire | Oui pour le Passe Bateau (objet clé : invendable, déjà géré). **L'objet supplémentaire est un écart avec RB**, où Léo ne donne que le ticket. Coût selon l'objet : V-1, E-6. |
| 4 | Route 25 : 5 à 7 Dresseurs, majorité facultative | Oui. RB en compte davantage sur un sentier étroit, presque tous inévitables : la grille devra **élargir le chemin** pour que la majorité soit vraiment évitable (`plan_check` le vérifie). |
| 5 | Rocket : combat et courte poursuite | Oui. **Aucune mécanique nouvelle** : marche scriptée (`move` en arrière-plan), puis le joueur marche librement jusqu'au point d'arrêt, où la vue du Dresseur déclenche le combat. Rejouable sur le modèle de Pierre (point 4). |
| 6 | CT28 Tunnel fonctionnelle | Oui, mais **c'est la grosse mécanique du J14** : les attaques en deux tours ont été **reportées par le J11** (dossier 14, ligne « deux tours : Lance-Soleil, Coud'Krâne → reporté »). `dig` n'existe pas dans `moves.json` ; seule la table des CT du J11 la nomme. Point 3, E-7, E-8. |
| 7 | Sortie sud ouverte après le cambriolage | Oui, mais **écart avec RB** : la Route 5 y est libre dès l'arrivée, et le Sbire du jardin bloque l'**est** (vers la Route 9), pas le sud. Il faut une raison visible dans le monde (E-10). |
| 8 | Compagnon sur la Route 25, rappelé chez Léo | Oui, et **c'est déjà la règle du J11** : le compagnon rentre dans sa Ball dans toute carte d'intérieur et ressort en sortant ; il reste choisi par son `uid` (dossier 14, décision 5 et §8). **Rien à coder.** |

## 2. Ce que la V2 oublie ou contredit

1. **Deux personnages s'appellent Léo.** L'enfant de Bourg Palette qui joue avec son Rattata
   s'appelle déjà Léo (dossier 02 §4, `data/npcs/pallet_town.json` id `leo`,
   `data/dialogues/pallet_town.json`). Le dossier 06 (post-game) cite « Mme Aoki, Léo » : on ne sait
   plus lequel. Léo est le nom français officiel du personnage de RB. → **E-1**.
2. **Qui a créé le stockage ?** Dans RB, Léo a inventé le système de stockage des PC. Kanto 2026
   l'attribue au **système de recherche de Chen** (dossier 09 §8 : « {Pokémon} a été confié au
   système de recherche de Chen »). Si Léo s'en dit l'inventeur, les deux récits se contredisent.
   → **E-2**.
3. **Abra est absent de la V2.** Le J13 l'a reporté ici (D-9, Route 25, RB). Il cache **deux
   mécaniques** :
   - **la fuite adverse** : un Abra sauvage n'a que Téléport et s'enfuit au premier tour ; le moteur
     ne sait faire fuir que le joueur (`BattleRules.can_flee`) ;
   - **l'évolution par échange** : Abra évolue en Kadabra au niveau 16, donc **pendant le J14**.
     Kadabra → Alakazam se fait par échange. Le format existe (`"method": "trade"`, déjà utilisé par
     Gravalanche) mais `evolution_rule.gd` dit : « aucune logique de jeu ne les déclenche
     (adaptation solo à décider par Kevin) ».

   → **E-3**.
4. **Tunnel en combat = un état de combat nouveau.** Il faut :
   - un **tour de préparation** (« {pokemon} creuse un trou ! ») ;
   - un état « **sous terre** » où le Pokémon est **intouchable**, avec son sprite caché ;
   - un **tour de frappe** dont l'action est verrouillée.

   Le verrou d'action ressemble à celui de **Patience** (CT34, J11 §6.3 : « Tour 2 : action
   verrouillée »), mais **Patience n'est pas encore codée** (le J11 en est à T3). Il faut aussi
   régler ses interactions avec les statuts du J11 (sommeil, paralysie, gel, confusion,
   apeurement), le changement de Pokémon, l'IA et la capture. Le mécanisme servira ensuite à
   Lance-Soleil, Coud'Krâne et **Vol** : il vaut mieux le concevoir **général**. → **E-7, E-8**.
5. **Tunnel hors combat.** Dans RB, Tunnel s'utilise hors combat comme une Corde Sortie. Kanto 2026
   a tout ce qu'il faut pour la règle : la Corde Sortie du J12 (`FieldItemRules`,
   `data/world/caves.json`, sortie de la grotte, ni soin ni point de repos touchés). En revanche,
   **l'entrée de menu manque** : on ne peut pas utiliser une capacité depuis la fiche d'un Pokémon.
   Or le dossier 06 §11 prévoit justement ce menu pour les ex-CS (Coupe, Surf, Force, Flash, Vol),
   et **Coupe arrive avec le S.S. Anne**. Créer ce menu pour Tunnel seul revient à concevoir trop
   tôt celui des ex-CS, pour un seul usage (le Mont Sélénite, que la Corde Sortie couvre déjà).
   → **V-2, E-9**.
6. **La transformation demande un effet nouveau.** Les étapes de scène existantes (`move`,
   `despawn`, `spawn`, `face`, `wait`, `dialogue`…) suffisent pour l'entrée de Léo dans la cabine et
   sa sortie. Il n'existe en revanche **aucun flash ni effet d'écran** dans les scènes (la séquence
   d'évolution en a un, mais hors du directeur de scènes). → une **petite étape nouvelle**
   (`flash` ou effet de machine), réutilisable. Défaut au plan.
7. **Super Bonbon = montée de niveau hors combat.** Rien ne fait monter un niveau hors combat
   aujourd'hui. Il faudrait enchaîner, depuis le Sac :
   - le gain de niveau ;
   - l'apprentissage d'une capacité, avec « oublier une capacité » (l'écran viendra des CT du
     J11, 11B) ;
   - l'évolution hors combat (elle viendra de la Pierre Lune du J12).

   C'est faisable, mais c'est un **parcours d'objet nouveau**, à mettre en balance avec la règle
   « petit, utile, pas déséquilibrant ». → **V-1, E-6**.
8. **L'ordre libre (V-3) diffère de RB.** Dans RB, la maison cambriolée est gardée par un policier
   **jusqu'à la visite chez Léo** : l'ordre est imposé. La V2 rend les deux histoires indépendantes.
   C'est cohérent avec « liberté sans blocage définitif » (le Passe Bateau reste à prendre plus
   tard, la Route 25 reste ouverte). Conséquence à assumer : **un joueur peut partir vers le J15
   sans être allé chez Léo**. Le J15 ne devra donc rien supposer de la visite à Léo, sauf au S.S.
   Anne. → **V-3**.
9. **Accès à la Route 25 : il dépend de réponses du J13.** La V2 dit que le rival suffit à ouvrir le
   nord. Mais entre le rival et la Route 25 il y a **le Pont Pépite et le recruteur** (J13 C-4 :
   combat après le refus, Pépite remise avant). Le J13 ne dit pas encore si le recruteur **bloque**
   le passage tant qu'il n'est pas battu (RB : oui, il se tient au bout du pont). Le J13 a aussi
   prévu un raccord « ROUTE 25 — À venir » au bout de la Route 24 nord (C-7), que le J14 remplace.
   → **E-11**.
10. **Mélofée : un sauvage existe déjà au J12.** Il n'apparaît **qu'en combat** (Mont Sélénite,
    rare) : aucune Mélofée n'est posée dans le décor (`jalon-12.md` §0.2 n° 16). Le Mélofée de Léo
    sera donc le **premier Mélofée visible dans le monde**. Il n'y a pas de confusion possible avec
    un sauvage ; on le distingue par la mise en scène et le nom affiché. → **E-4**.
11. **Le J14 ajoute des espèces.** Données RB vérifiées dans le désassemblage `pret/pokered`
    (`data/wild/maps/Route25.asm`, `data/maps/objects/Route25.asm`, `data/trainers/parties.asm`) :
    - **Sauvages de la Route 25** (taux 15, plus bas que la Route 24 à 25) : Rouge = Aspicot 8,
      Coconfort 9, Roucool 13, **Mystherbe** 12–14, **Abra** 10 et 12, Chrysacier 7, Chenipan 8 ;
      Bleu = la même chose avec **Chétiflor** à la place de Mystherbe. Même pool que la Route 24 :
      il dépend de D-8 du J13.
    - **9 Dresseurs dans RB** (la V2 en garde 5 à 7) :

      | Classe RB | Équipe RB |
      |---|---|
      | Gamin | Rattata, Piafabec (Nv. 15) |
      | Gamin | **Ramoloss** (Nv. 17) |
      | Gamin | Abo, Sabelette (Nv. 14) |
      | Jeune Dresseur (Jr. Trainer ♂) | Rattata, Abo (Nv. 14) |
      | Fillette | Nidoran ♂, Nidoran ♀ (Nv. 15) |
      | Fillette | Mystherbe, Roucool, Mystherbe (Nv. 13) |
      | Montagnard | **Machoc**, Racaillou (Nv. 15) |
      | Montagnard | Racaillou ×3, **Machoc** (Nv. 13) |
      | Montagnard | Onix (Nv. 17) |

    - Espèces nouvelles possibles : **Abra, Kadabra, Machoc, Ramoloss** (et Mackogneur ou
      Flagadoss s'ils devenaient atteignables : non au J14). Aucun dos peint n'existe (dette du
      J12 et du J13).

    → **E-5**.
12. **Sauvegarde : rien de nouveau.** Tout tient dans `flags` (Léo, machine, poursuite, Rocket,
    sortie sud), `bag` (Passe Bateau, objet de Léo, CT28) et `moments`. Le J11 écrit la v6 ; ni le
    J12, ni le J13, ni le J14 ne changent le format. L'**état « sous terre »** est volatil, comme
    tous les états de combat : il n'est jamais écrit.
13. **Objets de la Route 25 dans RB** : la **CT19 Frappe Atlas** au sol (vérifié), et deux objets
    cachés, **Huile** et **Élixir**, qui rendent des PP. **Les PP ne se restaurent pas par objet**
    dans Kanto 2026 (aucun objet de ce type dans `items.json`) : défaut, deux objets cachés
    existants à la place. Frappe Atlas inflige des dégâts fixes, effet **accepté par le J11**
    (A-3) ; elle est compatible si 11B est fusionné.
14. **Raccord sud (Route 5).** Le J15 est conçu en parallèle (avant-projet V1 : Route 5, Pension,
    souterrain, Route 6, Carmin-sur-Mer). Le J14 doit lui **passer le relais** comme le J12 l'a fait
    au J13 :
    - identifiant de carte `route_5` ;
    - point d'arrivée `from_cerulean` ;
    - repère de coordonnées.

    Avant le J15, le bord sud mène à un raccord « ROUTE 5 — À venir » en développement (bord
    bloqué en release, mécanisme existant).
15. **Dépendances.** Le code du J14 vient **après la clôture du J13**, elle-même après le J12 et le
    J11 :
    - CT, statuts, Patience (le verrou d'action), Frappe Atlas : J11 ;
    - Mélofée, Sbire Rocket peint, étape « choix qui lance une scène », évolution hors combat :
      J12 ;
    - Azuria, maison cambriolée, policier, Route 24 nord, raccord Route 25, Centre d'Azuria : J13.

    La conception (dossier, grilles, vues peintes, art) peut avancer en parallèle.

## 3. Plan et déplacements

- **Angles droits** (dossiers 01 et 07). La Route 25 longe la mer vers l'est jusqu'au Cap :
  falaises et rivage en paliers rectilignes, pas de côte en diagonale.
- **L'eau reste un obstacle** (pas de Surf ni de pêche, J13 D-12).
- **Route 25** : un chemin principal d'au moins **2 cases de large** (compagnon, J11). Les Dresseurs
  facultatifs se placent dans des **poches latérales** (herbes, petites terrasses), avec un ou deux
  combats inévitables au plus, que la grille rend lisibles. Aucune vue de Dresseur ne couvre toute
  la largeur, sauf choix explicite.
- **Cap d'Azuria** : une petite pointe, la maison de Léo au bout. Un **cul-de-sac assumé**, et la
  récompense du voyage.
- **Maison de Léo (intérieur)** : deux cabines, une console, un écran de diagnostic. Le compagnon
  rentre en entrant (règle du J11).
- **Azuria (J13)** : la poursuite se joue **derrière la maison cambriolée** (jardin, trou dans le
  mur, J13 C-8). Le point d'arrêt du Rocket est une **impasse visible**, sans issue vers l'est : la
  Route 9 reste fermée jusqu'à Coupe.
- **Budget** : ≤ 3 000 nœuds par carte, mémoire = carte + voisines (J10). Une route côtière avec de
  l'eau animée se mesure dès la grille.
- **Filière habituelle** : grille `tools/plans/*.txt` et `plan_check`, puis vue générale peinte
  validée par Kevin, puis la carte. Une **référence peinte de l'intérieur de Léo** est à produire
  (comme `chambre-joueur-v1`), car aucun intérieur « laboratoire excentrique » n'existe.

## 4. Les points ouverts de la V2 (V-1 à V-3) et la poursuite

| # | V2 | Avis |
|---|---|---|
| **V-1** | Objet de Léo = Super Bonbon | **Possible, mais pas gratuit** (§2 point 7). Le Super Bonbon reviendra souvent par la suite (RB en cache plusieurs) : le parcours servira. Il vient **après** 11B (oublier une capacité) et l'évolution hors combat du J12. Voir E-6 pour les autres choix. |
| **V-2** | Tunnel hors combat = sortie de donjon | **La règle est bonne** (identique à la Corde Sortie : grottes de `caves.json` seulement, ni soin ni point de repos touchés, refus « Impossible de l'utiliser ici. » ailleurs). **Je recommande de reporter le menu** au jalon des ex-CS (E-9). |
| **V-3** | Les deux histoires dans n'importe quel ordre | **Oui**, écart RB assumé (§2 point 8). |
| — | Rocket en scène scriptée, sans chronomètre | **Oui.** Déroulé recommandé : le joueur entre dans le jardin → « ! » au-dessus du Rocket → réplique → le Rocket part en marche scriptée de quelques cases et s'arrête au fond de l'impasse → le joueur reprend la main et le rejoint à son rythme → la vue déclenche le combat. Une seule fois : drapeau `cerulean_rocket_spotted`. Après une défaite : réveil au Centre, le Rocket **attend à son point d'arrêt**, avec une réplique de reprise (modèle de Pierre, `brock_met`). Victoire : CT28 remise, le Rocket part (`despawn`), drapeau `cerulean_rocket_beaten`. |

## 5. Arbitrages à trancher (E-1 à E-15)

| # | Question | Recommandation |
|---|---|---|
| **E-1** | Deux Léo | **Renommer l'enfant de Bourg Palette** (et son identifiant `leo` → nouveau nom). Une réplique, une ligne du dossier 02, une PNJ : coût minime. Léo garde son nom officiel. Nom à choisir par toi. Alternative : garder les deux (déconseillé : le post-game du dossier 06 devient ambigu). |
| **E-2** | Léo et le stockage | **Léo n'est pas l'inventeur du stockage.** Il travaille sur la **téléportation de la matière** (sa machine) ; il peut dire, au plus, qu'il « a aidé Chen sur les transferts ». Le récit du dossier 09 reste vrai. *K26.* |
| **E-3** | Abra | **Au J14, sur la Route 25, rare.** Avec **la fuite adverse** (nouvelle, petite : un sauvage qui connaît Téléport la lance au premier tour et le combat finit, « {pokemon} s'est téléporté ! »). Elle rend Abra difficile, comme dans RB. **Évolution par échange : règle à décider maintenant**, car Kadabra est atteignable au J14. Trois options pour Kadabra, Machopeur, Gravalanche et Spectrum : **(a)** un **objet d'évolution unique** (rare, à nommer), passant par le parcours de la Pierre Lune du J12 ; **(b)** un **PNJ** (maison d'échange d'Azuria) qui « échange puis rend » le Pokémon ; **(c)** une évolution **par niveau**. **Reco : (a)**, la moins chère, la seule qui garde un geste. Sans décision : Kadabra reste au J14 sans évolution, et Abra est reporté. |
| **E-4** | Apparence de Léo-Mélofée | **Même planche que le Mélofée du J12**, sans accessoire (RB). Le nom affiché dans les dialogues est « Mélofée » à la première réplique, puis « Léo » une fois qu'il s'est présenté. Il **parle** ; aucun cri ni combat. Alternative : un accessoire (lunettes) = un asset de plus. |
| **E-5** | Espèces nouvelles | **Abra, Kadabra, Machoc** (Montagnards de RB), données et face ; dos provisoires selon la dette J12/J13. **Ramoloss écarté** : le Gamin de RB qui l'utilise disparaît, puisqu'on passe de 9 à 6 Dresseurs. Machopeur et Mackogneur **non atteignables** au J14 (Machoc est de Dresseur seulement). Alternative à coût nul : Dresseurs avec des espèces existantes, sans Abra. |
| **E-6** | Objet supplémentaire de Léo | **Super Bonbon (×1)** si tu acceptes le coût du §2 point 7. **Alternative moins chère : une CT** (le parcours CT existe après 11B). Par exemple **CT30 Téléport**, qui fait un clin d'œil à la machine, mais qui est **sans effet** en combat de Dresseur. Ou **rien de plus** (RB). Je recommande le Super Bonbon : utile, modeste, et son parcours resservira. |
| **E-7** | Tunnel en combat : règles | **RB** : Sol, puissance **100**, précision 100, 10 PP. **Tour 1** : « {pokemon} creuse un trou ! », le sprite disparaît. **Tour 2** : frappe, action verrouillée. **Sous terre, toute attaque adverse échoue** (« {pokemon} évite l'attaque ! »). Les dégâts de fin de tour (poison, brûlure, Vampigraine) s'appliquent. **Immunité Vol** déjà dans `types.json` : le tour 2 « n'affecte pas ». Séisme ne double pas (G+), car il est hors de portée avant longtemps. |
| **E-8** | Tunnel : interruptions | Défauts G+, simples : **sommeil, gel, paralysie totale, confusion qui frappe, apeurement** au tour 1 → rien ne se passe, le Pokémon reste en surface. Au tour 2, s'il est endormi ou gelé entre-temps → il **remonte sans frapper**. **Pas de changement de Pokémon** pendant le tour verrouillé (comme Patience). **Capture** : une Ball sur un sauvage sous terre **échoue** (« Impossible de viser ! »), mais aucun sauvage du J14 ne connaît Tunnel. L'IA `smart` peut choisir Tunnel ; **aucun adversaire du J14 ne le connaît**. Mécanisme écrit **général** (« charge puis frappe », avec ou sans invulnérabilité) pour Lance-Soleil, Coud'Krâne et Vol. |
| **E-9** | Tunnel hors combat | **Reporté au jalon des ex-CS** (Coupe, S.S. Anne), où le menu « capacité de terrain » sera conçu une fois pour toutes (dossier 06 §11). Au J14, la description de la CT dit seulement son effet en combat. Alternative : au J14, entrée **TUNNEL** dans la fiche Équipe, avec la règle de la Corde Sortie. Cela coûte un menu nouveau, pour le seul Mont Sélénite. |
| **E-10** | Raison du verrou sud | **Barrage de police à la sortie sud** : un policier (modèle « garde » existant) contrôle la sortie : « On recherche un voleur. Personne ne sort par le sud tant qu'il court. » Il part après la victoire contre le Rocket. Une raison visible, liée au cambriolage, sans porte verrouillée. *K26.* |
| **E-11** | Accès à la Route 25 | **Rival battu + recruteur passé** suffisent, sans verrou de plus (accord avec la V2). **À confirmer dans le dossier 16** : le recruteur bloque le bout du pont jusqu'à sa défaite (RB). Le raccord « ROUTE 25 — À venir » du J13 devient la vraie Route 25. |
| **E-12** | Ordre de la machine | **Guidé et linéaire** : Léo dit quoi faire, l'objet suivant a un léger repère visuel (lueur douce), les autres répondent par une phrase d'aide. Écran → module → Léo entre → console → transformation. Chaque étape lève un drapeau. **Une sortie de la maison en cours de route garde l'avancement.** Aucun échec possible. |
| **E-13** | Rejouer le Rocket | **Oui** (§4) : réveil au Centre d'Azuria, le Rocket attend à son point d'arrêt, réplique de reprise, ni moquerie ni introduction rejouée. Pas de Grand moment (ce n'est ni un rival ni un Champion). |
| **E-14** | Grand moment de Léo | **Oui, un seul**, à la fin de la transformation (« Léo a retrouvé forme humaine »), sur le modèle des moments existants. Alternative : aucun. |
| **E-15** | Ordre de validation sur S24 | **14.0** art et données (Léo humain, intérieur peint, effet de machine, Tunnel, Passe Bateau, objet de Léo, espèces) · **14A** Route 25, Cap, maison de Léo, scène complète, récompenses · **14B** poursuite, Rocket, CT28, **Tunnel en combat** (validé seul si le mécanisme « deux tours » est risqué : E-8), barrage sud levé, raccord Route 5, clôture. Code après la clôture du J13. |

## 6. Ce qui est verrouillable tel quel

- Léo-Mélofée parle, ne combat pas, et n'a ni cri ni capture.
- Aucune transformation de Pokémon pour le joueur.
- Machine sans énigme ni échec.
- Passe Bateau : objet clé, invendable, jamais perdu, sans bouton UTILISER au J14.
- CT28 remise une seule fois (`got_tm28`, modèle `got_<id>`).
- Compagnon : règle des intérieurs du J11, rien de nouveau.
- Poursuite sans chronomètre, sans course, sans réflexe.
- Le Rocket ne nomme personne et ne révèle aucun chef. La révélation du lien avec le Mont Sélénite
  reste au niveau du joueur (J13 D-14) : au plus, « Les ordres viennent d'en haut. »
- La Route 9 reste fermée (Coupe), la Route 5 n'existe qu'en raccord « À venir ».
- Aucune nouvelle version de sauvegarde.

## 7. À fournir par la consolidation (dossier 17) : textes et données à relire

**Textes définitifs**, regroupés et numérotés, relus en un seul lot :

- **Léo-Mélofée** : premier contact, explication du problème, consignes de la machine (écran,
  module, console), phrases d'aide sur les objets hors de l'ordre, réplique s'il est déjà entré
  dans la cabine.
- **Machine** : texte de l'écran de diagnostic, du module, de la console (EXAMINER).
- **Léo humain** : retour, remerciements, remise du Passe Bateau et de l'objet, phrases après la
  visite (y compris si l'on revient avant ou après le cambriolage).
- **Descriptions d'objets** : Passe Bateau, objet de Léo, CT28 Tunnel, et l'objet d'évolution
  d'E-3 s'il est retenu.
- **Route 25** : 5 à 7 Dresseurs (avant, défaite, après), panneaux (Route 25, Cap d'Azuria,
  maison de Léo).
- **Rocket** : repérage, fuite, reprise après défaite, avant combat, victoire du joueur, remise
  de la CT28, départ.
- **Azuria** : policier du barrage sud (avant / après), policier de la maison (après), victime du
  cambriolage (après), deux habitants qui commentent (après).
- **Combat** : textes de Tunnel (creuse, évite, remonte sans frapper, « Impossible de viser ! »),
  fuite par Téléport.
- **Pokédex** : descriptions et notes des espèces nouvelles.
- **Tableau de bord** : objectifs (Cap d'Azuria, cambriolage).

**Données** :

- équipes exactes et capacités, en signalant toute capacité absente du moteur ;
- tables de rencontres de la Route 25 ;
- liste des drapeaux ;
- plan fonctionnel ASCII de la Route 25, du Cap, de la maison de Léo et du jardin de la maison
  cambriolée ;
- relais vers le J15 (`route_5`, `from_cerulean`).

**Cas limites** :

- quitter la maison de Léo au milieu de la machine ;
- fermer le jeu pendant la transformation ;
- défaite contre le Rocket, puis retour au Centre ;
- Rocket battu avant la visite à Léo ;
- sauvegarde dans le jardin pendant la marche du Rocket ;
- Tunnel avec sommeil, paralysie, Vol, capture, changement ;
- Kadabra atteint sans règle d'échange décidée ;
- partie sauvegardée sur le raccord « Route 25 — À venir » du J13.
