#!/usr/bin/env bash
# Installe, lance et capture l'écran sur le Galaxy S24 (câble USB ou débogage sans fil).
# Usage : tools/deploy_s24.sh [--no-build] [--shot chemin.png] [--wait secondes]
#                             [--debug-start nom]
# --debug-start nom : dépose tools/debug_start/<nom>.json comme départ de débogage
# (user://debug_start.json, lu par l'APK debug seulement) ; sans cette option, le fichier est
# retiré et la partie démarre normalement. Voir tools/debug_start/README.md.
set -euo pipefail
cd "$(dirname "$0")/.."
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
export ADB
PKG="dev.kevin.kanto2026"
BUILD=1; SHOT="build/screenshot.png"; WAIT=5; DEBUG_START=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) BUILD=0 ;;
    --shot) SHOT="$2"; shift ;;
    --wait) WAIT="$2"; shift ;;
    --debug-start) DEBUG_START="$2"; shift ;;
  esac; shift
done
if [[ -n "$DEBUG_START" && ! -f "tools/debug_start/$DEBUG_START.json" ]]; then
  echo "Départ de débogage inconnu : tools/debug_start/$DEBUG_START.json" >&2
  exit 1
fi
[[ $BUILD == 1 ]] && tools/build_android.sh
SERIAL=$(tools/s24_serial.sh) || exit 1
echo "S24 : $SERIAL"
"$ADB" -s "$SERIAL" install -r build/kanto2026-debug.apk | tail -1
"$ADB" -s "$SERIAL" shell am force-stop "$PKG"
# Départ de débogage : user:// de l'appli = son dossier files/ (run-as : APK debug seulement).
if [[ -n "$DEBUG_START" ]]; then
  "$ADB" -s "$SERIAL" shell "run-as $PKG sh -c 'mkdir -p files && cat > files/debug_start.json'" \
    < "tools/debug_start/$DEBUG_START.json"
  echo "Départ de débogage : $DEBUG_START"
else
  "$ADB" -s "$SERIAL" shell "run-as $PKG rm -f files/debug_start.json" || true
fi
"$ADB" -s "$SERIAL" logcat -c
"$ADB" -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep "$WAIT"
mkdir -p "$(dirname "$SHOT")"
"$ADB" -s "$SERIAL" exec-out screencap -p > "$SHOT"
echo "Capture : $SHOT"
echo "--- logs Godot ---"
"$ADB" -s "$SERIAL" logcat -d -s godot:V | tail -40
