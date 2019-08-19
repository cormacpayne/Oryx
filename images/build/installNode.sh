#!/bin/bash

set -ex

function tryCreateLink() {
    local linkSource="$1"
    local linkDestination="$2"

    if [ -d "/opt/nodejs/$linkSource" ] || [ -L "/opt/nodejs/$linkSource" ]
    then
        ln -s $linkSource $linkDestination
    fi
}

curl -sL https://git.io/n-install | bash -s -- -ny

allVersions=(4.4.7 4.5.0 4.8.0 6.2.2 6.6.0 6.9.3 6.10.3 6.11.0 8.0.0 8.1.4 8.2.1 8.8.1 8.9.4 8.11.2 8.12.0 8.15.1 9.4.0 10.1.0 10.10.0 10.14.2 $NODE6_VERSION $NODE8_VERSION $NODE10_VERSION $NODE12_VERSION)
versionsToInstall="$@"
if [ "$#" -eq 0 ]
then
    versionToInstall=( "${allVersions[@]}" )
fi

for version in $versionToInstall
do
    ~/n/bin/n -d "$version"
done

mv /usr/local/n/versions/node /opt/nodejs
rm -rf /usr/local/n ~/n

for ver in `ls /opt/nodejs`
do
    nodeModulesDir="/opt/nodejs/$ver/lib/node_modules"
    npm_ver=`jq -r .version $nodeModulesDir/npm/package.json`
    if [ ! "$npm_ver" = "${npm_ver#6.}" ]; then
        echo "Upgrading node $ver's npm version from $npm_ver to 6.9.0"
        cd $nodeModulesDir
        PATH="/opt/nodejs/$ver/bin:$PATH" \
        "$nodeModulesDir/npm/bin/npm-cli.js" install npm@6.9.0
        echo
    fi
done

for ver in `ls /opt/nodejs`
do
    npm_ver=`jq -r .version /opt/nodejs/$ver/lib/node_modules/npm/package.json`
    if [ ! -d /opt/npm/$npm_ver ]; then
        mkdir -p /opt/npm/$npm_ver
        ln -s /opt/nodejs/$ver/lib/node_modules /opt/npm/$npm_ver/node_modules
        ln -s /opt/nodejs/$ver/lib/node_modules/npm/bin/npm /opt/npm/$npm_ver/npm
        if [ -e /opt/nodejs/$ver/lib/node_modules/npm/bin/npx ]; then
            chmod +x /opt/nodejs/$ver/lib/node_modules/npm/bin/npx
            ln -s /opt/nodejs/$ver/lib/node_modules/npm/bin/npx /opt/npm/$npm_ver/npx
        fi
    fi
done

source /tmp/__nodeVersions.sh

/tmp/scripts/receivePgpKeys.sh 6A010C5166006599AA17F08146C2130DFD2497F5 \
&& curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
&& curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
&& gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
&& mkdir -p /opt/yarn \
&& tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn \
&& mv /opt/yarn/yarn-v$YARN_VERSION /opt/yarn/$YARN_VERSION \
&& rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

tryCreateLink 4.4.7 /opt/nodejs/4.4 \
 && tryCreateLink 4.5.0 /opt/nodejs/4.5 \
 && tryCreateLink 4.8.0 /opt/nodejs/4.8 \
 && tryCreateLink 4.8 /opt/nodejs/4 \
 && tryCreateLink 6.2.2 /opt/nodejs/6.2 \
 && tryCreateLink 6.6.0 /opt/nodejs/6.6 \
 && tryCreateLink 6.9.3 /opt/nodejs/6.9 \
 && tryCreateLink 6.10.3 /opt/nodejs/6.10 \
 && tryCreateLink 6.11.0 /opt/nodejs/6.11 \
 && tryCreateLink 8.0.0 /opt/nodejs/8.0 \
 && tryCreateLink 8.1.4 /opt/nodejs/8.1 \
 && tryCreateLink 8.2.1 /opt/nodejs/8.2 \
 && tryCreateLink 8.8.1 /opt/nodejs/8.8 \
 && tryCreateLink 8.9.4 /opt/nodejs/8.9 \
 && tryCreateLink 8.11.2 /opt/nodejs/8.11 \
 && tryCreateLink 8.12.0 /opt/nodejs/8.12 \
 && tryCreateLink 8.15.1 /opt/nodejs/8.15 \
 && tryCreateLink 9.4.0 /opt/nodejs/9.4 \
 && tryCreateLink 9.4 /opt/nodejs/9 \
 && tryCreateLink 10.1.0 /opt/nodejs/10.1 \
 && tryCreateLink 10.10.0 /opt/nodejs/10.10 \
 && tryCreateLink 10.14.2 /opt/nodejs/10.14 \
 && tryCreateLink $NODE6_VERSION /opt/nodejs/$NODE6_MAJOR_MINOR_VERSION \
 && tryCreateLink $NODE6_MAJOR_MINOR_VERSION /opt/nodejs/6 \
 && tryCreateLink $NODE8_VERSION /opt/nodejs/$NODE8_MAJOR_MINOR_VERSION \
 && tryCreateLink $NODE8_MAJOR_MINOR_VERSION /opt/nodejs/8 \
 && tryCreateLink $NODE10_VERSION /opt/nodejs/$NODE10_MAJOR_MINOR_VERSION \
 && tryCreateLink $NODE10_MAJOR_MINOR_VERSION /opt/nodejs/10 \
 && tryCreateLink $NODE12_VERSION /opt/nodejs/$NODE12_MAJOR_MINOR_VERSION \
 && tryCreateLink $NODE12_MAJOR_MINOR_VERSION /opt/nodejs/12 \
 && tryCreateLink 10 /opt/nodejs/lts

tryCreateLink 2.15.9 /opt/npm/2.15 \
 && tryCreateLink 2.15 /opt/npm/2 \
 && tryCreateLink 3.9.5 /opt/npm/3.9 \
 && tryCreateLink 3.10.10 /opt/npm/3.10 \
 && tryCreateLink 3.10 /opt/npm/3 \
 && tryCreateLink 5.0.3 /opt/npm/5.0 \
 && tryCreateLink 5.3.0 /opt/npm/5.3 \
 && tryCreateLink 5.4.2 /opt/npm/5.4 \
 && tryCreateLink 5.6.0 /opt/npm/5.6 \
 && tryCreateLink 5.6 /opt/npm/5 \
 && tryCreateLink 6.9.0 /opt/npm/6.9 \
 && tryCreateLink 6.9 /opt/npm/6 \
 && tryCreateLink 6 /opt/npm/latest

tryCreateLink $YARN_VERSION /opt/yarn/stable \
 && ln -s $YARN_VERSION /opt/yarn/latest \
 && ln -s $YARN_VERSION /opt/yarn/$YARN_MINOR_VERSION \
 && ln -s $YARN_MINOR_VERSION /opt/yarn/$YARN_MAJOR_VERSION

mkdir -p /links \
 && cp -s /opt/nodejs/lts/bin/* /links \
 && cp -s /opt/yarn/stable/bin/yarn /opt/yarn/stable/bin/yarnpkg /links