#!/bin/bash

if [[ -n "$STACK_SCRIPT_DEBUG" ]]; then
    set -x
fi

BPI_LIGHTHOUSE_DATADIR=${BPI_LIGHTHOUSE_DATADIR:-/data}
export BPI_LIGHTHOUSE_DATADIR
cd "$BPI_LIGHTHOUSE_DATADIR"

# For any legacy scripts
DATADIR=$BPI_LIGHTHOUSE_DATADIR
export DATADIR

# See https://linuxconfig.org/how-to-propagate-a-signal-to-child-processes-from-a-bash-script
cleanup() {
    echo "Signal received, cleaning up..."
    kill $(jobs -p)

    wait
    echo "Done"
}
trap 'cleanup' SIGINT SIGTERM

if [[ $(find "$BPI_LIGHTHOUSE_DATADIR" | wc -l) -le 1 ]]; then
  echo "Copying initial data..."
  cp -r /opt/testnet/build/cl/* "$BPI_LIGHTHOUSE_DATADIR"
  chmod -R o-rwx "$BPI_LIGHTHOUSE_DATADIR"
fi

if [[ "true" == "$RUN_BOOTNODE" ]]; then
    cd $BPI_LIGHTHOUSE_DATADIR
    python3 -m http.server 3000 &


    cd /opt/testnet/cl
    ./bootnode.sh &
    bootnode_pid=$!

    wait $bootnode_pid
else
    while [[ 1 -eq 1 ]]; do
      echo "Waiting on geth ..."
      sleep 5
      result=`wget --no-check-certificate --quiet \
        -O - \
        --method POST \
        --timeout=0 \
        --header 'Content-Type: application/json' \
        --body-data '{ "jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": [] }' "${ETH1_ENDPOINT:-localhost:8545}" | jq -r '.result'`
       if [ ! -z "$result" ] && [ "null" != "$result" ]; then
           break
       fi
    done

    cd /opt/testnet/cl

    if [[ -z "$LIGHTHOUSE_GENESIS_STATE_URL" ]]; then
        # Check if beacon node data exists to avoid resetting genesis time on a restart
        if [ -d $BPI_LIGHTHOUSE_DATADIR/node_"$NODE_NUMBER"/beacon ]; then
            echo "Skipping genesis time reset"
        else
            ./reset_genesis_time.sh
        fi
    else
        while [[ 1 -eq 1 ]]; do
            echo "Waiting on Genesis time ..."
            sleep 5
            result=`wget --no-check-certificate --quiet -O - --timeout=0 $LIGHTHOUSE_GENESIS_STATE_URL | jq -r '.data.genesis_time'`
            if [ ! -z "$result" ]; then
                ./reset_genesis_time.sh $result
                break;
            fi
        done
    fi

    if [[ ! -z "$ENR_URL" ]]; then
        while [[ 1 -eq 1 ]]; do
            echo "Waiting on ENR for boot node..."
            sleep 5
            result=`wget --no-check-certificate --quiet -O - --timeout=0 $ENR_URL`
            if [ ! -z "$result" ]; then
                export ENR="$result"
                break;
            fi
        done
    fi

    export JWTSECRET="${BPI_LIGHTHOUSE_DATADIR}/jwtsecret"
    echo -n "$JWT" > $JWTSECRET

    ./beacon_node.sh &
    beacon_pid=$!
    ./validator_client.sh &
    validator_pid=$!

    wait $beacon_pid $validator_pid
fi
