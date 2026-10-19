# J18 — La traversée de la Grotte Sombre : V2 de ChatGPT (reçue le 2026-10-14)

> Reproduite telle que Kevin l'a transmise (le schéma « Sans Flash / Avec Flash » de la section 3
> était une illustration, non reproduite). Passe d'alignement : `j18-v2-alignement.md`.

Dossier de conception V2 · 7 arbitrages validés · En attente d'audit par Claude

État d'avancement : les décisions de conception de J11 à J18 sont préparées. J18 peut maintenant
être consolidé, tandis que nous lançons la réflexion sur J19. Cela ne signifie pas que ces jalons
sont déjà implémentés ou validés sur Galaxy S24.

J18 doit offrir une expérience très différente du Mont Sélénite : une longue traversée où la
lumière, l'orientation et l'atmosphère comptent autant que les combats.

Et surtout, le joueur doit ressentir quelque chose en découvrant Lavanville après la grotte.

## 1. Les sept décisions verrouillées

| Sujet | Décision |
|---|---|
| Périmètre | Route 9 + Route 10 + Grotte Sombre + Lavanville |
| Grotte Sombre | Deux niveaux, embranchements lisibles |
| Flash | Très utile, mais facultatif |
| Éclairage | Petit halo sans Flash, visibilité étendue avec Flash |
| Difficulté | Modérée, rencontres variées |
| Lavanville | Mélancolique, mystérieuse, respectueuse |
| Tour Pokémon | Extérieur et rez-de-chaussée au J18 ; étages au J19 |

Ces choix constituent la base du dossier. Claude pourra signaler des incompatibilités techniques,
mais pas modifier silencieusement ces décisions.

## 2. Géographie et progression

Schéma de progression, non une carte à l'échelle. La Route 10 est une même zone géographique avec
des secteurs nord et sud.

### Route 9 — La sortie vers l'est

Je propose une carte d'environ 88 × 38 cases, à ajuster lors du plan fonctionnel.

La Route 9 doit avoir un relief visuel marqué : falaises basses, rochers, sentiers, herbes et
passages entre les arbres. La caméra reste orthogonale, sans vue isométrique.

Contenu proposé : six à huit Dresseurs, dont deux ou trois incontournables, plusieurs objets et
quelques petits chemins alternatifs.

Les équipes doivent marquer une progression depuis Route 11 sans introduire une difficulté
excessive.

### Route 10 — Une transition en deux temps

Au nord, un Centre Pokémon permet de se préparer à la traversée. La centrale électrique et les
zones accessibles par Surf pourront être visibles ou suggérées, mais pas explorées au J18.

Au sud, la sortie de la grotte débouche sur un environnement plus calme. Le joueur aperçoit
progressivement Lavanville.

La Route 10 doit rester identifiable comme une seule route, même si les portions nord et sud sont
séparées par la grotte.

## 3. Grotte Sombre — Deux niveaux, pas de labyrinthe punitif

Je propose deux cartes :

| Niveau | Dimensions indicatives | Rôle |
|---|---|---|
| Niveau 1 | 78 × 58 cases | Entrée, premiers embranchements, repères naturels |
| Niveau 2 | 64 × 52 cases | Traversée principale, quelques détours et sortie |

Les dimensions sont provisoires et devront être réduites si elles allongent inutilement le temps
de traversée.

La grotte doit posséder des repères visuels mémorables : une grande colonne rocheuse, une paroi
fissurée, des racines visibles, une zone légèrement humide et un passage plus étroit.

Les échelles et les chemins doivent être cohérents géographiquement. Pas de téléportations
arbitraires entre des salles éloignées.

### Éclairage : Flash utile, jamais obligatoire

Sans Flash : halo limité autour du joueur, mais chemin encore praticable. (Schéma illustratif, pas
un rendu Godot.)

Je recommande un éclairage local doux, sans obscurité totale, et une visibilité étendue après
utilisation de Flash. Le rendu doit rester lisible sur un écran de Galaxy S24, y compris avec une
luminosité d'écran modérée.

Flash ne doit pas révéler des passages secrets invisibles autrement : il améliore la lecture du
terrain, pas les règles de collision.

## 4. Rencontres et difficulté

Les espèces envisagées dans la grotte sont Racaillou, Nosferapti, Machoc et Onix, selon les tables
historiques et les données disponibles.

Les Dresseurs doivent être moins nombreux que sur la Route 9. Je propose quatre à six rencontres de
Dresseurs au total dans la grotte, dont une partie facultative.

L'objectif n'est pas d'épuiser artificiellement les ressources du joueur. La difficulté doit venir
de l'exploration, de la gestion de l'équipe et de quelques combats bien placés.

Le joueur peut ressortir par l'entrée nord avant d'avoir terminé la traversée. Les Corde Sortie et
Tunnel devront utiliser une règle de destination explicite, auditée avec les mécaniques
introduites aux J12 et J14.

## 5. Lavanville — Une ville qui raconte quelque chose

Je propose une ville d'environ 58 × 46 cases, avec des rues paisibles, une végétation discrète et
une palette de gris violacés, de beige et de vert désaturé.

La ville doit être mélancolique, mais pas horrifique.

Les habitants parlent des Pokémon disparus, de leurs souvenirs et de la Tour Pokémon. Certains sont
tristes, d'autres reconnaissants, d'autres simplement occupés par leur quotidien.

Le Centre Pokémon, la Boutique et les bâtiments essentiels sont disponibles dès l'arrivée.

### La Tour Pokémon au J18

Le joueur peut entrer au rez-de-chaussée, parler aux visiteurs et comprendre le rôle du lieu.

Les étages supérieurs restent inaccessibles jusqu'à J19, avec une justification narrative
naturelle.

Il ne doit pas y avoir de spectres agressifs, de combat contre le rival ni de confrontation Rocket
dans la Tour au J18.

Le dernier moment de J18 : le joueur entre dans la Tour, observe le calme du lieu et comprend
qu'une histoire plus profonde l'attend.

## 6. Dépendances techniques et risques

| Référence | Dépendance | Point à vérifier |
|---|---|---|
| J18-A | Coupe, J16 | Accès à Route 9 depuis Azuria, sans contournement |
| J18-B | Flash, J17 | Apprentissage, usage hors combat et persistance de l'effet |
| J18-C | Éclairage Godot | Halo dynamique, transitions, performances sur S24 |
| J18-D | Rencontres de grotte, J12 | Zones de déclenchement, taux et tables d'espèces |
| J18-E | Corde Sortie / Tunnel | Destination cohérente depuis chaque niveau |
| J18-F | Pokémon et capacités | Machoc, Onix et autres espèces, effets de combat nécessaires |
| J18-G | Sauvegarde | Dresseurs, objets, position et état lumineux |
| J18-H | Tour Pokémon | Accès au rez-de-chaussée, étages bloqués jusqu'à J19 |
| J18-I | Compagnon | Suivi dans la grotte, rétraction dans les passages étroits |
| J18-J | Fonds de combat CB.3 | Route rocheuse, grotte sombre et environs de Lavanville |

### Trois risques prioritaires

1. **Flash ne doit pas créer un blocage.** Si le joueur ne possède pas Flash, la grotte reste
   traversable. Les collisions et la géographie sont strictement identiques avec ou sans éclairage.
2. **La Grotte Sombre ne doit pas devenir trop longue.** Deux niveaux, des embranchements et des
   rencontres répétées peuvent rapidement transformer l'exploration en épreuve d'endurance. Claude
   devra estimer la durée réelle et réduire les détours si nécessaire.
3. **J18 ne doit pas commencer l'intrigue de J19 trop tôt.** Lavanville peut présenter ses
   habitants, sa mémoire et la Tour Pokémon, mais les événements majeurs liés aux spectres, au
   rival et à la Team Rocket restent réservés au jalon suivant.

## 7. Découpage de production J18

| Lot | Contenu |
|---|---|
| 18.0 | Audit, plans fonctionnels, dialogues, données et assets |
| 18A | Route 9 et Route 10 nord |
| 18B | Grotte Sombre, géographie et transitions |
| 18C | Éclairage, Flash et rencontres |
| 18D | Route 10 sud et Lavanville |
| 18E | Rez-de-chaussée de la Tour Pokémon |
| 18F | QA complète Galaxy S24 et non-régression |

Validation attendue : le joueur peut effectuer Azuria → Route 9 → Route 10 → Grotte Sombre →
Lavanville, avec ou sans Flash, sauvegarder à différents points, revenir en arrière et accéder au
rez-de-chaussée de la Tour sans déclencher prématurément J19.

## 8. Message transmis à Claude

Nous avons validé sept arbitrages pour J18 : (1) périmètre Route 9, Route 10, Grotte Sombre et
Lavanville ; (2) Grotte Sombre sur deux niveaux, avec embranchements lisibles ; (3) Flash très
utile mais non obligatoire ; (4) sans Flash : halo réduit, avec Flash : visibilité étendue ;
(5) difficulté modérée et rencontres variées ; (6) Lavanville mélancolique, mystérieuse et
respectueuse, sans horreur excessive ; (7) Tour Pokémon : extérieur et rez-de-chaussée au J18,
étages au J19.

Direction artistique inchangée : monde 2D HD peint, top-down orthogonal, éclairage géré dans
Godot. Pas de pixel art, d'isométrie, de minimap ni de flèches d'objectif.

Conception proposée : Route 9 rocheuse, avec Dresseurs et chemins alternatifs ; Route 10 divisée
géographiquement entre secteur nord et secteur sud, avec Centre Pokémon au nord ; Grotte Sombre à
deux niveaux, lisible même sans Flash ; repères environnementaux et embranchements, sans labyrinthe
punitif ; Lavanville complète avec Centre, Boutique, habitants et Tour Pokémon accessible au
rez-de-chaussée ; aucun événement majeur de la Tour avant J19.

Audit demandé :

1. Vérifier les frontières J17/J18/J19 et la roadmap.
2. Vérifier l'accès à Route 9 via Coupe.
3. Auditer CS05 Flash, ses conditions d'utilisation, son comportement lumineux et sa persistance.
4. Vérifier la compatibilité de l'éclairage avec les shaders et les performances sur Galaxy S24.
5. Auditer les mécaniques de rencontre en grotte, les tables sauvages, les Dresseurs et les
   capacités nécessaires.
6. Vérifier les règles de Corde Sortie et Tunnel sur les deux niveaux.
7. Identifier tous les Pokémon et assets nécessaires, y compris sprites du monde et dos peints.
8. Définir les cartes, raccords, PNJ, dialogues, objets, états de sauvegarde et critères QA.
9. Vérifier que la Tour Pokémon ne déclenche aucun événement de J19.
10. Signaler les contradictions avec Rouge/Bleu, en distinguant les adaptations volontaires.

Produis une passe d'alignement avec arbitrages numérotés, puis le dossier de conception complet
après validation. Travaille sur une branche documentaire indépendante, vérifie le prochain numéro
de dossier disponible et ne code rien. Nous préparons en parallèle J19.
