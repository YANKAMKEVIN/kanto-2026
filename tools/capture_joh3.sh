#!/usr/bin/env bash
# Captures du jalon JOH3 (Routes 37, 36, 35, Doublonville, Souterrain ; `docs/tech/jalon-joh3.md`
# T13, dossier joh-04 §14) : Routes 37 et 35 de nuit, Route 36, Doublonville de jour et de nuit,
# Souterrain, Grand Magasin et toit, Centre (Orme). 2340 × 1080, Movie Maker (Mac, pas en
# headless), par `tools/capture_pewter.gd` en mode `--boot` (vraie scène `game/boot.tscn`).
#   tools/capture_joh3.sh [dossier [filtre]]   (défaut : build/captures/joh3, tout)
# Une image par plan (dernière image du film). override.cfg temporaire à la racine, retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh3}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R37="--boot --start=johto_route_37"
R37N="--boot --start=johto_route_37_night"
GOL="--boot --start=johto_goldenrod"
GOLN="--boot --start=johto_goldenrod_night"
UND="--boot --start=johto_underground"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r37_jour_entree|50|$R37 --cell=9,2 --facing=down"
	"r37_jour_bosquet|50|$R37 --cell=12,22 --facing=right"
	"r37_nuit_bosquet|50|$R37N --cell=12,25 --facing=right"
	"r37_nuit_sbire_b|50|$R37N --cell=7,29 --facing=left"
	"r36_carrefour|50|--boot --start=johto_route_36_wednesday --cell=24,10 --facing=right"
	"r36_pont|50|--boot --start=johto_route_36_wednesday --cell=40,10 --facing=right"
	"r36_parc|50|--boot --start=johto_route_36_wednesday --cell=33,8 --facing=up"
	"r35_nuit_etang|50|--boot --start=johto_route_35_night --cell=9,20 --facing=left"
	"r35_nuit_anna|50|--boot --start=johto_route_35_night --cell=11,36 --facing=down"
	"gol_jour_entree|50|$GOL --cell=35,4 --facing=down"
	"gol_haut_parleur|160|$GOL --hold=down --mash=4"
	"gol_jour_place|50|$GOL --cell=35,29 --facing=down"
	"gol_jour_tour_radio|50|$GOL --cell=11,17 --facing=up"
	"gol_jour_magasin|50|$GOL --cell=50,29 --facing=up"
	"gol_jour_sud|50|$GOL --cell=35,54 --facing=down"
	"gol_nuit_place|50|$GOLN --cell=35,29 --facing=down"
	"gol_nuit_avenue|50|$GOLN --cell=35,12 --facing=down"
	"gol_jeudi_jerome|50|--boot --start=johto_goldenrod_thursday --cell=54,28 --facing=right"
	"und_entree|50|$UND --cell=3,6 --facing=right"
	"und_chef|50|$UND --cell=32,8 --facing=down"
	"centre_orme|50|--boot --start=johto_goldenrod_full_party --cell=8,5 --facing=right"
	"magasin_rdc|50|--map=goldenrod_dept_store_1f --cell=9,7 --facing=up"
	"magasin_toit|50|--map=goldenrod_dept_store_roof --cell=12,5 --facing=up"
	"maison_lien|50|--map=goldenrod_bond_house --cell=7,7 --facing=up"
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
