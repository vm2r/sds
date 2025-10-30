#
# SDS - Standardized Development Stack
# Makefile importer

export SDS_SDS_ROOT_PATH_IN_REPO := /sds

# 
# DON'T EDIT ANYTHING IN THIS SECTION
#
#BASE_MKFILE_PATH := /share/Makefile.base.mk
SDS_MKFILE_PATH := $(SDS_SDS_ROOT_PATH_IN_REPO)/bootstrap/Makefile.sds.mk
BASE_MKFILE_PATH := $(SDS_SDS_ROOT_PATH_IN_REPO)/share/Makefile.base.mk

include $(SDS_REPO_ROOT_PATH)$(SDS_MKFILE_PATH)
include $(SDS_REPO_ROOT_PATH)$(BASE_MKFILE_PATH)
