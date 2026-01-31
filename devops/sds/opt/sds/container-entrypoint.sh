#!/usr/bin/env bash

##
## container-entrypoint.sh
##
## The entrypoint script executed when the SDS container starts
## This script is executed by the container ENTRYPOINT
##

printf "STARTING SDS CONTAINER\n"
printf "  - SDS version    : ${SDS_VERSION_DATE_TAG} (${SDS_RUN_VERSION_TARGET})\n"
printf "  - SDS root path  : ${SDS_SDS_ROOT_PATH_IN_CONTAINER}\n"

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
pyenv global 3.14; \
pyenv rehash;

#
# Initialize Pants daeamon to save user's time on the first run
#
printf "Initializing Pants daemon\n"
pants

#
# Initialize SDS specific env vars and utility/helper scripts 
#
printf "Initializing SDS specific env vars and utility/helper scripts\n"
source ${SDS_SDS_ROOT_PATH_IN_CONTAINER}/etc/sds.conf
source ${SDS_SDS_ROOT_PATH_IN_CONTAINER}/etc/sds.env

#
# Add termination signals handlers
#
printf "Adding termination signals handlers\n"
handle_shutdown() {
    signal=${1}
    printf "Terminating container. Signal: ${signal}\n"
}
trap "handle_shutdown SIGTERM" SIGTERM
trap "handle_shutdown SIGINT"  SIGINT
trap "handle_shutdown SIGHUP"  SIGHUP
trap "handle_shutdown ERR"     ERR
trap "handle_shutdown EXIT"    EXIT


#
# Infinite loop to keep the container alive
#
printf "\n\n"
printf "=== ENV VARS ===\n"
set
printf "================\n"
printf "\n\n"

printf "Keeping the container alive\n"
while true; do 
    sleep 300; 
done
