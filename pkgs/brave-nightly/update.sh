#!/usr/bin/env bash

echo "Fetching latest Linux Nightly release from Brave's official APT repository..."

# Download the 'Packages' manifest from Brave's official Nightly S3 bucket
MANIFEST=$(curl -s https://brave-browser-apt-nightly.s3.brave.com/dists/stable/main/binary-amd64/Packages)

if [ -z "$MANIFEST" ]; then
  echo "Error: Could not download the Brave APT manifest."
  exit 1
fi

# Parse the manifest to find the Version and the Filename of the newest .deb
VERSION=$(echo "$MANIFEST" | grep -i "^Version:" | head -n 1 | awk '{print $2}')
FILE_PATH=$(echo "$MANIFEST" | grep -i "^Filename:" | head -n 1 | awk '{print $2}')

if [ -z "$VERSION" ] || [ -z "$FILE_PATH" ]; then
  echo "Error: Could not parse the version or file path from the manifest."
  exit 1
fi

# Combine the base URL with the exact file path
DOWNLOAD_URL="https://brave-browser-apt-nightly.s3.brave.com/$FILE_PATH"

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
