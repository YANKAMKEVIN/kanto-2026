# Jalon JOH8 — La flamme : Bois de la Tour, Tour Carillon, Dante (1), Entei, Ho-Oh

> **PLAN.** Sources de vérité : `docs/design/dossier-joh-09-tour-carillon.md` (textes H-1 à H-38
> et arbitrages JH-52 à JH-55 validés par Kevin le 2026-11-02 ; le reste porte des défauts
> **[D]**) ; cadre `dossier-joh-00-cadre.md` (§4.3, §4.5, §7 : niveaux 62–68) ; grilles
> `tools/plans/bell_tower_woods.txt`, `bell_tower_1f.txt`, `bell_tower_2f.txt`,
> `bell_tower_roof.txt` (validées le 2026-11-03, **elles font foi**) et la retouche de
> `rosalia.txt` (sage blessé, raccord nord) ; vues générales `docs/design/reference/bois-de-la-tour-*`,
> `tour-carillon-1f-*`, `tour-carillon-2f-*`, `tour-carillon-sommet-*` (DA seulement). Systèmes du
> JOH0 (`jalon-joh0.md` §2), conventions du JOH1 (moment imposé `JohtoPeriodRule`) et du JOH2
> (cartes depuis une grille, données générées, préfixe de fichiers). Écrit le 2026-11-04 sur la
> branche `claude/joh8-carillon-ab63fa` (cut de `main` @ `bdcc90ae`, JOH1 fusionné tôt pour ses
> outils ; `main` refusionné dès que JOH1 et JOH2 y sont).

> Objectif jouable : **de Rosalia au sommet de la Tour Carillon et retour** : le sage blessé (H-1)
> au pied du chemin gardé, le doyen qui ouvre la tour (H-2, H-3), le Bois de la Tour (Sbire de guet
> évitable, Hyper Potions, panneau, lanternes), le 1F (sages assommés, Sbire V inévitable, Rappel
> Max), le 2F (planches qui cèdent → chute au 1F, Sbire W, Hiroshi qui soigne, PP Plus), le long
> escalier en fondu (H-12), le sommet **à l'aube forcée** (Dante, la cage de feu, premier combat
> contre Dante, la cloche, Ho-Oh qui refuse Dante, la fuite sur Arcanin, Entei puis Ho-Oh en
> rencontres fixes capturables, la Plume Arc-en-ciel), puis Rosalia (doyen H-34, Orme H-35 / H-36,
> habitante H-37, Diane H-38 le dimanche) et `johto_act3`.
>
> Validation **déléguée** (décision de Kevin du 2026-11-04) : tests GUT, CI verte, QA A17, fusion
> dans `main`, compte rendu à la coordination. Aucun format de sauvegarde ne change.

## 0. État d'entrée (relu le 2026-11-04)

| Point | Réel | Conséquence |
|---|---|---|
| JOH3 à JOH7 | Codés en parallèle par d'autres sessions ; rien dans `main` | Départs de débogage qui posent l'état de fin du JOH7 (`johto_lugia_done`, `johto_bell_tower_clue`, drapeaux des actes 1 et 2, équipe 62–68) |
| Rosalia | Carte du JOH2 (branche à fusionner) : chemin gardé (42..43, 0..13), garde R-20 (41, 13), déclencheur `barriere_carillon` `unless johto_bell_tower_open`, warp nord « À venir » vers `bell_tower_woods` / `from_ecruteak`, `sage_blesse` (44, 13) **sauté** par le JOH2 | JOH8 : PNJ `sage_blesse` (H-1), garde `unless johto_bell_tower_open`, reconstruction de Rosalia (`build_joh2_maps.gd --maps=ecruteak_city`) quand mes cartes existent |
| Doyen | `ecruteak_elders_house` (JOH2, dialogue `ecruteak_elders_house_doyen`) ; le JOH6 y ajoute C-10 à C-12 | Variantes JOH8 (H-2 + H-3 ; H-34) **en tête** du dialogue, ajoutées à la fusion ; ancienneté JOH6 > JOH8 |
| Diane (dimanche) | PNJ du JOH6 (C-46) | H-38 : variante `if johto_ho_oh_seen` ajoutée à son dialogue après la fusion du JOH6 ; texte prêt dans `joh8_ecruteak.json` |
| Moment imposé | `JohtoPeriodRule` (JOH1) : règle pure sur les drapeaux | Aube du sommet = règle **par carte** (§2.6), branchée dans `Boot._apply_story_period` |
| Espèces | Entei, Ho-Oh et toutes les équipes existent (`johto.json`, Kanto) | Rien à ajouter |
| Art | Vues validées, aucun décor peint, aucun sprite de Dante, Ho-Oh, cage | Tuiles provisoires, sprites existants [D], aplats ; « Reportés » |

## 1. Découpage

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH8A** — la tour | T1 données générées, T2 quatre cartes, T3 raccords, planches qui cèdent, T4 données de monde | Tests, captures Mac |
| **JOH8B** — la flamme | T5 scènes de Rosalia (sage blessé, doyen, après), T6 sommet (Dante, cloche, Ho-Oh, fuite, Entei, Ho-Oh, plume), T7 aube forcée, T8 Corde Sortie, T9 départs de débogage, T10 tests, T11 captures | Tests, captures Mac |
| Clôture | T12 QA A17, T13 CI verte et fusion, T14 état du projet, compte rendu | Déléguée |

## 2. Conception technique

(complétée au fil de l'implémentation ; §2.1 à §2.9)
