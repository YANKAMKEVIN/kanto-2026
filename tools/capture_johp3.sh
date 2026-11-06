#!/usr/bin/env bash
# Captures du jalon JOHP3 (Ébènelle, Antre du Dragon, Sanctuaire ; `docs/tech/jalon-joh-pierres.md`
# §5) : 2340 × 1080, Movie Maker (Mac, pas en headless), par `tools/capture_pewter.gd` en mode
# `--boot` (vraie scène `game/boot.tscn`).
#   tools/capture_johp3.sh [dossier [filtre]]   (défaut : build/captures/johp3, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/johp3}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

CITY="--boot --start=johto_blackthorn"
DEN="--boot --start=johto_den_1f"
SANCTUARY="--boot --start=johto_den_sanctuary"
ALTAR="--boot --start=johto_den_altar"
ROSALIA="--boot --start=johto_rosalia_corentin"
SHOTS=(
	"ebenelle_aire|50|$CITY --cell=15,24 --facing=up"
	"ebenelle_rue|50|$CITY --cell=16,14 --facing=right"
	"ebenelle_maison_aieule|50|$CITY --cell=15,12 --facing=up"
	"ebenelle_centre|50|$CITY --cell=23,13 --facing=up"
	"antre_croisee|50|$DEN --cell=13,15 --facing=up"
	"antre_eau|50|$DEN --cell=5,13 --facing=left"
	"antre_ciel|50|$DEN --cell=14,5 --facing=up"
	"sanctuaire_entree|50|$SANCTUARY --cell=10,14 --facing=down"
	"sanctuaire_autel|50|$ALTAR --cell=10,7 --facing=up"
	"sanctuaire_cenere|200|$ALTAR --hold=up"
	"rosalia_corentin|50|$ROSALIA --cell=34,18 --facing=right"
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
