#!/usr/bin/env bash

echo "Fetching latest Linux Nightly release from Brave's GitHub releases..."

RELEASE=$(curl -s "https://api.github.com/repos/brave/brave-browser/releases?per_page=100" | jq -r '[.[] | select(any(.assets[]; .name | test("^brave-browser-nightly_.*_amd64\\.deb$")))] | .[0]')

if [ -z "$RELEASE" ] || [ "$RELEASE" = "null" ]; then
  echo "Error: Could not fetch the latest Brave Nightly release."
  exit 1
fi

VERSION=$(echo "$RELEASE" | jq -r '.tag_name' | sed 's/^v//')

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Error: Could not parse the version from the release."
  exit 1
fi

DOWNLOAD_URL="https://github.com/brave/brave-browser/releases/download/v${VERSION}/brave-browser-nightly_${VERSION}_amd64.deb"

echo "Found official version: $VERSION"
echo "Download URL: $DOWNLOAD_URL"

# Calculate the Nix hash using the exact, verified URL
echo "Downloading and calculating Nix hash"
HASH=$(nix-prefetch-url "$DOWNLOAD_URL")

echo "{
  \"version\": \"$VERSION\",
  \"url\": \"$DOWNLOAD_URL\",
  \"hash\": \"$HASH\"
}" > brave-nightly.json
