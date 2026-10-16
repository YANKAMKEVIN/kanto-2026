# Dossier 27 — Les Îles Écume et Artikodin (jalon 24)

> Consolidé par Claude le 2026-10-16 à partir de la V2 de ChatGPT (`passes/j24-v2-chatgpt.md`) et
> de la passe d'alignement (`passes/j24-v2-alignement.md`). **Les 7 décisions de la V2 et les
> arbitrages P-1 à P-22 sont validés par Kevin** (« okay pour tes reco », 2026-10-16). Les **textes
> du §15 sont validés** par Kevin le 2026-10-16 (« pour J24 je valide ses 90 textes », relayé par une
> autre session à sa demande). Plan technique : `docs/tech/jalon-24.md`. **Aucun code avant la fusion du J23** (§17), sauf le
> travail indépendant listé au §17.3.
>
> Faits Rouge/Bleu : désassemblage `pret/pokered` (`af51989`). Marqueurs : **[V]** validé par
> Kevin, **[D]** valeur par défaut (règle 4 de `CLAUDE.md`), **RB** Rouge/Bleu, **K26** invention de
> Kanto 2026.
>
> Branche : `docs/dossier-27-j24`. Dossiers voisins :
> - 19 (J16, Coupe et modèle hybride des CS) et 20 (J17, Flash, `FieldMoves`) ;
> - 23 (J20, Erika et Badge Prisme) et 24 (J21, rencontre statique de Ronflex) ;
> - 25 (J22, Parmanie, pêche, Vélo) et 26 (J23, Safari, CS03, CS04, Koga).

## Décisions de Kevin

### Les 7 décisions de la V2 [V]

1. Routes 19 et 20, Îles Écume complètes, accès maritime à Cramois'Île.
2. Donjon avec courants, rochers, trous et puzzles de Force.
3. Artikodin : rencontre légendaire unique et capturable.
4. Surf : navigation libre, rencontres sauvages, transitions entre cartes.
5. Rochers persistants, avec prévention et récupération des blocages.
6. Cramois'Île accessible, bâtiments principaux ouverts ; Manoir et Arène pour un jalon ultérieur.
7. Fin libre, sans événement narratif forcé.

### Arbitrages P-1 à P-22 [V]

| # | Décision |
|---|---|
| P-1 | Dossier n° 27, `dossier-27-iles-ecume.md`. |
| P-2 | **Le J23 livre** `hm03`, `hm04`, les capacités `surf` et `strength` (données et combat), leurs entrées `FieldMoves` et les compatibilités. **Le J24 construit** le mode Surf et les rochers de Force. Transmis à la session du J23 le 2026-10-16. |
| P-3 | **Eau surfable seulement sur les cartes du J24** (Routes 19, 20, 21, Îles Écume, Cramois'Île) **et sur la côte sud de Parmanie**. Ailleurs, l'eau reste un décor. |
| P-4 | **La Route 21 est construite au J24** ; la côte sud de Bourg Palette s'ouvre. |
| P-5 | Géométrie RB agrandie ; les coordonnées des documents de conception sont celles de **RB**. |
| P-6 | **RB** : par la mer, Cramois'Île passe par les Îles Écume (traversée en Surf, sans Force). Si l'émulateur infirme ce trajet en 24.0, on ajoute un chenal au sud de l'île. |
| P-7 | Monture générique peinte ; le compagnon rentre dans sa Ball en Surf. |
| P-8 | **Bouton contextuel SURFER** face à l'eau surfable ; entrée Surf aussi dans le menu Équipe. |
| P-9 | **Persistance par 8 drapeaux de chute** ; les rochers non tombés reviennent à leur place quand on change d'étage ou qu'on recharge ; **pas de sauvegarde v8** pour les rochers. |
| P-10 | **Courants visibles**, en cases de la grille, réutilisant la glissade du J20, coupés par les drapeaux. |
| P-11 | Surf sur les routes : **Tentacool seul (RB), taux 5, niveaux resserrés**. |
| P-12 | Tables des Îles Écume : **union Rouge + Bleu** ; aucune rencontre en Surf dans le donjon. |
| P-13 | **Les 29 Dresseurs RB** des Routes 19–21, équipes RB, niveaux recalés par l'outil de simulation. |
| P-14 | Objets RB du donjon **plus 2 ou 3 objets visibles** sur les îlots et la prairie de la Route 21. |
| P-15 | Artikodin : **capture ou K.O. → il disparaît ; fuite ou défaite → il reste**, nouvelle chance. |
| P-16 | Pas de blocage « au B4F sans Surf » : la Route 20 ne s'atteint qu'en Surf. Garde-fou de chargement quand même. |
| P-17 | Aucun objectif nouveau au tableau de bord. |
| P-18 | **Résurrection des fossiles au J24** (RB). |
| P-19 | **CT35 Métronome au J24** ; **échanges du Labo reportés**, et leurs PNJ ne promettent rien. |
| P-20 | Arène : porte fermée sans la Clé Secrète (RB). Manoir : **entrée effondrée**, sans promesse. |
| P-21 | Arrivée à Cramois'Île sans événement. |
| P-22 | **24.0 · 24A Surf · 24B la mer · 24C Îles Écume · 24D Artikodin + QA finale** ; quatre validations S24, Surf et Îles Écume chacun seuls. |

## 1. Intention

Après Koga, Kanto s'ouvre vers le large. Le joueur quitte la plage de Parmanie, nage au milieu
des Nageurs, trouve deux grandes îles de glace et d'écume, et comprend en poussant des rochers
qu'il peut **changer le cours de l'eau**. Au fond, un oiseau de glace l'attend, sans un mot. De
l'autre côté, Cramois'Île, île volcanique et savante : un Centre, une Boutique, et le Labo qui
ramène enfin à la vie le fossile du Mont Sélénite. Puis, par la Route 21, la mer ramène le joueur
**à Bourg Palette**, là où tout a commencé.

Le jalon apprend deux gestes qui resteront : **nager** et **pousser**. Il les apprend sans tutoriel
plaqué : un panneau, un courant qu'on voit, un rocher qui tombe avec fracas.

## 2. Périmètre

| Dans le J24 | Hors du J24 |
|---|---|
| Mode Surf (monde), eau surfable des cartes listées, rencontres sur l'eau, Nageurs | Surf ailleurs (passe « Surf partout » avec un jalon ultérieur) |
| Rochers de Force, trous, courants ; **le rocher de la maison du Gardien** à Parmanie (§6.5) | Force ailleurs (Route Victoire, etc.) |
| Routes 19, 20, 21 ; côte sud de Parmanie et de Bourg Palette | Pêche (J22) |
| Îles Écume 1F, B1F, B2F, B3F, B4F | Électhor, Sulfura, Mewtwo |
| Artikodin N50 | Manoir Pokémon, Clé Secrète, Arène d'Auguste, Badge Volcan |
| Cramois'Île : ville, Centre, Boutique, Labo (hall, salle R&D, salle des fossiles, salle de réunion) | Échanges du Labo |
| Résurrection des fossiles, CT35 Métronome | |

## 3. Contrat d'entrée

Le J24 suppose fusionnés dans la branche d'intégration :

| Le J24 suppose | Identifiant | Jalon | Vérifié le 2026-10-16 |
|---|---|---|---|
| Sauvegarde v7, drapeaux libres | `SaveSystem.VERSION = 7`, `StoryFlags` | J15 | `origin/main` |
| Modèle hybride des CS, `FieldMoves`, étape `field_move` | `field_moves.json`, `CutsceneStep.Kind.FIELD_MOVE` | J16 + J17 | Sur deux branches, **à fusionner** (les deux entrées `cut` et `flash`) |
| Badge Prisme obtenable | drapeau `badge_rainbow`, étape `BADGE` | J20 | **Non** (données d'Erika seulement) |
| Rencontre statique | étape `wild_battle` (plan J21 §2.10), issues `win` / `catch` / `clear` | J21 | **Non codée** |
| Glissade forcée | `SpinSlide`, `SpinTileRules` | J20 | Codée, non fusionnée |
| Don d'un Pokémon | `PokemonGift` | J20 | Codé, non fusionné |
| Parmanie et sa sortie sud | `fuchsia_city` ; bord sud vers `route_19` | J22 | **Non** (60 × 54 prévu, M-1 à M-24 à trancher) |
| État « monté » (Vélo) et compagnon rentré | M-6, M-7 | J22 | Documenté |
| CS03 Surf, CS04 Force | `hm03` → `surf`, `hm04` → `strength`, entrées `surf` (`badge_soul`) et `strength` (`badge_rainbow`) | J23 | **Non** (P-2 transmis) |
| Badge Âme obtenable | `badge_soul` | J23 | **Non** |
| Fossile du Mont Sélénite | objet `dome_fossil` ou `helix_fossil`, drapeaux `mt_moon_got_*_fossil` | J12 | `main` |
| Métronome | capacité `metronome`, `pending_effects: ["metronome"]` | J12 | **Effet absent** : à coder au J24 (§13.3) |
| Capture → Stockage si équipe pleine | `BattleDirector._finish_capture`, `PokemonStorage` | J7 | `main` |

**Pas de Vieil Ambre** dans le projet : le Labo ne ressuscite que Kabuto et Amonita. Ptéra viendra
si un jalon donne l'Ambre.

## 4. Topologie

```
                       PARMANIE (J22) — côte sud surfable
                            |
   ROUTE 19 ── plage (2 Topdresseurs) ── mer (8 Nageurs)
                            |
   ROUTE 20 ─ mer ouest ─┬─ ÎLES ÉCUME ─┬─ mer est ─┘
     │   îlot de l'      │ entrée est   │ entrée ouest
     │   Ornithologue    │ (cul-de-sac) │ (donjon complet)
     │
   CRAMOIS'ÎLE ── nord ── ROUTE 21 (mer, prairie, îlots de Pêcheurs) ── BOURG PALETTE (côte sud)
```

- **Les deux mers de la Route 20 ne communiquent pas** (RB, P-6) : depuis Parmanie, on rejoint
  Cramois'Île par le donjon, ou par Bourg Palette et la Route 21.
- **Boucle complète** : Parmanie → Route 19 → Route 20 est → Îles Écume (traversée) → Route 20
  ouest → Cramois'Île → Route 21 → Bourg Palette.
- **Échelle [D]** :
  - routes et ville à **×1,5** de RB, comme Parmanie au J22. Route 19 ≈ 30 × 81, Route 20 ≈ 150 × 27,
    Route 21 ≈ 30 × 135, Cramois'Île ≈ 30 × 27 ;
  - **Îles Écume à 1:1 (30 × 18 par étage)** : agrandir casserait les puzzles de rochers (nombre de
    poussées, alignements). 30 cases font ≈ 2,9 écrans de large.
  - Les grilles de 24.0 font foi.

## 5. Surf [V décision 4, P-3, P-7, P-8]

### 5.1 Conditions

`FieldMoves.status("surf")` : `hm03` dans le Sac, `badge_soul`, un Pokémon **de l'équipe** qui
connaît Surf ou peut l'apprendre par la CS. Le compagnon est préféré, un Pokémon K.O. compte
(règle J16).

### 5.2 Eau surfable

- La grille distingue **l'eau surfable** (caractère propre) de **l'eau décor**.
- Seules les cartes du §2 et la côte sud de Parmanie en contiennent. Un test refuse toute autre
  carte (P-3).
- **Côte sud de Bourg Palette** : les lignes d'eau actuelles deviennent surfables et mènent au bord
  sud → Route 21.

### 5.3 Monter

| Situation | Comportement |
|---|---|
| Face à l'eau surfable, `READY` | Le bouton contextuel affiche **SURFER**. Un toucher : le compagnon rentre dans sa Ball, la monture apparaît, le joueur saute dessus (≈ 0,5 s), puis avance d'une case. |
| Face à l'eau surfable, conditions manquantes | Le bouton affiche **EXAMINER** : texte T-1 et sa variante (pas de CS, pas de badge, aucun Pokémon) avec les variantes `field` existantes. |
| Menu Équipe → Pokémon → SURF | Même effet si le joueur est face à l'eau surfable ; sinon « Impossible ici. » (RB). |
| Vélo | Rangé automatiquement (règle J22). |

### 5.4 En mer

- **Contrôles de la marche**, sans bouton de plus. **Pas de course** : une seule vitesse,
  ≈ 1,15 × la marche [D].
- **Monture** : générique, peinte, 4 directions, légère ondulation à l'arrêt, sillage d'écume en
  mouvement.
- **Collisions** : terre infranchissable sauf pour descendre ; rochers, récifs, PNJ et Nageurs
  bloquent.
- **Rencontres** : terrain `water` de la carte (§11). **Fond de combat** « mer ouverte » sur les
  routes, « grotte glacée » dans le donjon.
- **Nageurs** : Dresseurs ordinaires dont la ligne de vue passe au-dessus de l'eau. Ils nagent
  jusqu'au joueur.

### 5.5 Descendre

Avancer vers une case de terre praticable : le joueur saute sur la rive, la monture disparaît, le
compagnon ressort. Pas de bouton.

### 5.6 Changer de carte

- **Par un bord** : le Surf est gardé (routes ↔ routes, route ↔ Cramois'Île, Bourg Palette ↔
  Route 21).
- **Par un warp** (entrée de grotte, échelle) : le joueur repasse à pied, sauf sur une case
  **« Surf forcé »**. Ces cases sont les arrivées dans l'eau du B3F et du B4F (chutes, warps d'eau),
  où le joueur arrive monté (RB).

### 5.7 Sauvegarde et reprise

- La position sauvegardée porte `surfing` (champ facultatif ; `false` par défaut).
- **Au chargement**, si `surfing` :
  - la case est une eau surfable et les conditions du §5.1 sont réunies → reprise en Surf ;
  - sinon → **garde-fou** : le joueur est replacé sur la **dernière case de terre** de la carte
    (mémorisée dans la position), à défaut au point d'arrivée de la carte.
- **Pas de sauvegarde pendant une glissade de courant** (`is_stable`).
- Si le format de position n'accepte pas de champ facultatif, la sauvegarde passe en **v8**
  (vérifié en 24A ; migration triviale).

## 6. Force [V décision 2, P-9]

### 6.1 Conditions

`FieldMoves.status("strength")` : `hm04`, `badge_rainbow`, un Pokémon de l'équipe compatible.

### 6.2 Activer

- Le joueur touche EXAMINER face à un rocher de Force → texte T-5 → **UTILISER FORCE / LAISSER**.
- Avec UTILISER : « {Pokémon} utilise Force ! » (cri, le compagnon prend appui).
- Force reste **active jusqu'au prochain changement de carte** (RB) ; un combat ne l'annule pas.
- Si les conditions manquent, EXAMINER donne seulement T-5 et sa variante `field`.

### 6.3 Pousser

- **Activer** : marcher contre le rocher en gardant la direction **0,25 s** [D].
- **Ce qui se passe** : le rocher glisse d'une case (≈ 0,3 s, son de raclement), et le joueur avance
  derrière lui.
- **Refus** (le rocher tremble, son sourd, **aucun texte**) dans ces cas :
  - eau, mur ou arête ;
  - escalier ou échelle ;
  - changement de niveau de sol ;
  - PNJ, autre rocher, case d'objet.
- **Trou** : le rocher bascule et disparaît (fracas, poussière), puis le drapeau du trou est posé.
  Une **sauvegarde automatique** suit.

### 6.4 Rochers de Force et rochers décor

Les rochers poussables ont un aspect propre : arrondis, plus clairs, une fissure. Les petits rochers
fixes de RB (`r`) restent du décor.

### 6.5 Le rocher de la maison du Gardien (Parmanie)

- **D'où il vient** : le J23 pose ce rocher comme **obstacle fixe**, avec la même image que les
  rochers de Force ; c'est le seul rocher posé par le J23 (message de la session du J23,
  2026-10-16). Derrière lui, un Super Bonbon (RB).
- **Ce que fait le J24** : il le rend **poussable**, avec les règles du §6.
- **Persistance** : pas de drapeau. Comme dans RB, il reprend sa place quand on quitte la carte. Une
  fois ramassé, l'objet reste acquis (`found_items`).
- **Anti-blocage** : la grille de Parmanie doit garantir qu'aucune poussée ne mure la porte du
  Gardien. Ce contrôle est ajouté au lot 24C.

## 7. Îles Écume [V décision 2, P-6, P-9, P-10, P-12]

### 7.1 Les étages

Cinq cartes de 30 × 18 cases, deux niveaux de sol (bas, haut) reliés par des escaliers ; échelles
entre étages. Plans de topologie : `passes/j24-v2-alignement.md`, annexe A. Ambiance : glace bleutée,
écume, vent, gouttes ; la lumière baisse à chaque étage, sauf dans la salle d'Artikodin, plus claire.

| Étage | Rôle |
|---|---|
| 1F | Deux entrées (ouest : depuis la mer est ; est : depuis la mer ouest). **2 rochers, 2 trous.** |
| B1F | Les 2 rochers tombés du 1F, 2 trous. |
| B2F | Les 2 rochers tombés du B1F, 2 trous. Pépite cachée. |
| B3F | Grand bassin central avec **courant 1**. 4 rochers + 2 trous à l'ouest. Max Élixir caché. |
| B4F | Deux mers séparées. **Courant 2** à l'ouest. **Salle d'Artikodin** au nord-ouest. Hyper Ball cachée. Panneaux T-12 et T-13. |

### 7.2 Les 8 trous et leurs drapeaux

| Trou | Drapeau | Le rocher réapparaît |
|---|---|---|
| 1F n° 1 | `seafoam_1f_hole_1_filled` | B1F, point fixe 1 |
| 1F n° 2 | `seafoam_1f_hole_2_filled` | B1F, point fixe 2 |
| B1F n° 1 | `seafoam_b1f_hole_1_filled` | B2F, point fixe 1 |
| B1F n° 2 | `seafoam_b1f_hole_2_filled` | B2F, point fixe 2 |
| B2F n° 1 | `seafoam_b2f_hole_1_filled` | B3F, **dans l'eau** (coupe le courant 1) |
| B2F n° 2 | `seafoam_b2f_hole_2_filled` | B3F, **dans l'eau** (coupe le courant 1) |
| B3F n° 1 | `seafoam_b3f_hole_1_filled` | B4F, **dans l'eau** (coupe le courant 2) |
| B3F n° 2 | `seafoam_b3f_hole_2_filled` | B4F, **dans l'eau** (coupe le courant 2) |

**Un trou rempli est bouché**. Le rocher qui l'a rempli importe peu (on ne reproduit pas la
bizarrerie de RB).

### 7.3 État d'un étage

Il est **calculé à l'entrée** depuis les 8 drapeaux, sans autre donnée :
- les trous remplis de l'étage sont bouchés ;
- les rochers tombés d'au-dessus sont à leurs points fixes ;
- les rochers libres de l'étage sont **à leur position d'origine**, dans cet ordre :
  - 1F : 2 rochers, moins les trous remplis du 1F ;
  - B1F et B2F : les rochers tombés d'au-dessus, moins les trous remplis de l'étage ;
  - B3F : 4 rochers, moins les trous remplis du B3F. Les rochers retirés sont les derniers de la
    liste d'origine : la solution reste possible avec ceux qui restent.
- Les courants sont actifs ou coupés.

**Récupération locale** : changer d'étage, ou recharger la partie, remet les rochers libres à leur
place. Un panneau à l'entrée des étages à rochers le dit (T-11).

### 7.4 Courants

| Courant | Actif tant que | Effet |
|---|---|---|
| **1** (B3F) | `seafoam_b2f_hole_1_filled` **et** `_2_filled` ne sont pas tous deux posés | Entrer dans le bassin, ou y tomber, emporte le joueur en Surf le long d'un trajet fixe jusqu'au bord sud du bassin → **B4F, mer est** (RB). Le chemin de traversée vers Cramois'Île l'utilise. |
| **2** (B4F) | `seafoam_b3f_hole_*_filled` ne sont pas tous deux posés | Tomber du B3F emporte le joueur jusqu'à la plateforme centrale, où il descend. Depuis l'escalier de la plateforme, SURFER est refusé (T-14). La mer ouest et la salle d'Artikodin restent hors d'atteinte. |

- Les cases de courant sont **visibles** : écume orientée, petites vagues, son plus fort.
- Une fois coupé, le courant redevient de l'eau calme, et les deux rochers tombés sont posés en
  travers du passage.
- Glissade : moteur `SpinSlide` du J20 (case d'arrivée sûre), vitesse ≈ 2 × la marche [D].
  Aucune entrée n'est prise pendant la glissade.

### 7.5 Chutes du joueur

- Le joueur peut **sauter dans un trou non bouché** : fondu court, il atterrit au point d'arrivée
  fixe de l'étage inférieur.
- Au B2F et au B3F, ce point est dans l'eau : il arrive **en Surf forcé** (et le courant s'applique
  s'il est actif).

### 7.6 Anti-blocage (prouvé par tests sur les grilles)

1. Depuis chaque case atteignable de chaque étage, pour **toutes les positions** des rochers
   obtenables par poussée, il existe un chemin vers une échelle qui remonte ou vers une entrée.
2. Une case où un rocher murerait ce chemin est **retirée de la grille** (mur ou décor) au lot 24.0.
3. Chaque arrivée dans l'eau a une rive atteignable.
4. La solution complète (8 chutes) reste possible depuis chaque état reconstruit (§7.3).
5. Le joueur qui atteint le B4F remplit toujours les conditions du Surf (P-16). Le garde-fou du
   §5.7 couvre tout chargement anormal.

### 7.7 Solution attendue (RB)

1. 1F : 2 rochers dans 2 trous.
2. B1F : idem.
3. B2F : idem → courant 1 coupé.
4. B3F : 4 rochers pour 2 trous → courant 2 coupé.
5. B4F : surfer dans la mer ouest jusqu'à l'escalier de la salle d'Artikodin.

**Seuls les rochers du B3F sont indispensables** pour Artikodin ; la chaîne du haut sert à calmer le
bassin du B3F. Le solveur et l'émulateur confirment la solution en 24.0.

### 7.8 Objets

| Étage | Objet | Visible ? |
|---|---|---|
| B2F | Pépite | cachée (RB) |
| B3F | Max Élixir | caché (RB) |
| B4F | Hyper Ball | cachée (RB) |

La lueur d'aide existante s'applique aux objets cachés.

## 8. Artikodin [V décision 3, P-15]

### 8.1 Présence

- B4F, salle au nord-ouest, posé, tourné vers l'entrée de la salle. Il respire, ailes repliées,
  souffle froid léger.
- **Pas de cinématique.** Rien ne le montre avant que le joueur entre dans la salle.
- Il est visible tant que `articuno_done` n'est pas posé.

### 8.2 Rencontre

1. Le joueur touche **OBSERVER** : T-20 (« … »), cri d'Artikodin, petit souffle de givre sur
   l'écran.
2. Combat sauvage par l'étape `wild_battle` (J21) : **Artikodin N50, Picpic, Laser Glace** (RB).
   Taux de capture **3** (RB).
3. **Intro légendaire** : le bandeau d'apparition est plus lent (≈ 1,5 ×) [D]. Musique de combat
   sauvage. Fond « grotte glacée ».

### 8.3 Issues

| Issue | Effet |
|---|---|
| **Capture** | `articuno_done` + `articuno_caught` ; équipe, ou Stockage si elle est pleine (message existant). Artikodin quitte le monde. |
| **K.O.** | `articuno_done` ; T-21 dans le monde ; Artikodin quitte le monde. |
| **Fuite** | Rien n'est posé. Artikodin reste à sa place. |
| **Défaite** | Réveil au dernier Centre. Artikodin reste. |

### 8.4 Sans duplication

- Le drapeau, le Pokémon capturé et la position sont écrits **dans une seule sauvegarde forcée**,
  juste après la fin du combat, avant tout texte.
- Si l'application se ferme avant cette écriture, la partie reprend **avant l'interaction**, avec
  Artikodin présent et rien de capturé.
- Le Pokémon capturé porte son identifiant unique (v6).

### 8.5 Pokédex

Artikodin est « vu » au début du combat et « pris » à la capture (règles existantes).

## 9. Routes 19, 20, 21 [V décision 1, P-4, P-11, P-13, P-14]

### 9.1 Route 19

- **Plage** au nord, sous Parmanie : sable, parasols repliés, deux **Topdresseurs** qui
  s'échauffent.
- Panneau T-30.
- Puis la **mer**, avec 8 Nageurs qui ferment la route en quinconce.

### 9.2 Route 20

- Mer d'est en ouest, avec :
  - **l'île des Îles Écume** (falaises blanches, deux entrées de grotte) ;
  - à l'ouest, **l'îlot de l'Ornithologue**, où il attend sans pouvoir repartir.
- 9 Nageurs.
- Panneaux T-31 devant chaque entrée.
- Le Nageur de la **poche fermée** (N35) n'est atteignable que par la rive ouest de l'île.

### 9.3 Route 21

- Mer nord-sud entre Bourg Palette et Cramois'Île :
  - en haut, une **prairie d'herbes hautes** qu'on n'atteint qu'en Surf ;
  - deux **îlots de Pêcheurs** ;
  - 5 Nageurs.
- Les Pêcheurs ont une **vue 0** : il faut leur parler (RB).
- **Rencontres d'herbe** (RB, taux 25) : Rattata, Rattatac, Roucool, Roucoups, Saquedeneu
  (N21–32).

### 9.4 Dresseurs (équipes RB ; niveaux recalés par simulation au plan)

| Route | Classe et nom [D] | Équipe RB (niveau) | Argent |
|---|---|---|---|
| 19 | Topdresseur Hugo | Tentacool, Kokiyas (30) | règle existante |
| 19 | Topdresseur Malo | Poissirène, Hypotrempe, Stari (29) | |
| 19 | Nageur Yann | Ptitard, Têtarte (30) | |
| 19 | Nageur Erwan | Hypotrempe, Tentacool, Tentacool, Poissirène (27) | |
| 19 | Nageur Loïc | Poissirène, Kokiyas, Poissoroy (29) | |
| 19 | Nageur Tanguy | Hypotrempe, Hypotrempe (30) | |
| 19 | Nageuse Maëlle | Ptitard, Poissirène, Poissoroy, Poissirène, Ptitard (27) | |
| 19 | Nageuse Anaïs | Poissirène, Poissoroy (30) | |
| 19 | Nageur Gwen | Tentacool, Tentacool, Stari, Hypotrempe, Tentacruel (27) | |
| 19 | Nageuse Léna | Stari, Stari, Stari (29) | |
| 20 | Nageur Ronan | Kokiyas, Crustabri (31) | |
| 20 | Nageuse Solène | Hypocéan, Hypotrempe, Hypocéan (30) | |
| 20 | Nageuse Iris | Poissoroy (35), poche fermée | |
| 20 | Nageuse Lou | Tentacool, Hypotrempe, Otaria (30) | |
| 20 | Nageur Mathis | Stari (35) | |
| 20 | Nageur Kilian | Hypotrempe, Hypotrempe, Hypocéan, Hypotrempe (28) | |
| 20 | Ornithologue Bastien | Rapasdepic, Rapasdepic, Roucoups (30) | |
| 20 | Nageuse Clara | Kokiyas, Kokiyas, Crustabri (30) | |
| 20 | Nageuse Nina | Poissirène, Poissoroy (31) | |
| 20 | Nageuse Elsa | Ptitard, Poissoroy (31) | |
| 21 | Pêcheur Gilles | Poissoroy, Poissirène, Poissoroy, Poissoroy (28) | |
| 21 | Pêcheur Marcel | Magicarpe ×6 (27) | |
| 21 | Nageur Thibault | Hypocéan, Tentacruel (33) | |
| 21 | Nageur Dylan | Tentacool, Tentacool, Tentacruel (31) | |
| 21 | Nageur Simon | Staross (37) | |
| 21 | Nageur Arthur | Stari, Carabaffe (33) | |
| 21 | Nageur Noé | Têtarte, Tentacool, Hypocéan (32) | |
| 21 | Pêcheur René | Kokiyas, Crustabri (31) | |
| 21 | Pêcheur Yves | Poissoroy, Poissirène (33) | |

- Les capacités suivent la règle des Dresseurs ordinaires : celles apprises jusqu'au niveau.
- Les Nageuses remplacent la classe « Canon » de RB, qui porte un sprite de Nageur dans les routes
  marines.

### 9.5 Objets visibles (P-14) [D]

| Lieu | Objet |
|---|---|
| Route 21, prairie | Max Repousse |
| Route 21, îlot sud | Hyper Potion |
| Route 20, îlot de l'Ornithologue | Super Ball ×3 |

## 10. Cramois'Île [V décision 6, P-18, P-19, P-20, P-21]

### 10.1 Ville

- Île volcanique : roche sombre, sable noir près de l'eau, fumerolles légères au fond.
- Bâtiments : Labo blanc et moderne ; **Manoir** au nord-ouest, incendié, l'entrée effondrée ;
  **Arène** au nord-est.
- Arrivée par l'est (Route 20) ou par le nord (Route 21). **Aucun événement** (P-21) : titre de zone
  seulement.

| Lieu | Contenu |
|---|---|
| Panneau de la ville | T-40 |
| Panneau de l'Arène | T-41 |
| **Porte de l'Arène** | Sans `secret_key` : T-42, le joueur recule d'une case (RB). |
| **Manoir** | Gravats devant la porte, poutres calcinées. EXAMINER : T-43. Aucun warp. |
| Fille (marche) | T-44 |
| Homme | T-45 |

### 10.2 Centre Pokémon

- Gabarit existant ; le Centre devient le point de retour.
- PNJ : Topdresseuse (T-46), Gentleman (T-47, dit autre chose que les échanges).
- Le Pokémon qui apprend après une évolution annulée (RB) est hors sujet : il n'est pas repris.

### 10.3 Boutique

- Gabarit existant. Inventaire RB, limité aux objets qui existent : Hyper Ball, Super Ball, Hyper
  Potion, Max Repousse, Corde Sortie, Total Soin, Rappel. Ceux qui manquent sont créés en 24.0.
- PNJ : employée Sylphe (T-48), scientifique (T-49).

### 10.4 Labo Pokémon

| Salle | Contenu |
|---|---|
| Hall | Pêcheur expert (T-50) ; photo du fondateur, EXAMINER : T-51 (« Dr Fuji », sans rien de plus) |
| Salle de réunion | Les 3 PNJ des échanges, **sans échange** : T-52, T-53, T-54 (ils parlent de leur Pokémon) |
| Salle R&D | Scientifique : **CT35 Métronome**, une fois (`got_tm35`), « Sac plein » géré : T-55, T-56 ; scientifique d'Évoli : T-57 ; PC : T-58 |
| Salle des fossiles | Scientifique : **résurrection** (§10.5) |

### 10.5 Résurrection des fossiles (RB) [P-18]

1. Parler au scientifique avec un fossile dans le Sac (`dome_fossil` ou `helix_fossil`) : T-60, puis
   le choix du fossile (un seul possible en pratique) → OUI / NON.
2. Avec OUI : le fossile est retiré, `fossil_reviving_kabuto` ou `fossil_reviving_omanyte` est posé,
   puis T-61 (« va faire un tour »).
3. **Quand le joueur ressort sur la carte de Cramois'Île** (RB), le drapeau `fossil_ready` est posé.
4. Au retour, T-62 : le scientifique donne le Pokémon **N30** par `PokemonGift` (équipe, ou Stockage
   si elle est pleine), puis efface les drapeaux.
5. Le don est **idempotent** : le drapeau n'est effacé qu'après que le Pokémon est écrit, dans la
   même sauvegarde.
6. Sans fossile : T-63.

### 10.6 CT35 Métronome [P-19]

L'effet de **Métronome** est codé au J24 :
- il lance une capacité tirée au hasard parmi **les capacités implémentées du jeu** ;
- sont exclues : Métronome, Lutte, et celles marquées `pending_effects` ;
- comportement RB : la capacité tirée est lancée comme si le Pokémon la connaissait.

## 11. Rencontres sauvages [P-11, P-12]

| Lieu | Terrain | Taux | Table |
|---|---|---|---|
| Routes 19, 20, 21, Cramois'Île, côte sud de Parmanie et de Bourg Palette | `water` | 5 (RB) | **Tentacool** N25–35 [D] (RB : N5–40) |
| Route 21, prairie | `grass` | 25 (RB) | Rattata 21/23, Roucool 21/23, Rattatac 30, Roucoups 30/32, Saquedeneu 28–32 (RB) |
| Îles Écume, sol | `floor` (J19) | 15 au 1F, 10 ailleurs (RB) | **Union Rouge + Bleu** par étage (tables complètes de la passe, §2.3) : Otaria, Ramoloss, Psykokwak, Kokiyas, Stari, Hypotrempe, Krabby, Nosferapti (1F), Nosferalto, et une rareté par étage (Akwakwak, Flagadoss, Lamantine, Hypocéan, Krabboss). Niveaux RB 21–39. |
| Îles Écume, eau | — | 0 (RB) | Aucune rencontre en Surf |

**Fusion des deux versions** : à chaque étage, l'union des espèces de Rouge et Bleu. Les poids sont
la moyenne des deux tables, arrondie à la règle `weight` existante. Les niveaux sont ceux de RB.
Les tables sont écrites au plan.

## 12. Fin du jalon [V décision 7, P-17]

- Aucun événement forcé, aucun objectif nouveau.
- Le joueur circule librement entre Parmanie, la mer, les Îles Écume, Cramois'Île et Bourg
  Palette.
- **Bourg Palette** :
  - la mère du joueur a une réplique nouvelle si le joueur arrive par la mer (T-70, une fois,
    drapeau `mom_saw_surf`) [D] ;
  - rien d'autre ne change.

## 13. Données, systèmes et sauvegarde

### 13.1 Nouveaux systèmes (logique pure d'abord, règle 8)

| Système | Rôle | Tests |
|---|---|---|
| `SurfRules` | conditions, montée, descente, case « Surf forcé », garde-fou de chargement | unitaires |
| `PlayerMount` (état du joueur) | marche / Vélo (J22) / Surf, compagnon rentré | unitaires + intégration |
| Grille : eau surfable | caractère distinct, `GroundMask` | contrôle de grille |
| `EncounterTable` terrain `water` | rencontres en Surf | unitaires |
| `BoulderRules` | poussée, refus, chute | unitaires |
| `SeafoamState` | état de chaque étage depuis les 8 drapeaux | 256 combinaisons |
| `CurrentField` | courants en cases, coupés par drapeaux, glissade `SpinSlide` | unitaires |
| Étape `wild_battle` | celle du J21, réutilisée | J21 |
| `fossil_revival` | dépôt, attente, don idempotent | unitaires |
| Effet `metronome` | tirage et exécution | combat |

### 13.2 Drapeaux

| Drapeau | Posé quand |
|---|---|
| `seafoam_{1f,b1f,b2f,b3f}_hole_{1,2}_filled` (8) | Un rocher tombe dans ce trou |
| `articuno_done` | Capture ou K.O. |
| `articuno_caught` | Capture |
| `got_tm35` | CT35 reçue |
| `fossil_reviving_kabuto` / `fossil_reviving_omanyte` | Fossile confié |
| `fossil_ready` | Sortie sur la carte de Cramois'Île pendant la résurrection |
| `mom_saw_surf` | Réplique T-70 dite |
| `beat_route_{19,20,21}_*` | Dresseurs (règle existante) |

- Objets trouvés : `found_items` (existant).
- Position : champ `surfing` et dernière case de terre (§5.7).
- **Aucune position de rocher sauvegardée.**

### 13.3 Sauvegardes forcées

Sauvegarde forcée après :
- la chute d'un rocher ;
- la fin du combat d'Artikodin (avant tout texte) ;
- le don du Pokémon ressuscité ;
- la remise de la CT35.

## 14. Espèces, capacités, objets et art

### 14.1 Espèces

| À créer (données + dos repeint) | Remarque |
|---|---|
| Tentacruel, Têtarte, Poissoroy, Crustabri, Hypocéan, Otaria, Lamantine, Ramoloss, Flagadoss, Psykokwak, Akwakwak, Krabby, Krabboss | Rencontres et Dresseurs |
| **Artikodin** | Légendaire, N50 |
| Kabuto, Amonita | Résurrection |
| Tentacool, Ptitard (J21), Rapasdepic, Saquedeneu (J20), Léviator (J19) | À fusionner ; vérifier Rapasdepic |

Évolutions par niveau des nouvelles espèces : règles existantes. Les évolutions par pierre ou par
échange (Têtarte → Tartard, Kokiyas → Crustabri par Pierre Eau) suivent les règles du J11.

### 14.2 Capacités

- `surf`, `strength` (J23).
- Celles des nouvelles espèces jusqu'au niveau 40, auditées au plan. Un effet absent donne un
  remplacement explicite, comme pour Major Bob. Candidats : Écume, Ligotage, Acidarmure, Repli,
  Entrave, Coud'Krâne, Pince-Masse, Guillotine, Cage-Éclair, Brume.
- **Métronome** (effet, §10.6).
- **Artikodin N50 n'a besoin d'aucune capacité nouvelle** (Picpic, Laser Glace).

### 14.3 Objets

`tm35` (CT35 Métronome) ; Hyper Ball, Max Repousse, Total Soin, Rappel, Hyper Potion, Max Élixir,
Pépite s'ils n'existent pas encore.

### 14.4 Art (lot 24.0)

| Asset | Note |
|---|---|
| Vues générales peintes + plans : Routes 19, 20, 21, Cramois'Île ; 5 étages des Îles Écume | Procédé habituel ; la grille fait foi |
| Kit de grotte glacée | Base : Mont Sélénite et Grotte Sombre |
| Eau surfable, courant (écume orientée), eau calme | |
| Monture de Surf, joueur en Surf | 4 directions, ondulation |
| Nageur, Nageuse, Topdresseur, Ornithologue, Pêcheur, Scientifique | Planches PNJ |
| Rocher de Force, rocher tombé dans l'eau, trou bouché | |
| Artikodin dans le monde | Posé, ailes repliées, souffle |
| Fonds de combat : mer ouverte, grotte glacée | |
| Intérieurs : Labo de Cramois'Île (4 pièces) | Centre et Boutique : gabarits existants |
| Dos de combat des espèces du §14.1 | Rendu X/Y repeint |

## 15. Lot de textes — VALIDÉ par Kevin (2026-10-16)

> Ton du projet : court, simple, lisible sur téléphone. Les noms sont des valeurs par défaut.

### 15.1 Surf et Force

| # | Texte |
|---|---|
| T-1 | « L'eau est profonde. Un Pokémon pourrait vous porter. » |
| T-2 | (variante : CS sans badge) « Il faut le Badge Âme pour utiliser Surf hors des combats. » |
| T-3 | « {Pokémon} vous porte sur l'eau ! » (première fois seulement ; ensuite, rien) |
| T-4 | (menu Équipe, pas face à l'eau) « Impossible ici. » |
| T-5 | « Un gros rocher. Il pourrait être déplacé. » |
| T-6 | (variante : CS sans badge) « Il faut le Badge Prisme pour utiliser Force hors des combats. » |
| T-7 | « {Pokémon} utilise Force ! Les rochers peuvent être déplacés. » |

### 15.2 Îles Écume

| # | Texte |
|---|---|
| T-11 | (panneau, entrée des étages à rochers) « Les rochers déplacés reprennent leur place quand on quitte la grotte. » |
| T-12 | (B4F, RB) « Les rochers peuvent changer le cours de l'eau ! » |
| T-13 | (B4F, RB) « DANGER ! Courant rapide ! » |
| T-14 | (SURFER refusé, RB) « Le courant est beaucoup trop fort ! » |
| T-15 | (rocher qui tombe, première fois) « Le rocher a dévalé dans le trou ! » |

### 15.3 Artikodin

| # | Texte |
|---|---|
| T-20 | « Gyaoo ! » |
| T-21 | (après un K.O.) « Artikodin s'est envolé vers le large… » |

### 15.4 Routes

| # | Texte |
|---|---|
| T-30 | (panneau, Route 19) « ROUTE MARINE 19 — Parmanie ↑ · Îles Écume ← » |
| T-31 | (panneau, Route 20) « ÎLES ÉCUME — grottes glaciales, accès par la mer » |

**Dresseurs** (avant / défaite / après) :

| Dresseur | Avant | Défaite | Après |
|---|---|---|---|
| Topdresseur Hugo | « On s'échauffe avant la baignade ! » | « J'ai pris froid avant d'entrer dans l'eau… » | « Toujours s'échauffer. Toujours. » |
| Topdresseur Malo | « Tu viens nager ? Un combat d'abord ! » | « Bon. J'y vais seul. » | « L'eau est plus froide qu'elle n'en a l'air. » |
| Nageur Yann | « L'eau est glacée par ici ! » | « Brrr… » | « On dit que le froid vient des îles. » |
| Nageur Erwan | « Attention aux Tentacool ! » | « Piqué au vif ! » | « Les Tentacool adorent ces eaux. » |
| Nageur Loïc | « Tu vois les îles, là-bas ? » | « Je n'ai plus d'élan… » | « Les Îles Écume sont plus loin qu'on croit. » |
| Nageur Tanguy | « Nager ou combattre, il faut choisir ! » | « J'aurais dû nager. » | « Garde des forces pour le retour. » |
| Nageuse Maëlle | « Mes Pokémon nagent mieux que moi ! » | « Ils ont fait de leur mieux. » | « Pour trouver d'autres Pokémon marins, il faut pêcher. » |
| Nageuse Anaïs | « Pas d'éclaboussures, s'il te plaît ! » | « Trop tard. » | « Bon, je retourne à la plage. » |
| Nageur Gwen | « Personne ne passe sans un combat ! » | « Bon, passe. » | « Les îles sont encore loin. Courage ! » |
| Nageuse Léna | « Trois Stari, trois fois plus d'étoiles ! » | « Elles ont filé… » | « La nuit, la mer brille par ici. » |
| Nageur Ronan | « Sous l'île, il y a une immense caverne. » | « Tu nages vite ! » | « Ses grottes sont pleines de glace. » |
| Nageuse Solène | « Mes Hypocéan sont prêts ! » | « Ils se sont cachés… » | « Le courant tire vers les grottes, fais attention. » |
| Nageuse Iris | « Tu m'as trouvée ? Personne ne vient jamais ici. » | « Tu méritais d'arriver jusqu'ici. » | « C'est mon coin secret. Garde-le pour toi. » |
| Nageuse Lou | « On dit que ces îles n'en formaient qu'une, autrefois. » | « Je perds le fil… » | « La mer a dû les séparer. » |
| Nageur Mathis | « Une seule étoile, mais elle brille fort ! » | « Éteinte… » | « Mon Stari, c'est ma boussole. » |
| Nageur Kilian | « Les Hypotrempe, c'est ma passion ! » | « Ma passion a coulé. » | « Ils nagent en se tenant droits. Fascinant. » |
| Ornithologue Bastien | « Mes oiseaux ne peuvent pas me ramener. Alors combattons ! » | « Pas de vent pour moi aujourd'hui. » | « Je suis coincé sur ce rocher. Ils ne savent pas encore voler assez loin. » |
| Nageuse Clara | « Mes Kokiyas sont durs comme la pierre ! » | « Ils se sont refermés… » | « On trouve des Kokiyas partout dans ces eaux. » |
| Nageuse Nina | « Cramois'Île ? Tout droit vers l'ouest. » | « Je me suis trompée de direction… » | « Il y a un Labo célèbre là-bas. » |
| Nageuse Elsa | « On dit qu'un manoir abandonné se cache sur Cramois'Île. » | « Ça me donne des frissons. » | « Je n'irais pas là-bas seule. » |
| Pêcheur Gilles | « Ça mord ? Non. Alors un combat ! » | « Toujours rien… » | « La patience, c'est la moitié de la pêche. » |
| Pêcheur Marcel | « Six Magicarpe. Tu vas voir. » | « …Tu as vu. » | « Un jour, ils deviendront grands. » |
| Nageur Thibault | « Bourg Palette, ce n'est pas loin. Tu viens de là ? » | « Bien joué, voisin ! » | « Le Prof. Chen nage parfois jusqu'ici, paraît-il. » |
| Nageur Dylan | « La mer, c'est mon terrain ! » | « Ma route s'arrête ici. » | « Je rentre à Cramois'Île. » |
| Nageur Simon | « Staross, montre-lui ! » | « Joli. » | « Les étoiles de mer guérissent vite. Moi, moins. » |
| Nageur Arthur | « Mon Carabaffe est mon meilleur nageur ! » | « Il a besoin de repos. » | « Carabaffe et moi, on nage ensemble depuis toujours. » |
| Nageur Noé | « Encore un dresseur à la nage ? » | « Tu nages mieux que tu ne combats… non, les deux. » | « Le volcan réchauffe un peu l'eau près de l'île. » |
| Pêcheur René | « Ne fais pas fuir les poissons ! » | « Ils sont partis de toute façon. » | « Les Kokiyas mordent mieux par temps gris. » |
| Pêcheur Yves | « Un combat entre deux touches ? » | « Ça ne mord pas, et je perds. » | « La mer d'ici est généreuse. Un jour. » |

### 15.5 Cramois'Île

| # | Texte |
|---|---|
| T-40 | (panneau) « CRAMOIS'ÎLE — l'île au cœur de feu » |
| T-41 | (panneau) « ARÈNE DE CRAMOIS'ÎLE — Champion : Auguste, le maître du feu et des énigmes » |
| T-42 | (porte, RB) « La porte est fermée à clé… » |
| T-43 | (Manoir) « L'entrée s'est effondrée. Personne ne peut entrer. » |
| T-44 | (fille) « Auguste vit sur l'île depuis des dizaines d'années. Un drôle de bonhomme ! » |
| T-45 | (homme) « Ce vieux manoir a brûlé il y a longtemps. Plus personne n'y va. » |
| T-46 | (Centre, Topdresseuse, RB) « Tu peux empêcher un Pokémon d'évoluer en appuyant sur ARRÊTER pendant l'évolution. » |
| T-47 | (Centre, Gentleman) « On vient de loin pour le Labo. Moi, je viens pour la vue. » |
| T-48 | (Boutique, employée Sylphe) « Je suis en vacances. Mais je regarde quand même les rayons. » |
| T-49 | (Boutique, scientifique, RB) « Des objets en plus, ça ne fait jamais de mal ! » |

### 15.6 Labo Pokémon

| # | Texte |
|---|---|
| T-50 | (Pêcheur expert, RB) « Ici, on étudie les Pokémon rares. Des chercheurs du monde entier viennent travailler sur l'île. » |
| T-51 | (photo) « Le fondateur du Labo : le Dr Fuji. » |
| T-52 | (salle de réunion, Papy) « Mon Électrode s'appelle Doris. Elle ne tient pas en place ! » |
| T-53 | (salle de réunion, Canon) « Les Saquedeneu sont plus doux qu'ils n'en ont l'air. » |
| T-54 | (salle des fossiles, scientifique d'Otaria) « Otaria adore l'eau froide des Îles Écume. » |
| T-55 | (CT35) « Tu aimes les surprises ? Cette CT apprend Métronome : une capacité au hasard, à chaque fois ! » → « {joueur} reçoit la CT35 ! » |
| T-56 | (après) « Avec Métronome, même moi, je ne sais jamais ce qui va arriver. » |
| T-57 | (scientifique d'Évoli, RB) « Évoli peut évoluer de trois façons différentes. Fascinant ! » |
| T-58 | (PC, RB réécrit) « Un courriel : “Trois Pokémon oiseaux légendaires vivraient à Kanto. On parle de l'un d'eux près des Îles Écume…” » |

### 15.7 Résurrection

| # | Texte |
|---|---|
| T-60 | « Je recrée des Pokémon à partir de fossiles. Tu en as un ? » → choix du fossile → « Je te le prends ? » OUI / NON |
| T-61 | « Bien. Ça prend un peu de temps : va faire un tour dehors ! » |
| T-62 | « Te voilà ! Ton fossile était un {espèce} ! » → « {joueur} reçoit {espèce} ! » |
| T-63 | « Sans fossile, je n'ai rien à recréer. Il paraît qu'on en trouve au Mont Sélénite. » |
| T-64 | (le joueur revient sans être sorti) « Patience ! Va faire un tour. » |

### 15.8 Bourg Palette

| # | Texte |
|---|---|
| T-70 | (mère, une fois) « Tu es arrivé par la mer ?! Tu as vraiment beaucoup grandi. » |

## 16. Cas limites (à couvrir au plan technique)

1. Sauvegarde sur l'eau, puis le Pokémon de Surf est relâché ou déposé ailleurs (simulé) → garde-fou
   sur la dernière case de terre.
2. Chargement d'une sauvegarde sur une case de courant (impossible par `is_stable`, testé quand
   même) → case d'arrivée du courant.
3. Fermeture pendant la chute d'un rocher → soit avant (rocher libre, remis à sa place), soit après
   (drapeau posé) ; jamais un rocher perdu.
4. Fermeture pendant le combat d'Artikodin → avant l'interaction ; aucune duplication.
5. Capture d'Artikodin, équipe pleine → Stockage.
6. Fuite, puis nouvelle rencontre → combat identique, PV et statut d'Artikodin remis à neuf.
7. Joueur au B4F, mer est, courant 2 actif : la salle d'Artikodin reste inaccessible ; une sortie
   existe (escaliers, échelles).
8. Saut dans un trou du B2F, courant 1 actif → emporté au B4F ; il ressort.
9. Fossile confié, puis le joueur quitte l'île par la mer sans repasser par la ville → `fossil_ready`
   est posé quand même (sortie de la carte de la ville).
10. Fossile confié, Sac et équipe pleins → Stockage.
11. Combat d'un Nageur pendant que le joueur est en Surf → retour en Surf après le combat.
12. Défaite en mer → réveil au Centre, à pied.
13. Vélo en main, SURFER → Vélo rangé, compagnon dans sa Ball, puis à terre à pied.
14. Bourg Palette → Route 21 en Surf, puis retour : le Surf est gardé par le bord.
15. Force active, combat sauvage, retour → Force toujours active (RB).
16. Rocher poussé contre une échelle → refus.
17. Les 256 combinaisons des 8 drapeaux → étages valides, solution toujours possible.

## 17. Découpage et validation S24 [P-22]

### 17.1 Lots

| Lot | Contenu | Validation |
|---|---|---|
| **24.0** | Grilles (7 cartes + 4 intérieurs du Labo), vérification sur émulateur du trajet du courant et de la solution, vues peintes, données des espèces et capacités, objets, art | Kevin sur planches (grilles, vues) |
| **24A — Surf** | `SurfRules`, `PlayerMount`, eau surfable, verbe SURFER, rencontres `water`, fond mer, Nageurs, transitions, garde-fou ; **carte d'essai** puis Routes 19–20 | **S24, seul** |
| **24B — La mer** | Route 21, Cramois'Île, Centre, Boutique, Labo, fossiles, CT35, Métronome, côtes de Parmanie et de Bourg Palette, Manoir et Arène fermés | S24 |
| **24C — Îles Écume** | `BoulderRules`, `SeafoamState`, `CurrentField`, trous, 5 étages, objets, rencontres ; rocher du Gardien (Parmanie) | **S24, seul** |
| **24D — Artikodin + QA** | Rencontre, issues, sauvegarde forcée ; QA de bout en bout et non-régression | S24 |

### 17.2 QA S24

- **24A** : monter, descendre, traverser les Routes 19–20, un Nageur, une rencontre, fermer
  l'application en mer.
- **24B** : la boucle Parmanie → mer → Cramois'Île → Route 21 → Bourg Palette ; un fossile.
- **24C** : le donjon résolu, sortir, revenir, recharger au milieu d'un étage.
- **24D** : Artikodin (fuite, puis capture), Stockage plein.

Time-box ≈ 30–45 min par session, avec des départs de débogage.

### 17.3 Avant la fusion du J23

Ce travail peut avancer, sur une branche partie de l'intégration J16–J22 :
- 24.0 en entier ;
- `SurfRules`, `BoulderRules`, `SeafoamState`, `CurrentField` en logique pure ;
- les cartes d'essai ;
- l'effet Métronome.

La CS03 et la CS04 sont remplacées dans les tests par des données d'essai.

**Règle d'ancienneté de Kevin (2026-10-16)** : le J24 ne modifie pas un système sur lequel une
session plus ancienne (J15 à J23) travaille déjà. Les points concernés :
- l'état « monté » (Vélo, J22) : `PlayerMount` s'appuie dessus, sans le réécrire ;
- `FieldMoves` et les CS (J16, J17, J23) ;
- l'étape `wild_battle` (J21) ;
- la glissade `SpinSlide` (J20) ;
- Parmanie (J22, J23).

Si l'un d'eux doit changer, le J24 attend, puis demande à Kevin.

## 18. Valeurs par défaut (règle 4)

| Sujet | Valeur |
|---|---|
| Échelle | Routes et ville ×1,5 ; Îles Écume 1:1 |
| Vitesse en Surf | ≈ 1,15 × la marche, pas de course |
| Poussée | direction tenue 0,25 s |
| Glissade de courant | ≈ 2 × la marche |
| Intro légendaire | bandeau ≈ 1,5 × plus lent |
| Tentacool en Surf | N25–35 |
| Objets visibles | Max Repousse, Hyper Potion, Super Ball ×3 |
| Noms des Dresseurs | ceux du §9.4 |
| Réplique de la mère | T-70, une fois |

## 19. Grilles v1 (lot 24.0) — à produire

Elles seront dans `tools/plans/` : `route_19.txt`, `route_20.txt`, `route_21.txt`,
`cinnabar_island.txt`, `seafoam_1f.txt` … `seafoam_b4f.txt`, intérieurs du Labo. Chacune aura son
contrôle `plan_check_*.py` :
- raccords des bords ;
- atteignabilité de chaque sortie depuis chaque case ;
- eau surfable autorisée ;
- pour le donjon : recherche exhaustive des positions de rochers et preuve de l'anti-blocage (§7.6).

## Décisions verrouillées

- Les 7 décisions de la V2 et les arbitrages P-1 à P-22 (2026-10-16).
- Textes du §15 validés (2026-10-16).
- **À valider** : les grilles et les vues du lot 24.0.
