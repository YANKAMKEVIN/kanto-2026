#!/bin/bash
# Captures du CB.3 en 2340 x 1080 : vrai combat sauvage complet sur le décor peint de la
# Route 1, puis le repli (labo : carte recadrée et floutée), et la planche combat-v1 | jeu.
# Sortie : build/captures/combat_cb3/ (ou $OUT). Passe « poses » : ton Pokémon au sol, plusieurs
# espèces (correctifs après la QA S24).
set -e
cd "$(dirname "$0")/.."
OUT=${OUT:-build/captures/combat_cb3}
mkdir -p "$OUT"
for PLACE in route_1 oak_lab route_22; do
	godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
		-s res://tools/capture_combat_cb3.gd -- --out="$OUT" --place="$PLACE" 2>&1 \
		| grep -E "ERROR|CAPTURE|\[perf\]" || true
done
godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
	-s res://tools/capture_combat_cb3.gd -- --out="$OUT" --pass=poses 2>&1 \
	| grep -E "ERROR|CAPTURE|\[perf\]" || true
python3 tools/art/combat_decors/planche_comparaison.py "$OUT"
