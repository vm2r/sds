#!/usr/bin/env bash
set -eux

##
## build-local.sh
##
## Builds a SDS (Standardized Development Stack) Docker image locally.
##
## This script is called by sds-start.sh
##

if [[ -z "${SDS_ROOT_IN_HOST}" ]]; then
    echo "SDS_ROOT_IN_HOST is not set. It should have been set before running this script ($0)."
	exit -1
fi

source ${SDS_ROOT_IN_HOST}/etc/sds.conf
source ${SDS_ROOT_IN_HOST}/etc/sds.env

if [[ -z "${SDS_SDS_DOCKER_NAME}" ]]; then
    echo "SDS_SDS_DOCKER_NAME is not set. It should have been set before running this script ($0)."
	exit -1
fi

dockerfile_path=${SDS_ROOT_IN_HOST}/image-builder/Dockerfile
if [[ ! -f "${dockerfile_path}" ]]; then
    echo "Dockerfile not found at ${dockerfile_path}."
	exit -1
fi

version_date_tag=$(date +%Y-%m-%d-%H-%M-%S)

SDS_IMAGE_NAME=${SDS_SDS_DOCKER_NAME}
SDS_IMAGE_TAG="latest"
SDS_IMAGE_DESCRIPTION="Standardized Development Stack (${SDS_SDS_DOCKER_NAME} - ${version_date_tag})"


#
# Detect host architecture and OS
#
HOST_ARCH=$(uname -m)
HOST_OS=$(uname -s)

# Determine the correct Docker platform flag
# For SRE workflows: 
# - x86_64/amd64 -> linux/amd64
# - arm64/aarch64 -> linux/arm64 (Native performance on Apple Silicon M1/M2/M3)
if [[ "${HOST_ARCH}" == "x86_64" ]]; then
    DOCKER_PLATFORM="linux/amd64"
elif [[ "${HOST_ARCH}" == "arm64" || "${HOST_ARCH}" == "aarch64" ]]; then
    DOCKER_PLATFORM="linux/arm64"
else
    # Fallback to amd64 for unknown environments
    DOCKER_PLATFORM="linux/amd64"
fi

printf "  - Building for host ${HOST_OS} (${HOST_ARCH}) using platform ${DOCKER_PLATFORM}"

# Build the SDS Docker image locally
docker image prune -f;

docker image build \
	--platform ${DOCKER_PLATFORM} \
	--file ${dockerfile_path} \
	--progress=plain \
	--tag ${SDS_IMAGE_NAME}:${SDS_IMAGE_TAG} \
	--build-arg SDS_VERSION_DATE_TAG=${version_date_tag} \
	--build-arg SDS_IMAGE_DESCRIPTION="${SDS_IMAGE_DESCRIPTION}" \
	--build-arg SDS_SDS_ROOT_PATH_IN_CONTAINER="${SDS_SDS_ROOT_PATH_IN_CONTAINER}" \
	${SDS_ROOT_IN_HOST}

# Tag the image with the version date tag
docker image tag \
	"${SDS_IMAGE_NAME}:${SDS_IMAGE_TAG}" \
	"${SDS_IMAGE_NAME}:${version_date_tag}"
