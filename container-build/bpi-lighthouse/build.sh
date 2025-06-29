#!/usr/bin/env bash
# Build bpi/lighthouse

source ${STACK_CONTAINER_BASE_DIR}/build-base.sh

# See: https://stackoverflow.com/a/246128/1701505
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build -t bpi/lighthouse:stack ${build_command_args} ${SCRIPT_DIR}
