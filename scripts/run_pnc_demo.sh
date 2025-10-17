#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DEFAULT_PREFIX="$REPO_ROOT/build/dist"

show_usage() {
    cat <<'USAGE'
Usage: run_pnc_demo.sh [CONFIG]

Starts the Plug & Charge software-in-the-loop demo with the given EVerest
configuration file. If no configuration path is provided the script uses
config/config-sil-pnc-demo.yaml (or the copy under the installation prefix).

Environment variables:
  EVEREST_PREFIX      Override the install prefix that contains the EVerest
                      runtime (defaults to ./build/dist).
  EVEREST_CONFIG      Alternative way to point to a config file.
  EVEREST_EXTRA_ARGS  Extra arguments forwarded to the EVerest manager
                      binary (for example "--log-level debug").
  EVEREST_LOG_ROOT    Directory that should receive the combined stdout/stderr
                      log (defaults to logs/pnc-demo under the repository or
                      prefix).
USAGE
}

if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
    show_usage
    exit 0
fi

PREFIX=${EVEREST_PREFIX:-$DEFAULT_PREFIX}
DEFAULT_CONFIG="$REPO_ROOT/config/config-sil-pnc-demo.yaml"
if [[ ! -f "$DEFAULT_CONFIG" && -f "$PREFIX/config/config-sil-pnc-demo.yaml" ]]; then
    DEFAULT_CONFIG="$PREFIX/config/config-sil-pnc-demo.yaml"
fi
CONFIG_PATH=${1:-${EVEREST_CONFIG:-$DEFAULT_CONFIG}}
MANAGER_BIN="$PREFIX/bin/manager"

if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Error: could not find configuration file: $CONFIG_PATH" >&2
    exit 1
fi

if [[ ! -x "$MANAGER_BIN" ]]; then
    cat <<EOF >&2
Error: could not find the EVerest manager runtime at $MANAGER_BIN
Build and install everest-core first:
  mkdir -p build && cd build
  cmake ..
  make install
(Adjust the commands if you use Ninja or a different build directory.)
EOF
    exit 1
fi

DEFAULT_LOG_ROOT="$REPO_ROOT/logs/pnc-demo"
case "$CONFIG_PATH" in
    $PREFIX/*)
        DEFAULT_LOG_ROOT="$PREFIX/logs/pnc-demo"
        ;;
    *)
        ;;
esac
LOG_ROOT=${EVEREST_LOG_ROOT:-$DEFAULT_LOG_ROOT}
mkdir -p "$LOG_ROOT"
LOG_FILE="$LOG_ROOT/everest.log"

cat <<EOF
Starting the Plug & Charge demo …
  Prefix : $PREFIX
  Config : $CONFIG_PATH
  Logs   : $LOG_FILE

Press Ctrl+C to stop the simulator once you are done.
EOF

CMD=("$MANAGER_BIN" --prefix "$PREFIX" --conf "$CONFIG_PATH")
if [[ -n ${EVEREST_EXTRA_ARGS:-} ]]; then
    # shellcheck disable=SC2206
    EXTRA_ARGS=( ${EVEREST_EXTRA_ARGS} )
    CMD+=("${EXTRA_ARGS[@]}")
fi

# stream output to both stdout and the log file for convenience
if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL -eL "${CMD[@]}" | tee "$LOG_FILE"
else
    "${CMD[@]}" | tee "$LOG_FILE"
fi
exit ${PIPESTATUS[0]}
