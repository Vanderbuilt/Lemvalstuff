#!/bin/bash
# Script: isEpochVal.sh - Script returns 1 if validator was active in the current Epoch
# Version 0.01
 
# Options
# -p, Print out statistics using prometheus formatting

# Variables
# -------------  Modify this variable -------------------------- #
# valID: replace # with your Validator ID                        #   
# -------------------------------------------------------------- #
valID=#

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
epoch=$($operaCMD 'admin.nodeInfo.protocols.opera.epoch;')
valList=$($operaCMD "sfcc.getEpochValidatorIDs($epoch);")

# Remove commas and brackets
valList=$(echo $valList | tr -d ',[]')

# Check if valID exists in list
if exists_in_list "$valList" " " $valID; then
  active=1
else
  active=0
fi


# Print out Validator Metrics for people 
print_stats() {
    echo "Current Epoch: $epoch"
    echo "Validator $valID is active: $active"
    }
    
# Print out Validator Metrics for Prometheus
print_stats_prom() {
    echo "# HELP val_active Validator is active in Current Epoch"
    echo "# TYPE val_active guage"
    echo "val_active{instance=\"$valID\",epoch=\"$epoch\"} $active"

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
