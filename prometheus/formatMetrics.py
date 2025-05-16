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
    if key.startswith(("memstats", "les", "eth")):
        del response_dict[key]
    # Get the local validator ID
    elif key.startswith(("cmdline")):
        new_key = "val_id"
        cmdline_value = response_dict.pop(key)
        response_dict[new_key] = cmdline_value[9]
    # format everything that will have multiple sub-types
    elif '.' in key: 
        new_key = key.replace("/","_")
        type = new_key.rsplit(".", 1)[1]
        new_key = new_key.rsplit(".", 1)[0]
        new_key = new_key + "{type=\"" + type + "\"}"
        response_dict[new_key] = response_dict.pop(key)
    # format everything else
    else:
        new_key = key.replace("/","_")
        response_dict[new_key] = response_dict.pop(key)

for key in response_dict:
    print(key, response_dict[key])
