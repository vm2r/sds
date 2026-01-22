#
# SDS - Standardized Development Stack
# Root Makefile

#
# DON'T EDIT THIS SECTION
#
export CURR_REPO_ROOT_PATH := $(shell git rev-parse --show-toplevel)
include $(CURR_REPO_ROOT_PATH)/Makefile.importer.mk

#
# ADD YOUR TARGETS AND OTHER IMPORTS HERE
#