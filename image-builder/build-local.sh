#!/usr/bin/env bash
set -eux

usage() {
    echo "Usage: $0 <dockerfile> <service_name> [<service_description>]"
    exit 1
}

SDS_DOCKERFILE=${1}
SDS_SERVICE_NAME=${2}
SDS_SERVICE_DESCRIPTION=${3-"Standardized Development Stack"}

if [[ -z "${SDS_DOCKERFILE}" ]]; then
    echo "SDS_DOCKERFILE is not set"
	usage
fi

if [[ -z "${SDS_SERVICE_NAME}" ]]; then
    echo "SDS_SERVICE_NAME is not set"
	usage
fi

# Build the SDS Docker image locally
SDS_VERSION_DATE_TAG=$(date +%Y-%m-%d-%H-%M-%S)

docker image prune -f;
time \
	docker build \
		--file ${SDS_DOCKERFILE} \
		--progress=plain \
		--tag ${SDS_SERVICE_NAME} \
		--build-arg SDS_VERSION_DATE_TAG=${SDS_VERSION_DATE_TAG} \
		--build-arg SDS_SERVICE_DESCRIPTION="${SDS_SERVICE_DESCRIPTION}" \
		.

