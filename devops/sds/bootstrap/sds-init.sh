#!/usr/bin/env bash
set -eu

##
## sds-init.sh
## 
## Initialize the SDS environment (copy template files) or revert it (delete files)
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

# Determine the repository name
REPO_NAME=$(basename "${CURR_REPO_ROOT_PATH}")

# List of placeholders to replace: "PLACEHOLDER_NAME:VALUE"
# (without the {{ }} curly braces)
PLACEHOLDERS=( \
    "REPO_NAME:${REPO_NAME}" \
)

# Add the SDS utilities folder to the PATH
PATH=${PATH}:${SDS_ROOT_IN_HOST}/opt/sds

# List of files to copy: "absolute-folder:example-file:destination-file"
FILES_TO_COPY=( \
    "${SDS_ROOT_IN_HOST}/etc:sds.conf.example:sds.conf" \
    "${SDS_ROOT_IN_HOST}/etc:sds.bashrc.example:sds.bashrc" \
    "${SDS_ROOT_IN_HOST}/image-builder:Dockerfile.example:Dockerfile" \
    "${CURR_REPO_ROOT_PATH}/devops/python/cicd:lint.toml.example:lint.toml" \
    "${CURR_REPO_ROOT_PATH}/.agents/workflows:sds-exec.md.example:sds-exec.md" \
)

# Initializes the SDS environment by copying template files and
# replacing placeholders with repository-specific values.
function initialize_sds() {
    printf_color "blue" "INITIALIZING THE SDS ENVIRONMENT\n\n"
    printf_color "blue" "Copying template files\n"

    for entry in "${FILES_TO_COPY[@]}"; do
        IFS=":" read -r folder example destination <<< "$entry"
        
        target_path="${folder}/${destination}"
        source_path="${folder}/${example}"

        printf_color "blue" "  - ${destination}\n"
        printf "    - Checking '${target_path}'... "
        
        if [ ! -f "$target_path" ]; then
            printf_color "yellow" "NOT FOUND\n"
            printf "    - Creating '${destination}' from '${example}'... "
            
            # Temporary file for processing replacements
            temp_target=$(mktemp)
            cp "$source_path" "$temp_target"

            # Apply all replacements
            for placeholder_entry in "${PLACEHOLDERS[@]}"; do
                IFS=":" read -r key value <<< "$placeholder_entry"
                sed -i "" "s/{{${key}}}/${value}/g" "$temp_target"
            done
            
            mv "$temp_target" "$target_path"
            printf_color "green" "CREATED\n\n"
            printf_color "yellow" "      Please, edit file to match your needs:\n"
            printf_color "yellow" "        ${target_path}\n\n"
        else
            printf_color "green" "FOUND\n"
        fi
        echo
    done
    echo
}

# Reverts the SDS environment initialization by deleting all
# generated configuration and workflow files.
function revert_sds() {
    printf_color "blue" "REVERTING THE SDS ENVIRONMENT INITIALIZATION\n\n"
    printf_color "blue" "Deleting template files\n"

    for entry in "${FILES_TO_COPY[@]}"; do
        IFS=":" read -r folder example destination <<< "$entry"
        
        target_path="${folder}/${destination}"

        printf_color "blue" "  - ${destination}\n"
        printf "    - Checking '${target_path}'... "
        
        if [ -f "$target_path" ]; then
            printf_color "yellow" "FOUND\n"
            printf "    - Deleting '${destination}'... "
            rm "$target_path"
            printf_color "green" "DELETED\n"
        else
            printf_color "green" "NOT FOUND (NOTHING TO DO)\n"
        fi
        echo
    done
    echo
}

#
# MAIN EXECUTION
#

# Parse arguments
REVERT=false
if [[ "${1:-}" == "--revert" ]]; then
    REVERT=true
fi

if [ "$REVERT" = true ]; then
    revert_sds
else
    initialize_sds
fi
