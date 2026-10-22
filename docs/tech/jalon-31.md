# Jalon 31 — La Grotte Inconnue et Mewtwo

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j31-v1-chatgpt.md` (dossier V1, 7 arbitrages verrouillés). Les arbitrages et
> les textes recommandés par la passe sont **validés par Kevin le 2026-10-21 (validation d'avance
> des textes recommandés)**. Tout texte absent de la passe est une proposition marquée **[D]**.

> Objectif jouable sur le téléphone : **après la Ligue, on retourne à Azuria, on entre dans la
> Grotte Inconnue, on y explore trois niveaux, on affronte Mewtwo N70 et on tente de le capturer.**
> Aucune nouvelle fin imposée ; la partie continue librement.
>
> Mécaniques nouvelles : l'**accès post-Ligue** (calculé, jamais sauvegardé), la **rencontre
> légendaire unique** (une seule règle pour Artikodin, Sulfura et Mewtwo). Rien d'autre : le Surf,
> les échelles et les donjons multi-étages existent déjà (passe systèmes 2, J24, J29).
>
> **Format de sauvegarde : pas d'incrément prévu** (§2.4). Si un incrément devient nécessaire, il
> se fait après la fusion du jalon précédent et se valide seul (règle 1 de `CLAUDE.md`).

## 0. État et dépendances (relu sur le dépôt, `origin/main`)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Espèce Mewtwo | Absente de `data/pokemon/species/` (les espèces arrivent jalon par jalon) | À créer (T4) |
| Grotte Inconnue | Aucune carte ni grille dans `tools/plans/` | Les 3 grilles sont à relever (T3) |
| Entrée côté Azuria | Carte d'Azuria du J13 ; point d'entrée non vérifié | À vérifier en 31.0 (T1) |
| Victoire à la Ligue | `league_first_clear_completed` n'existe pas encore (J30, conception seule) | Contrat à poser (T2), test avec drapeau simulé |
| Surf, rochers, courants | Passe systèmes 2 (branches `s2c-surf`, `s2d-force`), pas encore dans `main` | Les cartes réelles attendent leur fusion |
| Rencontre légendaire | Règle d'Artikodin dans `docs/tech/jalon-24.md` §2.7 (capture ou K.O. : consommée ; fuite ou défaite : rien) | Une seule implémentation (T2) |
| Master Ball | J26, conception | Test de capture garantie après sa fusion |
| Sauvegarde | `SaveSystem.VERSION = 7`, écriture atomique, migrations (`game/systems/save/save_system.gd`) | Drapeaux en champs à valeur par défaut |
| Outils de carte | `tools/plans/*.txt`, `tools/build_*.gd`, `tools/art/plan_grille.py`, `cave_map_kit.gd` | Réutilisés tels quels |

### 0.1 Ce qui peut commencer tout de suite
- **T1** audit 31.0 (lecture seule) ; **T2** contrat J30 → J31 et règle légendaire (logique pure) ;
  **T3** grilles ASCII des trois niveaux (relevé Rouge/Bleu) ; **T4** données (Mewtwo, rencontres,
  objets) ; **T5** accès calculé (test avec drapeau simulé).

### 0.2 Ce qui attend
- **T6 à T9** (cartes réelles, Surf, échelles, combat) : après la fusion de la passe systèmes 2 et
  du J30. **T9** (Master Ball) : après le J26. **T10** (QA complète) : après tout le reste.
- Règle d'ancienneté : le J31 ne modifie aucun système qu'un jalon plus ancien est en train de
  modifier ; en cas de doute, demander à Kevin.

## 1. Périmètre

**Dedans** : trois cartes (1F, 2F, B1F), accès depuis Azuria, rencontres sauvages de haut niveau,
objets, Mewtwo N70 (fixe, capturable une fois), persistance, rejouabilité.
**Dehors** : nouvelle CS, nouveau Badge, minimap, flèches d'objectif, cinématique explicative,
Dresseurs dans la grotte (non prévus par la passe : à confirmer au §8).

## 2. Contrats

### 2.1 Accès (dossier §3)
`CeruleanCaveAccess.is_open(state)` est **calculé** depuis `league_first_clear_completed` (J30). Il
ne lit ni le nombre de Badges, ni le Pokédex, ni la présence de Mewtwo. Refusé : 7 Badges ; 8 Badges
sans Ligue ; Conseil des Quatre vaincu sans Champion ; accordé : Champion vaincu et victoire
enregistrée, y compris après rechargement.

### 2.2 Géographie
Entrée au nord-ouest d'Azuria, par les berges. Surf selon le modèle hybride du J16 (CS possédée,
Pokémon compatible dans l'équipe, Badge Âme). **Tous les chemins sont atteignables avec les
capacités déjà obtenues** (test d'atteignabilité sur la grille, T7).

### 2.3 Rencontre légendaire (un seul comportement pour trois Pokémon)
Données par légendaire : `id`, espèce, niveau, carte, case, drapeau de résolution. Règle :
**capture ou K.O. : rencontre consommée ; fuite ou défaite : rien n'est consommé, le Pokémon reste.**
Mewtwo : N70, fixe, ne se déplace pas, absent de la carte une fois résolu. Aucun doublon après
rechargement ni après fermeture de l'appli pendant le combat (la rencontre n'est consommée qu'à la
résolution ; la capture ajoute le Pokémon et pose le drapeau dans **la même écriture**).

### 2.4 États persistants (dossier §8)
| Identifiant | Source |
|---|---|
| `cerulean_cave_unlocked` | **Calculé** (pas sauvegardé) |
| `cerulean_cave_discovered` | Drapeau d'histoire (valeur par défaut `false`) |
| `cerulean_cave_items_collected` | Liste d'objets ramassés (mécanisme existant des objets de carte) |
| `mewtwo_encounter_resolved` | Drapeau (partagé avec le contrat §2.3) |
| `mewtwo_captured` | **Non sauvegardé** : source de vérité = équipe, stockage, Pokédex |
| `postgame_unlocked` | Hérité du J30 |
Lecture par `JsonFields.get_*` avec valeur par défaut : une ancienne sauvegarde se charge sans
migration.

### 2.5 Capacités de Mewtwo
Référence du dossier (à confirmer sur les données de première génération) : Psyko, Soin, Météores,
Bouclier. T4 vérifie chaque capacité contre `data/pokemon/moves/` ; une capacité absente est
ajoutée par le jalon ou signalée à Kevin, jamais remplacée en silence.

## 3. Tâches

### T1 — Audit 31.0 (Sonnet, lecture seule)
Inventaire : carte d'Azuria et point d'entrée, `FieldMoves` et état de la passe systèmes 2, données
légendaires du J24, drapeaux du J30, espèces présentes, tables de rencontres `water` et `cave`.
Classement : implémenté et vérifié / présent incomplet / spécifié / absent.
Critère : rapport court dans `docs/tech/` (section 31.0 de ce fichier) avec chemins réels.

### T2 — Contrat J30 → J31 et règle légendaire (Opus, logique pure)
`LegendaryEncounter` (règle §2.3) en données ; `CeruleanCaveAccess` (§2.1). Aucun écran.
Tests : les 5 cas d'accès du §2.1 ; capture, K.O., fuite, défaite ; rechargement après chaque cas ;
interruption entre « capture » et « écriture » (simulée avec le faux système de fichiers de
`tests/`).

### T3 — Grilles des trois niveaux (Sonnet, validation Kevin)
`tools/plans/cerulean_cave_1f.txt`, `_2f.txt`, `_b1f.txt`, relevées sur **Rouge/Bleu** (pas Rouge
Feu/Vert Feuille). Graphe des transitions (échelles, sorties) en tête de chaque fichier. Contrôle
par `plan_check` (atteignabilité, cases d'eau surfable, échelles appariées).
Critère : Kevin valide les grilles et **une** vue générale peinte (stratégie d'accélération, levier 4).

### T4 — Données (Sonnet)
Espèce Mewtwo ; capacités vérifiées ; tables de rencontres par étage (taux et niveaux historiques) ;
objets visibles et cachés placés selon la référence ; musique et ambiance : provisoires (règle 3).
Tests : `tools/check_json_keys.py` ; test de structure des tables ; aucun objet historique remplacé.

### T5 — Accès depuis Azuria (Sonnet)
Porte ou berge d'entrée qui interroge `CeruleanCaveAccess`. Refus : message court (§4). Test
d'intégration avec drapeau simulé ; point de départ de débogage `tools/debug_start/cerulean_cave.json`.

### T6 — Cartes (après passe systèmes 2)
Trois scripts `tools/build_cerulean_cave_*.gd` sur `cave_map_kit.gd` ; palette « gris-bleu, bassins
sombres, reflets froids » du dossier §4. Capture headless relue.

### T7 — Surf, échelles, collisions (après passe systèmes 2)
Entrée et sortie de chaque étage aux bonnes coordonnées ; test d'atteignabilité de tous les objets
et de Mewtwo depuis l'entrée ; Surf refusé sans CS, sans Badge ou sans Pokémon compatible.

### T8 — Rencontres sauvages et objets (Sonnet)
Branchement des tables du T4 ; objet ramassé puis rechargement : absent ; sauvages ordinaires qui
réapparaissent selon le moteur.

### T9 — Mewtwo : combat, capture, persistance (Opus, après J26 pour la Master Ball)
Étape `wild_battle` réutilisée (issues `win` / `catch` / `flee`). Équipe pleine : stockage (jamais
de perte). Tests : Hyper Ball, Master Ball, envoi au stockage, retour après capture (absent),
nouvelle victoire à la Ligue sans reset, interruption pendant le combat.
**Sauvegarde touchée : validée seule** (règle 1).

### T10 — Rejouabilité, sauvegardes, QA S24
Suite complète, QA téléphone (§6), mise à jour de `etat-projet.md` et de la roadmap.

## 4. Textes

Validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés) : aucune cinématique
explicative ; dialogues de deux lignes maximum, environ 40 caractères par ligne.
Propositions **[D]** (la passe ne fournit aucun texte) :
- Refus d'accès : « Les eaux sont trop agitées. Pas maintenant. » [D]
- Première interaction avec Mewtwo : pas de dialogue, cri puis combat. [D]
- Journaux du Manoir (J25) : inchangés ; la cohérence narrative est un contrôle, pas un texte neuf.

## 5. Critères d'acceptation
1. Huit Badges sans Ligue : accès refusé ; première victoire : accès ouvert ; rechargement : ouvert.
2. Les trois niveaux sont traversables, tous les objets atteignables, retour à l'entrée toujours possible.
3. Mewtwo N70 combattu et capturé une seule fois ; absent ensuite ; aucun doublon après fermeture forcée.
4. Pokédex et stockage enregistrent Mewtwo ; Ligue rejouable sans reset.
5. Suite complète verte ; ancienne sauvegarde v7 chargée sans migration.

## 6. QA téléphone (S24)
Une session : entrée depuis Azuria, Surf, échelles aller-retour, 3 combats sauvages, un objet
ramassé puis appli tuée et relancée, Mewtwo (fuite puis retour, puis capture), retour à Azuria.
Observer : commandes tactiles du Surf, stabilité des transitions, reprise Android.

## 7. Risques
Plan relevé sur la mauvaise version du jeu ; Mewtwo dupliqué par une écriture non atomique ;
chemin inaccessible sans nouvelle CS ; collision avec le J30 sur le drapeau de victoire.

## 8. Points ouverts pour Kevin
1. Dresseurs dans la Grotte Inconnue : aucun (fidèle à Rouge/Bleu) ? [D : aucun]
2. Fuite devant Mewtwo : il reste (règle d'Artikodin) ? [D : oui]
3. Refus d'accès : message de §4 à valider, ou la grotte reste simplement non repérable ?
4. Mewtwo absent du Pokédex avant rencontre : voulu ? [D : oui, comme les autres]
