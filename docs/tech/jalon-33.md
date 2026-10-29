# Jalon 33 — Stabilisation globale et version de référence

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j33-v1-chatgpt.md` (7 décisions verrouillées). Décisions et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> Objectif : **une version de référence testable sur le S24, avec preuves et registre des
> anomalies.** Aucun ajout fonctionnel majeur : une idée « intéressante » ne suffit pas. Sortie :
> APK de test versionné + rapport QA + décision de livraison.
>
> **Ce jalon ne commence pour de bon qu'une fois J0–J32 fusionnés.** Mais son outillage (mesure,
> campagne scriptée, sauvegarde) peut avancer maintenant.

## 0. État et dépendances (relu sur le dépôt)

> **Gel fonctionnel en vigueur depuis le 2026-10-29** (`main` @ `ad1914bf`) : J0–J32, DAF.4, T1, T4, Reportés P1, CV.1 + CV.3 et lot 32P fusionnés. Désormais seuls les correctifs (§1).

| Domaine | Réel aujourd'hui | Manque |
|---|---|---|
| Tests | ≈ 6 890 tests GUT, 731 scripts (baseline T1 : `jalon-33-baseline.md`) ; `tools/test.sh` (ciblé, `--changed`, verrou de 2 suites) ; `tools/check_test_timing.sh` ; CI 8 lots (`.github/workflows/godot-tests.yml`) | Aucun test de parcours complet |
| Sauvegarde | `SaveSystem` : v7, écriture temporaire relue puis renommée, migrations, fichier corrompu mis de côté (`.corrupt`) | **Copie de secours** de la dernière sauvegarde valide |
| Arrière-plan Android | `game/systems/session/session_lifecycle.gd` : `APPLICATION_PAUSED` et `WM_CLOSE_REQUEST` demandent une sauvegarde stable (test `test_session_lifecycle.gd`) | À vérifier sur appareil, hors départ de débogage |
| Mesure | `tools/measure_map_load.gd`, `measure_map_cache.gd`, `measure_tower_t19.gd` ; rapports de QA dans `build/qa/` | Pas de mesure batterie ni température |
| Déploiement S24 | `tools/deploy_s24.sh` (installation, lancement, capture, départ de débogage), `tools/s24_serial.sh`, `tools/build_android.sh` (APK **debug**) | Pas d'APK versionné |
| Départs de débogage | ≈ 130 fichiers `tools/debug_start/*.json` | Servent aux parcours accélérés |
| Export | `export_presets.cfg` : preset « Android », arm64-v8a, `dev.kevin.kanto2026`, `tests/`, `tools/`, `docs/`, `addons/gut/` déjà exclus | Aucun `version/code` ni `version/name` |
| Art | `docs/design/inventaire-art.md` : provisoires encore présents (dos de combat en pixel art 64 px, 6 fonds de combat…) | Lots d'art à intégrer avant 33A |

### 0.1 Ce qui peut commencer tout de suite
- **T1** baseline : inventaire des jalons, état des tests, mesures de référence sur `main` ;
- **T4** copie de secours de la sauvegarde (**système de sauvegarde : validé seul**) ;
- **T3** scripts de mesure (batterie, mémoire en session longue) ;
- **T5** squelette de la campagne de parcours scriptés (départs de débogage existants).

### 0.2 Ce qui attend
- T2 (harmonisation visuelle) : après les lots d'art (série 22 bis faite ; dos de combat ensuite).
- T6 (campagne complète) : après J32. T7 (APK et décision) : après T2 à T6.

## 1. Contrats

- **Gel fonctionnel** : seuls les correctifs sont admis. Une correction visuelle ne déplace
  **jamais** une collision, un déclencheur de combat ou une coordonnée d'événement (contrôle :
  `tools/dump_map_logic.gd` avant/après).
- **Priorités** : P0 bloquant (crash systématique, sauvegarde corrompue, perte de Pokémon,
  progression impossible) ; P1 majeur ; P2 modéré ; P3 mineur. **Sortie : zéro P0 et zéro P1
  ouverts.** P2/P3 documentés, reproductibles, explicitement acceptés.
- **DA inchangée** : 2D HD peinte, orthogonale ; case ≈ 1 m, fenêtre ≈ 24 × 11 cases (96 px par
  case en 1920 × 1080, cohérent avec `CLAUDE.md`) ; dialogues de 2 lignes de 40 caractères.
- **Pas de chiffres annoncés sans exécution** : les cibles (60 FPS, mémoire stable, batterie) sont
  des objectifs de validation, ajustés après profilage.

## 2. Tâches

### T1 — Inventaire et baseline (Sonnet)
Pour chaque jalon J0–J32 : fusionné ? tests ? QA S24 faite ? Baseline : suite complète, 3 mesures de
chargement de carte, FPS sur 5 zones (extérieur, ville, donjon, combat, menu stockage).
Critère : `docs/tech/jalon-33-baseline.md` avec commit exact. **Fait le 2026-10-28** (sur `212b52d0`, CI verte ; FPS S24 à refaire à la QA du J33).

### T2 — Harmonisation visuelle (33A, Sonnet puis Kevin)
Grille de contrôle : sols, bâtiments, personnages, Pokémon, eau, donjons, combats, menus. Chaque
écart devient une ligne du registre, avec priorité. Corrections par lots d'art, pas à la main.

### T3 — Profilage Android (33C, Sonnet)
`tools/profile_s24.sh` [D] : session de 30 minutes avec relevé périodique de la mémoire ; protocole
batterie et température écrit (appareil branché ou non, luminosité fixée). Profils séparés :
extérieur, ville, grand donjon, combat, stockage. Optimisations seulement après mesure, sans
sacrifier la qualité peinte.

### T4 — Copie de secours de la sauvegarde (33D, Opus — validé seul)
Avant chaque remplacement du fichier, la dernière sauvegarde valide est conservée (`save.json.bak`
[D]). Au chargement : si le principal est illisible, essayer la copie ; sinon la mise de côté
existante (`.corrupt`). **Écriture bloquée** si le stockage est plein : message, aucune destruction.
Tests (`tests/unit/test_save_system.gd`, faux système de fichiers) : coupure à chaque étape de
l'écriture ; principal corrompu avec copie valide ; les deux corrompus ; version plus récente
refusée sans toucher ; disque plein.
Critère : aucun scénario ne laisse zéro sauvegarde valide alors qu'une existait.

#### T4 — plan retenu et état (2026-10-28, branche `claude/jalon-33-efe2a8`)
**Format inchangé** (v8, aucun champ nouveau) : la copie est le fichier précédent, octet pour
octet. Valeurs par défaut (règle 4) : `user://save.json.bak` à côté du principal (point ouvert 1,
[D] retenu) ; une seule copie ; les réglages (`settings.json`) n'en ont pas.

**Écriture** (`SaveSystem.write`) : 1. `save.json.tmp` écrit puis relu (inchangé) ; 2. si le
principal existe et est valide, il est **renommé** en `.bak` (aucune place disque en plus) ; s'il
est illisible, il est mis de côté en `.corrupt` et la copie existante reste ; 3. `.tmp` renommé en
principal. Validité : relu une fois par session, puis connue (lecture ou écriture réussie par la
même instance).

**Lecture** (`SaveSystem.read`) : principal valide → lu (copie ignorée) ; principal illisible →
`.corrupt`, puis la copie ; principal absent (coupure entre 2 et 3) → la copie. Une copie lue
pose `restored_from_backup` (Boot affiche « Sauvegarde restaurée depuis la copie de secours. » à
la reprise). Version plus récente (principal ou copie) : refusée, rien n'est touché, pas de repli.
Les deux illisibles : `ERR_FILE_CORRUPT`, copie laissée en place. `has_save()` vrai avec la seule
copie ; `erase()` supprime les deux. `OpeningCommit` copie la copie de secours vers
`save.previous.json` quand le principal manque.

**Stockage plein** : si l'écriture du temporaire échoue et que la place libre
(`SaveFileSystem.space_left`, `DirAccess.get_space_left`) est inférieure à la taille + 64 Kio :
`SaveSystem.STORAGE_FULL`, aucun fichier touché. Message « Sauvegarde impossible : espace
insuffisant. Libère de la place. » (toast une fois par série d'échecs, écran Menu ; les écritures
sont retentées toutes les 5 s comme avant).

| Cas de perte | Ce qui reste |
|---|---|
| Coupure pendant le temporaire | principal + copie intacts |
| Coupure entre rotation et remplacement | copie = dernière partie, reprise au lancement |
| Échec de la rotation | principal intact, rien d'écrit |
| Échec du remplacement | principal remis depuis la copie (sinon lu dans la copie) |
| Principal abîmé sur le disque | `.corrupt` + copie (jamais remplacée par l'illisible) |
| Les deux illisibles | `.corrupt` et `.bak` gardés, nouvelle partie |
| Stockage plein | tout intact, message |

Limite assumée : la copie a une écriture de retard (quelques secondes de jeu). Tests :
`tests/unit/test_save_backup.gd` (coupure à chaque opération avec `crashing_file_system.gd`,
corruptions, versions, disque plein, réglages, `OpeningCommit`) ; journaux d'opérations ajustés
dans `test_opening_commit.gd` et `test_opening_boot.gd`.

**QA S24 faite le 2026-10-29** (APK debug de `31c95070`, vraie partie de Kevin au Plateau Indigo,
v7 migrée en v8, `files/` sauvegardé puis restauré à l'identique, Ne pas déranger pendant la QA,
~10 min) :
- rotation réelle : au premier chargement, `save.json.bak` = l'ancienne sauvegarde octet pour octet ;
- 9 arrêts forcés (`am force-stop`) à +0,1 à +1,4 s après CONTINUER (écriture du changement de
  carte) et à +0 à +0,15 s après HOME (écriture d'arrière-plan, dont un arrêt pris entre la perte de
  focus et la fin de l'écriture) : après chacun, principal et copie valides (v8), copie d'une
  écriture en retard, aucun `.tmp` laissé, relance « sauvegarde VALID » ;
- principal tronqué à 3 000 octets par adb : mis de côté en `.corrupt`, partie reprise depuis la
  copie (même temps de jeu), toast « Sauvegarde restaurée depuis la copie de secours. » lisible
  en haut de l'écran ;
- principal supprimé (copie seule) : écran titre « sauvegarde VALID », reprise depuis la copie.
Non fait : stockage plein (non réalisable proprement sur le téléphone personnel ; couvert par les
tests). **T4 validé par Kevin le 2026-10-29, fusionné dans `main`.**

### T5 — Parcours scriptés (33E, Opus)
Harnais d'intégration qui enchaîne les étapes sur le vrai jeu en mode headless, à partir des
`debug_start`. Six parcours du dossier : 01 début ; 02 progression ; 03 donjons et légendaires ;
04 Ligue ; 05 post-game ; 06 collection. Variantes : les trois starters (équipes du rival). Les
états accélérés complètent le parcours réel de Kevin, ils ne le remplacent pas.

**Fait le 2026-10-29** (branche `claude/charming-dubinsky-f24364`, depuis `main` @ `9ce12d8e`).
- **Harnais** `tests/parcours/parcours_play.gd` (`ParcoursPlay`, hérite de `tests/helpers/hideout_play.gd` ;
  hors de `tests/helpers/` pour que `--changed` ne relance pas toute la suite) : **une seule partie
  par parcours** sur la vraie Boot et une sauvegarde en mémoire ; l'état passe d'une étape à l'autre,
  seul le premier pas part d'un `debug_start` (ou d'une nouvelle partie, `start_new`). Étapes :
  `jump` (changement de carte réel, comme un Vol), `walk_through` (marche, Dresseurs qui repèrent le
  joueur combattus), `talk` / `talk_to` / `approach` (case voisine par la vraie grille), `surf_to`
  (berge, `MountDirector.start_surf`, nage), `catch_with` / `catch_in_grass` (Ball au premier tour,
  aléatoire « toujours 1 » quand la capture doit être sûre), `run_league` (5 salles, portes, appels),
  `persist` (sauvegarde écrite, application relancée, partie relue identique : carte, case, équipe,
  Stockage, Sac, Pokédex, drapeaux, argent, Panthéon…), relevé des combats (`battles` : Dresseur,
  **équipe adverse réellement affrontée**, issue). Journal par étape (« ✔ / ✘ ») imprimé par GUT ;
  chaque **raccourci** (tronçon sauté) est noté « ↷ » avec sa raison et ses tests propres.
- **Victoires** : `make_ace` met en tête un Mewtwo N100 (Psyko) et `heal` soigne avant chaque grand
  combat : le parcours vérifie les **enchaînements**, pas l'équilibrage (tests IA tiers, RP-249 à
  RP-254).
- **Parcours** (`tests/parcours/`, 9 tests, ≈ 6 min sur le Mac) :

| Parcours | Départ | Étapes réelles (combats, scènes, sauvegarde) | Raccourcis |
|---|---|---|---|
| 01 début `test_parcours_01_debut.gd` | nouvelle partie au labo | fiche et CHOISIR du starter, rival du labo, colis à la Boutique, Pokédex, rival de la Route 22, Arène d'Argenta (Liam, Pierre), relance | prologue, Route 1, Route 2 et Forêt |
| 02 progression `test_parcours_02_progression.gd` | `rival_cerulean` | rival d'Azuria, Ondine, rival du S.S. Anne, capitaine (CS01), arbuste coupé, Major Bob, Erika, Giovanni (Scope), rival de la Tour, Ossatueur, Rockets du 7F et Fuji (Poké Flûte), Ronflex de la Route 12, Koga, rival et Giovanni à la Sylphe (porte à carte, Master Ball), Morgane ; Dresseurs d'Arène croisés ; relance | Pont Pépite et Bill, puzzle de Carmin, Routes 9-10 et Grotte Sombre, Casino et B1F-B4F du repaire, Tour 3F-5F, Route 16 et Piste Cyclable, Sylphe 1F-6F |
| 03 donjons et légendaires `test_parcours_03_donjons.gd` | `j24_articuno` | Surf depuis l'escalier (7, 11) et Artikodin, interrupteur et Clé Secrète du Manoir, Auguste (première victoire de Boot sur lui), Giovanni à Jadielle, Électhor, dernier rival de la Route 22 (première fois en Boot), Sulfura, relance (trois légendaires relus) | Badge Marais, Manoir 1F-3F, portes du quiz, dalles de Jadielle, Route 23, Route Victoire 1F |
| 04 Ligue `test_parcours_04_ligue.gd` | `league_lorelei` | Olga, Aldo, Agatha, Peter, rival (équipe contre Salamèche), portes nord, Panthéon, générique, Bourg Palette, relance | — |
| 05 post-game `test_parcours_05_post_game.gd` | `cerulean_cave_locked` | Grotte fermée avant le titre (en Surf), Champion, Grotte ouverte, Mewtwo capturé, **Ligue rejouée en entier** (2e entrée du Panthéon, Mewtwo gardé), dons de Chen, relance | étages 1F à B1F de la Grotte |
| 06 collection `test_parcours_06_collection.gd` | `evolution_qa` | Chenipan bat Théo et évolue, captures dans les herbes jusqu'à l'équipe pleine puis au Stockage, dépôt et retrait (règles du Stockage), relance, Diplôme, Mew sous le camion (151), relance | Chenipan mis en tête, 150 captures, Ligue |
| Starters `test_parcours_starters.gd` | `route_22_final_<s>`, `silph_7f_rival_<s>`, `league_champion_<s>` | pour Bulbizarre, Salamèche, Carapuce : les trois derniers combats du rival, équipe affrontée = données, dernier Pokémon (Dracaufeu, Tortank, Florizarre), Panthéon | — |

- **Anomalies** (registre `reportes.md`) : **RP-266** (P3, corrigé) `DebugStart` prenait le premier
  Pokémon comme starter même évolué : 109 départs sans starter connu, tout combat du rival depuis
  eux partait sans équipe et comptait comme une défaite ; désormais le premier s'il est un starter
  de base, sinon la paire `taken_*` (une seule lecture), test `test_debug_start_starter.gd`, rejoué
  par le parcours 03. **RP-267** (P3, ouvert) : un combat de Dresseur sans équipe adverse est compté
  comme une défaite au lieu d'être refusé ; aucune vraie sauvegarde n'y mène (champ `starter`
  présent de v1 à v8). **Aucun P0 ni P1 trouvé.**
- **Pour T6** : les raccourcis du tableau sont les tronçons que seule la passe humaine rejoue.

### T6 — Campagne complète et corrections (33E)
Une passe humaine sur S24 par parcours ; chaque anomalie dans `docs/tech/registre-anomalies.md` [D]
(ID, priorité, build, étapes, état). Fermeture seulement après **rejeu réussi du scénario**.

### T7 — APK versionné, rapport, décision (33F)
`version/code` et `version/name` dans le preset (nommage fixé en J34 T1), `tools/build_android.sh`
accepte un preset de test. Dossier : APK, commit exact, version de Godot, paramètres d'export,
résultats de tests, métriques, registre. **Une APK compilée ne prouve pas à elle seule que le
jalon est terminé.**

## 3. Textes
Validés par Kevin le 2026-10-21 : tableau des priorités P0–P3 ; critère « zéro P0/P1 » ;
dialogues de 2 lignes. Propositions **[D]** : message de disque plein « Sauvegarde impossible :
espace insuffisant. Libère de la place. » ; message de copie de secours utilisée « Sauvegarde
restaurée depuis la copie de secours. »

## 4. Critères d'acceptation (« J33 terminé »)
1. APK généré et installé sur le S24 ; 2. parcours critiques de l'aventure et du post-game validés ;
3. sauvegardes anciennes et nouvelles chargées ; 4. aucune régression bloquante J0–J32 ;
5. zéro P0 / P1 ouverts ; 6. rapport QA et limitations connues écrits.

## 5. QA téléphone (S24)
Session de 30 minutes en jeu réel ; appli en arrière-plan puis retour pendant un combat ; fermeture
forcée pendant une sauvegarde (copie de secours) ; stockage presque plein (si réalisable) ;
relevé FPS par zone.

## 6. Risques
Une optimisation de textures qui déplace une collision ; une copie de secours qui masque une
corruption ; trop de P2 acceptés « pour finir » ; mesures de batterie incomparables.

## 7. Points ouverts pour Kevin
1. Nom et emplacement de la copie de secours : `save.json.bak` à côté du fichier ? [D : oui]
2. Registre des anomalies : fichier du dépôt ou tickets GitHub ? (voir J39, source unique) [D : tickets GitHub dès J35]
3. Combien de parcours humains complets de Kevin avant la décision ? [D : un seul, le 01 à 06 d'affilée]
4. Appareils de test disponibles en plus du S24 (pour J34) ?
