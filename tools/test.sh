#!/usr/bin/env bash
# Lance les tests GUT en headless. Usage : tools/test.sh [dossier_res]  (défaut : res://tests)
set -euo pipefail
cd "$(dirname "$0")/.."
DIR="${1:-res://tests}"
# Garde-fou : aucune mesure de durée en temps réel dans les tests (voir le script).
tools/check_test_timing.sh tests
godot --headless --path . --import >/dev/null 2>&1 || true
LOG="$(mktemp -t kanto_gut.XXXXXX)"
trap 'rm -f "$LOG"' EXIT
status=0
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir="$DIR" -ginclude_subdirs -gexit -glog=1 \
	2>&1 | tee "$LOG" || status=$?
# Garde-fou : GUT ignore sans échec un fichier de test qui ne se charge pas (erreur de
# syntaxe) et finit quand même « All tests passed ». On échoue dans ce cas.
if grep -E "Parse Error|Ignoring script|Failed to load script|SCRIPT ERROR" "$LOG" >/dev/null; then
	echo "ÉCHEC : un script de test ne s'est pas chargé (voir les lignes ci-dessous)." >&2
	grep -E "Parse Error|Ignoring script|Failed to load script|SCRIPT ERROR" "$LOG" | head -20 >&2
	exit 1
fi
exit "$status"
