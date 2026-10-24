#!/usr/bin/env bash
# Session téléphone groupée S2F + S2E + S2G (passe systèmes 2, docs/tech/systemes-2.md §6).
# Pour chaque départ : installe (une seule construction), dépose le départ, lance, capture l'écran
# et filtre le journal Godot dans build/qa_s2efg/<départ>.{png,log}. Les gestes du scénario
# (marcher sur un téléporteur, OUVRIR, S'ENVOLER, OBSERVER) restent à faire à la main ou par
# `adb shell input` ; le script attend Entrée entre deux départs.
# Usage : ANDROID_SERIAL=RFCR40827ZZ tools/qa/s2efg_phone.sh [départ…]
# Défaut : s2_fly s2_field_travel (les départs des cartes et du PNJ de QA sont retirés en S2Z, T33)
set -euo pipefail
cd "$(dirname "$0")/../.."
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
OUT=build/qa_s2efg
mkdir -p "$OUT"
STARTS=("$@")
[[ ${#STARTS[@]} -eq 0 ]] && STARTS=(s2_fly s2_field_travel)
BUILD_FLAG=""
for START in "${STARTS[@]}"; do
  echo "=== $START ==="
  "$ADB" logcat -c || true
  tools/deploy_s24.sh $BUILD_FLAG --debug-start "$START" --shot "$OUT/$START.png" --wait 8
  BUILD_FLAG="--no-build"
  read -r -p "Scénario de $START joué ? Entrée pour relever le journal… " _
  "$ADB" logcat -d -s godot | grep -E "Départ de débogage|SceneRouter|Sauvegarde|point de sauvegarde|ERROR|SCRIPT ERROR|KeyDoor|FlyDirector" \
    > "$OUT/$START.log" || true
  "$ADB" exec-out screencap -p > "$OUT/${START}_fin.png"
  echo "→ $OUT/$START.log, $OUT/${START}_fin.png"
done
