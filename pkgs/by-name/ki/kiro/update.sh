#!/usr/bin/env bash

set -euo pipefail
package_nix=$(dirname "$(readlink -f "$0")")/package.nix

# Platform configuration array
declare -A platforms=(
    ["x86_64-linux"]="https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json"
    ["x86_64-darwin"]="https://prod.download.desktop.kiro.dev/stable/metadata-dmg-darwin-x64-stable.json"
    ["aarch64-darwin"]="https://prod.download.desktop.kiro.dev/stable/metadata-dmg-darwin-arm64-stable.json"
)

# Arrays to store platform data
declare -A platform_versions
declare -A platform_urls

# Function to get version and URL for a platform
get_platform_info() {
    local url=$1
    local platform=$2
    
    echo "Fetching metadata for $platform..."
    local response=$(curl -s "$url")
    
    # JSON response - extract from releases array
    local file_url=$(echo "$response" | jq -r '.releases[0].updateTo | select(.url | contains(".tar") or contains(".dmg")) | .url' | head -1)
    local version=$(echo "$response" | jq -r '.currentRelease')
    
    platform_versions["$platform"]="$version"
    platform_urls["$platform"]="$file_url"
}

# Fetch metadata for all platforms
echo "Fetching platform information..."
for platform in "${!platforms[@]}"; do
    get_platform_info "${platforms[$platform]}" "$platform"
done

# Determine the maximum version
max_version=""
for platform in "${!platform_versions[@]}"; do
    version="${platform_versions[$platform]}"
    if [[ -z "$max_version" ]] || [[ "$version" > "$max_version" ]]; then
        max_version="$version"
    fi
done

echo "Latest version across all platforms: $max_version"

# Get current version from package.nix
current_version=$(grep -E '^  version = ' ${package_nix} | cut -d'"' -f2)

if [[ "$max_version" == "$current_version" ]]; then
    echo "No update needed. Current version is already the latest: $current_version"
    exit 0
fi

echo "Updating to version: $max_version"

# Update the version and URLs with hashes
echo "Updating package.nix with new version and hashes..."

# Arrays to store platform hashes
declare -A platform_hashes

# Get hashes for all platforms
echo "Calculating hashes..."
for platform in "${!platform_urls[@]}"; do
    url="${platform_urls[$platform]}"
    echo "  Calculating hash for $platform..."
    platform_hashes["$platform"]=$(nix hash convert --hash-algo sha256 "$(nix-prefetch-url "$url")")
done

# Update version in package.nix
sed -i "s/version = \".*\"/version = \"$max_version\"/" ${package_nix}

# Update URLs and hashes for each platform
for platform in "${!platform_urls[@]}"; do
    url="${platform_urls[$platform]}"
    hash="${platform_hashes[$platform]}"
    
    # Use awk to update the specific platform section
    awk -v platform="$platform" -v new_url="$url" -v new_hash="$hash" '
    BEGIN { in_platform = 0 }
    $0 ~ platform " = fetchurl" { in_platform = 1 }
    in_platform && /url = / { 
        gsub(/url = ".*"/, "url = \"" new_url "\"")
    }
    in_platform && /hash = / { 
        gsub(/hash = ".*"/, "hash = \"" new_hash "\"")
        in_platform = 0
    }
    { print }
    ' ${package_nix} > ${package_nix}.tmp
    
    mv ${package_nix}.tmp ${package_nix}
done

echo "Successfully updated package.nix to version $max_version"
echo "Hashes calculated and updated:"
for platform in "${!platform_hashes[@]}"; do
    echo "  $platform: ${platform_hashes[$platform]}"
done
