# Jalon 34 — 34B (T3) : installation propre, mise à jour, désinstallation sur l'A17

> Plan : `docs/tech/jalon-34.md` §2 T3 ; procédure de build : `docs/tech/release.md`.
> Branche `claude/j34-34b-c7976d`. Appareil : Galaxy A17 (série `R5GYB2R7W2Y`, adb sans fil), le
> S24 n'étant pas disponible depuis le 2026-10-31. Session : 34B (2026-11-04).
> **État : T3 joué sur l'A17 le 2026-11-04, trois scénarios réussis, aucun P0/P1** (fiches du §4,
> bugs du §5). **À valider par Kevin**, rien n'est fusionné dans `main`.

## 1. Préalables (état au 2026-11-04)

| Préalable | État |
|---|---|
| Commit à construire | Le HEAD de la branche, qui ne diffère de `99dfa688` (= `origin/main`, **CI verte** run 41711310886) que par la documentation et `tools/build_rc.sh`. **Défaut de procédure trouvé et corrigé ici** : `build_rc.sh` exigeait une CI sur le commit exact, or la CI ne se lance pas pour un commit de documentation seule (`paths-ignore`) ; le script prend maintenant la CI du dernier ancêtre testé si tout ce qui a changé depuis est de la documentation (`release.md` §3). Le commit qui modifie le script déclenche, lui, sa propre CI. |
| Clé de signature | **Créée le 2026-11-04 à la demande de Kevin** par cette session (`tools/make_keystore.sh`, mot de passe tiré au hasard, jamais affiché) : `~/.pokemake/pokemake-release.jks` + `pokemake-release.pass` (droits 600, hors dépôt). Empreinte SHA-256 du certificat `01:E2:B9:8F:…:2C:6D:73`. **À copier par Kevin dans son gestionnaire de mots de passe.** |
| A17 en adb | Revenu en USB à 12:44 ; tour accordé par la coordination ; rendu à la fin (§3.6). |
| Build | `tools/build_rc.sh` sur `af081d38` (CI verte, run 41747482368) : `build/rc/pokemake-0.34.0.apk`, 616 924 680 octets, SHA-256 `8e4aff827c8fb8765243436053ab0d05e975dc31754f1dcb1e8b18b49ed7118e`, versionCode 3400, non débogable. |
| Vieille version | `build/kanto2026-0.33.0-debug.apk` (dépôt principal, commit `54355608`, versionCode 33, **signé avec la clé de débogage**, `save` **v8**). |
| Vieille sauvegarde | `build/qa/sauvegarde_kevin_s21_2026-10-14/` (`save.json` **v6**, joueur « Kevin », Bourg Palette → Jadelle, Salamèche, 2100 ₽, copie réelle prise sur le S21 le 2026-10-14 ; `save.previous.json`, `settings.json`) : une vraie partie, pas créée par la RC. |

## 2. Découverte qui change la procédure

**Une mise à jour d'un APK signé en débogage par un APK release est impossible** : Android refuse
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) car la signature diffère. Or toutes les builds 0.33.0 et
antérieures du dépôt (et l'app actuellement sur l'A17) sont signées avec la clé de débogage. Donc :

- aucun proche n'a, ni n'aura, de 0.33.0 « par-dessus » laquelle installer la RC : la première
  installation de la RC est forcément propre ;
- pour **tester** la mise à jour d'une vraie ancienne version, on utilise la 0.33.0 **re-signée avec
  la clé release** (`apksigner sign`, sans reconstruire) : même contenu, même `versionCode` 33,
  même identifiant, signature identique à celle de la RC. C'est la seule manière de reproduire,
  avec une ancienne version, ce que vivra un proche entre la 0.34.0 et la 0.34.1 ;
- ce APK 0.33.0 est un export **debug** (débogable) : cela permet d'y poser la sauvegarde ancienne par
  `run-as`. La RC, elle, n'est pas débogable : après la mise à jour on ne lit plus les fichiers de
  l'app, on vérifie par le jeu lui-même (écrans) et le journal `logcat`.

## 3. Procédure

### 3.0 Avant de toucher au téléphone
1. Tour sur l'A17 demandé à la session coordinatrice ; la rendre dès la fin (§3.6).
2. Variables : `ADB=~/Library/Android/sdk/platform-tools/adb`, `A17=R5GYB2R7W2Y` (ou la série
   `adb-…` / `ip:port` du sans-fil), `PKG=dev.kevin.kanto2026`, dossier de travail
   `OUT=build/qa-34b` (hors Git).
3. **Ne pas déranger** activé sur l'A17 (`adb -s $A17 shell cmd notification set_dnd priority`) ;
   **avant chaque tap** : `adb -s $A17 shell dumpsys window | grep mCurrentFocus` doit nommer
   `dev.kevin.kanto2026`, sinon on s'arrête.
4. **Sauvegarde de l'état actuel de l'A17** (app debug installée, saves des autres sessions) :
   `adb -s $A17 exec-out run-as $PKG tar cf - files > $OUT/a17-avant/files.tar`, plus
   `adb shell dumpsys package $PKG | grep -E "versionName|versionCode|signatures"`.
5. Build RC : `tools/build_rc.sh` (clé exportée dans le terminal de Kevin) → `build/rc/pokemake-0.34.0.apk`,
   `manifest.json`, `SHA256SUMS`. Relever la taille, le SHA-256, `apksigner verify --print-certs`.
6. Vieille 0.33.0 re-signée :
   `cp build/kanto2026-0.33.0-debug.apk $OUT/pokemake-0.33.0-resigne.apk` puis
   `apksigner sign --ks "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" --ks-key-alias "$GODOT_ANDROID_KEYSTORE_RELEASE_USER" --ks-pass env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD $OUT/pokemake-0.33.0-resigne.apk`
   (le mot de passe n'apparaît ni dans la commande ni dans un journal), puis `apksigner verify`.
   Vérifier que le certificat est celui de la RC (SHA-256 identique).

### 3.1 Scénario 0 (contrôle, 5 min) — signature différente
Avec l'app debug de l'A17 encore installée : `adb install -r build/rc/pokemake-0.34.0.apk` doit
échouer avec `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, et l'app debug et sa sauvegarde rester intactes
(vérifier par `run-as … ls files`). Résultat noté en fiche 0 ; confirme la phrase de `release.md` §4.

### 3.2 Scénario 1 — installation propre et première sauvegarde
1. `adb uninstall $PKG` (la sauvegarde des autres sessions est déjà dans `a17-avant/files.tar`).
2. `adb install build/rc/pokemake-0.34.0.apk` (ou `--install`) ; relever le temps et le résultat.
3. Lancer ; relever : ident (carton, bande-annonce, lettres), écran titre avec « v0.34.0 (3400) »,
   fréquence d'images et mémoire (`dumpsys meminfo`, `gfxinfo`) pendant la bande-annonce
   (point d'attention de l'état du projet : 8 textures ≈ 45 Mo de VRAM), erreurs de `logcat -s godot`.
4. Nouvelle partie : introduction de Chen, apparence, prénoms, passage à la chambre, jusqu'à la
   **première sauvegarde** (écriture de `save.json` : repérer le sauvetage dans le journal, ou
   mettre l'app en arrière-plan puis la rouvrir : « Continuer » doit apparaître).
5. Fermer de force (`am force-stop`), relancer, **Continuer** : la partie reprend au même endroit.

### 3.3 Scénario 2 — mise à jour par-dessus la 0.33.0 avec une vraie ancienne sauvegarde
1. `adb uninstall $PKG` ; `adb install $OUT/pokemake-0.33.0-resigne.apk`.
2. Poser la vraie sauvegarde (app débogable, avant le premier lancement) :
   `adb shell "run-as $PKG sh -c 'mkdir -p files && cat > files/save.json'" < build/qa/sauvegarde_kevin_s21_2026-10-14/save.json`
   (idem `save.previous.json` → `save.json.bak` si la 0.33.0 le lit ainsi, `settings.json`).
3. Lancer la 0.33.0, **Continuer** : elle migre la v6 en mémoire. Relever l'écran de reprise,
   l'Équipe (Salamèche), le Sac, le Pokédex, la position. Mettre en arrière-plan pour qu'elle écrive
   sa propre sauvegarde (**v8**) ; la récupérer (`run-as … cat files/save.json`) et la garder : c'est
   la « sauvegarde ancienne » de la 0.33.0, avec son résumé (version, équipe, Sac, entrées du Pokédex,
   drapeaux, carte, case, argent, temps de jeu).
4. Fermer l'app, puis la mettre à jour (33 → 3400) : **`adb push` de l'APK dans `/data/local/tmp`, puis `adb shell pm install -r`** (plus fiable que `adb install -r` pour 617 Mo, voir B-1).
5. Lancer la RC, **Continuer** : comparer au résumé du point 3 : équipe, Sac, Pokédex, drapeaux,
   position, argent, noms du joueur et du rival. Migration v8 → v9 passée sans erreur (journal sans
   `push_warning` de SaveSystem, pas de `.corrupt`, pas de « partie reprise depuis la copie de
   secours »). Jouer quelques pas, mettre en arrière-plan, fermer de force, relancer : reprise identique.
6. (Si le temps le permet, sans bloquer) variante v6 intacte : refaire 3.3 avec la 0.33.0 **jamais lancée**
   pour que la RC lise la v6 directement et migre en chaîne 6 → 9.

### 3.4 Scénario 3 — désinstallation
1. Avec la partie du scénario 2 présente, `adb uninstall $PKG` (retour attendu : `Success`).
2. Vérifier que le dossier de l'app a disparu (`adb shell ls /data/data/$PKG` → inaccessible ; `pm list packages`).
3. Réinstaller la RC : l'écran titre propose-t-il « Continuer » ? (Sauvegarde locale disparue ?)
   Contrôler aussi `adb shell dumpsys backup` / `android:allowBackup` du manifeste (`aapt2 dump xmltree`)
   pour savoir si Android pourrait restaurer des données depuis le cloud de Google, et si des fichiers
   restent sur `/sdcard/Android/data/$PKG` (le jeu n'y écrit rien, à confirmer).
4. Compléter `release.md` §4 avec le résultat constaté (texte à dire au testeur).

### 3.5 Bugs
Tout bug noté dans le tableau du §5 avec priorité et reproduction. P0/P1 bloquent la RC. Seuls les
défauts de build ou de procédure sont corrigés dans cette branche ; un bug de jeu est signalé à Kevin.

### 3.6 Fin de session téléphone
Réinstaller l'état initial de l'A17 pour les autres sessions : désinstaller la RC, réinstaller un APK
debug (`build/kanto2026-debug.apk` ou `tools/deploy_s24.sh`), restaurer `a17-avant/files.tar` par
`run-as` ; désactiver Ne pas déranger si on l'a activé ; **rendre l'A17 à la coordinatrice**.
(Une app signée release laissée sur l'A17 ferait échouer les prochains `deploy` en debug.)

## 4. Fiches

**Appareil commun aux quatre fiches** : Samsung Galaxy **A17** (`SM-A175F`), **Android 16** (SDK 36),
arm64-v8a, écran 2340 × 1080 en paysage, branché en USB (adb), batterie 8 % puis en charge, Ne pas
déranger activé pendant la QA puis remis (état initial). **Build RC** : Pokemake **0.34.0 (3400)**,
commit `af081d38`, Godot 4.7.2, signée avec la clé du 2026-11-04 (SHA-256 du certificat
`01e2b98f…12c6d73`). **Vieille version** : Pokemake/Kanto 2026 **0.33.0 (33)**, commit `54355608`,
build de débogage du J33 re-signée avec la même clé (`apksigner sign`, contenu inchangé, débogable).
Aucune ligne d'erreur de Godot, aucun `FATAL` ni ANR dans `logcat` sur toutes les exécutions.

### Fiche 0 — mise à jour d'un APK debug par la RC (signature) : **conforme, refus attendu**
- État de départ : app debug versionCode 1 / 1.0.0 (clé de débogage), `files/` : seulement
  `shader_cache` et `vulkan` (aucune sauvegarde sur l'A17).
- `adb install -r pokemake-0.34.0.apk` → `Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package
  dev.kevin.kanto2026 signatures do not match newer version; ignoring!]`. L'app debug et ses fichiers
  sont restés intacts. **Confirme `release.md` §4** : un APK debug installé avant doit être désinstallé.

### Fiche 1 — installation propre et première sauvegarde : **réussi**
- Désinstallation de l'app debug, puis `adb install` de la RC : **Success**, 48 s en flux (une première
  tentative a été coupée par un redémarrage du serveur adb, voir B-1). `dumpsys package` :
  versionCode 3400, versionName 0.34.0, `flags=[HAS_CODE ALLOW_CLEAR_USER_DATA]` (non débogable),
  installeur `null`.
- Lancement : splash, ident « Les studios Kevin & Co », **bande-annonce jouée** (plan Pokédex relevé),
  fin de l'ident 27 s après l'ouverture du titre (journal : `Ouverture : titre (sauvegarde NONE)` puis
  `Ident : fini`). Écran titre avec « v0.34.0 (3400) » et **seulement** Nouvelle partie / Paramètres
  (pas de Continuer).
- Mémoire pendant l'ident : PSS total **908 Mo** (graphique 592 Mo) ; après l'introduction : 892 Mo
  (graphique 575 Mo) ; `gfxinfo` : 371 images, **7 saccadées (1,89 %)**. Aucun arrêt par manque de mémoire.
- Nouvelle partie jouée par adb : introduction de Chen, choix d'apparence (garçon), prénom « Red »,
  confirmation, rival (apparence, prénom « Blue »), passage à la chambre. Journal :
  `Ouverture : nouvelle partie écrite (user://save.json)` = **première sauvegarde**.
- `am force-stop`, relance : `Ouverture : titre (sauvegarde VALID)`, carte « Continuer — Red, Bourg
  Palette, 0 h 00 », puis `Sauvegarde chargée : player_house_2f (3, 4) (temps de jeu 0 s)` : la partie
  reprend dans la chambre.
- Incident hors jeu : une première introduction a été interrompue à 12:49:08 par un `am force-stop`
  venu d'un autre client adb (`ApplicationExitInfo` : « USER REQUESTED / FORCE STOP ») ; ce n'est pas
  un plantage de l'app. Introduction rejouée.

### Fiche 2 — mise à jour 0.33.0 → 0.34.0 avec une vraie sauvegarde ancienne : **réussi**
- Vieille sauvegarde : copie réelle de Kevin prise sur le S21 le 2026-10-14, `save.json` **v6**
  (`build/qa/sauvegarde_kevin_s21_2026-10-14`, avec `settings.json`, SHA-1 vérifié à l'identique après la
  pose par `run-as`).
- 0.33.0 re-signée installée en propre, sauvegarde posée avant le premier lancement. Lancement :
  carte « Continuer — Kevin, Jadelle, 23 h 36, 4 capturés » ; journal 0.33.0 : `[qa] sauvegarde v6 → v8`
  puis autosave : le fichier est maintenant une **v8 écrite par la 0.33.0** (`save.json.bak` = la v6
  d'origine). Résumé de référence (`tools/qa/save_resume.py`) : Kevin / rival Régis, Jadelle (42, 22),
  2 100 ₽, 85 005 s, starter Salamèche, équipe Salamèche Nv 8 (25 PV), Roucool Nv 3, Rattata Nv 3,
  Nidoran♂ Nv 3, Sac vide, 5 entrées de Pokédex dont 4 capturées, 18 drapeaux, 9 cartes découvertes,
  4 moments.
- **Mise à jour** : `pm install -r` de la RC (33 → 3400, débogable → non débogable, **sans
  désinstaller**) : Success, `versionName 0.34.0`.
- Lancement de la RC : `Ouverture : titre (sauvegarde VALID)`, même carte « Continuer — Kevin, Jadelle,
  23 h 36, 4 capturés », `Sauvegarde chargée : viridian_city (42, 22) (temps de jeu 85005 s)`. Menu :
  « 5 vus · 4 capturés », Salamèche Nv 8 25/25 ; Équipe 4/6 identique (Roucool favori) ; Sac « Ton Sac est
  vide », 2 100 ₽ ; objectif « continuer vers le nord ». Aucun `.corrupt`, aucun message de copie de
  secours, aucune erreur.
- Écriture par la RC : après retour à l'accueil et arrêt forcé, la relance donne un temps de jeu de
  **85 081 s** (> 85 005) : la RC a écrit sa propre sauvegarde (v9). Elle n'est pas lisible
  directement (RC non débogable, `run-as` refusé ; un retour à la 0.33.0 est refusé, voir fiche 3), et
  la RC n'imprime pas de ligne de migration en release (voir B-2).
- **Variante forte** : la RC lisant la **v6 intacte** (0.33.0 installée, sauvegarde posée, jamais
  lancée, RC installée par-dessus) : même résultat, `Sauvegarde chargée : viridian_city (42, 22) (temps
  de jeu 85005 s)`, tableau de bord identique. La migration en chaîne **6 → 9** passe sur une vraie partie.
- Durée de l'installation de la RC par-dessus : 12 s en `pm install -r` après 27 à 42 s de `adb push`.
- Réglage hérité de la sauvegarde de Kevin : `reduce_motion` vrai (`settings.json`), d'où l'ident réduit
  (≈ 4 s) pendant ce scénario ; ce n'est pas une anomalie.

### Fiche 3 — désinstallation : **la sauvegarde disparaît** (à dire aux proches)
- Avec la partie du scénario 1 : `adb uninstall dev.kevin.kanto2026` → Success ; `pm list packages` ne
  liste plus l'app ; `/data/data/dev.kevin.kanto2026` et `/sdcard/Android/data/dev.kevin.kanto2026`
  (qui existait avant) **n'existent plus**.
- Réinstallation de la RC : `Ouverture : titre (sauvegarde NONE)` : plus de « Continuer », la sauvegarde
  est **perdue** et rien ne la restaure.
- Manifeste : `android:allowBackup=false` ; le gestionnaire de sauvegarde Android de l'A17 est
  désactivé (« Backup Manager is disabled »), donc la restauration depuis le cloud de Google n'a pas pu
  être éprouvée ici ; avec `allowBackup=false` Android ne devrait de toute façon rien sauvegarder ni
  restaurer.
- **Pas de retour en arrière** : installer la 0.33.0 par-dessus la RC échoue avec
  `INSTALL_FAILED_VERSION_DOWNGRADE` (même avec `-d`) ; revenir à une version antérieure exige de
  désinstaller, donc de perdre la sauvegarde. Texte pour `release.md` §4.

## 5. Bugs trouvés

**Aucun P0, aucun P1, aucun P2.** La RC n'est pas bloquée par le T3.

| # | Priorité | Description | Reproduction | Suite |
|---|---|---|---|---|
| B-1 | P3 (procédure, corrigé) | `adb install` de la RC (617 Mo) coupé quand le serveur adb redémarre (« daemon not running ; starting now » puis « device offline » ou « protocol fault ») : 3 échecs sur 5 essais, l'état de l'app est resté intact. Cause non établie (un autre client adb, probablement une autre session). | `adb install -r build/rc/pokemake-0.34.0.apk` sur l'A17 en USB pendant que d'autres sessions utilisent adb. | **Corrigé dans `release.md` §4** : `adb push` puis `adb shell pm install -r` sur le téléphone, qui a réussi à chaque fois. |
| B-2 | P3 (suggestion de jeu, à décider) | La RC n'écrit dans `logcat` ni `[qa] sauvegarde v8 → v9` ni « Sauvegarde automatique » : ces lignes n'existent qu'en build de débogage. On ne peut donc pas prouver une migration sur un proche par le journal. | Mise à jour 33 → 3400 puis `logcat -s godot`. | À signaler à Kevin ; une ligne de journal en release (« Sauvegarde migrée de la v8 à la v9 ») relève du jeu, non traitée ici. |
| B-3 | P3 (info) | L'APK release fait 616 924 680 octets, contre 476 486 244 pour la 0.33.0 de débogage (+ 29 %) : lourd à envoyer en privé (AirDrop, messagerie). | `ls -l build/rc/` | À suivre ; aucune action dans cette branche. |

Limites de ce test : un seul appareil (A17, Android 16), installation par adb uniquement (pas
d'installation depuis un fichier avec l'autorisation « sources inconnues », pas de S24 ni de S21),
restauration par le cloud de Google non éprouvée (gestionnaire de sauvegarde désactivé sur l'A17),
première utilisation par un tiers (T4) et interruptions Android (T5) hors périmètre.
