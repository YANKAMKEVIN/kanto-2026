#!/usr/bin/env bash
# Captures du Casino, du repaire Rocket (B1F à B4F, dalles de B2F et B3F) et de la cabine d'ascenseur
# (jalon 20 T20 ; modèle `capture_celadon.sh`),
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, WorldLighting + profil de la carte) :
#   tools/capture_repaire.sh [dossier [filtre]]   (défaut : build/captures/jalon20_t20, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon20_t20}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_pewter.gd
SHOTS=(
	"casino_entree|40|--map=celadon_game_corner --spawn=entrance --facing=up"
	"casino_ensemble|20|--map=celadon_game_corner --aim=10,9 --zoom=0.5 --noplayer"
	"casino_coursive|40|--map=celadon_game_corner --cell=16,5 --facing=right"
	"casino_allee|40|--map=celadon_game_corner --cell=3,9 --facing=left"
	"b1f_arrivee|40|--map=rocket_hideout_b1f --spawn=from_casino --facing=down"
	"b1f_ensemble|20|--map=rocket_hideout_b1f --aim=15,14 --zoom=0.36 --noplayer"
	"b1f_ascenseur|40|--map=rocket_hideout_b1f --spawn=from_elevator --facing=up"
	"b2f_ensemble|20|--map=rocket_hideout_b2f --aim=15,14 --zoom=0.36 --noplayer"
	"b2f_dalles|40|--map=rocket_hideout_b2f --cell=8,9 --facing=left"
	"b2f_arrivee_nord|40|--map=rocket_hideout_b2f --spawn=from_b1f_north --facing=down"
	"b3f_dalles|40|--map=rocket_hideout_b3f --cell=13,11 --facing=right"
	"b4f_ensemble|20|--map=rocket_hideout_b4f --aim=15,12 --zoom=0.36 --noplayer"
	"b4f_ouest|40|--map=rocket_hideout_b4f --spawn=from_b3f --facing=down"
	"b4f_est|40|--map=rocket_hideout_b4f --spawn=from_elevator --facing=up"
	"b4f_porte|40|--map=rocket_hideout_b4f --cell=24,13 --facing=up"
	"cabine|40|--map=rocket_hideout_elevator --spawn=entrance_w --facing=down"
	"perf_b2f|300|--map=rocket_hideout_b2f --cell=8,9 --facing=left --perf"
	"perf_casino|300|--map=celadon_game_corner --cell=9,12 --facing=up --perf"
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
