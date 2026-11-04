# Jalon 34 — 34B (T3) : installation propre, mise à jour, désinstallation sur l'A17

> Plan : `docs/tech/jalon-34.md` §2 T3 ; procédure de build : `docs/tech/release.md`.
> Branche `claude/j34-34b-c7976d`. Appareil : Galaxy A17 (série `R5GYB2R7W2Y`, adb sans fil), le
> S24 n'étant pas disponible depuis le 2026-10-31. Session : 34B (2026-11-04).
> **État : procédure prête, exécution en attente de la clé de signature de Kevin et de l'A17**
> (voir §1). Les fiches du §4 se remplissent pendant l'exécution.

## 1. Préalables (état au 2026-11-04)

| Préalable | État |
|---|---|
| Commit à construire | `99dfa688` = `origin/main`, **CI verte** (run 41711310886). `build_rc.sh` exige un arbre propre (fichiers suivis) et cette CI : on construit **avant** de modifier un fichier suivi, les fiches restent donc dans ce fichier neuf. |
| Clé de signature | **Absente** : `~/.pokemake/` n'existe pas, aucune variable `GODOT_ANDROID_KEYSTORE_RELEASE_*`. Kevin la crée (`tools/make_keystore.sh`, `release.md` §2) ; cette session ne la crée jamais. |
| A17 en adb | **Non connecté** au Mac au moment de l'écriture (`adb devices` vide, aucun service mDNS). Il faut que Kevin le rallume en débogage sans fil. |
| Tour sur l'A17 | À demander à la session coordinatrice (voir §2.0). |
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
4. Fermer l'app, puis **`adb install -r build/rc/pokemake-0.34.0.apk`** (mise à jour, 33 → 3400).
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

### Fiche 0 — mise à jour d'un APK debug par la RC (signature)
_À remplir._

### Fiche 1 — installation propre et première sauvegarde
_À remplir (modèle, version Android, build, résultat, journal Godot pertinent)._

### Fiche 2 — mise à jour 0.33.0 → 0.34.0 avec une vraie sauvegarde
_À remplir._

### Fiche 3 — désinstallation
_À remplir._

## 5. Bugs trouvés

| # | Priorité | Description | Reproduction | Suite |
|---|---|---|---|---|
| — | — | aucun relevé pour l'instant | — | — |
