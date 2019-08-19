#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -ex

versionsToInstall="$@"

shouldInstallVersion () {
    # If no arguments are given, we will assume all versions are to be installed
    if [ "$#" -eq 0 ]
    then
        return 0
    fi

    local versionToLookFor="$1"
    for version in $versionsToInstall
    do
        if [ "$versionToLookFor" == "$version" ]
        then
            return 0
        else
            return 1
        fi
    done
}

apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

mkdir /var/nuget

# Check https://www.microsoft.com/net/platform/support-policy for support policy of .NET Core versions
source /tmp/__dotNetCoreSdkVersions.sh
source /tmp/__dotNetCoreRunTimeVersions.sh

if shouldInstallVersion "$DOT_NET_CORE_11_SDK_VERSION"
then
    echo "Installing .NET Core SDK '$DOT_NET_CORE_11_SDK_VERSION'..."
    apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl3 \
        libuuid1 \
        libunwind8 \
    && rm -rf /var/lib/apt/lists/*

    DOTNET_SDK_VER=$DOT_NET_CORE_11_SDK_VERSION \
    DOTNET_SDK_SHA=$DOT_NET_CORE_11_SDK_SHA512 \
    DOTNET_SDK_URL=https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VER/dotnet-dev-debian.9-x64.$DOTNET_SDK_VER.tar.gz \
    INSTALL_PACKAGES=false \
    /tmp/installDotNetCoreSdk.sh
fi

if shouldInstallVersion "$DOT_NET_CORE_21_SDK_VERSION"
then
    echo "Installing $DOT_NET_CORE_21_SDK_VERSION..."
    DOTNET_SDK_VER=$DOT_NET_CORE_21_SDK_VERSION \
    DOTNET_SDK_SHA=$DOT_NET_CORE_21_SDK_SHA512 \
    /tmp/installDotNetCoreSdk.sh
fi

if shouldInstallVersion "$DOT_NET_CORE_22_SDK_VERSION"
then
    echo "Installing $DOT_NET_CORE_22_SDK_VERSION..."
    DOTNET_SDK_VER=$DOT_NET_CORE_22_SDK_VERSION \
    DOTNET_SDK_SHA=$DOT_NET_CORE_22_SDK_SHA512 \
    /tmp/installDotNetCoreSdk.sh
fi

if shouldInstallVersion "$DOT_NET_CORE_30_SDK_VERSION"
then
    echo "Installing $DOT_NET_CORE_30_SDK_VERSION..."
    DOTNET_SDK_VER=$DOT_NET_CORE_30_SDK_VERSION_PREVIEW_NAME \
    DOTNET_SDK_SHA=$DOT_NET_CORE_30_SDK_SHA512 \
    /tmp/installDotNetCoreSdk.sh
fi

rm -rf /tmp/NuGetScratch \
&& find /var/nuget -type d -exec chmod 777 {} \;

sdksDir=/opt/dotnet/sdks \
 && cd $sdksDir \
 && ln -s 1.1 1 \
 && ln -s 2.1 2 \
 && ln -s 3.0 3

dotnetDir=/opt/dotnet \
 && sdksDir=$dotnetDir/sdks \
 && runtimesDir=$dotnetDir/runtimes \
 && mkdir -p $runtimesDir \
 && cd $runtimesDir

if shouldInstallVersion "$DOT_NET_CORE_11_SDK_VERSION"
then
    # 1.1 sdk <-- 1.0 runtime's sdk
    # 1.1 sdk <-- 1.1 runtime's sdk
    mkdir $NET_CORE_APP_10 \
    && ln -s $NET_CORE_APP_10 1.0 \
    && ln -s $sdksDir/$DOT_NET_CORE_11_SDK_VERSION $NET_CORE_APP_10/sdk \
    && mkdir $NET_CORE_APP_11 \
    && ln -s $NET_CORE_APP_11 1.1 \
    && ln -s 1.1 1 \
    && ln -s $sdksDir/$DOT_NET_CORE_11_SDK_VERSION $NET_CORE_APP_11/sdk
fi

if shouldInstallVersion "$DOT_NET_CORE_21_SDK_VERSION"
then
    # 2.1 sdk <-- 2.0 runtime's sdk
    # 2.1 sdk <-- 2.1 runtime's sdk
    mkdir $NET_CORE_APP_20 \
    && ln -s $NET_CORE_APP_20 2.0 \
    && ln -s $sdksDir/$DOT_NET_CORE_21_SDK_VERSION $NET_CORE_APP_20/sdk \
    && mkdir $NET_CORE_APP_21 \
    && ln -s $NET_CORE_APP_21 2.1 \
    && ln -s 2.1 2 \
    && ln -s $sdksDir/$DOT_NET_CORE_21_SDK_VERSION $NET_CORE_APP_21/sdk
fi

if shouldInstallVersion "$DOT_NET_CORE_22_SDK_VERSION"
then
    # 2.2 sdk <-- 2.2 runtime's sdk
    mkdir $NET_CORE_APP_22 \
    && ln -s $NET_CORE_APP_22 2.2 \
    && ln -s $sdksDir/$DOT_NET_CORE_22_SDK_VERSION $NET_CORE_APP_22/sdk
fi

if shouldInstallVersion "$DOT_NET_CORE_30_SDK_VERSION"
then
    # 3.0 sdk <-- 3.0 runtime's sdk
    # LTS sdk <-- LTS runtime's sdk
    mkdir $NET_CORE_APP_30 \
    && ln -s $NET_CORE_APP_30 3.0 \
    && ln -s 3.0 3 \
    && ln -s $sdksDir/$DOT_NET_CORE_30_SDK_VERSION $NET_CORE_APP_30/sdk \
    && ln -s 2.1 lts \
    && ltsSdk=$(readlink lts/sdk) \
    && ln -s $ltsSdk/dotnet /usr/local/bin/dotnet
fi