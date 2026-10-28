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
dans `test_opening_commit.gd` et `test_opening_boot.gd`. **Reste : validation seule par Kevin
(QA S24 bornée : arrêt forcé pendant une sauvegarde, principal abîmé par adb → reprise).**

### T5 — Parcours scriptés (33E, Opus)
Harnais d'intégration qui enchaîne les étapes sur le vrai jeu en mode headless, à partir des
`debug_start`. Six parcours du dossier : 01 début ; 02 progression ; 03 donjons et légendaires ;
04 Ligue ; 05 post-game ; 06 collection. Variantes : les trois starters (équipes du rival). Les
états accélérés complètent le parcours réel de Kevin, ils ne le remplacent pas.

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
