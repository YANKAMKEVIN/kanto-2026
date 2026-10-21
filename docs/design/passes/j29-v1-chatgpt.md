# Kanto 2026 — J29 : La Route Victoire

> Dossier de conception consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le
> lancement du J29** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages
> verrouillés. Remplace l'avant-projet incomplet `j29-v0-avant-projet.md`. Les images et liens de la
> passe d'origine ne sont pas repris. Notes de la session de coordination à la fin.

Dernière grande zone d'exploration avant la Ligue : le retour du rival, le contrôle des huit
Badges, la Route Victoire et la rencontre avec Sulfura.

## 1. Les sept décisions définitives

| Sujet | Décision verrouillée |
|---|---|
| Périmètre | Routes 22 et 23, Route Victoire complète, accès au Plateau Indigo |
| Rival | Combat obligatoire sur la Route 22, équipe évolutive de six Pokémon |
| Badges | Huit contrôles distincts, fidèles à Rouge/Bleu |
| Route Victoire | Donjon complet, plusieurs étages et énigmes historiques de Force |
| Sulfura | Rencontre unique, capturable au niveau 50 |
| Exploration | Pokémon sauvages, Dresseurs et objets historiques |
| Fin | Arrivée libre au Plateau Indigo ; Ligue réservée au J30 |

Décisions définitives pour la conception. Plans exacts, données historiques et état réel du dépôt
restent à auditer.

## 2. Parcours global

Jadielle (départ libre vers l'ouest) → **Route 22** (rival obligatoire) → **Route 23** (huit postes
de contrôle) → **Route Victoire** (donjon, Force, Dresseurs, Sulfura) → **Plateau Indigo** (soins,
préparation, accès à la Ligue).

Le joueur peut toujours rebrousser chemin. Aucune transition automatique ne le fait entrer dans la
Ligue.

## 3. Route 22 : dernier combat contre le rival avant la Ligue

- Combat obligatoire pour valider le passage narratif vers la Ligue.
- Six Pokémon, selon la variante du starter.
- Victoire enregistrée définitivement ; en cas de défaite, le rival reste disponible.
- Aucun changement imposé à l'équipe du joueur après la victoire.

**Vigilance historique** : dans Rouge/Bleu, ce combat n'est pas nécessairement un verrou physique.
Le rendre obligatoire est une **adaptation Kanto 2026 assumée**, à ne pas présenter comme une règle
historique.

**Contrat** : l'équipe du rival est calculée à partir de l'identifiant du **starter initial**,
jamais de l'équipe que porte le joueur. Les trois variantes sont auditées avant de fixer espèces,
niveaux, capacités et IA.

## 4. Route 23 : contrôle des huit Badges

Chaque garde vérifie un Badge précis ; le joueur progresse vers le nord.

| Poste | Badge contrôlé |
|---|---|
| 1 | Roche |
| 2 | Cascade |
| 3 | Foudre |
| 4 | Prisme |
| 5 | Âme |
| 6 | Marais |
| 7 | Volcan |
| 8 | Terre |

- Le contrôle porte sur la **possession** du Badge, pas sur le jalon où il a été développé.
- Un joueur à sept Badges franchit les postes autorisés, est arrêté au contrôle manquant et peut
  revenir sans blocage.
- Portions terrestres et aquatiques historiques ; l'eau demande Surf selon le modèle hybride du J16.

## 5. Route Victoire : donjon complet

Trois niveaux (1F, 2F, 3F), reliés par des escaliers et des passages internes.

| Élément | Fonction |
|---|---|
| Rochers de Force | À pousser sur des cases autorisées |
| Interrupteurs | Activés par certains rochers |
| Barrières | Ouvertes lorsque les conditions sont réunies |
| Escaliers | Connexions entre les niveaux |
| Dresseurs | Combats selon les lignes de vue |
| Pokémon sauvages | Rencontres selon la zone |
| Objets | Ressources et capacités historiques |
| Sulfura | Rencontre légendaire fixe |

**Force (modèle hybride du J16)** : utilisable sur le terrain si un Pokémon compatible est dans
l'équipe, que la CS est possédée et que le Badge Prisme est obtenu. Pas besoin de l'apprendre comme
capacité de combat.

**Prévention des blocages** : distinguer les rochers mobiles (réinitialisables au retour sur la
carte) et les événements permanents (qui survivent à la sauvegarde). L'audit vérifie le
comportement historique des rochers et interrupteurs avant de fixer ce qui persiste. Un rocher ne
doit **jamais** pouvoir rendre la sortie définitivement inaccessible.

## 6. Sulfura : rencontre légendaire

Niveau 50, rencontre fixe, unique, capturable, sans cinématique obligatoire.

- Le combat démarre par interaction.
- Capturé ou mis K.O. : rencontre consommée.
- Joueur vaincu ou fuite : même politique que pour Artikodin au J24, après audit.
- La Master Ball du J26 est utilisable contre Sulfura, sans être nécessaire.
- La sauvegarde empêche toute duplication et préserve l'état de la rencontre.

## 7. Plateau Indigo : zone de préparation

Le J29 comprend l'arrivée au Plateau Indigo, pas les combats de la Ligue : Centre Pokémon, services
de préparation de Rouge/Bleu, PNJ d'accueil, entrée vers le Conseil des Quatre. L'entrée reste sous
le contrôle du joueur : aucun dialogue, soin ou déplacement ne lance le premier combat.

## 8. Dépendances J16–J28 → J29

Revue des contrats de conception (pas encore des fichiers du dépôt).

| Dépendance | Jalon d'origine | Résultat |
|---|---|---|
| Route 22 et raccord à Jadielle | Cartographie antérieure | À raccorder et auditer |
| Rival évolutif selon starter | Combats précédents, J26 | Réutiliser les trois variantes |
| Huit Badges | J28 et antérieurs | Vérifier les huit identifiants |
| Surf | J23 / J16 | CS possédée + Pokémon compatible + Badge Âme |
| Force | J23 / J16 | CS possédée + Pokémon compatible + Badge Prisme |
| Puzzles à rochers | J24 | Réutiliser la logique, adapter les interrupteurs |
| Rencontres légendaires | J24, Artikodin | Réutiliser la politique de sauvegarde |
| Master Ball | J26 | Compatible avec Sulfura |
| Transitions multiétages | J24–J26 | Réutiliser le système existant |
| Soins et stockage | Systèmes antérieurs | Fonctionnels au Plateau Indigo |
| Accès au Conseil des Quatre | J30 | Entrée préparée, combats non livrés |

**Trois points de vigilance** :

1. Les Badges ne sont pas forcément obtenus dans l'ordre des jalons : les gardes consultent
   l'inventaire réel des Badges.
2. Les rochers ne sont pas persistés aveuglément : états sûrs, réinitialisations cohérentes, tests
   de retour.
3. La Route 22 a plusieurs états narratifs : le combat tardif ne doit ni effacer ni réactiver la
   rencontre antérieure déjà développée sur cette route.

## 9. Drapeaux et sauvegardes

| Identifiant proposé | Rôle |
|---|---|
| `route22_final_rival_defeated` | Rival vaincu avant la Ligue |
| `route23_checkpoint_progress` | Dernier contrôle franchi, si nécessaire |
| `victory_road_puzzle_states` | États sûrs des énigmes |
| `victory_road_trainers_defeated` | Dresseurs vaincus |
| `moltres_encounter_resolved` | Rencontre Sulfura consommée |
| `moltres_captured` | Sulfura capturé |
| `indigo_plateau_discovered` | Plateau Indigo atteint |

Noms provisoires, à aligner sur les conventions du projet. Les huit Badges restent la source de
vérité des gardes : `route23_checkpoint_progress` ne remplace pas leur vérification.

## 10. Découpage technique

| Lot | Livraison |
|---|---|
| 29.0 | Audit du dépôt, cartes historiques et dépendances |
| 29A | Route 22, rival et états narratifs |
| 29B | Route 23, huit gardes et traversées Surf |
| 29C | Route Victoire : trois étages et transitions |
| 29D | Rochers, Force, interrupteurs et barrières |
| 29E | Dresseurs, rencontres, objets et Sulfura |
| 29F | Plateau Indigo, sauvegardes et QA Galaxy S24 |

**Tests d'acceptation** : rival à six Pokémon dans la bonne variante ; chaque garde vérifie le bon
Badge ; un Badge manquant ne bloque que son poste ; Surf et Force respectent le modèle hybride ;
tous les puzzles de Force restent résolubles après retour, sauvegarde ou rechargement ; Sulfura
capturable et non duplicable ; Dresseurs vaincus et objets ramassés enregistrés ; Plateau Indigo
accessible après la Route Victoire ; la Ligue ne démarre jamais automatiquement ; rien ne bloque la
navigation tactile sur Galaxy S24.

**« J29 terminé »** : le joueur traverse les Routes 22 et 23, réussit la Route Victoire, rencontre
Sulfura et arrive librement au Plateau Indigo avec les huit Badges.

## 11. Prompt de transmission à Claude (au lancement du J29)

> **Kanto 2026 — J29 : audit et conception technique.** Prépare le J29 : Routes 22 et 23, Route
> Victoire complète, Sulfura et accès au Plateau Indigo.
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Routes 22 et 23 + Route Victoire complète +
> Plateau Indigo. 2. Rival obligatoire sur la Route 22, équipe évolutive de six Pokémon. 3. Huit
> contrôles de Badges distincts, fidèles à Rouge/Bleu. 4. Route Victoire complète avec étages et
> énigmes historiques de Force. 5. Sulfura : rencontre légendaire unique, capturable au niveau 50.
> 6. Rencontres sauvages, Dresseurs et objets historiques. 7. Arrivée libre au Plateau Indigo ;
> Ligue réservée au J30.
>
> **Audit demandé** : inspecter le dépôt, les cartes et les contrats J16–J28 en distinguant
> l'implémenté, le décidé et l'absent ; reconstituer les plans historiques des Routes 22 et 23 et des
> trois étages de la Route Victoire ; vérifier les variantes du rival selon le starter et les
> événements antérieurs de la Route 22 ; documenter les huit contrôles, les coordonnées des gardes et
> les transitions aquatiques ; reconstituer les puzzles de Force (rochers, destinations,
> interrupteurs, barrières, escaliers, chemins) et **prouver l'absence de blocage définitif** ;
> préserver le modèle hybride du J16 (Surf : CS + Pokémon compatible + Badge Âme ; Force : CS +
> Pokémon compatible + Badge Prisme ; aucun apprentissage obligatoire) ; auditer Dresseurs, équipes,
> Pokémon sauvages et objets ; prévoir Sulfura N50, sa capture, sa consommation unique et la Master
> Ball, avec la politique d'Artikodin du J24 après fuite ou défaite ; préparer le Plateau Indigo et
> l'entrée de la Ligue sans les combats du J30.
>
> **Livrables** : 1. Contrat d'entrée J28 → J29. 2. Plans ASCII détaillés. 3. Graphe des transitions
> et chemins. 4. Rival et trois variantes. 5. Huit contrôles de Badges. 6. Tables de rencontres et
> Dresseurs. 7. Énigmes de Force et preuve de résolubilité. 8. Objets et récompenses. 9. Sulfura et
> règles de capture. 10. Plateau Indigo. 11. Drapeaux et sauvegardes. 12. Assets 2D HD peints et
> fonds de combat. 13. Lots 29.0 à 29F. 14. Tests automatisés et QA Galaxy S24. 15. Risques et
> questions ouvertes. Pour chaque élément : référence Rouge/Bleu, adaptation Kanto 2026, état réel du
> code. Vue orthogonale 2D HD peinte, sans pixel art, isométrie, minimap ni flèches d'objectif.
>
> Conception et audit uniquement. Ne rien coder avant validation.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 29.0

- **Rival** : `data/trainers/rival.json` calcule déjà les équipes par starter (`team_by_starter`).
  Il existe **déjà** une entrée `rival_route22` (rival n° 2, J7B) : le combat du J29 doit avoir son
  propre identifiant (par exemple `rival_route22_final`) pour ne pas réactiver ni effacer l'ancien
  (vigilance n° 3).
- **Politique d'Artikodin** (`jalon-24`, plan §2.7) : capture → `articuno_done` + `articuno_caught` ;
  K.O. → `articuno_done` ; **fuite et défaite → rien** (le légendaire reste là) ; sauvegarde forcée à
  la sortie du combat. Sulfura peut la reprendre telle quelle (`moltres_done`, `moltres_caught`).
- **Force, rochers, trous** : logique pure déjà écrite sur `jalon-24` (`BoulderRules`), dans le
  périmètre de la passe systèmes 2. Les **interrupteurs** et **barrières** de la Route Victoire sont
  un ajout : à prévoir dans la passe systèmes 2 avec la Force, plutôt qu'au J29.
- **Huit Badges** : tous déclarés dans `data/badges.json` avec leurs drapeaux (`badge_*`).
- **Nuance historique à vérifier par l'audit** : dans Rouge/Bleu, il semble que le contrôle du Badge
  Roche soit au poste de la Route 22, et les sept autres sur la Route 23. Si c'est confirmé, le
  dossier (huit postes sur la Route 23) est une adaptation, à signaler à Kevin plutôt qu'à corriger
  d'office.
