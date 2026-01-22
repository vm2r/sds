#!/usr/bin/env bash

#
# SDS Local Builder
#
# This script builds a SDS (Standardized Development Stack) Docker image locally.
# It takes the Dockerfile path, service name, and an optional service description as arguments.
# The script automatically tags the build with the current timestamp and prunes dangling
# images before building.
#

set -eux

if [[ -z "${SDS_ROOT_IN_HOST}" ]]; then
    echo "SDS_ROOT_IN_HOST is not set. It should have been set before running this script ($0)."
	exit -1
fi

source ${SDS_ROOT_IN_HOST}/etc/sds_config

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

# Build the SDS Docker image locally
docker image prune -f;

docker image build \
	--file ${dockerfile_path} \
	--progress=plain \
	--tag ${SDS_IMAGE_NAME}:${SDS_IMAGE_TAG} \
	--build-arg SDS_VERSION_DATE_TAG=${version_date_tag} \
	--build-arg SDS_IMAGE_DESCRIPTION="${SDS_IMAGE_DESCRIPTION}" \
	${SDS_ROOT_IN_HOST}

# Tag the image with the version date tag
docker image tag \
	"${SDS_IMAGE_NAME}:${SDS_IMAGE_TAG}" \
	"${SDS_IMAGE_NAME}:${version_date_tag}"
