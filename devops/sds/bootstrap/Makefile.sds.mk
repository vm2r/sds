##
## Makefile.sds.mk
##
## Makefile for managing and operating the SDS environment (container and console)
##


# 
# DON'T EDIT ANYTHING IN THIS SECTION
#
export SDS_INIT_SCRIPT       := $(SDS_ROOT_IN_HOST)/bootstrap/sds-init.sh
export SDS_START_SCRIPT      := $(SDS_ROOT_IN_HOST)/bootstrap/sds-start.sh
export SDS_STOP_SCRIPT       := $(SDS_ROOT_IN_HOST)/bootstrap/sds-stop.sh
export SDS_RESET_SCRIPT      := $(SDS_ROOT_IN_HOST)/bootstrap/sds-reset.sh
export SDS_PRINT_HELP_SCRIPT := $(SDS_ROOT_IN_HOST)/bootstrap/print-help.sh

SHELL := /bin/bash

.PHONY: sds-init sds-start sds-start-tag sds-stop sds-restart sds-restart-tag sds-reset print-vars help

sds-init: ## Initialize the SDS environment
	@$(SDS_INIT_SCRIPT)

sds-start: ## Start the latest SDS environment
	@$(MAKE) sds-start-tag tag="latest"

sds-start-tag: ## Start a SDS environment with a specific tag (make sds-start-tag tag="<tag>")
	@$(SDS_START_SCRIPT) $(if $(tag),--image-tag "$(tag)",)

sds-stop: ## Stop the SDS
	@$(SDS_STOP_SCRIPT)

sds-restart: ## Remove the current SDS container and start the latest SDS
	@$(MAKE) sds-stop
	@$(MAKE) sds-start

sds-restart-tag: ## Remove the current SDS container and start the SDS with a specific tag
	@$(MAKE) sds-stop
	@$(MAKE) sds-start-tag tag="$(tag)"

sds-reset: ## Reset the SDS environment (delete container, all images and root volume)
	@$(SDS_RESET_SCRIPT)

print-vars: ## Print all env vars visible to Make
	@$(foreach V,$(sort $(.VARIABLES)), $(info $V=$($V)))

help: ## Show help message
	@$(SDS_PRINT_HELP_SCRIPT) "$(MAKEFILE_LIST)"

.DEFAULT_GOAL := help
