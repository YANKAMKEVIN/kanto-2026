# Stratégie d'accélération — de J19 à la fin du jeu

> Adoptée par Kevin le 2026-10-19. S'applique à toutes les sessions Kanto à partir de maintenant.
> Le reste des règles de `CLAUDE.md` est inchangé ; en cas de doute, ce document décide de
> **l'ordre** et du **rythme** du travail, pas du game design.

## Constat (2026-10-19)

- Rythme mesuré : J12 → J18 clos entre le 2026-10-14 et le 2026-10-19, soit **≈ 1,2 jalon par jour**.
- Il reste **au moins 30 jalons** jusqu'à la fin du jeu (Ligue et post-game compris) : ≈ 25 jours
  au rythme actuel. Objectif : **≈ 2 jalons par jour**, soit 12 à 15 jours (ordre de grandeur, non mesuré).
- Ce qui ralentit, par ordre d'impact :
  1. **Trop de jalons codés en même temps** (J19 à J25 ouverts le même jour) : fusions croisées,
     synchronisations avec `main`, blocages par la règle d'ancienneté (exemple : le Surf du J24
     attend le Vélo du J22 et la CS03 du J23).
  2. **Les tests saturent le Mac** : ≈ 5 600 tests en suite complète à chaque tâche, jusqu'à
     8 suites simultanées, ≈ 30 min chacune.
  3. **Beaucoup d'étapes validées une par une** par jalon (dossier, grilles, vues peintes, plan,
     sous-jalons, QA S24, textes).
  4. **L'art à la main** (prompts ChatGPT / Codex, allers-retours).

## Les six leviers

### 1. Passe « systèmes 2 » avant le reste du contenu (priorité n° 1)

Comme le J11 pour les statuts et les CT : coder **en une passe** tous les systèmes de déplacement
et d'exploration qui restent, avant d'étendre le contenu.

Périmètre validé par Kevin le 2026-10-19 : Vélo et Piste Cyclable, Surf, Force (rochers, trous), Vol,
Scope Sylphe, Poké Flûte, états « monté » du joueur, **téléporteurs** et **portes à carte**
(Carte Magnétique ; ajoutés par Kevin le 2026-10-19 pour le J26, Sylphe SARL), et tout système
encore prévu dans un jalon de contenu.

Ajoutés par Kevin le 2026-10-19 (deuxième vague) :

- **K.O. en un coup** (effet `ohko`, aujourd'hui en `pending_effects`) : Empal'Korne, Guillotine
  (J24) et Abîme (CT27, J28), codé une seule fois ;
- **interrupteurs et barrières** actionnés par les rochers de Force (Route Victoire, J29), à côté de
  `BoulderRules` ;
- **sauvegarde à la mise en arrière-plan Android** (appel, notification, verrouillage) : système de
  sauvegarde, donc **validé seul** (règle 1 de `CLAUDE.md`), utile à tout le jeu (J30 à J36).

**Entrée dans Safrania** (décision de Kevin, 2026-10-19) : faite au **J20**, qui a déjà les boissons
et les postes de garde (`route_7_gate`, `route_8_gate`) : donner une boisson au garde ouvre la porte,
comme dans Rouge/Bleu. Le J26 la consomme sans la coder.

Point de départ déjà écrit (message du J24, 2026-10-19) : `jalon-24` (@ `ed306985`) contient une
logique pure et testée de **Surf et de Force**, sans dépendance à une carte : `GridWorld` (eau
surfable, courants, niveaux de sol, `can_enter_as`, `find_reachable`), `SurfRules`, `BoulderRules`,
`SeafoamState`, `CurrentField`, `FossilLab`. Conception dans `docs/tech/jalon-24.md` §2.1 à §2.6 bis
(Warp FALL compris), résumé au §0.4. La passe systèmes 2 en est propriétaire : elle peut la
reprendre, la modifier ou la remplacer.

Ensuite, un jalon de contenu (route, ville, arène) n'est **que des données et des cartes** : il
ne dépend plus des autres jalons, et la règle d'ancienneté ne bloque presque plus rien.

### 2. Paralléliser la conception, pas le code

| Étage | Combien en parallèle | Contenu |
|---|---|---|
| Conception | 4 à 6 jalons d'avance | dossiers, arbitrages, textes, grilles (aucun test) |
| Code | **2 à 3 jalons maximum** | sur des zones de carte qui ne se touchent pas |
| Intégration | **1 seul à la fois** | fusion dans `main` dès la validation, puis le suivant |

Un jalon n'entre en code que si les systèmes qu'il utilise sont **déjà dans `main`**. Sinon, il
reste en conception.

### 3. Des tests plus rapides — outillé le 2026-10-19

- **Pendant une tâche** : `tools/test.sh --changed [base]` lance seulement les tests liés aux
  fichiers modifiés (tests modifiés, tests qui citent le fichier ou sa `class_name`). Si un fichier
  commun change (helpers, fixtures, autoload, addons, `project.godot`), il bascule sur la suite
  complète. `tools/test.sh -f motif1,motif2` cible des fichiers de test par leur nom.
- **Avant une fusion** : `tools/test.sh` (suite complète), toujours obligatoire. Le ciblage ne voit
  pas les dépendances indirectes.
- **Verrou** : 2 suites complètes au maximum en même temps sur le Mac (`KANTO_TEST_SLOTS`), places
  dans `/tmp/kanto2026-test-slots/`, libérées automatiquement si leur processus meurt. Les
  lancements ciblés ne prennent pas de place.
- **CI sur les branches de jalon** (décision de Kevin, 2026-10-19) : `.github/workflows/godot-tests.yml`
  se déclenche aussi sur les `push` des branches `jalon-*` (8 lots parallèles sur GitHub). Avant une
  fusion, une session peut pousser sa branche et lire le résultat de la CI (`gh run list`,
  `gh run watch`) au lieu de lancer la suite complète sur le Mac. Une branche ne profite du
  déclencheur qu'après avoir récupéré le workflow de `main`.
- **Tests lents** : la suite complète affiche à la fin ses 10 scripts les plus lents. Reste à faire :
  alléger les plus lents, sans perdre de couverture.

### 4. Moins d'étapes pour les jalons de contenu

- **Une seule QA S24 par jalon** pour le contenu simple (routes, Dresseurs, villes). Les
  sous-jalons et les QA séparées restent pour les systèmes risqués (sauvegarde, nouveaux
  systèmes), selon la règle 1 de `CLAUDE.md`.
- **Art : décision de Kevin (2026-10-19), entre-deux.**
  - **Avant le code**, on garde seulement ce qui sert au code : la **grille** (elle fait foi pour
    la géométrie) et **une vue générale peinte** comme repère d'ambiance.
  - **Tout le reste est reporté et produit par lots** de plusieurs jalons : décors finaux,
    personnages, dos et faces de Pokémon, planches. Le jalon est codé et validé sur S24 avec le
    kit existant ou des placeholders (règle 3).
  - **Le code ne bloque jamais sur l'art.** Une tâche d'intégration par lot branche l'art produit
    et le vérifie sur S24.

### 5. Validations groupées

Un ou deux **créneaux de validation par jour**, où Kevin valide tout d'un coup (textes, grilles,
prénoms, art). Entre deux créneaux, les sessions avancent avec des valeurs par défaut (règle 4)
et préparent la liste de ce qui est à valider, au lieu d'attendre.

### 6. Outils pour fabriquer le contenu

La plupart des jalons restants suivent le même modèle (route + Dresseurs + ville + arène). On
investit une fois dans :

- grille de `tools/plans/` → carte jouable ;
- fiche de Dresseur (données) → combat ;
- modèle d'arène (énigme, Champion, badge, CT) ;
- textes en lot (fichiers de données, validés d'un bloc).

Un jalon de contenu devient alors surtout un fichier de données à remplir.

## Ordre de marche

1. **Clore le J19** (QA 19A), puis fusionner le **J20** (déjà prêt).
2. Ouvrir la **passe systèmes 2**. Pendant ce temps, les J21 à J25 ne terminent que leur partie
   indépendante ; aucun nouveau jalon n'entre en code.
3. En parallèle, Kevin fait avancer **les dossiers des J26 à J30** (conception seulement).
4. Une fois les systèmes dans `main` : enchaîner les jalons de contenu au rythme du tableau du levier 2.
5. Mesurer le rythme chaque semaine (jalons clos par jour) et noter le résultat ici.

## Suivi

| Date | Jalons clos depuis le 2026-10-19 | Rythme | Remarque |
|---|---|---|---|
| 2026-10-19 | 0 | ≈ 1,2 / jour (base) | stratégie adoptée |
