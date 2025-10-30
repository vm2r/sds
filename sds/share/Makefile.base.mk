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
SDS_SERVICE_PATH := $(shell git rev-parse --show-prefix | sed 's/.$$//' )

# Remove "projects" prefix from code projects, 
SDS_SERVICE_NAME := $(shell echo $(SDS_SERVICE_PATH) | tr \/ \- | sed -e 's/^vm2r-//')

build: ## builds it using Cloud Build
	$(eval BUILD_SUBSTITUTIONS := $(BUILD_SUBSTITUTIONS),_SDS_SERVICE_NAME=$(SDS_SERVICE_NAME))
	$(eval BUILD_SUBSTITUTIONS := $(BUILD_SUBSTITUTIONS),_SDS_DOCKERFILE=$(SDS_DOCKERFILE))
	$(eval BUILD_SUBSTITUTIONS := $(BUILD_SUBSTITUTIONS),_SDS_DOCKER_REGISTRY_REPO_DEVOPS=$(SDS_DOCKER_REGISTRY_REPO_DEVOPS))
	$(eval BUILD_SUBSTITUTIONS := $(BUILD_SUBSTITUTIONS),_SDS_DOCKER_REGISTRY_REPO_RUNTIME=$(SDS_DOCKER_REGISTRY_REPO_RUNTIME))
	$(eval BUILD_SUBSTITUTIONS := $(BUILD_SUBSTITUTIONS),_SDS_VERSION_DATE_TAG=$(SDS_VERSION_DATE_TAG))
	time gcloud builds submit \
		--config $(CLOUDBUILD_YAML) \
		--project $(SDS_GCP_PROJECT_ID_DEVOPS_CICD_PROD) \
		--region $(SDS_CICD_REGION) \
		--substitutions $(BUILD_SUBSTITUTIONS) \
		.


SDS_DEFAULT_DOCKERFILE := $(SDS_REPO_ROOT_PATH)/image-builder/Dockerfile
SDS_DEFAULT_SERVICE_NAME := sds-std

build-local: ## Builds the SDS Docker image locally
	$(SDS_REPO_ROOT_PATH)/image-builder/build-local.sh \
		$(if $(dockerfile), "$(dockerfile)", $(SDS_DEFAULT_DOCKERFILE)) \
		$(if $(service_name), "$(service_name)", $(SDS_DEFAULT_SERVICE_NAME))
	

print-vars:
	$(foreach V,$(sort $(.VARIABLES)), $(info $V=$($V) ($(value $V))))

help: ## Display this help message
	@for f in $(MAKEFILE_LIST); do \
		echo; \
		echo $$f; \
		grep -E '^[a-zA-Z0-9_-]+:.*?[## .*]?$$' $$f; \
		echo; \
	done

.DEFAULT_GOAL := help