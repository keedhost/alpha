#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$ROOT_DIR/Alpha/Alpha.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"

mkdir -p "$DERIVED_DATA"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme Alpha \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build
