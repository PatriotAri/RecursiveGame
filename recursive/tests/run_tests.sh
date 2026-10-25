#!/usr/bin/env bash
# Runs test scenes and exits non-zero if any fails.
#   tests/run_tests.sh              every headless test
#   tests/run_tests.sh smoke save   just these
#   tests/run_tests.sh onscreen     needs a display (xvfb-run locally or in CI)
#   tests/run_tests.sh perf_budget  physics-cost budget; PERF_CAP_MS sets the cap
# GODOT is the Godot 4.6 binary (default: godot on PATH). A test that never
# reaches finish() — a script error stops it — fails on TEST_TIMEOUT seconds.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
TIMEOUT="${TEST_TIMEOUT:-180}"
ALL=(menus attacks smoke projectile spells ai types sfx rounds world1 save
	load_flow campaign fixes qol armor layers repath menu_exit navbake)

tests=("$@")
[ ${#tests[@]} -eq 0 ] && tests=("${ALL[@]}")

# Builds .godot (class names, imported assets) on a fresh checkout.
timeout 600 "$GODOT" --headless --import >/dev/null 2>&1

failed=()
for t in "${tests[@]}"; do
	args=(--headless "res://tests/$t.tscn")
	case "$t" in
		onscreen) args=(--rendering-driver opengl3 "res://tests/$t.tscn") ;;
		perf_budget) args+=(-- "${PERF_CAP_MS:-100}") ;;
	esac
	out=$(timeout "$TIMEOUT" "$GODOT" "${args[@]}" 2>&1)
	code=$?
	echo "$out" | grep -E "^  (ok|FAIL) |^median| (PASS|FAIL)$|SCRIPT ERROR|Parse Error"
	if [ $code -ne 0 ]; then
		[ $code -eq 124 ] && why="timed out after ${TIMEOUT}s" || why="exit $code"
		failed+=("$t: $why")
		echo "--- $t: $why; last output:"
		echo "$out" | tail -n 25
	fi
done

echo
if [ ${#failed[@]} -gt 0 ]; then
	printf 'FAILED %s\n' "${failed[@]}"
	exit 1
fi
echo "all ${#tests[@]} passed"
