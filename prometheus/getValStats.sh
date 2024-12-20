#!/bin/bash
# Script: getValStats.sh - A script to gether Lemon Validator statistics

# Options
# -p, Print out statistics using prometheus formatting

# Variables
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
divisor=10**18
rewards=$rewards/$divisor
block=$($operaCMD 'ftm.blockNumber;')
epoch=$($operaCMD 'admin.nodeInfo.protocols.opera.epoch;')
listening=$($operaCMD 'net.listening;')
peerCount=$($operaCMD 'net.peerCount;')
walletStatus=$($operaCMD 'personal.listWallets;' | grep status | cut -d'"' -f2)
txPoolPending=$($operaCMD 'txpool.status.pending;')
txPoolQueued=$($operaCMD 'txpool.status.queued;')

# Print out Validator Metrics for people 
print_stats() {
    echo "Validator Status: $listening"
    echo "Validator Peers:  $peerCount"
    echo "Current Block: $block"
    echo "Current Epoch: $epoch"
    echo "Wallet Status: $walletStatus"
    echo "TX Pool Pending: $txPoolPending"
    echo "TX Pool Queued:  $txPoolQueued"
    printf "%s" "Pending Rewards: "
    awk "BEGIN {print $rewards}" 
    }
    
# Print out Validator Metrics for Prometheus
print_stats_prom() {
    if $listening
      then listening=1
      else listening=0
    fi
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

    if  [ "$walletStatus" = "Locked" ]
      then walletStatus=1
      else walletStatus=0
    fi
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
    printf "%s" "val_pending_rewards "
    awk "BEGIN {print $rewards}"
    } 

# if -p was used, display metrics using prometheus formatting 
    if [[ $@ == "-p" ]] 
      then 
	print_stats_prom
	exit 0
    else
      print_stats
      exit 0
    fi
