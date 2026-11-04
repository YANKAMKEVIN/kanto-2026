# Jalon 34 — 34D (T5) : résilience Android

> Plan : `docs/tech/jalon-34.md` §2 T5 ; passe `docs/design/passes/j34-v1-chatgpt.md` §6 ;
> système de sauvegarde : `docs/tech/systemes-2.md` §2.12 et §3.2 (S2A), `jalon-33.md` T4 (copie
> de secours, stockage plein). Branche `claude/j34-34d-resilience`. Appareil : Galaxy A17
> (`SM-A175F`, série `R5GYB2R7W2Y`, Android 16), le S24 n'étant pas disponible. Session : 34D
> (2026-11-04). **État : voir §0.**

## 0. État

- **Audit du code (§1)** : fait le 2026-11-04 ; aucun manque bloquant, un complément (§2).
- **Tests automatiques (§2)** : écrits et verts (`tests/integration/test_resilience_android.gd`,
  6 tests ; `test_session_lifecycle.gd` +2).
- **Scénarios sur l'A17 (§3, §4)** : à jouer (tour sur le téléphone demandé à la coordination).
- **Défauts (§5)** : à remplir.

## 1. Ce qui existe déjà (relu sur `main` @ `f3470936`)

| Besoin (T5) | Mécanisme en place | Où |
|---|---|---|
| Écriture atomique | temporaire → relecture → principal valide renommé en `.bak` → temporaire renommé en principal ; coupure à n'importe quelle étape = au moins une partie valide | `SaveSystem.write`, `SaveFileSystem.rename` (`rename` POSIX) |
| Fichier tronqué / illisible | refusé, mis de côté en `save.json.corrupt` (jamais détruit), copie de secours reprise avec un avertissement dans le journal | `SaveSystem.read`, `_quarantine` |
| Version plus récente | refusée, jamais écrasée (autosave coupé pour la session) | `SaveSystem._accept`, `Boot._can_write` |
| Stockage plein | écriture refusée sans rien toucher, `STORAGE_FULL`, message au joueur une fois par série, nouvelle tentative toutes les 5 s | `SaveSystem._fail_write`, `Boot._warn_storage_full`, `SaveCoordinator.RETRY_DELAY` |
| Mise en arrière-plan (`APPLICATION_PAUSED`, `WM_CLOSE_REQUEST`) | partie stable → état courant écrit tout de suite ; instable (dialogue, scène, rencontre, combat, transition, glisse, ascenseur, Flash) → **point de reprise** capturé au passage stable → instable, écrit s'il est plus récent que le disque ; jamais deux écritures d'arrière-plan en moins de 2 s ; jamais un point de reprise plus ancien que le disque | `SessionLifecycle.handle_notification`, `SaveCheckpoint`, `Boot._save_in_background` |
| `FOCUS_OUT` seul (bandeau, rideau) | délai de garde de 1 s puis même écriture ; Godot 4.7 sous Android ne l'envoie qu'avec `PAUSED` (constat S2A sur S21) | `SaveCheckpoint.focus_out/focus_due` |
| Son en arrière-plan | `PAUSED` → Master coupé ; `FOCUS_OUT` → musique et ambiance à −20 dB ; retour → fondu de 0,5 s ; le moteur met aussi le pilote audio Android en pause | `Audio.handle_app_change` |
| Temps de jeu | ne compte pas hors du premier plan ni pendant l'ouverture ; pas d'image plafonnée à 0,5 s | `SessionLifecycle.play_time_step` |
| Retour Android | ne quitte jamais (`quit_on_go_back=false`) ; menu un niveau en arrière, en exploration écriture immédiate puis menu, sinon ignoré ou absorbé | `Boot._on_go_back` |
| Rotation | `window/handheld/orientation=4` (paysage capteur : les deux paysages, jamais portrait) ; Godot déclare `configChanges` : l'activité n'est pas recréée | `project.godot`, manifeste du gabarit |
| Perte de focus pendant le chargement d'une carte | la transition rend la partie instable : le point de reprise est **la case d'avant le passage** ; les fondus (tweens) et le chargement en tâche de fond reprennent avec le fil de rendu | `SceneRouter._change_map`, `Boot._watch_save_checkpoint` |
| Opérations uniques (capture, échange, évolution, don, Panthéon) | appliquées **d'un bloc en mémoire** ; autosave demandé puis écrit à la première image stable (fin de rencontre / de scène) ; interrompues avant : le point de reprise d'avant le combat ou la scène est sur le disque → la rencontre ou la scène se rejoue, rien n'est dupliqué, rien n'est supprimé sans son pendant | `BattleDirector._finish_capture`, `InGameTrade.execute`, `LocalTrade.execute`, `EvolutionDirector._play_one`, `LeagueDirector.complete_ceremony`, étape « save » des scènes |
| Permissions | le jeu n'écrit que dans `user://` (stockage interne de l'app) : aucune permission à demander ni à refuser ; vibration sans permission dangereuse | `SaveFileSystem`, `Haptics` |
| Mémoire basse | Android (Godot 4.7) ne transmet pas `onTrimMemory` au jeu ; iOS envoie `OS_MEMORY_WARNING` | — (complément §2) |

Première conclusion : **le point de reprise de la sauvegarde est respecté** par construction (jamais
d'état intermédiaire sur le disque, parce que l'écriture est atomique et que l'instantané est
toujours un état d'avant ou d'après une opération, jamais du milieu).

## 2. Compléments de code (ce lot)

- `SessionLifecycle.handle_notification` traite **`NOTIFICATION_OS_MEMORY_WARNING`** comme une
  mise en arrière-plan pour la sauvegarde (point de reprise s'il est plus récent, état courant
  si la partie est stable, écart de 2 s respecté) **sans** quitter le premier plan ni toucher au
  son : le système peut tuer le processus juste après, le point de reprise est déjà écrit. Android
  ne l'envoie pas dans Godot 4.7 (iOS oui) ; coût nul, assurance pour la cible iOS et les futures
  versions. `save_reason()` nomme le motif dans le journal (« arrière-plan », « fermeture »,
  « mémoire basse »).
- Tests GUT ajoutés, sans scène pour la logique et avec le vrai `Boot` sur un système de fichiers
  en mémoire pour l'enchaînement (`tests/integration/test_resilience_android.gd`) :

| Test | Ce qu'il prouve |
|---|---|
| pause pendant un changement de carte | la position d'avant le passage est écrite, jamais la carte en cours de chargement ; au retour la transition s'achève, les commandes reviennent, l'autosave d'arrivée suit |
| tuée pendant un changement de carte | relancée, la partie reprend **avant** le passage, stable, sans transition fantôme |
| pause sur la carte de capture | le Pokémon rangé en mémoire n'est pas sur le disque (équipe et Balls d'avant le combat) ; la rencontre finie, **une seule** capture et une seule Ball de moins ; relancée : exactement un Rattata |
| pause pendant une évolution par Super Bonbon (voile du niveau, puis début de l'écran d'évolution) | bonbon, niveau et espèce d'avant restent **ensemble** sur le disque ; à la fin, consommé et évolué ensemble ; relancée : une seule fois |
| tuée pendant cette évolution | le bonbon est encore là, Abra N15 : rien de perdu, rien de dupliqué |
| mémoire basse pendant un dialogue | point de reprise écrit, premier plan conservé (le temps de jeu continue), `PAUSED` juste après n'écrit rien de plus |

Déjà couverts avant ce lot (gardés tels quels) : dialogue, scène + relance, écriture immédiate
jamais dépassée par un point plus ancien, combat sauvage, `FOCUS_OUT` court / long, écart de 2 s,
panne puis nouvelle tentative (`test_save_background.gd`) ; coupure à chaque opération d'écriture,
principal corrompu, copie corrompue, stockage plein (`test_save_backup.gd`, `test_save_system.gd`).

## 3. Scénarios sur l'A17 (APK debug, par adb)

APK **debug** (`tools/build_android.sh`, décision de la coordination : jamais de release sur
l'A17 partagé). La différence avec l'APK signé (34B) est la clé et le drapeau `debuggable` : même
code, mêmes chemins d'écriture ; le 34B a déjà vu la RC écrire en arrière-plan et reprendre après
`am force-stop` (fiches 1 et 2). Le debug permet en plus `run-as` : lire `files/save.json*` et
**poser des états intermédiaires** d'écriture, ce qui remplace une coupure impossible à placer
par adb dans une écriture de quelques millisecondes.

Préparation : `ADB=~/Library/Android/sdk/platform-tools/adb`, `A17=R5GYB2R7W2Y`,
`PKG=dev.kevin.kanto2026`, `OUT=build/qa-34d` (hors Git). Ne pas déranger activé puis remis ;
**focus vérifié avant chaque tap** (`dumpsys window | grep mCurrentFocus` nomme `$PKG`) ; état
initial de l'A17 copié (`run-as $PKG tar cf - files`) et restauré à la fin ; départ de débogage
`s2_save` (Route 3, entrée ouest, Hugo à droite ; **`autosave: true`**, il remplace la
sauvegarde) comme pour la QA S2A. Journal : `logcat -s godot:V` (« [save] focus … »,
« Sauvegarde du point de reprise (…) », « Sauvegarde automatique (…) »), `logcat | grep -E
"AndroidRuntime|FATAL|ANR"`.

| # | Scénario | Commandes | Attendu |
|---|---|---|---|
| 1 | Accueil pendant un **dialogue** (Hugo) puis retour | joystick vers Hugo, `keyevent 3`, `am start -n $PKG/.GodotApp` | point de reprise d'avant le dialogue écrit ; au retour le dialogue continue, son revenu, joystick actif |
| 2 | **Verrouillage** pendant un **combat** (Hugo), déverrouillage | `keyevent 26`, puis `keyevent 26` + `wm dismiss-keyguard` | point de reprise d'avant le combat ; au retour le combat reprend où il était |
| 3 | **Processus tué** en arrière-plan pendant le combat | Accueil, `am kill $PKG` (ou `am force-stop`), relance, Continuer | reprise juste avant le combat, PV pleins, Hugo à rejouer, une seule écriture |
| 4 | **Appel** : activité Téléphone au premier plan pendant un dialogue (`am start -a android.intent.action.DIAL`), retour par `am start` du jeu ; bandeau heads-up (`cmd notification post`) | aucun appel réel sans SIM : même chemin Android que le 34B/S2A (onPause + onStop) | point de reprise ; le bandeau seul n'écrit rien et ne coupe rien |
| 5 | **Changement de carte** interrompu : Route 3 → Argenta, Accueil pendant le fondu | swipe tenu vers l'ouest sur le passage + `keyevent 3` enchaînés | écrit = case d'avant le passage, ou autosave d'arrivée si le passage était fini ; jamais une carte à moitié chargée ; au retour l'arrivée s'achève |
| 6 | **Évolution** interrompue (départ `evolution_qa`, Chenipan N6 → combat → N7 → Chrysacier) : Accueil puis `am kill` pendant l'écran d'évolution | joystick dans l'herbe, combat joué au doigt (taps), Accueil à l'écran d'évolution | disque = avant le combat ; relancée : Chenipan N6, combat à rejouer |
| 7 | **Mémoire basse** : `am send-trim-memory $PKG RUNNING_CRITICAL` au premier plan, puis `COMPLETE` en arrière-plan | — | aucun crash ; survit ou est tué par le système ; dans les deux cas reprise sur le point de reprise |
| 8 | **Rotation** : capteur en portrait, auto-rotation forcée | `settings put system accelerometer_rotation 0/1`, `user_rotation 0` ; `dumpsys window | grep -i orientation` | le jeu reste en paysage (`sensorLandscape`), aucune recréation d'activité (pas de « Sauvegarde automatique » ni de relance dans le journal) |
| 9 | **Sauvegarde en cours** coupée : états intermédiaires posés par `run-as` sur une partie connue : (a) `save.json.tmp` orphelin à côté d'un principal valide ; (b) principal absent + `.bak` valide (coupure entre les deux renommages) ; (c) principal tronqué + `.bak` valide | `run-as $PKG sh -c '…'` puis relance | (a) ignoré puis écrasé ; (b) reprise depuis la copie (journal « partie reprise depuis la copie de secours ») puis réécriture normale ; (c) `.corrupt` créé, partie reprise de la copie, rien de détruit |
| 10 | **Stockage presque plein** | non rejoué sur l'A17 partagé (remplir le stockage d'un téléphone prêté) : tests `test_save_backup.gd` (refus sans rien toucher, message, nouvelle tentative) | [D] : simulation seulement |

## 4. Fiches

À remplir après le tour sur l'A17.

## 5. Défauts

| # | Priorité | Scénario | Constat | Suite |
|---|---|---|---|---|
| — | — | — | — | — |
