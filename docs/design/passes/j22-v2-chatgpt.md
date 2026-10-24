# J22 — V2 de ChatGPT : « Les deux chemins vers Parmanie »

> Reçue de Kevin le 2026-10-16, recopiée telle quelle (mise en forme Markdown seulement). Elle
> **remplace le périmètre Safrania** du prompt du 2026-10-15
> (`docs/design/prompts/chatgpt-dossier-25-safrania-j22.md`, désormais reporté) et rejoint le
> dossier 24 (J21), qui rangeait déjà « Route 12 sud, Routes 13 à 15, Parmanie » sous le J22.
> Passe d'alignement : `j22-v2-alignement.md`.

---

Kanto 2026 — J22 : Les deux chemins vers Parmanie
Conception V2 · 7 arbitrages validés · Audit du dépôt à effectuer

État d'avancement : J22 est maintenant verrouillé sur le plan de la conception. Il relie les deux itinéraires historiques vers Parmanie, introduit la pêche et rend la bicyclette pleinement utilisable. J23 sera consacré au Parc Safari, aux CS et à l'Arène de Koga.

Notre objectif est clair : le joueur choisit librement sa route vers Parmanie, sans qu'un itinéraire soit obligatoire pour débloquer l'autre.

## 1. Les décisions définitives

| Sujet | Décision J22 |
|---|---|
| Périmètre | Routes 12 à 18 et Parmanie |
| Progression | Deux itinéraires indépendants et complets |
| Pêche | Fonctionnelle, avec les cannes disponibles selon la progression |
| Bicyclette | Utilisable, Piste Cyclable opérationnelle |
| Difficulté | Modérée, nombreux Dresseurs facultatifs |
| Parmanie | Ville et bâtiments principaux ; Safari et Koga réservés à J23 |
| Fin | Exploration libre, aucun événement imposé |

## 2. Deux itinéraires, une destination

**Chemin est : Routes 12 → 13 → 14 → 15.** Un parcours de pêcheurs, passerelles, herbes hautes et Dresseurs. La route doit rester praticable sans vélo, avec des possibilités de pêche et des embranchements facultatifs.

**Chemin ouest : Routes 16 → 17 → 18.** Un trajet à vélo, avec une longue descente, des motards et des zones de repos. La pente doit être sensible dans les déplacements, sans rendre les contrôles tactiles frustrants.

## 3. Les dépendances à sécuriser

| Dépendance | Origine | Contrôle demandé |
|---|---|---|
| Poké Flûte | J21 | Permet de réveiller chaque Ronflex indépendamment |
| Ronflex Route 12 | J21 | Sa disparition ouvre l'accès est |
| Ronflex Route 16 | J21 | Sa disparition ouvre l'accès ouest |
| Bicyclette | Azuria / J13–J15 | Vérifier le Bon Vélo et l'échange du Bon de Commande |
| Pêche | Jalons antérieurs | Vérifier les cannes déjà remises, les rencontres aquatiques et leur compatibilité |
| CS Coupe | J16 | Permet d'accéder à certains espaces annexes, notamment sur Route 16 |
| Safrania | Jalons précédents | Ne pas débloquer ses accès par accident |
| Sauvegarde | Système existant | Préserver l'état des Ronflex, du vélo, des Dresseurs et des objets |

Point historique important : dans Rouge/Bleu, le Bon Vélo est obtenu auprès du président du Fan Club Pokémon à Carmin, puis échangé contre une bicyclette à Azuria. Il faudra vérifier que cette chaîne est réellement présente dans nos jalons antérieurs. Sinon, elle devra être raccordée proprement, sans donner automatiquement le vélo au joueur.

De même, la pêche ne doit pas faire apparaître des Pokémon qui n'ont pas encore leurs données, leurs capacités et leurs illustrations nécessaires.

## 4. Règles de gameplay proposées

| Système | Règle de conception |
|---|---|
| Vélo | Montée/descente volontaire hors Piste Cyclable |
| Piste Cyclable | Bicyclette obligatoire pour entrer ; descente assistée, contrôlable |
| Pêche | Utilisation depuis les berges et quais autorisés |
| Dresseurs | Majoritairement facultatifs, sans couloirs de combats forcés |
| Objets | Visibles ou cachés, persistants après collecte |
| Rencontres | Espèces cohérentes avec chaque route et les données existantes |
| Parmanie | Centre Pokémon, Boutique et bâtiments accessibles |
| Parc Safari | Entrée présente, activité réservée à J23 |
| Arène de Koga | Bâtiment visible, défi réservé à J23 |

Pour la Piste Cyclable, je recommande de ne pas inventer de mini-jeu de course. Le plaisir vient de la descente et de l'exploration, pas d'un chronomètre.

La liberté du joueur est également importante : il peut prendre l'itinéraire est, revenir à Céladon, essayer l'ouest ou explorer Parmanie sans déclencher automatiquement une nouvelle quête.

## 5. Découpage de production J22

| Lot | Livraison |
|---|---|
| 22.0 | Audit des cartes, des objets et des systèmes existants |
| 22A | Routes 12–15, pêcheurs, Dresseurs et rencontres |
| 22B | Bicyclette, Routes 16–18 et Piste Cyclable |
| 22C | Système de pêche et cannes |
| 22D | Parmanie et ses bâtiments principaux |
| 22E | Connexions, sauvegardes et états persistants |
| 22F | QA Galaxy S24 et non-régression |

Critère de réussite : les deux Ronflex ayant été réveillés, le joueur peut atteindre Parmanie par chacun des deux itinéraires, avec les prérequis propres à chacun, puis poursuivre librement son exploration.

## 6. Prompt de transmission à Claude (résumé)

Décisions verrouillées (ne pas les rouvrir) : 1. Routes 12 à 18 complètes et Parmanie accessible. 2. Deux itinéraires indépendants : Routes 12–15 et Routes 16–18. 3. Pêche fonctionnelle dès J22, selon les cannes disponibles. 4. Bicyclette utilisable et Piste Cyclable fonctionnelle. 5. Difficulté modérée, nombreux Dresseurs facultatifs. 6. Parmanie accessible avec ses bâtiments principaux ; Parc Safari et Arène de Koga réservés à J23. 7. Arrivée libre, sans événement narratif forcé.

Audit demandé : cartes et connexions des Routes 12 à 18 ; Poké Flûte et deux Ronflex du J21 et leurs états ; Bon de Commande, Boutique de Vélos d'Azuria, bicyclette ; cannes, donneurs historiques, tables de rencontres ; espèces aquatiques (données, Pokédex, capacités, art) ; règles de la Piste Cyclable ; accès à la maison de la CS02 Vol (Route 16) ; Dresseurs, objets, herbes, bâtiments ; continuité jusqu'à Parmanie ; conflits avec le J23.

Production attendue, en 16 sections : contrat d'entrée J21 → J22 ; dépendances vérifiées et manquantes ; topologie historique ; plans fonctionnels ; vélo et pente ; pêche et cannes ; Dresseurs ; rencontres et espèces nouvelles ; objets ; Parmanie ; dialogues exacts ; drapeaux et cas limites ; art, animations, fonds de combat CB.3 ; découpage 22.0 à 22F ; tests et QA S24 ; questions ouvertes numérotées avec recommandations. Pour chaque mécanique : Rouge/Bleu, génération ultérieure ou adaptation Kanto 2026. DA 2D HD peinte, vue de dessus orthogonale, quatre directions, sans pixel art, isométrie ni minimap. Ne rien coder ; branche documentaire indépendante ; ne jamais supposer qu'un jalon conçu est fusionné ou validé sur appareil ; attendre la validation avant toute implémentation.
