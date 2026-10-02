#!/usr/bin/env bash
# Installe, lance et capture l'écran sur le Galaxy S24 (câble USB ou débogage sans fil).
# Usage : tools/deploy_s24.sh [--no-build] [--shot chemin.png] [--wait secondes]
set -euo pipefail
cd "$(dirname "$0")/.."
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
export ADB
PKG="dev.kevin.kanto2026"
BUILD=1; SHOT="build/screenshot.png"; WAIT=5
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) BUILD=0 ;;
    --shot) SHOT="$2"; shift ;;
    --wait) WAIT="$2"; shift ;;
  esac; shift
done
[[ $BUILD == 1 ]] && tools/build_android.sh
SERIAL=$(tools/s24_serial.sh) || exit 1
echo "S24 : $SERIAL"
"$ADB" -s "$SERIAL" install -r build/kanto2026-debug.apk | tail -1
"$ADB" -s "$SERIAL" shell am force-stop "$PKG"
"$ADB" -s "$SERIAL" logcat -c
"$ADB" -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep "$WAIT"
mkdir -p "$(dirname "$SHOT")"
"$ADB" -s "$SERIAL" exec-out screencap -p > "$SHOT"
echo "Capture : $SHOT"
echo "--- logs Godot ---"
"$ADB" -s "$SERIAL" logcat -d -s godot:V | tail -40
