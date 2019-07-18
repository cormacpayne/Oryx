#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

#set -e

ls -l /tmp/cores

echo
declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )
declare -r buildBuildImagesScript="$REPO_DIR/build/buildBuildImages.sh"
declare -r testProjectName="Oryx.BuildImage.Tests"

# Load all variables
source $REPO_DIR/build/__variables.sh

if [ "$1" = "skipBuildingImages" ]
then
    echo
    echo "Skipping building build images as argument '$1' was passed..."
else
    echo
    echo "Invoking script '$buildBuildImagesScript'..."
    $buildBuildImagesScript "$@"
fi

echo "Setting the core dump file size to unlimited..."
echo '/tmp/cores/core_%e.%p' | sudo tee /proc/sys/kernel/core_pattern
ulimit -c unlimited

echo
echo "Building and running tests..."
cd "$TESTS_SRC_DIR/$testProjectName"
dotnet test --test-adapter-path:. --logger:"xunit;LogFilePath=$ARTIFACTS_DIR\testResults\\$testProjectName.xml" -c $BUILD_CONFIGURATION

ls -l /tmp/cores