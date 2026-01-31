#!/usr/bin/env bash
set -eu

##
## reset-sds.sh
## 
## Reset the entire SDS environment (deletes containers, images and volumes)
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

#
# STOP THE CONTAINER
#
${THIS_SCRIPT_PATH}/sds-stop.sh

#
# DELETE ANY REGISTERED IMAGES 
#
printf_color "blue" "\nSDS images\n"
printf "  - Checking existing SDS images.... "
IMAGE_LIST=$(\
	docker image ls \
	"$SDS_SDS_DOCKER_NAME" \
	--format "{{.Repository}}:{{.Tag}}" \
	2>/dev/null\
)

if [[ -z "$IMAGE_LIST" ]]; then
    printf_color "green" "NONE FOUND\n"
else
    printf_color "green" "FOUND\n"
fi

for image in $IMAGE_LIST; do
	printf "    - Removing image................ "
    docker image rm "$image" > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		printf_color "red" "ERROR ($image)\n"
	else
		printf_color "green" "REMOVED ($image)\n"
	fi
done

#
# DELETE ROOT USER DIRECTORY VOLUME
#
printf_color "blue" "\nSDS root user volume\n"
printf "  - Checking SDS root user volume... "
set +e
docker volume inspect "$SDS_SDS_ROOT_VOLUME_NAME" &> /dev/null

if [[ $? -eq 0 ]]; then
    printf_color "green" "FOUND ($SDS_SDS_ROOT_VOLUME_NAME)\n"
    
	printf "    - Removing volume............... "
    if docker volume rm "$SDS_SDS_ROOT_VOLUME_NAME" > /dev/null 2>&1; then
        printf_color "green" "DELETED ($SDS_SDS_ROOT_VOLUME_NAME)\n"
    else
        printf_color "red" "ERROR: Could not delete volume '$SDS_SDS_ROOT_VOLUME_NAME'. It might be in use." >&2
    fi
else
    printf_color "green" "NONE FOUND ($SDS_SDS_ROOT_VOLUME_NAME)\n"
fi
printf "\n"