# Jalon 25 — Le secret du Manoir Pokémon : Manoir, échanges du Labo, Vieil Ambre, Arène d'Auguste

> Objectif jouable sur le téléphone : à **Cramois'Île**, le joueur explore le **Manoir Pokémon** sur
> quatre niveaux (statues qui basculent les grilles, trous dans le plancher, quatre journaux sur
> Mew et Mewtwo, six Dresseurs, objets), y trouve la **Clé Secrète**, ouvre l'**Arène d'Auguste**,
> passe ses six salles par **quiz** ou par combat, bat **Auguste** (Badge Volcan, CT38
> Déflagration) et reste libre. Au **Labo** (construit par le J24), trois PNJ proposent leurs
> **échanges fixes** ; à **Argenta**, une réserve du Musée derrière un arbre à Couper donne le
> **Vieil Ambre**, que le Labo du J24 ressuscite en **Ptéra**.
>
> Mécaniques nouvelles : **interrupteur global à deux jeux de portes**, **chute** (si le J24 n'en
> livre pas), **machine de quiz**, **échange fixe**, **porte à clé qui s'ouvre pour toujours**,
> capacités **Déflagration** et **contrecoup de Bélier**. Tout le reste est du contenu.

**Pré-requis.** Dossier 28 : arbitrages X-1 à X-24 et textes (§16) **validés par Kevin**
(2026-10-16), grilles v1 et vues générales validées (2026-10-19), réalignement sur le J24
(X-25 à X-30, dossier 28 §0) validé selon les recommandations (2026-10-19). Organisation : **une session par jalon** ; le J25 est la session **la plus récente**
(règle d'ancienneté) : il ne modifie rien de ce qu'un jalon plus ancien est en train de modifier.

Plan écrit sur `docs/dossier-28-j25`. **Code lu** : `origin/main` à **`aebbd85`** (J15, J16, J17
fusionnés ; sauvegarde **v7**) ; J24 : `origin/docs/dossier-27-j24` (`8e70db8`, dossier 27 et
`jalon-24.md`), `origin/j24-t2-mer` (grilles de Cramois'Île et du Labo), `origin/j24-t4-donnees`.
Quand un nom n'existe que dans un plan, c'est écrit « (plan) ». **Chaque tâche d'architecture
commence par réaligner ce plan sur le code du moment.**

Références : `CLAUDE.md`, `docs/design/dossier-28-cramois-ile.md`, `docs/design/passes/
j25-v2-alignement.md`, `j25-annexe-rb-cramois.md` (relevé RB), grilles `tools/plans/manoir_1f.txt`
… `manoir_b1f.txt`, `cramois_arene.txt`, `argenta_musee_reserve.txt`, contrôles
`tools/art/plan_check_manoir.py` et `plan_check_cramois.py` (verts), plans en aplats
`tools/art/plan_aplats_j25.py`.

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin

| Besoin | `origin/main` (aebbd85) | Autre jalon | Reste à faire |
|---|---|---|---|
| Portes pilotées par un drapeau | `FlagGate` + `blocking_cells` (J15), réglé à l'arrivée et à chaque drapeau | — | deux jeux A/B sur **un** drapeau (`unless_flags` existe déjà) : données seulement (§2.1) |
| Statue = Action face à elle, OUI/NON, bascule | `dialogue_choice.gd` (`confirm_set`), `switch_puzzle.gd` (J16, Carmin) | — | étape « basculer un drapeau » (§2.1) |
| Remise à zéro en entrant | `SceneRouter.arrival_flags` (J17) | — | remise à ARRÊT à l'arrivée par la porte (§2.1) |
| Escaliers | `Warp` `STEP_ON` | — | rien |
| Chute | **rien** | J24 : trous pour les **rochers** (drapeaux de chute) ; chute du **joueur** non décrite | `Warp` « chute » (§2.2), **ou** celui du J24 s'il existe à l'intégration |
| Journaux | `examen` + dialogues | — | rien (données) |
| Dresseurs, objets, cachés, Grand moment | complets | — | données |
| Rencontres en intérieur | tables `grass` / `rubble` | — | terrain « intérieur » [D] = `grass` sur toutes les cases praticables (§2.7) |
| Clé et porte | `key_item_repair.gd` (J16) | J24 : `porte_arene` (texte + recul) | ouverture pour toujours (§2.4) |
| Quiz | rien | — | `GymQuiz` (§2.3) |
| Échange fixe | `Pokemon.nickname`, `original_trainer`, `Origin {UNKNOWN, STARTER, CAPTURE}` | J20 : `PokemonGift` (pas dans `main`) | `InGameTrade` + `Origin.TRADE` (§2.5) |
| Fossiles | `dome_fossil`, `helix_fossil` | **J24 : `FossilLab`**, Kabuto, Amonita, `fossil_reviving_*` | Vieil Ambre → Ptéra (données, §2.6) |
| Coupe à Argenta | Coupe (J16), arbustes (J17) | — | un arbuste + porte arrière + réserve (§2.6) |
| Capacités | `take_down` (J17, `pending_effects: recoil_damage`), `roar` (J17), `RECOIL` codé (`battle.gd:861`) ; `fire_spin` (piège), brûlure | J20 : `stomp` | `fire_blast` ; Bélier avec `RECOIL ¼` ; `stomp` si J20 non fusionné |
| Espèces | Salamèche, Reptincel, Caninos, Goupix, Magnéti(+on), Voltorbe, Smogo, Raichu | J20 : Arcanin, Feunard, Saquedeneu ; J24 : Kabuto, Amonita | §2.8 |
| Badge, CT | `badge_volcano` dans `badges.json` ; `tm_compatibility` « 38 » → `fire_blast` | — | `tm38`, scène d'Auguste |

### 0.2 Dépendances envers les autres jalons

| Jalon | Ce que le J25 prend | État au 2026-10-19 | Tâches |
|---|---|---|---|
| **J24** | Cramois'Île (carte, Centre), Labo et ses PNJ, `FossilLab`, Kabuto, Amonita, `porte_arene`, gravats du Manoir, Surf | dossier et plan validés, **code en cours** | T15, T17, T18, T19, sessions 25A à 25C |
| J20 | `PokemonGift`, Arcanin, Feunard, Saquedeneu, Écrasement, Rappel | codé, **non fusionné** | T6, T17, T18 |
| J22 / J23 | Mimitoss (échange de Lina) | conception seulement | aucune : l'offre attend le joueur |

---

## 1. Découpage

### 1.1 Sous-jalons et validations (X-24, X-30)

| Lot | Contenu | Validation |
|---|---|---|
| **25.0** | Données, logique pure et tests, art, simulation | captures, planches |
| **25A** | Manoir complet (4 cartes, interrupteur, chutes, journaux, Dresseurs, objets, Clé) + porte du Manoir sur Cramois'Île | S24 |
| **25B** | Échanges du Labo + Vieil Ambre (Argenta) → Ptéra | S24 **seul** (un échange retire un Pokémon) |
| **25C** | Arène (porte à clé, quiz, 7 Dresseurs, Auguste, Badge Volcan, CT38) ; clôture | S24 |

### 1.2 Tâches

« (A) » = lançable maintenant depuis `origin/main` ; « (B) » = attend un autre jalon.

| Tâche | Agent | Quand | Attend | Fichiers |
|---|---|---|---|---|
| T0 Plan (ce document) | architecte | fait | — | docs |
| T1 Branche `jalon-25` + réalignement | architecte | **(A)** | — | depuis `origin/main` |
| T2 Interrupteur global : `MansionSwitch` (pur) + étape `toggle_flag` | architecte | **(A)**, après T1 | — | `game/world/puzzle/mansion_switch.gd` nouveau, `cutscene_step.gd` (une entrée) |
| T3 Chute : **réutiliser** le `Warp` `FALL` du J24 (plan J24 §2.6 bis, T15) | architecte | **(B)** | J24 fusionné | aucun fichier du J24 modifié ; données des 3 trous du 3F |
| T4 Quiz : `GymQuiz` (pur) + étape `quiz` | architecte | **(A)** | — | `game/systems/gym/gym_quiz.gd` nouveau |
| T5 Échange fixe : `InGameTrade` (pur), `Origin.TRADE`, lecture tolérante | architecte | **(A)** | — | `game/systems/trade/in_game_trade.gd` nouveau, `pokemon.gd` (énum) |
| T6 Capacités : `fire_blast`, `take_down` recoil, `stomp` ; audit des nouvelles espèces | architecte | **(A)** | J20 pour `stomp` (sinon copie identique) | `data/pokemon/moves/j25.json` nouveau |
| T7 Espèces, Pokédex, compatibilités CT (§2.8) | architecte | **(A)**, après T6 | J24 : ne pas recréer Kabuto / Amonita | `kanto_j25.json`, `pokedex` |
| T8 Objets : `secret_key`, `old_amber`, `tm38`, `max_potion`, `max_revive`, `tm14`, `tm22` | architecte | **(A)** | — | `data/items/items_j25.json` |
| T9 Dresseurs, rencontres, dialogues, simulation d'Auguste et des Dresseurs | architecte | **(A)**, après T6, T7 | — | `data/trainers/cinnabar_*.json`, `data/encounters/pokemon_mansion_*.json`, `data/dialogues/` |
| T10 Kit d'assets (série à réserver au moment du push) : fiche, prompts | architecte | **(A)** | vues générales (à valider) | `docs/design/fiches-assets/serie-NN-cramois.md` |
| T11 Génération Codex → planches | constructeur-monde (Mac) | **(A)**, après T10 | — | `build/art/` |
| T12 Dos de combat (14, méthode Colab) | constructeur-monde (Mac) | **(A)** | — | images |
| T13 Intégration de l'art | constructeur-monde | **(A)**, après T11, T12 | — | entrées en fin de fichier |
| T14 Cartes du Manoir (4) depuis les grilles | constructeur-monde | **(A)**, après T2, T3, T13 | — | `tools/build_pokemon_mansion.gd` nouveau |
| T15 Porte du Manoir sur Cramois'Île (X-25) | constructeur-monde | **(B)** | **J24** fusionné | grille et outil du J24 : **un bloc**, accord de Kevin (X-25) |
| T16 Session 25A | qa-mobile | **(B)** | T14, T15 | — |
| T17 Échanges sur les PNJ du Labo (X-26 ; identifiants J24 `papy`, `canon`, `scientifique_otaria`) | constructeur-monde | **(B)** | J24 fusionné, T5 | dialogues des 3 PNJ |
| T18 Vieil Ambre : Argenta (arbuste, porte arrière, réserve), ligne `old_amber` du `FossilLab` | constructeur-monde | **(B)** | J24 (`FossilLab`) fusionné ; J20 (`PokemonGift`) | `argenta.txt` (variante J25), `build_argenta_reserve.gd` |
| T19 Session 25B | qa-mobile | **(B)** | T17, T18 | — |
| T20 Arène : carte, herses, machines, Dresseurs | constructeur-monde | **(A)**, après T4, T13 | — | `tools/build_cinnabar_gym.gd` |
| T21 Porte à clé + scène d'Auguste (badge, CT38, Dresseurs battus) | constructeur-monde | **(B)** pour la porte | J24 (`porte_arene`) | cutscene `cinnabar_gym.json` |
| T22 Session 25C | qa-mobile | après T20, T21 | — | S24 |
| T23 Clôture | architecte | fin | — | docs, retrait des cartes de QA |

Cartes de QA [D] : `qa_manoir` (départ au 1F avec Clé ou sans, interrupteur au choix),
`qa_cramois` (équipe avec Raichu, Ponyta, Vieil Ambre, Clé). Retirées au T23.

---

## 2. Conception technique

### 2.1 Interrupteur global et portes A/B (T2, T14)

- **Drapeau** `mansion_switch_on` (`StoryFlags`).
- **Portes** : une `FlagGate` par porte (2 × 2 cases), `blocking_cells` = ses cases.
  Jeu A (`a`) : bloque **sans** le drapeau (`unless_flags = [mansion_switch_on]`) ; jeu B (`b`) :
  bloque **avec** (`if_flags`). Images : grille fermée / rail au sol.
- **Statue** : `InteractPoint` bloquant, Action seulement **face à elle** (case du dessous,
  `facing=up`), scène : texte 9 → OUI/NON → OUI : texte 10, étape **`toggle_flag`**
  (`mansion_switch_on`), son ; NON : texte 11.
- `MansionSwitch` (pur) : `toggle(flags)`, `reset_on_entry(flags, from_map)` (remise à ARRÊT si l'on
  arrive depuis `cinnabar_island`), testé sans scène.
- Remise : `SceneRouter.arrival_flags` sur les deux warps d'entrée du 1F ; jamais aux escaliers,
  aux chutes ni au chargement.
- Un joueur **dans** une case de porte au moment du basculement : impossible (la statue est
  actionnée depuis une case qui n'est jamais une porte, vérifié par `plan_check_manoir.py`).

### 2.2 Chute (T3)

- **Confirmé par la session du J24 (2026-10-19)** : le J24 code un `Warp` générique de type
  **`FALL`** (petit saut, fondu, arrivée sur `target_spawn`, trou bouchable par drapeau
  `unless_flags`), sans règle propre aux Îles Écume (`jalon-24.md` §2.6 bis, T15, lot 24C). Le J25
  le **réutilise tel quel** pour les trois trous du 3F ; il ne le modifie pas (règle d'ancienneté).
- Le compagnon et l'autosave suivent la règle du `FALL` du J24.

### 2.3 Quiz de l'Arène (T4, T20)

- `GymQuiz` (pur) : `ask(n) -> {question, answer}` depuis `data/gym/cinnabar_quiz.json` (6 entrées :
  texte, réponse `yes` / `no`, herse, Dresseur) ; `resolve(n, answer, flags) -> {RIGHT, WRONG_FIGHT,
  WRONG_ALREADY_BEATEN, ALREADY_OPEN}`.
- Étape de scène **`quiz`** : intro (texte 80) → question → OUI/NON → selon le résultat : `set`
  `cinnabar_gym_gate_<n>` (texte 87) ; ou texte 88, le Dresseur **marche jusqu'au joueur**
  (déplacement de PNJ existant), combat, victoire → `set` herse.
- Défaite : chemin habituel (Centre) ; la herse reste fermée.
- Herses : `FlagGate` 2 × 2 avec `unless_flags = [cinnabar_gym_gate_<n>]`.
- Dresseurs de l'Arène : `sight = 0` (on leur parle).

### 2.4 Porte à clé (T21)

- La porte du J24 (`porte_arene`, texte + recul) reçoit une branche : **avec** `secret_key` et sans
  `cinnabar_gym_unlocked` → textes 76–77, `set cinnabar_gym_unlocked` ; **avec** le drapeau → warp
  vers `cinnabar_gym`. Un bloc dans les données du J24, **après sa fusion** (X-29).
- `key_item_repair` : `got_pokemon_mansion_b1f_item_5` posé et `secret_key` absente → rendue.

### 2.5 Échange fixe (T5, T17)

- `InGameTrade.offer(party, trade_data) -> {NO_SPECIES, CANDIDATES[]}` ;
  `InGameTrade.execute(state, trade_data, party_index) -> {DONE, ALREADY_DONE, WRONG_SPECIES}`.
- `execute`, **un seul bloc synchrone** : retirer le compagnon s'il s'agit de lui (règle J11) ;
  créer le Pokémon reçu (`PokemonFactory`, niveau du Pokémon donné, IV tirés, surnom fixe,
  `original_trainer` = prénom du PNJ, `origin = TRADE`) ; le mettre **à la même place** dans
  l'équipe ; Pokédex vu + capturé ; rencontre ; `set cinnabar_trade_<id>_done`.
- Données : `data/trades/cinnabar.json` (3 entrées : PNJ, espèce voulue, espèce donnée, surnom,
  jeux de répliques).
- Sélection : sélecteur de cible existant (Super Bonbon), filtré sur l'espèce.
- **Sauvegarde** : `Origin.TRADE` ajouté **en fin** d'énumération ; la lecture d'une valeur inconnue
  donne `UNKNOWN` (test). Pas de changement de version.

### 2.6 Vieil Ambre (T18)

- `old_amber` (objet clé). La liste des fossiles du J24 est **en données** (`data/world/fossils.json` :
  fossile → espèce, drapeau ; `FossilLab` ne connaît aucune espèce). Le J25 y ajoute **une ligne**
  (`old_amber` → `aerodactyl`, `fossil_reviving_aerodactyl`), rien d'autre ; accord de Kevin (X-27).
- Argenta : variante J25 de `argenta.txt` (modèle des variantes `J14`) : arbuste à Couper devant
  une porte arrière sur la façade est du Musée ; grille `argenta_musee_reserve.txt` ; scientifique
  qui donne l'ambre (`pewter_museum_got_old_amber`).

### 2.7 Manoir : cartes, rencontres, objets (T9, T14)

- `tools/build_pokemon_mansion.gd` lit les 4 grilles (légende `# . a b U V O E T P`).
- Rencontres : 4 tables `pokemon_mansion_<étage>` (dossier 28 §4.7), terrain `grass` sur toutes les
  cases `.`, hors seuils et trous ; fond de combat `manoir_salle`.
- Corde Sortie / Tunnel : `field_item_rules.gd`, carte de sortie = `cinnabar_island`, devant la
  porte du Manoir.

### 2.8 Données (T6, T7, T8, T9)

| Type | Contenu |
|---|---|
| Espèces nouvelles | Ponyta, Galopa, Tadmorv, Grotadmorv, Smogogo, Magmar, Électrode, Otaria, Lamantine, Ptéra (Kabuto, Kabutops, Amonita, Amonistar : **J24**, `kanto_j24.json`, à reprendre) ; Arcanin, Feunard (si J20 non fusionné : mêmes données) |
| Capacités | `fire_blast` (110, 85 %, 5 PP, brûlure 10 %), `take_down` (90, 85 %, `RECOIL ¼`), `stomp`, `blizzard` et `solar_beam` si les CT14 / CT22 sont gardées |
| Objets | `secret_key`, `old_amber`, `tm38`, `tm14`, `tm22`, `max_potion`, `max_revive` |
| Dresseurs | 6 du Manoir, 7 de l'Arène, Auguste (dossier 28 §4.6, §8.3, §8.4) |
| Dialogues | textes validés du dossier 28 §16, moins ceux retirés au §0 |
| Simulation | outil des jalons précédents : Auguste **35–60 %**, Dresseurs **≤ 80 %** ; écart → Kevin |

### 2.9 Art (T10 à T13)

| Lot | Contenu |
|---|---|
| Cartes peintes | Manoir 1F, 2F, 3F, B1F ; Arène ; réserve du Musée ; façade est du Musée |
| Objets | statue, grilles A/B, trou, pupitre et carnet, machine de quiz, herse (2 états), vitrine d'ambre |
| PNJ | Pillard, Intello, guide de l'Arène, Auguste + carte de Champion (Scientifique : existant) |
| Combat | 14 dos (§2.8) ; décors `manoir_salle`, `arene_cramois` |

Vues générales validées (2026-10-19) : `docs/design/reference/manoir-vue-generale-v1.png` et
`cramois-arene-vue-generale-v1.png` (+ leurs plans) : DA et composition ; la grille fait foi.
Numéro de série d'art : réservé au moment du push, après vérification de toutes les branches
distantes (règle d'ancienneté).

---

## 3. Tests et critères d'acceptation

- **GUT** : `MansionSwitch` (bascule, remise à l'entrée, pas au chargement) ; portes A/B (image +
  `blocking_cells`) ; chute (arrivée, compagnon) ; `GymQuiz` (4 issues) ; `InGameTrade` (espèce,
  refus, annulation, niveau, surnom, dresseur d'origine, compagnon, une seule fois, atomicité,
  lecture d'une origine inconnue) ; porte à clé et réparation ; Badge et CT38 uniques ; journaux
  sans effet sur le Pokédex ; Vieil Ambre unique ; `old_amber` → Ptéra dans le `FossilLab`.
- **Grilles** : `plan_check_manoir.py`, `plan_check_cramois.py` dans `tools/test.sh` (comme les
  contrôles des jalons précédents).
- **Sauvegarde** : rechargement à chaque étape d'un échange et de la remise de l'ambre.
- **QA téléphone** bornée (~30–45 min, départs de débogage) pour 25A, 25B, 25C.
- Critère de fin (V2) : explorer le Manoir, prendre la Clé, échanger, ressusciter le Vieil Ambre,
  battre Auguste, continuer librement.

## 4. Questions ouvertes

| N° | Question | Où |
|---|---|---|
| — | Chute du joueur au J24 ? (lecture au T3) | §2.2 |
