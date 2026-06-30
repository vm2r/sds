#!/usr/bin/env bash

##
## run-container.sh
##
## Run the SDS docker container
## Assumes the image was previously built
## Creates the root volume if needed
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

#
# PREPARE THE SDS CONTAINER CONFIGURATION
#
DOCKER_ENV_FILE=$(mktemp)
touch ${DOCKER_ENV_FILE}

# Volumes from host to be mounted in the container
# Format: <host_path>:<container_path>



VOLUMES_ARGS=""
for mapping in ${SDS_ALL_VOLUMES_MAPPING}; do
    host_path="${mapping%%:*}"
    container_path="${mapping#*:}"
    VOLUMES_ARGS+=" --mount type=bind,source=${host_path},destination=${container_path}"
done

# Environment variables to be passed to the container
SDS_ENV_VARS=(
    "SDS_HOST_UNAME"
    "SDS_START_DIR"
    "SDS_RUN_VERSION_TARGET"
)
ENV_ARGS=""
for var in "${SDS_ENV_VARS[@]}"; do
    # Append the --env flag and the variable assignment to the args string
    escaped_var=$(echo "${!var}" | sed 's/\ /\\ /g' | sed 's/:/\\:/g' | sed 's/\./\\./g')
    echo "${var}=${escaped_var}" >> ${DOCKER_ENV_FILE}
done

# Capabilities to be added to the container
SDS_CAPABILITIES=(
    "SYS_ADMIN"
    "NET_ADMIN"
    "SYSLOG"
)
CAPABILITIES_ARGS=""
for capability in "${SDS_CAPABILITIES[@]}"; do
    CAPABILITIES_ARGS+=" --cap-add ${capability}"
done

# TCP ports to be published
tcp_ports_args=""
if [ -n "${SDS_TCP_PORTS_PUBLISH:-}" ]; then
    for port in "${SDS_TCP_PORTS_PUBLISH[@]}"; do
        tcp_ports_args+=" --publish ${port}:${port}"
    done
fi

#
# CREATE THE SDS CONTAINER
#

# Create the root volume
docker volume create ${SDS_SDS_ROOT_VOLUME_NAME} > /dev/null 2>&1

if [ $? -ne 0 ]; then
    printf_color "red" "FATAL ERROR: Failed to create volume \"${SDS_SDS_ROOT_VOLUME_NAME}\".\n"
    exit 6
fi

# Start the SDS container
echo ${VOLUMES_ARGS}
docker run -d \
    --name ${SDS_SDS_DOCKER_NAME} \
    ${tcp_ports_args} \
    --env-file ${DOCKER_ENV_FILE} \
    --workdir /${REPO_NAME} \
    ${VOLUMES_ARGS} \
    --mount type=volume,source=${SDS_SDS_ROOT_VOLUME_NAME},destination=/root \
    ${CAPABILITIES_ARGS} \
    ${SDS_SDS_DOCKER_NAME}:${SDS_RUN_VERSION_TARGET} > /dev/null

RESULT=$?
rm -f ${DOCKER_ENV_FILE}

if [ $? -ne 0 ]; then
    printf_color "red" "FATAL ERROR: Container \"${SDS_SDS_DOCKER_NAME}\" failed to start (Docker error: $RESULT).\n"
    exit 7
fi
