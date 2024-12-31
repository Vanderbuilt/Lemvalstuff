#!/bin/bash
# Script to check LemonChain for updated files

network=lemon
start_node_file=start_node.bash
genesis_file=genesis-${network}.g
enodes_file=enodes-${network}.txt
preload_file=preload.js
start_node=/home/ubuntu/${start_node_file}
genesis=/home/ubuntu/${genesis_file}
enodes=/home/ubuntu/${enodes_file}
preload=/extra/${preload_file}
tmpdir=/home/ubuntu/tmp
start_node_tmp=/home/ubuntu/tmp/${start_node_file}
genesis_tmp=/home/ubuntu/tmp/${genesis_file}
enodes_tmp=/home/ubuntu/tmp/${enodes_file}
preload_tmp=/home/ubuntu/tmp/${preload_file}

asset_base_url="https://assets.allthingslemon.io/validators"

# Download start_node.bash file
    echo "Downloading start_node.bash file for ${network}..."
    wget -O "${start_node_tmp}" "${asset_base_url}/${start_node_file}"

# Download enodes file
    echo "Downloading enodes file for ${network}..."
    wget -O "${enodes_tmp}" "${asset_base_url}/${enodes_file}"

# Download genesis file if needed
    echo "Downloading genesis file for ${network}..."
    wget -O "${genesis_tmp}" "${asset_base_url}/${genesis_file}"

# Download preload file if needed
    echo "Downloading preload file for ${network}..."
    wget -O "${preload_tmp}" "${asset_base_url}/${preload_file}"

# diff on start_node.bash
    echo "Running diff on ${start_node_file}..."
    diff -I '^validator_id=' -I '^startup_mode=' -I '^public_key='  <(sed -e '$a\' "${start_node}") <(sed -e '$a\' "${start_node_tmp}")

# diff on enodes
    echo "Running diff on ${enodes_file}..."
    diff "${enodes}" "${enodes_tmp}"

# diff on genesis
    echo "Running diff on ${genesis_file}..."
    diff "${genesis}" "${genesis_tmp}"

# diff on preload
    echo "Running diff on ${preload_file}..."
    diff "${preload}" "${preload_tmp}"

