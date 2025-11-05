#!/usr/bin/env bash
# run.sh - simple build+test helper for BoltDBG
# Usage:
#   ./run.sh                # default: Debug build, ASAN off, run tests
#   BUILD_TYPE=Release ./run.sh
#   ASAN=ON ./run.sh
#   CLEAN=1 ./run.sh       # remove build/ then do everything
#   INSTALL=1 ./run.sh     # run `cmake --install` after build
#
set -euo pipefail

# Defaults (can be overridden by environment variables)
: "${BUILD_TYPE:=Debug}"
: "${ASAN:=OFF}"         # ON or OFF
: "${CLEAN:=0}"          # 1 to remove build dir first
: "${JOBS:=auto}"        # number of parallel build jobs; auto = detect
: "${INSTALL:=0}"        # 1 to install after build
: "${CMAKE_EXTRA_ARGS:=""}" # any extra args for cmake

# Detect number of processors
if [ "$JOBS" = "auto" ]; then
    if command -v nproc >/dev/null 2>&1; then
        JOBS=$(nproc)
    elif [ "$(uname)" = "Darwin" ] && command -v sysctl >/dev/null 2>&1; then
        JOBS=$(sysctl -n hw.ncpu)
    else
        JOBS=2
    fi
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"

echo "=== BoltDBG build helper ==="
echo "Root:        ${ROOT_DIR}"
echo "Build dir:   ${BUILD_DIR}"
echo "Build type:  ${BUILD_TYPE}"
echo "ASAN:        ${ASAN}"
echo "Jobs:        ${JOBS}"
echo "Clean:       ${CLEAN}"
echo "Install:     ${INSTALL}"
echo "Extra args:  ${CMAKE_EXTRA_ARGS}"
echo

# Step 0: optionally clean
if [ "${CLEAN}" = "1" ]; then
    echo "[1/6] Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
fi

# Step 1: init/update submodules (if any)
if [ -f .gitmodules ]; then
    echo "[2/6] Initializing/updating git submodules..."
    git submodule sync --recursive || true
    git submodule update --init --recursive --depth 1 || true
else
    echo "[2/6] No .gitmodules found — skipping submodule init."
fi

# Step 2: create build dir
echo "[3/6] Preparing build directory..."
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Step 3: run cmake configure
echo "[4/6] Configuring with CMake..."
cmake \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DBOLTDBG_ENABLE_ASAN="${ASAN}" \
    ${CMAKE_EXTRA_ARGS} \
    "${ROOT_DIR}"

# Step 4: build
echo "[5/6] Building (parallel jobs: ${JOBS})..."
# Use cmake --build for multi-config generators as well
cmake --build . -- -j"${JOBS}"

# Step 5: run tests (if enabled in CMake)
if cmake --build . --target help | grep -q "RUN_TESTS" || true; then
    echo "[6/6] Running ctest (if any tests present)..."
    # Prefer ctest binary if available
    if command -v ctest >/dev/null 2>&1; then
        ctest --output-on-failure -j "${JOBS}" || {
            echo "Some tests failed."
            # do not exit immediately so user sees build artifacts; still return non-zero
            exit 1
        }
    else
        echo "ctest not found; skipping tests."
    fi
else
    echo "[6/6] No tests target detected; skipping ctest."
fi

# Optional install
if [ "${INSTALL}" = "1" ]; then
    echo "[+] Installing to CMAKE_INSTALL_PREFIX..."
    cmake --install . --prefix "${CMAKE_INSTALL_PREFIX:-/usr/local}"
fi

echo "=== Build finished successfully ==="
