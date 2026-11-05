# Jalons JOHP0 à JOHP3 — L'arc des Pierres : Réveil, Ruines d'Alpha, Irisia, Ébènelle et Antre du Dragon

> **PLAN — aucun code n'est écrit par ce document.** Sources de vérité :
> `docs/design/dossier-joh-11-arc-pierres.md` (arbitrages JH-61 à JH-79 et textes validés par Kevin les
> 2026-11-04 et 2026-11-05) ; grilles `tools/plans/ruins_of_alph.txt`, `alph_tent.txt`, `alph_gallery.txt`,
> `alph_chamber.txt`, `goeland_deck.txt`, `cianwood_city.txt`, `tide_cave_1f.txt`, `tide_cave_b1f.txt`,
> `blackthorn_city.txt`, `dragons_den_1f.txt`, `dragons_den_sanctuary.txt` et variantes `ARC` de
> `route_36.txt`, `oliville.txt`, `rosalia.txt` (validées par Kevin le 2026-11-05, **elles font foi**) ; contrôle `tools/art/plan_check_johp.py` ; vues `docs/design/reference/johp*-vues-v1.png`
> (validées le 2026-11-05, DA seulement). Écrit le 2026-11-05 sur la branche `claude/dossier-arc-pierres-3e4a45`.

> Objectif jouable : **de la fin de la Tour Radio au doyen de Rosalia**, par les trois lieux, jusqu'au
> Réveil et au retour de l'équipe de Kanto, sans changer les niveaux ni les textes de JOH6 à JOH9.
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) pour JOHP1 et JOHP2 : tests, CI verte, QA,
> fusion. **JOHP0 et JOHP3 touchent la sauvegarde** : validés seuls (règle 1 de `CLAUDE.md`). Le **format
> de sauvegarde ne change pas** (v10, JH-75).

## 0. État des lieux (relu sur `main`, 2026-11-05)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Retour de l'équipe | `TeamConfiscation.restore` (une opération) ; étape de scène `return_team` ; écran `TeamReturnOverlay` ; `johto_return_stored` ; `{returning_pokemon}` | Tout se réutilise tel quel : seules les **données de scène** bougent |
| JOH5 | Fusionné ; `tools/gen_joh5_data.py` écrit `goldenrod_radio_office` (retour, `save`) et `goldenrod_radio_exit` (`johto_act2`) | Réécrit au JOHP3 (§5) |
| Exp ×1,5 | `TeamConfiscation.exp_bonus` tant que `johto_act1` est levé | **Rien à coder** (JH-70) |
| Stockage | `storage_offline` levé jusqu'à `restore` ; `CaptureGate.blocks` refuse la Ball à 6 | Une condition de plus (§3.3) |
| Évolutions | `Evolution.level_up_target` (une étape), `Evolution.evolve` (rend les capacités), lecture `_evolutions.play` | Boucle pour les chaînes (§2) |
| Capacités | `MoveLearnPrompt.teach`, `MoveForgetPanel` | Réutilisés depuis l'écran du Réveil |
| Niveau, XP | `ExpCurve.exp_for_level`, `Pokemon.recalc`, `met_map` | Pas de champ neuf |
| Vol | `fly_points.json`, ouverts par cartes découvertes | 2 points neufs, `from_dragon` et `retour_centre` |
| Grilles à variantes | `plan_grille.lire(chemin, "ARC")` ; `tests/helpers/plan_grid.gd` lit la base | Route 36, Oliville, Rosalia : outil de cartes à relancer en variante, base inchangée jusqu'à la bascule |

## 1. Découpage

| Jalon | Contenu | Validation | Dépend de |
|---|---|---|---|
| **JOHP0** — le Réveil | Logique pure, étape de scène, écran, tests de sauvegarde, sur scène de test | **Seul** | JOH5 (fait) |
| **JOHP1** — Ruines d'Alpha | 4 cartes, retouche Route 36, dalles, faux archéologue, Pierre Mémoire | Déléguée | JOHP0 non requis |
| **JOHP2** — Irisia | Goéland, 3 cartes, retouche Oliville, vannes, revers, fermeture de la mer (A-13) | Déléguée | JOHP1 (drapeaux) |
| **JOHP3** — Ébènelle, l'Antre, la bascule | Vol scénarisé, 3 cartes, épreuve, Réveil réel, Cenere, **déplacement du retour de l'équipe**, `johto_act2` | **Seul** | JOHP0, JOHP1, JOHP2 |

**Bascule unique.** Tant que JOHP3 n'est pas fusionné, le JOH5 garde son bureau et le jeu reste jouable de bout
en bout : JOHP1 et JOHP2 vivent derrière `johto_stones_quest`, que rien ne pose, et se testent par des départs de
débogage. JOHP3 change les scènes du JOH5 et ouvre l'arc **en un seul commit de données**.

## 2. JOHP0 — le pouvoir des pierres

### 2.1 Logique pure : `game/systems/johto/stone_awakening.gd`

Classe statique, sur le modèle de `TeamConfiscation` :

- `target_level(confiscated: ConfiscatedTeam) -> int` : moyenne arrondie des **3 plus hauts niveaux**
  (moins s'il y en a moins), bornée à **55–62** (JH-66).
- `eligible(state, zones) -> Array[Pokemon]` : l'équipe, puis les Pokémon du Stockage dont `met_map` est à Johto
  (JH-67) ; ni œuf, ni niveau ≥ cible.
- `apply(pokemon, target, data) -> AwakeningResult` : `experience = ExpCurve.exp_for_level(rate, target)`,
  `level = target`, puis tant que `Evolution.level_up_target` rend une espèce, `Evolution.evolve` (chaîne entière,
  capacités cumulées), `recalc`, `heal_full`, statut retiré. `bond` inchangé.
- `AwakeningResult` : niveaux avant et après, chaîne d'espèces, capacités nouvelles (les 3 plus récentes de
  l'apprentissage entre l'ancien et le nouveau niveau, [D]).
- Pokémon du Stockage : même chose, puis ses 4 capacités = les 4 dernières de l'apprentissage ([D]).
- Une **seule opération synchrone**, comme `restore` : rien n'est `await`é au milieu.

### 2.2 Scène : étape `stones_awaken`

Étape de `CutscenePlayer` : appelle `StoneAwakening`, joue `AwakeningOverlay` (ci-dessous), pose
`johto_stones_awakened`, retire les objets clés, puis `save` (une écriture). L'étape est **non passable** la
première fois (JH-73) ; pendant la lecture, l'état est déjà calculé mais non écrit : application tuée = la scène
reprend à l'autel, rien n'est perdu.

### 2.3 Écran : `game/ui/johto/awakening_overlay.gd`

Déroulé du dossier §13.2 : silence (`AudioDirector`, coupure nette), lumière en trois couleurs (`ColorRect` et
shader additif, couches de la famille d'effets existante), plans par Pokémon (artwork, cri, **compteur de niveau**
en tween, palier d'évolution, flash), plan large final, ligne P-31, écran du Réveil (liste, panneau d'attaques,
« Continuer »). Compagnon rafraîchi à la fin. Pokédex : marquer chaque espèce de la chaîne comme capturée.

### 2.3 bis Ce qui a été fait, écarts et contrat pour JOHP3 (2026-11-05)

- **Ordre réel de l'étape** : `StoneAwakening.awaken` (niveaux, évolutions, Pokédex, pierres et `johto_stones_awakened` d'un seul bloc en mémoire), film, **écriture**, écran du Réveil, puis une seconde écriture seulement si une attaque a été apprise. Écart [D] avec le §2.2 et le point 6 du §13.2 : le §15 du dossier veut l'écran **après** l'écriture (« les attaques non choisies sont perdues ») ; lever le drapeau dans le bloc garde la mémoire cohérente. Aucune écriture différée ne tombe pendant la scène (`Boot.is_stable` faux).
- **Scène** : `{"stones_awaken": true}`, sans étape `save` derrière. P-31 est dans le film (`data/dialogues/johp0.json`) : ne pas la rejouer. Étape sautée si le Réveil est fait. Plans dans l'ordre de l'équipe : P-28b frappe le Pokémon de tête.
- **Silence** : `"music": "cut"` sur l'étape de P-29 coupe net musique et ambiance. Le film recoupe de toute façon à son début.
- **Thème** : événement `awakening` de `data/audio/tracks.json`, **provisoire** (`final_road`), à choisir avec Kevin (dossier §16).
- **Annonce du Stockage** (texte [D], `stones_awakening_stored`, brouillon) : « Au laboratoire d'Orme aussi, des Pokémon se réveillent. »
- Écran : textes de système [D] « Le Réveil », « CONTINUER », « N attaques à voir ». Toucher une ligne enchaîne ses attaques dans `MoveLearnPrompt.teach`.
- Les objets `stone_*` restent au JOHP1 : le Réveil les retire s'ils sont là, sans les exiger.
- Départs : `johto_awakening`, `johto_awakening_autosave` (Grotte marine en attendant le Sanctuaire ; clés neuves `bond` et `met_map` des membres).
- Les fichiers `johp*` de `data/dialogues` et `data/cutscenes` sortent du test central (`j22_ids.gd`, `test_dialogue_data.gd`), comme ceux des `joh<n>_`.

### 2.4 Tests

- `test_stone_awakening.gd` : cible (équipe de 6, 2 faibles, moins de 3, bornes), jamais de baisse, chaîne
  Chenipan → Papilusion, lien (Togepi à 70 et à 40), Évoli par moment, PV et PP pleins, Pokédex.
- `test_stone_awakening_save.gd` : application tuée avant et après l'écriture ; rechargement ; v10 inchangée.
- Scène de test : départ de débogage `johto_awakening` (Sanctuaire, 3 pierres, équipe de Johto niv. 38–44).

**Critères** : scène en 60 à 90 s ; aucune question hors de l'écran du Réveil ; sauvegarde reprise dans les deux cas.

## 3. JOHP1 — Ruines d'Alpha

### 3.1 Cartes

| Carte | Identifiant | Taille | Lumière |
|---|---|---|---|
| Ruines d'Alpha | `ruins_of_alph` | 36 × 30 | `johto_auto` |
| Tente d'Héloïse | `alph_tent` | 9 × 7 | `interior_warm` |
| Galerie des Glyphes | `alph_gallery` | 24 × 18 | `cave` [D] |
| Chambre de la Mémoire | `alph_chamber` | 14 × 12 | `cave` [D] |

Outil `tools/build_johp1_maps.gd`, données `tools/gen_johp1_data.py`, sur le modèle du JOH4. **Pas de nom
d'autoload dans les scripts du monde** (mémoire « Outils sans autoload »). Zone `ruins_of_alph`, région `johto`.

### 3.2 Scènes et données

- Retouche `route_36` (variante ARC) : ouvrier, `barriere_ruines`, raccord ; textes P-2, P-42.
- Dalles : déclencheurs par case ; bonne dalle, drapeau de rang ; mauvaise, P-45 et téléport vers `retour_dalles`.
- `alph_scene_faux` : P-6, combat, P-7 ; `socle` : P-8, Pierre Mémoire, `johto_stone_memory`.
- Dresseurs P-43, P-44 ; rencontres §11 ; objets §12 ; Zarbi : signes animés dans la Galerie, aucune donnée.
- Objets clés `stone_memory`, `stone_tide`, `stone_breath` (`data/items/items_johp.json`), descriptions P-9.

### 3.3 Capture à 6 pendant l'arc (JH-71)

`CaptureGate.blocks` : ne bloque plus si `johto_stones_quest` est levé. La capture suit le chemin « équipe
pleine » existant (vers le Stockage) avec le texte P-58 ; le PC reste fermé. Test : Stockage inaccessible, Pokémon
présent au retour de l'équipe.

**Critères** : du hall de la Tour (départ de débogage) à la Pierre Mémoire ; mauvaises dalles ; Corde Sortie vers
`retour_galerie` ; aucune CS requise.

**État : fait, fusionné dans `main` le 2026-11-05** (CI verte run 41999662979, QA A17 sans bloquant). Écarts [D] : lumière `cave_1f` et `cave_b1f` (le profil `cave` n'existe pas) ; Route 36 retouchée dès le JOHP1 (`build_johp1_maps.gd`, puis `build_joh_ambiance.gd` avec la clé `variant`), fermée par l'ouvrier tant que `johto_stones_quest` manque ; signes de la Galerie dessinés (`AlphGlyph`), le signe de chaque mur marquant la bonne dalle de son rang.

## 4. JOHP2 — Irisia

### 4.1 Cartes

`goeland_deck` (16 × 8), `cianwood_city` (32 × 28, `johto_auto`), `tide_cave_1f` (26 × 20), `tide_cave_b1f`
(20 × 16), intérieurs `cianwood_center`, `cianwood_goulven_house`, `cianwood_house_1` (coques de Johto). Outil
`tools/build_johp2_maps.gd`, données `tools/gen_johp2_data.py`. Point de Vol `cianwood_city`.

### 4.2 Scènes

- Oliville (variante ARC) : Goulven P-11, P-12 ; Goéland en sprite (`decor`) ; Ultra Ball ×3 ; traversée :
  fondu, `goeland_deck`, P-13, fondu.
- Vannes : `FlagGate` sur `a` et `b` (eau, puis gué), `johto_tide_valve_1`, `johto_tide_valves_done`.
- Revers : `scene_socle`, P-16 à P-19, `johto_stone_tide_lost`. P-19b au retour à Oliville.
- **A-13** : `barriere_mer_sud` (`actif_sans=johto_act2`, en Surf), P-59. Vaut aussi pour le JOH7, déjà dans `main`.
- Rosalia (variante ARC) : Corentin et Dracolosse, actifs avec `johto_stone_tide_lost`.

**Critères** : aller-retour libre ; vannes dans l'ordre ; pas de Surf ; bateau noir absent après le revers.

## 5. JOHP3 — Ébènelle, l'Antre et la bascule

### 5.1 Cartes

`blackthorn_city` (32 × 30), `dragons_den_1f` (28 × 24), `dragons_den_sanctuary` (22 × 18), intérieurs
`blackthorn_center`, `blackthorn_elder_house`, `blackthorn_house_1`. Outil `tools/build_johp3_maps.gd`, données
`tools/gen_johp3_data.py`. Point de Vol `blackthorn_city`, ouvert à la première visite.

### 5.2 Scènes

- Vol scénarisé : P-20, P-21, animation de survol (sprite de Dracolosse, 2 sens), `johto_clan_called`. Retour P-38,
  arrivée `from_dragon` à Rosalia, `johto_act2`.
- Aïeule : P-22, P-23, `johto_clan_trial_open`. Gardiens P-24, P-51 ; `johto_clan_guardians_done`.
- Sanctuaire : P-25 (soin une fois), Ysolde P-26, P-27, Pierre Souffle. `scene_autel` : P-28, **P-28b (le coup de
  Farfuret, scène sans combat)**, P-29, P-30, `stones_awaken`, P-31 ; `scene_cenere` : P-32, combat, P-33, retour
  de l'équipe.
- Réglage : Cenere à 70–80 % de victoire du premier coup (simulation, mémoire « Difficulté des combats ») ; Ysolde
  35–60 %.

### 5.3 Le déplacement du retour de l'équipe (la bascule)

Dans **`tools/gen_joh5_data.py`** et les fichiers qu'il écrit, en un commit :

| Élément | Avant | Après |
|---|---|---|
| T-21, T-23, T-24, T-26, T-31, T-32, T-34 | Anciens | Dossier JOH-06 §14 (validés) |
| `goldenrod_radio_office` | T-27, `return_team`, T-29, T-30, `save`, Multi Exp | Papier, Multi Exp, `johto_radio_office_done` ; **plus de `return_team`** |
| `goldenrod_radio_exit` | `if johto_team_returned unless johto_act2` ; pose `johto_act2` | `if johto_radio_office_done unless johto_stones_quest` ; T-33, T-34, P-1 ; pose `johto_stones_quest` |
| Cases `johto_team_returned` et `johto_act2` des PNJ 1F et 5F, `objectives.json` | Anciennes | `johto_radio_office_done`, `johto_stones_quest` ; objectifs neufs [D] |
| M-14 (JOH7) | « Deux erreurs » | « Trois erreurs » |
| Route 36, Oliville, Rosalia | Base | Variante ARC appliquée au build |
| Tests JOH5, JOH7 | Retour au bureau | Réalignés ; test du retour déplacé au Sanctuaire |

Étapes `return_team` et `save` reprises sans changement dans `scene_cenere`, textes P-34 à P-37. Parties déjà
passées par le bureau : `johto_stones_quest` n'est jamais posé, la barrière de la Route 36 reste fermée (JH-75).

### 5.4 Tests

- De bout en bout (`hideout_play`) : hall de la Tour → Antre → Réveil → retour → doyen.
- Application tuée à chaque écriture (Réveil, retour).
- Équipe de Johto de 1 à 6 ; captures au Stockage ; total ≤ 6 (pas d'écran des 6).
- Vol et grotte marine fermés avant, ouverts après ; ×1,5 retiré après.
- Simulation de JOH6 à JOH8 avec une équipe mixte (JH-78) ; **niveaux inchangés**.

### 5.5 Réalisé (2026-11-05)

- **Scènes** : `data/cutscenes/johp3_blackthorn.json`. `dragons_den_altar` est une seule scène à trois
  variantes (première fois ; Réveil acquis ; Cenere battue sans équipe rendue) : la grille prévoyait
  deux déclencheurs sur les mêmes cases, `scene_cenere` est donc ignoré par l'outil. P-31 est dite par
  `AwakeningOverlay` (avant l'écran du Réveil, §13.2).
- **Étapes neuves** : `dragon_flight` (écran `DragonFlightOverlay`), `rest_point` (§15 : une défaite contre
  Ysolde ou Cenere ramène au Centre d'Ébènelle même sans y être entré). Jeton `{lead_pokemon}` (P-28b).
- **Défauts [D]** : Corentin vole dans les deux sens pendant l'arc (Ébènelle n'a pas de Boutique), sans
  question ; texte `johp3_corentin_blackthorn` en « draft ». Joueur rentré par son propre Vol : Corentin de
  Rosalia dit P-38 sans le vol et pose `johto_act2`. L'Aïeule est chez elle jusqu'aux trois Gardiens, au
  Sanctuaire ensuite, de nouveau chez elle après Ysolde. Farfuret ouvre l'équipe de Cenere (P-32, §13.2).
  Objectifs de l'arc `stones_*` en « draft ». T-32 garde sa bulle sur le réseau jusqu'au retour de
  l'équipe. Le don du mari et Raphaël chez lui suivent `johto_stones_quest` (la Tour libérée), avec une
  variante `johto_act2` pour les parties passées par l'ancien bureau.
- **Rosalia** : `from_dragon` ajouté **au texte** de `ecruteak_city.tscn` (`tools/build_johp3_maps.gd`), jamais
  réenregistré : la sauvegarde par l'outil aplatissait les décors peints.
- **Équilibrage** (`tools/sim/gen_johp3_scenarios.py`, `simulate_mt_moon.gd`, 200 graines, attentif avec 3
  Hyper Potions / naïf). Décision de Kevin du 2026-11-05 : joueur attentif autour de 80 %, naïf pas
  impuissant, niveaux permis au-delà de JH-74 et JH-78, pour Cenere et Brace seulement. Niveaux [D] notés au
  dossier JOH-11 §10 :

| Combat | Niveaux | Équipe | Attentif | Naïf | Lecture |
|---|---|---|---|---|---|
| Ysolde | 42–45 (dossier) | 6 Pokémon 37–39 | 46,5 % | 0,5 % | Dans la cible 35–60 % |
| Ysolde | 42–45 (dossier) | 4 Pokémon 40–42 | 56,5 % | 2,5 % | Dans la cible |
| Ysolde | 42–45 (dossier) | 3 Pokémon 44 | 89,5 % | 45,5 % | Au-dessus de 80 % : qui ne monte que trois Pokémon |
| Cenere, autel | **59–61 [D]** (était 54–56) | 6 Pokémon 58 | 100 % | 83,5 % | |
| Cenere, autel | **59–61 [D]** | 4 Pokémon 55 | 76,5 % | 11,5 % | Autour de 80 % |
| Brace, mixte | **63–65 [D]** (était 60–62) | N59 | 78 % | 3 % | Autour de 80 % |
| Brace, mixte | **63–65 [D]** | N61 | 89,5 % | 12 % | |
| Cenere, Îles Tourbillon, mixte | **64–66 [D]**, Démolosse à la place de Noarfang | N61 / N63 | 85,3 / 98,3 % | 7,7 / 15 % | Cible 85–95 % (Kevin), ≈ 92 % en moyenne |
| Dante (1), mixte | 64–68, inchangé | N63 / N65 | 63,5 / 82,5 % | 4 / 13 % | |

  Attaques ajoutées à Cenere (autel et Îles Tourbillon) et à Brace, avec changements de Pokémon. Cenere des
  Îles Tourbillon restait à 100 % en attentif quels que soient niveaux et attaques : seconde décision de Kevin,
  85–95 %, son équipe peut changer. Essais de sa quatrième place [D] : Tyranocif 58–65, 27–61 % (trop fort) ;
  Démolosse 65, 75–94 % ; Démolosse 64, retenu ; 63, 89–99 % ; Noctali, Nostenfer, Ectoplasma, 96–100 %.
  Le naïf perd presque toujours ce combat (8–15 %) : Kevin a fixé la cible sur l'attentif. Essai écarté : des
  attaques choisies pour Ysolde donnaient 0 à 5 %.
- **QA A17 du 2026-11-05** (sans bloquant) : autel, film et écran du Réveil, écran des 6, vol et arrivée à Rosalia.
  Reprise sur vraie sauvegarde, sans perte, tuée sur l'écran du Réveil, sur l'écran des 6, après VALIDER avant
  l'écriture, après l'écriture. Combat complet contre Cenere non joué sur téléphone (couvert dans le vrai Boot).

## 6. Risques

| Risque | Parade |
|---|---|
| Bascule qui casse la QA des jalons en cours | Un seul commit, à la fin ; départs de débogage de l'acte 2 inchangés |
| Évolutions groupées qui ne passent pas par le chemin de combat (Pokédex, compagnon) | Tests dédiés, JOHP0 validé seul |
| Scène du Réveil trop lourde sur A17 | Mode économie : moins de particules, mêmes plans |
| Variantes de grille lues par un outil qui ne les connaît pas | Vérifier `plan_grid.gd` et les outils de cartes au JOHP1 |

## 7. Prompts de reprise

**JOHP0** — « Reprise de l'arc des Pierres, JOHP0 (le Réveil). Lis CLAUDE.md, docs/tech/etat-projet.md,
docs/tech/jalon-joh-pierres.md §0 et §2, docs/design/dossier-joh-11-arc-pierres.md §13. Branche depuis `main`.
Prochaine tâche : `stone_awakening.gd` et ses tests, puis l'étape `stones_awaken` et `AwakeningOverlay`, sur le
départ de débogage `johto_awakening`. Validation seule : sauvegarde. Niveaux et textes : ne pas changer. »

**JOHP1** — « Reprise de l'arc des Pierres, JOHP1 (Ruines d'Alpha). Lis CLAUDE.md, docs/tech/etat-projet.md,
docs/tech/jalon-joh-pierres.md §0, §1 et §3, docs/design/dossier-joh-11-arc-pierres.md. Grilles `ruins_of_alph`,
`alph_*`, variante ARC de `route_36` (validées). Branche depuis `main`. Prochaine
tâche : cartes, données, dalles, faux archéologue, `CaptureGate`. Rien ne pose `johto_stones_quest` hors des
départs de débogage : la bascule est au JOHP3. »

**JOHP2** — « Reprise de l'arc des Pierres, JOHP2 (Irisia). Lis CLAUDE.md, docs/tech/etat-projet.md,
docs/tech/jalon-joh-pierres.md §0, §1 et §4, docs/design/dossier-joh-11-arc-pierres.md. Dépend du JOHP1. Grilles
`goeland_deck`, `cianwood_city`, `tide_cave_*`, variantes ARC d'`oliville` et `rosalia`. Prochaine tâche : cartes,
Goulven et la traversée, vannes, revers, fermeture de la mer au sud d'Oliville (A-13). »

**JOHP3** — « Reprise de l'arc des Pierres, JOHP3 (Ébènelle, Antre, bascule). Lis CLAUDE.md,
docs/tech/etat-projet.md, docs/tech/jalon-joh-pierres.md §0, §1 et §5, docs/design/dossier-joh-11-arc-pierres.md,
docs/design/dossier-joh-06-tour-radio.md. Dépend de JOHP0, 1 et 2. Prochaine tâche : cartes, vol, épreuve, Ysolde,
Réveil réel, Cenere, puis la bascule du §5.3 en un commit. Validation seule : le retour de l'équipe touche la
sauvegarde. Niveaux de JOH6 à JOH9 : ne pas changer. »

## 8. Valeurs par défaut [D] posées par ce plan

Trois capacités les plus récentes à l'écran du Réveil ; 4 dernières de l'apprentissage pour le Stockage ; lumière
`cave` des grottes ; ordre des jalons JOHP1 → JOHP2 → JOHP3, JOHP0 en parallèle ; identifiants de cartes ci-dessus.
