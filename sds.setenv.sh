#!/usr/bin/env bash
set -eu

##
## sds.setenv.sh
##
## Initializes environment variables used by the SDS scripts
##


#
# GCP SPECIFIC VARIABLES
#

# Google Cloud accounts to be authenticated in the container
# Example:
# export SDS_GOOGLE_ACCOUNTS=(\
#     "user_1@gmail.com" \
#     "user_2@gmail.com" \
#     "user_3@gmail.com"
# )
export SDS_GOOGLE_ACCOUNTS=(\
    "user_1@gmail.com"
)


#
# CONTAINER SPECIFIC VARIABLES
#

# The TCP ports the SDS container will publish to the host machine
# Example:
# export SDS_TCP_PORTS_PUBLISH=(\
#     "8000-8010" \
#     "8080" \
#     "55432" \
#     "33306"
# )
export SDS_TCP_PORTS_PUBLISH=(
)

# The paths and mountpoints to be mounted in the container
# Format: <host_path>:<container_path>
# Example:
# export SDS_VOLUMES_MAPPING=(\
#     "/Users/user/github/org_1/repo_1:/repo_1" \
#     "/Users/user/github/org_1/repo_2:/repo_2" \
#     "/Users/user/github/org_2/repo_3:/repo_3"
# )
export SDS_VOLUMES_MAPPING=(\
)



##
## DO NOT EDIT THIS SECTION
##
export REPO_ROOT_PATH=$(git rev-parse --show-toplevel)
export REPO_NAME=$(basename $(git remote get-url origin) .git)
export SDS_SDS_DOCKER_NAME="sds-${REPO_NAME}"


##
## The root path for SDS files
##

# On the host, this is an absolute path
export SDS_SDS_ROOT_PATH_IN_HOST="${REPO_ROOT_PATH}/sds"
# In the container, this is relative to the "sds" user home folder (~)
export SDS_SDS_ROOT_PATH_IN_CONTAINER="/home/sds"


#
# The path for the SDS CLI root folder in the container
#
export SDS_SDS_CLI_ROOT="${SDS_SDS_ROOT_PATH_IN_CONTAINER}/opt/sds/cli"

# The name of the volume that will be created to persist root folder in the container
export SDS_SDS_ROOT_VOLUME_NAME="${SDS_SDS_DOCKER_NAME}-root-volume"