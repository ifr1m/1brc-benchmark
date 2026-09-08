#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "prerequisite check failed: $*" >&2
  exit 2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required"
}

require_command java
require_command javac
require_command python3
require_command dd

if command -v shasum >/dev/null 2>&1; then
  :
elif command -v sha256sum >/dev/null 2>&1; then
  :
else
  fail "shasum or sha256sum is required"
fi

JAVA_VERSION="$(java -version 2>&1 | awk -F'"' '/version/ { print $2; exit }')"
JAVA_MAJOR="${JAVA_VERSION%%.*}"
if [[ "$JAVA_MAJOR" == "1" ]]; then
  JAVA_MAJOR="$(printf '%s' "$JAVA_VERSION" | cut -d. -f2)"
fi
[[ "$JAVA_MAJOR" =~ ^[0-9]+$ ]] || fail "could not determine Java version"
(( JAVA_MAJOR >= 25 )) || fail "Java 25 or newer is required (found $JAVA_VERSION)"

PYTHON_VERSION="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
PYTHON_MAJOR="${PYTHON_VERSION%%.*}"
PYTHON_MINOR="${PYTHON_VERSION#*.}"
(( PYTHON_MAJOR > 3 || (PYTHON_MAJOR == 3 && PYTHON_MINOR >= 9) )) \
  || fail "Python 3.9 or newer is required (found $PYTHON_VERSION)"

case "${RUN_DISK_BASELINE:-1}" in
  0|1) ;;
  *) fail "RUN_DISK_BASELINE must be 0 or 1" ;;
esac

echo "Java $JAVA_VERSION"
echo "Python $PYTHON_VERSION"
