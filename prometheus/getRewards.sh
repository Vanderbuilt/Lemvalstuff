#!/bin/bash
# Version 0.3
# Script: getRewards.sh - A script to gether Lemon Validator Rewards
#  the script creates a epoch.tmp file in /tmp that contains the epoch # of the current epoch
#  IF the script is run multiple times in the same epoch with the -c option, it will immediately exit
#  This is done so the script can be run frequently from cron but will only output data once per epoch

# Options
# None, will always dispply rewards data in a human readable format
# -c, Print out stats in a comma separated values format once per epoch
# -h, Print out a header in a comma separated values format
# -p, Print out stats in prometheus file importer format once per epoch
 
# checks if number is in Scientific Notation
is_sci_not() {
    local num=$1
    if [[ $num =~ ^[+-]?[0-9]*\.?[0-9]+([eE][+-]?[0-9]+)?$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

#Converts from Scientific Notation to a Decimal number
convert_sci_to_dec() {
    local num=$1
    if [[ $(is_sci_not "$num") == "true" ]]; then
        awk '{printf "%f\n", $1}' <<< "$num"
    else
        echo "$num"
    fi
}

#Converts from Scientific Notation to a Decimal number, then divides the number by 10^18
convert_lemx() {
    local particle=10^18
    local num=$1
    num=$(convert_sci_to_dec "$num")
    num=$(echo "scale=5; $num / $particle" | bc)
    echo $num
}


#print CSV header line if a -c option was supplied
if [[ $@ == "-h" ]];then
  echo "ID,Epoch,Staked,Delegated,Locked,ActualStake,Rewards"
  exit 0
fi

# Run the Opera Console Command
operaCMD="/home/ubuntu/go-opera/build/opera attach --preload /extra/preload.js --datadir=/extra/lemon/data --exec"

#Get valList
#Get Epoch Snapshot
#Get rewards for each val


# Get Specific Validator Metrics
particle=10^18
seed=10**9
delegationPercent=0.35
delegationPercent=$(echo "scale=4; $delegationPercent" | bc)
epoch=$($operaCMD 'sfcc.currentEpoch();')
prevEpoch=$epoch-1
totalStake=$($operaCMD "sfcc.totalStake();")
valList=$($operaCMD "sfcc.getEpochValidatorIDs($epoch);")

# Remove commas and brackets from Active Val list
valList=$(echo $valList | tr -d ',[]')

# check for tmp epoch file
FILE=/tmp/epoch.tmp     
if [ -f $FILE ]; then
   epoch_chk=$(cat $FILE)
   if [[ "$epoch" == "$epoch_chk" && ( $@ == "-c" || $@ == "-p" ) ]] ; then
       exit 0
   else
      echo "$epoch" > $FILE
   fi
else
   echo "$epoch" > $FILE
fi

# If we're printing Prometheus metrics, we need to print the header rows
if [[ $@ == "-p" ]];then
    echo "# HELP val_stat_staked The number of staked LEMX on the validator instance"
    echo "# TYPE val_stat_staked gauge"
    echo "# HELP val_stat_locked The number of locked LEMX on the validator instance"
    echo "# TYPE val_stat_locked gauge"
    echo "# HELP val_stat_delegated The number of delegated LEMX on the validator instance"
    echo "# TYPE val_stat_delegated gauge"
    echo "# HELP val_stat_rewards The number of current rewards on the validator instance"
    echo "# TYPE val_stat_rewards gauge"
    echo "# HELP val_stat_stakeActual The number of staked coins plus 35% of delegated coins"
    echo "# TYPE val_stat_stakeActual gauge"
fi

# loop through all the validators
for valID in $valList; do
  valInfo=$($operaCMD "sfcc.getValidator($valID);")
  valInfo=$(echo $valInfo | tr -d ',[]')
  valInfo=($valInfo)
  valAddr=${valInfo[6]}
  delegated=${valInfo[3]}
  delegated=$(convert_lemx $delegated) 
  staked=$($operaCMD "sfcc.getStake($valAddr,$valID);")
  staked=$(convert_lemx $staked) 
  lockedStake=$($operaCMD "sfcc.getLockedStake($valAddr,$valID);")
  lockedStake=$(convert_lemx $lockedStake) 
  rewards=$($operaCMD "sfcc.pendingRewards($valAddr,$valID);")
  rewards=$(convert_lemx $rewards)
  # not sure what this metrics is - removing for now
  #rewardsPerToken=$($operaCMD "sfcc.getEpochAccumulatedRewardPerToken($prevEpoch,$valID);")
  #rewardsPerToken=$(convert_lemx $rewardsPerToken)

# calculate Actual stake - stake/lock + 35% of delegation
  delegatedActual=$(echo "$delegated - $staked" | bc)
  delegatedPercent=$(echo "$delegatedActual * $delegationPercent" | bc)
  stakeActual=$(echo "$staked + $delegatedPercent" | bc)
  
# print metrics in CSV format if a -c option was supplied
  if [[ $@ == "-c" ]];then
    echo "$valID,$epoch,$staked,$delegated,$lockedStake,$stakeActual,$rewards"  
# print metrics in prometheus file importer format if -p option was supplied
  elif [[ $@ == "-p" ]];then
    echo "val_stat_staked{validator=\"$valID\"} $staked"
    echo "val_stat_locked{validator=\"$valID\"} $lockedStake"
    echo "val_stat_delegated{validator=\"$valID\"} $delegated"
    echo "val_stat_rewards{validator=\"$valID\"} $rewards"
    echo "val_stat_stakeActual{validator=\"$valID\"} $stakeActual"
    #echo "val_stat_rewardsPerToken{validator=\"$valID\"} $rewardsPerToken"
  else
    echo "ID: $valID"
    #  echo "Addr: $valAddr"
    echo "delegated:   $delegated"
    echo "staked:      $staked"
    echo "lockedStake: $lockedStake"
    echo "Actual Stake: $stakeActual"
    echo "Rewards:     $rewards"
    #echo "Previous Epoch rewards Per Token: $rewardsPerToken"
  fi
done


if [[ $@ == "" ]]
  then
    epochSnap=$($operaCMD "sfcc.getEpochSnapshot($epoch);")
    prevEpochSnap=$($operaCMD "sfcc.getEpochSnapshot($prevEpoch);")

    echo ""
    echo "Epoch $epoch Snapshot data: $epochSnap"
    echo "Epoch $prevEpoch Snapshot data: $prevEpochSnap"
fi
