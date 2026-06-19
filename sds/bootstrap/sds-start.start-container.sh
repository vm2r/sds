#!/usr/bin/env bash

##
## start-container.sh
## 
## Start the SDS docker container
##
## This script must run on the host machine, not inside the SDS container
##

THIS_SCRIPT_PATH=$(dirname $0)

#
# INITIALIZE PATH AND PROJECT SPECIFIC CONFIG
#
if [ -z "${SDS_SDS_ROOT_PATH_IN_HOST:-}" ]; then
    printf_color "red" "FATAL ERROR: Env var \"SDS_SDS_ROOT_PATH_IN_HOST\" is not set\n\n"
    printf_color "red" "Please set this variable before running this script ($0).\n\n"
    printf_color "red" "ABORTING\n\n"
    exit 1
fi

# Add the SDS utilities folder to the PATH
PATH=${PATH}:${SDS_SDS_ROOT_PATH_IN_HOST}/opt/sds

# Load sds configuration
source ${THIS_SCRIPT_PATH}/sds-check-config.sh


set +eu
TEMP_FILE=$(mktemp)
docker start ${SDS_SDS_DOCKER_NAME} > ${TEMP_FILE} 2>&1
if [[ $? -ne 0 ]]; then
    printf_color "red" "FAILED\n\n"
    cat ${TEMP_FILE}
    printf "\n\n"
    rm -f ${TEMP_FILE}
    exit -1
fi

printf_color "green" "STARTED\n"
rm -f ${TEMP_FILE}
set -eu

