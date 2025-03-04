#!/bin/bash

set -e

source ${BPI_CONTAINER_BASE_DIR}/build-base.sh

cd $BPI_REPO_BASE_DIR/din-caddy-plugins

docker build . -t bpi/din-caddy:stack
