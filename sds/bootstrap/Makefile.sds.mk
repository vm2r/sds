#
# SDS - Standardized Development Stack
# Makefile for the SDS
# 
# DON'T EDIT ANYTHING IN THIS SECTION
#

export SDS_SDS_ROOT_PATH := $(SDS_REPO_ROOT_PATH)$(SDS_SDS_ROOT_PATH_IN_REPO)

export SDS_ENVVARS_PATH := $(SDS_SDS_ROOT_PATH)/etc/sds_config
export SDS_START_SCRIPT := $(SDS_SDS_ROOT_PATH)/bootstrap/start-sds.main.sh
export SDS_STOP_SCRIPT  := $(SDS_SDS_ROOT_PATH)/bootstrap/stop-sds.sh

SHELL := /bin/bash

.PHONY: sds sds-local rest help

sds: ## Start the SDS
# Arguments:
#   - tag:	the docker image tag to run
#				prod (default), rc, latest
#   - helpers: 	which bashrc to run at shell initialization inside the container
#				"container" runs /etc/bashrc (default)
#				"repo"      runs <SDS_REPO_PATH>/etc/bashrc 
#	- image: 	Where to get the image from
#				"remote" Start the SDS with an image from the remote repository (default)
#				"local"  Start the SDS with an image built locally

	$(SDS_START_SCRIPT) \
		$(if $(tag),--image-tag "$(tag)",) \
		$(if $(helpers),--helpers-source "$(helpers)",) \
		$(if $(image),--image-location "$(image)",) 


sds-local: ## Start the SDS locally
	@$(MAKE) sds \
		tag="latest" \
		helpers="repo" \
		image="sds-std"

# Stop the standardized local development environment
rest: ## Stop the SDS
	@$(SDS_STOP_SCRIPT)

