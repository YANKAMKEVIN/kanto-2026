#!/usr/bin/env bash
# Lance les tests GUT en headless.
#
# Usage :
#   tools/test.sh                    suite complète (avant une fusion) ; verrou partagé du Mac
#   tools/test.sh res://tests/unit   un dossier
#   tools/test.sh -f surf,safari     les fichiers de test dont le nom contient « surf » ou « safari »
#   tools/test.sh --changed [base]   les tests liés aux fichiers modifiés depuis base (défaut : origin/main),
#                                    modifications non commitées comprises
#
# Verrou : au plus KANTO_TEST_SLOTS suites complètes en même temps sur le Mac (défaut : 2), tous
# worktrees et toutes sessions confondus. Les lancements ciblés (-f, --changed, dossier) ne prennent
# pas de place. Deux suites rapides valent mieux que huit qui se freinent
# (docs/design/strategie-acceleration.md, levier 3).
#
# Les lancements ciblés servent pendant une tâche ; la suite complète reste obligatoire avant une fusion.
set -euo pipefail
cd "$(dirname "$0")/.."

MODE=dir
DIR="res://tests"
PATTERNS=""
BASE="origin/main"
case "${1:-}" in
	-f)
		MODE=files
		PATTERNS="${2:?Usage : tools/test.sh -f motif[,motif…]}"
		;;
	--changed)
		MODE=changed
		BASE="${2:-origin/main}"
		;;
	-h|--help)
		sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
		exit 0
		;;
	"") ;;
	*) DIR="$1" ;;
esac

LOG="$(mktemp -t kanto_gut.XXXXXX)"
JUNIT="$(mktemp -t kanto_junit.XXXXXX)"
SLOT=""
cleanup() {
	rm -f "$LOG" "$JUNIT"
	if [ -n "$SLOT" ]; then rm -rf "$SLOT"; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- Choix des scripts de test ------------------------------------------------------------------

# Imprime les chemins res:// des tests liés aux fichiers modifiés depuis $BASE,
# ou « ALL » si un fichier commun à tous les tests a changé.
changed_tests() {
	local base_commit files f name cls
	base_commit="$(git merge-base "$BASE" HEAD)"
	files="$( { git diff --name-only "$base_commit"; git ls-files --others --exclude-standard; } | sort -u)"
	if [ -z "$files" ]; then return 0; fi
	if echo "$files" | grep -qE '^(tests/helpers/|tests/fixtures/|addons/|project\.godot$|\.gutconfig\.json$|game/autoload/)'; then
		echo "ALL"
		return 0
	fi
	{
		# Tests modifiés eux-mêmes.
		echo "$files" | grep -E '^tests/.*test_[^/]*\.gd$' || true
		# Tests qui citent un fichier modifié (par son nom de fichier) ou sa class_name.
		echo "$files" | grep -vE '^tests/|^docs/|\.md$|\.uid$|\.import$' | while read -r f; do
			[ -f "$f" ] || continue
			name="$(basename "$f")"
			grep -rlF --include='test_*.gd' -e "$name" tests || true
			if [[ "$f" == *.gd ]]; then
				cls="$(sed -nE 's/^class_name[[:space:]]+([A-Za-z0-9_]+).*/\1/p' "$f" | head -1)"
				if [ -n "$cls" ]; then grep -rlw --include='test_*.gd' -e "$cls" tests || true; fi
			fi
		done
	} | sort -u | sed 's|^|res://|'
}

# Imprime les chemins res:// des tests dont le nom de fichier contient l'un des motifs.
pattern_tests() {
	local p pats
	IFS=',' read -ra pats <<< "$PATTERNS"
	for p in "${pats[@]}"; do
		find tests -name "test_*${p}*.gd"
	done | sort -u | sed 's|^|res://|'
}

GUT_TARGET=()
case "$MODE" in
	dir)
		GUT_TARGET=(-gdir="$DIR" -ginclude_subdirs)
		;;
	files|changed)
		if [ "$MODE" = files ]; then selected="$(pattern_tests)"; else selected="$(changed_tests)"; fi
		if [ "$selected" = "ALL" ]; then
			echo "Un fichier commun a changé (helpers, fixtures, autoload, addons, project.godot) : suite complète."
			MODE=dir
			GUT_TARGET=(-gdir="res://tests" -ginclude_subdirs)
		elif [ -z "$selected" ]; then
			echo "Aucun test lié trouvé. Rien à lancer ; la suite complète reste due avant la fusion."
			exit 0
		else
			echo "Tests ciblés : $(echo "$selected" | wc -l | tr -d ' ') script(s)."
			echo "$selected" | sed 's|^|  |'
			# -gconfig= : sans quoi .gutconfig.json ajouterait tout res://tests.
			GUT_TARGET=(-gconfig= -gtest="$(echo "$selected" | paste -sd, -)")
		fi
		;;
esac

# --- Verrou des suites complètes ----------------------------------------------------------------

acquire_slot() {
	local root="/tmp/kanto2026-test-slots" max="${KANTO_TEST_SLOTS:-2}" i pid waited=0
	if ! mkdir -p "$root" 2>/dev/null; then
		echo "Verrou indisponible ($root) : suite lancée sans verrou." >&2
		return 0
	fi
	while true; do
		for ((i = 1; i <= max; i++)); do
			if mkdir "$root/slot-$i" 2>/dev/null; then
				SLOT="$root/slot-$i"
				echo "$$ $(pwd)" > "$SLOT/owner"
				return 0
			fi
			# Place laissée par un processus mort : on la libère.
			pid="$(cut -d' ' -f1 "$root/slot-$i/owner" 2>/dev/null || true)"
			if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
				rm -rf "$root/slot-$i"
				if mkdir "$root/slot-$i" 2>/dev/null; then
					SLOT="$root/slot-$i"
					echo "$$ $(pwd)" > "$SLOT/owner"
					return 0
				fi
			fi
		done
		if (( waited % 60 == 0 )); then
			echo "Verrou : $max suites complètes tournent déjà sur le Mac, attente d'une place…"
			cat "$root"/slot-*/owner 2>/dev/null | sed 's/^/  occupée par PID /' || true
		fi
		sleep 10
		waited=$((waited + 10))
	done
}

FULL_SUITE=false
if [ "$MODE" = dir ] && [ "$(echo "${GUT_TARGET[0]}" | sed 's/^-gdir=//')" = "res://tests" ]; then
	FULL_SUITE=true
	acquire_slot
fi

# --- Lancement ------------------------------------------------------------------------------------

# Garde-fou : aucune mesure de durée en temps réel dans les tests (voir le script).
tools/check_test_timing.sh tests
godot --headless --path . --import >/dev/null 2>&1 || true
status=0
godot --headless --path . -s addons/gut/gut_cmdln.gd "${GUT_TARGET[@]}" -gexit -glog=1 \
	-gjunit_xml_file="$JUNIT" \
	2>&1 | tee "$LOG" || status=$?
# Garde-fou : GUT ignore sans échec un fichier de test qui ne se charge pas (erreur de
# syntaxe) et finit quand même « All tests passed ». On échoue dans ce cas.
if grep -E "Parse Error|Ignoring script|Failed to load script|SCRIPT ERROR" "$LOG" >/dev/null; then
	echo "ÉCHEC : un script de test ne s'est pas chargé (voir les lignes ci-dessous)." >&2
	grep -E "Parse Error|Ignoring script|Failed to load script|SCRIPT ERROR" "$LOG" | head -20 >&2
	exit 1
fi

# Les 10 scripts les plus lents (pour savoir quoi alléger), seulement pour la suite complète.
if $FULL_SUITE && [ -s "$JUNIT" ]; then
	echo
	echo "Scripts les plus lents (secondes) :"
	grep -oE '<testsuite name="[^"]*"[^>]*time="[0-9.]+"' "$JUNIT" \
		| sed -E 's/.*name="([^"]*)".*time="([0-9.]+)".*/\2 \1/' \
		| sort -rn | head -10 | awk '{ printf "  %7.1f  %s\n", $1, $2 }' || true
fi
exit "$status"
