#!/usr/bin/env bash

#
# run-container.sh
#
# This script is used to run the SDS container
#


SDS_VOLUMES_MAPPING=$@

ROOT_VOLUME_NAME="sds-root-volume"

DEFAULT_VOLUMES_MAPPING=(
    "${HOME}/.gitconfig:/mnt/host/.gitconfig"
    "${HOME}/.ssh:/mnt/host/.ssh"
)
SDS_VOLUMES_MAPPING="${SDS_VOLUMES_MAPPING} ${DEFAULT_VOLUMES_MAPPING[@]}"

VOLUMES_ARGS=""
for mapping in ${SDS_VOLUMES_MAPPING}; do
    host_path="${mapping%%:*}"
    container_path="${mapping#*:}"
    VOLUMES_ARGS+=" --mount type=bind,source=${host_path},destination=${container_path}"
done


# ENVIRONMENT VARIABLES ARGUMENTS
DOCKER_ENV_FILE=$(mktemp)
touch ${DOCKER_ENV_FILE}
SDS_ENV_VARS=(
    "SDS_HOST_UNAME"
    "SDS_START_DIR"
    "SDS_RUN_HELPERS_SOURCE"
    "SDS_RUN_VERSION_TARGET"
)
ENV_ARGS=""
for var in "${SDS_ENV_VARS[@]}"; do
    # Append the --env flag and the variable assignment to the args string
    escaped_var=$(echo "${!var}" | sed 's/\ /\\ /g' | sed 's/:/\\:/g' | sed 's/\./\\./g')
    echo "${var}=${escaped_var}" >> ${DOCKER_ENV_FILE}
done

# CAPABILITIES ARGUMENTS
SDS_CAPABILITIES=(
    "SYS_ADMIN"
    "NET_ADMIN"
    "SYSLOG"
)
CAPABILITIES_ARGS=""
for capability in "${SDS_CAPABILITIES[@]}"; do
    CAPABILITIES_ARGS+=" --cap-add ${capability}"
done

# TCP PORT ARGUMENTS
TCP_PORTS=(
    "8000-8010"
    "8080"
    "55432"
    "33306"
)
TCP_PORTS_ARGS=""
for port in "${TCP_PORTS[@]}"; do
    TCP_PORTS_ARGS+=" --publish ${port}:${port}"
done

# Create the root volume
docker volume create ${ROOT_VOLUME_NAME}

# Start the SDS container
docker run -d \
    --name ${SDS_SDS_CONTAINER_NAME} \
    --platform linux/amd64 \
    ${TCP_PORTS_ARGS} \
    --env-file ${DOCKER_ENV_FILE} \
    --workdir /sds \
    ${VOLUMES_ARGS} \
    --mount type=volume,source=${ROOT_VOLUME_NAME},destination=/root \
    ${CAPABILITIES_ARGS} \
    ${SDS_SDS_IMAGE_URL}:${SDS_RUN_VERSION_TARGET} > /dev/null

    # --device /dev/fuse \
    # --workdir /$SDS_SDS_ROOT_PATH_IN_CONTAINER \

RESULT=$?

rm -f ${DOCKER_ENV_FILE}

exit ${RESULT}