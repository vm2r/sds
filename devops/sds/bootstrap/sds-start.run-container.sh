#!/usr/bin/env bash

#
# run-container.sh
#
# This script is used to run the SDS container
#

if [ -z "${SDS_ROOT_IN_HOST:-}" ]; then
    echo "Error: Env var \"SDS_ROOT_IN_HOST\" is not set. Please set this variable before running this script ($0)."
    exit 1
fi

# Load the project specific configuration (this file should be adjusted with per project settings)
source ${SDS_ROOT_IN_HOST}/etc/sds_config

#
# VERIFY THE REQUIRED ENVIRONMENT VARIABLES ARE SET
#
if [ -z "${SDS_SDS_ROOT_VOLUME_NAME:-}" ]; then
    echo "Error: Env var \"SDS_SDS_ROOT_VOLUME_NAME\" must be set in file \"${SDS_ROOT_IN_HOST}/etc/sds_config\"."
    exit 2
fi

if [ -z "${SDS_VOLUMES_MAPPING:-}" ]; then
    echo "Error: Env var \"SDS_VOLUMES_MAPPING\" must be set in file \"${SDS_ROOT_IN_HOST}/etc/sds_config\"."
    exit 3
fi

if [ -z "${SDS_SDS_DOCKER_NAME:-}" ]; then
    echo "Error: Env var \"SDS_SDS_DOCKER_NAME\" must be set in file \"${SDS_ROOT_IN_HOST}/etc/sds_config\"."
    exit 4
fi

#
# PREPARE THE SDS CONTAINER CONFIGURATION
#
DOCKER_ENV_FILE=$(mktemp)
touch ${DOCKER_ENV_FILE}

# Volumes from host to be mounted in the container
DEFAULT_VOLUMES_MAPPING=(
    "${HOME}/.gitconfig:/mnt/host/.gitconfig"
    "${HOME}/.ssh:/mnt/host/.ssh"
    "${SDS_ROOT_IN_HOST}:${SDS_SDS_ROOT_PATH_IN_CONTAINER}"
)
SDS_VOLUMES_MAPPING="${SDS_VOLUMES_MAPPING[@]} ${DEFAULT_VOLUMES_MAPPING[@]}"

VOLUMES_ARGS=""
for mapping in ${SDS_VOLUMES_MAPPING}; do
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
if [ -z "${SDS_TCP_PORTS_PUBLISH}" ]; then
    printf_color "yellow" "Variable \"SDS_TCP_PORTS_PUBLISH\" must be set in sds_config.\n"
    exit 5
fi

TCP_PORTS_ARGS=""
for port in "${SDS_TCP_PORTS_PUBLISH[@]}"; do
    TCP_PORTS_ARGS+=" --publish ${port}:${port}"
done

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
docker run -d \
    --name ${SDS_SDS_DOCKER_NAME} \
    --platform linux/amd64 \
    ${TCP_PORTS_ARGS} \
    --env-file ${DOCKER_ENV_FILE} \
    --workdir /sds \
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
