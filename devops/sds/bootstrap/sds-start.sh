#!/usr/bin/env bash
set -eu

##
## start-sds.main.sh
## 
## Start the SDS environment and provides a terminal console in the container
## Build images, create volumes, start and run containers as needed
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
# PROCESS COMMAND LINE ARGUMENTS
#

# Set defaults command line arguments values
export SDS_RUN_VERSION_TARGET="latest"

# Process command line arguments
while (($# > 0)); do
  case "$1" in
    --image-tag)
        # The Docker image tag to use for the SDS container
        export SDS_RUN_VERSION_TARGET="${2:-latest}"
        shift
        ;;

    *)
        printf_color "red" "\n\nError: Unknown argument: '${1}'\n\n"
        exit 4
        ;;
  esac
  shift
done



#
# GLOBAL VARIABLES
#

# SDS_HOST_UNAME is sent to the container as an ENVVAR, so it knows the OS it's running on
export SDS_HOST_UNAME="$(uname -a)"
export SDS_START_DIR=`git rev-parse --show-prefix | sed 's/.$$//'`

# The BASHRC to use
export BASHRC_FILE="${SDS_SDS_ROOT_PATH_IN_CONTAINER}/etc/sds.bashrc"

printf "\n\n"
printf_color "blue" "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\n" 
printf_color "blue" "= =                                                       = =\n"
printf_color "blue" "= =            PREPARING TO BUILD GREAT THINGS!!!         = =\n" 
printf_color "blue" "= =             Standardized  Development  Stack          = =\n"
printf_color "blue" "= =                                                       = =\n"
printf_color "blue" "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\n"

printf "\n\n"

printf_color "blue" "=============================================================\n"
printf_color "blue" "                  INITIALIZING SDS CONTAINER                 \n"
printf_color "blue" "=============================================================\n"
printf "\n"


##
## CHECK IF DOCKER IS RUNNING
##
set +eu
printf_color "blue" "Docker installation\n" 

printf "  - Checking Docker daemon status... "
docker info > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    printf_color "green" "RUNNING\n"
else
    printf_color "red" "NOT RUNNING\n\n\tACTION NEEDED: Ensure Docker Desktop is running\n\n\n"
    exit 5
fi

set -eu


##
## CHECK THE SDS IMAGE
##
printf_color "blue" "\nSDS Docker Image\n"

#
# Check if the SDS image exists
#
printf "  - Target Docker image\n"
printf "    - Name: ${SDS_SDS_DOCKER_NAME}\n"
printf "    - Tag : ${SDS_RUN_VERSION_TARGET}\n\n"

local_image_full="${SDS_SDS_DOCKER_NAME}:${SDS_RUN_VERSION_TARGET}"
dockerfile_path="${SDS_ROOT_IN_HOST}/image-builder/Dockerfile"
build_script="${SDS_ROOT_IN_HOST}/image-builder/build-local.sh"

# Check if build script exists
if [ ! -f "${build_script}" ]; then
    printf_color "red" "\n\nError: Build script not found at ${build_script}\n"
    exit 6
fi

# Check if image exists
printf "  - Looking for Docker image........ "
if ! docker inspect --type=image "${local_image_full}" > /dev/null 2>&1; then
    # No SDS image in the locak docker registry

    build_log_file=$(mktemp)
    printf_color "yellow" "NOT FOUND\n"
    printf "    - Building image. This can take several minutes if it's the first time you build ans SDS image\n"
    printf "    - Logs at: ${build_log_file}\n"

    "${build_script}" "${dockerfile_path}" "${SDS_SDS_DOCKER_NAME}" > "${build_log_file}" 2>&1
    
    if [ $? -ne 0 ]; then
        printf_color "red" "\nError: Failed to build Docker image.\n"
        rm -f "${build_log_file}"
        exit 7
    fi
    rm -f "${build_log_file}"
    printf_color "green" "    - Image built successfully\n\n"
else
    # There's a previously build image in the local docker registry
    printf_color "green" "FOUND\n"
    
    printf "  - Checking Docker image status.... "
    # Image exists, check if outdated
    if [ -f "${dockerfile_path}" ]; then
        # Get Dockerfile modification time
        # Use different stat syntax for macOS vs Linux/WSL
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS (BSD stat)
            dockerfile_mtime=$(stat -f %m "${dockerfile_path}")
        else
            # Linux/WSL (GNU stat)
            dockerfile_mtime=$(stat -c %Y "${dockerfile_path}")
        fi
        
        # Get image creation time from Docker
        image_created_str=$(docker inspect --format='{{.Created}}' "${local_image_full}")
        
        # Parse Docker timestamp to epoch (handles ISO 8601 format)
        # Docker returns format like: 2023-01-15T10:30:45.123456789Z
        # The 'Z' means UTC timezone
        
        # Convert to epoch using date command
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS (BSD date) - we need to handle UTC properly
            # Strip fractional seconds and Z: "2024-01-15T10:30:45.123Z" -> "2024-01-15T10:30:45"
            image_created_clean=$(echo "${image_created_str}" | sed 's/\.[0-9]*Z$//')
            # BSD date doesn't have timezone handling in -f, so we parse as UTC and adjust
            # Use -u flag to interpret as UTC
            image_created_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "${image_created_clean}" "+%s" 2>/dev/null)
        else
            # Linux/WSL (GNU date) - can handle ISO format directly
            image_created_epoch=$(date -d "${image_created_str}" "+%s" 2>/dev/null)
        fi
        
        # Check if date parsing succeeded
        if [ -z "${image_created_epoch}" ]; then
            printf_color "yellow" "    - Warning: Could not parse image creation time. Skipping age check.\n"
        elif [ "${image_created_epoch}" -lt "${dockerfile_mtime}" ]; then
            printf_color "yellow" "OUTDATED\n"
            printf "    - Image timestamp........ : $(date -r ${image_created_epoch})\n"
            printf "    - Dockerfile timestamp... : $(date -r ${dockerfile_mtime})).\n"
            read -p "- Do you want to rebuild it? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then  
                build_log_file=$(mktemp)
                printf "    - Rebuilding image. Logs at: ${build_log_file}\n"

                "${build_script}" "${dockerfile_path}" "${SDS_SDS_DOCKER_NAME}" > "${build_log_file}" 2>&1
                
                if [ $? -ne 0 ]; then
                    printf_color "red" "\nError: Failed to rebuild Docker image.\n"
                    exit 8
                fi
                printf_color "green" "\n    - Image rebuilt successfully.\n\n"
            fi
        else
            printf_color "green" "UP-TO-DATE\n"
        fi
    fi
fi

#
# CHECK IF THE SDS CONTAINER EXISTS AND IS RUNNING
#
printf_color "blue" "\nSDS Docker container\n"

printf "  - Container name: ${SDS_SDS_DOCKER_NAME}\n"
printf "  - Checking container status....... "
if docker inspect --type=container ${SDS_SDS_DOCKER_NAME} > /dev/null 2>&1; then
    #
    # Container exists, now check its running status
    #
    STATUS=$(docker inspect --format='{{.State.Status}}' ${SDS_SDS_DOCKER_NAME})

    if [ "$STATUS" == "running" ]; then
        printf_color "green" "RUNNING\n"
    else
        printf_color "yellow" "$(echo "$STATUS" | tr '[:lower:]' '[:upper:]')\n"
        printf "    - Starting container............ "
        ${THIS_SCRIPT_PATH}/sds-start.start-container.sh
    fi
else
    #
    # Container does not exist, so we need to run it
    #
    printf_color "yellow" "NOT FOUND\n"
    printf "    - Running container............. "

    ${THIS_SCRIPT_PATH}/sds-start.run-container.sh
    
    if [[ $? -ne 0 ]]; then
        printf_color "red" "FAILED\n"
        exit 9
    else
        printf_color "green" "LAUNCHED\n"
    fi
fi

# If the container wasn't running, wait a bit to re-check if it started
if [ "${STATUS:-}" != "running" ]; then
    printf "  - Re-checking container status.... "
    sleep 5

    STATUS=$(docker inspect --format='{{.State.Status}}' ${SDS_SDS_DOCKER_NAME})
    if [ "$STATUS" == "running" ]; then
        printf_color "green" "RUNNING\n"
    else
        printf_color "red" "FAILED TO START: $(echo "$STATUS" | tr '[:lower:]' '[:upper:]')\n"

        printf "\n"
        printf_color "red" "FATAL ERROR: Container failed to start.\n"
        printf_color "red" "Container logs:\n\n"
        docker logs ${SDS_SDS_DOCKER_NAME}
        echo
        exit 10
    fi
fi


##
## START THE SDS SHELL
##
printf_color "blue" "\nSDS shell\n"
set +e

printf "  - Container name: ${SDS_SDS_DOCKER_NAME}\n"
printf "  - BASHRC path: ${BASHRC_FILE}" 

printf "\n\n"
docker exec -it \
    --env SDS_START_DIR=${SDS_START_DIR} \
    ${SDS_SDS_DOCKER_NAME} \
    bash --rcfile ${BASHRC_FILE}

printf_color "blue" "\n\n\tMAGIC HAS BEEN MASTERFULLY PERFORMED!!!\n\n"
printf_color "blue" "\tNow, have some very well deserved rest!\n\n\tGood bye!\n\n\n"
