#!/usr/bin/env bash
# Captures de la peinture du Mont Argenté et de la Route 28, de jour et de nuit : vues d'ensemble et
# vues du joueur. 2340 × 1080, Movie Maker (Mac, pas en headless), par `tools/capture_pewter.gd`.
#   tools/capture_joh9_art.sh [dossier [filtre]]   (défaut : build/captures/joh9_art, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh9_art}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f tools/debug_start/_capargente_*.json; rm -rf "$TMP"; }
trap cleanup EXIT
python3 - <<'PY'
import json
for name, source, place in (("trail", "johto_mt_silver", None),
		("outside", "johto_mt_silver_outside", None), ("summit", "johto_after_chapter", None),
		("3f", "johto_route_28", ("mt_silver_3f", "from_2f")),
		("route", "johto_route_28", ("route_28", "from_mt_silver"))):
	for period in ("day", "night"):
		start = json.load(open(f"tools/debug_start/{source}.json"))
		start["period"] = period
		if place:
			start["map"], start["spawn"] = place
		json.dump(start, open(f"tools/debug_start/_capargente_{name}_{period}.json", "w"), ensure_ascii=False)
PY
S="--boot --start=_capargente_"
SHOTS=(
	"vue_sentier|30|--map=silver_trail --noplayer --aim=12,22 --zoom=0.24"
	"vue_exterieur|30|--map=mt_silver_outside --noplayer --aim=20,20 --zoom=0.27"
	"vue_1f|30|--map=mt_silver_1f --noplayer --aim=16,14 --zoom=0.38"
	"vue_2f|30|--map=mt_silver_2f --noplayer --aim=16,14 --zoom=0.38"
	"vue_3f|30|--map=mt_silver_3f --noplayer --aim=14,12 --zoom=0.42"
	"vue_sommet|30|--map=mt_silver_summit --noplayer --aim=10,9 --zoom=0.55"
	"vue_route_28|30|--map=route_28 --noplayer --aim=22,10 --zoom=0.5"
	"sentier_entree|50|${S}trail_day --cell=2,41 --facing=right"
	"sentier_centre|50|${S}trail_day --cell=6,13 --facing=up"
	"sentier_hugo|50|${S}trail_day --cell=12,27 --facing=up"
	"exterieur_esplanade|50|${S}outside_day --cell=19,17 --facing=up"
	"grotte_1f_entree|50|--boot --start=johto_mt_silver_1f"
	"grotte_1f_lac|50|--boot --start=johto_mt_silver_1f --cell=15,18 --facing=up"
	"grotte_1f_rochers|50|--boot --start=johto_mt_silver_1f --cell=12,9 --facing=up"
	"grotte_2f_flash|150|--boot --start=johto_mt_silver_2f"
	"grotte_3f|50|${S}3f_day --cell=8,13 --facing=up"
	"grotte_3f_corniche|50|${S}3f_day --cell=19,12 --facing=up"
	"sommet_arrivee|50|${S}summit_day --cell=16,8 --facing=up"
	"sommet_centre|50|${S}summit_day --cell=9,12 --facing=up"
	"sommet_bas|50|${S}summit_day --cell=9,16 --facing=down"
	"route_28_est|50|${S}route_day --cell=38,10 --facing=left"
	"route_28_maison|50|${S}route_day --cell=23,11 --facing=up"
	"route_28_poste|50|${S}route_day --cell=6,11 --facing=up"
	"nuit_route_28|50|${S}route_night --cell=23,11 --facing=up"
	"poste|50|--boot --start=johto_route_28_gate --cell=4,5 --facing=up"
	"nuit_sentier|50|${S}trail_night --cell=6,13 --facing=up"
	"nuit_sentier_sud|50|${S}trail_night --cell=12,30 --facing=up"
	"nuit_exterieur|50|${S}outside_night --cell=19,17 --facing=up"
	"nuit_sommet|50|${S}summit_night --cell=9,12 --facing=up"
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
