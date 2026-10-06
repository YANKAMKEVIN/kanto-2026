# Dossier 10 — Forêt de Jade

> Conçu par Kevin avec ChatGPT, reçu le 2026-10-06 ; passe d'alignement de Claude et **11 décisions de Kevin** le même jour (section « Arbitrages »). **Source de vérité** pour la Forêt de Jade (jalon 9 de la roadmap). Le tracé ASCII donne la logique, **pas à reproduire case par case**. Textes : section « Textes validés » (**validés tels quels par Kevin le 2026-10-06**, verrouillés). Jalon 9 lancé le 2026-10-06 (plan : `docs/tech/jalon-09.md`).

**Ligne directrice** : la Forêt de Jade est le premier endroit où Kanto cesse d'être confortable sans devenir hostile. Jusqu'ici, le joueur découvre ; ici, il commence à préparer son équipe.

## Arbitrages de Kevin (2026-10-06)
1. **Poison seul au jalon 9** ; le jalon 11 introduit le système général des statuts (paralysie, sommeil, brûlure, gel) et complète le poison. Roadmap corrigée.
2. **Le Poison persiste après le combat mais ne retire aucun PV pendant la marche** (modernisation assumée par rapport à Rouge/Bleu). Il disparaît avec un Antidote ou un soin au Centre Pokémon.
3. **Premières évolutions dès le jalon 9** (Chenipan et Aspicot atteignent leur niveau d'évolution dans la forêt) : séquence d'évolution **simple mais propre et définitive fonctionnellement**, avec possibilité d'annuler. Le jalon 11 enrichit la mise en scène et l'animation dans la présentation 2026, **sans refaire la logique métier**. Pas d'évolution « provisoire » à jeter.
4. **58 × 74 cases = enveloppe de référence verrouillée** ; les durées ne le sont pas (≈ 250 cases de chemin principal = un peu plus d'une minute de marche ; le reste vient des combats et des détours). Durées mesurées sur une vraie partie S24 avec rencontres et combats ; géométrie ajustée ensuite seulement si le rythme réel l'exige.
5. **Pikachu à 5 % partout** ; pas de table de rencontres par sous-zone pour H4. La clairière nord reste intéressante visuellement sans promettre davantage de Pikachu.
6. **Ni Roucool ni Rattata dans les rencontres sauvages** : Chenipan, Chrysacier, Aspicot, Coconfort et Pikachu seulement (nouvel écosystème). Roucool reste un Pokémon d'ambiance. Les 15 % libérés vont aux quatre Insecte, Pikachu inchangé.
7. **`poison_unlocked` s'active à la première conversation avec le garde du poste sud** : l'Antidote devient disponible à la Boutique de Jadielle (le joueur peut continuer avec celui de la forêt ou retourner s'équiper).
8. **Objets cachés** : texte environnemental pour découvrir la cache, puis **toast standard** de la bible UI (« Potion ×1 — Ajoutée au Sac », « Antidote ×1 — Ajouté au Sac ») ; pas de deuxième bulle « Une Potion ! ».
9. **Deux postes de garde verrouillés**, **une seule scène technique paramétrée** (garde, répliques et sorties différents).
10. **Repères : tronc incliné au sud → énorme souche au centre → clairière lumineuse au nord.** L'étude de DA (`reference/foret-jade-etude-ambiance-v1.png`, tracé provisoire, arbre ancien au centre) reste une référence d'**ambiance**, pas de level design.
11. **Contraintes du futur dossier de la Route 2** : aucun Dresseur avant la forêt (Léo reste le premier vrai Dresseur) ; la Route 2 est interrompue par la Forêt de Jade et ne permet pas de la contourner lors de la première progression (aussi notées dans la roadmap, phase 5).

## 1. Intention
**Première petite expédition** de l'aventure : « Je ne suis plus juste sur une route entre deux villes. Je suis entré quelque part. »
Différences avec la Route 1 : **orientation moins immédiate** (on voit moins loin) ; **pression légère sur les ressources** (poison, PV, plusieurs combats avant le prochain Centre) ; **biodiversité marquée** (Pokémon Insecte, premières compositions d'équipe intéressantes). Jamais oppressante : fraîche, vivante, mystérieuse et accueillante.
**Règle** : le joueur peut momentanément ne plus savoir où est la sortie, mais il n'est jamais réellement perdu.

## 2. Taille et durée
**≈ 58 × 74 cases** (enveloppe verrouillée), forme irrégulière à l'intérieur ; une grande partie est de la végétation infranchissable. Pas plus grand : un lieu conséquent, pas un donjon.
Durées visées (indicatives, arbitrage 4) : traversée directe 7–9 min ; première traversée 15–20 min ; exploration attentive 25–30 min, combats compris. La distance au Centre de Jadielle doit commencer à compter.

## 3. Entrées et sorties
ADN Rouge/Bleu : **Route 2 → poste sud → forêt → poste nord → Route 2 nord → Argenta**. Les postes sont de petits bâtiments-portes d'une pièce, traversés en quelques secondes, avec un garde chacun (une scène paramétrée, arbitrage 9). Répliques : « Textes validés ».
Conséquence pour la Route 2 : arbitrage 11.

## 4. Tracé
Structure logique (pas les dimensions exactes) :

```text
                         N
                  ┌──── POSTE NORD ────┐
██████████████████│    SORTIE          │████████████
██████████████████└──────┬─────────────┘████████████
████████████████████████ │ █████████████████████████
████████████       ┌─────┘ █████████████████████████
████████████   H4  │       ███████  O5 █████████████
████████████ ~~~~~ │   D5  ███████     █████████████
████████████ ~~~~~ ├───────────┐████████████████████
███████████████ ┌──┘   C3      │████████████████████
███████████████ │   CLAIRIÈRE  │████████████████████
██████ O4   ┌───┘      T4      └───────┐████████████
███████████ │ ~~~~~ H3 ~~~~~            │████████████
███████████ │ ~~~~~~~~~~~~~  ┌──────────┘████████████
███████████ └──────┐         │██████████████████████
██████████████████ │ D3   D4 │██████████████████████
██████████████ ┌───┘         └──────┐███████████████
████████ O3 ───┘       C2           │████████████████
████████████████   GRANDE SOUCHE    │████████████████
████████████████         P1         │████████████████
████████████████ ┌──────────────────┘████████████████
██████████   D2  │ █████████████████████████████████
██████████ ~~~~~ │      ┌──── O2 ███████████████████
██████████ ~~~~~ ├──────┘ ██████████████████████████
██████████ H2    │ █████████████████████████████████
██████████████ ┌─┘ █████████████████████████████████
██████████████ │       D1 ██████████████████████████
██████████████ │ ~~~~~~~~ ██████████████████████████
██████ O1 ─────┘ ~~~H1~~~ ██████████████████████████
██████████████      │ C1  ██████████████████████████
████████████████████│███████████████████████████████
                  ┌─┴──────────────┐
                  │   POSTE SUD    │
                  └──── ROUTE 2 ───┘
                         S
```

Légende : `████` forêt infranchissable · `│ ─` sentier · `~~~~` hautes herbes · `C` clairière · `H` hautes herbes · `D` Dresseur · `P` PNJ · `O` objet ou secret · `T4` repère.
Le chemin principal dessine un **grand S**, chaque segment **strictement orthogonal**. Boucles secondaires : on quitte le chemin, on trouve quelque chose, on revient naturellement dessus. **Aucun embranchement à trois directions équivalentes.** P2 (randonneuse) est dans une petite clairière secondaire (emplacement au level design).

## 5. Hautes herbes (4 zones)
- **H1 — lisière** : grande, facilement contournable ; montre que les rencontres changent.
- **H2 — sous-bois occidental** : facultative, capture / exploration, mène à O2.
- **H3 — passage dense** : une portion **obligatoire et courte (6–8 cases)** : on ne traverse pas la forêt sans rencontre.
- **H4 — clairière nord** : facultative, très tentante visuellement, juste avant la sortie (même table que le reste, arbitrage 5).

## 6. Rencontres sauvages
Une seule table pour toute la forêt (arbitrages 5 et 6), identique jour et nuit au jalon 9.

| Pokémon | Niveaux | Fréquence |
|---|---:|---:|
| Chenipan | 3–5 | 35 % |
| Aspicot | 3–5 | 35 % |
| Coconfort | 4–6 | 13 % |
| Chrysacier | 4–6 | 12 % |
| Pikachu | 4–5 | **5 %** |

Répartition des 15 % libérés = **valeur par défaut** (règle 4 de CLAUDE.md), ajustable dans les données. **Pikachu reste rare, jamais scénarisé** (« Attends… c'était Pikachu ? »).
**Données à créer au jalon 9** : les cinq espèces (absentes des données aujourd'hui) et leurs capacités (Dard-Venin, Sécrétion, Armure, Éclair, Rugissement…), leurs règles d'évolution (Chenipan → Chrysacier Nv. 7, Aspicot → Coconfort Nv. 7 ; Chrysacier → Papilusion et Coconfort → Dardargnan Nv. 10).

## 7. Pokémon d'ambiance
Ils rendent la forêt vivante sans remplacer les rencontres :
- **Chenipan** sur une feuille ou une branche basse : relève la tête quand on approche, puis continue.
- **Aspicot** sur un tronc : se rétracte vers le feuillage si le joueur arrive à une case.
- **Roucool** (un seul) sur une branche basse d'une clairière : **s'envole dans la canopée et disparaît** si on s'approche (comportement déjà existant au jalon 5).
- **Chrysacier / Coconfort** : très ponctuellement accrochés près d'un tronc, immobiles.
- **Aucun Pikachu d'ambiance.** Au plus, très rarement, un mouvement dans les feuillages sans source identifiable, sans cri obligatoire.

## 8. Dresseurs (5)
IA simple (début de jeu). Champs de vision en cases ; récompenses en ₽.

| | Dresseur | Vision | Évitable | Équipe | ₽ |
|---|---|---:|---|---|---:|
| D1 | Scout Léo | 4 | **non** (assez d'espace avant le déclenchement) | Chenipan Nv. 6 | 72 |
| D2 | Scout Noé | 5 | oui | Aspicot Nv. 6, Coconfort Nv. 6 | 144 |
| D3 | Gamin Tom | 4 | oui | Rattata Nv. 7 | 84 |
| D4 | Scout Milo | 5 | oui (détour par les hautes herbes) | Chenipan Nv. 6, Aspicot Nv. 6 | 144 |
| D5 | Scout Éli | 5 | oui | Chrysacier Nv. 7, Coconfort Nv. 7, Chenipan Nv. 7 | 252 |

Progression : un Pokémon simple → premier duo → autre famille → opposition de types → première petite équipe de trois. **Léo est le premier vrai Dresseur de l'aventure** (arbitrage 11). Répliques : « Textes validés ».
**Système à créer au jalon 9** (n'existe pas : le rival est déclenché par des scènes) : Dresseur qui voit le joueur dans son champ → « ! » → il avance de 2–3 cases → répliques → combat ; battu = mémorisé, réplique « après » ensuite.

## 9. PNJ non-combattants (2, plus les gardes)
- **P1 — jeune naturaliste**, près de la grande souche : marche sur 3 cases, s'arrête, observe un tronc, revient. Introduit les évolutions sans tutoriel.
- **P2 — randonneuse**, petite clairière secondaire : marche entre une souche et son sac posé au sol. Prépare à la gestion des ressources.

## 10. Objets (6)
| | Objet | Visible / caché | Emplacement |
|---|---|---|---|
| O1 | Antidote ×1 | visible | près du début : la solution **avant** que le poison devienne dangereux |
| O2 | Poké Ball ×1 | visible | cul-de-sac occidental (détour H2) |
| O3 | Potion ×1 | cachée | derrière la grande souche, par un passage discret dans le sous-bois |
| O4 | Antidote ×1 | caché | amas de racines |
| O5 | Poké Ball ×1 | visible | zone nord, récompense du détour final |
| O6 | Potion ×1 | cachée | près de la sortie |

Objets cachés : un texte environnemental puis le toast standard (arbitrage 8). **Aucun Antidote donné automatiquement** quand un Pokémon est empoisonné : avertissements + Antidote visible tôt, la mécanique a une conséquence réelle.

## 11. Secrets et recoins
- **La grande souche** : repère central ; on la contourne par un passage discret pour trouver O3.
- **Le cul-de-sac occidental** : ressemble à une erreur de chemin, contient O2 et une zone de rencontres : « les détours peuvent être utiles ».
- **La clairière H4** : pas de récompense artificielle ; un beau lieu (même table, arbitrage 5).

## 12. Ce que la forêt enseigne (sans tutoriel)
1. **Les Dresseurs** : D1 voit le joueur, marche vers lui, parle, combat. Le système s'explique seul.
2. **Le poison** : le garde avertit, un Antidote est visible, Aspicot peut empoisonner : danger → statut → objet.
3. **La distance au Centre** : à mi-parcours, revenir à Jadielle coûte du temps ; Potion et Antidote prennent leur sens.
4. **Construire une équipe** : nouvelles espèces, combats de Dresseurs qui font utiliser plusieurs Pokémon.
5. **L'évolution** : les Insecte changent vite (arbitrage 3) ; le naturaliste en parle.
6. **Les types** : aucun cours ; le joueur observe que certaines capacités marchent mieux.

## 13. Événements et narration
- **Rival absent** (le combat n°2 vient d'avoir lieu sur la Route 22).
- **Team Rocket absente et non nommée** (première apparition au Mont Sélénite).
- **Événement principal : la première détection par un Dresseur** (D1) : il remarque le joueur, « ! », avance de 2–3 cases, dialogue, combat. Pas de cinématique supplémentaire.

## 14. Ambiance
- **Palette** : verts profonds, bleu-vert léger dans les ombres, terre humide brun doux ; lumière chaude seulement dans les ouvertures de canopée. Pas de filtre vert uniforme. (Méthode C : assets en lumière neutre, ambiance portée par Godot.)
- **Lumière** : taches de lumière irrégulières ; clairières = respirations ; le personnage traverse parfois un rai lumineux puis retourne dans l'ombre.
- **Animation** très légère : feuilles, hautes herbes, petites branches, quelques particules végétales dans certains rayons. Pas d'effets permanents partout.
- **Son** : feuilles, vent filtré, branches, cris **exclusivement Pokémon** lointains ; l'espace sonore s'ouvre près des clairières.
- **Musique** : curieuse et légère (exploration, pas danger) ; éléments reconnaissables de la Forêt de Jade historique si le projet réinterprète les musiques.
- **Repères** : tronc incliné (sud) → énorme souche (centre) → clairière traversée par un rayon de lumière (nord) (arbitrage 10).
- **Aucune faune non-Pokémon.**

## 15. Défaite
Système normal : **réveil au dernier Centre utilisé** (normalement Jadielle), chez Maman si aucun Centre n'a été enregistré (dossier 09 §7) ; aucune perte d'argent ; aucun texte propre à la forêt. **Aucun point de reprise au milieu** : la distance au Centre fait partie de l'apprentissage.

## 16. Données et sauvegarde
À mémoriser : forêt découverte (entrée et sortie nord) ; chacun des 5 Dresseurs battu ou non ; chacun des 6 objets ramassé ou non ; `poison_unlocked` ; vu / capturé par le Pokédex existant ; statut Poison de chaque Pokémon (persistant, arbitrage 2) ; drapeau « première détection par un Dresseur » si le système en a besoin.
À ne pas mémoriser : la position des Pokémon d'ambiance (un Roucool parti peut revenir au rechargement ou au changement de carte).

## 17. Coûts techniques identifiés (pour le plan du jalon 9)
- **Statut Poison** persistant (combat + hors combat, Antidote, soin au Centre), sans dégâts à la marche.
- **Séquence d'évolution** fonctionnellement définitive avec annulation (logique existante dans `game/pokemon/evolution/`, présentation à créer).
- **Système de Dresseur** : champ de vision, approche, répliques avant / après, mémoire, récompense.
- **Données** : 5 espèces, leurs capacités et évolutions, la table de rencontres, les 5 Dresseurs, les objets.
- **Postes de garde** : une scène d'intérieur paramétrée (système existant).
- **Carte** 58 × 74 avec la forêt serrée du prototype de DA : performances à vérifier sur S24 (plus d'arbres que la Route 1).

## Textes validés
Lot proposé par ChatGPT, **validé tel quel par Kevin le 2026-10-06** (verrouillé : à reprendre mot pour mot dans `data/dialogues/`). Bulles de 2 lignes.

**Garde du poste sud** — « La Forêt de Jade est juste devant. » / « Garde un Antidote avec toi. » · en lui reparlant : « Les Aspicot peuvent empoisonner. » / « Mieux vaut être préparé. »
**Garde du poste nord** — depuis la forêt : « Encore quelques pas vers le nord, » / « et tu atteindras Argenta. » · depuis Argenta : « La Forêt de Jade mène à Jadielle. » / « Les jeunes Dresseurs s'y entraînent. »
**D1, Scout Léo** — avant : « Hé ! Toi aussi, tu cherches » / « des Pokémon dans la forêt ? » · après : « Ton Pokémon est bien entraîné. » / « Je dois encore progresser. »
**D2, Scout Noé** — avant : « Mes Pokémon ont grandi ici. » / « Tu veux les affronter ? » · après : « Ils deviennent plus forts » / « chaque jour. »
**D3, Gamin Tom** — avant : « Je connais cette forêt par cœur ! » / « Enfin... presque. » · après : « D'accord. Peut-être pas par cœur. »
**D4, Scout Milo** — avant : « Les Pokémon Insecte évoluent vite. » / « Regarde ça ! » · après : « Pas encore assez vite, apparemment. »
**D5, Scout Éli** — avant : « Tu as traversé toute la forêt ? » / « Alors montre-moi ton équipe ! » · après : « Pas mal ! » / « Argenta n'est plus très loin. »
**P1, naturaliste** — « Certains Pokémon changent très vite » / « quand ils grandissent. » · puis : « J'aimerais les observer évoluer ici. »
**P2, randonneuse** — « Plus on avance, plus Jadielle » / « paraît loin, pas vrai ? » · puis : « Je garde toujours de quoi soigner » / « mon équipe avant de repartir. »
**Objets cachés** — O3 : « Quelque chose est caché sous les feuilles. » · O4 : « Quelque chose est coincé entre les racines. » · O6 : « Quelque chose dépasse derrière cette souche. » → toast standard.

## Décisions verrouillées
| Élément | Décision |
|---|---|
| Rôle | Première véritable petite expédition |
| Ton | Dense, frais, vivant, jamais effrayant |
| Taille | ≈ 58 × 74 cases (enveloppe) ; durées mesurées sur S24 |
| Structure | Grand chemin orthogonal en S + boucles secondaires |
| Entrée / sortie | Route 2 sud → poste sud · poste nord → Route 2 nord → Argenta |
| Postes de garde | 2, une scène technique paramétrée |
| Route 2 | Aucun Dresseur avant la forêt ; pas de contournement à la première progression |
| Hautes herbes | 4 zones, passage obligatoire court (H3) |
| Rencontres | Chenipan 35 %, Aspicot 35 %, Coconfort 13 %, Chrysacier 12 %, Pikachu 5 % (partout) |
| Pikachu | Rare, jamais scénarisé, pas d'ambiance |
| Pokémon d'ambiance | Chenipan, Aspicot, Roucool (s'envole), Chrysacier/Coconfort |
| Dresseurs | 5 ; Scout Léo obligatoire et premier vrai Dresseur |
| PNJ | 2 (naturaliste, randonneuse) + 2 gardes |
| Objets | 6, dont 2 Antidotes ; cachés = texte + toast standard |
| Poison | Seul au J9, persistant, aucun dégât en marchant ; Antidote ou Centre |
| `poison_unlocked` | Première conversation avec le garde sud → Antidote à la Boutique de Jadielle |
| Évolutions | Dès le J9, séquence propre et définitive avec annulation ; mise en scène enrichie au J11 |
| Centre intermédiaire | Aucun |
| Rival / Team Rocket | Absents (Team Rocket non nommée) |
| Événement | Première détection par un Dresseur |
| Repères | Tronc incliné → grande souche → clairière lumineuse |
| Décor | Nature dense, objets rares et justifiés ; aucune faune non-Pokémon |
| Jour / nuit | Même table au J9 |
| Défaite | Dernier Centre utilisé (Jadielle), sinon Maman ; pas de perte d'argent |
| Textes | Lot ci-dessus, validé tel quel par Kevin (2026-10-06) |
