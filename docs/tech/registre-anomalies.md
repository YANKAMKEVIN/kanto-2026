# Registre des anomalies — J33 T6

> Registre de la campagne complète (`jalon-33.md` §2 T6) : une ligne par anomalie trouvée en
> jouant (passe humaine de Kevin sur téléphone, ou parcours headless de préparation). Format
> fixé par T6 **[D]** : ID, priorité, build, étapes, état. Priorités P0 à P3 de `jalon-33.md` §1.
> Une anomalie n'est **fermée qu'après rejeu réussi** du scénario (même build ou plus récent).
> Un point déjà connu garde son identifiant `RP-NNN` de `reportes.md` ; un point nouveau prend
> le prochain `RP-NNN` libre (vérifié sur toutes les branches distantes) et entre aussi dans
> `reportes.md`.
>
> **Build** : commit (8 caractères) et, pour une passe sur téléphone, l'appareil (A17 ; le S24
> n'est pas disponible). **État** : *ouvert* · *corrigé, à rejouer* · *fermé (rejoué le …)* ·
> *accepté (P2/P3, décision de Kevin)*.

## Ouvertes

| ID | P | Build | Étapes pour reproduire | Constat | État |
|---|---|---|---|---|---|
| RP-284 | P3 | `d5376e50` (headless) | `--debug-start game_corner` ; repaire jusqu'au B4F, Giovanni battu, Scope ramassé depuis (25, 3) ; sauvegarder sur place ; relancer l'appli | reprise en (24, 3), une case à gauche (case de départ de Giovanni écartée même s'il a disparu) | ouvert (1.0.x) |
| RP-285 | P3 | `d5376e50` (headless) | `--debug-start snorlax_16_qa` (ou `j25_manoir`, 17 départs) ; sauvegarder ; relancer | CS01 rendue (ou drapeau `got_hm01` levé) au chargement : le départ était incohérent | ouvert (outil) |

## Fermées

| ID | P | Build | Rejeu | État |
|---|---|---|---|---|
