# Kanto 2026 — J31 : La Grotte Inconnue et Mewtwo

> Dossier de conception consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le
> lancement du J31** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages
> verrouillés. Remplace l'avant-projet incomplet `j31-v0-avant-projet.md`. Les images de la passe
> d'origine ne sont pas reprises. Notes de la session de coordination à la fin.

Après la victoire à la Ligue, le joueur accède au dernier grand donjon de Kanto : la Grotte
Inconnue, près d'Azuria, où l'attend Mewtwo au niveau 70. Un vrai défi post-game, sans nouvelle
histoire linéaire imposée.

## 1. Les sept décisions définitives

| Sujet | Décision verrouillée |
|---|---|
| Périmètre | Grotte Inconnue complète, Mewtwo et exploration post-Ligue |
| Accès | Victoire à la Ligue obligatoire, entrée près d'Azuria |
| Structure | Donjon historique à plusieurs niveaux avec Surf |
| Mewtwo | Rencontre unique, capturable au niveau 70 |
| Exploration | Pokémon sauvages de haut niveau et objets historiques |
| Activités | Pokédex, revisites, Ligue rejouable et exploration libre |
| Fin | Sauvegarde persistante, aucune nouvelle fin obligatoire |

Décisions consolidées avec les contrats J16–J30 ; conformité technique à auditer.

## 2. Parcours du joueur

Victoire à la Ligue (Panthéon et générique terminés) → retour à Azuria (exploration libre) →
entrée de la grotte (réservée au Champion) → **Grotte Inconnue** (Surf, labyrinthes, objets,
rencontres) → **Mewtwo N70** (combat légendaire, capture possible) → Kanto post-game (retour libre,
Pokédex, Ligue rejouable).

Le joueur n'est pas téléporté à Azuria après le générique : il découvre lui-même que la grotte est
accessible.

## 3. Déverrouillage de la Grotte Inconnue

Condition : **première victoire contre le Champion de la Ligue**.

| État du joueur | Accès |
|---|---|
| Sept Badges | Refusé |
| Huit Badges, Ligue non terminée | Refusé |
| Conseil des Quatre vaincu, rival non vaincu | Refusé |
| Champion vaincu et victoire enregistrée | Autorisé |
| Nouvelle session après le générique | Autorisé définitivement |

- Vérification fondée sur l'état permanent `league_first_clear_completed` du J30 (ou son équivalent
  réel), jamais sur un compteur de Badges ni sur la présence de Mewtwo dans le Pokédex.
- **Accès géographique** : au nord-ouest d'Azuria, par les voies d'eau et les berges historiques.
  Surf nécessaire selon la configuration retenue, avec le modèle hybride du J16 (CS possédée,
  Pokémon compatible, Badge Âme, sans apprentissage obligatoire).

## 4. Structure du donjon

| Niveau | Fonction |
|---|---|
| 1F | Entrée, eau, passages, échelles et embranchements |
| 2F | Labyrinthe supérieur, objets et chemins secondaires |
| B1F | Parcours final et emplacement de Mewtwo |

- Plan relevé sur **Rouge/Bleu**, pas sur Rouge Feu/Vert Feuille (disposition différente).
- Exploration libre, Surf sur l'eau, échelles, retour vers l'entrée toujours possible.
- Ni minimap, ni flèches d'objectif, ni téléportation automatique vers Mewtwo. La lisibilité repose
  sur les volumes peints, les contours des passages, les échelles et les contrastes du sol.
- **DA** : grotte mystérieuse mais lisible. Roches gris-bleu, bassins sombres, reflets froids,
  cavités profondes, éclairage diffus. Plus étrange que la Route Victoire, sans basculer dans la
  science-fiction. Style peint HD orthogonal déjà validé.

## 5. Pokémon sauvages et objets

- Pokémon de haut niveau pour un joueur qui a fini la Ligue. Tables de rencontres Rouge/Bleu par
  étage (taux et niveaux) à reprendre et à confronter au système de rencontres existant.
- Pokémon rares, objets de soin, ressources et objets cachés placés selon la référence historique.
- Les sauvages ordinaires réapparaissent selon le moteur ; les objets ramassés restent consommés.
- Aucun objet historique important remplacé par une récompense inventée sans arbitrage.

## 6. Mewtwo — rencontre finale du post-game

Niveau 70, légendaire, rencontre fixe, capture unique. Au fond de la grotte ; n'apparaît pas sur la
carte du monde et ne se déplace pas.

| Situation | Comportement |
|---|---|
| Première interaction | Déclenche le combat |
| Capture réussie | Mewtwo rejoint l'équipe ou le stockage |
| Mise K.O. | Rencontre consommée selon la règle historique retenue |
| Fuite | Politique à aligner sur les légendaires J24/J29 |
| Défaite du joueur | Retour selon le système général |
| Retour après capture | Mewtwo absent |
| Rechargement | Aucun doublon possible |

Objectif : **un seul comportement** pour Artikodin, Sulfura et Mewtwo, pas trois.

**Capacités de référence (Rouge/Bleu, N70)** :

| Capacité | Fonction |
|---|---|
| Psyko | Attaque Psy principale |
| Soin | Récupération de PV |
| Météores | Attaque ne ratant normalement pas |
| Bouclier | Augmentation de la Défense |

Noms, effets et règles de première génération à vérifier dans les données de référence.

**Continuité avec le J25** : les journaux du Manoir évoquaient Mewtwo sans le montrer ; le J31
concrétise cette intrigue environnementale. Aucune cinématique explicative obligatoire.

## 7. Dépendances J16–J30 → J31

| Dépendance | Origine | Exigence J31 |
|---|---|---|
| Victoire contre la Ligue | J30 | Déverrouillage permanent de la grotte |
| Retour libre dans Kanto | J30 | Azuria accessible après le générique |
| Surf hybride | J16 / J23 | Utilisation sans apprentissage obligatoire |
| Navigation aquatique | J23 / J24 | Collisions et transitions correctes |
| Donjons multiétages | J24 / J29 | Échelles, coordonnées, chargement |
| Artikodin | J24 | Politique de rencontre légendaire |
| Journaux du Manoir | J25 | Cohérence narrative de Mewtwo |
| Master Ball | J26 | Capture possible avec l'objet |
| Sulfura | J29 | Même contrat de sauvegarde légendaire |
| Ligue rejouable | J30 | Aucun conflit avec les entrées du Panthéon |
| Pokédex et stockage | Systèmes existants | Enregistrement de Mewtwo |

**Vérifications prioritaires** :

- **Accès** : le statut de Champion est une donnée persistante, distincte de la tentative de Ligue.
- **Sauvegarde** : la capture met à jour de façon cohérente le combat, le Pokédex, l'équipe ou le
  stockage, et le drapeau de rencontre ; une interruption ne permet aucune duplication.
- **Navigation** : tous les chemins accessibles avec les capacités déjà obtenues, sans nouvelle CS
  ni nouveau Badge.
- **Référence historique** : plans, rencontres et objets relevés dans Rouge/Bleu ; ne pas mélanger
  silencieusement Jaune et les remakes.

## 8. États persistants proposés

| Identifiant | Fonction |
|---|---|
| `cerulean_cave_unlocked` | Accès autorisé après la Ligue |
| `cerulean_cave_discovered` | Grotte visitée |
| `cerulean_cave_items_collected` | Objets récupérés |
| `mewtwo_encounter_resolved` | Rencontre consommée |
| `mewtwo_captured` | Capture effectuée |
| `postgame_unlocked` | État permanent hérité du J30 |

`cerulean_cave_unlocked` peut être **calculé** depuis `league_first_clear_completed` plutôt que
sauvegardé, pour éviter les contradictions. La possession de Mewtwo a pour source de vérité le
système Pokémon/stockage, avec un état de rencontre distinct.

## 9. Découpage technique

| Lot | Livrable |
|---|---|
| 31.0 | Audit du dépôt, cartes et données historiques |
| 31A | Accès depuis Azuria et condition post-Ligue |
| 31B | Trois niveaux de la Grotte Inconnue |
| 31C | Surf, échelles, collisions et transitions |
| 31D | Rencontres sauvages, objets et ambiance |
| 31E | Mewtwo, capture et persistance |
| 31F | Rejouabilité, sauvegardes et QA Galaxy S24 |

| Scénario | Résultat attendu |
|---|---|
| Huit Badges sans victoire à la Ligue | Accès refusé |
| Première victoire à la Ligue | Accès déverrouillé |
| Rechargement après générique | Grotte toujours accessible |
| Surf sans CS possédée | Impossible |
| Surf avec CS, Badge et Pokémon compatible | Possible |
| Entrée et sortie de chaque étage | Coordonnées correctes |
| Objet ramassé puis rechargement | Objet absent |
| Capture de Mewtwo avec une Hyper Ball | Capture possible selon les règles |
| Capture avec Master Ball | Capture garantie selon le système existant |
| Mewtwo envoyé au stockage | Pokémon conservé |
| Retour après capture | Mewtwo absent |
| Nouvelle victoire à la Ligue | Aucun reset de Mewtwo |
| Application interrompue pendant le combat | Reprise cohérente, sans duplication |

Validation mobile : commandes tactiles, animations de Surf, stabilité des transitions, reprise
Android.

**« J31 terminé »** : après la Ligue, le joueur atteint et explore toute la Grotte Inconnue,
rencontre Mewtwo, tente de le capturer et poursuit librement son aventure.

## 10. Prompt de transmission à Claude (au lancement du J31)

> **Kanto 2026 — J31 : audit et conception technique.** Prépare le J31 : la Grotte Inconnue, Mewtwo
> et l'exploration post-Ligue.
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Grotte Inconnue complète, Mewtwo et
> exploration post-Ligue. 2. Victoire à la Ligue obligatoire, entrée près d'Azuria. 3. Donjon fidèle
> à Rouge/Bleu : 1F, 2F, B1F, Surf et échelles. 4. Mewtwo : rencontre unique, capturable au niveau
> 70. 5. Pokémon sauvages de haut niveau et objets historiques. 6. Pokédex, revisites, Ligue
> rejouable et exploration libre. 7. Sauvegarde persistante, aucune nouvelle fin imposée.
>
> **Audit obligatoire** : inspecter le dépôt, les ressources, les cartes et les jalons J16–J30, en
> distinguant explicitement : implémenté et vérifié ; présent mais incomplet ; seulement spécifié ;
> absent. Dépendances : J30 (victoire à la Ligue, retour libre, déverrouillage post-game) ; J16/J23
> (Surf hybride) ; J24/J29 (donjons, transitions, rencontres légendaires) ; J25 (journaux du Manoir) ;
> J26 (Master Ball) ; systèmes existants (Pokédex, stockage, objets, sauvegardes).
>
> **Conception** : 1. Plans exacts Rouge/Bleu de la Grotte Inconnue (1F, 2F, B1F). 2. Connexions,
> zones de Surf, échelles, collisions, sorties. 3. Rencontres, niveaux, taux, objets et objets
> cachés par étage. 4. Contrôle d'accès post-Ligue indépendant du nombre de Badges. 5. Mewtwo N70 :
> emplacement, sprite, capacités historiques, IA, combat, capture. 6. Fuite, défaite, K.O. et
> capture alignés sur Artikodin et Sulfura. 7. Aucune duplication de Mewtwo, même après fermeture
> Android ou rechargement. 8. Retour libre dans Kanto et Ligue rejouable préservés. 9. Pokédex et
> stockage enregistrent Mewtwo. 10. Assets 2D HD peints et ambiance sonore du donjon.
>
> **Livrables** : contrat J30 → J31 ; plans ASCII par étage ; graphe des transitions ; tables de
> rencontres et d'objets vérifiées ; contrat de rencontre de Mewtwo ; machine à états de capture et
> de sauvegarde ; drapeaux persistants ; liste des assets ; lots 31.0 à 31F ; tests automatisés et QA
> Galaxy S24 ; risques, écarts historiques et questions ouvertes. DA 2D HD peinte, vue orthogonale,
> sans pixel art, isométrie, minimap ni flèches d'objectif. Dialogues courts et lisibles sur mobile.
>
> Ne rien coder avant validation. Fournir un audit technique exploitable, avec chemins de fichiers
> réels et dépendances vérifiées.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 31.0

- **Mewtwo** : l'espèce n'existe pas encore dans `data/pokemon/species/` (les espèces sont ajoutées
  jalon par jalon). Les capacités de référence du dossier (Psyko, Soin, Météores, Bouclier)
  correspondent aux quatre dernières apprises au niveau 70 dans Rouge/Bleu d'après la session, à
  confirmer par l'audit.
- **Grotte Inconnue** : aucune carte ni grille trouvée ; l'entrée côté Azuria (J13) est à vérifier.
- **Politique légendaire unique** : la règle d'Artikodin (`jalon-24`, plan §2.7 : capture ou K.O. →
  rencontre consommée ; fuite ou défaite → rien) peut servir telle quelle pour Sulfura (J29) et
  Mewtwo (J31). Une seule implémentation, trois données.
