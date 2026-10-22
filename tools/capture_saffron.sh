#!/usr/bin/env bash
# Captures de Safrania, de ses intérieurs et des quatre postes (jalon 26 T6 ; modèle
# `capture_celadon.sh`),
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, WorldLighting + profil de la carte) :
#   tools/capture_saffron.sh [dossier [filtre]]   (défaut : build/captures/jalon26_t6, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon26_t6}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

CITY="--map=saffron_city"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"ville_ensemble|20|$CITY --aim=30,25 --zoom=0.2 --noplayer"
	"ville_poste_est|40|$CITY --spawn=from_gate_r8 --facing=left"
	"ville_sylphe|40|$CITY --cell=29,31 --facing=up"
	"ville_arene_dojo|40|$CITY --cell=45,11 --facing=up"
	"ville_centre|40|$CITY --spawn=from_center --facing=down"
	"ville_poste_nord|40|$CITY --spawn=from_gate_r5 --facing=down"
	"ville_poste_sud|40|$CITY --spawn=from_gate_r6 --facing=up"
	"ville_poste_ouest|40|$CITY --spawn=from_gate_r7 --facing=right"
	"centre|40|--map=saffron_center --spawn=entrance --facing=up"
	"boutique|40|--map=saffron_mart --spawn=entrance --facing=up"
	"maison_psy|40|--map=saffron_psychic_house --spawn=entrance --facing=up"
	"copieur_rdc|40|--map=saffron_copycat_house_1f --spawn=entrance --facing=up"
	"copieur_etage|40|--map=saffron_copycat_house_2f --spawn=from_1f --facing=down"
	"poste_r8|40|--map=route_8_gate --spawn=north_door --facing=up"
	"route_6_poste|40|--map=route_6 --cell=36,10 --facing=up"
	"perf_ville|300|$CITY --cell=30,31 --facing=left --perf"
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
