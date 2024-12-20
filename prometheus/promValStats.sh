#!/bin/bash
operaCMD="/home/ubuntu/go-opera/build/opera attach --preload /extra/preload.js --datadir=/extra/lemon/data --exec"
text="val_pending_rewards "
rewards=$($operaCMD 'sfcc.pendingRewards("0x<enter the rest of your Wallet Address here>",<enter Validator ID here: ###>);')
block=$($operaCMD 'ftm.blockNumber;')
epoch=$($operaCMD 'admin.nodeInfo.protocols.opera.epoch;')
listening=$($operaCMD 'net.listening;')
if $listening 
  then listening=1
  else listening=0
fi
peerCount=$($operaCMD 'net.peerCount;')
walletStatus=$($operaCMD 'personal.listWallets;' | grep status | cut -d'"' -f2)
if  [ "$walletStatus" = "Locked" ]
  then walletStatus=1
  else walletStatus=0
fi
txPoolPending=$($operaCMD 'txpool.status.pending;')
txPoolQueued=$($operaCMD 'txpool.status.queued;')
echo "# HELP val_listening Is the validator listening to the chain: 1=Yes 0=No"
echo "# TYPE val_listening gauge"
echo "val_listening $listening"

echo "# HELP val_peer_count Current number of peers"
echo "# TYPE val_peer_count gauge"
echo "val_peer_count $peerCount"

echo "# HELP val_current_block Current block on LemonChain"
echo "# TYPE val_current_block counter"
echo "val_current_block $block"

echo "# HELP val_current_epoch Current Epoch on LemonChain"
echo "# TYPE val_current_epoch counter"
echo "val_current_epoch $epoch"

echo "# HELP val_wallet_status Wallet Status: 1=Locked 0=Unlocked"
echo "# TYPE val_wallet_status gauge"
echo "val_wallet_status $walletStatus"

echo "# HELP val_tx_pool_pending Current number of pending in the TX Pool"
echo "# TYPE val_tx_pool_pending gauge"
echo "val_tx_pool_pending $txPoolPending"

echo "# HELP val_tx_pool_queued Current number queued in the TX Pool"
echo "# TYPE val_tx_pool_queued gauge"
echo "val_tx_pool_queued $txPoolQueued"

echo "# HELP val_pending_rewards Current amount of Pending Rewards in LEMX"
echo "# TYPE val_pending_rewards gauge"
divisor=10**18
printf "%s" "$text"
awk "BEGIN {print $rewards/$divisor}"
