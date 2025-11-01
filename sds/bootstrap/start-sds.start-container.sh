#!/usr/bin/env bash

#
# start-container.sh
#
# This script is used to start the SDS container
#

set +eu
TEMP_FILE=$(mktemp)
docker start ${SDS_SDS_CONTAINER_NAME} > ${TEMP_FILE} 2>&1
if [[ $? -eq 0 ]]; then
    printf_color "green" "STARTED\n"
else
    printf_color "red" "FAILED\n\n"
    cat ${TEMP_FILE}
    printf "\n\n"
    rm -f ${TEMP_FILE}
    exit -1
fi
set -eu

