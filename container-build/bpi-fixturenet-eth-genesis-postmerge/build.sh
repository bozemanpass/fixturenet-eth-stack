#!/usr/bin/env bash
# Build bozemanpass/fixturenet-eth-genesis-postmerge

source ${STACK_CONTAINER_BASE_DIR}/build-base.sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build -t bozemanpass/fixturenet-eth-genesis-postmerge:stack -f ${SCRIPT_DIR}/Dockerfile ${build_command_args} $SCRIPT_DIR
