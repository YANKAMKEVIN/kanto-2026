# Dossier 01 — Bourg Palette

> Le joueur doit reconnaître Bourg Palette en quelques secondes, puis découvrir qu'il est beaucoup plus vivant que dans son souvenir.

Statut : **Master Map v1 validée** (ChatGPT). Échelle **A+ verrouillée**. Prochaine étape de conception : *Population & Life System* (habitants un par un), puis concept visuel de référence en golden hour.

## Règle d'échelle A+ (officielle pour tout Kanto 2026)

Environ **3 à 4× l'échelle originale**, mais chaque agrandissement apporte du gameplay, de l'atmosphère ou de la narration. Pas de remplissage. **Dense plutôt que gigantesque.**

Temps de marche visés :
| Trajet | Durée |
|---|---|
| Maison → place | ~10 s |
| Place → laboratoire | ~10 s |
| Maison → Route 1 | 15–20 s |
| Traversée nord/sud complète | ~30–40 s |

> **Tranché par Kevin** : la taille prime (celle du concept golden hour, ≈ 48×32 cases, soit ×2 en longueur). Ces durées sont indicatives : on règle la vitesse de marche au test sur téléphone.

Principe : **si on superpose mentalement la carte à celle de Rouge/Bleu, on reconnaît encore Bourg Palette.** On enrichit la géographie, on ne la remplace pas.

## Master Map v1 — 7 micro-zones, sans chargement entre elles

```
                              NORD
                         ╔══════════╗
                         ║ ROUTE 1  ║
                         ╚════╤═════╝
                 🌳🌳🌳       │       🌳🌳🌳
              ┌───────────────┴───────────────┐
              │       PRAIRIE DU NORD         │
              │   herbes / clôtures / Pokémon │
              └───────────────┬───────────────┘
       ┌──────────────────────┼─────────────────────┐
       │   🏠 MAISON RIVAL          🏠 TA MAISON    │
       │       + jardin                 + jardin     │
       │            QUARTIER RÉSIDENTIEL            │
       └───────────────────────┼────────────────────┘
                     ╔═════════╧═════════╗
                     ║   PLACE CENTRALE  ║
                     ║ arbre / bancs     ║
                     ╚═════════╤═════════╝
                    ┌──────────┴─────────┐
                    │ 🔬 LABORATOIRE     │
                    │     DE CHEN        │
                    └──────────┬─────────┘
                  ┌────────────┴────────────┐
                  │ JARDINS DE RECHERCHE   │
                  │ serres / Pokémon       │
                  └────────────┬────────────┘
            🌳──────────── sentier côtier ─────────🌳
                    🌊 🌊 🌊 🌊 🌊 🌊
                         OCÉAN / ROUTE 21
```
Architecture, pas encore la carte artistique.

### Concept visuel « Master Map A+ » (golden hour) — référence de la nouvelle DA
Fichier : [`reference/bourg-palette-aplus-v1.png`](reference/bourg-palette-aplus-v1.png). Vue plongeante de tout le village, lumière dorée venant du haut-droite. Ce qu'on y voit :
- **Route 1** : chemin de terre au centre-nord, entre clôtures ; champ cultivé en haut à droite ; Roucool en vol, vélos garés.
- **Maison du rival** (nord-ouest) et **ta maison** (nord-est) : toits de tuiles rouges, murs clairs, jardins fleuris clôturés de piquets blancs, boîtes aux lettres. Le rival devant chez lui avec un Évoli ; le joueur devant chez lui avec Pikachu.
- **Place centrale** : grand arbre ancien sur un îlot de fleurs bordé de pierre, pavés, bancs, panneau « BOURG PALETTE », lampadaires noirs anciens, vieille dame assise.
- **Laboratoire** (centre-sud) : bâtiment gris moderne, panneaux solaires sur le toit, emblème Poké Ball au-dessus de l'entrée vitrée, camionnette garée à gauche, chercheurs devant.
- **Jardins de recherche** : à **l'est** du labo (pas derrière) — grande serre + petite serre, potagers, chercheurs, Bulbizarre.
- **Accès secret** : sentier qui s'enfonce dans la forêt au **bord est** de la carte, à côté des jardins.
- **Littoral** : falaises rocheuses et plage au sud-ouest, escalier en bois vers la plage, ponton avec pêcheur, Magicarpe qui saute, oiseaux marins ; **sentier côtier** tout le long du sud, avec lampadaires et barrières en bois.
- **Route 21** : départ vers l'**est** au bout du sentier côtier (sur l'eau plus tard via Surf).
- Densité : beaucoup d'arbres variés, fleurs, rochers ; aucun arbre répété à l'identique à proximité.

**Décisions de Kevin (2026-09-25) sur les écarts image/texte :**
- **Taille** : on garde la taille de l'image (≈ 48×32 cases). Les temps de marche du texte sont indicatifs : on règle la vitesse au test sur téléphone.
- **Jardins de recherche et secret** : **derrière le labo (au sud)**, comme dans le texte, et non à l'est comme sur l'image.
- **Pikachu et Évoli** visibles sur l'image : artefact de génération. Le starter se choisit au labo ; au départ, ni le joueur ni le rival n'ont de Pokémon.
- **Oiseaux marins** (Goélise, Gen 3) : à remplacer. L'espèce reste à définir dans le *Population & Life System*.
- Route 21 : départ vers l'est au bout du sentier côtier, comme sur l'image (compatible avec le texte).

### Vue générale peinte v1 — référence de rendu et de composition (validée par Kevin, 2026-10-05)
Fichiers : [`reference/bourg-palette-vue-generale-v1.png`](reference/bourg-palette-vue-generale-v1.png) (générée par Codex, prompt `tools/art/prompts/CONCEPT_BOURG_PALETTE_VUE_GENERALE_r6.txt`) et son plan schématique [`reference/bourg-palette-plan-v1.png`](reference/bourg-palette-plan-v1.png). Même main que `jadielle-vue-generale-v1`, lumière neutre (Godot porte l'ambiance). **Elle remplace la vue A+ comme cible de rendu** ; la vue A+ reste la référence d'éclairage golden hour.
- **Chemins à angle droit seulement** (on se déplace à l'horizontale ou à la verticale, jamais en diagonale) ; seule la place autour de l'arbre est arrondie.
- **Accès au labo** : sa porte est sur sa face sud (convention de la vue de trois quarts) ; depuis la place, deux allées partent à l'horizontale puis descendent de part et d'autre du labo jusqu'au parvis ; à l'ouest, l'allée continue jusqu'au sentier côtier.
- **Route 1** : une bande de hautes herbes barre toute la largeur du chemin, sans contournement : c'est là que Chen arrête le joueur.
- Jardins de recherche au sud du labo, ancien sentier envahi à leur est.

### Principes d'habillage (décisions de Kevin, 2026-10-06)
Tri des idées d'habillage proposées par ChatGPT. **Règle artistique principale de Bourg Palette : nature dense, objets rares.**
1. **Aucune faune non-Pokémon** (ni papillons, ni insectes, ni mouettes) : les signes de vie animale sont des Pokémon (Roucool, Piafabec près de la côte…).
2. **Pokémon des habitants** : dans le prototype, casting temporaire avec les Pokémon déjà peints (Rattata qui suit l'enfant, Roucool sur une clôture), sans figer les espèces ; choix définitifs au *Population & Life System*.
3. **Aucun des trois starters en liberté à Bourg Palette** (pas de Bulbizarre dans les jardins, contrairement à la vue générale) : cela affaiblirait le choix chez Chen. Plus tard, éventuellement un Pokémon commun de Kanto étudié par les chercheurs.
4. **Routines du prototype** (déplacement + pause seulement, sans animation d'action) : vieille dame maison ↔ banc ; pêcheur village ↔ ponton ; enfant + Rattata petite course ↔ retour ; chercheur labo ↔ serre. On teste d'abord si le mouvement suffit à faire vivre le village.
5. **Pas de props génériques** : chaque petit ensemble a un propriétaire (casiers du pêcheur, brouette de la jardinière, bois d'une maison). Un objet dont on ne peut pas expliquer la présence n'a pas à être là.
6. **Un seul ballon ou cerf-volant**, lié à l'enfant, plus tard (après l'attribution des maisons au *Population & Life System*).
7. **Garder volontairement des espaces vides** : une étendue d'herbe, un chemin calme ou une clôture sans activité participent à la DA. Le contraste entre quelques endroits habités et beaucoup de nature tranquille distingue Bourg Palette de Jadielle.
Plus tard : routines horaires, voisins qui discutent, fenêtres éclairées, fumée de cheminée, sons du vent et de la mer selon la position (phase 10 et *Population & Life System*) ; flaques après la pluie (météo, phase 10).

### 1. Maison du joueur — nord-est
Petit jardin, boîte aux lettres, vélo visible avant d'être utilisable, objets familiers.
**La chambre est le journal visuel de la progression** : au fil de l'aventure y apparaissent discrètement souvenirs, photos, cadeaux de PNJ, traces d'exploits (badges/récompenses). Pas un musée : quelques changements subtils. Revenir à la fin dans la chambre raconte le parcours.

### 2. Maison du rival — nord-ouest, en face
La proximité raconte leur relation (« vous avez grandi à quelques dizaines de mètres »). Sa sœur est présente comme dans l'original. Sa chambre : cartes, livres sur les Pokémon, trophées juniors → sans dialogue, on comprend qu'**il prépare son aventure depuis longtemps**.

### 3. Place centrale — nouveauté minuscule
Un grand **arbre ancien** (landmark émotionnel : « je suis chez moi »), deux bancs, panneau **BOURG PALETTE**. Des habitants s'y retrouvent selon l'heure.

### 4. Laboratoire de Chen — sud (fidèle)
Un peu plus imposant. Autour : antennes, matériel scientifique, caisses, vélos des chercheurs. Intérieur : salle principale, recherche, bibliothèque, machines, zone des starters, Pokémon qui y vivent (Rattata étudié, Roucool observé, un Pokémon endormi). **Le labo reste éclairé très tard.**

### 5. Jardins de recherche — derrière le labo
Petite serre (pas accessible au début), chercheurs visibles au travail.

### 6. Prairie du Nord — entre le village et la Route 1
Pas de combat. Premiers Pokémon sauvages **visibles** : Roucool, Rattata, Papilusion très rare. On peut les regarder. Quand on approche des **vraies hautes herbes** → Chen intervient (voir un Roucool paisible ≠ savoir affronter un Pokémon sauvage).
Depuis la prairie, on aperçoit **au loin l'horizon et les reliefs de Kanto** : « tout ça est devant moi ». Même horizon au retour en Maître.

### 7. Littoral — sud
L'eau fait partie de l'identité du village : petit sentier côtier, pontons, pêcheur, Magicarpe occasionnel, reflets. Le soir, probablement le plus bel endroit du village. **Surf** ouvrira plus tard la **Route 21** : visible dès les premières minutes, accessible bien plus tard.

## Secret — l'ancien sentier
Derrière les jardins de recherche, un **ancien sentier envahi par la végétation**, infranchissable. Chen : « Cette partie du terrain n'est plus utilisée depuis longtemps. » Rien de plus.
Accessible bien plus tard. Au bout : traces de **Chen jeune chercheur** (anciennes notes, photo, matériel abandonné) — pas Mew, pas un légendaire. Plante discrètement le fil **Mew/Mewtwo** sans prononcer leurs noms.

## Cycle horaire
| Heures | Ambiance |
|---|---|
| 06h–10h | lumière fraîche, rosée, habitants qui commencent leur journée |
| 10h–18h | village vivant |
| 18h–21h | lumière dorée sur l'océan, retour des habitants |
| 21h–06h | fenêtres éclairées, labo encore actif, presque personne dehors |

## Évolution avec l'aventure
Changements subtils : dialogues modifiés après quelques badges, habitants qui parlent des événements Team Rocket, retour après la Ligue presque un événement (on te reconnaît). Bourg Palette ne devient jamais une métropole.

## Habitants (10 à 15) — détail à venir (Population & Life System)
Pistes : jardinier·e, deux enfants jouant avec un Pokémon, chercheur qui traverse le village, vieille dame qui nourrit des Roucool, pêcheur près de l'eau à certaines heures, sœur du rival, mère du joueur.

## Déroulé d'ouverture
1. Chambre, soleil par la fenêtre, musique très légère. Pas de tutoriel.
2. Le joueur descend, sa mère lui parle.
3. Il sort : la caméra s'écarte légèrement, titre **BOURG PALETTE** / *Le commencement de toute aventure*, puis l'UI disparaît.
4. **Scène de l'herbe** : en entrant dans les hautes herbes vers la Route 1 sans Pokémon → « Hé ! Attends ! » — Chen arrive physiquement depuis le village, explique brièvement, « Viens avec moi. J'ai quelque chose à te montrer. », retour au labo.
5. **Choix du starter** mis en scène : sélection d'une Poké Ball → ouverture animée → le Pokémon apparaît dans la pièce avec une animation de caractère (Bulbizarre calme/curieux, Salamèche enthousiaste/flamme, Carapuce énergique/joueur). On peut examiner les trois. Pas de statistiques : décision émotionnelle.

Pas de Centre Pokémon à Bourg Palette.
