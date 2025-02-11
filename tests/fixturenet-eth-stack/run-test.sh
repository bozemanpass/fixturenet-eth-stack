#!/usr/bin/env bash
set -e
if [ -n "$BPI_SCRIPT_DEBUG" ]; then
  set -x
fi

SO_COMMAND=stack

test_name="Fixturenet eth stack deploy test"
echo "Running ${test_name}"

stack_name=$(pwd)/stacks/fixturenet-eth

test_fail_exit () {
    local fail_message=$1
    echo "${test_name}: ${fail_message}"
    echo "${test_name}: FAILED"
    exit 1
}

log_info () {
    local message=$1
    echo "$(date +"%Y-%m-%d %T"): ${message}"
}

# Sanity check the stack dir exists
if [ ! -d "${stack_name}" ]; then
    test_fail_exit "stack directory not present"
    exit 1
fi

# Set a non-default repo dir
export BPI_REPO_BASE_DIR=~/stack-orchestrator-test/repo-base-dir
reported_version_string=$( $SO_COMMAND version )
echo "SO version is: ${reported_version_string}"
echo "Cloning repositories into: $BPI_REPO_BASE_DIR"
rm -rf $BPI_REPO_BASE_DIR
mkdir -p $BPI_REPO_BASE_DIR

$SO_COMMAND --stack ${stack_name} setup-repositories

echo "Building containers"
$SO_COMMAND --stack ${stack_name} build-containers

test_deployment_dir=$BPI_REPO_BASE_DIR/test-deployment-dir
test_deployment_spec=$BPI_REPO_BASE_DIR/test-deployment-spec.yml

$SO_COMMAND --stack ${stack_name} deploy init --output $test_deployment_spec
# Check the file now exists
if [ ! -f "$test_deployment_spec" ]; then
    test_fail_exit "deploy init test: spec fille not present"
fi
echo "deploy init test: passed"

$SO_COMMAND --stack ${stack_name} deploy create --spec-file $test_deployment_spec --deployment-dir $test_deployment_dir
# Check the deployment dir exists
if [ ! -d "$test_deployment_dir" ]; then
    test_fail_exit "deploy create test: deployment directory not present"
fi
echo "deploy create test: passed"

$SO_COMMAND deployment --dir $test_deployment_dir start

timeout=900 # 15 minutes
log_info "Getting initial block number. Timeout set to $timeout seconds"
start_time=$(date +%s)
elapsed_time=0
initial_block_number=0
while [ "$initial_block_number" -eq 0 ]  && [ $elapsed_time -lt $timeout ]; do
  sleep 10
  log_info "Waiting for initial block..."
  initial_block_number=$($SO_COMMAND deployment --dir $test_deployment_dir exec foundry "cast block-number")
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
done

subsequent_block_number=$initial_block_number

# if initial block was 0 after timeout, assume chain did not start successfully and skip finding subsequent block
if [[ $initial_block_number -gt 0 ]]; then
  timeout=300
  log_info "Getting subsequent block number. Timeout set to $timeout seconds"
  start_time=$(date +%s)
  elapsed_time=0
  # wait for 5 blocks or timeout
  while [ "$subsequent_block_number" -le $((initial_block_number + 5)) ]  && [ $elapsed_time -lt $timeout ]; do
    sleep 10
    log_info "Waiting for five blocks or $timeout seconds..."
    subsequent_block_number=$($SO_COMMAND deployment --dir $test_deployment_dir exec foundry "cast block-number")
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
  done
fi

# will return 0 if either of the above loops timed out
block_number_difference=$((subsequent_block_number - initial_block_number))

log_info "Results of block height queries:"
echo "Initial block height: $initial_block_number"
echo "Subsequent block height: $subsequent_block_number"

# Block height difference should be between 1 and some small number
if [[ $block_number_difference -gt 1 && $block_number_difference -lt 100 ]]; then
  echo "Test passed"
  test_result=0
else
  echo "Test failed: block numbers were ${initial_block_number} and ${subsequent_block_number}"
  echo "Logs from stack:"
  $SO_COMMAND deployment --dir $test_deployment_dir logs
  test_result=1
fi
$SO_COMMAND deployment --dir $test_deployment_dir stop --delete-volumes
log_info "Removing cloned repositories"
rm -rf $BPI_REPO_BASE_DIR
log_info "Test finished"
exit $test_result
