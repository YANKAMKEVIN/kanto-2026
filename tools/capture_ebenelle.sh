#!/usr/bin/env bash
# Captures de la peinture d'Ébènelle (`blackthorn_city` et ses intérieurs ; `build_joh_ambiance.gd`),
# de jour et de nuit, plus la vue d'ensemble `vue` (caméra libre, à comparer à la vue générale).
# 2340 × 1080, Movie Maker (Mac, pas en headless), par `tools/capture_pewter.gd` en mode `--boot`.
#   tools/capture_ebenelle.sh [dossier [filtre]]   (défaut : build/captures/ebenelle, tout)
# Départs `_capeb_*` écrits dans `tools/debug_start/` le temps des captures, retirés à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/ebenelle}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f tools/debug_start/_capeb_*.json; rm -rf "$TMP"; }
trap cleanup EXIT

python3 - <<'PY'
import json
STARTS = {"ville": ("blackthorn_city", "from_dragon"), "aieule": ("blackthorn_elder_house", "entrance"),
	"maison": ("blackthorn_house_1", "entrance"), "centre": ("blackthorn_center", "entrance")}
for name, (map_id, spawn) in STARTS.items():
	for period in ("day", "night"):
		start = json.load(open("tools/debug_start/johto_blackthorn.json"))
		start.update({"map": map_id, "spawn": spawn, "period": period})
		json.dump(start, open(f"tools/debug_start/_capeb_{name}_{period}.json", "w"),
			ensure_ascii=False, indent=1)
PY

day() { echo "--boot --start=_capeb_$1_day"; }
night() { echo "--boot --start=_capeb_$1_night"; }
SHOTS=(
	"vue|30|--map=blackthorn_city --noplayer --aim=16,15 --zoom=0.36"
	"jour_aire|50|$(day ville) --cell=15,24 --facing=up"
	"jour_rue|50|$(day ville) --cell=11,14 --facing=up"
	"jour_aieule|50|$(day ville) --cell=15,13 --facing=up"
	"jour_centre|50|$(day ville) --cell=22,14 --facing=up"
	"jour_antre|50|$(day ville) --cell=25,14 --facing=right"
	"jour_herbes|50|$(day ville) --cell=18,18 --facing=right"
	"nuit_aire|50|$(night ville) --cell=15,24 --facing=up"
	"nuit_aieule|50|$(night ville) --cell=15,13 --facing=up"
	"nuit_centre|50|$(night ville) --cell=22,14 --facing=up"
	"nuit_antre|50|$(night ville) --cell=25,14 --facing=right"
	"int_aieule|50|$(day aieule) --facing=up"
	"int_maison|50|$(day maison) --facing=up"
	"int_centre|50|$(day centre) --facing=up"
	"int_aieule_nuit|50|$(night aieule) --facing=up"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --resolution 2340x1080 --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" | grep -v "_on_focus_change" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
