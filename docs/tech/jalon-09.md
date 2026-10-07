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
3. **Apparences** : depuis DA.2, les PNJ de Bourg Palette sont peints et `test_character_look` le suppose (« les starters restent provisoires ») ; la carte de QA garde l'apparence générique existante pour ses Dresseurs et son garde (T12), les planches peintes `scout` / `guard` / `naturalist` restent à la série 10 (T17).
4. **Textes (T0)** : lot `docs/design/textes/textes-brouillon-j9.md`. Les messages d'évolution utilisent `{species}`, absent de `BattleText.PLACEHOLDERS` (T8 l'ajoute, ou les textes de l'évolution vivent hors de `BattleText`) ; les noms de Dresseurs (« Scout Théo », « Gamin Tom ») sont des `name` entiers de `TrainerData` : aucune classe de Dresseur séparée à nommer.

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

`MoveLearnPrompt` (Node, `game/ui/battle/move_learn_prompt.gd`) extrait de `BattleDirector._offer_forget` / `_confirm_forget` : « {pokemon} apprend {move} ! » (toucher), ou le `MoveForgetPanel` (+ `ChoiceCards` si `confirm_forget`) puis la phrase. `BattleDirector` l'utilise pour `MOVE_LEARNED` / `MOVE_FORGET_OFFERED` (comportement **inchangé** : `test_battle_director` est le filet), `EvolutionDirector` pour les capacités rendues par `Evolution.evolve`. Le bandeau de message est passé en paramètre (celui du combat ou celui de l'écran d'évolution).

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
- Apparences peintes : `pokemon/caterpie`, `pokemon/weedle`, `pokemon/metapod`, `pokemon/kakuna` (série 10).

#### 2.7.7 PNJ et objets

- P1 naturaliste : `route` de 3 cases + `look` vers un tronc ; P2 randonneuse : `route` entre la souche et son sac, apparence `hiker` du J8 (défaut) ; dialogues « première fois / ensuite » par drapeau (`forest_naturalist_talked`, `forest_hiker_talked`), modèle du J8 (Q-2 du J8).
- Gardes : apparence peinte `guard` (nouvelle, série 10) ; Dresseurs : `scout` (nouvelle, une pour les quatre Scouts, défaut), Tom : `youngster` (existante).
- Objets visibles O1 (Antidote), O2 (Poké Ball), O5 (Poké Ball) : mécanisme du J8 (§2.3 du J8 : entrée de PNJ `object/poke_ball_ground`, verbe PRENDRE, scène `despawn` + `give found` + `set`). Cachés O3 (Potion), O4 (Antidote), O6 (Potion) : `EventTriggerPoint` sur herbe rase → narration (textes validés) → `give … found: true` → toast standard (arbitrage 8). Drapeaux `got_viridian_forest_item_1` … `_6`.

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
- **Fait (2026-10-07, branche `j9-t11-dresseurs`)** : voir §6.4 (contrat de `Npc.show_emote` posé, dessin au T12 ; `AWAITING_TRAINERS` à vider au T12).

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

#### T15 — constructeur-monde (Mac, Codex) : vue générale → **validation de Kevin (9B.0)**
- 3 essais au plus ; relecture contre la grille ; `docs/design/reference/foret-jade-vue-generale-v1.png` + `foret-jade-plan-v1.png`, section « Vue générale peinte v1 » du dossier 10.
- **CA** : image validée ; tout changement de composition passe d'abord par la grille (T14 rejoué).

#### T16 — architecte : liste exacte des assets (série 10) — dépend de T15
- Fiches : enveloppe du poste (10 × 8), garde, Scout, naturaliste ; Chenipan, Aspicot, Chrysacier, Coconfort d'ambiance ; tronc incliné, grande souche (emprise), amas de racines, sac posé, arbres des clairières, rais de lumière (décalcomanies) ; promotions éventuelles du J8 (planche de forêt plus sombre) ; règles `PaintedPropRules`.
- **CA** : chaque élément visible de la vue validée a un asset (existant, promu, nouveau) ou est abandonné explicitement.

#### T17 — constructeur-monde (Mac, Codex) : série 10 — dépend de T16
- Génération en lumière NE, manifeste, `preparer.py`, `build_painted_props.gd`, `build_character_frames.gd` (garde, Scout, naturaliste : marche + attente ; Pokémon d'ambiance : attente + `react`).
- **CA** : `preparer.py` relancé deux fois ne change rien ; `test_painted_props` vert ; planche contact `build/captures/jalon09_assets/` relue.

#### T18 — architecte : fondations de la forêt — parallèle à T15–T17
- `shy` `notice` / `hide` (`NpcSpec`, `NpcRoster`, `AmbientWatcher`, `Npc`), Pokémon d'ambiance sur case de forêt, tri de visibilité de `DenseForest` (paramètre, tests purs), profil `forest` (`lighting.json`), données `data/npcs/viridian_forest.json` (cases de la grille), `data/cutscenes/viridian_forest.json` (6 objets), `zones.json` (§2.7.3, textes validés en Q-1), `tools/debug_start/viridian_forest.json` (équipe N8–10, entrée sud).
- Tests : `test_ambient_rules` / `test_ambient_watcher` (`notice`, `hide`), `test_dense_forest` (tri de visibilité), `test_lighting_library`, `test_cutscene_library` (objets), `test_zone_library`.
- **CA** : tests verts ; aucune carte touchée.

#### T19 — constructeur-monde : la forêt et les postes (9B.1) — dépend de T17, T18
- `tools/build_viridian_forest.gd` (§2.7.4), `_forest_gate(side)` (§2.7.2), warp du poste dans `route_2` (une ligne de l'outil + le nœud), retour `from_forest_gate`, « ROUTE 2 NORD — À venir » ; Dresseurs posés aux cases de la grille (sans leur vie : T21).
- Tests : **`test_viridian_forest`** (taille, profil, warps et spawns, critères §2.7.1 sur la vraie grille, cases d'objets cachés sur herbe rase, aucune case praticable sous une cime, nœuds ≤ 3 000), `test_forest_gates` (deux scènes de la même définition, gardes, portes), `test_map_links`, `test_route_2` (porte vers le poste, plus de « À venir »), `test_coming_soon` (porte nord), `test_encounter_director` (H1–H4) ; `tools/capture_viridian_forest.gd` (entrée, tronc incliné, H3, souche, clairière, poste nord) relue contre la vue générale ; `[perf]` Mac.
- **CA** : tests verts, import propre, captures 2340 × 1080 relues.

#### T20 — qa-mobile : validation 9B.1 sur S24 → Kevin
- Vraie partie (Route 2 → poste sud → forêt → poste nord → « À venir » → retour) et départ `viridian_forest` ; traversées **directe et attentive chronométrées avec rencontres et combats** (arbitrage 4 : 7–9 min, 15–20 min) ; fps (moyenne, creux), mémoire des textures, temps de changement de carte, taille de l'APK.
- **CA** : rapport `build/qa/jalon09_t20/` ; validation de Kevin ; géométrie ajustée **seulement** si le rythme réel l'exige (arbitrage 4).

#### T21 — constructeur-monde (+ ui-mobile en relecture) : la vie de la forêt (9B.2)
- Dresseurs (répliques, visions vérifiées sur la vraie carte), P1 / P2, gardes, Pokémon d'ambiance, 6 objets, rais de lumière et particules ; relecture ui-mobile (PRENDRE, toasts, « ! », Carte, Pokédex « Forêt de Jade »).
- Tests : `test_viridian_forest_life` (objets : Sac, `found_items`, drapeaux, retrait immédiat et au rechargement ; cachés : narration puis toast, une fois ; Dresseurs : battus mémorisés ; routines hors herbes et hors visions), `test_viridian_forest` étendu (D1 inévitable, D2/D3/D5 évitables, D4 par l'herbe, sur la vraie scène avec les PNJ).
- **CA** : tests verts, captures relues.

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


### 6.4 T11 — logique des Dresseurs (2026-10-07)

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

### 6.4 T6 — carte et départs de QA, gardes (2026-10-07, branche `j9-t6-carte-qa`, base `jalon-09` à `fe43b08`)

Fait comme au §2.6 et §2.4.8, avec les écarts suivants :

1. **Couloir de Théo : il croise la ligne de vue au lieu de la suivre.** Le Dresseur marche jusqu'à la case voisine du joueur (§2.4.2) : dans l'axe d'un couloir d'une case, Théo s'arrêterait devant le joueur et **fermerait le passage pour de bon**. Le couloir (rangée 12, une case de large, de (24, 12) à (8, 12)) passe donc devant une **alcôve** (16, 8..11) où Théo (16, 8, tourné vers le bas, vision 4) tient sa ligne ; détection en (16, 12), 3 cases libres entre eux, et après son approche il reste dans l'alcôve (test : le couloir reste ouvert). Aucun autre chemin vers le nord (test : BFS avec sa ligne bloquée). **Conséquence pour T12 / T19** : ne jamais mettre un Dresseur dans l'axe d'un passage d'une case.
2. **Carte 26 × 20** (le « ≈ 24 × 18 » du plan s'est élargi pour loger les cinq Dresseurs) : zone sud (garde (11, 15), hautes herbes 5 × 4 en (2..6, 15..18), sortie (10..12, 18) PUSH ↓ vers `viridian_city` / `from_center`), couloir, zone nord (clairière de Noé et Milo, Tom, Éli). Tuiles provisoires `OverworldTiles`, aucune lumière, aucun prop.
3. **Cases réservées aux Dresseurs (T12)**, constante `TRAINER_SLOTS` de `tools/build_qa_forest_systems.gd` (et gabarit testé dans `test_qa_forest_systems`) : Théo (16, 8) ↓ vision 4 ; Noé (7, 3) → vision 5 ; Milo (11, 1) ↓ vision 5 (coupée par l'arbre (11, 5) : cases (11, 2..4)) ; Tom (19, 4) ← vision 4 (abordable de côté depuis (19, 3) ou (19, 5)) ; Éli (23, 1) ↓ vision 5. Lignes de Noé et de Milo : un seul croisement, (11, 3). Contournement par les hautes herbes (10..12, 6) (3 cases en plus des 20). **Aucun Dresseur n'est posé** : `data/npcs/qa_forest_systems.json` ne contient que le garde (`south_guard`, apparence `traveler` : hypothèse, « sprite générique »).
4. **Points d'apparition** : `poison_start` (11, 16) ↑ (une case sous le garde), `evolution_start` (7, 17) ← (au bord des herbes), `theo_corridor` (20, 12) ← (4 pas avant la ligne de Théo ; « entrée du couloir » interprétée ainsi). `trainers_qa` et `trainers_weak_qa` partagent `theo_corridor`.
5. **Garde sud « auto » (décision Q-4)** : première variante `auto: true` → il parle **à l'arrivée sur la carte** (mécanisme de Maman, `InteractionController.on_map_entered`), donc dès l'entrée dans le poste sud (T19 : le garde doit être dans le poste, à portée de la case d'arrivée). Le drapeau `poison_unlocked` est posé **à la fin** du dialogue (relevé : faux pendant, vrai après). Sur `poison_qa` il parle donc tout de suite (vérifié en capture) ; les trois autres départs posent `poison_unlocked` d'avance pour qu'il se taise. Test `test_mom_first_variant_is_automatic_and_only_hers` élargi à ce garde.
6. **Dialogues** : `data/dialogues/forest_gates.json` (les deux gardes, speaker « Garde », textes du dossier 10 mot pour mot, une page de 2 lignes par réplique ; test dédié dans `test_dialogue_data`). `forest_gate_north_guard` n'est joué par aucune carte avant T19 (exception `UNUSED_YET`) ; `pewter_arrived` ajouté à `FUTURE_FLAGS` (posé par le J10).
7. **À compléter ailleurs** : **T4** : 2 Antidotes dans `poison_qa`, 1 dans `trainers_qa` (l'objet n'existe pas encore ; `test_shipped_poison_qa_start` échouera à l'ajout de l'objet tant que le Sac n'en contient pas : voulu) ; **T12** : les 5 Dresseurs dans `qa_forest_systems.json` (blocs `trainer`) ; T8 / T9 : rien dans les données (l'évolution se joue sur les départs tels quels).
8. **`MapCatalog.QA_PREFIX` / `is_qa_map`** ; `test_zone_library` et `test_map_light_profiles` ignorent les cartes `qa_`. Aucune zone, aucune découverte au Pokédex/Carte (zone vide). Retrait à la clôture du J9 (T23) : scène, `tools/build_qa_forest_systems.gd`, `tools/capture_qa_forest.gd`, données, départs.

