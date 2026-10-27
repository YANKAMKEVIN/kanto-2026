#!/usr/bin/env bash
# Captures de la Sylphe SARL (jalon 26 T7 ; modèle `capture_repaire.sh`) : étages, téléporteurs,
# portes électroniques fermées et cabine d'ascenseur,
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, WorldLighting + profil de la carte) :
#   tools/capture_sylphe.sh [dossier [filtre]]   (défaut : build/captures/jalon26_t7, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon26_t7}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_pewter.gd
SHOTS=(
	"1f_entree|40|--map=silph_co_1f --spawn=from_city --facing=up"
	"1f_ensemble|20|--map=silph_co_1f --aim=15,9 --zoom=0.36 --noplayer"
	"5f_ensemble|20|--map=silph_co_5f --aim=15,9 --zoom=0.36 --noplayer"
	"5f_ascenseur|40|--map=silph_co_5f --spawn=from_elevator --facing=down"
	"5f_teleporteur|40|--map=silph_co_5f --cell=10,5 --facing=right"
	"5f_porte|40|--map=silph_co_5f --cell=8,12 --facing=left"
	"11f_ensemble|20|--map=silph_co_11f --aim=9,9 --zoom=0.5 --noplayer"
	"cabine|40|--map=silph_co_elevator --spawn=entrance --facing=up"
	"perf_5f|300|--map=silph_co_5f --cell=20,8 --facing=up --perf"
)
: > "$OUT/perf.txt"
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	if [[ "$name" == perf_* ]]; then
		# shellcheck disable=SC2086
		godot --path . --quit-after "$frames" -s res://tools/capture_pewter.gd -- $opts \
			> "$TMP/log.txt" 2>&1 || true
	else
		# shellcheck disable=SC2086
		godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
			-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	fi
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	if grep -q "\[perf\]" "$TMP/log.txt"; then
		{ echo "== $name"; grep "\[perf\]" "$TMP/log.txt"; } >> "$OUT/perf.txt"
	fi
	if [[ "$name" == perf_* ]]; then
		echo "$OUT/perf.txt ($name)"
		continue
	fi
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
