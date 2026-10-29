# Jalon 33 — Baseline (T1)

> Relevé du 2026-10-28, sans modification de code. Plan : `jalon-33.md` §2 T1.

## 1. En-tête

| Élément | Valeur |
|---|---|
| Commit de référence | `212b52d0b77ab8dbd4dd2305188e2171a2ad1b3d` (= `origin/main`, « Fusionne jalon-32 … validé par Kevin le 2026-10-28 »), commit du 2026-10-28 23:12 +0100 |
| Godot | `4.7.2.stable.official.ed1daf0bf` |
| Date du relevé | 2026-10-28 |
| Machine | Mac de Kevin, mesures headless |

## 2. Inventaire J0–J32 et chantiers hors numérotation

Preuve de fusion : `git merge-base --is-ancestor <commit> HEAD` vérifié le 2026-10-28 (HEAD = `212b52d0`) ; branche `jalon-XX` sans commit hors de HEAD. « Inconnu » = pas de preuve trouvée dans les documents ou l'historique.
Sources : `docs/design/roadmap.md` (à jour jusqu'au J20 seulement), `docs/tech/etat-projet.md`, `docs/tech/jalon-XX.md`, `git log`.

| Jalon | Fusionné dans main (preuve) | Validé par Kevin | QA téléphone | Restes connus non bloquants |
|---|---|---|---|---|
| J0 | Pas de `jalon-00.md` ni de branche ; la roadmap classe « J0 → J4 » en phase 1 terminée | roadmap : ✅ | inconnu | — |
| J1 | Antérieur au J3A (`dad5d5a`, 2026-09-26) ; pas de commit de fusion distinct retrouvé | 2026-09-25 (`jalon-01.md` §7) | S24, 2026-09-25 | — |
| J2 | Idem J1 | 2026-09-26 (`jalon-02.md` §8) | S24, 2026-09-26 | — |
| J3 (3A, 3B) | `dad5d5a` (3A), `735b0ee0` (3B, validation) 2026-09-26 | 2026-09-26 | S24 | — |
| J4 (4A, 4B) | `e6379a83` (4A, 2026-09-26), `3f530a40` (4B, 2026-09-29) | oui (« validé par Kevin sur S24 ») | S24, 2026-09-26 puis 2026-09-29 | — |
| J5 | `d8e8f2b7` 2026-10-02 | oui | S24, 2026-10-02 (60 fps) | — |
| J6 | `d44077d4` 2026-10-05 | oui | S24, 2026-10-05 (60 fps, menu 62 en combat) | — |
| J7 | `7fd51865` 2026-10-06 | oui | S21 (QA finale) 2026-10-06 | — |
| J8 | Pas de commit de fusion retrouvé par grep ; branche `jalon-08` absente, roadmap « ✅ 2026-10-07 », ancêtre de J9 | 2026-10-07 (roadmap) | S24 (Route 2 à 53 fps, `jalon-09.md`) | — |
| J9 | Branche `jalon-09` fusionnée (0 commit hors HEAD) ; roadmap ✅ 2026-10-08 | oui (QA finale T22 S21, 2026-10-08) | S21, 2026-10-08 | — |
| J10 | Branche absente ; roadmap ✅ 2026-10-10, `jalon-10.md` « TERMINÉ le 2026-10-10 » | 2026-10-10 | S21, 2026-10-10 (QA finale 10D) | — |
| OUV (ouverture) | `29ed0369` (2026-10-10), `556629c4` (OUV.2, 2026-10-11) | 2026-10-11 (OUV.2 après QA S21) | S21 | — |
| J11 | Branche absente ; roadmap ✅ 2026-10-13 | 2026-10-13 | S21 (état : S21 depuis le 2026-10-10) | Art partiel : 3 planches sur 5 ; mémoire `tex` 118–135 Mo et forêt 48–49 fps en combat au S21 (noté `jalon-12.md`) |
| J12 | `jalon-12` fusionnée ; roadmap/`jalon-12.md` « validé le 2026-10-14 » | 2026-10-14 | S21 | — |
| J13 | Branche absente ; roadmap/CLAUDE.md « terminé 2026-10-14 » | 2026-10-14 | S21 (rapports `build/qa/jalon13_*` du 2026-10-14) | — |
| J14 | `1d3bb84c` 2026-10-15 | 2026-10-14 (14.0, 14A–14C) | S21 | — |
| J15 | `440f9b17` 2026-10-15 (clôture notée 2026-10-16) | oui | S21 | Textures ≈ 94 Mo à Carmin (> 64 Mo, sans ralentissement) |
| J16 | `2d648666` 2026-10-16 | 2026-10-16 (16A–16F) | S21 | — |
| J17 | `aebbd857` 2026-10-19 | 2026-10-19 (17.0–17D) | S21 (QA 17A–D, 2026-10-16) puis sessions S24 | Route 11 : 49 → 53 i/s sur A17 |
| J18 | `d397b2df` 2026-10-19 | accordé par Kevin | S24 (QA 18A–18C, sans bloquant) | R-8 lumière de la Grotte Sombre à revoir au J33 |
| J19 | `06bdb0fa` 2026-10-19 | 19A et 19B validés | S24 (QA 19A, 19B, sans bloquant) | 5F à 39 i/s sur A17 (60 sur S24) |
| J20 | `537c40f0` 2026-10-20 | oui (clôture T24) | S24 `RFCX80Y0FVX` (T23, 2026-10-20) | — |
| Passe systèmes 2 (S2A–S2Z) | `58f5b7d4` 2026-10-22 (S2Z clôture) | S2B/S2C/S2D validés (2026-10-21/22) | S24/A17 | Téléporteurs : voir `systemes-2.md` |
| J21 | `a735bdbb` 2026-10-22 | 21A et 21B validées | inconnu (A17 cité pour la perf) | Route 12 (eau) 23–27 i/s sur A17, traité ensuite par moteur commun |
| Moteur commun | `a000bfe8` 2026-10-23 | inconnu (documenté comme fusionné) | A17 (Routes 11/12/16 ≈ 50 i/s) | « 60 i/s pas atteint dehors » sur A17 (R-9) |
| J22 | `e8b2b09d` 2026-10-23 | 2026-10-23 | inconnu (QA « validées ») | — |
| J24 | `0c55dcf3` 2026-10-23 | 2026-10-23 | inconnu (QA « validées ») | A17 plafonné à 50–55 fps |
| J25 | `23ad8965` 2026-10-24 | 25A–25C validés (accord de push 2026-10-24) | inconnu | RP-024 : Cramois'Île en aplats provisoires, à vérifier (P1 si confirmé) |
| Son (jalon-son) | Branche fusionnée (2026-10-25, `etat-projet.md`) | oui (lots validés) | inconnu | — |
| DAF.0–DAF.3, DAF.4 (part), DAF.5, DAF.7 (DA finale) | Fusionnés 2026-10-24 à 10-27 (`3f8ccbf0`, `4b62ad85`, `0f58c788`, `b68ee46d`) | planches validées (DA-6) | — | **DAF.4 fin (sol Route 23 / Plateau Indigo) non fusionné** (branche `claude/daf-4-route-23-b20c52`, « planche à valider ») |
| Combat vivant CV.0 à CV.3, lots fx | `23bca81c` (CV.0, 2026-10-27), CV.3 `d3c9bd36`, CV.1 et fx-2 fusionnés | vidéos validées 2026-10-26/27 | S24 : T8 60,0 i/s (2026-10-27) | — |
| IA « smart » (statuts) | `495034a2` 2026-10-27 | règle de Kevin codée | — | — |
| J23 | `3274bddb` 2026-10-27 (CI 10-26) | 23A à 23E validés (23E le 2026-10-25) | S24 / A17 (QA 23B–23D) | Koga ≈ 100 % : gardé aux niveaux RB (Q23-1) ; T23 QA bout en bout au doigt restait à faire |
| J26 | `5522e41a` 2026-10-26 (avec J27) | 2026-10-25 | A17 + S24, sans bloquant | Défauts mineurs dans « Reportés » |
| J27 | `5522e41a` 2026-10-26 | 2026-10-25 | A17 + S24, sans bloquant | idem |
| J28 | `183756b7` 2026-10-26 | 2026-10-25 | A17 + S24, sans bloquant | Jadielle 39–41 i/s sur A17 |
| J29 | `8823dfd4` 2026-10-27 | oui | S24, 2026-10-26 (59 i/s) | Sulfura de carte provisoire ; rencontres Route Victoire fréquentes (à confirmer avec la table RB) |
| J30 | `b8b596c2` 2026-10-27 | 2026-10-27 (QA 30A) | S24, 2026-10-26 et 2026-10-27 | Vraie victoire de la Ligue non rejouée à la main ; objectif « Pont Pépite » périmé (J31 §11.1) ; ≈ 40 i/s en combat sur A17 |
| J31 | `0df81b3f` 2026-10-27 (+1 commit de doc hors main : `jalon-31`, « K.O. de Mewtwo vu sur le S24 ») | oui | S24, 2026-10-26 (59 i/s) | Mewtwo de carte recouvre le héros (art provisoire) ; objectifs J22–J31 à valider |
| J32 | `212b52d0` 2026-10-28 | 2026-10-28 (« Oui, fusionne ») | S24, 2026-10-28 (60 i/s) | À vérifier au doigt : Coupe-Vent en combat, etc. ; RP-255 à RP-257 ; CT31 Copie écartée (49 CT sur 50) ; Diplôme et Grand moment reportés à la phase DA |

Jalons absents comme tels : il n'y a **pas de J3B séparé dans la liste J0–J32 du plan** (il est fusionné avec le J3) ; les J1 à J3 n'ont pas de commit de fusion (branches cloud, validées avant le 2026-09-26). Aucun jalon J0–J32 n'est non fusionné.

## 3. Tests

| Élément | Valeur |
|---|---|
| Scripts de test | **731** `test_*.gd` (373 integration, 343 unit dont audio 5 et opening 8, + 2 dans integration/audio ; `find tests -name 'test_*.gd' \| wc -l`). Le plan `jalon-33.md` §0 parle de 544 scripts : périmé. |
| Nombre de tests | non relancé (suite complète interdite sur le Mac) ; dernière valeur notée : 6 889 / 6 889 (`etat-projet.md`, J32 avant fusion) |
| CI GitHub, `main` @ `212b52d0` | **verte** : run 40778143531, workflow godot-tests, 22:12:22Z → 22:23:39Z UTC (11 min 17 s), conclusion `success` |

Lots de la CI de `212b52d0` :

| Lot | Conclusion | Durée |
|---|---|---|
| GUT (0) | success | 10 min 09 s |
| GUT (1) | success | 10 min 44 s |
| GUT (2) | success | 9 min 23 s |
| GUT (3) | success | 11 min 14 s |
| GUT (4) | success | 11 min 07 s |
| GUT (5) | success | 10 min 17 s |
| GUT (6) | success | 9 min 06 s |
| GUT (7) | success | 10 min 24 s |

Dernières runs de `main` : `495034a2` success (10-27), `750b7473` success, `d3c9bd36` success ; trois `cancelled` (`0f58c788`, `23bca81c`, `e772538c`), annulations par un push plus récent. Branche `jalon-32` : aucune run (branche fusionnée, runs sur `main`).

## 4. Mesures de chargement de carte (Mac, headless)

Commande exacte (depuis la racine du dépôt) :

```
godot --headless --path . -s res://tools/measure_map_load.gd -- route_1 celadon_city pokemon_mansion_1f mt_moon_b1f
```

Sans `--headless` (`--resolution 1170x540`, commande de l'en-tête de l'outil), le processus **n'a rien affiché et est resté bloqué plus de 5 min** (aucune sortie) dans cet environnement ; arrêté par PID. Les chiffres ci-dessous viennent du mode headless, donc sans rendu GPU : indicatifs seulement. Outil : lecture disque sans cache, instanciation, entrée dans l'arbre, première image ; 5 répétitions par carte (constante `REPEATS = 5`).

| Carte | Type | Médiane (total) | Plage des 5 mesures |
|---|---|---|---|
| `route_1` | extérieur | 562 ms | 469–723 ms |
| `celadon_city` | ville | 920 ms | 848–1 008 ms |
| `mt_moon_b1f` | donjon | 146 ms | 117–353 ms (1re mesure à froid) |
| `pokemon_mansion_1f` | donjon (intérieur) | 77 ms | 61–120 ms |

`measure_map_cache.gd` : non lancé (outil pour le trajet Bourg Palette → Mont Sélénite, avec rendu : même blocage probable hors headless, et le pilote factice ne compte aucune texture en headless). À lancer sur le Mac avec fenêtre lors de la QA du J33 si utile.

## 5. FPS par zone

**Relevés antérieurs, à refaire sur `212b52d0` lors de la QA S24 du J33.** Aucun téléphone dans cette tâche. `build/qa/` n'existe pas dans ce worktree.

| Zone | Dernier relevé S24 trouvé | Date, jalon, source | Remarque |
|---|---|---|---|
| Extérieur | 59 i/s en exploration (creux 34–39 au chargement de carte) | 2026-10-26, J29, `etat-projet.md` « QA S24 du J29 » (Route Victoire, Plateau Indigo) | Route 11 « 60 fps à froid » (S24, J17, 2026-10-16) |
| Ville | **Pas de relevé S24 sur une grande ville récente.** Safrania : 53,5 / 47,3 / 47,9 i/s sur **A17** (2026-10-23, J26, avant DAF.3) ; Lavanville 60 fps (J19, draw 254–343, tex 84 Mo, 39–44 °C) ; Jadielle 39–41 i/s sur A17 (J28) | `etat-projet.md`, `jalon-28.md` | À mesurer : Safrania, Céladopole, Carmin |
| Donjon | 59 i/s dans la Grotte Azurée ; Parmanie/Arène de Koga 60 i/s | 2026-10-26, J31 ; J23 | 5F de la Tour : 60 sur S24 (39 sur A17) |
| Combat | 60,0 i/s (CV.0 T8) ; 59 i/s en combat à la Grotte Azurée (J31) | 2026-10-27, `combat-vivant.md` ; 2026-10-26, J31 | A17 : ≈ 40 i/s en salle d'Olga et d'Aldo (J30, ancien) |
| Menu Stockage | **Aucun relevé de cadence.** Le Stockage a été ouvert au doigt (recherche, 4 tris) à la QA J32 ; seul « lancement 60 i/s » est noté | 2026-10-28, J32 | Menu Équipe sur Jadielle : 50 fps (S21, J7, fond flou, draw 385, ancien) |

## 6. Points d'attention

1. **Aucun jalon J0–J32 n'est non fusionné.** Hors main : 1 commit de doc sur `jalon-31` (QA Mewtwo), `claude/daf-4-route-23-b20c52` (sol Route 23, planche à valider), `claude/kind-burnell-8cdce9` (fonds de combat Azuria et Carmin, RP-014), `docs/dossier-heroine` (documents), `plans-j31-j40`.
2. Registre des reportés (`reportes.md`) : P0 0, **P1 7 ouverts** (dont RP-014 fonds de combat, RP-024 Cramois'Île en aplats, RP-133/136/143/150 des branches) ; la sortie du J33 exige zéro P1.
3. QA téléphone inconnue pour J21, J22, J24, J25, Son et moteur commun (« validées » sans appareil nommé) ; la perf y est surtout relevée sur l'A17, retiré depuis le 2026-10-27.
4. Pas de relevé S24 récent pour une ville (Safrania, Céladopole) ni pour le Stockage ; R-8 et R-9 renvoyés au J33.
5. `jalon-33.md` §0 est périmé : 731 scripts (non 544) ; pas encore de `version/code` ni `version/name` dans `export_presets.cfg` (aucun résultat à la recherche).
6. `measure_map_load.gd` bloque hors headless dans cette session (pas d'affichage) ; mesures headless seulement, sans coût de rendu.
7. Trois runs `cancelled` sur `main` (annulations par push suivant), sans lien avec un échec de test.
8. `roadmap.md` n'est plus à jour au-delà du J20 (« J21+ ← ICI ») ; `etat-projet.md` fait foi pour J21–J32. Le J3B n'a pas de ligne séparée dans le plan J0–J32.
