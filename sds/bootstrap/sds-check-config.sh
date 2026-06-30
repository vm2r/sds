#!/usr/bin/env bash
set -eu

##
## sds-check-config.sh
## 
## This script contains utility functions used by the other scripts in this folder
##

#
# Load the repo specific configuration from file "sds.conf"
#

if [ -z "${SDS_SDS_ROOT_PATH_IN_HOST:-}" ]; then
    printf_color "red" "FATAL ERROR: Env var \"SDS_SDS_ROOT_PATH_IN_HOST\" is not set\n\n"
    printf_color "red" "Please set this variable before running this script ($0).\n\n"
    printf_color "red" "ABORTING\n\n"
    exit 1
fi

#
# Check if all configuration variables have been set in sds.conf
#
MANDATORY_VARS=(
    "REPO_ROOT_PATH"
    "REPO_NAME"
    "SDS_SDS_DOCKER_NAME"
    "SDS_SDS_ROOT_PATH_IN_CONTAINER"
    "SDS_ALL_VOLUMES_MAPPING"
)

for var in "${MANDATORY_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        printf_color "red" "FATAL ERROR: Env var \"${var}\" must be set in file \"${SDS_SDS_ROOT_PATH_IN_HOST}/sds.setenv.sh\".\n\n"
        printf_color "red" "ABORTING\n\n"
        exit 102
    fi
done

#
# Set internal variables
#

