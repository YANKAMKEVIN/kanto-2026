# Jalon 4 — Le starter et le premier combat contre le rival

> Objectif jouable sur le S24, en deux temps.
>
> **4A — Le choix.** Juste après « Et pourtant, tu es toujours là. » (fin du 3B), **Prof. Chen** enchaîne : « Vous voulez tous les deux découvrir Kanto. » … « Alors... pourquoi ne pas commencer ensemble ? » (il regarde les trois Pokémon à la troisième réplique). Le joueur reprend la main et **« CHOISIS TON PREMIER PARTENAIRE »** s'affiche sur le monde, puis s'efface. Il **marche jusqu'à la table**. Face à un starter, le bouton contextuel dit **RENCONTRER**. Un toucher : le Pokémon s'avance vers lui, et une **fiche très légère** apparaît (**SALAMÈCHE** · pastille Feu · *Fougueux et courageux.* · **CHOISIR** / **RETOUR**). RETOUR le rend à la table. CHOISIR : le Pokémon **saute de la table et reste devant le joueur**, le regarde, s'approche ; Prof. Chen : « On dirait que le choix est réciproque. ». Le rival observe, regarde les deux restants, va prendre **celui qui a l'avantage** : « Alors ce sera toi. », son Pokémon le rejoint, « Ça devrait être intéressant. ». Il commence à partir avec lui, s'arrête, regarde les deux Pokémon, se retourne : « Attends. » / « On ne va quand même pas partir sans savoir ce qu'ils savent faire. ». **Fin provisoire du 4A** : le joueur récupère la main. Les hautes herbes du nord ne l'arrêtent plus.
>
> **4B — Le combat.** La dernière réplique du rival lance le **premier combat, dans le laboratoire même** : pas d'écran noir, pas de décor générique. La caméra se rapproche à peine, le labo s'assombrit légèrement, les deux Pokémon passent en **vue de combat** (le tien de dos au premier plan à gauche, celui du rival de face au centre droit), les **cartes d'information** glissent en place et la **grille ATTAQUER · SAC · ÉQUIPE · FUITE** apparaît, ATTAQUER mis en avant. ATTAQUER → **deux cartes de capacités** (nom, type, PP, puissance ; pression longue = fiche). On attaque, le Pokémon s'élance, l'impact fait trembler l'autre, la barre de PV descend en douceur (vert → jaune → rouge). Le rival répond. Jusqu'au K.O. de l'un des deux. Puis le décor revient, la suite de la scène se joue, et le joueur reprend la main.
>
> Pas de tutoriel, pas d'« OBJECTIF MIS À JOUR », pas de marqueur. C'est la fin du prologue (dossier 02 §6 suite à §10), le premier contact avec le système Pokémon (dossier 04) et avec l'interface de combat 2026 (dossier 05).

**Pré-requis** : le **jalon 3B est codé, fusionné et validé sur le S24** (fait ; alignement du 4A sur son code réel : **§13**). Le 4A s'accroche à la fin de sa scène `oak_intercept` (en réalité la variante 1 de `route1_grass`, §13.1), à son `CutsceneDirector`, à ses PNJ qui marchent et à sa présence conditionnelle (§9, **à relire avant l'étape d'architecture du 4A**). Au moment de ce plan, le 3B n'existe qu'en plan ([`jalon-03b.md`](jalon-03b.md)) : ce document s'appuie sur le **code réel du 3A** (`main`, 513 tests verts) et sur les **points d'accroche promis** par le 3B (§2.10 de son plan, décisions de Kevin en tête de son §7).

**Hors périmètre** (d'après les dossiers 02, 04, 05 et la règle « une couche à la fois ») :
- **Capture**, Poké Balls, Sac et objets en combat (dossier 05 §15–17) : phase 6. SAC reste visible mais inactif (Q18).
- **Changement de Pokémon** (dossier 05 §14) : le joueur n'a qu'un Pokémon. ÉQUIPE reste visible mais inactif (Q18).
- **Fuite** : impossible contre un Dresseur ; FUITE inactif (Q18). La fuite des combats sauvages vient au jalon 5.
- **XP, montée de niveau, apprentissage, évolution** (dossier 04 §6–7) : jalon 5 et suivants (Q20). Le combat du labo ne donne pas d'XP en 4B.
- **Statuts majeurs** (poison, paralysie, sommeil, brûlure, gel) et leurs effets visuels (dossier 05 §13) : aucune capacité du jalon ne les inflige. Seules les **modifications de stats** (Rugissement, Mimi-Queue) sont codées.
- **Rencontres sauvages**, Route 1, effet « jambes dans l'herbe » : jalon 5. Après le starter, les hautes herbes sont praticables, sans rencontre.
- **Défaite « classique »** (retour au Centre Pokémon, dossier 05 §23) : il n'existe aucun Centre. Le combat du labo est **sans conséquence** (Q19).
- **Pokémon compagnon** qui suit le joueur (dossier 04 §4) : jalon dédié (Q21).
- **Pokédex**, indice « Efficace / Peu efficace » sur les cartes (dossier 05 §8, il dépend du Pokédex), menus Équipe et Sac, surnoms (Q7), argent.
- **Sauvegarde** : comme en 3A et 3B, l'état vit dans `GameState` sans sauvegarde. Les classes du jalon prévoient `to_dict()` / `from_dict()` sans les brancher.
- Musique, sons, réaction du décor aux attaques (dossier 05 §11), option « Animations complètes / rapides » (§21), gestes (§24), mise en scène des boss (§22).
- Rendu « vraie DA » des Pokémon (monde et combat) : sprites **provisoires** aux dimensions finales.

Références : `CLAUDE.md`, **`docs/design/dossier-02-prologue.md` §6 à §10 et « Ajouts de Kevin » (source de vérité des textes)**, `dossier-04-systeme-pokemon.md`, `dossier-05-combat.md` (dont « Point à trancher » en fin de fichier), `dossier-06-progression.md` §6 (rival), `ui-ux-bible-v0.1.md` (qui **prime** sur la planche, y compris sa table de contradictions), `ui-reference.md` (section Combat), `vision.md` (contrôles de combat, 60 fps), références `combat-v1.webp`, `combat-capacites-v1.png.png` (§11), `combat-capture-v1.webp`, `labo-chen-v1.png`, `da-2026-planche-v1.webp`, [`jalon-03.md`](jalon-03.md), [`jalon-03b.md`](jalon-03b.md), skills `godot-conventions`, `world-tiles` et `ui-theme-2026`.

---

## 1. Découpage en 4A / 4B

| | 4A — Le choix du starter | 4B — Le premier combat |
|---|---|---|
| Couche nouvelle | **Données Pokémon** (types, espèces, capacités), **instance de Pokémon** et **équipe** | **Moteur de combat** (règles, IA, journal d'événements) |
| Visible sur le S24 | Chen §7, RENCONTRER, fiche, CHOISIR / RETOUR, le starter qui saute de la table, le choix du rival, « Attends. » | Le combat complet dans le labo, cartes, barres de PV, capacités, animations, fin du combat |
| Fin | provisoire : le joueur reprend la main après « …ce qu'ils savent faire. » | la scène du labo se termine, le prologue aussi |

Pourquoi ce découpage plutôt que « toute la logique en 4A » :
- **Chaque sous-jalon se valide sur le S24.** Un moteur de combat sans présentation ne se juge pas en jouant ; il resterait non validé tout le 4A. Le choix du starter, lui, se vit et se juge entièrement.
- **Une couche solide avant la suivante** (dossier 02) : le 4A pose ce dont le choix a besoin et rien de plus (espèces, types pour le choix du rival, instance de Pokémon dans l'équipe). Le 4B pose les règles de combat au moment où l'on peut les régler en jouant (dégâts, rythme).
- Le 4A se termine sur une réplique qui **annonce** le combat : la coupure est naturelle, comme la fin provisoire de la T3 du 3B.
- Les données de combat (capacités, statistiques) sont écrites **dès le 4A**, parce que l'instance de Pokémon en a besoin (PV, PP) : le 4B n'ajoute aucune donnée d'espèce.

Le 4B ne commence qu'une fois le 4A **validé par Kevin**. L'étape d'architecture du 4B (§2.2) peut être préparée sur sa branche pendant la QA du 4A sur le Mac (elle ne touche que des classes pures et leurs tests), mais rien n'est fusionné avant la validation.

---

## 2. Fondations logiques à poser (architecte)

Classes pures (`RefCounted`) et leurs tests, sur le modèle du §1 de `jalon-03.md`. Aucune ne dépend de l'arbre de scènes ni d'un autoload.

### 2.1 Avant le 4A (T0)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/systems/random/game_rng.gd` | `GameRng` | **Aléatoire injectable** : enveloppe un `RandomNumberGenerator` à graine (`_init(seed := -1)`, −1 = graine tirée et gardée). `roll(n) -> int` (1..n), `range(a, b) -> int`, `chance(num, den) -> bool`, `pick_index(size) -> int`, `get_seed()`. Tout l'aléatoire du jeu (IV, sexe, combat, IA) passe par elle. Les tests utilisent `tests/helpers/scripted_rng.gd` (hérite de `GameRng`, renvoie une file de valeurs imposées et échoue si la file est vide). |
| `game/pokemon/type_chart.gd` | `TypeChart` | Table des types **moderne** (18 types, dossier 04 « Types : système moderne »). `has_type(id)`, `get_type_name(id) -> String`, `multiplier(attack_type, defender_types: Array[StringName]) -> float` (produit ; 1 par défaut ; `&""` = sans type → 1). |
| `game/pokemon/species/species_data.gd` | `SpeciesData` | Une espèce : `id`, `dex`, `name`, `types` (1 ou 2), `base_stats: Dictionary[StringName, int]` (`hp atk def spa spd spe`), `male_ratio` (−1 = asexué), `learnset: Array` de `[niveau, move_id]`. `moves_at(level) -> Array[StringName]` : les **4 dernières** capacités apprises au plus tard à ce niveau (règle moderne), sans doublon. |
| `game/pokemon/moves/move_data.gd` | `MoveData` | Une capacité : `id`, `name`, `type`, `category` (enum `Category { PHYSICAL, SPECIAL, STATUS }`), `power` (0 = aucune), `accuracy` (0 = ne rate jamais), `pp`, `priority`, `effects: Array[MoveEffect]`, `description` (pression longue, texte `draft`), `typeless` (Lutte). |
| `game/pokemon/moves/move_effect.gd` | `MoveEffect` | Effet secondaire : `kind` (enum `Kind { STAT_STAGE, RECOIL }`), `stat`, `stages`, `target` (`SELF` / `FOE`), `fraction` (recul). Deux sortes seulement : celles du jalon. |
| `game/pokemon/pokemon_data.gd` | `PokemonData` | **Point d'entrée des données** : lit `data/pokemon/types.json`, tous les `.json` de `data/pokemon/species/` et de `data/pokemon/moves/` (`load_dir(root := DATA_DIR)`), sur le modèle exact de `DialogueLibrary` : clé inconnue, type manquant, valeur hors bornes, identifiant en double d'un fichier à l'autre, JSON illisible (avec la ligne). **Références croisées** vérifiées après chargement : chaque type d'espèce et de capacité existe dans la table, chaque capacité d'un learnset existe. Une entrée invalide est écartée (`push_error`, `get_errors()`). `get_species(id)`, `get_move(id)`, `get_type_chart()`, `get_species_ids()`, `get_move_ids()`. |
| `game/pokemon/stat_calc.gd` | `StatCalc` | Formules **modernes** (statiques, pures). PV = ⌊(2·B + IV + ⌊EV/4⌋)·N/100⌋ + N + 10 ; autres = ⌊⌊(2·B + IV + ⌊EV/4⌋)·N/100⌋ + 5⌋ × nature (1,0 en 4). `compute(species, level, ivs, evs) -> Dictionary[StringName, int]`. |
| `game/pokemon/move_slot.gd` | `MoveSlot` | `move_id`, `pp`, `max_pp`. `use() -> bool`, `restore()`. |
| `game/pokemon/pokemon.gd` | `Pokemon` | **Instance** : `species_id`, `nickname` (vide = nom de l'espèce), `level`, `gender` (enum `Gender { NONE, MALE, FEMALE }`), `ivs`, `evs`, `stats` (calculées), `hp`, `moves: Array[MoveSlot]` (1 à 4). `display_name(data)`, `max_hp()`, `take_damage(n) -> int` (borné à 0, renvoie les PV perdus), `heal_full()` (PV et PP), `is_fainted()`, `recalc(data)`, `to_dict()` / `static from_dict(dict, data)` (future sauvegarde, testés dès maintenant). |
| `game/pokemon/pokemon_factory.gd` | `PokemonFactory` | `create(data, species_id, level, rng) -> Pokemon` : IV tirés 0..31 (Q9), EV 0, sexe selon `male_ratio`, capacités `moves_at(level)`, PV pleins. Espèce inconnue : `push_error`, null. |
| `game/pokemon/party.gd` | `Party` | **Équipe** (6 max, dossier 04 §5) : `add(pokemon) -> bool` (faux si pleine), `get_lead()`, `get_all()`, `size()`, `is_full()`, `first_able() -> Pokemon` (premier non K.O.), `heal_all()`, `clear()`, `to_array()` / `load_array()`. |
| `game/pokemon/starter_offer.gd` | `StarterOffer` | Lit `data/pokemon/starters.json` (§3.2) : `map_id`, `level`, `prompt`, `choices` (espèce, PNJ de la carte, phrase de la fiche). `get_choice(species)`, `get_npc_ids()`. **`rival_pick(player_species, data) -> StringName`** : parmi les starters restants, celui dont **un type** donne le plus grand multiplicateur contre les types du starter du joueur ; à égalité, l'ordre du fichier (dossier 02 §9 : « il choisit le Pokémon avantagé contre celui du joueur »). Règle générale, **aucun nom d'espèce dans le code**. |
| `game/world/interactions/interaction.gd` (ajout) | `Interaction` | `Kind.MEET` (**en fin d'enum**) = « Rencontrer » ; `kind_name` → `&"meet"`, `kind_from_name("meet")`. `is_valid()` : une interaction MEET n'a pas de dialogue mais exige une `source`. `NpcRoster` continue de refuser `meet` dans les données (le verbe est posé par le code, §3.5). |
| `game/systems/cutscene/*` (ajout au 3B) | `CutsceneStep`, `CutsceneLibrary` | **Alias d'acteurs** `"$nom"` et trois étapes : `hop`, `lean`, `despawn` (§3.6). La bibliothèque valide la forme `$[a-z_]+` ; la résolution se fait au `play`. Le type `battle` est ajouté **en 4B** (§2.2). |

Tests : `tests/unit/test_game_rng.gd` (graine reproductible, bornes, `chance`), `test_type_chart.gd` (18 types ; Feu → Plante/Poison = 2, Eau → Feu = 2, Plante → Eau = 2, Normal → Spectre = 0, Plante → Feu = 0,5, double faiblesse = 4 ; valeurs de la table ∈ {0 ; 0,5 ; 2}), `test_pokemon_data.gd` (vraies données chargées sans erreur ; fixtures `tests/fixtures/pokemon/` : une valide, une par cas d'erreur, dont référence croisée cassée), `test_stat_calc.gd` (valeurs calculées à la main : Salamèche N5, IV 0 et IV 31), `test_species_data.gd` (`moves_at` : ordre, 4 max, niveau 1), `test_pokemon.gd` (dégâts bornés, K.O., soin, PP, aller-retour `to_dict`), `test_pokemon_factory.gd` (graine fixe → même Pokémon ; IV dans 0..31 ; ratio de sexe sur 1 000 tirages), `test_party.gd`, `test_starter_offer.gd` (les 3 cas du rival ; égalité → ordre du fichier), `test_interaction.gd` (+ MEET), `test_cutscene_library.gd` (+ alias, `hop`, `lean`, `despawn`).

### 2.2 Avant le 4B (T5)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/battle/battler.gd` | `Battler` | Le Pokémon **en jeu** d'un camp : référence au `Pokemon`, **niveaux de stats** (`atk def spa spd spe`, −6..+6, plus `acc eva` réservés à 0), `effective_stat(stat, ignore_drops := false, ignore_boosts := false)`, multiplicateur moderne max(2, 2+s)/max(2, 2−s), `change_stage(stat, delta) -> int` (variation réellement appliquée, 0 si déjà au bout). |
| `game/battle/battle_side.gd` | `BattleSide` | Un camp : `trainer_name` (vide = sauvage, jalon 5), `party`, `active: Battler`, `is_player`, `ai: BattleAI` (null pour le joueur). |
| `game/battle/battle_action.gd` | `BattleAction` | Choix d'un tour : `kind` (enum `Kind { MOVE }`, prévu pour `SWITCH`, `ITEM`, `RUN`), `move_index` (−1 = Lutte). |
| `game/battle/battle_event.gd` | `BattleEvent` | **Une ligne du journal** (donnée pure) : `kind` (enum `Kind { BATTLE_STARTED, SENT_OUT, TURN_STARTED, MOVE_USED, MOVE_MISSED, DAMAGE, NO_EFFECT, STAT_CHANGED, STAT_UNCHANGED, RECOIL, FAINTED, BATTLE_ENDED }`), `side` (enum `Side { PLAYER, FOE }`), `move_id`, `amount`, `hp`, `max_hp`, `effectiveness`, `critical`, `stat`, `stages`, `outcome`. Chaque événement porte **l'état d'après** (PV restants) : la présentation n'interroge jamais le moteur pendant qu'elle joue. |
| `game/battle/damage_calc.gd` | `DamageCalc` | Formule **moderne** (5e génération et suivantes) : base = ⌊⌊⌊2·N/5 + 2⌋ · P · A / D⌋ / 50⌋ + 2, puis dans l'ordre critique ×1,5, aléatoire ⌊× (85..100) / 100⌋, STAB ×1,5, efficacité ; minimum 1 si l'efficacité n'est pas nulle. Catégorie **par capacité** (physique : Atq/Déf ; spéciale : Atq. Spé/Déf. Spé). Critique : 1 chance sur 24, ignore les baisses d'attaque de l'attaquant et les hausses de défense de la cible. Précision : `rng.roll(100) <= accuracy`. `compute(attacker, defender, move, chart, rng) -> DamageResult` (`amount`, `critical`, `effectiveness`, `hit`). |
| `game/battle/battle_ai.gd` | `BattleAI` | `choose(own: BattleSide, foe: BattleSide, rng) -> BattleAction`. Une seule IA en 4B, **`random`** : une capacité au hasard parmi celles qui ont des PP (Lutte sinon). Dossier 05 §19 : le rival débutant « fait des erreurs ». |
| `game/battle/battle.gd` | `Battle` | **Moteur** : machine à états `State { READY, CHOOSING, OVER }`. `start() -> Array[BattleEvent]` (présentation des camps, envois) ; `get_usable_moves() -> Array[int]` ; `submit(action) -> Array[BattleEvent]` : **un tour entier** (choix de l'IA, ordre par priorité puis Vitesse effective, égalité tirée au sort, exécution, K.O., fin) ; `get_outcome()` (`Outcome { NONE, WIN, LOSS }`, du point de vue du joueur) ; `get_turn()`. Un Pokémon sans PP utilise **Lutte** (sans type, recul d'¼ des PV max). Refuse une action illégale (`push_error`, tableau vide). Aucune dépendance à l'arbre. |
| `game/battle/trainer_data.gd` / `trainer_library.gd` | `TrainerData`, `TrainerLibrary` | Lit `data/trainers/*.json` (même validation que les autres bibliothèques, espèces vérifiées contre `PokemonData`) : `name`, `ai`, `can_lose`, `heal_after`, `team_by_starter` (équipe selon le **starter du joueur**, comme Rouge/Bleu pour tous les combats du rival à venir). `build_team(trainer_id, player_starter, data, rng) -> Party`. |
| `game/battle/battle_text.gd` | `BattleText` | Traduit un `BattleEvent` en phrase à partir des modèles de `data/battle/messages.json` (`{pokemon}`, `{move}`, `{trainer}`, `{stat}`) ; chaîne vide = pas de message (ex. `TURN_STARTED`). Pur, testé sur chaque sorte d'événement. |
| `game/battle/battle_layout.gd` | `BattleLayout` | Placement de la vue de combat (§3.7) : `anchors(view_size: Vector2) -> Dictionary` (pieds du Pokémon du joueur, de l'adversaire, zoom de caméra), en fractions de l'écran tirées de `combat-v1.webp`. Testé à 1920 × 1080 et 2340 × 1080. |
| `game/systems/cutscene/*` (ajout) | `CutsceneStep`, `CutsceneLibrary` | Étape `battle` (§3.6), validée : `battle`, `player_pokemon`, `foe_pokemon`, `win`, `lose`. |

Tests : `tests/unit/test_battler.gd` (bornes −6/+6, multiplicateurs), `test_damage_calc.gd` (**valeurs attendues calculées à la main** avec `ScriptedRng` : Charge de Bulbizarre N5 sur Salamèche N5, avec et sans critique, avec Rugissement subi ; minimum 1 ; efficacité 0 → 0 dégât ; un critique ignore la baisse d'attaque), `test_battle.gd` (ordre par Vitesse, priorité, égalité tirée ; Rugissement → `STAT_CHANGED` −1 puis `STAT_UNCHANGED` à −6 ; raté ; K.O. → `FAINTED` puis `BATTLE_ENDED` sans action du camp K.O. ; PP décomptés ; Lutte quand tout est à 0 ; action illégale refusée ; **combat complet reproductible** avec une graine fixe : même journal deux fois), `test_battle_ai.gd`, `test_trainer_library.gd` (fixtures + vraies données ; **cohérence** : pour chaque starter, l'équipe du `rival_lab` est `StarterOffer.rival_pick`), `test_battle_text.gd`, `test_battle_layout.gd`.

---

## 3. Architecture

### 3.1 Arbre des scènes

```
game/boot.tscn
Boot (Node)  game/boot.gd                     racine de composition (câblage seulement)
├─ World (Node2D)                 %World
├─ BattleStage (instance)         %BattleStage          CanvasLayer 5 : Pokémon en vue de combat (4B)
├─ ExplorationHud (instance)      %ExplorationHud       + légende sur le monde (4A)
├─ BattleHud (instance)           %BattleHud            CanvasLayer 12 : cartes, grilles, messages (4B)
├─ StarterSheet (instance)        %StarterSheet         CanvasLayer 20 : fiche du starter (4A)
├─ DialogueBox (instance)         %DialogueBox          inchangé
├─ DialogueRunner (Node)          %DialogueRunner       inchangé
├─ InteractionController (Node)   %InteractionController  + MEET → meet_requested (4A)
├─ CutsceneDirector (Node)        %CutsceneDirector     (3B) + alias, hop, lean, despawn (4A), battle (4B)
├─ StarterChoice (Node)           %StarterChoice        game/systems/starter/starter_choice_controller.gd (4A)
├─ BattleDirector (Node)          %BattleDirector       game/battle/battle_director.gd (4B)
└─ ScreenFade (instance)          %ScreenFade

Autoloads : SceneRouter (inchangé) · GameState (+ équipe, starter, aléatoire)
```

`Boot._ready` (ajouts ; l'ordre reste : tout brancher **avant** `SceneRouter.start`) :
```gdscript
_pokemon.load_dir()                                   # PokemonData : data/pokemon/
_offer.load_file()                                    # StarterOffer : data/pokemon/starters.json
%StarterChoice.setup(_offer, _pokemon, GameState, _player, %StarterSheet, _hud,
		%CutsceneDirector, %InteractionController)
# 4B
_trainers.load_dir()                                  # TrainerLibrary : data/trainers/
%BattleDirector.setup(_pokemon, _trainers, _texts, %BattleStage, %BattleHud, _player, GameState)
%CutsceneDirector.set_battle_runner(%BattleDirector)
# battle_started / battle_finished et sheet_opened / sheet_closed → _refresh_controls()
```
`_refresh_controls()` (introduit par le 3B) devient : contrôles visibles seulement si **aucun** dialogue, scène, combat ni fiche n'est en cours. `Boot._on_map_changed` (3B) appelle aussi `%StarterChoice.set_map(map)`.

`StarterChoice` reçoit `GameState` (l'objet autoload) par `setup` au lieu de le lire : en test, on lui passe une instance neuve de `game_state.gd`, comme pour le routeur.

### 3.2 Données en fichiers (`data/`)

**Pourquoi du JSON, pas des `.tres`** : c'est déjà le format des dialogues, des PNJ et des scènes (3A, 3B). Kevin écrit ses données avec ChatGPT et les relit dans un diff ; les bibliothèques valident strictement au lancement **et** dans les tests (faute de frappe attrapée avec le numéro de ligne) ; un `.tres` se modifie mal hors de l'éditeur et ne dit pas où est l'erreur. Les classes `SpeciesData`, `MoveData`… restent des `RefCounted` construites par les bibliothèques. **Export** : comme `data/dialogues/`, vérifier `unzip -l` sur l'APK (T4, T8) ; sinon `include_filter="data/*"`.

Arborescence :
```
data/pokemon/types.json              table des types (une seule table)
data/pokemon/species/kanto.json      espèces (4 : les 3 starters ; 151 à terme, plusieurs fichiers possibles)
data/pokemon/moves/moves.json        capacités
data/pokemon/starters.json           l'offre du labo (4A)
data/trainers/rival.json             combats du rival (4B)
data/battle/messages.json            modèles des messages de combat (4B, draft)
```
Chaque bibliothèque lit **tous** les `.json` de son dossier ; les identifiants sont uniques dans tout le dossier (règle des dialogues). Format complet en tête de chaque classe.

`types.json` — noms affichés et table complète (18 types, seules les valeurs ≠ 1) :
```json
{
	"types": { "normal": { "name": "Normal" }, "fire": { "name": "Feu" }, "grass": { "name": "Plante" } },
	"chart": { "fire": { "grass": 2, "water": 0.5, "fire": 0.5 }, "normal": { "ghost": 0 } }
}
```
(extrait ; la table entière est saisie dès le 4A : elle est courte et évite un état partiel.) Les **couleurs** de type restent dans `UiTokens` (skill `ui-theme-2026`), pas dans les données.

`species/kanto.json` — valeurs officielles modernes ; 3 starters, plus rien (le rival prend l'un d'eux) :
```json
{
	"charmander": {
		"dex": 4, "name": "Salamèche", "types": ["fire"],
		"base_stats": { "hp": 39, "atk": 52, "def": 43, "spa": 60, "spd": 50, "spe": 65 },
		"male_ratio": 0.875,
		"learnset": [[1, "scratch"], [1, "growl"]]
	}
}
```
Le learnset ne contient **que** les capacités de départ en 4 (Q8) ; il s'allonge avec l'XP. Clés refusées tant qu'elles ne servent pas (courbe d'XP, rendement, évolutions) : on les ajoute avec leur jalon. Le sprite suit l'identifiant (`charmander` = sprite du monde de 3A et sprites de combat `charmander_front` / `charmander_back`).

`moves/moves.json` — 5 capacités : `tackle` (Charge), `scratch` (Griffe), `growl` (Rugissement), `tail_whip` (Mimi-Queue), `struggle` (Lutte) :
```json
{
	"growl": {
		"name": "Rugissement", "type": "normal", "category": "status",
		"accuracy": 100, "pp": 40,
		"effects": [{ "stat": "atk", "stages": -1, "target": "foe" }],
		"description": "…", "draft": true
	}
}
```
`description` sert à la fiche de la pression longue (dossier 05 §7) : texte à écrire par Kevin, marqué `draft` (Q15). Valeurs modernes : Charge et Griffe 40 / 100 % / 35 PP ; Rugissement 100 % / 40 PP ; Mimi-Queue 100 % / 30 PP ; Lutte 50, sans type, recul ¼.

`starters.json` (textes du dossier 02 §7, **définitifs**) :
```json
{
	"map": "oak_lab", "level": 5,
	"prompt": "CHOISIS TON PREMIER PARTENAIRE",
	"choices": [
		{ "species": "bulbasaur", "npc": "bulbasaur", "blurb": "Calme et tenace." },
		{ "species": "charmander", "npc": "charmander", "blurb": "Fougueux et courageux." },
		{ "species": "squirtle", "npc": "squirtle", "blurb": "Vif et malicieux." }
	],
	"open_flag": "starter_offered", "done_flag": "starter_chosen",
	"chosen_scene": "starter_chosen"
}
```
La fiche affiche le **nom de l'espèce en majuscules** et **les noms des types** (« Plante / Poison ») depuis `PokemonData` : rien n'est recopié. Les drapeaux et la scène sont des données : aucun `if flag == "starter_offered"` dans le code.

`trainers/rival.json` (4B) :
```json
{
	"rival_lab": {
		"name": "Rival", "ai": "random", "can_lose": true, "heal_after": true,
		"team_by_starter": {
			"bulbasaur": [{ "species": "charmander", "level": 5 }],
			"charmander": [{ "species": "squirtle", "level": 5 }],
			"squirtle": [{ "species": "bulbasaur", "level": 5 }]
		}
	}
}
```
`battle/messages.json` (4B) : un modèle par sorte d'événement, **tous `draft`** tant que Kevin ne les a pas relus (Q13).

### 3.3 Logique Pokémon (`game/pokemon/`)

- Un `Pokemon` ne connaît que des identifiants ; les noms et les valeurs viennent de `PokemonData`, passé en paramètre (`display_name(data)`, `recalc(data)`). Aucune référence à un autoload.
- Le **joueur** reçoit son starter par `PokemonFactory.create(data, species, offer.level, GameState.rng)`, ajouté à `GameState.party`.
- Le **Pokémon du rival** n'est pas stocké : il est créé au début du combat par `TrainerLibrary.build_team` (4B). En 4A, seul son **identifiant d'espèce** sert (quel Pokémon saute de la table).
- `GameState.rng` : une `GameRng` créée par `new_game()`, graine tirée et affichée dans les journaux en debug (reproduire un combat vu en QA). Les tests passent la leur.

### 3.4 Logique de combat testable sans scène (`game/battle/`)

Le moteur **ne joue rien** : il produit un **journal d'événements** que la présentation joue ensuite, dans l'ordre, à son rythme.
```
Battle.start()                ─► [BATTLE_STARTED(Rival), SENT_OUT(FOE, squirtle), SENT_OUT(PLAYER, charmander)]
Battle.submit(MOVE 0)         ─► [TURN_STARTED(1),
                                  MOVE_USED(PLAYER, scratch), DAMAGE(FOE, 7, hp 12/19, ×1, crit non),
                                  MOVE_USED(FOE, tail_whip), STAT_CHANGED(PLAYER, def, −1)]
…                             ─► [… , FAINTED(FOE), BATTLE_ENDED(WIN)]
```
- **Ordre** : priorité, puis Vitesse effective (niveaux compris), puis tirage.
- **Précision** : capacité à 0 = ne rate jamais ; sinon un tirage 1..100. Les niveaux de précision et d'esquive existent dans `Battler` (bornés, à 0) mais aucune capacité du jalon ne les modifie.
- **Critiques, STAB, aléatoire 85–100 %, efficacité** : `DamageCalc` (§2.2).
- **Modifications de stats** : `STAT_CHANGED` avec la variation réelle ; `STAT_UNCHANGED` si la stat est déjà à −6 (le message dira qu'elle ne peut plus baisser).
- **Fin** : dès qu'un camp n'a plus de Pokémon valide. `Outcome` du point de vue du joueur. La conséquence (soin, défaite sans retour au Centre) est décidée **hors du moteur**, par le directeur, d'après `TrainerData` (`can_lose`, `heal_after`).
- **IA** : `BattleAI` par nom (`"random"`), choisie par `TrainerData.ai`. L'IA qui « connaît le joueur » (dossier 05 §19) viendra avec les combats suivants du rival.
- **Aléatoire** : uniquement la `GameRng` reçue. Même graine, mêmes actions → même journal (test).

### 3.5 Choix du starter (4A)

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : le starter rejoint l'équipe **après** « On dirait que le choix est réciproque. » (§13.3), pas à CHOISIR.

**Déroulé :**
1. **Discours de Chen** : la scène `oak_intercept` du 3B **reçoit des étapes à la fin** (3B §2.10, première option : une seule scène ininterrompue du gel de la Route 1 jusqu'au choix). Après `set: [oak_lab_reunion]` : `wait`, `dialogue: oak_starter_offer` (§4.1), `set: [starter_offered]`. Fin de la scène, le joueur reprend la main.
2. **Ouverture du choix** : `StarterChoice` apprend l'ouverture par `GameState.flags.flag_changed(open_flag)` et **attend la fin de la scène** (`CutsceneDirector.cutscene_finished`) pour afficher la légende « CHOISIS TON PREMIER PARTENAIRE » (`ExplorationHud.show_caption`, §3.8). Il pose sur les trois PNJ starters une **interaction « Rencontrer »** : `npc.set_interaction_override(Interaction.new(Kind.MEET, cell, &"", ZERO, npc))`. Elle remplace « Observer » tant que le choix est ouvert, **y compris** si le joueur sort et revient (`set_map` la repose ; la légende se réaffiche en revenant, Q2).
3. **Rencontrer** : l'`InteractionController` voit une cible `MEET` (bouton RENCONTRER). À l'appui, au lieu de jouer un dialogue, il émet `meet_requested(npc)`. `StarterChoice` bloque le joueur (`&"starter_choice"`), le Pokémon **s'avance** (`Npc.lean_toward(player_cell)` : léger glissement de ~20 px vers le joueur, `Tween`), puis la **fiche** s'ouvre (`StarterSheet.open(view)`).
4. **RETOUR** : la fiche se ferme, le Pokémon revient (`Npc.settle()`), le joueur est libéré.
5. **CHOISIR** : la fiche se ferme ; `StarterChoice` applique le choix, **de façon synchrone** :
   - `rival = offer.rival_pick(player, data)` ;
   - `GameState.party.add(PokemonFactory.create(...))`, `GameState.starter_species = player` ;
   - drapeaux : `starter_chosen`, `taken_<player>`, `taken_<rival>` (les deux Pokémon quittent la table pour de bon, §4.3) ;
   - retrait des interactions « Rencontrer » ;
   - `cutscene_director.play(offer.chosen_scene, { &"player_starter": player_npc, &"rival_starter": rival_npc })`.
   Le blocage `&"starter_choice"` n'est rendu qu'**après** l'appel à `play` (qui pose `&"cutscene"`) : le joueur n'est jamais libre entre les deux.
6. **Scène `starter_chosen`** (données, §4.2) : le starter saute de la table et reste devant le joueur, Chen, le choix du rival, le départ, « Attends. ». En 4B, le combat et la fin s'y ajoutent.

**Pourquoi un contrôleur de code pour le choix, et des données pour la mise en scène** : le choix est une interface (fiche, deux boutons, retour possible) et modifie l'état de jeu (équipe) ; c'est de la logique, testable. Tout ce qui est **joué** (qui saute, qui parle, qui marche) reste dans des fichiers de scène, réglables sans code.

`StarterChoice` (`game/systems/starter/starter_choice_controller.gd`) :
```gdscript
signal sheet_opened
signal sheet_closed
signal starter_chosen(player_species: StringName, rival_species: StringName)
const REASON: StringName = &"starter_choice"
func setup(offer: StarterOffer, data: PokemonData, state: Node, player: Player, sheet: StarterSheet,
		hud: ExplorationHud, cutscenes: CutsceneDirector, interactions: InteractionController) -> void
func set_map(map: GameMap) -> void          # repose « Rencontrer » si le choix est ouvert
func is_open() -> bool                      # choix ouvert (drapeau posé, pas encore choisi)
func is_sheet_open() -> bool
```
`StarterSheet` (UI, §3.8) ne connaît ni Pokémon ni données : il reçoit une petite vue (`StarterSheetView` : nom, noms et identifiants de types, phrase) et émet `choose_pressed` / `back_pressed`.

**Nouveaux besoins sur `Npc`** (en plus du 3B) : `set_interaction_override(interaction)` / `clear_interaction_override()` (`get_interaction()` renvoie la surcharge si elle existe, sans allocation) ; `lean_toward(cell)` / `settle()` ; `hop_to(cell, grid) -> bool` (saut en arc ~0,35 s depuis la table : l'élévation `lift` descend à 0, la case change, la grille est mise à jour ; faux si la case d'arrivée est prise ou solide). `hop_to` sert aussi au Pokémon du rival.

### 3.6 Scènes scriptées : ce que le 4 ajoute au format du 3B

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : alias, `hop`, `lean`, `despawn` validés en T0 ; le style de saut vient du PNJ (`hop_style`, §13.4).

Rien n'est changé dans les 7 étapes du 3B. Ajouts (validés par `CutsceneLibrary`, format en tête du fichier) :

| Ajout | Forme | Effet |
|---|---|---|
| **Alias** d'acteur | `"$player_starter"` partout où un acteur ou une cible d'acteur est attendu | Résolu **au début de chaque étape** à partir du dictionnaire passé à `play(id, aliases)`. Alias absent : `push_error`, étape sautée (comme un acteur introuvable en 3B). Un alias vaut un **identifiant de PNJ** de la carte. |
| `hop` (4A) | `"hop": acteur`, `"to": case` (absolue ou `near`) | `Npc.hop_to` ; l'étape attend la fin du saut. Case refusée : `push_error`, étape sautée. |
| `lean` (4A) | `"lean": acteur`, `"to": cible` | Le PNJ s'avance légèrement vers la cible puis revient (« il s'approche légèrement », dossier 02 §8). |
| `despawn` (4A) | `"despawn": acteur` | `GameMap.remove_npc(id)` (3B) : case libérée, nœud retiré. Petit fondu de 0,2 s (retour dans la Ball, départ par la porte). |
| `battle` (4B) | `"battle": dresseur`, `"player_pokemon"`, `"foe_pokemon"` (acteurs), `"win"`, `"lose"` (drapeaux) | `await battle_runner.run(dresseur, map, { player: …, foe: … })` (acteurs résolus) ; lève `win` ou `lose` selon l'issue. Pas de runner branché : `push_error`, étape sautée. |

`CutsceneDirector.play(cutscene_id, aliases := {}) -> bool` et `set_battle_runner(runner: Node)`. Pas de branchement dans les scènes : **l'issue du combat** ne change que des **drapeaux**, et ce sont les **variantes de dialogue** (`if` / `unless`, 3A) qui en tiennent compte après le combat.

### 3.7 Le combat dans le décor actuel (4B)

**Décision** : le combat **ne change pas de scène**. Il se joue **par-dessus la carte courante**, qui reste chargée, éclairée et animée derrière (dossier 05 §2, décision préférée de Kevin, « continuité totale »). Pas de `SceneRouter.change_map`, pas de fondu au noir. Le même mécanisme servira sur la Route 1 (jalon 5).

**Composition** (défaut, Q23) : le monde est vu du dessus, alors que `combat-v1.webp` montre une vue de face avec horizon. En 2D, on ne tourne pas la caméra : la carte reste **le fond réel du combat** (même pièce, même lumière), et les deux Pokémon passent en **sprites de combat** (dos pour le joueur, face pour l'adversaire), composés **en espace écran** comme sur la référence :
- `BattleStage` (`game/battle/battle_stage.tscn`, `CanvasLayer`, `layer = UiTokens.LAYER_BATTLE_STAGE = 5`, entre le monde et l'UI) : deux `Sprite2D` NEAREST + une ombre au sol chacun ; positions données par `BattleLayout.anchors(view_size)` (pieds du Pokémon du joueur vers (0,33 ; 0,70) de l'écran, adversaire vers (0,70 ; 0,52), à régler sur capture) ; un voile sombre plein écran à ~20 % et un léger vignettage pour détacher les Pokémon du décor.
- Les **PNJ Pokémon du monde** qui combattent (le starter du joueur et celui du rival, donnés par l'étape `battle`) sont **cachés** pendant le combat, puis réaffichés. Les dresseurs restent visibles à leur place dans le labo.
- **Caméra** : zoom 1,00 → 1,06 en 0,3 s sur le centre actuel (« la caméra se rapproche légèrement », dossier 04 §2 et 05 §3), rendu à la fin. Les tremblements d'impact décalent le `BattleStage` (`offset`) et, très peu, la caméra ; retour immédiat au cadrage (dossier 05 §4). `Player.get_camera()` existe déjà.
- La lumière dynamique de la phase 10 ne touchera pas automatiquement un `CanvasLayer` : le `BattleStage` prendra alors la teinte ambiante (`modulate`) de la carte. Noté pour la phase 10.

**Transition d'entrée** (~1 s, dossier 05 §3 « Dresseur ») : la scène a déjà fait parler le rival ; voile et zoom (0,3 s) ; les PNJ Pokémon du monde disparaissent dans un petit éclair tandis que leurs sprites de combat apparaissent (0,3 s) ; les cartes glissent (`ANIM_PANEL`) ; la grille d'actions arrive. **Sortie** : l'inverse, puis `battle_finished`.

**`BattleDirector`** (`game/battle/battle_director.gd`, Node, enfant de `Boot`) — le **seul** à jouer un combat :
```gdscript
signal battle_started(trainer_id: StringName)
signal event_played(event: BattleEvent)                 # tests, futurs sons
signal battle_finished(trainer_id: StringName, outcome: int)
const REASON: StringName = &"battle"
## Durées multipliées (0 = instantané en test).
var speed_scale: float = 1.0
## [param state] : l'autoload GameState en jeu, une instance neuve de game_state.gd en test
## (équipe, starter du joueur, aléatoire).
func setup(data: PokemonData, trainers: TrainerLibrary, texts: BattleText, stage: BattleStage,
		hud: BattleHud, player: Player, state: Node) -> void
## Coroutine : joue le combat et renvoie Battle.Outcome. [param world_actors] : rôle
## (&"player", &"foe") → identifiant du PNJ Pokémon de [param map] à cacher pendant le combat.
func run(trainer_id: StringName, map: GameMap,
		world_actors: Dictionary[StringName, StringName]) -> int
func is_running() -> bool
```
Déroulé : `player.set_input_enabled(false, REASON)` (synchrone) → `battle_started` → construction des camps (`state.party`, `TrainerLibrary.build_team(trainer_id, state.starter_species, …, state.rng)`) → `Battle.start()` → **boucle** : la HUD propose les actions ; le choix du joueur passe par `Battle.submit` ; chaque événement du journal est joué **l'un après l'autre** (message, animation, barre de PV) → fin : soin si `heal_after`, sortie, `player.set_input_enabled(true, REASON)`, `battle_finished`. Le directeur ne lit **pas** les autoloads : il reçoit `GameState` par `setup` (comme `StarterChoice`) et la carte par l'étape `battle` ; il n'appelle jamais `SceneRouter`. Refus (faux, `push_error`) si un combat tourne déjà.

**Interactions avec l'existant** : le routeur n'est jamais appelé ; `InteractionController` est déjà désactivé par la scène (3B, `set_enabled(false)`) ; le HUD d'exploration est caché par `_refresh_controls()` ; la `DialogueBox` n'est pas utilisée pendant le combat (messages dans la `BattleHud`) ; le joueur est bloqué pour trois raisons à la fois (`cutscene`, `battle`, puis `dialogue` après le combat) sans conflit, grâce aux raisons de 3A.

### 3.8 UI (non pixel art, skill `ui-theme-2026` ; la bible prime sur la planche)

**4A**
- **Bouton contextuel** : `InteractButton.VERBS` + `&"meet"` → « RENCONTRER », icône `assets/ui/icons/meet.svg` (Poké Ball au trait, Q4). Libellé plus long que « EXAMINER » : la pastille doit rester dans `SAFE_MARGIN`.
- **Légende sur le monde** : `WorldCaption` (`game/ui/components/world_caption.tscn`), **sans rectangle** (bible §5) : texte en `FONT_TITLE` majuscules, ombre portée `TEXT_SHADOW`, en haut au centre ; fondu 300 ms, tenue `CAPTION_HOLD` ≈ 3 s, fondu. `ExplorationHud.show_caption(text)` / `hide_caption()`. Jamais permanent (bible §11).
- **Fiche du starter** : `StarterSheet` (`game/ui/starter/starter_sheet.tscn`, `CanvasLayer` `LAYER_MENU`) : carte sombre translucide (`PANEL_BG`, coins `RADIUS`), **à gauche de l'écran**, centrée verticalement, pour laisser voir la table et le joueur ; NOM (`FONT_TITLE`), pastilles de type (icône + nom, couleur du type), phrase en italique (`FONT_BODY`), deux boutons ≥ `TOUCH_MIN` : **CHOISIR** (accent) et **RETOUR**. Entrée en glissement 40 px + fondu (`ANIM_PANEL`). Pas de statistiques (dossier 02 §3 : « jamais de fiche technique »). Sur Mac : clic souris ; `interact` = CHOISIR n'est **pas** branché (évite un choix par un appui de trop).
- **Icônes de type** SVG : `assets/ui/icons/types/normal.svg`, `grass.svg`, `poison.svg`, `fire.svg`, `water.svg` (les autres avec leurs premiers Pokémon).

**4B** — `BattleHud` (`game/ui/battle/battle_hud.tscn`, `CanvasLayer` `LAYER_BATTLE_HUD = 12`), d'après `combat-v1.webp` et `combat-capacites-v1.png.png` :
- **Carte adversaire** (haut droite) : NOM, ♂/♀, « Nv. 5 », barre de PV **sans chiffres**. **Carte joueur** (bas gauche) : même structure **avec** « 19 / 19 », et au-dessus **6 pastilles d'équipe** (Poké Ball = Pokémon présent, gris = vide). Cartes **translucides** (`PANEL_BG`, comme la boîte de dialogue : réponse proposée au « point à trancher » du dossier 05, Q17).
- **Barre de PV** (`HpBar`) : vert > 50 %, jaune > 20 %, rouge ≤ 20 % ; descente animée (`HP_TWEEN` 0,4 s), plus rapide sur un gros coup (> 25 % des PV max, `HP_TWEEN_FAST`) avec vibration ; légère pulsation de la carte sous 20 % (dossier 05 §12).
- **Grille d'actions** (bas droite, 2 × 2) : ATTAQUER (rouge, lueur d'accent qui **pulse doucement** : « le jeu montre subtilement ATTAQUER », dossier 05 §18) · SAC (or) · ÉQUIPE (bleu) · FUITE (gris sombre) ; icônes SVG. En 4B, SAC, ÉQUIPE et FUITE sont **visibles mais atténués** et sans effet (Q18).
- **Grille des capacités** : remplace la grille d'actions ; 4 emplacements en 2 × 2 sur un bandeau sombre ; chaque carte : icône et pastille de type, NOM, « PP x/y » en haut à droite, « Puissance 40 » ou « Statut » en bas à droite, teinte du type ; emplacement vide si moins de 4 capacités ; carte sans PP atténuée. **Toucher** = lancer (dossier 05 §7, Q16) ; **pression longue** (`LONG_PRESS` 0,45 s) = petite fiche (puissance, précision, catégorie, description). Bouton rond « ‹ » en bas à gauche, sous la carte joueur.
- **Messages de combat** : un bandeau sombre translucide **à la place de la grille** (bas droite, à droite de la carte joueur), jamais sous la carte joueur ; texte `FONT_BODY` ; chaque message reste `BATTLE_MESSAGE_HOLD` ≈ 0,9 s ou avance au toucher (Q12). Pas de « › » d'attente : le combat avance seul (dossier 05 §21).
- Signaux : `action_selected(action: StringName)`, `move_selected(index: int)`, `back_requested`. Méthodes : `set_card(side, view)`, `animate_hp(side, hp, max_hp, big)` (coroutine), `set_party(count)`, `show_actions(enabled: Dictionary[StringName, bool])`, `show_moves(views: Array[BattleMoveView])`, `show_message(text)` (coroutine), `hide_all()`. La HUD ne connaît ni `Battle`, ni `Pokemon`, ni les données : `BattleCardView` et `BattleMoveView` (petites classes de vue dans `game/ui/battle/`) portent des chaînes et des entiers.
- **Haptique** (bible §12) : coup reçu → `HAPTIC_HIT_MS` ; coup critique → `HAPTIC_CRIT_MS`, plus marqué.

**Tokens à ajouter** (`UiTokens`, T2 et T6) : `LAYER_BATTLE_STAGE = 5`, `LAYER_BATTLE_HUD = 12`, `CAPTION_HOLD`, `STARTER_SHEET_WIDTH`, `TYPE_COLORS` (les 15 de la skill **+ Acier, Ténèbres, Fée**, absentes de la skill alors que la table est moderne : couleurs usuelles `#B7B7CE`, `#705746`, `#D685AD`, Q10), `ACTION_ATTACK`, `ACTION_BAG`, `ACTION_TEAM`, `ACTION_RUN`, `BATTLE_CARD_WIDTH`, `HP_BAR_HEIGHT = 14`, `HP_TWEEN = 0.4`, `HP_TWEEN_FAST`, `HP_LOW_PULSE`, `BATTLE_MESSAGE_HOLD`, `LONG_PRESS`, `HAPTIC_HIT_MS`, `HAPTIC_CRIT_MS`, `BATTLE_DIM`, `BATTLE_ZOOM`. Variations de thème `BattleCard`, `ActionButton`, `MoveCard`, `TypeBadge`, `StarterSheet` dans `tools/build_ui_theme.gd`.

### 3.9 `GameState` et drapeaux

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : drapeaux du 4A (qui lève `starter_chosen`, `oak_lab_exit`) : §13.3.

`GameState` (autoload, sans `class_name`) garde son rôle — l'état de la partie — et gagne trois champs :
```gdscript
var flags: StoryFlags = StoryFlags.new()
var party: Party = Party.new()
var starter_species: StringName = &""
var rng: GameRng = GameRng.new()
func new_game(rng_seed: int = -1) -> void     # drapeaux, équipe, starter, nouvelle graine
```
Il ne connaît toujours aucun autre autoload. `Boot` le passe par `setup` à ceux qui en ont besoin.

| Drapeau | Levé par | Lu par |
|---|---|---|
| `starter_offered` | `oak_intercept`, après le discours de Chen (4A) | `StarterChoice` (`open_flag`) ; variantes de dialogue futures |
| `starter_chosen` | `StarterChoice`, à CHOISIR (`done_flag`) | la scène `starter_chosen` (`if`) ; **le blocage des hautes herbes du 3B** (§9) ; présence des PNJ |
| `taken_bulbasaur` / `taken_charmander` / `taken_squirtle` | `StarterChoice` (starter du joueur et du rival) | présence des starters sur la table (§4.3) |
| `rival_challenged` | fin de la scène `starter_chosen` en 4A (après « …ce qu'ils savent faire. ») | la scène elle-même (`unless`, un seul passage) |
| `rival_lab_won` / `rival_lab_lost` | étape `battle` (4B) | variantes des futures répliques d'après-combat (Q19) |
| `rival_left_lab` | fin de la scène (4B) | présence du rival au labo |

Les noms `taken_<espèce>` sont formés par le code à partir des identifiants de `starters.json` : c'est une convention de nommage, pas une règle sur une espèce. Le test de 3A « chaque drapeau lu est levé quelque part » (étendu en 3B aux scènes et aux PNJ) s'étend aux drapeaux levés par code : `StarterChoice.get_set_flags(offer)` les énumère.

### 3.10 Signaux et flux

```
4A
oak_intercept (3B) … dialogue oak_starter_offer ─► set starter_offered ─► cutscene_finished
GameState.flags.flag_changed(starter_offered) ──┐
CutsceneDirector.cutscene_finished ─────────────┴► StarterChoice ─► hud.show_caption(prompt)
                                                                  ─► Npc.set_interaction_override(MEET) ×3
Player face au starter ─► InteractionController ─► target_changed(MEET) ─► Boot ─► hud.show_interact(&"meet")
[RENCONTRER] ─► InteractionController.meet_requested(npc) ─► StarterChoice ─► Player bloqué (&"starter_choice")
                                                             ─► npc.lean_toward ─► StarterSheet.open(view)
StarterSheet.back_pressed ─► StarterChoice ─► close, npc.settle, joueur libre
StarterSheet.choose_pressed ─► StarterChoice ─► StarterOffer.rival_pick ─► GameState.party.add(PokemonFactory.create)
                                            ─► flags starter_chosen, taken_* ─► overrides retirés
                                            ─► CutsceneDirector.play(&"starter_chosen", aliases)
scène : hop · face · lean · dialogue · move (+follower) · set rival_challenged
4B (suite de la même scène)
battle ─► BattleDirector.run(...) ─► Player bloqué (&"battle") ─► battle_started ─► Boot._refresh_controls
      ─► Battle.start / submit ─► [BattleEvent] ─► BattleText ─► BattleHud.show_message
                                               ─► BattleStage.play_move / play_hit / play_faint
                                               ─► BattleHud.animate_hp
BattleHud.action_selected / move_selected ─► BattleDirector ─► Battle.submit
fin ─► soin (heal_after) ─► sortie ─► battle_finished ─► étape battle : set win | lose ─► suite de la scène
```
`Battle`, `PokemonData`, `StarterOffer` ne connaissent aucun nœud. `BattleHud`, `BattleStage` et `StarterSheet` ne connaissent ni le moteur ni les données. `GameMap`, `Npc` et `Player` ne connaissent ni `StarterChoice` ni `BattleDirector`. `Boot` reste la seule racine de composition.

### 3.11 Fichiers à créer ou modifier

```
data/pokemon/types.json · species/kanto.json · moves/moves.json · starters.json     (4A)
data/trainers/rival.json · data/battle/messages.json                              (4B)
data/cutscenes/prologue.json (étendu, 4A) · data/cutscenes/starter.json (4A, étendu 4B)
data/dialogues/oak_lab.json (étendu) · data/npcs/oak_lab.json (étendu)
game/systems/random/game_rng.gd
game/pokemon/type_chart.gd · pokemon_data.gd · stat_calc.gd · move_slot.gd · pokemon.gd
game/pokemon/pokemon_factory.gd · party.gd · starter_offer.gd
game/pokemon/species/species_data.gd · game/pokemon/moves/move_data.gd · move_effect.gd
game/systems/starter/starter_choice_controller.gd
game/battle/battle.gd · battler.gd · battle_side.gd · battle_action.gd · battle_event.gd
game/battle/damage_calc.gd · battle_ai.gd · trainer_data.gd · trainer_library.gd
game/battle/battle_text.gd · battle_layout.gd · battle_director.gd · battle_stage.tscn/.gd
game/ui/components/world_caption.tscn/.gd · game/ui/starter/starter_sheet.tscn/.gd
game/ui/battle/battle_hud.tscn/.gd · battle_card.tscn/.gd · hp_bar.gd · action_grid.tscn/.gd
game/ui/battle/move_card.tscn/.gd · move_grid.tscn/.gd · battle_message.tscn/.gd · views (BattleCardView, BattleMoveView)
modifiés : game_state.gd · boot.gd/.tscn · interaction.gd · interaction_controller.gd · npc.gd
           cutscene_step.gd · cutscene_library.gd · cutscene_director.gd (3B) · exploration_hud.gd/.tscn
           interact_button.gd · ui_tokens.gd · tools/build_ui_theme.gd
assets/ui/icons/meet.svg · types/*.svg · battle/attack.svg · bag.svg · team.svg · run.svg · back.svg
assets/sprites/pokemon/placeholder/<espèce>_front.png · <espèce>_back.png (+ .import)
tools/gen_placeholder_battlers.gd · tools/capture_play.gd (scénarios) · tools/capture_battle_ui.gd
tests/helpers/scripted_rng.gd · tests/fixtures/pokemon/ · tests/fixtures/trainers/
```
Les dossiers vides `game/pokemon/species/` et `game/pokemon/moves/` (jalon 0) reçoivent leurs classes ; `game/pokemon/encounters/` et `evolution/` restent vides.

### 3.12 Assets provisoires

- **Sprites de combat** (`tools/gen_placeholder_battlers.gd`, sur le modèle de `gen_placeholder_npcs.gd`) : pour `bulbasaur`, `charmander`, `squirtle`, une vue de **face** et une de **dos**, 64 × 64 natif, silhouettes et couleurs des sprites du monde (Salamèche : flamme de queue lisible de dos). Affichage **×3 pour l'adversaire (192 px), ×4 pour le Pokémon du joueur au premier plan (256 px)** (Q24). NEAREST. Deux images « respiration » par vue, ou une seule image et un léger `Tween` d'échelle.
- **Monde** : les sprites de starters de 3A (32 × 32, ×2) servent tels quels ; le saut de la table est une animation de position (`Tween`), sans nouvelle image.
- **Icônes** SVG vectorielles (types, actions, retour, « Rencontrer »).
- Effets : éclair blanc (modulate) à l'entrée, élan de ~60 px vers la cible pour une attaque physique, pulsation pour une capacité de statut, clignotement de la cible touchée, chute + fondu au K.O. Aucune particule obligatoire en 4B.

---

## 4. Données du jalon

Textes : **exactement** ceux du dossier 02 (§7 à §10), une réplique « … » = une page (convention de 3A). Étiquettes : « Prof. Chen » (décision de Kevin, 3B §7 point 6) et « Rival ». Didascalies → mise en scène (`turn`, `pause`, étapes de scène), jamais du texte affiché.

### 4.1 Dialogues (`data/dialogues/oak_lab.json`, ajouts)

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : voir §13.5 (pas de `rival_starter_smile` ; « Attends. » est un dialogue à part ; `oak_lab_exit_block`).

| id | Locuteur | Pages (dossier 02) | Mise en scène |
|---|---|---|---|
| `oak_starter_offer` | Prof. Chen | §7, les **4** répliques, de « Vous voulez tous les deux découvrir Kanto. » à « Alors... pourquoi ne pas commencer ensemble ? » | page 3 : `turn { "oak": "right" }` (« il regarde les trois Pokémon », table à sa droite) ; page 4 : `turn { "oak": "player" }` (Q5) |
| `oak_starter_reciprocal` | Prof. Chen | §8 : « On dirait que le choix est réciproque. » | Chen se tourne vers le joueur (`turn`) |
| `rival_starter_pick` | Rival | §9, 1re réplique : « Alors ce sera toi. » | le rival regarde son Pokémon (étape `face` avant) |
| `rival_starter_smile` | Rival | §9, 2e réplique : « Ça devrait être intéressant. » | « il le regarde, puis le joueur » : étapes `face` avant ; « petit sourire » : pas d'expression sur le sprite provisoire, rien (Q5) |
| `rival_challenge` | Rival | §10 : « Attends. » puis « On ne va quand même pas partir sans savoir ce qu'ils savent faire. » | « petit sourire » avant la 2e : `pause` 0,6 s (Q5) |

Aucune autre réplique n'est écrite : **Maya après le starter**, Chen et le rival après le combat, une éventuelle indication de Chen pendant le combat et la sortie du labo avant le choix sont des **questions** (Q3, Q14, Q19, Q22). Rien n'est marqué `draft` dans les dialogues.

### 4.2 Scènes

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : `oak_intercept` = variante 1 de `route1_grass` ; scène `starter_chosen` et sortie empêchée : §13.5 et §13.6.

**`oak_intercept`** (`data/cutscenes/prologue.json`, 3B) — étapes ajoutées à la fin :
```json
{ "wait": 0.5 },
{ "dialogue": "oak_starter_offer" },
{ "set": ["starter_offered"] }
```
**`starter_chosen`** (`data/cutscenes/starter.json`, nouveau) — jouée par `StarterChoice` avec les alias ; valeurs par défaut réglables dans ce fichier :
```json
{
	"starter_chosen": {
		"if": ["starter_chosen"], "unless": ["rival_challenged"],
		"steps": [
			{ "hop": "$player_starter",
				"to": { "near": "player", "offsets": [[0, 1], [-1, 0], [1, 0]] } },
			{ "face": "player", "to": "$player_starter" },
			{ "face": "$player_starter", "to": "player" },
			{ "wait": 0.4 },
			{ "lean": "$player_starter", "to": "player" },
			{ "dialogue": "oak_starter_reciprocal" },
			{ "face": "rival", "to": "$player_starter" },
			{ "wait": 0.6 },
			{ "face": "rival", "to": "$rival_starter" },
			{ "wait": 0.6 },
			{ "move": "rival", "to": { "near": "$rival_starter", "offsets": [[0, 1]] } },
			{ "face": "rival", "to": "$rival_starter" },
			{ "dialogue": "rival_starter_pick" },
			{ "hop": "$rival_starter",
				"to": { "near": "rival", "offsets": [[0, 1], [1, 0], [-1, 0]] } },
			{ "face": "rival", "to": "$rival_starter" },
			{ "wait": 0.5 },
			{ "face": "rival", "to": "player" },
			{ "dialogue": "rival_starter_smile" },
			{ "move": "rival", "to": [8, 8], "follower": "$rival_starter" },
			{ "wait": 0.4 },
			{ "face": "rival", "to": "$rival_starter" },
			{ "wait": 0.4 },
			{ "face": "rival", "to": "$player_starter" },
			{ "wait": 0.4 },
			{ "face": "rival", "to": "player" },
			{ "dialogue": "rival_challenge" },
			{ "set": ["rival_challenged"] }
		]
	}
}
```
Ce que cela donne : le starter choisi saute de la table vers la case sous le joueur (ou à côté si elle est prise), le joueur se tourne vers lui, il s'avance ; Chen ; le rival regarde le Pokémon du joueur, puis la table ; il va se placer sous son Pokémon (la case sous la table est toujours libre, le joueur étant sous un autre starter) ; « Alors ce sera toi. » ; son Pokémon saute près de lui ; il le regarde, puis le joueur ; « Ça devrait être intéressant. » ; il part vers la sortie, son Pokémon derrière lui ; il s'arrête, regarde les deux Pokémon, se retourne ; « Attends. » … **Fin du 4A.**

**4B** — la même scène continue (et `rival_challenged` passe à la dernière étape) :
```json
{ "battle": "rival_lab", "player_pokemon": "$player_starter", "foe_pokemon": "$rival_starter",
	"win": ["rival_lab_won"], "lose": ["rival_lab_lost"] },
{ "wait": 0.6 },
{ "despawn": "$rival_starter" },
{ "move": "rival", "to": [7, 9] },
{ "despawn": "rival" },
{ "set": ["rival_left_lab", "rival_challenged"] },
{ "despawn": "$player_starter" }
```
Par défaut (Q19, Q21) : **aucune réplique** après le combat, faute de texte ; le rival rappelle son Pokémon, sort par la porte ; le starter du joueur rentre dans sa Ball ; le joueur reprend la main. Les répliques de Kevin s'inséreront comme étapes `dialogue` à variantes `if: [rival_lab_won]` / `if: [rival_lab_lost]`.

### 4.3 PNJ du labo (`data/npcs/oak_lab.json`, format réel de 3A : objet « identifiant → PNJ »)

| id | Changement | Présence |
|---|---|---|
| `bulbasaur`, `charmander`, `squirtle` | condition ajoutée ; interaction « Observer » de 3A inchangée (le verbe « Rencontrer » est posé par `StarterChoice`) | `unless: [taken_<id>]` : le starter restant reste sur la table après le choix, observable (Q22) |
| `rival` (3B) | condition ajoutée | `if: [oak_met]`, `unless: [rival_left_lab]` (4B) |
| `oak`, `maya_working` (3B) | inchangés | Chen reste non interactif (Q14) |

Rappel : la présence n'est réévaluée **qu'au chargement de la carte** (3B §2.6). Pendant la scène, les Pokémon qui ont sauté restent où ils sont ; en revenant au labo, ils n'y sont plus (drapeaux `taken_*`).

### 4.4 Invariants (testés)

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : les placements ci-dessous ferment une poche du labo réel ; invariants remplacés par le §13.4.

**Labo, pour chacun des 3 choix** (`tests/integration/test_starter_placement.gd`, nouveau, grille réelle du labo, PNJ présents pour `{ oak_met, oak_lab_reunion, starter_offered }`) :
- chaque starter a une case **libre et atteignable** face à lui (10..12, 6) d'où `InteractionFinder.find` renvoie l'interaction MEET une fois la surcharge posée ;
- le joueur étant sous son starter, `resolve_cell` trouve une case d'atterrissage (première des `offsets`) ; ensuite le chemin du rival depuis (9, 6) jusqu'à la case sous son starter existe (`find_path`) ; l'atterrissage du Pokémon du rival existe ; le chemin vers (8, 8) avec suiveur est libre ; en 4B, le chemin du rival jusqu'à la porte (7, 9) aussi ;
- aucune de ces cases n'est un warp ni un déclencheur, et aucune n'enferme le joueur (pas de poche après la scène).

**Données** (`test_dialogue_data.gd`, `test_cutscene_data.gd` du 3B, étendus ; `tests/integration/test_pokemon_content.gd`, nouveau) :
- `PokemonData`, `StarterOffer`, `TrainerLibrary`, `BattleText` : les vraies données se chargent **sans erreur** ; chaque `choices[].species` existe, chaque `choices[].npc` existe dans `data/npcs/<map>.json` avec le même sprite que l'espèce ;
- chaque capacité de départ des starters a `pp > 0` ; chaque espèce a 1 à 4 capacités au niveau de l'offre ;
- **textes** : les pages de `oak_starter_offer`, `oak_starter_reciprocal`, `rival_starter_pick`, `rival_starter_smile`, `rival_challenge` sont **égales** aux chaînes du dossier 02 recopiées dans le test ; les phrases de fiche aussi ; chaque page tient en `DIALOG_MAX_LINES` ;
- **simulation statique** de `starter_chosen` pour les 3 jeux d'alias : chaque acteur existe à chaque étape ;
- chaque drapeau lu est levé quelque part (scènes, dialogues, PNJ, `StarterChoice`, étape `battle`).

---

## 5. Découpage des tâches (dans l'ordre)

Chaque tâche finit par un essai sur le S24 (capture et retour de Kevin) avant la suivante. Les tâches de code se font sur une branche cloud (`jalon-04a`, puis `jalon-04b`) ; les tâches `qa-mobile` sur le Mac.

### 4A — le choix du starter

#### T0 — architecte-godot : fondations du 4A

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : T0 fait, T1 et T3 précisés : §13.9.

- §2.1 : classes pures, données `data/pokemon/*` et leurs tests ; extensions `Interaction` et `CutsceneLibrary`. **Avant de commencer : aligner ce plan sur le code réel du 3B** (§9).
- **CA** : tous les tests du §2.1 verts ; `PokemonData.load_dir()` sur les vraies données : 0 erreur ; import sans erreur ; `tools/test.sh` vert.

#### T1 — constructeur-monde : état de partie, Chen propose, PNJ prêts pour le choix
- `GameState` (§3.9) ; `Npc.set_interaction_override`, `lean_toward`, `settle`, `hop_to` ; `InteractionController` : cible MEET → signal `meet_requested(npc)` au lieu d'un dialogue ; `CutsceneDirector` : alias, `hop`, `lean`, `despawn` ; `oak_starter_offer` ; étapes ajoutées à `oak_intercept` ; conditions `taken_*` dans `data/npcs/oak_lab.json`.
- **CA** :
  - `test_game_state.gd` : `new_game()` vide drapeaux, équipe et starter, change la graine ; `new_game(42)` deux fois → même graine ; toujours aucune référence à `SceneRouter`.
  - `test_npc.gd` : surcharge renvoyée par `get_interaction()` (même instance à chaque appel), puis retirée ; `hop_to` : case libérée puis occupée, `lift` à 0 à la fin, refus sur case prise ; `lean_toward` / `settle` sans changement de case.
  - `test_interaction_controller.gd` : face à un PNJ surchargé, `target_changed(MEET)` ; `interact` → `meet_requested(npc)`, **aucun** dialogue joué ; anti-rebond identique aux dialogues.
  - `test_cutscene_director.gd` : alias résolus dans `face`, `move`, `hop`, `lean`, `despawn` et dans les cibles `near` ; alias absent → `push_error`, étape sautée ; `hop` attend la fin du saut ; `despawn` libère la case.
  - `test_route1_event.gd` (3B, étendu) : après « Et pourtant, tu es toujours là. », les 4 répliques de Chen avec l'étiquette « Prof. Chen », Chen tourné vers la table à la 3e ; `starter_offered` levé ; contrôle rendu.
  - **S24** : tout le 3B, puis le discours de Chen ; le joueur reprend la main ; les starters s'observent encore (le choix n'est pas encore branché).

#### T2 — ui-mobile : RENCONTRER, légende, fiche du starter
- `InteractButton` + `meet` ; `WorldCaption` et `ExplorationHud.show_caption` ; `StarterSheet` (§3.8) ; icônes ; tokens et variations de thème. **Aucune** référence au joueur, aux cartes, aux données ou aux classes Pokémon dans `game/ui/`.
- **CA** :
  - `test_exploration_hud.gd` : `show_interact(&"meet")` → « RENCONTRER », icône `meet.svg`, pastille entièrement dans `SAFE_MARGIN` à 1920 et 2340 de large ; `show_caption(texte)` : visible, puis caché après fondu + `CAPTION_HOLD` + fondu (± 1 image), sans fond de panneau.
  - `tests/integration/test_starter_sheet.gd` : `open(view)` affiche nom, 1 ou 2 pastilles de type avec la bonne couleur de `TYPE_COLORS`, phrase en italique ; CHOISIR et RETOUR ≥ `TOUCH_MIN`, dans `SAFE_MARGIN` ; un toucher sur CHOISIR → **un** `choose_pressed` ; RETOUR → **un** `back_pressed` ; fermée : invisible, ne reçoit rien ; `interact` n'a aucun effet.
  - Capture Movie Maker (`tools/capture_hud.gd` étendu) à 2340 × 1080 : bouton RENCONTRER ; légende « CHOISIS TON PREMIER PARTENAIRE » sur le labo ; fiche de chacun des 3 starters. Lues avec Read : pas pixel art, fiche translucide à gauche, table et joueur visibles, textes identiques au dossier.
  - Couleurs, tailles, durées uniquement via `UiTokens`.

#### T3 — constructeur-monde : le choix et la réponse du rival
- `StarterChoice` (§3.5) ; câblage de `Boot` (§3.1) ; `data/cutscenes/starter.json` (§4.2) ; dialogues du §4.1 ; invariants du §4.4 ; alignement avec le blocage des herbes du 3B (§9).
- **CA** :
  - `tests/integration/test_starter_choice.gd` (mini-labo de fixtures, `GameState` neuf, graine fixe, texte instantané) : sans `open_flag`, aucune surcharge ; drapeau levé pendant une scène → légende et surcharges **après** `cutscene_finished` ; `meet_requested` → joueur bloqué (`&"starter_choice"`), fiche ouverte avec la bonne vue ; RETOUR → fiche fermée, Pokémon revenu, joueur libre ; CHOISIR → équipe de 1 (bonne espèce, niveau 5, PV pleins, 2 capacités), `starter_species`, drapeaux `starter_chosen` et deux `taken_*`, surcharges retirées, scène `starter_chosen` lancée avec les bons alias, joueur **jamais** libre entre la fiche et la scène ; sortie et retour au labo avant le choix : « Rencontrer » reposé.
  - `tests/integration/test_starter_event.gd` (vrai `Boot`, départ au labo avec `{ oak_met, oak_lab_reunion }`, fondus et texte instantanés) : **pour chacun des 3 starters** : RENCONTRER, CHOISIR, le Pokémon choisi quitte la table et se trouve à côté du joueur, les 5 répliques du §4.1 dans l'ordre avec les bons noms, le rival prend **le bon** Pokémon (Salamèche si Bulbizarre, Carapuce si Salamèche, Bulbizarre si Carapuce), `rival_challenged` levé, joueur libre, contrôles visibles. Ressortir et remonter vers les hautes herbes : plus de pensée « Je ne devrais pas aller là sans Pokémon. », on entre dans les herbes. Revenir au labo : seul le starter restant est sur la table.
  - `test_starter_placement.gd`, `test_cutscene_data.gd`, `test_dialogue_data.gd`, `test_pokemon_content.gd` : invariants du §4.4.
  - **Export** : `tools/build_android.sh`, puis `data/pokemon/*.json`, `data/cutscenes/starter.json` présents dans l'APK (`unzip -l`).
  - Capture Movie Maker (`tools/capture_play.gd`, scénario `starter_choice`, un par starter) : RENCONTRER, fiche, saut, Chen, rival face à la table, saut de son Pokémon, départ, « Attends. ». Lues avec Read : sprites nets, rien sous la boîte de dialogue, aucun contrôle pendant la scène.
  - **S24** : les trois choix (trois lancements).

#### T4 — qa-mobile : validation du 4A sur le S24
- Checklist `android-deploy` : tests, import, `tools/deploy_s24.sh`, logcat.
- **CA à vérifier et rapporter** : les répliques du §4.1 **identiques** au dossier 02 ; légende lisible puis effacée ; RENCONTRER seulement face à un starter ; fiche lisible, boutons confortables au pouce, RETOUR fiable ; pour les **trois** choix, le bon Pokémon du rival ; pendant toute la scène, joystick et boutons cachés, le joueur ne bouge pas seul ; sortie du labo avant le choix puis retour (légende, RENCONTRER) ; après le choix, hautes herbes franchissables, starter restant sur la table ; 60 fps pendant les sauts et la marche du rival ; aucune erreur `PokemonData`, `StarterOffer`, `CutsceneLibrary`, `NpcRoster` dans logcat.

### 4B — le premier combat

#### T5 — architecte-godot : fondations du 4B
- §2.2 : moteur de combat, IA, dresseurs, textes, placement, étape `battle` ; données `data/trainers/rival.json` et `data/battle/messages.json`.
- **CA** : tests du §2.2 verts ; combat complet simulé 1 000 fois (graines 0..999) pour chacun des 3 couples starter/rival : il se termine toujours (≤ 200 tours), sans erreur, et le taux de victoire du joueur est **rapporté** (information pour Kevin, pas un seuil) ; import sans erreur.

#### T6 — constructeur-monde : la vue de combat dans le labo (sans UI)
- `tools/gen_placeholder_battlers.gd` ; `BattleStage` ; `BattleLayout` appliqué ; transition d'entrée et de sortie ; caméra ; masquage des PNJ Pokémon ; animations provisoires (attaque physique, statut, coup, K.O.). Scénario de capture `battle_stage` qui joue un journal **écrit à la main** (sans moteur ni UI).
- **CA** :
  - `tests/integration/test_battle_stage.gd` : positions égales à `BattleLayout` à 1920 et 2340 de large ; sprites NEAREST, échelles ×4 / ×3 ; `play_move` / `play_hit` / `play_faint` se terminent (coroutines) avec `speed_scale = 0` ; `hide_all` remet tout à l'état initial ; zoom de caméra rendu à 1,0.
  - Capture Movie Maker à 2340 × 1080, pour les 3 couples : entrée, vue de combat, coup, K.O., sortie. Lues avec Read : labo reconnaissable derrière, Pokémon du joueur de dos en bas à gauche, adversaire de face au centre droit, ombres au sol, rien de coupé, pas d'écran noir.
  - **S24** : Kevin juge la composition (Q23, Q24) **avant** l'UI.

#### T7 — ui-mobile : l'interface de combat
- `BattleHud` et ses composants (§3.8), tokens, thème, icônes. Outil `tools/capture_battle_ui.gd` (HUD seule sur une capture du labo).
- **CA** :
  - `tests/integration/test_battle_hud.gd` : cartes (nom, ♂/♀, « Nv. 5 », PV chiffrés **seulement** côté joueur) ; 6 pastilles dont 1 pleine ; couleur de barre aux seuils 50 % et 20 % ; `animate_hp` atteint la valeur en `HP_TWEEN` (± 1 image) et plus vite si `big` ; grille d'actions : ATTAQUER mis en avant, les trois autres atténués et **sans** signal ; ATTAQUER → grille des capacités ; carte de capacité : nom, pastille, PP, « Puissance 40 » ou « Statut » ; carte sans PP ne déclenche rien ; **un** toucher → **un** `move_selected` ; pression de `LONG_PRESS` → fiche, **sans** `move_selected` ; « ‹ » → retour à la grille ; `show_message` se termine après `BATTLE_MESSAGE_HOLD` ou au toucher ; toutes les zones ≥ `TOUCH_MIN` et dans `SAFE_MARGIN` à 1920 et 2340 ; message et carte joueur ne se chevauchent pas.
  - Capture à 2340 × 1080 : grille d'actions, grille des capacités (une sélectionnée), fiche de pression longue, message, PV bas. Comparée à `combat-v1.webp` et `combat-capacites-v1.png.png`, lue avec Read.
  - Couleurs, tailles et durées uniquement via `UiTokens`.

#### T8 — constructeur-monde : le premier combat jouable
- `BattleDirector` (§3.7) ; étape `battle` dans le `CutsceneDirector` ; câblage de `Boot` ; suite de la scène (§4.2) ; PNJ `rival` conditionnel ; soin après le combat.
- **CA** :
  - `tests/integration/test_battle_director.gd` (mini-carte, vraie `BattleHud`, vrai `BattleStage`, `speed_scale = 0`, graine fixe) : `run` bloque le joueur **dans l'appel** (`&"battle"`) ; chaque événement du journal est joué une fois et dans l'ordre (`event_played`) ; les PV affichés égalent ceux du moteur à chaque fin d'événement ; une capacité choisie dans la HUD arrive au moteur ; victoire → `WIN`, défaite → `LOSS` ; `heal_after` → PV et PP pleins ; à la fin, PNJ Pokémon réaffichés, zoom rendu, HUD cachée, joueur libre si aucune autre raison ; `run` pendant un combat → faux.
  - `test_cutscene_director.gd` : l'étape `battle` attend la fin, lève `win` **ou** `lose` ; sans runner, `push_error` et étape sautée.
  - `tests/integration/test_rival_battle.gd` (vrai `Boot`, depuis le labo avec `{ oak_met, oak_lab_reunion, starter_offered }`, texte et animations instantanés, graines choisies pour gagner **et** pour perdre) : choix, scène, combat en choisissant toujours la 1re capacité, fin ; `rival_lab_won` (ou `_lost`), `rival_left_lab` ; le rival n'est plus au labo, le starter est rentré ; joueur libre, contrôles visibles ; revenir au labo : rival absent.
  - Tous les tests des jalons 1 à 4A restent verts.
  - **Export** : `data/trainers/`, `data/battle/` dans l'APK.
  - Capture Movie Maker (scénario `rival_battle`) : une image par étape du combat. Lues avec Read.
  - **S24** : le combat complet, trois fois (un par starter).

#### T9 — qa-mobile : validation du 4B sur le S24
- **CA à vérifier et rapporter** : la transition du labo au combat **sans écran noir** en ~1 s ; composition conforme aux références (et aux réponses de Kevin) ; ATTAQUER mis en avant ; capacités lisibles, pression longue fiable, sans lancer l'attaque ; PV fluides, couleurs aux seuils, vibration sur un coup, plus forte sur un critique ; messages lisibles, rythme (durée d'un combat chronométrée pour les 3 couples) ; victoire et défaite (forcer une défaite) : pas de retour au Centre, la scène continue ; après : rival sorti, contrôle rendu ; **60 fps** pendant les attaques et les barres de PV ; aucune erreur `Battle*`, `TrainerLibrary` dans logcat.

---

## 6. Critères d'acceptation par sous-jalon (récapitulatif)

| | 4A | 4B |
|---|---|---|
| Tests | §2.1 + T1–T3, **tous verts** ; nombre de tests rapporté (513 au départ) | §2.2 + T6–T8 ; 4A toujours vert |
| Import | `godot --headless --path . --import` sans `ERROR` ni `SCRIPT ERROR` | idem |
| Textes | 5 dialogues, légende, 3 fiches **identiques** au dossier 02 (test + QA) | messages de combat conformes à `messages.json` validé par Kevin |
| Déterminisme | graine fixe → même starter, mêmes IV | graine fixe → même journal de combat |
| Captures | T2, T3 (3 choix) lues avec Read | T6, T7, T8 lues avec Read |
| S24 | 3 choix jouées, 60 fps, 0 erreur logcat | 3 combats joués, victoire et défaite, 60 fps, 0 erreur logcat |
| Export | `data/pokemon`, `data/cutscenes` dans l'APK | `data/trainers`, `data/battle` dans l'APK |

**Tests GUT prévus** : unitaires `test_game_rng`, `test_type_chart`, `test_pokemon_data`, `test_stat_calc`, `test_species_data`, `test_pokemon`, `test_pokemon_factory`, `test_party`, `test_starter_offer`, `test_battler`, `test_damage_calc`, `test_battle`, `test_battle_ai`, `test_trainer_library`, `test_battle_text`, `test_battle_layout` (nouveaux) ; `test_game_state`, `test_interaction`, `test_cutscene_library` (étendus). Intégration `test_starter_sheet`, `test_starter_choice`, `test_starter_event`, `test_starter_placement`, `test_pokemon_content`, `test_battle_stage`, `test_battle_hud`, `test_battle_director`, `test_rival_battle` (nouveaux) ; `test_npc`, `test_interaction_controller`, `test_exploration_hud`, `test_cutscene_director`, `test_cutscene_data`, `test_dialogue_data`, `test_route1_event`, `test_boot` (étendus).

---

## 7. Validation S24 (résumé)

| Après | Ce que Kevin essaie sur le S24 |
|---|---|
| T1 | La fin du 3B, puis le discours de Chen. |
| T2 | (captures) RENCONTRER, la légende, les trois fiches. |
| T3 | Le choix complet, trois fois, jusqu'à « Attends. ». |
| T4 | Rapport de QA du 4A. **Validation du 4A.** |
| T6 | La vue de combat dans le labo (sans interface). |
| T7 | (captures) L'interface de combat. |
| T8 | Le premier combat, trois fois. |
| T9 | Rapport de QA du 4B. **Validation du jalon 4.** |

---

## 8. Hypothèses et questions pour Kevin

> **Décisions de Kevin (2026-09-26)** — elles **priment** sur les propositions par défaut ci-dessous et sur le reste du plan. Découpage 4A / 4B **validé**. Les répliques ci-dessous sont **définitives** ; à l'implémentation, les reporter aussi dans `docs/design/dossier-02-prologue.md` (le test `test_dialogue_data.gd` y vérifie chaque texte).
>
> 1. **Q1 — le starter descend de la table** et vient vers le joueur (pas de Poké Ball) : premier contact direct. Animation propre à chacun : **Bulbizarre** descend calmement puis s'approche ; **Salamèche** descend avec plus d'enthousiasme ; **Carapuce** descend rapidement, attitude vive et joueuse. Il s'arrête devant le joueur et le regarde. **Prof. Chen** — « On dirait que le choix est réciproque. » C'est **ensuite** que le Pokémon rejoint officiellement l'équipe.
> 2. **Q3 — sortir est empêché** une fois la séquence de choix commencée. Sur le tapis de sortie avant d'avoir choisi : **Prof. Chen** — « Pas si vite. Tu n'as pas encore choisi ton partenaire. » (réaction du monde, pas de mur silencieux).
> 3. **Q8 — capacités réelles du début de progression au niveau 5**, sans ajout artificiel de Fouet Lianes, Flammèche ou Pistolet à O. **Tables d'apprentissage : celles de Rouge/Bleu** (confirmé par Kevin le 2026-09-26), soit au niveau 5 Bulbizarre Charge + Rugissement, Salamèche Griffe + Rugissement, Carapuce Charge + Mimi-Queue ; elles restent des données, remplaçables plus tard. Le premier combat peut être simple : il apprend ATTAQUER, choisir une capacité, les PV, l'alternance des tours, attaquer et être attaqué, gagner ou perdre. **Règle générale** : 4 capacités connues au maximum ; apprentissage progressif par niveau ; si les 4 emplacements sont pris, le joueur choisit laquelle oublier ; CT et autres méthodes plus tard.
> 4. **Évolutions à prévoir dans le modèle de données dès maintenant** (sans implémentation visuelle au jalon 4) : évolutions de Kanto par niveau, pierre et autres méthodes pertinentes (ex. Bulbizarre → Herbizarre → Florizarre, Salamèche → Reptincel → Dracaufeu, Carapuce → Carabaffe → Tortank). Évolutions par échange : adaptation solo décidée plus tard. **Architecture cible, à ne pas avoir à casser** : XP → niveaux → apprentissage progressif des capacités → 4 capacités max → évolution → nouvelles formes, statistiques et capacités.
> 5. **Q13 — nommage en combat : le nom seul** (« Carapuce — Nv. 5 »), ni « ennemi » ni « du Rival ». Introduction : « Le Rival envoie Carapuce ! ». Messages : « C'est super efficace ! », « Ce n'est pas très efficace... », « Coup critique ! ». Formulations françaises naturelles plutôt que la reproduction mot pour mot des jeux historiques (les autres messages restent `draft` jusqu'à relecture).
> 6. **Q19 — après le combat, dialogues selon l'issue** ; aucune sanction (ni argent, ni Centre, ni Game Over) ; **Prof. Chen soigne les deux Pokémon** quelle que soit l'issue ; **ni XP ni argent** pour ce combat narratif (Q20 confirmée).
>    - **Victoire** : le rival rappelle son Pokémon ; petit silence ; **Rival** — « ...Pas mal. » ; il regarde son Pokémon / sa Poké Ball ; « On a encore du travail. » ; il regarde le joueur ; « La prochaine fois, ce sera différent. » ; il commence à partir, puis « Essaie de ne pas trop prendre de retard. » ; il sort. (Compétitif, un peu arrogant, mais il ne reproche pas la défaite à son Pokémon.)
>    - **Défaite** : le rival rappelle son Pokémon ; **Rival** — « Pas mal pour un premier combat. » ; petit sourire ; « Mais je t'avais prévenu : j'étais prêt. » ; puis « Rattrape-moi quand tu le seras aussi. » ; il sort.
> 7. **Chen après le départ du rival** : **Prof. Chen** — « Pour un premier combat, vous vous êtes bien débrouillés. » / « Mais gagner n'est qu'une partie de ce qu'un Dresseur doit apprendre. » / « Apprends à connaître ton Pokémon. Il fera de même avec toi. » (cette dernière phrase pose la philosophie du jeu : le Pokémon est un partenaire).
> 8. **Q22 — répliques d'attente après le jalon 4** (remplacent celles du 3B) : **Prof. Chen** — « Le monde qui vous attend est bien plus vaste que Bourg Palette. » / « Prends le temps de l'observer. Les Pokémon ont beaucoup à nous apprendre. » ; **Maya** — « Alors, c'est lui que tu as choisi ? » (elle regarde le starter) / « Vous avez l'air de déjà bien vous entendre. »
> 9. **Q14 — aucune indication de Chen pendant le combat** : il observe. Apprendre en jouant ; une aide contextuelle légère viendra seulement si les tests montrent qu'un débutant ne comprend pas.
> 10. **Q23 — le combat se joue dans le vrai labo** : il peut être assombri, recadré, zoomé, **recomposé** pour une vue plus cinématique, avec des sprites de Pokémon plus grands ; jamais d'écran noir suivi d'un décor générique. Pas forcément un simple zoom brut de la vue d'exploration si le résultat est mauvais : la composition de combat peut être spécifique tout en représentant réellement le labo.
> 11. **Le rival choisit le starter avantagé** (règle conservée) : **Rival** — « Alors ce sera toi. » ; son Pokémon vient vers lui / rejoint son équipe ; quand il s'apprête à partir : « Attends. » ; il regarde son Pokémon, puis celui du joueur ; « On ne va quand même pas partir sans savoir ce qu'ils savent faire. » ; le combat commence.
> 12. **Premier combat volontairement simple** : pas de vitrine de tout le système. Les couches suivantes arrivent progressivement dans l'aventure (capacités élémentaires, types, statuts, changements, objets, capture, nouvelles capacités, niveaux, évolution, stratégies).
> 13. **Fin du jalon 4** : le joueur possède son premier Pokémon, a vécu son premier combat, comprend le tour par tour, a établi la rivalité, a compris que son Pokémon est un partenaire, et **peut enfin quitter Bourg Palette par les hautes herbes** (le blocage du 3B se lève avec `starter_chosen`).
> 15. **Réponses aux questions des fondations (2026-09-26)** : type électrique nommé **« Électrik »** (nom officiel ; remplace « Électrique » partout dans les données et l'UI) ; messages de combat **accordés au féminin** pour une Pokémon femelle ; **pas de message générique de fin** pour le premier combat contre le rival (ses répliques de victoire / défaite en tiennent lieu ; les messages « Tu as battu… » restent pour les autres dresseurs) ; descriptions des 24 capacités : restent `draft`, relecture plus tard ; **rendement d'XP moderne** des formes finales (Florizarre, Dracaufeu, Tortank : 263 à 267) ; Pokémon K.O. : le suivant est envoyé automatiquement jusqu'à l'écran ÉQUIPE.
> 16. **Réponses aux questions du 4A (Q-A à Q-I, 2026-09-26)** — à implémenter avant la validation du 4A :
>     - **Première rencontre (Q-B)** : jamais « sur la tête » du joueur. Le starter descend de la table et atterrit sur une **case libre à côté ou légèrement devant le joueur**, choisie **d'après l'espace disponible sur la grille** (pas un décalage visuel qui provoquerait des superpositions). Enchaînement : le starter descend → s'approche → s'arrête → **le joueur se tourne vers lui** → petit temps d'observation mutuelle → **Prof. Chen** « On dirait que le choix est réciproque. ».
>     - **Q-A — on garde** : après « Alors ce sera toi. » et l'arrivée de son Pokémon, le rival regarde ton Pokémon, puis toi (petit sourire = temps mort) : **Rival** « Ça devrait être intéressant. ». Plus tard seulement : « Attends. » puis « On ne va quand même pas partir sans savoir ce qu'ils savent faire. ».
>     - **Pendant la phase de choix (Q-G)**, dès que Chen a présenté les starters : **Prof. Chen** « Prends ton temps. » / « Choisis celui avec qui tu as envie de partir. » ; **Rival** « Tu comptes les regarder encore longtemps ? » / « Dépêche-toi de choisir. » (remplacent les répliques d'attente du 3B).
>     - **Répliques de la décision n° 8 réservées à l'APRÈS-COMBAT (Q-E)** : ni Chen (« Le monde qui vous attend… ») ni Maya (« Alors, c'est lui/elle que tu as choisi ? ») ne les disent avant le combat du 4B. Avant le combat, Maya garde une réplique adaptée à l'état courant (celle du 3B, « Ah, le professeur est revenu. »…). **Accord « lui / elle »** selon le sexe du starter (information déjà dans le modèle).
>     - **Pas de compagnon temporaire (Q-D)** : pendant la séquence du labo, le starter reste physiquement près du joueur, mais il **ne le suit pas** dans Bourg Palette ; à la fin de la séquence, au moment approprié, il rejoint sa Poké Ball. Le vrai système de compagnon (suivi, distances, animations, réactions, obstacles, intérieurs/extérieurs, comportements par espèce, rappel automatique) aura son jalon dédié.
>     - Q-C, Q-F, Q-H, Q-I : valeurs par défaut.
>     - **Principe** : les secondes qui suivent le choix doivent dire « Celui-là, c'est ton Pokémon » : choix → mouvement du Pokémon → proximité avec le joueur → regard mutuel → réaction de Chen → réaction du rival.
> 14. Toutes les autres questions (Q2, Q4–Q7, Q9–Q12, Q15–Q18, Q21, Q24–Q27) : **propositions par défaut**, à ajuster après l'essai sur S24.

Hypothèses techniques (pas de décision de design) :
- Données Pokémon, dresseurs et messages en **JSON** validé strictement, comme les dialogues et les scènes.
- Tout l'aléatoire passe par une `GameRng` à graine, injectée ; la graine de la partie est dans `GameState`.
- Le moteur de combat produit un **journal d'événements** ; la présentation le joue. Aucune règle dans les nœuds.
- Le combat se joue **par-dessus la carte**, sans changer de scène ni de carte.
- La mise en scène du choix est une **scène de données** (celles du 3B), avec des alias ; le choix lui-même est un contrôleur de code.
- Pas de sauvegarde.

Questions (**proposition par défaut** entre parenthèses ; c'est ce que le plan applique si tu ne dis rien) :

**Choix du starter (dossier 02 §7–§9)**
1. **Pokémon sur la table ou dans la Poké Ball ?** Le §3 dit que les starters sont **visibles** (c'est le cas depuis 3A, et sur `labo-chen-v1.png` ils sont posés sur la table avec une Ball devant chacun), mais le §8 dit « **La Poké Ball s'ouvre**, le Pokémon apparaît ». (*Le Pokémon **saute de la table** et atterrit devant le joueur ; pas d'animation de Ball.* Autre choix : il disparaît de la table dans un éclair et sort d'une Ball aux pieds du joueur.)
2. **« CHOISIS TON PREMIER PARTENAIRE »** : texte posé sur le monde, en haut au centre, sans rectangle (bible §5), environ 3 s puis il s'efface ; il revient si l'on ressort puis rentre au labo sans avoir choisi. (*Oui.* Autre choix : il reste affiché jusqu'au choix, mais la bible §11 interdit l'objectif permanent.)
3. **Sortir du labo avant d'avoir choisi** : Rouge/Bleu l'empêche (Chen rappelle le joueur). Le dossier ne donne pas de texte. (*On peut sortir ; Chen et le rival attendent ; en revenant, le choix est toujours ouvert.* Si tu veux l'empêcher, donne la réplique et qui la dit.)
4. **Rencontrer** : icône du bouton (*une Poké Ball au trait*) ; « le Pokémon s'approche » = il **glisse de ~20 px** vers le joueur au bord de la table, puis la fiche s'ouvre ; la fiche est **à gauche** de l'écran pour laisser voir la table ; **pas de seconde confirmation** après CHOISIR (le dossier n'en prévoit pas). (*Oui aux quatre.*)
5. **Didascalies** : Chen regarde la table à « Eux aussi ont encore beaucoup à découvrir. » puis **revient vers les deux** à « Alors... pourquoi ne pas commencer ensemble ? » ; « petit sourire » du rival : pas d'expression sur le sprite provisoire, remplacé par un silence de 0,6 s avant « On ne va quand même pas… » ; « il observe le choix, regarde les deux restants » : il se tourne vers ton Pokémon, puis vers la table. (*Oui.*)
6. **Déplacements du rival** : il va se placer sous son Pokémon, qui saute près de lui ; il « commence à partir » = 2 à 3 cases vers la sortie avec son Pokémon derrière lui, puis s'arrête et se retourne. (*Oui ; cases réglables dans `data/cutscenes/starter.json`.*)
7. **Surnom** du starter : non prévu par les dossiers. (*Pas de surnom au jalon 4 ; à décider avec le menu Équipe.*)

**Règles Pokémon (dossiers 04 et 05)**
8. **Niveau et capacités de départ** : niveau **5** pour les deux starters (Rouge/Bleu). Capacités de Rouge/Bleu : Bulbizarre **Charge + Rugissement**, Salamèche **Griffe + Rugissement**, Carapuce **Charge + Mimi-Queue** (dossier 05 §18 : « ~2 capacités utiles »). Les jeux récents ajoutent Fouet Lianes, Flammèche ou Pistolet à O dès le niveau 3–4. (*Rouge/Bleu.*)
9. **Règles modernes** : dossier 04 « Types : système moderne » et six statistiques (§8). Proposé : table des **18 types** (avec Acier, Ténèbres, Fée) ; catégorie physique / spéciale **par capacité** ; formules de stats et de dégâts actuelles ; critique 1/24 ×1,5 ; aléatoire 85–100 % ; STAB ×1,5 ; niveaux de stats −6..+6 ; **IV tirés 0–31**, EV à 0, **natures neutres** au jalon 4 (« les mécaniques profondes peuvent exister en arrière-plan »). (*Oui.* Autre choix pour les IV : fixes, pour un premier combat parfaitement prévisible.)
10. **Couleurs de types** : la skill UI liste 15 couleurs (sans Acier, Ténèbres, Fée). (*Ajouter les couleurs usuelles de ces trois types.*) **Nom français du type électrique** : le dossier 05 et `combat-capacites` écrivent « ÉLECTRIQUE », le nom officiel est « Électrik » (et la skill l'écrit ainsi). (*« Électrique », comme tes dossiers ; sans effet au jalon 4.*)
11. **Sexe** : tiré selon l'espèce (7 mâles pour 1 femelle chez les starters) et affiché ♂/♀ sur les cartes, comme les références. (*Oui.*)

**Interface de combat (dossier 05, références)**
12. **Où s'affichent les messages de combat ?** Aucune référence n'en montre. (*Dans un bandeau sombre translucide **à la place de la grille d'actions**, en bas à droite, qui avance seul après ~0,9 s ou au toucher ; la boîte de dialogue reste pour les personnages.*)
13. **Formulation des messages** (`data/battle/messages.json`, **à relire**) : envoi (« Rival envoie Carapuce ! », « En avant, Salamèche ! »), capacité utilisée, attaque ratée, coup critique, efficacité (« C'est super efficace ! » / « Ce n'est pas très efficace… » — le dossier 05 §8 interdit les multiplicateurs, pas ces phrases), stat qui baisse ou ne peut plus baisser, K.O., issue. Comment nommer le Pokémon adverse : « Carapuce du Rival », « Carapuce ennemi » ou le nom seul ? (*Formulations des jeux français récents, marquées `draft` jusqu'à ta relecture ; « Carapuce du Rival ».*)
14. **Indication de Chen pendant le combat** (dossier 05 §18 : « éventuellement une seule, seulement si nécessaire ») : il faut une réplique et une condition (par exemple 10 s sans action). (*Aucune au jalon 4.* Si tu la veux : le texte et la condition.)
15. **Pression longue sur une capacité** : fiche « Puissance · Précision · catégorie · description ». Les descriptions (« Baisse l'Attaque de la cible »…) sont du texte. (*Fiche incluse ; descriptions proposées en `draft`, à relire.*)
16. **Le geste** : `vision.md` dit « on choisit l'attaque, **on touche l'adversaire** → impact » ; le dossier 05 §7 dit « **Tap = rapide** ». (*Dossier 05, plus récent : toucher la carte lance l'attaque, sans toucher l'adversaire.*)
17. **Cartes et boutons** (point à trancher du dossier 05) : « pas de gros rectangles opaques » contre des cartes sur fond sombre dans `combat-v1` ; et `combat-v1` a des **boutons colorés** (rouge, or, bleu, gris), alors que la case 1 de `combat-capture-v1` montre des **boutons sombres** avec la sélection en or ; la planche v1 affichait aussi les PV chiffrés de l'adversaire. (*Cartes translucides comme la boîte de dialogue ; boutons colorés de `combat-v1` ; PV chiffrés du joueur seulement, dossier 05 §5.*)
18. **SAC, ÉQUIPE, FUITE au premier combat** : pas d'objet, un seul Pokémon, fuite impossible contre un Dresseur. (*Visibles mais atténués et sans effet, ce qui « montre subtilement ATTAQUER ».* Autre choix : les cacher pour ce combat.)

**Issue et suite (dossier 02 §10 s'arrête au lancement du combat)**
19. **Après le combat** : le dossier ne dit rien. Proposé : **aucune conséquence** si tu perds (pas de retour au Centre, qui n'existe pas) ; les deux Pokémon **soignés** en silence à la fin ; **pas d'XP** ni d'argent au jalon 4 ; aucune réplique faute de texte, le rival rappelle son Pokémon et **sort du labo**, ton starter rentre dans sa Ball, tu reprends la main. (*Oui.* Il manque surtout les **répliques du rival après victoire et après défaite**, et éventuellement celles de Chen : veux-tu les écrire ?)
20. **XP de ce combat** : Rouge/Bleu en donne. (*Aucune au jalon 4 ; l'XP arrive avec les combats sauvages, jalon 5.*)
21. **Le starter hors combat** : le dossier 04 §4 veut un compagnon visible et contextuel. (*Pas au jalon 4 : ton starter rentre dans sa Ball à la fin de la scène ; le compagnon aura son jalon.*)
22. **Après le choix, au labo** : le starter restant reste sur la table, observable avec sa réplique de 3A ; Chen reste non interactif ; Maya garde sa variante du 3B (« Ah, le professeur est revenu. »). Le dossier dit que Maya « évoluera encore après le choix du starter ». (*Oui en attendant tes textes pour Maya et Chen.*)

**Combat dans le décor**
23. **Composition** : le monde est vu de dessus, alors que `combat-v1` montre une vue de face avec horizon. Proposé : le **labo réel reste le fond**, légèrement assombri, zoom de 6 %, et les deux Pokémon passent en sprites de combat (dos / face) placés comme sur la référence ; les dresseurs restent visibles à leur place. (*Oui.* Autre choix : des fonds peints par lieu, en perspective, fidèles à la référence mais coûteux en dessins ; ou des Pokémon agrandis à leur place dans le monde, sans vue de dos.)
24. **Taille des Pokémon en combat** : sprites de combat 64 × 64 natif, **×4 pour le tien (256 px) et ×3 pour l'adversaire (192 px)**, plus grands que dans le monde (64 px), comme les références. (*Oui.* Autre choix : une seule échelle ×3 pour les deux, plus homogène en pixels.)
25. **Durées** : transition ~1 s, message ~0,9 s, élan d'attaque ~0,5 s, descente des PV 0,4 s. (*Valeurs de départ, réglables après l'essai sur S24 ; combat du labo visé en moins d'une minute.*)

**Cohérence avec le 3B**
26. **Nom du drapeau du starter** : le plan 3B cite `has_starter` (décision 10) et `starter_chosen` (§2.10). (*`starter_chosen` partout ; le blocage des herbes du 3B lit ce nom, §9.*)
27. **IA du rival** : une capacité au hasard parmi celles qui ont des PP (« erreurs au début », dossier 05 §19). (*Oui.*)

---

## 9. Dépendances au 3B, et que faire s'il livre autrement

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : ce que le 3B a réellement livré : §13.1 et §13.11.

Le 4A s'appuie sur ce que le plan 3B **promet** (pas encore dans le dépôt au moment de ce plan). À vérifier **au début de T0**, dans le code fusionné du 3B :

| Dépendance | Promis par le 3B | Si le 3B livre autrement |
|---|---|---|
| Scène `oak_intercept` en **données**, dernière étape `set: [oak_lab_reunion]` | §3.4 | Scène en code : on ajoute le discours de Chen au même endroit, dans le même langage. Si la dernière étape a changé, on accroche après la réplique « Et pourtant, tu es toujours là. ». |
| `CutsceneDirector` : `play`, `is_running`, `cutscene_started/finished`, étapes `wait dialogue face set spawn move change_map`, `follower`, `near` | §2.3, §2.4 | Les ajouts du §3.6 (alias, `hop`, `lean`, `despawn`, `battle`) se font dans le directeur réel. S'il n'y a pas de `follower`, le rival part seul et son Pokémon le rejoint par `hop` après. |
| `Npc` avec `GridMover` (`step`, `enter_grid`, `leave_grid`) ; `GameMap.add_npc`, `remove_npc`, `refresh_npcs(flags)` | §2.5, §2.6 | `hop_to` et `despawn` en dépendent directement ; sans eux, T1 les ajoute (même conception que le 3B). |
| `NpcSpec` `if` / `unless` et `NpcRoster.parse_entry` | §1 | Sans présence conditionnelle, les `taken_*` du §4.3 ne marchent pas : T1 l'ajoute. |
| Clé de page `turn` | §2.7 | Sans `turn`, étapes `face` avant chaque dialogue. |
| `Player.script_step` ; `InteractionController.set_enabled` ; `Boot._refresh_controls` | §2.4, §2.5, §2.1 | Nécessaires au verrouillage pendant la scène ; à ajouter en T1 sinon. |
| PNJ `oak` (8, 4) et `rival` (9, 6) au labo avec `if: [oak_met]` ; `maya_working` interactive (décision 7) | §3.2 | Les invariants du §4.4 sont recalculés sur les positions réelles ; `starter.json` ajusté. |
| **Blocage des hautes herbes** avant le starter, avec la pensée « Je ne devrais pas aller là sans Pokémon. » (décision 10) | §7 | Le 4A lève `starter_chosen`. Si le 3B a nommé le drapeau autrement (`has_starter`), **on renomme d'un côté** (Q26) ; le test `test_starter_event` vérifie que la pensée ne se joue plus. |
| Étiquette « Prof. Chen » | décision 6 | Les nouveaux dialogues l'utilisent quoi qu'il arrive (décision de Kevin). |

Si le 3B est fusionné avec des noms différents, on **aligne ce plan avant T0** (comme le §8 du plan 3B l'a fait pour le 3A), et on note les écarts en fin de ce document.

---

## 10. Points d'accroche pour la suite

- **Rencontres sauvages (jalon 5)** : `BattleSide.trainer_name` vide = combat sauvage ; FUITE s'active (`BattleAction.Kind.RUN`) ; `BattleLayout` sert en extérieur ; la transition « herbe qui bouge → cri → caméra » (dossier 05 §3) remplace le dialogue d'avant-combat ; la tuile `tall_grass` du 3B est lue par `GridWorld` ; une table de rencontres dans `data/encounters/<carte>.json` ; `PokemonFactory` crée le sauvage.
- **XP, niveaux, apprentissage, évolution** : événements `EXP_GAINED`, `LEVEL_UP`, `MOVE_LEARNED` dans le journal ; courbes d'XP et learnsets complets dans les données d'espèces ; `Pokemon.recalc`.
- **Capture (phase 6)** : `BattleAction.Kind.ITEM`, événements de secousses (1… 2… 3… clic) joués par `BattleStage` avec vibration ×3 ; `Party.is_full()` décide entre « rejoint ton équipe » et « confié au système de recherche de Chen » (dossier 05 §17).
- **Équipe et changement** : `Party` est prête ; `BattleAction.Kind.SWITCH` et le panneau latéral ÉQUIPE (dossier 05 §14).
- **Sauvegarde** : `GameState.party.to_array()`, `starter_species`, `flags.to_array()`, graine de `GameRng` ; `Pokemon.to_dict` / `from_dict` déjà testés.
- **Combats suivants du rival** : `team_by_starter` dans `data/trainers/rival.json` ; une IA qui « te connaît » s'ajoute à côté de `random` (dossier 05 §19, dossier 06 §6).
- **Pokédex progressif** : les événements `SENT_OUT` et `FAINTED` suffisent à noter « observé » et « combattu » (dossier 04 §13).
- **Statuts** : `MoveEffect.Kind.STATUS` et leurs effets visuels (dossier 05 §13).

---

## 11. Écarts constatés (2026-09-26)

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : état à jour au §13.10.

Constat fait sur `main`, base de ce plan :
1. **Code** : 3A présent, **513 tests verts** (confirmé par `tools/test.sh`), import sans erreur. **3B absent** (plan seulement). Aucune donnée Pokémon, aucun code dans `game/battle/` ni `game/pokemon/` (dossiers vides avec `.gitkeep`).
2. **Format des PNJ** : le plan 3B écrit ses exemples de `data/npcs/*.json` sous forme de **liste** d'objets avec `id` ; le format réel de 3A est un **objet** « identifiant → PNJ ». Les exemples de ce plan suivent le format réel.
3. **Conversion des directions** : en 3A, elle est dans `NpcRoster._FACINGS` (privée) et `InteractionController.dominant_direction` (statique) ; le 3B prévoit de la déplacer dans `Grid`. Les ajouts du 4 utilisent celle que le 3B aura livrée.
4. **Référence de sélection des capacités** : le fichier est `docs/design/reference/combat-capacites-v1.png.png` (double extension), attendu `combat-capacites-v1.png` par `etat-projet.md` et `ui-reference.md`. À renommer lors du prochain commit de documentation (ce plan cite le nom réel).
5. **Labo réel** (`tools/build_interiors.gd`) : table des starters (10..12, 4..5), starters en (10..12, 5) avec `lift` 56, tabouret (12, 7), paillasse (11..13, 8) après la retouche de Kevin, plantes (6, 8) et (9, 9), entrée (7, 9) avec warp PUSH vers le bas. Les chemins du §4.2 en tiennent compte ; les invariants du §4.4 les vérifient.

---

## 12. Fondations posées (écarts avec le plan)

> **Obsolète pour le 4A là où le §13 diffère** (alignement sur le code réel, 2026-09-26) : n° 2 et n° 7 remplacés par la décision n° 15 (§13.8) ; « Reportés » à jour au §13.10.

Branche `jalon-04-fondations` (issue de `plan-jalon-04`), 2026-09-26 : §2.1 et §2.2, classes pures, données et tests. **670 tests verts** (513 au départ), import sans erreur, chaque script vérifié aussi avec `--check-only` et les avertissements GDScript traités en erreurs. Les décisions de Kevin du §8 (et ses précisions de la session) priment sur le §3.2 ; écarts :

**Données Pokémon**
1. **Learnsets complets de Rouge/Bleu** pour les **9 espèces** des trois lignées (le §3.2 limitait le learnset aux capacités de départ) ; au niveau 5 : Bulbizarre Charge + Rugissement, Salamèche Griffe + Rugissement, Carapuce Charge + Mimi-Queue (testé). Une capacité peut figurer plusieurs fois (niveau 1 puis 7 chez Herbizarre) ; `moves_at` la compte à son **dernier** niveau.
2. Clés d'espèce acceptées dès maintenant : `growth_rate` (`medium_slow` pour les 9), `base_exp` (valeurs des 5e à 7e générations : 64/142/236, 62/142/240, 63/142/239), `evolutions` (seule clé facultative). Numéros de Pokédex uniques, vérifiés.
3. **24 capacités** (toutes celles des learnsets + Lutte), valeurs modernes, catégorie par capacité, Morsure Ténèbres ; chaque `description` est `draft`.
4. `MoveEffect` : `kind` écrit dans les données (`stat_stage` | `recoil`), `chance` en % (Écume : 10), `target` `self` | `foe` ; `RECOIL` = fraction des **PV max** du lanceur (Lutte ¼).
5. `MoveData.crit_stage` (0 → 1/24, 1 → 1/8, 2 → 1/2, 3 → toujours) : Tranch'Herbe et Tranche à 1.
6. `MoveData.pending_effects` : liste de chaînes libres documentée en tête de `move_data.gd` (`burn_10`, `poison`, `sleep`, `leech_seed`, `trap`, `two_turn`, `charge_def_up`, `flinch_30`, `rage`), **ignorée par le moteur**. Un test vérifie que les capacités connues au niveau 5 par les trois starters n'en ont aucune.
7. Types : « **Électrique** » (proposition Q10, en attente de Kevin).

**Progression (décisions de Kevin, §8 points 3 et 4)**
8. `EvolutionRule` et `Evolution` (`game/pokemon/evolution/`, qui ne reste donc pas vide) : méthodes `level`, `item`, `trade`, champs requis selon la méthode, cible vérifiée. `Evolution.level_up_target` / `item_target` ; l'échange n'est jamais déclenché. `Pokemon.evolve_into` garde capacités, IV, EV, XP, niveau, PV perdus. Les identifiants d'objets ne sont pas vérifiés (aucun objet n'existe encore).
9. `ExpCurve` : les **6 courbes** modernes. `Pokemon.experience` (et non `exp`, qui masque la fonction globale `exp()` ; la clé de sauvegarde reste `"exp"`). `Pokemon.gain_exp(amount, data) -> Array[LevelUp]` (niveau, capacités à proposer, gains de stats), plafond au niveau 100, **rien n'est appris d'office**. La formule d'XP gagnée en combat n'est **pas** faite (jalon 5).
10. Apprentissage : `learn_move` → `LearnResult { LEARNED, ALREADY_KNOWN, NEEDS_FORGET, INVALID }` (rien ne change hors `LEARNED`), `replace_move(slot, move, data)`, `SpeciesData.moves_learned_at(level)`.

**Noms et signatures**
11. `GameRng.range_int(a, b)` au lieu de `range` (fonction globale de GDScript). Toutes les méthodes passent par `roll(n)`, seule méthode remplacée par `ScriptedRng` (`tests/helpers/scripted_rng.gd`, chargé par `preload`, sans `class_name` : `tests/` n'est pas exporté).
12. `BattleEvent.SideId` au lieu de `Side` : `Side` est un enum global de Godot (l'import ne le signale pas, `--check-only` si). Champs ajoutés pour que la présentation n'interroge jamais le moteur : `pokemon_name`, `species_id`, `level`, `gender`, `trainer_name`, `turn`, `pp` (restants, −1 pour Lutte), `stage` (niveau d'après) ; `to_dict()`.
13. `BattleText.lines(event, data) -> PackedStringArray` (0, 1 ou 2 phrases : « Coup critique ! » puis « C'est super efficace ! ») au lieu d'une chaîne ; marque `{de_pokemon}` (« de Salamèche », « d'Évoli »). Un Pokémon sauvage (dresseur vide) n'a pas encore de phrase (jalon 5).
14. `TrainerLibrary.new(pokemon_data)` puis `build_team(trainer_id, starter, rng)`. Clés obligatoires `gives_exp` et `prize_money` (`rival_lab` : `false`, `0`), `name` « **Le Rival** » (message « Le Rival envoie Carapuce ! ») ; `team` (équipe fixe) **ou** `team_by_starter`.
15. Classes de données ajoutées : `StarterOption`, `TrainerSlot`, `DamageResult`, `LevelUp` ; `StarterOffer.check_species(data)` ; `SpeciesData.STATS` (ordre canonique des stats).

**Règles du moteur précisées**
16. Immunité de type vérifiée **avant** la précision (aucun tirage). La précision tient compte des niveaux `acc` / `eva` (multiplicateur moderne en 3), tous à 0 au jalon 4.
17. Un camp qui a encore un Pokémon valide l'envoie **automatiquement en fin de tour** (premier valide) ; le choix du joueur viendra avec `SWITCH`. Si les deux derniers Pokémon tombent pendant la même action (recul de Lutte), le camp du lanceur gagne.
18. Ordre des tirages documenté en tête de `battle.gd` et `damage_calc.gd` (tests écrits avec `ScriptedRng`).

**Simulation** (`tests/unit/test_battle_simulation.gd` et `tools/simulate_first_battle.gd`, graines 0..999, niveau 5, IV tirés) : tous les combats se terminent, 42 tours au plus. Victoires du joueur qui choisit **au hasard** : Bulbizarre contre Salamèche 45,6 %, Salamèche contre Carapuce 33,4 %, Carapuce contre Bulbizarre 71,4 %. En attaquant toujours : 61,2 %, 60,9 %, 84,8 %.

**Reportés** (hors de ce périmètre ou dépendants d'un autre travail)
- `BattleLayout` : composition du combat à trancher par Kevin (Q23, « recomposé »).
- `Interaction.Kind.MEET` : T1.
- `CutsceneStep` / `CutsceneLibrary` (alias, `hop`, `lean`, `despawn`, `battle`) : le 3B n'existe pas sur cette branche.
- `GameState` (équipe, starter, `rng`) : T1. `test_interaction.gd` et `test_cutscene_library.gd` ne sont donc pas étendus.

---

## 13. Alignement du 4A sur le code réel du 3B et des fondations (2026-09-26)

Fait sur la branche `jalon-04a` (`main` avec le 3B validé + `plan-jalon-04` + `jalon-04-fondations`), **avant T1**. Cette section **remplace, pour le 4A**, ce qui est obsolète dans §3.5, §3.6, §3.9, §4.1 à §4.4, §5 (T0 à T3), §9, §11 et §12. Les **décisions de Kevin du §8** priment toujours ; ce qui suit les applique. Le 4B (§2.2, §3.7, T5 à T9) n'est pas réaligné ici, sauf les points de la décision n° 15.

### 13.1 Noms réels (plan → code)

| Dans le plan | Dans le code |
|---|---|
| scène `oak_intercept` | **1re variante** (`unless: [oak_met]`) de la scène **`route1_grass`** (`data/cutscenes/prologue.json`), qui se termine par `{ "set": ["oak_lab_reunion"] }`. La 2e variante (pensée des herbes) lit **`unless: ["starter_chosen"]`**. |
| `has_starter` | **`starter_chosen`** partout (données, fixtures, tests, commentaires ; fait en T0). `jalon-03b.md` garde l'ancien nom (historique). |
| `GameRng.range(a, b)` | `GameRng.range_int(a, b)` (§12 n° 11) |
| `TrainerLibrary.load_dir()` puis `build_team(id, starter, data, rng)` | `TrainerLibrary.new(pokemon_data)`, `load_dir()`, `build_team(trainer_id, player_starter, rng)` (§12 n° 14) |
| `BattleText` : une chaîne par événement | `BattleText.lines(event, data, trainer: TrainerData = null) -> PackedStringArray` (§12 n° 13 ; `trainer` : §13.8) |
| `BattleEvent.Side` | `BattleEvent.SideId` (§12 n° 12) |
| `CutsceneDirector.play(id, aliases)` | `play(cutscene_id)` **sans alias** aujourd'hui : T1 ajoute `aliases: Dictionary[StringName, StringName] = {}` (clé = nom sans « $ », valeur = identifiant du PNJ). |
| conversion des directions (§11 n° 3) | `Grid.direction_from_name`, `Grid.direction_name`, `Grid.dominant_direction` (livrées par le 3B) |
| `InteractionController.set_enabled` (3B §2.4) | **n'existe pas** : le contrôleur ne vise rien quand le joueur est bloqué (`_can_target()`), ce qui suffit. MEET passe par `_interact(target)` (T1). |
| `Npc` : `hop_to`, `lean_toward`, `settle`, surcharge d'interaction | à faire en T1. **Attention** : `Npc.HOP_HEIGHT` / `HOP_DURATION` existent déjà et servent au petit bond de `react()` ; les constantes du saut depuis la table prennent un autre nom (`JUMP_…` ou `HOP_STYLE_PARAMS`, §13.4), ou celles de `react` sont renommées `REACT_HOP_…`. |
| Chen et le rival « non interactifs » au labo | ils parlent : `oak_lab_waiting` et `rival_lab_waiting` (décision de Kevin au 3B). |
| `StarterChoice` ajoute le starter à l'équipe **à CHOISIR** (§3.5 point 5) | **après** « On dirait que le choix est réciproque. » (décision n° 1, §13.3). |
| `starter_chosen` : `if: [starter_chosen]` sur la scène du même nom | la scène lève elle-même `starter_chosen` ; sa condition est **`unless: [rival_challenged]`** seulement. |
| `rival_starter_smile` (« Ça devrait être intéressant. ») | **supprimé** (décision n° 11, §13.5 ; question Q-A du §13.10). |

### 13.2 Le labo réel (grille vérifiée)

Grille de `oak_lab` (16 × 11) chargée par `GameMap`, PNJ de la nouvelle partie (`#` solide, `N` occupé, `.` praticable) :
```
    0 1 2 3 4 5 6 7 8 9101112131415
 2  # # # # # # . # # # # # # # # #
 3  # . # # . N . . # . . # # . # #      N (5, 3) Maya
 4  # . . . . . . . . . # # # . # #      table (10..12, 4..5) ; Chen en (8, 4) si oak_met
 5  # # # # # # . . . . N N N . . #      starters (10..12, 5), lift 56
 6  # # . . . . . . . . . . . . # #      rival en (9, 6) si oak_met ; cases de rencontre (10..12, 6)
 7  # # . # # . . . . . . . # . # #      tabouret (12, 7)
 8  # # # # . . # . . . . # # # # #      paillasse (11..13, 8) ; plante (6, 8)
 9  # # # # # . . . . # . . . . . #      tapis de sortie (7, 9) : warp PUSH vers le bas ; plante (9, 9)
```
Conséquence décisive : les cases à l'est de la colonne 10 (`(11..13, 6)`, `(11, 7)`, `(13, 3..7)`, `(14, 5)`) ne communiquent avec le reste de la pièce **que par (10, 6) et (10, 7)**, et `(12, 6)` ne communique avec `(13, *)` que par elle-même. Deux PNJ mal placés ferment une poche : les placements du §4.2 (starter « sous le joueur », rival « sous son Pokémon ») sont **impossibles** pour deux des trois choix. §13.4 les remplace.

### 13.3 Déroulé du 4A (remplace §3.5 et le flux 4A du §3.10)

1. **Discours de Chen** : la 1re variante de `route1_grass` reçoit à la fin (après `set: [oak_lab_reunion]`) : `{ "wait": 0.5 }`, `{ "dialogue": "oak_starter_offer" }`, `{ "set": ["starter_offered"] }`. Fin de la scène, le joueur reprend la main.
2. **Ouverture** (inchangé, §3.5 point 2) : `StarterChoice` écoute `flags.flag_changed(open_flag)`, attend `cutscene_finished`, affiche la légende, pose les surcharges MEET (`Interaction.new(Kind.MEET, cell, &"", Vector2i.ZERO, npc)`, valide seulement avec une source et sans dialogue).
3. **Rencontrer / RETOUR** : inchangés (§3.5 points 3 et 4).
4. **CHOISIR** — `StarterChoice`, de façon synchrone :
   - fiche fermée, `npc.settle()` ;
   - `rival = offer.rival_pick(player, data)` ;
   - drapeaux `taken_<joueur>` et `taken_<rival>` (ils ne jouent qu'au prochain chargement du labo) ;
   - surcharges MEET retirées ;
   - **espèce en attente** `_pending = player` et écoute de `flags.flag_changed(offer.done_flag)` ;
   - `cutscenes.play(offer.chosen_scene, { &"player_starter": <npc joueur>, &"rival_starter": <npc rival> })` ;
   - puis seulement, blocage `&"starter_choice"` rendu (la scène tient déjà `&"cutscene"`).
   - Si `play` renvoie faux (scène absente ou invalide) : `push_error`, et `StarterChoice` lève lui-même `done_flag` (le Pokémon n'est jamais perdu).
5. **Scène `starter_chosen`** (§13.5) : le Pokémon descend, vient devant le joueur, le regarde, s'approche ; « On dirait que le choix est réciproque. » ; **étape `set: [starter_chosen]` juste après ce dialogue**.
6. **Entrée dans l'équipe** : sur `flag_changed(done_flag, true)` avec une espèce en attente, `StarterChoice` fait `state.party.add(PokemonFactory.create(data, _pending, offer.level, state.rng))`, `state.starter_species = _pending`, émet `starter_chosen(player, rival)`, oublie `_pending`. C'est la **décision n° 1** : le Pokémon rejoint officiellement l'équipe **après** la réplique de Chen, pas au toucher de CHOISIR.
7. Suite de la scène : le choix du rival, « Attends. », les regards, « On ne va quand même pas partir… », `set: [rival_challenged]`. **Fin provisoire du 4A** : joueur libre ; les herbes sont ouvertes (`starter_chosen`) ; la sortie aussi (§13.6).

Drapeaux (remplace le tableau du §3.9 pour le 4A) :

| Drapeau | Levé par | Lu par |
|---|---|---|
| `starter_offered` | `route1_grass` variante 1, dernière étape | `StarterChoice` (`open_flag`) ; scène `oak_lab_exit` (`if`) |
| `starter_chosen` | scène `starter_chosen`, étape `set` juste après `oak_starter_reciprocal` | `StarterChoice` (`done_flag` : ajout à l'équipe) ; `route1_grass` variante 2 (`unless`) ; `oak_lab_exit` (`unless`) ; variantes des répliques d'attente (§13.7) |
| `taken_bulbasaur` / `taken_charmander` / `taken_squirtle` | `StarterChoice`, à CHOISIR (`get_set_flags(offer)` les énumère) | présence des starters (`unless`) |
| `rival_challenged` | scène `starter_chosen`, dernière étape (4A) | la scène elle-même (`unless`) |

Tests de données (T3) : `FUTURE_FLAGS` de `test_dialogue_data.gd` vaut aujourd'hui `[starter_chosen]` (lu par la pensée des herbes, levé par personne tant que `starter.json` n'existe pas) ; il redevient **vide** en T3, et les drapeaux levés par code s'ajoutent par `StarterChoice.get_set_flags(offer)` (seulement les `taken_*`). Un test vérifie que la scène `starter_chosen` lève `done_flag` **une seule fois**, à l'étape qui suit le dialogue `oak_starter_reciprocal`, et que l'équipe est **vide** jusqu'à cette étape, puis compte 1 Pokémon (`test_starter_choice.gd`).

### 13.4 « Devant le joueur » : la mise en scène (décision n° 1)

Le joueur est en `(x, 6)`, tourné vers le haut ; la case devant lui est celle du starter, sur la table (solide). Pour que le Pokémon soit **réellement devant** lui :
1. **Le joueur fait un pas pour lui laisser la place** : `{ "move": "player", "to": { "near": "player", "offsets": [[0, 1], [-1, 0], [1, 0]] } }` → Bulbizarre : `(10, 7)` ; Salamèche : `(11, 7)` ; Carapuce : `(12, 7)` est le tabouret, donc `(11, 6)`. (Ordre choisi pour ne jamais s'enfermer : vers `(13, 6)`, le joueur serait pris dans la poche est dès que Carapuce se pose en `(12, 6)`.)
2. **Le Pokémon descend sur la case libérée**, entre le joueur et la table : `{ "hop": "$player_starter", "to": { "near": "$player_starter", "offsets": [[0, 1]] } }` → toujours `(x, 6)`, saut de 1 case vers le bas.
3. **Ils se regardent** : `face player → $player_starter`, `face $player_starter → player` ; le Pokémon est sur la case que le joueur regarde (Bulbizarre et Salamèche : le joueur regarde en haut ; Carapuce : à droite).
4. `wait 0.4`, puis `lean $player_starter → player` (« il s'approche légèrement »).

Le pas du joueur se fait **en se retournant** (mécanique existante : `script_step` oriente le joueur) ; un vrai pas en arrière, sans se retourner, serait un ajout à `Player`/`GridMover` : question Q-B.

**Styles de saut** (décision n° 1) : clé facultative de PNJ **`"hop_style": "calm" | "eager" | "playful"`** (`NpcSpec.hop_style`, `NpcSpec.HOP_STYLES`, validée par `NpcRoster` ; posée en T0 dans `data/npcs/oak_lab.json` : Bulbizarre `calm`, Salamèche `eager`, Carapuce `playful`). L'étape `hop` reste **générique** : le style vient du PNJ, le même pour le Pokémon du rival. Les paramètres sont des **constantes documentées de `Npc`** (présentation, T1), une entrée par valeur de `NpcSpec.HOP_STYLES` plus le défaut `&""` (un test vérifie qu'aucun style ne manque). Valeurs de départ, à régler sur le S24 :

| Style | Hésitation avant | Durée du saut | Hauteur d'arc | Après l'atterrissage |
|---|---|---|---|---|
| défaut `""` | 0 | 0,35 s | 32 px | — |
| `calm` (Bulbizarre, « calmement ») | 0,35 s (il regarde, se penche) | 0,55 s, amorti | 24 px | — |
| `eager` (Salamèche, « avec enthousiasme ») | 0 ; petit appel 0,08 s | 0,38 s | 48 px | 1 rebond de 10 px (0,16 s) |
| `playful` (Carapuce, « rapidement, vif et joueur ») | 0 | 0,26 s | 28 px | 2 petits rebonds de 8 puis 5 px (0,12 s chacun) |

Le saut part de l'élévation courante (`lift` 56 sur la table) et finit à 0 ; la case est libérée au départ et occupée à l'arrivée ; `hop_to(cell) -> bool` refuse une case prise ou solide ; une distance de plus d'une case allonge la durée (≈ +25 % par case supplémentaire). Aucune nouvelle image (Tween sur le sprite et l'ombre).

**Le Pokémon du rival vient vers lui** (décision n° 11) : le rival reste en `(9, 6)` et son Pokémon **saute vers lui** : `{ "hop": "$rival_starter", "to": { "near": "rival", "offsets": [[1, 0], [0, -1], [0, 1], [-1, 0]] } }` → Bulbizarre choisi (rival : Salamèche) : `(11, 5) → (9, 5)`, 2 cases le long du bord de la table ; Salamèche choisi (rival : Carapuce) : `(12, 5) → (10, 6)` ; Carapuce choisi (rival : Bulbizarre) : `(10, 5) → (10, 6)`. Le rival ne marche jamais dans la poche est (elle est fermée par le joueur et son Pokémon dans deux cas sur trois). Puis il part vers `(8, 8)`, son Pokémon en suiveur (toujours voisin de lui : l'étape `move` + `follower` du 3B marche telle quelle).

**Invariants** (remplacent §4.4, `tests/integration/test_starter_placement.gd`, grille réelle, PNJ présents pour `{ oak_met, oak_lab_reunion, starter_offered }`, pour **chacun des 3 choix**, en rejouant les résolutions de la scène avec `CutsceneMoves.resolve_near` et `GridWorld.find_path` et en déplaçant les occupants comme le ferait le directeur) :
- chaque starter est rencontrable depuis `(x, 6)` (libre, atteignable depuis l'entrée ; `InteractionFinder.find` renvoie la surcharge MEET) ;
- pas du joueur : `(10, 7)`, `(11, 7)`, `(11, 6)` ; case d'atterrissage du starter du joueur = case quittée par le joueur ; ensuite **joueur + orientation = case du starter** (il est devant lui) ;
- atterrissage du Pokémon du rival : `(9, 5)`, `(10, 6)`, `(10, 6)`, voisin du rival ; aucun saut de plus de 2 cases sur un axe ;
- chemin du rival de `(9, 6)` à `(8, 8)` avec suiveur : existe, ne passe ni par un warp ni par un déclencheur ;
- après la scène : le joueur n'est **pas enfermé** (l'entrée `(7, 9)` est atteignable) ; toute cible encore interactive (Maya, Chen, rival, starter restant) est utilisable depuis une case atteignable ; une case devenue inaccessible derrière un Pokémon (poche est) est admise tant qu'elle ne contient ni cible ni sortie — au prochain chargement, les starters pris ont disparu (`taken_*`) ;
- les cases de la scène ne sont ni des warps ni des déclencheurs, sauf le tapis `(7, 9)` (§13.6), jamais emprunté par la scène en 4A.

### 13.5 Scène `starter_chosen` (remplace §4.2 pour le 4A ; `data/cutscenes/starter.json`, T3)

```json
{
	"starter_chosen": {
		"unless": ["rival_challenged"],
		"steps": [
			{ "move": "player", "to": { "near": "player", "offsets": [[0, 1], [-1, 0], [1, 0]] } },
			{ "hop": "$player_starter", "to": { "near": "$player_starter", "offsets": [[0, 1]] } },
			{ "face": "player", "to": "$player_starter" },
			{ "face": "$player_starter", "to": "player" },
			{ "wait": 0.4 },
			{ "lean": "$player_starter", "to": "player" },
			{ "face": "oak", "to": "player" },
			{ "dialogue": "oak_starter_reciprocal" },
			{ "set": ["starter_chosen"] },
			{ "face": "rival", "to": "$player_starter" },
			{ "wait": 0.6 },
			{ "face": "rival", "to": "$rival_starter" },
			{ "wait": 0.6 },
			{ "dialogue": "rival_starter_pick" },
			{ "hop": "$rival_starter",
				"to": { "near": "rival", "offsets": [[1, 0], [0, -1], [0, 1], [-1, 0]] } },
			{ "face": "rival", "to": "$rival_starter" },
			{ "face": "$rival_starter", "to": "rival" },
			{ "wait": 0.5 },
			{ "move": "rival", "to": [8, 8], "follower": "$rival_starter" },
			{ "wait": 0.3 },
			{ "face": "rival", "to": "player" },
			{ "dialogue": "rival_challenge_wait" },
			{ "face": "rival", "to": "$rival_starter" },
			{ "wait": 0.6 },
			{ "face": "rival", "to": "$player_starter" },
			{ "wait": 0.6 },
			{ "face": "rival", "to": "player" },
			{ "dialogue": "rival_challenge" },
			{ "set": ["rival_challenged"] }
		]
	}
}
```
Décision n° 11 : « Alors ce sera toi. » ; son Pokémon vient vers lui ; quand il s'apprête à partir : « Attends. » ; il regarde son Pokémon, puis celui du joueur ; « On ne va quand même pas partir sans savoir ce qu'ils savent faire. ». Les regards se glissent **entre deux dialogues** : `turn` (clé de page) ne connaît que des identifiants de PNJ, pas les alias, et le Pokémon regardé change selon le choix. « Attends. » est donc un dialogue à part (comme « Hé ! Attends ! » au 3B).

Dialogues (remplace §4.1 ; `data/dialogues/oak_lab.json`, textes mot pour mot, reportés au dossier 02, « Ajouts de Kevin », « Jalon 4 ») :

| id | Locuteur | Pages |
|---|---|---|
| `oak_starter_offer` | Prof. Chen | les 4 répliques du §7 du dossier 02 ; page 3 `turn { "oak": "right" }`, page 4 `turn { "oak": "player" }` |
| `oak_starter_reciprocal` | Prof. Chen | « On dirait que le choix est réciproque. » |
| `rival_starter_pick` | Rival | « Alors ce sera toi. » |
| `rival_challenge_wait` | Rival | « Attends. » |
| `rival_challenge` | Rival | « On ne va quand même pas partir sans savoir ce qu'ils savent faire. » |
| `oak_lab_exit_block` | Prof. Chen | « Pas si vite. Tu n'as pas encore choisi ton partenaire. » |

Pas de `rival_starter_smile` ni de silence « petit sourire » (la décision n° 11 ne les reprend pas).

### 13.6 Sortie du labo empêchée (décision n° 2)

Comment sort-on aujourd'hui : le tapis `(7, 9)` porte un warp **PUSH** vers le bas. On y **arrive** par un pas (depuis `(7, 8)`, `(6, 9)` ou `(8, 9)`), puis on **pousse** vers le bas contre le mur ; le changement de carte vient de `Player.bumped`. En tenant « bas » depuis `(7, 8)`, l'arrivée et la poussée ont lieu dans le même `GridMover.update` : fin du pas (`step_finished` → `moved`), puis nouvelle tentative de pas vers le bas → `bumped` → warp.

Mécanique retenue (celle de la pensée des herbes) :
- un **`EventTriggerPoint`** `LabExit` sur **`(7, 9)`**, `size (1, 1)`, `direction` ZERO (on arrive sur le tapis de trois côtés), `cutscene_id` `oak_lab_exit`, ajouté par `tools/build_interiors.gd` (table `triggers` de la pièce, à créer sur le modèle de `build_pallet_town.gd`) ;
- scène `oak_lab_exit` (dans `data/cutscenes/starter.json`) :
```json
"oak_lab_exit": {
	"if": ["starter_offered"], "unless": ["starter_chosen"],
	"steps": [
		{ "face": "oak", "to": "player" },
		{ "dialogue": "oak_lab_exit_block" },
		{ "move": "player", "path": ["up"] }
	]
}
```
**Pourquoi le dialogue passe avant tout changement de carte** : le directeur écoute `moved` et pose `&"cutscene"` **dans l'appel** ; `GridMover.update` vérifie le verrou après `step_finished` (« un gestionnaire a pu verrouiller ») : aucune tentative de pas, donc aucun `bumped`, donc aucun warp. Le warp PUSH n'est pas trouvé par `find_on_step` (`matches_step` exige `STEP_ON`) : le routeur ne fait rien à l'arrivée. Après le recul, le joueur est en `(7, 8)`, libre ; le passage suivant rejoue la scène (comme les herbes).

**La scène de retour du 3B ne la déclenche pas**, pour trois raisons indépendantes : l'arrivée par `change_map` est une **apparition** (aucun `moved`) ; les pas `move player up` qui suivent sont **scriptés** (joueur bloqué, directeur déjà en cours : ignorés) ; et la variante exige `starter_offered`, levé seulement à la fin de cette même scène. Hors du choix (avant `starter_offered`, ou après `starter_chosen`), le déclencheur ne fait rien et l'on sort comme avant.

À modifier en T3 : l'invariant du 3B « une case ne porte jamais un warp et un déclencheur » devient « jamais un déclencheur sur un warp **STEP_ON** » (un déclencheur peut partager la case d'un warp PUSH : l'arrivée précède la poussée) ; `test_interiors.gd` (nœud `Triggers` du labo non vide) ; `test_cutscene_data.gd` : `VARIANT_FLAGS` pour `oak_lab_exit` et une liste des scènes **jouées par le code** (`starter_chosen`), exemptées de « chaque scène est visée par un déclencheur » et simulées avec les 3 jeux d'alias ; `(7, 8)` libre et praticable pendant tout le choix (`test_starter_placement.gd`) ; test d'intégration : tenir « bas » depuis `(7, 8)` pendant le choix → réplique, recul, **toujours au labo**.

### 13.7 PNJ et répliques d'attente du labo (4A)

- `bulbasaur`, `charmander`, `squirtle` : `unless: [taken_<id>]` (inchangé, §4.3) et `hop_style` (posé en T0).
- `oak` : `oak_lab_waiting` reçoit une variante `if: [starter_chosen]` placée en premier, avec les deux répliques de la décision n° 8 (« Le monde qui vous attend… » / « Prends le temps de l'observer… »). Pendant le choix (`starter_offered` sans `starter_chosen`), il garde la réplique du 3B (Q-C).
- `maya` : variante `if: [starter_chosen]` en premier, avec « Alors, c'est lui que tu as choisi ? » / « Vous avez l'air de déjà bien vous entendre. » ; « elle regarde le starter » : `turn` ne connaît pas les alias ; par défaut elle se tourne vers le joueur (Q-D).
- `rival` : `rival_lab_waiting` inchangé jusqu'au 4B (il quitte le labo après le combat).

### 13.8 Décision n° 15 (faite en T0)

- (a) Type électrique : **« Électrik »** dans `data/pokemon/types.json` (testé dans `test_type_chart.gd`). Aucun « Électrique » dans `game/`. Restent dans les documents de conception de Kevin (`ui-reference.md`, `dossier-06-progression.md`), non modifiés.
- (b) **Accord au féminin** : clé facultative **`"text_f"`** d'un modèle de `data/battle/messages.json`, choisie par `BattleText` quand `BattleEvent.gender` vaut `FEMALE` (sinon `"text"`) ; validée comme `"text"` (texte non vide, marques connues). Seul modèle concerné aujourd'hui : `recoil` (« {pokemon} est blessée par le contrecoup ! », `draft`). `BattleText.get_template(id, feminine)`, `has_feminine(id)`.
- (c) **Pas de message générique de fin** : clé facultative de dresseur **`"end_message"`** (vrai par défaut), `false` pour `rival_lab` ; `TrainerData.end_message` ; `BattleText.lines(event, data, trainer)` ne renvoie rien pour `BATTLE_ENDED` quand elle est fausse. Le `BattleDirector` (T8) passe le `TrainerData` du combat. Les autres dresseurs gardent « Tu as battu… ».
- (d) `base_exp` modernes : Florizarre **263**, Dracaufeu **267**, Tortank **265** (`data/pokemon/species/kanto.json`, testés avec les 6 autres dans `test_pokemon_data.gd`). §12 n° 2 est remplacé.

### 13.9 Découpage du 4A (remplace §5 T0 à T3 là où ils diffèrent)

**T0 — fait** (architecte, cette branche) : `Interaction.Kind.MEET` (fin d'enum, `&"meet"`, `is_valid` : source exigée, pas de dialogue ; `NpcRoster` refuse toujours `meet`) ; `CutsceneStep` / `CutsceneLibrary` : alias `$[a-z_]+` validés partout où un acteur ou une cible d'acteur est attendu (face, move, near, follower, hop, lean, despawn ; refusé pour `spawn`), étapes `hop` (`to` obligatoire : case ou `near`), `lean` (`to` : cible de `face`), `despawn` (pas « player ») — **validation seulement** ; `Cutscene.get_aliases()`, `CutsceneLibrary.get_aliases(id)`, `CutsceneStep.is_alias` / `alias_name` ; `NpcSpec.hop_style` ; renommage `starter_chosen` ; décision n° 15. Tant que T1 n'est pas fait, le directeur signale une étape `hop` / `lean` / `despawn` comme « inconnue » (aucune donnée n'en contient). **849 tests verts** (832 au départ).

**T1 — constructeur-monde** (ajouts au §5 T1) :
- `GameState` (§3.9, inchangé) ; `Npc.hop_to(cell) -> bool` avec les styles du §13.4 (coroutine ou signal `hopped`), `lean_toward` / `settle`, surcharge d'interaction ; `CutsceneDirector.play(id, aliases := {})`, résolution des alias au début de chaque étape (acteur, cible, `near`, `follower`), lecture de `hop` (attend la fin du saut), `lean`, `despawn` (`GameMap.remove_npc`, fondu 0,2 s) ; alias absent ou acteur introuvable : `push_error`, étape sautée ; `hop` refusé (case prise) : `push_error`, étape sautée.
- `InteractionController` : cible MEET → signal `meet_requested(npc)` au lieu d'un dialogue.
- `oak_starter_offer` et les 3 étapes ajoutées à la **variante 1 de `route1_grass`**.
- **CA** en plus du §5 T1 : `test_npc.gd` : un paramétrage par valeur de `NpcSpec.HOP_STYLES` (+ défaut) ; durée du saut `calm` > `eager` > `playful` ; `lift` et ombre à 0 à l'arrivée. `test_cutscene_director.gd` : l'alias est résolu **à chaque étape** (le PNJ qu'il désigne peut avoir bougé).

**T2 — ui-mobile** : inchangé (§5 T2).

**T3 — constructeur-monde** (remplace le §5 T3 là où il diffère) :
- `StarterChoice` selon §13.3 (espèce en attente, ajout sur `done_flag`, repli si `play` échoue) ; `data/cutscenes/starter.json` (§13.5 et §13.6) ; dialogues du §13.5 ; variantes du §13.7 ; déclencheur `LabExit` (§13.6) ; `taken_*` dans `data/npcs/oak_lab.json`.
- **CA** : ceux du §5 T3, avec ces changements : **l'équipe est vide jusqu'à « On dirait que le choix est réciproque. »** et compte 1 Pokémon juste après (bonne espèce, niveau 5, PV pleins, 2 capacités) ; pour chaque starter, le Pokémon choisi finit **sur la case que regarde le joueur** ; 4 répliques du rival et de Chen dans l'ordre du §13.5, **aucune** « Ça devrait être intéressant. » ; le rival prend le bon Pokémon et celui-ci finit à côté de lui ; sortie empêchée pendant le choix (§13.6), libre avant `starter_offered` et après `starter_chosen` ; invariants du §13.4.
- Capture et S24 : les trois styles de saut sont **distincts à l'œil** (Kevin juge).

### 13.10 Ce qui reste ouvert après ce travail (remplace §11 et complète §12)

Réglé : §11 n° 1 (3B présent et validé), n° 2 (format des PNJ), n° 3 (directions dans `Grid`), n° 5 (grille du labo : §13.2). §12 n° 7 (Électrik) et n° 2 (`base_exp`) : décision n° 15. §12 « Reportés » : `Interaction.Kind.MEET` et la validation des alias et des étapes `hop` / `lean` / `despawn` sont faits ; restent `BattleLayout` (Q23, « recomposé »), l'étape `battle` (T5), `GameState` (T1), la lecture des nouvelles étapes par le directeur (T1).

Toujours ouvert : §11 n° 4 (renommer `combat-capacites-v1.png.png`, commit de documentation).

Questions pour Kevin (propositions par défaut appliquées si rien n'est dit) :
- **Q-A — « Ça devrait être intéressant. » et le « petit sourire »** (dossier 02 §9 et §10) : la décision n° 11 ne les reprend pas. *Par défaut : supprimés (scène du §13.5).* Faut-il garder la réplique après « Alors ce sera toi. » ?
- **Q-B — le pas du joueur pour laisser descendre son Pokémon** : aujourd'hui il se retourne, fait un pas, puis se retourne vers le Pokémon (et, avec Carapuce, il s'écarte vers la gauche, le tabouret bloquant l'arrière). *Par défaut : ainsi.* Un vrai pas en arrière sans se retourner est possible (petit ajout à `Player`) si le rendu S24 ne convient pas.
- **Q-C — ce que disent Chen et le rival pendant le choix** : leurs répliques d'attente du 3B (« Un peu de patience. J'ai quelque chose à vous montrer. ») ne vont plus une fois l'offre faite. *Par défaut : inchangées jusqu'à ta réponse*, ou une réplique à écrire.
- **Q-D — Maya « regarde le starter »** : au 4A, le starter du joueur reste près de la table jusqu'à ce qu'on quitte le labo ; au 4B, il rentre dans sa Ball (Q21). *Par défaut : Maya se tourne vers le joueur.* Veux-tu que le starter reste visible à côté du joueur au labo (ce qui touche au compagnon du dossier 04 §4) ?
- **Q-E — les trois styles de saut** (tableau du §13.4) : valeurs de départ, à régler sur le S24.

### 13.11 Dépendances au 3B : ce qui a été livré (remplace le tableau du §9)

| Dépendance | Livré par le 3B (code réel) | Conséquence pour le 4A |
|---|---|---|
| Scène en données, dernière étape `set: [oak_lab_reunion]` | Oui, mais c'est la **variante 1 de `route1_grass`**, pas une scène `oak_intercept` | On ajoute 3 étapes à la fin de cette variante (T1). |
| `CutsceneDirector` | `play(cutscene_id)`, `is_running`, `get_step_index`, `get_cutscene_id`, signaux `cutscene_started` / `step_started` / `cutscene_finished` ; 7 étapes ; `near`, `follower`, `run` ; `MOVE_BLOCK_TIMEOUT` | Alias, `hop`, `lean`, `despawn` : validation faite (T0), lecture en T1. `follower` existe : le rival part avec son Pokémon. |
| `Npc` qui marche | `GridMover`, `enter_grid`, `leave_grid`, `step`, `is_moving`, `step_finished`, `face`, `face_toward`, `react` (petit bond, constantes `HOP_HEIGHT` / `HOP_DURATION`) | `hop_to` s'y ajoute (T1) ; attention au nom des constantes (§13.1). |
| `GameMap.add_npc`, `remove_npc`, `refresh_npcs(flags)`, `get_npc` | Oui | `despawn` et `taken_*` s'appuient dessus. |
| `NpcSpec` `if` / `unless`, `NpcRoster.parse_entry` | Oui | `taken_*` (T3) ; `hop_style` ajouté en T0. |
| Clé de page `turn` | Oui, identifiants de PNJ ou « player » (pas d'alias) | Regards du rival entre deux dialogues (§13.5). |
| `Player.script_step` ; blocage par raisons ; `Boot._refresh_controls` | Oui | Inchangé. |
| `InteractionController.set_enabled` | **Non** (le blocage du joueur suffit) | MEET passe par `_interact` (T1). |
| PNJ `oak` (8, 4) et `rival` (9, 6), `if: [oak_met]` | Oui, **avec** leurs répliques d'attente | Variantes du §13.7. |
| Blocage des hautes herbes | Variante 2 de `route1_grass`, `unless` sur le drapeau du starter (renommé `starter_chosen` en T0) | Se lève tout seul quand la scène `starter_chosen` lève le drapeau. |
| Étiquette « Prof. Chen » | Oui | Tous les nouveaux dialogues de Chen. |
| `EventTriggerPoint` / `TriggerTable` | Oui (Route 1) ; aucun dans les intérieurs | Déclencheur `LabExit` en T3 (§13.6). |
