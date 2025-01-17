#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

# Folder structure is used to decide the tag name
# For example, if a Dockerfile is located at "images/runtime/node/10.1.0/Dockerfile",
# then the tag name would be 'node:10.1.0' (i.e. the path between 'runtime' and 'Dockerfile' segments)
function getTagName()
{
	if [ ! $# -eq 1 ]
	then
		echo "Wrong argument count."
		return 1
	fi

	if [ ! -d $1 ]
	then
		echo "Directory '$1' does not exist."
		return 1
	fi

	local replacedPath="$RUNTIME_IMAGES_SRC_DIR/"
	local remainderPath="${1//$replacedPath/}"
	local slashChar="/"
	getTagName_result=${remainderPath//$slashChar/":"}
	return 0
}

function dockerCleanupIfRequested()
{
	if [ "$DOCKER_SYSTEM_PRUNE" == "true" ]
	then
		echo "Running 'docker system prune -f'"
		docker system prune -f
	else
		echo "Skipping 'docker system prune -f'"
	fi
}

function execAllGenerateDockerfiles()
{
	runtimeImagesSourceDir="$1"
	generateDockerfiles=$(find $runtimeImagesSourceDir -type f -name "generateDockerfiles.sh")
	if [ -z "$generateDockerfiles" ]
	then
		echo "Couldn't find any 'generateDockerfiles.sh' under '$runtimeImagesSourceDir' and its sub-directories."
	fi

	for generateDockerFile in $generateDockerfiles; do
		echo
		echo "Executing '$generateDockerFile'..."
		echo
		"$generateDockerFile"
	done
}

function showDockerImageSizes()
{
	docker system df -v
}
