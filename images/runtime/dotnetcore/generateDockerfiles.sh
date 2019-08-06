#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

declare -r DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
declare -r RUNTIME_BASE_IMAGE_NAME_PLACEHOLDER="%RUNTIME_BASE_IMAGE_NAME%"
declare -r BASE_BUILD_NUMBER="20190802.1"

function generateDockerFile() {
	local versionDirectory=$1
	local dockerFileTemplate=$2
	echo "Generating Dockerfile for image $versionDirectory..."

	TARGET_DOCKERFILE="$DIR/$versionDirectory/Dockerfile"
	cp "$dockerFileTemplate" "$TARGET_DOCKERFILE"

	# Replace placeholders
	RUNTIME_BASE_IMAGE_NAME="mcr.microsoft.com/oryx/dotnetcore-base:$versionDirectory-$BASE_BUILD_NUMBER"
	sed -i "s|$RUNTIME_BASE_IMAGE_NAME_PLACEHOLDER|$RUNTIME_BASE_IMAGE_NAME|g" "$TARGET_DOCKERFILE"
}

cd $DIR
for VERSION_DIRECTORY in $(find . -type d -iname '[0-9]*' -printf '%f\n')
do
	if [ "$VERSION_DIRECTORY" == "1.0" ] || [ "$VERSION_DIRECTORY" == "1.1" ] || [ "$VERSION_DIRECTORY" == "2.0" ]
	then
		generateDockerFile "$VERSION_DIRECTORY" "$DIR/DockerfileWithCurlUpdate.template"
	else
		generateDockerFile "$VERSION_DIRECTORY" "$DIR/Dockerfile.template"
	fi
done