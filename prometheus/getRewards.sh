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
  echo "ID,Epoch,Staked,Delegated,Locked,Rewards,PreviousEpochRewardsPerToken"
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
valID=$($operaCMD "sfcc.getValidatorID(\"$walletAddr\");")
rewards=$($operaCMD "sfcc.pendingRewards(\"$walletAddr\",$valID);")
stake=$($operaCMD "sfcc.getStake(\"$walletAddr\",$valID);")/$particle
lockedStake=$($operaCMD "sfcc.getLockedStake(\"$walletAddr\",$valID);")
delegated=$($operaCMD "sfcc.getValidator($valID)[3];")
startTime=$($operaCMD "sfcc.getValidator($valID)[5];")
epoch=$($operaCMD 'sfcc.currentEpoch();')
prevEpoch=$epoch-1
totalStake=$($operaCMD "sfcc.totalStake();")
valList=$($operaCMD "sfcc.getEpochValidatorIDs($epoch);")

# Format Validator Run Time
currentTime=$(date +%s)
daySeconds=86400
valUpTime=$((currentTime - startTime))/$daySeconds

# Remove commas and brackets from Active Val list
valList=$(echo $valList | tr -d ',[]')

# check for tmp epoch file
FILE=/tmp/epoch.tmp     
if [ -f $FILE ]; then
   epoch_chk=$(cat $FILE)
   if [[ "$epoch" == "$epoch_chk" ]] && [[ $@ == "-c" ]]; then
       exit 0
   else
      echo "$epoch" > $FILE
   fi
else
   echo "$epoch" > $FILE
fi

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
  rewardsPerToken=$($operaCMD "sfcc.getEpochAccumulatedRewardPerToken($prevEpoch,$valID);")
  rewardsPerToken=$(convert_lemx $rewardsPerToken)

# print metrics in CSV format if a -c option was supplied
  if [[ $@ == "-c" ]];then
    echo "$valID,$epoch,$staked,$delegated,$lockedStake,$rewards,$rewardsPerToken"  
  else
    echo "ID: $valID"
    #  echo "Addr: $valAddr"
    echo "delegated:   $delegated"
    echo "staked:      $staked"
    echo "lockedStake: $lockedStake"
    echo "Rewards:     $rewards"
    echo "Previous Epoch rewards Per Token: $rewardsPerToken"
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
