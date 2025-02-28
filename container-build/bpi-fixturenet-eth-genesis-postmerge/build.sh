#!/usr/bin/env bash
# Build bpi/fixturenet-eth-genesis-postmerge

source ${BPI_CONTAINER_BASE_DIR}/build-base.sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build -t bpi/fixturenet-eth-genesis-postmerge:stack -f ${SCRIPT_DIR}/Dockerfile ${build_command_args} $SCRIPT_DIR
