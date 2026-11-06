#!/usr/bin/env bash
# Captures de la peinture des Ruines d'Alpha, de jour et de nuit : vues d'ensemble et vues du joueur.
# 2340 × 1080, Movie Maker (Mac, pas en headless), par `tools/capture_pewter.gd`.
#   tools/capture_johp1_art.sh [dossier [filtre]]   (défaut : build/captures/johp1_art, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/johp1_art}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f tools/debug_start/_capalpha_*.json; rm -rf "$TMP"; }
trap cleanup EXIT
python3 - <<'PY'
import json
for period in ("day", "night"):
	start = json.load(open("tools/debug_start/johto_alph_ruins.json"))
	start["period"] = period
	json.dump(start, open(f"tools/debug_start/_capalpha_{period}.json", "w"), ensure_ascii=False)
PY
DAY="--boot --start=_capalpha_day"
NIGHT="--boot --start=_capalpha_night"
SHOTS=(
	"ruines_vue|30|--map=ruins_of_alph --noplayer --aim=18,15 --zoom=0.36"
	"tente_vue|30|--map=alph_tent --noplayer --aim=4.5,3.5 --zoom=1"
	"galerie_vue|30|--map=alph_gallery --noplayer --aim=12,9 --zoom=0.6"
	"chambre_vue|30|--map=alph_chamber --noplayer --aim=7,6 --zoom=0.9"
	"ruines_nord|50|$DAY --cell=17,4 --facing=down"
	"ruines_tente|50|$DAY --cell=8,15 --facing=up"
	"ruines_temple|50|$DAY --cell=17,17 --facing=down"
	"ruines_nuit_tente|50|$NIGHT --cell=8,15 --facing=up"
	"ruines_nuit_temple|50|$NIGHT --cell=17,17 --facing=down"
	"tente|50|--boot --start=johto_alph_tent --cell=4,4 --facing=up"
	"galerie_entree|50|--boot --start=johto_alph_gallery --cell=6,13 --facing=up"
	"galerie_fouilles|50|--boot --start=johto_alph_gallery --cell=5,5 --facing=up"
	"galerie_dalles|50|--boot --start=johto_alph_tiles --cell=16,11 --facing=up"
	"galerie_porte|50|--boot --start=johto_alph_tiles --cell=16,5 --facing=up --flags=johto_alph_tile_1,johto_alph_tile_2"
	"chambre|50|--boot --start=johto_alph_chamber --cell=6,8 --facing=up"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --resolution 2340x1080 --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "SCRIPT ERROR" "$TMP/log.txt" | head -3 || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
