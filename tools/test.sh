#!/usr/bin/env bash
# Lance les tests GUT en headless. Usage : tools/test.sh [dossier_res]  (défaut : res://tests)
set -euo pipefail
cd "$(dirname "$0")/.."
DIR="${1:-res://tests}"
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir="$DIR" -ginclude_subdirs -gexit -glog=1
