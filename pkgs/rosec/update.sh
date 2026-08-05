#!/usr/bin/env bash

set -euo pipefail

echo "Fetching latest rosec release from GitHub..."

API_URL="https://api.github.com/repos/jmylchreest/rosec/releases/latest"
RELEASE=$(curl -sf "$API_URL")

VERSION=$(echo "$RELEASE" | jq -r '.tag_name' | sed 's/^v//')

# Asset names follow the pattern: rosec-<version>-x86_64-unknown-linux-gnu.tar.gz
# and rosec-provider-bitwarden-pm-<version>.wasm.tar.gz
MAIN_URL=$(echo "$RELEASE" | jq -r --arg name "rosec-${VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
  '.assets[] | select(.name == $name) | .browser_download_url')
WASM_URL=$(echo "$RELEASE" | jq -r --arg name "rosec-provider-bitwarden-pm-${VERSION}.wasm.tar.gz" \
  '.assets[] | select(.name == $name) | .browser_download_url')

if [ -z "$MAIN_URL" ] || [ -z "$WASM_URL" ]; then
  echo "Error: could not resolve release asset URLs for version $VERSION" >&2
  exit 1
fi

echo "Found official version: $VERSION"
echo "Main tarball URL: $MAIN_URL"
echo "Bitwarden provider URL: $WASM_URL"

echo "Downloading and calculating Nix hashes"
MAIN_HASH=$(nix-prefetch-url --unpack "$MAIN_URL")
WASM_HASH=$(nix-prefetch-url --unpack "$WASM_URL")

cat > rosec.json <<EOF
{
  "version": "$VERSION",
  "url": "$MAIN_URL",
  "hash": "$MAIN_HASH",
  "wasm_url": "$WASM_URL",
  "wasm_hash": "$WASM_HASH"
}
EOF

echo "Wrote rosec.json"
