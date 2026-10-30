#!/usr/bin/env bash
# Chantier CO : relance les images refusées par le filtre de Codex (refus au hasard à la sortie),
# révision après révision, jusqu'à ce qu'il n'en reste plus ou que les révisions soient épuisées.
# Les variables ADOUCIR et IDENTITE_<VERSION> sont transmises à `generer_sprites_co.sh`.
# Usage : tools/art/costumes/relancer_co.sh BADGE "r4 r5 r6" FILTRE [FILTRE ...]
# Sortie : une ligne « BADGE FILTRE rN » par image obtenue, puis « reste : … ». Quota de Codex
# épuisé : « QUOTA : try again at … », code de sortie 3 (le lot s'arrête).
set -uo pipefail
cd "$(dirname "$0")/../../.."
BADGE="$1"; REVS="$2"; shift 2
b=$(echo "$BADGE" | tr "[:upper:]" "[:lower:]")
RESTE=("$@")
for R in $REVS; do
	[[ ${#RESTE[@]} -eq 0 ]] && break
	REV=$R tools/art/costumes/generer_sprites_co.sh "$BADGE" "${RESTE[@]}" > "build/art/co_${b}_$R.log" 2>&1
	grep -E "^build/art/" "build/art/co_${b}_$R.log" | sed -E "s|build/art/CO_${BADGE}_(.*)_($R)\.png|$BADGE \1 \2|"
	if grep -q "usage limit" "build/art/co_${b}_$R.log"; then
		echo "QUOTA : $(grep -o 'try again at [^."]*' "build/art/co_${b}_$R.log" | tail -1)"
		RESTE=($(grep "ÉCHEC" "build/art/co_${b}_$R.log" | sed "s/ÉCHEC CO_${BADGE}_//"))
		echo "reste : ${RESTE[*]:-}"
		exit 3
	fi
	RESTE=($(grep "ÉCHEC" "build/art/co_${b}_$R.log" | sed "s/ÉCHEC CO_${BADGE}_//"))
done
echo "reste : ${RESTE[*]:-}"
