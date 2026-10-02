#!/usr/bin/env bash
# Installe, lance et capture l'écran sur le Galaxy S24 (câble USB ou débogage sans fil).
# Usage : tools/deploy_s24.sh [--no-build] [--shot chemin.png] [--wait secondes]
#                             [--debug-start nom] [--debug-unlock pokedex]
# --debug-start nom : dépose tools/debug_start/<nom>.json comme départ de débogage
# (user://debug_start.json, lu par l'APK debug seulement) ; sans cette option, le fichier est
# retiré et la partie démarre normalement. Voir tools/debug_start/README.md.
# --debug-unlock pokedex : dépose user://debug_unlocks.json ({ "pokedex": true }), qui débloque
# l'écran Pokédex du Menu Dresseur SANS poser le drapeau d'histoire (DebugUnlocks, APK debug
# seulement, jamais sauvegardé) ; marche avec la vraie partie comme avec --debug-start. Sans
# l'option, le fichier est retiré. Option répétable ; noms connus : DebugUnlocks.KEYS.
set -euo pipefail
cd "$(dirname "$0")/.."
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
export ADB
PKG="dev.kevin.kanto2026"
BUILD=1; SHOT="build/screenshot.png"; WAIT=5; DEBUG_START=""; DEBUG_UNLOCKS=""
KNOWN_UNLOCKS=" pokedex "
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) BUILD=0 ;;
    --shot) SHOT="$2"; shift ;;
    --wait) WAIT="$2"; shift ;;
    --debug-start) DEBUG_START="$2"; shift ;;
    --debug-unlock) DEBUG_UNLOCKS="$DEBUG_UNLOCKS $2"; shift ;;
  esac; shift
done
if [[ -n "$DEBUG_START" && ! -f "tools/debug_start/$DEBUG_START.json" ]]; then
  echo "Départ de débogage inconnu : tools/debug_start/$DEBUG_START.json" >&2
  exit 1
fi
UNLOCKS_JSON=""
for NAME in $DEBUG_UNLOCKS; do
  if [[ "$KNOWN_UNLOCKS" != *" $NAME "* ]]; then
    echo "Déblocage de débogage inconnu : $NAME (connus :$KNOWN_UNLOCKS)" >&2
    exit 1
  fi
  UNLOCKS_JSON="$UNLOCKS_JSON${UNLOCKS_JSON:+, }\"$NAME\": true"
done
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
# Déblocages de débogage du Menu Dresseur : user://debug_unlocks.json, même mécanique.
if [[ -n "$UNLOCKS_JSON" ]]; then
  printf '{ %s }\n' "$UNLOCKS_JSON" | "$ADB" -s "$SERIAL" shell \
    "run-as $PKG sh -c 'mkdir -p files && cat > files/debug_unlocks.json'"
  echo "Déblocages de débogage :$DEBUG_UNLOCKS"
else
  "$ADB" -s "$SERIAL" shell "run-as $PKG rm -f files/debug_unlocks.json" || true
fi
"$ADB" -s "$SERIAL" logcat -c
"$ADB" -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep "$WAIT"
mkdir -p "$(dirname "$SHOT")"
"$ADB" -s "$SERIAL" exec-out screencap -p > "$SHOT"
echo "Capture : $SHOT"
echo "--- logs Godot ---"
"$ADB" -s "$SERIAL" logcat -d -s godot:V | tail -40
