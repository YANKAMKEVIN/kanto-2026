#!/usr/bin/env bash
# Lot DAF.10c : gros plans à l'échelle du jeu (zoom 1, 2340 × 1080), joueur posé, rochers de Force.
#   tools/capture_daf10c_details.sh <dossier>
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:?dossier}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
trap 'rm -f override.cfg; rm -rf "$TMP"' EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' > override.cfg
# nom carte case_du_joueur visée
while read -r name map cell aim; do
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after 40 \
		-s res://tools/capture_viridian_forest.gd -- --map="$map" --boulders --gates= --cell="$cell" \
		--facing=down --aim="$aim" --zoom=1 > "$TMP/log.txt" 2>&1 || true
	last="$(ls "$TMP"/f/f*.png 2>/dev/null | sort | tail -1)"
	[[ -n "$last" ]] && cp "$last" "$OUT/$name.png" && echo "$OUT/$name.png"
done <<'LIST'
ecume_rochers seafoam_b3f 6,15 8.5,13
ecume_courants seafoam_b3f 12,12 17.5,10
ecume_1f seafoam_1f 16,9 17.5,8
centrale_electhor power_plant 6,9 8.5,7
centrale_salle power_plant 20,27 22.5,27
LIST
