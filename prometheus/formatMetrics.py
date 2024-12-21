#!/usr/bin/python3
import requests
import json

# Script to format the Validator debug metrics into something that prometheus can scrape

url = "http://localhost:6060/debug/metrics"
response = requests.get(url)
response_dict = json.loads(response.text)
tmp_dict = response_dict.copy()

for key in tmp_dict:
	# Delete metrics we don't care about
    if key.endswith(("percentile", "max", "mean", "min", "mean-rate", "minute", "std-dev")) or key.startswith(("memstats", "les", "eth", "cmdline", "system")):
        del response_dict[key]
    # format metrics that don't end in 'count'
    elif not key.endswith(("count")):
        new_key = key.replace("/","_") 
        response_dict[new_key] = response_dict.pop(key)
    # format everything that will have multiple sub-types
    elif key.startswith(("chain/account","chain/reorg","chain/storage","state/snapshot/bloom/account","state/snapshot/bloom/storage","state/snapshot/clean/account","state/snapshot/clean/storage","state/snapshot/dirty/account","state/snapshot/dirty/storage","state/snapshot/flush/account","state/snapshot/flush/storage","state/snapshot/generation/account","state/snapshot/generation/proof","state/snapshot/generation/storage","trie/bloom","trie/memcache/clean","trie/memcache/commit","trie/memcache/dirty","trie/memcache/flush","trie/memcache/gc","txpool/pending","txpool/queued","vflux/server/clientEvent")):
        new_key = key.replace("/","_")
        new_key = new_key.replace(".count","")
        type = new_key.rsplit("_", 1)[1]
        new_key = new_key.rsplit("_", 1)[0]
        new_key = new_key + "{type=\"" + type + "\"}"
        response_dict[new_key] = response_dict.pop(key)
    # special formatting for p2p egress/ingress    
    elif key.startswith(("p2p/egress/opera/63","p2p/ingress/opera/63")):
        new_key = key.replace("/","_")
        new_key = new_key.replace(".count","")
        if new_key.endswith(("packets")):
            tmp_key = new_key.split("_")
            new_key = tmp_key[0] + "_" + tmp_key[1] + "_" + tmp_key[2] + "_" + tmp_key[3] + "_" + tmp_key[5] + "_" + tmp_key[4]
        type = new_key.rsplit("_", 1)[1]
        new_key = new_key.rsplit("_", 1)[0]
        new_key = new_key + "{type=\"" + type + "\"}"
        response_dict[new_key] = response_dict.pop(key)
    # format everything else
    else:
        new_key = key.replace("/","_")
        new_key = new_key.replace(".count","") 
        response_dict[new_key] = response_dict.pop(key)

for key in response_dict:
    print(key, response_dict[key])
