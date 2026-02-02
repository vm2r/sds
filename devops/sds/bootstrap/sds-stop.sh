#!/usr/bin/env bash
set -eu

##
## sds-stop.sh
## 
## Stop and remove the SDS docker container
## It doesn't delete images or volumes
##
## This script must run on the host machine, not inside the SDS container
##

THIS_SCRIPT_PATH=$(dirname $0)

#
# INITIALIZE PATH AND PROJECT SPECIFIC CONFIG
#
if [ -z "${SDS_ROOT_IN_HOST:-}" ]; then
    printf_color "red" "FATAL ERROR: Env var \"SDS_ROOT_IN_HOST\" is not set\n\n"
    printf_color "red" "Please set this variable before running this script ($0).\n\n"
    printf_color "red" "ABORTING\n\n"
    exit 1
fi

# Add the SDS utilities folder to the PATH
PATH=${PATH}:${SDS_ROOT_IN_HOST}/opt/sds

# Load sds configuration
source ${THIS_SCRIPT_PATH}/sds-load-config.sh

function docker_stop() {
	docker container stop ${1} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		printf_color "red" "FATAL ERROR: Failed to stop container \"${1}\".\n\n"
		printf_color "red" "ABORTING\n\n"
		exit -1
	fi
}

function docker_rm() {
	docker container rm ${1} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		printf_color "red" "FATAL ERROR: Failed to remove container \"${1}\".\n\n"
		printf_color "red" "ABORTING\n\n"
		exit -1
	fi
}

printf "\n"
printf_color "blue" "SDS containers\n"
printf "  - Checking SDS container status... "

set +e 
if docker inspect --type=container ${SDS_SDS_DOCKER_NAME} > /dev/null 2>&1; then
    # Container exists, now check its running status
    STATUS=$(docker inspect --format='{{.State.Status}}' ${SDS_SDS_DOCKER_NAME})

    if [ "$STATUS" == "running" ]; then
		printf_color "green" "RUNNING (${SDS_SDS_DOCKER_NAME})\n"

		printf "    - Stopping SDS container........ "
		docker_stop ${SDS_SDS_DOCKER_NAME}
		printf_color "green" "STOPPED (${SDS_SDS_DOCKER_NAME})\n"
	else
		printf_color "yellow" "$(echo "$STATUS" | tr '[:lower:]' '[:upper:]')\n"
	fi

	printf "    - Removing container............ "
	docker_rm ${SDS_SDS_DOCKER_NAME}
	printf_color "green" "REMOVED (${SDS_SDS_DOCKER_NAME})\n"
else
	printf_color "green" "NONE FOUND (${SDS_SDS_DOCKER_NAME})\n"
fi


