# Jalon JOH9 — Le sommet du monde : Mont Argenté, Dante, Giovanni, le rival, épilogue

> **PLAN.** Sources de vérité : `docs/design/dossier-joh-10-mont-argente.md` (textes A-1 à A-54,
> arbitrages JH-56 à JH-60 validés par Kevin le 2026-11-02 ; le reste porte des défauts **[D]**),
> `docs/design/dossier-joh-00-cadre.md` (§3.2, §4.4, §4.5) ; grilles `tools/plans/silver_trail.txt`,
> `mt_silver_outside.txt`, `mt_silver_1f.txt`, `mt_silver_2f.txt`, `mt_silver_3f.txt`,
> `mt_silver_summit.txt`, `route_28.txt`, `route_28_gate.txt` et la **variante `JOH9`** de
> `route_22_ouest.txt` (validées le 2026-11-03, **elles font foi**) ; vues générales
> `docs/design/reference/*mont-argente*`, `route-28-vue-generale-v1.png`, `poste-route-28-v1.png`
> (DA seulement). Systèmes du JOH0 (`docs/tech/jalon-joh0.md` §2 et §8), modèle de construction du
> JOH2 (`tools/build_joh2_maps.gd`, `tools/gen_joh2_data.py`). Écrit le 2026-11-04 sur la branche
> `claude/joh9-mont-argente-f6ee3a` (depuis `main` ; `main` refusionné dès que JOH1 et JOH2 y sont,
> puis régulièrement).

> Objectif jouable : **du Lac Colère à l'épilogue**, en partant de l'état de fin du JOH8 (départs de
> débogage) : sentier et Centre du Mont Argenté (point de Vol), extérieur et **relais du rival**,
> grotte 1F (Force, Surf, Sbires), 2F dans le noir (Flash automatique, le rival soigne l'équipe), 3F,
> sommet (**Dante**, **Giovanni**, Cenere, **dernier combat du rival**), descente par la Route 28 et
> son poste, **porte neuve de la Route 22** (variante `JOH9`), **épilogue au labo de Chen** (Orme,
> Balle Verte, rival, petit générique), retour libre à Kanto.
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA sur l'A17,
> fusion dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change.

## 0. État des lieux (2026-11-04)

| Point | Réel | Conséquence |
|---|---|---|
| Cartes | Aucune carte du JOH9 ; grilles validées ; Lac Colère = carte du **JOH6** (en parallèle) | Raccord ouest du sentier « À venir » (« Lac Colère ») tant que `lake_of_rage.tscn` manque ; relancer l'outil à la fusion du JOH6 |
| Garde forestier (A-1, A-2) | PNJ et barrière de la carte du JOH6 (`garde_forestier`, `barriere_sentier` actif sans `johto_act3`) | Textes A-1, A-2 fournis ici (`joh9_*`) ; branchement sur le PNJ du JOH6 à sa fusion (message à JOH6) |
| Autel du Bois aux Chênes | Examen du **JOH4** (`ilex_forest`, (23, 11)) | Scène de Celebi (A-53, A-54) écrite ici ; branchée sur l'autel à la fusion du JOH4, sinon « Reportés » |
| Équipe de JOH8 | Dante (1), Ho-Oh, drapeaux `johto_act3`, `johto_dante_fled_1` : codés par le JOH8 en parallèle | Départs de débogage qui posent les drapeaux de fin du JOH8 (dossiers JOH-02 à JOH-09, §« Drapeaux ») |
| Espèces | Les 202 espèces sont dans `data/pokemon/species/` (JOH0) | Rien à ajouter |
| Rival de Ligue | `data/trainers/league.json` `rival_champion` (`team_by_starter`) | `rival_johto_final` : même structure, niveaux et Steelix du §9 |
| Art | Vues validées ; aucun décor peint ; pas de Dante âgé, Brace, Cenere, Orme, Agente ni tenue d'hiver du rival dans `main` | Tuiles provisoires, sprites existants [D] ; tout en « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH9A** — la montagne | T1 données générées, T2 cartes (sentier, extérieur, 1F, 2F, 3F, sommet, Route 28, poste), T3 Centre et maison du gardien, T4 zones, Vol, rencontres, lumière, musique | Tests, captures Mac |
| **JOH9B** — l'histoire | T5 relais, rival du 2F, Dante, Giovanni, rival final, défaites ; T6 poste et porte de la Route 22 (variante `JOH9`) ; T7 épilogue, Balle Verte, générique ; T8 Celebi (si JOH4 fusionné) ; T9 départs de débogage ; T10 tests ; T11 captures | Tests, captures Mac |
| Clôture | T12 QA A17 (tour demandé à la coordination), T13 CI verte et fusion dans `main`, T14 état du projet, compte rendu | Déléguée |

## 2. Conception technique

### 2.1 Cartes

| Carte | Identifiant | Grille | Taille | Lumière | Outil |
|---|---|---|---|---|---|
| Sentier du Mont Argenté | `silver_trail` | `silver_trail.txt` | 24 × 44 | `johto_auto` | `tools/build_joh9_maps.gd` |
| Mont Argenté, extérieur | `mt_silver_outside` | `mt_silver_outside.txt` | 40 × 40 | `johto_auto` | idem |
| Grotte 1F | `mt_silver_1f` | `mt_silver_1f.txt` | 32 × 28 | grotte | idem |
| Grotte 2F | `mt_silver_2f` | `mt_silver_2f.txt` | 32 × 28 | grotte + voile | idem |
| Grotte 3F | `mt_silver_3f` | `mt_silver_3f.txt` | 28 × 24 | grotte | idem |
| Sommet | `mt_silver_summit` | `mt_silver_summit.txt` | 20 × 18 | `johto_auto` | idem |
| Route 28 | `route_28` | `route_28.txt` | 44 × 20 | `johto_auto` | idem |
| Poste de la Route 28 | `route_28_gate` | `route_28_gate.txt` | 10 × 8 | intérieur | idem (intérieur provisoire) |
| Centre du Mont Argenté | `mt_silver_center` | définition commune des Centres | 15 × 10 | intérieur | `build_painted_interiors.gd --mont-argente` |
| Maison du gardien | `route_28_house` | maison commune [D] | 15 × 10 | intérieur | idem |

- **La grille fait foi** : test « grille de la scène = grille du plan » (`test_joh9_maps`).
- Neige `n` : tuile provisoire claire praticable sans rencontre [D] ; herbes sous la neige `h` =
  hautes herbes.
- **Route 22 ouest** (Kanto) : la carte `route_22_west` n'est **pas reconstruite** (art peint du
  DAF.4). La variante `JOH9` y est posée par des nœuds ajoutés (`tools/build_joh9_route22.gd`) :
  bâtiment provisoire `FlagGate` (cases Q en `blocking_cells`, **occupées** et non solides, la grille
  de base du J29 reste exacte pour `test_j29_maps`), porte `porte_route_28` (2, 10) STEP_ON ← et
  arrivée `from_route_28_gate` (3, 10), tous **actifs avec `johto_arrived`** [D] (la retouche
  n'apparaît qu'une fois le Chapitre Johto commencé).

### 2.2 Ordre de jeu et drapeaux

Ordre du dossier §4 : `johto_rival_relay` (extérieur) → `johto_rival_healed` (2F) →
`johto_dante_defeated_2` → `johto_giovanni_seen` → `johto_rival_final_done` (sommet) →
`johto_route28_open` (poste) → `johto_chapter_done` (labo) ; `johto_celebi_done` (post-game).

### 2.3 Combats et défaites

- Dresseurs du §6 (`data/trainers/joh9.json`), textes A-4 à A-6, A-14, A-18 mot pour mot.
- **Dante (2)** `dante_2` et **rival final** `rival_johto_final` : combats de scène, `can_lose`
  selon le moteur (défaite = retour au Centre du Mont Argenté, point de repos posé à la visite).
- Reprise après défaite : la scène du sommet lit les drapeaux (A-25 si Dante n'est pas battu ;
  A-45 si Giovanni est vu et le rival pas battu) ; aucune scène rejouée en double.

### 2.4 Épilogue

- Déclencheur à l'entrée du labo de Chen avec `johto_giovanni_seen` + `johto_rival_final_done`, sans
  `johto_chapter_done` : A-49 à A-51, Balle Verte, petit générique [D], sauvegarde proposée.

## 3. Tâches

(tenues à jour au §8 « Fait »)

## 6. Valeurs par défaut [D]

(remplies pendant le code)

## 8. Fait

### T0 — plan et branche (2026-11-04)

Plan écrit ; branche `claude/joh9-mont-argente-f6ee3a`.
