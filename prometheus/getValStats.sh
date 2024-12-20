#!/bin/bash

# -------------  Modify these 2 variables ---------------------- #
# valID: replace # with your Validator ID                        #   
# walletAddr: replace 0x00000 with your Validator Wallet Address #
# -------------------------------------------------------------- #
valID=#
walletAddr="0x00000"

# Run the Opera Console Command
operaCMD="/home/ubuntu/go-opera/build/opera attach --preload /extra/preload.js --datadir=/extra/lemon/data --exec"

# Get Specific Validator Metrics
rewards=$($operaCMD "sfcc.pendingRewards(\"$walletAddr\",$valID);")
block=$($operaCMD 'ftm.blockNumber;')
epoch=$($operaCMD 'admin.nodeInfo.protocols.opera.epoch;')
listening=$($operaCMD 'net.listening;')
peerCount=$($operaCMD 'net.peerCount;')
walletStatus=$($operaCMD 'personal.listWallets;' | grep status | cut -d'"' -f2)
txPoolPending=$($operaCMD 'txpool.status.pending;')
txPoolQueued=$($operaCMD 'txpool.status.queued;')

# Print out Validator Metrics
echo "val_listening $listening"
echo "val_peer_count $peerCount"
echo "val_current_block $block"
echo "val_current_epoch $epoch"
echo "val_wallet_status $walletStatus"
echo "val_tx_pool_pending $txPoolPending"
echo "val_tx_pool_queued $txPoolQueued"
text="val_pending_rewards "
divisor=10**18
printf "%s" "$text"
awk "BEGIN {print $rewards/$divisor}"
