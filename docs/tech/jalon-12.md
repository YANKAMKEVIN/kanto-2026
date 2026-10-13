# Jalon 12 — Route 3 et Mont Sélénite

> Objectif jouable sur le téléphone : **le premier donjon**. Depuis la sortie est d'Argenta (le garde
> du J10 laisse passer depuis le badge), la **Route 3** : prairie de la sortie, deux chemins de
> Dresseurs qui se rejoignent, le pied de la montagne, six Dresseurs (deux inévitables), Rondoudou
> sauvage, un objet caché ; le **Centre Pokémon du Mont Sélénite** (point de repos) ; le **Mont
> Sélénite** sur trois étages reliés par des échelles, sombre mais lisible, rencontres sur des
> **gravats** et couloirs calmes, la **Corde Sortie** ; la **Team Rocket** (trois Sbires, qui partent
> après leur défaite), le **chercheur Gaspard**, le **choix définitif d'un fossile**, le **Grand
> moment** ; la **Pierre Lune** (une visible, une cachée) et l'**évolution par pierre** ; enfin le
> **sas de la Route 4** et « AZURIA — À venir ».
>
> Mécaniques nouvelles : terrain de rencontre « gravats », catégorie de carte « grotte », Corde
> Sortie, objets cachés « face à un indice », évolution par objet, cinq effets de capacités (drain,
> piège, Entrave, Repos, Destruction), départ des Sbires, choix à confirmer qui lance une scène.
> **Format de sauvegarde inchangé** : celui que le J11 livre (v6), preuve au §2.20.

**Pré-requis.** Dossier 15 **verrouillé** (2026-10-11 : V-1…V-9, B-1…B-14, C-1…C-8, textes §20,
vues générales et grilles validées) : c'est la **source de vérité**. **C-7** : le code du J12
part **après la clôture du J11** (un seul jalon à la fois dans le moteur de combat et la
sauvegarde) ; la conception, l'art, les grilles — et, d'après la demande de l'appelant, les
**cartes sans combat** — peuvent avancer avant (§1.2, **Q-1**).

Plan écrit sur `docs/plan-j12` depuis `main` à `f73acae` (J10 terminé, OUV.1 et OUV.2 validés,
sauvegarde **v5**). Le J11 est **lu, pas modifié**, sur `origin/claude/lancement-j11-4pkt2k`
(`073769b` : T1 sauvegarde provisoire, T17 conception du compagnon, T18 préparé, compatibilités CT
générées) avec `docs/tech/jalon-11.md`, `jalon-11-compagnon.md` et `dossier-14-systemes-j11.md` de
cette branche. **Chaque tâche d'architecture commence par aligner ce plan sur le code du moment** ;
la première tâche après le J11 (T11) le réaligne sur le J11 réellement fusionné.

> **Réaligné au T11 (2026-10-13)** sur `jalon-12` à `1a3cad5` = `main` à `267fcf1` (**J11 terminé**,
> sauvegarde v6) + T1–T10 du J12. Écarts constatés dans le code et décisions techniques : **§0.4** ;
> règles de branche et de conflit (J13, J14, J15 avancent en parallèle, en aval du J12) : **§1.2**.
> Aucune décision de game design n'a changé.

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/dossier-15-route-3-mont-selenite.md`,
`dossier-14-systemes-j11.md` (statuts, CT, évolution courte, compagnon), `dossier-04` (intro de
rencontre ≤ 2 s), `dossier-05-combat.md`, `dossier-08-menu-dresseur.md` (Sac, Grands moments),
`jalon-10.md` (méthode, kit d'assets, cartes peintes, `pewter_map_kit.gd`), `jalon-08.md` (objets),
`jalon-09.md` (Dresseurs, poison, évolution, budgets), `combat-maquettes.md` (CB.3).

> Téléphone de validation : le **S21** depuis le 2026-10-10 (décision de Kevin, `etat-projet.md`,
> OUV.1). « Session S24 » désigne ici la session téléphone du sous-jalon, quel que soit l'appareil.

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin du dossier (`main` à `f73acae`) et ce que le J11 apporte

> T11 : la colonne « J11 » a été écrite d'après le plan du J11 ; ce que le J11 a **réellement** livré
> (noms, emplacements, écarts) est au §0.3 (colonne « Réalité ») et au §0.4. Là où les deux
> diffèrent, **le §0.4 fait foi**.

| Besoin (dossier 15) | Existant sur `main` (fichiers, fonctions) | Apporté par le J11 (fusionné, voir §0.4) | Manque |
|---|---|---|---|
| Grilles, contrôle | `tools/plans/route_3.txt`, `mont_selenite_1f/b1f/b2f.txt`, `route_4_sas.txt` (validés) ; `plan_check_route_3.py`, `plan_check_mont_selenite.py` ; lecteur `tests/helpers/plan_grid.gd` (ligne `PRATICABLES`, attributs `cle=valeur`, groupes « ; ») | — | deux conventions d'objet caché à unifier (§1.3) |
| Cartes extérieures peintes | `tools/pewter_map_kit.gd` (`_kind_of`, `_paint_logic` : `Ground` invisible = source logique, masque du sol, forêt serrée `DenseForest`, paroi en modules `relief_paroi_01..04`, hautes herbes, décalcomanies) ; `PaintedGround` (**trois textures fixes** : herbe, pavés, chemin) | — | `build_route_3.gd`, `build_route_4.gd` ; texture « sol rocheux » (`o`) |
| Cartes intérieures | `tools/build_painted_interiors.gd` : `_pokemon_center(id, …)` (définition commune Jadielle / Argenta, J10 T13), option `--rooms=` | — | `mt_moon_center` (une ligne + scène) |
| Catalogue, catégories de carte | `MapCatalog` (`scene_path`, `has_map`, `load_interiors` ← `data/world/interiors.json`) ; `GameMap.interior: bool` (`map.gd:45`) lu par `ZoneAnnouncer` (`boot.gd:1045`) et `SceneRouter._neighbor_paths` (`scene_router.gd:317`) | `CompanionRules.is_visible(… map_interior …)` (T17) | catégorie **grotte** (ni bâtiment ni extérieur) |
| Passages, échelles | `Warp` : `STEP_ON` avec `direction = ZERO` = « escalier » (`warp.gd`), `PUSH` ; `SceneRouter.change_map(map, spawn, facing)` (fondu, verrou, `map_changed`, `map_entered`) ; `show_coming_soon(label, return_spawn, facing)` (build debug, inerte en release) ; sortie est d'Argenta `Route3N/C/S` « Route 3 — À venir » (`build_pewter_city.gd:57-63`), spawns `from_route_3_n/c/s` (51, 25..27) déjà là | compagnon : rentre au fondu, ressort derrière le joueur | rien de neuf pour les échelles : **un warp `STEP_ON` sans direction + un décor** |
| Mémoire, préchargement | cache borné du routeur (`_prefetch_neighbors`, `_trim_cache`) ; une carte **extérieure** ne précharge pas ses voisines **intérieures** (J10) | — | une grotte n'est pas « intérieure » : 1F précharge Route 3 + B1F + B2F (à mesurer, §2.21) |
| Rencontres | `EncounterDirector._on_player_moved` → `_can_encounter` (**`grid.is_tall_grass` seulement**, constante `_GRASS_TERRAIN`) → `EncounterTable.roll` → `_play_grass_beat` (`GrassRustle`) ; `EncounterLibrary` indexée par **(carte, terrain)** ; `EncounterTable.TERRAINS = [&"grass"]` ; tables `data/encounters/*.json` (`rate`, `ramp`) | le compagnon ne déclenche rien (écoute du joueur seul) | terrain **`rubble`** (grille, tuiles, tables, intro « éboulis ») |
| Grille logique | `GridWorld` (drapeaux solide, eau, hautes herbes, rebord) ; `OverworldTiles.Kind` (`TALL_GRASS`, `LEDGE_DOWN` ajoutés **en fin d'enum**), données de tuile `solid`, `tall_grass`, `water`, `ledge` ; `GameMap._read_layer` | occupation « douce » du compagnon (T20a) | `Kind.RUBBLE` + donnée `rubble` + `GridWorld.is_rubble` |
| Dresseurs | `TrainerLibrary` / `TrainerData` (`ai` `random` / `smart`, `prize_money`, `moves` choisies, `card`) ; bloc `trainer` des PNJ (`NpcSpec.trainer_id`, `sight`, `before_dialogue`, `defeated_dialogue`) ; `TrainerEncounter.build` (« ! » → approche → face à face → avant → combat `beaten_<id>` → réplique « vaincu » ou « après » → `wake_up` sinon) ; `TrainerRules.sight_distance` ; `TrainerWatcher` ; scènes écrites `data/cutscenes/` (rival, Pierre) | — | réplique de **reprise** après une défaite du joueur, **départ** du Sbire (§2.11) |
| PNJ qui partent | étapes `move` (premier plan / arrière-plan) et `despawn` (fondu `DESPAWN_FADE` 0,2 s) ; présence `if` / `unless` (`NpcRoster`, `GameMap.refresh_npcs` à chaque changement de carte) | — | branchement dans la séquence des Dresseurs |
| Objets au sol | PNJ `object/poke_ball_ground` + scène `despawn` → `give … found: true` → `set got_<id>` (`data/cutscenes/route_2_north.json`) ; `GameState.found_items` = **journal** `{item, map, date}` (`game_state.gd:164`) ; l'état « trouvé » est le **drapeau** `got_<id>` | — | — |
| Objets cachés | J5/J8 : `EventTriggerPoint` **sur la case** (on marche dessus) → scène `give found` | — | « **face à un indice** » (B-10) : point d'examen qui **disparaît une fois trouvé** ; `InteractionFinder.find` ne connaît aucun drapeau (§2.8) |
| Bouton contextuel | `InteractButton` invisible sans cible ; `Boot._on_target_changed` le montre face à **toute** cible | — | conflit avec « aucun indicateur d'interface » → **Q-2** |
| Sac | catégories `BALL HEAL BATTLE FIELD KEY` (`item_data.gd`), onglets SOINS / CAPTURE / COMBAT / AVENTURE / OBJETS CLÉS (`bag_entry_view.gd`) ; **aucun objet FIELD** ; `ItemUse` = soins donnés à un Pokémon ; `BagQuery`, `PartyPicker`, `UseResultBar` | catégorie **CT**, `permanent`, `teaches`, états COMPATIBLE / DÉJÀ CONNUE / INCOMPATIBLE du sélecteur (T11–T12) ; Anti-Para, Réveil (T8) | usage d'un objet AVENTURE **sans cible** (Corde) et **avec cible** (pierre) ; la catégorie « OBJETS » du dossier §10 n'existe pas (§0.2 n° 6) |
| Boutique d'Argenta | `data/shops/pewter_mart.json` (Ball, Potion, Antidote), `ShopLibrary` (stock `if` / `unless`) | Anti-Para, Réveil, Anti-Brûle ajoutés (T8) | Corde Sortie 550 ₽ |
| Évolution | `Evolution.item_target(pokemon, item_id, data)` **existe, jamais appelé** ; `EvolutionRule.Method.ITEM` ; règles `moon_stone` déjà dans `kanto.json` (Nidorina, Nidorino) ; `EvolutionDirector.play(candidates, party)` (après combat) ; ARRÊTER toujours proposé (`evolution_stop`) | séquence courte ≈ 6 s, accélération au toucher (11C) | lancement depuis le Sac, **sans ARRÊTER**, pierre retirée au moment exact de l'évolution |
| Capacités | 66 capacités (`moves.json`) ; `MoveEffect.Kind` `STAT_STAGE RECOIL SEED STATUS` ; `pending_effects` : `self_ko` (Destruction, Explosion), `trap` (Étreinte, Danse Flamme) ; un learnset ne peut citer qu'une capacité connue (`PokemonData`, l. 520) | `status` aux 5 statuts, `confusion`, `hits`, `flinch`, `crit_up`, `fixed_damage` ; `can_act` ; Patience (`locked_move`, `get_usable_moves` / `is_legal`) ; événements et textes de statut (11A, 11B) | `drain`, `trap`, `disable`, `rest`, `self_ko` ; 21 capacités nouvelles |
| Statuts | poison seul (`status_rules.gd`) | paralysie, sommeil (compteur `Pokemon.status_turns`), brûlure, gel, confusion | Repos s'appuie sur le compteur du J11 |
| Espèces | 38 espèces (`kanto.json`), types **modernes** (18, Fée comprise : `types.json`), stats actuelles, apprentissages de Rouge/Bleu ; artworks officiels **001–151** (`assets/sprites/pokemon/official/`) ; sprites provisoires de face / dos (`gen_placeholder_battlers.gd`, exigés par `test_battle_stage` pour toute espèce de Dresseur) | compatibilités CT des 38 espèces (`data/pokemon/tm_compatibility.json`, `tools/gen_tm_compatibility.py`) | 12 espèces, Pokédex, compatibilités CT, sprites provisoires ; **icône du type Fée** (neutre aujourd'hui, `combat-maquettes.md` Q2) |
| Grands moments | `MomentLibrary.TYPES` (`starter`, `rival_battle`, `first_capture`, `zone_arrival`, `badge`) ; `data/trainer/moments.json` (titre + détail) ; arrivées de zone **seulement** pour les zones qui ont un texte (`zone_arrivals`) ; l'étape `badge` enregistre son moment | — | type `fossil` et une étape qui l'enregistre |
| Objectifs | `data/story/objectives.json` (première entrée valide l'emporte ; `go_route_3` en tête) | — | 2 entrées |
| Zones, points de repos | `zones.json` : `route_3`, `mt_moon`, `route_4` **déjà déclarées, sans carte** ; `rest_points.json` (toast « Point de repos enregistré — <titre de la carte> ») | — | cartes, services, descriptions ; entrée `mt_moon_center` |
| Lumière | `lighting.json` : `golden_hour`, `interior_warm`, `forest` (étalonnage global, liseré, ombres portées, ombres de contact, vent) ; **aucune `Light2D`** dans `game/` ; `WorldClock` **inactive** (phase 10) : il n'y a de jour/nuit nulle part | — | profils de grotte, halos légers (§2.4) |
| Décors de combat | `data/battle/decors.json` : un décor (`route_1_chemin`) ; `BattleDecorCatalog.pick(map_id, cell)` (variante locale par cases), repli = carte floutée ; production `tools/art/combat_decors/` | — | `route_3_roche`, `mt_moon_galerie`, `mt_moon_chambre` |
| Pokédex | `data/pokedex/kanto.json` (taille, poids, description, notes des formes de base) | — | 12 fiches |
| Compagnon | **rien sur `main`** | `CompanionRules`, `CompanionTrail`, `companions.json` (`species`, **`contexts`** carte → contexte de phrase), `data/dialogues/companion.json`, masquage sans case libre, rappel aux fondus et scènes (D-1, D-2) | contexte « grotte », planches C-4 |
| Sauvegarde | **v5** (OUV.1 : `rival_name`, `player_look`) ; règle d'en-tête de `save_system.gd` ; `Boot._keep_rejected_save` (entrée inconnue d'une build → `save.json.rejected`) | **v6** : `Pokemon.uid`, `status_turns`, `companion` (T1, numéro provisoire) | rien (§2.20) |
| Départs de QA | `tools/debug_start/*.json` + README (`moves`, `status`, drapeaux, Sac, argent) | `status_qa`, carte `qa_status` (retirée à sa clôture) | départs du J12, carte `qa_moves_j12` |
| Son | **aucun `AudioStreamPlayer`** dans `game/` ; points d'accroche (`cry_requested`) | — | point d'accroche « pierres qui roulent » |

### 0.2 Écarts et trous constatés

1. **Échelles** : aucun « nouveau type de passage » n'est nécessaire (dossier §5.1) : `Warp.STEP_ON` avec `direction = ZERO` est déjà l'escalier ; le fondu est celui des portes. Seuls le décor (trou + échelle) et les points d'arrivée sont nouveaux.
2. **Terrain « gravats »** : à créer de bout en bout (tuile, grille, table, intro). L'architecture (table par couple carte / terrain) le prévoyait déjà.
3. **Catégorie « grotte »** : `Map.interior` est un booléen. Les trois usages de la catégorie (Corde Sortie, phrase du compagnon, futur jour/nuit) et la règle « compagnon visible » tiennent avec **`interior = false`** sur les étages + une **liste de grottes en données** (§2.3) : aucun champ de scène nouveau, et la logique du compagnon du J11 marche telle quelle.
4. **Objets cachés** : deux conventions dans les grilles (Route 3 : `cache` = la case-indice elle-même, `bloque` ; grotte : `objet_cache` = case où l'on se tient, `libre`, indice `x` voisin). Règle unique au §1.3. Le point d'examen doit **disparaître une fois l'objet trouvé** (sinon EXAMINER reste sur le caillou) : `Interaction` ne connaît aucun drapeau aujourd'hui.
5. **Bouton contextuel** : sur téléphone, on n'interagit qu'avec le bouton contextuel, qui n'apparaît **que face à une cible** — donc face à l'indice. Le dossier dit « aucun indicateur d'interface » → **Q-2** (défaut : EXAMINER apparaît face à l'indice, comme pour tout décor examinable ; aucun scintillement, aucun son).
6. **« Catégorie du Sac OBJETS »** (dossier §10, [D]) : elle n'existe pas (SOINS, CAPTURE, COMBAT, AVENTURE, OBJETS CLÉS ; + CT au J11). Défaut : **AVENTURE** (« en exploration seulement ») pour la Pierre Lune et la Corde Sortie.
7. **Choix OUI / NON du fossile** : `DialogueChoice.confirm_action` n'accepte que `heal`, `center_heal`, `open_shop`, `open_storage` : il faut un choix qui **lance une scène** (§2.13).
8. **Reprise après une défaite** (§20 : R1, R2, R3, chercheur) : rien ne mémorise qu'on a perdu contre un Dresseur ; un drapeau `lost_<id>` posé par l'issue du combat (`lose_flags` existe dans l'étape `battle`) suffit, format inchangé.
9. **Toast « {fossil} obtenu »** (§20 n° 27) : le toast d'un objet clé est aujourd'hui « <NOM> — ajouté aux objets clés ». Le J11 introduit « CT34 — Patience obtenue » (dossier 14 §13 n° 40) : **réutiliser sa forme** (alignement T11). **T11** : `ItemData.added_text` ne donne « obtenu[e] » qu'aux CT → champ de donnée `obtained` (§0.4 n° 7, §2.13).
10. **Repos « dort deux tours »** : la valeur exacte du compteur dépend de la sémantique de `status_turns` du J11 (« baisse à chaque tentative, au réveil il agit dans le même tour ») ; le test fixe le résultat (manque exactement 2 tours, agit au 3e), pas le nombre. **T11** : sémantique confirmée dans `StatusRules.check_act` → `status_turns = 2` (§0.4 n° 1).
11. **Ligotage / Étreinte / Danse Flamme** : les messages validés (§20 n° 46) nomment le Ligotage (« souffre **du** Ligotage ») ; les deux autres ont besoin de leurs propres textes (élision, genre) → messages **par capacité** en données, brouillons à l'annexe A (non atteignables au J12 : Onix n'est pas capturable, Danse Flamme arrive au Nv. 46).
12. **Fuite et changement refusés quand ligoté** : la fuite réutilise « Impossible de fuir ! » (`flee_failed`, existant) ; le changement a besoin d'une raison sur les cartes de l'équipe (brouillon, annexe A).
13. **Fée** : Mélofée et Mélodelfe (Fée), Rondoudou et Grodoudou (Normal/Fée), types modernes décidés au J4 : **premiers Pokémon Fée** → l'icône du type (neutre aujourd'hui) devient nécessaire (ui-mobile).
14. **Pokédex** : le §20 renvoie les 12 descriptions « au plan » → **annexe A** (et 7 notes des formes de base, comme au J10).
15. **Sas = carte `route_4`** : pour que le J13 « remplace le sas en gardant le point d'arrivée », l'identifiant est **`route_4`** dès le J12 (aucune position sauvegardée à migrer). Le J13 devra garder le **repère de coordonnées** du sas (une partie sauvegardée en (10, 7) du sas doit retomber sur une case praticable) — noté pour la passation.
16. **Pokémon d'ambiance de la grotte** : la vue peinte montre Nosferapti, Racaillou, Mélofée et Paras ; ni la grille ni le dossier n'en placent → **non implémentés** (règle 10).
17. **Décor de combat « chambre » pour R3** : R3 se tient dans le **couloir** (29, 24), pas dans la chambre ; la variante locale couvre couloir + chambre (cases, §2.18).
18. **Sbires qui « disparaissent au fondu suivant »** : lecture retenue (règle 4) — il marche quelques cases puis s'efface par le fondu de l'étape `despawn` ; s'il ne peut pas s'éloigner (R1 dans sa niche), il s'efface sur place ; absent ensuite par `unless beaten_<id>` (§2.11).
19. **Budget de nœuds de la Route 3** : 82 × 38 (3 116 cases, contre 2 288 pour Argenta), forêt sur ≈ la moitié des cases ; la Forêt de Jade est à 2 983 nœuds pour 3 000 → **risque mesuré dès la première construction** (T8).

### 0.3 Ce que le J12 attend du J11 (et repli)

| Livraison du J11 | Pour | Si elle manque ou diffère | **Réalité (T11, `main` à `267fcf1`)** |
|---|---|---|---|
| 11.0 : v6, `status_turns` | Repos ; version écrite par le J12 | le J12 suit la version de `main` à T11 | **livrée** : `SaveSystem.VERSION = 6` ; `Pokemon.status_turns` (sommeil seul, borné à 7 à la lecture). Repli inutile ; Repos : §0.4 n° 1 |
| 11A : 4 statuts, confusion, `hits`, `flinch`, `can_act`, textes | toutes les espèces du J12 (Berceuse, Spore, Ultrason, Onde Folie, Regard Médusant, Torgnoles, Morsure, Para-Spore) | rien ne joue juste : **bloquant** (C-7) | **livrée** : `StatusRules.KNOWN` (poison, paralysie, sommeil, brûlure, gel), confusion `Battler.confusion_turns`, `MoveEffect.Kind` `CONFUSION HITS FLINCH CRIT_UP FIXED_DAMAGE`, `Battle._can_act`. Écart : **pas de `data/battle/status.json`** (valeurs en constantes de `status_rules.gd`, écart assumé du J11 T4) — §0.4 n° 2 |
| 11A : Anti-Para, Réveil | objets de la Route 3 et de la grotte | bloquant pour 12A | **livrée** (+ Anti-Brûle ; Antigel prêt, pas vendu) ; stock de Jadielle et d'Argenta |
| 11B : catégorie CT, `teaches`, `permanent`, états du sélecteur | CT01 ; libellés COMPATIBLE / INCOMPATIBLE de la pierre | la pierre affiche ses états seule (même composant) | **livrée** : `ItemData.Category.TM`, `tm_number`, `teaches`, `is_tm()`, `is_permanent()` ; `TmTeach.Check { COMPATIBLE, KNOWN, INCOMPATIBLE }` ; `PartyTargetView.show_reason` ; parcours `MenuDirector.tm_learn_requested` → Boot → `TmLearnOverlay`. Réutilisés tels quels (§2.9) |
| 11B : `get_usable_moves` / `is_legal` (Patience) | Entrave (capacité exclue des choix) | ajouter le filtre au T13 | **livrée, autrement** : Patience sur le **`Battler`** (`bide_stage`, `bide_slot`, `bide_stock`, `is_biding()`), `Battle.get_locked_move()` ; `get_usable_moves()` délègue à **`Battler.usable_moves()`**, que lit aussi l'IA. Pas de `locked_move` sur `BattleSide` — §0.4 n° 3 |
| 11C : évolution courte | évolution par pierre | séquence actuelle (≈ 9 s), sans ARRÊTER | **livrée** : transformation 2,5 s (≈ 4,5 s mesurées sur téléphone, gardé par Kevin), `EvolutionScreen.rush()`. Écart : **pas de `EvolutionCandidate.cancellable`** (créé au T23, §2.9) |
| 11D : compagnon, `contexts`, masquage | catégorie grotte, planches C-4 | le J12 se passe du compagnon (critères 12B retirés) | **livrée** : `CompanionCatalog`, `CompanionRules`, `CompanionTrail`, `CompanionController`, `companions.json` (12 espèces). Écarts : contexte « grotte » **pas en données seules** ; placement à l'arrivée **possible sur un warp** — §0.4 n° 5 et 6. Critères 12B gardés |
| T18 (série 13) validée | main et gabarit des planches C-4 | planches C-4 ancrées sur les starters de la série 09 | **partielle** : Herbizarre, Carabaffe, Papilusion validés ; Reptincel et Pikachu hors du lot (A-11). Sans effet sur le J12 (T3 fait : 11 planches) |
| 11A T9 : carte `qa_status` | modèle de `qa_moves_j12` | — | **jamais construite** (départ `status_qa` + clé `wild` de `DebugStart`) — §0.4 n° 4, §2.22 |

### 0.4 Alignement sur le J11 livré (T11, 2026-10-13) — écarts et décisions techniques

Vérifié dans le code de `jalon-12` à `1a3cad5`. Chaque écart reçoit une décision **technique** (règle 4) ;
aucune ne touche au game design.

1. **Repos et le compteur de sommeil.** `StatusRules.check_act` : tant que `status_turns > 0`, il
   baisse et le Pokémon ne fait rien (ASLEEP) ; à 0, `cure_status()` et il agit le même tour
   (WOKE_UP). `StatusRules.apply(SLEEP, …)` **tire** 1–3 tours (`sleep_turns`). → Repos pose
   `status = sleep` et **`status_turns = 2`** sans tirage (fonction pure nouvelle
   `StatusRules.apply_rest(pokemon)`, en fin de fichier) : manque exactement 2 tentatives, agit à la
   3ᵉ. Il ne passe pas par `can_inflict` (qui refuserait : ALREADY) : il soigne d'abord.
2. **`data/battle/status.json` n'existe pas** (valeurs du J11 en constantes de `StatusRules`, comme
   le poison du J9). → Les valeurs des effets du J12 (fraction du drain, tours du piège, d'Entrave)
   vivent **dans les données de capacité** (`effects`), comme prévu au §2.10 ; aucun fichier de
   statuts créé.
3. **Volatils sur le `Battler`.** La confusion (`confusion_turns`) et Patience (`bide_*`) sont des
   champs du `Battler`, perdus avec lui (changement, K.O., fin de combat), jamais sauvegardés. →
   Piège et Entrave y vont aussi : `trap_turns`, `trap_move` (identifiant, pour les messages par
   capacité), `trap_source: Battler` (fin du piège quand le lanceur quitte le terrain),
   `last_move_slot` (−1), `disabled_slot` (−1), `disabled_turns`. **Entrave** : exclue dans
   `Battler.usable_moves()` → `Battle.get_usable_moves()`, `is_legal()` et `BattleAI.choose` (qui lit
   `own.active.usable_moves()`) sont couverts d'un coup ; `Battle.get_disabled_move() -> int`
   (ou `NO_LOCK`) pour l'interface ; « échoue sur une cible en Patience » = `is_biding()`.
   **Piège** : le changement se refuse dans `is_legal(SWITCH)` (pas dans `check_switch`, que
   `replace` utilise après un K.O. : le remplacement forcé reste permis) ; `Battle.is_player_trapped()`
   donne la raison aux cartes de l'équipe.
4. **Pas de carte `qa_status`** (J11 T9 : départ `status_qa` + clé `wild` →
   `EncounterLibrary.override_grass`). → `qa_moves_j12` garde son rôle (un Dresseur `smart` ne se
   force pas par une clé de départ) mais prend pour **modèle la carte de QA du J13**,
   `qa_switch_j13` (branche `j13-t14` à `3d58fe6` : `tools/build_qa_switch_j13.gd`, données
   `data/{npcs,trainers,dialogues}/qa_*.json`, `MapCatalog.QA_PREFIX` / `is_qa_map`, exception
   datée dans `test_map_catalog.test_no_qa_map_is_shipped`). **Sans gravats** : les gravats se
   valident en 12B sur le vrai 1F (départ `mt_moon_1f` ; la clé `wild` accepte un `terrain`, T20).
5. **Contexte « grotte » du compagnon : pas « données seules ».** `CompanionCatalog.CONTEXTS =
   [forest, city]` refuse un contexte inconnu et `CompanionRules.CONTEXT_LINES` associe contexte →
   phrase dans le code. → T20 : `CONTEXTS += cave`, `CONTEXT_LINES[cave] = companion_cave` ; T21 :
   `companions.json` (`contexts` des trois étages), `data/dialogues/companion.json`
   (`companion_cave`, §20 n° 40), liste `PLAYED_BY_COMPANION` de `test_dialogue_data`.
6. **Placement du compagnon à l'arrivée.** `CompanionTrail.place_after_arrival(cell, facing,
   is_free)` reçoit de `CompanionController` (l. 290) `grid.is_free(c)` ; une case de warp
   `STEP_ON` est libre → il peut être posé **sur l'échelle**. → T20 : le Callable du contrôleur
   ajoute `_map.get_warps().get_at(c).is_empty()` (aucun changement de `CompanionTrail`, qui reste
   pur) ; sinon il apparaît au premier pas (règle du J11).
7. **Toast d'un objet clé.** `ItemData.added_text` : « obtenu[e] » pour les CT seulement, « ajouté[e]
   aux objets clés » pour un objet clé. → Champ de donnée booléen **`obtained`** (facultatif, en fin
   des champs d'`ItemData`, lu par `ItemLibrary`) : vrai → toast « <nom> » / « obtenu[e] » comme une
   CT. Les deux fossiles l'ont (§20 n° 27) ; le toast des CT ne change pas.
8. **Sonicboom.** `MoveEffect.FIXED_MODES = [half_hp, level]`. La description validée (annexe A.2 :
   « inflige toujours les mêmes dégâts », **sans** la mention « Sans effet ») suppose l'effet → mode
   **`value`** + clé `amount` (20), en fin de liste (T13) ; T12 écrit d'abord la capacité en
   `pending_effects: ["fixed_value"]`, T13 l'active.
9. **États du sélecteur.** `TmTeach.Check` a trois états (COMPATIBLE, KNOWN = « DÉJÀ CONNUE »,
   INCOMPATIBLE) et `PartyTargetView.show_reason` les affiche tous. → La pierre a son propre
   `StoneUse.Check { COMPATIBLE, INCOMPATIBLE }` (jamais « déjà connue ») et réutilise
   `show_reason` et les libellés de `BagQuery` (§2.9).
10. **Évolution hors combat.** `EvolutionDirector` appartient à Boot (`boot.gd` l. 235–247, écran
    `EvolutionScreen` partagé), `play(candidates, party)`, `handle_back()`, signaux
    `evolution_started(party_index, into)` et `evolution_finished(party_index, into, cancelled)`.
    ARRÊTER vit dans `EvolutionScreen.transform()` d'après l'`EvolutionView`. → `cancellable` est
    recopié du candidat dans la vue ; `play_item` = `play([candidate], party)` d'un candidat non
    annulable + `item_id` ; **c'est Boot**, pas le `MenuDirector` (le menu est déjà fermé), qui
    retire la pierre dans `evolution_applied` (§2.9). Modèle du parcours : `tm_learn_requested`.
11. **Noms réels** (lus au T11) : `BattleEvent.Kind` finit par `BIDE_BROKEN` ; `DRAINED` existe et
    désigne **Vampigraine** → les noms nouveaux du §2.10 (`DRAINED_HP`…) restent distincts ;
    clés de messages existantes réutilisées : `move_failed` (« Mais ça échoue ! »), `flee_failed`
    (« Impossible de fuir ! »), `fainted` ; `hp_restored` (« récupère {amount} PV. ») **n'est pas**
    le texte du drain (§20 n° 46) → clé nouvelle. `DialogueRunner.cutscene_requested` **existe
    déjà** (variantes `cutscene`) : `confirm_cutscene` le réutilise. `CutsceneStep.Kind` finit par
    `BADGE` ; l'étape `badge` (`BadgeMoment.TYPE`) est le modèle de l'étape `moment` ;
    `GameState.record_moment(type, map, details)` existe. `NpcRoster.TRAINER_KEYS = [id, sight,
    before, defeated]`. `TrainerEncounter.build(npc_id, spec, distance)` ne voit pas les drapeaux
    → la réplique de reprise passe par les **conditions d'étape** existantes (§2.11).
    `EncounterDirector._GRASS_TERRAIN`, `_can_encounter`, `EncounterTable.TERRAINS`,
    `EncounterLibrary.override_grass` sont dans `game/pokemon/encounters/`. `BagQuery` est dans
    `game/systems/menu/`. `LightGlow.set_reduce_motion` n'est **pas** branché
    (`Boot._apply_settings`, l. 1422) → T20.
12. **Points ouverts hérités** (inventaire du J11 T22) qui touchent le J12 : mémoire des textures
    déjà à 118–135 Mo sur la Route 1 et en combat (S21) ; Forêt de Jade à 48–49 fps en combat de
    Dresseur (S21) ; `test_rival_route22` instable sous charge. → mesures du J12 **relevées avec
    une référence J11 de la même session et du même téléphone** (§2.21) ; l'instabilité connue
    n'est pas une régression du J12 (relance seule, comme au T8).

---

## 1. Découpage

### 1.1 Sous-jalons et validations (B-14)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **12.0-art** | kit d'assets (série 14), planches Pokémon C-4 + lot parallèle, décors de combat, icônes d'objets | **Kevin, sur planches de contact** (pas de téléphone) |
| **12.0** | données des 12 espèces et des 21 capacités, Pokédex, CT ; moteur : drain, piège, Entrave, Repos, Destruction ; carte de QA `qa_moves_j12` | **S24** (combats de test) |
| **12A** | Route 3 (décor, raccord Argenta), Centre du Mont Sélénite, 6 Dresseurs, rencontres d'herbes, 3 objets visibles, **objets cachés** (Réveil) | **S24** |
| **12B** | Mont Sélénite 1F / B1F / B2F (décor, lumière, échelles), **gravats**, **catégorie grotte**, compagnon dans la grotte, **Corde Sortie** (au sol, à Argenta) | **S24** (lisibilité **sans monter la luminosité**) |
| **12C** | Team Rocket (R1, R2, R3 et leurs départs), chercheur, choix du fossile, objets clés, Grand moment, Pierre Lune visible et cachée, **évolution par pierre**, CT01 | **S24** |
| **12D** | sas de la Route 4, « AZURIA — À venir », objectifs, retrait de la carte de QA ; **QA finale** Argenta → sas en vraie partie, reprise dans la grotte | **S24** + fusion |

- **Jamais trois systèmes à la fois** : 12.0 = un système (effets de capacités) + des données ; 12A = un système neuf (objets cachés) sur des systèmes existants ; 12B = deux systèmes neufs (gravats ; grotte + Corde, liés) + du décor ; 12C = deux systèmes neufs (événement Rocket / fossile ; évolution par pierre), le reste étant des données sur les systèmes du J9–J11 ; 12D = du contenu et la QA.
- **Aucune validation de sauvegarde isolée** : le format ne change pas (§2.20). La reprise dans la grotte est un critère de 12B, 12C et 12D.

### 1.2 Branches et conflits (réécrit au T11, 2026-10-13)

**La restriction « fichiers du J11 » tombe** : le J11 est clos et fusionné (`main` à `267fcf1`),
OUV aussi (OUV.3 validé le 2026-10-11). `jalon-12` contient `main` depuis `1a3cad5` (T11). Tout le
code du jeu est ouvert au J12 — sous les règles ci-dessous, qui tiennent compte de **qui d'autre
travaille** (relevé `git log origin/main` et branches locales, 2026-10-13) :

| Qui | Branche | Base | Fichiers communs avec le J12 (code et données) |
|---|---|---|---|
| personne sur `main` | `origin/main` = `267fcf1` | — | dernier commit = clôture du J11 |
| reliquat d'art du J11 (Reptincel, Pikachu compagnons) | `j11-pikachu-compagnon` | `main` (aucun commit encore) | `data/pokemon/companions.json`, `tools/art/manifeste.json`, `build_character_frames.gd` (`LOOKS`), `assets/world/catalogue.json` — comme T21 |
| **J13** (Azuria) | `jalon-13` | **`jalon-12` à `5b3fe9b`** + `main` à `ee5d5c9` (11A, 11B) ; code déjà avancé (T11 données, T12 IA qui change, T13, T14 carte de QA, T16 briques) | `battle.gd`, `battler.gd`, `battle_ai.gd`, `battle_event.gd`, `battle_text.gd`, `battle_director.gd`, `battle_stage.gd`, `trainer_data.gd`, `item_data.gd`, `dialogue_choice.gd`, `dialogue_library.gd`, `dialogue_runner.gd`, `cutscene.gd`, `cutscene_library.gd`, `map_catalog.gd`, `boot.gd` ; `moves.json` (**5 capacités du J12 déjà copiées** : `acid`, `wrap`, `smokescreen`, `minimize`, `light_screen`), `kanto.json`, `pokedex/kanto.json`, `messages.json`, `items.json`, `tm_compatibility.json`, `zones.json`, `lighting.json`, `decors.json` ; `test_route_4` (réécrit : la Route 4 remplace le sas) |
| **J14** (Route 25) | `jalon-14` | `main` à `ee5d5c9` | `battle.gd`, `battler.gd`, `battle_event.gd`, `battle_text.gd`, `battle_ai.gd`, `move_effect.gd`, `move_data.gd`, `pokemon_data.gd`, `cutscene_step.gd`, `cutscene_library.gd`, `cutscene_director.gd`, `dialogue*.gd`, `npc_spec.gd`, `npc_roster.gd`, `map.gd`, `ui_tokens.gd`, `boot.gd`, `light_glows.json` ; ses données sont dans des **fichiers à part** (`moves_j14.json`, `kanto_j14.json`, `items_j14.json`) ; son plan : « le J14 fusionne en dernier, il absorbe les conflits » |
| **J15** (Carmin) | `jalon-15` | `main` à `ee5d5c9` + `origin/main` | **sauvegarde v7** (`save_system.gd`, `game_state.gd`, la Pension), `debug_start.gd`, `boot.gd` ; données à part (`kanto_vermilion.json`, `vermilion.json`…) |

**Ordre de fusion dans `main` : le J12 d'abord.** Les J13, J14 et J15 dépendent de lui (espèces,
`drain` / `trap`, `unless_flags`, `field_use`, `confirm_cutscene`, étape `moment`, `play_item`,
Corde Sortie) et l'ont écrit dans leurs plans. D'où :

1. `jalon-12` ne fusionne **que `main`** — jamais `jalon-13/14/15` (ce sont eux qui fusionnent
   `jalon-12`). Si une autre fusion arrive dans `main` avant la fin du J12 (non prévu ; ex. la v7 du
   J15), `jalon-12` fusionne `main` aussitôt et suit sa version de sauvegarde (§2.20).
2. **Noms figés** (cités par les plans des J13–J15) : `MoveEffect.Kind` `DRAIN TRAP DISABLE REST
   SELF_KO` **en fin d'enum, dans cet ordre** (le J15 met `COINS` après, le J14 ses genres après) ;
   clés de données `drain`, `trap`, `disable`, `rest`, `self_ko` et `pending_effects` `drain`,
   `trap` ; `ItemData.field_use` ; `InteractPoint.unless_flags` ; clés `rematch`, `leave` du bloc
   `trainer` ; `DialogueChoice.confirm_cutscene` ; `CutsceneStep.Kind.MOMENT` / `"moment"` ;
   type de moment `fossil` ; `EvolutionDirector.play_item`, `EvolutionCandidate.cancellable`,
   signal `evolution_applied` ; `escape_rope`, `moon_stone`, identifiants des 12 espèces.
   Tout écart se note au §0.4 **et** dans `etat-projet.md` (section J12), que les autres sessions
   lisent.
3. Ajouts **en fin** d'enum, de liste de clés, de fichier (`battle.gd` : points d'accroche courts,
   fonctions nouvelles en fin de fichier ; tests dans des fichiers nouveaux) ; aucune
   réorganisation, aucun renommage de l'existant.
4. **Données nouvelles dans des fichiers à part** quand le chargeur lit tout un dossier
   (`PokemonData` : tous les `.json` de `species/` et `moves/` ; `ItemLibrary` : `data/items/` ;
   `TrainerLibrary`, `ShopLibrary`, `EncounterLibrary` : un dossier) [D, convention des J14–J15] :
   12 espèces → `data/pokemon/species/kanto_mt_moon.json`, 21 capacités →
   `data/pokemon/moves/mt_moon.json`, 5 objets → `data/items/mt_moon.json`. Les retouches
   d'entrées existantes (`bind`, `fire_spin`, `self_destruct`, `explosion`, stock d'Argenta) restent
   dans leur fichier. Un identifiant défini dans deux fichiers est **refusé** par le chargeur
   (« identifiant déjà défini dans … ») : un doublon avec le J13 se verra au premier test après sa
   fusion, et c'est au J13 de retirer les siens (sa règle, `jalon-13.md` §0.5). Le T12 reprend les
   5 définitions déjà copiées par le J13 **à l'identique** (vérifiées au T11 : conformes à l'annexe A
   et au §20).
5. Fichiers uniques partagés (« garder les deux côtés ») : `data/pokedex/kanto.json`,
   `data/battle/messages.json`, `companions.json`, `zones.json`, `decors.json`, `lighting.json`,
   `light_glows.json`, manifeste, catalogue, `LOOKS`. **`tm_compatibility.json` est généré**
   (`tools/gen_tm_compatibility.py`) : en cas de conflit, le régénérer après la fusion, ne jamais le
   fusionner à la main.
6. Carte de QA : le T15 reprend **mot pour mot** le `MapCatalog.QA_PREFIX` / `is_qa_map` du J13
   (`3d58fe6`) pour que la fusion soit triviale.

**Règles internes inchangées** : une branche par tâche (`j12-t<n>-<sujet>`) depuis `jalon-12`,
fusionnée dans la copie d'intégration (mémoire « worktree d'intégration ») ; `jalon-12` jamais dans
`main` avant le T28 ; jamais de `pkill` ; chaque tâche met à jour `etat-projet.md`.

**Tâches T0–T10** (avant la clôture du J11) : **toutes faites** et fusionnées dans `jalon-12` (§3,
§9). Parallélisme à partir du T11 : §3 (« Ordre et parallélisme »).

### 1.3 Grilles : lecture et normalisations (aucune grille modifiée)

Les grilles font foi (règle 10) ; leurs `POSITIONS` sont des défauts « ajustables au plan ». Ce plan **ne déplace rien** ; il fixe la lecture des outils de construction (T8, T9) :

1. **Objet caché** : le point d'examen est **toujours sur la case de l'indice** (bloquée, décor). Route 3 : la position `cache` **est** l'indice (36, 18), examinable depuis (35, 18), (37, 18), (36, 19). Grotte : l'indice est la case `x` voisine de la position `objet_cache` (1F (57, 19) depuis (56, 19) ; B2F (36, 12) depuis (35, 12)) — la case `objet_cache` est celle où l'on se tient. Drapeau `got_<identifiant de la position>`.
2. **Points d'apparition sur plusieurs cases** : un spawn par case, suffixes `_n / _c / _s` (raccord d'Argenta, trois rangées, comme le J10) et `_w / _e` (entrée de la grotte, porte du Centre). La Corde Sortie vise `from_mt_moon_w` (73, 10).
3. **Échelles** : `WarpPoint` `STEP_ON`, `direction = ZERO`, vers le `spawn` de même `paire=` sur l'autre étage ; orientation à l'arrivée = à l'opposé de l'échelle (case du spawn − case de l'échelle).
4. **`scene=oui`** : R3 = séquence de Dresseur ordinaire dont la réplique « avant » fait 3 bulles (§20 n° 18) ; le chercheur = scène lancée par un déclencheur (§2.12). **`apres=15,30`** = seconde entrée de PNJ `if beaten_mt_moon_researcher`.
5. **Déclencheurs** (défauts) : `route_3_entered` sur (1, 25..27), toute direction ; scène du chercheur sur (25..26, 27) (bas du couloir, seul accès à la chambre), pas vers ↓ ; `route_4_reached` sur (4, 5..9) (toute la largeur du sas).
6. **Repères bloqués** (`repere`, `examen`, `fossile`) : cases solides de `Ground` ; les décors posés dessus ne touchent jamais une case praticable (règle de `pewter_map_kit.add_prop_at`).
7. **Écarts des vues non reproduits** (dossier 15) : montagne beige → ardoise et gris bleuté vers l'est ; Fillette à la jonction ; randonneur près du puits de jour (34, 38) ; Pokémon d'ambiance de la grotte absents (§0.2 n° 16) ; fossiles = images des objets officiels, pas les formes peintes sur la vue.

### 1.4 Kit d'assets : liste précise (méthode des J8–J10)

**Consigne de Kevin (J8–J10)** : le plus petit kit modulaire qui donne la **sensation** des vues validées dans Godot, sans répétition visible. Vues : `reference/route-3-vue-generale-v1.png`, `mont-selenite-vue-generale-v1.png` (essais 2) ; **la grille fait foi**. Série **14** (12 = Argenta, 13 = compagnon du J11), **lumière neutre (NE)** pour les objets et personnages ; la lumière de la grotte est **dans la valeur peinte** des sols et parois (clair au sol, sombre en masse) et dans les halos du moteur (§2.4), jamais dans une ombre portée peinte. Ancres de style : la vue d'Argenta et les modules `relief_paroi_*` (série 12) pour la roche, une planche de PNJ peint pour les personnages, `charmander_frames` / série 13 pour les Pokémon. Liste finale, fiches et prompts : **T1** (`docs/design/fiches-assets/serie-14-mont-selenite.md`, `tools/art/serie14.py`).

**A. Réutilisés tels quels**

| Rôle | Asset(s) |
|---|---|
| Sols de la Route 3 et du sas | `ground_herbe_01`, `ground_chemin_01` (masque G), décalcomanies `decal_touffe_*`, `decal_terre_*`, fleurs `decal_fleur_*` (de plus en plus rares vers l'est) |
| Forêt et bosquets (`T`) | `tree_foret_01..08` par `DenseForest` (+ `Shade` : de plus en plus sec vers l'est) + `ForestFloor` |
| Hautes herbes H1–H4 | `ground_hautes_herbes_jaune_01` (+ `_bas`) |
| Rebords L1, L2 | `relief_rebord_01` |
| Rochers, affleurements (`R`), buissons (`x`) | `prop_rocher_01`, `prop_grande_pierre_01` (échelles 0,6–1), `prop_pierres_01`, `prop_buisson_a/b/c_01_bourg` |
| Panneaux | `prop_panneau_01` |
| Centre (façade, intérieur) | `bldg_centre_01` (8 × 7) ; intérieur `_pokemon_center` (J10) : infirmière, machine, terminal de Stockage |
| Objets au sol | `object/poke_ball_ground` (Poké Ball, Potion, Anti-Para, Corde, Pierre Lune visible, CT01 : une Ball comme partout) |
| Personnages | Gamin `youngster`, Scout `scout`, voyageur `traveler`, randonneuse `hiker` (Route 3), randonneur `mountaineer` (1F), infirmière `nurse` |
| Pokémon d'ambiance | Piafabec `pokemon/spearow` (×2, `shy=fly`) ; Rondoudou : sa planche C-4 (T3) |
| Pokémon en combat | artworks officiels 023, 024, 035, 036, 039, 040, 041, 042, 046, 047, 100, 109 (déjà là) ; dos : **sprites provisoires** (`gen_placeholder_battlers.gd`), comme les 38 espèces actuelles |

**B. Variations sans nouvel asset** : forêt plus sèche vers l'est (`Shade`, valeur × 0,95 → × 0,9) ; rochers assombris et teintés vers le gris bleuté à l'est ; buissons en miroir ± 8 % ; paroi de la série 12 **réservée à l'ouest** de la Route 3 (rangées 0..3 vers x 30–40), la masse de l'est passant à l'ardoise (C).

**C. Nouveaux (série 14, Codex, lumière NE)** — **≈ 30 images** (défaut ; T1 peut fusionner des planches)

| Fiche → asset | Rôle que rien d'existant ne tient | Emprise | Images |
|---|---|---|---|
| `WORLD_GROUND_ROCHE_01` → `ground_roche_01` | sol rocheux praticable `o` du pied de la montagne (texture répétable) | sol | 1 |
| `WORLD_RELIEF_PAROI_ARDOISE_PLANCHE` → `relief_paroi_ardoise_01..04` | la montagne qui passe à l'ardoise (§7, écart de la vue) : Route 3 est, sas | modules ≈ 5 × 3 | 1 |
| `WORLD_RELIEF_ENTREE_GROTTE_01` → `relief_entree_grotte_01` | ouverture du Mont Sélénite dans la paroi (`Q`, 2 cases) ; reprise en miroir pour la bouche du sas (`D`) | 4 × 3 | 1 |
| `WORLD_GROUND_GROTTE_PLANCHE` → `ground_grotte_01` (sol calme), `ground_gravats_01` (gravats), `ground_masse_roche_01` (dessus des masses `#`) | les trois sols de la grotte (textures répétables, mélangées par le masque) | sol | 1 (3 textures) |
| `WORLD_RELIEF_PAROI_GROTTE_PLANCHE` → `relief_paroi_grotte_01..06` | faces des parois (bord sud des masses), angles, bords latéraux, goulets | modules ≈ 3 × 2 | 1 |
| `WORLD_PROP_GROTTE_PLANCHE` → `prop_colonne_grotte_01` (`K`), `prop_rocher_grotte_01/02` (`o`), `prop_eclats_lune_01/02` (`*`), `prop_mare_grotte_01` (`w`) | repères minéraux (V-3) | 1 à 4 × 3 | 1 |
| `WORLD_PROP_ROCKET_PLANCHE` → `prop_lampe_chantier_01` (`L`), `prop_caisse_r_01/02` (`R`), `prop_tranchee_01` (`F`), `prop_projecteur_01` | indices et camp Rocket (B-7 : R rouge, sobre) | 1 à 4 × 3 | 1 |
| `WORLD_PROP_ECHELLES_PLANCHE` → `prop_echelle_descend_01` (`V`), `prop_echelle_monte_01` (`U`) | passages entre étages « clairement visibles » | 1 × 1 (+ débord) | 1 |
| `WORLD_PROP_DALLE_FOSSILES_01` → `prop_dalle_01` (`S`, 3 × 1), `object/fossil_dome`, `object/fossil_helix` | la dalle et les deux fossiles posés | 3 × 1, 1 × 1 | 1 |
| `WORLD_PROP_INDICES_PLANCHE` → `prop_indice_caillou_01` (Route 3), `prop_indice_eclat_01` (grotte `x`) | indices discrets des objets cachés (B-10) | 1 × 1 | 1 |
| `WORLD_DECAL_PUITS_JOUR_01` | puits de jour du 1F (`j`) : flaque de lumière au sol | 2 × 2 à 4 × 3 | 1 |
| `PNJ_FILLETTE` (+ attente) → `fillette` (`lass_young`) | classe nouvelle (le `lass` du J7 est la « jeune Dresseuse ») | 108 px | 2 |
| `PNJ_SBIRE_ROCKET_H` (+ attente) → `sbire_h` (`rocket_grunt_m`) | R1, R3 (pose et place distinguent R3) | 128 px | 2 |
| `PNJ_SBIRE_ROCKET_F` (+ attente qui **creuse**) → `sbire_f` (`rocket_grunt_f`) | R2, la fouilleuse | 124 px | 2 |
| `PNJ_CHERCHEUR_FOSSILES` (+ attente) → `chercheur_fossiles` (`fossil_researcher`) | Gaspard, chercheur indépendant de terrain (≠ blouse du Musée) | 128 px | 2 |
| `UI_ITEM_PIERRE_LUNE`, `UI_ITEM_CORDE_SORTIE`, `UI_ITEM_FOSSILE_DOME`, `UI_ITEM_FOSSILE_NAUTILE` → `assets/ui/items/<id>.webp` | illustrations du Sac (même chaîne que `potion.webp`, `preparer_menu.py`) ; CT01 : l'illustration CT du J11 | — | 4 |

**Planches Pokémon (T3, chaîne de la série 13, validation de Kevin)** : C-4 **Rondoudou, Mélofée, Abo, Paras, Nosferapti (en vol), Racaillou (marche)** — repos + marche 4 directions ; **lot parallèle** Roucoups, Nidorino, Nidorina, Rattatac, Rapasdepic. 11 planches. Aucune espèce n'entre dans `companions.json` sans sa planche validée (A-11).

**Décors de combat (T4, CB.3)** : `route_3_roche`, `mt_moon_galerie`, `mt_moon_chambre` (fond + premier plan facultatif, master 2340 × 1080, lignes de sol mesurées par `preparer_decor.py`) ; prompts `tools/art/combat_decors/prompts/COMBAT_DECOR_{ROUTE3,GALERIE,CHAMBRE}_r1.txt`.

**Conditionnels** (prompts prêts, jamais lancés par défaut ; décision de l'architecte sur capture, notée dans `etat-projet.md`) : `WORLD_PROP_AFFLEUREMENTS_PLANCHE` (si les rochers existants ne tiennent pas les affleurements `R` de la Route 3) ; `WORLD_PROP_CAISSES_ARGENTA` (aucun) — défaut : seul le premier existe.

**D. Abandonnés** : Pokémon d'ambiance de la grotte, personnages placés par les vues, entrée de grotte en escalier (essai 1), sbire aux cheveux roses (essai 1).

**Personnages réutilisés** (règle du J10 « jamais deux fois le même modèle sur une carte » pour les **habitants** ; les Dresseurs d'une même classe partagent leur modèle, précédent des Scouts de la Forêt de Jade) : Route 3 → Gamin ×2 (`youngster`), Scout ×2 (`scout`), Fillette ×2 (nouveau), voyageur, randonneuse ; Centre → infirmière ; 1F → randonneur ; B1F → Sbire ♂ et ♀ ; B2F → Sbire ♂, chercheur.

**Poids attendu** : ≈ 6 à 8 Mo de PNG ajoutés (textures de sol 1 024², planches, 3 décors de combat en WebP ≈ 0,4 Mo chacun).

---

## 2. Conception technique

### 2.1 Cartes et raccords (T8, T9)

| Carte | Taille | Catégorie | Profil de lumière | `display_name` / `region` |
|---|---|---|---|---|
| `route_3` | 82 × 38 | extérieur | `golden_hour` | « Route 3 » / « Argenta — Mont Sélénite » |
| `mt_moon_center` | 15 × 10 | bâtiment (`interior = true`, `interiors.json`) | `interior_warm` | « Mont Sélénite » |
| `mt_moon_1f` | 60 × 46 | **grotte** (`interior = false`, `caves.json`) | `cave_1f` | « Mont Sélénite » / "" |
| `mt_moon_b1f` | 40 × 30 | grotte | `cave_b1f` | « Mont Sélénite » / "" |
| `mt_moon_b2f` | 50 × 38 | grotte | `cave_b2f` | « Mont Sélénite » / "" |
| `route_4` (sas) | 24 × 14 | extérieur | `golden_hour` | « Route 4 » / « Mont Sélénite — Azuria » |

- **Outils** : `tools/build_route_3.gd`, `tools/build_route_4.gd` (kit `pewter_map_kit.gd`, praticables de la grille, `o` → sol rocheux) ; `tools/build_mt_moon.gd -- --etage=1f|b1f|b2f|tous` sur un kit nouveau `tools/cave_map_kit.gd` (même méthode : deux passes masque / scène, graines fixes, `Ground` invisible = un caractère par case : `.` `j` `E` `U` `V` → sol, `g` → `RUBBLE`, tout le reste solide). Centre : `build_painted_interiors.gd -- --rooms=mt_moon_center` (`_pokemon_center`, sortie → `route_3` / `from_center_w|e`).
- **Raccords** : Argenta (51, 25..27) PUSH → (`Route3N/C/S` perdent leur `coming_soon`) → `route_3` / `from_pewter_n|c|s` (0, 25..27), tournés → ; Route 3 (0, 25..27) PUSH ← → `pewter_city` / `from_route_3_n|c|s` (existants), tournés ← ; Centre (61..62, 11) STEP_ON ↑ ; entrée de la grotte (73..74, 9) STEP_ON ↑ → `mt_moon_1f` / `from_route_3_w|e` (29..30, 44) ↑ ; 1F (29..30, 45) STEP_ON ↓ → `route_3` / `from_mt_moon_w|e` (73..74, 10) ↓ ; échelles A, B, C, D (§1.3) ; B2F (11, 29) → `route_4` / `from_mt_moon` (3, 6) → ; sas (2, 6) STEP_ON ← → `mt_moon_b2f` / `arrivee_s` (11, 30) ↓ ; raccord est (23, 6..7) PUSH → `coming_soon = "Azuria"`, retour sur la case, tourné ←.
- Argenta est **régénérée** (`build_pewter_city.gd`, constantes des trois warps seulement) ; test : diff limité aux trois `WarpPoint` (graines fixes). Le garde (`route_3_guard`, J10) ne change pas.
- `test_coming_soon` (aujourd'hui sur la sortie est d'Argenta) passe sur le **raccord est du sas** (« AZURIA — À venir », retour, rien de sauvegardé).

### 2.2 Échelles (T9)

Aucun code : `WarpPoint` `STEP_ON`, `direction = ZERO`, cible `spawn` de même paire. Décor `prop_echelle_descend_01` / `_monte_01` posé sur la case praticable (couche du sol, sans ombre). Le compagnon rentre au fondu (J11 : `CompanionController.on_transition_started`, relayé par Boot) ; **placement à l'arrivée** : jamais sur une case de warp (T20 : le Callable que `CompanionController` passe à `CompanionTrail.place_after_arrival` exige aussi `get_warps().get_at(c).is_empty()` — `CompanionTrail` reste pur et inchangé ; la case derrière le joueur à l'arrivée est souvent l'échelle elle-même ; sinon masqué jusqu'au premier pas, A-1). Tests (`test_mt_moon_maps`) : chaque paire aller-retour ; graphe des étages connexe sur les **vraies scènes** (même critère que `plan_check_mont_selenite.py`) ; retour à l'entrée possible de toute case praticable.

### 2.3 Catégorie « grotte » (T7 pur, T20 branchement)

```gdscript
# game/world/caves/cave_library.gd — pur, testable sans scène
class_name CaveLibrary
extends RefCounted
## Grottes de Kanto (`data/world/caves.json`) : cartes d'une grotte et sortie de la Corde Sortie.
## Une carte de grotte a `interior = false` (compagnon visible, titre de zone) ; ni jour ni nuit
## (phase 10 : `has_sky`), Corde Sortie permise.
func load_file(path: String = DEFAULT_PATH) -> bool
func is_cave(map_id: StringName) -> bool
func cave_of(map_id: StringName) -> StringName          # &"" hors grotte
func escape_target(map_id: StringName) -> CaveExit       # null hors grotte
static func has_sky(map: GameMap, caves: CaveLibrary) -> bool   # extérieur et pas grotte
```
```json
{ "caves": { "mt_moon": {
	"maps": ["mt_moon_1f", "mt_moon_b1f", "mt_moon_b2f"],
	"escape": { "map": "route_3", "spawn": "from_mt_moon_w", "facing": "down" } } } }
```
- `CaveExit` : `map`, `spawn`, `facing` (donnée pure). Lecture tolérante, erreurs signalées (carte absente, spawn vide, facing non cardinal) ; `test_cave_library` (pur) + `test_map_catalog` étendu : chaque carte de grotte existe, `interior == false`, n'est pas dans `interiors.json`, spawn de sortie présent.
- **Usages** : Corde Sortie (§2.6) ; phrase du compagnon (**pas en données seules**, §0.4 n° 5 : T20 ajoute `cave` à `CompanionCatalog.CONTEXTS` et `cave → companion_cave` à `CompanionRules.CONTEXT_LINES` ; T21 : `companions.json` `contexts` += les trois étages → `cave`, phrase §20 n° 40 dans `companion.json`, `PLAYED_BY_COMPANION` de `test_dialogue_data`) ; jour/nuit futur (`has_sky`). Le compagnon reste visible (`CompanionRules.is_visible` : `interior` faux). Titre de zone « MONT SÉLÉNITE » à l'entrée (une seule fois pour les trois étages : même nom, règle existante de `ZoneAnnouncer`).
- Rien dans `GameMap` : la catégorie se lit dans les données (un seul endroit, comme `interiors.json`).

### 2.4 Lumière de grotte (T7, T9)

- **Peinte d'abord** : sols clairs (`ground_grotte_01`), masses sombres (`ground_masse_roche_01`), faces de paroi qui séparent nettement les deux ; gravats légèrement plus sombres que le sol calme (B-3 : « galeries plus sombres ») ; puits de jour du 1F en décalcomanie claire.
- **Profils** (`lighting.json`) : `cave_1f` (étalonnage froid, ombres bleu ardoise, liseré froid faible, **aucune ombre portée** — pas de soleil —, ombres de contact gardées, vent 0) ; `cave_b1f` (plus sombre, moyens tons désaturés) ; `cave_b2f` (comme B1F). Progression 1F > B1F > B2F (« transitions progressives »).
- **Sources légères** : `LightGlow` (`game/world/lighting/light_glow.gd`, `Sprite2D` additif, texture `GradientTexture2D` radiale générée — **aucun asset** —, couleur et rayon par type en données : `lamp` orangé, `shaft` blanc bleuté, `shard` bleu pâle, `projector` blanc chaud) posé par l'outil aux cases `L`, `j`, `*` et aux projecteurs ; vacillement lent des lampes par shader (`TIME`), **coupé par « Réduire les animations »** (`LightGlow.set_reduce_motion`, fait au T7 ; **branché au T20** dans `Boot._apply_settings`, à côté de `_companion.set_reduce_motion`) ; au-dessus des personnages (`z` du monde, alpha ≤ 0,35) pour qu'ils prennent la lumière en passant. **Aucune `Light2D`** (rendu `mobile`, aucun précédent dans le jeu ; une mesure ne serait faite que si Kevin trouve les halos plats).
- **Budget** [D] : ≤ 16 halos par étage, ≤ 3 000 nœuds par carte, moyenne ≥ 58 fps, creux ≥ 50 sur S24.
- **Lisibilité, contrôle objectif sur Mac** (T9) : `tools/capture_mt_moon.gd` (captures 2340 × 1080 aux repères de chaque étage) + `tools/art/luminance_grotte.py` (lit la grille et la capture) : luminance relative moyenne des cases praticables ≥ **0,22** et rapport sol / paroi ≥ **2,0** [D] ; personnages lisibles (contraste du héros sur le sol ≥ celui de la Forêt de Jade). Le critère qui valide reste le téléphone **sans monter la luminosité** (12B).

### 2.5 Rencontres de grotte (T7 tuile, T20 moteur)

- **Tuile** (T7) : `OverworldTiles.Kind.RUBBLE` **en fin d'enum**, donnée de tuile `rubble` (couche de données ajoutée **en dernier** au TileSet par `gen_placeholder_tiles.gd` ; test : les données des cartes existantes inchangées).
- **Grille** (T20) : `GridWorld.set_rubble` / `is_rubble` (sur le modèle de `set_tall_grass` / `is_tall_grass`) ; `GameMap._read_layer` lit `rubble` (comme `tall_grass`, `map.gd` l. 442).
- **Moteur** (T20, `game/pokemon/encounters/`) : `EncounterTable.TERRAINS += &"rubble"` ; `EncounterDirector` : `_terrain_at(cell) -> StringName` (hautes herbes → `grass`, gravats → `rubble`, sinon rien) remplace `_GRASS_TERRAIN` (l. 28 ; lu l. 103 et 134) dans `_on_player_moved` / `_can_encounter` ; débogage : `EncounterLibrary.override_grass` devient un cas de `override_table(map_id, terrain, entry)` et la clé `wild` de `DebugStart` accepte un `"terrain"` facultatif (défaut `grass`) [D, §0.4 n° 4] ; table par (carte, terrain), même taux effectif et même série de pas calmes (`_quiet_steps` partagée : défaut, un seul compteur) ; intro choisie par le terrain.
- **Intro « éboulis »** (dossier 04, ≤ 2 s) : `RubbleBurst` (`game/world/rubble/rubble_burst.gd`, modèle `GrassRustle` : `spawn(map, pos)`, `burst(speed) -> await`) : quelques cailloux qui roulent et un peu de poussière sous les pieds (≈ 0,6 s, `Tween`), signal d'accroche `rubble_sound_requested` (aucun son au J12), puis le héros **se retourne** (demi-tour, `face(-facing)`), puis combat. Pas d'herbe agitée.
- **Données** : `data/encounters/route_3.json` (herbes, §3.3, `rate` 25, rampe 15 → 20) ; `data/encounters/mt_moon.json` : trois tables `rubble` (§6, mêmes taux et rampe). Habitats du Pokédex : automatiques (vu par carte).
- **Tests** : `test_encounter_library` (terrain `rubble`, couple unique), `test_encounter_director` (rencontre sur gravats, rien sur le sol calme, herbes inchangées, intro au pas près avec `TweenClock`, compagnon jamais déclencheur), `test_grid_world`, `test_overworld_tiles`. **Information** (pas un seuil) : `tools/simulate_grass_pacing.gd` sur le chemin principal (8 cases de gravats obligatoires) → combats attendus par traversée.

### 2.6 Corde Sortie (T20)

- **Donnée** : `escape_rope` (« Corde Sortie » / « Cordes Sortie », féminin, catégorie `field` = AVENTURE, 550 ₽, description §20 n° 32 ; écrite au T12 dans `data/items/mt_moon.json`, **sans** `field_use`, que le chargeur refuserait avant T20) ; `ItemData.field_use: StringName` (nouveau, **en fin de champs**, T20) ∈ `{"", "escape_rope", "evolution_stone"}`, validé par `ItemLibrary` ; T20 pose `field_use` sur `escape_rope`, T23 sur `moon_stone`. Un objet AVENTURE sans `field_use` n'a pas UTILISER (le J13 l'attend pour la Pépite).
- **Règle pure** `FieldItemRules` (`game/items/field_item_rules.gd`) : `check(item, map_id, caves) -> Check { OK, NOT_HERE, NOT_FIELD_USE }` ; `escape_target(map_id, caves) -> CaveExit`.
- **Parcours** (modèle de la CT du J11 : signal du `MenuDirector` → Boot) : Sac (exploration) → AVENTURE → Corde Sortie → **UTILISER** → `MenuDirector.request_item_use` (l. 446) consulte `FieldItemRules.check` → `NOT_HERE` : `bag_result_shown` « Impossible de l'utiliser ici. » (§20 n° 34), rien ne change ; `OK` : signal nouveau `field_item_requested(item_id)` → Boot ferme le menu, retire une Corde, narration « Tu utilises la Corde Sortie. » (§20 n° 33), puis `SceneRouter.change_map(route_3, from_mt_moon_w, DOWN)`. **Hors combat** : la catégorie AVENTURE n'est jamais proposée en combat (`ItemData.contexts()` : `field` seulement) ; **hors cinématique** : le menu ne s'ouvre pas pendant une scène (`Boot._can_open_menu`). Depuis la fiche Équipe (Sac « donner à un Pokémon ») : absente.
- **Sauvegarde** (vérification de Kevin, §11) : un changement de carte comme une porte ; l'autosave de `map_entered` enregistre position et Sac ; une fermeture pendant le fondu laisse l'ancienne sauvegarde (Corde comprise, position dans la grotte) : jamais de Corde perdue sans transport. Ni soin ni point de repos touchés. Compagnon : placé derrière le joueur à l'arrivée (J11).
- **Sources** : `pewter_mart.json` += `{ "item": "escape_rope" }` (sans condition) ; Corde au sol au 1F (9, 29).
- **Tests** : `test_field_item_rules` (pur : grotte / hors grotte / objet sans usage), intégration `test_escape_rope` (Boot réel : refus sur la Route 3 et à Argenta ; depuis 1F, B1F, B2F après l'événement → devant l'entrée côté Route 3, tourné ↓ ; une Corde de moins ; point de repos et PV inchangés ; Dresseurs battus et objets ramassés le restent ; fermeture simulée pendant le fondu → sauvegarde d'avant).

### 2.7 Objets visibles (T18, T21, T25)

Modèle du J8 (PNJ `object/poke_ball_ground`, verbe PRENDRE, scène `despawn` → `give found` → `set got_<id>`). Route 3 : Poké Ball (34, 36), Potion (57, 14), Anti-Para (77, 23) ; 1F : Corde Sortie (9, 29) ; B1F : Pierre Lune (25, 20), Potion (16, 21) ; B2F : CT01 (4, 5).

### 2.8 Objets cachés « face à un indice » (T17, T18)

- **Point d'examen conditionnel** : `InteractPoint` gagne `unless_flags: Array[StringName]` (export, en fin) recopié dans `Interaction` (`to_interactions`) ; `InteractionController`, qui tient déjà les drapeaux (`set_story_flags` → `_flags: StoryFlags`), ne retient pas une cible dont un drapeau `unless` est levé (le bouton disparaît une fois l'objet trouvé). `InteractionFinder` n'est plus protégé (J11 clos) mais reste inchangé : le plus simple tient dans le contrôleur. Ni `InteractionTable`.
- **Données** : l'outil pose un `InteractPoint` (verbe EXAMINER, toutes orientations) sur la case-indice (§1.3), `dialogue` = `<id>`, `unless_flags = [got_<id>]` ; dialogue `<id>` → `{ "cutscene": "<id>" }` ; scène : `give <objet> found: true` → `set got_<id>` (texte de ramassage existant = **toast seul**, « Réveil ×1 — Ajouté au Sac » ; aucune phrase nouvelle ; `found_items` alimenté par `found: true`). Décor : `prop_indice_caillou_01` / `prop_indice_eclat_01`, jamais dessiné sur le plan joint à Codex.
- **Q-2** : le bouton EXAMINER apparaît face à l'indice (défaut).
- **Tests** : `test_hidden_items` (Boot réel : face à l'indice → bouton, examen → toast, Sac, `found_items`, drapeau ; ensuite plus de bouton, même après rechargement ; de dos ou de côté : rien), sur les trois caches (Route 3, 1F, B2F).

### 2.9 Évolution par objet : Sac → Pierre Lune (T23, T24)

- **Donnée** : `moon_stone` (« Pierre Lune », AVENTURE, prix 0 = jamais en vente, `field_use: "evolution_stone"`, description §20 n° 31). Règles d'évolution : Nidorina, Nidorino (déjà là), Mélofée → Mélodelfe, Rondoudou → Grodoudou (T12).
- **Règle pure** `StoneUse` (`game/pokemon/evolution/stone_use.gd`) : `enum Check { COMPATIBLE, INCOMPATIBLE }` (pas de « déjà connue » : ce n'est pas `TmTeach.Check`), `check(pokemon, item_id, data)` par `Evolution.item_target` (existant, `evolution.gd` l. 25) ; un Pokémon K.O. reste COMPATIBLE [D].
- **Parcours** (modèle de la CT du J11, §0.4 n° 9–10) : Sac → AVENTURE → Pierre Lune → **UTILISER** (§20 n° 35) → `BagQuery.targets` donne à chaque membre `PartyTargetView.show_reason = true` et la raison **COMPATIBLE / INCOMPATIBLE** (libellés du J11, toujours visibles ; INCOMPATIBLE non choisissable) → toucher un Pokémon compatible → `MenuDirector.use_item_on` émet le signal nouveau `evolution_item_requested(index, item_id)` (comme `tm_learn_requested`) → Boot ferme le menu → `EvolutionDirector.play_item(candidate, party, item_id)` (= `play([candidate], party)` d'un candidat non annulable) :
  - `EvolutionCandidate.cancellable` (nouveau champ, **vrai par défaut** : rien ne change pour les évolutions de fin de combat ; faux pour une pierre), recopié dans l'`EvolutionView` : **ARRÊTER masqué** (`EvolutionScreen.transform()`), **retour Android sans effet** (`EvolutionScreen.handle_back` absorbe sans annuler) ;
  - signal nouveau **`evolution_applied(party_index, into)`**, émis dans `_play_one` **dans le même appel** que `Evolution.evolve` : **Boot** y retire la pierre (le menu est déjà fermé ; même image : jamais une pierre consommée sans évolution, ni l'inverse) ;
  - capacités de la nouvelle espèce : règle existante (`MoveLearnPrompt`) ; Pokédex : vu + possédé (existant) ; compagnon : rentre en silence si l'espèce n'est pas éligible (J11).
  - Fin → retour au monde [D] ; autosave à `evolution_finished` (une fermeture pendant la séquence reprend avant l'évolution, pierre comprise).
- **Hors combat seulement** (AVENTURE). Les évolutions de fin de combat gardent ARRÊTER (inchangées).
- **Tests** : `test_stone_use` (pur), `test_evolution_director` (non annulable : retour Android ignoré, `evolution_applied` une fois et avant la révélation), intégration `test_moon_stone` (Boot réel : 4 espèces compatibles, incompatibles refusées, pierre retirée exactement une fois, deux pierres → deux évolutions, rechargement), captures (sélecteur, écran sans ARRÊTER).

### 2.10 Capacités nouvelles et mécaniques (T12 données, T13 moteur, T14 interface)

**Genres d'effet nouveaux** (`MoveEffect.Kind`, **en fin d'enum**, documentés dans `move_effect.gd`), logique dans `Battle` / `Battler` (volatils perdus au changement et en fin de combat, jamais sauvegardés) :

| Effet | Donnée | Règle (G+ simplifiée, C-1 à C-3) | Messages (§20 n° 46) |
|---|---|---|---|
| `drain` | `{ "kind": "drain", "fraction": 0.5 }` | après les dégâts : le lanceur récupère `max(1, floor(dégâts × fraction))`, plafonné à ses PV max ; rien si l'attaque rate ou ne fait rien | « {pokemon} récupère des PV ! » (rien si PV pleins) |
| `trap` | `{ "kind": "trap", "turns": [4, 5], "fraction": 0.125, "messages": "wrap" }` | la cible est piégée 4–5 tours (tirage `GameRng`) ; fin de chaque tour : `max(1, PV max / 8)` ; elle ne peut **ni fuir** (« Impossible de fuir ! », existant) **ni être changée** (raison sur les cartes, annexe A) ; fin : compteur, K.O., changement **du lanceur** ; relancé pendant le piège : dégâts seulement, compteur inchangé ; un Pokémon sauvage piégé est capturable | « {pokemon} est ligoté[e] ! » · « {pokemon} souffre du Ligotage ! » · « {pokemon} est libéré[e] ! » ; Étreinte et Danse Flamme : leurs textes (annexe A) |
| `disable` | `{ "kind": "disable", "turns": 4 }` | bloque la **dernière capacité utilisée** par la cible 4 tours (décompte en fin de tour) ; échoue (« Mais ça échoue ! », J11 n° 27) si la cible n'a encore rien utilisé, a déjà une capacité bloquée, ou est verrouillée dans Patience ; la capacité bloquée est exclue de `get_usable_moves` / `is_legal` (plus de choix → Lutte, existante) ; l'IA ne la choisit plus ; perdue au changement | « {move} de {pokemon} est bloquée ! » · « {move} n'est plus bloquée. » |
| `rest` | `{ "kind": "rest" }` | échoue si PV pleins ou déjà endormi ; sinon soigne tout statut, **PV pleins**, puis sommeil avec un compteur tel que le lanceur **manque exactement 2 tentatives d'agir** (§0.2 n° 10) ; Réveil et réveil naturel du J11 s'appliquent | « {pokemon} s'endort et récupère ! » |
| `self_ko` | `{ "kind": "self_ko" }` | le lanceur tombe K.O. après sa capacité, **même si elle rate ou n'affecte pas** la cible ; pas s'il n'a pas pu agir (sommeil, paralysie, apeurement, confusion) ; si les deux derniers Pokémon tombent dans le même coup, **le camp du lanceur perd** [D, G+] ; XP : règle existante (aucune au K.O.) ; Destruction **et Explosion** | messages existants (« … est K.O. ! ») |

- **Ordre dans le tour** (matrice du J11 étendue) : piège → dégâts en fin de tour **après** poison / brûlure et Vampigraine [D] ; Entrave testée au choix de l'action (avant `can_act`) ; Repos passe par le statut du J11 ; Destruction : K.O. du lanceur après les effets de la capacité.
- **IA `smart`** : n'utilise pas Repos à PV pleins, ni Entrave si elle échouerait, ni Ligotage sur une cible déjà piégée ; Destruction **seulement** si sa vie est basse (≤ ¼) [D] ; `random` inchangée.
- **Événements** (`BattleEvent.Kind`, fin d'enum, après `BIDE_BROKEN`) : `DRAINED_HP` (distinct de `DRAINED`, qui est Vampigraine), `TRAPPED`, `TRAP_DAMAGED`, `TRAP_ENDED`, `MOVE_DISABLED`, `DISABLE_ENDED`, `RESTED`, `SELF_KO` ; textes dans `messages.json` (`templates`, en fin ; clé par capacité pour le piège : `trap_wrap_*`, `trap_bind_*`, `trap_fire_spin_*`, `text_f` ; drain : clé nouvelle `drain_hp`, `hp_restored` étant le texte de la Potion ; échec : `move_failed` existant).
- **Interface** (T14, ui-mobile) : carte de capacité bloquée grisée et **non touchable**, libellé « BLOQUÉE » (annexe A) ; raison « ligoté » sur les cartes de l'équipe ; icône du type **Fée** (`TypeBadge.ICONS`) ; aucun effet visuel nouveau sur le sprite (les statuts du J11 suffisent) ; captures relues.
- **Métronome** : donnée avec `pending_effects: ["metronome"]` et « Sans effet dans le moteur actuel. » (dossier 15 §16.2).
- **Capacités ajoutées** (21, apprentissages de Rouge/Bleu des 12 espèces, tous niveaux, + CT01) — genre d'effet entre parenthèses ; **J11** = genres du J11 ; **attente** = `pending_effects` + mention « Sans effet dans le moteur actuel. » :
  `leech_life` Vampirisme (drain) · `wrap` Ligotage (trap) · `disable` Entrave · `rest` Repos · `sing` Berceuse (J11 sommeil, préc. 55) · `spore` Spore (J11 sommeil) · `confuse_ray` Onde Folie (J11 confusion) · `glare` Regard Médusant (J11 paralysie) · `doubleslap` Torgnoles (J11 2–5 coups) · `pound` Écras'Face · `smog` Purédpois (poison 40 %) · `sludge` Détritus (poison 30 %) · `acid` Acide (Déf. Spé. −1, 10 %) · `smokescreen` Brouillard (précision −1) · `minimize` Lilliput (esquive +1) · `mega_punch` Ultimapoing (CT01) · `sonic_boom` Sonicboom (`fixed_damage` mode **`value`**, `amount` 20 : mode ajouté au T13, §0.4 n° 8 ; T12 l'écrit en `pending_effects: ["fixed_value"]`) · `metronome` Métronome (attente) · `haze` Buée Noire (attente) · `light_screen` Mur Lumière (attente) · `double_edge` Damoclès (attente : recul proportionnel aux dégâts).
  Capacités existantes activées : `bind` Étreinte et `fire_spin` Danse Flamme (`trap`), `self_destruct` Destruction et `explosion` (`self_ko`) ; description de Destruction remplacée par le texte §20 n° 45.
- **Tests** : `test_battle_drain`, `test_battle_trap`, `test_battle_disable`, `test_battle_rest`, `test_battle_self_ko` (graines fixées ; table pilotée par les données pour chaque capacité ajoutée ; interactions : piège + changement forcé après K.O., piège + capture, Entrave + Patience, Entrave sur la seule capacité → Lutte, Repos + Réveil, Repos à PV pleins, Destruction qui rate, double K.O. final, Destruction endormi), `test_battle_ai` (règles `smart`), non-régression du J11 (statuts, Patience) et du poison du J9.

- **Alignement sur le J11 livré (T11, §0.4 n° 1–3, 8, 11)** :
  - genres : `MoveEffect.Kind` += `DRAIN, TRAP, DISABLE, REST, SELF_KO` après `BIDE`, `KIND_NAMES`, clés obligatoires dans `PokemonData._EFFECT_KEYS` (`drain` : `fraction` ; `trap` : `turns`, `fraction`, `messages` ; `disable` : `turns` ; `rest`, `self_ko` : aucune) ; `FIXED_MODES` += `value` (+ `amount`, obligatoire pour ce mode seulement) ;
  - volatils sur le **`Battler`** (§0.4 n° 3) ; Entrave filtrée dans `Battler.usable_moves()` (choix du joueur, `is_legal`, IA en une fois) ; `last_move_slot` posé à MOVE_USED (pas pendant les tours imposés de Patience) ; `Battle.get_disabled_move()` pour l'interface ;
  - piège : changement refusé par `is_legal(SWITCH)` (le remplacement après K.O. par `replace` reste permis), `Battle.is_player_trapped()` pour la raison des cartes ; fuite : `is_legal(RUN)` faux, le `BattleDirector` affiche `flee_failed` **sans soumettre d'action** (aucun tour perdu, comme un changement refusé) [D, G+] ; dégâts en fin de tour : `_trap_damage(side)` après `_drain_seed` et `_status_damage` dans `_end_turn` ; décompte d'Entrave au même endroit ;
  - Repos : `StatusRules.apply_rest(pokemon)` (statut soigné, PV pleins, `sleep`, `status_turns = 2`) ; échec (`move_failed`) à PV pleins ou déjà endormi ;
  - Destruction : K.O. du lanceur par le chemin de `_faint` après les effets ; « n'a pas pu agir » = `_can_act` faux (statut, apeurement, confusion) ;
  - IA `smart` : règles ajoutées à `BattleAI.status_has_effect` / `score_move` (Repos, Entrave, Ligotage) et un seuil de PV pour Destruction ; `BattleAI.is_low` existe (⅓) — le seuil ¼ de Destruction est une constante nouvelle [D] ;
  - fichiers chauds partagés avec J13 (IA qui change) et J14 (charge puis frappe) : fonctions nouvelles **en fin** de `battle.gd`, points d'accroche courts (§1.2).

### 2.11 Dresseurs de la Route 3 et Sbires : reprise et départ (T17 moteur, T18, T25)

- **Données** : `data/trainers/route_3.json` (Hugo, Léa, Sacha, Enzo, Inès, Nolan : équipes, `random`, récompenses du §3.2) et `data/trainers/mt_moon.json` (`mt_moon_rocket_1/2/3` « Sbire Rocket », `random`, `random`, `smart`, 330 / 360 / 450 ₽ ; `mt_moon_researcher` « Chercheur Gaspard », `smart`, 325 ₽) ; capacités apprises au niveau (aucune `moves`). PNJ : blocs `trainer` aux cases et visions des grilles.
- **Bloc `trainer` étendu** (`NpcSpec`, `NpcRoster`, `TrainerEncounter.build`), deux clés facultatives — sans elles, la séquence du J9/J10 est **identique** (tests des Dresseurs de la forêt et de Liam inchangés) :
  - **`rematch`** : réplique dite à la place de « avant » si `lost_<id>` est levé ; l'étape `battle` reçoit `lose_flags = [lost_<id>]` (seulement si `rematch` existe). `TrainerEncounter.build(npc_id, spec, distance)` ne voit pas les drapeaux : il pose **deux** étapes `dialogue`, « avant » avec `unless_flags = [lost_<id>]` et « reprise » avec `if_flags = [lost_<id>]` (conditions d'étape existantes, J4B, évaluées au moment de jouer) ; clés ajoutées **en fin** de `NpcRoster.TRAINER_KEYS` (le J14 ajoute `moved` à une autre liste de `npc_spec.gd`) ;
  - **`leave`** : liste de cases (chemin relatif, 0 à 4 pas) ; après la réplique « vaincu » (`defeated`, J10) : `move` sur ce chemin puis `despawn` (fondu 0,2 s) ; chemin vide = s'efface sur place. L'entrée de PNJ porte `unless: [beaten_<id>]` (absent au rechargement).
- **Sbires** : R1 (14, 1) ↓, vision 5, `before` « Hé, toi !… », `defeated` « Tch… Je préviens les autres. », `rematch` « Encore toi ? Demi-tour. », `leave` vide (niche) ; R2 (8, 20) →, vision 2, apparence `sbire_f` en attente « creuse », `leave` vers la tranchée ; R3 (29, 24) ←, vision 4, `before` = les 3 bulles du §20 n° 18, `defeated`, `rematch`, `leave` vers la niche (29, 24) → effacé ; décor de combat « chambre » (§2.18).
- **Défaite du joueur** : réveil au dernier Centre (`wake_up`, existant) ; le Sbire reste ; reprise par `rematch`.
- **Tests** : `test_trainer_encounter` (rematch, leave, absent, compatibilité ascendante), `test_npc_roster` ; intégration `test_route_3_trainers` (D1, D2 inévitables et D3–D6 évitables sur la **vraie scène avec ses PNJ**, recherche de chemin hors des lignes de vue), `test_mt_moon_rocket` (R1, R3 inévitables, R2 évitable ; départ puis absence au rechargement ; défaite → reprise).

### 2.12 Le chercheur (T25)

- PNJ `mt_moon_researcher` sans bloc `trainer` (vision 0 : il est inévitable par sa **place**, le seul goulet (13, 31)) ; deux entrées : `unless beaten_mt_moon_researcher` en (13, 31) tourné → ; `if beaten_mt_moon_researcher` en (15, 30).
- **Déclencheur** (25..26, 27), pas ↓ → scène `mt_moon_researcher`, variante `if beaten_mt_moon_rocket_3`, `unless beaten_mt_moon_researcher` : `emote !` chercheur → `move` près du joueur (`near`) → `face` × 2 → `dialogue` `mt_moon_researcher_before` (§20 n° 20) ou `_rematch` (`if lost_mt_moon_researcher`, n° 25) → `battle mt_moon_researcher` (`win: [beaten_mt_moon_researcher]`, `lose: [lost_mt_moon_researcher]`) → victoire : `dialogue` n° 21 puis n° 22 → `move` vers (15, 30) ; défaite : `wake_up`. Ordre B-9 garanti : le déclencheur ne joue rien tant que R3 n'est pas battu, et le couloir est le seul accès à la chambre.
- **Ensuite** (dialogue du PNJ) : avant le choix, n° 22 ; après, n° 26.

### 2.13 Choix du fossile, objets clés, Grand moment (T23 moteur, T25 données)

- **Fossiles** : deux PNJ objets (`object/fossil_dome`, `object/fossil_helix`) sur la dalle (24, 31) et (26, 31), verbe EXAMINER, présents `if beaten_mt_moon_researcher` **et** `unless mt_moon_fossil_chosen` ; examinables depuis la case au nord ou au sud.
- **Choix qui lance une scène** : `DialogueChoice.confirm_cutscene` (clé nouvelle `"confirm_cutscene"`, **en fin** de `DialogueLibrary._CHOICE_KEYS`, exclusive de `confirm_action` ; le J13 ajoute `confirm_set` / `cancel_set` aux mêmes listes : garder les deux à sa fusion) ; le `DialogueRunner` émet `cutscene_requested` après la fermeture — **signal existant** (variantes `cutscene`), déjà relié par Boot. Dialogue `mt_moon_fossil_dome` : page « Prendre le Fossile Dôme ? » (n° 23, texte littéral par fossile : aucun jeton nouveau), `confirm` « OUI », `cancel` « NON », `cancel_pages` vides (NON → rien, on peut regarder l'autre).
- **Scène `mt_moon_fossil_dome`** (et `_helix`) : `despawn` des deux fossiles → `give dome_fossil` (objet clé, toast « Fossile Dôme » / « obtenu » : champ `obtained` de l'objet, §0.4 n° 7) → `set [mt_moon_fossil_chosen, mt_moon_got_dome_fossil]` → `face` chercheur → joueur → `dialogue` n° 24 → **`moment`** `fossil` (`{ "item": "dome_fossil" }`). **Définitif** : rien ne redonne l'autre (aucune entrée, aucun stock).
- **Étape `moment`** (`CutsceneStep.Kind.MOMENT` après `BADGE`, `TYPE_KEYS` += `"moment"` ; modèle : l'étape `badge`, qui enregistre `BadgeMoment.TYPE`) : `GameState.record_moment(type, carte, details)` (existant) une seule fois par type et par détails ; le J14 met `FLASH` après `MOMENT` ; `MomentLibrary.TYPES += fossil`, marque `{fossil}` (nom lu dans l'`ItemLibrary`) ; `moments.json` : présentation du texte validé n° 30 dans la frise (titre / détail / lieu) → annexe A n° A-30 ; icône : celle des objets clés.
- **Objets** (`data/items/mt_moon.json`, §1.2) : `dome_fossil` « Fossile Dôme », `helix_fossil` « Fossile Nautile » (KEY, `obtained: true`, descriptions n° 28–29) ; aucune indication de résurrection.
- **Tests** : `test_dialogue_library` (`confirm_cutscene`), `test_dialogue_runner`, `test_cutscene_director` (`moment` une fois), `test_moment_library`, `test_trainer_summary` ; intégration `test_mt_moon_fossil` (Boot réel : NON → rien ; OUI Dôme → Sac, toast, moment, fossiles absents, chercheur n° 26 ; idem Nautile ; rechargement à chaque étape : R3 battu sans chercheur, chercheur battu sans choix, choix fait).

### 2.14 Centre du Mont Sélénite (T8 carte, T18 vie)

Carte `mt_moon_center` (définition `_pokemon_center` du J10, sans Boutique) ; `rest_points.json` : `mt_moon_center` (`spawn` heal, `nurse_wakeup`, `registers` vrai) → toast « Point de repos enregistré — Mont Sélénite » (titre de la carte) ; `zones.json` : zone `mt_moon` = Centre + 3 étages, service `pokemon_center` `found_on: mt_moon_center` ; PNJ `data/npcs/mt_moon_center.json` (infirmière, terminal de Stockage : modèle de Jadielle). Le compagnon rentre (bâtiment). Panneau « CENTRE POKÉMON » / « Mont Sélénite » (64, 12).

### 2.15 Sas et raccord « AZURIA — À venir » (T8 carte, T28 vie)

Carte `route_4` (§2.1) : chemin, panneau (6, 5) « ROUTE 4 » / « Mont Sélénite ← → Azuria », vue sur la plaine (rebord bloqué), aucun Dresseur, herbe ni objet ; raccord est `coming_soon = "Azuria"` (build de développement ; en release, le bord est simplement bloqué — comportement existant). Déclencheur silencieux `route_4_reached` (§1.3 n° 5). Passation J13 (§0.2 n° 15).

### 2.16 Objectifs (T18, T28)

`objectives.json`, **en tête** : `{ "id": "go_cerulean", "text": "continuer vers Azuria.", "if": ["route_4_reached"] }`, puis `{ "id": "cross_mt_moon", "text": "traverser le Mont Sélénite.", "if": ["route_3_entered"], "unless": ["route_4_reached"] }` ; `go_route_3` (J10) inchangé derrière. Mises à jour en silence (existant). `test_objective_library` : les quatre états.

### 2.17 Garde d'Argenta → raccord réel (T8)

Le garde (`route_3_guard`, `route_3_guard_cleared`, J10) ne change pas : avant le badge, sa scène de recul ferme les trois cases (48, 25..27) ; après, la sortie est mène à la vraie Route 3 (§2.1). Test `test_pewter_badge` étendu : après le badge, PUSH → sur (51, 26) charge `route_3` en (0, 26).

### 2.18 Décors de combat (T4 art, T8 / T9 intégration)

`decors.json` : `route_3_roche` (défaut de `route_3`), `mt_moon_galerie` (défaut des trois étages), `mt_moon_chambre` (variante de `mt_moon_b2f`, `cells` = couloir des lampes + chambre, (14, 19) → (37, 35)) ; le sas et le Centre : repli existant. Tests `test_battle_stage_decor` (choix par carte et par case), captures CB.3.

### 2.19 Espèces, Pokédex, CT (T12)

- `data/pokemon/species/kanto_mt_moon.json` (fichier à part, §1.2 n° 4 ; capacités dans `data/pokemon/moves/mt_moon.json`, objets dans `data/items/mt_moon.json`) : `jigglypuff`, `wigglytuff`, `ekans`, `arbok`, `zubat`, `golbat`, `paras`, `parasect`, `clefairy`, `clefable`, `voltorb`, `koffing` — **conventions existantes** : statistiques et taux actuels, types modernes (Fée pour Mélofée / Mélodelfe, Normal/Fée pour Rondoudou / Grodoudou), apprentissages de Rouge/Bleu ; évolutions : Abo → Arbok (22), Nosferapti → Nosferalto (22), Paras → Parasect (24), Mélofée et Rondoudou → `item moon_stone`. 50 espèces.
- `data/pokedex/kanto.json` : 12 fiches (taille, poids officiels, description) + 7 notes des formes de base (annexe A).
- **CT** : `tools/gen_tm_compatibility.py` (J11) relancé sur 50 espèces → `tm_compatibility.json` (fichier **généré** : régénéré, jamais fusionné à la main, §1.2 n° 5) ; objet `tm01` (« CT01 — Ultimapoing », catégorie `tm`, `tm_number` 1, `teaches: mega_punch` ; permanent et jamais vendu par la catégorie, comme `tm34`).
- **Sprites provisoires** : `gen_placeholder_battlers.gd` étendu aux 12 (exigé par `test_battle_stage` pour les espèces de Dresseur ; l'adversaire est l'artwork officiel). Les 12 rejoignent la liste du futur lot de **dos peints** (chantier d'art du combat, hors J12).
- Tests : `test_pokemon_data` (50 espèces, learnsets résolus), `test_pokedex_library`, `test_tm_compatibility`, `test_trainer_library` (Dresseurs du J12 valides).

### 2.20 Drapeaux et sauvegarde : **aucune version nouvelle** (preuve)

Règle d'en-tête de `game/systems/save/save_system.gd` : incrémenter `VERSION` « quand un champ change de forme, **et aussi** quand on ajoute des champs qu'une build plus ancienne effacerait ». Inventaire de ce que le J12 écrit, champ par champ de `GameState.to_dict()` :

| Ce que le J12 mémorise | Champ (existant) | Forme |
|---|---|---|
| Dresseurs battus, défaites (`beaten_*`, `lost_*`), `mt_moon_fossil_chosen`, `mt_moon_got_<fossile>`, `route_3_entered`, `route_4_reached`, `got_<objet>` (visibles et cachés) | `flags` (tableau de chaînes) | inchangée |
| Corde Sortie, Pierre Lune, fossile, CT01 | `bag.items` (identifiant → quantité), `acquired` | inchangée |
| Objets trouvés | `found_items` (`{item, map, date}`) | inchangée |
| Grand moment `fossil` | `moments` (`{type, date, map, details}`, `details = {item}`) | inchangée |
| Nouvelles espèces, capacités, évolutions | `party`, `storage` (Pokémon : espèce, capacités…) | inchangée |
| Repos (sommeil) | `status` (J9) + `status_turns` (J11, v6) | inchangée |
| Position dans la grotte, Corde | `map`, `cell`, `facing` | inchangée |
| Point de repos du Centre | `heal_map`, `heal_spawn` | inchangée |
| Compagnon | `companion` (J11) | inchangée |
| Piège, Entrave, Destruction | **rien** : volatils de combat, l'autosave n'écrit jamais pendant un combat (`Boot._can_write` / `is_stable`) | — |

Aucun champ ajouté ni transformé → **pas de version nouvelle** : le J12 écrit la version de `main` après le J11 (**v6**, vérifié au T11 : `SaveSystem.VERSION = 6`, `Boot._can_write` / `is_stable` existent). La **v7** du J15 (Pension) est sur `jalon-15`, pas dans `main` : elle passera après le J12 (§1.2) ; si elle arrivait avant, le J12 suivrait `main` sans rien ajouter. Une build plus ancienne qui lirait une partie du J12 ne perd pas de champ ; elle écarterait les **valeurs** inconnues (espèce, capacité, objet) et l'a toujours fait en copiant l'original dans `save.json.rejected` (`Boot._keep_rejected_save`) — c'est le régime des J8 et J10, qui ont ajouté des espèces sans changer de version. **Garde** : toute tâche qui voudrait un champ nouveau (étape d'un événement en cours, compteur) s'arrête et revient à l'architecte (version + validation seule, règle 1).
Test `test_save_j12` : partie construite au B2F (R3 battu, chercheur non) → `to_dict` → JSON → `load_dict` → mêmes drapeaux, Sac, `found_items`, moments, Pokémon (Grodoudou, Pierre Lune en moins), position ; `SaveSystem.VERSION` inchangée par le J12.

### 2.21 Budgets et mesures (T8, T9, QA)

- ≤ 3 000 nœuds par carte (`NODE_BUDGET` des tests), mesuré **dès** la première construction de la Route 3 (§0.2 n° 19 ; parades : tri de visibilité de `DenseForest`, forêt plus aérée au cœur des masses, bosquets en grands modules).
- Mémoire « carte seule + voisines » (`tools/measure_map_cache.gd`) : Route 3 (Argenta + 1F ; le Centre, intérieur, n'est pas préchargé), 1F (Route 3 + B1F + B2F), B2F (1F + sas). Si 1F dépasse **64 Mo** avec ses voisines : les étages ne préchargent que l'étage voisin par l'échelle la plus proche du point d'arrivée [D, décision de l'architecte notée] ; changement de carte ≤ 1,5 × celui de Jadielle.
- fps : moyenne ≥ 58, creux ≥ 50 (Route 3, 1F, B2F avec ses halos et projecteurs) ; taille de l'APK notée.
- **Références J11 dans la même session** (T11, §0.4 n° 12) : la clôture du J11 a relevé sur le S21 une `tex` de 118–135 Mo (Route 1, combat), au-dessus du budget indicatif de 64 Mo, et 48–49 fps en combat de Dresseur dans la Forêt de Jade. Chaque session téléphone du J12 mesure aussi la Route 1 (marche + un combat) sur le **même téléphone** : un écart du J12 se juge contre cette référence, pas contre le budget seul. Le budget « carte + voisines ≤ 64 Mo » reste mesuré par `tools/measure_map_cache.gd` (cache de cartes, Mac) ; la `tex` totale du téléphone est notée en information.

### 2.22 Départs de débogage et carte de QA (T15, T18, T21, T25, T28)

- **Carte `qa_moves_j12`** — modèle réel : **`qa_switch_j13`** du J13 (T11, §0.4 n° 4 ; la carte `qa_status` du J11 n'a jamais existé) : outil `tools/build_qa_moves_j12.gd` (copie de `tools/build_qa_switch_j13.gd`, `j13-t14` à `3d58fe6` : tuiles provisoires, herbes, un Dresseur), données `data/npcs/qa_moves_j12.json`, `data/trainers/qa_moves_j12.json`, `data/dialogues/qa_moves_j12.json` ; herbes de la carte, table **forcée par la clé `wild` du départ** (J11 ; aucune table de rencontres en données) ; `MapCatalog.QA_PREFIX` / `is_qa_map` **repris mot pour mot** du J13 ; exception datée dans `test_map_catalog.test_no_qa_map_is_shipped` ; tests de zones, de lumière et de dialogues qui ignorent les cartes `qa_` (comme le J13). Contenu : herbes à table fixe (Nosferapti Nv. 22 Vampirisme / Onde Folie, Abo Nv. 20 Ligotage, Rondoudou Nv. 29 Entrave / Repos, Racaillou Nv. 21 Destruction — **QA seulement**, la vraie partie n'a aucun Racaillou sauvage ≥ 21), un Dresseur `smart` (Racaillou Destruction, Rondoudou Repos). **Pas de gravats** (validés en 12B sur le vrai 1F). Départ **`moves_qa`** (Racaillou N21 Destruction, Abo N20, Rondoudou N29, Nosferapti N22, remèdes, Potions ; la table forcée compte aussi un Voltorbe Nv. 20 qui lance Sonicboom [D]). **Retirée au T28** (carte, données, outil, exception du test, départ).
- Départs (`tools/debug_start/`, README complété ; clés du J11 disponibles : `wild`, `status_turns`, `companion`) : `route_3` (sortie est d'Argenta, badge, équipe Nv. 14–18 [D] de fin de J10/J11) ; `mt_moon_center` ; `mt_moon_1f` (avec `wild` + `terrain: rubble` pour forcer une rencontre de gravats, T20) ; `mt_moon_b1f` (avant R1) ; `mt_moon_b2f` (avant R3) ; `mt_moon_weak` (pour perdre contre R1 : reprise) ; `mt_moon_fossil` (R3 et chercheur battus, choix à faire) ; `moon_stone_qa` (Nidorina, Nidorino, Mélofée, Rondoudou, 2 Pierres Lune) ; `escape_rope_qa` (3 Cordes, 1F) ; `route_4` (sas). Un compagnon par départ de grotte (`companion`) pour 12B.

---

## 3. Tâches

Branche d'intégration **`jalon-12`** depuis `main` (copie dédiée), une branche par tâche (`j12-t<n>-<sujet>`) ; jamais de `pkill` ; chaque tâche met à jour `etat-projet.md` dans son commit ; textes **mot pour mot** du §20 et de l'annexe A validée.

#### T0 — architecte : plan (fait)

#### T1 — architecte : kit d'assets (série 14) — **maintenant** — **fait (2026-10-11, `j12-t1-kit`)** : 23 images + 3 conditionnels, fiche `docs/design/fiches-assets/serie-14-mont-selenite.md`
- Fiche `docs/design/fiches-assets/serie-14-mont-selenite.md` (une fiche par asset du §1.4 C : taille, emprise, couche, ombre, références recadrées `REF_R3_*` / `REF_MS_*`) ; `tools/art/serie14.py` (`--prompts`, `--refs`, `--commandes`, `--planche`, `--manifeste` **préparé, non lancé**, `--controle`) ; prompts d'attente des 4 personnages ; planche `build/art/MS_KIT_v1.png` (1 case = 48 px, héros à l'échelle).
- **CA** : chaque élément visible des deux vues validées a un asset (réutilisé, varié, nouveau) ou est abandonné explicitement ; aucun fichier de la liste §1.2 touché.

#### T2 — constructeur-monde (Mac, Codex) : série 14 → **12.0-art** — **fait (2026-10-11, `j12-t2-generation`, validé par Kevin)**
- `ART=/Users/kevinyankam/dev/kanto-2026/build/art python3 tools/art/serie14.py` (trois générations à la fois, corrections en `_r2`) ; repli si Codex refuse (Sbires Rocket, fossiles) : prompt collé dans l'app ChatGPT (précédent série 09). Planche de contact `build/captures/jalon12_assets/` → Kevin.
- **CA** : images validées par Kevin ; journal dans la fiche ; ni manifeste ni scène.

#### T3 — constructeur-monde (Mac) : planches Pokémon C-4 + lot parallèle → **12.0-art** — **fait (2026-10-11, `j12-t3-planches`)** ; intégration au T21
- 11 planches repos + marche 4 directions (gabarit de la série 13 du J11, ancres : planche de la forme précédente et héros validé) ; Nosferapti en vol (ombre au sol par le moteur, comme Papilusion) ; planche de contact → Kevin. **CA** : planches validées ; aucune intégration au compagnon avant T21.

#### T4 — constructeur-monde (Mac) : décors de combat → **12.0-art** — **fait (2026-10-11, `j12-t4-decors`)**
- `route_3_roche`, `mt_moon_galerie`, `mt_moon_chambre` (§2.18) par la chaîne CB.3. **CA** : validés par Kevin sur capture de combat Mac (`tools/capture_combat_cb3.sh`).

#### T5 — Kevin : lot de textes (annexe A) — **validé (2026-10-11, Q-3)**
- **CA** : validé en une passe ; bloque les données de T12 et T18 (pas le code).

#### T6 — constructeur-monde (Mac) : intégration de la série 14 — **maintenant**, après T2 — **fait (2026-10-11, `j12-t6-integration`)** : 24 entrées du manifeste, 32 scènes d'objets, 4 apparences + 2 objets fixes, 4 sols, 4 icônes ; second passage sans changement ; détail dans le journal de la fiche
- `serie14.py --manifeste` (entrées **en fin**), `preparer.py --source …` deux fois, règles `PaintedPropRules`, `build_painted_props.gd -- --nouveaux`, `build_character_frames.gd` (4 personnages, ajouts en fin), icônes `preparer_menu.py`. **CA** : second passage de `preparer.py` sans changement ; `test_painted_props` vert ; planche de contrôle relue.

#### T7 — architecte : fondations de carte — **fait** (2026-10-11, branche `j12-t7-fondations`, §9)
- `OverworldTiles.Kind.RUBBLE` + donnée `rubble` + TileSet régénéré ; `PaintedGround` : textures réglables (exports `base_texture`, `r_texture`, `g_texture`, défauts = herbe, pavés, chemin : cartes existantes **inchangées**) ; `LightGlow` (+ table des types de halo en données) ; `CaveLibrary` + `data/world/caves.json` ; `tools/cave_map_kit.gd`.
- Tests : `test_overworld_tiles`, `test_painted_ground` (défauts identiques), `test_light_glow` (réduction des animations), `test_cave_library`. **CA** : tests verts, import propre ; aucune carte existante modifiée (diff nul sur leurs `.tscn`).

#### T8 — constructeur-monde : Route 3, Centre, sas, raccord d'Argenta — **fait (2026-10-11, `j12-t8-route-3`, §9)**
- §2.1, §2.14 (carte), §2.15 (carte), §2.17, §2.18 (`route_3_roche`) ; cases des PNJ, objets et caches **réservées** d'après la grille (aucune donnée de PNJ) ; `lighting.json`, `zones.json` (cartes, services ; descriptions de l'annexe A une fois validées, T5), `interiors.json`, `rest_points.json`.
- Tests : `test_route_3` (grille de la scène = grille du plan ; critères de `plan_check_route_3.py` sur la vraie scène : D1/D2 inévitables par géométrie, rebords, raccords ; nœuds ≤ 3 000), `test_route_4`, `test_mt_moon_center`, `test_map_links`, `test_map_catalog`, `test_coming_soon` (sas), `test_map_light_profiles`, `test_pewter_city` (diff limité aux warps) ; captures `tools/capture_route_3.gd` (sortie, embranchement, pied de la montagne, Centre, entrée) relues contre la vue ; `[perf]` Mac et mémoire.
- **CA** : tests verts, captures 2340 × 1080 relues ; budget de nœuds tenu.

#### T9 — constructeur-monde : Mont Sélénite 1F / B1F / B2F — **maintenant**, après T6, T7 — **fait (2026-10-11, `j12-t9-mont-selenite`)** : trois étages construits, lumière, échelles ; repli « à venir » vers la Route 3 et le sas tant que le T8 n'est pas fusionné ; détail au §9
- §2.1, §2.2, §2.4 ; `tools/build_mt_moon.gd` ; gravats en tuiles `RUBBLE` ; halos ; profils `cave_*` ; décors `mt_moon_galerie` / `_chambre`.
- Tests : `test_mt_moon_maps` (grilles, échelles, graphe connexe, retour à l'entrée de partout, cases `g` = tuiles `RUBBLE`, goulets d'une case listés pour le compagnon, nœuds ≤ 3 000) ; captures + `luminance_grotte.py` (§2.4).
- **CA** : tests verts ; seuils de luminance tenus ; captures relues contre la vue (repères reconnaissables sans carte).

#### T10 — architecte : simulation préparée — **fait (2026-10-11, `j12-t10-simulation`)**
- `tools/simulate_mt_moon.gd` (modèle `simulate_brock.gd`) : Route 3 (combats sauvages tirés dans la vraie table + Hugo, Léa), R1, R3, chercheur ; équipes « naturelles » et partie réelle de Kevin (sauvegarde fournie). Lancé au T26.
- **Fait (2026-10-11, branche `j12-t10-simulation` depuis `jalon-12`)** : `tools/simulate_mt_moon.gd` (nouveau ; rien dans `game/` ni `data/`, aucun fichier du §1.2) lit un **scénario JSON** : `tools/sim/mt_moon_scenario.json` (valeurs du dossier 15 : tables Route 3 / 1F / B1F / B2F, D1–D6, R1–R3, chercheur, au format de `data/encounters/` et `data/trainers/` ; parcours de la grille : Hugo, H2/H3 4 cases, Léa, H4 4 cases, Centre, 1F-G1 3 cases, R1, B2F-G1 5 cases, R3, chercheur ; D4, D5, D6, R2 en détours ; 5 variantes avec / sans Centre, Potions, Antidote, fuite) et `mt_moon_scenario_demo.json` (réduit, espèces existantes). Vrai moteur ([Battle], IA, XP, évolutions), une graine = une partie, compteur de pas calmes commun ; joueurs `naif` / `attentif` repris du J10. Rapport : arrivée, défaites par étape, combats, victoires, fuites, tours, K.O., objets consommés, PV, niveaux. **Toute espèce, capacité ou objet absent des données est sauté** (message « SAUTÉ … », liste finale des identifiants manquants, **code 3**) ; scénario invalide → code 1 ; `--valider` (vérifie sans combattre), `--save` (équipe et Sac d'une sauvegarde), `--donnees` (Dresseurs et tables de `data/` à la place du scénario, pour le T26), `--seeds`, `--equipe`, `--variante`. Test `tests/integration/test_simulate_mt_moon.gd` (5, processus à part) + fixtures `tests/fixtures/sim/`. Au T26 : `--donnees --save <partie de Kevin>`.

#### T11 — architecte : alignement — **fait (2026-10-13, `j12-t11-alignement`)**
- `main` (J11 terminé, `267fcf1`) fusionné dans `jalon-12` (`1a3cad5`) ; plan réaligné sur le code réel : §0.3 (colonne « Réalité »), §0.4 (écarts et décisions), §1.2 (branches et conflits avec J13–J15), §2.x (noms, signatures, emplacements), tâches, critères, défauts. Détail au §9.

#### Ordre et parallélisme à partir du T12 (T11)

Quatre chaînes. Chaque flèche est une dépendance de **fichiers** ou de **données** (pas seulement
d'ordre) ; deux tâches en parallèle ne touchent pas les mêmes fichiers (vérifié sur les listes
ci-dessous). Les sessions téléphone restent **une à la fois, dans l'ordre** 12.0 → 12A → 12B →
12C → 12D (règle 1) ; le code peut prendre de l'avance sur elles.

```
A combat  : T12 ─→ T13 ─→ T14 ∥ T15 ─→ T16 (téléphone 12.0)
B monde   : T17 (∥ T12) ─→ T18 (après T12) ─→ T19 (téléphone 12A, après T16)
C grotte  : T20 (après T12 ; ∥ T13, T17) ─→ T21 (après T12, T20) ─→ T22 (téléphone 12B, après T19)
D Rocket  : T23 (après T20) ─→ T24 ─→ T25 (après T17, T21, T23) ─→ T26 ─→ T27 (téléphone 12C, après T22) ─→ T28 ─→ T29
```

**Tout de suite** : **T12 ∥ T17** (architecte, deux branches : données contre code du monde, aucun
fichier commun). Dès T12 fusionné : **T13 ∥ T20** (combat contre grotte, aucun fichier commun) et
**T18** (constructeur-monde, dès que T17 l'est aussi). T23 attend T20 (mêmes fichiers :
`item_data.gd`, `item_library.gd`, `menu_director.gd`, `bag_query.gd`, `boot.gd`).

#### T12 — architecte : données — après T11 (T5 validé) — **à lancer**
- §2.19 (12 espèces dans `kanto_mt_moon.json`, Pokédex, sprites provisoires, compatibilités CT régénérées), §2.10 (21 capacités dans `moves/mt_moon.json` : les genres nouveaux en `pending_effects` — `drain`, `trap`, `disable`, `rest`, `fixed_value` — activés au T13 ; les 5 déjà copiées par le J13 à l'identique ; description de Destruction remplacée, n° 45), objets dans `data/items/mt_moon.json` (`escape_rope`, `moon_stone`, `dome_fossil`, `helix_fossil` — sans `field_use` ni `obtained`, champs créés aux T20 / T23 — et `tm01`), Pokédex (annexe A). Fichiers : données seulement + `gen_placeholder_battlers.gd` + tests de données.
- **CA** : tests verts ; aucune carte touchée ; `--valider` de `tools/simulate_mt_moon.gd` ne signale plus d'espèce manquante (code 0 ou seulement des capacités en attente).

#### T13 — architecte : moteur de combat — après T12
- §2.10 (moteur, IA, événements, textes ; alignement §0.4 n° 1–3, 8, 11) : `move_effect.gd`, `pokemon_data.gd` (`_EFFECT_KEYS`), `battler.gd`, `battle.gd`, `battle_ai.gd`, `battle_event.gd`, `battle_text.gd`, `status_rules.gd` (`apply_rest`), `messages.json` ; activation (retrait des `pending_effects`) de `leech_life`, `wrap`, `bind`, `fire_spin`, `disable`, `rest`, `self_destruct`, `explosion`, `sonic_boom`.
- **CA** : tests verts ; Pierre et le rival inchangés (`test_brock_sequence`, `test_rival_route22` — instable connu sous charge, relancé seul : §0.4 n° 12) ; `tools/simulate_brock.gd` relancé : résultats identiques à la référence du J11 (`jalon-11.md` §8, « Équilibrage de Pierre ») — l'équipe de Pierre a ses capacités fixées (pas d'Étreinte ni de Destruction) ; statuts du J11 et Patience inchangés.

#### T14 — ui-mobile : interface de combat — après T13 (∥ T15)
- §2.10 (interface) : carte de capacité « BLOQUÉE » grisée et non touchable (`Battle.get_disabled_move()`), raison « Impossible de changer » sur les cartes de l'équipe (`Battle.is_player_trapped()`), fuite refusée affichée sans action (`flee_failed`), icône **Fée** (`TypeBadge.ICONS`, nouvelle icône SVG). **CA** : captures relues (capacité bloquée, ligoté, Fée) ; `game/ui/battle/`, `game/ui/components/type_badge.gd`, `battle_director.gd` (refus avant soumission) et `ui_tokens.gd` (fin de fichier) seuls touchés.

#### T15 — constructeur-monde : carte `qa_moves_j12` + départ — après T13 (∥ T14)
- §2.22 (modèle `qa_switch_j13` du J13, `MapCatalog.is_qa_map` repris mot pour mot). **CA** : tests verts (`test_qa_moves_j12` sur le modèle de `test_qa_switch_j13`) ; capture relue.

#### T16 — qa-mobile : **session 12.0** → Kevin
- Départ `moves_qa` : chaque effet vu (drain, piège et ses refus, Entrave et sa fin, Repos et réveil, Destruction, double K.O., Sonicboom), messages lisibles, IA ; espèces dans le Pokédex ; mesure de référence Route 1 (§2.21). **CA** : rapport `build/qa/jalon12_t16/` ; validation de Kevin.

#### T17 — architecte : briques du monde — après T11 (∥ T12) — **à lancer**
- §2.8 (`unless_flags` : `interact_point.gd`, `interaction.gd`, `interaction_controller.gd`), §2.11 (`rematch`, `leave`, `lost_<id>` : `npc_spec.gd`, `npc_roster.gd`, `trainer_encounter.gd`). **CA** : tests verts ; Dresseurs du J9 et du J10 inchangés (`test_trainer_encounter`, Dresseurs de la forêt, Liam).

#### T18 — constructeur-monde : la vie de la Route 3 (12A) — après T12, T17 (T8 fait)
- PNJ, Dresseurs, Pokémon d'ambiance, objets visibles et caché, panneaux, rencontres, déclencheur `route_3_entered`, objectifs, Centre (PNJ), départs `route_3`, `mt_moon_center`. Tests `test_route_3_life`, `test_route_3_trainers`, `test_hidden_items` (Route 3). **CA** : tests verts, captures relues.

#### T19 — qa-mobile : **session 12A** → Kevin — après T18 et la validation de 12.0
- Vraie partie depuis Argenta (badge) : garde, Route 3 entière, D1/D2 inévitables, D3–D6, Rondoudou, Réveil caché (bouton, toast, absent ensuite), Centre (soin, toast « Mont Sélénite », point de repos), fps / mémoire (avec la référence Route 1, §2.21) / durée de traversée.

#### T20 — architecte : moteur de la grotte — après T12 (∥ T13, T17)
- §2.5 (grille, directeur, `RubbleBurst`, `override_table` + `terrain` de la clé `wild`), §2.6 (Corde : `field_use`, `FieldItemRules`, `field_item_requested`, `BagQuery`), §2.2 (placement du compagnon hors warp dans `CompanionController`), §2.3 (`cave` dans `CompanionCatalog.CONTEXTS` et `CompanionRules.CONTEXT_LINES`), §2.4 (`LightGlow.set_reduce_motion` branché dans `Boot._apply_settings`). Fichiers : `game/pokemon/encounters/*`, `grid_world.gd`, `map.gd`, `item_data.gd`, `item_library.gd`, `field_item_rules.gd`, `menu_director.gd`, `bag_query.gd`, `boot.gd`, `debug_start.gd`, `companion_*.gd`, `game/world/rubble/*`. **CA** : tests verts ; herbes et compagnon du J11 inchangés.

#### T21 — constructeur-monde (+ ui-mobile en relecture) : la vie de la grotte (12B) — après T20, T12 (T9, T3 faits)
- Rencontres `mt_moon.json`, randonneur, panneau, caisses et lampe (examens), Corde au sol, stock d'Argenta, intégration des **11 planches** de T3 (manifeste, `LOOKS`, `companions.json` : espèces + `contexts` → `cave` ; conflit possible avec `j11-pikachu-compagnon`, garder les deux côtés), phrase « grotte » (`companion.json`), départs `mt_moon_*`, `escape_rope_qa`. Tests `test_mt_moon_life`, `test_escape_rope`, `test_hidden_items` (1F, B2F sans contenu de 12C). **CA** : tests verts, captures.

#### T22 — qa-mobile : **session 12B** → Kevin — après T21 et la validation de 12A
- Lisibilité **luminosité par défaut**, repères, échelles, gravats (rencontres, intro), couloirs calmes, Corde (refus dehors, retour devant l'entrée, Sac), compagnon (galeries, goulets, échelles : jamais posé sur l'échelle), halos coupés par « Réduire les animations », sauvegarde / reprise dans chaque étage, fps, mémoire.

#### T23 — architecte : moteur de l'événement et de la pierre — après T20 (mêmes fichiers)
- §2.9 (`StoneUse`, `evolution_item_requested`, `play_item`, `cancellable` dans le candidat et la vue, `evolution_applied`, retrait de la pierre par Boot ; `field_use` de `moon_stone`), §2.13 (`confirm_cutscene`, étape `moment`, type `fossil`, champ `obtained` + données des fossiles). **CA** : tests verts ; évolutions de fin de combat inchangées (ARRÊTER, retour Android) ; toast des CT inchangé.

#### T24 — ui-mobile : Sac et écran d'évolution — après T23
- UTILISER des objets AVENTURE (seulement avec `field_use`), sélecteur COMPATIBLE / INCOMPATIBLE pour la pierre (`show_reason`), bandeau de refus de la Corde, écran d'évolution sans ARRÊTER, ligne de la frise `fossil` ; captures.

#### T25 — constructeur-monde : Team Rocket, chercheur, fossiles, Pierres Lune, CT01 (12C) — après T17, T21, T23
- §2.11–§2.13 ; Pierre Lune visible (B1F) et cachée (B2F), CT01 ; départ `mt_moon_fossil`, `moon_stone_qa`. Tests `test_mt_moon_rocket`, `test_mt_moon_fossil`, `test_moon_stone`, `test_save_j12`.

#### T26 — architecte : équilibrage — après T25
- `simulate_mt_moon.gd -- --donnees --save <partie de Kevin>` : taux de victoire et durées (R1 ≈ 100 s, R3 ≈ 150 s, chercheur ≈ 130 s estimés par la grille) ; **information pour Kevin**, aucune donnée changée sans lui. **À fournir par Kevin** : sa sauvegarde v6 de fin de J11.

#### T27 — qa-mobile : **session 12C** → Kevin — après T24, T25 et la validation de 12B
- R1 (« Hé, toi ! »), R2, R3 (3 bulles, décor de la chambre), départs et absence au retour, défaite → reprise, chercheur (méprise, combat, partage), choix NON puis OUI (définitif), toast « … obtenu », Grand moment dans l'écran Dresseur, Pierre Lune visible et cachée, évolution sans ARRÊTER, CT01, reprise après fermeture à chaque étape.

#### T28 — constructeur-monde puis qa-mobile : fin du J12 (12D)
- Sas (panneau, `route_4_reached`), objectifs, **retrait de `qa_moves_j12`** (carte, données `qa_*`, outil, exception de `test_no_qa_map_is_shipped`, départ `moves_qa`) ; README des départs. `MapCatalog.is_qa_map` reste (le J13 s'en sert).
- QA finale (qa-mobile, **vraie partie de Kevin**, sans drapeau de débogage) : Argenta → Route 3 → Centre → grotte → événement → sas → « AZURIA — À venir » ; sauvegarde et reprise dans la grotte ; mesures. **CA** : rapport `build/qa/jalon12_t28/` ; validation de Kevin ; fusion de `jalon-12` dans `main` (copie d'intégration ; `project.godot` et filtre d'export vérifiés) ; **prévenir les sessions J13, J14, J15** (note dans `etat-projet.md`) : leur prochaine fusion de `main` apporte le J12.

#### T29 — architecte : clôture
- `etat-projet.md`, roadmap ; passation au J13 : remplacement du sas par la Route 4 (identifiant `route_4`, spawn `from_mt_moon` (3, 6), repère de coordonnées du sas), décors de combat de la Route 4, dos peints des 12 espèces, sons d'accroche (`rubble_sound_requested`) ; liste des noms livrés contre les noms cités par les plans des J13–J15 (§1.2 n° 2).

---

## 4. Critères d'acceptation par sous-jalon

**12.0-art** — Kevin valide les planches de contact (décors, personnages, Pokémon, icônes, décors de combat) ; chaque asset a sa fiche ; aucun Pokémon sans planche validée dans `companions.json`.

**12.0** — chaque capacité ajoutée a son effet ou sa mention « Sans effet dans le moteur actuel. » ; drain plafonné et annoncé ; piège : 4–5 tours, ⅛ par tour, fuite et changement refusés avec leur texte, libération ; Entrave : 4 tours, capacité grisée et non touchable, fin annoncée, échec annoncé, IA qui ne la choisit pas ; Repos : PV pleins, manque exactement 2 tours, échec à PV pleins ; Destruction : K.O. du lanceur même s'il rate, double K.O. final perdu par le lanceur ; Sonicboom : 20 PV fixes ; statuts du J11, Patience et poison du J9 inchangés ; 12 espèces au Pokédex (Fée visible) ; ≥ 55 fps en combat (jugé contre la référence J11 relevée dans la même session, §2.21) ; tests verts, import propre.

**12A** — raccord Argenta ↔ Route 3 sur les trois rangées (et garde inchangé avant le badge) ; **D1 et D2 impossibles à contourner**, D3–D6 évitables sur leur chemin ; récompenses du §3.2 ; rencontres H1–H4 (table, Rondoudou vu) ; 3 objets visibles ; **Réveil caché** : rien d'affiché avant d'être face à l'indice, toast, plus rien ensuite (même après rechargement) ; Centre : soin, toast « Point de repos enregistré — Mont Sélénite », défaite sur la Route 3 → réveil au Centre ; panneaux ; objectif « traverser le Mont Sélénite. » ; traversée directe mesurée (grille : ≈ 5 min 46 s avec Hugo et Léa) ; ≥ 58 fps moyens, creux ≥ 50 ; nœuds ≤ 3 000.

**12B** — sur le téléphone **sans augmenter la luminosité** : chemins, parois, échelles, gravats et personnages distinguables dans les trois étages ; repères reconnus (colonne du carrefour, camp, éclats, mare, lampes) ; échelles dans les deux sens, fondu comme une porte ; rencontres **seulement** sur les gravats, intro éboulis ≤ 2 s ; couloirs calmes ; **Corde** : refusée sur la Route 3 / à Argenta / au Centre (texte), acceptée dans les trois étages → devant l'entrée côté Route 3 tourné ↓, consommée, ni soin ni point de repos ; achat à Argenta 550 ₽ ; compagnon visible dans les galeries, masqué dans les goulets puis de retour, **jamais posé sur une échelle** à l'arrivée, rentré au Centre, phrase « grotte » ; halos sans vacillement avec « Réduire les animations » ; **reprise d'une partie quittée dans chaque étage** (position, objets, Dresseurs, compagnon) ; luminance Mac tenue ; fps, mémoire « carte + voisines », changement d'étage ≤ 1,5 × Jadielle.

**12C** — R1 et R3 inévitables, R2 évitable ; « Hé, toi ! Ce passage est interdit. Fais demi-tour. » ; après chaque défaite d'un Sbire : réplique, départ, absence au retour et au rechargement ; défaite du joueur → Centre → réplique de reprise ; R3 : 3 bulles au plus, décor « chambre des fossiles » ; chercheur seulement après R3 : méprise, combat inévitable, partage ; **choix du fossile définitif** (NON ne fait rien ; OUI → objet clé, toast, l'autre disparaît, aucun moyen de l'avoir ensuite) ; **Grand moment** unique dans l'écran Dresseur ; Pierre Lune visible ramassée, cachée trouvée ; Sac → Pierre Lune → COMPATIBLE / INCOMPATIBLE → évolution **sans ARRÊTER**, retour Android sans effet, pierre consommée une fois ; CT01 apprise (COMPATIBLE / INCOMPATIBLE du J11) ; reprise après fermeture à chaque étape de l'événement sans rien rejouer ni perdre.

**12D** — sas : panneau, raccord « AZURIA — À venir » (build de développement), retour par l'échelle ; objectif « continuer vers Azuria. » ; carte de QA retirée (carte, données `qa_*`, outil, exception du test ; `MapCatalog.is_qa_map` gardé pour le J13) ; **vraie partie de Kevin** Argenta → sas sans régression (J1–J11 sur les points de contrôle) ; sauvegarde relue par l'APK final (version inchangée : v6, ou celle de `main` au moment de la fusion) ; aucun nom du §1.2 n° 2 changé sans note ; `tools/test.sh` vert, import propre ; budgets tenus.

---

## 5. Risques

| Risque | Effet | Parade |
|---|---|---|
| ~~Le J11 tarde~~ | — | **levé** : J11 terminé et fusionné le 2026-10-13 |
| ~~Le J11 livre autre chose que son plan~~ | — | **traité au T11** : §0.3 (colonne « Réalité »), §0.4 |
| **J13, J14, J15 avancent en parallèle sur les mêmes fichiers** (combat, dialogues, scènes, Sac, Boot, données uniques) | conflits à la fusion ; noms du J12 attendus par leurs plans | le J12 fusionne **le premier** dans `main` ; ajouts en fin, données dans des fichiers à part, noms figés (§1.2) ; tout écart noté dans `etat-projet.md` |
| **Mémoire et fps déjà tendus à la fin du J11** (`tex` 118–135 Mo, forêt 48–49 fps en combat sur le S21) | un écart du J12 mal attribué | référence J11 relevée dans chaque session téléphone (§2.21) ; budget « carte + voisines » mesuré à part |
| **Grotte illisible sur le téléphone** | critère central de 12B raté | lumière peinte d'abord, seuils de luminance mesurés sur Mac (T9), profils réglables en données, halos ; essai téléphone dès que T9 est prêt (capture, pas validation) |
| **Budget de nœuds de la Route 3** (82 × 38, forêt) | fps, budget dépassé | mesure au premier passage de T8 ; parades §2.21 |
| **Mémoire des étages** (1F précharge trois cartes) | creux, changements lents | mesure (§2.21) ; préchargement réduit (défaut noté) |
| **Codex refuse la Team Rocket, les fossiles ou un Pokémon** | délai d'art | repli app ChatGPT (série 09) ; prompts sans marque, description de l'uniforme (B-7) |
| **Compagnon coincé** (goulets d'une case, échelles, poche de l'échelle C) | gêne, compagnon perdu | règle « masqué sans case libre » (J11) + placement hors warp (§2.2) ; goulets listés par `test_mt_moon_maps` |
| **Bouton contextuel qui « trahit » l'objet caché** | mécanique moins secrète | Q-2 ; l'indice reste discret, le bouton n'apparaît que face à lui |
| **Fermeture pendant la scène du chercheur** (combat gagné, autosave différé tant que la scène tourne) | combat rejoué | conforme au régime existant (aucune sauvegarde au milieu d'une scène) ; noté ; les étapes durables (`beaten_*`, choix) sont posées et sauvegardées en fin de scène |
| **Destruction et double K.O.** | issue de combat inattendue | règle G+ testée (§2.10) |
| **Régénération d'Argenta** | diff inattendu | graines fixes, test du diff limité aux warps |
| **J13 et le sas** | positions sauvegardées sur une case devenue arbre | passation : garder le repère de coordonnées, test de reprise au J13 |

---

## 6. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Validations | 12.0-art sur planches de contact ; 5 sessions téléphone (12.0, 12A, 12B, 12C, 12D) |
| Branches | `jalon-12` depuis `main` ; `main` (J11 terminé) fusionné au T11 (`1a3cad5`) ; `jalon-12` ne fusionne que `main` et entre dans `main` **avant** les J13–J15 ; ajouts en fin, noms figés (§1.2) |
| Fichiers de données | nouveautés à part : `species/kanto_mt_moon.json`, `moves/mt_moon.json`, `items/mt_moon.json` ; `tm_compatibility.json` régénéré, jamais fusionné à la main |
| Identifiants | `route_3`, `mt_moon_center`, `mt_moon_1f`, `mt_moon_b1f`, `mt_moon_b2f`, `route_4` ; Dresseurs `route_3_*`, `mt_moon_rocket_1/2/3`, `mt_moon_researcher` ; spawns `_n/_c/_s`, `_w/_e` |
| Catégorie grotte | `interior = false` + `data/world/caves.json` (aucun champ de scène) |
| Échelles | warps `STEP_ON` sans direction, orientation opposée à l'échelle, compagnon jamais placé sur un warp |
| Gravats | tuile `RUBBLE` ; taux 25, rampe 15 → 20, compteur de pas calmes commun avec les herbes ; intro éboulis ≈ 0,6 s + demi-tour |
| Lumière | profils `cave_1f` > `cave_b1f` = `cave_b2f` ; halos additifs générés (≤ 16 par étage, alpha ≤ 0,35), vacillement coupé par « Réduire les animations » ; aucune `Light2D` ; seuils Mac : luminance sol ≥ 0,22, sol / paroi ≥ 2,0 |
| Corde Sortie | AVENTURE, 550 ₽ à Argenta sans condition, 1 au 1F ; vers `route_3` / `from_mt_moon_w` tourné ↓ ; refus dans le bandeau du Sac |
| Pierre Lune | AVENTURE (« OBJETS » n'existe pas), jamais vendue ; K.O. compatible ; retour au monde après l'évolution ; `StoneUse.Check` à deux états ; `cancellable` vrai par défaut ; pierre retirée par Boot dans `evolution_applied` |
| Objets cachés | point d'examen sur la case-indice, disparaît une fois trouvé ; aucune phrase, toast standard ; EXAMINER face à l'indice (Q-2) |
| Sbires | départ : chemin `leave` puis fondu 0,2 s, sur place si impossible ; reprise par `lost_<id>` |
| Chercheur | déclencheur au bas du couloir (25..26, 27) ; s'approche du joueur ; se range en (15, 30) |
| Fossiles | deux objets sur la dalle, choix par EXAMINER ; toast « <fossile> » / « obtenu » par le champ d'objet `obtained` (forme des CT) ; drapeaux `mt_moon_fossil_chosen`, `mt_moon_got_<fossile>` |
| Effets de capacités | drain ½ (≥ 1) ; piège 4–5 tours, ⅛, après poison et Vampigraine ; Entrave 4 tours, échec sans capacité précédente ; Repos : `status_turns = 2` sans tirage (`StatusRules.apply_rest`), manque 2 tours ; Destruction : K.O. même en ratant, double K.O. perdu par le lanceur ; IA `smart` : Destruction à ≤ ¼ PV ; volatils sur le `Battler` ; Entrave filtrée dans `Battler.usable_moves()` ; fuite et changement refusés quand piégé **sans tour perdu** (G+) ; Sonicboom : `fixed_damage` mode `value`, 20 |
| Carte de QA | `qa_moves_j12` sur le modèle de `qa_switch_j13` (J13), herbes forcées par `wild`, sans gravats ; `MapCatalog.is_qa_map` repris du J13 |
| Compagnon (alignement T11) | contexte `cave` ajouté aux deux constantes du J11 ; jamais posé sur un warp à l'arrivée (Callable du contrôleur) |
| Mesures téléphone | référence J11 (Route 1, marche + combat) relevée dans chaque session du J12 sur le même téléphone |
| Espèces | stats et taux actuels, types modernes, apprentissages RB ; 21 capacités ; sprites provisoires ; dos peints hors J12 |
| Personnages | Fillette, Sbire ♂ et ♀ (attente « creuse »), chercheur de terrain : nouveaux ; voyageur `traveler`, randonneuse `hiker`, randonneur `mountaineer` ; deux Dresseurs d'une même classe partagent leur modèle |
| Déclencheurs | `route_3_entered` (1, 25..27) ; `route_4_reached` (4, 5..9) |
| Budgets | ≤ 3 000 nœuds ; moyenne ≥ 58 fps, creux ≥ 50 ; mémoire « carte + voisines » ≤ 64 Mo, sinon préchargement réduit ; changement de carte ≤ 1,5 × Jadielle |
| Sauvegarde | version de `main` après le J11 (**v6**, vérifiée au T11), aucune nouvelle |

---

## 7. Questions pour Kevin — tranchées le 2026-10-11 (toutes les recommandations retenues)

**Décisions de Kevin (2026-10-11)** : **Q-1 oui** (T1–T4, T6–T10 lancés avant la clôture du J11, sur `jalon-12` non fusionnée) ; **Q-2 oui** (EXAMINER face à l'indice, sans scintillement ni son) ; **Q-3 : lot de l'annexe A validé**.

Questions telles que posées :

- **Q-1 — Lancement avant la clôture du J11.** C-7 met le **code** après le J11 et laisse l'art avancer. Ce plan fait partir aussi, sur la branche `jalon-12` non fusionnée, les **cartes sans combat** (Route 3, Centre, sas, trois étages : décor, lumière, échelles, gravats peints), leurs outils et des fondations de carte qui ne touchent ni au combat, ni à la sauvegarde, ni aux fichiers du J11 (§1.2 : T1–T4, T6–T10). *Recommandation : oui — c'est ce qui permet de juger la lisibilité de la grotte sur captures bien avant 12B ; rien de cela n'entre dans `main` avant la fin du J12.*
- **Q-2 — Objets cachés et bouton contextuel.** Sur téléphone, on n'interagit qu'avec le bouton contextuel, qui n'apparaît que face à quelque chose d'examinable ; face à l'indice (caillou, éclat), il affichera donc EXAMINER — ce qui révèle l'objet à qui s'arrête devant. *Recommandation : l'accepter (rien ne s'affiche avant d'être face à l'indice, aucun scintillement, aucun son : c'est le décor qui guide, le bouton ne fait que confirmer).* Alternatives : rendre examinables d'autres cailloux sans objet (leurres, textes en plus) ; ou une règle d'interface nouvelle (bouton « INTERAGIR » toujours visible), qui change l'interface du jeu entier.
- **Q-3 — Lot de textes de l'annexe A** (non couverts par le §20) : 12 descriptions et 7 notes de Pokédex, descriptions des capacités ajoutées, descriptions et sous-titres des zones Route 3 / Mont Sélénite / Route 4, textes de combat manquants (Étreinte, Danse Flamme, changement refusé, « BLOQUÉE »), présentation du Grand moment (texte n° 30 réparti en titre / détail). *Recommandation : relecture en une passe, comme aux J9–J11 ; bloque les données (T12, T18), pas le code.*

**T11 (2026-10-13) : aucune question nouvelle.** Les écarts entre le plan et le J11 livré sont tous techniques (§0.4) ; les deux points qui frôlent le game design ont une réponse écrite : Sonicboom agit (sa description validée, annexe A.2, n'a pas la mention « Sans effet ») ; la fuite refusée quand on est piégé ne coûte pas de tour (règle G+ retenue par C-1).

**À fournir par Kevin** (pas une question) : la sauvegarde de sa vraie partie à la fin du J11 (équipe, niveaux) pour la simulation (T26) et le départ `route_3`.

---

## 8. Premières tâches à lancer maintenant (Q-1 accepté le 2026-10-11)

1. Créer **`jalon-12` depuis `main`** dans une copie dédiée.
2. **T1** (architecte) : kit de la série 14 → **T2** (Mac, Codex) → planche de contact pour Kevin.
3. En parallèle : **T3** (planches Pokémon), **T4** (décors de combat), **T7** (fondations de carte), **T10** (outil de simulation) ; Kevin relit l'annexe A (**T5**).
4. Après T2 et T7 : **T6** (intégration), puis **T8** ∥ **T9** (cartes), captures relues sur Mac.
5. ~~À la clôture du J11 : T11~~ **fait (2026-10-13)**. Suite : **T12 ∥ T17** tout de suite, puis T13 ∥ T20, T18 ; ordre complet au §3 (« Ordre et parallélisme à partir du T12 »).

---

## 9. Fait

- **T11 — alignement sur le J11 livré (2026-10-13, architecte, branche `j12-t11-alignement`
  depuis `jalon-12` à `1a3cad5`)** — documentation seulement (aucun fichier de `game/`, `data/`,
  `tests/`) :
  - **Fusion** de `main` (J11 terminé, `267fcf1`) dans `jalon-12` : commit `1a3cad5` (conflits
    résolus dans `assets/world/catalogue.json`, `etat-projet.md`, `build_character_frames.gd` :
    les deux côtés gardés). Import propre ; `tools/test.sh` sur `1a3cad5` : **3 956 tests, 3 956 verts**, 0 en attente, 0 échec (288 scripts, 156 018 assertions, 782 s ; relancé au T11 dans la copie du T11).
  - **Vérifié dans le code** : §0.3 (colonne « Réalité » : tout est livré ; écarts : pas de
    `status.json`, Patience sur le `Battler`, pas de `cancellable`, contexte de compagnon en
    constantes, placement possible sur un warp, pas de carte `qa_status`, T18 partiel) ; §0.4
    (12 points, une décision technique chacun : Repos = `status_turns = 2` par
    `StatusRules.apply_rest` ; volatils du J12 sur le `Battler` ; Entrave filtrée dans
    `Battler.usable_moves()` ; changement refusé par `is_legal`, pas `check_switch` ; Sonicboom
    actif par un mode `value` ; champ `obtained` pour le toast des fossiles ; `StoneUse.Check` à deux
    états ; pierre retirée par Boot ; `qa_moves_j12` sur le modèle de `qa_switch_j13` du J13, sans
    gravats ; `cave` dans `CompanionCatalog.CONTEXTS` et `CompanionRules.CONTEXT_LINES` ; compagnon
    jamais posé sur un warp ; `LightGlow` branché au T20 ; clé `wild` avec `terrain`).
  - **§1.2 réécrit** : la liste des fichiers du J11 tombe ; personne d'autre sur `main` ; J13
    (`jalon-13`, construite depuis `jalon-12` à `5b3fe9b`, code déjà avancé), J14 et J15 (sauvegarde
    v7) avancent en parallèle sur les mêmes fichiers → le J12 fusionne **le premier**, ne fusionne
    que `main`, garde ses noms (liste figée), ajoute en fin, met ses données nouvelles dans des
    fichiers à part ; `tm_compatibility.json` se régénère.
  - **§2.x** corrigés (noms, signatures, emplacements) sans changer de décision ; **§3** : T12–T29
    réécrites (dépendances de fichiers, quatre chaînes ; **T12 ∥ T17 tout de suite**, puis
    T13 ∥ T20 et T18) ; **§4** critères, **§5** risques, **§6** défauts complétés ; **§7** : aucune
    question nouvelle.

- **T9 — Mont Sélénite 1F / B1F / B2F (2026-10-11, branche `j12-t9-mont-selenite`, depuis
  `jalon-12`)** :
  - **Outil** `tools/build_mt_moon.gd -- --etage=1f|b1f|b2f|tous` (deux passes masque / scène,
    graines fixes) sur `tools/cave_map_kit.gd`, étendu : `place_walls` (parois en modules
    d'après la grille : **faces** 3 × 2 sur les cases `#` au-dessus d'une galerie, coupées à
    une case si la paroi est mince ; **bords latéraux** une tranche de 96 px par case — chapeau
    en haut, pied en bas, milieu entre les deux — ; **lèvres** au nord des masses ; jamais sur
    une galerie, découpe `region_rect`), `is_embedded` (repère bloqué pris dans la paroi :
    masse peinte dessous, pas de module, le repère se voit — lampes du couloir du gardien,
    indices au fond d'une niche), `add_sprite` (objet réduit à son `Sprite2D` : ses réglages
    propres sont enregistrés, ceux d'un enfant d'instance étaient perdus). Les éclats `*`
    comptent comme masse (texture G).
  - **Cartes** `mt_moon_1f` (292 nœuds, 8 halos), `mt_moon_b1f` (179, 8), `mt_moon_b2f`
    (207, 13) ; masques `assets/world/maps/mt_moon_*_ground.png`. Repères : colonne du
    carrefour, colonnes de B2F, rochers, éclats (un halo par groupe), lampes de chantier,
    projecteurs de la chambre (les deux du milieu braqués sur la dalle : halo entre eux et
    elle), caisses R, tranchées (celle de B1F étirée à 4 cases), mare, puits de jour (décal +
    halo), dalle et **fossiles posés sur la dalle** (pied relevé de 30 px), indices `x`,
    panneau de l'entrée (décor ; son texte au T21). Échelles : décor au sol + warp `STEP_ON`
    sans direction ; **échelle C (B1F)** : l'image montante ramenée à 128 px dans sa case (le
    trou au plafond débordait sur la case d'arrivée). Entrée 1F → `route_3` /
    `from_mt_moon_w|e`, sortie B2F → `route_4` / `from_mt_moon` : **repli « à venir »** tant
    que ces cartes manquent (retour sur l'arrivée) ; `test_mt_moon_maps` exige de relancer
    l'outil quand elles existent.
  - **Données** : `lighting.json` (`cave_1f` > `cave_b1f` = `cave_b2f` : étalonnage froid,
    liseré froid faible, aucune ombre portée, ombres de contact, vent 0), `zones.json`
    (`mt_moon` : trois étages, sous-titre et description de l'annexe A), `decors.json`
    (`mt_moon_galerie` sur les trois étages, `mt_moon_chambre` sur B2F (14, 19) → (37, 35)).
  - **Mesures (Mac)** : `tools/capture_mt_moon.sh` (2340 × 1080, fiche de caméra par vue) +
    `tools/art/luminance_grotte.py` : sol 0,22–0,37 (luminance relative WCAG), rapport
    sol / paroi 4,4–9,1 sur les 15 vues 1:1 (seuils 0,22 et 2,0 tenus) ; contraste du héros
    (moyenne pixel par pixel) 2,8–3,5 contre 4,4 dans la Forêt de Jade (sol clair : à juger
    sur téléphone). fps Mac 115–120 (plafond), 19–28 appels de dessin. Mémoire
    « carte + voisines » (`measure_map_cache.gd -- --route=mt_moon`) : 6,2 Mo (≤ 64 : pas de
    repli). Chargement (`measure_map_load.gd`, médiane) : 1F 284 ms, B1F 132 ms, B2F 136 ms,
    Jadielle 933 ms.
  - Tests : `test_mt_moon_maps` (nouveau), `test_cave_map_kit` (parois, sol peint effectif),
    `test_map_catalog` (grottes effectives), `test_map_links` (étages ; Route 3 et sas en
    parallèle), `test_overworld_tileset` (grottes exclues), `test_lighting_library`. Import propre ;
    `tools/test.sh` : 3 797 tests, 3 794 verts, 3 en attente (entrée vers la Route 3, sortie
    vers le sas, sortie de la Corde : T8), 0 échec.

- **T7 — fondations de carte (2026-10-11, branche `j12-t7-fondations`, depuis `jalon-12`)** :
  - **Gravats** : `OverworldTiles.Kind.RUBBLE` (rangée 13, en fin d'enum), `DATA_RUBBLE`,
    `is_rubble_kind` ; tuile provisoire (`gen_placeholder_tiles.gd`, sol ardoise semé de cailloux) ;
    couche de données `rubble` **ajoutée en dernier** à `overworld.tres` **et** à `interior.tres`
    (`gen_placeholder_interior_tiles.gd` : même ordre de couches, test existant) ; diff des `.tres`
    limité aux ajouts, rangées 0–12 de l'atlas identiques au pixel ; aucune carte ne pose de gravats
    (test). **Non lue** par `GridWorld` / `EncounterDirector` (T20).
  - **`PaintedGround` à textures réglables** : exports `base_texture`, `r_texture`, `g_texture`
    (nuls = herbe, pavés, chemin), `get_textures()`. Une carte construite sans réglage n'enregistre
    aucune propriété nouvelle ; aucun `.tscn` de carte modifié. **Preuve au pixel près** :
    `tools/capture_painted_ground.gd` (sol seul de Jadielle, Argenta, Route 2 sud et nord, forêt,
    Route 22, Route 1 ; carte entière + détail 1:1) avant / après : écart max **0 / 255** sur les
    14 images, pour les scènes enregistrées **et** pour un sol reconstruit à neuf (`--fresh`,
    ce que fera la régénération d'Argenta au T8). Bourg Palette exclu (mer animée).
  - **`LightGlow`** (`game/world/lighting/light_glow.gd`, `Sprite2D` additif, dégradé radial
    généré, partagé ; un matériau par type qui vacille, un seul pour les fixes ; `z` absolu 5,
    au-dessus de `Entities`, sous `Overhead`) + **`LightGlowLibrary`** (pure) +
    `data/world/light_glows.json` (`lamp` vacille, `shaft`, `shard`, `projector` fixes ;
    alpha ≤ 0,35 ; `MAX_PER_MAP` = 16). « Réduire les animations » :
    `LightGlow.set_reduce_motion(enabled)` (statique) coupe le vacillement de tous les halos —
    **branchement dans `Boot._apply_settings` à faire après le J11** (`boot.gd` est un fichier du
    J11, §1.2 : T20 ou T21). Aucune `Light2D` dans `game/` (test). Planche de contrôle :
    `tools/capture_light_glow.gd` (quatre halos, tuile `RUBBLE`, héros sous la lampe).
  - **`CaveLibrary`** + **`CaveExit`** (`game/world/caves/`, purs) + `data/world/caves.json`
    (`mt_moon` : 1F, B1F, B2F ; sortie `route_3` / `from_mt_moon_w` / ↓). Chemin par défaut
    `CaveLibrary.DATA_PATH` (convention des autres bibliothèques, au lieu de `DEFAULT_PATH`).
    `test_map_catalog` : grottes extérieures absentes de `interiors.json`, sortie avec son point
    d'apparition — **en attente** (`pending`) tant que T8 / T9 n'ont pas construit les cartes.
  - **`tools/cave_map_kit.gd`** : grille (`PRATICABLES .gjUVE`), `Ground` logique (`.` `j` `E`
    `U` `V` → sol, `g` → `RUBBLE`, reste solide), masque (R gravats, G masse `#`), sol peint aux
    trois textures de la série 14 (échoue proprement tant qu'elles manquent), bande de frontière
    ardoise, `Glows` + budget, échelles (`ladder_links` : paire, carte, spawn cible, orientation
    opposée à l'échelle ; `add_ladder` = `STEP_ON` sans direction), `spawn_names` (`_w/_e`,
    `_n/_c/_s`), objets peints (`add_prop_at`, `add_floor_prop`).
  - Tests : `test_overworld_tileset` (étendu), `test_interior_tileset` (5 couches),
    `test_painted_ground`, `test_light_glow`, `test_cave_library`, `test_cave_map_kit`,
    `test_map_catalog` (étendu). Import propre ; `tools/test.sh` : 3 769 tests, 3 767 verts,
    2 en attente (grottes, T8 / T9), 0 échec.

- **T8 — cartes Route 3, Centre du Mont Sélénite, sas de la Route 4, raccord d'Argenta (2026-10-11,
  branche `j12-t8-route-3`, depuis `jalon-12`)** — sans PNJ, sans rencontres, sans déclencheurs :
  - **`tools/build_route_3.gd`** → `route_3` (82 × 38, grille `route_3.txt` lue telle quelle,
    praticables `.=hvoDQ`) : sol peint avec le canal rouge = `ground_roche_01` (texture à 1:1,
    `paving_scale` 1,0) ; **répétition cassée** par le masque (16 % de cases `o` à 0,47 : l'herbe
    perce, 16 % + bords à 0,62 ; roche qui affleure sur la prairie de l'est, R ≤ 0,42 ; R 0,25 sur
    les chemins qui bordent la roche, sans bande d'herbe) et par 150 décalcomanies (cailloux
    `prop_pierres_01`, touffes sèches, terre grisée). Paroi en modules : **série 12 à l'ouest,
    ardoise (série 14) dès la colonne 44**, teinte de plus en plus froide de x 36 au bord est
    (× (0,84 ; 0,90 ; 1,0)) ; les deux grands affleurements `R` collés à la montagne (≥ 40 cases)
    sont de la paroi, les petits des rochers (grande pierre, rochers ; celui du goulet de Hugo posé
    à la main), assombris et bleutés vers l'est, sol rocheux dessous. Forêt serrée de plus en plus
    sèche vers l'est, fleurs de plus en plus rares (aucune après x 50), rebords L1 / L2, hautes
    herbes, Centre (`bldg_centre_01`, ancre (62, 11)), entrée du Mont Sélénite
    (`relief_entree_grotte_01`, ancre (74, 9)), deux panneaux (décor seul). **Cases réservées**
    (Dresseurs, PNJ, Pokémon, objets, caché) : la forêt s'en écarte comme pour un PNJ.
    Passages : (0, 25..27) PUSH ← Argenta ; Centre (61..62, 11) STEP_ON ↑ ; grotte (73..74, 9)
    STEP_ON ↑ → `mt_moon_1f` / `from_route_3_w|e` ; spawns `from_pewter_n|c|s`,
    `from_center_w|e`, `from_mt_moon_w|e`.
  - **`tools/build_route_4.gd`** → `route_4` (sas 24 × 14) : paroi d'ardoise, bouche de la grotte
    (l'entrée × 0,62, couche du sol), rochers bleutés, lisière buissons / rochers, rebord du versant
    (`relief_falaise_01`), panneau (décor) ; bouche (2, 6) STEP_ON ← → `mt_moon_b2f` /
    `arrivee_s` ↓ ; raccord est (23, 6..7) PUSH → « Azuria » à venir, retour `from_cerulean_n|s`
    tourné ← ; arrivée `from_mt_moon` (3, 6).
  - **`mt_moon_center`** : `_pokemon_center` (définition commune), titre « Mont Sélénite », sortie →
    `route_3` / `from_center_e` (`build_painted_interiors.gd -- --rooms=mt_moon_center`).
  - **Argenta** : sortie est → `route_3` / `from_pewter_n|c|s` tournée → ; scène **éditée sur les
    trois `WarpPoint` seulement** (`unique_id` gardés, diff de 18 lignes) et outil mis à jour ; la
    régénération (`build_pewter_city.gd -- --out=…`) donne la même scène, ids normalisés (diff
    vide). Garde inchangé. **`pewter_map_kit.gd`** : réglages `set_marks` (praticables, paroi,
    roche), `reserved_cells`, crochet du masque, style de paroi par colonne — défauts inchangés :
    Argenta et Route 2 nord reconstruites à l'identique (diff normalisé vide).
  - Données : `zones.json` (route_3, mt_moon = Centre + service `pokemon_center`, route_4 ;
    sous-titres et descriptions de l'annexe A ; les étages s'ajoutent au T9), `interiors.json`,
    `rest_points.json`, `lighting.json`, `decors.json` (`places` : `route_3` → `route_3_roche`).
  - Repli des cartes du T9 : les warps visent `mt_moon_1f` / `mt_moon_b2f` directement ;
    `test_map_links` les tient en « cartes parallèles » (vérifiées dès qu'elles existent) ; le
    préchargement ignore une scène absente. Avant la fusion du T9, entrer dans la grotte ne mène
    nulle part (branche seule).
  - Mesures (Mac) : **2 030 nœuds** (Route 3), 356 (sas) ; 117–120 i/s (vsync) aux trois points de
    la Route 3 et au sas ; lecture + entrée **236 ms** (Jadielle 405, Argenta 323 ; sas 110,
    Centre 62) ; changement Argenta → Route 3 préchargé 14 ms ; mémoire « carte + voisines »
    Route 3 **28,8 Mo** (Argenta + Route 3 ; 1F à ajouter au T9), Argenta 30,5 Mo (+ Route 3),
    Centre 19,0 Mo, sas 6,9 Mo. Chemin principal 93 pas, 8 cases d'herbes obligatoires.
  - Tests : `test_route_3` (19), `test_route_4` (8), `test_mt_moon_center` (4) ; `test_map_links`,
    `test_coming_soon` (sas « AZURIA — À venir »), `test_pewter_city`, `test_pewter_badge` (après
    le badge, la sortie est charge la Route 3 en (0, 26) et le bord ouest ramène en (51, 26)),
    `test_scene_router` (Argenta précharge la Route 3), `test_zone_library` (service du Mont
    Sélénite). Suite : 3 814 tests, 3 812 verts, 2 en attente (T9), seul l'intermittent connu
    `test_rival_route22` vu une fois. Captures `tools/capture_route_3.sh` → `build/captures/jalon12_t8/`
    (`capture_pewter.gd` : option `--hold=`).

---

## Annexe A — Textes VALIDÉS par Kevin le 2026-10-11 (Q-3)

Conventions des lots précédents : bulles de 2 lignes de ~40 caractères, `[e]` = forme au féminin du Pokémon (`text_f`). Ton du Pokédex : carnet de terrain, ce qui s'observe, aucun secret dévoilé.

### A.1 Pokédex (taille, poids officiels ; description ; note des formes de base)

| Espèce | Taille / poids | Description | Note |
|---|---|---|---|
| Rondoudou | 0,5 m / 5,5 kg | « Ses grands yeux ronds fixent quiconque l'approche. Sa berceuse est si douce que ceux qui l'écoutent finissent par s'endormir. » | « Il gonfle son corps comme un ballon avant de chanter. On le trouve là où le vent porte loin sa voix. » |
| Grodoudou | 1,0 m / 12,0 kg | « Son pelage est si fin et si doux qu'on s'y enfonce comme dans un nuage. Il se gonfle d'air quand on le contrarie. » | — |
| Abo | 2,0 m / 6,9 kg | « Il se faufile sans bruit entre les herbes sèches et les pierres chaudes. Il s'enroule autour de sa proie et ne la lâche plus. » | « Au matin, il se chauffe au soleil sur les rochers plats, immobile, avant de disparaître dans une fente. » |
| Arbok | 3,5 m / 65,0 kg | « Le motif de son ventre ressemble à un visage menaçant. Il le déploie pour effrayer ce qui s'approche de trop près. » | — |
| Nosferapti | 0,8 m / 7,5 kg | « Il n'a pas d'yeux et se repère grâce aux ultrasons qu'il émet sans cesse. Il ne quitte les grottes qu'à la nuit tombée. » | « Au plafond des galeries, ils dorment serrés les uns contre les autres. Un bruit suffit à les faire tous s'envoler. » |
| Nosferalto | 1,6 m / 55,0 kg | « Ses crocs creux lui permettent de boire très vite. Après un repas, il vole lourdement et se pose dans un coin sombre. » | — |
| Paras | 0,3 m / 5,4 kg | « Les champignons qui poussent sur son dos tirent leur force de lui. Il vit dans les recoins humides où rien d'autre ne pousse. » | « On le voit gratter le sol des galeries avec ses pinces, à la recherche de racines. » |
| Parasect | 1,0 m / 29,5 kg | « Le champignon a pris le dessus sur son hôte. Il recherche l'ombre et l'humidité, et répand des spores au moindre contact. » | — |
| Mélofée | 0,6 m / 7,5 kg | « On l'aperçoit rarement, et presque toujours par nuit claire. Les gens des montagnes racontent qu'il danse au clair de lune. » | « Là où il est passé, on trouve parfois de fins éclats de pierre brillante. » |
| Mélodelfe | 1,3 m / 40,0 kg | « Il est si discret qu'on ne le voit presque jamais. Ses grandes oreilles entendent une épingle tomber de très loin. » | — |
| Voltorbe | 0,5 m / 10,4 kg | « On le confond facilement avec une Poké Ball. Chargé d'électricité, il peut éclater au moindre choc. » | « Il apparaît près des installations électriques et des lieux où l'on travaille avec des machines. » |
| Smogo | 0,6 m / 1,0 kg | « Son corps mince est rempli de gaz toxiques. Il flotte au ras du sol en dégageant une odeur âcre. » | « Là où il s'attarde, l'air devient lourd et piquant. On le sent avant de le voir. » |

### A.2 Capacités ajoutées (description)

Berceuse « Une douce mélodie qui endort la cible. » · Écras'Face « Frappe la cible avec la paume ou la queue. » · Torgnoles « Gifle la cible de deux à cinq fois d'affilée. » · Regard Médusant « Un regard terrifiant qui paralyse la cible. » · Purédpois « Un gaz toxique qui peut empoisonner la cible. » · Détritus « Projette des boues toxiques qui peuvent empoisonner la cible. » · Brouillard « Un nuage de fumée qui baisse la Précision de la cible. » · Lilliput « Le lanceur rapetisse pour augmenter son Esquive. » · Spore « Un nuage de spores qui endort la cible à coup sûr. » · Onde Folie « Un rayon sinistre qui rend la cible confuse. » · Acide « Asperge la cible d'acide. Peut baisser sa Défense Spéciale. » · Ultimapoing « Un coup de poing d'une force incroyable. » · Sonicboom « Une onde de choc qui inflige toujours les mêmes dégâts. » · Métronome « Agite un doigt pour utiliser une capacité au hasard. Sans effet dans le moteur actuel. » · Buée Noire « Annule les changements de statistiques de tous les Pokémon. Sans effet dans le moteur actuel. » · Mur Lumière « Un mur de lumière qui réduit les dégâts spéciaux reçus. Sans effet dans le moteur actuel. » · Damoclès « Une charge téméraire qui blesse aussi le lanceur. Sans effet dans le moteur actuel. » (Vampirisme, Ligotage, Entrave, Repos, Destruction : §20 n° 41–45.)

### A.3 Zones (Carte, Pokédex)

- Route 3 — sous-titre « Argenta — Mont Sélénite » ; description « Une longue route qui monte d'Argenta vers la montagne, entre prairies, bosquets et rochers. Au loin, le Mont Sélénite grandit à chaque pas. »
- Mont Sélénite — sous-titre « Route 3 — Route 4 » ; description « Une montagne creusée de galeries sombres et silencieuses. On dit que des pierres y sont tombées du ciel, autrefois. »
- Route 4 — sous-titre « Mont Sélénite — Azuria » ; description « Le versant est du Mont Sélénite. La route descend vers la plaine, en direction d'Azuria. »

### A.4 Combat et interface

- Étreinte : « {pokemon} est pris[e] dans l'Étreinte ! » · « {pokemon} souffre de l'Étreinte ! »
- Danse Flamme : « {pokemon} est pris[e] dans un tourbillon de flammes ! » · « {pokemon} souffre de la Danse Flamme ! »
- (libération : « {pokemon} est libéré[e] ! », §20 n° 46 ; fuite refusée : « Impossible de fuir ! », existant)
- Changement refusé (raison sur les cartes de l'équipe) : « Impossible de changer »
- Carte d'une capacité bloquée : « BLOQUÉE »

### A.5 Grand moment (présentation du texte validé n° 30 dans la frise)

Titre « La Team Rocket repoussée » · détail « {fossil} obtenu. » · lieu « Mont Sélénite » (nom de la zone, comme pour le badge) — la ligne se lit « Mont Sélénite : la Team Rocket repoussée, Fossile Dôme obtenu. ».
