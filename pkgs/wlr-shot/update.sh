#!/usr/bin/env bash

set -euo pipefail

# wlr-shot is published as GitHub release binaries under the wlr-utils repo, so
# this follows the same releases/latest shape as pkgs/rosec/update.sh.

echo "Fetching latest wlr-utils release from GitHub..."

API_URL="https://api.github.com/repos/sjourdois/wlr-utils/releases/latest"
RELEASE=$(curl -sf "$API_URL")

TAG=$(echo "$RELEASE" | jq -r '.tag_name')
VERSION=${TAG#v}

# One tarball holds every binary in the suite (wlr-shot, wlr-chooser, ...).
ASSET="wlr-utils-x86_64-unknown-linux-gnu.tar.xz"
URL=$(echo "$RELEASE" | jq -r --arg name "$ASSET" \
  '.assets[] | select(.name == $name) | .browser_download_url')

if [ -z "$URL" ]; then
  echo "Error: release $TAG has no asset named $ASSET" >&2
  echo "Available assets:" >&2
  echo "$RELEASE" | jq -r '.assets[].name' >&2
  exit 1
fi

echo "Found official version: $VERSION"
echo "Tarball URL: $URL"

echo "Downloading and calculating Nix hash"
# nix-prefetch-url sends the hash to stdout and "path is ..." to stderr, but do
# not pipe through `head -1` here: that closes the pipe early, grep dies on
# SIGPIPE, and `set -o pipefail` aborts the script before it writes the JSON.
# No --unpack: that hashes the *unpacked directory*, whereas default.nix uses
# fetchurl, which wants the hash of the flat tarball.
RAW=$(nix-prefetch-url "$URL" | tr -dc 'a-z0-9\n' | grep -E '^[a-z0-9]{52}$' || true)

if [ -z "$RAW" ]; then
  echo "Error: could not extract a hash from nix-prefetch-url output" >&2
  exit 1
fi

# fetchurl wants SRI, not the bare base32 that --unpack prints. Pass the hash as
# an argument: this Lix build's `nix hash to-sri` reads nothing from stdin.
HASH=$(nix hash to-sri --type sha256 "$RAW")

cat > wlr-shot.json <<EOF
{
  "pname": "wlr-shot",
  "version": "$VERSION",
  "hash": "$HASH",
  "url": "$URL"
}
EOF

echo "Wrote wlr-shot.json"
echo
echo "Note: if a release bumps its ffmpeg sonames, update the ffmpeg_6 pin in default.nix."