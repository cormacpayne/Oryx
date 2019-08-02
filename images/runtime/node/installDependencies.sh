#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

# All users need access to node_modules at the root, as this is the location
# for packages valid for all apps.
mkdir -p /node_modules
chmod 777 /node_modules

npm_ver=$(npm --version)
if [ ! "$npm_ver" = "${npm_ver#6.}" ]; then
    echo "Upgrading npm version from $npm_ver to 6.10.2";
    npm install -g npm@6.10.2;
fi

# PM2 is supported as an option when running the app,
# so we need to make sure it is available in our images.
npm install -g pm2@3.5.1
