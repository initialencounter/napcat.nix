#! /usr/bin/env nix-shell
#! nix-shell -i bash --pure --keep GITHUB_TOKEN -p nix git curl cacert nix-prefetch-git jq

version=$(curl "https://api.github.com/repos/NapNeko/NapCatQQ/releases/latest" | jq -r '.tag_name')
amd64_url="https://github.com/NapNeko/NapCatQQ/releases/download/$version/NapCat.Shell.zip"
amd64_hash=$(nix-prefetch-url $amd64_url)

# use friendlier hashes
amd64_hash=$(nix hash to-sri --type sha256 "$amd64_hash")
sed -i "s|url = \".*\";|url = \"$amd64_url\";|g" ./src/modules/napcat.nix
sed -i "s|hash = \".*\";|hash = \"$amd64_hash\";|g" ./src/modules/napcat.nix