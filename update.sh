if [ "$1" = "napcat" ]; then
    version=$(curl "https://api.github.com/repos/NapNeko/NapCatQQ/releases/latest" | jq -r '.tag_name')
    amd64_url="https://github.com/NapNeko/NapCatQQ/releases/download/$version/NapCat.Shell.zip"
    amd64_hash=$(nix-prefetch-url $amd64_url)

    # use friendlier hashes
    amd64_hash=$(nix hash convert --hash-algo sha256 "$amd64_hash")
    sed -i "s|# Last updated: .*\.|# Last updated: $(date +%F)\.|g" ./src/sources.nix
    sed -i "s|napcat_version = \".*\";|napcat_version = \"$version\";|g" ./src/sources.nix
    sed -i "s|napcat_url = \".*\";|napcat_url = \"$amd64_url\";|g" ./src/sources.nix
    sed -i "s|napcat_hash = \".*\";|napcat_hash = \"$amd64_hash\";|g" ./src/sources.nix
fi

if [ "$1" = "qq" ]; then
    url=$2

    hash=$(echo "$url" | grep -oP '/QQNT/\K[^/]+')
    version=$(echo "$url" | grep -oP 'linuxqq_\K[^_]+')

    amd64_url="https://dldir1v6.qq.com/qqfile/qq/QQNT/${hash}/linuxqq_${version}_amd64.deb"
    arm64_url="https://dldir1v6.qq.com/qqfile/qq/QQNT/${hash}/linuxqq_${version}_arm64.deb"

    amd64_hash=$(nix-prefetch-url $amd64_url)
    arm64_hash=$(nix-prefetch-url $arm64_url)

    # use friendlier hashes
    amd64_hash=$(nix hash convert --to sri --hash-algo sha256 "$amd64_hash")
    arm64_hash=$(nix hash convert --to sri --hash-algo sha256 "$arm64_hash")
    
    sed -i "s|# Last updated: .*\.|# Last updated: $(date +%F)\.|g" ./src/sources.nix
    sed -i "s|qq_version = \".*\";|qq_version = \"$version\";|g" ./src/sources.nix
    sed -i "s|qq_amd64_url = \".*\";|qq_amd64_url = \"$amd64_url\";|g" ./src/sources.nix
    sed -i "s|qq_amd64_hash = \".*\";|qq_amd64_hash = \"$amd64_hash\";|g" ./src/sources.nix
    sed -i "s|qq_arm64_url = \".*\";|qq_arm64_url = \"$arm64_url\";|g" ./src/sources.nix
    sed -i "s|qq_arm64_hash = \".*\";|qq_arm64_hash = \"$arm64_hash\";|g" ./src/sources.nix
fi
