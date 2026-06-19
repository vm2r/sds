#!/usr/bin/env bash
set -eu

##
## fork_privately.sh
##
## Fork repo vmr2/sds to a private repository in another organization.
##
## Usage:
##   ./fork_privately.sh <forked_org> <forked_repo> <forked_path>
##
## Arguments:
##   <forked_org>    The organization to fork the repository to.
##   <forked_repo>   The name of the new repository.
##   <forked_path>   The path to the directory where the forked repository will be cloned.
##


SDS_GITHUB_ORG="vm2r"
SDS_GITHUB_REPO="sds"

forked_path=${1:-}
forked_org=${2:-}
forked_repo=${3:-}


if [ -z "${forked_org}" ] || [ -z "${forked_repo}" ] || [ -z "${forked_path}" ]; then
    echo "Usage: ${0} <forked_path> <forked_org> <forked_repo>"
    exit 1
fi

cd ${forked_path}

printf "\nCreating repo ${forked_org}/${forked_repo}\n"
set +e
gh repo create ${forked_org}/${forked_repo} --private
set -e

printf "\nViewing repo ${forked_org}/${forked_repo}\n"
gh repo view ${forked_org}/${forked_repo} --json visibility,owner

printf "\nCloning repo ${SDS_GITHUB_ORG}/${SDS_GITHUB_REPO}\n"
rm -rf ${SDS_GITHUB_REPO}.git
git clone --bare git@github.com:${SDS_GITHUB_ORG}/${SDS_GITHUB_REPO}.git
cd ${SDS_GITHUB_REPO}.git

printf "\nPushing repo ${forked_org}/${forked_repo}\n"
git push --mirror git@github.com:${forked_org}/${forked_repo}.git

printf "\nRemoving repo ${SDS_GITHUB_ORG}/${SDS_GITHUB_REPO}\n"
cd ..
rm -rf ${SDS_GITHUB_REPO}.git

printf "\nCloning repo ${forked_org}/${forked_repo}\n"
git clone git@github.com:${forked_org}/${forked_repo}.git