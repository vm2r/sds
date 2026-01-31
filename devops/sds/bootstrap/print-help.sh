#!/usr/bin/env bash
set -eu

##
## print-help.sh
## 
## Prints all Makefile targets with their description
##

MAKEFILE_LIST=$1

printf "\n"
printf "Usage: make TARGET [ARGS]\n"
printf "  Available targets:\033[36m\033[0m\n"; 

for makefile in ${MAKEFILE_LIST}; do 
    STRIPPED_FILENAME=${makefile#$SDS_ROOT_IN_HOST/};
    grep -E '^[a-zA-Z0-9_-]+:.*?##' "${makefile}" \
        | while IFS= read -r line; do 
        
            TARGET_NAME=$(\
                echo "${line}" \
                | sed -E 's/^([a-zA-Z0-9_-]+):.*$$/\1/');

            DESCRIPTION=$(
                echo "${line}" \
                | sed -E 's/^.*##[[:space:]]*(.*)$$/\1/');

            printf "    \033[36m%-15s\033[0m %s\n" "${TARGET_NAME}" "${DESCRIPTION} (${STRIPPED_FILENAME})"; 
        done;
done
