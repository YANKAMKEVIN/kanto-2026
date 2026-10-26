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
| J22 / J23 | Mimitoss (échange de Lina) | conception seulement (2026-10-19) ; **dans `main` depuis le J22** | aucune : l'échange de Lina marche (QA 25B) |

---

## 0.4 Nuit du 2026-10-21/22 : intégration sur le J24 (branche locale `j25-nuit`, poussée sur `jalon-25`)

Worktree `~/dev/kanto-2026-wt-j25`. **Fusion de `origin/jalon-24`** (J24 + `systemes-2`) : le `Warp`
FALL, `FossilLab`, le Labo en 4 pièces et Cramois'Île du J24 font foi, réutilisés tels quels.
Textes recommandés « validés par Kevin le 2026-10-21, validation d'avance ».

| Tâche | État |
|---|---|
| T2 interrupteur | fait : étape de scène `toggle` (et `unset`), statue OUI/NON → scène `mansion_switch` ; remise à ARRÊT par `MansionSwitchReset` posé **sur Cramois'Île** (on n'entre que par l'île : équivalent RB, rien aux escaliers, chutes ni au chargement dans le Manoir) |
| T3 chute | fait : `Warp` FALL du J24, sans modification |
| T4 quiz | fait en données : chaque machine = scène (intro, question OUI/NON, bonne réponse → herse ; mauvaise → le Dresseur lié marche jusqu'au joueur et combat ; victoire → herse). Herse ouverte par `cinnabar_gym_gate_N` **ou** `beaten_<Dresseur lié>` (lui parler directement ouvre aussi). `GymQuiz` reste la logique pure de contrôle |
| T5 échange | fait : étape `trade`, `Origin.TRADE`, `TradeOverlay` (sélecteur de l'équipe, places de l'espèce demandée seules utilisables), compagnon rafraîchi, autosave |
| T6–T9 données | faites (sous-agent) : 4 espèces, reprises J22 (Tadmorv, Grotadmorv, Smogogo, Électrode, à supprimer à la fusion du J22), Déflagration, Poing de Feu, 7 objets, 14 Dresseurs, 4 tables « floor », dialogues §16. Bélier : contrecoup déjà réel (E-3 sans objet) |
| T10–T13 art | **non intégré** : aplats provisoires (`OverworldTiles`), décors de combat de la Tour et de l'Arène de Carmin [D] ; Pillard = `gambler`, Auguste = `gentleman` [D] |
| T14 Manoir | fait : `tools/build_pokemon_mansion.gd` (grilles A/B, statues, pupitres, escaliers, trous, seuils, caches) ; Manoir = « grotte » (`caves.json` : Corde Sortie devant la porte) ; `tools/gen_j25_world_data.py` (PNJ, objets, scènes, depuis les grilles) |
| T15 porte du Manoir | fait (X-25) : warp sur les cases X de Cramois'Île, T-43 retiré, `plan_check_j24_mer.py` aligné |
| T17 échanges | faits sur Papy (Hector), Canon (Lina), scientifique des fossiles (Marc) ; T-52 à T-54 retirés. Lina (Mimitoss) : l'espèce vient du J22 (fusionné le 2026-10-23), échange testé en QA 25B ; sans Mimitoss dans l'équipe, l'offre répond « ce n'est pas un Mimitoss » |
| T18 Vieil Ambre | fait : porte arrière du Musée (PUSH ← depuis (15, 34)), arbre à Couper, `tools/build_j25_rooms.gd` (réserve), ambre donné une fois, `old_amber` → Ptéra N30 dans `fossils.json` |
| T20, T21 Arène | faits : carte, herses, machines, 7 Dresseurs, Auguste (carte, Badge Volcan, CT38 une fois, Dresseurs marqués battus), porte : avec la Clé textes 76–77 puis `cinnabar_gym_unlocked` ; Clé réparée au chargement (`key_item_repairs.json`) |
| Tests | `test_j25_maps` (6), `test_j25_flow` (6, vraie Boot : statue, quiz, échange, Vieil Ambre, porte), `test_j25_data` (20), listes recalées |
| T16, T19, T22 | **faits** : QA S24 25A (2026-10-23, bloquant de la porte du Manoir corrigé en `2dacecb3`), 25B, 25C (2026-10-23/24) ; **validés par Kevin** (§9) |
| T23 | **fait** (2026-10-24, §9) |

**Valeurs par défaut [D]** : vue 0 permise (`TrainerRules.SIGHT_MIN`) pour les Pillards et
l'Arène ; libellé « Reçu en échange à » ; titre « Échanger un Pokémon », refus « Pas l'espèce
demandée » ; lumière « tower » au Manoir ; arbre du Musée : texte sans CS « Un petit arbre pousse
devant une porte. » ; prénoms déjà pris remplacés (Aurélien, Clothilde, Léopold, Octave) ; Rappel Max
4 000 ₽ ; rencontres selon le relevé RB (le tableau §4.7 du 3F ne fait que 95 %) ; récompenses de
l'Arène non recalculées après +4 niveaux.

**Points pour Kevin** : Smogo n'évolue pas en Smogogo dans les données (au J22) ; E-2 (simulation
d'Auguste avec de vraies équipes) reste à refaire ; panneau intérieur de l'Arène (texte 78) non posé
(celui du J24 dehors suffit) ; `plan_check_j24_mer.py` signale un échec préexistant (`qa_sea`).

**Liste de QA (départs `tools/debug_start/`)** :
1. `j25_manoir` : entrer (interrupteur remis à ARRÊT), 1F → 2F → 3F, statue du 3F, trou → 1F,
   escalier ↓ B1F, statues sud puis nord, Clé ; journaux ; Pillards (on leur parle) ; Corde Sortie.
2. `j25_manoir_b1f` : statues du B1F, grilles A/B, Clé Secrète, objets.
3. `j25_echanges` (Labo) : Hector (Raichu), Marc (Ponyta), Lina (refus) ; compagnon donné (Pikachu
   n'est pas échangeable, Raichu oui si c'est lui) ; rechargement après chaque échange ; Vieil
   Ambre au scientifique des fossiles, ressortir, revenir : Ptéra N30.
4. `j25_argenta` : Coupe sur l'arbre derrière le Musée, porte arrière, comptoir OUI/NON, Vieil Ambre.
5. `j25_arene` : porte avec la Clé (76–77), quiz bonnes et mauvaises réponses (combat), parler à un
   Dresseur directement, Auguste, Badge Volcan, CT38, défaite (Centre, herses gardées).

## 0.3 État du lot 25.0 (2026-10-19)

| Tâche | État |
|---|---|
| T1 | fait (`jalon-25` = `origin/main` `aebbd85` + conception) |
| T2, T4, T5 (logique pure) | faits : `mansion_switch.gd`, `gym_quiz.gd`, `in_game_trade.gd`, `tests/unit/test_j25_logic.gd` ; l'étape de scène et `Origin.TRADE` viennent à l'intégration |
| T6, T7, T8, T9 (données) | prêtes dans `docs/tech/jalon-25-donnees/` (hors de `data/`, voir son `LISEZMOI.md`) ; quiz et échanges dans `data/` |
| T9 (simulation) | première passe : `jalon-25-equilibrage.md`, questions E-1 à E-3 |
| T10–T12 (art) | série 28 provisoire, Manoir fait, reste à relancer (limite d'usage de Codex) ; cartes recomposées par kit (écart validé à demander) |
| Suite complète | 5 336 / 5 336 |

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
`qa_cramois` (équipe avec Raichu, Ponyta, Vieil Ambre, Clé). Retirées au T23. *(Jamais créées :
remplacées par les départs `j25_*` de `tools/debug_start/`, vérifié au T23.)*

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
| — | ~~Chute du joueur au J24 ? (lecture au T3)~~ résolu : `Warp` FALL du J24 (§0.4) | §2.2 |
| E-4 | Niveaux d'Auguste après la nouvelle simulation | `jalon-25-equilibrage.md` §5.3 |

## Décisions de Kevin (2026-10-22)

Choix validés par Kevin sur la page d'arbitrages.

- Équilibrage d'Auguste : à resimuler après la fusion des J21–J24.
- Prénoms : acceptés.

## 9. Clôture (T23, 2026-10-24)

Clôture accordée par Kevin le 2026-10-24, sur `fix/j25-porte-manoir` (depuis `jalon-25`
`2dacecb3`) ; fusion dans `main` par la session de coordination.

### 9.1 Validé

| Lot | QA S24 (agent) | Validation de Kevin |
|---|---|---|
| **25A** Manoir | 1re passe : porte du Manoir infranchissable (cases `X` en falaise) → corrigé (`2dacecb3`) ; 2e passe : entrée et sortie, interrupteur remis à ARRÊT, chute 3F → 1F, herses, B1F, Clé Secrète, CT22, Corde Sortie : OK | 2026-10-23 |
| **25B** Échanges, Vieil Ambre | Hector (Raichu → Électrode « Kourjus »), Marc (Ponyta → Otaria « Bibi »), Lina (Mimitoss → Saquedeneu « Bigoudi »), refus, « déjà fait », onglet Histoire ; Coupe derrière le Musée, porte arrière, Vieil Ambre une fois, Ptéra N30 une fois : OK | 2026-10-24 |
| **25C** Arène | porte sans et avec la Clé, quiz raté → Dresseur puis herse, Dresseur abordé directement, herses non contournables, Auguste, Badge Volcan et CT38 une fois, défaite : OK | 2026-10-24 |

Non couvert par la QA (départs de débogage) : sauvegarde et rechargement en vraie partie, statue sud
et journal du B1F, compagnon pendant la chute, bonne réponse au quiz à l'écran, icône du Badge.

### 9.2 Fait au T23

- `tools/art/plan_check_argenta.py` (J10) : la porte arrière du Musée (`porte_reserve`, warp PUSH,
  pas une case `D`) est contrôlée à part (`PORTES_COUPE`) : fermée par `arbre_reserve`, atteignable
  une fois l'arbre coupé (11 pas de l'entrée sud), poussée vers le Musée ; tous les autres critères
  du J10 inchangés. Contrôles verts : `plan_check_argenta`, `_manoir`, `_cramois`, `_j24_mer` (plus d'échec `qa_sea`),
  `_j24_seafoam`.
- Cartes de QA : aucune à retirer (`qa_manoir`, `qa_cramois` jamais créées) ; les départs `j25_*`
  restent (documentés dans `tools/debug_start/README.md`).
- `tools/plans/cramois_arene.txt` : commentaires de niveaux des Dresseurs alignés sur les données
  (N38–45, E-1).
- Mentions « Lina attend le J22 » mises à jour (ce plan §0.2, §0.4 ; dossier 28 §6.2, note).
- Équilibrage d'Auguste resimulé avec des équipes réalistes : `jalon-25-equilibrage.md` §5,
  scénario `tools/sim/cinnabar_j25_realiste.json` ; **question E-4 pour Kevin**, rien changé.
- Import sans erreur ; suite complète **6 807 / 6 807**.

### 9.3 Valeurs par défaut [D] du jalon

Celles du §0.4 (vue 0 des Pillards et de l'Arène, libellés de l'échange, lumière « tower » du
Manoir, texte de l'arbre du Musée sans CS, prénoms Aurélien, Clothilde, Léopold, Octave, Rappel Max
4 000 ₽, rencontres du relevé RB, récompenses de l'Arène non recalculées après +4 niveaux,
Pillard = `gambler`, Auguste = `gentleman`, aplats provisoires) ; Dresseurs de l'Arène +4 (E-1).

### 9.4 Points ouverts pour Kevin : tranchés le 2026-10-26

Décisions de Kevin (« okay pour tes recos », toutes) :
- **E-4** : niveaux d'Auguste **gardés (option A, RB)** ; exception de type assumée (le Surf garanti
  à l'arrivée sur l'île), comme Tortank contre Pierre (`jalon-25-equilibrage.md` §5.3).
- **Hector après l'échange** : « Comment va mon ancien Électrode ? » (même point de vue que Lina et
  Marc ; dossier 28 texte 42, `cinnabar_trades.json`).
- **« Une Tadmorv sauvage »** : accord sur le sexe du Pokémon gardé (décision n° 15 du J4).
- **Comptoir de la réserve d'Argenta** et **rencontres du Manoir** (10/256 par pas) : gardés (RB).
- Restent ouverts : Smogo n'évolue pas en Smogogo dans les données (J22) ; panneau intérieur de
  l'Arène (texte 78) non posé ; art définitif (T10–T13) non intégré.
