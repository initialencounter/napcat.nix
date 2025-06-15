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
    payload=$(curl https://im.qq.com/rainbow/linuxQQDownload | grep -oP "var params= \K\{.*\}(?=;)")
    amd64_url=$(jq -r .x64DownloadUrl.deb <<< "$payload")
    arm64_url=$(jq -r .armDownloadUrl.deb <<< "$payload")
    version=$(jq -r .version <<< "$payload")-$(jq -r .updateDate <<< "$payload")

    # use friendlier hashes
    amd64_hash=$(nix-prefetch-url $amd64_url)
    arm64_hash=$(nix-prefetch-url $arm64_url)
    amd64_hash=$(nix hash convert --hash-algo sha256 "$amd64_hash")
    arm64_hash=$(nix hash convert --hash-algo sha256 "$arm64_hash").
    
    sed -i "s|# Last updated: .*\.|# Last updated: $(date +%F)\.|g" ./src/sources.nix
    sed -i "s|qq_version = \".*\";|qq_version = \"$version\";|g" ./src/sources.nix
    sed -i "s|qq_amd64_url = \".*\";|qq_amd64_url = \"$amd64_url\";|g" ./src/sources.nix
    sed -i "s|qq_amd64_hash = \".*\";|qq_amd64_hash = \"$amd64_hash\";|g" ./src/sources.nix
    sed -i "s|qq_arm64_url = \".*\";|qq_arm64_url = \"$arm64_url\";|g" ./src/sources.nix
    sed -i "s|qq_arm64_hash = \".*\";|qq_arm64_hash = \"$arm64_hash\";|g" ./src/sources.nix
fi
