#!/usr/bin/env bash

##
## SDS container entrypoint script
## /sds/opt/sds/container-entrypoint.sh
## This script is executed by the container ENTRYPOINT
##

printf "STARTING SDS CONTAINER\n"
printf "  - SDS version    : ${SDS_VERSION_DATE_TAG} (${SDS_RUN_VERSION_TARGET})\n"
printf "  - Repo root      : ${SDS_SDS_ROOT_PATH_IN_CONTAINER}\n"
printf "  - Helpers root   : ${SDS_RUN_HELPERS_SOURCE}\n"

export SDS_SESSION_ID=$(mktemp | cut -d'.' -f2)
printf "  - SDS Session ID : ${SDS_SESSION_ID}\n\n"

#
# Initialize networking
#

# Aliases for Cloud SQL instances
export HOSTALIASES=/etc/host.aliases


#
# Initialize the Python environment for the maintenace scripts
#
printf "Initializing Python environment\n"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
pyenv global 3.12; \
pyenv rehash;

#
# Initialize Pants daeamon to save user's time on the first run
#
printf "Initializing Pants daemon\n"
pants

set

#
# Initialize SDS specific env vars and utility/helper sripts 
#
printf "Initializing SDS specific env vars and utility/helper sripts\n"
source ${SDS_SDS_ROOT_PATH_IN_CONTAINER}/etc/sds_config



#
# Add termination signals handlers
#
printf "Adding termination signals handlers\n"
handle_shutdown() {
    signal=${1}
    ${SDS_HELPERS_ROOT}/log_gcp.sh \
        "INFO" \
        "TERMINATING" \
        "signal:${signal}" "{ \"signal\": \"${signal}\"}"
}
trap "handle_shutdown SIGTERM" SIGTERM
trap "handle_shutdown SIGINT"  SIGINT
trap "handle_shutdown SIGHUP"  SIGHUP
trap "handle_shutdown ERR"     ERR
trap "handle_shutdown EXIT"    EXIT

# #
# # Container Initialization
# #
# ${SDS_HELPERS_ROOT}/log_gcp.sh "INFO" "INITIALIZING" "" "{}"

# #
# # Source helper scripts
# #
# source ${SDS_HELPERS_ROOT}/git-prompt.sh

# #
# # Logs environment vars to Cloud Logging
# #
# ${SDS_HELPERS_ROOT}/log_envvars.sh

# #
# # Mounts all GCS Buckets as local directories
# #
# printf "MOUNTING GCS BUCKETS:\n"
# ${SDS_HELPERS_ROOT}/init_gcsfuse.sh

#
# Infinite loop to keep the container alive
#
printf "Keeping the container alive\n"
while true; do 
    #${SDS_HELPERS_ROOT}/check_sds_health.sh
    sleep 300; 
done

