#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------
#
# This script builds some base images that are needed for the build image:
# - Python binaries
# - PHP binaries
# - Yarn package cache
#

set -e

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )

# Load all variables
source $REPO_DIR/build/__variables.sh

IMAGE_DIR_TO_BUILD=$1
IMAGE_TAG="${BUILD_NUMBER:-latest}"
BUILD_IMAGE_PREFIX="$__REPO_DIR/images/build"
ARTIFACTS_FILE="$BASE_IMAGES_ARTIFACTS_FILE_PREFIX/$IMAGE_DIR_TO_BUILD-buildimage-bases.txt"

# Clean artifacts
mkdir -p `dirname $ARTIFACTS_FILE`
> $ARTIFACTS_FILE

volumeHostDir="$ARTIFACTS_DIR/platformSdks"
volumeContainerDir="/tmp/sdk"
mkdir -p "$volumeHostDir"

buildImage() {
	local dockerFile="$1"
	local imageName="$2"
	echo "Building '$imageName'..."
	docker build -f "$dockerFile" -t $imageName $__REPO_DIR
	echo "$imageName" >> $ARTIFACTS_FILE
}

getCompressedSdk() {
	local dockerFile="$1"
	local imageName="$2"
	buildImage $dockerFile $imageName
	echo "Copying compressed sdk file to host directory..."
	docker run -v $volumeHostDir:$volumeContainerDir $imageName bash -c "cp -f /tmp/compressedSdk/* /tmp/sdk"
}

case $IMAGE_DIR_TO_BUILD in
	'python')
		echo "Building Python base images"
		echo

		docker build -f $BUILD_IMAGE_PREFIX/python/prereqs/Dockerfile -t "python-build-prereqs" $__REPO_DIR

		declare -r PYTHON_IMAGE_PREFIX="$ACR_DEV_NAME/public/oryx/python-build"
		getCompressedSdk $BUILD_IMAGE_PREFIX/python/2.7/Dockerfile "$PYTHON_IMAGE_PREFIX-2.7:$IMAGE_TAG"
		getCompressedSdk $BUILD_IMAGE_PREFIX/python/3.6/Dockerfile "$PYTHON_IMAGE_PREFIX-3.6:$IMAGE_TAG"
		getCompressedSdk $BUILD_IMAGE_PREFIX/python/3.7/Dockerfile "$PYTHON_IMAGE_PREFIX-3.7:$IMAGE_TAG"
		getCompressedSdk $BUILD_IMAGE_PREFIX/python/3.8/Dockerfile "$PYTHON_IMAGE_PREFIX-3.8:$IMAGE_TAG"
		;;
	'php')
		echo "Building PHP base images"
		echo

		docker build -f $BUILD_IMAGE_PREFIX/php/prereqs/Dockerfile -t "php-build-prereqs" $__REPO_DIR

		declare -r PHP_IMAGE_PREFIX="$ACR_DEV_NAME/public/oryx/php-build"
		getCompressedSdk $BUILD_IMAGE_PREFIX/php/5.6/Dockerfile "$PHP_IMAGE_PREFIX-5.6:$IMAGE_TAG"
		getCompressedSdk $BUILD_IMAGE_PREFIX/php/7.0/Dockerfile "$PHP_IMAGE_PREFIX-7.0:$IMAGE_TAG"
		getCompressedSdk $BUILD_IMAGE_PREFIX/php/7.2/Dockerfile "$PHP_IMAGE_PREFIX-7.2:$IMAGE_TAG"
		getCompressedSdk $BUILD_IMAGE_PREFIX/php/7.3/Dockerfile "$PHP_IMAGE_PREFIX-7.3:$IMAGE_TAG"
		;;
	'node')
		echo "Installing Node base image"
		echo
		declare -r NODE_IMAGE_PREFIX="$ACR_DEV_NAME/public/oryx/node-build"
		getCompressedSdk $BUILD_IMAGE_PREFIX/node/Dockerfile "$NODE_IMAGE_PREFIX:$IMAGE_TAG"
		;;            
	'yarn-cache')
		echo "Building Yarn package cache base image"
		echo

		YARN_CACHE_IMAGE_BASE="$ACR_DEV_NAME/public/oryx/build-yarn-cache"
		YARN_CACHE_IMAGE_NAME=$YARN_CACHE_IMAGE_BASE:$IMAGE_TAG

		docker build $BUILD_IMAGE_PREFIX/yarn-cache -t $YARN_CACHE_IMAGE_NAME
		echo $YARN_CACHE_IMAGE_NAME >> $ARTIFACTS_FILE
		;;
	*) echo "Unknown image directory";;
esac

echo
echo "List of images built (from '$ARTIFACTS_FILE'):"
cat $ARTIFACTS_FILE
echo
