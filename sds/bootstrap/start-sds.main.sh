#!/usr/bin/env bash
set -eu

##
## start-sds.main.sh
## 
## This scripts must run on the host machine to start the SDS container
## and then runs a bash shell inside the container
##

THIS_SCRIPT_EXECUTION_DIR=$(dirname $0)

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


if [ -z "${SDS_REPO_ROOT_PATH:-}" ]; then
  printf_color "red" "Error: Env var \"SDS_REPO_ROOT_PATH\" is not set. Please set this variable before running this script.\n"
  exit -1
fi

if [ -z "${SDS_SDS_ROOT_PATH_IN_CONTAINER:-}" ]; then
  printf_color "red" "Error: Env var \"SDS_SDS_ROOT_PATH_IN_CONTAINER\" is not set. Please set this variable before running this script.\n"
  exit -1
fi

if [ -z "${SDS_VOLUMES_MAPPING:-}" ]; then
  printf_color "red" "Error: Env var \"SDS_VOLUMES_MAPPING\" is not set. Please set this variable before running this script.\n"
  exit -1
fi


#
# PROCESS COMMAND LINE ARGUMENTS
#

# Set defaults command line arguments values
export SDS_RUN_VERSION_TARGET="prod"
export SDS_RUN_HELPERS_SOURCE="container"
export SDS_RUN_IMAGE_LOCATION="remote"

# Process command line arguments
while (($# > 0)); do
  case "$1" in
    --image-tag)
        # The Docker image tag to use for the SDS container
        export SDS_RUN_VERSION_TARGET="${2:-prod}"
        shift
        ;;

    --helpers-source)
        # Maps to the folder where the helper scripts are located
        # Valid values are "repo" and "container"
        export SDS_RUN_HELPERS_SOURCE="${2:-container}"
        shift
        ;;

    --image-location)
        # The location of the SDS Docker image
        # Valid values are "remote" to pull the image from the remote repository
        # or the name of the image in the local repository
        export SDS_RUN_IMAGE_LOCATION="${2:-remote}"
        shift
        ;;

    *)
        echo "${0}: Unknown argument: '${1}'"
        exit 1
        ;;
  esac
  shift
done


# Decides which bashrc to use based on command line argument "helpers" passed to this script
case "${SDS_RUN_HELPERS_SOURCE}" in
    ""|container)
        export BASHRC_FILE="/etc/bashrc"
        ;;
    repo)
        export BASHRC_FILE="${SDS_SDS_ROOT_PATH_IN_CONTAINER}/etc/bashrc"
        ;;
    *)
        printf_color "red" "\n\nERROR: Invalid value '${SDS_RUN_HELPERS_SOURCE}' for option "helpers"\n\n"
        exit -1
        ;;
esac

# Decides which image location to use based on command line argument "image-location" passed to this script
case "${SDS_RUN_IMAGE_LOCATION}" in
    ""|remote)
        # The default image location is the remote repository

        # Use the default remote image URL (just ensure it's set)
        if [[ -z "${SDS_SDS_IMAGE_URL+x}" || -z "$SDS_SDS_IMAGE_URL" ]]; then
            printf_color "red" "\n\n\tFATAL: Environment variable SDS_SDS_IMAGE_URL must be previously set and exported\n\n"
            exit -1
        fi
        ;;

    *)
        # If provided, the image name in the local repository
        export SDS_SDS_IMAGE_URL="${SDS_RUN_IMAGE_LOCATION}"
        ;;
esac


#
# EXTERNAL VARIABLES THAT MUST ME SET AND EXPORTED BY THE CALLING SCRIPT
#
if [[ "${SDS_RUN_IMAGE_LOCATION}" == "remote" ]]; then
    if ! test -n "${SDS_SDS_IMAGE_URL+x}" ; then
        printf_color "red" "\n\n\tFATAL: Environment variable SDS_SDS_IMAGE_URL must be set in the sds/etc/sds_config file\n\n"
        exit -1
    fi
fi


#
# GLOBAL VARIABLES
#

# SDS_HOST_UNAME is sent to the container as an ENVVAR, so it knows the OS it's running on
export SDS_HOST_UNAME="$(uname -a)"
export SDS_START_DIR=`git rev-parse --show-prefix | sed 's/.$$//'`

printf "\n\n"
printf_color "blue" "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\n" 
printf_color "blue" "= =                                                                 = =\n"
printf_color "blue" "= =              PREPARING TO BUILD GREAT THINGS!!!                 = =\n" 
printf_color "blue" "= =       Initializing the SDS - Standardized Development Stack     = =\n"
printf_color "blue" "= =                                                                 = =\n"
printf_color "blue" "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\n"
printf "\n\n"


##
## CHECK IF DOCKER IS RUNNING
##
set +eu
printf_color "blue" "Checking Docker installation\n" 

printf "  - Checking if the Docker daemon is running..... "
docker info > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    printf_color "green" "OK\n"
else
    printf_color "red" "ERROR\n\n\tDOCKER DESKTOP IS NOT RUNNING\n\n\n"
    exit -1
fi

set -eu


##
## START THE SDS ENVIRONMENT
##
printf_color "blue" "\nPulling SDS Image SDS\n"

#
# PULL THE SDS IMAGE
#
if [[ "${SDS_RUN_IMAGE_LOCATION}" == "remote" ]]; then
    printf "  - Pulling SDS Docker image (${SDS_RUN_VERSION_TARGET})\n"
    printf "    - Image: ${SDS_SDS_IMAGE_URL}\n"
    printf "    - Tag  : ${SDS_RUN_VERSION_TARGET}\n\n"

    docker pull ${SDS_SDS_IMAGE_URL}:${SDS_RUN_VERSION_TARGET}
else
    printf "  - Using local SDS Docker image (${SDS_RUN_VERSION_TARGET})\n"
    printf "    - Image: ${SDS_SDS_IMAGE_URL}\n"
    printf "    - Tag  : ${SDS_RUN_VERSION_TARGET}\n\n"
fi

#
# CHECK IF THE SDS CONTAINER EXISTS AND IS RUNNING
#
printf_color "blue" "\nStarting SDS container\n"

printf "  - Container name: ${SDS_SDS_CONTAINER_NAME}\n"
printf "  - Checking container status... "
if docker inspect --type=container ${SDS_SDS_CONTAINER_NAME} > /dev/null 2>&1; then
    # Container exists, now check its running status
    STATUS=$(docker inspect --format='{{.State.Status}}' ${SDS_SDS_CONTAINER_NAME})

    if [ "$STATUS" == "running" ]; then
        printf_color "green" "RUNNING\n"
    else
        printf_color "yellow" "$(echo "$STATUS" | tr '[:lower:]' '[:upper:]')\n"
        printf "    - Starting container........ "
        ${THIS_SCRIPT_EXECUTION_DIR}/start-sds.start-container.sh
    fi
else
    # Container does not exist, so we need to launch it
    printf_color "yellow" "NOT FOUND\n"
    printf "    - Launching container....... "

    ${THIS_SCRIPT_EXECUTION_DIR}/start-sds.run-container.sh ${SDS_VOLUMES_MAPPING[@]}
    
    if [[ $? -eq 0 ]]; then
        printf_color "green" "LAUNCHED\n"
    else
        printf_color "red" "FAILED\n"
        exit -1
    fi
fi

##
## START THE SDS SHELL
##
printf_color "blue" "\nStarting SDS shell\n"
set +e

printf "  - .bashrc path: ${BASHRC_FILE}" 

printf "\n\n"
docker exec -it \
    --env SDS_START_DIR=${SDS_START_DIR} \
    sds-container \
    bash --rcfile ${BASHRC_FILE}

printf_color "blue" "\n\n\tMAGIC HAS BEEN MASTERFULLY PERFORMED!!!\n\n"
printf_color "blue" "\tNow, have some very well deserved rest!\n\n\tGood bye!\n\n\n"
