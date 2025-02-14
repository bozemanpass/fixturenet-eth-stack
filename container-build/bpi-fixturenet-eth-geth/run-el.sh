#!/bin/bash

if [ -n "$BPI_SCRIPT_DEBUG" ]; then
    set -x
fi

ETHERBASE=`cat /opt/testnet/build/el/accounts.csv | head -1 | cut -d',' -f2`
NETWORK_ID=`cat /opt/testnet/el/el-config.yaml | grep 'chain_id' | awk '{ print $2 }'`
NETRESTRICT=`ip addr | grep -w inet | grep -v '127.0' | awk '{print $2}'`
BPI_ETH_DATADIR="${BPI_ETH_DATADIR:-/data}"

if [ `ls -A "$BPI_ETH_DATADIR" | wc -l`  ]; then
  cp -rp "$HOME/ethdata/*" "$HOME/ethdata/.*" "$BPI_ETH_DATADIR"
fi

cd /opt/testnet/build/el
python3 -m http.server 9898 &
cd $HOME

START_CMD="geth"
if [ "true" == "$BPI_REMOTE_DEBUG" ] && [ -x "/usr/local/bin/dlv" ]; then
    START_CMD="/usr/local/bin/dlv --listen=:40000 --headless=true --api-version=2 --accept-multiclient exec /usr/local/bin/geth --continue --"
fi

# See https://linuxconfig.org/how-to-propagate-a-signal-to-child-processes-from-a-bash-script
cleanup() {
    echo "Signal received, cleaning up..."

    # Kill the child process first (BPI_REMOTE_DEBUG=true uses dlv which starts geth as a child process)
    pkill -P ${geth_pid}
    sleep 2
    kill $(jobs -p)

    wait
    echo "Done"
}
trap 'cleanup' SIGINT SIGTERM

if [ "true" == "$RUN_BOOTNODE" ]; then
    $START_CMD \
      --datadir="${BPI_ETH_DATADIR}" \
      --nodekeyhex="${BOOTNODE_KEY}" \
      --nodiscover \
      --ipcdisable \
      --networkid=${NETWORK_ID} \
      --netrestrict="${NETRESTRICT}" \
      &

    geth_pid=$!
else
    cd /opt/testnet/accounts
    ./import_keys.sh

    echo -n "$JWT" > /opt/testnet/build/el/jwtsecret

    OTHER_OPTS=""
    if [ "$BPI_ALLOW_UNPROTECTED_TXS" == "true" ]; then
      # Allow for unprotected (non EIP155) txs to be submitted via RPC
      OTHER_OPTS+=" --rpc.allow-unprotected-txs"
    fi

    $START_CMD \
      --datadir="${BPI_ETH_DATADIR}" \
      --bootnodes="${ENODE}" \
      --allow-insecure-unlock \
      --http \
      --http.addr="0.0.0.0" \
      --http.vhosts="*" \
      --http.api="${BPI_GETH_HTTP_APIS:-eth,web3,net,admin,personal,debug}" \
      --http.corsdomain="*" \
      --authrpc.addr="0.0.0.0" \
      --authrpc.vhosts="*" \
      --authrpc.jwtsecret="/opt/testnet/build/el/jwtsecret" \
      --ws \
      --ws.addr="0.0.0.0" \
      --ws.origins="*" \
      --ws.api="${BPI_GETH_WS_APIS:-eth,web3,net,admin,personal,debug}" \
      --http.corsdomain="*" \
      --networkid="${NETWORK_ID}" \
      --netrestrict="${NETRESTRICT}" \
      --state.scheme hash \
      --gcmode archive \
      --txlookuplimit=0 \
      --cache.preimages \
      --syncmode=full \
      --mine \
      --metrics \
      --metrics.addr="0.0.0.0" \
      --verbosity=${BPI_GETH_VERBOSITY:-3} \
      --log.vmodule="${BPI_GETH_VMODULE}" \
      --miner.etherbase="${ETHERBASE}" \
      ${OTHER_OPTS} \
      &

    geth_pid=$!
fi

wait $geth_pid

if [ "true" == "$BPI_KEEP_RUNNING_AFTER_GETH_EXIT" ]; then
  while [ 1 -eq 1 ]; do
    sleep 60
  done
fi
