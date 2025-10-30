#
# BUILDS A SDS IMAGE 
#


##
# THE "BASE OS" STAGE
# This stage is used as a base for building intermediate stages
##

FROM buildpack-deps:bookworm AS base_os
ARG APTGET_OPTIONS=-yqqq -o Dpkg::Progress-Fancy="0" -o APT::Color="0" -o Dpkg::Use-Pty="0" --no-install-recommends 

SHELL ["/bin/bash", "-c"]

# Update and Install dependencies
RUN set -eu; set +x; \
	DEBIAN_FRONTEND=noninteractive; \
	printf "\n\n\nPREPARING BASE OS\n\n\n"; \
	apt-get update $APTGET_OPTIONS; \
	apt-get upgrade $APTGET_OPTIONS; \
	printf "\n\n\nINSTALLING APT PACKAGES\n\n\n"; \
	apt-get install $APTGET_OPTIONS \
		build-essential ca-certificates gnupg curl git


##
# THE NODE STAGE (NVM)
#
# NVM
#   Based on instruction at:
#   https://github.com/nvm-sh/nvm	
#
##
FROM base_os AS node-builder-stage
RUN set -eu; set +x; \
	printf "\n\n\nINSTALLING NODE\n\n\n"; \
	curl \
		--silent --show-error --location \
		https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh \
		| bash; \
	export NVM_DIR="/root/.nvm"; \
	[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"; \
	time (\
		time nvm install v24.7.0 & \
		wait; \
	); 

##
# THE PYTHON STAGE
#
# Keep this Python installation stage in the very beginning of this Dockerfile
# as it takes a long time to build, so caching it is very benefical.  
##
FROM base_os AS python-builder-stage
RUN set -eu; set +x; \
	printf "\n\n\nINSTALLING PYTHON\n\n\n"; \
	export PYENV_ROOT="/root/.pyenv"; \
	export PATH="$PYENV_ROOT/bin:$PATH"; \
	curl \
		--silent --show-error --location \
		https://pyenv.run \
		| bash; \
	eval "$(pyenv init - bash)"; \
	time (\
		time pyenv install 3.12.8 & \
		time pyenv install 3.13.7 & \
		wait; \
	); \
	pyenv global 3.12; \
	pyenv rehash;


##
# THE PANTS STAGE
#
# Based on Pants installation instructions
# https://www.pantsbuild.org/stable/docs/getting-started/installing-pants
##
FROM base_os AS pants-builder-stage
RUN set -eu; set +x; \
	printf "\n\n\nINSTALLING PANTS\n\n\n"; \
	curl \
		--silent --show-error --location --proto '=https' --tlsv1.2 \
		https://static.pantsbuild.org/setup/get-pants.sh \
		| bash -s -- --bin-dir /usr/local/bin;


##
# THE PULUMI STAGE
#
# Based on Pulumi installation instructions
# https://www.pulumi.com/docs/iac/get-started/gcp/begin/
##
FROM base_os AS pulumi-builder-stage
ARG PULUMI_VERSION="latest"
RUN apt-get update -y && \
	printf "\n\n\nINSTALLING PULUMI\n\n\n" && \
	apt-get upgrade -y && \
	apt-get install -y \
	curl \
	build-essential \
	git; \
	# Install the Pulumi SDK, including the CLI and language runtimes.
	curl -fsSL https://get.pulumi.com/ \
		| bash -s -- --version $PULUMI_VERSION;

##
# THE SDS ENVIRONMENT BUILDER STAGE
# The OS to build the final SDS image
##
FROM debian:bookworm-slim AS sds_env_builder-stage

ARG APTGET_OPTIONS=-yqqq -o Dpkg::Progress-Fancy="0" -o APT::Color="0" -o Dpkg::Use-Pty="0" --no-install-recommends 

# Install Linux utilities
RUN set -eu; set +x; \
	DEBIAN_FRONTEND=noninteractive; \
	printf "\n\n\nINSTALLING LINUX UTILITIES\n\n\n"; \
	apt-get update $APTGET_OPTIONS; \
	apt-get upgrade $APTGET_OPTIONS; \
	apt-get install $APTGET_OPTIONS \
		ca-certificates gnupg make build-essential \
		wget curl ncat netcat-traditional tcptraceroute \
		iptables libc-bin net-tools dnsutils \
		inetutils-ftp inetutils-traceroute inetutils-ping inetutils-telnet \
		coreutils git gh \
		procps lsb-base lsb-release \
		zsh zplug sudo htop  \
		less vim nano jq \
		postgresql-client libpq-dev \
		bc;

# Install YQ (YAML)
RUN set -eu; set +x; \
	printf "\n\n\nINSTALLING YQ (YAML)\n\n\n"; \
	wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq; \
	chmod +x /usr/bin/yq


##
# THE TOOLS STAGE
# Build a stage with tools (PYTHON, NODE, GCP, etc...)
##
FROM sds_env_builder-stage AS tools-builder-stage

ARG APTGET_OPTIONS=-yqqq -o Dpkg::Progress-Fancy="0" -o APT::Color="0" -o Dpkg::Use-Pty="0" --no-install-recommends 

SHELL ["/bin/bash", "-c"]

## Copy from Python builder stage
COPY --from=python-builder-stage /root/.pyenv /root/.pyenv
RUN set -eu; set +x; \
	export PYENV_ROOT="/root/.pyenv"; \
	export PATH="$PYENV_ROOT/bin:$PATH"; \
	eval "$(pyenv init - bash)"; \
	pyenv global 3.12; \
	pyenv rehash; \
	printf "\n\n\n$(python --version)\n\n\n"; 
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH=${PYENV_ROOT}/bin:${PATH}

## Copy from Node builder stage
COPY --from=node-builder-stage /root/.nvm /root/.nvm
ENV NVM_DIR="/root/.nvm"


## Prepare APT environment for GCP tools
RUN set -eu; set +x; \
	printf "\n\n\nINSTALLING GOOGLE CLOUD APT KEYS\n\n\n"; \
	export GCP_GPG_KEY="/usr/share/keyrings/cloud.google.gpg"; \
	curl \
		--silent --show-error --location \
		https://packages.cloud.google.com/apt/doc/apt-key.gpg \
		| gpg --dearmor -o ${GCP_GPG_KEY};\
	echo "deb [signed-by=${GCP_GPG_KEY}] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list ; \
	export GCSFUSE_REPO="gcsfuse-$(lsb_release -c -s)"; \
	echo "deb [signed-by=${GCP_GPG_KEY}] https://packages.cloud.google.com/apt ${GCSFUSE_REPO} main" | tee -a /etc/apt/sources.list.d/gcsfuse.list; \
	printf "\n\n\nUPDATING PACKAGES\n\n\n"; \
	apt-get update $APTGET_OPTIONS; \
	apt-get upgrade $APTGET_OPTIONS; 


# GOOGLE CLOUD SDK (gcloud CLI)
# Based on TonyMet's Gcloud-Lite
# https://github.com/tonymet/gcloud-lite/blob/master/Dockerfile
#
# This is because the Google installer generates almos 1Gb of content in the image, 
# instead of TonyMet's 350Mb 
# https://cloud.google.com/sdk/docs/install#deb
ENV PATH=/google-cloud-sdk/bin:${PATH}
RUN set -eu; set +x; \
	printf "\n\n\nINSTALLING GOOGLE CLOUD SDK\n\n\n"; \
	ARCH=x86_64; \
	curl -s -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${ARCH}.tar.gz; \
	tar xzf google-cloud-cli-linux-${ARCH}.tar.gz; \
	rm google-cloud-cli-linux-${ARCH}.tar.gz; \
	rm -rf /google-cloud-sdk/platform/bundledpythonunix; \
	export PYENV_ROOT="/root/.pyenv"; \
	export PATH="$PYENV_ROOT/bin:$PATH"; \
	eval "$(pyenv init - bash)"; \
	pyenv global 3.12; \
	pyenv rehash; \
	gcloud config set core/disable_usage_reporting true; \
	gcloud config set component_manager/disable_update_check true; \
	gcloud config set metrics/environment github_docker_image; \
	gcloud components install -q beta; \
	rm -rf $(find google-cloud-sdk/ -regex ".*/__pycache__") \
			google-cloud-sdk/.install/.backup \
			google-cloud-sdk/bin/anthoscli; \
	gcloud --version


# GOOGLE CLOUD STORAGE FUSE
# Mount GCS buckets as local folders)
# Based on instructions from:
# https://cloud.google.com/storage/docs/cloud-storage-fuse/install
RUN set -eu; set +x; \
	DEBIAN_FRONTEND=noninteractive; \
	printf "\n\n\nINSTALLING GOOGLE GCS FUSE\n\n\n"; \
	apt-get install gcsfuse $APTGET_OPTIONS; \
	printf "\n\n\nCLEANING UP APT\n\n\n"; 	# THIS IS THE LAST APT LAYER SO CLEANUP all APT STUFF \
	rm -rf /var/lib/apt/lists/* \
			/var/cache/apt/* \
    		/usr/share/doc/* \
    		/usr/share/man/* \
    		/usr/share/locale/*; \
	apt-get autoremove $APTGET_OPTIONS; \
	apt-get clean $APTGET_OPTIONS; \
	apt-get autoclean $APTGET_OPTIONS; \
	apt-get check $APTGET_OPTIONS;


# GOOGLE CLOUD DATAFORM-CLI
# Based on instructions from:
# https://cloud.google.com/dataform/docs/use-dataform-cli=
RUN set -eu; set +x; \
	printf "\n\n\nINSTALLING GOOGLE DATAFORM CLI\n\n\n"; \
	export NVM_DIR="/root/.nvm"; \
	[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"; \
	nvm use v24.7.0; \
	npm i -g @dataform/cli@^3.0.29; \
	printf "\n\n\nCLEANING UP NPM\n\n\n"; 	# THIS IS THE LAST NPM LAYER SO CLEANUP all NPM STUFF \
	npm cache clean --force;


##
# THE FINAL SDS ENV IMAGE
# This stage to be published to the image repository
##
FROM tools-builder-stage AS sds_env

ARG SDS_SERVICE_DESCRIPTION
LABEL description="${SDS_SERVICE_DESCRIPTION}"

ARG SDS_VERSION_DATE_TAG
ENV SDS_VERSION_DATE_TAG="${SDS_VERSION_DATE_TAG}"

SHELL ["/bin/bash", "-c"]

ARG APTGET_OPTIONS=-yqqq -o Dpkg::Progress-Fancy="0" -o APT::Color="0" -o Dpkg::Use-Pty="0" --no-install-recommends 

## Copy from Pulumi builder stage
COPY --from=pulumi-builder-stage /root/.pulumi/bin/pulumi /usr/local/bin/pulumi
COPY --from=pulumi-builder-stage /root/.pulumi/bin/*-python* /usr/local/bin/
COPY --from=pulumi-builder-stage /root/.pulumi/bin/*-yaml* /usr/local/bin/

## Copy from Pants builder stage
COPY --from=pants-builder-stage /usr/local/bin/pants /usr/local/bin/pants

# SDS CONTAINER UTILITIES
COPY sds/opt/ /opt/
ENV PATH=${PATH}:/opt/sds

# SDS USER UTILITIES
COPY sds/etc/ /etc/

# SDS CLI SCRIPTS
# COPY cli/sds*.sh /usr/local/bin/

# The entrypoint contains many runtime initializations 
# and an infinite loop to keep the container awake
ENTRYPOINT ["bash", "/opt/sds/container-entrypoint.sh"]