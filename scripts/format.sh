#!/usr/bin/env bash
#
# format.sh — Formats all source files in the project using clang-format.
#
# Usage:
#   ./scripts/format.sh          # Format all C/C++ source files
#   ./scripts/format.sh --check  # Check formatting without modifying files
#

set -euo pipefail

# Project root (one level up from scripts/)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Find all C/C++ files (excluding build directories and third-party code)
FILES=$(find src include -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) \
  ! -path "*/build/*" ! -path "*/third_party/*")

# Default clang-format style (fallback if no .clang-format exists)
STYLE="file"
if [ ! -f ".clang-format" ]; then
  STYLE="llvm"
fi

# Command arguments
CMD_ARGS=("-i" "--style=${STYLE}")
if [[ "${1:-}" == "--check" ]]; then
  CMD_ARGS=("--dry-run" "--Werror" "--style=${STYLE}")
  echo "Checking code format..."
else
  echo "Formatting source files..."
fi

# Run clang-format on each file
for file in $FILES; do
  clang-format "${CMD_ARGS[@]}" "$file"
done

if [[ "${1:-}" == "--check" ]]; then
  echo "Format check passed!"
else
  echo "Formatting complete."
fi

