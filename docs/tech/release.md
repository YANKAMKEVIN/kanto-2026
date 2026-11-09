# Pokemake — construire et diffuser une version (J34)

> Périmètre décidé par Kevin le 2026-11-03 : le jeu est joué par **moins d'une dizaine de proches de
> sa maison**, installé par **adb** ou par un **fichier APK release signé** partagé en privé. Pas de
> store, pas de Play Console, pas d'AAB. Une seule clé, gardée par Kevin ; `versionCode` croissant.

## 1. Identité d'une version

| Élément | Où | Valeur |
|---|---|---|
| Nom du jeu | `project.godot` `config/name`, preset Android `package/name` | **Pokemake** (orthographe tranchée le 2026-11-03) |
| Identifiant d'application | preset Android `package/unique_name`, iOS `bundle_identifier` | `dev.kevin.kanto2026` — **ne change jamais** (sauvegarde et mises à jour par-dessus) |
| Version | `project.godot` `config/version` (**source unique**) | `MAJEUR.MINEUR.CORRECTIF`, ex. `0.34.1` |
| Code Android | dérivé : `MAJEUR × 10000 + MINEUR × 100 + CORRECTIF` | `0.34.0` → **3400** (> 33, code de la référence 0.33.0 du J33) |
| Clé de signature | fichier hors dépôt, variables d'environnement | une seule, pour toujours |

`tools/version.py` écrit la version dans `project.godot` et dans les presets Android et iOS, et
`check` refuse toute divergence ; le test `tests/unit/test_version.gd` la vérifie aussi en CI.
Le jeu lit la version par `GameVersion` (`game/systems/game_version.gd`) et l'affiche en bas de
l'écran titre, du côté du logo (« v0.34.0 (3400) ») : c'est ce qu'un proche lit pour dire quelle
version il a.

```bash
tools/version.py show          # 0.34.0 (code 3400) — Pokemake
tools/version.py set 0.34.1    # nouvelle version partout, à commiter
tools/version.py check         # cohérence (lancé par build_rc.sh)
```

## 2. La clé, une seule fois (Kevin)

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='…'   # choisi dans le gestionnaire de mots de passe
tools/make_keystore.sh                               # → ~/.pokemake/pokemake-release.jks, alias pokemake
```

Puis dans `~/.zshrc` (jamais dans le dépôt, ni dans un commit, ni dans la CI) :

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/.pokemake/pokemake-release.jks"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="pokemake"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='…'
```

Ce sont les variables que Godot lit lui-même quand `keystore/release*` du preset est vide ; le
preset reste vide dans le dépôt. **Sauvegarder le fichier `.jks` et le mot de passe** (gestionnaire
de mots de passe ou disque chiffré) : clé perdue = plus aucune mise à jour par-dessus chez les
proches, il faudrait désinstaller et la sauvegarde partirait avec.

La clé réelle a été créée le 2026-11-04 par la session 34B à la demande de Kevin : keystore
`~/.pokemake/pokemake-release.jks`, alias `pokemake`, mot de passe dans `~/.pokemake/pokemake-release.pass`
(droits 600, lu par la session sans être affiché), empreinte SHA-256 du certificat
`01:E2:B9:8F:D9:23:8F:09:0F:91:35:4E:E2:92:46:8A:00:F8:45:A2:29:A4:1D:C8:2C:57:2F:44:B1:2C:6D:73`.
**À sauvegarder par Kevin** (les deux fichiers) dans son gestionnaire de mots de passe.

## 3. Construire un APK release

Sur un commit **poussé**, **propre** et **CI verte** (`tools/ci_wait.sh`) :

```bash
tools/build_rc.sh            # → build/rc/pokemake-<version>.apk + manifest.json + SHA256SUMS
tools/build_rc.sh --install  # idem, puis adb install -r sur le téléphone branché
```

Le script : vérifie l'arbre Git et la version, exige la clé, vérifie la CI du commit (`gh`),
exporte avec `--export-release` (preset `Android`, arm64-v8a, signature release), applique le fond
sombre du splash Android 12+ (`tools/android_splash_bg.py --release`, re-signé avec la même clé),
contrôle la signature (`apksigner`), l'identifiant et la version (`aapt`), puis écrit le manifeste
(version, code, commit, branche, Godot, CI, taille, SHA-256, date). `--allow-dirty` et `--skip-ci`
servent aux essais locaux seulement : le manifeste le note, on ne diffuse pas un tel APK.
Quand GitHub Actions ne peut pas tourner, `--mac-suite` remplace la CI par la suite complète lancée
sur le Mac par le script lui-même : un échec arrête le build, et le manifeste le note.

La CI ne se lance pas pour un commit qui ne touche que `docs/` ou `*.md` : dans ce cas le script
prend la CI du dernier ancêtre testé, à condition que tout ce qui a changé depuis soit de la
documentation (sinon il refuse). Le manifeste note le commit réellement testé.

Une correction après un essai chez un proche = nouvelle version (`version.py set`), nouveau commit,
nouveau build : le code Android doit augmenter pour que la mise à jour s'installe par-dessus.

## 4. Installer chez un proche

Testé sur le Galaxy A17 (Android 16) le 2026-11-04 : `docs/tech/jalon-34-34b.md`.

- **adb** (téléphone en débogage USB) : `tools/build_rc.sh --install`, ou
  `adb install -r build/rc/pokemake-<version>.apk`. L'APK fait ≈ 617 Mo : si le serveur adb redémarre
  pendant le transfert (observé), préférer `adb push build/rc/pokemake-<version>.apk /data/local/tmp/`
  puis `adb shell pm install -r /data/local/tmp/pokemake-<version>.apk` (puis `rm` du fichier).
  `-r` met à jour par-dessus **sans perdre la sauvegarde**, à condition que la version installée ait été
  signée avec la **même clé** (vérifié : 0.33.0 re-signée → 0.34.0 avec une vraie sauvegarde v6 de Kevin,
  migration passée, équipe, Sac, Pokédex et position intacts). Un APK **debug** (clé de débogage de
  Godot) installé avant est refusé (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) : il faut le **désinstaller**
  d'abord, et sa sauvegarde est perdue (le dire avant). La première installation de la RC est donc
  forcément une installation propre.
- **Fichier** : envoyer l'APK en privé (AirDrop, messagerie, clé USB) avec son SHA-256 ; sur le
  téléphone, autoriser l'installation d'applications inconnues pour l'application qui ouvre le
  fichier, puis l'installer. Mise à jour : installer le nouveau fichier par-dessus (même clé). Cette
  voie n'a pas encore été éprouvée sur un téléphone.
- **Désinstaller le jeu supprime la sauvegarde, sans retour possible** (constaté : après désinstallation
  et réinstallation, l'écran titre n'a plus « Continuer » ; l'app a `allowBackup=false`, aucune
  restauration par le cloud de Google). À dire clairement à chaque proche avant de toucher à
  l'application : « Désinstaller le jeu peut supprimer ta sauvegarde. » (texte [D] du plan du J34).
  Même chose pour « vider les données » de l'application dans les réglages d'Android.
- **Pas de retour à une version plus ancienne par-dessus** : Android refuse
  (`INSTALL_FAILED_VERSION_DOWNGRADE`, même avec `-d`) ; revenir en arrière demande de désinstaller,
  donc de perdre la sauvegarde. Une version corrigée doit toujours avoir un code Android plus grand.

## 5. Ce qui reste du J34 dans ce périmètre

- **RC 0.34.1 (3401) construite** le 2026-11-04 sur `release/0.34` @ `012bdc8c`, **Kanto seul** (décision
  de Kevin) ; paquet dans `~/.pokemake/rc/0.34.1/` ; rapport et limitations : `jalon-34-rapport.md`.
- **T4** première utilisation par un proche sans aide : à Kevin, consignes `jalon-34-t4-consignes.md`.
- **Encore à éprouver** : installation depuis un fichier ; RC sur le S24 et le S21, seulement avec l'accord
  de Kevin, car il faut y retirer l'app debug et donc risquer la sauvegarde.
- **Version suivante pour les proches** : **RC 0.35.0 (3500), jeu complet, depuis `main`** (décision de Kevin du
  2026-11-06, remplace « RC Kanto seul »). La sauvegarde migre de v9 en v10. État et étapes : `rc-0.35.0.md`.
- **Envoi au téléphone** : si `adb push` de ≈ 650 Mo fait tomber le serveur adb, envoyer par morceaux de
  100 Mo (`split`, `adb push -Z`, `cat` sur le téléphone) et comparer le SHA-256. L'activité à lancer est
  `dev.kevin.kanto2026/com.godot.game.GodotAppLauncher`.
- iOS (`docs/tech/ios.md`) : hors de ce chemin ; TestFlight interne demande un compte développeur.
