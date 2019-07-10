#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

function UntagImages() {
	local imagePattern=$1
	local imagesToUntag=$(docker images --filter=reference="$imagePattern" --format "{{.Repository}}:{{.Tag}}")

	echo
	echo "Found following images having the pattern '$imagePattern'. Untagging them ..."
	echo $imagesToUntag
	echo

	if [ ! -z "$imagesToUntag" ]
	then
		docker rmi -f $imagesToUntag
	fi
}

function StopAndDeleteAllContainers() {
    echo
    echo "Printing all running containers and stopped containers"
    echo
    docker ps -a 
    echo
    echo "Kill all running containers and delete all stopped containers"
    echo
    docker kill $(docker ps -q)
    docker rm -f $(docker ps -a -q)
}

function PrintCurrentListOfImages() {
    echo
    echo "Current list of docker images:"
    echo
    docker images
}

function DeleteAllImages() {
    echo
    echo "Deleting all images..."
    echo
    docker rmi $(docker images -a -q)
}

function DockerSystemPrune() {
    echo
    echo "Running docker system prune..."
    echo
    docker system prune -f
}