#!/usr/bin/env bash
# Garde-fou : aucun test ne mesure de durée en temps réel (résultat qui dépend de la charge du Mac).
# Usage : tools/check_test_timing.sh [dossier]  (défaut : tests). Appelé par tools/test.sh.
#
# Refusé dans les tests :
#   - get_process_delta_time() / get_physics_process_delta_time() : somme de delta réels ;
#   - Time.get_ticks_msec() / get_ticks_usec() hors d'une ligne « deadline » (délai de garde).
# À la place : TweenClock, FrameSim, AnimationPlayer en mode manuel (skill godot-conventions,
# « Tests et temps »). Exception assumée : finir la ligne par « # temps réel : <raison> ».
set -euo pipefail
cd "$(dirname "$0")/.."
DIR="${1:-tests}"

violations=$(grep -rnE --include='*.gd' \
		'get_(physics_)?process_delta_time\(|Time\.get_ticks_(msec|usec)\(' "$DIR" \
	| grep -vE 'Time\.get_ticks_(msec|usec)\(.*deadline|deadline.*Time\.get_ticks_(msec|usec)\(' \
	| grep -vE '# temps réel : .+' || true)

if [ -n "$violations" ]; then
	echo "Mesure de temps réel dans les tests (fragile sous charge) :" >&2
	echo "$violations" >&2
	echo >&2
	echo "Mesurer en temps simulé : tests/helpers/tween_clock.gd (tweens)," >&2
	echo "tests/helpers/frame_sim.gd (directeur, joueur, PNJ), AnimationPlayer en mode manuel." >&2
	echo "Voir le skill godot-conventions, section « Tests et temps ». Exception assumée :" >&2
	echo "finir la ligne par « # temps réel : <raison> »." >&2
	exit 1
fi
echo "Temps des tests : OK (aucune mesure en temps réel)."
