#
# Base Makefile for SDS - Standardized Development Stack
# All other Makefiles should include this file with the following syntax:
#   export SDS_REPO_ROOT_PATH := $(shell git rev-parse --show-toplevel)
#   include $(SDS_REPO_ROOT_PATH)/vm2r/devops/Makefile.base.mk
#


ifndef VERBOSE
MAKEFLAGS += --no-print-directory
endif

##
# GCP Organization setups
##

#export CICD_PROJECT_ID := XXXXXX

#export CICD_REGION := us-central1
#export DOCKER_REPO_NAME := XXXXXX
#export DOCKER_REGISTRY_DOMAIN := ${SDS_CICD_REGION}-docker.pkg.dev
#export DOCKER_REGISTRY_REPO := $(DOCKER_REGISTRY_DOMAIN)/${SDS_GCP_PROJECT_ID_DEVOPS_CICD_PROD}/${DOCKER_REPO_NAME}

.PHONY: help print-vars sds rest build

##
# SDS RELATED TARGETS
##




##
# SDS ARCHITECTURE ELEMENTS SPECIFIC VARIABLES
##

SDS_DEFAULT_DOCKERFILE := $(SDS_REPO_ROOT_PATH)/image-builder/Dockerfile
SDS_DEFAULT_SERVICE_NAME := sds-std

build-local: ## Builds the SDS Docker image locally
	$(SDS_REPO_ROOT_PATH)/image-builder/build-local.sh \
		$(if $(dockerfile), "$(dockerfile)", $(SDS_DEFAULT_DOCKERFILE)) \
		$(if $(service_name), "$(service_name)", $(SDS_DEFAULT_SERVICE_NAME))
	

print-vars: ## Print all env vars visible to Make
	$(foreach V,$(sort $(.VARIABLES)), $(info $V=$($V) ($(value $V))))


help: ## Show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make TARGET [ARGS]\n  Available targets:\033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "    \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
