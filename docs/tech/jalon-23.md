# Jalon 23 — Les secrets du Parc Safari (Parc Safari, CS03 Surf, CS04 Force, Arène de Koga)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/dossier-26-parc-safari-koga.md` (7 décisions de la V2, arbitrages N-2 à N-24 et
> textes du §8 **validés par Kevin le 2026-10-16** ; dossier verrouillé). V2 :
> `docs/design/passes/j23-v2-chatgpt.md`. Partage avec le J24 : P-2 B (`docs/dossier-27-j24`,
> dossier 27 §6.5). Contrat avec le J22 : passe `j22-v2-alignement.md` (M-1 à M-24).

> Objectif jouable sur le téléphone : **le Parc Safari, puis Koga**. À Parmanie, le joueur paie
> 500 ₽, reçoit 30 Safari Balls et 500 pas, et parcourt les quatre zones du Parc. Chaque rencontre
> se joue sans ses Pokémon : SAFARI BALL, APPÂT, CAILLOU, FUIR. Au fond de la zone Ouest, la Maison
> Secrète donne la **CS03 Surf** ; dans la même zone, les **Dents d'Or** du Gardien, qui les échange
> contre la **CS04 Force**. Dans l'Arène aux murs invisibles, Koga remet le **Badge Âme** et la
> **CT06 Toxik**. Ensuite, aucun événement imposé.
>
> Mécaniques nouvelles :
> - la **visite Safari** : péage, compteur de pas et de Balls, fin de visite, sortie volontaire,
>   **champ de sauvegarde nouveau (v8)** ;
> - la **rencontre Safari** : un jeu de règles de combat sans Pokémon allié, appât, caillou, fuite
>   RB, Safari Ball (multiplicateur × 2) ;
> - le **poison grave** (Toxik) ;
> - les **murs invisibles** et leurs indices (sol, contact) ;
> - deux CS **sans** mécanique de monde (Surf et Force en combat et en données ; le monde est au
>   J24, P-2 B).
>
> Le reste (zones, maisons, Gardien, Dresseurs, Koga, objets) est du contenu posé sur des systèmes
> existants.

**Pré-requis.** Dossier 26 verrouillé ; grilles v1 (2026-10-19) `tools/plans/safari_centre.txt`,
`safari_est.txt`, `safari_nord.txt`, `safari_ouest.txt` (géométrie RB 1:1, N-3), `safari_porte.txt`,
`safari_maison_repos.txt`, `safari_maison_secrete.txt`, `parmanie_maison_gardien.txt`,
`parmanie_arene.txt` ; contrôle `python3 tools/art/plan_check_safari.py` (0 échec). **Les grilles
font foi pour la géométrie ; validées par Kevin le 2026-10-19.**

Plan écrit sur `docs/dossier-26-j23` (base `origin/main` à `440f9b17`). **Code lu** :
- `origin/main` à `440f9b17` (J15 terminé, sauvegarde v7) : code de référence ;
- `jalon-16` (CS01 Coupe, `FieldMoves`, étape `field_move`) et `jalon-17` (CS05 Flash, `FlagGate`,
  `poison_gas`, Soporifik, Hypnomade) ;
- `jalon-19` (Noeunoeuf), `jalon-20` (Rhinocorne, Kangourex, `badge_rainbow` prévu, ascenseurs,
  dalles), `jalon-21` (objet clé utilisable, `uncatchable`) ;
- passes J22 (`docs/dossier-25-j22` à `815d9e53`) et J24 (`docs/dossier-27-j24`).

Quand un nom n'existe que dans un plan, il est suivi de « (plan) ». **La tâche d'alignement (T9)
réaligne ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), skills `godot-conventions`, `world-tiles`,
`ui-theme-2026` ; modèles de forme `jalon-21.md`, `jalon-16.md` (`FieldMoves`), `jalon-15.md`
(Pension : péage et sauvegarde v7).

---

## 0. État et dépendances

### 0.1 Règle d'entrée : le code du moteur commence après la fusion J16 → J22

Les branches `jalon-17` à `jalon-21` partent toutes de `440f9b17` et ne se contiennent pas ; le
J22 (Parmanie, pêche) n'est qu'une passe d'alignement. **Le J23 ne touche ni au moteur ni aux cartes
avant que `main` contienne J16 à J22** (T9). Avant : documents, grilles, art, logique pure et
données en fichiers nouveaux.

**Règle d'ancienneté (Kevin, 2026-10-16)** : une session plus récente ne modifie pas ce qu'une
session plus ancienne est en train de modifier. Avant toute tâche qui touche un fichier chaud (§1.3),
vérifier les branches des J15 à J22 en cours ; en cas de recouvrement, attendre ou demander à Kevin.

### 0.2 Contrat d'entrée (dossier 26 §1)

| Attendu | Fourni par | État au 2026-10-19 | Bloque |
|---|---|---|---|
| Parmanie : carte, Centre, Boutique ; façades et portes réservées du Parc, de l'Arène et de la maison du Gardien (M-19) | J22 | passe à trancher | 23A, 23C, 23E |
| Au moins un chemin praticable vers Parmanie | J22 (M-3 avec le J21) | passe à trancher | QA de bout en bout |
| Pêche (`water_rod`, cannes) | J22 (M-8 à M-11) | passe à trancher | **N-6 seulement** (étangs pêchables) |
| `FieldMoves`, catégorie CS, apprentissage hybride | J16 | codé, non fusionné | 23D |
| `badge_rainbow` posé par une scène | J20 | J20 à T8 | rien au J23 (Force n'a pas d'usage de monde) |
| `poison_gas` (Koga), Soporifik et Hypnomade (Jongleurs) | J17 | codé, non fusionné | 23E |
| Rhinocorne, Kangourex | J20 | données, non fusionnées | 23B |
| Noeunoeuf | J19 | données, non fusionnées | 23B |
| Version de sauvegarde | J16 → J22 | v7 (aucun ne la change à ce jour) | 23A : **v8** ou la suivante |

### 0.3 Points d'accroche dans le code (`origin/main` à `440f9b17`, sauf mention)

| Besoin | Point d'accroche | Remarque |
|---|---|---|
| Pas du joueur | signal `Player.moved` (déjà écouté par `EncounterDirector._on_player_moved`) | un pas effectif ; pivoter et se cogner n'émettent rien |
| Rencontres | `EncounterDirector` (`_on_player_moved`, `_run`, `start_encounter`) ; `EncounterTable.roll` ; `BattleRequest.wild` | le directeur demandera une requête Safari quand la carte est du Parc |
| Combat | `BattleRules` (`wild`, `can_flee`, `allow_balls`, `allow_heal_items`, `items`) ; `BattleAction.Kind` ; `BattleDirector._choose_action` ; `battle.gd::_throw_ball` | mode Safari = règles + actions nouvelles (§2.3) |
| Capture | `capture_calc.gd` (G3/G4, 4 secousses) ; `BattleDirector.pokemon_caught(pokemon, stored)` ; `PokemonStorage` (illimité) | la Safari Ball passe un multiplicateur et un taux modifié |
| Argent | `GameState.spend_money` / `add_money` | péage |
| Scènes | `CutsceneStep` : `dialogue`, `give`, `take`, `set`, `change_map`, `battle`, `champion_card`, `badge`, `moment` ; `DialogueChoice` + `confirm_cutscene` (J12) | `take` existe : Dents d'Or rendues |
| Obstacles à drapeau | `FlagGate.blocking_cells` (J17) | rocher fixe du Gardien (§2.11) |
| Vibrations | `game/systems/settings/haptics.gd`, `game/ui/components/haptic_pattern.gd` | contact des murs invisibles |
| Statuts | `StatusRules` (`KNOWN`, `catch_bonus`) | poison grave à ajouter (§2.12) |
| CS | `game/world/field/field_moves.gd`, `data/world/field_moves.json`, `game/items/tm_teach.gd`, `tm_compatibility.json` (généré) | J16 / J17 |
| Sauvegarde | `save_system.gd` (`VERSION = 7`, `upgrade()` par version), autosave de `boot.gd` | §2.15 |

### 0.4 Écarts relevés en préparant les grilles (corrections du dossier)

1. **La Pépite RB du Centre (14, 10) est sur l'îlot de l'étang**, inaccessible sans Surf. Pour tenir
   N-17 (« Pépite dans la zone Centre, rentable dès la première visite »), elle est **déplacée sur la
   berge sud (14, 16)** [D]. Reporté au dossier §7 et §12.3.
2. **La moitié nord du Centre ne s'atteint pas depuis la Porte** (RB) : la clôture sous l'étang et
   les haies coupent le Centre en deux ; on y entre par l'Ouest ou le Nord. Depuis la Porte, le seul
   départ est **l'Est**. Chemin le plus court Porte → Maison Secrète : Centre sud → Est → Nord →
   Ouest.
3. **Le critère « une visite suffit » se mesure sans le retour** : la fin de visite ramène à la
   Porte. Mesuré : Porte → Maison Secrète → Dents d'Or = **233 pas** (≤ 300) ; avec le retour à pied,
   416 sur 500. Le dossier §2.2 disait « → Porte ≤ 300 » : corrigé [D].
4. **Pas de statue de Kangourex** dans le Centre RB (le dossier §2.2 la citait) : retirée.

---

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §14, N-21)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **23.0** | Plan, grilles, vues peintes, kit et lot d'art ; logique pure (`SafariVisit`, `SafariRules`, poison grave) ; données en fichiers nouveaux ; alignement après la fusion J16 → J22 (T9) | Kevin valide grilles, vues et art. **Aucune session téléphone.** |
| **23A** « La visite » | Porte et péage ; quatre zones, raccords, maisons, objets ; compteur de pas et de Balls ; pastille ; fin de visite ; sortie volontaire ; **sauvegarde v8** | **Téléphone, validé SEUL** (système de sauvegarde) |
| **23B** « La rencontre » | Tables ; rencontre Safari (écran, menu, appât, caillou, fuite, Ball, capture) ; fin par les Balls ; pêche du Parc si le J22 l'a livrée | **Téléphone** |
| **23C + 23D** « Les deux CS » | Maison Secrète et CS03 ; Dents d'Or ; Gardien et CS04 ; rocher fixe ; capacités Surf et Force, apprentissage, entrées `field_moves.json` | **Téléphone** (une seule session) |
| **23E** « Koga » | Murs invisibles et indices ; 6 Dresseurs ; Koga ; poison grave ; Badge Âme ; CT06 | **Téléphone** |
| **23F** « Clôture » | Équilibrage par simulation, non-régression, interruptions, retrait des cartes de QA, QA de bout en bout | **Téléphone** + fusion |

Règle des trois systèmes : 23A porte **la visite** (et sa sauvegarde, validée seule) ; 23B **la
rencontre Safari** ; 23C+23D **aucun** système (contenu et données) ; 23E **le poison grave** et
**les murs invisibles** (deux, pas trois).

### 1.2 « Peut commencer maintenant » ou « après la fusion »

| Tâche | Quand | Pourquoi |
|---|---|---|
| T1 branche `jalon-23` | **maintenant** | Depuis `origin/main` + `docs/dossier-26-j23` |
| T2 textes de l'annexe A | **maintenant** | Documents |
| T3 logique pure de la visite | **maintenant** | Fichiers nouveaux |
| T4 logique pure de la rencontre | **maintenant** | Fichiers nouveaux |
| T5 logique pure du poison grave | **maintenant** | Fichier nouveau ; branchement après T9 |
| T6 données valides sur `main` | **maintenant** | Espèces, attaques, objets en fichiers nouveaux |
| T7 kit et lot d'art | **maintenant** | Série à réserver au push (§2.17) |
| T8 vues peintes | **maintenant** | Grilles validées par Kevin d'abord |
| T9 alignement | **après la fusion J16 → J22 dans `main`** | Moteur, cartes, Parmanie |
| T10 à T24 | **après T9** | |

### 1.3 Branches et fichiers chauds

- Intégration sur **`jalon-23`**, dans une copie dédiée ; une branche par tâche (`j23-t<n>-<sujet>`) ;
  rien dans `main` avant la clôture (T24).
- **Fichiers nouveaux de préférence** : `game/systems/safari/` (`safari_visit.gd`,
  `safari_rules.gd`, `safari_director.gd`), `data/safari.json`, `species/kanto_j23.json`,
  `moves/j23.json`, `items/items_j23.json`, `encounters/safari.json`, `trainers/fuchsia_gym.json`,
  `npcs/safari_*.json`, `npcs/wardens_house.json`, `npcs/fuchsia_gym.json`, `dialogues/j23_*.json`,
  `cutscenes/j23_*.json`, `tools/build_safari_zone.gd`, `tools/build_fuchsia_gym.gd`.
- **Fichiers uniques, ajouts en fin** : `data/pokedex/kanto.json`, `zones.json`,
  `data/battle/decors.json`, `data/world/field_moves.json` (entrées `surf`, `strength`),
  `messages.json`, `tools/art/manifeste.json`, `build_character_frames.gd`,
  `data/story/objectives.json` (**en tête**).
- **Fichiers chauds (après T9 seulement), ajouts courts en bloc « J23 »** :
  - moteur de combat : `battle.gd`, `battle_action.gd`, `battle_rules.gd`, `battle_request.gd`,
    `battle_director.gd`, `battle_text.gd`, `capture_calc.gd`, `status_rules.gd` ;
  - monde : `encounter_director.gd`, `player.gd` (signal de contact), `grid_world.gd` (aucune
    modification prévue : les murs invisibles sont des cases bloquées ordinaires) ;
  - `boot.gd`, `game_state.gd`, `save_system.gd`, `debug_start.gd` ;
  - cartes des autres jalons : Parmanie (J22 : `build_fuchsia_city.gd` (plan), grille
    `parmanie.txt` (plan)) — **ouvrir les trois portes réservées seulement**.

---

## 2. Conception technique

### 2.1 La visite : `SafariVisit` (pur) et `SafariDirector` (T3, T11)

```
# game/systems/safari/safari_visit.gd — pur
class_name SafariVisit
var active: bool
var steps_left: int
var balls_left: int
static func start(money: int, cfg: SafariConfig) -> SafariVisit   # null si money < cfg.fee
func on_step() -> StringName      # &"" (continuer) ou &"time_up" ; RB : à 0, le pas SUIVANT termine
func on_ball_thrown() -> StringName   # &"" ou &"out_of_balls"
func to_dict() -> Dictionary ; static func from_dict(d: Dictionary) -> SafariVisit
```

- `data/safari.json` : `fee` 500, `balls` 30, `steps` 500, cartes du Parc (`safari_zone_*` et les
  maisons), carte et case de fin (`safari_zone_gate`, `arrivee_fin`). Données, pas de constantes.
- **Compteur** (dossier §4) : `SafariDirector` écoute `Player.moved` **sur les cartes du Parc
  seulement** (pas dans la Porte). Un pas = `on_step()`. Si `steps_left == 0` **avant** le pas, ce
  pas termine la visite (RB : 500 pas utilisables, le 501e appelle le haut-parleur). Franchir une
  porte ou un raccord est un pas. Dialogues, menus, combats : aucun signal, aucun pas.
- **Fin de visite** : verrou du joueur, texte 10 ou 11 (haut-parleur, bulle sans locuteur [D]),
  fondu vers `safari_zone_gate` / `arrivee_fin`, texte 12, `active = false`, Balls à 0. Jamais
  pendant un combat : la fin par les Balls est relevée par le directeur **au retour sur la carte**.
- **Sortie volontaire** : déclencheur du comptoir (grille `safari_porte`) en venant du nord avec une
  visite en cours → texte 7 (OUI / NON) ; NON → le joueur remonte d'un pas (étape `move`).
- **Corde Sortie** dans le Parc : termine la visite (même effet que la fin, sans le haut-parleur),
  puis l'effet habituel de la Corde.
- **Vol / Téléport hors combat** : refusés dans le Parc si ces usages existent au moment du J23
  (aucun à ce jour) ; un test garde la règle (`safari.json` : `no_fly: true`).

### 2.2 La Porte et le péage (T11)

- Scène `j23_safari_gate_enter` sur `declencheur_comptoir` (venant du sud, `unless` visite active) :
  texte 1 (OUI / NON) → `GameState.spend_money(500)` ; échec → texte 3 et recul d'un pas ;
  succès → texte 4, `SafariVisit.start`, **sauvegarde demandée** (étape `save` du J16), le joueur
  avance vers le passage nord. Première visite : texte 5 de l'employé des zones (`safari_intro_heard`).
- Étape nouvelle **`pay`** (plan) : `{ "pay": 500, "fail": "<scène>" }`, sur le modèle de la Pension
  (`daycare_rules.payment`) : pas de débit partiel, refus propre. Ajout **en fin** de
  `TYPE_KEYS` de `cutscene_step.gd` (fichier chaud).

### 2.3 La rencontre Safari (T4, T13)

- `BattleRequest.safari(species, level, visit)` (plan) : un sauvage, **aucun Pokémon allié en
  scène** (le dos du joueur à la place, §2.17), `BattleRules.safari = true` (plan) :
  `allow_switch = false`, `allow_heal_items = false`, `gives_exp = false`, `prize_money = 0`.
- `BattleAction.Kind` : ajout **en fin** de `SAFARI_BALL`, `BAIT`, `ROCK` (FUIR = `RUN`, toujours
  réussi).
- **`SafariRules` (pur, T4)** — tous les tirages par un `RandomNumberGenerator` injecté :

```
class_name SafariRules
var bait: int ; var anger: int ; var rate: int        # taux de capture courant
static func begin(base_rate: int) -> SafariRules
func throw_bait(rng) -> void     # rate = rate / 2 ; anger = 0 ; bait = min(bait + 1 + rng(0..4), 255)
func throw_rock(rng) -> void     # rate = min(rate * 2, 255) ; bait = 0 ; anger += 1 + rng(0..4)
func end_turn() -> StringName    # &"eating" | &"angry" | &"" ; anger → 0 remet rate = base_rate
func flees(speed: int, rng) -> bool   # b = speed*2 ; repas → /4 ; colère → min(*2, 255) ; rng(0..255) < b
```

  Particularités RB conservées (dossier §5.2) : la division d'appât n'est jamais annulée à la fin du
  repas ; la fin de la colère remet le taux de base. Aucun test de fuite avant la première action.
- **Ordre d'un tour** : action → si pas de capture : `end_turn()` (texte 24 ou 25) → test de fuite
  (texte 26) → menu.
- **Safari Ball** : `capture_calc` reçoit `ball_multiplier = 2.0` (N-5) et `rate` de `SafariRules`
  au lieu du taux de l'espèce ; aucun bonus de statut. Compteur `balls_left - 1` ; à 0 : texte 11,
  fin du combat **sans** test de fuite.
- **Capture** : chemin existant (`pokemon_caught`, Stockage si l'équipe est pleine, Pokédex).
- **Interruption** (N-9) : rien de neuf ; la reprise se fait à la dernière sauvegarde.

### 2.4 Rencontres : tables et pêche (T6, T13)

- `data/encounters/safari.json` : une table par zone, terrain `grass`, poids RB (20/20/15/10/10/10/
  5/5/4/1), emplacements partagés à parts égales entre Rouge et Bleu (N-4), taux équivalent à
  30/256 par pas (≈ 11,7 %) [D], **sans `ramp`** [D] (le Parc doit être vivant dès le premier pas).
- Le directeur choisit `BattleRequest.safari` quand la carte figure dans `safari.json`.
- **Pêche (N-6 A)** : si le J22 a livré `water_rod`, les berges marquées pêchables dans les grilles
  du Parc (caractère fixé par le J22, M-8) reçoivent les tables RB (Canne, Super Canne, Méga Canne
  du Parc : Minidraco, Krabby, Psykokwak, Ramoloss 15) ; la rencontre pêchée est une rencontre
  Safari ; un lancer ne coûte **pas** de pas. Sinon, la tâche T14 est sautée et notée.

### 2.5 Pastille « pas · Balls » (T12)

- Composant d'interface (skill `ui-theme-2026`) : capsule discrète sous le titre de zone, deux
  icônes et deux nombres, visible **seulement** sur les cartes du Parc (N-7). Aucune alerte.
- Se met à jour sur les signaux de `SafariDirector` ; masquée pendant les scènes et les combats
  (le combat affiche son propre compteur de Balls sur le bouton SAFARI BALL).

### 2.6 Cartes du Parc (T10)

- `tools/build_safari_zone.gd` construit les quatre zones, la Porte, la maison de repos (une scène,
  quatre instances paramétrées : `vers`, PNJ présents) et la Maison Secrète **depuis les grilles**.
- Raccords continus en bord de carte (mécanisme existant) entre les cases des grilles ; aucune case
  « n » praticable.
- Décor provisoire jusqu'aux vues peintes (T8) ; `zones.json` : une zone « Parc Safari » (titre de
  zone par carte : « PARC SAFARI — ZONE EST »…).
- Compagnon : suit le joueur dans les zones, rentre dans sa Ball dans les maisons (existant).

### 2.7 Objets du Parc (T6, T10)

- Tous les objets du dossier §7, avec les remplacements N-19 ; `gold_teeth` (objet clé, invendable) ;
  Pépite **déplacée** en (14, 16) (§0.4).
- CT37 Bomb'Œuf et CT32 Reflet : capacités `egg_bomb` (Normal, 100, 75 %, 10 PP) et `double_team`
  (Normal, statut, Esquive +1, 15 PP) [RB], `moves/j23.json`.

### 2.8 Maison Secrète et CS03 (T15)

- Scène `j23_secret_house` : textes 18 → `give hm03` + `set got_hm03` **dans la même étape de
  sauvegarde** → texte 19 ensuite. Réconciliation au chargement (dossier §11) : objet sans drapeau →
  drapeau ; drapeau sans objet → objet rendu une fois, anomalie journalisée.
- La remise ne dépend pas de la visite (si la visite se termine pendant la scène, impossible : aucun
  pas pendant une scène).

### 2.9 Gardien et CS04 (T15)

- Sans les Dents d'Or : textes 30 / 31 (OUI / NON sans effet).
- Avec : texte 32 → `take gold_teeth` + `set gave_gold_teeth` → texte 33 → `give hm04` +
  `set got_hm04` → texte 34. Si l'écriture s'interrompt entre les deux, le Gardien redonne la CS au
  dialogue suivant (`if gave_gold_teeth unless got_hm04`, RB).

### 2.10 Surf et Force sans monde (T16, P-2 B)

- `moves/j23.json` : `surf` (Eau, 95, 100 %, 15 PP), `strength` (Normal, 80, 100 %, 15 PP).
- `items/items_j23.json` : `hm03`, `hm04` (catégorie CS du J16, `teaches`).
- `data/world/field_moves.json` (ajout en fin) : `"surf": { "hm": "hm03", "badge": "badge_soul" }`,
  `"strength": { "hm": "hm04", "badge": "badge_rainbow" }`. **Aucun déclencheur de monde** ne les lit
  au J23 ; un test vérifie les quatre états de `FieldMoves` pour chacune.
- Compatibilités : `tm_compatibility.json` **régénéré** (pas fusionné) avec les espèces du J23.

### 2.11 Rocher fixe du Gardien (T15)

- Obstacle `rocher` (11, 3) de `parmanie_maison_gardien.txt` : case bloquée + interaction texte 46.
  Implémenté comme un objet de décor bloquant sans drapeau ; **même image** que les rochers du J24
  (art partagé, §2.17). Le J24 remplace son comportement (dossier 27 §6.5).

### 2.12 Poison grave (T5, T18)

- `StatusRules` : statut `poison` + indicateur `toxic` et compteur `toxic_n` sur le combattant (plan) ;
  dégâts `max(1, PVmax × N / 16)`, N = 1, 2, 3… en fin de tour.
- Au changement de Pokémon et en fin de combat : `toxic = false`, `toxic_n = 0` (reste `poison`).
- Pas d'interaction avec Vampigraine (N-14). Hors combat : comme le poison simple.
- Capacité `toxic` (Poison, statut, 85 %, 10 PP) ; CT06 `tm06` ; IA : Toxik ne vise pas un Pokémon
  déjà empoisonné ou de type Poison (règle de l'IA `smart` existante pour les statuts, à vérifier en
  T9).
- Interface : libellé « PSN+ » [D] sur la pastille de statut.

### 2.13 Arène de Koga (T17, T19)

- `tools/build_fuchsia_gym.gd` depuis `parmanie_arene.txt` ; les cases « i » sont des cases
  **bloquées ordinaires** pour `GridWorld`.
- **Indices** (N-15) :
  - au sol : une jointure de parquet légèrement différente sous chaque « i » (décor peint, T8) ;
  - au contact : `Player` émet `bumped(cell)` (plan, signal nouveau, sans effet ailleurs) quand un pas
    est refusé ; si la case est un mur invisible : vibration courte (`haptic_pattern` existant),
    son mat, frémissement 0,4 s d'un panneau translucide sur la case (shader ou sprite).
- Dresseurs (`trainers/fuchsia_gym.json`) : 6, positions et vues de la grille ; **J2 et J4
  inévitables** d'après le contrôle (aucun n'est imposé par le dossier : constat, rien à changer).
- Koga : `ai: smart`, équipe du dossier §10.3 ; scène sur le modèle de Major Bob
  (`champion_card`, `battle` avec `win: ["badge_soul"]`, `badge`, `give tm06` `unless
  tm06_received`, `moment`) ; rattrapage `j23_koga_tm_late`. `koga_met` au premier dialogue.
- Après le badge : aucun objectif, aucune scène (décision 7).

### 2.14 Espèces, Pokédex, art des Pokémon (T6)

- `species/kanto_j23.json` : Leveinard, Insécateur, Scarabrute, Tauros, Mimitoss, Aéromite, Doduo,
  Dodrio, Rhinoféros, Noadkoko, Smogogo, Tadmorv, Grotadmorv (+ Minidraco, Psykokwak, Ramoloss si
  N-6 A) ; `pokedex/kanto.json` en fin ; évolutions N-22.
- Dos de combat : pipeline X/Y repeint (règle « Pokémon art source ») ; face adverse : artwork.

### 2.15 Sauvegarde : **v8** (T3, T11)

- Champ nouveau : `safari = { active, steps_left, balls_left }` dans `GameState` ; `to_dict` /
  `from_dict` de `SafariVisit`.
- `save_system.gd` : `VERSION = 8` (ou la version qui suit celle des J16 → J22 au moment de T9) ;
  `upgrade()` : cas 7 → 8 = `safari.active = false`.
- **Cohérence au chargement** : visite active hors du Parc → close sans remboursement ; joueur dans
  le Parc sans visite → renvoyé à la Porte (`arrivee_fin`), message neutre [D].
- Autosave existante (arrivée sur une carte, fin de combat, capture, mise en pause) : suffit (N-9).
- Aucune position de rocher, aucun état « sur l'eau » (J24).

### 2.16 Départs de débogage (`tools/debug_start/`)

- `safari_qa` : Porte du Safari, 5 000 ₽, équipe de 6 (pour tester le Stockage).
- `safari_end_qa` : zone Est, visite active avec 3 pas et 2 Balls.
- `koga_qa` : entrée de l'Arène, équipe d'environ N40.
- `warden_qa` : maison du Gardien, Dents d'Or dans le Sac.
- **Retirés à la clôture** (T24).

### 2.17 Art (lot 23.0)

- **Série d'art** : numéro **à réserver au moment du push**, après vérification de toutes les
  branches distantes (règle d'ancienneté ; 20 à 24 pris au 2026-10-16, le J22 vise 25).
- Vues générales peintes des quatre zones, de la Porte, de l'Arène (avec les jointures du sol) ;
  intérieurs : maison de repos (une), Maison Secrète, maison du Gardien.
- Personnages : Koga (monde + carte), Gardien, Pêcheur expert, Jongleur, Dompteur, visiteurs
  (réutilisés), employés (modèle existant).
- Combat : **dos du joueur** avec un geste de lancer (Ball, appât, caillou) ; fonds CB.3 : un décor
  commun au Parc avec quatre lumières (N-18), un décor de l'Arène.
- Rocher : **une image commune avec le J24** (à demander à la session du J24 avant de peindre).

---

## 3. Tâches

Chaque tâche :
- part d'une branche `j23-t<n>-<sujet>` créée depuis `jalon-23` ;
- n'utilise jamais `pkill` ni `killall` (arrêter ses propres processus par PID) ;
- reprend les textes **mot pour mot** (dossier §8 validé et annexe A) ;
- met à jour `docs/tech/etat-projet.md` dans son commit ;
- **CA communs** : `tools/test.sh` vert ; `godot --headless --path . --import` sans `ERROR`.

Agents : **A** architecte-godot, **C** constructeur-monde, **U** ui-mobile, **Q** qa-mobile,
**K** Kevin.

### 3.1 Sous-jalon 23.0

#### T0 — A : plan (ce document) et grilles v1
- **CA** : `python3 tools/art/plan_check_safari.py` : 0 échec.

#### T1 — A : branche `jalon-23` — **maintenant**
- Créer `jalon-23` depuis `origin/main` dans une copie dédiée ; y fusionner `docs/dossier-26-j23`.

#### T2 — A puis K : annexe A des textes — **maintenant**
- Textes non écrits au §8 : vitrines du Gardien (RB « display »), panneaux de zone et de conseils
  (dossier §2.2 : quatre zones, conseils RB adaptés), prénoms et répliques des 6 Dresseurs (avant,
  défaite, après), descriptions de Surf, Force, Toxik, Bomb'Œuf, Reflet, des Dents d'Or ; libellé
  de la pastille.
- **CA** : Kevin valide l'annexe A en une passe.

#### T3 — A : logique pure de la visite — **maintenant**
- `game/systems/safari/safari_visit.gd`, `safari_config.gd` (plan), `data/safari.json`.
- **Tests** `tests/unit/test_safari_visit.gd` : péage refusé sous 500 ₽ ; 500 pas utilisables, le
  501e termine ; 30 Balls, la dernière termine ; aller-retour `to_dict` / `from_dict` ; valeurs lues
  dans les données.

#### T4 — A : logique pure de la rencontre — **maintenant**
- `game/systems/safari/safari_rules.gd`.
- **Tests** `tests/unit/test_safari_rules.gd` (graines fixes) : appât (÷ 2, compteur 1–5, colère à
  0) ; caillou (× 2 plafonné à 255, repas à 0) ; décrément de fin de tour ; retour au taux de base en
  fin de colère ; division d'appât jamais annulée ; fuite (÷ 4, × 2 plafonné) ; FUIR toujours réussi.

#### T5 — A : logique pure du poison grave — **maintenant**
- Fonctions pures (fichier nouveau `game/pokemon/toxic_rules.gd` (plan)) branchées en T18.
- **Tests** : N/16 croissant, plancher 1 ; remise à zéro au changement et en fin de combat.

#### T6 — A : données — **rédigées maintenant, fusionnées après T9**
- `species/kanto_j23.json`, `moves/j23.json` (`surf`, `strength`, `toxic`, `egg_bomb`, `double_team`),
  `items/items_j23.json` (`hm03`, `hm04`, `tm06`, `tm32`, `tm37`, `gold_teeth`),
  `encounters/safari.json`, `trainers/fuchsia_gym.json`, `pokedex/kanto.json` (en fin).
- **Tests** : `test_pokemon_data` (comptes, évolutions sans espèce absente) ; `test_trainers_j23`
  (6 Dresseurs + Koga, équipes et attaques RB, aucune attaque absente) ; `test_safari_encounters`
  (poids, niveaux, Insécateur **et** Scarabrute) ; `test_item_library` (CS jamais consommées,
  Dents d'Or objet clé invendable).

#### T7 — A puis C : kit et lot d'art — **maintenant**
- §2.17 ; numéro de série réservé au push ; planche de contact → K.

#### T8 — C : vues peintes — **maintenant**, après validation des grilles par K
- Quatre zones, Porte, Arène (jointures du sol discrètes) ; plans en aplats depuis les grilles.

#### T9 — A : alignement — **après la fusion J16 → J22 dans `main`**
- Fusionner `main` dans `jalon-23` ; relire les §0.2 et §0.3 sur le code ; régénérer
  `tm_compatibility.json` ; fixer la version de sauvegarde ; caractère « pêchable » du J22 (N-6) ;
  noms réels de Parmanie (carte, portes réservées).
- **CA** : ce plan est corrigé là où le code diffère ; tests verts.

### 3.2 Sous-jalon 23A (la visite)

#### T10 — C : cartes du Parc — après T9, T8
- §2.6, §2.7 ; ouverture de la porte du Parc à Parmanie (seulement elle).
- **Tests** `test_safari_maps` : chaque carte = sa grille (dimensions, cases bloquées) ; raccords
  réciproques ; objets aux cases de la grille.

#### T11 — A : visite, péage, fin, sauvegarde v8 — après T10, T3
- §2.1, §2.2, §2.15 ; étape `pay`.
- **Tests** : péage (succès, refus, aucun débit partiel) ; compteur (pivot, collision, dialogue,
  menu, combat, porte, raccord) ; fin au pas suivant le zéro ; fin dans une maison ; sortie
  volontaire OUI / NON ; Corde Sortie ; migration 7 → 8 ; cohérence au chargement (deux cas) ;
  **interruption** à chaque écriture (péage, arrivée sur une carte, fin) sans gain de pas ni de Balls
  au-delà de la dernière sauvegarde.

#### T12 — U : pastille — après T11
- §2.5. **CA** : capture relue sur S24 (lisibilité, aucun recouvrement du titre de zone).

#### T13a — Q : **session 23A** → K (validée seule : sauvegarde)
- Dossier §15 « 23A » ; tuer l'application dans chaque zone, dans une maison, juste après le péage.

### 3.3 Sous-jalon 23B (la rencontre)

#### T13 — A puis U : rencontre Safari — après T11, T4, T6
- §2.3, §2.4 ; menu de quatre boutons, compteur de Balls sur le bouton ; textes 20 à 29.
- **Tests** : aucun Pokémon allié en scène ; ni XP ni argent ; capture → Stockage si l'équipe est
  pleine ; dernière Ball (capture ou non) ; fuite et colère par graine ; Pokédex vu / capturé.

#### T14 — A : pêche du Parc (N-6 A) — après T13, **si** le J22 a livré la pêche
- Cases pêchables des grilles, tables RB, rencontre Safari, lancer sans coût de pas.

#### T15b — Q : **session 23B** → K

### 3.4 Sous-jalon 23C + 23D (les deux CS)

#### T15 — C : Maison Secrète, Gardien, rocher fixe — après T10, T6
- §2.8, §2.9, §2.11 ; ouverture de la porte du Gardien à Parmanie.
- **Tests** : remises uniques (deux fois la scène → un seul objet) ; réconciliations ; Gardien
  interrompu entre `take` et `give` ; rocher : case bloquée, texte 46, Super Bonbon hors d'atteinte.

#### T16 — A : Surf et Force en combat et en données — après T9, T6
- §2.10. **Tests** : apprentissage par la CS (compatibles seulement), oubli, CS non consommée ;
  `FieldMoves` : quatre états pour `surf` et `strength`.

#### T16b — Q : **session 23C+23D** → K

### 3.5 Sous-jalon 23E (Koga)

#### T17 — C : Arène — après T9, T8
- §2.13 (carte, murs, indices, Dresseurs, Guide) ; ouverture de la porte de l'Arène à Parmanie.
- **Tests** : carte = grille ; 36 murs invisibles bloquants ; contact → signal `bumped` sur un « i »
  et sur un mur ordinaire (seul le premier déclenche l'indice) ; Dresseurs à leurs cases et vues.

#### T18 — A : poison grave branché, Toxik, CT06 — après T5, T9
- §2.12. **Tests** : combat simulé (Smogogo de Koga → Toxik → dégâts croissants) ; changement ;
  fin de combat ; IA.

#### T19 — A : Koga, Badge Âme, CT06 — après T17, T18
- Scènes, rattrapage, Grand moment. **Tests** : badge et CT uniques ; défaite → Centre, Koga
  rejouable ; `badge_soul` rend `FieldMoves.surf` « prêt » (sans effet de monde).

#### T20 — Q : **session 23E** → K

### 3.6 Sous-jalon 23F (clôture)

#### T21 — A : simulation et équilibrage
- Koga (bande « grand combat » 35–60 %), Dresseurs (≤ 80 % au premier essai) ; niveaux seulement
  (jamais les attaques sans Kevin).

#### T22 — A : non-régression et interruptions
- Suite complète ; sauvegarde / rechargement à chaque transition du jalon.

#### T23 — Q : **QA de bout en bout** → K
- Parmanie → Parc (une visite : CS03, Dents d'Or) → Gardien → Koga → exploration libre.

#### T24 — A : clôture
- Retrait des départs `*_qa` ; passation au J24 (section « Clôture » ajoutée à ce plan) ; fusion de `jalon-23` dans `main`
  après validation de Kevin.

---

## 4. Tests automatiques (récapitulatif)

Voir dossier 26 §15 ; chaque tâche ci-dessus nomme ses fichiers de test. Contrôle des grilles :
`python3 tools/art/plan_check_safari.py` (raccords, herbes, objets, « une visite suffit », rocher du
Gardien, Arène).

## 5. Risques

| Risque | Parade |
|---|---|
| Fusion J16 → J22 tardive | Tout le 23.0 avance avant ; T9 est la seule porte |
| Conflits sur `cutscene_step.gd`, `battle_*.gd`, `save_system.gd` avec le J22 ou le J24 | Ajouts en fin, blocs « J23 » courts ; règle d'ancienneté (§0.1) |
| Version de sauvegarde prise par un autre jalon | T9 fixe le numéro ; migration écrite contre la version réelle |
| Fuite trop fréquente (Tauros, Insécateur : RB) | Voulu (RB, N-5) ; QA 23B note le ressenti, aucune retouche sans Kevin |
| Murs invisibles frustrants sur téléphone | Indices N-15 ; QA 23E mesure le temps et les chocs d'un testeur qui ne connaît pas la carte |
| Quatre grandes cartes peintes : mémoire et fps | Mesure en 23A (fps, mémoire de textures) ; découpe des vues si besoin |

## 6. Valeurs par défaut de ce plan (règle 4)

- Pépite déplacée en (14, 16) (§0.4) ; critère « une visite suffit » sans le retour (233 pas).
- Taux de rencontre ≈ 11,7 % par pas, sans rampe.
- Haut-parleur : bulle sans locuteur ; libellé « PSN+ ».
- Départs de débogage du §2.16.
- Joueur dans le Parc sans visite au chargement → renvoyé à la Porte.

---

## Annexe A — Textes complémentaires (T2, **validés par Kevin le 2026-10-19** : « annexe A ok »)

> Complète le §8 du dossier 26 (textes 1 à 59, validés). Bulles de 2 lignes d'environ 40
> caractères ; « / » sépare deux bulles. Inspirés des textes RB (`pret/pokered` `text/SafariZone*.asm`,
> `WardensHouse.asm`, `FuchsiaGym.asm`), jamais traduits mot à mot. Réponse attendue :
> « A-7 : … » ou « annexe A ok ».

### A.1 Panneaux du Parc (grilles v1)

| N° | Panneau (grille) | Texte |
|---|---|---|
| A-1 | Centre, maison de repos (18, 20) ; idem Est (26, 10), Nord (36, 4), Ouest (12, 12) | « MAISON DE REPOS » |
| A-2 | Centre, conseils (14, 22) | texte 13 du dossier (« PARC SAFARI — ZONE CENTRE » / « Respectez les Pokémon… ») |
| A-3 | Est, conseils (6, 4) | « CONSEIL DE DRESSEUR » / « Le compteur ne baisse que quand tu marches ! » |
| A-4 | Est, zone (5, 23) | « PARC SAFARI — ZONE EST » / « Ouest : ZONE CENTRE » |
| A-5 | Nord, conseils 1 (4, 25) | « CONSEIL DE DRESSEUR » / « La Maison Secrète est encore plus loin ! » |
| A-6 | Nord, zone (13, 31) | « PARC SAFARI — ZONE NORD » / « Sud : ZONES OUEST et CENTRE » |
| A-7 | Nord, conseils 2 (19, 33) | « CONSEIL DE DRESSEUR » / « Les Pokémon se cachent dans les herbes. » / « Zigzague pour les débusquer ! » |
| A-8 | Nord, conseils 3 (26, 28) | « GRANDE EXPLORATION ! » / « Qui trouvera la Maison Secrète ? » |
| A-9 | Ouest, dents du Gardien (17, 3) | texte 14 du dossier (« Avis : le Gardien a perdu ses dents en or. » / « Merci de les lui rapporter ! ») |
| A-10 | Ouest, conseils (26, 4) | « CONSEIL DE DRESSEUR » / « Une CS en prix pour qui trouve » / « la Maison Secrète ! » |
| A-11 | Ouest, zone (24, 22) | « PARC SAFARI — ZONE OUEST » / « Est : ZONE CENTRE » |
| A-12 | Le titre de zone affiché à l'arrivée | « PARC SAFARI — ZONE CENTRE », « — ZONE EST », « — ZONE NORD », « — ZONE OUEST » ; Porte : « PARC SAFARI » ; Maison Secrète : « MAISON SECRÈTE » |

### A.2 Maison du Gardien

| N° | Élément | Texte |
|---|---|---|
| A-13 | Vitrine, moitié gauche (5, 2) | « Des photos de Pokémon et des fossiles. » |
| A-14 | Vitrine, moitié droite (6, 2) | « De vieux souvenirs du Parc Safari. » |

### A.3 Arène de Koga : six Dresseurs (avant / défaite / après)

| N° | Dresseur (grille) | Avant | Défaite | Après |
|---|---|---|---|---|
| A-15 | Jongleur Hugo (10, 14) | « Mes balles volent, mon Hypnomade veille ! » | « Raté… j'ai tout fait tomber. » | « Koga voit tout. Même ce qu'on ne voit pas. » |
| A-16 | Jongleur Max (9, 9) | « Un, deux, trois… à toi de jongler ! » | « Trop de balles en l'air ! » | « Les murs ? Quels murs ? Moi, je ne vois rien. » |
| A-17 | Jongleur Sacha (3, 13) | « Tu cherches ton chemin ? Cherche-moi plutôt ! » | « Bien joué. » | « Avance à petits pas. Écoute le parquet. » |
| A-18 | Dompteur Bruno (5, 6) | « Mes Pokémon obéissent au fouet… et au sifflet ! » | « Ils n'ont rien écouté ! » | « Koga ne dompte pas : il commande. » |
| A-19 | Dompteur Edgar (10, 3) | « Arbok ! Montre-lui tes crocs ! » | « Couché, Arbok… » | « Le poison, c'est de la patience. » |
| A-20 | Jongleur Léon (4, 8) | « Hop ! Tu ne me verras pas venir ! » | « Tu m'as vu venir… » | « Le maître est juste derrière, au centre. » |

Prénoms [D], à vérifier contre les Dresseurs déjà nommés (aucun doublon dans une même carte ; un
doublon ailleurs est accepté s'il n'y a pas de confusion).

### A.4 Descriptions (Sac, combat)

| N° | Élément | Texte |
|---|---|---|
| A-21 | Surf (capacité) | « Une énorme vague déferle sur la cible. Permettra aussi de nager sur l'eau. » |
| A-22 | Force (capacité) | « Le lanceur frappe la cible de toute sa puissance. Permettra aussi de pousser les rochers. » |
| A-23 | Bomb'Œuf (capacité et CT37) | « Le lanceur projette violemment un gros œuf sur la cible. » |
| A-24 | Reflet (capacité et CT32) | « Le lanceur se démultiplie par des mouvements rapides. Augmente son esquive. » |
| A-25 | Toxik (capacité) | « Un poison qui s'aggrave à chaque tour. » |
| A-26 | Pastille du Parc | icône de pas + nombre, icône de Ball + nombre ; aucun texte (lecteur d'écran : « {n} pas, {m} Safari Balls ») |
| A-27 | Statut de combat | « PSN+ » (poison grave), à côté de « PSN » |

« Permettra » (A-21, A-22) : au J23, Surf et Force ne servent qu'en combat (P-2 B) ; la description
n'annonce pas un usage immédiat. Les textes 56 à 59 du dossier (Sac : CS03, CS04, Dents d'Or,
CT06) restent ceux validés.
