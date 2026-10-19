# J17 — Les chemins retrouvés : V2 de Kevin (avec ChatGPT), reçue le 2026-10-14

> Copie de travail de la proposition transmise par Kevin, pour la passe d'alignement
> (`j17-v2-alignement.md`). Les six arbitrages de la V2 restent numérotés **1 à 6** ; ceux de la
> passe prennent les lettres **H-** (B à G et V sont déjà prises par les passes J12 à J16).

Dossier de conception V2 · 6 décisions verrouillées · En attente d'audit technique par Claude.

J17 sera consacré à une idée forte : **Kanto commence à se reconnecter**. Grâce à Coupe, le joueur
découvre de nouveaux passages dans des lieux familiers et comprend que le monde continue d'évoluer à
mesure qu'il progresse.

## 1. Périmètre définitif

| Zone | Contenu validé |
|---|---|
| Route 11 | Route complète, Dresseurs, objets, rencontres |
| Cave Taupiqueur | Traversée courte avec quelques renfoncements |
| Route 2 revisitée | Raccourcis et découvertes accessibles grâce à Coupe |
| Maison de l'assistant de Chen | CS05 Flash après 10 espèces possédées |
| Extrémité est de Route 11 | Ronflex endormi, progression bloquée |
| Route 9 et Grotte Sombre | Réservées à J18 |

Pas de nouvelle Arène, de rival ou de combat contre la Team Rocket dans J17.

## 2. La progression géographique

Schéma des connexions, non une carte à l'échelle. Cave Taupiqueur relie le secteur de Carmin à la
Route 2.

**Route 11.** Carte horizontale d'environ 76 × 36 cases, six à huit Dresseurs, principalement
facultatifs. Les herbes et les clôtures offrent plusieurs parcours sans créer de labyrinthe. Le Ronflex
endormi est visible à la frontière de la Route 12. Le joueur peut l'examiner, mais pas encore le
réveiller. Le drapeau de progression correspondant reste inchangé jusqu'au futur jalon consacré à la
Poké Flûte.

**Cave Taupiqueur.** Carte d'environ 34 × 80 cases, principalement linéaire, avec deux ou trois
renfoncements facultatifs. Rencontres centrées sur Taupiqueur et Triopikeur. Triopikeur doit être rare
et potentiellement dangereux, sans rendre le passage impraticable. Pas de Flash nécessaire : l'éclairage
naturel du tunnel doit rester lisible.

**Route 2 revisitée.** Réutiliser la géographie déjà créée plutôt que reconstruire une deuxième Route 2.
Les nouveaux passages accessibles avec Coupe conduisent notamment à la maison de l'assistant de Chen,
à des raccourcis et à quelques découvertes facultatives. La sortie nord de la Cave Taupiqueur doit être
raccordée correctement à cette région, avec retour possible vers Carmin à tout moment.

## 3. CS05 Flash : la récompense majeure

Le joueur rencontre un assistant du Professeur Chen. Condition : **10 espèces distinctes possédées**
dans le Pokédex (pas dix Pokémon dans l'équipe, ni dix captures du même Pokémon). Si le seuil n'est pas
atteint, l'assistant indique la condition et reste disponible. Une fois les dix espèces enregistrées, il
remet la CS05 Flash une seule fois.

Recevoir Flash au J17 ne signifie pas forcément que son éclairage hors combat est déjà opérationnel.
Recommandation : implémenter et tester cet éclairage avant de considérer J17 terminé, pour ne pas
transférer une dépendance fragile à J18. Le rendu lumineux doit rester compatible avec l'éclairage
Godot du monde peint.

## 4. Les espèces, les Dresseurs et les objets

| Zone | Contenu proposé |
|---|---|
| Route 11 | Piafabec, Abo/Sabelette selon les données, Soporifik |
| Cave Taupiqueur | Taupiqueur courant, Triopikeur rare |
| Route 2 | Tables existantes, pas de nouvelles espèces imposées |
| Dresseurs Route 11 | 6 à 8, équipes et niveaux à auditer |
| Objets | 2 à 3 visibles, 1 caché sur Route 11 ; quelques découvertes après Coupe |

Conserver les espèces déjà introduites dans J1–J16 et vérifier les véritables données de Rouge/Bleu
avant de figer les rencontres. Illustrations du monde, dos de combat et données Pokédex des nouvelles
espèces préparés ensemble.

## 5. Dépendances et risques techniques

| Réf. | Dépendance | Risque à maîtriser |
|---|---|---|
| J17-A | CS01 Coupe du J16 | Obstacles qui bloquent encore après utilisation |
| J17-B | Cartes Route 2 existantes | Raccords incompatibles ou collisions |
| J17-C | Rencontres en grotte du J12 | Taux et niveaux de Triopikeur |
| J17-D | Pokédex et stockage | Mauvais calcul des 10 espèces possédées |
| J17-E | CS05 Flash | Capacité reçue mais non utilisable |
| J17-F | Ronflex | Obstacle contournable par erreur |
| J17-G | Sauvegarde | Récompense ou objet obtenu plusieurs fois |
| J17-H | Compagnon J11 | Rétraction dans les passages étroits |
| J17-I | Assets CB.3 | Fonds de combat propres à la Route 11 et à la Cave |
| J17-J | QA S24 | Transitions, performance, sauvegarde et retour arrière |

Vigilance sur Coupe : le joueur doit pouvoir revenir en arrière sans conserver en permanence le même
Pokémon dans son équipe. Les arbustes peuvent repousser après un changement de carte, mais jamais de
manière à enfermer le joueur.

## 6. Découpage de production

| Lot | Contenu |
|---|---|
| 17.0 | Audit, plans, dialogues, données et assets |
| 17A | Route 11, Dresseurs, objets, Ronflex |
| 17B | Cave Taupiqueur et raccords |
| 17C | Route 2 revisitée, passages Coupe |
| 17D | Assistant de Chen, condition Pokédex, Flash |
| 17E | QA complète sur Galaxy S24 |

Critères : traversée Carmin → Cave → Route 2 → Carmin, objets persistants, combats enregistrés, CS05
obtenue une seule fois, impossibilité de contourner Ronflex, absence de blocage après Coupe, tests de
sauvegarde / rechargement à chaque transition.

## 7. Les six arbitrages validés

1. Route 11 complète + Cave Taupiqueur + Route 2 revisitée.
2. Cave Taupiqueur courte et naturelle, avec quelques renfoncements.
3. Raccourcis et découvertes ouverts grâce à Coupe.
4. CS05 Flash remise par l'assistant de Chen après 10 espèces possédées.
5. Route 11 complète, avec Dresseurs et Ronflex bloquant à l'est.
6. Exploration de la Grotte Sombre réservée à J18.

Direction artistique : HD peint, top-down orthogonal, éclairage neutre pour les assets, éclairage du
monde géré dans Godot. Pas de pixel art, d'isométrie ni de minimap.

Mission confiée à Claude : passe d'alignement numérotée, puis dossier complet après validation. Ne rien
coder. Branche documentaire indépendante ; vérifier le prochain numéro de dossier disponible.
