# Jalon 16 — Le S.S. Anne et le Badge Foudre

> **Plan technique, écrit le 2026-10-15, VALIDÉ par Kevin sur le principe le même jour.** Textes
> validés (dossier 19 §0.5). Reste : vues générales (Mac de Kevin, indisponible pour l'instant) et
> annexe A (descriptions de capacités et d'objets).

> Objectif jouable sur le téléphone : **le S.S. Anne et Major Bob**. Depuis le quai de Carmin
> (J15), la passerelle contrôle le **Passe Bateau** et ouvre un navire de **9 cartes** : pont
> principal, couloir et cabine du capitaine, restaurant, ponts inférieur et extérieur, trois
> cabines. On y trouve 10 Dresseurs, tous évitables, des objets visibles et cachés, et le **rival
> n° 4**, obligatoire, dans le couloir. Le **capitaine malade** remet la **CS01 Coupe**. Après la
> CS01, quitter le navire demande une confirmation **PARTIR / PAS ENCORE**. Le départ est
> définitif et **sauvegardé immédiatement**. À terre, Coupe (avec le Badge Cascade et un Pokémon
> compatible) tranche **pour toujours** l'arbuste de l'Arène. Dedans : le puzzle Rouge/Bleu strict
> des deux interrupteurs, Major Bob, le **Badge Foudre** et la **CT24 Tonnerre**.
>
> Mécaniques nouvelles :
> - les **CS** (CS01 rangée avec les CT, utilisable dans le monde sans emplacement, apprise comme
>   une CT réutilisable) ;
> - **les capacités de terrain** (règle `FieldMoves`, variantes de dialogue selon l'équipe, étape
>   de scène `field_move`) ;
> - l'**écriture immédiate** depuis une scène (étape `save`) ;
> - le **puzzle des interrupteurs** (état temporaire, tirage, remise à zéro) ;
> - un décor animé par une scène (étape `animate`).
>
> **Format de sauvegarde inchangé** : celui du J15 (v7), preuve au §2.12.

**Pré-requis.** Dossier 19 (`docs/design/dossier-19-ss-anne-major-bob.md`) : décisions G-1 à
G-10, V3 consolidée, §0 de relecture (R-1 à R-17, **prévaut**). **Grilles validées** par Kevin le
2026-10-15 (`tools/plans/ss_anne_*.txt`, `carmin_arene.txt`, contrôle
`tools/art/plan_check_ss_anne.py` vert, planche `reference/ss-anne-plans-v1.png`). **En attente** :
les textes (dossier §15, 39 répliques, recommandations de Claude du 2026-10-15) et les trois vues
générales (prompts `CONCEPT_SS_ANNE_PONT_PRINCIPAL_r1`, `CONCEPT_SS_ANNE_PONT_EXTERIEUR_r1`,
`CONCEPT_ARENE_CARMIN_r1`).

**Règle de parallélisme (Kevin)** : une session = un jalon ; J15 avance en même temps. Tout ce qui
n'exige pas Carmin part **maintenant**. Ce qui l'exige (quai, arbuste, navire amarré, Centre)
attend la **fusion du J15**, avec un repli sur une carte de QA. **C-7** : un seul jalon à la fois
dans le moteur de combat et la sauvegarde. Le J16 n'ajoute au combat que des **données** (Coupe,
Tonnerre). Il n'ajoute à la sauvegarde **aucun champ** : l'étape `save` réutilise l'écriture du
réveil. Il peut donc avancer en parallèle du J15.

Code lu, jamais modifié : `main` à **`2bd6bbf7`** (J11 à J14 fusionnés, sauvegarde **v6**). Les
références `fichier:ligne` citent ce commit.

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin

| Besoin du J16 | Existe | Où |
|---|---|---|
| CT réutilisable, onglet CT du Sac, apprentissage, oubli | **oui** (J11) | `ItemData.Category.TM` (`item_data.gd:20`), `tm_number`, `teaches`, `is_permanent()` (l.132) ; `TmTeach.check/teach` (`tm_teach.gd`) ; `Boot._on_tm_learn_requested` (`boot.gd:1342`) ; onglet « CT » (`bag_screen.gd:54`) |
| Compatibilités CT | **oui**, 1 à 50 | `PokemonData.load_tm_file`, `can_learn_tm` (`pokemon_data.gd:94-145`), numéros bornés l.115 ; fichier généré `tools/gen_tm_compatibility.py` ; `"24": "thunderbolt"` déjà listé |
| Remise d'une CT par un Champion | **oui** | `cerulean_gym.json` : `give tm11`, `set tm11_received` ; rattrapage `cerulean_gym_misty_tm_late` |
| Scène d'Arène complète | **oui** (J10, J13) | carte de Champion, `battle win:[badge_*]`, étape `badge`, défaite → `wake_up` |
| Rival obligatoire et rejouable | **oui** (J13) | `route_24.json` (`lost_once`, `retried`, `won`) ; `rival.json` (`can_lose false`, `"moment": "win"`, `team_by_starter`) ; `RivalMoment` |
| Choix → scène | **oui** (J12) | `DialogueChoice.confirm_cutscene` (`dialogue_choice.gd:41`), exemple `mt_moon.json:109-124` ; annuler ne fait rien |
| Obstacle retiré par drapeau | **oui** (J14) | PNJ « objet » `unless:[…]` + scène `despawn` + `set` (`cerulean_city.json:36-49`, `cerulean_rocket.json:48-63`) |
| Décor qui suit un drapeau | **oui** (J14) | `FlagGate` (`flag_gate.gd`), visuel seulement |
| Objets visibles, cachés | **oui** | PNJ `object/poke_ball_ground` + `got_<id>` ; `InteractPoint.unless_flags` (J12) |
| Hasard sauvegardé et scriptable | **oui** | `GameRng` (`game_state.gd:55`) ; `tests/helpers/scripted_rng.gd` |
| Écriture immédiate | **une seule** | `_on_woke_up_after_defeat` → `_write_save("réveil")` (`boot.gd:1316`) |
| Corde Sortie hors grotte | **refusée** | `FieldItemRules.check` → `NOT_HERE` (`field_item_rules.gd:19-31`) |
| Compagnon (sortie / rappel animés) | **oui** (J11) | `Companion.appear/withdraw` (`companion.gd:223, 234`) ; `CompanionController.get_chosen()` |
| Intérieurs peints | **oui** | `tools/build_painted_interiors.gd` (pièces en dictionnaires, `--rooms=`) ; `data/world/interiors.json` |
| Sonicboom, Éclair, Cage-Éclair, paralysie | **oui** | `mt_moon.json` (`fixed_damage` 20), J11 |
| Abra, Kadabra, Machoc, Voltorbe, toutes les espèces des équipes | **oui** | `kanto*.json` (R-4) |

### 0.2 Écarts et trous

1. **Aucune CS.** La catégorie d'un objet est unique : il ne peut pas être à la fois `key` et
   `tm`. Les numéros sont bornés de 1 à 50 et uniques. **`tm01` est déjà pris**
   (Ultimapoing). → §2.1 : CS01 = `hm01`, catégorie `tm` avec une clé `hm`.
2. **Aucune capacité de terrain.** Les conditions des variantes de dialogue ne lisent que des
   drapeaux. → §2.2.
3. **Aucune étape d'écriture immédiate** dans les scènes. → §2.4 (`save`).
4. **Rien pour animer un grand décor** (le navire qui part). → §2.5 (`animate`).
5. **Rien pour un puzzle à état temporaire.** `InteractPoint` n'a ni `if_flags` ni lien vers une
   logique. → §2.6.
6. **`cut` et `thunderbolt` absents** des capacités ; Super Potion absente des objets. → §2.9.
7. **Aucun Centre au bord du navire** : la défaite ramène au **dernier Centre enregistré**, celui
   de Carmin quand le J15 l'aura posé.
8. **Personnages peints absents** : capitaine, Major Bob, marin, gentleman, rockeur, serveur,
   hôtesse. Aucun sprite d'arbuste, de poubelle ni de barrière électrique. → §1.4.

### 0.3 Ce que le J16 attend du J15 (et repli)

**Livré par le J15 (message de sa session, 2026-10-15 ; `jalon-15.md` §9, dossier 18 §17)** — le
J16 **adopte ses noms** :
- navire = 3 objets `bldg_ss_anne_proue_01`, `_milieu_01`, `_poupe_01`, absents si
  `ss_anne_departed` ;
- passerelle (31..32, 27), marin (31, 26) au texte provisoire T-26, que le J16 remplace ;
- arbuste `prop_jeune_arbre_arene_01` (49..50, 10), **`FlagGate.blocking_cells`**, retiré par
  **`cut_vermilion_gym_bush`** (le `cut_vermilion_gym_bush` du J16 est abandonné) ;
- Centre de Carmin = point de retour, Stockage ;
- quai dans `vermilion_city`, **pas de `vermilion_dock`** ;
- sauvegarde **v7** au J15 (`GameState.daycare`) : le J16 écrit la v7 telle quelle (§2.12) ;
- numérotation : dossier 18 et série d'art 17 au J15 → **série 18** pour le J16.

**Réponse du J15 (2026-10-15, transmise par Kevin ; `vermilion_city.tscn` dans `main` à
`440f9b17`, outil `tools/build_vermilion_city.gd`)** — le J16 **reprend ces noms**, le J15 ne
change rien (case = (x/96, y/96 − 1), nœuds posés aux pieds) :

| Besoin du J16 | Dans `vermilion_city` | Usage J16 |
|---|---|---|
| Arbuste à couper | `Entities/GymTree` : `FlagGate unless:[cut_vermilion_gym_bush]`, `blocking_cells` (49, 10), (50, 10), enfant `YoungTree` | cible du `field_move` : **`Entities/GymTree`** (nœud de carte : pas de despawn, le `set` suivant le retire) |
| Point d'examen de l'arbuste | `Interactables/GymTreeExamine` sur (49..50, 10), `size (2, 1)`, `facing` ↑, `unless_flags [cut_vermilion_gym_bush]`, dialogue `vermilion_gym_tree` (T-29) | **pas de second point** : au T15, le builder du J15 met `dialogue_id = cut_tree` (variante `cut:no_hm` = texte de T-29 ou ARB-00, à aligner) ; le défaut `vermilion_gym_bush` en (49..50, 11) est abandonné |
| Porte de l'Arène | `Warps/DoorGymW|E`, « À venir », arrivée `from_gym` | T14 : `target_map` de l'Arène, `coming_soon` retiré |
| Embarquement | `Warps/BoardingW|E` sur (31..32, 28), ↓, `coming_soon "S.S. Anne"`, `target_spawn from_ss_anne_w|e` | T11 : `target_map` = pont principal, `coming_soon` retiré ; **créer `from_ss_anne_w|e` sur la carte du navire** |
| Arrivée en descendant du navire | `Spawns/from_ss_anne_w` (31, 27), `from_ss_anne_e` (32, 27) | sortie du navire avant le départ → **`from_ss_anne_w|e`** (le défaut `from_ss_anne` (31, 28) est abandonné) ; après le départ : `dock`, voir plus bas |
| Navire | `Entities/SsAnne` : `FlagGate unless:[ss_anne_departed]`, enfants `SsAnneProue01`, `SsAnneMilieu01`, `SsAnnePoupe01` | cible de l'`animate` : **`Entities/SsAnne`** (réaffiché par l'étape, §2.5) |
| Passerelle peinte | `GroundDecals/Gangway` : `FlagGate unless:[ss_anne_departed]` | rien : elle disparaît avec le drapeau (non animée) |

**Après le départ (second échange avec le J15, 2026-10-15)** : (31..32, 27) et (31..32, 28) sont
au-dessus de la mer (passerelle `g`, accès `E` dans l'emprise du navire) ; une fois `SsAnne` et
`Gangway` cachés, on n'y voit que l'eau. Donc **aucun objet « passerelle fermée »** :
- le **marin** revient en (31, 26) avec `if:[ss_anne_departed]` (ou sa clé `moved`), réplique
  DEP-03 / TXT-07 « Le S.S. Anne a pris le large. » ; la bitte reste en (32, 26) : les rangées
  27..28 redeviennent inaccessibles ;
- la scène du départ replace le joueur sur **`Spawns/dock` (31, 24)**, sur le quai (et non sur
  `from_ss_anne_w`, qui serait sur l'eau) ;
- **garde-fou** : une `FlagGate` sans image `if:[ss_anne_departed]` avec `blocking_cells` (31..32,
  27..28), posée **par le J16** au T15 dans `build_vermilion_city.gd` (le J15 ne la pose pas : un
  seul des deux jalons).

Tableau d'origine (avant la livraison du J15) :

| Attente (contrat G-1 corrigé) | Utilisée par | Repli tant qu'elle manque |
|---|---|---|
| Carte de Carmin avec quai, **cases de la passerelle** et spawn de retour `from_ss_anne` | T11, T15 | sortie du navire en `coming_soon = "Carmin"` ; carte de QA `qa_dock_j16` (quai minimal) pour 16D |
| Navire amarré **sous `FlagGate unless:[ss_anne_departed]`** et warp de la passerelle **gardé par un PNJ objet `if:[ss_anne_departed]`** | T15 | idem |
| Arbuste devant la porte de l'Arène, PNJ objet `object/cut_tree`, id `vermilion_gym_bush` | T14 | arbuste posé sur `qa_dock_j16` ; l'Arène atteinte par un départ de débogage |
| Centre de Carmin dans `rest_points.json` | T12, T13 | la défaite ramène au dernier Centre enregistré (Azuria) |
| `got_ss_ticket` (J14, livré) ; `badge_cascade` (J13, livré) | T12, T6 | — |

Les identifiants du J15 sont **à confirmer** à sa fusion (T19). Si le J15 en choisit d'autres, le
J16 s'y adapte : ce sont trois lignes de données.

---

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §14)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **16.0** | vues générales, kit d'art, données, CS dans le moteur d'objets, règles pures (`FieldMoves`, `SwitchPuzzle`) | captures Mac et planche de contact |
| **16A** | les 9 cartes du navire, embarquement, PNJ, objets | **S21** |
| **16B** | 10 Dresseurs, rival n° 4 (défaite, reprise, Grand moment) | **S21** (peut se coupler à 16A) |
| **16C** | capitaine, CS01, Coupe dans le monde et en combat, arbuste | **S21** |
| **16D** | confirmation et départ, écriture immédiate, arrêt brutal | **S21 seul** (système risqué) |
| **16E** | Arène : puzzle, Dresseurs, Major Bob, Badge Foudre, CT24 | **S21** |
| **16F** | raccord au Carmin du J15, non-régression, vraie partie de Kevin | **S21** + fusion |

Jamais trois systèmes à la fois : 16C = CS + capacité de terrain ; 16D = un système ; 16E =
puzzle + contenu d'Arène sur un modèle existant.

### 1.2 « Maintenant » ou « après la fusion du J15 »

**Branche d'intégration `jalon-16` depuis `main`**, une branche par tâche (`j16-t<n>-<sujet>`).
`main` est refusionnée à chaque avancée utile. **`jalon-16` n'entre dans `main` qu'après le J15.**

**Fichiers partagés avec le J15 et parade** :

| Fichier | Parade |
|---|---|
| `cutscene_step.gd`, `cutscene_library.gd`, `cutscene_director.gd` | `FIELD_MOVE`, `SAVE`, `ANIMATE` **en fin d'enum** ; « garder les deux » |
| `item_data.gd`, `item_library.gd`, `bag_query.gd`, `bag_screen.gd` | clé `hm` sur une ligne à part ; libellé « CT/CS » de l'onglet en une ligne |
| `dialogue_library.gd`, `dialogue_variant.gd`, `dialogue_runner.gd` | clé de variante `field` sur une ligne à part ; source injectée comme `rng_source` |
| `pokemon_data.gd`, `tm_compatibility.json` | section `hms` à part ; le fichier est **généré** : en cas de conflit, relancer le générateur |
| `boot.gd` | 4 points d'accroche courts (CS dans le Sac, écriture `save`, routage du puzzle, `field_move`) |
| `objectives.json`, `zones.json`, `interiors.json`, `moments.json`, `rest_points.json` | ajouts **en tête** (objectifs) ou **en fin** ; « garder les deux côtés » |
| espèces, capacités, objets, Dresseurs | **fichiers nouveaux** : `moves/moves_j16.json`, `items/items_j16.json`, `trainers/ss_anne.json`, `trainers/vermilion_gym.json` ; rival n° 4 ajouté **en fin** de `rival.json` |
| listes de cartes des tests (`test_map_links`, `test_dialogue_data`, `test_cutscene_data`, `test_zone_library`, `test_map_catalog`, `test_painted_ground`, `test_map_light_profiles`) | entrées **en fin**, alignées à chaque fusion (T19) |

| Tâche | Agent | Quand | Dépendance réelle |
|---|---|---|---|
| T0 Plan | architecte | fait | — |
| T1 Kit d'art (série suivante libre) | architecte | **maintenant** | vues générales validées |
| T2 Génération Codex | constructeur-monde (Mac) | **maintenant**, après T1 | — |
| T3 Textes | Kevin | **maintenant** | — |
| T4 Données 16.0 | architecte | **maintenant** | textes : lot provisoire, remplacé après T3 |
| T5 CS dans le moteur d'objets | architecte | **maintenant** | — |
| T6 `FieldMoves` + variantes `field` | architecte | **maintenant** | — |
| T7 Étape `field_move` + arbuste | architecte | **maintenant**, après T6 | — |
| T8 Étapes `save` et `animate` | architecte | **maintenant** | — |
| T9 `SwitchPuzzle` + routage + barrière | architecte | **maintenant** | — |
| T10 Intégration de l'art (Mac) | constructeur-monde | après T2 | — |
| T11 Les 9 cartes du navire | constructeur-monde | **maintenant**, après T10 (tuiles provisoires avant) | — |
| T12 Vie du navire (PNJ, Dresseurs, objets) | constructeur-monde | après T4, T11 | — |
| T13 Rival n° 4 et capitaine | constructeur-monde | après T4, T5, T11 | — |
| T14 Arène de Carmin et Major Bob | constructeur-monde | après T4, T9, T10 | arbuste réel : J15 |
| T15 Départ du navire | constructeur-monde | après T8, T11 ; quai réel après la **fusion du J15** | repli `qa_dock_j16` |
| T16 Carte de QA et départs de débogage | constructeur-monde | **maintenant**, après T7, T8 | — |
| T17 Sessions 16A–16E | qa-mobile → Kevin | selon le §1.1 | — |
| T18 Équilibrage (rival n° 4, Major Bob) | architecte | après T12–T14 | — |
| T19 Alignements | architecte | à chaque fusion de `main` (J15) | — |
| T20 Fin et clôture | constructeur-monde, qa-mobile, architecte | après la fusion du J15 | — |

**Parallélisme maintenant** : T1 → T2 → T10 → T11 → (T12 ∥ T13 ∥ T14) ; en même temps T4, T5,
T6 → T7, T8, T9, T16.

### 1.3 Grilles (validées)

Elles font foi sur les coordonnées du dossier (§0 R-14). `build_painted_interiors.gd` lit déjà
`plan` et `walkable`. Les caractères praticables sont dans la ligne `PRATICABLES` de chaque grille.
Les portes `D` et escaliers `S` sont des **warps terminaux**. Le déclencheur `T` du couloir est
une scène. La barrière `B` est praticable et **bloquée par 3 PNJ objets** tant que
`vermilion_gym_puzzle_solved` n'est pas levé. Toute retouche de grille relance
`plan_check_ss_anne.py` et `plan_ss_anne.py`.

### 1.4 Kit d'assets (série suivante libre au moment du T1, défaut : 18)

- **A — réutilisés** : `lass` (Fillette Léna), `scout` (Oscar, ex-Basile : T19), `swimmer`, `traveler` et
  `naturalist` (passagers), `clerk` (hôtesse), `gym_guide`, `rival`, objets `poke_ball_ground`.
- **B — variations** : marin = `swimmer` habillé (tenue de matelot) ; serveur = `clerk` en veste.
- **C — nouveaux** :
  - personnages : capitaine, Major Bob, gentleman, rockeur, marin (si B ne suffit pas) ;
  - coques d'intérieur : pont principal, couloir, cabine du capitaine, restaurant, pont inférieur,
    une cabine déclinée en A, B, C ;
  - pont extérieur (extérieur, mer animée par le shader existant) ;
  - Arène électrique ;
  - objets : arbuste coupable, poubelle, armoire électrique, barrière électrique (3 états :
    active, coupée, absente), navire extérieur (amarré, pour Carmin) ;
  - effet générique de Coupe (trait de lame) ;
  - décors de combat (CB.3) : intérieur du navire, pont extérieur, Arène électrique.
- **D — abandonnés** : cuisine jouable, oiseaux marins (souhaitable seulement, dossier §12).

**Mise à jour du T1 (2026-10-16) : série 18** (numéro provisoire, revérifié au push ; 17 = J15,
19 = J17, 20 = J19). Fiche `docs/design/fiches-assets/serie-18-ss-anne.md`, outil
`tools/art/serie18.py`, prompts `tools/art/prompts/serie18/`, planche `build/art/J16_KIT_v1.png`.
**30 images nouvelles** (17 en vague 1, 13 en vague 2) + 3 conditionnelles :

| Famille | Retenu au T1 | Écart au plan ci-dessus |
|---|---|---|
| A réutilisés | navire amarré (3 tranches), passerelle, jeune arbre, caisses du port (série 17) ; `int_plante` ; `rival`, `lass` (Léna), `scout` (Basile), `traveler` (passager_1), `clerk` (**serveur**), `gym_guide`, **`sailor`** (marin, matelot, 6 Marins) | `swimmer`, `naturalist` non utilisés ; `clerk` = serveur, pas l'hôtesse |
| B variations | pont de teck = planches du quai éclaircies ; mer = `ground_eau_01` assombrie ; cabines A/B/C = une coque ; couchette = lit de cabine | marin : `sailor` livré par le J15 (plus de `swimmer` habillé) ; serveur sans veste neuve |
| C personnages | capitaine (+ attente + **poses malade**), Major Bob, gentleman, rockeur, **hôtesse**, **passagère** | hôtesse et passagère **nouvelles** (à valider) ; cuisinier en **conditionnel** (aucune case dans la grille) |
| C coques | pont principal et Arène (vague 1, recalées sur les vues), couloir (bande), cabine du capitaine, restaurant (passe-plat), pont inférieur (escalier), cabine A/B/C (vague 2) | escaliers peints dans les coques |
| C pont extérieur | planche des bastingages (N ×2, S + flanc, E, angles, chaises longues, bouée), superstructure ouest | — |
| C objets | planche A (banquette, comptoir d'accueil, table, comptoir de cuisine, lit, armoire), planche B (table sous hublot, bureau, lavabo 1 case, table à cartes, caisses 2 × 2 et 3 × 2), planche de l'Arène (**poubelle unique ×15**, armoires A/B, barrière active / coupée) | barrière « absente » = sans image ; navire « parti » = sans image (nœud caché) |
| C effet, Sac | Coupe : 4 images ; icônes Anti-Para et Réveil | icônes ajoutées (objets trouvés à bord) |
| C combat (CB.3) | `ss_anne_salon` (tout l'intérieur), `ss_anne_pont`, `vermilion_gym_salle` | — |
| conditionnels | `WORLD_GROUND_PONT_TECK_01`, `PNJ_CUISINIER` | — |

---

## 2. Conception technique

### 2.1 La CS01 (T5)

- **Objet** `hm01` dans `items_j16.json` : catégorie **`tm`**, clé nouvelle **`"hm": 1`** (exclusive
  de `"tm"`), `teaches: "cut"`, sans prix. `is_permanent()` est déjà vrai pour la catégorie `tm`.
  Elle n'est donc ni consommée ni vendable, et aucun nouveau type n'est nécessaire.
- **ItemLibrary** : `hm` borné de 1 à 5, unique ; `tm` et `hm` exclusifs. `ItemData.hm_number`.
- **Affichage** : nom « CS01 — Coupe » dans les données. L'onglet reste la catégorie `tm`, avec le
  libellé **« CT/CS »** dès qu'une CS est dans le Sac (défaut). Les CS sont triées **après** les CT.
- **Compatibilités** : `tools/gen_tm_compatibility.py` lit aussi la CS01 de PokeAPI (machines ≥ 101
  du groupe `red-blue`). Il écrit une section **`hms`** (`{"01": "cut"}`) et, par espèce, une liste
  `hm` à côté de la liste des CT. `PokemonData.can_learn_hm(species, n)` et `hm_move(n)`.
- **Apprendre** : `TmTeach.check/teach` acceptent la CS (même parcours, même oubli ; Coupe
  s'oublie **normalement**, G-2).
- **Test** : les 5 espèces garanties (Dardargnan, Sabelette, Paras, Chétiflor, Mystherbe) et les
  starters Bulbizarre et Salamèche sont compatibles ; Carapuce et Pikachu ne le sont pas (R-4,
  G-6).

### 2.2 Capacités de terrain : `FieldMoves` (T6)

Logique pure, sans scène :

```
FieldMoves.cut_state(party, bag, flags) -> {state, pokemon_index}
  state ∈ NO_HM | NO_BADGE | NO_POKEMON | READY
```

- `NO_HM` : pas de `hm01` dans le Sac.
- `NO_BADGE` : `badge_cascade` absent. **Prime sur `NO_POKEMON`** (dossier §7, ARB-01).
- `NO_POKEMON` : aucun Pokémon de l'équipe, non K.O. **ou** K.O., n'est compatible (`can_learn_hm`)
  ou ne connaît déjà Coupe. Un Pokémon K.O. **peut** couper : défaut, comme les CS de Rouge/Bleu.
- `READY` : le Pokémon choisi est le **compagnon** s'il est compatible, sinon le **premier
  compatible dans l'ordre de l'équipe** (ordre stable, dossier §7).

**Variantes de dialogue** : clé nouvelle **`"field": "cut:<état>"`** dans `_VARIANT_KEYS`, lue par
`DialogueRunner.field_source` (injectée comme `rng_source`). **`{pokemon}`** dans un texte =
surnom ou nom de l'espèce choisie. L'arbuste est un PNJ objet `object/cut_tree`, `verb: examine`,
`unless: [cut_<id>]`. Son dialogue `cut_tree` porte 4 variantes (ARB-00 à ARB-03). `READY` porte le
choix **COUPER / LAISSER** avec `confirm_cutscene: "cut_tree_<id>"`.

### 2.3 Étape `field_move` (T7)

`{"field_move": "cut", "target": "<id du PNJ arbuste>"}`, **2 s au plus** :

1. le Pokémon choisi apparaît sur la case libre devant le joueur, avec l'éclat de Ball
   (`Companion.appear`) ; si c'est le compagnon déjà sorti, il s'y déplace ;
2. effet de coupe (trait de lame peint, vibration légère) ;
3. `despawn` de l'arbuste ;
4. le Pokémon rentre (`withdraw`), sauf le compagnon, qui reste dehors.

La scène `cut_tree_<id>` enchaîne ensuite le dialogue ARB-04 (« {pokemon} utilise Coupe ! ») et
`set: [cut_<id>]`. Avec « Réduire les animations », il n'y a ni apparition ni trait : l'arbuste
disparaît en fondu (0,3 s). L'arbuste coupé ne repousse jamais : la clé `unless` lit le drapeau
(G-4).

### 2.4 Étape `save` : écriture immédiate (T8)

`{"save": "<raison>"}` appelle le chemin du réveil : `_write_save(raison)` si `_can_write()` et
qu'aucune transition n'est en cours, sinon `request_autosave`. Pendant une scène, `_can_write()`
est faux par construction. L'étape demande donc à Boot une **écriture forcée** : un indicateur
`_force_write_once` lève la seule garde « scène en cours ». Les gardes « combat », « transition » et
« dialogue ouvert » restent. Elle ne sert **qu'au départ du navire** (T15) : un test empêche tout
autre usage dans les données (liste blanche).

**Ordre de la scène de départ** (`ss_anne_departure`) :

1. `change_map` vers le quai de Carmin, spawn `dock` (31, 24) sur le quai (§0.3 ; le joueur est déjà à terre) ;
2. `set: [ss_anne_departed]` ;
3. `save: "départ du S.S. Anne"` ;
4. le spectacle (`animate`, légende DEP-02, 10 s au plus) ;
5. fin de scène.

**Arrêt brutal** :
- avant 3 : la dernière sauvegarde stable est **à bord, avant la confirmation** ; le joueur
  recommence le choix ;
- après 3 : la sauvegarde est **au quai, navire parti** ; le spectacle n'est pas rejoué
  (dossier §13).

Aucun état mixte n'est possible : le drapeau et la position sont écrits ensemble, après le
repositionnement. **Test** : écriture interceptée à chaque étape, puis relecture.

### 2.5 Étape `animate` (T8)

`{"animate": "<nœud de la carte>", "offset": [dx, dy], "duration": s, "fade": bool}` est générique.
Elle déplace un nœud nommé de la carte courante en interpolation, sans toucher à la grille, puis
peut le masquer. Utilisée pour le navire qui s'éloigne (amarres, recul, sortie de l'écran). La
`FlagGate unless:[ss_anne_departed]` le cache ensuite pour toujours. « Réduire les animations » :
fondu de 0,5 s sur place.

### 2.6 Puzzle des interrupteurs : `SwitchPuzzle` (T9)

Logique pure, état **jamais sauvegardé** (dossier §11) :

```
SwitchPuzzle.new(cols = 5, rows = 3, rng: GameRng)
  start()                    # à l'entrée dans la carte, si non résolu : tire `first`
  search(index) -> NOTHING | FIRST_FOUND | SOLVED | RESET
```

- `first` est tiré parmi les 15 positions (toutes ont un voisin orthogonal). Au premier succès,
  `second` est tiré parmi les **voisins orthogonaux** de `first` (le tirage de la V3, gardé).
- **Après le premier** :
  - le second → `SOLVED` ;
  - toute autre poubelle, y compris `first` → `RESET`, puis nouveau tirage de `first`.
- **Avant le premier** :
  - une poubelle quelconque → `NOTHING` ;
  - `first` → `FIRST_FOUND`.
- **Quitter la carte** efface tout ; on retire au retour.

**Branchement** :
- les 15 `InteractPoint` portent un attribut nouveau **`puzzle_slot`** (1..15, celui de la grille) ;
- Boot route l'interaction d'un `puzzle_slot` vers le puzzle de la carte, puis lance le dialogue du
  résultat (GYM-01 à GYM-04) ;
- `SOLVED` lance la scène `vermilion_gym_barrier_open` : `despawn` des 3 PNJ objets
  `object/electric_barrier`, puis `set: [vermilion_gym_puzzle_solved]`.

Le tirage passe par `GameState.rng` : reproductible en test (`ScriptedRng`). Recharger une partie
retire, car le premier interrupteur n'est jamais écrit. Un test parcourt les 15 premiers possibles
et tous leurs voisins.

### 2.7 Rival n° 4 (T13)

Le modèle exact est celui de `route_24_rival` :
- variantes `intro` / `resume` / `resume_again`, drapeaux `rival_ss_anne_lost_once`,
  `rival_ss_anne_retried`, `rival_ss_anne_won` ;
- **déclencheur** sur les 3 cases de la colonne 7 du couloir, `unless:[rival_ss_anne_won]` ;
- après la victoire : `move` vers la sortie, puis `despawn`.

**Données** : `rival_ss_anne` en fin de `rival.json` :
- IA `smart`, `can_lose false`, `"moment": "win"`, `prize_per_level 35`, `start_message true` ;
- `team_by_starter` : Roucoups 19, Rattatac 16, Kadabra 18 (**Choc Mental, Rafale Psy**, R-12),
  starter évolué 20 avec l'avantage de type ;
- capacités choisies à la main pour tous (dossier §5, sans mécanique interdite).

R-7 : le drapeau de victoire suit le modèle du J13 (`rival_<lieu>_won`) et non `beaten_`.
`ss_rival4_*` (V3) devient `rival_ss_anne_*`.

### 2.8 Capitaine (T13)

Scène `ss_anne_captain`, `unless:[got_hm01]` :

1. `face` ;
2. CAP-01 ;
3. narration « Tu lui frottes doucement le dos. » (si le lot de textes la retient) ;
4. CAP-02 ;
5. CAP-03 ;
6. `give hm01` ;
7. `set: [got_hm01]`.

Il n'y a pas d'autosave pendant la scène : un arrêt brutal fait rejouer la scène, et l'objet n'est
jamais doublé (le drapeau tombe à la dernière étape). Ensuite, le dialogue simple CAP-04.
**Rattrapage** (dossier §6) : `hm01` dans le Sac sans `got_hm01` → le drapeau est levé au
chargement ; `got_hm01` sans `hm01` → l'objet est rendu une fois. Les deux sont journalisés, dans
`GameState.repair_flags` (défaut : un petit hook à part, testé).

### 2.9 Données (T4)

- **Capacités** `moves_j16.json` :
  - `cut` : Coupe, Normal, 50, 95 %, 30 PP, physique ;
  - `thunderbolt` : Tonnerre, Électrik, 90, 100 %, 15 PP, spéciale, `status paralysis 10 %` ;
  - descriptions à valider (annexe A).
- **Objets** `items_j16.json` :
  - `hm01` (§2.1) ;
  - `tm24` (Tonnerre, catégorie `tm`, `"tm": 24`) ;
  - `super_potion` (Super Potion, `heal`, 50 PV, 700 ₽, R-6 ; vendue nulle part au J16).
- **Dresseurs** :
  - `trainers/ss_anne.json` : 10 Dresseurs du dossier §4, avec les noms de R-10, équipes et
    capacités, argent de la V3 recalé sur `prize_per_level` au T18 ;
  - `trainers/vermilion_gym.json` : Louis, Axel, Marc ; Major Bob (`card` « MAJOR BOB » /
    « Champion d'Arène de Carmin », IA `smart`, `can_lose false`, `switch true` (Kevin, R-19), capacités du §9,
    argent par défaut 2 400 ₽ comme la progression Pierre 1 300 → Ondine 2 100).
- **Dialogues** : `ss_anne.json`, `vermilion_gym.json`, `cut_tree.json`.
- **Scènes** : `ss_anne.json`, `vermilion_gym.json`, `cut_tree.json`.
- **PNJ** : `ss_anne_*.json`, `vermilion_gym.json`.
- **Objectifs** (R-9, en **tête**, minuscule et point), du plus avancé au moins avancé :
  1. `badge_thunder` → laissé au J17 (aucune entrée J16) ;
  2. `vermilion_gym_puzzle_solved` → « affronter Major Bob. » ;
  3. `cut_vermilion_gym_bush` → « ouvrir le passage vers Major Bob. » ;
  4. `got_hm01` + `badge_cascade` → « rejoindre l'Arène de Carmin. » ;
  5. `got_hm01` → « obtenir le Badge Cascade. » ;
  6. `rival_ss_anne_won` → « aider le capitaine. » ;
  7. `got_ss_ticket` → existant (« monter à bord… », à aligner).
- **Zones** :
  - `ss_anne` « S.S. Anne » (`kind` intérieur, les 9 cartes) ;
  - `vermilion_gym` rattachée à `vermilion_city` (J15).
- **Grands moments** : `rival_battle` (existant) ; badge générique (existant).

### 2.10 Cartes (T11, T14)

- Les 9 pièces du navire et l'Arène sont déclarées dans `build_painted_interiors.gd`, groupes
  **`SS_ANNE`** et **`CARMIN`**, options `--ss-anne`, `--carmin`. Elles sont ajoutées à
  `interiors.json`.
- **Le pont extérieur** est une carte peinte d'extérieur (mer par le shader existant). Il n'est pas
  intérieur : le compagnon peut y sortir (défaut).
- **Warps** : ceux des grilles. La sortie du pont principal mène au quai de Carmin du J15 ; repli
  `coming_soon = "Carmin"`, puis `qa_dock_j16`.
- **Après le départ**, la passerelle est gardée par un PNJ objet `object/gangway_closed`,
  `if:[ss_anne_departed]`. C'est le modèle du barrage du J14, posé sur la carte du J15 au T15.

### 2.11 Embarquement et sortie (T12, T15)

- **Embarquement** : sur le quai, le marin de la passerelle demande `got_ss_ticket`. Sans lui :
  TXT-02 et le joueur recule d'un pas.
- **Sortie, avant `got_hm01`** : libre, TXT-03 au premier passage (défaut : une fois).
- **Sortie, après `got_hm01`** : la case de sortie lance un dialogue de choix, DEP-01 et
  PARTIR / PAS ENCORE :
  - PARTIR → `confirm_cutscene: ss_anne_departure` ;
  - PAS ENCORE → le joueur reste à bord, un pas en arrière.
- **Contrôle** : `got_hm01` implique que le rival est battu (le capitaine est derrière lui).

### 2.12 Sauvegarde : **aucune version nouvelle** (preuve)

| Ce que le J16 mémorise | Champ existant | Forme |
|---|---|---|
| `rival_ss_anne_*`, `got_hm01`, `ss_anne_departed`, `cut_vermilion_gym_bush`, `vermilion_gym_puzzle_solved`, `surge_met`, `badge_thunder`, `tm24_received`, `beaten_ss_anne_*`, `beaten_vermilion_gym_*`, `got_ss_anne_*` | `flags` | inchangée |
| CS01, CT24, Super Potions, Anti-Para | `bag` | inchangée |
| objets trouvés | `found_items` | inchangée |
| Grand moment rival, badge | `moments` | inchangée |
| Coupe apprise | `party`, `storage` | inchangée |
| premier interrupteur, second | **rien** (volatils) | — |

`hm` est une clé de **données d'objet**, pas de sauvegarde. Le J16 écrit la version du J15 (**v7**, `GameState.daycare`) sans rien y ajouter. **Garde** :
toute tâche qui voudrait un champ nouveau s'arrête et revient à l'architecte. Test `test_save_j16` :
partie à bord (rival perdu une fois, CS01 obtenue), puis au quai après le départ, puis dans l'Arène
(puzzle résolu, Bob non battu) → `to_dict` → JSON → `load_dict` → tout identique.

### 2.13 Budgets

- ≤ 3 000 nœuds par carte : la plus grande pièce fait 26 × 13 = 338 cases.
- Mémoire « carte + voisines » : le navire ne précharge que la pièce voisine par warp.
- fps : ≥ 58 en moyenne, creux ≥ 50 sur le pont extérieur (mer) ; départ du navire ≥ 55 ; combat
  ≥ 55.

### 2.14 Carte de QA et départs de débogage (T16)

- **Carte `qa_dock_j16`** (tuiles provisoires) : un quai avec passerelle vers `ss_anne_pont_principal`,
  le navire amarré (prop provisoire), un arbuste `qa_tree`, une porte vers `carmin_arene`. Elle sert
  de repli tant que le Carmin du J15 manque ; **retirée au T20**.
- **Départs** (`tools/debug_start/`) :
  - `ss_anne` (à bord, Passe Bateau, équipe N20–24) ;
  - `ss_anne_rival` (devant le couloir) ;
  - `ss_anne_captain` (rival battu) ;
  - `ss_anne_exit` (CS01, devant la sortie) ;
  - `cut_no_badge`, `cut_no_pokemon` (Carapuce + Pikachu), `cut_ready` ;
  - `vermilion_gym` (arbuste coupé), `vermilion_gym_solved`, `surge_weak` (pour perdre) ;
  - `thunder_after` (badge, CT24).

---

## 3. Tâches

Branche **`jalon-16`** depuis `main`, une branche par tâche ; jamais de fusion dans `main` avant
le J15. Chaque tâche : `tools/test.sh` vert, import propre, capture relue si visible,
`etat-projet.md` mis à jour dans le même commit.

#### T0 — architecte : plan (fait)

#### T1 — architecte : kit d'assets — **maintenant**, après les vues générales

Fiche `docs/design/fiches-assets/serie-<n>-ss-anne.md` (emprises d'après les grilles, ancrages,
jointes), `tools/art/serie<n>.py` (`--prompts`, `--refs`, `--commandes`, `--planche`, `--manifeste`),
prompts versionnés. Personnages du §1.4 C, coques, objets, effet, décors de combat.

**Fait le 2026-10-16** (branche `j16-t1-kit`) : série **18** (§1.4, « Mise à jour du T1 »), 33
prompts, planche de contrôle relue. Au T10 : `serie18.py --manifeste`, et la découpe `boite` du
couloir dans `preparer.pieces` (deux lignes).

#### T2 — constructeur-monde (Mac, Codex) : génération → planche de contact — après T1

#### T3 — Kevin : textes — **maintenant**

Dossier §15, 39 répliques, recommandations de Claude du 2026-10-15, annexe A (descriptions de
Coupe, Tonnerre, CS01, CT24, Super Potion ; zone S.S. Anne ; panneau de l'Arène).

#### T4 — architecte : données 16.0 — **maintenant**

§2.9 en entier, avec des textes provisoires marqués `draft` jusqu'au T3. Tests :
`test_ss_anne_data`, `test_vermilion_gym_data` (équipes, capacités existantes ou créées au J16
uniquement, aucune mécanique interdite, noms uniques parmi tous les Dresseurs).

#### T5 — architecte : CS dans le moteur d'objets — **maintenant**

§2.1. Tests : `test_hm_item` (bornes, exclusivité, permanence, non vendable), `test_hm_compat`
(générateur relancé, 7 compatibles, 2 incompatibles), `test_tm_teach_hm` (apprendre, oublier
Coupe), libellé « CT/CS ».

#### T6 — architecte : `FieldMoves` + variantes `field` + `{pokemon}` — **maintenant**

§2.2. Tests purs des 4 états (priorité de `NO_BADGE`, choix du compagnon, Pokémon K.O.,
stockage) et du dialogue `cut_tree` (4 variantes, choix, `{pokemon}`).

#### T7 — architecte : étape `field_move` + arbuste — **maintenant**, après T6

§2.3. Tests : directeur de scène (ordre des étapes, compagnon sorti ou non, réduction), PNJ absent
au rechargement.

#### T8 — architecte : étapes `save` et `animate` — **maintenant**

§2.4, §2.5. Tests : écriture forcée une seule fois, gardes « combat » et « transition » intactes,
liste blanche ; départ interrompu à chaque étape → relecture cohérente.

#### T9 — architecte : `SwitchPuzzle` + `puzzle_slot` + barrière — **maintenant**

§2.6. Tests exhaustifs (15 × voisins), `RESET` et nouveau tirage, sortie de carte, `SOLVED`
définitif.

#### T10 — constructeur-monde (Mac) : intégration de l'art — après T2

#### T11 — constructeur-monde : les 9 cartes du navire — **maintenant**, après T10 (provisoire avant)

§2.10, warps des grilles, éclairage intérieur, sortie en `coming_soon`.

**Fait (2026-10-16), décor provisoire** (branche `j16-t11-cartes`) : les 9 pièces
(`ss_anne_main_deck`, `_captain_corridor`, `_captain_room`, `_restaurant`, `_lower_deck`,
`_outer_deck`, `_cabin_a|b|c`) et `vermilion_gym`, déclarées dans `build_painted_interiors.gd`
(`--ss-anne`, `--j16` ; **pas `--carmin`**, déjà pris par les intérieurs du J15), relues sur leur
grille. Décor **provisoire** en polygones à plat lu sur la grille (`tools/j16_placeholder_decor.gd`,
clé `"placeholder"` ; textures répétées `assets/world/interiors/provisoire/`, outil
`tools/gen_j16_placeholder_textures.gd`) : **au T10, remplacer `"placeholder"` par `"shell"` +
`"props"` / `"furniture"`** sans toucher aux grilles ni aux passages. Barrière : objet provisoire
`object/electric_barrier` (`tools/build_provisional_objects_j16.gd`), remplacé sous le même
identifiant. Écarts au plan :
- **sortie du pont principal branchée sur la vraie Carmin** (`vermilion_city`,
  `from_ss_anne_w|e`) et non en `coming_soon` (Carmin existe depuis la fusion du J15) ; l'Arène
  ramène sur `from_gym`. Côté Carmin, rien n'est touché : `BoardingW|E` et `DoorGymW|E` restent « À
  venir » (T15, T14) ; arrivées à viser : `ss_anne_main_deck/from_ss_anne_w|e` (12..13, 10) et
  `vermilion_gym/entrance` (8, 12) ;
- arrivées `from_<pièce>` (pont principal : `from_cabin_a`, `from_cabin_c`, `from_corridor`,
  `from_restaurant`, `from_outer_deck`, `from_lower_deck` ; pont inférieur `from_cabin_b` ; couloir
  `from_captain_room`), `entrance` = case `entree` de la grille, une case **au-dessus** de la sortie
  `X` (PUSH ↓ depuis la case `X`) ; portes `D` en STEP_ON vers le mur, escaliers `S` en STEP_ON sans
  direction ;
- **puzzle branché sur la vraie Arène** (moteur du T9) : 15 `InteractPoint` (`puzzle
  vermilion_gym`, emplacement = `index` de la grille), entrée `vermilion_gym` de
  `switch_puzzles.json`, dialogues GYM-01 à GYM-04 (`data/dialogues/vermilion_gym.json`, textes
  validés), scène `vermilion_gym_barrier_open` (`data/cutscenes/vermilion_gym.json`), barrière = 3
  PNJ objets **sans dialogue** (`data/npcs/vermilion_gym.json` ; aucun texte validé pour l'examen) ;
  Major Bob, Dresseurs, guide, panneau : T14 ;
- **aucun PNJ ni déclencheur à bord** (Dresseurs, objets, marin : T12 ; rival et son déclencheur,
  capitaine : T13) ;
- zone `ss_anne` (« S.S. Anne », sous-titre validé « Le grand paquebot de Kanto », `place`) avec
  une **description provisoire** (`draft`, annexe A au T3) et un rectangle provisoire sur la Carte
  (`kanto_placeholder_areas.json`, sous Carmin) ; `vermilion_gym` rangée dans `vermilion_city`.
  Le pont principal est un intérieur : **le titre de zone ne s'affiche qu'au pont extérieur** (carte
  d'extérieur) — à revoir au T12 (embarquement) si le titre doit tomber dès la passerelle.
Tests : `test_ss_anne_maps` (grille ↔ carte, passages, raccords à Carmin par identifiants, vision
des 13 Dresseurs des grilles sur la vraie carte, 0 inévitable sur le pont principal, rival
incontournable, puzzle et barrière sur la vraie Arène, départs, nœuds) ; listes de `test_map_links`
(retours vers Carmin en attente du T14 / T15 ; sortie PUSH à un pas acceptée),
`test_dialogue_data`, `test_cutscene_data`, `test_zone_library`, `test_no_draft_in_data`
(brouillon `ss_anne` en attente). Mémoire « carte + voisines »
(`measure_map_cache.gd -- --route=ss_anne`) : pont principal 30,3 Mo (dont Carmin ≈ 30), autres
pièces ≤ 1,1 Mo. Départs : `ss_anne`, `vermilion_gym_map`.

#### T12 — constructeur-monde : vie du navire (16A, 16B) — après T4, T11

PNJ et répliques, 10 Dresseurs (vues des grilles), objets visibles et cachés, embarquement.

#### T13 — constructeur-monde : rival n° 4 et capitaine (16B, 16C) — après T4, T5, T11

§2.7, §2.8.

**Fait le 2026-10-16** (branche `j16-t13-rival-capitaine`) : données par carte
(`data/{npcs,dialogues,cutscenes}/ss_anne_captain_{corridor,room}.json`), vue `RivalView`
(7, 2..4), rattrapage `KeyItemRepair` (`data/story/key_item_repairs.json`, appelé par Boot au
chargement), objectifs `help_captain`, `hm01_cascade_badge`, `go_vermilion_gym`. Écarts : pas de
`rival_ss_anne_retried` / `resume_again` (un seul texte de reprise validé) ; drapeaux du plan, pas
`beaten_rival_ss_anne` de la grille. La confirmation PARTIR / PAS ENCORE reste au T15.

#### T14 — constructeur-monde : Arène de Carmin (16E) — après T4, T9, T10

Carte, Dresseurs, guide, panneau, Major Bob (modèle `cerulean_gym_misty`), badge, CT24 et son
rattrapage.

**Fait (2026-10-16)** (branche `j16-t14-arene`) : PNJ, dialogues et scènes en données
(`vermilion_gym.json`), modèle d'Ondine ; panneau de Carmin au n° 30 ; objectifs « affronter
Major Bob. » et « ouvrir le passage vers Major Bob. » en tête ; départs `vermilion_gym_solved`,
`surge_weak`, `thunder_no_tm` ; test `test_vermilion_gym_sequence`. Correctif :
`SceneRouter.before_spawn` (FlagGate à jour avant de poser le joueur ; la sortie de l'Arène
tombait sur l'arbuste coupé). Écart à signaler : la poubelle 15 n'est atteignable que par la vue
d'Axel (guide en (10, 12)). Sprites provisoires `guard`/`traveler`/`youngster`/`sailor`.

#### T15 — constructeur-monde : départ du navire (16D) — après T8, T11

§2.4, §2.11 ; d'abord sur `qa_dock_j16`, puis sur le quai du J15 après sa fusion (navire `FlagGate`,
marin de retour en (31, 26), garde-fou `blocking_cells` (31..32, 27..28), arrivée `dock`, arbuste réel `Entities/GymTree` et son point `GymTreeExamine`, §0.3).

**Fait (2026-10-16)** directement sur la vraie Carmin (branche `j16-t15-depart`) :
- `build_vermilion_city.gd` : `BoardingW|E` → `ss_anne_main_deck` / `from_ss_anne_w|e` ;
  `DoorGymW|E` → `vermilion_gym` / `entrance` ; `GymTreeExamine` → dialogue `cut_tree` ;
  garde-fou `Entities/GangwayGuard` (`FlagGate if:[ss_anne_departed]`, sans image, cases
  (31..32, 27..28)) ; spawn de débogage `gym_tree` (49, 11) sous l'arbuste ;
- pont principal : déclencheur `DepartureTrigger` sur les deux cases de sortie, **de tous côtés**
  (un pas de côté sur la passerelle ne contourne pas la confirmation) → scène
  `ss_anne_departure` (`data/cutscenes/ss_anne_departure.json`, dialogues
  `data/dialogues/ss_anne_departure.json`) : TXT-03 une fois avant la CS01 ; après, DEP-01 et
  PARTIR / PAS ENCORE (modèle du T16 : `confirm_set ss_anne_departure_chosen`) ; PARTIR →
  `change_map` quai (`dock`), `set ss_anne_departed`, `save`, puis le spectacle (navire réaffiché,
  DEP-02, `animate` de `Entities/SsAnne` de (−32, +2) cases en 5 s, fondu) ≈ 9,2 s ;
- marin : **variante DEP-03 en tête de `vermilion_sailor`** (`if ss_anne_departed`) plutôt qu'un
  second PNJ : un PNJ conditionnel n'apparaît qu'au chargement de la carte, la réplique est juste
  dès la fin du spectacle. **Au T12** : si le marin quitte (31, 26) à l'embarquement (`moved`),
  sa place doit revenir avec `ss_anne_departed` (`unless` dans `moved`) ;
- Coupe : `data/dialogues/cut_tree.json` (4 variantes, `cut:no_hm` = texte T-29 du J15, puis
  ARB-01 à ARB-03) et `data/cutscenes/cut_tree.json` (`cut_tree_vermilion_gym` : `field_move`
  sur `Entities/GymTree`, `set cut_vermilion_gym_bush`, ARB-04) ;
- arrivée sur une case libérée par une `FlagGate` (retour de l'Arène sur `from_gym`, case de
  l'arbuste coupé ; passerelle avec le garde-fou) : correctif `SceneRouter.before_spawn` **du T14**
  (repris par fusion de `jalon-16`, pas de second correctif) ;
- départs de débogage repointés sur les vraies cartes : `ss_anne_exit` et `ss_anne_free_exit`
  (pont principal, `from_ss_anne_w`, Passe Bateau ajouté), `cut_no_hm|no_badge|no_pokemon|ready`
  (Carmin, `gym_tree` ; navire parti pour les trois derniers). `vermilion_gym` (QA) reste au T20 ;
- tests : `test_ss_anne_departure` (Boot réel, sauvegarde en mémoire relevée à chaque étape),
  `test_vermilion_city`, `test_ss_anne_maps`, `test_map_links` (plus d'exception de retour vers
  Carmin) ; outil de capture `tools/capture_ss_anne_departure.gd`.
- listes : `test_dialogue_data` (`vermilion_gym_tree` retiré ; `got_hm01` en `FUTURE_FLAGS`
  jusqu'au T13), `test_cutscene_data` (`ss_anne_departure`, `cut_tree_vermilion_gym`).

#### T16 — constructeur-monde : `qa_dock_j16` et départs — **maintenant**, après T7, T8

**Fait (2026-10-15).** Trois cartes au lieu d'une (`tools/build_qa_j16.gd`) : `qa_dock_j16`
(quai, navire `FlagGate` « Ship », passerelle, arbuste `qa_tree`, porte de l'Arène d'essai),
`qa_ship_j16` (pièce du navire, sortie sud à confirmation), `qa_gym_j16` (géométrie validée de
`carmin_arene.txt`). Objets provisoires `qa_cut_tree` / `qa_barrier` (`tools/build_qa_objects_j16.gd`).
Données `qa_*` (`data/{npcs,dialogues,cutscenes}/qa_*j16*.json`, entrée `qa_vermilion_gym` de
`data/world/switch_puzzles.json`) ; départs `cut_no_hm`, `cut_no_badge`, `cut_no_pokemon`,
`cut_ready`, `ss_anne_free_exit`, `ss_anne_exit` (autosave), `vermilion_gym` ; test `test_qa_j16`.
Moteur ajouté pour l'occasion (sert aussi aux vraies cartes) :
- **routage des objets à fouiller** : `InteractPoint.puzzle` + `puzzle_slot`, signal
  `InteractionController.puzzle_searched`, `SwitchPuzzleLibrary` (`data/world/switch_puzzles.json`),
  `Boot._on_puzzle_searched` (puzzle oublié à chaque arrivée sur une carte) ;
- **`animate` réaffiche son nœud** : le navire `FlagGate unless:[ss_anne_departed]`, masqué par
  l'étape `set` qui précède, joue quand même son départ.
**Écart au §2.11** : la confirmation n'enchaîne pas une seconde scène (`confirm_cutscene`
serait refusé, une scène tourne déjà : le déclencheur de sortie) ; le choix lève
`ss_anne_departure_chosen` (`confirm_set`) et les étapes suivantes de la **même** scène s'y
conditionnent. Ordre inchangé : `change_map`, `set ss_anne_departed`, `save`, spectacle. Aucune
écriture n'a lieu entre le choix et `save` (scène en cours) : le drapeau du choix n'est jamais
écrit seul. La scène réelle (T15) reprendra cette forme.
Reste au T7 : la mise en scène du Pokémon qui coupe (`field_move_handler`, avec l'art).

#### T17 — qa-mobile : sessions 16A–16E → Kevin

16D **seul** : arrêt brutal (forcer l'arrêt Android) pendant la confirmation, pendant la scène
avant et après l'écriture, juste après ; relance ; Passe Bateau et CS01 conservés.

#### T18 — architecte : équilibrage — après T12–T14

Outil de simulation existant (`simulate_*.gd`, méthode du J10) : rival n° 4 par starter, Major Bob
avec les équipes types à la sortie du navire. **Information pour Kevin**, aucune donnée changée
sans lui.

**Fait (2026-10-16, branche `j16-t18-equilibrage`)** : rapport `docs/tech/jalon-16-equilibrage.md`
(scénarios générés par `tools/sim/gen_ss_anne_scenarios.py`, graines 0–999, clé de variante
`keep_order` ajoutée à `simulate_mt_moon.gd`, test `test_simulate_ss_anne`). Constats : Major Bob
= mur binaire (Sol gardé pour Raichu : 100 % ; sans Sol : 0–5 % au niveau d'arrivée, Carapuce
0 % jusqu'au N26) à cause de Tonnerre ; rival n° 4 = mur pour Bulbizarre (0 % au N20–24), dans
la cible pour Salamèche et Carapuce (63–72 % en directe). Recommandations R-1 à R-3 et questions
Q-T18-1 à 5 au §6–7 du rapport ; **aucune donnée changée**.

#### T19 — architecte : alignements — à chaque fusion de `main`

Identifiants du J15 (quai, arbuste, Centre, objectifs), listes des tests, `tm_compatibility.json`
régénéré.

**Fait le 2026-10-16** (fusion de `main` à `440f9b17`, J15 terminé, branche `j16-sync-j15`) :
- `super_potion` existait des deux côtés : le J16 la retire d'`items_j16.json` et prend celle du
  J15 (`data/items/vermilion.json`, mêmes 50 PV / 700 ₽) ; `test_hm` inchangé ;
- sauvegarde **v7** telle quelle (le J16 ne touche ni `GameState` ni `SaveSystem`) ;
- `vermilion_city` réelle conforme au §0.3 (`Entities/GymTree`, `Interactables/GymTreeExamine`,
  `Entities/SsAnne`, `GroundDecals/Gangway`, `Warps/BoardingW|E`, `Spawns/from_ss_anne_w|e`,
  `Spawns/dock`) ;
- **écarts des cartes de QA à reprendre au T15** (rien à changer avant) : l'arbuste d'essai est
  un PNJ objet `qa_tree` (despawn, drapeau `cut_qa_tree`) alors que le vrai est un nœud de carte
  (`field_move` sur `Entities/GymTree`, puis `set cut_vermilion_gym_bush`) ; le navire d'essai
  s'appelle `Ship` (vrai : `Entities/SsAnne`), l'embarquement `ToShip11|12` (vrai :
  `BoardingW|E`), l'arrivée unique `from_ss_anne` (vrai : `from_ss_anne_w|e` avant le départ,
  `dock` après) ; les barrières `qa_gangway_w|e` après le départ n'ont pas d'équivalent (vrai :
  marin de retour en (31, 26) + garde-fou `blocking_cells` posé par le J16).
- **nom en double** : « Scout Basile » est aussi le Dresseur `route_6_scout_basile` du J15 (défaut
  de `jalon-15.md`, validé sur S21) ; `test_names_unique_across_all_trainers` le refuse. Le nom
  affiché de `ss_anne_scout_basile` devient **« Scout Oscar »** (défaut, règle 4 ; identifiant et
  grille `ss_anne_cabine_b.txt` inchangés) — **à confirmer par Kevin** (R-10 du dossier 19).

#### T20 — fin et clôture — après la fusion du J15

Raccord réel à Carmin, retrait de `qa_dock_j16`, vraie partie de Kevin (sauvegarde v7 relue),
`jalon-16.md` §9 (clôture), `etat-projet.md`, `CLAUDE.md`.

---

## 4. Critères d'acceptation

**16.0** — planche de contact validée ; données chargées sans erreur ; CS01 et CT24 dans « CT/CS » ;
compatibilités de Coupe exactes ; tests verts, import propre.

**16A** — embarquement contrôlé (Passe Bateau) ; 9 cartes reliées dans les deux sens ; aucun mur
traversé ; écran 24 × 11 lisible ; objets visibles et cachés ; navire accessible sans le Badge
Cascade.

**16B** — 10 Dresseurs, **0 inévitable** hors rival (grille) ; rival : défaite → dernier Centre sans
perte d'argent → reprise courte ; seconde reprise ; victoire → il part ; **Grand moment une fois**.

**16C** — CS01 remise une fois (rejouée sans doublon après un arrêt brutal) ; arbuste : les 4 cas ;
COUPER ≤ 2 s avec le Pokémon visible ; coupé pour toujours (sortie, stockage, évolution,
rechargement) ; Coupe apprise et oubliée comme une CT ; « Réduire les animations ».

**16D** (seul) — PAS ENCORE garde à bord ; PARTIR : quai, spectacle ≤ 10 s, navire absent ensuite,
retour impossible ; **aucun état mixte** après un arrêt brutal à chaque étape ; Passe Bateau
conservé ; Corde Sortie refusée à bord.

**16E** — puzzle strict (premier au hasard, second voisin, erreur → zéro, nouveau tirage à chaque
entrée) ; résolu pour toujours, même après une défaite ; Major Bob (paralysie, Sonicboom,
Tonnerre), aucun bonus caché ; « BADGE FOUDRE » ; CT24 une fois ; rattrapage.

**16F** — raccord au Carmin du J15 ; vraie partie de Kevin sans régression J1–J15 ; sauvegarde v7
relue par l'APK final ; carte de QA retirée ; ≥ 58 fps de moyenne.

---

## 5. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Le J15 tarde** ou nomme autrement le quai, l'arbuste, le Centre | 16D et 16F en attente | `qa_dock_j16` ; identifiants en données (3 lignes) ; T19 |
| **Écriture forcée mal gardée** | sauvegarde pendant un combat ou une transition | une seule garde levée, liste blanche testée, 16D validé seul |
| **Puzzle strict frustrant sur téléphone** | abandon | texte du guide clair (recommandation T3), objets lisibles ; information pour Kevin à la QA |
| **Joueur sans Pokémon compatible** | bloqué devant l'Arène | G-6 testé (5 espèces), ARB-02 renvoie au stockage du Centre |
| **CS01 obtenue sans Cascade** | incompréhension | ARB-01 explicite, objectif « obtenir le Badge Cascade. » |
| **Conflits avec le J15** (scènes, objets, Sac) | fusions coûteuses | fin d'enum, fichiers nouveaux, « garder les deux » |
| **Kadabra trop fort** (Choc Mental, Rafale Psy) | rival dur | simulation T18 |
| **Tonnerre de Raichu au N24** | Major Bob trop fort | simulation T18, niveaux recalés avec Kevin |

---

## 6. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Branches | `jalon-16` depuis `main`, refusionnée ; jamais dans `main` avant le J15 |
| CS01 | id `hm01`, catégorie `tm` + `"hm": 1` ; onglet « CT/CS » quand une CS est présente ; CS après les CT |
| Coupe par un Pokémon K.O. | autorisée |
| Pokémon qui coupe | compagnon s'il est compatible, sinon le premier compatible de l'équipe |
| Animation de Coupe | ≤ 2 s ; réduite : fondu 0,3 s |
| Écriture forcée | étape `save`, une seule garde levée, réservée au départ |
| Navire qui part | étape `animate`, ≤ 10 s ; réduite : fondu 0,5 s |
| Puzzle | tirage par `GameState.rng`, second tiré au premier succès, état jamais écrit |
| Drapeaux | `rival_ss_anne_*`, `got_hm01`, `ss_anne_departed`, `cut_<id>`, `vermilion_gym_puzzle_solved`, `surge_met`, `badge_thunder`, `tm24_received` |
| Major Bob | 2 400 ₽, `switch true` (Kevin) |
| Pont extérieur | carte d'extérieur, le compagnon peut sortir |
| TXT-03 | une seule fois |
| Sauvegarde | celle du J15 (v7), aucun champ ajouté |
| Téléphone | S21 de Kevin (depuis le 2026-10-10) |

---

## 7. Questions pour Kevin

**Aucune question de game design.** Le dossier 19 et son §0 tranchent tout.

**À valider (pas des questions)** : le lot de textes (T3) et ce plan, sur le principe.

**Pour information** (défauts réversibles d'une ligne) : un Pokémon K.O. peut couper ; onglet
« CT/CS » ; Major Bob 2 400 ₽.

---

## 8. Premières tâches à lancer maintenant

1. Créer **`jalon-16` depuis `main`** dans une copie dédiée.
2. Kevin : les **trois vues générales** (Mac) et le **lot de textes** (T3).
3. En parallèle : **T4** (données), **T5** (CS), **T6** → **T7** (Coupe), **T8** (`save`,
   `animate`), **T9** (puzzle), **T16** (QA).
4. Après les vues générales : **T1** → **T2** → **T10** → **T11** → **T12** ∥ **T13** ∥ **T14**.
5. À la fusion du J15 : **T15** (quai réel), **T19**, puis **T20**.
