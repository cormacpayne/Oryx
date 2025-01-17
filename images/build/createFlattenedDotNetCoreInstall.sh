#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

declare -r DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$DIR/__dotNetCoreSdkVersions.sh"
source "$DIR/__dotNetCoreRunTimeVersions.sh"

splitSdksDir="/opt/dotnet/sdks"

allSdksDir="/opt/dotnet/all"
mkdir -p "$allSdksDir"

# Get the latest (not 'lts') version of .NET Core SDK so that we can use the 'dotnet.exe' of that version
# as the muxer to switch between different versions of SDKs
currentMaxMajorVersion="0"
currentMaxMinorVersion="0"
cd "$splitSdksDir"
integerRegex='^[0-9]+$'
for sdkDir in "$splitSdksDir"/*/
do
    sdkDir=${sdkDir%*/}
    sdkDirName=${sdkDir##*/}

    IFS='.' read -ra SDK_VERSION_PARTS <<< "$sdkDirName"
    majorVersion=${SDK_VERSION_PARTS[0]}
    minorVersion=${SDK_VERSION_PARTS[1]:-0}

    # Ignore strings like 'lts'
    if ! [[ $majorVersion =~ $integerRegex ]] ; then
        continue
    fi

    if [ "$majorVersion" -gt "$currentMaxMajorVersion" ] || \
        ( [ "$majorVersion" -gt "$currentMaxMajorVersion" ] && \
            [ "$minorVersion" -gt "$currentMaxMinorVersion" ] ); then
        currentMaxMajorVersion=$majorVersion
        currentMaxMinorVersion=$minorVersion
    fi
done

muxerVersion="$currentMaxMajorVersion.$currentMaxMinorVersion"
echo "Using SDK version '$muxerVersion' for getting the muxer dotnet.exe..."
cp -f "$splitSdksDir/$muxerVersion/dotnet" "$allSdksDir"
cp -f "$splitSdksDir/$muxerVersion/LICENSE.txt" "$allSdksDir"
cp -f "$splitSdksDir/$muxerVersion/ThirdPartyNotices.txt" "$allSdksDir"

# Creates a structure which is how a typical .NET Core SDK install needs to be. Here we create only symlinks
# to existing split structure of SDKs.
function createLinks() {
    local sdkVersion="$1"
    local runtimeVersion="$2"
    
    cd "$splitSdksDir/$sdkVersion"

    # Find folders with name as sdk or runtime version
    find . -name "$sdkVersion" -o -name "$runtimeVersion" | while read subPath; do
        # Trim beginning 2 characters from the line which currently looks like, for example, './sdk/2.2.402'
        subPath="${subPath:2}"
        
        linkFrom="$allSdksDir/$subPath"
        linkFromParentDir=$(dirname $linkFrom)
        mkdir -p "$linkFromParentDir"

        linkTo="$splitSdksDir/$sdkVersion/$subPath"
        ln -s $linkTo $linkFrom
        echo "Created link: $linkFrom ==> $linkTo"
    done
}

createLinks "$DOT_NET_CORE_30_SDK_VERSION" "$NET_CORE_APP_30"
echo
createLinks "$DOT_NET_CORE_22_SDK_VERSION" "$NET_CORE_APP_22"
echo
createLinks "$DOT_NET_CORE_21_SDK_VERSION" "$NET_CORE_APP_21"
echo
createLinks "$DOT_NET_CORE_11_SDK_VERSION" "$NET_CORE_APP_11"