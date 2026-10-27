#!/usr/bin/env bash
# Attend le résultat de la CI GitHub (« Godot tests », 8 lots en parallèle) pour un commit déjà poussé.
# Remplace la suite complète du Mac avant une fusion tant que le dépôt est public (décision de Kevin,
# 2026-10-26) : pousser la branche, puis lancer ce script. Code de sortie 0 seulement si la CI est verte.
# Usage : tools/ci_wait.sh [commit]   (défaut : HEAD)
# Si la CI ne s'est pas déclenchée (commit qui ne touche que docs/ ou *.md), le script le dit et sort en 2.
set -euo pipefail

SHA="$(git rev-parse "${1:-HEAD}")"
WORKFLOW="godot-tests.yml"

if ! git branch -r --contains "$SHA" | grep -q .; then
	echo "Le commit $SHA n'est sur aucune branche distante : pousse-le d'abord." >&2
	exit 1
fi

RUN_ID=""
for _ in $(seq 1 30); do
	RUN_ID="$(gh run list --workflow "$WORKFLOW" --commit "$SHA" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"
	[ -n "$RUN_ID" ] && break
	sleep 10
done

if [ -z "$RUN_ID" ]; then
	echo "Aucune CI pour $SHA après 5 min (commit de documentation seule ?). Lance la suite du Mac ou :" >&2
	echo "  gh workflow run $WORKFLOW --ref <branche>" >&2
	exit 2
fi

echo "CI $RUN_ID pour $SHA : https://github.com/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/actions/runs/$RUN_ID"
gh run watch "$RUN_ID" --interval 30 --exit-status >/dev/null && STATUS=0 || STATUS=$?
gh run view "$RUN_ID" --json conclusion,jobs --jq '"Conclusion : " + .conclusion, (.jobs[] | "  " + .name + " : " + (.conclusion // .status))'
exit "$STATUS"
