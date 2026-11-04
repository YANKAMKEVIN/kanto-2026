# Jalon JOH5 — La Tour Radio de Doublonville (fin de l'acte 1)

> Sources de vérité : `docs/design/dossier-joh-06-tour-radio.md` (textes T-1 à T-38, arbitrages
> JH-40 à JH-43 validés par Kevin le 2026-11-02 ; grilles `tools/plans/radio_tower_1f.txt` à
> `radio_tower_5f.txt` validées le 2026-11-02 ; vues peintes validées le 2026-11-03), cadre
> `dossier-joh-00-cadre.md` §4.2, systèmes du JOH0 (`jalon-joh0.md` §2.2 : `return_team`).
> Écrit le 2026-11-04 sur la branche `claude/joh5-tour-radio-dfd1ba` (cut de `main` @ `695e0216`),
> en parallèle des JOH1 à JOH4 et JOH6 à JOH9 (validation déléguée par Kevin le 2026-11-04).

> Objectif jouable : **de la porte de la Tour au départ d'Orme** : faux employé démasqué par la
> Carte d'accès, quatre étages de Sbires, réserve des employés, Cenere, la voix de Dante, le
> bureau du directeur, **le retour de l'équipe** (choix des 6, Stockage reconnecté, sacs fusionnés,
> une seule écriture), la Multi Exp, puis l'Agente et Orme au hall (`johto_act2`).

## 0. État des lieux et dépendances

| Point | Réel | Conséquence |
|---|---|---|
| Retour de l'équipe | `TeamConfiscation.restore`, étape `return_team` + `save`, écran `TeamReturnOverlay` (titre [D] du JOH0), compagnon rendu | Mise en scène (§2.5) ; l'écran n'est **pas** montré à 6 Pokémon ou moins (dossier §7.3) |
| Doublonville | Codée par le **JOH3** (session parallèle) ; grille `doublonville.txt` : porte (10..11, 15), retour `retour_tour_radio` (10..11, 16) | Sortie du 1F vers `goldenrod_city:retour_tour_radio`, « à venir » tant que la carte manque ; T-1, T-35 à T-37 posés **après** la fusion du JOH3 (§2.8) |
| Souterrain | Grille `souterrain.txt` = JOH3 (dossier JOH-04 §3.2) ; le dossier JOH-06 §1 met l'entrepôt souterrain hors périmètre | **Pas codé ici** |
| Carte d'accès, Ordre de mission | Objets clés du JOH4 (drapeaux `johto_brace_defeated`, `johto_radio_pass`) | Ids demandés au JOH4 ; [D] `radio_card`, `rocket_orders` |
| Grotte marine (T-38) | JOH1 (`CurrentGate` levée par `johto_team_returned`) | T-38 ajouté après la fusion du JOH1 (§2.8) |
| Sylphe SARL | Étages en modules (`build_silph_co.gd`), cabine, `ElevatorDirector`, `KeyDoor` | Modèle de l'outil de la Tour |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH5A** — la Tour | T1 outil des 5 étages + cabine, T2 données (Dresseurs, PNJ, objets, dialogues), T3 scènes (faux employé, réserve, Cenere, Dante), T4 zone, ascenseur, musique, départs de débogage | Captures Mac |
| **JOH5B** — le retour | T5 bureau, retour de l'équipe, Multi Exp, T6 Agente et Orme, `johto_act2`, T7 test de reprise | **Seul** sur le téléphone (écriture unique) |
| **JOH5C** — raccords | T8 Doublonville (T-1, T-35 à T-37, raccord de la porte) et grotte marine (T-38) après les fusions du JOH3 et du JOH1 ; objectifs du Menu | CI |

## 2. Conception technique

### 2.1 Cartes

| Carte | Grille | Taille | Lumière |
|---|---|---|---|
| `goldenrod_radio_tower_1f` … `_5f` | `radio_tower_<n>f.txt` | 24 × 16 | `office` [D] |
| `goldenrod_radio_tower_elevator` | `sylphe_ascenseur.txt` [D] (cabine 4 × 4 de la Sylphe) | 4 × 4 | `office` |

Outil `tools/build_joh5_radio_tower.gd`, modèle `build_silph_co.gd` : kit des modules de la
Sylphe (moquette, murs, mobilier `M`) **provisoire** ; rayonnages `r` = armoires, pupitres `p` et
comptoir `c` = bureaux ; vitres `V` et escalier de secours `S` = murs [D] (vitres transparentes en
phase DA, « Reportés »). Titre « Tour Radio ». La grille fait foi (test : cases bloquées de la
scène = grille).
- `escalier` → WarpPoint STEP_ON (arrivée tournée comme la cible) ; `warp` (1F) → PUSH ↓ vers
  `goldenrod_city:retour_tour_radio` (« Doublonville » à venir tant que la carte manque) ;
  `spawn` → Marker2D ; `ascenseur` → porte STEP_ON vers la cabine, **`if_flags:
  [johto_cenere_defeated]`** ; `examen_ascenseur` → InteractPoint `unless johto_cenere_defeated` ;
  `declencheur` → EventTriggerPoint (scène du §2.3) ; `porte_cle` → `FlagGate` bloquante
  (`unless` le drapeau d'ouverture) + InteractPoint EXAMINER vers la scène de la porte ;
  `examen`, `decor` (haut-parleur), `cache` → InteractPoint. PNJ, Dresseurs, objets visibles :
  données (`data/npcs/`), cases praticables dans la scène.
- Ascenseur (`data/world/elevators.json`, entrée `goldenrod_radio_tower`, sans clé) : 5 étages,
  cabine `goldenrod_radio_tower_elevator` ; desservi après Cenere (T-32 « L'ascenseur remarche »).
- Zone `goldenrod_radio_tower` « Tour Radio » (`kind: place`, `region: johto`, T-14) ;
  `interiors.json` (Corde Sortie refusée, compagnon rentré) [D] ; musique `silph_co` [D] (lot Son).

### 2.2 Données (`tools/gen_joh5_data.py` → `data/npcs/goldenrod_radio_tower_*.json`,
`data/trainers/goldenrod_radio_tower.json`, `data/dialogues/joh5_radio_tower.json`,
`data/cutscenes/joh5_radio_tower.json`)

- 11 Dresseurs du dossier §5 (équipes et niveaux tels quels), classe `sbire_rocket` /
  `sbire_rocket_f` [D], prix 40 ₽ par niveau [D] (Cenere 60 [D]) ; IA `random`, Cenere `smart`,
  `switch`, carte « CENERE — Admin de la Team Rocket » [D]. Sbires évitables : vision de la grille.
- Faux employé et Cenere : PNJ sans bloc `trainer` (combat par la scène) ; sprites
  `rocket_grunt_m` (faux employé : `engineer` jusqu'au combat [D]), Cenere `rocket_grunt_f` [D] ;
  directeur `gentleman`, Raphaël `engineer`, employés `hostess` / `engineer`, Agente `guard`, Orme
  `researcher` (comme le JOH1) [D].
- Objets (§6) : PNJ `object/poke_ball_ground` (PRENDRE) ou cachés (EXAMINER), drapeaux `got_<id>`.
- Textes T-1 à T-38 **mot pour mot** (« / » = page) ; voix des haut-parleurs : locuteur
  « Haut-parleur » (T-1, T-37), Dante « Voix » (T-19) puis « Dante » (T-20, T-21) [D] ; textes
  absents du dossier en `draft` (porte fermée de la réserve, porte du bureau) + `PENDING_DRAFTS`.

### 2.3 Scènes de la Tour

| Scène | Lancement | Contenu |
|---|---|---|
| `goldenrod_radio_impostor` | déclencheur (3, 2), `unless johto_radio_impostor_defeated` | **avec** `johto_radio_pass` : T-2, combat (défaite : réveil), T-3, T-4, fuite par l'escalier ; **sans** : D-18 (JOH3), `johto_radio_tower_closed_seen`, un pas en arrière |
| `goldenrod_radio_reserve_door` | EXAMINER (17, 11) | avec `johto_radio_reserve_key` (posé par la réplique « défaite » du gardien, T-8) : T-9, `johto_radio_staff_freed` ; sinon « fermée à clé » [D] |
| `goldenrod_radio_raphael` | Raphaël | T-11, il sort par la porte, `johto_radio_staff_talked` |
| `goldenrod_radio_cenere` | déclencheur (12..13, 6), `unless johto_cenere_defeated` | T-15, T-16, combat (défaite : réveil, Cenere reste), T-17, T-18, T-19 à T-21, apparition de trois Sbires, T-22 (deux partent, JH-43), T-23, Cenere sort par l'escalier de secours, `johto_dante_revealed` |
| `goldenrod_radio_office` | déclencheur (7, 2) **ou** le directeur, `if johto_dante_revealed unless johto_team_returned` | §2.5 |
| `goldenrod_radio_exit` | déclencheur (1..22, 12), `if johto_team_returned unless johto_act2` | T-33, retrait des deux objets clés, T-34, `johto_act2` |

### 2.4 Ordre et cas limites

Défaite contre Cenere : réveil au dernier point de repos (Centre de Doublonville) ; les Sbires
battus le restent (`beaten_<id>`) ; Cenere est toujours au micro. Sortie avant Cenere : rien ne
change (T-1 en ville au JOH5C). Ascenseur en panne (T-5, D-19 au 1F avant le faux employé).

### 2.5 Le bureau et le retour de l'équipe (JOH5B)

Scène `goldenrod_radio_office` : T-24, T-25 (directeur, puis « {player} détache le directeur. »),
T-26, T-27 (jeton **`{returning_pokemon}`** : compagnon d'avant le vol, sinon le premier de
l'équipe confisquée ; jeton neuf de `DialogueTokens`, valeur donnée par Boot tant qu'une équipe
est confisquée [D] : le texte affiché est T-27 mot pour mot), **`return_team`** (écran du choix des
6 titré T-28 ; **sauté** quand les deux équipes font 6 Pokémon ou moins : tout le monde rentre,
dossier §7.3), T-29 si des Pokémon sont allés au Stockage (drapeau de travail
`johto_return_stored`, posé par Boot sur `team_returned`), T-30, **`save`** (seule écriture), puis
T-31 (Multi Exp, ou 3 Super Bonbons si `exp_all` est déjà dans le Sac), `radio_exp_share_given`,
T-32. Reprise : application tuée avant le `save` → rien n'a changé dans le fichier, la scène
rejoue (déclencheur ou directeur) ; après le `save` sans la Multi Exp → le directeur la donne
(variante `if johto_team_returned unless radio_exp_share_given`).

### 2.6 Départs de débogage (`tools/debug_start/`)

`johto_radio_tower` (1F, Carte d'accès, équipe de Johto niv. 26–28, équipe de Kanto confisquée,
drapeaux de l'acte 1 jusqu'au JOH4), `johto_radio_tower_5f` (devant la vitre, étages nettoyés),
`johto_radio_tower_office` (Dante révélé, devant le bureau, **`autosave: true`** : la scène écrit
la vraie sauvegarde ; QA : arrêt de l'appli puis « Continuer »), `johto_radio_tower_small`
(bureau, 2 + 3 Pokémon : pas d'écran), `johto_radio_tower_egg` (œuf non éclos dans l'équipe).

### 2.7 Tests

`test_joh5_data` (Dresseurs = dossier §5, textes T-n mot pour mot, drapeaux §10), `test_joh5_maps`
(grille = scène, raccords, Sbires inévitables : la case vue est le seul passage), `test_joh5_story`
(ordre faux employé → étages → Cenere → Dante → bureau sur le vrai `CutsceneDirector` sans écran ;
total ≤ 6 sans écran ; > 6 ; œuf ; sacs fusionnés ; drapeaux de fin d'acte ; Multi Exp ou Super
Bonbons ; preuves remises), `test_joh5_return_resume` (fichier écrit avant / après le `save`, reprise
du bureau, sauvegarde rechargée = équipe rendue, acte 2).

### 2.8 Raccords (JOH5C)

Après la fusion du JOH3 : D-18 et D-19 joués avec les dialogues du JOH3
(`goldenrod_radio_tower_impostor_closed`, `goldenrod_radio_tower_elevator_closed`, prévus pour le
hall du JOH5) à la place des copies du JOH5 ; T-1 / T-37 aux haut-parleurs de Doublonville (variantes `unless` /
`if johto_cenere_defeated`), femme de D-37 (variante T-35, Ultra Ball ×3,
`goldenrod_husband_gift`), Raphaël chez lui (T-36, `if johto_radio_staff_talked`), raccord de la
porte vérifié. Après la fusion du JOH1 : T-38 au premier passage dans la grotte marine.

## 3. Valeurs par défaut [D]

Lumière `office` ; vitres et escalier de secours en murs (provisoire) ; sprites §2.2 ; prix
40 ₽ / niveau, Cenere 60 ; IA `random`, Cenere `smart` ; musique `silph_co` ; locuteurs des voix ;
Raphaël rentre dès qu'on lui a parlé ; Sbire 1 (« Dante ? C'est qui, ça ? ») reste au 5F jusqu'au
retour, Sbires 2 et 3 partent ; animation des retrouvailles (le compagnon bondit) remplacée par le
texte T-27 (phase DA) ; textes « porte fermée » en `draft`.

## 4. Fait

| Date | Quoi |
|---|---|
| 2026-11-04 | T1 cartes (5 étages + cabine), T2 données, T3 scènes, T4 zone / ascenseur / musique / départs, T5 bureau et retour de l'équipe, T6 Agente et Orme, T7 tests (`test_joh5_data`, `test_joh5_maps`, `test_joh5_story` : parcours joué, arrêt pendant l'écran des 6 et reprise, œuf, Multi Exp déjà possédée, défaite contre Cenere) ; T-38 dans la grotte marine (JOH1 refusionné) ; objectifs [D] ; captures Mac relues ; CI verte sur `b150bbc0` |
| 2026-11-04 | QA A17 sans P0/P1 (`docs/tech/qa/joh5-a17-2026-11-04.md`) |
| — | Reste : raccords Doublonville après la fusion du JOH3 (sortie du 1F reconstruite, T-1, T-35 à T-37, D-18/D-19 du JOH3) |

Écarts au plan : points des portes fermées en EXAMINER (OUVRIR est réservé aux portes à carte du
`KeyDoorDirector`) ; Cenere sans séquence « VS » ni changement de Pokémon, comme Brace au JOH4.
