#!/bin/bash
set -e

declare -r __REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )

# VSTS environment variables
declare -r BUILD_NUMBER="$BUILD_BUILDNUMBER"
declare -r BUILD_CONFIGURATION="${BUILDCONFIGURATION:-Debug}"

declare -r BUILD_IMAGES_BUILD_CONTEXT_DIR="$__REPO_DIR/"
declare -r BUILD_IMAGES_DOCKERFILE="$__REPO_DIR/images/build/Dockerfile"
declare -r BUILD_IMAGES_SLIM_DOCKERFILE="$__REPO_DIR/images/build/slim.Dockerfile"
declare -r PACK_IMAGE_DOCKERFILE="$__REPO_DIR/images/pack-builder/pack-runner.Dockerfile"
declare -r ORYXTESTS_BUILDIMAGE_DOCKERFILE="$__REPO_DIR/tests/images/build/Dockerfile"
declare -r ORYXTESTS_SLIM_BUILDIMAGE_DOCKERFILE="$__REPO_DIR/tests/images/build/slim.Dockerfile"
declare -r RUNTIME_IMAGES_SRC_DIR="$__REPO_DIR/images/runtime"
declare -r RUNTIME_BASE_IMAGE_DOCKERFILE_PATH="$RUNTIME_IMAGES_SRC_DIR/commonbase/Dockerfile"
declare -r RUNTIME_BASE_IMAGE_NAME="oryx-run-base"
declare -r SOURCES_SRC_DIR="$__REPO_DIR/src"
declare -r TESTS_SRC_DIR="$__REPO_DIR/tests"

declare -r ARTIFACTS_DIR="$__REPO_DIR/artifacts"
declare -r BUILD_IMAGES_ARTIFACTS_FILE="$ARTIFACTS_DIR/images/build-images.txt"
declare -r BASE_IMAGES_ARTIFACTS_FILE_PREFIX="$ARTIFACTS_DIR/images"
declare -r RUNTIME_IMAGES_ARTIFACTS_FILE="$ARTIFACTS_DIR/images/runtime-images.txt"
declare -r ACR_BUILD_IMAGES_ARTIFACTS_FILE="$ARTIFACTS_DIR/images/build-images-acr.txt"
declare -r ACR_RUNTIME_IMAGES_ARTIFACTS_FILE="$ARTIFACTS_DIR/images/runtime-images-acr.txt"

declare -r PACK_IMAGE_NAME='pack'
declare -r PACK_STACK_BASE_IMAGE_NAME="pack-stack-base"
declare -r PACK_BUILDER_IMAGE_NAME="pack-builder"
declare -r ORYXTESTS_BUILDIMAGE_REPO="oryxtests/build"
declare -r ORYXTESTS_SLIM_BUILDIMAGE_REPO="oryxtests/build-slim"

declare -r DEVBOX_BUILD_IMAGES_REPO="oryx/build"
declare -r DEVBOX_SLIM_BUILD_IMAGE_REPO="oryx/build-slim"
declare -r DEVBOX_RUNTIME_IMAGES_REPO_PREFIX="oryx"

declare -r ACR_DEV_NAME="oryxdevmcr.azurecr.io"
declare -r ACR_PUBLIC_PREFIX="$ACR_DEV_NAME/public/oryx"
declare -r ACR_BUILD_IMAGES_REPO="$ACR_DEV_NAME/public/oryx/build"
declare -r ACR_SLIM_BUILD_IMAGE_REPO="$ACR_DEV_NAME/public/oryx/build-slim"
declare -r ACR_RUNTIME_IMAGES_REPO="$ACR_PUBLIC_PREFIX"
declare -r ACR_PACK_IMAGE_REPO="$ACR_PUBLIC_PREFIX/$PACK_IMAGE_NAME"

# Flag to add information to images through labels (example: build number, commit sha)
declare -r EMBED_BUILDCONTEXT_IN_IMAGES="${EMBEDBUILDCONTEXTINIMAGES:-false}"
declare -r GIT_COMMIT=$(git rev-parse HEAD)

declare -r DOCKER_SYSTEM_PRUNE="${ORYX_DOCKER_SYSTEM_PRUNE:-false}"

# If build_number has value that means we are building in build agent and not locally
if [ -n "$BUILD_NUMBER" ]; then
    declare -r AGENT_BUILD="true"
fi