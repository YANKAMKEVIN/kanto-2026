#!/usr/bin/env bash
# Captures du jalon JOHP1 (Ruines d'Alpha ; `docs/tech/jalon-joh-pierres.md` §3) : Route 36 (variante
# ARC), Ruines, tente, Galerie, dalles, Chambre. 2340 × 1080, Movie Maker (Mac, pas en headless), par
# `tools/capture_pewter.gd` en mode `--boot` (vraie scène `game/boot.tscn`).
#   tools/capture_johp1.sh [dossier [filtre]]   (défaut : build/captures/johp1, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/johp1}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

ROUTE="--boot --start=johto_alph_route_36"
RUINS="--boot --start=johto_alph_ruins"
TENT="--boot --start=johto_alph_tent"
GALLERY="--boot --start=johto_alph_gallery"
TILES="--boot --start=johto_alph_tiles"
CHAMBER="--boot --start=johto_alph_chamber"
SHOTS=(
	"route_36_ouverte|50|$ROUTE --cell=40,16 --facing=down"
	"route_36_barriere|50|$ROUTE --cell=40,15 --facing=down"
	"ruines_nord|50|$RUINS --cell=17,4 --facing=down"
	"ruines_tente|50|$RUINS --cell=8,15 --facing=up"
	"ruines_temple|50|$RUINS --cell=17,16 --facing=down"
	"tente|50|$TENT --cell=4,3 --facing=up"
	"galerie_entree|50|$GALLERY --cell=6,13 --facing=up"
	"galerie_fouilles|50|$GALLERY --cell=5,6 --facing=up"
	"galerie_sbire_x|50|$GALLERY --cell=8,14 --facing=right"
	"galerie_dalles|50|$TILES --cell=16,11 --facing=up"
	"galerie_dalles_haut|50|$TILES --cell=16,6 --facing=up --flags=johto_alph_tile_1"
	"galerie_porte|50|$TILES --cell=16,5 --facing=up --flags=johto_alph_tile_1,johto_alph_tile_2"
	"galerie_mur_3|50|$TILES --cell=16,14 --facing=down"
	"chambre|50|$CHAMBER --cell=6,8 --facing=up"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" | grep -v "_on_focus_change" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
