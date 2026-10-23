# Rebasage des J22 à J25 sur `main` : état des lieux (2026-10-23)

Analyse **en lecture seule** (simulations `git merge-tree`, aucune branche modifiée) faite face à
`origin/main` `76b788ff` (passe systèmes 2 complète, clôture S2Z, J21). Demandée par Kevin le
2026-10-22 au soir.

## En bref

- **Deux chaînes, pas quatre branches indépendantes** : `jalon-23` contient tout le J22,
  `jalon-25` contient tout le J24. Fusionner le J23 ou le J25 ferait entrer le J22 ou le J24 dans
  `main` sans leur validation. **Ordre** : J22 → `main`, puis `main` → J23 ; J24 → `main`, puis
  `main` → J25 (les deux chaînes sont indépendantes l'une de l'autre).
- **Méthode** : **fusionner `main` dans chaque branche**, pas de rebase (branches pleines de
  fusions, déjà poussées) ; même méthode que J21 et J26–J31.
- **Code de systèmes** : **rien à réécrire**. Les quatre branches ont déjà absorbé la passe
  systèmes 2 jusqu'à S2D (`8c2cb6ee`) et retiré leurs anciennes copies (pêche et Vélo du J22,
  `surf_rules` / `boulder_rules` / `current_field` du J24, Surf / Force / `hm03` / `hm04` du J23).
  Leur code propre s'appuie sur l'API de `main`, inchangée depuis.
- **Doublons bloquants communs** (le chargeur refuse un identifiant déjà défini) : `poliwag`,
  `tentacool` (espèces) et `amnesia`, `barrier` (capacités), définis à l'identique par le J21
  (`kanto_j21.json`, `moves/j21.json`) et par les reprises des branches
  (`kanto_j22_j21.json` / `moves/j22_j21.json` ; `kanto_j24_reprises.json` / `moves/j24_reprises.json`).
  → supprimer la copie de la branche (prévu par `jalon-22.md` et `jalon-24.md`).
- **Toutes** gardent `qa_teleport`, `qa_teleport_2` dans `interiors.json` et `qa_sea_water` dans
  les tests : à retirer (S2Z). Sprites provisoires `poliwag_*`, `tentacool_*` en double : garder
  ceux de `main`.
- **Aucune vraie question de game design nouvelle.** Le blocage est la **validation des QA** :
  J22 (QA de nuit non validée), J24 (24A–24D non validées, défauts D1, D2, D5).

## Par branche

| | J22 (`jalon-22`, `1a86a4f5`) | J23 (`jalon-23`, `5b009218`) | J24 (`jalon-24`, `d6f91495`) | J25 (`jalon-25`, `320c5996`) |
|---|---|---|---|---|
| Copie | `wt-j22`, propre, = origin | `wt-j23`, = origin | `wt-j24`, propre, = origin | `wt-j25`, propre, = origin |
| Contient | passe jusqu'à S2D | **J22** (sans ses 2 derniers commits `7c7d7bfa`, `1a86a4f5`) | passe jusqu'à S2D | **J24** (sans `d6f91495`, D3/D4) |
| Commits propres | 50 | 88 | 39 | 54 (29 J24 + 25 J25) |
| Conflits simulés | 21 | 35 | 22 | 30 (dont 23 du J24) |
| Code moteur en conflit | aucun | 6 (combat, scènes : ajouts parallèles) | aucun | 3 (scènes : ajouts parallèles) |
| Estimation | moyen | moyen (après le J22) | petit à moyen | petit à moyen (après le J24) |

Branches locales sans suite : `j23-safari-combat`, `j23-koga` (locales seulement, contenues dans
`j23-nuit`) ; `jalon-23` locale périmée ; copie `.claude/worktrees/jalon-25` (branche `jalon-25`
locale `f0bbe0ec`) contenue dans `j25-nuit`, obsolète. Les branches distantes s'appellent
`jalon-22` … `jalon-25` (les copies sont sur `j2x-nuit`, qui les suivent).

### J22 — Routes 12 sud à 18, Parmanie

- Conflits : `decors.json`, `interiors.json` (union, sans `qa_teleport*`), 8 sprites, 9 tests
  (compteurs), `build_painted_interiors.gd` (blocs `J22` + `ROUTE_12`), `etat-projet.md`.
- Code propre gardé : `map.gd` (Piste partielle `cycling_road_cells`, `fishable.json`),
  `mount_director.gd`, `fishing_director.gd`, `player.gd` (vélo provisoire `prop_velo_01`). Note de
  la session `moteur-commun` : elle remplace `_bike_placeholder` par `MountPlaceholder`
  (`moteur-commun.md` §4) — conflit à prévoir quand `moteur-commun` atteindra `main`.
- **Conflits silencieux** (clés JSON en double, Git ne dit rien) : `zones.json` et
  `assets/ui/map/kanto_placeholder_areas.json`, entrées `route_12` et `route_16` (J21 et J22) →
  fusionner les listes `maps`, choisir sous-titre, description et rectangle [D].
- **Raccords à faire (contrat J21 ↔ J22, `jalon-22.md` §0.5)** : bord sud de la Route 12 (`route_12`
  South0/1 ↔ `route_12_south` WarpNord, mêmes colonnes) ; poste de la Route 16 (`from_poste_w/_e`
  sur `main` contre `entrance_*_est` du J22), voie haute, porte haute, arbre `cut_route_16_tree` —
  bloc J22 de `build_route_16.gd` et de la grille `route_16.txt`, puis `build_j22_maps.gd`. Casse
  des tests du J21 (`test_route_12`, `test_route_16`, `test_map_links`) à mettre à jour.
- Drapeaux de Ronflex cohérents (`snorlax_route_12_*`, `snorlax_route_16_*`). Pêche au ponton de la
  Route 12 nord : RB oui, valeur [D] à poser.

### J23 — Parc Safari, Koga, CS03, CS04

- Conflits : 6 fichiers de combat et de scènes (`battle_request`, `battle_rules`, `battle_text`,
  `cutscene_step`, `cutscene_library`, `cutscene_director`) — garder les deux côtés, **`Kind` aligné
  avec le tableau des noms** (`SAFARI` et `FLUTE` ajoutés tous deux en fin) ; données
  (`decors`, `messages`, Pokédex, `objectives`, `interiors`), sprites, 13 tests, outils.
- **Sauvegarde v8** : pas de collision avec `SaveCheckpoint` (inchangé sur `main`) ; seulement
  `VERSION 7 → 8` avec étape de mise à niveau vide ; champ `safari` capturé par `GameState.to_dict`.
  Aucune autre branche n'utilise la v8 : J24–J31 l'hériteront.
- `no_fly_maps` rempli depuis `SafariConfig` (au lieu d'un trait de carte) : gardé ; le J30 (Ligue)
  devra poser la même interdiction.
- À régler : `vice_grip` (J23) et `vise_grip` (J22) = même capacité Force Poigne, déjà en double ;
  `tm_compatibility.json` sans Ronflex.
- À confirmer par Kevin (déjà [D] par la passe) : Surf à 90 au lieu de 95 (RB).

### J24 — Îles Écume, Routes 19–21, Artikodin, Labo des fossiles

- Conflits : `interiors.json`, 8 sprites, 9 tests, 3 outils, `etat-projet.md`. Aucun code moteur.
- Code propre gardé, sur l'API de `main` : `SeafoamState`, `seafoam_boulder_field` /
  `_setup` (`extends BoulderField` / `BoulderSetup`), `seafoam_floor_gate` (`FlagGate`),
  `FossilLab`, `metronome_rules` (`Kind.METRONOME`), correction D4 de `mount_director`. Le
  Surf forcé après une chute (point ouvert de `systemes-2.md` §10) est couvert
  (`MapTraits.forced_surf_cells` + `FALL`, `test_j24_seafoam_flow`). Artikodin passe par la
  rencontre fixe de `main`.
- À adapter : Guillotine (`moves/j24.json`) `pending_effects: ["ohko"]` → `effects` `ohko` (codé par
  la passe) ; évolutions Ptitard → Têtarte (N25), Tentacool → Tentacruel (N30) à ajouter dans
  `kanto_j21.json` ; Pokédex : doublons `tangela`, `gyarados` (déjà sur la branche) ;
  `tm_compatibility.json` à regénérer (Ronflex).
- Contrôle des grilles : `plan_check_systemes2.verifier_mer` échoue sur `route_19/20/21` et
  `cinnabar_island` (pas de case `depart`) → ajouter `depart` aux grilles ou garder
  `plan_check_j24_mer.py` [D].

### J25 — Manoir Pokémon, Cramois'Île, Auguste

- Propre au J25 (une fois le J24 dans `main`) : ≈ 7 conflits — `cutscene_director` /
  `_library` / `_step` (`UNSET_FLAGS`, `TOGGLE_FLAGS`, `TRADE` contre `FLUTE` du J21 : garder les
  deux, même ordre dans `Kind` et `TYPE_KEYS`), `decors.json`, `caves.json`, Pokédex, deux tests.
- Systèmes : chute du 3F = `Warp.Trigger.FALL` de `main` ; `MansionSwitch` sur `FlagGate` (pas le
  domaine de `ON_SWITCH`) ; porte de l'Arène en variante de scène (`KeyDoor` facultatif ; une
  variante `if_items` du J21 serait plus juste que le drapeau `got_pokemon_mansion_b1f_item_5`) ;
  Cramois'Île déjà dans `fly_points.json`. Échanges (`Pokemon.Origin.TRADE`) et quiz : gardés.
- À regarder : `SIGHT_MIN` 1 → 0 (validation globale des Dresseurs).
- `kanto_j25_reprises.json` (Tadmorv, Grotadmorv, Smogogo, Électrode) deviendra un doublon à
  l'entrée du J22 dans `main`.

## Fusions préparées (2026-10-23, locales, NON poussées)

Branches **locales** du dépôt principal (copies dans le scratchpad de la session de coordination) ;
`jalon-22`, `jalon-24` et leurs copies `wt-j22`, `wt-j24` n'ont pas bougé.

- **`prep/main-dans-jalon-22`** (`adeb1f5f`, sur `origin/jalon-22` `1a86a4f5`) : suite complète
  **6 662 / 6 662**, import sans erreur, `plan_check_systemes2`, `--legende`, `plan_check_j21`,
  `plan_check_j22` conformes. Retirés : `moves/j22_j21.json` (identique), `kanto_j22_j21.json`
  (sous-ensemble strict de `kanto_j21.json`, sans Ronflex — à confirmer), doublons du Pokédex.
  `zones.json` et rectangles de la Carte : une entrée `route_12` / `route_16`, `maps` en union,
  textes et rectangles du J21 [D] → la Route 12 sud et la Route 16 ouest sortent du rectangle de la
  Carte (à revoir avec l'illustration). Tests adaptés : `test_route_16` (Route 16 ouest a ses
  herbes), `test_j21_flags_contract` (7 départs du J22 posent les drapeaux de Ronflex). **Non
  fait, laissé à la session du J22** : raccords Route 12 sud et poste de la Route 16 (§0.5),
  pêche au ponton de la Route 12 nord [D].
- **`prep/main-dans-jalon-24`** (`abd847b2`, sur `origin/jalon-24` `d6f91495`) : suite complète
  **6 686 / 6 686**, import sans erreur. Retirés : `kanto_j24_reprises.json`, `moves/j24_reprises.json`
  (identiques), doublons du Pokédex (`poliwag`, `tentacool`, `tangela`, `gyarados`) ; évolutions
  Ptitard N25 et Tentacool N30 ajoutées à `kanto_j21.json` (accord J21/J24) ; Guillotine passée
  en effet `ohko`. Grilles de mer du J24 laissées à `plan_check_j24_mer.py` [D] ;
  `tm_compatibility.json` non regénéré (Ronflex sans CT, CSV absents).
- **Question d'équilibrage** (J24) : maintenant que Guillotine marche, la rendre aux Krabby des
  Dresseurs comme dans RB ? (Ils l'ont perdue par la règle de Major Bob.)

Pour pousser après validation : `git push origin prep/main-dans-jalon-22:jalon-22` (avance rapide),
idem pour le J24 ; les sessions des jalons font ensuite un `pull` dans `wt-j22` / `wt-j24`.

## Ce qui attend Kevin

1. **Valider les QA du J22 et du J24** (préalable à leur entrée dans `main`).
2. Feu vert pour fusionner `main` dans `jalon-22` et `jalon-24` (préparé, voir ci-dessous) puis,
   après validation, J22 et J24 dans `main` ; ensuite `main` dans J23 et J25.
3. Confirmer Surf à 90 (valeur de la passe) ; le reste est en valeurs par défaut [D].
