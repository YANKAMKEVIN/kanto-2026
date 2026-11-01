#!/usr/bin/env bash
# Exporte l'APK debug. Usage : tools/build_android.sh [preset] [sortie.apk]
# preset : nom du preset d'export (défaut « Android », celui du S24) ; un preset de test peut
# être ajouté dans export_presets.cfg et passé ici sans toucher au preset principal.
# sortie : chemin de l'APK (défaut build/kanto2026-debug.apk).
set -euo pipefail
cd "$(dirname "$0")/.."
PRESET="${1:-Android}"
APK="${2:-build/kanto2026-debug.apk}"
mkdir -p "$(dirname "$APK")"
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-debug "$PRESET" "$APK" 2>&1 | grep -E "ERROR|WARNING|DONE|rror" || true
test -f "$APK"
# Fond sombre de l'écran de démarrage système Android 12+ (Godot l'ignore sans build Gradle).
python3 tools/android_splash_bg.py "$APK" 2>&1 | grep -v "^WARNING: \|^$"
echo "APK : $APK ($(du -h "$APK" | cut -f1))"
