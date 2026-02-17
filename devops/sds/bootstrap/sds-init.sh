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

FILES_TO_COPY=(
    ("sds.conf.example" "sds.conf")
    ("sds.bashrc.example" "sds.bashrc")
    ("Dockerfile.example" "Dockerfile")
)

for file in ${FILES_TO_COPY[@]}; do
    printf_color "blue" "${file[1]}\n"
    printf "  - Checking ${file[1]}........ "
    if [ ! -f "${SDS_ROOT_IN_HOST}/etc/${file[1]}" ]; then
        printf_color "yellow" "NOT FOUND\n"
        printf '    - Creating ${file[1]} from ${file[0]}... '
        cp "${SDS_ROOT_IN_HOST}/etc/${file[0]}" "${SDS_ROOT_IN_HOST}/etc/${file[1]}"
        printf_color "green" "CREATED\n\n"
        printf_color "yellow" "\tPlease, edit 'devops/sds/etc/${file[1]}' to match your needs.\n\n"
    else
        printf_color "green" "FOUND\n"
    fi
done

# # Check if sds.conf file exists
# printf_color "blue" "SDS configuration\n"
# printf "  - Checking sds.conf file........ "
# if [ ! -f "${SDS_ROOT_IN_HOST}/etc/sds.conf" ]; then
#     printf_color "yellow" "NOT FOUND\n"
#     printf '    - Creating sds.conf from sds.conf.example... '
#     cp "${SDS_ROOT_IN_HOST}/etc/sds.conf.example" "${SDS_ROOT_IN_HOST}/etc/sds.conf"
#     printf_color "green" "CREATED\n\n"
#     printf_color "yellow" "\tPlease, edit 'devops/sds/etc/sds.conf' to match your needs.\n\n"
# else
#     printf_color "green" "FOUND\n"
# fi

# # Check if the BASHRC file exists
# printf_color "blue" "SDS BASHRC\n"
# printf "  - Checking sds.bashrc file... "
# if [ ! -f "${SDS_ROOT_IN_HOST}/etc/sds.bashrc" ]; then
#     printf_color "yellow" "NOT FOUND\n"
#     printf '    - Creating sds.bashrc from sds.bashrc.example... '
#     cp "${SDS_ROOT_IN_HOST}/etc/sds.bashrc.example" "${SDS_ROOT_IN_HOST}/etc/sds.bashrc"
#     printf_color "green" "CREATED\n\n"
#     printf_color "yellow" "\tPlease, edit 'devops/sds/etc/sds.bashrc' to match your needs.\n\n"
# else
#     printf_color "green" "FOUND\n"
# fi

# # Check if SDS Dockerfile exists
# printf_color "blue" "SDS Dockerfile\n"
# printf "  - Checking SDS Dockerfile....... "
# if [ ! -f "${SDS_ROOT_IN_HOST}/image-builder/Dockerfile" ]; then
#     printf_color "yellow" "NOT FOUND\n"
#     printf '    - Creating Dockerfile from Dockerfile.example... '
#     cp "${SDS_ROOT_IN_HOST}/image-builder/Dockerfile.example" "${SDS_ROOT_IN_HOST}/image-builder/Dockerfile"
#     printf_color "green" "CREATED\n\n"
#     printf_color "yellow" "\tPlease, edit 'devops/sds/image-builder/Dockerfile' to match your needs.\n\n"
# else
#     printf_color "green" "FOUND\n"
# fi

