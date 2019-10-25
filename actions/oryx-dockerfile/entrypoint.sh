#!/bin/sh -l

sourceDirectory=$1
outputDockerfile=$2
platform=$3
platformVersion=$4

echo

if [ -n "${sourceDirectory}" ]
then
    echo "Source directory provided : ${sourceDirectory}"
else
    sourceDirectory=$PWD
    echo "No source directory provided -- using the current working directory: ${sourceDirectory}"
fi

oryxCommand="oryx build ${sourceDirectory}"

echo

if [ -n "${outputDockerfile}" ]
then
    echo "Output Dockerfile provided: '${outputDockerfile}'"
else
    echo "No output Dockerfile provided -- the generated Dockerfile will be written to Dockerfile.oryx in the source directory."
    outputDockerfile="${sourceDirectory}/Dockerfile.oryx"
fi

oryxCommand="${oryxCommand} --output ${outputDockerfile}"

echo

if [ -n "${platform}" ]
then
    echo "Platform provided: '${platform}'"
    oryxCommand="${oryxCommand} --platform ${platform}"
else
    echo "No platform provided -- Oryx will enumerate the repository to determine the platform."
fi

echo

if [ -n "${platformVersion}" ]
then
    echo "Platform version provided: '${platformVersion}'"
    oryxCommand="${oryxCommand} --platform-version ${platformVersion}"
else
    echo "No platform version provided -- Oryx will determine the version."
fi

echo
echo "Running command '${oryxCommand}'"
eval $oryxCommand

echo ::set-output name=dockerfilePath::$outputDockerfile