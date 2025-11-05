#!/usr/bin/env bash
# scripts/fetch_deps.sh
# Idempotent dependency fetcher for BoltDBG.
# - clones lightweight (shallow) tagged commits into external/
# - safe to run repeatedly
# - respects GIT_CLONE_DEPTH and DRY_RUN env vars
#
# Defaults can be overridden via environment variables:
#   DRY_RUN=1                (don't actually clone)
#   GIT_CLONE_DEPTH=1        (use 0 for full clone)
#   IMGUITAG=... GLFWTAG=... SPDLOGTAG=... GLADTAG=...
#
# Examples:
#   ./scripts/fetch_deps.sh
#   DRY_RUN=1 ./scripts/fetch_deps.sh
#   IMGUITAG=v1.89.8 ./scripts/fetch_deps.sh

set -euo pipefail

# Configurable env vars with sane defaults
: "${DRY_RUN:=0}"
: "${GIT_CLONE_DEPTH:=1}"   # 1 = shallow, 0 = full clone
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXTERNAL_DIR="${ROOT_DIR}/external"

# Repos & tags (pin here; override with env)
IMGUI_REPO="https://github.com/ocornut/imgui.git"
IMGUI_TAG="${IMGUITAG:-v1.89.8}"

GLFW_REPO="https://github.com/glfw/glfw.git"
GLFW_TAG="${GLFWTAG:-3.3.8}"

SPDLOG_REPO="https://github.com/gabime/spdlog.git"
SPDLOG_TAG="${SPDLOGTAG:-v1.11.0}"

GLAD_REPO="https://github.com/Dav1dde/glad.git"
GLAD_TAG="${GLADTAG:-v0.1.36}"

# Helper utils
echo_header() {
    echo "================================================================="
    echo "$*"
    echo "-----------------------------------------------------------------"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: required command '$1' not found in PATH. Install it and retry."
        exit 2
    fi
}

# Check prerequisites (git required to clone)
require_cmd git

# Prepare external dir
mkdir -p "${EXTERNAL_DIR}"

# normalize depth option for git clone
git_depth_arg=()
if [ "${GIT_CLONE_DEPTH}" != "0" ]; then
    git_depth_arg=(--depth "${GIT_CLONE_DEPTH}")
fi

# Clone helper: idempotent and safe
clone_if_missing() {
    local target_dir="$1"; shift
    local repo="$1"; shift
    local tag="$1"; shift

    # If exists and is a git repo, skip
    if [ -d "${target_dir}" ] && [ -d "${target_dir}/.git" ]; then
        echo ">>> ${target_dir} already exists and is a git repo. Skipping."
        return 0
    fi

    # If exists but not a git repo, avoid overwriting
    if [ -d "${target_dir}" ] && [ ! -d "${target_dir}/.git" ]; then
        echo ">>> ${target_dir} exists but is not a git repo. Skipping to avoid overwrite."
        return 0
    fi

    # Dry-run mode: just print what would be done
    if [ "${DRY_RUN}" = "1" ]; then
        echo "[DRY RUN] git clone ${git_depth_arg[*]} --branch ${tag} ${repo} ${target_dir}"
        return 0
    fi

    # Attempt clone; if tag isn't found, try fallback to branch/commit directly
    echo "Cloning ${repo} (ref=${tag}) into ${target_dir} (depth=${GIT_CLONE_DEPTH:-full})..."
    set +e
    git clone "${git_depth_arg[@]}" --branch "${tag}" "${repo}" "${target_dir}"
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
        echo "Warning: clone with --branch ${tag} failed, attempting clone of default branch then checkout..."
        git clone "${git_depth_arg[@]}" "${repo}" "${target_dir}"
        (
            cd "${target_dir}"
            # try to checkout tag/commit; ignore failures but warn
            if ! git checkout "${tag}"; then
                echo "Warning: could not checkout '${tag}' in ${target_dir}; repository left on default branch."
            fi
        )
    fi
    echo "Cloned ${repo} -> ${target_dir}"
}

# Small network check (best-effort)
check_network() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsS --max-time 5 https://github.com >/dev/null 2>&1 || {
            echo "WARNING: network check to github.com failed. If you are offline, fetch will fail."
        }
    elif command -v ping >/dev/null 2>&1; then
        ping -c1 github.com >/dev/null 2>&1 || {
            echo "WARNING: unable to ping github.com. If you are offline, fetch will fail."
        }
    fi
}

# Begin
echo_header "BoltDBG: fetching external dependencies into ${EXTERNAL_DIR}"
echo "DRY_RUN=${DRY_RUN}  GIT_CLONE_DEPTH=${GIT_CLONE_DEPTH}"
echo "Pins: IMGUITAG=${IMGUI_TAG} GLFWTAG=${GLFW_TAG} SPDLOGTAG=${SPDLOG_TAG} GLADTAG=${GLAD_TAG}"
echo

check_network

# --- Clone sequence (order chosen to satisfy typical needs) ---

# ImGui: we want core + backends (we will keep repo as-is)
IMGUI_DIR="${EXTERNAL_DIR}/imgui"
clone_if_missing "${IMGUI_DIR}" "${IMGUI_REPO}" "${IMGUI_TAG}"

# GLFW: vendor if missing (many systems provide system package)
GLFW_DIR="${EXTERNAL_DIR}/glfw"
clone_if_missing "${GLFW_DIR}" "${GLFW_REPO}" "${GLFW_TAG}"

# spdlog: logging library
SPDLOG_DIR="${EXTERNAL_DIR}/spdlog"
clone_if_missing "${SPDLOG_DIR}" "${SPDLOG_REPO}" "${SPDLOG_TAG}"

# glad: OpenGL loader (optional but recommended)
GLAD_DIR="${EXTERNAL_DIR}/glad"
clone_if_missing "${GLAD_DIR}" "${GLAD_REPO}" "${GLAD_TAG}"

# Optional: prune heavy demo directories for space (shallow clones make this minor)
# e.g. remove example heavy files from imgui if you want:
if [ "${DRY_RUN}" != "1" ]; then
    # If a full clone was used, consider removing unnecessary files (uncomment if desired)
    # find "${IMGUI_DIR}" -name 'examples' -type d -exec rm -rf {} +
    :
fi

echo
echo_header "Done"
echo "Fetched dependencies are placed under ${EXTERNAL_DIR}."
echo "Note: external/ should be listed in .gitignore so these sources are not committed."
echo "If you prefer FetchContent at configure-time, CMake fallback will handle it automatically."
echo
echo "Tip: To force re-fetch (fresh clone), remove the target dir and run again:"
echo "  rm -rf ${EXTERNAL_DIR}/imgui ${EXTERNAL_DIR}/glfw ${EXTERNAL_DIR}/spdlog ${EXTERNAL_DIR}/glad && ./scripts/fetch_deps.sh"
echo_header "Finished fetching deps"

exit 0
