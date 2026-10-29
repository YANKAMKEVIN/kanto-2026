#!/usr/bin/env bash
# Chantier JR : génère les assets de la joueuse et de la rivale (Codex, 4 en parallèle).
# Ancres attendues dans build/art/ancres/ (gabarits du héros et du rival, planches JR validées).
# Usage : tools/art/joueuse_rivale/generer_jr.sh [IDENT ...]   (sans argument : tous)
# Sortie : build/art/JR_<IDENT>_r1.png
set -uo pipefail
cd "$(dirname "$0")/../../.."
A=build/art/ancres
python3 tools/art/joueuse_rivale/prompts_jr.py > build/art/jr_liste.txt
while read -r ID GABARIT PLANCHE; do
	[[ $# -gt 0 && ! " $* " =~ " ${ID#JR_} " ]] && continue
	echo "$ID $GABARIT $PLANCHE"
done < build/art/jr_liste.txt | xargs -P 4 -L 1 bash -c \
	'tools/art/generer.sh "$0_r1" "tools/art/joueuse_rivale/prompts/$0.txt" "'$A'/$1.png" "'$A'/$2.png" || echo "ÉCHEC $0"'
