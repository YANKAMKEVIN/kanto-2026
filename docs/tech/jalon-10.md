# Jalon 10 — Argenta et l'Arène de Pierre

> Objectif jouable sur le S24 : **fermer la première grande boucle**. Depuis la porte nord du poste nord de la Forêt de Jade (J9), la **Route 2 nord** (sas court, deux petites zones d'herbes, un Montagnard, une Potion, un sentier fermé par des éboulis), puis **Argenta** : titre « ARGENTA » seul, le Musée visible dès le premier écran, la place au gros rocher, six habitants, le tailleur et son Racaillou, le Centre (point de repos) et la Boutique (Ball, Potion, Antidote), le **Musée** (deux salles, vitrines, journal anonyme, laboratoire fermé), deux maisons, le **garde de la Route 3**, et l'**Arène** : le guide, le Campeur Liam (évitable), **Pierre** (carte de présentation, Racaillou 12 et Onix 14 aux capacités choisies à la main, IA `smart`), la défaite sans réintroduction, puis l'inscription **« BADGE ROCHE »**, le **Grand moment « badge »** avec le souvenir de l'équipe, l'écran Dresseur à jour, l'objectif « continuer vers la Route 3. » et le garde qui se décale.
>
> Aucune nouvelle mécanique de combat ; deux ajouts signalés par le dossier : capacités choisies à la main pour un Pokémon de Dresseur, carte de présentation du Champion. **Format de sauvegarde inchangé** (celui du J9, v4).

**Pré-requis.** Dossier 12 **verrouillé** (2026-10-07 : 20 arbitrages, textes validés, vue générale validée) : c'est la **source de vérité**. Le dossier dit « pas d'implémentation avant la fusion du J9 et ce plan » ; **à la demande de Kevin** (avancer le J10 tout de suite sur ce qui est possible), ce plan classe chaque tâche en **« maintenant »** (sur `main`, sans dépendance au J9 ni conflit probable avec lui) ou **« après la fusion du J9 »** (§1.2). Le J9 vit sur `jalon-09` et ses branches `j9-*` : **ce plan ne les modifie pas**, il les lit seulement.

Plan écrit sur `docs/plan-j10` depuis `main` à `bd6ee75` ; le J9 est lu sur `jalon-09` (`0ca017a`, 9A.1 validée), `j9-systemes` (`e0fb3a9`, tranche A intégrée, 9A.2 validée) et `j9-t14-vue-generale` (`80f1fd1`, grille, vue et liste des assets de la forêt), ainsi que `docs/tech/jalon-09.md` de cette dernière branche. **Chaque tâche d'architecture commence par aligner ce plan sur le code du moment**, et la première tâche « après le J9 » (T8) le réaligne sur le J9 réellement fusionné.

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/dossier-12-argenta.md` (arbitrages 1–20, §1–§20, « Textes verrouillés »), `dossier-05-combat.md`, `dossier-06-progression.md` §3 (Pierre : comprendre les types), `dossier-08-menu-dresseur.md` §6 (badges, Grands moments), `dossier-09-jadielle.md` §7–§10 (Centre, Boutique, défaite sans perte d'argent), `dossier-11-route-2.md` et `jalon-08.md` (méthode d'art, objets visibles et cachés), `jalon-09.md` (Dresseurs, poison, évolution, postes, série 11), `combat-maquettes.md` (branche `combat-maquettes` : CB.1–CB.3), `roadmap.md` phase 6.

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin du dossier (`main` à `bd6ee75`, et ce que le J9 apporte)

| Besoin (dossier 12) | Existant sur `main` | Apporté par le J9 (pas encore fusionné) | Manque |
|---|---|---|---|
| Grilles, plan, vue | `tools/plans/argenta.txt` (52 × 44), `route_2_nord.txt` (30 × 24), raccord (17..19, 43) ↔ (14..16, 0) ; `plan_aplats.py --empiler` ; `reference/argenta-plan-v1.png` (géométrie) et `argenta-vue-generale-v1.png` (DA) | `PlanGrid` / `plan_grille.py` : ligne `PRATICABLES`, attributs `cle=valeur` (T14) | grilles des intérieurs (Arène), contrôle des critères (`plan_check`), corrections de positions (§1.3) |
| Cartes peintes | modèle `tools/build_route_2.gd` (forêt serrée `DenseForest` + `Shade`, `ForestFloor`, `PaintedGround`, props `WorldProp`, `PaintedPropRules`) ; `tests/helpers/plan_grid.gd` | tri de visibilité de `DenseForest`, cache borné du `SceneRouter` (T18) | `tools/build_route_2_north.gd`, `tools/build_pewter_city.gd`, scènes, masques |
| Raccord sud | — | poste nord `viridian_forest_gate_north` (une définition `_forest_gate(side)` dans `build_painted_interiors.gd`, T19), porte nord **« ROUTE 2 NORD — À venir »** (`coming_soon`) ; garde nord : variante `if: [pewter_arrived]` (drapeau **que le J10 pose**) | porte nord du poste → `route_2_north` (une ligne de l'outil + scène régénérée) |
| Intérieurs | `build_painted_interiors.gd` (une fonction par pièce : enveloppe + meubles + cases bloquées), Centre et Boutique de Jadielle (`_viridian_center`, `_viridian_mart`) | `_forest_gate(side)` (deux scènes d'une définition) | Centre et Boutique d'Argenta (mêmes définitions, autre identifiant), Musée × 2, Arène, 2 maisons |
| Centre, point de repos | `ServiceDirector` (`center_heal`), `data/world/rest_points.json` (toast « Point de repos enregistré — <titre> »), `DefeatRecovery` | — | entrée `pewter_center` |
| Boutique | `ShopLibrary` : boutique **de la carte courante** (`data/shops/<carte>.json`), stock conditionnel `if` / `unless` | objet `antidote` (100 ₽), stock `if poison_unlocked` à Jadielle | `data/shops/pewter_mart.json` (Ball, Potion, Antidote) |
| Dresseurs | `TrainerData` / `TrainerLibrary` (`data/trainers/*.json`, IA `random` / `smart`, `prize_money`, `start_message`, `end_message`), `TrainerSlot` = **espèce + niveau seulement** | vision, « ! », approche, défi à la parole, `beaten_<id>`, `TrainerEncounter` (séquence : avant → combat → « après » → réveil), bloc `trainer` des PNJ (`NpcRoster`), `TrainerWatcher` | **capacités choisies à la main** (§2.4) ; réplique « vaincu » distincte de la réplique « après » (Liam, §2.5) |
| Champion (scène écrite) | modèle du rival n° 2 (`data/cutscenes/route_22.json` : réplique, `battle` `win` / `lose`, réplique de défaite, `wake_up`) ; dialogue sans page qui lance une scène (`{ "cutscene": … }`) | — | scène de Pierre (intro, reprise, défaite, victoire, badge) §2.6 |
| Carte du Champion | `ExplorationHud` (titre de zone, légende `WorldCaption`), tokens UI | — | composant `ChampionCard` + étape de scène (§2.7) |
| « BADGE ROCHE » | étape `caption` (« POKÉDEX ACTIVÉ », `WorldCaption` : fondu, tenue `CAPTION_HOLD` 3 s, fondu), `Haptics.vibrate(ms)` | — | étape `badge` (légende + vibration + Grand moment), §2.8 |
| Badges | `data/badges.json` (8 badges, `badge_boulder`), `BadgeLibrary` (obtenu = drapeau levé), écran Dresseur : 8 emplacements, « Roche » en ACCENT si obtenu, **pas de détail au toucher** (`BadgeSlot` : « le détail au toucher viendra avec le J10 ») ; tableau de bord : ligne badges (`DashboardViews.badges_text`) | — | détail au toucher (§2.9) |
| Grands moments | `GameState.record_moment(type, map, details)` ; `MomentLibrary` (types `starter`, `rival_battle`, `first_capture`, `zone_arrival`, marques `{zone}` `{species}` `{outcome}`), `TrainerSummary.moment_views`, `data/trainer/moments.json` (`zone_arrivals` : Route 1, Jadielle) | aucun moment au J9 | type `badge` (§2.8) ; arrivée à Argenta (texte) |
| Objectifs | `ObjectiveLibrary` (`data/story/objectives.json`, première entrée valide l'emporte) : `go_north` « continuer vers le nord. » si `pokedex_activated` | `go_north` gardé jusqu'à Argenta (pas de `unless`) | deux entrées (§2.10) |
| Garde de la Route 3 | `EventTriggerPoint` → scène ; étape `move` du joueur avec `keep_facing` (recul) ; PNJ à présence `if` / `unless` ; `WarpPoint.coming_soon` | apparence peinte `guard` (série 11, T17) | données + scène (§2.11) |
| Objets | objets visibles (J8 : PNJ `take`, `object/poke_ball_ground`, `despawn` + `give found` + `set`) | — | Potion de la Route 2 nord (données) |
| Pokémon d'ambiance | `look`, `idle_react`, `route` | format « Pokémon fixe » (planche de 4 poses, `preparer.py` `pokemon_fixes`, genre de `build_character_frames.gd`, T17) | Racaillou du tailleur (§2.12) |
| Espèces, capacités | 24 espèces (`data/pokemon/species/kanto.json`), Grincement, Charge, Griffe, Jet de Sable ; artworks officiels 001–151 (adversaire en combat, Pokédex) | Chenipan → Raichu, **Armure** (`harden`), Choc Mental, statut poison, évolution (Papilusion Nv. 10 : la réponse de Salamèche) | Racaillou (+ Gravalanch, Grolem), Onix, Sabelette (+ Sablaireau), Jet-Pierres, Boul'Armure (§2.3) |
| Départs de QA | `tools/debug_start/*.json` + README | départs du J9, `status`, `autosave` | départs du J10 (§2.14) |
| Lumière | `golden_hour`, `interior_warm` (`data/world/lighting.json`) | profil `forest` | `pewter_city`, `route_2_north` au plan des profils |

### 0.2 Écarts et trous constatés

1. **`TrainerSlot` n'a que `species` et `level`** (`game/battle/trainer_slot.gd`) ; `TrainerLibrary._read_team` refuse toute autre clé ; `build_team` passe par `PokemonFactory.create` (capacités de Rouge/Bleu au niveau). Le modèle d'un remplacement existe déjà dans `DebugStart._create` (`moves.clear()` puis `learn_move`) : on le reprend (§2.4).
2. **La séquence des Dresseurs du J9 n'a que deux répliques** (« avant », « après » dite tout de suite puis permanente, Q-3 du J9) ; **Liam en a trois** (avant, « D'accord… Tu es prêt. » à la victoire, « Pierre est encore plus solide. » ensuite). Petit ajout au bloc `trainer` (§2.5), après le J9.
3. **Le dossier §9 dit à la fois** « après le badge, il dit sa réplique **une fois** et se décale » et (§18) « garde décalé : **dérivé du badge** » sans drapeau : « une fois » demande une mémoire → **Q-2**.
4. **Durée de la Route 2 nord** : le dossier §3 indique « traversée directe ≈ 25–35 s », mais la grille validée met la porte du poste à **21 pas** de l'avenue d'Argenta sur un chemin droit (≈ 5 s à la marche, hors rencontre) → **Q-4**.
5. **Zone de la Route 2 nord** : défaut du dossier §20 = « zone à part, titre Route 2, sous-titre Forêt de Jade — Argenta » ; conséquences : deux « Route 2 » dans les habitats du Pokédex et sur la Carte, une description de zone à écrire, une aire à tracer sur la carte de Kanto → **Q-3**.
6. **Positions de la grille d'Argenta à corriger** (« ajustables au plan du J10 ») : le panneau « ARGENTA » (16, 40) est **sur la rue** et sur la routine de la visiteuse (12..16, 40) ; les emprises de la grille ne suivent pas les règles d'emprise des bâtiments réutilisés (Centre `C` 9 cases de large contre `width` 8 de `bldg_centre_01` : une colonne de mur invisible). T1 corrige la **grille d'abord** (§1.3).
7. **Porte du poste vue du nord** : la grille met la porte de la Route 2 nord **en haut** de l'emprise du poste (15, 21) (on y entre en descendant), la vue générale peint une façade de face (porte en bas). La grille fait foi ; aucune image existante ne montre le poste depuis le nord → un asset (§1.4, `bldg_poste_foret_nord_01`).
8. **Pierre « ne rejoue pas son introduction »** : il faut une mémoire de la première rencontre ; le dossier §18 n'en liste pas → drapeau `brock_met` (défaut, règle 4 ; format inchangé).
9. **Conflit déjà présent, hors J10** : `main` (`a1639f0`) et `j9-t14-vue-generale` modifient tous deux `tools/art/plan_aplats.py` et `plan_grille.py` ; la fusion du J9 le résoudra (« garder les deux côtés »). Le J10 n'ajoute rien à ces deux fichiers.
10. **`record_moment` documente des détails « chaînes, nombres, booléens »** : le souvenir de l'équipe est un tableau d'objets. Vérifié (§2.8) : aucun changement de format, mais lecture tolérante (nombres relus en flottants).

### 0.3 Alignement après la fusion du J9 (T8, 2026-10-08)

`jalon-10` contient `main` avec le J9 terminé (fusion `470176d`). Écarts constatés entre ce plan et le code réel, corrigés ici (le reste du plan tient) :

1. **Noms des capacités** (note A1 du lot validé) : *Self-Destruct* = **Destruction** (`self_destruct`), *Bind* = **Étreinte** (`bind`) ; « Ligotage » (*Wrap*) et « Patience » (*Bide*) ne sont dans aucun apprentissage de Rouge/Bleu des six espèces : **non ajoutées**. Capacités ajoutées : `rock_throw`, `defense_curl`, `self_destruct`, `earthquake`, `explosion`, `bind`, `slam` (§2.3).
2. **Identifiants des personnages réutilisés** (`tools/build_character_frames.gd`) : la visiteuse « `vieille` » est **`aoki`** (planche `vieille_dame`), le vieil habitant « `old` » est **`old_man`**, la chercheuse « `chercheuse` » est **`maya`** (planche `chercheuse`). La compagne du tailleur et la chercheuse sont donc toutes deux `maya`, sur des cartes différentes (règle « un modèle par carte » tenue). Nouveaux (T10, fiche de la série 12) : `brock`, `stonemason`, `mountaineer`, `camper`, `gym_guide`, `pokemon/geodude` ; un PNJ dont l'apparence manque garde l'apparence générique jusqu'au T10.
3. **Pokémon fixe** (J9) : feuille **6 × 1** (repos et réaction de face, de dos, de profil gauche ; droite en miroir), pas « 4 poses ».
4. **Poste nord** (`_forest_gate(&"north")`) : porte nord de **deux cases** (4..5, 1), warps `Route2NorthSoonW/E` (STEP_ON ↑, `coming_soon` « Route 2 nord »), spawn de retour existant **`north_door`** (4, 2). T11 : les deux warps visent `route_2_north` / `from_forest_gate` ; la porte (15, 21) de la Route 2 nord revient sur **`north_door`** (défaut : pas de nouveau spawn `from_route_2_north`).
5. **Séquence des Dresseurs** (`TrainerEncounter.build`) : réplique « avant » → combat → réplique `dialogue` si `beaten_<id>` (dite tout de suite, puis permanente) → réveil sinon. La clé `defeated` (§2.5, T9) remplace l'étape « après » de la séquence quand elle existe.
6. **Ce que les tests exigent d'une carte existante** : `test_rest_point_data` (carte + spawn du point de repos) et `test_map_light_profiles` (toute carte au plan des profils existe) → l'entrée `pewter_center` de `rest_points.json` passe au **T13** et les lignes de `lighting.json` au **T11** / **T13** (comme la Route 2 au J8 T5), pas au T8. `zones.json` est rempli au T8 avec une garde `AWAITING_MAPS` dans `test_zone_library` (retirée carte par carte).
7. **Pas encore lisibles par le moteur** (T9, **fait** : tout est lu et branché) : le bloc `card` de `TrainerLibrary` (absent de `data/trainers/pewter_gym.json` jusqu'au T9), la clé `defeated` du bloc `trainer` (absente de `data/npcs/pewter_gym.json`), les étapes `champion_card` et `badge` (absentes de `data/cutscenes/pewter_gym.json` : T9 insère la carte après `set: [brock_met]` et le badge après `pewter_gym_brock_won`).
8. **Équipe réelle de Kevin en fin de J9** (sauvegarde de la QA finale T22 sur S21, `save_fin_qa.json`, non versionnée) : Salamèche N10 (Griffe, Rugissement, Flammèche), Roucool N9, Chenipan N6, Chenipan N5, Rattata N3, Nidoran♂ N3 ; 1 396 ₽ ; **ni Papilusion ni Choc Mental**. Entrée du T16 (équilibrage), qui doit simuler cette équipe telle quelle en plus des équipes « naturelles ».
9. **Arène** : la grille corrigée au T1 (`tools/plans/argenta_arene.txt`) fait foi sur le §1.3 : chemin direct **6 pas**, détour **12 pas** (le tracé du §1.3 disait 7 et 13).
10. **Branche `j9-foret-xl`** (agrandissement de la Forêt de Jade, en préparation) : le T8 ne touche aucun fichier de la forêt ni des postes ; conflits possibles seulement sur les listes des tests partagés (`test_dialogue_data`, `test_cutscene_data`, `test_encounter_library`, `test_pokemon_data`) — garder les deux côtés. **Risque pour le T11** : il régénère `viridian_forest_gate_north.tscn` (porte nord) ; si la forêt XL déplace `from_gate_north` ou régénère les postes, faire le T11 après elle ou régénérer le poste après la fusion.

**Hors périmètre** (dossier 12 §2) : Route 3 jouable, CT (J11), nouveaux statuts, capacités d'exploration, échanges, Corde Sortie, Team Rocket, rival, musique (intentions seulement, `GameMap.music` vide), image peinte du Badge Roche (défaut : emblème existant en ACCENT, §5).

---

## 1. Découpage

### 1.1 Sous-jalons et validations

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **10.0** Kit visuel | liste exacte des assets d'Argenta (série 12), génération Codex en lumière NE | **Kevin, sur la planche de contact** (pas de S24) |
| **10A** La route et la ville | Route 2 nord et Argenta (cartes peintes, raccords, porte nord du poste, rencontres), façades, performances | **S24** |
| **10B** Les bâtiments et la vie | Centre (point de repos), Boutique (stock), Musée (2 salles), 2 maisons, Arène (salle vide), habitants, Racaillou, Montagnard, Potion, éboulis, garde **avant** le badge, arrivée (`pewter_arrived`), objectif « obtenir le Badge Roche. » | **S24** |
| **10C** L'Arène | guide, Campeur Liam (vision, évitable, battu mémorisé), Pierre (carte de présentation, capacités choisies, IA `smart`, défaite → réveil, reprise sans introduction), équilibrage (départ Salamèche) | **S24** |
| **10D** Le premier badge et la QA finale | « BADGE ROCHE » + vibration, Grand moment « badge », écran Dresseur (détail), objectif « continuer vers la Route 3. », garde qui se décale, « ROUTE 3 — À venir » ; vraie partie de Kevin du poste nord au badge, sauvegarde et reprise | **S24** + fusion |

- **Jamais trois systèmes à la fois** : 10A = le décor (comme 8.1) ; 10B = du contenu sur des systèmes existants ; 10C = deux briques nouvelles (carte du Champion, capacités choisies) sur le système de Dresseurs du J9 ; 10D = une brique (étape `badge` + moment) et l'interface du badge.
- **Aucune validation de sauvegarde isolée** : le format ne change pas (§2.8, §2.15).

### 1.2 « Maintenant » ou « après la fusion du J9 »

**Fichiers que le J9 modifie** (`git diff --name-only main...jalon-09`, `main...j9-systemes`, `main...j9-t14-vue-generale`, 220 fichiers) **ou va modifier** (tâches T17–T23 de `jalon-09.md`) — à ne pas toucher avant sa fusion :
`game/autoload/game_state.gd`, `game/boot.gd`, `game/battle/*` (directeur, IA, texte, événements…), `game/pokemon/*` (pokemon, evolution, pokedex, status), `game/items/*`, `game/systems/cutscene/*` (étape `emote` en fin d'enum), `game/systems/debug/debug_start.gd`, `game/systems/save/save_system.gd`, `game/systems/menu/dashboard_views.gd` et vues d'équipe, `game/world/npc/*` (roster, spec, npc, trainer_*), `game/world/interactions/interaction_controller.gd`, `game/world/map_catalog.gd`, `game/ui/battle/*`, `game/ui/theme/ui_tokens.gd` (ajouts au milieu du fichier), `data/pokemon/**`, `data/pokedex/kanto.json`, `data/items/items.json`, `data/battle/messages.json`, `data/shops/viridian_mart.json`, `data/trainers/` (nouveau fichier), `tools/debug_start/README.md`, `tools/gen_placeholder_battlers.gd`, `tools/art/plan_*.py`, `tests/helpers/plan_grid.gd`, `tests/integration/test_dialogue_data.gd`, `test_boot.gd`, `tests/unit/test_trainer_library.gd`, `test_npc_roster.gd`, `test_zone_library.gd`, `test_encounter_library.gd`, `test_debug_start.gd`, `test_map_light_profiles.gd` ; **à venir (tranche B)** : `tools/build_route_2.gd` + `route_2.tscn`, `tools/build_painted_interiors.gd`, `game/autoload/scene_router.gd`, `game/world/forest/dense_forest.gd`, `data/world/lighting.json`, `data/world/zones.json`, `tools/art/manifeste.json`, `preparer.py`, `assets/world/catalogue.json`, `tools/build_character_frames.gd`, `game/world/props/painted_prop_rules.gd`, `docs/design/fiches-assets/serie-01-place-jadielle.md`, `test_map_links.gd`, `test_coming_soon.gd`.

**Règles pour les tâches « maintenant »** : branche d'intégration **`jalon-10` depuis `main`** (une branche par tâche, fusionnée dans `jalon-10`, jamais dans `main` avant la fin du J10) ; **fichiers nouveaux** de préférence ; sinon seulement des fichiers que le J9 ne touche ni ne touchera ; un ajout à `ui_tokens.gd` va **à la toute fin du fichier** (le J9 insère au milieu, `combat-maquettes` dans la section combat : aucun recouvrement) ; aucun test existant que le J9 modifie n'est édité (on crée un fichier de test). Quand le J9 est dans `main` : fusion de `main` dans `jalon-10` (T8), conflits attendus seulement sur `docs/tech/etat-projet.md`.

| Tâche | Agent | Quand | Base | Pourquoi / comment éviter les conflits |
|---|---|---|---|---|
| T0 Plan (ce document) | architecte | **fait** | `main` | docs |
| T1 Kit d'assets (liste exacte, série 12), grilles des intérieurs, corrections de grille, contrôle des critères | architecte | **maintenant** | `jalon-10` | fichiers nouveaux (`serie12.py`, `serie-12-argenta.md`, `plan_check_argenta.py`, `argenta_arene.txt`, prompts) ; `tools/plans/argenta.txt` / `route_2_nord.txt` n'existent que sur `main` |
| T2 Génération Codex de la série 12 → **10.0** | constructeur-monde (Mac) | **maintenant** (après T1) | `jalon-10` | images dans `build/art/` (non versionné) + journal dans la fiche nouvelle ; **pas** de manifeste ni de `preparer.py` (T10) |
| T3 Capacités choisies à la main (`TrainerSlot.moves`) | architecte | **maintenant** | `jalon-10` | `trainer_slot.gd`, `trainer_library.gd` (non touchés par le J9) ; tests dans un **fichier nouveau** (`test_trainer_library.gd` est modifié par le J9) |
| T4 Grand moment « badge » (pur), textes des moments, objectifs | architecte | **maintenant** | `jalon-10` | `moment_library.gd`, `trainer_summary.gd`, `moments.json`, `objectives.json`, fichier nouveau `badge_moment.gd` ; tests `test_moment_library`, `test_trainer_summary`, `test_objective_library` (non touchés par le J9) ; **pas** `game_state.gd` |
| T5 Carte de présentation du Champion (composant) | ui-mobile | **maintenant** | `jalon-10` | fichiers nouveaux + `exploration_hud.gd` (non touché par le J9 ni `combat-maquettes`) + tokens en fin de `ui_tokens.gd` |
| T6 Écran Dresseur : badge obtenu, détail au toucher, moment « badge » dans la frise | ui-mobile | **maintenant** (après T4, T5) | `jalon-10` | `badge_slot.gd`, `trainer_screen.gd`, vues du menu Dresseur (non touchés) ; tokens en fin de `ui_tokens.gd` (après T5 : même agent, l'un après l'autre) |
| T7 Lot de textes système du J10 → Kevin | architecte | **maintenant** | `jalon-10` | docs (`textes-brouillon-j10.md`) |
| T8 Alignement + données (espèces, capacités, Pokédex, Dresseurs, Boutique, rencontres, zones, dialogues, scènes, PNJ, départs) | architecte | **fait** (2026-10-08) | `jalon-10` (J9 fusionné) | `data/pokemon/**`, `pokedex`, `test_dialogue_data`… (§0.3) |
| T9 Moteur : étapes `badge` et `champion_card`, réplique « vaincu » des Dresseurs | architecte | **après le J9** | `jalon-10` | `cutscene_*` (enum du J9), `npc_roster`, `trainer_encounter`, `boot.gd` |
| T10 Intégration de la série 12 (manifeste, `preparer.py`, règles, scènes, planches) | constructeur-monde (Mac) | **après le J9** (T17 du J9) | `jalon-10` | `manifeste.json`, `catalogue.json`, `painted_prop_rules.gd`, format « Pokémon fixe » et `guard` du J9 |
| T11 Cartes Route 2 nord + Argenta, porte nord du poste | constructeur-monde | **après le J9** | `jalon-10` | poste nord, `PlanGrid` (`PRATICABLES`), `lighting.json`, `zones.json`, `test_map_links` |
| T12 QA 10A | qa-mobile | après T11 | — | S24 |
| T13 Intérieurs (Centre, Boutique, Musée × 2, maisons, Arène) | constructeur-monde | **après le J9** | `jalon-10` | `build_painted_interiors.gd` (T19 du J9) |
| T14 La vie d'Argenta et de la route | constructeur-monde (+ ui-mobile en relecture) | après T13 | `jalon-10` | — |
| T15 QA 10B | qa-mobile | après T14 | — | S24 |
| T16 Équilibrage de Pierre (simulation, vraie partie de Kevin) | architecte | **après le J9** (données T8) | `jalon-10` | outil nouveau `tools/simulate_brock.gd` |
| T17 L'Arène sur la carte (Liam, Pierre, guide) | constructeur-monde | après T9, T13, T16 | `jalon-10` | — |
| T18 QA 10C | qa-mobile | après T17 | — | S24 |
| T19 Le badge en jeu (garde qui se décale, objectifs, Route 3 « À venir ») + QA finale 10D | constructeur-monde puis qa-mobile | après T18 | `jalon-10` | S24 + fusion |
| T20 Clôture | architecte | à la fin | — | — |

**Parallélisme maintenant** : T1 ∥ T3 ∥ T4 ∥ T5 ∥ T7 (fichiers disjoints) ; T2 après T1 ; T6 après T4 et T5. Après le J9 : T8 ∥ T10 ; T9 après T8 ; T11 après T10 ; T13 ∥ T11 ; T16 ∥ T13. **Une session S24 par sous-jalon** (T12, T15, T18, T19).

### 1.3 Grilles : corrections et ajouts (T1, défauts de la règle 4)

`tools/plans/argenta.txt` et `route_2_nord.txt` font foi (règle 10) ; leurs `POSITIONS` sont des défauts « ajustables au plan du J10 ». T1 corrige **la grille d'abord**, régénère le plan (`plan_aplats.py --empiler …`) ; **pas de nouvel essai de vue générale** pour une correction d'une case (la vue donne la DA, pas les cases).

- **Panneau « ARGENTA »** : de (16, 40) (sur la rue) à **(16, 42)**, sur l'herbe à l'ouest de l'avenue, lu depuis (16, 43) tourné ↑. La routine de la visiteuse (12..16, 40) reste.
- **Emprises des bâtiments réutilisés** : `C` ramené à la largeur de `bldg_centre_01` (`width` 8) ; `O` déjà à 8 (`bldg_boutique_01`) ; la porte reste au même x relatif que l'image (porte de Jadielle). Pour les bâtiments neufs (Musée, Arène, maisons, poste vu du nord), **la grille donne l'emprise** et la fiche de l'asset la reprend (T1).
- **Critères vérifiés** par `tools/art/plan_check_argenta.py` (nouveau, lit les grilles avec `plan_grille.lire` de `main`, praticables `.=hvDp`) puis par les tests des cartes (T11, T17) sur la vraie scène :

| Grille | Critère |
|---|---|
| Route 2 nord | porte du poste → raccord nord atteignable ; H1 et H2 évitables ; Potion (4, 1) atteignable hors herbes (« petit détour ») ; éboulis (24, 16..17) bloquent tout passage vers l'est ; Montagnard hors du chemin et hors herbes |
| Argenta | toutes les portes atteignables depuis l'entrée sud ; le Musée tombe dans le cadre de la caméra au point d'arrivée (≈ 24,4 × 11,25 cases, caméra bornée à la carte) ; les trois cases du passage est (x 48, y 25..27) sont le seul accès à la sortie est (51, 25..27) ; aucune routine sur une porte ni sur un panneau |
| Arène (nouvelle, ci-dessous) | salle ≤ 24 × 11 cases (caméra immobile : **Pierre visible depuis l'entrée**, `CameraFraming.is_static`) ; Pierre atteignable ; la ligne de Liam couvre toute la largeur du passage central ; il existe un chemin entrée → Pierre **hors de sa vision** (détour) ; son approche ne ferme aucun passage |

- **Arène** `tools/plans/argenta_arene.txt` (défaut, 15 × 11, une case = 96 px → 1 440 × 1 056, la salle entière à l'écran) : `K` paroi, `.` sol de sable, `R` piliers et rochers bas, `P` Pierre, `L` Liam, `G` guide, `X` sortie :

```text
          x : 0         1
              012345678901234
         0    KKKKKKKKKKKKKKK
         1    KKKKKKKKKKKKKKK
         2    KK....RPR....KK      Pierre (7, 2) ↓, estrade entre deux rochers
         3    KK...........KK      on lui parle depuis (7, 3)
         4    KKRR.......RRKK      piliers
         5    KK...........KK
         6    KKL.....RR...KK      Liam (2, 6) → vision 5 : (3..7, 6), arrêtée par (8, 6)
         7    KK......RR...KK      détour à l'est : x 10..12 (13 pas contre 7)
         8    KKRR.......RRKK      piliers
         9    KK...G.......KK      guide (5, 9) ↑, à côté de l'entrée
        10    KKKKKKXXXKKKKKK      sortie (6..8, 10), PUSH ↓ ; spawn `entrance` (7, 9)
```
  Chemin direct entrée → Pierre : 7 pas par x = 7 (vu par Liam en (7, 6), à 5 cases) ; détour hors de sa vision par x = 10 : 13 pas. Approche de Liam : il s'arrête en (6, 6), le passage x = 7 reste ouvert. T1 écrit ce tracé dans le fichier et le vérifie.

### 1.4 Kit d'assets : liste précise (méthode du J8 §1.2 et du J9 §2.8)

**Consigne de Kevin (J8, J9)** : le plus petit kit modulaire qui produit la **sensation** de la vue validée dans Godot, sans répétition visible. Vue : `reference/argenta-vue-generale-v1.png` ; **la grille fait foi**. Série **12** (la 11 est celle de la forêt, J9), **lumière neutre (NE)**, ancres de style : la façade du poste (`WORLD_BLDG_POSTE_FORET_01`) et une maison de Jadielle pour les bâtiments, la planche d'un PNJ peint pour les personnages, la coque du Centre pour les intérieurs. Liste finale, fiches et prompts : **T1** (`docs/design/fiches-assets/serie-12-argenta.md`, **fichier nouveau** pour ne pas toucher la fiche des séries que le J9 modifie ; `tools/art/serie12.py`).

**A. Réutilisés tels quels** (aucun travail d'art)

| Rôle (vue, grille) | Asset(s) |
|---|---|
| Sol : herbe, chemin, place pavée | `ground_herbe_01`, `ground_chemin_01` (masque G), `ground_paves_01` (masque R : la place `p`) ; décalcomanies `decal_touffe_*`, `decal_terre_*`, `decal_pave_*` |
| Forêt serrée (`T`) : bande entre la ville et la route, bords des deux cartes | `tree_foret_01..08` par `DenseForest` (+ `Shade` : forêt un peu moins saturée, défaut valeur × 0,95, rouge × 1,02) + `ForestFloor` |
| Arbres de la ville (`G`) | `tree_a_01`, `tree_c_01`, `tree_e_01`, `tree_b_01` (jamais le même côte à côte) |
| Hautes herbes H1, H2 | `ground_hautes_herbes_jaune_01` (+ `_bas`), comme la Route 2 sud (« même famille ») |
| Centre, Boutique (façades) | `bldg_centre_01`, `bldg_boutique_01` (« même enseigne », dossier §8) ; variations : pots de fleurs et caisses autour (`prop_pots_fleurs_01`, `prop_caisses_01`) |
| Intérieurs du Centre et de la Boutique | coques et meubles de Jadielle (`int_centre_*`, `int_boutique_*`, `int_plante`) |
| Bancs (`n`), panneaux, buissons (`x`) | `prop_banc_01`, `prop_panneau_01`, `prop_buisson_a/b/c_01_bourg` |
| Gros rocher de la Route 2 nord (`R`, 2 × 2) | `prop_grande_pierre_01` à l'échelle 0,75, en miroir (écho de la Route 2 sud : c'est la même route) |
| Éboulis du sentier est (`E`) | `prop_rocher_01` × 2 + `prop_pierres_01`, assombris (variation) ; asset conditionnel ci-dessous |
| Lisière, recoins | `prop_ronces_01`, `prop_tronc_couche_01`, `prop_pierres_01` (traversable) |
| Mobilier des maisons, salle « science » | meubles de Bourg Palette et du labo (`int_table_repas_01`, `int_grande_etagere_01`, `int_petite_etagere_01`, `int_paillasse_01`, `int_etagere_labo_01`, `int_classeur_01`, `int_bureau_pc_01`, `int_plante`…) |
| Personnages réutilisés | voir C (habitants) |
| Pokémon en combat | artworks officiels (Racaillou 074, Onix 095, Sabelette 027) : adversaire = artwork officiel (CB.1) ; aucun dos (ni capturable ni donné au J10) |

**B. Variations sans nouvel asset** : teinte plus sèche des arbres de forêt (`Shade`), fleurs plus rares et seulement `decal_fleur_1`, `_3`, `_5` (« touches discrètes ») ; buissons en miroir et teinte ± 8 % ; éboulis par rochers existants assombris ; deux maisons sur la même image (jamais à l'écran ensemble : 40 colonnes d'écart).

**C. Nouveaux (série 12, Codex, lumière NE)** — **23 images**

| Fiche → asset | Rôle que rien d'existant ne tient | Emprise (grille) | Images |
|---|---|---|---|
| `WORLD_BLDG_MUSEE_ARGENTA_01` → `bldg_musee_argenta_01` | le plus grand bâtiment, colonnes (repère n° 1) | 12 × 9 (3..14, 31..39), porte 2 cases (8..9, 39) | 1 |
| `WORLD_BLDG_ARENE_ARGENTA_01` → `bldg_arene_argenta_01` | Arène-forteresse dans les rochers (repère n° 2) ; `bldg_arene_01` est celle de Jadielle | 12 × 7 (30..41, 5..11), porte 2 cases (35..36, 11) | 1 |
| `WORLD_BLDG_MAISON_ARGENTA_01` → `bldg_maison_argenta_01` | maison de pierre au toit de tuiles (les maisons de Bourg Palette et Jadielle sont plus petites, 5–6 × 3) | 7 × 6, porte au 4e rang (x + 3) ; utilisée deux fois | 1 |
| `WORLD_RELIEF_PAROI_PLANCHE` → `relief_paroi_01..04` | paroi de montagne (repère n° 3) : nord d'Argenta et bloc rocheux de la Route 2 nord ; `relief_falaise_01` est une falaise basse | planche de 4 modules (≈ 4 × 3 cases), découpés par `preparer.py` | 1 |
| `WORLD_PROP_ROCHER_PLACE_01` → `prop_rocher_place_01` | gros rocher de la place (repère n° 4) | 3 × 3 (25..27, 17..19) | 1 |
| `WORLD_PROP_BLOCS_TAILLES_01` → `prop_blocs_tailles_01` | chantier du tailleur (blocs, outils) | 3 × 2 (3..5, 23..24) | 1 |
| `WORLD_BLDG_POSTE_FORET_NORD_01` → `bldg_poste_foret_nord_01` | le poste vu depuis la Route 2 nord : toit, mur nord, porte en haut de l'emprise (écart n° 7) | 7 × 3 (12..18, 21..23), porte (15, 21) | 1 |
| `PNJ_PIERRE` (+ attente) → `pierre` (`brock`) | le Champion | 128 px, marche + attente | 2 |
| `PNJ_TAILLEUR` (+ attente) → `tailleur` (`stonemason`) | habitant n° 1, routine de 3 cases | 128 px | 2 |
| `PNJ_MONTAGNARD` (+ attente) → `montagnard` (`mountaineer`) | Route 2 nord (arbitrage 7) ; la Randonneuse est déjà prise | 132 px | 2 |
| `PNJ_CAMPEUR` (+ attente) → `campeur` (`camper`) | Campeur Liam | 112 px | 2 |
| `PNJ_GUIDE_ARENE` (+ attente) → `guide_arene` (`gym_guide`) | guide d'Arène, **réutilisé dans les 8 Arènes** | 128 px | 2 |
| `POKE_RACAILLOU_FIXE` → `racaillou` (`pokemon/geodude`) | Racaillou d'ambiance (« travaille ») ; format « Pokémon fixe » du J9 (4 poses : repos et réaction, face et profil) | 56 px | 1 |
| `INT_MUSEE_COQUE` → `int_musee_coque` | **une** enveloppe pour les **deux** salles : porte sud de 2 cases, ouverture centrale au mur nord (salle principale : vers la salle science ; salle science : fermée par la porte du laboratoire) | 15 × 10 | 1 |
| `INT_MUSEE_PLANCHE` → `int_vitrine_dome_01`, `_nautile_01`, `_pierre_lune_01`, `_journal_01`, `int_porte_labo_01`, `int_panneau_expo_01` | vitrines (contenu peint), porte « LABORATOIRE », panneau d'exposition (évolution, traces) | 1 à 2 cases chacun | 1 |
| `INT_ARENE_COQUE` → `int_arene_coque` | salle de roche claire, sol de sable, parois (estrade de Pierre peinte) | 15 × 11 (§1.3) | 1 |
| `INT_ARENE_ROCHERS_PLANCHE` → `int_pilier_roche_01`, `int_rochers_bas_01`, `_02` | piliers naturels et formations (cases `R`) | 2 × 1, 2 × 2 | 1 |
| `INT_MAISON_ARGENTA_COQUE` → `int_maison_argenta_coque` | une enveloppe, deux mobiliers (arbitrage 14) | 15 × 10 (défaut) | 1 |

Hauteurs, tenues, emprises = **valeurs par défaut** (règle 4). Personnages : la tenue vient de la vue générale quand elle existe (tailleur, Montagnard, vieil habitant), sinon de la fiche.

**Conditionnels** (prompts prêts dans `serie12.py`, jamais lancés par défaut ; décision de l'architecte sur capture, notée dans `etat-projet.md`) : `WORLD_PROP_EBOULIS_01` (si les rochers existants ne se lisent pas comme un sentier bloqué) ; `WORLD_PROP_ROCHER_ROUTE2N_01` (si la grande pierre réduite fait doublon visible) ; `UI_BADGE_ROCHE` (image du badge, seulement si Kevin la demande, §5).

**Personnages réutilisés** (défaut : jamais deux fois le même modèle sur une même carte ; un habitant anonyme peut reprendre un modèle vu dans une autre ville, comme Rouge/Bleu) : enfant de la place → `kid` ; visiteuse du Musée → `vieille` ; vieil habitant → `old` ; jeune Dresseuse → `lass` ; employé du Musée → `courier` ; chercheurs de la salle science → `researcher` et `chercheuse` ; maison du tailleur : compagne → `maya`, enfant → `kid` ; maison de la chercheuse → `chercheuse` (sa sœur travaille au Musée : même famille de tenue) ; garde de la Route 3 → `guard` (J9, arbitrage 5).

**D. Abandonnés** (écarts de la vue, dossier 12 « Vue générale peinte v1 ») : décrochement du chemin de la Route 2 nord et poste décalé (chemin droit) ; façade du poste vue de face (porte en haut de l'emprise, n° 7) ; bancs supplémentaires et caisses près de la Boutique au-delà de la grille ; personnages placés par la vue.

**Poids attendu** : ≈ 4 à 5 Mo de PNG ajoutés (3 bâtiments ≈ 1 Mo chacun au plus, coques 960 × 768 × 3, planches de personnages × 10).

---

## 2. Conception technique

### 2.1 Cartes et raccords (T11)

| Carte | Taille | Profil | Titre (`display_name` / `region`) |
|---|---|---|---|
| `route_2_north` | 30 × 24 | `golden_hour` | « Route 2 » / « Forêt de Jade — Argenta » (dossier §20) |
| `pewter_city` | 52 × 44 | `golden_hour` | « Argenta » / "" (titre seul, arbitrage 10) |
| `pewter_center`, `pewter_mart` | 15 × 10 | `interior_warm` | « Argenta » (toast du point de repos) |
| `pewter_museum`, `pewter_museum_science` | 15 × 10 | `interior_warm` | « Argenta » |
| `pewter_gym` | 15 × 11 | `interior_warm` | « Argenta » |
| `pewter_house_mason`, `pewter_house_researcher` | 15 × 10 | `interior_warm` | « Argenta » |

- **Outils** : `tools/build_route_2_north.gd` et `tools/build_pewter_city.gd`, modèle `build_route_2.gd` (deux passes masque / scène, graines fixes), lecteur `PlanGrid` (avec `PRATICABLES` du J9). `Ground` invisible = un caractère par case ; `K`, `M`, `Z`, `C`, `O`, `m`, `k`, `n`, `R`, `E`, `x`, `T` bloqués ; `p` (pavé) praticable, masque R.
- **Raccords** : Argenta (17..19, 43) PUSH ↓ → `route_2_north`, `from_pewter_w/c/e` (14..16, 0) tournés ↓ ; Route 2 nord (14..16, 0) PUSH ↑ → `pewter_city`, `from_route_2_north_w/c/e` (17..19, 43) tournés ↑ ; Route 2 nord (15, 21) STEP_ON ↓ → `viridian_forest_gate_north`, `from_route_2_north` (spawn de la porte nord du poste, tourné ↓) ; spawn `from_forest_gate` (15, 20) tourné ↑.
- **Poste nord (J9)** : la porte nord de `_forest_gate(&"north")` perd son `coming_soon` « Route 2 nord » et mène à `route_2_north` / `from_forest_gate` ; scène régénérée seule (`--rooms=viridian_forest_gate_north`). `test_coming_soon` (que le J9 réécrit sur cette porte) passe sur la **sortie est d'Argenta** (« ROUTE 3 — À venir »).
- **Portes** : Musée (8..9, 39), Arène (35..36, 11), Centre, Boutique, maisons (6, 20) et (46, 20) : STEP_ON ↑ ; spawns `from_<lieu>` sur la case devant la porte, tournés ↓. Intérieurs : sortie de 2 ou 3 cases au mur sud (PUSH ↓), spawns `entrance`.
- **Sortie est** (51, 25..27) : PUSH →, `coming_soon = "Route 3"` (actif en build debug seulement, comportement existant) ; avant le badge, le garde l'empêche (§2.11).
- **Performances** (budget du J9, défaut) : ≤ 3 000 nœuds par carte, changement de carte ≤ 1,5 × celui de Jadielle, moyenne ≥ 58 fps sur S24 avec des creux ≥ 50 (la Route 2 a été validée à 53 fps : mesurer Jadielle, la Route 2 et Argenta dans la même session). Argenta a **8 voisines par warps** (7 intérieurs + la route) : avec le cache borné du J9 (toutes les voisines préchargées), mesurer la mémoire au T11 ; si elle dépasse 64 Mo « carte seule + voisines », ne précharger que les voisines extérieures (décision de l'architecte, notée).

### 2.2 Intérieurs (T13)

Dans `tools/build_painted_interiors.gd` (après le J9, qui y ajoute `_forest_gate`) :
- **Centre et Boutique** : `_viridian_center()` et `_viridian_mart()` deviennent `_pokemon_center(id, node, title, exit_target)` et `_poke_mart(…)` (mêmes meubles, mêmes cases, même infirmière et même marchand) ; Jadielle **n'est pas régénérée** (option `--rooms=pewter_center,pewter_mart` ; un test compare les deux définitions hors identifiants). Le déclencheur du colis reste propre à Jadielle.
- **Musée** : `pewter_museum` (salle principale : 3 vitrines Dôme, Nautile, Pierre Lune, ouverture nord → `pewter_museum_science`) et `pewter_museum_science` (2 chercheurs, panneau d'exposition, vitrine du journal, porte du laboratoire **fermée** au fond : panneau + porte = 2 points d'examen) ; une seule coque (§1.4). Passage entre salles : STEP_ON ↑ / PUSH ↓, spawns `from_hall` / `from_science`.
- **Maisons** : `_pewter_house(id, furniture)` → deux scènes d'une coque (arbitrage 14).
- **Arène** : `pewter_gym`, grille `tools/plans/argenta_arene.txt` (§1.3) relue par l'outil (piliers et rochers = meubles `WorldProp` aux cases `R`, le reste bloqué par la coque).

### 2.3 Espèces et capacités (T8)

- `data/pokemon/species/kanto.json` : `geodude` (74), `graveler` (75), `golem` (76, évolution `trade`), `sandshrew` (27), `sandslash` (28), `onix` (95). Conventions des espèces existantes : statistiques et taux actuels, **apprentissages de Rouge/Bleu** ; les évolutions entrent dans les données pour que le Pokédex montre « Racaillou → ??? » (défaut, comme Raichu au J9).
- `moves.json` : `rock_throw` (Jet-Pierres : Roche, physique, 50, précision 90, PP 15), `defense_curl` (Boul'Armure : statut, Défense +1 sur soi, PP 40) ; les capacités des apprentissages de Rouge/Bleu qui manquent : **Destruction** (`self_destruct`, 200, `pending_effects: ["self_ko"]`), **Séisme** (`earthquake`, 100), **Explosion** (`explosion`, 250, `["self_ko"]`), **Étreinte** (`bind`, 15, précision 85, `["trap"]`), **Souplesse** (`slam`, 80, précision 75) ; ni Ligotage ni Patience (§0.3 n° 1) ; descriptions du lot validé (A, note A2 : sans mention du K.O. absent).
- Pokédex : 6 entrées (taille, poids officiels ; descriptions et 3 notes des formes de base : lot validé, B). Sprites provisoires : `gen_placeholder_battlers.gd` étendu à Sabelette, Racaillou et Onix (exigé par `test_battle_stage` : toute espèce de Dresseur ; l'adversaire est l'artwork officiel) ; Gravalanch, Grolem et Sablaireau n'en ont pas (jamais en combat au J10).
- Vérifié : Grincement (`screech`), Charge, Griffe, Jet de Sable existent ; Armure (`harden`) et Choc Mental arrivent avec le J9 ; Salamèche a Flammèche au Nv. 9 (`kanto.json`). Racaillou Nv. 10–12 de Rouge/Bleu : Charge, Boul'Armure (Nv. 11) ; Sabelette Nv. 10 : Griffe, Jet de Sable.

### 2.4 Capacités choisies à la main (T3, maintenant)

```gdscript
# game/battle/trainer_slot.gd
var species: StringName = &""
var level: int = 1
## Capacités choisies à la main (1 à 4, distinctes, connues de PokemonData), dans l'ordre ;
## vide = celles de Rouge/Bleu au niveau (PokemonFactory). Dossier 12 §2 (Pierre).
var moves: Array[StringName] = []
```
- `TrainerLibrary` : `_SLOT_KEYS` += `"moves"` ; tableau de 1 à 4 identifiants **distincts** et **connus** (`PokemonData.get_move`), sinon erreur (« moves » mal formé, capacité inconnue, doublon, plus de 4). Pas de contrôle « apprenable » (c'est le but : Onix Nv. 14 avec Armure et Jet-Pierres).
- `build_team` : après `PokemonFactory.create`, si `slot.moves` n'est pas vide : `pokemon.moves.clear()` puis `learn_move` pour chacune (PP pleins) — **même règle que `DebugStart._create`** ; aucun tirage aléatoire en plus (les combats à graine fixe ne bougent pas).
- Données (T8) : `"team": [{ "species": "geodude", "level": 12, "moves": ["tackle", "defense_curl"] }, { "species": "onix", "level": 14, "moves": ["tackle", "screech", "harden", "rock_throw"] }]`.
- Tests : **`tests/unit/test_trainer_slot_moves.gd`** (nouveau) : lecture, ordre, PP pleins, refus (inconnue, doublon, 5 capacités, vide, pas un tableau), sans `moves` = capacités de Rouge/Bleu (inchangé), même graine → même équipe avec ou sans `moves` (IV et sexe identiques).

### 2.5 Campeur Liam : la réplique « vaincu » (T9, après le J9)

Bloc `trainer` du J9 + une clé facultative **`defeated`** (réplique dite **une fois** juste après la victoire) ; `dialogue` reste la réplique permanente (« après »). Sans `defeated`, comportement du J9 inchangé (la réplique « après » est dite tout de suite). `TrainerEncounter.build` : étape 6 = `defeated` si présente, sinon `dialogue`. `NpcRoster` la valide (dialogue existant) ; `test_npc_roster` / `test_trainer_encounter` étendus (les cinq Dresseurs de la forêt inchangés).

```json
"camper_liam": { "cell": [2, 6], "facing": "right", "sprite": "camper",
	"dialogue": "pewter_gym_liam_after",
	"trainer": { "id": "pewter_gym_liam", "sight": 5, "before": "pewter_gym_liam_before",
		"defeated": "pewter_gym_liam_defeated" } }
```
`data/trainers/pewter_gym.json` : `pewter_gym_liam` (« Campeur Liam », `random`, Racaillou 10, Sabelette 10, `prize_money` 200) ; `pewter_gym_brock` (« Pierre », `smart`, équipe du §2.4, `prize_money` 1 300, `start_message` faux : la carte et l'introduction en tiennent lieu ; `end_message` vrai, « Tu as battu Pierre ! » ; SAC permis ; **aucun objet** : l'IA n'en utilise pas), et son bloc **`card`** (§2.7). Liam battu = `beaten_pewter_gym_liam` (J9).

### 2.6 Pierre : une scène écrite (modèle du rival n° 2)

Pierre est un PNJ **sans** bloc `trainer` (pas de vision : on vient lui parler), tourné ↓ en (7, 2). Son dialogue `pewter_gym_brock` a trois variantes : `if: [badge_boulder]` → allusion au rival (« Un autre Dresseur de Bourg Palette… », 2 pages) ; sinon → `{ "cutscene": "pewter_gym_brock" }`. Scène (`data/cutscenes/pewter_gym.json`), une variante `unless: [badge_boulder]` :

1. `face` Pierre → joueur ; `dialogue` `pewter_gym_brock_intro` `unless: [brock_met]` (3 lignes = 2 pages) **ou** `pewter_gym_brock_resume` `if: [brock_met]` (« Prêt à essayer autrement ? ») ; `set: [brock_met]` ;
2. `champion_card` `pewter_gym_brock` (§2.7) ;
3. `battle` `pewter_gym_brock`, `win: [badge_boulder]` (bilan d'XP et évolution éventuelle jouent dans le combat, J9) ;
4. victoire (`if: [badge_boulder]`) : `wait` 0,6 → `dialogue` `pewter_gym_brock_won` (« Bien joué. » / « Mes Pokémon n'ont pas tenu face aux tiens. ») → **`badge` `boulder`** (§2.8) → `dialogue` `pewter_gym_brock_badge` ;
5. défaite (`unless: [badge_boulder]`) : `dialogue` `pewter_gym_brock_lost` (« Une équipe solide ne suffit pas. » / « Reviens avec une autre approche. ») → `wake_up` (réveil au dernier Centre utilisé, aucun argent perdu, existant).

Fin de scène → autosave existant ; objectif et écran Dresseur suivent le drapeau sans code. Liam battu le reste (`beaten_*`). Aucun Grand moment « rival » (équipe fixe : `Boot._on_battle_finished` ne l'enregistre que pour `team_by_starter`).

### 2.7 Carte de présentation du Champion (T5 maintenant, T9 après le J9)

- **Composant (T5)** : `game/ui/components/champion_card.tscn` + `champion_card.gd` (`class_name ChampionCard`, `Control`) : `show_card(name: String, title: String) -> void`, signal `card_finished` ; carte posée sur le monde (verre sombre du thème, liseré ACCENT, nom en `FONT_TITLE` majuscules, titre en dessous), **entrée glissée** depuis la gauche, tenue `CHAMPION_CARD_HOLD`, sortie ; un toucher abrège la tenue ; « Réduire les animations » supprime le glissé ; ignore les entrées hors toucher. Style aligné sur l'interface de combat (`combat-maquettes`, CB.2 : aplats du thème, pas de pixel art) ; **aucun portrait** (le dossier ne donne que deux lignes). Tokens `CHAMPION_CARD_*` **en fin** de `ui_tokens.gd`.
- `ExplorationHud.show_champion_card(name, title)` + signal `champion_card_hidden` (comme `show_caption` / `caption_hidden`).
- **Étape de scène (T9)** : `CutsceneStep.Kind.CHAMPION_CARD` (**fin d'enum**, après `EMOTE` du J9), clé `"champion_card": "<id du Dresseur>"` ; le directeur lit `TrainerData.card` (`{ "name", "title" }`, nouveau bloc facultatif de `TrainerLibrary`, deux textes non vides) et attend `champion_card_hidden`. Données : `"card": { "name": "PIERRE", "title": "Champion d'Arène d'Argenta" }` (texte verrouillé). Réutilisable tel quel pour les 8 Champions (un bloc `card` par Champion).
- **Placement (défaut)** : dans le monde, **avant** la transition du combat (la logique et l'interface du combat ne changent pas ; indépendant du calendrier de CB.3). Si Kevin préfère la carte **dans l'ouverture du combat** (sur le décor peint de CB.3), c'est un branchement de quelques lignes dans le directeur de combat après la fusion de `combat-maquettes` (noté, pas fait).
- Tests : `tests/integration/test_champion_card.gd` (textes, majuscules, durée au pas près avec `TweenClock`, toucher qui abrège, réduction des animations, signal une fois) ; `test_cutscene_library` / `test_cutscene_director` (T9 : étape lue, attendue, refus d'un Dresseur sans `card`) ; capture `tools/capture_champion_card.gd` (1920 et 2340 × 1080).

### 2.8 « BADGE ROCHE » et Grand moment « badge » (T4 maintenant, T9 après le J9)

**Étape `badge` (T9)** : `CutsceneStep.Kind.BADGE` (fin d'enum), `{ "badge": "boulder" }` :
1. lève le drapeau du badge (`BadgeLibrary.flag`, déjà levé par le combat : sans effet) ;
2. légende `BadgeLibrary.badge_name` en MAJUSCULES (« BADGE ROCHE ») par `ExplorationHud.show_caption` — même composant que « POKÉDEX ACTIVÉ », tenue **2 s** (dossier §13 ; paramètre facultatif de `show_caption`, défaut inchangé 3 s) — et `Haptics.vibrate(UiTokens.HAPTIC_BADGE_MS)` (40 ms, « légère ») à l'apparition ; **aucun toast** ;
3. enregistre le Grand moment : `GameState.record_moment(&"badge", <carte>, BadgeMoment.details(id, party))`, une seule fois par badge (`BadgeMoment.has_badge_moment`).

**`BadgeMoment` (T4, pur, `game/systems/menu/badge_moment.gd`)** :
```gdscript
const TYPE: StringName = &"badge"
## { "badge": "boulder", "team": [ { "species", "level", "nickname" }, … ] } dans l'ordre de
## l'équipe (Pokémon K.O. compris). Ni formes ni états (arbitrage 12).
static func details(badge_id: StringName, party: Party) -> Dictionary
## Équipe relue d'un moment enregistré (tolérante : nombres relus en flottants, entrées
## mal formées écartées) — pour l'écran qui la montrera plus tard.
static func team_of(details: Dictionary) -> Array[Dictionary]
```
- **Sauvegarde : aucun changement de format (confirmé dans le code)**. `GameState.moments` est déjà sérialisé tel quel (`to_dict` : `moments.duplicate(true)`) ; au chargement, `details` est relu par `JsonFields.get_dict` (copie du dictionnaire lu, tableaux imbriqués conservés) ; `SaveSystem` ne regarde les détails que pour la migration v3 des `first_capture`. Un tableau d'objets est du JSON valide : seuls les nombres reviennent en flottants (`team_of` les remet en entiers). `record_moment` fait une copie **superficielle** des détails : `details()` construit un tableau neuf à chaque appel (pas de partage). Version de sauvegarde : celle du J9 (4), inchangée. Test d'aller-retour réel (T4) : `GameState.to_dict` → `JSON.stringify` → `JSON.parse_string` → `load_dict` → `team_of` identique.
- **Textes (T4)** : `MomentLibrary.TYPES` += `badge` (tous obligatoires), marques `{badge}`, `{city}`, `{leader}` (lues dans `badges.json` d'après `details.badge` ; un badge inconnu écarte le moment) ; `moments.json` : `"badge": { "title": "{badge}", "detail": "Obtenu à {city} contre {leader}." }` (texte verrouillé du dossier, marques en anglais comme `{zone}`) ; `zone_arrivals.pewter_city` : « Arrivée à Argenta » / détail (Q-5 ; défaut « Une nouvelle ville. », comme Jadielle). `TrainerSummary.moment_views` reçoit la `BadgeLibrary` (paramètre facultatif, déjà passé à `build`). `test_moment_library` (l. 40 : Argenta a maintenant son texte d'arrivée), `test_trainer_summary` (moment « badge » : titre, détail, lieu, ordre chronologique ; badge inconnu écarté), **`tests/unit/test_badge_moment.gd`** (nouveau : détails, ordre, surnom vide, K.O. compris, aller-retour JSON, lecture tolérante).

### 2.9 Écran Dresseur (T6, maintenant)

- **Détail au toucher** d'un badge obtenu (dossier 08 §6, dossier 12 §13) : `BadgeSlot` devient touchable **seulement s'il est obtenu** ; toucher → bulle de détail ancrée sur l'emplacement : « Badge Roche » / « Argenta — Pierre » (`BadgeSlotView.name`, `detail` déjà remplis par `BadgeLibrary`) ; second toucher ou toucher ailleurs → fermée. Un badge muet reste inerte (aucun « ??? » touchable). Image : l'emblème existant en ACCENT (pas d'image du Badge Roche au J10, §5).
- **Frise des Grands moments** : le moment `badge` s'y range par date comme les autres (titre « Badge Roche », détail « Obtenu à Argenta contre Pierre. », lieu « Argenta ») ; icône : l'emblème du badge. Le **souvenir de l'équipe n'est pas affiché** au J10 (« données avant interface », dossier §13).
- Tests : `test_trainer_screen` / `test_menu_trainer` (drapeau levé dans le test : emplacement touchable, détail, fermeture ; non obtenu inerte), capture par `tools/capture_menu.gd` (scénario `trainer_badge`).

### 2.10 Arrivée et objectifs (T4 pour les objectifs, T14 pour l'arrivée)

- `data/story/objectives.json`, **en tête** (la première entrée valide l'emporte) : `{ "id": "go_route_3", "text": "continuer vers la Route 3.", "if": ["badge_boulder"] }`, puis `{ "id": "get_boulder_badge", "text": "obtenir le Badge Roche.", "if": ["pewter_arrived"], "unless": ["badge_boulder"] }` ; `go_north` (J8) inchangé derrière. `test_objective_library` : les trois états (nord, badge à obtenir, Route 3). Sans effet en jeu tant que rien ne lève ces drapeaux.
- **Arrivée** : `EventTriggerPoint` sur les trois cases d'entrée (17..19, 42) → scène `pewter_arrival` (`unless: [pewter_arrived]`, une seule étape `set: [pewter_arrived]`) : ni dialogue ni caméra (arbitrage 10). Le titre « ARGENTA » et le Grand moment d'arrivée viennent des systèmes existants (`ZoneAnnouncer`, `discovered_maps`). Le drapeau sert aussi le garde nord du J9.

### 2.11 Garde de la Route 3 (T14 avant le badge, T19 après)

- PNJ `route_3_guard` en (48, 24), tourné ↓, apparence `guard` (J9). Avant le badge, son dialogue : « Pierre dirige l'Arène d'Argenta. » (en lui reparlant) ; la première réplique (« La Route 3 est réservée… ») est dite par le déclencheur.
- **Verrou** : `EventTriggerPoint` sur (48, 25..27) → scène `route_3_guard` variante `unless: [badge_boulder]` : `face` garde → joueur, `face` joueur → garde, `dialogue` règle, `move` joueur ← 1 case avec `keep_facing` (recul, existant), et l'on peut repasser (scène rejouée à chaque fois, dossier §9).
- **Après le badge** (Q-2, défaut recommandé) : variante `if: [badge_boulder]`, `unless: [route_3_guard_cleared]` : regard, « Badge Roche confirmé. » / « Bonne route ! », `move` garde ↑ (48, 23), `set: [route_3_guard_cleared]` ; deux entrées de PNJ (`unless` / `if` `route_3_guard_cleared`) donnent sa place au rechargement. Ensuite la sortie est mène à « ROUTE 3 — À venir » (build debug).

### 2.12 Habitants, Montagnard, ambiance (T14)

Données `data/npcs/pewter_city.json`, `route_2_north.json` et des intérieurs, positions de la grille (corrigée au T1) ; routines existantes (`route`, `look`, `idle_react`) ; réactions au badge **seulement** pour l'enfant, la jeune Dresseuse, le guide d'Arène, et le Montagnard qui le remarque (arbitrage 6) : variantes `if: [badge_boulder]`. Chercheuse : variantes « première fois / ensuite » par le drapeau `pewter_researcher_talked` (modèle J8, aucun drapeau lié aux vitrines). Racaillou du tailleur en (4, 25) : `idle_react` toutes les 5 s (pose « réaction » = soulève une pierre), immobile, non capturable, sans dialogue. Potion visible (4, 1) : modèle J8 (`object/poke_ball_ground`, `take`, `got_route_2_north_item_1`). Éboulis : point d'examen (24, 16..17), « Des éboulis bloquent le sentier. » ; aucun panneau « Accès fermé » (arbitrage 9). Vitrines, journal, laboratoire : points d'examen (`narration`), textes verrouillés.

### 2.13 Zones, Carte, Pokédex, rencontres, point de repos, Boutique (T8)

- `zones.json` : `pewter_city.maps` = les 8 cartes d'Argenta, `services` (Centre, Boutique, Arène ; l'Arène est découverte **en y entrant**, `found_on: pewter_gym`, défaut), `description` (texte verrouillé) ; Route 2 nord = 2e carte de la zone `route_2` (**Q-3 tranchée**), sous-titre et description de la zone inchangés (lot validé).
- `data/encounters/route_2_north.json` : table du dossier §3 (Roucool 35, Rattata 30, Nidoran ♀ 12, Nidoran ♂ 12, Piafabec 8, Férosinge 3 ; niveaux 5–7 / 6–7), `rate` 25, rampe 15 → 20 (comme la Route 2 sud).
- `rest_points.json` (**T13**, avec la carte : §0.3 n° 6) : `pewter_center` (`spawn` heal, `nurse_wakeup`, `registers` vrai) → toast « Point de repos enregistré — Argenta ». `data/shops/pewter_mart.json` : `poke_ball`, `potion`, `antidote` (sans condition : `poison_unlocked` est déjà levé à la sortie de la forêt).
- `lighting.json` (**T11** et **T13**, avec les cartes) : `pewter_city`, `route_2_north` → `golden_hour` ; intérieurs `interior_warm`. Un profil « plus sec » n'est créé que si la capture du T11 le demande.

### 2.14 Départs de débogage (T8, T16)

**Fait au T8** : `route_2_north`, `pewter`, `pewter_gym`, `brock_weak` (devant le Centre d'Argenta : `DebugStart` n'a pas de clé de point de repos, on se soigne d'abord), `badge_after` ; **au T16** : les trois `brock_<starter>` (niveaux mesurés). `tools/debug_start/` (README complété) : `route_2_north.json` (sortie du poste nord, équipe Nv. 10–12 de fin de J9, Pokédex activé, drapeaux du J9) ; `pewter.json` (entrée d'Argenta) ; `pewter_gym.json` (devant l'Arène, équipe « naturelle » mesurée au T16) ; `brock_charmander.json` (**scénario « départ Salamèche »** : Salamèche, Papilusion avec Choc Mental, Roucool, niveaux de la mesure, 3 Potions) ; `brock_squirtle.json`, `brock_bulbasaur.json` ; `brock_weak.json` (pour perdre : réveil, argent intact, `brock_met` posé, Liam battu → reprise sans introduction) ; `badge_after.json` (`badge_boulder` levé : garde, objectif, écran Dresseur).

### 2.15 Drapeaux et sauvegarde

| Drapeau / donnée | Posé par |
|---|---|
| `badge_boulder` (existe dans `badges.json`) | victoire contre Pierre (`win` du combat) |
| `beaten_pewter_gym_liam` | système du J9 |
| `brock_met` | premier dialogue de Pierre (défaut, §0.2 n° 8) |
| `pewter_arrived` | entrée dans Argenta (attendu par le J9) |
| `route_3_guard_cleared` | Q-2 (défaut recommandé) |
| `got_route_2_north_item_1` | Potion |
| `pewter_researcher_talked` | chercheuse (première fois / ensuite) |
| Grand moment « badge » | `moments[]` (détails : badge + équipe) |

**Format de sauvegarde inchangé** (version du J9) : des noms de drapeaux nouveaux dans un tableau existant et un moment de plus dans une liste existante. Ni « Musée visité », ni « Musée payé ».

---

## 3. Tâches

Branche d'intégration **`jalon-10`** depuis `main` (dans une copie dédiée), une branche par tâche (`j10-t<n>-<sujet>`) ; jamais de `pkill` ; chaque tâche met à jour `etat-projet.md` dans son commit.

#### T0 — architecte : plan (fait)
- Ce document ; `etat-projet.md`.

#### T1 — architecte : kit d'assets, grilles, critères (10.0) — **maintenant**
- Fiche nouvelle `docs/design/fiches-assets/serie-12-argenta.md` (une fiche par asset du §1.4 C : taille en cases, emprise, couche, ombre, `fade`, porte, références recadrées `REF_AR_*` de la vue) ; `tools/art/serie12.py` (`--refs`, génération, `--manifeste` **préparé mais non lancé**, `--planche`) ; prompts d'attente `tools/art/attente/prompts/{PIERRE,TAILLEUR,MONTAGNARD,CAMPEUR,GUIDE_ARENE}_ATTENTE.txt` ; planche de contrôle `build/art/AR_KIT_v1.png` (1 case = 48 px, héros à l'échelle).
- Grilles : corrections du §1.3 dans `argenta.txt` (puis `plan_aplats.py --empiler`, plan relu) ; `tools/plans/argenta_arene.txt` ; `tools/art/plan_check_argenta.py` (critères du §1.3).
- **CA** : chaque élément visible de la vue validée a un asset (réutilisé, varié, nouveau) ou est abandonné explicitement ; `plan_check_argenta.py` vert ; aucun fichier de `game/` ni de la liste du §1.2 touché.

#### T2 — constructeur-monde (Mac, Codex) : série 12 → **validation de Kevin (10.0)** — **maintenant**, après T1
- `ART=/Users/kevinyankam/dev/kanto-2026/build/art python3 tools/art/serie12.py` (trois générations à la fois ; une image déjà là n'est pas refaite ; correction = `_r2`) ; les conditionnels ne partent pas ; relecture contre la vue et `AR_KIT_v1.png` ; planche de contact `build/captures/jalon10_assets/` présentée à Kevin. Repli si Codex refuse un Pokémon (Racaillou) : planche faite par Kevin dans l'app ChatGPT (précédent DA.3).
- **CA** : images validées par Kevin ; journal de la série 12 dans la fiche. **Pas** de `manifeste.json`, `preparer.py` ni scène (T10).

#### T3 — architecte : capacités choisies à la main — **maintenant**
- §2.4. **CA** : `tools/test.sh` vert, import propre ; aucune donnée de jeu changée (le rival garde ses capacités de Rouge/Bleu).

#### T4 — architecte : Grand moment « badge » (pur), textes des moments, objectifs — **maintenant**
- §2.8 (partie pure), §2.10 (objectifs). **CA** : tests verts ; l'aller-retour JSON prouve l'absence de changement de format ; `game_state.gd` non touché.

#### T5 — ui-mobile : carte de présentation du Champion — **maintenant**
- §2.7 (composant + `ExplorationHud`). Lire `combat-maquettes.md` et les captures CB.2 pour le style. **CA** : tests verts, captures 1920 et 2340 × 1080 relues (lisibilité, coins sûrs) ; aucune modification de `game/ui/battle/`.

#### T6 — ui-mobile : écran Dresseur (badge obtenu) — **maintenant**, après T4 et T5
- §2.9. **CA** : tests verts, captures relues ; tableau de bord inchangé (sa ligne de badges existe déjà).

#### T7 — architecte : lot de textes système du J10 → Kevin — **maintenant**
- `docs/design/textes/textes-brouillon-j10.md` : ce que le dossier ne couvre pas (Q-5). **CA** : Kevin valide en une passe (bloque les données de T8, pas le code).

#### T8 — architecte : alignement après le J9, données — **après la fusion du J9**
- Fusionner `main` (J9 compris) dans `jalon-10` ; aligner ce plan (§0, §1.2, état réel de `TrainerEncounter`, du poste nord, du cache du `SceneRouter`, des outils de la série 11) ; noter les niveaux réels de l'équipe de Kevin (sauvegarde de la QA finale du J9).
- Données : §2.3, `data/trainers/pewter_gym.json` (§2.5, `card`), `pewter_mart.json`, `route_2_north.json` (rencontres), `zones.json`, `rest_points.json`, `lighting.json`, dialogues (`route_2_north.json`, `pewter_city.json`, `pewter_museum.json`, `pewter_gym.json`, `pewter_houses.json` : textes verrouillés **mot pour mot**, une réplique « « … » / « … » » = une page jointe par `\n`, convention du J9), scènes (`pewter_gym.json`, `pewter_city.json` : arrivée, garde ; `route_2_north.json` : Potion), PNJ (cases de la grille corrigée), départs (§2.14).
- Tests : `test_pokemon_data`, `test_pokedex_library`, `test_trainer_library` (Pierre : capacités, `card`), `test_shop_library`, `test_encounter_library` (poids 100, aucune espèce nouvelle), `test_zone_library`, `test_rest_points`, `test_dialogue_data` (dossier 12 ajouté aux sources « mot pour mot »), `test_cutscene_data`, `test_debug_start`, `test_npc_roster` (données réelles) — avec les gardes « en attente » tant que les cartes manquent (modèle du J8 T4).
- **CA** : tests verts, import propre ; aucune carte touchée.
- **Fait (2026-10-08, branche `j10-t8-donnees` depuis `jalon-10`)** : alignement (§0.3) ; données : 6 espèces, 7 capacités, 6 fiches de Pokédex (+ 3 notes), `data/trainers/pewter_gym.json` (Liam, Pierre avec `moves`, sans `card`), `data/shops/pewter_mart.json`, `data/encounters/route_2_north.json`, `zones.json` (Argenta, Route 2 nord dans `route_2`), dialogues (`route_2_north`, `pewter_city`, `pewter_museum`, `pewter_gym`, `pewter_houses` : 38, mot pour mot), scènes (`pewter_city` : arrivée, garde ; `route_2_north` : Potion ; `pewter_gym` : Pierre sans carte ni badge), PNJ (`route_2_north`, `pewter_city`, `pewter_center`, `pewter_mart`, `pewter_museum_science`, `pewter_gym` : cases des grilles ; maisons au T13, faute de grille), 5 départs, sprites provisoires de Sabelette, Racaillou, Onix. Tests : `test_pewter_data` et `test_pewter_dialogue_data` (nouveaux) ; listes des tests partagés mises à jour ; gardes « en attente » : `UNUSED_YET` (`test_dialogue_data`), `AWAITING_MAP` (`test_cutscene_data`), `AWAITING_MAPS` (`test_zone_library`).

#### T9 — architecte : moteur — **après la fusion du J9**, après T8
- Étapes `champion_card` et `badge` (§2.7, §2.8 ; fin d'enum, après `EMOTE`), `show_caption(text, hold)`, `HAPTIC_BADGE_MS`, bloc `card` de `TrainerLibrary`, clé `defeated` du bloc `trainer` (§2.5).
- Tests : `test_cutscene_library`, `test_cutscene_director` (carte attendue, légende 2 s au pas près, vibration demandée une fois, moment enregistré une fois, drapeau), `test_trainer_encounter`, `test_npc_roster`, intégration `test_brock_sequence.gd` (Boot réel, `qa`) : intro → carte → combat (graine cherchée) → victoire → légende → réplique → drapeau, moment, objectif ; défaite → réplique → réveil → reprise sans introduction.
- **CA** : tests verts ; les Dresseurs de la forêt et le rival n° 2 inchangés (`test_trainer_watcher`, `test_rival_route22`).
- **Fait (2026-10-08, branche `j10-t9-moteur` depuis `jalon-10`)** : `CutsceneStep.Kind.CHAMPION_CARD` et `BADGE` en fin d'enum (clés `"champion_card": "<Dresseur>"`, `"badge": "<badge>"`), `CutsceneLibrary.get_card_trainer_ids` / `get_badge_ids` ; directeur : `set_trainers`, `set_badges(badges, state)` (Boot) ; `TrainerData.card_name` / `card_title` / `has_card()` (champs typés plutôt qu'un dictionnaire `card`) ; `show_caption(text, hold = -1)` (WorldCaption, ExplorationHud) ; tokens `BADGE_CAPTION_HOLD` (2 s) et `HAPTIC_BADGE_MS` (40) en fin de `ui_tokens.gd` ; `NpcSpec.defeated_dialogue` (clé `defeated`) et `TrainerEncounter` ; `ChampionCard.reduce_motion` suit `GameSettings.reduce_motion` ; données : `card` de Pierre, carte après `set: [brock_met]`, badge après `pewter_gym_brock_won`, `defeated` de Liam. `test_brock_sequence.gd` pose Pierre sur Jadielle (pas d'Arène avant T13 / T17) : combat gagné par un Salamèche Nv. 40 (comme le rival n° 2), pas de graine cherchée.

#### T10 — constructeur-monde (Mac) : intégration de la série 12 — **après la fusion du J9** (T17 du J9)
- `python3 tools/art/serie12.py --manifeste` (entrées **en fin** de sections), `preparer.py --source …` deux fois, règles `PaintedPropRules` (fiches du T1), `build_painted_props.gd -- --nouveaux`, `build_character_frames.gd` (5 personnages ; Racaillou au format « Pokémon fixe » du J9 ; `guard` existe déjà).
- **CA** : second passage de `preparer.py` sans changement ; `test_painted_props` vert ; planche de contact relue.
- **Fait (2026-10-08, branche `j10-t10-serie12`)** : 23 images intégrées telles quelles ; `planches_objets` (découpe par taches, la grille demandée n'étant pas respectée par Codex) ; 19 scènes d'objets (`build_painted_props.gd -- --nouveaux`), 6 apparences (`brock`, `stonemason`, `mountaineer`, `camper`, `gym_guide`, `pokemon/geodude`) ; sous-classe `_PlancheAr` de `serie12.py` retirée (`_Planche(largeur, titre)` du J9) ; `serie12.py --controle` (planche des assets préparés à 1:1). Poste vu du nord : couche du sol + `origin` (voir `etat-projet.md`). Points pour T11 / T13 : `etat-projet.md`, entrée « J10 T10 ».

#### T11 — constructeur-monde : les deux cartes (10A) — après T10
- §2.1 : `build_route_2_north.gd`, `build_pewter_city.gd`, scènes, masques, raccords, porte nord du poste, sortie est « À venir », bâtiments posés (portes vers des intérieurs **pas encore construits** : gardes « en attente » de `test_map_links` jusqu'au T13), cases des PNJ réservées.
- Tests : **`test_route_2_north`** (grille de la scène = grille du plan, critères du §1.3, rencontres H1 / H2, éboulis, nœuds), **`test_pewter_city`** (idem, Musée dans le cadre de l'arrivée, sortie est, nœuds ≤ 3 000), `test_map_links`, `test_coming_soon` (sortie est), `test_encounter_director` ; `tools/capture_pewter.gd` (arrivée avec le Musée, place et rocher, Arène, paroi, Route 2 nord, porte du poste) relue contre la vue générale ; `[perf]` Mac et mémoire « carte seule + voisines ».
- **CA** : tests verts, captures 2340 × 1080 relues.

#### T12 — qa-mobile : validation 10A sur S24 → Kevin
- Vraie partie (porte nord du poste → Route 2 nord → Argenta → retour) et départ `route_2_north` ; traversées chronométrées (Q-4) ; rencontres ; fps (moyenne, creux), mémoire, temps de changement de carte (Jadielle, Route 2, Argenta dans la même session), taille de l'APK. **CA** : rapport `build/qa/jalon10_t12/` ; validation de Kevin ; remarques de rendu → « Reportés ».

#### T13 — constructeur-monde : les intérieurs — **après la fusion du J9**
- §2.2. Tests : `test_pewter_interiors` (tailles, sorties, spawns, Centre et Boutique = définitions de Jadielle hors identifiants, Musée : passage entre salles et laboratoire fermé, Arène : critères du §1.3 sur la vraie scène), `test_map_links` (gardes du T11 retirées), `test_rest_point_data`. **CA** : tests verts, captures relues ; Jadielle non régénérée (diff nul sur ses scènes).
- **Fait (2026-10-08, branche `j10-t13-interieurs`)** : 7 cartes par `build_painted_interiors.gd -- --argenta` (Centre et Boutique = `_pokemon_center` / `_poke_mart`, définitions de Jadielle ; Musée, Arène, maisons relus sur leur grille, clé `plan`) ; grilles des maisons ajoutées ; **Arène : sortie et guide remontés d'une rangée** (la coque peint le mur du bas sur 2 rangées) ; piliers avant remplacés par des rochers bas (ils cachaient Liam). Détail : `etat-projet.md`, « J10 T13 ».

#### T14 — constructeur-monde (+ ui-mobile en relecture) : la vie (10B)
- §2.10 (arrivée), §2.11 (garde **avant** le badge), §2.12 ; ui-mobile relit PRENDRE, toasts (point de repos « Argenta »), Boutique (Antidote), Carte (zone Argenta, description, services) et Pokédex.
- Tests : `test_pewter_life` (arrivée → drapeau et objectif « obtenir le Badge Roche. » ; garde : réplique, recul, rejouable ; Potion : Sac, `found_items`, retrait ; chercheuse première fois / ensuite ; réactions au badge seulement chez l'enfant, la Dresseuse, le guide et le Montagnard ; routines hors portes et hors panneaux). **CA** : tests verts, captures relues.

#### T15 — qa-mobile : validation 10B sur S24 → Kevin
- Vraie partie : Centre (soin, toast, point de repos), Boutique (achat d'Antidote), Musée (deux salles, vitrines, journal, laboratoire), maisons, habitants, garde, objectif, sauvegarde et reprise dans Argenta. **CA** : rapport `build/qa/jalon10_t15/` ; validation de Kevin.

#### T16 — architecte : équilibrage de Pierre — **après la fusion du J9** (données T8)
- `tools/simulate_brock.gd` (nouveau, modèle `simulate_first_battle.gd`) : 1 000 graines, Pierre (données réelles) contre des équipes « naturelles » mesurées sur la vraie partie de Kevin en fin de J9 (une par starter ; Salamèche seul, Salamèche + Papilusion avec Choc Mental, + Roucool) ; joueur « au hasard », « première attaque », `smart` ; taux de victoire et durée. Information pour Kevin, pas un seuil.
- **CA** : rapport dans `etat-projet.md` ; **proposition** de niveaux (12 / 14 gardés ou recalés) **validée par Kevin** avant T17 ; départs `brock_*` réglés.
- **Fait (2026-10-08, branche `j10-t16-equilibrage`)** : `tools/simulate_brock.gd` (vrai moteur, vraie IA, vraies données, 1 000 graines par ligne ; Route 2 nord = 3 combats sauvages tirés dans la vraie table, menés par le starter ; Liam ; soin ; Pierre ; joueur « naïf » ou « attentif » : meilleur rapport dégâts infligés / reçus en tête, capacités par l'IA `smart`, Potion quand le prochain coup peut mettre K.O. ; options `--seeds`, `--save <sauvegarde>`, `--trace <ligne>`). Équipe de Kevin recopiée de `save_fin_qa.json` (IV compris : son Salamèche a **1** en Attaque, Att. Spé. et Déf. Spé.). Rapport complet : `build/sim/brock_t16.txt` (non versionné, ≈ 12 min). **Résultat** : avec les capacités des données, **Jet-Pierres d'Onix bloque Salamèche à tous les niveaux essayés** (12/14 → 10/10) : Onix est plus rapide que Salamèche, Roucool et Papilusion, Jet-Pierres met Papilusion K.O. en un coup (×4), Roucool (×2) et retire à Salamèche près de la moitié de ses PV (×2), et Flammèche ne lui retire que 3–4 PV. Équipe de Kevin à l'arrivée : **0 %** contre 12/14 même avec 5 Potions, **≤ 8 %** contre 10/10 ; il faudrait un Salamèche **N17–18** (Reptincel, 44–72 %, ≈ 55–70 combats sauvages). Équipes types Salamèche (± Papilusion, Férosinge) : 0–0,3 % à 12/14. **Sans Jet-Pierres** (Onix : Charge, Grincement, Armure) et **niveaux 12/14 inchangés** : Kevin 4 % sans Potion, 17 % avec 1, 65 % avec 3, 95 % avec 5 ; Salamèche + Roucool (3 Potions) 77 % ; Bulbizarre + Roucool 87 % sans Potion ; Carapuce 100 % — exactement le dossier (Salamèche le plus exigeant, jamais bloqué ; Carapuce et Bulbizarre avantagés). **Recommandation** : garder Racaillou 12, Onix 14 et Liam 10/10 (aucune donnée changée) et **retirer Jet-Pierres d'Onix** → **Q-6** (décision de Kevin, non appliquée). Départs `brock_charmander`, `brock_squirtle`, `brock_bulbasaur` (starter N12 = niveau moyen mesuré devant Pierre, Roucool N10, + Papilusion N10 Choc Mental pour Salamèche, 3 Potions, Liam pas battu) et `brock_kevin` (sa vraie équipe après la route, IV tirés) ; test `test_brock_starts.gd`.

#### T17 — constructeur-monde : l'Arène sur la carte (10C) — après T9, T13, T16
- Guide, Liam (bloc `trainer`, vision vérifiée sur la vraie scène), Pierre (dialogue → scène), données finales ; capture `tools/capture_pewter_gym.gd` (entrée : Pierre visible ; carte du Champion ; combat contre Onix).
- Tests : `test_pewter_gym` (Liam évitable et inévitable selon le chemin, sur la scène avec les PNJ ; approche qui ne ferme rien ; Pierre atteignable ; caméra immobile). **CA** : tests verts, captures relues.
- **Fait (2026-10-09, branche `j10-t17-arene`)** : sans changement de moteur, de données ni de carte ; `test_pewter_gym` (5, vraies entrées sur Boot), `test_brock_sequence` rebasé sur l'Arène (graine cherchée, réveil au Centre d'Argenta), aide `tests/helpers/trainer_seed.gd`, captures `tools/capture_pewter_gym.gd` (Liam, carte, Onix, badge, après). Détail : `etat-projet.md`, « J10 T17 ».

#### T18 — qa-mobile : validation 10C sur S24 → Kevin
- Départs `brock_charmander` (**scénario Salamèche**), `brock_squirtle`, `brock_bulbasaur`, `brock_weak` (défaite : réplique, réveil, argent intact, reprise « Prêt à essayer autrement ? », Liam toujours battu) ; carte du Champion ; IA (Grincement, Armure au plus deux fois, Jet-Pierres préféré quand il est super efficace) ; durée des combats. **CA** : rapport `build/qa/jalon10_t18/` ; validation de Kevin (niveaux confirmés).

#### T19 — constructeur-monde puis qa-mobile : le badge et la QA finale (10D)
- Garde **après** le badge (Q-2), sortie est « À venir », réactions au badge, objectif « continuer vers la Route 3. » ; test `test_pewter_badge` (scène complète sur Boot réel : drapeau, moment avec l'équipe, objectif, garde déplacé au rechargement, écran Dresseur).
- QA finale (qa-mobile) : **vraie partie de Kevin** sans drapeau de débogage, du poste nord au badge : Musée, Centre, Liam, défaite éventuelle, victoire, « BADGE ROCHE » + vibration, écran Dresseur (badge, détail, Grand moment), garde, sauvegarde et reprise (format du J9, moment relu). **CA** : rapport `build/qa/jalon10_t19/` ; validation de Kevin ; fusion de `jalon-10` dans `main`.

#### T20 — architecte : clôture
- `etat-projet.md`, lot de textes, passation au J11 (CT de Pierre « J'allais oublier. » sur `badge_boulder` sans le drapeau de la CT, dossier §14 ; image du badge si demandée ; souvenir de l'équipe à afficher) et au J12 (sortie est d'Argenta → Route 3, éboulis → Grotte Taupiqueur plus tard).

---

## 4. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Le J9 change encore** (tranche B, T17–T23) | plan désaligné, conflits | « maintenant » limité aux fichiers nouveaux ou hors liste (§1.2) ; T8 réaligne ; `jalon-10` ne va dans `main` qu'à la fin |
| **Conflits avec `combat-maquettes`** (`ui_tokens.gd`, interface de combat) | fusions pénibles | carte du Champion hors de `game/ui/battle/`, tokens en fin de fichier |
| **Pierre trop dur avec Salamèche** (ou trop facile avec Carapuce) | leçon des types ratée ou frustration | simulation (T16) sur la vraie partie de Kevin, scénario Salamèche en QA (T18), niveaux décidés par Kevin |
| **Performances d'Argenta** (52 × 44, 8 voisines préchargées) | fps, mémoire | budget testé, mesures Mac (T11) et S24 (T12, même session que Jadielle et la Route 2), préchargement limité aux voisines extérieures si besoin |
| **Série 12 plus grosse que la 10 et la 11** (23 images) | délai, cohérence | ancres de style, une planche par famille (vitrines, rochers, paroi), conditionnels jamais lancés par défaut |
| **Porte du poste vue du nord** (asset sans équivalent) | lecture de la porte | fiche précise (porte au mur nord, convention des passages), capture du T11 |
| **Grand moment mal relu** (nombres JSON en flottants) | souvenir faux plus tard | `BadgeMoment.team_of` tolérant, test d'aller-retour réel (T4) |
| **Carte du Champion hors du combat** | sensation « menu » plutôt que « duel » | style du combat (CB.2), capture relue ; branchement dans l'ouverture du combat possible après CB.3 (§2.7) |

---

## 5. Questions pour Kevin

> **Décisions de Kevin (2026-10-08) : Q-1 à Q-5, toutes les recommandations retenues** (lancement des tâches « maintenant » ; drapeau `route_3_guard_cleared` ; Route 2 nord = 2e carte de la zone `route_2` ; grille gardée, durée mesurée sur S24 au T12 ; lot de textes système rédigé au T7). Choix de présentation du kit (tenues de Pierre, du Montagnard, du guide, de Liam) : retenus, à confirmer sur la planche de contact du T2.

Vraies questions (une valeur par défaut permet de continuer) :

- **Q-1 — Lancement.** Valider ce plan et lancer **tout de suite** les tâches « maintenant » (T1 kit d'assets puis T2 Codex, T3 capacités choisies, T4 Grand moment « badge », T5 carte du Champion, T6 écran Dresseur, T7 lot de textes), alors que le dossier 12 disait « pas d'implémentation avant la fusion du J9 » ? *Recommandation : oui ; rien de ce qui part maintenant ne touche le J9.*
- **Q-2 — Le garde de la Route 3 après le badge.** Le dossier dit « sa réplique **une fois**, puis il se décale définitivement » (§9) et « décalé : **dérivé du badge** » (§18). *Recommandation : un drapeau `route_3_guard_cleared` : au premier passage avec le badge, il dit « Badge Roche confirmé. / Bonne route ! », fait un pas de côté et reste décalé (format inchangé).* Alternative sans drapeau : il est déjà sur le côté dès le badge et dit cette réplique chaque fois qu'on lui parle (le « une fois » disparaît).
- **Q-3 — La Route 2 nord dans les menus.** Défaut du dossier §20 : une **zone à part** (« Route 2 », sous-titre « Forêt de Jade — Argenta ») : deux « Route 2 » dans les habitats du Pokédex et sur la Carte, une description de zone à écrire. *Recommandation : la Route 2 nord est la **deuxième carte de la zone `route_2`** : une seule Route 2 dans les menus (comme Kanto), le titre à l'arrivée garde son sous-titre « Forêt de Jade — Argenta » (il vient de la carte), aucun texte nouveau.*
- **Q-4 — Durée de la Route 2 nord.** Le dossier §3 annonce 25–35 s de traversée directe ; la grille validée donne **21 pas** de la porte du poste à l'avenue (≈ 5 s de marche, plus une éventuelle rencontre). *Recommandation : garder la grille (le sas court est voulu, la forêt est la longue partie) et remplacer la durée indicative par la mesure S24 du T12.* Alternative : allonger la route (nouvelle grille, nouveau plan, la vue reste valable si la composition ne change pas).
- **Q-5 — Lot de textes système du J10** (**validé le 2026-10-08**, recopié au T8) (non couverts par le dossier) : descriptions de Jet-Pierres, Boul'Armure et des capacités des apprentissages ajoutés ; 6 descriptions Pokédex (Racaillou, Gravalanch, Grolem, Onix, Sabelette, Sablaireau) ; détail du Grand moment « Arrivée à Argenta » ; noms affichés (« Pierre », « Campeur Liam », « Guide », « Montagnard », « Tailleur », « Visiteuse », « Employé du Musée », « Chercheur », « Chercheuse », « Garde », « Habitante », « Enfant ») ; libellé de la bulle de détail d'un badge. *Recommandation : l'architecte rédige le lot au T7 dans le ton des textes verrouillés ; tu le valides en une passe (comme au J9).*

- **Q-6 — Jet-Pierres d'Onix (T16, bloque T17). DÉCISION DE KEVIN (2026-10-09) : Onix GARDE Jet-Pierres**, niveaux 12 / 14 et Liam 10 / 10 inchangés (« je n'aurai qu'à mieux me préparer ») ; aucune donnée à changer ; dossier 12 (arbitrage 3, §11, tableau) corrigé. Historique : La simulation montre qu'avec Jet-Pierres, **aucun niveau** ne respecte « Salamèche le plus exigeant, **jamais bloqué** » pour ta vraie partie : 0 % à l'arrivée contre Racaillou 12 / Onix 14 (même avec 5 Potions), ≤ 8 % en descendant jusqu'à 10 / 10, et il faudrait monter Salamèche au N17–18 (Reptincel). Papilusion n'est pas une réponse : Onix est plus rapide et Jet-Pierres le met K.O. en un coup (×4). Bulbizarre est lui aussi en peine (17 % sans Potion, 51 % avec 3), Carapuce gagne toujours en 2–3 tours. *Recommandation : Onix **sans Jet-Pierres** (Charge, Grincement, Armure ; dans nos données comme dans Rouge/Bleu, Onix n'apprend Jet-Pierres qu'au N19), niveaux 12 / 14 gardés : ta partie gagne à 17 % avec ta Potion, 65 % avec 3, 95 % avec 5 ; Salamèche + Roucool 77 % (3 Potions) ; Bulbizarre 87 % ; Carapuce 100 %.* Alternative : garder Jet-Pierres (identité « Roche » plus forte) en acceptant qu'un joueur Salamèche sans Carapuce doive s'entraîner longtemps (≈ 55–70 combats sauvages pour le N17–18) ; baisser les niveaux ne suffit pas. **Jet-Pierres sur Racaillou** (Charge, Boul'Armure, Jet-Pierres ; Onix : Charge, Grincement, Armure), mesuré ensuite (`--grille 2`) : **ne débloque pas Salamèche**. Racaillou a une Attaque bien plus forte qu'Onix (80 contre 45) : Jet-Pierres met Roucool K.O. en un coup et retire ⅔ des PV de Salamèche. Racaillou 12 / Onix 14 : Kevin 0 / 0 / 0 / 0,6 % avec 0 / 1 / 3 / 5 Potions, Salamèche + Roucool 0 %, + Papilusion 3,6 %, Bulbizarre + Roucool 14,5 % (80 % avec 3 Potions), Carapuce 100 % ; Racaillou 11 : Kevin 1,9 % au mieux. **Recommandation maintenue : aucun Jet-Pierres.**

**À fournir par Kevin** (pas une question) : la sauvegarde de sa vraie partie à la fin de la QA du J9 (équipe et niveaux) pour le T16.

Valeurs par défaut notées (règle 4), à corriger d'un mot si besoin :

| Sujet | Défaut |
|---|---|
| Validations | 10.0 sur la planche de contact (Kevin), puis 4 sessions S24 : 10A route et ville, 10B bâtiments et vie, 10C Arène, 10D badge + QA finale |
| Branches | `jalon-10` depuis `main` ; tâches « maintenant » sur fichiers nouveaux ou hors J9 ; fusion de `main` après le J9 au T8 |
| Kit (série 12) | 23 images : Musée, Arène, maison (×2), paroi (planche de 4), rocher de la place, blocs du tailleur, poste vu du nord ; Pierre, tailleur, Montagnard, Campeur, guide d'Arène (marche + attente) ; Racaillou « Pokémon fixe » ; coques Musée (une pour deux salles), Arène, maison ; planches vitrines + porte du labo, rochers de l'Arène ; conditionnels : éboulis, rocher de la Route 2 nord, image du badge |
| Réutilisés | Centre, Boutique (façades et intérieurs), sols, forêt serrée, arbres, hautes herbes jaune-vert, bancs, panneaux, buissons, grande pierre × 0,75 pour la Route 2 nord, éboulis en rochers existants, meubles de Bourg et du labo |
| Habitants réutilisés | enfant `kid`, visiteuse `vieille`, vieil habitant `old`, Dresseuse `lass`, employé `courier`, chercheurs `researcher` + `chercheuse`, compagne `maya`, garde `guard` (J9) ; jamais deux fois le même modèle sur une carte |
| Corrections de grille | panneau « ARGENTA » en (16, 42) ; Centre ramené à 8 cases de large ; emprises des bâtiments neufs = grille |
| Arène | 15 × 11 (salle entière à l'écran : Pierre visible depuis l'entrée) ; Liam (2, 6) tourné →, vision 5, détour à l'est (13 pas contre 7) ; guide (5, 9) ; Pierre (7, 2) |
| Musée | deux cartes (`pewter_museum`, `pewter_museum_science`) d'une même coque ; journal et laboratoire dans la salle science |
| Maisons | une coque, deux scènes, mobilier de Bourg Palette |
| Identifiants | `route_2_north`, `pewter_city`, `pewter_center`, `pewter_mart`, `pewter_museum`, `pewter_museum_science`, `pewter_gym`, `pewter_house_mason`, `pewter_house_researcher` ; Dresseurs `pewter_gym_liam`, `pewter_gym_brock` |
| Pierre | PNJ sans vision (on lui parle) ; scène écrite ; drapeau `brock_met` pour la reprise ; `start_message` faux (carte + intro), `end_message` vrai ; 1 300 ₽ ; SAC permis au joueur |
| Liam | réplique « vaincu » par la clé `defeated` du bloc `trainer` (J9 étendu) ; 200 ₽, `random` |
| Carte du Champion | dans le monde, avant la transition du combat ; nom en majuscules + titre, glissée, tenue puis sortie, toucher pour abréger, sans portrait ; données `card` du Dresseur |
| « BADGE ROCHE » | légende `WorldCaption` (comme « POKÉDEX ACTIVÉ »), tenue 2 s, vibration 40 ms, aucun toast |
| Grand moment « badge » | détails `{ badge, team: [{ species, level, nickname }] }` relevés **après** le bilan d'XP et l'évolution éventuelle ; K.O. compris ; textes « {badge} » / « Obtenu à {city} contre {leader}. » ; souvenir non affiché au J10 |
| Arrivée à Argenta | Grand moment « Arrivée à Argenta » / « Une nouvelle ville. » (comme Jadielle, Q-5) ; drapeau `pewter_arrived` par un déclencheur silencieux |
| Écran Dresseur | badge obtenu touchable, bulle « Badge Roche » / « Argenta — Pierre » ; emblème existant en ACCENT, pas d'image du badge au J10 |
| Espèces | Gravalanch, Grolem, Sablaireau ajoutés pour le Pokédex (comme Raichu) ; statistiques actuelles, apprentissages de Rouge/Bleu |
| Rencontres Route 2 nord | dossier §3, `rate` 25, rampe 15 → 20 |
| Boutique d'Argenta | Ball 200, Potion 300, Antidote 100 (prix des données), sans condition |
| Lumière | `golden_hour` (Argenta, Route 2 nord), `interior_warm` (intérieurs) ; forêt un peu plus sèche par `Shade` |
| Budget | ≤ 3 000 nœuds ; changement de carte ≤ 1,5 × Jadielle ; moyenne ≥ 58 fps, creux ≥ 50 ; mémoire mesurée avec les voisines |
| Réactions au badge | enfant, jeune Dresseuse, guide, Montagnard (variantes `if: [badge_boulder]`) |

---

## 6. Premières tâches à lancer maintenant

1. **Créer `jalon-10` depuis `main`** (après la validation de ce plan, Q-1), dans une copie dédiée.
2. **T1 (architecte)** : kit d'assets de la série 12, grilles corrigées, grille de l'Arène, `plan_check_argenta.py` → puis **T2 (constructeur-monde, Mac, Codex)** et la validation de la planche par Kevin (10.0).
3. **En parallèle, sans conflit** : **T3** (capacités choisies, architecte), **T4** (Grand moment « badge » et objectifs, architecte), **T5** (carte du Champion, ui-mobile), **T7** (lot de textes, architecte) ; puis **T6** (écran Dresseur, ui-mobile).
4. **Au moment de la fusion du J9 dans `main`** : T8 (alignement, données), T10 (intégration des images validées).
