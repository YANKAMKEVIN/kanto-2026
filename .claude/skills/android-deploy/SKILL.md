---
name: android-deploy
description: Exporter Kanto 2026 en APK et le tester sur le Galaxy S24 de Kevin — build headless, installation adb, lancement, capture d'écran, logs Godot, simulation de gestes tactiles, mesure des FPS. À charger pour toute validation sur téléphone.
---

# Déploiement et test sur le Galaxy S24

## Environnement (déjà configuré)

- Godot 4.7.2 + templates d'export installés ; editor settings pointent le SDK `~/Library/Android/sdk` et Java = JBR 21 d'Android Studio ; keystore debug dans `~/Library/Application Support/Godot/keystores/`.
- adb : `~/Library/Android/sdk/platform-tools/adb` (**pas dans le PATH**).
- S24 : série matérielle `RFCX80Y0FVX`, écran **2340×1080** en paysage. Il peut être branché en **USB ou en débogage sans fil** (série `ip:port` ou `adb-RFCX80Y0FVX-…`) : toujours résoudre la série avec `S24=$(tools/s24_serial.sh)` et passer `-s "$S24"`, jamais une série codée en dur.
- Preset « Android » dans `export_presets.cfg` : arm64 seul, sans gradle build, package `dev.kevin.kanto2026`, immersif.
- Kevin teste sur le **téléphone physique**, pas sur l'émulateur (lent et instable sur ce Mac).

## Commandes

```bash
tools/build_android.sh                          # → build/kanto2026-debug.apk
tools/deploy_s24.sh                             # build + install + lancement + capture + logs
tools/deploy_s24.sh --no-build --wait 8 --shot build/s24_bourg.png
```
Puis **lire la capture** (`Read build/screenshot.png`) et vérifier : rendu, lisibilité, marges de l'encoche (caméra perforée à gauche en paysage), zones tactiles.

Si le téléphone n'est pas détecté (`tools/s24_serial.sh` échoue) : demander à Kevin de brancher et déverrouiller le S24, ou d'activer le **débogage sans fil** (même Wi-Fi que le Mac). Ne pas basculer sur l'émulateur.

## Logs

```bash
ADB=~/Library/Android/sdk/platform-tools/adb
S24=$(tools/s24_serial.sh)
$ADB -s "$S24" logcat -d -s godot:V | tail -80        # print() et erreurs Godot
$ADB -s "$S24" logcat -d | grep -E "AndroidRuntime|FATAL" # crash natif
```

## Simuler des gestes (coordonnées écran physiques 2340×1080)

```bash
$ADB -s "$S24" shell input tap 2100 850                     # toucher (bouton droit)
$ADB -s "$S24" shell input swipe 400 800 400 800 1500       # appui long 1,5 s
$ADB -s "$S24" shell input swipe 400 800 600 800 2000       # glisser vers la droite (joystick)
```
Conversion depuis la résolution de référence 1920×1080 (aspect expand) : la hauteur est identique (y réf = y écran) ; en largeur l'espace est élargi à ~2340, donc x écran ≈ x réf + (2340−1920)/2 pour des éléments centrés, x réf pour des éléments ancrés à gauche, x réf + 420 pour des éléments ancrés à droite.

## FPS

Le jeu l'écrit déjà : en build debug seulement (`PerfCounter`, `game/systems/debug/perf_counter.gd`, ajouté par Boot quand il est la scène principale ; jamais sous GUT ni dans un outil), une ligne toutes les 2 s :

`[perf] fps=60 min=54 draw=87 tex=18.4` (`fps` = moyenne sur la fenêtre de 2 s, `min` = cadence de l'image la plus lente de la fenêtre, pour repérer une saccade pendant une transition ou un lancer, `draw` = appels de dessin de la dernière image, `tex` = mémoire des textures en Mo, budget 64 Mo par carte au J7).

Lecture : `adb logcat -s godot:V | grep perf`. Objectif : **60 fps stables** en exploration et en combat.

## Checklist de validation d'une fonctionnalité

1. `tools/test.sh` vert.
2. Import sans erreur.
3. APK construit, installé, lancé sans crash (logcat propre, aucune `SCRIPT ERROR`).
4. Capture S24 vérifiée visuellement ; comparée à `docs/design/ui-reference.md` si UI.
5. Geste(s) de la fonctionnalité simulé(s) avec `input` et effet constaté sur une seconde capture.
6. FPS ≥ 58 sur 10 s.
7. Compte rendu : ce qui marche, captures, ce qui reste — puis **validation de Kevin sur son téléphone** avant la fonctionnalité suivante.
