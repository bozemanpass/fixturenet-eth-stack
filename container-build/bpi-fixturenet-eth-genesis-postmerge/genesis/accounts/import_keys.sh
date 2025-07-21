#!/bin/sh

ACCOUNT_PASSWORD=${ACCOUNT_PASSWORD:-secret1212}

for line in `cat ../build/el/accounts.csv`; do
  BIP44_PATH="`echo "$line" | cut -d',' -f1`"
  ADDRESS="`echo "$line" | cut -d',' -f2`"
  PRIVATE_KEY="`echo "$line" | cut -d',' -f3`"

  echo "$ACCOUNT_PASSWORD" > /tmp/.pw.$$
  echo "$PRIVATE_KEY" | sed 's/0x//' > /tmp/.key.$$

  echo ""
  echo "$ADDRESS"
  geth account import --datadir=~/ethdata --password /tmp/.pw.$$ /tmp/.key.$$
  rm -f /tmp/.pw.$$ /tmp/.key.$$
done
