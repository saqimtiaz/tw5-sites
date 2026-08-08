#!/usr/bin/env bash
set -euo pipefail

SITE="${1:?Usage: $0 <siteId> <site-root>}"

SITE_ROOT="${2:?Usage: $0 <siteId> <site-root>}"

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
FRAMEWORK_ROOT="$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)"
SITE_ROOT="$(cd -- "$SITE_ROOT" && pwd)"

echo "Building site: $SITE"
echo "Framework: $FRAMEWORK_ROOT"
echo "Site root: $SITE_ROOT"

OUT_DIR="$SITE_ROOT/dist"
VENDOR_DIR="$OUT_DIR/vendor/secure-contact"

PLUGINS=(
  "$FRAMEWORK_ROOT/plugins/sites"
)

if [ -d "$SITE_ROOT/plugins" ]; then
  while IFS= read -r -d '' plugin; do
    PLUGINS+=("$plugin")
  done < <(find "$SITE_ROOT/plugins" -mindepth 1 -maxdepth 1 -type d -print0)
fi

PLUGIN_ARGS=()

for plugin in "${PLUGINS[@]}"; do
  PLUGIN_ARGS+=("++$plugin")
done

render() {
  npm exec --prefix "$FRAMEWORK_ROOT" -- \
    tiddlywiki \
    "${PLUGIN_ARGS[@]}" \
    "$SITE_ROOT" \
    --output "$OUT_DIR" \
    --render "$@"
}

echo "Building site: $SITE"

echo "Cleaning output directory..."
rm -rf "$OUT_DIR"
mkdir -p "$VENDOR_DIR"

echo "Copying static site files..."
if [ -d "$SITE_ROOT/public" ]; then
  cp -r "$SITE_ROOT/public/." "$OUT_DIR/"
fi

echo "Copying secure-contact..."

SECURE_CONTACT_DIR="$(npm exec --prefix "$FRAMEWORK_ROOT" -- secure-contact --assets 2>/dev/null)"

if [ ! -d "$SECURE_CONTACT_DIR" ]; then
  echo "✗ Could not resolve secure-contact assets directory (got: '$SECURE_CONTACT_DIR')"
  exit 1
fi

cp -r "$SECURE_CONTACT_DIR/." "$VENDOR_DIR/"

echo "Rendering site..."

echo "Framework plugin: $FRAMEWORK_ROOT/plugins/sites"

if [ -f "$FRAMEWORK_ROOT/plugins/sites/plugin.info" ]; then
  echo "✓ Sites plugin.info found"
else
  echo "✗ plugin.info NOT FOUND"
  exit 1
fi

render \
  "[tag[$:/tags/site-page]siteId[$SITE]]" \
  "[get[path]addprefix[.]addsuffix[index.html]]" \
  "text/plain" \
  "$:/plugins/sq/sites/common/page"

render \
  "$:/plugins/sq/sites/common/templates/sitemap" \
  "sitemap.xml" \
  "text/plain" \
  "" \
  "site" \
  "$SITE"

render \
  "$:/plugins/sq/sites/common/templates/robots.txt" \
  "robots.txt" \
  "text/plain" \
  "" \
  "site" \
  "$SITE"

echo "Build complete: $OUT_DIR"