# Jalon 5 — La Route 1 et les premières rencontres sauvages

> Objectif jouable sur le S24, en quatre temps.
>
> **5A — La Route 1.** Après le premier combat (4B), le joueur remonte le chemin nord de Bourg Palette, traverse les hautes herbes (23..24, 1..2) **sans rencontre** et arrive sur la **Route 1** : « **ROUTE 1** / Bourg Palette — Jadielle » s'affiche sur le monde, puis s'efface. Hautes herbes où **les jambes du personnage disparaissent** et où les brins s'écartent à chaque pas ; Pokémon d'ambiance qui réagissent (par défaut : un **Roucool** posé sur une clôture qui **s'envole** quand on approche, un **Rattata** qui **détale**). Le tracé, les zones d'herbe et le contenu de la route sont **à concevoir par Kevin** (§3.4, Q1 à Q5 : ce plan ne fait que proposer). On peut marcher jusqu'au bout de la carte côté Jadielle, et redescendre vers Bourg Palette, dont le titre revient.
>
> **5B — La rencontre.** Dans les hautes herbes, au hasard d'un pas : **l'herbe devant le joueur s'agite**, il **s'arrête**, la **caméra se rapproche** à peine, un **Rattata sauvage** jaillit à sa place de combat, **le starter entre dans le cadre** : tout cela en **~1 s**, sans spirale, sans flash, sans écran noir, **dans le décor même** de la Route 1. « Un Rattata sauvage apparaît ! ». Combat au tour par tour avec l'interface du 4B ; **FUITE** fonctionne ; le sauvage tombe K.O. et disparaît ; le décor revient, le joueur reprend la marche. Si son équipe tombe, écran très bref, retour à la maison, Pokémon soignés.
>
> **5C — L'XP.** À la fin d'un combat gagné : « **+21 XP** » sur la carte du joueur, la barre d'XP se remplit, « **Nv. 6** » s'illumine, sans fenêtre de statistiques. Une nouvelle capacité s'apprend (« Salamèche apprend Flammèche ! ») ; si les quatre emplacements sont pris, le joueur **choisit laquelle oublier** (ou renonce).
>
> **5D — La capture.** SAC → Poké Ball ; le dresseur entre dans le cadrage, lance, le Pokémon est absorbé, la Ball tombe **dans l'herbe de la Route 1**, **toc… toc… toc…** avec vibration, **✨ clic** : « **ROUCOOL CAPTURÉ !** » / « Nouvelle entrée Pokédex » / « Roucool rejoint ton équipe. ». Et on continue.
>
> Pas de marqueur, pas de mini-carte, pas d'« OBJECTIF MIS À JOUR », pas de fenêtre en cascade. Un combat contre un sauvage faible dure **20 à 40 s** (dossier 05 §21).

**Pré-requis** : le **jalon 4B** (premier combat) est codé, validé sur le S24 et fusionné. **Au moment de ce plan, il ne l'est pas** : le 4A est codé sur `jalon-04a` (949 tests verts, QA S24 à faire) et le 4B n'existe qu'en plan (`jalon-04.md` §2.2, §3.7, §3.8, T5 à T9). Le moteur de combat pur (`Battle`, `BattleText`, `TrainerLibrary`…) est déjà là ; la **présentation** du combat (`BattleDirector`, `BattleStage`, `BattleHud`, `BattleLayout`) ne l'est pas. Ce plan s'appuie donc sur le **code réel** pour tout ce qui existe et sur les **promesses du plan 4B** pour le reste ; le §9 dit quoi faire si le 4B livre autrement. **L'étape d'architecture de chaque sous-jalon (T0, T4, T9, T13) commence par aligner ce plan sur le code réel**, comme le §13 du jalon 4.

**Hors périmètre** (d'après les dossiers et la règle « une couche à la fois ») :
- **Jadielle** (première vraie ville, Centre Pokémon, boutique, colis de Chen) : jalon suivant. La Route 1 s'arrête à son bord nord (Q5).
- **Dresseurs sur les routes** (dossier 05 §3 « Dresseur ») : la Route 1 de Rouge/Bleu n'en a pas.
- **Changement de Pokémon** en combat (ÉQUIPE, dossier 05 §14) : reste inactif (Q20). Un Pokémon K.O. est remplacé automatiquement par le suivant (décision n° 15 du jalon 4).
- **Objets de soin** et Potions (en combat et hors combat) ; seul l'objet « Poké Ball » existe en 5D.
- **Statuts majeurs** (poison, paralysie, sommeil, brûlure, gel) et leurs effets visuels ; **exception possible** : Vampigraine (Q28).
- **Évolution** (scène de 8 à 12 s, dossier 04 §7) : différée (Q27).
- **Menus** (Équipe, Pokédex, Sac, Carte, Profil : phase 7), **sauvegarde** (phase 11), **jour/nuit et météo** (phase 10), **compagnon qui suit** (jalon dédié, décision Q-D du 4A), **sons et cris** (Q14), **indices dans l'herbe** (dossier 04 §3, Q12), **option Animations Complètes / Rapides** (dossier 05 §21 : `BattleDirector.speed_scale` la prépare). Le §10 dit ce que le jalon 5 fait au minimum pour chacun.
- Rendu « vraie DA » de la Route 1 et des Pokémon : tuiles et sprites **provisoires** aux dimensions finales.

Références : `CLAUDE.md`, `docs/design/vision.md` (échelle A+, « routes = lieux, pas des couloirs », vertical slice), `dossier-01-bourg-palette.md` (Route 1 sur le concept golden hour, §6 Prairie du Nord), `dossier-02-prologue.md` §5, `dossier-04-systeme-pokemon.md` §1 à §3, §6, §11 à §13, `dossier-05-combat.md` §2, §3, §6, §12, §15 à §17, §21, §23, `dossier-06-progression.md` §2 et §10, `ui-ux-bible-v0.1.md` (§5 titre « ROUTE 1 / Bourg Palette — Jadielle », §6 toasts, §11 interdits, §12 haptique), `ui-reference.md` (Combat, capture), références `combat-v1.webp`, `combat-capacites-v1.png.png`, `combat-capture-v1.webp`, `bourg-palette-aplus-v1.png`, [`jalon-03b.md`](jalon-03b.md) (hautes herbes, déclencheurs), [`jalon-04.md`](jalon-04.md) (moteur, 4B), skills `godot-conventions`, `world-tiles`, `ui-theme-2026`.

---

## 1. Découpage en 5A / 5B / 5C / 5D

| | 5A — La Route 1 | 5B — La rencontre | 5C — L'XP | 5D — La capture |
|---|---|---|---|---|
| Couche nouvelle | **Carte** + raccord, herbes lues par la grille, Pokémon d'ambiance qui réagissent | **Rencontres** (tables, tirage), **transition**, **combat sauvage**, **fuite**, défaite et soin | **XP**, niveaux, apprentissage, **oubli** | **Objets** (Poké Ball, Sac), **capture**, Pokédex et stockage minimaux |
| Visible sur le S24 | marcher de Bourg Palette au bout de la Route 1 et revenir | des combats sauvages complets | « +XP », barre, « Nv. », capacité apprise | la capture complète, en 3 s « sacrées » |
| Fin | exploration libre, aucune rencontre | on gagne, on fuit, on perd | le starter progresse | le Pokémon capturé rejoint l'équipe |

Pourquoi quatre sous-jalons plutôt que deux :
- **Une fonctionnalité → testée sur S24 → validée → suivante.** La carte se juge en marchant, sans combat ; la rencontre et le combat sauvage forment une seule boucle qu'on ne peut pas juger à moitié (déclencher une rencontre sans pouvoir en sortir n'est pas jouable) ; l'XP se juge sur des combats **déjà validés** ; la capture ajoute des objets, un sac, une mise en scène propre et trois états de partie (Pokédex, stockage, Balls) : c'est le plus gros morceau, et le plus « sacré » (dossier 05 §16).
- **La fuite reste en 5B** : sans elle, le premier combat sauvage n'a pas d'issue autre que le K.O. ; elle tient en une action et un calcul.
- **L'oubli reste en 5C, mais il est inatteignable en jeu** sur la Route 1 : le cinquième apprentissage arrive au niveau 20 (Bulbizarre, Poudre Toxik), 22 (Salamèche Frénésie, Carapuce Morsure), soit plus de 5 000 XP contre ~20 par sauvage. Il est construit et validé avec un **départ de débogage** (T11) ; ou reporté (Q29).
- **La capture pourrait devenir le jalon 6** (phase 6 du plan de `vision.md`). Elle est ici en 5D parce que la vertical slice de `vision.md` enchaîne « rencontre → combat → capture » sur la Route 1, et parce qu'elle dépend d'une décision de Kevin (d'où viennent les premières Poké Balls, Q32) : 5A à 5C n'en dépendent pas.

Chaque sous-jalon ne commence qu'une fois le précédent **validé par Kevin**. L'étape d'architecture du suivant peut être préparée sur sa branche pendant la QA du précédent (classes pures et tests seulement).

---

## 2. Fondations logiques à poser (architecte)

Classes pures (`RefCounted`) et leurs tests, sans scène, sans autoload. Même règles que le jalon 4 : données JSON validées strictement (clé inconnue, type, bornes, doublon entre fichiers, ligne du JSON illisible, références croisées vérifiées contre `PokemonData`), aléatoire uniquement par la `GameRng` reçue, ordre des tirages documenté en tête de fichier.

### 2.1 Avant le 5A (T0)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/world/grid_world.gd` (ajout) | `GridWorld` | Drapeau de case **hautes herbes** : `set_tall_grass(cell, tall := true) -> bool`, `is_tall_grass(cell) -> bool`. Nouveau bit `_FLAG_TALL_GRASS = 16` (les bits 2–3 portent le rebord). N'influe sur aucune règle de déplacement. |
| `game/world/map.gd` (ajout) | `GameMap` | `_read_layer` lit enfin `OverworldTiles.DATA_TALL_GRASS` (posée depuis le 3B, jamais lue) → `_grid.set_tall_grass`. |
| `game/world/npc/npc_spec.gd` + `npc_roster.gd` (ajout) | `NpcSpec`, `NpcRoster` | Clé facultative **`"shy"`** d'un Pokémon d'ambiance : `{ "action": "fly" \| "flee", "radius": 1..4 }` → `NpcSpec.shy_action: StringName` (`&""` = aucune), `shy_radius: int`, `const SHY_ACTIONS: Array[StringName] = [&"fly", &"flee"]`. Refusée sur un PNJ interactif (un Pokémon qui fuit ne se parle pas). |
| `game/world/npc/ambient_rules.gd` | `AmbientRules` | Règles du dossier 04 §1 (« Roucool se pose sur les clôtures et s'envole », « Rattata fuit facilement »), statiques : `is_within(npc_cell, player_cell, radius) -> bool` (distance de Manhattan) ; `flee_path(grid, from, away_from, max_steps, mover) -> Array[Vector2i]` (directions qui **augmentent** la distance au joueur, cases `is_free`, ordre haut-bas-gauche-droite reproductible ; vide si acculé). |

```gdscript
class_name AmbientRules
extends RefCounted
## Réactions des Pokémon d'ambiance à l'approche du joueur (dossier 04 §1). Pur, sans nœud.

## Vrai si le joueur est à [param radius] cases ou moins (distance de Manhattan).
static func is_within(npc_cell: Vector2i, player_cell: Vector2i, radius: int) -> bool
## Jusqu'à [param max_steps] pas qui éloignent de [param away_from], sur des cases libres
## (GridWorld.is_free). Vide si aucun pas n'éloigne : le Pokémon reste (il ne traverse
## jamais le joueur).
static func flee_path(grid: GridWorld, from: Vector2i, away_from: Vector2i, max_steps: int,
		mover: Object = null) -> Array[Vector2i]
```

Tests : `test_grid_world.gd` (herbes : indépendant du solide, de l'eau et du rebord ; hors carte → faux), `test_game_map.gd` (Bourg Palette réel : `is_tall_grass` vrai exactement sur (23..24, 0..2)), `test_npc_roster.gd` (`shy` : valeurs, bornes, refus sur PNJ interactif), `tests/unit/test_ambient_rules.gd` (distance, fuite en coin, fuite bloquée, reproductibilité).

### 2.2 Avant le 5B (T4)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/pokemon/encounters/encounter_slot.gd` | `EncounterSlot` | `species`, `min_level`, `max_level`, `weight`. |
| `game/pokemon/encounters/wild_encounter.gd` | `WildEncounter` | Résultat d'un tirage : `species`, `level`, `table_id`. |
| `game/pokemon/encounters/encounter_table.gd` | `EncounterTable` | `id`, `terrain` (`TERRAINS = [&"grass"]` ; eau, grotte plus tard), `maps: Array[StringName]`, `rate` (sur `RATE_DEN = 256`, **par pas terminé** sur une case du terrain), `slots`. `roll(rng) -> WildEncounter` (null = pas de rencontre), `pick(rng)` (sans le test de taux : tests, départ de débogage), `total_weight()`, `chance_of(species) -> float` (information pour Kevin). Tirages dans l'ordre : `roll(256) <= rate`, `roll(total_weight)`, `range_int(min, max)`. |
| `game/pokemon/encounters/encounter_library.gd` | `EncounterLibrary` | `EncounterLibrary.new(pokemon_data)`, `load_dir(DATA_DIR = "res://data/encounters/")`, `add_from_dict`, `get_table(map_id, terrain) -> EncounterTable`, `get_ids()`, `get_errors()`. Validation : espèces connues, niveaux 1..100 et `min ≤ max`, poids > 0, `rate` 1..255, **au plus une table par couple (carte, terrain)**. Les cartes ne sont pas vérifiées ici (tests de données, §4). |
| `game/battle/battle_rules.gd` | `BattleRules` | Règles d'un combat : `wild`, `can_flee`, `gives_exp`, `exp_multiplier` (1,0 ; 1,5 contre un dresseur, Q23), `allow_balls` (5D). `static for_wild() -> BattleRules`, `static for_trainer(trainer: TrainerData) -> BattleRules`. |
| `game/battle/battle_request.gd` | `BattleRequest` | **Ce que le directeur doit jouer** (§3.8) : `intro` (enum `Intro { TRAINER, WILD }`), `trainer: TrainerData` (null = sauvage), `foe_party: Party`, `rules: BattleRules`, `world_actors: Dictionary[StringName, StringName]` (4B), `origin_cell: Vector2i` (case de l'herbe qui bouge). `static wild(encounter, data, rng, cell) -> BattleRequest` (le sauvage est créé par `PokemonFactory.create`). |
| `game/battle/flee_calc.gd` | `FleeCalc` | Fuite (Q18, formule des 3e et 4e générations) : réussite assurée si la Vitesse du joueur ≥ celle du sauvage ; sinon F = ⌊A·128/B⌋ + 30·C (C = tentatives ratées de ce combat), réussite si F > 255 ou `roll(256) − 1 < F`. Vitesses **sans** niveaux de stats. |
| `game/battle/battle.gd` (ajouts) | `Battle` | `_init(player, foe, data, rng, rules: BattleRules = null)` (null = règles actuelles : le combat du rival ne change pas). `BattleAction.Kind.RUN` (**fin d'enum**), `BattleAction.run()` ; légal seulement si `rules.can_flee` ; joué **avant** les capacités. Événements `FLED`, `FLEE_FAILED` (fin de l'enum `BattleEvent.Kind`) ; `Battle.Outcome.FLED` (fin d'enum). Échec : l'adversaire joue son tour. `get_rules()`. |
| `game/battle/battle_text.gd` + `data/battle/messages.json` (ajouts) | `BattleText` | Modèles **`wild_appeared`**, **`fled`**, **`flee_failed`** (textes proposés, `draft`, §3.12). `SENT_OUT` adverse **sans dresseur** → `wild_appeared` (aujourd'hui : aucune phrase). `BATTLE_ENDED` avec `FLED` → rien (le message est porté par `FLED`). Les trois identifiants s'ajoutent à `TEMPLATE_IDS` **dans le même commit** que le fichier de données (tous les modèles sont obligatoires). |
| `game/systems/dialogue/*` (ajout) | `Dialogue`, `DialogueLibrary` | Clé de dialogue facultative **`"heal": true`** (soin de l'équipe à la fin du dialogue, §3.11). Validée comme `set`. |
| `data/pokemon/species/kanto.json`, `moves/moves.json` (ajouts) | — | Espèces et capacités des rencontres (§3.2), valeurs officielles modernes, learnsets de Rouge/Bleu. |

Tests : `tests/unit/test_encounter_table.gd` (taux sur 10 000 tirages avec une graine : ±2 points ; poids ; niveaux dans les bornes ; `ScriptedRng` : ordre des tirages), `test_encounter_library.gd` (fixtures `tests/fixtures/encounters/` : valide, clé inconnue, espèce inconnue, niveaux inversés, deux tables pour la même carte, JSON cassé avec la ligne), `test_flee_calc.gd` (valeurs à la main, C qui croît, Vitesse égale), `test_battle.gd` (étendu : RUN illégal contre un dresseur ; RUN joué avant une capacité prioritaire ; `FLED` puis `BATTLE_ENDED(FLED)` ; `FLEE_FAILED` puis action adverse ; règles nulles = comportement du 4), `test_battle_text.gd` (modèles sauvages ; `SENT_OUT` adverse sans dresseur), `test_dialogue_library.gd` (`heal`), `test_pokemon_data.gd` (nouvelles espèces, capacités, lignées complètes), `test_battle_simulation.gd` (étendu : §5 T4).

### 2.3 Avant le 5C (T9)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/pokemon/exp_calc.gd` | `ExpCalc` | Statique. `amount(foe: Pokemon, data, multiplier) -> int` = max(1, ⌊b · L · m / 7⌋) (`b` = `base_exp` moderne déjà en données, Q23) ; `split(total, count) -> Array[int]` (parts égales, reste au premier, Q24) ; `progress(pokemon, data) -> float` (0..1 de la barre, 1 au niveau 100). |
| `game/battle/battle.gd` (ajouts) | `Battle` | **Participants** : Pokémon du joueur envoyés contre l'adversaire en jeu (remis à zéro quand l'adversaire change). Au K.O. adverse, si `rules.gives_exp` : pour chaque participant debout, `gain_exp` puis, **entre `FAINTED` et `BATTLE_ENDED`** (aujourd'hui `_check_end` ajoute `BATTLE_ENDED` juste après `FAINTED` : l'ordre change), les événements `EXP_GAINED` (un par tranche de niveau : `amount` total sur le premier, `exp_from`, `exp_to` en fraction de barre), `LEVEL_UP` (`level`, `hp`, `max_hp`), `MOVE_LEARNED` (emplacement libre : `learn_move` fait **par le moteur**), `MOVE_FORGET_OFFERED` (4 emplacements pris : **rien n'est changé**, la présentation fera choisir). Nouveaux champs de `BattleEvent` : `exp_from`, `exp_to`. |
| `data/battle/messages.json` (ajouts) | — | `level_up`, `move_learned`, `move_forget_prompt`, `move_forgot`, `move_not_learned` (proposés, `draft`) ; marques `{level}`, `{exp}`, `{old_move}`. |
| (si Q28 = oui) `game/battle/battler.gd`, `battle.gd`, `move_effect.gd` | — | **Vampigraine** : effet `seed` (plante une graine, Plante immunisé), drain de ⅛ des PV max en fin de tour au profit du lanceur ; événements `SEEDED`, `DRAINED`. Seul statut volatil du jalon. |

Rien n'est choisi par le moteur : `MOVE_FORGET_OFFERED` laisse la décision à la présentation, qui appelle `Pokemon.replace_move` (existant) ou rien. Le moteur reste synchrone et reproductible.

Tests : `tests/unit/test_exp_calc.gd` (valeurs à la main : Roucool N3 → 21 XP ; plancher 1 ; partage), `test_battle.gd` (étendu : pas d'XP contre le rival, `gives_exp` faux ; un sauvage K.O. → `FAINTED`, `EXP_GAINED`, `LEVEL_UP`, `MOVE_LEARNED`, puis `BATTLE_ENDED` ; deux niveaux d'un coup → deux tranches ; 4 capacités → `MOVE_FORGET_OFFERED` et moves inchangés ; participant K.O. → rien ; XP du Pokémon égale à la somme des événements).

### 2.4 Avant le 5D (T13)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/items/item_data.gd`, `item_library.gd` | `ItemData`, `ItemLibrary` | `data/items/*.json` : `name`, `category` (`ball` au jalon 5 ; `heal`… plus tard), `catch_bonus` (balls), `description` (`draft`). Même validation que les autres bibliothèques. |
| `game/items/bag.gd` | `Bag` | `add(id, count := 1)`, `remove(id, count := 1) -> bool`, `count_of(id)`, `get_ids(category := &"")`, `to_dict()` / `load_dict()`. Aucune limite de quantité au jalon 5. |
| `game/battle/capture_calc.gd`, `capture_result.gd` | `CaptureCalc`, `CaptureResult` | Formule des 3e et 4e générations (Q33) : a = ⌊(3·PVmax − 2·PV) · taux · bonus_ball / (3·PVmax)⌋ × bonus_statut (1 au jalon 5) ; a ≥ 255 → capturé ; sinon b = ⌊1 048 560 / √√(16 711 680 / a)⌋ et 4 tests `roll(65536) − 1 < b`. `CaptureResult { caught, shakes }` (secousses montrées = min(tests réussis, 3)). |
| `game/pokemon/pokedex.gd` | `Pokedex` | Minimal : `mark_seen(species) -> bool` (vrai si nouveau), `mark_caught(species) -> bool`, `is_seen`, `is_caught`, `seen_count`, `caught_count`, `to_dict` / `load_dict`. Aucune interface. |
| `game/pokemon/pokemon_storage.gd` | `PokemonStorage` | « Système de recherche de Chen » (dossier 04 §5, 05 §17) : `add(pokemon)`, `size()`, `get_all()`, `to_array()` / `load_array()`. Aucune interface. |
| `game/battle/battle.gd` (ajouts) | `Battle` | `BattleAction.Kind.ITEM` + `item_id` (`BattleAction.ball(id)`), légal si `rules.allow_balls` (sauvage seulement) ; joué avant les capacités. Événements `BALL_THROWN`, `BALL_SHAKE` (×0 à 3, champ `shake`), `CAUGHT` ou `BROKE_FREE` ; `Battle.Outcome.CAUGHT`. Le moteur lit le bonus de la Ball dans `BattleRules.items: ItemLibrary` (champ ajouté en 5D, null avant) ; il **ne touche pas au Sac** (le directeur retire la Ball). |
| `data/pokemon/species/kanto.json` (ajout) | `SpeciesData` | Clé **`catch_rate`** (obligatoire, ajoutée aux 14 espèces dans le même commit ; valeurs officielles : les 9 des lignées de starters et Roucarnage 45, Roucool et Rattata 255, Roucoups 120, Rattatac 127). |
| `data/battle/messages.json` (ajouts) | — | `ball_thrown`, `broke_free` (proposés, `draft`) ; `caught_title`, `pokedex_new`, `joined_party`, `sent_to_storage` (**textes du dossier 05 §17**, `text_f` pour l'accord, Q36). |

Tests : `test_capture_calc.gd` (a ≥ 255 ; PV à 1 plus facile que PV pleins ; secousses 0..3 ; `ScriptedRng`), `test_bag.gd`, `test_item_library.gd`, `test_pokedex.gd`, `test_pokemon_storage.gd`, `test_battle.gd` (étendu : ITEM illégal contre un dresseur ; capture → `CAUGHT`, `BATTLE_ENDED(CAUGHT)` sans action adverse ; échec → `BROKE_FREE` puis action adverse), `test_pokemon_data.gd` (`catch_rate`).

---

## 3. Architecture

### 3.1 Arbre des scènes

```
game/boot.tscn
Boot (Node)  game/boot.gd                        racine de composition (câblage seulement)
├─ World (Node2D)                 %World
├─ BattleStage (instance)         %BattleStage          (4B) + intro sauvage (5B), lancer (5D)
├─ ExplorationHud (instance)      %ExplorationHud       + toast (5D)
├─ BattleHud (instance)           %BattleHud            (4B) + FUITE (5B), XP (5C), SAC (5D)
├─ StarterSheet (instance)        %StarterSheet         inchangé
├─ DialogueBox (instance)         %DialogueBox          inchangé
├─ DialogueRunner (Node)          %DialogueRunner       + clé « heal » (5B)
├─ InteractionController (Node)   %InteractionController  inchangé
├─ CutsceneDirector (Node)        %CutsceneDirector     inchangé (+ étape « give » si Q32 = Chen, 5D)
├─ StarterChoice (Node)           %StarterChoice        inchangé
├─ BattleDirector (Node)          %BattleDirector       (4B) + run_request (5B), XP/oubli (5C), capture (5D)
├─ EncounterDirector (Node)       %EncounterDirector    game/pokemon/encounters/encounter_director.gd (5B)
├─ AmbientWatcher (Node)          %AmbientWatcher       game/world/npc/ambient_watcher.gd (5A)
└─ ScreenFade (instance)          %ScreenFade

Autoloads : SceneRouter (inchangé) · GameState (+ point de soin 5B ; Sac, Pokédex, stockage 5D)
```

`Boot._ready` (ajouts ; toujours **tout brancher avant** `SceneRouter.start`) :
```gdscript
%AmbientWatcher.setup(_player)                                          # 5A
_encounters.load_dir()                                                  # 5B : EncounterLibrary
%EncounterDirector.setup(_encounters, _pokemon, GameState, _player, %BattleDirector,
		SceneRouter, %CutsceneDirector)
%EncounterDirector.encounter_started / encounter_finished → _refresh_controls()
_runner.heal_requested.connect(_on_heal_requested)                      # 5B, §3.11
_items.load_dir()                                                       # 5D : ItemLibrary
```
`Boot._on_map_changed` appelle aussi `%AmbientWatcher.set_map(map)` et `%EncounterDirector.set_map(map)`. `_refresh_controls()` : contrôles visibles seulement si **aucun** dialogue, scène, fiche, combat **ni rencontre** n'est en cours.

### 3.2 Données en fichiers (`data/`)

```
data/encounters/route_1.json          tables de rencontre (5B)
data/npcs/route_1.json                Pokémon d'ambiance, PNJ éventuels (5A)
data/pokemon/species/kanto.json       + Roucool, Rattata et leurs lignées (5B) ; + catch_rate (5D)
data/pokemon/moves/moves.json         + leurs capacités (5B)
data/battle/messages.json             + modèles sauvages (5B), XP (5C), capture (5D)
data/dialogues/player_house.json      + variante de Maman qui soigne (5B, texte de Kevin)
data/items/items.json                 Poké Ball (5D)
```
`export_presets.cfg` a `include_filter=""` et n'exclut pas `data/` : vérifier `data/encounters/` et `data/items/` dans l'APK (`unzip -l`), comme aux jalons précédents.

**`data/encounters/route_1.json`** — une table = un terrain sur une ou plusieurs cartes. Valeurs **par défaut = Rouge/Bleu** (Q8), d'après les données de la Route 1 de Rouge/Bleu (désassemblage `pokered`, à revérifier en T4) : taux 25/256 par pas ; dix emplacements aux poids de la 1re génération (20, 20, 15, 10, 10, 10, 5, 5, 4, 1) ; au total **Roucool 50 % (N2 à 5), Rattata 50 % (N2 à 4)**.
```json
{
	"route_1_grass": {
		"maps": ["route_1", "pallet_town"],
		"terrain": "grass",
		"rate": 25,
		"slots": [
			{ "species": "pidgey", "levels": [3, 3], "weight": 20 },
			{ "species": "rattata", "levels": [3, 3], "weight": 20 },
			{ "species": "rattata", "levels": [3, 3], "weight": 15 },
			{ "species": "rattata", "levels": [2, 2], "weight": 10 },
			{ "species": "pidgey", "levels": [2, 2], "weight": 10 },
			{ "species": "pidgey", "levels": [3, 3], "weight": 10 },
			{ "species": "pidgey", "levels": [3, 3], "weight": 5 },
			{ "species": "rattata", "levels": [4, 4], "weight": 5 },
			{ "species": "pidgey", "levels": [4, 4], "weight": 4 },
			{ "species": "pidgey", "levels": [5, 5], "weight": 1 }
		]
	}
}
```
`"pallet_town"` dans `maps` : les herbes (23..24, 1..2) de Bourg Palette sont « les véritables hautes herbes de la Route 1 » (dossier 02 §5) ; elles partagent la table (Q7). Kevin peut regrouper les emplacements (« `pidgey` [2, 5] poids 50 ») sans rien changer au code.

**Espèces à ajouter** (`kanto.json` ne contient que les trois lignées de starters) : **`pidgey`** (Roucool, n° 16, Normal/Vol, base 40/45/40/35/35/56, `medium_slow`, `base_exp` 50, ½ mâles) et **`rattata`** (Rattata, n° 19, Normal, base 30/56/35/25/35/72, `medium_fast`, `base_exp` 51, ½ mâles), valeurs modernes. Leurs `evolutions` exigent que la cible existe (`PokemonData` vérifie) : par défaut on ajoute **les lignées complètes** (Roucoups n° 17, Roucarnage n° 18, Rattatac n° 20), comme pour les starters (Q9).

**Capacités à ajouter** (`moves.json`, valeurs modernes) : celles que les sauvages connaissent aux niveaux 2 à 5 — **`gust`** (Tornade : **Vol**, spéciale, 40 ; Normal en 1re génération, Q10), **`sand_attack`** (Jet de Sable : Sol, statut, précision −1 : `STAT_STAGE` sur `acc`, déjà géré par le moteur), et `tackle`, `tail_whip` (existantes) ; puis, pour des learnsets de Rouge/Bleu complets : `quick_attack` (Vive-Attaque, priorité +1, gérée), `whirlwind` (Cyclone), `wing_attack` (Cru-Ailes), `agility` (Hâte), `mirror_move` (Mimique), `hyper_fang` (Croc de Mort), `focus_energy` (Puissance), `super_fang` (Croc Fatal). Celles dont l'effet n'est pas codé portent `pending_effects` (`flinch_10`, `force_switch`, `mirror`, `crit_up`, `half_hp`) : même règle qu'au jalon 4.

**Invariant de jouabilité** (testé, §4) : toute capacité connue par un sauvage de la table **à ses niveaux** n'a **aucun** `pending_effects`. Aujourd'hui vrai (Tornade, Jet de Sable, Charge, Mimi-Queue). **Attention au joueur** : Bulbizarre apprend **Vampigraine au niveau 7** (≈ 5 combats), et Vampigraine n'a **aucun effet** dans le moteur (`pending_effects: ["leech_seed"]`) : question Q28. Salamèche apprend Flammèche au niveau 9 (brûlure ignorée : dégâts corrects), Carapuce Écume au niveau 8 (baisse de Vitesse gérée).

### 3.3 Raccord Bourg Palette ↔ Route 1 (5A)

État actuel : le chemin de Bourg Palette (x 23–24) file jusqu'au bord nord ; (23, 0) et (24, 0) sont `blocked_cells` (le joueur s'arrête en y 1, tête à l'écran) ; aucun warp.

Mécanique retenue : celle du tapis de sortie des maisons, **warp `PUSH`** au bord (le changement de carte vient de `Player.bumped` : en tenant « haut », arrivée puis poussée dans la même mise à jour, jalon 4 §13.6), avec le fondu du routeur (0,45 s, Q6) :

| Carte | Élément | Case | Détail |
|---|---|---|---|
| `pallet_town` | warps `Route1NorthW` / `Route1NorthE` | (23, 1), (24, 1) | `PUSH`, direction haut → `route_1`, spawns `from_pallet_w` / `from_pallet_e`, orientation haut. y 0 reste bloquée. |
| `pallet_town` | spawns `from_route_1_w` / `from_route_1_e` | (23, 1), (24, 1) | arrivée tournée vers le bas, **sur sa colonne** |
| `route_1` | warps `PalletSouthW` / `PalletSouthE` | (23, H−2), (24, H−2) | `PUSH`, direction bas → `pallet_town` ; y H−1 bloquée (`blocked_cells`) |
| `route_1` | spawns `from_pallet_w` / `from_pallet_e` | (23, H−2), (24, H−2) | arrivée tournée vers le haut |

- **Largeur de la Route 1 = 48 cases, chemin d'arrivée en x 23–24** (défaut, Q1) : les deux cartes sont alignées ; une future connexion sans fondu (phase 9 ou 12) n'aura rien à recalculer.
- Une apparition ne déclenche ni rencontre ni scène (aucun `moved`) : arriver sur (23, 1), dans l'herbe, est sans risque.
- Les deux cases d'arrivée de Bourg Palette sont des hautes herbes **et** des warps `PUSH` : autorisé (un déclencheur ou une rencontre sur l'arrivée verrouille le joueur **avant** la poussée ; jalon 4 §13.6). L'invariant devient « jamais une case d'herbe **à rencontres** sous un warp `STEP_ON` ni sous un déclencheur ».
- Le déclencheur `Route1Grass` (23..24, 3) du 3B reste en place : après `starter_chosen`, aucune variante ne s'applique, il ne fait rien.
- **Titre** : `route_1.tscn` a `display_name = "Route 1"`, `region = "Bourg Palette — Jadielle"` (bible §5). `ZoneAnnouncer` fait déjà le reste : « ROUTE 1 » à l'arrivée, « BOURG PALETTE » au retour (règle du jalon 2, « il reviendra en rentrant de la Route 1 »). Le titre reste le bandeau actuel (contradiction avec la bible §5, toujours ouverte).
- `SceneRouter._prefetch_neighbors` précharge déjà la carte voisine d'après les warps.

### 3.4 La carte de la Route 1 (5A) — **à concevoir par Kevin**

Les dossiers ne décrivent pas la Route 1 au-delà de : chemin de terre au centre-nord entre clôtures, champ cultivé, Roucool, vélos (dossier 01, concept golden hour, **côté Bourg Palette**) ; échelle A+ (≈ 3–4×, dense plutôt que gigantesque) ; « routes = lieux, pas des couloirs », « chaque espace a une raison d'exister » ; Jadielle au bout. **Ce plan n'invente pas le level design.** Recommandation : que Kevin produise un court dossier « Route 1 » (comme le dossier 01) avant T1. À défaut, T1 applique l'**esquisse par défaut** ci-dessous, calquée sur la géographie de Rouge/Bleu, **explicitement provisoire** :

```
 PROPOSITION PAR DÉFAUT (Q1 à Q5) — ni tracé ni cases définitifs
 y 0    ███████████ bord nord bloqué (vers Jadielle, Q5) ███████████
        arbres      ║ chemin                  herbes C
        ═══rebord═══╝══╗        ═══rebord═══
        herbes B       ║               arbres, rochers
        ═══rebord════  ╚═══════╗   ═══rebord═══
        clôtures, champ        ║     herbes A (sur le chemin, Q2)
 y H−1  ████████████ chemin x 23–24 → Bourg Palette ███████████
```
- Taille **48 × 72** (≈ 2× l'original dans chaque dimension, comme Bourg Palette : 48 × 34 pour ~20 × 18) ; traversée ≈ 20 s en ligne droite, 30 à 45 s par le chemin (Q1).
- Deux ou trois zones de hautes herbes, **une qu'on ne peut pas contourner** à l'aller (la première rencontre arrive naturellement, Q2).
- **Rebords** qu'on saute vers le sud (raccourci du retour vers Bourg Palette, comme Rouge/Bleu, Q3). `GridWorld.Ledge` et `Grid.LEDGE_JUMP_DURATION` existent ; il manque une **tuile de rebord** (`OverworldTiles.Kind.LEDGE_DOWN`, en fin d'enum, donnée `ledge`) et l'**arc de saut** du joueur (`GridMover.is_jumping()` existe, `Player` ne l'affiche pas).
- Aucun PNJ, aucun objet, aucun point d'intérêt tant que Kevin ne les a pas conçus (Q4).
- Lumière : la même golden hour fixe que Bourg Palette (Q43).

Construction : `tools/build_route_1.gd` (script d'outil, `extends SceneTree`), sur le modèle exact de `tools/build_pallet_town.gd` (tables `GROUND`, `FENCES`, `TREES`, `PROPS_FIXED`, `SPAWNS`, warps) ; si la duplication devient pénible, les fonctions de peinture communes passent dans un `tools/map_builder_common.gd` chargé par `load()`. Le Rattata et le Roucool d'ambiance sont dans `data/npcs/route_1.json` (format réel : objet « identifiant → entrée »).

### 3.5 Les herbes et les Pokémon d'ambiance (5A)

**Jambes dans l'herbe** (annoncé depuis le 3B) : `Player` reçoit un `%GrassFront` (Sprite2D NEAREST, bande d'herbe dessinée **devant** le bas du corps) visible quand la case **d'arrivée** du pas est `is_tall_grass` ; au départ de chaque pas dans l'herbe, un petit froissement (`GrassRustle`, `game/world/grass/grass_rustle.tscn`, 2–3 images ou un `Tween` d'échelle, ~0,25 s, sans allocation par image : un nœud réutilisé par carte). Aucune logique dans ces nœuds : `Player` lit la grille qu'il connaît déjà (`enter_map`).

**Pokémon d'ambiance** (dossier 04 §1) : `AmbientWatcher` (Node, enfant de `Boot`) écoute `player.moved` ; pour chaque PNJ de la carte avec `shy_action` dont le joueur entre dans le rayon (`AmbientRules.is_within`) :
- `fly` (Roucool) : `Npc.fly_away()` — petit appel, envol en arc vers le haut et le bord de l'écran, fondu (~0,6 s, `Tween`), puis `GameMap.remove_npc(id)` ;
- `flee` (Rattata) : `Npc.flee(path)` — 2 à 4 pas en **courant** le long de `AmbientRules.flee_path`, puis fondu et `remove_npc`. Chemin vide : il se retourne et `react()` (petit bond existant).
Ils reviennent au prochain chargement de la carte (présence du fichier). Jamais de combat avec eux (décision 11 du 3B, Q16). Le watcher ne fait rien pendant une scène, une transition, un combat.

```gdscript
class_name AmbientWatcher
extends Node
## Fait réagir les Pokémon d'ambiance « shy » à l'approche du joueur (jalon 5 §3.5).
signal reacted(npc_id: StringName, action: StringName)          # tests
func setup(player: Player) -> void
func set_map(map: GameMap) -> void
```
`Npc` (ajouts) : `fly_away() -> void`, `flee(path: Array[Vector2i]) -> void`, signal `left_scene(npc_id)` émis à la fin (le watcher fait alors `remove_npc`).

### 3.6 Les rencontres (5B)

`EncounterDirector` (`game/pokemon/encounters/encounter_director.gd`, Node, enfant de `Boot`) — le **seul** à lancer une rencontre :
```gdscript
class_name EncounterDirector
extends Node
signal encounter_started(species_id: StringName, level: int)
signal encounter_finished(outcome: int)                  # Battle.Outcome
## Raison de blocage du joueur, de la rencontre jusqu'à la sortie du combat.
const REASON: StringName = &"encounter"
## Faux : aucun tirage (outils de capture, tests d'autres systèmes).
var enabled: bool = true
## [param state] : l'autoload GameState en jeu, une instance neuve de game_state.gd en test.
## [param router] : SceneRouter en jeu, une instance de scene_router.gd en test.
func setup(library: EncounterLibrary, data: PokemonData, state: Node, player: Player,
		battles: BattleDirector, router: Node, cutscenes: CutsceneDirector) -> void
func set_map(map: GameMap) -> void
func is_running() -> bool
## Lance la rencontre [param encounter] sans tirage (tests, départ de débogage).
func start_encounter(encounter: WildEncounter) -> bool
```
Déroulé, sur `player.moved(cell)` :
1. **Gardes** (rien ne se passe) : `not enabled` ; `not player.is_input_enabled()` (pas scripté, dialogue, scène) ; `router.is_transitioning()` ; `cutscenes.is_running()` ; `battles.is_running()` ; `not state.party.has_able()` ; `not map.get_grid().is_tall_grass(cell)` ; pas de table pour (`map.map_id`, `&"grass"`).
2. **Tirage** : `table.roll(state.rng)`. Null : rien.
3. **Verrou synchrone** : `player.set_input_enabled(false, REASON)` **dans le `moved`** (comme les déclencheurs du 3B : le pas suivant ne part pas, même doigt maintenu ou en courant), `encounter_started`.
4. `request = BattleRequest.wild(encounter, data, state.rng, <case de l'herbe qui bouge>)` ; `outcome = await battles.run_request(request, map)`.
5. Fin : `LOSS` → défaite (§3.11) ; sinon rien. Verrou rendu, `encounter_finished(outcome)`.

La case de l'herbe qui bouge : la case **devant** le joueur si elle est en hautes herbes, sinon la sienne. Ordre des écouteurs de `moved` sans importance : une case d'herbe à rencontres ne porte jamais de warp `STEP_ON` ni de déclencheur (invariant, §4).

### 3.7 La transition (~1 s, dossier 05 §3, dossier 04 §2)

« L'herbe bouge → cri → le personnage s'arrête → la caméra se rapproche légèrement → le Pokémon apparaît → le partenaire entre dans le cadre → combat. » Pas de spirale, pas de flash répété, pas d'écran noir, pas de décor générique : **la Route 1 reste le fond du combat** (même mécanisme que le labo du 4B, jalon 4 §3.7).

| t (s) | Monde | Vue de combat (`BattleStage`) | Interface |
|---|---|---|---|
| 0,00 | pas terminé dans l'herbe ; joueur bloqué ; contrôles cachés | — | — |
| 0,00–0,25 | l'herbe de la case d'origine **s'agite** (`GrassRustle` ×2 plus ample) ; le joueur **s'arrête** et se tourne vers elle (Q13) | — | — |
| 0,25 | **cri** : signal `cry_requested(species_id)` sans son (Q14) ; secousse de caméra de 2 px | — | — |
| 0,25–0,55 | zoom 1,00 → `BATTLE_ZOOM`, voile `BATTLE_DIM` (tokens du 4B) | — | — |
| 0,40–0,70 | — | le **sauvage apparaît** à sa place de combat : petit bond depuis le bas + fondu, ombre au sol | — |
| 0,70–1,00 | — | **le partenaire entre dans le cadre** depuis le bord gauche, en courant, jusqu'à sa place (Q15) | — |
| 1,00–1,30 | — | — | cartes (`ANIM_PANEL`), « Un Rattata sauvage apparaît ! », grille d'actions |

Toutes les durées sont des constantes de présentation (tokens), multipliées par `BattleDirector.speed_scale` (0 en test ; futur réglage « Animations Rapides »). **Sortie** : le sauvage disparaît (K.O. : chute et fondu ; fuite : le partenaire repart vers la gauche ; capture : il est déjà dans la Ball), les cartes glissent, le voile et le zoom se retirent (0,3 s), contrôle rendu. Le joueur est **toujours sur sa case d'herbe** : le pas suivant peut déclencher une autre rencontre (Q11).

### 3.8 Le combat sauvage (5B)

Le 4B prévoit `BattleDirector.run(trainer_id, map, world_actors) -> int`, qui construit les camps depuis `TrainerLibrary`. Le 5B le **généralise sans le casser** :
```gdscript
## Coroutine : joue le combat décrit par [param request] sur [param map] et renvoie
## Battle.Outcome (WIN, LOSS, FLED ; CAUGHT en 5D).
func run_request(request: BattleRequest, map: GameMap) -> int
## (4B) Devient une enveloppe : BattleRequest pour un dresseur, puis run_request.
func run(trainer_id: StringName, map: GameMap,
		world_actors: Dictionary[StringName, StringName]) -> int
```
Différences d'un combat sauvage (tout le reste est le 4B) :
- **Camps** : `BattleSide.new(request.foe_party, false, "")` (dresseur vide = sauvage, déjà prévu par `BattleSide`) ; IA `random` (`Battle._init` la pose d'office) ; `Battle.new(..., request.rules)`.
- **Entrée** : §3.7 (`BattleStage.play_wild_intro(origin_screen_pos)`, `play_partner_enter()`) au lieu de l'entrée « dresseur » du labo. Aucun PNJ du monde à cacher.
- **Carte adversaire** : nom, ♂/♀, « Nv. 3 », barre sans chiffres, **pas de pastilles d'équipe** pour un sauvage.
- **Actions** : ATTAQUER et **FUITE actifs** ; SAC atténué jusqu'au 5D ; ÉQUIPE atténué (Q20).
- **FUITE** : `BattleAction.run()` → `FLED` (message, sortie) ou `FLEE_FAILED` (message, l'adversaire joue).
- **Pokédex** : dès le 5D, `SENT_OUT` adverse → `state.pokedex.mark_seen` (le 5B n'a pas encore de Pokédex, rien n'est noté).
- **Fin** : pas de message « Tu as battu… » (dresseur vide : `BattleText` ne renvoie rien) ; pas de soin (`heal_after` n'existe que pour les dresseurs) ; les PV et PP restent tels quels.

Rythme visé : 20 à 40 s (dossier 05 §21). Starter N5 contre un sauvage N2–5 : 2 à 4 tours ; à ~2,5 s par action (message ~0,9 s, élan, PV 0,4 s), ≈ 15–30 s plus 2,5 s d'entrée et de sortie. Chronométré en QA (T8).

### 3.9 XP, niveaux, apprentissage, oubli (5C)

Présentation du dossier 04 §6 (« PIKACHU +142 XP », barre, « Nv. 17 », sans cinq fenêtres) :
- `EXP_GAINED` → sur la **carte joueur**, « **+21 XP** » monte et s'efface (0,8 s) ; une fine **barre d'XP** apparaît sous la barre de PV et se remplit de `exp_from` à `exp_to` (0,6 s), puis disparaît avec la carte (bible §11 : pas de barre d'XP permanente ; `combat-v1.webp` n'en montre pas, Q25).
- `LEVEL_UP` → « Nv. 6 » s'illumine (pulsation `ANIM_MICRO`), la barre de PV prend les nouveaux PV max ; **aucune** fenêtre de statistiques, **aucun** message par défaut (Q25).
- `MOVE_LEARNED` → message « Salamèche apprend Flammèche ! » (proposé).
- `MOVE_FORGET_OFFERED` → le directeur **suspend** la lecture du journal : message « {pokemon} veut apprendre {move}, mais connaît déjà quatre capacités. » (proposé), puis **panneau d'oubli** (§3.12) : la nouvelle capacité en haut, les quatre actuelles en 2 × 2 (cartes du 4B, pression longue = fiche), bouton **NE PAS APPRENDRE**. Toucher une carte la **sélectionne** (bordure d'accent), le bouton **OUBLIER** apparaît ; deux gestes, pas de fenêtre de confirmation (Q30). Choix : `pokemon.replace_move(slot, move, data)` puis « {pokemon} oublie {old_move} et apprend {move} ! » ; refus : « {pokemon} n'apprend pas {move}. ». La lecture reprend.
- Plusieurs Pokémon gagnent de l'XP (après une capture, 5D) : leurs événements s'enchaînent ; seul le Pokémon en jeu a une carte ; pour les autres, le gain est **appliqué sans être montré** au jalon 5 (Q24 ; il n'y a pas d'écran d'équipe).
- **Évolution** : `Evolution.level_up_target` n'est **pas** appelé au jalon 5 (Q27).

### 3.10 La capture (5D)

Flux (storyboard `combat-capture-v1.webp`, dossier 05 §15 à §17, dossier 04 §11–12, pas de geste d'adresse) :
1. **SAC** (or) → panneau **SAC** à gauche, sur le combat visible : section **Balls** (Poké Ball ×N, bordure jaune + ▶ sur la sélection), section Soins **masquée** tant qu'elle est vide, bouton « ‹ ». Un toucher sur une Ball la lance (pas de confirmation, comme une capacité).
2. Le directeur vérifie `state.bag.remove(id)`, puis `battle.submit(BattleAction.ball(id))`.
3. `BALL_THROWN` → `BattleStage.play_throw()` : le **dresseur entre dans le cadrage** (sprite de dos, par-dessus l'épaule, bas gauche, ~0,3 s), lancer en arc, impact, le Pokémon est **absorbé** dans un éclat rouge, la Ball **tombe dans l'herbe** (ombre au sol).
4. `BALL_SHAKE` ×n → une secousse par événement (0,6 s chacune, traits de mouvement) avec **vibration** « toc » (`HAPTIC_BALL_SHAKE_MS`, bible §12).
5. `CAUGHT` → **éclat doré**, « clic », motif de vibration de capture (`HAPTIC_CAPTURE`) ; `BROKE_FREE` → la Ball s'ouvre, le Pokémon réapparaît, « Oh non ! Il s'est libéré ! » (proposé), l'adversaire joue.
6. Capture réussie, **hors moteur**, par le directeur : `state.pokedex.mark_caught(species)` (nouvelle entrée ?), puis `state.party.add(foe)` ou, équipe pleine, `state.storage.add(foe)` ; le Pokémon garde ses PV, PP, niveau, IV (Rouge/Bleu). Carte de capture (§3.12) : « **ROUCOOL CAPTURÉ !** », vignette, « Nouvelle entrée Pokédex » (seulement si nouvelle), puis « Roucool rejoint ton équipe. » ou « Roucool a été confié au système de recherche de Chen. » ; ▼ pour continuer. Sortie du combat.

Aucun surnom (Q34). Pas d'XP à la capture (Q26).

**Les premières Poké Balls** : Rouge/Bleu n'en donne qu'**après le colis de Jadielle** (Pokédex + Poké Balls par Chen), alors que la vertical slice veut capturer sur la Route 1. Défaut (Q32) : **Prof. Chen en donne 5 au labo**, après sa dernière réplique d'après-combat du 4B, par une étape de scène `give` (`{ "give": "poke_ball", "count": 5 }` → `Bag.add` + **toast** « Poké Ball ×5 — Ajoutée au Sac », bible §6) ; la réplique qui l'accompagne est **à écrire par Kevin**. Pour tester avant sa réponse : départ de débogage avec 5 Balls.

### 3.11 Défaite et soin (5B)

Dossier 05 §23 : « Écran très bref → dernier Centre Pokémon visité → soin ». Il n'y a aucun Centre avant Jadielle (dossier 01 : « Pas de Centre Pokémon à Bourg Palette »). Défaut (Q21, Q22), comme Rouge/Bleu avant le premier Centre :
- **Point de soin** : `GameState.heal_map = &"player_house_1f"`, `heal_spawn = &"heal"` (nouveau spawn à côté de Maman, face à elle). Un futur Centre le remplacera.
- **Défaite** (`LOSS`) : pas de message « hors-jeu », pas d'argent perdu (il n'y a pas d'argent) ; sortie du combat, `state.party.heal_all()`, `await router.change_map(heal_map, heal_spawn, Vector2i.UP)` (fondu du routeur : c'est « l'écran très bref »). Aucune réplique par défaut ; une réplique de Maman (texte de Kevin) peut suivre.
- **Soin volontaire** : parler à Maman **après `starter_chosen`** joue une nouvelle variante de `mom` avec `"heal": true` : à la fin du dialogue, `DialogueRunner.heal_requested` → `Boot` → `GameState.party.heal_all()`. **Texte à écrire par Kevin** ; sans texte, la variante n'est pas posée et seul le soin après défaite existe.

### 3.12 Interface (non pixel art, skill `ui-theme-2026`, la bible prime)

Tout ce qui suit **étend l'interface du 4B** (`BattleHud`, `game/ui/battle/`), qui n'existe pas encore (§9). Aucun composant de `game/ui/` ne connaît `Battle`, `Pokemon` ou les données : petites classes de vue, comme au 4B.

**5B**
- Grille d'actions : `show_actions(enabled)` avec **FUITE actif** (gris sombre, pleine opacité) en sauvage ; SAC et ÉQUIPE atténués.
- Carte adverse sans pastilles d'équipe (`BattleCardView.party_count = -1`).
- Messages (proposés, `draft`, à relire par Kevin) : « Un {pokemon} sauvage apparaît ! » ; « Tu prends la fuite ! » ; « Impossible de fuir ! ». Ensuite, **le nom seul** (« Rattata utilise Charge ! »), décision n° 5 du jalon 4 (Q17).

**5C**
- `BattleHud.animate_exp(from: float, to: float, gained: int)` (coroutine, barre d'XP et « +N XP ») ; `pulse_level(side, level)`.
- `MoveForgetPanel` (`game/ui/battle/move_forget_panel.tscn`) : bandeau sombre à la place des grilles, carte de la nouvelle capacité mise en avant, 4 cartes actuelles (`MoveCard` du 4B), **OUBLIER** (accent, visible après sélection) et **NE PAS APPRENDRE** ; signaux `forget_chosen(slot: int)`, `skip_chosen` ; zones ≥ `TOUCH_MIN`, dans `SAFE_MARGIN`.

**5D**
- `BattleBagPanel` (`game/ui/battle/battle_bag_panel.tscn`) d'après la case 2 du storyboard : panneau sombre translucide à gauche, sections, lignes icône + nom + « ×12 », sélection bordure jaune + ▶, « ‹ » ; signaux `item_chosen(item_id)`, `back_requested` ; vue `BagEntryView`.
- `CaptureCard` (`game/ui/battle/capture_card.tscn`) d'après la case 9 : titre en `FONT_TITLE` majuscules, vignette du Pokémon, sous-titre discret, lignes suivantes, ▼ ; `show_capture(view)` (coroutine, se termine au toucher).
- **Toast** (bible §6, premier usage) : `game/ui/components/toast.tscn`, en haut, ~2 s, `ExplorationHud.show_toast(icon, text, detail)` ; jamais bloquant.
- Icônes SVG : `assets/ui/icons/items/poke_ball.svg`.
- **Tokens** : `EXP_BAR_HEIGHT`, `EXP_TWEEN`, `EXP_GAIN_HOLD`, `WILD_INTRO_*` (durées du §3.7), `BALL_SHAKE_TIME`, `HAPTIC_BALL_SHAKE_MS`, `HAPTIC_CAPTURE` (motif), `TOAST_HOLD`, `BAG_PANEL_WIDTH` ; variations de thème `BagPanel`, `CaptureCard`, `Toast` dans `tools/build_ui_theme.gd`.

### 3.13 `GameState`

```gdscript
var flags: StoryFlags            # inchangé
var party: Party                 # inchangé
var starter_species: StringName  # inchangé
var rng: GameRng                 # inchangé : rencontres, sauvages, fuite, capture
var heal_map: StringName = &"player_house_1f"    # 5B : dernier point de soin (§3.11)
var heal_spawn: StringName = &"heal"
var bag: Bag = Bag.new()                          # 5D
var pokedex: Pokedex = Pokedex.new()              # 5D
var storage: PokemonStorage = PokemonStorage.new()  # 5D
func new_game(rng_seed: int = -1) -> void         # remet tout à zéro, y compris les ajouts
```
Aucun nouveau drapeau d'histoire n'est nécessaire en 5A à 5C. En 5D, si Chen donne les Balls (Q32), l'étape `give` est suivie d'un `set: [got_poke_balls]` pour ne les donner qu'une fois.

### 3.14 Signaux et flux

```
5A
Player.moved ─► AmbientWatcher ─► AmbientRules.is_within ─► Npc.fly_away / Npc.flee
             ─► Npc.left_scene ─► GameMap.remove_npc
Player (pas terminé) ─► grid.is_tall_grass ─► %GrassFront visible · GrassRustle
Player.bumped (23|24, 1) haut ─► SceneRouter ─► route_1 ─► map_entered ─► ZoneAnnouncer « ROUTE 1 »
5B
Player.moved(cell) ─► EncounterDirector : gardes ─► EncounterTable.roll(GameState.rng)
   ─► Player.set_input_enabled(false, &"encounter") ─► encounter_started ─► Boot._refresh_controls
   ─► BattleRequest.wild ─► BattleDirector.run_request
        ─► BattleStage.play_wild_intro / play_partner_enter ─► BattleHud (cartes, actions)
        ─► Battle.start / submit(MOVE | RUN) ─► [BattleEvent] ─► BattleText ─► BattleHud / BattleStage
   ◄─ outcome ─► LOSS : party.heal_all ─► SceneRouter.change_map(heal_map, heal_spawn)
   ─► verrou rendu ─► encounter_finished ─► Boot._refresh_controls
Maman (variante heal) ─► DialogueRunner.heal_requested ─► Boot ─► GameState.party.heal_all
5C
Battle : FAINTED(FOE) ─► EXP_GAINED · LEVEL_UP · MOVE_LEARNED · MOVE_FORGET_OFFERED ─► BATTLE_ENDED
BattleDirector : MOVE_FORGET_OFFERED ─► MoveForgetPanel ─► forget_chosen(slot) ─► Pokemon.replace_move
5D
BattleHud SAC ─► BattleBagPanel.item_chosen ─► Bag.remove ─► Battle.submit(ITEM)
   ─► BALL_THROWN · BALL_SHAKE ×n · CAUGHT | BROKE_FREE ─► BattleStage.play_throw / shake (vibration)
   ─► CAUGHT : Pokedex.mark_caught · Party.add | PokemonStorage.add ─► CaptureCard
```
`EncounterTable`, `Battle`, `ExpCalc`, `CaptureCalc`, `Bag`, `Pokedex` ne connaissent aucun nœud. `BattleHud`, `BattleStage`, `BattleBagPanel`, `CaptureCard`, `MoveForgetPanel` ne connaissent ni le moteur ni les données. `GameMap`, `Npc`, `Player` ne connaissent ni `EncounterDirector` ni `AmbientWatcher`. `EncounterDirector` et `BattleDirector` reçoivent `GameState` et le routeur par `setup`. `Boot` reste la seule racine de composition.

### 3.15 Fichiers à créer ou modifier

```
5A  game/world/grid_world.gd · map.gd · npc/npc.gd · npc_spec.gd · npc_roster.gd (modifiés)
    game/world/npc/ambient_rules.gd · ambient_watcher.gd · game/world/grass/grass_rustle.tscn/.gd
    game/player/player.gd/.tscn (GrassFront, arc de saut) · game/world/overworld_tiles.gd (LEDGE_DOWN)
    game/world/maps/route_1.tscn · pallet_town.tscn (warps, spawns) · data/npcs/route_1.json
    tools/build_route_1.gd · build_pallet_town.gd · gen_placeholder_tiles.gd · capture_play.gd
5B  game/pokemon/encounters/encounter_slot.gd · wild_encounter.gd · encounter_table.gd
    game/pokemon/encounters/encounter_library.gd · encounter_director.gd
    game/battle/battle_rules.gd · battle_request.gd · flee_calc.gd
    game/battle/battle.gd · battle_action.gd · battle_event.gd · battle_text.gd (modifiés)
    game/battle/battle_director.gd · battle_stage.gd (4B, modifiés) · game/ui/battle/* (4B, modifiés)
    game/systems/dialogue/dialogue.gd · dialogue_library.gd · dialogue_runner.gd (heal)
    game/autoload/game_state.gd · game/boot.gd/.tscn · game/world/maps/player_house_1f.tscn (spawn heal)
    data/encounters/route_1.json · data/pokemon/species/kanto.json · moves/moves.json
    data/battle/messages.json · data/dialogues/player_house.json (si texte)
    assets/sprites/pokemon/placeholder/{pidgey,rattata}_front.png · _back.png
5C  game/pokemon/exp_calc.gd · game/battle/battle.gd · battle_event.gd (modifiés)
    game/ui/battle/move_forget_panel.tscn/.gd · battle_hud.gd (XP) · data/battle/messages.json
5D  game/items/item_data.gd · item_library.gd · bag.gd · data/items/items.json
    game/battle/capture_calc.gd · capture_result.gd · game/pokemon/pokedex.gd · pokemon_storage.gd
    game/ui/battle/battle_bag_panel.tscn/.gd · capture_card.tscn/.gd · game/ui/components/toast.tscn/.gd
    game/systems/cutscene/* (étape give, si Q32) · assets/sprites/characters/placeholder/player_back*
tests : voir §5 et §6
```

### 3.16 Assets provisoires

- **Tuiles** : `LEDGE_DOWN` (et `LEDGE_LEFT` / `LEDGE_RIGHT` seulement si le tracé en veut) dans `tools/gen_placeholder_tiles.gd` ; la tuile `TALL_GRASS` du 3B sert telle quelle ; une bande `grass_front.png` pour les jambes.
- **Sprites de combat** : `pidgey` et `rattata`, face et dos (le dos sert quand un Pokémon capturé est envoyé), 64 × 64 natif, générés par `tools/gen_placeholder_battlers.gd` (4B). Les sprites du monde de 3A (`pidgey`, `rattata`) servent pour l'ambiance ; il leur faut un « vol » et une « course » (2 images ou un `Tween`).
- **Dresseur de dos** (5D) : `player_back` 64 × 128, deux poses (prise, lancer).
- **Poké Ball** : sprite 16 × 16 natif (×3), 3 images de secousse, éclat.
- Aucun son (Q14).

---

## 4. Invariants (testés)

**Route 1 et raccord** (`tests/integration/test_route_1.gd`, nouveau ; `test_pallet_town.gd`, `test_map_links.gd`, étendus) :
- tous les warps des deux cartes visent une carte et un spawn existants ; chaque colonne revient sur sa colonne ; aucun spawn sur une case solide, occupée ou de déclencheur ;
- depuis `from_pallet_w` et `from_pallet_e`, le bout nord de la Route 1 est atteignable (`find_path`, **rebords compris** : on ne remonte jamais un rebord) ; depuis **toute** case atteignable, le retour vers Bourg Palette l'est aussi (aucun piège sous un rebord) ; aucune poche ;
- Bourg Palette : les invariants du 1, du 3B et du 4 restent vrais ; (23, 0) et (24, 0) toujours inatteignables ;
- aucune case d'herbe **à rencontres** ne porte de warp `STEP_ON`, de déclencheur ni de PNJ ; aucun spawn, **sauf** les arrivées du raccord `from_route_1_w` / `from_route_1_e` (une apparition ne fait aucun tirage) ;
- (si Q2 = défaut) une zone d'herbe ne peut pas être contournée : sur une grille où ses cases sont rendues solides, le nord n'est plus atteignable ;
- Pokémon d'ambiance : case praticable, hors herbe, hors chemin obligé (aucune poche s'il ne bouge pas) ; `flee_path` non vide depuis sa case pour un joueur venant du chemin.

**Rencontres et données** (`tests/integration/test_encounter_content.gd`, nouveau) :
- `EncounterLibrary.load_dir()` sur les vraies données : 0 erreur ; chaque carte de `maps` existe (`MapCatalog.has_map`) et **a au moins une case `tall_grass`** ; chaque carte qui a des hautes herbes atteignables **après `starter_chosen`** a une table (liste d'exceptions explicite, vide par défaut) ;
- pour chaque emplacement et chaque niveau : `PokemonFactory.create` donne un Pokémon valide avec au moins une capacité à PP > 0, et **aucune capacité à `pending_effects`** ;
- tous les modèles de `messages.json` se chargent ; chaque texte du dossier 05 §17 est **égal** à la chaîne recopiée dans le test.

**Simulation** (`test_battle_simulation.gd`, étendu, graines 0..999) : chaque starter N5 contre chaque emplacement de la table : le combat se termine (≤ 50 tours), sans erreur ; taux de victoire et **nombre moyen de tours rapportés** (information pour Kevin, pas un seuil) ; en 5C, XP cumulée jusqu'au niveau 7, 8 et 9 (nombre de combats rapporté).

---

## 5. Découpage des tâches (dans l'ordre)

Chaque tâche finit par un essai sur le S24 (capture et retour de Kevin) avant la suivante. Code sur des branches cloud (`jalon-05a`… `jalon-05d`), QA sur le Mac.

### 5A — la Route 1

#### T0 — architecte-godot : fondations du 5A
- **Aligner ce plan** sur le code fusionné du 4B et sur les réponses de Kevin (Q1 à Q7, Q16) ; §2.1.
- **CA** : tests du §2.1 verts ; import sans erreur ; `tools/test.sh` vert (nombre de tests rapporté ; 949 au moment de ce plan).

#### T1 — constructeur-monde : la carte et le raccord
- `OverworldTiles.Kind.LEDGE_DOWN` (fin d'enum, donnée `ledge`), `gen_placeholder_tiles.gd` ; arc de saut du joueur (`Player`, ombre au sol) ; `tools/build_route_1.gd` → `route_1.tscn` (tracé de Kevin ou esquisse du §3.4) ; warps et spawns du §3.3 dans les deux cartes ; titre.
- **CA** :
  - `test_overworld_tileset.gd` : `LEDGE_DOWN` a `ledge = DOWN`, non solide ; coordonnées d'atlas des types existants inchangées.
  - `test_route_1.gd`, `test_pallet_town.gd`, `test_map_links.gd` : invariants du §4 (Route 1 et raccord).
  - `tests/integration/test_route_1_link.gd` (vrai `Boot`, départ `pallet_town` en (23, 4) avec `starter_chosen`, fondus raccourcis) : `move_up` tenu → arrivée sur la Route 1 en (23, H−2), tourné vers le haut, titre « Route 1 » / « Bourg Palette — Jadielle » ; `move_down` tenu → retour en (23, 1), titre « Bourg Palette » ; même chose par la colonne 24 ; un saut de rebord dure `LEDGE_JUMP_DURATION` et franchit deux cases.
  - Capture Movie Maker (`tools/capture_play.gd`, scénarios `route1_link`, `route1_walk`) à 2340 × 1080, lues avec Read : raccord, titre, herbes lisibles, rebords compréhensibles, rien de coupé.
  - **S24** : aller au bout de la Route 1 et revenir, en marchant et en courant ; sauter les rebords.

#### T2 — constructeur-monde : les herbes et les Pokémon d'ambiance
- `%GrassFront`, `GrassRustle` ; `Npc.fly_away` / `flee` ; `AmbientWatcher` ; `data/npcs/route_1.json` (Q16).
- **CA** :
  - `test_player.gd` : `GrassFront` visible exactement sur les cases `tall_grass` (dès le début du pas qui y entre, caché dès le début du pas qui en sort) ; aucun nœud créé par pas.
  - `tests/integration/test_ambient_watcher.gd` (mini-carte) : joueur hors du rayon → rien ; dans le rayon → `reacted(id, &"fly")`, puis PNJ retiré et case libérée ; `flee` : le Rattata s'éloigne réellement puis disparaît ; acculé → `react()` et il reste ; aucune réaction pendant une scène ou un pas scripté ; recharger la carte → il est revenu.
  - Capture (scénario `route1_ambient`) : jambes cachées, froissement, envol, fuite. Lue avec Read.
  - **S24** : les herbes « se sentent » ; le Roucool s'envole, le Rattata détale ; 60 fps.

#### T3 — qa-mobile : validation du 5A sur le S24
- **CA à vérifier et rapporter** : raccord dans les deux sens, sur les deux colonnes, en marchant et en courant, doigt maintenu (jamais bloqué contre le bord, jamais de double changement) ; titre à chaque changement de zone ; rebords (jamais bloqué en contrebas) ; jambes dans l'herbe sans clignotement ; ambiance ; changement de carte < 100 ms ; 60 fps en traversant les herbes ; aucune erreur `NpcRoster`, `GameMap` dans logcat ; temps de traversée chronométré (Q1).

### 5B — la rencontre

#### T4 — architecte-godot : fondations du 5B
- **Aligner** sur le code réel du 4B (§9) ; §2.2 ; espèces, capacités, table.
- **CA** : tests du §2.2 verts ; `PokemonData`, `EncounterLibrary`, `BattleText` sur les vraies données : 0 erreur ; simulation du §4 ; import sans erreur.

#### T5 — constructeur-monde : rencontre et transition (sans combat jouable)
- `EncounterDirector` (§3.6) ; `BattleStage.play_wild_intro`, `play_partner_enter` et sortie ; `GrassRustle` d'origine ; placeholders `pidgey`, `rattata` ; scénario de capture qui joue une rencontre forcée (`start_encounter`) puis un journal **écrit à la main**.
- **CA** :
  - `tests/integration/test_encounter_director.gd` (mini-carte avec herbes, `ScriptedRng`, `speed_scale = 0`, `BattleDirector` factice qui renvoie une issue) : un pas terminé dans l'herbe avec un tirage gagnant bloque le joueur **dans le `moved`** et le pas suivant ne part pas (`move_up` tenu) ; tirage perdant → rien ; aucune rencontre hors herbe, pendant une scène, une transition, un pas scripté, un combat, ni sans Pokémon valide ; la requête a la bonne espèce, le bon niveau, la bonne case d'origine ; à la fin, joueur libre et `encounter_finished`.
  - `test_battle_stage.gd` (étendu) : intro sauvage et entrée du partenaire se terminent ; positions finales = `BattleLayout` ; `hide_all` remet tout en place.
  - Capture à 2340 × 1080, image par image (~10 images sur 1,3 s) : herbe qui bouge, zoom, apparition, partenaire, cartes. Lues avec Read : Route 1 derrière, **aucune image noire**, rien de coupé.
  - **S24** : Kevin juge la transition (durée, lisibilité, Q13 à Q15) **avant** l'interface.

#### T6 — ui-mobile : l'interface du combat sauvage
- FUITE active, carte adverse sans pastilles, modèles sauvages dans la HUD ; tokens du §3.7.
- **CA** : `test_battle_hud.gd` (étendu) : en sauvage, FUITE émet **un** `action_selected(&"run")`, SAC et ÉQUIPE n'émettent rien ; carte adverse sans pastilles ; zones ≥ `TOUCH_MIN` dans `SAFE_MARGIN` à 1920 et 2340. Captures lues avec Read. Couleurs, tailles et durées via `UiTokens` uniquement.

#### T7 — constructeur-monde : le combat sauvage jouable
- `BattleDirector.run_request` (§3.8), fuite, fin ; défaite et point de soin (§3.11) ; clé `heal` et variante de Maman (si texte) ; câblage de `Boot`.
- **CA** :
  - `test_battle_director.gd` (étendu) : combat sauvage complet (graine fixe, `speed_scale = 0`) : chaque événement joué une fois et dans l'ordre ; FUITE → `FLED` ou `FLEE_FAILED` puis action adverse ; victoire → `WIN`, PV **non** soignés ; le combat du rival (4B) inchangé.
  - `tests/integration/test_wild_battle.gd` (vrai `Boot`, départ Route 1 avec `starter_chosen` et un starter N5, graines choisies) : marcher dans l'herbe jusqu'à une rencontre ; combattre en choisissant la 1re capacité → victoire, joueur libre sur sa case d'herbe, contrôles visibles ; autre graine → fuite réussie ; autre → défaite : arrivée chez Maman sur `heal`, équipe soignée, titre non affiché (intérieur).
  - `test_dialogue_runner.gd` : `heal` → `heal_requested` **une fois**, à la fin du dialogue.
  - **Export** : `data/encounters/` dans l'APK.
  - Capture (scénario `wild_battle`) ; **S24** : dix rencontres, dont une fuite et une défaite forcée.

#### T8 — qa-mobile : validation du 5B
- **CA** : fréquence ressentie des rencontres (nombre de pas entre deux, sur 10 rencontres, Q8) ; transition ~1 s sans écran noir ; lisibilité de la Route 1 derrière le combat ; FUITE ; **durée de chaque combat chronométrée** (visée 20–40 s) ; défaite et retour chez Maman ; soin chez Maman ; aucune rencontre en sortant d'un combat avant le pas suivant ; 60 fps pendant la transition ; aucune erreur `Encounter*`, `Battle*` dans logcat.

### 5C — l'XP

#### T9 — architecte-godot : fondations du 5C
- §2.3 (+ Vampigraine si Q28 = oui) ; départ de débogage : `GameState` construit depuis un petit fichier de fixtures (équipe, niveaux, capacités, Balls), chargé **seulement en build debug** (mécanisme précis à choisir sur le code du moment : option de `Boot` lue au démarrage, ou scène de débogage).
- **CA** : tests du §2.3 verts ; simulation : combats nécessaires pour atteindre N7, N8, N9 rapportés par starter.

#### T10 — ui-mobile : XP, niveau, panneau d'oubli
- `animate_exp`, `pulse_level`, `MoveForgetPanel`, tokens.
- **CA** : `test_battle_hud.gd` : barre d'XP de `from` à `to` en `EXP_TWEEN`, cachée ensuite ; « +N XP » affiché puis effacé ; `test_move_forget_panel.gd` : 5 cartes, **un** toucher sélectionne sans rien émettre, OUBLIER → **un** `forget_chosen(slot)`, NE PAS APPRENDRE → **un** `skip_chosen`, pression longue = fiche sans sélection ; zones tactiles. Captures lues avec Read.

#### T11 — constructeur-monde : XP et apprentissage jouables
- Lecture de `EXP_GAINED`, `LEVEL_UP`, `MOVE_LEARNED`, `MOVE_FORGET_OFFERED` par le `BattleDirector` ; suspension et reprise du journal ; départ de débogage.
- **CA** : `test_battle_director.gd` : XP du Pokémon = somme affichée ; `MOVE_FORGET_OFFERED` → panneau ; oubli → capacité remplacée (PP pleins) ; refus → capacités inchangées ; `test_wild_battle.gd` : cinq victoires → niveau et capacité de Rouge/Bleu corrects pour les 3 starters. Captures (scénarios `exp_gain`, `move_forget`). **S24** : montée de niveau en jeu ; oubli par le départ de débogage.

#### T12 — qa-mobile : validation du 5C
- **CA** : « +XP », barre, « Nv. » lisibles et rapides (pas de fenêtre) ; capacité apprise ; oubli clair et impossible à déclencher par erreur ; durée d'un combat avec montée de niveau ; aucune erreur logcat.

### 5D — la capture

#### T13 — architecte-godot : fondations du 5D
- §2.4 ; `catch_rate` ; `data/items/items.json` ; étape `give` (si Q32 = Chen).
- **CA** : tests du §2.4 verts ; taux de capture calculés pour Roucool N3 à PV pleins, moitié, 1 PV (rapportés à Kevin).

#### T14 — ui-mobile : le SAC, la carte de capture, le toast
- `BattleBagPanel`, `CaptureCard`, `Toast`, icônes, tokens, haptique.
- **CA** : `test_battle_bag_panel.gd` (sections, masquage de Soins vide, sélection, **un** `item_chosen`, « ‹ ») ; `test_capture_card.gd` (titre, ligne « Nouvelle entrée Pokédex » seulement si demandée, fin au toucher) ; `test_toast.gd` (visible puis caché après `TOAST_HOLD`, n'intercepte aucun toucher). Captures comparées aux cases 2 et 9 de `combat-capture-v1.webp`.

#### T15 — constructeur-monde : la capture jouable
- `play_throw`, secousses, éclat, sprite du dresseur de dos ; `BattleDirector` : ITEM, Sac, Pokédex, équipe ou stockage ; SAC actif en sauvage ; source des Poké Balls (Q32).
- **CA** : `test_battle_director.gd` : Ball retirée du Sac **une fois** ; capture → équipe de 2 (même instance, PV conservés), `pokedex.is_caught` ; équipe pleine → stockage et bon message ; échec → Ball perdue, l'adversaire joue ; `test_wild_battle.gd` : capture complète avec une graine choisie ; vibrations demandées ×3 puis motif de capture (espion sur `Input.vibrate_handheld` ou enveloppe injectée). **Export** : `data/items/` dans l'APK. Capture image par image des « trois secondes sacrées ». **S24** : captures réussies et ratées.

#### T16 — qa-mobile : validation du 5D
- **CA** : lancer, absorption, chute dans l'herbe, trois secousses **ressenties** (vibration), clic ; carte lisible ; Pokémon capturé envoyé automatiquement si le starter tombe ; 60 fps pendant le lancer ; aucune erreur logcat.

---

## 6. Critères d'acceptation par sous-jalon (récapitulatif)

| | 5A | 5B | 5C | 5D |
|---|---|---|---|---|
| Tests | §2.1 + T1–T2 | §2.2 + T5–T7 | §2.3 + T10–T11 | §2.4 + T14–T15 |
| Toujours | `tools/test.sh` vert (tout ce qui précède compris), import sans `ERROR` ni `SCRIPT ERROR`, nombre de tests rapporté | | | |
| Déterminisme | — | graine fixe → même rencontre, même journal | même XP | même capture |
| Textes | titre de la bible §5 | messages sauvages validés ou `draft` | idem | textes du dossier 05 §17 **identiques** |
| Captures | T1, T2 | T5, T6, T7 | T10, T11 | T14, T15 |
| S24 | traversée, 60 fps | 10 combats, fuite, défaite, 60 fps | niveaux, oubli (débogage) | captures, vibration |
| Export | — | `data/encounters` | — | `data/items` |

**Tests GUT prévus** — unitaires nouveaux : `test_ambient_rules`, `test_encounter_table`, `test_encounter_library`, `test_flee_calc`, `test_exp_calc`, `test_capture_calc`, `test_bag`, `test_item_library`, `test_pokedex`, `test_pokemon_storage` ; étendus : `test_grid_world`, `test_npc_roster`, `test_battle`, `test_battle_text`, `test_battle_simulation`, `test_pokemon_data`, `test_dialogue_library`, `test_game_state`, `test_overworld_tileset`. Intégration nouveaux : `test_route_1`, `test_route_1_link`, `test_ambient_watcher`, `test_encounter_content`, `test_encounter_director`, `test_wild_battle`, `test_move_forget_panel`, `test_battle_bag_panel`, `test_capture_card`, `test_toast` ; étendus : `test_game_map`, `test_pallet_town`, `test_map_links`, `test_player`, `test_npc`, `test_dialogue_runner`, `test_boot`, et ceux du 4B (`test_battle_stage`, `test_battle_hud`, `test_battle_director`). Fixtures : `tests/fixtures/encounters/`, `tests/fixtures/items/`, `tests/fixtures/debug_start/`.

---

## 7. Validation S24 (résumé)

| Après | Ce que Kevin essaie sur le S24 |
|---|---|
| T1 | La Route 1 : aller, retour, rebords, titres. |
| T2 | Les herbes, le Roucool qui s'envole, le Rattata qui détale. |
| T3 | Rapport de QA. **Validation du 5A.** |
| T5 | La transition seule (jusqu'à la vue de combat). |
| T6 | (captures) FUITE et messages sauvages. |
| T7 | Des combats sauvages : victoire, fuite, défaite, soin. |
| T8 | Rapport de QA. **Validation du 5B.** |
| T10–T11 | « +XP », « Nv. », capacité apprise ; oubli par le départ de débogage. |
| T12 | Rapport de QA. **Validation du 5C.** |
| T14–T15 | Le SAC, la capture, la carte. |
| T16 | Rapport de QA. **Validation du jalon 5.** |

---

## 8. Hypothèses et questions pour Kevin

> **Décisions de Kevin (2026-09-26) — `docs/design/dossier-07-route-1.md`** : ce dossier **prime** sur les propositions par défaut ci-dessous et sur l'esquisse de carte du plan. À retenir pour l'alignement du plan :
> - **Q1–Q5 tranchées** : Route A+ compacte (direct 2–3 min, exploration 8–12 min), chemin qui **serpente**, transition sud (entretenu) → centre (nature, relief) → nord (traces humaines vers Jadielle) ; **3 zones d'herbes** (initiation contournable ; exploration avec un recoin et un secret ; **bande courte obligatoire** vers la moitié / deuxième moitié) ; **rebords vers le sud** avec saut animé, ombre, atterrissage, haptique ; **un seul PNJ, le Voyageur** (3 répliques), qui **marche** dans une petite zone près du chemin (jamais dans les herbes, ne bloque jamais le passage, s'arrête et se tourne vers le joueur quand on lui parle) — première application de la règle « PNJ avec une petite activité » (routines locales simples, pas d'horaires) ; **Potion cachée** dans les racines, sans scintillement, avec toast ; **aucun Dresseur** ; **l'entrée de Jadielle fonctionne** (« JADIELLE — À venir » seulement en build de développement si la ville n'existe pas encore).
> - **Q8** : Roucool Nv. 2–5, Rattata Nv. 2–4 ; Pokémon d'ambiance **distincts** des rencontres (Roucool sur une clôture, Rattata qui traverse et disparaît dans les herbes).
> - **Q21** : défaite → réveil **à la maison**, Maman a soigné ; première fois : « Tu m'as fait une de ces peurs... » / « Tes Pokémon vont bien. Repose-toi un peu avant de repartir. » ; ensuite « Tes Pokémon vont bien maintenant. » / « Fais attention à toi, d'accord ? » (toujours chaleureuse, jamais moqueuse). Maman = point de récupération tant qu'aucun Centre n'est découvert.
> - **Q32** : **Chen donne 5 Poké Balls** à la fin du jalon 4 (après ses dernières paroles) : « Une dernière chose. » → Poké Balls ×5 → « Observer les Pokémon t'apprendra beaucoup. Mais parfois, le meilleur moyen de les comprendre est encore de voyager avec eux. » → « Utilise-les avec discernement. ». **À intégrer au 4B.**
> - Première capture libre (aucune capture scriptée) ; micro-indication **une seule fois** à la première ouverture des Poké Balls : « Affaiblir un Pokémon facilite sa capture. ».
> - XP réelle à partir de la Route 1 ; XP de capture à définir dans le système.
> - **Q39 — sauvegarde** : **autosave obligatoire avant la validation du jalon 5, idéalement avant la capture finale** (contenu minimal listé au §13 du dossier 07). Ordre proposé : **5A carte → 5B rencontre → 5C XP → sauvegarde → 5D capture**.
> - **Consigne** : ne pas surcharger graphiquement la Route 1 ; valider géométrie, rythme, rencontres, raccourcis et exploration avec des assets provisoires avant la passe DA.
> - Les autres questions (Q6–Q7, Q9–Q20, Q22–Q31, Q33–Q38, Q40–Q43) : propositions par défaut.

Hypothèses techniques (pas de décision de design) :
- Le combat sauvage est **le combat du 4B**, par-dessus la carte courante, sans changement de scène ; un `BattleRequest` décrit ce qui change (sauvage ou dresseur, règles, entrée).
- Les rencontres, les objets et les messages sont des **données JSON** validées strictement ; les zones de rencontre sont les cases `tall_grass` des cartes listées par la table.
- Tout l'aléatoire (rencontres, sauvages, combat, fuite, capture) passe par `GameState.rng`, dans un ordre documenté ; une graine rejoue la même partie.
- Le moteur produit un journal ; l'XP et la capture y ajoutent des événements ; **aucun choix du joueur dans le moteur** (l'oubli est résolu par la présentation).
- Pas de sauvegarde (Q39).

Questions (**proposition par défaut** entre parenthèses ; c'est ce que le plan applique si tu ne dis rien). Les questions de level design gagneraient à recevoir une réponse groupée sous forme d'un **court dossier « Route 1 »**.

**La carte (5A)**
1. **Taille** : aucune n'est donnée. (*48 × 72 cases : même largeur que Bourg Palette, chemin d'arrivée aligné en x 23–24, ≈ 2× l'original dans chaque dimension ; traversée 30 à 45 s par le chemin.*)
2. **Tracé et zones d'herbe** : combien, où, évitables ? (*Esquisse du §3.4 : chemin qui serpente, 2 à 3 zones d'herbe dont une qu'on ne peut pas contourner à l'aller ; tout le reste à ta conception.*)
3. **Rebords** à sauter vers le sud (raccourci du retour, comme Rouge/Bleu) ? (*Oui, vers le bas seulement ; il faut une tuile et l'arc de saut du joueur.*)
4. **PNJ, objets, points d'intérêt** (« chaque espace a une raison d'exister ») : Rouge/Bleu a l'employé de la boutique qui donne une Potion et un garçon qui parle des rebords. (*Aucun au jalon 5 : la Potion demande des objets de soin, et les personnages sont à concevoir ; emplacements réservés sur la carte si tu les veux plus tard.*)
5. **Où s'arrête la carte côté Jadielle** : (*bord de carte bloqué, rien de Jadielle visible, comme la sortie de Bourg Palette au jalon 1, décision n° 6.* Autre choix : l'amorce de Jadielle visible mais inaccessible, avec une pensée à écrire.)
6. **Raccord** : fondu de 0,45 s comme les portes, ou continuité sans chargement entre les deux zones ? (*Fondu au jalon 5 ; la continuité est possible plus tard grâce aux cartes alignées.*) Titre « ROUTE 1 / Bourg Palette — Jadielle » à chaque arrivée depuis Bourg Palette, « BOURG PALETTE / Kanto » au retour. (*Oui, règle du jalon 2.*)
7. **Les herbes de Bourg Palette** (23..24, 1..2) déclenchent-elles des rencontres ? (*Oui, même table : ce sont « les véritables hautes herbes de la Route 1 ».*)

**Les rencontres (5B)**
8. **Espèces, niveaux, taux** : (*référence d'origine Rouge/Bleu : Roucool N2–5 (50 %) et Rattata N2–4 (50 %), 25/256 par pas dans l'herbe, soit une rencontre tous les ~10 pas en moyenne ; dix emplacements du §3.2.*) Ni Roucool ni Rattata n'existent dans `kanto.json` (seulement les trois lignées de starters).
9. **Lignées complètes** (Roucoups, Roucarnage, Rattatac) avec les learnsets de Rouge/Bleu ? (*Oui, comme les starters ; capacités non jouables marquées `pending_effects`.*)
10. **Capacités manquantes** dans `moves.json` : Tornade, Jet de Sable (utiles tout de suite), Vive-Attaque, Cyclone, Cru-Ailes, Hâte, Mimique, Croc de Mort, Puissance, Croc Fatal. **Tornade** est Normal en 1re génération, Vol depuis. (*Valeurs modernes : Vol.*)
11. **Période de grâce** après un combat ou une arrivée ? (*Aucune, comme Rouge/Bleu.*)
12. **Indices dans l'herbe** (dossier 04 §3 : herbe qui bouge = quelque chose est là, traces, cri au loin) : (*pas au jalon 5 ; seulement l'herbe qui bouge au moment de la rencontre. À concevoir avec les Pokémon rares.*)
13. **« Le personnage se retourne »** (dossier 04 §2) ou **« s'arrête »** (dossier 05 §3) ? (*Il s'arrête et se tourne vers l'herbe qui bouge : dossier 05, plus récent.*)
14. **Le cri** : le projet n'a encore aucun son. (*Pas de son au jalon 5 ; la transition garde un temps de 0,25 s et un point d'accroche pour le cri ; sons en phase 10.*) Veux-tu un bruitage provisoire plus tôt ?
15. **« Le partenaire entre dans le cadre »** : (*il arrive en courant depuis le bord gauche, sans Poké Ball, dans l'esprit du partenaire (dossier 04 §4) ; pas de compagnon qui suit, décision Q-D.* Autre choix : lancer de Ball comme les jeux classiques.)
16. **Pokémon d'ambiance** de la Route 1 : (*deux Roucool posés sur des clôtures qui s'envolent quand on arrive à 2 cases, un Rattata près du chemin qui détale à 2 cases ; ils reviennent quand on revient sur la carte ; jamais de combat. Ceux de la prairie de Bourg Palette restent immobiles (validés au 3B).* Papilusion « très rare » : dossier 01 §6, prairie ; pas au jalon 5.)

**Le combat sauvage (5B)**
17. **Messages** (proposés, à relire) : « Un Rattata sauvage apparaît ! », « Tu prends la fuite ! », « Impossible de fuir ! » ; ensuite **le nom seul** (« Rattata utilise Charge ! »), même si ton Roucool capturé combat un Roucool sauvage. (*Oui.*)
18. **Fuite** : (*formule des 3e et 4e générations : toujours réussie si ton Pokémon est au moins aussi rapide, sinon chances croissantes à chaque essai ; un échec laisse l'adversaire jouer.*)
19. **Durée** : (*messages ~0,9 s, visée 20 à 40 s par combat ; l'option « Animations Complètes / Rapides » est préparée (`speed_scale`), pas proposée au jalon 5.*)
20. **ÉQUIPE en combat sauvage** : (*inactif tout le jalon, même après une capture ; un Pokémon K.O. est remplacé automatiquement.*)
21. **Défaite** : dossier 05 §23, « dernier Centre visité », mais il n'y en a aucun. (*Écran très bref, retour à la maison à côté de Maman, équipe soignée, sans réplique ; comme Rouge/Bleu avant le premier Centre.*) Veux-tu une réplique de Maman ?
22. **Se soigner sans Centre** : entre deux combats, les PV ne remontent pas. (*Parler à Maman soigne l'équipe ; il faut sa réplique : à écrire. Sans texte, seul le soin après défaite existe.* Autre choix : Prof. Chen ou Maya au labo.)
    → **Décision Kevin (2026-10-02)** : **parler à Maman soigne l'équipe**, et cette possibilité **reste même quand les Centres Pokémon existeront**. Après avoir utilisé un Centre, c'est le **dernier Centre utilisé** qui devient le point de retour après une défaite, à la place de la maison. Réplique de Maman : provisoire, relue à la validation 5C. Câblage en T11 (clé de dialogue `heal` existante).

**L'XP (5C)**
23. **Formule** : (*b × N / 7 pour un sauvage, × 1,5 contre un dresseur — celle de Rouge/Bleu et de la 6e génération — avec les `base_exp` modernes déjà en données : Roucool N3 → 21 XP ; ≈ 5 combats pour passer du N5 au N7.*)
    → **Décision Kevin (2026-10-02)** : rythme gardé (arrivée à Jadielle vers N7–N8, simulation du T9) ; **courbe d'XP inchangée** ; à rejuger au doigt sur S24 une fois T10 et T11 intégrés.
24. **Partage** entre plusieurs Pokémon : (*parts égales entre ceux qui ont combattu ce Pokémon et sont encore debout ; pas de Multi Exp. ; le gain d'un Pokémon qui n'est pas en jeu n'est pas montré.*)
25. **Présentation** : (*« +21 XP » sur la carte, barre d'XP visible seulement pendant le gain, « Nv. 6 » qui s'illumine ; pas de message de niveau, pas de statistiques ; un message pour une capacité apprise.*)
26. **XP à la capture** (jeux récents : oui ; Rouge/Bleu : non). (*Non.*)
27. **Évolution** : Salamèche, Bulbizarre et Carapuce évoluent au N16, très loin sur la Route 1. (*Différée : aucune évolution au jalon 5, même si le niveau est atteint ; elle se déclenchera avec la scène du dossier 04 §7.*)
28. **Vampigraine** : Bulbizarre l'apprend au **niveau 7**, après ~5 combats, et le moteur ne l'applique pas (la capacité ne ferait rien). (*La coder en 5C : graine, drain de ⅛ en fin de tour, Plante immunisé.* Autres choix : ne pas l'apprendre tant qu'elle n'est pas codée, ou la laisser sans effet.) Flammèche (Salamèche N9) garde sa brûlure en attente : (*dégâts seuls jusqu'aux statuts.*)
29. **Choix de la capacité à oublier** : inatteignable sur la Route 1 (5e capacité au N20–22). (*Construit et validé au jalon 5 avec un départ de débogage.* Autre choix : le reporter au jalon où il devient atteignable.)
30. **Panneau d'oubli** : (*la nouvelle capacité en haut, les quatre en dessous ; toucher = sélectionner, puis OUBLIER ; NE PAS APPRENDRE ; pas de fenêtre de confirmation.*) Messages proposés : « Salamèche veut apprendre Frénésie, mais connaît déjà quatre capacités. », « Salamèche oublie Griffe et apprend Frénésie ! », « Salamèche n'apprend pas Frénésie. », « Salamèche apprend Flammèche ! ».

**La capture (5D)**
31. **Capture au jalon 5 ou au jalon 6** (phase 6 du plan) ? (*Au jalon 5 (5D), pour boucler la vertical slice « rencontre → combat → capture ».*)
32. **D'où viennent les premières Poké Balls ?** Rouge/Bleu : après le colis de Jadielle. (*Prof. Chen en donne 5 au labo après ses répliques d'après-combat, avec un toast « Poké Ball ×5 — Ajoutée au Sac » ; la réplique est à écrire.* Autres choix : Maman ; un objet à ramasser sur la Route 1 ; l'ordre de Rouge/Bleu, et donc pas de capture avant Jadielle.)
33. **Formule** : (*celle des 3e et 4e générations, 3 secousses visibles, sans capture critique ; taux officiels (Roucool et Rattata 255) : ≈ 1 chance sur 3 à PV pleins, bien plus quand ils sont bas.*)
34. **Surnom** après la capture : (*non, comme pour le starter.*)
35. **« Nouvelle entrée Pokédex »** alors que le joueur n'a pas encore de Pokédex (Rouge/Bleu le donne à Jadielle) : (*affichée et enregistrée, dossier 05 §17 ; le Pokédex est le système de recherche de Chen.*)
36. **Texte exact** : « ROUCOOL CAPTURÉ » (dossier 05 §17) ou « ROUCOOL CAPTURÉ ! » (storyboard) ; accord au féminin (décision n° 15) : « CAPTURÉE », « a été confiée ». (*Storyboard, avec « ! » ; accord au féminin.*)
37. **Sac en combat** : (*seulement la section Balls tant qu'il n'y a pas de soins.*)
38. **Stockage** quand l'équipe est pleine : (*liste en mémoire, invisible jusqu'au menu « Mes Pokémon » (phase 7) ; seul le message le dit.*)

**Ce qui touche d'autres phases**
39. **Sauvegarde** (phase 11) : avec des niveaux et des captures, quitter l'application fait tout perdre. (*Pas au jalon 5 ; `to_dict` est prêt partout.*) Faut-il avancer la sauvegarde juste après le jalon 5 ?
40. **Voir ses PV hors combat** : impossible sans menu Équipe (phase 7) ; la bible interdit un niveau ou des PV permanents. (*Accepté au jalon 5.* Autre choix : un petit panneau Équipe en lecture seule.)
41. **Pokédex, Sac, menu** : (*données seulement (Pokédex vu/capturé, Sac), aucune interface hors combat.*)
42. **Compagnon qui suit** : (*non, décision Q-D ; le partenaire n'apparaît qu'en combat.*)
43. **Jour/nuit, météo** : (*golden hour fixe comme Bourg Palette ; les tables de rencontre pourront recevoir une clé d'heure en phase 10.*)

---

## 9. Dépendances au 4B, et que faire s'il livre autrement

Le 5B à 5D s'appuient sur ce que le plan du 4B **promet** (`jalon-04.md` §2.2, §3.7, §3.8). À vérifier **au début de T4**, dans le code fusionné du 4B :

| Dépendance | Promis par le 4B | Si le 4B livre autrement |
|---|---|---|
| `BattleDirector.run(trainer_id, map, world_actors) -> int`, `battle_started` / `event_played` / `battle_finished`, `speed_scale`, `is_running`, `REASON` | §3.7 | T4 extrait `run_request(request, map)` et fait de `run` une enveloppe (§3.8). Si le directeur construit ses camps en dur, T4 déplace cette construction dans `BattleRequest`. |
| `BattleStage` : `BattleLayout.anchors`, sprites NEAREST ×4 / ×3, `play_move`, `play_hit`, `play_faint`, `hide_all`, zoom, voile | §3.7, §3.12 | Intro sauvage, partenaire, lancer s'ajoutent au `BattleStage` réel. **Si Kevin a choisi une composition « recomposée »** (Q23 du 4, décision n° 10 : fonds peints par lieu), la Route 1 demande **son propre fond de combat** (une ou plusieurs zones) : tâche d'assets à ajouter en T5 et question à Kevin. |
| `BattleHud` : `set_card(side, view)`, `animate_hp`, `set_party`, `show_actions(enabled)`, `show_moves`, `show_message`, `hide_all`, `action_selected` / `move_selected` / `back_requested`, `MoveCard`, `BattleCardView`, `BattleMoveView` | §3.8 | FUITE, XP, oubli, SAC et capture s'ajoutent aux composants réels ; mêmes noms de signaux si possible. |
| Tokens `LAYER_BATTLE_STAGE`, `LAYER_BATTLE_HUD`, `BATTLE_DIM`, `BATTLE_ZOOM`, `HP_TWEEN`, `BATTLE_MESSAGE_HOLD`, `LONG_PRESS`, `HAPTIC_*` | §3.8 | On étend ceux qui existent. |
| `tools/gen_placeholder_battlers.gd` (face/dos, 64 × 64) | §3.12 | T5 y ajoute `pidgey` et `rattata` ; sinon il le crée. |
| `Boot._refresh_controls` qui tient compte du combat | §3.1 | T5 ajoute la rencontre dans la même condition. |
| `Battle`, `BattleText.lines(event, data, trainer)`, `TrainerData.end_message`, `Battle.Outcome` | **livrés** (fondations du 4) | Les ajouts (RUN, FLED, XP, ITEM, CAUGHT) se font **en fin d'enum** pour ne rien décaler. |
| Répliques d'après-combat et soin par Chen (décisions n° 6 et 7 du 4) | §4.2, décisions | Si Q32 = Chen, l'étape `give` se place après sa dernière réplique. |

Si le 4B est fusionné avec d'autres noms ou une autre composition, **on aligne ce plan avant T4** (comme le §13 du jalon 4) et on note les écarts en fin de document. Le 5A, lui, ne dépend pas du 4B (sauf pour être joué après lui dans l'histoire) : il peut être codé dès que le 4A est validé si Kevin préfère avancer la carte pendant que le 4B se règle.

---

## 10. Points d'accroche pour la suite (et ce que le jalon 5 fait des autres phases)

| Sujet | Ce que le jalon 5 en fait | Plus tard |
|---|---|---|
| **Jadielle** | bord nord bloqué (Q5) | warp `PUSH` au bord nord vers `viridian_city`, même mécanique ; le Centre Pokémon remplace `GameState.heal_map` |
| **Centre Pokémon** | point de soin = maison (§3.11) | `heal_map` / `heal_spawn` mis à jour en entrant dans un Centre |
| **Sauvegarde** (phase 11) | rien ; `Bag`, `Pokedex`, `PokemonStorage`, `Party`, `Pokemon` ont `to_dict` | `SaveSystem` sérialise `GameState` ; jamais pendant une scène, une rencontre ou un combat |
| **Pokédex** (phase 7) | vu (5D, à l'envoi) / capturé, sans interface | l'application de Chen (bible §9), dossier 04 §13 |
| **Sac, menu, Équipe** (phase 7) | Sac en combat seulement (Balls) | menu superposé (bible §7) ; changement de Pokémon (`BattleAction.Kind.SWITCH`) |
| **Évolution** | différée (Q27) | `Evolution.level_up_target` après `LEVEL_UP`, scène de 8–12 s |
| **Statuts** | Vampigraine seulement (Q28) | `MoveEffect.Kind.STATUS`, effets visuels (dossier 05 §13), bonus de statut de la capture |
| **Dresseurs sur les routes** | aucun | `BattleRequest` dresseur + ligne de vue (dossier 05 §3 « il te voit → s'approche ») |
| **Indices, Pokémon rares** (dossier 04 §3, §15) | aucun | clés de table (`time`, `weather`, zones de cases) ; herbe qui bouge avant la rencontre |
| **Jour/nuit, météo, sons** (phase 10) | golden hour fixe ; `cry_requested` sans son | teinte ambiante sur `BattleStage` ; cris, musique de combat |
| **Compagnon** | non | jalon dédié ; le partenaire qui « entre dans le cadre » viendrait alors du monde |
| **Autres terrains** | `terrain` = `grass` seulement | `water` (Surf, pêche), `cave` |
| **Animations Complètes / Rapides** | `speed_scale` | option du menu (phase 7) |

---

## 11. Écarts et risques constatés dans le code (2026-09-26, branche `plan-jalon-05` issue de `jalon-04a`)

Constat fait sur le code réel : **949 tests verts** (`tools/test.sh`, 65 scripts), 0 `SCRIPT ERROR`.
1. **Les hautes herbes ne sont pas lues par la grille** : `OverworldTiles.DATA_TALL_GRASS` est posée sur les tuiles depuis le 3B, mais `GameMap._read_layer` l'ignore et `GridWorld` n'a pas de drapeau pour elle (T0).
2. **Aucune tuile de rebord** : `GridWorld.Ledge` et `Grid.LEDGE_JUMP_DURATION` existent, `OverworldTiles` n'a aucun type qui porte `ledge`, et `Player` n'affiche pas de saut (`GridMover.is_jumping()` n'est lu par personne).
3. **Sortie nord de Bourg Palette** : `blocked_cells` (23, 0) et (24, 0), aucun warp ; les deux cases d'arrivée proposées sont aussi des hautes herbes (§3.3).
4. **`BattleText`** : un Pokémon sauvage n'a aucune phrase (`SENT_OUT` adverse et `BATTLE_ENDED` exigent un dresseur) ; `TEMPLATE_IDS` sont tous obligatoires, donc tout nouveau modèle doit arriver **dans le même commit** que `messages.json`.
5. **`Battle`** : `BattleAction.Kind` = { MOVE } ; `Outcome` = { NONE, WIN, LOSS } ; `_check_end` ajoute `BATTLE_ENDED` **juste après** `FAINTED` : l'XP doit s'insérer entre les deux (§2.3). Les ajouts se font en fin d'enum.
6. **Vampigraine inopérante mais atteignable** : Bulbizarre l'apprend au N7 et `pending_effects: ["leech_seed"]` est ignoré par le moteur (Q28). Le test actuel ne vérifie que les capacités **du niveau 5**.
7. **Espèces et capacités** : `kanto.json` ne contient que les 9 starters ; `moves.json` n'a ni Tornade, ni Jet de Sable, ni Vive-Attaque ; `SpeciesData` n'a pas de `catch_rate` (clé refusée par `PokemonData._SPECIES_KEYS` tant qu'elle n'est pas ajoutée).
8. **Aucun Sac, aucun objet, aucun Pokédex, aucun stockage, aucun système de son** (`game/systems/audio/`, `game/ui/bag/`, `game/ui/pokedex/` vides).
9. **`GameState.new_game`** ne remet à zéro que ses quatre champs actuels : chaque ajout du §3.13 doit y entrer (test).
10. **Position des Pokémon de la prairie** : `jalon-03b.md` §3.1 dit (18, 2) et (29, 2), `data/npcs/pallet_town.json` a (20, 3) et (27, 2) (retouche du 3B, documentation non mise à jour). Sans conséquence ; les invariants lisent les données.
11. **Export** : `export_presets.cfg` a `include_filter=""` ; `data/` part dans l'APK aujourd'hui, à reconfirmer pour `data/encounters/` et `data/items/`.
12. **Toujours ouverts** : titre de zone en bandeau (bible §5 : sans rectangle) ; `docs/design/reference/combat-capacites-v1.png.png` à renommer.
13. **Risque de rythme** : 25/256 par pas donne en moyenne une rencontre tous les ~10 pas, soit ~3 s de marche dans l'herbe : fidèle à Rouge/Bleu mais dense sur des herbes A+ plus grandes. À juger en T8 (Q8, Q11).

---

## 15. Alignement du jalon 5 sur le code réel du 4B et le dossier-07 (2026-09-29)

Fait sur la branche `jalon-05` (`main` avec le **4B fusionné et validé**, `08fe0ac`), **au début
de T0**. Comme les §13/§14 du jalon 4, cette section **remplace, pour le jalon 5**, ce qui
diffère dans §2, §3.3, §3.4, §3.8, §3.10 et §9 du présent plan. Deux sources priment sur les
« propositions par défaut » écrites avant la fusion :

- **`docs/design/dossier-07-route-1.md`** (conception de Kevin, 2026-09-26) : il **prime** sur
  l'esquisse par défaut du §3.4 (carte, herbes, rebords, PNJ, secret, sorties) et sur les Q1–Q5,
  Q8, Q21, Q32, Q39. Les répliques y sont **définitives**.
- **Décision de Kevin du 2026-09-29** : les **données** `seen` / `caught` du **Pokédex** commencent
  à être collectées **dès le jalon 5** et doivent entrer dans la **sauvegarde** du jalon 5, pour
  que le jalon 6 ne soit qu'une interface sur des données déjà présentes (jamais rétro-greffées).
  → `Pokedex` posé **en fondation pure dès T0** (§15.7), pas au 5D comme le §2.4 le prévoyait.

Départ mesuré : **1147 tests verts** (le §11 en annonçait 949 depuis `jalon-04a` ; le 4B a
ajouté ses tests).

### 15.1 État réel du 4B (ce que le §9 « promettait » est livré, souvent plus complet)

| Sujet | Dans le code fusionné | Conséquence pour le jalon 5 |
|---|---|---|
| Directeur de combat | `BattleDirector` (`Node`, enfant de `Boot`) : `setup(data, trainers, texts, stage, hud, player, state)`, **`run(trainer_id, map, world_actors) -> int`** (coroutine), `is_running()`, `get_battle()`, `speed_scale`, `REASON = &"battle"` ; signaux `battle_started` / `event_played(event)` / `battle_finished(trainer_id, outcome)`. Construit ses camps **en dur** dans `run` (§14.2). | **`run_request` n'existe pas encore** : T4 l'extrait et déplace la construction des camps dans `BattleRequest` (§15.6). Les signaux sont par dresseur (`trainer_id`) : à généraliser pour un sauvage. |
| Rejeu du journal | `BattlePlayback.beats(event, texts, data, trainer) -> Array[BattleBeat]`, `BattleBeat` (`MESSAGE`/`SEND_OUT`/`MOVE`/`DAMAGE`/`STAT`/`FAINT`), `BattleViews.card/moves/…`, `BattleViews.TRAINER_BATTLE_ACTIONS = { attack: true }`. | Les temps sauvages (`FLED`, `FLEE_FAILED`, XP, capture) s'ajoutent à `BattlePlayback` **en fin** ; une table d'actions « sauvage » (FUITE active, SAC/ÉQUIPE atténués) s'ajoute à `BattleViews`. |
| Vue de combat | `BattleStage` (`CanvasLayer`) : `enter(camera, player_pkmn, foe_pkmn, player_species, foe_species)`, `set_frame(arena, map_rect)`, `show_pokemon(side, species)`, `play_move/play_hit/play_stat/play_faint`, `exit()`, `reset()`, `is_active()` ; **décor recomposé, pas d'écran noir** (décision n° 10). | L'intro sauvage (§3.7) et l'entrée du partenaire s'ajoutent au `BattleStage` réel. **Décision n° 10 confirmée** (fond = la carte recadrée) : la Route 1 sert de fond, **pas besoin d'un fond de combat dédié** (le risque « composition recomposée » du §9 est levé). |
| HUD | `BattleHud` (assemble les composants `game/ui/battle/`), `BattleHud.Side` (enum propre à l'UI). | FUITE/XP/oubli/SAC s'ajoutent aux composants réels (T6, T10, T14). |
| Fin de combat | `BattleConclusion.resolve(trainer, outcome) -> { heal_party, prize_money, blackout }`. | Un combat sauvage n'a pas de dresseur : la défaite et le soin passent par l'`EncounterDirector` et `GameState.heal_map` (§3.11), pas par `BattleConclusion`. |
| **Sac et objets (le §2.4 les croyait à faire au 5D)** | **Déjà livrés** : `Bag` (`add/remove/count_of/has/get_ids/clear/to_dict/load_dict`), `ItemData` (`Category { BALL }`, `catch_bonus`, `name_for/quantity_text/added_text`), `ItemLibrary`, `data/items/items.json` (Poké Ball), **`GameState.bag`** vidé par `new_game`. | Le 5D **n'a plus à créer** Sac ni objets : seuls `CaptureCalc`/`CaptureResult`, `PokemonStorage`, `catch_rate`, `BattleAction.ITEM` et la présentation restent (§15.6). |
| Étape de scène `give` | **Livrée** : `CutsceneStep` `GIVE`, `CutsceneDirector.set_inventory(bag, items)`, `_give`, `signal item_given(item_id, count)` ; **les 5 Poké Balls de Chen sont déjà dans `data/cutscenes/starter.json`** (`{ "give": "poke_ball", "count": 5 }`) avec les répliques **définitives** du dossier-07 §8 (`oak_poke_balls_intro`, `oak_poke_balls`). | **Q32 est tranchée et faite** : le 5D n'a rien à ajouter côté remise ; il branche seulement le **toast** sur `item_given` (Boot). |
| Étape de scène `battle` | **Livrée** : `{ "battle", "player_pokemon", "foe_pokemon", "win", "lose" }`, `if`/`unless` sur toute étape, `CutsceneDirector.set_battle_runner(runner)`. | Modèle réutilisable ; une rencontre sauvage n'est **pas** une scène : l'`EncounterDirector` appelle le directeur directement (§3.6). |
| Moteur | `Battle` (`start`, `submit`, `get_usable_moves`, `get_state`, `get_outcome`, `get_player_side`/`get_foe_side`), `State { READY, CHOOSING, OVER }`, `Outcome { NONE, WIN, LOSS }`, `BattleAction.Kind { MOVE }` + `STRUGGLE = -1`, `_check_end` insère `BATTLE_ENDED` **juste après** `FAINTED`. `BattleText.lines(event, data, trainer)`. | Conforme au §11.5. Tous les ajouts (RUN, FLED, ITEM, CAUGHT, XP) se font **en fin d'enum** ; l'XP s'insère entre `FAINTED` et `BATTLE_ENDED` (§2.3). |
| Grille / monde | `GridWorld.Ledge { NONE, DOWN, LEFT, RIGHT }`, `set_ledge`/`get_ledge`, `can_enter`/`get_step_target` gèrent le saut de rebord (2 cases) ; `Grid.LEDGE_JUMP_DURATION` ; `GridMover.is_jumping()`. `OverworldTiles.DATA_TALL_GRASS` posée sur les tuiles (3B) mais **jamais lue** par la grille avant T0. | T0 lit enfin l'herbe et ajoute la **tuile** de rebord (§15.3). L'**arc de saut du joueur** (T1) reste à faire (`GridMover.is_jumping()` non affiché). |

### 15.2 Écarts plan → code (liste explicite)

1. **`BattleDirector.run_request` n'existe pas** ; il y a `run(trainer_id, map, world_actors)`.
   → T4 : extraire `run_request(request: BattleRequest, map) -> int` et faire de `run` une
   enveloppe (§15.6). Les signaux `battle_started(trainer_id)` / `battle_finished(trainer_id,
   outcome)` prennent une clé (dresseur ou `&""` pour un sauvage) ou gagnent une variante.
2. **Sac, objets, étape `give`, `GameState.bag` : déjà là** (§2.4 les plaçait au 5D). Le 5D est
   allégé d'autant ; **Q32 est faite** (Chen donne 5 Balls, textes définitifs intégrés).
3. **`Pokedex` avancé du 5D à T0** (décision du 2026-09-29). `PokemonStorage`, `CaptureCalc`,
   `catch_rate` restent au 5D. `GameState.pokedex` est ajouté maintenant (§15.7).
4. **`GameMap._read_layer` ne lisait pas `tall_grass`** → corrigé en T0 (§15.3).
5. **`OverworldTiles` n'avait aucun type de rebord** → `Kind.LEDGE_DOWN` ajouté en T0 (le §3.4 et
   le §5 le plaçaient en T1) : c'est une **donnée pure testable**, prérequis de la carte.
6. **La carte par défaut du §3.4 (48 × 72, esquisse) est remplacée** par le dossier-07 (§15.4) :
   « **A+ compacte** » (trajet direct 2–3 min, exploration 8–12 min), chemin **qui serpente**,
   **3 zones d'herbes** dont **une bande courte obligatoire**, un **secret** (Potion) dans la
   zone d'exploration, **un seul PNJ** (le Voyageur, avec routine de marche), rebords vers le sud,
   **connexion Jadielle qui fonctionne** (placeholder « JADIELLE — À venir » en build de dev).
7. **La Potion cachée du dossier-07 §6 demande la catégorie d'objet `heal`** : `ItemData.Category`
   ne connaît que `BALL`. → à ajouter (donnée + un objet `potion`) quand la Potion est posée (5A/5B
   selon l'ordre), avec un **toast** ; l'usage de la Potion (soin) n'est **pas** requis au jalon 5
   (hors périmètre, §Hors périmètre) : elle est seulement **ramassée et rangée**. **Question Q-A.**
8. **La défaite** (§3.11) est confirmée par le dossier-07 §11 avec **textes définitifs** : Maman
   soigne, première fois « Tu m'as fait une de ces peurs… » / « Tes Pokémon vont bien. Repose-toi
   un peu avant de repartir. » ; ensuite « Tes Pokémon vont bien maintenant. » / « Fais attention
   à toi, d'accord ? ». → à mettre dans `data/dialogues/` et à câbler en T7 ; plus de « sans
   réplique par défaut ».
9. **Sauvegarde (Q39) tranchée** : le dossier-07 §13 la rend **obligatoire avant la validation du
   jalon 5**, idéalement **avant la capture finale**. Le §Hors périmètre disait « phase 11 ». →
   une tâche **sauvegarde** s'insère **entre le 5C et le 5D** (autosave : événement, capture,
   changement de zone, soin). Contenu minimal : dossier-07 §13. **Question Q-B** (mécanisme).

### 15.3 T0 — fondations réellement posées (cette tâche)

Classes pures et données de tuiles, aucune dépendance à l'arbre de scènes ni à un autoload,
toutes testées. Cela **remplace/complète le §2.1** :

- `GridWorld` : drapeau **hautes herbes** — `set_tall_grass(cell, tall := true)`,
  `is_tall_grass(cell)`, bit `_FLAG_TALL_GRASS = 16` (au-dessus du rebord, bits 2–3). N'entre dans
  **aucune** règle de déplacement (`can_enter`, `get_step_target`, `is_free` l'ignorent) : une case
  peut être **à la fois solide et en herbe** (le bord nord bloqué de Bourg Palette).
- `GameMap._read_layer` lit enfin `OverworldTiles.DATA_TALL_GRASS` → `_grid.set_tall_grass`.
- `NpcSpec` / `NpcRoster` : clé facultative **`shy`** = `{ "action": "fly" | "flee",
  "radius": 1..4 }` → `NpcSpec.shy_action: StringName` (`&""` = aucune, `SHY_ACTIONS = [&"fly",
  &"flee"]`), `shy_radius: int` (défaut 2, `SHY_RADIUS_DEFAULT`), `is_shy()`. **Refusée sur un PNJ
  interactif** (dialogue renseigné). Validation stricte (clé inconnue dans `shy`, action hors liste,
  rayon hors 1..4).
- `AmbientRules` (`game/world/npc/ambient_rules.gd`, statique) : `is_within(npc, player, radius)`
  (Manhattan) ; `flee_path(grid, from, away_from, max_steps, mover) -> Array[Vector2i]` (directions
  qui **augmentent** la distance, cases `is_free`, ordre haut-bas-gauche-droite, reproductible ;
  vide si acculé, jamais à travers le joueur).
- `OverworldTiles.Kind.LEDGE_DOWN` (**fin d'enum**, rangée 12) + `VARIANTS = 2`, `LEDGE_KINDS`,
  `ledge_of(kind)`, `is_ledge_kind`. Praticable (non solide), donnée `ledge = DOWN`. Atlas et
  `overworld.tres` **régénérés** (`gen_placeholder_tiles.gd`, tuile provisoire « talus + chevrons »)
  sans déplacer les rangées existantes. L'**arc de saut** du joueur reste à T1.
- `Pokedex` + `GameState.pokedex` (§15.7).

Tests : `test_grid_world` (herbes indépendantes du solide/eau/rebord, hors carte),
`test_pallet_town` (grille : `is_tall_grass` vrai exactement sur (23..24, 0..2), y compris les deux
cases bloquées), `test_npc_roster` (shy : défauts, valeurs, bornes, clé inconnue, refus sur PNJ
interactif), `test_ambient_rules` (rayon, fuite, coin, blocage, rebord, reproductibilité, grille
nulle), `test_overworld_tileset` (LEDGE_DOWN en fin, données ledge=bas, non solide ; autres types
sans ledge), `test_pokedex`, `test_game_state` (Pokédex vidé par `new_game`).

**Non fait volontairement** (5A et suivants, avec `constructeur-monde` / `ui-mobile` / `qa-mobile`) :
la carte `route_1.tscn` et son tracé, l'arc de saut, le sprite « jambes dans l'herbe »,
`AmbientWatcher`, les rencontres, l'XP visible, la capture.

### 15.4 La carte de la Route 1 (5A) — le dossier-07 remplace l'esquisse du §3.4

**L'esquisse « 48 × 72 » du §3.4 n'est plus la référence.** Le tracé et les cases restent le
**5A avec `constructeur-monde`**, sur la base du dossier-07 (Kevin), pas de l'architecte. Ce que le
dossier **verrouille** (à respecter par T1) :

- **Taille A+ compacte** : trajet direct **2–3 min**, exploration attentive **8–12 min**. Chemin
  **qui serpente** (pas de ligne droite verticale). Transition sud (entretenu, clôtures, fleurs) →
  centre (nature, petit relief, arbres) → nord (traces humaines vers Jadielle).
- **Trois zones de hautes herbes** : **Zone 1** initiation, **petite et contournable** ; **Zone 2**
  exploration, plusieurs passages, **un recoin qui cache la Potion** ; **Zone 3** vers la moitié /
  deuxième moitié, **bande courte impossible à contourner** (quelques cases).
- **Rebords franchissables uniquement vers le sud** (`LEDGE_DOWN`), saut animé + ombre +
  atterrissage + retour haptique ; le level design doit faire lire « je descends par là, pas
  l'inverse ».
- **Un seul PNJ, le Voyageur** (répliques **définitives**, dossier-07 §5), qui **marche** dans une
  petite zone près du chemin (**jamais** dans les herbes, **ne bloque jamais** le passage, **ne sort
  pas** de sa zone ; s'arrête et se tourne vers le joueur quand on lui parle, puis reprend). C'est la
  **première application** de la règle « un PNJ a une petite activité/routine locale » (pas
  d'horaires). → demande un **PNJ à routine de marche** : `Npc` sait déjà marcher (3B) ; il manque
  une petite routine « aller-retour dans une zone » à concevoir en T2. **Question Q-C** (portée de la
  routine : liste de cases ? rectangle ? pauses ?).
- **Premier secret** : objet caché **sans scintillement** près d'un arbre/souche → **Potion ×1** +
  toast (§15.2 point 7). Examen : « *Quelque chose est coincé entre les racines.* » (définitif).
- **Aucun Dresseur** (dossier-07 §7).
- **Jadielle** : l'entrée doit **déjà fonctionner** ; si la ville n'existe pas au premier build,
  placeholder **« JADIELLE — À venir » uniquement en build de développement** (dossier-07 §12). Ceci
  **tranche Q5** (l'ancien défaut « bord bloqué, rien de visible » ne s'applique plus).
- Assets **provisoires** aux dimensions finales ; ne pas surcharger graphiquement (dossier-07,
  consigne de production).

`data/npcs/route_1.json` : le Voyageur (une entrée interactive, avec routine) + les Pokémon
d'ambiance `shy` (Roucool `fly`, Rattata `flee`, dossier-07 §4).

### 15.5 Raccord Bourg Palette ↔ Route 1 sur la géométrie réelle (5A, §3.3)

Géométrie **réelle** de `tools/build_pallet_town.gd` (vérifiée) :
- chemin `DIRT [23, 0 → 24, 11]` qui file vers le bord **nord** ; **hautes herbes**
  `TALL_GRASS [23, 0 → 24, 2]` (les 3 dernières rangées du chemin) ;
- **(23, 0) et (24, 0) bloquées** (`BLOCKED_CELLS`) : le joueur s'arrête en y 1, tête à l'écran ;
- **aucun warp** au nord aujourd'hui ; déclencheur `Route1Grass` en **(23, 3) / (24, 3)** (cutscene
  `route1_grass`, sans effet après `starter_chosen`).

Donc **la sortie Route 1 est bien le bord nord, chemin en x 23–24** : le §3.3 s'applique tel quel
(warps `PUSH` vers le haut en (23, 1)/(24, 1), spawns `from_route_1_*`, y 0 restant bloquée). Les
deux cases d'arrivée sont des **hautes herbes**, donc T1 doit garantir l'invariant du §4 : « jamais
une case d'herbe **à rencontres** sous un warp `STEP_ON` ni sous un déclencheur » (ici c'est un warp
`PUSH`, autorisé ; une apparition ne fait aucun tirage). La largeur d'alignement (x 23–24) est
imposée par Bourg Palette ; la **largeur totale de la Route 1** est libre (dossier-07, à T1).

### 15.6 Le combat sauvage réutilise le `BattleDirector` réel (T4 → T7 ; 5D)

- **T4** extrait **`run_request(request: BattleRequest, map) -> int`** du `run` actuel et fait de
  `run(trainer_id, map, world_actors)` une **enveloppe** (construit un `BattleRequest` dresseur puis
  appelle `run_request`) : le combat du rival **ne change pas**. La construction des camps (§14.2 :
  `BattleSide`, `trainers.build_team`, `Battle.new(..., rng)`) se déplace dans `BattleRequest`
  (dresseur) / `BattleRequest.wild(...)` (sauvage, `PokemonFactory.create`).
- **`Battle`** reçoit `rules: BattleRules` optionnel (null = comportement du 4B) ; `BattleAction`
  gagne `RUN` puis `ITEM` (fin d'enum) ; `BattleEvent.Kind` gagne `FLED`, `FLEE_FAILED`, puis les
  temps XP et capture (fin d'enum) ; `Outcome` gagne `FLED` puis `CAUGHT` (fin d'enum).
- **Défaite sauvage** : pas de `BattleConclusion` (pas de dresseur) ; l'`EncounterDirector` fait
  `state.party.heal_all()` puis `router.change_map(GameState.heal_map, heal_spawn, UP)` (§3.11), avec
  la réplique de Maman (dossier-07 §11).
- **5D** : `Bag`/`ItemData`/`ItemLibrary`/`give` **existent** ; il reste `CaptureCalc`,
  `CaptureResult`, `PokemonStorage`, la clé `catch_rate` (14 espèces), `BattleAction.ITEM` + les
  temps `BALL_THROWN`/`BALL_SHAKE`/`CAUGHT`/`BROKE_FREE`, le **toast** sur `item_given`, et la
  présentation (§3.10, §3.12).

### 15.7 Le Pokédex dès le jalon 5 (décision du 2026-09-29)

`Pokedex` (`game/pokemon/pokedex.gd`, `RefCounted`, pur) : `mark_seen(species) -> bool`,
`mark_caught(species) -> bool` (**implique** `mark_seen` ; `caught ⊆ seen` invariant), `is_seen`,
`is_caught`, `seen_count`/`caught_count`, `seen_ids`/`caught_ids` (triés), `clear`, `to_dict` /
`from_dict`. `GameState.pokedex`, vidé par `new_game()`. **Aucune interface** (l'écran est au
jalon 6).

**Points de marquage** (implémentés dans leurs tâches, pas en T0) :
- **`seen`** quand un Pokémon **adverse** entre en combat — temps `SENT_OUT` côté `FOE` — donc **dès
  le 5B** (le §3.8 disait « dès le 5D » : à avancer au 5B puisque les données existent maintenant).
- **`caught`** à la capture réussie (**5D**), avant `Party.add` / `PokemonStorage.add`.
- **Sauvegarde** : `pokedex.to_dict()` **doit** être sérialisé par la tâche sauvegarde (entre 5C et
  5D, §15.2 point 9).

**Non tranché — question Q-D pour Kevin** : faut-il marquer **rétroactivement** le **starter** du
joueur et le **Pokémon du rival** du 4B ? *Proposition* : starter du joueur = **`caught`** dès son
entrée dans l'équipe (au choix du starter, 4A) ; Pokémon du rival = **rien** (combat narratif, on ne
« voit » pas encore le système Pokédex, et Rouge/Bleu ne l'inscrit pas). À confirmer.

### 15.8 Questions ouvertes pour Kevin (nouvelles, issues de cet alignement)

- **Q-A** — La **Potion** cachée (dossier-07 §6) : au jalon 5 elle est seulement **ramassée +
  rangée + toast** (la catégorie `heal` et un objet `potion` s'ajoutent aux données) ; **l'usage**
  (soigner hors/en combat) reste hors périmètre. OK, ou veux-tu la Potion utilisable dès le jalon 5 ?
  → **Décision Kevin (2026-09-29)** : ramassée seulement (défaut) ; l'usage viendra avec le Sac au J6.
- **Q-B** — **Sauvegarde** (dossier-07 §13, obligatoire avant validation du jalon 5, avant la
  capture finale) : mécanisme (autoload `SaveSystem` sérialisant `GameState`, un seul emplacement,
  autosave sur événement/capture/zone/soin) ? Contenu minimal = dossier-07 §13.
- **Q-C** — **Routine de marche** du Voyageur (première application de la règle « PNJ avec une
  petite activité ») : forme des données (liste de cases à parcourir en boucle ? rectangle + marche
  aléatoire ? durée des pauses ?). Contraintes déjà fixées : jamais dans les herbes, ne bloque jamais
  le passage, ne sort pas de sa zone.
- **Q-D** — Marquage **rétroactif** du starter (proposé `caught`) et du Pokémon du rival (proposé
  rien) au Pokédex (§15.7).
  → **Décision Kevin (2026-09-29)** : starter du joueur = **`caught`** (à l'entrée dans l'équipe, 4A) ;
  Pokémon du rival = **`seen`** (il est affronté au labo). Câblage dans la tâche Pokédex du J5.
- **La carte elle-même** (tracé exact, cases des 3 zones d'herbes, position de la bande obligatoire,
  du secret, de la zone du Voyageur, largeur totale) reste à produire en **5A avec
  `constructeur-monde`** d'après le dossier-07 ; ce n'est **pas** à l'architecte de la dessiner.
  → **Décision Kevin (2026-09-29)** : le 5A construit la carte **directement d'après le dossier-07**,
  jugement au doigt sur S24 ensuite. Q-B (sauvegarde) et Q-C (routine du Voyageur) : valeurs par
  défaut appliquées, ajustables ; à confirmer sur S24.

### 15.9 T4 — fondations pures du 5B réellement posées (2026-09-30)

Fait sur la branche `jalon-05`, **au début de T4** (départ mesuré : 1210 tests verts). Cette
sous-section précise, sur le code réel du 4B, comment un combat **sauvage** réutilise le moteur du
rival **sans le casser**, et liste les extensions faites. Elle complète §15.6 (qui décrivait le
plan) : ici, ce qui est **réellement posé** en fondation pure (`RefCounted` + tests ; aucun nœud,
aucun autoload). Ce qui reste (nœud `EncounterDirector`, `run_request`, transition, UI, capture)
est **hors T4** (T5→T7, 5D).

**Comment un combat sauvage réutilise `Battle`/`BattleDirector`.** Un sauvage est un `BattleSide`
**sans dresseur** : `BattleSide.new(foe_party, false, "")` (nom vide = sauvage, déjà géré par
`BattleSide` et par `BattleText`). Le camp adverse a une seule équipe d'un Pokémon (le tiré),
l'IA `random` posée d'office par `Battle._init`, et le combat reçoit des **règles**
(`BattleRules.for_wild()`). La conclusion ne passe **pas** par `BattleConclusion` (pas de
dresseur) : pas de soin en victoire sauvage (les PV/PP restent) ; la défaite (retour au point de
soin) est le rôle de l'`EncounterDirector` en T7 (`GameState.heal_map`). Le `run_request(request,
map)` qui enveloppe `run(trainer_id, …)` est **conçu ici** (`BattleRequest`) mais **implémenté en
T7** ; `run` du 4B reste inchangé.

**Extensions exactes du moteur (toutes en fin d'enum, le combat du rival ne bouge pas)** :
- `BattleAction.Kind` : `{ MOVE, RUN }` (RUN ajouté) ; `BattleAction.run()`. RUN n'est légal que
  si `rules.can_flee` ; sinon `submit` refuse (comportement du 4 : règles nulles → pas de fuite).
- `BattleEvent.Kind` : `… , BATTLE_ENDED, FLED, FLEE_FAILED` (deux ajoutés en fin).
- `Battle.Outcome` : `{ NONE, WIN, LOSS, FLED }` (FLED ajouté en fin).
- `Battle._init(player, foe, data, rng, rules: BattleRules = null)` : `rules` **optionnel**, null =
  comportement du 4B. `get_rules()`, `can_flee()`. La fuite est **jouée avant les capacités** : sur
  `submit(run())`, réussite → `FLED` puis `BATTLE_ENDED(FLED)` (l'adversaire ne joue pas) ; échec →
  `FLEE_FAILED` puis l'adversaire joue son tour. Ordre des tirages documenté : `FleeCalc` (un
  `roll(256)`, seulement si la fuite n'est pas déjà assurée), puis, en cas d'échec, l'IA adverse et
  l'exécution de son action.
- `BattleText` : trois modèles obligatoires ajoutés à `TEMPLATE_IDS` **dans le même commit** que
  `messages.json` — `wild_appeared` (`SENT_OUT` côté FOE **sans dresseur**, avec `text_f`), `fled`,
  `flee_failed`. `BATTLE_ENDED` n'émet plus de phrase que pour `WIN`/`LOSS` (jamais `FLED` ; un
  sauvage, sans dresseur, n'a de toute façon pas de « Tu as battu… »).

**Classes de données neuves** : `BattleRules` (`for_wild` : fuite oui, XP ×1, Balls oui ;
`for_trainer` : fuite non, XP ×1,5, Balls non) ; `BattleRequest` (`Intro { TRAINER, WILD }`,
`wild(encounter, data, rng, cell)` **implémenté** — le sauvage est créé par `PokemonFactory.create` ;
`trainer_battle(trainer, foe_party, actors)` pour T7) ; `FleeCalc` (formule des 3e/4e générations,
Vitesses **sans** niveaux de stats). Rencontres : `EncounterSlot`, `WildEncounter`, `EncounterTable`
(`roll`/`pick`/`total_weight`/`chance_of`, ordre des tirages `roll(256)≤rate`, `roll(poids)`,
`range_int`), `EncounterLibrary` (validation stricte comme `ItemLibrary` : espèces contre
`PokemonData`, poids > 0, niveaux 1..100 `min ≤ max`, `rate` 1..255, au plus une table par couple
(carte, terrain), JSON illisible avec la ligne).

**Données** : `data/encounters/route_1.json` (table `route_1_grass` : `maps` `["route_1",
"pallet_town"]`, `rate` 25/256, 10 emplacements → Roucool 50 % Nv.2–5, Rattata 50 % Nv.2–4) ; cinq
espèces ajoutées à `data/pokemon/species/kanto.json` (Roucool 16, Roucoups 17, Roucarnage 18,
Rattata 19, Rattatac 20 ; **lignées complètes**, valeurs modernes, learnsets Rouge/Bleu) et dix
capacités à `moves.json` (Tornade `flying`/40, Jet de Sable `ground` acc −1 **codée**, Vive-Attaque
priorité +1 **codée** ; Cyclone, Cru-Ailes, Hâte, Mimique, Croc de Mort, Puissance, Croc Fatal —
celles non codées portent `pending_effects`). **Invariant vérifié** (`test_pokemon_data`,
`test_battle_simulation`) : aux niveaux des rencontres (Roucool 2–5, Rattata 2–4), toute capacité
connue est **sans** `pending_effects`.

**Marquage Pokédex (item 5, logique pure ; câblage T5/T7)** : `Pokedex` existe depuis T0. Le point de
marquage « vu » est l'événement **`SENT_OUT` côté FOE** d'un sauvage — c'est justement celui qui
produit maintenant `wild_appeared`. En T5/T7, l'`EncounterDirector` (ou le `BattleDirector`) appelle
`state.pokedex.mark_seen(species)` sur cet événement ; aucun marquage n'est fait par le **moteur**
(il reste pur et reproductible). Voir §15.7 pour `seen`/`caught` et la sauvegarde.

**Non fait en T4 (T5→T7, 5D)** : `EncounterDirector` (nœud), `run_request`, transition ~1 s
(`BattleStage.play_wild_intro`/`play_partner_enter`), UI (FUITE active, carte sans pastilles), défaite
et soin (clé `heal` de dialogue, variante de Maman), et tout le 5D (capture). La clé de dialogue
`"heal"` (§2.2) et le câblage `GameState`/`Boot` restent à T7 : ce ne sont pas des fondations du
moteur de combat.

## 16. Sauvegarde (5C.5) — exigences (décision de Kevin du 2026-10-02)

La sauvegarde s'insère **entre le 5C et le 5D** (§15.2 point 9, Q-B). Son contenu minimal reste celui
du **dossier-07 §13**. Kevin y ajoute les **faits dont le J6 aura besoin**
(`docs/design/dossier-08-menu-dresseur.md` §9), selon la règle « données avant interface » de la
roadmap. **On stocke les faits nécessaires ; on ne construit aucun écran ni système d'interface du
J6, et on évite le sur-engineering** : pas de champ « au cas où » au-delà de cette liste.

### 16.1 Principes

- **Un seul emplacement**, **autosave permanent**, impossible à désactiver. Pas de bouton
  « Sauvegarder » au J5 (« Sauvegarder maintenant » arrive avec les Paramètres du J6).
- **Moments d'autosave** : fin d'un événement narratif, capture, changement de carte, soin, fin de
  combat, et **passage de l'application en arrière-plan** (Android). Jamais pendant une scène, une
  rencontre ou un combat : on sauvegarde l'état stable d'avant ou d'après. Le joueur ne doit jamais
  avoir peur de fermer l'application.
- **Écriture atomique** : fichier temporaire, puis remplacement. Une coupure en pleine écriture ne doit
  jamais corrompre la sauvegarde existante.
- **Format versionné** : un numéro de version à la racine. Charger une version plus ancienne remplit
  les champs absents avec leur valeur par défaut (et migre si un champ change de forme) ; un champ
  manquant ou inconnu ne fait jamais planter le chargement.
- **Validée seule sur le S24** (système à risque, `CLAUDE.md` règle 1).

### 16.2 Contenu de base (dossier-07 §13)

Position et carte du joueur, orientation ; starter ; équipe (`Pokemon.to_dict`, PV, statuts, XP,
capacités) ; Sac (`Bag.to_dict`) ; Pokédex ; drapeaux d'histoire (`StoryFlags` : événements terminés,
dialogues importants, objets ramassés comme `got_potion_route_1`) ; point de soin
(`GameState.heal_map`) ; état de l'aléatoire (`GameRng`) si nécessaire à la reproductibilité.

### 16.3 Faits supplémentaires pour le J6

Les lieux sont enregistrés par **identifiant de carte** (le J6 en déduit la zone : un intérieur
appartient à sa ville). Les dates sont la **date réelle de l'appareil** (format ISO), pas une heure de
jeu.

| Fait | Contenu | Enregistré quand |
|---|---|---|
| **Pokédex, par espèce** | vu, capturé ; première observation (carte, date) ; première capture (carte, date) ; cartes où l'espèce a été vue ; nombre de fois vue ; nombre de fois capturée | à chaque `mark_seen` / `mark_caught` |
| **Rencontre de chaque Pokémon** | carte, niveau, date, dresseur d'origine, manière (starter, capture) | à l'entrée dans l'équipe ; **le starter aussi** (labo de Chen, niveau du choix, date du choix) |
| **Temps de jeu** | secondes, comptées seulement quand le jeu est au premier plan | en continu |
| **Début de l'aventure** | date | nouvelle partie |
| **Zones découvertes** | carte, date de première visite | première arrivée sur une carte |
| **Objets trouvés dans le monde** | objet, carte, date | ramassage (ex. la Potion de la Route 1) |
| **Grands moments** | liste chronologique, ajout seulement : type, date, carte, détails | au J5 : premier Pokémon (starter), combat contre le rival (issue), première capture |
| **Nom du joueur** | « Kevin » par défaut (pas encore d'écran de nom) | nouvelle partie |

**Pas stocké** : les évolutions découvertes (elles se déduisent des espèces vues et des évolutions du
joueur) ; les notes d'Observations du Pokédex (ajoutées au J6, le format versionné le permet) ;
l'argent (J7) ; les badges (J10) ; les statistiques détaillées.

### 16.4 Tâches (entre T12 et T13)

- **S1 — architecte-godot** : format versionné et système de sauvegarde en logique pure (lecture,
  écriture atomique, migration), nouveaux faits dans `GameState` / `Pokedex` / `Pokemon`. Tests :
  aller-retour complet, chargement d'une version plus ancienne, champ manquant, fichier corrompu.
- **S2 — constructeur-monde** : autosave branché sur les moments du §16.1 (dont l'arrière-plan
  Android), enregistrement des faits au bon endroit, chargement au démarrage (`Boot`), starter
  rétroactif.
- **S3 — qa-mobile** : validation seule sur le S24 : fermer l'application ou la tuer à différents
  moments (exploration, juste après une capture, pendant un combat, pendant une écriture), relancer,
  vérifier que rien n'est perdu ni corrompu.
