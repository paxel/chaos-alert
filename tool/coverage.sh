#!/usr/bin/env bash
# Coverage floors: runs the tests with coverage, writes the LCOV files
# SonarQube Cloud imports (sonar-project.properties), and checks each
# group's line coverage against tool/coverage-floors.txt with
# tool/coverage_floor.py. Below a floor fails; a floor that rose is raised
# in that file, for the user to commit.
#
#   tool/coverage.sh [dart-core] [flutter-app]
#
# No group named runs both. A failing test stops the script; a group
# below its floor does not stop the other, so every LCOV file is written.
#
#   dart-core    dart test --coverage, format_coverage to LCOV with paths
#                from the repository root (packages/chaos_core/lib/…)
#   flutter-app  flutter test --coverage, lib/ without the generated
#                lib/l10n/app_localizations*.dart
#
# Output: packages/chaos_core/coverage/lcov.info and coverage/lcov.info.
#
# COVERAGE_JOBS=N limits the test parallelism (for a shared machine);
# unset leaves each tool's default.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

groups=("$@")
[ ${#groups[@]} -gt 0 ] || groups=(dart-core flutter-app)

jobs=${COVERAGE_JOBS:-}
failed=()

floor() {
  python3 tool/coverage_floor.py "$1" "$2" || failed+=("$1")
}

for group in "${groups[@]}"; do
  case $group in
    dart-core)
      (
        cd packages/chaos_core
        rm -rf coverage
        dart test ${jobs:+-j "$jobs"} --coverage=coverage
        dart run coverage:format_coverage --lcov \
          --in=coverage --out=coverage/lcov.info \
          --report-on=lib --base-directory=../..
      )
      floor dart-core packages/chaos_core/coverage/lcov.info
      ;;
    flutter-app)
      rm -rf coverage
      flutter test ${jobs:+--concurrency="$jobs"} --coverage
      floor flutter-app coverage/lcov.info
      ;;
    *)
      echo "unknown group: $group" >&2
      exit 2
      ;;
  esac
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "below its coverage floor: ${failed[*]}" >&2
  exit 1
fi
