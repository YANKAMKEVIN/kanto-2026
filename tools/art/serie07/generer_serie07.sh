#!/bin/bash
# Série 07 (Jadielle agrandie, jalon-07.md §15.20) : régénère une ou plusieurs images avec
# Codex (tools/art/generer.sh, abonnement ChatGPT, lumière neutre), 5 en parallèle.
#   tools/art/serie07/generer_serie07.sh WORLD_PROP_PORTAIL_01_NE_r1 [...]
# Sans argument : toute la série (identifiants = noms des prompts de tools/art/serie07/prompts).
# Les références recadrées de la vue générale sont dans tools/art/serie07/references ; les
# ancres de style et les autres références (VALIDE_*, WORLD_*_r1, REF_CLOTURE…) dans build/art/
# du Mac de Kevin. Les images produites arrivent dans build/art/<identifiant>.png, puis :
#   python3 tools/art/preparer.py  (manifeste à jour) ; godot … -s res://tools/build_painted_props.gd
set -u
cd "$(dirname "$0")/../../.."
A=build/art
R=tools/art/serie07/references
P=tools/art/serie07/prompts
STYLE="$A/VALIDE_CENTRE.png $A/WORLD_TREE_A_01_GH_r3_etal.png"
refs() {
	case "$1" in
		WORLD_RELIEF_MURET_01) echo "$R/REF_MURET_ESCALIER.png $A/WORLD_RELIEF_FALAISE_01_NE_r1.png" ;;
		WORLD_RELIEF_ESCALIER_VILLE_01) echo "$R/REF_ESCALIER_SUD.png $R/REF_MURET_ESCALIER.png $A/WORLD_RELIEF_FALAISE_01_NE_r1.png" ;;
		WORLD_PROP_POTAGER_01|WORLD_PROP_PLATEBANDE_01) echo "$R/REF_POTAGER.png $R/REF_JARDIN_EST.png" ;;
		WORLD_PROP_HAIE_V_01) echo "$A/REF_HAIE_MURET.png $A/WORLD_PROP_HAIE_01_NE_r1.png" ;;
		WORLD_PROP_CLOTURE_V_01) echo "$A/REF_CLOTURE.png $A/WORLD_PROP_CLOTURE_01_NE_r1.png" ;;
		WORLD_PROP_PORTAIL_01|WORLD_PROP_BUISSON_*) echo "$R/REF_JARDIN_EST.png $R/REF_POTAGER.png $A/WORLD_PROP_CLOTURE_01_NE_r1.png" ;;
		WORLD_PROP_BALUSTRADE_01) echo "$R/REF_MURET_ESCALIER.png $A/WORLD_RELIEF_MURET_01_NE_r1.png $A/WORLD_RELIEF_ESCALIER_VILLE_01_NE_r1.png" ;;
		WORLD_BLDG_MAISON_*) echo "$A/REF_MAISON_rouge.png $A/REF_MAISON_bleue.png $A/WORLD_BLDG_MAISON_A_01_NE_r1.png $A/WORLD_BLDG_MAISON_B_01_NE_r1.png" ;;
		WORLD_TREE_FRUITIER_01) echo "$R/REF_JARDIN_EST.png" ;;
		*) echo "$R/REF_JARDIN_EST.png $A/WORLD_PROP_BANC_01_GH_r1.png" ;;
	esac
}
IDS=("$@")
if [ ${#IDS[@]} -eq 0 ]; then
	for F in "$P"/WORLD_*.txt; do IDS+=("$(basename "$F" .txt)"); done
fi
mkdir -p "$A"
N=0
for ID in "${IDS[@]}"; do
	BASE="${ID%_NE_r*}"
	( tools/art/generer.sh "$ID" "$P/$ID.txt" $(refs "$BASE") $STYLE > "$A/log_$ID.txt" 2>&1
	  echo "$ID exit $?" ) &
	N=$((N + 1))
	if [ $((N % 5)) -eq 0 ]; then wait; fi
done
wait
