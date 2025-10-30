#
# SDS - Standardized Development Stack
# Root Makefile
# 
# DON'T EDIT ANYTHING IN THIS SECTION
#

export SDS_REPO_ROOT_PATH := $(shell git rev-parse --show-toplevel)
include $(SDS_REPO_ROOT_PATH)/Makefile.importer.mk
