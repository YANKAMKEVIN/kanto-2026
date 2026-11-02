#!/usr/bin/env bash
# Itération 5 : lance les générations Codex du lot en parallèle (journaux dans build/art/entree/).
cd "$(dirname "$0")/../../.."
for ID in ED_DECOR_ARENE_V4 ED_DECOR_ROUTE3_LANCER ED_DOS_M1 ED_DOS_M2 ED_DOS_VS ED_HUGO_LANCER_V3 ED_BANDEROLE_BLEUE_V2; do
	python3 tools/art/entree_dresseurs.py generer "$ID" 1 > "build/art/entree/log5_$ID.txt" 2>&1 &
done
wait
grep -h -v Reading build/art/entree/log5_*.txt
