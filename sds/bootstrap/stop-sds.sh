#!/usr/bin/env bash
set -eu

##
## start-sds.main.sh
## 
## This scripts must run on the host machine to start the SDS container
## and then runs a bash shell inside the container
##

#
# INITIALIZE PATH AND PROJECT SPECIFIC CONFIG
#

if [ -z "${SDS_SDS_ROOT_PATH:-}" ]; then
  echo "Error: Env var \"SDS_SDS_ROOT_PATH\" is not set. Please set this variable before running this script."
  exit -1
fi

# Add the SDS utilities folder to the PATH
PATH=${PATH}:${SDS_SDS_ROOT_PATH}/opt/sds

# Load the project specific configuration (this file should be adjusted with per project settings)
source ${SDS_SDS_ROOT_PATH}/etc/sds_config

echo
printf_color "blue" "Checking SDS container status..."

if docker inspect --type=container ${SDS_SDS_CONTAINER_NAME} > /dev/null 2>&1; then
    # Container exists, now check its running status
    STATUS=$(docker inspect --format='{{.State.Status}}' ${SDS_SDS_CONTAINER_NAME})

    if [ "$STATUS" == "running" ]; then
		printf_color "green" "RUNNING\n"
		docker container stop \
			${SDS_SDS_CONTAINER_NAME}
	else
		printf_color "yellow" "$(echo "$STATUS" | tr '[:lower:]' '[:upper:]')\n"
		exit -1
	fi

	printf_color "blue" "Removing SDS container..."
	docker container rm \
		${SDS_SDS_CONTAINER_NAME}
	printf_color "green" "REMOVED\n"
	printf_color "blue" "\nDONE! Now, have some very well deserved rest!\n\nGood bye!\n\n\n"
else
	printf_color "yellow" "NOT FOUND\n"
	printf_color "blue" "Nothing to do. Good bye!\n\n\n"
fi


