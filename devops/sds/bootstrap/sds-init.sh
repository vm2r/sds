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

printf_color "blue" "INITIALIZING THE SDS ENVIRONMENT\n\n"


printf_color "blue" "Copying template files\n"
# List of files to copy: "absolute-folder:example-file:destination-file"
FILES_TO_COPY=( \
    "${SDS_ROOT_IN_HOST}/etc:sds.conf.example:sds.conf" \
    "${SDS_ROOT_IN_HOST}/etc:sds.bashrc.example:sds.bashrc" \
    "${SDS_ROOT_IN_HOST}/image-builder:Dockerfile.example:Dockerfile" \
    "${CURR_REPO_ROOT_PATH}/devops/python/cicd:lint.toml.example:lint.toml" \
)

for entry in "${FILES_TO_COPY[@]}"; do
    IFS=":" read -r folder example destination <<< "$entry"
    
    target_path="${folder}/${destination}"
    source_path="${folder}/${example}"

    printf_color "blue" "  - ${destination}\n"
    printf "    - Checking '${target_path}'... "
    
    if [ ! -f "$target_path" ]; then
        printf_color "yellow" "NOT FOUND\n"
        printf "    - Creating '${destination}' from '${example}'... "
        cp "$source_path" "$target_path"
        printf_color "green" "CREATED\n\n"
        printf_color "yellow" "      Please, edit file\n\n"
        printf_color "yellow" "        ${target_path}\n\n"
        printf_color "yellow" "      to match your needs.\n\n"
    else
        printf_color "green" "FOUND\n"
    fi
    echo
done
echo

