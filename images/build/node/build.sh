#!/bin/bash

set -ex

upgradeNpm() {
    local ver="$1"
    nodeModulesDir="/usr/local/n/versions/node/$ver/lib/node_modules"
    npm_ver=`jq -r .version $nodeModulesDir/npm/package.json`
    if [ ! "$npm_ver" = "${npm_ver#6.}" ]; then
        echo "Upgrading node $ver's npm version from $npm_ver to 6.9.0"
        cd $nodeModulesDir
        PATH="/usr/local/n/versions/node/$ver/bin:$PATH" \
        "$nodeModulesDir/npm/bin/npm-cli.js" install npm@6.9.0
        echo
    fi
}

installNodeVersion() {
    local version="$1"
    ~/n/bin/n -d $version
    cd /usr/local/n/versions/node/$version
    upgradeNpm $version
    tar -zcf /tmp/compressedSdk/node-$version.tar.gz .
}

versions=()
versions+=("4.4.7")
versions+=("4.5.0")
versions+=("4.8.0")
versions+=("6.2.2")
versions+=("6.6.0")
versions+=("6.9.3")
versions+=("6.10.3")
versions+=("6.11.0")
versions+=("8.0.0")
versions+=("8.1.4")
versions+=("8.2.1")
versions+=("8.8.1")
versions+=("8.9.4")
versions+=("8.11.2")
versions+=("8.12.0")
versions+=("8.15.1")
versions+=("9.4.0")
versions+=("10.1.0")
versions+=("10.10.0")
versions+=("10.14.2")

curl -sL https://git.io/n-install | bash -s -- -ny -

mkdir -p /tmp/compressedSdk

for i in "${versions[@]}"
do
    installNodeVersion $i
done

rm -rf /usr/local/n ~/n