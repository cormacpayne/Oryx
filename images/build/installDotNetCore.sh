#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

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
        # For .NET Core 1.1
        libcurl3 \
        libuuid1 \
        libunwind8 \
    && rm -rf /var/lib/apt/lists/*

mkdir /var/nuget

cp build/__dotNetCoreSdkVersions.sh /tmp
cp build/__dotNetCoreRunTimeVersions.sh /tmp
cp images/build/installDotNetCoreSdk.sh /tmp
chmod +x /tmp/installDotNetCoreSdk.sh

# Check https://www.microsoft.com/net/platform/support-policy for support policy of .NET Core versions

source . /tmp/__dotNetCoreSdkVersions.sh

DOTNET_SDK_VER=$DOT_NET_CORE_11_SDK_VERSION \
DOTNET_SDK_SHA=$DOT_NET_CORE_11_SDK_SHA512 \
DOTNET_SDK_URL=https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VER/dotnet-dev-debian.9-x64.$DOTNET_SDK_VER.tar.gz \
# To save disk space do not install packages for this old version which is soon going to be out of support
INSTALL_PACKAGES=false \
/tmp/installDotNetCoreSdk.sh

DOTNET_SDK_VER=$DOT_NET_CORE_21_SDK_VERSION \
DOTNET_SDK_SHA=$DOT_NET_CORE_21_SDK_SHA512 \
/tmp/installDotNetCoreSdk.sh

DOTNET_SDK_VER=$DOT_NET_CORE_22_SDK_VERSION \
DOTNET_SDK_SHA=$DOT_NET_CORE_22_SDK_SHA512 \
/tmp/installDotNetCoreSdk.sh

DOTNET_SDK_VER=$DOT_NET_CORE_30_SDK_VERSION_PREVIEW_NAME \
DOTNET_SDK_SHA=$DOT_NET_CORE_30_SDK_SHA512 \
/tmp/installDotNetCoreSdk.sh

RUN set -ex \
    rm -rf /tmp/NuGetScratch \
    && find /var/nuget -type d -exec chmod 777 {} \;

RUN set -ex \
 && sdksDir=/opt/dotnet/sdks \
 && cd $sdksDir \
 && ln -s 1.1 1 \
 && ln -s 2.1 2 \
 && ln -s 3.0 3

dotnetDir=/opt/dotnet \
 && sdksDir=$dotnetDir/sdks \
 && runtimesDir=$dotnetDir/runtimes \
 && mkdir -p $runtimesDir \
 && cd $runtimesDir \
 && . /tmp/__dotNetCoreSdkVersions.sh \
 && . /tmp/__dotNetCoreRunTimeVersions.sh \
 # 1.1 sdk <-- 1.0 runtime's sdk
 && mkdir $NET_CORE_APP_10 \
 && ln -s $NET_CORE_APP_10 1.0 \
 && ln -s $sdksDir/$DOT_NET_CORE_11_SDK_VERSION $NET_CORE_APP_10/sdk \
 # 1.1 sdk <-- 1.1 runtime's sdk
 && mkdir $NET_CORE_APP_11 \
 && ln -s $NET_CORE_APP_11 1.1 \
 && ln -s 1.1 1 \
 && ln -s $sdksDir/$DOT_NET_CORE_11_SDK_VERSION $NET_CORE_APP_11/sdk \
 # 2.1 sdk <-- 2.0 runtime's sdk
 && mkdir $NET_CORE_APP_20 \
 && ln -s $NET_CORE_APP_20 2.0 \
 && ln -s $sdksDir/$DOT_NET_CORE_21_SDK_VERSION $NET_CORE_APP_20/sdk \
 # 2.1 sdk <-- 2.1 runtime's sdk
 && mkdir $NET_CORE_APP_21 \
 && ln -s $NET_CORE_APP_21 2.1 \
 && ln -s 2.1 2 \
 && ln -s $sdksDir/$DOT_NET_CORE_21_SDK_VERSION $NET_CORE_APP_21/sdk \
 # 2.2 sdk <-- 2.2 runtime's sdk
 && mkdir $NET_CORE_APP_22 \
 && ln -s $NET_CORE_APP_22 2.2 \
 && ln -s $sdksDir/$DOT_NET_CORE_22_SDK_VERSION $NET_CORE_APP_22/sdk \
 # 3.0 sdk <-- 3.0 runtime's sdk
 && mkdir $NET_CORE_APP_30 \
 && ln -s $NET_CORE_APP_30 3.0 \
 && ln -s 3.0 3 \
 && ln -s $sdksDir/$DOT_NET_CORE_30_SDK_VERSION $NET_CORE_APP_30/sdk \
 # LTS sdk <-- LTS runtime's sdk
 && ln -s 2.1 lts \
 && ltsSdk=$(readlink lts/sdk) \
 && ln -s $ltsSdk/dotnet /usr/local/bin/dotnet
