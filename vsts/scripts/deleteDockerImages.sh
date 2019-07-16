#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

#declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && cd .. && pwd )

printenv

source $BUILD_SOURCESDIRECTORY/vsts/scripts/__common.sh

StopAndDeleteAllContainers

PrintCurrentListOfImages

UntagImages "*:*"
UntagImages "*.*:*.*"

DockerSystemPrune

DeleteAllImages

PrintCurrentListOfImages