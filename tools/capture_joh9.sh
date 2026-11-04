#!/usr/bin/env bash
# Captures du jalon JOH9 (Mont Argenté, Route 28, épilogue ; `docs/tech/jalon-joh9.md` T11, dossier
# joh-10 §14) : sentier, relais devant la grotte, lac et rochers du 1F, noir et Flash du 2F, rival du
# 2F, sommet (Dante, Giovanni, Cenere, rival), Route 28 et son poste, porte neuve de la Route 22,
# labo de l'épilogue, sommet vide. 2340 × 1080, Movie Maker (Mac), `tools/capture_pewter.gd --boot`.
#   tools/capture_joh9.sh [dossier [filtre]]   (défaut : build/captures/joh9, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh9}"
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
	"sentier_entree|60|${S}johto_mt_silver --cell=2,41 --facing=right"
	"sentier_centre|60|${S}johto_mt_silver --cell=6,13 --facing=up"
	"sentier_hugo|60|${S}johto_mt_silver --cell=12,27 --facing=up"
	"exterieur_esplanade|60|${S}johto_mt_silver_outside --cell=19,17 --facing=up"
	"relais_brace|200|${S}johto_mt_silver_outside --cell=19,15 --hold=up --mash=40"
	"relais_rival|700|${S}johto_mt_silver_outside --cell=19,15 --hold=up --mash=40"
	"relais_entree|1400|${S}johto_mt_silver_outside --cell=19,15 --hold=up --mash=25"
	"grotte_1f_entree|60|${S}johto_mt_silver_1f"
	"grotte_1f_lac|60|${S}johto_mt_silver_1f --cell=15,18 --facing=up"
	"grotte_1f_rochers|60|${S}johto_mt_silver_1f --cell=12,9 --facing=up"
	"grotte_2f_flash|150|${S}johto_mt_silver_2f"
	"grotte_2f_rival|500|${S}johto_mt_silver_2f --cell=15,11 --hold=left --mash=40"
	"grotte_2f_soin|900|${S}johto_mt_silver_2f --cell=15,11 --hold=left --mash=30"
	"sommet_arrivee|200|${S}johto_mt_silver_summit --hold=down --mash=50"
	"sommet_dante|700|${S}johto_mt_silver_summit --hold=down --mash=40"
	"sommet_retour_rival|300|${S}johto_mt_silver_rival --hold=down --mash=40"
	"route_28_est|200|${S}johto_route_28 --cell=1,23 --hold=left"
	"poste_a47|300|${S}johto_route_28_gate --hold=down --mash=12"
	"poste_kanto|500|${S}johto_route_28_gate --hold=down --mash=20"
	"route_22_porte|60|${S}johto_kanto_gate"
	"poste_a48|300|${S}johto_kanto_gate --hold=left --mash=12"
	"epilogue_labo|500|${S}johto_epilogue --cell=24,23 --hold=up --mash=20"
	"epilogue_orme|1100|${S}johto_epilogue --cell=24,23 --hold=up --mash=48"
	"sommet_vide|60|${S}johto_after_chapter --cell=7,12 --facing=down"
	"celebi_autel|500|${S}johto_celebi --cell=23,12 --facing=up --mash=40"
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
