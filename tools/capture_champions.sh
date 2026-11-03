#!/usr/bin/env bash
# Captures réelles 2340 × 1080 de l'entrée des 8 Champions dans leur Arène (entrée, lancer, VS),
# puis planches : docs/design/fiches-assets/entree-champions/ (tools/art/planches_champions.py).
# Usage : tools/capture_champions.sh [arene ...]   (défaut : les 8)
set -euo pipefail
cd "$(dirname "$0")/.."
RACINE="$(pwd)"
ARENES=("$@")
[[ ${#ARENES[@]} -eq 0 ]] && ARENES=(argenta azuria carmin celadopole parmanie safrania cramois jadielle)
mkdir -p build/champions
for A in "${ARENES[@]}"; do
	rm -rf "build/champions/$A"
	godot --path . --resolution 2340x1080 --fixed-fps 60 -s res://tools/capture_trainer_intro.gd \
		-- --battle="$A" --shots="$RACINE/build/champions/$A" > "build/champions/$A.log" 2>&1 || true
	echo "$A : $(ls "build/champions/$A" 2>/dev/null | tr '\n' ' ')"
done
