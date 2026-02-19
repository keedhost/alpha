#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-}"
if [[ -z "$ARCH" ]]; then
  echo "Usage: $0 <arm64|x86_64>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$ROOT_DIR/Alpha/Alpha.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData-$ARCH"
BUILD_PRODUCTS="$DERIVED_DATA/Build/Products/Release"
APP_NAME="Alpha.app"
STAGING_DIR="$ROOT_DIR/.build/dmg-$ARCH"
DIST_DIR="$ROOT_DIR/dist"
DMG_NAME="Alpha-${ARCH}.dmg"

mkdir -p "$DERIVED_DATA" "$STAGING_DIR" "$DIST_DIR"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme Alpha \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  -arch "$ARCH" \
  ONLY_ACTIVE_ARCH=YES \
  build

rm -rf "$STAGING_DIR"/*
cp -R "$BUILD_PRODUCTS/$APP_NAME" "$STAGING_DIR/$APP_NAME"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "Alpha" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$DMG_NAME"

printf "Created %s\n" "$DIST_DIR/$DMG_NAME"
