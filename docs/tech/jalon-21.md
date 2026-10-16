# Jalon 21 — Le repos des esprits (Tour 6F–7F, M. Fuji, Poké Flûte, deux Ronflex)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/dossier-24-repos-des-esprits.md` (7 décisions et arbitrages L-1 à L-16 validés par
> Kevin le 2026-10-15 ; **textes du §15 et grilles du §19 à valider**). Passe :
> `docs/design/passes/j21-v2-alignement.md`.

> Objectif jouable sur le téléphone : **la Tour se résout, et Kanto s'ouvre**. Avec le Scope
> Sylphe, le SPECTRE du 6F se révèle : c'est Ossatueur, la mère d'Osselait. Le joueur la combat
> pour qu'elle trouve le repos. Il monte au 7F, bat 3 Sbires Rocket et sauve M. Fuji. Téléporté
> chez Fuji, il reçoit la **Poké Flûte**. Elle réveille les deux **Ronflex** (bout est de la Route
> 11, Route 16 est). Le joueur ouvre la **Route 12 nord** (ponton, 4 Pêcheurs, CT39) et la boucle
> Carmin ↔ Route 11 ↔ Route 12 ↔ Lavanville. **M-3 (2026-10-16)** : Ronflex « est » au croisement de la
> Route 12 (drapeaux `snorlax_route_12_*`), retiré de la Route 11 du J17.
>
> Mécaniques nouvelles :
> - le **premier objet clé utilisable** (`key_use`), en exploration et en combat ;
> - l'effet **« réveiller tous les endormis »** en combat (sans effet : le tour n'est pas pris) ;
> - les issues **`flee`** et **`catch`** de l'étape `wild_battle` (J19), plus `clear` ;
> - la règle **`uncatchable`** (Ball refusée avant le lancer), indépendante du mode spectre ;
> - l'**intro « révélation »** d'un combat sauvage (silhouette du J19 qui se dissout) ;
> - des **conditions d'objet** sur les variantes de scène (`if_items` / `unless_items`), sur le
>   modèle de celles des dialogues (J20).
>
> Tout le reste (7F, Sbires, Fuji, Pêcheurs, routes, variantes de Lavanville) est du contenu posé
> sur des systèmes existants. **Format de sauvegarde inchangé : v7** (§2.14).

**Pré-requis.** Dossier 24 consolidé ; grilles v1 `tools/plans/pokemon_tower_7f.txt`,
`route_12.txt`, `route_16.txt`, contrôle `python3 -I tools/art/plan_check_j21.py` (TOUT EST
CONFORME, commit `666d953e`). Les grilles font foi pour la géométrie.

Plan écrit sur `j21-plan` (base `docs/dossier-24-j21` à `666d953e`). **Code lu** :
- `origin/main` à `440f9b17` (**J15 terminé**, sauvegarde v7) : code de référence ;
- `jalon-16` à `77f3fd98` (étapes `field_move`, `save`, `animate`, `FieldMoves`) ;
- `jalon-17` à `07e716d8` et `j17-t16-route11` à `b508aa29` (`FlagGate`, Route 11, Ronflex) ;
- `jalon-18` à `4f90ac2c` (plan `jalon-18.md`, grille `lavanville.txt`, art) ;
- `jalon-19` à `8a0c7d9b` (plan `jalon-19.md`, T3–T6 codés : `GhostRule`, `GhostDisguise`,
  tables, `kanto_tower.json`, `tower.json`) ;
- `docs/plan-j20` à `5c42a28e` (plan `jalon-20.md`) et `docs/dossier-23-j20` à `b4a02b8f`
  (dossier 23, `celadopole.txt`).

Quand un nom n'existe que dans un plan, il est suivi de « (plan) ». **La tâche d'alignement (T9)
réaligne ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), skills `godot-conventions` et `world-tiles`, modèles de
forme `jalon-19.md` et `jalon-17.md`, `jalon-16.md` (étapes `animate`, `field_move`),
`jalon-20.md` (`if_items`).

---

## 0. État et dépendances

### 0.1 Règle C-7 : le code du moteur commence après la clôture du J20

- Un seul jalon à la fois dans le moteur de combat, les directeurs et la sauvegarde. Les J16 à
  J20 passent avant.
- **Les tâches qui touchent `game/battle/`, les directeurs (scènes, combat, menu), `boot.gd`,
  `item_data.gd`, ou une carte d'un autre jalon commencent après la clôture du J20.** À ce
  moment-là, `origin/main` (J16 à J20) est fusionné dans `jalon-21` : c'est **T9**.
- **Avant**, seulement : documents, logique pure dans des fichiers nouveaux, données dans des
  fichiers nouveaux, art, vues peintes, contrôles de grilles (§1.2).

### 0.2 Contrat d'entrée (dossier §3) relu sur le code et les plans réels

| Le J21 suppose | Jalon | État réel (2026-10-15) | Écart / ce que fait le J21 |
|---|---|---|---|
| Ronflex de la Route 11 : `FlagGate` 2 × 2 + `InteractPoint` 2 × 2 en (66..67, 14..15) | J17 | **Codé** : `tools/build_route_11.gd` (`j17-t16-route11`) l. 92-94 (`SNORLAX_FLAG = &"snorlax_route_12_awake"`), `_add_life` l. 256-306 ; dialogue `route_11_snorlax` (`data/dialogues/route_11.json` l. 8-20, T-6 puis T-7 par `snorlax_route_12_seen`) ; `FlagGate` (`game/world/flag_gate.gd` l. 21-48 : `if_flags`, `unless_flags`, `blocking_cells`, `is_open`, `apply`, `apply_to_grid`) | **Écart 1** : la porte s'ouvre sur `_awake`. Le J21 la passe sur `snorlax_route_12_done` (dossier §9.4, §19) : une ligne de donnée dans l'outil (T20). |
| Bord est de la Route 11 (75, 14..15) `raccord_est role=route_12` | J17 | **Aucun warp** : l'en-tête de `build_route_11.gd` dit « Bord est (75, 14..15) : aucun warp » ; `route_11.txt` : « praticable mais INATTEIGNABLE » | **Écart 2** : le dossier §3 parle d'un `raccord_est` ; il n'existe que dans la grille, pas dans la carte. Le J21 pose le warp PUSH → `route_12` / `from_route_11` et le spawn `from_route_12` en (74, 14..15) (§19). |
| Lavanville : bord sud « ROUTE 12 — À venir » | J18 | Grille `lavanville.txt` (`jalon-18`) : `warp_sud` (21..23, 35) `coming_soon=route_12`, spawn `from_route_12` (21..23, 34) déjà prévu ; **carte non codée** (plan `jalon-18.md` §4) | Le J21 retire le `coming_soon` (T21). |
| Maison des Pokémon au J19 : homme, fille, **Osselait** | J19 | Plan `jalon-19.md` §2.11 : homme et fille dans `data/npcs/pokemon_house.json` (Q-2 = A), **« sans Osselait visible (aucun art au J19) »** | **Écart 3** : Osselait n'est pas posé au J19. Le J21 le pose (L-14) : il faut un **sprite de monde d'Osselait** (lot d'art, §2.16). |
| 6F : scène `tower_6f_ghost`, déclencheur (10, 16), étape `wild_battle marowak 30 ghost: always`, recul (10, 15), variante `unless ghost_marowak_calmed` ; escalier 7F (9, 16), paire T67 | J19 | Grille `pokemon_tower_6f.txt` (`jalon-19`) : `escalier_7f` (9, 16), `declencheur_spectre` (10, 16), `recul_spectre` (10, 15). Scène et étape : **plan seulement** (`jalon-19.md` §2.4, T13, T14) | **Écart 4** : le 6F n'a **aucun spawn `arrivee_T67`** pour le retour du 7F. Le J21 l'ajoute en (10, 16), tourné → (§19). |
| Étape `wild_battle` avec `win` / `lose` ; `ball_refused`, `flee_always`, masque | J19 | **Plan seulement** (`jalon-19.md` §2.3, §2.4). Codé : `game/battle/ghost_rule.gd`, `ghost_disguise.gd`, `WildEncounter.ghost` (T5, T6) | Le J21 ajoute `flee`, `catch`, `clear`, `reveal`, `uncatchable` (§2.3). |
| `silph_scope` objet clé ; objectif « retourner à la Tour Pokémon. » | J20 | Plan `jalon-20.md` §2.7.5 (`silph_scope` : `key`, `obtained: true`) et objectif `back_to_tower` `if [got_rocket_hideout_b4f_silph_scope]` (« le J21 ajoutera son `unless` ») | Le J21 ajoute `unless [ghost_marowak_calmed]` (§2.12). |
| Céladopole : sortie ouest = haie et talus (H-4) | J20 | `celadopole.txt` (`docs/dossier-23-j20`) l. 12-15, `obstacle_ouest` (3, 22) examen, aucun warp | Le J21 la remplace (§19 : (0..3, 21..23) en chemin, `warp_ouest` → `route_16`, spawn `from_route_16`) (T22). |
| Drapeaux réservés jamais posés : `ghost_marowak_calmed`, `fuji_rescued`, `got_poke_flute`, `beaten_tower_rocket_1..3` | J19, J20 | Tests prévus : `test_j19_flags_contract` (plan J19 T22), `test_j20_no_j21_flags` (plan J20 §2.7.5) | Gardés. Le J21 ajoute son propre contrat (T23). |
| Espèces : Osselait, Ossatueur, Fantominus, Spectrum (J19) ; Soporifik (J17) ; Smogo, Nosferapti, Nosferalto, Rattata, Rattatac (`main`) | J15–J19 | `marowak`, `cubone`, `gastly`, `haunter` : `kanto_tower.json` (`jalon-19`) ; `drowzee` : `kanto_j17.json` (`jalon-17`) ; `zubat`, `golbat`, `koffing` : `kanto_mt_moon.json` ; `rattata`, `raticate` : `kanto.json` (`main`) | Conforme. **Ronflex absent partout** (créé au J21). |
| Capacités : Repos (`main`), Coup d'Boule (J17), Massd'Os (J19), Rugissement, Groz'Yeux, Puissance (`main`) | — | `rest` (`moves/mt_moon.json`), `headbutt` (`moves/j17.json`), `bone_club` (`moves/tower.json`), `growl`, `leer`, `focus_energy` (`moves.json`), `swift` (Météores, `moves.json`) | **Amnésie absente** → créée. `hypnosis` est créée **deux fois** (J17 `j17.json` et J19 `tower.json`) : doublon à retirer au second fusionné (signalé au J19/J20, pas au J21). |
| Sauvegarde v7 | J15 | `save_system.gd:36` `VERSION = 7` ; J16–J20 : aucune version nouvelle (plans) | Le J21 non plus (§2.14). |

### 0.3 Points d'accroche dans le code (`origin/main` à `440f9b17`)

| Pièce | Fichier et ligne | Ce que le J21 y fait |
|---|---|---|
| Catégories et contextes d'objet | `item_data.gd` l. 21 (`enum Category`), l. 95 (`contexts()` : `KEY` → `[]`), l. 135 (`is_permanent()` : CT seulement) | `key_use` → contextes exploration + combats (§2.1) |
| Usage d'un objet AVENTURE sans cible | `field_item_rules.gd` l. 24 (`check`), l. 48 (`is_targetless`) ; `menu_director.gd` l. 87 (`field_item_requested`), l. 743 (`_use_targetless_item`) ; `boot.gd` `_on_field_item_requested` (Corde Sortie seulement, ≈ l. 1631) | La Flûte passe par le même chemin ; Boot aiguille selon l'objet (§2.2) |
| Sac de combat | `battle_director.gd` l. 372 (`_choose_action` : SAC ouvert si `can_use_balls() or can_use_heal_items()`), l. 412 (`_choose_item` : tout ce qui ne soigne pas devient `BattleAction.ball`), l. 470 (`_spend_item`) ; `BattleBagPanel` cache les objets inutilisables | Branche « objet clé » (§2.4) |
| Actions et légalité | `battle_action.gd` l. 10 (`enum Kind { MOVE, RUN, ITEM, SWITCH }`) ; `battle.gd` l. 237 (`is_legal`), l. 327 (`submit`), l. 393 (`_throw_ball`), l. 421 (`_use_heal`), l. 1374 (`_ball_blocked`) | `Kind.KEY_ITEM` en fin d'enum, `_play_flute` (§2.4) |
| Sommeil | `status_rules.gd` l. 40 (`SLEEP`), l. 181 (`apply_rest`, compteur 2) ; `pokemon.gd` l. 132 (`cure_status` remet le compteur à 0) | Réveil par `cure_status` (§2.4) |
| Textes de combat | `battle_text.gd` l. 103 (`TEMPLATE_IDS`), l. 474 (`_fill` : pas de jeton `{player}`) ; `data/battle/messages.json` (`item_used` « Tu utilises… », `ball_blocked`) | Jeton `{player}` + 6 modèles (§2.4, §2.5) |
| Étapes de scène | `cutscene_step.gd` l. 84 (`enum Kind`, `TYPE_KEYS`), l. 190 (`outcome_flags` : WIN, LOSS) ; J16 ajoute `FIELD_MOVE`, `SAVE`, `ANIMATE` ; J19 `WILD_BATTLE` (plan) | Clés de `wild_battle`, `set` sur `give`, étape `flute` (§2.3) |
| Directeur de scènes | `cutscene_director.gd` l. 308 (`_play_step`), l. 508 (`_battle`), l. 529 (`_give`), l. 645 (`_change_map`) | §2.3 |
| Variantes de scène | `cutscene_variant.gd` l. 16 (`matches(flags)`) ; `cutscene.gd` l. 20 (`pick(flags)`) | `if_items` / `unless_items` (§2.3) |
| Variantes de dialogue, choix | `dialogue_library.gd` l. 46 (`_VARIANT_KEYS`), l. 50 (`_CHOICE_KEYS`) ; `dialogue_choice.gd` l. 41 (`confirm_cutscene`) | Rien de nouveau si le J20 livre `if_items` (§0.4 n° 3) |
| Enchaînement de scènes | `boot.gd` l. 1322 (`_on_cutscene_finished` : clé `next`, sauvegarde « entre deux scènes ») ; l. 695 (`is_stable` : aucune écriture pendant une scène, un dialogue, un combat) | Remise de la Flûte (§2.9) |
| « Vu » hors rencontre | `boot.gd` l. 1360 (`_on_battle_event` : tout `SENT_OUT` adverse hors rencontre) | Ossatueur et Ronflex « vus » sans code |
| Capture | `battle_director.gd` l. 747 (`_finish_capture` : équipe ou Stockage, Pokédex, Grand moment) | Ronflex capturé par une scène : sans code |
| Bulle du compagnon | `emote_bubble.gd` l. 12 (`NOTE`) ; `companion.gd` l. 248 (`show_emote`) | « ♪ » (§2.2) |
| Sauvegarde | `save_system.gd` l. 36 (`VERSION = 7`) | Inchangée |

### 0.4 Écarts et trous du dossier

1. **`*_awake` devient un drapeau de passage.** Le portail s'ouvre sur `*_done` (§9.4, §19). Le
   drapeau `*_awake` est posé au réveil et effacé à la fin du combat (clé `clear`, §2.3). Aucune
   sauvegarde n'est écrite pendant une scène (`boot.gd` l. 695) : il n'atteint jamais le disque.
   Il est gardé pour suivre le dossier [D].
2. **Deux drapeaux de plus** [D] (aucune version de sauvegarde) :
   - `snorlax_route_12_woken`, `snorlax_route_16_woken` : posés au réveil, **jamais effacés**. Ils
     servent au texte §15.7.5 (« dort de nouveau ») et à la réplique de Fuji §15.4.7 ;
   - `snorlax_route_12_caught`, `snorlax_route_16_caught` : posés à la capture seulement. Ils
     distinguent la capture (aucun texte) du K.O. (§15.7.3) ;
   - `tower_6f_mist_lifted` : posé au point 5 du §5.4, après la lumière. Il garde l'ordre du
     dossier (la brume se lève **après** les textes, pas dès la fin du combat).
3. **Conditions d'objet.** Le J20 ajoute `if_items` / `unless_items` aux **variantes de
   dialogue** (`jalon-20.md` §2.9.6). Le J21 en a besoin aussi sur les **variantes de scène** :
   le 6F choisit révélation ou SPECTRE selon le Scope, et la remise de la Flûte lit la possession
   (§7.2). Même sémantique, même nom de clé. Si le J20 n'a pas livré la clé de dialogue, T10 la
   crée selon son plan.
4. **Poids de la table du 7F.** Le dossier §6.1 dit « RB, taux 15 » et « mêmes poids que le 6F
   [D] ». Les poids RB du 7F (`data/wild/maps/PokemonTower7F.asm`) diffèrent : Fantominus 191
   (N20–24), Spectrum 39 (N28–30), Osselait 26 (N22–24). **Défaut retenu : les poids RB** (le
   dossier vise RB ; c'était une valeur par défaut). Kevin peut revenir aux poids du 6F.
5. **Pêcheurs : textes absents** (§15.8.5 « à rédiger au plan technique »). Brouillons en
   annexe A, à valider avec le lot §15.
6. **Cri d'Ossatueur et de Ronflex** (§5.2, §5.4) : aucun son dans le projet
   (`assets/audio/` vide ; `cry_requested` n'est qu'un signal). Rien à coder ; noté pour le
   jalon audio.
7. **« Lumière qui monte »** : le J19 interdit les particules [D]. Le J21 la fait avec l'étape
   `animate` du J16 sur un halo peint (`SpiritLight`), sans particule. « Réduire les
   animations » : le J16 joue un fondu sur place ; le dossier veut la lumière **coupée**. Le J21
   ajoute la clé `skip_reduced` à `animate` (étape sautée si l'option est active) [D].
8. **Réveil de Ronflex** (petit saut, bulle « ! ») : Ronflex est un décor (`FlagGate`), pas un
   PNJ. Les étapes `react` et `emote` ne visent que des PNJ. Le J21 leur permet de viser un
   **acteur de décor** (nœud de la carte du groupe `scene_props`) [D] (§2.3).
9. **Ossatueur, Pokédex** : `marowak` existe (`kanto_tower.json`, J19), avec un learnset qui
   donne au N30 exactement Massd'Os, Rugissement, Groz'Yeux, Puissance (RB). « Données
   complètes » = son **entrée de Pokédex** (§15.10). Aucune donnée de combat à refaire.
10. **Réplique de Fuji §15.4.7** « une fois un Ronflex réveillé » : lue sur `*_woken` (n° 2).
11. **Route 16 : texte de la porte du poste.** Le mécanisme `coming_soon` affiche « ROUTE 16 —
    À venir » en développement et bloque en release (grille). Aucun texte de plus.
12. **Route 12 : nom du poste.** Intérieur `route_12_gate` (grille), 1F traversant et 2F.
    Aucun nom de zone propre [D] : il fait partie de la zone Route 12.

---

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §17, L-16)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **21.0** | Textes (§15 et annexe A) ; logique pure de la Flûte ; données en fichiers nouveaux ; kit et lot d'art (série 23) ; vues peintes du 7F, de la Route 12 nord, de la Route 16 est ; variante de la grille de Céladopole ; alignement après le J20 (T9) | Kevin valide textes, grilles, vues et art. **Aucune session téléphone.** |
| **21A** « La Tour résolue » | Extensions de `wild_battle`, `uncatchable`, intro « révélation », conditions d'objet des scènes ; 6F révélé, brume apaisée ; 7F, Sbires, Fuji, téléportation ; remise idempotente ; variantes de Lavanville ; objectifs ; départs `tower_marowak_qa` et suivants | **Téléphone** (S24 ou S21) |
| **21B** « La Flûte » | Objet clé utilisable (exploration et combat) ; deux Ronflex ; Route 12 nord (poste, CT39, Pêcheurs) ; Route 16 est et raccord de Céladopole ; tests d'interruption ; QA de bout en bout | **Téléphone** + fusion |

Règle des trois systèmes :
- **21A** porte **un** système : l'extension de l'étape `wild_battle` (issues, révélation, refus de
  la Ball). Les conditions d'objet des scènes sont une petite clé de données.
- **21B** porte **un** système : l'objet clé utilisable (Sac, combat, exploration). Ronflex et les
  routes sont du contenu dessus.
- **Aucune validation isolée de sauvegarde** : rien ne touche sa forme (§2.14). Les tests
  d'interruption sont des tests automatiques, rejoués à la QA 21B.

### 1.2 « Peut commencer maintenant » ou « après la clôture du J20 »

| Tâche | Quand | Pourquoi |
|---|---|---|
| T1 branche `jalon-21` | **maintenant** | Depuis `main` + `docs/dossier-24-j21` |
| T2 textes (annexe A) | **maintenant** | Documents |
| T3 logique pure de la Flûte | **maintenant** | Fichiers nouveaux, sur des classes de `main` (`Party`, `Pokemon`, `StatusRules`) |
| T4 données qui valident sur `main` | **maintenant** | `moves/j21.json` (Amnésie), `items/items_j21.json` (`tm39`, `poke_flute` **sans** `key_use`) |
| T5 données qui dépendent des J17 / J19 | **rédigées maintenant**, validées et fusionnées **après T9** | Ronflex (learnset : `headbutt` J17, `hyper_beam` J19), Ptitard (`hypnosis`), Dresseurs (Soporifik J17), table du 7F (terrain `floor` J19), Pokédex d'Ossatueur (espèce J19) |
| T6 kit d'art (série 23) | **maintenant** | Vues générales à produire en T8 ; kit sur les grilles |
| T7 génération et intégration de l'art | **maintenant**, après T6 | Images, entrées **en fin** de manifeste |
| T8 vues peintes, variante de Céladopole | **maintenant** | Grilles validées par Kevin d'abord (§19) |
| T9 alignement | **après la clôture du J20** | Fusion de `main` (J16 à J20) |
| T10 à T25 | **après T9** | Moteur de combat, directeurs, `boot.gd`, cartes des J17 à J20 |

### 1.3 Branches et fichiers chauds

- Intégration sur **`jalon-21`**, dans une copie dédiée ; une branche par tâche
  (`j21-t<n>-<sujet>`) ; rien dans `main` avant la clôture (T25).
- **Fichiers nouveaux de préférence** : `species/kanto_j21.json`, `moves/j21.json`,
  `items/items_j21.json`, `trainers/pokemon_tower_7f.json`, `trainers/route_12.json`,
  `encounters/pokemon_tower_7f.json`, `npcs/pokemon_tower_7f.json`, `npcs/route_12.json`,
  `npcs/route_12_gate.json`, `npcs/route_16.json`, `dialogues/j21_*.json`, `cutscenes/j21_*.json`.
- **Fichiers uniques, ajouts en fin** : `data/pokedex/kanto.json`, `data/world/caves.json`,
  `zones.json`, `lighting.json`, `light_glows.json`, `data/battle/decors.json`, `messages.json`,
  `data/story/objectives.json` (**en tête** : ordre « plus avancé d'abord »),
  `tools/art/manifeste.json`, `build_character_frames.gd`.
- **Fichiers chauds (après T9 seulement), ajouts courts en bloc « J21 »** :
  - moteur : `battle.gd`, `battle_action.gd`, `battle_event.gd`, `battle_rules.gd`,
    `battle_request.gd`, `battle_director.gd`, `battle_text.gd`, `battle_stage.gd` ;
  - objets : `item_data.gd`, `item_library.gd`, `field_item_rules.gd`, `menu_director.gd` ;
  - scènes : `cutscene_step.gd`, `cutscene_library.gd`, `cutscene_director.gd`,
    `cutscene_variant.gd`, `cutscene.gd` ;
  - `boot.gd`, `debug_start.gd`, `game/world/map.gd`, `interact_point.gd` ;
  - cartes des autres jalons : `tools/build_route_11.gd` (J17), `tools/build_lavender_town.gd` et
    `build_painted_interiors.gd` (J18), `tools/build_pokemon_tower.gd` et la grille du 6F (J19),
    `tools/build_celadon_city.gd` (plan) et `celadopole.txt` (J20) ;
  - données des autres jalons : `data/dialogues/route_11.json`, `pokemon_tower.json`,
    `pokemon_tower_floors.json`, `lavender_houses.json`, `data/npcs/pokemon_house.json`,
    `lavender_center.json`, `data/cutscenes/pokemon_tower_floors.json`.

---

## 2. Conception technique

### 2.1 Objet clé utilisable : `key_use` (T17)

**Donnée** (`item_data.gd`, pure) :
- `var key_use: StringName = &""` ; `const KEY_USE_POKE_FLUTE := &"poke_flute"` ;
  `const KEY_USES: Array[StringName] = [KEY_USE_POKE_FLUTE]` (ajouts en fin).
- `contexts()` : `KEY` avec `key_use` → `[CONTEXT_FIELD, CONTEXT_WILD_BATTLE,
  CONTEXT_TRAINER_BATTLE]` ; sans `key_use` → `[]` (inchangé pour les autres objets clés).
- `func has_key_use() -> bool` ; `is_permanent()` vrai aussi pour un objet clé (jamais consommé).
- `ItemLibrary` : clé `"key_use"` réservée à la catégorie `key`, valeur dans `KEY_USES`, sinon
  erreur (test).

**Fichier** `data/items/items_j21.json` :

```json
{
  "poke_flute": {
    "name": "Poké Flûte", "plural": "Poké Flûtes", "feminine": true,
    "category": "key", "key_use": "poke_flute",
    "description": "Une flûte à la mélodie douce. Elle réveille les Pokémon endormis."
  },
  "tm39": {
    "name": "CT39", "plural": "CT39", "category": "tm",
    "tm_number": 39, "teaches": "swift",
    "description": "Météores ne rate jamais sa cible."
  }
}
```

- `key_use` est ajouté par T17 ; T4 crée l'objet sans cette clé (valide sur `main`).
- `tm39` : `tm_compatibility.json` liste déjà `"39": "swift"` (`main`). Le texte de description
  [D] reprend §15.8 bis ; à valider (annexe A).
- Toast d'ajout : « POKÉ FLÛTE — ajoutée aux objets clés » (accord féminin existant,
  `added_text`). Le dossier écrit « Poké Flûte — ajoutée aux objets clés » ; la casse vient de
  `quantity_text` (capitales pour un objet clé, règle du J7) [D].

### 2.2 La Flûte en exploration (T17, T18, T19)

**Logique pure** (T3, fichiers nouveaux) :

```gdscript
# game/items/flute_target.gd — pur
class_name FluteTarget
extends RefCounted
## Un Pokémon endormi qu'on réveille à la Flûte (Ronflex) : ses cases, ses conditions
## d'existence et la scène du réveil.
var cells: Array[Vector2i] = []
var unless_flags: Array[StringName] = []
var cutscene_id: StringName = &""
```

```gdscript
# game/items/poke_flute_rules.gd — pur, statique
class_name PokeFluteRules
extends RefCounted
## Scène de réveil si [param cell] touche (4 voisins) un dormeur encore présent ; &"" sinon.
static func field_target(targets: Array[FluteTarget], cell: Vector2i,
		flags: StoryFlags) -> StringName
## Pokémon endormis (non K.O.) des deux équipes, dans l'ordre : joueur, puis adversaire.
static func sleepers(player: Party, foe: Party) -> Array[Pokemon]
## Réveille chaque Pokémon de [param pokemons] (cure_status) ; rend ceux qui dormaient.
static func wake_all(pokemons: Array[Pokemon]) -> Array[Pokemon]
```

**Sur la carte** :
- `InteractPoint` : `@export var flute_cutscene: StringName = &""` (un seul `@export` ajouté).
- `GameMap.flute_targets() -> Array[FluteTarget]` : un `FluteTarget` par `InteractPoint` qui a
  une `flute_cutscene`. Les cases voisines se calculent depuis les cases du point.
- Aucune donnée de géométrie en double : la grille écrit le point (outil), la règle le lit.

**Parcours** :
1. Sac → Poké Flûte → UTILISER. `FieldItemRules.check` rend OK pour `key_use` partout ;
   `is_targetless` est vrai. `MenuDirector._use_targetless_item` émet `field_item_requested`
   (inchangé).
2. `Boot._on_field_item_requested` aiguille : Corde Sortie (existant) ou **Flûte**.
3. Flûte : menu fermé, puis
   `PokeFluteRules.field_target(map.flute_targets(), player_cell, GameState.flags)` :
   - une scène → `CutsceneDirector.play(scene)` (le réveil, §2.10) ;
   - sinon → étape d'effet `flute` jouée hors scène (notes, §2.3), dialogue
     `poke_flute_played` (§15.6.6), puis bulle `EmoteBubble.NOTE` du compagnon s'il est sorti.
4. En parlant à Ronflex, Flûte dans le Sac : variante de dialogue `if_items [poke_flute]` avec
   le choix (§2.10). Pas de code.

**Notes de musique** (T18) : `game/world/effects/flute_notes.gd` (`class_name FluteNotes`,
`extends Node2D`). 3 notes peintes [D] qui montent au-dessus du joueur et s'effacent, ≈ 1,5 s,
par un seul `Tween` ; aucun `_process`. « Réduire les animations » : aucune note, attente nulle.
Le nœud est libéré à la fin.

### 2.3 Scènes : étapes et conditions (T10, T19)

**Variantes de scène selon le Sac** (`cutscene_variant.gd`, `cutscene.gd`) :
- `var if_items: Array[StringName]`, `var unless_items: Array[StringName]` ;
- `matches(flags, bag: Bag = null)` : vraies si tous / aucun sont dans le Sac (sans Sac : faux
  si `if_items` n'est pas vide) ;
- `Cutscene.pick(flags, bag = null)` ; le directeur passe son Sac (`set_inventory`, existant).
- `CutsceneLibrary` accepte les deux clés (listes non vides de chaînes ; identifiant non vérifié
  contre `ItemLibrary`, comme `ghost_unless_item`).

**Étape `wild_battle` étendue** (format complet, J19 + J21) :

```json
{ "wild_battle": "snorlax", "level": 30,
  "ghost": "always" | "ghost_unless_item": "silph_scope",
  "reveal": true, "uncatchable": true,
  "win": [], "lose": [], "flee": [], "catch": [], "clear": [] }
```

| Clé | Sens | Règle |
|---|---|---|
| `reveal` | Intro « révélation » (§2.5) | Interdite avec `ghost: always` ; si `ghost_unless_item` rend un SPECTRE, `reveal` est ignorée |
| `uncatchable` | Ball refusée avant le lancer, non consommée (§2.6) | Indépendante du mode spectre |
| `win`, `lose` | Drapeaux levés (J19) | Inchangé |
| `flee` | Drapeaux levés si `FLED` | Nouveau |
| `catch` | Drapeaux levés si `CAUGHT` | Nouveau |
| `clear` | Drapeaux **effacés** à la fin du combat, quelle que soit l'issue, **avant** le réveil d'une défaite | Nouveau (`StoryFlags.set_flag(flag, false)`, existant) |

- `CutsceneStep.outcome_flags(outcome)` rend aussi `flee_flags` (FLED) et `catch_flags`
  (CAUGHT) ; `var clear_flags`.
- Ordre dans `CutsceneDirector._wild_battle` (plan J19) : combat → `clear` → drapeaux de
  l'issue → si `LOSS` : `wake_up` et arrêt de la scène.
- `WildEncounter` reçoit `reveal: bool` et `uncatchable: bool` ; `BattleRequest.wild` les recopie
  (§2.5, §2.6).

**Étape `give` avec `set`** : `{ "give": "poke_flute", "set": ["got_poke_flute"] }`. Les drapeaux
ne sont levés que si l'ajout au Sac a réussi, **dans le même appel** (dossier §7.2 : « dans la
même étape »).

**Étape `flute`** (`Kind.FLUTE`, en fin d'enum) : `{ "flute": true }`. Notes au-dessus du joueur
(`FluteNotes`), la scène attend leur fin. Elle sert au réveil de Ronflex et, hors scène, au
« ailleurs » (Boot appelle la même fonction).

**Acteurs de décor** pour `react` et `emote` : si l'identifiant n'est pas un PNJ, le directeur
cherche un nœud de la carte du groupe `&"scene_props"` qui porte ce nom et qui a `react()` /
`show_emote(kind)`. Script `game/world/prop_actor.gd` (`class_name PropActor`, `extends Node2D`) :
petit saut par `Tween`, bulle `EmoteBubble`. Le sprite de Ronflex en est un.

**`animate` avec `skip_reduced`** (étape du J16) : `"skip_reduced": true` → étape sautée si
« Réduire les animations » est actif.

### 2.4 La Flûte en combat (T17)

**Moteur** :

| Fichier | Changement |
|---|---|
| `battle_action.gd` | `Kind.KEY_ITEM` **en fin d'enum** ; `static func key_item(id)` |
| `battle_event.gd` | `Kind.FLUTE_PLAYED`, `Kind.FLUTE_WOKE`, `Kind.ALL_WOKE` **en fin d'enum** |
| `battle.gd` | `func can_use_key_items() -> bool` (règles et objets connus) ; `func flute_has_effect() -> bool` (`PokeFluteRules.sleepers` non vide) ; `is_legal(KEY_ITEM)` : objet `key_use == poke_flute` **et** effet ; `submit` : `_play_flute(events)` avant les capacités : `FLUTE_PLAYED`, un `FLUTE_WOKE` muet par Pokémon réveillé (le camp et le Pokémon, pour les cartes), `ALL_WOKE`, puis `_foe_turn_alone` (le tour est pris) |
| `battle_director.gd` | `_choose_action` : SAC ouvert aussi si `can_use_key_items()` ; `_choose_item` : un objet `has_key_use()` → `BattleAction.key_item` ; avant `submit` : si `not flute_has_effect()`, message `flute_no_effect`, **retour au choix sans tour** ; **jamais `_spend_item`** pour un objet clé |
| `battle_text.gd` | `FLUTE_PLAYED` → `flute_played` ; `ALL_WOKE` → `flute_all_woke` ; `FLUTE_WOKE` sans texte ; jeton `{player}` dans `_fill` (valeur de `token_values`, posée par Boot comme `{rival}`) |
| `BattleHud` / cartes | `FLUTE_WOKE` retire la pastille de sommeil du Pokémon en jeu (chemin de `STATUS_CURED` sans texte) |
| `messages.json` | `flute_played` « {player} joue de la Poké Flûte. » ; `flute_all_woke` « Tous les Pokémon endormis se réveillent ! » ; `flute_no_effect` « Personne ne dort. » / « La Flûte n'aurait aucun effet. » (deux pages) |

- **Qui se réveille** : `PokeFluteRules.sleepers(player.party, foe.party)`. Sauvage : l'équipe
  adverse ne compte qu'un Pokémon. Dresseur : **toute** l'équipe adverse (RB). Les K.O. ne
  comptent pas.
- **Réveil** = `Pokemon.cure_status()` : le compteur est remis à 0 (dossier §8.2). Un Pokémon de
  Repos aussi (compteur 2, `apply_rest`).
- **Rien d'autre** : PV, autres statuts, confusion, stades inchangés (test).
- **Patience** (`get_locked_move`) : aucune action d'objet n'est légale pendant le verrou
  (existant). **Mode spectre** (J19) : la Flûte marche ; le SPECTRE parle ensuite.
- **Ordre des tirages** : la Flûte n'en consomme aucun ; seul le tour adverse en tire.

**Sac de combat** (T18, `BattleBagPanel`) : l'onglet « OBJETS CLÉS » apparaît dès qu'un objet clé
y est utilisable (règle existante : rien d'inutilisable ne s'affiche). Bouton **UTILISER**
(`BagEntryView.ACTION_LABELS` : défaut existant). Icône de catégorie `key.svg` (existant).

### 2.5 Révélation d'Ossatueur (T10 moteur, T11 écran)

- `BattleRequest.reveal: bool` (depuis `WildEncounter.reveal`).
- `BattleDirector.run_request`, si `reveal` : l'intro sauvage montre **la silhouette** du J19
  (`BattleArt.image(GhostDisguise.SPECIES, false)`) au lieu de l'espèce, puis :
  1. message `ghost_revealed` « Le Scope Sylphe révèle l'identité du SPECTRE ! » ;
  2. `BattleStage.dissolve_foe(species)` : fondu croisé silhouette → artwork d'Ossatueur,
     **1,0 s** [D], un `Tween` ; « Réduire les animations » : remplacement immédiat ;
  3. le texte d'apparition du sauvage est remplacé par `ghost_revealed_species` « C'est un
     {pokemon} ! » [D : « un », car seul Ossatueur l'utilise].
- Les événements adverses ne sont **pas** masqués (`disguised` faux) : nom, niveau, carte réels ;
  Ossatueur est « vu » par le chemin des combats hors rencontre (`boot.gd` l. 1360).
- Cri : aucun (§0.4 n° 6).

### 2.6 Règle `uncatchable` (T10)

- `BattleRules.uncatchable: bool` (faux par défaut). `BattleRequest.wild` le pose depuis
  `WildEncounter.uncatchable`.
- `Battle.refuses_balls()` (plan J19) : vrai si `ghost` **ou** `uncatchable`.
- `BattleDirector._choose_action` : si `_choose_item` rend une Ball et `refuses_balls()` :
  message `ghost_ball_refused` (SPECTRE) **ou** `ball_uncatchable` « Ce Pokémon ne peut pas être
  capturé. » ; **ni `_spend_item`, ni tour**.
- Le reste suit un combat sauvage normal : fuite par `FleeCalc`, XP gagnée, Sac et changement
  permis.

### 2.7 Le 6F en version révélation (T12)

**Scène** `tower_6f_ghost` (`data/cutscenes/pokemon_tower_floors.json`, J19) : **une variante
ajoutée en tête**, la variante du J19 reste telle quelle :

```text
variante A  unless [ghost_marowak_calmed]  if_items [silph_scope]
  react player ; wait 0.6                                     # comme le J19
  dialogue tower_6f_ghost_warning                             # §15.1.1 (J19, inchangé)
  wild_battle marowak 30 reveal uncatchable win [ghost_marowak_calmed]
  move player path ["up"] keep_facing      unless [ghost_marowak_calmed]   # fuite : (10, 15)
  dialogue tower_6f_marowak_held           unless [ghost_marowak_calmed]   # §15.1.5
  dialogue tower_6f_marowak_soul           if [ghost_marowak_calmed]       # §15.1.6
  animate SpiritLight offset [0, -2] 2.0 fade skip_reduced  if [ghost_marowak_calmed]
  dialogue tower_6f_marowak_peace          if [ghost_marowak_calmed]       # §15.1.7
  set [tower_6f_mist_lifted]               if [ghost_marowak_calmed]
variante B  unless [ghost_marowak_calmed]                     # J19, SPECTRE
```

- **Défaite** : `wake_up` dans l'étape (Centre de Lavanville), scène arrêtée, déclencheur réarmé
  (le drapeau n'est pas posé).
- **Fuite** : la branche `unless` suit (seule issue restante, la défaite arrête la scène).
- **Victoire** : `ghost_marowak_calmed` est levé à la fin du combat, avant tout texte (§5.4).
- **Sans le Scope** : variante B, inchangée (dossier §16 n° 1).
- **Après** : aucune variante ne s'applique ; le pas sur (10, 16) ne joue rien.

**Carte du 6F** (`tools/build_pokemon_tower.gd`, bloc J21 ; grille du 6F) :
- spawn **`arrivee_T67`** (10, 16), tourné → (§19) ;
- `escalier_7f` (9, 16) : warp réel → `pokemon_tower_7f` / `arrivee_T67` (au lieu du
  `coming_soon` du J19) ;
- **brume** : la `MistLayer` du J19 passe dans une `FlagGate unless [tower_6f_mist_lifted]`
  (brume dense) ; une seconde `MistLayer`, moins opaque [D : alpha × 0,4], dans une `FlagGate if
  [tower_6f_mist_lifted]`. Même palette, même profil `tower` (dossier §5.4 : « moins de brume »).
  Aucun changement de `LightingLibrary` ;
- **`SpiritLight`** : halo pâle peint (lot d'art), caché, posé sur la case (10, 17) [D : sous
  l'escalier, d'où « l'esprit » se tenait], membre du groupe `scene_props`.

### 2.8 Le 7F (T13)

**Carte** `pokemon_tower_7f` (20 × 18), par l'outil du J19 (`--etage=7f`), grille
`pokemon_tower_7f.txt` :
- escalier `escalier_bas` (9, 16) → `pokemon_tower_6f` / `arrivee_T67` ; spawn `arrivee_T67`
  (10, 16), tourné → ;
- lumière `tower`, voile un peu plus sombre [D : `ambient` 0,86, après 6F 0,88] ; halos `candle`
  sur les deux stèles et l'autel (≤ 16) ; brume du J19 (dense, sans variante) ;
- `interior = false` (comme les étages du J19 : le compagnon y est visible) ;
- `caves.json` : `pokemon_tower_7f` ajouté à la liste `pokemon_tower` (Corde Sortie → devant la
  porte, dossier §16 n° 11) ;
- `zones.json` : ajouté à la zone de la Tour ; aucune légende en changeant d'étage.

**Rencontres** `data/encounters/pokemon_tower_7f.json` :

```json
{ "pokemon_tower_top": {
    "maps": ["pokemon_tower_7f"], "terrain": "floor", "rate": 15,
    "ghost_unless_item": "silph_scope",
    "slots": [
      { "species": "gastly", "levels": [20, 24], "weight": 191 },
      { "species": "haunter", "levels": [28, 30], "weight": 39 },
      { "species": "cubone", "levels": [22, 24], "weight": 26 } ] } }
```

Sans `ramp` (règle du J19). `floor` exclut warps, déclencheurs et cases calmes (J19).

**Sbires** `data/trainers/pokemon_tower_7f.json` (modèle `mt_moon.json`) :

| Id | Équipe (RB, `parties.asm` « Pokémon Tower 7F ») | `prize_money` (30 × dernier niveau, barème Rocket) | IA |
|---|---|---|---|
| `tower_rocket_1` | `zubat` 25, `zubat` 25, `golbat` 25 | 750 | `random` |
| `tower_rocket_2` | `koffing` 26, `drowzee` 26 | 780 | `random` |
| `tower_rocket_3` | `zubat` 23, `rattata` 23, `raticate` 23, `zubat` 23 | 690 | `smart` [D, comme le 3e Sbire du J12] |

`name` « Sbire Rocket », `can_lose: false`, `heal_after: false`, `gives_exp: true`. Capacités
naturelles au niveau.

**PNJ** `data/npcs/pokemon_tower_7f.json` :
- `tower_rocket_1..3` aux cases et orientations de la grille, `sight: 3`, `sprite:
  rocket_grunt_m` (1 et 3) et `rocket_grunt_f` (2) [D], `unless [beaten_tower_rocket_<n>]`, bloc
  `trainer` (`before`, `defeated`, `after` §15.2) ;
- `mr_fuji` (10, 3), tourné ↑, `unless [fuji_rescued]`, `sprite: mr_fuji` (pose de prière en
  `idle_up`, lot d'art), dialogue `tower_7f_fuji`.

**Dialogue** `tower_7f_fuji` :
1. `if [beaten_tower_rocket_1, beaten_tower_rocket_2, beaten_tower_rocket_3]` → `cutscene:
   tower_7f_fuji_rescue` (sans page) ;
2. sinon → « … » (§15.3.1, narration).

**Scène** `tower_7f_fuji_rescue` (`data/cutscenes/j21_tower.json`), clé `next:
pokemon_house_flute` :

```text
variante  unless [fuji_rescued]
  face mr_fuji → player                    # il se relève : la pose debout est l'idle tourné
  dialogue tower_7f_fuji_thanks            # §15.3.2 à 15.3.6
  set [fuji_rescued]                       # AVANT le fondu (L-8)
  change_map pokemon_house devant_fuji up  # fondu au noir, téléportation (existant)
```

À la fin, Boot écrit la sauvegarde « entre deux scènes » (`boot.gd` l. 1322) puis joue
`pokemon_house_flute` (§2.9).

**Inévitables** : vérifiés sur la vraie scène avec ses PNJ (recherche de chemin hors des vues),
dans l'ordre 1, 2, 3 (grille).

### 2.9 Maison de Fuji et remise idempotente (T14)

**Carte** `pokemon_house` (J18, `build_painted_interiors.gd`) :
- spawn `devant_fuji` sur la case devant Fuji, tourné ↑ [D] ;
- déclencheur d'entrée `pokemon_house_flute` (sans direction) sur les cases du premier pas
  depuis la porte (choisies par T14 sur la pièce du J18) ;
- Fuji `if [fuji_rescued]`, près de la fenêtre [D], dialogue `pokemon_house_fuji` ;
- **Osselait** (Pokémon d'ambiance, sprite de monde, lot d'art) près de la fille [D], sans
  dialogue de don ; présent dès le J19 dans le texte, posé seulement au J21 (§0.2, écart 3).

**Scène** `pokemon_house_flute` (une variante) :

```text
variante  if [fuji_rescued]  unless_items [poke_flute]
  face mr_fuji → player ; face player → mr_fuji
  dialogue fuji_flute_give                 # §15.4.1 à 15.4.3
  give poke_flute  set [got_poke_flute]    # même étape ; toast existant
  dialogue fuji_flute_received             # §15.4.4 (narration)
  dialogue fuji_flute_explain              # §15.4.5
```

**Trois chemins vers la même scène**, tous gardés par la même condition :
- `next` de la scène du 7F (arrivée par téléportation) ;
- le déclencheur d'entrée ;
- le dialogue `pokemon_house_fuji`, variante `if [fuji_rescued]` + `unless_items [poke_flute]`
  → `cutscene: pokemon_house_flute`.

**Dialogue** `pokemon_house_fuji` (autres variantes, dans l'ordre) :
`if [snorlax_route_12_woken]` → §15.4.7 ; `if [snorlax_route_16_woken]` → §15.4.7 ; sinon
§15.4.6.

**Pourquoi c'est sûr** : aucune sauvegarde n'est écrite pendant une scène. Les seuls états
stables sont : avant la scène du 7F ; entre les deux scènes (`fuji_rescued`, pas de Flûte, dans
la maison) ; après la remise (Flûte et drapeau ensemble). Dans chacun, il y a exactement une
façon d'avoir la Flûte, et une seule.

### 2.10 Les deux Ronflex (T19, T20, T22)

**Données** :
- `snorlax` (143) dans `species/kanto_j21.json` : Normal ; statistiques actuelles (PV 160,
  Att 110, Déf 65, Att. Spé 65, Déf. Spé 110, Vit 30), taux de capture 25, croissance lente,
  learnset RB (`headbutt` 1, `amnesia` 1, `rest` 1, `body_slam` 35, `harden` 41, `double_edge`
  48, `hyper_beam` 56). Au N30 : Coup d'Boule, Amnésie, Repos (L-12).
- `amnesia` (`moves/j21.json`) :
  `{"name": "Amnésie", "type": "psychic", "category": "status", "accuracy": 0, "pp": 20,
  "effects": [{"kind": "stat_stage", "stat": "spd", "stages": 2, "target": "self"}],
  "description": "Le lanceur fait le vide dans sa tête. Augmente beaucoup sa Défense
  Spéciale."}`.
- Pokédex (`data/pokedex/kanto.json`, en fin) : Ronflex et Ossatueur (§15.10).
- IA : sauvage, donc tirage au hasard (existant ; dossier : `random`).

**Sur la carte** (même modèle pour les deux) :
- `FlagGate` « Ronflex » `unless [snorlax_route_<n>_done]`, `blocking_cells` 2 × 2 ; le sprite
  endormi est un `PropActor` (groupe `scene_props`, nom `Snorlax`) ;
- `InteractPoint` 2 × 2, `unless_flags [snorlax_route_<n>_done]`, dialogue
  `snorlax_route_<n>`, **`flute_cutscene: snorlax_route_<n>_wake`**.

**Dialogue** `snorlax_route_12` (reprend les textes T-6 / T-7 de `route_11_snorlax` du J17) :

| Ordre | Condition | Contenu |
|---|---|---|
| 1 | `if_items [poke_flute]`, `if [snorlax_route_12_woken]` | §15.7.5, puis « Jouer de la Poké Flûte ? » + choix |
| 2 | `if_items [poke_flute]` | « Jouer de la Poké Flûte ? » + choix |
| 3 | `unless [snorlax_route_12_seen]`, `set [snorlax_route_12_seen]` | T-6 (J17) |
| 4 | — | T-7 (J17) |

Choix : `"confirm": "OUI", "cancel": "NON"` (dossier §8.3), `confirm_cutscene:
snorlax_route_12_wake` ; NON → rien.

**Scène** `snorlax_route_12_wake` (`data/cutscenes/j21_snorlax.json`) :

```text
variante  unless [snorlax_route_12_done]
  flute                                         # notes ≈ 1,5 s
  dialogue snorlax_flute_played                 # §15.6.3 « {player} joue de la Poké Flûte. »
  react Snorlax ; emote Snorlax exclamation     # petit saut, « ! » (acteur de décor)
  dialogue snorlax_wakes                        # §15.7.2
  set [snorlax_route_12_awake, snorlax_route_12_woken]
  wild_battle snorlax 30
      win [snorlax_route_12_done]
      catch [snorlax_route_12_done, snorlax_route_12_caught]
      clear [snorlax_route_12_awake]
  dialogue snorlax_calms   if [snorlax_route_12_done]  unless [snorlax_route_12_caught]  # §15.7.3
  dialogue snorlax_sleeps  unless [snorlax_route_12_done]                               # §15.7.4
```

- **K.O.** : `_done` → la `FlagGate` se cache (Boot `_on_flag_changed`, existant) → texte.
- **Capture** : `_done` + `_caught` ; équipe ou Stockage (`_finish_capture`) ; aucun texte.
- **Fuite** : `_awake` effacé ; « Ronflex bâille… » ; il reste.
- **Défaite** : `_awake` effacé **avant** `wake_up` ; réveil au Centre ; il dort toujours.
- **Fond de combat** : celui de la carte (Route 12 : `route_24_pont` [D], existant).
- Le dialogue `snorlax_route_16` et la scène `snorlax_route_16_wake` sont identiques, avec
  leurs propres drapeaux (`snorlax_route_16_*`). Un test vérifie qu'aucune donnée d'un Ronflex
  ne cite un drapeau de l'autre.

**M-3 (Kevin, 2026-10-16 ; passe du J22, dossier 25 §5)** : le Ronflex « est » est posé **sur la
carte de la Route 12, au croisement** (grille `route_12.txt` révisée : passage de 2 cases, Ronflex
2 × 2, repères `face_ronflex` nord / ouest / sud), et non plus sur la Route 11.

**Route 11 (J17, `tools/build_route_11.gd`, bloc J21)** :
- **retirer** `SNORLAX_FLAG`, le `FlagGate` « Ronflex endormi », le `SnorlaxPoint` 2 × 2 et le sprite
  endormi ; (66..67, 14..15) deviennent du chemin (retouche de `route_11.txt` à l'intégration) ;
  dialogue `route_11_snorlax` (T-6, T-7) **repris** par le point de la Route 12 ;
- **raccord est** : warp PUSH → (75, 14..15) vers `route_12` / `from_route_11` ; spawn
  `from_route_12` (74, 14..15), tourné ← (§19).

**Route 12** : `FlagGate` + `InteractPoint` 2 × 2 au croisement (`unless [snorlax_route_12_done]`),
`flute_cutscene: snorlax_route_12_wake` ; on lui parle depuis les cases `face_ronflex`.

### 2.11 Route 12 nord (T21)

**Carte** `route_12` (39 × 102, grille `route_12.txt`, échelle × 1,5 [D, §19]) :
- outil `tools/build_route_12.gd` sur `tools/coast_map_kit.gd` (eau, rivage, ponton ; modèle
  `build_route_11.gd`) ;
- raccords : `warp_nord` (21..23, 0) → `lavender_town` / `from_route_12` ; `warp_ouest` (0,
  93..94) → `route_11` / `from_route_12` ; `warp_sud` (24..26, 101) `coming_soon` « Route 12 »
  (J22) ; spawns `from_lavender`, `from_route_11`, `from_route_12_sud` (non utilisé) ;
- **poste** : portes `porte_poste_nord` (24..26, 24) et `porte_poste_sud` (24..26, 32) →
  `route_12_gate` / `entrance_nord|sud` ; sorties `from_poste_nord|sud` ;
- îlot de la CT Jackpot : **décor vide** (§19) ; aucun objet ;
- panneaux `panneau_route_12` (28, 20) → §15.8.1, `panneau_ponton` (position de la grille révisée) → §15.8.2 ;
- **aucune herbe, aucune table de rencontres** (RB : herbes au sud du croisement seulement ;
  vérifié sur `Route12.blk` : rangées 100 à 107) ;
- lumière `golden_hour` [D] ; fond de combat `route_24_pont` [D, pont sur l'eau] dans
  `decors.json` (`places.route_12`).

**Intérieur** `route_12_gate` (`build_painted_interiors.gd`, pièce en fin, modèle des postes de
la forêt du J9) : 1F traversant (portes nord et sud de 3 cases), escalier vers un 2F
`route_12_gate_2f` (pièce de maison) [D]. 2F : jeune femme `tm39_girl`, dialogue
`route_12_gate_tm39` :
1. `unless [got_tm39]` → `cutscene: route_12_gate_tm39` ;
2. sinon → §15.8 bis.2.

Scène : dialogue §15.8 bis.1 (première page) → `give tm39 set [got_tm39]` → narration « {player}
obtient la CT39 — Météores ! » → « Météores ne rate jamais sa cible. ».

**Pêcheurs** `data/trainers/route_12.json` (RB, `parties.asm` « Route 12 », Pêcheurs n° 3 à 6 ;
le n° 11, Magicarpe ×2, est au sud : J22) :

| Id | Case (grille) | Vue | Équipe (RB) | Récompense |
|---|---|---|---|---|
| `route_12_fisher_1` | (30, 47) ←, **inévitable** | 6 | `goldeen` 22, `poliwag` 22, `goldeen` 22 | `prize_per_level` 35 (RB) |
| `route_12_fisher_2` | (17, 59) ↑ | 6 | `tentacool` 24, `goldeen` 24 | 35 |
| `route_12_fisher_3` | (27, 60) ← | 6 | `goldeen` 27 | 35 |
| `route_12_fisher_4` | (23, 78) → | 6 | `poliwag` 21, `shellder` 21, `goldeen` 21, `horsea` 21 | 35 |

- `name` « Pêcheur <Prénom> » (prénoms : annexe A) ; `ai: random` ; sprite `pecheur` (planche
  existante, `build_character_frames.gd` l. 64 : `haru`).
- **Espèces nouvelles** : `poliwag` (60, Eau ; évolution vers Têtarte **absente** tant que
  `poliwhirl` n'existe pas, précédent J19 « pierre absente : aucune »), `tentacool` (72, Eau /
  Poison ; Tentacruel absent : aucune évolution). `goldeen`, `shellder`, `horsea` existent
  (`kanto.json`).
- Capacités au niveau : Ptitard N21–22 = Écume, Hypnose, Pistolet à O ; Tentacool N24 =
  Ultrason, Ligotage, Dard-Venin, Pistolet à O. Toutes existent après T9 (Hypnose J17/J19) ;
  T5 vérifie, sinon remplacement par une capacité existante de l'espèce (règle des J16 à J19).

**Zone** : `zones.json` (en fin) : `route_12` « Route 12 », description §15.8.3 ;
`route_12_visited` (titre d'arrivée, méthode existante).

### 2.12 Route 16 est et Céladopole (T22)

**Carte** `route_16` (44 × 28, grille `route_16.txt`) :
- outil `tools/build_route_16.gd` sur `pewter_map_kit.gd` (forêt serrée, chemin) ;
- `warp_est` (43, 21..23) → `celadon_city` / `from_route_16` ; spawn `from_celadon` ← ;
- Ronflex 2 × 2 en (24..25, 22..23) (§2.10), `face_ronflex` (26, 22..23) ;
- porte du poste (15..16, 20) : `coming_soon` « Route 16 » ; façade, voie haute et arbre :
  décor bloquant, **aucun examen** ; aucun texte sur le Vélo (L-4) ;
- **aucune herbe, aucune rencontre** (§19) ; lumière `golden_hour` [D] ; fond de combat
  `route_5_6_prairie` [D] ; zone `route_16` « Route 16 », description §15.8.4,
  `route_16_visited`.

**Céladopole** (J20, `celadopole.txt` et `build_celadon_city.gd`) :
- (0..3, 21..23) passent en chemin ; `warp_ouest` (0, 21..23) PUSH ← → `route_16` /
  `from_celadon` ; spawn `from_route_16` (1, 21..23) [D : première colonne praticable], tourné → ;
- `obstacle_ouest` (3, 22) et son texte T-21 retirés ;
- **avant T9**, la modification vit dans une **variante** `tools/plans/celadopole_j21.txt`
  (seulement la bande ouest, contrôle dans `plan_check_j21.py`), comme la variante J18 d'Azuria.
  T22 l'applique à la grille du J20 une fois fusionnée.

### 2.13 Lavanville après le sauvetage et objectifs (T14)

**Variantes** (en tête de chaque dialogue, `if [fuji_rescued]`) :

| PNJ | Fichier | Texte |
|---|---|---|
| Gardienne (Exorciste du 1F, J18/J19) | `data/dialogues/pokemon_tower.json` | §15.5.1 |
| Enfant, Maison des Pokémon (J18) | `lavender_houses.json` | §15.5.2 |
| Homme, Maison des Pokémon (J19) | `pokemon_house.json` (dialogues) | §15.5.3 |
| Fille, près d'Osselait (J19) | idem | §15.5.4 |
| Gentleman du Centre (J19) | `lavender_center.json` (dialogues) | §15.5.5 |

Les autres PNJ ne changent pas. Avant le sauvetage, rien ne change (dossier §4).

**Lavanville, bord sud** (`build_lavender_town.gd`, J18) : `warp_sud` (21..23, 35) → `route_12` /
`from_lavender` (au lieu du `coming_soon`).

**Objectifs** (`data/story/objectives.json`, **en tête**) :

```json
{ "id": "visit_fuji", "text": "rendre visite à M. Fuji.",
  "if": ["fuji_rescued"], "unless": ["got_poke_flute"] },
{ "id": "find_fuji", "text": "trouver M. Fuji, au sommet de la Tour.",
  "if": ["ghost_marowak_calmed"], "unless": ["fuji_rescued"] }
```

et `"unless": ["ghost_marowak_calmed"]` ajouté à `back_to_tower` (J20). Après la Flûte, aucun
objectif du J21 ne s'applique. Les objectifs lisent des drapeaux : `back_to_tower` lit
`got_rocket_hideout_b4f_silph_scope` (J20), pas la possession ; c'est cohérent (le Scope ne se
perd pas).

### 2.14 Sauvegarde : **aucun changement de version** (v7)

- `SaveSystem.VERSION` reste **7** (`save_system.gd:36`).
- Drapeaux du J21 (tous dans `StoryFlags`, déjà sérialisés) :
  - `ghost_marowak_calmed`, `tower_6f_mist_lifted` ;
  - `beaten_tower_rocket_1`, `_2`, `_3` ;
  - `fuji_rescued`, `got_poke_flute` ;
  - `snorlax_route_12_awake` (jamais sur disque), `_woken`, `_caught`, `_done` ; idem `16` ;
  - `got_tm39`, `route_12_visited`, `route_16_visited` ;
  - `snorlax_route_16_seen` [D, si le dialogue de la Route 16 reprend T-6 / T-7 ; sinon absent].
- La Flûte et la CT39 sont des identifiants du Sac (existant). Ronflex capturé est un Pokémon de
  l'équipe ou du Stockage (existant).
- Le `FlagGate` et la brume se **déduisent** des drapeaux (aucune donnée de plus).

**Tests d'interruption** (`tests/integration/test_save_j21.gd`, vraie Boot, modèle
`test_save_j19` du plan J19 ; on sauvegarde, on recharge, on vérifie) :

| n° | Point de coupure | Attendu au rechargement |
|---|---|---|
| 1 | Après la victoire contre Ossatueur (fin de scène), avant le 7F | 6F : brume légère, aucun déclencheur ; escalier praticable ; objectif « trouver M. Fuji… » |
| 1 bis | Application tuée **pendant** la scène du 6F (après le combat) | sauvegarde d'avant : Ossatueur à refaire, combat neuf (dossier §16 n° 2) |
| 2 | Entre le dernier Sbire et Fuji | Sbires absents, Fuji au 7F, qui répond |
| 3 | Sauvegarde « entre deux scènes » (`fuji_rescued`, pas de Flûte) | joueur dans la maison ; Fuji présent ; parler à Fuji **ou** sortir et rentrer → remise ; **une** Flûte |
| 3 bis | Application tuée pendant le fondu du 7F | sauvegarde d'avant : Fuji au 7F ; la scène se rejoue |
| 4 | Après la remise | une Flûte, `got_poke_flute` ; la scène ne se rejoue pas ; Fuji §15.4.6 |
| 5 | Après réveil + fuite (Ronflex 11) | Ronflex en place ; `_awake` absent ; `_woken` présent ; §15.7.5 à l'examen |
| 6 | Après réveil + défaite (Ronflex 16) | réveil au Centre ; Ronflex 16 en place ; `_awake` absent |
| 7 | Après capture (Ronflex 11) | Ronflex 11 absent, passage libre ; Ronflex dans l'équipe ou le Stockage ; **Ronflex 16 inchangé** |
| 8 | Après K.O. (Ronflex 16) | absent, passage libre ; Ronflex 11 inchangé |
| 9 | Sauvegarde J20 (fixture : Scope, aucun drapeau du J21) relue | rien ne change avant le 6F ; révélation au 6F |
| 10 | Sauvegarde J19 sans Scope relue | 6F : SPECTRE du J19, inchangé (§16 n° 1) |
| 11 | Reprise sur une case libérée par un Ronflex `_done` | aucun décalage (`SceneRouter.arrival_flags`, J17) |

Plus : `test_the_jalon_21_adds_no_save_version` (`VERSION == 7`) ; chaque drapeau du J21 survit à
un aller-retour.

### 2.15 Départs de débogage (`tools/debug_start/`, README complété)

Équipe de référence [D] : starter évolué N33, Roucarnage N30, Papilusion N28 (Poudre Dodo),
Évoli N25 (don du J20), Nidorino N28 **endormi** (`status_turns` 3), un Pokémon N26 empoisonné.
Sac : **10 Poké Balls, 10 Super Potions, 3 Réveils, 2 Cordes Sortie**, `silph_scope`. 5 000 ₽.
Badges jusqu'au Prisme (J20). Drapeaux des J18 à J20 jusqu'à
`got_rocket_hideout_b4f_silph_scope`. T9 recale l'équipe sur les sorties réelles du J20.

| Départ | Sous-jalon | Contenu |
|---|---|---|
| `tower_marowak_qa` | 21A | 6F, `devant_spectre` (10, 14), E8, E9, rival battus ; Scope dans le Sac |
| `tower_marowak_noscope` | 21A | Idem **sans** Scope : SPECTRE du J19 (non-régression) |
| `tower_marowak_weak` | 21A | Idem avec Salamèche N8 seul : défaite → Centre de Lavanville, déclencheur réarmé |
| `tower_7f_qa` | 21A | 7F, `arrivee_T67`, `ghost_marowak_calmed`, `tower_6f_mist_lifted` ; Sbires non battus |
| `fuji_flute_qa` | 21A | Maison des Pokémon, `fuji_rescued`, **sans** Flûte (cas « entre deux scènes ») |
| `poke_flute_qa` | 21B | Route 12, case `face_ronflex` ouest, tournée →, Flûte, équipe avec un endormi ; table `wild` forcée (Paras N24, Spore) pour tester la Flûte en combat |
| `snorlax_16_qa` | 21B | Route 16, `face_ronflex` (26, 22) tourné ←, Flûte, 1 Poké Ball (pour la fuite et la défaite) |
| `route_12_qa` | 21B | Lavanville, `from_route_12`, Flûte ; Pêcheurs non battus ; `got_tm39` absent |
| `j21_full_qa` | 21B | Lavanville devant la Tour (`retour_tour`), Scope, rien du J21 : parcours complet |

`poke_flute_qa` utilise la Spore de Paras (`spore`, `main`) pour endormir ; si Paras n'est pas
dans les données à T9, une autre espèce à capacité de sommeil existante [D].

### 2.16 Art (lot 21.0) — **série 23** proposée

Séries existantes vérifiées sur toutes les branches : 17 (J15, `serie-17-carmin.md`), **18
réservée au J16** (défaut de `jalon-16.md` §1.4, aucune fiche encore), 19 (J17,
`serie-19-chemins.md`), 20 (J19, `serie-20-tour-pokemon.md`). Le J18 et le J20 prennent « le
prochain numéro libre » et n'ont pas encore de fiche : **21 et 22 leur sont laissés**, dans
l'ordre des jalons. **Défaut : série 23 pour le J21**, revérifiée au T6 (fiche
`docs/design/fiches-assets/serie-23-repos-des-esprits.md`, outil `tools/art/serie23.py`).

| Élément | État | Besoin |
|---|---|---|
| **Vue peinte du 7F** | rien | Sur l'enveloppe du J19 ; autel, bougies, Fuji agenouillé (référence) |
| **Vue peinte de la Route 12 nord** | rien | Ponton, eau, poste traversant, éperons, îlot vide |
| **Vue peinte de la Route 16 est** | rien | Forêt serrée, goulet, façade du poste, voie haute en décor |
| Variante « apaisée » du 6F | — | **Texture de brume** du J19 réutilisée, alpha réduit : rien à peindre [D] |
| **Planche M. Fuji** | rien (vieil homme générique existant : `vieil_homme_sheet.png`) | Vieil homme reconnaissable, marche 4 directions **+ pose de prière agenouillée** |
| Pêcheur | **existe** (`pecheur_sheet.png`, `pecheur_idle_sheet.png`) | rien |
| Sbires Rocket | existent (`rocket_grunt_m/f_frames.tres`) | rien |
| **Osselait, sprite de monde** | rien (§0.2 écart 3) | Petit Pokémon peint d'ambiance (≈ 56 px), repos + petite animation |
| Ossatueur (face) | artwork officiel `official/105.png` (`main`) | rien ; **pas de dos** |
| Ronflex (face) | `official/143.png` (`main`) | rien |
| **Ronflex (dos)** | rien | Dos de combat (pipeline des dos, capturable) |
| Ronflex endormi (monde) | `snorlax_frames.tres` (J17, série 19) | rien |
| Ptitard, Tentacool (face) | `official/060.png`, `072.png` | rien |
| Ptitard, Tentacool (dos) | Tentacool : `dos_ia_072` provisoire ; Ptitard : rien | Provisoire suffisant (espèces de Dresseur, jamais au joueur au J21) [D] |
| **Icône de la Poké Flûte** | rien | `assets/ui/icons/items/poke_flute.svg` (UI, non pixel art, skill `ui-theme-2026`) |
| **Notes de musique** | rien | 1 à 2 notes peintes simples (effet `FluteNotes`) |
| **Halo `SpiritLight`** | rien | Petit halo pâle (ou réemploi d'un halo `candle` décoloré [D]) |
| Fonds de combat | `tour_pokemon` (J19), `route_11_coast` (J17), `route_24_pont`, `route_5_6_prairie` | rien |
| Intérieur du poste de la Route 12 | coques des postes (J9) et maison | 2F : réemploi de la coque de maison [D] |

---

## 3. Tâches

Chaque tâche :
- part d'une branche `j21-t<n>-<sujet>` créée depuis `jalon-21` ;
- n'utilise jamais `pkill` ni `killall` (arrêter ses propres processus par PID) ;
- reprend les textes **mot pour mot** (dossier §15 et annexe A validés) ;
- met à jour `docs/tech/etat-projet.md` dans son commit ;
- **CA communs** : `tools/test.sh` vert ; `godot --headless --path . --import` sans `ERROR`.

Agents : **A** architecte-godot, **C** constructeur-monde, **U** ui-mobile, **Q** qa-mobile, **K**
Kevin.

### 3.1 Sous-jalon 21.0

#### T0 — A : plan (ce document)

#### T1 — A : branche `jalon-21` — **maintenant**
- Créer `jalon-21` depuis `origin/main` dans une copie dédiée ; y fusionner `docs/dossier-24-j21`
  et `j21-plan`.
- **CA** : tests verts, import propre ; `python3 -I tools/art/plan_check_j21.py` conforme.

#### T2 — A puis K : textes — **maintenant**
- Annexe A : 4 Pêcheurs (prénoms, avant, défaite, après) ; libellés OUI / NON ; description de la
  CT39 ; noms de zone ; ligne système de la CT39 ; réplique « examen » de Ronflex 16 si différente.
- **CA** : Kevin valide l'annexe A **et le §15 du dossier** en une passe. Bloque les données de
  texte (T5, T12 à T14, T20 à T22), pas le code.

#### T3 — A : logique pure de la Flûte — **maintenant**
- Fichiers nouveaux : `game/items/flute_target.gd`, `game/items/poke_flute_rules.gd` (§2.2).
- **Tests** `tests/unit/test_poke_flute_rules.gd` :
  - `field_target` : vrai depuis chacune des 4 cases voisines d'un bloc 2 × 2 ; faux en
    diagonale, à 2 cases, sur un bloc caché par ses drapeaux ; deux cibles → la bonne scène ;
  - `sleepers` : joueur puis adversaire ; K.O. exclus ; autres statuts exclus ;
  - `wake_all` : statut et compteur à 0 ; PV, autres statuts et confusion inchangés ; Pokémon de
    Repos (compteur 2) réveillé ; liste vide → rien.
- **CA** : aucun fichier existant modifié.

#### T4 — A : données valides sur `main` — **maintenant**
- `data/pokemon/moves/j21.json` (`amnesia`) ; `data/items/items_j21.json` (`tm39` ; `poke_flute`
  sans `key_use`).
- **Tests** : `test_moves_j21` (Amnésie : Déf. Spé. +2, soi-même, description unique) ;
  `test_item_library` (deux objets ; `tm39` permanente, invendable ; `poke_flute` objet clé, sans
  prix) ; `test_tm` (CT39 enseigne Météores aux compatibles).

#### T5 — A : données qui dépendent des J17 et J19 — **rédigées maintenant, fusionnées après T9**
- `species/kanto_j21.json` (`snorlax`, `poliwag`, `tentacool`) ; `pokedex/kanto.json` (en fin :
  Ossatueur, Ronflex ; Ptitard et Tentacool : textes Q-3) ; `trainers/pokemon_tower_7f.json`,
  `trainers/route_12.json` ; `encounters/pokemon_tower_7f.json` ; `companions.json` : **aucune**
  entrée (Ronflex compagnon hors jalon).
- **Tests** : `test_pokemon_data` (comptes ; Ronflex N30 = Coup d'Boule, Amnésie, Repos ;
  Ossatueur N30 = Massd'Os, Rugissement, Groz'Yeux, Puissance ; aucune évolution vers une espèce
  absente) ; `tests/unit/test_trainers_j21.gd` (7 Dresseurs, équipes RB, récompenses, aucune
  `pending_effects` au niveau donné) ; `test_tower_encounters` (table du 7F : 191/39/26, taux 15,
  sans `ramp`, `floor`) ; `test_pokedex_library` ; `test_battle_art` (dos de Ronflex exigé ;
  Ossatueur sans dos toléré).

#### T6 — A : kit d'art, série 23 — **maintenant**
- §2.16 ; fiche, prompts, planche `build/art/J21_KIT_v1.png`.
- **CA** : chaque élément du tableau a un asset (réutilisé, varié ou nouveau) ou est abandonné
  explicitement.

#### T7 — C (Mac, Codex) : génération, planche de contact → K, intégration — après T6
- Fuji, Osselait (monde), dos de Ronflex, icône, notes, halo ; entrées en fin de manifeste,
  `build_character_frames.gd` (`mr_fuji` avec l'animation `pray`).
- **CA** : un second passage ne change rien ; Kevin valide la planche.

#### T8 — C : vues peintes et variante de Céladopole — **maintenant**
- Vues générales du 7F, de la Route 12 nord, de la Route 16 est (prompts, génération, plans en
  aplats) → K ; `tools/plans/celadopole_j21.txt` (bande ouest) + son contrôle dans
  `plan_check_j21.py`.
- **CA** : Kevin valide grilles (§19) et vues ; contrôle conforme.

#### T9 — A : alignement après la clôture du J20 — **après la clôture du J20**
- Fusionner `origin/main` (J16 à J20) dans `jalon-21`, puis les branches de T5.
- Vérifier chaque ligne du §0.2 et du §0.3 ; noter les écarts ici (§0).
- Vérifier que le J19 a livré `wild_battle`, `refuses_balls`, `MistLayer`,
  `build_pokemon_tower.gd` sous les noms du plan ; que le J20 a livré `if_items` (dialogues) et
  `back_to_tower`.
- Recaler l'équipe des départs (§2.15) sur les sorties réelles du J20.
- **M-3** : retirer Ronflex de la Route 11 (`route_11.txt`, `tools/build_route_11.gd` : `FlagGate`,
  `SnorlaxPoint`, sprite) ; régler en même temps les doublons J17 / J19 (`hypnosis`, `roar`,
  `take_down`, `growlithe`).
- **CA** : tests verts ; liste des écarts écrite au §0 ; T10 peut partir.

### 3.2 Sous-jalon 21A (la Tour résolue)

#### T10 — A : scènes et combat sauvage scripté — après T9
- Fichiers : `cutscene_step.gd`, `cutscene_library.gd`, `cutscene_director.gd`,
  `cutscene_variant.gd`, `cutscene.gd` (§2.3 : `if_items`/`unless_items`, clés de
  `wild_battle`, `give` + `set`, `animate.skip_reduced`) ; `wild_encounter.gd`,
  `battle_request.gd`, `battle_rules.gd`, `battle.gd` (`refuses_balls`), `battle_director.gd`
  (refus, intro révélation côté directeur), `battle_text.gd`, `messages.json`
  (`ball_uncatchable`, `ghost_revealed`, `ghost_revealed_species`).
- **Tests** :
  - `test_cutscene_library` : clés acceptées ; `reveal` + `ghost: always` refusé ; `clear` non
    vide ; `if_items` vide refusé ;
  - `test_cutscene_variant` : `if_items` / `unless_items` selon le Sac ; sans Sac ;
  - `tests/integration/test_cutscene_wild_battle_j21.gd` : `flee` / `catch` levés selon l'issue ;
    `clear` effacé **dans les quatre issues**, et **avant** le réveil sur `LOSS` (la sauvegarde
    « réveil » ne le contient pas) ; `give` + `set` : rien de levé si l'objet est inconnu ;
  - `tests/unit/test_battle_uncatchable.gd` : Ball refusée, nombre inchangé, aucun tour, aucun
    tirage ; fuite par `FleeCalc` (peut échouer) ; XP gagnée ; mode spectre inchangé ;
  - `test_battle_reveal` : événements non masqués ; Ossatueur « vu » au Pokédex.
- **CA** : `test_battle*.gd` et les tests du J19 verts sans changer leurs attentes.

#### T11 — U : intro « révélation » — après T10
- `battle_stage.gd` : `dissolve_foe(species)` (fondu croisé 1,0 s, `Tween`, coupé par « Réduire
  les animations »).
- **Tests** : `test_battle_stage_reveal` (`TweenClock` : silhouette pleine au départ, artwork
  plein à 1,0 s au pas près ; instantané en animations réduites).
- **Captures 2340 × 1080** : silhouette + `ghost_revealed`, mi-fondu, Ossatueur + « C'est un
  Ossatueur ! », refus de la Ball.

#### T12 — C : 6F révélé et brume — après T10, T11, T7
- `data/cutscenes/pokemon_tower_floors.json` (variante A en tête), `data/dialogues/j21_tower.json`
  (§15.1.5–7) ; `tools/build_pokemon_tower.gd` (bloc J21 : `arrivee_T67`, escalier réel, deux
  brumes, `SpiritLight`) ; grille du 6F (`arrivee_T67`) ; départs `tower_marowak_qa`, `_noscope`,
  `_weak`.
- **Tests** `tests/integration/test_tower_6f_marowak.gd` :
  - avec Scope : pas sur (10, 16) → §15.1.1 → combat révélé → victoire → §15.1.6 → lumière →
    §15.1.7 → `tower_6f_mist_lifted` ; brume légère visible, dense cachée ; escalier → 7F ;
  - fuite : recul en (10, 15), §15.1.5 ; on recommence : combat neuf, PV pleins (§16 n° 2) ;
  - défaite : Centre de Lavanville ; déclencheur réarmé ;
  - Ball refusée, non consommée ;
  - sans Scope : déroulé du J19, mot pour mot ;
  - « Réduire les animations » : textes et brume gardés, lumière sautée ;
  - compagnon : il rentre à la scène, ressort ensuite ; ni blocage ni chevauchement (§16 n° 10).
- **CA** : captures du 6F avant / après.

#### T13 — C : 7F, Sbires, Fuji, téléportation — après T10, T5, T7
- `tools/build_pokemon_tower.gd -- --etage=7f` ; `game/world/maps/pokemon_tower_7f.tscn` ;
  `data/npcs/pokemon_tower_7f.json` ; dialogues §15.2, §15.3 ; scène
  `tower_7f_fuji_rescue` ; `caves.json`, `zones.json`, `lighting.json`, `light_glows.json` ;
  départ `tower_7f_qa`.
- **Tests** `tests/integration/test_pokemon_tower_7f.gd` :
  - grille = plan ; paire T67 aller-retour ; ≤ 3 000 nœuds, ≤ 16 halos, aucune `Light2D` ;
  - Sbires inévitables dans l'ordre 1, 2, 3 (recherche de chemin sur la vraie scène) ; textes
    mot pour mot ; `beaten_tower_rocket_<n>` gardés après rechargement ;
  - défaite contre un Sbire : Centre ; Sbires battus absents ; Ossatueur reste apaisé (§16 n° 3) ;
  - Fuji avant les Sbires (debug) : « … » ; après : §15.3.2–6 → `fuji_rescued` posé **avant** le
    changement de carte → joueur dans la maison, `devant_fuji` ;
  - Corde Sortie au 7F : devant la Tour ; Fuji non sauvé attend (§16 n° 11) ;
  - rencontres : jamais sur l'escalier ni sur une case de PNJ ; taux 15.

#### T14 — C : Maison de Fuji, Lavanville, objectifs — après T13
- `build_painted_interiors.gd` (pièce `pokemon_house`, bloc J21 : `devant_fuji`, déclencheur
  d'entrée) ; `data/npcs/pokemon_house.json` (Fuji, Osselait) ; scène `pokemon_house_flute` ;
  dialogues §15.4, §15.5 ; `objectives.json` ; départ `fuji_flute_qa`.
- **Tests** `tests/integration/test_fuji_flute.gd` :
  - téléportation → remise → **une** Flûte, `got_poke_flute`, toast ;
  - les trois chemins (suite, entrée, dialogue) donnent la remise **une seule fois** au total ;
  - Flûte déjà dans le Sac sans drapeau (debug) → aucune remise ;
  - drapeau sans Flûte (fichier retouché) → remise (la possession fait foi) ;
  - Fuji après : §15.4.6 ; avec `_woken` : §15.4.7 ;
  - variantes de Lavanville mot pour mot, seulement avec `fuji_rescued` ;
  - objectifs : `back_to_tower` → `find_fuji` → `visit_fuji` → aucun du J21.

#### T15 — A : contrat et interruptions 21A — après T12 à T14
- `tests/integration/test_save_j21.gd` (n° 1 à 4, 9, 10 du §2.14) ;
  `tests/unit/test_j21_flags_contract.gd` (toute donnée qui pose un drapeau du J21 est dans un
  fichier du J21 ou un bloc « J21 » ; aucune donnée du J19 / J20 n'en pose, sauf le `unless` du
  6F) ; `VERSION == 7`.

#### T16 — Q : **session 21A** → K — après T15

Protocole des J15–J19 : APK debug, `tools/deploy_s24.sh --debug-start <départ>`, **30 à 45 min**,
preuves `21a_<n>.png`, rapport `build/qa/jalon21_t16/`.

| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `tower_marowak_noscope` | descendre sur (10, 16) | SPECTRE du J19, recul : rien n'a changé |
| 2 | `tower_marowak_qa` | idem | §15.1.1, silhouette, « Le Scope Sylphe révèle… », fondu, « C'est un Ossatueur ! » |
| 3 | (suite) | SAC → Poké Ball | « Ce Pokémon ne peut pas être capturé. », Balls inchangées, retour au choix |
| 4 | (suite) | FUITE (jusqu'à réussir) | recul, §15.1.5 ; revenir : combat neuf |
| 5 | (suite) | gagner | §15.1.6, lumière, §15.1.7, brume plus légère ; Pokédex : Ossatueur vu |
| 6 | `tower_marowak_weak` | perdre | Centre de Lavanville ; retour : la scène se rejoue |
| 7 | `tower_7f_qa` | monter vers Fuji | 3 Sbires inévitables, textes ; Fuji, fondu, maison, Flûte, toast, explication |
| 8 | `fuji_flute_qa` | entrer / parler | remise une fois ; ressortir, rentrer : rien |
| 9 | (suite) | Lavanville | gardienne, enfant, homme, fille + Osselait, gentleman ; objectifs |
| 10 | (fps) | 6F, 7F | ≥ 58 fps de moyenne, creux ≥ 50 |

**CA** : validation de Kevin.

### 3.3 Sous-jalon 21B (la Flûte)

#### T17 — A : objet clé utilisable — après T16 (ou en parallèle de T12–T14 si le moteur est libre)
- Fichiers (§2.1, §2.2, §2.4) : `item_data.gd`, `item_library.gd`, `field_item_rules.gd`,
  `items_j21.json` (`key_use`), `boot.gd` (aiguillage de `field_item_requested`, bulle du
  compagnon), `battle_action.gd`, `battle_event.gd`, `battle.gd`, `battle_director.gd`,
  `battle_text.gd`, `messages.json`.
- **Tests** :
  - `test_item_data` : contextes de la Flûte ; autres objets clés toujours sans contexte ;
    `key_use` hors catégorie `key` refusé ;
  - `test_field_item_rules` : Flûte OK partout, sans cible ;
  - `tests/unit/test_battle_flute.gd` (moteur pur, graines fixes) : réveil du joueur et du
    sauvage ; contre un Dresseur, **toute** l'équipe adverse ; K.O. ignorés ; tour pris
    (l'adversaire agit) ; sans dormeur : `is_legal` faux, aucun tour, aucun tirage ; Flûte non
    consommée ; Repos réveillé ; mode spectre ; Patience : refusée ;
  - `tests/integration/test_poke_flute_field.gd` : « ailleurs » (§15.6.6), bulle « ♪ » si le
    compagnon est sorti ; Flûte jamais retirée du Sac.

#### T18 — U : présentation de la Flûte — après T17
- `BattleBagPanel` (onglet OBJETS CLÉS), cartes (pastille retirée sur `FLUTE_WOKE`),
  `game/world/effects/flute_notes.gd`, icône.
- **Tests** : `test_battle_bag_panel` (onglet présent seulement avec la Flûte ; UTILISER) ;
  `test_flute_notes` (`TweenClock` : fin à 1,5 s au pas près ; rien en animations réduites ;
  libéré à la fin).
- **Captures** : Sac de combat (onglet), « Personne ne dort… », réveil, notes en exploration.

#### T19 — A : étape `flute`, acteurs de décor, cibles de la Flûte — après T17
- `cutscene_step.gd` (`FLUTE`), `cutscene_director.gd` (`flute`, `react` / `emote` sur un
  acteur de décor), `game/world/prop_actor.gd`, `interact_point.gd` (`flute_cutscene`),
  `game/world/map.gd` (`flute_targets()`).
- **Tests** : `test_cutscene_library` (`flute`) ; `test_prop_actor` ; `test_map_flute_targets`
  (carte de test : un point 2 × 2 → une cible ; caché par drapeau → aucune).

#### T20 — C : Ronflex du croisement de la Route 12 (M-3) — après T19, T5, T21
- `tools/build_route_12.gd` (Ronflex : `FlagGate`, `PropActor`, `InteractPoint`, `flute_cutscene`) ;
  `tools/build_route_11.gd` (bloc J21 : **retrait** de Ronflex, warp est, `from_route_12`) ; `data/dialogues/j21_snorlax.json` (§15.7, choix) ; scène
  `snorlax_route_12_wake` ; départ `poke_flute_qa`.
- **Tests** `tests/integration/test_snorlax_route_12.gd` :
  - sans Flûte : T-6 puis T-7 (J17 inchangé) ; passage fermé ;
  - parler avec la Flûte : choix ; NON → rien ; OUI → réveil → combat ;
  - Sac → UTILISER depuis chaque case `face_ronflex` (nord, ouest, sud) → réveil ; à 2 cases → « ailleurs » ;
  - les quatre issues (§2.10), avec la sauvegarde relue (§2.14 n° 5, 7) ;
  - réveils répétés jusqu'au `_done` (§16 n° 9) ; Repos puis Flûte en combat (§16 n° 7) ;
  - équipe pleine → Stockage (§16 n° 8) ;
  - avant `_done` : depuis Lavanville, ni la Route 11 ni le sud ; depuis la Route 11, ni Lavanville
    ni le sud ; après `_done` : les cases de Ronflex praticables, les trois bras reliés ;
  - la Route 11 n'a plus de Ronflex (66..67, 14..15 praticables dès le J21) ;
  - compagnon : passe avec le joueur après le réveil (§16 n° 10).

#### T21 — C : Route 12 nord, poste, Pêcheurs, raccords — après T19, T5, T8 (avant T20)
- `tools/build_route_12.gd`, `game/world/maps/route_12.tscn`, pièces `route_12_gate` et
  `route_12_gate_2f`, `data/npcs/route_12.json`, `route_12_gate.json`, dialogues (§15.8,
  annexe A), scène de la CT39 ; `build_lavender_town.gd` (bord sud) ; `zones.json`,
  `decors.json` ; départ `route_12_qa`.
- **Tests** `tests/integration/test_route_12.gd` : grille = plan ; raccords nord et ouest
  aller-retour (Lavanville (21..23, 34), Route 11 (74, 14..15)) ; bord sud « à venir » ; poste
  traversé dans les deux sens ; CT39 une fois (`got_tm39`, rechargement) ; Pêcheur 1 inévitable,
  2 à 4 évitables (vraie scène) ; aucune rencontre en 1 000 pas ; Lavanville → Ronflex au croisement ; ≤ 3 000 nœuds.

#### T22 — C : Route 16 est, Ronflex 16, raccord de Céladopole — après T19, T9
- `celadopole.txt` (variante appliquée), `build_celadon_city.gd` (bloc J21),
  `tools/build_route_16.gd`, `route_16.tscn`, `data/npcs/route_16.json`, scène
  `snorlax_route_16_wake` ; départ `snorlax_16_qa`.
- **Tests** `tests/integration/test_route_16.gd` : grille = plan ; raccord Céladopole aller-retour ;
  `obstacle_ouest` absent ; Ronflex sans contournement ; porte du poste « à venir » ; aucune
  rencontre ; mêmes issues que T20 ; **indépendance** : capturer / battre l'un ne change pas
  l'autre (§16 n° 12) ; aucun texte ne contient « Vélo ».

#### T23 — A : sauvegarde, contrat, simulation légère — après T20 à T22
- `test_save_j21` complet (§2.14, n° 5 à 8, 11) ; `test_j21_flags_contract` (étendu) ;
  vérification d'équilibre légère : un joueur à N28–35 bat Sbires, Pêcheurs, Ossatueur et
  Ronflex sans défaite en simulation (`tools/simulate_mt_moon.gd -- --scenario=j21`, 100 parties)
  [D : aucun réglage attendu, L-7 et L-12].

#### T24 — Q : **session 21B** et QA de bout en bout → K, fusion — après T23

| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `poke_flute_qa` | Sac → Flûte loin de Ronflex | notes, §15.6.6, bulle « ♪ » du compagnon |
| 2 | (suite) | rencontre, Flûte sans dormeur | « Personne ne dort… », aucun tour |
| 3 | (suite) | Paras endort, Flûte | réveil des deux camps, tour pris |
| 4 | (suite) | parler à Ronflex : NON, puis OUI | rien ; puis réveil, combat |
| 5 | (suite) | fuir | « Ronflex bâille… » ; examen : §15.7.5 |
| 6 | (suite) | Sac → Flûte à côté, capturer | Ronflex dans l'équipe ; passage libre |
| 7 | `snorlax_16_qa` | perdre, revenir, gagner | Centre ; il dort ; K.O. → §15.7.3 ; libre |
| 8 | `route_12_qa` | Lavanville → poste (CT39) → Pêcheurs → Ronflex au croisement → Flûte → Route 11 | boucle complète vers Carmin |
| 9 | `j21_full_qa` | Tour → Ossatueur → 7F → Flûte → deux Ronflex | **sans blocage** (critère de clôture) |
| 10 | (suite) | relancer l'appli à chaque étape | état gardé (§2.14) |
| 11 | (fps) | Route 12 (eau), 7F | ≥ 58 fps de moyenne, creux ≥ 50 |
| 12 | **vraie partie de Kevin** (si le J20 y est arrivé) | aller jusqu'à la Flûte | aucune régression |

**Critère de clôture (dossier §17)** : le joueur apaise Ossatueur, sauve M. Fuji, obtient la Poké
Flûte, affronte les deux Ronflex et continue librement, sans blocage.

#### T25 — A : clôture et passation — après T24
- `etat-projet.md`, roadmap (ligne J21 avec l'accord de Kevin), `CLAUDE.md`.
- **Passation au J22** : Route 12 sud (`warp_sud`, `from_route_12_sud`) ; **ce qui ferme la
  Route 12 sud sans Flûte** (dossier §10.3, non tranché) ; Pêcheur n° 11 (Magicarpe ×2) ;
  `magikarp`, `poliwhirl` à créer ; îlot de la CT Jackpot (avec le Surf).
- **Passation au jalon de la Piste Cyclable** : porte du poste de la Route 16, voie haute.
- **Reportés** : cris, mélodie de la Flûte, thème de la Tour qui s'éclaircit (jalon audio).

---

## 4. Critères d'acceptation par sous-jalon

**21.0** : textes validés ; logique pure de la Flûte testée ; données valides (Amnésie, CT39,
Flûte ; Ronflex, Ptitard, Tentacool, 7 Dresseurs, table du 7F, Pokédex après T9) ; planche d'art
et vues validées ; variante de Céladopole conforme ; alignement T9 fait ; tests verts, import
propre.

**21A** : révélation avec le Scope seulement ; Ball refusée et non consommée ; fuite (recul,
réarmé), défaite (Centre, réarmé), victoire (drapeau avant les textes, lumière, brume
légère) ; Ossatueur vu, XP gagnée ; 7F et 3 Sbires inévitables ; Fuji, fondu, maison ; **une
seule Flûte** quel que soit le point d'arrêt ; variantes de Lavanville ; objectifs ; session
validée.

**21B** : Flûte utilisable (Sac en exploration, Sac de combat, choix devant Ronflex) ; effet RB
en combat, sans tour si personne ne dort ; deux Ronflex indépendants (capture et K.O. ouvrent ;
fuite et défaite les rendorment) ; Route 12 nord (poste, CT39, Pêcheurs, raccords) ; Route 16 est
et raccord de Céladopole ; sauvegarde v7 et tests d'interruption ; ≥ 58 fps ; validation de
Kevin, puis fusion.

---

## 5. Cas limites (dossier §16) → tests

| Cas | Test | Attendu |
|---|---|---|
| n° 1 Sans Scope au 6F | `test_tower_6f_marowak`, `test_save_j21` n° 10 | scène du J19 |
| n° 2 Fuite puis retour | `test_tower_6f_marowak` | combat neuf, PV pleins |
| n° 3 Défaite contre un Sbire | `test_pokemon_tower_7f` | Centre ; Sbires battus absents ; Ossatueur apaisé |
| n° 4 Coupure entre `fuji_rescued` et la Flûte | `test_save_j21` n° 3, 3 bis | une Flûte |
| n° 5 Flûte et sauvage endormi par le joueur | `test_battle_flute` | il se réveille |
| n° 6 Flûte en combat SPECTRE | `test_battle_flute` | effet normal |
| n° 7 Repos puis Flûte | `test_battle_flute`, `test_snorlax_route_12` | réveillé |
| n° 8 Équipe pleine à la capture | `test_snorlax_route_12` | Stockage |
| n° 9 Ronflex rendormi | `test_snorlax_route_12` | réveil à volonté |
| n° 10 Compagnon | `test_tower_6f_marowak`, `test_snorlax_route_12` | ni blocage, il passe après |
| n° 11 Corde Sortie au 7F | `test_pokemon_tower_7f` | devant la Tour, Fuji attend |
| n° 12 Deux Ronflex | `test_route_16`, `test_save_j21` n° 7, 8 | indépendants |
| n° 13 Aucun drapeau J21 avant | `test_j21_flags_contract` + tests J19 / J20 gardés | — |

---

## 6. Risques et ordre

| Risque | Effet | Parade |
|---|---|---|
| **Le J19 livre `wild_battle` autrement que son plan** | §2.3 à réécrire | T9 réaligne ; les clés J21 sont des ajouts (`flee`, `catch`, `clear`, `reveal`, `uncatchable`) |
| **L'objet clé touche Sac, menu, combat et Boot** | régressions du Sac | tout est gardé par `has_key_use()` ; les autres objets clés restent sans contexte (test) ; les suites `test_bag*`, `test_battle*` vertes sans changer leurs attentes |
| **Duplication de la Flûte** | deux Flûtes | condition sur la **possession** ; trois chemins, une scène ; tests n° 3 et 3 bis |
| **`*_awake` sauvé à tort** | Ronflex disparu ou bloqué | `clear` avant le réveil ; test sur la sauvegarde « réveil » |
| **Six jalons non fusionnés** (J16–J20) | conflits | C-7 ; 21.0 en fichiers nouveaux ; variante de grille de Céladopole ; blocs « J21 » courts |
| **Route 12 nord grande (39 × 102), surtout de l'eau** | peinture lourde, fps | §19 (question de Kevin) ; mesure fps en T21 et T24 |
| Échec intermittent de `tools/test.sh` sous charge | faux rouge | relancer le fichier seul avant de conclure |

```
Maintenant  : T1 ─→ T3 ∥ T4 ∥ T5 (rédaction) ; T2 (K) ; T6 ─→ T7 ; T8 (K)
[clôture J20] ─→ T9 ─→ T10 ─→ T11 ─→ T12 ∥ T13 ─→ T14 ─→ T15 ─→ T16 (téléphone 21A)
21B          : T17 ─→ T18 ∥ T19 ─→ T20 ─→ T21 ∥ T22 ─→ T23 ─→ T24 (téléphone) ─→ T25
```

**Peut commencer maintenant** : T1, T2, T3, T4, T5 (rédaction), T6, T7, T8.

---

## 7. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Branches | `jalon-21` (copie dédiée) ; tâches `j21-t<n>-*` |
| Table du 7F | poids **RB** 191 / 39 / 26 (dossier : poids du 6F) — §0.4 n° 4 |
| Drapeaux ajoutés | `*_woken`, `*_caught`, `tower_6f_mist_lifted` (§0.4 n° 2) |
| `*_awake` | posé au réveil, effacé en fin de combat (`clear`) |
| Brume apaisée | seconde `MistLayer`, alpha × 0,4, dans une `FlagGate if [tower_6f_mist_lifted]` |
| Lumière qui monte | `animate` sur `SpiritLight` (10, 17), 2 cases vers le haut, 2,0 s, `skip_reduced` |
| Dissolution | fondu croisé 1,0 s ; immédiat en animations réduites |
| Texte d'apparition révélée | « C'est un {pokemon} ! » |
| Réveil de Ronflex | `react` + `emote exclamation` sur un acteur de décor |
| Notes de la Flûte | 3 notes, ≈ 1,5 s, un `Tween` |
| Choix devant Ronflex | OUI / NON |
| Sbires | IA `random`, `random`, `smart` ; sprites m, f, m |
| Fuji | 7F (10, 3) ↑ en prière ; maison près de la fenêtre ; spawn `devant_fuji` ↑ |
| Osselait | sprite de monde, près de la fille |
| Poste de la Route 12 | modèle des postes de la forêt ; 2F = coque de maison |
| Fonds de combat | Route 12 `route_24_pont` ; Route 16 `route_5_6_prairie` ; Route 11 existant |
| Lumière des routes | `golden_hour` ; 7F `tower`, voile 0,86 |
| Pêcheurs | `prize_per_level` 35, `ai: random`, sprite `pecheur` |
| Espèces sans évolution | Ptitard, Tentacool : évolution omise tant que la cible manque |
| Céladopole | spawn `from_route_16` (1, 21..23) → ; variante de grille jusqu'à T9 |
| Toast de la Flûte | casse des objets clés (« POKÉ FLÛTE — ajoutée aux objets clés ») |
| Série d'art | 23 (21 et 22 laissés aux J18 et J20) |
| Sauvegarde | v7 |
| Budgets | ≤ 3 000 nœuds, ≤ 16 halos, aucune `Light2D` ; ≥ 58 fps de moyenne, creux ≥ 50 |

---

## 8. Questions pour Kevin

Vraies décisions de game design seulement ; le reste a une valeur par défaut (§7).

- **Q-1 — Textes.** Le lot §15 du dossier, plus l'annexe A (Pêcheurs, CT39, OUI / NON).
  *Recommandation* : une seule passe. Bloque des données, pas le code.
- **Q-2 — Échelle de la Route 12 nord** (dossier §19) : 39 × 102 à × 1,5, ou réduire à × 1,25 ?
  Défaut : garder × 1,5.
- **Q-3 — Pokédex de Ptitard et Tentacool.** Ces deux espèces arrivent par les Pêcheurs : il
  leur faut taille, poids et description (non couverts par le §15.10). *Recommandation* : textes
  en annexe A, même ton que les entrées existantes.
- **Q-4 — Poids de la table du 7F** : RB (191 / 39 / 26, plus de Spectrum) ou ceux du 6F (le
  [D] du dossier) ? Défaut : RB.
- **Q-5 — Osselait chez Fuji** : le J19 ne l'affiche pas (pas d'art). Le J21 le pose avec un
  sprite de monde (lot 23). D'accord pour ce petit ajout d'art ? Défaut : oui.

---

## Annexe A — Textes complémentaires (brouillons, à valider)

> Rédigés par Claude le 2026-10-15, d'après RB (`text/Route12.asm`), ton des Pêcheurs existants.
> Bulles de 2 lignes ; « / » sépare deux bulles.

**Pêcheurs de la Route 12** (`speaker` « Pêcheur <Prénom> ») :

| Id | Prénom [D] | Avant | Défaite | Après |
|---|---|---|---|---|
| `route_12_fisher_1` | Ned | « Ça mord ! Ça mord ! / Ah non… c'est toi. » | « Bah ! Un petit poisson. » | « Ma ligne s'est encore prise dans les algues. » |
| `route_12_fisher_2` | Elton | « Patience ! / La pêche, c'est l'art d'attendre. » | « Celui-là m'a filé entre les doigts ! » | « Les plus gros dorment au fond. / Un jour, ils mordront. » |
| `route_12_fisher_3` | Bastien | « Le roi du ponton contre le petit dresseur ! » | « Trop fort ! » | « Tu m'as battu au combat. / À la pêche, c'est une autre histoire. » |
| `route_12_fisher_4` | Hervé | « J'aurais mieux fait d'aller travailler… » | « Pas facile, tout ça… » | « Perdre ? Ça ne me dérange plus. / J'ai l'habitude. » |

**Choix devant Ronflex** : cartes « OUI » / « NON ».

**CT39** : description de l'objet « Météores ne rate jamais sa cible. » ; ligne système « {player}
obtient la CT39 — Météores ! » (dossier §15.8 bis).

**Pokédex (Q-3)** :

| Espèce | Taille / poids (officiels) | Description |
|---|---|---|
| Ptitard | 0,6 m · 12,4 kg | « Sa peau est si fine qu'on voit ses entrailles en spirale. Il marche mal sur ses jambes toutes neuves. » |
| Tentacool | 0,9 m · 45,5 kg | « Il dérive près de la surface. Son corps presque transparent le rend difficile à voir dans l'eau. » |
