#!/bin/bash
# Script: getValStats.sh - A script to gether Lemon Validator statistics
# Version 1.12
 
# Options
# -p, Print out statistics using prometheus formatting

# Get Wallet Address
LEMON_DATA_DIR="/extra/lemon/data/"
walletAddr="0x$(ls -l $LEMON_DATA_DIR/keystore/ | awk '/UTC--/ { split($9, arr, "--"); print arr[length(arr)] }')"

# List Check function
#List check
function exists_in_list() {
    LIST=$1
    DELIMITER=$2
    VALUE=$3
    [[ "$LIST" =~ ($DELIMITER|^)$VALUE($DELIMITER|$) ]]
}

# Run the Opera Console Command
operaCMD="/home/ubuntu/go-opera/build/opera attach --preload /extra/preload.js --datadir=/extra/lemon/data --exec"

# Get Specific Validator Metrics
particle=10**18
seed=10**9
epoch=$($operaCMD 'sfcc.currentEpoch();')
prevEpoch=$epoch-1
valID=$($operaCMD "sfcc.getValidatorID(\"$walletAddr\");")
rewards=$($operaCMD "sfcc.pendingRewards(\"$walletAddr\",$valID);")/$particle
stake=$($operaCMD "sfcc.getStake(\"$walletAddr\",$valID);")/$particle
lockedStake=$($operaCMD "sfcc.getLockedStake(\"$walletAddr\",$valID);")/$particle
delegated=$($operaCMD "sfcc.getValidator($valID)[3];")/$particle
startTime=$($operaCMD "sfcc.getValidator($valID)[5];")
block=$($operaCMD 'ftm.blockNumber;')
gas=$($operaCMD 'ftm.gasPrice;')/$seed
maxGasFee=$($operaCMD 'ftm.maxPriorityFeePerGas;')/$seed
listening=$($operaCMD 'net.listening;')
peerCount=$($operaCMD 'net.peerCount;')
chainVersion=$($operaCMD 'sfcc.version();')
chainVersion=$(echo "$chainVersion" | tr -d "'\"") # Remove double quotes
chainVersion=$((chainVersion)) # convert HEX to DEC
walletStatus=$($operaCMD "personal.listWallets[0][\"status\"];")
walletStatus=$(echo "$walletStatus" | tr -d "'\"")
txPoolPending=$($operaCMD 'txpool.status.pending;')
txPoolQueued=$($operaCMD 'txpool.status.queued;')
totalStake=$($operaCMD "sfcc.totalStake();")/$particle
rewardsPerToken=$($operaCMD "sfcc.getEpochAccumulatedRewardPerToken($prevEpoch,$valID);")/$particle
valList=$($operaCMD "sfcc.getEpochValidatorIDs($epoch);")

# Format Validator Run Time
currentTime=$(date +%s)
daySeconds=86400
valUpTime=$((currentTime - startTime))/$daySeconds

# Remove commas and brackets from Active Val list
valList=$(echo $valList | tr -d ',[]')

# Check if valID exists in Active list
if exists_in_list "$valList" " " $valID; then
  active=1
  valStatus="ACTIVE"
else
  active=0
  valStatus="INACTIVE"
fi

# Count the total number of active Validators during the Epoch
# and gets the rank in total delegation
activeVals=0
valRank=0
checkVal=1
for x in $valList; do
  activeVals=$((activeVals+1))
  if [[ $checkVal == "1" ]]; then
    valRank=$activeVals 
    if [[ $x == $valID ]]; then 
      checkVal=0
    fi
  fi  
done

# Print out Validator Metrics for people 
print_stats() {
    echo "Validator Status: $listening"
    echo "Validator Peers:  $peerCount"
    echo "Current Block: $block"
    echo "Current Epoch: $epoch"
    echo "Validator $valID is $valStatus and ranked: #$valRank of $activeVals"
    echo "LemonChain version: $chainVersion"
    printf "%s" "Current Gas Fee(Gwei): "
    awk "BEGIN {print $gas}"
    printf "%s" "Current Max Priority Gas Fee(Gwei): "
    awk "BEGIN {print $maxGasFee}"
    echo "Wallet Status: $walletStatus"
    echo "TX Pool Pending: $txPoolPending"
    echo "TX Pool Queued:  $txPoolQueued"
    printf "%s" "Validator Uptime(days): "
    awk "BEGIN {print $valUpTime}" 
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
    printf "%s" "Previous Epoch rewards per Token: "
    awk "BEGIN {print $rewardsPerToken}"
    echo "Active Validators: $valList"
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
    echo "val_current_block_count $block"

    echo "# HELP val_current_epoch Current Epoch on LemonChain"
    echo "# TYPE val_current_epoch counter"
    echo "val_current_epoch_count $epoch"

    echo "# HELP val_active Validator is active in Current Epoch"
    echo "# TYPE val_active gauge"
    echo "val_active $active"

    echo "# HELP val_rank Validator rank in total delegation"
    echo "# TYPE val_rank gauge"
    echo "val_rank $valRank"

    echo "# HELP val_chain_version Lemon Chain version"
    echo "# TYPE val_chain_version gauge"
    echo "val_chain_version $chainVersion"

    echo "# HELP val_total_active Total number of active Validators in Current Epoch"
    echo "# TYPE val_total_active gauge"
    echo "val_total_active $activeVals"

    echo "# HELP val_current_gas Current Gas Fee on LemonChain"
    echo "# TYPE val_current_gas gauge"
    printf "%s" "val_current_gas "
    awk "BEGIN {print $gas}"

    echo "# HELP val_current_max_priority_gas Current Max Priority Gas Fee on LemonChain"
    echo "# TYPE val_current_max_priority_gas gauge"
    printf "%s" "val_current_max_priority_gas "
    awk "BEGIN {print $maxGasFee}"

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

    echo "# HELP val_start_time Epoch Time stamp when validator started up"
    echo "# TYPE val_start_time gauge"
    printf "%s" "val_start_time "
    awk "BEGIN {print $startTime}"

    echo "# HELP val_total_stake Total LEMX staked on the chain"
    echo "# TYPE val_total_stake gauge"
    printf "%s" "val_total_stake "
    awk "BEGIN {print $totalStake}"

    echo "# HELP val_prev_rewards_per_token Previous Epoch rewards per Token"
    echo "# TYPE val_prev_rewards_per_token gauge"
    printf "%s" "val_prev_rewards_per_token "
    awk "BEGIN {print $rewardsPerToken}"
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
