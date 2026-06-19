##
## Makefile.importer.mk
##
## Makefile that imports other Makefiles in the repo, including the SDS Makefile
##
## THIS FILE MUST BE PLACED AT AT THE ROOT OF THE REPOSITORY
##
## All Makefiles in this repository should include this file using these instructions:
##
## export REPO_ROOT_PATH := $(shell git rev-parse --show-toplevel)
## include $(REPO_ROOT_PATH)/Makefile.importer.mk
##

#
# DON'T EDIT THIS SECTION
#

ifndef ENV_SOURCED

# First pass: source the script, then re-run make for the real work
$(or $(MAKECMDGOALS),all): _bootstrap
	@:

_bootstrap:
	@set -a; . $(REPO_ROOT_PATH)/sds.setenv.sh; set +a; \
	exec $(MAKE) ENV_SOURCED=1 $(MAKECMDGOALS)

.PHONY: _bootstrap

else


# ---- real targets below; they all see the env vars ----

# Include the SDS makefile
export SDS_SDS_MKFILE_PATH := $(SDS_SDS_ROOT_PATH_IN_HOST)/bootstrap/Makefile.sds.mk

include $(SDS_SDS_MKFILE_PATH)

#
# ADD YOUR CUSTOM MAKEFILE TARGETS AND IMPORTS BELOW THIS LINE
#


endif
