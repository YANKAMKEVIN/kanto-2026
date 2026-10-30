#!/usr/bin/env bash
# Chantier CO : génère les planches de chara design des costumes (Codex, 4 en parallèle).
# Ancres attendues dans build/art/ancres_co/ : heros_portrait, heros_sheet (main),
# joueuse_portrait, joueuse_sheet (branche du chantier JR).
# Usage : tools/art/costumes/generer_co.sh [BADGE ...]   (sans argument : tous) ; sortie build/art/CO_PLANCHE_<BADGE>_r1.png
set -uo pipefail
export REV="${REV:-r1}"
cd "$(dirname "$0")/../../.."
A=build/art/ancres_co
python3 tools/art/costumes/prompts_co.py | while read -r ID; do
	[[ $# -gt 0 && ! " $* " =~ " ${ID#CO_PLANCHE_} " ]] && continue
	echo "$ID"
done | xargs -P 4 -L 1 bash -c \
	'tools/art/generer.sh "$0_${REV:-r1}" "tools/art/costumes/prompts/$0.txt" '$A'/heros_portrait.png '$A'/heros_sheet.png '$A'/joueuse_portrait.png '$A'/joueuse_sheet.png || echo "ÉCHEC $0"'
