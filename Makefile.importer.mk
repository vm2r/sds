##
## /Makefile.importer.mk
##
## Makefile that imports other Makefiles in the repo, including the SDS Makefile
##
## THIS FILE MUST BE PLACED AT AT THE ROOT OF THE REPOSITORY
##
## All Makefiles in this repository should include this file using these instructions:
##
## export CURR_REPO_ROOT_PATH := $(shell git rev-parse --show-toplevel)
## include $(CURR_REPO_ROOT_PATH)/Makefile.importer.mk
##

#
# DON'T EDIT THIS SECTION
#

# Include the SDS makefile
export SDS_ROOT_IN_HOST := $(CURR_REPO_ROOT_PATH)/devops/sds
export SDS_SDS_MKFILE_PATH := $(SDS_ROOT_IN_HOST)/bootstrap/Makefile.sds.mk
include $(SDS_SDS_MKFILE_PATH)

#
# ADD YOUR CUSTOM MAKEFILE TARGETS AND IMPORTS BELOW THIS LINE
#

