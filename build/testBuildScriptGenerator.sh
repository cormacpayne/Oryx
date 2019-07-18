#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )

# Load all variables
source $REPO_DIR/build/__variables.sh

echo
echo "Building and running tests..."
testProjectName="BuildScriptGenerator.Tests"
cd "$TESTS_SRC_DIR/$testProjectName"
dotnet test --test-adapter-path:. --logger:"xunit;LogFilePath=$TEST_RESULTS_DIR/$testProjectName.xml" -c $BUILD_CONFIGURATION

testProjectName="BuildScriptGeneratorCli.Tests"
cd "$TESTS_SRC_DIR/$testProjectName"
dotnet test --test-adapter-path:. --logger:"xunit;LogFilePath=$TEST_RESULTS_DIR/$testProjectName.xml" -c $BUILD_CONFIGURATION
