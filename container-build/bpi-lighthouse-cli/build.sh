#!/usr/bin/env bash
# Build bpi/lighthouse-cli

source ${BPI_CONTAINER_BASE_DIR}/build-base.sh

project_dir=${BPI_REPO_BASE_DIR}/lighthouse
docker build -t bpi/lighthouse-cli:local --build-arg PORTABLE=true -f ${project_dir}/lcli/Dockerfile ${build_command_args} ${project_dir}
