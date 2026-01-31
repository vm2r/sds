#!/usr/bin/env bash
set -eu

##
## sds-load-config.sh
## 
## This script contains utility functions used by the other scripts in this folder
##

#
# Load the repo specific configuration from file "sds.conf"
#

if [ -z "${SDS_ROOT_IN_HOST:-}" ]; then
    printf_color "red" "FATAL ERROR: Env var \"SDS_ROOT_IN_HOST\" is not set\n\n"
    printf_color "red" "Please set this variable before running this script ($0).\n\n"
    printf_color "red" "ABORTING\n\n"
    exit 1
fi

if [ ! -f "${SDS_ROOT_IN_HOST}/etc/sds.conf" ]; then
    printf_color "red" "\nFATAL ERROR: 'sds.conf' file not found in ${SDS_ROOT_IN_HOST}/etc\n"
    printf_color "red" "Please, create it from a copy of 'sds.conf.example' before running this script ($0).\n\n"
    printf_color "red" "ABORTING\n\n"
    exit 101
fi

source "${SDS_ROOT_IN_HOST}/etc/sds.conf"
source "${SDS_ROOT_IN_HOST}/etc/sds.env"

#
# Check if all configuration variables have been set in sds.conf
#
MANDATORY_VARS=(
    "SDS_SDS_DOCKER_NAME"
    "SDS_SDS_ROOT_PATH_IN_CONTAINER"
)

for var in "${MANDATORY_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        printf_color "red" "FATAL ERROR: Env var \"${var}\" must be set in file \"${SDS_ROOT_IN_HOST}/etc/sds.conf\".\n\n"
        printf_color "red" "ABORTING\n\n"
        exit 102
    fi
done

#
# Set internal variables
#

# The name of the volume that will be created to persist root folder in the container
export SDS_SDS_ROOT_VOLUME_NAME="${SDS_SDS_DOCKER_NAME}-root-volume"