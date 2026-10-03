# Jalon 6 — Le Menu Dresseur

> Objectif jouable sur le S24, écran par écran, dans l'ordre du dossier 08 §11.
>
> **6.0 — Ouvrir et fermer.** En exploration, un petit bouton rond ouvre en ~250 ms un **tableau de bord plein écran** posé sur le monde flouté et assombri ; le monde est **en pause** derrière. À gauche, la carte du Dresseur (« Kevin », « Dresseur Pokémon », portrait, temps de jeu) et le **Pokémon de tête** (nom, Nv., PV) ; à droite, **cinq grandes cartes** (ÉQUIPE · SAC · CARTE · DRESSEUR · PARAMÈTRES : la carte POKÉDEX est **absente** avant son activation au J7A) ; en bas, une ligne discrète « Objectif : rejoindre Jadielle ». Le × ou le retour Android referme : on retrouve exactement l'exploration. En exploration, le retour Android **ouvre** le menu ; il ne quitte jamais le jeu (Q-3).
>
> **6A — Équipe.** La liste à gauche, le Pokémon sélectionné en grand au centre, sa fiche à droite (Aperçu · Capacités · Histoire), barre d'XP « 320 / 560 XP — 240 XP avant le niveau suivant ». On réordonne l'équipe au doigt (appui long puis glisser) **ou** par DÉPLACER ; on marque un **FAVORI**.
>
> **6B — Sac.** Catégories à gauche, objets en cartes au centre, aperçu à droite. UTILISER une Potion → l'équipe avec ses PV → « +20 PV — Salamèche 33/51 » → UTILISER À NOUVEAU. **Le même Sac en combat** : la Potion se donne aussi pendant un combat sauvage.
>
> **6C — Pokédex** (débloqué par un **drapeau de débogage** : en partie normale, il n'existe qu'au J7A). Grille 1 à 151, inconnu / vu / capturé, fiche en quatre onglets, aucune silhouette, aucun spoiler.
>
> **6D — Carte.** Le Kanto du projet, Bourg Palette et la Route 1 racontées ; toucher une zone → panneau latéral.
>
> **6E — Dresseur.** Le résumé vivant de l'aventure : identité, 8 emplacements de badges vides et muets, grands moments datés.
>
> **6F — Paramètres.** Vitesse du texte, joystick, mode gaucher, haptique, réduction des animations et des flashs, taille du texte, contraste, « Sauvegarder maintenant ».

**Pré-requis** : le **jalon 5 validé par Kevin et fusionné** (T16, 5F). Au moment de ce plan, il reste le T16 (QA de la capture) et le 5F. **Rien du J6 n'est codé avant** (décision de Kevin). Ce plan s'appuie sur le code réel de `jalon-05` au commit `c1842e5` ; la tâche d'architecture de chaque sous-jalon commence par **aligner ce plan sur le code du moment** (comme les §15 du jalon 5 et §13–14 du jalon 4). Départ mesuré sur `c1842e5` : **1582 tests verts** (104 scripts), import sans erreur. **Aligné au T0 sur le code fusionné `d8e8f2b`** (jalon 5 complet + lot de dettes) : écarts au §15 ; 1600 tests au départ du J6, 1619 après le T0.

**Hors périmètre** (dossiers 08 et 09, règle de déblocage, règle « une couche à la fois ») :
- **Argent** (J7A), **badges obtenus** (J10), **Stockage Pokémon** et son écran (J7A), **Boutique** (J7A), **colis** (premier objet clé, J7A), **activation narrative du Pokédex** par Chen (J7A).
- **Évolutions jouables**, **CT**, **statuts** (J11) : la fiche n'affiche que l'état K.O. ; PSN, PAR, SOM, BRÛ, GEL viendront avec les statuts.
- **Changement de Pokémon en combat** (ÉQUIPE en combat, J11).
- **Son** (phase 10) : pas de catégorie AUDIO. **Réglages graphiques** : une seule catégorie GRAPHISMES minimale, Auto / Élevée / Économie (Q-17).
- **Vol** sur la Carte, recherche et filtres de la Carte, cartes locales, souvenirs de découverte (plus tard, dossier 08 §5).
- Personnalisation du Dresseur, niveau ou XP de Dresseur, titres, tenues, pourcentage d'histoire (exclus par le dossier 08 §6).
- Rendu « vraie DA » des écrans, illustrations HD des Pokémon, illustration finale de la carte de Kanto : provisoires aux dimensions finales (`CLAUDE.md` règle 3).

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/vision.md` (philosophie officielle, **règle de déblocage**), `roadmap.md` (phase 3), **`dossier-08-menu-dresseur.md`** (source de vérité, corrections du 2026-10-02 comprises), `dossier-09-jadielle.md` §6, §8, §16, §17, `dossier-04-systeme-pokemon.md`, `dossier-05-combat.md` §21, `ui-ux-bible-v0.1.md` (§1, §6, §11, §12 ; §7 remplacé par le dossier 08), `ui-reference.md`, maquettes `reference/menu-*-v1.jpg` (**DA uniquement**, `CLAUDE.md` règle 10), [`jalon-05.md`](jalon-05.md) §16 et §17, skills `godot-conventions`, `ui-theme-2026`.

---

## 1. Découpage

| | 6.0 Fondations + tableau de bord | 6A Équipe | 6B Sac | 6C Pokédex | 6D Carte | 6E Dresseur | 6F Paramètres |
|---|---|---|---|---|---|---|---|
| Couche nouvelle | sauvegarde v2, pause, navigation, bouton Menu, retour Android, objectif | réordonner, favori, fiche | objets utilisables, catégories, favoris, tri, soin en combat | fiches, filtres, notes, observation, toasts | zones, journal de la carte | résumé, moments, badges muets | réglages, fichier de réglages, haptique centralisée |
| Visible sur le S24 | ouvrir, fermer, cinq cartes | l'équipe et ses fiches | utiliser une Potion (menu et combat) | le Pokédex (drapeau de débogage) | la carte et ses panneaux | l'écran Dresseur | les réglages agissent pour de vrai |
| Validation S24 | **la sauvegarde v2 seule** (T1), puis le tableau de bord (T5) | T9 | T13 | T17 | T22 | T26 | T30 + QA finale du J6 |

Pourquoi ce découpage :
- **Une fonctionnalité → testée sur S24 → validée → suivante** (règle 1). Les fondations ne se jugent qu'avec un écran : elles sont validées avec le tableau de bord.
- **La sauvegarde v2 est validée seule** (règle 1, exception « système à risque ») : elle se fait **une seule fois pour tout le J6**, au T0, avec tous les champs du J6 et leurs valeurs par défaut, avant tout écran. Les sous-jalons suivants n'y touchent plus.
- **6B porte le seul changement du moteur de combat** du J6 (la Potion en combat). Il est validé avec le Sac, pas avec un autre écran.
- **6C avant 6D** (ordre du dossier) : la Carte affiche les Pokémon observés et le Pokédex ouvre la Carte ; le lien Pokédex → Carte est posé en 6C vers un écran provisoire, et branché en 6D.

Chaque sous-jalon ne commence qu'une fois le précédent **validé par Kevin**. Pendant la QA d'un sous-jalon, l'architecte peut préparer les fondations pures du suivant sur sa branche (§8).

---

## 2. Ce qui existe déjà (code réel, `c1842e5`) et ce que le J6 réutilise

### 2.1 Données déjà enregistrées depuis le J5 (jalon 5 §16)

| Fait | Où, dans le code | Écran du J6 |
|---|---|---|
| Équipe, ordre, PV, PP, XP, capacités | `GameState.party` (`Party`, `Pokemon.to_dict`) | 6A |
| Rencontre de chaque Pokémon : manière, carte, niveau, date, dresseur | `Pokemon.origin`, `met_map`, `met_level`, `met_date`, `original_trainer` | 6A Histoire |
| Pokédex par espèce : vu, capturé, premières observation et capture (carte, date), cartes vues, compteurs | `Pokedex` + `PokedexEntry` | 6C, 6D, 6E |
| Sac (quantités ; depuis le T0 : favoris et ordre d'obtention) | `Bag` (v1 : `{ "poke_ball": 5 }` ; v2 : `{ "items", "favorites", "acquired" }`, §5.1) | 6B |
| Temps de jeu, début de l'aventure, nom du joueur | `GameState.play_time`, `started_at`, `player_name` | tableau de bord, 6E |
| Zones découvertes (carte → date) | `GameState.discovered_maps` | 6D, 6E |
| Objets trouvés (objet, carte, date) | `GameState.found_items` | 6D |
| Grands moments (`starter`, `rival_battle`, `first_capture`) | `GameState.moments` | 6E |
| Drapeaux d'histoire, dont `pokedex_activated` (jamais posé avant le J7A) | `StoryFlags`, `StoryFlags.POKEDEX_ACTIVATED` | règle de déblocage |
| Stockage (« système de recherche de Chen ») | `GameState.storage` | rien au J6 (écran au J7A) |

### 2.2 Composants réutilisés tels quels

- **Fond flouté et assombri** : `game/battle/battle_backdrop.gdshader` (flou par les mipmaps de la copie d'écran, voile, vignettage), validé à 62 fps en combat. Le menu en pose une instance avec un flou plus fort et un voile plus sombre.
- **Toast** (`game/ui/components/toast.tscn`), **`HapticPattern`**, **`TypeBadge`**, **`HpBar`**, **`ExpBar`**, **`MoveCard`** et **`MoveDetailSheet`** (fiche d'une capacité), **`ComingSoonScreen`** (écran provisoire des écrans pas encore construits, en build de développement seulement).
- **Composants du Sac** déjà dessinés d'après le dossier 08 §3 : `BagCategoryTab`, `BagItemCard`, `BagTile`, `BagEntryView`. Ils sont **déplacés** de `game/ui/battle/` vers `game/ui/bag/` au T11 (avec leurs `.uid` ; aucun nom de classe ne change).
- **`UiTokens`** et `tools/build_ui_theme.gd` (nouvelles constantes et variations de thème `Menu*`), **`MapCatalog`**, **`DebugStart`**, **`SaveSystem`** / **`SaveFileSystem`** / **`JsonFields`**.

### 2.3 Ce qui doit être généralisé

| Aujourd'hui | Au J6 |
|---|---|
| `BattleViews.bag_entries(bag, items)` et `USABLE_IN_WILD_BATTLE = [BALL]` : le Sac du combat ne montre que les Balls | **`BagQuery`** (pur) fournit les entrées du Sac pour **tous** les contextes (exploration, fiche Équipe, combat sauvage). `BattleViews.bag_entries` devient une enveloppe de `BagQuery`. **Un seul Sac** : même `GameState.bag`, mêmes règles (`ItemUse`), mêmes composants ; deux mises en page (plein écran en exploration, panneau en bas à gauche en combat). |
| La Potion est rangée mais inutilisable (décision Q-A du J5) | `ItemData.heal_amount`, règle `ItemUse`, et action de combat `BattleAction.heal(item_id, index)` |
| `Input.vibrate_handheld` appelé à 7 endroits | une porte unique `Haptics.vibrate(ms)`, coupée par le réglage (6F) |
| Tailles de police et couleurs constantes (`UiTokens`) | `UiPrefs` (taille du texte, contraste) lu par les écrans du J6, la boîte de dialogue, le toast et le titre de zone (6F, Q-19) |
| `DialogueRunner.chars_per_second`, `BattleDirector.speed_scale` : prêts, jamais réglés | branchés sur les réglages (6F) |

---

## 3. Fondations logiques (architecte, classes pures et tests)

Toutes en `RefCounted` (ou statiques), sans nœud ni autoload, testées avec GUT ; données JSON validées strictement comme les bibliothèques existantes (clé inconnue, type, bornes, doublon, ligne du JSON illisible, références croisées vérifiées). Les vues (`*View`) ne contiennent que des chaînes, des nombres et des textures, comme `BattleCardView` : les écrans ne connaissent ni `GameState`, ni `Pokemon`, ni les données.

### 3.1 Sauvegarde v2 (T0)

**Fait au T0.** Voir §5.1. Fichiers : `save_system.gd` (`VERSION = 2`, cas 1 → 2 dans `upgrade`, membre `version` pour simuler une build plus ancienne dans les tests), `bag.gd` (favoris, ordre d'obtention, forme v2, `Bag.upgrade_flat`), `pokemon.gd` (`favorite`), `pokedex_entry.gd` (`notes`). La capture comptée comme observation (Q-8) était **déjà codée** par le lot de dettes du J5 (§15) : rien à refaire.

### 3.2 Navigation et déblocage (T2)

```gdscript
class_name MenuRoute
extends RefCounted
## Un écran du Menu Dresseur et ses paramètres (dossier 08 §8). Donnée pure.
const DASHBOARD: StringName = &"dashboard"
const TEAM: StringName = &"team"
const BAG: StringName = &"bag"
const POKEDEX: StringName = &"pokedex"
const MAP: StringName = &"map"
const TRAINER: StringName = &"trainer"
const SETTINGS: StringName = &"settings"
## Ordre des cartes du tableau de bord (dossier 08 §1).
const DASHBOARD_ORDER: Array[StringName] = [TEAM, POKEDEX, BAG, MAP, TRAINER, SETTINGS]
var screen: StringName
var params: Dictionary          # clés documentées par écran, ci-dessous
static func dashboard() -> MenuRoute
static func team(index: int = 0) -> MenuRoute                          # { "index" }
static func bag(context: StringName = BagQuery.CONTEXT_FIELD, target: int = -1) -> MenuRoute
static func pokedex(filter: int = PokedexQuery.Filter.ALL, species: StringName = &"") -> MenuRoute
static func map(zone: StringName = &"") -> MenuRoute
static func trainer() -> MenuRoute
static func settings() -> MenuRoute
```

```gdscript
class_name MenuUnlocks
extends RefCounted
## Ce qui existe pour le joueur (règle de déblocage, vision.md ; dossier 08 §1 et §4).
## Lit l'état, ne le modifie jamais : le drapeau de débogage n'est PAS un drapeau d'histoire.
var debug_pokedex: bool = false
func _init(flags: StoryFlags, party: Party) -> void
## Vrai si `pokedex_activated` est posé, ou si le drapeau de débogage l'est.
func pokedex_visible() -> bool
## Vrai dès que l'équipe compte un Pokémon (Q-2).
func team_visible() -> bool
## Cartes du tableau de bord, dans l'ordre : absentes (jamais grisées) si indisponibles.
func dashboard_cards() -> Array[StringName]
func is_available(screen: StringName) -> bool
```

```gdscript
class_name MenuNavigator
extends RefCounted
## Pile d'écrans du menu : ouverture, fermeture, liens croisés, retour (dossier 08 §1, §8).
signal opened(route: MenuRoute)
signal route_changed(route: MenuRoute)
signal closed
func _init(unlocks: MenuUnlocks) -> void
## Ouvre sur [param route] (tableau de bord par défaut). Faux si déjà ouvert. Une route
## indisponible ouvre le tableau de bord.
func open(route: MenuRoute = null) -> bool
func close() -> void
func is_open() -> bool
func current() -> MenuRoute
func depth() -> int
## Va vers [param route] (carte du tableau de bord ou lien croisé). Faux, et rien ne change,
## si l'écran est indisponible (Pokédex non activé, Équipe vide). Si l'écran est déjà dans la
## pile, on y revient en coupant la pile au-dessus (jamais de boucle Pokédex ↔ Carte qui
## s'empile) et ses paramètres sont remplacés.
func go(route: MenuRoute) -> bool
## Retour : écran précédent ; depuis le tableau de bord, ferme. Vrai si quelque chose a changé.
func back() -> bool
```

```gdscript
class_name DebugUnlocks
extends RefCounted
## Drapeau de débogage du dossier 08 §4 et du dossier 09 §6 : débloque l'écran Pokédex pour
## développer et tester le J6, **sans** poser `pokedex_activated` (rien n'est sauvegardé).
## Lu par Boot seulement en build debug, quand Boot est la scène principale (même garde que
## DebugStart.is_allowed), si `user://debug_unlocks.json` existe : { "pokedex": true }.
const USER_PATH: String = "user://debug_unlocks.json"
var pokedex: bool = false
func load_file(path: String) -> bool          # validation stricte (clé inconnue = erreur)
```
`tools/deploy_s24.sh --debug-unlock pokedex` dépose le fichier ; sans l'option, il est retiré (même mécanique que `--debug-start`). Il fonctionne **avec la vraie sauvegarde de Kevin** (le Pokédex se teste sur les vraies données du J5) ou avec un départ de débogage.

```gdscript
class_name ObjectiveLibrary
extends RefCounted
## « Objectif : … » du tableau de bord (dossier 08 §1) : rappel narratif, jamais un GPS.
## data/story/objectives.json : liste ordonnée [{ "text", "if", "unless", "draft" }] ;
## la première entrée dont les conditions tiennent l'emporte ; aucune → pas de ligne.
func load_file(path: String = "res://data/story/objectives.json") -> bool
func current(flags: StoryFlags) -> String
func get_errors() -> PackedStringArray
```

```gdscript
class_name ZoneLibrary
extends RefCounted
## Zones du Kanto du projet (data/world/zones.json) : une zone regroupe des cartes (un
## intérieur appartient à sa ville). T2 : noms et cartes ; T18 : le reste (Carte, 6D).
func load_file(path: String = "res://data/world/zones.json") -> bool
func zone_of(map_id: StringName) -> StringName        # &"" si la carte n'est rangée nulle part
func get_zone(id: StringName) -> ZoneData             # id, name, kind, maps, subtitle, …
func get_ids() -> Array[StringName]
func get_errors() -> PackedStringArray
```

Vue du tableau de bord : `DashboardViews.build(state, data, zones, objectives, unlocks) -> DashboardView` (nom, « Dresseur Pokémon », temps de jeu « 12 h 43 », ligne « vus · capturés » **vide** tant que le Pokédex n'est pas visible, ligne des badges vide avant le premier badge (Q-13), Pokémon de tête (`TeamMemberView` ou null), cartes, objectif, nom de la zone actuelle).

Tests : `test_menu_route`, `test_menu_navigator` (ouvrir, fermer, retour depuis le tableau de bord = fermer, lien croisé indisponible refusé sans changement, boucle Pokédex → Carte → Pokédex coupée, profondeur bornée), `test_menu_unlocks` (§4), `test_debug_unlocks`, `test_objective_library` (données réelles : 0 erreur ; ordre ; conditions ; clé inconnue), `test_zone_library` (données réelles : **chaque carte de `MapCatalog` appartient à exactement une zone**), `test_dashboard_views`.

**Fait au T2 (2026-10-03)** — ce qui diffère du croquis ci-dessus :
- Fichiers : `game/systems/menu/` (`menu_route.gd`, `menu_navigator.gd`, `menu_unlocks.gd`, `objective_library.gd`, `dashboard_views.gd`, `views/dashboard_view.gd`, `views/menu_card_view.gd`, `views/team_member_view.gd`), `game/world/zones/` (`zone_data.gd`, `zone_library.gd`), `game/systems/debug/debug_unlocks.gd`, `data/story/objectives.json`, `data/world/zones.json`, option `--debug-unlock` de `tools/deploy_s24.sh`.
- `MenuRoute` ne dépend ni de `BagQuery` ni de `PokedexQuery` (pas encore écrits) : il porte `BAG_CONTEXT_FIELD` / `BAG_CONTEXT_TEAM` et `DEX_FILTER_ALL..HABITAT` (0 à 3) ; **T10 et T14 reprennent ces valeurs** (même ordre pour `PokedexQuery.Filter`). `MenuRoute.for_screen(screen)` donne la route d'une carte du tableau de bord.
- `MenuNavigator.open(route)` pose toujours le tableau de bord au fond (un retour depuis l'écran ouvert y revient). `go` sur la route déjà affichée : accepté, `route_changed` non émis. Au-delà de `MAX_DEPTH` (4), **le nouvel écran remplace celui du dessus** (défaut, règle 4).
- `ObjectiveLibrary` : chaque entrée a un **`id`** (unique) en plus de `text`, `if`, `unless`, `draft` ; `text` est la fin de la ligne, `DashboardViews.OBJECTIVE_PREFIX` (« Objectif : ») la complète. Fichier = liste JSON (l'ordre fait foi). Q-4 : `reach_viridian` « rejoindre Jadielle », `if: [rival_battle_done]` (drapeau levé par la scène du labo), `draft`.
- **Zones : une seule source par fait.** `data/world/zones.json` porte **l'identité** des 22 zones (identifiant, nom, genre `town` / `route` / `place` / `sea_route`, cartes) ; `assets/ui/map/kanto_placeholder_areas.json` ne porte plus **que la géométrie** de l'illustration (le `kind` en a été retiré ; `tools/kanto_zones_overlay.gd` lit le genre dans `zones.json`). Mêmes identifiants des deux côtés (test). **Le rectangle ne sera pas recopié dans `zones.json` au T18** (§3.6) : il appartient à l'illustration, qui sera refaite en phase DA à une autre taille, pas à la zone. Noms : ceux du dossier 06 (Carmin-sur-Mer, Cramois'Île…) ; seules Bourg Palette et la Route 1 ont des cartes. Test croisé : le `display_name` de chaque carte = le nom de sa zone (deux sources aujourd'hui, à unifier quand `GameMap` lira `ZoneLibrary`).
- `DebugUnlocks.is_allowed` = `DebugStart.is_allowed` ; `apply(unlocks)` ne touche que `MenuUnlocks.debug_pokedex`. Fichier `user://debug_unlocks.json`, clés `DebugUnlocks.KEYS` (`pokedex`). Lu par `Boot` au T4.
- Textes des cartes (titre + une ligne, tutoiement, sans « audio ») : constantes d'interface `DashboardViews.CARD_TEXTS` (défaut, règle 4).

### 3.3 Équipe (T6)

- `Party.move(from: int, to: int) -> bool` (insère à la place, décale les autres), `Party.swap(a: int, b: int) -> bool`. Le premier reste le Pokémon de tête. (`Party.index_of(pokemon) -> int` **existe déjà**, lot de dettes du J5.)
- `Pokemon.favorite: bool` : **posé au T0** (champ public, sauvegardé ; pas de setter nécessaire).
- `ExpCalc.level_span(pokemon, data) -> Vector2i` : XP gagnée dans le niveau et XP du niveau (« 320 / 560 », reste « 240 XP avant le niveau suivant ») ; au niveau 100, `Vector2i.ZERO` (la barre est pleine, pas de texte).
- `EvolutionReveal.chain(species, data, pokedex, visible: bool) -> Array[EvolutionStageView]` : la chaîne de la lignée ; un stade est révélé s'il est **vu** et si le Pokédex est **visible** ; sinon « ??? ». **Jamais de condition** (niveau, objet). Une espèce sans évolution n'a pas de section (Q-9).
- `TeamViews.build(party, data, zones, pokedex, unlocks) -> TeamView` : membres (`TeamMemberView` : nom, sexe, Nv., PV, statut en texte — seulement « K.O. » au J6 —, favori, sprite) et fiche du sélectionné (`PokemonSheetView` : types, sexe, statistiques en `StatView` (nom, valeur, part de la jauge), capacités en `BattleMoveView` existants, histoire en `HistoryView` (lieu = nom de **zone**, niveau, dresseur, date « 2 octobre 2026 »), XP, évolution).

Tests : `test_party` (étendu : déplacer, échanger, bornes, tête), `test_exp_calc` (étendu), `test_evolution_reveal` (Salamèche → ??? → ??? ; Reptincel vu mais Pokédex non visible → ??? ; visible → révélé ; aucune condition dans les textes), `test_team_views` (statut K.O., histoire avec la zone d'un intérieur → nom de la ville, starter « Labo du Prof. Chen » → « Bourg Palette »).

**Fait au T6 (2026-10-03)** — ce qui diffère du croquis ci-dessus :
- Fichiers : `game/pokemon/party.gd` (`swap`, `move`), `game/pokemon/exp_calc.gd` (`level_span`), `game/systems/menu/` (`team_views.gd`, `evolution_reveal.gd`, `menu_format.gd`, `views/team_view.gd`, `views/pokemon_sheet_view.gd`, `views/stat_view.gd`, `views/history_view.gd`, `views/evolution_stage_view.gd`). Tests : `test_party` et `test_exp_calc` étendus, `test_evolution_reveal`, `test_team_views`, `test_menu_format` (+37, 1779 verts).
- **Réordonner = échanger** : `member_moved(from, to)` est appliqué par **`Party.swap`** (dossier 08 §2 : « courte animation d'échange » ; DÉPLACER = « choisir A, puis l'emplacement B » ; Rouge/Bleu). `Party.move` (insertion) existe et est testé, pour un futur Stockage. Défaut (règle 4). Sélection après l'échange : elle **suit le Pokémon sélectionné** (`TeamViews.selection_after_swap`).
- **`EvolutionReveal` vit dans `game/systems/menu/`** (pas `game/pokemon/`) : il fabrique des vues du menu ; le Pokédex (6C) le réutilise. Règle Q-9 appliquée (lecture stricte de « seulement ce que le joueur a réellement découvert ») :
  - lignée d'une seule espèce → `[]`, pas de section ;
  - Pokédex non visible → **un seul** « ??? » (même si un stade a déjà été vu, même pour un dernier stade) ;
  - Pokédex visible → l'espèce de la fiche et les espèces **vues** de la lignée, à leur colonne ; une colonne sans espèce vue **entre** deux colonnes connues → « ??? » ; après la dernière colonne connue, **un seul** « ??? » s'il reste des stades, **jamais leur nombre** (le croquis « Salamèche → ??? → ??? » révélait trois stades : écarté) ; dans une colonne qui a une espèce vue, les branches inconnues sont tues (« Évoli → Voltali »). Exemples : « Salamèche → ??? », « Salamèche → Reptincel → ??? », « Salamèche → ??? → Dracaufeu », « ??? → Reptincel → ??? ».
  - Un stade inconnu n'a ni nom, ni espèce (&""), ni image ; aucun champ ne porte de condition.
- **Fiches de tous les membres** dans `TeamView` (pas seulement du sélectionné) : l'écran change de Pokémon sans aller-retour (`member_selected` est informatif) ; `show_team(view, selected)` du §6.5 inchangé.
- **Histoire** d'après `met` seulement : libellé selon la manière (« Reçu à » starter, « Capturé à », « Rencontré à » inconnue), lieu = **nom de zone** (`ZoneLibrary.zone_name_of` ; carte hors zone → ligne absente, jamais un identifiant), niveau, dresseur d'origine, date « 2 octobre 2026 » / « 1er novembre 2026 » (`MenuFormat.long_date`), phrase « Ton premier Pokémon » pour le starter. Aucun moment n'est lié à un Pokémon précis (`moments` porte l'espèce, pas l'individu) : « premier combat » etc. restent « plus tard » (dossier 08 §2). Pokémon sans rencontre (avant le 5C.5) : `HistoryView.is_empty()`, l'écran écrit `TeamViews.HISTORY_UNKNOWN` (« Son histoire commence avec toi. », provisoire).
- XP : « 30 / 44 XP » et « 14 XP avant le niveau suivant » en deux champs ; milliers séparés par une espace insécable (`MenuFormat.number` : « 1 250 ») ; niveau 100 → deux textes vides, barre pleine.
- Statistiques : `StatView` (identifiant, « PV », « Attaque », « Défense », « Atq. Spé. », « Déf. Spé. », « Vitesse », valeur, part de la plus haute statistique du Pokémon) ; PV = PV max.
- Favori : pas de méthode (champ public `Pokemon.favorite`, posé au T0) ; MenuDirector l'inverse (§6.7).

### 3.4 Sac (T10)

**Catégories en données** (dossier 08 §3) : `ItemData.Category` gagne, **en fin d'enum**, `BATTLE`, `FIELD`, `KEY` ; `CATEGORY_NAMES = ["ball", "heal", "battle", "field", "key"]`. Les identifiants des fichiers ne changent pas (`ball`, `heal`) : **aucune migration des données ni de la sauvegarde** (le Sac stocke des identifiants d'objets, pas de catégories).

| Donnée (`category`) | Onglet | Utilisable | Au J6 |
|---|---|---|---|
| `heal` | SOINS | exploration et combat | Potion (`heal_amount: 20`) |
| `ball` | CAPTURE | combat sauvage | Poké Ball |
| `battle` | COMBAT | combat (« Utilisable en combat » hors combat) | aucun objet |
| `field` | AVENTURE | exploration | aucun objet |
| `key` | OBJETS CLÉS | jamais « utilisé », jamais vendu ni jeté | aucun objet (le colis au J7A) |
| (favoris) | FAVORIS | selon l'objet | rangée en tête, seulement si non vide |

Ordre des onglets : FAVORIS (si non vide), SOINS, CAPTURE, COMBAT, AVENTURE, OBJETS CLÉS. **Un onglet vide n'apparaît pas** (aucune catégorie artificielle, rien d'annoncé d'avance).

- `ItemData.heal_amount: int` (clé `heal_amount`, obligatoire pour `heal`, refusée ailleurs) ; `ItemData.contexts() -> Array[StringName]` déduits de la catégorie (tableau ci-dessus).
- `ItemUse` (statique, **une seule règle pour le menu et le moteur de combat**) :
```gdscript
class_name ItemUse
extends RefCounted
enum Check { OK, NOT_IN_BAG, WRONG_CONTEXT, FULL_HP, FAINTED, NOT_USABLE }
static func check(bag: Bag, item: ItemData, pokemon: Pokemon, context: StringName) -> Check
## Applique l'objet sur [param pokemon] et retire un exemplaire du Sac, seulement si check = OK.
static func apply(bag: Bag, item: ItemData, pokemon: Pokemon, context: StringName) -> ItemUseResult
```
  `ItemUseResult` : `check`, `item_id`, `hp_before`, `hp_after`, `max_hp`, `remaining`. Les raisons affichées (« PV déjà au maximum », « Ce Pokémon est K.O. ») sont des textes d'interface choisis par la vue d'après `Check` (Q-11).
- `Bag` : **posés au T0** : `is_favorite(id)`, `set_favorite(id, value) -> bool`, `favorite_ids()` (ordre de marquage), `acquired_rank(id) -> int` (rang de la **dernière** obtention : chaque `add` rend l'objet le plus récent, Q-12) ; un objet retiré à 0 garde son favori et son rang (il réapparaîtra favori). Le T10 n'ajoute qu'un éventuel `toggle_favorite(id)` (enveloppe de `set_favorite`).
- `BagQuery` (statique) : `CONTEXT_FIELD`, `CONTEXT_TEAM`, `CONTEXT_WILD_BATTLE`, `CONTEXT_TRAINER_BATTLE` ; `enum Sort { RELEVANCE, NAME, QUANTITY, RECENT }` ; `entries(bag, items, context, sort, target: Pokemon = null) -> Array[BagEntryView]` (catégorie, favori, utilisable ici, mention « Utilisable en combat ») ; `categories(entries) -> Array[StringName]` ; `start_category(context, last) -> StringName` (combat sauvage : CAPTURE ; depuis l'Équipe : SOINS, filtrés sur les objets **compatibles** avec ce Pokémon ; exploration : le dernier onglet ouvert pendant la session). « Pertinence » : en combat sauvage, Balls puis soins ; ailleurs, l'ordre des données.
- `PartyPickerView` : pour chaque membre, nom, PV, et soit « utilisable », soit la **raison** (jamais un bouton désactivé sans explication).

**Moteur de combat** (le seul changement de moteur du J6, T10) :
- `BattleAction.heal(item_id: StringName, party_index: int) -> BattleAction` (`Kind.ITEM` existant, champ `target` ajouté ; −1 pour une Ball).
- `BattleRules.allow_heal_items` (vrai pour `for_wild` et `for_trainer`) ; légal si `ItemUse.check(..., CONTEXT_*_BATTLE) == OK` ; joué **avant les capacités** comme une Ball ; l'adversaire joue ensuite (Q-10). Le moteur applique le soin au `Pokemon` de l'équipe ; **il ne touche pas au Sac** (le directeur retire l'objet une fois, comme la Ball au 5D).
- `BattleEvent.Kind.ITEM_USED` (**fin d'enum**) : `side`, `pokemon_name`, `species_id`, `hp`, `max_hp`, `amount`, `item_id`, `party_index`. (`BattleEvent.party_index` **existe déjà** sur tout événement de Pokémon, rempli par `Battle._pokemon_event` ; le directeur retrouve le Pokémon par `_find_player_pokemon` : le soin d'un membre hors combat s'appuie dessus.)
- `BattleText` + `data/battle/messages.json` : modèles `item_used` (« Tu utilises une Potion sur {pokemon}. ») et `hp_restored` (« {pokemon} récupère {amount} PV. »), **proposés, `draft`**, ajoutés à `TEMPLATE_IDS` dans le même commit.
- `BattlePlayback` : temps `HEAL` (fin d'enum) qui remonte la barre de PV du Pokémon en jeu.

Tests : `test_item_library` (catégories, `heal_amount`), `test_item_use` (PV pleins, K.O., contexte, retrait unique, Sac vide), `test_bag` (favoris, ordre d'obtention), `test_bag_query` (ordre des onglets, onglets vides absents, favoris en tête, filtres de contexte, tri), `test_battle` (étendu : soin légal en sauvage, objet retiré une seule fois par le directeur, PV bornés, l'adversaire joue ensuite, soin d'un membre hors combat), `test_battle_text`, `test_battle_playback`, `test_battle_simulation` (inchangée sans objet).

**Fait au T10 (2026-10-03)** — ce qui diffère du croquis ci-dessus :
- Fichiers : `game/items/item_data.gd` (catégories `BATTLE`, `FIELD`, `KEY` en fin d'enum ; `heal_amount`, `order`, `category_id()`, `contexts()`, `usable_in()`, `targets_pokemon()` ; constantes `CONTEXT_FIELD`, `CONTEXT_WILD_BATTLE`, `CONTEXT_TRAINER_BATTLE`), `item_library.gd` (`heal_amount` strict, `get_ids_in_data_order`), `bag.gd` (`toggle_favorite`), **nouveaux** `game/items/item_use.gd`, `item_use_result.gd`, `game/systems/menu/bag_query.gd`, `views/bag_view.gd`, `views/party_picker_view.gd`, `views/party_target_view.gd` ; `game/ui/battle/bag_entry_view.gd` (champs ajoutés, toujours à cet endroit : T11 le déplace) ; moteur : `battle_action.gd`, `battle_rules.gd`, `battle_event.gd`, `battle.gd`, `battle_beat.gd`, `battle_playback.gd`, `battle_text.gd`, `battle_views.gd` ; données : `data/items/items.json` (`"heal_amount": 20`), `data/battle/messages.json` (`item_used`, `hp_restored`, `draft`). Tests : `test_item_use`, `test_bag_query` (nouveaux) ; `test_item_library`, `test_bag`, `test_battle`, `test_battle_text`, `test_battle_playback` étendus.
- **Contextes** : les valeurs vivent dans `ItemData` (la règle d'un objet) ; `BagQuery.CONTEXT_*` les reprennent, `CONTEXT_TEAM` (= `ItemUse.CONTEXT_TEAM` = `MenuRoute.BAG_CONTEXT_TEAM`) se lit comme l'exploration pour les règles (`ItemUse.rule_context`).
- **`ItemUse`** : en plus de `check` / `apply` (menu), `check_target(item, pokemon, context)` et `restore(item, pokemon) -> int` **sans le Sac**, pour le moteur (une seule règle, le moteur ne connaît pas le Sac). Ordre des refus : `NOT_USABLE` (objet qui ne se donne pas à un Pokémon : Ball, objet clé… ; objet ou Pokémon absent), `WRONG_CONTEXT`, `NOT_IN_BAG`, `FAINTED`, `FULL_HP`. Seuls les soins (`HEAL`, `heal_amount` > 0) se donnent à un Pokémon au J6.
- **`BagQuery`** vit dans `game/systems/menu/` (§6.1) ; `BattleViews.bag_entries` en est une enveloppe (contexte combat sauvage). **Le Sac du combat ne propose encore que les Balls** (`USABLE_IN_WILD_BATTLE` gardé) : sinon UTILISER sur la Potion enverrait une Ball au moteur avant le câblage. **T12 retire ce filtre** en câblant le soin.
- **FAVORIS** : un onglet (le premier, s'il y a un favori **présent** dans le Sac), pas une catégorie : `BagView.favorites` porte les mêmes vues que `entries` ; en « pertinence », dans l'ordre de marquage ; sinon dans l'ordre du tri. Un objet favori reste aussi dans sa catégorie.
- **Tris** : nom (sans casse, naturel), quantité (la plus grande d'abord), récents (`acquired_rank`, Q-12) ; égalités dans l'ordre de la pertinence. Pertinence : combat sauvage, Balls puis soins puis le reste ; ailleurs l'**ordre des données** (`ItemData.order`, ordre de lecture des fichiers).
- **Depuis la fiche Équipe** (`CONTEXT_TEAM`) : seuls les objets qui se donnent à un Pokémon en exploration (« compatibles » = un soin, même si ce Pokémon a ses PV pleins : la raison s'affiche alors sur la carte, l'écran ne se vide pas) ; chaque vue dit si l'objet sert **sur ce Pokémon**, sinon `note` = la raison. Onglet d'ouverture : SOINS.
- **Mentions** : hors combat, un objet de combat (Ball comprise) porte « Utilisable en combat » et n'a pas d'action ; un objet clé n'a ni action ni mention.
- **Moteur** : `BattleAction.heal(id, index)` (`Kind.ITEM`, `target` ≥ 0 ; `is_heal()`), `BattleRules.allow_heal_items` (vrai pour `for_wild` **et** `for_trainer`, Q-10) ; `for_trainer(trainer, item_library = null)` : sans objets, aucun soin n'est légal. `BattleRequest.trainer_battle` ne passe **aucun** objet : contre le rival du labo, le moteur refuse le soin **et** la grille garde le SAC muet (décision n° 12). `Battle.can_use_heal_items()`, `Battle.item_context()`. Soin : aucun tirage propre ; ITEM_USED puis le tour adverse (`_foe_turn_alone`). `BattleEvent` n'a **aucun champ nouveau** (ITEM_USED réutilise `amount`, `item_id`, `item_name`, `party_index`) : `to_dict` et les journaux du J5 sont inchangés. Simulation du J5, combats et captures : inchangés (tests verts sans modification).
- **Messages** (`draft`) : `item_used` « Tu utilises une {item} sur {pokemon}. » (l'article « une » suit la convention de `ball_thrown` ; à revoir avec le premier objet masculin), `hp_restored` « {pokemon} récupère {amount} PV. » ; nouvelle marque `{amount}` (= `BattleEvent.amount`). Lecture : message, `HEAL`, message.
- **Textes d'interface provisoires** (`BagQuery`) : raisons « PV déjà au maximum », « Ce Pokémon est K.O. » (Q-11), « Il n'en reste plus », « Pas maintenant », « Sans effet » ; « Utilisable en combat » ; résultat « +20 PV — Salamèche 33/51 » ; « Ton Sac est vide. » (Q-2), depuis l'Équipe « Aucun soin dans ton Sac. » ; tris « Pertinence », « Nom », « Quantité », « Récents ».

### 3.5 Pokédex (T14)

- **Données** `data/pokedex/kanto.json` (nouveau, `PokedexLibrary`) : `{ "size": 151, "species": { "pidgey": { "height": 0.3, "weight": 1.8, "description": "…", "draft": true, "notes": [ { "id": "pidgey_paths", "text": "…", "unlock": { "seen": 1 }, "draft": true } ] } } }`. Le numéro vient de `SpeciesData.dex` (pas de doublon) ; l'espèce doit exister dans `PokemonData`. Conditions de note : `seen` (n observations), `caught` (n captures), `map` (vue sur cette carte), `flag` (drapeau d'histoire). Textes **provisoires** (Q-5, Q-6).
- `PokedexEntry.notes: Array[StringName]` (**posé au T0** : sauvegardé, doublons écartés à la lecture), `Pokedex.unlock_note(species, note_id) -> bool`, `Pokedex.has_seen_at(species, map) -> bool`.
- `PokedexNotes.refresh(pokedex, library, flags) -> Array[Array]` : débloque les notes dont la condition tient, renvoie les `[espèce, note]` nouvelles. Appelé après chaque observation, capture ou changement de drapeau. **Les notes se débloquent silencieusement avant l'activation** (règle de déblocage) ; elles apparaîtront d'un coup.
- `PokedexQuery` (statique) : `enum State { UNKNOWN, SEEN, CAUGHT }`, `enum Filter { ALL, SEEN, CAUGHT, HABITAT }` ; `slots(pokedex, data, library, filter, zone, type, text) -> Array[PokedexSlotView]` (numéros 1 à `size` ; inconnu = numéro et « ??? », **sans silhouette** ; la recherche ne porte que sur les espèces connues) ; `counts_text(pokedex, library) -> String` (« 3 vus · 2 capturés · 151 espèces ») ; `sheet(species, pokedex, data, library, zones) -> PokedexSheetView` (Aperçu ; à la capture seulement : types, taille, poids, description ; « vu N fois · capturé N fois » ; **pas de statistiques de base ni de talents** ; Habitat = zones observées, jamais une zone non découverte ; Évolution par `EvolutionReveal` ; Observations = notes débloquées).
- `PokedexUpdates.message(kind, species_name) -> Array[String]` : `NEW_SPECIES` → « Pokédex mis à jour » / « Roucool » ; `NEW_HABITAT` → « Nouvel habitat observé » / « Roucool » ; `NEW_NOTE` → « Pokédex mis à jour » / « Roucool » ; `EVOLUTION_DISCOVERED` → « Évolution découverte » / « Roucoups ». Une **capture** n'a pas de toast : la carte de capture dit déjà « Nouvelle entrée Pokédex » (après l'activation). Aucun message si le Pokédex n'est pas visible.
- **Observer dans le décor** (dossier 08 §4 et §12 Q1, défaut « oui ») : clé facultative **`"species"`** d'un Pokémon du décor (`NpcSpec.species`), validée contre `PokemonData` ; le geste **OBSERVER** l'enregistre « vu » sur la carte (Q-7).

Tests : `test_pokedex_library` (données réelles : 0 erreur, espèces connues, numéros), `test_pokedex_notes`, `test_pokedex_query` (trois états ; inconnu sans nom ni sprite ; filtres ; recherche limitée aux espèces vues ; **aucun texte « ??? » dans une liste d'habitats** ; compteur sans « / »), `test_pokedex_updates`, `test_npc_roster` (étendu : `species`).

### 3.6 Carte (T18)

- `data/world/zones.json` complété : par zone, `name`, `kind` (`town`, `route`, `place`, `sea_route` : posés au T2), `maps`, `subtitle` (connexions, « Bourg Palette — Jadielle »), `description` (`draft`), `services` ; **le rectangle (`area`) reste dans `assets/ui/map/kanto_placeholder_areas.json`** (géométrie de l'illustration, décision du T2, §3.2) (au J6 : aucun ; format `{ "id": "pokemon_center", "found_on": "<carte>" }` prêt pour le J7A).
- `MapJournal` (statique) : `discovered_zones(discovered_maps, zones) -> Dictionary[StringName, String]` (zone → date de première visite) ; `player_zone(current_map, zones)` ; `panel(zone, state, data, zones, pokedex_visible) -> ZonePanelView` (nom, sous-titre, description, **Pokémon observés** seulement si le Pokédex est visible et seulement ceux vus, **objets trouvés** seulement ceux ramassés, services seulement ceux découverts ; **aucun total, aucun « ??? »**).

Tests : `test_zone_library` (étendu : rectangles dans l'image, sous-titres), `test_map_journal` (zone non découverte : pas de panneau ; intérieur → sa ville ; Pokémon observés vides tant que le Pokédex n'est pas visible ; objets trouvés de la zone seulement).

### 3.7 Dresseur (T23)

- `data/trainer/moments.json` (`MomentLibrary`) : par type de moment (`starter`, `rival_battle`, `first_capture`, `zone_arrival`), un titre et un détail (`{species}`, `{zone}`, `{outcome}`), textes `draft`.
- `TrainerSummary.build(state, data, zones, moments, unlocks) -> TrainerView` : identité, temps de jeu, date de départ, vus · capturés (seulement si le Pokédex est visible), **8 emplacements de badges** sans nom ni apparence, grands moments (les moments enregistrés **et** la première arrivée dans chaque zone extérieure, dates et lieux, ordre chronologique, Q-14), statistiques de ce qui est déjà enregistré (temps de jeu, zones découvertes, Pokémon capturés, objets trouvés ; pas de combats gagnés : non enregistrés). `play_time_text(seconds) -> String` (« 0 h 07 », « 12 h 43 »).

Tests : `test_trainer_summary` (badges muets, pas de « 0/8 », pas de vus/capturés avant l'activation, moments dans l'ordre, lieux en noms de zone).

### 3.8 Paramètres (T27)

```gdscript
class_name GameSettings
extends RefCounted
## Réglages de l'appareil (dossier 08 §7) : valeurs par défaut, bornes, aller-retour JSON.
## Ils ne font PAS partie de la partie : fichier séparé, jamais remis à zéro par une partie.
enum TextSpeed { SLOW, NORMAL, FAST, INSTANT }
enum TextSize { NORMAL, LARGE }
var text_speed: TextSpeed = TextSpeed.NORMAL
var confirm_actions: bool = false          # Q-18
var joystick_scale: float = 1.0            # 0,8 à 1,3
var joystick_opacity: float = 1.0          # 0,3 à 1,0 (multiplie l'opacité actuelle)
var button_scale: float = 1.0              # 1,0 ou 1,2 (boutons ronds d'exploration)
var left_handed: bool = false
var haptics: bool = true
var text_size: TextSize = TextSize.NORMAL
var high_contrast: bool = false
var reduce_motion: bool = false
var reduce_flashes: bool = false
func to_dict() -> Dictionary
static func from_dict(dict: Dictionary) -> GameSettings   # valeurs hors bornes → défaut, jamais d'échec
func chars_per_second() -> float          # 25 / 45 (actuel) / 90 / INF (page entière)
func battle_speed_scale() -> float        # 1,0 ; 0,6 si reduce_motion
func menu_speed_scale() -> float          # 1,0 ; 0,5 si reduce_motion
```
```gdscript
class_name SettingsStore
extends RefCounted
## user://settings.json, écriture atomique (temporaire, relecture, renommage) avec le
## SaveFileSystem existant ; version propre (1) ; fichier illisible → défauts (mis de côté).
const DEFAULT_PATH: String = "user://settings.json"
func _init(file_system: SaveFileSystem = null, path: String = DEFAULT_PATH) -> void
func load_settings() -> GameSettings
func save_settings(settings: GameSettings) -> Error
```
```gdscript
class_name Haptics
extends RefCounted
## Porte unique des vibrations (bible §12, dossier 08 règle 11) : coupée par le réglage.
static var enabled: bool = true
static var sink: Callable = Callable()      # tests : espion
static func vibrate(duration_ms: int) -> void
```
`UiPrefs` (statique) : `text_scale`, `high_contrast`, `font(size) -> int`, `panel_bg() -> Color`, `text_muted() -> Color` ; lu par les composants du J6 et par la boîte de dialogue, le toast et le titre de zone (Q-19).

Tests : `test_game_settings` (défauts, bornes, aller-retour, champ inconnu ignoré, valeurs mal formées), `test_settings_store` (système de fichiers en mémoire : atomicité, fichier corrompu mis de côté), `test_haptics`.

---

## 4. La règle de déblocage appliquée au J6

> « Une fonctionnalité visible n'existe pas pour le joueur avant son déblocage narratif, mais les données nécessaires peuvent déjà être collectées silencieusement » (vision.md ; dossier 09 §6).

**En partie normale, avant `pokedex_activated` (posé au J7A)** :
- pas de carte POKÉDEX au tableau de bord : **cinq** cartes, pas six, et pas d'emplacement vide à sa place ;
- pas de ligne « vus · capturés » sur la carte du Dresseur ni sur l'écran Dresseur ; pas de lien « vus » / « capturés » ;
- pas de Pokémon observés dans le panneau d'une zone de la Carte ;
- pas d'onglet Habitat ni de chaîne d'évolution révélée par le Pokédex dans la fiche Équipe (« ??? ») ;
- pas de toast « Pokédex mis à jour », « Nouvel habitat observé », « Évolution découverte » ;
- `MenuNavigator.go(MenuRoute.pokedex())` est refusé (aucun lien croisé ne peut y mener) ;
- **les données continuent** : vus, capturés, lieux, dates, compteurs, notes d'Observations.

**Drapeau de débogage** : `DebugUnlocks.pokedex` (§3.2). Il agit sur `MenuUnlocks.debug_pokedex`, **jamais** sur `StoryFlags` : la sauvegarde écrite pendant une session débloquée **ne contient pas** `pokedex_activated`. Jamais lu en release ni sous GUT.

**Comment on le teste** :
- `test_menu_unlocks` : sans drapeau, `pokedex_visible()` faux et `dashboard_cards()` sans `pokedex` (5 cartes) ; avec `pokedex_activated`, 6 cartes ; avec `debug_pokedex` seul, 6 cartes **et** `flags.has_flag(POKEDEX_ACTIVATED)` reste faux.
- `test_menu_navigator` : lien vers le Pokédex refusé sans déblocage, accepté avec.
- `tests/integration/test_menu_unlock_rule.gd` (vrai `Boot`, équipe et Pokédex remplis à la main) : sans drapeau, ouvrir le menu et **parcourir tous les écrans** ; un utilitaire relève le texte de **tous les `Label` visibles** et vérifie qu'aucun ne contient « Pokédex », « vus », « capturés », « habitat » ; aucun toast Pokédex après une observation. Avec `debug_pokedex` : la carte existe, l'écran s'ouvre, et `GameState.to_dict()["flags"]` ne contient pas `pokedex_activated`.
- `test_debug_unlocks` + `test_boot` : le fichier n'est pas lu sous GUT ni en release (`DebugStart.is_allowed`).

---

## 5. Données et sauvegarde

### 5.1 Version 2 du format (T0, validée seule sur le S24 au T1)

**Pourquoi une version 2**, alors qu'ajouter un champ « n'exige pas de nouvelle version » (`save_system.gd`) : (1) la forme du Sac change ; (2) surtout, **un ancien APK du J5 qui lirait une sauvegarde du J6 ignorerait les nouveaux champs puis les effacerait au premier autosave** (favoris, notes). Avec `VERSION = 2`, un build du J5 refuse le fichier et ne l'écrase jamais (décision de Kevin du 2026-10-02, déjà codée : nouvelle partie **sans autosave**, fichier intact). **Une seule version pour tout le J6** : tous les champs sont posés au T0 avec leurs valeurs par défaut, même si leur écran arrive plus tard.

| Champ | Forme v2 | Valeur pour une partie v1 | Arrive dans l'écran |
|---|---|---|---|
| `bag` | `{ "items": { "poke_ball": 4 }, "favorites": ["potion"], "acquired": { "poke_ball": 1, "potion": 2 } }` | **migration** : `{ "items": <ancien dict>, "favorites": [], "acquired": <ordre alphabétique des quantités valides> }` (`Bag.upgrade_flat`) | 6B |
| `party[i].favorite`, `storage[i].favorite` | booléen | `false` (posé par la migration) | 6A (et Stockage au J7A) |
| `pokedex.entries[s].notes` | liste d'identifiants de notes débloquées | `[]` (posé par la migration) | 6C |
| `pokedex.entries[s].times_seen` | entier (inchangé) | **pas de migration** : la Q-8 est déjà corrigée **au chargement**, pour toute version (voir ci-dessous) | 6C |

**Fait au T0.** `SaveSystem.upgrade(content, target = VERSION)`, cas `1:` (`_upgrade_1_to_2`) : Sac plat → forme v2 par `Bag.upgrade_flat` (une seule règle, partagée avec le chargeur) ; `favorite: false` sur chaque Pokémon de `party` et `storage` ; `notes: []` sur chaque entrée du Pokédex ; un champ absent ou mal formé est laissé aux chargeurs tolérants (rien n'est inventé, rien ne plante). Les chargeurs restent **tolérants** : `Bag.load_dict` accepte aussi l'ancienne forme plate (même `upgrade_flat`), `Pokemon.from_dict` lit `favorite` (faux par défaut ou si mal formé), `PokedexEntry.from_dict` lit `notes` (vide par défaut, doublons écartés).

**Q-8 et migration — une seule règle** : le lot de dettes du J5 (`a6d9254`, fusionné `3ed11f8`) a déjà rendu la capture « première observation » (`PokedexEntry.capture` → `see` si `times_seen < 1`) et corrige les anciennes entrées **au chargement** : `PokedexEntry.from_dict` et `Pokedex.from_dict` appellent `ensure_seen()` (au moins 1 observation ; sans première observation datée, reprend la carte et la date de la première capture ; ajoute la carte à `seen_maps`). Cette correction vaut pour une v1 comme pour une v2. La migration v1 → v2 **ne touche donc pas** `times_seen` : le dictionnaire migré garde `0`, `GameState.load_dict` le lit à 1, et la première réécriture l'écrit à 1 (test `test_the_real_v1_save_is_migrated_to_v2_on_read`). Deux corrections parallèles auraient pu diverger (date, carte).

**Simuler une ancienne build** : `SaveSystem.version` (membre, `VERSION` par défaut) est la version écrite et acceptée ; les tests la mettent à 1 pour reproduire ce que fait un APK du J5 (même code de refus : `ERR_INVALID_DATA`, fichier intact, `Boot` sans autosave pour la session).

**Pas dans la sauvegarde** : l'onglet ouvert du Sac et le tri (mémoire de session) ; le drapeau de débogage ; l'objectif (déduit des drapeaux et des données) ; les zones et services (déduits des cartes découvertes) ; les évolutions découvertes (déduites des espèces vues) ; **les réglages** (fichier à part, §5.3).

**Fixture v1 réelle** : `tests/fixtures/save/v1_after_capture.json` = copie **telle quelle** de `build/qa/jalon05d_t16/save_passage1.json` (sauvegarde du S24 de Kevin, QA T16 passage 1, après les captures de Roucool à Bourg Palette et de Rattata sur la Route 1 ; 3 Pokémon, Sac `poke_ball: 3, potion: 1`, 4 espèces au Pokédex dont le starter « vu 0 fois », 3 grands moments, stockage vide). Les sauvegardes du S3 (`build/qa/jalon05_s3/`) précèdent la capture : non retenues.

**Tests (T0, faits, 19 nouveaux)** : `test_save_system` (v1 réelle migrée à la lecture : Sac v2, `favorite`, `notes`, `times_seen` non touché ; chargée : équipe, PV, XP, Sac, Pokédex, moments, temps de jeu, et **tous les autres champs réécrits à l'identique** ; réécrite en v2 et relue identique ; aller-retour v2 avec favoris (Sac, équipe, stockage) et notes ; v3 refusée, fichier intact ; une v2 lue par un `SaveSystem` en version 1 → refusée, intacte, pas mise de côté ; `upgrade` 1 → 2 laisse une forme v2 et les champs mal formés tranquilles), `test_bag` (forme v2, forme plate lue, `upgrade_flat`, rang de dernière obtention, favoris gardés à 0, champs informatifs mal formés ignorés, `items` non objet = erreur), `test_pokemon` (`favorite` : aller-retour, défaut, évolution), `test_pokedex` (`notes`), `test_save_boot` (vrai `Boot` : la v1 réelle reprend à l'identique — carte, case, orientation, équipe, Sac, Pokédex, temps de jeu — puis est réécrite en v2 ; une v2 avec un `SaveSystem` en version 1 → nouvelle partie, aucune écriture de la session, fichier intact). `test_game_state` n'avait rien à changer (mêmes clés de premier niveau).

#### 5.1.1 Protocole S24 du T1 (migration validée seule)

But : la **vraie partie de Kevin** (celle de la 5F, sur le S24, format v1) passe en v2 sans rien perdre, et un APK du J5 ne l'écrase jamais. Tout se fait depuis le Mac, S24 branché (ou débogage sans fil), APK **debug** (sinon `run-as` est refusé). Dossier des preuves : `build/qa/jalon06_t1/`. Variables : `ADB=~/Library/Android/sdk/platform-tools/adb`, `S=$(tools/s24_serial.sh)`, `PKG=dev.kevin.kanto2026`.

**Règles de sécurité** : jamais `adb uninstall`, jamais « Effacer les données » (la partie disparaîtrait) ; toujours `install -r` (et `-r -d` pour revenir à l'APK du J5) ; les deux APK sont signés par la même clé debug du Mac (même machine), sinon `install -r` échoue **sans** toucher aux données : s'arrêter et prévenir.

0. **APK du J5, à part, sans toucher au dépôt principal** (une fois, avant tout) :
   ```bash
   mkdir -p ~/dev/kanto-2026-j5 && git -C ~/dev/kanto-2026 archive d8e8f2b | tar -x -C ~/dev/kanto-2026-j5
   cd ~/dev/kanto-2026-j5 && godot --headless --path . --import >/dev/null 2>&1; \
     godot --headless --path . --export-debug "Android" ~/dev/kanto-2026/build/kanto2026-j5-debug.apk
   ```
   (`git archive` ne fait que lire les objets : ni branche, ni copie de travail, ni métadonnée de worktree ; `export_presets.cfg` est versionné, pas de build Gradle.) Dossier **hors** du projet (un `project.godot` imbriqué sous `build/` n'a rien à y faire). Vérifier que `SaveSystem.VERSION` y vaut 1 : `grep "VERSION: int" ~/dev/kanto-2026-j5/game/systems/save/save_system.gd`.
1. **Sauvegarde de départ** (APK du J5 encore installé, application arrêtée) : `$ADB -s $S shell am force-stop $PKG` puis `$ADB -s $S exec-out run-as $PKG cat files/save.json > build/qa/jalon06_t1/save_v1_kevin.json`. Contrôler : `"version": 1`, la carte, la case, l'équipe (Kevin la lit à voix haute : espèces, Nv., PV), le Sac, le temps de jeu. **Cette copie est la sauvegarde de secours** (restauration : application arrêtée, `$ADB -s $S shell "run-as $PKG sh -c 'cat > files/save.json'" < build/qa/jalon06_t1/save_v1_kevin.json`). Capture d'écran de l'écran actuel du jeu si possible (référence visuelle de la reprise).
2. **Installer le build du T0** : `tools/deploy_s24.sh` (construit, `install -r`, lance, capture, journal). Ne pas bouger avant la vérification.
3. **Reprise exacte** : même carte, même case, même orientation ; ouvrir rien d'autre que le jeu ; comparer à l'étape 1 : équipe (ordre, Nv., PV, PP via un combat si besoin), Sac (quantités, en combat sauvage : Poké Balls), temps de jeu qui reprend (pas remis à 0). Journal : « Sauvegarde chargée : … », **aucune** ligne `SaveSystem` ni `Boot : sauvegarde chargée en partie seulement`, aucun `ERROR`.
4. **Écrite en v2** : Accueil (la sauvegarde est écrite au passage en arrière-plan), puis `$ADB -s $S exec-out run-as $PKG cat files/save.json > build/qa/jalon06_t1/save_v2_apres_t0.json`. Attendu : `"version": 2` ; `bag` = `{ "items": <mêmes quantités>, "favorites": [], "acquired": {…} }` ; `"favorite": false` sur chaque Pokémon ; `"notes": []` sur chaque entrée du Pokédex ; le starter à `times_seen` ≥ 1 (si la partie de la 5F datait d'avant le lot de dettes, il passe de 0 à 1 : attendu) ; **tout le reste identique** à l'étape 1, sauf `play_time` (plus grand) et la position si Kevin a bougé. Comparaison au Mac : `diff <(jq -S 'del(.version,.bag,.play_time)|.party|=map(del(.favorite))|.pokedex.entries|=map_values(del(.notes,.times_seen))' build/qa/jalon06_t1/save_v1_kevin.json) <(jq -S '…même filtre…' build/qa/jalon06_t1/save_v2_apres_t0.json)` → vide. Aucun fichier `save.json.rejected` ni `.corrupt` (`$ADB -s $S shell run-as $PKG ls files`).
5. **Quitter et relancer** (application tuée depuis les applications récentes) : reprise identique à l'étape 3, journal propre.
6. **Retour à l'APK du J5** : `$ADB -s $S install -r -d build/kanto2026-j5-debug.apk`, `logcat -c`, lancer. Attendu : **partie neuve** (chambre), journal `SaveSystem : sauvegarde d'une version plus récente (2 > 1)` puis `Boot : … Nouvelle partie SANS sauvegarde automatique`. Jouer 1 à 2 minutes (sortir de la chambre, changer de carte, passer en arrière-plan) : rien ne doit être écrit. Puis `run-as … cat files/save.json` → **identique octet pour octet** à `save_v2_apres_t0.json` (`cmp`) ; `ls files` : ni `.rejected`, ni `.corrupt`.
7. **Retour au J6** : `tools/deploy_s24.sh --no-build` (réinstalle le build du T0 avec `install -r`). Attendu : la partie de Kevin reprend exactement comme à l'étape 5.
8. **Rapport** : chaque étape conforme ou non, les 3 fichiers JSON et les journaux (`logcat_etape_N.txt`) dans `build/qa/jalon06_t1/`, captures, nombre de sauvegardes automatiques vues, et la validation de Kevin (« sa partie est là »). En cas d'écart à l'étape 3 ou 4 : **ne plus lancer le J6**, restaurer la copie de l'étape 1, rapporter.

### 5.2 Données nouvelles (`data/`)

```
data/story/objectives.json      objectifs du tableau de bord (T2), textes draft (Q-4)
data/world/zones.json           zones : noms et cartes (T2) ; Carte (T18)
data/items/items.json           + "heal_amount": 20 sur la Potion (T10)
data/battle/messages.json       + item_used, hp_restored (T10, draft)
data/pokedex/kanto.json         taille, poids, description, notes (T14, draft, Q-5, Q-6)
data/npcs/pallet_town.json      + "species" sur les Pokémon observables (T16, Q-7)
data/trainer/moments.json       titres des grands moments (T23, draft)
```
Vérifier dans l'APK (`unzip -l`) : `data/story/`, `data/world/`, `data/pokedex/`, `data/trainer/` (règle des jalons précédents).

### 5.3 Réglages : un fichier à part

`user://settings.json` (`SettingsStore`, §3.8), version 1, écriture atomique. **Séparé de la partie** : un réglage de l'appareil ne doit pas être perdu si la sauvegarde est mise de côté, ni être restauré avec une vieille partie. Écrit à chaque changement de réglage (pas d'autosave à attendre). Lu au démarrage par `Boot` ; sous GUT et dans les outils, rien n'est lu ni écrit (même garde que la sauvegarde). Un départ de débogage n'empêche pas les réglages.

### 5.4 Moments d'autosave ajoutés

- **Fermeture du menu** si l'état de la partie a changé (équipe réordonnée, favori, objet utilisé) : `request_autosave("menu")`.
- **« Sauvegarder maintenant »** : écriture immédiate (le menu ouvert est un état stable), toast « Partie sauvegardée » + heure (`ui-reference.md`, Sauvegarde).
- **Passage en arrière-plan menu ouvert** : écriture immédiate comme aujourd'hui. Pour cela, **`Boot.is_stable()` reste vrai menu ouvert** : chaque action du menu est appliquée d'un bloc à `GameState`, il n'y a jamais d'état intermédiaire.

---

## 6. Architecture

### 6.1 Arbre des scènes

```
game/boot.tscn
Boot (Node, process_mode ALWAYS)             temps de jeu et autosave continuent menu ouvert (Q-21)
├─ World (Node2D, PAUSABLE)                  la carte et le joueur gèlent menu ouvert
├─ BattleStage, ExplorationHud, BattleHud, StarterSheet, DialogueBox      PAUSABLE
├─ DialogueRunner, InteractionController, CutsceneDirector, StarterChoice PAUSABLE
├─ BattleDirector, AmbientWatcher, EncounterDirector                     PAUSABLE
├─ MenuDirector (Node, ALWAYS)    game/systems/menu/menu_director.gd     6.0
├─ TrainerMenu (instance, ALWAYS) game/ui/menu/trainer_menu.tscn          6.0, calque LAYER_MENU (20)
├─ ScreenFade, ComingSoonScreen                                           PAUSABLE
ExplorationHud : + MenuButton (bouton rond, en haut à droite)            6.0
Autoloads : SceneRouter, GameState (inchangés ; aucun nouvel autoload)
```
**Aucun nouvel autoload** : `Boot` reste la racine de composition et tient `SaveSystem`, `SettingsStore`, `ZoneLibrary`, `ObjectiveLibrary`, `PokedexLibrary`, `MomentLibrary`, comme il tient déjà les bibliothèques de données. `Boot` passe en `ALWAYS` ; **tous ses enfants actuels sont posés `PAUSABLE` explicitement** dans `boot.tscn` (sinon ils hériteraient d'`ALWAYS`) : un test d'invariant le vérifie.

```
game/ui/menu/
  trainer_menu.tscn/.gd        TrainerMenu : fond (battle_backdrop.gdshader), en-tête (×, nom de zone),
                               hôte des écrans (instanciés à la première visite), Toast propre au menu
  menu_screen.gd               MenuScreen (base) : glissement + fondu, signaux route_requested, back_requested
  dashboard/                   DashboardScreen, TrainerCardPanel, LeadPokemonCard, MenuCard
  team/                        TeamScreen, TeamSlotCard, PokemonShowcase, PokemonSheet, StatGauge
  bag/ (+ composants déplacés) BagScreen, PartyPicker, UseResultBar, BagCategoryTab, BagItemCard, BagEntryView
  pokedex/                     PokedexScreen, PokedexSlot, PokedexSheet
  map/                         MapScreen, ZonePanel
  trainer/                     TrainerScreen, BadgeSlot, MomentRow
  settings/                    SettingsScreen, SettingToggle, SettingSlider, SettingChoice, ChoiceCards (Q-18)
game/systems/menu/             MenuRoute, MenuNavigator, MenuUnlocks, MenuDirector, ObjectiveLibrary,
                               DashboardViews, TeamViews, BagQuery, PokedexQuery, MapJournal, TrainerSummary
game/systems/settings/         GameSettings, SettingsStore, Haptics, UiPrefs
game/world/zones/              ZoneLibrary, ZoneData
game/pokemon/                  + EvolutionReveal, PokedexLibrary, PokedexNotes, PokedexUpdates
game/items/                    + ItemUse, ItemUseResult
```

### 6.2 Ouverture, pause, fermeture (dossier 08 règle 6)

```gdscript
class_name MenuDirector
extends Node
## Ouvre et ferme le Menu Dresseur, met le monde en pause, nourrit les écrans de vues et
## applique leurs actions à l'état de la partie (comme BattleDirector pour le combat).
signal menu_opened
## [param changed] : l'état de la partie a changé pendant l'ouverture (autosave).
signal menu_closed(changed: bool)
signal save_requested                        # « Sauvegarder maintenant » (6F)
signal settings_changed(settings: GameSettings)   # 6F
## Figé au T2 (§6.6) : MenuDirector ne connaît PAS TrainerMenu ; Boot relie les deux.
signal dashboard_shown(view: DashboardView)  # Boot → TrainerMenu.show_dashboard
signal placeholder_shown(screen: StringName) # Boot → TrainerMenu.show_placeholder (écran pas construit)
func setup(state: Node, data: PokemonData, zones: ZoneLibrary, objectives: ObjectiveLibrary,
		unlocks: MenuUnlocks, can_open: Callable) -> void
func open(route: MenuRoute = null) -> bool   # faux si can_open() est faux ou déjà ouvert
func close() -> void
func go(route: MenuRoute) -> bool            # TrainerMenu.route_requested
## Retour Android, Échap : un niveau en arrière ; depuis le tableau de bord, ferme. Vrai si
## le menu était ouvert (l'événement est alors consommé).
func handle_back() -> bool
func is_open() -> bool
func get_navigator() -> MenuNavigator
```
(Au T2, `menu: TrainerMenu` et `items` sont retirés de `setup` : le directeur pilote la pile, la pause et l'état, l'écran est relié par `Boot` ; ainsi T4 se teste sans l'interface de T3, §6.6. `items` reviendra au T12 avec le Sac.)

- **Ouvrir** : `MenuButton` (signal `menu_requested` de l'`ExplorationHud`) ou l'action `menu` (Échap, M sur Mac). Garde `can_open` fournie par `Boot` : `is_stable()` **et** ni écran « À venir », ni titre de zone en train d'entrer (il est caché à l'ouverture). Puis : contrôles cachés (`set_controls_visible(false)` relâche déjà joystick et boutons), `get_tree().paused = true`, fond de 0 à 1 et tableau de bord en `MENU_OPEN` (0,25 s), vibration « presque imperceptible » (`HAPTIC_MENU_MS`, bible §12).
- **Le monde gèle tel quel**, même au milieu d'un pas (il reprend à la fermeture). Aucun nœud du monde n'utilise de Tween non lié ni de minuteur `process_always` hors combat (vérifié : seul `HapticPattern` en crée un, en combat).
- **Fermer** : ×, retour depuis le tableau de bord, action `menu`. `paused = false` et contrôles rendus **tout de suite** ; le menu (en `ALWAYS`) joue son fondu inverse `MENU_CLOSE` (0,2 s) par-dessus le monde qui reprend (défaut du T2 : rien n'attend l'animation, le directeur ne connaît pas l'écran) ; autosave si `changed`. Une réouverture pendant le fondu le coupe (`TrainerMenu.open_animated`).
- **Retour Android** : aujourd'hui, `application/config/quit_on_go_back` vaut vrai par défaut et `Boot` sauvegarde sur `NOTIFICATION_WM_GO_BACK_REQUEST` avant que l'application ne quitte. Le J6 passe ce réglage à **faux** ; `Boot` reçoit le retour : menu ouvert → `MenuDirector.handle_back()` ; en exploration (contrôles visibles) → sauvegarde immédiate puis **ouverture du Menu Dresseur** ; pendant un dialogue, une scène, un combat ou une transition → ignoré. **Le jeu ne quitte jamais sur le retour** (décision de Kevin, Q-3) : la fermeture reste celle du système (accueil, applications récentes), déjà couverte par la sauvegarde au passage en arrière-plan. **À vérifier tôt sur le S24** (geste retour d'Android 14).

### 6.3 Liens croisés (dossier 08 §8)

| Depuis | Toucher | `MenuNavigator.go(...)` | Sous-jalon |
|---|---|---|---|
| Tableau de bord | Pokémon de tête | `MenuRoute.team(0)` | 6A (6.0 : écran provisoire) |
| 6A Équipe | UTILISER UN OBJET | `MenuRoute.bag(CONTEXT_TEAM, index)` : SOINS, objets compatibles | 6B |
| 6B Sac | UTILISER | choix du Pokémon **dans l'écran du Sac** (pas un autre écran) | 6B |
| 6C Pokédex | une zone de l'onglet Habitat | `MenuRoute.map(zone)` | 6D (6C : écran provisoire) |
| 6D Carte | un Pokémon observé | `MenuRoute.pokedex(ALL, species)` | 6D |
| 6E Dresseur | « vus » / « capturés » | `MenuRoute.pokedex(SEEN / CAUGHT)` | 6E |
| 6E Dresseur | un badge obtenu | détail dans l'écran (aucun badge au J6) | 6E |
| 6E Dresseur | « premier Pokémon » | `team(index)` s'il est dans l'équipe, sinon `pokedex(ALL, species)` si visible, sinon rien | 6E |

Un écran pas encore construit, dans les builds de développement du J6, ouvre l'écran provisoire « ÉQUIPE — À venir » (`ComingSoonScreen`) : jamais dans une version fusionnée (tous les écrans existent à la fin du J6).

### 6.4 Signaux et flux

```
6.0
ExplorationHud.menu_requested | action « menu » ─► MenuDirector.open ─► can_open (Boot.is_stable)
   ─► tree.paused ─► TrainerMenu.open_animated ─► DashboardScreen.show_dashboard(DashboardViews.build)
DashboardScreen.card_chosen(screen) ─► MenuNavigator.go ─► TrainerMenu.show_screen
× | retour | « menu » ─► MenuNavigator.back / close ─► menu_closed(changed) ─► Boot : autosave, contrôles
NOTIFICATION_WM_GO_BACK_REQUEST ─► Boot ─► MenuDirector.handle_back | sauvegarde + MenuDirector.open (Q-3 : jamais quit)
6A
TeamScreen.member_moved(from, to) ─► Party.swap ─► TeamScreen.show_team(TeamViews.build) · changed
TeamScreen.favorite_toggled(i) ─► Pokemon.favorite = not favorite ─► show_team · changed
6B
BagScreen.use_requested(id) ─► BagScreen.show_targets(PartyPickerView)
BagScreen.target_chosen(id, i) ─► ItemUse.apply ─► BagScreen.show_result(texte, peut_recommencer) · changed
Combat : BattleBagPanel.item_chosen(potion) ─► PartyPicker ─► Bag.remove ─► Battle.submit(heal) ─► ITEM_USED
6C
Player OBSERVER (species) ─► GameState.record_seen ─► PokedexNotes.refresh ─► PokedexUpdates (si visible) ─► toast
EncounterDirector (vu) ─► idem, toast différé à la fin de la rencontre
6F
SettingsScreen.setting_changed ─► GameSettings ─► SettingsStore.save ─► Boot._apply_settings :
   DialogueRunner.chars_per_second · BattleDirector.speed_scale · BattleStage.reduce_flashes ·
   ExplorationHud (joystick, boutons, gaucher) · Haptics.enabled · UiPrefs
```
`MenuNavigator`, `ItemUse`, `BagQuery`, `PokedexQuery`, `MapJournal`, `TrainerSummary`, `GameSettings` ne connaissent aucun nœud. Les écrans de `game/ui/menu/` ne connaissent ni `GameState`, ni `Pokemon`, ni les données : ils reçoivent des vues et émettent des signaux. `MenuDirector` reçoit tout par `setup`.

### 6.5 Interfaces des écrans (contrat entre ui-mobile et constructeur-monde)

```gdscript
class_name MenuScreen extends Control
signal route_requested(route: MenuRoute)     # lien croisé
signal back_requested
var speed_scale: float = 1.0
func enter() -> void                          # coroutine : glissement + fondu (ANIM_PANEL)
func leave() -> void

class_name DashboardScreen extends MenuScreen
signal card_chosen(screen: StringName)
signal lead_chosen
func show_dashboard(view: DashboardView) -> void

class_name TeamScreen extends MenuScreen
signal member_selected(index: int)
signal member_moved(from: int, to: int)       # glisser-déposer OU mode DÉPLACER
signal favorite_toggled(index: int)
signal use_item_requested(index: int)
func show_team(view: TeamView, selected: int) -> void

class_name BagScreen extends MenuScreen
signal category_opened(category: StringName)
signal item_previewed(item_id: StringName)
signal favorite_toggled(item_id: StringName)  # appui long sur une carte
signal sort_changed(sort: int)
signal use_requested(item_id: StringName)
signal target_chosen(item_id: StringName, index: int)
signal repeat_requested                        # UTILISER À NOUVEAU
func show_bag(view: BagView) -> void
func show_targets(view: PartyPickerView) -> void
func show_result(text: String, can_repeat: bool) -> void

class_name PokedexScreen extends MenuScreen
signal filter_changed(filter: int, zone: StringName, type: StringName, text: String)
signal species_opened(species: StringName)
func show_grid(view: PokedexGridView) -> void
func show_sheet(view: PokedexSheetView) -> void

class_name MapScreen extends MenuScreen
signal zone_touched(zone: StringName)
func show_map(view: MapView) -> void          # illustration, zones découvertes, portrait du joueur
func show_zone(view: ZonePanelView) -> void   # panneau latéral, sans changer d'écran

class_name TrainerScreen extends MenuScreen
func show_trainer(view: TrainerView) -> void

class_name SettingsScreen extends MenuScreen
signal setting_changed(key: StringName, value: Variant)
signal save_now_requested
func show_settings(view: SettingsView) -> void
func show_save_result(text: String) -> void
```

### 6.6 Contrat du 6.0 et partage T3 ∥ T4 (figé au T2)

**Vues figées** (T2, `game/systems/menu/`, ne changent plus de nom ni de sens ; on peut seulement y **ajouter** des champs, par l'architecte) : `MenuRoute` (écrans, paramètres, `for_screen`), `DashboardView` (`zone_name`, `player_name`, `player_title`, `play_time_text`, `dex_text`, `badges_text`, `lead`, `cards`, `objective_text` ; **texte vide = élément absent**, `lead` null = pas de carte), `MenuCardView` (`screen`, `title`, `caption`), `TeamMemberView` (`party_index`, `species_id`, `display_name`, `gender` en `BattleCardView.Gender`, `level`, `hp`, `max_hp`, `status_text`, `favorite`), `DashboardViews.build(state, data, zones, objectives, unlocks)`. T3 fabrique ces vues à la main ; T4 les construit pour de vrai.

**`TrainerMenu`** (T3, `game/ui/menu/trainer_menu.tscn/.gd`) — interface publique figée :
```gdscript
class_name TrainerMenu extends CanvasLayer     # layer = UiTokens.LAYER_MENU (20), process_mode ALWAYS
signal route_requested(route: MenuRoute)       # carte touchée : MenuRoute.for_screen(card.screen) ;
                                               # Pokémon de tête : MenuRoute.team(0) ; liens croisés (6A+)
signal back_requested                          # retour depuis un écran (pas depuis le tableau de bord)
signal close_requested                         # × (un seul signal par toucher)
var speed_scale: float = 1.0                   # 0 : animations instantanées (tests)
func open_animated() -> void                   # coroutine : fond 0 → 1 puis tableau de bord (MENU_OPEN),
                                               # vibration HAPTIC_MENU_MS ; coupe un fondu de fermeture en cours
func close_animated() -> void                  # coroutine : MENU_CLOSE, invisible à la fin
func show_dashboard(view: DashboardView) -> void   # en-tête (× + zone_name) compris
func show_placeholder(screen: StringName) -> void  # « ÉQUIPE — À venir » dans l'hôte d'écrans
func is_open() -> bool                         # vrai d'open_animated au début de close_animated
```
**`ExplorationHud`** (T3) : `signal menu_requested` (bouton Menu rond en haut à droite, Q-1, visible avec les contrôles).

**Câblage** (T4, dans `Boot`, une fois T3 fusionné) : `ExplorationHud.menu_requested` et l'action `menu` → `MenuDirector.open` ; `TrainerMenu.route_requested` → `MenuDirector.go` ; `back_requested` → `handle_back` ; `close_requested` → `close` ; `MenuDirector.menu_opened` → `TrainerMenu.open_animated` ; `menu_closed` → `close_animated` ; `dashboard_shown` → `show_dashboard` ; `placeholder_shown` → `show_placeholder`. Avant la fusion, T4 teste `MenuDirector` directement (sans écran) ; T3 teste `TrainerMenu` avec des vues fabriquées.

| Fichiers | T3 (ui-mobile) | T4 (constructeur-monde) |
|---|---|---|
| `game/ui/menu/**` (TrainerMenu, MenuScreen, `dashboard/` : DashboardScreen, TrainerCardPanel, LeadPokemonCard, MenuCard) | **oui** | lecture |
| `game/ui/hud/exploration_hud.gd/.tscn` (MenuButton, `menu_requested`) | **oui** | lecture |
| `game/ui/theme/ui_tokens.gd`, `ui_theme.tres`, `tools/build_ui_theme.gd` (`MENU_*`, `LAYER_MENU`, `HAPTIC_MENU_MS`) | **oui** | lecture |
| `assets/ui/icons/menu/**` (icônes des cartes), `tools/capture_menu.gd` | **oui** | — |
| `tests/integration/test_trainer_menu.gd`, `test_dashboard_screen.gd`, `test_exploration_hud.gd`, `test_ui_theme.gd` | **oui** | — |
| `game/boot.gd`, `game/boot.tscn`, `project.godot` (`quit_on_go_back`), `game/autoload/**`, `game/systems/save/**` | — | **oui** |
| `game/systems/menu/menu_director.gd` (nouveau) | — | **oui** |
| `tests/integration/test_menu_open.gd`, `test_menu_unlock_rule.gd`, `test_boot.gd`, `test_save_boot.gd`, `test_debug_start_boot.gd` | — | **oui** |
| Fondations du T2 (`game/systems/menu/` hors `menu_director.gd`, `views/`, `game/world/zones/`, `debug_unlocks.gd`, `data/story/`, `data/world/`) | lecture | lecture (un manque → l'architecte) |
| `docs/tech/etat-projet.md` | sa ligne dans « Point de reprise » | sa ligne ; l'orchestrateur fusionne |

`test_menu_unlock_rule.gd` (§4) parcourt de vrais écrans : il se termine **après** la fusion de T3, dans T4.

### 6.7 Contrat du 6A et partage T7 ∥ T8 (figé au T6)

**Vues figées** (T6, `game/systems/menu/views/`, même règle qu'au §6.6 : on peut seulement **ajouter** des champs, par l'architecte ; **texte vide = élément absent**) :
- `TeamView` : `members: Array[TeamMemberView]`, `sheets: Array[PokemonSheetView]` (même ordre, **une fiche par membre**), `size()`, `sheet_at(i)`, `SLOT_COUNT` (6).
- `TeamMemberView` (inchangée depuis le T2) : `party_index`, `species_id` (sprite : `BattleStage.sprite_path(species_id, false)`), `display_name`, `gender`, `level`, `hp`, `max_hp`, `status_text` (« K.O. » ou ""), `favorite`.
- `PokemonSheetView` : `member`, `species_name`, `type_ids` / `type_names` (TypeBadge), `exp_fraction` (ExpBar), `exp_text` (« 320 / 560 XP »), `exp_remaining_text` (« 240 XP avant le niveau suivant ») — les deux vides au niveau 100 —, `stats: Array[StatView]`, `moves: Array[BattleMoveView]` (MoveCard, MoveDetailSheet), `history: HistoryView`, `evolution: Array[EvolutionStageView]` et `evolution_text` (l'écran écrit « Évolution : » devant ; vide = pas de section).
- `StatView` : `stat_id`, `name`, `value`, `ratio` (0..1, jauge).
- `HistoryView` : `note`, `place_label`, `place`, `met_level` (0 = absent), `trainer`, `date_text`, `is_empty()` (alors afficher `TeamViews.HISTORY_UNKNOWN`). Libellés de l'écran (« Niveau », « Dresseur d'origine »…) : à T7 (règle 4).
- `EvolutionStageView` : `step` (colonne : « → » entre colonnes, « / » entre branches), `species_id` (&"" si inconnu), `name` (« ??? » si inconnu), `known`, `current`. **Jamais de niveau, de silhouette ni d'image d'un stade inconnu** (Q-9).
- `TeamViews.build(party, data, zones, pokedex, unlocks) -> TeamView`, `TeamViews.selection_after_swap(selected, a, b)`, `TeamViews.clamp_selection(selected, size)`.

**`TeamScreen`** (T7, `game/ui/menu/team/team_screen.gd/.tscn`) : interface du §6.5, précisée :
```gdscript
class_name TeamScreen extends MenuScreen
signal member_selected(index: int)            # informatif : l'écran change de fiche seul
signal member_moved(from: int, to: int)       # glisser A sur B, ou DÉPLACER A puis B ; jamais
                                              # vers un emplacement vide, jamais from == to
signal favorite_toggled(index: int)
signal use_item_requested(index: int)
func show_team(view: TeamView, selected: int) -> void
```
`show_team` rappelé **pendant** que l'Équipe est affichée (après un échange ou un favori) met la vue à jour **sans** rejouer l'entrée, en gardant l'onglet ouvert ; `selected` est déjà corrigé par le directeur. L'animation d'échange est jouée par l'écran au moment du geste (il n'attend pas la vue).

**`TrainerMenu`** (T7 ajoute ; le reste du §6.6 est inchangé) :
```gdscript
signal team_member_selected(index: int)       # relais de TeamScreen
signal team_member_moved(from: int, to: int)
signal team_favorite_toggled(index: int)
func show_team(view: TeamView, selected: int) -> void   # TeamScreen dans l'hôte d'écrans
                                              # (instancié à la première visite, puis gardé)
```
UTILISER UN OBJET → `route_requested(MenuRoute.bag(MenuRoute.BAG_CONTEXT_TEAM, index))` émis par `TrainerMenu` lui-même (lien croisé ; « SAC — À venir » jusqu'au 6B). Retour depuis l'Équipe → `back_requested` (comme les autres écrans).

**`MenuDirector`** (T8 ajoute) :
```gdscript
signal team_shown(view: TeamView, selected: int)   # Boot → TrainerMenu.show_team
func move_member(from: int, to: int) -> bool  # Party.swap ; vrai → mark_changed, sélection
                                              # = selection_after_swap, team_shown réémis
func toggle_favorite(index: int) -> bool      # inverse Pokemon.favorite ; mark_changed ; team_shown
func select_member(index: int) -> void        # garde la sélection (params « index » de la route)
```
`_on_route_shown` : `MenuRoute.TEAM` → `team_shown(TeamViews.build(state.party, data, zones, state.pokedex, unlocks), clamp_selection(params.index))` au lieu de l'écran provisoire. Rien d'autre ne change (pile, pause, autosave à la fermeture si `changed`).

**Câblage** (T8, `Boot`, après la fusion de T7) : `TrainerMenu.team_member_moved` → `move_member` ; `team_favorite_toggled` → `toggle_favorite` ; `team_member_selected` → `select_member` ; `MenuDirector.team_shown` → `TrainerMenu.show_team`. Avant la fusion, T8 teste `MenuDirector` avec `tests/helpers/fake_trainer_menu.gd` étendu (mêmes signaux et `show_team`) ; T7 teste `TeamScreen` et `TrainerMenu` avec des vues fabriquées à la main **ou** construites par `TeamViews.build` sur une équipe de test (les deux sont permis : `TeamViews` est pur).

| Fichiers | T7 (ui-mobile) | T8 (constructeur-monde) |
|---|---|---|
| `game/ui/menu/team/**` (TeamScreen, TeamSlotCard, PokemonShowcase, PokemonSheet, StatGauge) | **oui** | lecture |
| `game/ui/menu/trainer_menu.gd/.tscn` (`show_team`, signaux `team_*`, relais UTILISER UN OBJET) | **oui** | lecture |
| `game/ui/theme/ui_tokens.gd`, `ui_theme.tres`, `tools/build_ui_theme.gd` (`TEAM_*`) | **oui** | lecture |
| `game/ui/battle/**`, `game/ui/components/**` (MoveCard, MoveDetailSheet, TypeBadge, HpBar, ExpBar réutilisés ; un ajout éventuel) | **oui** | — |
| `tools/capture_menu.gd` (scénarios `team`, `team_sheet_moves`, `team_history`, `team_move_mode`) | **oui** | lecture (captures du T8 : son propre scénario ou `tools/capture_play.gd`) |
| `tests/integration/test_team_screen.gd`, `test_trainer_menu.gd` (étendu) | **oui** | — |
| `game/systems/menu/menu_director.gd`, `game/boot.gd`, `game/boot.tscn` | — | **oui** |
| `tests/helpers/fake_trainer_menu.gd` (étendu), `tests/integration/test_menu_team.gd`, `test_menu_open.gd`, `test_menu_unlock_rule.gd`, `test_boot.gd` | — | **oui** |
| Fondations du T6 (`game/pokemon/party.gd`, `exp_calc.gd`, `game/systems/menu/` hors `menu_director.gd`, `views/`) | lecture | lecture (un manque → l'architecte) |
| `docs/tech/etat-projet.md` | sa ligne dans « Point de reprise » | sa ligne ; l'orchestrateur fusionne |

Ordre : T7 ∥ T8 ; **T7 fusionné d'abord**, puis T8 relie l'écran dans `Boot` et finit `test_menu_team.gd` (vrai `Boot`) et ses captures ; puis T9.

### 6.8 Contrat du 6B et partage T11 ∥ T12 (figé au T10)

**Fondations figées** (T10 ; même règle qu'au §6.6 : on peut seulement **ajouter** des champs, par l'architecte ; **texte vide = élément absent**) :
- `BagEntryView` (`game/ui/battle/` → `game/ui/bag/` au T11, nom de classe inchangé) : `item_id`, `display_name` (singulier), `quantity`, `quantity_text()` (« ×3 »), `description`, `category_id`, `usable` (sert **ici**), `favorite`, `note` (« Utilisable en combat », ou la raison depuis l'Équipe), `targets_pokemon` (UTILISER ouvre le choix du Pokémon), `action_label` (« LANCER », « UTILISER »), `get_icon()` / `icon_for(id)` (`assets/ui/icons/items/<id>.svg`, sinon le sac), `category_label(id)` (FAVORIS, SOINS, CAPTURE, COMBAT, AVENTURE, OBJETS CLÉS), `is_displayable()` (Sac du combat : listé **et** utilisable), `is_listed()` (Sac du menu).
- `BagView` : `context`, `entries` (triés, chacun une fois), `favorites`, `categories` (onglets, dans l'ordre), `start_category`, `sort` (`BagQuery.Sort`), `sort_labels`, `empty_text`, `target_index` / `target_name` (depuis l'Équipe), `entries_in(category)` (`BagQuery.FAVORITES` compris), `entry(id)`, `category_label(id)`, `is_empty()`.
- `PartyPickerView` : `item_id`, `item_name`, `quantity`, `targets: Array[PartyTargetView]` (toute l'équipe, dans l'ordre), `selected` (−1 ou le Pokémon d'UTILISER À NOUVEAU), `target_at(i)`, `has_usable()`. `PartyTargetView` : `member` (`TeamMemberView` : nom, Nv., PV, « K.O. »…), `usable`, `reason`.
- `BagQuery` (statique) : `entries(bag, items, context, sort, target)`, `categories`, `start_category(context, last, available)`, `view(bag, items, context, sort, last_category, party, target_index, data) -> BagView`, `targets(party, bag, item, context, data, selected) -> PartyPickerView`, `reason_text(check)`, `result_text(result, pokemon_name)` (« +20 PV — Salamèche 33/51 » ou la raison), `can_repeat(result)` (il reste un exemplaire).
- `ItemUse.check / apply / check_target / restore`, `ItemUseResult` ; moteur : `BattleAction.heal`, `Battle.can_use_heal_items()`, `Battle.item_context()`, `BattleEvent.Kind.ITEM_USED`, `BattleBeat.Kind.HEAL`.

**`BagScreen`** (T11, `game/ui/bag/bag_screen.gd/.tscn`, d'après `menu-sac-v1.jpg`) : interface du §6.5, précisée :
```gdscript
class_name BagScreen extends MenuScreen
signal category_opened(category: StringName)   # onglet touché (le directeur s'en souvient)
signal item_previewed(item_id: StringName)     # informatif : un toucher = un aperçu, rien d'utilisé
signal favorite_toggled(item_id: StringName)   # appui long (LONG_PRESS) sur une carte
signal sort_changed(sort: int)                 # BagQuery.Sort choisi (bouton de tri toujours là)
signal use_requested(item_id: StringName)      # UTILISER / action de l'aperçu, objet usable seulement
signal target_chosen(item_id: StringName, index: int)  # une cible usable du PartyPicker, jamais une autre
signal repeat_requested                        # UTILISER À NOUVEAU (un seul par toucher)
func show_bag(view: BagView) -> void
func show_targets(view: PartyPickerView) -> void     # PartyPicker dans l'écran (pas un autre écran)
func show_result(text: String, can_repeat: bool) -> void   # UseResultBar
```
- `show_bag` rappelé **pendant** que le Sac est affiché (après un usage, un favori, un tri) met la vue à jour **sans** rejouer l'entrée, en gardant l'onglet ouvert et l'objet aperçu s'ils existent encore (sinon `start_category` et la première carte).
- Un objet non `usable` : aperçu avec sa `note`, **aucun bouton**. `targets_pokemon` faux et `usable` vrai (Ball en combat, objet AVENTURE) : le bouton porte `action_label` et émet `use_requested` (aucun cas en exploration au J6).
- **Depuis l'Équipe** (`view.target_index` ≥ 0) : UTILISER émet `use_requested` ; **pas de PartyPicker** (le Pokémon est déjà choisi) ; l'écran peut écrire « Pour Salamèche » (`target_name`). Défaut (règle 4).
- PartyPicker : retour (« ‹ » ou retour Android) referme le choix **dans l'écran**, sans signal ; il reste ouvert après un usage (§13 : « le choix du Pokémon reste ouvert pour en changer »), avec `selected` mis en avant.
- `show_result` : `UseResultBar` (texte, et UTILISER À NOUVEAU si `can_repeat`) ; elle reste jusqu'au prochain geste. Aucune confirmation.

**`PartyPicker`** (T11, `game/ui/bag/party_picker.gd/.tscn`), réutilisé tel quel en combat par T12 :
```gdscript
class_name PartyPicker extends BattleWidget     # glissement, speed_scale, haptics_enabled, haptic_played
signal target_chosen(index: int)               # seulement une cible usable
signal back_requested
func show_targets(view: PartyPickerView) -> void   # toute l'équipe : PV, « K.O. », raison en texte
```
**`UseResultBar`** (T11, `game/ui/bag/use_result_bar.gd/.tscn`) : `signal repeat_requested` ; `func show_result(text: String, can_repeat: bool)`.

**`TrainerMenu`** (T11 ajoute ; le reste est inchangé) :
```gdscript
signal bag_category_opened(category: StringName)
signal bag_favorite_toggled(item_id: StringName)
signal bag_sort_changed(sort: int)
signal bag_use_requested(item_id: StringName)
signal bag_target_chosen(item_id: StringName, index: int)
signal bag_repeat_requested
func show_bag(view: BagView) -> void                # BagScreen dans l'hôte (instancié à la première visite)
func show_bag_targets(view: PartyPickerView) -> void
func show_bag_result(text: String, can_repeat: bool) -> void
```

**`MenuDirector`** (T12 ajoute) : `setup(..., items: ItemLibrary = null)` (paramètre en fin, facultatif : les appels existants ne changent pas) ;
```gdscript
signal bag_shown(view: BagView)                     # Boot → TrainerMenu.show_bag
signal bag_targets_shown(view: PartyPickerView)     # Boot → show_bag_targets
signal bag_result_shown(text: String, can_repeat: bool)   # Boot → show_bag_result
func open_bag_category(category: StringName) -> void   # mémorise le dernier onglet (session, §13)
func toggle_item_favorite(item_id: StringName) -> bool # Bag.toggle_favorite ; mark_changed ; bag_shown
func set_bag_sort(sort: int) -> void                   # session seulement ; bag_shown
func request_item_use(item_id: StringName) -> void     # Équipe : apply sur target_index ;
                                                       # sinon bag_targets_shown(BagQuery.targets)
func use_item_on(item_id: StringName, index: int) -> bool   # ItemUse.apply ; OK → mark_changed ;
                                                       # bag_result_shown, bag_targets_shown, bag_shown
func repeat_item_use() -> bool                         # même objet, même Pokémon (§13)
```
`_on_route_shown` : `MenuRoute.BAG` → `bag_shown(BagQuery.view(state.bag, items, context, sort, last, state.party, params.target, data))` au lieu de l'écran provisoire. Onglet et tri gardés pendant la session, **jamais sauvegardés** (§13). Autosave à la fermeture si `changed` (inchangé).

**Combat** (T12) : `BattleViews.bag_entries` sans le filtre `USABLE_IN_WILD_BATTLE` (constante retirée, `test_battle_views` mis à jour : la Potion est proposée) ; `BattleBagPanel.item_chosen(id)` → si la vue a `targets_pokemon` : `PartyPicker` (nouvel emplacement `BattleHudLayout.Slot.PARTY_PICKER`, en fin d'enum) avec `BagQuery.targets(party, bag, item, battle.item_context(), data)` ; `target_chosen(i)` → `_spend_item` (`ItemUse.check` = OK, puis `Bag.remove` **une fois**) → `Battle.submit(BattleAction.heal(id, i))` ; « ‹ » → retour au Sac, rien consommé. `_spend_ball` devient `_spend_item` (Ball : comme au 5D). Temps `HEAL` : la barre du Pokémon en jeu remonte si `event.party_index` est le sien, sinon rien ne bouge (les messages suffisent). Grille : `WILD_BATTLE_ACTIONS` et `TRAINER_BATTLE_ACTIONS` **inchangées** (SAC muet contre le rival du labo) ; `BattleRequest.trainer_battle` continue de ne passer aucun objet.

**Câblage** (T12, `Boot`, après la fusion de T11) : `TrainerMenu.bag_*` → méthodes ci-dessus ; `MenuDirector.bag_*_shown` → `TrainerMenu.show_bag*` ; `Boot` passe `_items` à `MenuDirector.setup`. Avant la fusion, T12 teste avec `tests/helpers/fake_trainer_menu.gd` étendu (mêmes signaux et méthodes `show_bag*`) ; T11 teste `BagScreen`, `PartyPicker`, `UseResultBar` avec des vues fabriquées **ou** construites par `BagQuery` sur un Sac de test.

| Fichiers | T11 (ui-mobile) | T12 (constructeur-monde) |
|---|---|---|
| `game/ui/bag/**` (BagScreen, PartyPicker, UseResultBar ; **déplacés** depuis `game/ui/battle/` avec leurs `.uid` : `bag_category_tab`, `bag_item_card`, `bag_tile`, `bag_entry_view`) | **oui** | lecture |
| `game/ui/battle/battle_bag_panel.gd/.tscn` (chemins des scènes déplacées seulement) | **oui** | lecture |
| `game/ui/menu/trainer_menu.gd/.tscn` (`show_bag*`, signaux `bag_*`) | **oui** | lecture |
| `game/ui/theme/ui_tokens.gd`, `ui_theme.tres`, `tools/build_ui_theme.gd` (`BAG_*` nouveaux, `PICKER_*`, `RESULT_*`) | **oui** | lecture |
| `assets/ui/icons/items/potion.svg` (+ icônes d'onglets), `tools/capture_menu.gd` (scénarios `bag`, `bag_use`, `bag_result`, `bag_from_team`) | **oui** | lecture (captures du T12 : `bag_battle`, `bag_battle_target`, son propre outil ou `tools/capture_wild_battle_hud.gd`) |
| `tests/integration/test_bag_screen.gd`, `test_party_picker.gd`, `test_trainer_menu.gd` (étendu), `test_battle_bag_panel.gd` (inchangé, vert après le déplacement) | **oui** | — |
| `game/systems/menu/menu_director.gd`, `game/boot.gd`, `game/boot.tscn` | — | **oui** |
| `game/battle/battle_director.gd`, `game/battle/battle_views.gd` (filtre retiré), `game/ui/battle/battle_hud_layout.gd` (`Slot.PARTY_PICKER`) | — | **oui** |
| `tests/helpers/fake_trainer_menu.gd` (étendu), `tests/integration/test_menu_bag.gd`, `test_battle_director.gd`, `test_wild_battle.gd`, `test_menu_open.gd`, `test_boot.gd`, `tests/unit/test_battle_views.gd` | — | **oui** |
| Fondations du T10 (`game/items/**`, `game/systems/menu/bag_query.gd`, `views/`, moteur `game/battle/` hors `battle_director.gd` / `battle_views.gd`, `data/items/`, `data/battle/`) | lecture | lecture (un manque → l'architecte) |
| `docs/tech/etat-projet.md` | sa ligne dans « Point de reprise » | sa ligne ; l'orchestrateur fusionne |

`battle_bag_panel.gd` est touché par **T11 seulement** (chemins `preload` des scènes déplacées) ; T12 ne le modifie pas (il le pilote depuis `battle_director.gd`). Ordre : T11 ∥ T12 ; **T11 fusionné d'abord** (déplacements de fichiers), puis T12 relie l'écran dans `Boot`, place le `PartyPicker` en combat et finit `test_menu_bag.gd` (vrai `Boot`) et ses captures ; puis T13.

---

## 7. Découpage des tâches (dans l'ordre)

Chaque tâche finit par `tools/test.sh` vert (nombre de tests rapporté), un import sans `ERROR` ni `SCRIPT ERROR`, et, si elle est visible, des **captures relues** (Movie Maker, `tools/capture_menu.gd`, scénarios nommés ci-dessous, à **2340 × 1080 et 1920 × 1080**). La capture S24 vient à la validation du sous-jalon (règle 2). `docs/tech/etat-projet.md` est mis à jour dans le même commit (règle 5). Les durées, tailles et couleurs passent par `UiTokens` (nouvelles constantes `MENU_*`, `TEAM_*`, `DEX_*`, `MAP_*`, `SETTINGS_*`) et les variations de thème par `tools/build_ui_theme.gd`.

### 6.0 — Fondations, sauvegarde v2, tableau de bord

#### T0 — architecte-godot : alignement et sauvegarde v2
- Aligner ce plan sur le code fusionné du J5 (ce qui a bougé depuis `c1842e5`) et sur les réponses de Kevin ; §5.1.
- **CA** : tests du §5.1 verts ; fixture v1 réelle ; `etat-projet.md` à jour ; aucune interface.
- **Fait (2026-10-02)** : §5.1 et §15 ; 1619 tests verts (+19), import propre.

#### T1 — qa-mobile : la migration sur le S24 (validée seule)
- Protocole du §5.1.1. **CA à rapporter** : chaque étape conforme ; `save.json` en version 2 ; l'APK du J5 ne l'écrase pas (fichier identique octet pour octet) ; journal sans erreur ; validation de Kevin.

#### T2 — architecte-godot : navigation, déblocage, objectif, zones
- §3.2 ; `data/story/objectives.json` (Q-4), `data/world/zones.json` (noms et cartes) ; `DebugUnlocks` ; option `--debug-unlock` de `tools/deploy_s24.sh`.
- **CA** : tests du §3.2 et du §4 (unitaires) verts ; données réelles sans erreur.
- **Fait (2026-10-03)** : §3.2 (« Fait au T2 »), contrat et partage T3 ∥ T4 au §6.6 ; 7 scripts de tests nouveaux (+67 tests, 1693 verts).

#### T3 — ui-mobile : le menu et le tableau de bord (avec des vues fabriquées)
- `TrainerMenu` (fond flouté, en-tête ×, nom de zone), `MenuScreen`, `DashboardScreen` (carte du Dresseur, Pokémon de tête, cartes `MenuCard` avec icône, nom et une ligne de description, objectif), `MenuButton` dans l'`ExplorationHud`. Composition d'après `menu-tableau-de-bord-v1.jpg` **sans** argent ni heure, **avec** la ligne d'objectif.
- **CA** : `test_trainer_menu.gd`, `test_dashboard_screen.gd` : 5 cartes ou 6 selon la vue, jamais d'emplacement vide ; carte touchée → **un** `card_chosen` ; × → **un** `back_requested` ; ligne vus · capturés absente si la vue la laisse vide ; zones ≥ `TOUCH_MIN`, rien d'interactif dans `SAFE_MARGIN`, à 1920 et 2340 ; animation complète à `speed_scale = 0`. Captures `dashboard_5`, `dashboard_6`, `dashboard_no_team`, lues avec Read : le monde transparaît, rien n'est coupé, texte lisible.

#### T4 — constructeur-monde : ouvrir, mettre en pause, fermer
- `MenuDirector`, câblage dans `Boot` (process modes, garde, autosave à la fermeture, `menu`, retour Android, `quit_on_go_back = false`), `DashboardViews` branché, `DebugUnlocks` lu (même garde que `DebugStart`), écrans provisoires pour les autres cartes (`placeholder_shown` → `TrainerMenu.show_placeholder`, §6.6). Les liaisons avec `TrainerMenu` et `ExplorationHud.menu_requested` se font après la fusion de T3 (§6.6).
- **CA** :
  - `tests/integration/test_menu_open.gd` (vrai `Boot`) : ouverture refusée pendant un dialogue, une scène, une rencontre, un combat, une transition ; ouverte → `get_tree().paused`, le joueur ne bouge plus (`move_up` tenu), le Voyageur ne marche plus, le temps de jeu continue ; fermée → tout reprend, contrôles visibles ; retour (notification simulée) menu ouvert → fermé, **l'application ne quitte pas** ; autosave demandé seulement si l'état a changé ; passage en arrière-plan menu ouvert → sauvegarde écrite.
  - `test_boot.gd` : tous les enfants de `Boot` sauf `MenuDirector` et `TrainerMenu` sont `PAUSABLE`.
  - `test_menu_unlock_rule.gd` (§4).
  - Capture `menu_open` image par image (~8 images sur 0,3 s) : pas d'image noire, fond qui se floute.

#### T5 — qa-mobile : validation du 6.0
- **CA** : ouverture et fermeture < 300 ms ressenties, 20 fois de suite ; jamais ouvert pendant un dialogue ou un combat ; le monde est figé derrière ; retour Android dans les deux cas (menu ouvert : un niveau en arrière puis fermeture ; exploration : ouvre le menu, ne quitte jamais) ; 60 fps menu ouvert (le fond flouté) ; pas de joystick « collé » après la fermeture ; cinq cartes ; objectif lisible ; journal propre.

### 6A — Équipe

#### T6 — architecte-godot : fondations de l'Équipe
- §3.3. **CA** : tests du §3.3 verts.
- **Fait (2026-10-03)** : §3.3 (« Fait au T6 »), contrat et partage T7 ∥ T8 au §6.7 ; 3 scripts de tests nouveaux et 2 étendus (+37 tests, 1779 verts).

#### T7 — ui-mobile : l'écran Équipe
- `TeamScreen` d'après `menu-equipe-v1.jpg` : liste (6 emplacements, vides neutres et **sans action**, sans « Ajouter un Pokémon »), grand sprite (×6 entier, NEAREST, respiration par un léger décalage vertical et non par une échelle non entière), en-tête de fiche (nom, sexe, Nv., types, PV, XP), onglets Aperçu · Capacités · Histoire (une capacité touchée ouvre `MoveDetailSheet`), actions UTILISER UN OBJET · DÉPLACER · FAVORI. Réordonner : appui long (`LONG_PRESS`) puis glisser **et** DÉPLACER (choisir A, puis l'emplacement B), courte animation d'échange.
- **CA** : `test_team_screen.gd` : glisser A sur B → **un** `member_moved(a, b)` ; mode DÉPLACER → le même signal, sans glisser ; un emplacement vide n'émet rien ; FAVORI → `favorite_toggled` et l'étoile change **avec un texte** (« Favori »), pas seulement une couleur ; aucune condition d'évolution affichée ; statut « K.O. » en texte. Captures `team`, `team_sheet_moves`, `team_history`, `team_move_mode`.

#### T8 — constructeur-monde : l'Équipe jouable
- Câblage `MenuDirector` ↔ `TeamScreen` ; lien du Pokémon de tête. (Le sprite d'entrée en combat suit déjà le Pokémon envoyé : §10, écart 1, corrigé au J5.)
- **CA** : `test_menu_team.gd` (vrai `Boot`) : réordonner puis fermer → `GameState.party` dans le nouvel ordre, autosave demandé, **le combat suivant envoie le nouveau premier Pokémon valide** et l'animation d'entrée montre ce Pokémon ; favori sauvegardé et relu. Captures.

#### T9 — qa-mobile : validation du 6A
- **CA** : les quatre questions « qui, quel niveau, combien de PV, quel état » en moins de 2 s ; glisser-déposer au pouce sans erreur sur 10 essais ; DÉPLACER sans glisser ; favori ; le premier de la liste part au combat ; sauvegarde et reprise.

### 6B — Sac

#### T10 — architecte-godot : fondations du Sac et soin en combat
- §3.4 (dont le moteur de combat) ; `heal_amount` ; messages `draft`.
- **CA** : tests du §3.4 verts ; simulation du jalon 5 inchangée.
- **Fait (2026-10-03)** : §3.4 (« Fait au T10 »), contrat et partage T11 ∥ T12 au §6.8 ; 2 scripts de tests nouveaux et 5 étendus ; simulation et tests du J5 inchangés.

#### T11 — ui-mobile : l'écran Sac et le choix du Pokémon
- Déplacement des composants du Sac vers `game/ui/bag/` (imports vérifiés, `test_battle_bag_panel` inchangé et vert) ; `BagScreen` d'après `menu-sac-v1.jpg` (catégories à gauche, cartes au centre, aperçu à droite ; un toucher = un aperçu) ; rangée FAVORIS, appui long = favori ; tri ; `PartyPicker` (équipe, PV, raison pour un Pokémon incompatible) ; `UseResultBar` (« +20 PV — Salamèche 33/51 », UTILISER À NOUVEAU) ; icône `potion.svg`.
- **CA** : `test_bag_screen.gd` : un toucher n'utilise rien ; UTILISER → choix ; Pokémon incompatible visible avec sa raison et **sans** `target_chosen` ; résultat et UTILISER À NOUVEAU → **un** `repeat_requested` ; onglet vide absent ; objet de combat hors combat : mention « Utilisable en combat », pas de bouton. `test_party_picker.gd`. Captures `bag`, `bag_use`, `bag_result`, `bag_from_team`.

#### T12 — constructeur-monde : le Sac jouable, en exploration et en combat
- Câblage exploration et lien depuis l'Équipe ; en combat sauvage : SOINS dans `BattleBagPanel`, `PartyPicker` en combat (nouvel emplacement de `BattleHudLayout`), `BattleDirector` (`_spend_item`, action `heal`, temps `HEAL`).
- **CA** : `test_menu_bag.gd` : Potion sur Salamèche 13/20 → 20/20, Sac −1, autosave à la fermeture ; UTILISER À NOUVEAU sur PV pleins → raison, rien consommé. `test_battle_director.gd` (étendu) : Potion en combat → PV remontés, objet retiré **une** fois, l'adversaire joue, rien en combat contre le rival du labo (SAC muet, décision n° 12). `test_wild_battle.gd` : un combat avec une Potion. **Export** : rien de nouveau. Captures `bag_battle`, `bag_battle_target`.

#### T13 — qa-mobile : validation du 6B
- **CA** : une Potion en trois gestes au plus ; raison lisible ; UTILISER À NOUVEAU ; même Sac en combat (la quantité suit) ; favoris ; aucune confirmation en cascade ; 60 fps.

### 6C — Pokédex (débloqué par le drapeau de débogage)

#### T14 — architecte-godot : fondations du Pokédex
- §3.5 ; `data/pokedex/kanto.json` (14 espèces, textes provisoires) ; `NpcSpec.species`.
- **CA** : tests du §3.5 verts.

#### T15 — ui-mobile : l'écran Pokédex
- `PokedexScreen` d'après `menu-pokedex-v1.jpg` **sans** statistiques de base, talents, silhouettes, chaîne complète ni « 27/151 » : en-tête « POKÉDEX — KANTO » et « X vus · Y capturés · 151 espèces », filtres TOUS · VUS · CAPTURÉS · HABITATS, recherche par nom, grille numérotée (151 cases légères : seules les espèces vues chargent un sprite) ; `PokedexSheet` en quatre onglets (Aperçu, Habitat en petite carte des seules zones observées, Évolution, Observations).
- **CA** : `test_pokedex_screen.gd` : inconnu = numéro et « ??? » sans image ; vu = sprite et nom, pas de types ; capturé = fiche complète ; zone de l'Habitat touchée → **un** `route_requested(map)`. Défilement fluide de la grille. Captures `dex_grid`, `dex_sheet_seen`, `dex_sheet_caught`, `dex_habitat`.

#### T16 — constructeur-monde : le Pokédex jouable
- Câblage ; observation par OBSERVER (`"species"` dans `data/npcs/pallet_town.json`, Q-7) ; toasts Pokédex (différés à la fin d'une rencontre) ; notes rafraîchies ; lien vers la Carte (écran provisoire jusqu'au T21).
- **CA** : `test_menu_pokedex.gd` (vrai `Boot`, `debug_pokedex`) : Roucool vu sur la Route 1 → case « vu », fiche, Habitat « Route 1 » ; sans drapeau : **rien** de tout cela visible (`test_menu_unlock_rule`) mais les données sont là ; toast affiché après la rencontre, jamais pendant ; observer le Roucool de Mme Aoki → vu à Bourg Palette. Captures.

#### T17 — qa-mobile : validation du 6C (avec `--debug-unlock pokedex`, sur la vraie partie)
- **CA** : ce que Kevin a déjà rencontré apparaît ; aucune silhouette, aucun « ??? » dans un habitat, aucune condition d'évolution ; toasts discrets ; sans l'option, rien du Pokédex nulle part ; 60 fps en faisant défiler la grille.

### 6D — Carte

#### T18 — architecte-godot : fondations de la Carte
- §3.6 ; `zones.json` complet pour Bourg Palette et la Route 1 (descriptions provisoires) et l'emplacement des autres zones sur l'illustration (Q-15).
- **CA** : tests du §3.6 verts.

#### T19 — constructeur-monde : l'illustration provisoire de Kanto
- `tools/gen_kanto_map.gd` → `assets/ui/map/kanto_placeholder.png` (géographie de Rouge/Bleu stylisée, villes, routes, eau, reliefs, **sans aucun nom**), portrait du joueur (sprite agrandi). **Peut avancer en parallèle** dès le 6A (§8).
- **CA** : image générée, rectangles de `zones.json` alignés (test), relue avec Read.

#### T20 — ui-mobile : l'écran Carte
- `MapScreen` (illustration entière, portrait discret du joueur, zones découvertes touchables ≥ `TOUCH_MIN`, aucune icône superflue), `ZonePanel` latéral (nom, sous-titre, description, Pokémon observés, objets trouvés, services). Aucun bouton de déplacement, aucun « Se rendre ici ».
- **CA** : `test_map_screen.gd` : zone non découverte ni nommée ni touchable ; zone touchée → **un** `zone_touched` et le panneau, sans changer d'écran ; Pokémon observé touché → **un** `route_requested(pokedex)`. Captures `map`, `map_panel`.

#### T21 — constructeur-monde : la Carte jouable et ses liens
- Câblage ; liens Pokédex ↔ Carte.
- **CA** : `test_menu_map.gd` : position du joueur (y compris dans un intérieur : sa ville) ; Potion de la Route 1 trouvée → listée ; Pokémon observés seulement avec le Pokédex visible ; aller-retour Pokédex → Carte → Pokédex sans empiler.

#### T22 — qa-mobile : validation du 6D
- **CA** : la carte se lit d'un coup d'œil ; rien n'annonce ce qui reste à découvrir ; panneaux lisibles ; liens ; 60 fps.

### 6E — Dresseur

#### T23 — architecte-godot : fondations du Dresseur
- §3.7 ; `data/trainer/moments.json`. **CA** : tests verts.

#### T24 — ui-mobile : l'écran Dresseur (recomposé en paysage)
- `TrainerScreen` d'après la DA de `menu-dresseur-v1.jpg` **recomposée en paysage** : identité et portrait à gauche, badges au centre (8 emplacements muets), frise des grands moments à droite, statistiques en section secondaire. Sans niveau, XP, tenues, titres, pourcentage, biographie.
- **CA** : `test_trainer_screen.gd` : badge inconnu sans nom ni image ; « vus » / « capturés » absents si la vue les laisse vides, sinon **un** `route_requested` chacun. Captures `trainer`, `trainer_dex`.

#### T25 — constructeur-monde : le Dresseur jouable
- Câblage, liens (vus, capturés, premier Pokémon). **CA** : `test_menu_trainer.gd` (moments réels d'une partie de test, temps de jeu, liens selon le déblocage).

#### T26 — qa-mobile : validation du 6E
- **CA** : l'écran raconte la partie de Kevin ; aucun compteur « / 8 » ; liens.

### 6F — Paramètres

#### T27 — architecte-godot : fondations des Paramètres
- §3.8 ; remplacement des 7 appels à `Input.vibrate_handheld` par `Haptics.vibrate` (comportement inchangé, tests existants verts).
- **CA** : tests du §3.8 verts.

#### T28 — ui-mobile : l'écran Paramètres et les commandes réglables
- `SettingsScreen` d'après la DA de `menu-parametres-v1.jpg` recomposée en paysage : catégories à gauche (JEU, COMMANDES, GRAPHISMES, ACCESSIBILITÉ ; **pas** d'AUDIO, Q-17). GRAPHISMES : un seul choix **Auto** (défaut) / **Élevée** / **Économie** ; Économie = 30 images/s (`Engine.max_fps`) et flou du fond du menu coupé, autres effets coûteux réduits ; Auto choisit le profil selon l'appareil (S24 → Élevée) ; aucune autre option technique, interrupteurs, curseurs, choix ; « Sauvegarder maintenant » ; **aucune** option « sauvegarde automatique ». `TouchJoystick.size_scale` et `opacity`, échelle des boutons ronds, `ExplorationHud.set_left_handed(bool)` (joystick dans la moitié droite, boutons courir et contextuel en bas à gauche, bouton Menu en haut à droite inchangé ; exploration seulement, Q-16) ; `UiPrefs` dans la boîte de dialogue, le toast, le titre de zone et les écrans du menu ; `ChoiceCards` (Q-18).
- **CA** : `test_settings_screen.gd` (chaque contrôle → **un** `setting_changed` ; valeur affichée en texte, pas seulement par la position) ; `test_exploration_hud.gd` (gaucher : zones du joystick et des boutons miroir, toujours dans `SAFE_MARGIN`) ; `test_virtual_joystick.gd` (taille, opacité). Captures `settings`, `left_handed`, `text_large`, `contrast`.

#### T29 — constructeur-monde : les réglages agissent
- `Boot._apply_settings` (§6.4) ; `SettingsStore` lu au démarrage ; « Sauvegarder maintenant » ; `BattleStage.reduce_flashes` (clignotement du coup remplacé par un léger assombrissement, flash du critique et de la capture adoucis) ; la réduction des animations ne raccourcit **pas** la tenue des messages de combat (`BattleHud.message_hold_scale` séparé de `speed_scale`).
- **CA** : `test_settings_apply.gd` (vrai `Boot`) : vitesse du texte → `DialogueRunner.chars_per_second` ; animations réduites → `BattleDirector.speed_scale = 0,6` et durée d'un combat de test plus courte, messages tenus pareil ; haptique coupée → aucune vibration (espion `Haptics.sink`) ; réglages relus après redémarrage ; « Sauvegarder maintenant » → fichier écrit, toast ; départ de débogage → « sauvegarde désactivée pour cette session », rien d'écrit.

#### T30 — qa-mobile : validation du 6F et QA finale du J6
- **CA** : chaque réglage a un effet visible ou sensible sur le S24 ; mode gaucher jouable ; fichier de réglages survivant à une réinstallation par-dessus ; puis **parcours complet** : partie réelle, chaque écran, chaque lien du §6.3, combat avec Potion, sauvegarde et reprise, 60 fps partout, journal propre, aucun élément du Pokédex sans le drapeau de débogage.

---

## 8. Parallélisme (deux agents au plus, chacun dans sa copie)

**Peut avancer en parallèle** :
- l'architecte prépare les **fondations pures** du sous-jalon suivant (T6, T10, T14, T18, T23, T27) pendant la QA du précédent (fichiers nouveaux et tests seulement) ;
- **T19** (illustration provisoire de Kanto, outil et image) à tout moment après T2 : aucun fichier partagé ;
- **T3** (écran du tableau de bord) pendant T4 (câblage), **si** les vues de T2 sont figées : T3 travaille avec des vues fabriquées, T4 avec un écran factice ; la fusion se fait au T4.

**Ne peut pas avancer en parallèle** :
- deux tâches qui touchent `game/boot.gd` / `boot.tscn`, `game_state.gd`, le format de sauvegarde, `battle_director.gd` / `battle.gd`, `project.godot` ou `ui_tokens.gd` + `build_ui_theme.gd` (conflits garantis) ;
- **deux écrans** du menu (dossier 08 §11 : jamais les six à la fois ; Kevin les valide un par un) ;
- **T0 et quoi que ce soit d'autre** : la sauvegarde v2 est seule jusqu'à sa validation (T1) ;
- **T27** (remplacement des appels de vibration, 6 fichiers) et une tâche de combat.

---

## 9. Critères d'acceptation par sous-jalon (récapitulatif)

| | 6.0 | 6A | 6B | 6C | 6D | 6E | 6F |
|---|---|---|---|---|---|---|---|
| Tests | §5.1, §3.2, §4, T3–T4 | §3.3, T7–T8 | §3.4, T11–T12 | §3.5, T15–T16 | §3.6, T20–T21 | §3.7, T24–T25 | §3.8, T28–T29 |
| Toujours | `tools/test.sh` vert (tout ce qui précède compris), import sans `ERROR` ni `SCRIPT ERROR`, nombre de tests rapporté, `etat-projet.md` à jour | | | | | | |
| Déblocage | 5 cartes sans le drapeau | « ??? » d'évolution | — | rien sans le drapeau | pas de Pokémon observés sans le drapeau | pas de vus · capturés sans le drapeau | — |
| Sauvegarde | v2 validée seule (T1) | ordre, favori | Sac, favoris | notes | — | — | réglages à part, « Sauvegarder maintenant » |
| Captures | T3, T4 | T7, T8 | T11, T12 | T15, T16 | T19, T20 | T24 | T28 |
| S24 | T1, T5 | T9 | T13 | T17 | T22 | T26 | T30 |
| Export | `data/story`, `data/world` | — | — | `data/pokedex` | — | `data/trainer` | — |

**Tests GUT prévus** — unitaires nouveaux : `test_menu_route`, `test_menu_navigator`, `test_menu_unlocks`, `test_debug_unlocks`, `test_objective_library`, `test_zone_library`, `test_dashboard_views`, `test_evolution_reveal`, `test_team_views`, `test_item_use`, `test_bag_query`, `test_pokedex_library`, `test_pokedex_notes`, `test_pokedex_query`, `test_pokedex_updates`, `test_map_journal`, `test_trainer_summary`, `test_game_settings`, `test_settings_store`, `test_haptics` ; étendus : `test_save_system`, `test_game_state`, `test_bag`, `test_pokemon`, `test_pokedex`, `test_party`, `test_exp_calc`, `test_item_library`, `test_battle`, `test_battle_text`, `test_battle_playback`, `test_npc_roster`. Intégration nouveaux : `test_trainer_menu`, `test_dashboard_screen`, `test_menu_open`, `test_menu_unlock_rule`, `test_team_screen`, `test_menu_team`, `test_bag_screen`, `test_party_picker`, `test_menu_bag`, `test_pokedex_screen`, `test_menu_pokedex`, `test_map_screen`, `test_menu_map`, `test_trainer_screen`, `test_menu_trainer`, `test_settings_screen`, `test_settings_apply` ; étendus : `test_boot`, `test_save_boot`, `test_battle_director`, `test_battle_bag_panel`, `test_wild_battle`, `test_exploration_hud`, `test_virtual_joystick`. Fixtures : `tests/fixtures/save/`, `tests/fixtures/pokedex/`, `tests/fixtures/zones/`, `tests/fixtures/settings/`.

---

## 10. Écarts entre le dossier 08 et le code réel, contradictions relevées

1. ~~**Bug du J5 rendu fréquent par le 6A** : sprite du partenaire choisi par `party.get_lead()`~~ **Corrigé au J5** (`24901cb`, lot de dettes) : `run_request` lance `Battle.start()` d'abord et prend l'espèce des `SENT_OUT` du moteur ; `_find_player_pokemon` retrouve le Pokémon par `BattleEvent.party_index`. Plus rien au T8.
2. **Statuts** : le dossier 08 §2 demande « statut toujours en texte (K.O., PSN, PAR, SOM, BRÛ, GEL) ». `Pokemon` n'a aucun statut (statuts au J11) : au J6, seul « K.O. » (déduit des PV) existe.
3. **Retour Android** : aujourd'hui il ferme l'application (`quit_on_go_back` par défaut). Le dossier 08 §1 veut qu'il ferme le menu : réglage à changer ; en exploration, il ouvre le menu et ne quitte plus le jeu (Q-3, décision de Kevin).
4. ~~**Starter « vu 0 fois »**~~ **Corrigé au J5** (`a6d9254`, Q-8 au défaut) : la capture d'une espèce jamais vue compte une observation ; les anciennes entrées sont corrigées au chargement (`ensure_seen`). La migration v2 ne la refait pas (§5.1).
5. **Taille, poids, description, notes** : absents des données (`SpeciesData`) ; nouveau fichier `data/pokedex/kanto.json` plutôt que d'alourdir `kanto.json` et sa validation stricte.
6. **Grands moments** : le dossier 08 §6 cite « départ de Bourg Palette, arrivée à Jadielle » ; seuls `starter`, `rival_battle`, `first_capture` sont enregistrés. Les arrivées se déduisent de `discovered_maps` (Q-14) ; rien à rétro-greffer.
7. **Combats gagnés** et autres statistiques : non enregistrés ; l'écran Dresseur V1 ne montre que ce qui l'est (dossier 08 §6 l'autorise).
8. **Tableau du dossier 08 §10, ligne `menu-equipe-v1.jpg`** : « Marquer favori » figure dans « ne fait pas foi », alors que le §2 (corrigé le 2026-10-02) adopte FAVORI. Le plan suit le §2 ; le tableau n'a pas été mis à jour.
9. **Roadmap, phase 3** : catégories « objets, soins, Poké Balls, CT, objets clés » et « argent » au profil ; « audio, musique » aux Paramètres. Le dossier 08 (SOINS, CAPTURE, COMBAT, AVENTURE, OBJETS CLÉS + FAVORIS ; argent au J7A ; pas de son) prime.
10. **Bouton Menu** : la planche le met en haut à droite (☰), la bible parle d'« un geste ou un petit bouton », la contradiction n'est pas tranchée (Q-1).
11. **Tailles de texte et couleurs constantes** : tout passe par des constantes `UiTokens` et un thème généré ; la taille du texte et le contraste demandent des valeurs lues à l'exécution (`UiPrefs`). Le HUD de combat a des hauteurs fixes (`BATTLE_CARD_HEIGHT`) : il n'est pas couvert au J6 (Q-19).
12. **Vibrations dispersées** (7 appels directs) : centralisées au T27 avant de pouvoir les couper.
13. **Icônes** : seule `poke_ball.svg` existe pour les objets ; il faut au moins `potion.svg` et les icônes des six cartes du tableau de bord (provisoires).
14. **Sprites** : il n'existe de sprites de combat que pour les 3 starters, Roucool et Rattata (pas pour leurs évolutions) ; suffisant au J6, puisqu'une espèce non vue n'a pas d'image.
15. **`SaveSystem`** disait qu'ajouter un champ n'exige pas de nouvelle version : vrai pour la lecture, faux pour la protection contre un ancien APK (§5.1). **Commentaire précisé au T0** (avec l'historique des versions).

---

## 11. Risques et coûts cachés

| Risque | Effet | Parade |
|---|---|---|
| **Pause de l'arbre** | `Boot` doit continuer (temps de jeu, autosave) alors que ses enfants gèlent ; un nœud oublié en `INHERIT` hériterait d'`ALWAYS` | enfants posés `PAUSABLE` explicitement, test d'invariant (T4) |
| **Retour Android** (`quit_on_go_back`, geste retour d'Android 14) | quitter l'application au lieu de fermer le menu, ou ne plus pouvoir quitter | essai S24 dès le T4 ; test de la notification simulée |
| **Sauvegarde v2** | perte de données, ancien APK qui écrase | une seule migration, fixture réelle, QA S24 seule (T1) |
| **Moteur de combat** (soin) | régression des combats validés au J5 | ajouts en fin d'enum, règle partagée `ItemUse`, simulation et tests du J5 inchangés |
| **Coût du fond flouté** sur S24 | sous 60 fps menu ouvert | même shader que le combat (62 fps mesurés) ; flou par mipmaps ; mesure au T5 |
| **Instanciation des écrans** (gros arbres de `Control`) | à-coup à la première ouverture d'un écran | scènes préchargées, instanciées à la première visite puis gardées ; mesure au T5 et au T17 (grille de 151 cases légères) |
| **Glisser-déposer tactile** dans une liste | conflit avec le défilement, déclenchements par erreur | appui long (`LONG_PRESS`) avant de saisir, seuil de déplacement (`BAG_TAP_SLOP`) ; mode DÉPLACER toujours disponible |
| **Sprites pixel art agrandis** | scintillement avec une échelle non entière | échelles entières (NEAREST), respiration par décalage vertical |
| **Taille du texte, contraste** | coût réparti sur tous les composants | couverture limitée et listée (Q-19) ; le reste en polish |
| **Textes à écrire** (objectifs, descriptions de zones, Pokédex, notes, moments, messages du soin en combat) | attente de Kevin | textes provisoires `draft`, un seul lot à relire (Q-4 à Q-6) |
| **Illustration de Kanto** | asset lourd de DA | placeholder généré par un outil, rectangles des zones en données ; la vraie illustration en phase DA |
| **Toasts pendant un combat** | un toast « Pokédex mis à jour » sous l'interface de combat | toasts du Pokédex différés à la fin de la rencontre |
| **Agents en parallèle** sur `boot.gd` | conflits | règle du §8 |

---

## 12. Questions pour Kevin (valeur par défaut appliquée si tu ne dis rien)

> **Décisions de Kevin (2026-10-02) — verrouillées.** Défauts acceptés pour Q-1, Q-2, Q-4 à Q-6, Q-8, Q-10 à Q-16, Q-18 à Q-21. Modifiés ou précisés :
> - **Q-3** : le retour Android **ne ferme jamais le jeu**. En exploration, il ouvre le Menu Dresseur ; menu ouvert, il remonte d'un niveau ; à la racine, il ferme le menu et rend le jeu. La fermeture de l'application reste celle d'Android (pas une interaction de gameplay).
> - **Q-7** : Pokémon visible dans le monde → seul OBSERVER l'enregistre ; Pokémon rencontré en combat sauvage → la rencontre compte comme observation ; Pokémon reçu ou capturé → observé aussi. Les Pokémon des habitants peuvent être observés avant l'activation du Pokédex, mais rien n'est visible avant l'activation (J7). **Chen (J7A)** cite la **première espèce sauvage rencontrée en combat**, jamais un Pokémon d'habitant ni un Pokémon observé dans le décor.
> - **Q-9** : anti-spoiler jusqu'au bout. Avant activation : « Évolution : ??? ». Après : seulement ce que le joueur a réellement découvert ; **ni niveau d'évolution, ni silhouette, ni nom** d'une évolution inconnue.
> - **Q-17** : **GRAPHISMES dès le J6, minimal** : Auto (défaut, profil choisi selon l'appareil) / Élevée / Économie (30 images/s, flou coupé et effets coûteux réduits). Aucune autre option technique. **AUDIO absent** tant qu'il n'y a pas de système audio.

Seules les vraies questions de game design sont ici ; les petites (durées, tailles, positions) ont reçu une valeur par défaut au §13.

**Ouvrir le menu**
- **Q-1 — Le bouton Menu** : où et quand ? *Défaut* : un petit bouton rond translucide **en haut à droite** (planche), visible quand les contrôles le sont (caché pendant un dialogue, une scène, un combat) ; Échap ou M sur Mac.
- **Q-2 — Avant le starter** (chambre, prologue) : *Défaut* : le menu s'ouvre dès la chambre ; la carte **ÉQUIPE** et le Pokémon de tête sont **absents** tant que l'équipe est vide (comme la carte Pokédex : absents, pas grisés) ; le Sac vide dit « Ton Sac est vide. ».
- **Q-3 — Retour Android en exploration** : *Défaut* : comme aujourd'hui (sauvegarde, puis l'application se ferme). Menu ouvert : retour d'un niveau, puis fermeture.
- **Q-4 — Textes des objectifs** (dossier 08 §12 Q2) : *Défaut* : une seule ligne provisoire, « Objectif : rejoindre Jadielle », après le combat contre le rival ; aucune ligne avant (le prologue guide déjà le joueur). Le colis (J7A) ajoutera la sienne.

**Équipe et Sac**
- **Q-8 — Le starter « vu 0 fois »** : *Défaut* : capturer (ou recevoir) une espèce jamais vue compte **une observation** ; les parties existantes sont corrigées ~~par la migration v2~~ **au chargement** (déjà codé au J5, `a6d9254` ; §5.1).
- **Q-9 — Évolution dans la fiche Équipe avant l'activation du Pokédex** : *Défaut* : « Évolution : ??? » pour les stades suivants, rien n'est révélé avant l'activation ; ensuite, les stades vus se révèlent. Une espèce sans évolution n'a pas de section.
- **Q-10 — Potion en combat** : *Défaut* : sur **n'importe quel Pokémon de l'équipe** (PV visibles), l'action prend le tour et l'adversaire joue ensuite (Rouge/Bleu). Le SAC reste muet contre le rival du labo (décision n° 12).
- **Q-11 — Potion sur un Pokémon K.O.** : *Défaut* : impossible (Rouge/Bleu), raison affichée « Ce Pokémon est K.O. » ; aucun objet n'est annoncé pour le ranimer.
- **Q-12 — Tri « récents »** : *Défaut* : les objets **obtenus** le plus récemment d'abord ; le bouton de tri est toujours là.

**Pokédex**
- **Q-5 — Taille, poids, description** : *Défaut* : tailles et poids officiels ; descriptions **provisoires écrites pour le projet** (pas recopiées des jeux), marquées `draft`, à remplacer par tes textes.
- **Q-6 — Observations** : *Défaut* : une note provisoire par espèce rencontrable au J6 (Roucool, Rattata, les 3 starters), débloquée à la première observation ; les textes et les déclencheurs (rencontres, PNJ, événements) sont à toi.
- **Q-7 — Observer dans le décor** (dossier 08 §12 Q1, défaut « oui ») : précisions. *Défaut* : seul le geste **OBSERVER** compte (pas un Pokémon qui s'envole à 2 cases) ; les Pokémon des habitants comptent aussi (le Roucool de Mme Aoki est un Roucool) ; cela vaut dès le prologue. Conséquence pour le J7A : la réplique de Chen qui cite « la première espèce sauvage observée » devra choisir entre la première vue (par OBSERVER) et la première **rencontrée en combat**. *Défaut* : la première rencontrée en combat.

**Carte et Dresseur**
- **Q-13 — Badges avant le premier** : *Défaut* : l'écran Dresseur montre les **8 emplacements muets** dès le départ (pièce maîtresse) ; le tableau de bord n'a **pas** de ligne de badges avant le premier badge (pas de « 0 badge »).
- **Q-14 — Grands moments** : *Défaut* : les trois moments enregistrés (premier Pokémon, combat contre le rival, première capture) **et** la première arrivée dans chaque zone extérieure (« Départ de Bourg Palette » = première arrivée sur la Route 1) ; titres provisoires.
- **Q-15 — Zones non découvertes sur la Carte** : *Défaut* : la géographie est dessinée (placeholder d'après Rouge/Bleu) mais une zone non découverte n'a **ni nom ni toucher** ; les connexions d'une zone découverte sont son sous-titre en données (« Bourg Palette — Jadielle », déjà annoncé par le titre de la Route 1).

**Paramètres**
- **Q-16 — Mode gaucher en combat** : *Défaut* : il ne concerne que l'exploration au J6 (joystick à droite, boutons à gauche) ; l'interface de combat garde sa disposition validée.
- **Q-17 — AUDIO et GRAPHISMES** : *Défaut* : **absents** au J6 (règle 8 : rien à régler, pas de son). Autre choix : GRAPHISMES « Économie » = 30 images/s et flou coupé, pour la batterie.
- **Q-18 — « Confirmation de certaines actions »** : seule l'oubli d'une capacité est concerné aujourd'hui, validé sans confirmation au 5C. *Défaut* : réglage présent, **désactivé** par défaut ; le composant à deux cartes (bible §4) est construit au 6F et resservira au J7A (SOIGNER / PAS MAINTENANT, libérer, vendre un favori).
- **Q-19 — Taille du texte et contraste** : *Défaut* : deux tailles (Normale, Grande ≈ ×1,15) et un contraste renforcé (panneaux plus opaques, texte secondaire plus clair), appliqués aux **dialogues, toasts, titres de zone et écrans du menu** ; le HUD de combat suivra en polish.
- **Q-20 — Vitesse du texte en combat** : *Défaut* : elle règle les dialogues ; les messages de combat gardent leur tenue (un toucher avance déjà).
- **Q-21 — Temps de jeu menu ouvert** : *Défaut* : il continue (le temps passé dans les menus est du temps de jeu).

---

## 13. Valeurs par défaut (petites questions, règle 4)

| Sujet | Valeur |
|---|---|
| Ouverture / fermeture du menu | `MENU_OPEN` 0,25 s, `MENU_CLOSE` 0,2 s ; fond : flou `blur_lod` 2,0, voile 0,45 |
| Vibration à l'ouverture | `HAPTIC_MENU_MS` 8 ms |
| Jauges de statistiques (6A) | part de la plus haute statistique du Pokémon (on lit son profil) ; valeur écrite à côté |
| XP au niveau 100 | barre pleine, pas de texte « avant le niveau suivant » |
| Dates affichées | « 2 octobre 2026 » (date de l'appareil) |
| Temps de jeu | « 0 h 07 », « 12 h 43 » |
| Dernier état du Sac | onglet et tri gardés pendant la session, pas dans la sauvegarde |
| UTILISER À NOUVEAU | même objet, même Pokémon ; le choix du Pokémon reste ouvert pour en changer |
| Vitesses du texte | 25 / 45 / 90 caractères par seconde / page entière |
| Réduction des animations | combat ×0,6, menu ×0,5 ; tenue des messages inchangée |
| Joystick | taille 0,8 / 1,0 / 1,2 ; opacité 30 à 100 % de l'actuelle |
| Boutons ronds | ×1,0 ou ×1,2 |
| Pile du menu | 4 niveaux au plus (tableau de bord compris) |
| Grand sprite (6A) | 64 px natif ×6 = 384 px (≈ 36 % de la hauteur) |
| Écrans pas encore construits (builds de développement du J6) | `ComingSoonScreen` « <ÉCRAN> — À venir » |

---

## 14. Validation S24 (résumé)

| Après | Ce que Kevin essaie sur le S24 |
|---|---|
| T1 | Sa vraie partie reprise après la migration v2 ; l'ancien APK n'écrase rien. **Validation de la sauvegarde v2.** |
| T5 | Ouvrir, fermer, retour Android, monde figé, cinq cartes, objectif. **Validation du 6.0.** |
| T9 | L'Équipe : lire, réordonner, favori. **Validation du 6A.** |
| T13 | Le Sac : une Potion dans le menu et en combat. **Validation du 6B.** |
| T17 | Le Pokédex avec `--debug-unlock pokedex`, sur sa vraie partie ; puis sans l'option : rien. **Validation du 6C.** |
| T22 | La Carte. **Validation du 6D.** |
| T26 | L'écran Dresseur. **Validation du 6E.** |
| T30 | Les réglages, puis le parcours complet. **Validation du jalon 6.** |

---

## 15. Alignement du T0 (2026-10-02, code fusionné `d8e8f2b`)

Ce qui a bougé entre `c1842e5` (base du plan) et `d8e8f2b` (`main` = `jalon-06` au départ), et ce que le plan en retient :

1. **Capture T15 et rencontres 15 → 20** : déjà dans `c1842e5` (`1b07245`, `cb3da7b` en sont des ancêtres) ; le plan les prenait déjà en compte. Rien à changer.
2. **Départs de débogage `capture_qa` et `team_full`** (`d509854`) : utiles aux QA du J6 (équipe pleine pour 6A, 30 Balls). Leur `bag` garde **sa propre forme plate** (`DebugStart`, appliquée par `Bag.add`) : ce n'est pas le format de sauvegarde, rien à migrer.
3. **Q-8 déjà codée** (`a6d9254`) : capture = première observation ; anciennes entrées corrigées au chargement par `ensure_seen`. Le §5.1 ne la refait pas (une seule règle) ; la migration v1 → v2 laisse `times_seen` tel quel et reste cohérente avec ce correctif (testé sur la vraie sauvegarde, starter à 0 → lu 1).
4. **Entrée en scène et place dans l'équipe** (`24901cb`) : `BattleEvent.party_index` sur tout événement de Pokémon, `Party.index_of`, entrée en scène d'après les `SENT_OUT`. Écart 1 du §10 **corrigé** ; `Party.index_of` retiré du T6 ; `ITEM_USED` (T10) réutilise `party_index`.
5. **Compteur `[perf]`** (`ac13a69`, `PerfCounter`, build debug, `Boot` scène principale) : ligne de fps toutes les 2 s dans le journal ; à utiliser pour les mesures de 60 fps des QA du J6 (T5, T13, T17, T22, T30) au lieu d'estimations.
6. **Test d'XP déterministe** (`230a58e`) : rien pour le J6.
7. **Toujours vrai sur `d8e8f2b`** (vérifié) : 7 appels à `Input.vibrate_handheld` (6 fichiers : `battle_director`, `battle_widget`, `toast`, `interact_button`, `haptic_pattern`, `starter_sheet`) ; `USABLE_IN_WILD_BATTLE = [BALL]` et `BattleViews.bag_entries` ; composants du Sac encore sous `game/ui/battle/` ; `quit_on_go_back` absent de `project.godot` (vrai par défaut) et `Boot` qui sauvegarde sur `NOTIFICATION_WM_GO_BACK_REQUEST`.
8. **Décisions verrouillées de Kevin (§12)** : Q-3, Q-7, Q-9, Q-17 déjà reportées dans §6.2, §3.5, §3.3, T28 ; rien ne touche la sauvegarde v2 (aucun réglage n'y entre, Q-17 compris : GRAPHISMES vit dans `settings.json`, §5.3).

**Choix faits au T0 (petites questions, règle 4)** :
- `acquired` = rang de la **dernière** obtention (chaque `add` rend l'objet le plus récent ; racheter des Potions les remonte) : lecture du défaut de Q-12 « obtenus le plus récemment ». Pour une v1, ordre alphabétique (coïncide avec la vraie partie : Poké Balls de Chen, puis Potion).
- `favorites` dans l'ordre de marquage ; un objet favori absent du Sac le reste (dossier 08 §3).
- Favoris et rangs sont **informatifs** : mal formés, ils sont ignorés sans erreur ; seule une quantité invalide compte comme entrée écartée (copie `.rejected` par `Boot`, comme au J5).
- `SaveSystem.version` (membre) plutôt qu'une copie du code du J5 pour simuler l'ancienne build : la logique de refus est la même (`upgrade` et `Boot._load_save` inchangés depuis le J5).
