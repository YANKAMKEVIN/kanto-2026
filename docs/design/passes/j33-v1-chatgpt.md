# Kanto 2026 — J33 : Stabilisation globale et version de référence

> Dossier de conception V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le lancement du
> J33** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages verrouillés.
> Remplace l'avant-projet incomplet `j33-v0-avant-projet.md`. Les images de la passe d'origine ne
> sont pas reprises. Notes de la session de coordination à la fin.

On passe d'un développement par zones à une **qualité globale** : vérifier que toute l'aventure, du
Bourg Palette à Mewtwo, est cohérente, stable et agréable sur Android. Plus d'ajout de contenu : une
version de référence testable sur Galaxy S24, avec preuves de validation et liste claire des
problèmes restants.

## 1. Les sept décisions définitives

| # | Domaine | Décision verrouillée |
|---|---|---|
| 1 | Périmètre | Stabilisation complète J0–J32, sans nouvelle région |
| 2 | Direction artistique | Harmonisation des cartes, personnages, animations et combats en 2D HD peinte |
| 3 | Expérience tactile | Audit intégral des commandes, dialogues, menus, combats et accessibilité |
| 4 | Performances | Optimisation mémoire, chargements, fluidité et batterie Android |
| 5 | Sauvegardes | Migrations, interruptions Android, reprise et récupération après crash |
| 6 | Progression | Tests automatisés et manuels de toute l'aventure et du post-game |
| 7 | Livraison | APK de test versionné, rapport QA et registre des anomalies |

Contrat du J33 : **aucun ajout fonctionnel majeur** accepté simplement parce qu'il serait
intéressant.

## 2. Architecture de la validation

Toutes les fonctionnalités J0–J32, vérifiées selon six axes : **Visuel** (cartes, sprites,
animations), **UX mobile** (tactile, lisibilité, navigation), **Technique** (FPS, mémoire,
batterie), **Fiabilité** (sauvegardes, états, reprises), **Progression** (scénario et post-game),
**Collection** (Pokédex et stockage). Sortie : **APK de test + rapport QA** (version identifiable,
anomalies classées, tests reproductibles).

## 3. Audit visuel et direction artistique

DA inchangée : 2D HD peinte, vue orthogonale de dessus, sans pixel art ni isométrie.

| Élément | Contrôle J33 |
|---|---|
| Sols et chemins | Échelle et raccords cohérents |
| Bâtiments | Proportions, entrées, collisions |
| Personnages | Taille, silhouette, ombres et animations |
| Pokémon | Fidélité des formes et homogénéité du rendu |
| Eau | Surf, bords, transitions et profondeur visuelle |
| Donjons | Contrastes, obstacles et lisibilité |
| Combats | Fonds, sprites, effets et interface |
| Menus | Typographie, icônes et hiérarchie visuelle |

**Règles non négociables** :

- Base proche de 1 case = 1 mètre ; fenêtre de jeu cible d'environ 24 × 11 cases, à confronter au
  viewport réellement configuré.
- Pas de minimap, pas de flèches d'objectif, pas d'effets lumineux envahissants.
- Dialogues courts : deux lignes maximum, environ 40 caractères par ligne selon la place.
- Les corrections visuelles ne déplacent jamais silencieusement collisions, déclencheurs de combat
  ou coordonnées d'événements.

## 4. Expérience tactile Galaxy S24

Galaxy S24 = appareil de référence, sans exclure d'autres résolutions Android.

| Contexte | Commandes à auditer |
|---|---|
| Exploration | Déplacement, interaction, Surf, Force, escaliers, portes |
| Combat | Attaques, Sac, Pokémon, fuite, confirmation |
| Menus | Pokédex, équipe, stockage, options |
| Reprise | Pause, arrière-plan, retour au jeu, chargement |

Contrôler les zones tactiles trop petites, les appuis involontaires, les commandes simultanées et la
lisibilité. **Attention particulière** aux systèmes où le joueur perd temporairement le contrôle :
dalles de l'Arène de Jadielle, courants des Îles Écume, puzzles de Force de la Route Victoire.

## 5. Performances et budget technique

Pas de chiffres annoncés sans exécution : objectifs de validation, ajustés après profilage.

| Indicateur | Cible initiale |
|---|---|
| Fluidité en exploration | 60 FPS visés sur Galaxy S24 |
| Combats | Animations fluides, sans saccades visibles |
| Chargement de carte | Pas de gel prolongé de l'interface |
| Mémoire | Pas de croissance continue lors des changements de zone |
| Batterie | Consommation mesurée sur session prolongée |
| Température | Pas de dégradation majeure après une session longue |
| Application en arrière-plan | Reprise sans corruption ni perte anormale |

Profilage séparé : cartes extérieures, villes, grands donjons, combats, menus de stockage.
Optimisations sans sacrifier la qualité peinte : chargement maîtrisé, ressources partagées,
dimensionnement des textures, suppression des traitements inutiles.

## 6. Sauvegardes : le chantier le plus critique

Une sauvegarde corrompue après des dizaines d'heures est bien plus grave qu'un défaut d'animation.

| Scénario | Résultat attendu |
|---|---|
| Fermeture normale | Progression conservée |
| Passage en arrière-plan | Reprise sûre |
| Fermeture forcée | Dernier état validé récupérable |
| Mise à jour du jeu | Sauvegarde ancienne migrée |
| Combat interrompu | Aucun Pokémon ou objet dupliqué |
| Évolution interrompue | Opération entièrement validée ou annulée |
| Capture légendaire | Rencontre et stockage synchronisés |
| Changement de carte | Position valide au rechargement |
| Panthéon | Historique des victoires conservé |
| Stockage plein | Aucune perte silencieuse de Pokémon |

**Architecture recommandée** : version de schéma, écriture atomique, validation au chargement, copie
de secours ; migrations incrémentales sans perte d'information historique. Une sauvegarde valide
conserve Badges, Pokémon, objets, événements uniques, états des donjons, Panthéon et Pokédex.
**Vérifier ce qui existe déjà avant d'ajouter une couche.**

## 7. Campagne de tests de bout en bout

**Parcours de référence** : 01 début (starter, premières routes, première Arène) ; 02 progression
(villes, Arènes, rival, Team Rocket, CS) ; 03 donjons et légendaires (Îles Écume, Manoir, Sylphe
SARL, Route Victoire) ; 04 Ligue (Conseil des Quatre, Champion, Panthéon) ; 05 post-game (Grotte
Inconnue, Mewtwo, Ligue rejouable) ; 06 collection (Pokédex, évolutions, stockage, secrets).

Trois niveaux : tests unitaires des règles, tests d'intégration des transitions et sauvegardes,
parcours réels sur téléphone.

**Scénarios prioritaires** : finir l'aventure sans commande de débogage ; faire les Arènes dans les
ordres autorisés ; utiliser les CS selon le modèle hybride du J16 ; résoudre les puzzles sans
blocage définitif ; perdre puis recommencer un combat important ; capturer un légendaire et vérifier
sa persistance ; finir la Ligue, revoir le générique, rejouer la Ligue ; charger une sauvegarde
antérieure aux derniers jalons ; faire les évolutions locales et vérifier la complétion du Pokédex.
Parcours complet testé **avec plusieurs starters** (équipes du rival).

## 8. Dépendances J0–J32 et politique de correction

| Système | Jalons concernés | Risque principal |
|---|---|---|
| Cartes et transitions | Tous | Mauvaises coordonnées ou sorties |
| Déplacements automatiques | J24, J28 | Collisions et contrôle tactile |
| CS hybrides | J16, J23, J29, J31 | Conditions contradictoires |
| Événements uniques | J24–J31 | Duplication ou réapparition |
| Équipes du rival | J26, J29, J30 | Mauvaise variante de starter |
| Huit Badges | J28–J30 | Progression incohérente |
| Ligue et Panthéon | J30 | Tentative et victoire permanente confondues |
| Mewtwo | J25, J31 | Incohérence narrative ou sauvegarde |
| Collection complète | J32 | Espèce impossible à obtenir |
| Stockage | Tous | Perte ou duplication de Pokémon |
| Compatibilité des sauvegardes | Tous | Régression après mise à jour |

| Priorité | Définition |
|---|---|
| **P0 — Bloquant** (livraison interdite) | Crash systématique, sauvegarde corrompue, perte de Pokémon, progression impossible |
| **P1 — Majeur** | Combat ou fonctionnalité essentielle incorrecte, collision empêchant une activité importante, baisse sévère de performances |
| **P2 — Modéré** | Défaut visuel, comportement secondaire incorrect, gêne tactile sans blocage |
| **P3 — Mineur** | Finition cosmétique, détail sonore, amélioration non essentielle |

Version de référence acceptée avec **zéro P0 et zéro P1 ouverts** ; P2/P3 documentées,
reproductibles et explicitement acceptées.

## 9. Découpage technique

| Lot | Livrable |
|---|---|
| 33.0 | Inventaire réel du dépôt, état des jalons et baseline QA |
| 33A | Harmonisation visuelle et cohérence des assets |
| 33B | UX tactile, menus, combats et accessibilité |
| 33C | Profilage et optimisations Android |
| 33D | Sauvegardes, migrations et reprise après interruption |
| 33E | Tests complets J0–J32 et corrections de progression |
| 33F | APK versionné, rapport QA, registre des anomalies et décision de livraison |

Ordre : 33.0 → (33A, 33B, 33C en partie en parallèle) → 33D → 33E → 33F. La validation finale
s'exécute sur un ensemble de modifications stabilisé.

## 10. Livrables et critères de sortie

Dossier de livraison : APK installable, commit Git exact, version de Godot, paramètres d'export
Android, résultats de tests, métriques de performance, registre des anomalies.

**« J33 terminé »** seulement si : 1. l'APK est généré et installé sur Galaxy S24 ; 2. les parcours
critiques de l'aventure et du post-game sont validés ; 3. les sauvegardes anciennes et nouvelles
fonctionnent ; 4. aucune régression bloquante sur J0–J32 ; 5. aucun P0/P1 n'empêche la livraison ;
6. le rapport QA et les limitations connues sont disponibles. **Une APK compilée ne prouve pas à
elle seule que le J33 est terminé.**

## 11. Prompt de transmission à Claude (au lancement du J33)

> **Kanto 2026 — J33 : stabilisation globale et APK de référence.** Prépare le J33, consacré à la
> stabilisation de Kanto 2026, de J0 à J32.
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Stabilisation globale J0–J32, sans nouvelle
> région. 2. Harmonisation de toutes les cartes, personnages, animations et combats en 2D HD peinte.
> 3. Audit complet des commandes tactiles, dialogues, menus, combats et accessibilité sur Galaxy S24.
> 4. Optimisation de la mémoire, des chargements, de la fluidité et de la batterie Android. 5. Tests
> des sauvegardes anciennes, migrations, interruptions Android et récupération après crash.
> 6. Parcours automatisés et manuels de toute l'aventure, post-game compris. 7. APK de test
> versionné, rapport QA et liste des anomalies restantes.
>
> **Phase 1 — Audit réel du dépôt** : branche active, projet Godot, scènes, ressources, scripts,
> données, tests ; version de Godot, export Android, stratégie de sauvegarde, conventions, état réel
> des jalons J0–J32. Classer chaque fonctionnalité : implémentée et vérifiée ; présente mais
> incomplète ; spécifiée mais absente ; non vérifiable. N'inventer aucun fichier, commit, test ou
> résultat de performance.
> **Phase 2 — Audit visuel** : homogénéité des assets peints, personnages, Pokémon, cartes, combats,
> animations, interfaces ; vue orthogonale 2D HD peinte, sans pixel art, isométrie, minimap ni
> flèches ; ne pas modifier collisions ou coordonnées sans tests de régression.
> **Phase 3 — Audit mobile** : commandes tactiles, zones d'interaction, dialogues courts, menus,
> combats, transitions, Surf, Force, déplacements automatiques ; matrice QA Galaxy S24.
> **Phase 4 — Performances** : baseline mesurable (FPS, mémoire, chargements, stabilité,
> consommation, session longue) ; optimisations à fort impact sans dégrader la DA.
> **Phase 5 — Sauvegardes** : écritures atomiques, version des données, migrations, sauvegardes de
> secours, validation au chargement, reprise Android ; événements uniques, légendaires, échanges,
> évolutions, stockage, Badges, objets, Panthéon.
> **Phase 6 — Progression et régressions** : parcours du Bourg Palette à Mewtwo avec variantes de
> starters, combats, puzzles, CS hybrides, Ligue et collection ; tests unitaires, d'intégration et
> manuels ; anomalies classées P0 à P3 ; bloquer la livraison si un P0 ou un P1 reste ouvert.
>
> **Livrables** : 1. Rapport d'audit factuel avec chemins de fichiers. 2. Inventaire des
> fonctionnalités et dépendances J0–J32. 3. Baseline visuelle et technique. 4. Plan d'harmonisation
> artistique. 5. Audit UX tactile Galaxy S24. 6. Plan de profilage et d'optimisation. 7. Contrat de
> sauvegarde et de migration. 8. Matrice de tests de bout en bout. 9. Registre des risques et
> anomalies. 10. Lots 33.0 à 33F avec ordre de réalisation. 11. Critères de validation de l'APK.
> 12. Plan de transmission à Codex. Distinguer décisions de conception, faits vérifiés dans le dépôt
> et recommandations nouvelles.
>
> Conception et audit uniquement. Ne rien coder avant validation. Ne pas prétendre avoir généré ou
> testé un APK si ce n'est pas réellement le cas.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 33.0

**Sauvegardes (§6) : une bonne partie existe déjà** (`game/systems/save/save_system.gd`, depuis le
jalon 5) :

- **écriture atomique** : fichier temporaire, relu et comparé, puis renommé par-dessus la sauvegarde ;
- **format versionné** : `VERSION = 7` aujourd'hui, avec migrations incrémentales (`upgrade`) ; une
  version plus récente est refusée sans être touchée ;
- **fichier corrompu** mis de côté (`save.json.corrupt`, `save.json.rejected`), jamais écrasé.

Ce qui manque, d'après ce premier repérage : une **copie de secours** de la dernière sauvegarde
valide, et une **sauvegarde à la mise en arrière-plan Android** (aucune trouvée ; proposée pour la
passe systèmes 2). Toutes les branches de jalon (J19 à J25) sont encore en v7 : pas de conflit de
version de sauvegarde entre jalons parallèles pour l'instant, mais **chaque jalon qui l'incrémente
doit le faire après la fusion du précédent**.

**Visuel (§3)** : `CLAUDE.md` fixe la case à 96 px pour une résolution de référence de 1920 × 1080
(≈ 11 cases de haut, ≈ 24 de large sur le S24 en 2340 × 1080) : cohérent avec la cible 24 × 11 du
dossier.

**Export Android** : `export_presets.cfg` existe (paquet `dev.kevin.kanto2026`), mais aucun numéro
de version (`version/code`, `version/name`) n'y est renseigné : à prévoir pour l'APK versionné du lot
33F.

**Art** : le J33 recoupe la phase DA de la règle 3 de `CLAUDE.md` et les lots d'art reportés par la
stratégie d'accélération (levier 4) : c'est là que les visuels provisoires convergent.
