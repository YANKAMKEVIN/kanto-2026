#!/usr/bin/env bash
# Chantier CO : génère les 22 sprites de chaque badge donné (Codex, 4 en parallèle), en relançant
# les refus du filtre jusqu'à épuisement des révisions (`relancer_co.sh`), badge après badge.
# Usage : tools/art/costumes/lot_co.sh "r1 r2 r3" BADGE [BADGE ...]
set -uo pipefail
cd "$(dirname "$0")/../../.."
REVS="$1"; shift
for BADGE in "$@"; do
	ASSETS=($(python3 tools/art/costumes/prompts_sprites_co.py "$BADGE" | cut -d' ' -f1 | sed "s/^CO_${BADGE}_//"))
	# Reprise : les poses déjà obtenues (une image CO_<BADGE>_<POSE>_r*.png existe) sont sautées.
	MANQUE=()
	for A in "${ASSETS[@]}"; do
		ls build/art/CO_${BADGE}_${A}_r*.png > /dev/null 2>&1 || MANQUE+=("$A")
	done
	[[ ${#MANQUE[@]} -eq 0 ]] && continue
	tools/art/costumes/relancer_co.sh "$BADGE" "$REVS" "${MANQUE[@]}" || exit $?
done
