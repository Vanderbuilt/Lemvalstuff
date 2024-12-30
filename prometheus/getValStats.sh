#!/bin/bash
# Script: getValStats.sh - A script to gether Lemon Validator statistics
# Version 1.02
 
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
particle=10**18
rewards=$($operaCMD "sfcc.pendingRewards(\"$walletAddr\",$valID);")/$particle
stake=$($operaCMD "sfcc.getStake(\"$walletAddr\",$valID);")/$particle
lockedStake=$($operaCMD "sfcc.getLockedStake(\"$walletAddr\",$valID);")/$particle
delegated=$($operaCMD "sfcc.getValidator($valID)[3];")/$particle
block=$($operaCMD 'ftm.blockNumber;')
epoch=$($operaCMD 'admin.nodeInfo.protocols.opera.epoch;')
listening=$($operaCMD 'net.listening;')
peerCount=$($operaCMD 'net.peerCount;')
walletStatus=$($operaCMD "personal.listWallets[0][\"status\"];")
walletStatus=$(echo "$walletStatus" | tr -d "'\"")
txPoolPending=$($operaCMD 'txpool.status.pending;')
txPoolQueued=$($operaCMD 'txpool.status.queued;')
totalStake=$($operaCMD "sfcc.totalStake();")/$particle

# Print out Validator Metrics for people 
print_stats() {
    echo "Validator Status: $listening"
    echo "Validator Peers:  $peerCount"
    echo "Current Block: $block"
    echo "Current Epoch: $epoch"
    echo "Wallet Status: $walletStatus"
    echo "TX Pool Pending: $txPoolPending"
    echo "TX Pool Queued:  $txPoolQueued"
    printf "%s" "Staked LEMX: "
    awk "BEGIN {print $stake}" 
    printf "%s" "Locked/Staked LEMX: "
    awk "BEGIN {print $lockedStake}" 
    printf "%s" "Delegated LEMX: "
    awk "BEGIN {print $delegated}" 
    printf "%s" "Pending Rewards: "
    awk "BEGIN {print $rewards}"
    printf "%s" "Total Stake: "
    awk "BEGIN {print $totalStake}"
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

    echo "# HELP val_stake_lemx Current amount of LEMX Staked"
    echo "# TYPE val_stake_lemx gauge"
    printf "%s" "val_stake_lemx "
    awk "BEGIN {print $stake}"

    echo "# HELP val_lockedStake_lemx Current amount of LEMX Locked and Staked"
    echo "# TYPE val_lockedStake_lemx gauge"
    printf "%s" "val_lockedStake_lemx "
    awk "BEGIN {print $lockedStake}"

    echo "# HELP val_delegated_lemx Current amount of LEMX delegated"
    echo "# TYPE val_delegated_lemx gauge"
    printf "%s" "val_delegated_lemx "
    awk "BEGIN {print $delegated}"

    echo "# HELP val_pending_rewards Current amount of Pending Rewards in LEMX"
    echo "# TYPE val_pending_rewards gauge"
    printf "%s" "val_pending_rewards "
    awk "BEGIN {print $rewards}"

    echo "# HELP val_total_stake Total LEMX staked on the chain"
    echo "# TYPE val_total_stake gauge"
    printf "%s" "val_total_stake "
    awk "BEGIN {print $totalStake}"
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
