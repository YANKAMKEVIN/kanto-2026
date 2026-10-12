# Jalon 11 — conception technique du compagnon (T17)

> Écrite le 2026-10-10 pendant l'attente d'OUV.1 (accord de Kevin). **Aucun code.** Source de vérité
> du comportement : `docs/design/dossier-14-systemes-j11.md` §8 (décisions 4–6, A-1, A-10 à A-13).
> Ce document dit **comment** le faire dans le code réel (`main` à `29ed036` + T1) et fixe les valeurs
> par défaut techniques (règle 4). Relevé du code : points d'accroche cités avec leur fichier.
> Relecture par Fable possible sur demande de Kevin (`CLAUDE.md`).

## 1. Ce que le code impose (constats)

| Constat | Fichier | Conséquence pour le compagnon |
|---|---|---|
| Une case = un seul occupant ; le joueur et **tous** les PNJ (Pokémon d'ambiance compris) occupent la grille | `grid_world.gd:30,128` | le compagnon **ne doit pas occuper** la grille : sinon il bloque le joueur, coupe la vue des Dresseurs (`trainer_rules.gd:35-47` s'arrête sur tout occupant) et devient une cible d'interaction |
| `Player.moved` part **à la fin** du pas ; `GridMover.step_started(from, to, running)` existe mais n'est pas relayé | `player.gd:355`, `grid_mover.gd:24-27` | relayer `step_started` sur `Player` : le compagnon part **en même temps** que le joueur |
| Pas : marche 0,27 s, course 0,16 s, saut de rebord 0,40 s (cible à 2 cases, arc de 48 px) | `grid.gd:16-23`, `grid_mover.gd:228-235,288` | mêmes durées et même arc, lus aux mêmes constantes |
| Tout ce qui réagit aux pas (scènes, Dresseurs, Pokémon timides, rencontres, portes) écoute **le joueur seul** et ignore les pas scriptés | `boot.gd:173-246,364` | rien à faire : le compagnon ne déclenche rien |
| Changement de carte : verrou, fondu, la carte est instanciée, le joueur est **re-parenté** sous `Entities`, l'ancienne carte libérée | `scene_router.gd:144-169,253-274`, `map.gd:227-235` | le compagnon suit le même chemin (re-parenté au `map_changed`) |
| `GameMap.interior` existe (titre de zone, préchargement) | `map.gd:45` | règle de visibilité directe |
| Les PNJ à routine **attendent et réessaient** quand la case est prise ; les déplacements de scène réessaient 2 s puis abandonnent | `npc.gd:877-893,920-930`, `cutscene_director.gd:835-854` | « les PNJ attendent » = une occupation **douce**, consultée **seulement** par les routines (jamais par les scènes, qui casseraient au bout de 2 s) |
| Le combat ne cache pas le monde : `BattleStage` garde la carte vivante et recadre la caméra ; les Pokémon du monde sont fondus pendant un combat de Dresseur | `battle_stage.gd:1-30,359-386` | le compagnon doit être **caché pendant le combat** (sinon il apparaît dans la scène de combat) |
| Le joueur a un `GrassFront` (devant de touffe) dans les hautes herbes ; les PNJ non | `player.gd:135-139,293-309` | le compagnon reprend le mécanisme du joueur |
| Interaction : l'occupant de la case regardée qui a `get_interaction()` ; sur mobile, le bouton contextuel presse `interact` ; aucun toucher sur le monde | `interaction_finder.gd`, `interact_button.gd:8` | « parler au compagnon » = être face à lui + bouton contextuel ; le chercheur d'interactions doit le connaître (il n'occupe pas la grille) |
| Bulle d'émote : une seule icône (`emote_exclamation.svg`), `kind` ignoré | `npc.gd:1105-1134` | ajouter deux icônes SVG d'interface (« ♪ », « … ») ; la bulle devient réutilisable hors `Npc` |
| Menu Équipe : boutons codés dans `TeamScreen`, signaux relayés par `TrainerMenu` → `MenuDirector` | `team_screen.gd:326-351`, `trainer_menu.gd:265-282`, `menu_director.gd:362-388` | un bouton de plus, même chemin que FAVORI |
| Forêt de Jade : 2 983 nœuds pour un budget de 3 000 (test `test_viridian_forest`, `NODE_BUDGET`) | `jalon-09.md:1158` | le compagnon vit sous `Entities` mais **hors de la scène de carte** (créé par Boot) : il ne compte pas dans le budget de la carte ; ≤ 6 nœuds |
| Planches peintes de marche (idle + walk × 4) : bulbasaur, charmander, squirtle, pidgey, rattata, spearow, mankey, nidoran_f, nidoran_m ; geodude, kakuna, metapod, weedle n'ont que « react » | `assets/sprites/pokemon/painted/*_frames.tres` | **9 espèces éligibles** aujourd'hui (+ 5 avec la série 13) |

## 2. Architecture

```
game/world/companion/
  companion_rules.gd     # pur : éligibilité, visibilité, phrase de curiosité, réactions
  companion_trail.gd     # pur : où va le compagnon après un pas du joueur
  companion.gd / .tscn   # nœud : look peint, pas, saut, devant de touffe, éclat de Ball, bulle
  companion_controller.gd# Boot : écoute joueur / routeur / scènes / combats / menu, pilote le nœud
data/pokemon/companions.json   # espèces éligibles et leur look (aucune espèce sans planche)
data/dialogues/companion.json  # les 10 phrases (dossier 14 §13.12), clés par contexte
```

Logique pure (`CompanionRules`, `CompanionTrail`) testable sans scène (règle 8) ; le nœud ne prend
aucune décision ; le contrôleur est le seul à connaître Boot.

### 2.1 Données

```json
// data/pokemon/companions.json
{
  "species": {
    "charmander": { "sprite": "pokemon/charmander" },
    "bulbasaur":  { "sprite": "pokemon/bulbasaur" },
    "squirtle":   { "sprite": "pokemon/squirtle" },
    "pidgey":     { "sprite": "pokemon/pidgey" },
    "rattata":    { "sprite": "pokemon/rattata" },
    "spearow":    { "sprite": "pokemon/spearow" },
    "mankey":     { "sprite": "pokemon/mankey" },
    "nidoran_f":  { "sprite": "pokemon/nidoran_f" },
    "nidoran_m":  { "sprite": "pokemon/nidoran_m" }
  },
  "contexts": { "viridian_forest": "forest", "viridian_city": "city", "pewter_city": "city" }
}
```

- Une entrée = une planche **validée** ; un test vérifie que chaque `sprite` résout vers des frames
  peintes ayant `idle_*` et `walk_*` dans les 4 directions (jamais le repli `placeholder`).
- `flying: true` (Papilusion, série 13) : ombre au sol dessinée par le moteur, pas de devant de
  touffe. Ajouté avec la planche.
- `contexts` : carte → contexte de la phrase de curiosité (§2.6) ; absent = générique.

### 2.2 `CompanionRules` (pur)

```gdscript
static func is_eligible(pokemon: Pokemon, catalog: CompanionCatalog) -> bool
static func is_visible(state: VisibilityInput) -> bool
# VisibilityInput : chosen (Pokemon ou null), map_interior, in_cutscene, in_battle,
#                   in_transition, placed (une case est attribuée)
```

`is_visible` = choisi **et** éligible **et** pas K.O. **et** carte d'extérieur **et** hors scène
**et** hors combat **et** hors transition **et** placé. Le choix (`GameState.companion_uid`) ne
change **jamais** pour une raison de visibilité (dossier 14 §8.3, A-1, T1).

Le choix est effacé dans trois cas seulement : RAPPELER ; le Pokémon quitte l'équipe (dépôt au
Stockage, libération) ; il **évolue** en espèce non éligible (A-11, en silence).

### 2.3 `CompanionTrail` (pur)

État : la case du compagnon (ou aucune) et la file des pas du joueur.

- **Au départ d'un pas du joueur** `(from, to, kind)` avec `kind ∈ {walk, run, jump}` :
  - compagnon placé → il part vers `from`, avec le genre du pas **précédent** du joueur qui a
    amené le joueur en `from` (si ce pas était un saut de rebord, le compagnon saute à son tour :
    il suit exactement le chemin du joueur, jamais en travers d'un obstacle) ; la vitesse est celle
    du pas courant (le compagnon ne prend jamais de retard) ;
  - compagnon non placé (arrivée sans case libre) → il **apparaît en `from`** à la fin du pas
    (éclat de Ball) ;
  - le joueur marche **sur** la case du compagnon : même règle (il part vers `from`) = **échange
    de places**, ils se croisent (comme dans les jeux récents).
- Un pivot sur place, une poussée contre un mur (`bumped`) : rien.
- **Placement après une arrivée** (porte, reprise de partie, réveil au Centre, départ de débogage,
  fin de scène) : la case **derrière** le joueur (`cell - facing`) si elle est praticable (ni
  solide, ni eau, ni rebord, ni occupée) ; sinon aucune (§A-1 « masqué sans case libre »).
- Garantie testée : le compagnon n'est **jamais** à plus d'un pas (ou d'un saut) du joueur et
  n'entre jamais dans une case où le joueur n'est pas passé.

### 2.4 Nœud `Companion`

- `Node2D` sous `Entities` (tri en profondeur avec le joueur et les PNJ, origine aux pieds) ;
  enfants : `AnimatedSprite2D` (frames de `CharacterLook.resolve`), `GrassFront` (comme le joueur,
  texture `GameMap.grass_front`), ombre (pour `flying`), bulle d'émote ; ≤ 6 nœuds.
- Pas : interpolation de position sur la durée du pas, demi-cycle de `walk_<dir>` comme
  `Npc._play_move` ; à la course, `speed_scale` = 0,27 / 0,16 ; saut : arc de 48 px sur 0,40 s,
  devant de touffe caché pendant le saut ; arrêt → `idle_<dir>`.
- Éclat de Ball (sortie / rappel) : ≈ 0,4 s, sprite qui grandit / rétrécit depuis la Ball avec un
  éclat blanc (shader d'additif, aucun asset neuf) ; « Réduire les animations » : fondu de 0,15 s.
- Bulle : la logique de `Npc.show_emote` est extraite dans un petit composant `EmoteBubble`
  (utilisé par `Npc` et `Companion`, mêmes jetons `UiTokens.EMOTE_*`, même `EmotePlacement`) avec
  trois icônes SVG d'interface : `!` (existante), `♪`, `…` (nouvelles, ui-mobile, skill
  `ui-theme-2026`, pas de pixel art).

### 2.5 `CompanionController` (Boot)

Branché comme les autres contrôleurs (`boot.gd:173-246`, `_on_map_changed:835-848`) :

| Signal | Effet |
|---|---|
| `Player.step_started(from, to, running)` (**nouveau relais**, `player.gd`) | `CompanionTrail` → pas du nœud ; si une scène est en cours : rien (compagnon déjà rentré) |
| `SceneRouter.transition_started` | rappel pendant le fondu (sans éclat : le fondu le couvre) |
| `SceneRouter.map_changed` | re-parenté sous la nouvelle `Entities` ; placement (§2.3) ; visible si la règle le dit |
| `CutsceneDirector.cutscene_started` / `cutscene_finished` | rentre / ressort derrière le joueur (§3, D-2) |
| `BattleDirector.battle_started` / `battle_finished` | caché / montré (D-1) ; puis réaction « enthousiasme » si §2.6 |
| `DefeatRecovery.woke_up` | rien de spécial : réveil dans un intérieur (Centre, maison) → caché |
| `MenuDirector` : FAIRE SORTIR / RAPPELER, dépôt, ordre, objet utilisé | réévalue (choix, K.O. guéri par une Potion, etc.) |
| `ServiceDirector.center_healed` | note un « enthousiasme » en attente (montré à la sortie du Centre) |
| `EvolutionDirector` (fin) | si l'espèce n'est plus éligible : efface le choix |
| minuterie d'immobilité du joueur | réaction « repos » (§2.6) |

**Occupation douce** : `GridWorld` gagne `soft_hold(cell, entity)` / `soft_release` /
`is_soft_held(cell)` ; **seules** les routines de PNJ (`Npc._advance_route`, sortie de maison) la
consultent et attendent comme pour une case occupée. `can_enter`, `get_step_target`, les scènes,
les Dresseurs, le chercheur d'interactions **l'ignorent**. Le compagnon tient doucement sa case
d'arrivée au départ de chaque pas.

**Interaction** : `InteractionFinder` reçoit un fournisseur optionnel « compagnon » : si le
compagnon est **visible** sur la case regardée, l'interaction est la sienne (curiosité) ; sinon le
chemin actuel. Le bouton contextuel s'allume donc face à lui, comme pour un PNJ.

### 2.6 Réactions (dossier 14 §8.5)

- **Curiosité** : interaction → le compagnon se tourne vers le joueur, bulle `♪` (ou `…` si PV bas
  ou statut), une phrase de `data/dialogues/companion.json` choisie ainsi : PV ≤ 1/3 → n° 55 ;
  statut → n° 56 ; eau à ≤ 2 cases → n° 59 ; contexte de la carte (`forest` → 57, `city` → 58) ;
  sinon une générique (50–54) tirée sans répéter la dernière (aléatoire **hors** `GameRng`, comme
  les identifiants). Le joueur est déjà verrouillé par la boîte de dialogue existante.
- **Repos** : joueur immobile et sans verrou pendant 8 s → le compagnon regarde à gauche, à droite,
  puis le joueur (0,6 s par regard), recommence toutes les 6 s ; s'arrête au premier pas.
- **Enthousiasme** : en attente après une victoire contre un Dresseur, une capture, une montée de
  niveau du compagnon, un soin au Centre ; joué **une fois** quand le compagnon redevient visible
  sur une carte d'extérieur : petit saut (12 px, 0,25 s) + bulle `♪`. Plusieurs en attente → un seul.

## 3. Valeurs par défaut techniques (règle 4)

| N° | Sujet | Défaut | Pourquoi |
|---|---|---|---|
| D-1 | Combat | compagnon **caché** du `battle_started` au `battle_finished` | la scène de combat montre le monde (`BattleStage`) ; le dossier disait « rien ne change sur la carte » : sans ce cache, il apparaîtrait dans le combat |
| D-2 | Scènes | rentre à **toute** scène (`cutscene_started`), y compris l'approche d'un Dresseur, ressort à la fin | les déplacements de scène abandonnent au bout de 2 s si une case est tenue ; une règle « seulement si le joueur bouge » demanderait de prévoir chaque scène |
| D-3 | Course | même vitesse que le joueur, animation accélérée | pas de planche de course |
| D-4 | Échange de places | les deux se croisent sur un pas | pas d'occupation, pas de blocage |
| D-5 | Repos | 8 s puis toutes les 6 s | dossier 14 §8.5 |
| D-6 | Éclat de Ball | 0,4 s ; 0,15 s en animations réduites | dossier 14 §8.3 |
| D-7 | Contextes | forêt de Jade = forêt ; Jadielle, Argenta = ville ; le reste générique | Bourg Palette est un village (« les passants » n'y sonne pas juste) |
| D-8 | Phrase | pas deux fois de suite la même | variété sans système d'humeur |

Aucune décision de game design nouvelle : D-1 et D-2 précisent la règle « rentre quand une
cinématique l'exige » du dossier 14 §8.3 ; ils seront signalés à Kevin à la QA 11D.

## 4. Découpage en tâches (remplace T19–T20 du plan)

| T | Contenu | Agent |
|---|---|---|
| T19a | `CompanionCatalog` + `companions.json` + test des planches | architecte-godot |
| T19b | `CompanionRules`, `CompanionTrail` + tests purs (§5) | architecte-godot |
| T20a | relais `Player.step_started`, occupation douce dans `GridWorld` + routines de PNJ, fournisseur « compagnon » de `InteractionFinder` | architecte-godot |
| T20b | nœud `Companion`, `EmoteBubble` extrait, icônes `♪` / `…`, éclat de Ball | ui-mobile |
| T20c | `CompanionController` dans Boot, bouton FAIRE SORTIR / RAPPELER (`TeamScreen` → `MenuDirector`), réactions, phrases | constructeur-monde + ui-mobile |
| T20d | intégration sur les vraies cartes + captures relues | constructeur-monde |

## 5. Tests

- **Purs** : éligibilité (9 espèces, aucune sans planche, K.O. = invisible mais choisi) ; table
  complète de visibilité ; `CompanionTrail` : couloir droit, virage, demi-tour (échange), rebord
  puis pas suivant (le compagnon saute), deux rebords de suite, course, poussée contre un mur, pivot,
  arrivée avec case libre / sans case libre puis premier pas ; « jamais à plus d'un pas ».
- **Grille** : un PNJ à routine attend la case du compagnon puis repart ; une scène fait passer un
  PNJ sans attendre (compagnon rentré) ; un Dresseur voit le joueur « à travers » le compagnon.
- **Intégration** (vraies cartes, Boot) : Bourg Palette → Route 1 (rebords, herbes : aucune
  rencontre déclenchée par le compagnon, devant de touffe) ; Jadielle (Centre : rentre, ressort,
  enthousiasme) ; Forêt de Jade (Dresseur, combat : caché puis montré ; fps) ; Argenta ; reprise
  de partie avec compagnon ; évolution en espèce non éligible (choix effacé) ; dépôt au Stockage.
- **Captures relues** : compagnon derrière le joueur dans les 4 directions, dans les herbes, au
  saut de rebord, bulle de curiosité.

## 6. Risques

| Risque | Parade |
|---|---|
| Re-parentage pendant le fondu (nœud libéré avec l'ancienne carte) | le contrôleur re-parente dans `map_changed`, avant le `queue_free` de l'ancienne carte (`scene_router.gd:253-274`) ; test dédié |
| Une scène longue sans compagnon paraît étrange | D-2 noté pour la QA ; affinable plus tard par une option de scène (`companion: "keep"`) sans changer le reste |
| Ordre des signaux au pas (le joueur réserve sa case au départ) | le compagnon n'occupe rien : aucun conflit possible avec `move_occupant` |
| Fps dans la forêt | ≤ 6 nœuds hors budget de carte ; mesure au T21 (≥ 58 fps) |
