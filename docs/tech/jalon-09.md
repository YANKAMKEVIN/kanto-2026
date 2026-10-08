# Jalon 9 — Forêt de Jade

> Objectif jouable sur le S24 : **la première vraie petite expédition**. Depuis la Route 2 sud, le poste de garde (un garde qui prévient du poison), la forêt dense en grand S (≈ 58 × 74 cases), cinq espèces nouvelles dont Pikachu rare, **les premiers vrais Dresseurs** (le Scout Théo voit le joueur, « ! », s'approche, parle, combat), **le poison** (persistant, aucun dégât en marchant, Antidote ou Centre), **les premières évolutions** (séquence propre, annulable, définitive dans sa logique), six objets dont trois cachés, deux PNJ, des Pokémon d'ambiance, puis le poste nord et « ROUTE 2 NORD — À venir ».
>
> Deux tranches, à la demande de Kevin (2026-10-06) : **A — les systèmes**, codés **tout de suite, en parallèle du J8**, sans la carte et sans toucher aux fichiers que le J8 modifie, validés sur S24 grâce à une **carte de QA** ; **B — la forêt**, après la fusion du J8 (même méthode que le 8.0 : grille → plan en aplats → vue générale Codex validée par Kevin → assets → vraie carte).

**Pré-requis.** Dossier 10 et ses textes **validés tels quels** par Kevin (2026-10-06) : c'est la **source de vérité**. Rien de la tranche B ne démarre avant la fusion de `jalon-08` dans `main` (porte du poste, objets visibles, Randonneuse, forêt serrée éventuellement étendue). Ce plan est écrit sur `jalon-09` à `4107a05` (= `main`, DA.0 et DA.1 fusionnés) ; le plan du J8 est lu sur `docs/dossier-11-route-2` à `e9989c6`. **Chaque tâche d'architecture commence par aligner ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/dossier-10-foret-de-jade.md` (11 arbitrages, §1 à §17, « Textes validés »), `dossier-04-systeme-pokemon.md` §7 (évolution 8–12 s), `dossier-05-combat.md` §13 (statut visible), §19 (IA débutante), §23 (défaite), `dossier-06-progression.md`, `dossier-08-menu-dresseur.md` §2 (statut en texte : « PSN »), `dossier-09-jadielle.md` §7 (point de repos), §9–10 (Boutique, prix, pas de perte d'argent), `roadmap.md` phase 5 et J11 (présentation enrichie des évolutions et statuts complets **au J11, pas ici**), `jalon-07.md`, plan du J8 (`jalon-08.md`, §2.2, §2.3, §2.4, §2.12, T9).

---

## 0. État des lieux (code réel à `4107a05`) et écarts

### 0.1 Ce qui existe pour chaque besoin du dossier

| Besoin (dossier 10) | Existant | Manque |
|---|---|---|
| Statut Poison | **rien** : aucun champ de statut sur `Pokemon` ni `Battler` ; `MoveData.pending_effects` décrit `poison` (Poudre Toxik) et `poison_30` (Dard-Venin) **sans les jouer** ; `CaptureCalc` accepte déjà un `status_bonus` (1,0 partout) ; vues `TeamMemberView.status_text` (« K.O. » seulement), libellés de statut dans `LeadPokemonCard`, `PokemonShowcase`, `PartyTargetCard`, `BattlePartyCard` | champ persistant, règles, effet de capacité, fin de tour, événements, messages, affichage « PSN », Antidote (§2.1) |
| Sauvegarde | `SaveSystem.VERSION = 3`, migrations `upgrade`, règle « un champ nouveau = une version » (doc de `VERSION`) ; drapeaux d'histoire (tableau), `found_items`, `discovered_maps` | v4 pour le statut des Pokémon (§2.2) |
| Antidote, Boutique | `ItemData` (catégorie HEAL, `heal_amount` > 0 obligatoire), `ItemUse` (une règle pour le Sac et le combat), `BagQuery.REASONS` / `REFUSAL_FORMATS` (« Sans effet », « Cela n'aurait aucun effet sur %s. » déjà validés) ; **stock conditionnel déjà prévu** (`ShopData.stock` : `if` / `unless` par objet) | objet `antidote`, clé `cures`, contrôle « sans effet », entrée de stock `if poison_unlocked` (§2.1.5) |
| Soin au Centre / chez Maman / après défaite | `Party.heal_all` → `Pokemon.heal_full` (PV, PP) | `heal_full` efface aussi le statut (1 ligne) |
| Évolution | `Evolution.level_up_target` / `item_target` (purs, testés), `EvolutionRule` (level / item / trade), `Pokemon.evolve_into` (stats recalculées, PV perdus gardés) ; **rien ne les appelle** ; Pokédex : `EvolutionReveal` (chaîne « ??? » qui se révèle quand l'espèce est vue) | déclenchement après combat, séquence à l'écran avec annulation, capacités apprises à l'évolution, Pokédex (§2.3) |
| Apprendre une capacité | `Pokemon.learn_move` / `replace_move` ; `MoveForgetPanel` (scène autonome) piloté par `BattleDirector._offer_forget` / `_confirm_forget` (combat seulement) | le même déroulé hors du journal de combat (§2.3.4) |
| Dresseurs | `TrainerData` / `TrainerLibrary` (`data/trainers/*.json`, `prize_money` fixe **ou** `prize_per_level`, `start_message`, `end_message`, `ai`), `BattleConclusion` (argent versé, jamais retiré), étape de scène `battle` (drapeaux `win` / `lose`), `wake_up` (défaite → point de repos), alias `$nom`, conditions d'étape `if` / `unless` ; le rival n° 2 est **une scène écrite à la main** déclenchée par un `EventTriggerPoint` | champ de vision, « ! », approche, défi à la parole, mémoire « battu », données des 5 Dresseurs (§2.4) |
| « ! » | `Npc.react()` (animation « react » ou petit bond) ; étape `react` | une bulle « ! » (étape `emote`, §2.4.4) |
| Ordre des réactions à un pas | `Player.moved` écouté par `CutsceneDirector` (déclencheurs), `AmbientWatcher`, `EncounterDirector` (verrou synchrone dans le signal) ; connexions dans `Boot._ready` (l. 163 → 210) | `TrainerWatcher` branché **entre** les scènes et les rencontres (§2.4.6) |
| Espèces | 24 espèces (`data/pokemon/species/kanto.json` : starters, Roucool, Rattata, Piafabec, Nidoran ♀ ♂, Férosinge et leurs évolutions) ; stats **actuelles**, apprentissages **de Rouge/Bleu** ; un test exige une entrée Pokédex par espèce (`test_pokedex_library`) ; artworks officiels **001–151 déjà là** (`assets/sprites/pokemon/official/`, atlas) ; sprites de combat provisoires `placeholder/<espèce>_front/_back.png` (`tools/gen_placeholder_battlers.gd`) | Chenipan, Chrysacier, Papilusion, Aspicot, Coconfort, Dardargnan, Pikachu, Raichu ; 12 capacités (§2.5) |
| Rencontres | `EncounterLibrary` (une table peut couvrir plusieurs cartes : `maps`), `rate` 25 + `ramp` 15 → 20 (Route 1) | `data/encounters/viridian_forest.json` |
| Postes de garde | intérieurs peints générés par **une fonction par pièce** dans `tools/build_painted_interiors.gd` (enveloppe + meubles `WorldProp` + cases bloquées) ; `MapCatalog` : **un identifiant de carte = une scène** | une définition paramétrée `_forest_gate(side)` → deux scènes (§2.7.2) |
| Forêt serrée | **dans `game/` depuis le DA.0** : `DenseForest` (plan à graine fixe, arbres cuits dans la scène), `ForestFloor` (sous-bois, masque intégré) ; Route 1 peinte : 617 arbres, 58,8 fps sur S24 | une carte ≈ 3 à 4 fois plus boisée (§2.7.4, §5) |
| Objets cachés | Potion de la Route 1 : `EventTriggerPoint` → scène (`dialogue` narration, `give … found: true` → journal + toast standard, `set`) | données seulement |
| Objets visibles | **J8, T4** : `Interaction.Kind.TAKE`, verbe `take` dans `NpcRoster`, préfixe `object/` de `CharacterLook`, Poké Ball au sol | rien (réutilisé après la fusion du J8) |
| Pokémon d'ambiance | `shy` `fly` / `flee` (`AmbientWatcher`), `look`, `idle_react` ; peints : Roucool, Rattata, Nidoran, Piafabec, Férosinge | Chenipan qui « relève la tête », Aspicot qui « se rétracte » (§2.7.6) ; Chenipan, Aspicot, Chrysacier, Coconfort peints |
| Départs de QA | `tools/debug_start/*.json` + `DebugStart` (`party` avec `hp`, `exp_to_next`, `moves`, `flags`, `bag`, `money`, `storage`) | `status` d'un membre ; carte de QA (§2.6) |
| Objectif | `ObjectiveLibrary` ; le J8 ajoute « continuer vers le nord. » (si `pokedex_activated`) | rien : l'objectif reste vrai jusqu'à Argenta (défaut) |
| Zone | `zones.json` : `viridian_forest` **existe sans carte** | `maps`, `subtitle`, `description` (textes, Q-1) |

### 0.2 Écarts constatés

1. **Aucun statut n'existe** : le poison est un vrai système (logique, combat, sauvegarde, Sac, menus), pas une donnée. Le J11 généralisera ; ici, un modèle qui n'oblige pas à tout refaire (statut = identifiant sur `Pokemon`, règles dans une classe pure, événements génériques `STATUS_*`).
2. **Le statut change le format de sauvegarde** (champ nouveau sur chaque Pokémon) → **v4**, validée **seule** (règle 1). Les Dresseurs battus, les objets, la découverte et `poison_unlocked` sont des drapeaux ou des listes **existants** : ils ne changent pas le format.
3. **L'évolution n'est déclenchée nulle part** ; la logique existe, mais il manque le « quand » (après le combat), le « comment » (séquence, annulation) et les capacités de la nouvelle espèce.
4. **Le déroulé « apprendre / oublier » vit dans `BattleDirector`** (911 lignes) : l'évolution en a besoin hors du journal → l'extraire dans un nœud réutilisable plutôt que le copier (§2.3.4).
5. **Le plan du J8 (§0.2.1, §2.12) date d'avant la fusion du DA.0** : il dit la forêt serrée « seulement dans le prototype », alors que `DenseForest` / `ForestFloor` sont dans `game/`. Le T0 du J8 réalignera ; le J9 réutilise **ce que le J8 aura fusionné** (y compris son éventuel canal B du sous-bois et la teinte par rangée), sans le redéfinir.
6. **Tests qui énumèrent toutes les cartes** (`test_zone_library`, `test_map_light_profiles`) : une carte de QA les ferait échouer → préfixe `qa_` reconnu par `MapCatalog` (§2.6).
7. **Capacités en attente qui deviennent réelles** : Poudre Toxik (Bulbizarre Nv. 20, Herbizarre Nv. 22) et Dard-Venin (Aspicot ; Nidoran Nv. 14) empoisonneront partout, et un tirage aléatoire de plus par effet décale les combats à graine fixe (`tools/simulate_first_battle.gd`, tests de reproductibilité) → à recaler au T4, jamais en masquant.
8. **Cage-Éclair (Pikachu Nv. 9), Para-Spore, Ultrason, Choc Mental…** restent sans effet jusqu'au J11 (`pending_effects`, comme Poudre Dodo aujourd'hui) : limite connue, notée.

### 0.3 Alignement au T0 (2026-10-07, `main` à `b265ab4`)

Fusions dans `main` depuis `4107a05` : `360352c` (textes du dossier 10 verrouillés), DA.2 (`0fa57d4` … `c1a0215` : Bourg Palette peint, personnages peints, 4 routines) et `b265ab4` (planche de course de Chen). Effets sur ce plan :

1. **Le premier Dresseur s'appelle Scout Théo** (« Léo » est déjà le petit garçon de Bourg Palette) : plan corrigé partout (`forest_scout_theo`, `scout_theo`, « couloir de Théo »). La réplique de rappel du garde sud devient « Les Aspicot peuvent empoisonner. » / « La Boutique de Jadielle vend des Antidotes. » (§2.4.8 corrigé). **`jalon-09` ne contient pas encore cette version du dossier 10** : fusionner `main` dans `jalon-09` avant T6 / T11 (données des gardes et des Dresseurs « mot pour mot »).
2. **DA.2 a modifié `npc.gd` et `map.gd`** : routines retenues tant qu'aucun joueur n'est sur la carte (`Npc.set_routine_held`, `GameMap._release_routines`). Sans effet sur les Dresseurs (immobiles, approche jouée par des étapes `move` de scène, non concernées) ; utile aux tests de la forêt (P1 / P2 sur leur case de départ tant que le joueur n'est pas là). T11 / T12 (`Npc.show_emote`) partent d'une base qui contient ce changement.
3. **Apparences** : depuis DA.2, les PNJ de Bourg Palette sont peints et `test_character_look` le suppose (« les starters restent provisoires ») ; la carte de QA garde l'apparence générique existante pour ses Dresseurs et son garde (T12), les planches peintes `scout` / `guard` / `naturalist` restent à la série 11 (T17, §0.4 point 3).
4. **Textes (T0)** : lot `docs/design/textes/textes-brouillon-j9.md`. Les messages d'évolution utilisent `{species}`, absent de `BattleText.PLACEHOLDERS` (T8 l'ajoute, ou les textes de l'évolution vivent hors de `BattleText`) ; les noms de Dresseurs (« Scout Théo », « Gamin Tom ») sont des `name` entiers de `TrainerData` : aucune classe de Dresseur séparée à nommer.

### 0.4 Alignement après la fusion du J8 (2026-10-07, `jalon-09` à `5f25495` fusionné dans `j9-systemes`)

Le J8 (Route 2) et le Menu Dresseur MM.0–MM.3 sont dans la branche. Écarts avec la tranche B (à reprendre au T14 / T18 / T19, pas de code changé ici) :

1. **Constantes de la porte du poste : trois, pas une, et une à dédoubler.** `tools/build_route_2.gd` a `FOREST_GATE_SOON`, `FOREST_GATE_MAP`, `FOREST_GATE_TARGET` ; or `FOREST_GATE_TARGET` sert **à la fois** de `target_spawn` de la porte et de **nom du point d'apparition de retour** sur la Route 2 (`_add_spawns`). Le passer à `from_route_2` (§2.7.2) renommerait `from_forest_gate` et casserait la porte sud du poste. **T19** : ajouter `FOREST_GATE_RETURN := &"from_forest_gate"` pour le spawn de la Route 2, puis `FOREST_GATE_SOON = ""`, `FOREST_GATE_MAP = &"viridian_forest_gate_south"`, `FOREST_GATE_TARGET = &"from_route_2"` ; le nœud devient `ForestGate` (déjà prévu par l'outil). Dans la scène, `ForestGate` existe aussi sous `Entities` (la façade) : sans conflit (parents différents), mais un test qui cherche le warp par nom doit passer par `Warps/`.
2. **Objectif `go_north`** : la passation du J8 dit « le J9 ajoute son `unless` à l'entrée de la forêt » ; ce plan (§0.1, §2.7.3) garde « continuer vers le nord. » **jusqu'à Argenta** (défaut). Le dossier 10 n'en dit rien : **défaut du J9 gardé** (aucun `unless`), noté ici pour lever la contradiction.
3. **Numéro de série d'art** : la série 10 est prise deux fois (Route 2, `serie10.py` ; illustrations du Menu Dresseur, `serie10_menu.py`). La forêt devient la **série 11** : T14 (en-tête « Série 11 — Forêt de Jade » dans `fiches-assets/serie-01-place-jadielle.md`), T16, T17 (`serie11.py`) et §2.7.6 / §2.7.7 (« série 10 » → « série 11 »).
4. **Grille et outils** : `tools/plans/route_2.txt` + `tests/helpers/plan_grid.gd` (lecteur GDScript de la grille, même format que `plan_grille.py`) existent : `build_viridian_forest.gd` et `test_viridian_forest` les réutilisent (§2.7.1, §2.7.4). Hautes herbes jaune-vert (`ground_hautes_herbes_jaune_01` + `_bas`), `DenseForest.Shade` / `row_tint` (teinte par rangée) et `ForestFloor` sont disponibles ; le **tri de visibilité** de `DenseForest` n'existe pas encore (T18, comme prévu).
5. **Performances de référence** : la Route 2 (42 × 60, 2 732 nœuds) tourne à **53 fps** de moyenne sur S24 au T6 du J8 (69,3 Mo de textures, 184 appels de dessin). Le budget de la forêt (§2.7.4 : ≥ 58 fps, ≤ 3 000 nœuds sur 58 × 74) est donc **plus strict que ce que le J8 a atteint** sur une carte 1,7 fois plus petite : le tri de visibilité et le repli `Sprite2D` ne sont pas facultatifs ; mesurer la Route 2 et la forêt dans la même session au T20.
6. **Objets visibles et vision des Dresseurs** : un objet au sol (O1, O2, O5) est un PNJ `take` qui **occupe sa case** ; `TrainerRules` arrête la ligne de vue au premier personnage → un objet posé dans un champ de vision le coupe jusqu'à ce qu'il soit pris. T14 : aucun objet visible sur une ligne de vue (critère à ajouter à `plan_check.py` et à `test_viridian_forest`).
7. **Sans interférence avec la Route 2** : aucun Dresseur sur la Route 2 (dossier 11) ; `TrainerWatcher` parcourt les PNJ de la carte à chaque pas mais n'agit que sur `is_trainer()` ; le défi à la parole n'intercepte que les Dresseurs non battus ; `NpcRoster` impose le verbe `talk` à un Dresseur (un objet `take` ne peut pas en être un). Couvert par la suite complète après fusion.
8. **Tests à réécrire au T19**, déjà nommés : `test_coming_soon` (la porte du poste ne montre plus « À venir » : il passe sur la porte nord du poste nord) et `tools/capture_coming_soon.gd` (`start_spawn = from_forest_gate`).

**Hors périmètre** (dossier 10 et roadmap) : paralysie, sommeil, brûlure, gel (J11) ; mise en scène enrichie de l'évolution (J11) ; son et musique (intentions seulement, `GameMap.music` vide) ; Route 2 nord et Argenta (J10) ; mouvement « sans source » dans les feuillages (« au plus », facultatif : non fait au J9, noté) ; jour / nuit (même table).

---

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **9A.0** Fondations | alignement, lot de textes système (Q-1), données des 8 espèces et 12 capacités, sprites de combat provisoires | aucune (rien de jouable seul) |
| **9A.1** Sauvegarde v4 | statut persistant sur chaque Pokémon, migration v3 → v4, refus par une build v3 | **S24, seule** (règle 1) |
| **9A.2** Poison | combat (Dard-Venin, Poudre Toxik, dégâts de fin de tour, immunités, capture ×1,5), « PSN » partout, Antidote (Sac, combat), Centre / Maman / défaite, `poison_unlocked` → Antidote à la Boutique ; carte de QA | **S24** |
| **9A.3** Évolution | après le combat gagné, séquence ≈ 9 s, annulation, capacités de la nouvelle espèce, Pokédex | **S24** |
| **9A.4** Dresseurs | champ de vision, « ! », approche, répliques avant / après, défi à la parole, mémoire « battu », récompense, défaite | **S24** |
| **9B.0** Vue générale | grille fonctionnelle 58 × 74, plan en aplats, image Codex | **Kevin, sur l'image** |
| **9B.1** La forêt | carte peinte (forêt serrée, sous-bois, lumière), postes sud et nord, raccords, rencontres, performances | **S24** |
| **9B.2** La vie de la forêt | 5 Dresseurs, 2 PNJ, 2 gardes, Pokémon d'ambiance, 6 objets, rais de lumière ; **QA finale du J9** (vraie partie, durées mesurées) | **S24** + fusion |

- Jamais trois systèmes à la fois : 9A.2, 9A.3, 9A.4 sont **un système chacun**, codables **en parallèle** (fichiers presque disjoints, §3 « Parallélisme ») mais validés séparément. Si Kevin préfère, 9A.3 et 9A.4 peuvent être groupés en une session (deux systèmes, toléré par la règle 1).
- **9B.0 peut démarrer avant la fusion du J8** : elle ne touche que `tools/plans/`, `tools/art/` et `docs/` ; il lui faut seulement les outils du T0 du J8 (`plan_aplats.py`, `plan_check.py`) et la vue générale de la Route 2 validée (raccord au poste). La carte (9B.1) attend la fusion.

---

## 2. Conception technique

### 2.1 Poison (tranche A, 9A.2)

#### 2.1.1 Modèle

```gdscript
# game/pokemon/pokemon.gd
## Statut durable (jalon 9 : le poison seul, StatusRules) ; &"" = aucun. Persiste après le
## combat, sauvegardé (v4) ; effacé par heal_full (Centre, Maman, réveil après défaite), par un
## objet qui le soigne, et au K.O.
var status: StringName = &""
func has_status(id: StringName) -> bool
func cure_status() -> StringName   # rend le statut effacé (&"" s'il n'y en avait pas)
```

```gdscript
# game/pokemon/status_rules.gd — class_name StatusRules, RefCounted, statique et pur
const NONE: StringName = &""
const POISON: StringName = &"poison"
const KNOWN: Array[StringName] = [POISON]
## Règles actuelles (défaut, Q-6) : 1/8 des PV max en fin de tour (au moins 1), immunité des
## types Poison et Acier, capture ×1,5.
const POISON_FRACTION: float = 1.0 / 8.0
const POISON_IMMUNE_TYPES: Array[StringName] = [&"poison", &"steel"]
enum Inflict { OK, ALREADY, IMMUNE, FAINTED }
static func can_inflict(status: StringName, pokemon: Pokemon, types: Array[StringName]) -> Inflict
static func end_turn_damage(pokemon: Pokemon) -> int   # 0 si aucun statut à dégâts ou K.O.
static func catch_bonus(status: StringName) -> float   # 1,0 sans statut
```

Un seul statut à la fois (règle des jeux : un Pokémon empoisonné ne peut pas en recevoir un autre). Le J11 ajoute ses statuts à `KNOWN` et ses règles à cette classe, sans toucher au modèle.

#### 2.1.2 Effet de capacité

- `MoveEffect.Kind.STATUS` (**fin d'enum**), clé `"status"` ; champs `status` (identifiant de `StatusRules.KNOWN`, vérifié par `PokemonData`) et `chance` (existant, 100 par défaut).
- Données : `poison_powder` → `"effects": [{ "kind": "status", "status": "poison" }]` ; `poison_sting` → `{ …, "chance": 30 }` ; `twineedle` → `{ …, "chance": 20 }` ; les `pending_effects` correspondants **retirés** ; liste du vocabulaire `pending_effects` (doc de `MoveData`) complétée (`paralyze`, `paralyze_10`, `paralyze_30`, `confuse`, `confuse_10`, `double_hit`).
- `Battle._apply_effect` : capacité de **statut** (Poudre Toxik) → `IMMUNE` = `NO_EFFECT`, `ALREADY` = `STATUS_UNCHANGED` ; effet **secondaire** (Dard-Venin) → tirage `chance`, puis silence si `ALREADY` / `IMMUNE` / cible K.O. ; succès → `pokemon.status = POISON`, événement `STATUS_INFLICTED`.

#### 2.1.3 Combat

- `BattleEvent.Kind` (en fin d'enum) : `STATUS_INFLICTED`, `STATUS_UNCHANGED`, `STATUS_DAMAGED` (`amount`, `hp`, `max_hp`), `STATUS_CURED` ; champ `status: StringName` ; `SENT_OUT` porte le `status` du Pokémon envoyé (la carte de PV l'affiche dès l'entrée).
- **Fin de tour** (`Battle._end_turn`) : pour chaque camp (joueur puis adversaire), Vampigraine **puis** poison (`StatusRules.end_turn_damage`) ; un K.O. par le poison suit le chemin du K.O. existant (`_faint`, XP, `_check_end`, remplacement).
- **K.O.** : `_faint` efface le statut (règle actuelle des jeux).
- **Capture** : `_throw_ball` passe `StatusRules.catch_bonus(foe.status)` à `CaptureCalc` (déjà prévu).
- **IA « smart »** : `BattleAI.status_has_effect` refuse un effet de statut déjà présent ou sans effet (rival n° 3 plus tard ; « random » des Dresseurs de la forêt inchangée).
- **Antidote en combat** : `Battle._use_heal` → `ITEM_USED` puis `STATUS_CURED` ; le tour adverse suit (comme la Potion).
- `BattleText` + `data/battle/messages.json` : `status_inflicted_poison`, `status_unchanged_poison`, `status_damaged_poison`, `status_cured_poison` (accords `text_f`), **textes à valider (Q-1)**.
- Présentation (`BattleDirector._play_beat`, `BattleInfoCard`, `BattlePartyCard`) : étiquette **« PSN »** sur la carte de PV (dossier 08 : statut en texte), couleur du type Poison (`UiTokens.TYPE_COLORS[&"poison"]`) ; dégât de poison = court voile violet sur le Pokémon (≈ 0,35 s, défaut) + descente de la barre + message ; la « légère aura » du dossier 05 §13 reste au J11 (noté).

#### 2.1.4 Hors combat

- **Aucun dégât en marchant** (arbitrage 2) : rien n'écoute les pas pour le poison. Test explicite : 200 pas avec un Pokémon empoisonné, PV inchangés.
- « PSN » à la place de « K.O. » quand le Pokémon est debout : `TeamMemberView.STATUS_POISON` (`"PSN"`), rempli par `BattleViews`, `DashboardViews`, `TeamViews`, cartes de cible du Sac (une fonction commune `StatusRules`→texte dans les vues, jamais dans la logique).
- `heal_full` efface le statut : Centre, soin de Maman, réveil après défaite ; rien d'autre à câbler.

#### 2.1.5 Antidote et Boutique

- `data/items/items.json` : `"antidote": { "name": "Antidote", "plural": "Antidotes", "feminine": false, "category": "heal", "cures": ["poison"], "price": 100, "description": … }` (prix de Rouge/Bleu, défaut ; description : Q-1).
- `ItemData.cures: Array[StringName]` ; `ItemLibrary` : un soin a `heal_amount` > 0 **ou** `cures` non vide (statuts connus de `StatusRules`).
- `ItemUse` : `Check.NO_EFFECT` (**fin d'enum**) quand l'objet ne soigne que des statuts que le Pokémon n'a pas ; ordre : objet → contexte → Sac → K.O. → PV pleins (soin de PV) / sans effet (soin de statut) ; `apply` / `cure` ; `ItemUseResult.status_cured`. `BagQuery` : `NO_EFFECT` → « Sans effet » / « Cela n'aurait aucun effet sur %s. » (**déjà validés**) ; résultat « {pokemon} n'est plus empoisonné. » (Q-1).
- Toast au ramassage : format existant « Antidote ×1 — Ajouté au Sac » (arbitrage 8).
- `data/shops/viridian_mart.json` : `{ "item": "antidote", "if": ["poison_unlocked"] }` après la Potion (stock conditionnel existant).
- `poison_unlocked` : posé par la **première variante** du dialogue du garde sud (`"set"`), données seulement (§2.4.8, Q-4 pour l'automatisme).

### 2.2 Sauvegarde v4 (tranche A, 9A.1)

- `Pokemon.to_dict` : `"status": "poison"` ou `""` ; `from_dict` **tolérant** (absent → `""` ; inconnu de `StatusRules.KNOWN` → `""` + `push_warning`, jamais un refus de la sauvegarde).
- `SaveSystem.VERSION = 4` ; `upgrade` 3 → 4 sans transformation (champ absent = aucun statut) ; historique de la doc complété (« 4 = jalon 9 : statut des Pokémon ; une seule version pour tout le J9 ») ; une build v3 refuse un fichier v4 sans y toucher (mécanisme existant).
- `DebugStart` : clé de membre `"status"` (équipe et stockage).
- **Un seul changement de format pour tout le J9** : les Dresseurs battus (`beaten_<id>`), les objets (`got_viridian_forest_item_<n>` + `found_items`), la forêt et le poste nord découverts (`discovered_maps`), `poison_unlocked` sont des drapeaux ou des listes existants.
- Tests : `test_pokemon` (aller-retour du statut, valeur inconnue tolérée), `test_save_system` (v3 → v4, refus d'une v5, fichier v4 lu par une build v3 refusé intact), `test_game_state` (équipe et stockage empoisonnés relus), `test_debug_start` (`status`).

### 2.3 Évolution (tranche A, 9A.3)

#### 2.3.1 Quand

- **Après un combat gagné ou une capture** (même condition que le bilan : `BattleDirector.shows_progress`), **après le bilan**, avant la sortie de la vue de combat ; jamais après une défaite ni une fuite (les niveaux restent ; l'évolution sera proposée au prochain niveau gagné).
- Candidats (pur) : `Evolution.candidates(party: Party, leveled: Array[int], data: PokemonData) -> Array[EvolutionCandidate]` — chaque Pokémon de l'équipe **qui a gagné au moins un niveau** dans ce combat (entrées de l'`ExpSummary`), **debout**, dont `level_up_target` n'est pas vide ; ordre de l'équipe ; **une évolution par Pokémon et par combat** (un Chenipan passé de 6 à 10 devient Chrysacier ; Papilusion au prochain niveau).
- `EvolutionCandidate` (RefCounted) : `party_index`, `from_species`, `into`.
- **Annulée** : rien ne change ; reproposée au prochain niveau gagné (comportement de Rouge/Bleu, aucun état à sauvegarder) — Q-2.

#### 2.3.2 Ce qui change (pur)

```gdscript
# game/pokemon/evolution/evolution.gd (ajouts)
## Fait évoluer [param pokemon] en [param into] (evolve_into) et renvoie les capacités de la
## nouvelle espèce à son niveau actuel qu'il ne connaît pas encore, dans l'ordre des données.
static func evolve(pokemon: Pokemon, into: StringName, data: PokemonData) -> Array[StringName]
```

- Pokédex : `GameState.record_caught(into, &"")` (vu + capturé ; pas d'habitat : l'évolution n'est pas une rencontre) → toasts Pokédex existants si le Pokédex est activé ; « Évolution découverte » se déduit déjà (dossier 08, `EvolutionReveal`).
- Surnom, sexe, IV / EV, XP, rencontre, favori, PP **gardés** (`evolve_into`).

#### 2.3.3 Présentation (simple, définitive dans sa logique ; enrichie au J11)

`game/ui/evolution/evolution_screen.tscn` + `evolution_screen.gd` (`EvolutionScreen`, `CanvasLayer` au-dessus de la HUD de combat) et `game/systems/evolution/evolution_director.gd` (`EvolutionDirector`, Node) :

```gdscript
signal evolution_started(party_index: int, into: StringName)
signal evolution_finished(party_index: int, into: StringName, cancelled: bool)
func setup(state: Node, data: PokemonData, texts: BattleText, learn: MoveLearnPrompt) -> void
func play(candidates: Array[EvolutionCandidate], party: Party) -> void   # coroutine
func handle_back() -> bool   # retour Android = annuler pendant la transformation
```

Déroulé (défauts, règle 4 ; dossier 04 §7 : 8 à 12 s) : fond opaque sombre (« l'environnement disparaît ») → le Pokémon au centre, « Quoi ? {pokemon} évolue ! » (dossier 04) **1,5 s** → **transformation 5 s** : silhouettes blanches de l'ancienne et de la nouvelle espèce qui alternent en accélérant, bouton **« ARRÊTER »** visible (libellé : Q-1, geste : Q-2) → flash 0,3 s, silence 0,4 s, la nouvelle espèce en couleurs, vibration courte (`Haptics`), « Félicitations ! {pokemon} a évolué en {species} ! » (Q-1), toucher pour continuer → capacités de la nouvelle espèce (§2.3.4) → suivant. Annulé : retour à l'ancienne espèce, « {pokemon} n'évolue plus. » (Q-1). Durées dans `UiTokens.EVOLUTION_*` ; « Réduire les animations » divise les durées (comme le Centre) ; `speed_scale` des tests.

Images : artworks officiels (`PokedexArt.portrait_path`, déjà dans l'APK) pour les deux espèces et leur silhouette (matériau de silhouette existant) — aucune image nouvelle.

Câblage : `BattleDirector.set_evolution_director(d)` ; dans `run_request`, après `_play_progress(outcome)` : `await _evolutions.play(Evolution.candidates(...), party)` si `shows_progress(outcome)` ; verrou gardé ; `battle_finished` après (l'autosave existant suit). `[qa] évolution <de> → <en> (annulée|faite)`.

#### 2.3.4 Capacités à l'évolution : un seul déroulé

`MoveLearnPrompt` (Node, `game/battle/move_learn_prompt.gd` — écart du T8, §6.6) extrait de `BattleDirector._offer_forget` / `_confirm_forget` : « {pokemon} apprend {move} ! » (toucher), ou le `MoveForgetPanel` (+ `ChoiceCards` si `confirm_forget`) puis la phrase. `BattleDirector` l'utilise pour `MOVE_LEARNED` / `MOVE_FORGET_OFFERED` (comportement **inchangé** : `test_battle_director` est le filet), `EvolutionDirector` pour les capacités rendues par `Evolution.evolve`. Le bandeau de message est passé en paramètre (celui du combat ou celui de l'écran d'évolution).

### 2.4 Dresseurs (tranche A, 9A.4)

#### 2.4.1 Données

Le **combat** reste dans `data/trainers/` ; le **placement et la vision** sont un bloc du PNJ dans `data/npcs/<carte>.json` ; les **répliques** dans `data/dialogues/`.

```json
// data/trainers/viridian_forest.json
"forest_scout_theo": {
	"name": "Scout Théo", "ai": "random",
	"can_lose": false, "heal_after": false, "gives_exp": true, "prize_money": 72,
	"team": [{ "species": "caterpie", "level": 6 }]
}
// data/npcs/viridian_forest.json (et qa_forest_systems.json)
"scout_theo": {
	"cell": [x, y], "facing": "up", "sprite": "scout",
	"dialogue": "forest_scout_theo_after",
	"trainer": { "id": "forest_scout_theo", "sight": 4, "before": "forest_scout_theo_before" }
}
```

| Id | Nom (`name`, aussi `speaker`) | Vision | Équipe | ₽ (`prize_money`) |
|---|---|---:|---|---:|
| `forest_scout_theo` | Scout Théo | 4 | Chenipan 6 | 72 |
| `forest_scout_noe` | Scout Noé | 5 | Aspicot 6, Coconfort 6 | 144 |
| `forest_youngster_tom` | Gamin Tom | 4 | Rattata 7 | 84 |
| `forest_scout_milo` | Scout Milo | 5 | Chenipan 6, Aspicot 6 | 144 |
| `forest_scout_eli` | Scout Éli | 5 | Chrysacier 7, Coconfort 7, Chenipan 7 | 252 |

- Montants **fixes** du dossier (ils ne suivent pas « base × niveau » : `prize_money`, déjà prévu). IA `random` (dossier 05 §19 : débutants), SAC permis, messages génériques « {trainer} veut se battre ! » / « Tu as battu {trainer} ! » (existants).
- `NpcSpec` : `trainer_id`, `sight`, `before_dialogue`, `is_trainer()` ; `NpcRoster` valide le bloc (vision 1..8, `before` non vide, `dialogue` = réplique « après » obligatoire, `facing` obligatoire, **ni** `route`, `look`, `shy`, `idle_react` : un Dresseur qui tourne changerait sa vision — défaut). Un test croise `trainer.id` avec `TrainerLibrary` et les dialogues avec `DialogueLibrary`.
- Drapeau **« battu »** : `TrainerRules.beaten_flag(id)` = `beaten_<id>` (`StoryFlags`, sauvegardé, format inchangé).

#### 2.4.2 Vision (pur)

```gdscript
# game/world/npc/trainer_rules.gd — class_name TrainerRules, statique et pur
static func beaten_flag(trainer_id: StringName) -> StringName
## Distance (1..sight) du joueur sur la ligne droite devant le Dresseur, ou -1. La ligne
## s'arrête à la première case infranchissable (décor, eau, autre personnage) ; les hautes
## herbes et les rebords ne la coupent pas.
static func sight_distance(grid: GridWorld, from: Vector2i, facing: Vector2i, sight: int,
		target: Vector2i) -> int
## Pas de l'approche : jusqu'à la case voisine du joueur (distance − 1 pas, 0 à 4).
static func approach_path(facing: Vector2i, distance: int) -> Array[Vector2i]
```

Défaut (règle 4) : le Dresseur **marche jusqu'à la case voisine** (Rouge/Bleu) ; avec une vision de 4–5, c'est 0 à 4 pas, « 2–3 cases » dans le cas courant voulu par le level design (le dossier parle d'une approche de 2–3 cases : le T19 place les Dresseurs pour que la détection type arrive à 3–4 cases).

#### 2.4.3 Séquence (construite en code, jouée par le directeur de scènes)

`TrainerEncounter.build(npc_id, spec, distance) -> CutsceneVariant` (pur, `game/world/npc/trainer_encounter.gd`) produit des `CutsceneStep` **existants** + un nouveau (`emote`) :

1. *(vu)* `emote` « ! » sur le Dresseur (0,6 s), `wait` 0,3 ;
2. *(vu, distance > 1)* `move` du Dresseur sur `approach_path` (marche) ;
3. `face` joueur → Dresseur, `face` Dresseur → joueur ;
4. `dialogue` `before` ;
5. `battle` `trainer_id`, `win: [beaten_<id>]` ;
6. `dialogue` « après » `if: [beaten_<id>]` (Q-3 : jouée tout de suite après la victoire) ;
7. `wake_up` `unless: [beaten_<id>]` (défaite : réveil au dernier Centre, rien de retiré, le Dresseur n'est pas battu et redéfiera — dossier 10 §15).

`CutsceneDirector.play_variant(cutscene_id: StringName, variant: CutsceneVariant, aliases := {}) -> bool` : `play()` y délègue après `pick` ; même verrou, mêmes signaux (`cutscene_started` / `finished` → autosave existant). Aucun fichier de scène par Dresseur.

#### 2.4.4 Étape `emote`

`CutsceneStep.Kind.EMOTE` (**fin d'enum**, clé `"emote"` dans `TYPE_KEYS`, acteur + `"kind": "exclamation"`), aussi acceptée dans les fichiers de scènes (`CutsceneLibrary`). `Npc.show_emote(kind) -> void` + signal `emote_finished` : bulle au-dessus de la tête (SVG `assets/ui/icons/emote_exclamation.svg`, UI non pixel art), apparition en rebond, tenue, disparition (tween ; durée `UiTokens.EMOTE_*`, 0,6 s par défaut).

#### 2.4.5 Défi à la parole

`InteractionController._interact` : PNJ `is_trainer()` **non battu** → `challenge_requested(npc)` (comme `meet_requested`), sans dialogue ; `TrainerWatcher.challenge(npc)` joue la séquence **sans « ! » ni approche** (étapes 3 à 7). Battu → son dialogue (« après »).

#### 2.4.6 `TrainerWatcher`

`game/world/npc/trainer_watcher.gd` (Node, modèle `AmbientWatcher`) : `setup(player, flags, cutscenes)`, `set_map(map)`, `challenge(npc)`, signal `trainer_spotted(npc_id, trainer_id)`. Sur `Player.moved` : rien si le joueur est bloqué (scène, dialogue, combat, transition) ; sinon le **premier** Dresseur non battu (ordre du fichier) dont `sight_distance` ≥ 1 lance sa séquence (verrou synchrone dans le signal). **Branché dans `Boot` entre le `CutsceneDirector` et l'`EncounterDirector`** : un pas qui entre dans un champ de vision ne déclenche pas de rencontre sauvage (test d'ordre). Après la victoire, le Dresseur reste où il s'est arrêté jusqu'au rechargement de la carte (Rouge/Bleu).

#### 2.4.7 Textes

`data/dialogues/viridian_forest.json` : `forest_<dresseur>_before` / `_after`, **mot pour mot** depuis « Textes validés » ; une réplique « « … » / « … » » = **une page**, les deux lignes jointes par `\n` (bulle de 2 lignes, comme le panneau « ROUTE 2\n… » du J8) ; « Enfin... presque. » garde ses trois points. `speaker` = nom du Dresseur.

#### 2.4.8 Gardes (données de la tranche A, réutilisées en B)

`forest_gate_south_guard` : variante 1 `unless: [poison_unlocked]`, `set: [poison_unlocked]`, page « La Forêt de Jade est juste devant.\nGarde un Antidote avec toi. » (+ `auto` si Q-4) ; variante 2 : « Les Aspicot peuvent empoisonner.\nLa Boutique de Jadielle vend des Antidotes. ». `forest_gate_north_guard` : défaut « Encore quelques pas vers le nord,\net tu atteindras Argenta. » ; variante `if: [pewter_arrived]` (drapeau que le J10 posera à l'arrivée à Argenta ; défaut) « La Forêt de Jade mène à Jadielle.\nLes jeunes Dresseurs s'y entraînent. ». `speaker` « Garde » (défaut).

### 2.5 Données des espèces (tranche A, 9A.0)

- `data/pokemon/species/kanto.json` : `caterpie` (10), `metapod` (11), `butterfree` (12), `weedle` (13), `kakuna` (14), `beedrill` (15), `pikachu` (25), `raichu` (26). Conventions **des 24 espèces existantes** : statistiques, `base_exp`, `catch_rate`, `growth_rate`, `male_ratio` des jeux actuels ; apprentissages de **Rouge/Bleu**.
- Évolutions : Chenipan → Chrysacier Nv. 7, Chrysacier → Papilusion Nv. 10, Aspicot → Coconfort Nv. 7, Coconfort → Dardargnan Nv. 10 (dossier) ; Pikachu → Raichu `item` `thunder_stone` (défaut : Raichu entre dans les données pour que le Pokédex montre « Pikachu → ??? » ; la Pierre Foudre n'existe pas : jamais déclenché).
- Chrysacier et Coconfort : `[1, "harden"], [7, "harden"]` (modèle d'Herbizarre) → Armure apprise **à l'évolution** (défaut moderne, Q-5).
- Capacités nouvelles (`moves.json`, valeurs actuelles comme l'existant) : `string_shot` (Sécrétion), `harden` (Armure), `thunder_shock` (Éclair), `thunder_wave` (Cage-Éclair), `confusion` (Choc Mental), `stun_spore` (Para-Spore), `supersonic` (Ultrason), `psybeam` (Rafale Psy), `twineedle` (Double-Dard), `pin_missile` (Dard-Nuée), `swift` (Météores), `thunder` (Fatal-Foudre) ; effets non gérés en `pending_effects` ; **descriptions : Q-1**.
- `data/pokedex/kanto.json` : 8 entrées (taille, poids officiels ; **description : Q-1**).
- Sprites de combat provisoires : `tools/gen_placeholder_battlers.gd` étendu aux 8 espèces (`placeholder/<espèce>_front/_back.png`). Dos peints : chantier « dos de combat » existant (mémoire du projet), hors J9.
- Rencontres : `data/encounters/viridian_forest.json` (`viridian_forest_grass`, `maps: ["viridian_forest", "qa_forest_systems"]`, `rate` 25, rampe 15 → 20 comme la Route 1 et la Route 2 — défaut ; poids 35 / 35 / 13 / 12 / 5, niveaux du dossier §6).

### 2.6 Carte et départs de QA (tranche A)

- `MapCatalog.QA_PREFIX = "qa_"`, `is_qa_map(id)` : les tests qui énumèrent les cartes (`test_zone_library`, `test_map_light_profiles`) les ignorent ; une carte de QA n'appartient à aucune zone (le Pokédex n'y note aucun habitat, la Carte ne la montre pas — tests). Inaccessible en jeu (aucun warp n'y mène) ; seulement par `DebugStart`. **Retirée à la clôture du J9** (T23) avec ses données.
- `tools/build_qa_forest_systems.gd` → `game/world/maps/qa_forest_systems.tscn` (≈ 24 × 18, tuiles provisoires `OverworldTiles`, aucune lumière) :
  - garde sud (sprite générique) au nord du départ : `forest_gate_south_guard` ;
  - hautes herbes 5 × 4 (table de la forêt) ;
  - **couloir de Théo** : Dresseur tourné vers le bas, couloir d'une case de large qui oblige à entrer dans sa vision (inévitable) ;
  - **clairière de Noé et Milo** : visions qui se croisent (un seul défi à la fois), Milo contournable par l'herbe ;
  - **Tom** tourné vers la gauche, abordable de côté (défi à la parole) ;
  - **Éli** (trois Pokémon) au fond ;
  - sortie sud (3 cases, PUSH ↓) → `viridian_city`, spawn `from_center` (existant) : Centre et Boutique à deux pas, **sans toucher Jadielle**.
- `data/npcs/qa_forest_systems.json` (vrais identifiants de Dresseurs et de dialogues : les drapeaux `beaten_*` d'une partie de QA ne servent qu'au débogage).
- Départs (`tools/debug_start/`, README complété) :
  - `poison_qa.json` : Salamèche N9 **empoisonné** (`status`), Roucool N7, 2 Antidotes, 2 Potions, 3 000 ₽, Pokédex activé, `poison_unlocked` absent, devant le garde ;
  - `evolution_qa.json` : Chenipan N6 et Aspicot N6 à 1 XP du N7 (`exp_to_next`), Salamèche N9, 5 Potions, au bord des hautes herbes ; plus un Chrysacier N9 à 1 XP du N10 (deuxième évolution) ;
  - `trainers_qa.json` : Salamèche N9, Roucool N8, 5 Potions, 1 Antidote, 3 000 ₽, à l'entrée du couloir de Théo ;
  - `trainers_weak_qa.json` : Salamèche N4 seul (pour perdre contre Théo : réveil, argent intact, Théo redéfie).

### 2.7 La forêt (tranche B)

#### 2.7.1 Grille fonctionnelle (T14, source unique)

`tools/plans/viridian_forest.txt` (≈ 58 × 74, enveloppe verrouillée), légende du J8 étendue : `T` forêt, `.` herbe rase / sous-bois praticable, `=` sentier, `h` hautes herbes, `C` clairière, `S` grande souche (emprise), `I` tronc incliné, `L` clairière au rayon de lumière, `r` amas de racines, `D1..D5`, `P1`, `P2`, `O1..O6`, `g` / `G` sorties sud / nord. Tracé du dossier §4 (grand S **strictement orthogonal**, boucles secondaires, aucun embranchement à trois directions équivalentes), repères tronc → souche → clairière (arbitrage 10).

Critères vérifiés par `plan_check.py` (J8, étendu) **et** par `test_viridian_forest` sur la vraie scène :

| Critère | Valeur |
|---|---|
| Chemin principal le plus court, entrée sud → sortie nord | 220 à 280 pas (≈ 250, arbitrage 4 ; défaut de tolérance) |
| Herbes obligatoires | 6 à 8 cases, **toutes dans H3** ; H1, H2, H4 évitables |
| D1 (Théo) | **inévitable** : tout chemin sud → nord traverse son champ de vision, et la case de détection laisse ≥ 2 cases entre lui et le joueur |
| D2, D3, D5 | évitables (un chemin sud → nord qui n'entre dans aucun de leurs champs) ; D4 évitable **par les hautes herbes** seulement |
| Objets | les 6 cases atteignables ; O1 à moins de 25 pas de l'entrée ; O2 au fond du cul-de-sac occidental (via H2) ; O3 derrière la souche par un passage d'une case ; O6 à moins de 15 pas de la sortie nord |
| Vision | aucune case de vision d'un Dresseur sous une cime ou sur une case infranchissable au-delà du premier obstacle (cohérence) |
| Caméra | ≈ 24,4 × 11,25 cases visibles sur S24 : les clairières (C1–C3) font au moins 7 × 5 cases (« respirations ») |

#### 2.7.2 Postes de garde : une définition, deux scènes (arbitrage 9)

`tools/build_painted_interiors.gd` : `_forest_gate(side: StringName) -> Dictionary` (même enveloppe peinte, mêmes meubles, garde à la même place ; seuls changent l'identifiant, le fichier de PNJ et les warps) → `viridian_forest_gate_south.tscn` et `viridian_forest_gate_north.tscn`. Deux scènes générées parce que `MapCatalog` lie un identifiant de carte à une scène (la position sauvegardée et la Carte s'appuient dessus) ; une seule scène partagée par deux identifiants demanderait de toucher le routeur et la sauvegarde pour rien. Pièce **10 × 8 cases** (défaut), portes au milieu des murs sud et nord, `interior = true`.

| Passage | Warp | Cible / spawn |
|---|---|---|
| Route 2 (20, 8) | `ForestGateSoon` du J8 → **`ForestGate`** : `coming_soon` vide (seule ligne changée, constante `FOREST_GATE_*` de `build_route_2.gd`) | `viridian_forest_gate_south`, `from_route_2` |
| Poste sud, porte sud | STEP_ON ↓ | `route_2`, `from_forest_gate` (20, 9), tourné ↓ |
| Poste sud, porte nord | STEP_ON ↑ | `viridian_forest`, `from_gate_south` |
| Forêt, sortie sud (dernière rangée) | PUSH ↓ | `viridian_forest_gate_south`, `from_forest` |
| Forêt, porte du poste nord | STEP_ON ↑ | `viridian_forest_gate_north`, `from_forest` |
| Poste nord, porte sud | STEP_ON ↓ | `viridian_forest`, `from_gate_north`, tourné ↓ |
| Poste nord, porte nord | STEP_ON ↑, `coming_soon = "Route 2 nord"` | retour devant la porte, tourné ↓ (« ROUTE 2 NORD — À venir ») |

Défaut : depuis la forêt, le poste sud n'est pas une façade (on ne voit que son toit au bas de l'écran, selon la vue générale) ; le poste nord réutilise la façade `bldg_poste_foret_01` du J8.

#### 2.7.3 Zone, découverte, objectif

`zones.json` : `viridian_forest.maps` = `[viridian_forest, viridian_forest_gate_south, viridian_forest_gate_north]` (défaut : les postes appartiennent à la forêt) ; `subtitle` / `description` : Q-1. « Forêt découverte (entrée et sortie nord) » = `discovered_maps` de `viridian_forest` et `viridian_forest_gate_north`. Objectif : « continuer vers le nord. » (J8) reste vrai (défaut). Défaite : système normal.

#### 2.7.4 Carte, forêt serrée, performances

`tools/build_viridian_forest.gd` (modèle `build_route_1.gd` / `build_route_2.gd`, deux passes masque / scène) lit la grille : `Ground` logique, `PaintedGround` + masque, `ForestFloor`, `DenseForest` (graine fixe) **avec tri de visibilité à la construction** : aucun arbre dont le pied est à plus de 13 colonnes ou 9 rangées (6 + cime de 3) de toute case praticable (jamais à l'écran ; le sous-bois sombre suffit) ; arbres repères (tronc incliné, grande souche, arbres des clairières), hautes herbes jaune-vert (art du J8), racines, sac de la randonneuse, poste nord, rais de lumière.

Budget (défaut, comme le J8) : ≤ 3 000 nœuds, changement de carte ≤ 1,5 × celui de Jadielle, moyenne ≥ 58 fps sur S24 avec des creux ≥ 50. Repli si dépassé : arbres de forêt en `Sprite2D` simples sans scène `WorldProp` (le J8 a le même repli), puis regroupement par tronçons.

#### 2.7.5 Lumière et ambiance (dossier §14)

- Profil `forest` (nouveau dans `data/world/lighting.json`, `maps.viridian_forest`) : ombres bleu-vert, verts profonds, pas de filtre vert uniforme ; les postes gardent le profil des intérieurs.
- Rais de lumière : décalcomanies additives peintes dans les clairières et sur quelques cases du chemin (le joueur traverse un rai puis retourne dans l'ombre) ; particules végétales très rares dans 2–3 rais (CPUParticles2D, ≤ 12 particules chacun, défaut) ; aucun effet permanent ailleurs.

#### 2.7.6 Pokémon d'ambiance (dossier §7)

- `NpcSpec.SHY_ACTIONS` += `notice` (Chenipan : animation « react » quand le joueur passe à ≤ 2 cases, puis reprend, sans quitter la carte ; pas plus d'une fois toutes les 4 s, défaut) et `hide` (Aspicot sur un tronc : petit recul vers le haut + fondu quand le joueur arrive à 1 case, retiré comme l'envol). Roucool `fly` existant (un seul, dans une clairière). Chrysacier / Coconfort : immobiles, sans comportement. Aucun Pikachu d'ambiance.
- Un Pokémon d'ambiance peut être posé sur une case de forêt (tronc, branche basse) : vérifier que `NpcRoster` / `GameMap` l'acceptent pour un PNJ non interactif et immobile.
- Apparences peintes : `pokemon/caterpie`, `pokemon/weedle`, `pokemon/metapod`, `pokemon/kakuna` (série 11, planches « Pokémon fixes », §2.8).

#### 2.7.7 PNJ et objets

- P1 naturaliste : `route` de 3 cases + `look` vers un tronc ; P2 randonneuse : `route` entre la souche et son sac, apparence `hiker` du J8 (défaut) ; dialogues « première fois / ensuite » par drapeau (`forest_naturalist_talked`, `forest_hiker_talked`), modèle du J8 (Q-2 du J8).
- Gardes : apparence peinte `guard` (nouvelle, série 11) ; Dresseurs : `scout` (nouvelle, une pour les quatre Scouts, défaut), Tom : `youngster` (existante).
- Objets visibles O1 (Antidote), O2 (Poké Ball), O5 (Poké Ball) : mécanisme du J8 (§2.3 du J8 : entrée de PNJ `object/poke_ball_ground`, verbe PRENDRE, scène `despawn` + `give found` + `set`). Cachés O3 (Potion), O4 (Antidote), O6 (Potion) : `EventTriggerPoint` sur herbe rase → narration (textes validés) → `give … found: true` → toast standard (arbitrage 8). Drapeaux `got_viridian_forest_item_1` … `_6`.

### 2.8 Assets de la forêt : liste exacte (T16, 2026-10-07, d'après la vue validée)

**Méthode** : celle du J8 T2 (§1.2 du J8), consigne de Kevin « le plus petit kit modulaire qui produit la sensation de la vue validée dans Godot, sans effet répétitif ». Vue : `reference/foret-jade-vue-generale-v1.png` (essai r2, validé le 2026-10-07) ; **la grille `tools/plans/viridian_forest.txt` fait foi** pour la géométrie (règle 10, dossier 10 « Vue générale peinte v1 »). **Bilan : 16 images Codex** (4 décors, 1 planche de sous-bois promue du J8, 1 enveloppe de pièce, 3 personnages × marche + attente, 4 Pokémon d'ambiance en une planche chacun), 2 conditionnels, 4 abandons ; tout le reste vient de la Route 2, de la Route 1 et des intérieurs de Bourg Palette. Script : `tools/art/serie11.py` ; planche de contrôle sans Codex : `build/art/FJ_KIT_v1.png` (`python3 tools/art/serie11.py --planche`), 1 case = 48 px, héros à l'échelle.

#### 2.8.1 Réutilisés tels quels (aucun travail d'art)

| Élément de la vue (grille) | Asset(s) |
|---|---|
| Forêt serrée (toutes les cases `T`) | `tree_foret_01` … `08` par `DenseForest` + sous-bois `ForestFloor` (masque des cases de forêt) |
| Arbres des clairières (C1, C2, C3, parvis, clairières de P2, d'O5, de H4) | `tree_e_01` (grand feuillu), `tree_b_01` (conifère), `tree_c_01`, `tree_a_01` : 2 à 3 par clairière, sur des cases `T` du bord, jamais deux fois le même côte à côte ; **aucun arbre neuf** |
| Sentier | `ground_chemin_01` (masque G) |
| Herbe rase des clairières et du sous-bois praticable (`C`, `L`, `.`) | `ground_herbe_01` ; `.` = herbe + `ForestFloor` partiel (comme le dernier tiers de la Route 2) |
| Hautes herbes H1 à H4 | `ground_hautes_herbes_jaune_01` (+ `_bas`), deux touffes par case |
| Poste nord (façade vue du sud, porte (25, 5)) | `bldg_poste_foret_01` (J8), emprise 7 × 4, porte `open [(0, 0)]` |
| Petites souches `s` (20, 7) et (40, 44) (O6, souche de P2) | `prop_souche_01` |
| Lisière, recoins | `prop_ronces_01`, `prop_tronc_couche_01` (sur des cases `T` au bord des clairières, deux ou trois chacun) |
| Fleurs blanches, roses, orange des clairières | `decal_fleur_1`, `_3`, `_5`, `_6` (rares, seulement dans les clairières) ; `decal_touffe_*` |
| Poké Balls au sol (O1 Antidote, O2, O5) | `object/poke_ball_ground` (J8 ; même aspect pour tout objet visible, décision de Kevin du dossier 11 §11) |
| Randonneuse (P2) | `randonneuse` (`hiker`, J8, défaut du §2.7.7) |
| Gamin Tom (D3) | `jeune_dresseur` (`youngster`) |
| Roucool (clairière de H4) | `roucool` (`pokemon/pidgey`) |
| Intérieur des postes : mobilier | `int_plante` ×2, `int_meuble_bas_01`, `int_porte_manteau_01` (série 07, lumière NE) ; aucun meuble neuf |

#### 2.8.2 Variations sans nouvel asset

| Variation | Où, comment | Qui |
|---|---|---|
| **Forêt plus sombre et plus froide que la Route 2** (vue : verts profonds, bleu-vert) | `DenseForest.Shade` uniforme sur toute la carte (défaut : valeur × 0,78, rouge × 0,97, bleu × 1,05), plus sombre au cœur (× 0,72 à plus de 4 cases d'une case praticable, invisible de toute façon) ; essences `04`, `05`, `06` (bleu-vert, conifères) poids × 2 partout | T19 (paramètres existants du J8) |
| **Lumière** | profil `forest` (§2.7.5) : la forêt est assombrie par Godot, les assets restent en lumière NE | T18 |
| **H3 sous la canopée** | touffes de H3 × 0,86 (comme H3 de la Route 2) | T19 |
| **Ombres de canopée au sol** | ombres d'arbres existantes à plat sur l'herbe des clairières (J8 §1.2 B), plus denses hors des rais | T19 |
| **Rais de lumière** (C3, cases `L` ; 2 à 4 taches sur le chemin) | **par Godot, sans image** : quadrilatère incliné (`Polygon2D` + `GradientTexture2D`, matériau additif) + tache au sol (`GradientTexture2D` radial) ; orientation du haut-gauche vers le bas-droite (lumière du jeu) ; particules ≤ 12 dans 2–3 rais (§2.7.5) | T21 |
| **Souches** | `prop_souche_01` en miroir et teinte ± 8 % (les deux ne sont jamais à l'écran ensemble) | T19 |
| **Sous-bois des bandes `.`** (réserve « haies taillées » de la vue) | bord irrégulier : `ForestFloor` partiel à taches bruitées + décalcomanies de sous-bois (2.8.3) semées à graine fixe ; **aucun buisson** sur une case praticable | T19 |

#### 2.8.3 Nouveaux (série 11, Codex, lumière NE)

Fiches complètes : `docs/design/fiches-assets/serie-01-place-jadielle.md` (« Série 11 — liste exacte et fiches »). Références = recadrages `REF_FJ_*` de la vue (`serie11.py --refs`).

| Fiche → asset | Rôle que rien d'existant ne tient | Taille / emprise (grille) | Images |
|---|---|---|---|
| `WORLD_PROP_TRONC_INCLINE_01` → `prop_tronc_incline_01` | repère sud (arbitrage 10) ; `prop_tronc_couche_01` est couché et petit | ≈ 4 × 3 cases ; pied = cases `I` (37..38, 63), le tronc monte vers le haut-gauche **au-dessus de la forêt**, jamais du sentier (choix de Kevin au T14 : à côté, pas en arche) | 1 |
| `WORLD_PROP_GRANDE_SOUCHE_01` → `prop_grande_souche_01` | repère central, creux, racines étalées (modèle : la souche creuse de la vue) | ≈ 3,4 × 2,6 cases ; emprise 3 × 2 = `S` (26..28, 43..44) | 1 |
| `WORLD_PROP_RACINES_01` → `prop_racines_01` | amas de racines d'O4 (« coincé entre les racines ») | ≈ 1,6 × 2 cases ; emprise 1 × 2 = `r` (5, 35..36) | 1 |
| `WORLD_PROP_SAC_RANDO_01` → `prop_sac_rando_01` | sac posé de P2 ; le sac de voyage de la chambre (`int_sac_voyage_01`) est celui du héros | 0,7 case ; emprise 1 case (45, 44) | 1 |
| `WORLD_GROUND_SOUS_BOIS_01` → `decal_sousbois_1..8` | fougères, mousse, feuilles mortes, racines, brindilles, champignons (vue) ; **conditionnel du J8, promu** | planche 4 × 2, 0,6 case chacun | 1 |
| `INT_POSTE_FORET_COQUE` → `int_poste_foret_coque` | enveloppe vide **commune aux deux postes** (§2.7.2) : pierre claire et bois comme la façade, ouvertures de 2 cases au centre des murs nord et sud | 10 × 8 cases | 1 |
| `PNJ_GARDE` (+ attente) → `garde` (`guard`) | les deux gardes ; aucun uniforme dans le jeu | 130 px, marche 4 × 4 + attente 4 × 1 | 2 |
| `PNJ_SCOUT` (+ attente) → `scout` (`scout`) | les quatre Scouts (une apparence, défaut §2.7.7) : chapeau de paille, filet | 112 px | 2 |
| `PNJ_NATURALISTE` (+ attente) → `naturaliste` (`naturalist`) | P1 ; le chercheur de Bourg Palette porte une blouse | 128 px | 2 |
| `POKE_CHENIPAN_FIXE` → `chenipan` (`pokemon/caterpie`) | 2 Chenipan, `notice` = relève la tête | 44 px ; planche 4 × 1 (2.8.5) | 1 |
| `POKE_ASPICOT_FIXE` → `aspicot` (`pokemon/weedle`) | 2 Aspicot, `hide` (recul + fondu par le code), réaction = se recroqueville | 44 px | 1 |
| `POKE_CHRYSACIER_FIXE` → `chrysacier` (`pokemon/metapod`) | cocon immobile ; réaction = frisson (si un `react` lui est donné) | 56 px | 1 |
| `POKE_COCONFORT_FIXE` → `coconfort` (`pokemon/kakuna`) | idem | 56 px | 1 |

Hauteurs, tenues et emprises = **valeurs par défaut** (règle 4).

**Conditionnels** (prompts prêts dans `serie11.py`, jamais lancés par défaut ; décision de l'architecte sur capture, notée dans `etat-projet.md`) : `WORLD_TREE_FORET_PLANCHE_C` (4 arbres de forêt plus sombres, si la capture du T19 montre des répétitions : la forêt pose ≈ 2 à 3 fois plus d'arbres que la Route 2 avec les mêmes 8 images) ; `WORLD_DECAL_RAIS_LUMIERE_01` (rai et tache peints sur fond noir, mode additif, si le rai de Godot du T21 ne se lit pas).

#### 2.8.4 Règles `PaintedPropRules` prévues (T17)

`prop_tronc_incline_01` : `{"cells": [Vector2i(-1, 0), Vector2i(0, 0)], "align": edge, "origin": <pied mesuré sur l'image>}` (ancre (38, 63) ; l'image déborde vers le haut-gauche sur des cases de forêt seulement : ni `fade` ni vent) ; `prop_grande_souche_01` : `{"width": 3, "depth": 2}` (ancre (27, 44)) ; `prop_racines_01` : `{"width": 1, "depth": 2}` (ancre (5, 36)) ; `prop_sac_rando_01` : `{"width": 1, "depth": 1}`. Aucune ombre portée (règle des petits objets et de la végétation) ; contact préparé.

#### 2.8.5 Pokémon d'ambiance immobiles : un format, deux ajouts d'outil (T17)

Ils ne marchent jamais : une planche de marche 4 × 4 (le format des PNJ) serait générée pour rien. **Une planche par Pokémon**, une ligne de 4 poses : repos de face, réaction de face, repos de profil gauche, réaction de profil gauche.
- `preparer.py`, section **`pokemon_fixes`** (entrées déjà écrites dans `serie11.py`) : coupe les 4 colonnes, **une seule échelle** pour les 4 (hauteur = la pose de repos de face ; une réaction plus haute n'est pas réduite), pieds alignés ; écrit une feuille 6 × 1 : face, face réaction, gauche, gauche réaction, **droite et droite réaction = miroirs** ; catalogue « personnages » avec `colonnes: 6`, `lignes: 1`, `ordre_colonnes`.
- `build_character_frames.gd`, genre **« Pokémon fixe »** (`LOOKS` : `chenipan` → `caterpie`, `aspicot` → `weedle`, `chrysacier` → `metapod`, `coconfort` → `kakuna`) : `idle_down` / `idle_up` = face, `idle_left`, `idle_right` ; `react_<dir>` non bouclée (repos, réaction tenue ≈ 0,6 s, repos), lue telle quelle par `Npc.react()` (aucun code du jeu à changer) ; ni `walk_*` ni `run_*`.
- Un cocon « accroché à un tronc » est posé sur sa case de forêt avec un décalage vertical (`lift`, comme le Roucool de l'auvent de Jadielle) ; l'image ne contient ni tronc ni fil.

#### 2.8.6 Budget des textures : comment la forêt tient

- **Ce que mesure le chiffre du S24** : `PerfCounter tex=` lit `RENDER_TEXTURE_MEM_USED`, la mémoire de **tout le processus**, pas celle de la carte. Le budget de 64 Mo du J7 est un budget **par carte** (mesuré sur Mac, « carte seule »). La Route 2 seule pèse **≈ 15 Mo** (borne haute, 54 images, calcul sur les fichiers de sa scène) ; les 69,3 Mo du T6 du J8 viennent surtout d'ailleurs : interface et combat, **Jadielle préchargée** comme voisine (≈ 25 Mo), et toute carte déjà visitée.
- **Cause trouvée** : `SceneRouter._scenes` garde **chaque carte chargée pour toute la session**, sans jamais rien libérer ; une `PackedScene` retient ses textures. Après une vraie partie Bourg Palette → Route 1 → Jadielle → Route 2 → forêt, toutes ces cartes restent en mémoire (≈ 25 + 13 + 25 + 15 Mo).
- **La carte de la forêt elle-même : ≈ 15 à 19 Mo** (estimation) : elle partage presque toutes les textures de la Route 2 (8 arbres de forêt, sols, hautes herbes, façade du poste ≈ 1,1 Mo, souche, ronces) et en perd plusieurs (pavés, grande pierre, clôtures, panneaux, buissons, rebord) ; elle ajoute ≈ 2,5 Mo de décors et de décalcomanies neufs, ≈ 1,5 Mo de personnages (3 planches de marche + attente ; les Pokémon fixes, < 0,1 Mo) ; ses deux voisines (les postes) partagent **une** enveloppe 960 × 768 (≈ 2,8 Mo). Le nombre d'arbres ne coûte pas de texture (mêmes 8 images), seulement des nœuds (budget ≤ 3 000, tri de visibilité du T18).
- **Stratégie** : (1) **T18 : cache du `SceneRouter` borné** à la carte courante et à ses voisines par warps (les voisines restent préchargées : pas de chargement disque sous le rideau) ; dans la forêt, la mémoire attendue devient ≈ forêt + enveloppe des postes + le socle du processus (≈ 25–30 Mo d'interface et de combat, **déduit**, à confirmer au T20) ≈ **45–50 Mo**. La Route 2 garde Jadielle comme voisine, elle restera vers 60–70 Mo : ce n'est pas un défaut de la forêt. (2) Aucun nouvel arbre ni planche C par défaut (conditionnel seulement). (3) Si le T20 mesure encore plus de 64 Mo dans la forêt : compression VRAM (ETC2/ASTC) des textures du monde sur Android, à valider par A/B sur S24 (le J7 l'a écartée sur Mac à cause du rendu BPTC, jamais essayée sur le téléphone) ; c'est un choix de rendu, à présenter à Kevin.
- **Mesures** : T19 (Mac) relève la mémoire « carte seule » et le processus après Jadielle → Route 2 → forêt ; T20 (S24) mesure la forêt et la Route 2 dans la même session, après une vraie montée depuis Jadielle.

#### 2.8.7 Commande du T17 (Mac, Codex)

Depuis la copie de la branche, les ancres étant dans le checkout principal :

```bash
ART=/Users/kevinyankam/dev/kanto-2026/build/art python3 tools/art/serie11.py
```

(recadre d'abord les `REF_FJ_*` ; trois générations à la fois ; 13 tâches = 16 images, les planches d'attente partent quand leur marche existe ; une image déjà là n'est pas refaite ; correction = la supprimer ou passer en `_r2`.) Puis : relecture contre la vue et `FJ_KIT_v1.png` ; `python3 tools/art/serie11.py --manifeste` (4 objets, 1 pièce, 1 planche de décalcomanies, 3 personnages, 3 attentes, 4 Pokémon fixes) ; ajouts d'outil du 2.8.5 ; `python3 tools/art/preparer.py --source /Users/kevinyankam/dev/kanto-2026/build/art` (deux fois) ; règles du 2.8.4 et `godot --headless --path . -s res://tools/build_painted_props.gd -- --nouveaux` ; `godot --headless --path . -s res://tools/build_character_frames.gd` ; planche de contact `build/captures/jalon09_assets/`. Risque connu : Codex a déjà refusé un Pokémon (Salamèche, DA.3) ; repli : la planche faite à la main par Kevin dans l'app ChatGPT, comme alors.

---

## 3. Tâches

Branche d'intégration `jalon-09` (cette copie) ; une branche par tâche, chacune dans sa propre copie ; jamais de `pkill`. **Tranche A : ne pas toucher** `game/world/maps/route_2*`, `viridian_city*`, `tools/build_viridian_city.gd`, `tools/build_route_2.gd`, `tools/art/`, `assets/world/`, `game/world/ground/`, `interaction.gd`, `character_look.gd`, `tools/build_character_frames.gd`, `data/encounters/route_2.json`, `data/world/zones.json`, `data/story/objectives.json` (fichiers du J8). Points de contact connus : `npc_roster.gd` / `npc_spec.gd` (J8 : verbe `take` ; J9 : bloc `trainer`) et `interaction_controller.gd` (J9 : défi) — petits, à fusionner à la main ; `jalon-08` est fusionné dans `jalon-09` dès sa fusion dans `main`.

### Tranche A — systèmes (démarre tout de suite)

#### T0 — architecte : alignement et lot de textes système (9A.0)
- Aligner §0 sur `main` ; `docs/design/textes/textes-brouillon-j9.md` : messages de combat du poison (4), de l'évolution (3 + bouton), résultat de l'Antidote (1), description de l'Antidote, 12 descriptions de capacités, 8 descriptions Pokédex, sous-titre et description de la zone, noms affichés (« Garde », « Naturaliste », « Randonneuse »). Rien dans `data/` avant validation (`test_no_draft_in_data`).
- **CA** : lot relu par Kevin (Q-1) ; aucun fichier de `game/` touché.
- **Fait (2026-10-07, branche `j9-t0-textes`)** : §0.3 ; lot écrit, **en attente de la relecture de Kevin**.

#### T1 — architecte : espèces, capacités, Pokédex, sprites provisoires (9A.0) — dépend de T0 (textes)
- §2.5 ; `gen_placeholder_battlers.gd` étendu ; poison **encore** en `pending_effects` (T4 le rend réel).
- Tests : `test_pokemon_data` (8 espèces, évolutions, apprentissages, Raichu par objet), `test_pokedex_library` (8 entrées), `test_evolution` (Chenipan 7, Chrysacier 10, Aspicot 7, Coconfort 10, Pikachu jamais par niveau), `test_encounter_library` (table de la forêt : poids 100, 5 espèces, niveaux, ni Roucool ni Rattata), `test_trainer_library` (5 Dresseurs, montants fixes), `test_battle_stage` (sprite de combat présent pour chaque espèce).
- **CA** : `tools/test.sh` vert, import propre ; aucune carte touchée.
- **Fait (2026-10-07, branche `j9-t1-especes`)** : voir §6.3 (écarts : vocabulaire `pending_effects` existant, données des Dresseurs ici et répliques au T11, zone au T18).

#### T2 — architecte : sauvegarde v4 (9A.1) — parallèle à T0 / T1
- §2.2 ; `Pokemon.status`, `cure_status`, `heal_full` ; `StatusRules` (constantes et `KNOWN` seulement) ; `DebugStart` (`status`) ; `tools/debug_start/save_v4_qa.json` (Salamèche N9 empoisonné, Roucool N7, à Jadielle devant le Centre).
- **CA** : tests §2.2 verts ; `[qa]` au chargement : « sauvegarde v3 → v4 » une fois.
- **Fait (2026-10-07, branche `j9-t2-sauvegarde-v4`)** : voir §6.1 (écarts) ; procédure exacte du T3 au §6.2.

#### T3 — qa-mobile : validation 9A.1 sur S24 → Kevin
- APK actuel (v3) : partie avancée → installer l'APK du J9 → reprise intacte (équipe, Sac, argent, position, Pokédex) ; départ `save_v4_qa` : statut relu après fermeture forcée (journal `[qa]`, fichier `save.json` relevé par `adb`) ; réinstaller l'APK v3 → refus propre, fichier intact.
- **CA** : rapport `build/qa/jalon09_t3/` ; validation de Kevin.

#### T4 — architecte : logique du poison (9A.2) — dépend de T2, parallèle à T8 et T11
- §2.1.1 à §2.1.5 hors affichage : `StatusRules` complet, `MoveEffect.STATUS`, `Battle` (effet, fin de tour, K.O., capture, Antidote), `BattleEvent`, `BattleAI.status_has_effect`, `ItemData.cures`, `ItemUse.NO_EFFECT` / `cure`, `BagQuery`, `BattleText`, messages, données (capacités, Antidote, stock).
- Tests : `test_status_rules`, `test_battle` (Dard-Venin à 30 % sur graine fixe, Poudre Toxik, immunité Poison, déjà empoisonné, dégâts 1/8 en fin de tour, K.O. par le poison → XP et remplacement, statut effacé au K.O., Antidote en combat), `test_capture_calc` (×1,5), `test_item_use` (Antidote : OK, sans effet, K.O.), `test_bag_query`, `test_shop_rules` (Antidote seulement avec `poison_unlocked`), `test_party` (`heal_all` efface le statut), `test_battle_ai` ; reproductibilité recalée (écart 7).
- **CA** : tests verts ; `simulate_first_battle` relancé, écarts expliqués dans le compte rendu.
- **Fait (2026-10-07, branche `j9-t4-poison`, base `jalon-09` à `fe43b08`)** : voir §6.4 (écarts, `simulate_first_battle` identique, contrat pour le T5).

#### T5 — ui-mobile : présentation du poison (9A.2) — dépend de T4
- « PSN » : carte de PV en combat (dès l'envoi), panneau ÉQUIPE du combat, tableau de bord, Équipe, cartes de cible du Sac ; dégât de poison (voile violet + barre + message) ; Antidote dans le Sac (SOINS) et en combat (choix du Pokémon, refus « Sans effet ») ; Boutique (Antidote affiché après `poison_unlocked`).
- Tests : `test_battle_director` (temps de l'empoisonnement et du dégât, étiquette à l'envoi), `test_team_views`, `test_dashboard_views`, cartes ; `tools/capture_poison.gd` → `build/captures/jalon09_poison/` (combat 2340 × 1080 et 1920 × 1080, Équipe, Sac, Boutique) relues.
- **CA** : tests verts, captures relues ; rien dans le monde ne retire de PV.

#### T6 — constructeur-monde : carte et départs de QA (9A.2) — parallèle à T4 (dépend de T1)
- §2.6 ; données des gardes (§2.4.8) et de la table de la forêt.
- Tests : `test_qa_forest_systems` (warps, spawns, herbes de la table forêt, couloir de Théo inévitable par recherche de chemin, sortie vers `from_center`), `test_map_catalog` (`is_qa_map`), `test_zone_library` / `test_map_light_profiles` (cartes `qa_` ignorées), `test_dialogue_data` (gardes mot pour mot), `test_debug_start` (4 nouveaux fichiers).
- **CA** : tests verts, capture de la carte relue.

#### T7 — qa-mobile : validation 9A.2 (poison) sur S24 → Kevin
- `poison_qa` et vraie partie (Jadielle) : parler au garde → Antidote en vente ; Aspicot sauvage empoisonne ; dégâts en fin de tour ; marcher 2 minutes : PV inchangés ; Antidote du Sac et en combat ; Centre et Maman soignent le statut ; défaite d'un Pokémon empoisonné ; capture d'un sauvage empoisonné ; reprise après fermeture forcée.
- **CA** : rapport `build/qa/jalon09_t7/` ; validation de Kevin ; remarques de rendu → « Reportés ».

#### T8 — architecte : logique de l'évolution (9A.3) — parallèle à T4 (dépend de T1)
- §2.3.1, §2.3.2, extraction de `MoveLearnPrompt` (§2.3.4) sans changer le combat, contrat d'`EvolutionDirector` (§2.3.3) et son câblage dans `BattleDirector` (sans écran : un `EvolutionDirector` sans écran fait évoluer sans attendre, pour les tests).
- Tests : `test_evolution` (candidats : debout, niveau gagné, une seule par combat, défaite / fuite → aucun ; `evolve` : capacités de la nouvelle espèce, surnom gardé), `test_battle_director` (inchangé + victoire qui fait évoluer, défaite qui ne fait pas évoluer, ordre bilan → évolution → `battle_finished`), `test_game_state` (Pokédex : vu et capturé, pas d'habitat).
- **CA** : tests verts ; aucun comportement de combat changé (tests existants inchangés).

#### T9 — ui-mobile : écran d'évolution (9A.3) — dépend de T8
- §2.3.3 : `EvolutionScreen`, ARRÊTER + retour Android (chaîne `Boot._screen_back`), silhouettes (artworks officiels), flash, vibration, « Réduire les animations », capacités à l'évolution dans l'écran.
- Tests : `test_evolution_screen` (durées au pas près avec `TweenClock` / `FrameSim`, annulation acceptée pendant la transformation seulement, retour Android, réduction des animations) ; `tools/capture_evolution.gd` → `build/captures/jalon09_evolution/` (début, transformation, fin, annulation) relues.
- **CA** : tests verts, captures relues, durée totale 8–12 s hors lecture des textes.

#### T10 — qa-mobile : validation 9A.3 (évolution) sur S24 → Kevin
- `evolution_qa` : Chenipan → Chrysacier (Armure apprise, Q-5), Aspicot → Coconfort, annulation puis évolution au niveau suivant, Chrysacier → Papilusion, deux évolutions dans le même combat (partage d'XP), Pokédex et Équipe à jour, reprise après fermeture forcée pendant l'écran (l'évolution n'est pas faite tant qu'elle n'est pas finie : vérifier ce qui est sauvegardé).
- **CA** : rapport `build/qa/jalon09_t10/` ; validation de Kevin.

#### T11 — architecte : logique des Dresseurs (9A.4) — parallèle à T4 / T8 (dépend de T1)
- §2.4.1 à §2.4.7 hors bulle : `NpcSpec` / `NpcRoster` (bloc `trainer`), `TrainerRules`, `TrainerEncounter`, `CutsceneStep.EMOTE` (le directeur appelle `Npc.show_emote`, un PNJ sans bulle passe l'étape en 0,6 s), `CutsceneDirector.play_variant`, `TrainerWatcher`, défi par `InteractionController`, branchement dans `Boot` (ordre), données `data/trainers/viridian_forest.json` + `data/dialogues/viridian_forest.json` (5 Dresseurs, mot pour mot).
- Tests : `test_trainer_rules` (vision : ligne droite, obstacle, PNJ, herbes, bord de carte ; approche), `test_trainer_encounter` (étapes vu / à la parole, conditions `beaten_*`), `test_npc_roster` (bloc valide / refusé), `test_cutscene_library` (`emote`), `test_cutscene_director` (`play_variant`, `emote`), `test_trainer_watcher` (intégration sur une petite grille : pas dans la vision → « ! », marche, combat, drapeau ; joueur bloqué → rien ; battu → plus rien ; deux visions → le premier ; **pas de rencontre sauvage sur le pas de la détection**), `test_interaction_controller` (défi à la parole, réplique « après » une fois battu), `test_dialogue_data` (mot pour mot).
- **CA** : tests verts ; le rival de la Route 22 inchangé (`test_rival_route22`).
- **Fait (2026-10-07, branche `j9-t11-dresseurs`)** : voir §6.8 (contrat de `Npc.show_emote` posé, dessin au T12 ; `AWAITING_TRAINERS` à vider au T12).

#### T12 — ui-mobile + constructeur-monde : bulle « ! » et Dresseurs sur la carte de QA (9A.4) — dépend de T11
- ui-mobile : `emote_exclamation.svg`, `Npc.show_emote` (rebond, tenue, fondu ; `UiTokens.EMOTE_*`) ; constructeur-monde : les 5 Dresseurs dans `qa_forest_systems.json` (§2.6), apparence générique.
- Tests : `test_npc` (bulle : durée au pas près, retirée ensuite) ; `tools/capture_trainer_spotted.gd` → `build/captures/jalon09_dresseurs/` (« ! », approche, réplique, prix) relues.
- **CA** : tests verts, captures relues.

#### T13 — qa-mobile : validation 9A.4 (Dresseurs) sur S24 → Kevin
- `trainers_qa` et `trainers_weak_qa` : Théo inévitable, « ! » lisible, approche, répliques avant / après, prix « Tu remportes 72 ₽. » et argent, Milo contourné par l'herbe, Tom défié à la parole, visions croisées, défaite → réveil au Centre, argent intact, Théo redéfie ; battus après rechargement ; évolution après un combat de Dresseur (si 9A.3 est fusionnée).
- **CA** : rapport `build/qa/jalon09_t13/` ; validation de Kevin.

### Tranche B — la forêt (après la fusion du J8 ; T14–T15 peuvent commencer dès le 8.0 validé)

#### T14 — architecte : grille, plan en aplats, prompt (9B.0)
- Aligner ce plan sur `main` après le J8 (warp du poste, objets visibles, forêt serrée, outils `plan_aplats.py` / `plan_check.py`) ; `tools/plans/viridian_forest.txt` (§2.7.1) + positions (Dresseurs, PNJ, objets, Pokémon d'ambiance, portes) ; `plan_check.py` étendu (critères §2.7.1) ; `build/art/PLAN_FORET_JADE_v1.png` ; `tools/art/prompts/CONCEPT_FORET_JADE_VUE_GENERALE_r1.txt` (méthode du J8 §1.3 : plan + vue d'un **autre** lieu comme ancre, `route-2-vue-generale-v1.png` ou `route-1-vue-generale-v1.png` ; ambiance de `foret-jade-etude-ambiance-v1.png` décrite en mots, **sans la joindre** comme plan ; interdits : faune non-Pokémon, Pikachu, eau, bâtiments autres que le poste nord, chemins courbes) ; en-tête « Série 10 — Forêt de Jade » dans la fiche des séries.
- **CA** : `plan_check.py` vert ; plan relu ; aucun fichier de `game/` touché.
- **Fait (2026-10-07, branche `j9-t14-vue-generale`, base `j9-systemes` à `df2d652`)**, **rejoué le même jour après le retour de Kevin** (choix 1 à 6 validés, couloirs élargis : §6.13, « Décisions de Kevin ») : grille 58 × 74 vérifiée (chemin principal **234 pas**, ≥ 2 cases de large partout, 7 cases d'herbes obligatoires toutes dans H3, Théo inévitable vu à 3–4 cases, D2 / D3 / D5 évitables, D4 par 12 cases d'herbes au lieu de 7, aucun objet sur une ligne de vue, aucune approche qui ferme un passage), plan en aplats + version annotée de relecture, prompt r1 (ancre : vue de la Route 2). Écarts et passation : §6.13. **Rien n'est lancé chez Codex : T15 sur validation de Kevin.**

#### T15 — constructeur-monde (Mac, Codex) : vue générale → **validation de Kevin (9B.0)**
- 3 essais au plus ; relecture contre la grille ; `docs/design/reference/foret-jade-vue-generale-v1.png` + `foret-jade-plan-v1.png`, section « Vue générale peinte v1 » du dossier 10.
- **CA** : image validée ; tout changement de composition passe d'abord par la grille (T14 rejoué).
- **Fait (2026-10-07)** : 2 essais (r1, r2) ; **r2 validé par Kevin** → `reference/foret-jade-vue-generale-v1.png` + `foret-jade-plan-v1.png` ; section « Vue générale peinte v1 » du dossier 10 (écrite au T16).

#### T16 — architecte : liste exacte des assets (série 11) — dépend de T15
- Fiches : enveloppe du poste (10 × 8), garde, Scout, naturaliste ; Chenipan, Aspicot, Chrysacier, Coconfort d'ambiance ; tronc incliné, grande souche (emprise), amas de racines, sac posé, arbres des clairières, rais de lumière (décalcomanies) ; promotions éventuelles du J8 (planche de forêt plus sombre) ; règles `PaintedPropRules`.
- **CA** : chaque élément visible de la vue validée a un asset (existant, promu, nouveau) ou est abandonné explicitement.
- **Fait (2026-10-07, branche `j9-t14-vue-generale`)** : liste exacte §2.8 (24 éléments repris tels quels, 7 variations sans asset, **16 images Codex** : 4 décors, 1 planche de sous-bois promue du J8, l'enveloppe des postes, 3 personnages × marche + attente, 4 Pokémon d'ambiance en une planche chacun ; 2 conditionnels ; 4 abandons) ; `tools/art/serie11.py` (références `--refs`, génération, `--manifeste`, planche `--planche`) ; prompts d'attente `tools/art/attente/prompts/{GARDE,SCOUT,NATURALISTE}_ATTENTE.txt` ; fiche « Série 11 » ; stratégie mémoire §2.8.6. Planche de contrôle `build/art/FJ_KIT_v1.png` relue. Écarts : §6.14.

#### T17 — constructeur-monde (Mac, Codex) : série 11 — dépend de T16
- Génération en lumière NE, manifeste, `preparer.py`, `build_painted_props.gd`, `build_character_frames.gd` (garde, Scout, naturaliste : marche + attente ; Pokémon d'ambiance : attente + `react`).
- **Détail et commande : §2.8.7** (16 images, ordre, outillage à ajouter : section `pokemon_fixes` de `preparer.py`, genre « Pokémon fixe » de `build_character_frames.gd`, règles `PaintedPropRules` §2.8.4).
- **CA** : `preparer.py` relancé deux fois ne change rien ; `test_painted_props` vert ; planche contact `build/captures/jalon09_assets/` relue.
- **Fait (2026-10-07, branche `j9-t14-vue-generale`)** : 15 images sur 16 générées du premier coup et relues (tronc incliné, grande souche, racines, sac, sous-bois, coque des postes, garde / Scout / naturaliste en marche + attente, Aspicot, Chrysacier, Coconfort) ; **Chenipan refusé par Codex** (« génération bloquée par le système », comme Salamèche), non relancé : repli = planche faite par Kevin dans l'app ChatGPT (prompt `build/art/prompts/POKE_CHENIPAN_FIXE_NE_r1.txt`, rendu dans le compte rendu). Outillage : section `pokemon_fixes` de `preparer.py` (feuille 6 × 1, une échelle, source absente = sautée), genre « Pokémon fixe » de `build_character_frames.gd` (`FIXED_POKEMON`, `idle_*` + `react_*` non bouclée 0,15 / 0,6 / 0,15 s), 4 règles `PaintedPropRules`, `LOOKS` garde / scout / naturaliste, `test_character_look` (+1 test). Écarts : §6.15.

#### T18 — architecte : fondations de la forêt — parallèle à T15–T17
- `shy` `notice` / `hide` (`NpcSpec`, `NpcRoster`, `AmbientWatcher`, `Npc`), Pokémon d'ambiance sur case de forêt, tri de visibilité de `DenseForest` (paramètre, tests purs), profil `forest` (`lighting.json`), données `data/npcs/viridian_forest.json` (cases de la grille), `data/cutscenes/viridian_forest.json` (6 objets), `zones.json` (§2.7.3, textes validés en Q-1), `tools/debug_start/viridian_forest.json` (équipe N8–10, entrée sud) ; **cache de cartes du `SceneRouter` borné** à la carte courante et à ses voisines par warps (§2.8.6 : aujourd'hui, toute carte visitée reste en mémoire avec ses textures).
- Tests : `test_ambient_rules` / `test_ambient_watcher` (`notice`, `hide`), `test_dense_forest` (tri de visibilité), `test_lighting_library`, `test_cutscene_library` (objets), `test_zone_library`, `test_scene_router` (cache : après A → B → C, seules C et ses voisines restent ; retour vers une voisine sans rechargement disque).
- **CA** : tests verts ; aucune carte touchée.
- **Fait (2026-10-07, branche `j9-t18-fondations`, base `jalon-09` à `53d6d60`)** : `shy` `notice` / `hide` (`Npc.retreat`, `AmbientWatcher.play_reaction` partagé avec l'étape `scare`), Pokémon d'ambiance immobile sur case de forêt (déjà accepté, désormais testé) et **Pokémon d'ambiance sans planche sauté sans erreur** (`GameMap.awaits_painted_look` : Chenipan), tri de visibilité `DenseForest.cull_hidden` (pur, caméra bornée à la carte), profil `forest`, données de la forêt (PNJ, objets, dialogues, zone, départ), **cache de cartes borné** (`SceneRouter._trim_cache`). Mémoire des textures des cartes retenues sur Bourg Palette → Route 1 → Jadielle → Route 2 : **84,4 Mo → 27,1 Mo** à l'arrivée sur la Route 2. Écarts et passation au T19 : §6.16.

#### T19 — constructeur-monde : la forêt et les postes (9B.1) — dépend de T17, T18
- `tools/build_viridian_forest.gd` (§2.7.4), `_forest_gate(side)` (§2.7.2), warp du poste dans `route_2` (une ligne de l'outil + le nœud), retour `from_forest_gate`, « ROUTE 2 NORD — À venir » ; Dresseurs posés aux cases de la grille (sans leur vie : T21).
- Tests : **`test_viridian_forest`** (taille, profil, warps et spawns, critères §2.7.1 sur la vraie grille, cases d'objets cachés sur herbe rase, aucune case praticable sous une cime, nœuds ≤ 3 000), `test_forest_gates` (deux scènes de la même définition, gardes, portes), `test_map_links`, `test_route_2` (porte vers le poste, plus de « À venir »), `test_coming_soon` (porte nord), `test_encounter_director` (H1–H4) ; `tools/capture_viridian_forest.gd` (entrée, tronc incliné, H3, souche, clairière, poste nord) relue contre la vue générale ; `[perf]` Mac.
- **CA** : tests verts, import propre, captures 2340 × 1080 relues.
- **Fait (2026-10-08, branche `j9-t19-foret`, base `jalon-09` à `cd18164`)** : base vérifiée d'abord (3 243 / 3 244, seul échec un « Parameter "t" is null » intermittent de `test_settings_screen`, sans lien, vert ensuite) ; `tools/build_viridian_forest.gd` (carte 58 × 74, **2 683 nœuds**), `_forest_gate(side)` dans `tools/build_painted_interiors.gd` (`--foret`) → deux postes, `data/npcs/viridian_forest_gate_{south,north}.json`, porte de la Route 2 vers le poste sud (`FOREST_GATE_RETURN` puis les trois constantes), « ROUTE 2 NORD — À venir » sur la porte nord du poste nord, `DenseForest.place_sprites` (repli `Sprite2D`), zone et lumière, listes d'attente vidées ; **3 266 tests verts**, import propre ; captures `build/captures/jalon09_t19/` relues ; `[perf]` Mac et temps de chargement. Écarts et procédure du T20 : §6.17.

#### T20 — qa-mobile : validation 9B.1 sur S24 → Kevin
- Vraie partie (Route 2 → poste sud → forêt → poste nord → « À venir » → retour) et départ `viridian_forest` ; traversées **directe et attentive chronométrées avec rencontres et combats** (arbitrage 4 : 7–9 min, 15–20 min) ; fps (moyenne, creux), mémoire des textures, temps de changement de carte, taille de l'APK.
- **CA** : rapport `build/qa/jalon09_t20/` ; validation de Kevin ; géométrie ajustée **seulement** si le rythme réel l'exige (arbitrage 4).

#### T21 — constructeur-monde (+ ui-mobile en relecture) : la vie de la forêt (9B.2)
- Dresseurs (répliques, visions vérifiées sur la vraie carte), P1 / P2, gardes, Pokémon d'ambiance, 6 objets, rais de lumière et particules ; relecture ui-mobile (PRENDRE, toasts, « ! », Carte, Pokédex « Forêt de Jade »).
- Tests : `test_viridian_forest_life` (objets : Sac, `found_items`, drapeaux, retrait immédiat et au rechargement ; cachés : narration puis toast, une fois ; Dresseurs : battus mémorisés ; routines hors herbes et hors visions), `test_viridian_forest` étendu (D1 inévitable, D2/D3/D5 évitables, D4 par l'herbe, sur la vraie scène avec les PNJ).
- **CA** : tests verts, captures relues.
- **Fait (2026-10-08, branche `j9-t21-vie`, base `jalon-09` à `01ed931`)** : données du T18 vérifiées **sur la vraie carte** (cases, orientations et visions = la grille ; textes mot pour mot du dossier 10 ; aucune donnée à corriger) ; rais de lumière réglés (teinte plus orangée, rai α 0,3, taches du sentier × 0,55) et **particules** (3 rais : C3, C1, C2 ; 9 grains chacun, additifs) ; **`test_viridian_forest_life`** (12, nouveau : objets visibles et cachés, Dresseur battu mémorisé, PNJ, Aspicot, rais) et **`test_viridian_forest`** étendu (+4, sur la vraie scène avec les PNJ) ; **3 282 tests verts**, import propre ; captures `build/captures/jalon09_t21/` (2340 × 1080) relues ; relecture ui-mobile : défauts au §6.18. Procédure de la QA finale T22 : §6.18.

#### T22 — qa-mobile : validation 9B.2 et QA finale du J9 → Kevin
- Partie réelle sans drapeau de débogage, de Jadielle au poste nord : garde (poison, Boutique), Théo, Insecte, évolutions, objets, PNJ, ambiance, défaite au milieu (retour à Jadielle), sauvegarde et reprise dans la forêt, durées mesurées.
- **CA** : rapport `build/qa/jalon09_t22/` ; validation de Kevin ; fusion de `jalon-09` dans `main`.

#### T23 — architecte : clôture
- Retirer `qa_forest_systems` (scène, outil, PNJ, `maps` de la table, départs de QA devenus inutiles) ; `etat-projet.md` ; lot de textes ; passation au J10 (porte nord, `pewter_arrived`, réplique du garde nord « depuis Argenta »).

**Parallélisme.** Tout de suite : **T0 ∥ T2**. Après T0 (textes validés) : T1. Après T1 et T2 : **T4 ∥ T6 ∥ T8 ∥ T11** (fichiers disjoints, sauf `battle_director.gd` : T5 et T9 y touchent tous deux → T9 rebasé sur T5, ou l'inverse, jamais en même temps). Puis T5 ∥ T9 ∥ T12 (ui-mobile : un à la fois si une seule session ui-mobile). Une session S24 par sous-jalon (T3, T7, T10, T13, T20, T22). Tranche B : T14 dès le 8.0 validé ; T18 ∥ T15–T17 ; T19 après la fusion du J8.

---

## 4. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Sauvegarde v4** | perte d'une partie, build ancienne qui écrase | migration sans transformation, tests v3 → v4 / refus v3, validation **seule** (T3) |
| **Poison qui devient réel** (Poudre Toxik, Dard-Venin partout, tirage en plus) | équilibrage du rival et de la Route 2 changé, tests à graine fixe décalés | recaler les graines au T4 en expliquant chaque écart ; jamais masquer un test |
| **`BattleDirector` touché par trois tâches** (T5, T8 / T9, extraction de `MoveLearnPrompt`) | conflits, régressions du combat | extraction en premier (T8) avec les tests existants comme filet ; T5 et T9 jamais en parallèle sur ce fichier |
| **Conflits avec le J8** (`npc_roster.gd`, `npc_spec.gd`, `interaction_controller.gd`) | fusions pénibles | ajouts en fin de fichier et de listes ; `jalon-08` fusionné dans `jalon-09` dès sa fusion dans `main` ; liste des fichiers interdits en tranche A (§3) |
| **Ordre des réactions au pas** (scène, Dresseur, rencontre) | combat sauvage pendant une détection, double verrou | branchement ordonné dans `Boot`, test d'ordre (T11) |
| **Performances de la forêt** (≈ 3 à 4 fois les arbres de la Route 1) | fps < 58, chargement lent | tri de visibilité à la construction, budget testé, repli `Sprite2D`, mesures Mac (T19) puis S24 (T20) |
| **Vue générale qui s'écarte de la grille** (courbes, eau, faune) | composition invalide | interdits explicites, 3 essais, la grille fait foi (règle 10) |
| **Théo évitable par accident** (ou D4 évitable sans l'herbe) | leçon des Dresseurs ratée | critère de recherche de chemin sur la grille (T14) **et** la vraie scène (T19, T21) |
| **Évolution interrompue** (application tuée pendant l'écran) | Pokémon à moitié évolué | `evolve_into` n'est appelé qu'à la fin de la séquence ; aucune écriture avant ; vérifié au T10 |
| **Carte de QA oubliée** | contenu de débogage dans la version finale | préfixe `qa_`, aucun warp vers elle, retrait au T23 (critère de clôture) |
| **Capacités sans effet** (Cage-Éclair, Para-Spore, Ultrason…) | Pikachu N9+ « utilise Cage-Éclair », rien ne se passe | limite connue jusqu'au J11, notée dans `etat-projet.md` |

---

## 5. Questions pour Kevin

**Décisions de Kevin (2026-10-07) : les six recommandations sont retenues.**
- **Q-1** : l'architecte rédige le lot complet au T0 ; Kevin le valide en une seule passe avant verrouillage.
- **Q-2** : bouton « ARRÊTER » visible pendant la transformation + retour Android ; pas de maintien du doigt ; une évolution annulée est reproposée à la prochaine montée de niveau.
- **Q-3** : la réplique « après » est dite immédiatement après la défaite du Dresseur, puis devient sa réplique permanente quand on lui reparle.
- **Q-4** : le garde sud interpelle le joueur automatiquement, **une seule fois**, au premier passage vers la forêt ; cette interaction pose `poison_unlocked` ; ensuite PNJ normal (interaction volontaire).
- **Q-5** : Chrysacier et Coconfort apprennent Armure à l'évolution (modernisation assumée).
- **Q-6** : 1/8 des PV max par tour, Dard-Venin 30 %, Poison et Acier immunisés, capture ×1,5 sur une cible empoisonnée. **Hors combat : aucune perte de PV en marchant** ; le statut reste jusqu'à un Antidote ou un soin au Centre (dossier 10).
- Découpage 9A (systèmes, parallèle au J8) → 9B (forêt, après fusion du J8) validé ; **9A.1 (sauvegarde v4) validée seule sur S24 avant d'empiler le poison**.
- **Point de vigilance de Kevin pour 9A.3** : l'évolution est le premier moment vraiment émotionnel du jeu ; même simple au J9, elle ne doit **jamais** avoir l'air d'un écran technique provisoire. Le J11 l'enrichit, mais la première version doit déjà être satisfaisante (soin particulier au T9 et à la session S24 du T10).

Questions d'origine (conservées pour mémoire) :

- **Q-1 — Lot de textes système du J9.** Le dossier ne couvre pas : messages de combat du poison (« {pokemon} est empoisonné ! », « {pokemon} souffre du poison ! », « {pokemon} est déjà empoisonné ! », « {pokemon} n'est plus empoisonné. »), de l'évolution (« Félicitations ! {pokemon} a évolué en {species} ! », « {pokemon} n'évolue plus. », bouton « ARRÊTER » ; « Quoi ? {pokemon} évolue ! » vient du dossier 04), la description de l'Antidote, 12 descriptions de capacités, 8 descriptions Pokédex (Chenipan → Raichu), le sous-titre et la description de la zone « Forêt de Jade », les noms « Garde », « Naturaliste », « Randonneuse ». *Défaut : l'architecte rédige le lot au T0 (`textes-brouillon-j9.md`), dans le ton des textes validés ; tu le valides en une fois (ou ChatGPT le réécrit).* Bloque la fusion des données, pas le code.
- **Q-2 — Annuler une évolution sur un écran tactile.** *Recommandation : un bouton « ARRÊTER » discret, visible seulement pendant la transformation (≈ 5 s), plus le retour Android ; l'évolution est reproposée au prochain niveau gagné (Rouge/Bleu).* Alternative : maintenir le doigt sur l'écran (plus proche du « maintenir B », mais invisible).
- **Q-3 — Réplique « après » d'un Dresseur juste après sa défaite.** *Recommandation : oui, elle est dite une fois tout de suite dans le monde (comme le rival n° 2), puis à chaque fois qu'on lui reparle.* Alternative Rouge/Bleu : rien après le combat, la réplique seulement quand on lui reparle.
- **Q-4 — Le garde sud parle-t-il de lui-même au premier passage ?** `poison_unlocked` s'active à la première conversation (arbitrage 7), mais un joueur pressé peut traverser le poste sans lui parler (pas d'avertissement, pas d'Antidote en Boutique). *Recommandation : oui, une seule fois, comme le premier mot de Maman (mécanisme « auto » existant) ; ensuite on lui reparle si l'on veut.*
- **Q-5 — Chrysacier et Coconfort apprennent-ils Armure en évoluant ?** Rouge/Bleu : non (un Chrysacier issu d'un Chenipan ne connaît que Charge et Sécrétion) ; jeux actuels : oui. *Recommandation : oui (Armure à l'évolution), plus lisible : « il change vraiment ».*
- **Q-6 — Règles du poison.** *Recommandation : règles actuelles* — 1/8 des PV max à la fin de chaque tour, Dard-Venin 30 % (déjà dans les données), types Poison (et Acier) immunisés, statut effacé au K.O., capture ×1,5. Alternative Rouge/Bleu : 1/16 après chaque attaque du Pokémon empoisonné, Dard-Venin 20 %.

Valeurs par défaut notées (règle 4), à corriger d'un mot si besoin :

| Sujet | Défaut |
|---|---|
| Validations | 9A.1 seule (sauvegarde), puis une session par système (9A.2, 9A.3, 9A.4 ; 9A.3 + 9A.4 groupables), 9B.0 sur l'image, 9B.1, 9B.2 |
| Approche du Dresseur | jusqu'à la case voisine du joueur (0 à 4 pas) ; détection type à 3–4 cases par le placement |
| Dresseur | immobile, orientation fixe ; à la parole : ni « ! » ni approche ; vainqueur : redéfie ; reste où il s'est arrêté jusqu'au rechargement |
| « ! » | bulle 0,6 s + 0,3 s de pause |
| Vision | coupée par tout obstacle et tout personnage ; pas par les herbes ni les rebords |
| IA des 5 Dresseurs | `random` (débutants) |
| Défaite contre un Dresseur | réveil au dernier Centre, aucune perte d'argent, Dresseur non battu |
| Prix de l'Antidote | 100 ₽ |
| Évolution | après victoire ou capture seulement, après le bilan ; une par Pokémon et par combat ; ≈ 9 s (1,5 + 5 + 0,7 + révélation) ; artworks officiels et silhouettes ; aucune image nouvelle |
| Pokédex à l'évolution | vu + capturé, sans habitat |
| Poison à l'écran | « PSN » couleur du type Poison ; voile violet 0,35 s au dégât ; aura du dossier 05 au J11 |
| Données | stats actuelles, apprentissages de Rouge/Bleu ; Raichu et la règle « Pierre Foudre » présents, jamais déclenchés |
| Rencontres | `rate` 25, rampe 15 → 20 (Route 1, Route 2) ; ajuster la grille avant le taux |
| Textes du dossier 10 | une réplique « « … » / « … » » = une page, lignes jointes par `\n` |
| Garde nord « depuis Argenta » | variante `if: [pewter_arrived]` (drapeau posé au J10) |
| Postes | une définition, deux scènes générées ; 10 × 8 cases ; rattachés à la zone Forêt de Jade |
| Poste sud vu de la forêt | sortie par le bas de la carte (toit visible selon la vue générale), pas de façade |
| Objectif | « continuer vers le nord. » (J8) jusqu'à Argenta |
| Apparences | une planche `scout` pour les 4 Scouts ; Tom = `youngster` ; randonneuse P2 = `hiker` du J8 ; `guard` et `naturalist` nouveaux |
| Pokémon d'ambiance | Chenipan `notice` (≤ 2 cases, 4 s de répit) ; Aspicot `hide` (1 case) ; « mouvement sans source » non fait |
| Budget | ≤ 3 000 nœuds ; changement de carte ≤ 1,5 × Jadielle ; moyenne ≥ 58 fps, creux ≥ 50 |
| Chemin principal | 220 à 280 pas |
| Carte de QA | `qa_forest_systems`, hors zone, retirée au T23 |

---

## 6. Écarts au plan et contrats (tâches faites)

### 6.1 T2 — sauvegarde v4 (2026-10-07)

Fait comme au §2.2 (`Pokemon.status` / `has_status` / `cure_status`, `heal_full` efface le statut, `StatusRules` réduit à `NONE` / `POISON` / `KNOWN` + `is_known`, `SaveSystem.VERSION = 4`, migration 3 → 4 **sans aucune transformation**, `DebugStart` clé de membre `status`, départ `save_v4_qa`). Écarts et ajouts :

1. **Fixture v3 réelle** : `tests/fixtures/save/v3_kevin_j7_fin.json` = copie exacte de `integ-j7/build/qa/jalon07_final_s21/save_final.json` (la vraie partie de Kevin à la fin de la QA finale du J7, jouée sur le S21 **sans** départ de débogage : Centre de Jadielle (7, 5), Salamèche N8, Roucool, Rattata, Nidoran ♂ N3, 2 100 ₽, Pokédex activé, 72 722 s). Aucune copie de la partie du S24 en v3 n'existe sur le Mac : le T3 la relève (étape 1) et la fait passer sur le Mac avant toute installation.
2. **Départ de débogage qui écrit la sauvegarde** (ajout nécessaire au T3) : un départ de débogage ne lisait ni n'écrivait jamais la sauvegarde, donc « statut relu après fermeture forcée » était impossible. Nouvelle clé racine **`"autosave": true`** (faux par défaut) : le départ **remplace `user://save.json`** (autosave actif pour la session ; Boot l'annonce au journal : « la sauvegarde n'est pas lue, elle sera REMPLACÉE »). Seul `save_v4_qa.json` l'a. Tous les autres départs gardent la garantie d'origine (test existant inchangé).
3. **Journal `[qa]`** (build debug, `Boot._log_loaded_save`) : `[qa] sauvegarde vN → v4` une seule fois, au chargement d'un fichier plus ancien (`SaveSystem.read_version`, version lue avant migration ; `SaveSystem.migration_note`) ; **en plus**, une ligne `[qa] statut relu : <nom> (équipe|stockage <n>) <statut>` par Pokémon ayant un statut, puisque « PSN » n'est affiché qu'au T5.
4. **Statut inconnu ou mal formé** dans un fichier (`"paralysis"`, nombre, `null`…) : Pokémon gardé sans statut + `push_warning` (jamais d'erreur, jamais `.rejected`). Statut absent (v3) : aucun, sans avertissement.
5. `DebugStart` refuse un `status` inconnu (validation stricte comme les autres clés) ; `describe()` affiche `charmander N9 (poison)` et « (remplace la sauvegarde) ».
6. Tests existants recalés sur la v4 (attendus « v3 » → « v4 », comparaisons « rien d'autre ne change » qui ignorent maintenant le `status` vide écrit sur chaque Pokémon) ; `test_upgrade_2_to_3_…` migre explicitement jusqu'à 3.

Valeurs par défaut (règle 4) : `save_v4_qa` = Salamèche N9 empoisonné PV pleins, Roucool N7, 3 Poké Balls, 2 Potions, 3 000 ₽, drapeaux du départ `center_qa` (prologue fait, Jadielle découverte), spawn `from_center` face au sud ; aucun Centre enregistré (point de repos : chez Maman).

### 6.2 Procédure du T3 (qa-mobile, S24, 9A.1 validée seule)

Variables : `PKG=dev.kevin.kanto2026`, `ADB=$HOME/Library/Android/sdk/platform-tools/adb`, `S=$(tools/s24_serial.sh)`, dossier `build/qa/jalon09_t3/`. **Jamais `adb uninstall`** (efface la partie). Lecture d'un fichier : `"$ADB" -s $S shell "run-as $PKG cat files/save.json" > <fichier>` ; écriture : `"$ADB" -s $S shell "run-as $PKG sh -c 'cat > files/save.json'" < <fichier>`.

0. **APK v3 de référence** : construire l'APK de `main` (dernier code qui écrit la v3) dans un worktree dédié (`tools/build_android.sh`), le copier en `build/qa/jalon09_t3/kanto2026-v3.apk`. Vérifier que c'est celui installé sur le S24 (sinon l'installer avec `adb install -r` **avant** l'étape 1, partie de Kevin conservée).
1. **Relevé de la vraie partie (v3)** : `save_v3_kevin_avant.json` ; vérifier `"version": 3`. **Répétition sur le Mac** avant de toucher au téléphone : copier ce fichier dans `~/Library/Application Support/Godot/app_userdata/Kanto 2026/save.json` (après avoir mis de côté celui du Mac), lancer `godot --path . --quit-after 600` depuis la branche du J9 : journal `Sauvegarde chargée : …` puis **une** ligne `[qa] sauvegarde v3 → v4`, aucune erreur ; puis restaurer le fichier du Mac. Si la partie du S24 diffère de la fixture, l'ajouter en `tests/fixtures/save/v3_kevin_s24.json` (copie exacte) et le signaler à l'architecte (test de migration à doubler), sans bloquer.
2. **Migration sur le S24** : `tools/deploy_s24.sh` (APK du J9, sans départ de débogage). Attendus : journal `Sauvegarde chargée : <carte> <case>` et **exactement une** ligne `[qa] sauvegarde v3 → v4` ; reprise intacte à l'écran (même carte, case, orientation ; équipe, PV, ordre ; Sac ; argent ; Pokédex) — captures. Relever `save_v4_kevin_apres.json` : `"version": 4`, chaque Pokémon a `"status": ""`, et **rien d'autre ne change** hormis `version`, `play_time` et les champs que l'autosave met à jour normalement (position si le joueur a bougé) :
   `python3 -c "import json;a=json.load(open('save_v3_kevin_avant.json'));b=json.load(open('save_v4_kevin_apres.json'));[m.pop('status') for k in ('party','storage') for m in b[k]];[d.pop(k) for d in (a,b) for k in ('version','play_time')];print('IDENTIQUE' if a==b else 'DIFF')"` (sans avoir bougé : `IDENTIQUE`). Puis `am force-stop $PKG` et relance (`monkey -p $PKG -c android.intent.category.LAUNCHER 1`) : **aucune** ligne `[qa] sauvegarde` (déjà en v4).
3. **Statut persistant** : relever la partie v4 de Kevin (`save_v4_kevin.json`, sauvegarde de sécurité). `tools/deploy_s24.sh --no-build --debug-start save_v4_qa` : journal `Départ de débogage (…) : viridian_city/from_center, charmander N9 (poison), pidgey N7 (remplace la sauvegarde)` puis `Sauvegarde automatique (changement de carte) : viridian_city …, OK`. Relever `save_qa_1.json` : `party[0].status == "poison"`, `party[1].status == ""`. Faire quelques pas, entrer et sortir du Centre **sans parler à l'infirmière**. Puis `tools/deploy_s24.sh --no-build` (retire le départ, fermeture forcée, relance) : journal `Sauvegarde chargée : …` et `[qa] statut relu : Salamèche (équipe 1) poison`. Encore une fermeture forcée + relance : même ligne. Relever `save_qa_2.json` : toujours `"poison"`, PV de Salamèche **inchangés** (aucun dégât à la marche). Facultatif : soigner au Centre, relancer : plus de ligne `statut relu`, `"status": ""` dans le fichier.
4. **Restauration** de la partie de Kevin : écrire `save_v4_kevin.json` dans `files/save.json`, relancer : reprise identique à l'étape 2.
5. **Refus par la build v3** : relever `save_v4_avant_v3.json` ; `adb install -r -d build/qa/jalon09_t3/kanto2026-v3.apk` puis lancer. Attendus : journal `SaveSystem : sauvegarde d'une version plus récente (4 > 3)` et `Nouvelle partie SANS sauvegarde automatique` ; jouer une minute (changer de pièce, ouvrir le menu, passer en arrière-plan) ; relever `save_v4_apres_v3.json` : **identique octet pour octet** (`cmp save_v4_avant_v3.json save_v4_apres_v3.json`) ; aucun `save.json.corrupt` (`run-as $PKG ls files`).
6. **Retour au J9** : `tools/deploy_s24.sh` (ou `--no-build`) : la partie de Kevin reprend, aucune ligne `[qa] sauvegarde` (déjà v4).
7. Rapport `build/qa/jalon09_t3/rapport.md` (verdict par étape, fichiers relevés, journal `logcat -d -s godot:V`, captures) → **validation de Kevin**.

### 6.3 T1 — espèces, capacités, Pokédex, sprites provisoires (2026-10-07)

Fait comme au §2.5 sur la branche `j9-t1-especes` (base `jalon-09` à `6f649cd`, lot de textes verrouillé) : 8 espèces dans `data/pokemon/species/kanto.json` (valeurs vérifiées sur PokeAPI : statistiques, `base_exp`, `catch_rate`, croissance `medium_fast`, ½ mâles ; apprentissages du groupe `red-blue`), 12 capacités dans `moves.json` (valeurs actuelles), 8 fiches de Pokédex (taille, poids officiels ; textes n° 40 à 50 mot pour mot, notes `caterpie_leaf`, `weedle_curl`, `pikachu_scorch`), `data/encounters/viridian_forest.json`, `data/trainers/viridian_forest.json`, `tools/gen_placeholder_battlers.gd` étendu (17 espèces ; les 9 anciennes images sont régénérées à l'identique). Écarts et précisions :

1. **Vocabulaire `pending_effects`** : celui **déjà employé** dans les données, pas celui du §2.1.2 — `paralysis` / `paralysis_10` / `paralysis_30` (comme Plaquage), `confusion` / `confusion_10`, `hits_2` (comme Double Pied), `multi_hit` (comme Furie), `poison_20` (Double-Dard). Le T4 retire `poison_20` de Double-Dard en même temps que `poison` et `poison_30`, et complète la liste de la doc de `MoveData` (non touchée ici : périmètre « données »).
2. **Données des 5 Dresseurs posées au T1** (`data/trainers/viridian_forest.json`, test `test_trainer_library` demandé ici) ; leurs **répliques** (`data/dialogues/viridian_forest.json`) et le bloc `trainer` des PNJ restent au **T11** (avec `NpcSpec` / `NpcRoster`). Messages génériques de début et de fin gardés (défaut `true`), SAC permis, `prize_money` fixe.
3. **Table de la forêt** : 5 emplacements (un par espèce, niveaux en plage `[3, 5]`, `[4, 6]`, `[4, 5]`), poids 35 / 35 / 13 / 12 / 5. `maps` cite déjà `viridian_forest` et `qa_forest_systems` (aucune des deux cartes n'existe : `EncounterLibrary` ne vérifie pas les cartes, la table attend T6 / T19).
4. **Invariant de jouabilité** (« toute capacité connue aux niveaux des rencontres est pleinement codée ») : **impossible à tenir dans la forêt** — Dard-Venin (Aspicot) attend le T4 et Éclair (Pikachu) garde sa paralysie à 10 % jusqu'au J11. Test dédié `test_forest_wild_moves_only_wait_for_poison_and_paralysis` : seuls ces deux effets manquent ; les dégâts sont joués.
5. **Poudre Dodo** : description « Une poudre soporifique qui endort la cible. Sans effet dans le moteur actuel. » (décision de Kevin du 2026-10-07 ; mention retirée au J11 avec Cage-Éclair, Para-Spore, Ultrason).
6. **Non posés ici** (pas des données du T1) : zone `viridian_forest` (`subtitle` n° 51, `description` n° 52) → **T18** (`data/world/zones.json` est un fichier du J8) ; Antidote et messages du poison → T4 ; textes de l'évolution → T8 / T9 ; « Garde », « Naturaliste », « Route 2 nord » → T6 / T18 / T19.
7. **Combats à graine fixe** : aucun décalage (l'ajout d'espèces ne tire aucun nombre aléatoire de plus ; `test_battle_simulation`, `test_battle` inchangés et verts).
8. **Sprites provisoires** : pixel art 64 × 64 comme les autres (silhouettes simples : chenille, cocons, papillon, larve, guêpe, deux souris), relus sur une planche ; le peint en combat reste au chantier « dos de combat » (hors J9). Test `test_every_species_met_in_battle_has_its_sprites` (`test_battle_stage`) : chaque espèce d'une table de rencontres ou d'une équipe de Dresseur, plus les 8 espèces du J9.

Tests ajoutés ou recalés : `test_pokemon_data` (liste des 32 espèces, 59 capacités, chaînes d'évolution, taux de capture, valeurs et apprentissages de la forêt, capacités et textes mot pour mot, mention « Sans effet » dont Poudre Dodo), `test_pokedex_library` (tailles et poids, notes des 3 formes de base, textes mot pour mot), `test_evolution` (7 et 10, Pikachu jamais par niveau, Raichu par la Pierre Foudre), `test_encounter_library` (table de la forêt : poids 100, 5 espèces, niveaux, ni Roucool ni Rattata), `test_trainer_library` (5 Dresseurs, montants fixes), `test_battle_stage` (sprites).

### 6.4 T4 — logique du poison (2026-10-07)

Fait comme aux §2.1.1 à §2.1.5, **sans aucune présentation** (branche `j9-t4-poison`, base `jalon-09` à `fe43b08`) : `StatusRules` complet (`Inflict`, `can_inflict`, `immune_types`, `end_turn_damage`, `catch_bonus`, constantes Q-6), `MoveEffect.Kind.STATUS` (clé `"status"`, champs `status` et `chance`, validés par `PokemonData`), `Battle` (effet, fin de tour, K.O., capture, Antidote), `BattleEvent` (`STATUS_INFLICTED`, `STATUS_UNCHANGED`, `STATUS_DAMAGED`, `STATUS_CURED` en fin d'enum, champ `status`), `BattleAI.status_has_effect`, `BattleText` + `messages.json` (textes n° 1 à 7 mot pour mot), `ItemData.cures` / `cures_status`, `ItemLibrary` (`cures`), `ItemUse.Check.NO_EFFECT` / `ItemUse.cure`, `ItemUseResult.status_cured` / `gender`, `BagQuery` (refus « Sans effet », résultat n° 14 et 15), données (Poudre Toxik, Dard-Venin 30 %, Double-Dard 20 % ; Antidote n° 11 à 13, 100 ₽ ; stock `if poison_unlocked` après la Potion). Écarts et précisions :

1. **Tirage de l'effet secondaire** : cible déjà K.O. par le coup → **aucun** tirage (même convention que les niveaux de statistiques) ; sinon `roll(100)` si `chance` < 100, **puis** le refus (déjà un statut, type immunisé) est silencieux. Le §2.1.2 plaçait le K.O. après le tirage : l'ordre du moteur existant est gardé.
2. **Un seul statut à la fois** : `Inflict.ALREADY` = n'importe quel statut présent (ordre des vérifications : K.O., immunité, déjà un statut). `STATUS_UNCHANGED` porte le statut **présent** (le modèle `status_unchanged_<statut>` suit donc le statut réel, prêt pour le J11).
3. **Fin de tour** : pour chaque camp, le joueur d'abord, **graine puis poison** (joueur : graine, poison ; adversaire : graine, poison). Aucun tirage.
4. **`status` sur tous les événements** (pas seulement `SENT_OUT`) : l'état du Pokémon au moment de l'événement ; `FAINTED` l'a toujours vide (le K.O. efface le statut **avant** l'événement) ; `STATUS_CURED` porte le statut **effacé**. `to_dict` a un champ `status` (les comparaisons de reproductibilité, symétriques, ne changent pas).
5. **Antidote en combat** : `ITEM_USED` (`amount` 0) puis `STATUS_CURED`, puis le tour adverse ; `BattleText` n'écrit plus « … récupère 0 PV. » quand aucun PV n'est rendu.
6. **Règle d'`ItemUse`** : K.O. → `FAINTED` ; des PV à rendre → OK ; un statut que l'objet soigne → OK ; sinon `FULL_HP` si l'objet rend des PV, `NO_EFFECT` (fin d'enum) s'il ne soigne qu'un statut. Une Potion sur un Pokémon empoisonné à PV pleins reste refusée (« PV déjà au maximum ») et ne soigne jamais le poison. `ItemData.targets_pokemon()` inclut les soins de statut : **le Sac du menu et celui du combat proposent l'Antidote sans changement** de `MenuDirector` ni de `BattleDirector` (choix du Pokémon, refus « Sans effet » / « Cela n'aurait aucun effet sur %s. », retrait unique du Sac).
7. **Accord du résultat du Sac** (« … n'est plus empoisonnée. ») : le sexe vient d'`ItemUseResult.gender`, posé par `ItemUse.apply` ; la signature de `BagQuery.result_text` ne change pas. Les deux phrases sont des constantes de `BagQuery` (`STATUS_CURED_FORMATS`), comme les raisons déjà validées ; les messages de combat sont dans `messages.json`.
8. **`ItemLibrary`** : un soin a `heal_amount` (> 0) **et / ou** `cures` (liste non vide de statuts connus, sans doublon) ; les deux clés sont refusées hors des soins. L'Antidote est rangé après la Potion dans `items.json` (ordre « pertinence » du Sac : Potion puis Antidote).
9. **Vocabulaire `pending_effects`** (doc de `MoveData`) : remplacé par la liste **réelle** des données (`burn_10`, `paralysis*`, `confusion*`, `sleep`, `flinch_10` / `flinch_30`, `trap`, `two_turn`, `charge_def_up`, `rage`, `rampage`, `hits_2`, `multi_hit`, `crit_up`, `force_switch`, `mirror`, `half_hp`, `level_damage`, `ohko`) ; plus aucun `poison`, `poison_20`, `poison_30` (test : aucun `pending_effects` ne commence par `poison`).
10. **Combats à graine fixe : aucun décalage.** `tools/simulate_first_battle.gd` relancé avant / après : sortie **identique** (`diff` vide) — aucun Pokémon simulé (starters N5 du labo ; rival n° 2 : Roucool N7 et starter N8 ; joueur : starter N8 + Roucool ou Rattata N7) ne connaît Poudre Toxik (Bulbizarre N20, Herbizarre N22) ni Dard-Venin (Nidoran N14, Aspicot). `test_battle_simulation` (rival du labo, Route 1, Route 22) et tous les tests de reproductibilité inchangés et verts. Les combats changeront quand ces capacités seront connues (Aspicot de la forêt, Nidoran N14+, Bulbizarre N20+) : c'est voulu (écart 7 du §0.2).
11. **Tests existants recalés** (attendus qui changent légitimement, aucun masqué) : `test_battle_ai` (Poudre Toxik n'est plus « un effet non géré » : le cas utilise maintenant Poudre Dodo), `test_pokemon_data` (Dard-Venin et Double-Dard sans poison en attente ; `test_forest_wild_moves_only_wait_for_poison_and_paralysis` → `…_only_wait_for_paralysis`), `test_item_library` (identifiants avec l'Antidote), `test_shop_library` (stock : sans drapeau, celui du J7 ; avec `poison_unlocked`, l'Antidote).
12. **« Aucune perte de PV en marchant »** : `tests/integration/test_poison_field.gd` sur la vraie scène Boot, **200 pas annoncés** (`Player.moved` émis 200 fois : scènes, rencontres, Pokémon d'ambiance, warps réagissent) plutôt que 200 pas marchés (≈ 50 s de test) ; PV et statut inchangés, puis `heal_all` efface le statut. Rien dans le code n'écoute les pas pour le poison (`StatusRules.end_turn_damage` n'est appelé que par `Battle`).
13. **IA** : « smart » juge Poudre Toxik utile sur une cible saine non immunisée, inutile sinon ; l'effet secondaire de Dard-Venin n'entre pas dans la note d'une attaque (inchangé). « random » (Dresseurs de la forêt) inchangée.
14. **Question pour Kevin (non bloquante)** : poudres sans effet sur les types Plante (règle des jeux depuis la 6e génération, absente de Q-6) ? Défaut : non (Rouge/Bleu) ; sans conséquence au J9 (les seuls Plante rencontrés sont aussi Poison, donc immunisés).

**Contrat pour le T5 (présentation)** :
- `BattlePlayback` : les quatre `STATUS_*` tombent pour l'instant dans la branche par défaut (**messages seulement**). **Jusqu'au T5, la barre de PV ne descend pas au dégât de poison** (elle se recale au prochain `DAMAGE` / `HEAL`, la carte part au `FAINT`) : `STATUS_DAMAGED` doit devenir un temps propre (voile violet ≈ 0,35 s + barre jusqu'à `event.hp` / `event.max_hp`, puis le message), sur le modèle de `DRAINED`.
- « PSN » : `SENT_OUT` porte `event.status` (carte dès l'entrée) ; `STATUS_INFLICTED` pose l'étiquette (camp `event.side`), `STATUS_CURED` la retire sur le Pokémon `event.party_index` (pas forcément en jeu) ; `FAINTED` a `status` vide. Hors combat et panneau ÉQUIPE : lire `Pokemon.status` (`StatusRules.POISON`) dans `BattleViews.party`, `DashboardViews`, `TeamViews`, `PartyTargetView` (via `DashboardViews.member`) → `TeamMemberView.STATUS_POISON` (« PSN »), jamais dans la logique.
- Antidote : déjà jouable (Sac SOINS du menu et du combat, refus « Sans effet », résultat « … n'est plus empoisonné(e). ») ; rien à câbler, seulement à relire en capture.
- Boutique : l'Antidote apparaît dès que `poison_unlocked` est posé (`ShopRules.stock`), rien à câbler. **Rien ne pose encore `poison_unlocked`** (garde sud : T6 / T11) ; pour la capture, poser le drapeau dans un départ de débogage.

### 6.5 T5 : présentation du poison (2026-10-07)

Fait comme au §2.1.3 / §2.1.4 et au contrat du §6.4, branche `j9-t5-poison-ui` (base `j9-t4-poison` à `e38c002`). **Aucune logique de jeu touchée** ; `battle_director.gd` : deux petites fonctions ajoutées (`_play_poison`, `_play_status_tag`) et deux cas dans `_play_beat` (le T9 peut rebaser sans conflit de fond).

- **« PSN »** : `StatusView` (`game/systems/menu/views/status_view.gd`, une seule fonction texte / couleur pour toutes les vues ; `TeamMemberView.STATUS_POISON`) lu par `BattleViews.party`, `DashboardViews.member` (donc `TeamViews`, tableau de bord, cartes de cible du Sac), K.O. prime. Carte de PV du combat : **pastille `TypeBadge` sans icône** (couleur du type Poison, `UiTokens.STATUS_POISON`) à droite du sexe, posée dès l'entrée (`SENT_OUT.status`, aussi au `RELEASE`), par `STATUS_INFLICTED` (camp de l'événement), retirée par `STATUS_CURED` seulement si le Pokémon soigné est en jeu. Listes (Équipe, tableau de bord, cibles du Sac, panneau ÉQUIPE du combat) : texte « PSN » en `STATUS_POISON_TEXT` (`#E08EDD`), le type pur `#A33EA1` ne tenant pas sur fond sombre (contraste testé ≥ 4,5 : 1).
- **Dégât de poison** : `BattleBeat.Kind.POISON` (voile + barre en même temps, comme `DRAIN`, puis le message) et `STATUS_TAG` (instantané) ; `BattleStage.play_poison` : **voile violet 0,35 s** (`STATUS_VEIL_DURATION`), vibration douce 20 ms (`HAPTIC_STATUS_MS`), « Réduire les animations » → voile à moitié. **Écart au plan (« teinte »)** : le voile n'est pas un `modulate` (multiplier du violet par l'orange de Salamèche donne du rouge) mais un petit shader posé sur **le seul sprite** (`status_veil.gdshader`, fond de couleur vers `UiTokens.STATUS_VEIL`, retiré ensuite) ; pas de shader plein écran.
- **Antidote** : relu en capture (Sac SOINS du menu et du combat, choix du Pokémon avec « PSN », refus « Sans effet », résultat) : rien à câbler. Icône de l'Antidote = **sac provisoire** (pas d'icône dédiée dans le jeu) ; noté « Reportés ».
- **Boutique** : Antidote 100 ₽ visible avec `poison_unlocked`. Départ de débogage `tools/debug_start/poison_ui.json` (pose le drapeau).
- **Défauts (règle 4)** : pastille seulement en combat ; voile violet `#B04CC8` à 60 % au pic ; pas d'« aura » (J11).
- **Écart avec la planche** : aucune planche ne montre le statut ; la pastille réutilise le composant de type du jeu (cohérent avec le Pokédex et l'Équipe).
- **Tests** : `test_status_view` (nouveau), `test_battle_playback`, `test_battle_views`, `test_team_views`, `test_dashboard_views`, `test_battle_cards` (pastille, vibration), `test_battle_stage` (voile 0,35 s au pas près, version douce), `test_battle_director` (poison adverse et du joueur sur de vraies parties ; temps POISON en temps simulé : fini quand la barre l'est, voile retiré).
- **Captures** : `tools/capture_poison.gd` → `build/captures/jalon09_poison/` (`2340_*` et `1920_*` : dashboard, team, bag, bag_targets, bag_result, bag_refused, shop, combat_enter, combat_inflicted, combat_veil_own / foe, combat_bag_targets). **Non capturé** : le panneau ÉQUIPE du combat (le script n'arrive pas à l'ouvrir avant le délai : la carte lit le même `status_text`, couvert par test).

### 6.6 T8 — logique de l'évolution (2026-10-07)

Fait comme au §2.3 sur la branche `j9-t8-evolution` (base `jalon-09` à `fe43b08`), sans écran : `Evolution.candidates` / `Evolution.evolve`, `EvolutionCandidate`, `ExpSummary.leveled_indices`, `MoveLearnPrompt` extrait de `BattleDirector`, `EvolutionDirector` + `EvolutionView`, squelette `EvolutionScreen` (le contrat du T9), câblage dans `BattleDirector` (après le bilan, avant la sortie de la vue, verrou gardé) et dans `Boot` (sans écran). Textes du bloc B mot pour mot dans `data/battle/messages.json` (`evolution_started`, `evolution_finished`, `evolution_cancelled`, `evolution_stop`) ; `{species}` ajouté à `BattleText.PLACEHOLDERS` (= nom de l'espèce de l'événement). Journal `[qa] évolution Chenipan → Chrysacier (faite|annulée)`. Écarts :

1. **`MoveLearnPrompt` vit dans `game/battle/`**, pas `game/ui/battle/` : `test_ui_theme` interdit à tout script de `game/ui/` de nommer une classe de logique (`Pokemon`, `PokemonData`, `BattleText`, `BattleEvent`…), et le déroulé en a besoin (comme `BattleDirector`, qui est aussi un nœud de `game/battle/`). Il reçoit le bandeau (`BattleMessageBanner`) et le parent des panneaux (`Control`) en paramètres. Dans le combat, la dernière phrase de l'oubli passe par `banner.show_message` au lieu de `_hud.show_message` : même effet (la zone du bas est déjà MESSAGE à ce moment-là) ; `test_battle_director` **inchangé et vert** (40 tests). `BattleDirector.get_forget_panel()`, `confirm_forget`, `choice_cards_script` gardés (relayés au prompt).
2. **Capacités rendues par `Evolution.evolve`** : celles que la nouvelle espèce apprend **du niveau de la règle au niveau actuel** (pas seulement « au niveau actuel »). Sinon un Chenipan annulé au N7 puis évolué au N8, ou passé de 6 à 10 d'un coup, n'apprendrait jamais Armure, contrairement à Q-5 (et le T10 teste justement « annulation puis évolution au niveau suivant »). Au niveau de la règle, c'est exactement le §2.3.2. Aucun autre changement de jeu : Papilusion n'a rien à l'évolution (Choc Mental au N12), Herbizarre non plus (Fouet Lianes au N13 < 16).
3. **Pokédex : `GameState.record_evolved(into)`** (nouveau : `Pokedex.mark_evolved`, `PokedexEntry.obtain`) au lieu de `record_caught(into, &"")` : vue (première observation si besoin) et **possédée**, datée, sans lieu ni habitat, **sans incrémenter `times_caught`**. Avec `record_caught`, chaque évolution aurait compté comme une capture dans la statistique de carrière « Captures » du Dresseur (`TrainerSummary.capture_count`). Conséquence visible : la fiche d'un Chrysacier obtenu par évolution affiche « capturé 0 fois » (vrai). Aucun changement du format de sauvegarde (`caught: true`, `times_caught: 0` se relit tel quel, testé).
4. **Aucun toast Pokédex à l'évolution** : le signal `recorded` est émis comme pour une capture (`caught = true`), et `PokedexUpdates.classify` ne fait jamais de toast pour une capture (la carte de capture le dit) ; ici, l'écran d'évolution le dit. Le §2.3.2 supposait « toasts existants » : il n'y en a pas pour ce cas. Défaut (règle 4), à changer d'un mot si Kevin veut « Pokédex mis à jour » après l'écran.
5. **Tests du combat qui fait évoluer** dans un fichier à part, `tests/integration/test_battle_director_evolution.gd` (même montage que `test_battle_director`), pour ne pas toucher au filet de l'extraction ni créer de conflit avec T4 / T5 sur ce fichier.
6. **Sans écran** (Boot jusqu'au T9) : l'évolution est appliquée sans rien montrer et une capacité n'est apprise que s'il reste une place (sinon rien : aucun choix fait à la place du joueur). Le T9 branche l'écran par `EvolutionDirector.set_screen` (Boot : `get_evolution_director()`).
7. **Retour Android** : `Boot._on_go_back` appelle déjà `BattleDirector.handle_back()` en premier ; pendant une évolution, celui-ci le passe à `EvolutionDirector.handle_back()` (vrai pendant **toute** la séquence : le geste ne ferme jamais ce qui est dessous) → `EvolutionScreen.handle_back()` (annule pendant la transformation seulement). Aucun changement de `Boot._screen_back`.
8. **Conflit attendu avec le T4** : `BattleText.TEMPLATE_IDS` / `PLACEHOLDERS` et `messages.json` (le T4 y ajoute les messages du poison) — ajouts en fin de liste des deux côtés, fusion à la main.

**Contrat de l'écran (T9 l'implémente, sans changer les signatures)** — `game/ui/evolution/evolution_screen.gd` (`EvolutionScreen extends CanvasLayer`, squelette immédiat sans image posé ici ; le T9 crée `evolution_screen.tscn` avec ce script) :

| Appel (coroutines) | Quand | Ce que l'écran fait (défauts du §2.3.3) |
|---|---|---|
| `open()` | une fois par combat, avant la 1re évolution | fond opaque sombre, l'environnement disparaît |
| `present(view: EvolutionView)` | chaque évolution | ancienne espèce au centre, `view.started_text` ≈ 1,5 s, sans toucher |
| `transform() -> bool` | chaque évolution | silhouettes qui alternent en accélérant ≈ 5 s ; bouton `view.stop_label` visible et actif **seulement** ici ; rend `true` si arrêtée (bouton ou `handle_back`), aussitôt ; `false` arrivée au terme |
| *(le directeur applique l'évolution ici, seulement si `false`)* | | |
| `reveal()` | évolution faite | flash 0,3 s, silence 0,4 s, nouvelle espèce en couleurs, vibration courte (`Haptics`), `view.finished_text`, attente d'un toucher (`view.continue_text`) |
| `revert()` | évolution annulée | retour à l'ancienne espèce en couleurs, `view.cancelled_text`, attente d'un toucher |
| `get_message_banner() -> BattleMessageBanner` / `get_prompt_host() -> Control` | après `reveal()`, une fois par capacité | bandeau des phrases « apprend » / « veut apprendre… » et parent plein écran du `MoveForgetPanel` (placé à `BattleHudLayout.Slot.FORGET`) et de `ChoiceCards` ; null = capacités apprises en silence (place libre seulement) |
| `close()` | une fois, après la dernière | retour à la vue de combat (qui sort ensuite) |
| `handle_back() -> bool` | retour Android, à tout moment | annule pendant `transform()` seulement ; vrai tant que l'écran est ouvert |
| `speed_scale` | relayé avant `open()` | multiplie toutes les durées (`UiTokens.EVOLUTION_*`, à créer) ; 0 = instantané (tests) ; « Réduire les animations » les divise |

`EvolutionView` (données pures, textes déjà remplis, nom **d'avant** l'évolution) : `party_index`, `pokemon_name`, `from_species`, `into_species`, `from_name`, `into_name`, `from_dex`, `into_dex` (→ `PokedexArt.portrait`, `PokedexArt.silhouette_material`), `started_text`, `finished_text`, `cancelled_text`, `stop_label`, `continue_text`. L'écran n'écrit aucun texte de jeu et ne nomme aucune classe de logique (`test_ui_theme`). Signaux du directeur pour le son ou la QA : `evolution_started(party_index, into)`, `evolution_finished(party_index, into, cancelled)`. Toute attente de l'écran par Tween (temps simulé, `TweenClock`) ; le directeur ne mesure aucun temps. Faux écran de test : `tests/helpers/fake_evolution_screen.gd`.

Tests : `test_evolution` (+10 : candidats debout / niveau gagné / ordre de l'équipe / un par combat / défaite et fuite → aucun via `shows_progress`, `leveled_indices`, `evolve` : individu gardé, surnom, PV perdus, PP, Armure au N7, au N8 et au N10, rien sous le niveau de la règle, espèce inconnue), `test_game_state` (+1 : vu et possédé, sans habitat ni capture, aller-retour), `test_evolution_director` (6 : sans écran, ordre du contrat et évolution appliquée après la transformation, textes mot pour mot avec et sans surnom, deux évolutions dans un seul écran, retour Android → annulée puis faite au niveau suivant, offre d'oubli dans l'écran, candidat périmé), `test_battle_director_evolution` (3 : victoire → bilan → évolution, verrou gardé → `battle_finished` ; défaite après une montée de niveau → rien ; retour Android par le directeur de combat).

### 6.7 T9 — écran d'évolution (2026-10-07)

Fait comme au §2.3.3 et au contrat du §6.6 sur la branche `j9-t9-ecran-evolution` (base `j9-t8-evolution` à `7696ccf`) : `game/ui/evolution/evolution_screen.tscn` (CanvasLayer, calque `UiTokens.LAYER_EVOLUTION` = 24, entre l'interface de combat et les transitions) avec `evolution_screen.gd` (signatures du contrat inchangées) et `evolution_rays.gd` ; `Boot` crée l'écran et appelle `get_evolution_director().set_screen(...)`. `battle_director.gd` non touché. Écarts et choix :

1. **Arbre construit en code** (`_ready`), la scène ne porte que la racine : le faux écran des tests du T8 (`fake_evolution_screen.gd`, script seul) appelle `super.open()` / `present()` / `close()` et doit trouver les mêmes nœuds. Aucune nouvelle variation de thème (`ui_theme.tres` inchangé, pas de conflit avec les autres branches) : `WorldCaption` (phrase, nom à 64 px en ACCENT), `ZoneTitleRegion` (consigne), `PanelButton` (ARRÊTER, icône `close.svg`), bandeau `BattleMessageBanner` réutilisé.
2. **Durées** (`UiTokens.EVOLUTION_*`, règle 4) : ouverture 0,5 s + présentation 1,5 s + transformation 5 s + flash 0,3 s + silence 0,4 s + révélation 0,8 s = **8,5 s hors lecture** ; annulation 0,6 s ; fermeture 0,45 s. Chaque phase est **un seul Tween** (temps simulé au pas près) ; l'attente d'un toucher n'a pas de durée (signal). À `speed_scale` 0, tout est instantané et rien n'attend de toucher (tests).
3. **« Réduire les animations »** : l'écran reçoit le `speed_scale` du combat, relayé par `BattleDirector._play_evolutions` → facteur **0,6** (`REDUCED_BATTLE_SPEED`), pas 0,5 comme le Centre. Rien à câbler en plus (le directeur de combat écrase de toute façon la vitesse du directeur d'évolution).
4. **« Réduire les flashs »** (ajout) : `EvolutionScreen.reduce_flashes`, relayé par `Boot._apply_settings` ; sommet du flash 0,3 au lieu de 0,95.
5. **Silhouettes** : matériau existant `PokedexArt.silhouette_material()` **dupliqué** avec la teinte blanche (le partagé reste sombre pour le Pokédex) ; lueur = 5 copies agrandies translucides (aucun flou plein écran). Alternance : `EvolutionScreen.swap_phase(p)` (fréquence a + 3·b·t², intervalle 0,7 s → 0,07 s, ≈ 28 bascules, même motif à toute vitesse) ; première bascule une fois la silhouette pleine.
6. **ARRÊTER** : en bas à droite (320 × 128, à 80 px du bord droit et 64 du bas), visible et actif **seulement** pendant `transform()`, désactivé à l'instant où elle finit ; l'appui vibre (`HAPTIC_TAP_MS`) et rend la main **dans l'appui même** (`transform()` → vrai). Retour Android : même effet pendant la transformation, consommé sans effet ailleurs, faux une fois l'écran fermé.
7. **Toucher pour continuer** : pris seulement une fois la phrase posée (fin de la révélation ou de l'annulation) ; la consigne « Touchez l'écran pour continuer » apparaît à ce moment-là et respire.
8. **Capacités dans l'écran** : bandeau du combat centré en bas (texte centré) ; la phrase et la consigne s'effacent quand le directeur le demande. Panneau d'oubli : à sa place habituelle (`Slot.FORGET`, droite) ; pendant qu'il est affiché, le Pokémon et son nom glissent au milieu de la place libre à gauche (sinon le panneau le couvrait, vu sur capture).
9. **Aucun son** au J9 (pas de musique d'évolution ni de bruitage : rien dans le projet) ; « musique spécifique » du dossier 04 §7 → J11 ou phase audio.
10. Tous les touchers sont pris par le fond de l'écran : rien n'atteint la vue de combat dessous.

Tests : `test_evolution_screen` (12 : ouverture et présentation au pas près, retour Android consommé sans effet pendant la présentation ; transformation au pas près, ARRÊTER visible et actif seulement pendant ; ARRÊTER annule dans l'appui ; retour Android pendant la transformation puis pendant l'attente ; révélation : vibration au bout de flash + silence, flash au sommet, nom, phrase, consigne, toucher ignoré avant la phrase, attente sans limite ; « Réduire les flashs » ; « Réduire les animations » (×0,6) ; durée totale 8–12 s ; alternance qui accélère ; placement tactile ; vitesse 0 ; vrai directeur : « Chrysacier apprend Armure ! » dans le bandeau de l'écran, puis offre d'oubli dans l'écran). `test_evolution_director` (faux écran, désormais sur le vrai script) inchangé et vert. **2 975 tests verts**, import propre.

Captures (2340 × 1080, relues) : `tools/capture_evolution.gd` → `build/captures/jalon09_evolution/evolution_01_ouverture` … `11_oubli` (ouverture, début, silhouette, transformation, flash, silence, révélation, fin, capacité apprise, annulation, oubli). Fond de la capture : Route 1 sous un voile (pas de vrai combat derrière : il est caché par le fond opaque dès 0,5 s).

À voir au doigt sur S24 (T10) : ARRÊTER assez visible mais discret ; retour Android ; lisibilité ; vibration ; 60 fps pendant les bascules rapides et les poussières (CPUParticles2D, 36) ; rendu des artworks agrandis (500 px de cadre pour des sources de 475 px).

### 6.8 T11 — logique des Dresseurs (2026-10-07)

Fait comme au §2.4.1 à §2.4.7 (hors dessin de la bulle) sur la branche `j9-t11-dresseurs` (base `jalon-09` à `fe43b08`) : `NpcSpec` (`trainer_id`, `sight`, `before_dialogue`, `is_trainer()`), bloc `trainer` de `NpcRoster`, `TrainerRules`, `TrainerEncounter`, étape `emote` (`CutsceneStep.Kind.EMOTE` en fin d'enum, clé `"kind"` obligatoire, aussi dans les fichiers de scènes), `CutsceneDirector.play_variant` (`play` y délègue), `TrainerWatcher` (nœud de `boot.tscn`, branché entre le directeur de scènes et l'`EncounterDirector`), défi par `InteractionController.challenge_requested`, `data/dialogues/viridian_forest.json` (10 répliques mot pour mot ; deux lignes = une page jointe par `\n`). Q-3 appliquée (réplique « après » dite tout de suite, puis réplique permanente) ; **aucun Grand moment** pour le premier Dresseur battu (ni drapeau, ni texte : un combat de Dresseur sans `team_by_starter` n'enregistre rien). Écarts et précisions :

1. **Contrat de la bulle posé au T11, dessin au T12** : `Npc.show_emote(kind)` existe déjà (attente en `Tween` de `Npc.EMOTE_DURATION` = 0,6 s, puis `emote_finished` ; `is_emoting()`), **sans rien afficher**. Le directeur appelle toujours `show_emote` et attend `is_emoting()` faux (ou la disparition du PNJ). Le T12 remplit `show_emote` (SVG, rebond, tenue, fondu) **sans changer ce contrat** ; il peut déplacer la durée dans `UiTokens.EMOTE_*` (garder `Npc.EMOTE_DURATION` ou mettre à jour `test_cutscene_director` et `test_trainer_watcher`).
2. **Vision** : `sight_distance` lit l'orientation **des données** (`spec.facing`, fixe) et la case **courante** du PNJ. Une case hors carte coupe la ligne avant tout ; le joueur est reconnu par sa case (le test d'occupation ne s'applique qu'aux cases d'avant). Vision permise **1 à 8** (`TrainerRules.SIGHT_MIN` / `SIGHT_MAX`).
3. **Bloc `trainer` refusé** sans `facing` écrit, sans `dialogue` (réplique « après »), avec un verbe autre que `talk`, ou avec `route`, `look`, `shy`, `idle_react` (clés inconnues du bloc refusées aussi). Les références (`trainer.id` dans `data/trainers/`, `before` et `dialogue` dans `data/dialogues/`) sont croisées par `test_npc_roster` (`test_real_trainers_exist_with_their_dialogues`) sur **tous** les fichiers de `data/npcs/` — vrai à vide tant que le T12 n'a pas posé de Dresseur.
4. **`test_dialogue_data`** : liste `AWAITING_TRAINERS` (les 10 répliques, que **aucun PNJ ne porte encore**) exemptée de « tout dialogue est utilisé ». **Le T12 doit** ajouter `qa_forest_systems` à `MAPS` et **vider** `AWAITING_TRAINERS` (la réplique « avant » d'un Dresseur compte comme utilisée sur sa carte). Le mot pour mot est vérifié contre le dossier 10 sous la forme « « ligne 1 » / « ligne 2 » ».
5. **Identifiant de scène** d'une séquence : `trainer_<id du Dresseur>` (`TrainerEncounter.cutscene_id`), visible dans le journal `[qa] scène « trainer_forest_scout_theo » jouée` et dans `cutscene_started` / `cutscene_finished` (autosave « fin de scène » existant).
6. **Issue `NONE`** (combat refusé : dresseur inconnu, aucun Pokémon valide — impossibles en jeu, les données sont testées et la défaite soigne) : `beaten_*` n'est pas levé, donc l'étape `wake_up unless beaten_*` joue (soin + retour au point de repos). Limite assumée plutôt qu'un drapeau de défaite persistant (un Dresseur vainqueur doit redéfier).
7. **Défi à la parole** : `InteractionController.set_story_flags(flags)` (Boot lui passe `GameState.flags`) ; même anti-rebond que « Rencontrer ». Le PNJ n'est pas tourné par le contrôleur : c'est l'étape `face` de la séquence. Battu : son dialogue (« après ») comme un PNJ ordinaire.
8. **Défaite** : `wake_up` arrête la scène ; au retour sur la carte, le Dresseur (rechargé à sa case de départ) redéfie. Victoire : il reste sur la case voisine du joueur jusqu'au rechargement de la carte.

Tests ajoutés : `test_trainer_rules` (8), `test_trainer_encounter` (6), `test_npc_roster` (+4 : bloc valide, bornes, 16 blocs refusés, données réelles), `test_cutscene_library` (+2 : `emote`), `test_cutscene_director` (+4 : `play_variant`, refus, bulle au pas près, PNJ absent), `test_trainer_watcher` (7, intégration : vu → « ! », approche, regards, répliques, combat, drapeau ; défaite → réveil, redéfie ; hors vision ; joueur bloqué ; deux visions → le premier du fichier ; **aucune rencontre sauvage sur le pas de la détection**, avec témoin ; défi à la parole), `test_interaction_controller` (+2), `test_dialogue_data` (+1, mot pour mot et locuteurs), `test_boot` (+1 : ordre des branchements sur `Player.moved`). `test_cutscene_wake_up` recalé (« react » n'est plus le dernier type : « emote » le suit). `test_rival_route22` inchangé et vert.

**Pour le T12** : (a) dessiner la bulle dans `Npc.show_emote` (contrat ci-dessus) ; (b) poser les 5 Dresseurs dans `data/npcs/qa_forest_systems.json` avec le bloc `"trainer": { "id": "forest_…", "sight": n, "before": "forest_…_before" }`, `"dialogue": "forest_…_after"`, `facing` écrit, aucune routine (visions du §2.6 : Théo vers le bas dans le couloir, Tom vers la gauche, Noé / Milo croisés, Éli au fond) ; (c) `test_dialogue_data` : `MAPS` + `AWAITING_TRAINERS` vidée ; (d) le fichier `data/dialogues/viridian_forest.json` contient les répliques des Dresseurs : les gardes du T6 s'y ajoutent (fusion à la main si T6 l'a créé de son côté).

### 6.9 T6 — carte et départs de QA, gardes (2026-10-07, branche `j9-t6-carte-qa`, base `jalon-09` à `fe43b08`)

Fait comme au §2.6 et §2.4.8, avec les écarts suivants :

1. **Couloir de Théo : il croise la ligne de vue au lieu de la suivre.** Le Dresseur marche jusqu'à la case voisine du joueur (§2.4.2) : dans l'axe d'un couloir d'une case, Théo s'arrêterait devant le joueur et **fermerait le passage pour de bon**. Le couloir (rangée 12, une case de large, de (24, 12) à (8, 12)) passe donc devant une **alcôve** (16, 8..11) où Théo (16, 8, tourné vers le bas, vision 4) tient sa ligne ; détection en (16, 12), 3 cases libres entre eux, et après son approche il reste dans l'alcôve (test : le couloir reste ouvert). Aucun autre chemin vers le nord (test : BFS avec sa ligne bloquée). **Conséquence pour T12 / T19** : ne jamais mettre un Dresseur dans l'axe d'un passage d'une case.
2. **Carte 26 × 20** (le « ≈ 24 × 18 » du plan s'est élargi pour loger les cinq Dresseurs) : zone sud (garde (11, 15), hautes herbes 5 × 4 en (2..6, 15..18), sortie (10..12, 18) PUSH ↓ vers `viridian_city` / `from_center`), couloir, zone nord (clairière de Noé et Milo, Tom, Éli). Tuiles provisoires `OverworldTiles`, aucune lumière, aucun prop.
3. **Cases réservées aux Dresseurs (T12)**, constante `TRAINER_SLOTS` de `tools/build_qa_forest_systems.gd` (et gabarit testé dans `test_qa_forest_systems`) : Théo (16, 8) ↓ vision 4 ; Noé (7, 3) → vision 5 ; Milo (11, 1) ↓ vision 5 (coupée par l'arbre (11, 5) : cases (11, 2..4)) ; Tom (19, 4) ← vision 4 (abordable de côté depuis (19, 3) ou (19, 5)) ; Éli (23, 1) ↓ vision 5. Lignes de Noé et de Milo : un seul croisement, (11, 3). Contournement par les hautes herbes (10..12, 6) (3 cases en plus des 20). **Aucun Dresseur n'est posé** : `data/npcs/qa_forest_systems.json` ne contient que le garde (`south_guard`, apparence `traveler` : hypothèse, « sprite générique »).
4. **Points d'apparition** : `poison_start` (11, 16) ↑ (une case sous le garde), `evolution_start` (7, 17) ← (au bord des herbes), `theo_corridor` (20, 12) ← (4 pas avant la ligne de Théo ; « entrée du couloir » interprétée ainsi). `trainers_qa` et `trainers_weak_qa` partagent `theo_corridor`.
5. **Garde sud « auto » (décision Q-4)** : première variante `auto: true` → il parle **à l'arrivée sur la carte** (mécanisme de Maman, `InteractionController.on_map_entered`), donc dès l'entrée dans le poste sud (T19 : le garde doit être dans le poste, à portée de la case d'arrivée). Le drapeau `poison_unlocked` est posé **à la fin** du dialogue (relevé : faux pendant, vrai après). Sur `poison_qa` il parle donc tout de suite (vérifié en capture) ; les trois autres départs posent `poison_unlocked` d'avance pour qu'il se taise. Test `test_mom_first_variant_is_automatic_and_only_hers` élargi à ce garde.
6. **Dialogues** : `data/dialogues/forest_gates.json` (les deux gardes, speaker « Garde », textes du dossier 10 mot pour mot, une page de 2 lignes par réplique ; test dédié dans `test_dialogue_data`). `forest_gate_north_guard` n'est joué par aucune carte avant T19 (exception `UNUSED_YET`) ; `pewter_arrived` ajouté à `FUTURE_FLAGS` (posé par le J10).
7. **À compléter ailleurs** : **T4** : 2 Antidotes dans `poison_qa`, 1 dans `trainers_qa` (l'objet n'existe pas encore ; `test_shipped_poison_qa_start` échouera à l'ajout de l'objet tant que le Sac n'en contient pas : voulu) ; **T12** : les 5 Dresseurs dans `qa_forest_systems.json` (blocs `trainer`) ; T8 / T9 : rien dans les données (l'évolution se joue sur les départs tels quels).
8. **`MapCatalog.QA_PREFIX` / `is_qa_map`** ; `test_zone_library` et `test_map_light_profiles` ignorent les cartes `qa_`. Aucune zone, aucune découverte au Pokédex/Carte (zone vide). Retrait à la clôture du J9 (T23) : scène, `tools/build_qa_forest_systems.gd`, `tools/capture_qa_forest.gd`, données, départs.

### 6.10 T12 — bulle « ! » et Dresseurs de la carte de QA (2026-10-07, branche `j9-t12-dresseurs-carte`, base `j9-t11-dresseurs` + fusion de `j9-t6-carte-qa`)

Fait comme au §2.4.4, §2.6 et §3 « T12 ». Écarts et précisions :

1. **Bulle** : `assets/ui/icons/emote_exclamation.svg` (pastille jaune `ACCENT`, contour et « ! » `#1C1C1C`, pointe vers le bas) ; `Npc.show_emote` crée un `Sprite2D` « EmoteBubble » (`z_index` 10, devant le tri en profondeur) : apparition en rebond (`TRANS_BACK`, 0,18 s, légère montée), tenue, fondu 0,15 s, retrait immédiat de l'arbre ; durée totale inchangée = `Npc.EMOTE_DURATION` = `UiTokens.EMOTE_DURATION` (0,6 s) : `test_cutscene_director` et `test_trainer_watcher` non modifiés. Réglages dans `UiTokens.EMOTE_*` (échelle 0,7, pointe à 118 px au-dessus des pieds, soit un peu sur le chapeau : valeurs par défaut à juger sur S24).
2. **Limite de cadrage (corrigée, branche `j9-bulle-ecran`)** : la caméra centrait le joueur, un Dresseur à 4 cases au nord (Théo) avait la tête à ~150 px du haut et le haut de la bulle était rogné sur S24 (T12, T13). Correctif : `Npc.show_emote` calcule la position écran de la pointe et décale la bulle du minimum (`EmotePlacement.shift`, logique pure, `game/world/npc/emote_placement.gd`) pour qu'elle reste entière dans la vue, marge `UiTokens.SAFE_MARGIN` (48 px), rebond compris (`UiTokens.EMOTE_OVERSHOOT`) : vers le bas près du haut (la pointe reste sur le Dresseur, la bulle recouvre alors son torse), vers l'intérieur près d'un bord latéral, vers le haut près du bas. Aucun décalage quand il y a la place ; vision (4 cases) et contrat `show_emote` / `is_emoting` / `emote_finished` / `EMOTE_DURATION` inchangés. Captures : `build/captures/jalon09_bulle/{avant,apres}/`. À revoir au doigt au prochain passage S24.
3. **Apparences provisoires** : aucune planche `scout` : les 4 Scouts utilisent `traveler` (peint), Tom `youngster` (peint). Aucun art nouveau.
4. **Données** : 5 PNJ dans `data/npcs/qa_forest_systems.json` sur les cases de `TRAINER_SLOTS`, `facing` écrit, aucune routine. `test_dialogue_data` : `qa_forest_systems` dans `MAPS`, `AWAITING_TRAINERS` supprimée (`UNUSED_YET` reste pour le garde nord).
5. **Fusion** : T6 dans T11 résolue en gardant les deux côtés (`UNUSED_YET`, `GATE_GUARDS`, `pewter_arrived`, `AWAITING_TRAINERS` jusqu'à ce commit ; §6.8 et §6.9).
6. **Capture** : `tools/capture_trainer_spotted.gd` (`--after` : Théo battu par drapeau, réplique « après » ; le combat lui-même n'est pas capturé) → `build/captures/jalon09_t12/`.

Tests ajoutés : `test_npc` (+2 : bulle au pas près, une seule bulle), `test_qa_forest_systems` (+2 : Dresseurs sur leurs cases avec vision, regard et répliques ; aucune vision le long du couloir) ; `test_tom_can_be_reached…` recalé (Éli occupe sa case : on teste la case devant lui).

### 6.11 Intégration de la tranche A sur `j9-systemes` (2026-10-07, base `jalon-09`)

Ordre : `j9-t5-poison-ui` (T4 + T5) en avance rapide ; `j9-t9-ecran-evolution` (T8 + T9) fusionné (`3992772`) ; `j9-t12-dresseurs-carte` (T6 + T11 + T12) fusionné (`e4555ab`). **Rien n'est fusionné dans `jalon-09`** : la tranche attend T3 (9A.1, sauvegarde v4, validée seule), puis T7 / T10 / T13 sur S24 depuis cette branche. Écarts et constats :

1. **Conflits, tous « garder les deux côtés »** : `messages.json` et `BattleText.TEMPLATE_IDS` (poison puis évolution ; `{species}` du T8 présent dans `PLACEHOLDERS`, aucun test n'impose l'ordre) ; `UiTokens` (`STATUS_*` / `HAPTIC_STATUS_MS` puis `LAYER_EVOLUTION` / `EVOLUTION_*` ; `EMOTE_*` du T12 sans conflit) ; `tools/debug_start/README.md` (`poison_ui` du T5 et départs du T6) ; ce document (§6.4 à §6.10 renumérotés, renvois corrigés) et `etat-projet.md`. `battle_director.gd` fusionné sans conflit : `_play_poison` / `_play_status_tag` (T5) dans la lecture des événements, `_play_evolutions` (T8) après le bilan, indépendants. `boot.gd` (T9 : écran d'évolution ; T11 : `TrainerWatcher`) fusionné sans conflit.
2. **Garde-fou du T6 déclenché comme prévu** (`test_shipped_poison_qa_start` : l'Antidote existe désormais) : `poison_qa` reçoit **2 Antidotes**, `trainers_qa` **1** (§6.9, point 7 : fait) ; `test_debug_start` vérifie les quantités ; README à jour (plus de « à compléter », Dresseurs posés, évolutions jouées).
3. **Contrôles croisés** (`tests/integration/test_forest_systems_together.gd`, vraie scène Boot sur `qa_forest_systems`, graines cherchées sur le moteur pur) : l'Aspicot du Scout Noé **empoisonne bien** en combat de Dresseur (Dard-Venin, dégât de fin de tour, statut gardé après le combat : un Dresseur ne soigne pas) ; une victoire contre le Scout Théo qui fait passer Chenipan au N7 donne l'ordre **réplique « avant » → bilan → évolution (Chrysacier) → fin du combat → réplique « après »** (l'évolution est jouée dans `BattleDirector.run_request`, avant que l'étape BATTLE de la scène rende la main) ; un Chenipan **empoisonné** qui évolue **reste empoisonné** ; `trainers_qa` et `poison_qa` portent leurs Antidotes. Aucun défaut révélé : les trois systèmes se composent sans code d'intégration. **3 101 tests verts** (5 ajoutés), import propre.

### 6.12 Fusion de `jalon-09` (J8 terminé, Menu Dresseur MM.0–MM.3) dans `j9-systemes` (2026-10-07)

`jalon-09` à `5f25495` (qui contient `main` : Route 2 et Menu Dresseur) fusionné dans la branche d'intégration de la tranche A. Conflits, tous « garder les deux côtés » : `UiTokens` (poison et évolution, puis verre du Menu Dresseur MM.1 / MM.2) ; `test_dashboard_views` (Pokémon de tête « PSN », puis badges et numéro du Pokédex du MM.1) ; `test_dialogue_data` (dossiers 10 **et** 11 comme sources « mot pour mot », cartes `route_2` et `qa_forest_systems`, drapeaux levés par dialogue : `poison_unlocked` + `route_2_*_talked`) ; README des départs (départs du J9 puis `route_2`) ; `etat-projet.md`. Fusionnés sans conflit : `npc_roster.gd` / `npc_spec.gd` (verbe `take` et bloc `trainer`), `interaction_controller.gd` (TAKE et défi), `boot.gd`, vues d'équipe du menu (« PSN » dans les nouvelles cartes du MM.1). Écarts pour la tranche B : §0.4.

### 6.13 T14 — grille, plan en aplats, prompt de la vue générale (2026-10-07, branche `j9-t14-vue-generale`, base `j9-systemes` à `df2d652`)

Fait comme au §2.7.1 et au §3 « T14 » ; **aucun fichier de `game/` touché**. Fichiers : `tools/plans/viridian_forest.txt` (grille + positions, source unique), `tools/art/plan_check.py` (critères de la forêt, `verifier_foret` ; sans argument, vérifie la Route 2 et la forêt), `tools/art/plan_aplats.py` (`dessiner_foret`, `--annote`), `tools/art/plan_grille.py` et `tests/helpers/plan_grid.gd` (ligne `PRATICABLES`, attributs `cle=valeur`), `tests/unit/test_plan_grid.gd` (5 tests), `tools/art/prompts/CONCEPT_FORET_JADE_VUE_GENERALE_r1.txt`, en-tête « Série 11 » dans `fiches-assets/serie-01-place-jadielle.md`. Rendus (non versionnés) : `build/art/PLAN_FORET_JADE_v1.png` (1024 × 1536, 1 case = 17 px) et `PLAN_FORET_JADE_v1_annote.png` (768 px, Dresseurs et lignes de vue, PNJ, objets, Pokémon d'ambiance, zones, repères ; **jamais joint à Codex**). Le plan de la Route 2 est rendu à l'identique (comparé au pixel près à `reference/route-2-plan-v2.png`).

**Résultat de `plan_check.py`** (plan v1, avant l'élargissement ci-dessous) : chemin principal 240 pas (retour 240) ; H1 42 cases (x 42–48, y 64–69), H2 48 (x 2–7, y 50–57), H3 76 (x 14–30, y 32–39, dont la traversée obligatoire de 7 cases x 14–20 et la bande du détour de Milo), H4 72 (x 5–13, y 10–17) ; 1 444 cases praticables sur 4 292 (34 %).

**Tracé (sud → nord)** : sortie sud (39..40, 73) → **C1** (x 32–48, y 64–71 ; H1 à l'est, O1 dans une baie à l'ouest) → **tronc incliné** (pied (37..38, 63), lisière ouest, juste au-dessus de C1) → couloir nord puis **1re traversée vers l'ouest** (y 56–57, ressaut en x 19–20 vers y 53–54) avec **Théo** dans son alcôve (28, 53) ↓ → au bout, le **cul-de-sac occidental** continue tout droit (H2, Noé, O2 au fond) pendant que le sentier tourne au nord (x 9–10) → **2e traversée vers l'est** (y 47–48) à travers **C2** (x 19–35, y 43–51 : **grande souche** (26..28, 43..44) au fond, O3 derrière elle par le passage d'une case (30, 42), naturaliste, Tom) puis le sentier plonge de 3 rangées et file à l'est (y 50–51) ; **clairière de la randonneuse** en boucle au nord (x 39–46, y 42–46) → montée à l'est (x 49–50) → **3e traversée vers l'ouest** (y 33–34 puis ressaut x 31–32 vers y 35–36) : Milo (25, 32) ↓, **H3**, racines et O4 au bout (5, 35..36) → montée (x 9–10) → **4e traversée vers l'est** (y 26–27) à travers **C3** (x 22–34, y 20–31, **rai de lumière** (26..29, 21..24)), ressaut (x 35–36 vers y 24–25) → montée à l'est (x 47–48), sente vers la clairière d'O5 (nord-est, cul-de-sac) → **5e traversée vers l'ouest** (y 13–14), sente vers la **clairière de H4** (nord-ouest, cul-de-sac) → **parvis** (x 19–32, y 6–11 : Éli, O6) → **porte du poste nord** (25, 5) (emprise x 22–28, y 2–5).

**Écarts et précisions** :
1. **Légende** : la grille n'a qu'un caractère par case ; Dresseurs, PNJ, objets, Pokémon d'ambiance sont dans `POSITIONS` (attribut `role=D1..D5`, `P1`, `P2`, `O1..O6`), pas dans la grille. Le poste nord garde la légende de la Route 2 (`P` emprise, `D` porte) au lieu de `G` (qui veut dire « grand arbre repère » à la Route 2) ; ajouts : `s` petite souche, `g` sortie sud. Cases praticables de la forêt déclarées par la ligne `PRATICABLES .=hCLgD` (`plan_grille.py` et `PlanGrid` : défaut inchangé `.=hvD`, Route 2 identique).
2. **Grand S → serpentin à cinq traversées** : un S à trois traversées ne fait qu'environ 180 à 200 pas dans 58 × 74 ; cinq traversées (ouest, est, ouest, est, ouest) avec trois ressauts orthogonaux donnent **240 pas** (≈ 250 visés, arbitrage 4 : durées mesurées au T20). Les lacets alternent couloirs serrés et clairières (C1, C2, C3, parvis), les détours sont des culs-de-sac lisibles (H2, recoin d'O3, racines d'O4, clairière d'O5, clairière de H4) et deux boucles (clairière de la randonneuse ; clairière de C2 autour de la vue de Tom).
3. **Placement des Dresseurs** (règle du §6.9 : jamais dans l'axe d'un passage d'une case ; contrôlé par recherche de chemin, Dresseur déplacé sur sa case d'arrêt) : **Théo** dans une alcôve d'une case au nord de la 1re traversée, tourné ↓ : sa ligne croise le couloir de 2 cases à 3 et 4 cases de lui (approche de 2 ou 3 pas) ; il est visible bien avant (≈ 30 pas après l'entrée). **Noé** regarde dans H2 (on l'évite en traversant les herbes plus au sud). **Tom** dans C2, au sud du sentier, tourné ↑ : contournable par le nord de la clairière. **Milo** dans une niche au nord de la 3e traversée, tourné ↓ : on l'évite seulement par la bande d'herbes sous le sentier (12 cases d'herbes au lieu de 7). **Éli** au parvis, tourné ←, contournable par la colonne ouest du sentier. Écart avec le tracé ASCII du dossier (logique, pas les cases) : D1 après H1 sur la 1re traversée (et non le long de H1), D5 au parvis (et non entre C3 et H4).
4. **Critères de `plan_check.py` ajoutés au §2.7.1** : carte fermée (seule la sortie sud touche le bord) ; H1, H2, H4 évitables **sans détour** ; vision **entièrement dégagée** (la valeur `sight` est la portée réelle) ; aucun PNJ, Pokémon d'ambiance ni décor sur une ligne de vue ou dans les herbes ; **l'approche d'un Dresseur ne ferme aucun passage** (porte, entrée, objets atteignables depuis chaque case de détection, Dresseur sur sa case d'arrêt) ; O2 inaccessible sans traverser H2 ; O3 par un passage d'une case (deux voisins praticables, repère `passage_o3`) ; repères ordonnés du sud au nord. Les critères « routines hors herbes et hors visions » du T21 sont déjà vérifiés sur la grille. Contrôle négatif fait à la main (Théo tourné ailleurs, Ball sur la vue de Milo, alcôve ouverte, H3 contournée : chaque critère échoue).
5. **Pokémon d'ambiance sur des cases de forêt** (§2.7.6) : `caterpie_2` (21, 33), les deux Aspicot (36, 44) et (21, 22), Chrysacier (18, 44) et Coconfort (8, 51) sont posés sur des cases `T` au bord d'une case praticable (vérifié) ; Chenipan `caterpie_1` (41, 67) et Roucool (14, 9) sur des cases praticables. **T18** : `NpcRoster` / `GameMap` doivent accepter un PNJ non interactif et immobile sur une case de forêt (déjà noté au §2.7.6).
6. **Prompt r1** : ancre de style = `reference/route-2-vue-generale-v1.png` (son tiers haut montre déjà la lisière de la forêt et le même poste ; la vue de la Route 1 est plus éloignée) ; l'étude d'ambiance décrite en mots, non jointe ; lumière « douce et seulement légèrement chaude là où la canopée s'ouvre » (dossier §14) ; grande souche **et pas** un grand arbre vivant (l'étude en avait un) ; interdits du §3 T14 + papillons, panneaux, ponts, clôtures. Personnages montrés : un Scout (Théo), le naturaliste, la randonneuse ; 4 Pokémon d'ambiance. L'ancien prompt du prototype (étude d'ambiance sur tracé provisoire) est renommé `CONCEPT_FORET_JADE_ETUDE_AMBIANCE_r1.txt`.
7. **Pour le T19** (rappel du §0.4) : `build_route_2.gd` → ajouter `FOREST_GATE_RETURN := &"from_forest_gate"` (spawn de la Route 2), puis `FOREST_GATE_SOON = ""`, `FOREST_GATE_MAP = &"viridian_forest_gate_south"`, `FOREST_GATE_TARGET = &"from_route_2"`. Positions de la forêt (grille) : warps `warp_sud_w` / `warp_sud_e` (39..40, 73) PUSH ↓ → `viridian_forest_gate_south`, `from_forest` ; spawn `from_gate_south` (39, 73) ↑ ; warp `warp_poste_nord` (25, 5) STEP_ON ↑ → `viridian_forest_gate_north`, `from_forest` ; spawn `from_gate_north` (25, 6) ↓ ; façade `bldg_poste_foret_01` ancrée sur la porte (25, 5) (emprise 7 × 4 identique à la Route 2). **Pour le T18** : identifiants des PNJ = clés de `data/npcs/viridian_forest.json`, objets `viridian_forest_item_1..6` (drapeaux `got_…`), attributs `facing` / `sight` / `trainer` / `shy` repris tels quels ; `test_viridian_forest` lit la grille avec `PlanGrid` (`attr()`, `walkable`).

**Décisions de Kevin (2026-10-07, sur le plan v1 de ce T14)** : **choix 1 à 6 validés** (serpentin à cinq traversées ; tronc incliné au bord du sentier ; Théo sur la première traversée, dans son alcôve ; Éli au parvis du poste nord ; boucle de la randonneuse et deux culs-de-sac de fin ; longueur ajustée au T20 sur les durées réelles). **Une modification : chemin principal d'au moins 2 cases de large dans les traversées et les montées** (comme la Route 2, 2 à 3 cases), « une expédition, pas un labyrinthe de couloirs » ; les passages d'une case restent réservés aux recoins.
- **Constat** : le sentier (`=`) faisait déjà 2 cases partout ; c'est la forêt collée à ses deux bords qui donnait l'effet de couloir. **Fait** : bandes de sous-bois praticable (`.`, une case) le long de la plupart des traversées et des montées (le passage praticable fait 3 cases, 4 dans les baies), posées seulement sur la forêt ; **aucune au droit de Théo** (x 26–30 autour des rangées 55 et 58) : sa ligne couvre les 2 cases du sentier (28, 56) et (28, 57), il reste inévitable sur toute la largeur. Les autres visions et évitements sont inchangés (Milo : 12 cases d'herbes contre 7 ; Tom, Noé, Éli évitables) ; aucune approche ne ferme un passage.
- **Nouveau critère de `plan_check.py`** : « chemin principal ≥ 2 cases de large » : toute case du sentier (`=`, `g`) appartient à un carré 2 × 2 de terrain praticable, et le trajet le plus court se fait entièrement sur de telles cases (plus la porte) ; contrôle négatif fait (goulet d'une case en (20, 27) : échec). Critère « Théo couvre toute la largeur du sentier ». Recoins d'une case autorisés hors du trajet : `passage_o3`, alcôve de Théo, niche de Milo, sentes vers O5, les racines et H4.
- **Chiffres après élargissement** : chemin principal **234 pas** (les bandes coupent les angles ; 220–280), 1 579 cases praticables (37 %), herbes inchangées (7 obligatoires dans H3), O1 à 14 pas de l'entrée, O6 à 6 pas de la porte. Prompt r1 : description de la largeur du sentier mise à jour (2 pas, bandes de sous-bois, resserré seulement au droit du Scout).

**Commande du T15** (Mac, depuis la copie qui contient la grille ; 3 essais au plus, r2 / r3 = nouveau fichier de prompt, même grille) :

```bash
python3 tools/art/plan_check.py tools/plans/viridian_forest.txt && python3 tools/art/plan_aplats.py tools/plans/viridian_forest.txt
tools/art/generer.sh CONCEPT_FORET_JADE_VUE_GENERALE_r1 tools/art/prompts/CONCEPT_FORET_JADE_VUE_GENERALE_r1.txt build/art/PLAN_FORET_JADE_v1.png docs/design/reference/route-2-vue-generale-v1.png
```

### 6.14 T16 — liste exacte des assets (2026-10-07, branche `j9-t14-vue-generale`)

Fait comme au §2.8 ; **aucun fichier de `game/` touché**, rien lancé chez Codex. Fichiers : `tools/art/serie11.py`, `tools/art/attente/prompts/GARDE_ATTENTE.txt`, `SCOUT_ATTENTE.txt`, `NATURALISTE_ATTENTE.txt`, `tools/art/serie10.py` (titre de la planche paramétrable, sortie inchangée), fiche « Série 11 » de `fiches-assets/serie-01-place-jadielle.md`, section « Vue générale peinte v1 » du dossier 10, roadmap (phase 5). Écarts et décisions :
1. **16 images au lieu d'un kit « 4 images » comme au J8** : la forêt a trois personnages nouveaux (garde, Scout, naturaliste) qui demandent chacun marche + attente, quatre espèces d'ambiance nouvelles, et l'intérieur des postes ; le décor neuf se limite aux trois repères du dossier (tronc, souche, racines), au sac et à une planche de sous-bois (le conditionnel du J8 « mutualisable au J9 », promu : la forêt est tout entière du sous-bois).
2. **Pokémon d'ambiance : une planche de 4 poses chacun, sans planche de marche** (§2.8.5) : 4 images au lieu de 12 ; demande deux ajouts d'outil au T17 (section `pokemon_fixes` de `preparer.py`, genre « Pokémon fixe » de `build_character_frames.gd`), aucun code du jeu (`Npc.react()` lit déjà `react_<dir>`).
3. **Rais de lumière par Godot**, pas par une image (méthode C : la lumière est l'affaire du moteur ; dégradés de quelques Ko, réglables à la capture) ; image peinte additive en conditionnel. Orientation du haut-gauche vers le bas-droite (lumière du jeu), alors que le rai de la vue descend du haut-droite (défaut, règle 4).
4. **Pas de planche de forêt plus sombre** : `DenseForest.Shade` uniforme + poids des essences bleu-vert (paramètres du J8) ; planche C en conditionnel si la répétition se voit.
5. **Abandons** (écarts de la vue) : seconde souche au centre (une seule grande souche, repère central) ; bords de couloir en haies taillées (sous-bois irrégulier, la grille fait foi) ; chicot où pend le Coconfort près du naturaliste (le Chrysacier de la grille est sur un tronc de forêt ordinaire ; un second tronc mort affaiblirait le repère sud) ; arrière du poste sud vu depuis la forêt (la sortie sud est un bord de carte, comme les autres sorties de route).
6. **Enveloppe des postes : ouvertures de 2 cases au centre des murs nord et sud** (défaut : une seule image pour les deux postes ; la sortie sud de la forêt fait 2 cases) ; les warps de chaque poste restent posés par `_forest_gate(side)` au T19.
7. **Mémoire des textures** (§2.8.6) : le chiffre du S24 est celui du processus ; `SceneRouter._scenes` ne libère jamais une carte visitée. Ajouté au T18 : cache borné à la carte courante et à ses voisines (+ test). Estimation de la carte de la forêt : 15–19 Mo.
8. **Le Roucool d'ambiance de la vue est au sol dans la clairière de H4** ; la grille le met sur une branche basse (14, 9) : la grille fait foi (`lift`).
9. **`CLAUDE.md`** : la ligne du dossier 10 doit citer la vue validée ; non modifié par l'architecte (fichier de configuration du projet : à faire par Kevin ou la session principale), texte proposé dans le compte rendu.

### 6.15 T17 : série 11 générée et préparée (2026-10-07, branche `j9-t14-vue-generale`)

Fichiers : `tools/art/preparer.py`, `tools/art/manifeste.json` (16 entrées, `serie11.py --manifeste`), `tools/build_character_frames.gd`, `game/world/props/painted_prop_rules.gd`, `tests/unit/test_character_look.gd`, assets préparés (`assets/world/props/prop_{tronc_incline,grande_souche,racines,sac_rando}_01*`, `assets/world/ground/decals/decal_sousbois_1..8`, `assets/world/interiors/int_poste_foret_coque`, planches `garde` / `scout` / `naturaliste` (+ `_idle`), `aspicot` / `chrysacier` / `coconfort`), scènes `game/world/props/painted/` (4), `SpriteFrames` (`guard`, `scout`, `naturalist`, `weedle`, `metapod`, `kakuna`). Écarts et décisions :
1. **Chenipan refusé par Codex** (une tentative, aucune insistance). Tant que sa planche manque : `preparer.py` saute la source absente, `build_character_frames.gd` saute `chenipan` sans erreur, `test_fixed_pokemon_frames_have_rest_and_reaction` ne teste que les planches présentes (au moins 3). Quand la planche de Kevin arrive : la poser dans `build/art/POKE_CHENIPAN_FIXE_NE_r1.png`, relancer `preparer.py` puis `build_character_frames.gd` (aucun autre changement).
2. **Origine du tronc incliné** : pied mesuré sur l'image préparée (384 × 308) : `Vector2(288, 304)`, bord entre les deux cases `I`. Les règles du §2.8.4 sont reprises telles quelles pour les autres.
3. **`react_<dir>`** : trois images (repos 0,15 s, réaction 0,6 s, repos 0,15 s) ; `idle_up` = face (pas de dos) ; droite = miroir du profil gauche.
4. Aucune des 15 images n'a demandé de seconde génération.

### 6.16 T18 — fondations de la forêt (2026-10-07, branche `j9-t18-fondations`, base `jalon-09` à `53d6d60`)

Base vérifiée d'abord : `tools/test.sh` sur `53d6d60` vert (3 207 tests ; les 3 échecs du relevé venaient de fichiers du T18 modifiés pendant la passe, aucun de la fusion). **Aucune carte touchée.** Fichiers : `game/autoload/scene_router.gd`, `game/world/forest/dense_forest.gd`, `game/world/map.gd`, `game/world/npc/{ambient_rules,ambient_watcher,npc,npc_spec,npc_roster}.gd`, `game/systems/cutscene/cutscene_director.gd` (étape `scare`), `data/world/{lighting,zones}.json`, `data/npcs/viridian_forest.json`, `data/cutscenes/viridian_forest.json`, `data/dialogues/viridian_forest.json` (naturaliste, randonneuse, 6 objets), `tools/debug_start/viridian_forest.json` (+ README), `tools/measure_map_cache.gd` ; tests (**3 238 verts**, import propre) : `test_scene_router` (+4), `test_dense_forest` (+7), `test_ambient_rules` (+1), `test_npc_roster` (+1), `test_lighting_library` (+1), `test_zone_library`, `test_debug_start` (+1), `test_cutscene_data`, `test_dialogue_data`, nouveaux `test_ambient_watcher` (6) et `test_viridian_forest_data` (7), fixture `tests/fixtures/npcs/forest_ambient.json`.

1. **Cache borné** (§2.8.6) : après chaque arrivée (`start`, `start_at`, `change_map`), `_trim_cache` ne garde que la scène de la carte courante et celles de ses voisines par warps (hors « à venir ») ; un préchargement devenu inutile est récupéré puis jeté s'il est fini, sinon laissé en attente (repris au tri suivant ou à la sortie). **Seules les `PackedScene` sont oubliées** : aucune carte instanciée ne vient du cache après coup, la carte courante n'est jamais touchée, l'ancienne carte part comme avant (`queue_free` au changement). Combat, scènes et menus ne gardent qu'un nœud de carte (`CutsceneDirector._map`, `BattleDirector` via `run(…, map)`, Boot via `get_current_map()`), jamais une scène : rien ne perd de référence (test : une instance faite depuis une scène oubliée reste valide et utilisable). Un préchargement fini mais devenu inutile n'est lâché que **deux images plus tard** (`_retired`) : l'initialisation des textures chargées en arrière-plan attend dans la file du RenderingServer, et les libérer avant initialisait une texture déjà libérée (« Parameter "t" is null », vu une fois dans `test_rival_route22` pendant la passe complète). Compteur `disk_loads` et `get_cached_paths()` pour les tests et la mesure. Tests sur une chaîne M1 ↔ M2 ↔ M3 ↔ M4 enregistrée en vraies scènes (`user://`) : après M1 → M2 → M3, seules M2, M3, M4 restent et la scène de M1 quitte le cache de ressources ; retour vers M2 sans lecture disque (seul M1 est relu, en arrière-plan) ; M1 ensuite prise au préchargement.
2. **Mesure (Mac, `tools/measure_map_cache.gd`, deux processus)** — textures des scènes de cartes retenues (RVBA 8 bits, chaque image une fois, par les dépendances) :

| Étape | Avant (tout gardé) | Cache borné |
|---|---:|---:|
| Bourg Palette (+ 3 intérieurs, Route 1 préchargée) | 49,3 Mo | 49,3 Mo |
| Route 1 | 64,6 Mo (6 scènes) | 39,2 Mo (3) |
| Jadielle | 84,4 Mo (10) | 46,4 Mo (6) |
| Route 2 | 84,4 Mo (10) | **27,1 Mo** (2 : Route 2, Jadielle) |

   Le compteur du processus (`RENDER_TEXTURE_MEM_USED`, celui du `PerfCounter` du S24) n'est **pas fiable sur Mac après des libérations** : il suit le chargement avec une étape de retard et passe sous zéro après la libération (valeur absurde relevée à l'arrivée sur la Route 2) ; il atteint 95,5 Mo dans le mode « tout gardé ». La mesure du S24 (T20) dira si le compteur Android a le même défaut ; à défaut, se fier au calcul des dépendances. Dans la forêt, on attend : forêt + enveloppe des postes (≈ 18–22 Mo de cartes) plus le socle de l'interface et du combat.
3. **Tri de visibilité** (§2.7.4) : `DenseForest.visibility_mask` (union des vues de la caméra pour chaque case où se tenir, caméra **bornée à la carte** comme `CameraFraming`, vue 24,4 × 11,25 cases + 1 case de marge, différences cumulées) et `cull_hidden` (garde un arbre ou un buisson si son emprise, 2 cases de part et d'autre du pied et 4 vers le nord, touche une case vue), purs, ordre conservé. Plus juste que « 13 colonnes / 9 rangées de toute case praticable » : près d'un bord, la caméra bornée montre jusqu'à 24 colonnes d'un côté du joueur. **Constat pour le T19** : sur la grille de la forêt, le serpentin passe partout ; avec le plan actuel (graine 1, 9 000 tirages), **1 112 entrées → 1 090 gardées** : le tri ne retire presque rien. Le budget de nœuds (≤ 3 000) ne se tiendra pas par le tri : il dépendra du nombre de nœuds par arbre (`WorldProp` + ombre de contact) ; repli prévu (§2.7.4) : arbres de forêt en `Sprite2D` simples, puis regroupement par tronçons. Note : 9 000 tirages sur 58 × 74 garnissent peut-être moins que sur la Route 1 (plus de buissons de garnissage) ; à juger sur capture.
4. **Pokémon d'ambiance sur case de forêt** : `GameMap` / `GridMover.place` acceptaient déjà un PNJ sur une case solide (occupation sans contrôle de solidité : Roucool de la clôture d'Aoki, Pokémon des tables) ; documenté et testé (la case reste solide, aucun bouton, `lift`). Aucune règle ajoutée : la grille du T14 garantit déjà qu'ils sont immobiles, non interactifs et au bord d'une case praticable (`test_viridian_forest_data`).
5. **`notice` / `hide`** : `notice` = `Npc.react()` (animation `react_<dir>` des planches « Pokémon fixe »), le Pokémon reste, au plus une fois toutes les 4 s (`AmbientWatcher.NOTICE_COOLDOWN`, minuterie en `Tween`, remise à zéro au changement de carte) ; `hide` = `Npc.retreat()` (recul de 24 px vers le haut et fondu en 0,4 s, puis `left_scene` → retiré comme l'envol). Le nom `hide` est celui des données ; la méthode s'appelle `retreat` (`CanvasItem.hide` existe). Un seul geste par action pour le watcher et l'étape `scare` (`AmbientWatcher.play_reaction`). Rayons des données : Chenipan 2, Aspicot 1 (« arrive à une case »), Roucool 2.
6. **Chenipan sans planche** : un Pokémon d'ambiance `pokemon/<espèce>` non interactif sans SpriteFrames (ni peints ni provisoires) est **sauté par `GameMap`** sans erreur (`awaits_painted_look`), au chargement comme dans `refresh_npcs`, au lieu de s'afficher sous l'apparence générique d'un humain. Il apparaît de lui-même quand ses SpriteFrames sont générés (aucun autre changement). Une étape `spawn` de scène n'est pas filtrée (choix explicite d'une scène).
7. **Profil `forest`** (`lighting.json`, valeurs par défaut à régler sur capture au T19) : ombres (0,76 ; 0,86 ; 0,92) bleu-vert, tons moyens (0,88 ; 0,92 ; 0,92) assombris **sans dominante verte**, hautes lumières (1,03 ; 1,0 ; 0,92) chaudes (ouvertures de la canopée) ; soleil haut-gauche (comme les rais, décision de Kevin) ; liseré 0,45, ombre portée α 0,22, contact α 0,66, vent 2,5. **`maps.viridian_forest` n'est pas écrit** : `test_map_light_profiles` exige que toute carte prévue existe → une ligne au T19, avec la carte.
8. **Zone** : `subtitle` « Jadielle — Argenta » et `description` (n° 51–52, mot pour mot) posés ; **`maps` reste vide** pour la même raison (`test_zone_library` exige des cartes existantes) → T19 : `["viridian_forest", "viridian_forest_gate_south", "viridian_forest_gate_north"]` (le test le vérifie dès que la carte existe, avec `region` = sous-titre).
9. **Données de la forêt** (`data/npcs/viridian_forest.json`, clés = identifiants de la grille) : 5 Dresseurs (Scouts `scout`, Tom `youngster`, vision et orientation de la grille) ; naturaliste (`naturalist`, boucle (21..23, 44), pause 2,5 s : il revient sur sa case ouest **en marchant vers l'ouest**, donc tourné vers le tronc du Chrysacier — le `look` est interdit avec une routine) ; randonneuse (`hiker`, apparence de la Route 2, boucle (41..44, 44), pause 1,6 s) ; O1, O2, O5 (PRENDRE, `object/poke_ball_ground`, `unless got_…`) ; 7 Pokémon d'ambiance avec `lift` par défaut (Chenipan sur branche 24 px, Aspicot 32, cocons 40, Roucool 48 : à régler sur capture au T21). Scènes des 6 objets (O1 Antidote, O2 Poké Ball, O3 Potion, O4 Antidote, O5 Poké Ball, O6 Potion), dialogues mot pour mot du dossier 10 (naturaliste et randonneuse « première fois / ensuite » par `forest_naturalist_talked` / `forest_hiker_talked`, 3 narrations d'objets cachés). Départ `viridian_forest.json` (Salamèche 10, Roucool 9, Rattata 8, `poison_unlocked`, sans Antidote, spawn `from_gate_south`).
10. **Listes d'attente à vider au T19** (le test les exige ensuite sur la carte) : `UNUSED_YET` de `test_dialogue_data` (naturaliste, randonneuse, objets ; ajouter `viridian_forest` et les deux postes à `MAPS`) et `AWAITING_MAP` de `test_cutscene_data` (objets cachés 3, 4, 6 ; ajouter `viridian_forest` à `MAPS`, `CODE_PLAYED` garde 1, 2, 5).

**Pour le T19** : déclencheurs des objets cachés (`EventTriggerPoint` → `viridian_forest_item_3/4/6`) aux cases de la grille ; `light_profile = &"forest"` et `region = "Jadielle — Argenta"` sur la racine de la carte ; ligne `maps` de la zone et de `lighting.json` ; appeler `DenseForest.cull_hidden(plan, cases praticables, taille)` après `plan` (gain faible, voir 3) et compter les nœuds ; un Pokémon d'ambiance posé sur une case `T` peut être caché par l'arbre cuit sur la même case : vérifier sur capture, `lift` et ordre de tri (pied du Pokémon au bas de sa case) ; le poste nord est la porte (25, 5) et la sortie sud (39..40, 73) (en-tête de `tools/plans/viridian_forest.txt` corrigé au T18 : il citait encore (27..28, 73) et (29, 6) ; les POSITIONS faisaient foi).

### 6.17 T19 — la forêt et les postes (2026-10-08, branche `j9-t19-foret`, base `jalon-09` à `cd18164`)

Fait comme au §2.7.2, §2.7.4, §2.7.5 et §2.8. Fichiers : `tools/build_viridian_forest.gd` (nouveau), `tools/build_painted_interiors.gd` (`_forest_gate(side)`, `--foret`, sol décrit par un rectangle `floor` + `doors`, passages avec orientation d'arrivée et « à venir »), `tools/build_route_2.gd` (`FOREST_GATE_RETURN`, puis `FOREST_GATE_SOON = ""`, `FOREST_GATE_MAP`, `FOREST_GATE_TARGET`), `game/world/forest/dense_forest.gd` (`place_sprites`, `painted_sprite_model`), scènes `game/world/maps/viridian_forest{,_gate_south,_gate_north}.tscn` et `route_2.tscn` régénérée (seuls le passage du poste et les `unique_id` changent), masque `assets/world/maps/viridian_forest_ground.png`, `data/npcs/viridian_forest_gate_{south,north}.json`, `data/world/{zones,lighting}.json`, outils de capture et de mesure (`tools/capture_viridian_forest.{gd,sh}`, `tools/measure_map_load.gd`, `tools/measure_map_cache.gd` prolongé jusqu'à la forêt). Tests : **`test_viridian_forest`** (22, nouveau), **`test_forest_gates`** (5, nouveau), `test_dense_forest` (+1), `test_route_2` (porte → poste sud), `test_coming_soon` (porte nord du poste nord), `test_map_links` (+3 cartes), `test_encounter_director` (+1, H1–H4), `test_cutscene_data` / `test_dialogue_data` (cartes ajoutées, `AWAITING_MAP` et `UNUSED_YET` vidées). **3 266 tests verts.**

1. **Budget tenu par le repli `Sprite2D` dès le départ** : arbres de forêt, jeunes arbres de garnissage et touffes d'herbes = un `Sprite2D` chacun (`DenseForest.place_sprites` : même image, décalage et matériau de vent que la scène peinte ; rien ne se perd, ces objets n'ont ni emprise ni fondu). Carte : **2 683 nœuds** (≤ 3 000) dont 1 116 arbres et jeunes arbres, 476 touffes, ≈ 1 000 décalcomanies au sol. Le tri de visibilité ne retire presque rien (1 246 → 1 116 avec le garnissage, comme prévu au §6.16) ; les décalcomanies du bord du sentier sont gardées à 40 % (les bandes de sous-bois le bordent déjà). Les 9 000 tirages de `DenseForest.plan` garnissent bien 58 × 74 (aucun trou visible ; vue d'ensemble `ensemble.png`).
2. **Pas de haies taillées** (réserve de la vue validée) : le garnissage des bandes trop étroites pour un arbre (règle du couvert de 3 rangées) était fait des buissons fleuris de Bourg Palette, qui se lisaient en rangées claires, exactement le « labyrinthe de haies » à éviter (première capture). **Remplacés par de jeunes arbres de forêt** (mêmes 8 images, échelle 0,42–0,74, assombris × 0,78–0,92, décalés de ± 0,3 case, 22 % des cases laissées au sous-bois), réduits pour que leur cime ne déborde pas de plus de 0,35 case sur une case praticable au-dessus (plancher 0,4). Testé (`test_undergrowth_shrubs_barely_reach_walkable_cells`). Une bande d'**une** rangée (parvis, rangée 12) reste une rangée d'arbres irrégulière : la grille fait foi.
3. **Planche C (arbres plus sombres) : non lancée.** Sur capture, la forêt ne se répète pas (8 essences, tailles, miroirs, teintes, jeunes arbres) et l'assombrissement uniforme (`Shade` × 0,78, rouge × 0,97, bleu × 1,05, essences 04–06 poids × 2, × 0,72 au cœur) + le profil `forest` donnent la forêt bleu-vert de la vue. À revoir seulement si le S24 dit le contraire.
4. **Rais de lumière posés dès le T19 (simples)** : le §2.8.2 les donnait au T21 ; la capture « clairière au rai » du T19 en avait besoin. `LightRays` : un rai incliné du haut-gauche (`Polygon2D`, couleurs aux sommets, additif, z 5 au-dessus des cimes) et une tache radiale au sol (`GradientTexture2D`, additif) dans C3, plus 4 taches (3 avec un rai faible) sur le sentier (C1, C2, montée est, parvis) ; aucune ombre de canopée près d'eux. **T21** : réglage des intensités, particules (≤ 12 dans 2–3 rais).
5. **Arbres des clairières** (§2.8.1) : 12 arbres repères (`tree_e_01`, `tree_b_01`, `tree_c_01`, `tree_a_01`) au bord **nord** ou sur les côtés de C1, C2, C3, de la clairière de la randonneuse, de H4, d'O5 et du parvis (cime au-dessus de la forêt), moitié moins assombris que la forêt ; 5 objets de lisière (ronces, troncs couchés). Petites souches : miroir et teinte ± 8 %. Positions : défauts (règle 4), constantes `CLEARING_TREES` / `EDGE_PROPS`.
6. **Pokémon d'ambiance sur case de forêt** : seuls les arbres **juste devant** eux sont retirés (± 1,3 case, jusqu'à 2,2 cases plus bas) et aucun jeune arbre dans la case au-dessous : Aspicot, Chrysacier, Coconfort restent « dans » la forêt et se voient (captures `souche.png`, `randonneuse.png`, `clairiere_rai.png`). `lift` des données (T18) **gardés** : lisibles sur capture ; à revoir au T21 avec les réactions. Chenipan (planche absente) est sauté sans erreur (`awaits_painted_look`). Même dégagement pour l'amas de racines d'O4 (sinon caché par la lisière sud).
7. **Le joueur derrière la lisière** : dans les recoins d'une case au nord d'une bande de forêt (racines d'O4, bas de la clairière de la randonneuse), la cime d'un arbre ou d'un jeune arbre au sud couvre ses jambes : c'est le tri en profondeur voulu (« derrière les cimes »), comme sur la Route 2. À juger au doigt sur S24.
8. **Postes** : pièce 10 × 8 (enveloppe `int_poste_foret_coque`), sol (1..8, 2..6), ouverture nord (4..5, 1) et paillasson (4..5, 7), **portes STEP_ON** (la pièce n'a pas de rangée sous le paillasson : on avance d'un pas dessus) ; meubles : meuble bas (1..3, 2), porte-manteau (8, 2), plantes (1, 6) et (8, 6) ; **garde en (7, 4) tourné ←** (défauts). Arrivées : poste sud `from_route_2` (4, 6) tourné ↑, `from_forest` (4, 2) tourné ↓ ; poste nord `from_forest` (4, 6) ↑, `north_door` (4, 2) ↓ (retour de « ROUTE 2 NORD — À venir »). Le garde sud parle à l'arrivée tant que `poison_unlocked` manque (variante `auto` du T6), aussi en revenant de la forêt.
9. **Orientation à l'entrée du poste depuis la Route 2 : ↑** (au lieu de ↓, gardé par le J8 pour le retour de l'écran « à venir ») : `build_route_2.gd` choisit ↓ seulement si la porte est « à venir » ; une ligne de plus que la consigne « seules les constantes changent ».
10. **Sac de la randonneuse** : décor « bloque » de la grille sur une case `C` (45, 44) ; la scène le rend solide par son emprise (la grille logique garde `C`). Le test de grille en tient compte.
11. **Mesures Mac** (`tools/capture_viridian_forest.sh`, plans `perf_*` sans Movie Maker, 2340 × 1080) : 116 à 145 fps une fois chargé, **149 à 175 appels de dessin**, 195 à 236 objets ; mémoire des textures : **cartes retenues dans la forêt = 14,2 Mo** (forêt + deux postes, calcul par dépendances, `measure_map_cache.gd`) contre 15–19 Mo estimés ; compteur du processus 43,7 Mo sur une carte seule. **Changement de carte** (`tools/measure_map_load.gd`, lecture disque + instance + première image, médiane de 5) : Jadielle 384 ms, **forêt 286 ms (0,74 × Jadielle)**, Route 2 257 ms. Le S24 dira les vrais chiffres (T20).
12. **Hypothèses notées** : `display_name` des postes « Forêt de Jade » (leur zone), sans sous-titre ; titre de zone à l'entrée dans le poste sud (il appartient à la forêt, §2.7.3) ; rais posés au T19.

**Procédure du T20 (qa-mobile, S24, 9B.1)** — branche `j9-t19-foret` (ou `jalon-09` après fusion) :
1. `tools/deploy_s24.sh` ; noter la taille de l'APK (`build/kanto2026-debug.apk`).
2. **Vraie partie** (sauvegarde de Kevin, ou départ `route_2` + `poison_unlocked` non posé) : Jadielle → Route 2 → porte du poste (20, 8) → **poste sud** (le garde parle tout de suite si `poison_unlocked` manque ; arrivée tournée vers le nord) → ouverture nord → **forêt** (titre de zone « Forêt de Jade — Jadielle — Argenta ») → traversée jusqu'à la porte du poste nord (25, 5) → **poste nord** (garde : « Encore quelques pas… ») → ouverture nord → **« ROUTE 2 NORD — À venir »** → retour sous l'ouverture, tourné vers le sud → redescendre jusqu'à la Route 2 (vérifier chaque passage dans les deux sens).
3. Départ de débogage `viridian_forest` (`tools/deploy_s24.sh --debug-start viridian_forest`) : traversées **directe** et **attentive** chronométrées avec rencontres et combats (cibles : 7–9 min et 15–20 min, arbitrage 4) ; noter les durées.
4. Lisibilité : sentier et clairières lisibles, jamais « labyrinthe de haies » ; tronc incliné, grande souche, clairière au rai repérables ; joueur derrière les cimes au sud des recoins (point 7) ; Aspicot / Chrysacier / Coconfort visibles ; Dresseurs debout à leurs cases (leurs combats sont le T21, mais Théo inévitable se déclenche déjà).
5. **Perf** : `PerfCounter` fps (moyenne ≥ 58, creux ≥ 50) dans C1, H3, C2, C3 et au parvis ; mémoire des textures (`tex=`) dans la forêt après une vraie montée depuis Jadielle (attendu ≈ 45–50 Mo, §2.8.6) et sur la Route 2 dans la même session ; temps des changements de carte Route 2 → poste → forêt (≤ 1,5 × l'entrée dans Jadielle).
6. Rapport `build/qa/jalon09_t20/` (captures S24 : entrée, tronc, H3, souche, C3, poste nord, intérieurs) ; géométrie ajustée **seulement** si le rythme réel l'exige (arbitrage 4).

### 6.18 T21 : la vie de la Forêt de Jade (2026-10-08, branche `j9-t21-vie`, base `jalon-09` à `01ed931`)

Fichiers : `tools/build_viridian_forest.gd` (rais, particules), `game/world/maps/viridian_forest.tscn` (régénérée : 3 nœuds `RayMotes`, 2 686 nœuds, budget 3 000), `tests/integration/test_viridian_forest_life.gd` (nouveau, 12), `tests/integration/test_viridian_forest.gd` (+4), `tools/capture_viridian_forest.gd` (`--dismiss=n` pour un objet caché trouvé en marchant), `tools/capture_forest_ui_t21.gd` (relecture ui-mobile). **Aucune donnée modifiée** : `data/npcs/viridian_forest.json`, dialogues, scènes d'objets et Dresseurs du T18 étaient justes sur la vraie carte.

1. **Vérifié sur la vraie scène (Boot, sauvegarde en mémoire)** : O1 (Antidote), O2 et O5 (Poké Ball) : PRENDRE → Sac + 1, `found_items` (carte `viridian_forest`), drapeau `got_viridian_forest_item_n`, PNJ retiré tout de suite, case libérée, rien au rechargement, un seul toast, aucune bulle ; O3, O4, O6 : narration (texte verrouillé) puis toast standard (« Potion ×1 / Ajoutée au Sac », « Antidote ×1 / Ajouté au Sac »), une seule fois (on repasse : rien) ; Théo non battu voit le joueur à 4 cases et lance `trainer_forest_scout_theo` ; Théo battu (drapeau sauvegardé, rechargé) ne défie plus et dit sa réplique « après » à la parole, sans combat ; naturaliste et randonneuse : « première fois » (drapeau posé) puis « ensuite » toujours la même ; Aspicot (36, 44) retiré quand le joueur arrive à une case, pas avant.
2. **`test_viridian_forest` sur la vraie scène avec les PNJ** : la vision de chaque Dresseur calculée par `TrainerRules.sight_distance` sur la **vraie grille** = la ligne de la grille du T14, case par case ; aucun PNJ, Pokémon d'ambiance, objet ni case de routine sur une vision ; avec tous les PNJ posés : la porte reste atteignable, **Théo inévitable, Noé, Tom et Éli évitables, Milo évitable seulement par les hautes herbes (12 cases au lieu de 7)** et sans herbes il barre le passage ; **aucun Dresseur ne ferme un passage à sa case d'arrêt** (toutes les distances de détection) ; les routines (naturaliste, randonneuse) hors herbes, praticables, et la porte reste atteignable quelle que soit la case occupée.
3. **Rais (suite du §6.17 point 4)** : lumière `(1,0 ; 0,8 ; 0,46)` (le jaune clair tirait au citron sur l'herbe), rai α 0,22 → 0,30, taches du sentier × 0,55 (l'additif blanchissait le beige) ; particules `CPUParticles2D` dans C3, C1 et C2 : 9 grains (≤ 12), durée 7 s, dérive vers le bas-droite (sens du rai), graine fixe, `preprocess` (déjà en cours à l'arrivée), additifs, z 5 comme le rai. Cohérents avec une forêt plus sombre (note de Kevin) : tout est additif et ne vit que dans les trouées ; assombrir la forêt les fera ressortir sans rien changer. Le profil `forest` n'est pas touché.
4. **Hypothèses (règle 4)** : particules dans C3, C1 et C2 (les trois rais à intensité forte) ; 9 grains ; pas de rai ni de particule ailleurs. `lift` des Pokémon d'ambiance **gardés** (Chenipan 24 sans planche, Aspicot 32, cocons 40, Roucool 48) : lisibles sur capture (Aspicot de C2 sur la lisière, cocons accrochés).
5. **Chenipan d'ambiance** : toujours sans planche, sauté sans erreur (2 des 7 Pokémon d'ambiance : `caterpie_1`, `caterpie_2` ; pas de réaction « notice » visible tant que la planche manque). Sac de la randonneuse : solide par son emprise de scène (case `C` de la grille), vérifié.
6. **Relecture ui-mobile** (`ui_*.png`) : PRENDRE devant O1 : bouton et libellé lisibles, bien placés ; toasts : « Potion ×1 / Ajoutée au Sac » lisible, sans chevauchement avec le titre de zone ; « ! » de Théo : entier à l'écran (décalé par `EmotePlacement`, sa tête est à 5,3 cases au-dessus du joueur : au bord haut) ; Carte : la zone « Forêt de Jade » apparaît (« Tu es ici », 1 zone découverte, description du dossier, Pokémon observés) ; Pokédex : habitat « Forêt de Jade » sur la fiche d'Aspicot. **Défauts notés, non corrigés** : (a) Carte, carte de zone « Pokémon observés » : la rangée est rognée par le bas du cadre au format S24 (les noms Chenipan / Chrysacier / Aspicot sont coupés ; la liste défile) ; (b) l'image de la zone « Forêt de Jade » (bandeau et vignette) est celle d'un décor générique, pas de la forêt ; (c) fiche Pokédex ouverte sur l'onglet Aperçu alors que le panneau Habitat est déjà visible : sans gravité ; (d) le bas du rai (tache) a un bord net horizontal visible de près ; (e) Théo, vision de 4 cases face au joueur : sa tête est à la limite haute de l'écran (le « ! » tient, mais peu de marge) : à juger au doigt.
7. **Captures** (`build/captures/jalon09_t21/`) : `theo_exclamation`, `naturaliste`, `randonneuse`, `objet_cache_narration`, `objet_cache_toast`, `rai_particules`, `aspicot_avant` / `aspicot_retracte` / `aspicot_apres`, `ui_prendre`, `ui_carte_foret`, `ui_pokedex_aspicot`, `ui_pokedex_liste`.

**Procédure de la QA finale T22 (qa-mobile, S24, 9B.2 et fin du J9)** — branche `jalon-09` après fusion de `j9-t21-vie` :
1. `tools/deploy_s24.sh` ; taille de l'APK ; **aucun drapeau de débogage** (sauvegarde de Kevin ou nouvelle partie jouée jusqu'à Jadielle : Centre, Boutique, colis, activation du Pokédex).
2. **Partie réelle de Jadielle au poste nord** : Boutique (acheter un Antidote) → Route 2 → poste sud (le garde interpelle **une fois** et pose `poison_unlocked` ; reparler : rappel de la Boutique) → forêt : **Théo** (inévitable, « ! », approche, combat, réplique « après » tout de suite), Insecte, évolutions (Chenipan / Aspicot au N7, annulation possible), les 6 objets (3 visibles avec PRENDRE, 3 cachés avec narration puis toast), naturaliste et randonneuse (1re fois puis ensuite), Pokémon d'ambiance (Aspicot qui se rétracte à une case, Roucool qui s'envole), rais et particules, Noé / Tom / Milo (par les herbes) / Éli → poste nord (garde) → « ROUTE 2 NORD — À venir ». **Défaite au milieu** : retour au Centre de Jadielle, rien de perdu, le Dresseur battu reste battu et le non battu redéfie. **Sauvegarde et reprise dans la forêt** (objets repris restent retirés, Dresseurs battus restent battus).
3. **Mesures** (restées à faire depuis le T20) : traversées **directe** (cible 7–9 min) et **attentive** (15–20 min) chronométrées avec rencontres et combats ; fps (`PerfCounter`, moyenne ≥ 58, creux ≥ 50) dans C1, H3, C2, C3 (rai et particules) et au parvis ; mémoire des textures (`tex=`, attendu ≈ 45–50 Mo dans la forêt après la montée depuis Jadielle) ; temps de changement de carte Route 2 → poste → forêt (≤ 1,5 × l'entrée dans Jadielle) ; taille de l'APK.
4. **À juger au doigt** : le joueur derrière les cimes dans les recoins (§6.17 point 7) ; la position de Théo en haut de l'écran à la détection ; l'intensité des rais et des particules (ni blancs ni gênants) ; la lisibilité des objets cachés (rien à voir : seulement la narration).
5. Rapport `build/qa/jalon09_t22/` ; validation de Kevin ; fusion de `jalon-09` dans `main`.


## 7. Forêt agrandie (chantier du 2026-10-08, branche `j9-foret-xl`, base `main` à `322d70e`)

**Décision de Kevin (2026-10-08, après la QA finale T22 sur S21)** : la traversée directe mesurée fait **233 pas en 2 min 48 s sans combat** (≈ 0,72 s par pas) ; la cible du dossier 10 (arbitrage 4) est **7–9 min combats compris**. On agrandit la carte : ≈ 58 × 74 → **≈ 70 × 90**, **7 traversées** au lieu de 5, chemin principal **≈ 330–360 pas**, **une 2e zone d'herbes obligatoire courte** en plus de H3, **mêmes repères** (tronc incliné → grande souche → clairière au rai), **mêmes Dresseurs, PNJ et objets**, même DA, **sans nouvelle vue générale**. Un combat de Dresseur obligatoire de plus (en plus de Théo) est accepté **si l'estimation reste sous 7 min** (proposition ci-dessous, §7.3).

Trois étapes : **1. la grille** (ce paragraphe, fait) ; **2. la carte** (§7.5, fait le 2026-10-08) ; **3. QA chronométrée** sur téléphone puis validation de Kevin.

**Décision de Kevin XL-1 (2026-10-08) : Milo devient inévitable** (variante vérifiée au §7.3 appliquée à l'étape 2).

### 7.1 Étape 1 — la grille (fait, 2026-10-08)

Méthode du T14 (§2.7.1, §6.13 et les décisions de Kevin sur la composition) ; **aucun fichier de `game/` touché**. Fichiers :
- **`tools/plans/viridian_forest_xl.txt`** (70 × 90, grille + positions) : **nouveau fichier**, pas une réécriture de `viridian_forest.txt`, parce que la scène actuelle et ses tests (`test_viridian_forest`, `_life`, `_data`, `test_plan_grid`, `test_dense_forest`) lisent la grille du T14 case par case ; **il la remplace à l'étape 2**, dans le même commit que la carte reconstruite et les tests adaptés (`tools/test.sh` reste vert entre les deux).
- **`tools/art/plan_check.py`** : critères de la forêt **par profil** (`FORET_PROFILS` : `viridian_forest` = T14, `viridian_forest_xl` = forêt agrandie) : taille, fourchette de pas (**330–360**), zones d'herbes nommées et **zones obligatoires avec leur fourchette** (H3 6–8, **H5 4–6**, défaut « courte ») : chacune incontournable, minimum d'herbes du trajet = somme des deux, aucune case hors de ces zones ; les autres zones évitables sans détour. Noms des zones par une position `herbes` (`role=H1..H5`, une case dans la zone) ; sans elle, du sud au nord comme au T14. Tous les autres critères inchangés (largeur ≥ 2, Théo inévitable sur toute la largeur, vision dégagée, aucun objet sur une vision, aucune approche qui ferme un passage, O2 derrière H2, O3 par un passage d'une case, repères ordonnés, clairières ≥ 7 × 5…). Nouvelle ligne : **estimation de la traversée directe** (§7.3). Contrôles négatifs faits : H5 contournée par le sous-bois → échec ; H5 à 9 cases → échec.
- **`tools/art/plan_aplats.py`** : grille XL → `build/art/PLAN_FORET_JADE_v2.png` (1 case = 14 px) ; `--annote` nomme les zones par leurs positions `herbes`. Rendus non versionnés : `PLAN_FORET_JADE_v2.png`, `PLAN_FORET_JADE_v2_annote.png` (relecture seulement, **jamais joint à Codex** ; pas de nouvelle vue générale).

**Résultat de `plan_check.py`** (tous les critères verts) : chemin principal **338 pas** (retour 338), entièrement sur cases larges ; **12 cases d'herbes obligatoires** (7 dans H3 + 5 dans H5) ; 1 960 cases praticables sur 6 300 (31 %, contre 37 % au T14 : la forêt serrée prend la surface ajoutée) ; 242 cases d'herbes (H1 42, H2 56, H3 61, H4 63, H5 20) ; O1 à 15 pas de l'entrée, O6 à 6 pas de la porte ; Milo évitable par 17 cases d'herbes au lieu de 12 (342 pas).

**Tracé (sud → nord ; entre parenthèses, pas depuis l'entrée sur le trajet le plus court)** :
1. Sortie sud (44..45, 89) → **C1** (x 36–55, y 79–86 ; H1 à l'est, O1 dans une baie à l'ouest) → **tronc incliné** (pied (42..43, 78), au bord ouest du sentier, juste au-dessus de C1) (11) → couloir nord (x 44–45).
2. **T1 vers l'ouest** (y 70–71) : **Théo** dans son alcôve (30, 67) ↓, sa vue couvre les 2 cases du sentier (30, 70) et (30, 71), aucune bande de sous-bois au droit de lui (x 28–32) ; vu au pas 32. Au bout, le **cul-de-sac occidental** continue tout droit (H2, Noé, O2 au fond) pendant que le sentier tourne au nord (x 12–13).
3. **T2 vers l'est** (y 60–61) à travers **C2** (x 20–38, y 55–64 ; **grande souche** (28..30, 55..56) au fond, O3 derrière elle par le passage d'une case (32, 54), naturaliste, Tom) (65–85), **ressaut** (x 41–42) vers y 57–58, montée à l'est (x 51–52).
4. **T3 vers l'ouest** (y 48–49) : **Milo** (30, 45) ↓, **H3** (x 20–26, traversée obligatoire de 7 cases, pas 132–138) et la bande d'herbes du détour de Milo (x 27–32, y 50–51) ; racines et O4 au bout (5, 48..49) ; montée (x 10–11).
5. **T4 vers l'est** (y 41–42, ressaut x 29–30, puis y 38–39) : **boucle de la randonneuse** au sud du sentier (clairière x 40–48, y 41–44, deux entrées (40, 40) et (48, 40)) (187) ; montée à l'est (x 55–56).
6. **T5 vers l'ouest** (y 30–31) à travers **C3** (x 30–44, y 26–34, **rai de lumière** (35..38, 27..29)) (220–234) ; montée (x 14–15).
7. **T6 vers l'est** (y 21–22) : **H5**, passage court sous la canopée (x 30–34, y 20–23, **5 cases obligatoires**, pas 274–278), ressaut (x 42–43) vers y 18–19 ; montée à l'est (x 53–54) ; la sente (54, 9..12) continue tout droit vers la **clairière d'O5** (nord-est, cul-de-sac).
8. **T7 vers l'ouest** (y 13–14) : la sente (x 16–27) continue tout droit vers la **clairière de H4** (nord-ouest, cul-de-sac, Roucool) pendant que le sentier tourne vers le **parvis** (x 22–35, y 6–11 : Éli, O6) → **porte du poste nord** (28, 5) (338) (emprise x 25–31, y 2–5).

**Écarts et choix** (défauts, règle 4) :
1. **H5** (nom nouveau : H1–H4 gardent leur sens du dossier, la zone ajoutée prend le numéro suivant) : bloc de 5 × 4 traversé sur toute sa largeur, sur la 6e traversée, entre C3 et le parvis : la 2e rencontre obligatoire tombe dans le dernier tiers, loin de H3 (≈ 140 pas entre les deux), quand la distance au Centre compte le plus (dossier §12.3). « Courte » = **4 à 6 cases** (défaut, H3 garde 6–8).
2. **La boucle de la randonneuse passe de la 2e à la 4e traversée** (même forme : petite clairière secondaire à deux entrées, souche et sac) : elle donne une respiration à une traversée nouvelle et décharge C2 (souche, O3, naturaliste, Tom). Tous les autres éléments gardent leur traversée.
3. **Trois ressauts** (T2, T4, T6) et des montées de longueurs différentes, pour que les sept lacets ne se lisent pas comme un accordéon régulier ; C3 décalée vers l'est par rapport à C2. Repères espacés : tronc au pas 11, souche ≈ 76, rai ≈ 228, porte 338 (mêmes proportions qu'au T14 : 10 / 69 / 172 sur 234).
4. Rythme : aucun tronçon de plus de ≈ 40 pas sans repère, clairière, herbes, Dresseur ou détour. Écarts entre corridors : 8 à 10 rangées de forêt (la caméra en montre ≈ 11) ; aucun embranchement à trois directions équivalentes (les trois culs-de-sac continuent **tout droit** dans l'axe du sentier, qui tourne).
5. Bandes de sous-bois d'une case le long de la plupart des traversées et des montées, coupées par endroits ; aucune au droit de Théo. Passages d'une case seulement dans les recoins (alcôve de Théo, niches de Noé et de Milo, `passage_o3`, sentes d'O5, entrées de la boucle).

### 7.2 Positions qui changent (pour l'étape 2)

Les noms ne changent pas (PNJ, warps, spawns, drapeaux) ; **raccords côté postes inchangés** (scènes des postes, cibles et spawns `from_forest`) : seules les cases dans la forêt bougent. Orientations inchangées.

| Élément | T14 (58 × 74) | Forêt agrandie (70 × 90) |
|---|---|---|
| `warp_sud_w` / `warp_sud_e` (PUSH ↓ → poste sud, `from_forest`) | (39..40, 73) | **(44..45, 89)** |
| spawn `from_gate_south` (↑) | (39, 73) | **(44, 89)** |
| `warp_poste_nord` (STEP_ON ↑ → poste nord, `from_forest`), façade `bldg_poste_foret_01` | (25, 5), emprise x 22–28 | **(28, 5)**, emprise x 25–31, y 2–5 |
| spawn `from_gate_north` (↓) | (25, 6) | **(28, 6)** |
| `scout_theo` D1 ↓ 4 | (28, 53) | **(30, 67)** |
| `scout_noe` D2 ↓ 5 | (4, 48) | **(6, 65)** |
| `youngster_tom` D3 ↑ 4 | (24, 51) | **(26, 64)** |
| `scout_milo` D4 ↓ 5 | (25, 32) | **(30, 45)** |
| `scout_eli` D5 ← 5 | (31, 9) | **(34, 9)** |
| `naturalist` (route, regarde ←) | (21..23, 44), tronc (18, 44) | **(22..24, 57)**, route [(22,57), (23,57), (24,57), (23,57)], tronc (19, 57) |
| `hiker` (route) / sac / souche | (41..44, 44) / (45, 44) / (40, 44) | **(41..44, 42)** / **(45, 42)** / **(40, 42)** |
| O1 `viridian_forest_item_1` (visible) | (30, 67) | **(34, 83)** |
| O2 (visible) | (3, 60) | **(4, 77)** |
| O3 (caché) / `passage_o3` | (27, 41) / (30, 42) | **(29, 53)** / **(32, 54)** |
| O4 (caché) / racines | (6, 36) / (5, 35..36) | **(6, 49)** / **(5, 48..49)** |
| O5 (visible) | (50, 4) | **(59, 5)** |
| O6 (caché) / souche du parvis | (20, 6) / (20, 7) | **(23, 6)** / **(23, 7)** |
| `caterpie_1` / `caterpie_2` | (41, 67) / (21, 33) | **(47, 83)** / **(27, 46)** |
| `weedle_1` / `weedle_2` | (36, 44) / (21, 22) | **(39, 57)** / **(29, 28)** |
| `metapod` / `kakuna` / `pidgey` | (18, 44) / (8, 51) / (14, 9) | **(19, 57)** / **(11, 69)** / **(14, 8)** |
| tronc incliné `I` / grande souche `S` / rai `L` | (37..38, 63) / (26..28, 43..44) / (26..29, 21..24) | **(42..43, 78)** / **(28..30, 55..56)** / **(35..38, 27..29)** |

Données à reporter : `data/npcs/viridian_forest.json` (`cell` et `route` de tous les PNJ ci-dessus) ; `data/cutscenes/viridian_forest.json` n'a **aucune case** (rien à changer) ; les déclencheurs des objets cachés sont lus dans la grille par l'outil (`HIDDEN_ITEMS`). Constantes en cases de `tools/build_viridian_forest.gd` (défauts proposés, à relire en capture) :
- `SIZE` 70 × 90 ; `FIXED_PROPS` : poste (28, 5), tronc (43, 78), souche (29, 56), racines (5, 49), sac (45, 42), souche du parvis (23, 7), souche de la randonneuse (40, 42) ; `CLEAR_LIKE_PERCH` (5, 49), (6, 49).
- `CLEARING_TREES` : C1 est (50, 78), C1 ouest (35, 80) ; C2 nord (24, 54), C2 nord-est (35, 54) ; C3 nord (31, 25) et **côté est (45, 27)** (au nord de C3, H5 et la bande de T6 ne sont qu'à deux rangées : la cime du bord nord est bornée par `WALK_OVERLAP_MAX`, à relire en capture) ; randonneuse : **côté est (49, 43)** (le bord nord touche le sentier : une cime y couvrirait le chemin) ; H4 nord (8, 6), H4 nord-est (13, 6) ; O5 nord (53, 2) ; parvis est (34, 5), ouest (23, 5).
- `EDGE_PROPS` : ronces C2 (21, 54), tronc couché C3 (36, 25), ronces C1 (47, 78), tronc couché H4 (4, 18), ronces O5 (52, 9).
- `LIGHT_SPOTS` : rai de C3 centré (37, 28.5) taille ≈ (5, 3) ; taches C1 (45, 82), C2 (28, 61), T5 (50, 31), parvis (27.5, 9) ; **+2 taches** sur les nouvelles traversées (défaut) : T4 (20, 42), T6 (48, 19) ; `PARTICLE_SPOTS` inchangés (C3, C1, C2).
- `H3_ROWS` (herbes sombres sous la canopée) → **H3 et H5** (lire les zones par leurs positions `herbes` plutôt que par des rangées).
- `tools/capture_viridian_forest.sh` : cases des captures à reporter ; départ de débogage `viridian_forest` inchangé (spawn par nom).

### 7.3 Estimation de la durée et combat obligatoire supplémentaire

Modèle (demandé par Kevin, imprimé par `plan_check.py`) : pas × 0,72 s (mesure S21) + Théo ≈ 100 s (mesuré) + rencontres attendues dans les herbes **obligatoires** au taux de la table (25 / 256 par pas ; la montée du taux ne joue pas sous 15 pas) × durée d'un combat sauvage. **La durée d'un combat sauvage n'a jamais été mesurée** : défaut **50 s** (apparition, 2–3 tours, expérience).

| Trajet | Calcul | Durée |
|---|---|---|
| T14 (référence) | 234 × 0,72 + 100 + 0,68 × 50 | ≈ 5 min 02 s (la QA T22 estimait 5–6 min) |
| **Forêt agrandie, minimum obligatoire** (Théo seul) | 338 × 0,72 + 100 + 12 × 25/256 = 1,17 rencontre × 50 | **≈ 6 min 41 s** (6 min 18 s à 30 s par combat sauvage, 7 min 04 s à 70 s) |
| Forêt agrandie, **+ Milo inévitable** (≈ 120 s, deux Pokémon, défaut) | 402 + 120 | **≈ 8 min 40 s** |
| Forêt agrandie, + Tom inévitable (≈ 90 s, un Pokémon, défaut) | 402 + 90 | ≈ 8 min 10 s |
| Joueur qui suit le sentier sans éviter personne (Théo, Tom, Milo) | 402 + 90 + 120 | ≈ 10 min |

**Constat** : le minimum reste **sous 7 min** (6 min 41 s) → la proposition de Kevin s'applique. **Mais** Tom et Milo sont déjà sur le sentier (comme au T14) : les éviter demande de passer par le nord de C2 (sans détour) et par 5 cases d'herbes de plus pour Milo ; un joueur qui suit le chemin sans y penser les combat tous les deux.

**Recommandation : Milo devient inévitable** (aucun 6e Dresseur) :
- il est déjà dans l'axe du sentier ; le changement de grille est minime : couper la bande d'herbes du détour sous sa ligne et à l'est (cases (31..32, 50..51) et (30, 51) → forêt ; (30, 50) reste en herbe, 5e case de sa vue dégagée), plus aucun passage ne croise sa colonne hors de sa vue ; il voit les deux cases du sentier, détection à 3 cases comme Théo ; aucune réplique nouvelle ;
- c'est le premier duo de la forêt (Chenipan + Aspicot : poison possible) **juste après H3 et à mi-parcours** (pas ≈ 131) : la pression sur les ressources (Potion, Antidote) arrive là où le dossier la veut (§12.3), et l'estimation tombe au milieu de la cible (≈ 8 min 40 s) ;
- **coût** : la ligne « D4 évitable : oui (détour par les hautes herbes) » du dossier 10 §8 change, et la forêt perd son seul choix « Dresseur ou herbes ». Alternative : Tom (≈ 8 min 10 s), mais il faudrait fermer le nord de C2 (la clairière perd sa respiration autour de lui).
- **Non appliqué** à cette étape : la grille livrée garde Milo évitable par les herbes (dossier en vigueur). Variante vérifiée sur une copie : tous les critères restent verts sauf « D4 évitable par les herbes » (Milo devient incontournable, aucune approche ne ferme un passage, H3 garde 7 cases obligatoires) ; le critère deviendrait « D4 inévitable ». → **Question XL-1 pour Kevin** (§7.6).

### 7.4 Budget de nœuds de la carte (≤ 3 000)

Carte du T19 : 2 683 nœuds pour 58 × 74 (1 116 arbres et jeunes arbres en `Sprite2D`, 476 touffes, ≈ 1 000 décalcomanies, ≈ 90 autres). À densité égale, la grande carte en ferait ≈ 3 600 (forêt serrée 4 340 cases au lieu de 2 713, praticables 1 960 au lieu de 1 579, herbes 242 au lieu de 238). Comment elle tient (défauts pour l'étape 2, dans l'ordre) :
1. **Repli `Sprite2D` déjà en place** (aucun `WorldProp` pour la forêt) ; `cull_hidden` garde son rôle mais retire peu : 163 cases de forêt seulement (les coins) sont à plus de 13 colonnes / 9 rangées de toute case praticable.
2. **Densité des arbres selon la distance au praticable** : 2 972 cases de forêt à 1–5 cases (Tchebychev) d'une case praticable gardent la densité du T19 (≈ 0,41 arbre par case → ≈ 1 220) ; les 1 368 cases à 6 cases ou plus (marges est et ouest, cœur des massifs) reçoivent un arbre sur trois, plus grand (≈ 190) : ≈ **1 410 arbres**. Les tirages de `DenseForest.plan` passent de 9 000 à ≈ 13 200 (même densité de départ).
3. **Décalcomanies ≈ 0,5 par case praticable** (au lieu de 0,63) : `BORDER_KEEP` 0,4 → 0,3, `UNDERGROWTH_PER_STRIP` 0,6 → 0,45 → ≈ **980** ; touffes inchangées (≈ **490**) ; autres ≈ **100**.
4. Total projeté **≈ 2 980** : juste sous le plafond. **Si le compte dépasse 3 000** : décalcomanies du bord du sentier à 0,2, puis arbres des cases à 6+ un sur quatre ; repli structurel seulement si cela ne suffit pas (un `MultiMeshInstance2D` par texture d'arbre de forêt, vent par instance) — à décider sur mesure, pas avant.
Mémoire des textures : aucune texture nouvelle (mêmes arbres, sols, décalcomanies) ; seul le masque du sol peint grandit (≈ × 1,47).

### 7.5 Étape 2 — la carte (fait, 2026-10-08)

Tâche **constructeur-monde** (Sonnet), sur `j9-foret-xl`, **après la réponse de Kevin à XL-1** (si Milo devient inévitable : modifier d'abord la grille et le critère D4 de `plan_check.py`, « D4 inévitable »).
1. **Grille** : `viridian_forest_xl.txt` **remplace** `tools/plans/viridian_forest.txt` (même nom de fichier qu'avant pour la scène et les tests ; en-tête mis à jour) ; `plan_check.py` : le profil `viridian_forest` prend les valeurs XL (le profil T14 disparaît) ; `plan_aplats.py` : sortie `PLAN_FORET_JADE_v2.png`.
2. **Données** : `data/npcs/viridian_forest.json` selon §7.2 (`test_viridian_forest_data` compare déjà données et grille).
3. **Outil** : `tools/build_viridian_forest.gd` selon §7.2 et §7.4 (taille, ancrages, arbres de clairières, lisières, rais, herbes sombres H3 + H5, densité, décalcomanies) ; scène régénérée `game/world/maps/viridian_forest.tscn`.
4. **Tests** : `test_viridian_forest` (taille 70 × 90, chemin 330–360, H3 + H5 obligatoires, visions, Théo, approches), `test_viridian_forest_life` (cases des objets et des PNJ via la grille), `test_plan_grid` (enveloppe), `test_dense_forest` (lecture de la grille) ; `tools/capture_viridian_forest.sh` (cases).
5. **Critères d'acceptation** : `plan_check.py` vert ; grille de la scène = grille case par case ; **≤ 3 000 nœuds** (compte imprimé par l'outil) ; `tools/test.sh` vert ; import propre ; captures Mac relues (C1 et tronc, Théo, C2 et souche, H3 et Milo, boucle de la randonneuse, C3 et rai, H5, parvis ; aucun trou dans la forêt, aucune haie régulière, aucun arbre sur le sentier) ; changement de carte Route 2 → forêt mesuré sur Mac (`tools/measure_map_load.gd`) sans dérive notable par rapport au T19.
6. **Étape 3 — qa-mobile** (S21 ou S24, vraie partie ou départ `viridian_forest`) : traversée **directe chronométrée avec combats** (minimum obligatoire **et** sentier suivi sans éviter), durée d'un combat sauvage relevée (remplace le défaut de 50 s), fps (moyenne ≥ 58) dans C1, H3, C3, H5, parvis, mémoire des textures, temps de changement de carte → validation de Kevin.

**Fait (2026-10-08, branche `j9-foret-xl`)** — critères d'acceptation tenus :
- **Grille** : XL-1 appliquée (cases (31..32, 50..51) et (30, 51) → forêt ; (30, 50) reste en herbe, 5e case de la vue de Milo) ; `viridian_forest_xl.txt` **remplace** `tools/plans/viridian_forest.txt` (en-tête « avant / après ») ; `plan_check.py` : un seul profil `viridian_forest` (valeurs XL), critère « D4 évitable par les herbes » → **« D4 inévitable »** (même contrôle que Théo : vue sur les deux cases du sentier, première case vue à 3 cases), estimation avec Milo (120 s, défaut) ; **vert** : 338 pas, 12 cases d'herbes obligatoires (H3 7 + H5 5), 1 955 cases praticables, 237 cases d'herbes (H3 56), **traversée directe estimée 8 min 41 s** ; `plan_aplats.py` → `PLAN_FORET_JADE_v2.png`.
- **Données** : `data/npcs/viridian_forest.json` selon §7.2 (17 cases, deux routines) ; `test_viridian_forest_data` vert sans changement de logique (naturaliste (22..24, 57), Chrysacier (19, 57)).
- **Outil** (`tools/build_viridian_forest.gd`) : 70 × 90, ancrages du §7.2 ; herbes sombres lues par zone (`DARK_GRASS_ZONES` = positions `herbes_h3`, `herbes_h5`, 152 touffes) ; `DenseForest.plan(..., attempts)` (nouveau paramètre facultatif, défaut 9 000 inchangé pour les autres cartes) à **13 200 tirages** ; **densité selon la distance** (`_thin_far` : à 6 cases ou plus du praticable, un arbre sur trois gardé, × 1,3, aucun garnissage) ; décalcomanies `UNDERGROWTH_PER_STRIP` 0,45, `BORDER_KEEP` **0,2** (premier repli du §7.4, nécessaire) ; rais : C3 (37, 28.5), C1 (45, 82), C2 (28, 61), T5 (50, 31), parvis (27.5, 9) + T4 (20, 42) et T6 (48, 19, rai faible 0,3) ; particules inchangées (C3, C1, C2).
- **Nœuds : 2 983** (≤ 3 000 ; 1ʳᵉ mesure à densité égale : 3 707, puis 3 111 avec la densité par distance et les décalcomanies à 0,3) : 1 014 arbres + 367 jeunes arbres, 474 touffes, ≈ 1 040 décalcomanies (379 sous-bois, 326 ombres de canopée, ≈ 340 bords et clairières), ≈ 100 autres.
- **Perf Mac** (`tools/capture_viridian_forest.sh`, 2340 × 1080, une fois chargé) : 112–140 fps, **131–159 appels de dessin** (T19 : 149–175), 173–281 objets, textures 43,7 Mo (processus), **cartes retenues dans la forêt 14,2 Mo** (inchangé). **Changement de carte** (`measure_map_load.gd`, médiane de 5, deux séries) : Jadielle 372 ms, **forêt 294–317 ms (0,79–0,85 × Jadielle ; T19 : 286 ms)**, Route 2 257–273 ms.
- **Tests** : **`tools/test.sh` vert, 3 322 tests** (1er passage : 3 320 / 3 321, échec isolé de `test_wild_battle` « Parameter "t" is null » sous la charge des autres sessions, sans lien avec la forêt, vert seul deux fois puis au 2e passage complet) ; import propre ; `test_viridian_forest` (19 : 70 × 90, sortie (44..45, 89), porte (28, 5), 338 pas dans 330–360, **H3 et H5 obligatoires** (zones nommées par les positions `herbes`), H1 / H2 / H4 évitables sans détour, **Théo et Milo inévitables** sur la grille et sur la vraie scène avec tous les PNJ, approches sans fermeture), `test_encounter_director` (**H1 à H5**), `test_plan_grid` (enveloppe 70 × 90), `test_viridian_forest_data` (naturaliste) ; `test_viridian_forest_life`, `test_forest_gates`, `test_map_links`, `test_qa_forest_systems`, `test_dense_forest` verts sans changement (raccords des postes : cibles et spawns par nom).
- **Captures** relues (`build/captures/foret_xl/`) : `entree`, `c1_objet`, `tronc_incline`, `theo`, `h2_cul_de_sac`, `souche`, `h3`, `milo`, `racines`, `randonneuse`, `clairiere_rai`, `h5`, `montee_o5`, `h4`, `poste_nord`, intérieurs, `ensemble`. Aucun trou dans la forêt, aucun arbre sur le sentier, pas d'effet labyrinthe (lacets de longueurs différentes, ressauts) ; Milo visible dans sa niche au-dessus du sentier, H3 à gauche ; rai de C3 entier.

**Écarts** (défauts, règle 4) :
1. **Arbres des clairières déplacés** par rapport au §7.2 : au nord de C2 (H3 à 3 rangées), de C3 (H5 à 2 rangées) et de la boucle de la randonneuse (sentier à 2 rangées), une cime de 4–5 cases aurait couvert des herbes ou le sentier → `TreeC2West` (19, 56, au-dessus du Chrysacier), `TreeC2NorthEast` (36, 54), `TreeC3West` (29, 27, au-dessus de l'Aspicot), `TreeC3East` (45, 28), `TreeHiker` (49, 44, `tree_a_01` plus bas) ; ronces de C1 (48, 78) (en (47, 78), l'une de leurs cases était praticable).
2. **Cœur des massifs éclairci** : à 6 cases ou plus du praticable, de grands arbres espacés sur le sous-bois sombre (visible en bord d'écran, ex. `h2_cul_de_sac`) ; se lit comme une forêt profonde, pas comme un trou. À juger sur téléphone.
3. **Rai de C3** : la forêt au nord de C3 ne fait que 2 rangées ; le haut du rai (additif, au-dessus des cimes) passe sur la bande de forêt et s'éteint au bord de H5 (`h5.png`). Gardé.
4. Budget juste (2 983 / 3 000) : un ajout de décor dans la forêt demandera le repli suivant (arbres à 6+ cases un sur quatre).

**Procédure de l'étape 3 (qa-mobile, S24 ou S21, bornée à 30–45 min)** — branche `j9-foret-xl` ; départs `viridian_forest` (entrée sud) et **`viridian_forest_north`** (nouveau : devant la porte du poste nord, tourné vers le sud) ; `PerfCounter` visible ; rapport `build/qa/foret_xl_etape3/`.
1. **Préparation (≈ 3 min)** : `tools/deploy_s24.sh --debug-start viridian_forest` ; taille de l'APK ; chronomètre prêt.
2. **Traversée directe chronométrée, minimum obligatoire (≈ 12 min)** : chrono au premier pas, arrêt à l'entrée dans le poste nord ; suivre le sentier sans détour, éviter ce qui s'évite (Tom : passer par le nord de C2 ; ne pas entrer dans H1, H2, H4). Relever : durée totale (**cible 7–9 min**, estimée 8 min 41 s), **durée de chaque combat** (Théo, Milo, chaque sauvage : remplace le défaut de 50 s), nombre de rencontres dans H3 (7 cases) et H5 (5 cases), temps intermédiaires entrée → Théo, Théo → Milo, Milo → porte. Au passage : Théo voit le joueur à 3 cases sur la 1re traversée ; **Milo inévitable** (essayer de passer sous lui par les herbes, rangées 50–51 : la forêt bloque ; « ! » à 3 cases, duo Chenipan + Aspicot) ; la porte du poste nord est atteinte.
3. **Raccord nord (≈ 3 min)** : poste nord (garde « Encore quelques pas… ») → ouverture nord → « ROUTE 2 NORD — À venir » → retour → porte sud du poste → forêt : arrivée en (28, 6) tournée vers le sud, devant la porte.
4. **fps par zone (≈ 10 min)** : `tools/deploy_s24.sh --no-build --debug-start viridian_forest` puis, à l'arrêt ≈ 10 s et en marchant, fps moyen et creux à **C1** (entrée), **tronc incliné**, **H3**, **C2** (souche, naturaliste), **C3** (rai et particules) ; puis `--debug-start viridian_forest_north` : **parvis** (Éli) et **H5**. Mémoire des textures (`tex=`) dans la forêt. Cible : moyenne ≥ 58, creux ≥ 50.
5. **Raccord sud et changement de carte (≈ 5 min)** : depuis l'entrée sud, descendre : sortie (44..45, 89) → poste sud (arrivée (4, 2) tournée vers le sud) → Route 2 → revenir dans le poste → forêt (arrivée (44, 89) tournée vers le nord). Relever dans le journal les temps « SceneRouter : … en X ms » Route 2 → poste → forêt et les comparer à une entrée dans Jadielle (≤ 1,5 ×).
6. **Si le temps le permet (≈ 10 min)** : traversée « sentier suivi sans éviter » (Tom compris), durée ; sinon la noter à faire.
7. **Au doigt (≈ 2 min)** : effet labyrinthe ou lacets répétitifs ? cœur éclairci des massifs (grands arbres espacés sur le sous-bois sombre, bords d'écran) lisible comme forêt profonde ? rai de C3 sur la bande nord, repères (tronc, souche, rai) repérables ; Milo bien visible dans sa niche avant la détection.

### 7.6 Questions pour Kevin (chantier « Forêt agrandie »)

- **XL-1 — tranchée par Kevin le 2026-10-08 : Milo inévitable** (appliqué à l'étape 2). Question d'origine — combat de Dresseur obligatoire supplémentaire : minimum obligatoire estimé ≈ 6 min 41 s (< 7 min). Recommandation : **Milo inévitable** (≈ 8 min 40 s ; la ligne « D4 évitable par les herbes » du dossier 10 §8 change). Alternatives : Tom inévitable (≈ 8 min 10 s, nord de C2 fermé) ; aucun (≈ 6 min 41 s, mais ≈ 10 min pour qui suit le sentier sans éviter Tom ni Milo).
- **Dossier 10** : mis à jour le 2026-10-08 (étape 2, à la demande de Kevin) : section « Forêt agrandie » avec avant / après, arbitrage 4, §2, §4, §5 (H5), §8 (Milo inévitable), table des décisions.
- Défauts posés (règle 4, sans blocage) : H5 = 4–6 cases (5 posées) ; randonneuse sur la 4e traversée ; combat sauvage 50 s dans l'estimation.
