# J16 — S.S. Anne et Badge Foudre : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-11. Relu contre `vision.md`, `roadmap.md`, dossiers 05, 06, 09, 11, 12, 14
> (J11), 15 (J12), `jalon-11.md`, `jalon-12.md`, la passe `j12-v1-alignement.md` et le code de
> `main` (`906566a`, J11 : 11.0 fusionné, 11A à faire). Conception seulement : aucune ligne de code.
> Les 6 décisions de la V2 sont reprises telles quelles **sauf la n° 5**, qui contredit une décision
> verrouillée (§2 n° 1). Les arbitrages proposés par la V2 restent **F-1 à F-6** ; les miens sont
> numérotés **G-1 à G-10** pour éviter toute collision. À répondre par numéro, puis à transmettre à
> ChatGPT avec la V2 pour la consolidation.
>
> **Révision r2 (2026-10-11, précision de Kevin)** : J11 à J15 avancent **en parallèle** dans d'autres
> sessions ; ici on ne traite **que le J16**, sans attendre. Le §0 ne bloque donc rien : il liste les
> **hypothèses d'entrée** à recouper avec ces sessions. Faits Rouge/Bleu vérifiés sur les CSV publics
> de PokeAPI (groupe de versions `red-blue`), comme `tools/gen_tm_compatibility.py`.

## 0. Hypothèses d'entrée (J13–J15 en cours en parallèle)

Aucun dossier J13–J15 n'est encore poussé sur une branche du dépôt (vérifié sur toutes les branches
distantes le 2026-10-11). Le dossier 15 réserve au J13 « Route 4, Azuria, Pont Pépite, rival n° 3 ».
La V2 suppose que ces jalons livrent :

| Ce que le J16 attend | Jalon supposé | État réel |
|---|---|---|
| Badge Cascade (`badge_cascade`) | J13 | badge déclaré dans `data/badges.json`, rien d'autre |
| Rival n° 3 (Pont Pépite) : base de la cohérence du n° 4 | J13 | « à concevoir » (roadmap) |
| Passe Bateau remis par « Léo » | J14 | ni objet, ni personnage, ni lieu (Cap Azuria) |
| Routes 5 / 6 (ou Souterrain) jusqu'à Carmin | J14–J15 | rien |
| Carmin-sur-Mer : ville, Centre, quai, navire visible, Arène | J15 | zone `vermilion_city` vide dans `zones.json` |
| Espèces capturables entre Azuria et Carmin | J13–J15 | rien |

Le J16 avance sans les attendre : il **écrit ces hypothèses noir sur blanc** (contrat d'entrée, G-1)
et les sessions J13–J15 les reprennent ou les contestent. Rien du J16 n'est bloqué. Seul le code
suit C-7 : un seul jalon à la fois dans le moteur de combat et la sauvegarde.

## 1. Les 6 décisions et les arbitrages F-1 à F-6

| # | V2 | Avis |
|---|---|---|
| 1 | S.S. Anne + Major Bob au J16 | Oui. Ce sera le plus gros jalon de contenu à ce jour (≈ 6 à 8 cartes de navire + Arène). Rouge/Bleu : l'Arène est **derrière un arbuste**, donc le navire passe forcément avant l'Arène (G-5). |
| 2 | Plusieurs ponts, cabines, restaurant, pont extérieur | Oui. Une carte par espace, plus les cabines en petites cartes (méthode de la salle science du Musée : warps entre cartes, aucun code nouveau). |
| 3 | Rival n° 4 à bord, victoire obligatoire | Oui ; défaite → réveil au dernier Centre (comme Pierre et les Dresseurs de la forêt). Composition : G-7. |
| 4 | Capitaine malade | Oui (Rouge/Bleu). Scène courte. |
| 5 | Coupe utilisable en combat et hors combat | **Contradiction** avec le dossier 06 §11 (verrouillé, « non négociable ») → G-2. |
| 6 | Départ définitif après confirmation | Oui. **Écart volontaire** à Rouge/Bleu, où le navire part sans demander. Faisable avec le moteur actuel moyennant deux extensions techniques (§3). |
| F-1 | Badge Cascade + Pokémon compatible qui l'a apprise | Dépend de G-2 et G-3. |
| F-2 | CS réutilisables, oubli interdit par le menu ordinaire | Inutile si G-2 = C (recommandé). Si G-2 = B, il faut un système de capacité protégée (absent : `MoveForgetPanel` laisse tout oublier) **et** un Maître des capacités, que le dossier 14 a sorti du périmètre. |
| F-3 | Navire accessible après Coupe jusqu'à confirmation | Oui. |
| F-4 | Puzzle des deux interrupteurs avec indices | Oui sur le principe ; la règle exacte change tout → G-8. |
| F-5 | Voltorbe 21, Pikachu 18, Raichu 24 | Oui comme **référence**. Niveaux à fixer par simulation, comme pour Pierre (`simulate_brock.gd`, T16 du J10 : le Pierre « historique » donnait 0 % de victoire à Kevin). |
| F-6 | Badge Foudre + CT24 Tonnerre, sans bonus caché | Oui : conforme au dossier 12 §13 (« aucun bonus caché », pas d'obéissance). Tonnerre est déjà dans les compatibilités générées (Pikachu, Raichu, lignées Rattata, Nidoran, Férosinge). |

## 2. Ce que la V2 oublie ou contredit

1. **Les CS ne prennent pas d'emplacement de capacité.** Le dossier 06 §11 dit : « Coupe, Surf,
   Force, Flash, Vol restent, mais une fois apprises/débloquées l'équipe les utilise dans le monde
   **sans occuper l'un des 4 emplacements de combat**. Et elles sont visuelles. » Décision verrouillée :
   « CS occupant des capacités : **non** ». La V2 (décision 5, F-1, F-2) revient au modèle de
   Rouge/Bleu. Seul toi peux rouvrir ce point → G-2.
2. **Carapuce ne peut pas apprendre Coupe** dans Rouge/Bleu, et Pikachu non plus. Un joueur sans espèce
   compatible est bloqué devant l'Arène (Rouge/Bleu : arbuste devant la porte).

   **Compatibles Coupe dans Rouge/Bleu (vérifié)** : Bulbizarre, Herbizarre, Florizarre, Salamèche,
   Reptincel, Dracaufeu, **Dardargnan**, Sabelette, Sablaireau, Mystherbe, Ortide, Rafflesia, Paras,
   Parasect, Chétiflor, Boustiflor, Empiflor, Tentacool, Tentacruel, Canarticho, Krabby, Krabboss,
   Excelangue, Saquedeneu, Insécateur, Scarabrute, Mew.

   **Le risque est déjà presque couvert.** Dardargnan (Aspicot de la forêt, évolution N10, J9), Sabelette
   (sauvage Route 3, B-5 du J12) et Paras (Mont Sélénite, J12) sont tous atteignables avant Carmin, quel
   que soit le starter. G-6 se réduit à un **test** qui le garantit. Il faut quand même étendre
   `tools/gen_tm_compatibility.py` aux CS : il exclut aujourd'hui les numéros ≥ 101.
3. **La condition de badge est une règle cachée.** Le dossier 12 a supprimé tout effet mécanique des
   badges. Si l'ordre J13 → J14 garantit Cascade avant le Passe Bateau, la vérification ne sert à rien.
   S'il ne le garantit pas, le joueur peut obtenir une CS qu'il ne peut pas utiliser : c'est le piège
   connu de Rouge/Bleu → G-3.
4. **Arbustes : « réapparition cohérente » = risque de blocage.** Le moteur sait déjà retirer un
   obstacle « pour la durée de la carte » (`despawn` → `Map.remove_npc`, recréé par `refresh_npcs`).
   C'est exactement la repousse de Rouge/Bleu. Mais un joueur qui sauvegarde derrière un arbuste, puis
   dépose son seul Pokémon compatible ou le fait évoluer en une espèce incompatible, peut se retrouver
   enfermé. La V2 demande aussi « le monde se souvient » (dossier 06 §5) → G-4.
5. **Inventaire des arbustes.** Seul le FUTUR A de la Route 2 existe : un arbre dense avec son texte,
   dont le dossier 11 n°11 précise qu'il ne verrouille « ni Coupe, ni CS, ni manière de le franchir ».
   Ce qu'il y a derrière n'est conçu nulle part (Rouge/Bleu : maison d'échange, Grotte Taupiqueur).
   Autres arbustes probables dans Rouge/Bleu : devant l'Arène de Carmin, entre Azuria et la Route 9,
   et plus tard Céladopole. **Règle proposée pour la consolidation** : le J16 ne pose que l'arbuste de
   l'Arène, plus éventuellement celui de la Route 2 si un contenu est conçu derrière. Tout autre arbuste
   arrive avec son jalon, comme les obstacles fermés jusqu'ici.
6. **Rival n° 4 « cohérent avec les trois combats précédents » : le n° 3 n'existe pas.** Rouge/Bleu :
   Roucoups 19, Rattatac 16, Kadabra 18, starter évolué 20. **Rattatac est imposé** par le dossier 06 §6 :
   le tournant de Lavanville repose sur la disparition du Rattata ou Rattatac de son équipe, il doit donc
   y être avant. Abra et Kadabra sont absents des données. → G-7.

   **Capacités naturelles (vérifié)** :
   - Abra : **Téléport seul**, à tout niveau. Rouge/Bleu : l'Abra du rival n° 3 ne fait que ça.
   - Kadabra N18 : Choc Mental, **Entrave**, Téléport. Le J12 a écarté Entrave comme mécanique nouvelle
     (B-6).

   Il faut donc des **capacités choisies à la main** (le bloc `moves` existe déjà, comme pour Pierre),
   ou bien créer Entrave et un Téléport qui échoue en combat de Dresseur.
7. **Rival : un Grand moment « victoire comme défaite »** (roadmap) n'a pas été pensé pour un combat
   qu'on recommence. Petite question, valeur par défaut au §6.
8. **IA du rival.** Le dossier 09 §14 prévoit qu'il change de Pokémon « plus tard », mais le dossier 14
   A-4 a reporté les changements par l'IA. Le n° 4 aura donc l'IA `smart` sans changement, sauf si le
   J13–J15 l'ajoute.
9. **Major Bob : 4 mécaniques absentes du moteur.**
   - La paralysie arrive avec le J11 (11A).
   - **Sonicboom** = 20 dégâts fixes. Le plan 11A ne prévoit que `half_hp` et `level` : il manque une
     valeur fixe (une ligne de plus).
   - **Tonnerre** est à créer : **90 / 100 % / 15 PP, paralysie 10 %**. Le projet suit les **valeurs
     actuelles**, pas celles de la génération 1 (Fatal-Foudre y vaut 110, Morsure est Ténèbres). La
     « génération de référence » de la V2 s'entend donc ainsi ; Rouge/Bleu donnait 95.
   - **Destruction** (`self_ko`) n'est planifié nulle part. Voltorbe ne l'apprend qu'au N22 (vérifié),
     donc il ne l'a pas au N21. **Si la simulation monte son niveau, ses capacités seront choisies à la
     main.**

   Capacités naturelles au niveau de référence (vérifié) :
   - Voltorbe N21 : Charge, Grincement, Sonicboom ;
   - Pikachu N18 : Rugissement, Éclair, Cage-Éclair, Vive-Attaque ;
   - Raichu N24 : Rugissement, Éclair, Cage-Éclair, plus **Tonnerre** imposé par sa fiche de Dresseur
     (Rouge/Bleu ; à recouper à la consolidation, PokeAPI ne publie pas les équipes de Dresseurs).

   Les Dresseurs de l'Arène de Rouge/Bleu (Gentleman, Rockeur, Marin) restent à confirmer.
10. **Puzzle = mécanique nouvelle.** Il n'existe ni interrupteur, ni poubelle, ni état d'énigme.
    Faisable sans système dédié, grâce à deux éléments :
    - le point d'interaction conditionnel du J12 (`unless_flags`, prévu au `jalon-12.md`) ;
    - une barrière posée en PNJ « objet » et retirée par drapeau.

    Coût : **faible**, si G-8 retient une règle sans hasard.
11. **Départ du navire et coupure brutale.** Comportement réel du moteur :
    - les drapeaux ne font que monter, donc tout événement est à sens unique ;
    - la sauvegarde n'est écrite qu'en état stable : pas pendant une scène ;
    - une scène interrompue **se rejoue** (`boot.gd`). Un arrêt pendant la scène du départ fait donc
      revenir le joueur **à bord, avant la confirmation** : cohérent, rien n'est perdu ni dupliqué.

    Le seul risque est une sauvegarde qui contiendrait « navire parti » avec un joueur encore placé dans
    une carte du navire. Garde-fou technique (§3) : une écriture immédiate, au moment où le drapeau
    monte, avec le joueur déjà posé sur le quai (comme `wake_up` après une défaite).

    **Seul élément indispensable avant le départ : la CS01** (le rival battu est déjà un préalable du
    capitaine). Tout le reste (Dresseurs, objets) est facultatif et perdu au départ, comme dans
    Rouge/Bleu ; la confirmation le dit.
12. **« Partir / Pas encore » : le moteur ne sait pas encore faire.** `DialogueChoice` applique les
    `set_flags` et la scène d'une variante **quelle que soit la réponse**, et `confirm_action` ne
    connaît que soin, boutique et stockage. Il faut une extension : « confirmer → scène ». Elle servira
    aussi à « Utiliser Coupe ? ». Le reste est déjà là : `ChoiceCards` (deux cartes, jamais Oui / Non)
    convient tel quel (« PARTIR » / « PAS ENCORE »).
13. **Collision de nom : « Léo ».** C'est le nom français de Bill, mais c'est déjà le petit garçon de
    Bourg Palette (dossier 02). Le Scout de la forêt a été renommé Théo pour cette raison (dossier 10).
    À trancher au J14, mais la V2 le cite → G-1.
14. **Coût en espèces et en art** (règle du J12 : espèce capturable = évolution disponible).
    - **Rival** : Roucoups, Rattatac, Reptincel, Carabaffe, Herbizarre ont leurs données, mais ni dos
      ni sprite provisoire. **Abra et Kadabra** sont à créer : données, Pokédex, dos.
    - **Major Bob** : Voltorbe (arrive au J12), Pikachu et Raichu (données présentes, Raichu sans art du
      monde).
    - **Dresseurs du navire** : dans Rouge/Bleu, surtout Machoc, Tentacool, Kokiyas, Ptitard, Caninos,
      Goupix, Noeunoeuf, toutes absentes des données. Dix à douze Dresseurs peuvent faire exploser le
      lot → G-9.
    - **Personnages peints nouveaux** : capitaine, marins, gentleman, cuisinier, passagers, Major Bob
      (aucun n'existe).
    - **Décors de combat** : navire (intérieur et pont) et Arène.
15. **Rythme.** Le dossier 06 §10 prévoit 3 h d'Ondine à Major Bob. Ces 3 h comprennent les routes du
    J14–J15, Carmin, le navire et l'Arène. Avec 10 à 12 Dresseurs, le navire seul approche l'heure :
    c'est cohérent, mais il ne faut pas plus.
16. **Images de la V2** (art officiel Let's Go) : ambiance seulement, **à ne pas mettre dans le dépôt**.
    La filière reste la même : vue générale peinte + grilles `tools/plans/*.txt` validées par toi
    avant toute carte.
17. **Numérotation : risque de collision entre sessions.** Le numéro suit l'ordre de conception
    (dossier 15, en-tête), et le premier libre est le **16**. Mais J13, J14 et J15 sont conçus **en même
    temps** ailleurs et viseront peut-être le même numéro, ainsi que la série d'art 15.
    **Défaut (règle 4)** : chaque dossier prend son numéro **au moment du push**, après vérification de
    toutes les branches distantes. Le premier poussé garde le 16, et les autres se renumérotent avant
    fusion. Même règle pour les séries d'art.

## 3. Coûts techniques à connaître (pas des décisions)

- **Sauvegarde : pas de v7 a priori.** Arbustes, départ, puzzle, capitaine et rival sont des drapeaux ;
  le Passe Bateau et la CS sont des objets clés (catégorie `key`, comme le Colis). Une catégorie `hm`
  (ou CS rangée avec les CT du 11B) ne change pas le format.
- **Écriture immédiate** au départ du navire : une étape de scène (ou un drapeau marqué « à écrire tout
  de suite ») sur le modèle de `wake_up`. C'est le seul point sensible du jalon pour la sauvegarde :
  **16D validé seul** (règle 1, exception « système risqué »).
- **Choix → scène** dans `DialogueChoice` (§2 n° 12) : petite extension, testable sans scène.
- **Condition « l'équipe sait couper »** : il faut un test nouveau, d'équipe ou d'objet, dans les
  conditions. Aujourd'hui `if` / `unless` ne lisent que des drapeaux. Le plus simple : un
  `InteractPoint` « arbuste » dédié, qui interroge une fonction logique pure (`FieldMoves.can_cut(party,
  bag, flags)`), plutôt que d'étendre toutes les conditions.
- **Coupe visible** (dossier 06 : « elles sont visuelles ») : le Pokémon compatible sort (compagnon du
  J11 s'il est dehors, sinon apparition brève), effet de coupe, l'arbuste disparaît. Une animation
  générique, pas une animation par espèce.
- **Navire** : 6 à 8 cartes intérieures de taille moyenne, budget ≤ 3 000 nœuds chacune ; mémoire =
  carte + voisines. Le navire doit exister **dans la carte de Carmin** en deux états (amarré / parti),
  par un objet conditionné à un drapeau.
- **Combat** : Sonicboom (20 dégâts fixes, 90 %, 20 PP), Tonnerre (90, 100 %, 15 PP), Coupe (Normal,
  50, 95 %, 30 PP, valeurs vérifiées). Ce sont des données seulement, une fois 11A fusionné.

## 4. Arbitrages à trancher (G-1 à G-10)

| # | Question | Recommandation |
|---|---|---|
| **G-1** | Contrat d'entrée avec les sessions J13–J15 | **À valider tel quel, puis à transmettre à ces sessions** : `badge_cascade` obtenu avant le Passe Bateau ; objet clé `ss_ticket` (« Passe Bateau ») ; Carmin avec Centre, quai, navire amarré et **arbuste devant l'Arène** (G-5) ; rival n° 3 avec Rattata (G-7 ; **pas d'Abra**, correction du 2026-10-13 ci-dessous) ; donneur du Passe Bateau nommé autrement que « Léo ». Le J16 n'attend rien : en cas d'écart, c'est le contrat qui se corrige. |
| **G-2** | Modèle de Coupe (contradiction avec le dossier 06 §11) | **C, hybride.** (A) Dossier 06 strict : la CS débloque Coupe dans le monde, utilisable si l'équipe compte un Pokémon compatible, et rien en combat. (B) Rouge/Bleu (V2) : capacité apprise, emplacement occupé, oubli interdit. (C) **La CS débloque Coupe dans le monde**, comme en A, sans emplacement ; **et** elle s'utilise comme une CT réutilisable pour l'apprendre en combat si on le veut, oubliable normalement. C respecte le dossier 06 et la décision 5, et ne demande ni capacité protégée ni Maître des capacités. F-2 devient sans objet. *Écart volontaire à Rouge/Bleu.* |
| **G-3** | Condition de badge pour Coupe ? | **Aucune** si G-1 garantit Cascade avant le Passe Bateau : pas de règle cachée (dossier 12). Sinon, garder Cascade (Rouge/Bleu) avec une réplique claire du Pokémon qui ne peut pas encore couper. |
| **G-4** | Arbuste coupé : repousse ou définitif ? | **Définitif** (drapeau par arbuste) : aucun blocage possible, « le monde se souvient ». *Écart volontaire* (Rouge/Bleu : repousse en quittant la carte). |
| **G-5** | Arbuste devant l'Arène de Carmin ? | **Oui** (Rouge/Bleu) : donne à Coupe un usage immédiat et impose l'ordre navire → Arène sans garde ni texte d'excuse. Posé au J15, coupé au J16. |
| **G-6** | Garantie anti-blocage | **Règle testée** : quel que soit le starter, au moins une espèce compatible Coupe est capturable avant Carmin. C'est déjà le cas : Dardargnan (forêt), Sabelette (Route 3), Paras (Mont Sélénite). L'arbuste explique ce qui manque (« Il faudrait un Pokémon capable de couper »), et le Centre de Carmin donne accès au stockage. |
| **G-7** | Équipe du rival n° 4 | **Structure Rouge/Bleu** : Roucoups, Rattatac, Kadabra, starter évolué (avantage de type), soit **4 Pokémon** comme la V2. Niveaux de référence 19 / 16 / 18 / 20, recalés par simulation. ~~Kadabra suppose un Abra au n° 3 (J13).~~ Kadabra arrive **directement** au n° 4 (correction du 2026-10-13 ci-dessous). IA `smart`. |
| **G-8** | Règle du puzzle | **Sans hasard ni remise à zéro.** Le premier interrupteur est désigné par un indice du décor (câble, étincelle). Le second est voisin, révélé par une étincelle quand le premier est trouvé. Une erreur ne coûte rien ; l'énigme résolue reste résolue (drapeau). *Écart volontaire* (Rouge/Bleu : position tirée au sort, remise à zéro à chaque erreur). |
| **G-9** | Budget d'espèces nouvelles au J16 | **≤ 3 espèces nouvelles** (Abra, Kadabra + au plus une de marin, par exemple Machoc ou Tentacool, si le J13–J15 ne l'apporte pas). Les Dresseurs du navire puisent dans les espèces déjà présentes à la fin du J15. Nombre de Dresseurs : **10**, dont **2 inévitables** au plus (le rival excepté). |
| **G-10** | Que dit la confirmation de départ ? | Une phrase du marin à la passerelle, **une seule fois par tentative de sortie** une fois la CS01 obtenue : le navire part et on ne pourra plus remonter, avec les cartes **PARTIR** / **PAS ENCORE**. Avant la CS01, la sortie est libre, sans question. Textes à écrire par la consolidation. |

## 5. Ce qui est verrouillable tel quel

Navire en plusieurs cartes (pont principal, pont inférieur, restaurant, pont extérieur, cabine du
capitaine), sans Centre à bord, retour libre à Carmin avant la CS01. Rival dans le couloir du
capitaine, qui part après sa défaite ; défaite → dernier Centre, sans perte d'argent, nouvelle
tentative sans réintroduction (réplique de reprise courte). Capitaine malade, scène courte sans
mini-jeu, CS01 remise une seule fois. Passe Bateau objet clé non consommé (Rouge/Bleu : on le garde),
contrôlé à la passerelle. Départ irréversible après confirmation, courte scène vue du quai, navire
absent ensuite. Major Bob : carte de Champion et Grand moment « badge » génériques du J10, légende
« BADGE FOUDRE », CT24 Tonnerre, aucun bonus caché, IA `smart`, capacités choisies à la main, pas
de Destruction. Pas de Team Rocket au J16 (Rouge/Bleu : aucune à bord). DA : boiseries, laiton,
grandes fenêtres, lumière naturelle, pas de paquebot contemporain.

## 6. Valeurs par défaut (règle 4, sans arbitrage)

- Grand moment du rival n° 4 : **une seule fois, à la victoire**. Les défaites ne créent pas de moment,
  sinon le joueur en accumulerait.
- Arbuste sans Pokémon compatible : la réplique seule, sans choix.
- « Utiliser Coupe ? » : cartes **COUPER** / **LAISSER**.
- Passe Bateau après le départ : reste dans le Sac (souvenir).
- Objectif du tableau de bord : « monter à bord du S.S. Anne. », puis « Aider le capitaine. », puis
  « Affronter Major Bob. ».

## 7. À fournir par la consolidation (dossier 16)

- Le contrat d'entrée (G-1) mot pour mot.
- Les plans fonctionnels ASCII de chaque carte du navire et de l'Arène, avec les cases des Dresseurs,
  des objets, de la passerelle, du rival et des interrupteurs.
- La liste des Dresseurs (nom, classe, équipe, capacités, inévitable ou non, argent).
- Les équipes exactes du rival n° 4 par starter et de Major Bob, en signalant toute capacité absente
  du moteur.
- Les objets du navire (dont combien de cachés).
- Les textes définitifs regroupés et numérotés : passerelle, équipage, passagers, rival avant / après /
  reprise, capitaine, CS01, confirmation de départ, Arène, guide, Major Bob, badge, CT24, arbuste avec
  et sans Pokémon compatible.
- La liste des drapeaux.
- Les cas limites :
  - défaite contre le rival puis Corde Sortie ;
  - application tuée pendant la confirmation, pendant la scène de départ, juste après ;
  - CS01 obtenue mais sortie sans confirmer ;
  - Pokémon compatible déposé au stockage ;
  - arbuste de l'Arène avec une équipe entièrement incompatible ;
  - interrupteur trouvé puis carte quittée ;
  - défaite contre Major Bob après le puzzle.
- Les critères de QA S21/S24 par lot :
  - **16A** embarquement et navigation entre cartes ;
  - **16B** Dresseurs et rival, défaite et reprise ;
  - **16C** CS01, Coupe dans le monde et en combat, arbuste, anti-blocage ;
  - **16D** départ, **validé seul** : arrêt brutal à chaque étape ;
  - **16E** puzzle, Major Bob, badge, CT24 ;
  - **16F** non-régression.

## 8. Réponses de Kevin (2026-10-11) — arbitrages tranchés

| # | Décision |
|---|---|
| **G-1** | Contrat d'entrée **validé** tel que proposé, à transmettre aux sessions J13–J15. **Corrigé le 2026-10-13** (voir ci-dessous) : pas d'Abra au rival n° 3. |
| **G-2** | **Modèle hybride.** La CS01 débloque Coupe dans le monde dès qu'un Pokémon compatible est dans l'équipe, sans occuper d'emplacement. Elle s'apprend aussi comme une CT réutilisable pour servir en combat, et s'oublie normalement. Le dossier 06 §11 et la décision 5 tiennent tous les deux. **F-2 devient sans objet.** |
| **G-3** | **Aucune condition de badge** pour Coupe. Le contrat garantit Cascade avant le Passe Bateau. **F-1 devient** : « un Pokémon compatible dans l'équipe ». |
| **G-4** | Arbuste coupé **définitif** (un drapeau par arbuste). *Écart volontaire à Rouge/Bleu.* |
| **G-5** | **Arbuste devant l'Arène de Carmin** : posé au J15, coupé au J16. |
| **G-6** | Anti-blocage **garanti par un test** (Dardargnan, Sabelette, Paras atteignables avant Carmin quel que soit le starter). |
| **G-7** | Rival n° 4 : **Roucoups, Rattatac, Kadabra, starter évolué** ; niveaux de référence 19 / 16 / 18 / 20, recalés par simulation ; capacités de Kadabra choisies à la main (sans Entrave). |
| **G-8** | **Puzzle Rouge/Bleu strict** : le premier interrupteur est tiré au hasard, le second est voisin du premier, et **toute erreur remet tout à zéro** (nouveau tirage). *Fidèle à Rouge/Bleu ; F-4 « indices plus lisibles » ne s'applique qu'à la lisibilité des objets à fouiller.* |
| **G-9** | **≤ 3 espèces nouvelles** au J16 (Abra, Kadabra + au plus une de marin) ; **10 Dresseurs** sur le navire, dont au plus 2 inévitables (rival excepté). |
| **G-10** | Confirmation à la passerelle, une fois la CS01 obtenue : **PARTIR** / **PAS ENCORE**. Avant la CS01, sortie libre. |

**Correction du contrat d'entrée (Kevin, 2026-10-13, demandée depuis la session du J13)** :
- Le J13 garde son arbitrage **D-6** (validé par Kevin le 2026-10-11) : le rival n° 3 (Pont Pépite) a
  **Roucoups Nv. 18, Rattata Nv. 15, starter évolué Nv. 17**, **sans Abra** (un Abra n'aurait que
  Téléport, inutile en combat de Dresseur, contraire à « le rival progresse »). Le J13 reporte Abra et
  la règle des évolutions par échange au J14 (**D-9**).
- Conséquence pour le J16 : **Kadabra arrive directement** dans l'équipe du rival n° 4 (il l'a attrapé
  et fait évoluer entre Azuria et Carmin, comme au S.S. Anne de Rouge/Bleu). G-7 inchangé sur le fond
  (Roucoups, Rattatac, Kadabra, starter évolué ; Kadabra sans Entrave, capacités choisies à la main).
- G-9 : le budget « Abra, Kadabra » reste valable ; Abra n'est à créer au J16 que si le J14 ne l'a pas
  déjà apporté (données et Pokédex d'Abra nécessaires pour Kadabra).
- Reste conforme : `badge_cascade` (J13) et le **Rattata** du rival présent dès le n° 3, avant
  Lavanville.
- Contrat de sortie du J13 : `docs/tech/jalon-13.md` §7 bis (branche `jalon-13`).
- **Numéro de dossier** : `dossier-16-azuria.md` est déjà pris par le J13 (branches
  `docs/dossier-16-j13` et `jalon-13`, depuis le 2026-10-11) ; le dossier du J16 doit prendre un autre
  numéro libre au moment de sa création.

**Valeurs par défaut prises pour G-8 (règle 4, à corriger si besoin)** :
- les interrupteurs se cachent dans des **objets à fouiller bien lisibles** (poubelles / armoires
  électriques), sans indice qui désigne le bon ;
- le tirage se refait **à chaque entrée dans l'Arène** tant que l'énigme n'est pas résolue ;
- une fois les deux trouvés, la barrière s'ouvre **pour toujours** (drapeau).

**Prochaine étape** : envoyer `docs/design/prompts/chatgpt-dossier-16-ss-anne.md` (bloc des réponses
rempli) à ChatGPT avec la V2 et cette passe → dossier 16 consolidé → relecture de Claude.
