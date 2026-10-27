#!/usr/bin/env bash
# Exporte l'APK debug. Usage : tools/build_android.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-debug "Android" build/kanto2026-debug.apk 2>&1 | grep -E "ERROR|WARNING|DONE|rror" || true
test -f build/kanto2026-debug.apk
# Fond sombre de l'écran de démarrage système Android 12+ (Godot l'ignore sans build Gradle).
python3 tools/android_splash_bg.py build/kanto2026-debug.apk 2>&1 | grep -v "^WARNING: \|^$"
echo "APK : build/kanto2026-debug.apk ($(du -h build/kanto2026-debug.apk | cut -f1))"
