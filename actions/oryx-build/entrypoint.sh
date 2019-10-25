#!/bin/sh -l

sourceDirectory=$1
outputDirectory=$2
platform=$3
platformVersion=$4

if [ -n "${sourceDirectory}" ]
then
    echo -e "Source directory provided : ${sourceDirectory}\n"
else
    sourceDirectory=$PWD
    echo -e "No source directory provided -- using the current working directory: ${sourceDirectory}\n"
fi

oryxCommand="oryx build ${sourceDirectory}"

if [ -n "${outputDirectory}" ]
then
    echo -e "Output directory provided: '${outputDirectory}'\n"
    oryxCommand="${oryxCommand} --output ${outputDirectory}"
else
    echo -e "No output directory provided -- the source directory will be used as the output directory.\n"
fi

if [ -n "${platform}" ]
then
    echo -e "Platform provided: '${platform}'\n"
    oryxCommand="${oryxCommand} --platform ${platform}"
else
    echo -e "No platform provided -- Oryx will enumerate the repository to determine the platform.\n"
fi

if [ -n "${platformVersion}" ]
then
    echo -e "Platform version provided: '${platformVersion}'\n"
    oryxCommand="${oryxCommand} --platform-version ${platformVersion}"
else
    echo -e "No platform version provided -- Oryx will determine the version.\n"
fi

echo -e "Running command '${oryxCommand}'\n"
eval $oryxCommand

echo ::set-output name=outputDirectory::$outputDirectory