#!/usr/bin/env bash
# Captures du jalon JOHP2 (arc des Pierres : Goéland, Irisia, Grotte de la Marée, Oliville variante ARC ;
# `docs/tech/jalon-joh-pierres.md` §4). 2340 × 1080, Movie Maker (Mac), `tools/capture_pewter.gd --boot`.
#   tools/capture_johp2.sh [dossier [filtre]]   (défaut : build/captures/johp2, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/johp2}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

S="--boot --start="
# nom | images | options de capture_pewter.gd
SHOTS=(
	"oliville_goeland|60|${S}johto_johp2_olivine --cell=41,33 --facing=left"
	"oliville_goulven_p12|260|${S}johto_johp2_olivine --cell=40,33 --facing=down --mash=30"
	"pont_arrivee|60|${S}johto_johp2_deck"
	"pont_goulven|60|${S}johto_johp2_deck --cell=11,3 --facing=right"
	"irisia_quai|60|${S}johto_johp2_cianwood"
	"irisia_centre|60|${S}johto_johp2_cianwood_autosave"
	"irisia_goulven_maison|60|${S}johto_johp2_cianwood --cell=10,14 --facing=up"
	"irisia_grotte|60|${S}johto_johp2_cianwood --cell=6,15 --facing=left"
	"irisia_plage_bateau|60|${S}johto_johp2_cianwood --cell=24,25 --facing=down"
	"irisia_nuit|60|${S}johto_johp2_cianwood_night"
	"grotte_1f_hall|60|${S}johto_johp2_tide_1f"
	"grotte_1f_pompes|60|${S}johto_johp2_tide_1f --cell=8,9 --facing=up"
	"grotte_b1f_quai|60|${S}johto_johp2_tide_b1f"
	"grotte_b1f_gues|60|${S}johto_johp2_chief --cell=12,5 --facing=down"
	"grotte_b1f_socle|300|${S}johto_johp2_socle --hold=left --mash=30"
	"mer_sud|200|${S}johto_johp2_south_sea --hold=up --mash=20"
	"centre_interieur|120|${S}johto_johp2_cianwood_autosave --hold=up"
	"maison_goulven|160|${S}johto_johp2_cianwood --cell=10,14 --hold=up"
	"maison_1|160|${S}johto_johp2_cianwood --cell=21,22 --hold=up"
	"rosalia_corentin|60|${S}johto_johp2_rosalia --cell=33,18 --facing=right"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" | grep -v "_on_focus_change" | head -5 && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
