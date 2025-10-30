#!/usr/bin/env bash

##
## set-helpers-path.sh
## 
## This script sets the PATH variable to include the SDS helper tools
##

if [[ -z "${SDS_RUN_HELPERS_SOURCE}" ]]; then
    echo "Error: SDS_RUN_HELPERS_SOURCE is not set."
    exit 1
fi

if [[ -z "${SDS_SDS_ROOT_PATH_IN_CONTAINER}" ]]; then
    echo "Error: SDS_SDS_ROOT_PATH_IN_CONTAINER is not set."
    exit 1
fi


case "${SDS_RUN_HELPERS_SOURCE}" in
    repo)
        # Override the PATH variable to use the SDS scripts and CLI from the repo
        export SDS_HELPERS_ROOT="${SDS_SDS_ROOT_PATH_IN_CONTAINER}/opt/sds"
        export PATH="${SDS_HELPERS_ROOT}:${PATH}"
        ;;

    container)
        export SDS_HELPERS_ROOT="/opt/sds"
        export PATH="${SDS_HELPERS_ROOT}:${PATH}"
        ;;
    *)
        printf_color "red" "  - Invalid SDS run helpers source: '${SDS_RUN_HELPERS_SOURCE}'\n"
        exit -1
        ;;
esac   

