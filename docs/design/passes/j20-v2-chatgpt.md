# J20 — Céladopole, les lumières et les ombres : V2 de ChatGPT (reçue le 2026-10-14)

> Reproduite telle que Kevin l'a transmise (mise en forme Markdown seulement ; les illustrations
> n'étaient pas jointes). Passe d'alignement : `j20-v2-alignement.md`.

Dossier de conception V2 · 7 décisions validées · Audit de Claude à venir

État d'avancement : J19 est consolidé sur le plan narratif. Les sept arbitrages de J20 sont désormais
validés. Nous pouvons préparer le dossier pour Claude et commencer J21, qui résoudra l'intrigue de la
Tour Pokémon.

J20 sera l'un des jalons les plus ambitieux du jeu jusqu'ici : une nouvelle grande ville, deux routes,
un passage souterrain, une Arène et le premier affrontement contre Giovanni.

L'idée centrale : Céladopole paraît prospère et accueillante en surface, mais la Team Rocket opère
secrètement sous la ville.

## 1. Les sept décisions verrouillées

| Sujet | Décision |
|---|---|
| Périmètre | Route 8, passage souterrain, Route 7, Céladopole |
| Ville | Complète, avec grand magasin et bâtiments principaux |
| Arène | Erika affrontable, Badge Prisme disponible |
| Repaire Rocket | Intégral, Giovanni et Scope Sylphe |
| Énigmes | Dalles tournantes et ascenseur fidèles à Rouge/Bleu |
| Casino | Lieu narratif, sans mini-jeux d'argent jouables |
| Fin du jalon | Scope Sylphe obtenu ; retour à la Tour au J21 |

La victoire contre Erika et celle contre Giovanni sont deux objectifs distincts. Je recommande de ne
pas imposer un ordre entre eux : le joueur peut visiter la ville, défier l'Arène ou enquêter sur le
Casino selon son envie.

## 2. Géographie et progression

Schéma de progression uniquement. Les raccords définitifs devront respecter les cartes existantes et
la géographie historique.

### Route 8
Une route relativement longue, avec des Dresseurs, des herbes et des chemins alternatifs. Je propose
six à huit Dresseurs et des rencontres adaptées au niveau de progression.

Le poste de garde vers Safrania reste fermé tant que les conditions d'accès à la ville ne sont pas
remplies.

### Passage souterrain
Il relie la Route 8 à la Route 7, sans ouvrir Safrania.

Je recommande un couloir sobre, légèrement plus développé que dans les jeux originaux, avec une
découverte facultative mais aucun combat imposé.

### Route 7
Une route courte servant de transition. Elle doit permettre d'apercevoir progressivement les grands
bâtiments de Céladopole.

## 3. Céladopole — Une vraie grande ville

Je propose une ville d'environ 110 × 80 cases, à ajuster lors de l'audit des dimensions et du
viewport.

Elle doit être plus vaste et plus animée qu'Azuria ou Carmin, mais sans foule artificielle ni
personnages décoratifs qui bloquent les déplacements.

| Bâtiment | Fonction J20 |
|---|---|
| Centre Pokémon | Soins et sauvegarde |
| Grand magasin | Plusieurs étages, vendeurs et objets |
| Résidence Céladon | PNJ, exploration et éventuelle récompense historique |
| Arène d'Erika | Combat complet et Badge Prisme |
| Casino | Enquête narrative et accès au repaire |
| Restaurant | Dialogues et récompenses à auditer |
| Hôtel | Décor et interactions légères |
| Maison liée au Thé | Préparation de l'accès futur à Safrania |

Le grand magasin doit avoir une véritable identité : ascenseur, escaliers, étages spécialisés et toit.
Les objets vendus doivent respecter l'économie du jeu.

Point historique à préserver : Céladopole est associée à l'obtention d'Évoli et à plusieurs objets
importants. Claude devra vérifier leur emplacement, leur unicité et leur disponibilité selon notre
progression.

## 4. L'Arène d'Erika

L'Arène sera un espace végétal élégant, avec des haies, des plantes et des passages à dégager grâce à
Coupe.

Je recommande une structure proche de Rouge/Bleu : plusieurs Dresseuses, un chemin vers Erika et un
combat qui récompense la préparation de l'équipe.

Équipe historique à vérifier : Empiflor, Saquedeneu et Rafflesia, avec des niveaux proches de 29 à 32.

Récompenses proposées : Badge Prisme et CT21 Méga-Sangsue, sous réserve de confirmation de leur
correspondance historique et de l'implémentation des capacités.

Le Badge Prisme doit être enregistré dans la sauvegarde, sans appliquer automatiquement de bonus de
statistiques caché si ce système n'a pas été retenu dans le projet.

## 5. Casino et repaire Rocket

Le Casino est présent comme lieu narratif, mais il n'y a aucun mini-jeu d'argent jouable.

L'accès au repaire se fait par la découverte d'un mécanisme secret lié à une affiche et à un membre de
la Team Rocket, conformément à l'esprit de Rouge/Bleu.

| Niveau | Contenu |
|---|---|
| Casino | PNJ, indice, mécanisme secret |
| Sous-sol 1 | Introduction du repaire, premiers Rocket |
| Sous-sol 2 | Dalles tournantes, embranchements, objets |
| Sous-sol 3 | Exploration, Dresseurs, accès vers la suite |
| Sous-sol 4 | Clé d'ascenseur, derniers Rocket, Giovanni |

La disposition exacte des dalles et la localisation de la clé doivent être vérifiées avec les cartes
historiques.

### Dalles tournantes : adaptation mobile
Le joueur marche sur une dalle et est transporté automatiquement dans la direction indiquée. Le
mouvement est animé, lisible et déterministe.

Il ne doit pas être possible de sortir d'une dalle à un endroit non prévu, de traverser un mur ou de
rester coincé après une interruption de l'application.

L'ascenseur doit desservir uniquement les étages autorisés par la progression.

## 6. Giovanni — Premier grand affrontement

Giovanni doit être présenté comme un chef calme, autoritaire et sûr de lui, pas comme un antagoniste
caricatural.

Son équipe historique pour le premier combat comprend Onix, Rhinocorne et Kangourex, avec des niveaux
à auditer.

Je recommande une victoire obligatoire pour obtenir le Scope Sylphe, avec possibilité de retenter le
combat après une défaite.

Après sa défaite, Giovanni quitte le repaire et le joueur récupère le Scope Sylphe. L'objet est
enregistré comme objet-clé unique.

Le repaire reste explorable pour récupérer les objets oubliés, mais les combats et récompenses déjà
consommés ne se réinitialisent pas.

## 7. Dépendances avec J19

| Dépendance | Règle |
|---|---|
| Spectres non identifiés | Le Scope Sylphe permet leur identification |
| Ossatueur | Rencontre réservée au retour à la Tour |
| M. Fuji | Toujours prisonnier à la fin de J20 |
| Poké Flûte | Non obtenue en J20 |
| Ronflex | Toujours endormi |
| Cinquième rival | Victoire conservée depuis J19 |
| Tour Pokémon | Étages et événements supérieurs prêts à être activés en J21 |

Le Scope Sylphe doit fonctionner sans réécrire la sauvegarde du J19. Sa possession doit suffire à
modifier les règles d'identification des spectres lors du retour.

J20 ne doit pas déclencher automatiquement le sauvetage de M. Fuji. Le joueur doit physiquement
retourner à Lavanville et terminer la Tour au J21.

## 8. Dépendances techniques et risques

| Référence | Point à auditer |
|---|---|
| J20-A | Connexions Route 8 → passage souterrain → Route 7 |
| J20-B | État des postes de garde de Safrania |
| J20-C | Grand magasin, inventaire, prix, ascenseur |
| J20-D | Coupe et accès à l'Arène |
| J20-E | Combat d'Erika, Badge Prisme, CT |
| J20-F | Dalles tournantes et ascenseur Rocket |
| J20-G | Combats Rocket et première équipe de Giovanni |
| J20-H | Scope Sylphe et système de spectres J19 |
| J20-I | Sauvegarde, objets uniques, flags et migrations |
| J20-J | Assets du monde, combats CB.3 et QA Galaxy S24 |

Les trois risques principaux sont la taille du jalon, les collisions des dalles tournantes et les
dépendances entre le Scope Sylphe et la Tour Pokémon.

Je recommande de préparer toutes les cartes du repaire avant d'implémenter les événements, afin
d'éviter de reconstruire les transitions après coup.

## 9. Découpage de production

| Lot | Contenu |
|---|---|
| 20.0 | Audit et plan documentaire |
| 20A | Route 8, souterrain et Route 7 |
| 20B | Ville, bâtiments et grand magasin |
| 20C | Arène d'Erika et Badge Prisme |
| 20D | Casino narratif et repaire Rocket |
| 20E | Giovanni et Scope Sylphe |
| 20F | QA Galaxy S24 et non-régression |

Critère de fin J20 : le joueur peut atteindre Céladopole, explorer la ville, obtenir le Badge Prisme,
terminer le repaire Rocket et récupérer le Scope Sylphe. Il peut retourner à Lavanville, mais les
événements de résolution de la Tour restent réservés à J21.

## 10. Message transmis à Claude

Mission : auditer le dépôt réel, la roadmap, les dossiers J16–J19 et les règles historiques de
Rouge/Bleu ; préparer le dossier J20 (cartographie des Routes 8 et 7 et du souterrain, plan de
Céladopole, grand magasin, récompenses historiques dont Évoli, Arène d'Erika, Casino narratif,
repaire Rocket, Giovanni, Scope Sylphe, drapeaux et migrations, assets, tests et QA S24).

Vérifications prioritaires :
1. Emplacement exact de la Clé Ascenseur dans le repaire original (ne pas la déduire du seul étage de
   Giovanni).
2. Accès à Safrania et conséquences futures de l'obtention du Thé.
3. Indépendance de l'Arène d'Erika et du repaire Rocket dans l'ordre de progression.
4. Comportement des spectres avant et après acquisition du Scope Sylphe.
5. Préparer J21 sans activer Ossatueur, le sauvetage de M. Fuji ou la Poké Flûte.
6. Numéros de dossiers et version actuelle du schéma de sauvegarde sur la branche de référence.

Contraintes : 2D HD peinte, top-down orthogonal, pas de pixel art ni d'isométrie ; pas de minimap ni
de flèches d'objectif ; pas de foule artificielle ; Casino non jouable pour les jeux d'argent ;
respect des décisions validées, toute divergence soumise à arbitrage. Passe d'alignement numérotée
d'abord, dossier complet après validation. Branche documentaire indépendante. Ne rien coder.
