#!/usr/bin/env bash
# build.sh - Professional build script for BoltDBG (improved)
#
# Usage:
#   ./build.sh                          # Debug build (preset: debug)
#   ./build.sh --preset release         # Release build
#   ./build.sh --preset debug-asan      # Debug with ASAN
#   ./build.sh --clean                  # Clean build
#   ./build.sh --install                # Build and install
#   ./build.sh --format                 # Format code before build
#   ./build.sh --help                   # Show help
#
# Environment variables:
#   CMAKE_PRESET     - CMake preset to use (default: debug)
#   JOBS             - Number of parallel jobs (default: auto -> detected)
#   BUILD_DIR        - Build directory (default: build/<preset>)
#   INSTALL_PREFIX   - Install prefix (default: /usr/local)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"

# Defaults (can be overridden by env)
: "${CMAKE_PRESET:=debug}"
: "${JOBS:=auto}"
: "${INSTALL_PREFIX:=/usr/local}"
: "${VERBOSE:=0}"

# Flags
CLEAN_BUILD=1
RUN_INSTALL=0
RUN_TESTS=0
RUN_FORMAT=0
SHOW_HELP=0

# ============================================================================
# Colors and Formatting
# ============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# ============================================================================
# Helper Functions
# ============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_header()  {
    echo
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}$*${NC}"
    echo -e "${BOLD}========================================${NC}"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Required command '$1' not found. Please install it."
        exit 2
    fi
}

detect_jobs() {
    if [[ "${JOBS}" == "auto" ]]; then
        if command -v nproc >/dev/null 2>&1; then
            JOBS="$(nproc)"
        elif [[ "$(uname)" == "Darwin" ]] && command -v sysctl >/dev/null 2>&1; then
            JOBS="$(sysctl -n hw.ncpu)"
        else
            JOBS=2
        fi
    fi
    # ensure integer
    if ! [[ "${JOBS}" =~ ^[0-9]+$ ]]; then
        JOBS=2
    fi
}

show_help() {
    cat << EOF
${BOLD}BoltDBG Build Script${NC}

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --preset PRESET       CMake preset (debug, release, debug-asan, etc.)
    --clean               Remove build directory before building
    --install             Install after building
    --no-tests            Skip running tests
    --format              Run code formatter before building
    --jobs N              Number of parallel build jobs (default: auto)
    --prefix PATH         Installation prefix (default: /usr/local)
    --verbose             Enable verbose output
    --help                Show this help message

PRESETS:
    debug                 Debug build with symbols
    release               Optimized release build
    debug-asan            Debug with Address Sanitizer
    debug-ubsan           Debug with UB Sanitizer
    debug-tsan            Debug with Thread Sanitizer
    ci                    CI/CD build configuration

EXAMPLES:
    $0                              # Basic debug build
    $0 --preset release             # Release build
    $0 --preset debug-asan --clean  # Clean ASAN build
    $0 --install --prefix ~/local   # Build and install to ~/local
    $0 --format --preset release    # Format then build release

EOF
    exit 0
}

# ============================================================================
# Argument Parsing
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --preset)
            CMAKE_PRESET="${2:-}"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=1
            shift
            ;;
        --install)
            RUN_INSTALL=1
            shift
            ;;
        --no-tests)
            RUN_TESTS=0
            shift
            ;;
        --format)
            RUN_FORMAT=1
            shift
            ;;
        --jobs)
            JOBS="${2:-}"
            shift 2
            ;;
        --prefix)
            INSTALL_PREFIX="${2:-}"
            shift 2
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --help|-h)
            SHOW_HELP=1
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [[ $SHOW_HELP -eq 1 ]]; then
    show_help
fi

# ============================================================================
# Prerequisites
# ============================================================================

require_cmd cmake
require_cmd git

detect_jobs

BUILD_DIR="${ROOT_DIR}/build/${CMAKE_PRESET}"

# ============================================================================
# Main Build Process
# ============================================================================

log_header "BoltDBG Build Configuration"
log_info "Root directory:    ${ROOT_DIR}"
log_info "Build directory:   ${BUILD_DIR}"
log_info "CMake preset:      ${CMAKE_PRESET}"
log_info "Parallel jobs:     ${JOBS}"
log_info "Install prefix:    ${INSTALL_PREFIX}"
log_info "Clean build:       ${CLEAN_BUILD}"
log_info "Run tests:         ${RUN_TESTS}"
log_info "Run install:       ${RUN_INSTALL}"

# Step 1: Code formatting (optional)
if [[ $RUN_FORMAT -eq 1 ]]; then
    log_header "Step 1/6: Code Formatting"
    if [[ -f "${ROOT_DIR}/scripts/format.sh" ]]; then
        "${ROOT_DIR}/scripts/format.sh"
        log_success "Code formatted"
    else
        log_warning "scripts/format.sh not found, skipping formatting"
    fi
else
    log_info "Skipping code formatting (use --format to enable)"
fi

# Step 2: Fetch dependencies (optional helper)
# If you use submodules or have a fetch script, run it here.
if [[ -f "${ROOT_DIR}/scripts/fetch_deps.sh" ]]; then
    log_header "Step 2/6: Fetch Dependencies"
    "${ROOT_DIR}/scripts/fetch_deps.sh" || {
        log_warning "fetch_deps.sh failed or returned non-zero, continuing anyway"
    }
else
    log_info "No fetch_deps.sh found — relying on CMake FetchContent or vendored deps"
fi

# Step 3: Clean (optional)
if [[ $CLEAN_BUILD -eq 1 ]]; then
    log_header "Step 3/6: Clean Build Directory"
    if [[ -d "${BUILD_DIR}" ]]; then
        log_info "Removing ${BUILD_DIR}..."
        rm -rf "${BUILD_DIR}"
        log_success "Build directory cleaned"
    else
        log_info "Build directory does not exist, nothing to clean"
    fi
else
    log_info "Using existing build directory (use --clean for fresh build)"
fi

# Step 4: Configure
log_header "Step 4/6: CMake Configure"
mkdir -p "${BUILD_DIR}"

# If CMakePresets.json exists, prefer using presets. Otherwise fallback to manual args.
CMAKE_CONF_ARGS=()
CMAKE_CONF_ARGS+=("-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}")

if [[ "${VERBOSE}" -eq 1 ]]; then
    CMAKE_CONF_ARGS+=("-DCMAKE_VERBOSE_MAKEFILE=ON")
fi

if [[ -f "${ROOT_DIR}/CMakePresets.json" ]]; then
    # Use preset; need to call with -S and -B for predictable behavior
    log_info "Found CMakePresets.json — configuring with preset '${CMAKE_PRESET}'"
    cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" --preset "${CMAKE_PRESET}" "${CMAKE_CONF_ARGS[@]}"
else
    # Fallback: map simple preset names to CMAKE_BUILD_TYPE and sanitizer flags
    log_info "No CMakePresets.json — using fallback configure for preset '${CMAKE_PRESET}'"
    case "${CMAKE_PRESET}" in
        debug)
            CMAKE_CONF_ARGS+=("-DCMAKE_BUILD_TYPE=Debug")
            ;;
        release)
            CMAKE_CONF_ARGS+=("-DCMAKE_BUILD_TYPE=Release")
            ;;
        debug-asan)
            CMAKE_CONF_ARGS+=("-DCMAKE_BUILD_TYPE=Debug" "-DBOLTDBG_ENABLE_ASAN=ON")
            ;;
        debug-ubsan)
            CMAKE_CONF_ARGS+=("-DCMAKE_BUILD_TYPE=Debug" "-DBOLTDBG_ENABLE_UBSAN=ON")
            ;;
        debug-tsan)
            CMAKE_CONF_ARGS+=("-DCMAKE_BUILD_TYPE=Debug" "-DBOLTDBG_ENABLE_TSAN=ON")
            ;;
        ci)
            CMAKE_CONF_ARGS+=("-DCMAKE_BUILD_TYPE=RelWithDebInfo")
            ;;
        *)
            # default fallback
            CMAKE_CONF_ARGS+=("-DCMAKE_BUILD_TYPE=Debug")
            log_warning "Unknown preset '${CMAKE_PRESET}', falling back to Debug build type"
            ;;
    esac

    # Run configure explicitly with -S and -B
    log_info "Running: cmake -S ${ROOT_DIR} -B ${BUILD_DIR} ${CMAKE_CONF_ARGS[*]}"
    cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" "${CMAKE_CONF_ARGS[@]}"
fi

log_success "Configuration complete"

# Step 5: Build
log_header "Step 5/6: Build"

# Build args for cmake --build
CMAKE_BUILD_ARGS=(--build "${BUILD_DIR}" --parallel "${JOBS}")
if [[ "${VERBOSE}" -eq 1 ]]; then
    CMAKE_BUILD_ARGS+=(--verbose)
fi

log_info "Running: cmake ${CMAKE_BUILD_ARGS[*]}"
cmake "${CMAKE_BUILD_ARGS[@]}"
log_success "Build complete"

# Step 6: Tests
if [[ $RUN_TESTS -eq 1 ]]; then
    log_header "Step 6/6: Run Tests"
    if command -v ctest >/dev/null 2>&1; then
        (
            cd "${BUILD_DIR}"
            if ! ctest --output-on-failure --parallel "${JOBS}"; then
                log_error "Some tests failed"
                exit 1
            fi
        )
        log_success "All tests passed"
    else
        log_warning "ctest not found, skipping tests"
    fi
else
    log_info "Skipping tests (use --no-tests to enable)"
fi

# Optional: Install
if [[ $RUN_INSTALL -eq 1 ]]; then
    log_header "Installing"
    cmake --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"
    log_success "Installation complete to ${INSTALL_PREFIX}"
fi

# ============================================================================
# Summary
# ============================================================================

log_header "Build Complete"

# Try to guess executable path, but don't assume too much
POSSIBLE_BIN="${BUILD_DIR}/src/boltdbg"
if [[ -x "${POSSIBLE_BIN}" ]]; then
    log_success "Executable: ${POSSIBLE_BIN}"
else
    log_info "Executable not found at ${POSSIBLE_BIN}. Check your targets inside ${BUILD_DIR}"
    log_info "You can inspect build tree or run: cmake --build ${BUILD_DIR} --target <your-target>"
fi

if [[ $RUN_INSTALL -eq 1 ]]; then
    log_success "Installed to: ${INSTALL_PREFIX}/bin/ (if install step created it)"
fi

echo
log_info "To run the application (if present):"
echo "  ${POSSIBLE_BIN}"
echo
log_info "To run tests manually:"
echo "  cd ${BUILD_DIR} && ctest --output-on-failure"
echo
log_info "To install manually:"
echo "  cmake --install ${BUILD_DIR} --prefix ${INSTALL_PREFIX}"
echo

exit 0
