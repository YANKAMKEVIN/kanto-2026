# Pokemake — construire et diffuser une version (J34)

> Périmètre décidé par Kevin le 2026-11-03 : le jeu est joué par **moins d'une dizaine de proches de
> sa maison**, installé par **adb** ou par un **fichier APK release signé** partagé en privé. Pas de
> store, pas de Play Console, pas d'AAB. Une seule clé, gardée par Kevin ; `versionCode` croissant.

## 1. Identité d'une version

| Élément | Où | Valeur |
|---|---|---|
| Nom du jeu | `project.godot` `config/name`, preset Android `package/name` | **Pokemake** (orthographe à l'écran à confirmer avant le logo) |
| Identifiant d'application | preset Android `package/unique_name`, iOS `bundle_identifier` | `dev.kevin.kanto2026` — **ne change jamais** (sauvegarde et mises à jour par-dessus) |
| Version | `project.godot` `config/version` (**source unique**) | `MAJEUR.MINEUR.CORRECTIF`, ex. `0.34.0` |
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

La CI ne se lance pas pour un commit qui ne touche que `docs/` ou `*.md` : dans ce cas le script
prend la CI du dernier ancêtre testé, à condition que tout ce qui a changé depuis soit de la
documentation (sinon il refuse). Le manifeste note le commit réellement testé.

Une correction après un essai chez un proche = nouvelle version (`version.py set`), nouveau commit,
nouveau build : le code Android doit augmenter pour que la mise à jour s'installe par-dessus.

## 4. Installer chez un proche

- **adb** (téléphone en débogage USB) : `tools/build_rc.sh --install`, ou
  `adb install -r build/rc/pokemake-<version>.apk`. `-r` met à jour par-dessus sans perdre la
  sauvegarde, à condition que la version installée ait été signée avec la **même clé** : un APK
  **debug** (clé de débogage de Godot) installé avant doit être **désinstallé** d'abord, et sa
  sauvegarde est perdue (le dire avant).
- **Fichier** : envoyer l'APK en privé (AirDrop, messagerie, clé USB) avec son SHA-256 ; sur le
  téléphone, autoriser l'installation d'applications inconnues pour l'application qui ouvre le
  fichier, puis l'installer. Mise à jour : installer le nouveau fichier par-dessus.
- Désinstaller le jeu supprime la sauvegarde locale : « Désinstaller le jeu peut supprimer ta
  sauvegarde. » (texte [D] du plan du J34).

## 5. Ce qui reste du J34 dans ce périmètre

- **Nom à l'écran** : logo peint « Pokemake » (écran titre, splash `boot_splash/image`, icônes si
  besoin) quand Kevin a tranché l'orthographe (Pokemake / Pokémake / PokéMake…).
- **T3** installation propre, mise à jour par-dessus 0.33.0 avec une vraie sauvegarde, désinstallation :
  sur les téléphones réellement disponibles (A17 ; S24 et S21 quand ils reviennent).
- **T4** première utilisation par un proche sans aide ; **T5** interruptions Android (sur APK signé) ;
  **T6** inventaire des ressources (lecture seule) ; **T7** rapport et décision de Kevin.
- iOS (`docs/tech/ios.md`) : hors de ce chemin ; TestFlight interne demande un compte développeur.
