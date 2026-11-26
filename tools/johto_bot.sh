#!/usr/bin/env bash
# Bot de parcours de Johto (tests/parcours/johto_bot.gd) : une partie entière, de la lettre d'Orme au
# retour à Bourg Palette, jouée seule sur la vraie scène Boot (1 à 2 h). Hors de la suite complète.
# Usage : tools/johto_bot.sh [départ de débogage] [journal]
#   départ : nom d'un fichier de tools/debug_start/ sans « .json » (défaut : johto_letter) ;
#   journal : fichier de sortie (défaut : build/johto_bot.log).
# Le journal finit par les actions jouées, les culs-de-sac et, en cas de blocage, le diagnostic.
set -euo pipefail
cd "$(dirname "$0")/.."
START="${1:-}"
LOG="${2:-build/johto_bot.log}"
mkdir -p "$(dirname "$LOG")"
GODOT="${GODOT:-godot}"
status=0
JOHTO_BOT_START="$START" "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig= \
	-gtest=res://tests/parcours/johto_bot_run.gd -gexit -glog=1 > "$LOG" 2>&1 || status=$?
grep -E "Bot de Johto|CUL-DE-SAC|Blocage|SCRIPT ERROR" "$LOG" || true
echo "Journal complet : $LOG (code $status)"
exit "$status"
