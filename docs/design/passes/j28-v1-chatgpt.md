# Kanto 2026 — J28 : Le dernier Badge de Kanto

> Dossier de conception consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le
> lancement du J28** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages
> verrouillés. Remplace l'avant-projet incomplet `j28-v0-avant-projet.md`. Les images et liens de la
> passe d'origine ne sont pas repris. Notes de la session de coordination à la fin.

Le J28 termine le cycle des huit Arènes avec le retour de Giovanni, cette fois Champion de Jadielle.
Le joueur retrouve une Arène longtemps fermée, résout son puzzle de dalles directionnelles, affronte
des Dresseurs spécialisés et bat Giovanni pour obtenir le Badge Terre. La Route Victoire et les
contrôles d'accès à la Ligue sont réservés au J29.

## 1. Les sept décisions définitives

| Sujet | Arbitrage verrouillé |
|---|---|
| Périmètre | Arène de Jadielle complète ; Route Victoire au J29 |
| Ouverture | Conditions historiques, sans imposer le Badge Marais |
| Puzzle | Dalles directionnelles fidèles à Rouge/Bleu |
| Dresseurs | Équipes historiques, combats évitables selon le parcours |
| Giovanni | Équipe historique Rouge/Bleu à cinq Pokémon |
| Récompenses | Badge Terre + CT27 Abîme |
| Fin | Huitième Badge obtenu, exploration libre |

Règle de continuité : les J26, J27 et J28 sont des unités de développement, pas une obligation de
parcourir les Arènes dans cet ordre.

## 2. Le parcours du joueur

1. **Retour à Jadielle** : l'Arène auparavant fermée est ouverte.
2. **Exploration de l'Arène** : dalles directionnelles, obstacles et Dresseurs.
3. **Giovanni, combat final** : cinq Pokémon, équipe Rouge/Bleu.
4. **Badge Terre + CT27 Abîme** : huitième Badge, exploration libre.

## 3. Ouverture de l'Arène

Dans Rouge/Bleu, l'Arène de Jadielle devient accessible après les événements de la Sylphe SARL.
Kanto 2026 retient :

- la victoire contre Giovanni à la Sylphe SARL comme événement narratif préalable ;
- aucune obligation d'avoir vaincu Morgane ;
- aucune obligation d'avoir le Badge Volcan ;
- une porte qui reste ouverte définitivement une fois la condition remplie.

Le joueur revient à Jadielle quand il le souhaite ; aucun message ne l'y pousse.

## 4. L'Arène de Jadielle

Les dalles transportent le personnage dans une direction jusqu'à une case d'arrêt ou un obstacle.
Le puzzle repose sur leur placement, les murs et les chemins possibles.

| Élément | Comportement |
|---|---|
| Dalle directionnelle | Déplacement automatique selon la direction indiquée |
| Obstacle | Arrêt avant la case bloquée |
| Dalle d'arrêt | Fin du déplacement automatique |
| Entrée de l'Arène | Retour toujours possible |
| Dresseur | Combat selon sa ligne de vue ou interaction |
| Sauvegarde | Position stable et valide au rechargement |

Animation fluide, sans glissement incontrôlable ni perte de précision tactile. Les déplacements
automatiques ne déclenchent jamais de transition de carte ni d'interaction involontaire.

**Plan fonctionnel** : reproduire couloirs, obstacles, Dresseurs et dalles de Rouge/Bleu. Chaque
dalle reçoit une direction, une vitesse et une condition d'arrêt explicites. Le **graphe des
déplacements** doit reproduire le puzzle historique, pas seulement une carte ressemblante.

## 5. Dresseurs de l'Arène

Équipes cohérentes avec Rouge/Bleu (Sol, Poison, Combat). Certains combats sont évitables par les
bons chemins ; les passages contrôlés par des Dresseurs gardent leurs conditions. Chaque Dresseur a
un identifiant persistant, une équipe fixe, un dialogue avant et après combat, et une récompense.
Positions, niveaux et capacités à confronter aux données Rouge/Bleu lors de l'audit.

## 6. Giovanni : dernier Champion

Nouveau combat, distinct de celui de la Sylphe SARL.

| Pokémon | Niveau |
|---|---|
| Rhinocorne | 45 |
| Triopikeur | 42 |
| Nidoqueen | 44 |
| Nidoking | 45 |
| Rhinoféros | 50 |

Récompenses : **Badge Terre** et **CT27 Abîme**. Espèces et niveaux verrouillés ; capacités et IA
adaptées au moteur.

**Après la victoire** : Giovanni reconnaît sa défaite, remet le Badge et la CT27, puis quitte son
rôle de Champion. Départ persistant. Aucun déclenchement automatique de la Route Victoire.

## 7. Dépendances et compatibilité

Références Rouge/Bleu vérifiées par la passe : équipe de Giovanni, Badge Terre, CT27 Abîme. **Ne
pas reprendre la CT26 Séisme des remakes Rouge Feu/Vert Feuille.**

| Dépendance | Origine | Vérification nécessaire |
|---|---|---|
| Jadielle et accès à l'Arène | Cartes antérieures | Entrée, porte, collisions |
| Libération de la Sylphe SARL | J26 | Drapeau de progression |
| Badge Marais | J27 | Ne pas en faire un prérequis |
| Dalles directionnelles | Moteur de déplacement | Déplacements automatiques |
| Giovanni à la Sylphe SARL | J26 | Identité commune, combat distinct |
| Combat à cinq Pokémon | Moteur | Équipes, capacités et IA |
| Abîme | Moteur de combat | Précision et K.O. en un coup |
| Badge Terre | Système de badges | Huitième Badge et obéissance |
| Sauvegarde | Système existant | États et récompenses uniques |
| Route 22 | J29 | Déclenchement du rival final |
| Contrôles des Badges | J29 | Vérification des huit Badges |

**Abîme** : dans Rouge/Bleu, capacité Sol à K.O. en un coup, avec une condition de vitesse et des
règles de précision propres à la première génération. À vérifier dans le moteur avant de livrer la
CT27 : ne pas remettre une capacité inutilisable.

### Persistance

| Identifiant proposé | Fonction |
|---|---|
| `viridian_gym_unlocked` | Porte de l'Arène ouverte |
| `viridian_giovanni_defeated` | Combat final remporté |
| `badge_earth` | Badge Terre obtenu |
| `tm27_received` | CT27 remise |
| `giovanni_disbanded_rocket` | Départ narratif de Giovanni |

Identifiants à aligner sur le dépôt. Chaque Dresseur vaincu garde son état.
`silph_giovanni_defeated` (J26) et `viridian_giovanni_defeated` (J28) sont **deux événements
distincts**.

## 8. Tests et cas limites

| Test | Résultat attendu |
|---|---|
| Entrée avant la libération de la Sylphe SARL | Arène fermée |
| Entrée après J26, sans Badge Marais | Arène ouverte |
| Dalle vers un mur | Arrêt sans traverser le décor |
| Dalles successives | Déplacement déterministe |
| Sauvegarde pendant un déplacement | Reprise sur une case valide |
| Défaite contre Giovanni | Combat disponible au retour |
| Victoire contre Giovanni | Badge et CT remis une seule fois |
| Retour après victoire | Giovanni ne redevient pas Champion |
| Retour à Safrania | États J26 et J27 inchangés |
| Déplacement vers Route 22 | Aucun départ automatique |

Tests avec les contrôles tactiles et les performances du Galaxy S24.

## 9. Découpage technique

| Lot | Livrable |
|---|---|
| 28.0 | Audit du dépôt et des références historiques |
| 28A | Ouverture de l'Arène et plan complet |
| 28B | Dalles directionnelles et collisions |
| 28C | Dresseurs, équipes, dialogues et objets |
| 28D | Giovanni et équilibrage du combat |
| 28E | Badge Terre, CT27 et départ de Giovanni |
| 28F | Sauvegardes, tests et QA Galaxy S24 |

**Critères de fin** : le joueur entre dans l'Arène après la Sylphe SARL, résout le puzzle, bat
Giovanni, reçoit le Badge Terre et la CT27, puis repart librement. Les huit Badges sont reconnus par
la progression, sans ouvrir artificiellement la Route Victoire à qui n'en a pas huit.

## 10. Prompt de transmission à Claude (au lancement du J28)

> **Kanto 2026 — J28 : audit et conception technique.** Prépare le jalon J28, consacré à l'Arène de
> Jadielle et au dernier combat contre Giovanni.
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Arène de Jadielle complète ; Route Victoire
> au J29. 2. Ouverture selon les conditions historiques, sans imposer le Badge Marais. 3. Puzzle de
> dalles directionnelles fidèle à Rouge/Bleu. 4. Équipes historiques des Dresseurs, combats évitables
> selon le parcours. 5. Giovanni : Rhinocorne N45, Triopikeur N42, Nidoqueen N44, Nidoking N45,
> Rhinoféros N50. 6. Récompenses : Badge Terre et CT27 Abîme. 7. Fin : exploration libre, aucune
> transition automatique.
>
> **Audit demandé** : inspecter le dépôt, les jalons antérieurs et les ressources ; vérifier le
> contrat d'entrée depuis le J26 (ouverture après la libération de la Sylphe, sans condition
> artificielle sur les Badges Marais ou Volcan) ; reconstituer le plan historique de l'Arène, les
> dalles, leurs directions, les obstacles, les Dresseurs, les objets et les chemins vers Giovanni ;
> définir une machine à états fiable pour les déplacements automatiques, compatible avec le tactile
> et les sauvegardes ; vérifier les équipes des Dresseurs et les capacités de Giovanni ; contrôler
> les règles d'Abîme dans Rouge/Bleu et leur compatibilité avec le moteur ; préserver la distinction
> entre le Giovanni de la Sylphe et celui de Jadielle ; prévoir le Badge Terre, la CT27, le départ de
> Giovanni et la persistance de tous les événements.
>
> **Livrables** : 1. Contrat d'entrée J26/J27 → J28. 2. Plan ASCII complet de l'Arène. 3. Graphe des
> dalles. 4. Dresseurs, équipes, niveaux, capacités. 5. Combat de Giovanni. 6. Badge Terre et CT27.
> 7. Drapeaux, sauvegardes, états du monde. 8. Assets peints et fonds de combat. 9. Lots 28.0 à 28F.
> 10. Tests automatisés et QA Galaxy S24. 11. Risques et questions ouvertes. Distinguer les
> références Rouge/Bleu, les adaptations validées et ce qui est réellement implémenté. DA 2D HD
> peinte, vue orthogonale, sans pixel art, minimap ni flèches d'objectif.
>
> Conception et audit uniquement. Ne rien coder avant validation.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 28.0

- **Dalles directionnelles** : le J20 a déjà écrit les dalles tournantes (`game/world/spin/`,
  `SpinTileField`, branche `jalon-20`, pour le repaire Rocket). À réutiliser après la fusion du J20 ;
  toute extension (dalle d'arrêt, vitesse) relève de la passe systèmes 2.
- **Badge Terre** : déjà déclaré dans `data/badges.json` (`earth`, drapeau `badge_earth`).
- **CT27** : `data/pokemon/tm_compatibility.json` associe bien la CT27 à `fissure` (pas Séisme).
- **K.O. en un coup** : **pas encore géré par le moteur**. Empal'Korne (`horn_drill`, sur `main`) et
  Guillotine (`jalon-24`) le déclarent en `pending_effects: ["ohko"]` (effet que le moteur ignore
  pour l'instant). Abîme a besoin du même effet. Recommandation : l'implémenter **une fois** dans la
  passe systèmes 2, pour les trois capacités, plutôt que dans le J28.
- **Art** (entre-deux, levier 4) : grille et une vue générale de l'Arène avant le code ; le reste
  (Giovanni Champion, Triopikeur, Nidoking, Rhinoféros, fond de combat) va dans un lot d'art.
