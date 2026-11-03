# Jalon JOH0 — Systèmes du Chapitre Johto

> **PLAN — aucun code n'est écrit par ce document.** Sources de vérité :
> `docs/design/dossier-joh-00-cadre.md` (cadre, JH-1 à JH-20 tranchés) et
> `docs/design/dossier-joh-01-systemes-joh0.md` (JOH0, JH-21 à JH-24 tranchés par Kevin le
> 2026-11-02 ; le reste du dossier porte des défauts **[D]**). Écrit le 2026-11-03 sur la branche
> `claude/joh0-systemes` (depuis `main` @ `0b80db1d`), à l'ouverture du code Johto décidée par
> Kevin le 2026-11-03 (« commençons sur une branche »).

> Objectif : **tout ce dont les jalons de contenu JOH1 à JOH9 ont besoin, en une passe de
> systèmes**, pour qu'ensuite une route, une ville ou un donjon de Johto ne soit plus que des
> données et des cartes (`strategie-acceleration.md`, levier 1). Rien de visible pour un joueur
> de Kanto : ni heure, ni lumière de Johto, ni Pokémon de Johto dans ses tables (JH-8).
>
> Règle 1 de `CLAUDE.md` : **la sauvegarde v10 (équipe confisquée, Stockage hors ligne,
> migration) se valide seule (JOH0A)** ; le reste part en un lot (JOH0B à JOH0D), jamais trois
> systèmes à la fois dans une même validation.

## 0. État des lieux (relu sur `main` @ `0b80db1d`, 2026-11-03)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Heure | `WorldClock` (`game/systems/day_night/world_clock.gd`) : classe pure, **inactive**, minutes avancées à la main ; la puce du Menu Dresseur (`TrainerMenu.set_clock`) l'interroge | On l'active sur l'heure du téléphone (`DeviceClock`), on ajoute les moments et les jours |
| Lumière | `LightingLibrary` (profils de `data/world/lighting.json`), `WorldLighting.apply(profile, map)` appelé par `Boot._apply_lighting` au changement de carte ; `GameMap.light_profile` | 3 profils neufs, résolution `johto_auto` → profil du moment, fondu de 10 s |
| Rencontres | `EncounterLibrary` : **une table par (carte, terrain)**, clés `maps`, `terrain`, `rate`, `slots`, `ramp`, `ghost_unless_item` | Clé facultative `period`, index (carte, terrain, moment) |
| Régions | `ZoneLibrary` (`zones.json`) sans région ; `FlyRules` lit `fly_points.json` ; `MapScreen` affiche **une** illustration (`MapIllustration`, `kanto_placeholder_areas.json`) | `region` par zone, points de Vol avec région, seconde page de Carte |
| Sauvegarde | `SaveSystem.VERSION = 9` ; migrations additives depuis la v4 (« rien à transformer », défauts dans `GameState.load_dict`) ; champs facultatifs écrits seulement s'ils disent quelque chose (`mount`, `safari`, `hall_of_fame`) | **v10** : `bond` par Pokémon, `egg_steps`, section `confiscated` |
| Équipe, Sac, Stockage | `Party` (6), `Bag` (quantités, favoris, rangs), `PokemonStorage` (sans limite), `StorageRules` (refus), `companion_uid` | Le vol et le retour sont des opérations pures sur ces objets |
| Pokémon | `Pokemon` : `uid`, `status`, `favorite`, rencontre ; `to_dict` / `from_dict` tolérants | `bond`, `egg_steps`, `Origin.EGG` |
| Évolutions | `EvolutionRule.Method { LEVEL, ITEM, TRADE }` ; `Evolution.level_up_target` (fin de combat, Pension, Super Bonbon) ; `LocalTrade` (J32) déclenche TRADE au terminal des Centres | Méthode `BOND` (+ `period`), `item` facultatif sur TRADE |
| Expérience | `BattleRules.exp_multiplier` (1,0 sauvage, 1,5 Dresseur, 0 Safari), `ExpCalc.amount(foe, data, multiplier)` | Bonus ×1,5 de l'acte 1 multiplié par-dessus |
| Pokédex | `PokedexLibrary` : un fichier, `size` = taille de la grille ; `PokedexQuery.slots` parcourt `1..size` ; diplôme par variante `if_caught_at_least` | 202 espèces, liste continue (JH-22), filtre Kanto / Johto / Tout, compteur de Johto pour le diplôme |
| Données | 151 espèces, 164 attaques ; effets connus : 33 sortes (`stat_stage`, `status`, `flinch`, `drain`, `hits`…) ; familles d'effets visuels `data/battle/move_fx/families.json` | 51 espèces et ≈ 40 attaques de plus, chacune rattachée à une famille |
| Starter | `StarterOffer.load_file(path)` (un fichier, une carte) ; `StarterChoice` | Le JOH1 chargera une seconde offre (`starters_johto.json`) : rien à changer au JOH0 |
| Scènes | `CutsceneStep.Kind` : `GIVE`, `TAKE`, `GIFT_POKEMON`, `SAVE`, `TRADE`… | Deux étapes neuves : `CONFISCATE_TEAM`, `RETURN_TEAM` |
| Pas du joueur | `Player.moved(cell)` ; `DaycareStepCounter.on_player_moved(daycare, input_enabled)` | Même modèle pour le lien et l'œuf |
| Combat | `BattleDirector.battle_finished(trainer_id, outcome)`, `get_exp_summary()` (participants), journal d'événements `FAINTED` côté joueur | Gains et pertes de lien lus à la fin du combat |

Seule retouche de Kanto prévue pour Johto : le poste de la Route 28 sur `tools/plans/route_22_ouest.txt`
(variante `JOH9` de la grille), **hors JOH0** (au code du JOH9).

## 1. Découpage

### 1.1 Sous-jalons

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH0A** | Sauvegarde **v10** (`bond`, `egg_steps`, `confiscated`), migration 9 → 10, équipe confisquée (vol et retour, opérations pures + étapes de scène + départ de débogage), Stockage et terminal hors ligne, lancer refusé à 6 (JH-23), choix des 6 au retour (JH-24) | **Seule** (système risqué) : CI verte, puis relecture de la vraie sauvegarde de Kevin (copie, A17) |
| **JOH0B** | Heure réelle (`WorldClock` : 3 moments, 7 jours, moment forcé), 3 profils de lumière, `johto_auto`, fondu de 10 s, lumières de nuit, rencontres par moment, conditions `if_period` / `if_weekday` des dialogues et PNJ | Lot (captures matin / jour / nuit sur une carte de test) |
| **JOH0C** | Lien (`bond`, gains et pertes), évolutions `bond` (+ `period`) et `trade` + objet, œuf et éclosion, Exp ×1,5 de l'acte 1 | Lot |
| **JOH0D** | Données des 51 espèces et de leurs attaques, Pokédex 202 en liste continue + filtre + compteur de Johto, régions (`region`), Carte à deux pages, Vol entre régions | Lot |

JOH0B, JOH0C et JOH0D sont validés **en un seul lot** par Kevin (dossier JOH-00 §10 : « le reste en
un lot ») ; ils sont découpés ici pour l'ordre du travail et les tests ciblés, pas pour des
validations séparées.

### 1.2 Ordre

1. JOH0A en entier, CI verte, **proposé seul à Kevin** ; le reste commence pendant l'attente
   (règle 5 de `strategie-acceleration.md`), sur la même branche, **sans toucher à nouveau au
   format de sauvegarde**.
2. JOH0D-données (51 espèces, attaques) par sous-agents Sonnet, en parallèle de JOH0B.
3. JOH0B, JOH0C, puis le reste de JOH0D.
4. CI verte sur l'ensemble, état du projet, prompt de reprise du JOH1.

### 1.3 Fichiers partagés (conflits attendus avec les branches ouvertes)

`game/boot.gd` (branchements), `game/autoload/game_state.gd`, `game/pokemon/pokemon.gd`,
`game/systems/save/save_system.gd`, `data/world/lighting.json`, `data/world/zones.json`,
`docs/tech/etat-projet.md`. Les branches encore ouvertes de Kanto (`claude/entree-finitions`,
`claude/reportes-fx-j33`, `claude/menu-peint-reliquats`, `claude/j34-logo`) ne touchent ni la
sauvegarde ni les Pokémon : conflits limités à `boot.gd` et à l'état du projet.

## 2. Conception technique

### 2.1 Sauvegarde v10 (JOH0A)

- `SaveSystem.VERSION = 10` ; `_upgrade_9_to_10(content)` : pose `bond: 50` sur chaque Pokémon de
  `party`, `storage` et `daycare.pokemon` qui n'en a pas (dossier JOH-01 §12 : « Pokémon déjà
  présents à la migration : 50 »). Rien d'autre : `egg_steps` absent = pas un œuf, `confiscated`
  absent = rien de confisqué (`GameState.load_dict`), comme tous les champs facultatifs depuis la
  v7 **[D]** (le dossier dit « ajoute `confiscated` vide » ; la convention du projet est qu'un
  champ facultatif absent vaut son défaut et n'est écrit que s'il dit quelque chose : une partie
  de Kanto garde exactement son fichier d'avant, `bond` en plus).
- `Pokemon.bond: int` (0..100, défaut **50** à la lecture d'un fichier sans la clé, borné) ;
  `Pokemon.egg_steps: int` (0 = pas un œuf ; écrit seulement si > 0) ; `Origin.EGG` (« egg »,
  **en fin d'enum**). `to_dict` écrit toujours `bond`.
- `GameState.confiscated: ConfiscatedTeam` (`game/systems/johto/confiscated_team.gd`, classe
  pure) : `party: Array[Pokemon]`, `items: Dictionary[StringName, int]`, `companion_uid: String` ;
  `is_empty()`, `to_dict()` / `from_dict(dict, data)` (Pokémon invalide → section vide **et** faux,
  comme la Pension : Boot copie l'original en `save.json.rejected`). Écrite dans le fichier
  **seulement si non vide**. Les `uid` des Pokémon confisqués entrent dans
  `ensure_unique_uids()` (après la Pension).
- Drapeaux d'histoire ordinaires (aucun format) : `storage_offline`, `johto_act1`,
  `johto_team_returned`, `johto_arrived`.
- Une build v9 refuse un fichier v10 (comportement actuel de `SaveSystem.read`).
- **Tests** : aller-retour v10 ; `{"version": 9}` → `{"version": 10}` seul ; une v9 complète
  (nouvelle partie + équipe + Stockage + Pension) migre avec `bond = 50` partout et **mêmes
  Pokémon, même ordre** ; les fixtures réelles `v6_kevin_s21.json` et `v6_kevin.json` traversent
  6 → 10 sans entrée écartée et se réécrivent à l'identique (champs de la v6 + `daycare` + `bond`) ;
  `bond` hors bornes ou absent → 50 ; `egg_steps` négatif → 0 ; `confiscated` absent, vide,
  mal formé, avec un Pokémon invalide ; v11 refusée. **Vraie sauvegarde de Kevin** : copie
  relevée sur l'A17 au moment de la validation (la dernière fixture réelle est une v6 ; la v9
  d'aujourd'hui sera ajoutée en fixture `v9_kevin_a17.json` si Kevin l'accorde).

### 2.2 Équipe confisquée (JOH0A)

`TeamConfiscation` (`game/systems/johto/team_confiscation.gd`), statique et pur, reçoit l'état de
partie (l'autoload en jeu, une instance de `game_state.gd` en test) et la bibliothèque d'objets :

- `confiscate(state, items) -> bool` (**une seule opération synchrone**, dossier §6.2) : copie
  l'équipe (mêmes objets `Pokemon`) et les objets **non clés** du Sac (catégorie ≠ `key`, CT
  comprises **[D]** : une CT est un objet du Sac, pas une clé ; le Multi Exp, le Vélo et les
  cannes sont des objets clés et restent) dans `confiscated`, vide l'équipe, retire ces objets du
  Sac (favoris et rangs gardés : ils reviendront favoris), efface `companion_uid`, lève
  `storage_offline` et `johto_act1`. Faux (rien ne change) si `confiscated` n'est pas vide.
- `restore(state, kept: Array[String]) -> Dictionary` : `kept` = identifiants (`uid`) des Pokémon
  gardés (1 à 6, au moins un **en état de combattre**, pris dans l'équipe de Johto **ou** dans
  l'équipe confisquée) ; les autres vont au **Stockage**, dans l'ordre : équipe de Johto puis
  équipe confisquée **[D]** ; les Sacs fusionnent (quantités additionnées) ; `confiscated` vidé ;
  `storage_offline` et `johto_act1` baissés, `johto_team_returned` levé ; compagnon : celui
  d'avant le vol s'il est gardé, sinon le premier de l'équipe gardée **[D]**. Rend `{ok, stored,
  companion}`. Faux si `confiscated` est vide ou si `kept` est invalide : rien ne change.
- `TeamReturnSelection` (pur) : la **réserve** (équipe de Johto puis confisquée, chacun avec son
  origine), la sélection (ordre de touche), `can_confirm()` (1 à 6, un apte),
  `default_selection()` = l'équipe de Johto **puis** la confisquée jusqu'à 6 **[D]** (la liste
  présentée a 12 Pokémon au plus).
- **Écriture unique** : l'opération est synchrone ; la scène la fait suivre d'une étape `SAVE`
  (étape existante, J16) : avant l'écriture, le fichier est entièrement « avant », après,
  entièrement « après ». Test dédié : un autosave ne peut pas tomber au milieu (aucun `await`).
- Étapes de scène (`CutsceneStep.Kind`, en fin d'enum) : `CONFISCATE_TEAM` (le vol) et
  `RETURN_TEAM` (le retour : ouvre l'écran de sélection, attend la confirmation, applique). Une
  scène refuse `CONFISCATE_TEAM` si l'équipe est vide ou si `confiscated` n'est pas vide
  (erreur de chargement).
- Écran de sélection du retour (`TeamReturnScreen`, `game/ui/johto/`) : liste des 12 Pokémon
  au plus (nom, niveau, icône, provenance « Johto » / « Kanto »), cases à cocher, compteur
  « 4 / 6 », bouton VALIDER actif selon `can_confirm()`, pas de retour Android (le choix est
  obligatoire) ; thème 2026 ; DA en phase DA. Sans écran (tests) : `default_selection()`.
- **Stockage hors ligne** (`storage_offline` levé) : `open_storage` (terminal du Centre) et
  `open_local_trade` répondent par le dialogue `storage_offline` (« Le réseau de Kanto ne répond
  pas. ») **[D]** au lieu d'ouvrir l'écran ; le Menu Dresseur ne propose rien de plus (le
  Stockage n'y a pas d'entrée).
- **Lancer refusé à 6** (JH-23) : `CaptureGate.can_throw(party_full, storage_offline)` ; en
  combat, le choix d'une Ball avec l'équipe pleine et le Stockage hors ligne est refusé **avant
  le lancer**, texte « Ton équipe est pleine, et le PC ne répond pas. » (`data/battle/messages.json`),
  la Ball n'est pas consommée, le tour n'est pas joué.
- **Départ de débogage** `johto_confiscated` (`tests/fixtures/debug_start/`) : équipe de Ligue
  confisquée, équipe de Johto de 2 Pokémon, `storage_offline`, à Bourg Palette (la carte
  d'Oliville n'existe pas encore) ; la scène de test `johto_return_test` (données) enchaîne
  `RETURN_TEAM` puis `SAVE`.
- Hors périmètre du JOH0A : la mise en scène du vol à Oliville, Orme, le choix du Pokémon de
  départ de Johto (JOH1), la Tour Radio (JOH5).

### 2.3 Heure (JOH0B)

- `WorldClock` garde son état « minutes depuis minuit » et gagne : `Period { MORNING, DAY,
  NIGHT }` (`period_of(hour)` : 4–9 matin, 10–17 jour, 18–3 nuit), `period()`, `weekday()` (0 =
  lundi … 6 = dimanche, noms `WEEKDAYS`), `PERIOD_NAMES`, signal `period_changed(period)`.
- **Heure réelle** : `start_on_device(clock: DeviceClock)` lit `Time.get_datetime_dict_from_system`
  via une méthode de `DeviceClock` (`now_dict()`, injectable : `FixedClock` rend une date fixe
  avancée à la main) ; `sync()` relit l'appareil et émet `period_changed` si le moment a changé ;
  Boot appelle `sync()` **une fois par seconde** (Timer) et à chaque changement de carte.
- **Moment forcé** (scènes) : `force_period(period)` / `release_period()` ; `period()` rend le
  moment forcé tant qu'il l'est ; la fin d'une scène qui a forcé libère **[D]** (le JOH1 posera
  l'étape de scène `FORCE_PERIOD`, hors JOH0).
- **Portée** (JH-8) : l'horloge tourne partout ; `Boot` ne la **lit** (lumière, rencontres,
  évolutions, puce du menu) que si la région de la carte est `johto` (`ZoneLibrary.region_of`).
  La puce du Menu Dresseur : `TrainerMenu.set_clock_shown(bool)` posé par Boot à chaque carte ;
  texte « 14:32 » + pictogramme du moment (3 icônes SVG provisoires, `assets/ui/icons/menu/`).
- Changement d'heure du téléphone : accepté tel quel **[D]**.

### 2.4 Lumière de Johto (JOH0B)

- `data/world/lighting.json` : `johto_morning` (lumière rasante froide, liseré pâle, ombres
  longues, brume légère), `johto_day` (lumière blanche, ombres courtes, liseré faible),
  `johto_night` (étalonnage bleu, ombres très douces, **pas de liseré**, `cast_shadow` absent).
  Valeurs de départ **[D]**, réglées sur captures (les captures matin / jour / nuit font partie du
  lot de validation).
- **`johto_auto`** : identifiant réservé (`LightingLibrary.AUTO_PROFILE`), jamais un profil ;
  `LightingLibrary.resolve(id, period) -> StringName` rend `johto_<moment>` pour `johto_auto`,
  l'identifiant tel quel sinon ; `Boot._apply_lighting(map)` passe par `resolve` avec le moment
  courant. Une carte intérieure garde son profil fixe.
- **Fondu de 10 s** : `LightProfile.lerp(a, b, t)` (statique, pur : gains, couleurs, intensités,
  alphas, longueur, inclinaison, vent interpolés ; `flat` et `room` pris de `b`) ;
  `WorldLighting.blend_to(profile, map, seconds)` : Tween qui réapplique l'interpolation à chaque
  image (globals + étalonnage), les ombres portées retransformées **à la fin seulement** **[D]**
  (leur transformation parcourt la carte). Immédiat (`apply`) à l'arrivée sur une carte ; fondu
  (`FADE_SECONDS = 10.0`) quand `period_changed` arrive sur une carte `johto_auto`.
- **Lumières de nuit** : groupe `night_lights` (nœuds posés dans les cartes de Johto, JOH1+) ;
  `WorldLighting.set_night(bool)` montre / cache le groupe de la carte courante ; appelé avec
  `period == NIGHT` après `apply` / `blend_to` sur une carte `johto_auto`, caché ailleurs.

### 2.5 Rencontres par moment (JOH0B)

- Clé facultative `period` d'une table : `"morning"`, `"day"`, `"night"` ou une liste non vide de
  ces valeurs ; l'index devient (carte, terrain, moment) ; une table sans `period` couvre les
  trois moments. **Erreur au chargement** si, pour une même carte et un même terrain, une table
  sans `period` coexiste avec une table avec `period`, ou si deux tables couvrent le même moment.
- `get_table(map, terrain, period = &"")` : la table du moment si elle existe, sinon la table
  de toute la journée ; `has_table` pareil. `EncounterDirector.period_source: Callable` (posé par
  Boot : le moment courant si la carte est à Johto, `&""` sinon) ; Kanto n'a aucune table datée,
  son tirage est inchangé octet pour octet (test : même séquence sur la Route 1 avec et sans
  source).
- Départs de débogage : `wild` accepte `period` dans sa table forcée.

### 2.6 Dialogues et PNJ datés (JOH0B)

- `DialogueVariant` : `if_period` (un moment ou une liste) et `if_weekday` (un jour ou une
  liste) ; `Dialogue.pick` reçoit `period` et `weekday` (défauts : « aucune condition » pour
  Kanto) par un `time_source: Callable` du `DialogueRunner`, nul à Kanto.
- `NpcSpec` : mêmes clés `if_period` / `if_weekday` sur la présence du PNJ (lu à l'entrée sur la
  carte **[D]** : un PNJ ne disparaît pas sous les yeux du joueur ; il manque au prochain
  chargement de la carte).
- Les sept PNJ de la semaine, le Grand Magasin et le Lokhlass du vendredi sont du **contenu**
  (JOH3 à JOH7) : ils n'utilisent que ces clés.

### 2.7 Lien (JOH0C)

- `BondRules` (`game/pokemon/bond_rules.gd`, statique, pur) : `MIN 0`, `MAX 100`, `THRESHOLD 70`,
  départs `START_CAPTURE 20`, `START_GIFT 50` (starter, cadeau, échange fixe, œuf éclos),
  `WIN_GAIN 2`, `STEPS_PER_POINT 256`, `COMPANION_BONUS 1`, `FAINT_LOSS 3` **[D]**.
- Départ posé par `GameState.stamp_meeting(pokemon, kind, map)` selon l'origine (c'est là que
  l'origine est connue) ; `PokemonFactory` laisse 50 (défaut d'un Pokémon sans rencontre).
- **Pas** : `BondStepCounter` (même modèle que `DaycareStepCounter`) : à chaque `Player.moved`
  avec l'entrée libre, compte ; tous les 256 pas, `+1` à chaque Pokémon de l'équipe (œufs
  exclus), `+1` de plus au compagnon. Le compteur **n'est pas sauvegardé** **[D]** (moins de 256
  pas perdus à la fermeture).
- **Combat** : `BondRules.apply_battle(party, outcome, participants, fainted)` : victoire →
  `+2` à chaque participant (`ExpSummary.get_entries()` : ceux qui ont gagné de l'XP) ; `−3` à
  chaque Pokémon du joueur tombé K.O. pendant le combat (événements `FAINTED` côté joueur, un
  par K.O.). Boot l'appelle dans `_on_battle_finished` (défaites comprises : seules les pertes
  s'appliquent). Le Safari (aucun combat) ne touche pas au lien.
- Pas de raccourci (objets, Centre) **[D]** ; pas de jauge (JH-21) ; le PNJ de Doublonville aux
  4 paliers est du contenu (JOH3) : `BondRules.tier(bond)` (0..3) le sert déjà.

### 2.8 Évolutions neuves (JOH0C)

- `EvolutionRule.Method.BOND` (`"bond"`, en fin d'enum) avec clé facultative `period` (un moment
  ou une liste) ; `Method.TRADE` accepte une clé facultative `item`.
- `Evolution.level_up_target(pokemon, data, period = &"")` : une règle `bond` est satisfaite si
  `bond ≥ 70` et (`period` de la règle vide, **ou** `period` passé non vide et dans la règle).
  Boot passe le moment seulement à Johto (§2.3) : à Kanto, Évoli n'évolue ni en Mentali ni en
  Noctali **[D]** ; Togepi, Leveinard, Nosferalto évoluent partout. Tous les chemins existants
  (fin de combat, Pension, Super Bonbon) reçoivent le moment par la même source.
- `LocalTrade.trade_target(pokemon, data, bag = null)` : une règle TRADE **avec** `item` ne
  compte que si le Sac contient l'objet ; `execute(...)` reçoit le Sac et **consomme l'objet**
  dans le même bloc synchrone que l'évolution (jamais un objet consommé sans évolution). Le
  `LocalTradeDirector` demande « Utiliser une Peau Métal ? » (dialogue `trade_terminal_item`,
  jeton `{item}`) avant la confirmation habituelle **[D]**.
- Objets neufs (`data/items/items_johto.json`, catégorie `field` sans `field_use` : se consultent,
  sans UTILISER) : `metal_coat` Peau Métal, `kings_rock` Roche Royale, `dragon_scale` Écaille
  Draco, `up_grade` Améliorator ; prix 0 (jamais en Boutique) ; icônes du Sac provisoires.
- Règles de données : Togepi → Togetic (`bond`), Leveinard → Leuphorie, Nosferalto → Nostenfer,
  Évoli → Mentali (`bond`, `["morning", "day"]`) et Noctali (`bond`, `night`) ; Onix → Steelix
  (`trade` + `metal_coat`), Insécateur → Cizayox, Ramoloss → Roigada (`kings_rock`), Têtarte →
  Tarpaud, Hypocéan → Hyporoi (`dragon_scale`), Porygon → Porygon2 (`up_grade`). Les règles de
  Kanto existantes ne changent pas (Évoli garde ses trois pierres).

### 2.9 Œuf (JOH0C)

- `Pokemon.is_egg()` = `egg_steps > 0`. Un œuf : compte dans les 6, **sauté** par
  `Party.first_able()` / `has_able()` (un œuf n'est jamais apte), exclu des participants et de
  la répartition d'XP (`ExpCalc.distribute` ignore les œufs), refusé comme compagnon
  (`GameState.set_companion`), refusé en remplacement en combat (`BattlePartyPanel` : « Un œuf
  ne peut pas combattre. ») **[D]**, visible dans l'Équipe avec une icône d'œuf et la phrase du
  reste (`EggRules.hint_text(steps)` : > 1 000 « Il a l'air bien tranquille. », 1 000–301
  « Il bouge un peu. », ≤ 300 « On l'entend remuer ! ») **[D]**, ni favori ni libérable au
  Stockage tant qu'il est un œuf **[D]** (il se dépose).
- `EggRules.create(species, steps, data, rng)` : un Pokémon de niveau 5 **déjà tiré** (IV, sexe,
  capacités du niveau 5) avec `egg_steps` ; Pokédex non touché. Étape de scène `GIVE_EGG`
  (`species`, `steps`, défaut 2 000) **[D]** pour le JOH3.
- `BondStepCounter.on_player_moved` décrémente `egg_steps` de chaque œuf de l'équipe ; à 0,
  Boot joue l'**éclosion** au pas suivant hors combat, hors scène, hors menu :
  `EggHatching` (coroutine, pure dans sa logique) : bannière « Oh ? … L'œuf a éclos : c'est
  Togepi ! », `Origin.EGG`, rencontre datée, `bond = 50`, Pokédex vu + capturé, autosave. Sans
  écran (tests) : immédiat.

### 2.10 Expérience de l'acte 1 (JOH0C)

- `JohtoAct1.exp_bonus(flags) -> float` : 1,5 si `johto_act1`, 1,0 sinon ;
  `BattleDirector.exp_bonus_source: Callable` ; le multiplicateur des règles du combat est
  multiplié par le bonus à la création du moteur (`request.rules.exp_multiplier *= bonus`) :
  ×1,5 sauvage, ×2,25 Dresseur, 0 Safari (dossier §10).
- Multi Exp : déjà un objet clé (lot 32P), gardé au vol ; le don de la Tour Radio est du contenu
  (JOH5).

### 2.11 Données de Johto (JOH0D, Sonnet)

- `data/pokemon/species/johto.json` : les 51 espèces (152 Germignon → 251 Celebi, liste du
  dossier JOH-00 §6 avec Écrémeuh) : `dex` national, `name` français, `types` et `base_stats`
  **modernes**, `male_ratio`, `growth_rate`, `base_exp`, `catch_rate`, `learnset` **d'Or/Argent**
  (montée de niveau), `evolutions` (§2.8 ; Évoli de Kanto reçoit ses deux règles `bond`).
  Source : PokeAPI (`gold` / `silver`), comme Kanto.
- `data/pokemon/moves/johto.json` : les attaques des learnsets qui manquent (≈ 40, dossier §13) ;
  chacune typée, avec ses effets dans les sortes existantes ; un effet qui n'existe pas dans le
  moteur part en `pending_effects` (comme au J11), **jamais inventé** ; `tools/audit_moves.py`
  (nouveau, lecture seule) liste les attaques des 51 learnsets absentes des données.
- `data/battle/move_fx/families.json` : chaque attaque neuve rattachée à une famille existante
  (test de données : aucune attaque sans famille).
- `data/pokedex/johto.json` : `size: 51`, taille, poids, description française (`draft: true`
  tant que Kevin ne les a pas relues) ; `PokedexLibrary.load_dir()` additionne les `size` (202) ;
  `check_references` : numéro ≤ 251 (`MAX_DEX` national, plus « ≤ size »).
- `data/pokemon/companions.json` : aucune espèce de Johto (il n'y a pas de planche validée) : un
  starter de Johto compagnon n'a pas d'apparence tant que l'art n'existe pas (le compagnon reste
  dans sa Ball, règle du 11D) ; à noter dans « Reportés ».
- Art : artwork officiel 152–251 et dos repeints **hors JOH0** (levier 4 : lot d'art, pas de
  blocage du code) ; en attendant, l'artwork manquant tombe sur le substitut existant.

### 2.12 Pokédex 202 (JOH0D)

- `PokedexQuery.slots` parcourt les **espèces des données triées par numéro** (liste continue,
  JH-22) au lieu de `1..size` : 151 cases de Kanto puis les 51 de Johto, sans trou ; une case
  inconnue garde son numéro national (« N° 152 »).
- Filtre **région** : `PokedexQuery.Region { ALL, KANTO, JOHTO }` (`PokedexRegions.of_dex` :
  ≤ 151 Kanto, sinon Johto), bouton « Région : Tout » à côté du bouton de type, visible seulement
  quand une espèce de Johto est **vue** **[D]** ; compteur « vus · capturés · 202 espèces ».
- Diplôme de Johto : `Pokedex.caught_count_where(predicate)` ; `DialogueRunner.caught_johto_count:
  Callable` ; variante `if_caught_johto_at_least` / `unless_caught_johto_at_least` (mêmes règles
  que `if_caught_at_least`). Le dialogue d'Orme est du contenu (JOH1 / JOH9) ; le seuil 50 vit
  dans la donnée.

### 2.13 Régions, Carte et Vol (JOH0D)

- `ZoneData.region: StringName` (`"kanto"` par défaut, `"johto"`), clé `region` de `zones.json`
  (valeurs de `ZoneData.REGIONS`) ; `ZoneLibrary.region_of(map_id)` (`kanto` si la carte n'a pas
  de zone **[D]**), `zones_of_region(region)`.
- `FlyRules.Point.region` (de sa zone, posé par `check_references(zones)`) ; `destinations(
  discovered, region, cross_allowed)` : d'abord la région courante, puis l'autre si
  `cross_allowed` ; `FlyDirector.check(zone)` rend `Check.OTHER_REGION` (nouveau, en fin d'enum :
  « Trop loin pour voler d'ici. » **[D]**) quand la destination est dans l'autre région et que
  `johto_team_returned` n'est pas levé (JH-18). Les points de Johto (Oliville, Rosalia,
  Doublonville, Écorcia, Acajou) entrent dans `fly_points.json` avec leur zone (zones déclarées
  au JOH0 avec `maps: []`, remplies par les jalons de contenu).
- Carte à deux pages : `MapIllustration` devient **par région** (`assets/ui/map/johto_placeholder.webp`
  + `johto_placeholder_areas.json`, image provisoire dessinée par `tools/make_map_placeholder.py`
  à partir de la géographie du dossier JOH-00 §3) ; `MapView.region`, `MapView.regions` (pages
  disponibles) ; `MenuDirector` ouvre la page de la région courante ; bouton « Johto ▸ » /
  « ◂ Kanto » dans l'en-tête, visible seulement si `johto_arrived` **[D]** ; `MapScreen.REGION_TEXT`
  devient le nom de la page. La frise et le panneau ne montrent que les zones de la page.

## 3. Tâches

Chaque tâche : tests ciblés (`tools/test.sh --changed`), import headless sans erreur, état du
projet dans le même commit, push. **A** = JOH0A (seul), **B/C/D** = le lot.

| N° | Tâche | Sous-jalon | Qui |
|---|---|---|---|
| T1 | Plan (ce fichier), branche, état du projet | — | Opus |
| T2 | `Pokemon.bond`, `egg_steps`, `Origin.EGG` ; `ConfiscatedTeam` ; `GameState.confiscated` ; `SaveSystem` v10 et `_upgrade_9_to_10` ; tests de migration (fixtures v6 réelles → v10, v9 complète) | A | Opus |
| T3 | `TeamConfiscation.confiscate` / `restore`, `TeamReturnSelection`, `CaptureGate` ; tests (atomicité, objets clés gardés, favoris, compagnon, fusion des Sacs, Stockage au retour, lancer refusé) | A | Opus |
| T4 | Étapes de scène `CONFISCATE_TEAM`, `RETURN_TEAM` ; Stockage et terminal hors ligne (dialogue `storage_offline`) ; refus de la Ball en combat ; `TeamReturnScreen` ; départ de débogage et scène de test ; capture relue | A | Opus |
| T5 | CI verte, **validation de Kevin sur la copie de sa sauvegarde** (A17), fixture v9 réelle si accordée | A | Kevin |
| T6 | Données : 51 espèces, attaques manquantes, familles d'effets, Pokédex de Johto, objets ; `tools/audit_moves.py` ; tests de données | D | Sonnet ×2 (espèces + Pokédex ; attaques + familles) |
| T7 | `WorldClock` réel (moments, jours, forçage, `sync`), `DeviceClock.now_dict`, Timer de Boot, puce du menu avec pictogramme, portée Johto | B | Opus |
| T8 | 3 profils de lumière, `johto_auto`, `LightProfile.lerp`, `WorldLighting.blend_to`, lumières de nuit ; carte de test `johto_light_test` (copie d'une route de Kanto avec `johto_auto`) ; captures matin / jour / nuit | B | Opus |
| T9 | `period` des tables de rencontres, `period_source` ; `if_period` / `if_weekday` des dialogues et PNJ | B | Opus |
| T10 | `BondRules`, `BondStepCounter`, départs par origine, gains et pertes en combat | C | Opus |
| T11 | `Method.BOND` + `period`, `TRADE` + `item` ; `LocalTrade` et son directeur avec l'objet ; données d'évolution et objets | C | Opus |
| T12 | Œuf : `EggRules`, `GIVE_EGG`, exclusions (combat, compagnon, Stockage), éclosion, Équipe | C | Opus |
| T13 | Exp ×1,5 de l'acte 1 | C | Opus |
| T14 | `PokedexLibrary.load_dir`, liste continue, filtre région, compteur de Johto, variantes de dialogue | D | Opus |
| T15 | `region` des zones, points de Vol, `OTHER_REGION`, Carte à deux pages, illustration provisoire | D | Opus |
| T16 | CI verte sur le lot, état du projet, prompt de reprise du JOH1 | — | Opus |

## 4. Critères d'acceptation

### JOH0A (seul)
1. Une partie v9 (vraie sauvegarde de Kevin, copie) s'ouvre en v10 : **mêmes Pokémon, même
   ordre**, mêmes objets, argent, badges, drapeaux, Pension, Panthéon ; `bond = 50` partout ;
   un seul avertissement de migration (« sauvegarde v9 → v10 »).
2. L'APK 0.34.0 (v9) **refuse** le fichier v10 sans l'écraser.
3. Départ `johto_confiscated` : l'équipe est celle de Johto ; le PC du Centre répond « Le réseau
   de Kanto ne répond pas. » ; le terminal d'échange aussi ; avec 6 Pokémon, une Ball est refusée
   avec son texte, sans être consommée.
4. Scène de test du retour : l'écran liste les 12 au plus, VALIDER refusé à 0 ou > 6 ou sans
   apte ; après validation, les 6 gardés sont l'équipe, les autres au Stockage, les Sacs
   fusionnés, le PC répond ; tuer l'application pendant l'écran rend l'état d'avant.
5. Suite CI verte ; `test_save_*` existants inchangés.

### Lot JOH0B–D
6. Sur la carte de test : matin, jour, nuit donnent trois rendus distincts ; forcer l'heure du
   Mac (ou `WorldClock.force_period`) change la lumière en 10 s sans recharger ; les lumières de
   nuit n'apparaissent que la nuit ; la puce du menu affiche l'heure et le pictogramme ; à Kanto,
   rien de tout cela.
7. Une table `period: "night"` ne donne ses Pokémon que la nuit ; la Route 1 tire la même séquence
   qu'avant.
8. Un Pokémon à `bond = 70` évolue au prochain niveau ; Évoli à Kanto n'évolue pas en Mentali ;
   au terminal, Onix avec Peau Métal devient Steelix et la Peau Métal disparaît ; sans l'objet,
   rien.
9. Un œuf dans l'équipe ne combat pas, éclot après ses pas en Togepi niveau 5 capturé au Pokédex.
10. Avec `johto_act1`, un combat sauvage donne 1,5 × l'XP d'avant.
11. Pokédex : 202 espèces, liste continue (152 juste après 151), filtre Kanto / Johto / Tout,
    compteur « … · 202 espèces » ; les 51 fiches s'ouvrent (artwork provisoire).
12. Carte : page Kanto inchangée ; page Johto atteignable avec `johto_arrived` ; Vol vers l'autre
    région refusé pendant l'acte 1, accepté après.
13. Suite CI verte ; import headless sans erreur ; aucune donnée de Kanto modifiée hors Évoli
    (deux règles `bond` ajoutées) et les quatre espèces à évolution `trade` + objet.

## 5. Risques

- **Sauvegarde** : le vol vide l'équipe ; la seule protection est l'atomicité (opération
  synchrone + écriture atomique). Test dédié, validation seule, copie de la vraie partie.
- **Heure du téléphone** : un changement de jour en pleine partie ; `sync()` tolère tout saut.
- **Fondu de lumière** : coût sur l'A17 (le calque d'étalonnage est déjà le point chaud du J33) ;
  le fondu ne réapplique que les globals et une couleur, 10 s une fois par moment : négligeable ;
  à mesurer au lot (captures et i/s).
- **Données** : 51 learnsets et ≈ 40 attaques, risque d'erreur de saisie ; tests de données
  (références, familles, numéros, doublons) et audit croisé des deux sous-agents.
- **Pokédex en liste continue** : `PokedexQuery.slots` est au cœur de l'écran du J32 ; les tests
  de `pokedex_query` existants doivent rester verts à 151 (le changement ne se voit qu'avec les
  données de Johto chargées).
- **Conflits** : `boot.gd` avec les branches ouvertes de Kanto ; fusionner `main` avant chaque CI.

## 6. Valeurs par défaut [D] posées par ce plan

| Sujet | Valeur |
|---|---|
| `confiscated` absent | rien de confisqué (écrit seulement si non vide) |
| CT au vol | confisquées avec le Sac (objets non clés) |
| Retour : non gardés | au Stockage, équipe de Johto puis confisquée |
| Retour : sélection par défaut | équipe de Johto puis confisquée jusqu'à 6 |
| Compteur de pas du lien | non sauvegardé |
| Lien : valeurs | 20 / 50 / +2 / 256 pas / +1 compagnon / −3 K.O. / seuil 70 |
| Œuf : pas | 2 000 ; paliers de phrase 1 000 et 300 |
| Œuf : compagnon, favori, libération | refusés |
| Lumière : ombres pendant le fondu | retransformées à la fin |
| Puce de l'heure | Johto seulement ; pictogrammes SVG provisoires |
| PNJ datés | lus à l'entrée sur la carte |
| Objets d'évolution | catégorie `field` sans usage, prix 0 |
| Filtre région du Pokédex | visible dès qu'une espèce de Johto est vue |
| Page Johto de la Carte | visible avec `johto_arrived` |
| Vol vers l'autre région refusé | « Trop loin pour voler d'ici. » |
| Carte sans zone | région `kanto` |

## 7. Questions ouvertes (pour Kevin, non bloquantes)

- JOH-Q1 : la copie de la vraie sauvegarde v9 (A17) peut-elle entrer en fixture de test
  (`tests/fixtures/save/v9_kevin_a17.json`), comme les v2 à v6 ?
- JOH-Q2 : les descriptions françaises du Pokédex des 51 espèces (écrites par Sonnet, `draft:
  true`) sont-elles relues au JOH0 ou en lot avec les textes du JOH1 ?

## 8. Fait

### T1 — plan et branche (2026-11-03)
Branche `claude/joh0-systemes` depuis `main` @ `0b80db1d` ; ce plan ; état du projet.

### T2 — sauvegarde v10 (2026-11-03, `fd908015`)
`SaveSystem.VERSION = 10`, `_upgrade_9_to_10` (seul `bond = 50` ajouté aux Pokémon présents) ;
`Pokemon.bond`, `egg_steps`, `Origin.EGG`, `set_bond` / `add_bond` / `is_egg` ; `ConfiscatedTeam`,
`GameState.confiscated` (écrite seulement si non vide, refus signalé comme la Pension, identifiants
uniques) ; `BondRules` (constantes, `start_for`, `tier`) ; départ du lien posé par `stamp_meeting`.
En avance sur T7 : `WorldClock` réel (moments, jours, forçage, `sync`, `DeviceClock.now_dict`,
`FixedClock.now_dict`) ; en avance sur T11 : règles `bond` (+ `period`) et `trade` + `item` lues par
`PokemonData` (`EvolutionRule.periods`, `allows_period`). Tests : `test_save_joh0.gd` (14 tests :
format, migration, fixtures réelles v6 → v10, bornes, section confisquée), `test_world_clock.gd`
(+5) ; 11 tests de sauvegarde des jalons passés réalignés sur le lien de migration
(`tests/helpers/save_v10.gd`), 13 assertions `VERSION == 9` passées à 10.

### T3 — vol et retour, logique pure (2026-11-03, `1b1b06bb`)
`TeamConfiscation` (`confiscate`, `restore`, `check_kept`, `pool`, `is_key_item`, drapeaux
`storage_offline` / `johto_act1` / `johto_team_returned` / `johto_arrived`), `TeamReturnSelection`
(réserve, ordre de touche, 6 au plus, `default_selection`), `CaptureGate` ; 13 tests
(`test_team_confiscation.gd` : objets clés gardés, favoris, K.O. non soigné, fusion des Sacs,
Stockage dans l'ordre, compagnon, refus EMPTY / TOO_MANY / UNKNOWN / DUPLICATE / NO_ABLE,
écriture avant / après, gabarit du refus).

### T4 — scènes, écran, hors ligne, combat, débogage (2026-11-03)
Étapes `confiscate_team` et `return_team` (`CutsceneStep.Kind` en fin d'enum, `_EXTRA_KEYS`,
drapeaux levés listés) ; `CutsceneDirector.team_return_handler` (coroutine), signaux
`team_confiscated` / `team_returned` ; `TeamReturnOverlay` (`game/ui/johto/`, liste à bascule,
compteur « n / 6 », VALIDER, retour avalé) ; Boot : écran branché, `_on_storage_requested` et
`_on_local_trade_requested` répondent par le dialogue `storage_offline` tant que le Stockage est
hors ligne, scène de débogage à la première entrée de carte (clé `cutscene`) ; `BattleDirector` :
Ball refusée avant le lancer (`ball_refused_offline`, `data/battle/messages.json`, liste
`BattleText.TEMPLATE_IDS`) ; `DebugStart` : clés `confiscated` et `cutscene` ; départs
`johto_confiscated`, `johto_confiscated_full`, `johto_return` (README) ; données
`data/dialogues/johto_systems.json`, `data/cutscenes/johto_systems.json` (scènes de test
`johto_return_test`, `johto_confiscate_test`). Tests : `test_cutscene_johto_steps.gd` (7),
`test_team_return_overlay.gd` (2), `test_debug_start_johto.gd` (3) ; tests de la bibliothèque de
scènes réalignés sur les deux kinds de plus. `main` fusionné (`cb43cbae`). Reste du JOH0A : CI
verte (T5), validation de Kevin sur la copie de sa sauvegarde.

### T7, T8, T9 — heure, lumière, rencontres et PNJ datés (2026-11-03, lot JOH0B)
T7 : `ZoneData.region` / `ZoneLibrary.region_of`, `is_johto`, `zones_of_region` (clé `region`) ;
Boot : `_world_clock` sur `GameState.clock`, Timer d'une seconde (`WORLD_CLOCK_SYNC_SECONDS`),
`period_for_map`, `_current_time`, `is_johto_map`, `get_world_clock` ; `TrainerMenu.clock_shown`
(posé par Boot à chaque carte), pictogramme du moment (`PERIOD_ICONS`, 3 SVG provisoires),
`refresh_status`. T8 : profils `johto_morning` / `johto_day` / `johto_night` [D] dans
`lighting.json` ; `LightingLibrary.AUTO_PROFILE` (« johto_auto », accepté dans « maps »),
`resolve`, `FADE_SECONDS` ; `LightProfile.lerp` ; `WorldLighting.blend_to` (tween sur les globals
et l'étalonnage, ombres et pièce reposées à la fin), `set_night` (groupe `night_lights`) ;
`Boot._apply_lighting(map, blend)` résout le moment et appelle le fondu sur `period_changed`.
T9 : `EncounterTable.periods`, index (carte, terrain, moment) et refus des croisements dans
`EncounterLibrary`, `get_table(map, terrain, period)` ; `EncounterDirector.period_source` ;
`DialogueVariant.if_periods` / `if_weekdays` (clés `if_period`, `if_weekday`), `Dialogue.pick`
et `DialogueRunner.time_source` ; `NpcSpec.if_periods` / `if_weekdays`, `NpcRoster.get_present`
daté, `GameMap.set_time_context` (lu à l'entrée sur la carte [D]). Tests : zones (3), menu (1),
lumière (4 + 3), rencontres (4), dialogues et PNJ datés (`test_dialogue_variant_time.gd`, 7).
**Reste du lot B** : carte de test `johto_light_test` et captures matin / jour / nuit (à la fin du
lot, avec le téléphone).

### T10 à T13 — lien, évolutions, œuf, Exp ×1,5 (2026-11-03, lot JOH0C)
`BondStepCounter` (+1 tous les 256 pas, +1 de plus au compagnon, décompte des œufs),
`BondRules.apply_battle` (+2 aux participants d'une victoire ou capture, −3 par K.O. du joueur ;
`BattleDirector.get_fainted_indices`), `Evolution.period_source` (statique, posé par Boot) et
règles « bond » dans `level_up_target` (seuil 70, moments de la règle) ; `LocalTrade.trade_rule` /
`trade_item` (règle « trade » + objet : exigé dans le Sac, consommé dans le bloc de l'évolution),
`LocalTradeDirector` demande « Utiliser {item} ? » (`trade_terminal_item`, jeton `{item}`) ;
`EggRules` (création niveau 5, phrases [D], éclosion : origine « egg », Pokédex vu et capturé),
œuf sauté par `Party.first_able`, `Battle.SwitchCheck.EGG` (« Un œuf ne peut pas combattre. »),
exclu du Multi Exp, du compagnon, de la libération et du favori (`StorageRules.Status.EGG`), ligne
« Œuf » de l'Équipe (`TeamMemberView.egg`) ; étape de scène `give_egg` (`steps`, `say`) ; Boot :
éclosion au premier pas stable (`egg_hatched`), lien à chaque pas et en fin de combat,
`exp_bonus_source` (×1,5 pendant `johto_act1`, `TeamConfiscation.exp_bonus`). Tests :
`test_bond_and_eggs.gd` (7), `give_egg` (1) ; 339 tests des fichiers touchés verts.

### T6 — données de Johto (2026-11-03, sous-agent Sonnet, `claude/joh0-donnees` @ `0094298e`, fusionné `e15bc331`)
`data/pokemon/species/johto.json` (51 espèces, dex 152–251, types et stats modernes, learnsets
d'Or/Argent de PokeAPI), règles `bond` (Togepi, Leveinard, Nosferalto, Évoli matin/jour et nuit)
et `trade` + objet (Onix, Insécateur, Ramoloss, Têtarte, Hypocéan, Porygon) dans les fichiers de
Kanto ; `data/pokemon/moves/johto.json` (47 attaques, 28 en `pending_effects` : météo, Abri,
Relais, Encore, Ténacité… ; `tools/audit_moves.py` : 0 manquante) ; `data/battle/move_fx/johto.json`
(familles [D] : acier et ténèbres en contact, météo en statut_plus) ; `data/pokedex/johto.json`
(51 fiches `draft`, descriptions à relire par Kevin, JOH-Q2) ; `data/items/items_johto.json`
(4 objets) ; outils `gen_johto_data.py`, `gen_johto_pokedex.py` ; 11 tests de Kanto bornés à
dex ≤ 151 ; `test_johto_data.gd` (8). Valeurs de substitution [D] : Prescience 80, Baston 20,
Fléau et Contre-Attaque 40, Voile Miroir en statut (priorité −5), Rayon Lune / Aurore / Synthèse
50 %. **Reportés** : icônes du Sac des 4 objets, cris 152–251 (lot Son), ancrages d'effets et
sprites (art hors JOH0), `caught_count` ≥ 150 du Diplôme de Kanto compte toutes les espèces.

### T14, T15 — Pokédex 202, régions, Carte, Vol (2026-11-03, lot JOH0D)
`PokedexLibrary.load_dir` (les `size` s'additionnent : 202), `MAX_DEX` 251 à la place de
« ≤ size » ; `PokedexQuery` : liste continue des espèces du Pokédex par numéro (151 puis 152…),
filtre région (`region_choices` : proposé dès qu'une espèce de Johto est vue, bouton « Région :
Tout / Kanto / Johto » de l'écran, cinquième paramètre de `filter_changed` /
`set_pokedex_filter`), `caught_in_region` ; variantes `if_caught_johto_at_least` /
`unless_caught_johto_at_least` (`DialogueRunner.caught_johto_count`, posé par Boot).
`zones.json` : Oliville, Rosalia, Doublonville, Écorcia, Acajou (`region: johto`, `maps: []`,
descriptions [D] `draft`) ; `fly_points.json` : leurs cinq points ; `FlyRules.Point.region`
(`stamp_regions`), `can_fly_to(..., from_region, cross_allowed)` → `OTHER_REGION` (le bouton
S'ENVOLER se cache [D], pas de texte), `destinations(discovered, region, cross)` ;
`FlyDirector.region_source` / `cross_source` (Boot : pas de Vol entre régions pendant
`johto_act1`). Carte : `MapIllustration` par région (`assets/ui/map/johto_placeholder.webp` +
`_areas.json`, image provisoire dessinée par `tools/make_johto_map_placeholder.py`),
`MapJournal.view(..., region, regions)`, `available_regions` (Johto dès `johto_arrived` [D]),
`MapView.region` / `regions` / `next_region`, `MenuDirector.switch_map_region`, bouton
« Johto › » / « Kanto › » dans l'en-tête de `MapScreen` (`map_region_requested`). Débogage :
clés `light_profile` et `period` de `DebugStart`, départ `johto_light_test` (captures du lot B).
Tests : `test_johto_regions.gd` (5), zones (+1), Vol, Pokédex (bibliothèque, requête, écrans)
réalignés ; 124 tests des fichiers touchés verts.

### T16 — clôture du code (2026-11-03)
Captures Mac (Movie Maker, départ `johto_light_test`, Route 1 sous `johto_auto`) : matin (lumière
chaude rasante, ombres longues), jour (blanc neutre), nuit (étalonnage bleu, sans liseré) bien
distincts ; planche `build/captures/joh0/johto-lumiere-matin-jour-nuit.jpg` (hors dépôt). Réglage
fin des trois profils en phase DA. **À Kevin** : T5 (validation de la v10 seule, sur une copie de
sa vraie sauvegarde), puis le lot B–D sur le téléphone (`jalon-joh0.md` §4, critères 6 à 13).
CI : voir `etat-projet.md`. Prompt de reprise du JOH1 : `etat-projet.md`, entrée du 2026-11-03.

