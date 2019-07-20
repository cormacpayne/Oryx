#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && cd .. && pwd )

declare -r BUILD_NUMBER="$BUILD_BUILDNUMBER"
declare -r DOCKER_SYSTEM_PRUNE="${ORYX_DOCKER_SYSTEM_PRUNE:-false}"

source $REPO_DIR/vsts/scripts/__common.sh

StopAndDeleteAllContainers

PrintCurrentListOfImages

# An image that is built in our pipelines is tagged with 'latest' and 'build number'.
# The following is to untag an image with the 'build number' tag so that when the next time
# images are built, the older images can become dangled which can later be cleaned up.
#
# **NOTE**
# - We still keep the tags of the following pattern because we still need some cache so that next builds are faster
#	a. oryxdevmcr.azurecr.io/public/oryx/*:latest
# - We should untag these images only after they have been pushed to a remote repository.
UntagImages "test-*"
UntagImages "oryxdevms/*:*.*"
UntagImages "oryxdevms/*:latest"
UntagImages "oryxtests/*:latest"
UntagImages "oryxprod/*:latest"
UntagImages "oryxprod/*:*.*"
UntagImages "oryxdevmcr.azurecr.io/public/oryx/*:*.*"
UntagImages "oryxmcr.azurecr.io/public/oryx/*:latest"
UntagImages "oryxmcr.azurecr.io/public/oryx/*:*.*"
UntagImages "mcr.microsoft.com/oryx/*:20190417.1"
UntagImages "mcr.microsoft.com/oryx/*:20190506.1"
UntagImages "mcr.microsoft.com/oryx/*:20190506.2"
UntagImages "mcr.microsoft.com/oryx/*:20190506.3"
UntagImages "mcr.microsoft.com/oryx/*:20190506.4"
UntagImages node:4.4.7
UntagImages node:4.5.0
UntagImages node:4.8.7
UntagImages node:6.2.2
UntagImages node:6.6.0
UntagImages node:6.9.5
UntagImages node:6.10.3
UntagImages node:6.11.5
UntagImages node:8.0.0
UntagImages node:8.1.4
UntagImages node:8.2.1
UntagImages node:8.8.1
UntagImages node:8.9.4

PrintCurrentListOfImages

echo
echo "Cleanup: Run 'docker system prune': $DOCKER_SYSTEM_PRUNE"
if [ "$DOCKER_SYSTEM_PRUNE" == "true" ]
then
    DockerSystemPrune

    PrintCurrentListOfImages
fi